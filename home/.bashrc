set -o emacs

case "$TERM" in
	xterm-color|*-256color) _coloured_prompt=yes;;
esac

if [ "$_coloured_prompt" = yes ]; then
    PS1='\[\e[32m\]\u@\h\[\e[00m\]:\[\e[34m\]\W\[\e[00m\]$ '
else
    PS1='\u@\h:\W$ '
fi
unset _coloured_prompt
