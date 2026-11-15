#!/usr/bin/env bash
# RedGiant OS (3.7.4): a release of this commit for update-test.sh, as GitHub would serve it to a
# machine: release.json, redgiant-os-stack.json (the images at --source-tag, the references naming
# the version's tags), the system's files, each signed with a key made here and thrown away (the
# release's key never leaves its secret), and release-api.json pointing at file:///root/feed/.
#
#   update-feed.sh --out <dir> --version x.y.z --above x.y.z [--source-tag <tag>]
#     --above: the version the machine runs; the feed must be newer, so a version that is not
#       (a branch whose release-kind.json still names the last release) becomes the next patch.
set -euo pipefail
OUT="" VERSION="" ABOVE="" SOURCE="" TAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT=$2 && shift ;;
    --version) VERSION=$2 && shift ;;
    --above) ABOVE=$2 && shift ;;
    --source-tag) SOURCE=$2 && shift ;;
    *) echo "unknown option $1" >&2 && exit 2 ;;
  esac
  shift
done
if [ -z "$OUT" ] || ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || ! [[ $ABOVE =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: update-feed.sh --out <dir> --version x.y.z --above x.y.z [--source-tag <tag>]" >&2
  exit 2
fi
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
if [ "$(printf '%s\n%s\n' "$ABOVE" "$VERSION" | sort -V | tail -1)" = "$ABOVE" ]; then
  IFS=. read -r a b c <<<"$ABOVE"
  echo "::notice title=Update test::$VERSION is not newer than $ABOVE: the feed is $a.$b.$((c + 1)) (same images and files)"
  # The next patch has no images of its own: the stack names the version's (its tag).
  TAG=$VERSION
  VERSION=$a.$b.$((c + 1))
fi
mkdir -p "$OUT"
node "$ROOT/packaging/os/stack.mjs" --version "$VERSION" --tag "${TAG:-$VERSION}" --source-tag "$SOURCE" --out "$OUT/redgiant-os-stack.json"
node "$ROOT/packaging/os/files.mjs" --version "$VERSION" --out "$OUT"
node "$ROOT/packaging/update/release-info.mjs" --version "$VERSION" --out "$OUT"
key=$(mktemp)
openssl genrsa -out "$key" 2048 2>/dev/null
openssl rsa -in "$key" -pubout -out "$OUT/key.pem" 2>/dev/null
for f in release.json redgiant-os-stack.json redgiant-os-files.json; do
  openssl dgst -sha256 -sign "$key" "$OUT/$f" | base64 -w0 >"$OUT/$f.sig"
done
rm -f "$key"
(cd "$OUT" && ls) | grep -vxE 'key.pem|release-api.json' |
  jq -R '{name: ., browser_download_url: ("file:///root/feed/" + .)}' | jq -s --arg t "v$VERSION" '{tag_name: $t, assets: .}' >"$OUT/release-api.json"
echo "feed of $VERSION:"
ls -la "$OUT"
