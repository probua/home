#!/bin/bash

mkdir -p ~/.config/hypr
if [ -f ~/.config/hypr/bindings.lua ] && ! cmp -s config/hypr/bindings.lua ~/.config/hypr/bindings.lua; then
  cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)
fi
cat config/hypr/bindings.lua > ~/.config/hypr/bindings.lua

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  hyprctl reload >/dev/null 2>&1
fi
