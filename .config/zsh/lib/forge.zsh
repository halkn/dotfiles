# forge - the GitHub / Azure DevOps differences behind one interface, so that
# callers deal in pull requests instead of in `gh` and `az repos`.
#
# This file is sourced from .zshrc and from lib/worktree.zsh, so it must only
# define functions and must not touch the current shell state.

# Own path, so fzf preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_FORGE_LIB=${${(%):-%x}:A}

# Which forge hosts `origin`.
_forge_host() {
  local url
  url=$(git remote get-url origin 2>/dev/null) || return 1
  [[ -n $url ]] || return 1
  case $url in
    *dev.azure.com* | *.visualstudio.com*)
      print -r -- azure
      ;;
    *)
      print -r -- github
      ;;
  esac
}

_forge_cli_available() {
  local cli=$1
  command -v "$cli" >/dev/null 2>&1 || {
    print "forge: $cli is not installed" >&2
    return 1
  }
}

# Head of a PR description for the preview window; the rest is folded into a
# line count. GitHub stores descriptions with CRLF, which shows up as ^M here.
_forge_pr_body_head() {
  awk '
    { sub(/\r$/, "") }
    NR <= 20 { print }
    END { if (NR > 20) printf "\n… %d more lines\n", NR - 20 }
  '
}

# <number><TAB><label> for every open pull request.
_forge_pr_rows() {
  local host
  host=$(_forge_host) || {
    print 'forge: no origin remote' >&2
    return 1
  }

  if [[ $host == azure ]]; then
    _forge_cli_available az || return 1
    # Not silenced: az reports sign-in and detection failures on stderr, and
    # they are the usual reason for an empty list.
    az repos pr list --status active --top 50 --only-show-errors -o json \
      | jq -r '.[] | [(.pullRequestId | tostring), (if .isDraft then "[draft] " else "" end) + .title + " (" + (.createdBy.displayName // "?") + ") — " + (.sourceRefName | ltrimstr("refs/heads/"))] | @tsv'
    return
  fi

  _forge_cli_available gh || return 1
  gh pr list --limit 50 \
    --json number,title,author,isDraft,headRefName \
    --template '{{range .}}{{printf "%v" .number}}	{{if .isDraft}}[draft] {{end}}{{.title}} ({{.author.login}}) — {{.headRefName}}{{"\n"}}{{end}}'
}

# Preview body for the PR picker: title, state, author and branches, then the
# description. `gh pr view` also prints labels, assignees, reviewers, projects
# and the URL, which pushes the description out of view.
# Azure's own `active` / `completed` / `abandoned` are mapped onto gh's
# vocabulary so both forges read alike.
_forge_pr_preview() {
  local number=$1 host info
  host=$(_forge_host) || return 0

  if [[ $host == azure ]]; then
    info=$(az repos pr show --id "$number" --only-show-errors -o json 2>/dev/null) || return 0
    print -r -- "$info" | jq -r '
      [
        .title, "",
        "state   " + (
          if .isDraft then "DRAFT"
          elif .status == "active" then "OPEN"
          elif .status == "completed" then "MERGED"
          elif .status == "abandoned" then "CLOSED"
          else (.status // "?") end
        ),
        "author  " + (.createdBy.displayName // "?"),
        "branch  " + (.sourceRefName | ltrimstr("refs/heads/")) + " -> " + (.targetRefName | ltrimstr("refs/heads/")),
        ""
      ] | .[]'
    print -r -- "$info" | jq -r '.description // ""' | _forge_pr_body_head
    return
  fi

  info=$(gh pr view "$number" \
    --json title,state,isDraft,author,headRefName,baseRefName,body 2>/dev/null) || return 0
  print -r -- "$info" | jq -r '
    [
      .title, "",
      "state   " + (if .isDraft then "DRAFT" else .state end),
      "author  " + (.author.login // "?"),
      "branch  " + .headRefName + " -> " + .baseRefName,
      ""
    ] | .[]'
  print -r -- "$info" | jq -r '.body // ""' | _forge_pr_body_head
}

# <head branch><TAB><true|false whether the head lives in a fork> for one PR.
_forge_pr_head() {
  local number=$1 host info head fork
  host=$(_forge_host) || {
    print 'forge: no origin remote' >&2
    return 1
  }

  if [[ $host == azure ]]; then
    _forge_cli_available az || return 1
    info=$(az repos pr show --id "$number" --only-show-errors -o json) || return 1
    head=$(print -r -- "$info" | jq -r '.sourceRefName // "" | ltrimstr("refs/heads/")')
    fork=$(print -r -- "$info" | jq -r 'if .forkSource then "true" else "false" end')
  else
    _forge_cli_available gh || return 1
    info=$(gh pr view "$number" --json headRefName,isCrossRepository) || return 1
    head=$(print -r -- "$info" | jq -r '.headRefName')
    fork=$(print -r -- "$info" | jq -r '.isCrossRepository')
  fi

  print -r -- "$head	$fork"
}
