#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

info() {
	printf '\033[0;32m==>\033[0m %s\n' "$1"
}

warn() {
	printf '\033[0;33m==>\033[0m %s\n' "$1"
}

ensure_homebrew() {
	if command -v brew >/dev/null 2>&1; then
		return 0
	fi

	if [[ ! -f "$DOTFILES_DIR/Brewfile" ]]; then
		return 0
	fi

	info "Installing Homebrew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

load_homebrew() {
	local brew_bin=""

	if [[ -x /opt/homebrew/bin/brew ]]; then
		brew_bin="/opt/homebrew/bin/brew"
	elif [[ -x /usr/local/bin/brew ]]; then
		brew_bin="/usr/local/bin/brew"
	elif command -v brew >/dev/null 2>&1; then
		brew_bin="$(command -v brew)"
	fi

	if [[ -n "$brew_bin" ]]; then
		eval "$("$brew_bin" shellenv)"
	fi
}

backup_path() {
	local target="$1"

	if [[ -e "$target" && ! -L "$target" ]]; then
		mkdir -p "$BACKUP_DIR$(dirname "${target#$HOME}")"
		mv "$target" "$BACKUP_DIR/${target#$HOME/}"
		info "Backed up $target"
	fi
}

link_file() {
	local source="$1"
	local target="$2"

	mkdir -p "$(dirname "$target")"
	backup_path "$target"
	ln -sfn "$source" "$target"
	info "Linked $target"
}

info "Restoring dotfiles from $DOTFILES_DIR"

# Keep the repository itself as ~/.config. If it was cloned elsewhere, link it.
if [[ "$DOTFILES_DIR" != "$HOME/.config" ]]; then
	backup_path "$HOME/.config"
	ln -sfn "$DOTFILES_DIR" "$HOME/.config"
	info "Linked ~/.config -> $DOTFILES_DIR"
fi

# Home-level files that are commonly read from ~/ instead of ~/.config.
[[ -f "$DOTFILES_DIR/zsh/.zshrc" ]] && link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# Use the repo Git config without copying secrets or machine state.
if [[ -f "$DOTFILES_DIR/git/config" ]]; then
	git config --global include.path "$DOTFILES_DIR/git/config"
	info "Configured Git to include $DOTFILES_DIR/git/config"
fi

# Package restore. Brewfile is intentionally curated for this dotfiles setup.
if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
	ensure_homebrew
	load_homebrew

	if command -v brew >/dev/null 2>&1; then
		info "Installing packages from Brewfile"
		brew bundle --file "$DOTFILES_DIR/Brewfile"
	else
		warn "Homebrew is not available. Install it manually, then run: brew bundle --file ~/.config/Brewfile"
	fi
fi

info "Done. Restart your terminal."
cat <<'EOF'

Manual steps that should stay manual:
- Add or restore your SSH key.
- Run: gh auth login
- Sign in to Raycast and import/export Raycast settings if needed.
- Sign in to Atuin if you use history sync.
- Open Neovim once so plugins can install/update.

EOF
