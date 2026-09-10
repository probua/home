# Migración i3 → Omarchy: capa de hotkeys

Este documento describe la capa de personalización que replica los hotkeys de
mi antigua configuración de i3 (`config/i3/i3`) sobre una instalación limpia
de Omarchy (Hyprland). El archivo fuente de la capa es
`config/hypr/bindings.lua` y se instala con
`config/scripts/set-hyprland-config.sh`.

## Cómo aplicar

```bash
git clone https://github.com/probua/home.git
cd home
source install-on-omarchy.sh
```

O solo esta capa (desde la raíz del repo):

```bash
source config/scripts/set-hyprland-config.sh
```

El script es idempotente, hace backup de `~/.config/hypr/bindings.lua` antes
de sobrescribirlo y fuerza `hyprctl reload` si hay sesión Hyprland activa.

## Equivalencias directas (no requieren cambios)

| i3 | Omarchy (default) |
|---|---|
| `$mod+Return` terminal | `SUPER+RETURN` Terminal |
| `$mod+flechas` foco | `SUPER+FLECHAS` (en grupos, LEFT/RIGHT cambian de tab) |
| `$mod+Shift+flechas` mover ventana | `SUPER+SHIFT+FLECHAS` (swap) |
| `$mod+f` fullscreen | `SUPER+F` |
| `$mod+1..0` workspaces (+Shift para mover) | `SUPER+1..0` (+Shift, +Shift+Alt silencioso) |
| `floating_modifier $mod` | `SUPER+clic izq.` mover / `SUPER+clic der.` redimensionar |
| `Print` captura | `PRINT` Screenshot |
| `$mod+Escape` menú lock | `SUPER+ESCAPE` System menu (lock/logout/reboot/shutdown) |
| `$mod+Shift+e` menú exit | Cubierto por `SUPER+ESCAPE` |
| `$mod+Shift+w` selector de wallpaper | `SUPER+CTRL+SPACE` Background switcher* |
| Teclas XF86 volumen/brillo/media | Idénticas, con OSD de Omarchy |

\* `SUPER+CTRL+SPACE` se reasigna en esta capa (ver conflictos).

## Adiciones sin conflicto

| i3 | Nuevo atajo |
|---|---|
| `$mod+q` kill | `SUPER+Q` Close window |
| `$mod+d` rofi drun | `SUPER+D` Apps menu |
| `$mod+a` dmenu | `SUPER+A` Omarchy root menu |
| `$mod+h` split h | `SUPER+H` Toggle split (Hyprland divide automático; alterna dirección) |
| `$mod+e` layout toggle split | `SUPER+E` (duplicado de `SUPER+H`) |
| `$mod+w` layout tabbed | `SUPER+W` agrupa/desagrupa todas las ventanas tiled del workspace (≈ tabbed; navega con `SUPER+ALT+TAB`) |
| `$mod+Ctrl+m` mute micro | `SUPER+CTRL+M` |
| `$mod+Ctrl+Up/Down` volumen ± | `SUPER+CTRL+UP/DOWN` (con OSD y repetición) |

## Workspaces por letra (esquema completo de i3)

`SUPER` + tecla → ir al workspace; `SUPER+SHIFT` + tecla → mover ventana:

| Tecla | Workspace |
|---|---|
| `M` | 1 |
| `,` (COMMA) | 2 |
| `.` (PERIOD) | 3 |
| `J` | 4 |
| `K` | 5 |
| `L` | 6 |
| `U` | 7 |
| `I` | 8 |
| `O` | 9 |
| `-` (MINUS) | 10 |
| `Ñ` (NTILDE) | 11 |
| `P` | 12 |

## Conflictos resueltos (i3 gana) y mitigaciones

| Tecla | Se pierde (default Omarchy) | Mitigación |
|---|---|---|
| `SUPER+COMMA` | Dismiss last notification | Historial vía menú root (`SUPER+A`) |
| `SUPER+J` | Toggle window split | Repuesto en `SUPER+H` |
| `SUPER+K` | Menú de keybindings | Accesible vía menú root |
| `SUPER+L` | Toggle workspace layout | Repuesto en `SUPER+E` |
| `SUPER+O` | Pop window out (float & pin) | `SUPER+T` sigue flotando la ventana |
| `SUPER+MINUS` | Expand window left | Quedan `SUPER+CTRL/ALT+MINUS` |
| `SUPER+P` | Pseudo window | Sin reemplazo (poco usado) |
| `SUPER+SHIFT+COMMA` | Dismiss all notifications | — |
| `SUPER+SPACE` | Omarchy menu (launcher) | Apps menu (`SUPER+D`) y menú root (`SUPER+A`) |
| `SUPER+W` | Close window | `SUPER+Q` (mismo atajo que en i3) |
| `SUPER+SHIFT+O` | Lanzar Obsidian | Vía apps menu (`SUPER+D`) |
| `SUPER+SHIFT+P` | Lanzar Google Photos | Vía apps menu |
| `SUPER+SHIFT+MINUS` | Shrink window up | Quedan variantes CTRL/ALT |
| `SUPER+CTRL+SPACE` | Background switcher | Vía menú root o `omarchy-menu toggle background` |
| `SUPER+CTRL+LEFT/RIGHT` | Foco en grupos de ventanas | Solo afecta si se usan grupos |
| `SUPER+CTRL+S` | Menú Share | Vía `omarchy-menu toggle share` |

Nota: Omarchy define MINUS/IGUAL por keycode, por eso los unbinds usan
`SUPER + code:20` (y su variante SHIFT) en lugar del keysym.

Nota: `SUPER+E` antes alternaba el layout del workspace (dwindle/scrolling);
esa función sigue disponible como comando
`omarchy-hyprland-workspace-layout-toggle`.

## No migrado (con alternativas)

| i3 | Situación en Hyprland |
|---|---|
| `$mod+r` modo resize | No hay modos. Usar `SUPER+MINUS/IGUAL` (y variantes CTRL/ALT) o `SUPER+clic der.` para redimensionar |
| `$mod+s` layout stacking | Sin equivalente. Grupos: `SUPER+G` |
| `$mod+space` toggle floating | `SUPER+SPACE` (y `SUPER+T` sigue igual) |
| `$mod+v` split v | `SUPER+H` cubre h/v con una tecla; `SUPER+V` sigue siendo pegado universal |
| `$mod+Shift+c/r` reload/restart | Hyprland recarga la config automáticamente al guardar |
| Barra i3blocks / colores / gaps | Fuera de alcance: solo hotkeys (Omarchy shell los cubre) |

## Validación tras aplicar

```bash
hyprctl reload && hyprctl configerrors   # debe salir limpio; probar la Ñ en layout español
omarchy menu keybindings --print          # verificar el mapa final
```

## Revertir

```bash
omarchy refresh hyprland                  # restaura defaults (crea backup automático)
```

O restaurar manualmente el último `~/.config/hypr/bindings.lua.bak.*` y
`hyprctl reload`.
