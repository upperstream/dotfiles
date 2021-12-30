# Dotfiles for development environment with Docker

Invoking `dotfiles_install_tools.sh` and `dotfiles_link_files.sh` with
`-s docker` option installs tools and configuration files for
development environment with [Docker](https://www.docker.com/) as
well as the following tools:

* [Docker Compose](https://docs.docker.com/compose/)
* [docker.el](https://github.com/Silex/docker.el) - [Emacs][]
  integration for Docker
* [dockerfile-mode](https://github.com/spotify/dockerfile-mode) -
  Dockerfile mode for Emacs
* [docker-compose-mode](https://github.com/meqif/docker-compose-mode) -
  Major mode for editing docker-compose files
* [docker-tramp](https://github.com/emacs-pe/docker-tramp.el) - TRAMP
  integration for docker containers

Using `--docker-daemon-disabled` option for `dotfiles_install_tools.sh`
installs Docker but its daemon is disabled.

[Emacs]: https://www.gnu.org/software/emacs/

- - -

Copyright &copy; 2021 Upperstream Software.
