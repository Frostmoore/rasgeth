// @vitest-environment jsdom
// The mascots (G40.2): the approved board's faces stay the same (golden), every face of one
// RedGiant differs, the hues keep 3:1 on both themes, and every drawing is valid SVG.
import type { AgentKind, MascotSpec, MascotState } from "@redgiant/protocol";
import { MascotSpec as MascotSpecSchema } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import {
  COLD_HUES_FOR_TEST,
  contrast,
  HUES,
  MASCOT_STATES,
  MascotBook,
  mascotSignature,
  mascotSpec,
  mascotSvg,
  oklchHex,
  THEMES,
} from "../src/index.js";

// The board's roster in its order (rg-test/tavole-rgcompanion/src/ui.js): name, kind, parent,
// the seed the registry keeps and body.eyes.mouth.head.pattern:hue:tool:cheeks, as the approved
// generator (mascot.js) made them. A change here changes everyone's faces.
const ROSTER: [string, AgentKind, string | null, string, string][] = [
  ["God", "god", null, "God", ""],
  ["Chat", "assistant", null, "Chat", "8.4.3.3.2:268:4:1"],
  ["Ricercatore", "agent", null, "Ricercatore", "0.0.0.6.5:55:1:0"],
  ["Coder Web", "orchestrator", null, "Coder Web", "2.5.5.4.0:185:5:1"],
  ["Assistente mail", "assistant", null, "Assistente mail", "0.8.3.3.4:245:3:1"],
  ["Contabile", "agent", null, "Contabile", "6.4.0.4.2:340:3:1"],
  ["Tester", "subagent", "Coder Web", "Tester", "2.2.2.4.0:185:5:0"],
  ["Revisore", "inspector", null, "Revisore", "2.4.3.4.5:245:5:0"],
  ["Grafico", "agent", null, "Grafico#1", "3.2.4.5.1:115:0:1"],
  ["Traduttore", "agent", null, "Traduttore", "0.6.5.2.4:315:1:1"],
  ["Archivista", "agent", null, "Archivista#5", "5.2.7.1.4:225:3:0"],
  ["Agenda", "assistant", null, "Agenda", "6.9.1.0.1:205:3:0"],
  ["Capo cantiere", "orchestrator", null, "Capo cantiere#1", "2.6.3.4.1:95:2:1"],
  ["Sistemista", "agent", null, "Sistemista#9", "4.6.3.1.5:75:0:0"],
  ["Analista dati", "agent", null, "Analista dati#1", "8.1.4.5.5:290:2:1"],
  ["Scrittore", "agent", null, "Scrittore#9", "9.8.3.3.4:268:1:1"],
  ["Notizie", "assistant", null, "Notizie#9", "6.8.7.5.2:205:1:0"],
  ["Viaggi", "assistant", null, "Viaggi#9", "6.3.6.3.3:245:2:1"],
  ["Fotografo", "agent", null, "Fotografo#9", "4.4.4.3.0:95:3:0"],
  ["Giardiniere", "agent", null, "Giardiniere#9", "1.6.7.5.5:268:1:0"],
  ["Cuoco", "assistant", null, "Cuoco#9", "0.3.2.3.5:225:5:0"],
  ["Bibliotecario", "agent", null, "Bibliotecario#9", "8.2.1.7.0:55:1:0"],
  ["Musicista", "agent", null, "Musicista#9", "3.2.4.7.3:115:5:1"],
  ["Ispettore costi", "inspector", null, "Ispettore costi", "7.4.5.4.5:245:2:1"],
  ["Demetra", "demigod", null, "Demetra#9", "2.5.7.4.4:55:3:1"],
  ["Ricerca fonti", "subagent", "Ricercatore", "Ricerca fonti", "0.1.4.6.5:55:2:0"],
  ["Tester UI", "subagent", "Coder Web", "Tester UI", "2.9.4.4.0:185:2:0"],
  ["Postino", "agent", null, "Postino#9", "4.1.6.0.4:340:3:1"],
  ["Meteo", "assistant", null, "Meteo#9", "6.6.6.0.2:290:1:1"],
];

const choices = (s: MascotSpec) => `${mascotSignature(s)}:${s.hue}:${s.tool}:${s.cheeks ? 1 : 0}`;

function boardRoster(): Map<string, MascotSpec> {
  const book = new MascotBook();
  const all = new Map<string, MascotSpec>();
  for (const [name, kind, parent] of ROSTER) {
    const p = parent ? all.get(parent) : undefined;
    all.set(name, book.claim(name, kind, p));
  }
  return all;
}

/** Well-formed XML, as an SVG viewer reads it. */
function parses(svg: string): Document {
  const doc = new DOMParser().parseFromString(svg, "image/svg+xml");
  expect(doc.getElementsByTagName("parsererror")).toHaveLength(0);
  expect(doc.documentElement.namespaceURI).toBe("http://www.w3.org/2000/svg");
  return doc;
}

