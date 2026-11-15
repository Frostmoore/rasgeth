// @vitest-environment jsdom
// The mascots' motion: one table for page and app. Every state moves (idle included), every moved
// group is in the drawing with its turning point, nothing hidden shows at rest (the sign stays the
// same without motion), every mascot has its own rhythm, the page's CSS comes from the table and
// the app embeds exactly the same table.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { AgentKind } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import {
  MASCOT_MOTION,
  MASCOT_STATES,
  type MotionTrack,
  mascotMotionCss,
  mascotSpec,
  mascotSvg,
  RHYTHM_SIZE,
  rhythmOf,
} from "../src/index.js";

const KINDS: [string, AgentKind][] = [
  ["God", "god"],
  ["Demetra", "demigod"],
  ["Coder Web", "orchestrator"],
  ["Ricercatore", "agent"],
  ["Chat", "assistant"],
  ["Revisore", "inspector"],
];

const groups = (svg: string) => {
  const doc = new DOMParser().parseFromString(svg, "image/svg+xml");
  return [...doc.querySelectorAll("[class]")];
};

describe("the table", () => {
  const all: [string, MotionTrack[]][] = [
    ...Object.entries(MASCOT_MOTION.states),
    ["tiny", MASCOT_MOTION.tiny],
  ];

  it("moves every state, idle included, with the body and at least one rare event", () => {
    for (const state of MASCOT_STATES) {
      const els = new Set(MASCOT_MOTION.states[state].map((t) => t.el));
      expect(els.has("core"), state).toBe(true);
      expect(els.has("ev"), state).toBe(true);
    }
    expect(MASCOT_MOTION.tiny.map((t) => t.el)).toEqual(["eyes"]);
  });

  it("has well-formed tracks: one per group and property, frames from 0 to 1", () => {
    for (const [name, tracks] of all) {
      const seen = new Set<string>();
      for (const t of tracks) {
        const key = `${t.el}.${t.prop}`;
        expect(seen.has(key), `${name} ${key}`).toBe(false);
        seen.add(key);
        expect(MASCOT_MOTION.elements).toContain(t.el);
        expect(t.frames[0]?.[0], key).toBe(0);
        expect(t.frames.at(-1)?.[0], key).toBe(1);
        for (let i = 1; i < t.frames.length; i++)
          expect((t.frames[i] as [number])[0]).toBeGreaterThan((t.frames[i - 1] as [number])[0]);
        for (const [, v] of t.frames) {
          if (t.prop === "translate" || t.prop === "scale")
            expect(Array.isArray(v), key).toBe(true);
          else expect(typeof v, key).toBe("number");
          if (t.prop === "opacity") expect(v as number).toBeGreaterThanOrEqual(0);
        }
        if (Array.isArray(t.dur)) expect(t.dk, key).toBeTypeOf("number");
        for (const k of [t.dk, t.pk]) if (k !== undefined) expect(k).toBeLessThan(RHYTHM_SIZE);
      }
    }
  });

  it("finds every moved group in the drawings, each with its turning point and never nested", () => {
    const drawn = new Set<string>();
    for (const [seed, kind] of KINDS)
      for (const state of MASCOT_STATES)
        for (const size of [20, 64]) {
          const svg = mascotSvg(mascotSpec(seed, kind), { state, size });
          for (const el of groups(svg)) {
            const cls = el.getAttribute("class")?.split(" ")[0] ?? "";
            if (!MASCOT_MOTION.elements.includes(cls)) continue;
            drawn.add(cls);
            expect(el.getAttribute("style"), cls).toMatch(/^transform-origin:[\d.]+px [\d.-]+px$/);
            expect(el.hasAttribute("transform"), cls).toBe(false);
            // Inside core only core's own `ev`: the app cuts the others out as flat layers.
            let up = el.parentElement;
            while (up && up.tagName !== "svg") {
              const c = up.getAttribute("class")?.split(" ")[0] ?? "";
              if (MASCOT_MOTION.elements.includes(c))
                expect(c === "core" || (c === "ev" && cls !== "core"), `${cls} in ${c}`).toBe(true);
              up = up.parentElement;
            }
          }
        }
    expect([...drawn].sort()).toEqual(MASCOT_MOTION.elements);
  });

  it("hides at rest only what appears while moving, so the sign stays the same without motion", () => {
    const hidden = new Set<string>();
    for (const [seed, kind] of KINDS)
      for (const state of MASCOT_STATES)
        for (const el of groups(mascotSvg(mascotSpec(seed, kind), { state, size: 64 })))
          if (el.getAttribute("opacity") === "0")
            hidden.add(el.getAttribute("class")?.split(" ")[0] ?? "");
    expect([...hidden].sort()).toEqual(
      ["bub", "eyw", "gl", "orbb", "pop", "smk1", "smk2", "smk3", "spk", "yn", "z3"].sort(),
    );
    // The two z's of the approved board, where they were.
    const idle = mascotSvg(mascotSpec("Chat", "assistant"), { state: "idle", size: 64 });
    expect(idle).toContain('<path d="M78 9h7l-7 8h7"/>');
    expect(idle).toContain('<path d="M89 2h5l-5 6h5"/>');
  });
});

describe("the rhythm", () => {
  it("is the mascot's own: stable for a seed, different for two neighbours", () => {
    expect(rhythmOf("Chat")).toEqual(rhythmOf("Chat"));
    expect(rhythmOf("Chat")).toHaveLength(RHYTHM_SIZE);
    expect(rhythmOf("Chat")).not.toEqual(rhythmOf("Agenda"));
    for (const k of rhythmOf("Ricercatore")) expect(k >= 0 && k < 1).toBe(true);
    const svg = mascotSvg(mascotSpec("Chat", "assistant"), { state: "idle" });
    expect(svg).toContain(`--k0:${rhythmOf("Chat")[0]}`);
    expect(svg).toContain(`--k15:${rhythmOf("Chat")[15]}`);
  });

  it("spreads the blinks: thirty mascots never blink all at once", () => {
    const periods = Array.from({ length: 30 }, (_, i) => {
      const k = rhythmOf(`agent ${i}`);
      return 3.4 + 2.8 * (k[1] as number);
    });
    expect(new Set(periods.map((p) => p.toFixed(2))).size).toBeGreaterThan(20);
  });
});

describe("the page's CSS", () => {
  const css = mascotMotionCss();
  it("has one keyframes rule per track, with each mascot's rhythm in its timing", () => {
    for (const [name, tracks] of Object.entries(MASCOT_MOTION.states))
      for (const t of tracks) expect(css).toContain(`@keyframes rgm-${name}-${t.el}-${t.prop}{`);
    expect(css).toContain(".masc.st-idle:not(.tiny) .core{animation:rgm-idle-core-scale ");
    expect(css).toContain("var(--k1)");
    expect(css).toMatch(/\.masc\.tiny \.eyes\{animation:rgm-tiny-eyes-scale /);
    // Only transforms and opacity move.
    expect(css).not.toMatch(/\{(?!translate|rotate|scale|opacity|animation|transform-box)[a-z-]+:/);
  });
});

describe("the app", () => {
  it("embeds exactly this table (regenerate with apps/companion/tool/mascot_fixtures.mjs)", () => {
    const dart = readFileSync(
      join(import.meta.dirname, "../../../apps/companion/lib/mascot/motion_table.g.dart"),
      "utf8",
    );
    const json = /r'''(.*)'''/s.exec(dart)?.[1];
    expect(json && JSON.parse(json)).toEqual(MASCOT_MOTION);
  });
});
