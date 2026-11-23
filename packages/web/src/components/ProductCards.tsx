// Product cards (G40.16): what show_products showed, as a carousel in the answer. The pictures
// come from RedGiant's server (it downloaded them), never from the shop: the browser calls the
// shop's site only when the person presses «Open», in a new tab without a way back to the page.
import type { ProductCard } from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { lang, t } from "../i18n.js";
import { IconBag, IconChevronLeft, IconChevronRight, IconExternal, IconStar } from "../icons.js";
import { getApi } from "../state.js";

/** A page people may open from a card: http or https only. */
export const safeLink = (url: string): string | undefined => {
  try {
    const u = new URL(url);
    return u.protocol === "https:" || u.protocol === "http:" ? u.toString() : undefined;
  } catch {
    return undefined;
  }
};

/** A price in the page's language: «32,90 €», «$45.00»; the bare number without a currency. */
export function priceText(price: number | undefined, currency: string | undefined): string {
  if (price === undefined) return "";
  const locale = lang.value === "it" ? "it-IT" : "en-US";
  try {
    return currency
      ? new Intl.NumberFormat(locale, { style: "currency", currency }).format(price)
      : new Intl.NumberFormat(locale, {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        }).format(price);
  } catch {
    return `${price.toFixed(2)}${currency ? ` ${currency}` : ""}`;
  }
}

type Load = (id: string) => Promise<Blob>;

function Picture({ image, name, load }: { image?: string; name: string; load: Load }) {
  const [url, setUrl] = useState<string>();
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    if (!image) return;
    let alive = true;
    let made: string | undefined;
    load(image).then(
      (blob) => {
        if (!alive) return;
        made = URL.createObjectURL(blob);
        setUrl(made);
      },
      () => alive && setFailed(true),
    );
    return () => {
      alive = false;
      if (made) URL.revokeObjectURL(made);
    };
  }, [image]);
  if (url && !failed)
    return (
      <div class="product-picture">
        <img src={url} alt={name} loading="lazy" onError={() => setFailed(true)} />
      </div>
    );
  return (
    <div class="product-picture empty" title={t("productNoPicture")}>
      <IconBag size={34} />
    </div>
  );
}

/** Five stars, filled to the rating (0 to 5), with the number and, when known, the reviews. */
export function Stars({ rating, reviews }: { rating: number; reviews?: number | undefined }) {
  const row = (
    <>
      {[0, 1, 2, 3, 4].map((i) => (
        <IconStar key={i} size={13} />
      ))}
    </>
  );
  return (
    <span class="stars" title={t("foundRating", { n: rating.toFixed(1) })}>
      <span class="stars-row" aria-hidden="true">
        <span class="stars-off">{row}</span>
        <span
          class="stars-on"
          style={{ width: `${(Math.min(5, Math.max(0, rating)) / 5) * 100}%` }}
        >
          {row}
        </span>
      </span>
      <span class="stars-n">{rating.toFixed(1)}</span>
      {reviews !== undefined && <span class="stars-reviews">({reviews})</span>}
    </span>
  );
}

function Card({ p, load }: { p: ProductCard; load: Load }) {
  const link = safeLink(p.url);
  const price = priceText(p.price, p.currency);
  return (
    <article class="product-card">
      <Picture image={p.image} name={p.name} load={load} />
      <div class="product-body">
        <strong class="product-name" title={p.name}>
          {p.name}
        </strong>
        {p.rating !== undefined && <Stars rating={p.rating} reviews={p.reviews} />}
        {price && <span class="product-price">{price}</span>}
        {p.shop && <span class="product-shop">{p.shop}</span>}
        {p.description && <p class="product-desc">{p.description}</p>}
        <div class="product-foot">
          {p.source !== undefined && (
            <span class="product-source" title={t("productSource", { n: String(p.source) })}>
              {p.source}
            </span>
          )}
          <div class="spacer" />
          {link && (
            <a
              class="product-open"
              href={link}
              target="_blank"
              rel="noopener noreferrer"
              referrerpolicy="no-referrer"
            >
              {t("productOpen")}
              <IconExternal size={13} />
            </a>
          )}
        </div>
      </div>
    </article>
  );
}

/** The carousel: cards side by side, scrolled by hand (a phone) or with the arrows (a computer). */
export function ProductCards({
  title,
  products,
  load = (id) => getApi().productImage(id),
}: {
  title?: string | undefined;
  products: ProductCard[];
  load?: Load;
}) {
  const row = useRef<HTMLDivElement>(null);
  const [ends, setEnds] = useState({ start: true, end: products.length <= 1 });
  const measure = () => {
    const el = row.current;
    if (!el) return;
    setEnds({
      start: el.scrollLeft <= 2,
      end: el.scrollLeft + el.clientWidth >= el.scrollWidth - 2,
    });
  };
  useEffect(measure, [products.length]);
  const move = (dir: 1 | -1) => {
    const el = row.current;
    if (!el) return;
    el.scrollBy({ left: dir * Math.max(200, el.clientWidth * 0.8), behavior: "smooth" });
  };
  return (
    <section class="products" aria-label={title ?? t("productsTitle")}>
      {title && <div class="products-title">{title}</div>}
      <div class="products-frame">
        {!ends.start && (
          <button
            type="button"
            class="products-arrow prev"
            aria-label={t("productsPrev")}
            onClick={() => move(-1)}
          >
            <IconChevronLeft size={18} />
          </button>
        )}
        <div class="products-row" ref={row} onScroll={measure}>
          {products.map((p, i) => (
            <Card key={`${i}-${p.url}`} p={p} load={load} />
          ))}
        </div>
        {!ends.end && (
          <button
            type="button"
            class="products-arrow next"
            aria-label={t("productsNext")}
            onClick={() => move(1)}
          >
            <IconChevronRight size={18} />
          </button>
        )}
      </div>
    </section>
  );
}
