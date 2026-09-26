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
| `$mod+Shift+flechas` mover ventana | `SUPER+SHIFT+FLECHAS` (swap; si la ventana está en grupo, la saca de él — `hypr-swap-or-ungroup`) |
| `$mod+f` fullscreen | `SUPER+F` |
| `$mod+1..0` workspaces (+Shift para mover) | `SUPER+1..0` (+Shift, +Shift+Alt silencioso) |
| `floating_modifier $mod` | `SUPER+clic izq.` mover / `SUPER+clic der.` redimensionar |
| `Print` captura | `PRINT` Screenshot |
| `$mod+Escape` menú lock | `SUPER+ESCAPE` Lock directo (`omarchy-shell lock lock`, IPC del servicio omarchy.lock) |
| `$mod+Shift+e` menú exit | `SUPER+SHIFT+E` System menu (antes en `SUPER+ESCAPE`) |
| `$mod+Shift+w` selector de wallpaper | `SUPER+SHIFT+W` Background switcher |
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

## Barra: rueda sobre workspaces (capa shell)

Réplica del scroll de i3bar: la rueda del ratón sobre el widget de
workspaces de la barra inferior rota de workspace (arriba = anterior,
abajo = siguiente). `SUPER+rueda` (global) sigue disponible.

Implementación: `config/scripts/set-omarchy-shell-config.sh` clona el
widget built-in con el mecanismo oficial (`omarchy plugin clone
omarchy.workspaces` → `~/.config/omarchy/plugins/probua.workspaces/`) e
inyecta parches mínimos sobre el QML clonado, en dos fases idempotentes:

- fase 1 (rueda): función `focusRelativeWorkspace()` → dispatch `e±1` +
  `onWheelMoved` en los botones (señal que `WidgetButton` ya emite,
  mismo patrón que los widgets Tray/Microphone)
- fase 2 (estilo visual): activo = número blanco, pasivo (con ventanas,
  no visible) = número gris, inactivo (sin ventanas) = oculto — la barra
  solo muestra existentes + activo (réplica de i3 con
  `strip_workspace_numbers`)
  - fase 3 (rango y etiqueta): los workspaces 10-12 se muestran como
    "10"/"11"/"12" (el filtro original tapaba 11/12 y el 10 salía como
    "0")
  - fase 7 (rotación acotada): la rueda salta solo entre workspaces
    existentes dentro del rango 1..12; en los bordes la rotación se
    detiene (nada de wrap). El delta se acumula con umbral ±120 (un
    click de rueda) y al disparar se consume todo el acumulado, de modo
    que el trackpad no dispara un cambio por cada micro-evento. Sin
    lógica temporal: el cooldown inicial se retiró por confort (fase 8).

Los parches usan anclajes sobre el QML más reciente: si Omarchy cambia
el widget upstream, el installer detecta el anclaje roto y avisa sin
tocar nada. Las escrituras son in-place (preservan el inode para el
watcher del shell) y al final se ejecuta `omarchy-restart-shell` solo
si se aplicó algún parche (los re-runs sin cambios son silenciosos y
no tocan el shell). La deriva de features del widget no llega al clon
automáticamente (es un fork), pero el fallo siempre es gracioso: a lo
sumo el widget desaparece de la barra.

Reversión: `omarchy plugin remove probua.workspaces` restaura el
built-in. Las actualizaciones de Omarchy nunca tocan
`~/.config/omarchy/`.

## Look & feel: smart gaps/borders

Réplica del `smart_gaps on` + `smart_borders no_gaps` de i3: cuando un
workspace tiene una sola ventana tiled, ocupa todo el espacio sin gaps
ni borde; al haber dos o más vuelven los valores por defecto de Omarchy.

Hyprland no tiene esta opción nativa: la histórica
`dwindle:no_gaps_when_only` fue eliminada en la reestructuración lua
(verificado en wiki y fuente de 0.56), sin reemplazo. La implementa el
daemon `config/hypr/scripts/hypr-smart-single-window.sh` (instalado en
`~/.local/bin/` y arrancado por la capa de binds con `o.exec_on_start`):
escucha eventos de Hyprland por socket2 y aplica el mismo mecanismo del
toggle oficial de Omarchy — un lua de estado en
`~/.local/state/omarchy/toggles/hypr/smart-single-window.lua` (gaps y
borde a 0) más `hyprctl reload` cuando el workspace enfocado tiene una
sola ventana tiled; al pasar a dos o más elimina el archivo y recarga,
restaurando lo que definan los config files (sin defaults
hardcodeados). Nota: ni las workspace rules ni los `hyprctl eval`
runtime re-layoutean de forma fiable — solo la recarga de config.

Semántica: las ventanas flotantes no cuentan y un grupo (SUPER+W)
cuenta como N ventanas (como i3 tabbed). Singleton via flock; solo
recarga en las transiciones 1↔N del ws enfocado. Log de diagnóstico
en `$XDG_RUNTIME_DIR/hypr-smart-single.log`. Escala-agnóstico: no toca
geometría, solo cuenta ventanas.

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
| `SUPER+SHIFT+M` | Music (Spotify) | Restaurado: mover a ws 1 (colisión dura: Hyprland ejecuta el primer bind registrado) |
| `SUPER+SHIFT+E` | Email (webapp) | `SUPER+SHIFT+E` System menu (menú exit i3) |
| `SUPER+SHIFT+W` | Omawrite | `SUPER+SHIFT+W` Background switcher (wallpaper picker i3) |
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

## Variante Ubuntu (Hyprland vanilla)

La variante Ubuntu (Hyprland vanilla >=0.55, sin Omarchy) tiene su propio
documento: `MIGRATION-ubuntu.md` — tracking de instalación (PPA + apt +
configs), monitores, rationale de unbinds y fase 2.

