# ---------------------------------------------------------------------------
# environment variables
# ---------------------------------------------------------------------------
# common
export LANG=C.UTF-8
export EDITOR=vim
export PAGER=less

# XDG Base Directory
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.local/cache
export XDG_DATA_HOME=~/.local/share
export XDG_BIN_HOME=~/.local/bin
export XDG_STATE_HOME=~/.local/state

# zsh
skip_global_compinit=1

# bun
export BUN_INSTALL="$HOME/.bun"

# uv
export UV_CACHE_DIR=$XDG_CACHE_HOME/uv
export UV_PYTHON_PREFERENCE=only-managed
export UV_PROJECT_ENVIRONMENT=.venv
export UV_COMPILE_BYTECODE=true

# less
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

# ripgrep
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

# ---------------------------------------------------------------------------
# path
# ---------------------------------------------------------------------------
typeset -U path
path=(
  $XDG_BIN_HOME(N-/)
  $BUN_INSTALL/bin(N-/)
  $path
)
