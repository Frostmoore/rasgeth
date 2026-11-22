// Magic rules (3.12, the person: «mettici anche qui la generazione magica tramite god»): the person
// describes a rule in words, God builds it (event, conditions, actions), says what is missing,
// tests it on its two examples and proposes it beside the conversation. Nothing is a rule before
// the person's yes; it is made switched on only when its examples pass.
import { randomUUID } from "node:crypto";
import type { Tool } from "@redgiant/agent";
import type { SqlClient } from "@redgiant/events";
import { tryExamples } from "@redgiant/hierarchy";
import { type MagicRule, PersonRule, PRODUCT_NAME, RuleDraft } from "@redgiant/protocol";
import { z } from "zod";
import type { MagicHost } from "./magic.js";
import { magicTitle } from "./magic.js";
import { type PersonRules, RuleStateError } from "./person-rules.js";
import { blankPastedSecrets } from "./vault.js";

export class MagicRuleNotFoundError extends Error {}

interface Row {
  id: string;
  owner_id: string;
  title: string;
  request: string;
  session_id: string;
  agent_id: string;
  status: MagicRule["status"];
  proposal: MagicRule["proposal"] | string | null;
  rule_id: string | null;
  created_at: Date | string;
  updated_at: Date | string;
}

const iso = (d: Date | string) => new Date(d).toISOString();
const toMagic = (r: Row): MagicRule => ({
  id: r.id,
  title: r.title,
  request: r.request,
  sessionId: r.session_id,
  agentId: r.agent_id,
  status: r.status,
  proposal: typeof r.proposal === "string" ? JSON.parse(r.proposal) : (r.proposal ?? null),
  ruleId: r.rule_id,
  createdAt: iso(r.created_at),
  updatedAt: iso(r.updated_at),
});

/** The rule's fields, for God. */
export const RULE_HELP_TEXT = `A rule is JSON: {name, description, when, if, actions, examples}.
when.event: usage (a subscription's window was read: facts marginPct, usedPct, window "7d" or "5h" or "model:<name>", provider), budget (facts budgetPct, budget), tool (a tool or command about to run: facts tool, command, path, project, agent), file (a file about to be written: path, tool, project, agent), agent_done (an agent ended its turn: agent, project, stopReason), schedule (needs cron and timezone; no facts).
if: conditions that must all hold: {field, op, value}; numbers (marginPct, usedPct, budgetPct) use lt, lte, gt, gte, eq, neq; texts use eq, neq, matches (whole text, * and ?), contains.
margin = how much of the window has passed minus how much of it is used, in points (+31: well ahead; 0: on pace).
actions (1-10): {do: "notify", text, to: [page, app, chats]}, {do: "ask", text} and {do: "block", text} (only for tool and file), {do: "stop", text, scope: all|project|agent, resume: person|auto} (the agents save and stop until the person resumes them), {do: "tools_off", kits: [...], tools: [...]}, {do: "automation", automation: "<name>"}, {do: "command", command, project} (runs in the sandbox, checked as an agent's command).
examples: {fire: {<field>: value...}, pass: {...}}: one case where the rule must act and one where it must not. There is no action that allows anything.`;

/** What God reads, only in a magic rule's conversation. */
export const MAGIC_RULE_PROMPT = `## This conversation builds a rule (magic rule)
The person pressed "Magic rule" and wrote what they want: a rule of theirs that ${PRODUCT_NAME} enforces by itself (when something happens, if conditions hold, then act). Your job is to turn it into one rule, with them:
1. Understand what they want. Ask short, simple questions (ask_user) only for what you cannot sensibly choose (a threshold, where to be told). Write to them in their language, in plain words.
2. Build the rule and its two examples (one case that must make it act, one that must not). Call propose_rule without proposing first ("test": true) to see whether it is valid and its examples pass; fix what is wrong.
3. Call propose_rule with the rule, a two-line summary in the person's language and what is still missing (missing: words such as "a linked chat"). The person sees it beside this conversation and approves, changes or refuses it. Nothing exists before their yes. When they refuse, change what they ask and propose again.
A rule never gives more than the person has: it can tell, ask, block, stop, switch tools off, start an automation or a command that is checked like an agent's; it can never allow anything.

### The rule
${RULE_HELP_TEXT}`;

