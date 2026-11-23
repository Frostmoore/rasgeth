// The agents' strip at the bottom of «Oggi» (3.12.1, tavole-mascotte-chat/striscia-fitta.html):
// the mascots of every agent, overlapping by almost half. The mouse over it, or a finger sliding
// along it, enlarges the one under it (its neighbours a little); it makes a small movement and a
// balloon with its name and live state appears above; tapping the balloon opens its conversation.
// By keyboard each mascot is a button: focus picks it; the balloon comes after the strip.
// 3.12.2: the strip floats at the bottom of the window; when the picked one changes, the old one
// shrinks while the new one grows and the one balloon slides to its place (no jump, none with
// reduced motion); a press anywhere outside the strip and its balloon picks nobody.
import { useEffect, useRef, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { agentMascotState } from "../mascot-state.js";
import { agents, chatAgentId, nearestIndex, openAgentConversation, stripAgents } from "../state.js";
import { Mascot } from "./Mascot.js";

export function SimpleStrip() {
  const list = stripAgents(agents.value, chatAgentId.value);
  const [on, setOn] = useState<string | null>(null);
  const strip = useRef<HTMLDivElement>(null);
  const wrap = useRef<HTMLDivElement>(null);
  const [left, setLeft] = useState<number>();
  // The last one picked: the balloon fades out with its words, it does not vanish at once.
  const lastId = useRef<string | null>(null);
  if (on) lastId.current = on;
  const at = list.findIndex((a) => a.id === on);
  const shownAt = list.findIndex((a) => a.id === (on ?? lastId.current));
  const picked = shownAt >= 0 ? list[shownAt] : undefined;
  const open = at >= 0;
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
  // A press outside the strip and its balloon picks nobody (a finger has no «leave»).
  useEffect(() => {
    if (!on) return;
    const away = (e: Event) => {
      if (!wrap.current?.contains(e.target as Node)) setOn(null);
    };
    document.addEventListener("pointerdown", away, true);
    return () => document.removeEventListener("pointerdown", away, true);
  }, [on]);
  // The balloon over the picked one (its centre, from the strip's own box). While the sizes
  // change (a short animation) it is followed frame by frame, so it slides with them.
  useEffect(() => {
    const measure = () => {
      const el = strip.current?.querySelectorAll<HTMLElement>(".smp-sm")[shownAt];
      const w = wrap.current?.getBoundingClientRect();
      if (!el || !w) return;
      const r = el.getBoundingClientRect();
      setLeft(r.left + r.width / 2 - w.left);
    };
    measure();
    const still =
      typeof matchMedia === "function" && matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (still || typeof requestAnimationFrame !== "function") return;
    let raf = 0;
    const t0 = performance.now();
    const tick = () => {
      measure();
      if (performance.now() - t0 < 320) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [shownAt, on]);
  if (list.length === 0) return null;
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
          class={`smp-balloon${open ? " show" : ""}`}
          tabIndex={open ? 0 : -1}
          aria-hidden={open ? undefined : "true"}
          style={left === undefined ? undefined : { left: `${left}px` }}
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
