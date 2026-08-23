# nav - one list of everywhere there is to go: open workspaces, worktrees that
# are not open, the repositories under $REPO_ROOT, and the running agents. One
# picker serves all of them, so `wt`, `repo` and the herdr popup cannot drift
# apart in what they offer.
#
# The entry points `wt` and `repo` live here because their bare form is this
# picker; their subcommands are implemented in worktree.zsh and repo.zsh. The
# dependency runs one way only - nav.zsh calls into those two, neither calls
# back - so that the load order stays irrelevant.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-picker.sh, so
# it must only define functions and must not touch the current shell state. For
# the same reason it never returns early on a missing dependency: the picker
# would lose the listing silently.

# Own path, so the fzf preview and transform commands (each of which runs in a
# fresh shell without these functions) can re-source the workflows.
# `%x` expands to the file being sourced.
_NAV_LIB=${${(%):-%x}:A}

# What a fresh shell has to run to get the functions back. The whole workflow
# set rather than this file alone: the rows, the preview and the removal all
# reach into worktree.zsh and repo.zsh.
_nav_source_cmd() {
  print -r -- "source ${_NAV_LIB:h}/repo.zsh; source ${_NAV_LIB:h}/worktree.zsh; source ${_NAV_LIB}"
}

# ── rows ─────────────────────────────────────────────
# Rows carry `<kind>:<target>` in their second field because what a jump means
# differs per kind: a workspace is focused, a worktree is opened, a repository
# becomes a new workspace, an agent is focused.
#
# The producers below emit six fields - `<kind> <key> <target> <name> <branch>
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
_nav_workspace_filter() {
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
# is listed all the same and folded away by `_nav_merge`, which keeps this
# filter independent of which workspaces happen to be open.
_nav_worktree_filter() {
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
_nav_herdr_rows() {
  local workspaces panes worktrees
  workspaces=$(herdr workspace list 2>/dev/null) || workspaces=''
  panes=$(herdr pane list 2>/dev/null) || panes=''
  worktrees=$(herdr worktree list --json 2>/dev/null) || worktrees=''
  if [[ -n $workspaces ]]; then
    print -r -- "$workspaces" | _nav_workspace_filter "${panes:-null}" "${worktrees:-null}"
  fi
  if [[ -n $worktrees ]]; then
    print -r -- "$worktrees" | _nav_worktree_filter
  fi
  return 0
}

# The worktrees of the repository the shell is standing in, whether or not
# herdr knows about them. Nothing wider is reachable from git alone, since only
# herdr knows which checkouts exist outside this repository.
_nav_git_rows() {
  whence _wt_entries >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  _wt_entries | awk -F'\t' '{
    name = $1
    sub(/.*\//, "", name)
    printf "worktree\t%s\t%s\t%s\t%s\t%s\n", $1, $1, name, $2, $1
  }'
  return 0
}

# `_repo_rows` lives in repo.zsh. Workflows do not source each other, so the
# repositories are simply left out when it has not been loaded.
_nav_repo_rows() {
  whence _repo_rows >/dev/null 2>&1 || return 0
  _repo_rows | awk -F'\t' '{ printf "repo\t%s\t%s\t%s\t\t%s\n", $2, $2, $1, $2 }'
  return 0
}

# Six fields in, the two `_nav_merge` reads out. The kind is spelled out in the
# label so that typing `repo` in the picker narrows to repositories.
_nav_format() {
  awk -F'\t' '{
    kind = ($1 == "workspace") ? "ws" : ($1 == "worktree") ? "wt" : $1
    printf "%s\t%s\t%s\t%-4s %-34s %-26s %s\n", $1, $2, $3, kind, $4, ($5 == "" ? "-" : $5), $6
  }'
}

# Branch a .git/HEAD file points at, or `(detached)` when it holds a commit
# instead of a ref. Reading the file is only correct for a main checkout, where
# .git is a directory; a linked worktree keeps its HEAD elsewhere.
_nav_head_branch() {
  local head
  # Checked before opening: zsh reports a failed redirection itself, and the
  # picker would show that on the row instead of a branch.
  [[ -r $1 ]] || return 0
  read -r head <"$1" || return 0
  case $head in
    'ref: refs/heads/'*)
      print -r -- "${head#ref: refs/heads/}"
      ;;
    *)
      print -r -- '(detached)'
      ;;
  esac
  return 0
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
_nav_resolve() {
  local line kind key target name branch wt_path root
  local -a f
  while IFS= read -r line; do
    f=("${(@ps:\t:)line}")
    kind=${f[1]-} key=${f[2]-} target=${f[3]-}
    name=${f[4]-} branch=${f[5]-} wt_path=${f[6]-}
    if [[ -n $key ]]; then
      key=${key:A}
      if [[ -d $key/.git ]]; then
        # A directory that holds a .git directory is a work tree root already,
        # and its HEAD is a file. Reading it is what keeps a listing of dozens
        # of repositories from paying a git process or two for every row.
        wt_path=$key
        [[ -n $branch ]] || branch=$(_nav_head_branch "$key/.git/HEAD")
      elif root=$(git -C "$key" rev-parse --path-format=absolute --show-toplevel 2>/dev/null); then
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
# text out, so .config/zsh/test/nav_test.zsh can pin it down.
_nav_merge() {
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

_nav_place_rows() {
  local herdr_rows=''
  if _wt_use_herdr; then
    herdr_rows=$(_nav_herdr_rows) || herdr_rows=''
  fi
  {
    # An unreachable server (or a missing jq) leaves the herdr rows empty; the
    # git view alone is worth more here than an empty picker.
    if [[ -n $herdr_rows ]]; then
      print -r -- "$herdr_rows"
    fi
    # Always asked as well: herdr lists the worktrees it manages, so a checkout
    # it never opened - one under .claude/worktrees, or one the `git worktree
    # add` fallback created - is only reachable through git. The overlap folds
    # away in _nav_merge, which keeps herdr's own spelling of the path.
    _nav_git_rows
    _nav_repo_rows
  } | _nav_resolve | _nav_format | _nav_merge
}

# Agents are a mode of their own because focusing one is a different question:
# it lands in a pane rather than in a directory, and the rows fold onto nothing.
_nav_agent_rows() {
  local agents rows
  _wt_use_herdr || return 0
  agents=$(herdr agent list 2>/dev/null) || return 0
  rows=$(
    print -r -- "$agents" \
      | jq -r '
              .result.agents[]?
              | ["\(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.cwd // "-")",
                 "agent:\(.terminal_id)",
                 (.cwd // "")]
              | @tsv
            ' 2>/dev/null
  ) || return 0
  [[ -n $rows ]] && print -r -- "$rows"
  return 0
}

# ── preview ──────────────────────────────────────────

# Body of the workspace preview: what the workspace holds, then the checkout it
# is standing on. The checkout comes from the row rather than from herdr,
# because a workspace opened on a plain directory does not report one and the
# listing has already worked out where it is.
# Each answer is captured before it is printed rather than piped straight to the
# screen: the picker runs the preview under `set -euo pipefail`, where one
# unreachable call would end the process and leave the whole pane blank instead
# of only the section it could not fill.
_nav_workspace_preview() {
  local id=$1 checkout=${2:-} head agents
  if _wt_use_herdr; then
    head=$(
      herdr workspace list 2>/dev/null \
        | jq -r --arg w "$id" '
                                  .result.workspaces[] | select(.workspace_id == $w)
                                  | "[\(.number)] \(.label)",
                                    "agent: \(.agent_status // "-")   tabs: \(.tab_count)   panes: \(.pane_count)"
                                ' 2>/dev/null
    ) || head=''
    agents=$(
      herdr agent list 2>/dev/null \
        | jq -r --arg w "$id" '
                                  .result.agents[] | select(.workspace_id == $w)
                                  | "  \(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.terminal_title_stripped // "")"
                                ' 2>/dev/null
    ) || agents=''
    print -r -- "${head:-$id}"
    print
    print -r -- 'agents:'
    print -r -- "${agents:-  -}"
  fi
  if [[ -n $checkout ]]; then
    print
    _wt_preview "$checkout"
  fi
  return 0
}

# Preview for one row: its `<kind>:<target>` and the checkout the listing
# resolved for it. Every row that has a checkout shows the same git body, so
# that the window does not change shape between kinds.
_nav_preview() {
  local entry=${1:-} checkout=${2:-}
  [[ -n $entry ]] || return 0
  case ${entry%%:*} in
    workspace)
      _nav_workspace_preview "${entry#*:}" "$checkout"
      ;;
    worktree | repo)
      _wt_preview "${checkout:-${entry#*:}}"
      ;;
    agent)
      herdr agent read "${entry#*:}" --source recent \
        --lines "${FZF_PREVIEW_LINES:-40}" --format ansi 2>/dev/null || true
      ;;
  esac
  return 0
}

# ── going there ──────────────────────────────────────

# Make a repository the cwd: a workspace of its own inside herdr, a cd outside.
# A repository that is already open is normally folded into its workspace row,
# but that fold rests on where the workspace's panes are standing, so a second
# workspace on one repository stays possible - and is a legitimate thing to
# want, which is why this does not try to prevent it.
_nav_open_dir() {
  local dir=$1
  [[ -d $dir ]] || {
    print "nav: no such directory: $dir" >&2
    return 1
  }
  if _wt_use_herdr; then
    # --focus is not the default (herdr 0.8.2).
    herdr workspace create --cwd "$dir" --label "${dir:t}" --focus >/dev/null 2>&1 && return 0
    print 'nav: herdr could not create the workspace; falling back to cd' >&2
  fi
  cd -- "$dir"
}

_nav_open() {
  local entry=${1:-} target
  [[ -n $entry ]] || return 1
  target=${entry#*:}
  case ${entry%%:*} in
    workspace)
      _wt_use_herdr || {
        print 'nav: workspaces can only be focused inside herdr' >&2
        return 1
      }
      herdr workspace focus "$target" >/dev/null
      ;;
    agent)
      _wt_use_herdr || {
        print 'nav: agents can only be focused inside herdr' >&2
        return 1
      }
      herdr agent focus "$target" >/dev/null
      ;;
    worktree)
      _wt_open_path "$target"
      ;;
    repo)
      _nav_open_dir "$target"
      ;;
    *)
      return 1
      ;;
  esac
}

