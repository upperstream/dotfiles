# .bash_profile
if [ -f $HOME/.profile ]; then
	. $HOME/.profile
else
	if [ -f $HOME/.bashrc ]; then
		. $HOME/.bashrc
	fi
	PATH=$PATH:$HOME/.local/bin:$HOME/bin
	export PATH
fi
