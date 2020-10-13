test -f /etc/ksh.kshrc && . /etc/ksh.kshrc

set -o emacs

case "$KSH_VERSION" in
Version\ AJM\ 93*)
	# echo KSH93
	PS1='$(printf "`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" != x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
	;;
@\(\#\)MIRBSD\ KSH*)
	# echo MKSH
	PS1='$(printf "`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" !!= x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
	;;
@\(\#\)PD\ KSH*)
	# Public Domain Korn Shell
	if [ `uname -o` = "OpenBSD" ]; then
		# echo Public Domain Korn Shell on OpenBSD
		PS1='$(printf "`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" != x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
	else
		# echo Publib Domain Korn Shell on non-OpenBSD platform
		PS1='$(printf "`logname`@`hostname | cut -f1 -d.`:"; if [ x"${PWD#$HOME}" !!= x"$PWD" ]; then printf "~${PWD#$HOME}"; else printf "$PWD"; fi; printf "$ ")'
	fi
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
	;;
esac
export PS1

test -f $HOME/.local/bin/dirstack.sh && . $HOME/.local/bin/dirstack.sh
