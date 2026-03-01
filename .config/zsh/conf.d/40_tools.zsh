# ── mise ─────────────────────────────────────────────
if command -v mise > /dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi

# ── uv ───────────────────────────────────────────────
if command -v uv > /dev/null 2>&1; then
  _uv_comp=$ZCACHEDIR/uv_completion.zsh
  _uv_bin=$(command -v uv)
  if [[ ! -f $_uv_comp || $_uv_bin -nt $_uv_comp ]]; then
    mkdir -p ${_uv_comp:h}
    uv generate-shell-completion zsh > $_uv_comp
  fi
  source $_uv_comp
  unset _uv_comp _uv_bin
fi

# ── eza ──────────────────────────────────────────────
if command -v eza > /dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first --time-style=long-iso --git'
  alias la='eza -la --group-directories-first --time-style=long-iso --git'
  alias ltr='eza -l --sort=modified --reverse'
  alias lst='eza -l --sort=modified'
  alias tree='eza --tree --group-directories-first --time-style=long-iso -I .git'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim > /dev/null 2>&1; then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

