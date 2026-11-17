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
    // A window opened by itself (what's new, a request): put away, before every step.
    const calm = async () => {
      for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
        await page.keyboard.press("Escape");
        await page.waitForTimeout(400);
        if ((await page.locator(".ui-modal-veil").count()) > 0)
          await page.locator(".ui-modal-veil").first().click({ force: true }).catch(() => {});
        await page.waitForTimeout(300);
      }
      if ((await page.locator(".ui-modal-veil").count()) > 0) {
        // One that will not close (a request waiting for the person): seen once, then set aside.
        await page.screenshot({ path: `${out}/debug-${device}-${theme}-window.png` });
        const yes = page.locator(".ui-modal button", { hasText: /Più tardi|Chiudi|Annulla|Nega/ });
        if (await yes.count()) await yes.first().click({ force: true }).catch(() => {});
        await page.waitForTimeout(400);
        await page.evaluate(() => {
          for (const e of document.querySelectorAll(".ui-modal-back")) e.remove();
        });
      }
    };
    await calm();
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
      await calm();
      const row = page.locator(".session-row", { hasText: title }).first();
      if (!(await row.isVisible().catch(() => false))) {
        await page.getByText(project, { exact: true }).first().click();
        await page.waitForTimeout(800);
      }
      await page
        .locator(".session-row", { hasText: title })
        .first()
        .click({ force: true })
        .catch(() => {});
      await page.waitForTimeout(1500);
    };
    await openConversation("Demo", "Give me a quick tour of the project");
    await calm();
    await shot(1, "conversazione");
    const folder = page.locator(".top .icon-button[aria-label='File del progetto e terminale']");
    await calm();
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
    await calm();
    // The archived project (DEMO_ARCHIVE=1): its page, «Mostra i file», read only.
    try {
      await calm();
      if (device === "telefono") {
        await page.locator(".icon-button.menu").first().click();
        await page.waitForTimeout(600);
      }
      const arch = page.getByText(/^Archiviati/).first();
      if (await arch.isVisible().catch(() => false)) await arch.click();
      await page.waitForTimeout(400);
      await page.getByText("Old site", { exact: true }).first().click();
      await page.waitForTimeout(1200);
      const show = page.locator("button", { hasText: "Mostra i file" }).first();
      if (await show.isVisible().catch(() => false)) await show.click();
      await page.waitForTimeout(1000);
      await shot(5, "archiviato-sola-lettura");
    } catch (e) {
      console.error("archived:", e.message);
    }
    await page.close();
  }
await browser.close();
