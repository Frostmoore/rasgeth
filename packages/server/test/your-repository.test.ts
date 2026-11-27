// The project's remotes in the agent's system prompt (3.12.10, the person: «il modello non vede le remotes
// configurate»: an agent said GitHub was not set up while the project pushed there through the egress proxy).
import { execFile } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { describe, expect, it } from "vitest";
import { describeRemote, yourRepository } from "../src/core.js";

const git = promisify(execFile);

describe("the agent's repository section (3.12.10)", () => {
  it("names Rasgeth's routes by service and repository, and never shows credentials", () => {
    expect(
      describeRemote("http://egress:3128/route/gitea/smp-webmaster/gaia-itas-plugin-wordpress.git"),
    ).toBe("Gitea, smp-webmaster/gaia-itas-plugin-wordpress");
    expect(
      describeRemote("http://egress:3128/route/github/Frostmoore/gaia-itas-plugin-wordpress.git"),
    ).toBe("GitHub, Frostmoore/gaia-itas-plugin-wordpress");
    expect(describeRemote("https://user:secret-token@git.example.org/a/b.git")).toBe(
      "https://git.example.org/a/b.git",
    );
  });

  it("lists every remote of the project's folder, or says there is none", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-remotes-"));
    try {
      await git("git", ["-C", dir, "init", "-q"]);
      expect(await yourRepository(dir)).toMatch(/no git remote yet/);
      await git("git", [
        "-C",
        dir,
        "remote",
        "add",
        "origin",
        "http://egress:3128/route/gitea/me/site.git",
      ]);
      await git("git", [
        "-C",
        dir,
        "remote",
        "add",
        "github",
        "https://me:tok@github.example/me/site.git",
      ]);
      const text = await yourRepository(dir);
      expect(text).toMatch(/^## Your repository/);
      expect(text).toContain("- `origin`: Gitea, me/site");
      expect(text).toContain("- `github`: https://github.example/me/site.git");
      expect(text).not.toContain("me:tok@");
      expect(text).toContain("git push <remote> <branch>");
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
});
