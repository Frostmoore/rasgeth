// «Oggi»'s stage (3.12.1, tavole-mascotte-chat/luna.html): God's mascot, giant, at the centre
// above the greeting. Its mood follows what really happens (`giantMood` in state.ts) and, still,
// it makes a small gesture now and then, never the same twice in a row. With reduced motion it
// stays still.
import { mascotSpec, mascotSvg, SATELLITE_SEED } from "@redgiant/mascot";
import type { MascotSpec, MascotState } from "@redgiant/protocol";
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { reducedMotion } from "../a11y.js";
import type { Agent } from "../api.js";
import { t } from "../i18n.js";
import { agentMascotState } from "../mascot-state.js";
import {
  agents,
  approvals,
  chatAgentId,
  chatSending,
  GESTURE_MS,
  GIANT_STATE,
  type GiantMood,
  gestureDelay,
  giantCheer,
  giantMood,
  godRouting,
  IDLE_GESTURES,
  type IdleGesture,
  lastError,
  nextGesture,
  ORBIT_BACK,
  orbitPlace,
  questions,
  type StageFront,
  simpleTyping,
  stageFront,
  topics,
  topicsTrouble,
} from "../state.js";
import { addMascotMotion, specOf } from "./Mascot.js";

/** God's own agent, when the registry has come. */
export const godAgent = (): Agent | undefined => agents.value.find((a) => a.kind === "god");

/** God's mood on «Oggi», from the page's real facts. */
export function godMood(): GiantMood {
  const god = godAgent();
  const live: MascotState = god ? agentMascotState(god.id) : "idle";
  const list = topics.value;
  return giantMood({
    typing: simpleTyping.value && stageFront.value === "god",
    routing: godRouting.value || live === "think",
    working: live === "work" || list.some((x) => x.state === "working"),
    waiting:
      live === "wait" ||
      approvals.value.length + questions.value.length > 0 ||
      list.some((x) => x.state === "waiting"),
    happy: giantCheer.value,
    error: lastError.value !== null || topicsTrouble.value !== null || live === "error",
  });
}

/** A still mascot's gestures: a different one now and then, only while [still]. */
export function useIdleGesture(still: boolean, from: readonly IdleGesture[]): IdleGesture | null {
  const [gesture, setGesture] = useState<IdleGesture | null>(null);
  useEffect(() => {
    if (!still || reducedMotion()) return;
    let last: IdleGesture | null = null;
    let timer: ReturnType<typeof setTimeout>;
    const next = () => {
      timer = setTimeout(() => {
        const g = nextGesture(last, from, Math.random);
        last = g;
        setGesture(g);
        timer = setTimeout(() => {
          setGesture(null);
          next();
        }, GESTURE_MS[g]);
      }, gestureDelay(Math.random));
    };
    next();
    return () => {
      clearTimeout(timer);
      setGesture(null);
    };
  }, [still, from]);
  return gesture;
}

/** Each mood in words, for screen readers. */
export const MOOD_WORDS = {
  rest: "smpMoodRest",
  listen: "smpMoodListen",
  think: "smpMoodThink",
  work: "smpMoodWork",
  wait: "smpMoodWait",
  happy: "smpMoodHappy",
  worried: "smpMoodWorried",
} as const satisfies Record<GiantMood, string>;

/** God's gestures: its eyes are one group, so no wink. */
const GOD_GESTURES: readonly IdleGesture[] = ["look-l", "look-r", "hop", "wiggle", "nod"];

/** A giant mascot with its mood and gestures; [label] for screen readers. */
export function GiantMascot({
  agent,
  spec: given,
  name,
  mood,
  gestures,
  still = false,
  size = 260,
}: {
  agent: Agent | undefined;
  /** A drawing of its own (Satellite's), whatever the agent's spec. */
  spec?: MascotSpec;
  name?: string;
  mood: GiantMood;
  gestures: readonly IdleGesture[];
  /** Behind on the orbit: no gestures. */
  still?: boolean;
  size?: number;
}) {
  addMascotMotion();
  const spec = given ?? (agent ? specOf(agent) : mascotSpec("God", "god"));
  // Behind on the orbit it shows no sign of its state (it would land on the one in front).
  const state = still ? "active" : GIANT_STATE[mood];
  const gesture = useIdleGesture(mood === "rest" && !still, gestures);
  const id = useMemo(() => `rgg${Math.random().toString(36).slice(2, 8)}-`, []);
  const label = t("smpMascotOf", {
    name: name ?? agent?.name ?? "God",
    state: t(MOOD_WORDS[mood]),
  });
  const svg = useMemo(
    () => mascotSvg(spec, { state, size, idPrefix: id, label }),
    [spec, state, size, id, label],
  );
  return (
    <div
      class={`smp-giant mood-${mood}${gesture ? ` g-${gesture}` : ""}`}
      data-mood={mood}
      data-gesture={gesture ?? undefined}
    >
      <div class="smp-giant-float">
        <div
          class="smp-giant-act"
          // Our own drawing: numbers from the spec and an escaped label, never the agent's text.
          dangerouslySetInnerHTML={{ __html: svg }}
        />
      </div>
    </div>
  );
}

/** Satellite's gestures: its eyes are its own, so it winks too. */
const SATELLITE_GESTURES: readonly IdleGesture[] = IDLE_GESTURES;

/** The Chat's agent, when it was made. */
export const chatAgent = (): Agent | undefined =>
  agents.value.find((a) => a.id === chatAgentId.value);

