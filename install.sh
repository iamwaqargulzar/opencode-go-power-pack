#!/usr/bin/env bash
# OpenCode-Go Power Pack installer (macOS/Linux)
# Provisions opencode with autonomous agents, MCP servers, skills, spec-driven dev,
# and a lossless token-reduction stack — locked to the opencode-go subscription.
#
# Usage:
#   ./install.sh                 # standard tier (default)
#   ./install.sh --tier full     # full tier
#   ./install.sh --tier lean     # lean tier
#   ./install.sh --skip-mcp      # skip MCP prefetch
#   ./install.sh --skip-skills   # skip third-party skill packs
#   ./install.sh --dry-run       # show what would be installed
#   ./install.sh --force         # overwrite without prompting

set -euo pipefail

# ── Defaults ───────────────────────────────────────────────────────────────
TIER="standard"
FORCE=false
SKIP_MCP=false
SKIP_SKILLS=false
DRY_RUN=false

# ── Parse args ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)        TIER="$2"; shift 2 ;;
    --tier=*)      TIER="${1#*=}"; shift ;;
    --force)       FORCE=true; shift ;;
    --skip-mcp)    SKIP_MCP=true; shift ;;
    --skip-skills) SKIP_SKILLS=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--tier lean|standard|full] [--force] [--skip-mcp] [--skip-skills] [--dry-run]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

case "$TIER" in lean|standard|full) ;; *) echo "Invalid tier: $TIER"; exit 1 ;; esac

# Catch errors so the user can read the output before the terminal closes
trap 'echo ""; echo "  ERROR on line $LINENO: $BASH_COMMAND"; echo "  Press Enter to close..."; read -r; exit 1' ERR

# ── Paths ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config/opencode"
MANIFEST_PATH="${CONFIG_DIR}/.power-pack-manifest.json"

# ── Helpers ────────────────────────────────────────────────────────────────
step()  { printf "\n\033[36m=== %s ===\033[0m\n" "$1"; }
ok()    { printf "  \033[32m[OK]\033[0m %s\n" "$1"; }
warn()  { printf "  \033[33m[WARN]\033[0m %s\n" "$1"; }
err()   { printf "  \033[31m[ERR]\033[0m %s\n" "$1"; }
info()  { printf "  \033[90m%s\033[0m\n" "$1"; }

has() { command -v "$1" &>/dev/null; }

run() {
  if $DRY_RUN; then info "DRY-RUN: $*"; return 0; fi
  "$@" 2>&1 | while IFS= read -r line; do info "$line"; done
  return "${PIPESTATUS[0]}"
}

# Manifest array
MANIFEST_FILES=()
MANIFEST_DIRS=()
MANIFEST_PKGS=()

# ── Preflight: required prerequisites ──────────────────────────────────────
step "Preflight: required prerequisites"

MISSING=()

# git
if has git; then
  GIT_VER=$(git --version 2>/dev/null)
  ok "git: $GIT_VER"
else
  MISSING+=("git")
  err "git NOT found. Install: https://git-scm.com/downloads"
fi

# node (v18+)
if has node; then
  NODE_VER=$(node --version 2>/dev/null)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/^v\([0-9]*\).*/\1/')
  if [[ "$NODE_MAJOR" -ge 18 ]]; then
    ok "node: $NODE_VER"
  else
    MISSING+=("node (v18+)")
    err "node $NODE_VER is too old — need v18+. Update: https://nodejs.org"
  fi
else
  MISSING+=("node (v18+)")
  err "node NOT found. Install: https://nodejs.org"
fi

# npm
if has npm; then
  NPM_VER=$(npm --version 2>/dev/null)
  ok "npm: $NPM_VER"
else
  MISSING+=("npm")
  err "npm NOT found. Ships with Node.js — install from https://nodejs.org"
fi

# npx (ships with npm v5+)
if has npx; then
  NPX_VER=$(npx --version 2>/dev/null)
  ok "npx: $NPX_VER"
else
  MISSING+=("npx")
  err "npx NOT found. Ships with npm v5+ — update: npm install -g npm@latest"
fi

# If any required prerequisite is missing, stop now
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  printf "  \033[31mMISSING PREREQUISITES: %s\033[0m\n" "${MISSING[*]}"
  printf "  \033[33mInstall the above tools, then re-run this script.\033[0m\n"
  echo ""
  exit 1
fi

# ── Preflight: recommended prerequisites ───────────────────────────────────
step "Preflight: recommended prerequisites (warnings only)"

