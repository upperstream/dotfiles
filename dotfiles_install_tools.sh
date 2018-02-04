#!/bin/sh
# Install basic tools.
# Copyright (C) 2017, 2018 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

set -e
#set -x

dotfiles_dir=`dirname $0`

usage() {
	cat <<-EOF
	Usage:
	$0 [-bkx] [-s set]
	$0 -H|--help

	-b : prefer installing binary package over compiling source code
	-k : keep going even if some software can't be installed
	-s set
	   : install specified set of tools; see below list for available sets
	-x : install additional tools for X Window System; this may install
	     X Window System as a part of dependencies
	-H|--help
	   : print this help summary and exit

	Available sets are:

EOF

	for s in dotfiles_install_tools_*.sh; do
		. ./$s && `echo $s | sed s/dotfiles_install_tools_\\\\\([^.]*\\\\\).sh/\\\\1/`_describe_module
	done
}

test "$1" = "--help" && { usage; exit 255; }

prefer_binary_package=0
with_x11=0

sets=""
keep_going=0

while getopts bks:xH opt; do
	case $opt in
		b) prefer_binary_package=1;;
		k) keep_going=1;;
		s) sets=`printf "$sets\n$OPTARG"`;;
		x) with_x11=1;;
		H) usage; exit 255;;
	esac
done

error=0
report_error() {
	if [ $keep_going -eq 1 ]; then
		test $error -lt 254 && error=`expr $error + 1`
		return 0
	else
		echo "$0: Error: installation failed" 1>&2
		exit 1
	fi
}

determine_operating_system() {
	echo `uname`
}

linux_determine_distribution() {
	name=`cat /etc/*release | grep -F "NAME="`
	case $name in
		*Alpine*) echo "Alpine";;
		*CentOS*) echo "CentOS";;
		*Debian*) echo "Debian";;
		*Devuan*) echo "Devuan";;
		*Ubuntu*) echo "Ubuntu";;
		*)        echo "$0: Warning: Unknown distribution: $name" 1>&2; return 1;;
	esac
	return 0
}

linux_determine_package_manager() {
	for name in apk apt-get yum; do
		has $name && { echo $name; return 0; }
	done
	return 1
}

determine_sudo_command() {
	for name in sudo doas; do
		has $name && { echo $name; return 0; }
	done
	return 1
}

locate_pip() {
	for name in pip pip2.7; do
		path=`command -v $name 2>/dev/null` && { echo $path; return 0; }
	done
	return 1
}

determine_downloader() {
	test "$os" != "Linux" -a "$os" != "Darwin" && for name in fetch ftp; do
		has $name && { echo $name; return 0; }
	done
	for name in curl wget; do
		has $name && { echo $name; return 0; }
	done
	install curl && { echo "curl"; return 0; }
	install wget && { echo "wget"; return 0; }
}

inspect_current_environment() {
	cat <<-EOF
	-----------------------------------------
	Inspecting current environment
	-----------------------------------------
EOF
	os=`determine_operating_system`
	if [ "$os" = "Linux" ]; then
		distribution=`linux_determine_distribution`
		pkgmgr=`linux_determine_package_manager`
	fi
	sudo=`determine_sudo_command`
	downloader=`determine_downloader`
	pip=`locate_pip` || true

	echo "os=$os"
	echo "distribution=$distribution"
	echo "sudo=$sudo"
	echo "downloader=$downloader"
	echo "pkgmgr=$pkgmgr"
	echo "pip=$pip"
}

alpine_enable_community_repo() {
	if grep "^#.*/v[0-9]*\.[0-9]*/community$" /etc/apk/repositories > /dev/null; then
		$sudo sh -c "(rm /etc/apk/repositories; sed 's=^#\\(.*/v[0-9]*\.[0-9]*/community\\)\$=\\1=' > /etc/apk/repositories) < /etc/apk/repositories" && \
		$sudo apk update
	fi
}

alpine_enable_edge_repos() {
	if grep "^#.*/edge/.*$" /etc/apk/repositories > /dev/null; then
		$sudo sh -c "(rm /etc/apk/repositories; sed 's=^#\\(.*/edge/.*\\)\$=\\1=' > /etc/apk/repositories) < /etc/apk/repositories" && \
		$sudo apk update
	fi
}

linux_install_package() {
	case $pkgmgr in
		apk)
			$sudo apk add $@
			;;
		apt-get)
			$sudo apt-get install -y $@
			;;
		yum)
			$sudo yum install -y $@
			;;
	esac
}

