test -f /etc/ksh.kshrc && . /etc/ksh.kshrc

set -o emacs

case "$TERM" in
	xterm-color|*-256color) _coloured_prompt=yes;;
esac

case "$KSH_VERSION" in
Version\ AJM\ 93*)
	# echo KSH93
	if [ "$_coloured_prompt" = yes ]; then
		PS1='$(printf "\033[32m$(logname)@$(hostname | cut -f1 -d.)\033[00m:\033[34m"; if [ x"${PWD#$HOME}" != x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "\033[00m$ ")'
	else
		PS1='$(printf "`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" != x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
	fi
	;;
@\(\#\)MIRBSD\ KSH*)
	# echo MKSH
	if [ "$_coloured_prompt" = yes ]; then
		PS1=$'\1\r\1\e[32m\1${LOGNAME:-${USERNAME:-$(logname)}}@${HOSTNAME:-$(hostname)}\1\e[00m\1:\1\e[34m\1$(if [ x"${PWD#$HOME}" !!= x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi)\1\e[00m\1$ '
	else
		PS1=$'${LOGNAME:-${USERNAME:-$(logname)}}@${HOSTNAME:-$(hostname)}:$(if [ x"${PWD#$HOME}" !!= x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi)$ '
	fi
	bind '^I'=complete
	;;
@\(\#\)PD\ KSH*)
	# Public Domain Korn Shell
PS1=$(printf '\033[32m$(logname)@$(hostname)\033[00m$ ')
	if [ `uname -s` = "OpenBSD" ]; then
		# echo Public Domain Korn Shell on OpenBSD
		if [ "$_coloured_prompt" = yes]; then
			PS1='$(printf "\033[32m$(logname_@$(hostname | cut -f1 -d.)\033[00m:\033[34m"; if [ x"${PWD#$HOME}" != x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "\033[00m$ ")'
		else
			PS1='$(printf "$`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" != x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
		fi
	else
		# echo Publib Domain Korn Shell on non-OpenBSD platform
		if [ "$_coloured_prompt" = yes ]; then
		PS1='$(printf "\033[32m$(logname)@$(hostname | cut -f1 -d.)\033[00m:\033[34m"; if [ x"${PWD#$HOME}" !!= x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "\033[00m$ ")'
		else
		PS1='$(printf "`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" !!= x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
		fi
	fi
	bind '^I'=complete
	;;
*)
	# echo Other KSH variants
	_hostname=`hostname | sed 's/\..*//'`
	if [ -z "$_hostname" ]; then
		PS1="`logname`"
	else
		PS1="`logname`@$hostname"
	fi
	unset _hostname
	case `id -u` in
		0) PS1="${PS1}# ";;
		*) PS1="${PS1}$ ";;
	esac
	bind '^I'=complete
	;;
esac
export PS1
unset _coloured_prompt

test -f $HOME/.local/bin/dirstack.sh && . $HOME/.local/bin/dirstack.sh
