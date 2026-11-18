// Notifications from the server (G40.4, 3.8): a device (its token of G40.1) registers where its
// notifications go: UnifiedPush / Web Push (an endpoint and the device's keys, RFC 8291) or
// APNs (Apple's device token, with a key pair the device made: the content is sealed for it and
// crosses a blind relay). A notification is one more channel of the requests «all at once»
// (G36.17): the first answer withdraws it. What is notified, and what the notification offers,
// are pure rules here, tested as tables.
import { z } from "zod";
import { ARTIFACT_GRANT_TOOL } from "./artifact-bridge.js";
import { criticalTitle, isCriticalRequest } from "./critical.js";
import type { QuestionRequestInfo } from "./questions.js";
import { requestSentence } from "./requests.js";
import type { PermissionRequestInfo } from "./wire.js";

/** The device's keys (base64url): a P-256 public key (65 bytes) and a 16-byte secret. */
export const PushKeys = z.object({
  p256dh: z.string().regex(/^[A-Za-z0-9_-]{86,88}={0,2}$/),
  auth: z.string().regex(/^[A-Za-z0-9_-]{21,24}={0,2}$/),
});
export type PushKeys = z.infer<typeof PushKeys>;

/** `PUT /api/devices/:id/push`: where this device's notifications go. */
export const PushRegisterBody = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("webpush"),
    /** The UnifiedPush distributor's endpoint (ntfy, the person's own ntfy, Sunup…). */
    endpoint: z
      .string()
      .max(2000)
      .refine((s) => /^https?:\/\/[^\s]+$/.test(s) && URL.canParse(s), "an http(s) address"),
    keys: PushKeys,
  }),
  z.object({
    kind: z.literal("apns"),
    /** Apple's device token (hex). */
    token: z.string().regex(/^[0-9a-fA-F]{64,200}$/),
    /** The device's own key pair: the relay and Apple see only what is sealed for it. */
    keys: PushKeys,
    /** A development build talks to APNs' sandbox. */
    environment: z.enum(["production", "sandbox"]).default("production"),
  }),
]);
export type PushRegisterBody = z.input<typeof PushRegisterBody>;
export type PushKind = PushRegisterBody["kind"];

/** A device's notifications as Settings › Devices shows them (never keys nor tokens). */
export const PushChannelView = z.object({
  kind: z.enum(["webpush", "apns"]),
  registeredAt: z.string(),
  /** Where they go: the endpoint's host (Web Push), "APNs" otherwise. */
  target: z.string(),
  lastSentAt: z.string().nullable(),
  /** The last failure, in English (a status, a timeout), cleared by the next success. */
  lastError: z.string().nullable(),
  /**
   * Why nothing can be sent now: APNs is ready but switched off until the app is published
   * (no relay), or the keychain is locked (the VAPID keys live there).
   */
  blocked: z.enum(["relay_off", "keychain_locked"]).optional(),
});
export type PushChannelView = z.infer<typeof PushChannelView>;

/** `POST /api/app/requests/:id/answer`: a notification's quick answer, from the device. */
export const PushAnswerBody = z.object({ decision: z.enum(["allow", "deny"]) });

/** What reaches the device, encrypted (version 1). Short: the app opens the rest. */
export const PushNotice = z.object({
  v: z.literal(1),
  /** The same id for the update that withdraws it. */
  id: z.string(),
  kind: z.enum(["request", "question", "task", "message", "automation", "test"]),
  /** Which RedGiant it comes from (the machine's name). */
  server: z.string(),
  title: z.string(),
  body: z.string(),
  sessionId: z.string().optional(),
  requestId: z.string().optional(),
  /** The quick answers it offers: never «allow» for a truly dangerous request. */
  actions: z.array(z.enum(["allow", "deny"])).optional(),
  critical: z.boolean().optional(),
  /** The update that withdraws it: answered (where), or no longer needed. */
  closed: z.object({ via: z.string().optional() }).optional(),
});
export type PushNotice = z.infer<typeof PushNotice>;

// --- The rules ------------------------------------------------------------------------------

/** The longest title and body a notification carries (the app shows the rest when opened). */
export const PUSH_TITLE_MAX = 80;
export const PUSH_BODY_MAX = 180;

const clip = (s: string, n: number) => {
  const one = s.replace(/\s+/g, " ").trim();
  return one.length > n ? `${one.slice(0, n - 1).trimEnd()}…` : one;
};
const it = (lang: string) => lang.toLowerCase().startsWith("it");

/** What may be notified, as the server sees it happen. */
export type PushTrigger =
  | { type: "approval"; info: PermissionRequestInfo }
  | { type: "question"; info: QuestionRequestInfo }
  | {
      type: "task";
      taskId: string;
      title: string;
      outcome: "verified" | "not_testable" | "abandoned";
      /** The conversation it goes back to. */
      sessionId?: string | undefined;
      /** Handed over by one of the person's own agents (no parent agent): theirs to know. */
      forPerson: boolean;
      /** Given up and handed to the backup model: its own end is notified, not this one. */
      escalated: boolean;
    }
  | {
      type: "message";
      sessionId: string;
      agentName: string;
      /** The agent's last words in the turn. */
      text: string;
      /** The person started the turn (not an automation, a task, another agent). */
      byPerson: boolean;
      /** A page or an app has this conversation open now. */
      watched: boolean;
      stopReason: string;
    }
  | {
      /** An automation's message for the person (`notify.to: [web]`) no page or app showed (G42.9). */
      type: "automation";
      automationId: string;
      runId: string;
      name: string;
      status: string;
      sessionId: string | null;
      text: string;
    };

