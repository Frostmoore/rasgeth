// Signatures made by release.yml's own signer (packaging/update/sign.mjs), for the app's update
// tests (G41.8b): a throwaway key (never the real one), a SHA256SUMS-companion signed with it, the
// same list signed by another key, and the list changed after signing.
//   node apps/companion/tool/update_vectors.mjs > apps/companion/test/fixtures/update_vectors.json
import { createHash, generateKeyPairSync } from "node:crypto";
import { dotnetXml, signManifest } from "../../../packaging/update/sign.mjs";

const pair = () =>
  generateKeyPairSync("rsa", {
    modulusLength: 3072,
    publicKeyEncoding: { type: "spki", format: "pem" },
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
  });
const key = pair();
const other = pair();
const xml = dotnetXml(key.publicKey);
const part = (tag) => new RegExp(`<${tag}>([^<]*)</${tag}>`).exec(xml)[1];

// The packages the fake release carries: their bytes are made by the test from these texts.
const files = {
  "RGCompanion-Setup.exe": "MZ fake installer 3.9.0\n",
  "rgcompanion-linux-x64.tar.gz": "fake archive 3.9.0\n",
};
const sha = (s) => createHash("sha256").update(s).digest("hex");
const sums = `${Object.entries(files)
  .map(([n, b]) => `${sha(b)}  ${n}`)
  .join("\n")}\n`;
const sig = `${signManifest(Buffer.from(sums), key.privateKey)}\n`;

console.log(
  JSON.stringify(
    {
      modulus: part("Modulus"),
      exponent: part("Exponent"),
      files,
      sums,
      sig,
      otherKeySig: `${signManifest(Buffer.from(sums), other.privateKey)}\n`,
      changedSums: sums.replace(/^./, (c) => (c === "0" ? "1" : "0")),
    },
    null,
    2,
  ),
);
