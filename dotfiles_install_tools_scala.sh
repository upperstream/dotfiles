# Script to set up Scalanenvironment

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

install_jdk() {
	case "$os" in
		FreeBSD)
			install_package openjdk8
			;;
		Linux)
			case "$distribution" in
				Alpine)
					alpine_enable_community_repo && \
					linux_install_package openjdk8 && \
					(cd /usr/bin && $sudo ln -sf /usr/lib/jvm/default-jvm/bin/* .)
					;;
				CentOS)
					linux_install_package java-1.8.0-openjdk-devel
					;;
				Debian|Ubuntu)
					linux_install_package openjdk-8-jdk-headless
					;;
				Devuan)
					linux_install_package openjdk-7-jdk
					;;
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
	case "$os" in
		Linux)
			case "$distribution" in
				CentOS)        linux_install_package java-1.8.0-openjdk-src;;
				Debian|Ubuntu) linux_install_package openjdk-8-source;;
				Devuan)        linux_install_package openjdk-7-source;;
			esac
			;;
	esac
}

install_tools_scala() {
	cat <<-EOF
	-----------------------------------------
	Installing tools for Scala
	-----------------------------------------
EOF

	install jdk java-source sbt
#	install scala scala-doc scala-mode-el
}
