#!/bin/bash

# omarchy:summary=Group or ungroup all windows in the active workspace (floating ones get tiled into the group)

ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')
[[ $ACTIVE_WORKSPACE =~ ^-?[0-9]+$ ]] || exit 1

# Ventana activa al disparar: el foco debe volver a ella al terminar. Todo
# ocurre DENTRO del ws activo: ningún window cruza workspaces (los moves
# programáticos entre workspaces tienen bugs upstream de render con
# animaciones desactivadas; ver hyprwm/Hyprland #5430, #8090, #8349). Los
# swaps actúan sobre la ventana activa — focus_and_wait verifica que el foco
# aterrizó antes de actuar (poll corto, sin sleeps fijos).
ACTIVE_ADDR=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')

# Mapeadas del ws (flotantes incluidas) por historial de foco ascendente:
# la activa al disparar queda primera (será la primera tab).
workspace_windows() {
  hyprctl clients -j | jq -r --argjson ws "$ACTIVE_WORKSPACE" \
    'map(select(.mapped and (.workspace.id == $ws)))
     | sort_by(.focusHistoryID) | .[].address'
}

grouped_count() {
  hyprctl clients -j | jq --argjson ws "$ACTIVE_WORKSPACE" \
    '[.[] | select(.mapped and (.workspace.id == $ws))
      | select(.grouped | length > 0)] | length'
}

is_grouped() {
  hyprctl clients -j | jq -e --arg a "$1" \
    'any(.[]; .address == $a and (.grouped | length > 0))' >/dev/null
}

is_floating() {
  hyprctl clients -j | jq -e --arg a "$1" \
    'any(.[]; .address == $a and .floating)' >/dev/null
}

# Está $1 en el mismo grupo que el ancla $2? Distingue "se unió al grupo
# ancla" de "quedó en un grupo herrante".
is_with_anchor() {
  hyprctl clients -j | jq -e --arg a "$1" --arg b "$2" \
    'any(.[]; .address == $a and ((.grouped | index($b)) != null))' >/dev/null
}

# Foco verificado: los dispatches que siguen (swap) actúan sobre la ventana
# ACTIVA; sin verificación actuarían sobre la anterior. Normalmente aterriza
# al primer chequeo.
focus_and_wait() {
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$1\" })" >/dev/null
  for _ in $(seq 1 10); do
    [ "$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')" == "$1" ] && return 0
    sleep 0.01
  done
  return 1
}

# Address de una ventana geométricamente adyacente al tile del grupo del
# ancla, excluyendo miembros del grupo y a $2 (la atascada). Tolerancia 20px
# para gaps/bordes entre tiles vecinos.
neighbor_of_group() {
  local ANCHOR=$1 STUCK=$2
  hyprctl clients -j | jq -r --arg an "$ANCHOR" --arg st "$STUCK" --argjson ws "$ACTIVE_WORKSPACE" '
    def base: .mapped and (.workspace.id == $ws) and .address != $st
              and .address != $an and ((.grouped | index($an)) == null);
    (.[] | select(.address == $an)) as $g
    | ( [.[] | select(base)
               | select(((.at[0] + .size[0] - $g.at[0]) | fabs) < 20
                        or (($g.at[0] + $g.size[0] - .at[0]) | fabs) < 20)
               | select(.at[1] < $g.at[1] + $g.size[1] and .at[1] + .size[1] > $g.at[1])
               | .address]
      + [.[] | select(base)
               | select(((.at[1] + .size[1] - $g.at[1]) | fabs) < 20
                        or (($g.at[1] + $g.size[1] - .at[1]) | fabs) < 20)
               | select(.at[0] < $g.at[0] + $g.size[0] and .at[0] + .size[0] > $g.at[0])
               | .address] )
    | .[0] // empty'
}

