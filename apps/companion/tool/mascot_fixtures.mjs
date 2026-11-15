// Writes test/fixtures/mascots.json: specs and SVGs made by @redgiant/mascot (the library the
// server uses), so the app's tests draw exactly what the server sends.
//
//   pnpm build && node apps/companion/tool/mascot_fixtures.mjs [path/to/mascot/dist/index.js]
import { writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const lib = resolve(process.argv[2] ?? join(here, "../../../packages/mascot/dist/index.js"));
const { mascotSpec, mascotSvg, MASCOT_STATES } = await import(pathToFileURL(lib).href);

const parent = mascotSpec("Coder Web", "agent");
const cases = [
  ["God", "god"],
  ["Demi", "demigod"],
  ["Capo cantiere", "orchestrator"],
  ["Coder Web", "agent"],
  ["Ricercatore", "agent"],
  ["Assistente mail", "assistant"],
  ["Revisore", "inspector"],
  ["Tester", "subagent", parent],
];

const out = cases.map(([seed, kind, p]) => {
  const spec = mascotSpec(seed, kind, p);
  const svg = {};
  for (const theme of ["light", "dark"]) {
    svg[theme] = {};
    for (const state of MASCOT_STATES)
      svg[theme][state] = mascotSvg(spec, { state, theme, size: 128, idPrefix: "m" });
  }
  const tiny = mascotSvg(spec, { state: "idle", theme: "light", size: 20, idPrefix: "m" });
  return { seed, kind, spec, svg, tiny };
});

const file = join(here, "../test/fixtures/mascots.json");
writeFileSync(file, `${JSON.stringify(out, null, 1)}\n`);
console.log(`${out.length} mascots -> ${file}`);
