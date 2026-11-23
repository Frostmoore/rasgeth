// The design kit of agent-made pages (3.5.12) and the runtime's errors as the agent reads them:
// the kit comes after the WebRTC lockdown, the runtime and the import map, before the page's own
// CSS; its themes follow the host; errors say the line of the file's source, `[lib]` only for a
// library, a blocked picture becomes a placeholder; canvas_look tells old errors as old.
import { readFileSync } from "node:fs";
import { runInNewContext } from "node:vm";
import { WIDGET_MAX_BYTES } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { ARTIFACT_HELP, ArtifactErrors, artifactPage, widgetPage } from "../src/artifact-engine.js";
import { ARTIFACT_GUIDANCE, CHAT_ARTIFACT_GUIDANCE } from "../src/artifact-guidance.js";
import { KIT_SCRIPT, KIT_STYLE, KIT_STYLE_WIDGET } from "../src/artifact-kit.js";
import { WEBRTC_LOCKDOWN_TAG } from "../src/webrtc-lockdown.js";

const RUNTIME = '<script>(()=>{"use strict"';

/** Where a text starts in a page, failing when it is not there. */
const at = (page: string, text: string) => {
  const i = page.indexOf(text);
  expect(i, text).toBeGreaterThanOrEqual(0);
  return i;
};

/** The 1-based line of a text in a page. */
const lineOf = (page: string, text: string) => page.slice(0, at(page, text)).split("\n").length;

interface FakeEl {
  tagName: string;
  className?: string;
  textContent?: string;
  title?: string;
  src?: string;
  href?: string;
  dataset: Record<string, string>;
  attrs: Record<string, string>;
  style: { setProperty(k: string, v: string): void; [k: string]: unknown };
  vars: Record<string, string>;
  added: FakeEl[];
  kids: (FakeEl | string)[];
  setAttribute(k: string, v: string): void;
  getAttribute(k: string): string | null;
  after(e: FakeEl): void;
}

function el(tagName: string, props: Partial<FakeEl> = {}): FakeEl {
  const e: FakeEl = {
    tagName,
    dataset: {},
    attrs: {},
    vars: {},
    added: [],
    kids: [],
    style: {
      setProperty(k: string, v: string) {
        e.vars[k] = v;
      },
    },
    setAttribute(k, v) {
      e.attrs[k] = v;
    },
    getAttribute(k) {
      return e.attrs[k] ?? null;
    },
    after(x) {
      e.added.push(x);
    },
    ...({
      appendChild(x: FakeEl) {
        e.kids.push(x);
        return x;
      },
      replaceChildren(...x: (FakeEl | string)[]) {
        e.kids = x;
      },
      querySelector: () => null,
      querySelectorAll: () => [],
    } as object),
    ...props,
  };
  return e;
}

/**
 * Our runtime script of a page, run in a small fake window: what it posts to its parent, the
 * listeners it set, the root element it themes.
 */
function runRuntime(
  page: string,
  language = "it-IT",
  found: (selector: string) => FakeEl[] = () => [],
) {
  const start = at(page, RUNTIME) + "<script>".length;
  const code = page.slice(start, page.indexOf("</script>", start));
  const posted: { method: string; params: Record<string, unknown> }[] = [];
  const listeners: Record<string, ((e: unknown) => void)[]> = {};
  const parent = {
    postMessage: (m: { method: string; params: Record<string, unknown> }) => posted.push(m),
  };
  const root = el("HTML");
  const created: FakeEl[] = [];
  const document = {
    readyState: "complete",
    documentElement: root,
    body: undefined,
    querySelectorAll: found,
    addEventListener: () => {},
    createElement: (t: string) => {
      const x = el(t.toUpperCase());
      created.push(x);
      return x;
    },
  };
  const win: Record<string, unknown> = {
    parent,
    document,
    navigator: { language },
    location: { protocol: "http:", host: "rg.local", href: "http://rg.local/preview/T/a.html" },
    addEventListener: (type: string, f: (e: unknown) => void) => {
      listeners[type] = [...(listeners[type] ?? []), f];
    },
    dispatchEvent: () => true,
    CustomEvent: class {},
    getComputedStyle: () => ({ marginTop: "0", marginBottom: "0" }),
    requestAnimationFrame: () => 0,
    console: { error: () => {} },
    Element: class {},
    HTMLInputElement: class {},
    Object,
    JSON,
    Set,
    Math,
    String,
    Array,
    URL,
  };
  win.window = win;
  runInNewContext(code, win);
  const fire = (type: string, e: unknown) => {
    for (const f of listeners[type] ?? []) f(e);
  };
  return { posted, fire, root, created, parent, window: win };
}

