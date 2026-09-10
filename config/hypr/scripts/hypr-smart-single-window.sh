#!/bin/bash

# omarchy:summary=Lone tiled window fills the workspace without gaps or border (i3 smart_gaps/smart_borders)

LOG="${XDG_RUNTIME_DIR:-/tmp}/hypr-smart-single.log"
exec >>"$LOG" 2>&1

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hypr-smart-single-window.lock"
flock -n 9 || exit 0

SIG=${HYPRLAND_INSTANCE_SIGNATURE:-}
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
if [[ -z $SIG || ! -S $RUNTIME/hypr/$SIG/.socket2.sock ]]; then
  SIG=$(ls -t "$RUNTIME/hypr" 2>/dev/null | head -1)
fi
SOCK="$RUNTIME/hypr/$SIG/.socket2.sock"
if [[ ! -S $SOCK ]]; then
  echo "$(date +%T) no hyprland socket; exiting"
  exit 1
fi

TOGGLES_DIR="$HOME/.local/state/omarchy/toggles/hypr"
STATE_FILE="$TOGGLES_DIR/smart-single-window.lua"

SINGLE_LUA='-- Managed by hypr-smart-single-window: lone tiled window fills the workspace.
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 0,
  },
})
'

tiled_count() {
  local ws
  ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
  [[ $ws =~ ^-?[0-9]+$ ]] || { echo 0; return; }
  hyprctl clients -j 2>/dev/null | jq --argjson ws "$ws" \
    '[.[] | select(.mapped and (.floating == false) and (.workspace.id == $ws))] | length'
}

update() {
  local count single=0
  count=$(tiled_count)
  [[ $count =~ ^[0-9]+$ ]] || count=0
  (( count == 1 )) && single=1

  if (( single )); then
    if [[ ! -f $STATE_FILE ]]; then
      mkdir -p "$TOGGLES_DIR"
      printf '%s\n' "$SINGLE_LUA" >"$STATE_FILE"
      hyprctl reload >/dev/null 2>&1
      echo "$(date +%T) single -> no gaps (focused ws)"
    fi
  elif [[ -f $STATE_FILE ]]; then
    rm -f "$STATE_FILE"
    hyprctl reload >/dev/null 2>&1
    echo "$(date +%T) multi -> gaps restored"
  fi
}

trap 'echo "$(date +%T) exiting"' EXIT
echo "$(date +%T) started (pid $$, socket $SOCK)"
update

socat -U - "$SOCK" | while read -r line; do
  case "$line" in
    workspace\>*|openwindow\>*|closewindow\>*|movewindow\>*|changefloatingmode\>*|moveworkspace\>*)
      sleep 0.05
      update
      ;;
  esac
done
