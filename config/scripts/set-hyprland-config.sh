#!/bin/bash

# Despliega la capa Hyprland del repo: bindings.lua, looknfeel.lua y los
# scripts de config/hypr/scripts/ hacia ~/.local/bin. Además parchea
# ~/.config/hypr/hyprland.lua para que cargue los workspaces que genera
# nwg-displays (ver fase más abajo). Idempotente: sin delta no escribe,
# no recarga, no imprime nada.

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

# Fase: cargar los workspaces de nwg-displays.
# nwg-displays escribe ~/.config/hypr/workspaces.lua al hacer Apply, pero el
# hyprland.lua stock de Omarchy nunca lo requiere: sin este parche las reglas
# workspace→monitor son un archivo muerto y Hyprland asigna cada workspace al
# monitor que lo crea/enfoca. Se usa package.searchpath para tolerar la
# ausencia del archivo (máquina limpia donde nwg-displays aún no corrió) sin
# tragar los errores del propio archivo, como haría pcall. Escritura in-place
# (cat) para no despistar el inotify de Hyprland.
HYPR_LUA="$HOME/.config/hypr/hyprland.lua"
if [ ! -f "$HYPR_LUA" ]; then
  echo "set-hyprland-config: hyprland.lua inexistente, se omite la fase workspaces" >&2
elif grep -q 'hypr\.workspaces' "$HYPR_LUA"; then
  : # Fase ya aplicada: re-run silencioso.
elif [ "$(grep -cE '^require\("hypr\.monitors"\)$' "$HYPR_LUA")" != "1" ]; then
  # Anclaje ausente o no único: deriva del stock de Omarchy (p. ej. tras un
  # `omarchy refresh hyprland`). No romper el estado existente: avisar y omitir.
  echo "set-hyprland-config: anclaje require(\"hypr.monitors\") ausente o no único, se omite la fase workspaces" >&2
elif awk '
  { print }
  /^require\("hypr\.monitors"\)$/ {
    print "-- Cargar los workspaces generados por nwg-displays si existen (en una"
    print "-- máquina limpia todavía no). Parche aplicado por set-hyprland-config.sh."
    print "if package.searchpath(\"hypr.workspaces\", package.path) then require(\"hypr.workspaces\") end"
  }
' "$HYPR_LUA" > "$HYPR_LUA.tmp" 2>/dev/null; then
  cp "$HYPR_LUA" "$HYPR_LUA.bak.$(date +%s)"
  cat "$HYPR_LUA.tmp" > "$HYPR_LUA"
  rm -f "$HYPR_LUA.tmp"
  CHANGED=1
  echo "set-hyprland-config: parche de workspaces aplicado a hyprland.lua" >&2
else
  rm -f "$HYPR_LUA.tmp"
  echo "set-hyprland-config: falló la generación del parche de workspaces" >&2
fi

# Efectos secundarios solo si hubo delta.
if [ "$CHANGED" -eq 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  hyprctl reload >/dev/null 2>&1
fi
