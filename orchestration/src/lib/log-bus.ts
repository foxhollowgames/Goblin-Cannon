/** In-memory pub/sub for live CLI logs (SSE) + ring buffer so logs aren't lost before SSE connects. */

type Listener = (line: string) => void;

const byRun = new Map<string, Set<Listener>>();
const buffers = new Map<string, string>();
const MAX_BUFFER = 512_000;

export function getLogBuffer(runId: string): string {
  return buffers.get(runId) ?? "";
}

export function clearLogBuffer(runId: string): void {
  buffers.delete(runId);
}

export function subscribe(runId: string, fn: Listener): () => void {
  let set = byRun.get(runId);
  if (!set) {
    set = new Set();
    byRun.set(runId, set);
  }
  set.add(fn);
  return () => {
    set!.delete(fn);
    if (set!.size === 0) byRun.delete(runId);
  };
}

export function publish(runId: string, line: string): void {
  let buf = buffers.get(runId) ?? "";
  buf += line;
  if (buf.length > MAX_BUFFER) {
    buf = buf.slice(-MAX_BUFFER);
  }
  buffers.set(runId, buf);

  const set = byRun.get(runId);
  if (!set || set.size === 0) return;
  for (const fn of set) {
    try {
      fn(line);
    } catch {
      /* ignore */
    }
  }
}
