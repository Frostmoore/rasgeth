// The person's rules (3.12, «Regole della persona»): rules they write (or God builds with them)
// that Rasgeth enforces by itself. Where they plug in: before every tool call (`beforeTool`, beside
// the permission broker: a rule can only block or make it ask, never allow), before every model
// call (`modelGate`: a stop holds the agents), when an agent ends its turn (`agentDone`), when the
// subscriptions' windows are read (`usage`, every few minutes from `tick`) and at the rules' own
// times (`schedule`). Every change keeps the version before it (history, undo); a rule switches on
// only when its two examples pass. The pure parts are in `@redgiant/hierarchy` (person-rules.ts).
import { randomUUID } from "node:crypto";
import { nextRun, webhookSecrets } from "@redgiant/automations";
import type { SqlClient } from "@redgiant/events";
import {
  fireRules,
  ruleProblems,
  toolFacts,
  webhookFacts,
  toolVerdict,
  tryExamples,
  windowMargin,
} from "@redgiant/hierarchy";
import {
  PersonRule,
  type Recipe,
  RULE_TEMPLATES,
  RuleDraft,
  type RuleDraftInput,
  type RuleEventKind,
  type RuleFire,
  RuleHold,
  type RuleNotifyTo,
  type RuleSample,
  type RuleTemplateId,
  type RuleTrial,
  type RuleVersion,
} from "@redgiant/protocol";

export class RuleNotFoundError extends Error {}
export class RuleStateError extends Error {}
/** A webhook call with a wrong secret, for a rule that is off or not a webhook's. */
export class RuleForbiddenError extends Error {}

/** What the rules need from the core. */
export interface RulesHost {
  language(ownerId: string): "it" | "en";
  /** Tells the person; resolves to where it arrived ("page", "app", "chats"). */
  notify(
    ownerId: string,
    text: string,
    to: readonly RuleNotifyTo[],
    info: { ruleId: string; ruleName: string; fireId: string },
  ): Promise<string[]>;
  /** Interrupts the turns still running in a stop's scope; resolves to how many. */
  interrupt(ownerId: string, hold: RuleHold): Promise<number>;
  /** Switches kits and tools off for every agent (an undoable configuration change). */
  toolsOff(ownerId: string, kits: string[], tools: string[]): Promise<void>;
  /** Starts an automation by name or id; resolves to what happened, in words. */
  runAutomation(ownerId: string, automation: string): Promise<string>;
  /**
   * Runs a command in a sandbox, checked as an agent's would be (dangers, criticalOf, the person
   * asked when needed, never the server's environment). Resolves to the exit code and output.
   */
  runCommand(
    ownerId: string,
    command: string,
    project: string | undefined,
    rule: { id: string; name: string },
  ): Promise<{ exitCode: number; output: string }>;
  /** The subscriptions' windows, as Settings > Subscriptions shows them. */
  limits(): Promise<
    {
      provider: string;
      windows: { id: string; usedPct: number; resetsAt?: string | undefined }[];
    }[]
  >;
  /** The owners that exist (the usage readings are the server's, the rules each owner's). */
  owners(): Promise<string[]>;
}

interface RuleRow {
  id: string;
  owner_id: string;
  body: PersonRule | string;
}
interface VersionRow {
  rule_id: string;
  version: number;
  change: RuleVersion["change"];
  by_whom: string;
  at: Date | string;
  body: PersonRule | string | null;
}
interface FireRow {
  id: string;
  rule_id: string;
  rule_name: string;
  at: Date | string;
  event: RuleEventKind;
  facts: RuleSample | string;
  results: string[] | string;
}

const json = <T>(v: T | string): T => (typeof v === "string" ? (JSON.parse(v) as T) : v);
const iso = (d: Date | string) => new Date(d).toISOString();

