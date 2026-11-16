// Messages sealed by the server's own code (packages/server/src/push/ece.ts, built in dist), for
// the app's decryption tests (G40.10): a device's fixed keys, and the notices `pushFor` makes for
// a request, a critical request, its withdrawal and the test, each encrypted as the server sends
// them (a fresh salt and key every time).
//   pnpm --filter @redgiant/server build   (once)
//   node apps/companion/tool/push_vectors.mjs > apps/companion/test/fixtures/push_vectors.json
import { createECDH } from "node:crypto";
import { pushFor, pushTest, pushWithdrawal } from "../../../packages/protocol/dist/index.js";
import { b64u, encrypt } from "../../../packages/server/dist/push/ece.js";

const ua = createECDH("prime256v1");
ua.setPrivateKey(Buffer.alloc(32, 0x2a));
const auth = Buffer.alloc(16, 0x11);
const keys = { p256dh: b64u(ua.getPublicKey()), auth: b64u(auth) };

const info = (over) => ({
  requestId: "r1",
  agentId: "a0",
  agentName: "God",
  sessionId: "s1",
  projectId: null,
  tool: "run_command",
  input: { command: "npm install" },
  reasons: ["installs packages"],
  danger: [],
  createdAt: "2026-11-16T10:00:00.000Z",
  ...over,
});

const notices = {
  request: pushFor({ type: "approval", info: info() }, "it", "RedGiant di casa"),
  critical: pushFor(
    {
      type: "approval",
      info: info({
        requestId: "r2",
        input: { command: "rm -rf /" },
        danger: ["critical-delete"],
        critical: [{ id: "critical-delete", action: "delete-disk", target: "/" }],
      }),
    },
    "en",
    "Home",
  ),
  withdrawal: pushWithdrawal("r1", "app (Pixel)", "it", "RedGiant di casa"),
  test: pushTest("it", "RedGiant di casa", "2026-11-16T10:00:00.000Z"),
};

const out = {
  device: { d: b64u(ua.getPrivateKey()), auth: b64u(auth), p256dh: keys.p256dh },
  messages: Object.fromEntries(
    Object.entries(notices).map(([k, n]) => [
      k,
      { notice: n, body: b64u(encrypt(Buffer.from(JSON.stringify(n)), keys)) },
    ]),
  ),
};
console.log(JSON.stringify(out, null, 2));
