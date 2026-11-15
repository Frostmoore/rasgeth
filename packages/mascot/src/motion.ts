// The mascots' motion (G40.9 follow-up, the user's request: «always alive, with some variety»).
// One table of tracks is the only source: the page turns it into CSS animations
// (`mascotMotionCss`), the app embeds the same JSON (apps/companion/lib/mascot/motion_table.g.dart)
// and plays it on its layers. Only transforms (translate, rotate, scale) and opacity move, around
// the `transform-origin` written on each group of the SVG; nothing is redrawn.
//
// Every mascot has its own rhythm: sixteen numbers in 0..1 from its seed (`--k0`…`--k15` on the
// SVG's root) pick each track's period inside its range and its phase, so two mascots side by side
// never blink, hop or yawn together. The rare events (a hop, waking up with a start, a yawn, a look
// to the side, a head shake) sit at the start of long cycles whose length differs per mascot.

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

/** A rare event at the start of a cycle of about `nominal` seconds: frames given in seconds. */
function event(nominal: number, rest: MotionValue, frames: [number, MotionValue][]) {
  return [f(0, rest), ...frames.map(([s, v]) => f(s / nominal, v)), f(1, rest)];
}

// ---------- The pieces ----------

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
    const common = { el, dur: 4.8, pk: 0, phase: r4(phases[el] ?? 0), ease: "linear" as const };
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
        f(0.3, [0.62, 0.58]),
        f(0.45, [0.7, 0.72]),
        f(0.68, [1.05, 1.05]),
        f(0.71, [1.3, 1.3]),
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
      frames: [f(0, [0.6, 0.6]), f(0.705, [0.6, 0.6]), f(0.8, [1.4, 1.4]), f(1, [1.4, 1.4])],
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
  const c = { dur: 14, ease: "linear" as const };
  return [
    { el: "orbf", prop: "translate", ...c, frames: translate },
    { el: "orbf", prop: "opacity", ...c, frames: front },
    { el: "orbb", prop: "translate", ...c, frames: translate },
    { el: "orbb", prop: "opacity", ...c, frames: back },
  ];
}
const godTracks = (): MotionTrack[] => [
  { el: "hal", prop: "opacity", dur: 5.2, frames: [f(0, 1), f(0.5, 0.55), f(1, 1)] },
  ...orbitTracks(),
  {
    el: "gl",
    prop: "scale",
    dur: [5.5, 9],
    dk: 14,
    pk: 15,
    frames: event(
      7,
      [0.1, 0.1],
      [
        [0.25, [1.2, 1.2]],
        [0.6, [0.1, 0.1]],
      ],
    ),
  },
  {
    el: "gl",
    prop: "opacity",
    dur: [5.5, 9],
    dk: 14,
    pk: 15,
    frames: event(7, 0, [
      [0.2, 1],
      [0.6, 0],
    ]),
  },
  {
    el: "gl",
    prop: "rotate",
    dur: [5.5, 9],
    dk: 14,
    pk: 15,
    frames: event(7, 0, [[0.6, 90]]),
  },
];

/** The two eye groups: the drawn eyes and, sleeping, the open ones of waking up. */
const both = (make: (el: string) => MotionTrack[]): MotionTrack[] => [
  ...make("eyes"),
  ...make("eyw"),
];

/** The head's things (antenna, tuft, ears, hat) wiggling: back and front together. */
const wiggle = (dur: [number, number], dk: number, pk: number, nominal: number): MotionTrack[] =>
  ["hb", "hf"].map((el) => ({
    el,
    prop: "rotate" as const,
    dur,
    dk,
    pk,
    frames: event(nominal, 0, [
      [0.15, -7],
      [0.35, 6],
      [0.55, -4],
      [0.75, 2],
      [0.95, 0],
    ]),
  }));

// ---------- The states ----------

