// @vitest-environment jsdom
// Search widgets on the page (3.12.2): found.shown becomes an item (from the log, so it survives a
// reload), the gallery shows one big and four small with «All», broken pictures a placeholder and
// no referrer, trains and flights as rows whose «Choose» writes to the agent (never books), a route
// as a drawn map with mode chips and «Open in Maps»; and every widget has the same fixed width.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { Event, FoundWidget } from "@redgiant/protocol";
import { cleanup, fireEvent, render } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { setLang } from "../src/i18n.js";

const sent: Array<[string, string]> = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  sendInChat: (sessionId: string, text: string) => {
    sent.push([sessionId, text]);
    return true;
  },
}));
const { buildItems } = await import("../src/state.js");
const { FoundCard, chooseText, minutesText, distanceText } = await import(
  "../src/components/FoundWidgets.js"
);
const { drawRoute } = await import("../src/found-map.js");
const { Stars } = await import("../src/components/ProductCards.js");

const gallery: FoundWidget = {
  kind: "gallery",
  title: "Fontana di Trevi",
  source: "Wikimedia",
  images: Array.from({ length: 7 }, (_, i) => ({
    url: `https://img.example/${i}.jpg`,
    thumbUrl: `https://img.example/t${i}.jpg`,
    title: `Foto ${i}`,
    pageUrl: `https://page.example/${i}`,
  })),
};
const trips: FoundWidget = {
  kind: "trips",
  mode: "train",
  from: "Milano C.le",
  to: "Roma Termini",
  date: "ven 27 nov",
  operators: "Trenitalia e Italo",
  offers: [
    {
      departs: "06:20",
      arrives: "09:15",
      duration: "2 h 55",
      stops: 0,
      label: "Frecciarossa 9505",
      operator: "Trenitalia",
      price: 39.9,
      currency: "EUR",
      availability: "posti liberi",
    },
    {
      departs: "07:35",
      arrives: "10:45",
      stops: 1,
      label: "Frecciarossa 9515",
      price: 29.9,
      currency: "EUR",
    },
  ],
};
const route: FoundWidget = {
  kind: "route",
  from: { name: "Termini", lat: 41.9009, lon: 12.5016 },
  to: { name: "Colosseo", lat: 41.8902, lon: 12.4922 },
  points: [
    { lat: 41.9009, lon: 12.5016 },
    { lat: 41.8955, lon: 12.4985 },
    { lat: 41.8902, lon: 12.4922 },
  ],
  options: [
    {
      mode: "walk",
      durationMin: 22,
      distanceM: 1700,
      steps: [
        { text: "Esci su piazza dei Cinquecento", minute: 0 },
        { text: "Via Cavour", minute: 12 },
      ],
    },
    { mode: "transit", durationMin: 8, steps: [{ text: "Metro B, 2 fermate" }] },
  ],
  note: "Con la metro B sono 2 fermate.",
};

beforeEach(() => {
  setLang("it");
  sent.length = 0;
});
afterEach(cleanup);

