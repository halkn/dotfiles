# wt - the lifecycle of a git worktree: create one for a branch or a pull
# request, jump into it, remove it again. Inside a herdr session a worktree is
# opened as a workspace (1 branch = 1 directory = 1 workspace); outside herdr it
# degrades to a plain `cd`. The `wt` command itself, and the listing that picks
# where to go, live in nav.zsh.
#
# Which checkouts exist, what state each one is in, where a new one belongs and
# whether removing one would lose work are all `trepo`. What is left here is the
# part a subprocess cannot do: asking the question, drawing the row, trusting a
# mise config, and moving the shell or the herdr session into the answer.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-picker.sh, so
# it must only define functions and must not touch the current shell state. For
# the same reason it never returns early on a missing dependency: the picker
# would lose `_wt_preview` and `_wt_remove_path` silently.
#
# The `_forge_*` section at the end is the GitHub / Azure DevOps boundary, kept
# here because `wt pr` is its only caller. trepo has no notion of a pull
# request, so this is the one part of the lifecycle it does not answer for.

# Own path, so fzf preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_WT_LIB=${${(%):-%x}:A}

_wt_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'wt: not inside a git repository' >&2
    return 1
  }
}

_wt_trepo_available() {
  command -v trepo >/dev/null 2>&1 || {
    print "${1:-wt}: trepo is not installed" >&2
    return 1
  }
}

# The herdr worktree/workspace API is served over the session socket, so it is
# only usable from inside a herdr session. The default value keeps the check
# usable from the herdr picker, which runs under `set -u` where a bare
# $HERDR_ENV would abort the script instead of answering the question.
_wt_use_herdr() {
  [[ -n ${HERDR_ENV:-} ]] && command -v herdr >/dev/null 2>&1
}

# mise prompts for trust on every new checkout path. Only pre-trust code that
# already comes from a repository the user works in - never a fork's PR head.
_wt_trust_mise() {
  local wt_path=$1
  command -v mise >/dev/null 2>&1 || return 0
  [[ -f $wt_path/mise.toml || -f $wt_path/.mise.toml || -f $wt_path/mise/config.toml ]] || return 0
  mise trust --quiet "$wt_path" >/dev/null 2>&1 || true
}

# ── preview ──────────────────────────────────────────

# Preview body for a checkout, shared by `wt` and the herdr picker.
#
# `trepo status` answers the header - repository, branch, kind, flags, upstream -
# and says `missing:` for a directory that is gone, so nothing here has to test
# for one. The two git calls below are the part trepo does not render: a
# coloured working-tree summary and the recent history.
_wt_preview() {
  local wt_path=${1:A}
  [[ -n $wt_path ]] || return 0

  if command -v trepo >/dev/null 2>&1; then
    trepo status "$wt_path" 2>/dev/null || true
  else
    print -r -- "$wt_path"
  fi

  [[ -d $wt_path ]] || return 0
  print
  git -C "$wt_path" -c color.ui=always status --short --branch 2>/dev/null
  print
  git -C "$wt_path" log --oneline --decorate --color=always -15 2>/dev/null
  # A directory git refuses (no repository yet, or a broken checkout) must not
  # end the preview process, which runs under `set -e` in the herdr picker.
  return 0
}

# ── going there ──────────────────────────────────────

# open_workspace_id of the worktree at $1, empty when it is not open in herdr.
_wt_workspace_id() {
  local wt_path=$1
  _wt_use_herdr || return 0
  herdr worktree list --json 2>/dev/null \
    | jq -r --arg p "$wt_path" \
      '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' 2>/dev/null
}

# Jump to an existing checkout: focus its workspace, open one, or just cd.
_wt_open_path() {
  local wt_path=${1:A} ws
  [[ -d $wt_path ]] || {
    print "wt: no such worktree: $wt_path" >&2
    return 1
  }

  if _wt_use_herdr; then
    ws=$(_wt_workspace_id "$wt_path")
    if [[ -n $ws ]]; then
      herdr workspace focus "$ws" >/dev/null && return 0
    elif herdr worktree open --path "$wt_path" --focus >/dev/null 2>&1; then
      return 0
    fi
    print 'wt: herdr could not open the worktree; falling back to cd' >&2
  fi

  cd -- "$wt_path"
}

# ── creating ─────────────────────────────────────────

