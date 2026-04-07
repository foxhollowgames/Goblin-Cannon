import type { ChildProcess } from "node:child_process";
import { killChildProcessGracefully } from "./kill-child-process.js";

interface Slot {
  cancelled: boolean;
  child: ChildProcess | null;
  running: boolean;
}

const slots = new Map<string, Slot>();

function getSlot(runId: string): Slot {
  let s = slots.get(runId);
  if (!s) {
    s = { cancelled: false, child: null, running: false };
    slots.set(runId, s);
  }
  return s;
}

export function registerPipelineChild(runId: string, child: ChildProcess | null): void {
  const s = getSlot(runId);
  s.child = child;
}

export function clearPipelineChild(runId: string): void {
  const s = slots.get(runId);
  if (s) s.child = null;
}

export function isPipelineCancelled(runId: string): boolean {
  return slots.get(runId)?.cancelled ?? false;
}

export function isPipelineRunning(runId: string): boolean {
  return slots.get(runId)?.running ?? false;
}

export function beginPipelineRun(runId: string): void {
  const s = getSlot(runId);
  s.cancelled = false;
  s.child = null;
  s.running = true;
}

export function endPipelineRun(runId: string): void {
  const s = slots.get(runId);
  if (s) {
    s.running = false;
    s.child = null;
  }
}

export function stopPipelineRun(runId: string): boolean {
  const s = slots.get(runId);
  if (!s?.running) return false;
  s.cancelled = true;
  if (s.child) {
    killChildProcessGracefully(s.child);
  }
  return true;
}
