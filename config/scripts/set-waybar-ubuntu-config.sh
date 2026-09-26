#!/bin/bash

# Barra de estado waybar (variante Ubuntu): despliega config.jsonc y
# style.css versionados y (re)arranca waybar si hubo delta. Detalle
# crítico: waybar lee ~/.config/waybar/config (sin extensión) ANTES que
# config.jsonc, así que la config legacy de la era sway se respalda y se
# retira — si no, la nueva jamás carga. Sin waybar instalado, la capa se
# omite con aviso (ver MIGRATION-ubuntu.md).

set_waybar_ubuntu_config() {
  if ! command -v waybar >/dev/null 2>&1; then
    echo "set-waybar-ubuntu-config: waybar no instalado; capa omitida (instalar el kit del PPA y re-ejecutar)" >&2
    return 0
  fi

  mkdir -p ~/.config/waybar
  local changed=0
  for f in config.jsonc style.css; do
    src="config/waybar/ubuntu/$f"
    dst="$HOME/.config/waybar/$f"
    if cmp -s "$src" "$dst"; then
      continue
    fi
    if [ -f "$dst" ]; then
      cp "$dst" "$dst.bak.$(date +%s)"
    fi
    cat "$src" > "$dst"
    changed=1
  done

  # Legacy: 'config' (era sway, módulos sway/*) tiene prioridad sobre
  # config.jsonc para waybar. Respaldo + retiro; el .bak permite volver.
  if [ -f ~/.config/waybar/config ]; then
    mv ~/.config/waybar/config ~/.config/waybar/config.legacy.bak.$(date +%s)
    changed=1
  fi

  # Efectos solo con delta: relanzar waybar si corría; arrancarlo si hay
  # sesión activa (el autostart de hyprland.lua cubre futuros logins)
  if [ "$changed" = 1 ]; then
    if pgrep -x waybar >/dev/null 2>&1; then
      pkill -x waybar
      sleep 0.5
    fi
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      nohup waybar >/dev/null 2>&1 &
      disown
    fi
  fi
}

set_waybar_ubuntu_config
