// Search widgets (3.12.2): what `show_results` showed, inside the answer: a gallery of pictures
// (one big, four small, «All» opens them all), trains or flights as rows with «Choose», a route on a
// drawn map with the steps and «Open in Maps». Nothing here runs remote HTML: pictures are plain
// http(s) addresses loaded with no referrer, a broken one shows a neutral placeholder, and the map is
// an SVG drawn from the route's points. «Choose» only tells the agent, which asks the person before
// anything is booked or paid (the question card with its buttons).
import {
  type FoundWidget,
  type GalleryWidget,
  type GeoPoint,
  mapsLink,
  type RouteMode,
  type RouteWidget,
  routeLine,
  type TripOffer,
  type TripsWidget,
} from "@redgiant/protocol";
import { useState } from "preact/hooks";
import { drawRoute } from "../found-map.js";
import { t } from "../i18n.js";
import {
  IconBus,
  IconCar,
  IconChevronLeft,
  IconChevronRight,
  IconExternal,
  IconImage,
  IconMapPin,
  IconPlane,
  IconTrain,
  IconWalk,
} from "../icons.js";
import { sendInChat } from "../state.js";
import { priceText, safeLink } from "./ProductCards.js";
import { Modal } from "./ui.js";

/** One picture: no referrer, lazy, and a neutral placeholder when it cannot be loaded. */
function Picture({ url, alt, class: cls }: { url: string; alt: string; class?: string }) {
  const [bad, setBad] = useState(false);
  const src = safeLink(url);
  if (!src || bad)
    return (
      <div class={`found-pic empty ${cls ?? ""}`} title={t("foundImageBroken")}>
        <IconImage size={26} />
      </div>
    );
  return (
    <img
      class={`found-pic ${cls ?? ""}`}
      src={src}
      alt={alt}
      loading="lazy"
      referrerpolicy="no-referrer"
      onError={() => setBad(true)}
    />
  );
}

function Gallery({ w }: { w: GalleryWidget }) {
  const [all, setAll] = useState(false);
  const [at, setAt] = useState<number | undefined>();
  const shown = w.images.slice(0, 5);
  const more = w.images.length - 5;
  const openAll = () => {
    setAt(undefined);
    setAll(true);
  };
  const open = (i: number) => {
    setAt(i);
    setAll(true);
  };
  const big = at === undefined ? undefined : w.images[at];
  const bigLink = big?.pageUrl ? safeLink(big.pageUrl) : undefined;
  return (
    <>
      <div class="found-head">
        <span class="found-name">
          <IconImage size={14} />
          {w.title ?? t("foundGalleryTitle")}
        </span>
        {w.source && <span class="found-sub">{w.source}</span>}
      </div>
      <div class={`found-gallery n${Math.min(shown.length, 5)}`}>
        {shown.map((im, i) => (
          <button
            key={i}
            type="button"
            class={`found-tile${i === 0 ? " main" : ""}`}
            title={im.title ?? t("foundOpenPicture")}
            aria-label={im.title ?? t("foundOpenPicture")}
            onClick={() => open(i)}
          >
            <Picture url={i === 0 ? im.url : (im.thumbUrl ?? im.url)} alt={im.title ?? ""} />
            {i === 4 && more > 0 && <span class="found-more">+{more}</span>}
          </button>
        ))}
      </div>
      {w.images.length > 1 && (
        <button type="button" class="found-all" onClick={openAll}>
          {t("foundAll")} ({w.images.length})
        </button>
      )}
      {all && (
        <Modal
          title={w.title ?? t("foundAllTitle", { n: String(w.images.length) })}
          wide
          onClose={() => setAll(false)}
        >
          {big && at !== undefined ? (
            <div class="found-lightbox">
              <Picture url={big.url} alt={big.title ?? ""} class="large" />
              <div class="found-lightbar">
                <button
                  type="button"
                  class="found-nav"
                  aria-label={t("foundPrevious")}
                  disabled={at === 0}
                  onClick={() => setAt(at - 1)}
                >
                  <IconChevronLeft size={18} />
                </button>
                <span class="found-cap">
                  {big.title ?? ""}
                  {bigLink && (
                    <a
                      href={bigLink}
                      target="_blank"
                      rel="noopener noreferrer"
                      referrerpolicy="no-referrer"
                    >
                      {t("foundOpenPage")}
                      <IconExternal size={12} />
                    </a>
                  )}
                </span>
                <button
                  type="button"
                  class="found-nav"
                  aria-label={t("foundNext")}
                  disabled={at >= w.images.length - 1}
                  onClick={() => setAt(at + 1)}
                >
                  <IconChevronRight size={18} />
                </button>
              </div>
              <button type="button" class="link" onClick={() => setAt(undefined)}>
                {t("foundAll")}
              </button>
            </div>
          ) : (
            <div class="found-grid">
              {w.images.map((im, i) => (
                <button
                  key={i}
                  type="button"
                  class="found-tile"
                  title={im.title ?? t("foundOpenPicture")}
                  aria-label={im.title ?? t("foundOpenPicture")}
                  onClick={() => setAt(i)}
                >
                  <Picture url={im.thumbUrl ?? im.url} alt={im.title ?? ""} />
                </button>
              ))}
            </div>
          )}
        </Modal>
      )}
    </>
  );
}

