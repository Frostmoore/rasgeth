// Search widgets (3.12.2): what `show_results` shows inside an answer, in a conversation of the
// Chat, God or any agent: a gallery of pictures, trains or flights, a route on a drawn map. (Product
// cards are `products.ts`.) The agent fills them with what it found on the web; the log keeps the
// data, so they come back on reload. Pictures are plain http(s) addresses the page loads with no
// referrer; nothing here is HTML, and a map is drawn from the route's points (no map service, no key).
// Paying or booking is never a widget's action: «Choose» only tells the agent, which asks the person
// (ask_user) before anything is paid.
import { z } from "zod";
import { WebLink } from "./products.js";

export const MAX_GALLERY_IMAGES = 24;
export const MAX_TRIP_OFFERS = 12;
export const MAX_ROUTE_POINTS = 400;
export const MAX_ROUTE_STEPS = 30;

const Text = (n: number) => z.string().trim().min(1).max(n);

/** One picture of a gallery. */
export const GalleryImage = z.object({
  /** The picture itself (shown in the widget). */
  url: WebLink,
  /** A smaller copy, when the site gives one (the grid prefers it). */
  thumbUrl: WebLink.optional(),
  title: z.string().trim().max(160).optional(),
  /** The page it comes from (opened by a press on its caption). */
  pageUrl: WebLink.optional(),
});
export type GalleryImage = z.infer<typeof GalleryImage>;

export const GalleryWidget = z.object({
  kind: z.literal("gallery"),
  title: z.string().trim().max(120).optional(),
  /** Where the pictures come from, in words («Wikimedia Commons»). */
  source: z.string().trim().max(80).optional(),
  images: z.array(GalleryImage).min(1).max(MAX_GALLERY_IMAGES),
});
export type GalleryWidget = z.infer<typeof GalleryWidget>;

/** One train or flight. Times are as the timetable writes them (local, «06:20»). */
export const TripOffer = z.object({
  departs: Text(40),
  arrives: Text(40),
  /** «2 h 55». */
  duration: z.string().trim().max(30).optional(),
  /** 0 is direct. */
  stops: z.number().int().min(0).max(9).default(0),
  /** The service: «Frecciarossa 9505», «LH 1234». */
  label: Text(80),
  operator: z.string().trim().max(60).optional(),
  price: z.number().nonnegative().optional(),
  currency: z
    .string()
    .regex(/^[A-Z]{3}$/)
    .optional(),
  /** «posti liberi», «ultimi 4 posti»: as the source says it. */
  availability: z.string().trim().max(60).optional(),
  /** The page to see or buy it (opened only when the person asks). */
  url: WebLink.optional(),
});
export type TripOffer = z.infer<typeof TripOffer>;

export const TripsWidget = z.object({
  kind: z.literal("trips"),
  title: z.string().trim().max(120).optional(),
  mode: z.enum(["train", "flight"]),
  from: Text(80),
  to: Text(80),
  /** «ven 27 nov». */
  date: z.string().trim().max(40).optional(),
  /** «Trenitalia e Italo». */
  operators: z.string().trim().max(80).optional(),
  offers: z.array(TripOffer).min(1).max(MAX_TRIP_OFFERS),
});
export type TripsWidget = z.infer<typeof TripsWidget>;

export const GeoPoint = z.object({
  lat: z.number().min(-90).max(90),
  lon: z.number().min(-180).max(180),
});
export type GeoPoint = z.infer<typeof GeoPoint>;

export const RouteMode = z.enum(["walk", "transit", "drive"]);
export type RouteMode = z.infer<typeof RouteMode>;

export const RouteStep = z.object({
  text: Text(200),
  /** Minutes from the start. */
  minute: z.number().min(0).max(2000).optional(),
});
export type RouteStep = z.infer<typeof RouteStep>;

/** One way to go: its duration, distance and steps; its own line on the map, or the shared one. */
export const RouteOption = z.object({
  mode: RouteMode,
  durationMin: z.number().min(0).max(100000),
  distanceM: z.number().min(0).max(40000000).optional(),
  steps: z.array(RouteStep).max(MAX_ROUTE_STEPS).default([]),
  points: z.array(GeoPoint).min(2).max(MAX_ROUTE_POINTS).optional(),
});
export type RouteOption = z.infer<typeof RouteOption>;

export const RouteWidget = z.object({
  kind: z.literal("route"),
  title: z.string().trim().max(120).optional(),
  from: GeoPoint.extend({ name: Text(100) }),
  to: GeoPoint.extend({ name: Text(100) }),
  /** The line drawn when an option has none of its own. */
  points: z.array(GeoPoint).min(2).max(MAX_ROUTE_POINTS).optional(),
  /** The ways to go; the first is shown first. */
  options: z.array(RouteOption).min(1).max(3),
  /** One line under the steps («Con la metro B sono 2 fermate»). */
  note: z.string().trim().max(300).optional(),
});
export type RouteWidget = z.infer<typeof RouteWidget>;

/** What `found.shown` carries. */
export const FoundWidget = z.discriminatedUnion("kind", [GalleryWidget, TripsWidget, RouteWidget]);
export type FoundWidget = z.infer<typeof FoundWidget>;

/** The page to open the route in the system's maps (an app where there is one, else the site). */
export function mapsLink(r: Pick<RouteWidget, "from" | "to">, mode: RouteMode): string {
  const m = { walk: "walking", transit: "transit", drive: "driving" }[mode];
  const q = (p: GeoPoint) => `${p.lat.toFixed(6)},${p.lon.toFixed(6)}`;
  return `https://www.google.com/maps/dir/?api=1&origin=${q(r.from)}&destination=${q(r.to)}&travelmode=${m}`;
}

/** The line a mode shows: its own points, else the shared ones, else a straight line. */
export function routeLine(r: RouteWidget, o: RouteOption): GeoPoint[] {
  return o.points ?? r.points ?? [r.from, r.to];
}
