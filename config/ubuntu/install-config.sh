#!/bin/bash

# bash
curl -L https://raw.githubusercontent.com/probua/home/main/config/bash/prompt > /home/probua/.bashrc
curl -L https://raw.githubusercontent.com/probua/home/main/config/bash/alias >> /home/probua/.bashrc
curl -L https://raw.githubusercontent.com/probua/home/main/config/bash/default >> /home/probua/.bashrc
curl -L https://raw.githubusercontent.com/probua/home/main/config/bash/run >> /home/probua/.bashrc

# vim
curl -fLo /home/probua/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -L https://raw.githubusercontent.com/probua/home/main/config/vimrc > /home/probua/.vimrc

# rofi
curl -fLo /home/probua/.config/rofi/config.rasi --create-dirs https://raw.githubusercontent.com/probua/home/main/config/rofi

# picom
curl -fLo /home/probua/.config/picom/picom.conf --create-dirs https://raw.githubusercontent.com/probua/home/main/config/picom

# i3
curl -fLo /home/probua/.config/i3/config --create-dirs https://raw.githubusercontent.com/probua/home/main/config/i3/i3
curl -fLo /home/probua/.config/i3blocks/config --create-dirs https://raw.githubusercontent.com/probua/home/main/config/i3/i3blocks
echo "i3-sensible-terminal" > /home/probua/.config/i3/terminal

# alacritty
curl -fLo /home/probua/.alacritty.yml --create-dirs https://raw.githubusercontent.com/probua/home/main/config/alacritty/alacritty.yml
curl -fLo /home/probua/.alacritty.toml --create-dirs https://raw.githubusercontent.com/probua/home/main/config/alacritty/alacritty.toml
echo "alacritty" > /home/probua/.config/i3/terminal

# kmonad
curl -fLo /home/probua/.config/kmonad/kbd/ziyoulang-k68.kbd --create-dirs https://raw.githubusercontent.com/probua/home/main/config/kmonad/kbd/ziyoulang-k68.kbd

# probua scripts
git clone https://github.com/probua/home.git /home/probua/init
cp -r /home/probua/init/config/scripts/ /home/probua/.config/probua/