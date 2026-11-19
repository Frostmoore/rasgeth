// An agent's timeline operations in plain words (G41.2, canvas_edit): place, append, move, trim,
// blade, delete, duplicate, link, properties, tracks, markers, transitions, texts, subtitles and
// the format. Each runs the protocol's pure edit (video-timeline.ts) on the timeline the one
// before left, and becomes the family's actions through `diffTimeline`: one action per
// operation, tagged with its edit, so the panel says what each did.
import {
  addCaption,
  addGenerator,
  addMarker,
  addTrack,
  addTransition,
  appendClip,
  applyVideoAction,
  bladeAt,
  clipEnd,
  clipOf,
  closeGap,
  copyClips,
  diffTimeline,
  isLocked,
  kenBurnsPreset,
  lanes,
  liftClips,
  linkClips,
  moveClips,
  parseTime,
  pasteClips,
  placeClip,
  type RgVideo,
  removeCaptions,
  removeMarker,
  removeTrack,
  removeTransition,
  rippleDeleteClips,
  setCaption,
  setCaptionSettings,
  setClipProps,
  setFormat,
  setGenerator,
  setMarker,
  setNormalize,
  setTrack,
  setTransition,
  trackOf,
  trimClip,
  unlinkClips,
  VIDEO_MARKER_COLORS,
  VIDEO_TEXT_POSITIONS,
  VIDEO_TEXT_STYLES,
  VIDEO_TRANSITIONS,
  type VideoAction,
  type VideoClipProps,
  type VideoEdit,
  type VideoFormat,
  type VideoKenBurns,
  type VideoMediaRef,
  type VideoRate,
  type VideoRect,
} from "@redgiant/protocol";

export const VIDEO_CATALOG = `Video timelines (.rgvideo, tracks as in DaVinci Resolve): canvas_edit "ops", applied in order, each on what the one before left. canvas_look view "structure" lists the tracks (V1 V2… video, the higher on top; A1 A2… audio), the clips with their ids, times, files and links, the gaps, transitions, markers and subtitles. Times: a number is frames at the timeline's rate; a string is seconds ("4s", "2.5s") or a timecode "HH:MM:SS:FF"; "-2s" goes back. Where clips land they overwrite what is there (as Resolve's overwrite); locked tracks are never touched; clips linked (a file's video and audio) move, trim and delete together unless "linked": false. Files are paths in the project; pictures (jpg, png, webp…) have no length of their own.
- {"op":"place","media":"riprese/intervista.mp4","in":"2s","out":"14s","at":"00:00:10:00","mode":"overwrite|insert","video":"V1","audio":"A1"}: a part of a file at a time; its audio on "audio" (null for none, "audio_on": false to keep it silent), linked to the video. "insert" opens the space (everything after moves on every track). "file_length": the file's length (its trims then stop there); "sound": false for a file without audio. A picture: "length" instead of in/out (5 s by default), Ken Burns zoom in by default ("ken_burns": null for none).
- {"op":"append","media":"…","in":…,"out":…}: the same, after the last clip of its tracks.
- {"op":"move","clips":["c4"],"by":"2s","tracks":1} or "to":"00:00:20:00" (where the first clip starts) or "track":"V2": a video goes to another video track, its linked audio stays on its own.
- {"op":"trim","clip":"c4","edge":"in|out","by":"-12f"} or "to": where that edge goes. Never over the neighbour nor out of the file; "ripple": true moves what follows instead (closes or opens the space).
- {"op":"blade","at":"00:00:12:00"} cuts every unlocked track there; "clips":[…] only those (and their linked).
- {"op":"lift","clips":[…]} removes, leaving the gap; {"op":"ripple_delete","clips":[…]} removes and closes the gap; {"op":"close_gap","track":"V1","at":…} closes the gap there.
- {"op":"duplicate","clips":[…],"at":…}: copies at a time, on the same tracks.
- {"op":"link","clips":["c4","c5"]} / {"op":"unlink","clips":["c4"]}.
- {"op":"set","clips":[…],"enabled":false,"volume":-6,"fade_in":"12f","fade_out":"1s","ken_burns":"in_right","fit":"fill|fit","background":"black|blur","crop":{"x":0.3,"y":0,"w":0.32,"h":1},"name":"…"}: volume in dB (−60..+12, audio), fades on the picture for video clips and on the sound for audio clips (at most half the clip), Ken Burns "in|out" + "_left|_right|_up|_down" or {"from":{x,y,w,h},"to":{…}} (parts of the picture, 0..1) or null; crop: the part kept (a horizontal shot reframed for 9:16).
- {"op":"add_track","kind":"Video|Audio","name":"Musica"} / {"op":"remove_track","track":"V3"} (an empty one; V1 and A1 stay) / {"op":"set_track","track":"A2","name":"…","locked":true,"hidden":true (video),"muted":true (audio),"duck":{"under":["A1"],"amount_db":-12} (music lowered under the voice) or null}.
- {"op":"add_transition","from":"c4","kind":"dissolve","length":"1s"}: at the cut after clip c4 (the next clip on its track must start where it ends). Kinds: ${VIDEO_TRANSITIONS.join(", ")}. {"op":"set_transition","id":"t1","kind":…,"length":…} / {"op":"remove_transition","id":"t1"}.
- {"op":"add_text","text":"Titolo","at":"0s","length":"4s","style":"${VIDEO_TEXT_STYLES.join("|")}","position":"${VIDEO_TEXT_POSITIONS.join("|")}","track":"V3","fade":"12f"}: a title clip on a video track (by default the top one if free there, otherwise a new track on top). {"op":"add_color","color":"#000000","at":…,"length":…}. {"op":"set_text","clip":"c9","text":"…"}.
- {"op":"add_marker","at":…,"color":"${VIDEO_MARKER_COLORS.join("|")}","note":"…"} / {"op":"set_marker","id":"m1",…} / {"op":"remove_marker","id":"m1"}.
- {"op":"captions","language":"it","burn_in":true,"style":"plain|boxed|bold","position":"bottom|top"} / {"op":"add_caption","start":…,"end":…,"text":"…"} / {"op":"set_caption","id":"s3","text":"…"} / {"op":"remove_captions","ids":["s3"]}.
- {"op":"format","aspect":"16:9|9:16|1:1|free","width":1920,"height":1080,"rate":"30000/1001","name":"Gita","normalize":true}: a shape alone takes its usual size; another rate retimes every clip; "normalize" brings the finished sound to −14 LUFS (on unless false).`;

