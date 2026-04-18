command -v fzf &>/dev/null || return

source <(fzf --zsh)

# ── util ────────────────────────────────────────────
# fh - repeat history
fh() {
  print -z $(fc -l 1 | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# d - change directory from recent directory history
d() {
  local dir name suffix expanded_dir
  dir=$(cdr -l | sed '1d' | awk '{$1=""; sub(/^ /, ""); print}' | fzf --header 'ENTER: cd to recent dir')
  [[ -z "$dir" ]] && return

  case "$dir" in
    '~')
      expanded_dir=$HOME
      ;;
    '~/'*)
      expanded_dir=$HOME/${dir#~/}
      ;;
    '~'*)
      name=${dir#\~}
      name=${name%%/*}
      suffix=${dir#\~$name}
      expanded_dir=${nameddirs[$name]}$suffix
      ;;
    *)
      expanded_dir=$dir
      ;;
  esac

  [[ -n "$expanded_dir" ]] && cd -- "$expanded_dir"
}

# fcd - interactive change directory
if command -v fd >/dev/null 2>&1; then
  alias fcd='cd $(fd --type d --hidden --exclude .git | fzf \
    --preview "eza -lah --color=always --icons {} && echo && eza --tree --level=2 --color=always --icons {}" \
    --preview-window=right:60% \
    --bind "ctrl-/:toggle-preview")'
fi

# ── git ─────────────────────────────────────────────
# ── opts ────────────────────────────────────────────
_fzf_git_opts=(
  --height 80%
  --layout reverse
  --border
  --multi
  --bind 'ctrl-_:change-preview-window(down,50%|hidden|)'
  --color header:italic
)

# ── switch branch ───────────────────────────────────
fgb() {
  local branch
  branch=$(git branch -a --color=always |
    grep -v HEAD |
    fzf "${_fzf_git_opts[@]}" \
      --no-multi \
      --ansi \
      --header 'ENTER: checkout  CTRL-_: toggle preview' \
      --preview 'git log --oneline --graph --color=always $(echo {} | sed "s/^[* ]*//" | sed "s/\s.*//" | sed "s|remotes/||") | head -50' |
    sed 's/^[* ]*//' | sed 's/\s.*//' | sed 's|remotes/||')
  [[ -n "$branch" ]] && git switch "$branch"
}

# ── stage/unstage ───────────────────────────────────
fga() {
  local files
  files=$(git -c color.status=always status --short |
    fzf "${_fzf_git_opts[@]}" \
      --ansi \
      --nth 2.. \
      --header 'TAB: multi-select  ENTER: git add  CTRL-U: unstage  CTRL-_: toggle preview' \
      --preview 'git diff --color=always -- {2} | delta' \
      --bind 'ctrl-u:execute-silent(git restore --staged {2})+reload(git -c color.status=always status --short)' \
      --bind 'enter:execute-silent(git add {+2})+reload(git -c color.status=always status --short)' |
    awk '{print $2}')
  [[ -n "$files" ]] && git status --short
}

# ── commit log ──────────────────────────────────────
fgl() {
  local commit
  commit=$(git log --oneline --color=always --decorate --all |
    fzf "${_fzf_git_opts[@]}" \
      --no-multi \
      --ansi \
      --header 'ENTER: show stat  CTRL-V: full diff  CTRL-S: stat  CTRL-_: toggle preview' \
      --preview 'git show --color=always --stat {1} | delta' \
      --bind 'ctrl-v:change-preview(git show --color=always {1} | delta)' \
      --bind 'ctrl-s:change-preview(git show --color=always --stat {1} | delta)' |
    awk '{print $1}')
  [[ -n "$commit" ]] && git show --stat "$commit"
}

# ── worktree cd ─────────────────────────────────────
fgw() {
  local worktree
  worktree=$(git worktree list |
    fzf "${_fzf_git_opts[@]}" \
      --no-multi \
      --header 'ENTER: cd to worktree  CTRL-_: toggle preview' \
      --preview 'eza --tree --color=always --level 2 {1}' |
    awk '{print $1}')
  [[ -n "$worktree" ]] && cd "$worktree"
}
