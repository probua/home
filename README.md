# home — instaladores del entorno de trabajo

Entorno activo: **Omarchy** (Arch + Hyprland). El instalador de entrada es
`install-on-omarchy.sh`; es idempotente (re-ejecutar no tiene efecto).

## Instalación remota (sin git)

```bash
tmp=$(mktemp -d) \
  && curl -sL https://github.com/probua/home/archive/refs/heads/main.tar.gz | tar xz -C "$tmp" \
  && cd "$tmp/home-main" && ./install-on-omarchy.sh
```

El tarball pesa ~5 MB. El directorio temporal se limpia solo al reiniciar
(`/tmp` es tmpfs), o manualmente con `rm -rf "$tmp"`.

## Instalación local (con git)

```bash
git clone https://github.com/probua/home.git
cd home && ./install-on-omarchy.sh
```

## Legacy (Ubuntu/i3)

`config/scripts/auto-install/` es el flujo histórico de Ubuntu y no se
mantiene (referencia `install-config.sh`, eliminado del repo).

## AutoHotKey en Windows

Descargar https://www.autohotkey.com/, abrir `Win+R` → `shell:startup` y
crear un acceso directo al script ahí.