# python
if has python3 || has python; then
  PYTHON_BIN="python3"; has python3 || PYTHON_BIN="python"
  PY_VER=$($PYTHON_BIN --version 2>&1)
  ok "python: $PY_VER"
else
  warn "python NOT found. Install: https://www.python.org/downloads/"
  warn "  Without python: no uvx, no Python MCP servers, no code-review-graph, no libcst."
fi

# uvx
if has uvx; then
  UVX_VER=$(uvx --version 2>/dev/null)
  ok "uvx: $UVX_VER"
else
  warn "uvx NOT found. Install: pip install uv"
  warn "  Without uvx: no Python MCP servers, no ast-outline, no GitHub Spec Kit."
  SKIP_MCP=true
fi

# gh CLI
if has gh; then
  GH_VER=$(gh --version 2>/dev/null | head -1)
  ok "gh: $GH_VER"
  if gh auth status &>/dev/null; then
    ok "gh: authenticated"
  else
    warn "gh CLI found but NOT authenticated. Run: gh auth login"
    warn "  Without auth: GitHub MCP token will use {env:GITHUB_TOKEN} placeholder."
  fi
else
  warn "gh CLI NOT found. Install: https://cli.github.com/"
  warn "  Without gh: GitHub MCP token will use {env:GITHUB_TOKEN} placeholder."
fi

# bun (optional)
if has bun; then
  ok "bun: found (optional)"
else
  info "bun not found (optional — not required for any core feature)"
fi

# ── Preflight: check opencode-go auth ──────────────────────────────────────
step "Preflight: opencode-go subscription"

AUTH_FILE="${HOME}/.local/share/opencode/auth.json"
if [[ -f "$AUTH_FILE" ]]; then
  if python3 -c "import json; d=json.load(open('$AUTH_FILE')); assert 'opencode-go' in d" 2>/dev/null; then
    ok "opencode-go: authenticated"
  else
    warn "opencode-go subscription NOT found in auth.json."
    warn "  Run /connect in opencode TUI, select 'OpenCode Go', paste API key from https://opencode.ai/auth"
  fi
else
  warn "auth.json not found at $AUTH_FILE"
  warn "  If you haven't used opencode yet, this is normal. Run /connect after install."
fi

# ── Backup existing config ─────────────────────────────────────────────────
step "Backup existing config"

EXISTING_CONFIG=""
for cf in "${CONFIG_DIR}/opencode.jsonc" "${CONFIG_DIR}/opencode.json"; do
  if [[ -f "$cf" ]]; then EXISTING_CONFIG="$cf"; break; fi
done

if [[ -n "$EXISTING_CONFIG" ]]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BACKUP_PATH="${CONFIG_DIR}/opencode.json.backup-${TS}"
  if ! $DRY_RUN; then
    mkdir -p "$CONFIG_DIR"
    cp "$EXISTING_CONFIG" "$BACKUP_PATH"
    MANIFEST_FILES+=("$BACKUP_PATH")
  fi
  ok "Backed up existing config to $BACKUP_PATH"
else
  info "No existing opencode config found — fresh install."
fi

# ── Create directory tree ──────────────────────────────────────────────────
step "Create directory tree"

for d in agents commands skills profiles scripts; do
  p="${CONFIG_DIR}/${d}"
  if ! $DRY_RUN; then mkdir -p "$p"; MANIFEST_DIRS+=("$p"); fi
  ok "dir: $p"
done

# ── Write opencode.json (rewrite MCP commands for *nix) ────────────────────
step "Write opencode.json"

TARGET_CONFIG="${CONFIG_DIR}/opencode.json"
if ! $DRY_RUN; then
  # Read the template, rewrite ["cmd","/c","npx",...] → ["npx",...] for *nix
  python3 -c "
import json, sys
with open('${SCRIPT_DIR}/opencode.json') as f:
    cfg = json.load(f)
# Strip _comment fields
cfg = {k: v for k, v in cfg.items() if not k.startswith('_comment')}
# Rewrite MCP commands for *nix
for name, srv in cfg.get('mcp', {}).items():
    cmd = srv.get('command', [])
    if len(cmd) >= 3 and cmd[0] == 'cmd' and cmd[1] == '/c' and cmd[2] in ('npx','uvx'):
        srv['command'] = cmd[2:]
# Tier adjustments
tier = '${TIER}'
if tier == 'lean':
    for mcp_name in ['code-review-graph', 'pakt']:
        cfg.get('mcp', {}).pop(mcp_name, None)
