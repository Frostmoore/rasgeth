import { signal } from "@preact/signals";
import { ACCENTS, type Accent, isAccent } from "@redgiant/protocol";

/**
 * The accent colour (3.10.4), chosen in Settings > General next to the theme: Rasgeth's red (the
 * default) or one of four others. Kept per device like the theme (`rg.accent`); the shades for
 * each theme live in styles.css (`html[data-accent=…]`), mirrored in the app's `RgAccent`.
 */
export { ACCENTS, type Accent };

const saved = typeof localStorage !== "undefined" ? localStorage.getItem("rg.accent") : null;
export const accent = signal<Accent>(isAccent(saved) ? saved : "red");

export function applyAccent(): void {
  const root = document.documentElement;
  // Red is `:root`'s own: no attribute, so every page and frame without the choice looks the same.
  if (accent.value === "red") delete root.dataset.accent;
  else root.dataset.accent = accent.value;
}

export function setAccent(a: Accent): void {
  accent.value = a;
  localStorage.setItem("rg.accent", a);
  applyAccent();
}

/** Each accent's own shade for its swatch (the light theme's `--accent`, styles.css). */
export const ACCENT_SWATCH: Record<Accent, string> = {
  red: "#d23a2c",
  amber: "#a8640c",
  green: "#2c8156",
  blue: "#3273bf",
  violet: "#8a59cb",
};
