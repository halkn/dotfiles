# ── prompt (Pure) ─────────────────────────────────────────────────────────────
# Auto-installed as a zsh plugin on first launch (no binary, no mise required).
# See: conf.d/30_plugins.zsh
if [[ -d "$ZPLUGINDIR/pure" ]]; then
  fpath=("$ZPLUGINDIR/pure" $fpath)
  autoload -U promptinit
  promptinit

  zstyle ':prompt:pure:path'            color 'blue'
  zstyle ':prompt:pure:prompt:success'  color 'magenta'   # ❯ purple on success
  zstyle ':prompt:pure:prompt:error'    color 'red'        # ❯ red on error
  zstyle ':prompt:pure:prompt:vicmd'    color 'green'      # ❮ green in vim normal mode
  zstyle ':prompt:pure:git:branch'      color 'bright-black'
  zstyle ':prompt:pure:git:dirty'       color '218'
  zstyle ':prompt:pure:execution_time'  color 'yellow'

  prompt pure
fi
