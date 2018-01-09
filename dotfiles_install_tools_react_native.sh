#!/bin/sh

react_native_describe_module() {
	cat <<-EOF
	react_native:
	    install React Native development tools
EOF
}

install_nodebrew() {
	case $os in
		Linux)
			{ has wget || install wget; } && \
			wget -O - https://git.io/nodebrew | perl - setup
			;;
	esac
	rc=$?
	PATH=$HOME/.nodebrew/current/bin:$PATH
	return $rc
}

default_node_version=7.10.1

install_node() {
	node_version=${1:-$default_node_version}
	case $os in
		Linux)
			nodebrew install-binary $node_version
			;;
	esac
	nodebrew use $node_version
}

install_watchman_prerequisites() {
	case $os in
		Linux)
			case $distribution in
				Debian|Devuan|Ubuntu)
					install m4 libtool autoconf pkg-config && \
					install libssl-dev
					;;
			esac
			;;
	esac
}

install_watchman() {
	install_watchman_prerequisites && \
	case $os in
		Linux)
			test -d `echo /tmp/watchman-* | cut -f1 -d' '` || download https://github.com/facebook/watchman/archive/v4.9.0.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/watchman-* && \
			./autogen.sh && \
			./configure --without-python --without-pcre && \
			make && $sudo make install) && \
			rm -rf /tmp/watchman-*
			;;
	esac
}

install_xde_prerequisites() {
	case $os in
		Linux)
			case $distribution in
				Debian|Devuan|Ubuntu)
					install fuse && \
					$sudo modprobe fuse && \
					{ grep fuse /etc/group > /dev/null || $sudo groupadd fuse; } && \
					$sudo usermod -a -G fuse `whoami` && \
					install libgtk2.0 libnspr4 desktop-file-utils xdg-utils zenity
					;;
			esac
			;;
	esac
}

install_xde() {
	install_xde_prerequisites && \
	case $os in
		Linux)
			{ has wget || install wget; } && \
			(cd $HOME/.local/bin; wget https://github.com/expo/xde/releases/download/v2.22.1/xde-2.22.1-x86_64.AppImage) && chmod +x $HOME/.local/bin/xde-*.AppImage
			;;
	esac
}

install_tools_react_native() {
	has nodebrew || install_nodebrew
	has node || install_node
	has create-react-native-app || npm install -g create-react-native-app
	has exp || npm install -g exp
	has watchman || install_watchman
	if [ $with_x11 -eq 1 ]; then
		test -f `echo $HOME/.local/bin/xde-*-x86_64.AppImage | cut -f1 -d' '` || install_xde
	fi
}
