#!/bin/bash

# Capa de personalización del omarchy-shell sobre el widget de workspaces:
#   fase 1 - rueda del ratón sobre el widget rota de workspace (réplica i3bar)
#   fase 2 - estilo visual: activo = número claro, resto = punto gris
# Mecanismo: clon oficial del widget + parches mínimos con anclajes,
# idempotentes por fase y con detección de deriva upstream. Escrituras
# in-place (sin sustituir el inode, para no despistar al watcher del shell)
# y reinicio del shell solo cuando se aplicó algún parche.

# Override a nivel de máquina del omarchy-shell (gana al tema activo y
# hot-recarga): barra de 28px para que la frontera ventana↔barra caiga en
# píxel físico exacto con scale 1.25 (836×1.25=1045) y eliminar la franja
# de 1-2px al cambiar de workspace (layout flush sin gaps).
install_shell_toml() {
  mkdir -p "$HOME/.config/omarchy"
  if [ -f "$HOME/.config/omarchy/shell.toml" ] && ! cmp -s config/omarchy/shell.toml "$HOME/.config/omarchy/shell.toml"; then
    cp "$HOME/.config/omarchy/shell.toml" "$HOME/.config/omarchy/shell.toml.bak.$(date +%s)"
  fi
  if ! cmp -s config/omarchy/shell.toml "$HOME/.config/omarchy/shell.toml"; then
    cat config/omarchy/shell.toml > "$HOME/.config/omarchy/shell.toml"
    echo "set-omarchy-shell-config: shell.toml instalado (barra 28px, hot-reload)"
  fi
}

set_omarchy_shell_config() {
  local SOURCE_ID="omarchy.workspaces"
  local PLUGIN_ID="${USER:-$(id -un)}.workspaces"
  local PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
  local QML="$PLUGIN_DIR/Workspaces.qml"
  local patched=0

  # Registro en máquina nueva: el clone sustituye él solo la entrada del
  # layout en shell.json (omarchy.workspaces -> <usuario>.workspaces).
  if ! grep -q "\"$PLUGIN_ID\"" "$HOME/.config/omarchy/shell.json" 2>/dev/null; then
    omarchy plugin clone "$SOURCE_ID" >/dev/null
  fi

  if [[ ! -f $QML ]]; then
    echo "set-omarchy-shell-config: falta $QML" >&2
    return 1
  fi

  local TMP
  TMP=$(mktemp)

  # ---------- Fase 1: rueda ----------
  if ! grep -q "focusRelativeWorkspace" "$QML"; then
    local ANCHOR_PROP="readonly property real trailingGap"
    local ANCHOR_PRESS="onPressed: function() { root.focusWorkspace(modelData) }"
    local anchor count
    for anchor in "$ANCHOR_PROP" "$ANCHOR_PRESS"; do
      count=$(grep -cF "$anchor" "$QML")
      if [[ $count != 1 ]]; then
        echo "set-omarchy-shell-config: anclaje no único (x$count): $anchor" >&2
        rm -f "$TMP"
        return 1
      fi
    done

    local SNIP
    SNIP=$(mktemp)
    cat >"$SNIP" <<'EOF'
  function focusRelativeWorkspace(offset) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"e" + (offset > 0 ? "+1" : "-1") + "\" })"))
  }

