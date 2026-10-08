-- Desactiva solo animaciones/transiciones (abrir/cerrar/mover) para cambio inmediato.
-- No toca gaps, bordes, blur, opacidad, rounding ni layout.
-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
hl.config({
  animations = {
    enabled = false,
  },
})

-- Smart gaps nativo ("no gaps when only"): workspace con exactamente 1 ventana
-- tiled visible (grupo con pestañas = 1) queda sin gaps ni borde; en multi cae a
-- los defaults del tema (5/10/2). Evaluado por el compositor: instantáneo.
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/#smart-gaps
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })

-- Bug conocido del cliente de Steam (steamwebhelper/CEF): abre popups internos
-- cuyo initialTitle es "about:blank?createflags=..." que pueden quedar tildeados
-- ocupando el workspace completo, simulando un "wallpaper fantasma" (2026-10-07).
-- Se fuerzan flotantes y con tamaño reducido: siempre visibles y cerrables.
-- Carga después de los defaults de Omarchy (apps/steam.lua), y la última
-- coincidencia gana, así que prevalece sobre la regla genérica de steam.
hl.window_rule({
  match = { class = "^steam$", initial_title = "^about:blank" },
  float = true,
  size = { 480, 400 },
})
