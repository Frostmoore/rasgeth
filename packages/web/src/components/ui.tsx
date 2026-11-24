// The pieces every screen is built from (G24.1), so that each one reads the same way:
// a step says what it is for and can be skipped, a field explains itself, a switch has its
// words next to it, a long action shows its steps and progress, and errors say what to do.
import type { Job, JobProgress } from "@redgiant/protocol";
import type { ComponentChildren, JSX } from "preact";
import { useEffect, useId, useRef, useState } from "preact/hooks";
import { bytes } from "../format.js";
import { t, tOptional } from "../i18n.js";
import { IconAlert, IconCheck, IconChevron, IconSpinner, IconX } from "../icons.js";
import { attempt, getApi } from "../state.js";

/** One screen of a guided flow: a title, one sentence on what it is for, an optional skip. */
export function Step({
  title,
  purpose,
  children,
  onSkip,
  skipLabel,
}: {
  title: string;
  purpose: string;
  children: ComponentChildren;
  onSkip?: () => void;
  skipLabel?: string;
}) {
  return (
    <section class="ui-step">
      <h2>{title}</h2>
      <p class="ui-purpose">{purpose}</p>
      <div class="ui-step-body">{children}</div>
      {onSkip && (
        <div class="ui-step-skip">
          <button type="button" class="link" onClick={onSkip}>
            {skipLabel ?? t("uiSkip")}
          </button>
        </div>
      )}
    </section>
  );
}

/** A labelled control with a line of help under it, and the error when there is one. */
export function Field({
  label,
  help,
  error,
  children,
}: {
  label: string;
  help?: string | undefined;
  error?: string | undefined;
  children: ComponentChildren;
}) {
  return (
    // biome-ignore lint/a11y/noLabelWithoutControl: the control comes in as children.
    <label class={`ui-field${error ? " invalid" : ""}`}>
      <span class="ui-label">{label}</span>
      {children}
      {help && !error && <span class="ui-help">{help}</span>}
      {error && (
        <span class="ui-error" role="alert">
          <IconAlert size={13} /> {error}
        </span>
      )}
    </label>
  );
}

/** An on/off switch with its name and a line of explanation on the same row. */
export function Toggle({
  label,
  description,
  checked,
  onChange,
  disabled,
}: {
  label: string;
  description?: string | undefined;
  checked: boolean;
  onChange: (on: boolean) => void;
  disabled?: boolean | undefined;
}) {
  const id = useId();
  return (
    <div class={`ui-toggle${disabled ? " disabled" : ""}`}>
      <div class="ui-toggle-text">
        <label for={id} class="ui-toggle-label">
          {label}
        </label>
        {description && <span class="ui-help">{description}</span>}
      </div>
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        class={`ui-switch${checked ? " on" : ""}`}
        disabled={disabled}
        onClick={() => onChange(!checked)}
      >
        <span />
      </button>
    </div>
  );
}

/**
 * Our small on/off switch with its words beside it (never a native checkbox, 2026-11-09):
 * for bars and tight places; `help` is the longer explanation, as a tooltip.
 */
export function SmallSwitch({
  label,
  help,
  on,
  onChange,
  disabled,
}: {
  label: string;
  help?: string | undefined;
  on: boolean;
  onChange: (on: boolean) => void;
  disabled?: boolean | undefined;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      class={`ui-small-switch${on ? " on" : ""}`}
      title={help}
      disabled={disabled}
      onClick={() => onChange(!on)}
    >
      <span class="ui-switch small" aria-hidden="true">
        <span />
      </span>
      <span class="ui-small-switch-label">{label}</span>
    </button>
  );
}

export interface ChoiceOption<T extends string> {
  id: T;
  title: string;
  description: string;
  icon?: JSX.Element;
  /** A small word on the card ("Recommended"). */
  badge?: string;
}

