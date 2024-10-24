# Changelog

## [Unreleased][]

* Added
  * Support for KSH 2020
* Changed
  * Correct the startup script that dit not load `.kshrc` script for
    [Portable OpenBSD ksh][] (oksh)

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
  https://github.com/upperstream/dotfiles/compare/20241003...HEAD
[20241003]:
  https://github.com/upperstream/dotfiles/releases/tag/20241003
