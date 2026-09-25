-- Variante Ubuntu de la capa de hotkeys (ver MIGRATION-omarchy.md).
-- API Lua vanilla de Hyprland (>=0.55): sin helpers de Omarchy (`o`)
-- ni comandos omarchy-*. Stack propio: alacritty (terminal), rofi
-- (launcher, vía XWayland) y pactl/playerctl (audio/media).
-- Fase 2 pendiente: menús lock/exit/wallpaper y barra (waybar).

-- Despejar colisiones con defaults vanilla (M = exit!; el resto son
-- teclas que este mapa reutiliza para workspaces/ventanas)
hl.unbind("SUPER + M")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + O")
hl.unbind("SUPER + P")
hl.unbind("SUPER + W")
hl.unbind("SUPER + MINUS")
hl.unbind("SUPER + SHIFT + MINUS")

-- Terminal y launcher (equivalen a $mod+Return y $mod+d de i3)
hl.bind("SUPER + RETURN", hl.dsp.exec("alacritty"))
hl.bind("SUPER + D", hl.dsp.exec("rofi -show drun"))

-- Ventanas y layout (núcleo portable de la capa Omarchy)
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + H", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + E", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + W", hl.dsp.exec("hypr-workspace-group-toggle"))
hl.bind("SUPER + LEFT", hl.dsp.exec("hypr-focus-or-group prev l"))
hl.bind("SUPER + RIGHT", hl.dsp.exec("hypr-focus-or-group next r"))
hl.bind("SUPER + SHIFT + LEFT", hl.dsp.exec("hypr-swap-or-ungroup l"))
hl.bind("SUPER + SHIFT + RIGHT", hl.dsp.exec("hypr-swap-or-ungroup r"))
hl.bind("SUPER + SHIFT + UP", hl.dsp.exec("hypr-swap-or-ungroup u"))
hl.bind("SUPER + SHIFT + DOWN", hl.dsp.exec("hypr-swap-or-ungroup d"))
hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))

-- Audio/media (tomados de config/i3/i3, sin la señal a i3blocks;
-- pactl y playerctl son agnósticos del compositor)
hl.bind("SUPER + CTRL + M", hl.dsp.exec("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("SUPER + CTRL + S", hl.dsp.exec("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("SUPER + CTRL + UP", hl.dsp.exec("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + DOWN", hl.dsp.exec("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec("playerctl play-pause"), { locked = true })
hl.bind("SUPER + CTRL + LEFT", hl.dsp.exec("playerctl previous"), { locked = true })
hl.bind("SUPER + CTRL + RIGHT", hl.dsp.exec("playerctl next"), { locked = true })

-- Workspaces por letra (esquema i3 completo)
local ws_keys = { M = 1, COMMA = 2, PERIOD = 3, J = 4, K = 5, L = 6, U = 7, I = 8, O = 9, MINUS = 10, NTILDE = 11, P = 12 }
for key, ws in pairs(ws_keys) do
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(ws) }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws) }))
end

-- Fase 2 (decisiones de stack pendientes): menús rofi exit/lock adaptados
-- a hyprctl (i3-msg/i3lock no aplican), swaybg para wallpaper, waybar.
