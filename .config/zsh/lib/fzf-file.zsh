# File-scoped fzf helpers.

# frm - fuzzy select files and remove them (multi-select, confirmation required).
frm() {
  command -v fd >/dev/null 2>&1 || { print 'frm: fd is not installed' >&2; return 1; }

  local -a files
  local f
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(fd --type f --hidden --exclude .git --print0 | fzf --multi --read0 --print0 --preview 'cat {}')
  [[ ${#files[@]} -eq 0 ]] && return

  print -r -- "${files[@]}"
  print -n 'remove these files? [y/N] '
  if read -q; then
    print
    rm -- "${files[@]}"
  else
    print
    return 1
  fi
}
