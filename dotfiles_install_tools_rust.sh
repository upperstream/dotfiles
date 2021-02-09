# Script to set up Rust environment
# Copyright (C) 2021 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

rust_describe_module() {
	cat <<-EOF
	rust:
	    install Rust programming language development tools
EOF
}

install_distribution_golang() {
	tar -zxf `download_distfile go1.15.6.linux-amd64.tar.gz https://dl.google.com/go/go1.15.6.linux-amd64.tar.gz` -C $local_dir/ && \
	(cd $local_dir/bin && \
	ln -sf $local_dir/go/bin/* .)
}

install_rust() {
	case "$os" in
		Linux)
			case $distribution in
				Alpine)
					alpine_enable_community_repo && linux_install_package rust
					;;
				*)
					linux_install_package rust
					;;
			esac
			;;
		*)
			install_package rust
			;;
	esac
}

install_rust_distribution() {
	require curl
	require gcc
	curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
}

install_tools_rust() {
	cat <<-EOF
	----------------------------------------------
	Installing tools for Rust Programming Language
	----------------------------------------------
EOF

	has git || install git || report_error
	has rustc || \
		if [ $prefer_binary_package -eq 1 ]; then
			install_rust
		else
			install_rust_distribution
		fi || report_error
#	if [ ! -f $lisp_dir/gotags.el ]; then
#		download https://raw.githubusercontent.com/craig-ludington/gotags-el/master/me-alpheus-gotags.el > $lisp_dir/gotags.el
#	fi
}
