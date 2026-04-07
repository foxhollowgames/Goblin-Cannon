/**
 * Serialize async work per key (e.g. one assign-at-a-time per run, one merge-at-a-time per repo).
 */
const tails = new Map<string, Promise<unknown>>();

export async function enqueueExclusive<T>(
  key: string,
  fn: () => Promise<T>
): Promise<T> {
  const prev = tails.get(key) ?? Promise.resolve();
  const next = prev.then(() => fn());
  tails.set(
    key,
    next.then(
      () => {},
      () => {}
    )
  );
  return next;
}
