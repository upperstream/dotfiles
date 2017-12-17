#!/bin/sh
# Install basic tools.
# Copyright (C) 2017 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

#set -x

usage() {
	cat <<-EOF
	Usage
	$0 [-x]
	$0 -H|--help

	-x : install additional tools for X Window System; this may install
	     X Window System as a part of dependencies
	-H|--help
	   : print this help summary and exit
EOF
}

test "$1" = "--help" && { usage; exit 255; }

with_x11=0

while getopts xH opt; do
	case $opt in
		x) with_x11=1;;
		H) usage; exit 255;;
	esac
done

locate_pip() {
	pip=`command -v pip 2>/dev/null` || pip=`command -v pip2.7 2>/dev/null` || return 1
	echo "pip=$pip"
}

install_package() {
	case `uname` in
		Darwin)
			brew install $@
			;;
		FreeBSD)
			sudo pkg install -y $@
			;;
		NetBSD)
			sudo pkg_add $@
			;;
		OpenBSD)
			doas pkg_add $@
			;;
		*)
			echo "$0: Error: Unsupported platform: `uname`" 1>&2
			return 1
			;;
	esac
}

determine_downloader() {
	for name in fetch ftp curl wget; do
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
	case `uname` in
		Darwin|FreeBSD)
			install_package abduco
			;;
		NetBSD|OpenBSD)
			install_package dtach
			;;
		*)
			download http://www.brain-dump.org/projects/abduco/abduco-0.6.tar.gz | tar -zxf - -C /tmp && \
			(cd /tmp/abduco-*; make && sudo make install) && \
			rm -rf /tmp/abduco-*
			;;
	esac
}

install_cdiff() {
	case `uname` in
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
	printf "s/^M/# M/\n/# .*`uname`/ {N; s/\\\n# /\\\\\n/; }\ns:^PREFIX = /usr/local:PREFIX = \${HOME}/.local:" > config.sed && \
	(rm config.mk && sed -f config.sed > config.mk) < config.mk && \
	make install) && \
	rm -rf /tmp/upperstream-dirstack-*
}

install_dvtm() {
	case `uname` in
		Darwin)
			brew install ncurses
			brew link --force ncurses
			download http://www.brain-dump.org/projects/dvtm/dvtm-0.15.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/dvtm-*; \
			(rm config.mk; sed '/^CPPFLAGS =/ s/-D_POSIX_C_SOURCE=[^ ]*//; s/-D_XOPEN_SOURCE[^ ]*//g' > config.mk) < config.mk && \
			make && sudo make install) && \
			rm -rf /tmp/dvtm-*
			;;
		FreeBSD|NetBSD|OpenBSD)
			install_package dvtm
			;;
		*)
			download http://www.brain-dump.org/projects/dvtm/dvtm-0.15.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/dvtm-*; make && sudo make install) && \
			rm -rf /tmp/dvtm-*
			;;
	esac
}

install_editorconfig() {
	case `uname` in
		Darwin)
			brew install editorconfig
			;;
		FreeBSD)
			install_package editorconfig-core-c
			;;
		NetBSD)
			install_package editorconfig-core
			;;
		OpenBSD)
			for t in cmake pcre; do
				has $t || install_package $t
			done
			has gcc || download `cat /etc/installurl`/`uname -r`/`uname -m`/comp`uname -r | tr -d '.'`.tgz | doas tar -zxpf - -C /
			download https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/editorconfig-core-c-0.12.1 && cmake . && make && doas make install) && rm -rf /tmp/editorconfig-core-c-0.12.1
			;;
		*)
			echo "$0: Error: Unsupported platform: `uname`" 1>&2
			return 1
			;;
	esac
}

install_markdown() {
	case `uname` in
		FreeBSD|NetBSD|OpenBSD)
			install_package p5-Text-Markdown
			;;
		*)
			install_package markdown
			;;
	esac
}

install_micro() {
	case `uname` in
		NetBSD)
			{ has stow || install_package stow; } && \
			{ test -d $HOME/.local/stow || mkdir -p $HOME/.local/stow; } && \
			download https://github.com/zyedidia/micro/releases/download/v1.3.4/micro-1.3.4-netbsd64.tar.gz | tar zxf - -C $HOME/.local/stow && \
			{ mkdir -p $HOME/.local/stow/micro-1.3.4/bin && mv $HOME/.local/stow/micro-1.3.4/micro $HOME/.local/stow/micro-1.3.4/bin/; } && \
			(cd $HOME/.local/stow && stow micro-1.3.4)
			;;
		*)
			install_package micro
			;;
	esac
}

install_pip() {
	case `uname` in
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

install_xsel() {
	case `uname` in
		Darwin)
			brew install xclip
			;;
		FreeBSD|NetBSD)
			install_package xsel
			;;
		OpenBSD)
			if [ ! -f /usr/X11R6/lib/libX11.a ]; then
				download `cat /etc/installurl`/`uname -r`/`uname -m`/xbase`uname -r | tr -d '.'`.tgz | doas tar -zxpf - -C /
			fi
			install_package xsel
			;;
		*)
			echo "$0: Error: Unsupported platform: `uname`" 1>&2
			return 1
			;;
	esac
}

install() {
	for t in $@; do
		case $t in
			abduco)
				install_abduco
				;;
			cdiff)
				install_cdiff
				;;
			dirstack)
				install_dirstack
				;;
			dvtm)
				install_dvtm
				;;
			editorconfig)
				install_editorconfig
				;;
			Markdown)
				install_markdown
				;;
			micro)
				install_micro
				;;
			pip)
				install_pip
				;;
			xsel)
				install_xsel
				;;
			*)
				install_package $t
				;;
		esac
		rc=$?
		test $rc -ne 0 && return $rc
	done
}

has() {
	command -v $1 >/dev/null
}

locate_pip

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
has pushd || install dirstack

# cdiff
has cdiff || install cdiff

# adbuco or dtach
{ has abduco || has dtach; } || install abduco

# dvtm
has dvtm || install dvtm

# mg
has mg || install mg

test $with_x11 -eq 1 || exit

# Additional tools for X Window System

# XSel or xclip
{ has xsel || has xclip; } || install xsel
