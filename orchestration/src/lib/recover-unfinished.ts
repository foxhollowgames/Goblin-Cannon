import type { RunState, Task } from "./types.js";
import { getRun, newId, appendOutcome } from "./store.js";
import { recoverTaskToTestingAndRunTests } from "./recover-task.js";

/** Tasks that `recoverTaskToTestingAndRunTests` can act on (has worktree + status). */
function isRecoverableUnfinished(t: Task): boolean {
  if (t.status === "done") return false;
  if (!t.assignedWorktreePath) return false;
  return (
    t.status === "failed" ||
    t.status === "assigned" ||
    t.status === "testing"
  );
}

export type RecoverUnfinishedResult =
  | {
      ok: true;
      run: RunState;
      attempted: string[];
      skippedLabels: string[];
      failures: { taskId: string; title: string; error: string }[];
    }
  | { ok: false; error: string };

/**
 * For each unfinished task that has a worktree and is failed/assigned/testing, run the same
 * recovery path as single-task recover (Godot tests, status updates). Continues on per-task
 * failure. Pending tasks (no worktree) are skipped — use the pipeline to assign them first.
 */
export async function recoverUnfinishedTasksForRun(
  runId: string
): Promise<RecoverUnfinishedResult> {
  const run = getRun(runId);
  if (!run) return { ok: false, error: "Run not found" };

  const candidates = run.backlog.filter(isRecoverableUnfinished);
  const skippedLabels = run.backlog
    .filter((t) => t.status !== "done" && !isRecoverableUnfinished(t))
    .map((t) => `${t.title} (${t.status})`);

  if (candidates.length === 0) {
    appendOutcome(run, {
      id: newId("out"),
      kind: "orchestrator",
      at: new Date().toISOString(),
      summary:
        `Batch recover: no tasks in recoverable state (need worktree + failed/assigned/testing). ` +
        `Skipped: ${skippedLabels.length ? skippedLabels.join("; ") : "none"}.`,
    });
    const after = getRun(runId);
    return after
      ? {
          ok: true,
          run: after,
          attempted: [],
          skippedLabels,
          failures: [],
        }
      : { ok: false, error: "Run disappeared" };
  }

  const attempted: string[] = [];
  const failures: { taskId: string; title: string; error: string }[] = [];

  for (const task of candidates) {
    const fresh = getRun(runId);
    if (!fresh) return { ok: false, error: "Run disappeared during recovery" };
    const result = await recoverTaskToTestingAndRunTests(fresh, task.id);
    attempted.push(task.id);
    if (!result.ok) {
      failures.push({
        taskId: task.id,
        title: task.title,
        error: result.error,
      });
    }
  }

  const finalRun = getRun(runId);
  if (!finalRun) return { ok: false, error: "Run disappeared" };

  const failSummary =
    failures.length === 0
      ? "none"
      : failures.map((f) => `"${f.title}": ${f.error}`).join("; ");

  appendOutcome(finalRun, {
    id: newId("out"),
    kind: "orchestrator",
    at: new Date().toISOString(),
    summary: `Batch recover finished: ${attempted.length} task(s) attempted, ${failures.length} failure(s). ${failSummary}. Skipped (not recoverable): ${skippedLabels.length ? skippedLabels.join("; ") : "none"}.`,
  });

  const out = getRun(runId);
  return out
    ? {
        ok: true,
        run: out,
        attempted,
        skippedLabels,
        failures,
      }
    : { ok: false, error: "Run disappeared" };
}
