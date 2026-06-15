# Shared fzf setup and helpers for the lib/fzf-*.zsh modules.
# Sourced first by the loader in .zshrc (glob order: core < file < git).

export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border
  --info=inline
  --preview-window=right:60%:wrap
  --bind ctrl-u:preview-page-up,ctrl-d:preview-page-down
  --bind ctrl-/:toggle-preview
"

# Provides the built-in widgets: Ctrl-R (history), Alt-C (cd), Ctrl-T (paste).
source <(fzf --zsh)

# Guard used by git-scoped helpers: bail out cleanly outside a work tree.
_fzf_in_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'fzf: not inside a git repository' >&2
    return 1
  }
}