EOF

    awk -v prop_anchor="$ANCHOR_PROP" -v press_anchor="$ANCHOR_PRESS" -v snip="$SNIP" '
      { lines[NR] = $0 }
      END {
        for (i = 1; i <= NR; i++) {
          line = lines[i]
          if (index(line, prop_anchor) > 0) {
            while ((getline l < snip) > 0) print l
            close(snip)
          }
          print line
          if (index(line, press_anchor) > 0) {
            print "        onWheelMoved: function(delta) { root.focusRelativeWorkspace(delta > 0 ? -1 : 1) }"
          }
        }
      }
    ' "$QML" >"$TMP" && cat "$TMP" >"$QML"
    rm -f "$SNIP"
    patched=1
    echo "set-omarchy-shell-config: fase 1 aplicada (rueda)"
  fi

  # ---------- Fase 2: estilo visual ----------
  # activo = número blanco, pasivo (con ventanas, no visible) = número gris,
  # inactivo (sin ventanas) = oculto. Marker de aplicado: la línea `visible:`.
  local NEW_TEXT='text: modelData === 10 ? "0" : String(modelData)'
  local NEW_OPACITY='opacity: focused ? 1 : 0.5'
  local NEW_VISIBLE='visible: occupied || focused'

  if ! grep -qF "$NEW_VISIBLE" "$QML"; then
    # Entradas reconocidas: upstream (icono) o v1 (punto) — una línea text y una opacity
    local has_text has_op
    has_text=$(grep -cF 'text: focused ?' "$QML")
    has_op=$(( $(grep -cF 'opacity: occupied || focused' "$QML") + $(grep -cF 'opacity: focused ?' "$QML") ))
    if (( has_text != 1 )) || (( has_op != 1 )); then
      echo "set-omarchy-shell-config: estado inesperado en text/opacity (¿deriva upstream?); fase 2 omitida" >&2
      rm -f "$TMP"
      return 1
    fi

    awk -v new_text="$NEW_TEXT" -v new_op="$NEW_OPACITY" -v new_vis="$NEW_VISIBLE" '
      { lines[NR] = $0 }
      END {
        for (i = 1; i <= NR; i++) {
          l = lines[i]
          if (index(l, "text: focused ?") > 0) {
            print "        " new_text
          } else if (index(l, "opacity: occupied || focused") > 0 || index(l, "opacity: focused ?") > 0) {
            print "        " new_op
            print "        " new_vis
          } else {
            print l
          }
        }
      }
    ' "$QML" >"$TMP" && cat "$TMP" >"$QML"
    patched=1
    echo "set-omarchy-shell-config: fase 2 aplicada (estilo visual)"
  fi

  # ---------- Fase 3: workspaces 10-12 en la barra ----------
  # El filtro original (id <= 10) excluye 11/12 por completo y el 10 sale
  # como "0" (legacy SUPER+0). Amplía el rango a 12 y etiqueta literal.
  local OLD_RANGE='id > 0 && id <= 10'
  local NEW_RANGE='id > 0 && id <= 12'
  local OLD_LABEL='text: modelData === 10 ? "0" : String(modelData)'
  local NEW_LABEL='text: String(modelData)'

  if ! { grep -qF "$NEW_RANGE" "$QML" && grep -qF "$NEW_LABEL" "$QML"; }; then
    local need_range=0 need_label=0
    grep -qF "$NEW_RANGE" "$QML" || need_range=1
    grep -qF "$NEW_LABEL" "$QML" || need_label=1

    if (( need_range )) && [[ $(grep -cF "$OLD_RANGE" "$QML") != 1 ]]; then
      echo "set-omarchy-shell-config: anclaje de rango no único; fase 3 omitida" >&2
      rm -f "$TMP"
      return 1
    fi
    if (( need_label )) && [[ $(grep -cF "$OLD_LABEL" "$QML") != 1 ]]; then
      echo "set-omarchy-shell-config: anclaje de etiqueta no único; fase 3 omitida" >&2
      rm -f "$TMP"
      return 1
    fi

    awk -v old_range="$OLD_RANGE" -v new_range="$NEW_RANGE" \
        -v old_label="$OLD_LABEL" -v new_label="$NEW_LABEL" '
      {
        line = $0
        pos = index(line, old_range)
        if (pos > 0) {
          print substr(line, 1, pos - 1) new_range substr(line, pos + length(old_range))
          next
        }
        pos = index(line, old_label)
        if (pos > 0) {
          print substr(line, 1, pos - 1) new_label substr(line, pos + length(old_label))
          next
        }
        print line
      }
    ' "$QML" >"$TMP" && cat "$TMP" >"$QML"
    patched=1
    echo "set-omarchy-shell-config: fase 3 aplicada (workspaces 10-12)"
  fi

  rm -f "$TMP"

  # ---------- Recarga determinista ----------
  # El watcher del shell recarga solo, pero la instancia viva puede quedar
  # rancia tras recargas rápidas; el reinicio garantiza el resultado.
  if (( patched )); then
    omarchy-restart-shell >/dev/null 2>&1
    echo "set-omarchy-shell-config: shell reiniciado para aplicar los parches"
  fi
}

install_shell_toml
set_omarchy_shell_config
