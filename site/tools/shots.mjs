#!/usr/bin/env node
// Screenshots of the site to look at it: both pages, computer and phone, light and dark, it and
// en. Serves site/ on a local port (GitHub's API is blocked, as when it does not answer, unless
// `--live`), then writes <outdir>/<page>-<device>-<theme>-<lang>.png.
// Needs a Chromium: run it in the Playwright image, for example
//   docker run --rm -v "$PWD:$PWD" -w "$PWD" mcr.microsoft.com/playwright:v1.64.1-noble \
//     node site/tools/shots.mjs /mnt/archive1/officina-dati/rg-test/site-rasgeth
import { readFile } from "node:fs/promises";
import { mkdirSync } from "node:fs";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { dirname, extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const SITE = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const out = process.argv[2];
if (!out) throw new Error("usage: shots.mjs <outdir> [--live]");
const live = process.argv.includes("--live");
mkdirSync(out, { recursive: true });

const { chromium } = createRequire(join(SITE, "..", "packages", "web", "package.json"))(
  "playwright-core",
);
const TYPES = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".png": "image/png", ".svg": "image/svg+xml" };
const server = createServer(async (req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, "http://x").pathname)).replace(/^\/+/, "");
  const file = join(SITE, path === "" ? "index.html" : path);
  if (!file.startsWith(SITE)) return res.writeHead(403).end();
  try {
    const body = await readFile(file);
    res.writeHead(200, { "content-type": TYPES[extname(file)] ?? "application/octet-stream" }).end(body);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise((ok) => server.listen(0, "127.0.0.1", ok));
const base = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch();
const devices = {
  desktop: { viewport: { width: 1366, height: 860 }, deviceScaleFactor: 1 },
  phone: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
};
for (const page of ["index", "download", "security", "privacy"]) {
  for (const [device, opts] of Object.entries(devices)) {
    for (const theme of ["light", "dark"]) {
      for (const lang of ["it", "en"]) {
        const ctx = await browser.newContext({
          ...opts,
          colorScheme: theme,
          locale: lang === "it" ? "it-IT" : "en-US",
          reducedMotion: "reduce",
        });
        if (!live) await ctx.route("https://api.github.com/**", (r) => r.abort());
        const p = await ctx.newPage();
        await p.goto(`${base}${page}.html`, { waitUntil: "networkidle" });
        // Lazy images load only near the viewport: walk down the page once.
        await p.evaluate(async () => {
          for (let y = 0; y < document.documentElement.scrollHeight; y += 600) {
            window.scrollTo(0, y);
            await new Promise((r) => setTimeout(r, 60));
          }
          window.scrollTo(0, 0);
        });
        await p.waitForTimeout(500);
        const file = join(out, `${page}-${device}-${theme}-${lang}.png`);
        await p.screenshot({ path: file, fullPage: true });
        console.log(file);
        // The same page in slices, easier to look at closely (<outdir>/parts/).
        const height = await p.evaluate(() => document.documentElement.scrollHeight);
        const step = device === "phone" ? 1300 : 1100;
        mkdirSync(join(out, "parts"), { recursive: true });
        for (let y = 0, i = 1; y < height; y += step, i++) {
          const clip = { x: 0, y, width: opts.viewport.width, height: Math.min(step, height - y) };
          await p.screenshot({ path: join(out, "parts", `${page}-${device}-${theme}-${lang}-${i}.png`), fullPage: true, clip });
        }
        await ctx.close();
      }
    }
  }
}
await browser.close();
server.close();
