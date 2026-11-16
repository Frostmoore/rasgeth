// Product pictures (G40.16): the server downloads the pictures of show_products' cards, so the
// person's browser never calls a shop's site before they press «Open». Only public http(s)
// addresses (no private, local or reserved network, checked again on every address the name
// resolves to, at connection time, and on every redirect), only real pictures recognised from
// their bytes (never SVG), at most 5 MB and 10 seconds; big JPEG and PNG pictures are made
// smaller. They are kept on disk for 30 days, by the SHA-256 of their address.
import { createHash, randomBytes } from "node:crypto";
import { lookup as dnsLookup, type LookupAddress } from "node:dns";
import { mkdir, readdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import http, { type IncomingMessage } from "node:http";
import https from "node:https";
import { isIP } from "node:net";
import { join } from "node:path";
import { PRODUCT_IMAGE_TYPES, type ProductImageType } from "@redgiant/protocol";
import { decode as decodePng } from "fast-png";
import { decode as decodeJpeg, encode as encodeJpeg } from "jpeg-js";
import { pngOf, rgbaOf, shrink } from "./convert-js.js";

export const PRODUCT_IMAGE_MAX_BYTES = 5 * 1024 * 1024;
export const PRODUCT_IMAGE_TIMEOUT_MS = 10_000;
export const PRODUCT_IMAGE_TTL_MS = 30 * 24 * 3600 * 1000;
/** Pictures larger than this on a side are made smaller, to `SIDE`. */
const BIG = 800;
const SIDE = 640;
/** Beyond this a picture is kept as it came: shrinking it would hold the server too long. */
const MAX_SHRINK_PIXELS = 12_000_000;
const MAX_REDIRECTS = 3;
const PRUNE_EVERY_MS = 3600 * 1000;

/** The cache's key for a picture's address. */
export const productImageId = (url: string): string =>
  createHash("sha256").update(url).digest("hex");

const v4 = (ip: string) => ip.split(".").map(Number) as [number, number, number, number];

/**
 * Addresses a picture is never downloaded from: loopback, private, link-local, CGNAT, multicast,
 * broadcast, documentation and benchmark ranges, unique-local IPv6, and IPv4 inside IPv6
 * (mapped, NAT64, 6to4) when the IPv4 inside is one of those.
 */
export function blockedAddress(ip: string): boolean {
  const kind = isIP(ip);
  if (kind === 4) {
    const [a, b, c] = v4(ip);
    return (
      a === 0 ||
      a === 10 ||
      a === 127 ||
      a >= 224 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168) ||
      (a === 192 && b === 0 && (c === 0 || c === 2)) ||
      (a === 198 && (b === 18 || b === 19)) ||
      (a === 198 && b === 51 && c === 100) ||
      (a === 203 && b === 0 && c === 113)
    );
  }
  if (kind !== 6) return true;
  const full = expandV6(ip.toLowerCase());
  if (!full) return true;
  const word = (i: number) => Number.parseInt(full[i] as string, 16);
  const tail4 = () => `${word(6) >> 8}.${word(6) & 255}.${word(7) >> 8}.${word(7) & 255}` as const;
  // :: and ::1
  if (full.slice(0, 7).every((w) => w === "0000") && word(7) <= 1) return true;
  // IPv4-mapped (::ffff:a.b.c.d) and IPv4-compatible (::a.b.c.d)
  if (full.slice(0, 5).every((w) => w === "0000") && (word(5) === 0xffff || word(5) === 0))
    return blockedAddress(tail4());
  // NAT64 (64:ff9b::/96)
  if (word(0) === 0x64 && word(1) === 0xff9b) return blockedAddress(tail4());
  // 6to4 (2002::/16): the IPv4 in the next two words
  if (word(0) === 0x2002)
    return blockedAddress(`${word(1) >> 8}.${word(1) & 255}.${word(2) >> 8}.${word(2) & 255}`);
  const first = word(0);
  return (
    (first & 0xfe00) === 0xfc00 || // unique local fc00::/7
    (first & 0xffc0) === 0xfe80 || // link-local fe80::/10
    (first & 0xffc0) === 0xfec0 || // site-local fec0::/10
    (first & 0xff00) === 0xff00 || // multicast
    (first === 0x2001 && word(1) === 0x0db8) // documentation
  );
}

