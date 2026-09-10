#!/bin/bash

# omarchy:summary=Directional focus that cycles group tabs when the focused window is grouped

[[ $1 == prev || $1 == next ]] || exit 1
[[ $2 == l || $2 == r || $2 == u || $2 == d ]] || exit 1

if hyprctl activewindow -j | jq -e '(.grouped | length) > 0' >/dev/null 2>&1; then
  hyprctl dispatch "hl.dsp.group.$1()"
else
  hyprctl dispatch "hl.dsp.focus({ direction = \"$2\" })"
fi
