# Home Files

## .bashrc

```bash
curl -O https://raw.githubusercontent.com/probua/home/main/.bashrc > $HOME/.bashrc
```

## .vimrc

```bash
curl -O https://raw.githubusercontent.com/probua/home/main/.vimrc > $HOME/.vimrc
```

## .alacritty

### Linux

```bash
# Download into alacritty configuration
curl -O https://raw.githubusercontent.com/probua/home/main/.alacritty.yml > $HOME/.alacritty.yml
```

### Windows

```bash
# Download into alacritty configuration
curl -O https://raw.githubusercontent.com/probua/home/main/.alacritty.yml > $APPDATA/alacritty/alacritty.yml
```
```bash
# Create Link on Home (Run Git Bash as Administrator)
> export MSYS=winsymlinks:nativestrict
> ln -s $APPDATA/alacritty/alacritty.yml $HOME/.alacritty.yml
```

```yml
# Uncomment this lines
shell:
    program: "C:\\Program Files\\Git\\bin\\bash.exe"
key_bindings:
    - { key: T, mods: Control|Alt, action: SpawnNewInstance }
```