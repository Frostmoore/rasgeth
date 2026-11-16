#!/usr/bin/env bash
# RedGiant OS (3.7.4): the update a machine makes, tried in Incus on CI's runner. A container
# template (the latest release's that carries RedGiant OS, or this commit's) starts as Proxmox would
# start it, then its own redgiant-os-update brings it to a feed of this commit: a new stack (this
# commit's Docker images), its release.json and its system's files, signed with a key made for the
# test. The machine must end on the new version with the pinned images, its system files as listed,
# RedGiant answering. Cheap enough for every version: the images are not built again for it.
#
#   sudo update-test.sh --template <…-lxc.tar.zst> --feed <dir> --logs <dir> [--first] [--timeout <s>]
#
# --feed: release-api.json (a GitHub release whose assets point at file:///root/feed/<name>), the
#   release's files and key.pem (the test key's public half). The updater runs as it is, from a copy
#   whose only change is the address of the latest release (the feed instead of api.github.com).
# --first: the new machine's own first start (redgiant-os-update first, the marker in place)
#   instead of `apply`.
set -uo pipefail
TEMPLATE="" FEED="" LOGS=. TIMEOUT=1800 NAME=rg-update-test FIRST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --template) TEMPLATE=$2 && shift ;;
    --feed) FEED=$2 && shift ;;
    --logs) LOGS=$2 && shift ;;
    --timeout) TIMEOUT=$2 && shift ;;
    --first) FIRST=1 ;;
    *) echo "unknown option $1" >&2 && exit 2 ;;
  esac
  shift
done
if ! [ -r "$TEMPLATE" ] || ! [ -r "$FEED/release-api.json" ] || ! [ -r "$FEED/key.pem" ]; then
  echo "usage: update-test.sh --template <file> --feed <dir> --logs <dir> [--first]" >&2
  exit 2
fi
mkdir -p "$LOGS"
LOG=$LOGS/update-journal.log
in_ct() { timeout "${T:-60}" incus exec "$NAME" -- "$@" </dev/null; }
fail() {
  echo "::error::$*"
  T=60 in_ct journalctl -b --no-pager -n 600 2>&1 | sed 's/\r$//' >"$LOG"
  tail -n 150 "$LOG"
  T=30 in_ct cat /var/lib/redgiant/os-update.json 2>&1
  T=30 in_ct docker ps -a 2>&1
  exit 1
}
start=$SECONDS
work=$(mktemp -d)
printf 'architecture: %s\ncreation_date: %s\nproperties:\n  description: RedGiant OS (CI update)\n  os: debian\n  release: trixie\n' \
  "$(uname -m)" "$(date +%s)" >"$work/metadata.yaml"
tar -C "$work" -czf "$work/metadata.tar.gz" metadata.yaml
timeout 900 incus image import "$work/metadata.tar.gz" "$TEMPLATE" --alias redgiant-os-update-ci ||
  fail "incus could not import the template"
timeout 600 incus init redgiant-os-update-ci "$NAME" -c security.nesting=true \
  -c security.syscalls.intercept.mknod=true -c security.syscalls.intercept.setxattr=true ||
  fail "the container could not be made"
# Never the real latest release while the test runs: the marker goes, and comes back for --first.
timeout 60 incus file delete "$NAME/var/lib/redgiant/first-update" >/dev/null 2>&1 || true
timeout 300 incus start "$NAME" || fail "the container did not start"

wait_until() { # what seconds command…
  local what=$1 deadline=$((SECONDS + $2))
  shift 2
  while [ $SECONDS -lt $deadline ]; do
    "$@" >/dev/null 2>&1 && { echo "$what after $((SECONDS - start)) s"; return 0; }
    sleep 5
  done
  return 1
}
healthy() { T=15 in_ct curl -fsS --max-time 5 http://127.0.0.1:7600/api/health; }
wait_until "RedGiant answering" "$TIMEOUT" healthy || fail "RedGiant did not answer within $TIMEOUT s"
old=$(T=15 in_ct bash -c '. /usr/lib/redgiant-os/common.sh; installed_version')
new=$(jq -r .tag_name "$FEED/release-api.json")
new=${new#v}
echo "the machine runs RedGiant $old; the feed brings $new"

# The feed inside the machine, the test key in place of the update key (the machine trusts it).
T=30 in_ct mkdir -p /root/feed
for f in "$FEED"/*; do timeout 120 incus file push "$f" "$NAME/root/feed/" || fail "could not copy $f"; done
T=30 in_ct install -m 0644 /root/feed/key.pem /usr/share/redgiant-os/release-key.pem || fail "no test key"
up=/usr/lib/redgiant-os/redgiant-os-update
T=30 in_ct sh -c "sed 's#https://api.github.com/repos/\$REPO/releases/latest#file:///root/feed/release-api.json#' $up >$up-ci && chmod 755 $up-ci" ||
  fail "no copy of the updater"
T=15 in_ct grep -q "file:///root/feed/release-api.json" "$up-ci" || fail "the updater does not read the latest release where expected"

if [ "$FIRST" = 1 ]; then
  T=15 in_ct touch /var/lib/redgiant/first-update
  T="$TIMEOUT" in_ct "$up-ci" first 2>&1 | tail -n 40
  T=15 in_ct test ! -e /var/lib/redgiant/first-update || fail "the first start kept its marker"
else
  T="$TIMEOUT" in_ct "$up-ci" apply 2>&1 | tail -n 40
fi

ok=1
now=$(T=15 in_ct bash -c '. /usr/lib/redgiant-os/common.sh; installed_version')
[ "$now" = "$new" ] || { echo "::error::the machine runs $now, not $new"; ok=0; }
state=$(T=15 in_ct jq -r .state /var/lib/redgiant/os-update.json)
[ "$state" = latest ] || { echo "::error::the updater says $state"; ok=0; }
healthy >/dev/null || { echo "::error::RedGiant does not answer after the update"; ok=0; }
# The containers run the stack's pinned images (the id Docker reports is the stack's).
arch=$(T=15 in_ct bash -c '. /usr/lib/redgiant-os/common.sh; arch')
for id in $(jq -r --arg a "$arch" '.images[$a][].id' "$FEED/redgiant-os-stack.json"); do
  T=30 in_ct sh -c "docker ps -q | xargs docker inspect -f '{{.Image}}'" | grep -qx "$id" ||
    { echo "::error::no container runs $id"; ok=0; }
done
# The system's files as the release lists them (the container's own and every board's).
while read -r path sha; do
  [ "$(T=15 in_ct sha256sum "$path" 2>/dev/null | cut -d' ' -f1)" = "$sha" ] || { echo "::error::$path is not the release's"; ok=0; }
done < <(jq -r '.files[] | select(.board == null or .board == "lxc") | "\(.path) \(.sha256)"' "$FEED/redgiant-os-files.json")
[ "$ok" = 1 ] || fail "the update did not land"
T=60 in_ct journalctl -b --no-pager -n 600 2>&1 | sed 's/\r$//' >"$LOG"
timeout 120 incus delete --force "$NAME" >/dev/null 2>&1 || true
timeout 60 incus image delete redgiant-os-update-ci >/dev/null 2>&1 || true
echo "OK: RedGiant $old updated to $new in $((SECONDS - start)) s"
