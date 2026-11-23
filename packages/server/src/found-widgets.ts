// show_results (3.12.2): an agent shows what it found on the web as a widget inside its answer: a
// gallery of pictures, trains or flights, or a route on a drawn map. The data goes in the log
// (`found.shown`), so it comes back on reload; the model reads only a summary in words. Nothing is
// downloaded here: the page loads the pictures itself, with no referrer. Paying or booking is
// never done by a widget: the person is asked first (ask_user).

import type { Tool } from "@redgiant/agent";
import type { AgentRecord } from "@redgiant/hierarchy";
import {
  FoundWidget,
  MAX_GALLERY_IMAGES,
  MAX_ROUTE_POINTS,
  MAX_ROUTE_STEPS,
  MAX_TRIP_OFFERS,
} from "@redgiant/protocol";
import type { z } from "zod";

/** When to use it: joined to the instructions of every agent that has the tool. */
export const FOUND_GUIDANCE = `## Pictures, trains, flights and routes
After searching the web, show what you found as a widget with show_results (it appears inside your answer), then add only what helps (your pick and why), never the same list again in words:
- kind "gallery": pictures of a place, a thing or a person (up to ${MAX_GALLERY_IMAGES}; the first is shown big). Use the picture and page addresses you read on the web, never invented ones.
- kind "trips": trains or flights (up to ${MAX_TRIP_OFFERS}): times, duration, stops, the operator, the price and the availability from the sources.
- kind "route": a way to go from a place to another, with the coordinates of the start and the end, a line of points when you have it (up to ${MAX_ROUTE_POINTS}), and for each way (walk, transit, drive) the minutes, the metres and up to ${MAX_ROUTE_STEPS} steps.
For things to buy use show_products. Pressing «Choose» on a train or flight sends you its details as the person's message: you never pay or book by yourself. Before any payment or booking, ask with ask_user and the options "Yes, book it", "No" and "Change", naming what, when, how many people and the price, and book only on the first.`;

const Input = FoundWidget;

const summary = (w: FoundWidget): string => {
  switch (w.kind) {
    case "gallery":
      return `a gallery of ${w.images.length} picture${w.images.length === 1 ? "" : "s"}${w.title ? ` under "${w.title}"` : ""}`;
    case "trips":
      return `${w.offers.length} ${w.mode === "train" ? "train" : "flight"} option${w.offers.length === 1 ? "" : "s"} ${w.from} to ${w.to}:\n${w.offers
        .map(
          (o, n) =>
            `${n + 1}. ${o.label} ${o.departs}-${o.arrives}${o.price !== undefined ? `, ${o.price.toFixed(2)}${o.currency ? ` ${o.currency}` : ""}` : ""}`,
        )
        .join("\n")}`;
    case "route":
      return `a route from ${w.from.name} to ${w.to.name} (${w.options.map((o) => `${o.mode} ${Math.round(o.durationMin)} min`).join(", ")})`;
  }
};

export interface FoundToolHost {
  /** Writes the event in the conversation's log. */
  shown(sessionId: string, payload: FoundWidget): Promise<void>;
}

const NUM = { type: "number" } as const;
const STR = { type: "string" } as const;
const POINT = {
  type: "object",
  properties: { lat: NUM, lon: NUM },
  required: ["lat", "lon"],
} as const;
const POINTS = { type: "array", maxItems: MAX_ROUTE_POINTS, items: POINT } as const;

export function showResultsTool(_agent: AgentRecord, host: FoundToolHost): Tool {
  return {
    def: {
      name: "show_results",
      description:
        "Show the person what you found on the web as a widget inside your answer: a gallery of pictures (kind gallery), trains or flights (kind trips) or a route on a map (kind route). Use the real data you read; they see the widget, you get a summary. For products to buy use show_products.",
      inputSchema: {
        type: "object",
        properties: {
          kind: { type: "string", enum: ["gallery", "trips", "route"] },
          title: { type: "string", description: "A short title" },
          source: { type: "string", description: "gallery: where the pictures come from" },
          images: {
            type: "array",
            description: "gallery: the pictures, the best first",
            maxItems: MAX_GALLERY_IMAGES,
            items: {
              type: "object",
              properties: {
                url: { type: "string", description: "The picture (http or https)" },
                thumbUrl: { type: "string", description: "A smaller copy, if the site gives one" },
                title: STR,
                pageUrl: { type: "string", description: "The page it comes from" },
              },
              required: ["url"],
            },
          },
          mode: { type: "string", enum: ["train", "flight"], description: "trips" },
          from: {
            description: "trips: the departure place (text). route: {name, lat, lon} of the start",
            anyOf: [STR, { type: "object", properties: { name: STR, lat: NUM, lon: NUM } }],
          },
          to: {
            description: "trips: the arrival place (text). route: {name, lat, lon} of the end",
            anyOf: [STR, { type: "object", properties: { name: STR, lat: NUM, lon: NUM } }],
          },
          date: { type: "string", description: "trips: «ven 27 nov»" },
          operators: { type: "string", description: "trips: «Trenitalia e Italo»" },
          offers: {
            type: "array",
            description: "trips: the options, the most convenient first",
            maxItems: MAX_TRIP_OFFERS,
            items: {
              type: "object",
              properties: {
                departs: { type: "string", description: "«06:20»" },
                arrives: STR,
                duration: { type: "string", description: "«2 h 55»" },
                stops: { type: "number", description: "0 is direct" },
                label: { type: "string", description: "«Frecciarossa 9505»" },
                operator: STR,
                price: NUM,
                currency: { type: "string", description: "ISO code" },
                availability: STR,
                url: { type: "string", description: "Where to see or buy it" },
              },
              required: ["departs", "arrives", "label"],
            },
          },
          points: { ...POINTS, description: "route: the line to draw, from the start to the end" },
          options: {
            type: "array",
            description: "route: the ways to go (walk, transit, drive), the first is shown first",
            maxItems: 3,
            items: {
              type: "object",
              properties: {
                mode: { type: "string", enum: ["walk", "transit", "drive"] },
                durationMin: NUM,
                distanceM: NUM,
                steps: {
                  type: "array",
                  maxItems: MAX_ROUTE_STEPS,
                  items: {
                    type: "object",
                    properties: { text: STR, minute: NUM },
                    required: ["text"],
                  },
                },
                points: POINTS,
              },
              required: ["mode", "durationMin"],
            },
          },
          note: { type: "string", description: "route: one line under the steps" },
        },
        required: ["kind"],
      },
    },
    schema: Input,
    run: async (i: z.infer<typeof Input>, ctx) => {
      await host.shown(ctx.sessionId, i);
      return `Shown to the person inside your answer: ${summary(i)}.\nThey see the widget: do not list it again, add only what helps choose.${i.kind === "trips" ? " If they choose one, ask before booking (ask_user)." : ""}`;
    },
  } as Tool;
}
