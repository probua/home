#!/bin/bash

# Define imv como visor de imágenes por defecto vía xdg-mime (estándar
# freedesktop: escribe en ~/.config/mimeapps.list).
# La lista de tipos sale de la línea MimeType= de imv.desktop (se
# auto-mantiene), más webp/avif que imv soporta pero no declara.

set_default_image_viewer_config() {
  local desktop="imv.desktop"

  if ! command -v xdg-mime >/dev/null; then
    echo "set-default-image-viewer-config: xdg-mime no disponible; omitido" >&2
    return 0
  fi

  local desktop_file
  desktop_file=$(find /usr/share/applications ~/.local/share/applications \
    -maxdepth 1 -name "$desktop" 2>/dev/null | head -1)
  if [ -z "$desktop_file" ]; then
    echo "set-default-image-viewer-config: $desktop no encontrado (¿imv instalado?); omitido" >&2
    return 0
  fi

  # Tipos declarados por imv.desktop + webp/avif no declarados upstream
  local mimes=()
  while IFS= read -r m; do
    [ -n "$m" ] && mimes+=("$m")
  done < <(grep -oP '(?<=^MimeType=).*' "$desktop_file" | tr ';' '\n')
  mimes+=(image/webp image/avif)

  # Idempotencia: solo setear los tipos que no apunten ya a imv
  local pending=()
  for m in "${mimes[@]}"; do
    [ "$(xdg-mime query default "$m")" = "$desktop" ] || pending+=("$m")
  done
  if [ ${#pending[@]} -eq 0 ]; then
    return 0
  fi

  xdg-mime default "$desktop" "${pending[@]}"
  echo "set-default-image-viewer-config: imv por defecto para: ${pending[*]}"
}

set_default_image_viewer_config