describe("seed and choices", () => {
  it("gives the board's faces, seeds included (golden)", () => {
    const all = boardRoster();
    for (const [name, kind, , seed, expected] of ROSTER) {
      const s = all.get(name) as MascotSpec;
      expect(s.seed, name).toBe(seed);
      if (kind !== "god") expect(choices(s), name).toBe(expected);
    }
  });

  it("is stable: the same seed always makes the same spec", () => {
    for (const [name, kind] of ROSTER)
      expect(mascotSpec(name, kind)).toEqual(mascotSpec(name, kind));
    expect(MascotSpecSchema.parse(mascotSpec("Chat", "assistant"))).toBeTruthy();
  });

  it("keeps 200 agents of one Rasgeth all different, and gives them back the same seeds", () => {
    const names = Array.from(
      { length: 200 },
      (_, i) => `Agent ${i} ${["web", "mail", "data", "ops"][i % 4]}`,
    );
    const kinds: AgentKind[] = ["agent", "assistant", "orchestrator", "inspector", "demigod"];
    const run = () => {
      const book = new MascotBook();
      return names.map((n, i) => book.claim(n, kinds[i % kinds.length] as AgentKind));
    };
    const first = run();
    expect(new Set(first.map(mascotSignature)).size).toBe(200);
    expect(run().map((s) => s.seed)).toEqual(first.map((s) => s.seed));
  });

  it("draws God by hand, whatever the seed", () => {
    const a = mascotSpec("God", "god");
    const b = mascotSpec("Zeus", "god");
    expect(a.handDrawn).toBe(true);
    expect({ ...a, seed: "" }).toEqual({ ...b, seed: "" });
    // The same drawing; only the rhythm (when it blinks, hops…) follows the seed.
    const still = (svg: string) => svg.replace(/;--k\d+:[\d.]+/g, "");
    expect(still(mascotSvg(a, { idPrefix: "x" }))).toBe(still(mascotSvg(b, { idPrefix: "x" })));
  });

  it("draws God as the crowned red giant with three companion stars, and the Demigod as its child", () => {
    const god = mascotSpec("God", "god");
    expect([god.parts.body, god.parts.head]).toEqual(["god", "crown"]);
    const demi = mascotSpec("Demetra#9", "demigod");
    expect([demi.parts.body, demi.parts.head, demi.handDrawn]).toEqual(["demigod", "diadem", true]);
    const big = mascotSvg(god, { state: "active", size: 128, idPrefix: "g" });
    for (const k of ["orbf", "orbf2", "orbf3", "orbb", "orbb2", "orbb3", "hal", "gl"])
      expect(big, k).toContain(`class="${k}"`);
    // Awake: the icon's arched eyes; asleep: closed eyes that open with a start.
    expect(big).toMatch(/stroke-width="3.3"/);
    expect(mascotSvg(god, { state: "idle", size: 128 })).toContain('class="eyw"');
    // The Demigod is God's drawing made smaller, with the diadem and God's red gem.
    const d = mascotSvg(demi, { state: "active", size: 128, idPrefix: "d" });
    expect(d).toContain('transform="translate(7.5 13.5) scale(0.85)"');
    expect(d).toContain('fill="#e5371f"');
    expect(d).not.toContain('class="orbf"');
  });

  it("keeps only body, face and crown (diadem) at 32 px and less", () => {
    for (const kind of ["god", "demigod"] as const) {
      const s = mascotSpec("Demetra#9", kind);
      for (const size of [16, 20, 24, 32]) {
        const svg = mascotSvg(s, { state: "active", size });
        expect(svg, `${kind} ${size}`).not.toMatch(/class="(orbf|orbb|hal|gl)\d?"/);
        expect(svg, `${kind} ${size}`).toContain("#8a5a00"); // the crown's or the diadem's gold line
        expect(svg).toContain('class="eyes"');
      }
      expect(mascotSvg(s, { state: "active", size: 48 })).toMatch(/class="(orbf|hal)"/);
    }
  });

  it("gives every demigod cream and gold, a little different by seed", () => {
    const golds = new Set(
      [0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
        const svg = mascotSvg(mascotSpec(`d${i}`, "demigod"), { theme: "light", idPrefix: "d" });
        return /<stop offset=".85" stop-color="(#[0-9a-f]{6})"/.exec(svg)?.[1];
      }),
    );
    expect(golds.size).toBe(3);
  });

  it("makes a subagent look like its parent: body, hue, headgear and pattern", () => {
    const parent = mascotSpec("Coder Web", "orchestrator");
    for (const seed of ["Tester", "Tester UI", "Runner"]) {
      const s = mascotSpec(seed, "subagent", parent);
      expect([s.body, s.hue, s.head, s.pattern, s.chroma]).toEqual([
        parent.body,
        parent.hue,
        parent.head,
        parent.pattern,
        parent.chroma,
      ]);
    }
  });

  it("keeps each kind's rules: assistants soft and cold, inspectors grey-blue with glasses", () => {
    for (let i = 0; i < 50; i++) {
      const a = mascotSpec(`a${i}`, "assistant");
      expect(COLD_HUES_FOR_TEST).toContain(a.hue);
      expect(a.parts.holds).toBe("nothing");
      const insp = mascotSpec(`i${i}`, "inspector");
      expect([insp.hue, insp.chroma, insp.parts.eyes, insp.parts.holds]).toEqual([
        245,
        0.035,
        "glasses",
        "lens",
      ]);
      expect(mascotSpec(`o${i}`, "orchestrator").parts.holds).toBe("headset");
      expect([55, 75, 95]).toContain(mascotSpec(`d${i}`, "demigod").hue);
    }
  });
});

