local active_border_color = "rgb(dcd7ba)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
    },

    -- Cero margen entre los tabs y la ventana: se eliminan el gap del
    -- indicador y su línea (default Omarchy: 5px + 1px de banda vacía).
    -- La pestaña activa queda marcada solo por el color del tab
    -- (col.active vs col.inactive).
    groupbar = {
      -- Tabs pegados entre sí: sin separación horizontal entre tabs
      -- (default Omarchy: 5px).
      gaps_in = 0,
      indicator_gap = 0,
      indicator_height = 0,

      -- Diseño de pestañas, dos mecánicas intencionales:
      --   - Activa: OPACA #1f1f28. La transparencia la aporta la opacity
      --     de la regla de ventana (0.95/0.92), que Hyprland aplica
      --     también a las decoraciones: 0.95 x 1.0 = fórmula exacta de la
      --     terminal, se funde sobre cualquier wallpaper (poner alpha en
      --     col.active lo compondría: 0.95 x 0.949 = 0.90 y desalinea).
      --   - Inactiva: TRANSLÚCIDA rgba(1f1f2880) (~50% de tinte de paleta,
      --     estilo barra en modo transparente; ajuste manual fino). Acá el
      --     alpha sí es buscado: deja ver el wallpaper; componerse con la
      --     opacity de la ventana lo baja a ~48%, irrelevante para el look.
      -- locked_* anclados al tema: upstream usa naranjas (0x66ff5500).
      --
      -- gradients = true es el switch que habilita el dibujado del FONDO
      -- de las tabs: con false Hyprland solo dibuja títulos, y col.* únicamente
      -- tiñe el indicator (que acá está en 0). col.active es el "active group
      -- bar background color" según la wiki, y siendo monocolor el gradiente
      -- de cairo queda plano/solid (mismo patrón que el default de Omarchy).
      gradients = true,
      col = {
        active = "rgb(1f1f28)",
        inactive = "rgba(1f1f2870)",
        locked_active = "rgb(1f1f28)",
        locked_inactive = "rgba(1f1f2870)",
      },
      -- Texto idéntico en activa e inactiva: la distinción queda 100% a
      -- cargo del fondo. text_color_inactive se deja unset a propósito
      -- (defaultea a text_color según la wiki, así sigue al foreground si
      -- el tema cambia); font_weight_inactive se pisa explícito porque el
      -- default de Omarchy lo baja a "normal".
      text_color = "rgb(dcd7ba)",
      font_weight_inactive = "ultraheavy",
    },
  },
})

-- Transparencia de terminales: "enfocada desenfocada" (1.0 = opaca).
o.window({ tag = "terminal" }, { opacity = "0.95 0.92" })

-- Nautilus igual que las terminales. Sin el tag del default, la regla global
-- (0.985 0.96) no compite: opacity es settable y esta carga más tarde.
o.window({ class = "org.gnome.Nautilus" }, { tag = "-default-opacity", opacity = "0.95 0.92" })
