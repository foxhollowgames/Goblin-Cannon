import { statSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { spawnSync } from "node:child_process";

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

/**
 * Resolves the Cursor CLI executable. On Windows, `spawn("cursor")` often fails
 * with ENOENT because the shim is `cursor.cmd` and may not resolve without a full path.
 */
export function resolveCursorCommand(configured: string): string {
  const envPath =
    process.env.CURSOR_CLI?.trim() || process.env.CURSOR_AGENT_BIN?.trim();
  if (envPath) {
    if (isFile(envPath)) return finalizeWin(envPath);
    const fixed = winTryCursorBin(envPath);
    if (fixed) return fixed;
  }

  if (configured && (configured.includes("\\") || configured.includes("/"))) {
    if (isFile(configured)) return finalizeWin(configured);
    const fixed = winTryCursorBin(configured);
    if (fixed) return fixed;
  }

  if (process.platform === "win32") {
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
        if (isFile(first)) return finalizeWin(first);
        const fixed = winTryCursorBin(first);
        if (fixed) return fixed;
      }
    }

    const local = process.env.LOCALAPPDATA;
    if (local) {
      const candidates = [
        join(local, "Programs", "cursor", "resources", "app", "bin", "cursor.cmd"),
        join(local, "Programs", "cursor", "resources", "app", "bin", "cursor.exe"),
        join(local, "Programs", "cursor", "resources", "app", "bin", "Cursor.exe"),
      ];
      for (const p of candidates) {
        if (isFile(p)) return p;
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

  return finalizeWin(configured || "cursor");
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
