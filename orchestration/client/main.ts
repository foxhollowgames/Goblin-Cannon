/**
 * JSON API helper. Fastify rejects `Content-Type: application/json` with an empty
 * body (400). For POST/PUT/PATCH without a body, we send `{}`.
 */
const api = (path: string, init?: RequestInit) => {
  const method = (init?.method ?? "GET").toUpperCase();
  let body = init?.body;
  if (
    ["POST", "PUT", "PATCH"].includes(method) &&
    (body === undefined || body === null)
  ) {
    body = "{}";
  }
  return fetch(`/api${path}`, {
    ...init,
    body: body ?? undefined,
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });
};

async function readHttpError(r: Response): Promise<string> {
  try {
    const j = (await r.json()) as { error?: string };
    if (j.error) return j.error;
  } catch {
    /* ignore */
  }
  return r.statusText || `HTTP ${r.status}`;
}

function setProblemStatus(
  message: string,
  kind: "ok" | "error" | "info" = "info"
) {
  const el = document.getElementById("problemStatus");
  if (!el) return;
  el.textContent = message;
  el.classList.remove("ok", "error");
  if (kind === "ok") el.classList.add("ok");
  if (kind === "error") el.classList.add("error");
}

const RUN_STORAGE_KEY = "goblinOrchRunId";

const AGENT_MODEL_ID_RE = /^[a-zA-Z0-9._-]{1,128}$/;

/** Built-in + config; used for searchable suggestions. */
let lastAgentModelCatalog: string[] = [];
let modelCombosInitialized = false;
let modelComboDocListener = false;

const MODEL_INPUT_LS: Record<string, string> = {
  agentModelPlannerInput: "goblinOrchAgentModelPlanner",
  agentModelExecutionInput: "goblinOrchAgentModelExecution",
  agentModelCommunicationInput: "goblinOrchAgentModelCommunication",
  agentModelFallbackInput: "goblinOrchAgentModel",
};

function persistRunId(id: string | null) {
  try {
    if (id) sessionStorage.setItem(RUN_STORAGE_KEY, id);
    else sessionStorage.removeItem(RUN_STORAGE_KEY);
  } catch {
    /* storage blocked */
  }
}

let currentRunId: string | null = null;
/** Default from GET /api/config — used to seed the concurrent-tasks input. */
let lastConfigMaxParallel = 4;
/** Local files queued for the next Send (multipart). Cleared after a run is created. */
let pendingAttachments: File[] = [];
let eventSource: EventSource | null = null;
let pollTimer: ReturnType<typeof setInterval> | null = null;
let dungeonInterval: ReturnType<typeof setInterval> | null = null;
let dungeonStart = 0;
const DUNGEON_WINDOW_MS = 120_000;

