#!/bin/sh

OFF=" "
ON=" "
ICON=""
SOUND_MUTED=""
MUTED=$(amixer get Master | awk ' /%/{print ($NF=="[off]" ? 1 : 0); exit;}')

if [ "$MUTED" = "1" ]; then
#	echo "$ICON $OFF" 
	echo "$SOUND_MUTED"
else
#	echo "$ICON $ON"
	echo "$ICON"
fi
