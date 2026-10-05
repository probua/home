#!/bin/bash

# omarchy:summary=Reorder active tab inside its group (l/r one step, u/d to first/last); directional swap when ungrouped

[[ $1 == l || $1 == r || $1 == u || $1 == d ]] || exit 1

ACTIVE=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')
[[ -n $ACTIVE ]] || exit 1

# Índice de la ventana activa dentro de su propio grupo (-1 si no agrupada).
# El array grouped de un miembro lista al grupo entero incluyéndose.
tab_index() {
  hyprctl clients -j | jq -r --arg a "$1" \
    '([.[] | select(.address == $a)][0].grouped // []) | to_entries | map(select(.value == $a)) | .[0].key // -1'
}

group_size() {
  hyprctl clients -j | jq -r --arg a "$1" \
    '([.[] | select(.address == $a)][0].grouped | length)'
}

IDX=$(tab_index "$ACTIVE")
if (( IDX >= 0 )); then
  # Agrupada: reordenar tabs en vez de sacar del grupo. move_window toma un
  # booleano forward (los strings direction se ignoran y defaultean a
  # adelante): false = una tab a la izquierda, true = una a la derecha.
  # Actúa sobre la ventana activa y el foco queda en ella (nativo, atómico).
  # En los bordes no se dispacha (Hyprland wrapearía al otro extremo).
  case $1 in
    l) (( IDX == 0 )) || hyprctl dispatch 'hl.dsp.group.move_window({ forward = false })' >/dev/null ;;
    r) (( IDX == $(($(group_size "$ACTIVE") - 1)) )) || hyprctl dispatch 'hl.dsp.group.move_window({ forward = true })' >/dev/null ;;
    u) for (( _i=0; _i<$(group_size "$ACTIVE"); _i++ )); do
         (( $(tab_index "$ACTIVE") == 0 )) && break
         hyprctl dispatch 'hl.dsp.group.move_window({ forward = false })' >/dev/null
       done ;;
    d) for (( _i=0; _i<$(group_size "$ACTIVE"); _i++ )); do
         (( $(tab_index "$ACTIVE") == $(($(group_size "$ACTIVE") - 1)) )) && break
         hyprctl dispatch 'hl.dsp.group.move_window({ forward = true })' >/dev/null
       done ;;
  esac
else
  hyprctl dispatch "hl.dsp.window.swap({ direction = \"$1\" })" >/dev/null
fi
