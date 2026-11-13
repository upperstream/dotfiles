#!/bin/sh
# Tests for the Zig installer; requires jq, openssl, tar, and xz.
# Provided under the ISC License.  See LICENSE.txt file for details.

# shellcheck disable=SC2034

set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zig-test.XXXXXXXX")
trap 'rm -rf "$test_dir"' 0
trap 'exit 1' HUP INT TERM

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_equal() {
	[ "$1" = "$2" ] || fail "expected '$2', got '$1'"
}

setup() {
	case_dir="$test_dir/$1"
	mkdir -p "$case_dir/fixtures"
	local_dir="$case_dir/local directory"
	distfiles_dir="$case_dir/distfiles directory"
	prefer_binary_package=0
	os=Linux
	distribution=Debian
	machine=x86_64
	zig_present=0
	missing_tool=''
	package_status=0
	download_failure=''
	: > "$case_dir/downloads"
	: > "$case_dir/packages"
	: > "$case_dir/repos"
	: > "$case_dir/errors"
	[ -f "$repo_dir/dotfiles_install_tools_zig.sh" ] || \
		fail 'Zig installer module is missing'
	. "$repo_dir/dotfiles_install_tools_zig.sh"
}

# Replace host detection, network, and package-manager side effects only.
uname() {
	case "$1" in
		-m) printf '%s\n' "$machine";;
		-p) printf '%s\n' "$processor";;
		*) fail "unexpected uname arguments: $*";;
	esac
}

has() {
	[ "$1" != zig ] || { [ "$zig_present" -eq 1 ]; return $?; }
	[ "$1" != "$missing_tool" ] || return 1
	command -v "$1" >/dev/null 2>&1
}

install_package() {
	printf '%s\n' "$*" >> "$case_dir/packages"
	return "$package_status"
}

report_error() {
	printf 'error\n' >> "$case_dir/errors"
	return 1
}

alpine_enable_community_repo() {
	printf 'community\n' >> "$case_dir/repos"
}

download() {
	printf '%s\n' "$1" >> "$case_dir/downloads"
	if [ "${1##*/}" = "$download_failure" ]; then
		printf 'partial download\n'
		return 1
	fi
	cat "$case_dir/fixtures/${1##*/}"
}

