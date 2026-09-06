#!/usr/bin/env zsh
# Load only the completion definition, avoiding interactive startup and local overrides.
set -uo pipefail
eval "$(sed -n '/^  _fzf_complete_git() {/,/^  }/p' "${0:A:h}/../.zshrc")"
typeset -i failures=0
scratch=$(mktemp -d "${TMPDIR:-/tmp}/completion-test.XXXXXX") || exit 1
scratch=${scratch:A}
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/with space/child"
ln -s "$scratch/with space/child" "$scratch/link"
_GIT_LIB=${0:A:h}/../workflows/git.zsh

git() {
  print -r -- "git:${(j:|:)@}"
  [[ $1 == diff ]] && print -r -- "preview-cwd:$PWD"
  return 0
}
_git_stage_rows() { print -r -- "rows:$PWD"; }
_fzf_path_completion() { print fallback; }
chpwd() { print unexpected-chpwd; }
_fzf_complete() {
  local preview=
  while (($#)); do
    if [[ $1 == --preview ]]; then
      preview=$2
      break
    fi
    shift
  done
  command cat
  # fzf substitutes a shell-quoted selection; these fixed values need no escaping.
  preview=${preview//\{1\}/HEAD}
  preview=${preview//\{\}/sample}
  eval "$preview"
}

for sub in switch log add restore; do
  out=$(_fzf_complete_git "git -C ${(q)scratch}/with\\ space -C child $sub")
  rc=$?
  case $sub in
    switch)
      want='branch'
      preview='log'
      ;;
    log)
      want='log'
      preview='show'
      ;;
    add | restore)
      want="rows:$scratch/with space/child"
      preview='diff'
      ;;
  esac
  if ((rc != 0)) || [[ $out != *$want* || $out != *$preview* || $out == *fallback* || $out == *unexpected-chpwd* ]]; then
    print -u2 "FAIL completion $sub: rc=$rc, output=$out"
    ((failures++))
  fi
  if [[ $sub == (switch|log) && $out != *"git:-C|$scratch/with space|-C|child|$preview"* ]]; then
    print -u2 "FAIL completion preview context $sub: $out"
    ((failures++))
  fi
  if [[ $sub == (add|restore) && $out != *"preview-cwd:$scratch/with space/child"* ]]; then
    print -u2 "FAIL completion preview cwd $sub: $out"
    ((failures++))
  fi
done

out=$(_fzf_complete_git "git -C ${(q)scratch}/link -C .. add")
if [[ $out != *"rows:$scratch/with space"$'\n'* || $out != *"preview-cwd:$scratch/with space" ]]; then
  print -u2 "FAIL completion symlink parent: $out"
  ((failures++))
fi

out=$(_fzf_complete_git 'git switch')
if [[ $out != *git:branch* || $out != *git:log* || $out == *'git:-C'* ]]; then
  print -u2 "FAIL completion without -C: $out"
  ((failures++))
fi

out=$(_fzf_complete_git 'git -C')
if [[ $out != fallback ]]; then
  print -u2 "FAIL incomplete -C: $out"
  ((failures++))
fi

((failures == 0)) || exit 1
print 'completion_test: ok'
