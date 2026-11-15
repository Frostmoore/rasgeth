// The mascots' motion (G40.9 follow-up, the user's request: «always alive, with some variety»).
// One table of tracks is the only source: the page turns it into CSS animations
// (`mascotMotionCss`), the app embeds the same JSON (apps/companion/lib/mascot/motion_table.g.dart)
// and plays it on its layers. Only transforms (translate, rotate, scale) and opacity move, around
// the `transform-origin` written on each group of the SVG; nothing is redrawn.
//
// Every mascot has its own rhythm: sixteen numbers in 0..1 from its seed (`--k0`…`--k15` on the
// SVG's root) pick each track's period inside its range and its phase, so two mascots side by side
// never blink, hop or yawn together. The rare events (a hop, waking up with a start, a yawn, a look
// to the side, a head shake) come back at irregular times: the app draws every gap from the
// mascot's own numbers (`rareStarts`), the page repeats five uneven gaps in a long cycle whose
// length and phase differ per mascot. Each mascot also starts a little shifted when it appears
// (`--j` on the page, a random offset in the app), so even twins never move together.

import type { MascotState } from "@redgiant/protocol";

export type MotionProp = "translate" | "rotate" | "scale" | "opacity";
export type MotionEase = "ease-in-out" | "linear" | "ease-out" | "ease-in";
/** translate: [x, y] in the 100x100 box; rotate: degrees; scale: [x, y]; opacity: 0..1. */
export type MotionValue = number | [number, number];

export interface MotionTrack {
  /** The class of the group it moves (each animated group has exactly one such class). */
  el: string;
  prop: MotionProp;
  /** Seconds: fixed, or a [min, max] range picked by the mascot's `k[dk]`. */
  dur: number | [number, number];
  dk?: number;
  /** The phase: the mascot's `k[pk]` plus `phase` (fractions of a cycle). */
  pk?: number;
  phase?: number;
  /** Between every two frames, as CSS `animation-timing-function` (default ease-in-out). */
  ease?: MotionEase;
  /**
   * A rare event: `dur` is its own length and it comes back after `gap[0]..gap[1]` seconds, a
   * different gap every time (`rareStarts`); the tracks of one event share `ev`.
   */
  rare?: { ev: string; gap: [number, number] };
  /** [at 0..1, value], from 0 to 1. */
  frames: [number, MotionValue][];
}

export interface MotionTable {
  v: 1;
  /** Every element moved, in no particular order (the app cuts these out as layers). */
  elements: string[];
  /** The whole body (`core`) and the rare events (`ev`, inside it). */
  states: Record<MascotState, MotionTrack[]>;
  /** 16-20 px: body and eyes only, so only the blink. */
  tiny: MotionTrack[];
}

/** How many rhythm numbers each mascot has. */
export const RHYTHM_SIZE = 16;

const r4 = (n: number) => Math.round(n * 10000) / 10000;
const f = (at: number, v: MotionValue): [number, MotionValue] => [
  r4(at),
  typeof v === "number" ? r4(v) : [r4(v[0]), r4(v[1])],
];
const ONE: [number, number] = [1, 1];
const ZERO: [number, number] = [0, 0];

// ---------- The pieces ----------

/**
 * A rare event: `len` seconds of frames (given in seconds), at rest outside them; it comes back
 * after a gap of `gap[0]..gap[1]` seconds (start to start), a different one every time and per
 * mascot (`rareStarts`). Tracks of one event share its name, gap and phase number.
 */
function rare(
  ev: string,
  gap: [number, number],
  pk: number,
  dk: number,
  len: number,
  base: { el: string; prop: MotionProp; ease?: MotionEase },
  rest: MotionValue,
  frames: [number, MotionValue][],
): MotionTrack {
  return {
    ...base,
    dur: len,
    dk,
    pk,
    rare: { ev, gap },
    frames: [f(0, rest), ...frames.map(([s, v]) => f(s / len, v)), f(1, rest)],
  };
}

const blink = (el: string): MotionTrack => ({
  el,
  prop: "scale",
  dur: [3.4, 6.2],
  dk: 1,
  pk: 2,
  frames: [f(0, ONE), f(0.92, ONE), f(0.95, [1, 0.08]), f(0.98, ONE), f(1, ONE)],
});

