// The generator's tables, ported unchanged from the approved board (rg-test/tavole-rgcompanion,
// src/mascot.js, study G40 section 3). Their order is part of every mascot: never reorder, never
// insert in the middle; a change that moves mascots needs a new `MascotSpec.v`.

export const INK = "#1b1e27";

export interface Body {
  n: string;
  d: string;
  /** Top of the head. */
  top: number;
  /** Ear anchor. */
  ex: number;
  ey: number;
  /** Half width at the hands. */
  h72: number;
  feet: 0 | 1;
  noEars?: 1;
}

export const BODIES: readonly Body[] = [
  {
    n: "round",
    d: "M50 31a29.5 29.5 0 1 1 0 59a29.5 29.5 0 1 1 0-59Z",
    top: 31,
    ex: 19,
    ey: 38,
    h72: 28,
    feet: 1,
  },
  {
    n: "egg",
    d: "M50 24C67 24 79 44 79 62C79 79 66 90 50 90C34 90 21 79 21 62C21 44 33 24 50 24Z",
    top: 24,
    ex: 15,
    ey: 32,
    h72: 28,
    feet: 1,
  },
  {
    n: "drop",
    d: "M50 21C58 33 80 43 80 64C80 80 66 90 50 90C34 90 20 80 20 64C20 43 42 33 50 21Z",
    top: 22,
    ex: 0,
    ey: 0,
    h72: 29,
    feet: 1,
    noEars: 1,
  },
  {
    n: "soft cube",
    d: "M38 30H62C74 30 80 36 80 48V72C80 84 74 90 62 90H38C26 90 20 84 20 72V48C20 36 26 30 38 30Z",
    top: 30,
    ex: 21,
    ey: 33,
    h72: 30,
    feet: 1,
  },
  {
    n: "bell",
    d: "M50 26C65 26 72 38 73 54C74 68 82 76 82 83C82 88 79 90 74 90H26C21 90 18 88 18 83C18 76 26 68 27 54C28 38 35 26 50 26Z",
    top: 26,
    ex: 13,
    ey: 31,
    h72: 27,
    feet: 0,
  },
  {
    n: "cloud",
    d: "M28 90C18 90 15 81 19 75C13 69 16 58 25 57C23 45 34 37 43 42C47 32 61 31 66 40C75 37 84 46 80 56C88 60 87 72 80 75C84 83 78 90 71 90Z",
    top: 35,
    ex: 17,
    ey: 42,
    h72: 30,
    feet: 1,
  },
  {
    n: "bean",
    d: "M33 29C45 22 64 25 73 34C83 44 83 62 78 75C72 88 58 92 44 90C30 88 20 78 20 62C20 47 24 35 33 29Z",
    top: 26,
    ex: 17,
    ey: 31,
    h72: 29,
    feet: 1,
  },
  {
    n: "pear",
    d: "M50 28C59 28 63 35 63 42C63 49 80 55 80 72C80 84 68 90 50 90C32 90 20 84 20 72C20 55 37 49 37 42C37 35 41 28 50 28Z",
    top: 28,
    ex: 10,
    ey: 32,
    h72: 30,
    feet: 1,
  },
  {
    n: "capsule",
    d: "M50 22C63 22 74 32 74 46V66C74 80 63 90 50 90C37 90 26 80 26 66V46C26 32 37 22 50 22Z",
    top: 22,
    ex: 16,
    ey: 28,
    h72: 24,
    feet: 1,
  },
  {
    n: "ghost",
    d: "M22 56C22 38 34 26 50 26C66 26 78 38 78 56V85C78 90 74 91 70 88L65 84L59 89C56 91 54 91 51 89L50 88L49 89C46 91 44 91 41 89L35 84L30 88C26 91 22 90 22 85Z",
    top: 26,
    ex: 18,
    ey: 32,
    h72: 28,
    feet: 0,
  },
];

const glint = (x: number, y: number, r: number) =>
  `<circle cx="${x}" cy="${y}" r="${r}" fill="#fff"/>`;

export interface Eyes {
  n: string;
  dx: number;
  w: number;
  h: number;
  single?: 1;
  /** ox/oy move the look (thinking looks up). */
  draw: (x: number, y: number, ox: number, oy: number) => string;
  post?: (pos: number[], y: number) => string;
}

