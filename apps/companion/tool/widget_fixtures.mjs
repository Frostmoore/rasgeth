// Writes test/fixtures/widget_vectors.json: answers split by the page's own `answerSegments`
// (packages/protocol/src/widget.ts) and `splitWidgets` / `streamingWithoutWidgets`
// (packages/web/src/state.ts, copied below as they are there), so test/g387_web_test.dart checks
// that the app splits an answer exactly as the page and the server do (3.8.7). zod is not needed
// for these functions: a stand-in answers its schema calls.
//
//   node --experimental-strip-types apps/companion/tool/widget_fixtures.mjs
import { writeFileSync } from "node:fs";
import { register } from "node:module";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
// `zod` → a chainable stand-in; `./x.js` → `./x.ts` (the sources import with .js).
const zod = `const any=new Proxy(function(){},{get:(_t,k)=>k==="then"?undefined:any,apply:()=>any});export const z=any;`;
register(
  `data:text/javascript,${encodeURIComponent(`
export async function resolve(s,c,n){
  if(s==="zod")return{url:"data:text/javascript,${encodeURIComponent(zod)}",shortCircuit:true};
  if(s.startsWith("./")&&s.endsWith(".js")&&c.parentURL&&c.parentURL.endsWith(".ts"))
    return n(s.slice(0,-3)+".ts",c);
  return n(s,c);
}`)}`,
);
const { answerSegments } = await import(
  pathToFileURL(join(here, "../../../packages/protocol/src/widget.ts")).href
);

// packages/web/src/state.ts, `splitWidgets` and `streamingWithoutWidgets` (t() → the word given).
function splitWidgets(texts) {
  const widgets = [];
  let n = 0;
  const out = texts.map((text0) => {
    if (!/^\s{0,3}(`{3,}|~{3,})\s*widget\b/im.test(text0)) return text0;
    const segs = answerSegments(text0, n);
    n += segs.filter((x) => x.kind === "widget").length;
    return segs
      .map((x) => {
        if (x.kind === "text") return x.text;
        if (x.closed && !x.tooBig) {
          widgets.push({ index: x.index, title: x.title });
          return "";
        }
        return x.closed ? `\`\`\`html\n${x.html}\n\`\`\`` : `\`\`\`html\n${x.html}`;
      })
      .map((x) => x.replace(/^\n+|\n+$/g, ""))
      .filter((x) => x.trim())
      .join("\n\n");
  });
  return { texts: out, widgets };
}
function streamingWithoutWidgets(text, preparing) {
  if (!/(`{3,}|~{3,})\s*widget\b/i.test(text)) return text;
  return answerSegments(text)
    .map((x) => (x.kind === "text" ? x.text : `\n_${preparing}_\n`))
    .join("\n\n");
}

const answers = [
  "Solo testo, niente widget.",
  "```widget Umidità\n<div>60%</div>\n```",
  "Prima\n\n```widget\n<b>1</b>\n```\n\nDopo",
  "x\n~~~widget\n<i>2</i>\n~~~\n```widget C\n<p>never closed",
  "````widget Lungo\n<pre>```</pre>\n````\nfine",
  "   ```WIDGET   Titolo con spazi  \n<p>a</p>\n   ```   ",
  "    ```widget\n<p>rientro di 4: codice</p>\n```",
  "```html\n<p>x</p>\n```",
  "```widgets\n<p>non è widget</p>\n```",
  "```widget\n```",
  "```widget A\n<p>1</p>\n```\n```widget B\n<p>2</p>\n```\n\n\n",
  "testo\r\n```widget CR\r\n<p>r</p>\r\n```\r\ndopo",
  "~~~widget T\n<p>tilde</p>\n```\nancora dentro\n~~~",
  "Ecco:\n```widget Umidità\n<script>let a=1",
  "\n\n```widget\n<p>solo</p>\n```\n\n",
];
const parts = [
  ["```widget A\n<b>1</b>\n```", "x\n~~~widget\n<i>2</i>\n~~~\n```widget C\n<p>never closed"],
  ["nessuno", "```widget Z\n<p>z</p>\n```", "dopo"],
];
const vectors = {
  segments: answers.map((text) => ({ text, first: 0, out: answerSegments(text) })),
  segmentsFrom: [{ text: answers[2], first: 3, out: answerSegments(answers[2], 3) }],
  split: [...answers.map((a) => [a]), ...parts].map((texts) => ({ texts, out: splitWidgets(texts) })),
  streaming: answers.map((text) => ({ text, out: streamingWithoutWidgets(text, "Sto preparando un widget…") })),
};
// The limit (64 KB of UTF-8): one byte over, and exactly at it with two-byte letters.
const big = (c, n) => `\`\`\`widget\n${c.repeat(n)}\n\`\`\``;
vectors.limit = [
  ["a", 64 * 1024 + 1],
  ["a", 64 * 1024],
  ["é", 32 * 1024],
  ["é", 32 * 1024 + 1],
].map(([c, n]) => ({ char: c, times: n, tooBig: answerSegments(big(c, n))[0].tooBig }));
const file = join(here, "../test/fixtures/widget_vectors.json");
writeFileSync(file, `${JSON.stringify(vectors, null, 1)}\n`);
console.log(`wrote ${file}`);
