import type { ToolContext } from "@redgiant/agent";
import { describe, expect, it } from "vitest";
import { frictionOf, SKILL_PROMPT, SkillNudge } from "../src/skill-nudge.js";
import { startServer } from "./helpers.js";

const ctx: ToolContext = { ownerId: "me", projectId: null, agentId: "a", sessionId: "s1" };
const call = (name: string, input: unknown = {}) => ({ callId: "c", name, input });
const ok = (content = "done") => ({ content, isError: false });
const bad = { content: "Error: exit 1", isError: true };

describe("the nudge to propose a skill (G36.8)", () => {
  it("adds one line after a success that followed several failures, once per conversation", async () => {
    const n = new SkillNudge();
    const hook = n.hook();
    for (let i = 0; i < 3; i++) expect(await hook(call("bash"), bad, ctx)).toBeUndefined();
    const r = await hook(call("bash"), ok("tests pass"), ctx);
    expect(r?.content).toMatch(/^tests pass\n\n\[Rasgeth\] That worked after 3 failed attempts\./);
    expect(r?.content).toMatch(/propose_extension/);
    // Never twice in the same conversation, even after another struggle.
    n.turnStarted("s1");
    for (let i = 0; i < 4; i++) await hook(call("bash"), bad, ctx);
    expect(await hook(call("bash"), ok(), ctx)).toBeUndefined();
  });

  it("says nothing for routine work, or once the agent proposed", async () => {
    const n = new SkillNudge();
    const hook = n.hook();
    const c2 = { ...ctx, sessionId: "s2" };
    await hook(call("bash"), bad, c2);
    expect(await hook(call("bash"), ok(), c2)).toBeUndefined();
    // Failures of an earlier turn do not count.
    await hook(call("bash"), bad, c2);
    n.turnStarted("s2");
    await hook(call("bash"), bad, c2);
    expect(await hook(call("read_file"), ok(), c2)).toBeUndefined();
    const c3 = { ...ctx, sessionId: "s3" };
    await hook(call("propose_extension"), ok(), c3);
    for (let i = 0; i < 3; i++) await hook(call("bash"), bad, c3);
    expect(await hook(call("bash"), ok(), c3)).toBeUndefined();
    // Asking the person never counts as effort.
    const c4 = { ...ctx, sessionId: "s4" };
    for (let i = 0; i < 3; i++) await hook(call("ask_user"), bad, c4);
    expect(await hook(call("bash"), ok(), c4)).toBeUndefined();
  });

  it("after a verified task that took many steps, points to the skill it used", async () => {
    const hook = new SkillNudge().hook();
    const c = { ...ctx, sessionId: "t1" };
    await hook(call("skill_load", { name: "deploy-docs" }), ok(), c);
    for (let i = 0; i < 8; i++) await hook(call("edit_file"), ok(), c);
    const r = await hook(
      call("complete_task"),
      ok("Verified: `pnpm test` exited 0. Task task_1 is closed."),
      c,
    );
    expect(r?.content).toMatch(/The task is verified\./);
    expect(r?.content).toMatch(/You used the skill "deploy-docs"/);
    // A task closed as not testable is no reason.
    const c2 = { ...ctx, sessionId: "t2" };
    for (let i = 0; i < 9; i++) await hook(call("edit_file"), ok(), c2);
    expect(
      await hook(call("complete_task"), ok("Task task_2 closed as not testable."), c2),
    ).toBeUndefined();
  });

  it("is in the instructions of agents that can propose, not of Demi-God", async () => {
    const s = await startServer(() => ({ text: "ok" }));
    try {
      const god = await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
      });
      const demi = await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "demigod",
        parentId: god.body.id,
        name: "Demi",
      });
      const systemOf = async (agentId: string) => {
        const { sessionId } = (
          await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId })
        ).body;
        const started = (await s.core.store.list({ sessionId })).find(
          (e) => e.type === "session.started",
        );
        return started?.type === "session.started" ? (started.payload?.system ?? "") : "";
      };
      expect(await systemOf(god.body.id)).toContain(SKILL_PROMPT);
      expect(await systemOf(demi.body.id)).not.toContain("Skills from solved problems");
    } finally {
      await s.close();
    }
  });
});

