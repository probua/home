#!/bin/bash
dmenumods="-i -fn "Hack-14" -nb "#181818" -nf "#ffd787" -sb "#181818" -sf "#00afff""
if [ $(echo -e "No\nSi" | dmenu $dmenumods -p "$1") == "Si" ]; then
	[ $(echo -e "No\nSi" | dmenu $dmenumods -p "$2") == "Si" ] && $3
fi
