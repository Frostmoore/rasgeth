// 3.12: Settings > Rules (the person's rules), dark and light, on a computer and on a phone: the
// page with a stop in place, the editor, God's magic rule beside its conversation, the history.
// Usage: DEMO_RULES=1 demo-server, then node rules-shots.mjs <url> <token> <outdir> (needs a
// Chromium: the Playwright image has one).
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();

async function closeWindows(page) {
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(250);
  }
}

for (const [device, width, height] of [
  ["desk", 1440, 900],
  ["phone", 390, 844],
]) {
  for (const scheme of ["dark", "light"]) {
    const page = await browser.newPage({
      viewport: { width, height },
      colorScheme: scheme,
      locale: "it-IT",
    });
    page.on("pageerror", (e) => console.error("pageerror:", e.message));
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(800);
    await closeWindows(page);
    if (device === "phone") {
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    }
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    if (device === "phone") {
      await page.locator(".st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item", { hasText: "Regole" }).first().click();
    } else await page.locator(".settings-nav .st-nav-item", { hasText: "Regole" }).first().click();
    await page.waitForSelector(".rl-page");
    await page.waitForTimeout(900);
    const base = `${out}/${device}-${scheme}`;
    await page.screenshot({ path: `${base}-01-pagina.png` });
    await page.locator(".rl-card").first().scrollIntoViewIfNeeded();
    await page.screenshot({ path: `${base}-02-regole.png` });
    // The editor on the first rule.
    await page.locator(".rl-card .wz-btn", { hasText: "Cambia" }).first().click();
    await page.waitForSelector(".rl-editor");
    await page.locator(".rl-editor .wz-btn", { hasText: "Prova" }).click();
    await page.waitForTimeout(600);
    await page.screenshot({ path: `${base}-03-editor.png` });
    await page.locator(".rl-examples").scrollIntoViewIfNeeded();
    await page.screenshot({ path: `${base}-04-editor-prova.png` });
    await closeWindows(page);
    // The history.
    await page.locator(".rl-card .wz-btn", { hasText: "Storia" }).first().click();
    await page.waitForSelector(".rl-history");
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${base}-05-storia.png` });
    await closeWindows(page);
    // God's magic rule beside its conversation.
    await page.locator(".rl-magic-item").first().click();
    await page.waitForSelector(".mg-proposal");
    await page.waitForTimeout(1200);
    await page.screenshot({ path: `${base}-06-magica.png` });
    await closeWindows(page);
    // The magic start.
    await page.locator(".rl-start .wz-btn", { hasText: "Regola magica" }).click();
    await page.waitForSelector(".mg-start");
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${base}-07-magica-avvio.png` });
    await page.close();
  }
}
await browser.close();
