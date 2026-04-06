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
import { loadConfig } from "./config.js";
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

async function executePipeline(runId: string): Promise<void> {
  let run = getRun(runId);
  if (!run) {
    publish(
      runId,
      `ERROR: Run ${runId} not found in persisted state (data/state.json). Pipeline aborted.\n`
    );
    return;
  }
  run.pipelineStatus = "running";
  run.pipelineMessage = "Starting automated pipeline…";
  touchRun(run);
  publish(runId, "--- Automated pipeline started ---\n");

  try {
    const cfg = loadConfig();
    if (cfg.godotPath) {
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
    run.pipelineMessage = "Running planner (Cursor CLI)…";
    touchRun(run);
    await runPlanner(run, runId);

    if (isPipelineCancelled(runId)) {
      pipelineFinish(runId, "stopped", "Stopped by user");
      return;
    }

    run = getRun(runId)!;
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

    while (true) {
      if (isPipelineCancelled(runId)) {
        pipelineFinish(runId, "stopped", "Stopped by user");
        return;
      }

      run = getRun(runId)!;
      const task = nextAssignableTask(run);
      if (!task) break;

      run.pipelineMessage = `Assigning worktree: ${task.title}`;
      touchRun(run);
      const assign = performAssignNext(run);
      if (!assign.ok) {
        pipelineFinish(runId, "failed", assign.error);
        return;
      }

      run = getRun(runId)!;
      const execTask = run.backlog.find((x) => x.id === assign.task.id);
      if (!execTask) break;

      run.pipelineMessage = `Executing: ${execTask.title}`;
      touchRun(run);
      const execResult = await runExecution(run, execTask, runId);
      if (execResult.pipelineAbort) {
        pipelineFinish(runId, "failed", execResult.pipelineAbort);
        return;
      }

      if (isPipelineCancelled(runId)) {
        pipelineFinish(runId, "stopped", "Stopped by user");
        return;
      }

      run = getRun(runId)!;
      const afterExec = run.backlog.find((x) => x.id === execTask.id);
      if (!afterExec) break;
      if (afterExec.status === "failed") {
        pipelineFinish(
          runId,
          "failed",
          "Execution agent failed (non-zero exit)"
        );
        return;
      }

      if (afterExec.status === "testing" && afterExec.assignedWorktreePath) {
        run.pipelineMessage = `Testing: ${afterExec.title}`;
        touchRun(run);
        await runGodotTests(
          run,
          afterExec,
          afterExec.assignedWorktreePath,
          runId
        );
      }

      run = getRun(runId)!;
      const afterTest = run.backlog.find((x) => x.id === execTask.id);
      if (afterTest?.status === "failed") {
        pipelineFinish(runId, "failed", "Godot tests failed");
        return;
      }
    }

    if (isPipelineCancelled(runId)) {
      pipelineFinish(runId, "stopped", "Stopped by user");
      return;
    }

    run = getRun(runId)!;
    run.pipelineMessage = "Generating report (Cursor CLI)…";
    touchRun(run);
    await runCommunication(run, runId);

    pipelineFinish(runId, "completed", "All automated steps finished");
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

export function startPipelineJob(runId: string): void {
  if (!getRun(runId)) throw new Error("Run not found");
  if (isPipelineRunning(runId)) throw new Error("Pipeline already running");
  beginPipelineRun(runId);
  void executePipeline(runId).finally(() => endPipelineRun(runId));
}

export { isPipelineRunning, stopPipelineRun } from "./pipeline-controller.js";
