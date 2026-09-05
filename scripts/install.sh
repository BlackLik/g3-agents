#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

OPENCODE_FILES="flow.md subflow.md player.md coach.md"
OPENCODE_REF_FILES="coach-reference.md flow-reference.md"
CLAUDE_FILES="flow.md subflow.md player.md coach.md"
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

install_one() {
  local src="$1" dest="$2" files="$3" f
  mkdir -p "$dest"
  if [ "$(cd "$src" && pwd)" = "$(cd "$dest" && pwd)" ]; then
    echo "skip: $src == $dest"
    return
  fi
  for f in $files; do
    cp "$src/$f" "$dest/$f"
  done
  echo "installed: $dest"
}

if [ "$tool" = "opencode" ] || [ "$tool" = "all" ]; then
  [ "$target" = "--global" ] && base="$HOME/.config/opencode" || base="./.opencode"
  install_one "$REPO_ROOT/.opencode/agents" "$base/agents" "$OPENCODE_FILES"
  install_one "$REPO_ROOT/.opencode/reference" "$base/reference" "$OPENCODE_REF_FILES"
fi

if [ "$tool" = "claude" ] || [ "$tool" = "all" ]; then
  [ "$target" = "--global" ] && base="$HOME/.claude" || base="./.claude"
  install_one "$REPO_ROOT/.claude/agents" "$base/agents" "$CLAUDE_FILES"
  install_one "$REPO_ROOT/.claude/reference" "$base/reference" "$CLAUDE_REF_FILES"
fi
