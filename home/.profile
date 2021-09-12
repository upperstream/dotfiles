#set -x

if [ -f $HOME/.environment ]; then
	. $HOME/.environment
fi
if command -v hostname > /dev/null && [ -f $HOME/.environment.`hostname` ]; then
	. $HOME/.environment.`hostname`
fi
for f in $HOME/.environment_*; do
	if [ -f $f ]; then
		. $f
	fi
done

if [ `uname` = FreeBSD ]; then
	test -x /usr/bin/fortune && /usr/bin/fortune freebsd-tips
elif command -v fortune 2>&1 >/dev/null; then
	fortune
fi

case "`echo ${0##*/} | sed 's/^-//'`" in
	ksh*|mksh)
		ENV=$HOME/.kshrc
		;;
	sh)
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
		if [ -f $ENV ]; then
			. $ENV
		fi
		;;
esac
