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
export ZHOMEDIR=$XDG_CONFIG_HOME/zsh
export ZDATADIR=$XDG_DATA_HOME/zsh
export ZCACHEDIR=$XDG_CACHE_HOME/zsh
export ZSTATEDIR=$XDG_STATE_HOME/zsh
export ZPLUGINDIR=$XDG_DATA_HOME/zsh_plugins

# node/npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# deno
export DENO_INSTALL=~/.local/opt/deno
export DENO_DIR=$XDG_CACHE_HOME/deno
export DENO_INSTALL_ROOT=$XDG_BIN_HOME
export DENO_NO_UPDATE_CHECK=1

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

# fzf
export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border
  --info=inline
  --preview-window=right:60%:wrap
  --bind ctrl-u:preview-page-up,ctrl-d:preview-page-down
  --bind ctrl-/:toggle-preview
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# ---------------------------------------------------------------------------
# path
# ---------------------------------------------------------------------------
typeset -U path
path=(
  $XDG_BIN_HOME(N-/)
  $XDG_DATA_HOME/npm/bin(N-/)
  $path
)
