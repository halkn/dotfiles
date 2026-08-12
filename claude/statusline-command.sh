#!/bin/sh
# Claude Code status line

input=$(cat)

# Colors
GREEN='\033[38;2;98;198;99m'
YELLOW='\033[38;2;229;192;123m'
ORANGE='\033[38;2;210;130;50m'
RED='\033[38;2;224;108;117m'
DIM='\033[2m'
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

# Braille progress bar (8 segments)
# BRAILLE: ' ⣀⣄⣤⣦⣶⣷⣿' (indices 0-7)
braille_bar() {
  pct=$1
  width=4
  # Clamp 0-100
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100

  bar=''
  i=0
  while [ $i -lt $width ]; do
    # seg_start = i * 100 / width, seg_end = (i+1) * 100 / width  (integer math, *100 to avoid floats)
    seg_start=$((i * 100 / width))
    seg_end=$(((i + 1) * 100 / width))

    if [ "$pct" -ge "$seg_end" ]; then
      bar="${bar}⣿"
    elif [ "$pct" -le "$seg_start" ]; then
      bar="${bar} "
    else
      frac=$(((pct - seg_start) * 7 / (seg_end - seg_start)))
      case $frac in
        0)
          bar="${bar} "
          ;;
        1)
          bar="${bar}⣀"
          ;;
        2)
          bar="${bar}⣄"
          ;;
        3)
          bar="${bar}⣤"
          ;;
        4)
          bar="${bar}⣦"
          ;;
        5)
          bar="${bar}⣶"
          ;;
        6)
          bar="${bar}⣷"
          ;;
        *)
          bar="${bar}⣿"
          ;;
      esac
    fi
    i=$((i + 1))
  done

  printf '%s' "$bar"
}

fmt() {
  label=$1
  pct=$2
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null || echo "${pct%%.*}")
  col=$(color_for_pct "$pct_int")
  bar=$(braille_bar "$pct_int")
  printf '%b%s%b %b%s%b %d%%' "$DIM" "$label" "$R" "$col" "$bar" "$R" "$pct_int"
}

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
} <<EOF
$(printf '%s' "$input" | jq -r '
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
    (.cost.total_lines_removed // "")
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
    medium)
      effort_col="$GREEN"
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

# Epoch seconds; date +%s works on both GNU and BSD date.
now=$(date +%s)

reset_in() {
  # $1 = resets_at epoch seconds (may be empty/float)
  resets_at=$1
  [ -z "$resets_at" ] && return
  resets_at=${resets_at%%.*}
  diff=$((resets_at - now))
  [ "$diff" -le 0 ] && return
  h=$((diff / 3600))
  m=$(((diff % 3600) / 60))
  printf ' %dh%dm' "$h" "$m"
}

if [ -n "$five" ]; then
  five_reset_str=$(reset_in "$five_resets_at")
  parts="${parts} ${DIM}│${R} $(fmt '5h' "$five")${DIM}${five_reset_str}${R}"
fi

if [ -n "$week" ]; then
  week_reset_str=$(reset_in "$week_resets_at")
  parts="${parts} ${DIM}│${R} $(fmt '7d' "$week")${DIM}${week_reset_str}${R}"
fi

if [ -n "$git_branch" ]; then
  parts="${parts} ${DIM}│${R}\033[90m${git_branch}${git_status_str}\033[0m"
fi

if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  added=${lines_added:-0}
  removed=${lines_removed:-0}
  parts="${parts} ${DIM}│${R} \033[38;2;98;198;99m+${added}\033[0m\033[90m/\033[0m\033[38;2;224;108;117m-${removed}\033[0m"
fi

printf '%b' " $parts"
