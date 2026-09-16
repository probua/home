#!/bin/bash

# omarchy:summary=Directional swap that pulls the active window out of its group when grouped

[[ $1 == l || $1 == r || $1 == u || $1 == d ]] || exit 1

if hyprctl activewindow -j | jq -e '(.grouped | length) > 0' >/dev/null 2>&1; then
  hyprctl dispatch 'hl.dsp.window.move({ out_of_group = true })'
else
  hyprctl dispatch "hl.dsp.window.swap({ direction = \"$1\" })"
fi
