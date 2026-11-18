// show_products (G40.16): an agent shows things to buy or compare as a carousel of cards. The
// server downloads each picture (product-images.ts) before the event is written, so the log keeps
// the cards' data and their pictures' references; the model reads only a summary in words.

import type { Tool } from "@redgiant/agent";
import type { AgentRecord } from "@redgiant/hierarchy";
import {
  MAX_PRODUCTS,
  PRODUCT_NAME,
  type ProductCard,
  type ProductsShownPayload,
  WebLink,
} from "@redgiant/protocol";
import { z } from "zod";
import type { ProductImages } from "./product-images.js";

const Product = z.object({
  name: z.string().trim().min(1).max(200),
  price: z.number().nonnegative().optional(),
  currency: z
    .string()
    .trim()
    .regex(/^[A-Za-z]{3}$/, "a three-letter code such as EUR or USD")
    .transform((c) => c.toUpperCase())
    .optional(),
  shop: z.string().trim().max(80).optional(),
  url: WebLink,
  image_url: WebLink.optional(),
  description: z.string().trim().max(300).optional(),
  source: z.number().int().min(1).max(99).optional(),
});

const Input = z.object({
  title: z.string().trim().max(120).optional(),
  products: z.array(Product).min(1).max(MAX_PRODUCTS),
});

/** When to use it: joined to the instructions of every agent that has the tool. */
export const PRODUCTS_GUIDANCE = `## Products to buy or compare
When the person wants to buy something or compare things that are for sale, search the web, then call show_products with the best options (up to ${MAX_PRODUCTS}): name, price and currency, shop, the product's page, its picture's address and one line each, with the number of the web source you cite for it. They appear as cards with pictures in your answer; then add only what helps choose (the differences, your pick and why), never the same list again in words. Not for things that are not for sale.`;

export interface ProductsToolHost {
  images: ProductImages;
  /** Writes the event in the conversation's log. */
  shown(sessionId: string, payload: ProductsShownPayload): Promise<void>;
}

const priceText = (p: { price?: number | undefined; currency?: string | undefined }) =>
  p.price === undefined
    ? "price not given"
    : `${p.price.toFixed(2)}${p.currency ? ` ${p.currency}` : ""}`;

/** Up to `n` downloads at a time, in the given order. */
async function pool<T, R>(items: T[], n: number, run: (x: T) => Promise<R>): Promise<R[]> {
  const out = new Array<R>(items.length);
  let next = 0;
  await Promise.all(
    Array.from({ length: Math.min(n, items.length) }, async () => {
      while (next < items.length) {
        const i = next++;
        out[i] = await run(items[i] as T);
      }
    }),
  );
  return out;
}

export function showProductsTool(_agent: AgentRecord, host: ProductsToolHost): Tool {
  return {
    def: {
      name: "show_products",
      description: `Show the person products to buy or compare as a carousel of cards in your answer: a picture, the name, the price, the shop, a link to the product's page and the number of the web source it comes from (as you cite it, [1], [2]…). Up to ${MAX_PRODUCTS}. ${PRODUCT_NAME} downloads the pictures itself; you do not see them, only a summary.`,
      inputSchema: {
        type: "object",
        properties: {
          title: { type: "string", description: "A short title over the cards" },
          products: {
            type: "array",
            maxItems: MAX_PRODUCTS,
            items: {
              type: "object",
              properties: {
                name: { type: "string" },
                price: { type: "number", description: "The price, a number (129.9)" },
                currency: { type: "string", description: "ISO code: EUR, USD, GBP…" },
                shop: { type: "string", description: "Who sells it" },
                url: { type: "string", description: "The product's page (http or https)" },
                image_url: {
                  type: "string",
                  description: "The address of its picture (http or https), from the page",
                },
                description: { type: "string", description: "One line about it" },
                source: {
                  type: "number",
                  description: "The number of the web source you cite for it in your answer",
                },
              },
              required: ["name", "url"],
            },
          },
        },
        required: ["products"],
      },
    },
    schema: Input,
    run: async (i: z.infer<typeof Input>, ctx) => {
      const pictures = await pool(i.products, 4, (p) =>
        p.image_url ? host.images.fetch(p.image_url) : Promise.resolve(undefined),
      );
      const products: ProductCard[] = i.products.map((p, n) => {
        const pic = pictures[n];
        return {
          name: p.name,
          ...(p.price !== undefined && { price: p.price }),
          ...(p.currency && { currency: p.currency }),
          ...(p.shop && { shop: p.shop }),
          url: p.url,
          ...(p.description && { description: p.description }),
          ...(p.source !== undefined && { source: p.source }),
          ...(p.image_url && { imageUrl: p.image_url }),
          ...(pic && "id" in pic && { image: pic.id }),
        };
      });
      await host.shown(ctx.sessionId, { ...(i.title && { title: i.title }), products });
      const lines = products.map((p, n) => {
        const pic = pictures[n];
        const picture = !p.imageUrl
          ? "no picture given"
          : pic && "error" in pic
            ? `picture not shown: ${pic.error}`
            : "with its picture";
        return `${n + 1}. ${p.name}: ${priceText(p)}${p.shop ? `, ${p.shop}` : ""}${p.source ? ` [${p.source}]` : ""} (${picture})`;
      });
      return `Shown to the person as ${products.length} product card${products.length === 1 ? "" : "s"}${i.title ? ` under "${i.title}"` : ""}:\n${lines.join("\n")}\nThey see the cards in your answer: do not list them again, add only what helps choose.`;
    },
  } as Tool;
}
