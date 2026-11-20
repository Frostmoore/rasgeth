// 3.10, video part 2, in the inspector: the clip's speed (0.5×, 1×, 2×) and still frame; the
// picture in a box (picture in picture) with simple keys at the playhead; a simple colour
// correction (exposure, contrast, saturation, temperature) and a `.cube` LUT of the project; the
// volume's keys; the music's beats (found, cuts put on them, removed). Every change is one of the
// protocol's pure edits, so the agent makes the same with canvas_edit.
import {
  boxAt,
  clipEnd,
  cutsToBeats,
  type RgVideo,
  setBeats,
  setClipKey,
  setClipProps,
  type VideoBox,
  type VideoClip,
  type VideoColor,
  type VideoEdit,
  volumeAt,
} from "@redgiant/protocol";
import { lang, t } from "../../../i18n.js";
import { IconClose, IconMusic, IconPlus } from "../../../icons.js";
import { askText } from "../../dialogs.js";
import { Seg } from "../../SettingsKit.js";
import { Toggle } from "../../ui.js";
import { Dial } from "./Inspector.js";

type Commit = (next: RgVideo, what: VideoEdit, select?: string[]) => boolean;

const pct = (v: number) => `${Math.round(v * 100)}%`;
const signed = (v: number, it: boolean) => {
  const s = (Math.round(v * 100) / 100).toString();
  return `${v > 0 ? "+" : ""}${it ? s.replace(".", ",") : s}`;
};
const SPEEDS = ["0.5", "1", "2"] as const;

/** Where the playhead is in the clip (a frame of it), or undefined outside it. */
const inside = (c: VideoClip, playhead: number) =>
  playhead >= c.start && playhead < clipEnd(c) ? playhead - c.start : undefined;

/** Speed and still frame. */
export function SpeedSection({
  doc,
  clip: c,
  commit,
  audio,
}: {
  doc: RgVideo;
  clip: VideoClip;
  commit: Commit;
  audio: boolean;
}) {
  const sp = String(c.speed ?? 1);
  return (
    <section class="ve-insp-sec" aria-label={t("veSpeed")}>
      <span class="ve-label">{t("veSpeed")}</span>
      <Seg
        label={t("veSpeed")}
        value={(SPEEDS as readonly string[]).includes(sp) ? sp : ""}
        options={[
          ["0.5", t("veSpeedSlow")],
          ["1", t("veSpeedNormal")],
          ["2", t("veSpeedFast")],
        ]}
        onChange={(v) =>
          commit(setClipProps(doc, [c.id], { speed: v === "1" ? null : Number(v) }), "props")
        }
      />
      {!audio && (
        <Toggle
          label={t("veFreeze")}
          description={t("veFreezeHelp")}
          checked={!!c.freeze}
          onChange={(on) => commit(setClipProps(doc, [c.id], { freeze: on }), "props")}
        />
      )}
    </section>
  );
}

/** The picture in a box, with keys at the playhead. */
export function BoxSection({
  doc,
  clip: c,
  playhead,
  commit,
}: {
  doc: RgVideo;
  clip: VideoClip;
  playhead: number;
  commit: Commit;
}) {
  const at = inside(c, playhead);
  const keys = c.boxKeys ?? [];
  const on = !!c.box || keys.length > 0;
  const now = boxAt(c, at ?? 0);
  const keyHere = at !== undefined && keys.some((k) => k.at === at);
  /** A change of the box: at the playhead when the clip has keys there or anywhere, else the box. */
  const set = (b: VideoBox) =>
    keys.length && at !== undefined
      ? commit(setClipKey(doc, c.id, "box", playhead, b), "keys")
      : commit(setClipProps(doc, [c.id], { box: b }), "props");
  return (
    <section class="ve-insp-sec" aria-label={t("veBox")}>
      <Toggle
        label={t("veBox")}
        description={t("veBoxHelp")}
        checked={on}
        onChange={(v) =>
          commit(
            setClipProps(
              doc,
              [c.id],
              v ? { box: { x: 0.75, y: 0.25, scale: 0.33 } } : { box: null, boxKeys: null },
            ),
            "props",
          )
        }
      />
      {on && (
        <>
          <Dial
            label={t("veBoxX")}
            value={Math.round(now.x * 100) / 100}
            min={0}
            max={1}
            step={0.01}
            format={pct}
            onCommit={(x) => set({ ...now, x })}
          />
          <Dial
            label={t("veBoxY")}
            value={Math.round(now.y * 100) / 100}
            min={0}
            max={1}
            step={0.01}
            format={pct}
            onCommit={(y) => set({ ...now, y })}
          />
          <Dial
            label={t("veBoxScale")}
            value={Math.round(now.scale * 100) / 100}
            min={0.1}
            max={1}
            step={0.01}
            format={pct}
            onCommit={(scale) => set({ ...now, scale })}
          />
          <div class="ve-key-row">
            <span class="dim ve-small">
              {keys.length ? t("veKeys", { n: String(keys.length) }) : t("veKeysNone")}
            </span>
            {at !== undefined && !keyHere && (
              <button
                type="button"
                class="vw-btn small"
                onClick={() => commit(setClipKey(doc, c.id, "box", playhead, now), "keys")}
              >
                <IconPlus size={13} /> {t("veKeyAdd")}
              </button>
            )}
            {keyHere && (
              <button
                type="button"
                class="vw-btn small"
                onClick={() => commit(setClipKey(doc, c.id, "box", playhead, null), "keys")}
              >
                <IconClose size={13} /> {t("veKeyRemove")}
              </button>
            )}
          </div>
        </>
      )}
    </section>
  );
}

