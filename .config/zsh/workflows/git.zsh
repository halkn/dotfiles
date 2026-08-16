# git - staging the working tree interactively. Browsing branches and the log is
# `git switch **<TAB>` / `git log **<TAB>`; worktrees live in
# workflows/worktree.zsh as `wt`.
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
# what does the work: ctrl-s stages, f5 restores. Not ctrl-r for the latter,
# which reloads the list everywhere else and would read as undoable.
gst() {
  _git_fzf_available || return 1
  _git_in_repo || return 1

  local reload="reload(source ${_GIT_LIB}; _git_stage_rows)"
  _git_stage_rows \
    | fzf --multi \
      --prompt 'stage> ' \
      --header 'ctrl-s: stage / f5: restore' \
      --preview "source ${_GIT_LIB}; _git_stage_preview {}" \
      --bind "ctrl-s:execute-silent(git add -- {+})+$reload" \
      --bind "f5:execute-silent(git restore -- {+})+$reload" >/dev/null
  git status --short
}
