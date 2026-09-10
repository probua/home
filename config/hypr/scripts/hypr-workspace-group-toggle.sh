#!/bin/bash

# omarchy:summary=Group or ungroup all tiled windows in the active workspace

ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')
[[ $ACTIVE_WORKSPACE =~ ^-?[0-9]+$ ]] || exit 1

workspace_windows() {
  hyprctl clients -j | jq -r --argjson ws "$ACTIVE_WORKSPACE" \
    'map(select(.mapped and (.workspace.id == $ws) and (.floating == false)))
     | sort_by(.focusHistoryID) | .[].address'
}

grouped_count() {
  hyprctl clients -j | jq --argjson ws "$ACTIVE_WORKSPACE" \
    '[.[] | select(.mapped and (.workspace.id == $ws) and (.floating == false))
      | select(.grouped | length > 0)] | length'
}

focus_window() {
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$1\" })" >/dev/null
}

COUNT=$(workspace_windows | wc -l)
(( COUNT < 2 )) && exit 0

if [[ $(grouped_count) -eq $COUNT ]]; then
  # Ungroup: pull windows out of groups until none is grouped
  for _ in $(seq 1 $((COUNT * 2))); do
    ADDR=$(hyprctl clients -j | jq -r --argjson ws "$ACTIVE_WORKSPACE" \
      'map(select(.mapped and (.workspace.id == $ws) and (.floating == false)))
       | map(select(.grouped | length > 0))[0].address // empty')
    [[ -n $ADDR ]] || break
    focus_window "$ADDR"
    hyprctl dispatch 'hl.dsp.window.move({ out_of_group = true })' >/dev/null
  done
  omarchy-notification-send -g 󰓩 "Workspace ungrouped"
else
  # Group: the first window opens the group, the rest join it
  FIRST=1
  for ADDR in $(workspace_windows); do
    focus_window "$ADDR"
    if (( FIRST )); then
      hyprctl dispatch 'hl.dsp.group.toggle()' >/dev/null
      FIRST=0
    else
      for DIR in l r u d; do
        hyprctl dispatch "hl.dsp.window.move({ into_group = \"$DIR\" })" >/dev/null
        if hyprctl clients -j | jq -e --arg a "$ADDR" \
          'any(.[]; .address == $a and (.grouped | length > 0))' >/dev/null; then
          break
        fi
      done
    fi
  done
  if [[ $(grouped_count) -eq $COUNT ]]; then
    omarchy-notification-send -g 󰓩 "Workspace grouped ($COUNT windows)"
  else
    omarchy-notification-send -g 󰓩 "Workspace grouping incomplete"
  fi
fi
