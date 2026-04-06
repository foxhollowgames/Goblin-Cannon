import { mkdirSync } from "node:fs";
import { loadConfig } from "./config.js";
import {
  canAssignWorktree,
  nextAssignableTask,
  acquireRunLock,
  releaseRunLock,
} from "./orchestrator.js";
import { createWorktree } from "./worktree.js";
import { newId, appendOutcome, touchRun, updateTask } from "./store.js";
import type { Task, RunState } from "./types.js";

/**
 * Assigns the next ready task to a new git worktree. Mutates `run`.
 */
export function performAssignNext(
  run: RunState
): { ok: true; task: Task } | { ok: false; error: string } {
  const cfg = loadConfig();
  const cap = canAssignWorktree(run);
  if (!cap.ok) return { ok: false, error: cap.reason ?? "Cannot assign" };
  const task = nextAssignableTask(run);
  if (!task) return { ok: false, error: "No pending task ready" };
  try {
    mkdirSync(cfg.worktreeParentDir, { recursive: true });
    acquireRunLock(run, "assign");
    const wt = createWorktree(cfg.repoRoot, cfg.worktreeParentDir, task.id);
    if (!wt.ok) {
      releaseRunLock(run);
      touchRun(run);
      return { ok: false, error: wt.error ?? "git worktree add failed" };
    }
    run.activeWorktreePaths.push(wt.path);
    updateTask(run, task.id, {
      status: "assigned",
      assignedWorktreePath: wt.path,
      branchName: wt.branch,
    });
    appendOutcome(run, {
      id: newId("out"),
      kind: "orchestrator",
      at: new Date().toISOString(),
      summary: `Assigned task "${task.title}" to worktree ${wt.path} (branch ${wt.branch})`,
      metadata: { path: wt.path, branch: wt.branch, taskId: task.id },
    });
    releaseRunLock(run);
    const assigned = run.backlog.find((x: Task) => x.id === task.id)!;
    return { ok: true, task: assigned };
  } catch (e) {
    releaseRunLock(run);
    return {
      ok: false,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}
