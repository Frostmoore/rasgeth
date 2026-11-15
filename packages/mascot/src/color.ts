// OKLCH to sRGB and WCAG contrast, for the app's colours and the 3:1 test (study G40 §3.4).

/** Linear sRGB of an OKLCH colour, each channel clipped to 0..1. */
export function oklchToLinear(L: number, C: number, h: number): [number, number, number] {
  const a = C * Math.cos((h * Math.PI) / 180);
  const b = C * Math.sin((h * Math.PI) / 180);
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
  const clip = (v: number) => Math.min(1, Math.max(0, v));
  return [
    clip(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    clip(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    clip(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s),
  ];
}

const encode = (v: number) => (v <= 0.0031308 ? 12.92 * v : 1.055 * v ** (1 / 2.4) - 0.055);

/** An OKLCH colour as `#rrggbb`. */
export function oklchHex(L: number, C: number, h: number): string {
  return `#${oklchToLinear(L, C, h)
    .map((v) =>
      Math.round(encode(v) * 255)
        .toString(16)
        .padStart(2, "0"),
    )
    .join("")}`;
}

/** Linear channels of `#rrggbb`. */
export function hexToLinear(hex: string): [number, number, number] {
  const c = [1, 3, 5].map((i) => {
    const v = Number.parseInt(hex.slice(i, i + 2), 16) / 255;
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  });
  return [c[0] ?? 0, c[1] ?? 0, c[2] ?? 0];
}

/** WCAG relative luminance of linear channels. */
export const luminance = (c: readonly [number, number, number]) =>
  0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];

/** WCAG contrast ratio of two `#rrggbb` colours. */
export function contrast(a: string, b: string): number {
  const ya = luminance(hexToLinear(a));
  const yb = luminance(hexToLinear(b));
  return (Math.max(ya, yb) + 0.05) / (Math.min(ya, yb) + 0.05);
}
