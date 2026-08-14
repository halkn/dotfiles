# git - interactive helpers over the current repository: branches, staging and
# the commit log. Worktrees live in workflows/worktree.zsh as `wt`.
#
# Functions are always defined; each entry point checks its own dependencies, so
# a machine without fzf reports what is missing instead of `command not found`.

# Both guards take the calling function's name so the message names the command
# the user actually typed.
_git_fzf_available() {
  command -v fzf >/dev/null 2>&1 || {
    print "$1: fzf is not installed" >&2
    return 1
  }
}

_git_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print "$1: not inside a git repository" >&2
    return 1
  }
}

# fgb - switch to a branch (local or remote), most-recent first.
fgb() {
  _git_fzf_available fgb || return 1
  _git_in_repo fgb || return 1

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
  _git_fzf_available fga || return 1
  _git_in_repo fga || return 1

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
  _git_fzf_available fgl || return 1
  _git_in_repo fgl || return 1

  git log --color=always --format='%C(auto)%h %s %C(dim)%cr' \
    | fzf --ansi --no-sort \
      --preview 'git show --color=always {1}' \
      --bind 'enter:execute(git show --color=always {1} | less -R)'
}
