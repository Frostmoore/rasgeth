// The name guard (plan 3.9.0, N1): which occurrences of the old names a person would see, as a
// table. Change the table first, then scripts/name-audit.mjs.

import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
// @ts-expect-error plain JavaScript, no types
import { auditText, globToRegExp, parseKeep, phaseOf, summarize } from "../name-audit.mjs";

interface Finding {
  path: string;
  line: number;
  token: string;
  kind: "visible" | "comment" | "internal" | "kept";
  group?: string;
  why?: string;
  phase: string;
}

const audit = (path: string, text: string, keep: unknown[] = []): Finding[] =>
  auditText(path, text, parseKeep(keep));
const kinds = (path: string, text: string, keep: unknown[] = []) =>
  audit(path, text, keep).map((f) => f.kind);

describe("name-audit: one line, one verdict", () => {
  // [what, path, text, the kind of each occurrence in order]
  const table: [string, string, string, Finding["kind"][]][] = [
    // Visible text: forbidden.
    ["a string", "packages/web/src/x.ts", 'const s = "Welcome to RedGiant";', ["visible"]],
    ["two words", "packages/web/src/x.ts", 'say("the Red Giant way");', ["visible"]],
    ["the app's old name", "apps/companion/lib/a.dart", "const t = 'RGCompanion';", ["visible"]],
    ["capitals alone", "packaging/os/x.sh", 'echo "REDGIANT OS"', ["visible"]],
    ["a file people download", "packages/server/src/u.ts", 'f("RedGiant-Setup.exe");', ["visible"]],
    [
      "the address on the network",
      "packages/web/src/x.ts",
      'go("https://redgiant.local");',
      ["visible"],
    ],
    [
      "the repository",
      "packages/server/src/u.ts",
      'const r = "Frostmoore/redgiant2";',
      ["visible"],
    ],
    [
      "the app's archive",
      "apps/companion/lib/b.dart",
      "'rgcompanion-linux-x64.tar.gz'",
      ["visible"],
    ],
    // biome-ignore lint/suspicious/noTemplateCurlyInString: a shell line, not a template
    ["the OS images", "packaging/os/build.sh", 'out="redgiant-os-${V}-lxc.tar.zst"', ["visible"]],
    [
      "the command's name",
      "packages/cli/package.json",
      '"redgiant-acp": "./dist/acp.js"',
      ["visible"],
    ],
    ["a // inside a string", "packages/web/src/x.ts", 'const u = "a // RedGiant";', ["visible"]],
    [
      "prose: a document",
      "docs/INSTALL.md",
      "Install RedGiant, then run redgiant serve.",
      ["visible", "visible"],
    ],
    ["prose: a page", "site/index.html", "<h1>RedGiant</h1>", ["visible"]],
    [
      "a shell script without extension",
      "packaging/os/rootfs/usr/lib/redgiant-os/redgiant-console",
      '#!/bin/sh\necho "Welcome to RedGiant"',
      ["visible"],
    ],
    ["Inno Setup", "packaging/windows/RedGiant.iss", "AppName=RedGiant", ["visible"]],
    // Comments: allowed.
    ["a line comment", "packages/web/src/x.ts", "// RedGiant keeps it", ["comment"]],
    ["after the code", "packages/web/src/x.ts", "const a = 1; // the RedGiant way", ["comment"]],
    ["after an address", "packages/web/src/x.ts", 'const u = "http://x"; // RedGiant', ["comment"]],
    [
      "a block comment",
      "packages/web/src/x.ts",
      "/**\n * RedGiant\n */\nconst a = 1;",
      ["comment"],
    ],
    ["a doc comment in Dart", "apps/companion/lib/a.dart", "/// RGCompanion's window", ["comment"]],
    ["a shell comment", "packaging/os/x.sh", "# RedGiant OS", ["comment"]],
    ["a YAML comment", ".github/workflows/ci.yml", "  # RedGiant's packages", ["comment"]],
    [
      "an Inno Setup comment",
      "packaging/windows/RedGiant.iss",
      "; RedGiant's installer",
      ["comment"],
    ],
    [
      "a C# comment",
      "packaging/windows/launcher/Updates.cs",
      "  // RedGiant-Setup.exe",
      ["comment"],
    ],
    ["an HTML comment", "docs/INSTALL.md", "<!-- RedGiant -->", ["comment"]],
    ["a cmd comment", "install.cmd", "rem RedGiant", ["comment"]],
    [
      "ARB metadata",
      "apps/companion/lib/l10n/app_en.arb",
      '"@x": {\n  "description": "RedGiant"\n},',
      ["comment"],
    ],
    [
      "a JSON $comment",
      "packaging/models/catalog.json",
      '  "$comment": "RedGiant\'s models",',
      ["comment"],
    ],
    [
      "a Jinja comment",
      "packages/server/templates/t.jinja",
      "{#- RedGiant's template #}",
      ["comment"],
    ],
    [
      "XML whatever its extension",
      "packaging/os/rootfs/etc/avahi/services/redgiant.service",
      '<?xml version="1.0"?>\n<!-- RedGiant OS -->',
      ["comment"],
    ],
    [
      "a sourced script without shebang",
      "packaging/os/rootfs/usr/lib/redgiant-os/redgiant-selftest-wifi",
      "# RedGiant OS self-test\nx=1",
      ["comment"],
    ],
    [
      "a file of // comments without extension",
      "packaging/os/rootfs/etc/apt/apt.conf.d/50redgiant-os",
      "// RedGiant OS: no recommended packages",
      ["comment"],
    ],
    ["a Caddyfile", "packaging/os/rootfs/etc/caddy/Caddyfile", "# RedGiant OS", ["comment"]],
    [
      "a patch: a comment it adds",
      "engine/llama-patches/0001-x.patch",
      "+// RedGiant (G27): the mask",
      ["comment"],
    ],
    [
      "a patch: a string it adds",
      "engine/llama-patches/0001-x.patch",
      '+  log("RedGiant");',
      ["visible"],
    ],
    [
      "a file the person copies and reads",
      "packaging/os/rootfs/usr/share/redgiant-os/x.txt",
      "# RedGiant OS: Wi-Fi",
      ["visible"],
    ],
    // The inside: allowed (decision «l'interno resta»).
    [
      "an environment variable",
      "packages/server/src/x.ts",
      "process.env.REDGIANT_URL",
      ["internal"],
    ],
    ["a package", "packages/web/src/x.ts", 'import { x } from "@redgiant/protocol";', ["internal"]],
    ["an identifier", "packages/server/src/x.ts", "class RedGiantCore {}", ["internal"]],
    [
      "a lower-case technical name",
      "packages/server/src/x.ts",
      'const dir = "redgiant";',
      ["internal"],
    ],
    ["a service", "packaging/os/x.sh", 'systemctl start "redgiant-stack.service"', ["internal"]],
    ["the data folder", "docs/INSTALL.md", "Your data stay in /var/lib/redgiant.", ["internal"]],
    ["the Docker folder", "docs/INSTALL.md", "cd ~/redgiant", ["internal"]],
    [
      "the images (choice 12)",
      "packaging/os/x.yaml",
      "image: ghcr.io/frostmoore/redgiant2-sandbox",
      ["internal"],
    ],
    [
      "an image by its name alone",
      ".github/workflows/images.yml",
      "IMAGE: redgiant2-engine-cuda",
      ["internal"],
    ],
    [
      "the extension's id",
      "packages/browser-extension/m.json",
      '"id": "keychain@redgiant.local"',
      ["internal"],
    ],
    [
      "the app's package",
      "apps/companion/lib/a.dart",
      "import 'package:rgcompanion/app.dart';",
      ["internal"],
    ],
    [
      "the Mac's ids",
      "packaging/mac/Info.plist",
      "<string>com.redgiant.app</string>",
      ["internal"],
    ],
    ["project folders", "packages/server/src/x.ts", 'join(dir, ".redgiant/plan.md")', ["internal"]],
    ["mDNS", "packaging/os/x.sh", "_redgiant._tcp", ["internal"]],
    ["the local TLS header", "packages/server/src/x.ts", '"X-RedGiant-Local-TLS"', ["internal"]],
    [
      "the Mac keychain's service",
      "packages/server/src/vault.ts",
      '"redgiant-vault"',
      ["internal"],
    ],
    [
      "the widgets' API",
      "packages/server/test/fixtures/widgets/w.html",
      'redgiant.sendMessage(x); on("redgiant:theme")',
      ["internal", "internal"],
    ],
    ["the widgets' API object", "packages/web/src/x.ts", "window.redgiant = api;", ["internal"]],
    // No name at all.
    ["nothing", "packages/web/src/x.ts", 'const s = "Rasgeth";', []],
  ];
  it.each(table)("%s", (_what, path, text, want) => {
    expect(kinds(path, text)).toEqual(want);
  });

  it("gives the line, the token and the phase", () => {
    const [f] = audit(
      "packaging/windows/RedGiant.iss",
      "[Setup]\nOutputBaseFilename=RedGiant-Setup",
    );
    expect(f).toMatchObject({ line: 2, token: "RedGiant-Setup", kind: "visible", phase: "N3" });
  });
});

