caps=$(xset q | grep Caps | awk '{print $4}')
if [ "$caps" == "on" ] ; then
	echo ""
fi
