#!/bin/bash

rofimods="-l 6 -i"

wallpapers_path="~/projects/probua/wallpapers"
wallpaper=$(ls ~/projects/probua/wallpapers | grep .jpg | rofi -dmenu $rofimods -p " Wallpaper:")

feh --bg-fill ~/projects/probua/wallpapers/$wallpaper
