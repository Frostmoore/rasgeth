// @redgiant/mascot (G40.2): every agent's face, from the generator approved on the board
// (rg-test/tavole-rgcompanion/src/mascot.js, study G40 section 3). Pure: no DOM, no clock.
//
// Seed -> small PRNG -> choices in a fixed order (body, eyes, mouth, headgear, pattern, hue, tool,
// cheeks). `mascotSpec` makes the JSON the app paints; `mascotSvg` draws it as the page shows it,
// with CSS variables (the page's theme) or, given a theme, with plain colours.

import type { AgentKind, MascotColors, MascotSpec, MascotState } from "@redgiant/protocol";
import { oklchHex } from "./color.js";
import { COMPANIONS, mascotRhythm, Z_REST } from "./motion.js";
import {
  BODIES,
  COLD,
  EYES,
  HEAD,
  HUES,
  INK,
  LENS,
  MOUTHS,
  PATTERNS,
  SOFT_BODIES,
  TOOLS,
  WARM,
  wavy,
} from "./tables.js";

export { contrast, hexToLinear, luminance, oklchHex, oklchToLinear } from "./color.js";
export {
  MASCOT_MOTION,
  type MotionEase,
  type MotionProp,
  type MotionTable,
  type MotionTrack,
  type MotionValue,
  mascotMotionCss,
  RHYTHM_SIZE,
  rareProgress,
  rareStarts,
  Z_REST,
} from "./motion.js";
export { BODIES, EYES, HEAD, HUES, MOUTHS, PATTERNS, TOOLS } from "./tables.js";
export type { AgentKind, MascotSpec, MascotState };

// ---------- Seed and choices ----------

/** cyrb128's last word: the board's hash of the seed (UTF-16 code units). */
function hash(str: string): number {
  let h1 = 1779033703;
  let h2 = 3144134277;
  let h3 = 1013904242;
  let h4 = 2773480762;
  for (let i = 0; i < str.length; i++) {
    const k = str.charCodeAt(i);
    h1 = h2 ^ Math.imul(h1 ^ k, 597399067);
    h2 = h3 ^ Math.imul(h2 ^ k, 2869860233);
    h3 = h4 ^ Math.imul(h3 ^ k, 951274213);
    h4 = h1 ^ Math.imul(h4 ^ k, 2716044179);
  }
  h1 = Math.imul(h3 ^ (h1 >>> 18), 597399067);
  h2 = Math.imul(h4 ^ (h2 >>> 22), 2869860233);
  h3 = Math.imul(h1 ^ (h3 >>> 17), 951274213);
  h4 = Math.imul(h2 ^ (h4 >>> 19), 2716044179);
  return (h1 ^ h2 ^ h3 ^ h4) >>> 0;
}

