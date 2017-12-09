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
		OpenBSD)
			pkg_add $@
			;;
	esac
}

install_editorconfig() {
	case `uname` in
		Darwin)
			brew install editorconfig
			;;
		OpenBSD)
			for t in cmake pcre; do
				has $t || install $t
			done
			ftp -o- https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz | tar -zxf - -C /tmp
			(cd /tmp/editorconfig-core-c-0.12.1 && cmake . && make && doas make install) && rm -rf /tmp/editorconfig-core-c-0.12.1
			;;
	esac
}

install() {
	for t in $@; do
		case $t in
			editorconfig)
				install_editorconfig
				;;
			*)
				install_package $t
				;;
		esac
	done
}

has() {
	command -v $1 >/dev/null
}

if [ `id -u` -ne 0 ]; then
	echo "You may need the root privilege to run this script." 1>&2
fi

# Micro editor
has micro || install micro

# EditorConfig Core C
has editorconfig || install editorconfig