export const EYES: readonly Eyes[] = [
  {
    n: "round",
    dx: 10,
    w: 5,
    h: 5.5,
    draw: (x, y, ox, oy) =>
      `<ellipse cx="${x}" cy="${y + oy * 0.4}" rx="5" ry="5.5" fill="${INK}"/>${glint(x + 1.7 + ox, y - 2 + oy, 1.8)}`,
  },
  {
    n: "oval",
    dx: 9,
    w: 4.3,
    h: 7,
    draw: (x, y, ox, oy) =>
      `<ellipse cx="${x}" cy="${y + oy * 0.4}" rx="4.3" ry="6.8" fill="${INK}"/>${glint(x + 1.4 + ox, y - 3 + oy, 1.7)}`,
  },
  {
    n: "almond",
    dx: 10.5,
    w: 6.5,
    h: 5,
    draw: (x, y, ox, oy) =>
      `<path d="M${x - 6.5} ${y + 1}Q${x} ${y - 8} ${x + 6.5} ${y - 1}Q${x} ${y + 6} ${x - 6.5} ${y + 1}Z" fill="${INK}"/>${glint(x + 1.5 + ox, y - 1.6 + oy, 1.6)}`,
  },
  {
    n: "one eye",
    dx: 0,
    w: 10,
    h: 10,
    single: 1,
    draw: (x, y, ox, oy) =>
      `<circle cx="${x}" cy="${y}" r="10" fill="#fff" stroke="${INK}" stroke-width="2"/><circle cx="${x + ox}" cy="${y + 0.5 + oy}" r="5.4" fill="${INK}"/>${glint(x + 2 + ox, y - 1.8 + oy, 1.9)}`,
  },
  {
    n: "glasses",
    dx: 11,
    w: 7.5,
    h: 7.5,
    draw: (x, y, ox, oy) =>
      `<circle cx="${x}" cy="${y}" r="7.5" fill="#fff" opacity=".35"/><circle cx="${x + ox * 0.6}" cy="${y + oy * 0.6}" r="3.3" fill="${INK}"/>${glint(x + 1.2 + ox * 0.6, y - 1.2 + oy * 0.6, 1.1)}`,
    post: (pos, y) =>
      `<g fill="none" stroke="${INK}" stroke-width="2.2"><circle cx="${pos[0]}" cy="${y}" r="7.5"/><circle cx="${pos[1]}" cy="${y}" r="7.5"/><path d="M${(pos[0] ?? 0) + 7.5} ${y - 1}Q50 ${y - 4} ${(pos[1] ?? 0) - 7.5} ${y - 1}"/></g>`,
  },
  {
    n: "dots",
    dx: 9,
    w: 3.4,
    h: 3.4,
    draw: (x, y, ox, oy) =>
      `<circle cx="${x}" cy="${y + oy * 0.5}" r="3.4" fill="${INK}"/>${glint(x + 1 + ox * 0.6, y - 1.1 + oy * 0.6, 1)}`,
  },
  {
    n: "lashes",
    dx: 10,
    w: 4.8,
    h: 5,
    draw: (x, y, ox, oy) => {
      const s = x < 50 ? -1 : 1;
      return `<ellipse cx="${x}" cy="${y + oy * 0.4}" rx="4.8" ry="5" fill="${INK}"/>${glint(x + 1.5 + ox, y - 1.8 + oy, 1.6)}<path d="M${x + s * 3.6} ${y - 3.6}l${s * 3} -2.6M${x + s * 4.8} ${y - 1}l${s * 3.6} -0.8" stroke="${INK}" stroke-width="1.8" stroke-linecap="round"/>`;
    },
  },
  {
    n: "pixel",
    dx: 10,
    w: 4.2,
    h: 5.4,
    draw: (x, y, ox, oy) =>
      `<rect x="${x - 4.2}" y="${y - 5.4 + oy * 0.4}" width="8.4" height="10.8" rx="2.6" fill="${INK}"/><rect x="${x + 0.4 + ox}" y="${y - 3.6 + oy}" width="2.6" height="2.6" rx=".6" fill="#fff"/>`,
  },
  {
    n: "cartoon",
    dx: 9.5,
    w: 6,
    h: 7,
    draw: (x, y, ox, oy) =>
      `<ellipse cx="${x}" cy="${y}" rx="6" ry="7" fill="#fff" stroke="${INK}" stroke-width="1.8"/><circle cx="${x + (x < 50 ? 1.2 : -1.2) + ox}" cy="${y + 1.4 + oy * 1.3}" r="3.5" fill="${INK}"/>${glint(x + (x < 50 ? 2.2 : -0.2) + ox, y + 0.2 + oy * 1.3, 1.1)}`,
  },
  {
    n: "shiny",
    dx: 10,
    w: 6.2,
    h: 6.4,
    draw: (x, y, ox, oy) =>
      `<ellipse cx="${x}" cy="${y + oy * 0.3}" rx="6" ry="6.4" fill="${INK}"/>${glint(x + 2 + ox, y - 2.3 + oy, 2.3)}${glint(x - 2.2 + ox * 0.5, y + 2.4 + oy * 0.5, 1)}`,
  },
];

