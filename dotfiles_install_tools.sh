#!/bin/sh
# Install basic tools.
# Copyright (C) 2017-2021 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

set -e
#set -x

dotfiles_dir=`dirname $0`
modules_dir=$dotfiles_dir/modules

local_dir=$HOME/.local
dotfiles_home=$HOME/.dotfiles.d
distfiles_dir=$dotfiles_home/distfiles
lisp_dir=$HOME/.emacs.d/lisp

usage() {
	cat <<-EOF
	Usage:
	$0 [-bkx] [-s set]
	$0 -H|-h|--help

	-b : prefer installing binary package over compiling source code
	-k : keep going even if some software can't be installed
	-s set
	   : install specified set of tools; see below list for available sets
	-x : install additional tools for X Window System; this may install
	     X Window System as a part of dependencies
	-H|-h|--help
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

while getopts bhks:xH opt; do
	case $opt in
		b)   prefer_binary_package=1;;
		k)   keep_going=1;;
		s)   sets=`printf "$sets\n$OPTARG"`;;
		x)   with_x11=1;;
		h|H) usage; exit 255;;
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
		*Amazon*) echo "Amazon";;
		*Arch*)   echo "Arch";;
		*CentOS*) echo "CentOS";;
		*Debian*) echo "Debian";;
		*Devuan*) echo "Devuan";;
		*Ubuntu*) echo "Ubuntu";;
		*)        echo "$0: Warning: Unknown distribution: $name" 1>&2; return 1;;
	esac
	return 0
}

linux_determine_distro_version() {
	cat /etc/os-release | grep VERSION_ID | cut -f2 -d'"'
}

linux_determine_package_manager() {
	for name in apk apt-get pacman yum; do
		has $name && { echo $name; return 0; }
	done
	return 1
}

netbsd_determine_package_manager() {
	if has pkgin; then
		echo "pkgin -y install"
	else
		echo pkg_add
	fi
}

netbsd_determine_pkg_delete() {
	if has pkgin; then
		echo "pkgin -y remove"
	else
		echo pkg_delete
	fi
}

determine_sudo_command() {
	for name in sudo doas; do
		has $name && { echo $name; return 0; }
	done
	return 1
}

locate_pip() {
	for name in pip pip3.8 pip2.7; do
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
	install curl && { echo "curl -L"; return 0; }
	install wget && { echo "wget"; return 0; }
}

download_distfile() {
	distfile=$distfiles_dir/$1
	test -f $distfile || download $2 > $distfile
	rc=$?
	test $rc -eq 0 || return $rc
	echo $distfile
	unset distfile
	return $rc
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
		distro_version=`linux_determine_distro_version`
		pkgmgr=`linux_determine_package_manager`
	elif [ "$os" = "NetBSD" ]; then
		pkgmgr=`netbsd_determine_package_manager`
		netbsd_pkg_delete=`netbsd_determine_pkg_delete`
	fi
	sudo=`determine_sudo_command`
	downloader=`determine_downloader`
	pip=`locate_pip` || true

	echo "dotfiles_home=$dotfiles_home"
	echo "dotfiles_dir=$dotfiles_dir"
	echo "lisp_dir=$lisp_dir"
	echo "os=$os"
	echo "distribution=$distribution"
	echo "distro_version=$distro_version"
	echo "sudo=$sudo"
	echo "downloader=$downloader"
	echo "pkgmgr=$pkgmgr"
	if [ "$os" = "NetBSD" ]; then
		echo "netbsd_pkg_delete=$netbsd_pkg_delete"
	fi
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
		pacman)
			$sudo pacman -Syu --noconfirm $@
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
			$sudo $pkgmgr $@
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

require() {
	package=${2:-$1}
	command -v "$1" 2>/dev/null || install_package "$package"
	rc=$?
	unset package
	return $rc
}

