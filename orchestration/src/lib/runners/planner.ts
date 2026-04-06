import { readFileSync } from "node:fs";
import { promptPath } from "../paths.js";
import { runCursorAgent } from "./cursor-cli.js";
import { loadConfig } from "../config.js";
import type { Task, RunState } from "../types.js";
import { newId, touchRun, appendOutcome } from "../store.js";
import { publish } from "../log-bus.js";

interface RawTask {
  title: string;
  description: string;
  acceptance: string[];
  filesHint?: string[];
  /** Indices into the raw tasks array */
  dependsOn?: number[];
}

interface PlannerJson {
  tasks: RawTask[];
}

function tryParsePlannerJson(raw: string): PlannerJson | null {
  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const tasks = parsed.tasks ?? parsed.Tasks;
    if (!Array.isArray(tasks)) return null;
    return { tasks: tasks as RawTask[] };
  } catch {
    return null;
  }
}

/**
 * `cursor agent --output-format json` prints one JSON envelope; the assistant reply
 * (with fenced planner JSON) lives in `result`, not at the top level.
 */
function unwrapCursorAgentStdout(text: string): string {
  const t = text.trim();
  if (!t.startsWith("{")) return text;
  try {
    const o = JSON.parse(t) as Record<string, unknown>;
    if (Array.isArray(o.tasks) || Array.isArray(o.Tasks)) {
      return text;
    }
    for (const key of ["result", "text", "message", "output"] as const) {
      const v = o[key];
      if (typeof v === "string" && v.trim().length > 0) return v;
    }
  } catch {
    /* not a single JSON object */
  }
  return text;
}

/** Extract one JSON object starting at `start` with string-aware brace matching. */
function extractBalancedObject(text: string, start: number): string | null {
  if (text[start] !== "{") return null;
  let depth = 0;
  let inString = false;
  let escape = false;
  for (let i = start; i < text.length; i++) {
    const c = text[i];
    if (inString) {
      if (escape) {
        escape = false;
        continue;
      }
      if (c === "\\") {
        escape = true;
        continue;
      }
      if (c === '"') inString = false;
      continue;
    }
    if (c === '"') {
      inString = true;
      continue;
    }
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return text.slice(start, i + 1);
    }
  }
  return null;
}

/**
 * Find JSON objects that contain `"tasks"` (Cursor often prints plain JSON without fences).
 */
function extractJsonNearTasksKey(text: string): string | null {
  const needle = '"tasks"';
  let search = 0;
  while (search < text.length) {
    const tasksIdx = text.indexOf(needle, search);
    if (tasksIdx < 0) break;
    let braceStart = text.lastIndexOf("{", tasksIdx);
    while (braceStart >= 0) {
      const obj = extractBalancedObject(text, braceStart);
      if (obj && tryParsePlannerJson(obj)) return obj;
      braceStart = text.lastIndexOf("{", braceStart - 1);
    }
    search = tasksIdx + 1;
  }
  return null;
}

/**
 * Models often emit several ``` fences (thinking + JSON). Try every fenced block,
 * JSON near `"tasks"`, then first `{`…last `}` slice.
 */
function extractJsonBlock(text: string): string {
  const fenceRe = /```(?:json)?\s*([\s\S]*?)```/gi;
  let m: RegExpExecArray | null;
  while ((m = fenceRe.exec(text)) !== null) {
    const block = m[1].trim();
    if (!block.startsWith("{")) continue;
    if (tryParsePlannerJson(block)) return block;
  }
  const nearTasks = extractJsonNearTasksKey(text);
  if (nearTasks) return nearTasks;
  const trimmed = text.trim();
  if (trimmed.startsWith("{") && tryParsePlannerJson(trimmed)) return trimmed;
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start >= 0 && end > start) {
    const slice = text.slice(start, end + 1);
    if (tryParsePlannerJson(slice)) return slice;
  }
  throw new Error(
    "Planner output did not contain parseable JSON with a tasks array (expected JSON with a tasks array, fenced or plain)."
  );
}

function parsePlannerOutput(combined: string): PlannerJson {
  const unwrapped = unwrapCursorAgentStdout(combined);
  const raw = extractJsonBlock(unwrapped);
  const parsed = tryParsePlannerJson(raw);
  if (!parsed) {
    throw new Error("Planner JSON missing tasks[]");
  }
  return parsed;
}

