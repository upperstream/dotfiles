#!/bin/sh

react_native_describe_module() {
	cat <<-EOF
	react_native:
	    install React Native development tools
EOF
}

install_nodebrew() {
	case $os in
		FreeBSD|Linux|NetBSD)
			{ has wget || install wget; } && \
			wget -O - --no-check-certificate https://git.io/nodebrew | perl - setup
			;;
	esac
	rc=$?
	PATH=$HOME/.nodebrew/current/bin:$PATH
	return $rc
}

default_node_version=7.10.1

install_node_dependencies() {
	case $os in
		FreeBSD)
			install_package python27 && \
			$sudo ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
			;;
		NetBSD)
			install_package python27 && \
			$sudo ln -sf /usr/pkg/bin/python2.7 /usr/pkg/bin/python
			;;
		OpenBSD)
			install_package python-2.7.14 && \
			$sudo ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
			;;
	esac
}

install_node() {
	node_version=${1:-$default_node_version}
	install_node_dependencies && \
	case $os in
		FreeBSD)
			install_package gmake libexecinfo && \
			if [ $prefer_binary_package -eq 1 ]; then
				install gmake && \
				install node6 && \
				if [ ! -f /usr/ports/Makefile ]; then
					fetch -o - http://ftp.jaist.ac.jp/pub/FreeBSD/releases/amd64/amd64/11.1-RELEASE/ports.txz | sudo tar zxpf - -C /
				fi && \
				(install_package gmake && \
				cd /usr/ports/www/npm3 && \
				$sudo make -DBATCH install clean)
			else
				install gmake libexecinfo && \
				CC=cc CXX=c++ nodebrew install $node_version && \
				nodebrew use $node_version
			fi
			;;
		Linux)
			nodebrew install-binary $node_version && \
			nodebrew use $node_version
			;;
		NetBSD)
			if [ $prefer_binary_package -eq 1 ]; then
				install_package nodejs-8.4.0nb1 && \
				$sudo npm install -g npm@4
			else
				{ has cc || download `sed -n 's:^PKG_PATH=\(.*\)/pkgsrc/.*$:\1:p' /etc/pkg_install.conf`/NetBSD/NetBSD-`uname -r`/`uname -m`/binary/sets/comp.tgz | $sudo tar zxpf - -C /; } && \
				install gmake libexecinfo && \
				CC=cc CXX=c++ nodebrew install $node_version && \
				nodebrew use $node_version
			fi
			;;
		OpenBSD)
			if [ $prefer_binary_package -eq 1 ]; then
				install_package node
			else
				{ has gmake || install_package gmake; } && \
				install_package libexecinfo && \
				CC=cc CXX=c++ MAKE=gmake nodebrew install $node_version
			fi
			;;
	esac
}

install_exp() {
	case $os in
		OpenBSD)
			echo "Error: $0: exp does not support $os.  This error is not fatal." 1>&2
			;;
		*)
			$acquire_root_privilege npm install -g exp
			;;
	esac
}

install_watchman_prerequisites() {
	case $os in
		Linux)
			case $distribution in
				CentOS)
					install m4 libtool autoconf pkgconfig gcc-c++ && \
					install openssl-devel
					;;
				Debian|Devuan|Ubuntu)
					install m4 libtool autoconf pkg-config && \
					install libssl-dev
					;;
			esac
			;;
		OpenBSD)
			install_package autoconf-2.69p2 automake-1.15.1 m4 gmake bash
			;;
	esac
}

autogen_watchman() {
	case $os in
		Linux)
			./autogen.sh
			;;
		OpenBSD)
			AUTOCONF_VERSION=2.69 AUTOMAKE_VERSION=1.15 M4=gm4 bash ./autogen.sh
			;;
	esac
}

install_watchman() {
	install_watchman_prerequisites && \
	case $os in
		FreeBSD|NetBSD)
			install watchman
			;;
		Linux|OpenBSD)
			test -d `echo /tmp/watchman-* | cut -f1 -d' '` || download https://github.com/facebook/watchman/archive/v4.9.0.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/watchman-* && \
			autogen_watchman && \
			./configure --without-python --without-pcre && \
			make && $sudo make install) && \
			rm -rf /tmp/watchman-*
			;;
	esac
}

install_exctags() {
	case $os in
		Linux)
			case $distribution in
				CentOS)
					install_package ctags-etags
					;;
				Debian|Devuan|Ubuntu)
					install_package exuberant-ctags
					;;
				*)
					install_package ctags
					;;
			esac
			;;
		NetBSD)
			install_package exctags
			;;
		OpenBSD)
			install_package ectags
			;;
		*)
			install_package ctags
			;;
	esac
}

