# =========================================================
# Modern CLI replacements
# =========================================================

# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza
compdef eza=ls

# Better cat (bat on Arch, batcat on Ubuntu)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias cat='batcat'
fi

# fd (fdfind on Ubuntu)
if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# =========================================================
# Editor
# =========================================================

# NeoVim
alias vim='nvim'
