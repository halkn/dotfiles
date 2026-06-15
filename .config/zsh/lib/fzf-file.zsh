# File-scoped fzf helpers.

# frm - fuzzy select files and remove them (multi-select, confirmation required).
frm() {
  local files
  files=$(
    fd --type f --hidden --exclude .git \
      | fzf --multi --preview 'cat {}'
  ) || return
  [[ -z $files ]] && return

  print -r -- "$files"
  print -n 'remove these files? [y/N] '
  if read -q; then
    print
    print -r -- "$files" | while IFS= read -r f; do rm -- "$f"; done
  else
    print
    return 1
  fi
}