make_fixture() {
	target=$1
	bundle="zig-$target-0.10.0"
	mkdir -p "$case_dir/source/$bundle/lib/std"
	printf '#!/bin/sh\nprintf "0.10.0\\n"\n' > \
		"$case_dir/source/$bundle/zig"
	chmod +x "$case_dir/source/$bundle/zig"
	printf 'fixture standard library\n' > \
		"$case_dir/source/$bundle/lib/std/std.zig"
	tar -cf "$case_dir/bundle.tar" -C "$case_dir/source" "$bundle"
	xz -c "$case_dir/bundle.tar" > "$case_dir/fixtures/$bundle.tar.xz"
	digest=$(openssl dgst -sha256 "$case_dir/fixtures/$bundle.tar.xz")
	digest=${digest##* }
	jq -n --arg target "$target" --arg digest "$digest" \
		--arg url "https://ziglang.org/download/0.10.0/$bundle.tar.xz" '
		{
			"master": {"version": "0.11.0-dev.1"},
			"0.9.0": {},
			"0.10.0": {($target): {tarball: $url, shasum: $digest}}
		}' > "$case_dir/fixtures/index.json"
}

test_linux_distribution() (
	setup linux
	make_fixture x86_64-linux
	install_tools_zig || fail 'Linux installation failed'
	[ -L "$local_dir/bin/zig" ] || fail 'Zig symlink is missing'
	assert_equal "$("$local_dir/bin/zig" version)" '0.10.0'
	[ -f "$local_dir/$bundle/lib/std/std.zig" ] || \
		fail 'Zig standard library was not preserved'
	assert_equal "$(cat "$case_dir/packages")" ''
	assert_equal "$(wc -l < "$case_dir/downloads" | tr -d ' ')" 2
)

test_linux_distribution
printf 'PASS: Linux upstream installation\n'

test_platform_distribution() (
	setup "$1-$2-${4:-$2}"
	os=$1
	machine=$2
	processor=${4:-$2}
	make_fixture "$3"
	install_distribution_zig || fail "installation failed for $1/$2"
	assert_equal "$("$local_dir/bin/zig" version)" '0.10.0'
)

while read -r platform architecture target cpu; do
	test_platform_distribution "$platform" "$architecture" \
		"$target" "$cpu"
	printf 'PASS: %s/%s -> %s\n' "$platform" "$architecture" "$target"
done <<-EOF
	Darwin x86_64 x86_64-macos
	Darwin arm64 aarch64-macos
	FreeBSD amd64 x86_64-freebsd
	FreeBSD arm64 aarch64-freebsd
	OpenBSD amd64 x86_64-openbsd
	OpenBSD arm64 aarch64-openbsd
	NetBSD amd64 x86_64-netbsd
	NetBSD evbarm aarch64-netbsd aarch64
	NetBSD evbarm arm-netbsd earmv7hf
	Linux aarch64 aarch64-linux
	Linux i686 x86-linux
	Linux armv7l arm-linux
	Linux ppc64le powerpc64le-linux
	Linux riscv64 riscv64-linux
EOF

test_native_package() (
	setup "package-$1-$2"
	os=$1
	distribution=$2
	prefer_binary_package=1
	install_zig || fail "native package installation failed for $1/$2"
	assert_equal "$(cat "$case_dir/packages")" zig
	assert_equal "$(cat "$case_dir/downloads")" ''
	if [ "$2" = Alpine ]; then
		assert_equal "$(cat "$case_dir/repos")" community
	fi
)

while read -r platform distro; do
	test_native_package "$platform" "$distro"
	printf 'PASS: %s/%s native package\n' "$platform" "$distro"
done <<-EOF
	Linux Debian
	Linux Ubuntu
	Linux Devuan
	Linux Alpine
	Linux Arch
	Linux CentOS
	Darwin unused
	FreeBSD unused
	OpenBSD unused
	NetBSD unused
EOF

test_existing_zig() (
	setup existing
	zig_present=1
	install_tools_zig || fail 'existing Zig was not skipped'
	assert_equal "$(cat "$case_dir/downloads")" ''
	assert_equal "$(cat "$case_dir/packages")" ''
)

test_cached_archive() (
	setup cached
	make_fixture x86_64-linux
	install_distribution_zig || fail 'initial installation failed'
	install_distribution_zig || fail 'cached installation failed'
	assert_equal "$(wc -l < "$case_dir/downloads" | tr -d ' ')" 3
	assert_equal "$("$local_dir/bin/zig" version)" '0.10.0'
)

test_failure() (
	setup "failure-$1"
	make_fixture x86_64-linux
	archive_fixture="$case_dir/fixtures/$bundle.tar.xz"
	index_fixture="$case_dir/fixtures/index.json"
	case "$1" in
		unsupported-os) os=SunOS;;
		unsupported-package-os)
			os=SunOS
			prefer_binary_package=1
			;;
		unsupported-arch) machine=mips;;
		invalid-index) printf 'invalid JSON\n' > "$index_fixture";;
		index-download) download_failure=index.json;;
		archive-download) download_failure="$bundle.tar.xz";;
		bad-checksum)
			printf 'corrupt archive\n' > "$archive_fixture"
			;;
		bad-cache)
			mkdir -p "$distfiles_dir"
			printf 'corrupt cache\n' > "$distfiles_dir/$bundle.tar.xz"
			;;
		bad-xz|bad-tar|missing-executable)
			case "$1" in
				bad-xz)
					printf 'not xz\n' > "$archive_fixture"
					;;
				bad-tar)
					printf 'not tar\n' | xz -c > "$archive_fixture"
					;;
				missing-executable)
					chmod -x "$case_dir/source/$bundle/zig"
					tar -cf "$case_dir/bundle.tar" \
						-C "$case_dir/source" "$bundle"
					xz -c "$case_dir/bundle.tar" > "$archive_fixture"
					;;
			esac
			digest=$(openssl dgst -sha256 "$archive_fixture")
			jq --arg digest "${digest##* }" \
				'.["0.10.0"]["x86_64-linux"].shasum = $digest' \
				"$index_fixture" > "$case_dir/new-index.json"
			mv "$case_dir/new-index.json" "$index_fixture"
			;;
		dependency) missing_tool=jq; package_status=1;;
		package) prefer_binary_package=1; package_status=1;;
		*) fail "unknown failure case: $1";;
	esac
	if install_tools_zig > "$case_dir/output" \
		2> "$case_dir/stderr"; then
		fail "$1 unexpectedly succeeded"
	fi
	assert_equal "$(cat "$case_dir/errors")" error
	[ ! -L "$local_dir/bin/zig" ] || fail "$1 installed a Zig symlink"
	case "$1" in
		archive-download|bad-checksum|bad-cache)
			[ ! -f "$distfiles_dir/$bundle.tar.xz" ] || \
				fail "$1 left an invalid cached archive"
			;;
	esac
	for leftover in "$distfiles_dir"/zig.*; do
		[ ! -d "$leftover" ] || fail "$1 left a temporary directory"
	done
)

