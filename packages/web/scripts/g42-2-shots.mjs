// G42.2: the page's side of the comparison with RGCompanion. Against the demo server with
// DEMO_ARTIFACTS=1 DEMO_PORT=1: the board of variants (from its link, `#tavola=`, as Telegram
// sends it) and an agent's port as the page shows it inside the app (`/embed.html#embed=port`),
// light and dark, computer 1440x900 and phone 390x844. Settings › Artifacts: settings-shots.mjs.
// Usage: node g42-2-shots.mjs <url> <token> <outdir> <board session.proposal> <agent> <port>
//   (a Chromium: the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out, board, agent, port] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const nonce = "shots-nonce-0123456789";

for (const [device, viewport] of [
  ["computer", { width: 1440, height: 900 }],
  ["telefono", { width: 390, height: 844 }],
])
  for (const [theme, scheme] of [
    ["chiaro", "light"],
    ["scuro", "dark"],
  ]) {
    const page = await browser.newPage({ viewport, colorScheme: scheme, locale: "it-IT" });
    page.on("pageerror", (e) => console.error("pageerror:", e.stack));
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate((t) => {
      localStorage.clear();
      localStorage.setItem("rg.theme", t);
    }, scheme);
    // A new load (a fragment alone would not read the link again).
    await page.goto("about:blank");
    await page.goto(`${url}/#token=${token}&tavola=${board}`);
    await page.waitForSelector(".tavola-variant", { timeout: 20000 }).catch(async (e) => {
      await page.screenshot({ path: `${out}/debug-tavola-${device}-${theme}.png` });
      throw e;
    });
    for (let i = 0; i < 3 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(400);
    }
    await page.waitForTimeout(2500);
    await page.screenshot({ path: `${out}/web-tavola-${device}-${theme}.png` });
    await page.close();

    const embed = await browser.newPage({ viewport, colorScheme: scheme, locale: "it-IT" });
    embed.on("pageerror", (e) => console.error("pageerror:", e.stack));
    await embed.goto(
      `${url}/embed.html#token=${token}&embed=port&bridge=${nonce}&agent=${agent}&port=${port}&theme=${scheme}&lang=it`,
    );
    await embed.waitForTimeout(4000);
    await embed.screenshot({ path: `${out}/web-porta-${device}-${theme}.png` });
    // One variant alone, as each frame of the app's board shows it.
    const [s, p] = board.split(".");
    await embed.goto("about:blank");
    await embed.goto(
      `${url}/embed.html#token=${token}&embed=board&bridge=${nonce}&board=${s}.${p}&variant=1&screen=phone&theme=${scheme}&lang=it`,
    );
    await embed.waitForTimeout(3000);
    await embed.screenshot({ path: `${out}/web-variante-${device}-${theme}.png` });
    await embed.close();
  }
await browser.close();
