# Auto Install (Tested on Ubuntu 24.04)
```bash
sudo curl -o- -L https://raw.githubusercontent.com/probua/home/main/config/scripts/auto-install/auto-install.sh | bash
```

# Install config
```bash
git clone https://github.com/probua/home.git
cd home
source install-config.sh
cd ..
rm -rf home
```

## Install autohotkey on Windows
Download https://www.autohotkey.com/
Press Win+R to open the run dialog, type "shell:startup" (without quotes) and click ok.
Finally, create a shortcut to your script file and place it in the startup folder.
