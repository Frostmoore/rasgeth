// show_products (G40.16): the Chat shows product cards; the server downloads the pictures from
// a fake shop on 127.0.0.1, the log keeps the cards with the pictures' references (never the
// bytes), the model reads a summary in words, and the pictures come from a signed-in route.
import { createServer, type Server as HttpServer } from "node:http";
import type { AddressInfo } from "node:net";
import { ProductsShownPayload } from "@redgiant/protocol";
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { encode as encodePng } from "fast-png";
import { afterEach, describe, expect, it } from "vitest";
import { productImageId } from "../src/product-images.js";
import { OTHER, startServer, TOKEN } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
let shop: HttpServer | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
  shop?.closeAllConnections();
  await new Promise((r) => (shop ? shop.close(r) : r(null)));
  shop = undefined;
}, 60_000);

const textOf = (req: CompletionRequest | undefined) =>
  req?.messages
    .at(-1)
    ?.parts.flatMap((p) =>
      p.type === "text" ? [p.text] : p.type === "tool_result" ? [p.content] : [],
    )
    .join("\n") ?? "";

function script(req: CompletionRequest): FakeTurn {
  const last = req.messages.at(-1);
  if (last?.parts.some((p) => p.type === "tool_result")) return { text: `RESULT: ${textOf(req)}` };
  const m = textOf(req).match(/^CALL (\w+) ([\s\S]+)$/);
  if (m?.[1] && m[2]) return { toolCalls: [{ name: m[1], input: JSON.parse(m[2]) }] };
  return { text: "ok" };
}

const PICTURE = encodePng({
  width: 8,
  height: 8,
  data: new Uint8Array(8 * 8 * 4).fill(180),
  channels: 4,
});

async function fakeShop() {
  const hits: string[] = [];
  shop = createServer((req, res) => {
    hits.push(req.url ?? "");
    if (req.url === "/moka.png") {
      res.setHeader("content-type", "image/png");
      return res.end(PICTURE);
    }
    res.statusCode = 404;
    res.end();
  });
  await new Promise<void>((r) => shop?.listen(0, "127.0.0.1", r));
  return { base: `http://127.0.0.1:${(shop.address() as AddressInfo).port}`, hits };
}

describe("show_products (G40.16)", () => {
  it("shows cards with the server's pictures, a summary for the model, a signed-in route", async () => {
    const { base, hits } = await fakeShop();
    s = await startServer(script, {}, { productImages: { allowHosts: ["127.0.0.1"] } });
    await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "God" });
    const chat = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body.id;
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: chat }))
      .body.sessionId;
    const input = {
      title: "Moka pots",
      products: [
        {
          name: "Moka Express 3 cups",
          price: 32.9,
          currency: "eur",
          shop: "Bialetti",
          url: "https://shop.example.com/moka",
          image_url: `${base}/moka.png`,
          description: "The classic, aluminium.",
          source: 1,
        },
        {
          name: "Venus 4 cups",
          price: 45,
          currency: "EUR",
          url: "https://shop.example.com/venus",
          image_url: `${base}/missing.png`,
          source: 2,
        },
        { name: "Brikka", url: "https://shop.example.com/brikka" },
      ],
    };
    await (await s.core.send("me", sid, `CALL show_products ${JSON.stringify(input)}`)).done;

    // The tool is offered with its guidance, and the prompt says when to use it.
    const first = s.provider.requests[0];
    expect(first?.tools?.map((t) => t.name)).toContain("show_products");
    expect(first?.system).toContain("## Products to buy or compare");

    // The model reads words: what it showed, which pictures did not come, no bytes.
    const said = textOf(s.provider.requests.at(-1));
    expect(said).toContain('Shown to the person as 3 product cards under "Moka pots"');
    expect(said).toContain("1. Moka Express 3 cups: 32.90 EUR, Bialetti [1] (with its picture)");
    expect(said).toContain(
      "2. Venus 4 cups: 45.00 EUR [2] (picture not shown: the site answered 404)",
    );
    expect(said).toContain("3. Brikka: price not given (no picture given)");
    expect(said).not.toMatch(/base64|iVBOR/);

    const events = await s.core.store.list({ types: ["products.shown"] });
    expect(events).toHaveLength(1);
    const payload = ProductsShownPayload.parse(events[0]?.payload);
    const id = productImageId(`${base}/moka.png`);
    expect(payload).toEqual({
      title: "Moka pots",
      products: [
        {
          name: "Moka Express 3 cups",
          price: 32.9,
          currency: "EUR",
          shop: "Bialetti",
          url: "https://shop.example.com/moka",
          description: "The classic, aluminium.",
          source: 1,
          imageUrl: `${base}/moka.png`,
          image: id,
        },
        {
          name: "Venus 4 cups",
          price: 45,
          currency: "EUR",
          url: "https://shop.example.com/venus",
          source: 2,
          imageUrl: `${base}/missing.png`,
        },
        { name: "Brikka", url: "https://shop.example.com/brikka" },
      ],
    });
    expect(JSON.stringify(events[0])).not.toMatch(/base64|iVBOR/);
    expect(hits.sort()).toEqual(["/missing.png", "/moka.png"]);

    // The picture, only with a sign-in, exactly as it was checked.
    const url = `${s.url}/api/products/images/${id}`;
    expect((await fetch(url)).status).toBe(401);
    const r = await fetch(url, { headers: { authorization: `Bearer ${TOKEN}` } });
    expect(r.status).toBe(200);
    expect(r.headers.get("content-type")).toBe("image/png");
    expect(r.headers.get("x-content-type-options")).toBe("nosniff");
    expect(new Uint8Array(await r.arrayBuffer())).toEqual(new Uint8Array(PICTURE));
    const other = await fetch(`${s.url}/api/products/images/${"0".repeat(64)}`, {
      headers: { authorization: `Bearer ${OTHER}` },
    });
    expect(other.status).toBe(404);
  });

  it("refuses links that are not web pages and more than ten cards", async () => {
    s = await startServer(script);
    await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "God" });
    const chat = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body.id;
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: chat }))
      .body.sessionId;
    const bad = { products: [{ name: "X", url: "javascript:alert(1)" }] };
    await (await s.core.send("me", sid, `CALL show_products ${JSON.stringify(bad)}`)).done;
    const many = {
      products: Array.from({ length: 11 }, (_, i) => ({
        name: `P${i}`,
        url: `https://shop.example.com/${i}`,
      })),
    };
    await (await s.core.send("me", sid, `CALL show_products ${JSON.stringify(many)}`)).done;
    expect(await s.core.store.list({ types: ["products.shown"] })).toHaveLength(0);
  });

  it("can be switched off on the tools page", async () => {
    s = await startServer(script);
    await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "God" });
    expect((await s.api("PUT", "/api/tools", { off: ["show_products"] })).status).toBe(200);
    const chat = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body.id;
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: chat }))
      .body.sessionId;
    await (await s.core.send("me", sid, "hi")).done;
    const req = s.provider.requests.at(-1);
    expect(req?.tools?.map((t) => t.name)).not.toContain("show_products");
    expect(req?.system).not.toContain("## Products to buy or compare");
  });
});
