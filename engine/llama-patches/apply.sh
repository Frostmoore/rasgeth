#!/bin/sh
# RedGiant's changes to llama.cpp (G27, G32.2, C.4): run from llama.cpp's source folder, at tag b12679.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
cp "$here/llama-teal.h" "$here/llama-teal.cpp" "$here/llama-moe-prefetch.h" "$here/llama-moe-prefetch.cpp" src/
git apply --whitespace=nowarn "$here/0001-redgiant-teal.patch"
git apply --whitespace=nowarn "$here/0002-redgiant-moe-prefetch.patch"
# C.4 (plan_contesto.md): the full-context layers' cache in RAM, our attention on the processor, the first cells in the
# card too (LLAMA_KV_FULL_HOST, LLAMA_KV_HOT_CELLS); it carries its own files
git apply --whitespace=nowarn "$here/0003-redgiant-kv-host.patch"
