# shellcheck disable=SC1090,SC1091,SC2006,SC2148
#set -x

if [ -f "$HOME/.environment" ]; then
	. "$HOME/.environment"
fi
if type hostname > /dev/null 2>&1 && [ -f "$HOME/.environment.`hostname`" ]; then
	. "$HOME/.environment.`hostname`"
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

case "`echo "$0" | sed 's/^-//;s:^.*/\(.*\)$:\1:'`" in
	ksh*|mksh|oksh)
		ENV=$HOME/.kshrc
		;;
	jsh|sh)
		ENV=$HOME/.shrc
		if [ -f "$ENV" ]; then
			. "$ENV"
		fi
		;;
	ash)
		ENV=$HOME/.shrc
		;;
	dash)
		ENV=$HOME/.shrc
		;;
	bash)
		ENV=$HOME/.bashrc
		if [ -f "$ENV" ]; then
			. "$ENV"
		fi
		;;
esac

export ENV
