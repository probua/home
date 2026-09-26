#!/bin/bash
#
# install-hyprland-ppa.sh — instala Hyprland (>=0.55, config Lua) en Ubuntu
# 24.04 desde el PPA comunitario ppa:cppiber/hyprland.
#
# Por qué PPA y no compilar: Hyprland 0.56 exige cmake>=3.30, xkbcommon>=1.11,
# wayland-protocols>=1.49, libinput>=1.29, lua>=5.5 y parches de toolchain
# que noble no tiene. El PPA backportea esas libs y parchea el build (fuentes
# auditables: github.com/cpiber/hyprland-ppa). Es el mecanismo estándar
# adoptado por JaKooLit/Ubuntu-Hyprland para su rama 24.04.
#
# Riesgo: PPA de terceros (confianza en el maintainer); actualiza algunas
# libs de sistema (libxkbcommon, libinput, wayland-protocols). Reversión:
#   sudo apt install ppa-purge && sudo ppa-purge ppa:cppiber/hyprland
#
# Uso:
#   ./bin/install-hyprland-ppa.sh
#
# Idempotente: si hyprland ya está instalado con config Lua, no hace nada.
# Doc y contexto: MIGRATION-omarchy.md, sección "Variante Ubuntu".

PPA="ppa:cppiber/hyprland"
PACKAGES=(hyprland xdg-desktop-portal-hyprland hyprlock hypridle hyprpaper hyprpicker waybar)

msg()  { echo "install-hyprland-ppa: $*"; }
warn() { echo "install-hyprland-ppa: $*" >&2; }

# Guard: apt disponible (fuera de Ubuntu/Debian no aplica)
if ! command -v apt-get >/dev/null 2>&1; then
  warn "apt-get no disponible; omitido"
  exit 0
fi

# Guard: ¿ya instalado con config Lua (>=0.55)?
if command -v Hyprland >/dev/null 2>&1; then
  ver=$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
  min=$(printf '%s\n0.55\n' "$ver" | sort -V | head -1)
  if [ "$min" = "0.55" ]; then
    msg "Hyprland $ver ya instalado: nada que hacer"
    exit 0
  fi
  warn "Hyprland $ver existente es <0.55 (sin config Lua); no se toca nada"
  exit 1
fi

# add-apt-repository viene en software-properties-common
if ! command -v add-apt-repository >/dev/null 2>&1; then
  msg "instalando software-properties-common"
  sudo apt-get update
  sudo apt-get install -y software-properties-common
fi

# PPA: solo si no estaba ya agregado (nombra .list o .sources según versión)
if ! ls /etc/apt/sources.list.d/ 2>/dev/null | grep -q '^cppiber-ubuntu-hyprland'; then
  msg "agregando $PPA"
  sudo add-apt-repository -y "$PPA"
  sudo apt-get update
else
  msg "PPA ya agregado"
fi

# Instalar solo lo que falte
missing=()
for p in "${PACKAGES[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done
if [ ${#missing[@]} -gt 0 ]; then
  msg "instalando: ${missing[*]}"
  sudo apt-get install -y "${missing[@]}"
else
  msg "paquetes ya instalados"
fi

cat >&2 <<'EOF'
install-hyprland-ppa: listo. Siguiente:
  1) Probar desde TTY (Ctrl+Alt+F3): Hyprland
     (GDM tiene bugs conocidos con Hyprland: mejor no usarlo para probar)
  2) Aplicar la capa de config: cd <repo> && source install-on-ubuntu.sh
  3) Con sesión activa validar: hyprctl configerrors
Reversión: sudo apt install ppa-purge && sudo ppa-purge ppa:cppiber/hyprland
EOF
