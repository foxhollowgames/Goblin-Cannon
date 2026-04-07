import { mkdirSync } from "node:fs";
import { loadConfig } from "./config.js";
import {
  canAssignWorktree,
  nextAssignableTask,
  acquireRunLock,
  releaseRunLock,
} from "./orchestrator.js";
import { createWorktree } from "./worktree.js";
import { newId, appendOutcome, touchRun, updateTask, getRun } from "./store.js";
import { enqueueExclusive } from "./async-queue.js";
import type { Task, RunState } from "./types.js";

/**
 * Assigns the next ready task to a new git worktree. Mutates persisted run state.
 * Serialized per run so parallel pipeline workers cannot claim the same task.
 */
export async function performAssignNext(
  run: RunState
): Promise<{ ok: true; task: Task } | { ok: false; error: string }> {
  return enqueueExclusive(`assign:${run.id}`, async () => {
    const cfg = loadConfig();
    const state = getRun(run.id);
    if (!state) return { ok: false, error: "Run not found" };

    const cap = canAssignWorktree(state);
    if (!cap.ok) return { ok: false, error: cap.reason ?? "Cannot assign" };

    const task = nextAssignableTask(state);
    if (!task) return { ok: false, error: "No pending task ready" };

    try {
      mkdirSync(cfg.worktreeParentDir, { recursive: true });
      acquireRunLock(state, "assign");
      touchRun(state);
      const wt = createWorktree(cfg.repoRoot, cfg.worktreeParentDir, task.id);
      if (!wt.ok) {
        releaseRunLock(state);
        touchRun(state);
        return { ok: false, error: wt.error ?? "git worktree add failed" };
      }
      state.activeWorktreePaths.push(wt.path);
      updateTask(state, task.id, {
        status: "assigned",
        assignedWorktreePath: wt.path,
        branchName: wt.branch,
      });
      appendOutcome(state, {
        id: newId("out"),
        kind: "orchestrator",
        at: new Date().toISOString(),
        summary: `Assigned task "${task.title}" to worktree ${wt.path} (branch ${wt.branch})`,
        metadata: { path: wt.path, branch: wt.branch, taskId: task.id },
      });
      releaseRunLock(state);
      const assigned = getRun(state.id)?.backlog.find((x: Task) => x.id === task.id);
      if (!assigned) {
        return { ok: false, error: "Task missing after assign" };
      }
      return { ok: true, task: assigned };
    } catch (e) {
      releaseRunLock(state);
      touchRun(state);
      return {
        ok: false,
        error: e instanceof Error ? e.message : String(e),
      };
    }
  });
}
