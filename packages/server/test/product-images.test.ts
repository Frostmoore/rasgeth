// Product pictures (G40.16): which addresses and bytes are accepted (tables), and the download
// and the cache against a fake shop on 127.0.0.1 (never the real network).
import { mkdtemp, readdir } from "node:fs/promises";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { encode as encodePng } from "fast-png";
import { encode as encodeJpeg } from "jpeg-js";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  blockedAddress,
  checkImageUrl,
  ProductImages,
  productImageId,
  sniffImage,
} from "../src/product-images.js";

describe("addresses a picture may come from (G40.16)", () => {
  it.each([
    ["8.8.8.8", false],
    ["93.184.216.34", false],
    ["127.0.0.1", true],
    ["10.1.2.3", true],
    ["172.16.0.1", true],
    ["172.32.0.1", false],
    ["192.168.1.13", true],
    ["169.254.169.254", true],
    ["100.64.0.1", true],
    ["0.0.0.0", true],
    ["224.0.0.1", true],
    ["255.255.255.255", true],
    ["192.0.2.10", true],
    ["198.18.0.1", true],
    ["::1", true],
    ["::", true],
    ["fd00::1", true],
    ["fe80::1", true],
    ["ff02::1", true],
    ["::ffff:127.0.0.1", true],
    ["::ffff:7f00:1", true],
    ["::ffff:8.8.8.8", false],
    ["64:ff9b::10.0.0.1", true],
    ["2002:c0a8:0101::1", true],
    ["2001:db8::1", true],
    ["2606:4700:4700::1111", false],
    ["not-an-ip", true],
  ])("%s blocked: %s", (ip, blocked) => {
    expect(blockedAddress(ip)).toBe(blocked);
  });

  it.each([
    ["https://shop.example.com/p/moka.jpg", true],
    ["http://cdn.shop.example/moka.webp?w=600", true],
    ["https://93.184.216.34/a.png", true],
    ["ftp://shop.example.com/a.jpg", false],
    ["file:///etc/passwd", false],
    ["data:image/png;base64,AAAA", false],
    ["javascript:alert(1)", false],
    ["https://user:pass@shop.example.com/a.jpg", false],
    ["http://localhost:8080/a.jpg", false],
    ["http://127.0.0.1/a.jpg", false],
    ["http://[::1]/a.jpg", false],
    ["http://[::ffff:10.0.0.1]/a.jpg", false],
    ["http://169.254.169.254/latest/meta-data", false],
    ["http://nas/a.jpg", false],
    ["http://printer.local/a.jpg", false],
    ["http://redgiant.lan/a.jpg", false],
    ["http://router.home.arpa/a.jpg", false],
    ["not a url", false],
  ])("%s allowed: %s", (url, ok) => {
    expect(checkImageUrl(url).ok).toBe(ok);
  });

  it("lets a test server through only when it is named", () => {
    expect(checkImageUrl("http://127.0.0.1:9/a.png", ["127.0.0.1"]).ok).toBe(true);
    expect(checkImageUrl("http://127.0.0.1:9/a.png", ["127.0.0.2"]).ok).toBe(false);
  });
});

const JPEG = (w: number, h: number) =>
  new Uint8Array(
    encodeJpeg({ width: w, height: h, data: new Uint8Array(w * h * 4).fill(200) }, 90).data,
  );
const PNG = (w: number, h: number) =>
  encodePng({ width: w, height: h, data: new Uint8Array(w * h * 4).fill(255), channels: 4 });
const bytes = (s: string) => new Uint8Array(Buffer.from(s, "binary"));

describe("picture types from their bytes (G40.16)", () => {
  it.each([
    ["jpeg", JPEG(4, 4), "image/jpeg"],
    ["png", PNG(4, 4), "image/png"],
    ["gif", bytes("GIF89a\x01\x00\x01\x00"), "image/gif"],
    ["webp", bytes("RIFF\x10\x00\x00\x00WEBPVP8 "), "image/webp"],
    ["avif", bytes("\x00\x00\x00\x1cftypavif\x00\x00\x00\x00avifmif1miaf"), "image/avif"],
    [
      "avif among compatible brands",
      bytes("\x00\x00\x00\x1cftypmif1\x00\x00\x00\x00mif1avifmiaf"),
      "image/avif",
    ],
    ["heic", bytes("\x00\x00\x00\x18ftypheic\x00\x00\x00\x00mif1heic"), undefined],
    ["svg", bytes('<svg xmlns="http://www.w3.org/2000/svg"/>'), undefined],
    ["html", bytes("<!doctype html><img src=x onerror=alert(1)>"), undefined],
    ["empty", new Uint8Array(), undefined],
  ])("%s", (_name, b, type) => {
    expect(sniffImage(b)).toBe(type);
  });
});

