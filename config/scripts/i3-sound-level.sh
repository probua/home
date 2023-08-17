#!/bin/sh

VOLUME_0=""
VOLUME_LOW=""
VOLUME_HIGH=""
SOUND_LEVEL=$(amixer -M get Master | awk -F"[][]" '/%/ { print $2 }' | awk -F"%" 'BEGIN{tot=0; i=0} {i++; tot+=$1} END{printf("%s\n", tot/i) }')

ICON="$VOLUME_0"
if [ "$SOUND_LEVEL" -lt 10 ]; then
	ICON="$VOLUME_0"
elif [ "$SOUND_LEVEL" -lt 40 ]; then
	ICON="$VOLUME_LOW"
else
	ICON="$VOLUME_HIGH"
fi

echo "$ICON" "$SOUND_LEVEL" | awk '{ printf("%s%3s%%\n", $1, $2) }'
