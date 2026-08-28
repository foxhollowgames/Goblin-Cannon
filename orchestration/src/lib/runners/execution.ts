import { readFileSync } from "node:fs";
import { promptPath } from "../paths.js";
import { runCursorAgent } from "./cursor-cli.js";
import { resolveAgentModelForPhase } from "../agent-model.js";
import { loadConfig } from "../config.js";
import type { Task, RunState, TaskStatus } from "../types.js";
import { getRun, newId, appendOutcome, touchRun, updateTask } from "../store.js";
import { publish } from "../log-bus.js";
import {
  getWorktreeHead,
  worktreeGitDelta,
} from "../worktree.js";
import { formatAttachmentContextForPrompt } from "../attachments.js";

const TEST_FAILURE_LOG_MAX = 10_000;
const EXECUTION_RECOVERY_LOG_MAX = 10_000;

/** Injected when the pipeline retries the execution phase after a failed CLI run or no-op. */
export type ExecutionRecoveryContext = {
  /** 1-based attempt index for this task round (includes the first try). */
  attempt: number;
  /** Total attempts allowed for this round (1 + executionRecoveryRetries). */
  maxAttempts: number;
  reason: "no_git_changes" | "nonzero_exit";
  exitCode?: number;
  logExcerpt: string;
};

export function formatExecutionRecoveryBlock(
  ctx: ExecutionRecoveryContext
): string {
  const reasonLine =
    ctx.reason === "no_git_changes"
      ? "The last run exited **0** but produced **no tracked file changes** in this worktree (or `requireExecutionGitChanges` detected an empty run). You must edit/create/delete files under the worktree root so `git status` shows changes."
      : `The Cursor/agent CLI exited **${ctx.exitCode ?? "?"}** without leaving usable worktree changes. Fix the cause (API key, headless flags, wrong cwd, or incomplete edits) and complete the task.`;

  return [
    "## PREVIOUS EXECUTION ATTEMPT FAILED (automated recovery)",
    `Recovery attempt **${ctx.attempt}** of **${ctx.maxAttempts}** for this task round — the pipeline is re-invoking you with the last captured output.`,
    "",
    reasonLine,
    "",
    "**Recent agent CLI stdout/stderr (tail):**",
    "```",
    ctx.logExcerpt.slice(-EXECUTION_RECOVERY_LOG_MAX),
    "```",
    "",
  ].join("\n");
}

/** Injected into the execution prompt after a failed Godot run when the pipeline retries. */
export type TestFailureRetryContext = {
  /** 1-based index of this execution round (matches dashboard messaging). */
  executionRound: number;
  /** Total execution+test rounds allowed for this task (including the first). `Infinity` when unlimited retries. */
  maxRounds: number;
  outcomeSummary: string;
  logExcerpt: string;
  killedByTimeout: boolean;
};

export function formatTestFailureRetryBlock(ctx: TestFailureRetryContext): string {
  if (ctx.killedByTimeout) {
    return [
      "## PREVIOUS GODOT RUN HIT THE WALL-CLOCK TIMEOUT",
      "The test process was killed because it exceeded `godotHeadlessTimeoutMs`. Fix infinite loops or deadlocks, or raise the timeout in orchestration config only if the suite legitimately needs longer.",
      "",
    ].join("\n");
  }
  const totalLabel = Number.isFinite(ctx.maxRounds)
    ? String(Math.trunc(ctx.maxRounds))
    : "unlimited";
  return [
    "## PREVIOUS GODOT TEST RUN FAILED (automated retry)",
    `This is execution round **${ctx.executionRound}** of **${totalLabel}** for this task. The last headless test run did not pass.`,
    "",
    "Fix the implementation **or** update tests/assertions if they are wrong or outdated. Edits must be under this worktree. Another test run will execute automatically after you finish.",
    "If the last failure was due to a hung Cursor agent (`agent.cmd` with no exit), prefer `%LOCALAPPDATA%\\\\cursor-agent\\\\agent.exe` (set `CURSOR_AGENT_BIN` or `cursorCli.command`) so stdin mode exits cleanly on Windows.",
    "",
    "**Summary:** " + ctx.outcomeSummary,
    "",
    "**Recent stdout/stderr (tail):**",
    "```",
    ctx.logExcerpt.slice(-TEST_FAILURE_LOG_MAX),
    "```",
    "",
  ].join("\n");
}

function buildExecutionPrompt(
  run: RunState,
  task: Task,
  testFailureRetry?: TestFailureRetryContext,
  executionRecovery?: ExecutionRecoveryContext
): string {
  const template = readFileSync(promptPath("execution.md"), "utf8");
  const acc = task.acceptance.map((a) => `- ${a}`).join("\n");
  const hints = (task.filesHint ?? []).join(", ") || "(none)";
  const worktree = task.assignedWorktreePath ?? "";
  const attachmentBlock = formatAttachmentContextForPrompt(run);
  const body = template
    .replace(/\{\{PROBLEM\}\}/g, run.problem || "")
    .replace(/\{\{TASK_TITLE\}\}/g, task.title)
    .replace(/\{\{TASK_DESCRIPTION\}\}/g, task.description)
    .replace(/\{\{TASK_ACCEPTANCE\}\}/g, acc)
    .replace(/\{\{TASK_FILES_HINT\}\}/g, hints)
    .replace(/\{\{WORKTREE_CWD\}\}/g, worktree);
  const recoveryBlock = executionRecovery
    ? "\n\n" + formatExecutionRecoveryBlock(executionRecovery) + "\n"
    : "";
  const retryBlock = testFailureRetry
    ? "\n\n" + formatTestFailureRetryBlock(testFailureRetry) + "\n"
    : "";
  return [
    "### AUTOMATION — DO NOT ASK FOR THE ASSIGNMENT",
    "The task below is complete and authoritative. There is no human to answer questions.",
    "Original user goal: " + (run.problem.trim() || "(none)"),
    "Task id: " + task.id,
    "Worktree root (pipeline checks git only here): " + worktree,
    "",
    body,
    attachmentBlock,
    recoveryBlock,
    retryBlock,
  ].join("\n");
}

