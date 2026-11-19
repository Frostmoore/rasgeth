// G41.5d (A5) on the server: a timeline's named versions written beside it, listed the newest
// first, a name used twice in a minute kept apart, a version read back (and nothing outside its
// folder), the routes the editor calls, and an archived project's timeline left as it is.
import { mkdir, mkdtemp, readdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { newRgVideo, type RgVideo, readRgVideo, writeRgVideo } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { listVideoVersions, saveVideoVersion } from "../src/editor/video/versions.js";
import { startServer } from "./helpers.js";

const timeline = (name: string): RgVideo => {
  const d = newRgVideo({ width: 1080, height: 1920, aspect: "9:16" }, name);
  d.clips = [
    {
      id: "c1",
      track: "V1",
      start: 0,
      sourceRange: { start: 0, duration: 50 },
      ref: { media: "clip.mp4" },
      enabled: true,
      volume: 0,
      fadeIn: 0,
      fadeOut: 0,
      fit: "fill",
      crop: { x: 0.3, y: 0, w: 0.32, h: 1 },
    },
  ];
  return d;
};

let dirs: string[] = [];
afterEach(async () => {
  for (const d of dirs) await rm(d, { recursive: true, force: true });
  dirs = [];
});

describe("saveVideoVersion and listVideoVersions", () => {
  it("beside the timeline, the newest first, the same name in the same minute kept apart", async () => {
    const root = await mkdtemp(join(tmpdir(), "rg-versions-"));
    dirs.push(root);
    await mkdir(join(root, "video"));
    const abs = join(root, "video", "gita.rgvideo");
    await writeFile(abs, writeRgVideo(timeline("Gita")));
    expect(await listVideoVersions(abs, "video/gita.rgvideo")).toEqual([]);
    const at = new Date(2026, 10, 16, 15, 30, 5);
    const first = await saveVideoVersion({
      abs,
      path: "video/gita.rgvideo",
      doc: timeline("Gita"),
      name: "Prima bozza",
      reason: "manual",
      now: at,
    });
    expect(first).toEqual({
      path: "video/gita.versions/2026-11-16 1530 Prima bozza.rgvideo",
      name: "Prima bozza",
      at: at.toISOString(),
      reason: "manual",
      clips: 1,
    });
    const again = await saveVideoVersion({
      abs,
      path: "video/gita.rgvideo",
      doc: timeline("Gita"),
      name: "Prima bozza",
      reason: "manual",
      now: new Date(at.getTime() + 20_000),
    });
    expect(again.path).toBe("video/gita.versions/2026-11-16 1530 Prima bozza (2).rgvideo");
    const before = await saveVideoVersion({
      abs,
      path: "video/gita.rgvideo",
      doc: timeline("Gita"),
      name: "before assembly",
      reason: "before_assemble",
      now: new Date(2026, 10, 16, 16, 0),
    });
    // The copy is a timeline of its own, saying what it is a version of.
    const copy = readRgVideo(await readFile(join(root, before.path), "utf8"));
    expect(copy.version).toMatchObject({ of: "video/gita.rgvideo", reason: "before_assemble" });
    expect(copy.clips[0]?.crop).toEqual({ x: 0.3, y: 0, w: 0.32, h: 1 });
    // Something else in the folder is left out of the list, and never touched.
    await writeFile(join(root, "video", "gita.versions", "nota.txt"), "x");
    await writeFile(join(root, "video", "gita.versions", "2026-11-16 1700 rotto.rgvideo"), "{");
    const list = await listVideoVersions(abs, "video/gita.rgvideo");
    expect(list.map((v) => [v.name, v.reason])).toEqual([
      ["before assembly", "before_assemble"],
      ["Prima bozza", "manual"],
      ["Prima bozza", "manual"],
    ]);
    expect(await readdir(join(root, "video", "gita.versions"))).toHaveLength(5);
  });
});

describe("the versions' routes", () => {
  it("save, list and read; nothing outside the versions' folder; an archived project's stays", async () => {
    const s = await startServer([]);
    try {
      const root = await s.core.scopeFolder("me", "platform");
      await mkdir(root, { recursive: true });
      await writeFile(join(root, "film.rgvideo"), writeRgVideo(timeline("Film")));
      const file = { scope: "platform", path: "film.rgvideo" };
      const saved = await s.api<{ version: { path: string; name: string } }>(
        "POST",
        "/api/editor/video/versions/save",
        { ...file, name: "  Per Marco  " },
      );
      expect(saved.status).toBe(200);
      expect(saved.body.version.name).toBe("Per Marco");
      expect(saved.body.version.path).toMatch(
        /^film\.versions\/\d{4}-\d\d-\d\d \d{4} Per Marco\.rgvideo$/,
      );
      const list = await s.api<{ versions: { path: string }[] }>(
        "POST",
        "/api/editor/video/versions",
        file,
      );
      expect(list.body.versions.map((v) => v.path)).toEqual([saved.body.version.path]);
      const read = await s.api<{ doc: RgVideo }>("POST", "/api/editor/video/versions/read", {
        ...file,
        version: saved.body.version.path,
      });
      expect(read.body.doc.name).toBe("Film");
      expect(read.body.doc.version?.of).toBe("film.rgvideo");
      for (const version of [
        "film.rgvideo",
        "film.versions/../film.rgvideo",
        "altro.versions/x.rgvideo",
      ]) {
        const r = await s.api("POST", "/api/editor/video/versions/read", { ...file, version });
        expect(r.status).toBe(400);
      }
      const empty = await s.api("POST", "/api/editor/video/versions/save", { ...file, name: " " });
      expect(empty.status).toBe(400);

      // An archived project: its timeline gets no new version.
      const outside = await mkdtemp(join(tmpdir(), "rg-versions-old-"));
      dirs.push(outside);
      await writeFile(join(outside, "film.rgvideo"), writeRgVideo(timeline("Old")));
      await s.api("POST", "/api/projects", { name: "Old", path: outside });
      await s.core.archiveProject("me", "old", "human");
      const refused = await s.api("POST", "/api/editor/video/versions/save", {
        scope: "project:old",
        path: "film.rgvideo",
        name: "No",
      });
      expect(refused.status).toBeGreaterThanOrEqual(400);
      expect(await readdir(outside)).toEqual(["film.rgvideo"]);
    } finally {
      await s.close();
    }
  });
});
