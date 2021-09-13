# Script to set up Terraform environment
# Copyright (C) 2021 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

terraform_describe_module() {
	cat <<-EOF
	terraform:
	    install Terraform environment
EOF
}

install_terraform() {
	require unzip && \
	require stow && \
	case $os in
		Darwin)
			package=terraform_1.0.6_darwin_amd64.zip
			;;
		FreeBSD)
			package=terraform_1.0.6_freebsd_amd64.zip
			;;
		Linux)
			package=terraform_1.0.6_linux_amd64.zip
			;;
		OpenBSD)
			package=terraform_1.0.6_openbsd_amd64.zip
			;;
		*)
			echo $os is not supported >&2
			return 1
			;;
	esac
	mkdir -p $HOME/.local/stow/terraform-1.0.6/bin
	unzip `download_distfile $package https://releases.hashicorp.com/terraform/1.0.6/$package` -d $HOME/.local/stow/terraform-1.0.6/bin
	(cd $HOME/.local/stow && stow terraform-1.0.6)
}

install_tools_terraform() {
	cat <<-EOF
	------------------------------
	Installing tools for Terraform
	------------------------------
EOF

	has terraform || install_terraform || report_error
}
