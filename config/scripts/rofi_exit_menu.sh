#!/bin/bash
rofimods="-l 3 -i"

rofi_select=$(echo -e "Close\nLock\nShutdown" | rofi -dmenu $rofimods -p "$1")
if [ "$rofi_select" != "" ]; then
	case $rofi_select in
		Close)
			source ~/projects/probua/home/config/scripts/rofi_double_confirmation.sh "  Close session" "  Confirm close session" "echo close" "i3-msg exit"
			;;
		Lock)
			source ~/projects/probua/home/config/scripts/rofi_double_confirmation.sh " Lock screen" " Confirm lock screen" "echo lock" "dm-tool lock"
			;;
		Shutdown)
			source ~/projects/probua/home/config/scripts/rofi_double_confirmation.sh " Shutdown" "  Confirm shutdown " "echo shutdown" "shutdown now"
			;;
	esac
fi
