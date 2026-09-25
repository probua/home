#!/bin/bash

# Variante Ubuntu de la capa Hyprland: instala bindings.lua adaptado a
# Hyprland vanilla (sin Omarchy) + looknfeel.lua compartido + los scripts
# de binds en ~/.local/bin. La instalación de Hyprland en sí queda fuera
# (config-only): si no está instalado, se avisa y se omite sin romper el
# resto del instalador.

set_hyprland_ubuntu_config() {
  if ! command -v Hyprland >/dev/null 2>&1; then
    echo "set-hyprland-ubuntu-config: Hyprland no instalado; capa omitida (instalar 0.55+ y re-ejecutar)" >&2
    return 0
  fi

  mkdir -p ~/.config/hypr
  # bindings viene de ubuntu/; looknfeel es compartido con la capa Omarchy
  for f in ubuntu/bindings.lua looknfeel.lua; do
    src="config/hypr/$f"
    dst="$HOME/.config/hypr/$(basename "$f")"
    if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
      cp "$dst" "$dst.bak.$(date +%s)"
    fi
    cat "$src" > "$dst"
  done

  mkdir -p ~/.local/bin
  for script in config/hypr/scripts/*.sh; do
    name=$(basename "$script" .sh)
    cp "$script" ~/.local/bin/"$name"
    chmod +x ~/.local/bin/"$name"
  done

  if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl reload >/dev/null 2>&1
  fi
}

set_hyprland_ubuntu_config
