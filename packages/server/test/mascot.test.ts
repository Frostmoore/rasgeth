// The agents' mascots over HTTP (G40.2): every agent carries its spec (the app paints it), the
// spec and an SVG file have their own address, and «Change mascot» is the person's.
import { MascotSpec } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { OTHER, startServer, TOKEN } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  const server = s;
  s = undefined;
  await server?.close();
}, 60_000);

interface AgentOut {
  id: string;
  name: string;
  mascotSeed?: string;
  mascot?: MascotSpec;
}

describe("mascots", () => {
  it("sends the spec with every agent and at its own address, as SVG too", async () => {
    s = await startServer();
    await s.api("POST", "/api/projects", { name: "Shop" });
    const god = (
      await s.api<AgentOut>("POST", "/api/agents", { kind: "god", parentId: null, name: "God" })
    ).body;
    const orch = (
      await s.api<AgentOut>("POST", "/api/agents", {
        kind: "orchestrator",
        parentId: god.id,
        projectId: "shop",
        name: "Coder Web",
      })
    ).body;
    expect(orch.mascotSeed).toBe("Coder Web");
    expect(MascotSpec.parse(orch.mascot).parts.holds).toBe("headset");
    const listed = (await s.api<AgentOut[]>("GET", "/api/agents")).body;
    expect(listed.find((a) => a.id === orch.id)?.mascot).toEqual(orch.mascot);

    const spec = await s.api<MascotSpec>("GET", `/api/agents/${orch.id}/mascot`);
    expect(spec.status).toBe(200);
    expect(spec.body).toEqual(orch.mascot);

    const svg = await fetch(
      `${s.url}/api/agents/${orch.id}/mascot?format=svg&state=wait&theme=dark&size=64`,
      {
        headers: { authorization: `Bearer ${TOKEN}` },
      },
    );
    expect(svg.headers.get("content-type")).toMatch(/image\/svg\+xml/);
    const text = await svg.text();
    expect(text).toMatch(/^<svg xmlns="http:\/\/www.w3.org\/2000\/svg" class="masc st-wait"/);
    expect(text).toContain(`fill="${orch.mascot?.colors.dark.body}"`);
    expect(text).not.toContain("var(");

    const bad = await s.api("GET", `/api/agents/${orch.id}/mascot?format=svg&state=dancing`);
    expect(bad.status).toBe(400);
    expect((await s.api("GET", `/api/agents/${orch.id}/mascot`, undefined, OTHER)).status).toBe(
      404,
    );
  });

  it("keeps the face through a rename and changes it only on «Change mascot»", async () => {
    s = await startServer();
    await s.api("POST", "/api/projects", { name: "Shop" });
    const god = (
      await s.api<AgentOut>("POST", "/api/agents", { kind: "god", parentId: null, name: "God" })
    ).body;
    const orch = (
      await s.api<AgentOut>("POST", "/api/agents", {
        kind: "orchestrator",
        parentId: god.id,
        projectId: "shop",
        name: "Coder Web",
      })
    ).body;
    const renamed = await s.api<AgentOut>("PATCH", `/api/agents/${orch.id}`, { name: "Front-end" });
    expect(renamed.body.name).toBe("Front-end");
    expect(renamed.body.mascot).toEqual(orch.mascot);

    const changed = await s.api<AgentOut>("POST", `/api/agents/${orch.id}/mascot`);
    expect(changed.status).toBe(200);
    expect(changed.body.mascotSeed).not.toBe("Coder Web");
    expect(changed.body.mascot).not.toEqual(orch.mascot);
    expect((await s.api("POST", `/api/agents/${god.id}/mascot`)).status).toBe(400);
  });
});
