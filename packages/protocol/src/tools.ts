// The tools page (G34.5, decision of 2026-11-07): the person switches the common tools off, for
// every agent or agent by agent. The catalog names what can be chosen (one tool, or a family that
// only makes sense together, like the browser's); the tools a mechanism needs are essential and
// never switch off. What is off is computed when a conversation starts and stays fixed in it.
//
// Tools off by default, switched on by groups (3.9.4, decision «Strumenti spenti di serie, accesi a
// gruppi quando servono»): every other entry belongs to a kit. The `core` kit starts on; the others
// start "off by default" (`auto`): the agent switches one on itself with request_tool when the work
// needs it, without asking the person. A kit the person switched off asks them, as before; one they
// switched on is there from the start. An agent's profile (its kind) starts some kits on.
import { z } from "zod";

export const TOOL_GROUPS = [
  "files",
  "web",
  "memory",
  "credentials",
  "canvas",
  "mail",
  "talk",
  "agents",
  "platform",
] as const;
export type ToolGroup = (typeof TOOL_GROUPS)[number];

/** The kits the agents switch on when they need them, in the page's order. */
export const TOOL_KITS = [
  "core",
  "team",
  "helpers",
  "platform",
  "knowledge",
  "browser",
  "canvas",
  "present",
  "images",
  "video",
  "audio",
  "documents",
  "3d",
  "computer",
  "machines",
  "git",
  "mail",
  "keychain",
  "extensions",
] as const;
export type ToolKit = (typeof TOOL_KITS)[number];

/** A kit's state: on from the start, off by default (the agent switches it on), off by the person. */
export const KitState = z.enum(["on", "auto", "off"]);
export type KitState = z.infer<typeof KitState>;

/** The kits an agent's profile starts on (its kind): what its role cannot do without. */
export const KIT_PROFILES: Readonly<Record<string, readonly ToolKit[]>> = {
  god: ["team", "helpers", "platform"],
  orchestrator: ["team", "helpers"],
};

export interface ToolCatalogEntry {
  /** What the person switches: a tool's name, or a family's id. */
  id: string;
  group: ToolGroup;
  /** The tools it stands for (a family: every name starting with `prefix`). */
  tools?: readonly string[];
  prefix?: string;
  /** Never switched off: the mechanism that needs it (an i18n key's suffix). */
  essential?: boolean;
  /** The kit it comes with (every entry but the essential ones). */
  kit?: ToolKit;
}

const one = (id: string, group: ToolGroup, kit: ToolKit | true): ToolCatalogEntry => ({
  id,
  group,
  ...(kit === true ? { essential: true } : { kit }),
});

