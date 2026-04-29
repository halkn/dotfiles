if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

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
  fcd() {
    local dir preview_cmd

    if command -v lsd >/dev/null 2>&1; then
      preview_cmd='lsd -lah {} && echo && lsd --tree --depth 2 {}'
    else
      preview_cmd='ls -lah {}'
    fi

    dir=$(fd --type d --hidden --exclude .git \
      | fzf \
        --preview "$preview_cmd" \
        --preview-window=right:60% \
        --bind "ctrl-/:toggle-preview")
    [[ -n "$dir" ]] && cd -- "$dir"
  }
fi

# frm - interactive remove files
frm() {
  local target preview_cmd reply
  local target_path
  local sorted_dirs
  local -a targets files dirs

  if ! command -v fzf >/dev/null 2>&1; then
    echo 'frm: fzf is not installed or not in PATH' >&2
    return 1
  fi

  if command -v bat >/dev/null 2>&1 && command -v lsd >/dev/null 2>&1; then
    preview_cmd='if [[ -d {} ]]; then lsd -lah {} && echo && lsd --tree --depth 2 {}; else bat --style=plain --color=always --line-range=:200 {}; fi'
  elif command -v bat >/dev/null 2>&1; then
    preview_cmd='if [[ -d {} ]]; then ls -lah {}; else bat --style=plain --color=always --line-range=:200 {}; fi'
  elif command -v lsd >/dev/null 2>&1; then
    preview_cmd='if [[ -d {} ]]; then lsd -lah {} && echo && lsd --tree --depth 2 {}; else sed -n "1,200p" {}; fi'
  else
    preview_cmd='if [[ -d {} ]]; then ls -lah {}; else sed -n "1,200p" {}; fi'
  fi

  if command -v fd >/dev/null 2>&1; then
    target=$(fd --hidden --strip-cwd-prefix --exclude .git \
      | fzf \
        --height 80% \
        --layout reverse \
        --border \
        --multi \
        --header 'TAB: multi-select  ENTER: mark for delete  CTRL-/: toggle preview' \
        --preview "$preview_cmd" \
        --preview-window=right:60% \
        --bind 'ctrl-/:toggle-preview')
  else
    target=$(find . -path ./.git -prune -o -mindepth 1 -print \
      | sed 's#^\./##' \
      | fzf \
        --height 80% \
        --layout reverse \
        --border \
        --multi \
        --header 'TAB: multi-select  ENTER: mark for delete  CTRL-/: toggle preview' \
        --preview "$preview_cmd" \
        --preview-window=right:60% \
        --bind 'ctrl-/:toggle-preview')
  fi
  [[ -z "$target" ]] && return

  targets=("${(@f)target}")

  print 'remove targets:'
  printf '  %s\n' "${targets[@]}"
  read "reply?delete? [y/N]: "
  [[ "$reply" =~ ^[Yy]$ ]] || return

  for target_path in "${targets[@]}"; do
    if [[ -d "$target_path" ]]; then
      dirs+=("$target_path")
    else
      files+=("$target_path")
    fi
  done

  [[ ${#files[@]} -gt 0 ]] && rm -- "${files[@]}"
  if [[ ${#dirs[@]} -gt 0 ]]; then
    sorted_dirs=$(printf '%s\n' "${dirs[@]}" | awk -F/ '{ print NF "\t" $0 }' | sort -rn | cut -f2-)
    for target_path in ${(f)sorted_dirs}; do
      [[ -e "$target_path" ]] || continue
      rm -r -- "$target_path"
    done
  fi
}

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
  branch=$(git branch -a --color=always \
    | grep -v HEAD \
    | fzf "${_fzf_git_opts[@]}" \
      --no-multi \
      --ansi \
      --header 'ENTER: checkout  CTRL-_: toggle preview' \
      --preview 'git log --oneline --graph --color=always $(echo {} | sed "s/^[* ]*//" | sed "s/\s.*//" | sed "s|remotes/||") | head -50' \
    | sed 's/^[* ]*//' | sed 's/\s.*//' | sed 's|remotes/||')
  [[ -n "$branch" ]] && git switch "$branch"
}

# ── stage/unstage ───────────────────────────────────
fga() {
  local files
  files=$(git -c color.status=always status --short \
    | fzf "${_fzf_git_opts[@]}" \
      --ansi \
      --nth 2.. \
      --header 'TAB: multi-select  ENTER: git add  CTRL-U: unstage  CTRL-_: toggle preview' \
      --preview 'git diff --color=always -- {2} | delta --paging=never --width "${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}"' \
      --bind 'ctrl-u:execute-silent(git restore --staged {2})+reload(git -c color.status=always status --short)' \
      --bind 'enter:execute-silent(git add {+2})+reload(git -c color.status=always status --short)' \
    | awk '{print $2}')
  [[ -n "$files" ]] && git status --short
}

# ── commit log ──────────────────────────────────────
fgl() {
  local commit
  commit=$(git log --oneline --color=always --decorate --all \
    | fzf "${_fzf_git_opts[@]}" \
      --no-multi \
      --ansi \
      --header 'ENTER: show stat  CTRL-V: full diff  CTRL-S: stat  CTRL-_: toggle preview' \
      --preview 'git show --color=always --stat {1} | delta --paging=never --width "${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}"' \
      --bind 'ctrl-v:change-preview(git show --color=always {1} | delta --paging=never --width "${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}")' \
      --bind 'ctrl-s:change-preview(git show --color=always --stat {1} | delta --paging=never --width "${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}}")' \
    | awk '{print $1}')
  [[ -n "$commit" ]] && git show --stat "$commit"
}

# ── worktree cd ─────────────────────────────────────
fgw() {
  local worktree
  worktree=$(git worktree list \
    | fzf "${_fzf_git_opts[@]}" \
      --no-multi \
      --header 'ENTER: cd to worktree  CTRL-_: toggle preview' \
      --preview 'eza --tree --color=always --level 2 {1}' \
    | awk '{print $1}')
  [[ -n "$worktree" ]] && cd "$worktree"
}
