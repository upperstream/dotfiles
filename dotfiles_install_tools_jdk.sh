# Script to set up JDK environment
# Copyright (C) 2018 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

jdk_describe_module() {
	cat <<-EOF
	jdk:
	    install JDK tools
EOF
}

install_auto_java_complete() {
	if [ ! -d $HOME/.emacs.d/auto-java-complete-0.2.9 ]; then
		tar -zxf `download_distfile auto-java-complete-0.2.9.tar.gz https://github.com/emacs-java/auto-java-complete/archive/0.2.9.tar.gz` -C $HOME/.emacs.d/
	fi && \
	(cd $HOME/.emacs.d && ln -sf auto-java-complete-0.2.9 auto-java-complete)
}

install_jdk() {
	case "$os" in
		Darwin)
			install_package -c java
			;;
		FreeBSD)
			install_package openjdk8
			;;
		Linux)
			case "$distribution" in
				Alpine)
					alpine_enable_community_repo && \
					linux_install_package openjdk8 && \
					(cd /usr/bin && $sudo ln -sf /usr/lib/jvm/default-jvm/bin/* .)
					;;
				Arch)
					linux_install_package jdk8-openjdk
					;;
				CentOS)
					linux_install_package java-1.8.0-openjdk-devel
					;;
				Debian|Ubuntu)
					linux_install_package openjdk-8-jdk-headless
					;;
				Devuan)
					linux_install_package openjdk-7-jdk
					;;
			esac
			;;
		NetBSD)
			install_package openjdk8 && \
			(cd ~/.local/bin; ln -sf /usr/pkg/java/openjdk8/bin/* .)
			;;
		OpenBSD)
			if [ ! -f /usr/X11R6/lib/libX11.a ]; then
				filename=xbase`uname -r | tr -d '.'`.tgz
				download_distfile $filename `cat /etc/installurl`/`uname -r`/`uname -m`/$filename && \
				$sudo tar -zxpf $distfiles_dir/$filename -C /
				unset filename
			fi
			install_package jdk && \
			(cd ~/.local/bin; ln -sf /usr/local/jdk-1.8.0/bin/* .)
			;;
	esac
}

install_java_source() {
	case "$os" in
		Linux)
			case "$distribution" in
				Arch)          linux_install_package openjdk8-src;;
				CentOS)        linux_install_package java-1.8.0-openjdk-src;;
				Debian|Ubuntu) linux_install_package openjdk-8-source;;
				Devuan)        linux_install_package openjdk-7-source;;
			esac
			;;
	esac
}

install_tools_jdk() {
	cat <<-EOF
	-----------------------------------------
	Installing tools for JDK
	-----------------------------------------
EOF

	{ test "$os" != "Darwin" && has javac; } || install_jdk || report_error
	install_java_source || report_error
	install_auto_java_complete || report_error
}