export async function migrateMagicRules(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_magic_rules (
      id         text PRIMARY KEY,
      owner_id   text NOT NULL,
      title      text NOT NULL,
      request    text NOT NULL,
      session_id text NOT NULL UNIQUE,
      agent_id   text NOT NULL,
      status     text NOT NULL DEFAULT 'building',
      proposal   jsonb,
      rule_id    text,
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now()
    )`);
}

export class MagicRules {
  constructor(
    private readonly o: {
      db: SqlClient;
      rules: PersonRules;
      host: Pick<MagicHost, "god" | "startSession" | "send">;
    },
  ) {}

  private async row(ownerId: string, id: string): Promise<Row> {
    const [r] = await this.o.db.query<Row>(
      "SELECT * FROM rg_magic_rules WHERE id = $1 AND owner_id = $2",
      [id, ownerId],
    );
    if (!r) throw new MagicRuleNotFoundError(`Magic rule "${id}" not found`);
    return r;
  }

  async list(ownerId: string): Promise<MagicRule[]> {
    const rows = await this.o.db.query<Row>(
      "SELECT * FROM rg_magic_rules WHERE owner_id = $1 AND status <> 'dismissed' ORDER BY created_at DESC",
      [ownerId],
    );
    return rows.map(toMagic);
  }

  async get(ownerId: string, id: string): Promise<MagicRule> {
    return toMagic(await this.row(ownerId, id));
  }

  async forSession(sessionId: string): Promise<MagicRule | undefined> {
    const [r] = await this.o.db.query<Row>("SELECT * FROM rg_magic_rules WHERE session_id = $1", [
      sessionId,
    ]);
    return r ? toMagic(r) : undefined;
  }

  async create(ownerId: string, request: string): Promise<MagicRule> {
    const text = blankPastedSecrets(request.trim());
    if (!text) throw new RuleStateError("Write what the rule should do");
    const god = this.o.host.god(ownerId);
    if (!god) throw new RuleStateError("There is no God yet: finish the setup first");
    const id = `mrule_${randomUUID().slice(0, 12)}`;
    const sessionId = await this.o.host.startSession(ownerId, god.id, async (sid) => {
      await this.o.db.query(
        `INSERT INTO rg_magic_rules (id, owner_id, title, request, session_id, agent_id)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [id, ownerId, magicTitle(text), text, sid, god.id],
      );
    });
    await this.o.host.send(ownerId, sessionId, text);
    return this.get(ownerId, id);
  }

  /** God's proposal: checked and tried as saving would, kept for the person. */
  async propose(
    ownerId: string,
    sessionId: string,
    p: { rule: unknown; summary: string; missing: string[] },
  ): Promise<MagicRule> {
    const draft = this.o.rules.check(p.rule);
    const magic = await this.forSession(sessionId);
    if (!magic || magic.status === "dismissed")
      throw new RuleStateError("This conversation is not a magic rule");
    if (magic.status === "done") throw new RuleStateError("This magic rule is already approved");
    const proposal = {
      rule: draft,
      summary: p.summary,
      missing: p.missing,
      trial: tryExamples(draft),
      at: new Date().toISOString(),
    };
    await this.o.db.query(
      `UPDATE rg_magic_rules SET status = 'ready', proposal = $2::jsonb, title = $3, updated_at = now()
       WHERE id = $1`,
      [magic.id, JSON.stringify(proposal), draft.name],
    );
    return this.get(ownerId, magic.id);
  }

  /**
   * The person's yes (with their change, if they made one): the rule is made, switched on when its
   * examples pass, off otherwise (it says why).
   */
  async approve(
    ownerId: string,
    id: string,
    rule?: unknown,
  ): Promise<{ magic: MagicRule; rule: PersonRule }> {
    const m = await this.get(ownerId, id);
    if (m.status !== "ready" || !m.proposal)
      throw new RuleStateError("There is no proposal to approve yet");
    const draft = this.o.rules.check(rule ?? m.proposal.rule);
    const made = await this.o.rules.create(ownerId, draft, {
      origin: "god",
      by: "person",
      enable: tryExamples(draft).ok,
    });
    await this.o.db.query(
      "UPDATE rg_magic_rules SET status = 'done', rule_id = $2, updated_at = now() WHERE id = $1",
      [id, made.id],
    );
    return { magic: await this.get(ownerId, id), rule: PersonRule.parse(made) };
  }

  async reject(ownerId: string, id: string, reason?: string): Promise<MagicRule> {
    const m = await this.get(ownerId, id);
    if (m.status !== "ready") throw new RuleStateError("There is no proposal to refuse");
    await this.o.db.query(
      "UPDATE rg_magic_rules SET status = 'building', proposal = NULL, updated_at = now() WHERE id = $1",
      [id],
    );
    const words = reason?.trim();
    await this.o.host.send(
      ownerId,
      m.sessionId,
      words
        ? `I did not approve the rule. ${words}`
        : "I did not approve the rule. Ask me what to change.",
    );
    return this.get(ownerId, id);
  }

  async dismiss(ownerId: string, id: string): Promise<void> {
    await this.row(ownerId, id);
    await this.o.db.query(
      "UPDATE rg_magic_rules SET status = 'dismissed', updated_at = now() WHERE id = $1",
      [id],
    );
  }
}

