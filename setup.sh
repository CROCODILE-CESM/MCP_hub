#!/usr/bin/env bash
# Sets up all three MCP servers in one local venv, for use on machines without
# outbound internet access at launch time (e.g. HPC compute nodes). Generates
# mcp.local.json pointing an MCP client at the installed console scripts.
#
# For normal desktop/laptop use with internet access, you likely don't need
# this at all -- just point your MCP client at mcp.json instead.
set -euo pipefail

HUB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$HUB_ROOT/.venv"

echo "==> Syncing submodules"
git -C "$HUB_ROOT" submodule update --init --recursive

echo "==> Creating venv at $VENV_DIR"
python3 -m venv "$VENV_DIR"

echo "==> Installing all three servers (editable)"
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -e "$HUB_ROOT/servers/crocodash" \
                     -e "$HUB_ROOT/servers/regional-ocean-debugger" \
                     -e "$HUB_ROOT/servers/cesm-runner"

echo "==> Generating mcp.local.json"
sed "s#__VENV_BIN__#$VENV_DIR/bin#g" "$HUB_ROOT/mcp.local.json.template" > "$HUB_ROOT/mcp.local.json"

echo
echo "Done. Point your MCP client at:"
echo "  $HUB_ROOT/mcp.local.json"
