# ── prompt ───────────────────────────────────────────────────────────────────
#
# Alternatives comparison (in order of "no binary + speed" priority):
#
#   Pure          ✅ no binary  ✅ async git  ✅ simple  ← current choice
#   Spaceship     ✅ no binary  △ slower      ✅ feature-rich
#   Powerlevel10k ❌ has binary ✅ fastest     △ complex config
#   Starship      ❌ Rust binary △ blocking    △ cross-shell (fallback)
#
# To switch back to Starship: comment out the pure block below.
# To try Spaceship: replace pure with spaceship-prompt/spaceship-prompt
#   and change the fpath/promptinit lines accordingly.
# ─────────────────────────────────────────────────────────────────────────────

# ── Pure ──────────────────────────────────────────────────────────────────────
if [[ -d "$ZPLUGINDIR/pure" ]]; then
  fpath=("$ZPLUGINDIR/pure" $fpath)
  autoload -U promptinit
  promptinit

  # Match current Starship color scheme
  zstyle ':prompt:pure:path'            color 'blue'
  zstyle ':prompt:pure:prompt:success'  color 'magenta'   # ❯ purple on success
  zstyle ':prompt:pure:prompt:error'    color 'red'        # ❯ red on error
  zstyle ':prompt:pure:prompt:vicmd'    color 'green'      # ❮ green in vim normal mode
  zstyle ':prompt:pure:git:branch'      color 'bright-black'
  zstyle ':prompt:pure:git:dirty'       color '218'
  zstyle ':prompt:pure:execution_time'  color 'yellow'

  prompt pure

# ── Starship (fallback if Pure is not installed) ───────────────────────────────
elif command -v starship > /dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi
