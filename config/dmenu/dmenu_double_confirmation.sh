#!/bin/bash
dmenumods="-i -fn "Hack-16" \
	-nb "#181818" \
	-nf "#ffd787" \
	-sb "#ffd787" \
	-sf "#181818""
if [ $(echo -e "No\nSi" | dmenu $dmenumods -p "$1") == "Si" ]; then
	[ $(echo -e "No\nSi" | dmenu $dmenumods -p "$2") == "Si" ] && $3
fi