/** mulberry32 seeded by the hash. */
function rng(seed: string): () => number {
  let a = hash(seed);
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** A seed's sixteen rhythm numbers in 0..1 (`--k0`…`--k15`): when it blinks, hops, yawns. */
export const rhythmOf = (seed: string): number[] => mascotRhythm(seed, rng);

const pick = (r: () => number, n: number) => Math.floor(r() * n);
const at = <T>(list: readonly T[], i: number): T => list[i] as T;

/** The two themes' lightness for body, outline and light parts (the board's `--mL`, `--mLo`, `--mLl`). */
export const THEMES = {
  light: {
    mL: 0.62,
    mLo: 0.4,
    mLl: 0.8,
    accent: "#d23a2c",
    dim: "#6b7385",
    err: "#d23d3d",
    panel: "#ffffff",
    bg: "#f6f7f9",
    text: "#1c2230",
  },
  dark: {
    mL: 0.74,
    mLo: 0.44,
    mLl: 0.87,
    accent: "#ef4b3a",
    dim: "#8f96a3",
    err: "#d23d3d",
    panel: "#1c1f26",
    bg: "#15171c",
    text: "#e8e6e3",
  },
} as const;
export type MascotTheme = keyof typeof THEMES;

/** God's hue for its spec's colours (the app's outline before the drawing comes); the drawing has its own. */
const GOD_HUE = 25;
const CHROMA = 0.13;

function colorsOf(hue: number, chroma: number, theme: MascotTheme): MascotColors {
  const t = THEMES[theme];
  const h2 = (hue + 150) % 360;
  return {
    body: oklchHex(t.mL, chroma, hue),
    line: oklchHex(t.mLo, chroma * 0.9, hue),
    soft: oklchHex(t.mLl, chroma * 0.55, hue),
    blocked: oklchHex(t.mL, chroma * 0.3, hue),
    second: oklchHex(0.68, 0.13, h2),
    cap: oklchHex(0.64, 0.12, h2),
  };
}

const holdsOf = (kind: AgentKind, tool: number): string =>
  kind === "orchestrator"
    ? "headset"
    : kind === "inspector"
      ? "lens"
      : kind === "agent" || kind === "subagent"
        ? at(TOOLS, tool).n
        : "nothing";

/**
 * The mascot of a seed and a kind. A subagent takes body, hue, headgear, pattern and chroma from
 * its parent's mascot (it looks like it), the rest from its own seed. God is drawn by hand.
 */
export function mascotSpec(seed: string, kind: AgentKind, parent?: MascotSpec): MascotSpec {
  const r = rng(seed);
  let body = pick(r, BODIES.length);
  let eyes = pick(r, EYES.length);
  let mouth = pick(r, MOUTHS.length);
  let head = pick(r, HEAD.length);
  let pattern = pick(r, PATTERNS.length);
  let hue: number = at(HUES, pick(r, HUES.length));
  let tool = pick(r, TOOLS.length);
  let cheeks = r() < 0.55;
  let chroma = CHROMA;
  if (kind === "god") {
    // Hand-drawn and fixed: the seed does not count (the board's God has no choices).
    body = 0;
    eyes = 9;
    mouth = 0;
    head = 0;
    pattern = 0;
    tool = 0;
    cheeks = true;
    hue = GOD_HUE;
  }
  if (kind === "assistant") {
    body = at(SOFT_BODIES, body % SOFT_BODIES.length);
    hue = at(COLD, pick(r, COLD.length));
    if (head === 6 || head === 7) head = 3;
  }
  if (kind === "inspector") {
    eyes = 4;
    hue = 245;
    chroma = 0.035;
  }
  if (kind === "demigod") hue = at(WARM, pick(r, WARM.length));
  if (kind === "subagent" && parent) {
    body = parent.body;
    hue = parent.hue;
    head = parent.head;
    pattern = parent.pattern;
    chroma = parent.chroma;
  }
  if (at(BODIES, body).noEars && at(HEAD, head).ears) head = 4 + (head % 2);
  const handDrawn = kind === "god" || kind === "demigod";
  return {
    v: 1,
    seed,
    kind,
    handDrawn,
    body,
    eyes,
    mouth,
    head,
    pattern,
    tool,
    cheeks,
    hue,
    chroma,
    parts: {
      body: handDrawn ? (kind === "god" ? "god" : "demigod") : at(BODIES, body).n,
      eyes: at(EYES, kind === "god" || kind === "demigod" ? 9 : eyes).n,
      mouth: at(MOUTHS, mouth).n,
      head: handDrawn ? (kind === "god" ? "crown" : "diadem") : at(HEAD, head).n,
      pattern: handDrawn ? "none" : at(PATTERNS, pattern),
      holds: holdsOf(kind, tool),
    },
    bodyPath:
      kind === "god"
        ? "M50 32.5a28.5 28.5 0 1 1 0 57a28.5 28.5 0 1 1 0-57Z"
        : kind === "demigod"
          ? "M50 41.13a24.23 24.23 0 1 1 0 48.45a24.23 24.23 0 1 1 0-48.45Z"
          : at(BODIES, body).d,
    colors: { light: colorsOf(hue, chroma, "light"), dark: colorsOf(hue, chroma, "dark") },
  };
}

/** What makes two faces the same: the choices without the hue. */
export const mascotSignature = (s: MascotSpec): string =>
  [s.body, s.eyes, s.mouth, s.head, s.pattern].join(".");

/**
 * The faces already given in one RedGiant (the agents' registry keeps one): a new agent whose
 * face is taken tries `seed#1`, `seed#2`… and keeps the first free one, preferring a hue nobody has
 * yet (the board's rule). The winning seed is what gets saved.
 */
export class MascotBook {
  private readonly used = new Set<string>();
  private readonly hues = new Map<number, number>();

  /** Records a face already given (loading the registry). God's is not counted. */
  add(spec: MascotSpec): void {
    if (spec.kind === "god") return;
    this.used.add(mascotSignature(spec));
    this.hues.set(spec.hue, (this.hues.get(spec.hue) ?? 0) + 1);
  }

  has(spec: MascotSpec): boolean {
    return spec.kind !== "god" && this.used.has(mascotSignature(spec));
  }

  /** The first free face for `base`, recorded. */
  claim(base: string, kind: AgentKind, parent?: MascotSpec): MascotSpec {
    if (kind === "god") return mascotSpec(base, kind);
    for (let i = 0; ; i++) {
      const s = mascotSpec(i ? `${base}#${i}` : base, kind, parent);
      const freshHue =
        kind === "subagent" || kind === "inspector" || (this.hues.get(s.hue) ?? 0) < 1 || i > 8;
      // Past a thousand tries (never in practice) the face is kept even if repeated.
      if ((!this.used.has(mascotSignature(s)) && freshHue) || i >= 1000) {
        this.add(s);
        return s;
      }
    }
  }
}

// ---------- Drawing ----------

export interface MascotSvgOptions {
  state?: MascotState;
  /** Pixels; 16-20 draw body and eyes only (no accessories, marks or animation). */
  size?: number;
  /**
   * With a theme the colours are written in (for the app and files); without one the page's CSS
   * variables and classes colour it (`--mL`, `--accent`…), so a theme change redraws nothing.
   */
  theme?: MascotTheme;
  /** The accessible name («Mascot of Chat, thinking»): without one it is decorative. */
  label?: string;
  /** Prefix of the ids inside (clip path, gradients); unique per page by default. */
  idPrefix?: string;
}

let uid = 0;

type EyeMode = "open" | "half" | "up" | "x";
const eyeMode = (st: MascotState): EyeMode =>
  st === "idle" ? "half" : st === "think" ? "up" : st === "error" ? "x" : "open";

/** An animated group: its one class, its turning point, and an opacity when it starts hidden. */
const group = (cls: string, x: number, y: number, inner: string, opacity?: number) =>
  `<g class="${cls}"${opacity === undefined ? "" : ` opacity="${opacity}"`} style="transform-origin:${+x.toFixed(2)}px ${+y.toFixed(2)}px">${inner}</g>`;

/**
 * The eyes in a group that blinks (`eyes`, around their middle); asleep, also the open eyes of
 * waking up with a start (`eyw`, hidden). Glasses and lashes stay out: they do not blink.
 */
function eyesSvg(eyesIndex: number, mode: EyeMode, lidClass: string, tiny = false): string {
  const t = at(EYES, eyesIndex);
  const pos = t.single ? [50] : [50 - t.dx, 50 + t.dx];
  let out = group("eyes", 50, 55, eyeShapes(t, pos, mode, lidClass));
  if (mode === "half" && !tiny) out += group("eyw", 50, 55, eyeShapes(t, pos, "open", lidClass), 0);
  if (t.post && mode !== "x") out += t.post(pos, 55);
  return out;
}

function eyeShapes(
  t: (typeof EYES)[number],
  pos: number[],
  mode: EyeMode,
  lidClass: string,
): string {
  const y = 55;
  let out = "";
  for (const x of pos) {
    if (mode === "x") {
      const k = t.single ? 5.5 : 3.8;
      out += `<path d="M${x - k} ${y - k}l${2 * k} ${2 * k}m0 ${-2 * k}l${-2 * k} ${2 * k}" stroke="${INK}" stroke-width="2.8" stroke-linecap="round"/>`;
      continue;
    }
    const up = mode === "up";
    out += t.draw(x, y, up ? 1 : 0, up ? -2 : 0);
    if (mode === "half") {
      const ly = y - t.h * 0.3;
      out += `<path d="M${x - t.w - 2} ${y - t.h - 2.5}H${x + t.w + 2}V${ly}Q${x} ${ly + 2.6} ${x - t.w - 2} ${ly}Z" class="${lidClass}"/><path d="M${x - t.w - 0.6} ${ly + 0.2}Q${x} ${ly + 2.8} ${x + t.w + 0.6} ${ly + 0.2}" fill="none" stroke="${INK}" stroke-width="2" stroke-linecap="round"/>`;
    }
  }
  return out;
}

/** The mouth (`mouth`) and, asleep, the round open mouth of a yawn (`yn`, hidden). */
function mouthSvg(mouth: string, my: number, state: MascotState): string {
  if (!mouth) return "";
  let out = group("mouth", 50, my, mouth);
  if (state === "idle")
    out += group(
      "yn",
      50,
      my + 1,
      `<ellipse cx="50" cy="${my + 1}" rx="3.6" ry="4.2" fill="${INK}"/><ellipse cx="50" cy="${my + 3.4}" rx="2.1" ry="1.3" fill="#ff8f9c"/>`,
      0,
    );
  return out;
}

/** What the state adds to the face (all hidden without motion, the sign stays outside). */
function extrasSvg(state: MascotState, my: number, top: number): string {
  if (state === "idle") {
    // The sleep bubble at the corner of the mouth, and the lines of its pop.
    const x = 60;
    const y = my - 2;
    return `${group(
      "bub",
      x,
      y,
      `<circle cx="${x}" cy="${y}" r="3.8" fill="#dff1ff" fill-opacity=".6" stroke="#8dbbe0" stroke-width="1.1"/><circle cx="${x - 1.3}" cy="${y - 1.3}" r=".9" fill="#fff"/>`,
      0,
    )}${group(
      "pop",
      x,
      y,
      `<path d="M${x} ${y - 4}v-2.4M${x + 3.6} ${y - 2.4}l1.8-1.6M${x - 3.6} ${y - 2.4}l-1.8-1.6M${x + 4.4} ${y + 1}h2.2M${x - 4.4} ${y + 1}h-2.2" fill="none" stroke="#8dbbe0" stroke-width="1.2" stroke-linecap="round"/>`,
      0,
    )}`;
  }
  if (state === "error")
    return [46, 53, 49]
      .map((x, i) =>
        group(
          `smk${i + 1}`,
          x,
          top - 3,
          `<circle cx="${x}" cy="${top - 3}" r="3.2" fill="#9aa1ad"/>`,
          0,
        ),
      )
      .join("");
  return "";
}

/**
 * The state's sign, visible without animation: z z (idle), dots (think), waves (work), dot (wait),
 * "!" (blocked); none when active (awake, eyes open).
 */
function marks(state: MascotState): string {
  if (state === "think") {
    // The thought's two little bubbles, then the three dots (.35, .65, 1 at rest).
    const dots = [0.35, 0.65, 1]
      .map((o, i) =>
        group(`d${i + 1}`, 74 + 9 * i, 13, `<circle cx="${74 + 9 * i}" cy="13" r="3.2"/>`, o),
      )
      .join("");
    return `<g class="mk think">${group("tc1", 64.5, 25.5, `<circle cx="64.5" cy="25.5" r="1.7"/>`, 0.5)}${group("tc2", 68.5, 20, `<circle cx="68.5" cy="20" r="2.3"/>`, 0.5)}${dots}</g>`;
  }
  if (state === "wait")
    return `<g class="mk wait">${group("rng", 86, 14, `<circle class="ring" cx="86" cy="14" r="9"/>`)}${group("dt", 86, 14, `<circle class="dot" cx="86" cy="14" r="5.5"/>`)}</g>`;
  if (state === "error")
    return `<g class="mk err">${group("ex", 86, 14, `<circle cx="86" cy="14" r="8.5"/><path d="M86 9.5v5.6M86 18.6v.1" stroke="#fff" stroke-width="2.6" stroke-linecap="round"/>`)}</g>`;
  if (state === "work")
    return `<g class="mk work" fill="none" stroke-width="2.4" stroke-linecap="round">${group("w1", 9, 60, `<path d="M9 54q-3 6 0 12"/>`)}${group("w2", 4, 60, `<path d="M4 50q-4.5 10 0 20"/>`)}</g>`;
  // Two z's at rest (the sign); moving, three rise from the head one after the other.
  const z = (cls: string, o?: number) => {
    const [x, y, w, h] = Z_REST[cls] as [number, number, number, number];
    const d = `M${x - w / 2} ${y - h / 2}h${w}l${-w} ${h}h${w}`;
    return group(cls, x, y, `<path d="${d}"/>`, o);
  };
  // Awake after answering: no sign, its open eyes say it.
  if (state === "active") return "";
  return `<g class="mk idle" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${z("z3", 0)}${z("z1")}${z("z2")}</g>`;
}

/** The body (`core`, the state's motion) and inside it the rare events (`ev`), both around 50,90. */
const CORE = `<g class="core" style="transform-origin:50px 90px"><g class="ev" style="transform-origin:50px 90px">`;

// ---------- God and the Demigod (G-B of the 3.9.1 board, the Rasgeth icon) ----------
// God is the crowned red giant of the icon with three little companion stars going round (the
// header's); the Demigod is one of those stars grown up, God's drawing at 0.85 with a gold diadem
// carrying God's red gem. Awake they smile with arched eyes, asleep the eyes are closed and calm.
// At 32 px and less only body, face and crown (diadem) stay.

/** Eyes per state: happy arcs when awake (the icon's), closed asleep, open at work and waiting. */
type GodEyes = "happy" | "sleep" | "up" | "x" | "open";
const godEyeMode = (st: MascotState): GodEyes =>
  st === "active"
    ? "happy"
    : st === "idle"
      ? "sleep"
      : st === "think"
        ? "up"
        : st === "error"
          ? "x"
          : "open";

function godEyeShapes(mode: GodEyes, y: number, dx: number): string {
  let out = "";
  for (const x of [50 - dx, 50 + dx]) {
    if (mode === "happy")
      out += `<path d="M${x - 5.6} ${y + 1.8}Q${x} ${y - 6.2} ${x + 5.6} ${y + 1.8}" fill="none" stroke="${INK}" stroke-width="3.3" stroke-linecap="round"/>`;
    else if (mode === "sleep")
      out += `<path d="M${x - 5.4} ${y - 0.6}Q${x} ${y + 4.6} ${x + 5.4} ${y - 0.6}" fill="none" stroke="${INK}" stroke-width="2.8" stroke-linecap="round"/>`;
    else if (mode === "x")
      out += `<path d="M${x - 3.8} ${y - 3.8}l7.6 7.6m0 -7.6l-7.6 7.6" stroke="${INK}" stroke-width="2.8" stroke-linecap="round"/>`;
    else {
      const up = mode === "up";
      out += at(EYES, 9).draw(x, y, up ? 1 : 0, up ? -2 : 0);
    }
  }
  return out;
}

/** The eyes (`eyes`, blinking) and, asleep, the open eyes of waking up with a start (`eyw`). */
function godEyes(state: MascotState, y: number, dx: number, tiny: boolean): string {
  let out = group("eyes", 50, y, godEyeShapes(godEyeMode(state), y, dx));
  if (state === "idle" && !tiny) out += group("eyw", 50, y, godEyeShapes("open", y, dx), 0);
  return out;
}

const godSmile = (y: number) =>
  `<path d="M44.5 ${y}Q50 ${y + 5.2} 55.5 ${y}" fill="none" stroke="${INK}" stroke-width="2.6" stroke-linecap="round"/>`;

const godMouthOf = (state: MascotState, y: number) =>
  state === "error"
    ? wavy(y)
    : state === "think"
      ? at(MOUTHS, 2).draw(y)
      : state === "wait"
        ? at(MOUTHS, 1).draw(y)
        : godSmile(y);

const godCheeks = (y: number, fill: string, op: number) =>
  `<ellipse cx="30.5" cy="${y}" rx="5.4" ry="3.7" fill="${fill}" opacity="${op}"/><ellipse cx="69.5" cy="${y}" rx="5.4" ry="3.7" fill="${fill}" opacity="${op}"/>`;

/** The glint that runs over the crown (or the gem) now and then, hidden at rest. */
const godGlint = (x: number, y: number) =>
  group(
    "gl",
    x,
    y,
    `<path d="M${x} ${y - 4.2}L${x + 1.1} ${y - 1.1}L${x + 4.2} ${y}L${x + 1.1} ${y + 1.1}L${x} ${y + 4.2}L${x - 1.1} ${y + 1.1}L${x - 4.2} ${y}L${x - 1.1} ${y - 1.1}Z" fill="#fff"/>`,
    0,
  );

/** The giant's gradient, its halo and the clip of its surface. */
const giantDefs = (id: string, stops: readonly string[], edge: string) =>
  `<radialGradient id="${id}b" cx=".4" cy=".36" r=".72"><stop offset="0" stop-color="${stops[0]}"/><stop offset=".45" stop-color="${stops[1]}"/><stop offset=".85" stop-color="${stops[2]}"/><stop offset="1" stop-color="${stops[3]}"/></radialGradient><radialGradient id="${id}h"><stop offset=".5" stop-color="${edge}" stop-opacity=".5"/><stop offset="1" stop-color="${edge}" stop-opacity="0"/></radialGradient><clipPath id="${id}c"><circle cx="50" cy="61" r="28.5"/></clipPath><linearGradient id="${id}g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe9a6"/><stop offset=".45" stop-color="#f5c04a"/><stop offset="1" stop-color="#c9861a"/></linearGradient>`;

const GOD_STOPS = ["#ffb45a", "#f45a26", "#d8311a", "#8f1d12"] as const;

/** The red giant's surface: soft bands of lava, clipped to the body. */
const LAVA = (id: string) =>
  `<g clip-path="url(#${id}c)" fill="none" stroke-linecap="round"><path d="M18 52C30 44 42 56 56 47S76 44 84 50" stroke="#ffcf6b" stroke-width="3.2" opacity=".45"/><path d="M24 82C36 74 48 86 62 78S78 76 86 70" stroke="#c4261a" stroke-width="5" opacity=".35"/><path d="M30 88C44 84 56 92 70 86" stroke="#c4261a" stroke-width="3" opacity=".3"/></g>`;

/** God's crown (the icon's: three points with balls), tilted on the right of the head. */
const CROWN = { x: 63, y: 35.5, rot: 18 };
function godCrown(id: string, s: number): string {
  const sw = +(1.7 / s).toFixed(2);
  return `<g transform="translate(${CROWN.x} ${CROWN.y}) rotate(${CROWN.rot}) scale(${s})"><path d="M-11 0L-12.5 -11.5L-5.2 -4.6L0 -14L5.2 -4.6L12.5 -11.5L11 0Z" fill="url(#${id}g)" stroke="#8a5a00" stroke-width="${sw}" stroke-linejoin="round"/><rect x="-11.6" y="-3.2" width="23.2" height="4.6" rx="1.6" fill="#f2b632" stroke="#8a5a00" stroke-width="${sw}"/><g fill="#ffe9a6" stroke="#8a5a00" stroke-width="${+(1.1 / s).toFixed(2)}"><circle cx="-12.5" cy="-11.5" r="2.5"/><circle cx="0" cy="-14" r="2.8"/><circle cx="12.5" cy="-11.5" r="2.5"/></g><circle cx="0" cy="-.9" r="1.5" fill="#e5371f"/></g>`;
}
/** The crown's middle point, where the glint shows. */
function crownTip(s: number): [number, number] {
  const r = (CROWN.rot * Math.PI) / 180;
  return [
    +(CROWN.x + s * 14 * Math.sin(r)).toFixed(2),
    +(CROWN.y - s * 14 * Math.cos(r)).toFixed(2),
  ];
}

/** A companion star with a small face (the header's), drawn around its rest place. */
const COMPANION_COLORS: Record<string, [string, string]> = {
  "": ["#ffe7a0", "#c98a1a"],
  "2": ["#fff4d6", "#c9a35a"],
  "3": ["#ff9a72", "#b0412a"],
};
function companion(k: string, x: number, y: number, scale: number): string {
  const [fill, line] = COMPANION_COLORS[k] ?? ["#ffe7a0", "#c98a1a"];
  // Plain shapes, no group inside: the moving group is the only one (the app cuts it as a layer).
  const n = (v: number) => +v.toFixed(2);
  const X = (dx: number) => n(x + dx * scale);
  const Y = (dy: number) => n(y + dy * scale);
  return `<circle cx="${x}" cy="${y}" r="${n(5.6 * scale)}" fill="${fill}" stroke="${line}" stroke-width="${n(1.1 * scale)}"/><circle cx="${X(-1.9)}" cy="${Y(-0.4)}" r="${n(0.75 * scale)}" fill="${INK}"/><circle cx="${X(1.9)}" cy="${Y(-0.4)}" r="${n(0.75 * scale)}" fill="${INK}"/><path d="M${X(-1.4)} ${Y(1.5)}Q${x} ${Y(2.7)} ${X(1.4)} ${Y(1.5)}" fill="none" stroke="${INK}" stroke-width="${n(0.7 * scale)}" stroke-linecap="round"/>`;
}

function godSvg(state: MascotState, size: number, id: string): string {
  const compact = size <= 32;
  const tiny = size <= 20;
  let back = "";
  let front = "";
  if (!compact) {
    // The orbit and its three companions: each has a front and a back copy that trade places.
    back += `<path d="M8 66A43 12 -14 0 1 92 46" fill="none" stroke="#ffb36b" stroke-width="1.2" opacity=".55"/>`;
    front += `<path d="M92 46A43 12 -14 0 1 8 66" fill="none" stroke="#ffb36b" stroke-width="1.4" opacity=".8"/>`;
    for (const c of COMPANIONS) {
      back += group(`orbb${c.k}`, c.x, c.y, companion(c.k, c.x, c.y, 0.82), c.front ? 0 : 1);
      front += group(`orbf${c.k}`, c.x, c.y, companion(c.k, c.x, c.y, 1), c.front ? 1 : 0);
    }
  }
  const crownS = compact ? 0.95 : 0.8;
  const mouth = godMouthOf(state, 66);
  return `<defs>${giantDefs(id, GOD_STOPS, GOD_STOPS[2])}</defs>${
    compact
      ? ""
      : group("hal", 50, 61, `<circle cx="50" cy="61" r="42" fill="url(#${id}h)" opacity=".8"/>`)
  }${CORE}${back}<circle cx="50" cy="61" r="28.5" fill="url(#${id}b)" stroke="#a3200f" stroke-width="${compact ? 2.6 : 1.6}"/>${compact ? "" : LAVA(id)}<ellipse cx="37" cy="44" rx="7" ry="3.6" fill="#fff" opacity=".3" transform="rotate(-35 37 44)"/>${godEyes(state, 57, 11.5, tiny)}${godCheeks(65.5, "#ff5f5f", 0.55)}${tiny ? mouth : mouthSvg(mouth, 66, state)}${front}${godCrown(id, crownS)}${compact ? "" : godGlint(...crownTip(crownS))}${compact ? "" : extrasSvg(state, 66, 24)}</g></g>`;
}

/** The Demigod: God's drawing at 0.85 around the feet (as a subagent's), so it reads as God's child. */
const DEMI_SCALE = 0.85;
const DEMI_G = `<g transform="translate(${+(50 - 50 * DEMI_SCALE).toFixed(2)} ${+(90 - 90 * DEMI_SCALE).toFixed(2)}) scale(${DEMI_SCALE})">`;
/** The seed's warm hue (55, 75, 95) moves the gold a little: every demigod cream and gold, none alike. */
const demiGold = (hue: number) => 78 + (hue - 55) * 0.3;
const demiStops = (hue: number) => {
  const h = demiGold(hue);
  return [
    oklchHex(0.985, 0.03, h + 10),
    oklchHex(0.94, 0.1, h + 5),
    oklchHex(0.85, 0.15, h - 5),
    oklchHex(0.6, 0.12, h - 10),
  ];
};

function demigodSvg(state: MascotState, size: number, id: string, hue: number): string {
  const compact = size <= 32;
  const tiny = size <= 20;
  const stops = demiStops(hue);
  const edge = stops[3] as string;
  const w = compact ? 1.25 : 1;
  // The diadem: a thin gold band on the forehead with God's red gem.
  const diadem = `<path d="M27 43Q50 30 73 43" fill="none" stroke="#8a5a00" stroke-width="${5.4 * w}" stroke-linecap="round"/><path d="M27 43Q50 30 73 43" fill="none" stroke="#f5c04a" stroke-width="${3 * w}" stroke-linecap="round"/><path d="M50 30.5L55 36.5L50 42.5L45 36.5Z" fill="#e5371f" stroke="#7d1b12" stroke-width="1.4" stroke-linejoin="round"/><path d="M48.2 35.2L50 33L51 34.4" fill="none" stroke="#fff" stroke-width="1" opacity=".8" stroke-linecap="round"/>`;
  const mouth = godMouthOf(state, 68);
  return `<defs>${giantDefs(id, stops, stops[2] as string)}</defs>${
    compact
      ? ""
      : `${DEMI_G}${group("hal", 50, 61, `<circle cx="50" cy="61" r="42" fill="url(#${id}h)" opacity=".9"/>`)}</g>`
  }${CORE}${DEMI_G}<circle cx="50" cy="61" r="28.5" fill="url(#${id}b)" stroke="${edge}" stroke-width="${compact ? 3 : 2}"/><ellipse cx="37" cy="47" rx="6.5" ry="3.4" fill="#fff" opacity=".6" transform="rotate(-35 37 47)"/>${diadem}${godEyes(state, 59, 11, tiny)}${godCheeks(67, "#ff7a6a", 0.6)}${tiny ? mouth : mouthSvg(mouth, 68, state)}${compact ? "" : godGlint(50, 31)}${compact ? "" : extrasSvg(state, 68, 28)}</g></g></g>`;
}

function bodySvg(s: MascotSpec, state: MascotState, size: number, id: string): string {
  const b = at(BODIES, s.body);
  const h = at(HEAD, s.head);
  const tiny = size <= 20;
  const sub = s.kind === "subagent";
  let back = "";
  let front = "";
  let inner = "";
  // The head's things wiggle around the top of the head.
  if (!tiny && h.back) back += group("hb", 50, b.top + 4, h.back(b));
  if (!tiny && h.front) front += group("hf", 50, b.top + 4, h.front(b));
  const feet = b.feet
    ? `<ellipse cx="39" cy="89.5" rx="7" ry="3.6" class="o"/><ellipse cx="61" cy="89.5" rx="7" ry="3.6" class="o"/>`
    : "";
  // The pattern, clipped to the body.
  const p = at(PATTERNS, s.pattern);
  if (p === "belly") inner += `<ellipse cx="50" cy="81" rx="17" ry="11" class="l" opacity=".85"/>`;
  if (p === "spots")
    inner += `<circle cx="27" cy="73" r="5" class="l" opacity=".8"/><circle cx="74" cy="64" r="4" class="l" opacity=".8"/><circle cx="68" cy="83" r="5.5" class="l" opacity=".8"/>`;
  if (p === "stripes")
    inner += `<path d="M10 76H90M10 83H90" class="sl" stroke-width="3.4" opacity=".8"/>`;
  if (p === "two tones") inner += `<path d="M0 79Q50 72 100 79V100H0Z" class="l" opacity=".75"/>`;
  inner += `<ellipse cx="50" cy="100" rx="42" ry="14" class="o" opacity=".22"/>`;
  const hx0 = 50 - Math.max(b.ex, 12) * 0.75;
  const hl = `<ellipse cx="${hx0}" cy="${b.top + 13}" rx="6.5" ry="3.6" fill="#fff" opacity=".4" transform="rotate(-38 ${hx0} ${b.top + 13})"/>`;
  const freckles =
    p === "freckles"
      ? `<g class="o" opacity=".75"><circle cx="31" cy="64" r="1.1"/><circle cx="34" cy="66.5" r="1.1"/><circle cx="29" cy="67" r="1.1"/><circle cx="69" cy="64" r="1.1"/><circle cx="66" cy="66.5" r="1.1"/><circle cx="71" cy="67" r="1.1"/></g>`
      : "";
  const cheeks =
    s.cheeks || s.kind === "assistant"
      ? `<ellipse cx="31" cy="64" rx="4.6" ry="2.8" fill="#ff8f9c" opacity=".5"/><ellipse cx="69" cy="64" rx="4.6" ry="2.8" fill="#ff8f9c" opacity=".5"/>`
      : "";
  const my = at(EYES, s.eyes).single ? 73 : 69;
  let mouth =
    state === "error"
      ? wavy(my)
      : state === "wait"
        ? at(MOUTHS, 1).draw(my)
        : at(MOUTHS, s.mouth).draw(my);
  if (tiny) mouth = "";
  // Hands and tool.
  let hands = "";
  const hasTool = !tiny && (s.kind === "agent" || s.kind === "inspector" || s.kind === "subagent");
  if (hasTool) {
    const hx = 50 + b.h72 + 2;
    const lx = 50 - b.h72 - 2;
    const toolD = s.kind === "inspector" ? LENS : at(TOOLS, s.tool).d;
    // The free hand scratches its head and waves; working, sparks fly at the end of each stroke.
    hands = `${group("hand", lx, 73, `<circle cx="${lx}" cy="73" r="4.8" class="b so" stroke-width="2.2"/>`)}<g class="tool" style="transform-origin:${hx}px 73px"><g transform="translate(${hx} 73) rotate(18)">${toolD}</g><circle cx="${hx}" cy="73" r="4.8" class="b so" stroke-width="2.2"/></g>`;
    if (state === "work")
      hands += group(
        "spk",
        hx + 1,
        45,
        `<path d="M${hx + 1} 41v-4.4M${hx + 4.6} 42.6l3-3M${hx - 2.6} 42.6l-3-3M${hx + 5.4} 46h4" fill="none" stroke="#ffc94a" stroke-width="2" stroke-linecap="round"/>`,
        0,
      );
  }
  let headset = "";
  if (!tiny && s.kind === "orchestrator") {
    const w = b.h72 - 2 + 1;
    headset = `<g class="hs" style="transform-origin:50px 54px"><path d="M${50 - w} 54C${50 - w} ${b.top - 16} ${50 + w} ${b.top - 16} ${50 + w} 54" fill="none" stroke="#2b2f3a" stroke-width="3.4" stroke-linecap="round"/><rect x="${50 - w - 5}" y="47" width="9" height="15" rx="4" fill="#2b2f3a"/><rect x="${50 + w - 4}" y="47" width="9" height="15" rx="4" fill="#2b2f3a"/><path d="M${50 - w} 60Q${50 - w + 2} 73 40.5 72.5" fill="none" stroke="#2b2f3a" stroke-width="2.2" stroke-linecap="round"/><circle cx="39.5" cy="72.5" r="2.6" fill="#2b2f3a"/><circle class="hsled" cx="${50 + w + 0.5}" cy="54.5" r="1.6"/></g>`;
  }
  const scale = sub ? ` transform="translate(10 18) scale(.8)"` : "";
  return `<defs><clipPath id="${id}"><path d="${b.d}"/></clipPath></defs>${CORE}<g${scale}>${back}${feet}<path d="${b.d}" class="b so" stroke-width="2.6" stroke-linejoin="round"/><g clip-path="url(#${id})">${inner}</g>${hl}${freckles}${cheeks}${eyesSvg(
    s.eyes,
    eyeMode(state),
    "b",
    tiny,
  )}${mouthSvg(mouth, my, state)}${front}${headset}${tiny ? "" : extrasSvg(state, my, b.top - 2)}${hands}</g></g></g>`;
}

const escapeAttr = (v: string) =>
  v.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

/** The colours the page's CSS gives each class, written in for one theme. */
function painter(s: MascotSpec, state: MascotState, theme: MascotTheme) {
  const t = THEMES[theme];
  const c = s.colors[theme];
  return (classes: string[]): Record<string, string> => {
    const a: Record<string, string> = {};
    const has = (k: string) => classes.includes(k);
    if (has("b")) a.fill = state === "error" ? c.blocked : c.body;
    if (has("so")) a.stroke = c.line;
    if (has("o")) a.fill = c.line;
    if (has("l")) a.fill = c.soft;
    if (has("sl")) Object.assign(a, { stroke: c.soft, fill: "none" });
    if (has("tint2")) a.fill = c.second;
    if (has("cap")) a.fill = c.cap;
    if (has("hsled") || has("dot")) a.fill = t.accent;
    if (has("ring"))
      Object.assign(a, { fill: "none", stroke: t.accent, "stroke-width": "2.2", opacity: ".45" });
    if (has("mk")) {
      if (has("think")) a.fill = t.dim;
      if (has("err")) a.fill = t.err;
      if (has("work") || has("idle")) a.stroke = t.dim;
    }
    return a;
  };
}

/** Writes the colours of a theme into the markup (classes stay, for animation). */
function paint(svg: string, colorsFor: (classes: string[]) => Record<string, string>): string {
  return svg.replace(
    /<([a-zA-Z]+)((?:\s+[\w:-]+="[^"]*")*)\s*(\/?)>/g,
    (whole, tag: string, attrs: string, slash: string) => {
      const cls = /\sclass="([^"]*)"/.exec(attrs);
      if (!cls?.[1]) return whole;
      const add = colorsFor(cls[1].split(/\s+/));
      const keys = Object.keys(add);
      if (keys.length === 0) return whole;
      let rest = attrs;
      for (const k of keys) rest = rest.replace(new RegExp(`\\s${k}="[^"]*"`), "");
      const extra = keys.map((k) => ` ${k}="${add[k]}"`).join("");
      return `<${tag}${rest}${extra}${slash ? "/" : ""}>`;
    },
  );
}

