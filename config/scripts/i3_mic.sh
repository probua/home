ICON=""
MIC_OFF=""
OFF=" "
ON=" "

if [[ "$(pactl get-source-mute @DEFAULT_SOURCE@)" != "Mute: no" ]]; then
#	echo "$ICON $OFF"
	echo "$MIC_OFF"
else
#	echo "$ICON $ON"
	echo "$ICON"
fi
