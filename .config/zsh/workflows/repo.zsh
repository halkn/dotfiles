# repo - acquiring a repository. Where a clone lands, how a URL maps onto that
# layout and which repositories exist are all `trepo`; what is left here is the
# cd that follows, which is the one thing a subprocess cannot do for the shell.
# Navigating to a repository that is already local is nav.zsh's picker, which
# is also where the `repo` command itself lives.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-picker.sh, so
# it must only define functions and must not touch the current shell state. For
# the same reason it never returns early on a missing dependency: the picker
# would lose these silently.

_repo_root() {
  local root=${REPO_ROOT:-$HOME/repos}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

_repo_trepo_available() {
  command -v trepo >/dev/null 2>&1 || {
    print "${1:-repo}: trepo is not installed" >&2
    return 1
  }
}

# Clone into the trepo root and cd into it. `owner/repo` or any clone URL.
# `trepo get` is idempotent and prints the checkout path on stdout either way,
# so asking for a repository that is already there is a request to go to it.
_repo_get() {
  local dir
  (($# == 1)) || {
    print 'usage: repo get <owner/repo|url>' >&2
    return 1
  }
  _repo_trepo_available repo || return 1
  dir=$(trepo get "$1") || return 1
  [[ -n $dir ]] || return 1
  cd -- "$dir"
}

# dot - jump to this dotfiles checkout. Spelled out rather than resolved through
# `trepo path`, which enumerates every repository and runs git in each one: this
# is a fixed location, and paying for a full listing to reach it would make the
# shortcut slower than the picker it exists to skip.
dot() {
  cd -- "$(_repo_root)/github.com/halkn/dotfiles"
}
