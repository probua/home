#!/bin/bash

# Paquetes apt que el config asume pero Ubuntu/WSL no trae
# (eza: dependencia de los aliases ls/l/ll de config/bash/alias).
# Cada instalador puede sumar extras como argumentos al sourcear
# (ej: install-on-ubuntu pasa "imv"); también funciona standalone:
# ./set-apt-packages-config.sh imv
# En Omarchy vienen preinstalados, por eso este script solo vive
# en los instaladores Ubuntu/WSL.
PACKAGES=(eza "$@")

# Guard: sin apt no hay nada que hacer (p.ej. al sourcear en Omarchy)
if ! command -v apt-get >/dev/null 2>&1; then
  echo "set-apt-packages-config: apt-get no disponible, se omite" >&2
  return 0 2>/dev/null || exit 0
fi

# Idempotencia: instalar solo lo que falte (dpkg -s, no command -v,
# porque el nombre del paquete y del binario no siempre coinciden)
MISSING=()
for pkg in "${PACKAGES[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
done

if [ ${#MISSING[@]} -eq 0 ]; then
  return 0 2>/dev/null || exit 0
fi

echo "set-apt-packages-config: instalando ${MISSING[*]}" >&2
sudo apt-get update
sudo apt-get install -y "${MISSING[@]}"
