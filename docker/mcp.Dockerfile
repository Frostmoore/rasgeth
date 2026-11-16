# The sandbox of RedGiant's local MCP servers (G41.0): one container per person and server, with
# npx and uvx to install the server's package at its exact version, and nothing of RedGiant's data.
# Published as ghcr.io/frostmoore/redgiant2-mcp (REDGIANT_MCP_IMAGE); built here for tests as
# redgiant/mcp:dev (`docker build -f docker/mcp.Dockerfile -t redgiant/mcp:dev docker`).
FROM ghcr.io/astral-sh/uv:0.13.8 AS uv

FROM node:24-trixie-slim
COPY --from=uv /uv /uvx /usr/local/bin/
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates coreutils python3 tini \
 && rm -rf /var/lib/apt/lists/*
# Node's own fetch goes through the egress proxy (HTTP(S)_PROXY, set by the sandbox); uv uses the
# image's Python, never one downloaded; npm stays quiet.
ENV NODE_USE_ENV_PROXY=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON_PREFERENCE=only-system \
    npm_config_update_notifier=false \
    npm_config_fund=false \
    npm_config_audit=false
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]
