#!/usr/bin/env zsh
# ui.zsh: preview failures must preserve output and return successfully, and a
# branch preview reads the local branch before origin's.
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

# git is stubbed: `rev-parse --verify` succeeds for the refs listed in $2.
branch_preview() {
  zsh -df -c '
    set -uo pipefail
    source "$1"
    known=$2
    git() {
      case $1 in
        rev-parse) [[ " $known " == *" ${@[-1]} "* ]] ;;
        log) print -r -- "log ${@[-1]}" ;;
      esac
    }
    _ui_branch_preview "$3"
  ' -- "$ui_lib" "$@"
}

for args want in \
  'refs/heads/b refs/remotes/origin/b' 'log refs/heads/b' \
  'refs/remotes/origin/b' 'log refs/remotes/origin/b' \
  '' 'a new branch from HEAD'; do
  got=$(branch_preview "$args" b)
  [[ $got == "$want" ]] || {
    print -u2 "FAIL branch preview ($args): want $want, got $got"
    ((failures++))
  }
done

# _ui_require <cmd> <tool>...: every tool is checked, and the first missing one
# is named after the command.
require() {
  zsh -df -c 'source "$1"; shift; _ui_require "$@"' -- "$ui_lib" "$@" 2>&1
}
got=$(require herdr-x zsh git) || {
  print -u2 "FAIL require (all present): $got"
  ((failures++))
}
got=$(require herdr-x zsh no-such-tool-a no-such-tool-b) && {
  print -u2 'FAIL require (missing) should fail'
  ((failures++))
}
[[ $got == 'herdr-x: no-such-tool-a is not installed' ]] || {
  print -u2 "FAIL require (missing): got $got"
  ((failures++))
}

((failures == 0)) || exit 1
print 'ui_test: ok'
