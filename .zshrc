#!/usr/bin/env zsh
# =============================================================================
# ~/.config/zsh/.zshrc — interactive shell configuration
# Environment variables (WIN_HOME, DOTFILES, REPOS, etc.) are set in .zshenv,
# which zsh always sources BEFORE this file. Do not redefine them here.
# =============================================================================

# =========================================================
# Homebrew — must run first: every tool below (zoxide,
# starship, fzf, eza, bat, fd, rg) lives in the brew prefix
# =========================================================

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  # Brew-installed completions must be on fpath before compinit runs
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

# Generated user completions (e.g. `pdm completion zsh > .../_pdm`) live on
# the native filesystem for the same drvfs reason as plugins (see plugins.zsh)
fpath=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions" $fpath)

# Deduplicate entries accumulated across nested shells
typeset -U path fpath

# =========================================================
# Interactive-session environment
# =========================================================

# bat is brew-installed, so this check only works after shellenv above
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
fi

export GPG_TTY=$(tty)

# -----------------------------------------------------------------------------
# Self-healing symlinks (safety net)
# Only relinks when a target is missing or points to the wrong place.
# Bails immediately if $DOTFILES is unresolved, so it can never create broken
# relative links. Silent on success. For a fresh machine, run bootstrap.zsh.
# Note: zsh config itself is NOT linked here — it loads via ZDOTDIR
# (~/.zshenv stub points ZDOTDIR at ~/.config/zsh, a symlink to this repo).
# -----------------------------------------------------------------------------
_ensure_links() {
  # CLI tool configs live in this repo (tools/), addressed via $ZDOTDIR so the
  # links survive a repo move/rename. Cross-platform configs (gitconfig, nvim)
  # stay in the dotfiles repo.
  typeset -A links=(
    "$ZDOTDIR/tools/tmux/tmux.conf"     "$HOME/.config/tmux/tmux.conf"
    "$ZDOTDIR/tools/yazi/yazi.toml"     "$HOME/.config/yazi/yazi.toml"
    "$ZDOTDIR/tools/yazi/keymap.toml"   "$HOME/.config/yazi/keymap.toml"
    "$ZDOTDIR/tools/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
    "$ZDOTDIR/tools/btop"               "$HOME/.config/btop"
    "$ZDOTDIR/tools/git/ignore"         "$HOME/.config/git/ignore"
    "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
    "$DOTFILES/nvim"                    "$HOME/.config/nvim"
    # Lets ~-based paths in the shared .gitconfig (core.excludesFile etc.)
    # resolve identically on WSL and Windows
    "$WIN_HOME/repos"                   "$HOME/repos"
  )
  for src target in "${(@kv)links}"; do
    [[ -e "$src" ]] || continue  # skip if source repo/file isn't present
    if [[ ! -L "$target" || "$(readlink "$target")" != "$src" ]]; then
      # A real (non-link) dir at $target would swallow the link; move it aside
      [[ -d "$target" && ! -L "$target" ]] && mv "$target" "$target.pre-link.bak"
      mkdir -p "$(dirname "$target")"
      ln -sfn "$src" "$target"
    fi
  done
}
_ensure_links

# =========================================================
# Auto-launch tmux — replaces this shell (exec), so exiting
# tmux closes the terminal. Rollback: set AUTO_TMUX=0 in
# ~/.zsh_local (or remove this block) to restore the old
# manual workflow (`t` to enter tmux). tmux-continuum
# restores saved sessions when the server starts.
# Must stay after brew shellenv (tmux is brew-installed) and
# _ensure_links (tmux.conf symlink), before the config below
# (redundant work for a shell about to exec away).
# =========================================================

if [[ "${AUTO_TMUX:-1}" != 0 ]] &&      # opt-out flag, set in ~/.zsh_local
   [[ -z "$TMUX" ]] &&                  # not already inside tmux
   [[ -z "$ZSH_EXECUTION_STRING" ]] &&  # not `zsh -i -c ...` (smoke tests, scripts)
   [[ "$TERM_PROGRAM" != "vscode" ]] && # IDE terminals manage their own tabs
   [[ -t 0 && -t 1 ]] &&                # real tty on stdin/stdout, not a pipe
   command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt SHARE_HISTORY          # share (and incrementally append) across sessions
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# =========================================================
# Smart directory navigation & lf
# =========================================================

[[ -r ~/.config/lf/icons ]] && export LF_ICONS="$(tr '\n' ':' < ~/.config/lf/icons)"

# Initialize zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

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

# Colored completion listings
command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Highlight PIDs and show useful columns when completing kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# =========================================================
# Modular Config Files
# =========================================================

# fzf configuration (also sources fzf key-bindings + completion)
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

# Inert when nvm isn't installed (node comes from brew on this machine)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# =========================================================
# Extra PATH entries
# =========================================================

path+=("$HOME/.local/share/codeql")

# =========================================================
# Persistent SSH agent — pinned socket, survives across shells
# =========================================================

export SSH_AUTH_SOCK="/tmp/ssh-agent-$(id -u).sock"

_start_agent() {
    rm -f "$SSH_AUTH_SOCK"
    ssh-agent -a "$SSH_AUTH_SOCK" > /dev/null
    ssh-add -q ~/.ssh/asapvw
}

# Exit codes: 0=keys loaded, 1=agent alive but no keys, 2=agent dead
if ssh-add -l &>/dev/null; then
    : # keys already loaded, nothing to do
elif ssh-add -q ~/.ssh/asapvw &>/dev/null; then
    : # agent alive, key added successfully
else
    _start_agent # agent dead or key add failed — full restart
fi
