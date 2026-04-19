# ── uv ───────────────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  _uv_comp=$ZCACHEDIR/completions/_uv
  _uv_bin=$(command -v uv)
  if [[ ! -f $_uv_comp || $_uv_bin -nt $_uv_comp ]]; then
    mkdir -p ${_uv_comp:h}
    uv generate-shell-completion zsh >$_uv_comp
  fi
  source $_uv_comp
  unset _uv_comp _uv_bin
fi

# ── lsd ──────────────────────────────────────────────
if command -v lsd >/dev/null 2>&1; then
  # Override the default ls aliases only when lsd is available.
  alias ls='lsd'
  alias ll='lsd -l'
  alias la='lsd -la'
  alias ltr='lsd -l --timesort --reverse'
  alias lst='lsd -l --timesort'
  alias tree='lsd --tree -I .git'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
  alias v='nvim'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi
