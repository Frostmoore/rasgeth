// @vitest-environment jsdom
// The downloads card (G41.1): ffmpeg's download shows its real bar (bytes, speed, time left) and
// a «Cancel» that stops the job; the other downloads keep the card without it.
import type { Job } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
let jobs: Job[] = [];
const fakeApi = {
  jobs: () => Promise.resolve(jobs),
  cancelJob: (...args: unknown[]) => {
    calls.push(["cancelJob", args]);
    return Promise.resolve({});
  },
};
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { Downloads } = await import("../src/components/Downloads.js");

const MB = 1_000_000;
const job = (kind: string, id: string): Job =>
  ({
    id,
    kind,
    state: "running",
    startedAt: new Date().toISOString(),
    vars: {},
    steps: [
      {
        id: "tool_download",
        state: "running",
        progress: { done: 40 * MB, total: 153 * MB, rate: 8 * MB, secondsLeft: 14 },
      },
      { id: "tool_unpack", state: "waiting" },
    ],
  }) as unknown as Job;

afterEach(() => {
  cleanup();
  calls.length = 0;
  lang.value = "it";
});

describe("the downloads card", () => {
  for (const l of ["it", "en"] as const)
    it(`ffmpeg's download has its bar and «Cancel» (${l})`, async () => {
      lang.value = l;
      jobs = [job("download_ffmpeg", "j1"), job("download_git", "j2")];
      const view = render(<Downloads />);
      await waitFor(() => expect(view.container.querySelectorAll(".ui-job")).toHaveLength(2));
      const [ff, git] = [...view.container.querySelectorAll(".ui-job")] as HTMLElement[];
      expect(ff?.textContent).toContain(
        l === "it" ? "Scarico ffmpeg e ffprobe" : "Downloading ffmpeg and ffprobe",
      );
      // Amounts, speed and time left.
      expect(ff?.textContent).toMatch(/26%/);
      expect(ff?.textContent).toMatch(/\/s/);
      expect(ff?.textContent).toContain(
        l === "it" ? "manca meno di un minuto" : "less than a minute left",
      );
      const cancel = ff?.querySelector("button");
      expect(cancel?.textContent).toBe(l === "it" ? "Annulla" : "Cancel");
      expect(git?.querySelector("button")).toBeNull();
      fireEvent.click(cancel as HTMLElement);
      await waitFor(() => expect(calls).toEqual([["cancelJob", ["j1"]]]));
    });
});
