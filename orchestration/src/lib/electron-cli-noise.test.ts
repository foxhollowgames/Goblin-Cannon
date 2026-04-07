import { describe, expect, it } from "vitest";
import { stripElectronCliNoise } from "./electron-cli-noise.js";

describe("stripElectronCliNoise", () => {
  it("removes Chromium registration_protocol stderr (VS Code / Electron headless)", () => {
    const msg =
      "[0406/100955.805:ERROR:registration_protocol_win.cc(108)] CreateFile: The system cannot find the file specified. (0x2)\n";
    expect(stripElectronCliNoise(msg)).toBe("");
  });

  it("preserves planner JSON", () => {
    const j = '{"tasks":[{"title":"t","description":"d","acceptance":[]}]}\n';
    expect(stripElectronCliNoise(j)).toBe(j.trim());
  });

  it("keeps stderr that does not match Chromium log lines", () => {
    expect(stripElectronCliNoise("real error: missing API key\n")).toBe("real error: missing API key");
  });

  it("removes Cursor CLI unknown --print forwarded to Electron warning", () => {
    const msg =
      "Warning: 'print' is not in the list of known options, but still passed to Electron/Chromium.\n";
    expect(stripElectronCliNoise(msg)).toBe("");
  });

  it("removes Cursor CLI unknown -p (quoted as 'p') forwarded to Electron warning", () => {
    const msg =
      "Warning: 'p' is not in the list of known options, but still passed to Electron/Chromium.\n";
    expect(stripElectronCliNoise(msg)).toBe("");
  });
});
