#!/usr/bin/env bash
# Uninstall claude-setup symlinks listed in the manifest.
# Safety: only removes symlinks whose current target still matches what was installed.
# Anything modified by the user or installed by a third party is left untouched.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
MANIFEST="$TARGET/.claude-setup-manifest"
BACKUPS_ROOT="$TARGET/.backups"

DRY_RUN=0

log()  { printf '%s\n' "$*"; }
note() { printf '  %s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-h|--help]

Uninstall claude-setup symlinks recorded in $MANIFEST.
Only removes links that still point to the source they were installed from.

Options:
  -n, --dry-run   Show what would be removed without modifying anything.
  -h, --help      This message.

Backups (from past install runs) are NOT removed automatically.
They live under $BACKUPS_ROOT and can be restored manually if needed.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage ; exit 0 ;;
    *) log "Unknown argument: $1" ; usage ; exit 1 ;;
  esac
  shift
done

# Counters
declare -i C_REMOVED=0
declare -i C_ALREADY_GONE=0
declare -i C_MISMATCH=0
declare -i C_NOT_A_LINK=0

remove_link() {
  local dst="$1" expected_src="$2"

  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    note "[already gone] $dst"
    C_ALREADY_GONE+=1
    return 0
  fi

  if [ ! -L "$dst" ]; then
    note "[not a symlink, kept] $dst"
    C_NOT_A_LINK+=1
    return 0
  fi

  local current
  current="$(readlink -f "$dst")"
  local expected
  expected="$(readlink -f "$expected_src" 2>/dev/null || echo "$expected_src")"

  if [ "$current" != "$expected" ]; then
    note "[target changed, kept] $dst → $current (expected $expected)"
    C_MISMATCH+=1
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    note "[would remove] $dst"
  else
    rm -- "$dst"
    note "[removed] $dst"
  fi
  C_REMOVED+=1
}

cleanup_empty_dirs() {
  # Remove empty subdirs we manage (commands/, agents/, scripts/, skills/) — only if truly empty.
  for d in commands agents scripts skills; do
    local p="$TARGET/$d"
    if [ -d "$p" ] && [ -z "$(ls -A "$p" 2>/dev/null)" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        note "[would remove empty dir] $p"
      else
        rmdir "$p"
        note "[removed empty dir] $p"
      fi
    fi
  done
}

main() {
  log "Uninstalling claude-setup"
  log "  target   : $TARGET"
  log "  manifest : $MANIFEST"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  mode     : DRY RUN (nothing will be changed)"
  fi
  log ""

  if [ ! -f "$MANIFEST" ]; then
    log "No manifest found at $MANIFEST — nothing to uninstall."
    exit 0
  fi

  # Read manifest line by line. Format: <target>\t<source>\t<iso_timestamp>
  while IFS=$'\t' read -r dst src _ts; do
    [ -z "$dst" ] && continue
    remove_link "$dst" "$src"
  done < "$MANIFEST"

  cleanup_empty_dirs

  # Remove manifest if all entries were cleaned.
  if [ "$C_MISMATCH" -eq 0 ] && [ "$C_NOT_A_LINK" -eq 0 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      note "[would remove manifest] $MANIFEST"
    else
      rm -- "$MANIFEST"
      note "[removed manifest] $MANIFEST"
    fi
  else
    note "[manifest kept] $MANIFEST — some entries were not removable (see warnings above)"
  fi

  log ""
  log "Summary :"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  would remove : $C_REMOVED"
  else
    log "  removed      : $C_REMOVED"
  fi
  log "  already gone : $C_ALREADY_GONE"
  log "  target changed (kept) : $C_MISMATCH"
  log "  not a symlink (kept)  : $C_NOT_A_LINK"

  if [ -d "$BACKUPS_ROOT" ] && [ -n "$(ls -A "$BACKUPS_ROOT" 2>/dev/null)" ]; then
    log ""
    log "Backups still present at $BACKUPS_ROOT :"
    ls -1t "$BACKUPS_ROOT" | head -5 | sed 's/^/  /'
    log "  (kept on purpose — delete manually with: rm -rf $BACKUPS_ROOT/<timestamp>)"
  fi
}

main "$@"
