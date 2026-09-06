#!/usr/bin/env zsh
# Session failures must degrade even when called directly under errexit.
set -uo pipefail
lib=${0:A:h}/../lib/session.zsh
typeset -i failures=0

for scenario in unavailable offline invalid empty valid; do
  out=$(zsh -df -c '
    set -euo pipefail
    source "$1"
    scenario=$2
    _sess_available() { [[ $scenario != unavailable ]]; }
    herdr() {
      case $scenario in
        offline) return 1 ;;
        invalid) print invalid-json ;;
        empty) print "{}" ;;
        valid)
          print '\''{"result":{"workspaces":[{"workspace_id":"w1","number":1,"label":"","worktree":{"checkout_path":"/repo"}}],"worktrees":[{"path":"/repo","open_workspace_id":"w1"}]}}'\''
          ;;
      esac
    }
    _sess_workspace_rows
    _sess_workspace_id /repo
    print survived
  ' -- "$lib" "$scenario")
  rc=$?
  want=survived
  [[ $scenario == valid ]] && want=$(printf 'w1\t1\t\t/repo\nw1\nsurvived')
  if ((rc != 0)) || [[ $out != "$want" ]]; then
    print -u2 "FAIL session $scenario: rc=$rc, output=$out"
    ((failures++))
  fi
done

for fn in _sess_open_dir _sess_open_worktree; do
  zsh -df -c '
    set -euo pipefail
    source "$1"
    target=${1:A:h}
    _sess_available() { return 0; }
    herdr() { return 1; }
    cd /
    "$2" "$target"
    [[ $PWD == "$target" ]]
  ' -- "$lib" "$fn" 2>/dev/null
  if (($? != 0)); then
    print -u2 "FAIL $fn fallback to cd"
    ((failures++))
  fi
done

((failures == 0)) || exit 1
print 'session_test: ok'
