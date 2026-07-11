# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Zsh configuration for a WSL2 Ubuntu machine, created by merging a personal config into the open-source [radleylewis/zsh](https://github.com/radleylewis/zsh) project. There is no build, lint, or test suite — validation is done by syntax-checking and launching a shell.

## Validation commands

```sh
zsh -n .zshrc                      # syntax check any file (no execution)
ZDOTDIR=$PWD zsh -i -c exit        # smoke-test THIS repo's config end to end
time ZDOTDIR=$PWD zsh -i -c exit   # startup-time measurement
```

Without the `ZDOTDIR=$PWD` override, `zsh -i` tests the machine's live config, not this working copy (see below).

## Deployment model — read this before editing

This working copy IS the live config. `~/.config/zsh` is a symlink to this repo, and a `~/.zshenv` bootstrap stub sets `ZDOTDIR="$HOME/.config/zsh"` and sources `$ZDOTDIR/.zshenv` (the stub exists because setting `ZDOTDIR` in `/etc/zsh/zshenv` would need root). Load order: `~/.zshenv` stub → `$ZDOTDIR/.zshenv` → `$ZDOTDIR/.zshrc` → the five modular files.

Consequences:

1. Edits here take effect in the next shell — no copy/sync step. Test with `zsh -i -c exit` before considering a change done.
2. The dotfiles repo (`$WIN_HOME/repos/dotfiles/cli/linux/`) still contains stale `.zshrc`/`.zshenv` copies from the pre-ZDOTDIR era; its `bootstrap.zsh` no longer links them. Do not resurrect them.
3. `_ensure_links` in `.zshrc` self-heals only the non-zsh symlinks (yazi, gitconfig, nvim) toward the dotfiles repo.
4. Plugins clone to `~/.local/share/zsh/plugins/` (not `$ZDOTDIR/plugins/`) to keep them off the slow `/mnt/c` drvfs mount.

## File roles and load order

- `.zshenv` — sourced by *every* zsh invocation (including scripts); must stay fast and output-free. Sets XDG dirs, editor, and derives `WIN_HOME` (WSL mount of the Windows home) with a `wslpath`/`cmd.exe` fallback chain, caching the result to `~/.zsh_local`. `~/.zsh_local` (untracked, per-machine) is sourced first and wins. Interactive-only setup (MANPAGER, GPG_TTY, tool inits) belongs in `.zshrc`, not here.
- `.zshrc` — interactive config. Order is load-bearing: Homebrew `shellenv` + `fpath` first (every tool below is brew-installed), then `compinit` (once, with the XDG-cached dump), then the modular files, then NVM/SSH-agent. Don't add a second `compinit`, a second `zoxide init`, or prompt-theme calls (`promptinit`/`prompt`) — starship in `prompt.zsh` owns the prompt.
- `fzf.zsh`, `aliases.zsh`, `bindings.zsh`, `plugins.zsh`, `prompt.zsh` — modular files, each sourced from `.zshrc`. Aliases and shell functions go in `aliases.zsh`; fzf env vars and widgets in `fzf.zsh`.
- `.src-zshenv`, `.src-zshrc`, `SRC-README.md` — pristine reference copies of the upstream project ([radleylewis/zsh](https://github.com/radleylewis/zsh)). Never edit these as live config; they exist for diffing against upstream.
- `starship.toml` — prompt config, loaded via `STARSHIP_CONFIG="$ZDOTDIR/starship.toml"` in `.zshenv`.

## Plugin system

No third-party plugin manager. `plugins.zsh` defines `_zplugin_load`, which clones each plugin into `~/.local/share/zsh/plugins/` on first launch and sources it. `zplugin-update` pulls all of them.

**zsh-vi-mode constraint:** the plugin resets all keybindings when it initializes at the first prompt. Any `bindkey` must be registered inside the `zvm_after_init()` hook in `bindings.zsh` or it will be silently wiped. That hook also re-runs `_fzf_shell_integration` (defined in `fzf.zsh`) to restore fzf's Ctrl+R/Ctrl+T/Alt+C — keep that call first if you edit the hook.

## Conventions

- Commit messages follow loose conventional-commit prefixes: `feat:`, `fix:`, `refactor:`, `chore:`.
- Work happens on `qo/YYYY.WW` branches (e.g. `qo/2026.28`); PRs target `main`.
- Machine-specific values go in `~/.zsh_local`, never committed.
