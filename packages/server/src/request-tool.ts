// Switching tools on (G36.15; 3.9.4, decision «Strumenti spenti di serie, accesi a gruppi quando
// servono»). An agent starts with its essential tools, the core kit and the kits its profile or the
// person switched on; the others are listed in its instructions by kit, one short line each. With
// request_tool it switches on a whole kit (or one tool) the moment the work needs it: a kit off by
// default comes on at once, without asking the person; a tool the person switched off asks them, as
// an approval (on Telegram too), and only a yes switches it on: a no, an error or the time running
// out is a no. The tools join the running session at the end of its set (`session.tools_added`):
// a provider with deferred loading reads them from the result's references and keeps its cached
// prefix; another gets them at the end of its tool list (the prefix is rebuilt once). "Always for
// this agent" is also a configuration change in the history, undoable.
import type { Tool, ToolContext } from "@redgiant/agent";
import { isToolKit, kitOf, type ToolKit, toolCatalogEntry, toolEntryOf } from "@redgiant/protocol";
import { z } from "zod";

/** How long the person has to answer before it counts as a no. */
export const REQUEST_TOOL_TIMEOUT_MS = 15 * 60_000;

/** What each kit is for, in the agent's instructions (one line each). */
export const KIT_LINES: Readonly<Record<ToolKit, string>> = {
  core: "find and search files, a list of steps, memory, the web, showing and sending files",
  team: "make, read, stop, remove and restore agents; make projects; change an agent's model",
  helpers: "sub-agents, the inspector, assistants, group chats and the team board",
  platform: "the platform itself: settings, budgets, rules, automations, MCP servers, its code",
  knowledge: "the person's document collections: search them, make one, add sources",
  browser: "a real browser: open pages, click, type, read, screenshots",
  devices:
    "Android emulators and phones: open one, look at its screen, tap, type, install and launch apps, logs",
  canvas: "the person's canvas: look at it, act on it, edit an open file with them",
  present: "show what you made in the canvas, product cards, boards of variants to choose from",
  images: "make pictures, and look at image files",
  video: "make videos",
  audio: "make speech, music and sounds",
  documents:
    "convert closed formats (Office, PSD, Figma…) to open ones; edit ODF and EPUB packages",
  "3d": "Blender: 3D scenes and renders",
  computer: "find files and programs on this computer; a short program that chains many tool calls",
  machines: "the person's machines over SSH and their other nodes",
  git: "pull requests and issues on the project's repository",
  mail: "the person's mailboxes: search, read, draft, send, move",
  keychain: "use a stored credential; ask the person for a connection",
  extensions: "propose a new tool or skill",
};

/** The first sentence of a description, short. */
function firstLine(description: string): string {
  const s = description.split(/(?<=[.!?])\s/)[0] ?? description;
  return s.length > 90 ? `${s.slice(0, 87).trimEnd()}...` : s;
}

/** The catalog entries of some tools, each with the tools it stands for. */
function entries(tools: readonly Tool[]): Map<string, Tool[]> {
  const out = new Map<string, Tool[]>();
  for (const t of tools) {
    const id = toolEntryOf(t.def.name)?.id ?? t.def.name;
    out.set(id, [...(out.get(id) ?? []), t]);
  }
  return out;
}

/**
 * The system prompt's part on the tools it starts without: the kits off by default, each with its
 * tools and what it is for, and the tools the person switched off, by name with a short line. Fixed
 * when the conversation starts, like the rest of the system prompt.
 */
export function switchedOffSection(
  off: readonly string[],
  deferred: readonly string[],
  aside: readonly Tool[],
): string {
  const parts: string[] = [];
  if (deferred.length > 0) {
    const kits = new Map<ToolKit, string[]>();
    for (const n of deferred) {
      const k = kitOf(n);
      if (k) kits.set(k, [...(kits.get(k) ?? []), n]);
    }
    const lines = [...kits]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([k, ns]) => `- ${k}: ${KIT_LINES[k]} (${[...ns].sort().join(", ")})`);
    parts.push(
      `## More tools\nTo keep requests small you start with few tools. These groups are off until you need them:\n${lines.join("\n")}\nWhen the work needs one, switch it on with request_tool (the group's name and why): it is on from your next step, you do not ask the person. Switch on only what the work needs.`,
    );
  }
  if (off.length > 0) {
    const byEntry = entries(aside.filter((t) => off.includes(t.def.name)));
    const lines = [...byEntry]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([id, ts]) => `- ${id}: ${firstLine(ts[0]?.def.description ?? "")}`);
    parts.push(
      `## Tools switched off\nThese tools exist, but the person switched these tools off for you to keep requests small:\n${lines.join("\n")}\nIf the work really needs one, ask for it with request_tool (its name and why); do not work around it with other tools. Without the person's yes it stays off.`,
    );
  }
  return parts.join("\n\n");
}

export type ToolRequestAnswer =
  | { allow: false; reason?: string }
  | { allow: true; scope: "session" | "agent" };

