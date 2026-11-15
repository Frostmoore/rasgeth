// Web Push encryption (RFC 8291, the "aes128gcm" content coding of RFC 8188) and VAPID (RFC 8292),
// with node:crypto only (G40.4). A message is one record: the push services take up to 4096
// bytes, so the record size is 4096 and a payload may be at most 4096 - 86 (header) - 17 bytes.
//
//   ecdh_secret = ECDH(as_private, ua_public)
//   IKM   = HKDF(salt = auth_secret, ikm = ecdh_secret, info = "WebPush: info\0" ua_public as_public, 32)
//   CEK   = HKDF(salt, IKM, "Content-Encoding: aes128gcm\0", 16)
//   NONCE = HKDF(salt, IKM, "Content-Encoding: nonce\0", 12)
//   body  = salt(16) | rs(4) | idlen(1) = 65 | as_public(65) | AES-128-GCM(plaintext | 0x02)
//
// The same coding seals what goes to an Apple device through the blind relay: the device made
// the key pair and keeps the private half, so the relay (and Apple) see only ciphertext.

import {
  createCipheriv,
  createDecipheriv,
  createECDH,
  createPrivateKey,
  hkdfSync,
  type KeyObject,
  randomBytes,
  sign,
} from "node:crypto";

export const RECORD_SIZE = 4096;
/** salt + rs + idlen + key */
const HEADER = 16 + 4 + 1 + 65;
/** The padding delimiter and the GCM tag. */
const OVERHEAD = 1 + 16;
/** The longest plaintext one message carries. */
export const MAX_PLAINTEXT = RECORD_SIZE - HEADER - OVERHEAD;

export const b64u = (b: Uint8Array): string => Buffer.from(b).toString("base64url");
export const unb64u = (s: string): Buffer => Buffer.from(s, "base64url");

/** A device's keys, as the browser or UnifiedPush give them (base64url). */
export interface SubscriberKeys {
  /** The device's P-256 public key, uncompressed (65 bytes). */
  p256dh: string;
  /** Its 16-byte authentication secret. */
  auth: string;
}

/** Whether keys have the right shape (a 65-byte uncompressed point, a 16-byte secret). */
export function validKeys(k: SubscriberKeys): boolean {
  try {
    const pub = unb64u(k.p256dh);
    const auth = unb64u(k.auth);
    if (pub.length !== 65 || pub[0] !== 4 || auth.length !== 16) return false;
    // A point off the curve fails here, not at the first message.
    const probe = createECDH("prime256v1");
    probe.generateKeys();
    probe.computeSecret(pub);
    return true;
  } catch {
    return false;
  }
}

const hkdf = (salt: Buffer, ikm: Buffer, info: Buffer, length: number) =>
  Buffer.from(hkdfSync("sha256", ikm, salt, info, length));

function keysFor(
  shared: Buffer,
  auth: Buffer,
  salt: Buffer,
  uaPublic: Buffer,
  asPublic: Buffer,
): { cek: Buffer; nonce: Buffer } {
  const keyInfo = Buffer.concat([Buffer.from("WebPush: info\0"), uaPublic, asPublic]);
  const ikm = hkdf(auth, shared, keyInfo, 32);
  return {
    cek: hkdf(salt, ikm, Buffer.from("Content-Encoding: aes128gcm\0"), 16),
    nonce: hkdf(salt, ikm, Buffer.from("Content-Encoding: nonce\0"), 12),
  };
}

/**
 * Encrypts a message for a subscriber. `salt` and `asPrivate` exist for the RFC's test vectors:
 * otherwise both are new for every message.
 */
export function encrypt(
  plaintext: Uint8Array,
  keys: SubscriberKeys,
  o: { salt?: Buffer; asPrivate?: Buffer } = {},
): Buffer {
  if (plaintext.length > MAX_PLAINTEXT)
    throw new Error(`A push message holds at most ${MAX_PLAINTEXT} bytes`);
  const uaPublic = unb64u(keys.p256dh);
  const auth = unb64u(keys.auth);
  const ecdh = createECDH("prime256v1");
  if (o.asPrivate) ecdh.setPrivateKey(o.asPrivate);
  else ecdh.generateKeys();
  const asPublic = ecdh.getPublicKey();
  const shared = ecdh.computeSecret(uaPublic);
  const salt = o.salt ?? randomBytes(16);
  const { cek, nonce } = keysFor(shared, auth, salt, uaPublic, asPublic);
  const cipher = createCipheriv("aes-128-gcm", cek, nonce);
  const body = Buffer.concat([
    cipher.update(Buffer.concat([plaintext, Buffer.from([2])])),
    cipher.final(),
    cipher.getAuthTag(),
  ]);
  const rs = Buffer.alloc(4);
  rs.writeUInt32BE(RECORD_SIZE);
  return Buffer.concat([salt, rs, Buffer.from([asPublic.length]), asPublic, body]);
}

