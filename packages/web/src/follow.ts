/**
 * Following a reply as it streams (3.10.4). The person: with cloud models the text comes faster
 * than one reads, and a finger put down to stay at a point was pulled to the bottom anyway. So the
 * conversation follows the newest text only while the view is at the bottom (within `NEAR` px);
 * a touch, a press, a wheel or a key upwards, or any scroll up, stops it and the view stays where
 * it is (new text grows below and moves nothing). Scrolling back to the bottom by hand (once the
 * finger is lifted), the «New text» button, or sending a message follows again.
 * Pure state, no DOM: `useFollow` (components/follow-hook.ts) wires it to a scroller.
 */
export const NEAR = 4;

export interface FollowState {
  /** Keep the view at the bottom as text grows. */
  follow: boolean;
  /** Text came below while not following: the «New text» button. */
  unseen: boolean;
  /** A finger or a button is down on the conversation. */
  holding: boolean;
  /** The last scroll offset seen, to tell a scroll up from one down. */
  top: number;
  /** The last content height seen, to tell new text from a mere render. */
  height: number;
}

export interface Metrics {
  scrollTop: number;
  scrollHeight: number;
  clientHeight: number;
}

export const startFollow = (): FollowState => ({
  follow: true,
  unseen: false,
  holding: false,
  top: 0,
  height: 0,
});

const atEnd = (m: Metrics) => m.scrollHeight - m.scrollTop - m.clientHeight <= NEAR;

/** The person put a finger (or a button) down, wheeled or pressed a key upwards. */
export function stopFollowing(s: FollowState, holding = s.holding): FollowState {
  return { ...s, follow: false, holding };
}

/** The finger lifted: at the bottom, following again. */
export function release(s: FollowState, m: Metrics): FollowState {
  const r = { ...s, holding: false, top: m.scrollTop };
  return atEnd(m) ? { ...r, follow: true, unseen: false } : r;
}

/** A scroll, the person's or ours. */
export function scrolled(s: FollowState, m: Metrics): FollowState {
  const up = m.scrollTop < s.top - 1;
  const r = { ...s, top: m.scrollTop };
  if (s.follow) return up && !atEnd(m) ? { ...r, follow: false } : r;
  return !s.holding && atEnd(m) ? { ...r, follow: true, unseen: false } : r;
}

/** The content changed size: while not following, there is text below to see. */
export function grew(s: FollowState, m: Metrics): FollowState {
  if (m.scrollHeight === s.height) return s;
  const more = m.scrollHeight > s.height && s.height > 0;
  return {
    ...s,
    height: m.scrollHeight,
    unseen: s.unseen || (!s.follow && more && !atEnd(m)),
  };
}

/** «New text», or a message sent: back to the bottom and following. */
export function resume(s: FollowState): FollowState {
  return { ...s, follow: true, unseen: false, holding: false };
}

/** Keys that move a conversation up. */
export const UP_KEYS = new Set(["ArrowUp", "PageUp", "Home"]);
