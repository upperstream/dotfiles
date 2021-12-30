# Script to set up Docker environment
# Copyright (C) 2021 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

docker_describe_module() {
	cat <<-EOF
	docker:
	    install Docker environment
EOF
}

install_docker() {
	case "$os" in
		Linux)
			case "$distribution" in
				Alpine)
					$sudo sed -i "/community/s/^#//" /etc/apk/repositories
					$sudo apk --update add docker
					;;
				Amazon)
					$sudo amazon-linux-extras install docker
					;;
				*)
					download https://get.docker.com | $sudo sh -
					;;
			esac
			;;
		*)
			echo "$0: Error: don't know how to install Docker on $os" 1>&2
			return 1
			;;
	esac
}

install_docker_compose() {
	if [ "$os" = "Linux" ] && [ "$distribution" = "Alpine" ]; then
		$sudo sed -i "/community/s/^#//" /etc/apk/repositories
		$sudo apk --update add docker-compose
	else
		$pip install docker-compose
	fi
}

enable_docker_daemon() {
	case "$distribution" in
		Alpine)
			$sudo rc-update add docker boot
			$sudo rc-service docker start
			;;
		Devuan)
			$sudo update-rc.d docker defaults
			$sudo /etc/init.d/docker start
			;;
		*)
			$sudo systemctl enable docker
			$sudo systemctl start docker
			;;
	esac
}

disable_docker_daemon() {
	case "$distribution" in
		Alpine)
			$sudo rc-service docker stop
			$sudo rc-update del docker boot
			;;
		Devuan)
			$sudo /etc/init.d/docker stop
			$sudo update-rc.d docker defaults-disabled
			;;
		*)
			$sudo systemctl stop docker
			$sudo systemctl disable docker
			;;
	esac
}

install_tools_docker() {
	cat <<-EOF
	---------------------------
	Installing tools for Docker
	---------------------------
	--docker-daemon-disabled=$docker_daemon_disabled
EOF

	has docker-compose || install_docker_compose || report_error
	has docker || install_docker || report_error

	if has docker; then
		if [ "$docker_daemon_disabled" = "yes" ]; then
			disable_docker_daemon
		else
			enable_docker_daemon
		fi
	fi
}
