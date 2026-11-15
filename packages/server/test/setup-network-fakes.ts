// Fakes for the temporary network's tests (G40.3): the OS helper as redgiant-setup-ap answers.
import type { HelperOp, OsHelper } from "../src/os-helper.js";

/** What the machine answers to ap-status, as redgiant-setup-ap prints it. */
export const apStatus = (o: Record<string, unknown> = {}) => ({
  ok: true,
  active: true,
  mode: "setup",
  capable: "ok",
  pending: true,
  ssid: "RedGiant-Setup-1A2B",
  passphrase: "redgiant",
  address: "10.42.0.1",
  subnet: "10.42.0.0/24",
  since: 1_763_000_000,
  windowEnds: 1_763_001_800,
  trying: false,
  networks: [{ ssid: "Casa", security: "psk", signal: -45 }],
  lastTry: null,
  ...o,
});

/** A fake OS helper: answers ap-status with `status`, records every request. */
export function fakeHelper(status: () => Record<string, unknown> | null) {
  const calls: HelperOp[] = [];
  const helper: OsHelper = {
    how: "socket",
    call: async (o) => {
      calls.push(o);
      switch (o.op) {
        case "ap-status": {
          const s = status();
          if (!s) throw new Error("unknown_op");
          return s;
        }
        case "home-network-try":
          return "cable" in o
            ? { ok: true, state: "connected", address: "192.168.1.40" }
            : { ok: true, state: "trying" };
        case "https-status":
          return { ok: true, on: true, ca: "Q0EgUEVN" };
        default:
          return { ok: true };
      }
    },
  };
  return { helper, calls };
}
