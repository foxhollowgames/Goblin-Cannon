import type { RunState } from "./types.js";
import { getRun, newId, appendOutcome, updateTask } from "./store.js";
import { worktreeHasSubstantiveWork } from "./worktree.js";
import { runGodotTests } from "./runners/testing.js";

/**
 * When execution failed or was stopped but the worktree actually contains work,
 * move the task to testing and run Godot tests (same as an automated success path).
 */
export async function recoverTaskToTestingAndRunTests(
  run: RunState,
  taskId: string
): Promise<{ ok: true; run: RunState } | { ok: false; error: string }> {
  const task = run.backlog.find((t) => t.id === taskId);
  if (!task) return { ok: false, error: "Task not found" };
  if (
    task.status !== "failed" &&
    task.status !== "assigned" &&
    task.status !== "testing"
  ) {
    return {
      ok: false,
      error:
        "Task must be failed, assigned, or testing (use testing to re-run Godot tests in the worktree).",
    };
  }
  if (!task.assignedWorktreePath) {
    return { ok: false, error: "Task has no worktree" };
  }

  if (task.status === "testing") {
    appendOutcome(run, {
      id: newId("out"),
      kind: "orchestrator",
      taskId: task.id,
      at: new Date().toISOString(),
      summary: `Manual recovery: re-run Godot tests for task "${task.title}" (already in testing).`,
    });
    const fresh = getRun(run.id);
    if (!fresh) return { ok: false, error: "Run disappeared" };
    const t2 = fresh.backlog.find((x) => x.id === taskId);
    if (!t2?.assignedWorktreePath) {
      return { ok: false, error: "Task has no worktree after update" };
    }
    await runGodotTests(fresh, t2, t2.assignedWorktreePath);
    const after = getRun(run.id);
    return after ? { ok: true, run: after } : { ok: false, error: "Run disappeared" };
  }

  if (!worktreeHasSubstantiveWork(task.assignedWorktreePath)) {
    return {
      ok: false,
      error:
        "Worktree has no uncommitted changes and no commits ahead of main/master — nothing to validate.",
    };
  }
  updateTask(run, task.id, { status: "testing" });
  appendOutcome(run, {
    id: newId("out"),
    kind: "orchestrator",
    taskId: task.id,
    at: new Date().toISOString(),
    summary: `Manual recovery: task "${task.title}" → testing (worktree has changes), running Godot tests.`,
  });
  const fresh = getRun(run.id);
  if (!fresh) return { ok: false, error: "Run disappeared" };
  const t2 = fresh.backlog.find((x) => x.id === taskId);
  if (!t2?.assignedWorktreePath) {
    return { ok: false, error: "Task has no worktree after update" };
  }
  await runGodotTests(fresh, t2, t2.assignedWorktreePath);
  const after = getRun(run.id);
  return after ? { ok: true, run: after } : { ok: false, error: "Run disappeared" };
}
