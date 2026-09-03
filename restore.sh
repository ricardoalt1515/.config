#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_ROOT="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
LINKS_ONLY=false
APPLY_MACOS_DEFAULTS=false
CORE=false
OPTIONAL=false
AGENTS=false
PROFILE_SELECTED=false
BREW_BIN=""
CONFIG_ROOT_REPLACED=false

usage() {
	cat <<'EOF'
Usage: ./restore.sh [options]

Options:
  --profile core|optional|agents  Select a package/config profile (repeatable)
  --links-only                    Project config without installing packages
  --macos-defaults                Apply macOS defaults after restore
  --dry-run                       Print actions without changing anything
  -h, --help                      Show this help

The core profile is selected when no profile is given.
EOF
}

select_profile() {
	case "$1" in
	core) CORE=true ;;
	optional) OPTIONAL=true ;;
	agents) AGENTS=true ;;
	*) printf 'Unknown profile: %s\n' "$1" >&2; exit 2 ;;
	esac
	PROFILE_SELECTED=true
}

while (($#)); do
	case "$1" in
	--profile)
		[[ $# -ge 2 ]] || { printf '%s\n' '--profile requires a value' >&2; exit 2; }
		select_profile "$2"
		shift 2
		;;
	--profile=*) select_profile "${1#*=}"; shift ;;
	--links-only) LINKS_ONLY=true; shift ;;
	--macos-defaults) APPLY_MACOS_DEFAULTS=true; shift ;;
	--dry-run) DRY_RUN=true; shift ;;
	-h|--help) usage; exit 0 ;;
	*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
	esac
done

[[ "$PROFILE_SELECTED" == true ]] || CORE=true
if [[ "$LINKS_ONLY" == true && "$APPLY_MACOS_DEFAULTS" == true ]]; then
	printf '%s\n' '--links-only cannot be combined with --macos-defaults' >&2
	exit 2
fi

info() {
	printf '==> %s\n' "$1"
}

replace_symlink_with_directory() {
	local target="$1"

	if [[ "$DRY_RUN" == true ]]; then
		info "Would replace symlink $target with a local directory"
		return 0
	fi
	rm "$target"
	mkdir -p "$target"
	info "Replaced symlink $target with a local directory"
}

backup_path() {
	local target="$1"
	local relative backup

	[[ -e "$target" && ! -L "$target" ]] || return 0
	relative="${target#"$HOME"/}"
	backup="$BACKUP_ROOT/$relative"
	if [[ "$DRY_RUN" == true ]]; then
		info "Would back up $target to $backup"
		return 0
	fi
	mkdir -p "$(dirname "$backup")"
	mv "$target" "$backup"
	info "Backed up $target to $backup"
}

link_path() {
	local source="$1"
	local target="$2"
	local parent_replaced=false

	[[ -e "$source" ]] || return 0
	if [[ "$DRY_RUN" == true ]]; then
		[[ "$CONFIG_ROOT_REPLACED" == true && "$target" == "$HOME/.config/"* ]] && parent_replaced=true
	fi
	if [[ "$source" -ef "$target" ]]; then
		info "Kept $target (source checkout is already live)"
		return 0
	fi
	if [[ "$parent_replaced" == false && -L "$target" && "$(readlink "$target")" == "$source" ]]; then
		info "Kept $target (already linked)"
		return 0
	fi
	[[ "$parent_replaced" == true ]] || backup_path "$target"
	if [[ "$DRY_RUN" == true ]]; then
		info "Would link $target -> $source"
		return 0
	fi
	mkdir -p "$(dirname "$target")"
	ln -sfn "$source" "$target"
	info "Linked $target -> $source"
}

link_core() {
	local path
	for path in config.fish fish_plugins conf.d functions themes; do
		link_path "$DOTFILES_DIR/fish/$path" "$HOME/.config/fish/$path"
	done
	link_path "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
	for path in init.lua lazyvim.json stylua.toml .neoconf.json lua; do
		link_path "$DOTFILES_DIR/nvim/$path" "$HOME/.config/nvim/$path"
	done
	link_path "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship/starship.toml"
	link_path "$DOTFILES_DIR/bat/themes" "$HOME/.config/bat/themes"
	link_path "$DOTFILES_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
	link_path "$DOTFILES_DIR/git/config" "$HOME/.config/git/config"
	link_path "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
	link_path "$DOTFILES_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"
	link_path "$DOTFILES_DIR/bin/ghostty-herdr" "$HOME/.config/bin/ghostty-herdr"
}

link_optional() {
	link_path "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
	link_path "$DOTFILES_DIR/herdr/sounds" "$HOME/.config/herdr/sounds"
	link_path "$DOTFILES_DIR/hunk/config.toml" "$HOME/.config/hunk/config.toml"
	link_path "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
	link_path "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
	link_path "$DOTFILES_DIR/atuin/config.toml" "$HOME/.config/atuin/config.toml"
}

resolve_homebrew() {
	BREW_BIN="$(command -v brew 2>/dev/null || true)"
	if [[ -z "$BREW_BIN" && -x /opt/homebrew/bin/brew ]]; then
		BREW_BIN=/opt/homebrew/bin/brew
	elif [[ -z "$BREW_BIN" && -x /usr/local/bin/brew ]]; then
		BREW_BIN=/usr/local/bin/brew
	fi
}

install_manifest() {
	local manifest="$1"
	if [[ "$DRY_RUN" == true ]]; then
		info "Would run ${BREW_BIN:-brew} bundle --file $DOTFILES_DIR/$manifest"
		return 0
	fi
	"$BREW_BIN" bundle --file "$DOTFILES_DIR/$manifest"
}

if [[ "$LINKS_ONLY" == false ]]; then
	resolve_homebrew
	if [[ -z "$BREW_BIN" ]]; then
		if [[ "$DRY_RUN" == true ]]; then
			printf 'Warning: Homebrew is missing; the real run would fail before package actions.\n' >&2
		else
			printf 'Homebrew is required for package profiles. Install it, then rerun this command.\n' >&2
			exit 1
		fi
	fi
fi

info "Restoring from $DOTFILES_DIR"
if [[ ( "$CORE" == true || "$OPTIONAL" == true ) && -L "$HOME/.config" ]]; then
	CONFIG_ROOT_REPLACED=true
	replace_symlink_with_directory "$HOME/.config"
fi
[[ "$CORE" == true ]] && link_core
[[ "$OPTIONAL" == true ]] && link_optional

if [[ "$AGENTS" == true && "$LINKS_ONLY" == true ]]; then
	info "Agents is a package-only profile; generated agent config remains installer-owned and no package action runs with --links-only."
fi

if [[ "$LINKS_ONLY" == false ]]; then
	[[ "$CORE" == true ]] && install_manifest Brewfile
	[[ "$OPTIONAL" == true ]] && install_manifest Brewfile.optional
	[[ "$AGENTS" == true ]] && install_manifest Brewfile.agents
fi

if [[ "$APPLY_MACOS_DEFAULTS" == true ]]; then
	if [[ "$DRY_RUN" == true ]]; then
		info "Would run $DOTFILES_DIR/macos/defaults.sh"
	else
		"$DOTFILES_DIR/macos/defaults.sh"
	fi
fi

if [[ "$LINKS_ONLY" == false && "$DRY_RUN" == true && -z "$BREW_BIN" ]]; then
	info "Restore dry-run incomplete: Homebrew is required for a real package restore"
	exit 1
fi

info "Restore complete"
