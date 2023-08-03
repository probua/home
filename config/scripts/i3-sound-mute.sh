#!/bin/sh

SOUND_MUTED=""
#SOUND_MUTED=""

MUTED=$(amixer get Master | awk ' /%/{print ($NF=="[off]" ? 1 : 0); exit;}')

if [ "$MUTED" = "1" ]; then
	echo "$SOUND_MUTED"
fi