const NO_COLOR: VideoColor = { exposure: 0, contrast: 0, saturation: 0, temperature: 0 };

/** Colour correction and LUT. */
export function ColorSection({
  doc,
  clip: c,
  commit,
}: {
  doc: RgVideo;
  clip: VideoClip;
  commit: Commit;
}) {
  const it = lang.value === "it";
  const k = c.color ?? NO_COLOR;
  const set = (p: Partial<VideoColor>) =>
    commit(setClipProps(doc, [c.id], { color: { ...k, ...p } }), "color");
  const dial = (key: keyof VideoColor, min: number, max: number, step: number) => (
    <Dial
      label={t(`veColor_${key}`)}
      value={k[key]}
      min={min}
      max={max}
      step={step}
      format={(v) => signed(v, it)}
      onCommit={(v) => set({ [key]: v })}
    />
  );
  const pickLut = async () => {
    const path = await askText(t("veLutPick"), c.lut ?? "", { label: t("veLutPath") });
    const p = path?.trim().replace(/\\/g, "/").replace(/^\/+/, "");
    if (!p) return;
    if (!/\.cube$/i.test(p) || p.split("/").includes("..")) return;
    commit(setClipProps(doc, [c.id], { lut: p }), "color");
  };
  return (
    <section class="ve-insp-sec" aria-label={t("veColor")}>
      <span class="ve-label">{t("veColor")}</span>
      {dial("exposure", -2, 2, 0.1)}
      {dial("contrast", -1, 1, 0.05)}
      {dial("saturation", -1, 1, 0.05)}
      {dial("temperature", -1, 1, 0.05)}
      <div class="ve-key-row">
        {c.color && (
          <button
            type="button"
            class="vw-btn small"
            onClick={() => commit(setClipProps(doc, [c.id], { color: null }), "color")}
          >
            {t("veColorReset")}
          </button>
        )}
        <button type="button" class="vw-btn small" onClick={() => void pickLut()}>
          {c.lut ? t("veLutChange") : t("veLutAdd")}
        </button>
        {c.lut && (
          <button
            type="button"
            class="vw-btn small"
            title={c.lut}
            onClick={() => commit(setClipProps(doc, [c.id], { lut: null }), "color")}
          >
            <IconClose size={13} /> {t("veLutRemove", { name: c.lut.split("/").pop() ?? c.lut })}
          </button>
        )}
      </div>
    </section>
  );
}

/** The volume: one value, or keys at the playhead. */
export function VolumeKeys({
  doc,
  clip: c,
  playhead,
  commit,
  format,
}: {
  doc: RgVideo;
  clip: VideoClip;
  playhead: number;
  commit: Commit;
  format: (v: number) => string;
}) {
  const at = inside(c, playhead);
  const keys = c.volumeKeys ?? [];
  const now = volumeAt(c, at ?? 0);
  const keyHere = at !== undefined && keys.some((k) => k.at === at);
  return (
    <>
      <Dial
        label={t("veVolume")}
        value={Math.max(-30, Math.min(12, Math.round(now * 2) / 2))}
        min={-30}
        max={12}
        step={0.5}
        format={format}
        onCommit={(v) =>
          keys.length && at !== undefined
            ? commit(setClipKey(doc, c.id, "volume", playhead, v), "keys")
            : commit(setClipProps(doc, [c.id], { volume: v }), "props")
        }
      />
      <div class="ve-key-row">
        <span class="dim ve-small">
          {keys.length ? t("veKeys", { n: String(keys.length) }) : t("veKeysNone")}
        </span>
        {at !== undefined && !keyHere && (
          <button
            type="button"
            class="vw-btn small"
            onClick={() => commit(setClipKey(doc, c.id, "volume", playhead, now), "keys")}
          >
            <IconPlus size={13} /> {t("veKeyAdd")}
          </button>
        )}
        {keyHere && (
          <button
            type="button"
            class="vw-btn small"
            onClick={() => commit(setClipKey(doc, c.id, "volume", playhead, null), "keys")}
          >
            <IconClose size={13} /> {t("veKeyRemove")}
          </button>
        )}
      </div>
    </>
  );
}

/** The music's beats: found in this clip, cuts put on them, removed. */
export function BeatsSection({
  doc,
  clip: c,
  commit,
  busy,
  onFind,
}: {
  doc: RgVideo;
  clip: VideoClip;
  commit: Commit;
  busy: boolean;
  onFind: () => void;
}) {
  const n = doc.beats?.length ?? 0;
  const fps = doc.format.rate.num / doc.format.rate.den;
  const mine = doc.beatsOf === c.id;
  return (
    <section class="ve-insp-sec" aria-label={t("veBeats")}>
      <span class="ve-label">{t("veBeats")}</span>
      <p class="dim ve-small">
        {n ? t(mine ? "veBeatsHere" : "veBeatsOther", { n: String(n) }) : t("veBeatsNone")}
      </p>
      <div class="ve-key-row">
        <button type="button" class="vw-btn small" disabled={busy} onClick={onFind}>
          <IconMusic size={13} /> {t(busy ? "veBeatsFinding" : "veBeatsFind")}
        </button>
        {n > 0 && (
          <button
            type="button"
            class="vw-btn small"
            title={t("veBeatsCutHint")}
            onClick={() =>
              commit(cutsToBeats(doc, "V1", Math.max(1, Math.round(fps / 4))), "beats")
            }
          >
            {t("veBeatsCut")}
          </button>
        )}
        {n > 0 && (
          <button
            type="button"
            class="vw-btn small"
            onClick={() => commit(setBeats(doc, null), "beats")}
          >
            <IconClose size={13} /> {t("veBeatsRemove")}
          </button>
        )}
      </div>
    </section>
  );
}
