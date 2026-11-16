// The person's saved passages (G40.14, 3.8.1), for the page and the app:
//   GET    /api/saved?q=&tag=&agentId=&before=&limit=   SavedList, newest first
//   POST   /api/saved           SavedCreateBody          201 SavedItem (404: not the person's message)
//   GET    /api/saved/export?q=&tag=&agentId=&lang=     text/markdown, every match (up to 2000)
//   GET    /api/saved/:id                                 SavedItem
//   PATCH  /api/saved/:id       SavedUpdateBody          SavedItem (note and tags)
//   DELETE /api/saved/:id                                 { ok: true }
// Every route is bound to the signed-in owner: another person's items answer 404.

import {
  SavedCreateBody,
  type SavedItem,
  SavedQuery,
  SavedUpdateBody,
  savedMarkdown,
} from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import type { RedGiantCore } from "./core.js";
import { SavedError } from "./saved.js";

const EXPORT_MAX = 2000;

// biome-ignore lint/suspicious/noExplicitAny: the app's own Env, kept private in app.ts
export function savedRoutes<E extends { Variables: any }>(
  app: Hono<E>,
  core: RedGiantCore,
  owner: (c: Context<E>) => string,
): void {
  const query = (c: Context<E>) => SavedQuery.safeParse(c.req.query());
  const notFound = (c: Context<E>) => c.json({ error: "Saved item not found" }, 404);

  app.get("/api/saved", async (c) => {
    const q = query(c);
    if (!q.success) return c.json({ error: q.error.issues[0]?.message ?? "Bad query" }, 400);
    return c.json(await core.saved.list(owner(c), q.data), 200);
  });
  app.post("/api/saved", async (c) => {
    const b = SavedCreateBody.safeParse(await c.req.json().catch(() => null));
    if (!b.success) return c.json({ error: b.error.issues[0]?.message ?? "Bad body" }, 400);
    try {
      return c.json(await core.saved.create(owner(c), b.data), 201);
    } catch (err) {
      if (err instanceof SavedError) return c.json({ error: err.message }, err.status);
      throw err;
    }
  });
  app.get("/api/saved/export", async (c) => {
    const q = query(c);
    if (!q.success) return c.json({ error: q.error.issues[0]?.message ?? "Bad query" }, 400);
    const lang = c.req.query("lang") === "it" ? "it" : "en";
    const items: SavedItem[] = [];
    let before = q.data.before;
    // Page by page, up to EXPORT_MAX items.
    while (items.length < EXPORT_MAX) {
      const page = await core.saved.list(owner(c), {
        ...q.data,
        ...(before && { before }),
        limit: 200,
      });
      items.push(...page.items);
      before = page.items.at(-1)?.createdAt;
      if (!page.more || !before) break;
    }
    return c.body(savedMarkdown(items.slice(0, EXPORT_MAX), lang), 200, {
      "content-type": "text/markdown; charset=utf-8",
      "content-disposition": `attachment; filename="${lang === "it" ? "salvati" : "saved"}.md"`,
    });
  });
  app.get("/api/saved/:id", async (c) => {
    const item = await core.saved.get(owner(c), c.req.param("id"));
    return item ? c.json(item, 200) : notFound(c);
  });
  app.patch("/api/saved/:id", async (c) => {
    const b = SavedUpdateBody.safeParse(await c.req.json().catch(() => null));
    if (!b.success) return c.json({ error: b.error.issues[0]?.message ?? "Bad body" }, 400);
    const item = await core.saved.update(owner(c), c.req.param("id"), b.data);
    return item ? c.json(item, 200) : notFound(c);
  });
  app.delete("/api/saved/:id", async (c) => {
    const ok = await core.saved.remove(owner(c), c.req.param("id"));
    return ok ? c.json({ ok: true }, 200) : notFound(c);
  });
}