do_ungroup() {
  # Capturar el orden de tabs de cada grupo (al extraer al último miembro el
  # grupo se disuelve, por eso se lee primero) y extraer.
  EXTRACT_ORDER=""
  for _ in $(seq 1 $((COUNT * 2))); do
    MEMBERS=$(hyprctl clients -j | jq -r --argjson ws "$ACTIVE_WORKSPACE" \
      '[.[] | select(.mapped and (.workspace.id == $ws) and (.grouped | length > 0))][0].grouped[]? // empty')
    [[ -n $MEMBERS ]] || break
    for ADDR in $MEMBERS; do
      EXTRACT_ORDER="$EXTRACT_ORDER $ADDR"
      is_grouped "$ADDR" || continue
      hyprctl dispatch "hl.dsp.window.move({ window = \"address:$ADDR\", out_of_group = true })" >/dev/null
    done
  done
  # Flotantes del lote (p. ej. grupos flotantes creados a mano) salen tiled
  for ADDR in $EXTRACT_ORDER; do
    is_floating "$ADDR" || continue
    hyprctl dispatch "hl.dsp.window.float({ window = \"address:$ADDR\" })" >/dev/null
  done
  # Ordenar los tiles al orden de tabs: selection sort por swaps explícitos
  # (el tile i-ésimo en orden de lectura — x, luego y — recibe la tab i-ésima).
  # Los swaps preservan la forma del árbol (trade-off aceptado a cambio de
  # estabilidad); el ORDEN queda garantizado. Pasadas hasta converger.
  read -ra TABS <<< "$EXTRACT_ORDER"
  for _PASS in 1 2 3; do
    SWAPPED=0
    for (( I=0; I<${#TABS[@]}; I++ )); do
      hyprctl clients -j | jq -e --arg a "${TABS[I]}" \
        'any(.[]; .address == $a)' >/dev/null || continue
      CURRENT=$(hyprctl clients -j | jq -r --argjson ws "$ACTIVE_WORKSPACE" \
        "[.[] | select(.mapped and (.workspace.id == \$ws))] | sort_by(.at[0], .at[1]) | .[$I].address // empty")
      [[ -n $CURRENT && $CURRENT != ${TABS[I]} ]] || continue
      focus_and_wait "${TABS[I]}" || continue
      hyprctl dispatch "hl.dsp.window.swap({ target = \"address:$CURRENT\" })" >/dev/null
      sleep 0.05
      SWAPPED=1
    done
    (( SWAPPED == 0 )) && break
  done
}

do_group() {
  # Snapshot antes de tilear nada para que el orden de tabs siga el historial
  # de foco original. Las flotantes se tilean para entrar al grupo (a
  # conciencia: al desagrupar salen tiled).
  WINDOWS=($(workspace_windows))
  for ADDR in "${WINDOWS[@]}"; do
    is_floating "$ADDR" || continue
    hyprctl dispatch "hl.dsp.window.float({ window = \"address:$ADDR\" })" >/dev/null
  done
  # Agrupado en pasadas: into_group exige que el grupo sea adyacente en
  # alguna dirección desde la propia ventana, y esa adyacencia mejora a
  # medida que el grupo crece — las que fallan se reintentan en la pasada
  # siguiente. La primera ventana abre el grupo (o ancla uno preexistente).
  # Grupos herrantes (p. ej. grupos parciales previos) se disuelven miembro
  # a miembro y se re-incorporan al ancla.
  PENDING=("${WINDOWS[@]}")
  ANCHORED=0
  ANCHOR_ADDR=""
  for _ in $(seq 1 "$COUNT"); do
    (( ${#PENDING[@]} == 0 )) && break
    JOINED=0
    NEXT=()
    for ADDR in "${PENDING[@]}"; do
      if (( ANCHORED == 0 )); then
        is_grouped "$ADDR" || hyprctl dispatch "hl.dsp.group.toggle({ window = \"address:$ADDR\" })" >/dev/null
        ANCHORED=1
        ANCHOR_ADDR=$ADDR
        JOINED=$((JOINED + 1))
      else
        if is_grouped "$ADDR" && ! is_with_anchor "$ADDR" "$ANCHOR_ADDR"; then
          hyprctl dispatch "hl.dsp.window.move({ window = \"address:$ADDR\", out_of_group = true })" >/dev/null
        fi
        for DIR in l r u d; do
          hyprctl dispatch "hl.dsp.window.move({ window = \"address:$ADDR\", into_group = \"$DIR\" })" >/dev/null
          is_with_anchor "$ADDR" "$ANCHOR_ADDR" && break
        done
        if ! is_with_anchor "$ADDR" "$ANCHOR_ADDR"; then
          # No es adyacente en ninguna dirección (topología del árbol):
          # intercambiarla in-place con una vecina del grupo y reintentar.
          NEIGHBOR=$(neighbor_of_group "$ANCHOR_ADDR" "$ADDR")
          if [[ -n $NEIGHBOR ]] && focus_and_wait "$ADDR"; then
            hyprctl dispatch "hl.dsp.window.swap({ target = \"address:$NEIGHBOR\" })" >/dev/null
            sleep 0.05
            for DIR in l r u d; do
              hyprctl dispatch "hl.dsp.window.move({ window = \"address:$ADDR\", into_group = \"$DIR\" })" >/dev/null
              is_with_anchor "$ADDR" "$ANCHOR_ADDR" && break
            done
          fi
        fi
        if is_with_anchor "$ADDR" "$ANCHOR_ADDR"; then
          JOINED=$((JOINED + 1))
        else
          NEXT+=("$ADDR")
        fi
      fi
    done
    # Sin progreso en una pasada completa: no insistir (evita loop infinito)
    (( JOINED > 0 )) || break
    PENDING=("${NEXT[@]}")
  done
}

COUNT=$(workspace_windows | wc -l)
(( COUNT < 2 )) && exit 0

# Convergencia con reintento: ambas ramas son idempotentes, así que si una
# race de timing (dispatches rápidos contra el compositor) deja el estado a
# medio hacer, el siguiente intento lo completa — verificado contra el
# estado final esperado, no asumido.
for _ATTEMPT in 1 2 3; do
  if [[ $(grouped_count) -eq $COUNT ]]; then
    do_ungroup
    [[ $(grouped_count) -eq 0 ]] && { MSG="Workspace ungrouped"; break; }
  else
    do_group
    if [[ $(grouped_count) -eq $COUNT ]]; then
      MSG="Workspace grouped ($COUNT windows)"
      break
    fi
    MSG="Workspace grouping incomplete"
  fi
done

# El foco vuelve a la ventana (tab) activa al momento del disparo.
[[ -n $ACTIVE_ADDR ]] && hyprctl dispatch "hl.dsp.focus({ window = \"address:$ACTIVE_ADDR\" })" >/dev/null
omarchy-notification-send -g 󰓩 "$MSG"
