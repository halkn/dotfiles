# ---------------------------------------------------------------------------
# zsh plugin manager
#
# To add a plugin:
#   1. Append "owner/repo" to _zsh_plugins
#   2. Append its entry file to _zsh_plugin_entries (fpath-only plugins skip step 2)
#   3. Run "zsh-plugin-install" to fetch any missing plugins
#
# To update all plugins:
#   zsh-plugin-update
# ---------------------------------------------------------------------------

_zsh_plugins=(
  zsh-users/zsh-autosuggestions
  zdharma-continuum/fast-syntax-highlighting # replaces zsh-syntax-highlighting
)

_zsh_plugin_entries=(
  zsh-autosuggestions/zsh-autosuggestions.zsh
  fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
)

zsh-plugin-install() {
  if ! command -v git >/dev/null 2>&1; then
    print "zsh: git is required to install plugins." >&2
    return 1
  fi

  local _p _d
  for _p in $_zsh_plugins; do
    _d=$ZPLUGINDIR/${_p#*/}
    if [[ ! -d $_d ]]; then
      print "installing: ${_p#*/}"
      git clone --depth 1 "https://github.com/$_p" "$_d" || return 1
    fi
  done
}

typeset -a _zsh_missing_plugins=()
for _p in $_zsh_plugins; do
  _d=$ZPLUGINDIR/${_p#*/}
  [[ -d $_d ]] || _zsh_missing_plugins+=("${_p#*/}")
done
unset _p _d

if ((${#_zsh_missing_plugins[@]} > 0)); then
  print "zsh: missing plugins: ${_zsh_missing_plugins[*]} (run: zsh-plugin-install)" >&2
fi
unset _zsh_missing_plugins

# Source plugins (order matters)
for _e in $_zsh_plugin_entries; do
  [[ -f $ZPLUGINDIR/$_e ]] && source $ZPLUGINDIR/$_e
done
unset _e

# Update all installed plugins
zsh-plugin-update() {
  if ! command -v git >/dev/null 2>&1; then
    print "zsh: git is required to update plugins." >&2
    return 1
  fi

  local _p _d
  for _p in $_zsh_plugins; do
    _d=$ZPLUGINDIR/${_p#*/}
    [[ -d $_d ]] && {
      print "updating: ${_p#*/}"
      git -C "$_d" pull --ff-only
    }
  done
}
