sudo cp config/kmonad/kmonad.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl start kmonad.service
sudo systemctl enable kmonad.service