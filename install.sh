#!/usr/bin/env bash

# ══════════════════════════════════════════════════════════════════════
# install.sh — Installe claude-setup dans ~/.claude/ via des symlinks.
#
# Principes :
#   - Idempotent : relancer ne change rien si tout est déjà en place.
#   - Non destructif : les fichiers existants sont sauvegardés avant
#     d'être remplacés (dans .backups/ à la racine du projet).
#   - Interactif par défaut, non-interactif avec -y.
# ══════════════════════════════════════════════════════════════════════

# --- Options de sécurité bash ---
# set -e  : arrêter le script si une commande échoue (sauf dans if/while)
# set -u  : arrêter si on utilise une variable non définie (évite les fautes de frappe)
# set -o pipefail : dans un pipe (cmd1 | cmd2), l'erreur de cmd1 n'est pas masquée
set -euo pipefail

# --- Chemins de base ---
# BASH_SOURCE[0] = chemin du script lui-même, même lancé via symlink
# dirname + cd + pwd = chemin absolu du dossier contenant le script
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SOURCE : le dossier claude/ du repo, contenant les fichiers à installer
SOURCE="$REPO_ROOT/claude"

# TARGET : où installer (par défaut ~/.claude/, personnalisable via $CLAUDE_HOME)
# ${VAR:-valeur} = utiliser $VAR si défini, sinon "valeur"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"

# MANIFEST : fichier TSV qui garde la trace de chaque lien créé (pour uninstall)
MANIFEST="$TARGET/.claude-setup-manifest"

# BACKUP_DIR : dossier horodaté dans le projet pour les sauvegardes
# $(date +%Y%m%d-%H%M%S) produit par ex. "20260521-143000"
BACKUP_DIR="$REPO_ROOT/.backups/$(date +%Y%m%d-%H%M%S)"

# --- Drapeaux (flags) ---
# 0 = désactivé, 1 = activé ; modifiés par les arguments en ligne de commande
DRY_RUN=0
BACKUP_ALL=0

# --- Fonctions utilitaires d'affichage ---
# log : affiche une ligne. printf est préféré à echo (comportement plus prévisible)
log()  { printf '%s\n' "$*"; }
# note : affiche une ligne indentée (sous-information)
note() { printf '  %s\n' "$*"; }

# --- Aide ---
# cat <<EOF ... EOF : "here-document", permet d'écrire du texte multi-lignes
# \$ échappe le $ pour qu'il s'affiche littéralement au lieu d'être interprété
usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-y|--backup-all] [-h|--help]

Install claude-setup into \$CLAUDE_HOME (default: ~/.claude) via symlinks.

Options:
  -n, --dry-run      Show what would happen without modifying anything.
  -y, --backup-all   Backup all conflicts without prompting.
  -h, --help         This message.
EOF
}

# --- Lecture des arguments ---
# $# = nombre d'arguments restants. On boucle tant qu'il y en a.
# case "$1" in ... esac : switch/case sur le premier argument
# shift : retire le premier argument (décale $2 → $1, $3 → $2, etc.)
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--backup-all) BACKUP_ALL=1 ;;
    -h|--help) usage ; exit 0 ;;
    *) log "Unknown argument: $1" ; usage ; exit 1 ;;
  esac
  shift
done

# --- Configuration : quoi installer, et comment ---

# ROOT_FILES : fichiers installés directement à la racine de ~/.claude/
ROOT_FILES=("CLAUDE.md" "settings.json")

# FILE_DIRS : dossiers dont chaque FICHIER devient un symlink individuel
# ex: claude/commands/audit.md → ~/.claude/commands/audit.md
FILE_DIRS=("commands" "agents" "scripts")

# DIR_DIRS : dossiers dont chaque SOUS-DOSSIER devient un symlink
# ex: claude/skills/ml-review/ → ~/.claude/skills/ml-review (le dossier entier)
DIR_DIRS=("skills")

# --- Compteurs ---
# declare -i : déclare une variable entière (les += font de l'addition, pas de la concaténation)
declare -i C_LINKED=0
declare -i C_UNCHANGED=0
declare -i C_SKIPPED=0
declare -i C_BACKED_UP=0

# --- Création des dossiers cibles ---
# S'assure que ~/.claude/ et ses sous-dossiers existent avant d'y créer des symlinks.
# mkdir -p : crée le dossier et tous les parents manquants, sans erreur si déjà existant.
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

# --- Journalisation dans le manifest ---
# Ajoute une ligne au manifest : chemin_destination \t chemin_source \t horodatage
# >> : ajoute à la fin du fichier (> écraserait tout)
add_to_manifest() {
  local dst="$1" src="$2"
  [ "$DRY_RUN" -eq 1 ] && return 0
  mkdir -p "$(dirname "$MANIFEST")"
  printf '%s\t%s\t%s\n' "$dst" "$src" "$(date -Iseconds)" >> "$MANIFEST"
}

# --- Sauvegarde + suppression d'un fichier/dossier existant ---
# cp -a : copie en préservant permissions, dates, liens symboliques
# cp -P : ne suit pas les symlinks (copie le lien, pas sa cible)
# rm -rf : supprime récursivement sans demander (-- sépare les options des arguments)
backup_and_remove() {
  local f="$1"
  # ${f#$TARGET/} : retire le préfixe $TARGET/ pour obtenir le chemin relatif
  # ex: /home/jbo/.claude/commands/audit.md → commands/audit.md
  local rel="${f#$TARGET/}"
  local backup="$BACKUP_DIR/$rel"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$backup")"
    cp -aP "$f" "$backup"
    rm -rf -- "$f"
  fi
  note "[backed up] $f → $backup"
  C_BACKED_UP+=1
}

