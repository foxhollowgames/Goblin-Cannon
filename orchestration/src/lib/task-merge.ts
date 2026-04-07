import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { loadConfig } from "./config.js";
import { enqueueExclusive } from "./async-queue.js";
import {
  getRun,
  newId,
  appendOutcome,
  touchRun,
  updateTask,
} from "./store.js";
import { removeWorktree } from "./worktree.js";
function git(
  repoRoot: string,
  args: string[]
): { ok: boolean; stdout: string; stderr: string } {
  const r = spawnSync("git", ["-C", repoRoot, ...args], {
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  return {
    ok: r.status === 0,
    stdout: r.stdout ?? "",
    stderr: r.stderr ?? "",
  };
}

function resolveMainBranch(repoRoot: string): "main" | "master" | null {
  for (const b of ["main", "master"] as const) {
    const v = git(repoRoot, ["rev-parse", "--verify", b]);
    if (v.ok) return b;
  }
  return null;
}

/**
 * Merge `branch` into the primary branch in `repoRoot` (main checkout, not a worktree).
 */
export function mergeBranchIntoPrimary(
  repoRoot: string,
  branch: string
): {
  ok: boolean;
  error?: string;
  gitOutput?: string;
  primary?: "main" | "master";
} {
  const root = resolve(repoRoot);
  const primary = resolveMainBranch(root);
  if (!primary) {
    return { ok: false, error: "No main or master branch in repo" };
  }
  const co = git(root, ["checkout", primary]);
  if (!co.ok) {
    return {
      ok: false,
      error: `checkout ${primary}: ${co.stderr || co.stdout}`.trim(),
    };
  }
  const mg = git(root, [
    "merge",
    "--no-ff",
    branch,
    "-m",
    `Merge agent branch ${branch}`,
  ]);
  const combined = `${mg.stdout}\n${mg.stderr}`.trim();
  if (!mg.ok) {
    git(root, ["merge", "--abort"]);
    return {
      ok: false,
      error: `merge ${branch}: ${combined || "(no output)"}`.trim(),
    };
  }
  return { ok: true, gitOutput: combined || undefined, primary };
}

function pushPrimaryBranch(
  repoRoot: string,
  remote: string,
  primary: "main" | "master"
): { ok: boolean; error?: string; output?: string } {
  const root = resolve(repoRoot);
  const p = git(root, ["push", remote, primary]);
  const out = `${p.stdout}\n${p.stderr}`.trim();
  if (!p.ok) {
    return { ok: false, error: out || `git push failed (${remote} ${primary})` };
  }
  return { ok: true, output: out || undefined };
}

/** Best-effort: remove agent branch on remote if it was ever pushed (usually a no-op). */
function deleteRemoteAgentBranchQuiet(
  repoRoot: string,
  remote: string,
  agentBranch: string
): { ok: boolean; output: string } {
  const root = resolve(repoRoot);
  const p = git(root, ["push", remote, "--delete", agentBranch]);
  return {
    ok: p.ok,
    output: `${p.stdout}\n${p.stderr}`.trim(),
  };
}

export function releaseActiveWorktreeSlot(
  runId: string,
  worktreePath: string
): void {
  const run = getRun(runId);
  if (!run) return;
  run.activeWorktreePaths = run.activeWorktreePaths.filter(
    (p) => p !== worktreePath
  );
  touchRun(run);
}

/**
 * After Godot tests: release capacity slot; if tests passed and autoMerge, merge into main and remove worktree.
 */
export async function finalizeTaskAfterGodotTests(
  runId: string,
  taskId: string,
  testsPassed: boolean
): Promise<void> {
  const cfg = loadConfig();
  const run = getRun(runId);
  if (!run) return;
  const task = run.backlog.find((t) => t.id === taskId);
  if (!task?.assignedWorktreePath) return;

  const wtPath = task.assignedWorktreePath;
  const branch = task.branchName;

  if (!testsPassed) {
    releaseActiveWorktreeSlot(runId, wtPath);
    return;
  }

  if (cfg.dryRun) {
    await enqueueExclusive(`merge:${cfg.repoRoot}`, async () => {
      const fresh = getRun(runId);
      if (!fresh) return;
      const t = fresh.backlog.find((x) => x.id === taskId);
      if (!t?.assignedWorktreePath || t.status !== "done") {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Dry-run: worktree cleanup skipped — task state was not done + worktree (status=${t?.status ?? "missing"}, hasPath=${Boolean(t?.assignedWorktreePath)}).`,
          metadata: { repoRoot: resolve(cfg.repoRoot) },
        });
        touchRun(fresh);
        return;
      }
      const pathForRm = t.assignedWorktreePath;
      const br = t.branchName;
      const rm = removeWorktree(cfg.repoRoot, pathForRm, true, br);
      if (!rm.ok) {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Dry-run: worktree remove failed: ${rm.error ?? "failed"}`,
        });
      } else if (rm.error) {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Dry-run: ${rm.error}`,
        });
      }
      updateTask(fresh, taskId, {
        assignedWorktreePath: undefined,
        branchName: undefined,
      });
      releaseActiveWorktreeSlot(runId, pathForRm);
      touchRun(fresh);
    });
    return;
  }

  const autoMerge = cfg.autoMergeOnPass !== false;
  if (!autoMerge) {
    releaseActiveWorktreeSlot(runId, wtPath);
    return;
  }

  if (!branch) {
    appendOutcome(run, {
      id: newId("out"),
      kind: "orchestrator",
      taskId,
      at: new Date().toISOString(),
      summary: `Task done but branchName missing — cannot auto-merge; released worktree slot.`,
    });
    releaseActiveWorktreeSlot(runId, wtPath);
    touchRun(run);
    return;
  }

  const pathForSlot = wtPath;
  const repoResolved = resolve(cfg.repoRoot);
  await enqueueExclusive(`merge:${cfg.repoRoot}`, async () => {
    const fresh = getRun(runId);
    if (!fresh) return;
    const t = fresh.backlog.find((x) => x.id === taskId);
    if (!t?.assignedWorktreePath || t.status !== "done") {
      appendOutcome(fresh, {
        id: newId("out"),
        kind: "orchestrator",
        taskId,
        at: new Date().toISOString(),
        summary: `Auto-merge skipped — task state changed before merge ran (status=${t?.status ?? "missing"}, hasWorktreePath=${Boolean(t?.assignedWorktreePath)}). No merge into main was performed.`,
        metadata: { branch, repoRoot: repoResolved },
      });
      touchRun(fresh);
      return;
    }

    const mergeRes = mergeBranchIntoPrimary(cfg.repoRoot, branch);
    if (!mergeRes.ok) {
      appendOutcome(fresh, {
        id: newId("out"),
        kind: "orchestrator",
        taskId,
        at: new Date().toISOString(),
        summary: `Auto-merge failed: ${mergeRes.error ?? "unknown"}`,
        metadata: { branch, repoRoot: repoResolved },
      });
      updateTask(fresh, taskId, { status: "failed" });
      releaseActiveWorktreeSlot(runId, pathForSlot);
      return;
    }

    const mergeHint = mergeRes.gitOutput
      ? mergeRes.gitOutput.slice(0, 400)
      : "(git reported success; empty stdout/stderr)";
    appendOutcome(fresh, {
      id: newId("out"),
      kind: "orchestrator",
      taskId,
      at: new Date().toISOString(),
      summary: `Merged ${branch} into main at ${repoResolved} and removing worktree.`,
      metadata: {
        branch,
        repoRoot: repoResolved,
        gitMergeOutput: mergeHint,
      },
    });

    const rm = removeWorktree(cfg.repoRoot, pathForSlot, true, branch);
    if (!rm.ok) {
      appendOutcome(fresh, {
        id: newId("out"),
        kind: "orchestrator",
        taskId,
        at: new Date().toISOString(),
        summary: `Merge ok but worktree remove: ${rm.error ?? "failed"}`,
      });
    }

    const primary = mergeRes.primary;
    if (cfg.pushAfterMerge && primary) {
      const pushRes = pushPrimaryBranch(
        cfg.repoRoot,
        cfg.gitRemote,
        primary
      );
      if (pushRes.ok) {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Pushed ${primary} to ${cfg.gitRemote}.`,
          metadata: {
            remote: cfg.gitRemote,
            branch: primary,
            gitPushOutput: pushRes.output?.slice(0, 500),
          },
        });
      } else {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Push to ${cfg.gitRemote} failed (merge is local only): ${pushRes.error ?? "unknown"}`,
          metadata: { remote: cfg.gitRemote, branch: primary },
        });
      }
    }

    if (cfg.deleteRemoteAgentBranch) {
      const del = deleteRemoteAgentBranchQuiet(
        cfg.repoRoot,
        cfg.gitRemote,
        branch
      );
      if (del.ok) {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Removed remote branch ${branch} from ${cfg.gitRemote}.`,
          metadata: { branch },
        });
      } else if (
        !/remote ref does not exist|does not exist|not a valid ref/i.test(
          del.output
        )
      ) {
        appendOutcome(fresh, {
          id: newId("out"),
          kind: "orchestrator",
          taskId,
          at: new Date().toISOString(),
          summary: `Remote branch delete (${branch}): ${del.output.slice(0, 300)}`,
          metadata: { branch },
        });
      }
    }

    updateTask(fresh, taskId, {
      status: "done",
      assignedWorktreePath: undefined,
      branchName: undefined,
    });
    releaseActiveWorktreeSlot(runId, pathForSlot);
  });
}