export interface Mouth {
  n: string;
  draw: (y: number) => string;
}

export const MOUTHS: readonly Mouth[] = [
  {
    n: "smile",
    draw: (y) =>
      `<path d="M43.5 ${y - 1}Q50 ${y + 5} 56.5 ${y - 1}" fill="none" stroke="${INK}" stroke-width="2.4" stroke-linecap="round"/>`,
  },
  {
    n: "open",
    draw: (y) =>
      `<path d="M43 ${y - 2}Q50 ${y + 9} 57 ${y - 2}Z" fill="${INK}" stroke="${INK}" stroke-width="1.6" stroke-linejoin="round"/><ellipse cx="50" cy="${y + 2.6}" rx="3" ry="1.6" fill="#ef8c8c"/>`,
  },
  { n: "o", draw: (y) => `<ellipse cx="50" cy="${y + 1}" rx="2.6" ry="3.1" fill="${INK}"/>` },
  {
    n: "cat",
    draw: (y) =>
      `<path d="M43 ${y - 1}Q46.5 ${y + 4} 50 ${y - 0.5}Q53.5 ${y + 4} 57 ${y - 1}" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`,
  },
  {
    n: "tooth",
    draw: (y) =>
      `<path d="M43.5 ${y - 1}Q50 ${y + 5} 56.5 ${y - 1}" fill="none" stroke="${INK}" stroke-width="2.4" stroke-linecap="round"/><path d="M48.6 ${y + 1.6}h3v2.4a1.5 1.5 0 0 1-3 0Z" fill="#fff" stroke="${INK}" stroke-width="1"/>`,
  },
  {
    n: "smirk",
    draw: (y) =>
      `<path d="M44.5 ${y + 0.5}Q51 ${y + 4} 56.5 ${y - 2}" fill="none" stroke="${INK}" stroke-width="2.4" stroke-linecap="round"/>`,
  },
  {
    n: "grin",
    draw: (y) =>
      `<path d="M41.5 ${y - 2.5}H58.5Q58 ${y + 7} 50 ${y + 7}Q42 ${y + 7} 41.5 ${y - 2.5}Z" fill="${INK}" stroke="${INK}" stroke-width="1.4" stroke-linejoin="round"/><path d="M43.5 ${y - 1.2}H56.5V${y + 0.6}H43.5Z" fill="#fff"/><ellipse cx="50" cy="${y + 4.4}" rx="3.4" ry="1.5" fill="#ef8c8c"/>`,
  },
  {
    n: "small",
    draw: (y) =>
      `<path d="M46.5 ${y}Q50 ${y + 3} 53.5 ${y}" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linecap="round"/>`,
  },
];

export const wavy = (y: number) =>
  `<path d="M42.5 ${y + 1.5}q1.9 -2.6 3.75 0t3.75 0t3.75 0t3.75 0" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linecap="round"/>`;

export interface Head {
  n: string;
  ears?: 1;
  /** Drawn behind the body. */
  back?: (b: Body) => string;
  /** Drawn over it. */
  front?: (b: Body) => string;
}

