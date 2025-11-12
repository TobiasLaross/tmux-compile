#!/usr/bin/env bash

# scripts/utils/get-history-file.sh
#
# Returns the session-aware history file path

set -euo pipefail
base_history_dir="${TMUX_COMPILE_HISTORY_DIR:-$HOME/.tmux-compile-history}"
session_name="$(tmux display-message -p '#S' 2>/dev/null || echo default)"

# Delete base_dir if it is a file
if [ -f "$base_history_dir" ]; then
    rm "$base_history_dir"
fi

mkdir -p "$base_history_dir"

# Ensure history file exists
touch "$base_history_dir/$session_name"

echo "$base_history_dir/$session_name"
