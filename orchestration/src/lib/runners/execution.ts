import { readFileSync } from "node:fs";
import { promptPath } from "../paths.js";
import { runCursorAgent } from "./cursor-cli.js";
import { loadConfig } from "../config.js";
import type { Task, RunState, TaskStatus } from "../types.js";
import { getRun, newId, appendOutcome, touchRun, updateTask } from "../store.js";
import { publish } from "../log-bus.js";
import {
  getWorktreeHead,
  worktreeGitDelta,
} from "../worktree.js";
import { formatAttachmentContextForPrompt } from "../attachments.js";

function buildExecutionPrompt(
  run: RunState,
  task: Task
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
  return [
    "### AUTOMATION — DO NOT ASK FOR THE ASSIGNMENT",
    "The task below is complete and authoritative. There is no human to answer questions.",
    "Original user goal: " + (run.problem.trim() || "(none)"),
    "Task id: " + task.id,
    "Worktree root (pipeline checks git only here): " + worktree,
    "",
    body,
    attachmentBlock,
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
  pipelineRunId?: string
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
  publish(run.id, `--- Execution: task ${task.title} ---\n`);

  const headBefore = getWorktreeHead(task.assignedWorktreePath);
  if (headBefore === null) {
    publish(
      run.id,
      "--- Warning: could not read git HEAD in worktree; cannot verify agent wrote files. ---\n"
    );
  }

  const prompt = buildExecutionPrompt(run, task);
  const res = await runCursorAgent({
    prompt,
    cwd: task.assignedWorktreePath,
    onChunk: (c) => publish(run.id, c),
    pipelineRunId,
    phase: "execution",
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
