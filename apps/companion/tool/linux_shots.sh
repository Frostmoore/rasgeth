#!/usr/bin/env bash
# The Linux app against a real RedGiant (the monorepo's demo server, FakeProvider, no real model),
# with screenshots (G40.7). Runs inside rgcompanion-linux-build:trixie, with /mnt/archive1 mounted:
#   docker run --rm -v /mnt/archive1:/mnt/archive1 -w "$PWD" rgcompanion-linux-build:trixie \
#     bash tool/linux_shots.sh /mnt/archive1/officina-dati/rg-test/companion-shots
# Node comes from $RG_NODE (default rg-test/bin/node), Flutter from rg-test/flutter.
set -euo pipefail
shots="${1:?a folder for the screenshots}"
rg=/mnt/archive1/officina-dati/rg-test
export FLUTTER_ROOT="$rg/flutter" PUB_CACHE="$rg/pub-cache" PATH="$rg/flutter/bin:$PATH"
node="${RG_NODE:-$rg/bin/node}"
repo="$(cd ../.. && pwd)"
mkdir -p "$shots"
Xvfb :99 -screen 0 1280x720x24 >/tmp/xvfb.log 2>&1 &
export DISPLAY=:99
eval "$(dbus-launch --sh-syntax)"
DEMO_PASSWORD=companion-test-1 DEMO_HOST=127.0.0.1 DEMO_REQUESTS=1 DEMO_CRITICAL=1 \
  "$node" "$repo/packages/web/scripts/demo-server.mjs" 7651 >/tmp/demo.log 2>&1 &
for _ in $(seq 1 120); do grep -q '"url"' /tmp/demo.log && break; sleep 1; done
grep -q '"url"' /tmp/demo.log || { cat /tmp/demo.log; exit 1; }
RG_LIVE_URL=http://127.0.0.1:7651 RG_SHOTS="$shots" \
  flutter test integration_test/shots_test.dart -d linux
