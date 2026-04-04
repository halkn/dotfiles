#!/usr/bin/env bash
TOTAL=$(tmux display-message -p '#{window_width}')
LEFT=$((TOTAL * 3 / 10))
CWD=$(tmux display-message -p '#{pane_current_path}')

tmux send-keys 'claude' Enter
tmux split-window -h -l "$((TOTAL - LEFT))" -c "$CWD" 'nvim'
tmux select-pane -L
