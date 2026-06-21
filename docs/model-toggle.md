# Model Toggle

The pack defaults to **multi-model mode** — per-agent model orchestration where each agent uses the opencode-go model best suited to its task. You can switch to **single-model mode** where all agents inherit one model.

## Why two modes?

- **Multi-model** (default): best capability/cost balance. `glm-5.2` for build, `deepseek-v4-pro` for planning, `qwen3.7-max` for review, `deepseek-v4-flash` for cheap exploration. Maximizes quality while controlling cost.
- **Single-model**: simpler to reason about. Everything runs on one model. Useful for benchmarking, debugging, or when you want simplicity.

## Commands

### Windows (PowerShell)
```powershell
.\toggle-models.ps1 status                              # show current mode + agent models
.\toggle-models.ps1 multi                               # restore per-agent model assignments
.\toggle-models.ps1 single                              # all agents use top-level model
.\toggle-models.ps1 single opencode-go/kimi-k2.7-code   # single + pick specific model
```

### macOS / Linux
```bash
./toggle-models.sh status
./toggle-models.sh multi
./toggle-models.sh single
./toggle-models.sh single opencode-go/kimi-k2.7-code
```

## How it works

### Multi mode
The script reads `profiles/multi-models.json` and writes per-agent `model` fields into `opencode.json`:
```json
{
  "model": "opencode-go/glm-5.2",
  "small_model": "opencode-go/deepseek-v4-flash",
  "agent": {
    "build":             { "model": "opencode-go/glm-5.2" },
    "plan":              { "model": "opencode-go/deepseek-v4-pro" },
    "reviewer":          { "model": "opencode-go/qwen3.7-max" },
    ...
  }
}
```

### Single mode
The script removes all per-agent `model` fields from `opencode.json`. Every agent inherits the top-level `model`:
```json
{
  "model": "opencode-go/glm-5.2",
  "small_model": "opencode-go/glm-5.2",
  "agent": {
    "build":             {},
    "plan":              {},
    "reviewer":          {},
    ...
  }
}
```

## Customizing multi-mode assignments

Edit `~/.config/opencode/profiles/multi-models.json` to change which model each agent uses in multi mode. The toggle script reads this file on every `multi` invocation.

```json
{
  "model": "opencode-go/glm-5.2",
  "small_model": "opencode-go/deepseek-v4-flash",
  "agents": {
    "build": "opencode-go/glm-5.2",
    "plan": "opencode-go/deepseek-v4-pro",
    "reviewer": "opencode-go/qwen3.7-max",
    "explorer": "opencode-go/deepseek-v4-flash",
    "data-engineer": "opencode-go/kimi-k2.7-code",
    "frontend-engineer": "opencode-go/glm-5.2",
    "devops-engineer": "opencode-go/deepseek-v4-pro",
    "doc-writer": "opencode-go/mimo-v2.5",
    "title": "opencode-go/deepseek-v4-flash",
    "summary": "opencode-go/deepseek-v4-flash",
    "compaction": "opencode-go/deepseek-v4-flash"
  }
}
```

## Ad-hoc switching (without the script)

opencode's TUI `/model` command switches the **active session's** model on the fly — useful for one-off switches without editing config. The toggle script is for **persistent** config-level switching across all agents and future sessions.

## After toggling

**Restart opencode** for config changes to take effect. Config is loaded once at startup and is not hot-reloaded.
