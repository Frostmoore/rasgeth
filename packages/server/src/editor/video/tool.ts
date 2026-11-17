// The agents' `video` tool (G41.6): what canvas_edit does not do on a video project. `inspect`
// (ffprobe's facts; a timeline's summary and the B rules' warnings), `analyze` (G41.4: words with
// their times, silences proposed as cuts, speech or coverage), `assemble` (the automatic draft,
// `autoAssemble`, written as one edit the person sees and can undo; a timeline already edited is
// replaced only with the person's yes, and a version of it is kept first, A5), `captions` (the
// subtitles from what the timeline plays), `frame` (exact frames to look at) and `render` (the
// MP4 made on this machine as a job with its bar and «Cancel», put in the project and shown).
// Every edit of a timeline is canvas_edit's.

import { createHash, randomUUID } from "node:crypto";
import { mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { basename, dirname, extname, isAbsolute, join, relative, resolve } from "node:path";
import type { Tool, ToolContext } from "@redgiant/agent";
import {
  ASSEMBLE_ROLES,
  type AssembleFile,
  type AssembleRole,
  autoAssemble,
  BROLL_COVERAGE,
  type BrollCoverage,
  brollRules,
  cutsFromSilence,
  type DocFile,
  diffTimeline,
  framesToSeconds,
  isMediaRef,
  type Job,
  type MediaAnalysis,
  type MediaProbe,
  parseTime,
  type RenderMachine,
  type RenderWhere,
  type RgVideo,
  readRgVideo,
  setCaptionSegments,
  setCaptionSettings,
  timecode,
  timelineInserts,
  VIDEO_ENGINE,
  VIDEO_ENGINE_VERSION,
  type VideoAction,
  type VideoDocOp,
  type VideoRenderResult,
  validateInserts,
  writeRgVideo,
} from "@redgiant/protocol";
import type { Workspace } from "@redgiant/tools";
import { z } from "zod";
import { fileAt, within } from "../../canvas-tools.js";
import type { Jobs } from "../../jobs.js";
import type { EditorHost } from "../host.js";
import type { VideoAnalysis, VideoTools } from "./analysis.js";
import { captionsForTimeline, timelineWords } from "./captions.js";
import type { MediaRunner } from "./media-run.js";
import type { VideoPreviews } from "./preview.js";
import type { VideoRenders } from "./renders.js";
import { saveVideoVersion } from "./versions.js";

const PICTURE = /\.(png|jpe?g|webp|gif|bmp|tiff?|avif|heic|heif)$/i;
const MEDIA =
  /\.(mp4|mov|m4v|mkv|webm|avi|mts|m2ts|mxf|3gp|mp3|wav|m4a|aac|flac|ogg|oga|opus|aiff?|png|jpe?g|webp|gif|bmp|tiff?|avif|heic|heif)$/i;
/** Frames one call shows at most (montatore: one every 2 s, at most 8). */
export const FRAMES_MAX = 8;
/** The transcript an answer carries, per file. */
const WORDS_CHARS = 6000;

export interface VideoToolHost {
  analysis(): VideoAnalysis;
  renders(): VideoRenders;
  previews(): VideoPreviews;
  /** ffmpeg and ffprobe (downloaded when missing). */
  tools(owner: string): Promise<VideoTools>;
  run(): MediaRunner;
  jobs: Jobs;
  editor: EditorHost;
  docFileOf(owner: string, abs: string): Promise<DocFile | undefined>;
  scopeRoot(owner: string, scope: string): Promise<string>;
  readOnly(owner: string, scope: string): boolean;
  /** Asks the person (every channel, their rules); true only for a yes. */
  confirm(ctx: ToolContext, question: string, yes: string, no: string): Promise<boolean>;
  /** Opens a file in the person's canvas (show_file). */
  show(abs: string, title: string, ctx: ToolContext): Promise<void>;
  /** The person's language, for the track names and the question. */
  lang(owner: string): string;
  /** G41.7: where a render in `scope` goes (the person's choice, remembered when it changes). */
  place(
    owner: string,
    scope: string,
    asked: string | undefined,
    byPerson: boolean,
  ): Promise<{ where: RenderWhere; machines: RenderMachine[] }>;
  /** Asks the person to pick one of `options` (every channel, their rules): the label, or none. */
  choose(ctx: ToolContext, question: string, options: string[]): Promise<string | undefined>;
}

export const VIDEO_TOOL_DESCRIPTION = `Video projects: look at, analyse, assemble and render videos. Edits of a timeline (.rgvideo) are canvas_edit's (help: true lists them); canvas_look view "structure" reads it.
Recommended flow: inspect → analyze → assemble → look at the B clips (frame) and direct them on the words that name what they show (assemble again with "inserts", or canvas_edit) → captions → render.
- {"action":"inspect","files":["riprese/a.mp4","film.rgvideo"]}: length, size, rate, rotation, date and camera timecode of each file; for a timeline its tracks and what breaks the rules of the B clips (they warn, never block: the person decides).
- {"action":"analyze","files":["riprese/"]}: the words said with their times, the silences proposed as cuts, and whether each clip is speech (A, carries the story) or coverage (B). A folder means its media files. Slow the first time (transcription), then cached.
- {"action":"assemble","path":"montaggio.rgvideo","files":["riprese/"],"aspect":"9:16","target_seconds":60,"music":"musica/base.mp3","roles":{"riprese/drone.mp4":"B"},"inserts":[{"media":"riprese/porto.mp4","start":12.4,"end":17,"in":3,"reason":"«il porto»"}]}: a repeatable draft: speech on V1/A1 in shooting order with its silences cut, coverage and pictures on V2 with fades and Ken Burns, music ducked on A3, a voice-over covered by the B clips. "inserts" (seconds of the program, from the words this action returns) places the B clips where you say; they are moved to keep the rules (2–7 s, nothing in the first 5 s, 3 s of speaker between, no word split). Roles: A, B, music, voice, skip. Replacing a timeline the person edited asks them first, and a version of it is kept.
- {"action":"captions","path":"montaggio.rgvideo","burn_in":true,"style":"boxed"}: subtitles from the speech the timeline plays.
- {"action":"frame","file":"riprese/porto.mp4","at":["2s","00:00:07:12"]} or "every":"2s": exact frames to look at (at most ${FRAMES_MAX}); on a timeline, the finished picture at that time.
- {"action":"render","path":"montaggio.rgvideo","aspect":"16:9|9:16|1:1","height":1080,"quality":"draft|good|best"}: the MP4 (minutes; the person sees the bar and can cancel), saved as renders/<name>-v<n>.mp4 and shown. One render at a time per project. It is made on the machine the person chose for the project (this one or a node, asked at the first render); "where" only suggests one then, it cannot change their choice.`;

const Insert = z.object({
  media: z.string().min(1),
  start: z.union([z.number(), z.string()]),
  end: z.union([z.number(), z.string()]),
  in: z.union([z.number(), z.string()]).optional(),
  reason: z.string().max(400).optional(),
});

const Input = z.object({
  action: z.enum(["inspect", "analyze", "assemble", "captions", "frame", "render"]),
  files: z.array(z.string().min(1)).max(200).optional(),
  file: z.string().min(1).optional(),
  path: z.string().min(1).optional(),
  language: z.string().max(20).optional(),
  transcribe: z.boolean().optional(),
  force: z.boolean().optional(),
  aspect: z.enum(["16:9", "9:16", "1:1"]).optional(),
  order: z.array(z.string()).max(200).optional(),
  roles: z
    .record(z.string(), z.enum(ASSEMBLE_ROLES as [AssembleRole, ...AssembleRole[]]))
    .optional(),
  cut_silences: z.boolean().optional(),
  target_seconds: z.number().positive().max(86_400).optional(),
  music: z.union([z.string().min(1), z.literal(false), z.null()]).optional(),
  inserts: z.array(Insert).max(500).optional(),
  rules: z
    .object({
      min_seconds: z.number().min(0.5).max(60).optional(),
      max_seconds: z.number().min(0.5).max(120).optional(),
      intro_seconds: z.number().min(0).max(120).optional(),
      gap_seconds: z.number().min(0).max(120).optional(),
      coverage: z
        .enum(Object.keys(BROLL_COVERAGE) as [BrollCoverage, ...BrollCoverage[]])
        .optional(),
    })
    .optional(),
  brief: z.string().max(4000).optional(),
  burn_in: z.boolean().optional(),
  style: z.enum(["plain", "boxed", "bold"]).optional(),
  position: z.enum(["bottom", "top"]).optional(),
  at: z
    .union([z.string(), z.number(), z.array(z.union([z.string(), z.number()])).max(FRAMES_MAX)])
    .optional(),
  every: z.union([z.string(), z.number()]).optional(),
  width: z.number().int().min(256).max(1600).optional(),
  height: z.number().int().min(144).max(4320).optional(),
  quality: z.enum(["draft", "good", "best"]).optional(),
  where: z.string().min(1).max(100).optional(),
});
type In = z.infer<typeof Input>;

class Bad extends Error {}
const bad = (why: string): never => {
  throw new Bad(why);
};

const s1 = (s: number) => `${(Math.round(s * 10) / 10).toFixed(1)} s`;
const clock = (s: number) => {
  const m = Math.floor(s / 60);
  const r = s - m * 60;
  return `${m}:${r < 10 ? "0" : ""}${r.toFixed(1)}`;
};

/** Seconds from "4s", "4.5", "1:02.5", "00:00:04:12" (at `fps`), or a number of seconds. */
export function secondsOf(v: unknown, fps = 30): number | undefined {
  if (typeof v === "number") return Number.isFinite(v) && v >= 0 ? v : undefined;
  if (typeof v !== "string") return undefined;
  const t = v.trim().replace(",", ".");
  const tc = /^(\d+):(\d{1,2}):(\d{1,2}):(\d{1,3})$/.exec(t);
  if (tc) return Number(tc[1]) * 3600 + Number(tc[2]) * 60 + Number(tc[3]) + Number(tc[4]) / fps;
  const ms = /^(?:(\d+):)?(\d+):(\d+(?:\.\d+)?)$/.exec(t);
  if (ms) return Number(ms[1] ?? 0) * 3600 + Number(ms[2]) * 60 + Number(ms[3]);
  const sec = /^(\d+(?:\.\d+)?)\s*s?$/.exec(t);
  return sec ? Number(sec[1]) : undefined;
}

/** A file's facts in one line. */
export function probeLine(path: string, p: MediaProbe): string {
  const parts: string[] = [];
  if (p.kind === "image") parts.push(`picture ${p.width}×${p.height}`);
  else if (p.kind === "audio")
    parts.push(
      `sound ${s1(p.duration ?? 0)}${p.sampleRate ? `, ${p.sampleRate / 1000} kHz` : ""}${p.channels ? `, ${p.channels} ch` : ""}`,
    );
  else {
    const fps = p.rate ? Math.round((p.rate.num / p.rate.den) * 100) / 100 : undefined;
    parts.push(
      `video ${p.width}×${p.height}${fps ? ` ${fps} fps` : ""}, ${s1(p.duration ?? 0)}, ${p.audio ? "with sound" : "no sound"}`,
    );
    if (p.rotation) parts.push(`rotated ${p.rotation}°`);
  }
  if (p.createdAt) parts.push(`shot ${p.createdAt.replace("T", " ").slice(0, 16)}`);
  if (p.timecode) parts.push(`camera timecode ${p.timecode}`);
  return `${path}: ${parts.join(", ")}`;
}

/** The words as short timed lines: a new one at a sentence's end, a pause or 10 s. */
export function wordLines(
  words: readonly { text: string; start: number; end: number }[],
  max = WORDS_CHARS,
): string {
  const lines: string[] = [];
  let cur: { start: number; end: number; text: string[] } | undefined;
  const flush = () => {
    if (cur) lines.push(`[${cur.start.toFixed(1)}–${cur.end.toFixed(1)}] ${cur.text.join(" ")}`);
    cur = undefined;
  };
  for (const w of words) {
    if (cur && (w.start - cur.end > 0.7 || w.end - cur.start > 10)) flush();
    cur ??= { start: w.start, end: w.end, text: [] };
    cur.text.push(w.text);
    cur.end = w.end;
    if (/[.!?…]["»”]?$/.test(w.text)) flush();
  }
  flush();
  let out = "";
  for (const [i, l] of lines.entries()) {
    if (out.length + l.length > max) return `${out}… (${lines.length - i} more lines)`;
    out += `${l}\n`;
  }
  return out.trimEnd();
}

/** The silences to cut: between the words, or (nothing transcribed) the quiet stretches. */
export function cutsOf(
  a: MediaAnalysis,
): { start: number; end: number; where: "head" | "mid" | "tail" }[] {
  if (a.cuts.length || a.transcript?.words.length) return a.cuts;
  return cutsFromSilence(a.silent, a.probe.duration ?? 0, a.settings.minSec, a.settings.padding);
}

/** What `analyze` tells of one file. */
export function analysisText(path: string, a: MediaAnalysis): string {
  const out = [probeLine(path, a.probe)];
  if (a.probe.kind === "image") return `${out[0]}\n  coverage (B): a picture`;
  const sp = a.speech;
  out.push(
    `  speech ${Math.round(sp.ratio * 100)}% (${s1(sp.seconds)}${sp.source === "sound" ? ", from the sound's level: no transcription" : ""}) → ${sp.role === "A" ? "A, carries the story" : a.probe.kind === "audio" ? (sp.ratio >= 0.25 && sp.seconds >= 3 ? "a voice-over" : "music or sound") : "B, coverage"}`,
  );
  const cuts = cutsOf(a);
  if (cuts.length)
    out.push(
      `  silences proposed as cuts (${s1(cuts.reduce((n, c) => n + c.end - c.start, 0))}${a.transcript?.words.length ? "" : ", from the sound's level"}): ${cuts
        .slice(0, 40)
        .map(
          (c) =>
            `${c.start.toFixed(1)}–${c.end.toFixed(1)}${c.where === "mid" ? "" : ` (${c.where})`}`,
        )
        .join(", ")}${cuts.length > 40 ? ", …" : ""}`,
    );
  if (a.transcript?.words.length)
    out.push(
      `  words (${a.transcript.language || "?"}, times ${a.transcript.timing === "word" ? "per word" : a.transcript.timing === "segment" ? "spread in sentences" : "estimated"}):\n${wordLines(
        a.transcript.words,
      )
        .split("\n")
        .map((l) => `    ${l}`)
        .join("\n")}`,
    );
  return out.join("\n");
}

const TEXTS = {
  en: {
    ask: "Replace the timeline «{name}» with a new automatic assembly? It was changed after it was made; a copy stays in Versions.",
    yes: "Replace it",
    no: "Keep it",
    header: "Assembly",
    music: "Music",
  },
  it: {
    ask: "Sostituisco la timeline «{name}» con un nuovo montaggio automatico? È stata cambiata dopo; una copia resta in Versioni.",
    yes: "Sostituisci",
    no: "Tienila",
    header: "Montaggio",
    music: "Musica",
  },
} as const;
const textsOf = (lang: string) => (lang.startsWith("it") ? TEXTS.it : TEXTS.en);

/** The timeline's bytes without its assembly mark: changed after the draft or not. */
export function assembledHash(doc: RgVideo): string {
  const meta = { ...(doc.metadata ?? {}) };
  delete meta.assembledHash;
  const bare: RgVideo = { ...doc, metadata: meta };
  if (!Object.keys(meta).length) delete bare.metadata;
  return createHash("sha256").update(writeRgVideo(bare)).digest("hex").slice(0, 32);
}

const wrap = (op: VideoAction): VideoDocOp => ({
  family: "video",
  engine: VIDEO_ENGINE,
  engineVersion: VIDEO_ENGINE_VERSION,
  op,
});

export function videoTool(
  agent: { id: string; name: string; ownerId: string },
  ws: Workspace,
  host: VideoToolHost,
): Tool {
  const owner = agent.ownerId;
  const author = (ctx: ToolContext) => ({
    id: agent.id,
    name: agent.name,
    sessionId: ctx.sessionId,
  });

  /** A file of the workspace, in a project RedGiant knows. */
  const where = async (p: string, mustExist = true) => {
    let abs: string;
    if (mustExist) {
      const f = await fileAt(ws, p);
      if ("error" in f) return bad(f.error);
      abs = f.abs;
    } else {
      abs = isAbsolute(p) ? resolve(p) : resolve(ws.root, p);
      if (!within(resolve(ws.root), abs)) bad(`"${p}" is outside your workspace.`);
    }
    const file = await host.docFileOf(owner, abs);
    if (!file) bad(`${basename(abs)} is in no project or folder RedGiant knows.`);
    return { abs, file: file as DocFile };
  };

  /** The media files named (a folder: its media files, not deeper than 3 levels). */
  const mediaList = async (names: readonly string[]) => {
    const out: string[] = [];
    for (const n of names) {
      const abs = isAbsolute(n) ? resolve(n) : resolve(ws.root, n);
      const st = await stat(abs).catch(() => undefined);
      if (st?.isDirectory()) {
        // Paths relative to the workspace's root; at most three folders below the one named.
        const under = relative(ws.root, abs).replace(/\\/g, "/") || ".";
        const depth = under === "." ? 0 : under.split("/").length;
        const found = await ws.glob("**/*", under).catch(() => [] as string[]);
        for (const f of found)
          if (
            MEDIA.test(f) &&
            !f.includes(".versions/") &&
            !/(^|\/)renders\//.test(f) &&
            f.split("/").length - depth <= 4
          )
            out.push(f);
      } else out.push(n);
    }
    return [...new Set(out)];
  };

  const probeOf = async (abs: string, signal?: AbortSignal) =>
    host.analysis().probe(abs, await host.tools(owner), undefined, signal);

  /** Waits for a job; the turn stopped, it is cancelled. */
  const settle = async (job: Job, signal?: AbortSignal): Promise<Job> => {
    const stop = () => host.jobs.cancel(owner, job.id);
    signal?.addEventListener("abort", stop, { once: true });
    try {
      return (await host.jobs.settled(job.id, 50)) ?? job;
    } finally {
      signal?.removeEventListener("abort", stop);
    }
  };

  const analyzeOne = async (abs: string, name: string, i: In, signal?: AbortSignal) => {
    const job = await host.analysis().analyze(owner, abs, name, {
      ...(i.language && { language: i.language }),
      ...(i.transcribe === false && { transcribe: false }),
      ...(i.force && { force: true }),
    });
    const end = await settle(job, signal);
    if (end.state === "done") return end.result as MediaAnalysis;
    throw new Bad(
      end.state === "cancelled"
        ? "the analysis was cancelled"
        : (end.error?.message ?? "the analysis failed"),
    );
  };

  /** The timeline as saved now (the editor's latest edits first). */
  const timeline = async (p: string | undefined) => {
    if (!p) return bad('give "path", the timeline (.rgvideo)');
    if (extname(p).toLowerCase() !== ".rgvideo") bad(`"${p}" is not a timeline (.rgvideo)`);
    const w = await where(p);
    await host.editor.writeNow(owner, w.file).catch(() => {});
    const doc = readRgVideo(await readFile(w.abs, "utf8"));
    const root = await host.scopeRoot(owner, w.file.scope);
    const mediaPath = async (m: string) => {
      const abs = resolve(root, m);
      return within(resolve(root), abs) && (await stat(abs).catch(() => undefined))?.isFile()
        ? abs
        : undefined;
    };
    return { ...w, doc, root, mediaPath };
  };

  const inspect = async (i: In, ctx: ToolContext) => {
    const lines: string[] = [];
    for (const name of await mediaList(i.files ?? (i.file ? [i.file] : bad('give "files"')))) {
      try {
        if (/\.rgvideo$/i.test(name)) {
          const t = await timeline(name);
          lines.push(await timelineText(name, t.doc, t.mediaPath));
          continue;
        }
        const w = await where(name);
        if (!MEDIA.test(name)) {
          lines.push(`${name}: not a video, picture or sound`);
          continue;
        }
        lines.push(probeLine(name, await probeOf(w.abs, ctx.signal)));
      } catch (e) {
        lines.push(`${name}: ${(e as Error).message}`);
      }
    }
    return lines.join("\n");
  };

  /** A timeline in a few lines, with what breaks the B rules. */
  const timelineText = async (
    name: string,
    doc: RgVideo,
    mediaPath: (m: string) => Promise<string | undefined>,
  ) => {
    const rate = doc.format.rate;
    const end = doc.clips.reduce((n, c) => Math.max(n, c.start + c.sourceRange.duration), 0);
    const out = [
      `${name}: timeline «${doc.name ?? basename(name, ".rgvideo")}» ${doc.format.width}×${doc.format.height} (${doc.format.aspect}) at ${Math.round((rate.num / rate.den) * 100) / 100} fps, ${timecode(end, rate)} (${s1(framesToSeconds(end, rate))}), ${doc.tracks.length} tracks, ${doc.clips.length} clips${doc.assembled ? `, assembled ${doc.assembled.at.slice(0, 16).replace("T", " ")}` : ""}. canvas_look view "structure" lists every clip.`,
    ];
    const inserts = timelineInserts(doc);
    if (inserts.length) {
      const transcripts: Record<string, { words: { start: number; end: number; text: string }[] }> =
        {};
      const coverage = new Map<string, { id: string; still: boolean; duration: number | null }>();
      for (const c of doc.clips) {
        if (!isMediaRef(c.ref)) continue;
        const abs = await mediaPath(c.ref.media);
        const a = abs
          ? await host
              .analysis()
              .cached(abs)
              .catch(() => undefined)
          : undefined;
        if (a?.transcript && c.track.startsWith("A")) transcripts[c.ref.media] = a.transcript;
        if (!c.track.startsWith("A") && c.track !== "V1")
          coverage.set(c.ref.media, {
            id: c.ref.media,
            still: !!c.ref.still,
            duration: c.ref.still
              ? null
              : c.ref.frames
                ? framesToSeconds(c.ref.frames, rate)
                : null,
          });
      }
      const words = timelineWords(doc, transcripts).map((w) => ({
        start: framesToSeconds(w.start, rate),
        end: framesToSeconds(w.end, rate),
      }));
      const v = validateInserts(
        brollRules(),
        [...coverage.values()].map((b) =>
          b.duration === null && !b.still ? { ...b, duration: 1e9 } : b,
        ),
        words,
        framesToSeconds(end, rate),
        inserts,
      );
      out.push(
        v.length
          ? `B clips against the rules (warnings only, the person decides):\n${v.map((x) => `  - ${x.message}`).join("\n")}`
          : `The ${inserts.length} B clips keep the rules.`,
      );
    }
    return out.join("\n");
  };

  const analyze = async (i: In, ctx: ToolContext) => {
    const names = await mediaList(i.files ?? (i.file ? [i.file] : bad('give "files"')));
    if (!names.length) bad("no video, picture or sound among the files given");
    const out: string[] = [];
    for (const name of names) {
      try {
        const w = await where(name);
        if (PICTURE.test(name)) {
          out.push(
            `${probeLine(name, await probeOf(w.abs, ctx.signal))}\n  coverage (B): a picture`,
          );
          continue;
        }
        out.push(analysisText(name, await analyzeOne(w.abs, w.file.path, i, ctx.signal)));
      } catch (e) {
        if (ctx.signal?.aborted) throw e;
        out.push(`${name}: ${(e as Error).message}`);
      }
    }
    return out.join("\n\n");
  };

  const assemble = async (i: In, ctx: ToolContext) => {
    if (!i.path) bad('give "path", the timeline to write (.rgvideo)');
    const path = (i.path as string).replace(/\\/g, "/");
    if (extname(path).toLowerCase() !== ".rgvideo") bad(`"${path}" is not a timeline (.rgvideo)`);
    const target = await where(path, false);
    if (host.readOnly(owner, target.file.scope))
      bad(
        `${basename(path)} belongs to an archived project: its files are read only until the person restores it.`,
      );
    const names = await mediaList(
      i.files ?? bad('give "files": the clips, pictures and music to use'),
    );
    const files: AssembleFile[] = [];
    const notes: string[] = [];
    const byName = new Map<string, string>();
    for (const name of names) {
      try {
        const w = await where(name);
        if (w.file.scope !== target.file.scope) {
          notes.push(`${name}: not in the same project as the timeline, left out`);
          continue;
        }
        byName.set(name.replace(/\\/g, "/").replace(/^\.\//, ""), w.file.path);
        const role = i.roles?.[name];
        if (role === "skip") {
          files.push({ path: w.file.path, probe: await probeOf(w.abs, ctx.signal), role });
          continue;
        }
        if (PICTURE.test(name)) {
          files.push({
            path: w.file.path,
            probe: await probeOf(w.abs, ctx.signal),
            ...(role && { role }),
          });
          continue;
        }
        const a = await analyzeOne(w.abs, w.file.path, i, ctx.signal);
        files.push({
          path: w.file.path,
          probe: a.probe,
          cuts: cutsOf(a),
          ...(a.transcript && { words: a.transcript.words }),
          speech: a.speech,
          ...(role && { role }),
        });
      } catch (e) {
        if (ctx.signal?.aborted) throw e;
        notes.push(`${name}: ${(e as Error).message}, left out`);
      }
    }
    if (!files.length) bad(`nothing to assemble: ${notes.join("; ") || "no media files"}`);
    const inProject = (n: string) => byName.get(n.replace(/\\/g, "/").replace(/^\.\//, "")) ?? n;
    const fpsOf = files.find((f) => f.probe.rate)?.probe.rate;
    const fps = fpsOf ? fpsOf.num / fpsOf.den : 30;
    const sec = (v: unknown, what: string) =>
      secondsOf(v, fps) ?? bad(`"${what}" is not a time (seconds, "4.5s" or "00:00:04:12")`);
    const t = textsOf(host.lang(owner));
    const r = i.rules;
    const made = autoAssemble(files, {
      name: basename(path, extname(path)),
      at: new Date().toISOString(),
      ...(i.aspect && { aspect: i.aspect }),
      ...(i.order && { order: i.order.map(inProject) }),
      ...(i.cut_silences === false && { cutSilences: false }),
      ...(i.target_seconds && { targetSeconds: i.target_seconds }),
      ...(i.music === false || i.music === null
        ? { music: false }
        : i.music
          ? { music: inProject(i.music) }
          : {}),
      ...(r && {
        rules: {
          ...(r.min_seconds !== undefined && { minLen: r.min_seconds }),
          ...(r.max_seconds !== undefined && { maxLen: r.max_seconds }),
          ...(r.intro_seconds !== undefined && { introHold: r.intro_seconds }),
          ...(r.gap_seconds !== undefined && { minGap: r.gap_seconds }),
          ...(r.coverage && { coverage: r.coverage }),
        },
      }),
      ...(i.inserts?.length && {
        inserts: i.inserts.map((x) => ({
          media: inProject(x.media),
          start: sec(x.start, "start"),
          end: sec(x.end, "end"),
          ...(x.in !== undefined && { in: sec(x.in, "in") }),
          ...(x.reason && { reason: x.reason }),
        })),
      }),
      ...(i.brief && { text: i.brief }),
      names: { music: t.music },
    });
    const doc: RgVideo = { ...made.doc, metadata: { ...(made.doc.metadata ?? {}) } };
    (doc.metadata as Record<string, unknown>).assembledHash = assembledHash(doc);
    const head = await replaceTimeline(target, doc, ctx, t);
    if (typeof head !== "string") return head;
    await host.show(target.abs, basename(path), ctx).catch(() => {});
    return `${head}\n${reportText(made.report, notes)}`;
  };

  /** Writes the assembly: a new file, or one edit over the timeline there (asked when edited). */
  const replaceTimeline = async (
    target: { abs: string; file: DocFile },
    doc: RgVideo,
    ctx: ToolContext,
    t: (typeof TEXTS)[keyof typeof TEXTS],
  ): Promise<string | { content: string; isError: true }> => {
    const exists = (await stat(target.abs).catch(() => undefined))?.isFile();
    if (!exists) {
      await mkdir(dirname(target.abs), { recursive: true });
      await writeFile(target.abs, writeRgVideo(doc), { flag: "wx" });
      return `Assembled into ${target.file.path} (a new timeline).`;
    }
    await host.editor.writeNow(owner, target.file).catch(() => {});
    const read = await host.editor.read(owner, target.file);
    const before = (read.model as { doc: RgVideo }).doc;
    let kept = "";
    if (before.clips.length) {
      const untouched =
        before.assembled &&
        (before.metadata as Record<string, unknown> | undefined)?.assembledHash ===
          assembledHash(before);
      if (!untouched) {
        const yes = await host.confirm(
          ctx,
          t.ask.replace("{name}", before.name ?? basename(target.file.path)),
          t.yes,
          t.no,
        );
        if (!yes)
          return {
            content: `Nothing replaced: the person kept the timeline as it is (it was edited after its assembly). Change it with canvas_edit, or assemble into another path.`,
            isError: true,
          };
      }
      const v = await saveVideoVersion({
        abs: target.abs,
        path: target.file.path,
        doc: before,
        name: before.name ?? basename(target.file.path, ".rgvideo"),
        reason: "before_assemble",
      });
      kept = ` The timeline before is kept as the version ${v.path}.`;
    }
    const action = diffTimeline(before, doc, "replace");
    if (!action) return `The assembly is the same as the timeline there: nothing changed.`;
    const mode = host.editor.modeFor(owner, agent.id, target.file);
    const req = {
      author: author(ctx),
      baseRevision: read.revision,
      ops: [wrap(action)],
      groupId: host.editor.groupOf(ctx.sessionId),
    };
    if (mode === "propose") {
      const p = await host.editor.propose(owner, target.file, req);
      return `Proposed to the person as one edit (proposal ${p.proposalId}): it applies when they accept it.${kept}`;
    }
    const out = await host.editor.apply(owner, target.file, req);
    if (!out.ok)
      return { content: `Refused (nothing replaced): ${out.reason}.${kept}`, isError: true };
    host.editor.seen(ctx.sessionId, owner, target.file, out.revision);
    return `Assembled into ${target.file.path} as revision ${out.revision} (one edit the person can undo).${kept}`;
  };

  const captions = async (i: In, ctx: ToolContext) => {
    const tl = await timeline(i.path);
    if (host.readOnly(owner, tl.file.scope))
      bad(`${basename(tl.file.path)} belongs to an archived project.`);
    const audible = new Set(
      tl.doc.tracks.filter((x) => x.kind === "Audio" && !x.muted).map((x) => x.id),
    );
    const sounds = [
      ...new Set(
        tl.doc.clips.flatMap((c) =>
          audible.has(c.track) && c.enabled && isMediaRef(c.ref) ? [c.ref.media] : [],
        ),
      ),
    ];
    const transcripts: Record<string, { words: { start: number; end: number; text: string }[] }> =
      {};
    const silent: string[] = [];
    for (const m of sounds) {
      const abs = await tl.mediaPath(m);
      if (!abs) {
        silent.push(`${m} (missing)`);
        continue;
      }
      const a = await analyzeOne(abs, m, i, ctx.signal);
      if (a.transcript?.words.length) transcripts[m] = a.transcript;
      else silent.push(m);
    }
    const segs = captionsForTimeline(tl.doc, transcripts);
    if (!segs.length)
      bad(
        `no words in what the timeline plays${silent.length ? ` (no words in ${silent.join(", ")})` : ""}`,
      );
    let next = setCaptionSegments(tl.doc, segs);
    next = setCaptionSettings(next, {
      ...(i.language !== undefined
        ? { language: i.language }
        : !next.captions.language && { language: host.lang(owner).split("-")[0] }),
      ...(i.burn_in !== undefined && { burnIn: i.burn_in }),
      ...(i.style && { style: i.style }),
      ...(i.position && { position: i.position }),
    });
    const action = diffTimeline(tl.doc, next, "caption");
    if (!action) return "The subtitles are already these: nothing changed.";
    await host.editor.writeNow(owner, tl.file).catch(() => {});
    const read = await host.editor.read(owner, tl.file);
    const out = await host.editor.apply(owner, tl.file, {
      author: author(ctx),
      baseRevision: read.revision,
      ops: [wrap(action)],
      groupId: host.editor.groupOf(ctx.sessionId),
    });
    if (!out.ok) return { content: `Refused (nothing changed): ${out.reason}.`, isError: true };
    host.editor.seen(ctx.sessionId, owner, tl.file, out.revision);
    return `${segs.length} subtitles from the speech in ${tl.file.path} (revision ${out.revision})${next.captions.burnIn ? ", burnt into the picture at the render" : ", as SRT and WebVTT beside the render (burn_in: true writes them into the picture)"}.${silent.length ? ` No words in: ${silent.join(", ")}.` : ""} Fix a line with canvas_edit set_caption.`;
  };

  const frame = async (i: In, ctx: ToolContext) => {
    const name = i.file ?? i.path ?? bad('give "file"');
    const side = i.width ?? 768;
    const tools = await host.tools(owner);
    const run = host.run();
    const tmp = join(host.analysis().cacheRoot, "work", `frames-${randomUUID().slice(0, 8)}`);
    await mkdir(tmp, { recursive: true });
    try {
      let times: number[];
      if (/\.rgvideo$/i.test(name)) {
        // A timeline: the finished picture, through the exact preview of one frame each.
        const tl = await timeline(name);
        const rate = tl.doc.format.rate;
        const asked = i.at === undefined ? [0] : Array.isArray(i.at) ? i.at : [i.at];
        const frames = asked.map((v) => parseTime(v, rate) ?? bad(`"${String(v)}" is not a time`));
        const images = [];
        const said: string[] = [];
        for (const f of frames.slice(0, FRAMES_MAX)) {
          const job = host.previews().exact(owner, {
            doc: tl.doc,
            name: basename(name),
            from: f,
            to: f + 1,
            mediaPath: tl.mediaPath,
          });
          const end = await settle(job, ctx.signal);
          if (end.state !== "done") {
            said.push(`${timecode(f, rate)}: ${end.error?.message ?? "not made"}`);
            continue;
          }
          const file = host
            .previews()
            .previewPath(owner, (end.result as { id: string }).id) as string;
          const got = await grab(
            run,
            tools.ffmpeg,
            file,
            0,
            side,
            join(tmp, `t${f}.jpg`),
            ctx.signal,
          );
          if (got) {
            images.push(got);
            said.push(`${timecode(f, rate)} (picture ${images.length})`);
          } else said.push(`${timecode(f, rate)}: no picture`);
        }
        return {
          content: `${basename(name)}, the finished picture at 360p: ${said.join("; ")}.`,
          ...(images.length && { images }),
        };
      }
      const w = await where(name);
      const abs = w.abs;
      const p = await probeOf(abs, ctx.signal);
      if (p.kind === "audio") bad(`${name} is a sound: it has no picture`);
      const d = p.duration ?? 0;
      const fps = p.rate ? p.rate.num / p.rate.den : 30;
      if (i.every !== undefined) {
        const step = secondsOf(i.every, fps) ?? bad('"every" is a time ("2s")');
        if (step <= 0) bad('"every" must be more than 0');
        const n = Math.min(
          FRAMES_MAX,
          Math.max(1, Math.floor(d / step) + (d % step > 0.05 ? 1 : 0)),
        );
        times = Array.from({ length: n }, (_, k) => k * step);
      } else {
        const asked = i.at === undefined ? [d / 2] : Array.isArray(i.at) ? i.at : [i.at];
        times = asked
          .slice(0, FRAMES_MAX)
          .map((v) => secondsOf(v, fps) ?? bad(`"${String(v)}" is not a time`));
      }
      const images = [];
      const said: string[] = [];
      for (const [k, t0] of times.entries()) {
        const t = p.kind === "image" ? 0 : Math.min(Math.max(0, t0), Math.max(0, d - 0.05));
        const got = await grab(run, tools.ffmpeg, abs, t, side, join(tmp, `f${k}.jpg`), ctx.signal);
        if (got) {
          images.push(got);
          said.push(`${clock(t)} (picture ${images.length})`);
        } else said.push(`${clock(t)}: no frame`);
        if (p.kind === "image") break;
      }
      return {
        content: `${probeLine(name, p)}\nFrames: ${said.join("; ")}.`,
        ...(images.length && { images }),
      };
    } finally {
      await rm(tmp, { recursive: true, force: true });
    }
  };

  const render = async (i: In, ctx: ToolContext) => {
    const tl = await timeline(i.path);
    if (host.readOnly(owner, tl.file.scope))
      bad(`${basename(tl.file.path)} belongs to an archived project.`);
    // G41.7: the machine the person chose (asked at the project's first render).
    let place = await host.place(owner, tl.file.scope, i.where, false);
    if (place.where.kind === "ask") {
      const ok = place.machines.filter((m) => m.ok);
      const label = (m: RenderMachine) =>
        `${m.id === "here" ? "This machine" : m.name}${m.gpu ? ` (${m.gpu}${m.nvenc ? ", NVENC" : ""})` : m.id === "here" ? "" : " (CPU only)"}`;
      const suggested = place.where.suggested;
      const options = [...ok].sort(
        (a, b) => Number(b.id === suggested) - Number(a.id === suggested),
      );
      const picked = await host.choose(
        ctx,
        `Where should the videos of this project be made? The choice stays for the project (you can change it in «Make the video» or Settings > Nodes).`,
        options.map(label),
      );
      const m = options.find((x) => label(x) === picked);
      if (!m)
        return {
          content: "The person did not choose where to make the video: nothing was rendered.",
          isError: true,
        };
      place = await host.place(owner, tl.file.scope, m.id, true);
    }
    if (place.where.kind === "refuse") {
      const w = place.where;
      const chosen = place.machines.find((m) => m.id === w.id);
      return {
        content:
          w.reason === "person-chose"
            ? `The person chose to make this project's videos on ${chosen?.id === "here" ? "this machine" : chosen?.name}: only they change it. Render without "where".`
            : w.reason === "unknown"
              ? `There is no machine "${i.where}". Machines: ${place.machines.map((m) => (m.id === "here" ? "here" : m.name)).join(", ")}.`
              : `${chosen?.id === "here" ? "This machine" : (chosen?.name ?? "That machine")} cannot render now (${w.reason}).`,
        isError: true,
      };
    }
    const target = place.where.kind === "use" ? place.where.id : "here";
    const node = target === "here" ? undefined : place.machines.find((m) => m.id === target);
    const queue = `${owner}\n${tl.file.scope}`;
    const waited = host.renders().busy(queue);
    const job = host.renders().start(owner, {
      ...(node && { node: { fingerprint: node.id, name: node.name } }),
      doc: tl.doc,
      name: basename(tl.file.path),
      queue,
      root: tl.root,
      path: tl.file.path,
      mediaPath: tl.mediaPath,
      ...(i.aspect && { aspect: i.aspect }),
      ...(i.height && { height: i.height }),
      ...(i.quality && { quality: i.quality }),
    });
    const end = await settle(job, ctx.signal);
    if (end.state === "cancelled")
      return {
        content: "The render was cancelled (by the person or the turn's end): no file was left.",
        isError: true,
      };
    if (end.state !== "done")
      return {
        content: `The render failed: ${end.error?.message ?? "unknown error"}.`,
        isError: true,
      };
    const r = end.result as VideoRenderResult;
    const abs = join(tl.root, r.path);
    await host.show(abs, basename(r.path), ctx).catch(() => {});
    return `Rendered ${r.path}${r.node ? ` on ${r.node}` : ""}${r.encoder === "h264_nvenc" ? " with NVENC" : ""}: ${r.width}×${r.height}, ${s1(r.seconds)}${r.reused ? ` (${r.reused} segments from the cache)` : ""}${waited ? ", after the render that was running" : ""}; shown to the person.${r.sidecars.length ? ` Subtitles beside it: ${r.sidecars.join(", ")}.` : ""}${r.warnings.length ? `\nWarnings: ${r.warnings.join("; ")}` : ""}`;
  };

  const t: Tool<In> = {
    def: {
      name: "video",
      description: VIDEO_TOOL_DESCRIPTION,
      inputSchema: {
        type: "object",
        properties: {
          action: {
            type: "string",
            enum: ["inspect", "analyze", "assemble", "captions", "frame", "render"],
          },
          files: {
            type: "array",
            items: { type: "string" },
            description: "Files or folders of your workspace",
          },
          file: { type: "string", description: "frame: the clip or timeline" },
          path: { type: "string", description: "The timeline (.rgvideo)" },
          aspect: { type: "string", enum: ["16:9", "9:16", "1:1"] },
          target_seconds: { type: "number", description: "assemble: about how long" },
          music: {
            type: ["string", "boolean", "null"],
            description: "assemble: the music file, or false for none",
          },
          roles: { type: "object", description: 'assemble: {"path": "A|B|music|voice|skip"}' },
          order: {
            type: "array",
            items: { type: "string" },
            description: "assemble: the speech clips' order",
          },
          inserts: {
            type: "array",
            items: { type: "object" },
            description: "assemble: {media, start, end, in?, reason?} in seconds of the program",
          },
          rules: {
            type: "object",
            description:
              "assemble: min_seconds, max_seconds, intro_seconds, gap_seconds, coverage low|medium|high",
          },
          cut_silences: { type: "boolean" },
          brief: {
            type: "string",
            description: "assemble: what the person asked, kept in the timeline",
          },
          language: { type: "string" },
          burn_in: { type: "boolean" },
          style: { type: "string", enum: ["plain", "boxed", "bold"] },
          at: { description: 'frame: a time or a list ("2s", "00:00:07:12")' },
          every: { description: 'frame: one every so long ("2s")' },
          height: { type: "number", description: "render: the short side in pixels (1080, 720…)" },
          quality: { type: "string", enum: ["draft", "good", "best"] },
          where: {
            type: "string",
            description: 'render: "here" or a node\'s name (a suggestion at the first render)',
          },
        },
        required: ["action"],
      },
    },
    schema: Input,
    async run(i, ctx) {
      try {
        switch (i.action) {
          case "inspect":
            return await inspect(i, ctx);
          case "analyze":
            return await analyze(i, ctx);
          case "assemble":
            return await assemble(i, ctx);
          case "captions":
            return await captions(i, ctx);
          case "frame":
            return await frame(i, ctx);
          case "render":
            return await render(i, ctx);
        }
      } catch (e) {
        if (e instanceof Bad) return { content: `Nothing done: ${e.message}.`, isError: true };
        throw e;
      }
    },
  };
  return t as Tool;
}

/** The assembly's report for the agent: what went where, the program's words for the direction. */
export function reportText(
  r: ReturnType<typeof autoAssemble>["report"],
  notes: string[] = [],
): string {
  const out = [
    `Program ${s1(r.seconds)}${r.cut ? ` (${s1(r.cut)} of silence cut)` : ""}. Speech on V1/A1: ${r.order.join(", ") || "none"}. Coverage: ${r.coverage.join(", ") || "none"}.${r.music ? ` Music on A3 (ducked under A1): ${r.music}.` : ""}${r.skipped.length ? ` Left out: ${r.skipped.join(", ")}.` : ""}`,
    r.inserts.length
      ? `B clips on V2: ${r.inserts.map((x) => `${x.b} ${x.start.toFixed(1)}–${x.end.toFixed(1)} s${x.bIn ? ` (from ${x.bIn.toFixed(1)} s)` : ""}`).join("; ")}.`
      : "No B clips on V2.",
  ];
  const fixed = r.actions.filter((a) => !a.code.startsWith("dropped_"));
  const dropped = r.actions.filter((a) => a.code.startsWith("dropped_"));
  if (fixed.length) out.push(`Moved to keep the rules: ${fixed.map((a) => a.message).join("; ")}.`);
  if (dropped.length) out.push(`Dropped: ${dropped.map((a) => a.message).join("; ")}.`);
  for (const w of [...r.warnings, ...notes]) out.push(`Note: ${w}`);
  if (r.words.length)
    out.push(
      `The program's words (seconds of the program, for "inserts": put each B on the words that name what it shows; look at the B clips with frame first):\n${wordLines(r.words)}`,
    );
  return out.join("\n");
}

// One exact frame of a file as a JPEG, at most `side` pixels on its long side.
async function grab(
  run: MediaRunner,
  ffmpeg: string,
  abs: string,
  t: number,
  side: number,
  out: string,
  signal?: AbortSignal,
) {
  await run(
    ffmpeg,
    [
      "-hide_banner",
      "-nostdin",
      "-y",
      "-ss",
      t.toFixed(3),
      "-i",
      abs,
      "-frames:v",
      "1",
      "-vf",
      `scale='if(gt(iw,ih),min(${side},iw),-2)':'if(gt(iw,ih),-2,min(${side},ih))'`,
      "-q:v",
      "4",
      out,
    ],
    { ...(signal && { signal }) },
  ).catch(() => undefined);
  const data = await readFile(out).catch(() => undefined);
  return data?.length
    ? {
        type: "image" as const,
        mediaType: "image/jpeg" as const,
        data: data.toString("base64"),
        name: basename(out),
      }
    : undefined;
}
