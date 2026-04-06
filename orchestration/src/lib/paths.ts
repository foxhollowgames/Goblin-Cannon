import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/** `orchestration/` package root */
export function packageRoot(): string {
  return join(__dirname, "../..");
}

export function promptPath(name: string): string {
  return join(packageRoot(), "prompts", name);
}