# Make sure a checkout for a branch exists and go there. `trepo add` is
# idempotent, so this is equally the way to reach one that is already there; the
# extra arguments are its own (`--from <ref>`).
#
# $2 says whether the result may be pre-trusted for mise, which is false for a
# fork's head: that is code from outside the repository.
_wt_add_and_open() {
  local branch=$1 trust=$2 wt_path
  shift 2
  _wt_trepo_available || return 1
  wt_path=$(trepo add "$branch" "$@") || return 1
  [[ -n $wt_path ]] || return 1
  ((trust)) && _wt_trust_mise "$wt_path"
  _wt_open_path "$wt_path"
}

# Everything a branch name can mean - it exists locally, it exists only on
# origin, it does not exist at all - is one call: trepo picks the branch up
# where it is, and only creates one off the integration branch when there is
# nothing to pick up. A base given here says a new branch was asked for.
_wt_new() {
  local branch=${1:-} base=${2:-}
  [[ -n $branch ]] || {
    print 'usage: wt new <branch> [base]' >&2
    return 1
  }

  if [[ -n $base ]]; then
    _wt_add_and_open "$branch" 1 --from "$base"
  else
    _wt_add_and_open "$branch" 1
  fi
}

# Fetch a branch that lives on origin and open it as a worktree. Remote refs are
# read as they are, so the fetch is what makes a branch added since the last one
# visible; creating the tracking branch is trepo's.
_wt_track_and_open() {
  local branch=$1
  git fetch origin "$branch" || return 1
  _wt_add_and_open "$branch" 1
}

# ── removing ─────────────────────────────────────────

# Remove one checkout by path.
#
# Whether it may go at all is trepo's: it refuses a main checkout, the one being
# stood in and a locked one outright, and keeps anything whose removal needs a
# decision - uncommitted work, ignored files, unpushed commits, a checkout
# another tool manages - reporting the reason on stderr and exiting 3. $2 is the
# caller having made that decision.
#
# The herdr workspace is closed afterwards rather than before, so a removal
# trepo declines does not cost the window that was open on it.
_wt_remove_path() {
  local wt_path=${1:A} force=${2:-0} ws rc
  local -a flags
  _wt_trepo_available || return 1
  ((force)) && flags=(--force)

  ws=$(_wt_workspace_id "$wt_path")
  trepo rm "${flags[@]}" -- "$wt_path"
  rc=$?
  ((rc == 0)) || return $rc

  if [[ -n $ws ]]; then
    herdr workspace close "$ws" >/dev/null 2>&1 || true
  fi
  return 0
}

# `trepo list --worktrees --here` on stdin, laid out as one display column plus
# the path. Kept apart from the call below so a test can pin the columns down
# (trepo v0.5.0). The repository slug is dropped because --here makes it the
# same on every row, and the padding trepo puts on the first two fields is taken
# off again: the columns are laid out to this picker's width, and a branch
# longer than trepo's 28 would otherwise push the flags out of line.
_wt_format_rows() {
  awk -F'\t' '{
    branch = $2
    sub(/ +$/, "", branch)
    printf "%-34s %-26s\t%s\n", branch, $3, $4
  }'
}

# The worktrees of this repository, ready for the picker. `--worktrees` is also
# what makes the plain output enough here: with the main checkout excluded every
# row is the same kind, which is the one thing the text form cannot say.
_wt_rows() {
  trepo list --worktrees --here 2>/dev/null | _wt_format_rows
}

_wt_confirm() {
  print -n "$1 [y/N] "
  if read -r -q; then
    print
    return 0
  fi
  print
  return 1
}

