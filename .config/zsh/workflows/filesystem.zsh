# filesystem - interactive navigation and cleanup of the working directory.
#
# Functions are always defined; each entry point checks its own dependencies, so
# a machine without tv or fd reports what is missing instead of `command not
# found`.
#
# The previews of the built-in channels are overridden: `dirs` colours `ls` with
# a GNU-only flag and `files` previews through `bat`, which is not installed
# here.

# fcd - interactively cd into a directory under the given root (default: .).
fcd() {
  command -v tv >/dev/null 2>&1 || {
    print 'fcd: tv is not installed' >&2
    return 1
  }
  command -v fd >/dev/null 2>&1 || {
    print 'fcd: fd is not installed' >&2
    return 1
  }
  local root=${1:-.} dir
  # The channel runs `fd` in the root, so its entries are relative to it.
  dir=$(tv dirs "$root" --preview-command 'ls -la {}') || return
  [[ -n $dir ]] && cd -- "$root/$dir"
}

# frm - fuzzy select files and remove them (multi-select, confirmation required).
frm() {
  command -v tv >/dev/null 2>&1 || {
    print 'frm: tv is not installed' >&2
    return 1
  }
  command -v fd >/dev/null 2>&1 || {
    print 'frm: fd is not installed' >&2
    return 1
  }

  local -a files
  local f tmp
  # Run tv in a foreground pipeline (not a process substitution): an interactive
  # picker inside <(...) is not in the foreground process group, so it blocks on
  # /dev/tty (SIGTTIN) and frm hangs.
  tmp=$(mktemp) || {
    print 'frm: failed to create temp file' >&2
    return 1
  }
  tv files --preview-command 'cat {}' >|"$tmp"
  while IFS= read -r f; do
    [[ -n $f ]] || continue
    # A multi-selection comes back newline-joined, so a file name holding a
    # newline reads as two entries. Removing either would hit the wrong path.
    [[ -e $f ]] || {
      print "frm: cannot resolve '$f'" >&2
      rm -f -- "$tmp"
      return 1
    }
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