/** Every built-in tool an agent can get, in the page's order. MCP, custom and skill tools are not here. */
export const TOOL_CATALOG: readonly ToolCatalogEntry[] = [
  // The base of working on files: an agent that works in a project cannot do without them.
  one("read_file", "files", true),
  one("write_file", "files", true),
  one("edit_file", "files", true),
  one("bash", "files", true),
  // Background commands (p3.3.1) are part of bash: reading and stopping them goes with it.
  one("bash_output", "files", true),
  one("glob", "files", "core"),
  one("grep", "files", "core"),
  // Finding files and programs on the computer (p3.4.0): not essential, like glob and grep.
  one("find_files", "files", "computer"),
  one("update_todos", "files", "core"),
  one("run_script", "files", "computer"),
  one("convert_file", "files", "documents"),
  one("edit_package", "files", "documents"),
  one("blender", "files", "3d"),
  { id: "repo", group: "files", prefix: "repo_", kit: "git" },
  // The person's machines over SSH (G38.2): commands, copies, folders and files there.
  { id: "ssh", group: "files", prefix: "ssh_", kit: "machines" },
  // The person's nodes (G39.4): commands in a sandbox on another RedGiant, and how they are.
  { id: "node", group: "files", prefix: "node_", kit: "machines" },
  one("fetch", "web", "core"),
  one("web_search", "web", "core"),
  { id: "browser", group: "web", prefix: "browser_", kit: "browser" },
  one("memory", "memory", "core"),
  // The person's documents (G36.5): only the collections the agent may read.
  one("search_knowledge", "memory", "knowledge"),
  // Making collections and adding their sources, and their state (3.5.3, decision «Gli agenti
  // possono creare tutto da sé»): what the person does on the Knowledge page.
  one("knowledge_create", "memory", "knowledge"),
  one("knowledge_add_source", "memory", "knowledge"),
  one("knowledge_status", "memory", "knowledge"),
  // After a summary the details of the conversation are only reachable through it.
  one("conversation_history", "memory", true),
  // Echo (3.9.6): past conversations the agent may see, searched by their words. In the core
  // kit (on from the start: an agent looks back without asking) but not essential (the person
  // may not want agents to look at old conversations).
  one("search_conversations", "memory", "core"),
  one("use_credential", "credentials", "keychain"),
  one("request_connection", "credentials", "keychain"),
  one("show_file", "canvas", "core"),
  // Looking at the person's canvas and leafing through it (G36.12).
  one("canvas_look", "canvas", "canvas"),
  one("canvas_act", "canvas", "canvas"),
  // Editing an open file with the person (G37.1). Not essential: write_file and edit_file stay the
  // way to change files; this one is the shared editor's (visible, undoable, the person's lead).
  one("canvas_edit", "canvas", "canvas"),
  one("show", "canvas", "present"),
  one("view_image", "canvas", "images"),
  one("send_file", "canvas", "core"),
  // Product cards with pictures (G40.16): things to buy or compare, in a carousel.
  one("show_products", "canvas", "present"),
  one("publish_board", "canvas", "present"),
  one("image_generation", "canvas", "images"),
  one("video_generation", "canvas", "video"),
  one("audio_generation", "canvas", "audio"),
  // Email (G38.1): the mailboxes the person opened to the agents; sending always asks them.
  one("mail_search", "mail", "mail"),
  one("mail_read", "mail", "mail"),
  one("mail_draft", "mail", "mail"),
  one("mail_send", "mail", "mail"),
  one("mail_move", "mail", "mail"),
  // Questions and plans: plan mode ends only through propose_plan.
  one("ask_user", "talk", true),
  // A switched-off tool comes back only through the person (G36.15): the way to ask must stay.
  one("request_tool", "talk", true),
  one("propose_plan", "talk", true),
  // Demi-God's one tool.
  one("ask_god", "talk", true),
  { id: "board", group: "talk", prefix: "board_", kit: "helpers" },
  one("ask_assistant", "talk", "helpers"),
  one("ask_group", "talk", "helpers"),
  one("propose_extension", "talk", "extensions"),
  // Tasks (RD17): opened by delegate, closed only by complete_task; merge_work brings the work in.
  one("delegate", "agents", true),
  one("complete_task", "agents", true),
  one("merge_work", "agents", true),
  one("create_agent", "agents", "team"),
  // Another agent's model, on the person's request and with their yes (G38.9).
  one("set_agent_model", "agents", "team"),
  one("create_project", "agents", "team"),
  one("list_agents", "agents", "team"),
  one("read_agent", "agents", "team"),
  one("stop_agent", "agents", "team"),
  // Removing an agent from the team, and bringing it back (p3.8.9): nothing of its history goes.
  one("remove_agent", "agents", "team"),
  one("restore_agent", "agents", "team"),
  // A stopped agent is paused: resuming it lets its open tasks go on (p3.8.9).
  one("resume_agent", "agents", "team"),
  { id: "subagents", group: "agents", tools: ["run_subagent", "run_subagents"], kit: "helpers" },
  one("ask_inspector", "agents", "helpers"),
  // A magic automation's conversation exists to propose one.
  one("propose_automation", "platform", true),
  // A magic integration's or extension's conversation exists to propose one (G38.3).
  one("propose_magic_extension", "platform", true),
  one("platform_status", "platform", "platform"),
  one("platform_changes", "platform", "platform"),
  one("platform_configure_agent", "platform", "platform"),
  one("platform_set_budget", "platform", "platform"),
  one("platform_policy", "platform", "platform"),
  one("platform_automation", "platform", "platform"),
  one("platform_mcp", "platform", "platform"),
  one("platform_undo", "platform", "platform"),
  // Archiving and restoring a whole project (3.5.3), with the person's yes.
  one("platform_project", "platform", "platform"),
  { id: "platform_code", group: "platform", prefix: "platform_code_", kit: "platform" },
];

