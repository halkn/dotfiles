# ── tmux ─────────────────────────────────────────────
export ZSH_TMUX_AUTO_START=${ZSH_TMUX_AUTO_START:-1}
export ZSH_TMUX_SESSION_NAME=${ZSH_TMUX_SESSION_NAME:-main}

if command -v tmux >/dev/null 2>&1 &&
  [[ -o interactive ]] &&
  [[ -z $TMUX ]] &&
  [[ -t 0 ]] &&
  [[ -t 1 ]] &&
  [[ $ZSH_TMUX_AUTO_START == 1 ]]; then
  exec tmux new-session -A -s "$ZSH_TMUX_SESSION_NAME"
fi