/** Satellite's mood: the Chat's live state, and the person writing to it. */
export function satelliteMood(): GiantMood {
  const chat = chatAgent();
  const live: MascotState = chat ? agentMascotState(chat.id) : "idle";
  return giantMood({
    typing: simpleTyping.value && stageFront.value === "chat",
    routing: chatSending.value || live === "think",
    working: live === "work",
    waiting: live === "wait",
    happy: false,
    error: live === "error",
  });
}

/** The radius of the orbit for the stage's width. */
const radiusFor = (width: number) => Math.max(110, Math.min(240, width * 0.36));

/**
 * «Oggi»'s stage: God, giant, and Satellite behind him on the same orbit. A swipe, a tap on the one
 * behind or on the names bring the other in front (`stageFront`); with reduced motion at once.
 */
export function SimpleStage() {
  const front = stageFront.value;
  const box = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(720);
  // The angles on the orbit: 0 in front; the one behind at ±ORBIT_BACK.
  const [th, setTh] = useState<Record<StageFront, number>>(() =>
    front === "god" ? { god: 0, chat: ORBIT_BACK } : { god: ORBIT_BACK, chat: 0 },
  );
  const anim = useRef<number | undefined>(undefined);
  const start = useRef<number | null>(null);
  useEffect(() => {
    const el = box.current;
    if (!el) return;
    const measure = () => setWidth(el.clientWidth || 720);
    measure();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  useEffect(() => () => cancelAnimationFrame(anim.current ?? 0), []);
  const rotate = (dir: 1 | -1) => {
    const now = stageFront.value;
    const back: StageFront = now === "god" ? "chat" : "god";
    stageFront.value = back;
    const to = { [now]: dir * ORBIT_BACK, [back]: 0 } as Record<StageFront, number>;
    if (reducedMotion() || typeof requestAnimationFrame === "undefined") {
      setTh(to);
      return;
    }
    const from = { ...th };
    // The one coming in front goes all the way round to 0, on the side of the swipe.
    const target = { ...to, [back]: dir > 0 ? 2 * Math.PI : -2 * Math.PI } as Record<
      StageFront,
      number
    >;
    if (dir > 0 && from[back] < 0) from[back] += 2 * Math.PI;
    if (dir < 0 && from[back] > 0) from[back] -= 2 * Math.PI;
    const t0 = performance.now();
    cancelAnimationFrame(anim.current ?? 0);
    const step = (at: number) => {
      const p = Math.min(1, (at - t0) / 900);
      const e = p < 0.5 ? 4 * p * p * p : 1 - (-2 * p + 2) ** 3 / 2;
      setTh({
        god: from.god + (target.god - from.god) * e,
        chat: from.chat + (target.chat - from.chat) * e,
      });
      if (p < 1) anim.current = requestAnimationFrame(step);
      else setTh(to);
    };
    anim.current = requestAnimationFrame(step);
  };
  const bring = (who: StageFront) => {
    if (stageFront.value === who) return;
    rotate(th[who] > 0 ? -1 : 1);
  };
  const radius = radiusFor(width);
  const place = (who: StageFront) => {
    const p = orbitPlace(th[who], radius);
    return {
      transform: `translate(${p.x}px, ${p.y}px) scale(${p.scale})`,
      zIndex: p.z,
      // Dimmer behind (opacity: a filter on the drawing leaves a grey box in Chromium).
      opacity: p.light,
    };
  };
  const god = godAgent();
  const satellite = useMemo(() => mascotSpec(SATELLITE_SEED, "assistant"), []);
  return (
    <div class="smp-stage-wrap">
      <div
        ref={box}
        class="smp-stage"
        onPointerDown={(e) => {
          start.current = e.clientX;
        }}
        onPointerUp={(e) => {
          const x0 = start.current;
          start.current = null;
          if (x0 === null) return;
          if (Math.abs(e.clientX - x0) > 40) rotate(e.clientX > x0 ? 1 : -1);
          else {
            // A tap on the one behind brings it in front (the names below do it by keyboard).
            const back = (e.target as Element | null)?.closest?.(".smp-orbiter.back");
            if (back) bring(back.classList.contains("sat") ? "chat" : "god");
          }
        }}
      >
        <div class="smp-orbit" aria-hidden="true" />
        {(["god", "chat"] as const).map((who) => (
          <div
            key={who}
            class={`smp-orbiter ${who === "chat" ? "sat" : "god"}${front === who ? " front" : " back"}`}
            style={place(who)}
          >
            {who === "god" ? (
              <GiantMascot
                agent={god}
                mood={godMood()}
                gestures={GOD_GESTURES}
                still={front !== "god"}
              />
            ) : (
              <GiantMascot
                agent={chatAgent()}
                spec={satellite}
                name={t("smpSatellite")}
                mood={satelliteMood()}
                gestures={SATELLITE_GESTURES}
                still={front !== "chat"}
              />
            )}
          </div>
        ))}
      </div>
      <div class="smp-names">
        <button
          type="button"
          class={front === "god" ? "on" : ""}
          aria-pressed={front === "god"}
          onClick={() => bring("god")}
        >
          {god?.name ?? "God"}
        </button>
        <button
          type="button"
          class={front === "chat" ? "on sat" : "sat"}
          aria-pressed={front === "chat"}
          onClick={() => bring("chat")}
        >
          {t("smpSatelliteChat")}
        </button>
      </div>
    </div>
  );
}
