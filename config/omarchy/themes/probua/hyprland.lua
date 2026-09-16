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
  },
})

-- Transparencia de terminales: "enfocada desenfocada" (1.0 = opaca).
o.window({ tag = "terminal" }, { opacity = "0.95 0.92" })

-- Nautilus igual que las terminales. Sin el tag del default, la regla global
-- (0.985 0.96) no compite: opacity es settable y esta carga más tarde.
o.window({ class = "org.gnome.Nautilus" }, { tag = "-default-opacity", opacity = "0.95 0.92" })
