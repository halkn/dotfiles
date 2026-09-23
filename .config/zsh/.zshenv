# ---------------------------------------------------------------------------
# environment variables
# ---------------------------------------------------------------------------
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

# Clones land at <host>/<owner>/<repo> under this root. `repo` (bin/repo) owns that
# layout. Exported because `repo` is a separate process.
: "${REPO_ROOT:=$HOME/repos}"
export REPO_ROOT

# Worktrees (<owner>/<repo>/<branch> under this root). herdr's `[worktrees]
# directory` holds the same path, so a worktree herdr creates and one `wt new`
# creates land in the same tree: the two must be changed together.
: "${WT_ROOT:=$XDG_DATA_HOME/worktrees}"
export WT_ROOT

# zsh
skip_global_compinit=1

# rumdl
export RUMDL_CACHE_DIR=$XDG_CACHE_HOME/rumdl

# uv
export UV_CACHE_DIR=$XDG_CACHE_HOME/uv
export UV_PYTHON_PREFERENCE=only-managed
export UV_PROJECT_ENVIRONMENT=.venv
export UV_COMPILE_BYTECODE=true

# go
# GOBIN is left unset so it stays $GOPATH/bin: Go Makefiles commonly resolve
# their install dir with `go env GOPATH`/bin and would otherwise look elsewhere.
export GOPATH=$XDG_DATA_HOME/go
export GOMODCACHE=$XDG_CACHE_HOME/go/mod
export GOCACHE=$XDG_CACHE_HOME/go/build

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
  $GOPATH/bin(N-/)
  $path
)

# ---------------------------------------------------------------------------
# machine-local overrides (not tracked in git)
# ---------------------------------------------------------------------------
[[ -f "$ZDOTDIR/.zshenv.local" ]] && source "$ZDOTDIR/.zshenv.local"