/** An IPv6 address as eight words of four hex digits; undefined if it is not one. */
function expandV6(ip: string): string[] | undefined {
  let s = ip.replace(/^\[|\]$/g, "").replace(/%.*$/, "");
  const dotted = s.match(/(\d+\.\d+\.\d+\.\d+)$/);
  if (dotted?.[1]) {
    if (isIP(dotted[1]) !== 4) return undefined;
    const [a, b, c, d] = v4(dotted[1]);
    s = `${s.slice(0, -dotted[1].length)}${((a << 8) | b).toString(16)}:${((c << 8) | d).toString(16)}`;
  }
  const halves = s.split("::");
  if (halves.length > 2) return undefined;
  const head = halves[0] ? halves[0].split(":") : [];
  const tail = halves.length === 2 && halves[1] ? halves[1].split(":") : [];
  const fill = halves.length === 2 ? 8 - head.length - tail.length : 0;
  if (fill < 0) return undefined;
  const words = [...head, ...Array(fill).fill("0"), ...tail];
  if (words.length !== 8 || words.some((w) => !/^[0-9a-f]{1,4}$/.test(w))) return undefined;
  return words.map((w) => w.padStart(4, "0"));
}

export type UrlVerdict = { ok: true; url: URL } | { ok: false; reason: string };

/**
 * Whether a picture may be downloaded from an address, before any name is resolved (pure):
 * http or https, no user or password in it, a public name or a public address. `allowHosts`
 * (tests and the demo only) lets a local test server through.
 */
export function checkImageUrl(raw: string, allowHosts: readonly string[] = []): UrlVerdict {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return { ok: false, reason: "not an address" };
  }
  if (url.protocol !== "https:" && url.protocol !== "http:")
    return { ok: false, reason: "only http and https addresses" };
  if (url.username || url.password) return { ok: false, reason: "an address with a password" };
  const host = url.hostname.replace(/^\[|\]$/g, "").toLowerCase();
  if (allowHosts.includes(host)) return { ok: true, url };
  if (isIP(host))
    return blockedAddress(host) ? { ok: false, reason: "a private address" } : { ok: true, url };
  if (
    !host.includes(".") ||
    host === "localhost" ||
    /\.(localhost|local|internal|intranet|lan|home|corp|home\.arpa|in-addr\.arpa|ip6\.arpa)\.?$/.test(
      host,
    )
  )
    return { ok: false, reason: "a local name" };
  return { ok: true, url };
}

