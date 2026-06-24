#!/usr/bin/env bash
# Uninstall OpenCode-Go Power Pack and restore opencode to stock configuration.
#
# Usage:
#   ./uninstall.sh                  # restore config, keep skills
#   ./uninstall.sh --full           # complete removal
#   ./uninstall.sh --full --dry-run # preview full removal
#   ./uninstall.sh --keep-backups   # restore but preserve backup files
#   ./uninstall.sh --remove-skills  # also remove skill packs
#   ./uninstall.sh --remove-mcp     # also uninstall MCP packages

set -euo pipefail

KEEP_BACKUPS=false
REMOVE_SKILLS=false
REMOVE_MCP=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)         REMOVE_SKILLS=true; REMOVE_MCP=true; shift ;;
    --keep-backups) KEEP_BACKUPS=true; shift ;;
    --remove-skills) REMOVE_SKILLS=true; shift ;;
    --remove-mcp)   REMOVE_MCP=true; shift ;;
    --dry-run)      DRY_RUN=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--full] [--keep-backups] [--remove-skills] [--remove-mcp] [--dry-run]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

CONFIG_DIR="${HOME}/.config/opencode"
MANIFEST_PATH="${CONFIG_DIR}/.power-pack-manifest.json"
REMOVED_FILES=0
REMOVED_DIRS=0

step()  { printf "\n\033[36m=== %s ===\033[0m\n" "$1"; }
okk()   { printf "  \033[32m[OK]\033[0m %s\n" "$1"; }
warnn() { printf "  \033[33m[WARN]\033[0m %s\n" "$1"; }
infoo() { printf "  \033[90m%s\033[0m\n" "$1"; }
errr()  { printf "  \033[31m[ERR]\033[0m %s\n" "$1"; }

if [[ ! -f "$MANIFEST_PATH" ]]; then
  errr "Manifest not found: $MANIFEST_PATH"
  errr "Cannot safely uninstall without the manifest."
  errr "You can manually delete ~/.config/opencode/ to reset to stock."
  exit 1
fi

# ── Restore backup config ──────────────────────────────────────────────────
step "Restore config"

CONFIG_FILE="${CONFIG_DIR}/opencode.json"
LATEST_BACKUP=$(ls -1 "${CONFIG_DIR}"/opencode.json.backup-* 2>/dev/null | sort -r | head -1)

if [[ -n "$LATEST_BACKUP" ]]; then
  if ! $DRY_RUN; then cp "$LATEST_BACKUP" "$CONFIG_FILE"; fi
  okk "Restored config from backup: $(basename "$LATEST_BACKUP")"

  if ! $KEEP_BACKUPS; then
    for b in "${CONFIG_DIR}"/opencode.json.backup-*; do
      [[ -f "$b" ]] || continue
      if ! $DRY_RUN; then rm -f "$b"; fi
      infoo "Removed backup: $(basename "$b")"
    done
  else
    infoo "Keeping backup files (--keep-backups)"
  fi
else
  warnn "No backup found — writing minimal stock config."
  if ! $DRY_RUN; then
    echo '{"$schema":"https://opencode.ai/config.json"}' > "$CONFIG_FILE"
  fi
  okk "Wrote minimal stock config."
fi

# ── Remove agents ──────────────────────────────────────────────────────────
step "Remove agents"
for a in build.md plan.md reviewer.md explorer.md data-engineer.md frontend-engineer.md devops-engineer.md doc-writer.md; do
  p="${CONFIG_DIR}/agents/${a}"
  if [[ -f "$p" ]]; then
    if ! $DRY_RUN; then rm -f "$p"; fi
    okk "Removed: agents/$a"; ((REMOVED_FILES++))
  fi
done

# ── Remove commands ────────────────────────────────────────────────────────
step "Remove commands"
for c in review.md plan.md test.md ship.md debug.md refactor.md docs.md; do
  p="${CONFIG_DIR}/commands/${c}"
  if [[ -f "$p" ]]; then
    if ! $DRY_RUN; then rm -f "$p"; fi
    okk "Removed: commands/$c"; ((REMOVED_FILES++))
  fi
done