describe("friction after a skill asks for a new version of it (3.9.7)", () => {
  // The table first: what the person's words say about the work done with a skill.
  const table: [string, ReturnType<typeof frictionOf>][] = [
    ["No, non è così: il totale è nella tabella sopra", "correction"],
    ["no, the VAT is the other one", "correction"],
    ["Hai sbagliato tabella", "correction"],
    ["Guarda che la scadenza è un'altra", "correction"],
    ["That's not what I asked", "correction"],
    ["Actually, use the second page", "correction"],
    ["Questa abilità si può migliorare", "skill"],
    ["la skill è incompleta, manca il passo della firma", "skill"],
    ["this skill could be better", "skill"],
    ["Aggiorna l'abilità delle fatture", "skill"],
    ["improve the invoice skill please", "skill"],
    ["Perfetto, grazie", undefined],
    ["Notevole il lavoro", undefined],
    ["Nonostante tutto va bene", undefined],
    ["now do the next one", undefined],
    ["Abilitato il servizio, procedi", undefined],
    ["", undefined],
  ];
  it.each(table)("«%s» → %s", (text, kind) => {
    expect(frictionOf(text)).toBe(kind);
  });

  it("asks for a new version after attempts fail following a skill, once per skill", async () => {
    const n = new SkillNudge();
    const hook = n.hook();
    const c = { ...ctx, sessionId: "f1" };
    await hook(call("skill_load", { name: "invoice-pdf" }), ok(), c);
    await hook(call("bash"), bad, c);
    await hook(call("bash"), bad, c);
    const r = await hook(call("bash"), ok("total 120"), c);
    expect(r?.content).toMatch(
      /^total 120\n\n\[Rasgeth\] 2 attempts failed after you loaded the skill "invoice-pdf"\./,
    );
    expect(r?.content).toMatch(/name "invoice-pdf", updates true.*summary saying what went wrong/);
    // Not again for the same skill in this conversation.
    n.turnStarted("f1", "no, the VAT is wrong");
    expect(await hook(call("bash"), ok(), c)).toBeUndefined();
  });

  it("asks after the person corrects the agent or says the skill could be better", async () => {
    const n = new SkillNudge();
    const hook = n.hook();
    const c = { ...ctx, sessionId: "f2" };
    // Words of the person before any skill was used change nothing.
    n.turnStarted("f2", "No, non così");
    await hook(call("read_file"), ok(), c);
    await hook(call("skill_load", { name: "invoice-pdf" }), ok(), c);
    expect(await hook(call("read_document"), ok(), c)).toBeUndefined();
    n.turnStarted("f2", "No, non è così: l'IVA è nell'altra tabella");
    const r = await hook(call("read_document"), ok("IVA 22"), c);
    expect(r?.content).toMatch(
      /The person corrected you after you followed the skill "invoice-pdf"\./,
    );
    const c3 = { ...ctx, sessionId: "f3" };
    await hook(call("skill_load", { name: "deploy-docs" }), ok(), c3);
    await hook(call("bash"), ok(), c3);
    n.turnStarted("f3", "Questa abilità si può migliorare, aggiungi il controllo dei link");
    expect((await hook(call("bash"), ok(), c3))?.content).toMatch(
      /The person said the skill "deploy-docs" could be better\./,
    );
    // A conversation that already proposed is left alone; a correction without a skill too.
    const c4 = { ...ctx, sessionId: "f4" };
    await hook(call("skill_load", { name: "deploy-docs" }), ok(), c4);
    await hook(call("propose_extension"), ok(), c4);
    n.turnStarted("f4", "no, wrong");
    expect(await hook(call("bash"), ok(), c4)).toBeUndefined();
  });

  it("the instructions ask for new versions sparingly", () => {
    expect(SKILL_PROMPT).toMatch(/propose a new version of it once the work is done/);
    expect(SKILL_PROMPT).toMatch(/At most one proposal per conversation/);
  });
});