/** Big cards to pick from: one, or several when `multiple`. */
export function Choice<T extends string>({
  options,
  value,
  onChange,
  multiple,
}: {
  options: ChoiceOption<T>[];
  value: T[];
  onChange: (value: T[]) => void;
  multiple?: boolean;
}) {
  return (
    <div class="ui-choice" role={multiple ? "group" : "radiogroup"}>
      {options.map((o) => {
        const on = value.includes(o.id);
        return (
          <button
            key={o.id}
            type="button"
            aria-pressed={on}
            class={`ui-card${on ? " on" : ""}`}
            onClick={() =>
              onChange(
                multiple ? (on ? value.filter((v) => v !== o.id) : [...value, o.id]) : [o.id],
              )
            }
          >
            <span class="ui-card-head">
              {o.icon}
              <strong>{o.title}</strong>
              {o.badge && <span class="chip ok">{o.badge}</span>}
            </span>
            <span class="ui-help">{o.description}</span>
          </button>
        );
      })}
    </div>
  );
}

/** One of a `DropChoice`'s options: its value, its words, an optional line under them. */
export interface DropOption<T extends string> {
  id: T;
  label: string;
  hint?: string;
  /** The heading it sits under; a new heading starts where the group changes. */
  group?: string;
  /** More words a search matches (a model's id). */
  keywords?: string;
  /** In use now without being the chosen value (the composer's: the agent's model); drawn apart. */
  inUse?: boolean;
}

/**
 * A choice that opens a list (3.10): what the page uses instead of a native `<select>`, which no
 * page may show (the project's rule: our drawn controls only). A button with the chosen words
 * and a chevron; its list placed over the page (a bar clips what overflows it), with the keys a
 * list takes: arrows and Home/End move, Enter or Space choose, Esc and a click away close.
 */
