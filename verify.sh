#!/usr/bin/env bash
# Post-install smoke test for OpenCode-Go Power Pack.
# Verifies that the installer wrote all expected files and key tools are available.

set -uo pipefail

CONFIG_DIR="${HOME}/.config/opencode"
PASS=0
FAIL=0

# Find working Python (Windows has non-functional Microsoft Store stubs for python3)
PYTHON=""
for py in python py python3; do
  if "$py" --version >/dev/null 2>&1; then PYTHON="$py"; break; fi
done

check() {
  if eval "$2"; then
    printf "  \033[32m[PASS]\033[0m %s\n" "$1"; ((PASS++))
  else
    printf "  \033[31m[FAIL]\033[0m %s\n" "$1"; ((FAIL++))
  fi
}

has() { command -v "$1" &>/dev/null; }

info() { printf "  \033[90m%s\033[0m\n" "$1"; }

echo ""
echo "=== OpenCode-Go Power Pack — Post-install Verification ==="

# Config files
echo -e "\n--- Config files ---"
check "opencode.json exists" "[[ -f '${CONFIG_DIR}/opencode.json' ]]"
check "AGENTS.md exists" "[[ -f '${CONFIG_DIR}/AGENTS.md' ]]"
check "manifest exists" "[[ -f '${CONFIG_DIR}/.power-pack-manifest.json' ]]"
check "profiles/multi-models.json exists" "[[ -f '${CONFIG_DIR}/profiles/multi-models.json' ]]"

# Config content
echo -e "\n--- Config content ---"
if [[ -f "${CONFIG_DIR}/opencode.json" ]]; then
  if [[ -n "$PYTHON" ]]; then
    check "model is opencode-go/*" "\"$PYTHON\" -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('model','').startswith('opencode-go/')\""
    check "small_model is opencode-go/*" "\"$PYTHON\" -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('small_model','').startswith('opencode-go/')\""
    check "enabled_providers locked to opencode-go" "\"$PYTHON\" -c \"import json; assert 'opencode-go' in json.load(open('${CONFIG_DIR}/opencode.json')).get('enabled_providers',[])\""
    check "compaction.prune is true" "\"$PYTHON\" -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('compaction',{}).get('prune')==True\""
    check "permission.bash allows *" "\"$PYTHON\" -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('permission',{}).get('bash',{}).get('*')=='allow'\""
    check "permission.bash denies rm -rf /" "\"$PYTHON\" -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('permission',{}).get('bash',{}).get('rm -rf / *')=='deny'\""
    MCP_COUNT=$("$PYTHON" -c "import json; print(len(json.load(open('${CONFIG_DIR}/opencode.json')).get('mcp',{})))" 2>/dev/null)
    check "MCP servers configured (${MCP_COUNT:-0})" "[[ ${MCP_COUNT:-0} -ge 10 ]]"
    AGENT_COUNT=$("$PYTHON" -c "import json; print(len(json.load(open('${CONFIG_DIR}/opencode.json')).get('agent',{})))" 2>/dev/null)
    check "Agents configured (${AGENT_COUNT:-0})" "[[ ${AGENT_COUNT:-0} -ge 8 ]]"
  else
    info "Python not available — skipping config-content checks"
  fi
fi

# Agents
echo -e "\n--- Agents ---"
for a in build.md plan.md reviewer.md explorer.md data-engineer.md frontend-engineer.md devops-engineer.md doc-writer.md; do
  check "agent $a" "[[ -f '${CONFIG_DIR}/agents/${a}' ]]"
done

# Commands
echo -e "\n--- Commands ---"
for c in review.md plan.md test.md ship.md debug.md refactor.md docs.md; do
  check "command $c" "[[ -f '${CONFIG_DIR}/commands/${c}' ]]"
done

# Skills
echo -e "\n--- Custom skills ---"
SKILL_COUNT=$(find "${CONFIG_DIR}/skills" -maxdepth 1 -type d -name 'custom-*' 2>/dev/null | wc -l)
check "22 custom skills installed" "[[ $SKILL_COUNT -eq 22 ]]"

# Tools
echo -e "\n--- Tools ---"
check "git available" "has git"
check "node available" "has node"
check "npx available" "has npx"
if has gh; then
  check "gh authenticated" "gh auth token &>/dev/null"
else
  echo "  [SKIP] gh CLI not found"
fi

# Summary
echo -e "\n=== Summary ==="
printf "  Passed: %d\n" "$PASS"
if [[ $FAIL -gt 0 ]]; then
  printf "  \033[31mFailed: %d\033[0m\n" "$FAIL"
  echo ""
  echo "  Some checks failed. Review the output above."
  CODE=1
else
  printf "  \033[32mFailed: 0\033[0m\n"
  echo ""
  echo "  All checks passed. Restart opencode for changes to take effect."
  CODE=0
fi
# Pause when launched by double-click; skip in non-interactive contexts.
if [ -t 0 ]; then
  printf "  Press any key to close this window..."
  read -n 1 -s -r _
  echo ""
fi
exit $CODE
