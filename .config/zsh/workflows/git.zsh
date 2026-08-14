# git - interactive helpers over the current repository. Browsing the log and
# staging files are the `git-log` and `git-stage` tv channels; worktrees live in
# workflows/worktree.zsh as `wt`.
#
# Functions are always defined; each entry point checks its own dependencies, so
# a machine without tv reports what is missing instead of `command not found`.

# Both guards take the calling function's name so the message names the command
# the user actually typed.
_git_tv_available() {
  command -v tv >/dev/null 2>&1 || {
    print "$1: tv is not installed" >&2
    return 1
  }
}

_git_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print "$1: not inside a git repository" >&2
    return 1
  }
}

# fgb - switch to a branch (local or remote), most-recent first. The built-in
# git-branch channel checks the branch out instead, which detaches HEAD on a
# remote one.
fgb() {
  _git_tv_available fgb || return 1
  _git_in_repo fgb || return 1

  local branch
  branch=$(
    tv --input-prompt 'branch> ' \
      --source-command "git branch --all --sort=-committerdate --format='%(refname:short)' | grep -v '^origin/HEAD$'" \
      --preview-command 'git log --oneline --graph --color=always {} -- 2>/dev/null | head -200'
  ) || return
  [[ -n $branch ]] || return
  if [[ $branch == */* ]]; then
    git switch --track "$branch"
  else
    git switch "$branch"
  fi
}
