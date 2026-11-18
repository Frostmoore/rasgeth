// The product's name as a person sees it (plan 3.9.0, N1): one place, so that the page, the
// server's texts and prompts, the channels and the command line take it from here. The inside
// keeps its technical prefix (`@redgiant/*`, `REDGIANT_*`, `rg.*`, `redgiant-*` services):
// only what a person sees carries the name. scripts/name-audit.mjs guards the old names.

/** The product's name, everywhere a person reads it. */
export const PRODUCT_NAME = "Rasgeth";

/** The app alone on a computer (Windows, the Mac, Linux), where it may sit next to the whole
 * installation: two entries with the same name would confuse (plan 3.9.0, choice 4). On the
 * phones the app is just {@link PRODUCT_NAME}. */
export const DESKTOP_APP_NAME = `${PRODUCT_NAME} App`;

/** The name before 3.9.0, only to recognise what older versions wrote (their built-in
 * instructions, their backup folders): never shown. */
export const FORMER_PRODUCT_NAME = "RedGiant";