const BY_ID = new Map(TOOL_CATALOG.map((e) => [e.id, e]));

/** The catalog entry a tool belongs to; none for MCP, custom and skill tools. */
export function toolEntryOf(name: string): ToolCatalogEntry | undefined {
  const own = BY_ID.get(name);
  if (own && !own.prefix && !own.tools) return own;
  return TOOL_CATALOG.find(
    (e) => e.tools?.includes(name) || (e.prefix !== undefined && name.startsWith(e.prefix)),
  );
}

export const toolCatalogEntry = (id: string) => BY_ID.get(id);

/** An agent's own choice for one entry: on even if off for everyone, or off. */
export const AgentToolState = z.enum(["on", "off"]);
export type AgentToolState = z.infer<typeof AgentToolState>;

/**
 * What the person chose: entries off for every agent, and each agent's exceptions; kits for every
 * agent and for each agent (3.9.4). A kit not chosen follows its default (`kitDefault`).
 */
export const ToolChoice = z.object({
  off: z.array(z.string()).default([]),
  agents: z.record(z.string(), z.record(z.string(), AgentToolState)).default({}),
  kits: z.record(z.string(), KitState).optional(),
  agentKits: z.record(z.string(), z.record(z.string(), KitState)).optional(),
});
export type ToolChoice = z.infer<typeof ToolChoice>;

export const EMPTY_TOOL_CHOICE: ToolChoice = { off: [], agents: {} };

/** Ids the choice cannot hold: unknown, or essential (never off). */
export function invalidToolIds(ids: readonly string[]): { unknown: string[]; essential: string[] } {
  const unknown = ids.filter((id) => !BY_ID.has(id));
  const essential = ids.filter((id) => BY_ID.get(id)?.essential === true);
  return { unknown, essential };
}

/** Kit ids that are not kits. */
export const invalidKitIds = (ids: readonly string[]) =>
  ids.filter((id) => !(TOOL_KITS as readonly string[]).includes(id));

export const isToolKit = (id: string): id is ToolKit =>
  (TOOL_KITS as readonly string[]).includes(id);

/** Who the state is for: the agent, the agent it works for (a sub-agent), and its kind. */
export interface ToolStateFor {
  agentId: string;
  parentId?: string | null | undefined;
  kind?: string | undefined;
}

/** A kit's state when the person chose nothing: `core` and the profile's kits on, the rest auto. */
export function kitDefault(kit: ToolKit, kind?: string): KitState {
  if (kit === "core") return "on";
  return kind && KIT_PROFILES[kind]?.includes(kit) ? "on" : "auto";
}

/** A kit's state for an agent (or for every agent, with `agentId` null): own choice, everyone's, default. */
export function kitState(choice: ToolChoice, kit: ToolKit, who: ToolStateFor | null): KitState {
  const own = who
    ? (choice.agentKits?.[who.agentId]?.[kit] ??
      (who.parentId ? choice.agentKits?.[who.parentId]?.[kit] : undefined))
    : undefined;
  return own ?? choice.kits?.[kit] ?? kitDefault(kit, who?.kind);
}

/**
 * Whether an entry is on for an agent, off by default (the agent may switch it on) or switched off by
 * the person. The rule, most specific first: the entry's own choice for the agent (or the agent it
 * works for: a sub-agent is made per run and has no choice of its own, 3.5.3), the kit's choice for
 * the agent, the entry switched off for everyone, the kit's choice for everyone, then the default.
 */
