#!/usr/bin/env zsh
# Exercise removal decisions without removing a checkout or contacting herdr.
set -uo pipefail
typeset -i failures=0
workflow=${0:A:h}/../workflows/wk.zsh
scratch=$(mktemp -d "${TMPDIR:-/tmp}/wk-remove-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT

out=$(zsh -df -c '
  set -euo pipefail
  source "$1"
  _sess_workspace_id() { print w1; }
  _sess_close_worktree() { print "closed:$1"; }
  _ck_wt_root() { print /worktrees; }
  _wk_confirm() { print confirmed; }
  git() { [[ $* == *--force* ]]; }
  rmdir() { return 1; }
  _wk_remove_path /worktrees/owner/repo/topic
  print survived
' -- "$workflow")
if (($? != 0)) || [[ $out != $'confirmed\nclosed:w1\nsurvived' ]]; then
  print -u2 "FAIL force confirmation and parent cleanup: $out"
  ((failures++))
fi

for scenario in success partial declined cancel empty error; do
  out=$(zsh -df -c '
    set -euo pipefail
    source "$1"
    scenario=$2
    export TMPDIR=$3
    _ui_require() { return 0; }
    _ck_wt_repo_rows() { print row; }
    fzf() {
      command cat >/dev/null
      case $scenario in
        cancel) return 130 ;;
        empty) return 1 ;;
        error) return 2 ;;
        *) print -l /one /two ;;
      esac
    }
    _wk_confirm() { [[ $scenario != declined ]]; }
    _wk_remove_path() {
      print "removed:$1"
      [[ $scenario != partial || $1 != /one ]]
    }
    _wk_rm
  ' -- "$workflow" "$scenario" "$scratch")
  rc=$?
  case $scenario in
    success)
      want=0
      ;;
    partial | declined)
      want=1
      ;;
    cancel | empty)
      want=0
      ;;
    error)
      want=2
      ;;
  esac
  leftovers=("$scratch"/*(N))
  if ((rc != want || ${#leftovers} != 0)); then
    print -u2 "FAIL removal $scenario: rc=$rc, temporary files=${#leftovers}"
    ((failures++))
  fi
  if [[ $scenario == partial && $out != *removed:/two* ]]; then
    print -u2 'FAIL removal stops after first failure'
    ((failures++))
  fi
  if [[ $scenario == (declined|cancel|empty|error) && $out == *removed:* ]]; then
    print -u2 "FAIL unexpected removal after $scenario"
    ((failures++))
  fi
done

out=$(zsh -df -c '
  set -euo pipefail
  source "$1"
  _sess_workspace_id() { print w1; }
  _sess_close_worktree() { print unexpected-close; }
  _wk_confirm() { return 1; }
  git() {
    [[ $* == *--force* ]] && print unexpected-force
    return 1
  }
  _wk_remove_path /worktrees/owner/repo/topic
' -- "$workflow")
if (($? != 1)) || [[ -n $out ]]; then
  print -u2 "FAIL declined force removal: $out"
  ((failures++))
fi

((failures == 0)) || exit 1
print 'wk_remove_test: ok'