install_from_source_abduco() {
	if [ ! -d /tmp/abduco-0.6 ]; then
		require tar && \
		tar -zxf `download_distfile abduco-0.6.tar.gz http://www.brain-dump.org/projects/abduco/abduco-0.6.tar.gz` -C /tmp
	fi && \
	(cd /tmp/abduco-0.6 && make && $sudo make install) && \
	rm -rf /tmp/abduco-*
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
				Amazon)
					install_from_source_abduco
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
			install_from_source_abduco
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
		{ has make || install_package make; } && \
		case "$distribution" in
			Alpine)
				alpine_enable_edge_repos && \
				{ has mandb || install_package man-db; }
				;;
			Ubuntu)
				has mandb || install_package man-db
				;;
		esac
	fi && \
	if [ ! -d `echo /tmp/upperstream-dirstack-* | cut -f1` ]; then
		require tar && \
		tar -zxf `download_distfile upperstream-dirstack-20171213.tar.gz https://bitbucket.org/upperstream/dirstack/get/20171213.tar.gz` -C /tmp
	fi && \
	(cd `echo /tmp/upperstream-dirstack-* | cut -f1` && \
	printf "s/^M/# M/\n/# .*$os/ {N; s/\\\n# /\\\\\n/; }\ns:^PREFIX = /usr/local:PREFIX = \${HOME}/.local:" > config.sed && \
	(rm config.mk && sed -f config.sed > config.mk) < config.mk && \
	make install) && \
	rm -rf /tmp/upperstream-dirstack-*
}

install_from_source_dvtm() {
	if [ ! -d /tmp/dvtm-0.15 ]; then
		require tar && \
		tar -zxf `download_distfile dvtm-0.15.tar.gz http://www.brain-dump.org/projects/dvtm/dvtm-0.15.tar.gz` -C /tmp
	fi && \
	(cd /tmp/dvtm-0.15 && make && $sudo make install) && \
	unset filename && \
	rm -rf /tmp/dvtm-*
}

install_dvtm() {
	case "$os" in
		Darwin)
			brew install ncurses && \
			brew link --force ncurses && \
			if [ ! -d /tmp/dvtm-0.15 ]; then
				require tar && \
				tar -zxf `download_distfile dvtm-0.15.tar.gz http://www.brain-dump.org/projects/dvtm/dvtm-0.15.tar.gz` -C /tmp
			fi && \
			(cd /tmp/dvtm-0.15; \
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
				Amazon|CentOS)
					linux_install_package ncurses-devel
					has gcc || linux_install_package gcc
					install_from_source_dvtm
					;;
				*)
					if ! linux_install_package dvtm; then
						echo "$0: Error: Don't know how to install dvtm on $distribution" 1>&2
						return 1
					fi
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
	if [ ! -d /tmp/editorconfig-core-c-0.12.1 ]; then
		require tar && \
		tar -zxf `download_distfile editorconfig-core-c-0.12.1.tar.gz https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz` -C /tmp
	fi && \
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
				Amazon|CentOS)
					for t in cmake pcre-devel; do
						linux_install_package $t
					done
					has gcc || install gcc
					install_from_source_editorconfig
					;;
				Arch)
					linux_install_package editorconfig-core-c
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
			if ! has gcc; then
				filename=comp`uname -r | tr -d '.'`.tgz
				compiler_url=`cat /etc/installurl`/`uname -r`/`uname -m`/$filename
				require tar && \
				$sudo tar -zxpf `download_distfile $filename $compiler_url` -C / && \
				unset filename
				unset compiler_url
			fi && \
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
			install_package emacs || install_package emacs25
			;;
		Linux)
			case "$distribution" in
				Alpine) alpine_enable_community_repo && linux_install_package emacs-nox;;
				Amazon) linux_install_package emacs;;
				Arch)   yes | $sudo pacman -Syu emacs;;
				CentOS) linux_install_package emacs;;
				Debian) linux_install_package emacs25;;
				Devuan) linux_install_package emacs;;
				Ubuntu) linux_install_package emacs24;;
			esac
			;;
		NetBSD)
			$sudo $netbsd_pkg_delete emacs27-nox11 || true
			install_package emacs27
			;;
		OpenBSD)
			$sudo pkg_delete emacs--no_x11 || true
			install_package emacs--gtk2
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
			install_package emacs-nox || install_package emacs-nox11
			;;
		Linux)
			case "$distribution" in
				Alpine) alpine_enable_community_repo && linux_install_package emacs-nox;;
				Amazon) linux_install_package emacs-nox;;
				Arch)   yes | $sudo pacman -Syu emacs-nox;;
				CentOS) linux_install_package emacs-nox;;
				Debian) linux_install_package emacs25-nox;;
				Devuan) linux_install_package emacs-nox;;
				Ubuntu) linux_install_package emacs24-nox;;
			esac
			;;
		NetBSD)
			$sudo $netbsd_pkg_delete emacs27 || true
			install_package emacs27-nox11
			;;
		OpenBSD)
			$sudo pkg_delete emacs--gtk2 || true
			install_package emacs--no_x11
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
				Alpine)
					alpine_enable_community_repo && install_package markdown
					;;
				Amazon)
					require perl
					require unzip
					require perl-Digest-MD5
					if [ ! -d /tmp/Markdown_1.0.1 ]; then
						unzip `download_distfile Markdown_1.0.1.zip https://daringfireball.net/projects/downloads/Markdown_1.0.1.zip` -d /tmp
						(cd /tmp/Markdown_1.0.1 && \
						mv Markdown.pl $HOME/.local/bin && \
						chmod +x $HOME/.local/bin/Markdown.pl && \
						mkdir -p ~/.local/doc/Markdown && \
						mv *.text ~/.local/doc/Markdown/) && \
						rm -rf /tmp/Markdown_1.0.1
					fi
					;;
				CentOS)
					linux_install_package perl-Text-Markdown
					;;
				*)
					linux_install_package markdown
					;;
			esac
			;;
		*)
			install_package markdown
			;;
	esac
}

