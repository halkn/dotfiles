#!/bin/sh
# Claude Code status line

GREEN='\033[38;2;98;198;99m'
YELLOW='\033[38;2;229;192;123m'
ORANGE='\033[38;2;210;130;50m'
RED='\033[38;2;224;108;117m'
DIM='\033[2m'
GRAY='\033[90m'
R='\033[0m'

color_for_pct() {
  pct=$1
  if [ "$pct" -ge 80 ]; then
    printf '%s' "$RED"
  elif [ "$pct" -ge 50 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

braille_bar() {
  pct=$1
  width=4

  bar=''
  i=0
  while [ $i -lt $width ]; do
    seg_start=$((i * 100 / width))
    seg_end=$(((i + 1) * 100 / width))
    # Clamping to 0..7 also covers the empty and full cells.
    frac=$(((pct - seg_start) * 7 / (seg_end - seg_start)))
    [ "$frac" -lt 0 ] && frac=0
    [ "$frac" -gt 7 ] && frac=7
    set -- ' ' ⣀ ⣄ ⣤ ⣦ ⣶ ⣷ ⣿
    shift "$frac"
    bar="${bar}$1"
    i=$((i + 1))
  done

  printf '%s' "$bar"
}

fmt() {
  label=$1
  pct=$2
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null || echo "${pct%%.*}")
  col=$(color_for_pct "$pct_int")
  if [ "$compact" = 1 ]; then
    printf '%b%s%b %b%d%%%b' "$DIM" "$label" "$R" "$col" "$pct_int" "$R"
    return
  fi
  bar=$(braille_bar "$pct_int")
  printf '%b%s%b %b%s%b %d%%' "$DIM" "$label" "$R" "$col" "$bar" "$R" "$pct_int"
}

# Claude Code captures stdout, so the terminal width only arrives via COLUMNS.
# An unset or zero COLUMNS keeps the full layout.
compact=0
if [ "${COLUMNS:-0}" -gt 0 ] && [ "$COLUMNS" -lt 100 ]; then
  compact=1
fi

# One value per line, read back with `IFS= read -r` so that empty values keep
# their position instead of collapsing the way IFS splitting would.
{
  IFS= read -r cwd
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r thinking
  IFS= read -r ctx
  IFS= read -r five
  IFS= read -r five_resets_at
  IFS= read -r week
  IFS= read -r week_resets_at
  IFS= read -r lines_added
  IFS= read -r lines_removed
  IFS= read -r cache_observed
  IFS= read -r cache_warm
  IFS= read -r cache_expires_at
  IFS= read -r worktree
  IFS= read -r now
} <<EOF
$(jq -r '
  [
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // "Claude"),
    (.effort.level // ""),
    (.thinking.enabled // false),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.cost.total_lines_added // ""),
    (.cost.total_lines_removed // ""),
    (.prompt_cache.caching_observed // false),
    (.prompt_cache.warm // false),
    (.prompt_cache.expires_at // ""),
    (.worktree.name // .workspace.git_worktree // ""),
    (now | floor)
  ] | map(tostring) | .[]
')
EOF

# A single porcelain=v2 --branch run carries the branch name, the HEAD oid, the
# upstream distance and the per-file index/worktree state, so no further git
# process is needed. --no-optional-locks keeps the status line from touching
# index.lock while the user runs git in the same repository.
git_dir=${cwd:-$(pwd)}
git_raw=$(git --no-optional-locks -C "$git_dir" status --porcelain=v2 --branch 2>/dev/null) || git_raw=""

git_branch=""
git_status_str=""
if [ -n "$git_raw" ]; then
  {
    IFS= read -r git_head
    IFS= read -r git_oid
    IFS= read -r staged
    IFS= read -r modified
    IFS= read -r untracked
    IFS= read -r ahead
    IFS= read -r behind
  } <<EOF
$(printf '%s\n' "$git_raw" | awk '
    $1 == "#" {
      if ($2 == "branch.oid") oid = $3
      else if ($2 == "branch.head") head = $3
      else if ($2 == "branch.ab") { ahead = $3 + 0; behind = -($4 + 0) }
      next
    }
    $1 == "?" { untracked = 1; next }
    # XY status, where "." means unchanged: X is the index, Y the worktree.
    $1 == "1" || $1 == "2" || $1 == "u" {
      if (substr($2, 1, 1) != ".") staged = 1
      if (substr($2, 2, 1) != ".") modified = 1
    }
    END {
      printf "%s\n%s\n%d\n%d\n%d\n%d\n%d\n",
        head, oid, staged, modified, untracked, ahead, behind
    }
  ')
EOF

  if [ "$git_head" = "(detached)" ]; then
    git_branch=$(printf ' %.7s' "$git_oid")
  elif [ -n "$git_head" ]; then
    git_branch=" $git_head"
  fi
fi

if [ -n "$git_branch" ]; then
  markers=""
  [ "$modified" -gt 0 ] && markers="${markers}*"
  [ "$untracked" -gt 0 ] && markers="${markers}?"
  [ "$staged" -gt 0 ] && markers="${markers}+"
  [ "$ahead" -gt 0 ] && markers="${markers}⇡"
  [ "$behind" -gt 0 ] && markers="${markers}⇣"

  [ -n "$markers" ] && git_status_str=" ($markers)"
fi

parts="$model"

if [ -n "$effort" ]; then
  case "$effort" in
    low)
      effort_col="$DIM"
      ;;
    high)
      effort_col="$YELLOW"
      ;;
    xhigh)
      effort_col="$ORANGE"
      ;;
    max)
      effort_col="$RED"
      ;;
    *)
      effort_col="$GREEN"
      ;;
  esac
  parts="${parts} ${effort_col}${effort}${R}"
fi

if [ "$thinking" = "true" ]; then
  parts="${parts} ${DIM}~${R}"
fi

if [ -n "$ctx" ]; then
  parts="${parts} ${DIM}│${R} $(fmt 'ctx' "$ctx")"
fi

reset_in() {
  # $1 = resets_at epoch seconds (may be empty/float)
  resets_at=$1
  [ -z "$resets_at" ] && return
  [ "$compact" = 1 ] && return
  resets_at=${resets_at%%.*}
  diff=$((resets_at - now))
  [ "$diff" -le 0 ] && return
  h=$((diff / 3600))
  m=$(((diff % 3600) / 60))
  printf ' %dh%dm' "$h" "$m"
}

# The TTL is at most 1h, so minutes are enough. caching_observed separates a
# cache that went cold from a provider that never reports cache tokens.
if [ "$cache_warm" = "true" ] && [ -n "$cache_expires_at" ]; then
  cache_left=$(((${cache_expires_at%%.*} - now) / 60))
  if [ "$cache_left" -ge 0 ]; then
    cache_col=$GREEN
    [ "$cache_left" -lt 5 ] && cache_col=$YELLOW
    parts="${parts} ${DIM}│ cache${R} ${cache_col}${cache_left}m${R}"
  fi
elif [ "$cache_observed" = "true" ]; then
  parts="${parts} ${DIM}│ cache${R} ${GRAY}cold${R}"
fi

if [ -n "$five" ]; then
  five_reset_str=$(reset_in "$five_resets_at")
  parts="${parts} ${DIM}│${R} $(fmt '5h' "$five")${DIM}${five_reset_str}${R}"
fi

if [ -n "$week" ]; then
  week_reset_str=$(reset_in "$week_resets_at")
  parts="${parts} ${DIM}│${R} $(fmt '7d' "$week")${DIM}${week_reset_str}${R}"
fi

if [ -n "$worktree" ]; then
  parts="${parts} ${DIM}│ wt${R} ${worktree}"
fi

if [ -n "$git_branch" ]; then
  parts="${parts} ${DIM}│${R}${GRAY}${git_branch}${git_status_str}${R}"
fi

if [ "$compact" = 0 ] && { [ -n "$lines_added" ] || [ -n "$lines_removed" ]; }; then
  added=${lines_added:-0}
  removed=${lines_removed:-0}
  parts="${parts} ${DIM}│${R} ${GREEN}+${added}${R}${GRAY}/${R}${RED}-${removed}${R}"
fi

printf '%b' " $parts"
