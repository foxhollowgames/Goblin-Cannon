/**
 * Cursor Agent CLI accepts `--model <id>` (see Cursor headless docs). Used for dashboard + API validation.
 */

const MODEL_RE = /^[a-zA-Z0-9._-]{1,128}$/;

export function isValidAgentModelId(s: string): boolean {
  return MODEL_RE.test(s);
}

export type ParseAgentModelResult =
  | { ok: true; value: string | undefined }
  | { ok: false; error: string };

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
      error: "agentModel must be 1–128 characters: letters, digits, . _ -",
    };
  }
  return { ok: true, value: s };
}
