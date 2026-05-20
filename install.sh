#!/usr/bin/env bash
# Install claude-setup into ~/.claude/ via symlinks.
# Idempotent: re-running only adds missing links and reports unchanged ones.
# Conflicts (existing files at target paths) are handled interactively.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$REPO_ROOT/claude"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
MANIFEST="$TARGET/.claude-setup-manifest"
BACKUP_DIR="$TARGET/.backups/$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0

log()  { printf '%s\n' "$*"; }
note() { printf '  %s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-h|--help]

Install claude-setup into \$CLAUDE_HOME (default: ~/.claude) via symlinks.

Options:
  -n, --dry-run   Show what would happen without modifying anything.
  -h, --help      This message.
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

# Files installed at the root of ~/.claude/ (one symlink each)
ROOT_FILES=("CLAUDE.md" "settings.json")

# Directories whose individual files become symlinks
FILE_DIRS=("commands" "agents" "scripts")

# Directories whose immediate sub-directories become symlinks (skills are atomic)
DIR_DIRS=("skills")

# Counters
declare -i C_LINKED=0
declare -i C_UNCHANGED=0
declare -i C_SKIPPED=0
declare -i C_BACKED_UP=0

ensure_target() {
  if [ ! -d "$TARGET" ]; then
    log "Creating $TARGET"
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir -p "$TARGET"
    fi
  fi
  for d in "${FILE_DIRS[@]}" "${DIR_DIRS[@]}"; do
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir -p "$TARGET/$d"
    fi
  done
}

add_to_manifest() {
  local dst="$1" src="$2"
  [ "$DRY_RUN" -eq 1 ] && return 0
  mkdir -p "$(dirname "$MANIFEST")"
  printf '%s\t%s\t%s\n' "$dst" "$src" "$(date -Iseconds)" >> "$MANIFEST"
}

backup_file() {
  local f="$1"
  local rel="${f#$TARGET/}"
  local backup="$BACKUP_DIR/$rel"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$backup")"
    cp -aP "$f" "$backup"
  fi
  note "[backed up] $f → $backup"
  C_BACKED_UP+=1
}

show_diff() {
  local existing="$1" incoming="$2"
  if [ -d "$existing" ] && [ -d "$incoming" ]; then
    diff -rq "$existing" "$incoming" || true
  elif [ -f "$existing" ] && [ -f "$incoming" ]; then
    diff -u "$existing" "$incoming" || true
  else
    log "(cannot diff: mixed file/dir or special files)"
  fi
}

handle_conflict() {
  # Returns 0 if caller should proceed to link, 1 if caller should skip.
  local src="$1" dst="$2"
  log ""
  log "Conflict at: $dst"
  if [ -L "$dst" ]; then
    note "current : symlink → $(readlink "$dst")"
  elif [ -d "$dst" ]; then
    note "current : directory (regular)"
  else
    note "current : regular file ($(wc -l <"$dst" 2>/dev/null || echo "?") lines)"
  fi
  note "new     : symlink → $src"

  while true; do
    read -r -p "  [v]iew diff / [b]ackup-and-link / [s]kip / [a]bort all : " choice </dev/tty
    case "${choice,,}" in
      v) show_diff "$dst" "$src" ;;
      b)
        backup_file "$dst"
        if [ "$DRY_RUN" -eq 0 ]; then
          rm -rf -- "$dst"
        fi
        return 0
        ;;
      s) note "[skipped] $dst" ; C_SKIPPED+=1 ; return 1 ;;
      a) log "Aborted by user." ; exit 130 ;;
      *) note "Unknown choice '$choice'." ;;
    esac
  done
}

install_link() {
  local src="$1" dst="$2"

  # Already our symlink pointing at the right source ? no-op (idempotent).
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    note "[unchanged] $dst"
    C_UNCHANGED+=1
    return 0
  fi

  # Something else at the target ? prompt.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    handle_conflict "$src" "$dst" || return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    note "[would link] $dst → $src"
  else
    ln -s "$src" "$dst"
    add_to_manifest "$dst" "$src"
    note "[linked] $dst → $src"
  fi
  C_LINKED+=1
}

install_root_files() {
  for f in "${ROOT_FILES[@]}"; do
    local src="$SOURCE/$f"
    [ -e "$src" ] || { note "(missing in repo: $f, skipped)" ; continue ; }
    install_link "$src" "$TARGET/$f"
  done
}

install_file_dirs() {
  local d
  for d in "${FILE_DIRS[@]}"; do
    local src_dir="$SOURCE/$d"
    [ -d "$src_dir" ] || continue
    while IFS= read -r -d '' src; do
      install_link "$src" "$TARGET/$d/$(basename "$src")"
    done < <(find "$src_dir" -maxdepth 1 -mindepth 1 -type f -print0)
  done
}

install_dir_dirs() {
  local d
  for d in "${DIR_DIRS[@]}"; do
    local src_dir="$SOURCE/$d"
    [ -d "$src_dir" ] || continue
    while IFS= read -r -d '' src; do
      install_link "$src" "$TARGET/$d/$(basename "$src")"
    done < <(find "$src_dir" -maxdepth 1 -mindepth 1 -type d -print0)
  done
}

check_ruff() {
  if ! command -v ruff >/dev/null 2>&1; then
    log ""
    log "Warning : ruff not found in PATH."
    log "The Python formatting hook in settings.json will silently fail on every Python edit."
    log "Install with one of :"
    log "  pipx install ruff   # recommended"
    log "  uv tool install ruff"
    log "  pip install ruff"
  fi
}

main() {
  log "Installing claude-setup"
  log "  source : $SOURCE"
  log "  target : $TARGET"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  mode   : DRY RUN (nothing will be changed)"
  fi
  log ""

  if [ ! -d "$SOURCE" ]; then
    log "Error : $SOURCE not found. Run install.sh from the repo root."
    exit 1
  fi

  ensure_target

  install_root_files
  install_file_dirs
  install_dir_dirs

  check_ruff

  log ""
  log "Summary :"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  would link : $C_LINKED"
  else
    log "  linked     : $C_LINKED"
  fi
  log "  unchanged  : $C_UNCHANGED"
  log "  skipped    : $C_SKIPPED"
  log "  backed up  : $C_BACKED_UP"
  if [ "$C_BACKED_UP" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    log "  backups at $BACKUP_DIR"
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    log "  manifest  : $MANIFEST"
  fi
}

main "$@"