install_package() {
	cask=""
	test "$1" = "-c" && { cask="cask"; shift; }
	case "$os" in
		Darwin)
			brew $cask install $@
			;;
		FreeBSD)
			$sudo pkg install -y $@
			;;
		Linux)
			linux_install_package $@
			;;
		NetBSD)
			$sudo pkg_add $@
			;;
		OpenBSD)
			$sudo pkg_add $@
			;;
		*)
			echo "$0: Error: Unsupported platform: $os" 1>&2
			return 1
			;;
	esac
}

download() {
	case $downloader in
		fetch)
			fetch -o- $1
			;;
		ftp)
			ftp -o- $1
			;;
		curl)
			curl -L $1
			;;
		wget)
			wget -O- $1
			;;
	esac
}

install_abduco() {
	case "$os" in
		Darwin|FreeBSD)
			install_package abduco
			;;
		Linux)
			case "$distribution" in
				Alpine)
					alpine_enable_edge_repos && linux_install_package abduco
					;;
				Debian|Devuan)
					linux_install_package dtach
					;;
				*)
					linux_install_package abduco
					;;
			esac
			;;
		NetBSD|OpenBSD)
			install_package dtach
			;;
		*)
			download http://www.brain-dump.org/projects/abduco/abduco-0.6.tar.gz | tar -zxf - -C /tmp && \
			(cd /tmp/abduco-*; make && $sudo make install) && \
			rm -rf /tmp/abduco-*
			;;
	esac
}

install_cdiff() {
	case "$os" in
		FreeBSD)
			install_package cdiff
			;;
		*)
			{ has pip || install pip; } && \
			$pip install --user cdiff
			;;
	esac
}

install_dirstack() {
	if [ "$os" = "Linux" ]; then
		case "$distribution" in
			Alpine)
				alpine_enable_edge_repos && \
				{ has mandb || install_package man-db; } && \
				{ has make || install_package make; }
				;;
			Ubuntu)
				has mandb || install_package man-db
				;;
		esac
	fi && \
	download https://bitbucket.org/upperstream/dirstack/get/20171213.tar.gz | tar -zxf - -C /tmp || return 1
	(cd /tmp/upperstream-dirstack-* && \
	printf "s/^M/# M/\n/# .*$os/ {N; s/\\\n# /\\\\\n/; }\ns:^PREFIX = /usr/local:PREFIX = \${HOME}/.local:" > config.sed && \
	(rm config.mk && sed -f config.sed > config.mk) < config.mk && \
	make install) && \
	rm -rf /tmp/upperstream-dirstack-*
}

install_from_source_dvtm() {
	download http://www.brain-dump.org/projects/dvtm/dvtm-0.15.tar.gz | tar -zxf - -C /tmp
	(cd /tmp/dvtm-*; make && $sudo make install) && \
	rm -rf /tmp/dvtm-*
}

install_dvtm() {
	case "$os" in
		Darwin)
			brew install ncurses
			brew link --force ncurses
			download http://www.brain-dump.org/projects/dvtm/dvtm-0.15.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/dvtm-*; \
			(rm config.mk; sed '/^CPPFLAGS =/ s/-D_POSIX_C_SOURCE=[^ ]*//; s/-D_XOPEN_SOURCE[^ ]*//g' > config.mk) < config.mk && \
			make && $sudo make install) && \
			rm -rf /tmp/dvtm-*
			;;
		FreeBSD|NetBSD|OpenBSD)
			install_package dvtm
			;;
		Linux)
			case "$distribution" in
				Alpine)
					alpine_enable_community_repo && \
					linux_install_package dvtm
					;;
				CentOS)
					linux_install_package ncurses-devel
					has gcc || linux_install_package gcc
					install_from_source_dvtm
					;;
				Debian|Devuan|Ubuntu)
					linux_install_package dvtm
					;;
				*)
					echo "$0: Error: Unsupported platform: $distribution" 1>&2
					return 1
					;;
			esac
			;;
		*)
			echo "$0: Error: Unsupported platform: $os" 1>&2
			return 1
			;;
	esac
}

install_from_source_editorconfig() {
	download https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz | tar -zxf - -C /tmp
	(cd /tmp/editorconfig-core-c-0.12.1 && cmake . && make && $sudo make install) && rm -rf /tmp/editorconfig-core-c-0.12.1
}

