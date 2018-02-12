# Script to set up Golang environment
# Copyright (C) 2018 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

golang_describe_module() {
	cat <<-EOF
	golang:
	    install Go programming language development tools
EOF
}

go_install_package() {
	go get $@
}

install_golang() {
	case "$os" in
		FreeBSD)
			install_package go
			;;
		Linux)
			case $distribution in
				Alpine)
					alpine_enable_edge_repos && linux_install_package libc-dev go
					;;
				Arch)
					linux_install_package go
					;;
				*)
					linux_install_package golang
					;;
			esac
			;;
		NetBSD)
			if [ ! -x /usr/pkg/sbin/mozilla-rootcerts ]; then
				install_package mozilla-rootcerts
			fi && \
			if [ ! -f `echo /etc/openssl/certs/mozilla-rootcert-* | cut -f1 -d' '` ]; then
				$sudo /usr/pkg/sbin/mozilla-rootcerts install
			fi && \
			install_package go
			;;
		OpenBSD)
			install_package go
			;;
		*)
			install_package golang
			;;
	esac
}

install_tools_golang() {
	cat <<-EOF
	-----------------------------------------
	Installing tools for Golang
	-----------------------------------------
EOF

	has git || install git || report_error
	has go || install_golang || report_error
	GOPATH=$HOME/go
	export GOPATH
	test -d $GOPATH || mkdir -p $GOPATH
	PATH=$PATH:$GOPATH/bin
	has gocode || go_install_package github.com/nsf/gocode || report_error
	has gotags || go_install_package github.com/jstemmer/gotags || report_error
	has joe || install joe || report_error
	if [ ! -f $lisp_dir/gotags.el ]; then
		download https://raw.githubusercontent.com/craig-ludington/gotags-el/master/me-alpheus-gotags.el > $lisp_dir/gotags.el
	fi
}
