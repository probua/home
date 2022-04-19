# probua-theme
function git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
# http://unix.stackexchange.com/questions/88307/escape-sequences-with-echo-e-in-different-shells
function markup_git_branch {
	if [[ "x$1" == "x" ]]; then
    	echo -e "$1"
	else
    	if [[ $(git status 2> /dev/null | tail -n1) == *"nothing to commit"* ]]; then
      		echo -e 'git:'"$1"
    	else
      		echo -e 'git:''\033[0;38;5;210m'"$1"
    	fi
  	fi
}

PS1='\[\e[0;38;5;222m\]\u@\h \[\e[0;38;5;39m\]\w \[\e[0m\]$(markup_git_branch $(git_branch))
\[\e[0;38;5;222m\]> \[\e[0m\]'

# alias
alias gs="git status -s"
alias ll="ls -lah --color=auto --group-directories-first"
alias gl="git log --graph --abbrev-commit --decorate --format=format:'%C(yellow)%h%C(reset) %C(green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold red)%d%C(reset)' --all"

#git alias
git config --global alias.lg "log --graph --abbrev-commit --decorate --format=format:'%C(yellow)%h%C(reset) %C(green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold red)%d%C(reset)' --all"

cd
