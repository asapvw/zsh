#!/usr/bin/env zsh
# =============================================================================
# ~/.zshrc — interactive shell configuration
# Environment variables (WIN_HOME, DOTFILES, REPOS, etc.) are set in .zshenv,
# which zsh always sources BEFORE this file. Do not redefine them here.
# =============================================================================

# -----------------------------------------------------------------------------
# Self-healing symlinks (safety net)
# Only relinks when a target is missing or points to the wrong place.
# Bails immediately if $DOTFILES is unresolved, so it can never create broken
# relative links. Silent on success. For a fresh machine, run bootstrap.zsh.
# -----------------------------------------------------------------------------
_ensure_links() {
  [[ -z "$DOTFILES" || ! -d "$DOTFILES" ]] && return

  typeset -A links=(
    "$DOTFILES/cli/linux/.zshrc"       "$HOME/.zshrc"
    "$DOTFILES/cli/linux/.zshenv"      "$HOME/.zshenv"
    "$DOTFILES/cli/linux/yazi.toml"    "$HOME/.config/yazi/yazi.toml"
    "$DOTFILES/git/.gitconfig"         "$HOME/.gitconfig"
    "$DOTFILES/nvim"                   "$HOME/.config/nvim"
  )
  for src target in "${(@kv)links}"; do
    if [[ ! -L "$target" || "$(readlink "$target")" != "$src" ]]; then
      mkdir -p "$(dirname "$target")"
      ln -sf "$src" "$target"
    fi
  done
}
_ensure_links

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
# setopt histignorealldups sharehistory
# setopt INC_APPEND_HISTORY   # write each command as it's entered

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# =========================================================
# Smart directory navigation & lf
# =========================================================

LF_ICONS=$(cat ~/.config/lf/icons | tr '\n' ':')
export LF_ICONS

# Initialize zoxide
eval "$(zoxide init zsh)"

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# =========================================================
# Fuzzy finder
# =========================================================

# macOS / Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

# macOS / Homebrew (Intel)
if [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
fi

# Arch
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# Ubuntu
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# =========================================================
# Modular Config Files
# =========================================================

# fzf configuration
source "$ZDOTDIR/fzf.zsh"

# Aliases
source "$ZDOTDIR/aliases.zsh"

# Custom keybindings
source "$ZDOTDIR/bindings.zsh"

# Plugins and plugin manager
source "$ZDOTDIR/plugins.zsh"

# Prompt/theme
source "$ZDOTDIR/prompt.zsh"


# =========================================================
# Node / NVM
# =========================================================

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Set up the prompt
autoload -Uz promptinit
promptinit
prompt adam1

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Completion styling (compinit runs after Homebrew is initialized below)
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Homebrew — sets PATH, MANPATH, INFOPATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Add Homebrew completions to fpath, then initialize completion system
fpath=("/home/linuxbrew/.linuxbrew/share/zsh/site-functions" $fpath)
autoload -Uz compinit
compinit

# Configure zoxide
eval "$(zoxide init zsh)"

# fzf — use fd as default finder
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always {}' --preview-window=right:50%"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -100'"

function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Fix CRLF line endings (Windows -> Unix)
fix_crlf() {
  dos2unix "$1" 2>/dev/null || sed -i 's/\r//' "$1"
}

# Better ls
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'

# Quick navigation
alias ..='cd ..'
alias ...='cd ~'
alias ....='cd ../..'

# Shortcuts
alias cl='clear'
alias cat='bat'
alias grep='rg'
alias lg='lazygit'
alias bru='brew update && brew upgrade -y'
alias aptu='sudo apt update && sudo apt upgrade -y'
alias resclaude='claude --resume'

# Claude Code
alias cleanpaste='xclip -selection clipboard -o | sed "s/[▏▕│┃]//g" | sed "s/[[:space:]]*$//" | xclip -selection clipboard -i'

# repo picker function
function repo() {
  local dir
  dir=$(fd . "$REPOS" --max-depth 1 --type d | fzf --prompt="repo> ")
  [[ -n "$dir" ]] && cd "$dir"
}

# Persistent SSH agent — pinned socket, survives across shells
export SSH_AUTH_SOCK="/tmp/ssh-agent-$(id -u).sock"

_start_agent() {
    rm -f "$SSH_AUTH_SOCK"
    ssh-agent -a "$SSH_AUTH_SOCK" > /dev/null
    ssh-add ~/.ssh/asapvw
}

# Exit codes: 0=keys loaded, 1=agent alive but no keys, 2=agent dead
if ssh-add -l &>/dev/null; then
    : # keys already loaded, nothing to do
elif ssh-add ~/.ssh/asapvw &>/dev/null; then
    : # agent alive, key added successfully
else
    _start_agent # agent dead or key add failed — full restart
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/asapvw/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/asapvw/miniforge3/etc/profile.d/conda.sh" ]; then
#         . "/home/asapvw/miniforge3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/asapvw/miniforge3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# # <<< conda initialize <

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/codeql:$PATH"

export EDITOR=nvim
export VISUAL=nvim

# Keybindings
bindkey "^[[3~" delete-char        # Del
bindkey "^[[1;5C" forward-word     # Ctrl+Right
bindkey "^[[1;5D" backward-word    # Ctrl+Left
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

cd ~

