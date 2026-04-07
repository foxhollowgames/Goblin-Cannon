# Goblin Cannon — Agent Orchestration (local web UI)

Local pipeline for **Planner → Orchestrator → Execution (git worktree + Cursor Agent CLI) → Godot tests → Communication** with persisted JSON state under `data/`.

The web UI is a **single dashboard**: after you **Send** a problem, the **full pipeline runs automatically** (baseline capture if Godot is configured, planner, then each task: assign worktree → execute → test, then the communication report). Use **Stop** to kill the current subprocess (Cursor or Godot).

## Requirements

- **Node.js 20+**
- **Git** on `PATH`
- **Godot** executable path (for testing) — copy `orchestration.config.example.json` to `orchestration.config.local.json` and set `godotPath`, or set `GODOT_PATH`
- **Cursor Agent CLI** — On Windows, `spawn("cursor")` often fails with **ENOENT** unless the CLI is on `PATH`. The server resolves `cursor` via `where`, common install paths, or you can set **`CURSOR_CLI`** (or **`CURSOR_AGENT_BIN`**) to the **full path** to `cursor.cmd` (for example under `%LOCALAPPDATA%\Programs\cursor\resources\app\bin\cursor.cmd`). Arguments stay in `cursorCli.args` (default uses `{{PROMPT}}` substitution).

## Setup

```powershell
cd orchestration
npm install
copy orchestration.config.example.json orchestration.config.local.json
# Edit orchestration.config.local.json — set repoRoot, worktreeParentDir, godotPath, cursorCli if needed
```

## Development (Vite + API)

Runs the UI on port **5173** with `/api` proxied to **8787**.

```powershell
npm run dev
```

Open http://127.0.0.1:5173

## Production-style (single port)

```powershell
npm run build
npm start
```

Open http://127.0.0.1:8787 (or set `ORCH_PORT`).

## Configuration

| Key | Meaning |
|-----|---------|
| `repoRoot` | Absolute or relative path to Goblin Cannon repo (default `..` from this package) |
| `worktreeParentDir` | Directory where `goblin-cannon-agent-*` worktrees are created (often same as parent of repo) |
| `godotPath` | Full path to `Godot_*.exe` |
| `cursorCli.command` | CLI binary (e.g. `cursor`) |
| `cursorCli.args` | Argument list; include `{{PROMPT}}` where the composed prompt is injected |
| `cursorCli.env` | Optional extra env vars for the Cursor child (e.g. `CURSOR_API_KEY`) |
| `cursorCli.headlessAgent` | If `true`, injects `--print` and (on execution) `--force` / `--yolo` so the agent **applies** edits. **Required** for meaningful execution with standalone **`agent.cmd`** — if `false`, the agent may reply without touching files. |
| `limits.maxParallelWorktrees` | Default cap on **concurrent** task worktrees (typical **`4`** in `orchestration.config.example.json`). Each **run** can override via `POST /api/runs` body `maxParallelWorktrees` or the dashboard number field. Tasks still run **one after another** if the planner links them with **`dependsOn`**, or if this value is **`1`**. |
| `plannerFallback` | If `true` (default), create a single task from the problem when planner output is **empty** or **not parseable JSON** (prose instead of `tasks[]`). Set `false` to fail the run when JSON is missing. |
| `dryRun` | If `true`, prints commands instead of running Cursor/Godot |
| `godotHeadlessTimeoutMs` | Max time (ms) for each Godot headless run (baseline + worktree tests); kills the process if exceeded so the pipeline never hangs. Default **600000** (10 min). Env: **`ORCH_GODOT_HEADLESS_TIMEOUT_MS`**. **`0`** disables the limit (not recommended). |
| `godotTestFixRetries` | After a **failed** Godot test run (non-zero exit, not timeout), how many **extra** execution+test rounds to run. The next execution prompt includes the failing log tail so the agent can fix code or tests. Default **2** (up to **3** Godot runs per task). **`0`** = one shot (legacy behavior). Env: **`ORCH_GODOT_TEST_FIX_RETRIES`**. **Timeouts** do not trigger retries (fix hangs or raise `godotHeadlessTimeoutMs`). |

Environment overrides: `GOBLIN_CANNON_ROOT`, `ORCH_WORKTREE_PARENT`, `GODOT_PATH`, **`ORCH_GODOT_HEADLESS_TIMEOUT_MS`**, **`ORCH_GODOT_TEST_FIX_RETRIES`**, **`CURSOR_AGENT_BIN`** (preferred) or **`CURSOR_CLI`**, `ORCH_PORT`, `ORCH_HOST`. **`CURSOR_AGENT_BIN`** is checked **first**: use it for the standalone **`agent.cmd`** path so a user-level **`CURSOR_CLI`** pointing at **`cursor.cmd`** does not override your config.

### Parallel task execution

