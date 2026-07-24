# fzf setup and helpers. This file is sourced from .zshrc only when fzf and a TTY are available.

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
  command -v fd >/dev/null 2>&1 || {
    print 'fcd: fd is not installed' >&2
    return 1
  }
  local dir
  dir=$(fd --type d --hidden --exclude .git . "${1:-.}" | fzf --preview 'ls -la {}') || return
  [[ -n $dir ]] && cd -- "$dir"
}

# frm - fuzzy select files and remove them (multi-select, confirmation required).
frm() {
  command -v fd >/dev/null 2>&1 || {
    print 'frm: fd is not installed' >&2
    return 1
  }

  local -a files
  local f tmp
  # Run fzf in a foreground pipeline (not a process substitution): an
  # interactive fzf inside <(...) is not in the foreground process group, so it
  # blocks on /dev/tty (SIGTTIN) and frm hangs. Buffer NUL-delimited output to a
  # temp file to keep filenames with newlines safe before removing them.
  tmp=$(mktemp) || {
    print 'frm: failed to create temp file' >&2
    return 1
  }
  fd --type f --hidden --exclude .git --print0 \
    | fzf --multi --read0 --print0 --preview 'cat {}' >|"$tmp"
  while IFS= read -r -d '' f; do
    files+=("$f")
  done <"$tmp"
  rm -f -- "$tmp"
  [[ ${#files[@]} -eq 0 ]] && return

  print -r -- "${files[@]}"
  print -n 'remove these files? [y/N] '
  if read -r -q; then
    print
    rm -- "${files[@]}"
  else
    print
    return 1
  fi
}

# fgb - switch to a branch (local or remote), most-recent first.
fgb() {
  _fzf_in_git_repo || return

  local branch
  branch=$(
    git branch --all --sort=-committerdate --format='%(refname:short)' \
      | grep -v '^origin/HEAD$' \
      | fzf --preview 'git log --oneline --graph --color=always {} -- 2>/dev/null | head -200'
  ) || return
  [[ -n $branch ]] || return
  if [[ $branch == */* ]]; then
    git switch --track "$branch"
  else
    git switch "$branch"
  fi
}

# fga - stage one or more changed files (multi-select).
fga() {
  _fzf_in_git_repo || return

  local files
  files=$(
    git status --short \
      | fzf --multi --preview 'git diff --color=always -- "$(printf "%s" "{}" | cut -c4-)"' \
      | cut -c4-
  ) || return
  [[ -z $files ]] && return

  print -r -- "$files" | while IFS= read -r f; do git add -- "$f"; done
  git status --short
}

# fgl - browse the commit log; Enter opens the full commit in the pager.
fgl() {
  _fzf_in_git_repo || return

  git log --color=always --format='%C(auto)%h %s %C(dim)%cr' \
    | fzf --ansi --no-sort \
      --preview 'git show --color=always {1}' \
      --bind 'enter:execute(git show --color=always {1} | less -R)'
}

# fgw - cd into a git worktree.
fgw() {
  _fzf_in_git_repo || return

  local dir
  dir=$(
    git worktree list \
      | fzf --preview 'eza --tree --level=1 --icons {1} 2>/dev/null || ls -la {1}' \
      | awk '{print $1}'
  ) || return
  [[ -n $dir ]] && cd -- "$dir"
}

# repo            : pick a ghq-managed repository with fzf and cd into it
# repo get <repo> : clone with ghq and cd into it (owner/repo or URL)
repo() {
  command -v ghq >/dev/null 2>&1 || {
    print 'repo: ghq is not installed or not in PATH' >&2
    return 1
  }

  local dir
  if [[ "$1" == get ]]; then
    shift
    (($#)) || {
      print 'usage: repo get <owner/repo|url>' >&2
      return 1
    }
    ghq get "$@" || return
    # --exact resolves owner/repo to its full path; URLs may not match, so cd is best-effort.
    dir=$(ghq list --full-path --exact "${@[-1]}" 2>/dev/null | head -1)
    [[ -n "$dir" ]] && cd -- "$dir" && la
    return
  fi

  dir=$(ghq list --full-path | fzf \
    --query="$*" \
    --preview 'eza --tree --level=1 --icons {} 2>/dev/null || ls -la {}') || return
  [[ -n "$dir" ]] && cd -- "$dir" && la
}
