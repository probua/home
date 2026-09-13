#!/bin/bash

# Define firefox como navegador por defecto vía xdg-mime (estándar
# freedesktop: escribe en ~/.config/mimeapps.list).
# No toca x-scheme-handler/mailto (se mantiene HEY para mail).

set_default_browser_config() {
  local desktop="firefox.desktop"

  if ! command -v xdg-mime >/dev/null; then
    echo "set-default-browser-config: xdg-mime no disponible; omitido" >&2
    return 0
  fi

  if ! find /usr/share/applications ~/.local/share/applications -maxdepth 1 -name "$desktop" 2>/dev/null | grep -q .; then
    echo "set-default-browser-config: $desktop no encontrado (¿firefox instalado?); omitido" >&2
    return 0
  fi

  xdg-mime default "$desktop" \
    x-scheme-handler/http \
    x-scheme-handler/https \
    x-scheme-handler/about \
    x-scheme-handler/unknown \
    text/html

  echo "set-default-browser-config: navegador por defecto = $(xdg-settings get default-web-browser)"
}

set_default_browser_config
