#!/usr/bin/env bash

# scripts/recompile.sh
#
# Re-run the most recent compile command.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

history_file="${TMUX_COMPILE_HISTORY:-$HOME/.tmux-compile-history}"

last_cmd=$(tail -n 1 "$history_file" 2>/dev/null)

if [ -z "$last_cmd" ]; then
    tmux display-message "No previous compile command"
    exit 0
fi

"$CURRENT_DIR/run-compile.sh" "$last_cmd"

exit 0