/** A picture's type from its first bytes; undefined for anything else (SVG included). */
export function sniffImage(b: Uint8Array): ProductImageType | undefined {
  const ascii = (from: number, to: number) => String.fromCharCode(...b.subarray(from, to));
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return "image/jpeg";
  if (b.length >= 8 && ascii(0, 8) === "\x89PNG\r\n\x1a\n") return "image/png";
  if (b.length >= 6 && (ascii(0, 6) === "GIF87a" || ascii(0, 6) === "GIF89a")) return "image/gif";
  if (b.length >= 12 && ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP") return "image/webp";
  if (b.length >= 16 && ascii(4, 8) === "ftyp") {
    const box = Math.min(b.length, new DataView(b.buffer, b.byteOffset, 4).getUint32(0));
    for (let i = 8; i + 4 <= box; i += 4) {
      if (i === 12) continue; // the minor version
      const brand = ascii(i, i + 4);
      if (brand === "avif" || brand === "avis") return "image/avif";
    }
  }
  return undefined;
}

/** A PNG's size from its header, without decoding it. */
const pngSize = (b: Uint8Array) => {
  const v = new DataView(b.buffer, b.byteOffset, b.byteLength);
  return b.length >= 24 ? { width: v.getUint32(16), height: v.getUint32(20) } : undefined;
};

/** A big JPEG or PNG made smaller (the longest side to 640); anything else as it came. */
export function smallerPicture(
  bytes: Uint8Array,
  type: ProductImageType,
): { bytes: Uint8Array; type: ProductImageType } {
  try {
    if (type === "image/png") {
      const size = pngSize(bytes);
      if (!size || Math.max(size.width, size.height) <= BIG) return { bytes, type };
      if (size.width * size.height > MAX_SHRINK_PIXELS) return { bytes, type };
      const p = decodePng(bytes);
      if (p.depth !== 8 || p.channels !== 4 || p.palette) {
        // Rarer layouts: filled out to RGBA by the converters' reader.
        return small(rgbaOf(bytes), bytes, type);
      }
      return small({ width: p.width, height: p.height, data: p.data as Uint8Array }, bytes, type);
    }
    if (type === "image/jpeg") {
      const j = decodeJpeg(bytes, {
        useTArray: true,
        formatAsRGBA: true,
        maxResolutionInMP: MAX_SHRINK_PIXELS / 1e6,
        maxMemoryUsageInMB: 256,
      });
      if (Math.max(j.width, j.height) <= BIG) return { bytes, type };
      return small({ width: j.width, height: j.height, data: j.data }, bytes, type);
    }
  } catch {
    // A picture the decoders refuse (too big, unusual): kept as it came.
  }
  return { bytes, type };
}

function small(
  img: { width: number; height: number; data: Uint8Array | Uint8ClampedArray },
  original: Uint8Array,
  type: ProductImageType,
): { bytes: Uint8Array; type: ProductImageType } {
  const s = shrink(img, SIDE);
  let transparent = false;
  for (let i = 3; i < s.data.length; i += 4)
    if ((s.data[i] as number) < 255) {
      transparent = true;
      break;
    }
  const out = transparent
    ? { bytes: pngOf(s), type: "image/png" as const }
    : {
        bytes: new Uint8Array(
          encodeJpeg({ width: s.width, height: s.height, data: s.data }, 82).data,
        ),
        type: "image/jpeg" as const,
      };
  return out.bytes.length < original.length ? out : { bytes: original, type };
}

export interface ProductImagesOptions {
  /** Where the pictures are kept. */
  dir: string;
  maxBytes?: number;
  timeoutMs?: number;
  ttlMs?: number;
  now?: () => number;
  /** Tests and the demo only: hosts allowed although they are local (a test server on 127.0.0.1). */
  allowHosts?: readonly string[];
  /** Tests only: how names resolve (the system's resolver otherwise). */
  resolve?: (host: string) => Promise<LookupAddress[]>;
}

export type ProductImageResult = { id: string } | { error: string };

interface Meta {
  type: ProductImageType;
  url: string;
  at: number;
}

class FetchError extends Error {}

const sizeText = (n: number) =>
  n >= 1048576 ? `${Math.round(n / 1048576)} MB` : `${Math.round(n / 1024)} KB`;

/** The server's product pictures: downloaded once, kept on disk, served by their id. */
export class ProductImages {
  private readonly inFlight = new Map<string, Promise<ProductImageResult>>();
  private lastPrune = 0;
  private readonly now: () => number;

  constructor(private readonly o: ProductImagesOptions) {
    this.now = o.now ?? Date.now;
  }

  private get ttl() {
    return this.o.ttlMs ?? PRODUCT_IMAGE_TTL_MS;
  }

  /** The picture at an address, in the cache (downloaded now if it is not there or too old). */
  fetch(url: string): Promise<ProductImageResult> {
    const id = productImageId(url);
    const running = this.inFlight.get(id);
    if (running) return running;
    const p = this.fetchOnce(id, url).finally(() => this.inFlight.delete(id));
    this.inFlight.set(id, p);
    return p;
  }

  private async fetchOnce(id: string, url: string): Promise<ProductImageResult> {
    void this.pruneSometimes();
    if (await this.fresh(id)) return { id };
    try {
      const bytes = await this.download(url);
      const type = sniffImage(bytes);
      if (!type || !PRODUCT_IMAGE_TYPES.includes(type))
        return { error: "not a picture (JPEG, PNG, WebP, GIF or AVIF)" };
      const kept = smallerPicture(bytes, type);
      await mkdir(this.o.dir, { recursive: true });
      const tmp = join(this.o.dir, `.${id}.${randomBytes(4).toString("hex")}`);
      await writeFile(tmp, kept.bytes);
      await rename(tmp, join(this.o.dir, id));
      const meta: Meta = { type: kept.type, url, at: this.now() };
      await writeFile(join(this.o.dir, `${id}.json`), JSON.stringify(meta));
      return { id };
    } catch (err) {
      return { error: err instanceof FetchError ? err.message : "could not be downloaded" };
    }
  }

  /** A kept picture by its id, if it is there and not too old. */
  async read(id: string): Promise<{ bytes: Buffer; type: ProductImageType } | undefined> {
    if (!/^[0-9a-f]{64}$/.test(id)) return undefined;
    const meta = await this.fresh(id);
    if (!meta) return undefined;
    const bytes = await readFile(join(this.o.dir, id)).catch(() => undefined);
    return bytes && { bytes, type: meta.type };
  }

  private async fresh(id: string): Promise<Meta | undefined> {
    const meta = await readFile(join(this.o.dir, `${id}.json`), "utf8")
      .then((t) => JSON.parse(t) as Meta)
      .catch(() => undefined);
    if (!meta || !PRODUCT_IMAGE_TYPES.includes(meta.type)) return undefined;
    return this.now() - meta.at < this.ttl ? meta : undefined;
  }

  /** Forgets the pictures older than the cache keeps them. */
  async prune(): Promise<number> {
    const names = await readdir(this.o.dir).catch(() => [] as string[]);
    let removed = 0;
    for (const n of names) {
      const m = n.match(/^([0-9a-f]{64})\.json$/);
      if (!m?.[1] || (await this.fresh(m[1]))) continue;
      await rm(join(this.o.dir, m[1]), { force: true });
      await rm(join(this.o.dir, n), { force: true });
      removed++;
    }
    return removed;
  }

  private async pruneSometimes() {
    if (this.now() - this.lastPrune < PRUNE_EVERY_MS) return;
    this.lastPrune = this.now();
    await this.prune().catch(() => 0);
  }

  /** The bytes at an address, following up to three redirects, each one checked again. */
  private async download(raw: string): Promise<Uint8Array> {
    const deadline = this.now() + (this.o.timeoutMs ?? PRODUCT_IMAGE_TIMEOUT_MS);
    let address = raw;
    for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
      const verdict = checkImageUrl(address, this.o.allowHosts);
      if (!verdict.ok) throw new FetchError(verdict.reason);
      const r = await this.get(verdict.url, deadline);
      if ("redirect" in r) {
        address = new URL(r.redirect, verdict.url).toString();
        continue;
      }
      return r.bytes;
    }
    throw new FetchError("too many redirects");
  }

  private get(url: URL, deadline: number): Promise<{ bytes: Uint8Array } | { redirect: string }> {
    const max = this.o.maxBytes ?? PRODUCT_IMAGE_MAX_BYTES;
    const allow = this.o.allowHosts ?? [];
    const host = url.hostname.replace(/^\[|\]$/g, "").toLowerCase();
    // Every address the name resolves to is checked, and the connection goes to one of those.
    const lookup = (
      hostname: string,
      options: { all?: boolean },
      cb: (err: Error | null, address?: string | LookupAddress[], family?: number) => void,
    ) => {
      const resolve =
        this.o.resolve ??
        ((h: string) =>
          new Promise<LookupAddress[]>((ok, ko) =>
            dnsLookup(h, { all: true }, (err, list) => (err ? ko(err) : ok(list))),
          ));
      resolve(hostname).then(
        (addresses) => {
          if (!addresses.length) return cb(new FetchError("the name does not resolve"));
          if (!allow.includes(host) && addresses.some((a) => blockedAddress(a.address)))
            return cb(new FetchError("the name resolves to a private address"));
          if (options.all) return cb(null, addresses);
          const first = addresses[0] as LookupAddress;
          cb(null, first.address, first.family);
        },
        (err: Error) => cb(err),
      );
    };
    return new Promise((resolve, reject) => {
      const left = deadline - this.now();
      if (left <= 0) return reject(new FetchError("took too long"));
      const lib = url.protocol === "https:" ? https : http;
      const req = lib.get(
        url,
        {
          lookup: lookup as never,
          headers: {
            "user-agent": "RedGiant (product pictures)",
            accept: "image/avif,image/webp,image/png,image/jpeg,image/gif;q=0.9,*/*;q=0.1",
          },
          agent: false,
        },
        (res: IncomingMessage) => {
          const status = res.statusCode ?? 0;
          if (status >= 300 && status < 400 && res.headers.location) {
            res.resume();
            return resolve({ redirect: res.headers.location });
          }
          if (status !== 200) {
            res.resume();
            return reject(new FetchError(`the site answered ${status}`));
          }
          const length = Number(res.headers["content-length"] ?? 0);
          if (length > max) {
            res.destroy();
            return reject(new FetchError(`bigger than ${sizeText(max)}`));
          }
          const chunks: Buffer[] = [];
          let size = 0;
          res.on("data", (c: Buffer) => {
            size += c.length;
            if (size > max) {
              res.destroy();
              reject(new FetchError(`bigger than ${sizeText(max)}`));
              return;
            }
            chunks.push(c);
          });
          res.on("end", () => {
            clearTimeout(timer);
            resolve({ bytes: new Uint8Array(Buffer.concat(chunks)) });
          });
          res.on("error", (e) => reject(e));
        },
      );
      const timer = setTimeout(() => {
        req.destroy(new FetchError("took too long"));
      }, left);
      req.on("error", (e) => {
        clearTimeout(timer);
        reject(e instanceof FetchError ? e : new FetchError("could not be reached"));
      });
      req.on("close", () => clearTimeout(timer));
    });
  }
}
