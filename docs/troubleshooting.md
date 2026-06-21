# Troubleshooting

## Common issues

### opencode won't start after install

**Cause:** Invalid config (wrong field shape, unknown key).

**Fix:**
1. Check the error message — opencode tells you which field is invalid.
2. Compare your `~/.config/opencode/opencode.json` against the template in this repo.
3. Validate against the schema: `https://opencode.ai/config.json`.
4. If stuck, use the escape hatch: `OPENCODE_DISABLE_PROJECT_CONFIG=1 opencode` (skips project config, loads globals only).

### MCP server not connecting

**Cause:** Package not prefetched, or wrong command format for the platform.

**Fix:**
1. On Windows, MCP commands should be `["cmd","/c","npx",...]`. The installer handles this, but if you edited the config manually, check the format.
2. On macOS/Linux, commands should be `["npx",...]`.
3. Try running the command manually: `npx -y @playwright/mcp@latest` — if it fails, the package may not be available.
4. Check `experimental.mcp_timeout` — if the server is slow to start, increase the timeout.

### GitHub MCP token not working

**Cause:** `gh auth token` returned empty, or the token was not injected.

**Fix:**
1. Check: `gh auth status` — confirm you're authenticated.
2. If not: `gh auth login` and follow the prompts.
3. Re-run the installer: `.\install.ps1 -Force` (Windows) or `./install.sh --force` (macOS/Linux).
4. Or manually edit `~/.config/opencode/opencode.json` and set `mcp.github.environment.GITHUB_TOKEN` to your token.
5. Alternatively, use `{env:GITHUB_TOKEN}` and set the `GITHUB_TOKEN` environment variable.

### Superpowers plugin not loading

**Cause:** `git` not on PATH, or network issue fetching from GitHub.

**Fix:**
1. Check: `git --version` — confirm git is available.
2. Try: `npm install superpowers@git+https://github.com/obra/superpowers.git --prefix ~/.config/opencode` (Windows long-path workaround).
3. Use the local path in config: `"plugin": ["~/.config/opencode/node_modules/superpowers"]`.

### gtr (git-worktree-runner) not working on Windows

**Cause:** gtr's install script is bash-based; native Windows may not support it.

**Fix:**
1. Install WSL: `wsl --install`.
2. Run gtr's install script inside WSL: `curl -fsSL https://raw.githubusercontent.com/coderabbitai/git-worktree-runner/main/install.sh | sh`.
3. Or use manual git worktrees: `git worktree add ../feature-branch feature-branch`.

### RTK plugin not compressing on Windows

**Cause:** RTK's auto-rewrite hook doesn't run on native Windows (falls back to CLAUDE.md-style injection). Full hook support requires WSL.

**Fix:**
1. Use WSL for full RTK hook support.
2. Or use the `rtk` CLI manually: `rtk read <file> -l aggressive` (signatures only).
3. Or `rtk git status` / `rtk git diff` for compact git output.

### opencode-go models not showing in /models

**Cause:** opencode-go subscription not authenticated.

**Fix:**
1. Run `/connect` in the opencode TUI.
2. Select "OpenCode Go".
3. Go to https://opencode.ai/auth, sign in, add billing details, copy your API key.
4. Paste the API key in the TUI.
5. Run `/models` to see available models.

### Too many MCP servers slowing startup

**Cause:** Each MCP server starts a process at opencode startup. 18 servers (full tier) can slow things down.

**Fix:**
1. Switch to standard or lean tier: `.\install.ps1 -Tier standard -Force`.
2. Or disable specific servers in `opencode.json`: set `"enabled": false` on servers you don't need.
3. Or remove servers you don't use from the `mcp` section.

### Skills not triggering

**Cause:** Skill `description` frontmatter doesn't match the task keywords, or skills directory not in the right place.

**Fix:**
1. Check: `ls ~/.config/opencode/skills/` — confirm skill folders are there.
2. Each skill folder must contain a `SKILL.md` file with `name` and `description` frontmatter.
3. The `description` should front-load trigger keywords. If a skill isn't triggering, improve its description.
4. Check that the folder name matches the `name` field in frontmatter.

### Uninstall didn't remove everything

**Cause:** Files were modified after install, or the manifest is incomplete.

**Fix:**
1. Run `.\uninstall.ps1 -Full -DryRun` (Windows) or `./uninstall.sh --full --dry-run` (macOS/Linux) to preview what would be removed.
2. If files remain, manually delete `~/.config/opencode/agents/`, `~/.config/opencode/commands/`, `~/.config/opencode/skills/custom-*/`.
3. To completely reset: delete `~/.config/opencode/` entirely (opencode will recreate it on next start).

## Escape hatches

| Env var | Effect |
|---|---|
| `OPENCODE_DISABLE_PROJECT_CONFIG=1` | Skip project's local `opencode.json`, load globals only |
| `OPENCODE_CONFIG=/path/to/file.json` | Load an additional explicit config |
| `OPENCODE_CONFIG_CONTENT='{"$schema":"..."}'` | Inject inline JSON as a final local-scope merge |
| `OPENCODE_DISABLE_DEFAULT_PLUGINS=1` | Skip default plugins |
| `OPENCODE_PURE=1` | Skip external plugins entirely |
| `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` | Skip external skill scans under `~/.claude/` and `~/.agents/` |

## Getting help

- [File a bug report](https://github.com/<your-org>/opencode-go-power-pack/issues/new?template=bug-report.yml)
- [Request a feature](https://github.com/<your-org>/opencode-go-power-pack/issues/new?template=feature-request.yml)
- [opencode docs](https://opencode.ai/docs/)
- [opencode Discord](https://opencode.ai/discord)
