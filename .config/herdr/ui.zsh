# ui - what the scripts in .config/herdr/ share: the dependency check, the popup
# prompts, the chrome of a full-screen picker, the preview of a directory, and
# the rows of the open workspaces.
#
# It sources nothing itself, which is what lets an fzf preview - a fresh shell -
# source it alone.

_UI_LIB=${${(%):-%x}:A}

# The command name is passed in so the message names what the user typed, not
# the file the check lives in.
_ui_require() {
  local tool=${1:-} cmd=${2:-}
  command -v "$tool" >/dev/null 2>&1 || {
    print "$cmd: $tool is not installed" >&2
    return 1
  }
}

# A popup closes as soon as its command ends, taking what was printed with it.
_ui_pause() {
  print -n 'press any key '
  read -rsk1 || true
}

_ui_die() {
  local cmd=${1:-} msg=${2:-}
  [[ -z $msg ]] || print -u2 "$cmd: $msg"
  _ui_pause
  exit 1
}

_ui_confirm() {
  print -n "$1 [y/N] "
  read -rq && {
    print
    return 0
  }
  print
  return 1
}

# Not FZF_DEFAULT_OPTS, which is sized for a completion popped up under the
# cursor: these pickers are the window while they are open, and the herdr popup
# they also run in is too narrow for a preview beside the list.
#
# The border label is left to the caller, which names it after the command the
# picker belongs to rather than after the file the chrome lives in.
typeset -ga _UI_FZF_CHROME=(
  --height=100%
  --style=full
  --preview-window 'down:60%:wrap'
)

# Every row a picker offers is a directory, so one preview covers all of them.
# A directory that is not a checkout still gets a listing.
_ui_git_preview() {
  local dir=${1:-}
  [[ -n $dir ]] || return 0
  dir=${dir:A}
  print -r -- "$dir"
  [[ -d $dir ]] || {
    print 'missing'
    return 0
  }
  print
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$dir" -c color.ui=always status --short --branch 2>/dev/null || true
    print
    git -C "$dir" log --oneline --decorate --color=always -15 2>/dev/null || true
  else
    ls -A -- "$dir" 2>/dev/null | head -30 || true
  fi
  # A directory git refuses is still a preview, not a failure.
  return 0
}

# The branch a checkout is on, into REPLY: the name under refs/heads/, or the
# short hash of a detached HEAD. Read off the HEAD file because it runs once per
# row, where git is kept to the preview. A worktree's .git is a file naming its
# gitdir, relative to the worktree when not absolute.
_ui_branch() {
  local dir=$1 gitdir=$1/.git head=
  REPLY=
  if [[ -f $gitdir ]]; then
    read -r head <"$gitdir" || [[ -n $head ]] || return 1
    gitdir=${head#gitdir: }
    [[ $gitdir == /* ]] || gitdir=$dir/$gitdir
    head=
  fi
  [[ -r $gitdir/HEAD ]] || return 1
  read -r head <"$gitdir/HEAD" || [[ -n $head ]] || return 1
  if [[ $head == 'ref: refs/heads/'* ]]; then
    REPLY=${head#ref: refs/heads/}
  else
    REPLY=${head[1,7]}
  fi
}

# `<display>\t<workspace id>\t<path>` per open workspace. herdr 0.9.1 gives a
# path only to a workspace on a git checkout; the others show their label alone.
# A checkout under either root reads as the last two segments `wt` names its
# worktrees by - <owner>/<repo>, or <project>/<repo> on Azure DevOps - and its
# branch, so a clone (●) and its worktrees
# (├ └) line up under one name and sort together. Anything else keeps its full
# path and follows in herdr's order.
_ui_workspaces() {
  local out rows row dir wt_root repo_root key next kind
  local -a f keys sorted nums ids dirs repos marks branches
  local -i i n width=0
  out=$(herdr workspace list) || return 1
  rows=$(print -r -- "$out" | jq -r '
    .result.workspaces[]?
    | [.workspace_id, (.number | tostring), .label, (.worktree.checkout_path // "")]
    | @tsv
  ') || return 1
  wt_root=$(wt root 2>/dev/null) || wt_root=
  repo_root=$(repo root 2>/dev/null) || repo_root=
  for row in ${(f)rows}; do
    f=("${(@ps:\t:)row}")
    ((n += 1))
    ids[n]=$f[1] nums[n]=$f[2] dir=${f[4]-} dirs[n]=$dir
    if [[ -n $wt_root && $dir == "$wt_root"/*/*/* ]]; then
      repos[n]=${${dir#"$wt_root"/}%/*} marks[n]=├ kind=2
      _ui_branch "$dir" || REPLY=${dir:t}
    elif [[ -n $repo_root && $dir == "$repo_root"/*/*/* ]]; then
      repos[n]=${${dir:h}:t}/${dir:t} marks[n]=● kind=1
      _ui_branch "$dir" || true
    else
      repos[n]=${${dir/#$HOME/'~'}:-${f[3]-}} marks[n]=
      REPLY=
      keys+=("1"$'\x1'"${(l:8::0:)f[2]}"$'\x1'"$n")
      continue
    fi
    branches[n]=$REPLY
    ((${#repos[n]} <= width)) || width=${#repos[n]}
    keys+=("0"$'\x1'"${repos[n]}"$'\x1'"$kind"$'\x1'"$REPLY"$'\x1'"$n")
  done
  sorted=("${(@o)keys}")
  for ((i = 1; i <= ${#sorted}; i++)); do
    n=${sorted[i]##*$'\x1'}
    if [[ -z ${marks[n]} ]]; then
      printf '[%s] %s\t%s\t%s\n' "$nums[n]" "$repos[n]" "$ids[n]" "$dirs[n]"
      continue
    fi
    # The last worktree of a repository closes its branch of the tree.
    next=${sorted[i+1]-}
    key=${${next#0$'\x1'}%%$'\x1'*}
    [[ ${marks[n]} != ├ || ($next == 0$'\x1'* && $key == "${repos[n]}") ]] || marks[n]=└
    printf '[%s] %-*s %s %s\t%s\t%s\n' "$nums[n]" "$width" "$repos[n]" "$marks[n]" \
      "$branches[n]" "$ids[n]" "$dirs[n]"
  done
}

# `<workspace id>\t<path>` of the workspace the popup was opened over. Read off
# `focused` because herdr 0.9.1 has no cwd for a workspace off a checkout.
_ui_focused_workspace() {
  local out
  out=$(herdr workspace list) || return 1
  print -r -- "$out" | jq -r '
    first(.result.workspaces[]? | select(.focused))
    | [.workspace_id, (.worktree.checkout_path // "")]
    | @tsv
  '
}
