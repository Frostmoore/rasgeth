#!/usr/bin/env bash
# The Linux app against a real RedGiant (the monorepo's demo server, FakeProvider, no real model),
# with screenshots (G40.7). Runs inside rgcompanion-linux-build:trixie, with /mnt/archive1 mounted:
#   docker run --rm -v /mnt/archive1:/mnt/archive1 -w "$PWD" rgcompanion-linux-build:trixie \
#     bash tool/linux_shots.sh /mnt/archive1/officina-dati/rg-test/companion-shots
# The first start (G40.8):
#   ... -e RG_DEMO_ENV="DEMO_FRESH=1 DEMO_SETUP_AP=1" ... \
#     bash tool/linux_shots.sh <folder> integration_test/first_start_shots_test.dart
# Node comes from $RG_NODE (default rg-test/bin/node), Flutter from rg-test/flutter.
set -euo pipefail
shots="${1:?a folder for the screenshots}"
# The test to drive (default: G40.7's tour) and the demo's environment (G40.8's first start:
# RG_DEMO_ENV="DEMO_FRESH=1 DEMO_SETUP_AP=1").
test="${2:-integration_test/shots_test.dart}"
demo_env="${RG_DEMO_ENV:-DEMO_PASSWORD=companion-test-1 DEMO_REQUESTS=1 DEMO_CRITICAL=1}"
rg=/mnt/archive1/officina-dati/rg-test
# RG_PUB_CACHE: a pub cache of its own (another build on the shared one races on its lock).
export FLUTTER_ROOT="$rg/flutter" PUB_CACHE="${RG_PUB_CACHE:-$rg/pub-cache}" PATH="$rg/flutter/bin:$PATH"
node="${RG_NODE:-$rg/bin/node}"
# RG_REPO: the demo server of another worktree, already built (this one may have no node_modules).
repo="${RG_REPO:-$(cd ../.. && pwd)}"
mkdir -p "$shots"
# RG_SCREEN=WxH: a phone-sized screen, and the app's window as big (default 1280x720).
screen="${RG_SCREEN:-1280x720}"
export RGCOMPANION_WINDOW="$screen"
Xvfb :99 -screen 0 "${screen}x24" >/tmp/xvfb.log 2>&1 &
export DISPLAY=:99
eval "$(dbus-launch --sh-syntax)"
# shellcheck disable=SC2086 # the variables are words on purpose
env $demo_env DEMO_HOST=127.0.0.1 \
  "$node" "$repo/packages/web/scripts/demo-server.mjs" 7651 >/tmp/demo.log 2>&1 &
# RG_DEMO_WAIT: seconds the demo may take to start (a busy Docker host needs more than 120).
for _ in $(seq 1 "${RG_DEMO_WAIT:-120}"); do grep -q '"url"' /tmp/demo.log && break; sleep 1; done
grep -q '"url"' /tmp/demo.log || { cat /tmp/demo.log; exit 1; }
RG_LIVE_URL=http://127.0.0.1:7651 RG_SHOTS="$shots" \
  flutter test "$test" -d linux
