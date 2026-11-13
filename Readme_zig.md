# Dotfiles for development environment for Zig Programming Language

Invoke `dotfiles_install_tools.sh` with `-s zig` to install
[Zig](https://ziglang.org/):

    ./dotfiles_install_tools.sh -s zig

The installer supports Linux, macOS, FreeBSD, OpenBSD, and NetBSD.
By default, it selects the latest stable release from Zig's official
[download index](https://ziglang.org/download/index.json), detects the
host's CPU architecture, and verifies the archive's SHA-256 checksum
before extraction.  Development builds are not selected.

The complete distribution, including Zig's standard library, is kept
under `~/.local`.  A symbolic link at `~/.local/bin/zig` makes it
available through the PATH configured by this project's dotfiles.
If necessary, add `~/.local/bin` to your PATH and restart your shell.
Archives are cached under `~/.dotfiles.d/distfiles`; failed downloads
are not cached, and archives with invalid checksums are removed.

The installer installs `jq`, OpenSSL, `tar`, and `xz` through the
platform's package manager if needed.  It uses `xz` separately from
`tar` so that extraction does not depend on GNU tar extensions.
If the latest release has no binary for your architecture, installation
fails with a diagnostic rather than downloading another platform's
binary.

To use the platform's native Zig package instead, specify `-b`:

    ./dotfiles_install_tools.sh -b -s zig

This uses Homebrew on macOS, `pkg` on FreeBSD, `pkg_add` on OpenBSD,
`pkgin` or `pkg_add` on NetBSD, and the detected Linux package manager.
On Alpine Linux, the community repository is enabled first.  Package
versions and availability depend on the configured repositories;
not every Linux distribution provides a Zig package.

An existing `zig` executable on PATH is left unchanged.

## Emacs configuration

Link the Zig configuration into your home directory:

    ./dotfiles_link_files.sh -s zig

This links `sets/zig/.emacs.d/init.d/zig.el`, which installs
[`zig-mode`](https://github.com/ziglang/zig-mode) through `use-package`.
Files ending in `.zig` or `.zon` use Zig syntax highlighting and
indentation.  The mode also provides build, run, and test commands.

By default, `zig-mode` formats buffers on save with `zig fmt`.
The Zig executable must be available on Emacs' PATH.  To disable
automatic formatting, customize `zig-format-on-save` to `nil`.

## Tests

With `jq`, OpenSSL, `tar`, and `xz` installed, run:

    sh tests/test_zig.sh

These offline tests exercise platform and architecture detection,
archive extraction, checksum validation, caching, and package selection.
They simulate foreign hosts; native execution on each OS is a separate
validation step.

With `use-package`, `zig-mode`, and its dependencies installed in Emacs,
run the configuration tests:

    emacs -Q --batch -l tests/test_zig_emacs.el \
        -f ert-run-tests-batch-and-exit

The formatting test requires `zig` on PATH; it is skipped otherwise.

- - -

Copyright &copy; 2026 Upperstream.