install_editorconfig() {
	case "$os" in
		Darwin)
			brew install editorconfig
			;;
		FreeBSD)
			install_package editorconfig-core-c
			;;
		Linux)
			case "$distribution" in
				Alpine)
					alpine_enable_community_repo && \
					linux_install_package editorconfig
					;;
				CentOS)
					for t in cmake pcre-devel; do
						linux_install_package $t
					done
					has gcc || install gcc
					install_from_source_editorconfig
					;;
				Debian|Devuan|Ubuntu)
					linux_install_package editorconfig
					;;
				*)
					echo "$0: Error: Unsupported platform: $distribution" 1>&2
					return 1
					;;
			esac
			;;
		NetBSD)
			install_package editorconfig-core
			;;
		OpenBSD)
			for t in cmake pcre; do
				has $t || install_package $t
			done
			has gcc || download `cat /etc/installurl`/`uname -r`/`uname -m`/comp`uname -r | tr -d '.'`.tgz | $sudo tar -zxpf - -C /
			install_from_source_editorconfig
			;;
		*)
			echo "$0: Error: Unsupported platform: $os" 1>&2
			return 1
			;;
	esac
}

install_emacs() {
	case "$os" in
		Darwin)
			brew uninstall emacs
			install_package -c emacs
			;;
		FreeBSD)
			install_package emacs25
			;;
		Linux)
			case "$distribution" in
				Alpine) alpine_enable_community_repo && linux_install_package emacs-nox;;
				CentOS) linux_install_package emacs;;
				Debian) linux_install_package emacs25;;
				Devuan) linux_install_package emacs;;
				Ubuntu) linux_install_package emacs24;;
			esac
			;;
		NetBSD)
			$sudo pkg_delete emacs-nox11 || true
			install_package emacs
			;;
		OpenBSD)
			$sudo pkg_delete emacs-25.3-no_x11 || true
			install_package emacs-25.3-gtk2
			;;
		*)
			install_package -c emacs
			;;
	esac
}

install_emacs_nox11() {
	case "$os" in
		Darwin)
			brew cask uninstall emacs
			install_package emacs
			;;
		FreeBSD)
			install_package emacs-nox11
			;;
		Linux)
			case "$distribution" in
				Alpine) alpine_enable_community_repo && linux_install_package emacs-nox;;
				CentOS) linux_install_package emacs-nox;;
				Debian) linux_install_package emacs25-nox;;
				Devuan) linux_install_package emacs-nox;;
				Ubuntu) linux_install_package emacs24-nox;;
			esac
			;;
		NetBSD)
			$sudo pkg_delete emacs || true
			install_package emacs-nox11
			;;
		OpenBSD)
			$sudo pkg_delete emacs-25.3-gtk2 || true
			install_package emacs-25.3-no_x11
			;;
		*)
			install_package emacs-nox11
			;;
	esac
}

install_markdown() {
	case "$os" in
		FreeBSD|NetBSD|OpenBSD)
			install_package p5-Text-Markdown
			;;
		Linux)
			case "$distribution" in
				Alpine) alpine_enable_community_repo && install_package markdown;;
				CentOS) linux_install_package perl-Text-Markdown;;
				*)      linux_install_package markdown;;
			esac
			;;
		*)
			install_package markdown
			;;
	esac
}

install_stow() {
	if [ "$os" = "Linux" -a "$distribution" = "Alpine" ]; then
		alpine_enable_community_repo
	fi && \
	install_package stow
}

__install_micro() {
	if [ "$os" = "Linux" -a "$distribution" = "Alpine" ]; then
		alpine_enable_edge_repos && \
		linux_install_package micro
	else
		case $1 in
			linux64|netbsd64)
				{ has stow || install_stow; } && \
				{ test -d $HOME/.local/stow || mkdir -p $HOME/.local/stow; } && \
				download https://github.com/zyedidia/micro/releases/download/v1.3.4/micro-1.3.4-$1.tar.gz | tar -zxf - -C $HOME/.local/stow && \
				{ mkdir -p $HOME/.local/stow/micro-1.3.4/bin && mv $HOME/.local/stow/micro-1.3.4/micro $HOME/.local/stow/micro-1.3.4/bin/; } && \
				(cd $HOME/.local/stow && stow micro-1.3.4)
				;;
			*)
				echo "$0: Error: Unsupported platform: `uname`" 1>&2
				return 1
				;;
		esac
	fi
}

install_micro() {
	case "$os" in
		Linux)
			__install_micro linux64
			;;
		NetBSD)
			__install_micro netbsd64
			;;
		*)
			install_package micro
			;;
	esac
}

