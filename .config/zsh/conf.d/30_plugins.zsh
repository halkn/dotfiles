# ---------------------------------------------------------------------------
# zsh plugin manager
#
# To add a plugin:
#   1. Append "owner/repo" to _zsh_plugins
#   2. Append its entry file to _zsh_plugin_entries (fpath-only plugins skip step 2)
#   3. Reopen your shell — missing plugins are auto-installed on launch
#
# To update all plugins:
#   zsh-plugin-update
# ---------------------------------------------------------------------------

_zsh_plugins=(
  zsh-users/zsh-autosuggestions
  zdharma-continuum/fast-syntax-highlighting  # replaces zsh-syntax-highlighting
)

_zsh_plugin_entries=(
  zsh-autosuggestions/zsh-autosuggestions.zsh
  fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
)

# Auto-install missing plugins on first launch
for _p in $_zsh_plugins; do
  _d=$ZPLUGINDIR/${_p#*/}
  if [[ ! -d $_d ]]; then
    print "zsh: installing plugin ${_p#*/}..."
    git clone --depth 1 "https://github.com/$_p" "$_d"
  fi
done
unset _p _d

# Source plugins (order matters)
for _e in $_zsh_plugin_entries; do
  [[ -f $ZPLUGINDIR/$_e ]] && source $ZPLUGINDIR/$_e
done
unset _e

# Update all installed plugins
zsh-plugin-update() {
  for _p in $_zsh_plugins; do
    local _d=$ZPLUGINDIR/${_p#*/}
    [[ -d $_d ]] && { print "updating: ${_p#*/}"; git -C "$_d" pull --ff-only }
  done
}
