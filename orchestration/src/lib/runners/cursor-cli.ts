import { spawn } from "node:child_process";
import type { ChildProcess } from "node:child_process";
import { loadConfig } from "../config.js";
import {
  applyHeadlessAgentFlags,
  ensureStandaloneWorkspaceTrust,
  isStandaloneAgentExecutablePath,
  isStandaloneExecutionHeadlessForced,
  stripStandaloneAgentSubcommandIfNeeded,
  type CursorAgentPhase,
} from "../cursor-agent-args.js";
import { resolveCursorCommand } from "../resolve-cursor-cli.js";
import {
  registerPipelineChild,
  clearPipelineChild,
  isPipelineCancelled,
} from "../pipeline-controller.js";
import { killChildProcessGracefully } from "../kill-child-process.js";

/** Keep enough of agent output for JSON plans — truncating to 16k was dropping fenced JSON at the start of long replies. */
function tail(s: string, max = 1_048_576): string {
  if (s.length <= max) return s;
  return s.slice(-max);
}

/**
 * Windows `cmd.exe` enforces ~8191 chars for the full command line; embedding a huge
 * prompt in argv triggers "The command line is too long." Cursor `agent` accepts `-`
 * and reads the prompt from stdin (same as `cursor -`).
 */
const WIN_MAX_CMD_CHARS = 7000;

function approxCommandLineChars(exe: string, args: string[]): number {
  return exe.length + args.reduce((n, a) => n + a.length + 3, 0) + 8;
}

function shouldSendPromptViaStdin(argsWithPrompt: string[], exe: string): boolean {
  return approxCommandLineChars(exe, argsWithPrompt) > WIN_MAX_CMD_CHARS;
}

export interface CursorRunResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

/**
 * Spawns configured Cursor CLI with {{PROMPT}} substituted in args.
 */