install_pip() {
	case "$os" in
		Linux)
			case "$distribution" in
				Alpine)
					linux_install_package py2-pip
					;;
				CentOS)
					linux_install_package python2-pip
					;;
				Debian|Devuan|Ubuntu)
					install_package python-pip
					;;
			esac
			;;
		NetBSD)
			install_package py27-pip
			;;
		OpenBSD)
			install_package py-pip
			;;
		*)
			{ has python || install python; } && \
			{ download https://bootstrap.pypa.io/get-pip.py | python - --user; } && \
			PATH=$PATH:`python -m site --user-base`/bin
			;;
	esac
	rc=$?
	pip=`locate_pip`
	return $?
}

install_xsel() {
	case "$os" in
		Darwin)
			brew install xclip
			;;
		FreeBSD|NetBSD)
			install_package xsel
			;;
		Linux)
			case "$distribution" in
				Alpine) install_package xclip;;
				*)      install_package xsel;;
			esac
			;;
		OpenBSD)
			if [ ! -f /usr/X11R6/lib/libX11.a ]; then
				download `cat /etc/installurl`/`uname -r`/`uname -m`/xbase`uname -r | tr -d '.'`.tgz | $sudo tar -zxpf - -C /
			fi
			install_package xsel
			;;
		*)
			echo "$0: Error: Unsupported platform: $os" 1>&2
			return 1
			;;
	esac
}

install() {
	for t in $@; do
		case $t in
			abduco)       install_abduco;;
			cdiff)        install_cdiff;;
			dirstack)     install_dirstack;;
			dvtm)         install_dvtm;;
			editorconfig) install_editorconfig;;
			emacs)        install_emacs;;
			emacs-nox11)  install_emacs_nox11;;
			java-source)  install_java_source;;
			jdk)          install_jdk;;
			Markdown)     install_markdown;;
			micro)        install_micro;;
			pip)          install_pip;;
			sbt)          install_sbt;;
			xsel)         install_xsel;;
			*)            install_package $t;;
		esac
		rc=$?
		test $rc -ne 0 && return $rc
	done
	return 0
}

has() {
	command -v $1 >/dev/null
}

install_terminal_tools() {
	cat <<-EOF
	-----------------------------------------
	Installing tools running in terminal
	-----------------------------------------
EOF

	# Micro editor
	has micro || install micro || report_error

	# EditorConfig Core C
	has editorconfig || install editorconfig || report_error

	# nano
	has nano || install nano || report_error

	# Markdown
	{ has Markdown || has markdown || has Markdown.pl; } || install Markdown || report_error

	# lynx
	has lynx || install lynx || report_error

	# dirstack
	has dirstack.sh || install dirstack || report_error

	# cdiff
	has cdiff || install cdiff || report_error

	# adbuco or dtach
	{ has abduco || has dtach; } || install abduco || report_error

	# dvtm
	has dvtm || install dvtm || report_error

	# mg
	has mg || install mg || report_error

	# Emacs
	if [ $with_x11 -eq 0 ]; then
		install emacs-nox11 || report_error
	fi
}

install_sets() {
	for s in `echo $sets`; do
		if [ -f $dotfiles_dir/dotfiles_install_tools_$s.sh ]; then
			{ . $dotfiles_dir/dotfiles_install_tools_$s.sh && install_tools_$s; } || report_error
		else
			echo "Error: $0: $dotfiles_dir/dotfiles_install_tools_$s.sh not found" 1>&2
			report_error
		fi
	done
}

install_x11_tools() {
	cat <<-EOF
	-----------------------------------------
	Installing tools running on window system
	-----------------------------------------
EOF

	# XSel or xclip
	{ has xsel || has xclip; } || install xsel || report_error

	# Emacs
	install emacs || report_error
}

main() {
	if [ $prefer_binary_package -eq 1 ]; then
		printf "Install binary package rather than compiling source code\n"
	fi
	printf "Additional sets to install: $sets\n"

	test -d $HOME/.local/bin || mkdir -p $HOME/.local/bin

	inspect_current_environment
	install_terminal_tools
	install_sets
	{ test $with_x11 -eq 1 && install_x11_tools; } || true
}

main

if [ $error -eq 0 ]; then
	echo "$0: installation succeeded"
elif [ $error -eq 1 ]; then
	echo "$0: an error reported during installation" 1>&2
elif [ $error -gt 1 ]; then
	echo "$0: $error errors reported during installation" 1>&2
fi
exit $error
