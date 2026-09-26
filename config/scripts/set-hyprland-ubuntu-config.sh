#!/bin/bash

# Variante Ubuntu de la capa Hyprland: instala hyprland.lua (config
# principal, base del ejemplo vanilla que cargará los módulos propios vía
# require), bindings.lua adaptado a Hyprland vanilla (sin Omarchy),
# looknfeel.lua compartido y los scripts de binds en ~/.local/bin. La
# instalación de Hyprland en sí queda fuera (config-only): si no está
# instalado, se avisa y se omite sin romper el resto del instalador.

set_hyprland_ubuntu_config() {
  if ! command -v Hyprland >/dev/null 2>&1; then
    echo "set-hyprland-ubuntu-config: Hyprland no instalado; capa omitida (instalar 0.55+ y re-ejecutar)" >&2
    return 0
  fi

  mkdir -p ~/.config/hypr
  local changed=0
  # hyprland.lua y bindings vienen de ubuntu/; looknfeel es compartido con
  # la capa Omarchy. hyprland.lua debe existir ANTES del primer login de
  # Hyprland: si no, el compositor autogenera su ejemplo sin requires y la
  # capa de hotkeys queda huérfana.
  for f in ubuntu/hyprland.lua ubuntu/bindings.lua looknfeel.lua; do
    src="config/hypr/$f"
    dst="$HOME/.config/hypr/$(basename "$f")"
    if cmp -s "$src" "$dst"; then
      continue
    fi
    if [ -f "$dst" ]; then
      cp "$dst" "$dst.bak.$(date +%s)"
    fi
    cat "$src" > "$dst"
    changed=1
  done

  mkdir -p ~/.local/bin
  for script in config/hypr/scripts/*.sh; do
    name=$(basename "$script" .sh)
    if cmp -s "$script" ~/.local/bin/"$name"; then
      continue
    fi
    cp "$script" ~/.local/bin/"$name"
    chmod +x ~/.local/bin/"$name"
    changed=1
  done

  # Efecto lateral (reload) solo si hubo delta: re-runs silenciosos
  if [ "$changed" = 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl reload >/dev/null 2>&1
  fi
}

set_hyprland_ubuntu_config
