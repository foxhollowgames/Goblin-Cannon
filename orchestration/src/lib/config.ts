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
    /** No `--print` here: Cursor 3.0.x often treats unknown flags as Electron args; use plannerFallback if agent prints nothing. */
    args: ["agent", "{{PROMPT}}"],
    timeoutMs: 3_600_000,
  },
  limits: { maxParallelWorktrees: 1 },
  dryRun: false,
  plannerFallback: true,
  requireExecutionGitChanges: true,
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
