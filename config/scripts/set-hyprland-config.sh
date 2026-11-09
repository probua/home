#!/bin/bash

# Despliega la capa Hyprland del repo: bindings.lua, looknfeel.lua y los
# scripts de config/hypr/scripts/ hacia ~/.local/bin. Además retira el
# require de los workspaces de nwg-displays de ~/.config/hypr/hyprland.lua
# y alinea los bloques de workspace por identidad de monitor con la
# prioridad de esta máquina (ver fases más abajo). Idempotente: sin delta
# no escribe, no recarga, no imprime nada.

CHANGED=0

mkdir -p ~/.config/hypr
if [ -f ~/.config/hypr/bindings.lua ] && ! cmp -s config/hypr/bindings.lua ~/.config/hypr/bindings.lua; then
  cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)
fi
if ! cmp -s config/hypr/bindings.lua ~/.config/hypr/bindings.lua 2>/dev/null; then
  cat config/hypr/bindings.lua > ~/.config/hypr/bindings.lua
  CHANGED=1
fi

if [ -f ~/.config/hypr/looknfeel.lua ] && ! cmp -s config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua; then
  cp ~/.config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua.bak.$(date +%s)
fi
if ! cmp -s config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua 2>/dev/null; then
  cat config/hypr/looknfeel.lua > ~/.config/hypr/looknfeel.lua
  CHANGED=1
fi

mkdir -p ~/.local/bin
for script in config/hypr/scripts/*.sh; do
  name=$(basename "$script" .sh)
  if ! cmp -s "$script" ~/.local/bin/"$name" 2>/dev/null; then
    cp "$script" ~/.local/bin/"$name"
    chmod +x ~/.local/bin/"$name"
    CHANGED=1
  fi
done

# Fase: retirar la carga de los workspaces de nwg-displays.
# Omarchy 4.5+ trae su propio sistema de workspaces por monitor
# (default/hypr/monitor-workspaces.lua): cada monitor es dueño de un bloque
# contiguo de 10 workspaces, asignado por identidad física y persistido en
# ~/.local/state/omarchy/monitor-workspaces; su reconcile() corre en CADA
# hyprctl reload moviendo/renumerando todo workspace ocupado que no esté
# en el monitor dueño de su bloque. Las reglas nwg-displays (1-9→DP-1,
# 10→HDMI-A-1) contradecían la asignación real de bloques (HDMI=bloque 0):
# cada reload renumeraba ws 1-4 → 11-14, "perdiendo" las ventanas de sus
# workspaces (post-mortem completo en MIGRATION-omarchy.md). El require
# queda retirado: las reglas dejan de cargar y de pelear con reconcile.
# Idempotente por ausencia; escritura in-place (cat) para no despistar el
# inotify de Hyprland.
HYPR_LUA="$HOME/.config/hypr/hyprland.lua"
if [ -f "$HYPR_LUA" ] && grep -q 'package\.searchpath("hypr\.workspaces"' "$HYPR_LUA"; then
  if [ "$(grep -c 'package\.searchpath("hypr\.workspaces"' "$HYPR_LUA")" != "1" ]; then
    echo "set-hyprland-config: require nwg presente más de una vez, se omite la retirada" >&2
  elif awk '
    /^-- Cargar los workspaces generados por nwg-displays si existen/ { next }
    /^-- máquina limpia todavía no\)\. Parche aplicado por set-hyprland-config\.sh\.$/ { next }
    /^if package\.searchpath\("hypr\.workspaces", package\.path\) then require\("hypr\.workspaces"\) end$/ { next }
    { print }
  ' "$HYPR_LUA" > "$HYPR_LUA.tmp" 2>/dev/null; then
    cp "$HYPR_LUA" "$HYPR_LUA.bak.$(date +%s)"
    cat "$HYPR_LUA.tmp" > "$HYPR_LUA"
    rm -f "$HYPR_LUA.tmp"
    CHANGED=1
    echo "set-hyprland-config: retirado el require de workspaces nwg-displays" >&2
  else
    rm -f "$HYPR_LUA.tmp"
    echo "set-hyprland-config: falló la retirada del require nwg" >&2
  fi
fi

# Fase: alinear los bloques de workspace con la prioridad de monitores.
# La primaria (GIGA-BYTE GS27Q, en DP-1) debe ser bloque 0 → ws 1-10, y la
# secundaria (LG FULL HD, HDMI-A-1) bloque 1 → ws 11-20 (en uso: 11-12,
# binds SUPER+NTILDE/P). El sistema identifica monitores por identidad
# física, así que la asignación sobrevive a cambios de puerto o dock; este
# guard solo fuerza la prioridad si encuentra AMBAS identidades: en otra
# máquina (laptop, otros monitores) se omite y Omarchy asigna solo (un
# monitor único toma el bloque 0 = ws 1-10, correcto sin tocar nada). El
# state file también lo escribe el propio Omarchy al asignar; esta
# escritura es convergente con la suya (mismo contenido → cmp implícito
# por el guard, no-op en re-runs).
MW_STATE="$HOME/.local/state/omarchy/monitor-workspaces"
if [ -f "$MW_STATE" ]; then
  primaria=$(awk -F'\t' '$3 ~ /GIGA-BYTE/ {print $1}' "$MW_STATE" | head -1)
  secundaria=$(awk -F'\t' '$3 ~ /LG Electronics/ {print $1}' "$MW_STATE" | head -1)
  if [ -n "$primaria" ] && [ -n "$secundaria" ] && { [ "$primaria" != "0" ] || [ "$secundaria" != "1" ]; }; then
    cp "$MW_STATE" "$MW_STATE.bak.$(date +%s)"
    awk -F'\t' -v OFS='\t' '{
      if ($3 ~ /GIGA-BYTE/) $1 = 0
      else if ($3 ~ /LG Electronics/) $1 = 1
      print
    }' "$MW_STATE" > "$MW_STATE.tmp" && cat "$MW_STATE.tmp" > "$MW_STATE"
    rm -f "$MW_STATE.tmp"
    CHANGED=1
    echo "set-hyprland-config: bloques alineados (GIGA-BYTE/DP-1=ws 1-10, LG/HDMI-A-1=ws 11-20)" >&2
  fi
fi

# Efectos secundarios solo si hubo delta.
if [ "$CHANGED" -eq 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  hyprctl reload >/dev/null 2>&1
fi