/** «Choose»'s message to the agent: the trip's details, and that nothing is booked before asking. */
export function chooseText(w: TripsWidget, o: TripOffer): string {
  const price = o.price === undefined ? "" : `, ${priceText(o.price, o.currency)}`;
  return t("foundChooseText", {
    kind: t(w.mode === "train" ? "foundKind_train" : "foundKind_flight"),
    label: o.label,
    departs: o.departs,
    arrives: o.arrives,
    from: w.from,
    to: w.to,
    date: w.date ? `, ${w.date}` : "",
    price,
  });
}

function Offer({ w, o, onChoose }: { w: TripsWidget; o: TripOffer; onChoose: () => void }) {
  const price = priceText(o.price, o.currency);
  return (
    <li class="found-offer">
      <div class="found-times">
        <strong>{o.departs}</strong>
        <span class="found-arrow" aria-hidden="true" />
        <strong>{o.arrives}</strong>
      </div>
      <div class="found-offer-body">
        <span class="found-label">{o.label}</span>
        <span class="found-sub">
          {[
            o.duration,
            o.stops === 0
              ? t("foundDirect")
              : o.stops === 1
                ? t("foundStop1")
                : t("foundStopN", { n: String(o.stops) }),
            o.operator,
          ]
            .filter(Boolean)
            .join(" · ")}
        </span>
      </div>
      <div class="found-offer-side">
        {price && <strong class="found-price">{price}</strong>}
        {o.availability && <span class="found-sub">{o.availability}</span>}
      </div>
      <button type="button" class="found-choose" data-trip={w.mode} onClick={onChoose}>
        {t("foundChoose")}
      </button>
    </li>
  );
}

function Trips({ w, sessionId }: { w: TripsWidget; sessionId: string | undefined }) {
  const [chosen, setChosen] = useState<number>();
  return (
    <>
      <div class="found-head">
        <span class="found-name">
          {w.mode === "train" ? <IconTrain size={15} /> : <IconPlane size={15} />}
          {w.from} → {w.to}
          {w.date ? ` · ${w.date}` : ""}
        </span>
        {w.operators && <span class="found-sub">{w.operators}</span>}
      </div>
      <ul class="found-offers">
        {w.offers.map((o, i) => (
          <Offer
            key={i}
            w={w}
            o={o}
            onChoose={() => {
              // The agent is told; it asks the person (Yes, book it / No / Change) before booking.
              if (sessionId && sendInChat(sessionId, chooseText(w, o))) setChosen(i);
            }}
          />
        ))}
      </ul>
      {chosen !== undefined && (
        <span class="sr-only" role="status">
          {w.offers[chosen]?.label}
        </span>
      )}
    </>
  );
}

const MODE_ICON: Record<RouteMode, (p: { size?: number }) => preact.JSX.Element> = {
  walk: IconWalk,
  transit: IconBus,
  drive: IconCar,
};

/** Minutes as «22 min» or «1 h 05 min». */
export function minutesText(n: number): string {
  const m = Math.max(0, Math.round(n));
  return m < 60
    ? t("foundMinutes", { n: String(m) })
    : t("foundHours", { h: String(Math.floor(m / 60)), m: String(m % 60).padStart(2, "0") });
}

