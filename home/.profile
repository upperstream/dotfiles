#set -x

test -f $HOME/.environment && . $HOME/.environment
test -f $HOME/.environment.`hostname` && . $HOME/.environment.`hostname`
for f in $HOME/.environment_*; do
	test -f $f && . $f
done

if [ `uname` = FreeBSD ]; then
	test -x /usr/bin/fortune && /usr/bin/fortune freebsd-tips
elif command -v fortune 2>&1 >/dev/null; then
	fortune
fi

case "$0" in
	-ksh|-mksh)
		ENV=$HOME/.kshrc
		;;
	-sh)
		ENV=$HOME/.shrc
		;;
	-ash)
		ENV=$HOME/.shrc
		;;
	-dash)
		ENV=$HOME/.shrc
		;;
	-bash)
		ENV=$HOME/.bashrc
		test -f $ENV && . $ENV
		;;
esac
