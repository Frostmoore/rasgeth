// G42.0: the page's side of the embed. Against the demo server with DEMO_CANVAS=1: the test page
// (`#embed=probe`), a PDF and a 3D file in the Canvas without the page's bar, and the page's
// Settings (`#open=settings`), light and dark, computer 1440x900 and phone 390x844; the test page's
// results in Chromium (Android's WebView and WebView2 are Chromium) and WebKit (WKWebView's engine)
// in probe-<engine>.json. The bridge is a stand-in channel that keeps what the page sends.
// Usage: node g42-embed-shots.mjs <url> <token> <outdir>   (the Playwright image)
import { mkdir, writeFile } from "node:fs/promises";
import { chromium, webkit } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const NONCE = "shotsnonce-0123456789";
const hash = (o) =>
  new URLSearchParams({ token, bridge: NONCE, ...o }).toString().replace(/^/, "#");

const embeds = [
  ["probe", { embed: "probe" }],
  ["pdf", { embed: "canvas", scope: "platform", path: "canvas/modulo.pdf" }],
  ["3d", { embed: "canvas", scope: "platform", path: "canvas/stanza.gltf" }],
];

const sent = {};
for (const [engineName, engine] of [
  ["chromium", chromium],
  ["webkit", webkit],
]) {
  const browser = await engine.launch();
  for (const [device, viewport] of [
    ["computer", { width: 1440, height: 900 }],
    ["telefono", { width: 390, height: 844 }],
  ])
    for (const [theme, scheme] of [
      ["chiaro", "light"],
      ["scuro", "dark"],
    ]) {
      // WebKit only for the test page's results (computer, light).
      if (engineName === "webkit" && (device !== "computer" || theme !== "chiaro")) continue;
      const page = await browser.newPage({ viewport, colorScheme: scheme, locale: "it-IT" });
      page.on("pageerror", (e) => console.error(`${engineName} pageerror:`, e.message));
      await page.addInitScript(() => {
        window.__sent = [];
        window.RGEmbed = { postMessage: (s) => window.__sent.push(JSON.parse(s)) };
      });
      for (const [name, o] of embeds) {
        if (engineName === "webkit" && name !== "probe") continue;
        // Reload with the same fragment: the page takes it out at once.
        await page.goto("about:blank");
        await page.goto(
          `${url}/embed.html${hash({ ...o, embed: o.embed, theme: scheme, lang: "it" })}`,
        );
        await page.waitForFunction(() => window.__sent.some((m) => m.m.t === "ready"), null, {
          timeout: 20000,
        });
        await page.waitForTimeout(name === "probe" ? 9000 : 4000);
        if (name === "probe") {
          const r = await page.evaluate(() => window.__rgProbe);
          await writeFile(`${out}/probe-${engineName}.json`, `${JSON.stringify(r, null, 2)}\n`);
        }
        const leaked = await page.evaluate(() => ({
          href: location.href,
          stored: localStorage.getItem("rg.token"),
          bar: !!document.querySelector("header.top, .sidebar"),
        }));
        if (leaked.href.includes("token") || leaked.stored || leaked.bar)
          console.error("embed leaked:", name, JSON.stringify(leaked));
        sent[`${engineName}-${name}`] = await page.evaluate(() => window.__sent.map((m) => m.m));
        await page.screenshot({
          path: `${out}/${engineName === "webkit" ? "webkit-" : ""}embed-${name}-${device}-${theme}.png`,
        });
      }
      if (engineName === "chromium") {
        await page.goto("about:blank");
        await page.evaluate(() => localStorage.clear()).catch(() => {});
        await page.goto(`${url}/#token=${token}&open=settings`);
        await page.waitForTimeout(3500);
        for (let i = 0; i < 3 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
          await page.keyboard.press("Escape");
          await page.waitForTimeout(400);
        }
        await page.screenshot({ path: `${out}/impostazioni-${device}-${theme}.png` });
      }
      await page.close();
    }
  await browser.close();
}
await writeFile(`${out}/sent.json`, `${JSON.stringify(sent, null, 2)}\n`);
console.log("shots in", out);
