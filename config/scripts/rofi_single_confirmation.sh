#!/bin/bash
rofimods="-l 2 -i"
[ $(echo -e "No\nYes" | rofi -dmenu $rofimods -p "$1") == "Yes" ] && $2
