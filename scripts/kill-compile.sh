#!/usr/bin/env bash

# scripts/kill-compile.sh
#
# Terminate the compile pane if it exists.

current_window=$(tmux display-message -p '#{window_id}')

compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' 2>/dev/null | \
    awk '$2=="compile" {print $1}')

if [ -n "$compile_pane" ]; then
    tmux kill-pane -t "$compile_pane"
else
    tmux display-message "No compile pane found"
fi

exit 0
