import { spawn } from "node:child_process";
import type { ChildProcess } from "node:child_process";
import { loadConfig } from "../config.js";
import { resolveCursorCommand } from "../resolve-cursor-cli.js";
import {
  registerPipelineChild,
  clearPipelineChild,
  isPipelineCancelled,
} from "../pipeline-controller.js";

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
}): Promise<CursorRunResult> {
  const cfg = loadConfig();
  const dry = options.dryRunOverride ?? cfg.dryRun;
  const exe = resolveCursorCommand(cfg.cursorCli.command);
  const argsWithPrompt = cfg.cursorCli.args.map((a) =>
    a.split("{{PROMPT}}").join(options.prompt)
  );
  const useStdin =
    process.platform === "win32" &&
    cfg.cursorCli.args.some((a) => a.includes("{{PROMPT}}")) &&
    shouldSendPromptViaStdin(argsWithPrompt, exe);
  const args = useStdin
    ? cfg.cursorCli.args.map((a) => a.split("{{PROMPT}}").join("-"))
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

  return new Promise((resolvePromise, reject) => {
    let child: ChildProcess;
    try {
      /** Windows: `spawn` without a shell cannot run `.cmd`/`.bat` reliably — child exits with no captured stdout/stderr. */
      const useShell =
        process.platform === "win32" &&
        (/\.cmd$/i.test(exe) || /\.bat$/i.test(exe));
      if (useStdin) {
        options.onChunk?.(
          "--- Cursor CLI: prompt exceeds Windows command-line limit; sending via stdin (`agent -`). ---\n"
        );
      }
      child = spawn(exe, args, {
        cwd: options.cwd,
        stdio: [useStdin ? "pipe" : "ignore", "pipe", "pipe"],
        shell: useShell,
        windowsHide: true,
        env: {
          ...process.env,
          ...(cfg.cursorCli.env ?? {}),
        },
      });
      if (useStdin && child.stdin) {
        try {
          child.stdin.end(Buffer.from(options.prompt, "utf8"));
        } catch (e) {
          reject(
            new Error(
              `Failed to send prompt on stdin: ${e instanceof Error ? e.message : String(e)}`
            )
          );
          return;
        }
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

    let stdout = "";
    let stderr = "";
    const onOut = (buf: Buffer) => {
      const s = buf.toString("utf8");
      stdout += s;
      options.onChunk?.(s);
    };
    const onErr = (buf: Buffer) => {
      const s = buf.toString("utf8");
      stderr += s;
      options.onChunk?.(s);
    };
    child.stdout?.on("data", onOut);
    child.stderr?.on("data", onErr);
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
    }, cfg.cursorCli.timeoutMs);

    const cleanup = () => {
      clearTimeout(timer);
      if (options.pipelineRunId) clearPipelineChild(options.pipelineRunId);
    };

    child.on("error", (err) => {
      cleanup();
      reject(
        new Error(
          `Cursor CLI (${exe}): ${err.message}. On Windows set CURSOR_CLI to the full path of cursor.cmd (see Local App Data\\Programs\\cursor\\...).`
        )
      );
    });
    child.on("close", (code) => {
      cleanup();
      resolvePromise({
        exitCode: code ?? 1,
        stdout: tail(stdout),
        stderr: tail(stderr),
      });
    });
  });
}
