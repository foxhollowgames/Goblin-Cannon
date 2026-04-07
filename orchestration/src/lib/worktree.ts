import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, rmSync } from "node:fs";
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

/**
 * From a folder basename `goblin-cannon-agent-<slug>`, derive the agent branch name
 * (`agent/task-<slug>`) for git cleanup.
 */
export function branchNameFromAgentWorktreeFolder(folderBasename: string): string | null {
  const prefix = "goblin-cannon-agent-";
  if (!folderBasename.startsWith(prefix)) return null;
  const slug = folderBasename.slice(prefix.length);
  if (!slug.length) return null;
  return `agent/task-${slug}`;
}

/** Which branch is the primary branch in this repo (`main` or `master`). */
export function resolvePrimaryBranch(repoRoot: string): "main" | "master" | null {
  const root = resolve(repoRoot);
  for (const b of ["main", "master"] as const) {
    const v = git(root, ["rev-parse", "--verify", b]);
    if (v.ok) return b;
  }
  return null;
}

/**
 * Ensure the **primary** working tree at `repoRoot` is checked out to `main` or `master`.
 * New agent worktrees branch from `HEAD`; the primary checkout should be main before `worktree add`.
 * After cleanup, switch back if the repo was left on `agent/task-*`.
 */
export function ensurePrimaryBranchCheckedOut(repoRoot: string): {
  ok: boolean;
  primary?: "main" | "master";
  switched?: boolean;
  error?: string;
} {
  const root = resolve(repoRoot);
  const primary = resolvePrimaryBranch(root);
  if (!primary) {
    return { ok: false, error: "No main or master branch in repo" };
  }
  const cur = git(root, ["rev-parse", "--abbrev-ref", "HEAD"]);
  if (!cur.ok) {
    return {
      ok: false,
      error: (cur.stderr || cur.stdout || "rev-parse HEAD failed").trim(),
    };
  }
  const name = cur.stdout.trim();
  if (name === primary) {
    return { ok: true, primary, switched: false };
  }
  const co = git(root, ["checkout", primary]);
  if (!co.ok) {
    return {
      ok: false,
      primary,
      error: (co.stderr || co.stdout || `checkout ${primary} failed`).trim(),
    };
  }
  return { ok: true, primary, switched: true };
}

/**
 * Remove leftover agent worktree dirs (e.g. failed run, cleared state) that are not referenced
 * by any persisted task. Uses `deleteBranch: true` so `git worktree add -b …` can recreate the branch.
 */
export function pruneUnreferencedAgentWorktrees(
  repoRoot: string,
  worktreeParentDir: string,
  referencedPaths: Set<string>
): {
  removed: string[];
  warnings: string[];
  /** Present if the primary repo checkout was switched back to main/master. */
  switchedToPrimary?: "main" | "master";
} {
  const removed: string[] = [];
  const warnings: string[] = [];
  const parent = resolve(worktreeParentDir);
  if (!existsSync(parent)) {
    const idle = ensurePrimaryBranchCheckedOut(repoRoot);
    return {
      removed,
      warnings,
      ...(idle.switched && idle.primary
        ? { switchedToPrimary: idle.primary }
        : {}),
    };
  }
  let entries: string[];
  try {
    entries = readdirSync(parent);
  } catch (e) {
    warnings.push(
      `readdir ${parent}: ${e instanceof Error ? e.message : String(e)}`
    );
    const afterErr = ensurePrimaryBranchCheckedOut(repoRoot);
    return {
      removed,
      warnings,
      ...(afterErr.switched && afterErr.primary
        ? { switchedToPrimary: afterErr.primary }
        : {}),
    };
  }
  for (const name of entries) {
    if (!isAgentWorktreeFolderName(name)) continue;
    const full = resolve(parent, name);
    const norm = resolve(full);
    if (referencedPaths.has(norm)) continue;
    const br = branchNameFromAgentWorktreeFolder(name);
    if (!br) {
      warnings.push(`skip ${full}: could not derive branch name`);
      continue;
    }
    const rm = removeWorktree(repoRoot, full, true, br);
    if (rm.ok) {
      removed.push(full);
      if (rm.error) warnings.push(`${full}: ${rm.error}`);
    } else {
      warnings.push(`${full}: ${rm.error ?? "git worktree remove failed"}`);
    }
  }
  const back = ensurePrimaryBranchCheckedOut(repoRoot);
  if (!back.ok && back.error) {
    warnings.push(`ensurePrimaryBranchCheckedOut: ${back.error}`);
  }
  return {
    removed,
    warnings,
    ...(back.switched && back.primary ? { switchedToPrimary: back.primary } : {}),
  };
}

export function createWorktree(
  repoRoot: string,
  worktreeParentDir: string,
  taskId: string
): { ok: boolean; path: string; branch: string; error?: string } {
  const path = worktreePath(worktreeParentDir, taskId);
  const branch = branchNameForTask(taskId);
  const primaryReady = ensurePrimaryBranchCheckedOut(repoRoot);
  if (!primaryReady.ok) {
    return {
      ok: false,
      path,
      branch,
      error:
        `Primary repo must be on main/master before adding a worktree (${primaryReady.error ?? "unknown"}).`,
    };
  }
  if (existsSync(path)) {
    const rm = removeWorktree(repoRoot, path, true, branch);
    if (!rm.ok) {
      return {
        ok: false,
        path,
        branch,
        error:
          `Stale worktree at ${path} could not be removed (restart/re-assign needs a clean path): ${rm.error ?? "git worktree remove failed"}`,
      };
    }
    git(repoRoot, ["worktree", "prune"]);
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
 * `git merge` only sees commits; uncommitted edits in the worktree would be lost on merge + remove.
 * Snapshot them into a single commit so the merge step can land them on main.
 */
export function snapshotUncommittedInWorktreeIfNeeded(worktreeRoot: string): {
  ok: boolean;
  error?: string;
  committed?: boolean;
} {
  const por = git(worktreeRoot, ["status", "--porcelain"]);
  if (!por.ok) {
    return { ok: false, error: (por.stderr || por.stdout).trim() };
  }
  if (!por.stdout.trim()) {
    return { ok: true, committed: false };
  }
  const add = git(worktreeRoot, ["add", "-A"]);
  if (!add.ok) {
    return { ok: false, error: (add.stderr || add.stdout).trim() };
  }
  const commit = git(worktreeRoot, [
    "commit",
    "-m",
    "chore(orchestration): snapshot agent worktree before merge into main",
  ]);
  if (!commit.ok) {
    return { ok: false, error: (commit.stderr || commit.stdout).trim() };
  }
  return { ok: true, committed: true };
}

/** Commits on `branch` not reachable from `primary` (same notion as `git merge` into primary). */
export function commitCountPrimaryBranchAhead(
  repoRoot: string,
  primary: "main" | "master",
  branch: string
): number | null {
  const root = resolve(repoRoot);
  const r = git(root, ["rev-list", "--count", `${primary}..${branch}`]);
  if (!r.ok) return null;
  const n = parseInt(r.stdout.trim(), 10);
  return Number.isFinite(n) ? n : null;
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
