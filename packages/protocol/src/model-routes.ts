/**
 * How a model is reached (G40.9b, the person: «se ho sia abbonamento che api key di un fornitore,
 * quando scelgo i modelli mi deve far scegliere tra abbonamento e api key»). The server keeps the
 * ways apart as providers (`claude-subscription` and `anthropic`, `chatgpt-subscription` and
 * `openai`, a node's `node-<name>`); the menus show one entry per model family (same company,
 * same model) with the ways it can go: the subscription, the API key, a node, a local engine.
 * One pure rule, read by the page, the app (mirrored in Dart) and the request sentences.
 */

type Lang = "it" | "en";
const lng = (lang: string): Lang => (lang === "it" ? "it" : "en");

export type ModelRouteKind = "subscription" | "key" | "node" | "local" | "other";

export interface ModelRoute {
  kind: ModelRouteKind;
  /** The company behind the model (`anthropic`, `openai`…), or the provider when unknown. */
  vendor: string;
  /** The model's id at that company (without a node's `<provider>:` prefix). */
  model: string;
  /** For `node`: the node's name. */
  node?: string;
  /** For `node`: how the node itself reaches the model, when it says. */
  through?: "subscription" | "key";
}

/** The subscriptions and the company they belong to. */
const SUBSCRIPTION_VENDOR: Readonly<Record<string, string>> = {
  "claude-subscription": "anthropic",
  "chatgpt-subscription": "openai",
};

/** Providers that run on a computer of the person's (llama.cpp, their own server). */
const LOCAL = new Set(["local", "server"]);

/** Companies people pay with an API key (`KEY_PROVIDERS`; kept here so the rule stays pure). */
const KEYS = new Set([
  "anthropic",
  "openai",
  "gemini",
  "mistral",
  "deepseek",
  "xai",
  "groq",
  "openrouter",
  "together",
  "fireworks",
  "cerebras",
]);

const viaName = (name: string | undefined) => name?.match(/\(via ([^)]+)\)\s*$/)?.[1]?.trim();

/** How `provider` reaches `model`; `name` is the menu's name (a node's says «(via Rig)»). */
export function modelRoute(provider: string, model: string, name?: string): ModelRoute {
  const sub = SUBSCRIPTION_VENDOR[provider];
  if (sub) return { kind: "subscription", vendor: sub, model };
  if (provider.startsWith("node-")) {
    const i = model.indexOf(":");
    const inner = i > 0 ? model.slice(0, i) : "";
    const id = i > 0 ? model.slice(i + 1) : model;
    const r = modelRoute(inner, id);
    return {
      kind: "node",
      vendor: inner ? r.vendor : provider,
      model: id,
      node: viaName(name) ?? provider.slice(5),
      ...(r.kind === "subscription" && { through: "subscription" as const }),
      ...(r.kind === "key" && { through: "key" as const }),
    };
  }
  if (LOCAL.has(provider)) return { kind: "local", vendor: provider, model };
  if (KEYS.has(provider)) return { kind: "key", vendor: provider, model };
  return { kind: "other", vendor: provider, model };
}

const ORDER: readonly ModelRouteKind[] = ["subscription", "key", "node", "local", "other"];

/** One model with every way it can go, the cheapest-to-think-about first. */
export interface ModelFamily<T> {
  /** `<vendor>/<model>`: the same for every way. */
  id: string;
  vendor: string;
  model: string;
  /** The menus' name without a node's «(via …)». */
  name?: string;
  routes: { route: ModelRoute; choice: T }[];
}

/** The models in families, in the order they first appear; each family's ways in `ORDER`. */
export function modelFamilies<T extends { provider: string; model: string; name?: string }>(
  choices: readonly T[],
): ModelFamily<T>[] {
  const out: ModelFamily<T>[] = [];
  const byId = new Map<string, ModelFamily<T>>();
  for (const choice of choices) {
    const route = modelRoute(choice.provider, choice.model, choice.name);
    const id = `${route.vendor}/${route.model}`;
    let f = byId.get(id);
    if (!f) {
      const name = choice.name?.replace(/\s*\(via [^)]+\)\s*$/, "") || undefined;
      f = { id, vendor: route.vendor, model: route.model, ...(name && { name }), routes: [] };
      byId.set(id, f);
      out.push(f);
    } else if (!f.name && choice.name && route.kind !== "node") f.name = choice.name;
    f.routes.push({ route, choice });
  }
  for (const f of out)
    f.routes.sort((a, b) => ORDER.indexOf(a.route.kind) - ORDER.indexOf(b.route.kind));
  return out;
}

