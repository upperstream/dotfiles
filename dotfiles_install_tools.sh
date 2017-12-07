#!/bin/sh
# Install basic tools.
# Copyright (C) 2017 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

set -x

install() {
case `uname` in
	OpenBSD)
		pkg_add $@
		;;
esac
}

has() {
	command -v $1 >/dev/null
}

if [ `id -u` -ne `id -u root` ]; then
	echo "You need the root privilege to run this script." 1>&2
	exit 1
fi

# Micro editor
has micro || install micro

# EditorConfig core library
for t in cmake pcre; do
	has $t || install $t
done
ftp -o- https://github.com/editorconfig/editorconfig-core-c/archive/v0.12.1.tar.gz | tar -zxf - -C /tmp
(cd /tmp/editorconfig-core-c-0.12.1 && cmake . && make && doas make install) && rm -rf /tmp/editorconfig-core-c-0.12.1
