#!/usr/bin/env bash
# Moved in 3.9.0 (RedGiant is now Rasgeth): rasgeth-proxmox.sh does the work. This path stays on
# main because pages and notes written before name it; it only runs the new script, with the same
# arguments (the one next to it when there is one, otherwise main's).
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)
if [ -n "$here" ] && [ -r "$here/rasgeth-proxmox.sh" ]; then exec bash "$here/rasgeth-proxmox.sh" "$@"; fi
exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/Frostmoore/rasgeth/main/packaging/os/proxmox/rasgeth-proxmox.sh)" rasgeth-proxmox.sh "$@"
