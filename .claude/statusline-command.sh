#!/bin/sh
# Claude Code status line - inspired by Starship prompt configuration

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# User and host
user=$(whoami)
host=$(hostname -s)

# Directory: show ~ for home
if [ -n "$cwd" ]; then
  home="$HOME"
  case "$cwd" in
    "$home"*) dir="~${cwd#$home}" ;;
    *) dir="$cwd" ;;
  esac
else
  dir=$(pwd)
  home="$HOME"
  case "$dir" in
    "$home"*) dir="~${dir#$home}" ;;
  esac
fi

# Git branch (matching Starship's git_branch module)
git_branch=""
if git_ref=$(git -C "${cwd:-$(pwd)}" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch=" $git_ref"
elif git_ref=$(git -C "${cwd:-$(pwd)}" rev-parse --short HEAD 2>/dev/null); then
  git_branch=" $git_ref"
fi

# Git status indicators (matching Starship's git_status module)
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

# Context usage
ctx_str=""
if [ -n "$used_pct" ]; then
  ctx_str=" ctx:${used_pct}%"
fi

# Model (short name)
model_str=""
if [ -n "$model" ]; then
  model_str=" $model"
fi

# Build output using printf with ANSI colors (dimmed-friendly)
printf "\033[32m%s@%s\033[0m \033[34m%s\033[0m\033[90m%s%s\033[0m\033[33m%s\033[0m\033[36m%s\033[0m" \
  "$user" "$host" \
  "$dir" \
  "$git_branch" "$git_status_str" \
  "$ctx_str" \
  "$model_str"
