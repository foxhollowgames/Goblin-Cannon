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

function persistRunId(id: string | null) {
  try {
    if (id) sessionStorage.setItem(RUN_STORAGE_KEY, id);
    else sessionStorage.removeItem(RUN_STORAGE_KEY);
  } catch {
    /* storage blocked */
  }
}

let currentRunId: string | null = null;
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

  syncRecoverPanel();
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
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
  if (!prob) {
    setProblemStatus("Type a problem or goal before sending.", "error");
    ta?.focus();
    return;
  }
  btn?.setAttribute("disabled", "true");
  setProblemStatus("Starting run and pipeline…", "info");
  stopPolling();
  try {
    const r = await api("/runs", {
      method: "POST",
      body: JSON.stringify({ problem: prob }),
    });
    const body = (await r.json()) as { id: string };
    if (!r.ok) {
      setProblemStatus(await readHttpError(r), "error");
      btn?.removeAttribute("disabled");
      return;
    }
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

void (async () => {
  await refreshConfig();
  syncRecoverPanel();
  const restored = await restoreRunIfAny();
  if (!restored) {
    setProblemStatus(
      "Describe the goal and Send — the full pipeline runs automatically.",
      "info"
    );
    setControlsForPipeline(false);
  }
  syncRecoverPanel();
})();
