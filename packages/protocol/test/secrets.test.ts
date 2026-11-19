// Secrets in links (2026-11-19, the person's Amazon link taken for a secret): inside an http(s)
// link a parameter is a secret only by its name (token, signature, api_key…) or a well-known key
// format (SECRET_PATTERNS, a real JWT); long mixed ids, tracking codes and the like are not. A
// «JWT» whose header has no `alg` is not one. Outside links nothing changes.
import { describe, expect, it } from "vitest";
import { findSecrets, hasSecret, hideSecrets } from "../src/secrets.js";

const JWT =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
const GHP = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

/** Links that are not secrets: they go as they are. */
const NOT_SECRET: [string, string][] = [
  [
    "the person's Amazon link (dib=eyJ2IjoiMSJ9.…, crid, sprefix)",
    "https://www.amazon.it/Apple-AirPods-Pro-2/dp/B0CHWRXH8B/ref=sr_1_1?__mk_it_IT=%C3%85M%C3%85%C5%BD%C3%95%C3%91&crid=2X3K9QZ7M1ABC&dib=eyJ2IjoiMSJ9.M4fWq7XkPz3RtY8sLmN2bVcQ9wEaH5jK1oUiP0lZxCv6BnM_gTyR4eDs.Xk9Lq2Wm8NvBz3PcRf7HtY5gJu1KoI0aSdE6&dib_tag=se&keywords=airpods+pro&qid=1732012345&sprefix=airpods%2Caps%2C120&sr=8-1",
  ],
  [
    "the same link in a sentence",
    "guarda questo: https://www.amazon.it/dp/B0CHWRXH8B?dib=eyJ2IjoiMSJ9.M4fWq7XkPz3RtY8sLmN2bVcQ9wEaH5jK1oUiP0lZxCv6BnM.Xk9Lq2Wm8NvBz3PcRf7HtY5gJu1&dib_tag=se, costa poco",
  ],
  [
    "Google Maps",
    "https://www.google.com/maps/place/Colosseo/@41.8902102,12.4922309,17z/data=!3m1!4b1!4m6!3m5!1s0x132f61b6532013ad:0x28f1c82e908503c4!8m2!3d41.8902102!4d12.4922309!16zL20vMGQ1cXg?entry=ttu&g_ep=EgoyMDI0MTExMy4xIKXMDSoASAFQAw%3D%3D",
  ],
  [
    "YouTube with a share id and a playlist",
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=Kz3pQ8vR2mN7xT1bLw9YcA&list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG",
  ],
  [
    "a long tracking link",
    "https://click.example-mail.com/ls/click?upn=u001.Qk8xT2Vz9pLmN4rB7cD1fG3hJ5kL8mN0pQ2rS4tU6vW8xY0zA2bC4dE6fG8hI0jK&utm_source=newsletter&utm_campaign=Nov2026Promo_A1b2C3d4E5f6G7h8",
  ],
  [
    "a path with a long mixed id",
    "https://drive.example.com/file/d/1aB2cD3eF4gH5iJ6kL7mN8oP9qR0sT/view",
  ],
  ["a Pinterest pin (not a PIN)", "https://www.pinterest.com/pin/123456789/"],
  ["a «JWT» without alg outside a link", "il codice è eyJ2IjoiMSJ9.abcdefgh12.ijklmnop34"],
  ["a short key= that says nothing", "https://example.com/search?key=abc&monkey=Zx81Kq0pLm2Nb7Vc9"],
];

/** Still secrets, and which value must be found. */
const SECRET: [string, string, string][] = [
  [
    "an S3 signed link (the credential's key and the signature)",
    "https://my-bucket.s3.amazonaws.com/report.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20261119%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20261119T120000Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=3f9c1b7e2a5d8c4f6e0b9a1d2c3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e",
    "3f9c1b7e2a5d8c4f6e0b9a1d2c3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e",
  ],
  [
    "an S3 link's security token",
    "https://b.s3.amazonaws.com/k?X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJr%2F%2F%2F%2Fwo&X-Amz-Date=20261119T120000Z",
    "IQoJb3JpZ2luX2VjEJr%2F%2F%2F%2Fwo",
  ],
  [
    "a GCS signed link",
    "https://storage.googleapis.com/bucket/file.zip?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Date=20261119T120000Z&X-Goog-Expires=900&X-Goog-Signature=8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b",
    "8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b",
  ],
  ["?token=", "https://example.com/download?token=Zx81Kq0pLm2Nb7Vc", "Zx81Kq0pLm2Nb7Vc"],
  [
    "?access_token=",
    "https://api.example.com/v1/data?fields=id&access_token=ya29.a0AfH6SMBx1yZ2Kq",
    "ya29.a0AfH6SMBx1yZ2Kq",
  ],
  ["?api_key=", "https://maps.example.com/api?api_key=4f7c9a2b1e8d6f3a&q=roma", "4f7c9a2b1e8d6f3a"],
  ["#access_token= in the fragment", "https://app.example.com/cb#access_token=Ab12Cd34Ef56Gh78&x=1", "Ab12Cd34Ef56Gh78"],
  ["Azure's sig=", "https://acct.blob.core.windows.net/c/f.txt?sv=2022-11-02&sig=Xy7%2BAb3cD9eF", "Xy7%2BAb3cD9eF"],
  ["a real JWT (alg) on its own", `il token: ${JWT}`, JWT],
  ["a real JWT (alg) in a link parameter of any name", `https://app.example.com/?state=${JWT}`, JWT],
  ["a known key format inside a link", `https://example.com/hook?x=${GHP}&y=1`, GHP],
  ["a long mixed string outside a link", "la chiave è Ab3dE5fG7hJ9kL1mN3pQ5rS7tU", "Ab3dE5fG7hJ9kL1mN3pQ5rS7tU"],
  ["a password next to a link", "password: hunter22 https://example.com", "hunter22"],
];

describe("secrets in links (2026-11-19)", () => {
  it.each(NOT_SECRET)("not a secret: %s", (_, text) => {
    expect(findSecrets(text)).toEqual([]);
    expect(hideSecrets(text).text).toBe(text);
  });

  it.each(SECRET)("still a secret: %s", (_, text, value) => {
    expect(hasSecret(text)).toBe(true);
    const found = findSecrets(text);
    expect(found.some((s) => s.value.includes(value))).toBe(true);
    expect(hideSecrets(text).text).not.toContain(value);
    // Only the value goes: the link's address and the other parameters stay.
    for (const s of found) expect(s.value).not.toMatch(/^https?:/);
  });

  it("the signed S3 link keeps its address and harmless parameters when hidden", () => {
    const [, text] = SECRET[0] as [string, string, string];
    const hidden = hideSecrets(text).text;
    expect(hidden).toContain("https://my-bucket.s3.amazonaws.com/report.pdf?X-Amz-Algorithm=");
    expect(hidden).toContain("X-Amz-Date=20261119T120000Z");
    expect(hidden).toContain("X-Amz-Signature=[secret]");
  });
});