export type ExecutionResult = {
  run: RunState;
  /** When set, automated pipeline should stop with this user-facing message */
  pipelineAbort?: string;
};

export async function runExecution(
  run: RunState,
  task: Task,
  pipelineRunId?: string,
  execOpts?: {
    testFailureRetry?: TestFailureRetryContext;
    executionRecovery?: ExecutionRecoveryContext;
  }
): Promise<ExecutionResult> {
  const cfg = loadConfig();
  const persisted = getRun(run.id);
  if (persisted) {
    run.problem = persisted.problem;
    run.attachments = persisted.attachments;
  }
  if (!task.assignedWorktreePath) {
    throw new Error("Task has no worktree path; assign worktree first.");
  }
  run.phase = "executing";
  run.currentTaskId = task.id;
  touchRun(run);
  const retryHdr = execOpts?.testFailureRetry
    ? (() => {
        const mr = execOpts.testFailureRetry.maxRounds;
        const mrLbl = Number.isFinite(mr) ? String(Math.trunc(mr)) : "∞";
        return `--- Execution (fix retry ${execOpts.testFailureRetry.executionRound}/${mrLbl}): ${task.title} ---\n`;
      })()
    : execOpts?.executionRecovery
      ? `--- Execution (recovery ${execOpts.executionRecovery.attempt}/${execOpts.executionRecovery.maxAttempts}): ${task.title} ---\n`
    : `--- Execution: task ${task.title} ---\n`;
  publish(run.id, retryHdr);

  const headBefore = getWorktreeHead(task.assignedWorktreePath);
  if (headBefore === null) {
    publish(
      run.id,
      "--- Warning: could not read git HEAD in worktree; cannot verify agent wrote files. ---\n"
    );
  }

  const prompt = buildExecutionPrompt(
    run,
    task,
    execOpts?.testFailureRetry,
    execOpts?.executionRecovery
  );
  const res = await runCursorAgent({
    prompt,
    cwd: task.assignedWorktreePath,
    onChunk: (c) => publish(run.id, c),
    pipelineRunId,
    phase: "execution",
    model: resolveAgentModelForPhase(run, "execution"),
  });

  const delta =
    !cfg.dryRun && headBefore !== null
      ? worktreeGitDelta(task.assignedWorktreePath, headBefore)
      : null;

  let finalStatus: TaskStatus = res.exitCode === 0 ? "testing" : "failed";
  let summary: string;
  let pipelineAbort: string | undefined;
  const metadata: Record<string, unknown> = {};

  if (res.exitCode !== 0) {
    if (delta?.changed) {
      finalStatus = "testing";
      summary =
        `Execution agent exited ${res.exitCode} for task "${task.title}", but the worktree has changes (${delta.detail}) — ` +
        `treating as success (e.g. Stop after a hung agent, or timeout after edits). Proceeding to Godot tests.`;
      publish(run.id, `--- ${summary} ---\n`);
    } else {
      summary = `Execution agent exited ${res.exitCode} for task "${task.title}".`;
    }
  } else {
    const strictNoChange =
      cfg.requireExecutionGitChanges && delta && !delta.changed;
    if (strictNoChange) {
      finalStatus = "failed";
      summary =
        `Execution produced no git changes (${delta.detail}). ` +
        `Interactive \`cursor agent "…"\` in a terminal is not the same as the headless child spawned by this server (no TTY). ` +
        `For headless/CI, Cursor docs often require \`CURSOR_API_KEY\` in the environment — set it for the Node process (or \`cursorCli.env\` in orchestration.config.local.json). ` +
        `Upgrade Cursor if \`agent --print\` shows Electron warnings. See orchestration/README.md (Headless agent).`;
      pipelineAbort = summary;
      metadata.noGitChanges = true;
      publish(run.id, `--- ${summary} ---\n`);
    } else {
      summary = `Execution agent finished for task "${task.title}".`;
    }
  }

  updateTask(run, task.id, {
    status: finalStatus,
  });
  if (execOpts?.testFailureRetry) {
    metadata.testFixRetryExecutionRound = execOpts.testFailureRetry.executionRound;
    const mr = execOpts.testFailureRetry.maxRounds;
    metadata.testFixRetryMaxRounds = Number.isFinite(mr) ? mr : "unlimited";
  }
  if (execOpts?.executionRecovery) {
    metadata.executionRecoveryAttempt = execOpts.executionRecovery.attempt;
    metadata.executionRecoveryMaxAttempts = execOpts.executionRecovery.maxAttempts;
  }
  appendOutcome(run, {
    id: newId("out"),
    kind: "execution",
    taskId: task.id,
    at: new Date().toISOString(),
    exitCode: res.exitCode,
    summary,
    logTail: (res.stdout + "\n" + res.stderr).slice(-8000),
    metadata: Object.keys(metadata).length ? metadata : undefined,
  });
  run.phase = "orchestrating";
  delete run.currentTaskId;
  touchRun(run);
  return { run, pipelineAbort };
}
