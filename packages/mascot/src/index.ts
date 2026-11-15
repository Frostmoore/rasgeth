// @redgiant/mascot (G40.2): every agent's face, from the generator approved on the board
// (rg-test/tavole-rgcompanion/src/mascot.js, study G40 section 3). Pure: no DOM, no clock.
//
// Seed -> small PRNG -> choices in a fixed order (body, eyes, mouth, headgear, pattern, hue, tool,
// cheeks). `mascotSpec` makes the JSON the app paints; `mascotSvg` draws it as the page shows it,
// with CSS variables (the page's theme) or, given a theme, with plain colours.

import type { AgentKind, MascotColors, MascotSpec, MascotState } from "@redgiant/protocol";
import { oklchHex } from "./color.js";
import { mascotRhythm, Z_REST } from "./motion.js";
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

/** God's colour on the hue circle when a page has no `--accent` (its body is a gradient anyway). */
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
      head: handDrawn ? (kind === "god" ? "crown" : "half crown") : at(HEAD, head).n,
      pattern: handDrawn ? "none" : at(PATTERNS, pattern),
      holds: holdsOf(kind, tool),
    },
    bodyPath: handDrawn
      ? "M50 32.5a28.5 28.5 0 1 1 0 57a28.5 28.5 0 1 1 0-57Z"
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

function godSvg(state: MascotState, small: boolean, demi: boolean, id: string): string {
  const body = demi ? `class="b so"` : `fill="url(#${id}b)" stroke="#7d1b12"`;
  // The crown, and the glint that runs over it now and then (hidden at rest).
  const glint = (x: number, y: number) =>
    group(
      "gl",
      x,
      y,
      `<path d="M${x} ${y - 4.2}L${x + 1.1} ${y - 1.1}L${x + 4.2} ${y}L${x + 1.1} ${y + 1.1}L${x} ${y + 4.2}L${x - 1.1} ${y + 1.1}L${x - 4.2} ${y}L${x - 1.1} ${y - 1.1}Z" fill="#fff"/>`,
      0,
    );
  const crown = demi
    ? `<path d="M40 37L42 27L47 32L52 24L55 33Z" fill="#f5c04a" stroke="#8a5a00" stroke-width="1.8" stroke-linejoin="round" transform="rotate(-14 48 32)"/>${glint(50.5, 23)}`
    : `<path d="M37 37L39 24L45 30.5L50 20L55 30.5L61 24L63 37Z" fill="#f5c04a" stroke="#8a5a00" stroke-width="2" stroke-linejoin="round"/><circle cx="50" cy="20" r="2.2" fill="#fff3c4" stroke="#8a5a00" stroke-width="1.2"/><circle cx="39" cy="24" r="1.7" fill="#fff3c4" stroke="#8a5a00" stroke-width="1"/><circle cx="61" cy="24" r="1.7" fill="#fff3c4" stroke="#8a5a00" stroke-width="1"/><path d="M38.5 33.5H61.5" stroke="#c88a12" stroke-width="1.6"/>${glint(53, 18.5)}`;
  // The little planet goes round: the copy behind the body shows on the far half of the orbit.
  const planet = `<circle cx="17" cy="70.5" r="3.4" class="orbp"/>`;
  const orbitBack = `<path d="M8 66A43 12 -14 0 1 92 46" fill="none" class="orb" stroke-width="2.4" stroke-linecap="round" opacity=".55"/>${group("orbb", 17, 70.5, planet, 0)}`;
  const orbitFront = `<path d="M92 46A43 12 -14 0 1 8 66" fill="none" class="orb" stroke-width="2.6" stroke-linecap="round"/>${group("orbf", 17, 70.5, planet)}`;
  const net = demi
    ? ""
    : `<g opacity=".55" stroke="#ffe0b0" stroke-width="1.1" fill="#ffe0b0"><path d="M62 80L70 71L66 62M62 80L55 84" fill="none"/><circle cx="62" cy="80" r="1.6"/><circle cx="70" cy="71" r="1.6"/><circle cx="66" cy="62" r="1.3"/><circle cx="55" cy="84" r="1.3"/></g>`;
  const mouth =
    state === "error"
      ? wavy(70)
      : state === "think"
        ? at(MOUTHS, 2).draw(69)
        : state === "wait"
          ? at(MOUTHS, 1).draw(69)
          : at(MOUTHS, 0).draw(69);
  return `<defs><radialGradient id="${id}b" cx=".38" cy=".32" r=".75"><stop offset="0" stop-color="#ffb070"/><stop offset=".5" style="stop-color:var(--accent)"/><stop offset="1" stop-color="#8f2016"/></radialGradient><radialGradient id="${id}h"><stop offset=".55" style="stop-color:var(--accent)" stop-opacity=".35"/><stop offset="1" style="stop-color:var(--accent)" stop-opacity="0"/></radialGradient></defs>${
    demi || small
      ? ""
      : group("hal", 50, 60, `<circle cx="50" cy="60" r="48" fill="url(#${id}h)" class="halo"/>`)
  }${CORE}${small ? "" : orbitBack}<circle cx="50" cy="61" r="28.5" ${body} stroke-width="2.4"/><ellipse cx="38" cy="45" rx="7" ry="4" fill="#fff" opacity=".35" transform="rotate(-35 38 45)"/>${net}${eyesSvg(
    9,
    eyeMode(state),
    demi ? "b" : "godlid",
    small,
  )}<ellipse cx="33" cy="64" rx="4.5" ry="2.8" fill="#ff9aa0" opacity=".55"/><ellipse cx="67" cy="64" rx="4.5" ry="2.8" fill="#ff9aa0" opacity=".55"/>${small ? mouth : mouthSvg(mouth, 69, state)}${small ? "" : orbitFront}${small ? "" : crown}${small ? "" : extrasSvg(state, 69, demi ? 24 : 18)}</g></g>`;
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
    if (has("godlid") || has("hsled") || has("dot")) a.fill = t.accent;
    if (has("orb")) a.stroke = "#ffb36b";
    if (has("orbp")) a.fill = "#ffd27a";
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
      ? godSvg(state, small, false, id)
      : spec.kind === "demigod"
        ? godSvg(state, small, true, id)
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
