# Entorno Ubuntu 24.04 + Hyprland vanilla

Variante Ubuntu del entorno de trabajo: los hotkeys y flujos de la antigua
config i3 (`config/i3/i3`) portados a Hyprland vanilla >=0.55 (API Lua
upstream), sin Omarchy. La capa Omarchy (Arch + omarchy-shell) tiene su
propio documento (`MIGRATION-omarchy.md`); este es la fuente de verdad del
entorno Ubuntu.

## Cómo aplicar

```bash
git clone https://github.com/probua/home.git
cd home
./bin/install-hyprland-ppa.sh    # solo si Hyprland no está instalado
./install-on-ubuntu.sh
```

`install-on-ubuntu.sh` es idempotente: cada capa compara antes de escribir
(backup + escritura in-place si hay delta), instala solo los paquetes que
faltan y no relanza nada si no hubo cambios. Re-ejecutarlo siempre es
seguro; los scripts asumen CWD = raíz del repo.

## Instalación base: Hyprland por PPA

`bin/install-hyprland-ppa.sh` instala desde el PPA comunitario
`ppa:cppiber/hyprland`. Por qué PPA y no compilar: Hyprland 0.56 exige
cmake>=3.30, xkbcommon>=1.11, wayland-protocols>=1.49, libinput>=1.29,
lua>=5.5 y parches de toolchain que noble no tiene; el PPA backportea esas
libs y mantiene el build (mecanismo estándar adoptado por
JaKooLit/Ubuntu-Hyprland en su rama 24.04).

Riesgo asumido: PPA de terceros que actualiza libs de sistema
(libxkbcommon, libinput, wayland-protocols, libdisplay-info). Reversión
completa: `sudo apt install ppa-purge && sudo ppa-purge ppa:cppiber/hyprland`.

## Tracking de instalación

Inventario de todo lo que el entorno pone en la máquina. Al añadir un
paquete o config nueva, actualizar aquí.

### Kit del PPA

