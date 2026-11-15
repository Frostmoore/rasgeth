// Recorded vectors of the setup channel's handshake (G40.7), made with node:crypto exactly as
// packages/server/src/nodes/channel.ts does it, from fixed keys and nonces: the Dart client must
// compute the same transcript hash, signatures, keys and frames without a server.
//   node apps/companion/tool/setup_vectors.mjs > apps/companion/test/fixtures/setup_vectors.json
import {
  createCipheriv,
  createHash,
  createPrivateKey,
  createPublicKey,
  diffieHellman,
  hkdfSync,
  sign,
} from "node:crypto";

const VERSION = "rg-node-v1";
const seed = (n) => Buffer.alloc(32, n);

// PKCS#8 DER prefixes for a raw 32-byte private key.
const ED_PREFIX = Buffer.from("302e020100300506032b657004220420", "hex");
const X_PREFIX = Buffer.from("302e020100300506032b656e04220420", "hex");
const priv = (prefix, s) =>
  createPrivateKey({ key: Buffer.concat([prefix, s]), format: "der", type: "pkcs8" });
const rawPub = (k) =>
  Buffer.from(createPublicKey(k).export({ format: "jwk" }).x ?? "", "base64url");

const dId = priv(ED_PREFIX, seed(1));
const lId = priv(ED_PREFIX, seed(2));
const dEph = priv(X_PREFIX, seed(3));
const lEph = priv(X_PREFIX, seed(4));
const dNonce = seed(5);
const lNonce = seed(6);
const mode = "setup";

const parts = [rawPub(dEph), rawPub(dId), dNonce, rawPub(lEph), rawPub(lId), lNonce];
const hash = createHash("sha256").update(VERSION).update(mode);
for (const p of parts) hash.update(p);
const th = hash.digest();

const secret = diffieHellman({ privateKey: dEph, publicKey: createPublicKey(lEph) });
const okm = Buffer.from(hkdfSync("sha256", secret, th, `${VERSION} keys`, 64));
const d2l = okm.subarray(0, 32);
const l2d = okm.subarray(32, 64);

function seal(key, n, m) {
  const head = Buffer.alloc(8);
  head.writeBigUInt64BE(BigInt(n));
  const nonce = Buffer.alloc(12);
  nonce.writeBigUInt64BE(BigInt(n), 4);
  const c = createCipheriv("chacha20-poly1305", key, nonce, { authTagLength: 16 });
  c.setAAD(head);
  const body = Buffer.concat([c.update(Buffer.from(JSON.stringify(m), "utf8")), c.final()]);
  return Buffer.concat([head, body, c.getAuthTag()]);
}

const fp = (raw) =>
  `SHA256:${createHash("sha256").update(raw).digest("base64").replace(/=+$/, "")}`;
const b64 = (b) => b.toString("base64");

process.stdout.write(
  `${JSON.stringify(
    {
      note: "made by tool/setup_vectors.mjs (node:crypto, the formulas of nodes/channel.ts)",
      mode,
      seeds: { dialler: b64(seed(1)), listener: b64(seed(2)) },
      dEph: b64(parts[0]),
      dEphPriv: b64(seed(3)),
      dId: b64(parts[1]),
      dNonce: b64(dNonce),
      lEph: b64(parts[3]),
      lId: b64(parts[4]),
      lNonce: b64(lNonce),
      listenerFingerprint: fp(parts[4]),
      diallerFingerprint: fp(parts[1]),
      th: b64(th),
      listenerSig: b64(sign(null, Buffer.concat([Buffer.from("listener"), th]), lId)),
      diallerSig: b64(sign(null, Buffer.concat([Buffer.from("dialler"), th]), dId)),
      secret: b64(secret),
      d2l: b64(d2l),
      l2d: b64(l2d),
      frames: [
        { key: "d2l", n: 0, message: { t: "info", id: 1 }, frame: b64(seal(d2l, 0, { t: "info", id: 1 })) },
        {
          key: "l2d",
          n: 3,
          message: { id: 4, ok: true, status: 200, body: "è" },
          frame: b64(seal(l2d, 3, { id: 4, ok: true, status: 200, body: "è" })),
        },
      ],
    },
    null,
    2,
  )}\n`,
);
