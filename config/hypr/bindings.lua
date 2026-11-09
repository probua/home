hl.unbind("SUPER + COMMA")
hl.unbind("SUPER + SHIFT + COMMA")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + O")
hl.unbind("SUPER + SHIFT + O")
hl.unbind("SUPER + P")
hl.unbind("SUPER + SHIFT + P")
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + SHIFT + code:20")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + W")
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + W")
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
hl.unbind("SUPER + ESCAPE")

hl.unbind("SUPER + CTRL + SPACE")
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
hl.unbind("SUPER + CTRL + S")

o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + D", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + A", "Omarchy root menu", "omarchy-menu toggle root")
o.bind("SUPER + H", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + E", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + W", "Group/ungroup all windows in workspace", "hypr-workspace-group-toggle")
o.bind("SUPER + LEFT", "Focus left / previous group tab", "hypr-focus-or-group prev l")
o.bind("SUPER + RIGHT", "Focus right / next group tab", "hypr-focus-or-group next r")
o.bind("SUPER + SHIFT + LEFT", "Move group tab left / swap left", "hypr-swap-or-ungroup l")
o.bind("SUPER + SHIFT + RIGHT", "Move group tab right / swap right", "hypr-swap-or-ungroup r")
o.bind("SUPER + SHIFT + UP", "Move group tab to first / swap up", "hypr-swap-or-ungroup u")
o.bind("SUPER + SHIFT + DOWN", "Move group tab to last / swap down", "hypr-swap-or-ungroup d")
o.bind("SUPER + SPACE", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + ESCAPE", "Lock screen", "omarchy-shell lock lock")
o.bind("SUPER + SHIFT + E", "System menu (lock/logout/reboot/shutdown)", "omarchy-menu toggle system")
o.bind("SUPER + SHIFT + W", "Background switcher", "omarchy-menu toggle background")

o.bind("SUPER + CTRL + M", "Mute microphone", "omarchy-audio-input-mute", { locked = true })
o.bind("SUPER + CTRL + S", "Mute", "omarchy-audio-output-volume mute-toggle", { locked = true })
o.bind("SUPER + CTRL + UP", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("SUPER + CTRL + DOWN", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
o.bind("SUPER + CTRL + SPACE", "Play/pause", "omarchy-shell media playPause", { locked = true })
o.bind("SUPER + CTRL + LEFT", "Previous track", "omarchy-shell media previous", { locked = true })
o.bind("SUPER + CTRL + RIGHT", "Next track", "omarchy-shell media next", { locked = true })

-- Workspaces por bloque FIJO (sistema de bloques de Omarchy 4.5+,
-- default/hypr/monitor-workspaces.lua). Cada monitor es dueño de un bloque
-- contiguo de 10 workspaces, asignado por IDENTIDAD física (make/model/
-- serial, no por puerto): primaria (GIGA-BYTE, DP-1) = bloque 0 → ws 1-10;
-- secundaria (LG, HDMI-A-1) = bloque 1 → ws 11-20 (en uso: 11-12). La
-- alineación la aplica set-hyprland-config.sh; post-mortem completo en
-- MIGRATION-omarchy.md.
-- Semántica i3 (números GLOBALES y fijos — NO "slot del monitor enfocado",
-- que era la nativa de Omarchy/Niri y hacía que SUPER+M desde la secundaria
-- abriera ws 11): las teclas apuntan SIEMPRE al mismo workspace.
--   SUPER+{M..MINUS}        → ws 1..10 (bloque de la PRIMARIA): desde
--                             cualquier pantalla enfoca la primaria y su
--                             slot N
--   SUPER+{NTILDE,P}        → ws 11/12 (slots 1-2 de la SECUNDARIA), siempre
--   SUPER+SHIFT+{M..MINUS}  → mover ventana (y seguirla) a ws 1..10
--   SUPER+SHIFT+{NTILDE,P}  → mover ventana (y seguirla) a ws 11/12
-- Primaria/secundaria se resuelven AL PRESIONAR desde el propio sistema
-- de bloques (o.workspaces.workspace_id): la primaria es la dueña del
-- bloque 0 (su slot 1 = ws 1) — autoritativo (lee el state file), no
-- heurístico. Portable: en una laptop sola la única pantalla ES la
-- primaria (SUPER+M..MINUS funcionan igual) y NTILDE/P son no-op
-- graciable. Closures propias: el menú de keybindings lista sus
-- descripciones pero no puede replayearlas.
local ws_keys = { M = 1, COMMA = 2, PERIOD = 3, J = 4, K = 5, L = 6, U = 7, I = 8, O = 9, MINUS = 10 }
local secondary_keys = { NTILDE = 1, P = 2 }

local function active_monitors()
  local list = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    if not monitor.is_mirror then list[#list + 1] = monitor end
  end
  return list
end

-- Dueña del bloque 0 (ws 1-10): la primaria.
local function primary_monitor()
  for _, monitor in ipairs(active_monitors()) do
    if o.workspaces.workspace_id(monitor, 1) == 1 then
      return monitor
    end
  end
  return nil
end

-- Primera pantalla que no es la primaria: la secundaria.
local function secondary_monitor()
  local primary = primary_monitor()
  for _, monitor in ipairs(active_monitors()) do
    if primary == nil or monitor.name ~= primary.name then
      return monitor
    end
  end
  return nil
end

for key, slot in pairs(ws_keys) do
  o.bind("SUPER + " .. key, "Switch to workspace " .. slot .. " (primary)", function()
    local primary = primary_monitor()
    if primary then o.workspaces.focus(slot, primary.name)() end
  end)
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. slot .. " (primary)", function()
    local primary = primary_monitor()
    if primary then
      hl.dispatch(hl.dsp.window.move({ workspace = tostring(o.workspaces.workspace_id(primary, slot)), follow = true }))
    end
  end)
end

for key, slot in pairs(secondary_keys) do
  o.bind("SUPER + " .. key, "Switch to workspace " .. (slot + 10) .. " (secondary)", function()
    local secondary = secondary_monitor()
    if secondary then o.workspaces.focus(slot, secondary.name)() end
  end)
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. (slot + 10) .. " (secondary)", function()
    local secondary = secondary_monitor()
    if secondary then
      hl.dispatch(hl.dsp.window.move({ workspace = tostring(o.workspaces.workspace_id(secondary, slot)), follow = true }))
    end
  end)
end
