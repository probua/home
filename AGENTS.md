# AGENTS.md

Este documento da contexto a los agentes (opencode, Claude, etc.) que trabajan
en este repositorio. Léelo completo antes de tocar nada.

## Propósito del repo

Repositorio de instaladores del entorno de trabajo personal. El entorno activo
es **Omarchy** (Arch + Hyprland); el instalador de entrada es
`install-on-omarchy.sh`. Existe un instalador antiguo de uso general
(`install-config.sh`, i3/Ubuntu) que queda como legacy: no se mantiene ni se
extiende, pero se conserva como referencia histórica.

**Regla de oro:** cualquier modificación en la experiencia del entorno Omarchy
debe configurarse a través de `install-on-omarchy.sh` (nuevo script
`set-*-config.sh` o extensión de uno existente). Nunca dejar configuración
manual en `~` que el instalador no pueda reproducir: el objetivo es que una
máquina limpia con Omarchy converja al estado deseado ejecutando el instalador
una o varias veces.

## Arquitectura

### Puntos de entrada

- `install-on-omarchy.sh` — instalador activo. Hace `source` en orden de los
  scripts de `config/scripts/set-*-config.sh`. Ese es el único flujo soportado.
- `install-config.sh` — legacy (Ubuntu/i3). No tocar salvo pedido explícito.

### Modelo de los scripts `set-*-config.sh`

- Cada script se **auto-ejecuta al sourcearse** (define funciones y las invoca
  al final) y también es ejecutable standalone desde la raíz del repo:
  `source config/scripts/set-foo-config.sh`.
- Los scripts asumen que el CWD es la raíz del repo (las rutas fuente son
  relativas: `config/...`, `backgrounds/...`).
- Scripts activos en Omarchy: `set-bash-config.sh`, `set-vim-config.sh`,
  `set-hyprland-config.sh`, `set-omarchy-shell-config.sh`,
  `set-omarchy-theme-config.sh`, `set-docker-user-config.sh`,
  `set-default-browser-config.sh`.
- Scripts legacy (comentados en el instalador): rofi, picom, i3, alacritty,
  kmonad, autohotkey. No reactivar sin pedido explícito.

### Mapa de directorios

| Ruta | Contenido |
|---|---|
| `config/hypr/` | `bindings.lua` (capa de hotkeys) y `looknfeel.lua`; `scripts/` se copia a `~/.local/bin/` |
| `config/omarchy/` | `shell.toml` (override máquina) y `themes/probua/` (colors.toml, hyprland.lua, vscode.json) |
| `config/scripts/` | instaladores modulares `set-*.sh` + scripts legacy i3 |
| `config/bash/`, `config/vimrc` | dotfiles base (bash se concatena en orden fijo) |
| `backgrounds/` | wallpapers; se instalan en `~/.config/omarchy/backgrounds/probua/` |
| `bin/submodules/` | helpers de submodules (histórico) |
| `MIGRATION-omarchy.md` | documento clave: migración i3→Omarchy, equivalencias de hotkeys, decisiones y racional de cada capa. **Consultarlo antes de tocar bindings o el shell** |
| `MIGRATION-ubuntu.md` | variante Ubuntu (Hyprland vanilla): tracking de instalación (PPA/apt/configs), monitores, waybar y fase 2. **Consultarlo antes de tocar la capa Ubuntu** |

## Convenciones de idempotencia (obligatorias)

Todo script nuevo o modificado debe cumplir estos patrones, ya consolidados en
el repo:

1. **Re-runs silenciosos y sin efecto**: si el destino ya converge, no se
   escribe, no se reinicia nada, no se imprime ruido. Patrón base:
   `cmp -s origen destino` antes de copiar.
2. **Backup antes de sobrescribir** un archivo gestionado que ya existe y
   difiere: `cp destino destino.bak.$(date +%s)`.
3. **Escrituras in-place** (`cat tmp > destino`, nunca `mv` ni re-crear) en
   archivos que el omarchy-shell watchea (QML, TOML, JSON de
   `~/.config/omarchy/`): reemplazar el inode despista al watcher.
4. **Parches por fases con marcador de aplicado**: cada fase detecta si ya está
   aplicada (grep de un marcador) y se salta. Si el anclaje upstream no existe
   o no es único, la fase se omite con aviso por stderr y el script sigue o
   falla de forma grácil — nunca romper el estado existente ante deriva
   upstream.
5. **Acciones con efecto lateral solo si hubo delta**: `hyprctl reload`,
   `omarchy-restart-shell`, re-`omarchy theme set` únicamente cuando se aplicó
   algún cambio.
6. **Guards ante dependencias ausentes**: `command -v`, comprobar que el
   grupo/archivo existe, etc. — omitir con mensaje claro en lugar de fallar
   (ver `set-docker-user-config.sh`, `set-default-browser-config.sh`).

## Notas específicas de Omarchy

- **Plugins del shell**: los widgets se personalizan clonando el built-in
  (`omarchy plugin clone omarchy.<widget>` → `~/.config/omarchy/plugins/
  $USER.<widget>/`) y parcheando el QML clonado. El clon es un fork: la deriva
  de features upstream NO llega sola; los parches usan anclajes únicos y
  detectan deriva para avisar. Reversión: `omarchy plugin remove <id>`.
- **Tema propio `probua`**: los archivos versionados son solo `colors.toml`,
  `hyprland.lua` y `vscode.json` (el resto los genera Omarchy). El despliegue
  real vive en `~/.local/state/omarchy/current/theme/`: tras cambiar archivos
  hay que re-aplicar con `omarchy theme set probua`, y si ya está activo usar
  `OMARCHY_THEME_SKIP_BACKGROUND=1` para no rotar el fondo.
- **Estado runtime**: `~/.local/state/omarchy/` (tema activo, toggles lua).
  Las actualizaciones de Omarchy nunca tocan `~/.config/omarchy/`.
- **shell.json**: editar con `jq` (check con `jq -e` antes, escritura in-place).
- **Racional y equivalencias de hotkeys**: ver `MIGRATION-omarchy.md` — es la
  fuente de verdad de por qué cada bind/capa existe.

## Flujo de trabajo requerido

Ante cualquier pedido de cambio en la experiencia del entorno:

1. **Investigar el estado actual**: leer el/los scripts `set-*.sh` implicados
   y el destino real en `~/.config/`, `~/.local/state/omarchy/` (o donde
   corresponda). Entender qué gestiona Omarchy por defecto vs. qué gestiona
   este repo antes de proponer nada.
2. **Presentar un plan de implementación** antes de escribir código: qué
   script se extiende o crea, cómo entra por `install-on-omarchy.sh`, y cómo
   se garantiza la idempotencia (marcador, anclajes, backups, guards).
3. **Implementar** siguiendo las convenciones de este documento y el estilo
   de los scripts existentes (comentarios en español explicando el racional,
   mensajes con prefijo `set-<nombre>-config:`).
4. **Verificar**:
   - Ejecutar el instalador/script dos veces: la primera aplica, la segunda
     debe ser silenciosa y sin reinicios.
   - `hyprctl reload && hyprctl configerrors` debe salir limpio tras tocar
     la capa Hyprland.
   - Si se tocó el shell: comprobar que la barra/lock siguen funcionales tras
     `omarchy-restart-shell`.

## Commits

Convención del repo (prefijos en minúscula): `add:`, `upd:`, `fix:`, `del:`.
**Los commits los gestiona el usuario**: el agente no debe hacer commit, push
ni PR salvo pedido explícito.
