pstatus=$(playerctl status)

picon=""
if [[ "$pstatus" == "Playing" ]]; then
	picon=""
elif [[ "$pstatus" == "Paused" ]]; then
	picon=""
elif [[ "$pstatus" == "Stopped" ]]; then
	picon=""
fi
echo $picon
