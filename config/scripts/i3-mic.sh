MIC_MUTED=" Microphone"

if [[ "$(pactl get-source-mute @DEFAULT_SOURCE@)" != "Mute: no" ]]; then
	echo "$MIC_MUTED"
fi
