#!/bin/bash

sudo curl -o- -L https://slss.io/install | bash # install serverless
sudo curl -o- -L https://raw.githubusercontent.com/probua/home/main/config/scripts/auto-install/install-kmonad.sh | bash # install kmonad
sudo curl -o- -L https://raw.githubusercontent.com/probua/home/main/config/scripts/auto-install/install-docker.sh | bash # install docker
mkdir -p ~/.config/probua
sudo curl -o- -L https://raw.githubusercontent.com/probua/home/main/config/scripts/auto-install/install-home.sh | bash # install home
sudo curl -o- -L https://raw.githubusercontent.com/probua/home/main/config/scripts/auto-install/install-wallpapers.sh | bash # install wallpapers
sudo usermod -aG docker probua
sudo usermod -aG video probua
sudo timedatectl set-timezone America/Lima