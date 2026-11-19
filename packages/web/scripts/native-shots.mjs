// The model's own generation (3.9.2): the picture an engine drew, in place in the chat and big in
// the Canvas; the «generating a picture» card; a picture by a path and one that cannot be read,
// said plainly; the setting in Settings › Extensions. Dark and light, computer and phone.
// Usage: node native-shots.mjs <url> <token> <outdir>   (demo with DEMO_NATIVE=1; needs a Chromium)
import { mkdir } from "node:fs/promises";
import { chromium } from "playwright-core";

const [url, token, out] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const browser = await chromium.launch();

async function closeWindows(page) {
  for (let i = 0; i < 4 && (await page.locator(".ui-modal-veil").count()); i++) {
    await page.keyboard.press("Escape");
    await page.waitForTimeout(200);
    if (await page.locator(".ui-modal-veil").count())
      await page.locator(".ui-modal-veil").first().click({ force: true });
    await page.waitForTimeout(200);
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
    const shot = (name) =>
      page.screenshot({ path: `${out}/pagina-${device}-${scheme}-${name}.png` });
    await page.goto(`${url}/#token=${token}`);
    await page.evaluate(() => localStorage.clear());
    await page.goto(`${url}/#token=${token}`);
    await page.waitForSelector(".bar, .top");
    await page.waitForTimeout(1200);
    await closeWindows(page);
    /** The page again with nothing open beside the chat (the Canvas covers a phone). */
    const fresh = async () => {
      await page.evaluate(() => localStorage.clear());
      await page.goto(`${url}/#token=${token}`);
      await page.waitForSelector(".bar, .top");
      await page.waitForTimeout(800);
      await closeWindows(page);
      // The Canvas stays open from before (it narrows the settings): closed.
      for (
        let i = 0;
        i < 4 && (await page.locator('.side-area button.icon-button[title^="Chiudi"]').count());
        i++
      ) {
        await page
          .locator('.side-area button.icon-button[title^="Chiudi"]')
          .first()
          .click({ force: true });
        await page.waitForTimeout(300);
      }
      // On a phone the Canvas covers the chat: back to it.
      if (device === "phone" && (await page.locator(".side-to-chat").isVisible())) {
        await page.locator(".side-to-chat").click();
        await page.waitForTimeout(400);
      }
    };
    const open = async (title) => {
      if (device === "phone") {
        await page.locator('button[aria-label="Menu"]').click();
        await page.waitForTimeout(300);
      }
      if (!(await page.getByText("Grafica", { exact: true }).count()))
        await page.locator(".bar").getByText("Agenti", { exact: true }).first().click();
      await page.waitForTimeout(300);
      if (!(await page.getByText(title, { exact: true }).count()))
        await page.getByText("Grafica", { exact: true }).first().click();
      await page.waitForTimeout(300);
      await page.getByText(title, { exact: true }).first().click();
      await page.waitForTimeout(600);
      await closeWindows(page);
    };

    // The engine's picture, in place, with Open and Save under it.
    await open("Disegna una stella (Codex)");
    await page.waitForSelector(".chat-image.ok", { timeout: 15_000 });
    await page.waitForTimeout(400);
    await shot("01-immagine-in-chat");
    await page
      .locator(".file-card")
      .first()
      .screenshot({
        path: `${out}/pagina-${device}-${scheme}-01b-card.png`,
      });
    // A press opens it big in the Canvas.
    await page.locator(".chat-image").first().click();
    await page.waitForTimeout(1200);
    await shot("02-canvas");

    // Being drawn: the card says so (no «reading the context»).
    await fresh();
    await open("Disegna lentamente (Codex)");
    await page.waitForSelector(".drawing", { timeout: 15_000 });
    await page.waitForTimeout(600);
    await shot("03-sta-generando");

    // A picture by a path, and one whose file is gone.
    await open("Immagine per percorso");
    await page.waitForSelector(".chat-image.bad", { timeout: 15_000 });
    await page.waitForTimeout(400);
    await shot("04-non-disponibile");

    // The setting, in Settings › Extensions.
    await fresh();
    if (device === "phone") {
      await page.locator('button[aria-label="Menu"]').click();
      await page.waitForTimeout(300);
    }
    await page.locator(".bar-settings").click();
    await page.waitForSelector(".settings");
    await page.waitForTimeout(500);
    if (device === "phone") {
      await page.locator(".st-pick").click();
      await page.locator(".st-sheet-list .st-nav-item", { hasText: "Estensioni" }).first().click();
    } else
      await page.locator(".settings-nav .st-nav-item", { hasText: "Estensioni" }).first().click();
    await page.waitForTimeout(900);
    const row = page.locator(".st-switch-row", { hasText: "Usa lo strumento del modello" });
    await row.scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    await shot("05-impostazione");
    await row.screenshot({ path: `${out}/pagina-${device}-${scheme}-05b-interruttore.png` });
    await page.close();
  }
}
await browser.close();
console.log("done");
