# Dotfiles

Portable macOS development configuration. The repository is intended to live at `~/.dotfiles`; authored config is projected to explicit destinations under `~/.config` and `$HOME`.

The current checkout may remain at `~/.config` during development. `restore.sh` detects source-equals-destination paths and leaves them in place.

## New Mac

Install Apple's command line tools and Homebrew first, then clone and inspect the restore:

```bash
xcode-select --install
git clone https://github.com/ricardoalt1515/.config.git ~/.dotfiles
cd ~/.dotfiles
./restore.sh --dry-run
./restore.sh
```

The default run projects the core config and installs `Brewfile`. Homebrew is required but is never installed automatically.

## Profiles

Profiles are explicit and repeatable:

```bash
# Core config and packages only (the default)
./restore.sh --profile core

# Core plus optional desktop and terminal tools
./restore.sh --profile core --profile optional

# Agent packages without linking mutable agent config directories
./restore.sh --profile agents

# Project config only; no package or defaults commands
./restore.sh --profile core --profile optional --links-only
```

- Core: Fish, Ghostty, Starship, Zoxide, Neovim/LazyVim, Git, GH, Delta, Bat, and Lazygit.
- Optional: Herdr, tmux, AeroSpace, Hunk, Atuin, Carapace, and Raycast.
- Agents: package manifests for the tracked agent harnesses. Pi plugins remain owned by Pi's package manager and are not globally duplicated.

Herdr is the primary multiplexer. Ghostty launches a PATH-resolved Herdr when available and falls back to the login shell otherwise. tmux is installed and configured by the optional profile, but neither Ghostty nor Fish starts it automatically.

## Restore Safety

`restore.sh` links only the authored resources named in the script. Mutable neighbors such as Fish variables/completions, Neovim lock state, and Bat cache remain local; the script never replaces all of `~/.config`.

- Existing non-symlink targets are moved to `~/.dotfiles-backups/YYYYMMDD-HHMMSS/` before linking.
- Re-running the same projection keeps correct links unchanged.
- `--dry-run` prints link, backup, package, and defaults actions without applying them.
- `--macos-defaults` is required to run `macos/defaults.sh`.

OpenCode, Claude, and Pi config directories are intentionally not linked. They contain mutable or generated assets managed by their own tools. Logins, sessions, caches, telemetry, package state, and trust decisions stay local.

Skills are intentionally out of scope: this repository does not track, copy, link, or index them.

## Git And Authentication

`git/config` contains portable behavior only. Set identity locally after restore:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
gh auth login
```

SSH keys, GitHub authentication, Git credential helpers, Raycast login, Atuin sync, and all agent-provider authentication remain manual and must not be committed.

## Package Manifests

- `Brewfile`: core packages.
- `Brewfile.optional`: optional desktop and terminal packages.
- `Brewfile.agents`: agent CLIs and applications, excluding Pi plugins.

Check manifests without installing anything:

```bash
brew bundle check --file Brewfile --verbose
brew bundle check --file Brewfile.optional --verbose
brew bundle check --file Brewfile.agents --verbose
```

Missing packages are expected on a machine that has not yet restored a profile.
