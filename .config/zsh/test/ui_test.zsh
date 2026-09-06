#!/usr/bin/env zsh
# Preview failures must preserve output and return successfully under errexit.
set -uo pipefail
typeset -i failures=0

for scenario in status log directory; do
  out=$(zsh -df -c '
    set -euo pipefail
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
  ' -- "${0:A:h}/../lib/ui.zsh" "$scenario")
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

((failures == 0)) || exit 1
print 'ui_test: ok'
