#!/bin/bash
# Rasgeth.app and its .dmg for macOS (2026-11-05; RedGiant.app until 3.9.0), on a Mac (the CI's, or yours), after
# `pnpm install --frozen-lockfile && pnpm build` at the repository's root.
#
#   packaging/mac/build.sh <version>
#
# Signed with a Developer ID when MAC_SIGN_IDENTITY names one in the keychain (the CI imports it),
# otherwise ad-hoc (it runs on this Mac only). Notarized and stapled when MAC_NOTARY_KEY (an App
# Store Connect API key file, .p8), MAC_NOTARY_KEY_ID and MAC_NOTARY_ISSUER_ID are set.
# pgvector (G36.1) goes into Resources/server/pgvector, signed with the rest: from PGVECTOR_ZIP (the
# release's pgvector job), otherwise built here with engine/pgvector/build-mac.sh (a minute or two).
# The app (G40.12): COMPANION_APP names the Flutter build («Rasgeth App.app», or the CI's
# rasgeth-app-macos.zip); it goes into Contents/Helpers and is signed again with the same identity
# (its own entitlements: the sandbox), inside out. Without it «Open Rasgeth» opens the browser.
set -euo pipefail

version="${1:-0.0.0}"
root="$(cd "$(dirname "$0")/../.." && pwd)"
here="$root/packaging/mac"
arch="$(uname -m)"
dist="$here/dist"
app="$dist/Rasgeth.app"
res="$app/Contents/Resources"
identity="${MAC_SIGN_IDENTITY:--}"

rm -rf "$dist"
mkdir -p "$app/Contents/MacOS" "$res/node"

echo "== The server, with its production modules (real folders, no links)"
cd "$root"
pnpm --filter @redgiant/server deploy --prod --legacy --config.node-linker=hoisted "$res/server" >/dev/null
# Codex and Claude Code (hundreds of MB) come down only when a subscription is switched on.
rm -rf "$res"/server/node_modules/@openai/codex-darwin-* \
  "$res"/server/node_modules/@anthropic-ai/claude-agent-sdk-darwin-*
# Postgres' libraries come three times each from npm: the copies become links again.
for lib in "$res"/server/node_modules/@embedded-postgres/darwin-*/native/lib; do
  node "$here/dedupe-libs.mjs" "$lib" | tail -1
done
echo "== pgvector for the embedded Postgres (universal, from a folder of its own)"
pgv_zip="${PGVECTOR_ZIP:-}"
if [ -z "$pgv_zip" ]; then
  bash "$root/engine/pgvector/build-mac.sh" "$dist/pgvector" | tail -3
  pgv_zip="$(ls "$dist"/pgvector/pgvector-*-macos-universal.zip)"
fi
mkdir -p "$res/server/pgvector"
unzip -q "$pgv_zip" -d "$res/server/pgvector"
lipo -info "$res/server/pgvector/lib/vector.dylib"
cp -R packages/web/dist "$res/web"
echo "== The rasgeth command line (G36.15), in the app: Resources/bin/rasgeth"
node packaging/cli/stage.mjs "$res/server"
mkdir -p "$res/bin"
cp "$here/rasgeth" "$res/bin/rasgeth"
chmod +x "$res/bin/rasgeth"
cp "$(command -v node)" "$res/node/node"
echo "what weighs most:"
du -sh "$res/node" "$res/web" "$res"/server/node_modules/* "$res"/server/node_modules/@*/* 2>/dev/null | sort -h | tail -8

echo "== The icon"
# Drawn by apps/companion/tool/make_icons_test.dart: the tile inside Apple's grid (the app's own
# macOS sizes) and the menu bar's template silhouette (plan 3.8.13 N8).
iconset="$dist/Rasgeth.iconset"
mkdir -p "$iconset"
appicons=apps/companion/macos/Runner/Assets.xcassets/AppIcon.appiconset
for s in 16 32 128 256 512; do
  cp "$appicons/app_icon_$s.png" "$iconset/icon_${s}x${s}.png"
  cp "$appicons/app_icon_$((s * 2)).png" "$iconset/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$iconset" -o "$res/Rasgeth.icns"
