#!/bin/sh
# Install basic tools.
# Copyright (C) 2017 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

#set -x

usage() {
	cat <<-EOF
	Usage:
	$0 [-s set] [-x]
	$0 -H|--help

	-s set
	   : install specified set in the following list:
             - scala
	-x : install additional tools for X Window System; this may install
	     X Window System as a part of dependencies
	-H|--help
	   : print this help summary and exit
EOF
}

test "$1" = "--help" && { usage; exit 255; }

with_x11=0

sets=""

while getopts s:xH opt; do
	case $opt in
		s) sets=`printf "$sets\n$OPTARG"`;;
		x) with_x11=1;;
		H) usage; exit 255;;
	esac
done

locate_pip() {
	pip=`command -v pip 2>/dev/null` || pip=`command -v pip2.7 2>/dev/null` || return 1
	echo "pip=$pip"
}

os=""
distribution=""

determine_operating_system() {
	test -z "$os" && os=`uname`
	if [ "$os" = "Linux" ]; then
		name=`cat /etc/*release | grep -F "NAME="`
		case $name in
			*CentOS*)
				distribution="CentOS"
				;;
			*Debian*)
				distribution="Debian"
				;;
			*Devuan*)
				distribution="Devuan"
				;;
			*Ubuntu*)
				distribution="Ubuntu"
				;;
			*)
				echo "$0: Warning: Unknown distribution: $name" 1>&2
				;;
		esac
	fi

	echo "OS=$os"
	test "$os" = "Linux" && echo "DISTRIBUTION=$distribution"
}

pkgmgr=""

determine_package_manager() {
	for name in apt-get yum; do
		has $name && { echo $name; return 0; }
	done
	return 1
}

sudo=""
determine_sudo_command() {
	for name in sudo doas; do
		if has $name; then
			sudo=$name
			echo "sudo=$name"
			return 0
		fi
	done
	return 1
}

linux_install_package() {
	test -z "$pkgmgr" && { pkgmgr=`determine_package_manager` || return 1; }
	case $pkgmgr in
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
	case $os in
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

determine_downloader() {
	test "$os" != "Linux" -a "$os" != "Darwin" && for name in fetch ftp; do
		has $name && { echo $name; return 0; }
	done
	for name in curl wget; do
		has $name && { echo $name; return 0; }
	done
	install curl && { echo curl; return 0; }
	install wget && { echo wget; return 0; }
}

downloader=""

download() {
	test -z "$downloader" && { downloader=`determine_downloader` || return 1; }
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
	case $os in
		Darwin|FreeBSD)
			install_package abduco
			;;
		Linux)
			case $distribution in
				Devuan) linux_install_package dtach;;
				*)      linux_install_package abduco;;
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
	case $os in
		FreeBSD)
			install_package cdiff
			;;
		*)
			has pip || install pip
			$pip install --user cdiff
			;;
	esac
}

install_dirstack() {
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
	case $os in
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
			case $distribution in
				CentOS)
					linux_install_package ncurses-devel
					has gcc || linux_install_package gcc
					install_from_source_dvtm
					;;
				Debian|Devuan|Ubuntu)
					linux_install_package dvtm
					;;
				*)
					echo "$0: Error: Unsupported platform: $os" 1>&2
					return 1
					;;
			esac
			;;
		*)
			install_from_source_dvtm
			;;
	esac
}

install_from_source_editorconfig() {
	download https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz | tar -zxf - -C /tmp
	(cd /tmp/editorconfig-core-c-0.12.1 && cmake . && make && $sudo make install) && rm -rf /tmp/editorconfig-core-c-0.12.1
}

install_editorconfig() {
	case $os in
		Darwin)
			brew install editorconfig
			;;
		FreeBSD)
			install_package editorconfig-core-c
			;;
		Linux)
			case $distribution in
				CentOS)
					for t in cmake pcre-devel; do
						linux_install_package $t
					done
					has gcc || linux_install_package gcc
					install_from_source_editorconfig
					;;
				Debian|Devuan|Ubuntu)
					linux_install_package editorconfig
					;;
				*)
					echo "$0: Error: Unsupported platform: $os" 1>&2
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
	case $os in
		Darwin)
			brew uninstall emacs
			install_package -c emacs
			;;
		FreeBSD)
			install_package emacs25
			;;
		Linux)
			case $distribution in
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
	case $os in
		Darwin)
			brew cask uninstall emacs
			install_package emacs
			;;
		FreeBSD)
			install_package emacs-nox11
			;;
		Linux)
			case $distribution in
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
	case $os in
		FreeBSD|NetBSD|OpenBSD)
			install_package p5-Text-Markdown
			;;
		Linux)
			case $distribution in
				CentOS) linux_install_package perl-Text-Markdown;;
				*)      linux_install_package markdown;;
			esac
			;;
		*)
			install_package markdown
			;;
	esac
}

