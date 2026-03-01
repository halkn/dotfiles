command -v fzf &>/dev/null || return

source <(fzf --zsh)

# ── ghq ─────────────────────────────────────────────
if command -v ghq > /dev/null 2>&1; then
  ghq-cd () {
    local repo=$(ghq list | fzf)
    if [ -n "$repo" ]; then
      repo=$(ghq list --full-path --exact $repo)
      cd ${repo} && la
    fi
  }
  alias dev='ghq-cd'
fi

# ── util ────────────────────────────────────────────
# fh - repeat history
fh() {
  print -z $(fc -l 1 | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# fcd - interactive change directory
if command -v fd > /dev/null 2>&1; then
  alias fcd='cd $(fd --type d --hidden | fzf \
    --preview "eza -lah --color=always --icons {} && echo && eza --tree --level=2 --color=always --icons {}" \
    --preview-window=right:60% \
    --bind "ctrl-/:toggle-preview")'
fi

# ── git ─────────────────────────────────────────────
command -v delta &>/dev/null || return

# gb - interactive git switch
fzf-git-branch() {
  local branches branch

  branches=$(git branch --all --color=always --format='%(refname:short)|%(authorname)|%(committerdate:relative)' | grep -v HEAD) &&
  branch=$(echo "$branches" |
    column -t -s '|' |
    fzf --ansi \
      --preview-window=right:70% \
      --preview '
        branch=$(echo {} | awk "{print \$1}" | sed "s#remotes/[^/]*/##")
        echo "=== Branch: $branch ==="
        echo
        git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $branch | head -50
        echo
        echo "=== Recent commits ==="
        git log --color=always --pretty=format:"%C(yellow)%h %C(blue)%ad %C(green)%an%C(reset)%n%s%n" --date=short $branch | head -20
      ' \
      --bind "ctrl-/:toggle-preview" \
      --bind "ctrl-u:preview-page-up,ctrl-d:preview-page-down" \
      --bind "ctrl-o:execute(git log --oneline --graph --color=always {1} | delta)" \
      --header "Enter: checkout / Ctrl-/: toggle preview / Ctrl-O: full log") &&

  branch=$(echo "$branch" | awk '{print $1}' | sed "s#remotes/[^/]*/##")

  if [ -n "$branch" ]; then
    git switch "$branch"
  fi
}
alias gb='fzf-git-branch'

