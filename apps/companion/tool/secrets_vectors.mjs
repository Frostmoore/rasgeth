// Writes test/fixtures/secrets_vectors.json: texts and what @redgiant/protocol's own `findSecrets`
// and `hideSecrets` make of them (the recogniser the server, the chats and the page share), so
// test/g42_1_secrets_test.dart checks that lib/api/secrets.dart finds the very same spans, at the
// same UTF-16 positions, and hides them the same way (G42.1).
//
//   pnpm exec tsc -b packages/protocol && node apps/companion/tool/secrets_vectors.mjs
import { writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const lib = resolve(process.argv[2] ?? join(here, "../../../packages/protocol/dist/index.js"));
const { findSecrets, hideSecrets, hasSecret, SECRET_PATTERNS } = await import(
  pathToFileURL(lib).href
);

const pem = [
  "-----BEGIN RSA PRIVATE KEY-----",
  "MIIEowIBAAKCAQEA1b2c3d4e5f6g7h8i9j0kLmNoPqRsTuVwXyZ",
  "abcdefABCDEF0123456789+/=",
  "-----END RSA PRIVATE KEY-----",
].join("\n");

const texts = [
  // Nothing secret.
  "",
  "Ciao, come stai?",
  "il password manager è comodo",
  "uso il PIN sul telefono",
  "la password è lunga",
  "my password is strong",
  "The token expired yesterday.",
  "https://example.com/elon-musk-s-2026-political-donations-explained",
  "Chiamami al 333 1234567 domani",
  "Il codice fiscale è RSSMRA80A01H501U.",
  "sk-short1",
  "the API key is in the vault",
  // Well-known keys.
  "my key is sk-ant-api03-AbCdEf0123456789ghIJklMNopQRstuv-wxyz_12",
  "OPENAI_API_KEY=sk-proj-abcdefghij1234567890KLMNOPqrst",
  "export OPENAI=sk-abcdefghijklmnopqrstu1vwxyz",
  "token ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
  "github_pat_11ABCDEFG0123456789_abcdefghijklmnopqrstuvwxyz",
  "hf_abcdefghijklmnopqrstuvwxyzABCDEF12",
  "AWS key AKIAIOSFODNN7EXAMPLE and more",
  "AIzaSyD-1234567890abcdefghijklmnopqrstu",
  "slack xoxb-1234567890-abcdefghij",
  "bot 123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsawABC",
  "Authorization: Bearer abcdefghijklmnopqrstuvwxyz.0123456789",
  `Here it is:\n${pem}\nthanks`,
  // Passwords, PINs, keys with words.
  "password: hunter22",
  "Password=Secr3t!x",
  "la password del wifi è casa1234",
  "la password della mail è «Gatto99»",
  "my password is correcthorse",
  "pwd: abc",
  "passphrase = 'a long phrase'",
  "parola d'ordine: Sesamo",
  "il mio PIN è 12345",
  "PIN 1234",
  "CVV: 123",
  "codice pin 98765",
  "OTP 482913 valid for 5 minutes",
  "api key: abcd1234efgh5678ijkl",
  "token = 0123456789abcdefABCD",
  "chiave api è ZZZZ1111yyyy2222xxxx",
  "access key AKIA but not really0123456789",
  "secret: onlylettersnodigitshere",
  // Random strings and JWTs.
  "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U",
  "id Ab3dEfGhIjKlMnOpQrStUvWx end",
  "abcdefghijklmnopqrstuvwxyz0123456789",
  // Cards and IBANs.
  "carta 4111 1111 1111 1111 scade 12/28",
  "card 4111-1111-1111-1112",
  "5500005555555559",
  "IBAN IT60 X054 2811 1010 0000 0123 456",
  "IT60X0542811101000000123456",
  "DE89370400440532013000",
  "GB82 WEST 1234 5698 7654 32",
  "IT60X0542811101000000123457",
  // Several in one text, overlapping, accents and emoji before them (UTF-16 positions).
  "Perché è così: password: àccènto9 e PIN 4321 😀 e sk-ant-api03-ZZZZZZZZZZZZZZZZZZZZ0123",
  "😀😀 token: 😀abcd1234efgh5678ijkl",
  "Caffè ☕ ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 poi 🎉 AKIAIOSFODNN7EXAMPLE",
  "Bearer sk-ant-api03-AbCdEf0123456789ghIJklMNopQRstuv",
  "token: sk-abcdefghijklmnopqrstu1vwxyz and api key = sk-abcdefghijklmnopqrstu1vwxyz",
  "城市 password: 東京1234 ok",
  "Ünïcödé PASSWORD: Straße42 ſ",
  "line one\npassword: first1\nline three\npin: 0000\n",
  "PaSsWoRd Is VeRyLoNg99",
  "La password per il server è lunga ma la password è Zeta1234",
  "mail: anna@example.com, tel. +39 02 1234 5678",
];

const out = texts.map((text) => ({
  text,
  found: findSecrets(text),
  hidden: hideSecrets(text, "[secret removed]").text,
  hiddenDefault: hideSecrets(text).text,
  has: hasSecret(text),
}));

writeFileSync(
  join(here, "../test/fixtures/secrets_vectors.json"),
  `${JSON.stringify(
    { patterns: SECRET_PATTERNS.map((p) => ({ name: p.name, source: p.re.source, flags: p.re.flags })), vectors: out },
    null,
    1,
  )}\n`,
);
console.log(`${out.length} vectors, ${out.filter((o) => o.has).length} with secrets`);