__install_micro() {
	case $1 in
		linux64|netbsd64)
			{ has stow || install_package stow; } && \
			{ test -d $HOME/.local/stow || mkdir -p $HOME/.local/stow; } && \
			download https://github.com/zyedidia/micro/releases/download/v1.3.4/micro-1.3.4-$1.tar.gz | tar zxf - -C $HOME/.local/stow && \
			{ mkdir -p $HOME/.local/stow/micro-1.3.4/bin && mv $HOME/.local/stow/micro-1.3.4/micro $HOME/.local/stow/micro-1.3.4/bin/; } && \
			(cd $HOME/.local/stow && stow micro-1.3.4)
			;;
		*)
			echo "$0: Error: Unsupported platform: `uname`" 1>&2
			return 1
			;;
	esac
}

install_micro() {
	case $os in
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
	case $os in
		Linux)
			case $distribution in
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
			download https://bootstrap.pypa.io/get-pip.py | python - --user
			;;
	esac
	rc=$?
	locate_pip
	return $?
}

install_sbt() {
	has bash || install bash
	case $os in
		Darwin)
			install_package sbt@1
			;;
		FreeBSD)
			install_package sbt
			;;
		Linux)
			case $distribution in
				CentOS)
					if ! grep "name=bintray--sbt-rpm" /etc/yum.repos.d/bintray-sbt-rpm.repo; then
						download https://bintray.com/sbt/rpm/rpm | $sudo tee -a /etc/yum.repos.d/bintray-sbt-rpm.repo
					fi
					linux_install_package sbt
					;;
				Debian|Devuan|Ubuntu)
					linux_install_package apt-transport-https dirmngr
					if ! grep "^deb https://dl.bintray.com/sbt/debian" /etc/apt/sources.list.d/sbt.list; then
						echo "deb https://dl.bintray.com/sbt/debian /" | $sudo tee -a /etc/apt/sources.list.d/sbt.list
						$sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
						$sudo apt-get update
					fi
					linux_install_package sbt
				;;
			esac
			;;
		NetBSD|OpenBSD)
			if ! has sbt; then
				download https://github.com/sbt/sbt/releases/download/v1.0.4/sbt-1.0.4.tgz | tar -zxf - -C ~/.local && \
				(cd ~/.local/bin; ln -sf ../sbt/bin/* .)
			fi
			;;
	esac
}

install_xsel() {
	case $os in
		Darwin)
			brew install xclip
			;;
		FreeBSD|NetBSD)
			install_package xsel
			;;
		Linux)
			install_package xsel
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

install_jdk() {
	case $os in
		FreeBSD)
			install_package openjdk8
			;;
		Linux)
			case $distribution in
				CentOS)        linux_install_package java-1.8.0-openjdk-devel;;
				Debian|Ubuntu) linux_install_package openjdk-8-jdk-headless;;
				Devuan)        linux_install_package openjdk-7-jdk;;
			esac
			;;
		NetBSD)
			install_package openjdk8 && \
			(cd ~/.local/bin; ln -sf /usr/pkg/java/openjdk8/bin/* .)
			;;
		OpenBSD)
			if [ ! -f /usr/X11R6/lib/libX11.a ]; then
				download `cat /etc/installurl`/`uname -r`/`uname -m`/xbase`uname -r | tr -d '.'`.tgz | $sudo tar -zxpf - -C /
			fi
			install_package jdk && \
			(cd ~/.local/bin; ln -sf /usr/local/jdk-1.8.0/bin/* .)
			;;
	esac
}

install_java_source() {
	case $os in
		Linux)
			case $distribution in
				CentOS)        linux_install_package java-1.8.0-openjdk-src;;
				Debian|Ubuntu) linux_install_package openjdk-8-source;;
				Devuan)        linux_install_package openjdk-7-source;;
			esac
			;;
	esac
}

install_scala_tools() {
	install jdk java-source sbt
#	install scala scala-doc scala-mode-el
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

locate_pip
determine_operating_system
determine_sudo_command
printf "Additional sets to install: $sets\n"

test -d ~/.local/bin || mkdir -p ~/.local/bin

# Micro editor
has micro || install micro

# EditorConfig Core C
has editorconfig || install editorconfig

# nano
has nano || install nano

# Markdown
{ has Markdown || has Markdown.pl; } || install Markdown

# lynx
has lynx || install lynx

# dirstack
has dirstack.sh || install dirstack

# cdiff
has cdiff || install cdiff

# adbuco or dtach
{ has abduco || has dtach; } || install abduco

# dvtm
has dvtm || install dvtm

# mg
has mg || install mg

# Emacs
test $with_x11 -eq 0 && install emacs-nox11

for s in `echo $sets`; do
	case $s in
		scala)
			install_scala_tools
			;;
	esac
done

test $with_x11 -eq 1 || exit

# Additional tools for X Window System

# XSel or xclip
{ has xsel || has xclip; } || install xsel

# Emacs
install emacs
