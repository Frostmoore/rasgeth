// Notifications (G40.4): what is notified and what a notification offers, as tables.
import { describe, expect, it } from "vitest";
import {
  ARTIFACT_GRANT_TOOL,
  DeviceView,
  type PermissionRequestInfo,
  PUSH_BODY_MAX,
  PushRegisterBody,
  type PushTrigger,
  pushFor,
  pushTest,
  pushWithdrawal,
  type QuestionRequestInfo,
  quickActions,
  quickAnswerAllowed,
} from "../src/index.js";

const request = (o: Partial<PermissionRequestInfo> = {}): PermissionRequestInfo => ({
  requestId: "r1",
  agentId: "a1",
  agentName: "God",
  projectId: null,
  tool: "bash",
  input: { command: "git push origin main" },
  reasons: [],
  danger: [],
  createdAt: "2026-11-15T10:00:00.000Z",
  sessionId: "s1",
  ...o,
});
const critical = request({
  danger: ["critical-delete"],
  critical: [{ id: "critical-delete", action: "delete-forever", target: "/home" } as never],
});
const question: QuestionRequestInfo = {
  requestId: "q1",
  sessionId: "s1",
  agentId: "a1",
  agentName: "Chat",
  projectId: null,
  questions: [
    {
      question: "Quale colore preferisci?",
      options: [{ label: "Rosso" }, { label: "Blu" }],
      multiSelect: false,
    },
  ],
  createdAt: "2026-11-15T10:00:00.000Z",
};

describe("the quick answers of a request's notification", () => {
  const rows: [string, PermissionRequestInfo, ("allow" | "deny")[]][] = [
    ["an ordinary request", request(), ["allow", "deny"]],
    ["a humanOnly danger (a push) is ordinary", request({ danger: ["push"] }), ["allow", "deny"]],
    ["a truly dangerous request: no quick yes", critical, []],
    ["a critical danger id alone", request({ danger: ["critical-secret"] }), []],
    ["an artifact's capability needs its cap", request({ tool: ARTIFACT_GRANT_TOOL }), []],
  ];
  it.each(rows)("%s", (_n, info, want) => expect(quickActions(info)).toEqual(want));

  const answers: [string, PermissionRequestInfo, "allow" | "deny", boolean][] = [
    ["yes to an ordinary request", request(), "allow", true],
    ["no to an ordinary request", request(), "deny", true],
    ["yes to a critical one is refused", critical, "allow", false],
    ["no to a critical one is welcome", critical, "deny", true],
    ["yes to a capability is refused", request({ tool: ARTIFACT_GRANT_TOOL }), "allow", false],
  ];
  it.each(answers)("%s", (_n, info, d, want) => expect(quickAnswerAllowed(info, d)).toBe(want));
});

describe("what is notified", () => {
  const task = (o: Partial<Extract<PushTrigger, { type: "task" }>> = {}): PushTrigger => ({
    type: "task",
    taskId: "t1",
    title: "Prepara la relazione",
    outcome: "verified",
    sessionId: "s1",
    forPerson: true,
    escalated: false,
    ...o,
  });
  const message = (o: Partial<Extract<PushTrigger, { type: "message" }>> = {}): PushTrigger => ({
    type: "message",
    sessionId: "s1",
    agentName: "Chat",
    text: "Ecco il riassunto.",
    byPerson: true,
    watched: false,
    stopReason: "end_turn",
    ...o,
  });
  const rows: [string, PushTrigger, string | null][] = [
    ["a request", { type: "approval", info: request() }, "request"],
    ["a critical request", { type: "approval", info: critical }, "request"],
    ["a question", { type: "question", info: question }, "question"],
    ["a task of the person's agent, done", task(), "task"],
    ["a task given up", task({ outcome: "abandoned" }), "task"],
    ["a task between sub-agents", task({ forPerson: false }), null],
    ["a task handed to the backup model", task({ outcome: "abandoned", escalated: true }), null],
    ["an answer nobody is watching", message(), "message"],
    ["an answer the person is watching", message({ watched: true }), null],
    ["a turn nobody started (automation)", message({ byPerson: false }), null],
    ["a turn stopped by the person", message({ stopReason: "aborted" }), null],
    ["a turn that failed", message({ stopReason: "error" }), null],
    ["a turn without words", message({ text: "  " }), null],
  ];
  it.each(rows)("%s", (_n, t, kind) => expect(pushFor(t, "it", "Casa")?.kind ?? null).toBe(kind));

  it("a critical request is marked and offers no yes; an ordinary one does", () => {
    const c = pushFor({ type: "approval", info: critical }, "it", "Casa");
    expect(c).toMatchObject({ critical: true, actions: [], id: "req:r1", requestId: "r1" });
    const o = pushFor({ type: "approval", info: request() }, "en", "Casa");
    expect(o).toMatchObject({ actions: ["allow", "deny"], title: "God asks for permission" });
    expect(o?.critical).toBeUndefined();
    expect(o?.body).toMatch(/Pushes the commits to origin \(main\)/);
  });

  it("keeps the body short and on one line", () => {
    const long = pushFor(message({ text: `riga uno\n\n${"parola ".repeat(200)}` }), "it", "Casa");
    expect(long?.body.length).toBeLessThanOrEqual(PUSH_BODY_MAX);
    expect(long?.body).not.toMatch(/\n/);
    expect(long?.body.endsWith("…")).toBe(true);
  });

  it("names the RedGiant it comes from, in the person's language", () => {
    expect(pushFor(task(), "it", "Casa")).toMatchObject({
      server: "Casa",
      title: "Compito finito",
    });
    expect(pushFor(task(), "en", "Casa")?.title).toBe("Task done");
    expect(pushTest("it", "Casa", "x").body).toMatch(/Casa/);
  });

  it("withdraws with the same id as the request's notification", () => {
    const w = pushWithdrawal("r1", "app (Pixel 8)", "it", "Casa");
    expect(w.id).toBe(pushFor({ type: "approval", info: request() }, "it", "Casa")?.id);
    expect(w.closed).toEqual({ via: "app (Pixel 8)" });
  });
});

describe("registering a channel", () => {
  const keys = {
    p256dh:
      "BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4",
    auth: "BTBZMqHH6r4Tts7J_aSIgg",
  };
  const rows: [string, unknown, boolean][] = [
    ["a UnifiedPush endpoint", { kind: "webpush", endpoint: "https://ntfy.sh/up123", keys }, true],
    ["a local ntfy over http", { kind: "webpush", endpoint: "http://192.168.1.5/up1", keys }, true],
    ["not a web address", { kind: "webpush", endpoint: "file:///etc/passwd", keys }, false],
    ["no keys", { kind: "webpush", endpoint: "https://ntfy.sh/up123" }, false],
    ["an Apple token", { kind: "apns", token: "a".repeat(64), keys }, true],
    ["an Apple token that is not hex", { kind: "apns", token: "z".repeat(64), keys }, false],
    ["another kind", { kind: "fcm", token: "x" }, false],
  ];
  it.each(rows)("%s", (_n, body, ok) => expect(PushRegisterBody.safeParse(body).success).toBe(ok));

  it("defaults Apple to production and lists a device without a channel", () => {
    const p = PushRegisterBody.parse({ kind: "apns", token: "a".repeat(64), keys });
    expect(p.kind === "apns" && p.environment).toBe("production");
    const d = {
      id: "dev_1",
      name: "Pixel",
      platform: "android",
      createdAt: "x",
      lastUsedAt: null,
      lastAddress: null,
    };
    expect(DeviceView.safeParse({ ...d, push: null }).success).toBe(true);
  });
});
