ICON=""
OFF=" "
ON=" "

if [[ "$(pactl get-source-mute @DEFAULT_SOURCE@)" != "Mute: no" ]]; then
	echo "$ICON $OFF"
else
	echo "$ICON $ON"
fi
