#!/bin/sh
# The fingerprint of a patched llama.cpp build (G32.2): a hash of everything that changes the
# result, so a release reuses the engine an earlier release built instead of compiling it again
# (release.yml, job engine-plan). Run from anywhere inside the repository:
#   LLAMA_BUILD=b12034 CUDA_VERSION=12.8.1 CUDA_ARCHS='75-real;...;120' engine/fingerprint.sh win|linux
# win: the zip llama-redgiant-win-cuda12.8-x64.zip (engine/build-win.ps1);
# linux: the image redgiant2-engine:cuda-prefetch (docker/engine-prefetch.Dockerfile).
# Both: llama.cpp's tag, CUDA's version, the card families and every file in engine/llama-patches.
# The recipe counts without what cannot change the program: comment lines, blank lines and the
# line writing the label build.txt (renaming the product changed only those, and the engines were
# compiled again for nothing; then the compilation broke, 3.9.0-3.9.4). Prints 16 hex digits.
set -eu
: "${LLAMA_BUILD:?}" "${CUDA_VERSION:?}" "${CUDA_ARCHS:?}"
cd "$(git rev-parse --show-toplevel)"
case "${1:-}" in
  win) recipe=engine/build-win.ps1 ;;
  linux) recipe=docker/engine-prefetch.Dockerfile ;;
  *) echo "usage: $0 win|linux" >&2; exit 2 ;;
esac
{
  printf 'target=%s\nllama=%s\ncuda=%s\narchs=%s\n' "$1" "$LLAMA_BUILD" "$CUDA_VERSION" "$CUDA_ARCHS"
  # Committed files only, by path, so the order and the line endings are the same everywhere.
  for f in $(git ls-files engine/llama-patches | LC_ALL=C sort); do
    printf '%s %s\n' "$f" "$(git show "HEAD:$f" | sha256sum | cut -c1-64)"
  done
  printf '%s %s\n' "$recipe" "$(git show "HEAD:$recipe" | tr -d '\r' \
    | grep -v -E '^[[:space:]]*(#.*)?$' | grep -v -F 'build.txt' | sha256sum | cut -c1-64)"
} | sha256sum | cut -c1-16