install_from_source_stow() {
	if [ ! -d "/tmp/stow-2.3.1" ]; then
		case "$os" in
			*BSD)
				_make=gmake
				;;
			*)
				_make=make
				;;
		esac && \
		require tar && \
		require gcc && \
		require $_make && \
		tar -zxf `download_distfile stow-2.3.1.tar.gz http://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz` -C /tmp
		(cd /tmp/stow-2.3.1 && ./configure && $_make && $sudo $_make install) && rm -rf /tmp/stow-2.3.1
		unset _make
	fi
}

install_stow() {
	if [ "$os" = "Linux" -a "$distribution" = "Alpine" ]; then
		alpine_enable_community_repo
	fi && \
	case "$os" in
		NetBSD)
			install_from_source_stow
			;;
		Linux)
			if [ "$distribution" = "Amazon" ]; then
				install_from_source_stow
			else
				install_package stow
			fi
			;;
		*)
			install_package stow
			;;
	esac
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
				if [ ! -d $local_dir/stow/micro-2.0.8 ]; then
					require tar && \
					tar -zxf `download_distfile micro-2.0.8-$1.tar.gz https://github.com/zyedidia/micro/releases/download/v2.0.8/micro-2.0.8-$1.tar.gz` -C $HOME/.local/stow
				fi && \
				{ test -d $HOME/.local/stow/micro-2.0.8/bin || mkdir -p $HOME/.local/stow/micro-2.0.8/bin; } && \
				{ test -f $HOME/.local/stow/micro-2.0.8/bin/micro || mv $HOME/.local/stow/micro-2.0.8/micro $HOME/.local/stow/micro-2.0.8/bin/; } && \
				(cd $HOME/.local/stow && stow micro-2.0.8)
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
					linux_install_package py3-pip
					;;
				CentOS)
					linux_install_package python2-pip
					;;
				*)
					if ! linux_install_package python-pip; then
						echo "$0: Error: Don't know how to install pip on $distribution" 1>&2
						report_error
					fi
					;;
			esac
			;;
		NetBSD)
			install_package py38-pip
			;;
		OpenBSD)
			install_package py3-pip
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
				filename=xbase`uname -r | tr -d '.'`.tgz
				xbase_url=`cat /etc/installurl`/`uname -r`/`uname -m`/$filename
				require tar && \
				$sudo tar -zxpf `download_distfile $filename $xbase_url` -C / && \
				unset filename && \
				unset xbase_url
			fi && \
			install_package xsel
			;;
		*)
			echo "$0: Error: Unsupported platform: $os" 1>&2
			return 1
			;;
	esac
}

install_mg() {
	if [ "$os" = "Linux" -a "$distribution" = "Amazon" ]; then
		if [ ! -d "/tmp/mg-6.8.1" ]; then
			require tar && \
			require make && \
			require gcc && \
			tar -zxf `download_distfile mg-6.8.1.tar.gz https://github.com/ibara/mg/releases/download/mg-6.8.1/mg-6.8.1.tar.gz` -C /tmp
			(cd /tmp/mg-6.8.1 && ./configure && make && $sudo make install) && rm -rf /tmp/mg-6.8.1
		fi
	else
		install_package mg
	fi
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
			mg)           install_mg;;
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
	test -d $distfiles_dir || mkdir -p $distfiles_dir
	test -d $lisp_dir || mkdir -p $lisp_dir

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
