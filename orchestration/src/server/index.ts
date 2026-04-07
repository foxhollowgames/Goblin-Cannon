import Fastify from "fastify";
import cors from "@fastify/cors";
import multipart from "@fastify/multipart";
import fastifyStatic from "@fastify/static";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { loadConfig, resetConfigCache } from "../lib/config.js";
import {
  resolveCursorCommand,
  describeCursorResolution,
  isCursorCliPathRunnable,
} from "../lib/resolve-cursor-cli.js";
import {
  startPipelineJob,
  stopPipelineRun,
  type PipelineStartMode,
} from "../lib/pipeline.js";
import { recoverTaskToTestingAndRunTests } from "../lib/recover-task.js";
import { recoverUnfinishedTasksForRun } from "../lib/recover-unfinished.js";
import { performAssignNext } from "../lib/assign-next.js";
import {
  getRun,
  createRun,
  listRuns,
  newId,
  appendOutcome,
  touchRun,
  updateTask,
  saveRun,
  dataDir,
  collectReferencedWorktreePaths,
} from "../lib/store.js";
import {
  isAllowedAttachmentFile,
  saveProblemAttachment,
} from "../lib/attachments.js";
import { pruneUnreferencedAgentWorktrees, removeWorktree } from "../lib/worktree.js";
import { runPlanner } from "../lib/runners/planner.js";
import { runExecution } from "../lib/runners/execution.js";
import { runGodotTests, captureBaseline } from "../lib/runners/testing.js";
import { runCommunication } from "../lib/runners/communication.js";
import { subscribe, getLogBuffer } from "../lib/log-bus.js";
import type { RunState } from "../lib/types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function appendPruneOutcomeOnNewRun(run: RunState): void {
  resetConfigCache();
  const c = loadConfig();
  if (c.dryRun) return;
  const pr = pruneUnreferencedAgentWorktrees(
    c.repoRoot,
    c.worktreeParentDir,
    collectReferencedWorktreePaths()
  );
  if (pr.removed.length === 0 && pr.warnings.length === 0) return;
  appendOutcome(run, {
    id: newId("out"),
    kind: "orchestrator",
    at: new Date().toISOString(),
    summary:
      pr.removed.length > 0
        ? `New run: pruned ${pr.removed.length} unreferenced agent worktree folder(s).`
        : `New run: prune pass reported ${pr.warnings.length} warning(s).`,
    metadata: { removed: pr.removed, warnings: pr.warnings },
  });
  saveRun(run);
}

function packageRoot(): string {
  return join(__dirname, "../..");
}

/** Per-run cap for parallel worktrees (pipeline + assign). Clamped 1–32. */
function clampParallelWorktrees(
  requested: number | undefined,
  fallback: number
): number {
  const base = Number.isFinite(fallback) ? Math.floor(fallback) : 4;
  if (requested === undefined || !Number.isFinite(requested)) {
    return Math.max(1, Math.min(32, base));
  }
  return Math.max(1, Math.min(32, Math.floor(requested)));
}

