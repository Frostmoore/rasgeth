// The agents' strip at the bottom of «Oggi» (3.12.1, tavole-mascotte-chat/striscia-fitta.html):
// the mascots of every agent, overlapping by almost half. The mouse over it, or a finger sliding
// along it, enlarges the one under it (its neighbours a little); it makes a small movement and a
// balloon with its name and live state appears above; tapping the balloon opens its conversation.
// By keyboard each mascot is a button: focus picks it; the balloon comes after the strip.
import { useRef, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { agentMascotState } from "../mascot-state.js";
import { agents, chatAgentId, nearestIndex, openAgentConversation, stripAgents } from "../state.js";
import { Mascot } from "./Mascot.js";

export function SimpleStrip() {
  const list = stripAgents(agents.value, chatAgentId.value);
  const [on, setOn] = useState<string | null>(null);
  const strip = useRef<HTMLDivElement>(null);
  const wrap = useRef<HTMLDivElement>(null);
  if (list.length === 0) return null;
  const at = list.findIndex((a) => a.id === on);
  const picked = at >= 0 ? list[at] : undefined;
  const under = (x: number) => {
    const els = [...(strip.current?.querySelectorAll<HTMLElement>(".smp-sm") ?? [])];
    const i = nearestIndex(
      els.map((e) => {
        const r = e.getBoundingClientRect();
        return r.left + r.width / 2;
      }),
      x,
    );
    const a = list[i];
    if (a) setOn(a.id);
  };
  // The balloon over the picked one (its centre, from the strip's own box).
  const balloonLeft = (() => {
    const el = strip.current?.querySelectorAll<HTMLElement>(".smp-sm")[at];
    const w = wrap.current?.getBoundingClientRect();
    if (!el || !w) return undefined;
    const r = el.getBoundingClientRect();
    return r.left + r.width / 2 - w.left;
  })();
  const state = picked ? agentMascotState(picked.id) : "idle";
  return (
    <div
      ref={wrap}
      class="smp-strip-wrap"
      onPointerLeave={(e) => {
        if (e.pointerType === "mouse") setOn(null);
      }}
    >
      <div class="smp-lbl smp-strip-t">{t("smpYourAgents")}</div>
      <div
        ref={strip}
        class="smp-strip"
        onPointerMove={(e) => under(e.clientX)}
        onPointerDown={(e) => under(e.clientX)}
      >
        {list.map((a, i) => (
          <button
            type="button"
            key={a.id}
            class={`smp-sm${a.id === on ? " on" : at >= 0 && Math.abs(i - at) === 1 ? " near" : ""}`}
            style={{ "--i": String(i) }}
            aria-label={t("smpAgentIs", {
              name: a.name,
              state: t(`mascotState_${agentMascotState(a.id)}`),
            })}
            aria-expanded={a.id === on}
            onFocus={() => setOn(a.id)}
            onClick={() => setOn(a.id)}
          >
            <Mascot agent={a} size={84} decorative />
          </button>
        ))}
      </div>
      {picked && (
        <button
          type="button"
          class="smp-balloon"
          style={balloonLeft === undefined ? undefined : { left: `${balloonLeft}px` }}
          onClick={() => void openAgentConversation(picked.id, picked.name)}
        >
          <b>{picked.name}</b>
          <span class="smp-balloon-go">{t("smpOpenChat")}</span>
          <small>{t(`mascotState_${state}`)}</small>
        </button>
      )}
    </div>
  );
}
