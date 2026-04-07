import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { extname, join, resolve } from "node:path";
import type { ProblemAttachment, RunState } from "./types.js";
import { dataDir, newId } from "./store.js";

const MAX_EMBED_PER_FILE_BYTES = 900_000;
const MAX_EMBEDDED_IMAGES = 6;
const MAX_TOTAL_EMBED_RAW_BYTES = 2_500_000;

/** Safe filename segment for disk (no path separators). */
export function sanitizeAttachmentFilename(name: string): string {
  const base = name
    .replace(/[/\\?*:|"<>]/g, "_")
    .replace(/^\.+/, "")
    .trim();
  const cut = base.slice(-120);
  return cut.length > 0 ? cut : "file";
}

const ALLOW_EXT = new Set([
  ".png",
  ".jpg",
  ".jpeg",
  ".webp",
  ".gif",
  ".bmp",
  ".mp4",
  ".webm",
  ".mov",
  ".mkv",
  ".mp3",
  ".wav",
  ".ogg",
  ".flac",
  ".m4a",
  ".pdf",
]);

export function isAllowedAttachmentMime(mime: string): boolean {
  const m = mime.toLowerCase().trim();
  return (
    m.startsWith("image/") ||
    m.startsWith("video/") ||
    m.startsWith("audio/") ||
    m === "application/pdf"
  );
}

/** Some browsers send `application/octet-stream`; allow known media extensions. */
export function isAllowedAttachmentFile(filename: string, mime: string): boolean {
  if (isAllowedAttachmentMime(mime)) return true;
  const m = mime.toLowerCase().trim();
  if (m === "application/octet-stream" || !m) {
    return ALLOW_EXT.has(extname(filename).toLowerCase());
  }
  return false;
}

export function saveProblemAttachment(
  runId: string,
  originalName: string,
  buffer: Buffer,
  mime: string
): ProblemAttachment {
  const id = newId("att");
  const safe = sanitizeAttachmentFilename(originalName);
  const dir = join(dataDir(), "attachments", runId);
  mkdirSync(dir, { recursive: true });
  const fname = `${id}_${safe}`;
  const abs = join(dir, fname);
  writeFileSync(abs, buffer);
  const relativePath = join("attachments", runId, fname).replace(/\\/g, "/");
  return {
    id,
    name: originalName || safe,
    mime: mime || "application/octet-stream",
    relativePath,
  };
}

/**
 * Appends multimodal context: small images as markdown data-URLs; larger or non-images as absolute paths.
 */
export function formatAttachmentContextForPrompt(run: RunState): string {
  const list = run.attachments;
  if (!list?.length) return "";

  const blocks: string[] = [];
  let embeddedCount = 0;
  let totalRaw = 0;

  for (const a of list) {
    const pathToRead = resolve(dataDir(), a.relativePath);

    if (!existsSync(pathToRead)) {
      blocks.push(`- **${a.name}** — (file missing on disk)`);
      continue;
    }

    let buf: Buffer;
    try {
      buf = readFileSync(pathToRead);
    } catch {
      blocks.push(`- **${a.name}** — (could not read file)`);
      continue;
    }

    const isRasterImage =
      a.mime.startsWith("image/") &&
      !a.mime.includes("svg") &&
      a.mime !== "image/svg+xml";

    if (
      isRasterImage &&
      embeddedCount < MAX_EMBEDDED_IMAGES &&
      buf.length <= MAX_EMBED_PER_FILE_BYTES &&
      totalRaw + buf.length <= MAX_TOTAL_EMBED_RAW_BYTES
    ) {
      const b64 = buf.toString("base64");
      const mime = a.mime || "image/png";
      blocks.push(`\n![${a.name}](data:${mime};base64,${b64})\n`);
      embeddedCount += 1;
      totalRaw += buf.length;
    } else {
      blocks.push(
        `- **${a.name}** (${a.mime}) — use as context; absolute path: \`${pathToRead}\``
      );
    }
  }

  if (blocks.length === 0) return "";

  return [
    "",
    "---",
    "### Attached media (user-provided context, like Cursor chat attachments)",
    "Use visuals and file paths below when planning, implementing, or summarizing.",
    "",
    ...blocks,
  ].join("\n");
}
