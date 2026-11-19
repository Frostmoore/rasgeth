// A video timeline as an agent reads it (G41.2, canvas_look view "structure"): the format, the
// tracks from the top, every clip with its id, its times as timecodes and frames, its file or
// text and its links, the gaps between clips, transitions, markers and subtitles.
import {
  clipEnd,
  clipLength,
  fps,
  isMediaRef,
  type RgVideo,
  timecode,
  timelineDuration,
  trackClips,
  type VideoClip,
} from "@redgiant/protocol";

const MAX_LINES = 800;

function clipLine(doc: RgVideo, c: VideoClip): string {
  const r = doc.format.rate;
  const tc = (f: number) => timecode(f, r);
  const what = isMediaRef(c.ref)
    ? `${c.ref.media}${c.ref.still ? " (picture)" : ` from ${tc(c.sourceRange.start)}`}${c.ref.frames ? `, file ${c.ref.frames}f` : ""}${c.ref.audio === false ? ", no sound" : ""}`
    : c.ref.generator === "text"
      ? `text «${c.ref.text.replace(/\s+/g, " ").slice(0, 120)}» (${c.ref.style}, ${c.ref.position})`
      : `colour ${c.ref.color}`;
  const linked = c.link
    ? `, linked ${c.link} (${doc.clips
        .filter((x) => x.link === c.link && x.id !== c.id)
        .map((x) => x.id)
        .join(", ")})`
    : "";
  const extra: string[] = [];
  if (!c.enabled) extra.push("off");
  if (c.volume) extra.push(`volume ${c.volume} dB`);
  if (c.fadeIn) extra.push(`fade in ${c.fadeIn}f`);
  if (c.fadeOut) extra.push(`fade out ${c.fadeOut}f`);
  if (c.kenBurns) extra.push("Ken Burns");
  if (c.fit === "fit") extra.push(`fit${c.background === "blur" ? " on a blurred copy" : ""}`);
  if (c.crop) extra.push("cropped");
  if (c.speed) extra.push(`speed ${c.speed}×`);
  return `  ${c.id} ${tc(c.start)}–${tc(clipEnd(c))} (${clipLength(c)}f) ${c.name ? `«${c.name}» ` : ""}${what}${linked}${extra.length ? ` [${extra.join(", ")}]` : ""}`;
}

export function videoStructure(
  doc: RgVideo,
  ask: { fromLine?: number | undefined; toLine?: number | undefined } = {},
): string {
  const r = doc.format.rate;
  const tc = (f: number) => timecode(f, r);
  const f = doc.format;
  const rate = Number.isInteger(fps(r))
    ? `${fps(r)}`
    : `${fps(r).toFixed(3).replace(/0+$/, "")} (${r.num}/${r.den})`;
  const total = timelineDuration(doc);
  const lines: string[] = [
    `Video timeline${doc.name ? ` «${doc.name}»` : ""} (.rgvideo): ${f.width}×${f.height} (${f.aspect}) at ${rate} fps, ${tc(total)} long (${total} frames). Times are frames at this rate, shown as HH:MM:SS:FF.`,
  ];
  // Video from the top (the higher covers the lower), then audio.
  const video = doc.tracks.filter((t) => t.kind === "Video").reverse();
  const audio = doc.tracks.filter((t) => t.kind === "Audio");
  lines.push("Tracks (the higher video track covers the lower):");
  for (const t of [...video, ...audio]) {
    const n = doc.clips.filter((c) => c.track === t.id).length;
    const flags = [
      t.locked && "locked",
      t.hidden && "hidden",
      t.muted && "muted",
      t.duck && `ducks under ${t.duck.under.join(", ")} by ${t.duck.amountDb} dB`,
    ].filter(Boolean);
    lines.push(
      `- ${t.id}${t.name !== t.id ? ` «${t.name}»` : ""}: ${n === 1 ? "1 clip" : `${n} clips`}${flags.length ? `, ${flags.join(", ")}` : ""}`,
    );
  }
  for (const t of [...video, ...audio]) {
    const clips = trackClips(doc, t.id);
    if (!clips.length) continue;
    lines.push(`${t.id}:`);
    let at = 0;
    for (const c of clips) {
      if (c.start > at) lines.push(`  gap ${tc(at)}–${tc(c.start)} (${c.start - at}f)`);
      lines.push(clipLine(doc, c));
      at = clipEnd(c);
    }
  }
  if (doc.transitions.length) {
    lines.push("Transitions:");
    for (const x of doc.transitions) {
      const to = doc.clips.find((c) => c.id === x.to);
      lines.push(
        `- ${x.id} ${x.kind} on ${x.track} at ${to ? tc(to.start) : "?"} (${x.from} → ${x.to}), ${x.inOffset}f before the cut + ${x.outOffset}f after`,
      );
    }
  }
  if (doc.markers.length) {
    lines.push("Markers:");
    for (const m of doc.markers)
      lines.push(
        `- ${m.id} ${tc(m.frame)}${m.duration ? ` (${m.duration}f)` : ""} ${m.color}${m.note ? ` «${m.note}»` : ""}`,
      );
  }
  const cap = doc.captions;
  if (cap.segments.length || cap.burnIn || cap.language) {
    lines.push(
      `Subtitles (${cap.language || "language not set"}, ${cap.burnIn ? "burned into the picture" : "in an SRT beside it"}, ${cap.style}, ${cap.position}): ${cap.segments.length}`,
    );
    for (const s of cap.segments)
      lines.push(
        `- ${s.id} ${tc(s.start)}–${tc(s.end)} «${s.text.replace(/\s+/g, " ").slice(0, 160)}»${s.words ? ` (${s.words.length} words timed)` : ""}`,
      );
  }
  if (doc.normalize === false)
    lines.push("The sound is rendered as mixed (no −14 LUFS normalization).");
  if (doc.assembled) lines.push(`Assembled automatically on ${doc.assembled.at}.`);
  if (doc.version)
    lines.push(
      `This is the named version «${doc.version.name}» of ${doc.version.of ?? "a timeline"} (${doc.version.at}).`,
    );
  const from = Math.max(1, ask.fromLine ?? 1);
  const to = Math.min(lines.length, ask.toLine ?? lines.length, from + MAX_LINES - 1);
  const shown = lines.slice(from - 1, to);
  if (from > 1 || to < lines.length)
    shown.push(`(lines ${from}-${to} of ${lines.length}: ask with fromLine/toLine for the others)`);
  return shown.join("\n");
}
