// Skills that improve with use (3.9.7), through the server: which version an agent sees (the one
// installed when its conversation started), the history through the API and the way back.

import type { CompletionRequest } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const toolResult = (req: CompletionRequest) => {
  const last = req.messages.at(-1);
  const p = last?.role === "user" ? last.parts.find((x) => x.type === "tool_result") : undefined;
  return p?.type === "tool_result" ? p.content : undefined;
};

const skill = (body: string) => ({
  projectId: null,
  input: {
    kind: "skill",
    name: "invoice-pdf",
    description: "Read a supplier's invoice PDF and pull out total, VAT and due date",
    body,
    untestableReason: "Instructions only, nothing to run here.",
    summary: "Written by the person.",
  },
});

describe("skill versions through the server (3.9.7)", () => {
  it("an agent keeps the version its conversation started with; the next one gets the newest", async () => {
    const loaded: string[] = [];
    s = await startServer((req) => {
      const r = toolResult(req);
      if (r === undefined)
        return { toolCalls: [{ name: "skill_load", input: { name: "invoice-pdf" } }] };
      loaded.push(r);
      return { text: "ok" };
    });
    const god = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const v1 = await s.api<{ status: string }>(
      "POST",
      "/api/extensions/proposals",
      skill("Version one: the total is on the last page."),
    );
    expect(v1.body.status).toBe("installed");
    const a = await s.core.startSession("me", god.body.id);
    await (await s.core.send("me", a, "read the invoice")).done;
    expect(loaded.at(-1)).toMatch(/^Version one/);
    // A new version while the conversation runs: it keeps the one it started with.
    await s.api("POST", "/api/extensions/proposals", skill("Version two: VAT above the total."));
    await (await s.core.send("me", a, "and the next one")).done;
    expect(loaded.at(-1)).toMatch(/^Version one/);
    const b = await s.core.startSession("me", god.body.id);
    await (await s.core.send("me", b, "read the invoice")).done;
    expect(loaded.at(-1)).toMatch(/^Version two/);

    // The history, newest first, with who and why.
    const list = await s.api<{ version: number; how: string; author: string; current: boolean }[]>(
      "GET",
      "/api/extensions/skills/invoice-pdf/versions?scope=platform",
    );
    expect(list.body.map((v) => [v.version, v.how, v.author, v.current])).toEqual([
      [2, "update", "human", true],
      [1, "install", "human", false],
    ]);
    const one = await s.api<{ skillMd: string }>(
      "GET",
      "/api/extensions/skills/invoice-pdf/versions/1?scope=platform",
    );
    expect(one.body.skillMd).toMatch(/Version one/);

    // «Go back to version 1»: a new version, and the next conversation gets it.
    const back = await s.api<{ version: number }>(
      "POST",
      "/api/extensions/skills/invoice-pdf/rollback?scope=platform",
      { version: 1 },
    );
    expect(back).toMatchObject({ status: 200, body: { version: 3, fromVersion: 1 } });
    const c = await s.core.startSession("me", god.body.id);
    await (await s.core.send("me", c, "read the invoice")).done;
    expect(loaded.at(-1)).toMatch(/^Version one/);
    const after = await s.api<{ how: string; fromVersion: number | null }[]>(
      "GET",
      "/api/extensions/skills/invoice-pdf/versions",
    );
    expect(after.body[0]).toMatchObject({ how: "rollback", fromVersion: 1 });

    // Wrong requests say why.
    expect(
      (await s.api("POST", "/api/extensions/skills/invoice-pdf/rollback", { version: 9 })).status,
    ).toBe(400);
    expect(
      (await s.api("POST", "/api/extensions/skills/Bad_Name/rollback", { version: 1 })).status,
    ).toBe(400);
    expect(
      (await s.api("GET", "/api/extensions/skills/invoice-pdf/versions?scope=project:nope")).status,
    ).toBe(404);
    expect((await s.api("GET", "/api/extensions/skills/invoice-pdf/versions/7")).status).toBe(404);
  });
});