# --- Affichage des différences entre fichier existant et nouveau ---
# diff -rq : compare récursivement deux dossiers (q = noms seulement)
# diff -u  : compare deux fichiers en format "unified" (lisible)
# || true  : empêche diff de faire planter le script (il retourne 1 si différent)
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

# --- Description de ce qui existe à la destination ---
# -L : teste si c'est un symlink
# -d : teste si c'est un dossier
# readlink : lit la cible d'un symlink
# wc -l : compte les lignes ; 2>/dev/null redirige les erreurs vers le néant
describe_target() {
  local dst="$1"
  if [ -L "$dst" ]; then
    note "current : symlink → $(readlink "$dst")"
  elif [ -d "$dst" ]; then
    note "current : directory (regular)"
  else
    note "current : regular file ($(wc -l <"$dst" 2>/dev/null || echo "?") lines)"
  fi
}

# --- Gestion d'un conflit (fichier existant ≠ symlink attendu) ---
# Retourne 0 si le caller doit créer le lien, 1 s'il doit passer au suivant.
handle_conflict() {
  local src="$1" dst="$2"
  log ""
  log "Conflict at: $dst"
  describe_target "$dst"
  note "new     : symlink → $src"

  # Mode automatique : sauvegarder sans demander
  if [ "$BACKUP_ALL" -eq 1 ]; then
    backup_and_remove "$dst"
    return 0
  fi

  # Mode interactif : boucle jusqu'à un choix valide
  local choice=""
  while true; do
    # read -r : ne pas interpréter les \ comme des échappements
    # read -p "texte" : affiche "texte" comme prompt avant de lire
    # </dev/tty : lit depuis le terminal physique (pas stdin qui peut être un pipe)
    # { ... } 2>/dev/null : redirige les erreurs du bloc entier vers /dev/null
    #   (supprime le message bash si /dev/tty n'existe pas)
    if ! { read -r -p "  [v]iew diff / [b]ackup / backup-[a]ll / [s]kip / [q]uit : " choice </dev/tty; } 2>/dev/null; then
      log "Error: no terminal available for interactive prompt."
      log "Use --backup-all (-y) to resolve conflicts non-interactively."
      exit 1
    fi
    # ${choice,,} : convertit en minuscules (bash 4+)
    # case accepte plusieurs valeurs séparées par | (ou)
    case "${choice,,}" in
      v|view|diff)
        show_diff "$dst" "$src" ;;
      b|backup)
        backup_and_remove "$dst"
        return 0
        ;;
      a|all|backup-all)
        BACKUP_ALL=1
        backup_and_remove "$dst"
        return 0
        ;;
      s|skip)
        note "[skipped] $dst"
        C_SKIPPED+=1
        return 1
        ;;
      q|quit|abort)
        log "Aborted by user."
        exit 130
        ;;
      *)
        note "Unknown choice '$choice'. Type b, a, s, v, or q."
        ;;
    esac
  done
}

# --- Création d'un symlink unique ---
# ln -s source destination : crée un lien symbolique
# readlink -f : résout tous les symlinks pour obtenir le chemin canonique
install_link() {
  local src="$1" dst="$2"

  # Déjà notre symlink pointant au bon endroit ? → rien à faire (idempotent)
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    note "[unchanged] $dst"
    C_UNCHANGED+=1
    return 0
  fi

  # Autre chose existe à cet emplacement ? → gérer le conflit
  # -e teste l'existence, -L teste si c'est un symlink (même cassé)
  # || return 0 : si handle_conflict retourne 1 (skip), on sort sans créer le lien
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

# --- Installation des fichiers racine (CLAUDE.md, settings.json) ---
install_root_files() {
  for f in "${ROOT_FILES[@]}"; do
    local src="$SOURCE/$f"
    [ -e "$src" ] || { note "(missing in repo: $f, skipped)" ; continue ; }
    install_link "$src" "$TARGET/$f"
  done
}

# --- Installation des fichiers dans commands/, agents/, scripts/ ---
# find -maxdepth 1 -mindepth 1 : fichiers/dossiers directs (pas récursif)
# -type f : fichiers uniquement
# -print0 : sépare par \0 au lieu de \n (gère les espaces dans les noms)
# read -d '' : lit jusqu'au \0 (correspondant au -print0 de find)
# < <(...) : "process substitution" — la sortie de find alimente la boucle while
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

# --- Installation des sous-dossiers de skills/ ---
# Même logique que install_file_dirs mais avec -type d (dossiers)
# Chaque skill est un dossier atomique → un seul symlink par skill
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

# --- Vérification de ruff (formateur Python) ---
# command -v : vérifie si une commande existe dans le PATH (plus fiable que which)
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

# --- Point d'entrée ---
main() {
  log "Installing claude-setup"
  log "  source : $SOURCE"
  log "  target : $TARGET"
  log "  backups: $REPO_ROOT/.backups/"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "  mode   : DRY RUN (nothing will be changed)"
  fi
  if [ "$BACKUP_ALL" -eq 1 ]; then
    log "  mode   : BACKUP ALL (no prompts)"
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

# "$@" passe tous les arguments du script à main()
main "$@"
