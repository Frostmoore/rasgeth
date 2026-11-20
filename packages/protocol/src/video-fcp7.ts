// A timeline from DaVinci Resolve or Premiere (3.10, video part 2): their FCP7 XML («xmeml»), as
// Resolve exports it with File › Export › Timeline, read into a `.rgvideo` beside the `.otio`
// the 3.9 already opens. What we know: the sequence's rate and size, its video and audio tracks
// (on or off), clip items of files (start, end, in, out; a file named once and then by its id),
// clips off, Time Remap's speed, Basic Motion's scale and centre (keys too) and the audio levels
// (keys too), dissolves between two clips, markers. The rest is left out with a warning (in
// English, for the agent). A small XML reader of our own: no DTD, no entities but the five and
// numeric ones; a file is a few MB at most.
import {
  RGVIDEO_FORMAT_VERSION,
  type RgVideo,
  type VideoBoxKey,
  type VideoClip,
  type VideoMarker,
  type VideoRate,
  type VideoTrack,
  type VideoTransition,
  type VideoVolumeKey,
} from "./doc-video.js";
import type { FromOtioOptions } from "./video-otio.js";
import { cleanTimeline } from "./video-timeline.js";

/** An element of the XML: its tag, attributes, children and text. */
export interface XmlEl {
  tag: string;
  attrs: Record<string, string>;
  kids: XmlEl[];
  text: string;
}

const ENTITIES: Record<string, string> = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'" };
const decode = (s: string) =>
  s.replace(/&(#x[0-9a-f]+|#\d+|amp|lt|gt|quot|apos);/gi, (_, e: string) => {
    if (e[0] === "#")
      return String.fromCodePoint(
        e[1] === "x" || e[1] === "X" ? Number.parseInt(e.slice(2), 16) : Number(e.slice(1)),
      );
    return ENTITIES[e.toLowerCase()] ?? "";
  });