// The z's rise from near the head and fade, one after the other (three, a third of a cycle
// apart). Each z is drawn at its resting place (z1 and z2 are the sign without motion, z3 is
// hidden); the frames move each one along the same path, measured from where it is drawn.
const Z_PATH: [number, number, number, number][] = [
  // at, x, y (centre), width; opacity follows below.
  [0, 72.5, 25, 5],
  [0.12, 75.5, 20.5, 6],
  [0.4, 81.5, 13, 7],
  [0.65, 91.5, 5, 5],
  [0.82, 98, -2, 3.8],
  [1, 98, -2, 3.8],
];
const Z_OPACITY: [number, number][] = [
  [0, 0],
  [0.12, 1],
  [0.65, 0.9],
  [0.82, 0],
  [1, 0],
];
/** Where each z is drawn (centre), its width and height: z1 and z3 the sign's big z, z2 the small. */
export const Z_REST: Record<string, [number, number, number, number]> = {
  z1: [81.5, 13, 7, 8],
  z2: [91.5, 5, 5, 6],
  z3: [81.5, 13, 7, 8],
};
function zTracks(): MotionTrack[] {
  const out: MotionTrack[] = [];
  const phases: Record<string, number> = { z1: 0, z2: 2 / 3, z3: 1 / 3 };
  for (const el of ["z1", "z2", "z3"]) {
    const [cx, cy, w] = Z_REST[el] as [number, number, number, number];
    const common = {
      el,
      dur: [4.2, 5.8] as [number, number],
      dk: 3,
      pk: 3,
      phase: r4(phases[el] ?? 0),
      ease: "linear" as const,
    };
    out.push({
      ...common,
      prop: "translate",
      frames: Z_PATH.map(([at, x, y]) => f(at, [x - cx, y - cy])),
    });
    out.push({ ...common, prop: "scale", frames: Z_PATH.map(([at, , , zw]) => f(at, zw / w)) });
    out.push({ ...common, prop: "opacity", frames: Z_OPACITY.map(([at, o]) => f(at, o)) });
  }
  // A scale given as one number is the same on both axes.
  for (const t of out)
    if (t.prop === "scale")
      t.frames = t.frames.map(([at, v]) => [at, typeof v === "number" ? [v, v] : v]);
  return out;
}

// The sleep bubble: it swells slowly with the breath, then pops (a few lines flash).
const bubble = (): MotionTrack[] => {
  const c = { dur: [4.6, 6.4] as [number, number], dk: 4, pk: 5 };
  return [
    {
      el: "bub",
      prop: "scale",
      ...c,
      frames: [
        f(0, [0.2, 0.2]),
        f(0.3, [0.66, 0.6]),
        f(0.45, [0.76, 0.8]),
        f(0.68, [1.15, 1.15]),
        f(0.71, [1.45, 1.45]),
        f(0.72, [0.2, 0.2]),
        f(1, [0.2, 0.2]),
      ],
    },
    {
      el: "bub",
      prop: "opacity",
      ...c,
      frames: [f(0, 0), f(0.08, 0.95), f(0.7, 0.95), f(0.715, 0), f(1, 0)],
    },
    {
      el: "pop",
      prop: "opacity",
      ...c,
      frames: [f(0, 0), f(0.705, 0), f(0.72, 1), f(0.8, 0), f(1, 0)],
    },
    {
      el: "pop",
      prop: "scale",
      ...c,
      frames: [f(0, [0.6, 0.6]), f(0.705, [0.6, 0.6]), f(0.8, [1.5, 1.5]), f(1, [1.5, 1.5])],
    },
  ];
};