export function DropChoice<T extends string>({
  value,
  options,
  onChange,
  label,
  title,
  class: c,
  disabled,
  search,
  current,
  onOpen,
  startOpen,
  onClose,
}: {
  value: T;
  options: DropOption<T>[];
  onChange: (value: T) => void;
  /** What is chosen (the button's and the list's accessible name). */
  label: string;
  title?: string;
  class?: string;
  disabled?: boolean;
  /** A search field on top of the list, with these words as its placeholder (long lists). */
  search?: string;
  /** The button's words when they differ from the chosen option's. */
  current?: string;
  /** Called as the list opens (to read the options again). */
  onOpen?: () => void;
  /** Open the list as soon as it is shown (a choice that appears after a button). */
  startOpen?: boolean;
  /** Called as the list closes, whether something was chosen or not. */
  onClose?: () => void;
}) {
  /** Where the list opens: under the button, from its left, or from its right near the edge. */
  const [at, setAt] = useState<{
    left?: number;
    right?: number;
    top?: number;
    bottom?: number;
    maxHeight: number;
    width: number;
  }>();
  const btn = useRef<HTMLButtonElement>(null);
  const list = useRef<HTMLDivElement>(null);
  const id = useId();
  const [query, setQuery] = useState("");
  const cur = options.find((o) => o.id === value) ?? options[0];
  const q = query.trim().toLowerCase();
  const shown = q
    ? options.filter((o) =>
        [o.label, o.hint ?? "", o.group ?? "", o.keywords ?? ""].some((w) =>
          w.toLowerCase().includes(q),
        ),
      )
    : options;
  const close = (focus = true) => {
    setAt(undefined);
    setQuery("");
    if (focus) btn.current?.focus();
    onClose?.();
  };
  const open = () => {
    onOpen?.();
    const r = btn.current?.getBoundingClientRect();
    const width = Math.max(r?.width ?? 0, 200);
    // Under the button, or over it when there is little room below (a composer at the bottom).
    const below = window.innerHeight - (r?.bottom ?? 0) - 12;
    const above = (r?.top ?? 0) - 12;
    const up = below < 260 && above > below;
    const room = Math.max(160, Math.min(up ? above : below, window.innerHeight * 0.7));
    const y = up
      ? { bottom: window.innerHeight - (r?.top ?? 0) + 4, maxHeight: room }
      : { top: (r?.bottom ?? 0) + 4, maxHeight: room };
    // Near the window's right edge the list grows leftwards from the button's right side.
    if ((r?.left ?? 0) + 280 > window.innerWidth)
      setAt({ right: Math.max(4, window.innerWidth - (r?.right ?? 0)), ...y, width });
    else setAt({ left: Math.max(4, r?.left ?? 0), ...y, width });
  };
  useEffect(() => {
    if (startOpen) open();
  }, []);
  useEffect(() => {
    if (!at) return;
    const on =
      list.current?.querySelector<HTMLElement>("[aria-checked=true]") ??
      list.current?.querySelector<HTMLElement>("button");
    on?.focus();
    // A long list opens at the chosen row, not at the top.
    on?.scrollIntoView?.({ block: "center" });
    const away = (e: PointerEvent) => {
      const n = e.target as Node;
      if (!list.current?.contains(n) && !btn.current?.contains(n)) close(false);
    };
    const gone = () => close(false);
    document.addEventListener("pointerdown", away, true);
    window.addEventListener("resize", gone);
    return () => {
      document.removeEventListener("pointerdown", away, true);
      window.removeEventListener("resize", gone);
    };
  }, [!!at]);
  const listKey = (e: KeyboardEvent) => {
    const items = [...(list.current?.querySelectorAll<HTMLElement>("button") ?? [])];
    const i = items.indexOf(document.activeElement as HTMLElement);
    const go = (n: number) => items[(n + items.length) % items.length]?.focus();
    if (e.key === "Escape" || e.key === "Tab") {
      // Esc closes the list only (the editor around it keeps its own Esc).
      e.stopPropagation();
      if (e.key === "Escape") e.preventDefault();
      return close(e.key === "Escape");
    }
    const typing = (e.target as HTMLElement).tagName === "INPUT";
    // A letter typed on a row goes to the search, as in any list with one.
    if (search && !typing && e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
      list.current?.querySelector<HTMLInputElement>(".ui-drop-search")?.focus();
      return;
    }
    const move: Record<string, () => void> = {
      ArrowDown: () => go(i + 1),
      ArrowUp: () => go(i - 1),
      ...(!typing && { Home: () => go(0), End: () => go(items.length - 1) }),
    };
    const f = move[e.key];
    if (!f) return;
    e.preventDefault();
    e.stopPropagation();
    f();
  };
  return (
    <span class={`ui-drop${c ? ` ${c}` : ""}`}>
      <button
        ref={btn}
        type="button"
        class="ui-drop-current"
        aria-haspopup="listbox"
        aria-expanded={!!at}
        aria-controls={at ? id : undefined}
        aria-label={`${label}: ${current ?? cur?.label ?? ""}`}
        title={title ?? label}
        disabled={disabled}
        onClick={() => (at ? close() : open())}
        onKeyDown={(e) => {
          if (!at && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
            e.preventDefault();
            e.stopPropagation();
            open();
          }
        }}
      >
        <span>{current ?? cur?.label}</span>
        <IconChevron open={!!at} size={12} />
      </button>
      {at && (
        <div
          ref={list}
          id={id}
          class="ui-drop-list"
          role="listbox"
          aria-label={label}
          style={{
            ...(at.right !== undefined ? { right: `${at.right}px` } : { left: `${at.left}px` }),
            ...(at.top !== undefined ? { top: `${at.top}px` } : { bottom: `${at.bottom}px` }),
            maxHeight: `${at.maxHeight}px`,
            minWidth: `${at.width}px`,
          }}
          onKeyDown={listKey}
        >
          {search && (
            <input
              class="ui-drop-search"
              type="search"
              aria-label={search}
              placeholder={search}
              value={query}
              onInput={(e) => setQuery((e.target as HTMLInputElement).value)}
            />
          )}
          {search && shown.length === 0 && <p class="ui-drop-none">{t("uiDropNone")}</p>}
          {shown.flatMap((o, i) => [
            ...(o.group && o.group !== shown[i - 1]?.group
              ? [
                  <div key={`g:${o.group}`} class="ui-drop-group" role="presentation">
                    {o.group}
                  </div>,
                ]
              : []),
            <button
              type="button"
              key={o.id}
              role="option"
              aria-selected={o.id === value}
              aria-checked={o.id === value}
              class={o.id === value ? "on" : o.inUse ? "use" : ""}
              {...(o.inUse && { "aria-current": "true" as const })}
              onClick={() => {
                close();
                if (o.id !== value) onChange(o.id);
              }}
            >
              <span class="ui-drop-mark" aria-hidden="true">
                {o.id === value && <IconCheck size={13} />}
              </span>
              <span class="ui-drop-words">
                <span>{o.label}</span>
                {o.hint && <small>{o.hint}</small>}
              </span>
            </button>,
          ])}
        </div>
      )}
    </span>
  );
}

