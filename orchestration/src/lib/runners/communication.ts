import { readFileSync } from "node:fs";
import { stripElectronCliNoise } from "../electron-cli-noise.js";
import { promptPath } from "../paths.js";
import { runCursorAgent } from "./cursor-cli.js";
import { loadConfig } from "../config.js";
import type { RunState } from "../types.js";
import { getRun, newId, appendOutcome, touchRun } from "../store.js";
import { publish } from "../log-bus.js";
import { formatAttachmentContextForPrompt } from "../attachments.js";

export async function runCommunication(
  run: RunState,
  pipelineRunId?: string
): Promise<RunState> {
  const cfg = loadConfig();
  run.phase = "reporting";
  touchRun(run);
  const persisted = getRun(run.id);
  if (persisted) {
    run.problem = persisted.problem;
    run.attachments = persisted.attachments;
  }
  const template = readFileSync(promptPath("communication.md"), "utf8");
  const payload = {
    runId: run.id,
    problem: run.problem,
    phase: run.phase,
    baselineTestSummary: run.baselineTestSummary,
    backlog: run.backlog,
    outcomes: run.outcomes,
  };
  const json = JSON.stringify(payload, null, 2);
  const attachmentBlock = formatAttachmentContextForPrompt(run);
  const prompt = template.replace(/\{\{RUN_JSON\}\}/g, json) + attachmentBlock;
  publish(run.id, "--- Communication: generating report ---\n");

  const res = await runCursorAgent({
    prompt,
    cwd: cfg.repoRoot,
    onChunk: (c) => publish(run.id, c),
    pipelineRunId,
    phase: "communication",
    model: run.agentModel,
  });

  const reportOut = stripElectronCliNoise(res.stdout).trim();
  const reportErr = stripElectronCliNoise(res.stderr);
  run.communicationReport =
    res.exitCode === 0
      ? reportOut
      : `Report generation failed (exit ${res.exitCode}).\n\n${reportErr.slice(-4000)}`;
  appendOutcome(run, {
    id: newId("out"),
    kind: "communication",
    at: new Date().toISOString(),
    exitCode: res.exitCode,
    summary: "Communication agent report generated.",
    logTail: (res.stdout + "\n" + res.stderr).slice(-8000),
  });
  run.phase = "idle";
  touchRun(run);
  return run;
}
