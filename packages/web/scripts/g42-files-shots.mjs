// G42.5: the page's side of the comparison with RGCompanion's files. Against the demo server, the
// Demo orchestrator's conversation with the top bar's folder open (src and docs open, then the
// hidden files), and the archived Old site read only; light and dark, computer 1440x900 and
// phone 390x844.
// Usage: node g42-files-shots.mjs <url> <token> <outdir>   (a Chromium: the Playwright image)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();

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
    const shot = (n, what) =>
      page.screenshot({ path: `${out}/web-${device}-${theme}-${String(n).padStart(2, "0")}-${what}.png` });
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForTimeout(2500);
    for (let i = 0; i < 3 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
      await page.keyboard.press("Escape");
      await page.waitForTimeout(400);
    }
    const openConversation = async (project, title) => {
      if (device === "telefono") {
        for (const sel of [".menu-button", "[aria-label='Menu']", ".icon-button.menu"]) {
          const b = page.locator(sel).first();
          if (await b.isVisible().catch(() => false)) {
            await b.click();
            break;
          }
        }
        await page.waitForTimeout(600);
      }
      const p = page.locator(".bar-item", { hasText: project }).first();
      if (await p.isVisible().catch(() => false)) await p.click();
      await page.waitForTimeout(600);
      await page
        .locator(".session-row", { hasText: title })
        .first()
        .click({ force: true })
        .catch(() => {});
      await page.waitForTimeout(1500);
    };
    await openConversation("Demo", "Give me a quick tour of the project");
    await shot(1, "conversazione");
    const folder = page.locator(".top .icon-button[aria-label='File del progetto e terminale']");
    await folder.first().click();
    await page.waitForSelector(".explorer .tree-row");
    await page.waitForTimeout(600);
    await shot(2, "file");
    for (const name of ["src", "docs"]) {
      await page.locator(".explorer .tree-row", { hasText: name }).first().click();
      await page.waitForTimeout(500);
    }
    await shot(3, "cartelle-aperte");
    await page.locator(".explorer-head .icon-button[title='Mostra i file nascosti']").click();
    await page.waitForTimeout(600);
    await shot(4, "nascosti");
    await page.close();
  }
await browser.close();
