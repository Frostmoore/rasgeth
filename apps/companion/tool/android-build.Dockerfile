# RGCompanion's APK in the agents' Docker (when Rig is off): rgcompanion-linux-build:trixie plus a
# JDK. The Android SDK stays outside the image, in rg-test/android-sdk (mounted), with its licenses
# accepted there.
#   docker build -t rgcompanion-android-build:trixie -f tool/android-build.Dockerfile tool
#   docker run --rm -v /mnt/archive1:/mnt/archive1 -w "$PWD" rgcompanion-android-build:trixie \
#     bash tool/android_apk.sh
FROM rgcompanion-linux-build:trixie
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-21-jdk-headless \
  && rm -rf /var/lib/apt/lists/*
