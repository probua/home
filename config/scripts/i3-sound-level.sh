#!/bin/sh

VOLUME_0=""
VOLUME_LOW=""
VOLUME_HIGH=""

DEFAULT_SINK=$(pactl get-default-sink)
SOUND_LEVEL=$(pactl get-sink-volume $DEFAULT_SINK | sed 's/ //g' | awk -F"/" '{ print $2 }' | awk -F"%" '{ print $1 }' )

#LEFT_SOUND_LEVEL=$(pactl get-sink-volume $DEFAULT_SINK | sed 's/ //g' | awk -F"/" '{ print $2 }' | awk -F"%" '{ print $1 }' )
#RIGHT_SOUND_LEVEL=$(pactl get-sink-volume $DEFAULT_SINK | sed 's/ //g' | awk -F"/" '{ print $4 }' | awk -F"%" '{ print $1 }' )

ICON="$VOLUME_0"
if [ "$SOUND_LEVEL" -lt 5 ]; then
	ICON="$VOLUME_0"
elif [ "$SOUND_LEVEL" -lt 50 ]; then
	ICON="$VOLUME_LOW"
else
	ICON="$VOLUME_HIGH"
fi

#echo "$LEFT_SOUND_LEVEL"
#echo "$RIGHT_SOUND_LEVEL"

echo "$ICON" "$SOUND_LEVEL" | awk '{ printf("%s %s%\n", $1, $2) }'
