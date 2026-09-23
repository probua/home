#!/bin/bash

# Capa de personalización del omarchy-shell sobre el widget de workspaces:
#   fase 1 - rueda del ratón sobre el widget rota de workspace (réplica i3bar)
#   fase 2 - estilo visual: activo = número claro, resto = punto gris
#   fase 4 - rueda sobre TODA la barra rota workspace, excepto sobre los tray
#            icons (que conservan su scroll propio vía propagación del evento)
#   fase 5 - lock sobrio: clon de omarchy.lock con el wallpaper ligeramente
#            oscurecido y desaturado (entorno de trabajo)
#   fase 6 - idle sin ttfx: lock directo a los 150s, monitor off ~155s
#   fase 7 - rueda acotada: salta solo entre workspaces existentes en
#            1..12 (sin wrap en los bordes) y acumula el delta para que
#            el trackpad no dispare un cambio por cada micro-evento
#   fase 8 - rueda sin lógica temporal: elimina el cooldown y el reset
#            de gesto de la fase 7 v1 (umbral ±120 + consumo total)
#   fase 11 - lock: guard de foco reactivo — cualquier pérdida de
#            activeFocus en el campo de contraseña se re-forza al instante
#            (latencia 0, sin polling); reemplaza y subsume a las fases 9
#            y 10 (wake por mouse y timer de 300ms con su ventana de
#            pérdida de input). La (re)creación de superficie la cubre
#            upstream con Component.onCompleted + Qt.callLater
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

  # ---------- Fase 4: rueda del ratón en toda la barra ----------
  # Un MouseArea se re-parentea al contentItem de la ventana de la barra,
  # encima de todo (los WidgetButton — reloj, menú, iconos de paneles —
  # aceptan la rueda en su onWheel aunque nadie la use, así que un capturador
  # al fondo de la pila dejaría zonas muertas). Sin botones ni hover no
  # interfiere con clics, arrastres ni tooltips. La rueda solo se intercepta
  # si el punto NO cae dentro del subtree del tray: en ese caso se declina
  # (wheel.accepted = false) y el evento sigue su entrega normal, de modo que
  # los tray icons conservan su scroll (Tray.qml consume onWheel él solo).
  # Requiere `import Quickshell` (el tipo attached QsWindow no resuelve sin él).
  local NEED_IMPORT=0 NEED_AREA=0
  grep -qFx "import Quickshell" "$QML" || NEED_IMPORT=1
  grep -q "barWheelArea" "$QML" || NEED_AREA=1
  if (( NEED_IMPORT || NEED_AREA )); then
    local ANCHOR_IMPLICIT='implicitHeight: grid.implicitHeight'
    local ANCHOR_IMPORT='import Quickshell.Hyprland'
    if (( NEED_AREA )) && [[ $(grep -cF "$ANCHOR_IMPLICIT" "$QML") != 1 ]]; then
      echo "set-omarchy-shell-config: anclaje de fase 4 no único; omitida" >&2
      rm -f "$TMP"
      return 1
    fi
    if (( NEED_IMPORT )) && [[ $(grep -cF "$ANCHOR_IMPORT" "$QML") != 1 ]]; then
      echo "set-omarchy-shell-config: anclaje de import no único; fase 4 omitida" >&2
      rm -f "$TMP"
      return 1
    fi

    local SNIP4
    SNIP4=$(mktemp)
    cat >"$SNIP4" <<'EOF'

  MouseArea {
    id: barWheelArea
    parent: root.QsWindow.contentItem
    anchors.fill: parent
    z: 999
    acceptedButtons: Qt.NoButton
    hoverEnabled: false

    function itemHit(item, x, y) {
      var kids = item.children
      for (var i = kids.length - 1; i >= 0; i--) {
        var child = kids[i]
        if (!child || child === barWheelArea || !child.visible) continue
        var origin = child.mapToItem(item, 0, 0)
        var localX = x - origin.x
        var localY = y - origin.y
        if (localX < 0 || localY < 0 || localX > child.width || localY > child.height) continue
        if (child.moduleName === "omarchy.tray") return true
        if (itemHit(child, localX, localY)) return true
      }
      return false
    }

    onWheel: function(wheel) {
      if (itemHit(barWheelArea.parent, wheel.x, wheel.y)) {
        wheel.accepted = false
        return
      }
      root.focusRelativeWorkspace(wheel.angleDelta.y > 0 ? -1 : 1)
    }
  }
