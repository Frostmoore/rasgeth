# RGCompanion

The RedGiant app (G40, 3.8): one Flutter project for Android, iOS, Windows, macOS and Linux. It is
an extra: everything still works from the browser. On computers the launchers stay the keeper of
the local server (start, updates, tray); the app is the window.

- Flutter **3.47.3** (Dart 3.13.3), the same on Rig, in the CI (`.github/workflows/companion.yml`)
  and for local checks.
- `lib/api`: the client of the app's protocol (`/api/app/hello`, `/api/app/pair`, `/api/agents`,
  the mascots), types from `packages/protocol/src/devices.ts` and `mascot.ts`; the device token in
  the system's keystore (`flutter_secure_storage`).
- `lib/mascot`: the agents' mascots, drawn from the server's SVG (`@redgiant/mascot`), cut into
  layers and moved like the page's CSS; nothing moves with «Reduce motion».
- `lib/theme`: the page's colours (`packages/web/src/styles.css`), light, dark or the system's.
- `lib/l10n`: Italian and English (ARB, `flutter gen-l10n`; the generated files are in git).
- `lib/screens`: proposal A, «La squadra» (Team | Chat | For you | Activity | You, with the Chat's
  field over the bar).

```sh
flutter pub get
flutter analyze
flutter test                       # goldens: drawn on Linux
flutter build linux|windows|macos|apk|ios
```

Mascot fixtures (`test/fixtures/mascots.json`) come from the library:
`pnpm build && node apps/companion/tool/mascot_fixtures.mjs`. The icons come from
`assets/icon/rgcompanion.svg`: `flutter test tool/make_icons_test.dart`.

Linux builds need `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev`.
On Severino the Linux build runs in the agents' Docker with the image
`rgcompanion-linux-build:trixie` (Debian trixie with those packages; Flutter and the pub cache are
mounted from `/mnt/archive1/officina-dati/rg-test`).