// God: the halo breathes, the little planet goes round the orbit (behind the body on the far
// half: two copies trade places), and the crown glints now and then.
const ORBIT = { cx: 50, cy: 56, rx: 43.2, ry: 12.06, tilt: (-14 * Math.PI) / 180 };
const PLANET: [number, number] = [17, 70.5];
function orbitTracks(): MotionTrack[] {
  const { cx, cy, rx, ry, tilt } = ORBIT;
  const cos = Math.cos(tilt);
  const sin = Math.sin(tilt);
  // The planet in the orbit's own frame: its angle and how far in it sits.
  const dx = PLANET[0] - cx;
  const dy = PLANET[1] - cy;
  const ux = (dx * cos + dy * sin) / rx;
  const uy = (-dx * sin + dy * cos) / ry;
  const k = Math.hypot(ux, uy);
  const a0 = Math.atan2(uy, ux);
  const steps = 24;
  const translate: [number, MotionValue][] = [];
  for (let i = 0; i <= steps; i++) {
    const a = a0 + (2 * Math.PI * i) / steps;
    const ex = k * rx * Math.cos(a);
    const ey = k * ry * Math.sin(a);
    const x = cx + ex * cos - ey * sin;
    const y = cy + ex * sin + ey * cos;
    translate.push(f(i / steps, [x - PLANET[0], y - PLANET[1]]));
  }
  // In front while sin(a) > 0: from a0 (in front) to pi, behind until 2 pi, in front again.
  const tBack = (Math.PI - a0) / (2 * Math.PI);
  const tFront = (2 * Math.PI - a0) / (2 * Math.PI);
  const e = 0.004;
  const front: [number, MotionValue][] = [
    f(0, 1),
    f(tBack - e, 1),
    f(tBack + e, 0),
    f(tFront - e, 0),
    f(tFront + e, 1),
    f(1, 1),
  ];
  const back = front.map(([at, v]) => [at, 1 - (v as number)] as [number, MotionValue]);
  const c = { dur: 14, pk: 14, ease: "linear" as const };
  return [
    { el: "orbf", prop: "translate", ...c, frames: translate },
    { el: "orbf", prop: "opacity", ...c, frames: front },
    { el: "orbb", prop: "translate", ...c, frames: translate },
    { el: "orbb", prop: "opacity", ...c, frames: back },
  ];
}
const godTracks = (): MotionTrack[] => {
  const glint = (prop: MotionProp, rest: MotionValue, frames: [number, MotionValue][]) =>
    rare("glint", [4.5, 10], 15, 14, 0.7, { el: "gl", prop }, rest, frames);
  return [
    { el: "hal", prop: "opacity", dur: 5.2, pk: 13, frames: [f(0, 1), f(0.5, 0.45), f(1, 1)] },
    ...orbitTracks(),
    glint(
      "scale",
      [0.1, 0.1],
      [
        [0.25, [1.3, 1.3]],
        [0.6, [0.1, 0.1]],
      ],
    ),
    glint("opacity", 0, [
      [0.2, 1],
      [0.6, 0],
    ]),
    glint("rotate", 0, [[0.6, 90]]),
  ];
};

/** The two eye groups: the drawn eyes and, sleeping, the open ones of waking up. */
const both = (make: (el: string) => MotionTrack[]): MotionTrack[] => [
  ...make("eyes"),
  ...make("eyw"),
];

/** The head's things (antenna, tuft, ears, hat) wiggling: back and front together. */
const wiggle = (ev: string, gap: [number, number], pk: number, dk: number): MotionTrack[] =>
  ["hb", "hf"].map((el) =>
    rare(ev, gap, pk, dk, 1.1, { el, prop: "rotate" }, 0, [
      [0.15, -11],
      [0.35, 9],
      [0.55, -6],
      [0.75, 3],
      [0.95, 0],
    ]),
  );

// ---------- The states ----------

/** A slow sway from side to side (the body leaning, around its feet). */
const sway = (deg: number, dur: [number, number], dk: number, pk: number): MotionTrack => ({
  el: "core",
  prop: "rotate",
  dur,
  dk,
  pk,
  frames: [f(0, 0), f(0.25, -deg), f(0.75, deg), f(1, 0)],
});

