// What a model does by itself (2026-11-19): one table by provider, and the way chosen for a
// conversation. Change the table first.
import { describe, expect, it } from "vitest";
import {
  CAPABILITIES,
  type Capability,
  type CapabilityWay,
  capabilityWay,
  NATIVE_CAPABILITIES,
  nativeToolNote,
  OUR_TOOL,
  sessionNative,
} from "../src/capabilities.js";

describe("the capability table", () => {
  it("says what each engine does by itself", () => {
    expect(NATIVE_CAPABILITIES).toEqual({
      "chatgpt-subscription": ["image", "web_search"],
      "claude-subscription": ["web_search"],
      anthropic: ["web_search"],
    });
    expect(Object.keys(OUR_TOOL).sort()).toEqual([...CAPABILITIES].sort());
  });

  // provider, capability, preferNative, ours → way
  const TABLE: [string, Capability, boolean, boolean, CapabilityWay][] = [
    // Codex draws by itself unless the person switched the model's tool off.
    ["chatgpt-subscription", "image", true, true, "native"],
    ["chatgpt-subscription", "image", false, true, "ours"],
    ["chatgpt-subscription", "image", false, false, "none"],
    ["chatgpt-subscription", "image", true, false, "native"],
    // Nobody's engine makes videos or sounds: ours, or nothing.
    ["chatgpt-subscription", "video", true, true, "ours"],
    ["chatgpt-subscription", "audio", true, false, "none"],
    ["claude-subscription", "image", true, true, "ours"],
    // Web search stays the engine's when it has one (the setting covers generation only).
    ["chatgpt-subscription", "web_search", false, true, "native"],
    ["claude-subscription", "web_search", true, true, "native"],
    ["anthropic", "web_search", false, false, "native"],
    // Any other provider: our tools.
    ["openai", "image", true, true, "ours"],
    ["openai", "web_search", true, true, "ours"],
    ["local", "image", true, false, "none"],
  ];
  it.each(TABLE)("%s %s (prefer native %s, ours %s): %s", (p, c, preferNative, ours, way) => {
    expect(capabilityWay(p, c, { preferNative, ours })).toBe(way);
  });

  // provider, preferNative, recorded at the start → native for the conversation
  const SESSION: [string, boolean, string[] | undefined, Capability[]][] = [
    ["chatgpt-subscription", true, undefined, ["image"]],
    ["chatgpt-subscription", false, undefined, []],
    // Resumed: the start's record wins over the setting now…
    ["chatgpt-subscription", false, ["image"], ["image"]],
    ["chatgpt-subscription", true, [], []],
    // …but only where the provider (changed since, perhaps) can still do it.
    ["openai", true, ["image"], []],
    ["claude-subscription", true, ["image"], []],
    ["claude-subscription", true, undefined, []],
  ];
  it.each(SESSION)("a conversation on %s (prefer %s, recorded %j): %j", (p, pref, rec, out) => {
    expect(sessionNative(p, pref, rec)).toEqual(out);
  });

  it("tells the model to use its own tool unless the person asks for ours", () => {
    expect(nativeToolNote("image")).toMatch(/makes pictures by itself/);
    expect(nativeToolNote("image")).toMatch(/only when the person asks for it by name/);
    expect(nativeToolNote("video")).toMatch(/videos/);
  });
});
