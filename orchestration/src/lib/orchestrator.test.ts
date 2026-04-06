import { describe, it, expect } from "vitest";
import { depsSatisfied, nextAssignableTask } from "./orchestrator.js";
import type { RunState, Task } from "./types.js";

function task(
  id: string,
  status: Task["status"],
  deps: string[] = []
): Task {
  const now = new Date().toISOString();
  return {
    id,
    title: id,
    description: "",
    acceptance: [],
    dependsOn: deps,
    status,
    createdAt: now,
    updatedAt: now,
  };
}

describe("orchestrator", () => {
  it("nextAssignableTask respects dependencies", () => {
    const run: RunState = {
      id: "r1",
      problem: "",
      phase: "orchestrating",
      backlog: [
        task("a", "pending", []),
        task("b", "pending", ["a"]),
      ],
      limits: { maxParallelWorktrees: 1 },
      activeWorktreePaths: [],
      outcomes: [],
      createdAt: "",
      updatedAt: "",
    };
    const first = nextAssignableTask(run);
    expect(first?.id).toBe("a");
    run.backlog[0].status = "done";
    const second = nextAssignableTask(run);
    expect(second?.id).toBe("b");
  });

  it("depsSatisfied is false when dependency not done", () => {
    const backlog = [task("a", "pending"), task("b", "pending", ["a"])];
    expect(depsSatisfied(backlog[1], backlog)).toBe(false);
    backlog[0].status = "done";
    expect(depsSatisfied(backlog[1], backlog)).toBe(true);
  });
});
