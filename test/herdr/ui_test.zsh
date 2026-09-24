#!/usr/bin/env zsh
# ui.zsh: preview failures must preserve output and return successfully, and
# workspace rows read off `herdr workspace list`.
set -uo pipefail
typeset -i failures=0
ui_lib=${0:A:h}/../../.config/herdr/ui.zsh

for scenario in status log directory; do
  out=$(zsh -df -c '
    set -uo pipefail
    source "$1"
    scenario=$2
    git() {
      case $* in
        *rev-parse*) [[ $scenario != directory ]] ;;
        *status*)
          if [[ $scenario == status ]]; then return 1; fi
          print status-output
          ;;
        *log*)
          if [[ $scenario == log ]]; then return 1; fi
          print log-output
          ;;
      esac
    }
    ls() { print directory-output; return 1; }
    _ui_git_preview .
    print survived
  ' -- "$ui_lib" "$scenario")
  rc=$?
  case $scenario in
    status)
      want=log-output
      ;;
    log)
      want=status-output
      ;;
    directory)
      want=directory-output
      ;;
  esac
  if ((rc != 0)) || [[ $out != *$want* || $out != *survived ]]; then
    print -u2 "FAIL preview $scenario: rc=$rc, output=$out"
    ((failures++))
  fi
done

# Workspace rows: herdr, wt and repo are stubbed, jq is the real one. Only a
# workspace on a git checkout carries a path (herdr 0.9.1). The branch is read
# off HEAD files laid out under a temporary root, as git would leave them.
ws_root=$(mktemp -d "${TMPDIR:-/tmp}/ui_test.XXXXXX")
trap 'rm -rf -- "$ws_root"' EXIT
() {
  local r=$ws_root/r w=$ws_root/w
  mkdir -p $r/github.com/me/dotfiles/.git/worktrees/feat-x $r/github.com/me/app/.git \
    $w/me/dotfiles/feat-x $w/me/dotfiles/bugfix $w/other/tool/dev/.gitdir \
    $r/dev.azure.com/org/proj/az/.git $w/proj/az/topic
  print 'ref: refs/heads/main' >$r/github.com/me/dotfiles/.git/HEAD
  print 'abcdef1234567890' >$r/github.com/me/app/.git/HEAD
  print "gitdir: $r/github.com/me/dotfiles/.git/worktrees/feat-x" >$w/me/dotfiles/feat-x/.git
  print 'ref: refs/heads/feat/x' >$r/github.com/me/dotfiles/.git/worktrees/feat-x/HEAD
  print 'gitdir: .gitdir' >$w/other/tool/dev/.git
  print 'ref: refs/heads/dev' >$w/other/tool/dev/.gitdir/HEAD
  print 'ref: refs/heads/main' >$r/dev.azure.com/org/proj/az/.git/HEAD
}

run_ws() {
  zsh -df -c '
    set -uo pipefail
    source "$1"
    root=$2
    herdr_fails=$3
    ws() {
      print -r -- "{\"workspace_id\":\"w$1\",\"number\":$1,\"label\":\"$2\",\"focused\":$3${4:+,\"worktree\":{\"checkout_path\":\"$4\"\}}}"
    }
    herdr() {
      [[ $herdr_fails == 0 ]] || { print -u2 herdr-down; return 1; }
      print -r -- "{\"result\":{\"workspaces\":[
        $(ws 1 "~" false),
        $(ws 2 dotfiles true $root/r/github.com/me/dotfiles),
        $(ws 3 feat false $root/w/me/dotfiles/feat-x),
        $(ws 4 else false $HOME/else),
        $(ws 5 bugfix false $root/w/me/dotfiles/bugfix),
        $(ws 6 app false $root/r/github.com/me/app),
        $(ws 7 dev false $root/w/other/tool/dev),
        $(ws 8 az false $root/r/dev.azure.com/org/proj/az),
        $(ws 9 topic false $root/w/proj/az/topic)
      ]}}"
    }
    wt() { print $root/w; }
    repo() { print $root/r; }
    shift 3
    "$@"
  ' -- "$ui_lib" "$ws_root" "$@"
}

ws_expect() {
  local name=$1 want=$2 got=$3
  [[ $got == "$want" ]] && return 0
  print -u2 "FAIL $name"
  print -u2 "  want: ${(q+)want}"
  print -u2 "  got:  ${(q+)got}"
  ((failures++))
}

# One repository's clone and worktrees sit together, the clone first; a
# worktree without a HEAD to read shows its directory name. An Azure DevOps
# clone drops its org to match the name `wt` gives its worktrees.
ws_expect 'workspaces rows' \
  "$(printf '%s\t%s\t%s\n' \
    '[6] me/app      ● abcdef1' w6 $ws_root/r/github.com/me/app \
    '[2] me/dotfiles ● main' w2 $ws_root/r/github.com/me/dotfiles \
    '[5] me/dotfiles ├ bugfix' w5 $ws_root/w/me/dotfiles/bugfix \
    '[3] me/dotfiles └ feat/x' w3 $ws_root/w/me/dotfiles/feat-x \
    '[7] other/tool  └ dev' w7 $ws_root/w/other/tool/dev \
    '[8] proj/az     ● main' w8 $ws_root/r/dev.azure.com/org/proj/az \
    '[9] proj/az     └ topic' w9 $ws_root/w/proj/az/topic \
    '[1] ~' w1 '' \
    '[4] ~/else' w4 "$HOME/else")" \
  "$(run_ws 0 _ui_workspaces 2>&1)"

ws_expect 'focused workspace' "w2"$'\t'"$ws_root/r/github.com/me/dotfiles" \
  "$(run_ws 0 _ui_focused_workspace 2>&1)"

out=$(run_ws 1 _ui_workspaces 2>&1) && rc=0 || rc=$?
if ((rc == 0)) || [[ $out != *herdr-down* ]]; then
  print -u2 "FAIL workspaces (herdr down): rc=$rc, output=$out"
  ((failures++))
fi

((failures == 0)) || exit 1
print 'ui_test: ok'
