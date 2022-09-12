#!/bin/bash

echo '# prompt
prompt="~/projects/probua/home/config/bash/prompt"
if [ -f $prompt ]; then
    . $prompt
fi

# alias
alias="~/projects/probua/home/config/bash/alias"
if [ -f $alias ]; then
    . $alias
fi
' > ~/.bashrc

cat ~/projects/probua/home/config/bash/optional >> ~/.bashrc
