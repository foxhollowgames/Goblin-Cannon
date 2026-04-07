import { getRun, touchRun } from "./store.js";
import { publish } from "./log-bus.js";
import { runPlanner } from "./runners/planner.js";
import { runExecution } from "./runners/execution.js";
import { runGodotTests, captureBaseline } from "./runners/testing.js";
import { runCommunication } from "./runners/communication.js";
import { performAssignNext } from "./assign-next.js";
import { nextAssignableTask } from "./orchestrator.js";
import {
  beginPipelineRun,
  endPipelineRun,
  isPipelineCancelled,
  isPipelineRunning,
} from "./pipeline-controller.js";
import { loadConfig, resetConfigCache } from "./config.js";
import type { PipelineStatus } from "./types.js";

function pipelineFinish(
  runId: string,
  status: PipelineStatus,
  message: string
): void {
  const r = getRun(runId);
  if (!r) return;
  r.pipelineStatus = status;
  r.pipelineMessage = message;
  r.phase = "idle";
  delete r.currentTaskId;
  touchRun(r);
  publish(runId, `\n--- Pipeline ${status}: ${message} ---\n`);
}

export type PipelineStartMode = "full" | "fromBacklogOnly";

async function executePipeline(
  runId: string,
  mode: PipelineStartMode = "full"
): Promise<void> {
  resetConfigCache();
  let run = getRun(runId);
  if (!run) {
    publish(
      runId,
      `ERROR: Run ${runId} not found in persisted state (data/state.json). Pipeline aborted.\n`
    );
    return;
  }
  run.pipelineStatus = "running";
  run.pipelineMessage =
    mode === "fromBacklogOnly"
      ? "Resuming backlog (skipping planner)…"
      : "Starting automated pipeline…";
  touchRun(run);
  publish(
    runId,
    mode === "fromBacklogOnly"
      ? "--- Backlog-only pipeline started (skipping planner) ---\n"
      : "--- Automated pipeline started ---\n"
  );

  try {
    const cfg = loadConfig();
    if (mode === "full" && cfg.godotPath) {
      run = getRun(runId)!;
      run.pipelineMessage = "Capturing test baseline on main repo…";
      touchRun(run);
      try {
        await captureBaseline(run, runId);
      } catch (e) {
        publish(
          runId,
          `Baseline skipped: ${e instanceof Error ? e.message : String(e)}\n`
        );
      }
    }

    if (isPipelineCancelled(runId)) {
      pipelineFinish(runId, "stopped", "Stopped by user");
      return;
    }

    run = getRun(runId)!;
    if (mode === "full") {
      run.pipelineMessage = "Running planner (Cursor CLI)…";
      touchRun(run);
      await runPlanner(run, runId);

      if (isPipelineCancelled(runId)) {
        pipelineFinish(runId, "stopped", "Stopped by user");
        return;
      }

      run = getRun(runId)!;
    }
    if (!run.backlog.length) {
      run.pipelineMessage = "No tasks planned; generating report…";
      touchRun(run);
      await runCommunication(run, runId);
      run = getRun(runId)!;
      const plannerOutcome = [...run.outcomes]
        .reverse()
        .find((o) => o.kind === "planner");
      const detail = plannerOutcome?.summary
        ? ` — ${plannerOutcome.summary.slice(0, 500)}`
        : "";
      pipelineFinish(
        runId,
        "completed",
        `Done (no tasks)${detail}`
      );
      return;
    }

    const maxParallel = Math.max(1, getRun(runId)!.limits.maxParallelWorktrees);
    const inFlight = new Set<Promise<void>>();
    let pipelineAbort: string | undefined;

    const runOneTask = async (taskId: string): Promise<void> => {
      const r0 = getRun(runId);
      if (!r0 || pipelineAbort) return;
      const execTask = r0.backlog.find((x) => x.id === taskId);
      if (!execTask) return;

      r0.pipelineMessage = `Executing: ${execTask.title}`;
      touchRun(r0);

      const execResult = await runExecution(r0, execTask, runId);
      if (execResult.pipelineAbort) {
        pipelineAbort = execResult.pipelineAbort;
        return;
      }

      if (isPipelineCancelled(runId)) return;

      const afterExec = getRun(runId)?.backlog.find((x) => x.id === taskId);
      if (!afterExec) return;
      if (afterExec.status === "failed") {
        pipelineAbort = "Execution agent failed (non-zero exit)";
        return;
      }

      if (afterExec.status === "testing" && afterExec.assignedWorktreePath) {
        const r1 = getRun(runId);
        if (r1) {
          r1.pipelineMessage = `Testing: ${afterExec.title}`;
          touchRun(r1);
        }
        await runGodotTests(
          getRun(runId)!,
          afterExec,
          afterExec.assignedWorktreePath,
          runId
        );
      }

      const afterTest = getRun(runId)?.backlog.find((x) => x.id === taskId);
      if (afterTest?.status === "failed") {
        pipelineAbort = "Task failed (Godot tests or auto-merge after tests)";
      }
    };

    while (!pipelineAbort && !isPipelineCancelled(runId)) {
      while (
        inFlight.size < maxParallel &&
        !pipelineAbort &&
        !isPipelineCancelled(runId)
      ) {
        const assign = await performAssignNext(getRun(runId)!);
        if (!assign.ok) {
          if (assign.error.includes("No pending task ready")) {
            break;
          }
          pipelineAbort = assign.error;
          break;
        }
        const p = runOneTask(assign.task.id);
        inFlight.add(p);
        void p.finally(() => inFlight.delete(p));
      }

      const snapshot = getRun(runId)!;
      if (inFlight.size === 0 && !nextAssignableTask(snapshot)) {
        break;
      }

      if (inFlight.size > 0) {
        await Promise.race(inFlight);
      } else {
        break;
      }
    }

    await Promise.allSettled(Array.from(inFlight));

    if (isPipelineCancelled(runId)) {
      pipelineFinish(runId, "stopped", "Stopped by user");
      return;
    }

    if (pipelineAbort) {
      pipelineFinish(runId, "failed", pipelineAbort);
      return;
    }

    run = getRun(runId)!;
    run.pipelineMessage = "Generating report (Cursor CLI)…";
    touchRun(run);
    await runCommunication(run, runId);

    pipelineFinish(
      runId,
      "completed",
      mode === "fromBacklogOnly"
        ? "Backlog steps finished"
        : "All automated steps finished"
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const r = getRun(runId);
    if (r) {
      r.pipelineStatus = "failed";
      r.pipelineMessage = msg;
      r.phase = "idle";
      delete r.currentTaskId;
      touchRun(r);
    }
    publish(runId, `\n--- Pipeline failed: ${msg} ---\n`);
  }
}

export function startPipelineJob(
  runId: string,
  mode: PipelineStartMode = "full"
): void {
  if (!getRun(runId)) throw new Error("Run not found");
  if (isPipelineRunning(runId)) throw new Error("Pipeline already running");
  beginPipelineRun(runId);
  void executePipeline(runId, mode).finally(() => endPipelineRun(runId));
}

export { isPipelineRunning, stopPipelineRun } from "./pipeline-controller.js";
