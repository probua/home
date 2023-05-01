pstatus=$(playerctl status)

picon=""
if [[ "$pstatus" == "Playing" ]]; then
	picon=""
elif [[ "$pstatus" == "Paused" ]]; then
	picon=""
fi

if [[ "$picon" == "" ]]; then
	echo ""
else
	partist=$(playerctl metadata artist)
	if [[ "$partist" != "" ]]; then
		if [[ ${#partist} -gt 20 ]] ; then
			partist=" ${partist:0:17}..."
		else
			partist=" $partist"
		fi
	fi
	ptitle=$(playerctl metadata title)
	if [[ "$ptitle" != "" ]]; then
		if [[ ${#ptitle} -gt 20 ]] ; then
			ptitle=" - ${ptitle:0:17}..."
		else
			ptitle=" - $ptitle"
		fi
	fi
	palbum=$(playerctl metadata album)
	if [[ "$palbum" != "" ]]; then
		if [[ ${#palbum} -gt 20 ]] ; then
			palbum=" - ${palbum:0:17}..."
		else
			palbum=" - $palbum"
		fi
	fi
	play="$partist$ptitle$palbum"
	if [[ ${#play} -gt 45 ]]; then
		echo "${play:0:42}..."
	else
		echo $play
	fi
fi
