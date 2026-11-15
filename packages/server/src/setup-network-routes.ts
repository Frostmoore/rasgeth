// The temporary network's routes (G40.3), for the first start's page from RedGiant-Setup-XXXX
// (whoever has no app configures from the browser) and Settings:
//   GET  /api/setup-network/here   open: whether this page is on the temporary network (no secret)
//   GET  /api/setup-network        signed in: the network, the networks seen around, the last try
//   POST /api/setup-network/home   signed in: {cable: true} | {ssid, password?, hidden?}
// and the captive portal (a middleware): from the temporary network, a request for a name that
// is not RedGiant's goes to the first start's page.
import type { SetupNetworkHereInfo, SetupNetworkInfo } from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import { HelperError } from "./os-helper.js";
import { captiveRedirect, homeChoiceOf, type SetupNetwork } from "./setup-network.js";

/** The captive portal: registered before every other route. */
export function setupCaptive<E extends { Variables: any }>(
  app: Hono<E>,
  network: SetupNetwork | undefined,
  addressOf: (c: Context<E>) => string,
): void {
  if (!network?.available) return;
  app.use("*", async (c, next) => {
    const here = await network.here(addressOf(c));
    if (here === "home") return next();
    const status = await network.status();
    const to = captiveRedirect({
      host: c.req.header("host"),
      here,
      address: status?.address ?? "10.42.0.1",
    });
    // 302 with no cache: the probes must see it every time (and never a 204 or "Success").
    if (to) {
      c.header("cache-control", "no-store");
      return c.redirect(to, 302);
    }
    return next();
  });
}

export function setupNetworkRoutes<E extends { Variables: any }>(
  app: Hono<E>,
  network: SetupNetwork | undefined,
  addressOf: (c: Context<E>) => string,
): void {
  const hereOf = async (c: Context<E>): Promise<SetupNetworkHereInfo> => {
    const here = (await network?.here(addressOf(c))) ?? "home";
    const s = here === "home" ? null : await network?.status();
    return { here, ...(s?.ssid && { ssid: s.ssid }) };
  };
  app.get("/api/setup-network/here", async (c) => c.json(await hereOf(c), 200));
  app.get("/api/setup-network", async (c) => {
    const info: SetupNetworkInfo = {
      ...(await hereOf(c)),
      status: (await network?.status(true)) ?? null,
    };
    return c.json(info, 200);
  });
  app.post("/api/setup-network/home", async (c) => {
    const choice = homeChoiceOf(await c.req.json().catch(() => null));
    if (!choice)
      return c.json(
        { error: "A network name (and its password) or the cable", code: "bad_request" },
        400,
      );
    if (!network?.available)
      return c.json({ error: "No temporary network here", code: "not_installed" }, 400);
    try {
      return c.json(await network.tryHome(choice), 200);
    } catch (err) {
      if (err instanceof HelperError)
        return c.json({ error: err.message, code: err.code }, err.code === "busy" ? 409 : 400);
      throw err;
    }
  });
}
