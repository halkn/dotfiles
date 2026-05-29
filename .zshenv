# Bootstrap stub: point zsh at the XDG config dir, then hand off to it.
# Everything else lives in $ZDOTDIR (.config/zsh).
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