/** The family and the way a chosen model belongs to; undefined when it is not among them. */
export function familyOf<T extends { provider: string; model: string; name?: string }>(
  families: readonly ModelFamily<T>[],
  m: { provider: string; model: string },
): { family: ModelFamily<T>; index: number } | undefined {
  for (const family of families) {
    const index = family.routes.findIndex(
      (r) => r.choice.provider === m.provider && r.choice.model === m.model,
    );
    if (index >= 0) return { family, index };
  }
  return undefined;
}

/** A way's name, short: «Abbonamento», «Chiave API», «Tramite Rig», «Locale». */
export function routeLabel(route: ModelRoute, lang: string, provider?: string): string {
  const it = lng(lang) === "it";
  switch (route.kind) {
    case "subscription":
      return it ? "Abbonamento" : "Subscription";
    case "key":
      return it ? "Chiave API" : "API key";
    case "node":
      return it ? `Tramite ${route.node}` : `Via ${route.node}`;
    case "local":
      return it ? "Locale" : "Local";
    default:
      return provider ?? route.vendor;
  }
}

/** What a way means for the person, in one line. */
export function routeHint(route: ModelRoute, lang: string): string {
  const it = lng(lang) === "it";
  switch (route.kind) {
    case "subscription":
      return it
        ? "Nei limiti del tuo piano: non paghi a consumo."
        : "Within your plan's limits: nothing is paid per use.";
    case "key":
      return it
        ? "A consumo con la tua chiave API: conta per il tetto di spesa."
        : "Paid per use with your API key: it counts toward the spending cap.";
    case "node":
      return it
        ? `Passa dal computer ${route.node}${route.through === "subscription" ? ", con il suo abbonamento" : route.through === "key" ? ", con la sua chiave API" : ""}.`
        : `Goes through the computer ${route.node}${route.through === "subscription" ? ", with its subscription" : route.through === "key" ? ", with its API key" : ""}.`;
    case "local":
      return it
        ? "Gira su un computer tuo: niente costi a consumo."
        : "Runs on a computer of yours: nothing is paid per use.";
    default:
      return it ? "Tramite un fornitore collegato." : "Through a connected provider.";
  }
}

/** The way in a sentence's tail: « con l'abbonamento», « con la chiave API», « tramite Rig». */
export function routePhrase(provider: string, model: string, lang: string): string {
  const it = lng(lang) === "it";
  const r = modelRoute(provider, model);
  switch (r.kind) {
    case "subscription":
      return it ? " con l'abbonamento" : " with the subscription";
    case "key":
      return it ? " con la chiave API" : " with the API key";
    case "node":
      return it ? ` tramite ${r.node}` : ` via ${r.node}`;
    case "local":
      return it ? " in locale" : " locally";
    default:
      return "";
  }
}

/**
 * The model menus by provider and by how one pays (2026-11-20, the person: «quando scelgo i
 * modelli vorrei che siano proprio chiaramente divisi per fornitore e chiave api/abbonamento […]
 * e i modelli più nuovi devono stare in cima»). Every way a model goes is its own entry, under a
 * clear heading: Anthropic's subscription, Anthropic's API key, OpenAI's…, each computer of the
 * person's (a node), then this computer and the person's own server. Inside a group the newest
 * model comes first (the release day of the models catalog); a model the catalog does not date
 * keeps the provider's order after the dated ones.
 */
export interface ModelGroup<T> {
  /** Stable: the provider, or `<provider>|<vendor>` for a node. */
  id: string;
  kind: ModelRouteKind;
  /** The company behind the models (`anthropic`…), or the provider when there is none. */
  vendor: string;
  /** Which key or subscription, which node, which local engine: the provider's id. */
  provider: string;
  /** For `node`: the node's name. */
  node?: string;
  choices: T[];
}

/** The companies in the menus' order; the others follow by name. */
const VENDORS = [
  "anthropic",
  "openai",
  "gemini",
  "xai",
  "deepseek",
  "mistral",
  "groq",
  "cerebras",
  "together",
  "fireworks",
  "openrouter",
];
const GROUP_ORDER: readonly ModelRouteKind[] = ["subscription", "key", "other", "node", "local"];

const vendorRank = (v: string) => {
  const i = VENDORS.indexOf(v);
  return i < 0 ? VENDORS.length : i;
};

