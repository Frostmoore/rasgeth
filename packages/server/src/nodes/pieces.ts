// Files that cross between machines in pieces (G39.4 storage, G41.7 media): 4 MB at a time in
// base64, in order, the whole file appearing only once complete (`<file>.part` renamed). A piece
// asked again after a reconnect is not written twice; one out of order is refused. With an
// expected SHA-256 the finished file is checked before it appears: a wrong one is thrown away.
import { createHash } from "node:crypto";
import { createReadStream } from "node:fs";
import { mkdir, open, rename, rm, stat } from "node:fs/promises";
import { dirname } from "node:path";
import { pipeline } from "node:stream/promises";
import { NodeError } from "./service.js";

export const PIECE = 4 * 1024 * 1024;

/** A file's SHA-256 and size. */
export async function fileHash(file: string): Promise<{ sha256: string; size: number }> {
  const h = createHash("sha256");
  await pipeline(createReadStream(file), h);
  return { sha256: h.digest("hex"), size: (await stat(file)).size };
}

/** What is already there of a file: whole (with its hash) or a part to resume from. */
export async function pieceState(
  file: string,
): Promise<{ sha256?: string; size: number; partial: number }> {
  const whole = await stat(file).catch(() => undefined);
  const part = await stat(`${file}.part`).catch(() => undefined);
  if (whole?.isFile()) return { ...(await fileHash(file)), partial: 0 };
  return { size: 0, partial: part?.size ?? 0 };
}

/**
 * Writes one piece at `offset`. Returns the bytes the part has now. `last` renames it into place,
 * after checking `sha256` when given (a mismatch removes it and throws `invalid`).
 */
export async function putPiece(
  file: string,
  b: { offset?: unknown; data?: unknown; last?: unknown; sha256?: unknown },
): Promise<{ size: number }> {
  const part = `${file}.part`;
  await mkdir(dirname(file), { recursive: true });
  const data = Buffer.from(String(b.data ?? ""), "base64");
  const offset = Number(b.offset) || 0;
  if (offset === 0) await rm(part, { force: true });
  const size = await stat(part).then(
    (s) => s.size,
    () => 0,
  );
  // Pieces in order: one asked again after a reconnect is not written twice.
  if (offset < size) {
    if (b.last && offset + data.length === size) return finish(file, part, size, b.sha256);
    return { size };
  }
  if (offset > size)
    throw new NodeError("invalid", `Piece out of order (at ${offset}, have ${size})`);
  const h = await open(part, "a");
  try {
    await h.write(data);
  } finally {
    await h.close();
  }
  const now = size + data.length;
  if (b.last) return finish(file, part, now, b.sha256);
  return { size: now };
}

async function finish(
  file: string,
  part: string,
  size: number,
  sha256: unknown,
): Promise<{ size: number }> {
  if (typeof sha256 === "string") {
    const got = await fileHash(part);
    if (got.sha256 !== sha256.toLowerCase()) {
      await rm(part, { force: true });
      throw new NodeError(
        "invalid",
        `The copy did not match its SHA-256 (expected ${sha256}, got ${got.sha256}): it was thrown away`,
      );
    }
  }
  // The whole file appears only once complete: never a half-written copy.
  await rename(part, file);
  return { size };
}

/** One piece of a file from `offset`: base64, its total size, and whether it was the last. */
export async function readPiece(
  file: string,
  offset: number,
): Promise<{ data: string; size: number; done: boolean }> {
  const total = (await stat(file)).size;
  const end = Math.min(total, offset + PIECE) - 1;
  const buf =
    end < offset
      ? Buffer.alloc(0)
      : await new Promise<Buffer>((ok, no) => {
          const parts: Buffer[] = [];
          createReadStream(file, { start: offset, end })
            .on("data", (d) => parts.push(d as Buffer))
            .on("end", () => ok(Buffer.concat(parts)))
            .on("error", no);
        });
  return { data: buf.toString("base64"), size: total, done: offset + buf.length >= total };
}
