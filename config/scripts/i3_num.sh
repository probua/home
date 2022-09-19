num=$(xset q | grep Num | awk '{print $8}')

if [ "$num" == "on" ] ; then
	echo "[NUM]"
fi;
