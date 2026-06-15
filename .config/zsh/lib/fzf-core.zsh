# Shared fzf setup and helpers for the lib/fzf-*.zsh modules.
# Sourced explicitly before the glob loop in .zshrc so other modules can depend on it.
[[ -t 0 ]] || return

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

# fh - select a history entry and place it on the command-line buffer for editing.
fh() {
  local cmd
  cmd=$(fc -l 1 | fzf --tac --no-sort | sed 's/^ *[0-9]* *//') || return
  [[ -n $cmd ]] && print -z -- "$cmd"
}

# fcd - interactively cd into a directory under the given root (default: .).
fcd() {
  command -v fd >/dev/null 2>&1 || { print 'fcd: fd is not installed' >&2; return 1; }
  local dir
  dir=$(fd --type d --hidden --exclude .git . "${1:-.}" | fzf --preview 'ls -la {}') || return
  [[ -n $dir ]] && cd -- "$dir"
}
