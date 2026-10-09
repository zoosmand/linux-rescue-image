# Shared interactive shell settings for root and rescue.
case $- in
    *i*) ;;
    *) return ;;
esac

if ! declare -F _init_completion >/dev/null && [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi
if [ -r /usr/lib/git-core/git-sh-prompt ]; then
    . /usr/lib/git-core/git-sh-prompt
fi

PS1='[\[\e[2;4m\]\u\[\e[0m\]@\[\e[1m\]\h\[\e[0m\] \[\e[1;92m\]\W\[\e[0;91m\]$(__git_ps1 " (%s)")\[\e[00m\]]$ '
