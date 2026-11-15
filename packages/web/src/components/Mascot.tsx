// An agent's mascot (G40.2): its face from `@redgiant/mascot`, coloured by the theme's CSS
// variables and always moving (the library's motion table as CSS animations, each mascot with its
// own rhythm from its seed; none with reduced motion, paused while the page is hidden). The state
// is the agent's live one unless given; screen readers hear the name and the state.
import { mascotMotionCss, mascotSpec, mascotSvg } from "@redgiant/mascot";
import type { MascotSpec, MascotState } from "@redgiant/protocol";
import { useMemo } from "preact/hooks";
import type { Agent } from "../api.js";
import { t } from "../i18n.js";
import { agentMascotState } from "../mascot-state.js";
import { agents } from "../state.js";

let next = 0;
let motionAdded = false;

/** Adds the motion's CSS once, and pauses it while the page is not in front. */
export function addMascotMotion(doc: Document | undefined = globalThis.document): void {
  if (motionAdded || !doc?.head) return;
  motionAdded = true;
  const style = doc.createElement("style");
  style.id = "rg-mascot-motion";
  style.textContent = mascotMotionCss();
  doc.head.append(style);
  const sync = () => doc.documentElement.classList.toggle("rg-hidden", doc.hidden);
  doc.addEventListener("visibilitychange", sync);
  sync();
}

/** The agent's spec: the server's, or made here from its seed (older servers, the demo). */
export function specOf(agent: Agent): MascotSpec {
  if (agent.mascot) return agent.mascot;
  const parent =
    agent.kind === "subagent" && agent.parentId
      ? agents.value.find((a) => a.id === agent.parentId)
      : undefined;
  return mascotSpec(agent.mascotSeed ?? agent.id, agent.kind, parent ? specOf(parent) : undefined);
}

export function Mascot({
  agent,
  size = 24,
  state,
  decorative,
}: {
  agent: Agent;
  /** 16-20: body and eyes only; 24-32 lists; 48-64 headers; 128 the agent's card. */
  size?: number;
  /** Fixed state; the agent's live one when absent. */
  state?: MascotState;
  /** Next to the agent's name and its state in words: screen readers skip it. */
  decorative?: boolean;
}) {
  addMascotMotion();
  const shown = state ?? agentMascotState(agent.id);
  const spec = specOf(agent);
  const id = useMemo(() => `rgm${++next}-`, []);
  const label = decorative
    ? undefined
    : t("mascotOf", { name: agent.name, state: t(`mascotState_${shown}`) });
  const svg = useMemo(
    () => mascotSvg(spec, { state: shown, size, idPrefix: id, ...(label && { label }) }),
    [spec, shown, size, id, label],
  );
  return (
    <span
      class="mascot"
      data-state={shown}
      style={{ width: `${size}px`, height: `${size}px` }}
      // Our own drawing: numbers from the spec and an escaped label, never the agent's text.
      dangerouslySetInnerHTML={{ __html: svg }}
    />
  );
}
