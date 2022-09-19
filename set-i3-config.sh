#!/bin/bash

mkdir -p ~/.config/i3
ln -s ~/projects/probua/home/config/i3/i3 ~/.config/i3/config
ln -s ~/projects/probua/home/config/i3/i3blocks ~/.config/i3blocks/config
echo "i3-sensible-terminal" > ~/.config/i3/default_terminal