function idle(): MotionTrack[] {
  const wake = (
    base: { el: string; prop: MotionProp },
    rest: MotionValue,
    fr: [number, MotionValue][],
  ) => rare("wake", [17, 32], 9, 8, 3, base, rest, fr);
  const yawn = (
    base: { el: string; prop: MotionProp },
    rest: MotionValue,
    fr: [number, MotionValue][],
  ) => rare("yawn", [14, 27], 11, 10, 2.6, base, rest, fr);
  const look = (
    base: { el: string; prop: MotionProp },
    rest: MotionValue,
    fr: [number, MotionValue][],
  ) => rare("look", [19, 34], 13, 12, 3.8, base, rest, fr);
  return [
    // Slow, deep breath, and a slight sway in its sleep.
    {
      el: "core",
      prop: "scale",
      dur: [3.4, 4.4],
      dk: 0,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.035, 1.065]), f(1, ONE)],
    },
    sway(2, [6, 9], 15, 4),
    ...both((el) => [blink(el)]),
    ...zTracks(),
    ...bubble(),
    // Now and then a hop in its sleep, at irregular times.
    rare("hop", [6, 14], 7, 6, 1.3, { el: "ev", prop: "translate" }, ZERO, [
      [0.12, [0, 1.2]],
      [0.36, [0, -11]],
      [0.62, [0, 0.8]],
      [0.78, [0, -3]],
      [0.95, ZERO],
    ]),
    // Wakes up with a start, looks around, falls asleep again.
    wake({ el: "ev", prop: "scale" }, ONE, [
      [0.12, [1.12, 1.16]],
      [0.3, [0.97, 0.96]],
      [0.5, ONE],
    ]),
    wake({ el: "eyes", prop: "opacity" }, 1, [
      [0.1, 0],
      [2.4, 0],
      [2.7, 1],
    ]),
    wake({ el: "eyw", prop: "opacity" }, 0, [
      [0.1, 1],
      [2.4, 1],
      [2.7, 0],
    ]),
    ...both((el) => [
      wake({ el, prop: "translate" }, ZERO, [
        [0.6, ZERO],
        [0.9, [-3.4, 0]],
        [1.5, [-3.4, 0]],
        [1.8, [3.2, 0]],
        [2.3, ZERO],
      ]),
    ]),
    // A yawn: the mouth gives way to a round open one, the antenna wiggles.
    yawn({ el: "mouth", prop: "opacity" }, 1, [
      [0.2, 0],
      [2.2, 0],
      [2.4, 1],
    ]),
    yawn({ el: "yn", prop: "opacity" }, 0, [
      [0.2, 1],
      [2.2, 1],
      [2.4, 0],
    ]),
    yawn(
      { el: "yn", prop: "scale" },
      [1, 0.3],
      [
        [0.9, [1.25, 1.5]],
        [1.8, [1.1, 1.2]],
        [2.3, [1, 0.3]],
      ],
    ),
    ...wiggle("yawn", [14, 27], 11, 10),
    // Looks to the side, tilting its head (and scratches it, when it has hands).
    look({ el: "ev", prop: "rotate" }, 0, [
      [0.4, -6],
      [1.6, -6],
      [2, 6],
      [3, 6],
      [3.4, 0],
    ]),
    look({ el: "hand", prop: "translate" }, ZERO, [
      [2.2, ZERO],
      [2.6, [4, -17]],
      [2.8, [5.5, -18.5]],
      [3, [4, -17]],
      [3.2, [5.5, -18.5]],
      [3.6, ZERO],
    ]),
  ];
}

/** Awake after answering the person: eyes open, it looks around, breathes, sways, now and then a hop. */
function active(): MotionTrack[] {
  const look = (el: string) =>
    rare("glance", [3.2, 6.5], 9, 8, 2.6, { el, prop: "translate" }, ZERO, [
      [0.25, [-3.2, -0.4]],
      [0.9, [-3.2, -0.4]],
      [1.2, [3, -0.6]],
      [1.9, [3, -0.6]],
      [2.3, ZERO],
    ]);
  return [
    {
      el: "core",
      prop: "scale",
      dur: [2.8, 3.6],
      dk: 0,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.03, 1.05]), f(1, ONE)],
    },
    sway(3, [4.5, 7], 15, 4),
    blink("eyes"),
    look("eyes"),
    rare("hop", [7, 15], 7, 6, 0.9, { el: "ev", prop: "translate" }, ZERO, [
      [0.12, [0, 1]],
      [0.4, [0, -8]],
      [0.7, [0, 0.8]],
      [0.85, ZERO],
    ]),
    rare("tilt", [8, 17], 11, 10, 2, { el: "ev", prop: "rotate" }, 0, [
      [0.35, 7],
      [1.3, 7],
      [1.8, 0],
    ]),
    rare("wave", [13, 25], 13, 12, 1.6, { el: "hand", prop: "translate" }, ZERO, [
      [0.2, [-2, -15]],
      [0.45, [2, -17]],
      [0.7, [-2, -15]],
      [0.95, [2, -17]],
      [1.3, ZERO],
    ]),
    ...wiggle("wiggle", [9, 18], 5, 3),
  ];
}

