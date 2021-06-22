# Script to set up Python environment
# Copyright (C) 2021 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

python_describe_module() {
	cat <<-EOF
	python:
	    install Python programming language development tools
EOF
}

install_python_package() {
	pip3 install $1
}

install_python3() {
	case "$os" in
		FreeBSD)
			install_package python3
			;;
		Linux)
			case $distribution in
				Arch)
					linux_install_package python
					;;
				*)
					linux_install_package python3
					;;
			esac
			;;
		NetBSD)
			install_package python3.7
			;;
		OpenBSD)
			install_package python--%3.8
			;;
		*)
			install_package python3
			;;
	esac
}

install_tools_python() {
	cat <<-EOF
	-----------------------------------------
	Installing tools for Python
	-----------------------------------------
EOF

	has git || install git || report_error
	has python3 || install_python3 || report_error
	has pep8 || install_python_package pep8 || report_error
}
