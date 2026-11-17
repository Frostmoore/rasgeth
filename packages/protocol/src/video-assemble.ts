// The automatic assembly (G41.6), montatore's premontage in one pure function: the files of a
// project and what the analysis learnt of them (G41.4) become a draft timeline that is the same
// every time for the same input. The speech ("A": the clips that carry the story) goes on V1/A1
// in shooting order (then the names' natural order: clip2 before clip10), its silences cut;
// the coverage ("B": clips without much speech, and pictures) goes on V2 over the speech with
// fades and Ken Burns taking turns, its sound on A2 linked and off (as montatore: off until the
// person turns it on); a sound file without speech is music on A3, ducked under the voice; a
// sound file with speech is a voice-over whose picture is coverage laid on V1. The B clips are
// spread evenly and then made to keep montatore's rules (`repairInserts`), or placed where the
// agent says (`inserts`, its direction: the words that name what a B shows). The agent then
// refines the draft with canvas_edit.

import type { RgVideo, VideoAspect, VideoClip, VideoRate, VideoTrack } from "./doc-video.js";
import type { MediaProbe, SilenceCut, SpeechInfo, TranscriptWord } from "./video-analysis.js";
import {
  type BrollAction,
  type BrollInsert,
  type BrollItem,
  type BrollRules,
  brollAllowsReuse,
  brollRules,
  brollTargetCount,
  longestPart,
  type ProgramWord,
  repairInserts,
} from "./video-broll.js";
import {
  cleanTimeline,
  formatFor,
  kenBurnsPreset,
  newRgVideo,
  secondsToFrames,
  type VideoProbe,
} from "./video-timeline.js";

/** What a file is in the assembly. */
export type AssembleRole = "A" | "B" | "music" | "voice" | "skip";
export const ASSEMBLE_ROLES: readonly AssembleRole[] = ["A", "B", "music", "voice", "skip"];

export interface AssembleFile {
  /** Its path in the project. */
  path: string;
  probe: MediaProbe;
  /** The silences proposed as cuts (G41.4's analysis). */
  cuts?: readonly Pick<SilenceCut, "start" | "end">[];
  /** The words said, seconds of the file. */
  words?: readonly Pick<TranscriptWord, "start" | "end" | "text">[];
  speech?: Pick<SpeechInfo, "ratio" | "seconds" | "role"> & Partial<Pick<SpeechInfo, "source">>;
  /** Chosen by the agent or the person: never guessed over. */
  role?: AssembleRole;
  /** A B's good stretches (seconds); absent: all of it. */
  parts?: readonly (readonly [number, number])[];
}

/** An insert asked by the agent: which B covers which seconds of the program. */
export interface AssembleInsert {
  media: string;
  start: number;
  end: number;
  /** Where in the B it starts (seconds; 0 by default). */
  in?: number;
  reason?: string;
}

export interface AssembleBrief {
  name?: string;
  /** The shape; absent: the first speech clip's. */
  aspect?: Exclude<VideoAspect, "free">;
  /** The A clips' order (paths); absent: shooting date, then name. */
  order?: readonly string[];
  /** false keeps the silences. */
  cutSilences?: boolean;
  /** Seconds: the speech is ended at the last word before it. */
  targetSeconds?: number;
  /** The music file; false: none; absent: the first sound file without speech. */
  music?: string | false;
  /** The music's volume in dB (−8 by default), ducked by 12 dB under the voice. */
  musicDb?: number;
  /** The B clips' fades, frames (0.4 s by default). */
  fadeFrames?: number;
  rules?: Partial<BrollRules>;
  /** The agent's direction: replaces the evenly spread draft. */
  inserts?: readonly AssembleInsert[];
  /** The brief in words, kept in the timeline (`assembled.brief`). */
  text?: string;
  /** When (ISO 8601): the same input, the same timeline. */
  at: string;
  /** The tracks' names (the person's language). */
  names?: Partial<Record<"a" | "b" | "aAudio" | "bAudio" | "music", string>>;
}

/** One stretch of an A file kept in the program. */
export interface AssemblePiece {
  media: string;
  /** Seconds of the file. */
  from: number;
  to: number;
  /** Seconds of the program. */
  at: number;
  voice: boolean;
}

export interface AssembleReport {
  /** The A files in their order, then the voice-overs among them. */
  order: string[];
  coverage: string[];
  music?: string;
  skipped: string[];
  pieces: AssemblePiece[];
  /** Seconds of the program, and the seconds of silence cut. */
  seconds: number;
  cut: number;
  inserts: BrollInsert[];
  actions: BrollAction[];
  warnings: string[];
  /** The program's words (seconds), for the agent's direction. */
  words: (ProgramWord & { text: string })[];
}

