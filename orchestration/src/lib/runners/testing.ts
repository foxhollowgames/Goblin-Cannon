import { spawn } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { loadConfig } from "../config.js";
import type { Task, RunState } from "../types.js";
import { newId, appendOutcome, touchRun, updateTask, getRun } from "../store.js";
import { finalizeTaskAfterGodotTests } from "../task-merge.js";
import { publish } from "../log-bus.js";
import {
  registerPipelineChild,
  clearPipelineChild,
  isPipelineCancelled,
} from "../pipeline-controller.js";
import { killChildProcessGracefully } from "../kill-child-process.js";

const LOG_TAIL = 12_000;

function assertGodotExecutable(godotPath: string): void {
  if (!existsSync(godotPath)) {
    throw new Error(
      `Godot not found at: ${godotPath}. Set environment variable GODOT_PATH to your Godot.exe, or set godotPath in orchestration.config.local.json (copy from orchestration.config.example.json).`
    );
  }
  try {
    if (!statSync(godotPath).isFile()) {
      throw new Error(`Godot path is not a file: ${godotPath}`);
    }
  } catch (e) {
    if (e instanceof Error && e.message.startsWith("Godot")) throw e;
    throw new Error(`Cannot read Godot path: ${godotPath}`);
  }
}

/**
 * Fresh `git worktree` checkouts have no `.godot/`. Headless runs then parse scripts
 * before `class_name` globals are registered → "Could not find type X in the current scope."
 * Copy minimal cache files from the main clone (paths are `res://`, portable).
 */
function seedWorktreeGodotClassCache(
  repoRoot: string,
  worktreeRoot: string,
  onLog: (line: string) => void
): void {
  const a = repoRoot.replace(/[/\\]+$/, "");
  const b = worktreeRoot.replace(/[/\\]+$/, "");
  if (a === b) return;
  const srcGodot = join(repoRoot, ".godot");
  const dstGodot = join(worktreeRoot, ".godot");
  const files = ["global_script_class_cache.cfg", "extension_list.cfg"] as const;
  let n = 0;
  for (const f of files) {
    const src = join(srcGodot, f);
    const dst = join(dstGodot, f);
    if (existsSync(src)) {
      mkdirSync(dstGodot, { recursive: true });
      copyFileSync(src, dst);
      n++;
    }
  }
  if (n > 0) {
    onLog(
      `--- Seeded worktree .godot (${n} files) from main repo — fresh worktrees lack Godot global class cache. ---\n`
    );
  }
}

function parseTestSummary(stdout: string): string | undefined {
  const lines = stdout.split("\n");
  for (const line of lines) {
    if (line.includes("Total:") && line.includes("passed")) {
      return line.trim();
    }
  }
  return undefined;
}

