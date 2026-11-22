/**
 * The accent colours a person may choose (3.10.4, Settings > General in the page, «Tu › Aspetto»
 * in the app): Rasgeth's red, the default, and four others. The shades live in the page's
 * styles.css (`html[data-accent=…]`) and the app's `RgAccent`.
 */
export const ACCENTS = ["red", "amber", "green", "blue", "violet"] as const;
export type Accent = (typeof ACCENTS)[number];

export function isAccent(v: unknown): v is Accent {
  return typeof v === "string" && (ACCENTS as readonly string[]).includes(v);
}
