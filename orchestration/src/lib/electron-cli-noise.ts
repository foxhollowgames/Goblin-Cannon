/**
 * Chromium/Electron often prints benign stderr when the app runs headless (e.g. Crashpad
 * registration on Windows). That noise is not model output; it blocks JSON parsing and
 * prevents planner fallback (stderr was non-empty but meaningless).
 */

export function isElectronCliNoiseLine(line: string): boolean {
  const t = line.trim();
  if (t.length === 0) {
    return false;
  }
  // Chrome-style log: [0406/100955.805:ERROR:file.cc(108)]
  if (/^\[\d{4}\/\d{6}\.\d+:/.test(t)) {
    return true;
  }
  // Alternate: [12345:0406/100955.805:INFO:...]
  if (/^\[\d+:\d{4}\/\d{6}\.\d+:/.test(t)) {
    return true;
  }
  if (t.includes("registration_protocol_win.cc")) {
    return true;
  }
  // Cursor forwards unknown flags to Electron when the CLI build does not support them.
  // Short `-p` can surface as Warning: 'p' is not in the list... (same as full `--print`).
  if (
    /Warning:\s*'(?:print|p)'\s+is\s+not\s+in\s+the\s+list\s+of\s+known\s+options/i.test(t) &&
    t.includes("Electron")
  ) {
    return true;
  }
  return false;
}

/** Remove known Electron/Chromium CLI noise lines; preserve everything else. */
export function stripElectronCliNoise(text: string): string {
  return text
    .split(/\r?\n/)
    .filter((line) => !isElectronCliNoiseLine(line))
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}
