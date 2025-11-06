#!/usr/bin/env bash

# scripts/run-compile.sh
#
# Launch a compile command in a dedicated tmux pane.

compile_cmd="$1"

if [ -z "$compile_cmd" ]; then
    exit 0
fi

# Read configuration
height="${TMUX_COMPILE_HEIGHT:-30%}"
history_file="${TMUX_COMPILE_HISTORY:-$HOME/.tmux-compile-history}"

# Save to history
mkdir -p "$(dirname "$history_file")" 2>/dev/null
echo "$compile_cmd" >> "$history_file" 2>/dev/null || true

# Get current context - explicitly from the active pane
current_pane=$(tmux display-message -p '#{pane_id}')
current_window=$(tmux display-message -p '#{window_id}')
current_path=$(tmux display-message -p '#{pane_current_path}')

# Verify we're in a valid tmux context
if [ -z "$current_pane" ] || [ -z "$current_window" ]; then
    tmux display-message "Error: Cannot determine current pane"
    exit 1
fi

# Find existing compile pane in THIS window only
compile_pane=$(tmux list-panes -t "$current_window" -F '#{pane_id} #{@compile-pane}' 2>/dev/null | \
    awk '$2=="compile" {print $1; exit}')

# Kill old compile pane if exists
if [ -n "$compile_pane" ]; then
    tmux kill-pane -t "$compile_pane" 2>/dev/null || true
    sleep 0.05  # Brief pause for tmux cleanup
fi

# Create wrapper script to avoid escaping issues
wrapper=$(mktemp)
cat > "$wrapper" << 'WRAPPER_EOF'
#!/usr/bin/env bash
compile_cmd="$1"
current_path="$2"

# Header
printf '\033[1;36m-*- mode: compilation; default-directory: "%s" -*-\033[0m\n' "$current_path"
printf '\033[1;36mCompilation started at %s\033[0m\n\n' "$(date +'%a %b %d %H:%M:%S')"

# Run command
time eval "$compile_cmd"
exit_code=$?

# Footer
echo
if [ $exit_code -eq 0 ]; then
    printf '\033[1;32mCompilation finished at %s\033[0m\n' "$(date +'%a %b %d %H:%M:%S')"
else
    printf '\033[1;31mCompilation exited abnormally with code %d at %s\033[0m\n' $exit_code "$(date +'%a %b %d %H:%M:%S')"
fi

# Keep pane alive
read -r -p "Press Enter to close..."
WRAPPER_EOF
chmod +x "$wrapper"

# Create compile pane - explicitly target the current window
new_pane=$(tmux split-window -t "$current_window" -v -l "$height" -c "$current_path" -P -F '#{pane_id}' \
    "$wrapper '$compile_cmd' '$current_path'; rm -f '$wrapper'" 2>/dev/null)

# Verify creation
if [ -z "$new_pane" ]; then
    rm -f "$wrapper"
    tmux display-message "Error: Failed to create compile pane"
    exit 1
fi

# Mark the pane OUTSIDE its shell to avoid race conditions
tmux set-option -p -t "$new_pane" @compile-pane "compile" 2>/dev/null

# Return focus to original pane
tmux select-pane -t "$current_pane" 2>/dev/null

exit 0