export function toolState(choice: ToolChoice, id: string, who: ToolStateFor): KitState {
  // An entry's id, or one of its tools' names.
  const e = BY_ID.get(id) ?? toolEntryOf(id);
  if (!e || e.essential || !e.kit) return "on";
  const own =
    choice.agents[who.agentId]?.[e.id] ??
    (who.parentId ? choice.agents[who.parentId]?.[e.id] : undefined);
  if (own) return own;
  const ownKit =
    choice.agentKits?.[who.agentId]?.[e.kit] ??
    (who.parentId ? choice.agentKits?.[who.parentId]?.[e.kit] : undefined);
  if (ownKit) return ownKit;
  if (choice.off.includes(e.id)) return "off";
  return choice.kits?.[e.kit] ?? kitDefault(e.kit, who.kind);
}

/**
 * Whether an entry is on for an agent from the start of its conversations (see `toolState`).
 */
export function toolEntryOn(
  choice: ToolChoice,
  agentId: string,
  id: string,
  parentId?: string | null,
  kind?: string,
): boolean {
  return toolState(choice, id, { agentId, parentId, kind }) === "on";
}

/**
 * The tools of `names` an agent does not start with: `off` those the person switched off (asking
 * them is needed), `deferred` those off by default (the agent switches them on itself). Essential
 * tools and tools outside the catalog (MCP, custom, skills) are never in either.
 */
export function toolsAside(
  choice: ToolChoice,
  names: readonly string[],
  who: ToolStateFor,
): { off: string[]; deferred: string[] } {
  const off: string[] = [];
  const deferred: string[] = [];
  for (const n of names) {
    const e = toolEntryOf(n);
    if (!e) continue;
    const st = toolState(choice, e.id, who);
    if (st === "off") off.push(n);
    else if (st === "auto") deferred.push(n);
  }
  return { off, deferred };
}

/** The tools of `names` the person switched off for an agent (see `toolsAside`). */
export function toolsSwitchedOff(
  choice: ToolChoice,
  agentId: string,
  names: readonly string[],
  parentId?: string | null,
  kind?: string,
): string[] {
  return toolsAside(choice, names, { agentId, parentId, kind }).off;
}

/** The kit a tool comes with; none for essential tools and tools outside the catalog. */
export const kitOf = (name: string): ToolKit | undefined => toolEntryOf(name)?.kit;

/** One entry on the page: what it weighs on every request, and how it is set. */
export interface ToolView {
  id: string;
  group: ToolGroup;
  essential: boolean;
  /** The kit it comes with (none for essential entries). */
  kit?: ToolKit;
  /** Its state: for every agent, or for the agent of the view (3.9.4). */
  state: KitState;
  /** The tools it stands for, as the model sees them. */
  tools: string[];
  /** Characters of names, descriptions and schemas, and the tokens they make (about 3.5 a token). */
  chars: number;
  tokens: number;
  /** On for every agent. */
  global: boolean;
  /** The agent's own choice (only in an agent's view). */
  own?: AgentToolState | null;
  /** What the agent gets (only in an agent's view). */
  on?: boolean;
  /**
   * In the view for every agent: the agents whose own choice differs from the rule for everyone
   * (3.5.3: an agent kept a switched-off tool on through its own choice, and the page did not say).
   */
  exceptions?: { agentId: string; name: string; state: AgentToolState }[];
}

/** One kit on the page (3.9.4): what it weighs, its state and how it was chosen. */
export interface KitView {
  id: ToolKit;
  /** Entries of the kit some agent has. */
  entries: string[];
  tokens: number;
  /** For every agent, or for the agent of the view. */
  state: KitState;
  /** What the state is without a choice (the kit's default, or the agent's profile). */
  default: KitState;
  /** The choice that sets it: the agent's own (agent view), everyone's, or none. */
  own: KitState | null;
  /** For an agent's view: the choice for every agent. */
  global?: KitState | null;
}

export interface ToolsView {
  /** The agent this view is about; none for the page of every agent. */
  agentId: string | null;
  entries: ToolView[];
  kits: KitView[];
  /** Tokens on every request with what is on from the start, and what the rest saves. */
  total: number;
  saved: number;
  /** Tokens of the essential tools alone (never off). */
  essential?: number;
}

/** Tokens from characters, as the summaries count them. */
export const toolTokens = (chars: number) => Math.ceil(chars / 3.5);
