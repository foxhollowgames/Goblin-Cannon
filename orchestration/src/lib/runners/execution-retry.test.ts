import { describe, expect, it } from "vitest";
import {
  formatTestFailureRetryBlock,
  type TestFailureRetryContext,
} from "./execution.js";

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