type Plain = Record<string, unknown>;

class Bad extends Error {}
const bad = (why: string): never => {
  throw new Bad(why);
};

const STILL = /\.(jpe?g|png|webp|gif|bmp|tiff?|heic|heif|avif|svg)$/i;

const strOf = (v: unknown, what: string): string =>
  typeof v === "string" && v.trim() ? v.trim() : bad(`give ${what}`);

const boolOf = (v: unknown, what: string): boolean | undefined =>
  v === undefined ? undefined : typeof v === "boolean" ? v : bad(`"${what}" is true or false`);

const numOf = (v: unknown, what: string): number => {
  const n = typeof v === "string" && v.trim() ? Number(v) : v;
  return typeof n === "number" && Number.isFinite(n) ? n : bad(`"${what}" must be a number`);
};

const pick = <T extends string>(v: unknown, list: readonly T[], what: string): T => {
  const s = typeof v === "string" ? v.trim() : "";
  const hit = list.find((x) => x.toLowerCase() === s.toLowerCase());
  return hit ?? bad(`"${what}" is one of ${list.join(", ")}`);
};

/** A time in frames (see the catalog). */
function time(doc: RgVideo, v: unknown, what: string): number {
  if (v === undefined || v === null || v === "") return bad(`give "${what}"`);
  const f = parseTime(v, doc.format.rate);
  return f === undefined
    ? bad(
        `"${what}" is not a time I can read (${JSON.stringify(v)}): frames, "4s" or "00:00:04:00"`,
      )
    : f;
}
const optTime = (doc: RgVideo, v: unknown, what: string) =>
  v === undefined || v === null ? undefined : time(doc, v, what);

function clipsOf(doc: RgVideo, o: Plain): string[] {
  const raw = o.clips ?? o.clip ?? o.ids ?? o.id;
  const list = Array.isArray(raw) ? raw : raw === undefined ? [] : [raw];
  if (!list.length) return bad('give "clips"');
  return list.map((x) => {
    const id = String(x);
    if (!clipOf(doc, id)) bad(`there is no clip «${id}» (canvas_look view "structure" lists them)`);
    return id;
  });
}

function trackIdOf(doc: RgVideo, v: unknown, what = "track"): string {
  const id = strOf(v, `"${what}"`).toUpperCase();
  return trackOf(doc, id) ? id : bad(`there is no track ${id}`);
}