const errorsOf = (posted: { method: string; params: Record<string, unknown> }[]) =>
  posted.filter((m) => m.method === "redgiant/error").map((m) => m.params);

describe("the design kit (3.5.12)", () => {
  const PAGE = `<!-- redgiant-artifact {"name":"Conti","version":1} -->
<!doctype html>
<html><head><style>body{color:red}</style><title>Conti</title></head>
<body>
<p>Totale</p>
<script>
nope();
</script>
</body></html>`;

  it("comes after the lockdown, the runtime and the import map, before the page's own CSS", async () => {
    const page = await artifactPage(PAGE, "/preview/T");
    // The lockdown is still the very first script.
    expect(page.indexOf("<script")).toBe(page.indexOf(WEBRTC_LOCKDOWN_TAG));
    const order = [
      WEBRTC_LOCKDOWN_TAG,
      RUNTIME,
      '<script type="importmap">',
      '<style id="rg-kit">',
      "<style>body{color:red}",
    ].map((x) => at(page, x));
    expect([...order].sort((a, b) => a - b)).toEqual(order);
    // In a cascade layer: the page's own rules win whatever their specificity.
    expect(page).toContain(`<style id="rg-kit">${KIT_STYLE}</style>`);
    expect(KIT_STYLE.startsWith("@layer rg-kit{")).toBe(true);
    // A widget gets the same kit with less room (its card gives the air); a fragment too.
    const widget = await widgetPage('<p class="rg-muted">x</p>', "/preview/T");
    expect(widget).toContain(`<style id="rg-kit">${KIT_STYLE_WIDGET}</style>`);
    expect(widget.indexOf("<script")).toBe(widget.indexOf(WEBRTC_LOCKDOWN_TAG));
    expect(at(widget, '<style id="rg-kit">')).toBeLessThan(at(widget, '<p class="rg-muted">'));
    expect(KIT_STYLE).toContain("--rg-pad:16px");
    expect(KIT_STYLE_WIDGET).toContain("--rg-pad:6px");
  });

  it("has both themes, follows the host's, and is transparent (no black box in the chat)", async () => {
    // Light by default, dark by the system or by the host's choice; the host's own values win
    // (inline on the root), the kit's derived tones follow the theme.
    expect(KIT_STYLE).toMatch(/:root\{color-scheme:light dark;--rg-bg:#f6f7f9;--rg-panel:#ffffff;/);
    expect(KIT_STYLE).toMatch(
      /@media \(prefers-color-scheme:dark\)\{:root:not\(\[data-theme=light\]\)\{--rg-bg:#15171c;/,
    );
    expect(KIT_STYLE).toMatch(/:root\[data-theme=dark\]\{color-scheme:dark;--rg-bg:#15171c;/);
    expect(KIT_STYLE).toContain("html{background:transparent;");
    expect(KIT_STYLE).toMatch(/body\{margin:0;padding:var\(--rg-pad\);background:transparent;/);
    // Every ready class the guidance names is there.
    for (const c of [
      "rg-card",
      "rg-grid",
      "rg-row",
      "rg-stack",
      "rg-field",
      "rg-input",
      "rg-stat",
      "rg-stats",
      "rg-delta",
      "rg-result",
      "rg-chip",
      "rg-actions",
      "rg-slider",
      "rg-tabs",
      "rg-muted",
      "rg-primary",
      "rg-ghost",
    ])
      expect(KIT_STYLE, c).toContain(`.${c}`);
    // No native look for checkboxes and radios.
    expect(KIT_STYLE).toMatch(/input:is\(\[type=checkbox\],\[type=radio\]\)\{appearance:none;/);

    const rt = runRuntime(await widgetPage("<p>x</p>", "/preview/T"));
    expect(rt.posted[0]?.method).toBe("ui/notifications/initialized");
    const host = (params: Record<string, unknown>) =>
      rt.fire("message", {
        source: rt.parent,
        data: { method: "ui/notifications/host-context-changed", params },
      });
    host({ theme: "dark", styles: { variables: { "--rg-panel": "#1c1f26", "--bad": "x" } } });
    expect(rt.root.dataset.theme).toBe("dark");
    expect(rt.root.style.colorScheme).toBe("dark");
    expect(rt.root.vars).toEqual({ "--rg-panel": "#1c1f26" });
    host({ theme: "light", styles: { variables: { "--rg-panel": "#ffffff" } } });
    expect(rt.root.dataset.theme).toBe("light");
    expect(rt.root.vars["--rg-panel"]).toBe("#ffffff");
    // Only from its parent.
    rt.fire("message", {
      source: {},
      data: { method: "ui/notifications/host-context-changed", params: { theme: "dark" } },
    });
    expect(rt.root.dataset.theme).toBe("light");
  });
});

describe("errors as the agent reads them (3.5.12)", () => {
  it("says the line in the file's own source and the stack's top, not the served page's", async () => {
    const SRC = `<!doctype html>
<html><head><title>Timer</title></head>
<body>
<button onclick="go()">Via</button>
<script>
function go() {
  startTimer();
}
</script>
</body></html>`;
    const page = await artifactPage(SRC, "/preview/T");
    const served = lineOf(page, "startTimer();");
    expect(served).toBeGreaterThan(7);
    const rt = runRuntime(page);
    rt.fire("error", {
      target: rt.window,
      message: "Uncaught ReferenceError: startTimer is not defined",
      lineno: served,
      colno: 3,
      error: {
        message: "startTimer is not defined",
        stack: `ReferenceError: startTimer is not defined\n    at go (http://rg.local/preview/T/a.html:${served}:3)\n    at HTMLButtonElement.onclick (http://rg.local/preview/T/a.html:${lineOf(page, "Via")}:20)`,
      },
    });
    expect(errorsOf(rt.posted)).toEqual([
      {
        kind: "error",
        message: "Uncaught ReferenceError: startTimer is not defined",
        where: "line 7:3, at go (line 7:3)",
      },
    ]);
  });

  it("keeps the lines after a JSX block right", async () => {
    const SRC = `<!-- redgiant-artifact {"name":"X","version":1,"libs":["react"]} -->
<!doctype html><html><head></head><body><div id="root"></div>
<script type="text/babel">
import { createRoot } from "react-dom/client";


function App() { return <p>ciao</p>; }


createRoot(document.getElementById("root")).render(<App />);
</script>
<script>
boom();
</script>
</body></html>`;
    const page = await artifactPage(SRC, "/preview/T");
    const rt = runRuntime(page);
    rt.fire("error", {
      target: rt.window,
      message: "Uncaught ReferenceError: boom is not defined",
      lineno: lineOf(page, "boom();"),
      colno: 1,
    });
    expect(errorsOf(rt.posted)[0]?.where).toBe("line 13:1");
  });

  it("says [lib] only for a library Rasgeth serves; outside things are blocked, and a picture gets a placeholder", async () => {
    const rt = runRuntime(await artifactPage("<p>x</p>", "/preview/T"));
    rt.fire("error", {
      target: el("SCRIPT", { src: "http://rg.local/preview/T/lib/react-19.0.0/react.js" }),
    });
    rt.fire("error", { target: el("SCRIPT", { src: "https://cdn.example.com/x.js" }) });
    rt.fire("error", { target: el("SCRIPT") });
    const img = el("IMG", { src: "https://example.com/logo.png" });
    img.attrs.width = "120";
    (img as FakeEl & { alt: string }).alt = "Logo";
    rt.fire("error", { target: img });
    const errs = errorsOf(rt.posted);
    expect(errs.map((e) => e.kind)).toEqual(["lib", "blocked", "error", "blocked"]);
    expect(errs[0]?.message).toBe("Could not load the library file react-19.0.0/react.js");
    expect(errs[1]?.message).toMatch(
      /^Could not load the script https:\/\/cdn\.example\.com\/x\.js \(artifacts reach no network/,
    );
    expect(errs[2]?.message).toMatch(/inline <script type=module> did not run/);
    expect(errs[3]?.message).toMatch(
      /^Picture not loaded: https:\/\/example\.com\/logo\.png \(artifacts reach no network: use a data: or blob: URL\)$/,
    );
    // The picture is hidden by the kit and a quiet placeholder stands next to it, in Italian here.
    expect(img.dataset.rgBlocked).toBe("outside");
    expect(KIT_STYLE).toContain("img[data-rg-blocked]{display:none!important}");
    const hole = img.added[0];
    expect(hole?.className).toBe("rg-img-blocked");
    expect(hole?.textContent).toBe("Immagine esterna bloccata");
    expect(hole?.attrs["aria-label"]).toBe("Logo: Immagine esterna bloccata");
    expect(hole?.style.width).toBe("120px");
    // In English with an English host.
    const en = runRuntime(await artifactPage("<p>x</p>", "/preview/T"), "en-US");
    const pic = el("IMG", { src: "https://example.com/a.png" });
    en.fire("error", { target: pic });
    expect(pic.added[0]?.textContent).toBe("External image blocked");
  });

  it("canvas_look tells errors from before the last change as old, and «no errors» after a clean load", () => {
    const errors = new ArtifactErrors();
    const key = ArtifactErrors.fileKey("me", "platform", "artefatti/t.html");
    expect(errors.text(key, 1000)).toBe("");
    errors.reset(key, 2000);
    errors.report(key, "artefatti/t.html", [{ kind: "error", message: "x is not defined" }], []);
    // The file has not changed since that load: the errors are current.
    expect(errors.text(key, 1500)).toBe(
      "It met 1 error: [error] x is not defined in the person's page.",
    );
    // The agent changed the file; the page has not loaded it yet: told as before the change.
    expect(errors.text(key, 3000)).toBe(
      "The person's page has not run your last change yet; before it, the page met 1 error: [error] x is not defined.",
    );
    // The page loads the new version, which says nothing: the list is empty.
    errors.reset(key, 4000);
    expect(errors.text(key, 3000)).toBe("No errors in the person's page since the last change.");
    // Changed again, not loaded yet.
    expect(errors.text(key, 5000)).toBe("The person's page has not run your last change yet.");
  });
});

describe("the widget components (3.8.8)", () => {
  const REFERENCE = readFileSync(
    new URL("./fixtures/widgets/umidita.html", import.meta.url),
    "utf8",
  );
  /** The rg- classes a text names, as `.rg-x` or inside `class="…"`. */
  const classesIn = (text: string) => {
    const out = new Set<string>();
    for (const m of text.matchAll(/\.(rg-[a-z0-9-]+)/g)) out.add(m[1] as string);
    for (const m of text.matchAll(/class="([^"]*)"/g))
      for (const c of (m[1] as string).split(/\s+/)) if (c.startsWith("rg-")) out.add(c);
    return out;
  };
  /** Whether the kit styles a class (as a selector, not inside a word). */
  const styled = (c: string) => new RegExp(`\\.${c}(?![a-z0-9-])`).test(KIT_STYLE_WIDGET);

  it("styles every class the guidance, the canvas help and the reference widget name", () => {
    const named = new Set([
      ...classesIn(ARTIFACT_GUIDANCE),
      ...classesIn(ARTIFACT_HELP),
      ...classesIn(REFERENCE),
    ]);
    // The new components are named and styled.
    for (const c of [
      "rg-head",
      "rg-split",
      "rg-controls",
      "rg-group",
      "rg-range",
      "rg-seg",
      "rg-hero",
      "rg-value",
      "rg-badge",
      "rg-meter",
      "rg-compare",
      "rg-kv",
      "rg-bars",
    ])
      expect(named.has(c), c).toBe(true);
    const missing = [...named].filter((c) => !styled(c));
    expect(missing).toEqual([]);
    // Tones on every component that takes one; a phone gets one column with the result first.
    for (const c of ["rg-hero", "rg-badge", "rg-chip", "rg-result"])
      expect(KIT_STYLE).toMatch(new RegExp(`:is\\([^)]*\\.${c}[^)]*\\)\\.ok\\{`));
    expect(KIT_STYLE).toContain(
      "@media (max-width:560px){.rg-split{grid-template-columns:minmax(0,1fr)}.rg-split>.rg-hero{order:-1}",
    );
    // Choices are drawn: the radio of a segment is invisible but focusable, its focus shown.
    expect(KIT_STYLE).toContain(".rg-seg>label>input{position:absolute;inset:0;");
    expect(KIT_STYLE).toContain("opacity:0");
    expect(KIT_STYLE).toContain(
      ".rg-seg>:is(label:has(>input:focus-visible),button:focus-visible){outline:2px solid",
    );
  });

  it("asks for good-looking widgets, in the same words for every agent and the Chat", () => {
    const look = (g: string) => g.slice(g.indexOf("## How widgets and artifacts look"));
    expect(look(CHAT_ARTIFACT_GUIDANCE)).toBe(look(ARTIFACT_GUIDANCE));
    for (const rule of [
      /A slider whenever the value has a sensible range/,
      /A number field only for free values/,
      /never a wall of fields/,
      /The answer in a \.rg-hero ok\|warn\|bad card \(softly tinted\)/,
      /Never a warning box as the answer/,
      /a short title and one line of what to try/,
      /on a phone it folds to one column, the result first/,
      /Start from the person's own values/,
      /redgiant\.num\(x, decimals\)/,
      /write no design CSS/,
      /Shape of a widget:\n<div class="rg-head">/,
    ])
      expect(ARTIFACT_GUIDANCE).toMatch(rule);
    // It is read on every conversation's first request: it stays short.
    expect(new TextEncoder().encode(ARTIFACT_GUIDANCE).length).toBeLessThan(4800);
  });

  it("the reference widget (humidity after airing) is small, offline and uses the kit's parts", async () => {
    const bytes = new TextEncoder().encode(REFERENCE).length;
    expect(bytes).toBeLessThan(WIDGET_MAX_BYTES / 10);
    // Nothing from outside, no design CSS, no fields where a slider fits, no warning box.
    expect(REFERENCE).not.toMatch(/https?:|<link|@import|<style|style="/i);
    expect(REFERENCE).not.toMatch(/type="number"|rg-result|type="checkbox"/);
    expect(REFERENCE.match(/type="range"/g)?.length).toBe(4);
    for (const c of ["rg-head", "rg-split", "rg-hero", "rg-meter", "rg-compare", "rg-badge"])
      expect(REFERENCE).toContain(c);
    const page = await widgetPage(REFERENCE, "/preview/T");
    expect(page).toContain(`<style id="rg-kit">${KIT_STYLE_WIDGET}</style>`);
  });

  it("asks nothing of the network and runs nothing it did not bring", () => {
    // Every url() of the kit is a picture written in it.
    for (const m of KIT_STYLE.matchAll(/url\(([^)]*)\)/g))
      expect(m[1], m[0]).toMatch(/^"data:image\/svg\+xml,/);
    expect(KIT_STYLE.replace(/url\("data:[^"]*"\)/g, "")).not.toMatch(
      /@import|@font-face|https?:|url\(/,
    );
    expect(KIT_SCRIPT).not.toMatch(
      /fetch\(|XMLHttpRequest|WebSocket|eval\(|new Function|innerHTML|import\(/,
    );
    // The kit stays light: it comes with every widget.
    expect(KIT_STYLE_WIDGET.length).toBeLessThan(40_000);
    expect(KIT_SCRIPT.length).toBeLessThan(9_000);
  });

  it("fills a slider's pill with its value and unit, in the person's language", async () => {
    const wrap = el("LABEL", {
      classList: { contains: (c: string) => c === "rg-range" },
      querySelector: () => null,
      appendChild: (x: FakeEl) => {
        wrap.kids.push(x);
        return x;
      },
    } as Partial<FakeEl>);
    const range = el("INPUT", {
      min: "10",
      max: "30",
      step: "0.5",
      value: "19",
      dataset: { unit: "°C" },
      closest: () => wrap,
    } as Partial<FakeEl>);
    const rt = runRuntime(await widgetPage("<p>x</p>", "/preview/T"), "it-IT", (sel) =>
      sel === "input[type=range]" ? [range] : [],
    );
    expect(rt.created.length).toBeGreaterThan(0);
    const out = wrap.kids[0] as FakeEl;
    expect(out.className).toBe("rg-pill");
    expect(out.attrs["aria-hidden"]).toBe("true");
    expect(out.kids[0]).toBe("19,0");
    expect((out.kids[1] as FakeEl).textContent).toBe("°C");
    expect(range.attrs["aria-valuetext"]).toBe("19,0°C");
    expect(wrap.vars["--rg-frac"]).toBe(String(9 / 20));
    // redgiant.num: the person's language, fixed decimals, a dash for no number.
    const num = (rt.window.redgiant as { num: (x: unknown, d?: number) => string }).num;
    expect(num(12345.678, 1)).toBe("12.345,7");
    expect(num(54.6)).toBe("55");
    expect(num(Number.NaN)).toBe("–");
  });

  it("draws a meter's zones, ticks, marker and start from its data", async () => {
    const meter = el("DIV", {
      dataset: {
        min: "30",
        max: "90",
        zones: "60 70",
        unit: "%",
        value: "77.5",
        from: "68",
        label: "Umidità",
      },
    });
    runRuntime(await widgetPage("<p>x</p>", "/preview/T"), "it-IT", (sel) =>
      sel === ".rg-meter" ? [meter] : [],
    );
    expect(meter.vars["--rg-at"]).toBe(String((77.5 - 30) / 60));
    expect(meter.vars["--rg-from"]).toBe(String((68 - 30) / 60));
    expect(meter.vars["--rg-mark"]).toBe("var(--rg-err)");
    expect(meter.dataset.tone).toBe("bad");
    expect(meter.vars["--rg-scale"]).toBe(
      "linear-gradient(90deg,color-mix(in srgb,var(--rg-ok) 72%,var(--rg-panel)) 0.0% 47.0%,color-mix(in srgb,var(--rg-warn) 72%,var(--rg-panel)) 53.0% 63.7%,color-mix(in srgb,var(--rg-err) 72%,var(--rg-panel)) 69.7% 100.0%)",
    );
    const ticks = meter.kids as FakeEl[];
    expect(ticks.map((t) => t.textContent)).toEqual(["30%", "60%", "70%", "90%"]);
    expect(ticks.map((t) => t.style.left)).toEqual(["0%", "50%", `${(40 / 60) * 100}%`, "100%"]);
    expect(meter.attrs.role).toBe("meter");
    expect(meter.attrs["aria-label"]).toBe("Umidità");
    expect(meter.attrs["aria-valuenow"]).toBe("77.5");
    expect(meter.attrs["aria-valuetext"]).toBe("77,5%");
    // Tones by zone, as a table: below the first zone ok, between warn, after bad.
    for (const [value, tone] of [
      ["45", "ok"],
      ["60", "warn"],
      ["69.9", "warn"],
      ["70", "bad"],
    ] as const) {
      const m = el("DIV", { dataset: { min: "30", max: "90", zones: "60 70", value } });
      runRuntime(await widgetPage("<p>x</p>", "/preview/T"), "it-IT", (sel) =>
        sel === ".rg-meter" ? [m] : [],
      );
      expect(m.dataset.tone, value).toBe(tone);
    }
  });
});
