#!/bin/bash

# Paquetes de los repos oficiales de Arch que este repo asume ya instalados
# pero que una máquina limpia con Omarchy no trae:
#   vim           -> config/vimrc + vim-plug (set-vim-config.sh solo despliega
#                    la config, nunca instala el paquete)
#   nwg-displays  -> GUI de gestión de monitores; escribe ~/.config/hypr/
#                    monitors.{lua,conf} y workspaces.{lua,conf}. Omarchy
#                    solo carga monitors.lua (vía `require("hypr.monitors")`);
#                    workspaces.lua requiere el parche que aplica
#                    set-hyprland-config.sh y los .conf no los carga nadie
# Es el equivalente Arch de set-apt-packages-config.sh (Ubuntu/WSL) y comparte
# su interfaz: cada instalador puede sumar extras como argumentos al sourcear
# (ej: source config/scripts/set-pacman-packages-config.sh wlr-randr); también
# funciona standalone: ./set-pacman-packages-config.sh
PACKAGES=(vim nwg-displays "$@")

# Guard: sin pacman no hay nada que hacer (p.ej. al sourcear en Ubuntu/i3)
if ! command -v pacman >/dev/null 2>&1; then
  echo "set-pacman-packages-config: pacman no disponible, se omite" >&2
  return 0 2>/dev/null || exit 0
fi

# Idempotencia: instalar solo lo que falte. Se usa `pacman -T` (no
# command -v) porque el nombre del paquete y el del binario no siempre
# coinciden. Imprime los faltantes y sale 127 si están todos presentes.
MISSING=($(pacman -T "${PACKAGES[@]}" 2>/dev/null))

if [ ${#MISSING[@]} -eq 0 ]; then
  return 0 2>/dev/null || exit 0
fi

echo "set-pacman-packages-config: instalando ${MISSING[*]}" >&2
# --needed para no reinstalar, --noconfirm para no romper un instalador no
# interactivo. No se refresca la DB a propósito: un `pacman -Sy` suelto es una
# actualización parcial. Si la DB está desactualizada, pacman falla y avisamos.
if ! sudo pacman -S --needed --noconfirm "${MISSING[@]}"; then
  echo "set-pacman-packages-config: falló la instalación de ${MISSING[*]}" >&2
  echo "set-pacman-packages-config: causas probables: DB desactualizada (sudo pacman -Sy) o paquete inexistente en los repos oficiales" >&2
  return 0 2>/dev/null || exit 0
fi

echo "set-pacman-packages-config: instalados ${MISSING[*]}" >&2