export const HEAD: readonly Head[] = [
  {
    n: "antenna",
    back: (b) =>
      `<path d="M50 ${b.top + 3}Q47 ${b.top - 7} 52 ${b.top - 12}" fill="none" class="so" stroke-width="2.4" stroke-linecap="round"/><circle cx="52.5" cy="${b.top - 14.5}" r="4" class="l so" stroke-width="2"/>`,
  },
  {
    n: "two antennas",
    back: (b) =>
      `<path d="M44 ${b.top + 4}Q40 ${b.top - 6} 36 ${b.top - 10}M56 ${b.top + 4}Q60 ${b.top - 6} 64 ${b.top - 10}" fill="none" class="so" stroke-width="2.3" stroke-linecap="round"/><circle cx="35" cy="${b.top - 11}" r="3.2" class="l so" stroke-width="1.8"/><circle cx="65" cy="${b.top - 11}" r="3.2" class="l so" stroke-width="1.8"/>`,
  },
  {
    n: "cat ears",
    ears: 1,
    back: (b) =>
      [-1, 1]
        .map((s) => {
          const x = 50 + s * b.ex;
          return `<path d="M${x - s * 9} ${b.ey + 5}L${x + s * 1} ${b.ey - 13}L${x + s * 7} ${b.ey + 7}Z" class="b so" stroke-width="2.4" stroke-linejoin="round"/><path d="M${x - s * 4.5} ${b.ey + 3}L${x + s * 1} ${b.ey - 6}L${x + s * 3.5} ${b.ey + 4}Z" class="l"/>`;
        })
        .join(""),
  },
  {
    n: "bear ears",
    ears: 1,
    back: (b) =>
      [-1, 1]
        .map(
          (s) =>
            `<circle cx="${50 + s * b.ex}" cy="${b.ey - 2}" r="8" class="b so" stroke-width="2.4"/><circle cx="${50 + s * b.ex}" cy="${b.ey - 2}" r="3.8" class="l"/>`,
        )
        .join(""),
  },
  {
    n: "sprout",
    front: (b) =>
      `<path d="M50 ${b.top + 2}V${b.top - 7}" class="so" stroke-width="2.4" stroke-linecap="round"/><path d="M50 ${b.top - 6}C45 ${b.top - 15} 36 ${b.top - 13} 37 ${b.top - 6}C41 ${b.top - 3} 47 ${b.top - 3} 50 ${b.top - 6}Z" class="l so" stroke-width="2" stroke-linejoin="round"/><path d="M50 ${b.top - 7}C54 ${b.top - 14} 61 ${b.top - 13} 61 ${b.top - 8}C58 ${b.top - 5} 53 ${b.top - 5} 50 ${b.top - 7}Z" class="l so" stroke-width="2" stroke-linejoin="round"/>`,
  },
  {
    n: "tuft",
    front: (b) =>
      `<g fill="none" class="so" stroke-width="2.6" stroke-linecap="round"><path d="M50 ${b.top + 1}C48 ${b.top - 5} 52 ${b.top - 10} 56 ${b.top - 9}"/><path d="M46 ${b.top + 2}C42 ${b.top - 3} 42 ${b.top - 8} 45 ${b.top - 10}"/><path d="M54 ${b.top + 2}C57 ${b.top - 2} 61 ${b.top - 3} 63 ${b.top - 1}"/></g>`,
  },
  {
    n: "horns",
    ears: 1,
    back: (b) =>
      [-1, 1]
        .map((s) => {
          const x = 50 + s * b.ex * 0.75;
          return `<path d="M${x - s * 4} ${b.ey + 5}Q${x - s * 3} ${b.ey - 9} ${x + s * 3} ${b.ey - 12}Q${x + s * 2} ${b.ey - 3} ${x + s * 5} ${b.ey + 5}Z" class="l so" stroke-width="2.2" stroke-linejoin="round"/>`;
        })
        .join(""),
  },
  {
    n: "cap",
    front: (b) => {
      const w = Math.max(b.ex, 13) + 5;
      return `<path d="M${50 - w} ${b.top + 8}Q50 ${b.top - 17} ${50 + w} ${b.top + 8}Z" class="cap so" stroke-width="2.2" stroke-linejoin="round"/><path d="M${50 - w - 1} ${b.top + 8}H${50 + w + 1}" class="so" stroke-width="4.5" stroke-linecap="round"/><circle cx="50" cy="${b.top - 6.5}" r="4" class="l so" stroke-width="2"/>`;
    },
  },
];