function setPhaseUI(phase: string) {
  const el = document.getElementById("phaseLabel");
  if (el) el.textContent = `Phase: ${phase}`;
  const idle =
    phase === "idle" || phase === "orchestrating" || phase === "";
  if (idle && dungeonInterval) {
    clearInterval(dungeonInterval);
    dungeonInterval = null;
    document.documentElement.style.setProperty("--dungeon-depth", "0%");
    const t = document.getElementById("dungeonTimer");
    if (t) t.textContent = "—";
  }
  if (!idle && !dungeonInterval) {
    dungeonStart = Date.now();
    const timerEl = document.getElementById("dungeonTimer");
    dungeonInterval = setInterval(() => {
      const elapsed = Date.now() - dungeonStart;
      const p = Math.min(100, (elapsed / DUNGEON_WINDOW_MS) * 100);
      document.documentElement.style.setProperty("--dungeon-depth", `${p}%`);
      const bar = document.getElementById("dungeonBar");
      if (bar) bar.setAttribute("aria-valuenow", String(Math.round(p)));
      if (timerEl) {
        timerEl.textContent = `${(elapsed / 1000).toFixed(1)}s`;
      }
    }, 250);
  }
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

function startPolling() {
  stopPolling();
  pollTimer = setInterval(() => {
    void loadRun();
  }, 1500);
}

/**
 * Opens SSE first so logs aren't missed; resolves when the connection is ready (or on error).
 */
function connectLogStream(runId: string): Promise<void> {
  eventSource?.close();
  const log = document.getElementById("log");
  if (log) log.textContent = "";
  return new Promise((resolve) => {
    const es = new EventSource(`/api/runs/${runId}/stream`);
    eventSource = es;
    let settled = false;
    const finish = () => {
      if (settled) return;
      settled = true;
      resolve();
    };
    es.addEventListener("open", finish, { once: true });
    setTimeout(finish, 3000);
    es.onmessage = (ev) => {
      try {
        const j = JSON.parse(ev.data) as { line?: string };
        if (j.line && log) log.textContent += j.line;
        if (log) log.scrollTop = log.scrollHeight;
      } catch {
        /* ignore */
      }
    };
  });
}

function setControlsForPipeline(running: boolean) {
  const send = document.getElementById("btnSend") as HTMLButtonElement | null;
  const stop = document.getElementById("btnStop") as HTMLButtonElement | null;
  if (send) send.disabled = running;
  if (stop) stop.disabled = !running;
}

async function refreshConfig() {
  const r = await api("/config");
  const c = (await r.json()) as {
    hasGodotPath: boolean;
    limits: { maxParallelWorktrees: number };
    dryRun: boolean;
    agentModelCatalog?: string[];
    agentModelOptions?: string[];
    cursorCliResolved?: string;
    cursorCliFoundOnDisk?: boolean;
    cursorApiKeyConfigured?: boolean;
  };
  const hint = document.getElementById("cursorHint");
  if (hint && c.cursorCliResolved) {
    const ok = c.cursorCliFoundOnDisk !== false;
    hint.textContent = ok
      ? `Cursor CLI: ${c.cursorCliResolved}`
      : `Cursor CLI not found — set env CURSOR_CLI to the full path. (${c.cursorCliResolved})`;
    hint.style.color = ok ? "" : "var(--danger)";
  }
  const keyHint = document.getElementById("apiKeyHint");
  if (keyHint) {
    if (c.cursorApiKeyConfigured) {
      keyHint.textContent =
        "CURSOR_API_KEY: configured (process environment or cursorCli.env in orchestration.config.local.json)";
      keyHint.style.color = "";
    } else {
      keyHint.textContent =
        "CURSOR_API_KEY: not detected — set in User env vars or under cursorCli.env in orchestration.config.local.json, then restart npm start";
      keyHint.style.color = "var(--danger)";
    }
  }
  lastConfigMaxParallel = Math.max(
    1,
    Math.min(32, c.limits?.maxParallelWorktrees ?? 4)
  );
  const parInp = document.getElementById(
    "maxParallelInput"
  ) as HTMLInputElement | null;
  if (parInp) parInp.value = String(lastConfigMaxParallel);
  lastAgentModelCatalog = Array.isArray(c.agentModelCatalog)
    ? c.agentModelCatalog
    : [];
  initModelCombos();
  restoreModelInputsFromStorage();
}

function parallelLimitForNewRun(): number {
  const inp = document.getElementById(
    "maxParallelInput"
  ) as HTMLInputElement | null;
  const raw = parseInt(inp?.value ?? "", 10);
  if (Number.isFinite(raw) && raw >= 1) {
    return Math.min(32, raw);
  }
  return lastConfigMaxParallel;
}

function restoreModelInputsFromStorage() {
  for (const [inputId, lsKey] of Object.entries(MODEL_INPUT_LS)) {
    const inp = document.getElementById(inputId) as HTMLInputElement | null;
    if (!inp) continue;
    try {
      const v = localStorage.getItem(lsKey);
      if (v !== null) inp.value = v;
    } catch {
      /* ignore */
    }
  }
}

function persistModelInput(inputId: string, value: string) {
  const key = MODEL_INPUT_LS[inputId];
  if (!key) return;
  try {
    localStorage.setItem(key, value);
  } catch {
    /* ignore */
  }
}

function initModelCombos() {
  const pairs: [string, string][] = [
    ["agentModelPlannerInput", "agentModelPlannerSuggest"],
    ["agentModelExecutionInput", "agentModelExecutionSuggest"],
    ["agentModelCommunicationInput", "agentModelCommunicationSuggest"],
    ["agentModelFallbackInput", "agentModelFallbackSuggest"],
  ];
  const combos = pairs
    .map(([inputId, ulId]) => ({
      inputId,
      input: document.getElementById(inputId) as HTMLInputElement | null,
      ul: document.getElementById(ulId) as HTMLUListElement | null,
    }))
    .filter((x) => x.input && x.ul) as Array<{
    inputId: string;
    input: HTMLInputElement;
    ul: HTMLUListElement;
  }>;

  if (combos.length === 0) return;

  const getCatalog = () => lastAgentModelCatalog;

  const closeAll = () => {
    for (const { ul } of combos) {
      ul.hidden = true;
      ul.classList.remove("open");
    }
  };

  const render = (input: HTMLInputElement, ul: HTMLUListElement) => {
    const q = input.value.trim().toLowerCase();
    const cat = getCatalog();
    const filtered = !q
      ? cat
      : cat.filter((id) => id.toLowerCase().includes(q));
    const take = filtered.slice(0, 80);
    ul.innerHTML = take
      .map((id) => {
        const safe = escapeAttr(id);
        return `<li role="option" tabindex="-1" data-id="${safe}">${escapeHtml(id)}</li>`;
      })
      .join("");
  };

  if (!modelCombosInitialized) {
    modelCombosInitialized = true;
    for (const { inputId, input, ul } of combos) {
      const open = () => {
        render(input, ul);
        ul.hidden = false;
        ul.classList.add("open");
      };

      input.addEventListener("focus", open);
      input.addEventListener("input", () => {
        open();
        persistModelInput(inputId, input.value);
      });
      ul.addEventListener("mousedown", (e) => {
        const li = (e.target as HTMLElement).closest("li[data-id]");
        if (!li) return;
        e.preventDefault();
        const id = li.getAttribute("data-id") ?? "";
        input.value = id;
        persistModelInput(inputId, id);
        closeAll();
      });
    }
  }

  if (!modelComboDocListener) {
    modelComboDocListener = true;
    document.addEventListener("click", (e) => {
      const t = e.target as Node;
      if (
        [...document.querySelectorAll(".model-combo")].some((c) =>
          c.contains(t)
        )
      ) {
        return;
      }
      closeAll();
    });
  }
}

function agentModelsForSubmit(): {
  payload: Record<string, string>;
  error?: string;
} {
  const fields: [key: string, inputId: string][] = [
    ["agentModel", "agentModelFallbackInput"],
    ["agentModelPlanner", "agentModelPlannerInput"],
    ["agentModelExecution", "agentModelExecutionInput"],
    ["agentModelCommunication", "agentModelCommunicationInput"],
  ];
  const payload: Record<string, string> = {};
  for (const [key, inputId] of fields) {
    const v =
      (document.getElementById(inputId) as HTMLInputElement | null)?.value?.trim() ??
      "";
    if (!v) continue;
    if (!AGENT_MODEL_ID_RE.test(v)) {
      return {
        payload: {},
        error: `Model id (${key}): use letters, digits, . _ - only (1–128 characters), or leave empty.`,
      };
    }
    payload[key] = v;
  }
  return { payload };
}

function formatRunModelsLine(run: {
  agentModel?: string;
  agentModelPlanner?: string;
  agentModelExecution?: string;
  agentModelCommunication?: string;
}): string {
  const t = (s?: string) => s?.trim() ?? "";
  const fb = t(run.agentModel);
  const hasPhase =
    t(run.agentModelPlanner) ||
    t(run.agentModelExecution) ||
    t(run.agentModelCommunication);
  if (!fb && !hasPhase) return "Default (CLI)";
  const plan = t(run.agentModelPlanner) || fb || "CLI default";
  const exec = t(run.agentModelExecution) || fb || "CLI default";
  const rep = t(run.agentModelCommunication) || fb || "CLI default";
  return `Plan: ${plan} · Exec: ${exec} · Report: ${rep}`;
}

/** Session run id, or the Run id field when you paste a run without using Send in this tab. */
function effectiveRecoverRunId(): string {
  if (currentRunId) return currentRunId;
  return (
    document.getElementById("recoverRunIdInput") as HTMLInputElement | null
  )?.value.trim() ?? "";
}

function syncRecoverPanel() {
  const btn = document.getElementById(
    "btnRecoverManual"
  ) as HTMLButtonElement | null;
  const hint = document.getElementById("recoverManualHint");
  const runId = effectiveRecoverRunId().trim();
  const canSubmit = Boolean(runId);
  if (btn) {
    btn.disabled = !canSubmit;
    btn.title = canSubmit
      ? "Run Godot tests for every recoverable unfinished task (worktree + failed/assigned/testing)."
      : "Paste Run id (run_…) or use Send above.";
  }
  if (hint) {
    hint.textContent =
      "Uses Run id only. After Send, it is filled automatically. Skips pending tasks until they have a worktree.";
  }
}

async function loadRun() {
  if (!currentRunId) {
    syncRecoverPanel();
    return;
  }
  const r = await api(`/runs/${currentRunId}`);
  if (!r.ok) return;
  const run = (await r.json()) as {
    id: string;
    problem: string;
    agentModel?: string;
    agentModelPlanner?: string;
    agentModelExecution?: string;
    agentModelCommunication?: string;
    limits?: { maxParallelWorktrees: number };
    attachments?: { id: string; name: string; mime: string }[];
    phase: string;
    pipelineStatus?: string;
    pipelineMessage?: string;
    backlog: Array<{
      id: string;
      title: string;
      status: string;
      assignedWorktreePath?: string;
    }>;
    communicationReport?: string;
  };

  const prob = document.getElementById("problem") as HTMLTextAreaElement;
  if (prob) prob.value = run.problem;

  const rid = document.getElementById("runIdDisplay");
  if (rid) rid.textContent = `Active run: ${run.id}`;

  const runField = document.getElementById(
    "recoverRunIdInput"
  ) as HTMLInputElement | null;
  if (runField) runField.value = run.id;

  const ps = document.getElementById("pipelineState");
  if (ps) ps.textContent = run.pipelineStatus ?? "—";

  const pm = document.getElementById("pipelineStep");
  if (pm) pm.textContent = run.pipelineMessage ?? "—";

  const rc = document.getElementById("runConcurrency");
  if (rc) {
    rc.textContent = run.limits?.maxParallelWorktrees != null
      ? String(run.limits.maxParallelWorktrees)
      : "—";
  }

  const ram = document.getElementById("runAgentModel");
  if (ram) {
    ram.textContent = formatRunModelsLine(run);
  }

  const mp = document.getElementById(
    "agentModelPlannerInput"
  ) as HTMLInputElement | null;
  if (mp) mp.value = run.agentModelPlanner ?? "";
  const me = document.getElementById(
    "agentModelExecutionInput"
  ) as HTMLInputElement | null;
  if (me) me.value = run.agentModelExecution ?? "";
  const mc = document.getElementById(
    "agentModelCommunicationInput"
  ) as HTMLInputElement | null;
  if (mc) mc.value = run.agentModelCommunication ?? "";
  const mf = document.getElementById(
    "agentModelFallbackInput"
  ) as HTMLInputElement | null;
  if (mf) mf.value = run.agentModel ?? "";

  const banner = document.getElementById("pipelineBanner");
  if (banner) {
    banner.textContent = run.pipelineMessage ?? "";
    banner.className = "pipeline-banner";
    const st = run.pipelineStatus ?? "";
    if (st === "running") banner.classList.add("running");
    else if (st === "stopped") banner.classList.add("stopped");
    else if (st === "failed") banner.classList.add("failed");
  }

  const running = run.pipelineStatus === "running";
  setControlsForPipeline(running);
  if (!running) stopPolling();

  const preview = document.getElementById("backlogPreview");
  if (preview) {
    preview.textContent = run.backlog.length
      ? JSON.stringify(run.backlog, null, 2)
      : "(empty)";
  }

  setPhaseUI(run.phase);

  const tl = document.getElementById("taskList");
  if (tl) {
    tl.innerHTML = run.backlog
      .map((t) => {
        const path = t.assignedWorktreePath
          ? ` — ${escapeHtml(t.assignedWorktreePath)}`
          : "";
        return `<li><span class="task-line"><strong>${escapeHtml(t.title)}</strong> — ${escapeHtml(t.status)}${path}</span></li>`;
      })
      .join("");
  }

  const report = document.getElementById("reportOut");
  if (report) {
    report.textContent = run.communicationReport ?? "—";
  }

  renderAttachmentStrip(run.attachments, run.id);

  syncRecoverPanel();
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function escapeAttr(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/"/g, "&quot;");
}

type MediaKind = "image" | "video" | "audio" | "pdf" | "other";

function mediaKindFromMimeAndName(mime: string, name: string): MediaKind {
  const t = (mime || "").toLowerCase();
  if (t.startsWith("image/")) return "image";
  if (t.startsWith("video/")) return "video";
  if (t.startsWith("audio/")) return "audio";
  if (t === "application/pdf") return "pdf";
  const ext = (name.split(".").pop() || "").toLowerCase();
  if (["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg"].includes(ext)) {
    return "image";
  }
  if (["mp4", "webm", "mov", "mkv"].includes(ext)) return "video";
  if (["mp3", "wav", "ogg", "flac", "m4a"].includes(ext)) return "audio";
  if (ext === "pdf") return "pdf";
  return "other";
}

function placeholderThumbHtml(kind: MediaKind): string {
  if (kind === "audio") {
    return `<span class="attachment-chip-thumb-fallback" aria-hidden="true">♪</span>`;
  }
  if (kind === "pdf") {
    return `<span class="attachment-chip-thumb-fallback attachment-chip-thumb-fallback--pdf">PDF</span>`;
  }
  return `<span class="attachment-chip-thumb-fallback" aria-hidden="true">▢</span>`;
}

/** Object URLs for pending File previews — revoked on remove / clear. */
const pendingPreviewUrls = new Map<File, string>();

function ensurePendingPreviewUrl(file: File): string | null {
  const kind = mediaKindFromMimeAndName(file.type, file.name);
  if (kind !== "image" && kind !== "video") return null;
  if (pendingPreviewUrls.has(file)) {
    return pendingPreviewUrls.get(file)!;
  }
  const url = URL.createObjectURL(file);
  pendingPreviewUrls.set(file, url);
  return url;
}

function revokePendingPreviewUrl(file: File): void {
  const u = pendingPreviewUrls.get(file);
  if (u) URL.revokeObjectURL(u);
  pendingPreviewUrls.delete(file);
}

function clearPendingPreviewUrls(): void {
  for (const u of pendingPreviewUrls.values()) URL.revokeObjectURL(u);
  pendingPreviewUrls.clear();
}

function pendingChipHtml(file: File, idx: number): string {
  const kind = mediaKindFromMimeAndName(file.type, file.name);
  const label = escapeHtml(file.name);
  let previewInner: string;
  if (kind === "image" || kind === "video") {
    const u = ensurePendingPreviewUrl(file);
    if (u) {
      const us = escapeAttr(u);
      previewInner =
        kind === "image"
          ? `<img src="${us}" alt="" class="attachment-chip-thumb-img" />`
          : `<video src="${us}" class="attachment-chip-thumb-video" muted playsinline preload="metadata"></video>`;
    } else {
      previewInner = placeholderThumbHtml(kind);
    }
  } else {
    previewInner = placeholderThumbHtml(kind);
  }

  return `<li class="attachment-chip">
    <div class="attachment-chip-preview">${previewInner}</div>
    <div class="attachment-chip-main">
      <span class="attachment-chip-name" title="${label}">${label}</span>
      <button type="button" class="attachment-chip-remove" aria-label="Remove ${label}" data-remove="${idx}">×</button>
    </div>
  </li>`;
}

function serverChipHtml(
  att: { id: string; name: string; mime: string },
  runId: string
): string {
  const kind = mediaKindFromMimeAndName(att.mime, att.name);
  const label = escapeHtml(att.name);
  const src = `/api/runs/${encodeURIComponent(runId)}/attachments/${encodeURIComponent(att.id)}`;
  let previewInner: string;
  if (kind === "image") {
    previewInner = `<img src="${escapeAttr(src)}" alt="" class="attachment-chip-thumb-img" loading="lazy" />`;
  } else if (kind === "video") {
    previewInner = `<video src="${escapeAttr(src)}" class="attachment-chip-thumb-video" muted playsinline preload="metadata"></video>`;
  } else {
    previewInner = placeholderThumbHtml(kind);
  }
  return `<li class="attachment-chip attachment-chip--server">
    <div class="attachment-chip-preview">${previewInner}</div>
    <div class="attachment-chip-main">
      <span class="attachment-chip-name" title="${label}">${label}</span>
    </div>
  </li>`;
}

function isSupportedPasteMediaFile(f: File): boolean {
  const t = (f.type || "").toLowerCase();
  if (t.startsWith("image/") || t.startsWith("video/") || t.startsWith("audio/"))
    return true;
  if (t === "application/pdf") return true;
  if (t === "" || t === "application/octet-stream") return true;
  return false;
}

/** Clipboard screenshots / copied files — browsers expose `files` and/or `items`. */
function filesFromClipboard(data: DataTransfer | null): File[] {
  if (!data) return [];
  const out: File[] = [];
  const seen = new Set<string>();
  const pushUnique = (raw: File) => {
    if (!isSupportedPasteMediaFile(raw)) return;
    const k = `${raw.size}:${raw.lastModified}:${raw.type}`;
    if (seen.has(k)) return;
    seen.add(k);
    out.push(normalizePastedFileName(raw));
  };

  if (data.files?.length) {
    for (let i = 0; i < data.files.length; i++) {
      const f = data.files.item(i);
      if (f) pushUnique(f);
    }
  }
  for (let i = 0; i < (data.items?.length ?? 0); i++) {
    const item = data.items[i];
    if (item.kind !== "file") continue;
    const f = item.getAsFile();
    if (f) pushUnique(f);
  }
  return out;
}

function normalizePastedFileName(f: File): File {
  const n = (f.name || "").trim().toLowerCase();
  const generic =
    !n ||
    n === "image.png" ||
    n === "image.jpeg" ||
    n === "image.jpg" ||
    n === "pasted_image";
  if (!generic) return f;

  const t = (f.type || "").toLowerCase();
  let ext = "bin";
  if (t === "image/png") ext = "png";
  else if (t === "image/jpeg" || t === "image/jpg") ext = "jpg";
  else if (t === "image/webp") ext = "webp";
  else if (t === "image/gif") ext = "gif";
  else if (t.startsWith("video/")) ext = "mp4";
  else if (t.startsWith("audio/")) ext = "mp3";
  else if (t === "application/pdf") ext = "pdf";

  const label = `pasted-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
  return new File([f], label, {
    type: f.type || "application/octet-stream",
  });
}

function renderAttachmentStrip(
  server?: { id: string; name: string; mime: string }[] | undefined,
  runIdForServer?: string
) {
  const ul = document.getElementById("attachmentStrip");
  if (!ul) return;
  if (pendingAttachments.length > 0) {
    ul.innerHTML = pendingAttachments
      .map((file, idx) => pendingChipHtml(file, idx))
      .join("");
    ul.querySelectorAll<HTMLButtonElement>(".attachment-chip-remove").forEach(
      (btn) => {
        btn.addEventListener("click", () => {
          const i = parseInt(btn.getAttribute("data-remove") ?? "-1", 10);
          if (i >= 0 && i < pendingAttachments.length) {
            const [removed] = pendingAttachments.splice(i, 1);
            revokePendingPreviewUrl(removed);
            if (pendingAttachments.length === 0 && currentRunId) {
              void loadRun();
            } else {
              renderAttachmentStrip();
            }
          }
        });
      }
    );
    return;
  }
  if (server?.length && runIdForServer) {
    ul.innerHTML = server
      .map((a) => serverChipHtml(a, runIdForServer))
      .join("");
    return;
  }
  if (server?.length) {
    ul.innerHTML = server
      .map(
        (a) =>
          `<li class="attachment-chip attachment-chip--server"><span class="attachment-chip-name" title="${escapeHtml(a.name)}">${escapeHtml(a.name)}</span> <span class="muted">(${escapeHtml(a.mime)})</span></li>`
      )
      .join("");
    return;
  }
  ul.innerHTML = "";
}

async function recoverUnfinishedForRun() {
  const runId = effectiveRecoverRunId().trim();
  if (!runId) return;
  const btn = document.getElementById(
    "btnRecoverManual"
  ) as HTMLButtonElement | null;
  if (btn) btn.disabled = true;
  try {
    const r = await api(`/runs/${runId}/recover-unfinished`, {
      method: "POST",
      body: "{}",
    });
    let body: {
      error?: string;
      run?: { id: string };
      attempted?: string[];
      skippedLabels?: string[];
      failures?: { title: string; error: string }[];
    };
    try {
      body = (await r.json()) as typeof body;
    } catch {
      setProblemStatus(`HTTP ${r.status}`, "error");
      return;
    }
    if (!r.ok) {
      setProblemStatus(body.error ?? `HTTP ${r.status}`, "error");
      return;
    }
    if (!currentRunId && body.run?.id) {
      currentRunId = body.run.id;
      persistRunId(body.run.id);
    }
    const n = body.attempted?.length ?? 0;
    const failed = body.failures?.length ?? 0;
    const skipN = body.skippedLabels?.length ?? 0;
    const parts = [
      `Batch recover: ${n} recoverable task(s) processed.`,
      failed ? `${failed} failed (see outcomes).` : "All attempts finished.",
      skipN
        ? `${skipN} other unfinished task(s) skipped (no worktree or not failed/assigned/testing).`
        : "",
    ].filter(Boolean);
    setProblemStatus(
      parts.join(" ") +
        " Merge agent branches into main to update your main game files.",
      failed ? "error" : "ok"
    );
    await loadRun();
  } catch (e) {
    setProblemStatus(
      e instanceof Error ? e.message : "Batch recover failed",
      "error"
    );
  } finally {
    syncRecoverPanel();
  }
}

async function restoreRunIfAny(): Promise<boolean> {
  let id: string | null = null;
  try {
    id = sessionStorage.getItem(RUN_STORAGE_KEY);
  } catch {
    return false;
  }
  if (!id) return false;
  const r = await api(`/runs/${id}`);
  if (!r.ok) {
    persistRunId(null);
    return false;
  }
  currentRunId = id;
  await connectLogStream(id);
  await loadRun();
  setProblemStatus(
    "Restored this tab’s last run (refresh keeps backlog + Recover). Send again to start a new run.",
    "info"
  );
  return true;
}

async function submitProblem() {
  const ta = document.getElementById("problem") as HTMLTextAreaElement;
  const btn = document.getElementById("btnSend") as HTMLButtonElement | null;
  const prob = ta?.value.trim() ?? "";
  const hasFiles = pendingAttachments.length > 0;
  if (!prob && !hasFiles) {
    setProblemStatus(
      "Type a problem or add at least one attachment before sending.",
      "error"
    );
    ta?.focus();
    return;
  }
  const am = agentModelsForSubmit();
  if (am.error) {
    setProblemStatus(am.error, "error");
    return;
  }

  btn?.setAttribute("disabled", "true");
  setProblemStatus("Starting run and pipeline…", "info");
  stopPolling();
  try {
    const r = hasFiles
      ? await fetch("/api/runs", {
          method: "POST",
          body: (() => {
            const fd = new FormData();
            fd.append("problem", prob);
            fd.append(
              "maxParallelWorktrees",
              String(parallelLimitForNewRun())
            );
            for (const [k, v] of Object.entries(am.payload)) {
              fd.append(k, v);
            }
            for (const f of pendingAttachments) {
              fd.append("files", f, f.name);
            }
            return fd;
          })(),
        })
      : await api("/runs", {
          method: "POST",
          body: JSON.stringify({
            problem: prob,
            maxParallelWorktrees: parallelLimitForNewRun(),
            ...am.payload,
          }),
        });
    const body = (await r.json()) as { id: string };
    if (!r.ok) {
      setProblemStatus(await readHttpError(r), "error");
      btn?.removeAttribute("disabled");
      return;
    }
    clearPendingPreviewUrls();
    pendingAttachments = [];
    const fileInput = document.getElementById(
      "problemFiles"
    ) as HTMLInputElement | null;
    if (fileInput) fileInput.value = "";
    currentRunId = body.id;
    persistRunId(body.id);
    await connectLogStream(body.id);
    const ps = await api("/pipeline/start", {
      method: "POST",
      body: JSON.stringify({ runId: body.id }),
    });
    if (!ps.ok && ps.status !== 202) {
      setProblemStatus(await readHttpError(ps), "error");
      btn?.removeAttribute("disabled");
      await loadRun();
      return;
    }
    setControlsForPipeline(true);
    startPolling();
    await loadRun();
    setProblemStatus("Pipeline running — watch status and live log.", "ok");
  } catch (e) {
    setProblemStatus(
      e instanceof Error
        ? e.message
        : "Network error — is the server running?",
      "error"
    );
    setControlsForPipeline(false);
    btn?.removeAttribute("disabled");
  }
}

document.getElementById("btnRecoverManual")?.addEventListener("click", () => {
  void recoverUnfinishedForRun();
});

document.getElementById("recoverRunIdInput")?.addEventListener("input", () => {
  syncRecoverPanel();
});

document.getElementById("btnSend")?.addEventListener("click", () => {
  void submitProblem();
});

document.getElementById("btnAttach")?.addEventListener("click", () => {
  document.getElementById("problemFiles")?.click();
});

document.getElementById("problemFiles")?.addEventListener("change", (ev) => {
  const input = ev.target as HTMLInputElement;
  const list = input.files;
  if (!list?.length) return;
  pendingAttachments.push(...Array.from(list));
  input.value = "";
  renderAttachmentStrip();
});

const problemCompose = document.getElementById("problemCompose");
problemCompose?.addEventListener("dragover", (e) => {
  e.preventDefault();
  e.stopPropagation();
  problemCompose.classList.add("problem-compose--drag");
});
problemCompose?.addEventListener("dragleave", (e) => {
  if (e.target === problemCompose) {
    problemCompose.classList.remove("problem-compose--drag");
  }
});
problemCompose?.addEventListener("drop", (e) => {
  e.preventDefault();
  e.stopPropagation();
  problemCompose?.classList.remove("problem-compose--drag");
  const dt = e.dataTransfer?.files;
  if (!dt?.length) return;
  pendingAttachments.push(...Array.from(dt));
  renderAttachmentStrip();
});

problemCompose?.addEventListener("paste", (e) => {
  const pasted = filesFromClipboard((e as ClipboardEvent).clipboardData);
  if (pasted.length === 0) return;
  e.preventDefault();
  pendingAttachments.push(...pasted);
  renderAttachmentStrip();
});

document.getElementById("btnStop")?.addEventListener("click", async () => {
  if (!currentRunId) return;
  const r = await api("/pipeline/stop", {
    method: "POST",
    body: JSON.stringify({ runId: currentRunId }),
  });
  const j = (await r.json()) as { ok?: boolean; message?: string };
  if (j.ok) {
    setProblemStatus("Stop requested — agent subprocess will terminate.", "info");
  } else {
    setProblemStatus(j.message ?? "Nothing to stop.", "info");
  }
  await loadRun();
});

document.getElementById("btnStartOver")?.addEventListener("click", async () => {
  if (currentRunId) {
    await api("/pipeline/stop", {
      method: "POST",
      body: JSON.stringify({ runId: currentRunId }),
    });
  }
  stopPolling();
  currentRunId = null;
  persistRunId(null);
  const runInp = document.getElementById(
    "recoverRunIdInput"
  ) as HTMLInputElement | null;
  if (runInp) runInp.value = "";
  syncRecoverPanel();
  eventSource?.close();
  eventSource = null;
  clearPendingPreviewUrls();
  pendingAttachments = [];
  const fileInput = document.getElementById(
    "problemFiles"
  ) as HTMLInputElement | null;
  if (fileInput) fileInput.value = "";
  renderAttachmentStrip();
  const ta = document.getElementById("problem") as HTMLTextAreaElement;
  if (ta) ta.value = "";
  const rid = document.getElementById("runIdDisplay");
  if (rid) rid.textContent = "";
  const log = document.getElementById("log");
  if (log) log.textContent = "";
  setProblemStatus("Cleared. Enter a new problem and Send.", "info");
  setControlsForPipeline(false);
  const ps = document.getElementById("pipelineState");
  if (ps) ps.textContent = "—";
  const pm = document.getElementById("pipelineStep");
  if (pm) pm.textContent = "—";
  const rc = document.getElementById("runConcurrency");
  if (rc) rc.textContent = "—";
  const ram = document.getElementById("runAgentModel");
  if (ram) ram.textContent = "—";
  for (const id of [
    "agentModelPlannerInput",
    "agentModelExecutionInput",
    "agentModelCommunicationInput",
    "agentModelFallbackInput",
  ]) {
    const el = document.getElementById(id) as HTMLInputElement | null;
    if (el) el.value = "";
  }
  const banner = document.getElementById("pipelineBanner");
  if (banner) {
    banner.textContent = "";
    banner.className = "pipeline-banner";
  }
});

const problemTa = document.getElementById("problem") as HTMLTextAreaElement | null;
problemTa?.addEventListener("keydown", (ev) => {
  if (ev.key !== "Enter" || ev.shiftKey) return;
  ev.preventDefault();
  void submitProblem();
});

document.getElementById("btnModelCopyExecToAll")?.addEventListener(
  "click",
  () => {
    const ex = (
      document.getElementById(
        "agentModelExecutionInput"
      ) as HTMLInputElement | null
    )?.value;
    const v = ex ?? "";
    for (const id of [
      "agentModelPlannerInput",
      "agentModelCommunicationInput",
      "agentModelFallbackInput",
    ]) {
      const el = document.getElementById(id) as HTMLInputElement | null;
      if (el) {
        el.value = v;
        persistModelInput(id, v);
      }
    }
  }
);

void (async () => {
  await refreshConfig();
  syncRecoverPanel();
  const restored = await restoreRunIfAny();
  if (!restored) {
    setProblemStatus(
      "Describe the goal (and optionally attach media), then Send — the full pipeline runs automatically.",
      "info"
    );
    setControlsForPipeline(false);
  }
  syncRecoverPanel();
})();
