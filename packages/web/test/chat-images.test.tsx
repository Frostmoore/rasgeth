// @vitest-environment jsdom
// Pictures in the chat (2026-11-19): every picture an agent sends shows in place, with a frame
// while it loads and a plain «cannot be opened» when it cannot; a picture by a path in an answer
// says it is not available; «generating a picture» while one is made, ours or the model's own.
import type { Event } from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, screen } from "@testing-library/preact";
import { afterEach, describe, expect, it, vi } from "vitest";

let link: (() => Promise<{ url: string }>) | undefined;
const opened: unknown[] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => ({ canvasLink: () => link?.() ?? Promise.reject(new Error("no")) }),
  openCanvas: (...a: unknown[]) => opened.push(a),
}));

const { generatingNow } = await import("../src/state.js");
const { ChatImage } = await import("../src/components/ChatImage.js");
const { renderAnswer } = await import("../src/markdown.js");

afterEach(() => {
  cleanup();
  opened.length = 0;
});

let seq = 0;
const ev = (type: string, payload: unknown) =>
  ({ seq: ++seq, type, payload, ts: "", sessionId: "s" }) as unknown as Event;

describe("generating right now", () => {
  it("is the last generation call still without its result", () => {
    expect(generatingNow([])).toBeUndefined();
    const call = ev("tool.call", {
      callId: "native_ig_1",
      tool: "image_generation",
      input: { by: "chatgpt-subscription" },
    });
    expect(generatingNow([call])).toBe("image");
    expect(generatingNow([call, ev("tool.result", { callId: "native_ig_1", ok: true })])).toBe(
      undefined,
    );
    expect(
      generatingNow([ev("tool.call", { callId: "v", tool: "video_generation", input: {} })]),
    ).toBe("video");
    // Other tools and a new message from the person end it.
    expect(generatingNow([ev("tool.call", { callId: "r", tool: "read_file", input: {} })])).toBe(
      undefined,
    );
    expect(generatingNow([call, ev("message.user", { text: "stop" })])).toBeUndefined();
  });
});

describe("a picture in the chat", () => {
  it("shows a frame, then the picture; a press opens it", async () => {
    link = () => Promise.resolve({ url: "/preview/x.png" });
    const onOpen = vi.fn();
    const { container } = render(
      <ChatImage scope="platform" path="images/a.png" alt="A red star" onOpen={onOpen} />,
    );
    await act(async () => {});
    expect(container.querySelector(".chat-image-wait")).not.toBeNull();
    const img = container.querySelector("img") as HTMLImageElement;
    expect(img.getAttribute("src")).toBe("/preview/x.png");
    fireEvent.load(img);
    expect(container.querySelector(".chat-image-wait")).toBeNull();
    expect(container.querySelector(".chat-image.ok")).not.toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "A red star" }));
    expect(onOpen).toHaveBeenCalled();
  });

  it("says plainly when it cannot be opened, never an empty card", async () => {
    link = () => Promise.resolve({ url: "/preview/broken.png" });
    const { container } = render(
      <ChatImage scope="platform" path="images/b.png" alt="b" onOpen={() => {}} />,
    );
    await act(async () => {});
    fireEvent.error(container.querySelector("img") as HTMLImageElement);
    expect(container.querySelector("img")).toBeNull();
    expect(screen.getByRole("status").textContent).toMatch(/cannot be opened|Non riesco/);

    link = () => Promise.reject(new Error("gone"));
    cleanup();
    const again = render(
      <ChatImage scope="platform" path="images/c.png" alt="c" onOpen={() => {}} />,
    );
    await act(async () => {});
    expect(again.container.querySelector(".chat-image.bad")).not.toBeNull();
  });
});

describe("pictures in an answer", () => {
  it("shows web pictures lazily and says a path is not available", () => {
    const html = renderAnswer(
      "![stella](https://example.com/s.png) ![cavallo](/data/engines/codex/generated_images/t/a.png)",
    );
    const box = document.createElement("div");
    box.innerHTML = html;
    const img = box.querySelector("img");
    expect(img?.getAttribute("src")).toBe("https://example.com/s.png");
    expect(img?.getAttribute("loading")).toBe("lazy");
    const missing = box.querySelector(".img-missing");
    expect(missing?.textContent).toMatch(/cavallo/);
    expect(missing?.getAttribute("title")).toBe("/data/engines/codex/generated_images/t/a.png");
    expect(box.querySelectorAll("img")).toHaveLength(1);
  });
});
