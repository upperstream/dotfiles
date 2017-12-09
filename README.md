# Dotfiles

## Install tools

The following command installs some tools for your convenience.

    sudo ./dotfiles_install_tools.sh

or

    doas ./dotfiles_install_tools.sh

Please note that you need the root privilege to run the script in order to perform actual installation.

Tools to be installed are:

* [Micro][] editor
* [EditorConfig Core C][]

At the time of writing this, the script only supports [macOS][] and [OpenBSD][].

[EditorConfig Core C]: https://github.com/editorconfig/editorconfig-core-c
[macOS]: https://www.apple.com/lae/macos/high-sierra/ "macOS High Sierra - Apple"
[Micro]: https://micro-editor.github.io/ "Micro - Home"
[OpenBSD]: https://www.openbsd.org/ "OpenBSD"


## Create symbolic links to dotfiles

The following command creates symbolic links in your home directory.  These links point to files in `home` directory.

    ./dotfiles_link_files.sh

Add `-b` option to back up files to be replaced.  Backup files will be created in your `~/.dotfiles.d/backups/YYYYmmdd'T'HHMMSS` directory.
Run the script with `-n` option does nothing but merely prints what will be done.
Execute `./dotfiles_link_files -H` to learn more options.


## Licensing

Files in this project are provided under the [ISC License][].
See [LICENSE.txt](LICENSE.txt) file for details.

[ISC License]: http://www.isc.org/downloads/software-support-policy/isc-license
