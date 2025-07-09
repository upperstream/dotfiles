# shellcheck disable=SC1090,SC1091,SC2006,SC2148
set -eu
#set -x

# echo "entering $HOME/.profile"

if [ -f "$HOME/.environment" ]; then
	. "$HOME/.environment"
fi

if type hostname > /dev/null 2>&1; then
	_hostname=`hostname`
	if [ -f "$HOME/.environment.${_hostname%%.*}" ]; then
		. "$HOME/.environment.${_hostname%%.*}"
	fi
fi

for f in "$HOME"/.environment_*; do
	if [ -f "$f" ]; then
		. "$f"
	fi
done

if [ "`uname`" = FreeBSD ]; then
	test -x /usr/bin/fortune && /usr/bin/fortune freebsd-tips
elif type fortune >/dev/null 2>&1; then
	fortune
fi

shell=${0##*/}
shell=${shell#-}
shell=${shell#.xsession}
# echo "shell=${shell:=${SHELL##*/}}"

case "$shell" in
	ksh*|mksh|oksh)
		ENV=$HOME/.kshrc
		;;
	jsh|posh|sh)
		ENV=$HOME/.shrc
		;;
	ash)
		ENV=$HOME/.shrc
		;;
	dash)
		ENV=$HOME/.shrc
		;;
	bash)
		ENV=$HOME/.bashrc
		;;
esac
unset shell

export ENV

# echo "leaving $HOME/.profile"
