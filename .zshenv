# =============================================================================
# ~/.config/zsh/.zshenv — environment variables, sourced for ALL zsh sessions
# Keep this file fast and side-effect free (no evals, no output)
# =============================================================================

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"

# -----------------------------------------------------------------------------
# Windows host home (WSL2 mount of C:\Users\<user>)
# Resolution order:
#   1. ~/.zsh_local (per-machine, untracked) — authoritative if present
#   2. $USERPROFILE via wslpath — fast, works when WSLENV forwards it
#   3. cmd.exe query — fallback when $USERPROFILE is empty/unset
# -----------------------------------------------------------------------------
# Per-machine overrides (untracked), if present
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# Auto-derive Windows home if not already set by .zsh_local
if [[ -z "$WIN_HOME" ]]; then
  WIN_HOME="$(wslpath "$USERPROFILE" 2>/dev/null)"
  # wslpath "" returns "." — reject that (and any non-directory) so the
  # cmd.exe fallback actually fires instead of silently accepting garbage.
  if [[ -z "$WIN_HOME" || "$WIN_HOME" == "." || ! -d "$WIN_HOME" ]]; then
    WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null)"
  fi
fi
export WIN_HOME

export REPOS="$WIN_HOME/repos"
export DOTFILES="$WIN_HOME/repos/dotfiles"
export ASAPVW="$WIN_HOME/repos/asapvw.xcx"
export QOPRODUCT="$WIN_HOME/repos/qo-product"
export QODOCS="$WIN_HOME/repos/qo-docs"
