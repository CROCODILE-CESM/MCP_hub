#!/usr/bin/env bash
# Bumps all three vendored servers to the latest commit on their main branch
# and stages the resulting pointer changes for review/commit.
set -euo pipefail

HUB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git -C "$HUB_ROOT" submodule update --remote --merge
git -C "$HUB_ROOT" add servers
git -C "$HUB_ROOT" status --short servers
echo
echo "Submodule pointers updated above. Review with 'git diff --cached' and commit when ready."
