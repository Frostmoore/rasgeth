// Product cards (G40.16): what `show_products` shows in an answer, a carousel of cards with a
// picture, a name, a price, a shop, a link and the number of the web source it comes from. The
// pictures are downloaded and kept by the server; the log keeps the product's data and the
// reference to its cached picture, never the picture itself.
import { z } from "zod";

/** At most this many cards in one carousel. */
export const MAX_PRODUCTS = 10;

/** A page people may open: http or https only (never javascript:, data: or a file). */
export const WebLink = z
  .string()
  .max(2048)
  .refine((u) => {
    try {
      const p = new URL(u).protocol;
      return p === "https:" || p === "http:";
    } catch {
      return false;
    }
  }, "an http or https address");

/** A cached product picture: the SHA-256 of its address, served by `GET /api/products/images/:id`. */
export const ProductImageId = z.string().regex(/^[0-9a-f]{64}$/);

/** One card, as the log keeps it and the page and the app draw it. */
export const ProductCard = z.object({
  name: z.string().min(1).max(200),
  price: z.number().nonnegative().optional(),
  /** ISO 4217, upper case (EUR, USD…). */
  currency: z
    .string()
    .regex(/^[A-Z]{3}$/)
    .optional(),
  shop: z.string().max(80).optional(),
  /** The product's page: opened only when the person presses «Open». */
  url: WebLink,
  /** One line about it. */
  description: z.string().max(300).optional(),
  /** The number of the web source it comes from, as the answer cites it ([1], [2]…). */
  source: z.number().int().min(1).max(99).optional(),
  /** The picture's address as the agent gave it (the cache's key). */
  imageUrl: WebLink.optional(),
  /** The picture in the server's cache; absent when it could not be downloaded (a drawn placeholder). */
  image: ProductImageId.optional(),
});
export type ProductCard = z.infer<typeof ProductCard>;

/** The `products.shown` event's payload. */
export const ProductsShownPayload = z.object({
  title: z.string().max(120).optional(),
  products: z.array(ProductCard).min(1).max(MAX_PRODUCTS),
});
export type ProductsShownPayload = z.infer<typeof ProductsShownPayload>;

/** The picture types the server keeps, recognised from their first bytes (never SVG: it runs code). */
export const PRODUCT_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/avif",
] as const;
export type ProductImageType = (typeof PRODUCT_IMAGE_TYPES)[number];
