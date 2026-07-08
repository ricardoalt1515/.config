# Dotfiles

Personal macOS configuration. The goal is intentionally simple: clone this repo on a new Mac and restore the configs already used on the current machine.

## New Mac restore

```bash
# If macOS does not have git yet, install Apple's command line tools first:
# xcode-select --install

git clone git@github.com:ricardoalt1515/.config.git ~/.config
cd ~/.config
chmod +x restore.sh
./restore.sh
```

## What this restores

`restore.sh` installs the curated tools in `Brewfile` and restores the tracked configs.

Tools include:

- Fish
- Ghostty
- Neovim
- Starship
- Tmux/Herdr
- Git/GitHub CLI/Git Delta
- Lazygit
- AeroSpace
- Raycast
- WezTerm
- AI/dev harness tools: Codex, CodexBar, Engram, Gentle AI, Worktrunk, and Pi plugins

Configs include:

- Fish config
- Ghostty config
- Neovim config
- Starship config
- Tmux/Herdr config
- Git preferences
- Lazygit config
- AeroSpace config
- OpenCode/Gentle AI config
- Claude Code agents, commands, status line, MCP definitions, theme, and safe settings
- Pi agents, chains, extensions, settings, themes, MCP definitions, and shared skills
- Shared `~/.agents/skills` used by Pi and other agent harnesses
- Conservative macOS developer preferences from `macos/defaults.sh`
- Other tracked files under `~/.config`

## What stays manual

These should not be committed or blindly restored:

- SSH keys
- GitHub authentication
- 1Password/session state
- Raycast account login
- Atuin login/sync
- Claude Code login/history/cache/telemetry
- Pi auth/session/trust/cache/MCP OAuth state
- Copilot or other OAuth tokens

After restoring, run the relevant manual steps:

```bash
gh auth login
```

Then sign in to Raycast, Atuin, Claude Code, Pi providers, Copilot, and any app that stores credentials locally.

## Packages

`Brewfile` is intentionally curated. It is not a full dump of every package installed on the current Mac.

If you want to refresh it from the current machine, generate a temporary dump and copy only the tools you really want on a fresh Mac:

```bash
brew bundle dump --file /tmp/current.Brewfile --force
```

Avoid committing the full dump blindly. Project-specific tools and local experiments should stay out of the base restore flow.

## Notes

- This repo is the source of truth for portable config.
- `Brewfile` is the source of truth for base apps and CLI tools.
- Runtime state, generated completions, app caches, and auth files are intentionally ignored.
- Existing files are backed up to `~/.config-backup-YYYYMMDD-HHMMSS/` before being replaced by symlinks.
