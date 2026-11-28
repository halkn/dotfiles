# Environment for login bash. While zsh stays in use this mirrors
# .config/zsh/.zshenv: change the two together.

export LANG=C.UTF-8
export EDITOR=nvim
export PAGER=less

# XDG Base Directory
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_BIN_HOME XDG_STATE_HOME

# `repo` and `hw` (bin/) read these; herdr's `[worktrees] directory` holds the
# same path as WT_ROOT.
: "${REPO_ROOT:=$HOME/repos}"
: "${WT_ROOT:=$XDG_DATA_HOME/worktrees}"
export REPO_ROOT WT_ROOT

export RUMDL_CACHE_DIR="$XDG_CACHE_HOME/rumdl"

export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_PYTHON_PREFERENCE=only-managed
export UV_PROJECT_ENVIRONMENT=.venv
export UV_COMPILE_BYTECODE=true

# GOBIN is left unset so it stays $GOPATH/bin, where Go Makefiles look.
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export GOCACHE="$XDG_CACHE_HOME/go/build"
export GOENV="$XDG_CONFIG_HOME/go/env"
# gopls appends /gopls itself.
export GOPLSCACHE="$XDG_CACHE_HOME"
export STATICCHECK_CACHE="$XDG_CACHE_HOME/staticcheck"

export BUN_INSTALL_CACHE_DIR="$XDG_CACHE_HOME/bun/install/cache"
export BUN_INSTALL_GLOBAL_DIR="$XDG_DATA_HOME/bun/install/global"
export BUN_INSTALL_BIN="$XDG_DATA_HOME/bun/bin"

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# Prepended in reverse so XDG_BIN_HOME ends up first. The check keeps a nested
# login shell from stacking duplicates.
for _dir in "$CARGO_HOME/bin" "$BUN_INSTALL_BIN" "$GOPATH/bin" "$XDG_BIN_HOME"; do
  [[ -d $_dir && ":$PATH:" != *":$_dir:"* ]] && PATH=$_dir:$PATH
done
unset _dir

# A login shell reads only this file; bashrc returns at once when not interactive.
[[ -f ~/.bashrc ]] && source ~/.bashrc
