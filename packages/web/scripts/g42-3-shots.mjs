// G42.3: the page's side of the comparison with RGCompanion. Against the demo server with
// DEMO_SUBAGENTS=1: God's conversation with its sub-agents' tabs and the background commands (a
// command's output, each sub-agent), the group chat «December release», the Chats, the earlier
// chat, the project's board with a thread, and the agents' browser; light and dark, computer
// 1440x900 and phone 390x844. Each view opens as the page would keep it open (`rg.tabs`).
// Usage: node g42-3-shots.mjs <url> <token> <outdir> <subSession> <godId>
//   ($PLAYWRIGHT: where playwright-core is, when this tree has no node_modules of its own)
import { mkdir } from "node:fs/promises";
import { pathToFileURL } from "node:url";

const { chromium } = await import(
  process.env.PLAYWRIGHT ? pathToFileURL(process.env.PLAYWRIGHT).href : "playwright-core"
);
const [url, token, out, sub, god] = process.argv.slice(2);
await mkdir(out, { recursive: true });
const api = async (path) =>
  (await fetch(`${url}${path}`, { headers: { authorization: `Bearer ${token}` } })).json();
const rooms = await api("/api/rooms");
const room = rooms.find((r) => r.title === "December release");
const chats = await api("/api/chats");
const agents = await api("/api/agents");
const assistant = agents.find((a) => a.kind === "assistant" && a.status === "active");
const browser = await chromium.launch();

const views = [
  ["01-linguette", { id: `chat:${sub}`, type: "chat", title: "God", sessionId: sub, agentId: god }],
  ["05-stanza", { id: `room:${room.id}`, type: "room", title: room.title, roomId: room.id }],
  ["06-chat", { id: "chats", type: "chats", title: "Chat" }],
  [
    "08-chat-di-prima",
    { id: `daily:${chats[0]?.id}`, type: "dailychat", title: chats[0]?.title, chatId: chats[0]?.id },
  ],
  ["09-bacheca", { id: "board:demo", type: "board", title: "Bacheca · Demo", projectId: "demo" }],
  [
    "11-browser",
    { id: `assistant:${assistant?.id}`, type: "assistant", title: assistant?.name, agentId: assistant?.id },
  ],
];

for (const [device, viewport] of [
  ["computer", { width: 1440, height: 900 }],
  ["telefono", { width: 390, height: 844 }],
])
  for (const [theme, scheme] of [
    ["chiaro", "light"],
    ["scuro", "dark"],
  ])
    for (const [name, tab] of views) {
      const page = await browser.newPage({ viewport, colorScheme: scheme, locale: "it-IT" });
      page.on("pageerror", (e) => console.error("pageerror:", e.stack));
      await page.addInitScript((t) => {
        if (sessionStorage.getItem("g42-3")) return;
        sessionStorage.setItem("g42-3", "1");
        localStorage.clear();
        localStorage.setItem("rg.tabs", JSON.stringify({ tabs: [t], active: t.id }));
      }, tab);
      await page.goto(`${url}/#token=${token}`);
      await page.waitForTimeout(3000);
      for (let i = 0; i < 3 && (await page.locator(".ui-modal-veil").count()) > 0; i++) {
        await page.keyboard.press("Escape");
        await page.waitForTimeout(400);
      }
      const shot = (what) =>
        page.screenshot({ path: `${out}/web-${device}-${theme}-${what}.png` });
      await shot(name);
      if (name === "01-linguette") {
        const output = page.locator(".cmd-row button.link", { hasText: "Output" }).first();
        if (await output.isVisible().catch(() => false)) {
          await output.click();
          await page.waitForTimeout(2500);
          await shot("02-output");
          await page.keyboard.press("Escape");
          await page.waitForTimeout(500);
        }
        const toggle = page.locator(".cmd-done-toggle").first();
        if (await toggle.isVisible().catch(() => false)) {
          await toggle.click();
          await page.waitForTimeout(500);
          await shot("03-comandi-finiti");
          await toggle.click();
        }
        const tabs = page.locator(".sub-row").first().locator(".sub-tab-main");
        const n = await tabs.count();
        for (let i = 0; i < n; i++) {
          await tabs.nth(i).click();
          await page.waitForTimeout(1500);
          await shot(`04-sotto-agente-${i + 1}`);
        }
      }
      if (name === "06-chat") {
        await page.evaluate(() => {
          const el = document.querySelector(".chats-page");
          el?.scrollTo(0, el.scrollHeight);
          (el?.parentElement ?? document.scrollingElement)?.scrollTo(0, 1e6);
        });
        await page.waitForTimeout(500);
        await shot("07-chat-gruppi");
      }
      if (name === "09-bacheca") {
        const thread = page.locator(".thread-item").first();
        if (await thread.isVisible().catch(() => false)) {
          await thread.click();
          await page.waitForTimeout(1200);
          await shot("10-thread");
        }
      }
      if (name === "11-browser") {
        const open = page.locator("button", { hasText: "Schermo" }).first();
        if (await open.isVisible().catch(() => false)) {
          await open.click();
          await page.waitForTimeout(2500);
          await shot("11-browser-assente");
        }
      }
      await page.close();
    }
await browser.close();