/** God's tool in a magic rule's conversation: try the rule, or propose it to the person. */
export function magicRuleTools(
  self: { id: string; kind: string; ownerId: string },
  magic: MagicRules,
): Tool[] {
  if (self.kind !== "god") return [];
  const owner = self.ownerId;
  return [
    {
      def: {
        name: "propose_rule",
        description:
          'Magic rules: with "test": true, checks the rule and runs its two examples (nothing is shown to the person). Without it, shows the person the rule as a proposal to approve, change or refuse beside this conversation; nothing exists before their yes. rule: the rule as described in the system prompt; summary: two lines for the person; missing: what is still missing, in words.',
        inputSchema: {
          type: "object",
          properties: {
            rule: { type: "object" },
            summary: { type: "string" },
            missing: { type: "array", items: { type: "string" } },
            test: { type: "boolean" },
          },
          required: ["rule"],
        },
      },
      schema: z.object({
        rule: z.unknown(),
        summary: z.string().default(""),
        missing: z.array(z.string()).default([]),
        test: z.boolean().default(false),
      }),
      async run(
        i: { rule: unknown; summary: string; missing: string[]; test: boolean },
        ctx: { sessionId?: string },
      ) {
        const parsed = RuleDraft.safeParse(i.rule);
        if (!parsed.success)
          return {
            content: `Not valid: ${parsed.error.issues.map((x) => `${x.path.join(".")}: ${x.message}`).join("; ")}`,
            isError: true,
          };
        const trial = tryExamples(parsed.data);
        if (i.test)
          return trial.ok
            ? "Valid; the case that must act acts and the case that must pass passes."
            : { content: `Not ready: ${trial.problems.join("; ")}`, isError: true };
        try {
          await magic.propose(owner, ctx.sessionId ?? "", i);
          return [
            "Proposed. The person sees it beside this conversation and approves, changes or refuses it; wait for their answer.",
            trial.ok
              ? ""
              : `Its examples do not pass yet (${trial.problems.join("; ")}): it would be made switched off.`,
          ]
            .filter(Boolean)
            .join("\n");
        } catch (err) {
          return { content: `Not proposed: ${(err as Error).message}`, isError: true };
        }
      },
    } as Tool,
  ];
}
