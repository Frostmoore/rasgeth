// @vitest-environment jsdom
import { describe, expect, it } from "vitest";
import { renderAnswer, renderMarkdown, renderStreamingMarkdown } from "../src/markdown.js";

const SOFTMAX = String.raw`P(i)=\frac{e^{z_i}}{\sum_j e^{z_j}}`;

/** The LaTeX sources of the formulas drawn in `html`, with whether each is display math. */
function formulas(html: string): { tex: string; display: boolean }[] {
  const box = document.createElement("div");
  box.innerHTML = html;
  return [...box.querySelectorAll(".katex")].map((k) => ({
    tex: k.querySelector("annotation")?.textContent ?? "",
    display: !!k.closest(".katex-display"),
  }));
}

describe("math in an answer (3.12.4)", () => {
  const table: [string, string, { tex: string; display: boolean }[]][] = [
    ["inline dollars", "so $x^2$ here", [{ tex: "x^2", display: false }]],
    ["inline parentheses", String.raw`so \(x^2\) here`, [{ tex: "x^2", display: false }]],
    ["display dollars", "$$x^2$$", [{ tex: "x^2", display: true }]],
    ["display brackets", String.raw`\[ ${SOFTMAX} \]`, [{ tex: SOFTMAX, display: true }]],
    ["display over lines", `Before\n\n$$\na = b\n$$\n\nAfter`, [{ tex: "a = b", display: true }]],
    ["price pair", "costs $5 and $10 today", []],
    ["price then formula", "from $10 or $x$ only", [{ tex: "x", display: false }]],
    ["space after the opening dollar", "a $ x$ b", []],
    ["space before the closing dollar", "a $x $ b", []],
    ["digit after the closing dollar", "a $x$5 b", []],
    ["escaped dollar", String.raw`a \$x\$ b`, []],
    ["lone dollar", "only $ here", []],
    ["unclosed display", "$$x^2", []],
    ["price then code", "is $10 or `$x$` ok", []],
    ["inline code", "use `$x$` and `\\(y\\)`", []],
    ["fenced code", "```tex\n$$x$$\n\\[y\\]\n```", []],
    [
      "a formula in a list",
      "- one $a$\n- two $b$",
      [
        { tex: "a", display: false },
        { tex: "b", display: false },
      ],
    ],
  ];
  it.each(table)("%s", (_name, md, expected) => {
    expect(formulas(renderMarkdown(md))).toEqual(expected);
  });

  it("keeps the text around a formula and no placeholder or raw delimiters", () => {
    const html = renderMarkdown(String.raw`Softmax: \[ ${SOFTMAX} \] where \(z_i\) is a score`);
    expect(html).not.toMatch(/[]/);
    expect(html).not.toContain("\\[");
    expect(html).toContain("Softmax:");
    expect(html).toContain("is a score");
    expect(html).toContain("katex-mathml");
    expect(html).toContain("katex-html");
  });

  it("price text stays as written", () => {
    const html = renderMarkdown("$5 e $10");
    expect(html).toBe("<p>$5 e $10</p>\n");
  });

  it("code keeps its dollars and backslashes", () => {
    const html = renderMarkdown("`$x$`");
    expect(html).toContain("<code>$x$</code>");
  });

  it("the model's HTML is still stripped, in the text and inside a formula", () => {
    const html = renderMarkdown(
      `<img src=x onerror=alert(1)><script>alert(2)</script> $\\text{<img src=x onerror=alert(3)>}$ $\\href{javascript:alert(4)}{x}$`,
    );
    const box = document.createElement("div");
    box.innerHTML = html;
    expect(box.querySelector("script")).toBeNull();
    expect(box.querySelector("[onerror]")).toBeNull();
    expect(html).not.toMatch(/href="javascript/i);
  });

  it("a mark inside a link address never injects markup", () => {
    const html = renderMarkdown("[a]($x$) and [b](http://e.com/$y$)");
    const box = document.createElement("div");
    box.innerHTML = html;
    for (const el of box.querySelectorAll("*"))
      expect(el.getAttributeNames()).not.toContain("onmouseover");
    expect(html).not.toMatch(/[]/);
  });

  it("a LaTeX error does not break the answer", () => {
    const html = renderMarkdown(String.raw`bad $\frac{1$ and $x$ ok`);
    expect(html).toContain("ok");
    expect(formulas(html).some((f) => f.tex === "x")).toBe(true);
  });

  it("works while streaming and with citations", () => {
    expect(formulas(renderStreamingMarkdown("see $a$ and $$b"))).toEqual([
      { tex: "a", display: false },
    ]);
    const html = renderAnswer("Text [1] and $x[1]$\n\n1. [Site: x](https://example.com/a)");
    expect(formulas(html)).toEqual([{ tex: "x[1]", display: false }]);
  });

  it("copying gives the LaTeX source", async () => {
    await import("katex/contrib/copy-tex");
    const box = document.createElement("div");
    box.innerHTML = renderMarkdown(String.raw`Is \(a+b\) and \[ ${SOFTMAX} \]`);
    document.body.append(box);
    const range = document.createRange();
    range.selectNodeContents(box);
    const selection = window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);
    const data = new Map<string, string>();
    const event = new Event("copy", { cancelable: true, bubbles: true });
    Object.assign(event, { clipboardData: { setData: (k: string, v: string) => data.set(k, v) } });
    document.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(true);
    const plain = data.get("text/plain") ?? "";
    expect(plain).toContain("$a+b$");
    expect(plain).toContain(`$$${SOFTMAX}$$`);
    box.remove();
  });
});
