# =============================================================================
#                             ZSH CONFIGURATION
# =============================================================================
# ~/.config/zsh/.zshrc
#
# Mantainer: Gemini
# Last-gen: 2025-08-05 (Nix-style Plugins)
#
# Description:
# This configuration uses zplug for plugin management to mirror the Nix setup,
# integrating zsh-autocomplete and zsh-vi-mode while keeping personal aliases
# and functions.
#
# Structure:
# 1. Login Shell Configuration (PATHs, Environment)
# 2. Zplug Plugin Management
# 3. Tool Initializations (Starship, Atuin, Zoxide, etc.)
# 4. Shell Options & History
# 5. Keybindings (Managed by zsh-vi-mode)
# 6. Aliases
# 7. Functions
# 8. Finalization & Auto-start
# =============================================================================

# ----------------------------------------------------------------------------
# 1. LOGIN SHELL CONFIGURATION (runs once per login)
# ----------------------------------------------------------------------------
if [[ -o login ]]; then
  # --- PATH Configuration ---
  export PATH="$HOME/.local/bin:$PATH"
  export PATH="$HOME/.codeium/windsurf/bin:$PATH"
  export PATH="$HOME/.opencode/bin:$PATH"
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"

  # --- Pyenv ---
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"

  # --- Environment Variables ---
  export EDITOR='nvim'
  export VISUAL='nvim'
  export HOMEBREW_NO_AUTO_UPDATE=1
  export ICLOUD_DRIVE_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
fi

# ----------------------------------------------------------------------------
# 2. ZPLUG PLUGIN MANAGEMENT
# ----------------------------------------------------------------------------

# Initialize zplug
export ZPLUG_HOME=/opt/homebrew/opt/zplug
source $ZPLUG_HOME/init.zsh

# Define plugins (Nix-style)
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "marlonrichert/zsh-autocomplete", as:plugin, from:github
zplug "jeffreytse/zsh-vi-mode", as:plugin, from:github

# Install plugins if they aren't already installed
if ! zplug check --verbose; then
    printf "Install? [y/N] "
    if read -q r;
    then
        echo; zplug install
    fi
fi

# Load plugins
zplug load

# ----------------------------------------------------------------------------
# 3. TOOL INITIALIZATIONS (runs for every new shell)
# ----------------------------------------------------------------------------

# --- Compinit (must run before completion-dependent tools) ---
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# --- Starship Prompt ---
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# --- NVM (Node Version Manager) - LAZY LOADING ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- Atuin (Shell History) ---
eval "$(atuin init zsh)"

# --- Zoxide (Smarter cd) ---
eval "$(zoxide init zsh)"

# --- fzf (Fuzzy Finder) ---
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# --- Carapace (Completion System) ---
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# ----------------------------------------------------------------------------
# 4. SHELL OPTIONS & HISTORY
# ----------------------------------------------------------------------------
HISTFILE="$HOME/.zhistory"
HISTSIZE=50000
SAVEHIST=50000
setopt BANG_HIST EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS HIST_VERIFY

# ----------------------------------------------------------------------------
# 5. KEYBINDINGS
# ----------------------------------------------------------------------------
# This section is now managed by the zsh-vi-mode plugin.
# Custom bindings that don't conflict can be added here.
# e.g., bindkey "ç" fzf-cd-widget # Fix for Alt+C on macOS

# ----------------------------------------------------------------------------
# 6. ALIASES
# ----------------------------------------------------------------------------

# --- General & Navigation ---
alias cl='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias pwdy='echo $(pwd) | pbcopy'
alias reload-zsh='source ~/.config/zsh/.zshrc'
alias edit-zsh='nvim ~/.config/zsh/.zshrc'
alias icloud='cd "$ICLOUD_DRIVE_PATH"'

# --- Tool Aliases ---
alias cat='bat'
alias ls='eza --icons=always'
alias vim='nvim'
alias lg='lazygit'
alias pip='pip3'

# --- Eza (ls replacement) ---
alias l='eza -lF --icons --git -a'
alias ll='eza -lF --icons --git'
alias lt='eza --tree --level=2 --icons --git'
alias ltree='eza --tree --level=3 --icons --git'

# --- Git ---
alias gits='git status'
alias gita='git add -u'
alias gitp='git push'
alias gitc='aicommits'
alias gc='git commit -m'
alias gitu='git commit -m "Update $(date +%F)"'
alias gitq='git add -u && git commit -m "Update $(date +%F)" && git push'

# --- Docker ---
alias dco='docker compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias dl='docker ps -l -q'
alias dx='docker exec -it'

# --- Azure ---
alias sub='az account set -s'

# opencode
alias oc='opencode'
alias oce='OPENCODE_EXPERIMENTAL_PLAN_MODE=1 opencode'


# --- App Shortcuts ---
alias leet='nvim leetcode.nvim'

# ----------------------------------------------------------------------------
# 7. FUNCTIONS
# ----------------------------------------------------------------------------

# --- fzf Configuration ---
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {}'"

# fzf aliases with improved previews
alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim $(fzf --preview="bat --theme=gruvbox-dark --color=always {})"'

# ya_zed - open files from yazi in zed
ya_zed() {
    tmp=$(mktemp -t "yazi-chooser.XXXXXXXXXX")
    yazi --chooser-file "$tmp" "$@"

    if [[ -s "$tmp" ]]; then
        opened_file=$(head -n 1 -- "$tmp")
        if [[ -n "$opened_file" ]]; then
            zed --add "$opened_file"
        fi
    fi
    rm -f -- "$tmp"
}

# y - yazi with auto cd on exit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ----------------------------------------------------------------------------
# 8. FINALIZATION & AUTO-START
# ----------------------------------------------------------------------------

# --- Auto-start Tmux ---
function start_if_needed() {
    if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -t 1 ]] && [[ -z "$ZED_TERMINAL" ]]; then
        tmux attach -t default 2>/dev/null || tmux new -s default
    fi
}
start_if_needed

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# direnv - auto-export environment variables based on directory
eval "$(direnv hook zsh)"


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
