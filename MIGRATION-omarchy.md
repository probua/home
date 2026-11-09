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

## Paquetes base (pacman)

Los `set-*-config.sh` despliegan configs, no instalan programas. Los paquetes
que la capa asume se instalan con `config/scripts/set-pacman-packages-config.sh`
(sourceado el primero en `install-on-omarchy.sh`, antes que `set-vim-config.sh`
para que el binario exista cuando se despliegue el `vimrc`):

| Paquete | Rol |
|---|---|
| `vim` | Editor de `config/vimrc` (vim-plug incluido). Distinto de `neovim`/`omarchy-nvim` que trae Omarchy |
| `nwg-displays` | GUI de gestión de monitores (layout, escala, rotación, workspaces→monitor) |

Es el equivalente Arch de `set-apt-packages-config.sh` (variante Ubuntu, que
instala `wdisplays`/`wlr-randr`). Detecta los faltantes con `pacman -T`, solo
instala esos, y en un re-run donde ya está todo no imprime nada.

**Los archivos de monitores no los gestiona este repo**: `nwg-displays` escribe
`~/.config/hypr/monitors.{lua,conf}` y `workspaces.{lua,conf}` en runtime, y
Omarchy los carga vía `require("hypr.monitors")` en `hyprland.lua`, por lo que
sustituyen su plantilla por defecto. `set-hyprland-config.sh` solo despliega
`bindings.lua` y `looknfeel.lua`, así que en una máquina limpia la disposición
se crea la primera vez que se abre la app (igual que en Ubuntu, donde la
disposición volcada a mano vive en `config/hypr/ubuntu/hyprland.lua`).

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
  - fase 12 (workspaces por monitor): cada barra muestra solo los
    workspaces del monitor donde vive — la pantalla de la ventana de la
    barra (`QsWindow.window.screen.name`, mismo patrón que `Bar.qml`)
    contra `HyprlandWorkspace.monitor.name`. Sin seed 1..5 (sembraría
    workspaces ajenos en el otro monitor), resaltado por `workspace.active`
    (el activo de SU monitor: cada barra siempre muestra ≥1 número) y
    rueda acotada al monitor de la barra (rota entre sus workspaces,
    con el activo de ese monitor como actual). Guard: sin ventana de
    barra (preview) se muestra todo. El rango por monitor se fijaba con
    `workspace_rules` de nwg-displays (DP-1: 1-9, HDMI-A-1: 10) —
    retiradas; ver «Workspaces por monitor: bloques de Omarchy».

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

## Barra: doble click sin moverla de borde (fase 13)

Síntoma: al doble click en la barra inferior esta "se buggea" — salta a un
lateral (y se vuelve vertical) y ventanas abiertas quedan varadas e
inaccesibles; en apps single-instance (Electron: Obsidian) relanzar "no
hace nada" porque la nueva instancia le avisa a la varada y muere
(verificado en journal: scope de 390ms).

