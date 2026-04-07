import { afterEach, describe, expect, it } from "vitest";
import {
  applyHeadlessAgentFlags,
  ensureStandaloneWorkspaceTrust,
  stripStandaloneAgentSubcommandIfNeeded,
} from "./cursor-agent-args.js";

describe("applyHeadlessAgentFlags", () => {
  it("inserts --print after agent for planner", () => {
    expect(applyHeadlessAgentFlags(["agent", "{{PROMPT}}"], "planner", true)).toEqual([
      "agent",
      "--print",
      "{{PROMPT}}",
    ]);
  });

  it("inserts --print and --force for execution", () => {
    expect(applyHeadlessAgentFlags(["agent", "{{PROMPT}}"], "execution", true)).toEqual([
      "agent",
      "--print",
      "--force",
      "{{PROMPT}}",
    ]);
  });

  it("does not duplicate --print", () => {
    expect(
      applyHeadlessAgentFlags(["agent", "--print", "{{PROMPT}}"], "execution", true)
    ).toEqual(["agent", "--print", "--force", "{{PROMPT}}"]);
  });

  it("no-ops when disabled", () => {
    const a = ["agent", "{{PROMPT}}"];
    expect(applyHeadlessAgentFlags(a, "execution", false)).toEqual(a);
  });

  it("standalone agent: execution still gets --print/--force when headlessAgent config is false", () => {
    expect(
      applyHeadlessAgentFlags(["--trust", "{{PROMPT}}"], "execution", false, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(["--trust", "--print", "--force", "{{PROMPT}}"]);
  });

  it("standalone agent: planner does not force flags when headlessAgent is false", () => {
    const a = ["--trust", "{{PROMPT}}"];
    expect(
      applyHeadlessAgentFlags(a, "planner", false, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(a);
  });

  it("no-ops when agent subcommand missing", () => {
    const a = ["chat", "{{PROMPT}}"];
    expect(applyHeadlessAgentFlags(a, "execution", true)).toEqual(a);
  });

  it("standalone agent exe: prepends --print (and --force on execution) when args have no agent token", () => {
    expect(
      applyHeadlessAgentFlags(["{{PROMPT}}"], "planner", true, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(["--print", "{{PROMPT}}"]);
    expect(
      applyHeadlessAgentFlags(["{{PROMPT}}"], "execution", true, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(["--print", "--force", "{{PROMPT}}"]);
  });

  it("standalone agent: inserts --print after --trust (not before)", () => {
    expect(
      applyHeadlessAgentFlags(["--trust", "{{PROMPT}}"], "planner", true, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(["--trust", "--print", "{{PROMPT}}"]);
    expect(
      applyHeadlessAgentFlags(["--trust", "{{PROMPT}}"], "execution", true, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(["--trust", "--print", "--force", "{{PROMPT}}"]);
  });
});

describe("applyHeadlessAgentFlags ORCH_STANDALONE_NO_FORCE_PRINT", () => {
  const prev = process.env.ORCH_STANDALONE_NO_FORCE_PRINT;

  afterEach(() => {
    if (prev === undefined) {
      delete process.env.ORCH_STANDALONE_NO_FORCE_PRINT;
    } else {
      process.env.ORCH_STANDALONE_NO_FORCE_PRINT = prev;
    }
  });

  it("disables standalone execution force when set to 1", () => {
    process.env.ORCH_STANDALONE_NO_FORCE_PRINT = "1";
    const a = ["--trust", "{{PROMPT}}"];
    expect(
      applyHeadlessAgentFlags(a, "execution", false, {
        standaloneAgentExecutable: true,
      })
    ).toEqual(a);
  });
});

describe("ensureStandaloneWorkspaceTrust", () => {
  const prev = process.env.ORCH_AGENT_SKIP_WORKSPACE_TRUST;

  afterEach(() => {
    if (prev === undefined) {
      delete process.env.ORCH_AGENT_SKIP_WORKSPACE_TRUST;
    } else {
      process.env.ORCH_AGENT_SKIP_WORKSPACE_TRUST = prev;
    }
  });

  it("prepends --trust when missing", () => {
    expect(ensureStandaloneWorkspaceTrust(["{{PROMPT}}"])).toEqual([
      "--trust",
      "{{PROMPT}}",
    ]);
  });

  it("no-ops when --trust, --yolo, or -f present", () => {
    expect(ensureStandaloneWorkspaceTrust(["--trust", "{{PROMPT}}"])).toEqual([
      "--trust",
      "{{PROMPT}}",
    ]);
    expect(ensureStandaloneWorkspaceTrust(["--yolo", "x"])).toEqual(["--yolo", "x"]);
    expect(ensureStandaloneWorkspaceTrust(["-f", "{{PROMPT}}"])).toEqual([
      "-f",
      "{{PROMPT}}",
    ]);
  });

  it("respects ORCH_AGENT_SKIP_WORKSPACE_TRUST=1", () => {
    process.env.ORCH_AGENT_SKIP_WORKSPACE_TRUST = "1";
    expect(ensureStandaloneWorkspaceTrust(["{{PROMPT}}"])).toEqual(["{{PROMPT}}"]);
  });
});

describe("stripStandaloneAgentSubcommandIfNeeded", () => {
  it("drops leading agent only for standalone agent binaries", () => {
    expect(
      stripStandaloneAgentSubcommandIfNeeded("C:/cursor-agent/agent.exe", [
        "agent",
        "{{PROMPT}}",
      ])
    ).toEqual(["{{PROMPT}}"]);
    expect(
      stripStandaloneAgentSubcommandIfNeeded("C:/Programs/cursor/cursor.cmd", [
        "agent",
        "{{PROMPT}}",
      ])
    ).toEqual(["agent", "{{PROMPT}}"]);
  });
});
