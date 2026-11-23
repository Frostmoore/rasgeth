// God's conversations by topic (3.12), for the page and the apps («Oggi»):
//   GET  /api/god/topics[?archived=true&q=]        → TopicList (active, pinned first; or the archive)
//   POST /api/god/messages                         → 202 GodMessageResponse (routed, then sent)
//   POST /api/sessions/:id/messages/:seq/move      → MoveResponse («Move»: God answers again there)
//   POST /api/god/topics/:id/archive | /restore | /read → { ok: true } (404: not a topic of God)
//   GET  /api/god/topics/settings                  → { model, defaultModel } (the routing model)
//   PUT  /api/god/topics/settings { model | null } → { ok: true }
//   GET  /api/god/nudges → NudgeSettings; PUT /api/god/nudges NudgeSettings → { ok: true } (3.12.1)
// Shapes in `@redgiant/protocol` (`topics.ts`). The old apps' `POST /api/agents/:id/work-session`
// gives God's latest active topic.

import {
  GodMessageRequest,
  ModelSpec,
  MoveRequest,
  NudgeSettings,
  TopicListQuery,
} from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import { z } from "zod";
import type { RedGiantCore } from "./core.js";
import { TopicError } from "./topics.js";

// biome-ignore lint/suspicious/noExplicitAny: the app's own Env, kept private in app.ts
export function topicRoutes<E extends { Variables: any }>(
  app: Hono<E>,
  core: RedGiantCore,
  owner: (c: Context<E>) => string,
): void {
  const failed = (c: Context<E>, err: unknown) => {
    if (err instanceof TopicError) return c.json({ error: err.message }, err.status);
    const name = (err as Error)?.name ?? "";
    if (name === "NotFoundError") return c.json({ error: (err as Error).message }, 404);
    if (/Archived|Inactive|UpdateRequired|Busy/.test(name))
      return c.json({ error: (err as Error).message }, 409);
    throw err;
  };

  // God's friendly nudges (3.12.1): on or off and how often (Settings, and the simple interface).
  app.get("/api/god/nudges", async (c) => c.json(await core.nudges.settings(owner(c)), 200));
  app.put("/api/god/nudges", async (c) => {
    const b = NudgeSettings.safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    await core.nudges.setSettings(owner(c), b.data);
    return c.json({ ok: true }, 200);
  });

  app.get("/api/god/topics", async (c) => {
    const q = TopicListQuery.safeParse(c.req.query());
    if (!q.success) return c.json({ error: q.error.message }, 400);
    return c.json(
      await core.topics.list(owner(c), {
        archived: q.data.archived,
        ...(q.data.q && { q: q.data.q }),
      }),
      200,
    );
  });

  app.post("/api/god/messages", async (c) => {
    const b = GodMessageRequest.safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    try {
      const { sessionId, routed, queued } = await core.topics.send(owner(c), b.data, {
        watch: true,
      });
      return c.json({ sessionId, routed, ...(queued && { queued: true }) }, 202);
    } catch (err) {
      return failed(c, err);
    }
  });

  app.post("/api/sessions/:id/messages/:seq/move", async (c) => {
    const seq = Number(c.req.param("seq"));
    if (!Number.isInteger(seq) || seq < 0) return c.json({ error: "A message's seq" }, 400);
    const b = MoveRequest.safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    try {
      const { done: _done, ...r } = await core.topics.move(
        owner(c),
        c.req.param("id"),
        seq,
        b.data,
      );
      return c.json(r, 200);
    } catch (err) {
      return failed(c, err);
    }
  });

  const act = (what: "archive" | "restore" | "read") => async (c: Context<E>) => {
    const o = owner(c);
    const id = c.req.param("id") ?? "";
    await core.topics.prepare(o);
    if (!core.topics.isTopic(id)) return c.json({ error: "Not one of God's topics" }, 404);
    if (what === "archive") await core.topics.archive(o, id, "person");
    else if (what === "restore") await core.topics.restore(o, id, "person");
    else await core.topics.read(o, id);
    return c.json({ ok: true as const }, 200);
  };
  app.post("/api/god/topics/:id/archive", act("archive"));
  app.post("/api/god/topics/:id/restore", act("restore"));
  app.post("/api/god/topics/:id/read", act("read"));

  app.get("/api/god/topics/settings", async (c) => {
    const o = owner(c);
    const [kept] = await core.db.query<{ value: unknown }>(
      "SELECT value FROM rg_settings WHERE owner_id = $1 AND key = 'topics_model'",
      [o],
    );
    const v = kept?.value;
    const model = ModelSpec.safeParse(typeof v === "string" ? JSON.parse(v) : v);
    return c.json(
      { model: model.success ? model.data : null, defaultModel: core.memoryModel ?? null },
      200,
    );
  });
  app.put("/api/god/topics/settings", async (c) => {
    const b = z
      .object({ model: ModelSpec.nullable() })
      .safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    await core.topics.setRoutingModel(owner(c), b.data.model);
    return c.json({ ok: true as const }, 200);
  });
}
