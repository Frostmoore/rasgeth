import type { RefObject } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import {
  type FollowState,
  grew,
  type Metrics,
  release,
  resume,
  scrolled,
  startFollow,
  stopFollowing,
  UP_KEYS,
} from "../follow.js";

const metrics = (el: HTMLElement): Metrics => ({
  scrollTop: el.scrollTop,
  scrollHeight: el.scrollHeight,
  clientHeight: el.clientHeight,
});

/**
 * Follows the newest text in `ref`'s scroller while the person lets it (follow.ts). Returns the
 * state for the «New text» button and `toBottom`, which also follows again (the button, a send).
 */
export function useFollow(ref: RefObject<HTMLElement | null>, reset: unknown) {
  const [s, setS] = useState<FollowState>(startFollow);
  const cur = useRef(s);
  const set = (f: (s: FollowState) => FollowState) => {
    const next = f(cur.current);
    if (next === cur.current) return;
    cur.current = next;
    setS(next);
  };
  const toEnd = () => {
    const el = ref.current;
    if (el) el.scrollTop = el.scrollHeight;
  };
  // Another conversation: following again.
  useEffect(() => set(resume), [reset]);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const hold = () => set((x) => stopFollowing(x, true));
    const lift = () => set((x) => (x.holding ? release(x, metrics(el)) : x));
    const wheel = (e: WheelEvent) => {
      if (e.deltaY < 0) set((x) => stopFollowing(x));
    };
    const key = (e: KeyboardEvent) => {
      if (UP_KEYS.has(e.key) || (e.key === " " && e.shiftKey)) set((x) => stopFollowing(x));
    };
    const scroll = () => set((x) => scrolled(x, metrics(el)));
    el.addEventListener("pointerdown", hold);
    el.addEventListener("touchstart", hold, { passive: true });
    window.addEventListener("pointerup", lift);
    window.addEventListener("pointercancel", lift);
    window.addEventListener("touchend", lift);
    el.addEventListener("wheel", wheel, { passive: true });
    el.addEventListener("keydown", key);
    el.addEventListener("scroll", scroll, { passive: true });
    return () => {
      el.removeEventListener("pointerdown", hold);
      el.removeEventListener("touchstart", hold);
      window.removeEventListener("pointerup", lift);
      window.removeEventListener("pointercancel", lift);
      window.removeEventListener("touchend", lift);
      el.removeEventListener("wheel", wheel);
      el.removeEventListener("keydown", key);
      el.removeEventListener("scroll", scroll);
    };
  }, [ref.current]);
  // After every render (new text): to the bottom while following, else note what came below.
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (cur.current.follow) toEnd();
    set((x) => grew(x, metrics(el)));
  });
  return {
    following: s.follow,
    unseen: s.unseen,
    /** Not following: the view stays, the button shows. */
    away: !s.follow,
    toBottom: () => {
      set(resume);
      toEnd();
    },
    /** For a jump to a passage: stop following so the view stays there. */
    stop: () => set((x) => stopFollowing(x)),
  };
}
