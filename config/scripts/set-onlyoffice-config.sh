#!/bin/bash

# Define OnlyOffice como suite de office por defecto vía xdg-mime (estándar
# freedesktop: escribe en ~/.config/mimeapps.list). Omarchy trae LibreOffice
# de fábrica y su default vive en /usr/share/applications/mimeapps.list
# (nivel sistema); el default a nivel usuario lo pisa limpiamente.
# La instalación de OnlyOffice es manual (AUR): este script no gestiona
# paquetes; si falta, se omite con una hint de cómo instalarlo.

set_onlyoffice_config() {
  local desktop="onlyoffice-desktopeditors.desktop"
  # Mimetype sonda para el chequeo de idempotencia (.docx)
  local probe_mime="application/vnd.openxmlformats-officedocument.wordprocessingml.document"

  if ! command -v xdg-mime >/dev/null; then
    echo "set-onlyoffice-config: xdg-mime no disponible; omitido" >&2
    return 0
  fi

  if ! find /usr/share/applications ~/.local/share/applications -maxdepth 1 -name "$desktop" 2>/dev/null | grep -q .; then
    echo "set-onlyoffice-config: $desktop no encontrado (¿OnlyOffice instalado?); omitido" >&2
    echo "set-onlyoffice-config: para instalarlo:" >&2
    echo "    yay -S onlyoffice-bin" >&2
    echo "set-onlyoffice-config: para liberar espacio (opcional, quita LibreOffice):" >&2
    echo "    sudo pacman -Rns libreoffice-fresh" >&2
    return 0
  fi

  # Idempotencia: si el default ya es OnlyOffice, no escribir nada
  if [ "$(xdg-mime query default "$probe_mime")" = "$desktop" ]; then
    return 0
  fi

  xdg-mime default "$desktop" \
    "$probe_mime" \
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet \
    application/vnd.openxmlformats-officedocument.presentationml.presentation \
    application/msword \
    application/vnd.ms-excel \
    application/vnd.ms-powerpoint \
    application/vnd.oasis.opendocument.text \
    application/vnd.oasis.opendocument.spreadsheet \
    application/vnd.oasis.opendocument.presentation

  echo "set-onlyoffice-config: suite de office por defecto = $desktop (docx → $(xdg-mime query default "$probe_mime"))"
}

set_onlyoffice_config
