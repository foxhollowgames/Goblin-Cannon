/**
 * Cursor Agent CLI accepts `--model <id>` (see Cursor headless docs). Used for dashboard + API validation.
 */

import type { RunState } from "./types.js";

const MODEL_RE = /^[a-zA-Z0-9._-]{1,128}$/;

export function isValidAgentModelId(s: string): boolean {
  return MODEL_RE.test(s);
}

export type ParseAgentModelResult =
  | { ok: true; value: string | undefined }
  | { ok: false; error: string };

const MODEL_ERR =
  "must be 1–128 characters: letters, digits, . _ - (or leave empty for CLI default)";

/**
 * Parses optional `agentModel` from JSON or multipart fields. Empty → undefined.
 */
export function parseAgentModelInput(raw: unknown): ParseAgentModelResult {
  if (raw === undefined || raw === null) return { ok: true, value: undefined };
  const s = String(raw).trim();
  if (!s) return { ok: true, value: undefined };
  if (!isValidAgentModelId(s)) {
    return {
      ok: false,
      error: MODEL_ERR,
    };
  }
  return { ok: true, value: s };
}

/** Stored on `RunState` — all optional; `agentModel` is fallback when a phase field is empty. */
export interface RunAgentModelsPayload {
  agentModel?: string;
  agentModelPlanner?: string;
  agentModelExecution?: string;
  agentModelCommunication?: string;
}

export type ParseRunAgentModelsResult =
  | { ok: true; value: RunAgentModelsPayload }
  | { ok: false; error: string };

export function parseRunAgentModelsFromBody(
  raw: Record<string, unknown>
): ParseRunAgentModelsResult {
  const keys = [
    "agentModel",
    "agentModelPlanner",
    "agentModelExecution",
    "agentModelCommunication",
  ] as const;
  const out: RunAgentModelsPayload = {};
  for (const k of keys) {
    if (raw[k] === undefined || raw[k] === null) continue;
    const p = parseAgentModelInput(raw[k]);
    if (!p.ok) {
      return { ok: false, error: `${k}: ${p.error}` };
    }
    if (p.value === undefined) continue;
    if (k === "agentModel") out.agentModel = p.value;
    else if (k === "agentModelPlanner") out.agentModelPlanner = p.value;
    else if (k === "agentModelExecution") out.agentModelExecution = p.value;
    else out.agentModelCommunication = p.value;
  }
  return { ok: true, value: out };
}

export function resolveAgentModelForPhase(
  run: RunState,
  phase: "planner" | "execution" | "communication"
): string | undefined {
  const phaseVal =
    phase === "planner"
      ? run.agentModelPlanner
      : phase === "execution"
        ? run.agentModelExecution
        : run.agentModelCommunication;
  const v = phaseVal?.trim() || run.agentModel?.trim();
  return v || undefined;
}
