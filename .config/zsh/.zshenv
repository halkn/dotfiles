# ---------------------------------------------------------------------------
# environment variables
# ---------------------------------------------------------------------------
# common
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

# zsh
skip_global_compinit=1

# rumdl
export RUMDL_CACHE_DIR=$XDG_CACHE_HOME/rumdl

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
  # $XDG_DATA_HOME/mise/shims(N-/)
  $path
)

# ---------------------------------------------------------------------------
# machine-local overrides (not tracked in git)
# ---------------------------------------------------------------------------
[[ -f "$ZDOTDIR/.zshenv.local" ]] && source "$ZDOTDIR/.zshenv.local"
