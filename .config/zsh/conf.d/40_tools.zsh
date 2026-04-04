# ── uv ───────────────────────────────────────────────
if command -v uv > /dev/null 2>&1; then
  _uv_comp=$ZCACHEDIR/completions/_uv
  _uv_bin=$(command -v uv)
  if [[ ! -f $_uv_comp || $_uv_bin -nt $_uv_comp ]]; then
    mkdir -p ${_uv_comp:h}
    uv generate-shell-completion zsh > $_uv_comp
  fi
  source $_uv_comp
  unset _uv_comp _uv_bin
fi

# ── deno ─────────────────────────────────────────────
if ! command -v deno > /dev/null 2>&1 && [[ -x $DENO_INSTALL/bin/deno ]]; then
  mkdir -p $XDG_BIN_HOME
  ln -sf $DENO_INSTALL/bin/deno $XDG_BIN_HOME/deno
fi

if command -v deno > /dev/null 2>&1; then
  _deno_comp=$ZCACHEDIR/completions/_deno
  _deno_bin=$(command -v deno)
  if [[ ! -f $_deno_comp || $_deno_bin -nt $_deno_comp ]]; then
    mkdir -p ${_deno_comp:h}
    deno completions zsh > $_deno_comp
  fi
  source $_deno_comp
  unset _deno_comp _deno_bin
fi

# ── lsd ──────────────────────────────────────────────
if command -v lsd > /dev/null 2>&1; then
  alias ls='lsd'
  alias ll='lsd -l'
  alias la='lsd -la'
  alias ltr='lsd -l --timesort --reverse'
  alias lst='lsd -l --timesort'
  alias tree='lsd --tree -I .git'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim > /dev/null 2>&1; then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

# ── tmux ─────────────────────────────────────────────
if command -v tmux > /dev/null 2>&1; then
  # ターミナル起動時に自動でtmuxを開始（既にtmux内でなければ）
  if [[ -z "$TMUX" ]]; then
    tmux attach-session 2>/dev/null || tmux new-session
  fi
fi

