# asapvw zsh shell .config

## Dependencies

### Setup Homebrew

#### 1. Install prerequisites 

```shell
sudo apt-get install build-essential procps curl file git
```

#### 2. Install Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 3. Add Homebrew to shell runtime config

Add Homebrew to your `PATH` to your shell rcfile (`~/.bashrc` for `bash` or `~/.zshrc` for `zsh`).

```shell
test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
```

### Setup `zsh` shell

#### 1. Install `zsh`

```shell
brew install zsh
```

#### 2. Get the repo into `~/.config/zsh`

Clone it there directly, or symlink an existing working copy (the WSL setup
symlinks the copy that lives on the Windows mount):

```shell
git clone git@github.com:asapvw/zsh.git ~/.config/zsh
# — or —
ln -sn /mnt/c/Users/<you>/repos/zsh ~/.config/zsh
```

#### 3. Point zsh at the config via `ZDOTDIR`

Create a `~/.zshenv` bootstrap stub (no root needed):

```sh
cat > ~/.zshenv <<'EOF'
# Bootstrap stub — the real zsh config lives in $ZDOTDIR (~/.config/zsh).
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
```

Alternatively (requires root, and then the stub is unnecessary), add to
`/etc/zsh/zshenv`:

```sh
if [[ -z "$XDG_CONFIG_HOME" ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```

#### 4. Configure `zsh` as default shell

```shell
chsh -s $(which zsh)
```

#### 5. Create required directories

```shell
mkdir -p ~/.local/state/zsh   # history
mkdir -p ~/.cache/zsh         # completion cache
```

#### 6. Start a new shell

```shell
exec zsh
```


Plugins are installed automatically on first launch via the built-in plugin manager.

### Setup Shell Tools

```shell
brew install neovim eza bat fd fzf zoxide starship ripgrep
```

## Plugins

Managed without a third-party plugin manager. Plugins are cloned into `~/.local/share/zsh/plugins/` on first launch (kept off `$ZDOTDIR`, which may sit on a slow `/mnt/c` mount in WSL).

| Plugin | Purpose |
|--------|---------|
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Syntax highlighting |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-style inline suggestions |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Up/down arrow history filtering |
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi keybindings |

To update all plugins:

```sh
zplugin-update
```

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search including hidden files (fzf + fd) |
| `Ctrl+F` | Fuzzy file search excluding hidden files (fzf + fd) |
| `Ctrl+→` | Move forward one word |
| `Ctrl+←` | Move backward one word |
| `↑` / `↓` | History search by prefix |
| `Ctrl+\` | Toggle autosuggestions |

## Starship Config

Included in the repo at [`starship.toml`](./starship.toml) and loaded automatically via `STARSHIP_CONFIG` in `.zshenv`. Requires a [Nerd Font](https://www.nerdfonts.com) in your terminal.