/**
 * The mascot as an SVG string, as on the board: the root has the classes `masc st-<state>` (and
 * `tiny` at 16-20) that the page's CSS animates; with `prefers-reduced-motion` the sign stays.
 */
export function mascotSvg(spec: MascotSpec, options: MascotSvgOptions = {}): string {
  const state = options.state ?? "idle";
  const size = options.size ?? 64;
  const small = size <= 20;
  const id = options.idPrefix ?? `rgm${++uid}`;
  let content =
    spec.kind === "god"
      ? godSvg(state, size, id)
      : spec.kind === "demigod"
        ? demigodSvg(state, size, id, spec.hue)
        : bodySvg(spec, state, size, id);
  if (!small) content += marks(state);
  const a11y = options.label
    ? `role="img" aria-label="${escapeAttr(options.label)}"`
    : `aria-hidden="true"`;
  const rhythm = rhythmOf(spec.seed)
    .map((k, i) => `;--k${i}:${k}`)
    .join("");
  let out = `<svg xmlns="http://www.w3.org/2000/svg" class="masc st-${state}${small ? " tiny" : ""}" viewBox="0 0 100 100" width="${size}" height="${size}" style="--h:${spec.hue};--c:${spec.chroma};--h2:${(spec.hue + 150) % 360}${rhythm}" ${a11y}>${content}</svg>`;
  if (options.theme) {
    const t = THEMES[options.theme];
    out = paint(out, painter(spec, state, options.theme)).replace(/var\(--accent\)/g, t.accent);
  }
  return out;
}

