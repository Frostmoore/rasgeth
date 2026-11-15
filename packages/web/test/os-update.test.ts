// RedGiant OS's update as the page shows it (3.8.1): which steps are done, which runs, which
// failed, and the time the whole still needs, from the updater's state.
import { describe, expect, it } from "vitest";
import {
  type OsUpdate,
  planBytes,
  secondsLeft,
  tookSeconds,
  updatedTo,
  updateSteps,
} from "../src/os-update.js";

const MB = 1_000_000;
const T0 = Date.parse("2026-11-15T10:00:00Z");
const at = (s: number) => new Date(T0 + s * 1000).toISOString();
const steps = ["check", "download", "files", "install", "restart", "wait"];

function upd(o: Partial<OsUpdate> = {}, run: Partial<NonNullable<OsUpdate["run"]>> = {}): OsUpdate {
  return {
    state: "applying",
    installed: "3.8.0",
    latest: "3.8.1",
    gate: "normal",
    note: null,
    step: "download",
    checkedAt: null,
    run: {
      from: "3.8.0",
      startedAt: at(0),
      finishedAt: null,
      reason: null,
      steps,
      stepAt: { check: at(0), download: at(4) },
      plan: {
        images: [
          { name: "redgiant", ref: "r:3.8.1", bytes: 400 * MB, here: false },
          { name: "postgres", ref: "p:17", bytes: 90 * MB, here: true },
        ],
        files: { name: "redgiant-os-files-3.8.1.tar.zst", bytes: 2 * MB },
      },
      progress: {
        done: 100 * MB,
        total: 300 * MB,
        bps: 10 * MB,
        eta: 20,
        items: [{ name: "redgiant", done: 100 * MB, total: 300 * MB, state: "down" }],
      },
      ...run,
    },
    ...o,
  };
}
const marks = (u: OsUpdate | null, running = true, lost = false) =>
  updateSteps(u, running, lost).map((s) => `${s.id}:${s.mark}`);

describe("the update's steps", () => {
  it.each([
    [
      "downloading",
      upd(),
      true,
      false,
      ["check:done", "download:now", "files:todo", "install:todo", "restart:todo", "wait:todo"],
    ],
    [
      "just asked, nothing written yet",
      upd({ state: "available", step: null, run: null }),
      true,
      false,
      ["check:now", "download:todo", "files:todo", "install:todo", "restart:todo", "wait:todo"],
    ],
    [
      "RedGiant restarting (the page lost it)",
      upd({ step: "install" }),
      true,
      true,
      ["check:done", "download:done", "files:done", "install:done", "restart:now", "wait:todo"],
    ],
    [
      "done",
      upd({ state: "latest", step: null, installed: "3.8.1" }, { finishedAt: at(300) }),
      false,
      false,
      ["check:done", "download:done", "files:done", "install:done", "restart:done", "wait:done"],
    ],
    [
      "the download failed",
      upd({ state: "error", step: null }, { reason: "download", finishedAt: at(60) }),
      false,
      false,
      ["check:done", "download:failed", "files:todo", "install:todo", "restart:todo", "wait:todo"],
    ],
    [
      "it did not come up and went back",
      upd(
        { state: "error", step: null },
        {
          reason: "not_up",
          steps: [...steps, "rollback"],
          stepAt: Object.fromEntries([...steps, "rollback"].map((s, i) => [s, at(i)])),
        },
      ),
      false,
      false,
      [
        "check:done",
        "download:done",
        "files:done",
        "install:done",
        "restart:done",
        "wait:failed",
        "rollback:done",
      ],
    ],
    [
      "an updater before 3.8.1 («files» was download and install)",
      upd({ step: "files", run: null }),
      true,
      false,
      ["check:done", "download:done", "files:done", "install:now", "restart:todo", "wait:todo"],
    ],
  ])("%s", (_name, u, running, lost, want) => {
    expect(marks(u, running, lost)).toEqual(want);
  });
});

describe("the time the whole update still needs", () => {
  const now = T0 + 30_000;
  it("counts the download at its speed, then the usual time of each step after it", () => {
    // 20 s of images, 2 MB of files at 10 MB/s, then install 10, restart 45, wait 45.
    expect(secondsLeft(upd(), true, now)).toBe(20 + 0 + 10 + 45 + 45);
  });
  it("cannot say it before the speed is known", () => {
    expect(secondsLeft(upd({}, { progress: null }), true, now)).toBeNull();
    expect(secondsLeft(upd({ step: "check" }, { progress: null }), true, now)).toBeNull();
  });
  it("takes off what the running step already took, never down to nothing", () => {
    const u = upd({ step: "restart" }, { stepAt: { restart: at(0) }, progress: null });
    expect(secondsLeft(u, true, T0 + 20_000)).toBe(25 + 45);
    expect(secondsLeft(u, true, T0 + 600_000)).toBe(Math.round(45 / 4) + 45);
  });
  it("says nothing when no update runs", () => {
    expect(secondsLeft(upd({ state: "latest", step: null }), false, now)).toBeNull();
  });
});

describe("sizes, duration and the version reached", () => {
  it("counts what really comes down once Docker said it", () => {
    expect(planBytes(upd({ step: "check" }, { progress: null }))).toBe(402 * MB);
    expect(planBytes(upd())).toBe(302 * MB);
  });
  it("says the new version only for an update that ended well, from another one", () => {
    const done = upd({ state: "latest", installed: "3.8.1", step: null }, { finishedAt: at(250) });
    expect(updatedTo(done)).toEqual({ to: "3.8.1", from: "3.8.0" });
    expect(tookSeconds(done)).toBe(250);
    expect(updatedTo(upd())).toBeNull();
    expect(updatedTo(upd({ state: "latest", step: null }, { finishedAt: at(9) }))).toBeNull();
  });
});
