#!/bin/bash

rofimods="-l 6 -i"
wallpapers_path="~/.config/probua/wallpapers"
wallpaper=$(ls ~/.config/probua/wallpapers | grep .jpg | rofi -dmenu $rofimods -p "Wallpaper")

if [ "$wallpaper" != "" ]; then
	feh --bg-fill ~/.config/probua/wallpapers/$wallpaper
fi