/** A destination track, or none (null). */
function targetOf(doc: RgVideo, v: unknown, def: string): string | null {
  if (v === null || v === false) return null;
  return v === undefined ? def : trackIdOf(doc, v);
}

function lockedHint(doc: RgVideo, tracks: readonly (string | undefined | null)[]): string {
  const locked = [...new Set(tracks.filter((t): t is string => !!t && isLocked(doc, t)))];
  return locked.length ? ` (track ${locked.join(", ")} is locked)` : "";
}

function kenBurnsOf(v: unknown): VideoKenBurns | null | undefined {
  if (v === undefined) return undefined;
  if (v === null || v === false || v === "none") return null;
  if (typeof v === "string") {
    const m = /^(in|out)[_ -]?(left|right|up|down)$/i.exec(v.trim());
    if (!m) return bad('"ken_burns" is in_left, in_right, in_up, in_down, out_… or {from, to}');
    return kenBurnsPreset(
      (m[1] as string).toLowerCase() as "in",
      (m[2] as string).toLowerCase() as "left",
    );
  }
  if (v && typeof v === "object") {
    const o = v as Plain;
    return { from: rectOf(o.from, "ken_burns.from"), to: rectOf(o.to, "ken_burns.to") };
  }
  return bad('"ken_burns" is a preset or {from, to}');
}

function rectOf(v: unknown, what: string): VideoRect {
  if (!v || typeof v !== "object") return bad(`"${what}" is {x, y, w, h} (0..1)`);
  const o = v as Plain;
  const r = {
    x: numOf(o.x, `${what}.x`),
    y: numOf(o.y, `${what}.y`),
    w: numOf(o.w, `${what}.w`),
    h: numOf(o.h, `${what}.h`),
  };
  if (r.w <= 0 || r.h <= 0 || r.x < 0 || r.y < 0 || r.x + r.w > 1.000001 || r.y + r.h > 1.000001)
    bad(`"${what}" must stay inside the picture (x, y, w, h between 0 and 1)`);
  return r;
}

function rateOf(v: unknown): VideoRate {
  if (typeof v === "string" && /^\d+\/\d+$/.test(v.trim())) {
    const [num, den] = v.trim().split("/").map(Number) as [number, number];
    if (num > 0 && den > 0) return { num, den };
  }
  const n = numOf(v, "rate");
  if (n <= 0 || n > 1000) bad('"rate" is frames a second (25, 29.97, "30000/1001")');
  for (const k of [24, 30, 48, 60, 120])
    if (Math.abs(n - (k * 1000) / 1001) < 0.01) return { num: k * 1000, den: 1001 };
  return Number.isInteger(n) ? { num: n, den: 1 } : { num: Math.round(n * 1000), den: 1000 };
}

/** A media reference from the op's words. */
function mediaRef(doc: RgVideo, o: Plain): VideoMediaRef {
  const media = strOf(o.media ?? o.file ?? o.path, '"media" (a file of the project)').replace(
    /\\/g,
    "/",
  );
  if (media.startsWith("/") || /^[a-z]:/i.test(media) || media.split("/").includes(".."))
    bad('"media" is a path inside the project');
  const still = boolOf(o.still, "still") ?? STILL.test(media);
  const ref: VideoMediaRef = { media };
  if (still) ref.still = true;
  const len = optTime(doc, o.file_length, "file_length");
  if (len !== undefined && !still) ref.frames = Math.max(1, len);
  if (o.sound === false && !still) ref.audio = false;
  return ref;
}

/** in/out (or length) of a placement. */
function rangeOf(doc: RgVideo, o: Plain, ref: VideoMediaRef): [number, number] {
  const fps = Math.round(doc.format.rate.num / doc.format.rate.den);
  const inF = Math.max(0, optTime(doc, o.in, "in") ?? 0);
  const len = optTime(doc, o.length ?? o.duration, "length");
  let out = optTime(doc, o.out, "out");
  if (out === undefined && len !== undefined) out = inF + len;
  if (out === undefined && ref.still) out = inF + 5 * fps;
  if (out === undefined && ref.frames !== undefined) out = ref.frames;
  if (out === undefined) return bad('give "out" (or "length"): where the part of the file ends');
  if (out <= inF) bad('"out" must come after "in"');
  if (ref.frames !== undefined && out > ref.frames)
    bad(`"out" is past the file's end (${ref.frames} frames)`);
  return [inF, out];
}

