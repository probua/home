icon=" "
total=$(brightnessctl -c backlight m)
used=$(brightnessctl -c backlight g)

echo "$icon" "$total" "$used" | awk '{ printf("%s  %.f%%\n"), $1, $3/$2*100 }'