export const PATTERNS = ["none", "belly", "spots", "stripes", "two tones", "freckles"] as const;

/** Tools held by agents (local coordinates: the hand is at 0,0, pointing up). */
export const TOOLS: readonly { n: string; d: string }[] = [
  {
    n: "pencil",
    d: `<rect x="-2.8" y="-21" width="5.6" height="17" rx="1" fill="#f2b632" class="so" stroke-width="1.6"/><path d="M-2.8 -21L0 -27.5L2.8 -21Z" fill="#f3d9b1" class="so" stroke-width="1.6" stroke-linejoin="round"/><path d="M-1 -25.4L0 -27.5L1 -25.4Z" fill="${INK}"/><rect x="-2.8" y="-6.5" width="5.6" height="3" fill="#e79a9a"/>`,
  },
  {
    n: "brush",
    d: `<rect x="-2" y="-16" width="4" height="13" rx="2" fill="#b98552" class="so" stroke-width="1.4"/><rect x="-2.6" y="-20" width="5.2" height="4.5" fill="#c3c8d1" class="so" stroke-width="1.4"/><path d="M-3 -20C-3.5 -24 -1.5 -28 0 -29C1.5 -28 3.5 -24 3 -20Z" class="tint2 so" stroke-width="1.4" stroke-linejoin="round"/>`,
  },
  {
    n: "wrench",
    d: `<path d="M-1.9 -3V-17M1.9 -3V-17" class="so" stroke-width="1.5"/><rect x="-1.9" y="-17" width="3.8" height="14" fill="#b7bdc8"/><path d="M-6 -22.5a6 6 0 1 0 12 0l-2.6 0l0 -4.2a6 6 0 0 0 -6.8 0l0 4.2Z" fill="#b7bdc8" class="so" stroke-width="1.6" stroke-linejoin="round"/>`,
  },
  {
    n: "book",
    d: `<g transform="rotate(25)"><rect x="-8" y="-20" width="14" height="17" rx="1.5" class="tint2 so" stroke-width="1.6"/><path d="M-5 -20V-3" class="so" stroke-width="1.4"/><path d="M-1 -15H3.5M-1 -11.5H3.5" stroke="#fff" stroke-width="1.4" stroke-linecap="round" opacity=".8"/></g>`,
  },
  {
    n: "screwdriver",
    d: `<rect x="-3" y="-13" width="6" height="10" rx="2.5" class="tint2 so" stroke-width="1.5"/><rect x="-1" y="-26" width="2" height="13" fill="#b7bdc8" class="so" stroke-width="1"/>`,
  },
  {
    n: "test tube",
    d: `<path d="M-2.5 -26H2.5V-20L7 -7C8 -4 6 -2.5 3.5 -2.5H-3.5C-6 -2.5 -8 -4 -7 -7L-2.5 -20Z" fill="#fff" fill-opacity=".55" class="so" stroke-width="1.6" stroke-linejoin="round"/><path d="M-5.6 -10H5.6L7 -7C8 -4 6 -2.5 3.5 -2.5H-3.5C-6 -2.5 -8 -4 -7 -7Z" class="tint2"/>`,
  },
];

export const LENS = `<rect x="-1.8" y="-14" width="3.6" height="11" rx="1.6" fill="#6b5640" class="so" stroke-width="1.3"/><circle cx="0" cy="-20" r="7" fill="#dff1ff" fill-opacity=".55" class="so" stroke-width="2.4"/><path d="M-3 -23a4 4 0 0 1 3 -1.6" stroke="#fff" stroke-width="1.5" fill="none" stroke-linecap="round"/>`;

/** The twelve hues: the critical red and the "done" green stay out, so states are never confused. */
export const HUES = [55, 75, 95, 115, 185, 205, 225, 245, 268, 290, 315, 340] as const;
export const COLD = [185, 205, 225, 245, 268, 290] as const;
export const WARM = [55, 75, 95] as const;
export const SOFT_BODIES = [0, 1, 5, 6, 8, 9] as const;