/** Every state, in the board's order. */
export const MASCOT_STATES: readonly MascotState[] = [
  "idle",
  "active",
  "think",
  "work",
  "wait",
  "error",
];

/** The assistants' cold hues (for tests). */
export const COLD_HUES_FOR_TEST: readonly number[] = COLD;

/**
 * Whether an agent has a mascot of its own (decision «Mascotte solo per orchestratori e agenti di
 * primo livello», 2026-11-19): the first level, every lasting kind (God, the Demi-God,
 * orchestrators, agents, assistants, inspectors), made by the person or by an agent as part of the
 * team. A sub-agent never does: an agent opens it for one task (`run_subagent`, `run_subagents`)
 * and it stops when the task ends, so it shows `subagentSignSvg` instead. The kind decides, not
 * the `persistent` flag.
 */
export function hasOwnMascot(a: { kind: AgentKind; persistent?: boolean }): boolean {
  return a.kind !== "subagent";
}

/** The sign's colours in one theme: the ring (the parent's body), the blocked red, the badge. */
export interface SubagentSignColors {
  ring: string;
  err: string;
  accent: string;
  /** The badge's outline: the surface it sits on. */
  panel: string;
}

/** A sub-agent's sign colours: its parent's body colour, or a neutral grey without a parent. */
export function subagentSignColors(
  parent: MascotSpec | undefined,
  theme: MascotTheme,
): SubagentSignColors {
  const t = THEMES[theme];
  return {
    ring: parent ? parent.colors[theme].body : t.dim,
    err: t.err,
    accent: t.accent,
    panel: t.panel,
  };
}

