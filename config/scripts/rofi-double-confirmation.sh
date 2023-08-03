#!/bin/bash
rofimods="-l 2 -i"
if [ $(echo -e "No\nYes" | rofi -dmenu $rofimods -p "$1") == "Yes" ]; then
	[ $(echo -e "No\nYes" | rofi -dmenu $rofimods -p "$2") == "Yes" ] && $3
fi