# ── Remove AGENTS.md ───────────────────────────────────────────────────────
step "Remove AGENTS.md"
p="${CONFIG_DIR}/AGENTS.md"
if [[ -f "$p" ]]; then
  if ! $DRY_RUN; then rm -f "$p"; fi
  okk "Removed: AGENTS.md"; ((REMOVED_FILES++))
fi

# ── Remove profiles ────────────────────────────────────────────────────────
step "Remove profiles"
p="${CONFIG_DIR}/profiles"
if [[ -d "$p" ]]; then
  if ! $DRY_RUN; then rm -rf "$p"; fi
  okk "Removed: profiles/"; ((REMOVED_DIRS++))
fi

# ── Remove skills ──────────────────────────────────────────────────────────
if $REMOVE_SKILLS; then
  step "Remove skills"
  SKILLS_DIR="${CONFIG_DIR}/skills"
  if [[ -d "$SKILLS_DIR" ]]; then
    # custom-* skills
    for d in "$SKILLS_DIR"/custom-*; do
      [[ -d "$d" ]] || continue
      if ! $DRY_RUN; then rm -rf "$d"; fi
      okk "Removed skill: $(basename "$d")"; ((REMOVED_DIRS++))
    done
    # third-party packs
    for tp in coderabbitai farmage addyosmani obra-superpowers-skills superpowers-lab; do
      p="${SKILLS_DIR}/${tp}"
      if [[ -d "$p" ]]; then
        if ! $DRY_RUN; then rm -rf "$p"; fi
        okk "Removed skill pack: $tp"; ((REMOVED_DIRS++))
      fi
    done
    # cherry-picked
    for cp in frontend-design tdd diagnose triage improve-codebase-architecture next-best-practices vercel-react-best-practices supabase-postgres-best-practices shadcn skill-creator; do
      p="${SKILLS_DIR}/${cp}"
      if [[ -d "$p" ]]; then
        if ! $DRY_RUN; then rm -rf "$p"; fi
        okk "Removed cherry-picked skill: $cp"; ((REMOVED_DIRS++))
      fi
    done
    # Remove if empty
    if [[ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]]; then
      if ! $DRY_RUN; then rm -rf "$SKILLS_DIR"; fi
      okk "Removed empty: skills/"; ((REMOVED_DIRS++))
    fi
  fi
else
  step "Keep skills (--remove-skills not set)"
  infoo "Skill packs will remain installed."
fi

# ── Remove MCP packages ────────────────────────────────────────────────────
if $REMOVE_MCP; then
  step "Remove MCP packages (npm global)"
  if command -v npm &>/dev/null; then
    for pkg in @playwright/mcp @modelcontextprotocol/server-github @modelcontextprotocol/server-sequential-thinking @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-memory think-mcp-server repomix @sriinnu/pakt @ast-grep/cli jscodeshift code-review-graph headroom-ai; do
      infoo "npm uninstall -g $pkg"
      if ! $DRY_RUN; then npm uninstall -g "$pkg" &>/dev/null || true; fi
    done
    okk "npm global packages removed (if installed)"
  else
    warnn "npm not available — skipping package removal"
  fi
else
  step "Keep MCP packages (--remove-mcp not set)"
fi

# ── Remove manifest ────────────────────────────────────────────────────────
step "Remove manifest"
if [[ -f "$MANIFEST_PATH" ]]; then
  if ! $DRY_RUN; then rm -f "$MANIFEST_PATH"; fi
  okk "Removed: .power-pack-manifest.json"
fi

# Remove scripts dir if empty
p="${CONFIG_DIR}/scripts"
if [[ -d "$p" && -z "$(ls -A "$p" 2>/dev/null)" ]]; then
  if ! $DRY_RUN; then rm -rf "$p"; fi
  okk "Removed empty: scripts/"
fi

# ── Summary ────────────────────────────────────────────────────────────────
step "Summary"
echo ""
printf "  Files removed:  %d\n" "$REMOVED_FILES"
printf "  Dirs removed:   %d\n" "$REMOVED_DIRS"
printf "  Config:         restored to stock (or backup)\n"
echo ""
printf "  \033[33mIMPORTANT: Restart opencode for changes to take effect.\033[0m\n"
echo ""
if $DRY_RUN; then
  printf "  \033[35m(DRY-RUN: no changes were actually made)\033[0m\n"
fi
