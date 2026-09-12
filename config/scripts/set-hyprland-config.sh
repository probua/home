#!/bin/bash

mkdir -p ~/.config/hypr
if [ -f ~/.config/hypr/bindings.lua ] && ! cmp -s config/hypr/bindings.lua ~/.config/hypr/bindings.lua; then
  cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)
fi
cat config/hypr/bindings.lua > ~/.config/hypr/bindings.lua

if [ -f ~/.config/hypr/looknfeel.lua ] && ! cmp -s config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua; then
  cp ~/.config/hypr/looknfeel.lua ~/.config/hypr/looknfeel.lua.bak.$(date +%s)
fi
cat config/hypr/looknfeel.lua > ~/.config/hypr/looknfeel.lua

mkdir -p ~/.local/bin
for script in config/hypr/scripts/*.sh; do
  name=$(basename "$script" .sh)
  cp "$script" ~/.local/bin/"$name"
  chmod +x ~/.local/bin/"$name"
done

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  hyprctl reload >/dev/null 2>&1
fi