has_exctags() {
	case $os in
		FreeBSD|NetBSD)
			has exctags
			;;
		Linux)
			case $distribution in
				CentOS)
					has etags.ctags
					;;
				Debian|Devuan|Ubuntu)
					has ctags-exuberant
					;;
				*)
					has ctags
					;;
			esac
			;;
		OpenBSD)
			has ectags
			;;
		*)
            has ctags
			;;
	esac
}

install_from_source_global() {
	compiler_url=`cat /etc/installurl`/`uname -r`/`uname -m`/comp`uname -r | sed 's/^\([0-9]*\)\.\([0-9]*\)$/\1\2/'`.tgz
	download $compiler_url | $sudo tar -zxpf - -C /
	download http://tamacom.com/global/global-6.6.1.tar.gz | tar -zxf - -C /
	(cd /tmp/global-*; \
	./configure --prefix=$HOME/.local --with-exuberant-ctags=`command -v ectags` && \
	make && $sudo make install) && \
	rm -rf /tmp/global-*
}

install_global() {
	case $os in
		Darwin)
			install_package global --with-exuberant-ctags --with-pygments
			;;
		Linux)
			case $distribution in
				CentOS)
					install_package global-ctags
					;;
				*)
					install_package global
					;;
			esac
			;;
		OpenBSD)
			install_from_source_global
			;;
		*)
			install_package global
			;;
	esac
}

install_xde_prerequisites() {
	case $os in
		Linux)
			case $distribution in
				CentOS)
					install_package --enablerepo=epel fuse-sshfs && \
					{ grep fuse /etc/group > /dev/null || $sudo groupadd fuse; } && \
					$sudo usermod -a -G fuse `whoami` && \
					install gtk2 xdg-utils zenity
					;;
				Debian|Devuan|Ubuntu)
					install fuse && \
					$sudo modprobe fuse && \
					{ grep fuse /etc/group > /dev/null || $sudo groupadd fuse; } && \
					$sudo usermod -a -G fuse `whoami` && \
					install libgtk2.0 libnspr4 desktop-file-utils xdg-utils zenity
					;;
			esac
			;;
		OpenBSD)
			echo "Error: $0: watchman does not support $os.  This error is not fatal." 1>&2
			return 1
			test -d `echo /tmp/watchman-* | cut -f1 -d' '` || download https://github.com/facebook/watchman/archive/v4.9.0.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/watchman-* && \
			if [ ! -f .dotfiles.patched ]; then
				patch -p1 <<-EOF
					diff -u watchman-4.9.0_orig/log.cpp watchman-4.9.0/log.cpp
					--- watchman-4.9.0_orig/log.cpp	Sun Jan  7 20:08:18 2018
					+++ watchman-4.9.0/log.cpp	Sun Jan  7 20:03:51 2018
					@@ -17,7 +17,9 @@
					 #else
					 static thread_local std::string thread_name_str;
					 #endif
					+#if (defined(HAVE_BACKTRACE) && defined(HAVE_BACKTRACE_SYMBOLS)) || defined(_WIN32)
					 static constexpr size_t kMaxFrames = 64;
					+#endif
					 
					 namespace {
					 template <typename String>
EOF
				test $? -eq 0 && touch .dotfiles.patched
			fi && \
			autogen_watchman && \
			CC=cc CXX=c++ CPPFLAGS='-Dva_list=__va_list' ./configure --without-python --without-pcre && \
			AUTOCONF_VERSION=2.69 AUTOMAKE_VERSION=1.15 gmake && $sudo gmake install) && \
			rm -rf /tmp/watchman-*
	esac
}

install_xde() {
	install_xde_prerequisites && \
	case $os in
		Linux)
			if [ ! -f `echo /tmp/xde-*.AppImage | cut -f1 -d' '` ]; then
				{ has wget || install wget; } && \
				(cd /tmp; wget https://github.com/expo/xde/releases/download/v2.22.1/xde-2.22.1-x86_64.AppImage)
			fi && \
			mv /tmp/xde-*.AppImage $HOME/.local/bin/ && chmod +x $HOME/.local/bin/xde-*.AppImage
			;;
		*)
			echo "Error: $0: XDE does not support $os.  This error is not fatal." 1>&2
			;;
	esac
}

install_tools_react_native() {
	acquire_root_privilege=""
	test $prefer_binary_package -eq 1 && acquire_root_privilege=$sudo
	test $prefer_binary_package -eq 0 && { has nodebrew || install_nodebrew; }
	has node || install_node
	has create-react-native-app || $acquire_root_privilege npm install -g create-react-native-app
	has exp || install_exp
	has watchman || install_watchman
	has tern || $acquire_root_privilege npm install -g tern
	has_exctags || install_exctags
	has global || install_global
	if [ $with_x11 -eq 1 ]; then
		test -f `echo $HOME/.local/bin/xde-*-x86_64.AppImage | cut -f1 -d' '` || install_xde
	fi
}