/** The models in groups by provider and way, the newest first in each. */
export function modelGroups<
  T extends { provider: string; model: string; name?: string; released?: string },
>(choices: readonly T[]): ModelGroup<T>[] {
  const groups: ModelGroup<T>[] = [];
  const byId = new Map<string, ModelGroup<T>>();
  for (const choice of choices) {
    const r = modelRoute(choice.provider, choice.model, choice.name);
    const id = r.kind === "node" ? `${choice.provider}|${r.vendor}` : choice.provider;
    let g = byId.get(id);
    if (!g) {
      g = {
        id,
        kind: r.kind,
        vendor: r.vendor,
        provider: choice.provider,
        ...(r.node && { node: r.node }),
        choices: [],
      };
      byId.set(id, g);
      groups.push(g);
    }
    g.choices.push(choice);
  }
  // Nodes and local engines after the companies; companies in their order, subscription first.
  const place = (g: ModelGroup<T>) => {
    const outer = g.kind === "node" ? 1 : g.kind === "local" ? 2 : 0;
    return [
      outer,
      outer === 1 ? 0 : vendorRank(g.vendor),
      GROUP_ORDER.indexOf(g.kind),
      g.kind === "local" && g.provider === "local" ? 0 : 1,
    ];
  };
  const cmp = (a: ModelGroup<T>, b: ModelGroup<T>) => {
    const pa = place(a);
    const pb = place(b);
    for (let i = 0; i < pa.length; i++) if (pa[i] !== pb[i]) return (pa[i] ?? 0) - (pb[i] ?? 0);
    if (a.kind === "node" && b.kind === "node") {
      const n = (a.node ?? "").localeCompare(b.node ?? "");
      if (n !== 0) return n;
      return vendorRank(a.vendor) - vendorRank(b.vendor) || a.vendor.localeCompare(b.vendor);
    }
    return a.vendor.localeCompare(b.vendor);
  };
  groups.sort(cmp);
  for (const g of groups) {
    const dated = g.choices.map((c, i) => ({ c, i }));
    dated.sort((a, b) => {
      const ra = a.c.released;
      const rb = b.c.released;
      if (ra && rb && ra !== rb) return ra < rb ? 1 : -1;
      if (ra && !rb) return -1;
      if (!ra && rb) return 1;
      return a.i - b.i;
    });
    g.choices = dated.map((x) => x.c);
  }
  return groups;
}

/** A company's name in the menus' headings. */
const VENDOR_NAMES: Readonly<Record<string, string>> = {
  anthropic: "Anthropic",
  openai: "OpenAI",
  gemini: "Google",
  xai: "xAI",
  deepseek: "DeepSeek",
  mistral: "Mistral",
  groq: "Groq",
  cerebras: "Cerebras",
  together: "Together AI",
  fireworks: "Fireworks AI",
  openrouter: "OpenRouter",
};

/** A group's heading: «Anthropic · Abbonamento Claude», «OpenAI · Chiave API», «Tramite Rig · Anthropic». */
export function groupTitle(
  g: Pick<ModelGroup<unknown>, "kind" | "vendor" | "provider" | "node">,
  lang: string,
): string {
  const it = lng(lang) === "it";
  const vendor = VENDOR_NAMES[g.vendor] ?? g.vendor;
  switch (g.kind) {
    case "subscription": {
      const plan =
        g.provider === "claude-subscription"
          ? "Claude"
          : g.provider === "chatgpt-subscription"
            ? "ChatGPT"
            : "";
      if (it) return `${vendor} · Abbonamento${plan ? ` ${plan}` : ""}`;
      return `${vendor} · ${plan ? `${plan} subscription` : "Subscription"}`;
    }
    case "key":
      return `${vendor} · ${it ? "Chiave API" : "API key"}`;
    case "node": {
      const own = g.vendor === "local" || g.vendor === "server";
      return `${it ? "Tramite" : "Via"} ${g.node} · ${own ? (it ? "Locale" : "Local") : vendor}`;
    }
    case "local":
      return g.provider === "local"
        ? it
          ? "Su questo computer"
          : "On this computer"
        : it
          ? "Il tuo server"
          : "Your own server";
    default:
      return vendor;
  }
}

/** Whether a model answers a search in the menus: its name, its id or its group's heading. */
export function modelMatches(
  m: { provider: string; model: string; name?: string },
  heading: string,
  query: string,
): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  return [m.name ?? "", m.model, heading].some((s) => s.toLowerCase().includes(q));
}