export async function runCursorAgent(options: {
  prompt: string;
  cwd: string;
  onChunk?: (chunk: string) => void;
  dryRunOverride?: boolean;
  /** When set, child is registered for Stop + cancel checks */
  pipelineRunId?: string;
  /** Controls `--print` / `--force` injection for headless CLI (see cursor-agent-args.ts). */
  phase?: CursorAgentPhase;
}): Promise<CursorRunResult> {
  const cfg = loadConfig();
  const dry = options.dryRunOverride ?? cfg.dryRun;
  const exe = resolveCursorCommand(cfg.cursorCli.command);
  const standaloneExecutable = isStandaloneAgentExecutablePath(exe);
  const phase = options.phase ?? "planner";
  let baseArgs = stripStandaloneAgentSubcommandIfNeeded(exe, cfg.cursorCli.args);
  if (standaloneExecutable) {
    baseArgs = ensureStandaloneWorkspaceTrust(baseArgs);
  }
  const argTemplate = applyHeadlessAgentFlags(
    baseArgs,
    phase,
    cfg.cursorCli.headlessAgent,
    { standaloneAgentExecutable: standaloneExecutable }
  );
  const argsWithPrompt = argTemplate.map((a) =>
    a.split("{{PROMPT}}").join(options.prompt)
  );
  const standaloneAgent = standaloneExecutable;
  /** Always pipe the prompt on stdin for Windows when using `{{PROMPT}}` — embedding long or special-rich prompts in argv via `cmd /c` often truncates or splits wrong, so the agent only “sees” the first line (e.g. automation header) while edits land in the wrong cwd. Non-Windows keeps argv unless the line is too long. */
  const useStdin =
    process.platform === "win32"
      ? argTemplate.some((a) => a.includes("{{PROMPT}}"))
      : argTemplate.some((a) => a.includes("{{PROMPT}}")) &&
        shouldSendPromptViaStdin(argsWithPrompt, exe);
  /**
   * Standalone `agent.cmd` → PowerShell `cursor-agent.ps1` breaks on a lone `-` stdin marker. Omit that argv token and send the prompt on stdin only.
   * Native `agent.exe` is spawned without that shim — use `-` per CLI so the process knows to read stdin and can exit (omitting `-` with `.exe` can leave the agent waiting/hung).
   */
  const standaloneStdinUseDash = /\.exe$/i.test(exe);
  const args =
    useStdin && standaloneAgent
      ? standaloneStdinUseDash
        ? argTemplate.map((a) => a.split("{{PROMPT}}").join("-"))
        : argTemplate
            .flatMap((a) => {
              if (a === "{{PROMPT}}") return [];
              if (a.includes("{{PROMPT}}")) {
                const j = a.split("{{PROMPT}}").join("");
                return j.length > 0 ? [j] : [];
              }
              return [a];
            })
            .filter((s) => s.length > 0)
      : useStdin
        ? argTemplate.map((a) => a.split("{{PROMPT}}").join("-"))
        : argsWithPrompt;

  if (options.pipelineRunId && isPipelineCancelled(options.pipelineRunId)) {
    return { exitCode: 130, stdout: "", stderr: "Cancelled before Cursor CLI" };
  }

  if (dry) {
    const line = useStdin
      ? `[dry-run] ${exe} ${args.map((a) => JSON.stringify(a)).join(" ")} <stdin ${options.prompt.length} chars> (cwd=${options.cwd})\n`
      : `[dry-run] ${exe} ${args.map((a) => JSON.stringify(a)).join(" ")} (cwd=${options.cwd})\n`;
    options.onChunk?.(line);
    return { exitCode: 0, stdout: line, stderr: "" };
  }

  options.onChunk?.(`--- Cursor CLI resolved to: ${exe} ---\n`);
  if (cfg.cursorCli.headlessAgent && !standaloneExecutable) {
    options.onChunk?.(
      "--- Warning: headlessAgent injects --print, but the resolved executable is not the standalone agent binary. On Windows, cursor.cmd often forwards that flag to Electron (empty I/O, stray agent tab, Warning: print / Electron). Set cursorCli.command to %LOCALAPPDATA%\\cursor-agent\\agent.cmd with args [\"--trust\",\"{{PROMPT}}\"] or similar, or set env CURSOR_AGENT_BIN to that path (overrides CURSOR_CLI). ---\n"
    );
  }
  if (isStandaloneExecutionHeadlessForced(phase, standaloneExecutable)) {
    if (!cfg.cursorCli.headlessAgent) {
      options.onChunk?.(
        "--- Standalone Cursor Agent: applying --print/--force for execution even though cursorCli.headlessAgent is false (safe for agent.exe/agent.cmd; not forwarded through Electron). Disable with ORCH_STANDALONE_NO_FORCE_PRINT=1. ---\n"
      );
    }
  } else if (
    !cfg.cursorCli.headlessAgent &&
    !standaloneExecutable &&
    phase === "execution"
  ) {
    options.onChunk?.(
      "--- Warning: cursorCli.headlessAgent is false and the resolved CLI is not the standalone agent — execution does not get --print/--force; the agent may answer in prose without editing files. Point cursorCli.command at agent.cmd/agent.exe and/or set headlessAgent to true. See orchestration/README.md (Headless agent). ---\n"
    );
  }

  return new Promise((resolvePromise, reject) => {
    let child: ChildProcess;
    let heartbeatTimer: ReturnType<typeof setInterval> | undefined;
    try {
      /**
       * Windows: `spawn` without a shell cannot run `.cmd`/`.bat` reliably — child exits with no captured stdout/stderr.
       * Do **not** use `{ shell: true }` here: Node joins exe + args unquoted (spaces break).
       * Do **not** pass one pre-quoted `/c` string either: Node then adds its own quoting and the line breaks (`' "C:\Program Files\..." '` not recognized).
       * Use `cmd /d /s /c call <exe> ...args` with separate argv so Node quotes each token for CreateProcess.
       */
      const useCmdExe =
        process.platform === "win32" &&
        (/\.cmd$/i.test(exe) || /\.bat$/i.test(exe));
      if (useStdin) {
        if (standaloneAgent) {
          options.onChunk?.(
            standaloneStdinUseDash
              ? "--- Cursor CLI: sending prompt on stdin (`-` argv + stdin; native agent.exe). ---\n"
              : "--- Cursor CLI: sending full prompt on stdin only (agent.cmd: no `-` in argv — avoids PowerShell cursor-agent.ps1 errors). Prefer agent.exe in the same folder if hangs. ---\n"
          );
        } else {
          options.onChunk?.(
            "--- Cursor CLI: prompt exceeds Windows command-line limit; sending via stdin (`agent -`). ---\n"
          );
        }
      }
      if (useCmdExe) {
        child = spawn(process.env.ComSpec || "cmd.exe", ["/d", "/s", "/c", "call", exe, ...args], {
          cwd: options.cwd,
          stdio: [useStdin ? "pipe" : "ignore", "pipe", "pipe"],
          windowsHide: true,
          env: {
            ...process.env,
            ...(cfg.cursorCli.env ?? {}),
          },
        });
      } else {
        child = spawn(exe, args, {
          cwd: options.cwd,
          stdio: [useStdin ? "pipe" : "ignore", "pipe", "pipe"],
          windowsHide: true,
          env: {
            ...process.env,
            ...(cfg.cursorCli.env ?? {}),
          },
        });
      }
      if (useStdin && child.stdin) {
        setImmediate(() => {
          try {
            child.stdin!.end(Buffer.from(options.prompt, "utf8"));
          } catch (e) {
            reject(
              new Error(
                `Failed to send prompt on stdin: ${e instanceof Error ? e.message : String(e)}`
              )
            );
          }
        });
      }
    } catch (e) {
      reject(
        new Error(
          `Failed to spawn Cursor CLI (${exe}): ${e instanceof Error ? e.message : String(e)}. Set CURSOR_CLI to the full path (e.g. ...\\cursor.cmd on Windows).`
        )
      );
      return;
    }

    if (options.pipelineRunId) {
      registerPipelineChild(options.pipelineRunId, child);
    }

    const startedAt = Date.now();
    let lastDataAt = startedAt;
    const exitAfterSummaryIdleMs = cfg.cursorCli.exitAfterSummaryIdleMs ?? 0;
    const exitAfterOutputIdleMs = cfg.cursorCli.exitAfterOutputIdleMs ?? 0;
    const maxExecutionWallMs = cfg.cursorCli.maxExecutionWallMs ?? 0;
    let summaryIdleWatch: ReturnType<typeof setInterval> | undefined;
    let stallWatch: ReturnType<typeof setInterval> | undefined;
    let summaryIdleArmed = false;

    /**
     * Cursor agents often end with `## Summary` **or** prose like `Summary of what was implemented:`.
     * The latter was not matching, so the post-summary idle kill never armed.
     */
    const hasAgentCompletionSection = (combined: string): boolean => {
      if (/(^|\n)#{1,3}\s+Summary\s*(\n|$)/m.test(combined)) return true;
      if (/(^|\n)Summary of what was implemented\s*:?/im.test(combined))
        return true;
      if (/(^|\n)###\s+Files touched\s*(\n|$)/m.test(combined)) return true;
      return false;
    };

    const tryArmSummaryIdleKill = () => {
      if (options.phase !== "execution" || exitAfterSummaryIdleMs <= 0) return;
      if (summaryIdleArmed) return;
      const combined = `${stdout}\n${stderr}`;
      if (!hasAgentCompletionSection(combined)) return;
      summaryIdleArmed = true;
      options.onChunk?.(
        `--- Agent output looks complete (Summary / "Summary of what was implemented" / "### Files touched") — will terminate after ${exitAfterSummaryIdleMs}ms with no further output (Windows agent.cmd often hangs here). Set cursorCli.exitAfterSummaryIdleMs to 0 to disable. ---\n`
      );
      summaryIdleWatch = setInterval(() => {
        if (Date.now() - lastDataAt < exitAfterSummaryIdleMs) return;
        options.onChunk?.(
          `--- Terminating Cursor CLI: idle ${exitAfterSummaryIdleMs}ms after completion-style output ---\n`
        );
        killWithSchedule();
        if (summaryIdleWatch) {
          clearInterval(summaryIdleWatch);
          summaryIdleWatch = undefined;
        }
      }, 5000);
    };

    if (
      options.phase === "execution" &&
      (exitAfterOutputIdleMs > 0 || maxExecutionWallMs > 0)
    ) {
      stallWatch = setInterval(() => {
        try {
          if (
            exitAfterOutputIdleMs > 0 &&
            Date.now() - lastDataAt >= exitAfterOutputIdleMs
          ) {
            options.onChunk?.(
              `--- Terminating Cursor CLI: no stdout/stderr for ${exitAfterOutputIdleMs}ms (cursorCli.exitAfterOutputIdleMs). ---\n`
            );
            killWithSchedule();
            if (stallWatch) {
              clearInterval(stallWatch);
              stallWatch = undefined;
            }
            return;
          }
          if (
            maxExecutionWallMs > 0 &&
            Date.now() - startedAt >= maxExecutionWallMs
          ) {
            options.onChunk?.(
              `--- Terminating Cursor CLI: execution wall time ${maxExecutionWallMs}ms exceeded (cursorCli.maxExecutionWallMs). ---\n`
            );
            killWithSchedule();
            if (stallWatch) {
              clearInterval(stallWatch);
              stallWatch = undefined;
            }
          }
        } catch {
          /* ignore */
        }
      }, 5000);
    }

    heartbeatTimer = setInterval(() => {
      const sec = Math.floor((Date.now() - startedAt) / 1000);
      const cwd = options.cwd.trim();
      const gitHint =
        cwd.length > 0
          ? ` Validate: git -C "${cwd}" status --short`
          : "";
      options.onChunk?.(
        `--- Cursor CLI still running (${sec}s) — cwd: ${cwd || "(unknown)"}.${gitHint} — If output already shows a finished Summary but this line keeps repeating, the subprocess is likely stuck (common with agent.cmd); click Stop, set CURSOR_AGENT_BIN to agent.exe next to agent.cmd, restart the server, and re-run. ---\n`
      );
    }, 120_000);

    let stdout = "";
    let stderr = "";
    const onOut = (buf: Buffer) => {
      const s = buf.toString("utf8");
      stdout += s;
      lastDataAt = Date.now();
      options.onChunk?.(s);
      tryArmSummaryIdleKill();
    };
    const onErr = (buf: Buffer) => {
      const s = buf.toString("utf8");
      stderr += s;
      lastDataAt = Date.now();
      options.onChunk?.(s);
      tryArmSummaryIdleKill();
    };
    child.stdout?.on("data", onOut);
    child.stderr?.on("data", onErr);
    const timer = setTimeout(() => {
      options.onChunk?.(
        `--- Cursor CLI timeout (${cfg.cursorCli.timeoutMs}ms) — terminating child ---\n`
      );
      killWithSchedule();
    }, cfg.cursorCli.timeoutMs);

    let settled = false;
    let postKillTimer: ReturnType<typeof setTimeout> | undefined;

    const cleanup = () => {
      clearTimeout(timer);
      if (postKillTimer) {
        clearTimeout(postKillTimer);
        postKillTimer = undefined;
      }
      if (heartbeatTimer) clearInterval(heartbeatTimer);
      if (summaryIdleWatch) clearInterval(summaryIdleWatch);
      if (stallWatch) clearInterval(stallWatch);
      if (options.pipelineRunId) clearPipelineChild(options.pipelineRunId);
    };

    function resolveOk(code: number | null, stderrExtra?: string): void {
      if (settled) return;
      settled = true;
      cleanup();
      const errOut = stderr + (stderrExtra ?? "");
      resolvePromise({
        exitCode: code ?? 1,
        stdout: tail(stdout),
        stderr: tail(errOut),
      });
    }

    function schedulePostKillResolve(): void {
      if (postKillTimer) {
        clearTimeout(postKillTimer);
        postKillTimer = undefined;
      }
      postKillTimer = setTimeout(() => {
        postKillTimer = undefined;
        if (settled) return;
        options.onChunk?.(
          "--- [orchestration: no exit/close after kill — forcing CLI completion. If the worktree has changes, the pipeline may still proceed to tests.] ---\n"
        );
        resolveOk(
          1,
          "\n--- [orchestration: child did not emit exit (Windows cmd tree); forced resolution.] ---\n"
        );
      }, 12_000);
    }

    function killWithSchedule(): void {
      killChildProcessGracefully(child, { onLog: options.onChunk });
      schedulePostKillResolve();
    }

    child.on("error", (err) => {
      if (settled) return;
      settled = true;
      cleanup();
      reject(
        new Error(
          `Cursor CLI (${exe}): ${err.message}. On Windows set CURSOR_CLI to the full path of cursor.cmd (see Local App Data\\Programs\\cursor\\...).`
        )
      );
    });
    child.on("exit", (code) => {
      resolveOk(code);
    });
    child.on("close", (code) => {
      resolveOk(code);
    });
  });
}
