#!/bin/bash

echo '# prompt
. ~/projects/probua/home/config/bash/prompt

# alias
. ~/projects/probua/home/config/bash/alias
' > ~/.bashrc

cat ~/projects/probua/home/config/bash/optional >> ~/.bashrc
