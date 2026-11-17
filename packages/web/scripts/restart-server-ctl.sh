#!/usr/bin/env bash
# restart-server-ctl.sh start|freeze|kill — drives restart-server.mjs (p3.8.9) for the app's
# test of a server that goes away and comes back (apps/companion/test/restart_server_test.dart).
#   start   starts it on RESTART_PORT (7652) with the data in RESTART_DIR (kept between starts);
#           run it detached or with its output to a file: read through a pipe, it never ends
#   freeze  stops it answering with every link still open (SIGSTOP: a power cut, as the app sees it)
#   kill    kills it with SIGKILL, no goodbye
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PORT="${RESTART_PORT:-7652}"
DIR="${RESTART_DIR:-/tmp/rg-restart-server}"
LOG="${RESTART_LOG:-/tmp/rg-restart-server.log}"
pids() { pgrep -f "^node packages/web/scripts/restart-server.mjs $PORT\$"; }
case "${1:-}" in
  start)
    cd "$ROOT" && RESTART_DIR="$DIR" DEMO_PASSWORD="${DEMO_PASSWORD:-companion-test-1}" \
      setsid nohup node packages/web/scripts/restart-server.mjs "$PORT" >"$LOG" 2>&1 </dev/null &
    for _ in $(seq 1 60); do grep -q '"url"' "$LOG" && break; sleep 1; done
    tail -1 "$LOG" ;;
  freeze) for p in $(pids); do kill -STOP "$p"; done; echo frozen ;;
  kill) for p in $(pids); do kill -9 "$p"; done; sleep 0.5; echo killed ;;
  *) echo "usage: restart-server-ctl.sh start|freeze|kill" >&2; exit 2 ;;
esac
