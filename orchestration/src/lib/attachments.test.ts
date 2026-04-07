import { describe, expect, it } from "vitest";
import { sanitizeAttachmentFilename } from "./attachments.js";

describe("sanitizeAttachmentFilename", () => {
  it("strips path separators and limits length", () => {
    expect(sanitizeAttachmentFilename("..\\evil\\x.png")).toBe("_evil_x.png");
    expect(sanitizeAttachmentFilename("a".repeat(200)).length).toBe(120);
  });
});