describe("name-audit: a name that stays, with its reason (scripts/name-keep.json)", () => {
  const keep = [
    { path: "research/**", group: "history", why: "studies of the past" },
    { pattern: "RedGiant\\.Launcher", group: "internal-id", why: "the launcher's mutex" },
    { path: "packages/web/src/i18n.ts", key: "^news\\d", group: "history", why: "past news" },
  ];
  it("by path", () => {
    const [f] = audit("research/sparsity/README.md", "RedGiant", keep);
    expect(f).toMatchObject({ kind: "kept", group: "history", why: "studies of the past" });
  });
  it("by pattern: only the occurrence inside it", () => {
    const src = 'new Mutex("RedGiant.Launcher"); Title = "RedGiant";';
    expect(kinds("packaging/windows/launcher/RedGiant.cs", src, keep)).toEqual(["kept", "visible"]);
  });
  it("by key, also on the lines that continue the key's text", () => {
    const src = [
      "const en = {",
      '  news3812Team: "RedGiant in the app",',
      "  news3814EditorsText:",
      '    "Every editor of RedGiant",',
      '  stGenQ: "How do you want RedGiant?",',
      "};",
    ].join("\n");
    expect(kinds("packages/web/src/i18n.ts", src, keep)).toEqual(["kept", "kept", "visible"]);
    // The same key elsewhere is not kept: the entry names its file.
    expect(kinds("packages/web/src/other.ts", '  news3812Team: "RedGiant",', keep)).toEqual([
      "visible",
    ]);
  });
  it("keys in single quotes (Dart maps) and in JSON", () => {
    const k = [{ path: "**", key: "^news", group: "history", why: "past news" }];
    expect(kinds("apps/companion/lib/w.dart", "    'news323Text': 'RedGiant',", k)).toEqual([
      "kept",
    ]);
    expect(kinds("apps/companion/lib/l10n/app_en.arb", '  "news1": "RedGiant",', k)).toEqual([
      "kept",
    ]);
  });
  it("an entry without its reason, group, or place is refused", () => {
    expect(() => parseKeep([{ path: "a/**", group: "history" }])).toThrow(/why/);
    expect(() => parseKeep([{ path: "a/**", why: "x" }])).toThrow(/group/);
    expect(() => parseKeep([{ group: "g", why: "x" }])).toThrow(/path or pattern/);
    expect(() => parseKeep([{ path: "a", pattern: "(", group: "g", why: "x" }])).toThrow();
    expect(() => parseKeep({})).toThrow();
  });
  it("the repository's list is valid, and every entry has its reason", () => {
    const list = JSON.parse(readFileSync(new URL("../name-keep.json", import.meta.url), "utf8"));
    const parsed = parseKeep(list);
    expect(parsed.length).toBeGreaterThan(0);
    for (const e of list) expect(e.why.length).toBeGreaterThan(10);
  });
});

