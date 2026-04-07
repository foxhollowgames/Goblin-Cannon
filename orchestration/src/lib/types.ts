/** Shared types for orchestration state and API. */

export type Phase =
  | "idle"
  | "planning"
  | "orchestrating"
  | "executing"
  | "testing"
  | "reporting";

export type TaskStatus =
  | "pending"
  | "assigned"
  | "executing"
  | "testing"
  | "done"
  | "blocked"
  | "failed";

export interface Task {
  id: string;
  title: string;
  description: string;
  acceptance: string[];
  filesHint?: string[];
  dependsOn?: string[];
  status: TaskStatus;
  assignedWorktreePath?: string;
  branchName?: string;
  createdAt: string;
  updatedAt: string;
}

export type OutcomeKind =
  | "planner"
  | "orchestrator"
  | "execution"
  | "testing"
  | "communication";

export interface Outcome {
  id: string;
  kind: OutcomeKind;
  taskId?: string;
  at: string;
  exitCode?: number;
  summary: string;
  /** Last ~8k of captured stdout/stderr for debugging */
  logTail?: string;
  metadata?: Record<string, unknown>;
}

export type PipelineStatus =
  | "idle"
  | "running"
  | "stopped"
  | "completed"
  | "failed";

/** Files saved under `orchestration/data/` — referenced by planner / execution / report prompts. */
export interface ProblemAttachment {
  id: string;
  /** Original filename for display */
  name: string;
  mime: string;
  /** Path relative to the orchestration `data/` directory (e.g. `attachments/run_…/…`). */
  relativePath: string;
}

export interface RunState {
  id: string;
  problem: string;
  /**
   * Fallback `--model` when a phase-specific field below is empty (dashboard or API can set any subset).
   */
  agentModel?: string;
  /** Planner step only — use a smaller/faster model for easy problems; leave empty to use `agentModel` or CLI default. */
  agentModelPlanner?: string;
  /** Task execution + fixes — prefer your strongest model for hard / complex work. */
  agentModelExecution?: string;
  /** Final communication / report step. */
  agentModelCommunication?: string;
  /** Optional screenshots, video, PDF, etc. for multimodal context (like Cursor chat attachments). */
  attachments?: ProblemAttachment[];
  phase: Phase;
  /** Automated pipeline (planner → tasks → report) */
  pipelineStatus?: PipelineStatus;
  pipelineMessage?: string;
  backlog: Task[];
  limits: { maxParallelWorktrees: number };
  /** Active worktrees tracked for capacity (paths) */
  activeWorktreePaths: string[];
  /** Optional global run lock (single-flight orchestration) */
  runLock?: { holder: string; since: string };
  outcomes: Outcome[];
  /** Captured from main at plan time for regression hints */
  baselineTestSummary?: string;
  /** Current task id when in executing/testing */
  currentTaskId?: string;
  /** Final user-facing report from communication agent */
  communicationReport?: string;
  createdAt: string;
  updatedAt: string;
}

export interface OrchestrationConfig {
  repoRoot: string;
  worktreeParentDir: string;
  godotPath: string;
  cursorCli: {
    command: string;
    args: string[];
    timeoutMs: number;
    /** Merged into the child process env (e.g. pass secrets only via local config + gitignore). */
    env?: Record<string, string>;
    /**
     * When true, inject `cursor agent --print` (+ `--force` on execution). Default false: many
     * Windows CLI builds do not support `--print` and show "Warning: 'print' is not in the list
     * of known options" (flag is passed to Electron). Enable only if your Cursor version supports it.
     */
    headlessAgent: boolean;
    /**
     * Execution phase only: if output contains a markdown `## Summary` block and then no stdout/stderr
     * for this many ms, send SIGTERM (Windows `agent.cmd` often never exits after printing Summary).
     * Set to 0 to disable. Env: `ORCH_EXIT_AFTER_SUMMARY_IDLE_MS`.
     */
    exitAfterSummaryIdleMs: number;
    /**
     * Execution phase only: SIGTERM if **no** stdout/stderr bytes for this long (catches hangs
     * that never print `## Summary`). 0 disables. Env: `ORCH_EXIT_AFTER_OUTPUT_IDLE_MS`.
     */
    exitAfterOutputIdleMs: number;
    /**
     * Execution phase only: SIGTERM after this wall time since spawn regardless of output
     * (use when the agent streams keepalives forever). 0 disables. Env: `ORCH_MAX_EXECUTION_WALL_MS`.
     */
    maxExecutionWallMs: number;
  };
  limits: { maxParallelWorktrees: number };
  dryRun: boolean;
  /**
   * When the Cursor agent returns no captured output (common with some CLI builds on Windows),
   * create a single backlog task from the problem text so the pipeline can continue.
   */
  plannerFallback: boolean;
  /**
   * After `cursor agent` exits 0, fail the step if the worktree has no new commits and no
   * dirty files (detects silent no-op runs on Windows). Set false for dry runs or debugging.
   */
  requireExecutionGitChanges: boolean;
  /**
   * When true (default), after Godot tests pass, merge the task branch into main/master and remove the worktree.
   * Set false to leave branches for manual merge (worktree slot is still released).
   */
  autoMergeOnPass: boolean;
  /**
   * After a successful local merge into main/master, run `git push <gitRemote> <primary>` so GitHub stays in sync.
   * Requires credentials (credential manager, SSH remote, etc.). Env: `ORCH_PUSH_AFTER_MERGE=0` to disable.
   */
  pushAfterMerge: boolean;
  /** Remote name for push and optional remote agent-branch delete (default `origin`). */
  gitRemote: string;
  /**
   * After merge, attempt `git push <gitRemote> --delete <agent-branch>` if the agent branch was ever pushed.
   * Failures are ignored (branch usually exists only locally).
   */
  deleteRemoteAgentBranch: boolean;
  /**
   * Max wall time for each `godot --headless -s tests/run_tests.gd` (worktree + baseline capture).
   * If exceeded, the child is SIGTERM/SIGKILL'd and tests are treated as failed so the pipeline never
   * blocks forever. 0 disables (not recommended). Env: `ORCH_GODOT_HEADLESS_TIMEOUT_MS`.
   */
  godotHeadlessTimeoutMs: number;
  /**
   * After Godot tests fail, how many **extra** execution+test rounds to run (agent sees failing output and must fix code or tests).
   * Example: **5** ⇒ up to **6** Godot runs total (initial + 5 retries). **0** = one Godot run only (no fix retries).
   * **-1** = retry until tests pass or the run is stopped (timeouts still abort). Env: `ORCH_GODOT_TEST_FIX_RETRIES`.
   */
  godotTestFixRetries: number;
  /**
   * Preset model ids shown in the dashboard selector (Cursor CLI `--model`).
   * Override or extend in `orchestration.config.local.json`.
   */
  agentModelOptions: string[];
}
