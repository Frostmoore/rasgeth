// Lets node read the page's TypeScript sources the way its bundler does (G42.17): an import of
// "./x.js" finds "./x.ts". Used by the vector tools with --import ./apps/companion/tool/ts_loader.mjs.
import { existsSync } from "node:fs";
import { register } from "node:module";
import { fileURLToPath } from "node:url";

if (!process.env.TS_LOADER_HOOK) {
  register(import.meta.url, { data: {} });
}

export async function resolve(specifier, context, next) {
  if (specifier.endsWith(".js") && context.parentURL?.includes("/packages/") && specifier.startsWith(".")) {
    const ts = new URL(specifier.replace(/\.js$/, ".ts"), context.parentURL);
    if (existsSync(fileURLToPath(ts))) return next(ts.href, context);
  }
  return next(specifier, context);
}
