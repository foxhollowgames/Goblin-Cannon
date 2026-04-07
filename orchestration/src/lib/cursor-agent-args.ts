import { basename } from "node:path";

/**
 * Cursor headless docs: `cursor agent --print` avoids opening the GUI; execution needs
 * `--print --force` so the agent can apply edits (otherwise only prints suggestions).
 *
 * The standalone **`agent`** executable (often `%LOCALAPPDATA%\cursor-agent\agent.cmd`)
 * is the same CLI without going through `cursor.cmd`; flags apply directly (no Electron
 * forwarding). Use `command` pointing at `agent` / `agent.cmd` and args **without** a
 * leading `agent` token — see `isStandaloneAgentExecutablePath`.
 */

export type CursorAgentPhase = "planner" | "execution" | "communication";

/** Satisfy Cursor Agent workspace trust (standalone CLI in unattended / worktree cwd). */
const STANDALONE_TRUST_FLAGS = new Set(["--trust", "--yolo", "-f"]);

export function hasStandaloneWorkspaceTrustFlag(args: string[]): boolean {
  return args.some((a) => STANDALONE_TRUST_FLAGS.has(a));
}

/**
 * Prepend `--trust` so non-interactive runs do not exit with "Workspace Trust Required"
 * (common when `cwd` is a git worktree). Idempotent if args already include trust/yolo/-f.
 * Opt out: `ORCH_AGENT_SKIP_WORKSPACE_TRUST=1`.
 */
export function ensureStandaloneWorkspaceTrust(args: string[]): string[] {
  if (process.env.ORCH_AGENT_SKIP_WORKSPACE_TRUST === "1") {
    return [...args];
  }
  if (hasStandaloneWorkspaceTrustFlag(args)) {
    return [...args];
  }
  return ["--trust", ...args];
}

/** True when `resolvedExe` is the standalone Cursor Agent binary, not `cursor`. */
export function isStandaloneAgentExecutablePath(resolvedExe: string): boolean {
  const base = basename(resolvedExe);
  return /^agent(\.(cmd|exe))?$/i.test(base);
}

/**
 * `cursor` is spawned as `cursor agent …`. The standalone binary (`agent.cmd` / `agent.exe`)
 * is already the agent CLI — a leftover leading `agent` argv is treated as a path or
 * subcommand (stray GUI agent tab, “picking up the command as a path” on Windows).
 */
export function stripStandaloneAgentSubcommandIfNeeded(
  resolvedExe: string,
  args: string[]
): string[] {
  if (!isStandaloneAgentExecutablePath(resolvedExe) || args.length === 0) {
    return args;
  }
  if (args[0] === "agent") {
    return args.slice(1);
  }
  return args;
}

/** Insert `--print` after leading flags (`--trust`, `-y`, etc.), before prompt/subcommand args. */
function insertIndexAfterLeadingFlags(args: string[]): number {
  let i = 0;
  while (i < args.length && args[i].startsWith("-")) {
    i++;
  }
  return i;
}

/**
 * When `headlessAgent` is false in config, `cursor agent` still often needs `--print` for
 * execution so the model **writes files** (otherwise prose-only replies pass `exit 0` and
 * fail later at tests). The standalone **`agent` / `agent.exe`** binary does not go through
 * Electron, so it is safe to always inject `--print` + `--force` on **execution** only.
 * Opt out: `ORCH_STANDALONE_NO_FORCE_PRINT=1`.
 */
export function isStandaloneExecutionHeadlessForced(
  phase: CursorAgentPhase,
  standaloneAgentExecutable: boolean
): boolean {
  return (
    standaloneAgentExecutable &&
    phase === "execution" &&
    process.env.ORCH_STANDALONE_NO_FORCE_PRINT !== "1"
  );
}

export function applyHeadlessAgentFlags(
  args: string[],
  phase: CursorAgentPhase,
  enabled: boolean,
  options?: { standaloneAgentExecutable?: boolean }
): string[] {
  const standalone = options?.standaloneAgentExecutable ?? false;
  const effectiveEnabled =
    enabled || isStandaloneExecutionHeadlessForced(phase, standalone);
  if (!effectiveEnabled) {
    return [...args];
  }
  const agentIdx = args.indexOf("agent");

  /** Standalone `agent` — args are e.g. `["{{PROMPT}}"]` or `["--trust", "-p", "{{PROMPT}}"]` (no `agent` token). */
  if (standalone && agentIdx < 0) {
    const out = [...args];
    const hasPrint = out.includes("--print") || out.includes("-p");
    if (!hasPrint) {
      out.splice(insertIndexAfterLeadingFlags(out), 0, "--print");
    }
    const needsForce = phase === "execution";
    const hasForce = out.includes("--force") || out.includes("--yolo");
    if (needsForce && !hasForce) {
      const printIdx = Math.max(out.indexOf("--print"), out.indexOf("-p"));
      const insertAfter = printIdx >= 0 ? printIdx : 0;
      out.splice(insertAfter + 1, 0, "--force");
    }
    return out;
  }

  if (agentIdx < 0) {
    return [...args];
  }

  const out = [...args];
  const hasPrint = out.includes("--print") || out.includes("-p");
  if (!hasPrint) {
    out.splice(agentIdx + 1, 0, "--print");
  }

  const needsForce = phase === "execution";
  const hasForce = out.includes("--force") || out.includes("--yolo");
  if (needsForce && !hasForce) {
    const printIdx = Math.max(out.indexOf("--print"), out.indexOf("-p"));
    const insertAfter = printIdx >= 0 ? printIdx : agentIdx;
    out.splice(insertAfter + 1, 0, "--force");
  }
  return out;
}