/**
 * The sign a sub-agent shows instead of a mascot (board «segno dei sotto-agenti», choice A): a
 * ring in its parent's colour with a dot in the middle, on a 24x24 box. Asleep the ring fades and
 * the dot goes; working, an arc turns on a faded ring (`spin`); thinking, the dot pulses (`pulse`);
 * waiting for the person, a red badge blinks (`blink`); blocked, the ring turns red with a cross.
 * Without a theme the page's CSS colours it (`--h`, `--c`, `--mL`, `--err`, `--accent`); with one
 * the colours are written in (the app's painter mirrors this drawing, `subagent_sign.dart`).
 */
export function subagentSignSvg(
  parent: MascotSpec | undefined,
  options: MascotSvgOptions = {},
): string {
  const state = options.state ?? "idle";
  const size = options.size ?? 24;
  const c = options.theme ? subagentSignColors(parent, options.theme) : undefined;
  const ringCol = state === "error" ? (c?.err ?? "") : (c?.ring ?? "");
  const stroke = (cls: string, col: string) => (c ? `stroke="${col}"` : `class="${cls}"`);
  const fill = (cls: string, col: string) => (c ? `fill="${col}"` : `class="${cls}"`);
  const ringCls = state === "error" ? "sge" : "sgr";
  let inner: string;
  if (state === "work") {
    inner =
      `<circle cx="12" cy="12" r="8" fill="none" ${stroke(ringCls, ringCol)} stroke-width="3.2" stroke-opacity=".3"/>` +
      `<g class="spin" style="transform-origin:12px 12px"><path d="M20 12A8 8 0 0 1 8.67 19.27" fill="none" ${stroke(ringCls, ringCol)} stroke-width="3.2" stroke-linecap="round"/></g>`;
  } else {
    inner = `<circle cx="12" cy="12" r="8" fill="none" ${stroke(ringCls, ringCol)} stroke-width="3.2"${state === "idle" ? ' stroke-opacity=".5"' : ""}/>`;
  }
  if (state === "error")
    inner += `<path d="M9.8 9.8l4.4 4.4M14.2 9.8l-4.4 4.4" fill="none" ${stroke("sge", c?.err ?? "")} stroke-width="2.2" stroke-linecap="round"/>`;
  else if (state !== "idle")
    inner += `<g class="${state === "think" ? "pulse" : "dot"}" style="transform-origin:12px 12px"><circle cx="12" cy="12" r="3" ${fill("sgf", c?.ring ?? "")}/></g>`;
  if (state === "wait")
    inner += `<g class="blink"><circle cx="19.5" cy="4.5" r="3.6" ${c ? `fill="${c.accent}" stroke="${c.panel}"` : 'class="sgw"'} stroke-width="1.6"/></g>`;
  const a11y = options.label
    ? `role="img" aria-label="${escapeAttr(options.label)}"`
    : `aria-hidden="true"`;
  const hue = parent?.hue ?? 0;
  const chroma = parent ? parent.chroma : 0;
  return `<svg xmlns="http://www.w3.org/2000/svg" class="sgn st-${state}" viewBox="0 0 24 24" width="${size}" height="${size}" style="--h:${hue};--c:${chroma}" ${a11y}>${inner}</svg>`;
}
