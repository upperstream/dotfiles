# Script to set up Zig environment
# Copyright (C) 2026 Upperstream Software.
# Provided under the ISC License.  See LICENSE.txt file for details.

# shellcheck disable=SC2148,SC2154

zig_describe_module() {
	cat <<-EOF
	zig:
	    install Zig programming language development tools
EOF
}

install_distribution_zig() (
	case "$os" in
		Darwin) zig_os=macos;;
		FreeBSD) zig_os=freebsd;;
		Linux) zig_os=linux;;
		NetBSD) zig_os=netbsd;;
		OpenBSD) zig_os=openbsd;;
		*)
			printf '%s: Error: Unsupported Zig platform: %s\n' \
				"$0" "$os" >&2
			return 1
			;;
	esac
	if [ "$os" = NetBSD ]; then
		zig_arch=$(uname -p) || return 1
	else
		zig_arch=$(uname -m) || return 1
	fi
	case "$zig_arch" in
		amd64) zig_arch=x86_64;;
		arm64) zig_arch=aarch64;;
		i[3-6]86) zig_arch=x86;;
		armv6|armv7|armv6l|armv7l|armv8l|earmv6hf|earmv7hf)
			zig_arch=arm;;
		ppc64le) zig_arch=powerpc64le;;
	esac
	zig_target="$zig_arch-$zig_os"

	for tool in jq openssl tar; do
		has "$tool" || install_package "$tool" || return 1
	done
	if ! has xz; then
		case "$os:${distribution:-}" in
			Linux:Debian|Linux:Devuan|Linux:Ubuntu)
				install_package xz-utils || return 1
				;;
			*) install_package xz || return 1;;
		esac
	fi

	mkdir -p "$distfiles_dir" "$local_dir/bin" || return 1
	zig_work=$(mktemp -d "$distfiles_dir/zig.XXXXXXXX") || return 1
	trap 'rm -rf "$zig_work"' 0
	trap 'exit 1' HUP INT TERM

	download https://ziglang.org/download/index.json > \
		"$zig_work/index.json" || return 1
	zig_metadata=$(jq -ec --arg target "$zig_target" '
		. as $releases
		| [keys[] | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))]
		| sort_by(split(".") | map(tonumber)) | last
		| $releases[.][$target] // empty
	' "$zig_work/index.json") || {
		printf '%s: Error: No stable Zig binary for %s\n' \
			"$0" "$zig_target" >&2
		return 1
	}
	zig_url=$(printf '%s\n' "$zig_metadata" | jq -er \
		'.tarball | select(startswith("https://ziglang.org/"))') || \
		return 1
	zig_sha=$(printf '%s\n' "$zig_metadata" | jq -er \
		'.shasum | select(test("^[0-9a-f]{64}$"))') || return 1
	zig_filename=${zig_url##*/}
	case "$zig_filename" in
		zig-*.tar.xz) ;;
		*) return 1;;
	esac
	zig_archive="$distfiles_dir/$zig_filename"
	if [ ! -f "$zig_archive" ]; then
		download "$zig_url" > "$zig_work/download.tar.xz" || return 1
		mv "$zig_work/download.tar.xz" "$zig_archive" || return 1
	fi
	zig_digest=$(openssl dgst -sha256 "$zig_archive") || return 1
	if [ "${zig_digest##* }" != "$zig_sha" ]; then
		printf '%s: Error: Zig checksum mismatch: %s\n' \
			"$0" "$zig_filename" >&2
		rm -f "$zig_archive"
		return 1
	fi

	# Decompress separately: POSIX pipelines hide decompressor failures,
	# and not every BSD tar supports xz compression directly.
	xz -dc "$zig_archive" > "$zig_work/zig.tar" || return 1
	tar -xf "$zig_work/zig.tar" -C "$local_dir" || return 1
	zig_bundle="$local_dir/${zig_filename%.tar.xz}"
	[ -x "$zig_bundle/zig" ] || return 1
	if [ -d "$local_dir/bin/zig" ]; then
		printf '%s: Error: Zig destination is a directory: %s\n' \
			"$0" "$local_dir/bin/zig" >&2
		return 1
	fi
	ln -sf "$zig_bundle/zig" "$local_dir/bin/zig"
)

install_zig() {
	if [ "$prefer_binary_package" -eq 0 ]; then
		install_distribution_zig
		return $?
	fi
	case "$os" in
		Darwin|FreeBSD|NetBSD|OpenBSD)
			install_package zig
			;;
		Linux)
			if [ "$distribution" = Alpine ]; then
				alpine_enable_community_repo || return 1
			fi
			install_package zig
			;;
		*)
			printf '%s: Error: Unsupported Zig platform: %s\n' \
				"$0" "$os" >&2
			return 1
			;;
	esac
}

install_tools_zig() {
	cat <<-EOF
	-----------------------------------------
	Installing tools for Zig
	-----------------------------------------
EOF

	has zig || install_zig || report_error
}
