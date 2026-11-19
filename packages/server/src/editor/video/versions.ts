// Named versions of a timeline (G41.5d, A5): a copy of the `.rgvideo` kept beside it, in
// `<name>.versions/<stamp> <name>.rgvideo`, with `version` saying what it is a version of, when and
// why. The person saves one with a name (the editor's «Versioni»); one is saved on its own before
// every automatic re-assembly (`reason: "before_assemble"`: G41.6's `assemble` calls
// `saveVideoVersion` before replacing a timeline already made) and before a version is brought
// back. Versions are files of the project: they are backed up, opened and deleted like the others.
export type { VideoVersionEntry } from "@redgiant/protocol";

import { mkdir, readdir, readFile, stat, writeFile } from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import {
  type RgVideo,
  readRgVideo,
  rgvideoVersionPath,
  rgvideoVersionsDir,
  type VideoVersionEntry,
  type VideoVersionInfo,
  versionFileOf,
  versionStamp,
  videoVersionOf,
  writeRgVideo,
} from "@redgiant/protocol";

const exists = (p: string) =>
  stat(p).then(
    () => true,
    () => false,
  );

/**
 * Writes a version of `doc` beside the timeline at `abs` (its path in the project is `path`) and
 * gives its path in the project. A name already used in the same minute gets " (2)", " (3)"…
 */
export async function saveVideoVersion(o: {
  abs: string;
  path: string;
  doc: RgVideo;
  name: string;
  reason: VideoVersionInfo["reason"];
  now?: Date;
}): Promise<VideoVersionEntry> {
  const now = o.now ?? new Date();
  const stamp = versionStamp(now);
  const name = o.name.replace(/\s+/g, " ").trim().slice(0, 120) || "version";
  const copy = videoVersionOf(o.doc, { name, at: now.toISOString(), of: o.path, reason: o.reason });
  const dirAbs = join(dirname(o.abs), rgvideoVersionsDir(basename(o.abs)));
  await mkdir(dirAbs, { recursive: true });
  for (let n = 1; n < 100; n++) {
    const label = n === 1 ? name : `${name} (${n})`;
    const rel = rgvideoVersionPath(o.path, label, stamp);
    const abs = join(dirAbs, basename(rel));
    if (await exists(abs)) continue;
    await writeFile(abs, writeRgVideo(copy), { flag: "wx" });
    return {
      path: rel,
      name,
      at: copy.version?.at ?? "",
      reason: o.reason,
      clips: o.doc.clips.length,
    };
  }
  throw new Error("Too many versions with that name in the same minute");
}

/** The versions of the timeline at `abs` (path in the project `path`), the newest first. */
export async function listVideoVersions(abs: string, path: string): Promise<VideoVersionEntry[]> {
  const dirAbs = join(dirname(abs), rgvideoVersionsDir(basename(abs)));
  const dirRel = rgvideoVersionsDir(path);
  const names = await readdir(dirAbs).catch(() => [] as string[]);
  const out: VideoVersionEntry[] = [];
  for (const f of names) {
    const meta = versionFileOf(f);
    if (!meta) continue;
    try {
      const doc = readRgVideo(await readFile(join(dirAbs, f), "utf8"));
      out.push({
        path: `${dirRel}/${f}`,
        name: doc.version?.name ?? meta.name,
        at: doc.version?.at ?? meta.stamp,
        reason: doc.version?.reason ?? "manual",
        clips: doc.clips.length,
      });
    } catch {
      // not a timeline (or a newer one): left out of the list, never touched
    }
  }
  return out.sort((a, b) => (a.at < b.at ? 1 : a.at > b.at ? -1 : a.path < b.path ? 1 : -1));
}
