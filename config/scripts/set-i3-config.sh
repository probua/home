#!/bin/bash

mkdir -p ~/.config/i3
mkdir -p ~/.config/i3blocks
mkdir -p ~/.config/probua
cat config/i3/i3 > ~/.config/i3/config
cat config/i3/i3blocks > ~/.config/i3blocks/config
cp -r config/scripts/ ~/.config/probua/
echo "i3-sensible-terminal" > ~/.config/i3/terminal