function idle(): MotionTrack[] {
  const wake = { dur: [26, 40] as [number, number], dk: 8, pk: 9 };
  const yawn = { dur: [22, 36] as [number, number], dk: 10, pk: 11 };
  const look = { dur: [30, 46] as [number, number], dk: 12, pk: 13 };
  return [
    // Slow breath.
    {
      el: "core",
      prop: "scale",
      dur: [3.4, 4.2],
      dk: 0,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.02, 1.035]), f(1, ONE)],
    },
    ...both((el) => [blink(el)]),
    ...zTracks(),
    ...bubble(),
    // Now and then a hop in its sleep.
    {
      el: "ev",
      prop: "translate",
      dur: [18, 30],
      dk: 6,
      pk: 7,
      frames: event(24, ZERO, [
        [0.25, [0, -7]],
        [0.5, ZERO],
        [0.65, [0, -2]],
        [0.8, ZERO],
      ]),
    },
    // Wakes up with a start, looks around, falls asleep again.
    {
      el: "ev",
      prop: "scale",
      ...wake,
      frames: event(33, ONE, [
        [0.15, [1.06, 1.08]],
        [0.45, ONE],
      ]),
    },
    {
      el: "eyes",
      prop: "opacity",
      ...wake,
      frames: event(33, 1, [
        [0.1, 0],
        [2.4, 0],
        [2.7, 1],
      ]),
    },
    {
      el: "eyw",
      prop: "opacity",
      ...wake,
      frames: event(33, 0, [
        [0.1, 1],
        [2.4, 1],
        [2.7, 0],
      ]),
    },
    ...both((el) => [
      {
        el,
        prop: "translate",
        ...wake,
        frames: event(33, ZERO, [
          [0.6, ZERO],
          [0.9, [-2.4, 0]],
          [1.5, [-2.4, 0]],
          [1.8, [2.2, 0]],
          [2.3, ZERO],
        ]),
      },
    ]),
    // A yawn: the mouth gives way to a round open one, the antenna wiggles.
    {
      el: "mouth",
      prop: "opacity",
      ...yawn,
      frames: event(29, 1, [
        [0.2, 0],
        [2.2, 0],
        [2.4, 1],
      ]),
    },
    {
      el: "yn",
      prop: "opacity",
      ...yawn,
      frames: event(29, 0, [
        [0.2, 1],
        [2.2, 1],
        [2.4, 0],
      ]),
    },
    {
      el: "yn",
      prop: "scale",
      ...yawn,
      frames: event(
        29,
        [1, 0.3],
        [
          [0.9, [1.1, 1.25]],
          [1.8, [1, 1]],
          [2.3, [1, 0.3]],
        ],
      ),
    },
    ...wiggle(yawn.dur, yawn.dk, yawn.pk, 29),
    // Looks to the side, tilting its head (and scratches it, when it has hands).
    {
      el: "ev",
      prop: "rotate",
      ...look,
      frames: event(38, 0, [
        [0.4, -3],
        [1.6, -3],
        [2, 3],
        [3, 3],
        [3.4, 0],
      ]),
    },
    {
      el: "hand",
      prop: "translate",
      ...look,
      frames: event(38, ZERO, [
        [2.2, ZERO],
        [2.6, [4, -17]],
        [2.8, [5.5, -18.5]],
        [3, [4, -17]],
        [3.2, [5.5, -18.5]],
        [3.6, ZERO],
      ]),
    },
  ];
}

function think(): MotionTrack[] {
  const tilt = { dur: [9, 15] as [number, number], dk: 6, pk: 7 };
  return [
    // A slow bob, as if weighing things.
    {
      el: "core",
      prop: "translate",
      dur: 2.8,
      pk: 0,
      frames: [f(0, ZERO), f(0.5, [0, -1.2]), f(1, ZERO)],
    },
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
        frames: [f(0, ZERO), f(0.35, [0, -1.6]), f(0.7, ZERO), f(1, ZERO)],
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
    {
      el: "ev",
      prop: "rotate",
      ...tilt,
      frames: event(12, 0, [
        [0.7, -5],
        [2.4, -5],
        [3.1, 0],
      ]),
    },
    {
      el: "hand",
      prop: "translate",
      ...tilt,
      frames: event(12, ZERO, [
        [0.6, [4, -17]],
        [0.85, [5.5, -18.5]],
        [1.1, [4, -17]],
        [1.35, [5.5, -18.5]],
        [1.6, [4, -17]],
        [2.2, ZERO],
      ]),
    },
    // Looks to the side, up.
    ...both((el) => [
      {
        el,
        prop: "translate",
        dur: [11, 19],
        dk: 8,
        pk: 9,
        frames: event(15, ZERO, [
          [0.5, [2.6, -0.6]],
          [2.6, [2.6, -0.6]],
          [3.1, ZERO],
        ]),
      },
    ]),
    // An idea: a small hop.
    {
      el: "ev",
      prop: "translate",
      dur: [20, 32],
      dk: 10,
      pk: 11,
      frames: event(26, ZERO, [
        [0.2, [0, -4.5]],
        [0.45, ZERO],
      ]),
    },
    ...wiggle([14, 22], 12, 13, 18),
  ];
}

function work(): MotionTrack[] {
  return [
    // Sways with the effort, the tool goes up and down, sparks fly at the end of each stroke.
    {
      el: "core",
      prop: "rotate",
      dur: 1.6,
      pk: 0,
      frames: [f(0, 0), f(0.25, -2.5), f(0.75, 2.5), f(1, 0)],
    },
    { el: "tool", prop: "rotate", dur: 1.6, pk: 0, frames: [f(0, 0), f(0.5, -16), f(1, 0)] },
    {
      el: "spk",
      prop: "opacity",
      dur: 1.6,
      pk: 0,
      frames: [f(0, 0), f(0.44, 0), f(0.5, 1), f(0.64, 0), f(1, 0)],
    },
    {
      el: "spk",
      prop: "scale",
      dur: 1.6,
      pk: 0,
      frames: [f(0, [0.4, 0.4]), f(0.44, [0.4, 0.4]), f(0.64, [1.3, 1.3]), f(1, [1.3, 1.3])],
    },
    { el: "hs", prop: "opacity", dur: 1.2, pk: 0, frames: [f(0, 1), f(0.5, 0.75), f(1, 1)] },
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
        frames: [f(0, ZERO), f(0.3, [-1.6, 0]), f(0.7, ZERO), f(1, ZERO)],
      },
    ]),
    // A double hop of effort, now and then.
    {
      el: "ev",
      prop: "translate",
      dur: [10, 16],
      dk: 6,
      pk: 7,
      frames: event(13, ZERO, [
        [0.15, [0, -3.5]],
        [0.3, ZERO],
        [0.45, [0, -3.5]],
        [0.6, ZERO],
      ]),
    },
    // Looks at what it is doing.
    ...both((el) => [
      {
        el,
        prop: "translate",
        dur: [12, 20],
        dk: 8,
        pk: 9,
        frames: event(16, ZERO, [
          [0.4, [2.4, 1.2]],
          [2.2, [2.4, 1.2]],
          [2.6, ZERO],
        ]),
      },
    ]),
    ...wiggle([15, 25], 12, 13, 20),
  ];
}