elif tier == 'full':
    cfg.setdefault('mcp', {})
    cfg['mcp']['arbor'] = {'type':'local','command':['arbor'],'enabled':True,'timeout':30000}
    cfg['mcp']['provenant'] = {'type':'local','command':['provenant','serve','.'],'enabled':True,'timeout':30000}
    cfg['mcp']['headroom'] = {'type':'local','command':['headroom','mcp'],'enabled':True,'timeout':30000}
# GitHub token
import subprocess
try:
    token = subprocess.check_output(['gh','auth','token'], stderr=subprocess.DEVNULL).decode().strip()
    if token:
        cfg['mcp']['github']['environment']['GITHUB_TOKEN'] = token
        print('GITHUB_TOKEN injected', file=sys.stderr)
except Exception:
    pass
with open('${TARGET_CONFIG}', 'w') as f:
    json.dump(cfg, f, indent=2)
" 2>&1 | while IFS= read -r line; do info "$line"; done
  MANIFEST_FILES+=("$TARGET_CONFIG")
fi
ok "config: $TARGET_CONFIG (tier=$TIER)"

# ── Copy agents ────────────────────────────────────────────────────────────
step "Copy agents"
if [[ -d "${SCRIPT_DIR}/agents" ]]; then
  for f in "${SCRIPT_DIR}"/agents/*.md; do
    [[ -f "$f" ]] || continue
    dest="${CONFIG_DIR}/agents/$(basename "$f")"
    if ! $DRY_RUN; then cp "$f" "$dest"; MANIFEST_FILES+=("$dest"); fi
    ok "agent: $(basename "$f")"
  done
fi

# ── Copy commands ──────────────────────────────────────────────────────────
step "Copy commands"
if [[ -d "${SCRIPT_DIR}/commands" ]]; then
  for f in "${SCRIPT_DIR}"/commands/*.md; do
    [[ -f "$f" ]] || continue
    dest="${CONFIG_DIR}/commands/$(basename "$f")"
    if ! $DRY_RUN; then cp "$f" "$dest"; MANIFEST_FILES+=("$dest"); fi
    ok "command: $(basename "$f")"
  done
fi

# ── Copy AGENTS.md ─────────────────────────────────────────────────────────
step "Copy AGENTS.md"
if [[ -f "${SCRIPT_DIR}/AGENTS.md" ]]; then
  dest="${CONFIG_DIR}/AGENTS.md"
  if ! $DRY_RUN; then cp "${SCRIPT_DIR}/AGENTS.md" "$dest"; MANIFEST_FILES+=("$dest"); fi
  ok "AGENTS.md: $dest"
fi

# ── Copy profiles ──────────────────────────────────────────────────────────
step "Copy profiles"
if [[ -d "${SCRIPT_DIR}/profiles" ]]; then
  for f in "${SCRIPT_DIR}"/profiles/*.json; do
    [[ -f "$f" ]] || continue
    dest="${CONFIG_DIR}/profiles/$(basename "$f")"
    if ! $DRY_RUN; then cp "$f" "$dest"; MANIFEST_FILES+=("$dest"); fi
    ok "profile: $(basename "$f")"
  done
fi

# ── Copy custom skills ─────────────────────────────────────────────────────
step "Copy custom skills"
SKILLS_DEST="${CONFIG_DIR}/skills"
if [[ -d "${SCRIPT_DIR}/skills" ]]; then
  for d in "${SCRIPT_DIR}"/skills/custom-*; do
    [[ -d "$d" ]] || continue
    name=$(basename "$d")
    dest="${SKILLS_DEST}/${name}"
    if ! $DRY_RUN; then
      rm -rf "$dest"
      cp -r "$d" "$dest"
      MANIFEST_DIRS+=("$dest")
    fi
    ok "skill: $name"
  done
fi

# ── Superpowers plugin ─────────────────────────────────────────────────────
step "Install superpowers plugin"
if ! $DRY_RUN; then
  info "superpowers is configured as a git+https plugin in opencode.json."
  info "It will be fetched automatically when opencode starts."
fi

# ── Third-party skill packs ────────────────────────────────────────────────
if ! $SKIP_SKILLS && [[ "$TIER" != "lean" ]]; then
  step "Install third-party skill packs (tier=$TIER)"

  if has git; then
    # CodeRabbit skills (standard+)
    if [[ "$TIER" == "standard" || "$TIER" == "full" ]]; then
      if has npx; then
        info "Installing CodeRabbit skills..."
        if run npx -y skills add coderabbitai/skills; then
          ok "CodeRabbit skills installed"
        else
          warn "CodeRabbit skills install failed — retry: npx skills add coderabbitai/skills"
        fi
      fi
    fi

    # Full tier: clone farmage, addyosmani
    if [[ "$TIER" == "full" ]]; then
      for pack in "farmage::https://github.com/farmage/opencode-skills.git" "addyosmani::https://github.com/addyosmani/agent-skills.git"; do
        name="${pack%%::*}"
        url="${pack##*::}"
        dest="${SKILLS_DEST}/${name}"
        if [[ ! -d "$dest" ]] || $FORCE; then
          info "Cloning $name..."
          if run git clone --depth 1 "$url" "$dest"; then ok "$name cloned"; else warn "$name clone failed"; fi
        else
          info "$name already installed"
        fi
      done

      # Cherry-picked skills
      if has npx; then
        for skill in \
          "anthropics/skills/frontend-design" \
          "mattpocock/skills/tdd" \
          "mattpocock/skills/diagnose" \
          "mattpocock/skills/triage" \
          "mattpocock/skills/improve-codebase-architecture" \
          "vercel-labs/next-skills/next-best-practices" \
          "vercel-labs/agent-skills/vercel-react-best-practices" \
          "supabase/agent-skills/supabase-postgres-best-practices" \
          "shadcn/ui/shadcn" \
          "anthropics/skills/skill-creator"; do
          info "npx skills add $skill"
          run npx -y skills add "$skill" && ok "skill: $skill" || warn "skill: $skill (failed, non-fatal)"
        done
      fi
    fi
  else
    warn "git not available — skipping third-party skill packs"
  fi
elif $SKIP_SKILLS; then
  step "Skip third-party skill packs (--skip-skills)"
else
  step "Skip third-party skill packs (lean tier)"
fi

# ── Prefetch MCP packages ──────────────────────────────────────────────────
if ! $SKIP_MCP; then
  step "Prefetch MCP packages (tier=$TIER)"

  NPM_MCPS=(
    "@playwright/mcp@latest"
    "@modelcontextprotocol/server-github"
    "@modelcontextprotocol/server-sequential-thinking"
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-memory"
    "repomix@latest"
    "@sriinnu/pakt"
  )
  [[ "$TIER" == "full" ]] && NPM_MCPS+=("headroom-ai")

  for pkg in "${NPM_MCPS[@]}"; do
    info "Prefetching $pkg..."
    run npx -y "$pkg" --help && ok "$pkg" || warn "$pkg prefetch failed (non-fatal)"
    MANIFEST_PKGS+=("$pkg")
  done

  if has uvx; then
    for pkg in mcp-server-fetch mcp-server-time mcp-server-git; do
      info "Prefetching $pkg..."
      run uvx "$pkg" --help && ok "$pkg" || warn "$pkg prefetch failed (non-fatal)"
      MANIFEST_PKGS+=("$pkg")
    done
  else
    warn "uvx not available — skipping Python MCP prefetch"
  fi

  # code-review-graph (pip package, NOT npm)
  if [[ "$TIER" == "standard" || "$TIER" == "full" ]]; then
    info "Installing code-review-graph via pip..."
    if has pip; then
      run pip install code-review-graph && ok "code-review-graph installed via pip" || warn "code-review-graph pip install failed"
      MANIFEST_PKGS+=("code-review-graph")
    elif has uvx; then
      run uvx --from code-review-graph code-review-graph --help && ok "code-review-graph available via uvx" || warn "code-review-graph install failed"
      MANIFEST_PKGS+=("code-review-graph")
    else
      warn "Neither pip nor uvx available — code-review-graph requires Python"
    fi
  fi
else
  step "Skip MCP prefetch (--skip-mcp)"
fi

# ── External CLIs ──────────────────────────────────────────────────────────
if [[ "$TIER" == "standard" || "$TIER" == "full" ]]; then
  step "Install external CLIs (tier=$TIER)"

  if has uvx; then
    info "Installing ast-outline..."
    run uvx ast-outline --help && ok "ast-outline available via uvx" || warn "ast-outline install failed"
    MANIFEST_PKGS+=("ast-outline")
  else
    warn "uvx not available — ast-outline requires uv/uvx"
  fi

  if has npm; then
    info "Installing ast-grep..."
    run npm install -g @ast-grep/cli && ok "ast-grep installed" || warn "ast-grep install failed"
    MANIFEST_PKGS+=("@ast-grep/cli")
  fi

  if has git; then
    info "Installing gtr (git-worktree-runner)..."
    if run bash -c 'curl -fsSL https://raw.githubusercontent.com/coderabbitai/git-worktree-runner/main/install.sh | sh'; then
      ok "gtr installed"
      run git gtr config set gtr.ai.default opencode 2>/dev/null || warn "gtr config set failed (non-fatal)"
      MANIFEST_PKGS+=("gtr")
    else
      warn "gtr install failed — install manually from https://github.com/coderabbitai/git-worktree-runner"
    fi
  fi
fi

if [[ "$TIER" == "full" ]]; then
  if has npm; then
    info "Installing jscodeshift..."
    run npm install -g jscodeshift && ok "jscodeshift installed" || warn "jscodeshift install failed"
    MANIFEST_PKGS+=("jscodeshift")
  fi
  if has pip; then
    info "Installing libcst..."
    run pip install libcst && ok "libcst installed" || warn "libcst install failed"
    MANIFEST_PKGS+=("libcst")
    info "Installing aider..."
    run pip install aider-chat && ok "aider installed" || warn "aider install failed"
    MANIFEST_PKGS+=("aider-chat")
  fi
fi

# ── GitHub Spec Kit ────────────────────────────────────────────────────────
if [[ "$TIER" == "standard" || "$TIER" == "full" ]]; then
  step "Install GitHub Spec Kit"
  if has uvx; then
    info "Installing specify-cli..."
    run uvx specify-cli --help && ok "specify-cli available via uvx" || warn "specify-cli install failed"
    MANIFEST_PKGS+=("specify-cli")
    info "Per-project: cd your-project; specify init . --integration opencode"
  else
    warn "uvx not available — install with: uv tool install specify-cli"
  fi
fi

# ── skillgate ──────────────────────────────────────────────────────────────
if [[ "$TIER" == "standard" || "$TIER" == "full" ]]; then
  step "Install skillgate (DoD gate)"
  info "skillgate is a TypeScript pre-commit/CI gate."
  info "Install per-project: see https://github.com/renezander030/skillgate"
  MANIFEST_PKGS+=("skillgate (per-project)")
fi

# ── Write manifest ─────────────────────────────────────────────────────────
step "Write manifest"
if ! $DRY_RUN; then
  python3 -c "
import json
manifest = {
    'version': '1.0.0',
    'tier': '${TIER}',
    'files': $(printf '%s\n' "${MANIFEST_FILES[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"),
    'dirs': $(printf '%s\n' "${MANIFEST_DIRS[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"),
    'packages': $(printf '%s\n' "${MANIFEST_PKGS[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))"),
}
with open('${MANIFEST_PATH}', 'w') as f:
    json.dump(manifest, f, indent=2)
" 2>/dev/null || {
    # Fallback if python3 array parsing fails
    echo "{\"version\":\"1.0.0\",\"tier\":\"${TIER}\"}" > "$MANIFEST_PATH"
  }
  ok "Manifest: $MANIFEST_PATH"
fi

# ── Summary ────────────────────────────────────────────────────────────────
step "Summary"
echo ""
MCP_COUNT=13; [[ "$TIER" == "lean" ]] && MCP_COUNT=10; [[ "$TIER" == "full" ]] && MCP_COUNT=18
printf "  Tier:           %s\n" "$TIER"
printf "  Config:         %s\n" "$TARGET_CONFIG"
printf "  Agents:         8\n"
printf "  Commands:       7\n"
printf "  Custom skills:  22\n"
printf "  MCP servers:    %d\n" "$MCP_COUNT"
printf "  Manifest:       %s\n" "$MANIFEST_PATH"
echo ""
printf "  \033[33mIMPORTANT: Restart opencode for changes to take effect.\033[0m\n"
printf "  \033[33mConfig is loaded once at startup and is not hot-reloaded.\033[0m\n"
echo ""
printf "  To revert: ./uninstall.sh --full\n"
printf "  To toggle models: ./toggle-models.sh status\n"
echo ""
# Pause when launched by double-click so the user can read the output.
# Skip the pause if stdin is not a terminal (e.g. piped or CI).
if [ -t 0 ]; then
  printf "  Press any key to close this window..."
  read -n 1 -s -r _
  echo ""
fi
