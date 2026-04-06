import type { RunState, Task, TaskStatus } from "./types.js";
import { loadConfig } from "./config.js";

export function depsSatisfied(task: Task, backlog: Task[]): boolean {
  if (!task.dependsOn?.length) return true;
  const byId = new Map(backlog.map((t) => [t.id, t]));
  for (const dep of task.dependsOn) {
    const d = byId.get(dep);
    if (!d || d.status !== "done") return false;
  }
  return true;
}

export function nextAssignableTask(run: RunState): Task | undefined {
  for (const t of run.backlog) {
    if (t.status !== "pending") continue;
    if (depsSatisfied(t, run.backlog)) return t;
  }
  return undefined;
}

export function canAssignWorktree(run: RunState): {
  ok: boolean;
  reason?: string;
} {
  const cfg = loadConfig();
  const limit = run.limits.maxParallelWorktrees;
  const active = run.activeWorktreePaths.length;
  if (active >= limit) {
    return {
      ok: false,
      reason: `At worktree capacity (${active}/${limit}). Remove a worktree or raise maxParallelWorktrees in config.`,
    };
  }
  if (run.runLock) {
    return {
      ok: false,
      reason: `Run lock held by ${run.runLock.holder} since ${run.runLock.since}`,
    };
  }
  return { ok: true };
}

export function acquireRunLock(run: RunState, holder: string): RunState {
  run.runLock = { holder, since: new Date().toISOString() };
  return run;
}

export function releaseRunLock(run: RunState): RunState {
  delete run.runLock;
  return run;
}

export function countByStatus(run: RunState, status: TaskStatus): number {
  return run.backlog.filter((t) => t.status === status).length;
}