describe("colours", () => {
  it("keeps every hue at 3:1 or more against panel and background, in both themes", () => {
    for (const theme of ["light", "dark"] as const) {
      const t = THEMES[theme];
      for (const h of HUES) {
        const body = oklchHex(t.mL, 0.13, h);
        expect(contrast(body, t.panel), `${theme} ${h}`).toBeGreaterThanOrEqual(3);
        expect(contrast(body, t.bg), `${theme} ${h}`).toBeGreaterThanOrEqual(3);
      }
      // The inspectors' grey-blue too.
      const grey = oklchHex(t.mL, 0.035, 245);
      expect(contrast(grey, t.panel)).toBeGreaterThanOrEqual(3);
      expect(contrast(grey, t.bg)).toBeGreaterThanOrEqual(3);
    }
  });

  it("never uses the critical red or the done green as a body", () => {
    for (const h of HUES) expect(h < 40 || h > 350 || (h > 125 && h < 175)).toBe(false);
  });
});

describe("drawing", () => {
  const sizes = [16, 20, 24, 32, 48, 64, 128];
  const sample = ROSTER.slice(0, 10);

  it("is valid SVG in every state, size and theme", () => {
    const all = boardRoster();
    for (const [name] of sample) {
      const s = all.get(name) as MascotSpec;
      for (const state of MASCOT_STATES)
        for (const size of sizes)
          for (const theme of [undefined, "light", "dark"] as const) {
            const svg = mascotSvg(s, {
              state,
              size,
              label: `Mascot of ${name} & co, ${state}`,
              ...(theme && { theme }),
            });
            const doc = parses(svg);
            const ids = [...doc.querySelectorAll("[id]")].map((e) => e.id);
            expect(new Set(ids).size).toBe(ids.length);
            if (theme) expect(svg).not.toMatch(/var\(/);
          }
    }
  });

  it("shows the state's sign without animation, and nothing but body and eyes at 16-20", () => {
    const s = mascotSpec("Ricercatore", "agent");
    const marks: Record<MascotState, string> = {
      idle: "mk idle",
      active: "",
      think: "mk think",
      work: "mk work",
      wait: "mk wait",
      error: "mk err",
    };
    for (const state of MASCOT_STATES) {
      if (marks[state])
        expect(mascotSvg(s, { state, size: 32 })).toContain(`class="${marks[state]}"`);
      else expect(mascotSvg(s, { state, size: 32 })).not.toContain('class="mk');
      const tiny = mascotSvg(s, { state, size: 20 });
      expect(tiny).toContain('class="masc st-');
      expect(tiny).toContain(" tiny");
      expect(tiny).not.toMatch(/class="(mk|tool|hs)[ "]/);
    }
    // Blocked: eyes become small crosses.
    expect(mascotSvg(s, { state: "error", size: 64 })).toMatch(/stroke-width="2.8"/);
  });

  it("is named for screen readers only when given a label", () => {
    const s = mascotSpec("Chat", "assistant");
    const named = parses(mascotSvg(s, { label: "Mascotte di Chat, pensa" })).documentElement;
    expect(named.getAttribute("role")).toBe("img");
    expect(named.getAttribute("aria-label")).toBe("Mascotte di Chat, pensa");
    expect(parses(mascotSvg(s)).documentElement.getAttribute("aria-hidden")).toBe("true");
  });

  it("writes in the theme's colours for the app, and leaves them to the page's CSS otherwise", () => {
    const s = mascotSpec("Chat", "assistant");
    const page = mascotSvg(s, { idPrefix: "p" });
    expect(page).toContain('class="b so"');
    expect(page).not.toContain(s.colors.light.body);
    expect(mascotSvg(s, { theme: "light" })).toContain(`fill="${s.colors.light.body}"`);
    expect(mascotSvg(s, { theme: "dark" })).toContain(`fill="${s.colors.dark.body}"`);
    expect(mascotSvg(s, { theme: "dark", state: "error" })).toContain(
      `fill="${s.colors.dark.blocked}"`,
    );
  });

  it("uses no emoji and no text: only shapes", () => {
    const s = mascotSpec("God", "god");
    for (const state of MASCOT_STATES) {
      const svg = mascotSvg(s, { state, size: 128 });
      expect(svg).not.toMatch(/<text/);
      expect(svg).not.toMatch(/[\u{1F300}-\u{1FAFF}☀-➿]/u);
    }
  });
});
