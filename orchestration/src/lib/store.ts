import {
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
  existsSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { randomBytes } from "node:crypto";
import type { ProblemAttachment, RunState, Task, Outcome } from "./types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

export function dataDir(): string {
  return join(resolvePackageRoot(), "data");
}

function resolvePackageRoot(): string {
  return join(__dirname, "../..");
}

interface PersistedState {
  runs: Record<string, RunState>;
}

function emptyPersisted(): PersistedState {
  return { runs: {} };
}

function statePath(): string {
  return join(dataDir(), "state.json");
}

export function ensureDataDir(): void {
  mkdirSync(dataDir(), { recursive: true });
}

export function loadPersisted(): PersistedState {
  ensureDataDir();
  const p = statePath();
  if (!existsSync(p)) return emptyPersisted();
  try {
    const raw = readFileSync(p, "utf8");
    const parsed = JSON.parse(raw) as PersistedState;
    if (!parsed.runs || typeof parsed.runs !== "object") return emptyPersisted();
    return parsed;
  } catch {
    return emptyPersisted();
  }
}

export function savePersisted(state: PersistedState): void {
  ensureDataDir();
  const p = statePath();
  const tmp = `${p}.${randomBytes(8).toString("hex")}.tmp`;
  writeFileSync(tmp, JSON.stringify(state, null, 2), "utf8");
  renameSync(tmp, p);
}

export function newId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${randomBytes(4).toString("hex")}`;
}

export function getRun(id: string): RunState | undefined {
  return loadPersisted().runs[id];
}

export function saveRun(run: RunState): void {
  const p = loadPersisted();
  p.runs[run.id] = run;
  savePersisted(p);
}

export function listRuns(): RunState[] {
  return Object.values(loadPersisted().runs).sort(
    (a, b) => b.createdAt.localeCompare(a.createdAt)
  );
}

export function createRun(
  problem: string,
  maxParallel: number,
  attachments?: ProblemAttachment[]
): RunState {
  const now = new Date().toISOString();
  const run: RunState = {
    id: newId("run"),
    problem: problem.trim(),
    attachments: attachments?.length ? [...attachments] : undefined,
    phase: "idle",
    pipelineStatus: "idle",
    pipelineMessage: "",
    backlog: [],
    limits: { maxParallelWorktrees: maxParallel },
    activeWorktreePaths: [],
    outcomes: [],
    createdAt: now,
    updatedAt: now,
  };
  saveRun(run);
  return run;
}

export function touchRun(run: RunState): RunState {
  run.updatedAt = new Date().toISOString();
  saveRun(run);
  return run;
}

export function appendOutcome(run: RunState, outcome: Outcome): RunState {
  run.outcomes.push(outcome);
  return touchRun(run);
}

export function setBacklog(run: RunState, tasks: Task[]): RunState {
  run.backlog = tasks;
  return touchRun(run);
}

export function updateTask(run: RunState, taskId: string, patch: Partial<Task>): RunState {
  const i = run.backlog.findIndex((t) => t.id === taskId);
  if (i >= 0) {
    run.backlog[i] = {
      ...run.backlog[i],
      ...patch,
      updatedAt: new Date().toISOString(),
    };
  }
  return touchRun(run);
}
