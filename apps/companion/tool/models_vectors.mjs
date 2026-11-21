// Writes test/fixtures/models_vectors.json: @redgiant/protocol's KEY_PROVIDERS (the API keys one
// can connect, with where to make one) and what its `estimatedSpeed` says for a table of models
// and computers, so test/g42_15_models_test.dart checks that the app's copies
// (lib/settings/models/key_providers.dart, local_speed.dart) say the very same (G42.15).
//
//   pnpm exec tsc -b packages/protocol && node apps/companion/tool/models_vectors.mjs
import { writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const lib = resolve(process.argv[2] ?? join(here, "../../../packages/protocol/dist/index.js"));
const { KEY_PROVIDERS, estimatedSpeed } = await import(pathToFileURL(lib).href);

const models = [
  { totalB: 8, activeB: 8 },
  { totalB: 30, activeB: 3 },
  { totalB: 120, activeB: 5 },
  { totalB: 70, activeB: 70 },
  { totalB: 106, activeB: 12 },
];
const computers = [
  { kind: "gpu", vramGb: 16, ramGb: 64 },
  { kind: "gpu", vramGb: 8, ramGb: 16 },
  { kind: "gpu", vramGb: 24 },
  { kind: "igpu", vramGb: 0, ramGb: 32 },
  { kind: "cpu", vramGb: 0, ramGb: 8 },
  { kind: "gpu-unknown", vramGb: 0, ramGb: 27 },
];
const sizes = [0.05, 5, 18.5, 39.7, 58, 120];
const speeds = [];
for (const m of models)
  for (const hw of computers)
    for (const fileGb of sizes) speeds.push({ m, hw, fileGb, out: estimatedSpeed(m, fileGb, hw) });

const out = join(here, "../test/fixtures/models_vectors.json");
writeFileSync(
  out,
  `${JSON.stringify(
    {
      keyProviders: KEY_PROVIDERS.map((p) => ({
        id: p.id,
        name: p.name,
        keyExample: p.keyExample,
        keyUrl: p.keyUrl,
      })),
      speeds,
    },
    null,
    1,
  )}\n`,
);
console.log(`wrote ${KEY_PROVIDERS.length} providers, ${speeds.length} speeds`);
