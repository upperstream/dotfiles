# shellcheck disable=SC1090,SC1091,SC2006,SC2148
#set -eu
#set -x

# echo "entering $HOME/.profile"

if [ "`uname`" = FreeBSD ]; then
	test -x /usr/bin/fortune && /usr/bin/fortune freebsd-tips
elif type fortune >/dev/null 2>&1; then
	fortune
fi

shell=${0##*/}
shell=${shell#-}
shell=${shell#.xsession}
shell=${shell#Xsession}
shell=${shell:=${SHELL##*/}}
# echo "shell=$shell"

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
# echo "ENV=$ENV"

# echo "leaving $HOME/.profile"
