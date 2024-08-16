#!/bin/bash

sudo curl -o- -L https://slss.io/install | bash # install serverless
sudo source config/scripts/auto-install/install-kmonad.sh # install kmonad
sudo source config/scripts/auto-install/install-docker.sh # install docker
sudo source config/scripts/auto-install/install-wallpapers.sh # install wallpapers
sudo usermod -aG docker probua
sudo usermod -aG video probua
source install-config.sh
sudo timedatectl set-timezone America/Lima
sudo passwd probua # update password