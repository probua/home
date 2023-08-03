#!/bin/bash
rofimods="-l 4 -i"

rofi_select=$(echo -e " Lock screen\n Close session\n Reboot \n Shutdown" | rofi -dmenu $rofimods -p "Exit:")
if [[ "$rofi_select" != "" ]]; then
	if [[ $rofi_select == *"Lock screen"* ]]; then
			source ~/workspace/probua/home/config/scripts/rofi_single_confirmation.sh " Confirm lock screen:" "dm-tool lock"
	elif [[ $rofi_select == *"Close session"* ]]; then
			source ~/workspace/probua/home/config/scripts/rofi_single_confirmation.sh " Confirm close session:" "i3-msg exit"
	elif [[ $rofi_select == *"Reboot"* ]]; then
			source ~/workspace/probua/home/config/scripts/rofi_single_confirmation.sh " Confirm reboot:" "reboot"
	elif [[ $rofi_select == *"Shutdown"* ]]; then
			source ~/workspace/probua/home/config/scripts/rofi_single_confirmation.sh " Confirm shutdown:" "shutdown now"
	fi
fi

