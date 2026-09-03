if status is-interactive
    # Install Fisher if not installed
    if not functions -q fisher
        echo "Fisher not installed. Run: curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
    end
end

# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    # Termux - use PREFIX for binaries
    set -x PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
else if test (uname) = Darwin
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
else
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
end

# Resolve Homebrew through PATH first, then the standard macOS locations.
if test $IS_TERMUX -eq 0
    set -l brew_bin (command -s brew)
    if not test -x "$brew_bin"
        for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew
            if test -x $candidate
                set brew_bin $candidate
                break
            end
        end
    end
    if test -x "$brew_bin"
        eval ($brew_bin shellenv)
    end
end

# Do not auto-start tmux from the shell.
# Ghostty starts Herdr directly, and Herdr panes should stay plain shell panes.

# Initialize tools
set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml
if type -q starship
    starship init fish | source
end
if type -q zoxide
    zoxide init fish | source
end
if type -q atuin
    atuin init fish | source
end
if type -q fzf
    fzf --fish | source
end

set -x PATH $HOME/.cargo/bin $PATH

# Carapace completions
if type -q carapace
    set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    if not test -d ~/.config/fish/completions
        mkdir -p ~/.config/fish/completions
    end
    if not test -f ~/.config/fish/completions/.initialized
        carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
        touch ~/.config/fish/completions/.initialized
    end
    carapace _carapace | source
end

set -g fish_greeting ""

# Set nvim as default editor for opencode and other tools
set -gx EDITOR nvim
set -gx VISUAL nvim

## alias

# Navegación
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias cl='clear'

# Herramientas modernas
alias cat='bat'
if type -q eza
    alias ls='eza --icons=always'
else
    alias ls='command ls'
end
alias vim='nvim'
alias lg='lazygit'

# Eza (mejor que ls)
alias l='eza -lF --icons --git -a'
alias ll='eza -lF --icons --git'
alias lt='eza --tree --level=2 --icons --git'
alias ltree='eza --tree --level=3 --icons --git'

# Git
alias gits='git status'
alias gita='git add -u'
alias gitp='git push'
alias gc='git commit -m'
alias gitu='git commit -m "Update $(date +%F)"'
alias gitq='git add -u && git commit -m "Update $(date +%F)" && git push'

# Docker
alias dco='docker compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias dx='docker exec -it'

# Opencode
alias oc='opencode'
alias oce='OPENCODE_EXPERIMENTAL_PLAN_MODE=1 opencode'

# Utilidades
alias pwdy='echo (pwd) | pbcopy'
alias icloud='cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs"'
alias reload-fish='source ~/.config/fish/config.fish'
alias edit-fish='nvim ~/.config/fish/config.fish'

alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=gruvbox-dark --color=always {}")'

set -l foreground F3F6F9 normal
set -l selection 263356 normal
set -l comment 8394A3 brblack
set -l red CB7C94 red
set -l orange DEBA87 orange
set -l yellow FFE066 yellow
set -l green B7CC85 green
set -l purple A3B5D6 purple
set -l cyan 7AA89F cyan
set -l pink FF8DD7 magenta

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

# Clear the screen only on interactive startup
if status is-interactive
    clear
end

# Added by Antigravity
fish_add_path $HOME/.antigravity/antigravity/bin

set -gx AWS_PROFILE default
set -gx AWS_REGION us-east-1

# Added by Antigravity IDE
fish_add_path $HOME/.antigravity-ide/antigravity-ide/bin

# Added by Antigravity CLI installer
fish_add_path $HOME/.local/bin
