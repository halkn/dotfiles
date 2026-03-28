#!/bin/sh
# Claude Code status line

input=$(cat)

# Colors
GREEN='\033[38;2;98;198;99m'
YELLOW='\033[38;2;229;192;123m'
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
  width=8
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
      frac=$(( (pct - seg_start) * 7 / (seg_end - seg_start) ))
      case $frac in
        0) bar="${bar} "  ;;
        1) bar="${bar}⣀" ;;
        2) bar="${bar}⣄" ;;
        3) bar="${bar}⣤" ;;
        4) bar="${bar}⣦" ;;
        5) bar="${bar}⣶" ;;
        6) bar="${bar}⣷" ;;
        *) bar="${bar}⣿" ;;
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

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# Git branch
git_branch=""
if git_ref=$(git -C "${cwd:-$(pwd)}" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch=" $git_ref"
elif git_ref=$(git -C "${cwd:-$(pwd)}" rev-parse --short HEAD 2>/dev/null); then
  git_branch=" $git_ref"
fi

# Git status indicators
git_status_str=""
if [ -n "$git_branch" ]; then
  git_dir="${cwd:-$(pwd)}"
  modified=$(git -C "$git_dir" status --porcelain 2>/dev/null | grep -c '^ M\|^M ')
  untracked=$(git -C "$git_dir" status --porcelain 2>/dev/null | grep -c '^??')
  staged=$(git -C "$git_dir" status --porcelain 2>/dev/null | grep -c '^[MADRCU]')
  ahead=$(git -C "$git_dir" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  behind=$(git -C "$git_dir" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

  markers=""
  [ "$modified" -gt 0 ] 2>/dev/null && markers="${markers}*"
  [ "$untracked" -gt 0 ] 2>/dev/null && markers="${markers}?"
  [ "$staged" -gt 0 ] 2>/dev/null && markers="${markers}+"
  [ "$ahead" -gt 0 ] 2>/dev/null && markers="${markers}⇡"
  [ "$behind" -gt 0 ] 2>/dev/null && markers="${markers}⇣"

  [ -n "$markers" ] && git_status_str=" ($markers)"
fi

parts="$model"

ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx" ]; then
  parts="${parts} ${DIM}│${R} $(fmt 'ctx' "$ctx")"
fi

five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five" ]; then
  parts="${parts} ${DIM}│${R} $(fmt '5h' "$five")"
fi

week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$week" ]; then
  parts="${parts} ${DIM}│${R} $(fmt '7d' "$week")"
fi

lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

if [ -n "$git_branch" ]; then
  parts="${parts} ${DIM}│${R}\033[90m${git_branch}${git_status_str}\033[0m"
fi

if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  added=${lines_added:-0}
  removed=${lines_removed:-0}
  parts="${parts} ${DIM}│${R} \033[38;2;98;198;99m+${added}\033[0m\033[90m/\033[0m\033[38;2;224;108;117m-${removed}\033[0m"
fi

printf '%b' " $parts"
