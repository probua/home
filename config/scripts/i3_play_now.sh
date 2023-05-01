pstatus=$(playerctl status)

picon=""
if [[ "$pstatus" == "Playing" ]]; then
	picon=""
elif [[ "$pstatus" == "Paused" ]]; then
	picon=""
elif [[ "$pstatus" == "Stopped" ]]; then
	picon=""
fi

if [[ "$picon" == "" ]]; then
	echo ""
else
	partist=$(playerctl metadata artist)
	if [[ "$partist" != "" ]]; then
		partist="   $partist"
	fi
	ptitle=$(playerctl metadata title)
	if [[ "$ptitle" != "" ]]; then
		ptitle=" - $ptitle"
	fi
	palbum=$(playerctl metadata album)
	if [[ "$palbum" != "" ]]; then
		palbum=" - $palbum"
	fi
	echo "$picon$partist$palbum$ptitle"
fi