EOF

    awk -v need_import="$NEED_IMPORT" -v need_area="$NEED_AREA" \
        -v anchor_import="$ANCHOR_IMPORT" -v anchor_implicit="$ANCHOR_IMPLICIT" -v snip="$SNIP4" '
      {
        if (need_import && index($0, anchor_import) > 0) print "import Quickshell"
        print $0
        if (need_area && index($0, anchor_implicit) > 0) {
          while ((getline l < snip) > 0) print l
          close(snip)
        }
      }
    ' "$QML" >"$TMP" && cat "$TMP" >"$QML"
    rm -f "$SNIP4"
    patched=1
    echo "set-omarchy-shell-config: fase 4 aplicada (rueda en toda la barra)"
  fi

  # ---------- Fase 5: lock sobrio ----------
  # Clon del servicio de lock para trabajo: el wallpaper de la pantalla de
  # bloqueo se atenúa ligeramente (brightness) y desatura (saturation) via el
  # MultiEffect de LockView.qml. El clon hereda la capability `authentication`
  # (PluginRegistry la copia del origen via clonedFrom), así que PAM password
  # y fingerprint siguen intactos; el IPC `lock` rutea al clon vía
  # resolveEnabledId y el built-in pasa a disabledPlugins[] al habilitarse.
  local LOCK_PLUGIN_ID="${USER:-$(id -un)}.lock"
  local LOCK_DIR="$HOME/.config/omarchy/plugins/$LOCK_PLUGIN_ID"
  local LOCK_QML="$LOCK_DIR/LockView.qml"

  # Registro en máquina nueva: el clone habilita el clon él solo (plugins[] +
  # disabledPlugins[] en shell.json).
  if ! grep -q "\"$LOCK_PLUGIN_ID\"" "$HOME/.config/omarchy/shell.json" 2>/dev/null; then
    omarchy plugin clone omarchy.lock >/dev/null
  fi

  if [[ ! -f $LOCK_QML ]]; then
    echo "set-omarchy-shell-config: falta $LOCK_QML" >&2
    return 1
  fi

  # Converge a brightness/saturation ligeros desde cualquier estado previo:
  # clones nuevos (stock) insertan ambas líneas tras el ancla contrast, e
  # instalaciones que ya traían el oscurecido fuerte (-0.55/-0.3) lo corrigen
  # en sitio sin duplicar. Marker de aplicado: `brightness: -0.1`.
  if ! grep -qF "brightness: -0.1" "$LOCK_QML"; then
    local ANCHOR_CONTRAST='contrast: -0.08'
    if [[ $(grep -cF "$ANCHOR_CONTRAST" "$LOCK_QML") != 1 ]]; then
      echo "set-omarchy-shell-config: anclaje de fase 5 no único; omitida" >&2
      rm -f "$TMP"
      return 1
    fi

    if grep -qE '^[[:space:]]*brightness:' "$LOCK_QML"; then
      awk '
        /^[ \t]*brightness:/ { print "      brightness: -0.1"; next }
        /^[ \t]*saturation:/ { print "      saturation: -0.15"; next }
        { print }
      ' "$LOCK_QML" >"$TMP"
    else
      awk -v anchor="$ANCHOR_CONTRAST" '
        {
          print
          if (index($0, anchor) > 0) {
            print "      brightness: -0.1"
            print "      saturation: -0.15"
          }
        }
      ' "$LOCK_QML" >"$TMP"
    fi
    cat "$TMP" >"$LOCK_QML"
    patched=1
    echo "set-omarchy-shell-config: fase 5 aplicada (lock sobrio: wallpaper ligeramente oscurecido)"
  fi

  # ---------- Fase 6: idle — lock directo, sin screensaver ttfx ----------
  # lock a los 150s y screensaver a los 300s: como el lock llega primero, el
  # guard isLocked de omarchy-launch-screensaver impide que ttfx arranque
  # durante idle, y el monitor se apaga ~5s después del lock (blank del lock).
  # screensaver debe ser MAYOR que lock: con ambos iguales disparan a la vez
  # y los terminales de ttfx parpadearían justo antes de que el lock los mate.
  # Escritura in-place (sin sustituir el inode) porque el shell watchea el
  # archivo; el cambio hot-recarga sin reinicio.
  if command -v jq >/dev/null 2>&1 && [[ -f $HOME/.config/omarchy/shell.json ]]; then
    if ! jq -e '(.idle.screensaver // 0) == 300 and (.idle.lock // 0) == 150' \
        "$HOME/.config/omarchy/shell.json" >/dev/null 2>&1; then
      local TMPJSON
      TMPJSON=$(mktemp)
      jq '.idle = ((.idle // {}) + {screensaver: 300, lock: 150})' \
        "$HOME/.config/omarchy/shell.json" >"$TMPJSON" && \
        cat "$TMPJSON" >"$HOME/.config/omarchy/shell.json"
      rm -f "$TMPJSON"
      echo "set-omarchy-shell-config: idle ajustado (lock 150s directo, ttfx nunca en idle)"
    fi
  else
    echo "set-omarchy-shell-config: shell.json/jq no disponibles; fase idle omitida" >&2
  fi

  # ---------- Fase 7: rueda acotada (1..12, existentes) + umbral trackpad ----------
  # focusRelativeWorkspace pasa de e±1 (relativo sin límite, envuelve) a
  # saltar entre workspaces EXISTENTES dentro de 1..12: se construye la
  # lista real desde Hyprland.workspaces.values (sin el seed 1..5 que usa
  # workspaceIds() para pintar botones) y se salta al id adyacente en la
  # dirección dada; en los bordes no hay wrap: la rueda simplemente para.
  # Trackpad: un gesto emite decenas de micro-deltas (±5..30) y cada una
  # cambiaba de workspace. rotateWorkspace() acumula el delta y solo
  # dispara al superar el umbral de un click de rueda (±120), consumiendo
  # todo el acumulado al disparar (sin lógica temporal; ver fase 8).
  local A1='? "+1" : "-1"'
  local A2='readonly property real trailingGap'
  local A3='onWheelMoved: function(delta) { root.focusRelativeWorkspace(delta > 0 ? -1 : 1) }'
  local A4='root.focusRelativeWorkspace(wheel.angleDelta.y > 0 ? -1 : 1)'
  if ! grep -q "rotateWorkspace" "$QML"; then
    local a
    for a in "$A1" "$A2" "$A3" "$A4"; do
      if [[ $(grep -cF "$a" "$QML") != 1 ]]; then
        echo "set-omarchy-shell-config: anclaje de fase 7 no único: $a; omitida" >&2
        rm -f "$TMP"
        return 1
      fi
    done

    local SNIP7A SNIP7B
    SNIP7A=$(mktemp)
    SNIP7B=$(mktemp)
    cat >"$SNIP7A" <<'EOF'
    var cur = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    if (!cur || cur < 1 || cur > 12) return
    var ids = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id >= 1 && id <= 12 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(l, r) { return l - r })
    var idx = ids.indexOf(cur)
    if (idx === -1) return
    var next = idx + (offset > 0 ? 1 : -1)
    if (next < 0 || next >= ids.length) return
    root.focusWorkspace(ids[next])