/**
 * Decrypts a one-record message with the subscriber's private key: what the device does (the
 * tests' fake endpoint, the RFC's vectors).
 */
export function decrypt(body: Buffer, uaPrivate: Buffer, auth: Buffer): Buffer {
  const salt = body.subarray(0, 16);
  const idlen = body[20] ?? 0;
  const asPublic = body.subarray(21, 21 + idlen);
  const data = body.subarray(21 + idlen);
  const ecdh = createECDH("prime256v1");
  ecdh.setPrivateKey(uaPrivate);
  const shared = ecdh.computeSecret(asPublic);
  const { cek, nonce } = keysFor(shared, auth, salt, ecdh.getPublicKey(), asPublic);
  const decipher = createDecipheriv("aes-128-gcm", cek, nonce);
  decipher.setAuthTag(data.subarray(data.length - 16));
  const record = Buffer.concat([
    decipher.update(data.subarray(0, data.length - 16)),
    decipher.final(),
  ]);
  // The last record ends with 0x02 and zero padding.
  let end = record.length - 1;
  while (end >= 0 && record[end] === 0) end--;
  if (record[end] !== 2) throw new Error("Not the last record");
  return record.subarray(0, end);
}

// --- VAPID (RFC 8292) ---------------------------------------------------------------------

/** The installation's VAPID key pair, kept in the keychain as its private scalar (base64url). */
export interface VapidKeys {
  /** The uncompressed public key, base64url (the `k` of the Authorization header). */
  publicKey: string;
  privateKey: KeyObject;
}

export function newVapidPrivate(): string {
  return b64u(randomScalar());
}

function randomScalar(): Buffer {
  // A valid P-256 private key: createECDH checks it is in range.
  for (;;) {
    const d = randomBytes(32);
    try {
      createECDH("prime256v1").setPrivateKey(d);
      return d;
    } catch {}
  }
}

/** The key pair from the private scalar kept in the keychain. */
export function vapidKeys(privateScalar: string): VapidKeys {
  const d = unb64u(privateScalar);
  const ecdh = createECDH("prime256v1");
  ecdh.setPrivateKey(d);
  const pub = ecdh.getPublicKey();
  const privateKey = createPrivateKey({
    key: {
      kty: "EC",
      crv: "P-256",
      d: b64u(d),
      x: b64u(pub.subarray(1, 33)),
      y: b64u(pub.subarray(33, 65)),
    },
    format: "jwk",
  });
  return { publicKey: b64u(pub), privateKey };
}

/** An ES256 JSON Web Token (the VAPID token, and APNs' provider token in the relay). */
export function es256Jwt(
  header: Record<string, unknown>,
  claims: Record<string, unknown>,
  key: KeyObject,
): string {
  const part = (o: unknown) => b64u(Buffer.from(JSON.stringify(o)));
  const data = `${part({ typ: "JWT", alg: "ES256", ...header })}.${part(claims)}`;
  const sig = sign("sha256", Buffer.from(data), { key, dsaEncoding: "ieee-p1363" });
  return `${data}.${b64u(sig)}`;
}

/**
 * The Authorization header for one push service: `aud` is the endpoint's origin, `exp` at most
 * 24 hours ahead (12 here).
 */
export function vapidAuthorization(
  endpoint: string,
  keys: VapidKeys,
  subject: string,
  now: number = Date.now(),
): string {
  const jwt = es256Jwt(
    {},
    { aud: new URL(endpoint).origin, exp: Math.floor(now / 1000) + 12 * 3600, sub: subject },
    keys.privateKey,
  );
  return `vapid t=${jwt}, k=${keys.publicKey}`;
}