rm -rf "$iconset"
cp packaging/icon/rasgeth-menubar.png "$res/menubar.png"

echo "== The menu bar program"
swiftc -O -target "$arch-apple-macos13" -o "$app/Contents/MacOS/Rasgeth" "$here/Rasgeth.swift"
sed "s/__VERSION__/$version/g" "$here/Info.plist" > "$app/Contents/Info.plist"

echo "== Signing ($([ "$identity" = "-" ] && echo ad-hoc || echo "$identity"))"
sign() {
  if [ "$identity" = "-" ]; then
    codesign --force --sign - "$@"
  else
    codesign --force --timestamp --options runtime --sign "$identity" "$@"
  fi
}

companion="${COMPANION_APP:-}"
if [ -n "$companion" ]; then
  echo "== The app's window (G40.12), from $companion"
  mkdir -p "$app/Contents/Helpers"
  case "$companion" in
    *.zip) ditto -x -k "$companion" "$app/Contents/Helpers" ;;
    *) ditto "$companion" "$app/Contents/Helpers/Rasgeth App.app" ;;
  esac
  helper="$app/Contents/Helpers/Rasgeth App.app"
  [ -x "$helper/Contents/MacOS/Rasgeth App" ] || { echo "no «Rasgeth App.app» in $companion"; exit 1; }
  # The entitlements Flutter's build signed it with (the sandbox, network, microphone).
  ents="$dist/rasgeth-app.entitlements"
  codesign -d --entitlements - --xml "$helper" > "$ents" 2>/dev/null || true
  [ -s "$ents" ] || cp "$root/apps/companion/macos/Runner/Release.entitlements" "$ents"
  # Flutter's ad-hoc signature ("sign to run locally") adds get-task-allow, which lets a
  # debugger attach: never in what ships, and Apple's notarization refuses it.
  /usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" "$ents" 2>/dev/null || true
  # Inside out: the frameworks' libraries, the frameworks, then the app with its entitlements.
  while IFS= read -r -d '' f; do
    if file -b "$f" | grep -q "Mach-O"; then sign "$f"; fi
  done < <(find "$helper/Contents/Frameworks" -type f \( -name "*.dylib" -o -perm -u+x \) ! -path "*.framework/*" -print0 2>/dev/null)
  while IFS= read -r -d '' fw; do sign "$fw"; done < <(find "$helper/Contents/Frameworks" -maxdepth 1 -name "*.framework" -print0 2>/dev/null)
  sign --entitlements "$ents" "$helper"
  codesign --verify --deep --strict "$helper"
  echo "Rasgeth App.app signed: $(du -sh "$helper" | cut -f1)"
fi
# Every program and library inside, deepest first: Node, Postgres, native modules.
count=0
while IFS= read -r -d '' f; do
  if file -b "$f" | grep -q "Mach-O"; then
    sign --entitlements "$here/node.entitlements" "$f"
    count=$((count + 1))
  fi
done < <(find "$res" -type f \( -name "*.node" -o -name "*.dylib" -o -name "*.so" -o -perm -u+x \) -print0)
echo "$count programs and libraries signed"
sign "$app"
codesign --verify --deep --strict "$app"

echo "== The disk image"
stage="$dist/stage"
mkdir -p "$stage"
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
dmg="$dist/Rasgeth-mac-$arch.dmg"
# LZMA (macOS 10.15 and later): smaller than the default zlib.
hdiutil create -volname Rasgeth -srcfolder "$stage" -ov -format ULMO "$dmg" >/dev/null
rm -rf "$stage"
if [ "$identity" != "-" ]; then
  codesign --force --timestamp --sign "$identity" "$dmg"
fi

if [ "$identity" != "-" ] && [ -n "${MAC_NOTARY_KEY:-}" ]; then
  echo "== Notarization (Apple checks it; a few minutes)"
  xcrun notarytool submit "$dmg" --key "$MAC_NOTARY_KEY" --key-id "$MAC_NOTARY_KEY_ID" \
    --issuer "$MAC_NOTARY_ISSUER_ID" --wait --timeout 30m
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
  spctl -a -t open --context context:primary-signature -v "$dmg"
fi
ls -lh "$dmg"
