#!/bin/bash
rofimods="-l 2 -i"
[ $(echo -e "Yes\nNo" | rofi -dmenu $rofimods -p "$1") == "Yes" ] && $2