The pipeline **already** runs up to **`limits.maxParallelWorktrees`** tasks **concurrently** when the backlog has **multiple `pending` tasks** whose **`dependsOn`** prerequisites are satisfied. If everything looks serial:

1. **`limits.maxParallelWorktrees` is `1`** in `orchestration.config.local.json` — raise it (or set **Concurrent agent tasks** on the dashboard when starting a run).
2. The **planner JSON** chained tasks with **`dependsOn`** (e.g. task 2 waits for task 1) — only independent tasks can overlap; adjust the plan or the prompt so unrelated work uses **`dependsOn: []`**.

### Headless agent (no git changes / empty planner output / empty window)

Running **`cursor agent "…"`** from Node (no TTY) often returns little or no stdout unless **`CURSOR_API_KEY`** is set (see below). **`cursorCli.headlessAgent`** defaults to **`false`**: on many Windows installs, **`cursor agent --print`** is **not** supported and you get `Warning: 'print' is not in the list of known options` (the flag is passed to Electron), which breaks planner JSON parsing. Set **`headlessAgent: true`** only after you confirm your Cursor build supports **`cursor agent --print`** per [Using Headless CLI](https://cursor.com/docs/cli/headless) (then execution gets **`--print --force`** automatically).

1. Set **`CURSOR_API_KEY`** for the process that runs `npm start` (or under **`cursorCli.env`** in `orchestration.config.local.json` — that file is gitignored).
2. Keep **`headlessAgent: false`** if you see the **`print` / Electron** warning above.
3. Keep **`CURSOR_CLI`** pointing at **`cursor.cmd`** on Windows — unless you use the standalone binary below.

**Standalone `agent` vs `cursor agent`:** The **`agent`** executable (e.g. `%LOCALAPPDATA%\cursor-agent\agent.cmd` when on `PATH`) runs the Cursor Agent CLI **directly**, so flags like **`--print`** are not forwarded through Electron the way **`cursor agent …`** sometimes is on Windows. In **`orchestration.config.local.json`**, set **`cursorCli.command`** to **`agent`** or the full path to **`agent.cmd`**, **`cursorCli.args`** to **`["{{PROMPT}}"]`** (do **not** include a literal **`agent`** token in `args` — the binary already is `agent`). Prefer **`headlessAgent: true`** so the server injects **`--print`** (and **`--force`** on execution) for **all** phases. **Important:** Even if **`headlessAgent`** is **`false`**, when the resolved executable is the **standalone `agent`**, the server **still injects `--print` and `--force` for the execution phase only** so the agent **applies file edits** instead of answering in prose only (which would pass **`exit 0`** but fail Godot tests). Opt out of that behavior: **`ORCH_STANDALONE_NO_FORCE_PRINT=1`**. For unattended runs, add workspace trust flags your CLI printed (e.g. **`--trust`**, **`-f`**, or **`--yolo`**) to **`args`** before **`{{PROMPT}}`**. If PowerShell blocks **`agent.ps1`**, call **`agent.cmd`** with a full path or run the server via **`cmd /c`**.

If the dashboard still shows **`Cursor CLI: …\cursor.cmd`** (under **`Programs\cursor\...`**), the server is **not** using standalone `agent` — you get GUI “agent” tabs and flaky I/O. Resolution order: **`CURSOR_AGENT_BIN`** → a **config file path** to **`agent.cmd` / `agent.exe`** (wins over **`CURSOR_CLI`**) → **`CURSOR_CLI`** → **`%LOCALAPPDATA%\cursor-agent\agent.cmd`** if installed → `where cursor`. Set **`CURSOR_AGENT_BIN`** to the standalone agent, or remove a user-level **`CURSOR_CLI`** that points at the IDE, or put the full agent path in **`cursorCli.command`**. Restart **`npm start`** after config edits.

**`cursor-agent.ps1` / “name argument is not valid”** when using stdin: **`agent.cmd`** cannot use a lone `-` in argv; the server omits that token and sends the prompt on stdin only. **`agent.exe`** uses the normal **`-` + stdin** contract. Prefer **`agent.exe`** when possible — with **`.cmd` only**, long execution with no progress may mean the agent never got a proper stdin handshake; install/update Cursor Agent so **`agent.exe`** exists next to **`agent.cmd`**, or set **`CURSOR_AGENT_BIN`** to that **`.exe`**.

**Execution seems stuck (many minutes):** Large tasks can run a long time. The live log emits a **“still running”** line every **2 minutes** with the agent **`cwd`** (the task worktree) and a **`git status --short`** command you can paste in a terminal to confirm real file changes.

### How to validate execution is doing real work

1. **Use the heartbeat line** — It includes **`cwd:`** pointing at `...\goblin-cannon-agent-task_...`. That is where the agent should edit files (not your main repo folder unless you merged).
2. **Check git in the worktree** (PowerShell or cmd):
   ```powershell
   git -C "c:\path\to\goblin-cannon-agent-task_..." status --short
   ```
   You should see modified/new files while the agent is working (or after it finishes).
3. **If the log already shows a complete “Summary” / test results but “still running” never stops** — The CLI child often **did not exit** (typical with **`agent.cmd`** without a clean stdin handshake). Click **Stop**, set **`CURSOR_AGENT_BIN`** to **`%LOCALAPPDATA%\cursor-agent\agent.exe`** if that file exists, restart **`npm start`**, and run again.
4. **Task Manager** — While a run is active, you may see **Cursor / agent** processes using CPU occasionally; flat idle CPU with endless heartbeats usually means a hung child (same fix as step 3).

Edits land in the **task worktree** (`goblin-cannon-agent-*`), not your main checkout, until you merge. Use **Stop** to kill the subprocess.

**“No git changes” but you see edits in the main repo:** The pipeline only checks the **task worktree** (`goblin-cannon-agent-*`). Execution’s agent must change files **under that worktree path** (relative paths from `cwd`). Edits applied via absolute paths to the parent checkout do **not** count. On Windows, the full prompt is always sent via **stdin** so the agent receives the task body (not just the first line). The planner runs with **`cwd`** = **`orchestration/`** so accidental writes from planning stay out of `scenes/`.

**If `cursor agent "…"` opens empty editor tabs** named `agent`, `say hi`, etc., the CLI is treating those tokens as **file paths** (same as `cursor <path> <path>`), not as the agent subcommand. That usually means the **`agent` subcommand is not active** in that Cursor build (despite appearing in `--help`) — update Cursor from [cursor.com](https://cursor.com) or ask [Cursor support](https://forum.cursor.com); the Goblin Cannon pipeline cannot automate the agent until **`cursor agent`** actually runs the agent instead of opening buffers.

## Safety

The Cursor CLI can edit files in the repo or worktree. Use only on trusted clones. Prefer `dryRun: true` to verify commands first.

## Godot tests, auto-merge, and headless quirks

**End-to-end flow:** baseline tests on **main checkout** (optional log) → planner → execution in **git worktree** → **Godot headless tests in that worktree** → if tests fail (and retries remain), **another execution** with the failing log in the prompt, then **re-test** → on **exit 0**, **`autoMergeOnPass`** (default **true**) merges the task branch into **`main`/`master`**, removes the worktree, optionally **`pushAfterMerge`**. You do **not** need to merge by hand for normal passes.

**When a task fails** with *“Task failed (Godot tests or auto-merge after tests)”*, open the **task outcome** in the dashboard log: **`testing`** outcomes show the suite summary; **`orchestrator`** outcomes show merge/snapshot/push errors (e.g. conflict, no commits ahead of main).

**Keeping main green:** Planner (`orchestration/prompts/planner.md`) and execution (`orchestration/prompts/execution.md`) instruct the agents to **update/add headless tests** and align assertions with shared constants. That avoids the common failure mode: gameplay constants change but **`tests/`** still expect old values.

**Fresh worktrees:** The server seeds a minimal **`.godot`** cache from the main repo so `class_name` and globals resolve. If you see missing-type errors only in worktrees, run tests once in the **main** project in the editor or headless so caches exist, then re-run the pipeline.

**SVG / textures in headless:** Godot may print import or loader warnings for **`.svg`** or other resources during headless runs; the **authoritative** pass signal is **`tests/run_tests.gd` exit code 0** and the **`Total: … passed, … failed`** line. In-editor rendering can still be fine when CI shows warnings.

**Hangs and forward progress (nothing blocks forever):**

| Stage | Guard | What happens |
|--------|--------|----------------|
| **Cursor agent** (planner / execution / report) | `cursorCli.timeoutMs`, `exitAfterOutputIdleMs`, `exitAfterSummaryIdleMs`, `maxExecutionWallMs` | Idle or runaway CLI is terminated; execution may still **continue to tests** if the worktree has file changes (see server log). |
| **Godot headless** (baseline + worktree tests) | **`godotHeadlessTimeoutMs`** (default **600000** = 10 min; **`ORCH_GODOT_HEADLESS_TIMEOUT_MS`** env; **`0`** = no limit, not recommended) | Process is killed; **worktree tests** count as **failed** (task won’t auto-merge); **baseline** gets a timeout note instead of hanging the run. |

After a failure, the pipeline still **finishes the run** (report phase when applicable), **releases the worktree slot**, and you can fix **`main`**, **delete the bad worktree**, or use **Rerun unfinished → tests**. The dashboard should never sit in **testing** forever.

## Tests (orchestration logic)

```powershell
npm test
```

Godot gameplay tests run inside the **automated pipeline** when a task reaches the testing phase, not from `npm test`.
