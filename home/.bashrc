set -o emacs

case "$TERM" in
	xterm-color|*-256color) _coloured_prompt=yes;;
esac

if [ "$_coloured_prompt" = yes ]; then
    PS1='\033[32m\u@\h\033[00m:\033[34m\W\033[00m$ '
else
    PS1='\u@\h:\W$ '
fi
unset _coloured_prompt
