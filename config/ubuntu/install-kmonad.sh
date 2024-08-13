#!/bin/bash
wget https://github.com/kmonad/kmonad/releases/download/0.4.2/kmonad
mv ./kmonad /usr/bin/kmonad
chmod +x /usr/bin/kmonad

wget https://raw.githubusercontent.com/probua/home/main/config/kmonad/kmonad.service
mv ./kmonad.service /etc/systemd/system
systemctl start kmonad.service
systemctl enable kmonad.service