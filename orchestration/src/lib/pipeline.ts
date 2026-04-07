import {
  collectReferencedWorktreePaths,
  getRun,
  touchRun,
  updateTask,
} from "./store.js";
import { publish } from "./log-bus.js";
import { runPlanner } from "./runners/planner.js";
import {
  runExecution,
  type TestFailureRetryContext,
} from "./runners/execution.js";
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
import { pruneUnreferencedAgentWorktrees } from "./worktree.js";
import type { Outcome, PipelineStatus, RunState } from "./types.js";

function latestTestingOutcomeForTask(
  run: RunState,
  taskId: string
): Outcome | undefined {
  for (let i = run.outcomes.length - 1; i >= 0; i--) {
    const o = run.outcomes[i]!;
    if (o.kind === "testing" && o.taskId === taskId) return o;
  }
  return undefined;
}

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
    if (!cfg.dryRun) {
      const pr = pruneUnreferencedAgentWorktrees(
        cfg.repoRoot,
        cfg.worktreeParentDir,
        collectReferencedWorktreePaths()
      );
      if (pr.removed.length > 0) {
        publish(
          runId,
          `--- Pruned ${pr.removed.length} unreferenced agent worktree folder(s) (no persisted task references them). ---\n`
        );
      }
      if (pr.warnings.length > 0) {
        for (const w of pr.warnings.slice(0, 16)) {
          publish(runId, `--- Prune: ${w} ---\n`);
        }
      }
    }
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
      const cfgTask = loadConfig();
      const unlimitedFixRetries = cfgTask.godotTestFixRetries < 0;
      const maxRounds = unlimitedFixRetries
        ? Number.POSITIVE_INFINITY
        : Math.max(1, 1 + Math.max(0, cfgTask.godotTestFixRetries));
      let testFailureRetry: TestFailureRetryContext | undefined;
      let round = 0;

      while (true) {
        round += 1;
        const rLoop = getRun(runId);
        if (!rLoop || pipelineAbort) return;
        const loopTask = rLoop.backlog.find((x) => x.id === taskId);
        if (!loopTask?.assignedWorktreePath) return;

        const roundLabel = unlimitedFixRetries
          ? `${round} (∞)`
          : `${round}/${maxRounds}`;
        rLoop.pipelineMessage =
          round === 1
            ? `Executing: ${loopTask.title}`
            : `Fix retry ${roundLabel}: ${loopTask.title}`;
        touchRun(rLoop);

        const execResult = await runExecution(
          rLoop,
          loopTask,
          runId,
          testFailureRetry ? { testFailureRetry } : undefined
        );
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

        if (afterExec.status !== "testing" || !afterExec.assignedWorktreePath) {
          return;
        }

        const r1 = getRun(runId);
        if (r1) {
          const testRoundLabel =
            unlimitedFixRetries || maxRounds > 1
              ? unlimitedFixRetries
                ? ` (${round}, ∞)`
                : ` (${round}/${maxRounds})`
              : "";
          r1.pipelineMessage = `Testing: ${afterExec.title}${testRoundLabel}`;
          touchRun(r1);
        }

        const testRes = await runGodotTests(
          getRun(runId)!,
          afterExec,
          afterExec.assignedWorktreePath,
          runId,
          {
            retainWorktreeSlotOnFailure:
              unlimitedFixRetries || round < maxRounds,
          }
        );

        if (testRes.pass) {
          return;
        }

        if (testRes.killedByTimeout) {
          pipelineAbort =
            "Godot tests exceeded godotHeadlessTimeoutMs — automated retries are skipped for timeouts. Fix the hang or raise the timeout.";
          return;
        }

        if (!unlimitedFixRetries && round >= maxRounds) {
          pipelineAbort =
            "Task failed — Godot tests did not pass after automated fix retries. See testing outcomes in the log.";
          return;
        }

        const fresh = getRun(runId);
        if (!fresh) return;
        const outcome = latestTestingOutcomeForTask(fresh, taskId);
        updateTask(fresh, taskId, { status: "testing" });
        touchRun(fresh);

        testFailureRetry = {
          executionRound: round + 1,
          maxRounds,
          outcomeSummary: outcome?.summary ?? "(no summary)",
          logExcerpt: outcome?.logTail ?? "",
          killedByTimeout: false,
        };

        const nextLabel = unlimitedFixRetries
          ? `${round + 1} (∞)`
          : `${round + 1}/${maxRounds}`;
        publish(
          runId,
          `\n--- Godot tests failed — automated fix retry, execution round ${nextLabel} ---\n`
        );
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
