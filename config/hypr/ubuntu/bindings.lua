-- Variante Ubuntu de la capa de hotkeys (ver MIGRATION-omarchy.md).
-- API Lua vanilla de Hyprland (>=0.55): sin helpers de Omarchy (`o`)
-- ni comandos omarchy-*. Stack propio: alacritty (terminal), rofi
-- (launcher, vía XWayland) y pactl/playerctl (audio/media).
-- Fase 2 pendiente: menús lock/exit/wallpaper y barra (waybar).

-- Despejar colisiones con defaults vanilla. Hyprland NO reemplaza un bind
-- al redefinir la misma tecla: dispara TODOS los que coinciden (a
-- diferencia de i3). Por eso cada default reutilizado por este mapa debe
-- desligarse explícitamente antes de rebindiarlo.
hl.unbind("SUPER + M")        -- vanilla: exit! / acá: workspace 1
hl.unbind("SUPER + J")        -- vanilla: togglesplit / acá: workspace 4
hl.unbind("SUPER + K")        -- defensivo (no está en el ejemplo 0.56)
hl.unbind("SUPER + L")        -- defensivo
hl.unbind("SUPER + O")        -- defensivo
hl.unbind("SUPER + P")        -- vanilla: pseudo / acá: workspace 12
hl.unbind("SUPER + W")        -- defensivo
hl.unbind("SUPER + MINUS")    -- defensivo
hl.unbind("SUPER + SHIFT + MINUS")
-- Colisiones reales con el ejemplo 0.56 (verificado con hyprctl binds:
-- sin estos unbinds, Q cerraba la ventana Y abría terminal a la vez)
hl.unbind("SUPER + Q")            -- vanilla: abrir terminal / acá: cerrar
hl.unbind("SUPER + E")            -- vanilla: thunar (ni instalado) / acá: togglesplit
hl.unbind("SUPER + LEFT")         -- vanilla: focus left / acá: focus-or-group
hl.unbind("SUPER + RIGHT")        -- vanilla: focus right / acá: focus-or-group
hl.unbind("SUPER + SHIFT + S")    -- vanilla: move a special:magic / acá: ws 11

-- Terminal y launcher (equivalen a $mod+Return y $mod+d de i3)
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("alacritty"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("rofi -show drun"))

-- Ventanas y layout (núcleo portable de la capa Omarchy)
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + H", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + E", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("hypr-workspace-group-toggle"))
hl.bind("SUPER + LEFT", hl.dsp.exec_cmd("hypr-focus-or-group prev l"))
hl.bind("SUPER + RIGHT", hl.dsp.exec_cmd("hypr-focus-or-group next r"))
hl.bind("SUPER + SHIFT + LEFT", hl.dsp.exec_cmd("hypr-swap-or-ungroup l"))
hl.bind("SUPER + SHIFT + RIGHT", hl.dsp.exec_cmd("hypr-swap-or-ungroup r"))
hl.bind("SUPER + SHIFT + UP", hl.dsp.exec_cmd("hypr-swap-or-ungroup u"))
hl.bind("SUPER + SHIFT + DOWN", hl.dsp.exec_cmd("hypr-swap-or-ungroup d"))
hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Audio/media (tomados de config/i3/i3, sin la señal a i3blocks;
-- pactl y playerctl son agnósticos del compositor)
hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("SUPER + CTRL + UP", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + DOWN", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("SUPER + CTRL + LEFT", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("SUPER + CTRL + RIGHT", hl.dsp.exec_cmd("playerctl next"), { locked = true })

-- Workspaces por letra (esquema i3 completo)
local ws_keys = { M = 1, COMMA = 2, PERIOD = 3, J = 4, K = 5, L = 6, U = 7, I = 8, O = 9, MINUS = 10, NTILDE = 11, P = 12 }
for key, ws in pairs(ws_keys) do
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(ws) }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws) }))
end

-- Fase 2 (decisiones de stack pendientes): menús rofi exit/lock adaptados
-- a hyprctl (i3-msg/i3lock no aplican), swaybg para wallpaper, waybar.
