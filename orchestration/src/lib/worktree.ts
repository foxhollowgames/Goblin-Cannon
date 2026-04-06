import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

function git(
  repoRoot: string,
  args: string[],
  opts?: { input?: string }
): { ok: boolean; stdout: string; stderr: string; status: number | null } {
  const r = spawnSync("git", ["-C", repoRoot, ...args], {
    encoding: "utf8",
    input: opts?.input,
    maxBuffer: 20 * 1024 * 1024,
  });
  return {
    ok: r.status === 0,
    stdout: r.stdout ?? "",
    stderr: r.stderr ?? "",
    status: r.status,
  };
}

export function slugTaskId(taskId: string): string {
  return taskId.replace(/[^a-zA-Z0-9_-]+/g, "-").slice(0, 48);
}

export function worktreeFolderName(taskId: string): string {
  return `goblin-cannon-agent-${slugTaskId(taskId)}`;
}

export function worktreePath(
  worktreeParentDir: string,
  taskId: string
): string {
  return join(worktreeParentDir, worktreeFolderName(taskId));
}

export function branchNameForTask(taskId: string): string {
  return `agent/task-${slugTaskId(taskId)}`;
}

export function createWorktree(
  repoRoot: string,
  worktreeParentDir: string,
  taskId: string
): { ok: boolean; path: string; branch: string; error?: string } {
  const path = worktreePath(worktreeParentDir, taskId);
  const branch = branchNameForTask(taskId);
  if (existsSync(path)) {
    return {
      ok: false,
      path,
      branch,
      error: `Worktree path already exists: ${path}`,
    };
  }
  const add = git(repoRoot, [
    "worktree",
    "add",
    path,
    "-b",
    branch,
    "HEAD",
  ]);
  if (!add.ok) {
    return {
      ok: false,
      path,
      branch,
      error: add.stderr || add.stdout || `git worktree add failed (${add.status})`,
    };
  }
  return { ok: true, path, branch };
}

export function removeWorktree(
  repoRoot: string,
  worktreePathArg: string,
  deleteBranch: boolean,
  branchName?: string
): { ok: boolean; error?: string } {
  const rm = git(repoRoot, ["worktree", "remove", "--force", worktreePathArg]);
  if (!rm.ok) {
    return {
      ok: false,
      error: rm.stderr || rm.stdout || `git worktree remove failed (${rm.status})`,
    };
  }
  if (deleteBranch && branchName) {
    const br = git(repoRoot, ["branch", "-D", branchName]);
    if (!br.ok) {
      return {
        ok: true,
        error: `Worktree removed; branch delete warning: ${br.stderr || br.stdout}`,
      };
    }
  }
  return { ok: true };
}

export function listWorktrees(repoRoot: string): string {
  const r = git(repoRoot, ["worktree", "list"]);
  return r.ok ? r.stdout : r.stderr;
}

/** Current `HEAD` in a worktree checkout, or null if git failed. */
export function getWorktreeHead(worktreeRoot: string): string | null {
  const r = git(worktreeRoot, ["rev-parse", "HEAD"]);
  return r.ok ? r.stdout.trim() : null;
}

/**
 * After an agent run, detect whether anything changed vs `headBefore` (new commits or dirty tree).
 */
export function worktreeGitDelta(
  worktreeRoot: string,
  headBefore: string
): { changed: boolean; detail: string } {
  const before = headBefore.trim();
  const headAfter = getWorktreeHead(worktreeRoot);
  if (!headAfter) {
    return {
      changed: true,
      detail: "could not re-read HEAD (skipping strict no-op detection)",
    };
  }
  if (headAfter !== before) {
    return {
      changed: true,
      detail: `new commit(s): ${before.slice(0, 7)} → ${headAfter.slice(0, 7)}`,
    };
  }
  const st = git(worktreeRoot, ["status", "--porcelain"]);
  const por = (st.ok ? st.stdout : "").trim();
  if (por.length > 0) {
    return { changed: true, detail: "uncommitted changes in worktree" };
  }
  return { changed: false, detail: "clean tree, same HEAD as before agent" };
}
