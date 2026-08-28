import { describe, expect, it } from "vitest";
import {
  formatExecutionRecoveryBlock,
  formatTestFailureRetryBlock,
  type TestFailureRetryContext,
} from "./execution.js";

describe("formatExecutionRecoveryBlock", () => {
  it("includes attempt numbers and log excerpt", () => {
    const s = formatExecutionRecoveryBlock({
      attempt: 2,
      maxAttempts: 3,
      reason: "nonzero_exit",
      exitCode: 1,
      logExcerpt: "ERR: broken",
    });
    expect(s).toContain("attempt **2**");
    expect(s).toContain("**3**");
    expect(s).toContain("ERR: broken");
    expect(s).toContain("exited **1**");
  });

  it("uses no-git wording when reason is no_git_changes", () => {
    const s = formatExecutionRecoveryBlock({
      attempt: 2,
      maxAttempts: 3,
      reason: "no_git_changes",
      exitCode: 0,
      logExcerpt: "",
    });
    expect(s).toContain("no tracked file changes");
  });
});

describe("formatTestFailureRetryBlock", () => {
  it("includes round numbers and log excerpt", () => {
    const ctx: TestFailureRetryContext = {
      executionRound: 2,
      maxRounds: 3,
      outcomeSummary: "Tests failed (Total: 1 failed)",
      logExcerpt: "SCRIPT ERROR: foo",
      killedByTimeout: false,
    };
    const s = formatTestFailureRetryBlock(ctx);
    expect(s).toContain("execution round **2**");
    expect(s).toContain("**3**");
    expect(s).toContain("SCRIPT ERROR: foo");
  });

  it("uses timeout wording when killedByTimeout", () => {
    const ctx: TestFailureRetryContext = {
      executionRound: 2,
      maxRounds: 3,
      outcomeSummary: "",
      logExcerpt: "",
      killedByTimeout: true,
    };
    expect(formatTestFailureRetryBlock(ctx)).toContain("TIMEOUT");
  });

  it("shows unlimited when maxRounds is Infinity", () => {
    const ctx: TestFailureRetryContext = {
      executionRound: 4,
      maxRounds: Number.POSITIVE_INFINITY,
      outcomeSummary: "fail",
      logExcerpt: "",
      killedByTimeout: false,
    };
    const s = formatTestFailureRetryBlock(ctx);
    expect(s).toContain("execution round **4**");
    expect(s).toContain("**unlimited**");
  });
});
