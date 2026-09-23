#!/bin/zsh
# herdr's worktree keys: `new` (alt+g), `pr` (alt+p), `rm` (alt+x) and `prune`
# (alt+c), each in a popup opened on the cwd of the pane it was called from.
#
# `wt` creates and removes the worktrees and prints their paths; this file only
# picks, confirms, and opens or closes the workspace sitting on a path. Only the
# chrome and the preview are shared, from lib/ui.zsh.
set -euo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/lib/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

# A popup closes as soon as its command ends, taking what was printed with it.
pause() {
  print -n 'press any key '
  read -rsk1 || true
}

whence _ui_require >/dev/null || {
  print -u2 "herdr-wt: $ui_lib not found"
  pause
  exit 1
}

need() {
  _ui_require "$1" herdr-wt || {
    pause
    return 1
  }
}

need wt || exit 1
need jq || exit 1

confirm() {
  print -n "$1 [y/N] "
  read -rq && {
    print
    return 0
  }
  print
  return 1
}

# `<resolved path>\t<workspace id>` for every open workspace on a checkout, read
# once so that a workspace can still be found after its worktree is gone.
typeset -A workspace_of
load_workspaces() {
  local out rows line
  out=$(herdr workspace list 2>/dev/null) || return 0
  rows=$(print -r -- "$out" | jq -r '
    .result.workspaces[]?
    | select(.worktree.checkout_path != null)
    | [.worktree.checkout_path, .workspace_id]
    | @tsv
  ' 2>/dev/null) || return 0
  for line in ${(f)rows}; do
    workspace_of[${${line%%$'\t'*}:A}]=${line#*$'\t'}
  done
}

open_worktree() {
  local dir=${1:A} ws
  load_workspaces
  ws=${workspace_of[$dir]-}
  if [[ -n $ws ]]; then
    herdr workspace focus "$ws" >/dev/null && return 0
  else
    herdr worktree open --path "$dir" --focus >/dev/null && return 0
  fi
  print -u2 "herdr-wt: could not open $dir"
  pause
  return 1
}

close_worktree() {
  local ws=${workspace_of[${1:A}]-}
  [[ -n $ws ]] || return 0
  herdr workspace close "$ws" >/dev/null 2>&1 || true
}

# An empty answer is a cancelled popup, not a failure.
cmd_new() {
  local branch='' dir
  read -r "branch?branch: " || return 0
  [[ -n $branch ]] || return 0
  dir=$(wt new "$branch") || {
    pause
    return 1
  }
  open_worktree "$dir"
}

cmd_pr() {
  local rows number dir
  need gh || return 1
  need fzf || return 1
  # Fetched before the picker opens rather than from inside it, so a gh failure
  # is reported instead of showing an empty list.
  rows=$(gh pr list --limit 100 \
    --json number,title,headRefName,author \
    --template '{{range .}}{{printf "#%-5v %-50.50v %v (@%v)\t%v\n" .number .title .headRefName .author.login .number}}{{end}}') || {
    pause
    return 1
  }
  [[ -n $rows ]] || {
    print 'no open pull requests'
    pause
    return 0
  }
  number=$(
    print -r -- "$rows" \
      | fzf "${_UI_FZF_CHROME[@]}" --border-label ' wt pr ' \
        --delimiter '\t' --with-nth 1 --accept-nth 2 \
        --prompt 'pr> ' \
        --preview 'gh pr view {2}'
  ) || return 0
  [[ -n $number ]] || return 0
  dir=$(wt pr "$number") || {
    pause
    return 1
  }
  open_worktree "$dir"
}

# wt refuses a worktree with local changes; seeing why and saying yes again is
# what `rm -f` is.
cmd_rm() {
  local root rows dir removed
  local -a targets
  local -i rc=0
  need fzf || return 1
  root=$(wt root)
  rows=$(wt list --full-path)
  [[ -n $rows ]] || {
    print 'no worktrees'
    pause
    return 0
  }
  targets=(${(f)"$(
    for dir in ${(f)rows}; do
    	printf '%s\t%s\n' "${dir#"$root"/}" "$dir"
    done | fzf "${_UI_FZF_CHROME[@]}" --border-label ' wt rm ' \
    	--multi --delimiter '\t' --with-nth 1 --accept-nth 2 \
    	--prompt 'remove> ' \
    	--header 'Tab: toggle / Enter: remove selected' \
    	--preview "source ${_UI_LIB}; _ui_git_preview {2}"
  )"}) || return 0
  ((${#targets} > 0)) || return 0

  print -rl -- "${targets[@]#"$root"/}"
  confirm 'remove these worktrees and their branches?' || return 0
  load_workspaces
  for dir in "${targets[@]}"; do
    if ! removed=$(wt rm "$dir"); then
      confirm "remove ${dir#"$root"/} anyway?" || {
        rc=1
        continue
      }
      removed=$(wt rm -f "$dir") || {
        rc=1
        continue
      }
    fi
    [[ -n $removed ]] && close_worktree "$removed"
  done
  pause
  return $rc
}

cmd_prune() {
  local candidates dir root
  local -a lines
  root=$(wt root)
  print 'looking for merged pull requests...'
  candidates=$(wt prune --dry-run) || {
    pause
    return 1
  }
  [[ -n $candidates ]] || {
    print 'nothing to prune'
    pause
    return 0
  }
  lines=(${(f)candidates})
  print -rl -- "${lines[@]#"$root"/}"
  confirm 'remove these worktrees and their branches?' || return 0
  load_workspaces
  for dir in ${(f)"$(wt prune)"}; do
    close_worktree "$dir"
  done
  pause
}

case ${1:-} in
  new)
    cmd_new
    ;;
  pr)
    cmd_pr
    ;;
  rm)
    cmd_rm
    ;;
  prune)
    cmd_prune
    ;;
  *)
    print -u2 'usage: herdr-wt.sh new|pr|rm|prune'
    exit 1
    ;;
esac
