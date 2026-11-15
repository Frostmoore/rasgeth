#!/usr/bin/env bash
# The debug APK in the agents' Docker (rgcompanion-android-build:trixie, see
# android-build.Dockerfile), with the SDK in rg-test/android-sdk: licenses accepted here, the
# packages Flutter asks for installed with sdkmanager's own progress bar, then the build.
#   docker run --rm -v /mnt/archive1:/mnt/archive1 -w "$PWD" rgcompanion-android-build:trixie \
#     bash tool/android_apk.sh [where to copy the APK]
set -euo pipefail
rg=/mnt/archive1/officina-dati/rg-test
export FLUTTER_ROOT="$rg/flutter" PUB_CACHE="$rg/pub-cache" GRADLE_USER_HOME="$rg/gradle-home"
export ANDROID_HOME="$rg/android-sdk" ANDROID_SDK_ROOT="$rg/android-sdk"
export PATH="$rg/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
(yes || true) | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"
flutter config --android-sdk "$ANDROID_HOME" >/dev/null
flutter build apk --debug
out="${1:-$rg/companion-builds}"
mkdir -p "$out"
cp build/app/outputs/flutter-apk/app-debug.apk "$out/rgcompanion-debug.apk"
chmod 644 "$out/rgcompanion-debug.apk"
ls -la "$out/rgcompanion-debug.apk"
