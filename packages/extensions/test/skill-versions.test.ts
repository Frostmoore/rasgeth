// Skills that improve with use (3.9.7): a new version of an installed skill goes through the same
// tests and approvals as a new skill, every installed skill keeps its versions (who, why, when),
// and the person can go back to any of them.

import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ToolContext } from "@redgiant/agent";
import { EventStore, migrate } from "@redgiant/events";
import { LocalWorkspace } from "@redgiant/tools";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { ExtensionBuilder, migrateExtensions, proposeTool, renderSkillMd } from "../src/index.js";
import { memoryDb } from "./pglite.js";

const ctx: ToolContext = { ownerId: "me", projectId: null, agentId: "a", sessionId: "s" };
let dir: string;
beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-skillver-"));
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

const text = (r: unknown) => (typeof r === "string" ? r : (r as { content: string }).content);

async function setup(auto = true) {
  const { db } = await memoryDb();
  await migrate(db);
  await migrateExtensions(db);
  const platform = join(dir, "platform");
  const project = join(dir, "project", ".redgiant");
  const store = new EventStore(db);
  const builder = new ExtensionBuilder({
    db,
    store,
    testWorkspace: async (id) => {
      const d = join(dir, "tests", id);
      await mkdir(d, { recursive: true });
      return {
        workspace: new LocalWorkspace(d),
        dispose: () => rm(d, { recursive: true, force: true }),
      };
    },
    installRoot: async (_o, projectId) => (projectId ? project : platform),
    skillRoots: async (_o, projectId) => [
      { dir: platform, scope: "platform" as const },
      ...(projectId ? [{ dir: project, scope: "project" as const }] : []),
    ],
  });
  let policy = auto;
  const tool = proposeTool(
    { id: "agent_x", ownerId: "me", projectId: null },
    builder,
    () => policy,
  );
  return {
    builder,
    tool,
    store,
    platform,
    project,
    setAuto: (v: boolean) => {
      policy = v;
    },
  };
}

const v1 = {
  kind: "skill" as const,
  name: "invoice-pdf",
  description: "Read a supplier's invoice PDF and pull out total, VAT and due date",
  body: "Open the PDF with read_document; the total is on the last page.",
  untestable_reason: "Instructions only, nothing to run here.",
  summary: "Invoices from three suppliers, read by hand twice.",
};
const v2 = {
  ...v1,
  updates: true,
  body: "Open the PDF with read_document; the total is on the last page, the VAT in the table above it.",
  summary: "The VAT was read from the wrong table twice: it is the one above the total.",
};
const skillFile = (root: string, name = "invoice-pdf") => join(root, "skills", name, "SKILL.md");