function wait(): MotionTrack[] {
  const hop = { dur: [2.6, 3.4] as [number, number], dk: 0, pk: 0 };
  const wave = { dur: [3.6, 5] as [number, number], dk: 4, pk: 5 };
  return [
    // Hops for attention, squashing as it lands.
    {
      el: "core",
      prop: "translate",
      ...hop,
      frames: [f(0, ZERO), f(0.78, ZERO), f(0.86, [0, -6]), f(0.93, [0, 1]), f(1, ZERO)],
    },
    {
      el: "core",
      prop: "scale",
      ...hop,
      frames: [f(0, ONE), f(0.86, ONE), f(0.93, [1.02, 0.98]), f(1, ONE)],
    },
    ...both((el) => [blink(el)]),
    // The ring around the dot calls out; the dot beats.
    {
      el: "rng",
      prop: "scale",
      dur: 1.6,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.25, 1.25]), f(1, ONE)],
    },
    { el: "rng", prop: "opacity", dur: 1.6, pk: 0, frames: [f(0, 1), f(0.5, 0.22), f(1, 1)] },
    {
      el: "dt",
      prop: "scale",
      dur: 1.6,
      pk: 0,
      frames: [f(0, ONE), f(0.15, [1.15, 1.15]), f(0.3, ONE), f(1, ONE)],
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
    {
      el: "ev",
      prop: "rotate",
      dur: [5, 7.5],
      dk: 6,
      pk: 7,
      frames: event(6, 0, [
        [0.3, -4],
        [0.6, 4],
        [0.9, -3],
        [1.2, 0],
      ]),
    },
  ];
}

function error(): MotionTrack[] {
  return [
    // A slumped breath.
    {
      el: "core",
      prop: "scale",
      dur: 4.6,
      pk: 0,
      frames: [f(0, ONE), f(0.5, [1.015, 0.975]), f(1, ONE)],
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
      frames: [f(0, ONE), f(0.08, [1.15, 1.15]), f(0.16, ONE), f(1, ONE)],
    },
    // Shakes its head.
    {
      el: "ev",
      prop: "rotate",
      dur: [6, 10],
      dk: 6,
      pk: 7,
      frames: event(8, 0, [
        [0.15, -5],
        [0.3, 5],
        [0.45, -4],
        [0.6, 3],
        [0.75, 0],
      ]),
    },
  ];
}

function build(): MotionTable {
  const god = godTracks();
  const states: Record<MascotState, MotionTrack[]> = {
    idle: [...idle(), ...god],
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

// ---------- Rhythm ----------

/** A seed's sixteen numbers in 0..1 (three decimals), from its own stream (not the face's). */
export function mascotRhythm(seed: string, random: (seed: string) => () => number): number[] {
  const r = random(`${seed}\u0000motion`);
  return Array.from({ length: RHYTHM_SIZE }, () => Math.round(r() * 1000) / 1000);
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

function durCss(t: MotionTrack): string {
  if (typeof t.dur === "number") return `${num(t.dur)}s`;
  const [a, b] = t.dur;
  return `calc(${num(a)}s + ${num(b - a)}s * var(--k${t.dk ?? 0}))`;
}

function delayCss(t: MotionTrack): string {
  const phase = t.phase ?? 0;
  if (t.pk === undefined && phase === 0) return "0s";
  const k = t.pk === undefined ? num(phase) : `(var(--k${t.pk}) + ${num(phase)})`;
  return `calc(${durCss(t)} * -1 * ${k})`;
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
        `@keyframes ${id}{${t.frames.map(([at, v]) => `${pct(at)}{${cssValue(t.prop, v)}}`).join("")}}`,
      );
      const anim = `${id} ${durCss(t)} ${t.ease ?? "ease-in-out"} ${delayCss(t)} infinite`;
      byEl.set(t.el, [...(byEl.get(t.el) ?? []), anim]);
    }
    for (const [el, anims] of byEl) out.push(`${root} .${el}{animation:${anims.join(",")}}`);
  }
  return out.join("\n");
}