function think(): MotionTrack[] {
  const tilt = (
    base: { el: string; prop: MotionProp },
    rest: MotionValue,
    fr: [number, MotionValue][],
  ) => rare("tilt", [7, 15], 7, 6, 3.2, base, rest, fr);
  return [
    // A slow bob, as if weighing things.
    {
      el: "core",
      prop: "translate",
      dur: [2.5, 3.2],
      dk: 0,
      pk: 0,
      frames: [f(0, ZERO), f(0.5, [0, -2.4]), f(1, ZERO)],
    },
    sway(2.5, [5, 8], 15, 4),
    ...both((el) => [blink(el)]),
    // The dots light up one after the other and rise a little; the cloud's bubbles pulse.
    ...[0, 1, 2].flatMap((i): MotionTrack[] => [
      {
        el: `d${i + 1}`,
        prop: "opacity",
        dur: 1.8,
        pk: 0,
        phase: r4(1 - (i * 0.3) / 1.8),
        frames: [f(0, 0.3), f(0.35, 1), f(1, 0.3)],
      },
      {
        el: `d${i + 1}`,
        prop: "translate",
        dur: 1.8,
        pk: 0,
        phase: r4(1 - (i * 0.3) / 1.8),
        frames: [f(0, ZERO), f(0.35, [0, -2.4]), f(0.7, ZERO), f(1, ZERO)],
      },
    ]),
    ...[0, 1].map(
      (i): MotionTrack => ({
        el: `tc${i + 1}`,
        prop: "opacity",
        dur: 1.8,
        pk: 0,
        phase: r4(0.5 - i * 0.25),
        frames: [f(0, 0.25), f(0.3, 0.85), f(0.6, 0.25), f(1, 0.25)],
      }),
    ),
    // Tilts its head and scratches it.
    tilt({ el: "ev", prop: "rotate" }, 0, [
      [0.7, -8],
      [2.4, -8],
      [3.1, 0],
    ]),
    tilt({ el: "hand", prop: "translate" }, ZERO, [
      [0.6, [4, -17]],
      [0.85, [5.5, -18.5]],
      [1.1, [4, -17]],
      [1.35, [5.5, -18.5]],
      [1.6, [4, -17]],
      [2.2, ZERO],
    ]),
    // Looks to the side, up.
    ...both((el) => [
      rare("up", [8, 17], 9, 8, 3.2, { el, prop: "translate" }, ZERO, [
        [0.5, [3.4, -1]],
        [2.6, [3.4, -1]],
        [3.1, ZERO],
      ]),
    ]),
    // An idea: a small hop.
    rare("idea", [12, 24], 11, 10, 0.9, { el: "ev", prop: "translate" }, ZERO, [
      [0.25, [0, -7]],
      [0.55, [0, 0.6]],
      [0.75, ZERO],
    ]),
    ...wiggle("wiggle", [10, 20], 13, 12),
  ];
}

function work(): MotionTrack[] {
  return [
    // Sways with the effort, the tool goes up and down, sparks fly at the end of each stroke.
    {
      el: "core",
      prop: "rotate",
      dur: [1.4, 1.8],
      dk: 0,
      pk: 0,
      frames: [f(0, 0), f(0.25, -4), f(0.75, 4), f(1, 0)],
    },
    {
      el: "tool",
      prop: "rotate",
      dur: [1.4, 1.8],
      dk: 0,
      pk: 0,
      frames: [f(0, 0), f(0.5, -22), f(1, 0)],
    },
    {
      el: "spk",
      prop: "opacity",
      dur: [1.4, 1.8],
      dk: 0,
      pk: 0,
      frames: [f(0, 0), f(0.44, 0), f(0.5, 1), f(0.64, 0), f(1, 0)],
    },
    {
      el: "spk",
      prop: "scale",
      dur: [1.4, 1.8],
      dk: 0,
      pk: 0,
      frames: [f(0, [0.4, 0.4]), f(0.44, [0.4, 0.4]), f(0.64, [1.4, 1.4]), f(1, [1.4, 1.4])],
    },
    { el: "hs", prop: "opacity", dur: 1.2, pk: 0, frames: [f(0, 1), f(0.5, 0.7), f(1, 1)] },
    ...both((el) => [blink(el)]),
    // The waves of work go out, one after the other.
    ...[0, 1].flatMap((i): MotionTrack[] => [
      {
        el: `w${i + 1}`,
        prop: "opacity",
        dur: 1.2,
        pk: 0,
        phase: r4(1 - i * 0.25),
        frames: [f(0, 0.35), f(0.3, 1), f(0.7, 0.35), f(1, 0.35)],
      },
      {
        el: `w${i + 1}`,
        prop: "translate",
        dur: 1.2,
        pk: 0,
        phase: r4(1 - i * 0.25),
        frames: [f(0, ZERO), f(0.3, [-2.4, 0]), f(0.7, ZERO), f(1, ZERO)],
      },
    ]),
    // A double hop of effort, now and then.
    rare("hop", [7, 13], 7, 6, 1.1, { el: "ev", prop: "translate" }, ZERO, [
      [0.15, [0, -6]],
      [0.3, ZERO],
      [0.45, [0, -6]],
      [0.6, ZERO],
    ]),
    // Looks at what it is doing.
    ...both((el) => [
      rare("look", [9, 16], 9, 8, 2.9, { el, prop: "translate" }, ZERO, [
        [0.4, [3.2, 1.6]],
        [2.2, [3.2, 1.6]],
        [2.6, ZERO],
      ]),
    ]),
    ...wiggle("wiggle", [10, 18], 13, 12),
  ];
}

