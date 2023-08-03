MIC_MUTED=""

if [[ "$(pactl get-source-mute @DEFAULT_SOURCE@)" != "Mute: no" ]]; then
	echo "$MIC_MUTED"
fi
