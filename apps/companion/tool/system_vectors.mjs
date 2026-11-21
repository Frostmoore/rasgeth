// Writes test/fixtures/system_vectors.json from the page's own rules (G42.14): the blocks to copy
// for one's own infrastructure and «Try a name»'s verdict (packages/web/src/own-infra.ts, read as
// TypeScript by Node), the host's steps to pass a disk into a container (hostMountGuide, the
// protocol built), and QR codes as the page draws them (qrcode-generator, level M, the smallest
// version: its squares, row by row). test/system_vectors_test.dart checks the app's Dart against
// them.
//
//   pnpm install && pnpm build && node apps/companion/tool/system_vectors.mjs
import { createRequire } from "node:module";
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "../../..");
const oi = await import(pathToFileURL(join(repo, "packages/web/src/own-infra.ts")).href);
const host = await import(pathToFileURL(join(repo, "packages/protocol/dist/backup-host.js")).href);
const qrcode = createRequire(join(repo, "packages/web/package.json"))("qrcode-generator");

const datas = [
  ["", "", null],
  ["rasgeth.home.example.com", "192.168.1.20", 7600],
  ["mio.dominio.it", "10.0.0.5", 8443],
  [" rasgeth.local ", " 192.168.50.7 ", 0],
  ["solo", "fd00::1", 70000],
];
const infra = datas.map(([name, address, port]) => {
  const d = oi.infraData(name, address, port);
  return {
    name,
    address,
    port,
    data: d,
    parent: oi.parentDomain(d.name),
    subnet: oi.subnetOf(d.address),
    caddy: oi.caddyBlock(d),
    caddyWildcard: oi.caddyWildcardBlock(d),
    traefik: oi.traefikBlock(d),
    forwardAuth: oi.caddyForwardAuthBypass(d),
    serve: oi.tailscaleServe(d),
    subnetUp: oi.tailscaleSubnet(d),
    dnsmasq: oi.dnsmasqWildcard(d),
    health: oi.healthCheck(oi.reachUrl(d.name)),
    healthHttp: oi.healthCheck(`${oi.reachUrl(d.name, false)}/`),
  };
});
const homes = [
  ["", ""],
  ["Git.Home.Example.com", "192.168.1.12"],
  [" nas.casa ", " 10.1.1.1 "],
].map(([name, proxy]) => {
  const h = oi.homeService(name, proxy);
  return {
    name,
    proxy,
    service: h,
    hosts: oi.homeHostsLine(h),
    dnsmasq: oi.homeDnsmasq(h),
    lookup: oi.homeLookup(h),
  };
});
const probes = [
  { name: "git.home", address: null, reachable: false, status: null, why: "not_found" },
  { name: "git.home", address: null, reachable: false, status: null, why: "dns_failed" },
  { name: "git.home", address: "192.168.1.12", reachable: true, status: 200, why: "ok" },
  { name: "git.home", address: "192.168.1.12", reachable: true, status: null, why: "tls" },
  { name: "git.home", address: "100.80.1.2", reachable: false, status: null, why: "unreachable" },
  { name: "git.home", address: "100.130.1.2", reachable: false, status: null, why: "timeout" },
  { name: "git.home", address: "fd7a:115c:a1e0::1", reachable: false, status: null, why: "timeout" },
  { name: "git.home", address: "192.168.1.12", reachable: false, status: 502, why: "unreachable" },
].map((p) => ({ probe: p, verdict: oi.probeVerdict(p) }));
const guides = [
  { kind: "proxmox", name: "Tech", device: "/dev/sdb1", containerId: "105" },
  { kind: "proxmox", name: "Tech" },
  { kind: "proxmox", name: "WD-Elements", device: "/dev/disk/by-uuid/5E3A-91F0", unprivileged: false, mp: 2 },
  { kind: "docker", name: "Tech", device: "/dev/sdc1", base: "/data/backups/" },
  { kind: "other", name: "Tech" },
  { kind: "proxmox", name: "../x" },
  { kind: "proxmox", name: "Tech", device: "/etc/passwd" },
  { kind: "proxmox", name: "Tech", containerId: "12" },
  { kind: "proxmox", name: "Tech", mp: 300 },
].map((input) => ({ input, guide: host.hostMountGuide(input) }));
// QR codes: short and long, to reach several versions (1 to 12 and the alignment patterns).
const texts = [
  "a",
  "https://rasgeth.local",
  "http://192.168.1.50/redgiant-ca.crt",
  "https://rasgeth.tail1234.ts.net",
  "otpauth://totp/Rasgeth:local?secret=JBSWY3DPEHPK3PXP&issuer=Rasgeth",
  `https://example.com/${"x".repeat(90)}`,
  `https://example.com/${"y".repeat(140)}`,
  `https://example.com/${"z".repeat(200)}`,
  `https://example.com/${"w".repeat(300)}`,
];
const qrs = texts.map((text) => {
  const q = qrcode(0, "M");
  q.addData(text);
  q.make();
  const n = q.getModuleCount();
  const rows = [];
  for (let r = 0; r < n; r++) {
    let line = "";
    for (let c = 0; c < n; c++) line += q.isDark(r, c) ? "1" : "0";
    rows.push(line);
  }
  return { text, rows };
});
writeFileSync(
  join(here, "../test/fixtures/system_vectors.json"),
  `${JSON.stringify({ infra, homes, probes, guides, qrs }, null, 1)}\n`,
);
console.log(`system vectors: ${infra.length} infra, ${guides.length} guides, ${qrs.length} QR`);