# The checkout that may be removed for one row, empty when there is none.
#
# Deliberately not the checkout the listing resolved for the row: that one is
# where the workspace's focused pane happens to be standing, which is a live
# value and can be a checkout of another repository entirely. Removal is
# destructive, so it asks herdr what the workspace was made from instead.
_nav_removable_path() {
  local entry=${1:-} workspaces
  case ${entry%%:*} in
    worktree)
      print -r -- "${entry#*:}"
      ;;
    workspace)
      _wt_use_herdr || return 0
      workspaces=$(herdr workspace list 2>/dev/null) || return 0
      print -r -- "$workspaces" \
        | jq -r --arg w "${entry#*:}" \
          '.result.workspaces[]? | select(.workspace_id == $w) | .worktree.checkout_path // empty' 2>/dev/null ||
        return 0
      ;;
  esac
  return 0
}

# ── picker ───────────────────────────────────────────
# One fzf invocation for `wt`, `repo` and the herdr popup. Only the chrome is
# passed in, so a key or a mode added here reaches all three at once.

_nav_list() {
  case ${1:-place} in
    place)
      _nav_place_rows
      ;;
    agent)
      _nav_agent_rows
      ;;
  esac
}

_nav_prompt() {
  case ${1:-place} in
    agent)
      print -r -- 'agents> '
      ;;
    *)
      print -r -- 'go> '
      ;;
  esac
}