describe("a new version of a skill (3.9.7)", () => {
  it("is proposed against the installed one, tested, installed by policy and kept in the history", async () => {
    const { tool, builder, platform, store } = await setup();
    expect(text(await tool.run(v1, ctx))).toMatch(/is installed/);
    const r = text(await tool.run(v2, ctx));
    expect(r).toMatch(/new version of the skill "invoice-pdf".*is installed/);
    expect(r).toMatch(/next conversation; this one keeps the version it started with/);
    expect(await readFile(skillFile(platform), "utf8")).toMatch(/VAT in the table/);
    const [p] = await builder.list("me");
    // The person sees the reason and the differences: the version before and the one proposed.
    expect(p?.previous?.skillMd).toMatch(/the total is on the last page\.\n/);
    expect(p?.proposedSkillMd).toBe(renderSkillMd({ ...v1, body: v2.body }));
    const history = await builder.versions.list("me", "platform", "invoice-pdf");
    expect(
      history.map((v) => [v.version, v.how, v.author, v.approvedBy, v.reason, v.current]),
    ).toEqual([
      [2, "update", "agent_x", "auto", v2.summary, true],
      [1, "install", "agent_x", "auto", v1.summary, false],
    ]);
    expect(
      (await store.list()).filter((e) => e.type === "extension.versioned").map((e) => e.payload),
    ).toEqual([
      expect.objectContaining({ version: 1, how: "install" }),
      expect.objectContaining({ version: 2, how: "update" }),
    ]);
  });

  it("says why or is refused, and a failing test installs nothing", async () => {
    const { tool, builder, platform } = await setup();
    await tool.run(v1, ctx);
    const { summary: _, ...noWhy } = v2;
    expect(text(await tool.run(noWhy, ctx))).toMatch(/say why in summary/);
    const broken = text(
      await tool.run(
        { ...v2, untestable_reason: undefined, tests: [{ command: "exit 3" }] } as never,
        ctx,
      ),
    );
    expect(broken).toMatch(/failed its tests/);
    expect(await readFile(skillFile(platform), "utf8")).not.toMatch(/VAT in the table/);
    expect((await builder.versions.list("me", "platform", "invoice-pdf")).length).toBe(1);
  });

  it("waits for the person without the policy, and their yes is in the history", async () => {
    const { tool, builder, setAuto } = await setup();
    await tool.run(v1, ctx);
    setAuto(false);
    expect(text(await tool.run(v2, ctx))).toMatch(/an update of the skill "invoice-pdf".*waits/);
    const [p] = await builder.list("me", "pending");
    await builder.decide("me", p?.id ?? "", "approve", "human");
    const [last] = await builder.versions.list("me", "platform", "invoice-pdf");
    expect(last).toMatchObject({ version: 2, author: "agent_x", approvedBy: "human" });
  });

  it("never installs by itself a version with scripts, nor a tool", async () => {
    const { tool, builder } = await setup();
    await tool.run(v1, ctx);
    const scripted = text(await tool.run({ ...v2, files: { "vat.py": "print('vat')\n" } }, ctx));
    expect(scripted).toMatch(/code never installs by itself/);
    const t = text(
      await tool.run(
        {
          kind: "tool",
          name: "vat-rate",
          description: "The VAT rate of a country",
          command: "cat",
          tests: [{ input: {}, expectExitCode: 0 }],
        },
        ctx,
      ),
    );
    expect(t).toMatch(/waits for the user's approval/);
    expect((await builder.list("me", "pending")).map((p) => p.kind).sort()).toEqual([
      "skill",
      "tool",
    ]);
  });

  it("keeps a skill from before the history as version 1, and a change by hand as its own", async () => {
    const { tool, builder, platform } = await setup();
    // Installed before 3.9.7: nobody knows who wrote it, so a new version waits.
    await mkdir(join(platform, "skills", "invoice-pdf"), { recursive: true });
    await writeFile(skillFile(platform), renderSkillMd(v1));
    expect(text(await tool.run(v2, ctx))).toMatch(/waits/);
    const [p] = await builder.list("me", "pending");
    await builder.decide("me", p?.id ?? "", "approve", "human");
    // Then the person edits the file by hand.
    await writeFile(skillFile(platform), renderSkillMd({ ...v1, body: "Edited by hand, twice." }));
    await tool.run({ ...v2, body: `${v2.body} Check the due date too.` }, ctx);
    const history = await builder.versions.list("me", "platform", "invoice-pdf");
    expect(history.map((v) => [v.version, v.how, v.author])).toEqual([
      [3, "edited", null],
      [2, "update", "agent_x"],
      [1, "baseline", null],
    ]);
    // Over a change by hand the agent's version waits.
    expect((await builder.list("me", "pending")).length).toBe(1);
  });

  it("goes back to version N as a new version, files and all", async () => {
    const { tool, builder, platform, store } = await setup();
    await tool.run({ ...v1, files: { "suppliers.md": "ACME, Rossi\n" } }, ctx);
    await tool.run({ ...v2, updates: undefined, files: { "vat.md": "Above the total.\n" } }, ctx);
    const folder = join(platform, "skills", "invoice-pdf");
    expect(await stat(join(folder, "suppliers.md")).catch(() => undefined)).toBeUndefined();
    const v = await builder.versions.rollback("me", "platform", "invoice-pdf", 1, "human");
    expect(v).toBe(3);
    expect(await readFile(skillFile(platform), "utf8")).toBe(renderSkillMd(v1));
    expect(await readFile(join(folder, "suppliers.md"), "utf8")).toBe("ACME, Rossi\n");
    expect(await stat(join(folder, "vat.md")).catch(() => undefined)).toBeUndefined();
    const history = await builder.versions.list("me", "platform", "invoice-pdf");
    expect(history[0]).toMatchObject({
      version: 3,
      how: "rollback",
      author: "human",
      fromVersion: 1,
      files: ["suppliers.md"],
      current: true,
    });
    expect(await builder.versions.skillMd("me", "platform", "invoice-pdf", 2)).toMatch(/VAT/);
    expect((await store.list()).at(-1)?.payload).toMatchObject({
      how: "rollback",
      version: 3,
      fromVersion: 1,
    });
    await expect(
      builder.versions.rollback("me", "platform", "invoice-pdf", 9, "human"),
    ).rejects.toThrow(/no version 9/);
    // After going back to the person's choice, an agent's next version waits for them.
    expect(text(await tool.run(v2, ctx))).toMatch(/waits/);
  });

  it("an update from a project lands where the skill lives (the platform's)", async () => {
    const { builder, platform, project } = await setup();
    const inProject = proposeTool(
      { id: "agent_p", ownerId: "me", projectId: "p" },
      builder,
      () => true,
    );
    const tool = proposeTool(
      { id: "agent_x", ownerId: "me", projectId: null },
      builder,
      () => true,
    );
    await tool.run(v1, ctx);
    expect(text(await inProject.run(v2, { ...ctx, projectId: "p" }))).toMatch(/is installed/);
    expect(await readFile(skillFile(platform), "utf8")).toMatch(/VAT in the table/);
    expect(await stat(skillFile(project)).catch(() => undefined)).toBeUndefined();
    expect((await builder.versions.list("me", "platform", "invoice-pdf"))[0]).toMatchObject({
      version: 2,
      author: "agent_p",
    });
  });
});
