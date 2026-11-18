# Reaching Rasgeth from outside home

Rasgeth runs at home (a PC, a mini PC with Rasgeth OS, a container on Proxmox, Docker on a server). At home it answers
on `http://<address>:7600` and, on Rasgeth OS, on `https://rasgeth.local`. This document describes every way to reach
it from outside home: from the phone on mobile data, from the office, from a laptop on holiday.

It is written for people and for their agents: if you want to set this up (or build something on top of it), everything
Rasgeth already does is described here, with the files where it lives.

There are three situations. Pick the one that matches what you have:

1. [You already have your own infrastructure](#1-you-already-have-your-own-infrastructure) (a reverse proxy, a domain,
   a home DNS, Tailscale or a VPN): Rasgeth sees it and tells you what to add.
2. [You can install Tailscale or a similar app](#2-you-can-install-tailscale-or-a-similar-app) on your devices: the
   simplest safe way, nothing opened on the router.
3. [You have nothing](#3-you-have-nothing): Rasgeth starts the way out by itself (Tailscale, a Cloudflare Tunnel, or
   your own domain with Caddy).

Whatever the way: **from outside, Rasgeth asks for your password** (and, if you switched it on, the code of an
authenticator app). Apps, the command line and editors (ACP) use their own token instead.

## Before anything: the password

- The first access is created **from home**: until a password exists and the first start is complete, the page opened
  from the local network shows «Create your access» (`POST /api/auth/first-access`). From outside it says «The first
  access is created from home». The rule is a pure function, `packages/server/src/first-access.ts`: the connection and
  every address declared by the proxies in front (Cloudflare, `X-Real-IP`, each entry of `X-Forwarded-For`,
  `Forwarded`) must be private; Tailscale's addresses (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`) count as home.
  `REDGIANT_FIRST_ACCESS=anywhere` lifts the rule (only for installations set up by an administrator).
- Settings › Access from outside home asks for the password before any way out starts (`SetupService.startRemote`
  refuses with `no_password`), and offers the second check with an authenticator app.
- Sessions get longer while they are used: a device that stays in does not sign in again.

## 1. You already have your own infrastructure

Rasgeth notices what is already there (`packages/server/src/net-detect.ts`):

- a **reverse proxy** running on the same machine (Caddy, Traefik, Nginx, HAProxy…: `proxiesRunning`) or in front of it
  (`X-Forwarded-*` headers from a private address: `proxyInFront`);
- **Tailscale** on the machine (`tailscale status`: `parseTailscaleStatus`);
- the **home DNS** the machine uses (`localDnsServer`);
- the **name** you used to open the page, if it is not a `.local` one (`reachedAs`).

When the page was opened through a name of yours, Settings › Access from outside home says «You are already reachable
as `<name>`» and opens the guide «Already have your own infrastructure», filled with the machine's name, address and
port (`packages/web/src/components/OwnInfra.tsx`, pure blocks in `packages/web/src/own-infra.ts`; the same guide in
English in [INSTALL.md](INSTALL.md#already-have-your-own-infrastructure)). «Skip: I am reachable already»
(`PUT /api/setup/reachable`) turns off Rasgeth's invitations to set up its own ways, and links it sends (to chats,
emails) use your address.

### A reverse proxy (Caddy, Traefik, Nginx Proxy Manager…)

Point a name at Rasgeth's port, for example with Caddy:

```
rasgeth.example.org {
	reverse_proxy 192.168.1.67:7600
}
```

- WebSockets must pass (`/ws`); Caddy and Traefik do it by themselves, Nginx needs the `Upgrade` headers.
- **Forward authentication** (Authelia, Authentik…) is not needed: Rasgeth has its own password. If you put it in
  front anyway, leave out `/api/` and `/ws`, or apps, the command line and ACP editors (which use a token) stop working.
- A real case: Rasgeth on a Proxmox container (`192.168.1.67`) behind the Caddy of another machine, reached from
  outside through Tailscale, with no extra login.

### A home DNS (Pi-hole, AdGuard, the router)

Give Rasgeth a name in the DNS your devices use: `rasgeth.home.example.org → <the proxy's local address>`.

- Point it at the **local** address of the proxy, not at its Tailscale address (`100.x`): a device or a container that
  is not on Tailscale cannot reach that one.
- Some routers accept names only one by one (no wildcard).
- Some routers answer «no such name» to IPv6 (`AAAA`) questions for the names added by hand; a resolver that caches that
  answer then hides the IPv4 one too. Rasgeth OS turns off the negative cache
  (`/etc/systemd/resolved.conf.d/redgiant.conf`, `Cache=no-negative`); on other systems use the same setting.

### Your home services seen by Rasgeth (Gitea, a NAS…)

The other way round: Rasgeth must find **your** services by name (a Gitea for the code, a NAS for backups). The guide
«Your home services» explains which DNS Rasgeth uses, what to write in the router or the home DNS, and offers «Try a
name» (`POST /api/setup/net/probe`, `packages/server/src/net-probe.ts`): it resolves the name, opens `https://name/`
(HEAD, short timeouts, no body read) and says the result in plain words.

### Tailscale, WireGuard, ZeroTier already on your network

- **Tailscale on the Rasgeth machine**: `tailscale serve --bg --https=443 http://localhost:7600` gives it an HTTPS name in
  your tailnet.
- **Tailscale as a subnet router** on another machine: advertise the home network and approve the route; Rasgeth's local
  address works from every device of the tailnet.
- **WireGuard or ZeroTier**: the same idea, a private network that includes home; open Rasgeth at its local address.

### Check that it answers

```
curl -s https://rasgeth.example.org/api/health
```

answers `{"ok":true,…}`. In the guide, «Check from here» does the same from the browser.

## 2. You can install Tailscale or a similar app

The simplest safe way: a private network made of your own devices, nothing opened on the router, HTTPS included.

1. Make a Tailscale account and install the app on the devices you want to use (phone, laptop).
2. In Rasgeth, Settings › Access from outside home › **Tailscale**. Rasgeth starts its own `tailscale/tailscale:stable`
   container next to itself, shows the sign-in link (read from `tailscale status`), and, once you signed in, publishes
   itself with `tailscale serve` (steps `remote_image`, `remote_start`, `remote_login`, `remote_https`).
3. In Tailscale's DNS page switch on **MagicDNS** and **HTTPS Certificates**: Rasgeth then answers on
   `https://<machine>.<tailnet>.ts.net`, the address it uses for its links.

Alternatives with the same shape (WireGuard, ZeroTier, Headscale) work as in section 1: put Rasgeth's machine in the
private network and open its local address.

## 3. You have nothing

Rasgeth starts the way out by itself, as a container next to it (`packages/server/src/remote.ts`; route
`POST /api/setup/remote`, `{ "way": "tailscale" | "cloudflare" | "caddy" }`; `DELETE /api/setup/remote` closes every
way). Each one is a job with its steps, followed by the page.

| Way                                  | What you need                                   | Opened on the router | Container                                                |
| ------------------------------------ | ----------------------------------------------- | -------------------- | -------------------------------------------------------- |
| **Tailscale** (section 2)            | a free account and the app on your devices      | nothing              | `redgiant-tailscale` (`tailscale/tailscale:stable`)      |
| **Cloudflare Tunnel**                | a domain on Cloudflare and a tunnel token       | nothing              | `redgiant-cloudflared` (`cloudflare/cloudflared:latest`) |
| **Your domain with Caddy** (experts) | a domain pointing at your home's public address | ports 80 and 443     | `redgiant-caddy` (`caddy:2`)                             |

- **Cloudflare Tunnel**: create a tunnel in Cloudflare's Zero Trust dashboard (Networks › Tunnels), copy its token and
  choose a hostname of your domain. Rasgeth keeps the token in its keychain (never in a log or a file in clear), starts
  `cloudflared` and connects; the hostname becomes Rasgeth's public address. Anyone on the internet reaches the
  sign-in page, so the password (and the authenticator code) is what protects it.
- **Your domain with Caddy**: point the domain at your home's public address (a dynamic DNS if it changes), open ports
  80 and 443 on the router towards the Rasgeth machine, give Rasgeth the domain: Caddy gets the certificate by itself
  (step `remote_cert`). Only for people who know what opening ports means.

Whichever way runs, its address becomes Rasgeth's public address (`setPublicUrl`): links in chats and emails,
webhooks of automations, Git hooks use it.

## For agents implementing on top of this

- The rules about **who may sign in from where** live in one pure function (`first-access.ts`) tested as a table:
  change the table first.
- Secrets (the tunnel token, passwords) go through the keychain (`Vault.setSystem` with `usedBy`), never into
  configuration files, logs, events or answers.
- The ways out are containers next to Rasgeth on its Docker network, reaching it at `http://redgiant:7600`; on Rasgeth
  OS the HTTPS at home is a separate thing (Caddy of the system with a local CA, `redgiant-tls`).
- The page's texts go through `t()` in Italian and English; the guide's blocks are pure functions in `own-infra.ts`.
- Test with fakes: no real Tailscale, Cloudflare or DNS in tests (`pnpm test`); live checks only in `*.live.test.ts`.
