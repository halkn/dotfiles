#!/usr/bin/env zsh
# ui.zsh: preview failures must preserve output and return successfully under
# errexit, and workspace rows read off `herdr workspace list`.
set -uo pipefail
typeset -i failures=0
ui_lib=${0:A:h}/../../.config/herdr/ui.zsh

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
# workspace on a git checkout carries a path (herdr 0.9.1).
run_ws() {
  zsh -df -c '
    set -euo pipefail
    source "$1"
    herdr_fails=$2
    herdr() {
      [[ $herdr_fails == 0 ]] || { print -u2 herdr-down; return 1; }
      print -r -- "{\"result\":{\"workspaces\":[
        {\"workspace_id\":\"w1\",\"number\":1,\"label\":\"~\",\"focused\":false},
        {\"workspace_id\":\"w2\",\"number\":2,\"label\":\"dotfiles\",\"focused\":true,
         \"worktree\":{\"checkout_path\":\"/r/github.com/me/dotfiles\"}},
        {\"workspace_id\":\"w3\",\"number\":3,\"label\":\"feat\",\"focused\":false,
         \"worktree\":{\"checkout_path\":\"/w/me/dotfiles/feat\"}},
        {\"workspace_id\":\"w4\",\"number\":4,\"label\":\"else\",\"focused\":false,
         \"worktree\":{\"checkout_path\":\"$HOME/else\"}}
      ]}}"
    }
    wt() { print /w; }
    repo() { print /r; }
    shift 2
    "$@"
  ' -- "$ui_lib" "$@"
}

ws_expect() {
  local name=$1 want=$2 got=$3
  [[ $got == "$want" ]] && return 0
  print -u2 "FAIL $name"
  print -u2 "  want: ${(q+)want}"
  print -u2 "  got:  ${(q+)got}"
  ((failures++))
}

ws_expect 'workspaces rows' \
  "$(printf '[%s] %-24s %s\t%s\t%s\n' \
    1 '~' '' w1 '' \
    2 dotfiles github.com/me/dotfiles w2 /r/github.com/me/dotfiles \
    3 feat me/dotfiles/feat w3 /w/me/dotfiles/feat \
    4 else '~/else' w4 "$HOME/else")" \
  "$(run_ws 0 _ui_workspaces 2>&1)"

ws_expect 'focused workspace' $'w2\t/r/github.com/me/dotfiles' \
  "$(run_ws 0 _ui_focused_workspace 2>&1)"

out=$(run_ws 1 _ui_workspaces 2>&1) && rc=0 || rc=$?
if ((rc == 0)) || [[ $out != *herdr-down* ]]; then
  print -u2 "FAIL workspaces (herdr down): rc=$rc, output=$out"
  ((failures++))
fi

((failures == 0)) || exit 1
print 'ui_test: ok'