describe("name-audit: globs, phases, summary", () => {
  it.each([
    ["research/**", "research/a/b.md", true],
    ["research/**", "researchx/a.md", false],
    ["packages/*/test/**", "packages/web/test/a/b.ts", true],
    ["packages/*/test/**", "packages/web/src/test/a.ts", false],
    ["**/*.md", "README.md", true],
    ["**/*.md", "docs/a/INSTALL.md", true],
    [
      "apps/companion/lib/l10n/app_localizations*.dart",
      "apps/companion/lib/l10n/app_localizations_it.dart",
      true,
    ],
    ["a?c", "abc", true],
    ["a.c", "abc", false],
  ])("glob %s on %s: %s", (glob, path, want) => {
    expect(globToRegExp(glob).test(path)).toBe(want);
  });

  it.each([
    ["packages/web/src/i18n.ts", "N2"],
    ["apps/companion/lib/l10n/app_it.arb", "N2"],
    ["packages/telegram/src/texts.ts", "N2"],
    ["packaging/windows/RedGiant.iss", "N3"],
    ["apps/companion/windows/runner/Runner.rc", "N3"],
    ["packaging/mac/RedGiant.swift", "N4"],
    ["apps/companion/macos/Runner/Configs/AppInfo.xcconfig", "N4"],
    ["apps/companion/android/app/build.gradle.kts", "N5"],
    ["apps/companion/ios/Runner/Info.plist", "N5"],
    ["packaging/linux-app/rgcompanion.desktop", "N5"],
    ["apps/companion/lib/brand.dart", "N5"],
    ["packages/cli/src/cli.ts", "N6"],
    ["compose.yaml", "N6"],
    ["install.ps1", "N6"],
    ["packaging/os/rootfs/etc/issue.d/50-redgiant.issue", "N6"],
    ["packaging/os/README.md", "N6"],
    [".github/workflows/release.yml", "N7"],
    ["packaging/stores/stores.mjs", "N7"],
    ["docs/INSTALL.md", "N10"],
    ["site/download.html", "N10"],
    ["README.md", "N10"],
    ["packages/server/README.md", "N10"],
    ["engine/x.py", "other"],
  ])("%s is %s", (path, phase) => {
    expect(phaseOf(path)).toBe(phase);
  });

  it("counts the visible occurrences by phase and file, the rest by kind", () => {
    const findings = [
      ...audit("packages/web/src/i18n.ts", 'a("RedGiant"); b("RedGiant");\n// RedGiant'),
      ...audit("docs/INSTALL.md", "RedGiant"),
      ...audit("packages/server/src/x.ts", "process.env.REDGIANT_URL"),
    ];
    const s = summarize(findings);
    expect(s.visible).toBe(3);
    expect(s.byKind).toEqual({ visible: 3, comment: 1, internal: 1, kept: 0 });
    expect(s.phases.N2).toEqual({ count: 2, files: { "packages/web/src/i18n.ts": 2 } });
    expect(s.phases.N10).toEqual({ count: 1, files: { "docs/INSTALL.md": 1 } });
  });
});
