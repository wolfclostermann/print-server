#!/usr/bin/env bash
# Bundle the flake for copying to an installer USB (no GitHub API on target).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/../print-server.tar.gz}"
tar -czf "$out" -C "$(dirname "$root")" "$(basename "$root")"
echo "Wrote $out"
echo "On the installer: tar -xzf print-server.tar.gz -C /mnt && nixos-install --flake /mnt/print-server#print-server"