/** The XML's root element; throws on what is not well formed. */
export function parseXml(text: string): XmlEl {
  const root: XmlEl = { tag: "#root", attrs: {}, kids: [], text: "" };
  const stack: XmlEl[] = [root];
  let i = 0;
  const n = text.length;
  while (i < n) {
    const lt = text.indexOf("<", i);
    const chunk = lt < 0 ? text.slice(i) : text.slice(i, lt);
    if (chunk.trim()) (stack[stack.length - 1] as XmlEl).text += decode(chunk);
    if (lt < 0) break;
    if (text.startsWith("<!--", lt)) {
      const e = text.indexOf("-->", lt + 4);
      if (e < 0) throw new Error("a comment is not closed");
      i = e + 3;
      continue;
    }
    if (text.startsWith("<![CDATA[", lt)) {
      const e = text.indexOf("]]>", lt + 9);
      if (e < 0) throw new Error("a CDATA section is not closed");
      (stack[stack.length - 1] as XmlEl).text += text.slice(lt + 9, e);
      i = e + 3;
      continue;
    }
    if (text.startsWith("<?", lt) || text.startsWith("<!", lt)) {
      const e = text.indexOf(">", lt);
      if (e < 0) throw new Error("a declaration is not closed");
      i = e + 1;
      continue;
    }
    const gt = text.indexOf(">", lt);
    if (gt < 0) throw new Error("a tag is not closed");
    const body = text.slice(lt + 1, gt);
    i = gt + 1;
    if (body.startsWith("/")) {
      const tag = body.slice(1).trim();
      const open = stack.pop();
      if (!open || open.tag !== tag)
        throw new Error(`</${tag}> closes <${open?.tag ?? "nothing"}>`);
      continue;
    }
    const self = body.endsWith("/");
    const inner = self ? body.slice(0, -1) : body;
    const m = /^([^\s/>]+)/.exec(inner);
    if (!m) throw new Error("a tag has no name");
    const el: XmlEl = { tag: m[1] as string, attrs: {}, kids: [], text: "" };
    for (const a of inner.slice(m[0].length).matchAll(/([^\s=]+)\s*=\s*("([^"]*)"|'([^']*)')/g))
      el.attrs[a[1] as string] = decode(a[3] ?? a[4] ?? "");
    (stack[stack.length - 1] as XmlEl).kids.push(el);
    if (!self) stack.push(el);
  }
  if (stack.length !== 1)
    throw new Error(`<${(stack[stack.length - 1] as XmlEl).tag}> is not closed`);
  const top = root.kids[0];
  if (!top) throw new Error("it is empty");
  return top;
}

const kid = (e: XmlEl | undefined, tag: string) => e?.kids.find((k) => k.tag === tag);
const kids = (e: XmlEl | undefined, tag: string) => e?.kids.filter((k) => k.tag === tag) ?? [];
const textOf = (e: XmlEl | undefined, tag: string) => kid(e, tag)?.text.trim() ?? "";
const intOf = (e: XmlEl | undefined, tag: string): number | undefined => {
  const v = Number(textOf(e, tag));
  return textOf(e, tag) !== "" && Number.isFinite(v) ? Math.round(v) : undefined;
};
const off = (e: XmlEl | undefined) => textOf(e, "enabled").toUpperCase() === "FALSE";

/** A `<rate>`: timebase and NTSC (29.97 = 30 with ntsc TRUE). */
function rateOf(e: XmlEl | undefined): VideoRate | undefined {
  const r = kid(e, "rate");
  const base = intOf(r, "timebase");
  if (!base || base <= 0) return undefined;
  return textOf(r, "ntsc").toUpperCase() === "TRUE"
    ? { num: base * 1000, den: 1001 }
    : { num: base, den: 1 };
}

/** A filter's parameter: one value, or its keyframes (when, value). */
function paramOf(effect: XmlEl, id: string): { at: number; v: XmlEl }[] {
  const p = kids(effect, "parameter").find(
    (x) => textOf(x, "parameterid").toLowerCase() === id.toLowerCase(),
  );
  if (!p) return [];
  const keys = kids(p, "keyframe");
  if (keys.length)
    return keys.flatMap((k) => {
      const v = kid(k, "value");
      const at = intOf(k, "when");
      return v && at !== undefined ? [{ at, v }] : [];
    });
  const v = kid(p, "value");
  return v ? [{ at: 0, v }] : [];
}

const effectsOf = (item: XmlEl) =>
  kids(item, "filter").flatMap((f) => (kid(f, "effect") ? [kid(f, "effect") as XmlEl] : []));
const effectId = (e: XmlEl) => textOf(e, "effectid").toLowerCase();

/**
 * A timeline from an FCP7 XML's text (Resolve's or Premiere's «xmeml»): its first sequence. Files
 * outside the project (`o.media` undefined) are left out with their clips. Throws when there is
 * no sequence.
 */
export function fromFcp7Xml(
  text: string,
  o: FromOtioOptions,
): { doc: RgVideo; warnings: string[] } {
  const root = parseXml(text);
  if (root.tag !== "xmeml") throw new Error("it is not an FCP7 XML (xmeml)");
  const find = (e: XmlEl): XmlEl | undefined =>
    e.tag === "sequence" ? e : e.kids.map(find).find((x) => x);
  const seq = find(root);
  if (!seq) throw new Error("it holds no sequence");
  const warnings: string[] = [];
  const warn = (w: string) => {
    if (!warnings.includes(w)) warnings.push(w);
  };
  const rate = rateOf(seq) ?? { num: 25, den: 1 };
  const media = kid(seq, "media");
  const sc = kid(kid(kid(kid(media, "video"), "format"), "samplecharacteristics"), "width")
    ? kid(kid(kid(media, "video"), "format"), "samplecharacteristics")
    : undefined;
  const width = intOf(sc, "width") ?? 1920;
  const height = intOf(sc, "height") ?? 1080;
  // Files named once, then by their id.
  const files = new Map<
    string,
    { path?: string; frames?: number; still: boolean; audio: boolean }
  >();
  const fileOf = (item: XmlEl) => {
    const f = kid(item, "file");
    if (!f) return undefined;
    const id = f.attrs.id ?? "";
    const known = id ? files.get(id) : undefined;
    if (known && !kid(f, "pathurl")) return known;
    const url = textOf(f, "pathurl");
    const path = url ? o.media(url) : undefined;
    if (url && !path) warn(`${textOf(f, "name") || url}: not a file of the project, left out`);
    const frames = intOf(f, "duration");
    const fm = kid(f, "media");
    const entry = {
      ...(path && { path }),
      ...(frames && frames > 0 && { frames }),
      still: /\.(jpe?g|png|webp|gif|bmp|tiff?|heic|heif|avif)$/i.test(path ?? url),
      audio: !fm || !!kid(fm, "audio"),
    };
    if (id) files.set(id, entry);
    return entry;
  };

  const tracks: VideoTrack[] = [];
  const clips: VideoClip[] = [];
  const transitions: VideoTransition[] = [];
  let n = 0;
  for (const kind of ["Video", "Audio"] as const) {
    const box = kid(media, kind === "Video" ? "video" : "audio");
    let i = 0;
    for (const t of kids(box, "track")) {
      i++;
      const id = `${kind[0]}${i}`;
      if (i > 99) {
        warn("more than 99 tracks of a kind: the rest left out");
        break;
      }
      tracks.push({
        id,
        kind,
        name: id,
        locked: textOf(t, "locked").toUpperCase() === "TRUE",
        ...(off(t) && (kind === "Video" ? { hidden: true } : { muted: true })),
      });
      let prevEnd = 0;
      let prevId: string | undefined;
      let pendingIn: { id: string; len: number } | undefined;
      for (const item of t.kids) {
        if (item.tag === "transitionitem") {
          const s = intOf(item, "start") ?? 0;
          const e = intOf(item, "end") ?? s;
          const name = textOf(kid(item, "effect"), "name").toLowerCase();
          if (!/dissolve/.test(name))
            warn(`a transition «${name || "?"}»: left out (dissolves only)`);
          else if (prevId) pendingIn = { id: prevId, len: Math.max(2, e - s) };
          continue;
        }
        if (item.tag !== "clipitem") continue;
        const f = fileOf(item);
        let start = intOf(item, "start") ?? -1;
        let end = intOf(item, "end") ?? -1;
        const inF = Math.max(0, intOf(item, "in") ?? 0);
        const outF = intOf(item, "out") ?? inF;
        if (start < 0) start = prevEnd;
        if (end < 0) end = start + Math.max(1, outF - inF);
        if (!f?.path) {
          if (!f)
            warn(
              `«${textOf(item, "name")}»: a clip without a file (a title or a generator), left out`,
            );
          prevEnd = end;
          continue;
        }
        const id2 = `x${++n}`;
        const c: VideoClip = {
          id: id2,
          track: id,
          start,
          sourceRange: { start: f.still ? 0 : inF, duration: Math.max(1, end - start) },
          ref: {
            media: f.path,
            ...(f.frames && !f.still && { frames: f.frames }),
            ...(f.still && { still: true }),
            ...(!f.audio && !f.still && { audio: false }),
          },
          enabled: !off(item),
          volume: 0,
          fadeIn: 0,
          fadeOut: 0,
          fit: "fill",
        };
        for (const e of effectsOf(item)) {
          const eid = effectId(e);
          if (eid === "timeremap") {
            const sp = Number(paramOf(e, "speed")[0]?.v.text ?? "100");
            if (Number.isFinite(sp) && sp > 0 && sp !== 100)
              c.speed = Math.min(10, Math.max(0.1, sp / 100));
          } else if (eid === "basic" && kind === "Video") {
            const sc2 = paramOf(e, "scale");
            const ce = paramOf(e, "center");
            const ats = [...new Set([...sc2.map((k) => k.at), ...ce.map((k) => k.at)])].sort(
              (a, b) => a - b,
            );
            const at = <T>(
              list: { at: number; v: XmlEl }[],
              f2: (v: XmlEl) => T,
              def: T,
              when: number,
            ) => {
              const k = [...list].reverse().find((x) => x.at <= when) ?? list[0];
              return k ? f2(k.v) : def;
            };
            const keys: VideoBoxKey[] = ats.map((w) => ({
              at: w,
              scale: Math.min(4, Math.max(0.05, at(sc2, (v) => Number(v.text) / 100, 1, w) || 1)),
              x: Math.min(
                1,
                Math.max(0, 0.5 + at(ce, (v) => Number(textOf(v, "horiz")) || 0, 0, w)),
              ),
              y: Math.min(
                1,
                Math.max(0, 0.5 + at(ce, (v) => Number(textOf(v, "vert")) || 0, 0, w)),
              ),
            }));
            const full = (k: VideoBoxKey) => k.scale === 1 && k.x === 0.5 && k.y === 0.5;
            if (keys.length === 1 && !full(keys[0] as VideoBoxKey)) {
              const { at: _a, ...b } = keys[0] as VideoBoxKey;
              c.box = b;
            } else if (keys.length > 1) c.boxKeys = keys;
          } else if (eid === "audiolevels" && kind === "Audio") {
            const lv = paramOf(e, "level");
            const db = (v: XmlEl) => {
              const g = Number(v.text);
              return g > 0 ? Math.max(-60, Math.min(12, 20 * Math.log10(g))) : -60;
            };
            if (lv.length === 1) c.volume = Math.round(db((lv[0] as { v: XmlEl }).v) * 10) / 10;
            else if (lv.length > 1)
              c.volumeKeys = lv.map(
                (k): VideoVolumeKey => ({ at: k.at, db: Math.round(db(k.v) * 10) / 10 }),
              );
          } else if (eid) warn(`the effect «${textOf(e, "name") || eid}»: left out`);
        }
        if (pendingIn) {
          transitions.push({
            id: `t${transitions.length + 1}`,
            track: id,
            from: pendingIn.id,
            to: id2,
            kind: "dissolve",
            inOffset: Math.floor(pendingIn.len / 2),
            outOffset: Math.ceil(pendingIn.len / 2),
          });
          pendingIn = undefined;
        }
        clips.push(c);
        prevEnd = end;
        prevId = id2;
      }
    }
  }
  const markers: VideoMarker[] = kids(seq, "marker").map((m, k) => ({
    id: `m${k + 1}`,
    frame: Math.max(0, intOf(m, "in") ?? 0),
    color: "BLUE",
    note: [textOf(m, "name"), textOf(m, "comment")].filter(Boolean).join(" — ").slice(0, 500),
  }));
  if (!tracks.some((t) => t.id === "V1"))
    tracks.unshift({ id: "V1", kind: "Video", name: "V1", locked: false });
  if (!tracks.some((t) => t.id === "A1"))
    tracks.push({ id: "A1", kind: "Audio", name: "A1", locked: false });
  const doc = cleanTimeline({
    formatVersion: RGVIDEO_FORMAT_VERSION,
    name: textOf(seq, "name") || undefined,
    format: {
      width,
      height,
      rate,
      aspect:
        width * 9 === height * 16
          ? "16:9"
          : width * 16 === height * 9
            ? "9:16"
            : width === height
              ? "1:1"
              : "free",
    },
    tracks,
    clips,
    transitions,
    markers,
    captions: { burnIn: false, style: "boxed", position: "bottom", segments: [] },
  });
  return { doc, warnings };
}
