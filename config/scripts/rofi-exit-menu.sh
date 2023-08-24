#!/bin/bash
rofimods="-l 4 -i"

rofi_select=$(echo -e "Lock screen\nClose session\nReboot \nShutdown" | rofi -dmenu $rofimods -p "Exit")
if [[ "$rofi_select" != "" ]]; then
	if [[ $rofi_select == *"Lock screen"* ]]; then
			source ~/.config/probua/scripts//rofi-single-confirmation.sh "Confirm lock screen" "source $HOME/.config/probua/scripts/i3-lock.sh"
	elif [[ $rofi_select == *"Close session"* ]]; then
			source ~/.config/probua/scripts//rofi-single-confirmation.sh "Confirm close session" "i3-msg exit"
	elif [[ $rofi_select == *"Reboot"* ]]; then
			source ~/.config/probua/scripts//rofi-single-confirmation.sh "Confirm reboot" "reboot"
	elif [[ $rofi_select == *"Shutdown"* ]]; then
			source ~/.config/probua/scripts//rofi-single-confirmation.sh "Confirm shutdown" "shutdown now"
	fi
fi

