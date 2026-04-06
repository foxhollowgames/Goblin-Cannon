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

export interface RunState {
  id: string;
  problem: string;
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
}