const round3 = (n: number) => Math.round(n * 1000) / 1000;
const natural = (a: string, b: string) =>
  a.localeCompare(b, "en", { numeric: true, sensitivity: "base" }) || (a < b ? -1 : a > b ? 1 : 0);

/** The role a file plays when nobody chose: speech, coverage, music or a voice-over. */
export function assembleRole(f: AssembleFile): Exclude<AssembleRole, "skip"> {
  if (f.role && f.role !== "skip") return f.role;
  const p = f.probe;
  if (p.kind === "image") return "B";
  const ratio = f.speech?.ratio ?? 0;
  const seconds = f.speech?.seconds ?? 0;
  const speaks = ratio >= 0.25 && seconds >= 3;
  // A sound file is a voice-over only when words were heard: its level alone says nothing.
  if (p.kind === "audio") return speaks && f.speech?.source !== "sound" ? "voice" : "music";
  return f.speech?.role ?? (speaks ? "A" : "B");
}

/** The A files' order: shooting date when every one has it, otherwise the names' natural order. */
export function assembleOrder(files: readonly AssembleFile[]): AssembleFile[] {
  const dated = files.every(
    (f) => f.probe.createdAt && !Number.isNaN(Date.parse(f.probe.createdAt)),
  );
  return [...files].sort((a, b) =>
    dated
      ? Date.parse(a.probe.createdAt as string) - Date.parse(b.probe.createdAt as string) ||
        natural(a.path, b.path)
      : natural(a.path, b.path),
  );
}

/** [0, duration] without the cuts (merged when they overlap). */
export function keptSpans(
  duration: number,
  cuts: readonly Pick<SilenceCut, "start" | "end">[],
): [number, number][] {
  const sorted = [...cuts]
    .map((c) => [Math.max(0, c.start), Math.min(duration, c.end)] as [number, number])
    .filter(([s, e]) => e > s)
    .sort((a, b) => a[0] - b[0]);
  const kept: [number, number][] = [];
  let pos = 0;
  for (const [s, e] of sorted) {
    if (s > pos) kept.push([pos, s]);
    pos = Math.max(pos, e);
  }
  if (pos < duration) kept.push([pos, duration]);
  return kept
    .map(([s, e]) => [round3(s), round3(e)] as [number, number])
    .filter(([s, e]) => e - s > 0.04);
}

/**
 * The cuts when nothing was transcribed: the quiet stretches themselves (ffmpeg's
 * `silencedetect`) longer than `minSec`, flush at the head and the tail, `padding` kept inside.
 */
export function cutsFromSilence(
  silent: readonly (readonly [number, number])[],
  duration: number,
  minSec = 0.8,
  padding = 0.15,
): { start: number; end: number; where: "head" | "mid" | "tail" }[] {
  const out: { start: number; end: number; where: "head" | "mid" | "tail" }[] = [];
  for (const [s, e] of [...silent].sort((a, b) => a[0] - b[0])) {
    const from = Math.max(0, s);
    const to = Math.min(duration, e);
    if (to - from < minSec - 1e-9) continue;
    const head = from <= 0.01;
    const tail = to >= duration - 0.01;
    const cs = head ? from : from + padding;
    const ce = tail ? to : to - padding;
    if (ce - cs >= 0.3 - 1e-9)
      out.push({
        start: round3(cs),
        end: round3(ce),
        where: head ? "head" : tail ? "tail" : "mid",
      });
  }
  return out;
}

const KB = [
  kenBurnsPreset("in", "right"),
  kenBurnsPreset("out", "left"),
  kenBurnsPreset("in", "left"),
  kenBurnsPreset("out", "right"),
];

/**
 * The draft timeline and what was done. Files whose probe is unknown never get here: the caller
 * says why they are missing. Nothing in it depends on the clock but `brief.at`.
 */
