#!/usr/bin/env bash

# Count how many lines eza --tree will print at a given depth
_eza_tree_lines() {
    depth="$1"
    dir="${2:-.}"

    # we don't care about colors here, just the line count
    eza --tree --all --group-directories-first -L "$depth" "$dir" 2>/dev/null | wc -l
}

# Dynamically choose -L based on terminal height and print the tree
eza_dynamic() {
    dir="${1:-.}"

    # Get terminal height (fallback to 24 if it fails)
    if lines="$(tput lines 2>/dev/null)"; then
        :
    else
        lines="$(stty size 2>/dev/null | awk '{print $1}')"
        [ -z "$lines" ] && lines=24
    fi

    # Leave a couple of lines for the prompt etc.
    usable_lines=$((lines - 2))
    [ "$usable_lines" -lt 1 ] && usable_lines=1

    depth=1
    current_lines="$(_eza_tree_lines "$depth" "$dir")"

    # Always show at least depth 1
    while :; do
        next_depth=$((depth + 1))
        next_lines="$(_eza_tree_lines "$next_depth" "$dir")"

        # Stop if:
        #  - going deeper doesn't add lines (we hit max depth), or
        #  - the next depth would overflow the screen
        if [ "$next_lines" -le "$current_lines" ] || [ "$next_lines" -gt "$usable_lines" ]; then
            break
        fi

        depth="$next_depth"
        current_lines="$next_lines"
    done

    # Now actually print, nicely formatted
    eza \
        -la \
        --tree \
        --git \
        --icons \
        --group-directories-first \
        --no-time \
        -I '.git' \
        -L "$depth" \
        "$dir"
        # --no-permissions \
        # --no-filesize \
        # --no-user \
}