function buildFallbackTasks(problem: string): Task[] {
  const now = new Date().toISOString();
  const firstLine = problem.trim().split("\n")[0] || "Implement requested change";
  return [
    {
      id: newId("task"),
      title: firstLine.slice(0, 200),
      description:
        "Planner fallback: the Cursor agent returned no captured stdout/stderr (typical for non-TTY / some Windows CLI builds). Implement the following.\n\n" +
        problem.trim(),
      acceptance: [
        "Behavior matches the problem statement",
        "Godot project still loads and tests pass where applicable",
      ],
      status: "pending",
      createdAt: now,
      updatedAt: now,
    },
  ];
}

function rawToTasks(raw: PlannerJson): Task[] {
  const now = new Date().toISOString();
  const ids: string[] = raw.tasks.map(() => newId("task"));
  const out: Task[] = [];
  for (let i = 0; i < raw.tasks.length; i++) {
    const r = raw.tasks[i];
    const depIndices = r.dependsOn ?? [];
    const dependsOn = depIndices.map((idx) => {
      if (idx < 0 || idx >= i || idx >= ids.length) {
        throw new Error(
          `Invalid dependsOn index ${idx} for task ${i} (must refer to earlier tasks only)`
        );
      }
      return ids[idx];
    });
    out.push({
      id: ids[i],
      title: r.title,
      description: r.description,
      acceptance: Array.isArray(r.acceptance) ? r.acceptance : [],
      filesHint: r.filesHint,
      dependsOn,
      status: "pending",
      createdAt: now,
      updatedAt: now,
    });
  }
  return out;
}

export async function runPlanner(
  run: RunState,
  pipelineRunId?: string
): Promise<RunState> {
  const cfg = loadConfig();
  run.phase = "planning";
  touchRun(run);
  const template = readFileSync(promptPath("planner.md"), "utf8");
  const prompt = template.replace(/\{\{PROBLEM\}\}/g, run.problem || "(no problem text)");
  publish(run.id, "--- Planner: starting Cursor agent ---\n");

  const res = await runCursorAgent({
    prompt,
    cwd: cfg.repoRoot,
    onChunk: (c) => publish(run.id, c),
    pipelineRunId,
  });

  let summary = "Planner finished with exit " + res.exitCode;
  let tasks: Task[] = [];
  const combined = `${res.stdout}\n\n${res.stderr}`.trim();

  if (combined.length === 0 && cfg.plannerFallback) {
    tasks = buildFallbackTasks(run.problem || "");
    summary = `Planner fallback: Cursor agent returned no output (empty stdout/stderr). Created ${tasks.length} task(s) from the problem text. Disable with plannerFallback: false or env ORCH_PLANNER_FALLBACK=0.`;
    publish(run.id, `--- ${summary} ---\n`);
    publish(
      run.id,
      "--- Hint: set CURSOR_CLI to the full path of cursor.cmd; for empty output from a headless child, set CURSOR_API_KEY (see Cursor CLI headless docs) or cursorCli.env in orchestration.config.local.json. ---\n"
    );
    run.backlog = tasks;
    run.phase = tasks.length ? "orchestrating" : "idle";
    appendOutcome(run, {
      id: newId("out"),
      kind: "planner",
      at: new Date().toISOString(),
      exitCode: res.exitCode,
      summary,
      logTail: "",
      metadata: { fallback: true },
    });
    touchRun(run);
    return run;
  }

  try {
    const parsed = parsePlannerOutput(combined);
    tasks = rawToTasks(parsed);
    summary = `Planner produced ${tasks.length} task(s).`;
    if (
      tasks.length === 0 &&
      (run.problem?.trim() ?? "").length > 0
    ) {
      summary +=
        " Model returned empty tasks[] — output must include at least one task (see planner prompt).";
    }
    if (res.exitCode !== 0) {
      summary = `Planner CLI exited ${res.exitCode}; parsed backlog anyway. ${summary}`;
    }
  } catch (e) {
    const hint =
      combined.length === 0
        ? " (no stdout/stderr from Cursor agent — check CLI login and agent args.)"
        : "";
    const preview =
      combined.length > 600
        ? `${combined.slice(0, 600)}…`
        : combined;
    summary = `Planner parse error: ${e instanceof Error ? e.message : String(e)}${hint}`;
    if (combined.length > 0) {
      summary += ` Output preview: ${preview.replace(/\s+/g, " ").trim()}`;
    }
    if (res.exitCode !== 0) {
      summary = `Planner CLI exited ${res.exitCode}. ${summary}`;
    }
  }

  publish(run.id, `--- ${summary} ---\n`);

  run.backlog = tasks;
  run.phase = tasks.length ? "orchestrating" : "idle";
  appendOutcome(run, {
    id: newId("out"),
    kind: "planner",
    at: new Date().toISOString(),
    exitCode: res.exitCode,
    summary,
    logTail: (res.stdout + "\n" + res.stderr).slice(-8000),
  });
  touchRun(run);
  return run;
}
