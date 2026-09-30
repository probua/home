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
      -- Tabs pegados entre sí: sin separación horizontal entre gradients
      -- (default Omarchy: 5px).
      gaps_in = 0,
      indicator_gap = 0,
      indicator_height = 0,
    },
  },
})

-- Transparencia de terminales: "enfocada desenfocada" (1.0 = opaca).
o.window({ tag = "terminal" }, { opacity = "0.95 0.92" })

-- Nautilus igual que las terminales. Sin el tag del default, la regla global
-- (0.985 0.96) no compite: opacity es settable y esta carga más tarde.
o.window({ class = "org.gnome.Nautilus" }, { tag = "-default-opacity", opacity = "0.95 0.92" })
