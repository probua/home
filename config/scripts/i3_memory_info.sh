#icon=" "
icon=" "
total=($(free | awk -F "Mem:" '{print $2}' | awk -F " " '{print $1}'))
used=($(free | awk -F "Mem:" '{print $2}' | awk -F " " '{print $2}'))

echo "$icon" "$total" "$used" | awk '{ printf("%s   %.2f%%\n"), $1, $3/$2*100 }'
