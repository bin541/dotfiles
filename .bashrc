# ~/.bashrc

if [ -f ~/.bash_alias ]; then
    . ~/.bash_alias
fi

[[ $- != *i* ]] && return
PS1="\[\e[30;107m\] \u@\h \[\e[0m\] \W \$ "

if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s -t 86400)" >/dev/null
fi

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export VISUAL="$EDITOR"
export LIBVIRT_DEFAULT_URI="qemu:///system"
export QT_QPA_PLATFORMTHEME="qt6ct"
export GPG_TTY="$(tty)"

set -o vi
bind 'set show-mode-in-prompt on'
bind 'set vi-ins-mode-string "\1\e[6 q\2"'
bind 'set vi-cmd-mode-string "\1\e[2 q\2"'
echo -ne "\e[6 q"
