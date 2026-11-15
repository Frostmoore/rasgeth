// Web Push encryption (G40.4): RFC 8291's own test vector (Appendix A), a round trip, and the
// VAPID token of RFC 8292 checked with the public key it announces.
import { createECDH, createPublicKey, verify } from "node:crypto";
import { describe, expect, it } from "vitest";
import {
  b64u,
  decrypt,
  encrypt,
  MAX_PLAINTEXT,
  newVapidPrivate,
  unb64u,
  validKeys,
  vapidAuthorization,
  vapidKeys,
} from "../src/push/ece.js";

// RFC 8291, Appendix A.
const RFC = {
  plaintext: "V2hlbiBJIGdyb3cgdXAsIEkgd2FudCB0byBiZSBhIHdhdGVybWVsb24",
  asPrivate: "yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw",
  asPublic:
    "BP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A8",
  uaPrivate: "q1dXpw3UpT5VOmu_cf_v6ih07Aems3njxI-JWgLcM94",
  uaPublic:
    "BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4",
  salt: "DGv6ra1nlYgDCS1FRnbzlw",
  auth: "BTBZMqHH6r4Tts7J_aSIgg",
  message:
    "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN",
};

describe("RFC 8291 encryption", () => {
  it("matches the RFC's test vector", () => {
    const out = encrypt(
      unb64u(RFC.plaintext),
      { p256dh: RFC.uaPublic, auth: RFC.auth },
      { salt: unb64u(RFC.salt), asPrivate: unb64u(RFC.asPrivate) },
    );
    expect(b64u(out)).toBe(RFC.message);
  });

  it("decrypts the RFC's message with the user agent's key", () => {
    const plain = decrypt(unb64u(RFC.message), unb64u(RFC.uaPrivate), unb64u(RFC.auth));
    expect(plain.toString()).toBe("When I grow up, I want to be a watermelon");
  });

  it("round-trips with fresh keys, and every message is different", () => {
    const ua = createECDH("prime256v1");
    ua.generateKeys();
    const keys = { p256dh: b64u(ua.getPublicKey()), auth: b64u(Buffer.alloc(16, 7)) };
    const text = Buffer.from("Una richiesta per te");
    const a = encrypt(text, keys);
    const b = encrypt(text, keys);
    expect(a.equals(b)).toBe(false);
    expect(decrypt(a, ua.getPrivateKey(), Buffer.alloc(16, 7)).toString()).toBe(
      "Una richiesta per te",
    );
  });

  it("refuses a message longer than one record", () => {
    const keys = { p256dh: RFC.uaPublic, auth: RFC.auth };
    expect(() => encrypt(Buffer.alloc(MAX_PLAINTEXT + 1), keys)).toThrow(/at most/);
    expect(encrypt(Buffer.alloc(MAX_PLAINTEXT), keys).length).toBe(4096);
  });

  it("checks the shape of a subscriber's keys", () => {
    expect(validKeys({ p256dh: RFC.uaPublic, auth: RFC.auth })).toBe(true);
    expect(validKeys({ p256dh: RFC.uaPublic, auth: "short" })).toBe(false);
    expect(validKeys({ p256dh: b64u(Buffer.alloc(65, 4)), auth: RFC.auth })).toBe(false);
    expect(validKeys({ p256dh: "", auth: RFC.auth })).toBe(false);
  });
});

describe("VAPID (RFC 8292)", () => {
  it("signs a token for the endpoint's origin that its public key verifies", () => {
    const keys = vapidKeys(newVapidPrivate());
    const now = Date.UTC(2026, 10, 15);
    const header = vapidAuthorization(
      "https://push.example.net/up/abc?x=1",
      keys,
      "mailto:a@b",
      now,
    );
    const m = header.match(/^vapid t=([^,]+), k=(.+)$/);
    expect(m?.[2]).toBe(keys.publicKey);
    const [h, c, s] = (m?.[1] ?? "").split(".");
    expect(JSON.parse(unb64u(h ?? "").toString())).toEqual({ typ: "JWT", alg: "ES256" });
    expect(JSON.parse(unb64u(c ?? "").toString())).toEqual({
      aud: "https://push.example.net",
      exp: now / 1000 + 12 * 3600,
      sub: "mailto:a@b",
    });
    const pub = unb64u(keys.publicKey);
    const key = createPublicKey({
      key: { kty: "EC", crv: "P-256", x: b64u(pub.subarray(1, 33)), y: b64u(pub.subarray(33)) },
      format: "jwk",
    });
    expect(
      verify(
        "sha256",
        Buffer.from(`${h}.${c}`),
        { key, dsaEncoding: "ieee-p1363" },
        unb64u(s ?? ""),
      ),
    ).toBe(true);
  });

  it("gives the same public key for the same private scalar", () => {
    const d = newVapidPrivate();
    expect(vapidKeys(d).publicKey).toBe(vapidKeys(d).publicKey);
    expect(unb64u(vapidKeys(d).publicKey)).toHaveLength(65);
  });
});