function props(doc: RgVideo, o: Plain): VideoClipProps {
  const p: VideoClipProps = {};
  const enabled = boolOf(o.enabled, "enabled");
  if (enabled !== undefined) p.enabled = enabled;
  if (o.volume !== undefined) {
    const v = numOf(o.volume, "volume");
    if (v < -60 || v > 12) bad('"volume" is in dB, from -60 to +12');
    p.volume = v;
  }
  const fi = optTime(doc, o.fade_in, "fade_in");
  if (fi !== undefined) p.fadeIn = Math.max(0, fi);
  const fo = optTime(doc, o.fade_out, "fade_out");
  if (fo !== undefined) p.fadeOut = Math.max(0, fo);
  const kb = kenBurnsOf(o.ken_burns);
  if (kb !== undefined) p.kenBurns = kb;
  if (o.fit !== undefined) p.fit = pick(o.fit, ["fill", "fit"] as const, "fit");
  if (o.background !== undefined)
    p.background =
      o.background === null ? null : pick(o.background, ["black", "blur"] as const, "background");
  if (o.crop !== undefined) p.crop = o.crop === null ? null : rectOf(o.crop, "crop");
  if (o.speed !== undefined) {
    const s = o.speed === null ? null : numOf(o.speed, "speed");
    if (s !== null && (s < 0.1 || s > 10)) bad('"speed" is from 0.1 to 10');
    p.speed = s === 1 ? null : s;
  }
  if (o.name !== undefined) p.name = o.name === null ? null : String(o.name).slice(0, 200);
  if (!Object.keys(p).length)
    bad(
      "say what to change (enabled, volume, fade_in, fade_out, ken_burns, fit, background, crop, name)",
    );
  return p;
}

