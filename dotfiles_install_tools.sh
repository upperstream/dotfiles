#!/bin/sh
# Install basic tools.
# Copyright (C) 2017 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

set -x

locate_pip() {
set -x
	pip=`command -v pip 2>/dev/null` || pip=`command -v pip2.7 2>/dev/null` || return 1
	echo "pip=$pip"
}

install_package() {
	case `uname` in
		Darwin)
			brew install $@
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
	for name in ftp curl wget; do
		has $name && { echo $name; return 0; }
	done
	install curl && { echo curl; return 0; }
	install wget && { echo wget; return 0; }
}

downloader=""

download() {
	test -z "$downloader" && { downloader=`determine_downloader` || return 1; }
	case $downloader in
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

install_cdiff() {
	has pip || install pip
	$pip install --user cdiff
}

install_dirstack() {
	download https://bitbucket.org/upperstream/dirstack/get/20171213.tar.gz | tar -zxf - -C /tmp || return 1
	(cd /tmp/upperstream-dirstack-* && \
	printf "s/^M/# M/\n/# .*`uname`/ {N; s/\\\n# /\\\\\n/; }\ns:^PREFIX = /usr/local:PREFIX = \${HOME}/.local:" > config.sed && \
	(rm config.mk && sed -f config.sed > config.mk) < config.mk && \
	make install) && \
	rm -rf /tmp/upperstream-dirstack-*
}

install_editorconfig() {
	case `uname` in
		Darwin)
			brew install editorconfig
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
		NetBSD|OpenBSD)
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
set -x
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

install() {
	for t in $@; do
		case $t in
			cdiff)
				install_cdiff
				;;
			dirstack)
				install_dirstack
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
