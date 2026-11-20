// Video timelines in the editor (G41.2): the `video` family and its `.rgvideo` file. The document
// is a timeline with tracks, shaped like montatore's (absolute positions in frames: moving a clip
// never touches the others, and conflicts are found on ids), with OpenTimelineIO's names and
// units, so an `.otio` export is a direct translation of the subset we use: tracks of kind
// "Video" or "Audio", clips with a `sourceRange` {start, duration} and a media or generator
// reference, transitions between two adjacent clips, markers with OTIO's colours. Captions are not
// in OTIO (they go in its metadata and an SRT beside it). Proxies, thumbnails, strips and
// waveforms are derived caches, outside the document.
//
// The family's operations are small JSON actions that set one entity (a clip, a track, a
// transition, a marker, a caption) by its id, or one of the timeline's settings; the timeline's
// edits (move, trim, blade… in video-timeline.ts) are pure functions whose result becomes those
// actions (`diffTimeline` in video-patch.ts), on the server for the agents and in the page for
// the person: one implementation.
import { z } from "zod";

/** The `.rgvideo` format this RedGiant writes; older ones are upgraded when read. */
export const RGVIDEO_FORMAT_VERSION = 1;
export const VIDEO_ENGINE = "rgvideo";
export const VIDEO_ENGINE_VERSION = "1";
export const RGVIDEO_EXT = ".rgvideo";

/** The longest timeline: 24 hours at 1000 frames a second. */
export const MAX_VIDEO_FRAMES = 86_400_000;

const Id = z
  .string()
  .min(1)
  .max(80)
  .regex(/^[A-Za-z0-9_.:-]+$/, "letters, digits and _ . : - only");
/** V1…V99, A1…A99: the letter says the kind. */
export const VideoTrackId = z.string().regex(/^[VA][1-9]\d?$/, "a track is V1…V99 or A1…A99");
const Frame = z.number().int().min(0).max(MAX_VIDEO_FRAMES);
const Length = z.number().int().min(1).max(MAX_VIDEO_FRAMES);
const Unit = z.number().min(0).max(1);
const Meta = z.record(z.string().max(200), z.unknown());

/** A frame rate as a fraction: 29.97 is 30000/1001, as in montatore and OTIO's rational time. */
export const VideoRate = z.object({
  num: z.number().int().min(1).max(1_000_000),
  den: z.number().int().min(1).max(1_000_000),
});
export type VideoRate = z.infer<typeof VideoRate>;

export const VIDEO_ASPECTS = ["16:9", "9:16", "1:1", "free"] as const;
export const VideoAspect = z.enum(VIDEO_ASPECTS);
export type VideoAspect = z.infer<typeof VideoAspect>;

export const VideoFormat = z.object({
  width: z.number().int().min(16).max(16_384),
  height: z.number().int().min(16).max(16_384),
  rate: VideoRate,
  /** Horizontal, vertical (9:16), square, or what width and height make. */
  aspect: VideoAspect,
});
export type VideoFormat = z.infer<typeof VideoFormat>;

/** A rectangle of the picture, normalized (0..1 of the width and the height). */
export const VideoRect = z.object({ x: Unit, y: Unit, w: Unit, h: Unit });
export type VideoRect = z.infer<typeof VideoRect>;

/** Music under the voice (G41.3): this audio track goes down while the `under` tracks speak. */
export const VideoDuck = z.object({
  under: z.array(VideoTrackId).min(1).max(20),
  amountDb: z.number().min(-40).max(0).default(-12),
  attackMs: z.number().int().min(0).max(5000).default(200),
  releaseMs: z.number().int().min(0).max(10_000).default(600),
});
export type VideoDuck = z.infer<typeof VideoDuck>;

export const VideoTrackKind = z.enum(["Video", "Audio"]);
export type VideoTrackKind = z.infer<typeof VideoTrackKind>;

export const VideoTrack = z.object({
  id: VideoTrackId,
  /** OTIO's track kinds; the id's letter matches it. */
  kind: VideoTrackKind,
  name: z.string().max(60),
  locked: z.boolean().default(false),
  /** A video track left out of the picture. */
  hidden: z.boolean().optional(),
  /** An audio track left out of the sound. */
  muted: z.boolean().optional(),
  duck: VideoDuck.optional(),
});
export type VideoTrack = z.infer<typeof VideoTrack>;

/**
 * A file of the project (OTIO's ExternalReference). `frames` is the file's length at the
 * timeline's rate when known (OTIO's available range; absent: no limit is checked yet), `still`
 * a picture (no length, never a base under the others), `audio` false for a file without sound.
 */
