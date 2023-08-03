#!/bin/bash

echo '# prompt
. ~/workspace/probua/home/config/bash/prompt

# alias
. ~/workspace/probua/home/config/bash/alias
' > ~/.bashrc

cat ~/projects/probua/home/config/bash/run >> ~/.bashrc
