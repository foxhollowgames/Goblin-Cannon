import { spawnSync } from "node:child_process";
import type { ChildProcess } from "node:child_process";

/**
 * Windows: spawned `cmd /c call agent.cmd` often ignores SIGTERM; the Promise never resolves.
 * Send SIGTERM, then after `waitMs` send SIGKILL and `taskkill /T /F` on the root PID.
 */
export function killChildProcessGracefully(
  child: ChildProcess,
  options?: { onLog?: (msg: string) => void; waitMs?: number }
): void {
  const onLog = options?.onLog;
  const waitMs = options?.waitMs ?? 4000;
  try {
    child.kill("SIGTERM");
  } catch {
    /* ignore */
  }
  const pid = child.pid;
  if (!pid) return;
  setTimeout(() => {
    try {
      child.kill("SIGKILL");
      onLog?.(
        `--- Force-killed child PID ${pid} (${waitMs}ms after SIGTERM; Windows cmd/agent.cmd often needs this) ---\n`
      );
    } catch {
      /* ignore — process may already be gone */
    }
    if (process.platform === "win32") {
      try {
        spawnSync("taskkill", ["/PID", String(pid), "/T", "/F"], {
          windowsHide: true,
          stdio: "ignore",
        });
      } catch {
        /* ignore */
      }
    }
  }, waitMs);
}
