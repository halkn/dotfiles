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

zstyle ':prompt:pure:path'            color 'blue'
zstyle ':prompt:pure:prompt:success'  color 'magenta'
zstyle ':prompt:pure:prompt:error'    color 'red'
zstyle ':prompt:pure:prompt:vicmd'    color 'green'
zstyle ':prompt:pure:git:branch'      color 'bright-black'
zstyle ':prompt:pure:git:dirty'       color '218'
zstyle ':prompt:pure:execution_time'  color 'yellow'

prompt pure
unset _pure_dir