/** Seconds left, in words: "less than a minute", "about 4 min", "about 1 h 20 min". */
export function timeLeft(seconds: number): string {
  if (seconds < 60) return t("uiLessThanMinute");
  const min = Math.round(seconds / 60);
  if (min < 60) return t("uiAboutMinutes", { min: String(min) });
  return t("uiAboutHours", { h: String(Math.floor(min / 60)), min: String(min % 60) });
}

/** What a progress says in words: amounts, speed and time left (bytes, or plain counts). */
export function progressText(p: JobProgress, unit: "bytes" | "count" = "bytes"): string {
  const amount = (n: number) => (unit === "bytes" ? bytes(n) : String(Math.round(n)));
  const parts = [
    p.total !== null ? t("uiOf", { done: amount(p.done), total: amount(p.total) }) : amount(p.done),
  ];
  if (p.rate !== null)
    parts.push(unit === "bytes" ? `${bytes(p.rate)}/s` : `${p.rate.toFixed(1)}/s`);
  if (p.secondsLeft !== null && p.total !== null && p.done < p.total)
    parts.push(timeLeft(p.secondsLeft));
  return parts.join(" · ");
}

/** A real progress bar with its words; without a total it moves without filling. */
export function Progress({
  progress,
  unit = "bytes",
}: {
  progress: JobProgress;
  unit?: "bytes" | "count";
}) {
  const pct =
    progress.total && progress.total > 0
      ? Math.min(100, Math.round((progress.done / progress.total) * 100))
      : null;
  return (
    <div class="ui-progress">
      <div
        class={`ui-bar${pct === null ? " busy" : ""}`}
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={pct ?? undefined}
        aria-label={progressText(progress, unit)}
      >
        <span style={pct === null ? undefined : { width: `${pct}%` }} />
      </div>
      <span class="ui-help">
        {pct !== null && `${pct}% · `}
        {progressText(progress, unit)}
      </span>
    </div>
  );
}

/** Options for experts, closed until opened. */
export function Advanced({ label, children }: { label?: string; children: ComponentChildren }) {
  return (
    <details class="ui-advanced">
      <summary>
        <IconChevron open={false} size={13} /> {label ?? t("uiAdvanced")}
      </summary>
      <div class="ui-advanced-body">{children}</div>
    </details>
  );
}

/** Follows a job until it ends (polls once a second); undefined until the first answer. */
export function useJob(id: string | undefined): Job | undefined {
  const [job, setJob] = useState<Job>();
  useEffect(() => {
    setJob(undefined);
    if (!id) return;
    let stop = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const tick = async () => {
      const j = await getApi()
        .job(id)
        .catch(() => undefined);
      if (stop) return;
      if (j) setJob(j);
      if (!j || j.state === "running") timer = setTimeout(() => void tick(), 1000);
    };
    void tick();
    return () => {
      stop = true;
      clearTimeout(timer);
    };
  }, [id]);
  return job;
}

/** Each step's mark: a dot (filled once done), a spinner while it runs, an X when it fails. The
 * step itself is lit by border and background, never ticked (the person's rule, 2026-11-06). */
const STEP_ICONS = {
  waiting: <span class="ui-dot" />,
  running: <IconSpinner size={14} />,
  done: <span class="ui-dot" />,
  failed: <IconX size={14} />,
  skipped: <span class="ui-dot" />,
} as const;

