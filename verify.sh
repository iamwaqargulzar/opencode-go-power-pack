#!/usr/bin/env bash
# Post-install smoke test for OpenCode-Go Power Pack.
# Verifies that the installer wrote all expected files and key tools are available.

set -euo pipefail

CONFIG_DIR="${HOME}/.config/opencode"
PASS=0
FAIL=0

check() {
  if eval "$2"; then
    printf "  \033[32m[PASS]\033[0m %s\n" "$1"; ((PASS++))
  else
    printf "  \033[31m[FAIL]\033[0m %s\n" "$1"; ((FAIL++))
  fi
}

has() { command -v "$1" &>/dev/null; }

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
  check "model is opencode-go/*" "python3 -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('model','').startswith('opencode-go/')\""
  check "small_model is opencode-go/*" "python3 -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('small_model','').startswith('opencode-go/')\""
  check "enabled_providers locked to opencode-go" "python3 -c \"import json; assert 'opencode-go' in json.load(open('${CONFIG_DIR}/opencode.json')).get('enabled_providers',[])\""
  check "compaction.prune is true" "python3 -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('compaction',{}).get('prune')==True\""
  check "permission.bash allows *" "python3 -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('permission',{}).get('bash',{}).get('*')=='allow'\""
  check "permission.bash denies rm -rf /" "python3 -c \"import json; assert json.load(open('${CONFIG_DIR}/opencode.json')).get('permission',{}).get('bash',{}).get('rm -rf / *')=='deny'\""
  MCP_COUNT=$(python3 -c "import json; print(len(json.load(open('${CONFIG_DIR}/opencode.json')).get('mcp',{})))")
  check "MCP servers configured ($MCP_COUNT)" "[[ $MCP_COUNT -ge 10 ]]"
  AGENT_COUNT=$(python3 -c "import json; print(len(json.load(open('${CONFIG_DIR}/opencode.json')).get('agent',{})))")
  check "Agents configured ($AGENT_COUNT)" "[[ $AGENT_COUNT -ge 8 ]]"
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
