// @vitest-environment jsdom
// Product cards on the page (G40.16): the event becomes a carousel; the pictures come from the
// server's route (the loader), a missing one shows the drawn placeholder; «Open» opens the shop in
// a new tab with rel=noopener, and nothing else calls the shop.
import type { Event, ProductCard } from "@redgiant/protocol";
import { cleanup, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { setLang } from "../src/i18n.js";
import { buildItems } from "../src/state.js";

const { ProductCards, priceText, safeLink } = await import("../src/components/ProductCards.js");

const ID = "a".repeat(64);
const products: ProductCard[] = [
  {
    name: "Moka Express 3 tazze",
    price: 32.9,
    currency: "EUR",
    shop: "Bialetti",
    url: "https://shop.example.com/moka",
    description: "La classica, in alluminio.",
    source: 1,
    imageUrl: "https://cdn.example.com/moka.jpg",
    image: ID,
  },
  {
    name: "Venus 4 tazze",
    price: 45,
    currency: "EUR",
    url: "https://shop.example.com/venus",
    source: 2,
    imageUrl: "https://cdn.example.com/missing.jpg",
  },
  { name: "Strana", url: "javascript:alert(1)" as string },
];

beforeEach(() => {
  setLang("it");
  URL.createObjectURL = vi.fn(() => "blob:picture-1");
  URL.revokeObjectURL = vi.fn();
});
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

describe("product cards (G40.16)", () => {
  it("turns products.shown into one carousel item", () => {
    const e = {
      seq: 4,
      sessionId: "s1",
      ts: "2026-11-16T10:00:00.000Z",
      type: "products.shown",
      payload: { title: "Moka", products },
    } as unknown as Event;
    expect(buildItems([e])).toEqual([{ kind: "products", key: "e4", title: "Moka", products }]);
  });

  it("draws the cards with the server's pictures, a placeholder, prices and safe links", async () => {
    const shop = vi.spyOn(globalThis, "fetch");
    const load = vi.fn(async (id: string) => {
      if (id !== ID) throw new Error("404");
      return new Blob(["x"], { type: "image/jpeg" });
    });
    const r = render(<ProductCards title="Moka" products={products} load={load} />);
    const cards = r.container.querySelectorAll(".product-card");
    expect(cards).toHaveLength(3);
    await waitFor(() =>
      expect(r.container.querySelector("img")?.getAttribute("src")).toBe("blob:picture-1"),
    );
    // Only the cached picture is asked, by its id; the card without one shows the drawing.
    expect(load.mock.calls).toEqual([[ID]]);
    expect(r.container.querySelectorAll(".product-picture.empty")).toHaveLength(2);
    expect(r.container.querySelector(".product-picture.empty svg")).not.toBeNull();
    expect(shop).not.toHaveBeenCalled();
    // No picture address of a shop anywhere in the page.
    expect(r.container.innerHTML).not.toContain("cdn.example.com");

    const first = cards[0] as HTMLElement;
    expect(first.querySelector(".product-name")?.textContent).toBe("Moka Express 3 tazze");
    expect(first.querySelector(".product-price")?.textContent?.replace(/\s/g, " ")).toBe("32,90 €");
    expect(first.querySelector(".product-shop")?.textContent).toBe("Bialetti");
    expect(first.querySelector(".product-source")?.textContent).toBe("1");
    const open = first.querySelector("a.product-open") as HTMLAnchorElement;
    expect(open.textContent).toBe("Apri");
    expect(open.getAttribute("href")).toBe("https://shop.example.com/moka");
    expect(open.getAttribute("target")).toBe("_blank");
    expect(open.getAttribute("rel")).toBe("noopener noreferrer");
    // A link that is not a web page is not drawn.
    expect((cards[2] as HTMLElement).querySelector("a")).toBeNull();
    expect(r.container.querySelector(".products-title")?.textContent).toBe("Moka");
  });

  it("says prices in the page's language and keeps only web links", () => {
    expect(priceText(32.9, "EUR").replace(/\s/g, " ")).toBe("32,90 €");
    setLang("en");
    expect(priceText(45, "USD")).toBe("$45.00");
    expect(priceText(12, undefined)).toBe("12.00");
    expect(priceText(undefined, "EUR")).toBe("");
    expect(safeLink("https://a.example/x")).toBe("https://a.example/x");
    expect(safeLink("javascript:alert(1)")).toBeUndefined();
    expect(safeLink("data:text/html,hi")).toBeUndefined();
  });
});
