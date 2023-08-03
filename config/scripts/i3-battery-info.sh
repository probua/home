battery_status=$(acpi | awk -F ", " '{print $1}' $1 | awk -F " " '{print $3}' $1)
battery_perc=$(acpi | awk -F ", " '{print $2}' $1)

battery_icon=" "


if [[ "$battery_status" == "Discharging" ]]; then
	if [[ "$battery_perc" = "100%" ]]; then
		battery_icon=" "
	elif [[ "$battery_perc" > "90" ]]; then
		battery_icon=" "
	elif [[ "$battery_perc" > "66" ]]; then
		battery_icon=" "
	elif [[ "$battery_perc" > "33" ]]; then
		battery_icon=" "
	elif [[ "$battery_perc" > "10" ]]; then
		battery_icon=" "
	else
		battery_icon=" "
	fi
fi

if [[ "$battery_perc" != "" ]]; then
	echo "$battery_icon $battery_perc"
fi