function wait(): MotionTrack[] {
  const hop = { dur: [2.4, 3.4] as [number, number], dk: 0, pk: 0 };
  const wave = { dur: [3.6, 5] as [number, number], dk: 4, pk: 5 };
  return [
    // Hops for attention, squashing as it lands.
    {
      el: "core",
      prop: "translate",
      ...hop,
      frames: [
        f(0, ZERO),
        f(0.74, ZERO),
        f(0.78, [0, 1.2]),
        f(0.86, [0, -9]),
        f(0.93, [0, 1.4]),
        f(1, ZERO),
      ],
    },
    {
      el: "core",
      prop: "scale",
      ...hop,
      frames: [
        f(0, ONE),
        f(0.74, ONE),
        f(0.78, [1.05, 0.94]),
        f(0.86, [0.96, 1.05]),
        f(0.93, [1.06, 0.94]),
        f(1, ONE),
      ],
    },
    ...both((el) => [blink(el)]),
    // The ring around the dot calls out; the dot beats.
    {
      el: "rng",
      prop: "scale",
      dur: 1.6,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.3, 1.3]), f(1, ONE)],
    },
    { el: "rng", prop: "opacity", dur: 1.6, pk: 0, frames: [f(0, 1), f(0.5, 0.22), f(1, 1)] },
    {
      el: "dt",
      prop: "scale",
      dur: 1.6,
      pk: 0,
      frames: [f(0, ONE), f(0.15, [1.2, 1.2]), f(0.3, ONE), f(1, ONE)],
    },
    // Waves at you (with a hand when it has one, with the whole body otherwise).
    {
      el: "hand",
      prop: "translate",
      ...wave,
      frames: [
        f(0, ZERO),
        f(0.1, [-2, -15]),
        f(0.18, [2, -17]),
        f(0.26, [-2, -15]),
        f(0.34, [2, -17]),
        f(0.44, ZERO),
        f(1, ZERO),
      ],
    },
    rare("sway", [4.5, 8], 7, 6, 1.4, { el: "ev", prop: "rotate" }, 0, [
      [0.3, -7],
      [0.6, 7],
      [0.9, -4],
      [1.2, 0],
    ]),
  ];
}

function error(): MotionTrack[] {
  return [
    // A slumped breath.
    {
      el: "core",
      prop: "scale",
      dur: [4.2, 5.2],
      dk: 0,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.025, 0.96]), f(1, ONE)],
    },
    // Puffs of smoke from the head.
    ...[0, 1, 2].flatMap((i): MotionTrack[] => {
      const c = { el: `smk${i + 1}`, dur: 2.7, pk: 0, phase: r4(i / 3) };
      const dx = [-3, 2.5, -1][i] ?? 0;
      return [
        {
          ...c,
          prop: "translate",
          ease: "ease-out",
          frames: [f(0, ZERO), f(0.75, [dx, -15]), f(1, [dx, -15])],
        },
        { ...c, prop: "scale", frames: [f(0, [0.4, 0.4]), f(0.75, [1.6, 1.6]), f(1, [1.6, 1.6])] },
        { ...c, prop: "opacity", frames: [f(0, 0), f(0.15, 0.65), f(0.75, 0), f(1, 0)] },
      ];
    }),
    // The «!» beats.
    {
      el: "ex",
      prop: "scale",
      dur: 2.2,
      pk: 0,
      frames: [f(0, ONE), f(0.08, [1.2, 1.2]), f(0.16, ONE), f(1, ONE)],
    },
    // Shakes its head.
    rare("shake", [5, 10], 7, 6, 0.9, { el: "ev", prop: "rotate" }, 0, [
      [0.12, -8],
      [0.27, 8],
      [0.42, -6],
      [0.57, 4],
      [0.72, 0],
    ]),
  ];
}

