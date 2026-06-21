# Contributing to OpenCode-Go Power Pack

Thank you for your interest in improving the pack. This repo is a portable installer + a curated set of agents, commands, skills, MCP server configs, and documentation that supercharges opencode-go. Contributions that add capabilities, fix bugs, or improve docs are all welcome.

## Quick navigation

- **Installer logic** — `install.ps1`, `install.sh`, `uninstall.ps1`, `uninstall.sh`, `verify.ps1`, `verify.sh`, `toggle-models.ps1`, `toggle-models.sh`
- **Agents** — `agents/*.md` (one file per agent, frontmatter + prompt body)
- **Commands** — `commands/*.md` (one file per slash command)
- **Skills** — `skills/custom-*/SKILL.md` (one folder per skill, `SKILL.md` inside)
- **Generated config** — `opencode.json` (the template the installer writes; Windows form by default)
- **Global instructions** — `AGENTS.md` (loaded into every session)
- **Docs** — `docs/*.md` (reference docs linked from README)

## Ways to contribute

### Add a new custom skill

1. Pick a short, lowercase-hyphenated name (max 64 chars). Prefix with `custom-` to distinguish from third-party packs (e.g. `custom-prompts-caching`).
2. Create `skills/<your-skill-name>/SKILL.md`.
3. Frontmatter requires `name` (must match the folder name) and `description` (one sentence covering what the skill does AND when to trigger it; front-load trigger keywords).
4. Body is markdown: instructions, examples, references. Keep it under ~200 lines — skills are loaded into context, so size matters.
5. Test: run `install.ps1 install` (or just copy the folder to `~/.config/opencode/skills/`) and restart opencode. Confirm the skill surfaces when you describe a matching task.
6. Update `docs/skills.md` with a one-line entry.
7. Open a PR.

### Add a new agent

1. Create `agents/<your-agent>.md` with frontmatter: `description`, `mode` (`primary` or `subagent`), `model` (`opencode-go/<id>`), optional `steps`, `color`, `permission`, `hidden`.
2. Body is the agent's prompt. Keep it focused — the agent should have a clear, narrow charter.
3. Add the agent to `profiles/multi-models.json` so the model-toggle script knows about it.
4. Update `docs/agents.md`.
5. Open a PR.

### Add a new MCP server

1. Add the server to `opencode.json` under `mcp.<name>`. Use `["cmd","/c","npx",...]` form for Windows (the installer rewrites to `["npx",...]` on *nix).
2. Add a one-line entry to `docs/mcp-servers.md`.
3. If the server needs a token/env var, document it in `docs/troubleshooting.md`.
4. Update `install.ps1` and `install.sh` to prefetch the package (so first run is fast).
5. Update the tier matrix in `README.md` and `docs/tiers.md` if the server is tier-gated.
6. Open a PR.

### Add a new external CLI

1. Add the install command to `install.ps1` and `install.sh` (detect platform; print a warning, not an error, if unavailable).
2. Add a section to `AGENTS.md` if the agent needs instructions on when/how to use it.
3. Update `docs/tiers.md` and the README's "What's included" matrix.
4. Open a PR.

### Improve the installer

1. Edit `install.ps1` and/or `install.sh`. Keep them in sync — same flags, same tier matrix, same manifest format.
2. The manifest at `~/.config/opencode/.power-pack-manifest.json` must list every file/dir the installer creates so `uninstall.ps1/sh` can safely revert.
3. Run `verify.ps1` / `verify.sh` after install to confirm the smoke tests pass.
4. Test the uninstaller: run `uninstall.ps1 -Full`, confirm opencode returns to stock config, then re-install.
5. Open a PR with both the change and any needed `CHANGELOG.md` entry.

## Coding conventions

- **PowerShell 5.1 compatible** — no `&&` chaining; use `cmd1; if ($?) { cmd2 }`. Use `Get-ChildItem`/`Set-Content`/`New-Item`/`Remove-Item`, not aliases.
- **POSIX bash compatible** — `install.sh` runs on macOS and Linux. Use `set -e` and `&&`.
- **No comments in code unless asked** — code should be self-documenting.
- **Conventional commits** — `feat(scope): description`, `fix(scope): description`, `docs(scope): description`, `chore(scope): description`.
- **Never commit secrets** — GitHub tokens, API keys, `.env` files. The `opencode.json` template uses `{env:GITHUB_TOKEN}` interpolation, not literal tokens.
- **Test on a clean opencode config** — before claiming your change works, run `uninstall.ps1 -Full`, then `install.ps1 install`, then `verify.ps1`.

## Pull request checklist

- [ ] `CHANGELOG.md` updated under `[Unreleased]` (or a new version section).
- [ ] `docs/` updated if the user-facing surface changed.
- [ ] `install.ps1` and `install.sh` kept in sync.
- [ ] `verify.ps1` / `verify.sh` pass after install.
- [ ] `uninstall.ps1 -Full` cleanly reverts to stock opencode.
- [ ] No secrets in the diff.
- [ ] Conventional commit message.
- [ ] If you added a skill/agent/MCP, the corresponding `docs/` reference is updated.

## Reporting bugs

Use the **Bug report** issue template. Include:
- OS (Windows / macOS / Linux distribution)
- opencode version (`opencode --version`)
- opencode-go subscription status (authenticated? which models visible in `/models`?)
- Tier installed (`lean` / `standard` / `full`)
- The exact command you ran
- The full output (or a paste link)
- The contents of `~/.config/opencode/.power-pack-manifest.json`

## Requesting features

Use the **Feature request** issue template. Tell us:
- The capability gap (what you cannot do today)
- The proposed addition (skill / agent / MCP / CLI / config)
- Whether it should be in `lean`, `standard`, `full`, or a new tier
- Any research / benchmarks / repos that back the proposal

## License

By contributing, you agree your contributions are licensed under the MIT license (see `LICENSE`). Third-party packs bundled by the installer retain their original licenses.