export interface RequestToolHost {
  /** Asks the person; resolves to a no on error, timeout or abort. */
  ask(
    input: { entry: string; tools: string[]; why: string },
    ctx: ToolContext,
  ): Promise<ToolRequestAnswer>;
  /** "Always for this agent": the configuration change (history, undoable). */
  keepOn(entry: string): Promise<void>;
  /**
   * Adds the tools to this conversation (recorded first); returns the names the result must
   * reference (deferred loading).
   */
  add(
    tools: Tool[],
    payload: {
      entry: string;
      why: string;
      scope: "session" | "agent";
      by: "agent" | "person";
    },
  ): Promise<string[]>;
  /**
   * What the instructions would have said about these tools had they been on from the start (mail
   * is data, how to cite the collections…): it comes with the result, the prefix stays the same.
   */
  guidance?(names: string[]): Promise<string>;
}

const Input = z.object({ tool: z.string().min(1).max(100), why: z.string().min(1).max(1000) });

/** A host that is never asked: for weighing the tool's definition (the tools page). */
export const REQUEST_TOOL_DRY: RequestToolHost = {
  ask: async () => ({ allow: false }),
  keepOn: async () => {},
  add: async () => [],
};

/** What a request names among the tools kept aside: a tool, a catalog entry, or a kit. */
function wantedTools(name: string, aside: readonly Tool[]): { id: string; tools: Tool[] } {
  const byEntry = entries(aside);
  const entry = toolCatalogEntry(name)?.id ?? toolEntryOf(name)?.id ?? name;
  const one = byEntry.get(entry);
  if (one?.length) return { id: entry, tools: one };
  if (isToolKit(name)) return { id: name, tools: aside.filter((t) => kitOf(t.def.name) === name) };
  return { id: entry, tools: [] };
}

/**
 * request_tool for one conversation: `aside` are the tools it may still switch on (removed as they
 * come), `off` the names the person switched off (those ask them).
 */
export function requestTool(aside: Tool[], off: ReadonlySet<string>, host: RequestToolHost): Tool {
  return {
    def: {
      name: "request_tool",
      description:
        "Switch on tools you do not have yet: a whole group or one tool, as listed in your instructions, saying why the work needs it. A group that is off until needed comes on at once; a tool the person switched off waits for their answer.",
      inputSchema: {
        type: "object",
        properties: {
          tool: { type: "string", description: "a group's name or a tool's name, as listed" },
          why: { type: "string" },
        },
        required: ["tool", "why"],
      },
    },
    schema: Input,
    async run(i: z.infer<typeof Input>, ctx: ToolContext) {
      const { id: wanted, tools: group } = wantedTools(i.tool, aside);
      if (!group.length) {
        const kits = [...new Set(aside.flatMap((t) => kitOf(t.def.name) ?? []))].sort();
        const offIds = [...entries(aside.filter((t) => off.has(t.def.name))).keys()].sort();
        return {
          content:
            kits.length + offIds.length > 0
              ? `"${i.tool}" is not one of the tools you can switch on.${kits.length ? ` Groups: ${kits.join(", ")}.` : ""}${offIds.length ? ` Switched off by the person: ${offIds.join(", ")}.` : ""}`
              : "Every tool you can have is already on.",
          isError: true,
        };
      }
      const take = (ts: Tool[]) => {
        for (const t of ts) aside.splice(aside.indexOf(t), 1);
      };
      const free = group.filter((t) => !off.has(t.def.name));
      const asked = group.filter((t) => off.has(t.def.name));
      const refs: string[] = [];
      const said: string[] = [];
      // Off by default: on at once, the agent's own choice (recorded, the person sees it).
      if (free.length > 0) {
        take(free);
        refs.push(
          ...(await host.add(free, { entry: wanted, why: i.why, scope: "session", by: "agent" })),
        );
        said.push(
          `${wanted} is on (${free.map((t) => t.def.name).join(", ")}). You can use it from your next step.`,
        );
      }
      if (asked.length > 0) {
        let answer: ToolRequestAnswer;
        try {
          answer = await host.ask(
            { entry: wanted, tools: asked.map((t) => t.def.name), why: i.why },
            ctx,
          );
        } catch {
          answer = { allow: false };
        }
        if (!answer.allow)
          said.push(
            `The person did not switch ${wanted} on${answer.reason ? `: ${answer.reason}` : ""}. Carry on without it, or say plainly what you cannot do without it.`,
          );
        else {
          if (answer.scope === "agent") for (const e of entries(asked).keys()) await host.keepOn(e);
          take(asked);
          refs.push(
            ...(await host.add(asked, {
              entry: wanted,
              why: i.why,
              scope: answer.scope,
              by: "person",
            })),
          );
          said.push(
            `${wanted} is on (${asked.map((t) => t.def.name).join(", ")})${answer.scope === "agent" ? ", for this agent from now on" : ", for this conversation"}. You can use it from your next step.`,
          );
        }
      }
      const more =
        refs.length > 0 && host.guidance ? await host.guidance(refs).catch(() => "") : "";
      return {
        content: [...said, more].filter(Boolean).join("\n\n"),
        ...(refs.length > 0 && { refs }),
      };
    },
  } as Tool;
}
