import { statSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { isStandaloneAgentExecutablePath } from "./cursor-agent-args.js";

function isFile(path: string): boolean {
  try {
    return statSync(path).isFile();
  } catch {
    return false;
  }
}

/**
 * On Windows the real launcher is often `cursor.cmd` next to a bogus or missing
 * extensionless `cursor` path returned by `where` or env. Prefer a sibling .cmd/.exe.
 */
function winTryCursorBin(p: string): string | null {
  if (process.platform !== "win32" || !p) return null;
  const looksLikePath =
    /^[A-Za-z]:[\\/]/.test(p) ||
    p.startsWith("\\\\") ||
    p.includes("\\") ||
    p.includes("/");
  if (!looksLikePath) return null;

  const dir = dirname(p);
  const base = basename(p).toLowerCase();
  /** Electron ships a no-extension `cursor` file next to `cursor.cmd`; CreateProcess cannot spawn it — prefer .cmd/.exe. */
  if (base === "cursor") {
    for (const name of ["cursor.cmd", "Cursor.exe", "cursor.exe"]) {
      const c = join(dir, name);
      if (isFile(c)) return c;
    }
  }

  if (isFile(p)) return p;
  const lower = p.toLowerCase();
  if (lower.endsWith(".cmd") || lower.endsWith(".exe")) return null;
  for (const ext of [".cmd", ".exe"]) {
    const alt = p + ext;
    if (isFile(alt)) return alt;
  }
  return null;
}

function finalizeWin(p: string): string {
  if (process.platform !== "win32") return p;
  return winTryCursorBin(p) ?? p;
}

/** `agent.cmd` often delegates to PowerShell `cursor-agent.ps1`, which mishandles a lone `-` stdin marker. Prefer a native `agent.exe` in the same folder when present. */
function winPreferAgentExeOverCmd(resolved: string): string {
  if (process.platform !== "win32") return resolved;
  if (basename(resolved).toLowerCase() !== "agent.cmd") return resolved;
  const dir = dirname(resolved);
  for (const name of ["agent.exe", "cursor-agent.exe"]) {
    const p = join(dir, name);
    if (isFile(p)) return p;
  }
  return resolved;
}

/**
 * Resolves the Cursor CLI executable. On Windows, `spawn("cursor")` often fails
 * with ENOENT because the shim is `cursor.cmd` and may not resolve without a full path.
 *
 * **Precedence (important):** `CURSOR_AGENT_BIN` is the only env that should force a
 * binary when you also have a misleading `CURSOR_CLI` pointing at the **IDE** `cursor.cmd`
 * (that override used to win and spawned GUI “agent” tabs). A **full path in config** to
 * the standalone `agent` wins over `CURSOR_CLI`. The default Windows install of the
 * headless agent (`%LOCALAPPDATA%\\cursor-agent\\agent.cmd`) is tried before `where cursor`.
 */
export function resolveCursorCommand(configured: string): string {
  const cfg = configured?.trim() ?? "";

  const agentBin = process.env.CURSOR_AGENT_BIN?.trim();
  if (agentBin) {
    if (isFile(agentBin)) return winPreferAgentExeOverCmd(finalizeWin(agentBin));
    const fixed = winTryCursorBin(agentBin);
    if (fixed) return winPreferAgentExeOverCmd(fixed);
  }

  if (cfg && (cfg.includes("\\") || cfg.includes("/"))) {
    if (isFile(cfg) && isStandaloneAgentExecutablePath(cfg)) {
      return winPreferAgentExeOverCmd(finalizeWin(cfg));
    }
  }

  const cursorCliEnv = process.env.CURSOR_CLI?.trim();
  if (cursorCliEnv) {
    if (isFile(cursorCliEnv)) return winPreferAgentExeOverCmd(finalizeWin(cursorCliEnv));
    const fixed = winTryCursorBin(cursorCliEnv);
    if (fixed) return winPreferAgentExeOverCmd(fixed);
  }

  if (cfg && (cfg.includes("\\") || cfg.includes("/"))) {
    if (isFile(cfg)) return winPreferAgentExeOverCmd(finalizeWin(cfg));
    const fixed = winTryCursorBin(cfg);
    if (fixed) return winPreferAgentExeOverCmd(fixed);
  }

  if (process.platform === "win32") {
    const local = process.env.LOCALAPPDATA;
    if (local) {
      const bundledAgent = join(local, "cursor-agent", "agent.cmd");
      if (isFile(bundledAgent)) {
        return winPreferAgentExeOverCmd(finalizeWin(bundledAgent));
      }
    }

    const where = spawnSync("where.exe", ["cursor"], {
      encoding: "utf8",
      shell: false,
    });
    if (where.status === 0 && where.stdout) {
      const first = where.stdout
        .split(/\r?\n/)
        .map((l) => l.trim())
        .find((l) => l.length > 0);
      if (first) {
        if (isFile(first)) return winPreferAgentExeOverCmd(finalizeWin(first));
        const fixed = winTryCursorBin(first);
        if (fixed) return winPreferAgentExeOverCmd(fixed);
      }
    }

    if (local) {
      const candidates = [
        join(local, "Programs", "cursor", "resources", "app", "bin", "cursor.cmd"),
        join(local, "Programs", "cursor", "resources", "app", "bin", "cursor.exe"),
        join(local, "Programs", "cursor", "resources", "app", "bin", "Cursor.exe"),
      ];
      for (const p of candidates) {
        if (isFile(p)) return winPreferAgentExeOverCmd(p);
      }
    }
  } else {
    const which = spawnSync("which", ["cursor"], {
      encoding: "utf8",
      shell: false,
    });
    if (which.status === 0 && which.stdout) {
      const p = which.stdout.trim().split("\n")[0];
      if (p && isFile(p)) return p;
    }
  }

  return winPreferAgentExeOverCmd(finalizeWin(configured || "cursor"));
}

/** True when `resolved` is a concrete path that exists as a file (not a directory name). */
export function isCursorCliPathRunnable(resolved: string): boolean {
  const looksLikePath =
    /^[A-Za-z]:[\\/]/.test(resolved) ||
    resolved.startsWith("\\\\") ||
    resolved.includes("/") ||
    resolved.includes("\\");
  if (!looksLikePath) return false;
  return isFile(resolved);
}

export function describeCursorResolution(resolved: string): string {
  if (isCursorCliPathRunnable(resolved)) return resolved;
  return `${resolved} (not found on disk — set CURSOR_CLI to the full path)`;
}