export function autoAssemble(
  files: readonly AssembleFile[],
  brief: AssembleBrief,
): { doc: RgVideo; report: AssembleReport } {
  const warnings: string[] = [];
  const skipped = files.filter((f) => f.role === "skip").map((f) => f.path);
  const live = files.filter((f) => f.role !== "skip");
  const roleOf = new Map(live.map((f) => [f.path, assembleRole(f)]));
  let speech = live.filter((f) => {
    const r = roleOf.get(f.path);
    return r === "A" || r === "voice";
  });
  if (brief.order?.length) {
    const at = new Map(brief.order.map((p, i) => [p, i]));
    const listed = speech
      .filter((f) => at.has(f.path))
      .sort((a, b) => (at.get(a.path) ?? 0) - (at.get(b.path) ?? 0));
    speech = [...listed, ...assembleOrder(speech.filter((f) => !at.has(f.path)))];
  } else speech = assembleOrder(speech);
  const coverage = assembleOrder(live.filter((f) => roleOf.get(f.path) === "B"));
  const musicFile =
    brief.music === false
      ? undefined
      : brief.music
        ? live.find((f) => f.path === brief.music)
        : assembleOrder(live.filter((f) => roleOf.get(f.path) === "music"))[0];
  if (typeof brief.music === "string" && !musicFile)
    warnings.push(`The music "${brief.music}" is not among the files given: no music.`);
  if (!speech.length && coverage.length)
    warnings.push("No file has speech: the coverage is laid one clip after the other on V1.");

  // The format: the shape asked, otherwise the first file with a picture.
  const first = [...speech, ...coverage].find((f) => f.probe.kind === "video");
  const rate: VideoRate = first?.probe.rate ?? { num: 30, den: 1 };
  const w = first?.probe.width || 1920;
  const h = first?.probe.height || 1080;
  const format = brief.aspect
    ? formatFor(brief.aspect, Math.min(1080, Math.min(w, h)), rate)
    : {
        width: Math.max(16, Math.round(w / 2) * 2),
        height: Math.max(16, Math.round(h / 2) * 2),
        rate,
        aspect: (Math.abs(w / h - 16 / 9) < 0.02
          ? "16:9"
          : Math.abs(w / h - 9 / 16) < 0.02
            ? "9:16"
            : Math.abs(w / h - 1) < 0.02
              ? "1:1"
              : "free") as VideoAspect,
      };
  const f = (s: number) => secondsToFrames(s, rate);
  const rules = brollRules(brief.rules);
  const fade = Math.max(0, Math.round(brief.fadeFrames ?? f(0.4)));

  // The program: the kept stretches of the speech, one after the other.
  const pieces: AssemblePiece[] = [];
  const words: (ProgramWord & { text: string })[] = [];
  let at = 0;
  let cut = 0;
  for (const file of speech) {
    const d = file.probe.duration ?? 0;
    if (d <= 0) continue;
    const spans =
      brief.cutSilences === false ? [[0, d] as [number, number]] : keptSpans(d, file.cuts ?? []);
    for (const [s, e] of spans) {
      pieces.push({
        media: file.path,
        from: s,
        to: e,
        at: round3(at),
        voice: roleOf.get(file.path) === "voice",
      });
      for (const wd of file.words ?? [])
        if (wd.start >= s - 1e-6 && wd.end <= e + 1e-6)
          words.push({
            text: wd.text,
            start: round3(at + wd.start - s),
            end: round3(at + wd.end - s),
          });
      at += e - s;
    }
    cut += d - spans.reduce((n, [s, e]) => n + e - s, 0);
  }
  // A length asked: the speech ends at the last word before it.
  if (brief.targetSeconds && at > brief.targetSeconds) {
    const limit = brief.targetSeconds;
    const last = words.filter((wd) => wd.end <= limit).at(-1);
    const end = last && last.end > limit - 15 ? Math.min(limit, last.end + 0.15) : limit;
    for (let i = pieces.length - 1; i >= 0; i--) {
      const p = pieces[i] as AssemblePiece;
      if (p.at >= end - 0.04) pieces.splice(i, 1);
      else if (p.at + (p.to - p.from) > end) p.to = round3(p.from + end - p.at);
    }
    for (let i = words.length - 1; i >= 0; i--)
      if ((words[i] as ProgramWord).end > end) words.splice(i, 1);
    warnings.push(
      `Ended at ${end.toFixed(1)} s of ${at.toFixed(1)} s to stay within the length asked.`,
    );
    at = end;
  }
  const duration = round3(at);

  const tracks: VideoTrack[] = [
    { id: "V1", kind: "Video", name: brief.names?.a ?? "A", locked: false, hidden: false },
    { id: "V2", kind: "Video", name: brief.names?.b ?? "B", locked: false, hidden: false },
    { id: "A1", kind: "Audio", name: brief.names?.aAudio ?? "A", locked: false, muted: false },
    { id: "A2", kind: "Audio", name: brief.names?.bAudio ?? "B", locked: false, muted: false },
  ];
  const clips: Partial<VideoClip>[] = [];
  let next = 1;
  const id = (p: string) => `${p}${next++}`;
  const probes: Record<string, VideoProbe> = {};
  const refOf = (file: AssembleFile) => {
    const still = file.probe.kind === "image";
    const frames = still
      ? undefined
      : Math.max(1, Math.floor(((file.probe.duration ?? 0) * rate.num) / rate.den + 1e-6));
    probes[file.path] = still ? { frames: null } : { frames: frames ?? 1, audio: file.probe.audio };
    return {
      media: file.path,
      ...(frames && { frames }),
      ...(still && { still: true }),
      audio: file.probe.audio,
    };
  };
  const byPath = new Map(live.map((x) => [x.path, x]));
  let kb = 0;
  /** A B on a video track (its sound on A2, linked and off). */
  const putB = (
    file: AssembleFile,
    track: "V1" | "V2",
    start: number,
    end: number,
    bIn: number,
    fades: boolean,
  ) => {
    const s = f(start);
    const dur = f(end) - s;
    if (dur < 1) return;
    const still = file.probe.kind === "image";
    const link = !still && file.probe.audio ? id("g") : undefined;
    clips.push({
      id: id("c"),
      track,
      start: s,
      sourceRange: { start: still ? 0 : f(bIn), duration: dur },
      ref: refOf(file),
      ...(link && { link }),
      enabled: true,
      fadeIn: fades ? Math.min(fade, Math.floor(dur / 2)) : 0,
      fadeOut: fades ? Math.min(fade, Math.floor(dur / 2)) : 0,
      ...(still && { kenBurns: KB[kb++ % KB.length] }),
    });
    if (link)
      clips.push({
        id: id("c"),
        track: "A2",
        start: s,
        sourceRange: { start: f(bIn), duration: dur },
        ref: refOf(file),
        link,
        enabled: false,
      });
  };

  // V1/A1: the speech, its picture linked to its sound; a voice-over's picture is coverage.
  const catalog: BrollItem[] = coverage.map((c) => ({
    id: c.path,
    still: c.probe.kind === "image",
    duration: c.probe.kind === "image" ? null : (c.probe.duration ?? 0),
    ...(c.parts?.length && { parts: c.parts }),
  }));
  let fill = 0;
  const voiceSpans: [number, number][] = [];
  for (const p of pieces) {
    const file = byPath.get(p.media) as AssembleFile;
    const s = f(p.at);
    const dur = f(p.at + p.to - p.from) - s;
    if (dur < 1) continue;
    const hasPicture = file.probe.kind === "video";
    const hasSound = file.probe.audio;
    const link = hasPicture && hasSound ? id("g") : undefined;
    if (hasPicture)
      clips.push({
        id: id("c"),
        track: "V1",
        start: s,
        sourceRange: { start: f(p.from), duration: dur },
        ref: refOf(file),
        ...(link && { link }),
        enabled: true,
      });
    if (hasSound)
      clips.push({
        id: id("c"),
        track: "A1",
        start: s,
        sourceRange: { start: f(p.from), duration: dur },
        ref: refOf(file),
        ...(link && { link }),
        enabled: true,
      });
    if (!hasPicture) voiceSpans.push([p.at, p.at + p.to - p.from]);
  }
  // A voice-over's picture: the coverage one after the other, as long as the rules allow.
  const fillSpan = (from: number, to: number) => {
    if (!catalog.length) {
      warnings.push(
        `Nothing covers ${from.toFixed(1)}–${to.toFixed(1)} s (no coverage files): black there.`,
      );
      return;
    }
    let t = from;
    let useless = 0;
    while (to - t > 0.04 && useless < catalog.length) {
      const item = catalog[fill++ % catalog.length] as BrollItem;
      const most = item.still ? rules.maxLen : Math.min(rules.maxLen, longestPart(item));
      if (most <= 0.04) {
        useless++;
        continue;
      }
      useless = 0;
      let len = Math.min(to - t, most);
      // A picture stretches over a rest too short for an insert of its own.
      if (item.still && to - t - len < rules.minLen) len = to - t;
      putB(byPath.get(item.id) as AssembleFile, "V1", t, t + len, item.parts?.[0]?.[0] ?? 0, true);
      t += len;
    }
  };
  for (const [s, e] of voiceSpans) fillSpan(s, e);
  if (!pieces.length && coverage.length) {
    // Only coverage: one after the other, each up to the longest insert.
    let t = 0;
    for (const item of catalog) {
      const len = item.still ? 4 : Math.min(longestPart(item), rules.maxLen * 2);
      putB(byPath.get(item.id) as AssembleFile, "V1", t, t + len, item.parts?.[0]?.[0] ?? 0, true);
      t += len;
    }
  }

  // V2: the inserts over the speech, spread evenly or where the agent said, then made to keep the rules.
  const speaking = pieces.filter((p) => !p.voice);
  const speakingSeconds = speaking.reduce((n, p) => n + p.to - p.from, 0);
  let asked: BrollInsert[];
  if (brief.inserts?.length)
    asked = brief.inserts.map((i) => ({
      b: i.media,
      start: i.start,
      end: i.end,
      bIn: i.in ?? 0,
      ...(i.reason && { reason: i.reason }),
    }));
  else {
    asked = [];
    const n = Math.min(
      brollTargetCount(rules, speakingSeconds),
      brollAllowsReuse(rules, speakingSeconds, catalog.length)
        ? Number.POSITIVE_INFINITY
        : catalog.length,
    );
    const free = Math.max(0, duration - rules.introHold);
    if (n > 0 && catalog.length && free > rules.minLen) {
      const step = free / n;
      const avg = (rules.minLen + rules.maxLen) / 2;
      for (let k = 0; k < n; k++) {
        const item = catalog[k % catalog.length] as BrollItem;
        const len = Math.min(avg, longestPart(item), step - rules.minGap);
        const mid = rules.introHold + step * (k + 0.5);
        const start = Math.max(rules.introHold, mid - len / 2);
        asked.push({
          b: item.id,
          start: round3(start),
          end: round3(start + Math.max(len, rules.minLen)),
          bIn: item.parts?.[0]?.[0] ?? 0,
        });
      }
    }
  }
  // Over a voice-over the picture is coverage already: no insert there.
  const overVoice = (i: BrollInsert) => voiceSpans.some(([s, e]) => i.start < e && i.end > s);
  const repaired = repairInserts(
    rules,
    catalog,
    words,
    duration,
    asked.filter((i) => !overVoice(i)),
  );
  for (const i of asked.filter(overVoice))
    repaired.actions.push({
      code: "dropped_voice",
      message: `dropped B ${i.b} (${i.start.toFixed(1)}–${i.end.toFixed(1)} s): it falls on a voice-over, already covered`,
    });
  for (const ins of repaired.inserts)
    putB(byPath.get(ins.b) as AssembleFile, "V2", ins.start, ins.end, ins.bIn, true);

  // A3: the music under everything, again and again if it is short, ducked under the voice.
  if (musicFile && duration > 0 && (musicFile.probe.duration ?? 0) > 0.5) {
    tracks.push({
      id: "A3",
      kind: "Audio",
      name: brief.names?.music ?? "Music",
      locked: false,
      muted: false,
      duck: { under: ["A1"], amountDb: -12, attackMs: 200, releaseMs: 600 },
    });
    const len = f(musicFile.probe.duration ?? 0);
    const total = f(duration);
    for (let s = 0; s < total; s += len) {
      const dur = Math.min(len, total - s);
      if (dur < 1) break;
      clips.push({
        id: id("c"),
        track: "A3",
        start: s,
        sourceRange: { start: 0, duration: dur },
        ref: refOf(musicFile),
        enabled: true,
        volume: brief.musicDb ?? -8,
        fadeIn: s === 0 ? Math.min(f(1), Math.floor(dur / 2)) : 0,
        fadeOut: s + dur >= total ? Math.min(f(2), Math.floor(dur / 2)) : 0,
      });
    }
  }

  const base = newRgVideo(format, brief.name);
  const doc = cleanTimeline(
    {
      ...base,
      tracks,
      clips,
      assembled: { at: brief.at, ...(brief.text && { brief: brief.text.slice(0, 4000) }) },
    },
    probes,
  );
  return {
    doc,
    report: {
      order: speech.map((x) => x.path),
      coverage: coverage.map((x) => x.path),
      ...(musicFile && { music: musicFile.path }),
      skipped,
      pieces,
      seconds: duration,
      cut: round3(cut),
      inserts: repaired.inserts,
      actions: repaired.actions,
      warnings,
      words,
    },
  };
}

/** The inserts a timeline has on V2 and above (seconds), for the rules' warnings on a montage. */
export function timelineInserts(doc: Pick<RgVideo, "format" | "clips" | "tracks">): BrollInsert[] {
  const r = doc.format.rate;
  const s = (fr: number) => round3((fr * r.den) / r.num);
  const over = new Set(
    doc.tracks.filter((t) => t.kind === "Video" && t.id !== "V1" && !t.hidden).map((t) => t.id),
  );
  return doc.clips
    .filter((c) => c.enabled && over.has(c.track) && "media" in c.ref)
    .map((c) => ({
      b: (c.ref as { media: string }).media,
      start: s(c.start),
      end: s(c.start + c.sourceRange.duration),
      bIn: s(c.sourceRange.start),
    }))
    .sort((a, b) => a.start - b.start);
}
