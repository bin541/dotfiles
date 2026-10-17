# ~/.bashrc

if [ -f ~/.bash_alias ]; then
    . ~/.bash_alias
fi

PROMPT_COMMAND=('printf "\033]2;foot\007"')

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

copy-line-to-clipboard() {
  printf '%s' "$READLINE_LINE" | wl-copy
}
bind -m vi-command -x '"y":copy-line-to-clipboard'

paste-from-clipboard() {
  local clip
  clip=$(wl-paste --no-newline; printf '\001') || return
  clip=${clip%$'\001'}

  READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${clip}${READLINE_LINE:READLINE_POINT}"
  READLINE_POINT=$((READLINE_POINT + ${#clip}))
}
bind -m vi-command -x '"p":paste-from-clipboard'