/** One operation: the edit it is, and the timeline after it. */
function one(doc: RgVideo, o: Plain): [VideoEdit, RgVideo, string] {
  const op = typeof o.op === "string" ? o.op.trim().toLowerCase() : "";
  switch (op) {
    case "place":
    case "append": {
      const ref = mediaRef(doc, o);
      const [inF, out] = rangeOf(doc, o, ref);
      const video = targetOf(doc, o.video, "V1");
      const audio = targetOf(doc, o.audio, "A1");
      const kb = kenBurnsOf(o.ken_burns);
      const opts = {
        targets: { video, audio },
        ...(o.audio_on === false && { audioEnabled: false }),
        ...(o.fade !== undefined && { fade: Math.max(0, time(doc, o.fade, "fade")) }),
        ...(kb !== undefined && { kenBurns: kb }),
        ...(typeof o.name === "string" && { name: o.name.slice(0, 200) }),
      };
      if (op === "append")
        return ["append", appendClip(doc, ref, inF, out, opts), lockedHint(doc, [video, audio])];
      const mode =
        o.mode === undefined ? "overwrite" : pick(o.mode, ["overwrite", "insert"] as const, "mode");
      const at = Math.max(0, time(doc, o.at, "at"));
      return [
        mode,
        placeClip(doc, ref, inF, out, at, { ...opts, mode }),
        lockedHint(doc, [video, audio]),
      ];
    }
    case "move": {
      const ids = clipsOf(doc, o);
      const first = clipOf(doc, ids[0] as string);
      let by = optTime(doc, o.by, "by");
      const to = optTime(doc, o.to, "to");
      if (to !== undefined && first) by = to - first.start;
      let lanesBy = o.tracks === undefined ? 0 : Math.round(numOf(o.tracks, "tracks"));
      if (o.track !== undefined && first) {
        const target = trackIdOf(doc, o.track);
        const kind = trackOf(doc, first.track)?.kind;
        if (trackOf(doc, target)?.kind !== kind)
          bad(`clip ${first.id} goes only to a ${kind?.toLowerCase()} track`);
        const ls = lanes(doc, kind ?? "Video");
        lanesBy = ls.indexOf(target) - ls.indexOf(first.track);
      }
      if (by === undefined && !lanesBy) bad('give "by", "to", "tracks" or "track"');
      const linked = boolOf(o.linked, "linked");
      return [
        "move",
        moveClips(doc, ids, by ?? 0, lanesBy, { ...(linked === false && { linked: false }) }),
        lockedHint(
          doc,
          ids.map((id) => clipOf(doc, id)?.track),
        ),
      ];
    }
    case "trim": {
      const [id] = clipsOf(doc, o) as [string];
      const c = clipOf(doc, id);
      const edge = pick(o.edge ?? "out", ["in", "out"] as const, "edge");
      let by = optTime(doc, o.by, "by");
      const to = optTime(doc, o.to, "to");
      if (to !== undefined && c) by = to - (edge === "in" ? c.start : clipEnd(c));
      if (by === undefined) bad('give "by" or "to"');
      const ripple = boolOf(o.ripple, "ripple") ?? false;
      const linked = boolOf(o.linked, "linked");
      return [
        ripple ? "ripple_trim" : "trim",
        trimClip(doc, id, edge, by ?? 0, { ripple, ...(linked === false && { linked: false }) }),
        ` (a neighbour, the file's end or a locked track stops it)${lockedHint(doc, [c?.track])}`,
      ];
    }
    case "blade":
    case "cut": {
      const at = time(doc, o.at, "at");
      const ids = o.clips || o.clip ? clipsOf(doc, o) : null;
      return ["blade", bladeAt(doc, at, ids), " (no clip crosses that time)"];
    }
    case "lift":
    case "delete": {
      const ids = clipsOf(doc, o);
      const linked = boolOf(o.linked, "linked");
      return [
        "lift",
        liftClips(doc, ids, { ...(linked === false && { linked: false }) }),
        lockedHint(
          doc,
          ids.map((id) => clipOf(doc, id)?.track),
        ),
      ];
    }
    case "ripple_delete": {
      const ids = clipsOf(doc, o);
      const linked = boolOf(o.linked, "linked");
      return [
        "ripple_delete",
        rippleDeleteClips(doc, ids, { ...(linked === false && { linked: false }) }),
        lockedHint(
          doc,
          ids.map((id) => clipOf(doc, id)?.track),
        ),
      ];
    }
    case "close_gap": {
      const track = trackIdOf(doc, o.track);
      return [
        "close_gap",
        closeGap(doc, track, time(doc, o.at, "at")),
        ` (no gap on ${track} there)${lockedHint(doc, [track])}`,
      ];
    }
    case "duplicate":
    case "paste": {
      const ids = clipsOf(doc, o);
      const linked = boolOf(o.linked, "linked");
      const copied = copyClips(doc, ids, { ...(linked === false && { linked: false }) });
      return ["paste", pasteClips(doc, copied, Math.max(0, time(doc, o.at, "at"))), ""];
    }
    case "link":
      return ["link", linkClips(doc, clipsOf(doc, o)), " (give two clips or more)"];
    case "unlink":
      return ["unlink", unlinkClips(doc, clipsOf(doc, o)), " (they are not linked)"];
    case "set": {
      const ids = clipsOf(doc, o);
      return [
        "props",
        setClipProps(doc, ids, props(doc, o)),
        lockedHint(
          doc,
          ids.map((id) => clipOf(doc, id)?.track),
        ),
      ];
    }
    case "add_track": {
      const kind = pick(o.kind ?? "Video", ["Video", "Audio"] as const, "kind");
      return [
        "add_track",
        addTrack(doc, kind, typeof o.name === "string" ? o.name : undefined),
        " (99 tracks at most)",
      ];
    }
    case "remove_track": {
      const t = trackIdOf(doc, o.track);
      return [
        "remove_track",
        removeTrack(doc, t),
        ` (V1 and A1 stay; a track with clips stays: ${t})`,
      ];
    }
    case "set_track": {
      const t = trackIdOf(doc, o.track);
      const p: Parameters<typeof setTrack>[2] = {};
      if (o.name !== undefined) p.name = String(o.name);
      for (const k of ["locked", "hidden", "muted"] as const) {
        const b = boolOf(o[k], k);
        if (b !== undefined) p[k] = b;
      }
      if (o.duck === null) p.duck = null;
      else if (o.duck !== undefined) {
        if (trackOf(doc, t)?.kind !== "Audio") bad("only an audio track ducks");
        const d = o.duck as Plain;
        const under = (Array.isArray(d.under) ? d.under : [d.under]).map((u) =>
          trackIdOf(doc, u, "duck.under"),
        );
        if (under.some((u) => trackOf(doc, u)?.kind !== "Audio" || u === t))
          bad('"duck.under" are other audio tracks (the voice)');
        p.duck = {
          under,
          amountDb:
            d.amount_db === undefined
              ? -12
              : Math.max(-40, Math.min(0, numOf(d.amount_db, "duck.amount_db"))),
          attackMs:
            d.attack_ms === undefined ? 200 : Math.round(numOf(d.attack_ms, "duck.attack_ms")),
          releaseMs:
            d.release_ms === undefined ? 600 : Math.round(numOf(d.release_ms, "duck.release_ms")),
        };
      }
      return ["track", setTrack(doc, t, p), ""];
    }
    case "add_marker": {
      const color = o.color === undefined ? undefined : pick(o.color, VIDEO_MARKER_COLORS, "color");
      const duration = optTime(doc, o.duration, "duration");
      return [
        "marker",
        addMarker(doc, time(doc, o.at, "at"), {
          ...(color && { color }),
          ...(typeof o.note === "string" && { note: o.note }),
          ...(duration !== undefined && { duration }),
        }),
        " (there is a marker on that frame already)",
      ];
    }
    case "set_marker": {
      const id = strOf(o.id, '"id"');
      if (!doc.markers.some((m) => m.id === id)) bad(`there is no marker «${id}»`);
      const frame = optTime(doc, o.at, "at");
      return [
        "marker",
        setMarker(doc, id, {
          ...(frame !== undefined && { frame }),
          ...(o.color !== undefined && { color: pick(o.color, VIDEO_MARKER_COLORS, "color") }),
          ...(typeof o.note === "string" && { note: o.note }),
        }),
        "",
      ];
    }
    case "remove_marker":
      return ["marker", removeMarker(doc, strOf(o.id, '"id"')), " (there is no such marker)"];
    case "add_transition": {
      const [from] = clipsOf(doc, { clips: o.from ?? o.clip }) as [string];
      const kind = pick(o.kind ?? "dissolve", VIDEO_TRANSITIONS, "kind");
      const fps = Math.round(doc.format.rate.num / doc.format.rate.den);
      const len = optTime(doc, o.length, "length") ?? fps;
      return [
        "transition",
        addTransition(doc, from, kind, len),
        ` (the next clip on its track must start where ${from} ends)`,
      ];
    }
    case "set_transition": {
      const id = strOf(o.id, '"id"');
      const len = optTime(doc, o.length, "length");
      return [
        "transition",
        setTransition(doc, id, {
          ...(o.kind !== undefined && { kind: pick(o.kind, VIDEO_TRANSITIONS, "kind") }),
          ...(len !== undefined && {
            inOffset: Math.floor(len / 2),
            outOffset: len - Math.floor(len / 2),
          }),
        }),
        ` (there is no transition «${id}», or its track is locked)`,
      ];
    }
    case "remove_transition":
      return [
        "transition",
        removeTransition(doc, strOf(o.id, '"id"')),
        " (there is no such transition)",
      ];
    case "add_text":
    case "add_color": {
      const fps = Math.round(doc.format.rate.num / doc.format.rate.den);
      const at = Math.max(0, time(doc, o.at, "at"));
      const len = optTime(doc, o.length, "length") ?? 4 * fps;
      const track = o.track === undefined ? undefined : trackIdOf(doc, o.track);
      if (track && trackOf(doc, track)?.kind !== "Video") bad("a text goes on a video track");
      const ref =
        op === "add_text"
          ? {
              generator: "text" as const,
              text: strOf(o.text, '"text"').slice(0, 2000),
              style:
                o.style === undefined
                  ? ("title" as const)
                  : pick(o.style, VIDEO_TEXT_STYLES, "style"),
              position:
                o.position === undefined
                  ? ("center" as const)
                  : pick(o.position, VIDEO_TEXT_POSITIONS, "position"),
            }
          : {
              generator: "color" as const,
              color: /^#[0-9a-f]{6}$/i.test(String(o.color))
                ? String(o.color)
                : bad('"color" is #rrggbb'),
            };
      const fade = optTime(doc, o.fade, "fade");
      return [
        "text",
        addGenerator(doc, ref, at, len, {
          ...(track && { track }),
          ...(fade !== undefined && { fade }),
        }),
        lockedHint(doc, [track]),
      ];
    }
    case "set_text": {
      const [id] = clipsOf(doc, o) as [string];
      return [
        "text",
        setGenerator(doc, id, {
          ...(typeof o.text === "string" && o.text && { text: o.text.slice(0, 2000) }),
          ...(o.style !== undefined && { style: pick(o.style, VIDEO_TEXT_STYLES, "style") }),
          ...(o.position !== undefined && {
            position: pick(o.position, VIDEO_TEXT_POSITIONS, "position"),
          }),
          ...(typeof o.color === "string" && /^#[0-9a-f]{6}$/i.test(o.color) && { color: o.color }),
        }),
        ` (${id} is not a text or a colour, or its track is locked)`,
      ];
    }
    case "captions": {
      const burnIn = boolOf(o.burn_in, "burn_in");
      return [
        "caption",
        setCaptionSettings(doc, {
          ...(typeof o.language === "string" && { language: o.language }),
          ...(burnIn !== undefined && { burnIn }),
          ...(o.style !== undefined && {
            style: pick(o.style, ["plain", "boxed", "bold"] as const, "style"),
          }),
          ...(o.position !== undefined && {
            position: pick(o.position, ["bottom", "top"] as const, "position"),
          }),
        }),
        "",
      ];
    }
    case "add_caption":
      return [
        "caption",
        addCaption(
          doc,
          time(doc, o.start, "start"),
          time(doc, o.end, "end"),
          strOf(o.text, '"text"'),
        ),
        ' ("end" must come after "start")',
      ];
    case "set_caption": {
      const id = strOf(o.id, '"id"');
      if (!doc.captions.segments.some((s) => s.id === id)) bad(`there is no subtitle «${id}»`);
      const start = optTime(doc, o.start, "start");
      const end = optTime(doc, o.end, "end");
      return [
        "caption",
        setCaption(doc, id, {
          ...(start !== undefined && { start }),
          ...(end !== undefined && { end }),
          ...(typeof o.text === "string" && { text: o.text }),
        }),
        "",
      ];
    }
    case "remove_captions": {
      const raw = o.ids ?? o.id;
      const ids = (Array.isArray(raw) ? raw : [raw]).filter((x) => x !== undefined).map(String);
      if (!ids.length) bad('give "ids"');
      return ["caption", removeCaptions(doc, ids), " (there are no such subtitles)"];
    }
    case "format": {
      const p: Partial<VideoFormat> = {};
      if (o.aspect !== undefined)
        p.aspect = pick(o.aspect, ["16:9", "9:16", "1:1", "free"] as const, "aspect");
      if (o.width !== undefined) p.width = Math.round(numOf(o.width, "width"));
      if (o.height !== undefined) p.height = Math.round(numOf(o.height, "height"));
      if (o.rate !== undefined) p.rate = rateOf(o.rate);
      for (const k of ["width", "height"] as const)
        if (p[k] !== undefined && ((p[k] as number) < 16 || (p[k] as number) > 16_384))
          bad(`"${k}" is from 16 to 16384`);
      let after = setFormat(doc, p);
      const normalize = boolOf(o.normalize, "normalize");
      if (normalize !== undefined) after = setNormalize(after, normalize);
      if (typeof o.name === "string") {
        const name = o.name.trim().slice(0, 200);
        if (name !== (doc.name ?? "")) {
          after = after === doc ? structuredClone(doc) : after;
          if (name) after.name = name;
          else delete after.name;
        }
      }
      return ["format", after, ""];
    }
    default:
      return bad(
        op
          ? `there is no operation "${op}" for a video timeline (call with "help": true)`
          : 'give "op"',
      );
  }
}

/** An agent's operations as the family's actions, or why not (the op's index, from 0). */
export function videoFromAgent(
  doc: RgVideo,
  ops: readonly unknown[],
): { actions: VideoAction[] } | { error: string; index?: number } {
  let work = doc;
  const actions: VideoAction[] = [];
  for (let i = 0; i < ops.length; i++) {
    const o = ops[i];
    try {
      if (!o || typeof o !== "object" || Array.isArray(o))
        bad('an operation is an object with "op"');
      const [what, after, why] = one(work, o as Plain);
      const action = after === work ? undefined : diffTimeline(work, after, what);
      if (!action) bad(`it changes nothing${why}`);
      actions.push(action as VideoAction);
      work = applyVideoAction(work, action as VideoAction);
    } catch (err) {
      if (err instanceof Bad) return { error: err.message, index: i };
      return { error: `the operation cannot be done: ${(err as Error).message}`, index: i };
    }
  }
  if (!actions.length) return { error: 'give "ops"' };
  return { actions };
}
