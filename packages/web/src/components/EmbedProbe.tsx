// The embed's test page (G42.0, `#embed=probe`): what the Canvas's editors need from a web view,
// measured where it runs. Cross-origin isolation and SharedArrayBuffer under /zeta/ (LibreOffice's
// threads), WebGL 2 (3D), H.264 in <video> (the video proxies), the clipboard (through the app), and
// the memory the page can see. Shown in a table; the same results in `window.__rgProbe` for the
// screenshot scripts.
import { PRODUCT_NAME } from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import { embedded, toApp } from "../embed.js";
import { t } from "../i18n.js";

type Result = { ok: boolean | undefined; detail: string };
export type ProbeResults = Record<"isolation" | "webgl2" | "h264" | "clipboard" | "memory", Result>;

const wait: Result = { ok: undefined, detail: "" };

/** WebGL 2 and who draws it. */
export function probeWebgl(): Result {
  try {
    const c = document.createElement("canvas");
    const gl = c.getContext("webgl2");
    if (!gl) return { ok: false, detail: "no webgl2" };
    const info = gl.getExtension("WEBGL_debug_renderer_info");
    const who = info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
    return { ok: true, detail: String(who) };
  } catch (e) {
    return { ok: false, detail: (e as Error).message };
  }
}

/** The isolated frame's answer (`/zeta/probe.html`). */
function probeIsolation(): Promise<Result> {
  return new Promise((done) => {
    const f = document.createElement("iframe");
    f.src = "/zeta/probe.html";
    f.style.display = "none";
    const timer = setTimeout(() => finish({ ok: false, detail: "no answer" }), 8000);
    const listen = (e: MessageEvent) => {
      const d = e.data as { redgiant?: string; result?: Record<string, unknown> } | null;
      if (e.source !== f.contentWindow || d?.redgiant !== "isolation-probe" || !d.result) return;
      const r = d.result;
      finish({
        ok: r.isolated === true && r.sab === true && r.atomics === true,
        detail: `crossOriginIsolated ${r.isolated}, SharedArrayBuffer ${r.sab}, Atomics ${r.atomics}, ${r.threads} threads`,
      });
    };
    function finish(r: Result) {
      clearTimeout(timer);
      window.removeEventListener("message", listen);
      f.remove();
      done(r);
    }
    window.addEventListener("message", listen);
    document.body.appendChild(f);
  });
}

/** A two-second H.264 clip, played for real (from a blob: no byte ranges needed). */
function probeH264(): Promise<Result> {
  const v = document.createElement("video");
  const can = v.canPlayType('video/mp4; codecs="avc1.42E01E"');
  return fetch("/probe/h264.mp4")
    .then((r) => r.blob())
    .then(
      (b) =>
        new Promise<Result>((done) => {
          const url = URL.createObjectURL(b);
          const end = (r: Result) => {
            URL.revokeObjectURL(url);
            done(r);
          };
          const timer = setTimeout(
            () => end({ ok: false, detail: `canPlayType "${can}", no frame` }),
            8000,
          );
          v.muted = true;
          v.playsInline = true;
          v.onloadeddata = () => {
            clearTimeout(timer);
            end({
              ok: v.videoWidth > 0,
              detail: `canPlayType "${can}", ${v.videoWidth}x${v.videoHeight}`,
            });
          };
          v.onerror = () => {
            clearTimeout(timer);
            end({ ok: false, detail: `canPlayType "${can}", error ${v.error?.code ?? "?"}` });
          };
          v.src = url;
          void v.play().catch(() => {});
        }),
      (e: unknown) => ({ ok: false, detail: (e as Error).message }),
    );
}

function probeClipboard(): Result {
  if (embedded()) {
    const sent = toApp({ t: "copy", text: `${PRODUCT_NAME} probe` });
    return { ok: sent, detail: sent ? "through the app" : "no app channel" };
  }
  const has = typeof navigator.clipboard?.writeText === "function";
  return { ok: has, detail: has ? "navigator.clipboard" : "none" };
}

function probeMemory(): Result {
  const m = (
    performance as Performance & { memory?: { jsHeapSizeLimit: number; usedJSHeapSize: number } }
  ).memory;
  const device = (navigator as Navigator & { deviceMemory?: number }).deviceMemory;
  const parts = [
    m &&
      `heap ${Math.round(m.usedJSHeapSize / 2 ** 20)} / ${Math.round(m.jsHeapSizeLimit / 2 ** 20)} MB`,
    device && `device ${device} GB`,
  ].filter(Boolean);
  return {
    ok: parts.length ? true : undefined,
    detail: parts.join(", ") || "not told by this engine",
  };
}

export function EmbedProbe() {
  const [r, setR] = useState<ProbeResults>({
    isolation: wait,
    webgl2: wait,
    h264: wait,
    clipboard: wait,
    memory: wait,
  });
  useEffect(() => {
    const now = { ...r, webgl2: probeWebgl(), clipboard: probeClipboard(), memory: probeMemory() };
    setR(now);
    void Promise.all([probeIsolation(), probeH264()]).then(([isolation, h264]) => {
      const all = { ...now, isolation, h264 };
      (window as Window & { __rgProbe?: ProbeResults }).__rgProbe = all;
      setR(all);
    });
  }, []);
  const rows: [keyof ProbeResults, string][] = [
    ["isolation", t("embedProbeIsolation")],
    ["webgl2", t("embedProbeWebgl")],
    ["h264", t("embedProbeVideo")],
    ["clipboard", t("embedProbeClipboard")],
    ["memory", t("embedProbeMemory")],
  ];
  return (
    <div class="embed-probe">
      <h2>{t("embedProbeTitle")}</h2>
      <p class="dim">{navigator.userAgent}</p>
      <table class="embed-probe-table">
        <tbody>
          {rows.map(([k, label]) => {
            const x = r[k];
            const tone = x.ok === undefined ? "wait" : x.ok ? "ok" : "ko";
            return (
              <tr key={k} data-probe={k} data-ok={String(x.ok)}>
                <th scope="row">{label}</th>
                <td>
                  <span class={`embed-probe-dot ${tone}`} />
                  {x.ok === undefined
                    ? x.detail
                      ? t("embedProbeUnknown")
                      : t("loading")
                    : x.ok
                      ? t("embedProbeYes")
                      : t("embedProbeNo")}
                </td>
                <td class="dim">{x.detail}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
