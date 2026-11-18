// @vitest-environment jsdom
// G42.0 (D1): RGCompanion does what the page does. apps/companion/parity.json has a row for every
// Settings section, Canvas viewer kind, chat item and wire message of the page, saying how the app
// does it (native, embed) or which phase brings it. This fails when the page has something the
// table does not name, or the table names something the page no longer has.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { ClientMessage, ServerMessage } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { GROUPS } from "../src/components/Settings.js";

const read = (p: string) => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8");
type Row = {
  app: string;
  files: string[];
  phase?: string;
  rows?: number[];
  note?: string;
  systems?: Record<string, string>;
};
const table = JSON.parse(read("../../../apps/companion/parity.json")) as Record<
  "settings" | "viewers" | "chat" | "client" | "server",
  Record<string, Row>
>;

/** The string members of a type union in a source file (`export type X = | "a" | "b";`). */
export function unionOf(source: string, name: string): string[] {
  const start = source.indexOf(`export type ${name} =`);
  if (start < 0) throw new Error(`no type ${name}`);
  const end = source.indexOf(";", start);
  const body = source
    .slice(start, end)
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\/\/.*$/gm, "");
  return [...body.matchAll(/"([\w.-]+)"/g)].map((m) => m[1] ?? "");
}

/** The `kind`s of the ChatItem union (each member's first `kind: "…"`). */
function chatKinds(source: string): string[] {
  const start = source.indexOf("export type ChatItem =");
  const end = source.indexOf("\nexport ", start + 1);
  return [
    ...new Set(
      [...source.slice(start, end).matchAll(/^\s*\|?\s*\{?\s*kind: "(\w+)"/gm)].map(
        (m) => m[1] ?? "",
      ),
    ),
  ];
}

const typesOf = (u: { options: readonly { shape: { type: { value: unknown } } }[] }) =>
  u.options.map((o) => String(o.shape.type.value));

const state = read("../src/state.ts");
const page = {
  settings: unionOf(state, "SettingsSection"),
  viewers: unionOf(read("../src/viewers/kind.ts"), "ViewerKind"),
  chat: chatKinds(state),
  client: typesOf(ClientMessage as never),
  server: typesOf(ServerMessage as never),
};
const STATES = ["native", "embed", "partial", "no", "n/a"];
const SYSTEMS = ["android", "ios", "windows", "macos", "linux"];

describe("the app's parity table (G42.0)", () => {
  it("reads the page's lists", () => {
    expect(unionOf('export type X =\n  | "a"\n  /** b */\n  | "c";', "X")).toEqual(["a", "c"]);
    expect(page.settings.length).toBeGreaterThan(20);
    expect(page.chat).toContain("widget");
    expect(page.client).toContain("session.send");
    expect(page.server).toContain("event");
    // Every section of the type is in Settings' list, and nothing else is.
    expect(GROUPS.flatMap((g) => g.sections.map((s) => s.id)).sort()).toEqual(
      [...page.settings].sort(),
    );
  });

  it.each(Object.entries(page))(
    "has a row for every %s of the page, and none it does not have",
    (group, keys) => {
      const rows = Object.keys(table[group as keyof typeof table]);
      expect({
        missing: keys.filter((k) => !rows.includes(k)),
        gone: rows.filter((k) => !keys.includes(k)),
      }).toEqual({
        missing: [],
        gone: [],
      });
    },
  );

  it("every row says how, with the app's files, or the phase that brings it", () => {
    const wrong: string[] = [];
    for (const [group, rows] of Object.entries(table).filter(([g]) => g in page))
      for (const [key, r] of Object.entries(rows)) {
        const at = `${group}.${key}`;
        if (!STATES.includes(r.app)) wrong.push(`${at}: app ${r.app}`);
        const doing = ["native", "embed", "partial"].includes(r.app);
        if (doing && !r.files?.length) wrong.push(`${at}: no file`);
        if ((r.app === "no" || r.app === "partial") && !/^G42\.\d+b?$/.test(r.phase ?? ""))
          wrong.push(`${at}: no phase`);
        for (const f of r.files ?? [])
          if (!/^lib\/[\w/.-]+\.dart$/.test(f)) wrong.push(`${at}: ${f}`);
        for (const [s, v] of Object.entries(r.systems ?? {}))
          if (!SYSTEMS.includes(s) || !["embed", "browser", "no"].includes(v))
            wrong.push(`${at}: ${s}=${v}`);
      }
    expect(wrong).toEqual([]);
  });
});
