icon=" "
total=$(brightnessctl m)
used=$(brightnessctl g)

echo "$icon" "$total" "$used" | awk '{ printf("%s  %.f%%\n"), $1, $3/$2*100 }'
