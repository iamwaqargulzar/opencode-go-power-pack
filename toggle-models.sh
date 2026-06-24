#!/usr/bin/env bash
# Toggle between multi-model and single-model mode.
#
# Usage:
#   ./toggle-models.sh multi                  # restore per-agent model assignments
#   ./toggle-models.sh single                 # all agents inherit top-level model
#   ./toggle-models.sh single opencode-go/kimi-k2.7-code  # single + pick model
#   ./toggle-models.sh status                 # show current mode + agent models

set -uo pipefail

ACTION="${1:-status}"
MODEL_ID="${2:-}"

CONFIG_DIR="${HOME}/.config/opencode"
CONFIG_FILE="${CONFIG_DIR}/opencode.json"
MULTI_PROFILE="${CONFIG_DIR}/profiles/multi-models.json"

# Find working Python (Windows has non-functional Microsoft Store stubs for python3)
PYTHON=""
for py in python py python3; do
  if "$py" --version >/dev/null 2>&1; then PYTHON="$py"; break; fi
done

case "$ACTION" in multi|single|status) ;; *)
  echo "Usage: $0 {multi|single [model-id]|status}"
  exit 1 ;; esac

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found: $CONFIG_FILE"
  echo "Run install.sh first."
  exit 1
fi

show_status() {
  echo ""
  echo "=== Model Toggle Status ==="
  local top_model small_model
  top_model=$("$PYTHON" -c "import json; print(json.load(open('$CONFIG_FILE')).get('model','?'))")
  small_model=$("$PYTHON" -c "import json; print(json.load(open('$CONFIG_FILE')).get('small_model','?'))")
  echo "  Top-level model: $top_model"
  echo "  Small model:     $small_model"
  echo ""
  echo "  Agent models:"
  "$PYTHON" -c "
import json
cfg = json.load(open('$CONFIG_FILE'))
agents = cfg.get('agent', {})
multi = False
for name, a in agents.items():
    m = a.get('model', '')
    hidden = a.get('hidden', False) or name in ('title','summary','compaction')
    if m:
        multi = True
        tag = '  (hidden)' if hidden else ''
        print(f'    {name}: {m}{tag}')
    else:
        print(f'    {name}: (inherits top-level: {cfg.get(\"model\",\"?\")})')
print()
if multi:
    print('  Mode: MULTI (per-agent models assigned)')
else:
    print('  Mode: SINGLE (all agents inherit top-level model)')
"
  echo ""
}

set_multi() {
  if [[ ! -f "$MULTI_PROFILE" ]]; then
    echo "Multi-model profile not found: $MULTI_PROFILE"
    echo "Run install.sh first to copy profiles."
    exit 1
  fi
  "$PYTHON" -c "
import json
with open('$CONFIG_FILE') as f: cfg = json.load(f)
with open('$MULTI_PROFILE') as f: prof = json.load(f)
cfg['model'] = prof['model']
cfg['small_model'] = prof['small_model']
for agent_name, model_id in prof['agents'].items():
    if agent_name in cfg.get('agent', {}):
        cfg['agent'][agent_name]['model'] = model_id
    else:
        cfg['agent'][agent_name] = {'model': model_id}
with open('$CONFIG_FILE', 'w') as f: json.dump(cfg, f, indent=2)
print('Switched to MULTI mode.')
print(f\"  model: {cfg['model']}\")
print('  Per-agent models restored from profiles/multi-models.json')
"
  echo ""
  echo "  Restart opencode for changes to take effect."
}

set_single() {
  local target="${MODEL_ID}"
  "$PYTHON" -c "
import json
with open('$CONFIG_FILE') as f: cfg = json.load(f)
target = '${target}' or cfg.get('model', 'opencode-go/glm-5.2')
cfg['model'] = target
cfg['small_model'] = target
for name, a in cfg.get('agent', {}).items():
    a.pop('model', None)
with open('$CONFIG_FILE', 'w') as f: json.dump(cfg, f, indent=2)
print('Switched to SINGLE mode.')
print(f'  model: {target}')
print('  All agents now inherit the top-level model.')
"
  echo ""
  echo "  Restart opencode for changes to take effect."
}

case "$ACTION" in
  status) show_status ;;
  multi)  set_multi ;;
  single) set_single ;;
esac
