import { spawnSync } from "node:child_process";
import { existsSync, rmSync } from "node:fs";
import { basename, join, resolve } from "node:path";

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

/** Only paths under this folder name pattern may get a filesystem fallback delete (never arbitrary dirs). */
export function isAgentWorktreeFolderName(name: string): boolean {
  return name.startsWith("goblin-cannon-agent-");
}

function removeAgentWorktreeDirIfPresent(absPath: string): string | undefined {
  if (!existsSync(absPath)) return undefined;
  const base = basename(absPath);
  if (!isAgentWorktreeFolderName(base)) {
    return `refusing non-agent path for fs cleanup: ${absPath}`;
  }
  try {
    rmSync(absPath, { recursive: true, force: true });
  } catch (e) {
    return e instanceof Error ? e.message : String(e);
  }
  return existsSync(absPath) ? `directory still exists after rm: ${absPath}` : undefined;
}

/**
 * Remove a registered git worktree, then delete the branch if requested.
 * Retries after `git worktree prune`. If the directory still exists (Windows sync, etc.),
 * removes it only when the folder name matches `goblin-cannon-agent-*`.
 */
export function removeWorktree(
  repoRoot: string,
  worktreePathArg: string,
  deleteBranch: boolean,
  branchName?: string
): { ok: boolean; error?: string } {
  const repo = resolve(repoRoot);
  const absWt = resolve(worktreePathArg);
  const tryGitRemove = (): { ok: boolean; err: string } => {
    const rm = git(repo, ["worktree", "remove", "--force", absWt]);
    if (rm.ok) return { ok: true, err: "" };
    return {
      ok: false,
      err: rm.stderr || rm.stdout || `git worktree remove failed (${rm.status})`,
    };
  };

  let first = tryGitRemove();
  if (!first.ok) {
    git(repo, ["worktree", "prune"]);
    first = tryGitRemove();
  }
  if (!first.ok) {
    return { ok: false, error: first.err };
  }

  git(repo, ["worktree", "prune"]);

  let branchWarning: string | undefined;
  if (deleteBranch && branchName) {
    const br = git(repo, ["branch", "-D", branchName]);
    if (!br.ok) {
      branchWarning = `branch delete warning: ${br.stderr || br.stdout}`;
    }
  }

  const fsErr = removeAgentWorktreeDirIfPresent(absWt);
  if (fsErr) {
    return {
      ok: false,
      error: [
        `git removed worktree but folder cleanup failed: ${fsErr}`,
        branchWarning,
      ]
        .filter(Boolean)
        .join(" — "),
    };
  }

  return branchWarning ? { ok: true, error: branchWarning } : { ok: true };
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

/**
 * True if the worktree has uncommitted changes or local commits ahead of `main` / `master`.
 * Used to recover a task marked failed after Stop/timeout when HEAD-before was not persisted.
 */
export function worktreeHasSubstantiveWork(worktreeRoot: string): boolean {
  const por = git(worktreeRoot, ["status", "--porcelain"]);
  if (por.ok && por.stdout.trim().length > 0) return true;
  for (const ref of ["main", "master"] as const) {
    const br = git(worktreeRoot, ["rev-parse", "--verify", ref]);
    if (!br.ok) continue;
    const base = br.stdout.trim();
    const cnt = git(worktreeRoot, ["rev-list", "--count", `${base}..HEAD`]);
    if (cnt.ok && parseInt(cnt.stdout.trim(), 10) > 0) return true;
  }
  return false;
}
