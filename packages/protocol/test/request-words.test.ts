import { describe, expect, it } from "vitest";
import {
  criticalSentences,
  dangerWords,
  PermissionRequestInfo,
  requestReasons,
  requestSentence,
  withRequestWords,
} from "../src/index.js";

const base: PermissionRequestInfo = {
  requestId: "r1",
  agentId: "a1",
  agentName: "Dev",
  projectId: "p1",
  tool: "bash",
  input: { command: "git push origin main" },
  reasons: ["git push needs a human"],
  danger: ["git-push"],
  createdAt: "2026-11-17T10:00:00.000Z",
  sessionId: "s1",
};

describe("withRequestWords (G42.1)", () => {
  it("says the request as the page does, in both languages", () => {
    const w = withRequestWords(base).words;
    for (const lang of ["it", "en"] as const) {
      expect(w?.[lang].what).toBe(requestSentence(lang, base.tool, base.input, base.names));
      expect(w?.[lang].reasons).toEqual(requestReasons(lang, base));
      expect(w?.[lang].critical).toEqual(criticalSentences(lang, base));
      expect(w?.[lang].dangers).toEqual([{ id: "git-push", ...dangerWords(lang, "git-push") }]);
    }
    expect(PermissionRequestInfo.parse(withRequestWords(base))).toEqual(withRequestWords(base));
  });

  it("makes the words again instead of keeping the ones carried", () => {
    const fake = { what: "x", reasons: [], critical: [], dangers: [] };
    const r = withRequestWords({ ...base, words: { it: fake, en: fake } });
    expect(r.words?.it.what).not.toBe("x");
  });

  it("gives a truly dangerous request its red sentences", () => {
    const r = withRequestWords({
      ...base,
      input: { command: "rm -rf /etc" },
      danger: ["critical-system"],
      critical: [{ id: "critical-system", action: "system-delete", target: "/etc" }],
    });
    expect(r.words?.it.critical.length).toBe(1);
    expect(r.words?.en.critical[0]).toBe(criticalSentences("en", r)[0]);
  });
});
