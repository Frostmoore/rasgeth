import { z } from "zod";
import { AgentKind } from "./agents.js";

/**
 * An agent's mascot (G40.2): the choices made from its seed, in a fixed order, so the page draws
 * it with `mascotSvg` (`@redgiant/mascot`) and the app paints the same parts natively.
 */

/** What the mascot shows: idle, thinking, working, waiting for the person, blocked. */
export const MascotState = z.enum(["idle", "think", "work", "wait", "error"]);
export type MascotState = z.infer<typeof MascotState>;

/** One theme's colours of a mascot, as sRGB hex (the page uses CSS variables instead). */
export const MascotColors = z.object({
  /** The body. */
  body: z.string(),
  /** Outlines, feet and the shading under the body. */
  line: z.string(),
  /** The lighter parts: belly, spots, inner ears, antenna tips. */
  soft: z.string(),
  /** The body when blocked (the colour fades). */
  blocked: z.string(),
  /** The second hue: brush tip, book, test tube. */
  second: z.string(),
  /** The cap's colour. */
  cap: z.string(),
});
export type MascotColors = z.infer<typeof MascotColors>;

export const MascotSpec = z.object({
  /** Version of the generator's tables: a change that moves mascots needs a new one. */
  v: z.literal(1),
  /** The seed it was made from (`AgentSpec.mascotSeed`). */
  seed: z.string(),
  kind: AgentKind,
  /** God (and the Demi-God's shape) is drawn by hand: the seed does not count for its shape. */
  handDrawn: z.boolean(),
  /** Indexes into the generator's tables, chosen in this order. */
  body: z.number().int().min(0),
  eyes: z.number().int().min(0),
  mouth: z.number().int().min(0),
  head: z.number().int().min(0),
  pattern: z.number().int().min(0),
  tool: z.number().int().min(0),
  cheeks: z.boolean(),
  /** The OKLCH hue (degrees) and chroma; the lightness depends on the theme. */
  hue: z.number(),
  chroma: z.number(),
  /** The names of the parts (for people and for the app's painter). */
  parts: z.object({
    body: z.string(),
    eyes: z.string(),
    mouth: z.string(),
    head: z.string(),
    pattern: z.string(),
    /** What it holds: a tool, the lens (inspectors), the headset (orchestrators) or nothing. */
    holds: z.string(),
  }),
  /** The body's outline as an SVG path on a 100x100 box. */
  bodyPath: z.string(),
  colors: z.object({ light: MascotColors, dark: MascotColors }),
});
export type MascotSpec = z.infer<typeof MascotSpec>;