export async function migratePersonRules(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_person_rules (
      id         text PRIMARY KEY,
      owner_id   text NOT NULL,
      body       jsonb NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    )`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_person_rule_versions (
      rule_id  text NOT NULL,
      owner_id text NOT NULL,
      version  integer NOT NULL,
      change   text NOT NULL,
      by_whom  text NOT NULL,
      at       timestamptz NOT NULL DEFAULT now(),
      body     jsonb,
      PRIMARY KEY (rule_id, version)
    )`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_person_rule_fires (
      id        text PRIMARY KEY,
      owner_id  text NOT NULL,
      rule_id   text NOT NULL,
      rule_name text NOT NULL,
      at        timestamptz NOT NULL DEFAULT now(),
      event     text NOT NULL,
      facts     jsonb NOT NULL,
      results   jsonb NOT NULL
    )`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_person_rule_hooks (
      rule_id     text PRIMARY KEY,
      owner_id    text NOT NULL,
      secret_hash text NOT NULL
    )`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_person_rule_holds (
      owner_id text NOT NULL,
      rule_id  text NOT NULL,
      body     jsonb NOT NULL,
      PRIMARY KEY (owner_id, rule_id)
    )`);
}

/** The words of the rules' own messages, in the person's language. */
const WORDS = {
  en: {
    fired: "Rule «{name}»",
    stopped: "Rule «{name}» stopped the agents: {reason}. Resume them in Settings > Rules.",
    holdTool:
      "Stopped by the person's rule «{name}» ({reason}): do not call more tools. In a few lines, say where you are and what is left; the person resumes the work.",
    holdModel: "stopped by the person's rule «{name}»: {reason}",
    margin: "{provider} {window}: margin {margin} points, {used}% used",
    agentDone: "{agent} finished ({stop})",
    tool: "{tool}{command}",
    time: "the time came",
    budget: "budget {name}: {pct}% used",
    webhook: "its address was called",
  },
  it: {
    fired: "Regola «{name}»",
    stopped:
      "La regola «{name}» ha fermato gli agenti: {reason}. Li riprendi da Impostazioni > Regole.",
    holdTool:
      "Fermato dalla regola della persona «{name}» ({reason}): do not call more tools. In a few lines, say where you are and what is left; the person resumes the work.",
    holdModel: "fermato dalla regola della persona «{name}»: {reason}",
    margin: "{provider} {window}: margine {margin} punti, {used}% usato",
    agentDone: "{agent} ha finito ({stop})",
    tool: "{tool}{command}",
    time: "è l'ora",
    budget: "budget {name}: {pct}% usato",
    webhook: "il suo indirizzo è stato chiamato",
  },
} as const;
type Word = keyof (typeof WORDS)["en"];

/** How long a stopped agent may take to save its work before its turn is cut. */
const GRACE_MS = 120_000;
/** How often the subscriptions' windows are read for the rules. */
const USAGE_EVERY_MS = 5 * 60_000;

export class PersonRules {
  private readonly cache = new Map<string, Promise<PersonRule[]>>();
  /** Continuous rules holding now, per owner (`fireRules`' `active`). */
  private readonly active = new Map<string, Set<string>>();
  private holds: Map<string, RuleHold[]> | undefined;
  private holdsLoading: Promise<void> | undefined;
  private readonly next = new Map<string, number>();
  private lastUsage = Number.NEGATIVE_INFINITY;
  private timer: NodeJS.Timeout | undefined;
  private readonly pending = new Set<Promise<unknown>>();
  private readonly changeListeners = new Set<(ownerId: string) => void>();

  constructor(
    private readonly o: {
      db: SqlClient;
      host: RulesHost;
      now?: () => number;
      graceMs?: number;
      usageEveryMs?: number;
    },
  ) {}

  private now() {
    return this.o.now?.() ?? Date.now();
  }
  private say(ownerId: string, key: Word, vars: Record<string, string | number> = {}) {
    return WORDS[this.o.host.language(ownerId)][key].replace(/\{(\w+)\}/g, (_, k: string) =>
      String(vars[k] ?? ""),
    );
  }

  /** Something about an owner's rules changed (a page reloads them). */
  onChange(listener: (ownerId: string) => void): () => void {
    this.changeListeners.add(listener);
    return () => this.changeListeners.delete(listener);
  }
  private changed(ownerId: string) {
    this.cache.delete(ownerId);
    for (const l of this.changeListeners) l(ownerId);
  }

  // ---------- The rules ----------

  async list(ownerId: string): Promise<PersonRule[]> {
    let p = this.cache.get(ownerId);
    if (!p) {
      p = this.o.db
        .query<RuleRow>("SELECT * FROM rg_person_rules WHERE owner_id = $1 ORDER BY id", [ownerId])
        .then((rows) =>
          rows
            .map((r) => PersonRule.parse(json(r.body)))
            .sort((a, b) => a.createdAt.localeCompare(b.createdAt)),
        );
      this.cache.set(ownerId, p);
      p.catch(() => this.cache.delete(ownerId));
    }
    return p;
  }

  async get(ownerId: string, id: string): Promise<PersonRule> {
    const r = (await this.list(ownerId)).find((x) => x.id === id);
    if (!r) throw new RuleNotFoundError(`Rule "${id}" not found`);
    return r;
  }

  /** A draft read and checked as saving would; the problems in one error. */
  check(input: unknown): RuleDraft {
    const parsed = RuleDraft.safeParse(input);
    if (!parsed.success)
      throw new RuleStateError(
        parsed.error.issues.map((i) => `${i.path.join(".") || "rule"}: ${i.message}`).join("; "),
      );
    const problems = ruleProblems(parsed.data);
    if (parsed.data.when.event === "schedule" && parsed.data.when.cron && !problems.length)
      try {
        nextRun(this.recipe(parsed.data), new Date(this.now()));
      } catch (err) {
        problems.push(`when: ${(err as Error).message}`);
      }
    if (problems.length) throw new RuleStateError(problems.join("; "));
    return parsed.data;
  }

  /** The rule's two examples, run now (the editor's «Try»). */
  trial(input: unknown): RuleTrial {
    const parsed = RuleDraft.safeParse(input);
    if (!parsed.success)
      return {
        ok: false,
        fire: null,
        pass: null,
        problems: parsed.error.issues.map((i) => `${i.path.join(".") || "rule"}: ${i.message}`),
      };
    return tryExamples(parsed.data);
  }

  private async save(
    ownerId: string,
    rule: PersonRule,
    change: RuleVersion["change"],
    by: string,
  ): Promise<PersonRule> {
    await this.o.db.query(
      `INSERT INTO rg_person_rules (id, owner_id, body, updated_at) VALUES ($1, $2, $3::jsonb, now())
       ON CONFLICT (id) DO UPDATE SET body = EXCLUDED.body, updated_at = now()`,
      [rule.id, ownerId, JSON.stringify(rule)],
    );
    await this.version(ownerId, rule.id, rule.version, change, by, rule);
    this.changed(ownerId);
    return rule;
  }
  private async version(
    ownerId: string,
    ruleId: string,
    version: number,
    change: RuleVersion["change"],
    by: string,
    body: PersonRule | null,
  ) {
    await this.o.db.query(
      `INSERT INTO rg_person_rule_versions (rule_id, owner_id, version, change, by_whom, body)
       VALUES ($1, $2, $3, $4, $5, $6::jsonb)`,
      [ruleId, ownerId, version, change, by, body ? JSON.stringify(body) : null],
    );
  }

  /** A new rule, off until the person switches it on (`enable: true` tries the examples first). */
  async create(
    ownerId: string,
    input: unknown,
    o: { origin?: PersonRule["origin"]; by?: string; enable?: boolean } = {},
  ): Promise<PersonRule> {
    const draft = this.check(input);
    if (o.enable) this.mustPass(draft);
    const at = new Date(this.now()).toISOString();
    const rule: PersonRule = {
      ...draft,
      id: `rule_${randomUUID().slice(0, 12)}`,
      enabled: o.enable === true,
      origin: o.origin ?? "person",
      version: 1,
      createdAt: at,
      updatedAt: at,
      lastFiredAt: null,
    };
    return this.save(ownerId, rule, "created", o.by ?? "person");
  }

  private mustPass(draft: RuleDraft) {
    const t = tryExamples(draft);
    if (!t.ok) throw new RuleStateError(`Not switched on: ${t.problems.join("; ")}`);
  }

  /** A changed rule; a rule that is on stays on only if its examples still pass. */
  async update(ownerId: string, id: string, input: unknown, by = "person"): Promise<PersonRule> {
    const now = await this.get(ownerId, id);
    const draft = this.check(input);
    if (now.enabled) this.mustPass(draft);
    return this.save(
      ownerId,
      {
        ...now,
        ...draft,
        version: now.version + 1,
        updatedAt: new Date(this.now()).toISOString(),
      },
      "changed",
      by,
    );
  }

  /** On only when its two examples pass (tested before it acts on anything real). */
  async setEnabled(ownerId: string, id: string, on: boolean, by = "person"): Promise<PersonRule> {
    const now = await this.get(ownerId, id);
    if (now.enabled === on) return now;
    if (on) this.mustPass(now);
    if (!on) await this.release(ownerId, id);
    return this.save(
      ownerId,
      {
        ...now,
        enabled: on,
        version: now.version + 1,
        updatedAt: new Date(this.now()).toISOString(),
      },
      on ? "enabled" : "disabled",
      by,
    );
  }

  /** Removed (its history stays: «undo» brings it back). */
  async remove(ownerId: string, id: string, by = "person"): Promise<void> {
    const now = await this.get(ownerId, id);
    await this.release(ownerId, id);
    await this.o.db.query("DELETE FROM rg_person_rules WHERE id = $1 AND owner_id = $2", [
      id,
      ownerId,
    ]);
    await this.version(ownerId, id, now.version + 1, "removed", by, null);
    this.changed(ownerId);
  }

  /** Every version of the owner's rules (or one rule's), newest first. */
  async history(ownerId: string, id?: string, limit = 100): Promise<RuleVersion[]> {
    const rows = await this.o.db.query<VersionRow>(
      `SELECT rule_id, version, change, by_whom, at, body FROM rg_person_rule_versions
       WHERE owner_id = $1${id ? " AND rule_id = $3" : ""} ORDER BY at DESC, version DESC LIMIT $2`,
      id ? [ownerId, limit, id] : [ownerId, limit],
    );
    return rows.map((r) => ({
      ruleId: r.rule_id,
      version: r.version,
      change: r.change,
      by: r.by_whom,
      at: iso(r.at),
      rule: r.body ? PersonRule.parse(json(r.body)) : null,
    }));
  }

  /**
   * Takes a rule's last change back: the version before it returns (a removed rule comes back,
   * switched off; a new rule goes away). Undoing is itself a change, so it can be undone too.
   */
  async undo(ownerId: string, id: string, by = "person"): Promise<PersonRule | null> {
    const [last, before] = await this.history(ownerId, id, 2);
    if (!last) throw new RuleNotFoundError(`Rule "${id}" not found`);
    const version = last.version + 1;
    if (!before || !before.rule) {
      // Undoing its creation: the rule goes (its history stays).
      if (last.rule) {
        await this.release(ownerId, id);
        await this.o.db.query("DELETE FROM rg_person_rules WHERE id = $1 AND owner_id = $2", [
          id,
          ownerId,
        ]);
        await this.version(ownerId, id, version, "undone", by, null);
        this.changed(ownerId);
      }
      return null;
    }
    // What comes back is checked as any change: on only if its examples pass now.
    const back: PersonRule = {
      ...before.rule,
      enabled: before.rule.enabled && tryExamples(before.rule).ok,
      version,
      updatedAt: new Date(this.now()).toISOString(),
    };
    if (!back.enabled) await this.release(ownerId, id);
    return this.save(ownerId, back, "undone", by);
  }

  /** A ready-made rule set (never on by default): added off, unless `enable`. */
  async addTemplate(
    ownerId: string,
    template: RuleTemplateId,
    o: { enable?: boolean; by?: string; once?: boolean } = {},
  ): Promise<PersonRule[]> {
    const lang = this.o.host.language(ownerId);
    const have = await this.list(ownerId);
    const out: PersonRule[] = [];
    for (const t of RULE_TEMPLATES[template]) {
      const name = t.name[lang];
      const same = have.find((r) => r.name === name);
      if (same) {
        out.push(same);
        continue;
      }
      // `once` (an installation's seed): a rule the person removed is not made again.
      if (o.once) {
        const [ever] = await this.o.db.query<{ n: number }>(
          `SELECT count(*)::int AS n FROM rg_person_rule_versions
           WHERE owner_id = $1 AND (body->>'name' = $2 OR body->>'name' = $3)`,
          [ownerId, t.name.it, t.name.en],
        );
        if ((ever?.n ?? 0) > 0) continue;
      }
      out.push(
        await this.create(
          ownerId,
          { ...(t.draft as unknown as Omit<RuleDraftInput, "name">), name },
          {
            origin: "template",
            by: o.by ?? "person",
            ...(o.enable !== undefined && { enable: o.enable }),
          },
        ),
      );
    }
    return out;
  }

  async fires(ownerId: string, limit = 50): Promise<RuleFire[]> {
    const rows = await this.o.db.query<FireRow>(
      "SELECT * FROM rg_person_rule_fires WHERE owner_id = $1 ORDER BY at DESC LIMIT $2",
      [ownerId, limit],
    );
    return rows.map((r) => ({
      id: r.id,
      ruleId: r.rule_id,
      ruleName: r.rule_name,
      at: iso(r.at),
      event: r.event,
      facts: json(r.facts),
      results: json(r.results),
    }));
  }

  // ---------- Stops ----------

  private async loadHolds(): Promise<Map<string, RuleHold[]>> {
    if (this.holds) return this.holds;
    this.holdsLoading ??= this.o.db
      .query<{ owner_id: string; body: RuleHold | string }>(
        "SELECT owner_id, body FROM rg_person_rule_holds",
      )
      .then((rows) => {
        const m = new Map<string, RuleHold[]>();
        for (const r of rows)
          m.set(r.owner_id, [...(m.get(r.owner_id) ?? []), RuleHold.parse(json(r.body))]);
        this.holds = m;
      })
      .finally(() => {
        this.holdsLoading = undefined;
      });
    await this.holdsLoading;
    return this.holds ?? new Map();
  }

  /** The stops in place now. */
  async holdsOf(ownerId: string): Promise<RuleHold[]> {
    return (await this.loadHolds()).get(ownerId) ?? [];
  }

  /** The person resumes the agents: one rule's stop, or all of them. */
  async resume(ownerId: string, ruleId?: string): Promise<void> {
    const holds = await this.holdsOf(ownerId);
    for (const h of holds)
      if (!ruleId || h.ruleId === ruleId) await this.release(ownerId, h.ruleId);
  }

  private async release(ownerId: string, ruleId: string) {
    const all = await this.loadHolds();
    const mine = all.get(ownerId) ?? [];
    if (!mine.some((h) => h.ruleId === ruleId)) return;
    all.set(
      ownerId,
      mine.filter((h) => h.ruleId !== ruleId),
    );
    await this.o.db.query("DELETE FROM rg_person_rule_holds WHERE owner_id = $1 AND rule_id = $2", [
      ownerId,
      ruleId,
    ]);
    this.changed(ownerId);
  }

  private async hold(ownerId: string, h: RuleHold) {
    const all = await this.loadHolds();
    all.set(ownerId, [...(all.get(ownerId) ?? []).filter((x) => x.ruleId !== h.ruleId), h]);
    await this.o.db.query(
      `INSERT INTO rg_person_rule_holds (owner_id, rule_id, body) VALUES ($1, $2, $3::jsonb)
       ON CONFLICT (owner_id, rule_id) DO UPDATE SET body = EXCLUDED.body`,
      [ownerId, h.ruleId, JSON.stringify(h)],
    );
    this.changed(ownerId);
  }

  private async holdFor(
    ownerId: string,
    where: { agentId?: string | undefined; projectId?: string | null | undefined },
  ): Promise<RuleHold | undefined> {
    return (await this.holdsOf(ownerId)).find(
      (h) =>
        h.scope === "all" ||
        (h.scope === "project" && h.projectId !== undefined && h.projectId === where.projectId) ||
        (h.scope === "agent" && h.agentId !== undefined && h.agentId === where.agentId),
    );
  }

  /** Before every model call: a stop in place holds it (the turn ends as on a budget). */
  async modelGate(
    ownerId: string,
    where: { agentId?: string; projectId?: string | null },
  ): Promise<{ allow: boolean; reason?: string }> {
    const h = await this.holdFor(ownerId, where).catch(() => undefined);
    if (!h) return { allow: true };
    return {
      allow: false,
      reason: this.say(ownerId, "holdModel", { name: h.ruleName, reason: h.reason }),
    };
  }

  // ---------- Events ----------

  /**
   * Before a tool runs: a stop in place refuses it (the agent saves and says where it is), then
   * the rules on `tool` (and `file`, when it writes) decide: block, ask, or nothing. Their other
   * actions (a notice, a stop…) run beside, never holding the call longer than needed.
   */
  async beforeTool(
    ownerId: string,
    where: {
      agentId: string;
      agent: string;
      projectId?: string | null;
      project?: string | undefined;
    },
    call: { name: string; input: unknown },
  ): Promise<{ decision: "run" | "ask" | "block"; reasons: string[] }> {
    const h = await this.holdFor(ownerId, where);
    if (h)
      return {
        decision: "block",
        reasons: [this.say(ownerId, "holdTool", { name: h.ruleName, reason: h.reason })],
      };
    const rules = await this.list(ownerId);
    if (!rules.some((r) => r.enabled && (r.when.event === "tool" || r.when.event === "file")))
      return { decision: "run", reasons: [] };
    const { facts, writes } = toolFacts(call, {
      project: where.project ?? where.projectId ?? undefined,
      agent: where.agent,
    });
    const fired = [
      ...fireRules(rules, "tool", facts).fired,
      ...(writes ? fireRules(rules, "file", facts).fired : []),
    ];
    if (!fired.length) return { decision: "run", reasons: [] };
    const verdict = toolVerdict(fired);
    for (const r of fired)
      this.track(
        this.act(
          ownerId,
          r,
          writes && r.when.event === "file" ? "file" : "tool",
          facts,
          where,
          verdict.decision,
        ),
      );
    return verdict;
  }

  /** An agent ended its turn. */
  agentDone(
    ownerId: string,
    t: {
      agentId: string;
      agent: string;
      projectId?: string | null;
      project?: string;
      stopReason: string;
    },
  ): void {
    this.track(
      (async () => {
        const facts: RuleSample = { agent: t.agent, stopReason: t.stopReason };
        const project = t.project ?? t.projectId;
        if (project) facts.project = project;
        const { fired } = fireRules(await this.list(ownerId), "agent_done", facts);
        for (const r of fired) await this.act(ownerId, r, "agent_done", facts, t);
      })(),
    );
  }

  /**
   * A level read again (a window's use, a budget's): each item acts once when its rules start
   * holding, and a stop that resumes by itself is lifted once they stop holding.
   */
  private async level(
    ownerId: string,
    event: "usage" | "budget",
    items: { key: string; facts: RuleSample }[],
  ): Promise<void> {
    const rules = await this.list(ownerId);
    if (!rules.some((r) => r.enabled && r.when.event === event)) return;
    let active = this.active.get(ownerId) ?? new Set<string>();
    for (const it of items) {
      const r = fireRules(rules, event, it.facts, active, it.key);
      active = r.active;
      for (const rule of r.fired) await this.act(ownerId, rule, event, it.facts, {});
      for (const rule of r.released)
        if (rule.actions.some((a) => a.do === "stop" && a.resume === "auto"))
          await this.release(ownerId, rule.id);
    }
    this.active.set(ownerId, active);
  }

  /** A reading of the subscriptions' windows: the margin and the use of each. */
  async usage(
    ownerId: string,
    readings: Awaited<ReturnType<RulesHost["limits"]>>,
    now = this.now(),
  ): Promise<void> {
    const items: { key: string; facts: RuleSample }[] = [];
    for (const p of readings)
      for (const w of p.windows) {
        const facts: RuleSample = { provider: p.provider, window: w.id, usedPct: w.usedPct };
        const margin = windowMargin(w, now);
        if (margin !== undefined) facts.marginPct = margin;
        items.push({ key: `${p.provider}/${w.id}`, facts });
      }
    await this.level(ownerId, "usage", items);
  }

  /** A spend was recorded (3.12): the budgets with a limit, by name, and how much is used. */
  async budget(
    ownerId: string,
    readings: { id: string; name: string; pct: number }[],
  ): Promise<void> {
    await this.level(
      ownerId,
      "budget",
      readings.map((b) => ({ key: `budget/${b.id}`, facts: { budget: b.name, budgetPct: b.pct } })),
    );
  }

  /** A rule's webhook address: a new secret, shown only now (the server keeps its hash). */
  async rotateSecret(ownerId: string, id: string): Promise<string> {
    const r = await this.get(ownerId, id);
    if (r.when.event !== "webhook")
      throw new RuleStateError("This rule is not called by a webhook");
    const secret = webhookSecrets.make();
    await this.o.db.query(
      `INSERT INTO rg_person_rule_hooks (rule_id, owner_id, secret_hash) VALUES ($1, $2, $3)
       ON CONFLICT (rule_id) DO UPDATE SET secret_hash = EXCLUDED.secret_hash, owner_id = EXCLUDED.owner_id`,
      [id, ownerId, webhookSecrets.hash(secret)],
    );
    return secret;
  }

  /**
   * A call to a rule's address (3.12): its secret checked as the automations' are; the body is
   * data, matched by the rule's conditions and never passed on as words to follow. A wrong secret,
   * a rule switched off or not a webhook's: forbidden, nothing acts.
   */
  async webhook(id: string, secret: string, body: unknown): Promise<{ acted: boolean }> {
    const [row] = await this.o.db.query<{ owner_id: string; secret_hash: string }>(
      "SELECT owner_id, secret_hash FROM rg_person_rule_hooks WHERE rule_id = $1",
      [id],
    );
    const rule = row ? (await this.list(row.owner_id)).find((r) => r.id === id) : undefined;
    if (
      !row ||
      !rule ||
      !rule.enabled ||
      rule.when.event !== "webhook" ||
      !webhookSecrets.matches(secret, row.secret_hash)
    )
      throw new RuleForbiddenError("Forbidden");
    const facts = webhookFacts(body);
    const { fired } = fireRules([rule], "webhook", facts);
    // The fire is written down without the body: what was sent stays out of the person's list.
    for (const r of fired) await this.act(row.owner_id, r, "webhook", {}, {});
    return { acted: fired.length > 0 };
  }

  /** Something changed for a page to show (a magic rule's proposal). */
  touch(ownerId: string): void {
    this.changed(ownerId);
  }

  /** The clock: the rules' times, and the windows read every few minutes. */
  async tick(now = this.now()): Promise<void> {
    const owners = await this.o.host.owners();
    for (const ownerId of owners) {
      for (const r of await this.list(ownerId)) {
        if (!r.enabled || r.when.event !== "schedule") continue;
        const key = `${r.id}\u0000${r.version}`;
        let at = this.next.get(key);
        if (at === undefined) {
          at = this.nextTime(r, now - 1);
          this.next.set(key, at);
        }
        if (at <= now) {
          this.next.set(key, this.nextTime(r, now));
          await this.act(ownerId, r, "schedule", {}, {});
        }
      }
    }
    if (now - this.lastUsage >= (this.o.usageEveryMs ?? USAGE_EVERY_MS)) {
      let wanted = false;
      for (const ownerId of owners)
        if ((await this.list(ownerId)).some((r) => r.enabled && r.when.event === "usage"))
          wanted = true;
      if (wanted) {
        this.lastUsage = now;
        const readings = await this.o.host.limits().catch(() => []);
        for (const ownerId of owners) await this.usage(ownerId, readings, now);
      }
    }
  }

  private recipe(r: Pick<RuleDraft, "when">): Recipe {
    return {
      on: { cron: r.when.cron, ...(r.when.timezone && { timezone: r.when.timezone }) },
    } as Recipe;
  }
  private nextTime(r: PersonRule, after: number): number {
    try {
      return nextRun(this.recipe(r), new Date(after))?.getTime() ?? Number.POSITIVE_INFINITY;
    } catch {
      return Number.POSITIVE_INFINITY;
    }
  }

  /** Starts the clock (once a minute). */
  start(): void {
    if (this.timer) return;
    this.timer = setInterval(() => {
      void this.tick().catch((err) => console.warn(`rules: ${(err as Error).message}`));
    }, 60_000);
    this.timer.unref?.();
  }
  /** Stops the clock and waits for what is acting. */
  async stop(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    this.timer = undefined;
    await this.settled();
  }
  /** Waits until the actions started so far are done (tests). */
  async settled(): Promise<void> {
    while (this.pending.size) await Promise.allSettled([...this.pending]);
  }
  private track(p: Promise<unknown>) {
    const q = p
      .catch((err) => console.warn(`rules: ${(err as Error).message}`))
      .finally(() => this.pending.delete(q));
    this.pending.add(q);
  }

  // ---------- Actions ----------

  /** What the event was, in a line for the person. */
  private what(ownerId: string, event: RuleEventKind, facts: RuleSample): string {
    if (event === "usage")
      return this.say(ownerId, "margin", {
        provider: facts.provider ?? "",
        window: facts.window ?? "",
        margin:
          typeof facts.marginPct === "number"
            ? `${facts.marginPct > 0 ? "+" : ""}${facts.marginPct}`
            : "?",
        used: facts.usedPct ?? "?",
      });
    if (event === "agent_done")
      return this.say(ownerId, "agentDone", {
        agent: facts.agent ?? "",
        stop: facts.stopReason ?? "",
      });
    if (event === "schedule") return this.say(ownerId, "time");
    // A webhook's body is data: never repeated to the person or to anyone as words to follow.
    if (event === "webhook") return this.say(ownerId, "webhook");
    if (event === "budget")
      return this.say(ownerId, "budget", { name: facts.budget ?? "", pct: facts.budgetPct ?? "?" });
    return this.say(ownerId, "tool", {
      tool: facts.tool ?? "",
      command: facts.command
        ? `: ${String(facts.command).slice(0, 200)}`
        : facts.path
          ? `: ${facts.path}`
          : "",
    });
  }

  /** Runs a rule's actions (ask and block are the caller's), and writes down what it did. */
  private async act(
    ownerId: string,
    rule: PersonRule,
    event: RuleEventKind,
    facts: RuleSample,
    where: { agentId?: string; projectId?: string | null },
    verdict?: "run" | "ask" | "block",
  ): Promise<void> {
    const fireId = `fire_${randomUUID().slice(0, 12)}`;
    const results: string[] = [];
    const what = this.what(ownerId, event, facts);
    for (const a of rule.actions) {
      try {
        switch (a.do) {
          case "notify": {
            const text = `${this.say(ownerId, "fired", { name: rule.name })}: ${a.text.trim() || what}`;
            const to = await this.o.host.notify(ownerId, text, a.to ?? ["page", "app", "chats"], {
              ruleId: rule.id,
              ruleName: rule.name,
              fireId,
            });
            results.push(to.length ? `notified: ${to.join(", ")}` : "notice not delivered");
            break;
          }
          case "ask":
          case "block":
            results.push(
              verdict === a.do ? (a.do === "ask" ? "asked the person" : "blocked") : a.do,
            );
            break;
          case "stop": {
            const h: RuleHold = {
              ruleId: rule.id,
              ruleName: rule.name,
              reason: a.text.trim() || what,
              at: new Date(this.now()).toISOString(),
              scope: a.scope,
              resume: a.resume,
              ...(a.scope === "project" && where.projectId && { projectId: where.projectId }),
              ...(a.scope === "agent" && where.agentId && { agentId: where.agentId }),
            };
            // A project's or an agent's stop without one to hold is everyone's: never less safe.
            if (h.scope !== "all" && !h.projectId && !h.agentId) h.scope = "all";
            await this.hold(ownerId, h);
            await this.o.host
              .notify(
                ownerId,
                this.say(ownerId, "stopped", { name: rule.name, reason: h.reason }),
                ["page", "app", "chats"],
                {
                  ruleId: rule.id,
                  ruleName: rule.name,
                  fireId,
                },
              )
              .catch(() => []);
            const cut = () =>
              this.holdsOf(ownerId).then((hs) =>
                hs.some((x) => x.ruleId === rule.id) ? this.o.host.interrupt(ownerId, h) : 0,
              );
            const grace = this.o.graceMs ?? GRACE_MS;
            if (grace <= 0) await cut();
            else setTimeout(() => this.track(cut()), grace).unref?.();
            results.push(`stopped (${h.scope})`);
            break;
          }
          case "tools_off":
            await this.o.host.toolsOff(ownerId, a.kits, a.tools);
            results.push(`switched off: ${[...a.kits, ...a.tools].join(", ")}`);
            break;
          case "automation":
            results.push(await this.o.host.runAutomation(ownerId, a.automation));
            break;
          case "command": {
            const r = await this.o.host.runCommand(ownerId, a.command, a.project, {
              id: rule.id,
              name: rule.name,
            });
            results.push(`command exited ${r.exitCode}`);
            break;
          }
        }
      } catch (err) {
        // An action that fails says so; it never turns into a yes for anything.
        results.push(`${a.do} failed: ${(err as Error).message}`);
      }
    }
    const at = new Date(this.now()).toISOString();
    await this.o.db.query(
      `INSERT INTO rg_person_rule_fires (id, owner_id, rule_id, rule_name, at, event, facts, results)
       VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::jsonb)`,
      [
        fireId,
        ownerId,
        rule.id,
        rule.name,
        at,
        event,
        JSON.stringify(facts),
        JSON.stringify(results),
      ],
    );
    // The time it last acted, without a new version (it is not a change of the rule).
    const now = (await this.list(ownerId)).find((r) => r.id === rule.id);
    if (now) {
      await this.o.db.query(
        "UPDATE rg_person_rules SET body = $3::jsonb WHERE id = $1 AND owner_id = $2",
        [rule.id, ownerId, JSON.stringify({ ...now, lastFiredAt: at })],
      );
      this.changed(ownerId);
    }
  }
}