export const VideoMediaRef = z.object({
  media: z.string().min(1).max(4000),
  frames: Length.optional(),
  still: z.boolean().optional(),
  audio: z.boolean().optional(),
});
export type VideoMediaRef = z.infer<typeof VideoMediaRef>;

export const VIDEO_TEXT_STYLES = ["title", "subtitle", "lower_third", "caption", "plain"] as const;
export const VIDEO_TEXT_POSITIONS = ["center", "top", "bottom", "lower_third"] as const;

/** A title or a text (OTIO's GeneratorReference): a clip on a video track. */
export const VideoTextRef = z.object({
  generator: z.literal("text"),
  text: z.string().min(1).max(2000),
  style: z.enum(VIDEO_TEXT_STYLES).default("title"),
  position: z.enum(VIDEO_TEXT_POSITIONS).default("center"),
});
export type VideoTextRef = z.infer<typeof VideoTextRef>;

const Colour = z.string().regex(/^#[0-9a-fA-F]{6}$/, "a colour is #rrggbb");

/** A plain colour (a black frame, a background). */
export const VideoColorRef = z.object({ generator: z.literal("color"), color: Colour });
export type VideoColorRef = z.infer<typeof VideoColorRef>;

export const VideoRef = z.union([VideoMediaRef, VideoTextRef, VideoColorRef]);
export type VideoRef = z.infer<typeof VideoRef>;

/** Ken Burns: the part of the picture shown at the clip's start and at its end. */
export const VideoKenBurns = z.object({ from: VideoRect, to: VideoRect });
export type VideoKenBurns = z.infer<typeof VideoKenBurns>;

/**
 * Where a clip's picture sits in the frame (3.10, picture in picture): its centre (0..1 of the
 * width and the height) and its scale (1: the whole frame, 0.3: a box a third wide). Absent: the
 * whole frame, as before. Resolve's «Basic Motion» (centre and scale) says the same.
 */
export const VideoBox = z.object({
  x: Unit,
  y: Unit,
  scale: z.number().min(0.05).max(4),
});
export type VideoBox = z.infer<typeof VideoBox>;
/** A box at a frame of the clip (from its first frame): the picture moves linearly between keys. */
export const VideoBoxKey = VideoBox.extend({ at: Frame });
export type VideoBoxKey = z.infer<typeof VideoBoxKey>;
/** A volume (dB) at a frame of the clip: the sound goes linearly between keys. */
export const VideoVolumeKey = z.object({ at: Frame, db: z.number().min(-60).max(12) });
export type VideoVolumeKey = z.infer<typeof VideoVolumeKey>;
/**
 * A simple colour correction (3.10): exposure in stops, contrast, saturation and temperature from
 * −1 to 1 (0: as shot; −1 saturation: black and white; temperature −1 cold, 1 warm).
 */
export const VideoColor = z.object({
  exposure: z.number().min(-3).max(3).default(0),
  contrast: z.number().min(-1).max(1).default(0),
  saturation: z.number().min(-1).max(1).default(0),
  temperature: z.number().min(-1).max(1).default(0),
});
export type VideoColor = z.infer<typeof VideoColor>;
/** The longest list of keys on one clip. */
export const VIDEO_KEYS_MAX = 200;

export const VideoClip = z.object({
  id: Id,
  track: VideoTrackId,
  /** Its first frame in the timeline: absolute. */
  start: Frame,
  /** The part of the source it plays, in frames at the timeline's rate (OTIO's source_range). */
  sourceRange: z.object({ start: Frame, duration: Length }),
  ref: VideoRef,
  name: z.string().max(200).optional(),
  /** Its audio/video group: clips with the same link move, trim and delete together. */
  link: Id.optional(),
  /** Off: kept in the timeline, not played (montatore's «attiva»). */
  enabled: z.boolean().default(true),
  /** dB, on an audio clip. */
  volume: z.number().min(-60).max(12).default(0),
  /** Frames: the picture from and to black on a video track, the sound on an audio track. */
  fadeIn: Frame.default(0),
  fadeOut: Frame.default(0),
  kenBurns: VideoKenBurns.optional(),
  /** Fill the frame (cropped at the centre) or fit inside it. */
  fit: z.enum(["fill", "fit"]).default("fill"),
  /** What shows around a fitted picture (A1: a blurred copy of itself). */
  background: z.enum(["black", "blur"]).optional(),
  /** The part of the picture kept (A1: a horizontal shot reframed for 9:16, movable). */
  crop: VideoRect.optional(),
  /** Speed (A3, 3.10): 0.5 slower, 2 faster; the source range is what plays. */
  speed: z.number().min(0.1).max(10).optional(),
  /** A still of the source's first frame for the whole clip (3.10, «fermo immagine»). */
  freeze: z.boolean().optional(),
  /** Where the picture sits (3.10, picture in picture); with `boxKeys` it moves. */
  box: VideoBox.optional(),
  boxKeys: z.array(VideoBoxKey).max(VIDEO_KEYS_MAX).optional(),
  /** The volume over time (3.10): with keys `volume` is not used. */
  volumeKeys: z.array(VideoVolumeKey).max(VIDEO_KEYS_MAX).optional(),
  color: VideoColor.optional(),
  /** A `.cube` LUT of the project, applied after the colour correction (3.10). */
  lut: z.string().min(1).max(4000).optional(),
  metadata: Meta.optional(),
});
export type VideoClip = z.infer<typeof VideoClip>;

export const VIDEO_TRANSITIONS = [
  "dissolve",
  "dip_to_black",
  "wipe_left",
  "wipe_right",
  "wipe_up",
  "wipe_down",
  "slide_left",
  "slide_right",
  "slide_up",
  "slide_down",
] as const;
export const VideoTransitionKind = z.enum(VIDEO_TRANSITIONS);
export type VideoTransitionKind = z.infer<typeof VideoTransitionKind>;

/**
 * Between two adjacent clips of one track (OTIO's Transition, SMPTE_Dissolve for the dissolve):
 * `inOffset` frames before the cut (into `from`), `outOffset` after it (into `to`).
 */
export const VideoTransition = z.object({
  id: Id,
  track: VideoTrackId,
  from: Id,
  to: Id,
  kind: VideoTransitionKind,
  inOffset: Frame,
  outOffset: Frame,
});
export type VideoTransition = z.infer<typeof VideoTransition>;

/** OTIO's MarkerColor names. */
export const VIDEO_MARKER_COLORS = [
  "PINK",
  "RED",
  "ORANGE",
  "YELLOW",
  "GREEN",
  "CYAN",
  "BLUE",
  "PURPLE",
  "MAGENTA",
  "BLACK",
  "WHITE",
] as const;
export const VideoMarkerColor = z.enum(VIDEO_MARKER_COLORS);
export type VideoMarkerColor = z.infer<typeof VideoMarkerColor>;

export const VideoMarker = z.object({
  id: Id,
  frame: Frame,
  duration: Frame.optional(),
  color: VideoMarkerColor.default("BLUE"),
  note: z.string().max(500).default(""),
});
export type VideoMarker = z.infer<typeof VideoMarker>;

export const VideoCaptionWord = z.object({ start: Frame, end: Frame, text: z.string().max(200) });
export type VideoCaptionWord = z.infer<typeof VideoCaptionWord>;

/** One subtitle, in timeline frames. */
export const VideoCaption = z.object({
  id: Id,
  start: Frame,
  end: Frame,
  text: z.string().max(2000),
  /** The words with their times (G41.4), for cutting the speech from the text. */
  words: z.array(VideoCaptionWord).max(500).optional(),
});
export type VideoCaption = z.infer<typeof VideoCaption>;

/** The subtitles' settings; the segments are their own entities. */
export const VideoCaptionSettings = z.object({
  /** BCP 47 ("it", "en"), "" when not known. */
  language: z.string().max(20).default(""),
  /** Written into the picture at the render (otherwise only the SRT beside it). */
  burnIn: z.boolean().default(false),
  style: z.enum(["plain", "boxed", "bold"]).default("boxed"),
  position: z.enum(["bottom", "top"]).default("bottom"),
});
export type VideoCaptionSettings = z.infer<typeof VideoCaptionSettings>;

export const VideoCaptions = VideoCaptionSettings.extend({
  segments: z.array(VideoCaption).max(20_000).default([]),
});
export type VideoCaptions = z.infer<typeof VideoCaptions>;

/** A named version (A5): a copy of the timeline kept beside it, one before every re-assembly. */
export const VideoVersionInfo = z.object({
  name: z.string().min(1).max(120),
  /** ISO 8601. */
  at: z.string().max(40),
  /** The timeline it is a version of (its path in the project). */
  of: z.string().max(4000).optional(),
  reason: z.enum(["manual", "before_assemble"]).default("manual"),
});
export type VideoVersionInfo = z.infer<typeof VideoVersionInfo>;

/** A named version as the editor lists it (A5, `POST /api/editor/video/versions`). */
export interface VideoVersionEntry {
  /** Its path in the project (in `<name>.versions/` beside the timeline). */
  path: string;
  name: string;
  /** ISO 8601. */
  at: string;
  reason: VideoVersionInfo["reason"];
  clips: number;
}

/** When the automatic assembly (G41.6) made it, and from what brief. */
export const VideoAssembled = z.object({
  at: z.string().max(40),
  brief: z.string().max(4000).optional(),
});
export type VideoAssembled = z.infer<typeof VideoAssembled>;

export const RgVideo = z.object({
  formatVersion: z.literal(RGVIDEO_FORMAT_VERSION),
  name: z.string().max(200).optional(),
  format: VideoFormat,
  tracks: z.array(VideoTrack).min(2).max(198),
  clips: z.array(VideoClip).max(20_000),
  transitions: z.array(VideoTransition).max(10_000),
  markers: z.array(VideoMarker).max(10_000),
  captions: VideoCaptions,
  assembled: VideoAssembled.optional(),
  /**
   * A2: the finished video's sound brought to −14 LUFS (`loudnorm`, measured then corrected);
   * absent means on, false leaves the mix as it is.
   */
  normalize: z.boolean().optional(),
  /** Set only in a named version's copy (A5). */
  version: VideoVersionInfo.optional(),
  /**
   * The music's beats (3.10), in timeline frames: found in an audio clip's sound, drawn on the
   * ruler and taken by the snapping; `beatsOf` names the clip they came from.
   */
  beats: z.array(Frame).max(20_000).optional(),
  beatsOf: Id.optional(),
  metadata: Meta.optional(),
});
export type RgVideo = z.infer<typeof RgVideo>;

// -------------------------------------------------------------------------------------------
// Operations

/** The timeline's settings an action may set (null removes an optional one). */
export const VIDEO_META_KEYS = [
  "name",
  "format",
  "captions",
  "assembled",
  "normalize",
  "version",
  "beats",
  "beatsOf",
  "metadata",
] as const;
export const VideoMetaKey = z.enum(VIDEO_META_KEYS);
export type VideoMetaKey = z.infer<typeof VideoMetaKey>;

/** The timeline's edits, for the panel's words and the summary. */
export const VIDEO_EDITS = [
  "move",
  "trim",
  "ripple_trim",
  "blade",
  "lift",
  "ripple_delete",
  "close_gap",
  "insert",
  "overwrite",
  "append",
  "paste",
  "link",
  "unlink",
  "props",
  "add_track",
  "remove_track",
  "track",
  "marker",
  "transition",
  "text",
  "caption",
  "format",
  "replace",
  "edit",
  "slip",
  "slide",
  "roll",
  "beats",
  "color",
  "keys",
] as const;
export const VideoEdit = z.enum(VIDEO_EDITS);
export type VideoEdit = z.infer<typeof VideoEdit>;

/** Each sets one entity by its id: `value` null removes it, a value adds or replaces it. */
export const VideoPlainAction = z.discriminatedUnion("t", [
  z.object({ t: z.literal("clip"), id: Id, value: VideoClip.nullable() }),
  z.object({ t: z.literal("track"), id: VideoTrackId, value: VideoTrack.nullable() }),
  z.object({ t: z.literal("transition"), id: Id, value: VideoTransition.nullable() }),
  z.object({ t: z.literal("marker"), id: Id, value: VideoMarker.nullable() }),
  z.object({ t: z.literal("caption"), id: Id, value: VideoCaption.nullable() }),
  /** One of the settings (`captions`: the settings, not the segments). */
  z.object({ t: z.literal("meta"), key: VideoMetaKey, value: z.unknown() }),
  /** The whole file (a change from outside, kept to be undone). */
  z.object({ t: z.literal("doc"), text: z.string().max(60_000_000) }),
]);
export type VideoPlainAction = z.infer<typeof VideoPlainAction>;

export const VideoAction = z.discriminatedUnion("t", [
  ...VideoPlainAction.options,
  z.object({
    t: z.literal("batch"),
    ops: z.array(VideoPlainAction).max(60_000),
    /** The edit they make, for the summary. */
    what: VideoEdit.optional(),
  }),
]);
export type VideoAction = z.infer<typeof VideoAction>;

export const VideoDocOp = z.object({
  family: z.literal("video"),
  engine: z.literal(VIDEO_ENGINE),
  engineVersion: z.string().max(40),
  op: VideoAction,
});
export type VideoDocOp = z.infer<typeof VideoDocOp>;

export const VideoSnapshot = z.object({
  family: z.literal("video"),
  /** The timeline as the host has it now. */
  doc: RgVideo,
});
export type VideoSnapshot = z.infer<typeof VideoSnapshot>;

/** What a timeline's change was, for the panel's words (`DocSummary.video`). */
export const VideoChange = z.object({
  action: VideoEdit,
  /** Entities touched (clips, tracks, markers…). */
  n: z.number().int().nonnegative(),
  /** Clips added and removed. */
  added: z.number().int().nonnegative().optional(),
  removed: z.number().int().nonnegative().optional(),
  /** The one clip (or track, marker…) touched. */
  id: z.string().max(80).optional(),
});
export type VideoChange = z.infer<typeof VideoChange>;
