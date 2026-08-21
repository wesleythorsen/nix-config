#!/usr/bin/env bash

set -e

current=$(hyprctl activeworkspace -j | jq '.id' -r)
monitor=$(hyprctl activeworkspace -j | jq '.monitorID' -r)

next=$(hyprctl workspaces -j | 
    jq \
        --argjson current "$current" \
        --argjson monitor "$monitor" \
        '(
            map(
                select(.monitorID == $monitor and .id > $current)
            ) | sort_by(.id)
        ) 
        as $filtered | 
        if ($filtered | length) > 0 
            then $filtered[0].id 
            else ((map(.id) | max) + 1) end')

echo $next
exit

hyprctl dispatch workspace "$next"