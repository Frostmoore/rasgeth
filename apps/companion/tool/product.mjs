// The product's name for the words the tools copy from the page and the protocol (plan 3.9.0,
// N1/N2): the page writes `{product}` where the name goes and its `t()` fills it with
// `PRODUCT_NAME` (packages/protocol/src/brand.ts); the app's copies are filled here, when they are
// written, so an ARB never gets a `{product}` placeholder and the Dart maps say the name itself.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const brand = readFileSync(join(here, "../../../packages/protocol/src/brand.ts"), "utf8");
const name = brand.match(/export const PRODUCT_NAME = "([^"]+)";/)?.[1];
if (!name) throw new Error("packages/protocol/src/brand.ts: no PRODUCT_NAME");

/** The product's name, as the protocol says it. */
export const PRODUCT_NAME = name;

/** A page's or the protocol's text with `{product}` filled, as the page's `fill()` does. */
export const fillProduct = (s) => (typeof s === "string" ? s.replaceAll("{product}", name) : s);
