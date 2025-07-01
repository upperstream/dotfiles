# Changelog

## [Unreleased][]

* Added
  * Add support for [Policy-compliant Ordinary SHell] (posh)

[Policy-compliant Ordinary SHell]: https://salsa.debian.org/clint/posh

## [20250614][]

* Changed
  * Correct a syntax error in PS1 for OpenBSD ksh
  * Make directory part brighter in PS1 for bash and ksh

## [20241024][]

* Added
  * Support for KSH 2020
* Changed
  * Correct the startup script that dit not load `.kshrc` script for
    [Portable OpenBSD ksh][] (oksh)
  * Stop using `MANPATH` environment variable and let the system
    determine the user's manual search path
  * Let [nano][] use the [classical keybind](https://lists.gnu.org/archive/html/info-gnu/2024-05/msg00000.html)

[nano]: https://www.nano-editor.org/ "nano &ndash; Text editor"
[Portable OpenBSD ksh]: https://github.com/ibara/oksh
  "ibara/oksh: Portable OpenBSD ksh, based on the Public Domain Korn Shell (pdksh)."

## [20241003][]

* Added
  * Add the change log file (this file) to the project
* Changed
  * Replace Cdiff (former name of [Ydiff][]) with [delta][] in order to
    reduce the dependency on Python

[delta]: https://dandavison.github.io/delta/ "Introduction - delta"
[Ydiff]: https://github.com/ymattw/ydiff
   "GitHub - ymattw/ydiff: View colored, incremental diff in workspace or from stdin with side by side and auto pager support"

[Unreleased]:
  https://github.com/upperstream/dotfiles/compare/20250614...HEAD
[20250614]:
  https://github.com/upperstream/dotfiles/compare/20241024...20250614
[20241024]:
  https://github.com/upperstream/dotfiles/compare/20241003...20241024
[20241003]:
  https://github.com/upperstream/dotfiles/releases/tag/20241003
