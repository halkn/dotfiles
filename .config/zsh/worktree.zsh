# wt - git worktree helpers. Inside a herdr session a worktree is opened as a
# workspace (1 branch = 1 directory = 1 workspace); outside herdr it degrades to
# plain `git worktree` + `cd`.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-picker.sh, so
# it must only define functions and must not touch the current shell state.

# Own path, so fzf preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_WT_LIB=${${(%):-%x}:A}

_wt_jq_bin() {
  if command -v jaq >/dev/null 2>&1; then
    print -r -- jaq
  else
    print -r -- jq
  fi
}

_wt_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'wt: not inside a git repository' >&2
    return 1
  }
}

# The herdr worktree/workspace API is served over the session socket, so it is
# only usable from inside a herdr session.
_wt_use_herdr() {
  [[ -n $HERDR_ENV ]] && command -v herdr >/dev/null 2>&1
}

# herdr's `[worktrees] directory` is the single source of truth for placement;
# read it instead of hardcoding a second copy of the path.
_wt_root() {
  local config dir
  config=${HERDR_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml}
  dir=$(awk '
    /^[[:space:]]*\[/ { in_section = ($0 ~ /^[[:space:]]*\[worktrees\]/) }
    in_section && /^[[:space:]]*directory[[:space:]]*=/ {
      sub(/^[^=]*=[[:space:]]*/, "")
      gsub(/^"|"[[:space:]]*$/, "")
      print
      exit
    }
  ' "$config" 2>/dev/null)
  dir=${dir:-${XDG_DATA_HOME:-$HOME/.local/share}/herdr/worktrees}
  dir=${dir/#\~/$HOME}
  # `:A` keeps every path comparable with what git reports (git resolves
  # symlinks such as /var -> /private/var; a raw string compare would not match).
  print -r -- "${dir:A}"
}

# Root of the main checkout (the worktree that owns .git), not of the current one.
_wt_main_root() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  print -r -- "${${common%/}:h}"
}

_wt_repo_name() {
  local root
  root=$(_wt_main_root) || return 1
  print -r -- "${root:t}"
}

# Fallback checkout path, used when herdr is unavailable or refuses the request.
# Slashes in branch names would otherwise create nested directories.
_wt_path_for() {
  local branch=$1 root repo
  root=$(_wt_root) || return 1
  repo=$(_wt_repo_name) || return 1
  print -r -- "${${root}/%\//}/$repo/${branch//\//-}"
}

# Default integration branch, e.g. origin/main.
_wt_base_ref() {
  local head
  head=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  if [[ -n $head ]]; then
    print -r -- "$head"
    return 0
  fi
  for head in origin/main origin/master; do
    if git rev-parse --verify --quiet "$head" >/dev/null 2>&1; then
      print -r -- "$head"
      return 0
    fi
  done
  return 1
}

# path<TAB>branch for every worktree of the current repository.
# `path` is zsh's PATH array, so worktree paths are kept in `wt_path` here and
# everywhere below - a `local path` would empty PATH inside the function.
_wt_entries() {
  local line wt_path branch
  while IFS= read -r line; do
    case $line in
      worktree\ *)
        wt_path=${line#worktree }
        branch=
        ;;
      branch\ *)
        branch=${${line#branch }#refs/heads/}
        ;;
      '')
        [[ -n $wt_path ]] && print -r -- "$wt_path	$branch"
        wt_path=
        branch=
        ;;
    esac
  done < <(git worktree list --porcelain)
  [[ -n $wt_path ]] && print -r -- "$wt_path	$branch"
  return 0
}

# Comma-separated markers describing how safe a worktree is to remove.
_wt_flags() {
  local wt_path=$1 branch=$2 base=$3
  local -a flags
  local main_root cur_root track

  main_root=$(_wt_main_root)
  cur_root=$(git rev-parse --path-format=absolute --show-toplevel 2>/dev/null)

  [[ $wt_path == "$main_root" ]] && flags+=(main)
  [[ $wt_path == "$cur_root" ]] && flags+=(current)
  [[ -z $branch ]] && flags+=(detached)
  [[ -d $wt_path ]] || flags+=(missing)

  if [[ -d $wt_path ]] && [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]]; then
    flags+=(dirty)
  fi

  if [[ -n $branch ]]; then
    track=$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch" 2>/dev/null)
    [[ $track == *'[gone]'* ]] && flags+=(gone)
    if [[ -n $base ]] && git merge-base --is-ancestor "$branch" "$base" 2>/dev/null; then
      flags+=(merged)
    fi
    if [[ -z $(git for-each-ref --format='%(upstream)' "refs/heads/$branch" 2>/dev/null) ]]; then
      flags+=(no-upstream)
    elif [[ $track == *ahead* ]]; then
      flags+=(unpushed)
    fi
  fi

  if ((${#flags} == 0)); then
    print -r -- '-'
  else
    print -r -- "${(j:,:)flags}"
  fi
}

# Display line<TAB>path for fzf. `--with-nth 1` hides the path column.
_wt_rows() {
  local base wt_path branch flags
  base=$(_wt_base_ref 2>/dev/null)
  while IFS=$'\t' read -r wt_path branch; do
    flags=$(_wt_flags "$wt_path" "$branch" "$base")
    printf '%-28s %-32s %s\t%s\n' "${wt_path:t}" "${branch:-(detached)}" "$flags" "$wt_path"
  done < <(_wt_entries)
}

# Preview body for a worktree, shared by `wt` and the herdr picker.
_wt_preview() {
  local wt_path=${1:A} branch
  if [[ ! -d $wt_path ]]; then
    print -r -- "missing: $wt_path"
    return 0
  fi
  branch=$(git -C "$wt_path" branch --show-current 2>/dev/null)
  print -r -- "${branch:-(detached)}  ${wt_path}"
  print
  git -C "$wt_path" -c color.ui=always status --short --branch 2>/dev/null
  print
  git -C "$wt_path" log --oneline --decorate --color=always -15 2>/dev/null
}

# open_workspace_id of the worktree at $1, empty when it is not open in herdr.
_wt_workspace_id() {
  local wt_path=$1
  _wt_use_herdr || return 0
  herdr worktree list --json 2>/dev/null \
    | "$(_wt_jq_bin)" -r --arg p "$wt_path" \
      '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' 2>/dev/null
}

# Extract the checkout path from a herdr worktree create/open response.
_wt_response_path() {
  "$(_wt_jq_bin)" -r '
    [.result | .. | objects | (.checkout_path? // .path?) | select(type == "string")][0] // empty
  ' 2>/dev/null
}

# mise prompts for trust on every new checkout path. Only pre-trust code that
# already comes from a repository the user works in - never a fork's PR head.
_wt_trust_mise() {
  local wt_path=$1
  command -v mise >/dev/null 2>&1 || return 0
  [[ -f $wt_path/mise.toml || -f $wt_path/.mise.toml || -f $wt_path/mise/config.toml ]] || return 0
  mise trust --quiet "$wt_path" >/dev/null 2>&1 || true
}

# A branch branched off origin/main inherits origin/main as its upstream, and
# `git push` (push.default = simple) then refuses because the names differ.
# Drop that upstream so the first push creates origin/<branch> instead.
_wt_clear_inherited_upstream() {
  local branch=$1 upstream
  upstream=$(git for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null)
  if [[ -n $upstream && $upstream != */$branch ]]; then
    git branch --unset-upstream "$branch" >/dev/null 2>&1
  fi
  return 0
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

# Create a checkout for a branch that already exists locally, or jump to it.
_wt_checkout_branch() {
  local branch=$1 trust=${2:-1} wt_path out
  wt_path=$(_wt_existing_path_for_branch "$branch")
  if [[ -n $wt_path ]]; then
    _wt_open_path "$wt_path"
    return
  fi

  if _wt_use_herdr; then
    out=$(herdr worktree open --branch "$branch" --focus --json 2>/dev/null) &&
      wt_path=$(print -r -- "$out" | _wt_response_path)
  fi

  if [[ -z $wt_path ]]; then
    wt_path=$(_wt_path_for "$branch") || return 1
    git worktree add "$wt_path" "$branch" || return 1
    [[ $trust == 1 ]] && _wt_trust_mise "$wt_path"
    _wt_open_path "$wt_path"
    return
  fi

  [[ $trust == 1 ]] && _wt_trust_mise "$wt_path"
  return 0
}

_wt_existing_path_for_branch() {
  local branch=$1 wt_path b
  while IFS=$'\t' read -r wt_path b; do
    [[ $b == "$branch" ]] && {
      print -r -- "$wt_path"
      return 0
    }
  done < <(_wt_entries)
  return 1
}

# Remove one worktree; returns non-zero and explains when it refuses.
_wt_remove_one() {
  local wt_path=${1:A} force=${2:-0} ws branch base main_root cur_root
  main_root=$(_wt_main_root)
  cur_root=$(git rev-parse --path-format=absolute --show-toplevel 2>/dev/null)

  if [[ $wt_path == "${main_root:A}" ]]; then
    print 'wt: refusing to remove the main checkout' >&2
    return 1
  fi
  if [[ $wt_path == "${cur_root:A}" ]]; then
    print 'wt: refusing to remove the worktree you are standing in' >&2
    return 1
  fi
  if ! git worktree list --porcelain | grep -qxF "worktree $wt_path"; then
    print "wt: not a worktree of this repository: $wt_path" >&2
    return 1
  fi

  branch=$(git -C "$wt_path" branch --show-current 2>/dev/null)

  ws=$(_wt_workspace_id "$wt_path")
  if _wt_use_herdr && [[ -n $ws ]]; then
    if [[ $force == 1 ]]; then
      herdr worktree remove --workspace "$ws" --force >/dev/null 2>&1
    else
      herdr worktree remove --workspace "$ws" >/dev/null 2>&1
    fi
  fi

  # herdr may not have removed the checkout (or was unavailable); finish in git.
  if git worktree list --porcelain | grep -qxF "worktree $wt_path"; then
    if [[ $force == 1 ]]; then
      git worktree remove --force "$wt_path" || return 1
    else
      git worktree remove "$wt_path" || return 1
    fi
  fi
  git worktree prune

  # Branch cleanup mirrors `git pm`: -d only, so unmerged work is never dropped.
  if [[ -n $branch ]]; then
    base=$(_wt_base_ref 2>/dev/null)
    if [[ -n $base ]] && git merge-base --is-ancestor "$branch" "$base" 2>/dev/null; then
      git branch -d "$branch" >/dev/null 2>&1 || true
    fi
  fi
  return 0
}

# Remove a worktree from outside its repository (used by the herdr picker):
# git commands must run in that repository, and never from the target itself.
_wt_remove_external() {
  local wt_path=${1:A} force=${2:-0} common
  common=$(git -C "$wt_path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  (cd "${${common%/}:h}" && _wt_remove_one "$wt_path" "$force")
}

_wt_fzf_available() {
  command -v fzf >/dev/null 2>&1 || {
    print 'wt: fzf is not installed' >&2
    return 1
  }
}

_wt_pick() {
  local rows
  rows=$(_wt_rows)
  [[ -n $rows ]] || return 1
  print -r -- "$rows" \
    | fzf --delimiter '\t' --with-nth 1 \
      --prompt 'worktree> ' \
      --header 'Enter: open' \
      --preview "source ${_WT_LIB}; _wt_preview {2}" \
    | awk -F'\t' '{print $2}'
}

_wt_go() {
  local wt_path
  _wt_fzf_available || return 1
  wt_path=$(_wt_pick) || return 1
  [[ -n $wt_path ]] || return 1
  _wt_open_path "$wt_path"
}

_wt_new() {
  local branch=$1 base=${2:-} wt_path out
  [[ -n $branch ]] || {
    print 'usage: wt new <branch> [base]' >&2
    return 1
  }
  # `wt new origin/feature` refers to the same branch as `wt new feature`;
  # keeping the prefix would name the checkout directory origin-feature.
  branch=${branch#origin/}

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    print "wt: branch $branch already exists; opening it" >&2
    _wt_checkout_branch "$branch"
    return
  fi

  # Only origin has this branch: create the local tracking branch first.
  # Without this the checkout below would branch off the base ref and silently
  # drop the remote work. An explicit base means a new branch was asked for.
  # Remote refs are read as-is - fetch beforehand to see branches added since.
  if [[ -z $base ]] && git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git branch --track "$branch" "origin/$branch" >/dev/null || return 1
    print "wt: tracking origin/$branch" >&2
    _wt_checkout_branch "$branch"
    return
  fi

  if [[ -z $base ]]; then
    base=$(_wt_base_ref 2>/dev/null)
  fi

  if _wt_use_herdr; then
    if [[ -n $base ]]; then
      out=$(herdr worktree create --branch "$branch" --base "$base" --focus --json 2>/dev/null)
    else
      out=$(herdr worktree create --branch "$branch" --focus --json 2>/dev/null)
    fi
    wt_path=$(print -r -- "$out" | _wt_response_path)
  fi

  if [[ -z $wt_path ]]; then
    wt_path=$(_wt_path_for "$branch") || return 1
    if [[ -n $base ]]; then
      git worktree add --no-track -b "$branch" "$wt_path" "$base" || return 1
    else
      git worktree add -b "$branch" "$wt_path" || return 1
    fi
    _wt_clear_inherited_upstream "$branch"
    _wt_trust_mise "$wt_path"
    _wt_open_path "$wt_path"
    return
  fi

  _wt_clear_inherited_upstream "$branch"
  _wt_trust_mise "$wt_path"
  return 0
}

# Which forge hosts `origin`, so `wt pr` can pick between gh and az repos.
_wt_pr_host() {
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

# Fetch a branch that lives on origin and open it as a worktree.
_wt_track_and_open() {
  local branch=$1
  git fetch origin "$branch" || return 1
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    git branch --track "$branch" "origin/$branch" || return 1
  fi
  _wt_checkout_branch "$branch"
}

# Head of a PR description for the preview window; the rest is folded into a
# line count. GitHub stores descriptions with CRLF, which shows up as ^M here.
_wt_pr_body_head() {
  awk '
    { sub(/\r$/, "") }
    NR <= 20 { print }
    END { if (NR > 20) printf "\n… %d more lines\n", NR - 20 }
  '
}

_wt_pr() {
  local host
  host=$(_wt_pr_host) || {
    print 'wt: no origin remote' >&2
    return 1
  }
  if [[ $host == azure ]]; then
    _wt_pr_az "${1:-}"
  else
    _wt_pr_gh "${1:-}"
  fi
}

# Preview body for the PR picker. `gh pr view` also prints labels, assignees,
# reviewers, projects and the URL, which pushes the description out of view.
_wt_pr_preview_gh() {
  local number=$1 info
  info=$(gh pr view "$number" \
    --json title,state,isDraft,author,headRefName,baseRefName,body 2>/dev/null) || return 0
  print -r -- "$info" | "$(_wt_jq_bin)" -r '
    [
      .title, "",
      "state   " + (if .isDraft then "DRAFT" else .state end),
      "author  " + (.author.login // "?"),
      "branch  " + .headRefName + " -> " + .baseRefName,
      ""
    ] | .[]'
  print -r -- "$info" | "$(_wt_jq_bin)" -r '.body // ""' | _wt_pr_body_head
}

_wt_pr_gh() {
  local number=$1 info head cross
  command -v gh >/dev/null 2>&1 || {
    print 'wt: gh is not installed' >&2
    return 1
  }

  if [[ -z $number ]]; then
    _wt_fzf_available || return 1
    number=$(
      gh pr list --limit 50 \
        --json number,title,author,isDraft,headRefName \
        --template '{{range .}}{{printf "%v" .number}}	{{if .isDraft}}[draft] {{end}}{{.title}} ({{.author.login}}) — {{.headRefName}}
            {{end}}' 2>/dev/null \
        | fzf --delimiter '\t' --with-nth 2 \
          --height=100% \
          --prompt 'pr> ' \
          --preview "source ${_WT_LIB}; _wt_pr_preview_gh {1}" \
          --preview-window 'down:60%:wrap' \
        | awk -F'\t' '{print $1}'
    ) || return 1
  fi
  [[ -n $number ]] || return 1

  info=$(gh pr view "$number" --json headRefName,isCrossRepository) || return 1
  head=$(print -r -- "$info" | "$(_wt_jq_bin)" -r '.headRefName')
  cross=$(print -r -- "$info" | "$(_wt_jq_bin)" -r '.isCrossRepository')

  if [[ $cross == true ]]; then
    # Fork heads are untrusted code: fetch read-only into pr-<n> and do not
    # pre-trust mise. Run `gh pr checkout <n>` inside the worktree to push back.
    git fetch origin "refs/pull/$number/head:pr-$number" --force || return 1
    _wt_checkout_branch "pr-$number" 0
    print "wt: fork PR checked out as pr-$number (run 'gh pr checkout $number' inside it to push back)" >&2
    return 0
  fi

  _wt_track_and_open "$head"
}

# Same four fields as the gh preview. Azure's own `active` / `completed` /
# `abandoned` are mapped onto gh's vocabulary so both forges read alike.
_wt_pr_preview_az() {
  local number=$1 info
  info=$(az repos pr show --id "$number" --only-show-errors -o json 2>/dev/null) || return 0
  print -r -- "$info" | "$(_wt_jq_bin)" -r '
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
  print -r -- "$info" | "$(_wt_jq_bin)" -r '.description // ""' | _wt_pr_body_head
}

# Azure Repos equivalent. `az repos` picks up organization / project /
# repository from the origin remote, so no ids have to be passed here.
_wt_pr_az() {
  local number=$1 prs info head fork
  command -v az >/dev/null 2>&1 || {
    print 'wt: az is not installed' >&2
    return 1
  }

  if [[ -z $number ]]; then
    _wt_fzf_available || return 1
    # Not silenced: az reports sign-in and detection failures on stderr, and
    # they are the usual reason for an empty list.
    prs=$(az repos pr list --status active --top 50 --only-show-errors -o json) || return 1
    number=$(
      print -r -- "$prs" \
        | "$(_wt_jq_bin)" -r '.[] | [(.pullRequestId | tostring), (if .isDraft then "[draft] " else "" end) + .title + " (" + (.createdBy.displayName // "?") + ") — " + (.sourceRefName | ltrimstr("refs/heads/"))] | @tsv' \
        | fzf --delimiter '\t' --with-nth 2 \
          --height=100% \
          --prompt 'pr> ' \
          --preview "source ${_WT_LIB}; _wt_pr_preview_az {1}" \
          --preview-window 'down:60%:wrap' \
        | awk -F'\t' '{print $1}'
    ) || return 1
  fi
  [[ -n $number ]] || return 1

  info=$(az repos pr show --id "$number" --only-show-errors -o json) || return 1
  head=$(print -r -- "$info" | "$(_wt_jq_bin)" -r '.sourceRefName // "" | ltrimstr("refs/heads/")')
  fork=$(print -r -- "$info" | "$(_wt_jq_bin)" -r 'if .forkSource then "true" else "false" end')

  if [[ $fork == true ]]; then
    # Azure Repos only publishes refs/pull/<id>/merge on the target repository,
    # so a fork head cannot be fetched from origin the way it can on GitHub.
    print "wt: PR $number comes from a fork; add that repository as a remote and use 'wt new'" >&2
    return 1
  fi
  [[ -n $head ]] || {
    print "wt: could not read the source branch of PR $number" >&2
    return 1
  }

  _wt_track_and_open "$head"
}

# Interactive removal. $1 = "clean" restricts the list to reclaimable worktrees
# and preselects them.
_wt_rm() {
  local mode=${1:-rm} rows line wt_path tmp
  local -a targets opts
  _wt_fzf_available || return 1

  rows=$(_wt_rows)
  opts=(--prompt 'remove> ')
  if [[ $mode == clean ]]; then
    # Reclaimable = merged or upstream gone, and not the main / current / dirty
    # checkout. Everything shown is preselected; deselect what should stay.
    rows=$(print -r -- "$rows" | grep -E '(merged|gone)' | grep -v -E '(main|current|dirty)')
    [[ -n $rows ]] || {
      print 'wt: nothing to reclaim' >&2
      return 0
    }
    opts=(--prompt 'reclaim> ' --bind 'start:select-all')
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/wt-rm.XXXXXX") || return 1
  print -r -- "$rows" \
    | fzf --multi --delimiter '\t' --with-nth 1 \
      "${opts[@]}" \
      --header 'Tab: toggle / Enter: remove selected' \
      --preview "source ${_WT_LIB}; _wt_preview {2}" >|"$tmp"

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    targets+=("${line##*$'\t'}")
  done <"$tmp"
  rm -f -- "$tmp"
  ((${#targets} == 0)) && return 0

  print -r -- "${(F)targets}"
  print -n 'remove these worktrees? [y/N] '
  if ! read -r -q; then
    print
    return 1
  fi
  print

  for wt_path in "${targets[@]}"; do
    if [[ -d $wt_path ]] && [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]]; then
      print -n "wt: $wt_path has uncommitted changes. remove anyway? [y/N] "
      if read -r -q; then
        print
        _wt_remove_one "$wt_path" 1
      else
        print
        print "wt: skipped $wt_path" >&2
      fi
    else
      _wt_remove_one "$wt_path" 0
    fi
  done
}

# wt              : pick a worktree and open it (herdr workspace, or cd)
# wt new <branch> [base] : create a branch + worktree and open it. Without a
#                          base, an existing origin/<branch> is tracked instead
#                          of branching off the default integration branch.
# wt pr [<number>]       : pick a pull request and open its head as a worktree.
#                          Uses gh, or az repos when origin is on Azure DevOps.
# wt rm                  : pick worktrees to remove
# wt clean               : remove merged / upstream-gone worktrees
wt() {
  _wt_in_repo || return 1

  case ${1:-} in
    '')
      _wt_go
      ;;
    new)
      shift
      _wt_new "$@"
      ;;
    pr)
      shift
      _wt_pr "${1:-}"
      ;;
    rm)
      shift
      _wt_rm rm
      ;;
    clean)
      shift
      _wt_rm clean
      ;;
    -h | --help | help)
      print 'usage: wt [new <branch> [base] | pr [<number>] | rm | clean]'
      ;;
    *)
      print "wt: unknown subcommand: $1" >&2
      return 1
      ;;
  esac
}
