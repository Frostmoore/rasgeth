// A timeline exported for another editor (G41.6b): the XML for DaVinci Resolve (FCP7, as
// montatore writes it: `fcp7Xml`) or OpenTimelineIO (`toOtio`), saved beside the timeline as
// `<name>.xml` / `<name>.otio`. The files point where Resolve will find them: in the folder the
// person names (where the originals are on the computer that runs Resolve, montatore's D21), else
// where they are on this machine. Both the page's route and the agents' `video` tool use it.
// Also `.otio` in: a timeline read from one (`fromOtio`), written as a new `.rgvideo`.

import { randomUUID } from "node:crypto";
import { readFile, rename, rm, writeFile } from "node:fs/promises";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import {
  fcp7Xml,
  fromFcp7Xml,
  fromOtio,
  isMediaRef,
  type MediaProbe,
  otioText,
  type ResolveLeftOut,
  ResolveRateError,
  type RgVideo,
  resolveJob,
  resolveMediaPaths,
  toOtio,
  type VideoExportFormat,
  type VideoExportResult,
} from "@redgiant/protocol";

export interface VideoExportRequest {
  doc: RgVideo;
  /** The timeline's file on this machine (the export goes beside it). */
  abs: string;
  /** Its path in the project (for the answer). */
  path: string;
  /** The project's folder: the timeline's files are relative to it. */
  root: string;
  format: VideoExportFormat;
  /** Where the originals are on the computer that runs Resolve (D21); empty: here. */
  mediaRoot?: string;
  /** A file of the timeline on this machine (undefined: not found). */
  mediaAbs(media: string): Promise<string | undefined>;
  /** ffprobe's facts of a file (cached; undefined when it cannot be read). */
  probe(abs: string): Promise<MediaProbe | undefined>;
}

/** The timeline's rate has no SMPTE timecode: no XML for Resolve (montatore fails there too). */
export class VideoExportRateError extends Error {
  readonly code = "video_export_rate";
}

const stem = (p: string) => basename(p).replace(/\.rgvideo$/i, "");

/** Writes a file whole or not at all. */
async function writeWhole(abs: string, text: string): Promise<void> {
  const tmp = join(dirname(abs), `.${basename(abs)}.${randomUUID().slice(0, 8)}.part`);
  try {
    await writeFile(tmp, text, "utf8");
    await rename(tmp, abs);
  } catch (e) {
    await rm(tmp, { force: true });
    throw e;
  }
}

/** The timeline exported beside itself; what it could not carry is in `leftOut`. */
export async function exportTimeline(r: VideoExportRequest): Promise<VideoExportResult> {
  const files = [...new Set(r.doc.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : [])))];
  const facts: Record<string, MediaProbe | undefined> = {};
  const here: Record<string, string> = {};
  for (const m of files) {
    const abs = await r.mediaAbs(m);
    here[m] = abs ?? resolve(r.root, m);
    facts[m] = abs ? await r.probe(abs) : undefined;
  }
  const where = resolveMediaPaths(files, r.mediaRoot, (m) => here[m] as string);
  const name = r.doc.name?.trim() || stem(r.abs);
  const { job, leftOut } = resolveJob(r.doc, facts, { name, path: (m) => where[m] as string });
  let text: string;
  if (r.format === "resolve") {
    try {
      text = fcp7Xml(job);
    } catch (e) {
      if (e instanceof ResolveRateError) throw new VideoExportRateError(e.message);
      throw e;
    }
  } else text = otioText(toOtio(r.doc, { name, media: job.media }));
  const out = join(dirname(r.abs), `${stem(r.abs)}.${r.format === "resolve" ? "xml" : "otio"}`);
  await writeWhole(out, text);
  const slash = r.path.replace(/\\/g, "/").lastIndexOf("/");
  const rel = `${slash >= 0 ? r.path.replace(/\\/g, "/").slice(0, slash + 1) : ""}${basename(out)}`;
  return {
    path: rel,
    format: r.format,
    clips: job.tracks.reduce((n, t) => n + t.clips.length, 0),
    files: files.length,
    ...(r.mediaRoot?.trim() && { mediaRoot: r.mediaRoot.trim() }),
    ...(files[0] && { example: where[files[0]] as string }),
    leftOut,
  };
}

/** What an export answer says, in English (the agent's). */
export function exportText(x: VideoExportResult): string {
  const l: ResolveLeftOut = x.leftOut;
  const lines = [
    `Saved ${x.path} (${x.format === "resolve" ? "FCP7 XML for DaVinci Resolve" : "OpenTimelineIO"}): ${x.clips} clip(s) of ${x.files} file(s).`,
  ];
  if (x.example)
    lines.push(
      x.mediaRoot
        ? `Files point to ${x.mediaRoot} by their names (e.g. ${x.example}): the originals must be there on the computer that runs Resolve; otherwise Resolve asks to relink them.`
        : `Files point to this machine (e.g. ${x.example}); give "media_root" (the folder of the originals on the computer with Resolve) if Resolve runs elsewhere.`,
    );
  const out: string[] = [];
  const add = (n: number, what: string) => {
    if (n > 0) out.push(`${n} ${what}`);
  };
  if (x.format === "resolve") {
    add(l.titles, "title/colour clip(s)");
    add(l.transitions, "transition(s)");
    add(l.fades, "clip(s) with fades");
    add(l.volumes, "volume change(s)");
    add(l.kenBurns, "Ken Burns move(s)");
    add(l.reframes, "reframed clip(s)");
    add(l.speeds, "speed change(s)");
    add(l.colors ?? 0, "colour correction(s) or LUT(s)");
    add(l.stills ?? 0, "still frame(s)");
    add(l.ducking, "ducked track(s)");
    add(l.markers, "marker(s)");
    add(l.captions, "subtitle(s)");
    if (out.length)
      lines.push(`Not in the XML (redo them in Resolve, as montatore does): ${out.join(", ")}.`);
  } else
    lines.push(
      "Titles, transitions and markers are OTIO's; the rest of the timeline is kept in metadata.redgiant.",
    );
  if (l.missing.length)
    lines.push(`Not found here (exported with what the timeline knows): ${l.missing.join(", ")}.`);
  return lines.join("\n");
}

/**
 * A timeline from an `.otio` file: its files are the project's when the URL points inside the
 * project (`root`), or when our own metadata names them; the rest is left out with a warning.
 */
export async function importOtio(
  abs: string,
  root: string,
): Promise<{ doc: RgVideo; warnings: string[] }> {
  const text = await readFile(abs, "utf8");
  const inside = (url: string): string | undefined => {
    let p: string;
    try {
      p = url.startsWith("file:")
        ? fileURLToPath(url.replace(/^file:\/\/localhost\//i, "file:///"))
        : url;
    } catch {
      return undefined;
    }
    const full = isAbsolute(p) ? resolve(p) : resolve(dirname(abs), p);
    const rel = relative(resolve(root), full);
    if (!rel || rel.startsWith("..") || isAbsolute(rel)) return undefined;
    return rel.split(sep).join("/");
  };
  // 3.10: an FCP7 XML from DaVinci Resolve or Premiere, beside the .otio.
  if (/\.xml$/i.test(abs)) return fromFcp7Xml(text, { media: inside });
  return fromOtio(text, { media: inside });
}
