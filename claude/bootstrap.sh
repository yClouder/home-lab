#!/usr/bin/env bash
# Bootstrap Claude Code config from this repo on a fresh machine.
#
# Idempotent: safe to re-run. Backs up any existing ~/.claude/* files into
# ~/.claude/.pre-bootstrap-<timestamp>/ before symlinking.
#
# Usage:
#   git clone git@github.com:yClouder/home-lab.git ~/dev/home-lab
#   ~/dev/home-lab/claude/bootstrap.sh
#
# What it does:
#   ~/.claude/skills       -> <repo>/claude/skills
#   ~/.claude/commands     -> <repo>/claude/commands
#   ~/.claude/CLAUDE.md    -> <repo>/claude/CLAUDE.md
#   ~/.claude/settings.json -> <repo>/claude/settings.json

set -euo pipefail

# Resolve this script's directory regardless of where it was invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
BACKUP_DIR="${CLAUDE_DIR}/.pre-bootstrap-$(date +%Y%m%d-%H%M%S)"

mkdir -p "${CLAUDE_DIR}"

needs_backup=0
for item in skills commands CLAUDE.md settings.json; do
  target="${CLAUDE_DIR}/${item}"
  # Only flag for backup if the path exists AND is not already the correct symlink.
  if [ -e "${target}" ] || [ -L "${target}" ]; then
    if [ -L "${target}" ] && [ "$(readlink "${target}")" = "${SCRIPT_DIR}/${item}" ]; then
      continue
    fi
    needs_backup=1
  fi
done

if [ "${needs_backup}" = "1" ]; then
  mkdir -p "${BACKUP_DIR}"
  echo "Backing up existing ~/.claude items to ${BACKUP_DIR}"
fi

for item in skills commands CLAUDE.md settings.json; do
  target="${CLAUDE_DIR}/${item}"
  source="${SCRIPT_DIR}/${item}"

  if [ ! -e "${source}" ]; then
    echo "warning: source missing, skipping: ${source}" >&2
    continue
  fi

  if [ -L "${target}" ] && [ "$(readlink "${target}")" = "${source}" ]; then
    echo "ok (already linked): ${target}"
    continue
  fi

  if [ -e "${target}" ] || [ -L "${target}" ]; then
    mv "${target}" "${BACKUP_DIR}/${item}"
  fi

  ln -s "${source}" "${target}"
  echo "linked: ${target} -> ${source}"
done

echo
echo "Done. Restart Claude Code to pick up the new skills, commands, and CLAUDE.md."
