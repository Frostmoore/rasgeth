# Rasgeth, the app

The Rasgeth app (G40, 3.8; «Rasgeth App» on a computer, next to the whole installation): one
Flutter project for Android, iOS, Windows, macOS and Linux. It is an extra: everything still works from the browser. On computers the launchers stay the keeper of
the local server (start, updates, tray); the app is the window.

- Flutter **3.47.3** (Dart 3.13.3), the same on Rig, in the CI (`.github/workflows/companion.yml`)
  and for local checks.
- `lib/api`: the client of the app's protocol, the same routes as the page.
  - `transport.dart`: how a Rasgeth is reached, one pure rule (`transportFor`): plain http only
    to this machine; https trusting only Rasgeth's local CA once the app has it (or the system's
    roots for a proxy or Tailscale); any other http address (the temporary network 10.42.0.1, a
    Rasgeth without HTTPS) through the setup channel, never in clear.
  - `setup_channel.dart`: the app's side of `/api/setup-channel`, the nodes' handshake in `setup`
    mode (ed25519, X25519, ChaCha20-Poly1305 with counters, package `cryptography`): Rasgeth's
    key pinned at first use, the password signed in inside it, the device token and the local CA
    handed back encrypted.
  - `discovery.dart`: `_redgiant._tcp` with bonsoir (the system's own mDNS service on all five).
  - `servers.dart`: the servers the app knows (home, work…: address, pinned key, local CA) and
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
  - `wifi.dart`: Rasgeth-Setup-XXXX (password `rasgeth`) joined system by system: Android
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
    networks Rasgeth saw, or the cable), then the wait while Rasgeth moves: the app leaves the
    temporary network, finds Rasgeth at home with the same key (the address it said, mDNS,
    rasgeth.local), and when it is not there goes back to the temporary network for the reason
    («try and come back»). Then the languages, a way of thinking (Claude or ChatGPT
    subscription, a provider's key), the names, and the first start is completed. The password is
    kept in memory only while the flow runs.
- `lib/mascot`: the agents' mascots, drawn from the server's SVG (`@redgiant/mascot`), cut into
  layers and moved like the page's CSS; nothing moves with «Reduce motion».
- `lib/theme`: the page's colours (`packages/web/src/styles.css`), light, dark or the system's.
- `lib/l10n`: Italian and English (ARB, `flutter gen-l10n`; the generated files are in git).
- `lib/screens`: proposal A, «La squadra» (Team | Chat | For you | Activity | You, with the Chat's
  field over the bar); a conversation (`conversation_screen.dart`), the Canvas (images, SVG, PDF
  with pdfx, Markdown natively; an artifact as in the page, see below; another HTML file in an
  isolated WebView: a document of ours with a CSP that allows no network, the file in
  `<iframe sandbox="allow-scripts allow-forms" srcdoc>`), a critical request's own screen; the first
  start (`first_start_screen.dart`) and «Settings of <name>» in You (`server_settings_screen.dart`,
  `full_settings_screen.dart`).
- `lib/ui/markdown.dart`: Markdown without raw HTML nor remote images, links only http(s) and
  mailto after a yes, task lists with drawn marks.
- Widgets and artifacts (3.8.7, as the page's 3.5.9-3.6): `lib/api/widgets.dart` splits an answer
  around its ```widget blocks exactly as the page (`answerSegments`, `splitWidgets`,
  `streamingWithoutWidgets`; `buildItems` puts a `WidgetItem` after its answer); the Canvas runs
  `artefatti/*.html` (the server says which, `POST /api/canvas/link`). One frame for both
  (`lib/ui/artifact_frame_view.dart`): a web view loads a page of ours from the app's preview
  relay on 127.0.0.1 (`lib/api/preview_relay.dart`), which holds the server's signed
  `/preview/<token>/…` in `<iframe sandbox="allow-scripts allow-forms">` and passes on to Rasgeth
  only those GETs, with the app's own trust (the local CA, or the system's roots), never the app's
  token; the server's policy (no network, Rasgeth's libraries) comes back with its origins moved
  to the relay's. The frame's messages reach the app only through that page, with a nonce of its
  load (`lib/api/artifact_frame.dart`: `FrameMessage`, the click rule `ClickGuard`,
  `FrameSession`): height (a widget, at most 70% of the screen), theme and language, errors for
  the agent (`POST /api/artifacts/errors`), «send to chat» at once only right after a click in
  it (otherwise «Manda» / «Lascia stare» under it), links after a yes, the bridge for artifacts.
  Android, iOS, macOS: webview_flutter 4.14.1; Windows: webview_flutter_windows 1.3.1 (WebView2
  drawn into Flutter, BSD-3); Linux: no web view the app can trust in a scrolling chat, so the
  widget's words and «Apri nella pagina» (the browser, on the same preview link), and in the Canvas
  the artifact's source under the same button.
- Android: `res/xml/network_security_config.xml` allows clear text only to 10.42.0.1 and to the
  app's own relay on 127.0.0.1 (the platform's stacks; the Dart connections follow `transportFor`).

```sh
flutter pub get
flutter analyze
flutter test                       # goldens: drawn on Linux
flutter build linux|windows|macos|apk|ios
```

Tests: `test/` runs everywhere (a fake Rasgeth on localhost with `/ws`, the setup channel's
vectors recorded with node:crypto by `tool/setup_vectors.mjs`, the screens). Against a real
Rasgeth (the monorepo's demo server, FakeProvider, no real model):

```sh
DEMO_PASSWORD=companion-test-1 DEMO_HOST=127.0.0.1 DEMO_REQUESTS=1 \
  node packages/web/scripts/demo-server.mjs 7651 &
RG_LIVE_URL=http://127.0.0.1:7651 flutter test test/live_server_test.dart
```

The first start against a Rasgeth never set up, with Rasgeth OS's temporary network acted out
by the demo (`DEMO_SETUP_AP=1`: ap-status, home-network-try, a Wi-Fi password `sbagliata` that
fails; no real network is touched, the Wi-Fi joining is a fake):

```sh
DEMO_FRESH=1 DEMO_SETUP_AP=1 DEMO_HOST=127.0.0.1 node packages/web/scripts/demo-server.mjs 7652 &
RG_SETUP_URL=http://127.0.0.1:7652 flutter test test/first_start_live_test.dart
```

Widgets and artifacts (3.8.7): `test/g387_web_test.dart` (the split against
`test/fixtures/widget_vectors.json`, written with the page's own functions by
`node --experimental-strip-types apps/companion/tool/widget_fixtures.mjs`; the frame's protocol as
tables; the relay on real sockets; the screens with a stand-in web view). In a real browser engine
against the demo (`DEMO_ARTIFACTS=1`): `dart run tool/relay_probe.dart <demo log> <relay.json>` in
the build image with `--network host`, then `tool/frame_probe.mjs` in the Playwright image
`mcr.microsoft.com/playwright:v1.64.1-noble` (`PW_FROM` = a folder with `playwright-core`). On Linux,
`integration_test/g387_web_shots_test.dart` (`RG_DEMO_LOG` = the demo's output).

The Linux app driven through its screens against the demo, with screenshots, in the agents'
Docker: `bash tool/linux_shots.sh <folder> [test]` (see the script; the first start with
`RG_DEMO_ENV="DEMO_FRESH=1 DEMO_SETUP_AP=1"` and `integration_test/first_start_shots_test.dart`).

Mascot fixtures (`test/fixtures/mascots.json`) come from the library:
`pnpm build && node apps/companion/tool/mascot_fixtures.mjs`. Every size of the icon, here and in
the page, the site and the installers, comes from the masters in `packaging/icon/` (plan 3.8.13
N8): `flutter test tool/make_icons_test.dart`. The
answers' figures (G40.17) are checked against the page's formatters with
`test/fixtures/metrics_vectors.json`: `node --experimental-strip-types apps/companion/tool/metrics_fixtures.mjs`.

Linux builds need `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev
libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libwebkit2gtk-4.1-dev` (GStreamer for reading answers aloud; «press and talk»
records with `parecord` from pulseaudio-utils at run time; WebKitGTK for the web view, G42.0: the app needs
`libwebkit2gtk-4.1-0` at run time, `install-app.sh` checks it). The web view on Linux is
`third_party/webview_all_linux`, a copy of webview_all_linux 1.5.1 (MIT) whose TLS errors carry the certificate.
On Severino the Linux build runs in the agents' Docker with the image
`rgcompanion-linux-build:trixie` (Debian trixie with those packages; Flutter and the pub cache are
mounted from `/mnt/archive1/officina-dati/rg-test`). GStreamer and parecord come from `tool/linux-audio.Dockerfile`, layered on it
(G40.10); WebKitGTK, H.264 and Mesa from `tool/linux-webview.Dockerfile` (G42.0), layered the same way.
The page inside the app (G42.0): `test/fixtures/embed_vectors.json` comes from the protocol's rules,
`pnpm build && node apps/companion/tool/embed_vectors.mjs`; the Linux shots with WebKitGTK:
`RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_CANVAS=1" RG_SHOT_TAG=computer bash tool/linux_shots.sh <folder> integration_test/g42_0_shots_test.dart`.
