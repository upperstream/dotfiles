# Dotfiles

Initial setup for tools and dot config files.


## Install tools

The following command installs some tools for your convenience:

    ./dotfiles_install_tools.sh

When an option `-x` is specified, additional tools for X Window System
will be installed as well.  Note that this may install X Window System
as a part of dependencies.
Execute `./dotfiles_link_files -H` to learn more options.

Please note that you should not invoke the script with the root
privilege.  The script automatically asks for the root privilege when
necessary.

Tools to be installed are:

* [abduco](http://www.brain-dump.org/projects/abduco/) or
  [dtach](http://dtach.sourceforge.net/)
* [cdiff](https://github.com/ymattw/cdiff)
* [dirstack](https://bitbucket.org/upperstream/dirstack)
* [dvtm](http://www.brain-dump.org/projects/dvtm/)
* [EditorConfig C Core](https://github.com/editorconfig/editorconfig-core-c)
* GNU [Emacs](https://www.gnu.org/software/emacs/) without window
  system support
* [Lynx](http://lynx.invisible-island.net/)
* [Markdown](https://daringfireball.net/projects/markdown/)
* [mg](https://homepage.boetes.org/software/mg/)
* [Micro](https://micro-editor.github.io/) editor
* GNU [nano](https://www.nano-editor.org/) editor

Tools for X Window System to be installed are:

* GNU Emacs with window system support
* [XSel](http://www.kfish.org/software/xsel/) or
  [xclip](https://github.com/astrand/xclip)

Additionally, the script can install the following sets of development
tools with a leading `-s` option:

* [`react_native`](Readme_react_native.md) - development environment
  with [React Native][] tools
* [`scala`](Readme_scala.md) - development environment with [Scala][]
  tools

At the time of writing this, the script supports [FreeBSD][],
[macOS][], [NetBSD][], [OpenBSD][], and the following [Linux][]
distributions:

* [Alpine Linux](https://alpinelinux.org/)
* [CentOS](https://www.centos.org/)
* [Debian](https://www.debian.org/)
* [Devuan GNU+Linux](https://devuan.org/)
* [Ubuntu](https://www.ubuntu.com/)


[FreeBSD]: https://www.freebsd.org/ "The FreeBSD Project"
[Linux]: https://www.kernel.org/ "The Linux Kernel Archives"
[macOS]: https://www.apple.com/lae/macos/high-sierra/
    "macOS High Sierra - Apple"
[NetBSD]: https://www.netbsd.org/ "The NetBSD Project"
[OpenBSD]: https://www.openbsd.org/ "OpenBSD"
[React Native]: https://facebook.github.io/react-native/
    "React Native &middot; A framework for building native apps using React"
[Scala]: https://www.scala-lang.org/ "The Scala Programming Language"


## Create symbolic links to dotfiles

The following command creates symbolic links in your home directory.
These links point to files in `home` directory.

    ./dotfiles_link_files.sh

Add `-b` option to back up files to be replaced.  Backup files will be
created in your `~/.dotfiles.d/backups/YYYYmmdd'T'HHMMSS` directory.
Executing the script with `-n` option does nothing but merely prints
what will be done.

This script supports `-s` option to set up symbolic links for
additional set of tools.  See the above description above for
`dotfiles_install_tools.sh` for details.

Execute `./dotfiles_link_files -H` to learn more options.


## Licensing

Files in this project are provided under the [ISC License][].
See [LICENSE.txt](LICENSE.txt) file for details.

[ISC License]:
    http://www.isc.org/downloads/software-support-policy/isc-license

- - -

Copyright &copy; 2017, 2018 Upperstream Software.