# Called by the tab binding. The mode lives in a file because each transform
# runs in its own process.
_nav_transform_cycle() {
  local state=$1 current next
  current=$(<"$state") || current=place
  case $current in
    place)
      next=agent
      ;;
    *)
      next=place
      ;;
  esac
  print -r -- "$next" >|"$state"
  printf 'reload(zsh -c %s)+change-prompt(%s)+first\n' \
    "'$(_nav_source_cmd); _nav_list $next'" "$(_nav_prompt "$next")"
}

# Called by the ctrl-x binding. No confirmation prompt is needed: `git worktree
# remove` refuses a checkout that still holds uncommitted work. The key is live
# in every mode, so rows with nothing removable behind them - a repository, an
# agent, a workspace on a plain directory - are left alone silently.
_nav_transform_remove() {
  local entry=${1:-} target message
  [[ -n $entry ]] || return 0
  target=$(_nav_removable_path "$entry")
  [[ -n $target ]] || return 0
  if message=$(_wt_remove_external "$target" 0 2>&1); then
    printf 'reload(zsh -c %s)+change-header(removed %s)\n' \
      "'$(_nav_source_cmd); _nav_list place'" "${target:t}"
  else
    # Parentheses would end the action's argument list.
    printf 'change-header(%s)\n' "${message//[()]/ }"
  fi
  return 0
}

_nav_fzf_available() {
  command -v fzf >/dev/null 2>&1 || {
    print "${1:-nav}: fzf is not installed" >&2
    return 1
  }
}

# Pick a place and go there. $1 names the calling command (so its guard messages
# read as that command), $2 is an initial query, and the rest is fzf chrome -
# the one thing the three entry points do not share.
_nav_go() {
  local name=${1:-nav} query=${2:-} state src entry
  if (($# > 2)); then
    shift 2
  else
    set --
  fi
  _nav_fzf_available "$name" || return 1

  state=$(mktemp "${TMPDIR:-/tmp}/nav-picker.XXXXXX") || return 1
  print -r -- place >|"$state"
  src=$(_nav_source_cmd)

  entry=$(
    _nav_list place \
      | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --query "$query" \
        --prompt "$(_nav_prompt place)" \
        --header 'Tab: places / agents | ctrl-x: remove a worktree | Enter: open' \
        --preview "$src; _nav_preview {2} {3}" \
        --bind "tab:transform:zsh -c '$src; _nav_transform_cycle $state'" \
        --bind "ctrl-x:transform:zsh -c '$src; _nav_transform_remove {2}'" \
        "$@"
  )
  rm -f -- "$state"

  [[ -n $entry ]] || return 1
  _nav_open "$entry"
}

# ── commands ─────────────────────────────────────────

# wt              : pick a workspace, worktree, repository or agent and go there
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
      _nav_go wt ''
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

# repo               : the same picker, opened on the repositories
# repo <words...>    : same, with the words narrowing the listing further
# repo get <repo>    : clone into the root and cd into it (owner/repo or URL)
#
# The listing is not filtered down to repositories, it is only queried for them:
# a repository that is already open is shown as its workspace, and clearing the
# query is how the rest of the places come back.
#
# `get` and the help flags are the only reserved words; anything else is a
# query, so `repo dotfiles` narrows the picker instead of failing.
repo() {
  case ${1:-} in
    get)
      shift
      _repo_get "$@"
      ;;
    -h | --help | help)
      print 'usage: repo [<query>... | get <owner/repo|url>]'
      ;;
    *)
      _nav_go repo "repo $*"
      ;;
  esac
}
