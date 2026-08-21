#!/usr/bin/env bash

set -e

current=$(hyprctl activeworkspace -j | jq '.id' -r)
monitor=$(hyprctl activeworkspace -j | jq '.monitorID' -r)

prev=$(hyprctl workspaces -j | 
    jq \
        --argjson current "$current" \
        --argjson monitor "$monitor" \
        '(
            map(
                select(.monitorID == $monitor and .id < $current)
            ) | sort_by(.id) | reverse
        ) 
        as $filtered | 
        if ($filtered | length) > 0 
            then $filtered[0].id 
            else $current 
        end')

echo $prev
exit

hyprctl dispatch workspace "$prev"