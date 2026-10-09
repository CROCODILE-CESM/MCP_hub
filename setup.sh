#!/usr/bin/env bash
# Sets up all four MCP servers in one local Python environment, for use on
# machines without outbound internet access at launch time (e.g. HPC compute
# nodes). Generates mcp.local.json pointing an MCP client at the installed
# console scripts.
#
# For normal desktop/laptop use with internet access, you likely don't need
# this at all -- just point your MCP client at mcp.json instead.
#
# crocodash-mcp requires ESMF/xesmf, which are conda-only compiled libraries
# that a plain venv cannot provide. If you already have a conda env with
# ESMF/xesmf installed (e.g. the env you use for the CrocoDash CLI itself),
# point this script at it instead of creating a fresh venv:
#
#   PYTHON_BIN=/path/to/envs/CrocoDash/bin/python ./setup.sh
#
# Without PYTHON_BIN, a fresh venv is created using the first of
# python3.12/python3.11/python3.10/python3 found that satisfies the servers'
# minimum Python version (3.11) -- but crocodash-mcp will fail at import time
# in that venv unless ESMF/xesmf are separately made available to it.
set -euo pipefail

HUB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$HUB_ROOT/.venv"

echo "==> Syncing submodules"
git -C "$HUB_ROOT" submodule update --init --recursive

if [ -n "${PYTHON_BIN:-}" ]; then
    echo "==> Using existing interpreter: $PYTHON_BIN"
    BIN_DIR="$(dirname "$PYTHON_BIN")"
    PIP_BIN="$BIN_DIR/pip"
else
    PYTHON=""
    for candidate in python3.12 python3.11 python3.10 python3; do
        if command -v "$candidate" >/dev/null 2>&1; then
            ver="$("$candidate" -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
            major="${ver%.*}"; minor="${ver#*.}"
            if [ "$major" -eq 3 ] && [ "$minor" -ge 11 ]; then
                PYTHON="$candidate"
                break
            fi
        fi
    done
    if [ -z "$PYTHON" ]; then
        echo "ERROR: no Python 3.11+ interpreter found (checked python3.12/3.11/3.10/python3)." >&2
        echo "Install one, or pass an existing env via PYTHON_BIN=/path/to/python ./setup.sh" >&2
        exit 1
    fi
    echo "==> Creating venv at $VENV_DIR using $PYTHON"
    "$PYTHON" -m venv "$VENV_DIR"
    BIN_DIR="$VENV_DIR/bin"
    PIP_BIN="$BIN_DIR/pip"
fi

echo "==> Installing all four servers (editable)"
"$PIP_BIN" install --upgrade pip -q
"$PIP_BIN" install -e "$HUB_ROOT/servers/crocodash" \
                    -e "$HUB_ROOT/servers/regional-ocean-debugger" \
                    -e "$HUB_ROOT/servers/cesm-runner" \
                    -e "$HUB_ROOT/servers/mom6-tools"

echo "==> Generating mcp.local.json"
# mom6-tools runs its library work in the mom6-tools conda env: pass that env's
# python as MOM6_TOOLS_PYTHON. Left unset, it uses the hub env's own python,
# which only works if mom6_tools is installed there.
sed -e "s#__VENV_BIN__#$BIN_DIR#g" \
    -e "s#__MOM6_TOOLS_PYTHON__#${MOM6_TOOLS_PYTHON:-$BIN_DIR/python}#g" \
    "$HUB_ROOT/mcp.local.json.template" > "$HUB_ROOT/mcp.local.json"

echo
echo "Done. Point your MCP client at:"
echo "  $HUB_ROOT/mcp.local.json"
