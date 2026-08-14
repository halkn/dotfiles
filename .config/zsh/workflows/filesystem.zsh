# filesystem - interactive navigation and cleanup of the working directory.
#
# Functions are always defined; each entry point checks its own dependencies, so
# a machine without fzf or fd reports what is missing instead of `command not
# found`.

# fcd - interactively cd into a directory under the given root (default: .).
fcd() {
  command -v fzf >/dev/null 2>&1 || {
    print 'fcd: fzf is not installed' >&2
    return 1
  }
  command -v fd >/dev/null 2>&1 || {
    print 'fcd: fd is not installed' >&2
    return 1
  }
  local dir
  dir=$(fd --type d --hidden --exclude .git . "${1:-.}" | fzf --preview 'ls -la {}') || return
  [[ -n $dir ]] && cd -- "$dir"
}

# frm - fuzzy select files and remove them (multi-select, confirmation required).
frm() {
  command -v fzf >/dev/null 2>&1 || {
    print 'frm: fzf is not installed' >&2
    return 1
  }
  command -v fd >/dev/null 2>&1 || {
    print 'frm: fd is not installed' >&2
    return 1
  }

  local -a files
  local f tmp
  # Run fzf in a foreground pipeline (not a process substitution): an
  # interactive fzf inside <(...) is not in the foreground process group, so it
  # blocks on /dev/tty (SIGTTIN) and frm hangs. Buffer NUL-delimited output to a
  # temp file to keep filenames with newlines safe before removing them.
  tmp=$(mktemp) || {
    print 'frm: failed to create temp file' >&2
    return 1
  }
  fd --type f --hidden --exclude .git --print0 \
    | fzf --multi --read0 --print0 --preview 'cat {}' >|"$tmp"
  while IFS= read -r -d '' f; do
    files+=("$f")
  done <"$tmp"
  rm -f -- "$tmp"
  [[ ${#files[@]} -eq 0 ]] && return

  print -r -- "${files[@]}"
  print -n 'remove these files? [y/N] '
  if read -r -q; then
    print
    rm -- "${files[@]}"
  else
    print
    return 1
  fi
}
