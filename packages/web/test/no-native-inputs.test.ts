// Never native checkboxes, radio buttons or selects in the page (the person's decision of
// 2026-11-09, selects since 3.10.1): on/off is our switch (`Toggle`, `SmallSwitch` in ui.tsx,
// `Switch`/`SwitchRow` in SettingsKit.tsx), choices are our drawn controls (`DropChoice` for a
// list). The styles may still name them (to leave them out of a rule), and so may comments; the
// sources may not make one.
import { readdirSync, readFileSync } from "node:fs";
import { join, relative } from "node:path";
import { describe, expect, it } from "vitest";

const SRC = join(import.meta.dirname, "..", "src");

function sources(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
    e.isDirectory()
      ? sources(join(dir, e.name))
      : /\.(tsx?|jsx?|mjs|html)$/.test(e.name)
        ? [join(dir, e.name)]
        : [],
  );
}

/** A native select or its options, as JSX or made by hand. */
const NATIVE_SELECT =
  /<(select|option|optgroup)(\s|>|\/|$)|createElement\(\s*["'](select|option)["']/;

/** Every source line that matches, outside comments, as `file:line: text`. */
function lines(re: RegExp): string[] {
  return sources(SRC).flatMap((f) =>
    readFileSync(f, "utf8")
      .split("\n")
      .flatMap((line, i) => {
        const code = line.trim();
        if (/^(\/\/|\/\*|\*)/.test(code)) return [];
        return re.test(code) ? [`${relative(SRC, f)}:${i + 1}: ${code}`] : [];
      }),
  );
}

describe("native inputs", () => {
  it("no checkbox or radio button anywhere in the page's sources", () => {
    expect(lines(/type\s*[=:]\s*\{?\s*["'](checkbox|radio)["']/)).toEqual([]);
  });

  it("no native select (or its options) anywhere in the page's sources", () => {
    expect(lines(NATIVE_SELECT)).toEqual([]);
  });

  it("the check itself sees a select", () => {
    for (const code of [
      "<select",
      "<select value={v} onChange={go}>",
      "<option>",
      'createElement("select")',
    ])
      expect(NATIVE_SELECT.test(code)).toBe(true);
    for (const code of ["<selection />", "<SelectTool", "<options-list>"])
      expect(NATIVE_SELECT.test(code)).toBe(false);
  });
});