test_xz_dependency() (
	setup "xz-$1-$2"
	os=$1
	distribution=$2
	processor=x86_64
	missing_tool=xz
	make_fixture "x86_64-$3"
	install_distribution_zig || fail 'xz dependency installation failed'
	assert_equal "$(cat "$case_dir/packages")" "$4"
)

test_existing_zig
printf 'PASS: existing Zig is preserved\n'
test_cached_archive
printf 'PASS: valid cached archive is reused\n'

for failure in unsupported-os unsupported-package-os unsupported-arch \
	invalid-index index-download archive-download \
	bad-checksum bad-cache \
	bad-xz bad-tar missing-executable dependency package; do
	test_failure "$failure"
	printf 'PASS: %s failure is reported safely\n' "$failure"
done

while read -r platform distro target package; do
	test_xz_dependency "$platform" "$distro" "$target" "$package"
	printf 'PASS: %s/%s xz dependency -> %s\n' \
		"$platform" "$distro" "$package"
done <<-EOF
	Linux Debian linux xz-utils
	Linux Devuan linux xz-utils
	Linux Ubuntu linux xz-utils
	Linux Alpine linux xz
	Linux Arch linux xz
	Linux CentOS linux xz
	Darwin unused macos xz
	FreeBSD unused freebsd xz
	OpenBSD unused openbsd xz
	NetBSD unused netbsd xz
EOF

test_destination_conflict() (
	setup "destination-$1"
	make_fixture x86_64-linux
	mkdir -p "$local_dir/bin"
	if [ "$1" = directory ]; then
		mkdir "$local_dir/bin/zig"
	else
		mkdir "$case_dir/existing-directory"
		ln -s "$case_dir/existing-directory" "$local_dir/bin/zig"
	fi
	if install_tools_zig > "$case_dir/output" \
		2> "$case_dir/stderr"; then
		fail "$1 destination conflict unexpectedly succeeded"
	fi
	assert_equal "$(cat "$case_dir/errors")" error
	[ -d "$local_dir/bin/zig" ] || fail 'destination was removed'
	[ ! -L "$local_dir/bin/zig/zig" ] || \
		fail 'Zig link was created inside the existing directory'
)

for destination in directory directory-symlink; do
	test_destination_conflict "$destination"
	printf 'PASS: %s destination is rejected\n' "$destination"
done