/**
 * A long action as people see it: its steps with what is happening now, the progress of the
 * running step, and at the end "done" or the error in plain words with the details below.
 */
export function JobView({
  job,
  cancellable,
  countSteps = [],
}: {
  job: Job;
  cancellable?: boolean;
  /** Steps whose progress counts things (conversations…), not bytes. */
  countSteps?: string[];
}) {
  return (
    <div class={`ui-job ${job.state}`} aria-live="polite">
      <strong>{tOptional(`job_${job.kind}`, job.vars) ?? job.kind}</strong>
      <ol class="ui-job-steps">
        {job.steps.map((s) => (
          <li key={s.id} class={s.state}>
            <span class="ui-job-icon">{STEP_ICONS[s.state]}</span>
            <span>
              {tOptional(`job_step_${s.id}`, job.vars) ?? s.id}
              {s.state === "skipped" && <span class="dim"> · {t("uiNotNeeded")}</span>}
              {s.progress && (
                <Progress
                  progress={s.progress}
                  unit={countSteps.includes(s.id) ? "count" : "bytes"}
                />
              )}
            </span>
          </li>
        ))}
      </ol>
      {job.state === "done" && <p class="notice ok">{t("uiDone")}</p>}
      {job.state === "cancelled" && <p class="notice">{t("uiCancelled")}</p>}
      {job.state === "failed" && job.error && (
        <div class="ui-job-error">
          <p class="notice error">
            <IconAlert size={14} />{" "}
            {(job.error.code && tOptional(`job_error_${job.error.code}`, job.vars)) ??
              t("uiFailedGeneric")}
          </p>
          <Advanced label={t("uiDetails")}>
            <pre>{job.error.message}</pre>
          </Advanced>
        </div>
      )}
      {cancellable && job.state === "running" && (
        <button
          type="button"
          class="link"
          onClick={() => void attempt(() => getApi().cancelJob(job.id))}
        >
          {t("cancel")}
        </button>
      )}
    </div>
  );
}

/** The QR code of an address, drawn here as SVG (no service sees the address); its code loads
 * with the first QR shown (3.5.11). */
export function Qr({ text, label }: { text: string; label: string }) {
  const [svg, setSvg] = useState<string>();
  useEffect(() => {
    let live = true;
    void import("qrcode-generator").then(({ default: qrcode }) => {
      const qr = qrcode(0, "M");
      qr.addData(text);
      qr.make();
      if (live) setSvg(qr.createSvgTag({ cellSize: 5, margin: 2, scalable: true }));
    });
    return () => {
      live = false;
    };
  }, [text]);
  return (
    <div
      class="qr"
      role="img"
      aria-label={label}
      // biome-ignore lint/security/noDangerouslySetInnerHtml: SVG made here from our own address.
      dangerouslySetInnerHTML={{ __html: svg ?? "" }}
    />
  );
}

/** A selectable square with its words: what the page uses instead of a check box (2026-11-03). */
export function Pick({
  on,
  onChange,
  children,
  small,
  disabled,
}: {
  on: boolean;
  onChange: (on: boolean) => void;
  children: ComponentChildren;
  small?: boolean;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      class={`pick-tile ${small ? "small" : ""} ${on ? "on" : ""}`}
      aria-pressed={on}
      disabled={disabled}
      onClick={() => !disabled && onChange(!on)}
    >
      <span>{children}</span>
    </button>
  );
}

/** What can take the focus inside `el`, in order (p3.5.11). */
export function focusables(el: HTMLElement): HTMLElement[] {
  return [
    ...el.querySelectorAll<HTMLElement>(
      'a[href], button, input, select, textarea, iframe, [tabindex], [contenteditable="true"]',
    ),
  ].filter(
    (x) =>
      x.tabIndex >= 0 &&
      !(x as HTMLButtonElement).disabled &&
      !x.closest("[hidden], [inert]") &&
      x.getAttribute("aria-hidden") !== "true",
  );
}

