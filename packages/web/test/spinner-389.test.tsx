// @vitest-environment jsdom
// 3.8.9, the person: «il cerchietto vicino ai comandi non gira». Every «in progress» spinner
// turns (`.icon.spinner`), the tool line swaps it for its done or failed mark, and with reduced
// motion the spinner stays still and shows three dots instead of a frozen arc.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { cleanup, render } from "@testing-library/preact";
import { afterEach, describe, expect, it } from "vitest";
import { ToolLine } from "../src/components/Chat.js";
import { IconSpinner } from "../src/icons.js";

afterEach(cleanup);
const css = readFileSync(join(import.meta.dirname, "..", "src", "styles.css"), "utf8");

/** The body of the first rule whose selector list is exactly `selector`, from `from` on. */
function rule(text: string, selector: string): string | undefined {
  const at = text.indexOf(`\n${selector} {`);
  if (at < 0) return undefined;
  return text.slice(text.indexOf("{", at) + 1, text.indexOf("}", at));
}
const reduced = (() => {
  const blocks = css.split("@media (prefers-reduced-motion: reduce) {").slice(1);
  return blocks.find((b) => b.includes(".icon.spinner")) ?? "";
})();

const tool = (result?: { ok: boolean; output: string }) =>
  ({
    kind: "tool",
    key: "t1",
    callId: "c1",
    tool: "bash_output",
    input: { id: "x" },
    result,
  }) as const;

describe("the spinner", () => {
  it("is an arc that turns, with still dots kept for reduced motion", () => {
    const r = render(<IconSpinner />);
    const svg = r.container.querySelector("svg");
    expect(svg?.getAttribute("class")).toBe("icon spinner");
    expect(svg?.querySelector(".spinner-arc")).not.toBeNull();
    expect(svg?.querySelectorAll(".spinner-dots circle")).toHaveLength(3);
    expect(rule(css, ".icon.spinner")).toContain("animation: spin 1s linear infinite");
    expect(rule(css, ".icon.spinner .spinner-dots")).toContain("display: none");
  });

  it("stays still and shows the dots with reduced motion", () => {
    expect(reduced).toMatch(
      /\.icon\.spinner,\s*\.icon\.spinner \* \{\s*animation: none !important;/,
    );
    expect(reduced).toMatch(/\.spinner-arc \{\s*display: none;/);
    expect(reduced).toMatch(/\.spinner-dots \{\s*display: inline;/);
  });

  it("runs on a running tool line and leaves once the tool is done or failed", () => {
    const running = render(<ToolLine item={tool()} agentId="a" />);
    expect(running.container.querySelector(".tool.running .mark .icon.spinner")).not.toBeNull();
    cleanup();
    const done = render(<ToolLine item={tool({ ok: true, output: "ok" })} agentId="a" />);
    expect(done.container.querySelector(".icon.spinner")).toBeNull();
    expect(done.container.querySelector(".tool.done .tool-dot")).not.toBeNull();
    cleanup();
    const failed = render(<ToolLine item={tool({ ok: false, output: "no" })} agentId="a" />);
    expect(failed.container.querySelector(".icon.spinner")).toBeNull();
    expect(failed.container.querySelector(".tool.failed .mark .icon")).not.toBeNull();
  });
});
