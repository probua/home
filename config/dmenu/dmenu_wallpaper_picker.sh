#!/bin/bash

dmenumods="-i -fn "Hack-16" \
	-nb "#181818" \
	-nf "#ffd787" \
	-sb "#ffd787" \
	-sf "#181818""

wallpapers_path="~/projects/probua/wallpapers"
wallpaper=$(ls ~/projects/probua/wallpapers | grep wp_ | dmenu $dmenumods -p "Wallpaper:")

feh --bg-fill ~/projects/probua/wallpapers/$wallpaper
