# =========================================================
# fzf
# =========================================================

# strip-cwd-prefix removes the leading ./ from results
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --strip-cwd-prefix'

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -100'"

# ---------------------------------------------------------
# Shell integration: Ctrl+R history, Ctrl+T files, Alt+C dirs.
# Called again from zvm_after_init (bindings.zsh) because zsh-vi-mode
# wipes all key bindings when it initialises at the first prompt.
# ---------------------------------------------------------
_fzf_shell_integration() {
  local dir
  for dir in \
    "${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}/opt/fzf/shell" \
    /opt/homebrew/opt/fzf/shell \
    /usr/local/opt/fzf/shell \
    /usr/share/fzf \
    /usr/share/doc/fzf/examples
  do
    if [[ -r "$dir/key-bindings.zsh" ]]; then
      source "$dir/key-bindings.zsh"
      [[ -r "$dir/completion.zsh" ]] && source "$dir/completion.zsh"
      return 0
    fi
  done
}
_fzf_shell_integration

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden
