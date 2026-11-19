// A picture in the chat (2026-11-19, the person: «le immagini si devono vedere nella chat quando
// sono state generate o quando sono state prese da qualche parte»): every picture an agent sends
// (ours, the model's own, a screenshot, a file it fetched) shows in place, its shape kept, loaded
// only when it comes near the screen; a frame while it loads, and a plain «cannot be opened» when
// it cannot (never an empty card). A press opens it big in the Canvas.
import { useEffect, useRef, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { IconAlert } from "../icons.js";
import { getApi } from "../state.js";

/** Starts once the element is near the screen (at once where the browser cannot tell). */
function useNear<T extends Element>(): [{ current: T | null }, boolean] {
  const ref = useRef<T>(null);
  const [near, setNear] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return setNear(true);
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          setNear(true);
          io.disconnect();
        }
      },
      { rootMargin: "400px" },
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);
  return [ref, near];
}

export function ChatImage({
  scope,
  path,
  alt,
  onOpen,
}: {
  scope: string;
  path: string;
  alt: string;
  onOpen: () => void;
}) {
  const [ref, near] = useNear<HTMLButtonElement>();
  const [url, setUrl] = useState<string>();
  const [state, setState] = useState<"wait" | "ok" | "bad">("wait");
  useEffect(() => {
    if (!near) return;
    let gone = false;
    setState("wait");
    void getApi()
      .canvasLink({ kind: "file", scope, path })
      .then(
        (r) => !gone && setUrl(r.url),
        () => !gone && setState("bad"),
      );
    return () => {
      gone = true;
    };
  }, [near, scope, path]);
  return (
    <button
      ref={ref}
      type="button"
      class={`chat-image ${state}`}
      title={t("canvasOpen")}
      aria-label={alt}
      onClick={onOpen}
    >
      {url && state !== "bad" && (
        <img
          src={url}
          alt={alt}
          decoding="async"
          onLoad={() => setState("ok")}
          onError={() => setState("bad")}
        />
      )}
      {state === "wait" && <span class="chat-image-wait" aria-hidden="true" />}
      {state === "bad" && (
        <span class="chat-image-bad" role="status">
          <IconAlert size={14} />
          {t("imageUnreadable")}
        </span>
      )}
    </button>
  );
}
