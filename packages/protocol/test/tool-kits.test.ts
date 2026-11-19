// Tools off by default, switched on by kits (3.9.4, decision «Strumenti spenti di serie, accesi a
// gruppi quando servono»): every entry of the catalog says its kit (essential ones none), and one
// pure rule says, for an agent, whether an entry is on from the start, off by default (the agent
// switches it on itself) or switched off by the person. The table is the rule.
import { describe, expect, it } from "vitest";
import {
  KIT_PROFILES,
  type KitState,
  kitDefault,
  kitOf,
  kitState,
  TOOL_CATALOG,
  TOOL_KITS,
  type ToolChoice,
  toolState,
  toolsAside,
} from "../src/index.js";

describe("the catalog's kits", () => {
  it("gives every entry but the essential ones a kit, and every kit an entry", () => {
    for (const e of TOOL_CATALOG) expect(e.essential === true, e.id).toBe(e.kit === undefined);
    for (const k of TOOL_KITS)
      expect(
        TOOL_CATALOG.some((e) => e.kit === k),
        k,
      ).toBe(true);
  });

  it("puts each tool in the kit a person would look for", () => {
    const table: [tool: string, kit: string | undefined][] = [
      ["read_file", undefined],
      ["bash", undefined],
      ["request_tool", undefined],
      ["complete_task", undefined],
      ["ask_god", undefined],
      ["glob", "core"],
      ["memory", "core"],
      ["web_search", "core"],
      ["send_file", "core"],
      ["image_generation", "images"],
      ["view_image", "images"],
      ["video_generation", "video"],
      ["audio_generation", "audio"],
      ["convert_file", "documents"],
      ["edit_package", "documents"],
      ["blender", "3d"],
      ["browser_click", "browser"],
      ["canvas_edit", "canvas"],
      ["publish_board", "present"],
      ["repo_pull_request", "git"],
      ["ssh_run", "machines"],
      ["node_run", "machines"],
      ["mail_send", "mail"],
      ["use_credential", "keychain"],
      ["propose_extension", "extensions"],
      ["create_agent", "team"],
      ["run_subagents", "helpers"],
      ["board_post", "helpers"],
      ["platform_code_start", "platform"],
      ["search_knowledge", "knowledge"],
      ["find_files", "computer"],
      ["mcp__github__x", undefined],
    ];
    for (const [tool, kit] of table) expect(kitOf(tool), tool).toBe(kit);
  });

  it("starts core on, the profile's kits on, the rest off by default", () => {
    expect(kitDefault("core")).toBe("on");
    expect(kitDefault("images")).toBe("auto");
    expect(kitDefault("team", "god")).toBe("on");
    expect(kitDefault("platform", "god")).toBe("on");
    expect(kitDefault("team", "orchestrator")).toBe("on");
    expect(kitDefault("team", "agent")).toBe("auto");
    // Who coordinates gets the helpers: sub-agents, the board, groups.
    expect(kitDefault("helpers", "orchestrator")).toBe("on");
    expect(kitDefault("helpers", "god")).toBe("on");
    expect(kitDefault("helpers", "agent")).toBe("auto");
    expect(KIT_PROFILES.agent).toBeUndefined();
  });
});

describe("toolState: on, off by default, or switched off by the person", () => {
  const choice: ToolChoice = {
    off: ["fetch", "blender"],
    agents: {
      a: { blender: "on", glob: "off" },
      parent: { canvas_edit: "on" },
    },
    kits: { images: "on", mail: "off", core: "auto" },
    agentKits: { a: { images: "off", "3d": "auto" }, parent: { video: "on" } },
  };
  type Row = [id: string, agent: string, kind: string | undefined, parent: string | null, KitState];
  const table: Row[] = [
    // Essential: always on, whatever the choice.
    ["read_file", "a", undefined, null, "on"],
    ["complete_task", "b", undefined, null, "on"],
    // The entry's own choice for the agent wins over everything.
    ["blender", "a", undefined, null, "on"],
    ["glob", "a", undefined, null, "off"],
    // A sub-agent follows the choice made for its parent, entry and kit.
    ["canvas_edit", "sub", "subagent", "parent", "on"],
    ["video_generation", "sub", "subagent", "parent", "on"],
    // The kit's own choice for the agent, then the entry off for everyone.
    ["image_generation", "a", undefined, null, "off"],
    ["fetch", "a", undefined, null, "off"],
    ["blender", "b", undefined, null, "off"],
    // The kit for everyone.
    ["image_generation", "b", undefined, null, "on"],
    ["mail_send", "b", undefined, null, "off"],
    ["glob", "b", undefined, null, "auto"],
    // Nothing chosen: the default, and the profile.
    ["browser_open", "b", undefined, null, "auto"],
    ["create_agent", "b", "agent", null, "auto"],
    ["create_agent", "g", "god", null, "on"],
    ["platform_status", "g", "god", null, "on"],
    ["create_agent", "o", "orchestrator", null, "on"],
    // Not in the catalog: on (MCP, custom and skill tools are the person's own choice elsewhere).
    ["mcp__x__y", "a", undefined, null, "on"],
  ];
  for (const [id, agent, kind, parent, want] of table)
    it(`${id} for ${agent}${kind ? ` (${kind})` : ""} is ${want}`, () => {
      expect(toolState(choice, id, { agentId: agent, kind, parentId: parent })).toBe(want);
    });

  it("splits a conversation's tools into those off and those off by default", () => {
    const names = ["read_file", "fetch", "glob", "image_generation", "browser_open", "mcp__x"];
    expect(toolsAside(choice, names, { agentId: "b" })).toEqual({
      off: ["fetch"],
      deferred: ["glob", "browser_open"],
    });
    // With nothing chosen, only the core kit and the essentials start on.
    expect(toolsAside({ off: [], agents: {} }, names, { agentId: "b" })).toEqual({
      off: [],
      deferred: ["image_generation", "browser_open"],
    });
  });

  it("says a kit's state for every agent and for one", () => {
    expect(kitState(choice, "images", null)).toBe("on");
    expect(kitState(choice, "images", { agentId: "a" })).toBe("off");
    expect(kitState(choice, "3d", { agentId: "a" })).toBe("auto");
    expect(kitState(choice, "team", { agentId: "g", kind: "god" })).toBe("on");
    expect(kitState(choice, "video", { agentId: "s", parentId: "parent" })).toBe("on");
  });
});
