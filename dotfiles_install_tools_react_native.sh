# Script to setp up React Native environment
# Copyright (C) 2018, 2020 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

# $(...) notation to invoke a subshell is not universal
# shellcheck disable=SC2006

react_native_describe_module() {
	cat <<-EOF
	react_native:
	    install React Native development tools
EOF
}

install_exp() {
	case "$os" in
		OpenBSD)
			echo "$0: Warning: Installing exp on OpenBSD is not supported." 1>&2
			;;
		*)
			$acquire_root_privilege npm install -g exp
			;;
	esac
}

install_watchman_prerequisites() {
	case "$os" in
		Linux)
			case "$distribution" in
				Arch)
					install m4 autoconf automake pkg-config clang
					;;
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
			install_package autoconf-2.69p2 automake-1.15.1 m4 gmake bash libtool
			;;
	esac
}

autogen_watchman() {
	case "$os" in
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
	case "$os" in
		Darwin|FreeBSD|NetBSD)
			install watchman
			;;
		Linux)
			if [ ! -d /tmp/watchman-4.9.0 ]; then
				tar -zxf `download_distfile watchman-4.9.0.tar.gz https://github.com/facebook/watchman/archive/v4.9.0.tar.gz` -C /tmp
			fi && \
			(cd /tmp/watchman-* && \
			autogen_watchman && \
			./configure --without-python --without-pcre && \
			make && $sudo make install) && \
			rm -rf /tmp/watchman-*
			;;
		OpenBSD)
			echo "$0: Warning: Installing Watchman on OpenBSD is not supported." 1>&2; return 0
			if [ ! -d /tmp/watchman-4.9.0 ]; then
				tar -zxf `download_distfile watchman-4.9.0.tar.gz https://github.com/facebook/watchman/archive/v4.9.0.tar.gz` -C /tmp
			fi && \
			(cd /tmp/watchman-* && \
			autogen_watchman && \
			CC=cc CXX=c++ ./configure --without-python --without-pcre && \
			gmake && $sudo gmake install) && \
			rm -rf /tmp/watchman-*
			;;
	esac
}

install_xde_prerequisites() {
	case "$os" in
		Linux)
			case "$distribution" in
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
			echo "$0: Warning: watchman does not support $os." 1>&2
			return 0
			if [ ! -d /tmp/watchman-4.9.0 ]; then
				tar -zxvf `download_distfile watchman-4.9.0.tar.gz https://github.com/facebook/watchman/archive/v4.9.0.tar.gz` -C /tmp
			fi && \
			(cd /tmp/watchman-4.9.0 && \
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
	case "$os" in
		Darwin)
			install_package -c expo-xde
			;;
		Linux)
			if [ ! -f `echo /tmp/xde-*.AppImage | cut -f1 -d' '` ]; then
				download https://github.com/expo/xde/releases/download/v2.22.1/xde-2.22.1-x86_64.AppImage > $HOME/.local/bin/xde-2.22.1-x86_64.AppImage && \
				chmod +x $HOME/.local/bin/xde-*.AppImage
			fi
			;;
		*)
			echo "$0: Warning: XDE does not support $os." 1>&2
			;;
	esac
}

install_tools_react_native() {
	if ! has node; then
		. $dotfiles_dir/dotfiles_install_tools_nodejs.sh && install_tools_nodejs || report_error
	fi
	cat <<-EOF
	-----------------------------------------
	Installing tools for React Native
	-----------------------------------------
EOF

	acquire_root_privilege=""
	has create-react-native-app || \
		$acquire_root_privilege npm install -g create-react-native-app || report_error
	has react-native || $acquire_root_privilege npm install -g react-native-cli || report_error
	has exp || install_exp || report_error
	has watchman || install_watchman || report_error
	if [ $with_x11 -eq 1 ]; then
		test -f `echo $HOME/.local/bin/xde-*-x86_64.AppImage | cut -f1 -d' '` || \
			install_xde || report_error
	fi
}