| Paquete | Rol |
|---|---|
| hyprland 0.56 | Compositor (config Lua >=0.55) |
| xdg-desktop-portal-hyprland | Portales Wayland (screencast, screenshots) |
| hyprlock / hypridle | Lock e idle (backlog #2) |
| hyprpaper | Wallpaper (backlog #1) |
| hyprpicker | Selector de color |
| waybar 0.14 | Barra de estado |

### Paquetes apt (vía `set-apt-packages-config.sh`)

| Paquete | Rol |
|---|---|
| eza | Dependencia de los aliases ls/l/ll de config/bash |
| imv | Visor de imágenes (default image viewer) |
| alacritty | Terminal (SUPER+RETURN) |
| rofi | Launcher (SUPER+D, vía XWayland) |
| playerctl | Media keys (binds capa propia) |
| brightnessctl | Brillo (teclas XF86 del ejemplo vanilla) |
| pulseaudio-utils | pactl para los binds de audio |
| wdisplays | GUI de monitores (ajustes en caliente) |
| wlr-randr | CLI de monitores (ajustes en caliente) |
| fonts-font-awesome | Iconos de waybar (FA 4.7, los del style.css) |
| network-manager-gnome | nm-connection-editor: GUI completa de redes (click del módulo network de la barra). NOTA: su applet (nm-applet) en noble NO registra SNI — probado con Wayland, env del compositor y X11; el estado de red lo da el módulo nativo de waybar |
| blueman | Icono/menú bluetooth en el tray SNI (autostart con guard: solo si bluetoothd activo) |

### Configs desplegadas

| Destino | Origen | Script |
|---|---|---|
| `~/.config/hypr/hyprland.lua` | `config/hypr/ubuntu/hyprland.lua` | set-hyprland-ubuntu-config.sh |
| `~/.config/hypr/bindings.lua` | `config/hypr/ubuntu/bindings.lua` | 〃 |
| `~/.config/hypr/looknfeel.lua` | `config/hypr/looknfeel.lua` (compartido con Omarchy) | 〃 |
| `~/.local/bin/hypr-*` (focus-or-group, swap-or-ungroup, workspace-group-toggle) | `config/hypr/scripts/*.sh` | 〃 |
| `~/.config/waybar/{config.jsonc,style.css}` | `config/waybar/ubuntu/` | set-waybar-ubuntu-config.sh (retira la config legacy sway `config` con backup) |
| bash, vim, rofi, alacritty, imv default | `config/...` | resto de set-*-config.sh |

## Capa Hyprland

### hyprland.lua (config principal)

Base: ejemplo vanilla 0.56 con `kb_layout=es`. Los módulos propios se
cargan al FINAL (`require("bindings")` y `require("looknfeel")`). OJO:
Hyprland no reemplaza un bind al redefinir la misma tecla — dispara TODOS
los que coinciden (a diferencia de i3) —, por eso bindings.lua desliga
explícitamente cada default que reutiliza (Q, E, LEFT, RIGHT, SHIFT+S del
ejemplo 0.56; M, J, P más un bloque defensivo K/L/O/W/MINUS).

### Monitores

Disposición volcada desde wdisplays (2026-09-25): LG 24" vertical
(transform 3) en `0x0`; GS27Q X a 2560x1440@240 en `1080x480`. Reglas
explícitas primero (la primera que matchea gana), comodín `""` al final
como fallback para displays desconocidos. La posición se calcula con la
resolución YA transformada (la LG vertical presenta 1080 de ancho).

Flujo de cambio: ajustar en caliente con wdisplays/wlr-randr (runtime-only,
no persisten) → volcar el estado (`hyprctl monitors`) a reglas `hl.monitor`
en `config/hypr/ubuntu/hyprland.lua` → re-ejecutar el instalador.

### Layout español

`kb_layout=es` en la config principal (tildes y Ñ; la tecla NTILDE es
workspace 11 en el esquema por letras).

## Equivalencias con la capa Omarchy

| Capa Omarchy | Variante Ubuntu |
|---|---|
| Terminal y menús del shell | `alacritty` y `rofi -show drun` (stack del viejo i3) |
| `omarchy-audio-*` / `omarchy-shell media` | `pactl` / `playerctl` (tomados de config/i3/i3) |
| Menús lock/exit/wallpaper (`omarchy-menu`) | (backlog #2/#1): adaptar menús rofi (`i3-msg exit` → `hyprctl dispatch exit`; i3lock no sirve en Wayland → hyprlock; feh → hyprpaper/swaybg) |
| Tema Omarchy (colores/gaps) | Defaults vanilla; looknfeel.lua aporta animaciones off + smart gaps |
| Gestión de monitores | `wdisplays`/`wlr-randr` en caliente + `hl.monitor` explícitos para persistir |
| Barra (omarchy-shell) | waybar minimal (abajo): workspaces+ventana \| reloj \| bandeja+audio — config/waybar/ubuntu/, autostart desde hyprland.lua; portada de la vieja config sway |

## Barra waybar: elementos e interacciones

Layout minimal (abajo): workspaces+ventana | reloj | bandeja+audio.

| Zona | Elemento | Interacciones |
|---|---|---|
| Izq | Workspaces 1-12 | Click = ir al workspace; activo en ámbar (FECA88); hover gris |
| Izq | Título de la ventana enfocada | Solo lectura (máx 40 caracteres) |
| Centro | Reloj HH:MM | Hover = calendario del mes |
| Der | Bandeja (tray): bluetooth (blueman, si hay adaptador) — apps con tray propio se suman solas | Click = menú de la app |
| Der | Red (módulo waybar) | Click = nm-connection-editor · Hover = interfaz + IP · click der = formato alternativo |
| Der | Audio | Click = mute/unmute · Click der = pavucontrol (mixer) · Rueda = volumen ±5% |

Nota: `format-muted` de la config sway original estaba vacío — al mutear,
el módulo desaparecía y parecía perderse el sonido. Ahora muestra glifo +
"muted". Los glifos FontAwesome se transplantan byte a byte desde la
config legacy (no sobreviven a la edición manual).

## Backlog incremental

Enfoque minimal-primero: se agrega de a uno por decisión, no por paridad
con Omarchy. Esfuerzo: S (<30 min) / M (una sesión) / L (varias).

| # | Feature | Esfuerzo | Nota |
|---|---|---|---|
| 1 | Wallpaper: hyprpaper + `backgrounds/` | S | Lo más visible tras la barra |
| 2 | Lock + exit: hyprlock + menú rofi (`hyprctl dispatch exit`) | M | Equivalen a `$mod+Escape` / `$mod+Shift+e` de i3 |
| 3 | Re-agregar cpu/red/mem a la barra | S | Bloques y glifos en git history |
| 4 | Notificaciones (mako/dunst) | L | Omarchy las trae de serie |
| 5 | Media/OSD (playerctl en barra u OSD) | L | Los binds ya funcionan |

## Validación

```bash
hyprctl reload && hyprctl configerrors   # debe salir limpio; probar Ñ y tildes
hyprctl binds                            # sin keys duplicadas (ver unbinds)
Hyprland --verify-config                 # opcional, offline
```

## Reversión

- PPA completo: `sudo ppa-purge ppa:cppiber/hyprland`
- Cada config gestionada deja `*.bak.<epoch>` al modificarse: restaurar y
  `hyprctl reload`
- Helpers en `~/.local/bin/hypr-*` (borrables a mano)
