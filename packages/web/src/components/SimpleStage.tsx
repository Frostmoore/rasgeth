// «Oggi»'s stage (3.12.1, tavole-mascotte-chat/luna.html): God's mascot, giant, at the centre
// above the greeting. Its mood follows what really happens (`giantMood` in state.ts) and, still,
// it makes a small gesture now and then, never the same twice in a row. With reduced motion it
// stays still.
import { mascotSpec, mascotSvg } from "@redgiant/mascot";
import type { MascotState } from "@redgiant/protocol";
import { useEffect, useMemo, useState } from "preact/hooks";
import { reducedMotion } from "../a11y.js";
import type { Agent } from "../api.js";
import { t } from "../i18n.js";
import { agentMascotState } from "../mascot-state.js";
import {
  agents,
  approvals,
  GESTURE_MS,
  GIANT_STATE,
  type GiantMood,
  gestureDelay,
  giantCheer,
  giantMood,
  godRouting,
  type IdleGesture,
  lastError,
  nextGesture,
  questions,
  simpleTyping,
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
    typing: simpleTyping.value,
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
export const MOOD_WORDS: Record<GiantMood, string> = {
  rest: "smpMoodRest",
  listen: "smpMoodListen",
  think: "smpMoodThink",
  work: "smpMoodWork",
  wait: "smpMoodWait",
  happy: "smpMoodHappy",
  worried: "smpMoodWorried",
};

/** God's gestures: its eyes are one group, so no wink. */
const GOD_GESTURES: readonly IdleGesture[] = ["look-l", "look-r", "hop", "wiggle", "nod"];

/** A giant mascot with its mood and gestures; [label] for screen readers. */
export function GiantMascot({
  agent,
  mood,
  gestures,
  size = 260,
}: {
  agent: Agent | undefined;
  mood: GiantMood;
  gestures: readonly IdleGesture[];
  size?: number;
}) {
  addMascotMotion();
  const spec = agent ? specOf(agent) : mascotSpec("God", "god");
  const state = GIANT_STATE[mood];
  const gesture = useIdleGesture(mood === "rest", gestures);
  const id = useMemo(() => `rgg${Math.random().toString(36).slice(2, 8)}-`, []);
  const label = t("smpMascotOf", {
    name: agent?.name ?? "God",
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

/** «Oggi»'s stage: God, giant, on its orbit. */
export function SimpleStage() {
  const mood = godMood();
  return (
    <div class="smp-stage">
      <div class="smp-orbit" aria-hidden="true" />
      <GiantMascot agent={godAgent()} mood={mood} gestures={GOD_GESTURES} />
    </div>
  );
}
