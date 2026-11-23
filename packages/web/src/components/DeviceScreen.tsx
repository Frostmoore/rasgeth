// An Android emulator or phone live in the area on the right (3.11, phase 2), as the agents'
// browser (Screen.tsx): watch what the agents do; «Take control» and the screen is the person's
// (a tap, a press held, a swipe with the mouse or the finger, the keyboard), never logged and never
// seen by a model; then give it back. The phone's own buttons and turning it are drawn under it.
import { type DeviceInput, isIosId } from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { H264Canvas, hasVideoDecoder } from "../device-video.js";
import { t } from "../i18n.js";
import { IconChevronLeft, IconHome, IconRotate, IconSquare } from "../icons.js";
import { deviceScreens, deviceVideoSinks, getLive } from "../state.js";

/** Keys sent as such; everything else printable is typed as text. */
const KEYS = new Set([
  "Enter",
  "Backspace",
  "Delete",
  "Tab",
  "Escape",
  "ArrowUp",
  "ArrowDown",
  "ArrowLeft",
  "ArrowRight",
]);

/** A pointer's path on the screen: a tap, a press held, or a swipe. Pure. */
export function gesture(
  from: { x: number; y: number },
  to: { x: number; y: number },
  ms: number,
): DeviceInput {
  const moved = Math.hypot(to.x - from.x, to.y - from.y);
  if (moved > 0.02)
    return {
      kind: "swipe",
      x: from.x,
      y: from.y,
      x2: to.x,
      y2: to.y,
      ms: Math.min(5000, Math.max(50, Math.round(ms))),
    };
  if (ms >= 500) return { kind: "long", x: from.x, y: from.y, ms: Math.min(5000, Math.round(ms)) };
  return { kind: "tap", x: from.x, y: from.y };
}

export function DeviceScreen({ device, title }: { device: string; title: string }) {
  const s = deviceScreens.value[device] ?? {
    state: "starting" as const,
    control: "agents" as const,
  };
  const area = useRef<HTMLDivElement>(null);
  const down = useRef<{ x: number; y: number; at: number } | undefined>(undefined);
  const canvas = useRef<HTMLCanvasElement>(null);
  // H.264 decoded here when the browser can (3.11 phase 7); JPEG frames otherwise or after a failure.
  const [format, setFormat] = useState<"h264" | "jpeg">(() =>
    hasVideoDecoder() ? "h264" : "jpeg",
  );
  const [video, setVideo] = useState(false);
  useEffect(() => {
    const live = getLive();
    let decoder: H264Canvas | undefined;
    if (format === "h264") {
      decoder = new H264Canvas(
        () => canvas.current,
        () => {
          setVideo(false);
          setFormat("jpeg");
        },
        () => setVideo(true),
      );
      deviceVideoSinks.set(device, (m) => void decoder?.push(m));
    }
    live.send({ type: "device.watch", id: device, ...(format === "h264" && { format }) });
    return () => {
      live.send({ type: "device.unwatch", id: device });
      if (deviceVideoSinks.get(device)) deviceVideoSinks.delete(device);
      decoder?.close();
    };
  }, [device, format]);
  useEffect(() => {
    if (s.control === "person") area.current?.focus();
  }, [s.control]);
  const mine = s.control === "person";
  const send = (event: DeviceInput) =>
    mine && getLive().send({ type: "device.input", id: device, event });
  const at = (e: PointerEvent) => {
    const r = (e.currentTarget as HTMLElement).getBoundingClientRect();
    return {
      x: Math.min(1, Math.max(0, (e.clientX - r.left) / r.width)),
      y: Math.min(1, Math.max(0, (e.clientY - r.top) / r.height)),
    };
  };
  const wide = s.frame ? s.frame.width > s.frame.height : false;
  // An iPhone has no back and no recents button: only home (and turning).
  const ios = isIosId(device);
  const button = (b: "back" | "home" | "recents") => send({ kind: "button", button: b });
  return (
    <div class="screen device-screen">
      <div class="screen-bar">
        <span class="screen-url" title={title}>
          {title}
          <span class="dim"> · {t(`dsState_${s.state}` as const)}</span>
        </span>
        <button
          type="button"
          class={mine ? "" : "primary"}
          disabled={s.state !== "on"}
          onClick={() => getLive().send({ type: "device.control", id: device, take: !mine })}
        >
          {mine ? t("screenGiveBack") : t("screenTake")}
        </button>
      </div>
      <p class={`ui-help screen-note${mine ? " mine" : ""}`}>
        {s.error ? t("dsError", { error: s.error }) : mine ? t("dsYours") : t("dsShared")}
      </p>
      <div class={`device-frame${wide ? " wide" : ""}`}>
        {/* biome-ignore lint/a11y/noNoninteractiveTabindex: while it is the person's, the screen takes their keyboard. */}
        <div
          ref={area}
          class={`device-view${mine ? " mine" : ""}`}
          tabIndex={mine ? 0 : -1}
          role="img"
          aria-label={t("dsScreen", { name: title })}
          onPointerDown={(e) => {
            if (!mine) return;
            (e.currentTarget as HTMLElement).setPointerCapture?.(e.pointerId);
            down.current = { ...at(e as unknown as PointerEvent), at: e.timeStamp };
          }}
          onPointerUp={(e) => {
            const d = down.current;
            down.current = undefined;
            if (!mine || !d) return;
            send(gesture(d, at(e as unknown as PointerEvent), e.timeStamp - d.at));
          }}
          onKeyDown={(e) => {
            if (!mine || e.isComposing) return;
            if (KEYS.has(e.key)) {
              e.preventDefault();
              send({ kind: "key", key: e.key as Extract<DeviceInput, { kind: "key" }>["key"] });
            } else if (e.key === " ") {
              e.preventDefault();
              send({ kind: "key", key: "Space" });
            } else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey) {
              e.preventDefault();
              send({ kind: "text", text: e.key });
            }
          }}
          onPaste={(e) => {
            const text = e.clipboardData?.getData("text") ?? "";
            if (mine && text) {
              e.preventDefault();
              send({ kind: "text", text: text.slice(0, 2000) });
            }
          }}
        >
          {format === "h264" && <canvas ref={canvas} hidden={!video} class="device-canvas" />}
          {video ? null : s.frame ? (
            <img src={`data:image/jpeg;base64,${s.frame.data}`} alt="" draggable={false} />
          ) : (
            <div class="empty">
              {s.state === "starting" ? t("dsStarting") : t("screenStarting")}
            </div>
          )}
        </div>
        <div class="device-keys">
          {!ios && (
            <button
              type="button"
              class="icon-button"
              disabled={!mine}
              title={t("dsBack")}
              aria-label={t("dsBack")}
              onClick={() => button("back")}
            >
              <IconChevronLeft size={16} />
            </button>
          )}
          <button
            type="button"
            class="icon-button"
            disabled={!mine}
            title={t("dsHome")}
            aria-label={t("dsHome")}
            onClick={() => button("home")}
          >
            <IconHome size={16} />
          </button>
          {!ios && (
            <button
              type="button"
              class="icon-button"
              disabled={!mine}
              title={t("dsRecents")}
              aria-label={t("dsRecents")}
              onClick={() => button("recents")}
            >
              <IconSquare size={14} />
            </button>
          )}
          <button
            type="button"
            class="icon-button"
            disabled={!mine}
            title={t("dsRotate")}
            aria-label={t("dsRotate")}
            onClick={() => send({ kind: "rotate" })}
          >
            <IconRotate size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}
