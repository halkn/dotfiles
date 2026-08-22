# wt - git worktree helpers, and the navigator that picks where to go. Inside a
# herdr session a worktree is opened as a workspace (1 branch = 1 directory =
# 1 workspace); outside herdr it degrades to plain `git worktree` + `cd`.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-picker.sh, so
# it must only define functions and must not touch the current shell state. For
# the same reason it never returns early on a missing dependency: the picker
# would lose the `_wt_nav_*` layer and `_wt_remove_external` silently.
#
# The `_forge_*` section at the end is the GitHub / Azure DevOps boundary, kept
# here because `wt pr` is its only caller.

# Own path, so fzf preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_WT_LIB=${${(%):-%x}:A}

_wt_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'wt: not inside a git repository' >&2
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
# main_root and cur_root are the same for every worktree of a repository, so
# they are computed once by the caller instead of once per row.
_wt_flags() {
  local wt_path=$1 branch=$2 base=$3 main_root=$4 cur_root=$5
  local -a flags
  local track

  [[ $wt_path == "$main_root" ]] && flags+=(main)
  [[ $wt_path == "$cur_root" ]] && flags+=(current)
  # Claude Code owns the lifecycle of its own checkouts. Matched by pattern
  # rather than against main_root: a session started inside a worktree creates
  # .claude/worktrees/ inside that worktree, not in the main checkout.
  [[ $wt_path == */.claude/worktrees/* ]] && flags+=(agent)
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

# Display line<TAB>flags<TAB>path. Flags get a column of their own so that
# filters match them as a field instead of anywhere in the text: a branch named
# fix/main-nav must not read as the `main` marker.
_wt_rows() {
  local base wt_path branch flags main_root cur_root
  base=$(_wt_base_ref 2>/dev/null)
  main_root=$(_wt_main_root)
  cur_root=$(git rev-parse --path-format=absolute --show-toplevel 2>/dev/null)
  while IFS=$'\t' read -r wt_path branch; do
    flags=$(_wt_flags "$wt_path" "$branch" "$base" "$main_root" "$cur_root")
    printf '%-28s %-32s\t%s\t%s\n' "${wt_path:t}" "${branch:-(detached)}" "$flags" "$wt_path"
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

# Body of the workspace preview: what the workspace holds, then the checkout it
# is standing on. The checkout comes from the row rather than from herdr,
# because a workspace opened on a plain directory does not report one and the
# listing has already worked out where it is.
_wt_workspace_preview() {
  local id=$1 checkout=${2:-}
  _wt_use_herdr || return 0
  herdr workspace list 2>/dev/null \
    | jq -r --arg w "$id" '
      .result.workspaces[] | select(.workspace_id == $w)
      | "[\(.number)] \(.label)",
        "agent: \(.agent_status // "-")   tabs: \(.tab_count)   panes: \(.pane_count)"
    '
  print
  print -r -- 'agents:'
  herdr agent list 2>/dev/null \
    | jq -r --arg w "$id" '
      .result.agents[] | select(.workspace_id == $w)
      | "  \(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.terminal_title_stripped // "")"
    '
  if [[ -n $checkout ]]; then
    print
    _wt_preview "$checkout"
  fi
}

# open_workspace_id of the worktree at $1, empty when it is not open in herdr.
_wt_workspace_id() {
  local wt_path=$1
  _wt_use_herdr || return 0
  herdr worktree list --json 2>/dev/null \
    | jq -r --arg p "$wt_path" \
      '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' 2>/dev/null
}

# Extract the checkout path from a herdr worktree create/open response.
_wt_response_path() {
  jq -r '
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

# ── navigator ────────────────────────────────────────
# One list of everywhere there is to go: open workspaces, worktrees that are not
# open, and the repositories under $REPO_ROOT. Shared with the herdr picker, so
# that both offer the same rows, preview and jump.

# Rows carry `<kind>:<target>` in their second field because what a jump means
# differs per kind: a workspace is focused, a worktree is opened, a repository
# becomes a new workspace.
#
# Producers below emit six fields - `<kind> <key> <target> <name> <branch>
# <path>` - where `key` is the checkout path the row folds onto (empty when the
# row has none) and `target` is what the jump acts on.
#
# Every one of them ends on `return 0`: the herdr picker runs under
# `set -euo pipefail`, where a source that has nothing to say (no server, no
# repository) would otherwise take the whole listing down with it.

# `herdr workspace list` on stdin, `herdr pane list` as $1 and
# `herdr worktree list --json` as $2, so that the shape of the three answers can
# be pinned down by a test instead of only in a live session (herdr 0.8.2).
#
# A workspace reports neither a directory nor a branch of its own: a WorkspaceInfo
# carries a checkout_path only when it was made from a worktree, the branch sits
# on the WorktreeInfo that points back at it, and a workspace opened on a plain
# directory only shows that directory as the cwd of its panes. All three are
# needed - the directory is what the row is recognised by, and it is also what
# folds the repository row behind it away.
_wt_nav_workspace_filter() {
  jq -r --argjson panes "${1:-null}" --argjson worktrees "${2:-null}" '
    (($panes.result.panes?) // []) as $p
    | (($worktrees.result.worktrees?) // []) as $w
    | .result.workspaces[]?
    | .workspace_id as $id
    | ([$w[] | select(.open_workspace_id == $id)] | first) as $wt
    | (
        .worktree.checkout_path
        // ([$p[] | select(.workspace_id == $id)]
            | (map(select(.focused == true)) + .)
            | first
            | (.cwd // .foreground_cwd))
        // ""
      ) as $path
    | ["workspace", $path, $id, "[\(.number)] \(.label)", (($wt.branch) // ""), $path]
    | @tsv
  ' 2>/dev/null
  return 0
}

# `herdr worktree list --json` on stdin. A worktree that is open as a workspace
# is listed all the same and folded away by `_wt_nav_merge`, which keeps this
# filter independent of which workspaces happen to be open.
_wt_nav_worktree_filter() {
  jq -r '
    .result.worktrees[]?
    | ["worktree", .path, .path, (.label // (.path | split("/") | last)), (.branch // ""), .path]
    | @tsv
  ' 2>/dev/null
  return 0
}

# Everything herdr knows, asked for once: the worktree list answers both the
# worktree rows and the branch of every workspace made from a worktree, so a
# listing that fetched it per kind would ask the same question twice.
_wt_nav_herdr_rows() {
  local workspaces panes worktrees
  workspaces=$(herdr workspace list 2>/dev/null) || workspaces=''
  panes=$(herdr pane list 2>/dev/null) || panes=''
  worktrees=$(herdr worktree list --json 2>/dev/null) || worktrees=''
  if [[ -n $workspaces ]]; then
    print -r -- "$workspaces" | _wt_nav_workspace_filter "${panes:-null}" "${worktrees:-null}"
  fi
  if [[ -n $worktrees ]]; then
    print -r -- "$worktrees" | _wt_nav_worktree_filter
  fi
  return 0
}

# Fallback listing: the worktrees of the repository the shell is standing in.
# Nothing wider is reachable without herdr, since only it knows every checkout.
_wt_nav_git_rows() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  _wt_entries | awk -F'\t' '{
    name = $1
    sub(/.*\//, "", name)
    printf "worktree\t%s\t%s\t%s\t%s\t%s\n", $1, $1, name, $2, $1
  }'
  return 0
}

# `_repo_rows` lives in repo.zsh. Workflows do not source each other, so the
# repositories are simply left out when only worktree.zsh has been loaded.
_wt_nav_repo_rows() {
  whence _repo_rows >/dev/null 2>&1 || return 0
  _repo_rows | awk -F'\t' '{ printf "repo\t%s\t%s\t%s\t\t%s\n", $2, $2, $1, $2 }'
  return 0
}

# Six fields in, the two `_wt_nav_merge` reads out. The kind is spelled out in
# the label so that typing `repo` in the picker narrows to repositories.
_wt_nav_format() {
  awk -F'\t' '{
    kind = ($1 == "workspace") ? "ws" : ($1 == "worktree") ? "wt" : $1
    printf "%s\t%s\t%s\t%-4s %-34s %-26s %s\n", $1, $2, $3, kind, $4, ($5 == "" ? "-" : $5), $6
  }'
}

# Ask git about the directory behind each row: which checkout it belongs to,
# and which branch that checkout is on. Both are needed because the answers the
# rows come from are uneven - herdr reports a branch for a worktree but not for
# a workspace, a repository row has neither, and a workspace is recognised by
# the directory its panes sit in, which can be anywhere below the checkout.
# Filling them in here is what makes every row read the same.
#
# Symlinks are taken out on the way, since git reports paths that way and the
# repository glob does not, and two spellings of one checkout would not fold.
#
# The fields are split with `(@ps:\t:)` rather than by `IFS=$'\t' read`: tab
# counts as IFS whitespace in zsh, so a run of them reads as one delimiter and a
# workspace with no checkout - an empty key - would lose the field and shift its
# target into it.
_wt_nav_resolve() {
  local line kind key target name branch wt_path root
  local -a f
  while IFS= read -r line; do
    f=("${(@ps:\t:)line}")
    kind=${f[1]-} key=${f[2]-} target=${f[3]-}
    name=${f[4]-} branch=${f[5]-} wt_path=${f[6]-}
    if [[ -n $key ]]; then
      key=${key:A}
      if root=$(git -C "$key" rev-parse --path-format=absolute --show-toplevel 2>/dev/null); then
        key=${root:A}
        wt_path=$key
        # `branch --show-current` rather than `rev-parse --abbrev-ref HEAD`:
        # the latter fails on a repository whose first commit is still missing.
        if [[ -z $branch ]]; then
          branch=$(git -C "$key" branch --show-current 2>/dev/null)
          branch=${branch:-(detached)}
        fi
      fi
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" "$key" "$target" "$name" "$branch" "$wt_path"
  done
  return 0
}

# Fold the sources onto one row per checkout: a worktree that is open as a
# workspace is a workspace row, and a repository whose checkout is already
# listed is dropped. Workspaces are never folded into each other - two of them
# on one repository are two places to go, which is what parallel work looks
# like; only the worktree and repository rows behind them are removed.
# Rows keep the order workspaces, worktrees, repositories. Pure text in, pure
# text out, so .config/zsh/test/worktree_test.zsh can pin it down.
_wt_nav_merge() {
  awk -F'\t' '
    {
      if ($1 == "" || $3 == "") next
      n++
      kind[n] = $1
      key[n] = $2
      target[n] = $3
      label[n] = $4
      rank[n] = ($1 == "workspace") ? 1 : ($1 == "worktree") ? 2 : 3
      if ($2 == "") next
      # The kind that claims a checkout decides which rows behind it disappear,
      # and the claim is by kind rather than by input order so that the listing
      # does not change with the order the sources answered in.
      if (!(($2) in claimed) || rank[n] < claimed[$2]) claimed[$2] = rank[n]
      if (!((rank[n] SUBSEP $2) in first)) first[rank[n] SUBSEP $2] = n
    }
    END {
      for (r = 1; r <= 3; r++) {
        for (i = 1; i <= n; i++) {
          if (rank[i] != r) continue
          # A checkout-less row has nothing to fold onto, and a workspace is
          # never folded away; everything else survives only as the first row
          # of the kind that claimed its checkout.
          if (key[i] != "" && r != 1) {
            if (claimed[key[i]] != r) continue
            if (first[r SUBSEP key[i]] != i) continue
          }
          # The checkout travels with the row so that the preview does not have
          # to ask herdr a second time what a workspace is standing on.
          printf "%s\t%s:%s\t%s\n", label[i], kind[i], target[i], key[i]
        }
      }
    }
  '
}

_wt_nav_rows() {
  local herdr_rows=''
  if _wt_use_herdr; then
    herdr_rows=$(_wt_nav_herdr_rows) || herdr_rows=''
  fi
  {
    # An unreachable server (or a missing jq) leaves the listing empty; the git
    # view is worth more here than an empty picker.
    if [[ -n $herdr_rows ]]; then
      print -r -- "$herdr_rows"
    else
      _wt_nav_git_rows
    fi
    _wt_nav_repo_rows
  } | _wt_nav_resolve | _wt_nav_format | _wt_nav_merge
}

# Preview for one row: its `<kind>:<target>` and the checkout the listing
# resolved for it. Every row that has a checkout shows the same git body, so
# that the window does not change shape between kinds.
_wt_nav_preview() {
  local entry=${1:-} checkout=${2:-}
  [[ -n $entry ]] || return 0
  case ${entry%%:*} in
    workspace)
      _wt_workspace_preview "${entry#*:}" "$checkout"
      ;;
    worktree | repo)
      _wt_preview "${checkout:-${entry#*:}}"
      ;;
  esac
}

# Make a repository the cwd: a workspace of its own inside herdr, a cd outside.
# Reached only for repositories that are not open yet - an open one is folded
# into its workspace row by _wt_nav_merge.
_wt_nav_open_dir() {
  local dir=$1
  [[ -d $dir ]] || {
    print "wt: no such directory: $dir" >&2
    return 1
  }
  if _wt_use_herdr; then
    # --focus is not the default (herdr 0.8.2).
    herdr workspace create --cwd "$dir" --label "${dir:t}" --focus >/dev/null 2>&1 && return 0
    print 'wt: herdr could not create the workspace; falling back to cd' >&2
  fi
  cd -- "$dir"
}

_wt_nav_open() {
  local entry=${1:-} target
  [[ -n $entry ]] || return 1
  target=${entry#*:}
  case ${entry%%:*} in
    workspace)
      _wt_use_herdr || {
        print 'wt: workspaces can only be focused inside herdr' >&2
        return 1
      }
      herdr workspace focus "$target" >/dev/null
      ;;
    worktree)
      _wt_open_path "$target"
      ;;
    repo)
      _wt_nav_open_dir "$target"
      ;;
    *)
      return 1
      ;;
  esac
}

_wt_nav_go() {
  local rows entry
  _wt_fzf_available || return 1
  rows=$(_wt_nav_rows)
  [[ -n $rows ]] || {
    print 'wt: nothing to open' >&2
    return 1
  }
  entry=$(
    print -r -- "$rows" \
      | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 \
        --prompt 'go> ' \
        --header 'Enter: open' \
        --preview "source ${_WT_LIB}; _wt_nav_preview {2} {3}"
  ) || return 1
  [[ -n $entry ]] || return 1
  _wt_nav_open "$entry"
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

# Fetch a branch that lives on origin and open it as a worktree.
_wt_track_and_open() {
  local branch=$1
  git fetch origin "$branch" || return 1
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    git branch --track "$branch" "origin/$branch" || return 1
  fi
  _wt_checkout_branch "$branch"
}

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
  _wt_checkout_branch "pr-$number" 0
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

# Confirm a set of worktrees and remove them. A dirty checkout is asked about on
# its own: uncommitted work is what no later step can give back.
_wt_remove_targets() {
  local wt_path
  local -a targets=("$@")
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

# Pick worktrees to remove.
_wt_rm() {
  local rows line tmp
  local -a targets
  _wt_fzf_available || return 1

  rows=$(_wt_rows)
  [[ -n $rows ]] || return 0

  # Buffer through a temp file: a picker inside <(...) is not in the foreground
  # process group, so it blocks on /dev/tty (SIGTTIN) and wt hangs.
  tmp=$(mktemp "${TMPDIR:-/tmp}/wt-rm.XXXXXX") || return 1
  print -r -- "$rows" \
    | fzf --multi --delimiter '\t' --with-nth 1,2 --accept-nth 3 \
      --prompt 'remove> ' \
      --header 'Tab: toggle / Enter: remove selected' \
      --preview "source ${_WT_LIB}; _wt_preview {3}" >|"$tmp"

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    targets+=("$line")
  done <"$tmp"
  rm -f -- "$tmp"
  _wt_remove_targets "${targets[@]}"
}

# Remove every reclaimable worktree. Confirmed as a whole; `wt rm` is the path
# for choosing individually.
_wt_clean() {
  local rows line
  local -a targets

  # Reclaimable = merged or upstream gone, and not the main / current / dirty
  # checkout. `agent` checkouts are excluded: Claude Code's own sweep reclaims
  # them, and one may be locked and in use by a running agent.
  rows=$(_wt_rows | awk -F'\t' '
    $2 ~ /(^|,)(merged|gone)(,|$)/ && $2 !~ /(^|,)(main|current|dirty|agent)(,|$)/
  ')
  [[ -n $rows ]] || {
    print 'wt: nothing to reclaim' >&2
    return 0
  }

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    targets+=("${line##*$'\t'}")
  done <<<"$rows"
  _wt_remove_targets "${targets[@]}"
}

# wt              : pick a workspace, worktree or repository and go there
# wt new <branch> [base] : create a branch + worktree and open it. Without a
#                          base, an existing origin/<branch> is tracked instead
#                          of branching off the default integration branch.
# wt pr [<number>]       : pick a pull request and open its head as a worktree.
#                          Uses gh, or az repos when origin is on Azure DevOps.
# wt rm                  : pick worktrees to remove
# wt clean               : remove merged / upstream-gone worktrees
#
# The bare form spans every repository, so only the subcommands - which act on
# the repository they are called from - require standing in one.
wt() {
  case ${1:-} in
    '')
      _wt_nav_go
      ;;
    new)
      shift
      _wt_in_repo || return 1
      _wt_new "$@"
      ;;
    pr)
      shift
      _wt_in_repo || return 1
      _wt_pr "${1:-}"
      ;;
    rm)
      shift
      _wt_in_repo || return 1
      _wt_rm
      ;;
    clean)
      shift
      _wt_in_repo || return 1
      _wt_clean
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