export async function runGodotTests(
  run: RunState,
  task: Task,
  worktreeRoot: string,
  pipelineRunId?: string
): Promise<RunState> {
  const cfg = loadConfig();
  if (!cfg.godotPath) {
    throw new Error(
      "GODOT_PATH or godotPath in orchestration.config.local.json is required for tests."
    );
  }
  if (pipelineRunId && isPipelineCancelled(pipelineRunId)) {
    run.phase = "orchestrating";
    delete run.currentTaskId;
    touchRun(run);
    return run;
  }
  run.phase = "testing";
  run.currentTaskId = task.id;
  touchRun(run);
  publish(run.id, `--- Testing: Godot headless in worktree ---\n`);

  const args = ["--headless", "-s", "tests/run_tests.gd"];
  assertGodotExecutable(cfg.godotPath);
  seedWorktreeGodotClassCache(cfg.repoRoot, worktreeRoot, (line) =>
    publish(run.id, line)
  );

  if (cfg.dryRun) {
    publish(
      run.id,
      `[dry-run] ${cfg.godotPath} ${args.join(" ")} (cwd=${worktreeRoot})\n`
    );
    appendOutcome(run, {
      id: newId("out"),
      kind: "testing",
      taskId: task.id,
      at: new Date().toISOString(),
      exitCode: 0,
      summary: "[dry-run] Skipped Godot",
      metadata: { dryRun: true },
    });
    updateTask(run, task.id, { status: "done" });
    await finalizeTaskAfterGodotTests(run.id, task.id, true);
    const dryAfter = getRun(run.id) ?? run;
    dryAfter.phase = "orchestrating";
    delete dryAfter.currentTaskId;
    touchRun(dryAfter);
    return dryAfter;
  }

  return new Promise((resolvePromise, reject) => {
    const child = spawn(cfg.godotPath, args, {
      cwd: worktreeRoot,
      stdio: ["ignore", "pipe", "pipe"],
      shell: false,
      env: { ...process.env },
    });
    if (pipelineRunId) registerPipelineChild(pipelineRunId, child);
    let stdout = "";
    let stderr = "";
    let killedByTimeout = false;
    let timeoutId: ReturnType<typeof setTimeout> | undefined;
    const timeoutMs = cfg.godotHeadlessTimeoutMs;
    if (timeoutMs > 0) {
      timeoutId = setTimeout(() => {
        killedByTimeout = true;
        publish(
          run.id,
          `--- Godot tests: exceeded godotHeadlessTimeoutMs (${timeoutMs}ms) — terminating so the pipeline does not hang ---\n`
        );
        killChildProcessGracefully(child, {
          onLog: (m) => publish(run.id, m),
        });
      }, timeoutMs);
    }
    child.stdout?.on("data", (b: Buffer) => {
      const s = b.toString("utf8");
      stdout += s;
      publish(run.id, s);
    });
    child.stderr?.on("data", (b: Buffer) => {
      const s = b.toString("utf8");
      stderr += s;
      publish(run.id, s);
    });
    child.on("error", (err) => {
      if (timeoutId !== undefined) clearTimeout(timeoutId);
      if (pipelineRunId) clearPipelineChild(pipelineRunId);
      reject(err);
    });
    child.on("close", (code) => {
      void (async () => {
        if (timeoutId !== undefined) clearTimeout(timeoutId);
        if (pipelineRunId) clearPipelineChild(pipelineRunId);
        const exitCode =
          killedByTimeout || code === null ? 1 : (code ?? 1);
        const summaryLine = parseTestSummary(stdout);
        const pass = exitCode === 0 && !killedByTimeout;
        const meta: Record<string, unknown> = {};
        if (summaryLine) meta.summaryLine = summaryLine;
        if (killedByTimeout) meta.killedByTimeout = true;
        if (run.baselineTestSummary && summaryLine) {
          meta.baseline = run.baselineTestSummary;
          meta.regressionHint =
            summaryLine === run.baselineTestSummary
              ? "same as baseline"
              : "differs from baseline — review";
        }
        updateTask(run, task.id, {
          status: pass ? "done" : "failed",
        });
        appendOutcome(run, {
          id: newId("out"),
          kind: "testing",
          taskId: task.id,
          at: new Date().toISOString(),
          exitCode,
          summary: killedByTimeout
            ? `Tests aborted: Godot exceeded godotHeadlessTimeoutMs (${timeoutMs}ms) — fix hangs locally or raise timeout in config`
            : pass
              ? `Tests passed (${summaryLine ?? "exit 0"})`
              : `Tests failed (${summaryLine ?? "exit " + exitCode})`,
          logTail: (stdout + "\n" + stderr).slice(-LOG_TAIL),
          metadata: meta,
        });
        await finalizeTaskAfterGodotTests(run.id, task.id, pass);
        const after = getRun(run.id) ?? run;
        after.phase = "orchestrating";
        delete after.currentTaskId;
        touchRun(after);
        resolvePromise(after);
      })().catch(reject);
    });
  });
}

/** Capture baseline summary from main repo (tests on repo root). */
export async function captureBaseline(
  run: RunState,
  pipelineRunId?: string
): Promise<RunState> {
  const cfg = loadConfig();
  if (!cfg.godotPath) {
    throw new Error("godotPath not configured for baseline.");
  }
  publish(run.id, "--- Baseline: running tests on main repo ---\n");
  assertGodotExecutable(cfg.godotPath);

  if (cfg.dryRun) {
    run.baselineTestSummary = "[dry-run] baseline not captured";
    touchRun(run);
    return run;
  }
  return new Promise((resolvePromise, reject) => {
    const child = spawn(cfg.godotPath, ["--headless", "-s", "tests/run_tests.gd"], {
      cwd: cfg.repoRoot,
      stdio: ["ignore", "pipe", "pipe"],
      shell: false,
    });
    if (pipelineRunId) registerPipelineChild(pipelineRunId, child);
    let stdout = "";
    let killedByTimeout = false;
    let timeoutId: ReturnType<typeof setTimeout> | undefined;
    const timeoutMs = cfg.godotHeadlessTimeoutMs;
    if (timeoutMs > 0) {
      timeoutId = setTimeout(() => {
        killedByTimeout = true;
        publish(
          run.id,
          `--- Baseline Godot: exceeded godotHeadlessTimeoutMs (${timeoutMs}ms) — terminating ---\n`
        );
        killChildProcessGracefully(child, {
          onLog: (m) => publish(run.id, m),
        });
      }, timeoutMs);
    }
    child.stdout?.on("data", (b: Buffer) => {
      stdout += b.toString("utf8");
    });
    child.stderr?.on("data", (b: Buffer) => {
      publish(run.id, b.toString("utf8"));
    });
    child.on("error", (err) => {
      if (timeoutId !== undefined) clearTimeout(timeoutId);
      if (pipelineRunId) clearPipelineChild(pipelineRunId);
      reject(err);
    });
    child.on("close", () => {
      if (timeoutId !== undefined) clearTimeout(timeoutId);
      if (pipelineRunId) clearPipelineChild(pipelineRunId);
      if (killedByTimeout) {
        run.baselineTestSummary =
          "[timeout] baseline Godot exceeded godotHeadlessTimeoutMs — compare worktree tests manually";
      } else {
        const line = parseTestSummary(stdout);
        run.baselineTestSummary = line ?? stdout.slice(-2000);
      }
      touchRun(run);
      resolvePromise(run);
    });
  });
}
