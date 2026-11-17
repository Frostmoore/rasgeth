// @vitest-environment jsdom
// p3.8.9 (the person's Coder after a blackout: «not even the requests sync any more between the
// page and the app»): the server restarted, the requests waiting died with the old process, and
// the page kept showing them (the permissions until the next 15-second refresh, the questions for
// ever), so answering them did nothing. A new link starts from what the server sends again right
// after `welcome`. And the lists: what was made elsewhere is read at once (`lists.changed`).
import type { PermissionRequestInfo, QuestionRequestInfo } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";

const state = await import("../src/state.js");
const { applyMessage, approvals, questions } = state;

const permission = (id: string) =>
  ({
    requestId: id,
    sessionId: "s1",
    agentId: "a1",
    agentName: "Coder",
    tool: "bash",
    input: { command: "ls" },
    danger: "exec",
    createdAt: "2026-11-17T10:00:00.000Z",
  }) as unknown as PermissionRequestInfo;
const question = (id: string) =>
  ({
    requestId: id,
    sessionId: "s1",
    agentId: "a1",
    agentName: "Coder",
    questions: [{ question: "Sì?", options: [{ label: "Sì" }] }],
    createdAt: "2026-11-17T10:00:00.000Z",
  }) as unknown as QuestionRequestInfo;

describe("a new link after the server restarted (p3.8.9)", () => {
  it("drops the requests and questions of before, keeps what the server sends again", () => {
    applyMessage({ type: "permission.request", request: permission("old") });
    applyMessage({ type: "question.request", request: question("q-old") });
    expect(approvals.value.map((r) => r.requestId)).toEqual(["old"]);
    expect(questions.value.map((q) => q.requestId)).toEqual(["q-old"]);

    // The server came back: nothing waits there any more, then a new request comes.
    applyMessage({ type: "welcome", protocolVersion: 2, ownerId: "local" });
    expect(approvals.value).toEqual([]);
    expect(questions.value).toEqual([]);
    applyMessage({ type: "permission.request", request: permission("new") });
    expect(approvals.value.map((r) => r.requestId)).toEqual(["new"]);
    applyMessage({ type: "permission.closed", requestId: "new", decision: "allow", via: "app" });
    expect(approvals.value).toEqual([]);
  });

  it("a lists.changed without a signed-in page does nothing harmful", () => {
    expect(() =>
      applyMessage({ type: "lists.changed", lists: ["agents", "projects", "sessions"] }),
    ).not.toThrow();
  });
});