# Remove the given checkouts, asking again about each one trepo would not settle
# on its own. The reason comes back from trepo, so the question here names it
# instead of restating a rule this side does not own.
_wt_remove_targets() {
  local wt_path message rc
  local -a targets=("$@")
  ((${#targets} == 0)) && return 0

  print -r -- "${(F)targets}"
  _wt_confirm 'remove these worktrees?' || return 1

  for wt_path in "${targets[@]}"; do
    message=$(_wt_remove_path "$wt_path" 0 2>&1)
    rc=$?
    ((rc == 0)) && continue
    if ((rc != 3)); then
      [[ -n $message ]] && print -r -- "$message" >&2
      continue
    fi
    print -r -- "$message" >&2
    if _wt_confirm "remove ${wt_path:t} anyway?"; then
      _wt_remove_path "$wt_path" 1
    else
      print "wt: skipped $wt_path" >&2
    fi
  done
}

_wt_fzf_available() {
  command -v fzf >/dev/null 2>&1 || {
    print 'wt: fzf is not installed' >&2
    return 1
  }
}

# Pick worktrees to remove.
_wt_rm() {
  local rows line tmp
  local -a targets
  _wt_fzf_available || return 1
  _wt_trepo_available || return 1

  rows=$(_wt_rows)
  [[ -n $rows ]] || return 0

  # Buffer through a temp file: a picker inside <(...) is not in the foreground
  # process group, so it blocks on /dev/tty (SIGTTIN) and wt hangs.
  tmp=$(mktemp "${TMPDIR:-/tmp}/wt-rm.XXXXXX") || return 1
  print -r -- "$rows" \
    | fzf --multi --delimiter '\t' --with-nth 1 --accept-nth 2 \
      --prompt 'remove> ' \
      --header 'Tab: toggle / Enter: remove selected' \
      --preview "source ${_WT_LIB}; _wt_preview {2}" >|"$tmp"

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    targets+=("$line")
  done <"$tmp"
  rm -f -- "$tmp"
  _wt_remove_targets "${targets[@]}"
}

# Remove every worktree whose work is finished. Which ones those are is
# `trepo rm --reclaimable`: merged, retired on the remote, or already deleted by
# hand, and never one that needs a decision - a checkout under .claude/worktrees
# is held back by trepo.protected, because Claude Code's own sweep reclaims it.
#
# The rehearsal is what the confirmation is about, so the selection is made
# once by trepo rather than being recomputed here to display it.
_wt_clean() {
  local preview rc
  _wt_trepo_available || return 1

  preview=$(trepo rm --reclaimable --here --dry-run 2>&1)
  rc=$?
  if ((rc == 1)); then
    print 'wt: nothing to reclaim' >&2
    return 0
  fi
  if ((rc != 0)); then
    [[ -n $preview ]] && print -r -- "$preview" >&2
    return 1
  fi

  print -r -- "$preview"
  _wt_confirm 'reclaim these worktrees?' || return 1
  trepo rm --reclaimable --here
}

# ── pull requests ────────────────────────────────────

# What to do with a PR whose head lives in a fork. This is the one step where
# the forges cannot be made to look alike.
_wt_pr_fork() {
  local number=$1 host
  host=$(_forge_host) || return 1

  if [[ $host == azure ]]; then
    # Azure Repos only publishes refs/pull/<id>/merge on the target repository,
    # so a fork head cannot be fetched from origin the way it can on GitHub.
    print "wt: PR $number comes from a fork; add that repository as a remote and use 'wt new'" >&2
    return 1
  fi

  # Fork heads are untrusted code: fetch read-only into pr-<n> and do not
  # pre-trust mise. Run `gh pr checkout <n>` inside the worktree to push back.
  git fetch origin "refs/pull/$number/head:pr-$number" --force || return 1
  _wt_add_and_open "pr-$number" 0
  print "wt: fork PR checked out as pr-$number (run 'gh pr checkout $number' inside it to push back)" >&2
  return 0
}

# Open the head of a pull request as a worktree. Which forge answers is the
# forge layer's problem; this is only the picker and the checkout.
_wt_pr() {
  local number=${1:-} rows head fork
  if [[ -z $number ]]; then
    _wt_fzf_available || return 1
    rows=$(_forge_pr_rows) || return 1
    [[ -n $rows ]] || {
      print 'wt: no open pull requests' >&2
      return 1
    }
    number=$(
      print -r -- "$rows" \
        | fzf --delimiter '\t' --with-nth 2 --accept-nth 1 \
          --prompt 'pr> ' \
          --height=100% \
          --preview "source ${_WT_LIB}; _forge_pr_preview {1}" \
          --preview-window 'down:60%:wrap'
    ) || return 1
  fi
  [[ -n $number ]] || return 1

  IFS=$'\t' read -r head fork < <(_forge_pr_head "$number") || return 1

  if [[ $fork == true ]]; then
    _wt_pr_fork "$number"
    return
  fi
  [[ -n $head ]] || {
    print "wt: could not read the source branch of PR $number" >&2
    return 1
  }

  _wt_track_and_open "$head"
}

# ── forge ────────────────────────────────────────────
# The GitHub / Azure DevOps differences behind one interface, so that `wt pr`
# above deals in pull requests instead of in `gh` and `az repos`.

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
