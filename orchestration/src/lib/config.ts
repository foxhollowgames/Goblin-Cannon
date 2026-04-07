import { readFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { OrchestrationConfig } from "./types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Package root: orchestration/ */
function packageRoot(): string {
  return resolve(__dirname, "../..");
}

function readJson(path: string): Record<string, unknown> {
  return JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
}

function mergeDeep(
  base: Record<string, unknown>,
  over: Record<string, unknown>
): Record<string, unknown> {
  const out = { ...base };
  for (const [k, v] of Object.entries(over)) {
    if (
      v &&
      typeof v === "object" &&
      !Array.isArray(v) &&
      typeof out[k] === "object" &&
      out[k] !== null &&
      !Array.isArray(out[k])
    ) {
      out[k] = mergeDeep(
        out[k] as Record<string, unknown>,
        v as Record<string, unknown>
      );
    } else {
      out[k] = v;
    }
  }
  return out;
}

const DEFAULTS: OrchestrationConfig = {
  repoRoot: "..",
  worktreeParentDir: "..",
  godotPath: "",
  cursorCli: {
    command: "cursor",
    /** Base args; `headlessAgent` injects `--print` (+ `--force` on execution). See cursor-agent-args.ts. */
    args: ["agent", "{{PROMPT}}"],
    timeoutMs: 3_600_000,
    /** When true, injects `cursor agent --print` (see cursor-agent-args.ts). Many Windows installs show "Warning: 'print' is not in the list of known options" — leave false unless your Cursor build supports headless per docs. */
    headlessAgent: false,
    exitAfterSummaryIdleMs: 60_000,
    exitAfterOutputIdleMs: 180_000,
    maxExecutionWallMs: 420_000,
  },
  limits: { maxParallelWorktrees: 4 },
  dryRun: false,
  plannerFallback: true,
  requireExecutionGitChanges: true,
  autoMergeOnPass: true,
  pushAfterMerge: true,
  gitRemote: "origin",
  deleteRemoteAgentBranch: true,
};

function normalizeConfig(
  raw: Record<string, unknown>,
  pkg: string
): OrchestrationConfig {
  const repoRoot = resolve(pkg, String(raw.repoRoot ?? DEFAULTS.repoRoot));
  const worktreeParentDir = resolve(
    pkg,
    String(raw.worktreeParentDir ?? DEFAULTS.worktreeParentDir)
  );
  const godotPath =
    process.env.GODOT_PATH?.trim() ||
    String((raw.godotPath as string) ?? DEFAULTS.godotPath);
  const cursorRaw = (raw.cursorCli as Record<string, unknown>) ?? {};
  const limitsRaw = (raw.limits as Record<string, unknown>) ?? {};
  return {
    repoRoot,
    worktreeParentDir,
    godotPath,
    cursorCli: {
      command: String(cursorRaw.command ?? DEFAULTS.cursorCli.command),
      args: Array.isArray(cursorRaw.args)
        ? (cursorRaw.args as string[])
        : DEFAULTS.cursorCli.args,
      timeoutMs: Number(cursorRaw.timeoutMs ?? DEFAULTS.cursorCli.timeoutMs),
      env:
        cursorRaw.env &&
        typeof cursorRaw.env === "object" &&
        !Array.isArray(cursorRaw.env)
          ? (cursorRaw.env as Record<string, string>)
          : undefined,
      headlessAgent: Boolean(
        cursorRaw.headlessAgent !== undefined
          ? cursorRaw.headlessAgent
          : DEFAULTS.cursorCli.headlessAgent
      ),
      exitAfterSummaryIdleMs: (() => {
        const fromEnv = process.env.ORCH_EXIT_AFTER_SUMMARY_IDLE_MS;
        const n =
          fromEnv !== undefined
            ? Number(fromEnv)
            : Number(
                cursorRaw.exitAfterSummaryIdleMs ??
                  DEFAULTS.cursorCli.exitAfterSummaryIdleMs
              );
        return Number.isFinite(n) ? n : DEFAULTS.cursorCli.exitAfterSummaryIdleMs;
      })(),
      exitAfterOutputIdleMs: (() => {
        const fromEnv = process.env.ORCH_EXIT_AFTER_OUTPUT_IDLE_MS;
        const n =
          fromEnv !== undefined
            ? Number(fromEnv)
            : Number(
                cursorRaw.exitAfterOutputIdleMs ??
                  DEFAULTS.cursorCli.exitAfterOutputIdleMs
              );
        return Number.isFinite(n)
          ? n
          : DEFAULTS.cursorCli.exitAfterOutputIdleMs;
      })(),
      maxExecutionWallMs: (() => {
        const fromEnv = process.env.ORCH_MAX_EXECUTION_WALL_MS;
        const n =
          fromEnv !== undefined
            ? Number(fromEnv)
            : Number(
                cursorRaw.maxExecutionWallMs ??
                  DEFAULTS.cursorCli.maxExecutionWallMs
              );
        return Number.isFinite(n) ? n : DEFAULTS.cursorCli.maxExecutionWallMs;
      })(),
    },
    limits: {
      maxParallelWorktrees: Number(
        limitsRaw.maxParallelWorktrees ?? DEFAULTS.limits.maxParallelWorktrees
      ),
    },
    dryRun: Boolean(raw.dryRun ?? DEFAULTS.dryRun),
    plannerFallback: Boolean(raw.plannerFallback ?? DEFAULTS.plannerFallback),
    requireExecutionGitChanges: Boolean(
      raw.requireExecutionGitChanges ?? DEFAULTS.requireExecutionGitChanges
    ),
    autoMergeOnPass: Boolean(
      raw.autoMergeOnPass !== undefined
        ? raw.autoMergeOnPass
        : DEFAULTS.autoMergeOnPass
    ),
    pushAfterMerge: (() => {
      const e = process.env.ORCH_PUSH_AFTER_MERGE;
      if (e === "0" || e === "false") return false;
      if (e === "1" || e === "true") return true;
      return Boolean(
        raw.pushAfterMerge !== undefined
          ? raw.pushAfterMerge
          : DEFAULTS.pushAfterMerge
      );
    })(),
    gitRemote: String(raw.gitRemote ?? DEFAULTS.gitRemote),
    deleteRemoteAgentBranch: Boolean(
      raw.deleteRemoteAgentBranch !== undefined
        ? raw.deleteRemoteAgentBranch
        : DEFAULTS.deleteRemoteAgentBranch
    ),
  };
}

let cached: OrchestrationConfig | null = null;

export function loadConfig(): OrchestrationConfig {
  if (cached) return cached;
  const pkg = packageRoot();
  const examplePath = join(pkg, "orchestration.config.example.json");
  const localPath = join(pkg, "orchestration.config.local.json");
  let merged: Record<string, unknown> = {};
  if (existsSync(examplePath)) {
    merged = readJson(examplePath);
  }
  if (existsSync(localPath)) {
    merged = mergeDeep(merged, readJson(localPath));
  }
  if (process.env.GOBLIN_CANNON_ROOT) {
    merged.repoRoot = process.env.GOBLIN_CANNON_ROOT;
  }
  if (process.env.ORCH_WORKTREE_PARENT) {
    merged.worktreeParentDir = process.env.ORCH_WORKTREE_PARENT;
  }
  if (process.env.ORCH_PLANNER_FALLBACK === "0") {
    merged.plannerFallback = false;
  } else if (process.env.ORCH_PLANNER_FALLBACK === "1") {
    merged.plannerFallback = true;
  }
  if (process.env.ORCH_REQUIRE_EXEC_GIT_CHANGES === "0") {
    merged.requireExecutionGitChanges = false;
  } else if (process.env.ORCH_REQUIRE_EXEC_GIT_CHANGES === "1") {
    merged.requireExecutionGitChanges = true;
  }
  cached = normalizeConfig(merged, pkg);
  return cached;
}

export function resetConfigCache(): void {
  cached = null;
}