EOF
    cat >"$SNIP7B" <<'EOF'
  property real wheelAccum: 0

  function rotateWorkspace(delta) {
    root.wheelAccum += delta
    if (Math.abs(root.wheelAccum) < 120) return
    var off = root.wheelAccum > 0 ? -1 : 1
    root.wheelAccum = 0
    root.focusRelativeWorkspace(off)
  }

EOF

    awk -v a1="$A1" -v a2="$A2" -v a3="$A3" -v a4="$A4" \
        -v snip7a="$SNIP7A" -v snip7b="$SNIP7B" '
      {
        line = $0
        if (index(line, a1) > 0) {
          while ((getline l < snip7a) > 0) print l
          close(snip7a)
          next
        }
        if (index(line, a3) > 0) {
          print "        onWheelMoved: function(delta) { root.rotateWorkspace(delta) }"
          next
        }
        if (index(line, a4) > 0) {
          print "      root.rotateWorkspace(wheel.angleDelta.y)"
          next
        }
        if (index(line, a2) > 0) {
          while ((getline l < snip7b) > 0) print l
          close(snip7b)
          print line
          next
        }
        print line
      }
    ' "$QML" >"$TMP" && cat "$TMP" >"$QML"
    rm -f "$SNIP7A" "$SNIP7B"
    patched=1
    echo "set-omarchy-shell-config: fase 7 aplicada (rueda acotada 1..12 + umbral trackpad)"
  fi

  # ---------- Fase 8: rueda sin lógica temporal ----------
  # La fase 7 v1 gateaba los disparos con cooldown (150ms) y reset de
  # gesto (300ms); en la práctica el cooldown se siente mal. Se elimina
  # toda la lógica temporal: queda la acumulación pura con umbral ±120
  # (un click de rueda) y consumo total del acumulado al disparar. Las
  # ráfagas se coalescen solas porque Hyprland.focusedWorkspace se
  # actualiza de forma asíncrona (IPC) entre disparos consecutivos.
  # Marcador: lastWheelTs (presente solo en la fase 7 v1); en máquinas
  # nuevas la fase 7 ya inserta la versión final y esto no actúa.
  local D1='  property real lastRotateTs: 0'
  local D2='  property real lastWheelTs: 0'
  local D3='    var now = Date.now()'
  local D4='    if (now - root.lastWheelTs > 300) root.wheelAccum = 0'
  local D5='    root.lastWheelTs = now'
  local D6='    if (now - root.lastRotateTs < 150) return'
  local D7='    root.lastRotateTs = now'
  if grep -q "lastWheelTs" "$QML"; then
    local d
    for d in "$D1" "$D2" "$D3" "$D4" "$D5" "$D6" "$D7"; do
      if [[ $(grep -cF "$d" "$QML") != 1 ]]; then
        echo "set-omarchy-shell-config: anclaje de fase 8 no único: $d; omitida" >&2
        rm -f "$TMP"
        return 1
      fi
    done

    awk -v d1="$D1" -v d2="$D2" -v d3="$D3" -v d4="$D4" \
        -v d5="$D5" -v d6="$D6" -v d7="$D7" '
      {
        if ($0 == d1 || $0 == d2 || $0 == d3 || $0 == d4 ||
            $0 == d5 || $0 == d6 || $0 == d7) next
        print
      }
    ' "$QML" >"$TMP" && cat "$TMP" >"$QML"
    patched=1
    echo "set-omarchy-shell-config: fase 8 aplicada (rueda sin cooldown ni reset de gesto)"
  fi

  # ---------- Fase 11: guard de foco reactivo del password ----------
  # Reemplaza las fases 9 y 10: en vez de perseguir cada camino de wake
  # (mouse) o sondear con timer (300ms, con su ventana de pérdida de
  # input), se reacciona al síntoma común a todos: la pérdida de
  # activeFocus del campo mientras el item vive dispara
  # onActiveFocusChanged y el handler re-forza el foco al instante
  # (latencia 0, sin polling, sin gate de visible: si el foco se pierde
  # durante el blank, queda reparado antes del wake). La recreación de
  # superficie (resume/tapa) la cubre upstream con Component.onCompleted +
  # Qt.callLater; el hueco teórico restante (teclas en el mismo tick de
  # creación, antes de que corra el onCompleted) es incerrable desde QML.
  # Solo hay un LockView interactivo (inputEnabled en Service.qml); el de
  # preview lo tiene a false y queda inerte, así que no hay guerra de focos.
  # Marcador de aplicado: la línea onActiveFocusChanged del TextInput.
  local OLD_POS9='onPositionChanged: { root.wakeRequested(); root.forcePasswordFocus() }'
  local STOCK_POS9='onPositionChanged: root.wakeRequested()'
  local ANCHOR_KEYS='Keys.onPressed: function(event) {'
  local NEW_FOCUS='onActiveFocusChanged: if (!activeFocus && root.inputEnabled) root.forcePasswordFocus()'

  # Migración desde fases 9+10 (máquinas que ya las tenían aplicadas):
  # 1) revertir el parche de fase 9 a la línea stock del MouseArea.
  if grep -qF "$OLD_POS9" "$LOCK_QML"; then
    awk -v old_pos="$OLD_POS9" -v stock_pos="$STOCK_POS9" '
      {
        line = $0
        pos = index(line, old_pos)
        if (pos > 0) {
          print substr(line, 1, pos - 1) stock_pos substr(line, pos + length(old_pos))
          next
        }
        print line
      }
    ' "$LOCK_QML" >"$TMP" && cat "$TMP" >"$LOCK_QML"
    patched=1
    echo "set-omarchy-shell-config: fase 11 migración (fase 9 revertida a stock)"
  fi

  # 2) eliminar el bloque Timer focusGuard de la fase 10 (buffer desde
  #    "  Timer {" hasta su "  }": solo se dropea si contiene
  #    id: focusGuard, junto al blanco que la inserción original añadió
  #    tras el bloque; cualquier otro Timer a nivel de root se respeta).
  if grep -q "id: focusGuard" "$LOCK_QML"; then
    awk '
      {
        if (!buffering && $0 == "  Timer {") {
          buffering = 1
          buf = $0 "\n"
          next
        }
        if (buffering) {
          buf = buf $0 "\n"
          if ($0 == "  }") {
            buffering = 0
            if (buf ~ /id: focusGuard/) {
              if ((getline nxt) > 0 && nxt != "") print nxt
            } else {
              printf "%s", buf
            }
          }
          next
        }
        print
      }
    ' "$LOCK_QML" >"$TMP" && cat "$TMP" >"$LOCK_QML"
    patched=1
    echo "set-omarchy-shell-config: fase 11 migración (focusGuard de fase 10 eliminado)"
  fi

  # 3) aplicar el guard reactivo (fresh clone o máquina sin el parche).
  if ! grep -qF "$NEW_FOCUS" "$LOCK_QML"; then
    if [[ $(grep -cF "$ANCHOR_KEYS" "$LOCK_QML") != 1 ]]; then
      echo "set-omarchy-shell-config: anclaje de fase 11 no único; omitida" >&2
    else
      awk -v anchor="$ANCHOR_KEYS" -v new_focus="$NEW_FOCUS" '
        {
          if (index($0, anchor) > 0) {
            match($0, /^ */)
            print substr($0, 1, RLENGTH) new_focus
          }
          print
        }
      ' "$LOCK_QML" >"$TMP" && cat "$TMP" >"$LOCK_QML"
      patched=1
      echo "set-omarchy-shell-config: fase 11 aplicada (guard de foco reactivo del password)"
    fi
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