/** Tab and Shift+Tab stay inside the window: from the last item back to the first, and back. */
export function trapTab(e: KeyboardEvent, el: HTMLElement | null): void {
  if (!el) return;
  const all = focusables(el);
  const first = all[0];
  const last = all.at(-1);
  if (!first || !last) {
    e.preventDefault();
    el.focus();
    return;
  }
  const at = document.activeElement;
  if (e.shiftKey && (at === first || at === el || !el.contains(at))) {
    e.preventDefault();
    last.focus();
  } else if (!e.shiftKey && (at === last || !el.contains(at))) {
    e.preventDefault();
    first.focus();
  }
}

/** A window over the page, closed with its button, Escape or a click outside (2026-11-04). */
/** The windows open now, the last on top. */
const stack: object[] = [];

export function Modal({
  title,
  onClose,
  children,
  wide,
  icon,
  sub,
  foot,
  class: cls,
  locked,
}: {
  title: string;
  onClose: () => void;
  children: ComponentChildren;
  /** A wider window, for a model's details (2026-11-06). */
  wide?: boolean | undefined;
  /** A picture before the title (an agent's avatar, 2026-11-07). */
  icon?: ComponentChildren;
  /** A line under the title. */
  sub?: ComponentChildren;
  /** The window's buttons in a bar that stays at the bottom while the body scrolls. */
  foot?: ComponentChildren;
  class?: string | undefined;
  /** A window that does not close (G36.19, a mandatory update): no X, no veil, no Escape. */
  locked?: boolean | undefined;
}) {
  const [me] = useState(() => ({}));
  const lockedRef = useRef(locked);
  lockedRef.current = locked;
  const box = useRef<HTMLDivElement>(null);
  // What had the focus before the window, read at its first render (a field inside takes it in
  // its own effect, which runs before ours).
  const [before] = useState(() =>
    typeof document === "undefined" ? null : (document.activeElement as HTMLElement | null),
  );
  useEffect(() => {
    stack.push(me);
    // The focus goes into the window (unless a field inside already took it) and back to what had
    // it when the window closes (p3.5.11): a keyboard is never left at the top of the page.
    const el = box.current;
    if (el && !el.contains(document.activeElement))
      (focusables(el).find((x) => !x.classList.contains("ui-modal-x")) ?? el).focus();
    return () => {
      stack.splice(stack.indexOf(me), 1);
      const now = document.activeElement;
      const lost = !now || now === document.body || !!el?.contains(now) || !now.isConnected;
      if (lost && before?.isConnected && before !== document.body) before.focus();
    };
  }, []);
  useEffect(() => {
    // Only the window on top closes: Escape in the mailbox's window, opened from an automation
    // being written, must not throw the draft away.
    const esc = (e: KeyboardEvent) => {
      if (stack.at(-1) !== me) return;
      if (e.key === "Tab") trapTab(e, box.current);
      else if (e.key === "Escape" && !lockedRef.current) onClose();
    };
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [onClose]);
  return (
    <div class="ui-modal-back">
      {locked ? (
        <div class="ui-modal-veil" />
      ) : (
        <button type="button" class="ui-modal-veil" aria-label={t("close")} onClick={onClose} />
      )}
      <div
        class={`ui-modal${wide ? " wide" : ""}${foot ? " with-foot" : ""}${cls ? ` ${cls}` : ""}`}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        ref={box}
        tabIndex={-1}
      >
        {/* Title and X centred on one line in every window (2026-11-07). */}
        <header>
          {icon && <span class="ui-modal-ico">{icon}</span>}
          {sub ? (
            <span class="ui-modal-title">
              <strong>{title}</strong>
              <span class="ui-modal-sub">{sub}</span>
            </span>
          ) : (
            <strong>{title}</strong>
          )}
          {/* An X to close, as on phones (2026-11-04). */}
          {!locked && (
            <button type="button" class="ui-modal-x" aria-label={t("close")} onClick={onClose}>
              <IconX size={18} />
            </button>
          )}
        </header>
        <div class="ui-modal-body">{children}</div>
        {foot && <footer class="ui-modal-foot wz-acts">{foot}</footer>}
      </div>
    </div>
  );
}