/** Metres as «1,7 km» or «450 m». */
export function distanceText(m: number, locale: string): string {
  if (m < 1000) return `${Math.round(m)} m`;
  return `${new Intl.NumberFormat(locale, { maximumFractionDigits: 1 }).format(m / 1000)} km`;
}

function RouteMap({ r, line }: { r: RouteWidget; line: readonly GeoPoint[] }) {
  const d = drawRoute(line, 560, 260);
  return (
    <svg
      class="found-map"
      viewBox={`0 0 ${d.width} ${d.height}`}
      role="img"
      aria-label={t("foundMapAlt", { from: r.from.name, to: r.to.name })}
    >
      <defs>
        <pattern id="found-grid" width="28" height="28" patternUnits="userSpaceOnUse">
          <path d="M28 0H0V28" fill="none" class="found-map-grid" />
        </pattern>
      </defs>
      <rect width={d.width} height={d.height} class="found-map-bg" />
      <rect width={d.width} height={d.height} fill="url(#found-grid)" />
      <path d={d.path} class="found-map-casing" />
      <path d={d.path} class="found-map-line" />
      <circle cx={d.start.x} cy={d.start.y} r="7" class="found-map-start" />
      <circle cx={d.end.x} cy={d.end.y} r="8" class="found-map-end" />
      <circle cx={d.end.x} cy={d.end.y} r="3" class="found-map-dot" />
      <text x={d.start.x + 11} y={d.start.y - 9} class="found-map-label">
        {r.from.name}
      </text>
      <text x={d.end.x + 12} y={d.end.y - 10} class="found-map-label">
        {r.to.name}
      </text>
    </svg>
  );
}

function Route({ r }: { r: RouteWidget }) {
  const [at, setAt] = useState(0);
  const o = r.options[Math.min(at, r.options.length - 1)] ?? r.options[0];
  if (!o) return null;
  const locale = document.documentElement.lang === "it" ? "it-IT" : "en-US";
  const link = safeLink(mapsLink(r, o.mode));
  return (
    <>
      <div class="found-head">
        <span class="found-name">
          <IconMapPin size={15} />
          {r.title ?? `${r.from.name} → ${r.to.name}`}
        </span>
      </div>
      <RouteMap r={r} line={routeLine(r, o)} />
      <div class="found-route-head">
        <strong class="found-duration">{minutesText(o.durationMin)}</strong>
        <span class="found-sub">
          {[
            t(`foundModeBy_${o.mode}`),
            o.distanceM !== undefined && distanceText(o.distanceM, locale),
          ]
            .filter(Boolean)
            .join(" · ")}
        </span>
      </div>
      <div class="found-modes">
        {r.options.map((x, i) => {
          const Icon = MODE_ICON[x.mode];
          return (
            <button
              key={x.mode}
              type="button"
              class={`found-mode${i === at ? " on" : ""}`}
              aria-pressed={i === at}
              onClick={() => setAt(i)}
            >
              <Icon size={14} />
              {t(`foundMode_${x.mode}`)}
            </button>
          );
        })}
        {link && (
          <a
            class="found-maps"
            href={link}
            target="_blank"
            rel="noopener noreferrer"
            referrerpolicy="no-referrer"
          >
            {t("foundOpenMaps")}
            <IconExternal size={13} />
          </a>
        )}
      </div>
      {o.steps.length > 0 && (
        <ol class="found-steps" aria-label={t("foundSteps")}>
          {o.steps.map((s, i) => (
            <li key={i}>
              {s.minute !== undefined && (
                <span class="found-step-min">{minutesText(s.minute)}</span>
              )}
              <span>{s.text}</span>
            </li>
          ))}
        </ol>
      )}
      {r.note && <p class="found-note">{r.note}</p>}
    </>
  );
}

/** A search widget in the answer; `sessionId` is the conversation «Choose» writes in. */
export function FoundCard({
  widget,
  sessionId,
}: {
  widget: FoundWidget;
  sessionId?: string | undefined;
}) {
  return (
    <section class={`found found-k-${widget.kind}`} data-found={widget.kind}>
      {widget.kind === "gallery" && <Gallery w={widget} />}
      {widget.kind === "trips" && <Trips w={widget} sessionId={sessionId} />}
      {widget.kind === "route" && <Route r={widget} />}
    </section>
  );
}
