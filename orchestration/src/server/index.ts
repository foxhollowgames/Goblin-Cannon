import Fastify from "fastify";
import cors from "@fastify/cors";
import fastifyStatic from "@fastify/static";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync, readFileSync } from "node:fs";
import { loadConfig, resetConfigCache } from "../lib/config.js";
import {
  resolveCursorCommand,
  describeCursorResolution,
  isCursorCliPathRunnable,
} from "../lib/resolve-cursor-cli.js";
import { startPipelineJob, stopPipelineRun } from "../lib/pipeline.js";
import { performAssignNext } from "../lib/assign-next.js";
import {
  getRun,
  createRun,
  listRuns,
  newId,
  appendOutcome,
  touchRun,
  updateTask,
} from "../lib/store.js";
import { removeWorktree } from "../lib/worktree.js";
import { runPlanner } from "../lib/runners/planner.js";
import { runExecution } from "../lib/runners/execution.js";
import { runGodotTests, captureBaseline } from "../lib/runners/testing.js";
import { runCommunication } from "../lib/runners/communication.js";
import { subscribe, getLogBuffer } from "../lib/log-bus.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function packageRoot(): string {
  return join(__dirname, "../..");
}

async function buildServer() {
  const app = Fastify({ logger: true });
  await app.register(cors, { origin: true });

  const staticRoot = join(packageRoot(), "dist", "client");
  const assetsRoot = join(staticRoot, "assets");

  /** Do not register @fastify/static on `/` — it adds broad GET handlers that can still win over `/api/*`. Serve `/assets/*` and `/` explicitly instead. */

  app.get("/api/health", async () => ({ ok: true }));

  app.get("/api/config", async () => {
    resetConfigCache();
    const c = loadConfig();
    const resolved = resolveCursorCommand(c.cursorCli.command);
    return {
      repoRoot: c.repoRoot,
      worktreeParentDir: c.worktreeParentDir,
      dryRun: c.dryRun,
      limits: c.limits,
      hasGodotPath: Boolean(c.godotPath),
      cursorCliResolved: describeCursorResolution(resolved),
      cursorCliFoundOnDisk: isCursorCliPathRunnable(resolved),
    };
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
    const problem = (req.body?.problem ?? "").trim();
    const max =
      req.body?.maxParallelWorktrees ?? cfg.limits.maxParallelWorktrees;
    const run = createRun(problem || "Describe your goal in the Problem step.", max);
    return reply.code(201).send(run);
  });

  app.get<{
    Params: { id: string };
  }>("/api/runs/:id", async (req, reply) => {
    const run = getRun(req.params.id);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    return run;
  });

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
    Body: { runId?: string };
  }>("/api/pipeline/start", async (req, reply) => {
    const runId =
      typeof req.body?.runId === "string" ? req.body.runId.trim() : "";
    if (!runId) {
      return reply.code(400).send({ error: "runId required" });
    }
    const run = getRun(runId);
    if (!run) return reply.code(404).send({ error: "Run not found" });
    resetConfigCache();
    try {
      startPipelineJob(runId);
      return reply.code(202).send({
        runId,
        message: "Pipeline started",
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
    const outcome = performAssignNext(run);
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
      const updated = await runGodotTests(run, task, task.assignedWorktreePath);
      return updated;
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
