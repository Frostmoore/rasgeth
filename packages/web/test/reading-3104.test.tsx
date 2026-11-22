// @vitest-environment jsdom
// 3.10.4: the accent colour (stored per device, applied as `data-accent`, every shade readable),
// the answers' «Lettura comoda» styles and following a streaming reply only while the person lets it.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { fireEvent, render } from "@testing-library/preact";
import { beforeEach, describe, expect, it } from "vitest";
import { ACCENT_SWATCH, ACCENTS, accent, applyAccent, setAccent } from "../src/accent.js";
import { AccentPicker } from "../src/components/AccentPicker.js";
import {
  grew,
  type Metrics,
  release,
  resume,
  scrolled,
  startFollow,
  stopFollowing,
} from "../src/follow.js";
import { lang, t } from "../src/i18n.js";

const css = readFileSync(join(import.meta.dirname, "..", "src", "styles.css"), "utf8");

/** The `--name: #hex;` pairs of the first block with exactly this selector. */
function block(selector: string): Record<string, string> {
  const start = css.indexOf(`\n${selector} {`);
  const at = start >= 0 ? start : css.indexOf(`  ${selector} {`);
  if (at < 0) throw new Error(`no ${selector}`);
  const body = css.slice(at, css.indexOf("}", at));
  return Object.fromEntries(
    [...body.matchAll(/--([\w-]+):\s*(#[0-9a-f]{6});/g)].map((m) => [m[1], m[2]]),
  );
}

const lum = (hex: string) => {
  const [r, g, b] = [1, 3, 5].map((i) => {
    const c = Number.parseInt(hex.slice(i, i + 2), 16) / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * (r as number) + 0.7152 * (g as number) + 0.0722 * (b as number);
};
const contrast = (a: string, b: string) => {
  const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p) as [number, number];
  return (x + 0.05) / (y + 0.05);
};

const root = block(":root");
const dark = { ...root, ...block('html[data-theme="dark"]') };
const SHADES = ["accent", "accent-2", "accent-soft", "accent-dim", "user"];

function palette(a: string, theme: "light" | "dark"): Record<string, string> {
  if (a === "red") return theme === "light" ? root : dark;
  const light = { ...root, ...block(`html[data-accent="${a}"]`) };
  return theme === "light"
    ? light
    : { ...dark, ...block(`html[data-accent="${a}"][data-theme="dark"]`) };
}

describe("the accent colour", () => {
  beforeEach(() => {
    lang.value = "it";
    localStorage.clear();
    setAccent("red");
  });

  it("every accent sets every shade, for dark and for the system's dark too", () => {
    for (const a of ACCENTS.filter((x) => x !== "red")) {
      expect(Object.keys(block(`html[data-accent="${a}"]`)).sort()).toEqual([...SHADES].sort());
      const d = block(`html[data-accent="${a}"][data-theme="dark"]`);
      expect(Object.keys(d).sort()).toEqual([...SHADES].sort());
      expect(block(`html[data-accent="${a}"][data-theme="system"]`)).toEqual(d);
      expect(ACCENT_SWATCH[a]).toBe(palette(a, "light").accent);
    }
    expect(ACCENT_SWATCH.red).toBe(root.accent);
  });

  it("every accent is readable in both themes (WCAG)", () => {
    for (const a of ACCENTS)
      for (const theme of ["light", "dark"] as const) {
        const p = palette(a, theme) as Record<string, string>;
        const panel = p.panel as string;
        const where = `${a} ${theme}`;
        // Links and list marks (--accent-2) are body text: 4.5:1 on the conversation's panel.
        expect(contrast(p["accent-2"] as string, panel), where).toBeGreaterThanOrEqual(4.5);
        // White words on the accent (buttons): AA in light, as today's red in dark.
        expect(contrast("#ffffff", p.accent as string), where).toBeGreaterThanOrEqual(
          theme === "light" ? 4.5 : 3.5,
        );
        // The accent as a mark (the headings' bar, icons): at least 3:1 on the panel.
        expect(contrast(p.accent as string, panel), where).toBeGreaterThanOrEqual(3);
      }
  });

  it("is chosen with drawn swatches, saved on this device and applied to the page", () => {
    const { container, getByTitle } = render(<AccentPicker />);
    expect(container.querySelector("input, select")).toBeNull();
    expect(container.querySelectorAll("button")).toHaveLength(5);
    fireEvent.click(getByTitle(t("accentBlue")));
    expect(accent.value).toBe("blue");
    expect(localStorage.getItem("rg.accent")).toBe("blue");
    expect(document.documentElement.dataset.accent).toBe("blue");
    expect(getByTitle(t("accentBlue")).getAttribute("aria-pressed")).toBe("true");
    fireEvent.click(getByTitle(t("accentRed")));
    expect(document.documentElement.dataset.accent).toBeUndefined();
    applyAccent();
    expect(document.documentElement.dataset.accent).toBeUndefined();
  });

  it("speaks both languages", () => {
    for (const l of ["it", "en"] as const) {
      lang.value = l;
      for (const k of ["accentTitle", "accentAmber", "newText"] as const) expect(t(k)).not.toBe(k);
    }
    lang.value = "en";
    expect(t("newText")).toBe("New text");
    lang.value = "it";
    expect(t("newText")).toBe("Nuovo testo");
  });
});

describe("answers to read («Lettura comoda»)", () => {
  const rule = (sel: string) => {
    const at = css.indexOf(`\n${sel} {`);
    expect(at, sel).toBeGreaterThanOrEqual(0);
    return css.slice(at, css.indexOf("}", at));
  };
  it("bigger text, room between lines and paragraphs", () => {
    expect(rule(".md.md-read")).toContain("font-size: 17px");
    expect(rule(".md.md-read")).toContain("line-height: 1.55");
    expect(rule(".md-read p")).toContain("margin: 0 0 16px");
  });
  it("headings in the text's colour with the accent's bar", () => {
    const h = rule(".md-read :is(h1, h2, h3)");
    expect(h).toContain("border-left: 4px solid var(--accent)");
    expect(h).toContain("font-weight: 700");
    expect(h).not.toContain("color:");
    expect(rule(".md-read h1")).toContain("font-size: 24px");
    expect(rule(".md-read h2")).toContain("font-size: 20.5px");
    expect(rule(".md-read h3")).toContain("font-size: 18.5px");
    expect(rule(".md-read h3")).toContain("border-left-width: 3px");
  });
  it("marks and links in the accent, bold simply bold", () => {
    expect(rule(".md-read li::marker")).toContain("var(--accent-2)");
    expect(rule(".md-read a")).toContain("var(--accent-2)");
    expect(rule(".md-read strong,\n.md-read b")).not.toContain("color");
  });
});

describe("following a streaming reply", () => {
  const m = (scrollTop: number, scrollHeight = 2000, clientHeight = 500): Metrics => ({
    scrollTop,
    scrollHeight,
    clientHeight,
  });

  it("follows at the bottom, stops at a touch and stays while text comes", () => {
    let s = grew(startFollow(), m(1500));
    expect(s.follow).toBe(true);
    s = stopFollowing(s, true);
    expect(s.follow).toBe(false);
    // Text grows below: nothing follows, the button says there is new text.
    s = grew(s, m(1500, 2400));
    expect(s.follow).toBe(false);
    expect(s.unseen).toBe(true);
    // Still holding at what was the bottom: no resuming under the finger.
    s = scrolled(s, m(1500, 2400));
    expect(s.follow).toBe(false);
    // Lifted away from the bottom: still reading there.
    s = release(s, m(1400, 2400));
    expect(s.follow).toBe(false);
    // The button (or a message sent): following again.
    s = resume(s);
    expect(s).toMatchObject({ follow: true, unseen: false });
  });

  it("any scroll up stops it; back at the bottom by hand follows again", () => {
    let s = scrolled(startFollow(), m(1500));
    s = scrolled(s, m(1300));
    expect(s.follow).toBe(false);
    s = grew(grew(s, m(1300, 2000)), m(1300, 2600));
    expect(s.unseen).toBe(true);
    s = scrolled(s, m(2098, 2600));
    expect(s).toMatchObject({ follow: true, unseen: false });
  });

  it("our own scroll to the bottom never stops it; a render without new text is not new text", () => {
    let s = scrolled(startFollow(), m(1500));
    s = scrolled(s, m(1900, 2400));
    expect(s.follow).toBe(true);
    s = stopFollowing(s);
    s = grew(s, m(1000, 2400));
    s = grew(s, m(1000, 2400));
    expect(s.unseen).toBe(false);
  });
});