Causa raíz — bug upstream
([omacom/omarchy#17385](https://github.com/omacom/omarchy/pull/17385),
abierto contra omarchy 4.5.0, reproducido en Hyprland 0.56.2 con dos
monitores):

1. El doble click en espacio vacío de la barra ejecuta `cycleBackground()`
   con el segundo botón aún presionado (Qt reporta el doble click en la
   segunda pulsación).
2. Entrar/salir de glassy ejecuta `hyprctl reload` (toggle `bar-glassy` en
   `~/.local/state/omarchy/toggles/hypr/`).
3. Al recargar, Hyprland re-enfoca una ventana y teletransporta el cursor
   a su centro (puede ser en el otro monitor).
4. El `CenterGestureArea` de `Bar.qml` lee el salto como arrastre (umbral
   4px, distancia Manhattan) y al soltar mueve la barra al borde más
   cercano del cursor saltado, con la tormenta de re-focus/re-tilo que
   deja ventanas varadas en workspaces no visibles.

El bug secundario
[#14649](https://github.com/omacom/omarchy/pull/14649) agrava el
disparador: los widgets (clock, números de workspace, tray) tampoco
consumen dobles clicks, así que un doble click sobre ellos también cicla
el fondo de la barra. No hay opt-out por configuración en 4.5.0 (el PR
#9933 que lo propone tampoco está fusionado).

Mitigación: fase 13 de `config/scripts/set-omarchy-shell-config.sh` —
clon del plugin de la barra (`omarchy plugin clone omarchy.bar` →
`probua.bar`) con el mismo guard del PR: la segunda pulsación de un doble
click que cicló el fondo no puede iniciar un bar-move hasta soltarse
(`cycledOnPress`). Un press-and-drag deliberado sigue moviendo la barra.
El gesto de ciclar fondo quedó luego neutralizado por la fase 14: cada
ciclo cruza glassy → `hyprctl reload` → `reconcile()` (ver sección
siguiente). El fondo de la barra se cambia por CLI (`omarchy bar
background <opaque|glassy|none>`).

Playbook de recuperación (si vuelve a pasar en otra máquina o antes de
re-aplicar el instalador):

```bash
omarchy bar position bottom                       # restaurar la barra
hyprctl dispatch focuswindow class:obsidian       # rescatar una ventana varada
pkill -x obsidian && gtk-launch obsidian.desktop  # instancia Electron zombi
omarchy-restart-shell                             # estado raro del shell
```

Deriva y reversión: el clon `probua.bar` es un fork del `Bar.qml`
(~2600 líneas): las mejoras upstream de la barra no llegan solas. Cuando
upstream fusione #17385 y lo libere conviene re-clonar o volver al
built-in (`omarchy plugin remove probua.bar` **y** quitar la fase 13 del
script — si solo se hace el remove, el instalador re-clonaría). Un clon
nuevo con el fix upstream ya trae el marcador `cycledOnPress` y la fase
se omite sola.

## Workspaces por monitor: bloques de Omarchy (primaria 1-10, secundaria 11-12)

Omarchy 4.5+ (instalado 7-nov-2026) gestiona workspaces por monitor con
**bloques contiguos de 10** (`default/hypr/monitor-workspaces.lua`): cada
monitor es dueño de un bloque, asignado por **identidad física**
(make/model/serial — no por puerto: sobrevive a docks y renombrados de
conector) y persistido en `~/.local/state/omarchy/monitor-workspaces`. En
cada `hyprctl reload` (y en cada evento de monitor) su `reconcile()`
mueve y **renumera** todo workspace ocupado que no esté en el monitor
dueño de su bloque.

### Post-mortem: ventanas "perdidas" (7-9 nov 2026)

Las `workspace_rules` de nwg-displays que este repo instalaba (1-9→DP-1,
10→HDMI-A-1) contradecían la asignación real de bloques (HDMI=bloque
0=ws 1-10, DP-1=bloque 1=ws 11-20, por orden de llegada). Cada reload —
incluido el que dispara el doble click en la barra al ciclar glassy —
hacía que reconcile "corrigiera": renumeraba ws 1-4 (ocupados, en DP-1)
→ 11-14, vaciando los workspaces y dejando ventanas inaccesibles.
Obsidian, además, es single-instance: reabrir "no hacía nada" (la nueva
instancia le avisa a la varada y muere — journal: scope de 390ms). El
incidente original del 8-nov se explica por completo con esta cadena más
el bar-move fantasma del PR #17385 (fase 13).

### Alineación adoptada

- **Primaria** (GIGA-BYTE GS27Q, DP-1) = bloque 0 → **ws 1-10**
- **Secundaria** (LG FULL HD, HDMI-A-1) = bloque 1 → ws 11-20, en uso
  **11-12**
- Limitación del sistema: bloques contiguos de 10 hardcoded —
  "10,11,12 en la secundaria" no es expresable; lo más cercano es 11-12
- El require de `hypr.workspaces` queda retirado de `hyprland.lua`: las
  reglas nwg dejan de cargar y de pelear con reconcile. nwg-displays
  puede seguir usándose para layout de monitores; si vuelve a escribir
  `workspaces.lua`, simplemente no se carga.
- Con los bloques alineados cada reload es inocuo (reconcile = no-op).
  Solo un monitor NUEVO (hotplug/reemplazo) dispara una renumeración
  única al asentarse su bloque — comportamiento diseñado, no el bug.

### Binds (config/hypr/bindings.lua)

Semántica i3: **números globales y fijos** — cada tecla apunta siempre al
mismo workspace (la semántica nativa "slot del monitor enfocado" de
Omarchy/Niri se probó y se descartó: desde la secundaria SUPER+M abría
ws 11 en vez de ws 1).

- `SUPER+{M..MINUS}` → ws 1-10, el bloque de la **primaria**: desde
  cualquier pantalla enfoca la primaria y su slot N (cierre sobre
  `o.workspaces.focus(slot, primary)`).
- `SUPER+{NTILDE,P}` → ws 11/12, slots 1-2 de la **secundaria**, siempre.
- `SUPER+SHIFT+…` → mover la ventana (y seguirla) al workspace destino.
- Primaria/secundaria se derivan **al presionar** desde el sistema de
  bloques (`o.workspaces.workspace_id(monitor, 1) == 1` → dueña del
  bloque 0): autoritativo, sobrevive a hotplugs. Portable — en una
  laptop sola la única pantalla ES la primaria y NTILDE/P son no-op
  graciable. El menú de keybindings lista sus descripciones pero no
  puede replayearlos (closures sin expresión registrada en
  `o.bind_expressions`).

### Reproducibilidad (set-hyprland-config.sh)

- Fase de retirada del require nwg (idempotente por ausencia, backup).
- Fase de alineación de bloques: fuerza GIGA-BYTE=0 / LG=1 **solo** si
  encuentra ambas identidades en el state file; en otra máquina se
  omite y Omarchy asigna solo (monitor único → bloque 0 = ws 1-10).
- Mover una ventana a un workspace concreto por teclado no existe como
  dispatch directo; para rescates manuales:
  `hyprctl dispatch 'hl.dsp.window.move({ workspace = "N", window = "address:0x…" })'`

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

