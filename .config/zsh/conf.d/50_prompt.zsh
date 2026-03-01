# ── prompt (Pure) ─────────────────────────────────────────────────────────────
_pure_dir="$ZPLUGINDIR/pure"

# Auto-install on first launch
if [[ ! -d "$_pure_dir" ]]; then
  print "zsh: installing pure..."
  git clone --depth 1 "https://github.com/sindresorhus/pure" "$_pure_dir"
fi

fpath=("$_pure_dir" $fpath)
autoload -U promptinit
promptinit

# Colors (defaults omitted)
zstyle ':prompt:pure:path'        color 'blue'
zstyle ':prompt:pure:git:branch'  color 'bright-black'
zstyle ':prompt:pure:git:dirty'   color '218'
zstyle ':prompt:pure:virtualenv'  color 'cyan'   # uv venv / venv activate

# Behavior
PURE_CMD_MAX_EXEC_TIME=3  # show execution time after 3s (default: 5)

prompt pure
unset _pure_dir
