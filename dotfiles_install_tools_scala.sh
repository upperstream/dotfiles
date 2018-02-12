# Script to set up Scala environment
# Copyright (C) 2018 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

scala_describe_module() {
	cat <<-EOF
	scala:
	    install Scala programming language development tools
EOF
}

install_sbt() {
	has bash || install bash
	case "$os" in
		Darwin)
			install_package sbt@1
			;;
		FreeBSD)
			install_package sbt
			;;
		Linux)
			case "$distribution" in
				Alpine)
					alpine_enable_edge_repos && \
					linux_install_package sbt
					;;
				Arch)
					linux_install_package sbt
					;;
				CentOS)
					if ! grep "name=bintray--sbt-rpm" /etc/yum.repos.d/bintray-sbt-rpm.repo; then
						download https://bintray.com/sbt/rpm/rpm | \
							$sudo tee -a /etc/yum.repos.d/bintray-sbt-rpm.repo
					fi
					linux_install_package sbt
					;;
				Debian|Devuan|Ubuntu)
					linux_install_package apt-transport-https dirmngr
					if ! grep "^deb https://dl.bintray.com/sbt/debian" /etc/apt/sources.list.d/sbt.list; then
						echo "deb https://dl.bintray.com/sbt/debian /" | \
							$sudo tee -a /etc/apt/sources.list.d/sbt.list
						$sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
						$sudo apt-get update
					fi
					linux_install_package sbt
				;;
			esac
			;;
		NetBSD|OpenBSD)
			if ! has sbt; then
				filename=sbt-1.0.4.tgz
				download_distfile $filename https://github.com/sbt/sbt/releases/download/v1.0.4/$filename && \
				tar -zxf $distfiles_dir/$filename -C ~/.local && \
				unset filename
				(cd ~/.local/bin; ln -sf ../sbt/bin/* .)
			fi
			;;
	esac
}

install_tools_scala() {
	if [ "$os" = "Darwin" ] || ! has javac; then
		. $dotfiles_dir/dotfiles_install_tools_jdk.sh && install_tools_jdk || report_error
	fi
	cat <<-EOF
	-----------------------------------------
	Installing tools for Scala
	-----------------------------------------
EOF

	has sbt || install sbt || report_error
#	install scala scala-doc scala-mode-el
}
