# MCP_hub

Single entry point for the CROCODILE-CESM MCP servers. Wires up all three
so an MCP client (Claude Desktop, Claude Code, Cursor, etc.) can load them
together, and vendors the source of each as a submodule for offline/HPC use.

## The servers

| Server | Repo | Role |
|---|---|---|
| `crocodash` | [MCP_CrocoDash](https://github.com/CROCODILE-CESM/MCP_CrocoDash) | Configure and deploy regional MOM6 ocean models within CESM (create/process/bundle a case) |
| `cesm-runner` | [MCP_cesm_runner](https://github.com/CROCODILE-CESM/MCP_cesm_runner) | Drive a CESM case through setup, build, submit, and monitoring (bare-metal or container) |
| `regional-ocean-debugger` | [MCP_regional_ocean_debugger](https://github.com/CROCODILE-CESM/MCP_regional_ocean_debugger) | Post-run diagnostics and scientific guidance for MOM6/CESM runs |

They're designed to be used together across a run's lifecycle: `crocodash`
creates and configures a case, `cesm-runner` builds/submits/monitors it, and
`regional-ocean-debugger` helps diagnose the result. See each server's own
`server.py` docstring for the exact deployment paths (HPC batch queue, HPC +
container, laptop + container).

## Quick start (recommended): remote, via `uvx`

No local checkout needed. Requires [`uv`](https://docs.astral.sh/uv/) and
outbound internet access at launch time. Point your MCP client's config at
this repo's [mcp.json](mcp.json), or copy its `mcpServers` block into your
client's own config file.

## Offline / HPC setup

Compute nodes often lack outbound internet access, so `uvx --from git+...`
won't work there. Instead, vendor and install all three servers locally:

```bash
git clone --recurse-submodules https://github.com/CROCODILE-CESM/MCP_hub.git
cd MCP_hub
./setup.sh
```

This creates a single venv, installs all three servers into it (editable),
and generates `mcp.local.json` (git-ignored, since it contains absolute
paths) pointing at the installed console scripts. Point your MCP client at
`mcp.local.json` instead of `mcp.json`.

`crocodash-mcp` needs ESMF/`xesmf`, which are conda-only compiled libraries
a plain venv can't provide. If you already have a conda env with those
installed (e.g. whatever env you use for the CrocoDash CLI itself), install
into it instead of a fresh venv:

```bash
PYTHON_BIN=/path/to/envs/CrocoDash/bin/python ./setup.sh
```

## Updating the vendored servers

The submodules are pinned to specific commits. To bump all three to the
latest `main`:

```bash
./update-submodules.sh
```

Review the diff, then commit the updated submodule pointers.

## Layout

```
mcp.json                   # default config: remote servers via uvx
mcp.local.json.template    # template for offline config, filled in by setup.sh
setup.sh                   # one-time offline/HPC setup (venv + editable installs)
update-submodules.sh       # bump vendored servers to latest main
servers/
  crocodash/                  # submodule -> MCP_CrocoDash
  cesm-runner/                # submodule -> MCP_cesm_runner
  regional-ocean-debugger/    # submodule -> MCP_regional_ocean_debugger
```
