#!/bin/bash

sudo curl -o- -L https://slss.io/install | bash
sudo source config/scripts/auto-install/install-kmonad.sh
sudo source config/scripts/auto-install/install-docker.sh
sudo usermod -aG docker probua
sudo usermod -aG video probua
source install-config.sh
sudo timedatectl set-timezone America/Lima