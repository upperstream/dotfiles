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

* [abduco][] or [dtach][]
* [cdiff][]
* [dirstack][]
* [dvtm][]
* [EditorConfig Core C][]
* [Lynx][]
* [Markdown][]
* [mg][]
* [Micro][] editor
* GNU [nano][] editor

Tools for X Window System to be installed are:

* [XSel][] or [xclip][]

At the time of writing this, the script supports [FreeBSD][],
[macOS][], [NetBSD][] and [OpenBSD][].

[abduco]: http://www.brain-dump.org/projects/abduco/
    "abduco || a tool for session [at|de]tach support"
[cdiff]: https://github.com/ymattw/cdiff
    "ymattw/cdiff: View colored, incremental diff in workspace or from stdin with side by side and auto pager support"
[dirstack]: https://bitbucket.org/upperstream/dirstack
    "upperstream / dirstack   &mdash; Bitbucket"
[dtach]: http://dtach.sourceforge.net/ "dtach"
[dvtm]: http://www.brain-dump.org/projects/dvtm/
    "dvtm || dynamic virtual terminal manager"
[EditorConfig Core C]:
    https://github.com/editorconfig/editorconfig-core-c
[FreeBSD]: https://www.freebsd.org/ "The FreeBSD Project"
[Lynx]: http://lynx.invisible-island.net/
    "LYNX &ndash; The Text Web-Browser"
[macOS]: https://www.apple.com/lae/macos/high-sierra/
    "macOS High Sierra - Apple"
[Markdown]: https://daringfireball.net/projects/markdown/
    "Daring Fireball: Markdown"
[mg]: https://homepage.boetes.org/software/mg/
[Micro]: https://micro-editor.github.io/ "Micro - Home"
[nano]: https://www.nano-editor.org/ "GNU nano"
[NetBSD]: https://www.netbsd.org/ "The NetBSD Project"
[OpenBSD]: https://www.openbsd.org/ "OpenBSD"
[xclip]: https://github.com/astrand/xclip
    "astrand/xclip: Command line interface to the X11 clipboard"
[XSel]: http://www.kfish.org/software/xsel/ "XSel by Conrad Parker"


## Create symbolic links to dotfiles

The following command creates symbolic links in your home directory.
These links point to files in `home` directory.

    ./dotfiles_link_files.sh

Add `-b` option to back up files to be replaced.  Backup files will be
created in your `~/.dotfiles.d/backups/YYYYmmdd'T'HHMMSS` directory.
Run the script with `-n` option does nothing but merely prints what
will be done.
Execute `./dotfiles_link_files -H` to learn more options.


## Licensing

Files in this project are provided under the [ISC License][].
See [LICENSE.txt](LICENSE.txt) file for details.

[ISC License]:
    http://www.isc.org/downloads/software-support-policy/isc-license

- - -

Copyright &copy; 2017 Upperstream Software.