function build(): MotionTable {
  const god = godTracks();
  const states: Record<MascotState, MotionTrack[]> = {
    idle: [...idle(), ...god],
    active: [...active(), ...god],
    think: [...think(), ...god],
    work: [...work(), ...god],
    wait: [...wait(), ...god],
    error: [...error(), ...god],
  };
  const tiny = [blink("eyes")];
  const elements = new Set<string>();
  for (const list of [...Object.values(states), tiny]) for (const t of list) elements.add(t.el);
  return { v: 1, elements: [...elements].sort(), states, tiny };
}

/** The table, the same for page and app. */
export const MASCOT_MOTION: MotionTable = build();

// ---------- Irregular rare events ----------

/** A 32-bit mix (lowbias32): the same integers in the app (motion.dart). */
export function mix32(x: number): number {
  let h = x | 0;
  h = Math.imul(h ^ (h >>> 16), 0x7feb352d);
  h = Math.imul(h ^ (h >>> 15), 0x846ca68b);
  return (h ^ (h >>> 16)) >>> 0;
}

/** FNV-1a of an ASCII name. */
function nameHash(s: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 0x01000193);
  return h >>> 0;
}

/** The event's own stream for one mascot: its name mixed with every rhythm number. */
function rareBase(ev: string, k: readonly number[]): number {
  let h = nameHash(ev);
  for (const v of k) h = mix32(h ^ Math.round(v * 1000));
  return h;
}

const unit = (base: number, n: number) => mix32((base + Math.imul(n, 0x9e3779b9)) | 0) / 4294967296;

/**
 * When a rare event starts, between `from` and `to` seconds, for a mascot of rhythm `k`: window
 * `n` (of the gap's mean `P`) holds one start at `n P + u(n) J`, with `J` half the gap's spread and
 * `u` the mascot's own numbers, so two starts are always `gap[0]..gap[1]` apart and never at a
 * fixed period. The phase shifts the windows by `k[pk]` of a window.
 */
export function rareStarts(
  t: MotionTrack,
  k: readonly number[],
  from: number,
  to: number,
): number[] {
  if (!t.rare) return [];
  const [g0, g1] = t.rare.gap;
  const P = (g0 + g1) / 2;
  const J = (g1 - g0) / 2;
  const shift = (t.pk !== undefined ? (k[t.pk] ?? 0) : 0) * P;
  const base = rareBase(t.rare.ev, k);
  const out: number[] = [];
  for (let n = Math.floor((from + shift) / P) - 1; n * P - shift < to; n++) {
    const s = n * P + unit(base, n) * J - shift;
    if (s >= from && s < to) out.push(r4(s));
  }
  return out;
}

/** Where a rare event is at `seconds` (0..1), or null while it rests. */
export function rareProgress(t: MotionTrack, k: readonly number[], seconds: number): number | null {
  const len = typeof t.dur === "number" ? t.dur : t.dur[0];
  for (const s of rareStarts(t, k, seconds - len, seconds + 1e-9))
    if (seconds >= s && seconds < s + len) return (seconds - s) / len;
  return null;
}

/** The fixed sequence of gaps the page's CSS repeats for an event (the app draws new ones). */
const CSS_RARE_COUNT = 5;
function cssRareCycle(t: MotionTrack): { length: number; starts: number[] } {
  const [g0, g1] = t.rare?.gap ?? [1, 1];
  const base = nameHash(t.rare?.ev ?? "");
  const starts: number[] = [];
  let at = 0;
  for (let i = 0; i < CSS_RARE_COUNT; i++) {
    starts.push(at);
    at += g0 + (g1 - g0) * unit(base, i);
  }
  return { length: at, starts };
}

// ---------- Rhythm ----------

/** A seed's sixteen numbers in 0..1 (three decimals), from its own stream (not the face's). */
export function mascotRhythm(seed: string, random: (seed: string) => () => number): number[] {
  const r = random(`${seed}\u0000motion`);
  return Array.from({ length: RHYTHM_SIZE }, () => Math.round(r() * 1000) / 1000);
}