describe("downloading and keeping pictures (G40.16)", () => {
  let server: Server;
  let base: string;
  let dir: string;
  const hits: string[] = [];
  const big = JPEG(1600, 1200);
  beforeEach(async () => {
    hits.length = 0;
    dir = await mkdtemp(join(tmpdir(), "rg-products-"));
    server = createServer((req, res) => {
      hits.push(req.url ?? "");
      if (req.headers.cookie || req.headers.authorization) res.statusCode = 400;
      const send = (type: string, body: Uint8Array) => {
        res.setHeader("content-type", type);
        res.end(body);
      };
      switch (req.url) {
        case "/moka.jpg":
          return send("image/jpeg", big);
        case "/small.png":
          return send("image/png", PNG(32, 32));
        case "/lies.jpg":
          return send("image/jpeg", bytes("<svg xmlns='http://www.w3.org/2000/svg'/>"));
        case "/huge.jpg":
          return send("image/jpeg", new Uint8Array(70_000).fill(0xff));
        case "/slow.jpg":
          return setTimeout(() => send("image/jpeg", big), 2000);
        case "/hop":
          res.statusCode = 302;
          res.setHeader("location", "/small.png");
          return res.end();
        case "/inside":
          res.statusCode = 302;
          res.setHeader("location", "http://169.254.169.254/latest/meta-data");
          return res.end();
        default:
          res.statusCode = 404;
          return res.end();
      }
    });
    await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
    base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });
  afterEach(async () => {
    server.closeAllConnections();
    await new Promise((r) => server.close(r));
  });

  const images = (o: Partial<ConstructorParameters<typeof ProductImages>[0]> = {}) =>
    new ProductImages({ dir, allowHosts: ["127.0.0.1"], ...o });

  it("downloads a picture once, makes a big one smaller and serves it by its id", async () => {
    const p = images();
    const r = await p.fetch(`${base}/moka.jpg`);
    expect(r).toEqual({ id: productImageId(`${base}/moka.jpg`) });
    const kept = await p.read((r as { id: string }).id);
    expect(kept?.type).toBe("image/jpeg");
    expect(kept?.bytes.length).toBeLessThan(big.length);
    expect(sniffImage(new Uint8Array(kept?.bytes ?? []))).toBe("image/jpeg");
    // From the cache the second time.
    await p.fetch(`${base}/moka.jpg`);
    expect(hits).toEqual(["/moka.jpg"]);
    const small = await p.fetch(`${base}/small.png`);
    expect((await p.read((small as { id: string }).id))?.type).toBe("image/png");
  });

  it("follows a redirect it checks again, and refuses one into a private network", async () => {
    const p = images();
    expect(await p.fetch(`${base}/hop`)).toHaveProperty("id");
    expect(hits).toEqual(["/hop", "/small.png"]);
    expect(await p.fetch(`${base}/inside`)).toEqual({ error: "a private address" });
  });

  it("refuses what is not a picture, too big, too slow or missing", async () => {
    const p = images({ maxBytes: 64_000, timeoutMs: 300 });
    expect(await p.fetch(`${base}/lies.jpg`)).toEqual({
      error: "not a picture (JPEG, PNG, WebP, GIF or AVIF)",
    });
    expect(await p.fetch(`${base}/huge.jpg`)).toEqual({ error: "bigger than 63 KB" });
    expect(await p.fetch(`${base}/slow.jpg`)).toEqual({ error: "took too long" });
    expect(await p.fetch(`${base}/gone.jpg`)).toEqual({ error: "the site answered 404" });
    expect(await readdir(dir)).toEqual([]);
  });

  it("never calls a local address it was not told about, nor a name resolving to one", async () => {
    const p = new ProductImages({
      dir,
      resolve: async (host) =>
        host === "shop.example.com" ? [{ address: "127.0.0.1", family: 4 }] : [],
    });
    expect(await p.fetch(`${base}/moka.jpg`)).toEqual({ error: "a private address" });
    const port = (server.address() as AddressInfo).port;
    expect(await p.fetch(`http://shop.example.com:${port}/moka.jpg`)).toEqual({
      error: "the name resolves to a private address",
    });
    expect(hits).toEqual([]);
  });

  it("forgets pictures after their time, and downloads them again", async () => {
    let now = 1_000_000;
    const p = images({ now: () => now, ttlMs: 1000 });
    const r = (await p.fetch(`${base}/small.png`)) as { id: string };
    expect(await p.read(r.id)).toBeDefined();
    now += 1001;
    expect(await p.read(r.id)).toBeUndefined();
    expect(await p.prune()).toBe(1);
    expect(await readdir(dir)).toEqual([]);
    await p.fetch(`${base}/small.png`);
    expect(hits).toEqual(["/small.png", "/small.png"]);
    expect(await p.read("../../etc/passwd")).toBeUndefined();
  });
});
