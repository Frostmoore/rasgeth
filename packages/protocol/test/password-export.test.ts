// Password exports pasted in a message (3.9.8): every manager's export is recognised with its rows
// counted, and ordinary CSVs, code and logs are not. Every value here is generated: no real
// password ever appears in a test.
import { describe, expect, it } from "vitest";
import {
  findPasswordExports,
  looksLikePassword,
  passwordExportRows,
  readPasswordExport,
  withoutPasswordExports,
} from "../src/password-export.js";
import { findSecrets, hideSecrets } from "../src/secrets.js";

/** A fake password, different for each row (letters, digits and a symbol, never a real one). */
const fake = (i: number) => `Fk${(i * 7919).toString(36)}#Qz${i % 10}x`;
const sites = (n: number) => Array.from({ length: n }, (_, i) => `site${i}.example.com`);

const csv = (header: string, row: (i: number) => string, n = 3) =>
  [header, ...Array.from({ length: n }, (_, i) => row(i))].join("\n");

/** [what, text, kind, rows]: exports that must be held. */
const EXPORTS: [string, string, string, number][] = [
  [
    "Bitwarden CSV",
    csv(
      "folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp",
      (i) => `,,login,Site ${i},,,0,https://${sites(9)[i]}/,user${i}@example.com,${fake(i)},`,
      4,
    ),
    "bitwarden",
    4,
  ],
  [
    "Avira CSV",
    csv("name,website,login,password,secondary_login,notes", (i) => {
      return `Site ${i},https://${sites(9)[i]},user${i},${fake(i)},,`;
    }),
    "avira",
    3,
  ],
  [
    "Chrome and Edge CSV",
    csv(
      "name,url,username,password,note",
      (i) => `${sites(9)[i]},https://${sites(9)[i]}/,u${i},${fake(i)},`,
      5,
    ),
    "chrome",
    5,
  ],
  [
    "Firefox CSV, quoted",
    csv(
      '"url","username","password","httpRealm","formActionOrigin","guid","timeCreated","timeLastUsed","timePasswordChanged"',
      (i) =>
        `"https://${sites(9)[i]}","u${i}","${fake(i)}",,"https://${sites(9)[i]}","{guid-${i}}","1700000000000","1700000000000","1700000000000"`,
    ),
    "firefox",
    3,
  ],
  [
    "1Password CSV",
    csv("Title,Url,Username,Password,OTPAuth,Favorite,Archived,Tags,Notes", (i) => {
      return `Site ${i},https://${sites(9)[i]},u${i},${fake(i)},,false,false,,`;
    }),
    "1password",
    3,
  ],
  [
    "KeePass CSV (KeePassXC)",
    csv(
      '"Group","Title","Username","Password","URL","Notes","TOTP","Icon","Last Modified","Created"',
      (i) =>
        `"Root","Site ${i}","u${i}","${fake(i)}","https://${sites(9)[i]}","","","0","2026-01-01","2026-01-01"`,
    ),
    "keepass",
    3,
  ],
  [
    "KeePass 1 CSV",
    csv('"Account","Login Name","Password","Web Site","Comments"', (i) => {
      return `"Site ${i}","u${i}","${fake(i)}","https://${sites(9)[i]}",""`;
    }),
    "keepass",
    3,
  ],
  [
    "a CSV with a semicolon and a password column, after the person's words",
    `ecco le mie password, mettile a posto\n${csv("sito;utente;password", (i) => `${sites(9)[i]};u${i};${fake(i)}`, 6)}\ngrazie`,
    "csv",
    6,
  ],
  [
    "a single row under its header",
    csv("name,url,username,password", (i) => `x,https://${sites(9)[i]},u,${fake(i)}`, 1),
    "chrome",
    1,
  ],
  [
    "Bitwarden JSON",
    JSON.stringify(
      {
        encrypted: false,
        folders: [],
        items: [0, 1, 2].map((i) => ({
          id: `id-${i}`,
          type: 1,
          name: `Site ${i}`,
          login: {
            uris: [{ uri: `https://${sites(9)[i]}` }],
            username: `u${i}`,
            password: fake(i),
          },
        })),
      },
      null,
      2,
    ),
    "bitwarden",
    3,
  ],
  [
    "1Password 1pux text",
    JSON.stringify({
      accounts: [
        {
          vaults: [
            {
              items: [0, 1].map((i) => ({
                overview: { title: `Site ${i}`, url: `https://${sites(9)[i]}` },
                details: {
                  loginFields: [
                    { designation: "username", value: `u${i}` },
                    { designation: "password", value: fake(i) },
                  ],
                },
              })),
            },
          ],
        },
      ],
    }),
    "1password",
    2,
  ],
  [
    "KeePass 2 XML",
    `<?xml version="1.0" encoding="utf-8"?>\n<KeePassFile><Root><Group>${[0, 1, 2]
      .map(
        (i) =>
          `<Entry><String><Key>Title</Key><Value>Site ${i}</Value></String><String><Key>UserName</Key><Value>u${i}</Value></String><String><Key>Password</Key><Value ProtectInMemory="True">${fake(i)}</Value></String><String><Key>URL</Key><Value>https://${sites(9)[i]}</Value></String></Entry>`,
      )
      .join("\n")}</Group></Root></KeePassFile>`,
    "keepass",
    3,
  ],
  [
    "a plain list: site user password",
    sites(5)
      .map((s, i) => `${s} user${i}@example.com ${fake(i)}`)
      .join("\n"),
    "list",
    5,
  ],
  [
    "a plain list with tabs and names",
    [0, 1, 2, 3].map((i) => `Banca ${i}\tutente${i}\t${fake(i)}`).join("\n"),
    "list",
    4,
  ],
];

/** Texts that are not exports: they go as written. */
const NOT_EXPORTS: [string, string][] = [
  [
    "an ordinary CSV",
    csv("date,amount,description", (i) => `2026-01-0${i + 1},12.50,coffee ${i}`, 5),
  ],
  [
    "a CSV of users without passwords",
    csv("name,email,role", (i) => `Person ${i},p${i}@example.com,admin`, 5),
  ],
  [
    "a header naming a password column, without rows",
    "the file has these columns: name,url,username,password",
  ],
  [
    "an access log",
    [0, 1, 2, 3]
      .map((i) => `192.168.1.${i} GET example.com/api/v1/items 200 ${12 + i}ms`)
      .join("\n"),
  ],
  [
    "code",
    'const user = { name: "a", password: hash(input) };\nif (user.password !== expected) throw new Error("no");\nreturn login(user.name, user.password);',
  ],
  [
    "a JSON setting with one password field",
    JSON.stringify({ smtp: { host: "mail.example.com", user: "me", password: "x" } }),
  ],
  [
    "a list of sites and people",
    "example.com Mario Rossi\nexample.org Anna Bianchi\nexample.net Luca Verdi",
  ],
  [
    "versions in a changelog",
    "core.example.com v1.2.3 2026-11-01\napi.example.com v2.0.0 2026-11-02\nweb.example.com v3.1.4 2026-11-03",
  ],
  [
    "prose about a password manager",
    "Ho esportato le password da Avira, come le metto nel portachiavi?",
  ],
];

describe("password exports (3.9.8)", () => {
  it.each(EXPORTS)("holds %s", (_what, text, kind, rows) => {
    const found = findPasswordExports(text);
    expect(found.map((f) => f.kind)).toEqual([kind]);
    expect(passwordExportRows(text)).toBe(rows);
    expect(readPasswordExport(text).rows).toHaveLength(rows);
  });

  it.each(NOT_EXPORTS)("lets %s go", (_what, text) => {
    expect(findPasswordExports(text)).toEqual([]);
  });

  it("reads every row with its site, user and value", () => {
    const text = EXPORTS[0]?.[1] ?? "";
    const { rows } = readPasswordExport(text);
    expect(rows[1]).toEqual({
      service: "Site 1",
      username: "user1@example.com",
      value: fake(1),
      url: `https://${sites(9)[1]}/`,
      notes: "",
    });
  });

  it("removes the export and keeps the person's words («Invia senza»)", () => {
    const text = EXPORTS[7]?.[1] ?? "";
    const out = withoutPasswordExports(text);
    expect(out.rows).toBe(6);
    expect(out.text).toBe(
      "ecco le mie password, mettile a posto\n[password export removed]\ngrazie",
    );
    for (let i = 0; i < 6; i++) expect(out.text).not.toContain(fake(i));
  });

  it("is one span in findSecrets, with its count, and hideSecrets blanks it whole", () => {
    const text = `ciao\n${EXPORTS[2]?.[1] ?? ""}`;
    const found = findSecrets(text);
    expect(found.map((f) => [f.kind, f.rows])).toEqual([["export", 5]]);
    const hidden = hideSecrets(text, "[x]").text;
    expect(hidden).toBe("ciao\n[x]");
  });

  it("two exports in one message count together", () => {
    const a = EXPORTS[1]?.[1] ?? "";
    const b = EXPORTS[12]?.[1] ?? "";
    expect(passwordExportRows(`${a}\n\nand also\n\n${b}`)).toBe(8);
  });

  it.each([
    ["Fk2x#Qz1x", true],
    ["hunter2a", true],
    ["2026-11-20", false],
    ["12.5ms", false],
    ["example.com", false],
    ["abcdefgh", false],
  ])("looksLikePassword(%s) = %s", (v, ok) => {
    expect(looksLikePassword(v)).toBe(ok);
  });
});
