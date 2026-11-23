// The drawn map of a route (3.12.2): the route's points projected into a small SVG, no map service
// and no key. Longitudes are narrowed by the cosine of the middle latitude, so a short walk keeps its
// shape; the same projection is in the app (`lib/ui/found_widgets.dart`).
import type { GeoPoint } from "@redgiant/protocol";

export interface MapDrawing {
  width: number;
  height: number;
  /** The SVG path of the route, from the start to the end. */
  path: string;
  start: { x: number; y: number };
  end: { x: number; y: number };
}

/** The points in a `width` x `height` box with `pad` around (north up). Pure. */
export function drawRoute(
  points: readonly GeoPoint[],
  width: number,
  height: number,
  pad = 28,
): MapDrawing {
  const first = points[0] ?? { lat: 0, lon: 0 };
  const last = points[points.length - 1] ?? first;
  const lats = points.map((p) => p.lat);
  const midLat = (Math.min(...lats) + Math.max(...lats)) / 2;
  const k = Math.max(0.05, Math.cos((midLat * Math.PI) / 180));
  const xs = points.map((p) => p.lon * k);
  const ys = points.map((p) => -p.lat);
  const minX = Math.min(...xs);
  const minY = Math.min(...ys);
  const spanX = Math.max(1e-9, Math.max(...xs) - minX);
  const spanY = Math.max(1e-9, Math.max(...ys) - minY);
  const scale = Math.min((width - 2 * pad) / spanX, (height - 2 * pad) / spanY);
  const offX = (width - spanX * scale) / 2;
  const offY = (height - spanY * scale) / 2;
  const at = (p: GeoPoint) => ({
    x: Math.round((offX + (p.lon * k - minX) * scale) * 10) / 10,
    y: Math.round((offY + (-p.lat - minY) * scale) * 10) / 10,
  });
  const path = points.map((p, i) => `${i ? "L" : "M"}${at(p).x} ${at(p).y}`).join(" ");
  return { width, height, path, start: at(first), end: at(last) };
}
