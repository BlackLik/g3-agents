#!/usr/bin/env bash
set -euo pipefail

OPENCODE_FILES="flow.md subflow.md player.md coach.md"
OPENCODE_REF_FILES="coach-reference.md flow-reference.md"
CLAUDE_FILES="flow.md player.md coach.md"
CLAUDE_REF_FILES="coach-reference.md flow-reference.md"

usage() {
  echo "Usage: $0 <opencode|claude|all> [--global|--local]" >&2
  exit 1
}

[ $# -ge 1 ] || usage
tool="$1"
target="${2:---global}"
case "$tool" in opencode|claude|all) ;; *) usage ;; esac
case "$target" in --global|--local) ;; *) usage ;; esac

uninstall_one() {
  local dest="$1" files="$2" f
  for f in $files; do
    rm -f "$dest/$f"
  done
  echo "uninstalled: $dest"
}

if [ "$tool" = "opencode" ] || [ "$tool" = "all" ]; then
  [ "$target" = "--global" ] && base="$HOME/.config/opencode" || base="./.opencode"
  uninstall_one "$base/agents" "$OPENCODE_FILES"
  uninstall_one "$base/reference" "$OPENCODE_REF_FILES"
fi

if [ "$tool" = "claude" ] || [ "$tool" = "all" ]; then
  [ "$target" = "--global" ] && base="$HOME/.claude" || base="./.claude"
  uninstall_one "$base/agents" "$CLAUDE_FILES"
  uninstall_one "$base/reference" "$CLAUDE_REF_FILES"
fi
