# Git-scoped fzf helpers. Each guards with _fzf_in_git_repo (see fzf-core.zsh).

# fgb - switch to a branch (local or remote), most-recent first.
fgb() {
  _fzf_in_git_repo || return

  local branch
  branch=$(
    git branch --all --sort=-committerdate --format='%(refname:short)' \
      | grep -v '^origin/HEAD$' \
      | fzf --preview 'git log --oneline --graph --color=always {} -- 2>/dev/null | head -200'
  ) || return
  [[ -n $branch ]] && git switch "${branch#origin/}"
}

# fga - stage one or more changed files (multi-select).
fga() {
  _fzf_in_git_repo || return

  local files
  files=$(
    git status --short \
      | fzf --multi --preview 'git diff --color=always -- "$(cut -c4- <<< {})"' \
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