describe("search widgets (3.12.2)", () => {
  it("turns found.shown into an item, the same after a reload", () => {
    const e = (seq: number, w: FoundWidget) =>
      ({
        seq,
        sessionId: "s1",
        ts: "2026-11-23T10:00:00.000Z",
        type: "found.shown",
        payload: w,
      }) as unknown as Event;
    const items = buildItems([e(3, gallery), e(4, trips), e(5, route)]);
    expect(items.map((i) => i.kind)).toEqual(["found", "found", "found"]);
    expect(buildItems([e(3, gallery), e(4, trips), e(5, route)])).toEqual(items);
  });

  it("draws one big picture and four small, no referrer, «All» opens every one", () => {
    const r = render(<FoundCard widget={gallery} sessionId="s1" />);
    const tiles = r.container.querySelectorAll(".found-tile");
    expect(tiles).toHaveLength(5);
    expect(tiles[0]?.classList.contains("main")).toBe(true);
    const img = tiles[0]?.querySelector("img") as HTMLImageElement;
    expect(img.getAttribute("src")).toBe("https://img.example/0.jpg");
    expect(img.getAttribute("referrerpolicy")).toBe("no-referrer");
    expect(tiles[1]?.querySelector("img")?.getAttribute("src")).toBe("https://img.example/t1.jpg");
    expect(r.container.querySelector(".found-more")?.textContent).toBe("+2");
    fireEvent.click(r.getByText("Tutte (7)"));
    expect(document.querySelectorAll(".found-grid .found-tile")).toHaveLength(7);
    fireEvent.click(document.querySelectorAll(".found-grid .found-tile")[2] as Element);
    const big = document.querySelector(".found-lightbox img") as HTMLImageElement;
    expect(big.getAttribute("src")).toBe("https://img.example/2.jpg");
    expect(document.querySelector(".found-cap a")?.getAttribute("href")).toBe(
      "https://page.example/2",
    );
  });

  it("shows a neutral placeholder for a broken or unsafe picture and never HTML", () => {
    const w: FoundWidget = {
      kind: "gallery",
      images: [{ url: "https://img.example/a.jpg" }, { url: "javascript:alert(1)" }],
    };
    const r = render(<FoundCard widget={w} />);
    expect(r.container.querySelectorAll(".found-pic.empty")).toHaveLength(1);
    fireEvent.error(r.container.querySelector("img") as Element);
    expect(r.container.querySelectorAll(".found-pic.empty")).toHaveLength(2);
    expect(r.container.querySelector("img")).toBeNull();
    expect(r.container.innerHTML).not.toContain("javascript:");
  });

  it("lists trains with times, stops and price; «Choose» writes to the agent, nothing is booked", () => {
    const r = render(<FoundCard widget={trips} sessionId="s1" />);
    const rows = r.container.querySelectorAll(".found-offer");
    expect(rows).toHaveLength(2);
    expect(rows[0]?.textContent).toContain("06:20");
    expect(rows[0]?.textContent).toContain("2 h 55 · diretto · Trenitalia");
    expect(rows[0]?.textContent?.replace(/\s/g, " ")).toContain("39,90 €");
    expect(rows[0]?.textContent).toContain("posti liberi");
    expect(rows[1]?.textContent).toContain("1 fermata");
    fireEvent.click(rows[0]?.querySelector("button") as Element);
    expect(sent).toHaveLength(1);
    expect(sent[0]?.[0]).toBe("s1");
    expect(sent[0]?.[1]).toBe(
      chooseText(trips as never, (trips as never as { offers: never[] }).offers[0] as never),
    );
    expect(sent[0]?.[1]).toContain("Frecciarossa 9505");
    expect(sent[0]?.[1]).toContain("Chiedimi conferma prima di prenotare o pagare");
  });

  it("draws the route, switches way, and opens the system maps", () => {
    const r = render(<FoundCard widget={route} />);
    expect(r.container.querySelector("svg.found-map path.found-map-line")).not.toBeNull();
    expect(r.container.querySelector(".found-duration")?.textContent).toBe("22 min");
    expect(r.container.querySelectorAll(".found-steps li")).toHaveLength(2);
    const a = r.container.querySelector("a.found-maps") as HTMLAnchorElement;
    expect(a.textContent).toContain("Apri in Mappe");
    expect(a.getAttribute("href")).toContain("travelmode=walking");
    expect(a.getAttribute("href")).toContain("origin=41.900900,12.501600");
    fireEvent.click(r.getByText("Mezzi"));
    expect(r.container.querySelector(".found-duration")?.textContent).toBe("8 min");
    expect(r.container.querySelector("a.found-maps")?.getAttribute("href")).toContain(
      "travelmode=transit",
    );
    expect(r.container.querySelector(".found-note")?.textContent).toContain("metro B");
  });

  it("projects points into the box and says times and distances", () => {
    const d = drawRoute(
      [
        { lat: 0, lon: 0 },
        { lat: 1, lon: 1 },
      ],
      200,
      100,
      10,
    );
    expect(d.start.x).toBeGreaterThanOrEqual(10);
    expect(d.end.x).toBeLessThanOrEqual(190);
    expect(d.start.y).toBeGreaterThan(d.end.y);
    expect(d.path.startsWith("M")).toBe(true);
    expect(minutesText(22)).toBe("22 min");
    expect(minutesText(65)).toBe("1 h 05 min");
    expect(distanceText(450, "it-IT")).toBe("450 m");
    expect(distanceText(1700, "it-IT")).toBe("1,7 km");
  });

  it("draws a product's stars", () => {
    const r = render(<Stars rating={4.6} reviews={120} />);
    expect(r.container.querySelectorAll("svg")).toHaveLength(10);
    expect(r.container.querySelector(".stars-n")?.textContent).toBe("4.6");
    expect((r.container.querySelector(".stars-on") as HTMLElement).style.width).toBe("92%");
  });

  it("gives every widget of a conversation the same fixed largest width", () => {
    const css = readFileSync(join(import.meta.dirname, "..", "src", "styles.css"), "utf8");
    expect(css).toMatch(/:root\s*\{\s*--chat-widget-max:\s*640px;/);
    const rule = (sel: string) =>
      css.match(new RegExp(`\\n${sel.replace(/[.]/g, "\\.")}\\s*\\{[^}]*\\}`))?.[0] ?? "";
    for (const sel of [".widget-card", ".found", ".products"])
      expect(rule(sel), sel).toContain("var(--chat-widget-max)");
    expect(css).toMatch(/\.chat-image img\s*\{[^}]*var\(--chat-widget-max\)/);
    // Room inside: the card is not crammed against its border.
    expect(rule(".widget-card")).toMatch(/padding:\s*12px 16px 16px/);
    expect(rule(".found")).toMatch(/padding:\s*16px 18px 18px/);
  });
});
