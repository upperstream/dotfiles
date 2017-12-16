# Dotfiles

Initial setup for tools and dot config files.


## Install tools

The following command installs some tools for your convenience.

    ./dotfiles_install_tools.sh

Please note that you should not invoke the script with the root
privilege.  The script automatically asks for the root privilege when
necessary.

Tools to be installed are:

* [cdiff][]
* [dirstack][]
* [EditorConfig Core C][]
* [Lynx][]
* [Markdown][]
* [Micro][] editor
* GNU [nano][] editor


At the time of writing this, the script only supports [macOS][],
[NetBSD][] and [OpenBSD][].

[cdiff]: https://github.com/ymattw/cdiff
    "ymattw/cdiff: View colored, incremental diff in workspace or from stdin with side by side and auto pager support"
[dirstack]: https://bitbucket.org/upperstream/dirstack
    "upperstream / dirstack   &mdash; Bitbucket"
[EditorConfig Core C]:
    https://github.com/editorconfig/editorconfig-core-c
[Lynx]: http://lynx.invisible-island.net/
    "LYNX &ndash; The Text Web-Browser"
[macOS]: https://www.apple.com/lae/macos/high-sierra/
    "macOS High Sierra - Apple"
[Markdown]: https://daringfireball.net/projects/markdown/
    "Daring Fireball: Markdown"
[Micro]: https://micro-editor.github.io/ "Micro - Home"
[nano]: https://www.nano-editor.org/ "GNU nano"
[NetBSD]: https://www.netbsd.org/ "The NetBSD Project"
[OpenBSD]: https://www.openbsd.org/ "OpenBSD"


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
