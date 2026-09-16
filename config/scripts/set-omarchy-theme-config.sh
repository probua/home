#!/bin/bash

# Tema personal "probua" para Omarchy (paleta kanagawa exacta).
#   - colors.toml / hyprland.lua / vscode.json se copian a
#     ~/.config/omarchy/themes/probua/, la ruta que Omarchy escanea.
#   - El resto de configs (alacritty, foot, shell, btop, ...) NO se
#     versionan: `omarchy theme set` los genera desde colors.toml.
#   - Fondos: se instalan en ~/.config/omarchy/backgrounds/probua/ (Omarchy
#     busca en esa ruta y en <tema>/backgrounds/), sin duplicarlos en el repo.
#   - preview.jpg: el selector de temas solo acepta como fallback fondos
#     dentro del dir del tema; se genera desde 01.jpg y no se versiona.
#   - Aplicación: Hyprland y el shell cargan la copia desplegada en
#     ~/.local/state/omarchy/current/theme/, no la de ~/.config, así que todo
#     cambio debe re-desplegarse con `omarchy theme set`. Si probua ya está
#     activo se re-aplica con OMARCHY_THEME_SKIP_BACKGROUND=1 para no rotar
#     el fondo (omarchy theme set cicla entre los disponibles).

install_omarchy_theme_files() {
  local THEME_DIR="$HOME/.config/omarchy/themes/probua"
  local BG_DIR="$HOME/.config/omarchy/backgrounds/probua"
  local SRC="config/omarchy/themes/probua"

  THEME_FILES_CHANGED=0
  mkdir -p "$THEME_DIR" "$BG_DIR"

  local f
  for f in colors.toml hyprland.lua vscode.json; do
    if [ -f "$THEME_DIR/$f" ] && ! cmp -s "$SRC/$f" "$THEME_DIR/$f"; then
      cp "$THEME_DIR/$f" "$THEME_DIR/$f.bak.$(date +%s)"
    fi
    if ! cmp -s "$SRC/$f" "$THEME_DIR/$f"; then
      cat "$SRC/$f" > "$THEME_DIR/$f"
      THEME_FILES_CHANGED=1
      echo "set-omarchy-theme-config: $f instalado"
    fi
  done

  local bg dest
  for bg in backgrounds/*.{jpg,jpeg,png,webp}; do
    [ -f "$bg" ] || continue
    dest="$BG_DIR/$(basename "$bg")"
    if ! cmp -s "$bg" "$dest"; then
      cat "$bg" > "$dest"
      echo "set-omarchy-theme-config: fondo $(basename "$bg") instalado"
    fi
  done

  if [ ! -f "$THEME_DIR/preview.jpg" ] && [ -f "$BG_DIR/01.jpg" ]; then
    cat "$BG_DIR/01.jpg" > "$THEME_DIR/preview.jpg"
  fi
}

apply_omarchy_theme() {
  local current
  current=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)

  if [ "$current" != "probua" ]; then
    omarchy theme set probua
  elif [ "$THEME_FILES_CHANGED" -eq 1 ]; then
    OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy theme set probua
    echo "set-omarchy-theme-config: tema probua re-desplegado (fondo intacto)"
  fi
}

install_omarchy_theme_files
apply_omarchy_theme
