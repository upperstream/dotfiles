#!/bin/sh

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
	install git
	install_golang
	GOPATH=$HOME/go
	export GOPATH
	test -d $GOPATH || mkdir -p $GOPATH
	go_install_package github.com/nsf/gocode github.com/jstemmer/gotags
	install joe
	test -d $HOME/.emacs.d/lisp || mkdir -p $HOME/.emacs.d/lisp
	if [ ! -f $HOME/.emacs.d/lisp/gotags.el ]; then
		download https://raw.githubusercontent.com/craig-ludington/gotags-el/master/me-alpheus-gotags.el > $HOME/.emacs.d/lisp/gotags.el
	fi
}
