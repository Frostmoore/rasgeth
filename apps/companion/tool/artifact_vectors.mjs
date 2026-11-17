// Writes test/fixtures/artifact_vectors.json from the protocol's own rules
// (packages/protocol/src/artifact-bridge.ts, built): what `parseCapability` takes and refuses, the
// canonical words, and `capabilitySentence` in both languages. test/g42_2_artifacts_test.dart checks
// the app's Dart (lib/api/artifacts.dart) against them (G42.2).
//
//   pnpm build && node apps/companion/tool/artifact_vectors.mjs
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const p = await import(
  pathToFileURL(join(here, "../../../packages/protocol/dist/artifact-bridge.js")).href
);

const words = [
  "ask",
  " storage ",
  "files:dati/",
  "files:dati",
  "files:dati//",
  "files:a/b/c/",
  "files:../x/",
  "files:.hidden/",
  "files:a\\b/",
  "files:",
  "files: a/",
  `files:${"x".repeat(201)}`,
  "network",
  "",
];
const out = {
  caps: p.ARTIFACT_ASK_CAPS,
  capDefault: p.ARTIFACT_ASK_CAP_DEFAULT,
  words: words.map((w) => {
    const c = p.parseCapability(w);
    return { w, word: c ? p.capabilityWord(c) : null };
  }),
  sentences: ["ask", "storage", "files:dati/", "network"].flatMap((c) =>
    ["it", "en"].flatMap((lang) =>
      [undefined, "Coder Web"].map((agent) => ({
        lang,
        c,
        ...(agent && { agent }),
        s: p.capabilitySentence(lang, c, agent),
      })),
    ),
  ),
};
writeFileSync(
  join(here, "../test/fixtures/artifact_vectors.json"),
  `${JSON.stringify(out, null, 2)}\n`,
);
console.log(`artifact vectors: ${out.words.length} words, ${out.sentences.length} sentences`);
