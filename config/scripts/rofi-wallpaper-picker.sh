#!/bin/bash

rofimods="-l 6 -i"

wallpapers_path="~/workspace/probua/wallpapers"
wallpaper=$(ls ~/workspace/probua/wallpapers | grep .jpg | rofi -dmenu $rofimods -p "Wallpaper")

if [ "$wallpaper" != "" ]; then
	feh --bg-fill ~/workspace/probua/wallpapers/$wallpaper
fi
