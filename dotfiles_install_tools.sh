#!/bin/sh
# Install basic tools.
# Copyright (C) 2017 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

set -x

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
			ftp -o- $1 | tar -zxf - -C $2
			;;
		curl)
			curl -L $1 | tar -zxf - -C $2
			;;
		wget)
			wget -O- $1 | tar -zxf - -C $2
			;;
	esac
}

install_dirstack() {
	download https://bitbucket.org/upperstream/dirstack/get/20171213.tar.gz /tmp || return 1
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
			has gcc || ftp -o- `cat /etc/installurl`/`uname -r`/`uname -m`/comp`uname -r | tr -d '.'`.tgz | doas tar -zxvpf - -C /
			download https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz /tmp
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
			download https://github.com/zyedidia/micro/releases/download/v1.3.4/micro-1.3.4-netbsd64.tar.gz $HOME/.local/stow && \
			{ mkdir -p $HOME/.local/stow/micro-1.3.4/bin && mv $HOME/.local/stow/micro-1.3.4/micro $HOME/.local/stow/micro-1.3.4/bin/; } && \
			(cd $HOME/.local/stow && stow micro-1.3.4)
			;;
		*)
			install_package micro
			;;
	esac
}

install() {
	for t in $@; do
		case $t in
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
