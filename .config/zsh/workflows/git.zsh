# git - staging the working tree interactively. Browsing branches and the log is
# `git switch **<TAB>` / `git log **<TAB>`; worktrees live in
# workflows/wk.zsh as `wk`.
#
# `gst` stages and restores from inside the picker, which is why it is a function
# rather than a completion: the list stays open while the decision of what to
# stage is made file by file.
#
# Functions are always defined; each entry point checks its own dependencies, so
# a machine without fzf reports what is missing instead of `command not found`.

# Own path, so preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_GIT_LIB=${${(%):-%x}:A}

# Changed and untracked paths, one per line. Not `git status --porcelain`, which
# quotes paths holding a space or a non-ASCII byte and renders a rename as
# `old -> new`; both would be handed to the shell running the actions below.
_git_stage_rows() {
  git -c core.quotePath=false diff --name-only HEAD 2>/dev/null
  git -c core.quotePath=false ls-files --others --exclude-standard 2>/dev/null
}

# `<marker> <path><TAB><path>` for the picker: the marker is what tells a staged
# path from an unstaged one, since neither the list nor the diff preview does.
_git_stage_display_rows() {
  local file
  local -a staged
  staged=(${(f)"$(git diff --cached --name-only 2>/dev/null)"})
  _git_stage_rows | while IFS= read -r file; do
    if ((${staged[(Ie)$file]})); then
      printf '+ %s\t%s\n' "$file" "$file"
    else
      printf '  %s\t%s\n' "$file" "$file"
    fi
  done
}

# Stage what is not staged and unstage what is, one path at a time: a mixed
# selection would otherwise need a single direction picked for all of it.
_git_stage_toggle() {
  local file
  for file in "$@"; do
    if git diff --cached --quiet -- "$file" 2>/dev/null; then
      git add -- "$file"
    else
      git restore --staged -- "$file"
    fi
  done
}

# An untracked file has nothing to diff against, hence the /dev/null comparison.
_git_stage_preview() {
  local file=$1
  [[ -n $file ]] || return 0
  if git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
    git diff HEAD --color=always -- "$file"
  else
    git diff --no-index --color=always -- /dev/null "$file"
  fi
}

_git_fzf_available() {
  command -v fzf >/dev/null 2>&1 || {
    print 'gst: fzf is not installed' >&2
    return 1
  }
}

_git_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'gst: not inside a git repository' >&2
    return 1
  }
}

# gst - stage or restore changed files. Enter closes the picker, so the keys are
# what does the work: ctrl-o stages and unstages, f5 throws the changes away.
# Not ctrl-r for the latter, which reloads the list everywhere else and would
# read as undoable; tab stays fzf's own multi-select.
gst() {
  _git_fzf_available || return 1
  _git_in_repo || return 1

  local reload="reload(source ${_GIT_LIB}; _git_stage_display_rows)"
  _git_stage_display_rows \
    | fzf --multi --delimiter '\t' --with-nth 1 \
      --prompt 'stage> ' \
      --header 'tab: select / ctrl-o: stage or unstage / f5: discard changes' \
      --preview "source ${_GIT_LIB}; _git_stage_preview {2}" \
      --bind "ctrl-o:execute-silent(source ${_GIT_LIB}; _git_stage_toggle {+2})+$reload" \
      --bind "f5:execute-silent(git restore -- {+2})+$reload" >/dev/null
  git status --short
}