async function buildServer() {
  const app = Fastify({ logger: true });
  await app.register(cors, { origin: true });
  await app.register(multipart, {
    limits: {
      fileSize: 25 * 1024 * 1024,
      files: 16,
      fields: 16,
      parts: 48,
    },
  });

  const staticRoot = join(packageRoot(), "dist", "client");
  const assetsRoot = join(staticRoot, "assets");

  /** Do not register @fastify/static on `/` — it adds broad GET handlers that can still win over `/api/*`. Serve `/assets/*` and `/` explicitly instead. */

  app.get("/api/health", async () => ({ ok: true }));

  /** Common mistake: `/config` is not the API (that serves the SPA). Send browsers to JSON. */
  app.get("/config", async (_req, reply) =>
    reply.redirect("/api/config", 302)
  );

  app.get("/api/config", async (req, reply) => {
    resetConfigCache();
    const c = loadConfig();
    const resolved = resolveCursorCommand(c.cursorCli.command);
    const cursorApiKeyConfigured = Boolean(
      (process.env.CURSOR_API_KEY?.trim() ||
        c.cursorCli.env?.CURSOR_API_KEY?.trim())?.length
    );
    const payload = {
      repoRoot: c.repoRoot,
      worktreeParentDir: c.worktreeParentDir,
      dryRun: c.dryRun,
      limits: c.limits,
      autoMergeOnPass: c.autoMergeOnPass,
      pushAfterMerge: c.pushAfterMerge,
      gitRemote: c.gitRemote,
      deleteRemoteAgentBranch: c.deleteRemoteAgentBranch,
      hasGodotPath: Boolean(c.godotPath),
      cursorCliResolved: describeCursorResolution(resolved),
      cursorCliFoundOnDisk: isCursorCliPathRunnable(resolved),
      cursorApiKeyConfigured,
    };

    /** Firefox’s JSON viewer often shows only the “Pretty-print” bar with no body; plain text is readable in the tab. */
    const q = req.query as Record<string, string | undefined>;
    const isAddressBarNavigation =
      req.headers["sec-fetch-mode"] === "navigate" &&
      req.headers["sec-fetch-dest"] === "document";
    const wantPlainText =
      q?.text === "1" ||
      q?.raw === "1" ||
      isAddressBarNavigation;

    if (wantPlainText) {
      return reply
        .header("Cache-Control", "no-store")
        .type("text/plain; charset=utf-8")
        .send(`${JSON.stringify(payload, null, 2)}\n`);
    }

    return reply
      .header("Cache-Control", "no-store")
      .type("application/json; charset=utf-8")
      .send(payload);
  });

  app.get("/api/runs", async () => ({ runs: listRuns() }));

  app.post<{
    Body: {
      problem?: string;
      maxParallelWorktrees?: number;
    };
  }>("/api/runs", async (req, reply) => {
    resetConfigCache();
    const cfg = loadConfig();
    const contentType = req.headers["content-type"] ?? "";

    if (contentType.includes("multipart/form-data")) {
      let problem = "";
      let maxParallel: number | undefined;
      const fileBuffers: {
        filename: string;
        mimetype: string;
        buffer: Buffer;
      }[] = [];

      for await (const part of req.parts()) {
        if (part.type === "field") {
          if (part.fieldname === "problem") {
            problem = String(part.value ?? "").trim();
          } else if (part.fieldname === "maxParallelWorktrees") {
            const n = parseInt(String(part.value ?? ""), 10);
            if (Number.isFinite(n)) maxParallel = n;
          }
        } else if (part.type === "file") {
          const filename = part.filename || "upload";
          const mimetype = part.mimetype || "application/octet-stream";
          if (!isAllowedAttachmentFile(filename, mimetype)) {
            return reply.code(400).send({
              error: `Attachment not allowed (type or extension): ${filename} (${mimetype}). Use images, video, audio, or PDF.`,
            });
          }
          const buffer = await part.toBuffer();
          fileBuffers.push({ filename, mimetype, buffer });
        }
      }

      if (!problem && fileBuffers.length === 0) {
        return reply.code(400).send({
          error: "Provide problem text and/or at least one attachment.",
        });
      }

      const max = clampParallelWorktrees(
        maxParallel,
        cfg.limits.maxParallelWorktrees
      );
      const run = createRun(
        problem ||
          (fileBuffers.length
            ? "(Problem text empty — see attached media.)"
            : "Describe your goal in the Problem step."),
        max
      );
      appendPruneOutcomeOnNewRun(run);

      if (fileBuffers.length > 0) {
        const attachments = fileBuffers.map((b) =>
          saveProblemAttachment(run.id, b.filename, b.buffer, b.mimetype)
        );
        run.attachments = attachments;
        saveRun(run);
      }

      return reply.code(201).send(run);
    }

    const problem = (req.body?.problem ?? "").trim();
    const max = clampParallelWorktrees(
      req.body?.maxParallelWorktrees,
      cfg.limits.maxParallelWorktrees
    );
    const run = createRun(problem || "Describe your goal in the Problem step.", max);
    appendPruneOutcomeOnNewRun(run);
    return reply.code(201).send(run);
  });

  app.get<{
    Params: { id: string };
  }>("/api/runs/:id", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    return run;
  });

  /** Serve saved attachment bytes for dashboard thumbnails (local use). */
  app.get<{
    Params: { runId: string; attachmentId: string };
  }>(
    "/api/runs/:runId/attachments/:attachmentId",
    async (req, reply) => {
      const run = getRun(req.params.runId);
      if (!run) return reply.code(404).send({ error: "Run not found" });
      const att = run.attachments?.find((a) => a.id === req.params.attachmentId);
      if (!att) {
        return reply.code(404).send({ error: "Attachment not found" });
      }
      const prefix = `attachments/${req.params.runId}/`;
      if (!att.relativePath.replace(/\\/g, "/").startsWith(prefix)) {
        return reply.code(403).send({ error: "Invalid attachment path" });
      }
      const abs = resolve(dataDir(), att.relativePath);
      if (!existsSync(abs)) {
        return reply.code(404).send({ error: "File missing" });
      }
      try {
        const buf = readFileSync(abs);
        return reply
          .header("Cache-Control", "private, max-age=3600")
          .type(att.mime || "application/octet-stream")
          .send(buf);
      } catch {
        return reply.code(404).send({ error: "Could not read file" });
      }
    }
  );

  app.patch<{
    Params: { id: string };
    Body: { problem?: string };
  }>("/api/runs/:id", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    if (req.body?.problem !== undefined) {
      run.problem = req.body.problem;
      touchRun(run);
    }
    return run;
  });

  /** Flat paths — avoid `/runs/:id/pipeline/start` (some routers miss multi-segment routes after a param → 404 Not found). */
  app.post<{
    Body: { runId?: string; fromBacklogOnly?: boolean };
  }>("/api/pipeline/start", async (req, reply) => {
    const runId =
      typeof req.body?.runId === "string" ? req.body.runId.trim() : "";
    if (!runId) {
      return reply.code(400).send({ error: "runId required" });
    }
    const run = getRun(runId);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    resetConfigCache();
    const mode: PipelineStartMode = req.body?.fromBacklogOnly
      ? "fromBacklogOnly"
      : "full";
    try {
      startPipelineJob(runId, mode);
      return reply.code(202).send({
        runId,
        message:
          mode === "fromBacklogOnly"
            ? "Backlog-only pipeline started (planner skipped)"
            : "Pipeline started",
      });
    } catch (e) {
      return reply.code(409).send({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  });

  app.post<{
    Body: { runId?: string };
  }>("/api/pipeline/stop", async (req, reply) => {
    const runId =
      typeof req.body?.runId === "string" ? req.body.runId.trim() : "";
    if (!runId) {
      return reply.code(400).send({ error: "runId required" });
    }
    const run = getRun(runId);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    const stopped = stopPipelineRun(runId);
    if (!stopped) {
      return { ok: false, message: "No pipeline was running" };
    }
    run.pipelineStatus = "stopped";
    run.pipelineMessage = "Stopped by user";
    run.phase = "idle";
    touchRun(run);
    return { ok: true };
  });

  app.post<{
    Params: { id: string };
  }>("/api/runs/:id/plan", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    resetConfigCache();
    try {
      const updated = await runPlanner(run);
      return updated;
    } catch (e) {
      req.log.error(e);
      return reply.code(500).send({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  });

  app.post<{
    Params: { id: string };
  }>("/api/runs/:id/baseline", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    resetConfigCache();
    try {
      const updated = await captureBaseline(run);
      return updated;
    } catch (e) {
      return reply.code(500).send({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  });

  app.post<{
    Params: { id: string };
  }>("/api/runs/:id/assign", async (req, reply) => {
    resetConfigCache();
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    const outcome = await performAssignNext(run);
    if (!outcome.ok) {
      return reply.code(400).send({ error: outcome.error });
    }
    return getRun(req.params.id) ?? run;
  });

  app.post<{
    Params: { id: string };
    Body: { taskId: string };
  }>("/api/runs/:id/execute", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    const taskId = req.body?.taskId;
    if (!taskId) return reply.code(400).send({ error: "taskId required" });
    const task = run.backlog.find((t) => t.id === taskId);
    if (!task) return reply.code(404).send({ error: "Task not found" });
    if (task.status !== "assigned") {
      return reply
        .code(400)
        .send({ error: "Task must be assigned before execution" });
    }
    resetConfigCache();
    try {
      const { run: updated } = await runExecution(run, task);
      return updated;
    } catch (e) {
      return reply.code(500).send({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  });

  /**
   * If execution failed or Stop left the task in `failed`/`assigned` but the worktree has real
   * changes, run Godot tests and advance the task. If the task is already `testing`, re-runs
   * Godot tests in that worktree only.
   */
  app.post<{
    Params: { id: string };
    Body: { taskId?: string };
  }>("/api/runs/:id/recover-task", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    const taskId =
      typeof req.body?.taskId === "string" ? req.body.taskId.trim() : "";
    if (!taskId) {
      return reply.code(400).send({ error: "taskId required" });
    }
    resetConfigCache();
    const result = await recoverTaskToTestingAndRunTests(run, taskId);
    if (!result.ok) {
      return reply.code(400).send({ error: result.error });
    }
    return result.run;
  });

  /**
   * For each backlog task that is not done and has a worktree in failed/assigned/testing,
   * runs the same recovery as POST /recover-task (Godot tests, status updates). Skips pending
   * tasks until they have a worktree.
   */
  app.post<{
    Params: { id: string };
  }>("/api/runs/:id/recover-unfinished", async (req, reply) => {
    resetConfigCache();
    const result = await recoverUnfinishedTasksForRun(req.params.id);
    if (!result.ok) {
      const code = result.error === "Run not found" ? 404 : 500;
      return reply.code(code).send({ error: result.error });
    }
    return {
      run: result.run,
      attempted: result.attempted,
      skippedLabels: result.skippedLabels,
      failures: result.failures,
    };
  });

  app.post<{
    Params: { id: string };
    Body: { taskId: string };
  }>("/api/runs/:id/test", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    const taskId = req.body?.taskId;
    if (!taskId) return reply.code(400).send({ error: "taskId required" });
    const task = run.backlog.find((t) => t.id === taskId);
    if (!task) return reply.code(404).send({ error: "Task not found" });
    if (task.status !== "testing") {
      return reply
        .code(400)
        .send({ error: "Task must be in testing state (run execution first)" });
    }
    if (!task.assignedWorktreePath) {
      return reply.code(400).send({ error: "Task has no worktree" });
    }
    resetConfigCache();
    try {
      const testResult = await runGodotTests(
        run,
        task,
        task.assignedWorktreePath
      );
      return testResult.run;
    } catch (e) {
      return reply.code(500).send({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  });

  app.post<{
    Params: { id: string };
  }>("/api/runs/:id/report", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    resetConfigCache();
    try {
      const updated = await runCommunication(run);
      return updated;
    } catch (e) {
      return reply.code(500).send({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  });

  app.post<{
    Params: { id: string };
    Body: { taskId: string; deleteBranch?: boolean };
  }>("/api/runs/:id/worktree/remove", async (req, reply) => {
    resetConfigCache();
    const cfg = loadConfig();
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    const taskId = req.body?.taskId;
    if (!taskId) return reply.code(400).send({ error: "taskId required" });
    const task = run.backlog.find((t) => t.id === taskId);
    if (!task?.assignedWorktreePath) {
      return reply.code(400).send({ error: "No worktree on task" });
    }
    const path = task.assignedWorktreePath;
    const delBranch = req.body?.deleteBranch !== false;
    const rm = removeWorktree(
      cfg.repoRoot,
      path,
      delBranch,
      task.branchName
    );
    run.activeWorktreePaths = run.activeWorktreePaths.filter((p) => p !== path);
    appendOutcome(run, {
      id: newId("out"),
      kind: "orchestrator",
      at: new Date().toISOString(),
      summary: rm.ok
        ? `Removed worktree ${path}${rm.error ? " — " + rm.error : ""}`
        : `Failed to remove worktree: ${rm.error}`,
      metadata: { path, taskId },
    });
    const nextStatus =
      task.status === "assigned" || task.status === "testing"
        ? "pending"
        : task.status;
    updateTask(run, task.id, {
      assignedWorktreePath: undefined,
      branchName: undefined,
      status: nextStatus,
    });
    return run;
  });

  app.get<{
    Params: { id: string };
  }>("/api/runs/:id/stream", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    reply.raw.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    });
    reply.raw.write(": connected\n\n");
    const buffered = getLogBuffer(req.params.id);
    if (buffered) {
      reply.raw.write(`data: ${JSON.stringify({ line: buffered })}\n\n`);
    }
    const send = (line: string) => {
      reply.raw.write(`data: ${JSON.stringify({ line })}\n\n`);
    };
    const unsub = subscribe(req.params.id, send);
    const ping = setInterval(() => {
      reply.raw.write(": ping\n\n");
    }, 15000);
    req.raw.on("close", () => {
      clearInterval(ping);
      unsub();
    });
    return reply;
  });

  if (existsSync(join(staticRoot, "index.html"))) {
    app.get("/", async (_req, reply) => {
      return reply
        .type("text/html")
        .send(readFileSync(join(staticRoot, "index.html"), "utf8"));
    });
    if (existsSync(assetsRoot)) {
      await app.register(fastifyStatic, {
        root: assetsRoot,
        prefix: "/assets/",
        decorateReply: false,
      });
    }
    app.setNotFoundHandler((req, reply) => {
      if (req.url.startsWith("/api")) {
        return reply.code(404).send({ error: "Not found" });
      }
      if (req.method === "GET" && !req.url.startsWith("/assets/")) {
        return reply
          .type("text/html")
          .send(readFileSync(join(staticRoot, "index.html"), "utf8"));
      }
      return reply.code(404).send();
    });
  }

  return app;
}

const port = Number(process.env.ORCH_PORT ?? 8787);
const host = process.env.ORCH_HOST ?? "127.0.0.1";

buildServer()
  .then((app) =>
    app.listen({ port, host }).then(() => {
      console.error(`Orchestration server http://${host}:${port}`);
    })
  )
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
