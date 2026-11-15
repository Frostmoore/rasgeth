// @vitest-environment jsdom
// G40.3: the home network chosen from RedGiant OS's temporary network, for whoever has no app:
// the networks the machine saw, the cable, the error of the last try; nothing at home. No native
// checkboxes or radios.
import type { SetupNetworkInfo } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: unknown[] = [];
let info: SetupNetworkInfo;
const fakeApi = {
  setupNetwork: async () => info,
  setupNetworkHome: async (b: unknown) => {
    calls.push(b);
    return "cable" in (b as object)
      ? { state: "connected", address: "192.168.1.40" }
      : { state: "trying" };
  },
};
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));
const { SetupNetworkPanel } = await import("../src/components/OsSystem.js");

const status = (o: Partial<NonNullable<SetupNetworkInfo["status"]>> = {}) => ({
  active: true,
  mode: "setup" as const,
  capable: "ok" as const,
  pending: true,
  ssid: "RedGiant-Setup-1A2B",
  passphrase: "redgiant",
  address: "10.42.0.1",
  subnet: "10.42.0.0/24",
  since: 1,
  windowEnds: 2,
  trying: false,
  networks: [
    { ssid: "Casa Rossi", security: "psk", signal: -45 },
    { ssid: "Bar", security: "open", signal: -80 },
  ],
  lastTry: null,
  ...o,
});

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  info = { here: "setup", ssid: "RedGiant-Setup-1A2B", status: status() };
});
afterEach(cleanup);

describe("the home network from the temporary network (G40.3)", () => {
  it("lists what the machine saw, joins one with its password", async () => {
    const v = render(<SetupNetworkPanel />);
    await waitFor(() => expect(v.container.textContent).toContain("RedGiant-Setup-1A2B"));
    expect(v.container.textContent).toContain("Casa Rossi");
    expect(v.container.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
    fireEvent.click(v.getByText("Casa Rossi"));
    const pw = v.container.querySelector('input[type="password"]') as HTMLInputElement;
    fireEvent.input(pw, { target: { value: "una password" } });
    fireEvent.click(v.getByText("Usa questa rete"));
    await waitFor(() => expect(v.container.textContent).toContain("si collega a «Casa Rossi»"));
    expect(calls).toEqual([{ ssid: "Casa Rossi", password: "una password" }]);
  });

  it("uses the cable and says the address on the home network", async () => {
    const v = render(<SetupNetworkPanel />);
    await waitFor(() => expect(v.container.textContent).toContain("Uso il cavo"));
    fireEvent.click(v.getByText("Uso il cavo"));
    await waitFor(() => expect(v.container.textContent).toContain("http://192.168.1.40:7600"));
    expect(calls).toEqual([{ cable: true }]);
  });

  it("says why the last home network did not work, and maintenance in its own words", async () => {
    info = {
      here: "maintenance",
      ssid: "RedGiant-Setup-1A2B",
      status: status({
        mode: "maintenance",
        lastTry: { state: "failed", ssid: "Casa Rossi", error: "connect_failed", at: 1 },
      }),
    };
    const v = render(<SetupNetworkPanel />);
    await waitFor(() => expect(v.container.textContent).toContain("non trovava più la rete"));
    expect(v.container.textContent).toContain("non è riuscito a collegarsi a «Casa Rossi»");
  });

  it("shows nothing at home", async () => {
    info = { here: "home", status: status() };
    const v = render(<SetupNetworkPanel />);
    await new Promise((r) => setTimeout(r, 20));
    expect(v.container.textContent).toBe("");
  });
});
