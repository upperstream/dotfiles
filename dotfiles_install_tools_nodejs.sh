# Script to setp up Node.js environment
# Copyright (C) 2020 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

# shellcheck shell=sh

# $(...) notation to invoke a subshell is not universal
# shellcheck disable=SC2006

nodejs_describe_module() {
	cat <<-EOF
	nodejs:
	    install Node.js development tools
EOF
}

install_nodebrew() {
	if [ "$os" = "Linux" -a "$distribution" = "Amazon" ]; then
		require which
	fi
	case "$os" in
		FreeBSD|Linux|Darwin|NetBSD|OpenBSD)
			{ has wget || install wget; } && \
			wget -O - --no-check-certificate https://git.io/nodebrew | perl - setup
			;;
	esac
	rc=$?
	PATH=$HOME/.nodebrew/current/bin:$PATH
	return $rc
}

get_nodejs_lts_versions() {
	download https://nodejs.org/dist/index.tab | \
	awk 'BEGIN { FS = "\t" } (NR > 1 && $10 != "-") { print $1, $10 }' | \
	sed 's/^v\([0-9][0-9]*\)\.\([0-9][0-9]*\).\([0-9][0-9]*\) \(.*\)/\1 \2 \3 \4/' | \
	sort -nr -k1 -k2 -k3 | \
	awk '{ if ($1 != prev_major) { prev_major = $1; printf("v%d.%d.%d\t%s\n", $1, $2, $3, $4); } }'
}

install_node_dependencies() {
	case "$os" in
		FreeBSD)
			install_package python27 && \
			$sudo ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
			;;
		NetBSD)
			install_package python27 && \
			$sudo ln -sf /usr/pkg/bin/python2.7 /usr/pkg/bin/python
			;;
		OpenBSD)
			install_package python%3 && \
			$sudo ln -sf `ls /usr/local/bin/python3* | sort -r | head -n1` /usr/local/bin/python
			;;
	esac
}

install_node() {
	node_version="$1"
	install_node_dependencies && \
	case "$os" in
		Darwin)
			nodebrew install-binary "$node_version" && \
			nodebrew use "$node_version"
			;;
		FreeBSD)
			install_package gmake libexecinfo && \
			if [ "$prefer_binary_package" -eq 1 ]; then
				install gmake && \
				install node6 && \
				if [ ! -f /usr/ports/Makefile ]; then
					$sudo tar -zxpf "`download_distfile ports.txz http://ftp.jaist.ac.jp/pub/FreeBSD/releases/amd64/amd64/11.1-RELEASE/ports.txz`" -C /
				fi && \
				(install_package gmake && \
				cd /usr/ports/www/npm3 && \
				$sudo make -DBATCH install clean)
				acquire_root_privilege="$sudo"
			else
				install gmake libexecinfo && \
				CC=cc CXX=c++ nodebrew install "$node_version" && \
				nodebrew use "$node_version"
			fi
			;;
		Linux)
			nodebrew install-binary "$node_version" && \
			nodebrew use "$node_version"
			;;
		NetBSD)
			if [ "$prefer_binary_package" -ne 1 ]; then
				echo "$0: Using Node.js binary package is preferred for NetBSD" 1>&2
				acquire_root_privilege="$sudo"
			fi
			if [ "$prefer_binary_package" -eq 1 -o true ]; then
				install_package nodejs-8.4.0nb1 && \
				$acquire_root_privilege npm install -g npm@4
			else
				if ! has cc; then
					compiler_url=`sed -n 's:^PKG_PATH=\(.*\)/pkgsrc/.*$:\1:p' /etc/pkg_install.conf`/NetBSD/NetBSD-`uname -r`/`uname -m`/binary/sets/comp.tgz
					$sudo tar -zxpf "`download_distfile comp.tgz "$compiler_url"`" -C / && \
					unset compiler_url
				fi
				install gmake libexecinfo && \
				CC=cc CXX=c++ nodebrew install "$node_version" && \
				nodebrew use "$node_version"
			fi
			;;
		OpenBSD)
			if [ "$prefer_binary_package" -ne 1 ]; then
				echo "$0: Using Node.js binary package is preferred for OpenBSD" 1>&2
				acquire_root_privilege="$sudo"
			fi
			if [ "$prefer_binary_package" -eq 1 -o true ]; then
				install_package node
			else
				{ has gmake || install_package gmake; } && \
				install_package libexecinfo && \
				CC=cc CXX=c++ nodebrew install "$node_version"
			fi
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

install_exctags() {
	case "$os" in
		Darwin)
			install_package ctags && \
			brew link --overwrite ctags
			;;
		Linux)
			case "$distribution" in
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
	case "$os" in
		Darwin)
			ctags --version | grep -F 'Exuberant Ctags' > /dev/null 2>&1
			;;
		FreeBSD|NetBSD)
			has exctags
			;;
		Linux)
			case "$distribution" in
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
	if ! has gcc; then
		filename=comp`uname -r | sed 's/^\([0-9]*\)\.\([0-9]*\)$/\1\2/'`.tgz
		compiler_url=`cat /etc/installurl`/`uname -r`/`uname -m`/$filename
		$sudo tar -zxpf "`download_distfile "$filename" "$compiler_url"`" -C / && \
		unset filename && \
		unset compiler_url
	fi && \
	if [ ! -d /tmp/global-6.6.1 ]; then
		tar -zxf "`download_distfile global-6.6.1.tar.gz http://tamacom.com/global/global-6.6.1.tar.gz`" -C /tmp
	fi && \
	require stow && \
	{ test -d "$HOME"/.local/stow || mkdir -p "$HOME"/.local/stow; } && \
	(cd /tmp/global-*; \
	./configure --prefix="$HOME"/.local --with-exuberant-ctags="`command -v ectags`" && \
	make && $sudo make install) && \
	rm -rf /tmp/global-*
}

install_global() {
	case "$os" in
		Darwin)
			install_package global --with-exuberant-ctags --with-pygments
			;;
		Linux)
			case "$distribution" in
				Amazon)
					install_from_source_global
					;;
				Arch)
					echo "$0: Warning: Installing GNU GLOBAL on Arch Linux is not supported." 1>&2
					return 0
					;;
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


install_tools_nodejs() {
	cat <<-EOF
	-----------------------------------------
	Installing tools for Node.js
	-----------------------------------------
EOF

	acquire_root_privilege=""
	if [ "$os" != "OpenBSD" ]; then
		has nodebrew || install_nodebrew || report_error
	fi
	has node || install_node "`get_nodejs_lts_versions | head -n1 | cut -f1`" || report_error
	has tern || $acquire_root_privilege npm install -g tern || report_error
	has_exctags || install_exctags || report_error
	has global || install_global || report_error
}
