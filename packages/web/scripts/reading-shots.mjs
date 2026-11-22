// 3.10.4: the answers' «Lettura comoda» in every accent, light and dark, computer and phone, and the
// accent's swatches in Settings > General. Against a demo started with DEMO_READING=1.
// Usage: node reading-shots.mjs <url> <token> <outdir>   (the Playwright image has a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();
const ACCENTS = (process.env.ACCENTS ?? "red blue amber").split(" ");
const SCREENS = Object.fromEntries(
  Object.entries({
    computer: { width: 1366, height: 900 },
    phone: { width: 390, height: 844 },
  }).filter(([k]) => (process.env.SCREENS ?? "computer phone").split(" ").includes(k)),
);

for (const [screen, viewport] of Object.entries(SCREENS)) {
  for (const theme of ["light", "dark"]) {
    for (const accent of ACCENTS) {
      const page = await browser.newPage({ viewport, colorScheme: theme, locale: "it-IT" });
      page.on("pageerror", (e) => console.error("pageerror:", e.message));
      await page.addInitScript(
        ([t, a]) => {
          localStorage.setItem("rg.theme", t);
          localStorage.setItem("rg.accent", a);
          localStorage.setItem("rg.lang", "it");
          localStorage.setItem("rg.newsSeen", "99.0.0");
        },
        [theme, accent],
      );
      await page.goto(`${url}/#token=${token}`);
      await page.waitForSelector(".top");
      // The Playwright image's default sans has no bold: one that has, as on a person's device.
      await page.addStyleTag({ content: 'body { font-family: "Liberation Sans", sans-serif; }' });
      // Any window that opens by itself (a notice): closed.
      for (let i = 0; i < 3; i++) {
        const veil = page.locator(".ui-modal-veil");
        if (!(await veil.count())) break;
        await page.keyboard.press("Escape");
        await page.waitForTimeout(200);
      }
      if (screen === "phone") {
        await page.locator('button[aria-label="Menu"]').click();
        await page.waitForTimeout(400);
      }
      await page.locator(".bar-item", { hasText: "Demo" }).first().click();
      await page.waitForTimeout(400);
      // On a phone the project opens its page and the menu closes: open it again, the project's
      // conversations under it.
      if (!(await page.getByText("Rilascio di dicembre").first().isVisible())) {
        if (screen === "phone") await page.locator('button[aria-label="Menu"]').click();
        await page.waitForTimeout(400);
      }
      await page.getByText("Rilascio di dicembre").first().click();
      await page.waitForSelector(".bubble.assistant .md-read h1");
      await page.waitForTimeout(400);
      // The answer from its title down.
      await page.evaluate(() =>
        document.querySelector(".bubble.assistant .md-read h1")?.scrollIntoView({ block: "start" }),
      );
      await page.waitForTimeout(200);
      await page.screenshot({ path: `${out}/${screen}-${theme}-${accent}.png` });
      if (accent === ACCENTS[0]) {
        await page.evaluate(() =>
          document
            .querySelector(".bubble.assistant .md-read pre")
            ?.scrollIntoView({ block: "end" }),
        );
        await page.waitForTimeout(200);
        await page.screenshot({ path: `${out}/${screen}-${theme}-${accent}-fine.png` });
      }
      await page.close();
    }
  }
}
console.log("done");
await browser.close();
