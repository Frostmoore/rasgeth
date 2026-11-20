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

const JWT =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
const GHP = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

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
  // Links (2026-11-19): only named or known-format parameters, a JWT only with alg.
  "a header without alg eyJ2IjoiMSJ9.abcdefgh12.ijklmnop34 and one with eyJhbGciOiJub25lIn0.eyJzdWIiOiIxIn0.sig12345",
  "https://www.amazon.it/Apple-AirPods-Pro-2/dp/B0CHWRXH8B/ref=sr_1_1?__mk_it_IT=%C3%85M%C3%85%C5%BD%C3%95%C3%91&crid=2X3K9QZ7M1ABC&dib=eyJ2IjoiMSJ9.M4fWq7XkPz3RtY8sLmN2bVcQ9wEaH5jK1oUiP0lZxCv6BnM_gTyR4eDs.Xk9Lq2Wm8NvBz3PcRf7HtY5gJu1KoI0aSdE6&dib_tag=se&keywords=airpods+pro&qid=1732012345&sprefix=airpods%2Caps%2C120&sr=8-1",
  "guarda questo: https://www.amazon.it/dp/B0CHWRXH8B?dib=eyJ2IjoiMSJ9.M4fWq7XkPz3RtY8sLmN2bVcQ9wEaH5jK1oUiP0lZxCv6BnM.Xk9Lq2Wm8NvBz3PcRf7HtY5gJu1&dib_tag=se, costa poco",
  "https://www.google.com/maps/place/Colosseo/@41.8902102,12.4922309,17z/data=!3m1!4b1!4m6!3m5!1s0x132f61b6532013ad:0x28f1c82e908503c4!8m2!3d41.8902102!4d12.4922309!16zL20vMGQ1cXg?entry=ttu&g_ep=EgoyMDI0MTExMy4xIKXMDSoASAFQAw%3D%3D",
  "https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=Kz3pQ8vR2mN7xT1bLw9YcA&list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG",
  "https://click.example-mail.com/ls/click?upn=u001.Qk8xT2Vz9pLmN4rB7cD1fG3hJ5kL8mN0pQ2rS4tU6vW8xY0zA2bC4dE6fG8hI0jK&utm_source=newsletter&utm_campaign=Nov2026Promo_A1b2C3d4E5f6G7h8",
  "https://drive.example.com/file/d/1aB2cD3eF4gH5iJ6kL7mN8oP9qR0sT/view",
  "https://www.pinterest.com/pin/123456789/",
  "il codice è eyJ2IjoiMSJ9.abcdefgh12.ijklmnop34",
  "https://example.com/search?key=abc&monkey=Zx81Kq0pLm2Nb7Vc9",
  "https://my-bucket.s3.amazonaws.com/report.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20261119%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20261119T120000Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=3f9c1b7e2a5d8c4f6e0b9a1d2c3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e",
  "https://b.s3.amazonaws.com/k?X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJr%2F%2F%2F%2Fwo&X-Amz-Date=20261119T120000Z",
  "https://storage.googleapis.com/bucket/file.zip?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Date=20261119T120000Z&X-Goog-Expires=900&X-Goog-Signature=8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b",
  "https://example.com/download?token=Zx81Kq0pLm2Nb7Vc",
  "https://api.example.com/v1/data?fields=id&access_token=ya29.a0AfH6SMBx1yZ2Kq",
  "https://maps.example.com/api?api_key=4f7c9a2b1e8d6f3a&q=roma",
  "https://app.example.com/cb#access_token=Ab12Cd34Ef56Gh78&x=1",
  "https://acct.blob.core.windows.net/c/f.txt?sv=2022-11-02&sig=Xy7%2BAb3cD9eF",
  `il token: ${JWT}`,
  `https://app.example.com/?state=${JWT}`,
  `https://example.com/hook?x=${GHP}&y=1`,
  "la chiave è Ab3dE5fG7hJ9kL1mN3pQ5rS7tU",
  "password: hunter22 https://example.com",
  // Password managers' exports (3.9.8): one span with its rows. Generated fakes only.
  ...exports(),
];

/** Exports of each kind and look-alikes that are not, with generated values only. */
function exports() {
  const fake = (i) => `Fk${(i * 7919).toString(36)}#Qz${i % 10}x`;
  const site = (i) => `site${i}.example.com`;
  const rows = (n, row) => Array.from({ length: n }, (_, i) => row(i));
  return [
    ["folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp", ...rows(3, (i) => `,,login,Site ${i},,,0,https://${site(i)}/,u${i}@example.com,${fake(i)},`)].join("\n"),
    ["name,website,login,password,secondary_login,notes", ...rows(3, (i) => `Site ${i},https://${site(i)},u${i},${fake(i)},,`)].join("\n"),
    `ecco le password\n${["name,url,username,password", ...rows(4, (i) => `${site(i)},https://${site(i)}/,u${i},${fake(i)}`)].join("\r\n")}\ngrazie`,
    ['"url","username","password","httpRealm","formActionOrigin","guid"', ...rows(2, (i) => `"https://${site(i)}","u${i}","${fake(i)}",,"https://${site(i)}","{g${i}}"`)].join("\n"),
    ['"Group","Title","Username","Password","URL","Notes"', ...rows(2, (i) => `"Root","Site ${i}","u${i}","${fake(i)}","https://${site(i)}",""`)].join("\n"),
    ["sito;utente;password", ...rows(3, (i) => `${site(i)};u${i};${fake(i)}`)].join("\n"),
    JSON.stringify({ encrypted: false, items: rows(2, (i) => ({ name: `S${i}`, login: { username: `u${i}`, password: fake(i), uris: [{ uri: `https://${site(i)}` }] } })) }, null, 2),
    JSON.stringify({ accounts: [{ vaults: [{ items: rows(2, (i) => ({ overview: { title: `S${i}` }, details: { loginFields: [{ designation: "password", value: fake(i) }] } })) }] }] }),
    `<?xml version="1.0"?>\n<KeePassFile><Root>${rows(2, (i) => `<Entry><String><Key>Title</Key><Value>S${i}</Value></String><String><Key>Password</Key><Value>${fake(i)}</Value></String></Entry>`).join("")}</Root></KeePassFile>`,
    rows(4, (i) => `${site(i)} u${i}@example.com ${fake(i)}`).join("\n"),
    rows(3, (i) => `Banca ${i}\tutente${i}\t${fake(i)}`).join("\n"),
    `prima riga\n${rows(3, (i) => `${site(i)} u${i}@example.com ${fake(i)}`).join("\n")}\n\npassword: hunter22`,
    // Not exports.
    ["date,amount,description", ...rows(4, (i) => `2026-01-0${i + 1},12.50,coffee ${i}`)].join("\n"),
    ["name,email,role", ...rows(3, (i) => `Person ${i},p${i}@example.com,admin`)].join("\n"),
    "the file has these columns: name,url,username,password",
    rows(4, (i) => `192.168.1.${i} GET example.com/api/v1/items 200 ${12 + i}ms`).join("\n"),
    JSON.stringify({ smtp: { host: "mail.example.com", user: "me", password: "x" } }),
    "example.com Mario Rossi\nexample.org Anna Bianchi\nexample.net Luca Verdi",
    "core.example.com v1.2.3 2026-11-01\napi.example.com v2.0.0 2026-11-02\nweb.example.com v3.1.4 2026-11-03",
  ];
}

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
