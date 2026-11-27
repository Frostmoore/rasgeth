# RedGiant local engine: llama.cpp's server with RedGiant's defaults.
#   docker build --build-arg VARIANT=server-cuda -t redgiant/engine:cuda -f docker/engine.Dockerfile docker
# VARIANT: server (CPU) | server-cuda | server-rocm | server-vulkan  (official llama.cpp images)
ARG VARIANT=server
FROM ghcr.io/ggml-org/llama.cpp:${VARIANT}

# Defaults RedGiant relies on:
#  --slot-save-path /kv   KV caches saved to the SSD (shared with the RedGiant server)
#  --parallel 4           slots shared by agents, scheduled by priority
#  --ctx-checkpoints 8    sliding-window models (Gemma, Inkling) keep their prefix between turns
#                         from saved checkpoints (3.12.10); --swa-full did it by keeping every
#                         token in every layer: 12-28 GB at 65536 tokens, the model pushed out
#                         of the card and writing 3-5 times slower (measured on an RTX 4080 SUPER)
#  --jinja                the model's own chat template (tool calls, reasoning)
#  --kv-unified           one memory pool for all slots: each conversation can use the whole
#                         context (65536), not a quarter of it (8192 was too small for God)
ENV LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=8080 \
    LLAMA_ARG_N_PARALLEL=4 \
    LLAMA_ARG_CTX_CHECKPOINTS=8 \
    LLAMA_ARG_JINJA=1 \
    LLAMA_ARG_KV_UNIFIED=1 \
    LLAMA_ARG_CTX_SIZE=65536
VOLUME ["/kv", "/models"]
# --slot-save-path has no environment variable: it is part of the entrypoint, so it can
# never be silently missing. Arguments given to `docker run` (e.g. -m /models/x.gguf) follow.
ENTRYPOINT ["/app/llama-server", "--slot-save-path", "/kv"]
