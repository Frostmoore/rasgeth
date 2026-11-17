// 3.8.7: the app's frame in a real browser engine (Chromium, as Android's WebView and WebView2 are):
// loads the wrapper pages the relay serves (tool/relay_probe.dart), stands in for the app's channel
// (`RGHost`, in the top page only, as the app's web view would get it), and checks what the app
// relies on: the frame's messages arrive with the wrapper's nonce, its height, the theme reaching
// it, a click in it, its errors, and that nothing leaves 127.0.0.1. Screenshots of each step.
//
//   PW_FROM=<a folder whose node_modules has playwright-core> node tool/frame_probe.mjs <relay.json> <shots>
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const info = JSON.parse(readFileSync(process.argv[2], "utf8"));
const shots = process.argv[3];
mkdirSync(shots, { recursive: true });
const req = createRequire(join(process.env.PW_FROM ?? process.cwd(), "x.js"));
const pw = await import(pathToFileURL(req.resolve("playwright-core")).href);
const chromium = pw.chromium ?? pw.default.chromium;

// The app's colours (lib/theme/colors.dart = the page's styles.css), as hostContext sends them.
const vars = (dark) =>
  dark
    ? { "--rg-bg": "#15171c", "--rg-panel": "#1c1f26", "--rg-panel-2": "#252932", "--rg-line": "#313642", "--rg-text": "#e8e6e3", "--rg-dim": "#8f96a3", "--rg-accent": "#ef4b3a", "--rg-accent-2": "#ff7a68", "--rg-accent-soft": "#3a1f1c", "--rg-ok": "#2e9d5b", "--rg-warn": "#c99a14", "--rg-warn-text": "#e0b23a", "--rg-err": "#d23d3d", "--rg-radius": "10px" }
    : { "--rg-bg": "#f6f7f9", "--rg-panel": "#ffffff", "--rg-panel-2": "#eef0f4", "--rg-line": "#dde1e8", "--rg-text": "#1c2230", "--rg-dim": "#6b7385", "--rg-accent": "#d23a2c", "--rg-accent-2": "#b8301f", "--rg-accent-soft": "#fbe0dc", "--rg-ok": "#2e9d5b", "--rg-warn": "#c99a14", "--rg-warn-text": "#7a5600", "--rg-err": "#d23d3d", "--rg-radius": "10px" };
const theme = (dark) => ({
  jsonrpc: "2.0",
  method: "ui/notifications/host-context-changed",
  params: { theme: dark ? "dark" : "light", locale: "it", styles: { variables: vars(dark) } },
});

const browser = await chromium.launch();
const report = { outside: [] };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function open(name, entry, viewport) {
  const ctx = await browser.newContext({ viewport, deviceScaleFactor: 2, locale: "it-IT" });
  // The app's channel, only in the wrapper (the top page): the frame has no way to the app.
  await ctx.addInitScript(() => {
    if (window !== window.top) return;
    window.__got = [];
    window.RGHost = { postMessage: (s) => window.__got.push(s) };
  });
  ctx.on("request", (r) => {
    const u = new URL(r.url());
    if (u.hostname !== "127.0.0.1" && u.protocol.startsWith("http")) report.outside.push(r.url());
  });
  const page = await ctx.newPage();
  await page.goto(entry.wrapper);
  const got = async () =>
    (await page.evaluate(() => window.__got)).map((s) => JSON.parse(s));
  const wait = async (ok, ms = 15000) => {
    const end = Date.now() + ms;
    while (Date.now() < end) {
      const g = await got();
      if (ok(g)) return g;
      await sleep(100);
    }
    return got();
  };
  const post = (m) => page.evaluate((s) => window.__rgPost(s), m);
  const r = { name };
  const all = await wait((g) => g.some((x) => x.d?.method === "ui/notifications/initialized"));
  r.initialized = all.some((x) => x.d?.method === "ui/notifications/initialized");
  r.allWithNonce = all.every((x) => x.n === entry.nonce);
  r.loads = all.filter((x) => x.k === "load").length;
  return { ctx, page, got, wait, post, r };
}

// The widget, light then dark, as wide as a phone's chat.
{
  const w = await open("widget", info.widget, { width: 400, height: 900 });
  await w.post(theme(false));
  let g = await w.wait((g) => g.some((x) => x.d?.method === "ui/notifications/size-changed"));
  const heights = g.filter((x) => x.d?.method === "ui/notifications/size-changed").map((x) => x.d.params.height);
  w.r.height = heights.at(-1);
  await sleep(600);
  const h = Math.ceil((await w.got()).filter((x) => x.d?.method === "ui/notifications/size-changed").map((x) => x.d.params.height).at(-1) ?? 300);
  await w.page.setViewportSize({ width: 400, height: h });
  await w.page.screenshot({ path: join(shots, "g387-chromium-01-widget-light.png") });
  await w.post(theme(true));
  await w.page.evaluate(() => {
    document.documentElement.style.background = "#1c1f26";
  });
  await sleep(500);
  await w.page.screenshot({ path: join(shots, "g387-chromium-02-widget-dark.png") });
  w.r.darkSeen = await w.page.frames().find((f) => f.url().includes("/preview/"))?.evaluate(() => document.documentElement.dataset.theme);
  // A click on its button: the wrapper says «click» (focus went to the frame) or has the user
  // activation, then the frame's «send to chat».
  const frame = w.page.frames().find((f) => f.url().includes("/preview/"));
  const before = (await w.got()).length;
  await frame.click("button");
  g = await w.wait((g) => g.slice(before).some((x) => x.d?.method === "ui/message"), 5000);
  const after = g.slice(before);
  w.r.clickEvent = after.some((x) => x.k === "click");
  const m = after.find((x) => x.d?.method === "ui/message");
  w.r.message = m?.d?.params?.content?.[0]?.text;
  w.r.messageFocused = m?.f;
  w.r.messageActivated = m?.a;
  // The frame cannot reach the wrapper's window, nor the app's channel.
  w.r.frameSeesTop = await frame.evaluate(() => {
    try {
      return String(window.top.location.href);
    } catch {
      return "blocked";
    }
  });
  w.r.frameHasChannel = await frame.evaluate(() => typeof window.RGHost);
  w.r.frameFetch = await frame.evaluate(() =>
    fetch("https://example.com/").then(
      () => "reached",
      (e) => `blocked: ${e.message}`,
    ),
  );
  report.widget = w.r;
  await w.ctx.close();
}

// The artifact, as the Canvas shows it.
{
  const a = await open("artifact", info.artifact, { width: 900, height: 640 });
  await a.post(theme(false));
  await sleep(3000);
  await a.page.screenshot({ path: join(shots, "g387-chromium-03-artifact.png") });
  const g = await a.got();
  a.r.errors = g.filter((x) => x.d?.method === "redgiant/error").map((x) => x.d.params);
  report.artifact = a.r;
  await a.ctx.close();
}
await browser.close();
writeFileSync(join(shots, "frame_probe.json"), `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
