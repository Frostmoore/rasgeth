# RGCompanion

The RedGiant app (G40, 3.8): one Flutter project for Android, iOS, Windows, macOS and Linux. It is
an extra: everything still works from the browser. On computers the launchers stay the keeper of
the local server (start, updates, tray); the app is the window.

- Flutter **3.47.3** (Dart 3.13.3), the same on Rig, in the CI (`.github/workflows/companion.yml`)
  and for local checks.
- `lib/api`: the client of the app's protocol, the same routes as the page.
  - `transport.dart`: how a RedGiant is reached, one pure rule (`transportFor`): plain http only
    to this machine; https trusting only RedGiant's local CA once the app has it (or the system's
    roots for a proxy or Tailscale); any other http address (the temporary network 10.42.0.1, a
    RedGiant without HTTPS) through the setup channel, never in clear.
  - `setup_channel.dart`: the app's side of `/api/setup-channel`, the nodes' handshake in `setup`
    mode (ed25519, X25519, ChaCha20-Poly1305 with counters, package `cryptography`): RedGiant's
    key pinned at first use, the password signed in inside it, the device token and the local CA
    handed back encrypted.
  - `discovery.dart`: `_redgiant._tcp` with bonsoir (the system's own mDNS service on all five).
  - `servers.dart`: the RedGiants the app knows (home, work…: address, pinned key, local CA) and
    the settings kept between starts; tokens and the app's own key in the keystore
    (`flutter_secure_storage`).
  - `live.dart`, `live_model.dart`: `/ws` with the device token (heartbeat, reconnection that
    follows again from the last event), requests, counters, conversations streaming, the mascots'
    states as the page's `mascot-state.ts`.
  - `conversation.dart`: sessions, events and `buildItems`, requests (critical ones), tasks.
  - `settings_types.dart`, `names.dart`, `web_settings.dart` (G40.8): what the first start and
    the settings read (the temporary network, updates with 3.8.1's bar and steps when the server
    has them, devices, the model, the voice, the access from outside); the readable name (never a
    container's id); «All settings» (the page's Settings in a WebView with the device's token in
    the fragment, `#token=…&open=settings`, never the query; a certificate goes on only when it
    is the very one checked against the local CA; Windows and Linux open the browser without the
    token; never over plain http on the network).
- `lib/setup` (G40.8): the first start from the app.
  - `wifi.dart`: RedGiant-Setup-XXXX (password `redgiant`) joined system by system: Android
    `WifiNetworkSpecifier` with the prefix (MainActivity.kt: a network without internet bound to
    the app alone; `NEARBY_WIFI_DEVICES` on 13+, the location only up to 12L), iOS
    `NEHotspotConfiguration` with the prefix, `joinOnce` (AppDelegate.swift, the Hotspot
    Configuration entitlement in `Runner.entitlements`), Windows `netsh wlan` with a temporary
    profile (added only when the person has none for that network, deleted after, the network
    before comes back), Linux `nmcli` with a connection of our own (never the default route,
    deleted after); macOS and the rest by hand, with the name and the password on screen.
    Programs run without a shell, names checked first.
  - `first_start.dart`: the flow: the setup channel (key pinned at first use), the access (the
    password inside the channel), the device token and the local CA, the home network (the
    networks RedGiant saw, or the cable), then the wait while RedGiant moves: the app leaves the
    temporary network, finds RedGiant at home with the same key (the address it said, mDNS,
    redgiant.local), and when it is not there goes back to the temporary network for the reason
    («try and come back»). Then the languages, a way of thinking (Claude or ChatGPT
    subscription, a provider's key), the names, and the first start is completed. The password is
    kept in memory only while the flow runs.
- `lib/mascot`: the agents' mascots, drawn from the server's SVG (`@redgiant/mascot`), cut into
  layers and moved like the page's CSS; nothing moves with «Reduce motion».
- `lib/theme`: the page's colours (`packages/web/src/styles.css`), light, dark or the system's.
- `lib/l10n`: Italian and English (ARB, `flutter gen-l10n`; the generated files are in git).
- `lib/screens`: proposal A, «La squadra» (Team | Chat | For you | Activity | You, with the Chat's
  field over the bar); a conversation (`conversation_screen.dart`), the Canvas (images, SVG, PDF
  with pdfx, Markdown natively; HTML in an isolated WebView: a document of ours with a CSP that
  allows no network, the artifact in `<iframe sandbox="allow-scripts allow-forms" srcdoc>`;
  Windows and Linux show the source until G40.12), a critical request's own screen; the first
  start (`first_start_screen.dart`) and «Settings of <name>» in You (`server_settings_screen.dart`,
  `full_settings_screen.dart`).
- `lib/ui/markdown.dart`: Markdown without raw HTML nor remote images, links only http(s) and
  mailto after a yes, task lists with drawn marks.
- Android: `res/xml/network_security_config.xml` allows clear text only to 10.42.0.1 (the platform's
  stacks; the Dart connections follow `transportFor`).

```sh
flutter pub get
flutter analyze
flutter test                       # goldens: drawn on Linux
flutter build linux|windows|macos|apk|ios
```

Tests: `test/` runs everywhere (a fake RedGiant on localhost with `/ws`, the setup channel's
vectors recorded with node:crypto by `tool/setup_vectors.mjs`, the screens). Against a real
RedGiant (the monorepo's demo server, FakeProvider, no real model):

```sh
DEMO_PASSWORD=companion-test-1 DEMO_HOST=127.0.0.1 DEMO_REQUESTS=1 \
  node packages/web/scripts/demo-server.mjs 7651 &
RG_LIVE_URL=http://127.0.0.1:7651 flutter test test/live_server_test.dart
```

The first start against a RedGiant never set up, with RedGiant OS's temporary network acted out
by the demo (`DEMO_SETUP_AP=1`: ap-status, home-network-try, a Wi-Fi password `sbagliata` that
fails; no real network is touched, the Wi-Fi joining is a fake):

```sh
DEMO_FRESH=1 DEMO_SETUP_AP=1 DEMO_HOST=127.0.0.1 node packages/web/scripts/demo-server.mjs 7652 &
RG_SETUP_URL=http://127.0.0.1:7652 flutter test test/first_start_live_test.dart
```

The Linux app driven through its screens against the demo, with screenshots, in the agents'
Docker: `bash tool/linux_shots.sh <folder> [test]` (see the script; the first start with
`RG_DEMO_ENV="DEMO_FRESH=1 DEMO_SETUP_AP=1"` and `integration_test/first_start_shots_test.dart`).

Mascot fixtures (`test/fixtures/mascots.json`) come from the library:
`pnpm build && node apps/companion/tool/mascot_fixtures.mjs`. The icons come from
`assets/icon/rgcompanion.svg`: `flutter test tool/make_icons_test.dart`.

Linux builds need `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev` (GStreamer for reading answers aloud; «press and talk»
records with `parecord` from pulseaudio-utils at run time).
On Severino the Linux build runs in the agents' Docker with the image
`rgcompanion-linux-build:trixie` (Debian trixie with those packages; Flutter and the pub cache are
mounted from `/mnt/archive1/officina-dati/rg-test`). GStreamer and parecord come from `tool/linux-audio.Dockerfile`, layered on it
(G40.10).