/** When the page's CSS starts a rare event (for tests): the long cycle, scaled and shifted per mascot. */
export function cssRareStarts(
  t: MotionTrack,
  k: readonly number[],
  from: number,
  to: number,
  shift = 0,
): number[] {
  if (!t.rare) return [];
  const { length, starts } = cssRareCycle(t);
  const d = length * (0.85 + 0.3 * (k[t.dk ?? 0] ?? 0));
  const delay = d * (k[t.pk ?? 0] ?? 0) + shift;
  const out: number[] = [];
  for (let c = Math.floor((from + delay) / d) - 1; c * d - delay < to; c++)
    for (const s of starts) {
      const at = c * d + (s / length) * d - delay;
      if (at >= from && at < to) out.push(r4(at));
    }
  return out;
}

// ---------- CSS ----------

const num = (n: number) => String(r4(n));
const pct = (at: number) => `${num(at * 100)}%`;

function cssValue(prop: MotionProp, v: MotionValue): string {
  const [x, y] = typeof v === "number" ? [v, v] : v;
  if (prop === "translate") return `translate:${num(x)}px ${num(y)}px`;
  if (prop === "scale") return `scale:${num(x)} ${num(y)}`;
  if (prop === "rotate") return `rotate:${num(x)}deg`;
  return `opacity:${num(x)}`;
}

/** A rare event's frames over the page's long cycle: five events at uneven distances. */
function cssFrames(t: MotionTrack): [number, MotionValue][] {
  if (!t.rare) return t.frames;
  const len = typeof t.dur === "number" ? t.dur : t.dur[0];
  const { length, starts } = cssRareCycle(t);
  const rest = (t.frames[0] as [number, MotionValue])[1];
  const out: [number, MotionValue][] = [];
  for (const s of starts)
    for (const [at, v] of t.frames) {
      const p = r4((s + at * len) / length);
      if (out.length > 0 && p <= (out.at(-1) as [number, MotionValue])[0]) continue;
      out.push([p, v]);
    }
  if ((out.at(-1) as [number, MotionValue])[0] < 1) out.push([1, rest]);
  return out;
}

function durCss(t: MotionTrack): string {
  if (t.rare) {
    // The long cycle, a little longer or shorter for each mascot.
    const { length } = cssRareCycle(t);
    return `calc(${num(length)}s * (0.85 + 0.3 * var(--k${t.dk ?? 0})))`;
  }
  if (typeof t.dur === "number") return `${num(t.dur)}s`;
  const [a, b] = t.dur;
  return `calc(${num(a)}s + ${num(b - a)}s * var(--k${t.dk ?? 0}))`;
}

/** The phase from the rhythm, minus the small shift each mascot gets when it appears (`--j`, seconds). */
function delayCss(t: MotionTrack): string {
  const phase = t.phase ?? 0;
  const k = t.pk === undefined ? num(phase) : `(var(--k${t.pk}) + ${num(phase)})`;
  return `calc(${durCss(t)} * -1 * ${k} - var(--j, 0) * 1s)`;
}

/**
 * The page's CSS for the table: one `@keyframes` per track and one `animation` list per element
 * and state. Reduced motion and the paused page are styles.css's (`.masc` rules).
 */
export function mascotMotionCss(table: MotionTable = MASCOT_MOTION): string {
  const out: string[] = [];
  out.push(`${table.elements.map((e) => `.masc .${e}`).join(",")}{transform-box:view-box}`);
  const lists: [string, string, MotionTrack[]][] = [
    ...Object.entries(table.states).map(
      ([s, l]) => [s, `.masc.st-${s}:not(.tiny)`, l] as [string, string, MotionTrack[]],
    ),
    ["tiny", ".masc.tiny", table.tiny],
  ];
  for (const [name, root, tracks] of lists) {
    const byEl = new Map<string, string[]>();
    for (const t of tracks) {
      const id = `rgm-${name}-${t.el}-${t.prop}`;
      out.push(
        `@keyframes ${id}{${cssFrames(t)
          .map(([at, v]) => `${pct(at)}{${cssValue(t.prop, v)}}`)
          .join("")}}`,
      );
      const anim = `${id} ${durCss(t)} ${t.ease ?? "ease-in-out"} ${delayCss(t)} infinite`;
      byEl.set(t.el, [...(byEl.get(t.el) ?? []), anim]);
    }
    for (const [el, anims] of byEl) out.push(`${root} .${el}{animation:${anims.join(",")}}`);
  }
  return out.join("\n");
}
