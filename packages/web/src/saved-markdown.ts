// The Markdown of a selected part of a message (G40.14): the rendered HTML the selection covers,
// back to Markdown near enough to keep headings, emphasis, code, links, lists, quotes and tables.
// The whole message's Markdown the server reads from the log; this is only for a part of it.

const SKIP = new Set(["BUTTON", "SVG", "SCRIPT", "STYLE", "TEMPLATE", "TEXTAREA", "INPUT"]);
const BLOCK = new Set(["P", "DIV", "SECTION", "ARTICLE", "HEADER", "FOOTER", "FIGURE"]);

const squeeze = (s: string) => s.replace(/[ \t]*\n[ \t]*/g, " ");

function inline(node: Node): string {
  let out = "";
  for (const n of Array.from(node.childNodes)) out += render(n, 0);
  return out;
}

function list(el: Element, depth: number): string {
  const ordered = el.tagName === "OL";
  let i = Number(el.getAttribute("start") ?? 1) || 1;
  const lines: string[] = [];
  for (const li of Array.from(el.children)) {
    if (li.tagName !== "LI") continue;
    const mark = ordered ? `${i++}.` : "-";
    const body = Array.from(li.childNodes)
      .map((n) =>
        n instanceof Element && (n.tagName === "UL" || n.tagName === "OL")
          ? `\n${list(n, depth + 1)}`
          : render(n, depth + 1),
      )
      .join("")
      .trim();
    lines.push(`${"  ".repeat(depth)}${mark} ${body}`);
  }
  return lines.join("\n");
}

function table(el: Element): string {
  const rows = Array.from(el.querySelectorAll("tr")).map((tr) =>
    Array.from(tr.children).map((c) => squeeze(inline(c)).replace(/\|/g, "\\|").trim()),
  );
  if (rows.length === 0) return "";
  const width = Math.max(...rows.map((r) => r.length));
  const line = (r: string[]) =>
    `| ${Array.from({ length: width }, (_, i) => r[i] ?? "").join(" | ")} |`;
  const [head, ...rest] = rows;
  return [line(head ?? []), `|${" --- |".repeat(width)}`, ...rest.map(line)].join("\n");
}

function render(n: Node, depth: number): string {
  if (n.nodeType === 3) return (n as Text).data;
  if (!(n instanceof Element)) return "";
  const tag = n.tagName.toUpperCase();
  if (SKIP.has(tag) || n.getAttribute("aria-hidden") === "true") return "";
  switch (tag) {
    case "BR":
      return "\n";
    case "STRONG":
    case "B": {
      const s = inline(n);
      return s.trim() ? `**${s}**` : s;
    }
    case "EM":
    case "I": {
      const s = inline(n);
      return s.trim() ? `_${s}_` : s;
    }
    case "DEL":
    case "S":
      return `~~${inline(n)}~~`;
    case "CODE":
      return n.parentElement?.tagName === "PRE" ? (n.textContent ?? "") : `\`${n.textContent}\``;
    case "PRE": {
      const code = n.querySelector("code");
      const lang = code?.className.match(/language-([\w+-]+)/)?.[1] ?? "";
      return `\n\n\`\`\`${lang}\n${(n.textContent ?? "").replace(/\n$/, "")}\n\`\`\`\n\n`;
    }
    case "A": {
      const href = n.getAttribute("href") ?? "";
      const s = inline(n);
      return /^https?:\/\//.test(href) && s.trim() && s !== href ? `[${s}](${href})` : s;
    }
    case "H1":
    case "H2":
    case "H3":
    case "H4":
    case "H5":
    case "H6":
      return `\n\n${"#".repeat(Number(tag[1]))} ${squeeze(inline(n)).trim()}\n\n`;
    case "UL":
    case "OL":
      return `\n\n${list(n, depth)}\n\n`;
    case "LI":
      // A list item without its list (the selection started inside it).
      return `\n- ${inline(n).trim()}\n`;
    case "BLOCKQUOTE":
      return `\n\n${fragmentMarkdown(n)
        .split("\n")
        .map((l) => `> ${l}`.trimEnd())
        .join("\n")}\n\n`;
    case "TABLE":
      return `\n\n${table(n)}\n\n`;
    case "HR":
      return "\n\n---\n\n";
    default:
      return BLOCK.has(tag) ? `\n\n${inline(n)}\n\n` : inline(n);
  }
}

/** A DOM fragment (a selection's contents, an element) as Markdown. */
export function fragmentMarkdown(root: Node): string {
  return inline(root)
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/**
 * The Markdown of a selection inside a message. A selection wholly inside a code block or a
 * heading keeps its fence or its hashes, which the cloned contents alone would lose.
 */
export function selectionMarkdown(range: Range): string {
  const md = fragmentMarkdown(range.cloneContents());
  const at = range.commonAncestorContainer;
  const el = at instanceof Element ? at : at.parentElement;
  const pre = el?.closest("pre");
  if (pre) {
    const lang = pre.querySelector("code")?.className.match(/language-([\w+-]+)/)?.[1] ?? "";
    return `\`\`\`${lang}\n${range.toString().replace(/\n$/, "")}\n\`\`\``;
  }
  // Inside bold, italics, inline code or a link: the selection keeps them.
  let out = md;
  for (let up: Element | null | undefined = el; up && INLINE.has(up.tagName); up = up.parentElement)
    out = wrapInline(up, out);
  const head = el?.closest("h1, h2, h3, h4, h5, h6");
  if (head) return `${"#".repeat(Number(head.tagName[1]))} ${out}`;
  return out;
}

const INLINE = new Set(["STRONG", "B", "EM", "I", "CODE", "A", "DEL", "S", "SPAN"]);

function wrapInline(el: Element, md: string): string {
  if (!md.trim()) return md;
  switch (el.tagName) {
    case "STRONG":
    case "B":
      return `**${md}**`;
    case "EM":
    case "I":
      return `_${md}_`;
    case "DEL":
    case "S":
      return `~~${md}~~`;
    case "CODE":
      return `\`${md}\``;
    case "A": {
      const href = el.getAttribute("href") ?? "";
      return /^https?:\/\//.test(href) ? `[${md}](${href})` : md;
    }
    default:
      return md;
  }
}
