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
| `limits.maxParallelWorktrees` | Capacity guard (default `1`) |
| `dryRun` | If `true`, prints commands instead of running Cursor/Godot |

Environment overrides: `GOBLIN_CANNON_ROOT`, `ORCH_WORKTREE_PARENT`, `GODOT_PATH`, `CURSOR_CLI`, `CURSOR_AGENT_BIN`, `ORCH_PORT`, `ORCH_HOST`.

### Headless agent (no git changes / empty planner output)

Running **`cursor agent "…"` in an interactive terminal** can open Cursor and show a reply, but the orchestration server **spawns the same CLI as a background child** (no TTY). On Windows that often exits **0** with little or no stdout and **no file edits** unless headless auth is set up.

1. Follow **Cursor’s CLI / headless** documentation (e.g. [CLI overview](https://cursor.com/docs/cli/overview)) and set **`CURSOR_API_KEY`** for the process that runs `npm start` (or add it under **`cursorCli.env`** in `orchestration.config.local.json` — that file is gitignored).
2. **Upgrade Cursor** if stderr shows unknown flags (e.g. `--print`) passed through to Electron — newer builds may support documented headless flags.
3. Keep **`CURSOR_CLI`** pointing at **`cursor.cmd`** on Windows.

## Safety

The Cursor CLI can edit files in the repo or worktree. Use only on trusted clones. Prefer `dryRun: true` to verify commands first.

## Tests (orchestration logic)

```powershell
npm test
```

Godot gameplay tests run inside the **automated pipeline** when a task reaches the testing phase, not from `npm test`.