/** The quick answers a request's notification offers. */
export function quickActions(info: PermissionRequestInfo): ("allow" | "deny")[] {
  // A truly dangerous request opens its full screen; a capability needs its cap chosen (G38.7).
  if (isCriticalRequest(info) || info.tool === ARTIFACT_GRANT_TOOL) return [];
  return ["allow", "deny"];
}

/** Whether a quick answer from a notification may decide this request. */
export function quickAnswerAllowed(info: PermissionRequestInfo, decision: "allow" | "deny") {
  // A no is always welcome (the safe side); a yes only where the notification offered one.
  return decision === "deny" || quickActions(info).includes("allow");
}

/**
 * What a notification says, or null when this is not notified. `server` names the RedGiant.
 * The id is stable per thing, so the update that withdraws it replaces it.
 */
export function pushFor(t: PushTrigger, lang: string, server: string): PushNotice | null {
  const base = { v: 1 as const, server };
  switch (t.type) {
    case "approval": {
      const critical = isCriticalRequest(t.info);
      const what = requestSentence(lang, t.info.tool, t.info.input, t.info.names);
      return {
        ...base,
        id: `req:${t.info.requestId}`,
        kind: "request",
        title: clip(
          critical
            ? criticalTitle(lang)
            : it(lang)
              ? `${t.info.agentName} chiede il permesso`
              : `${t.info.agentName} asks for permission`,
          PUSH_TITLE_MAX,
        ),
        body: clip(what, PUSH_BODY_MAX),
        requestId: t.info.requestId,
        ...(t.info.sessionId && { sessionId: t.info.sessionId }),
        actions: quickActions(t.info),
        ...(critical && { critical: true }),
      };
    }
    case "question":
      return {
        ...base,
        id: `req:${t.info.requestId}`,
        kind: "question",
        title: clip(
          it(lang) ? `${t.info.agentName} ti chiede` : `${t.info.agentName} asks you`,
          PUSH_TITLE_MAX,
        ),
        body: clip(t.info.questions[0]?.question ?? "", PUSH_BODY_MAX),
        requestId: t.info.requestId,
        sessionId: t.info.sessionId,
      };
    case "task": {
      if (!t.forPerson || t.escalated) return null;
      const done =
        t.outcome === "abandoned"
          ? it(lang)
            ? "Compito non riuscito"
            : "Task not completed"
          : it(lang)
            ? "Compito finito"
            : "Task done";
      return {
        ...base,
        id: `task:${t.taskId}`,
        kind: "task",
        title: done,
        body: clip(t.title, PUSH_BODY_MAX),
        ...(t.sessionId && { sessionId: t.sessionId }),
      };
    }
    case "message": {
      if (!t.byPerson || t.watched || !t.text.trim()) return null;
      // Stopped by the person, or failed: the page says why, nothing to tell.
      if (t.stopReason === "aborted" || t.stopReason === "error") return null;
      return {
        ...base,
        id: `msg:${t.sessionId}`,
        kind: "message",
        title: clip(t.agentName, PUSH_TITLE_MAX),
        body: clip(t.text, PUSH_BODY_MAX),
        sessionId: t.sessionId,
      };
    }
    case "automation": {
      if (!t.text.trim()) return null;
      const failed = t.status !== "ok";
      return {
        ...base,
        id: `auto:${t.runId}`,
        kind: "automation",
        title: clip(
          failed ? `${t.name}: ${it(lang) ? "non riuscita" : "not done"}` : t.name,
          PUSH_TITLE_MAX,
        ),
        body: clip(t.text, PUSH_BODY_MAX),
        ...(t.sessionId && { sessionId: t.sessionId }),
      };
    }
  }
}

/** The update that withdraws a notification (the first answer came from anywhere). */
export function pushWithdrawal(
  requestId: string,
  via: string | undefined,
  lang: string,
  server: string,
): PushNotice {
  return {
    v: 1,
    server,
    id: `req:${requestId}`,
    kind: "request",
    title: it(lang) ? "Richiesta chiusa" : "Request closed",
    body: it(lang) ? "Già risposta" : "Already answered",
    requestId,
    closed: { ...(via && { via }) },
  };
}

/** The test sent from Settings › Devices. */
export function pushTest(lang: string, server: string, at: string): PushNotice {
  return {
    v: 1,
    server,
    id: `test:${at}`,
    kind: "test",
    title: it(lang) ? "Prova delle notifiche" : "Notification test",
    body: it(lang)
      ? `Le notifiche di ${server} arrivano su questo dispositivo.`
      : `Notifications from ${server} reach this device.`,
  };
}
