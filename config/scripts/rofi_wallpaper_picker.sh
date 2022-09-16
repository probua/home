#!/bin/bash

dmenumods="-l 4"

wallpapers_path="~/projects/probua/wallpapers"
wallpaper=$(ls ~/projects/probua/wallpapers | grep wp_ | rofi -dmenu $dmenumods -p "Wallpaper:")

feh --bg-fill ~/projects/probua/wallpapers/$wallpaper
