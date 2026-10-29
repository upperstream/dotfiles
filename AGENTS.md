# Agent guidance

This repository contains personal dotfiles and shell scripts for setting
up command-line tools and development environments on Unix-like systems.
Use [README.md](README.md) for usage and supported platforms.

## Repository layout

* `home/` contains the base dotfiles linked into the user's home
  directory, including shell startup files and editor configuration.
* `sets/` contains optional development-tool configuration.  Files named
  `<set>.dependencies` declare other sets needed when linking files.
* `dotfiles_link_files.sh` creates symbolic links for the base dotfiles
  and selected sets.  It supports dry-run and backup options.
* `dotfiles_install_tools.sh` installs common tools and loads optional
  `dotfiles_install_tools_<set>.sh` modules.
* `Readme_<set>.md` files describe individual development-tool sets.
* `.agents/skills/` contains task-specific instructions for agents.

## Working conventions

Keep changes focused on the requested task.  Preserve unrelated staged,
unstaged, and untracked files; do not stage or commit without a request.

Follow `.editorconfig` and the surrounding file's style.  Keep scripts
using `#!/bin/sh` portable across the supported systems; do not
introduce Bash-only syntax or assume GNU utilities are available.  Keep
shell-specific behaviour in the appropriate startup file.

When changing a tool set, check its installer module, configuration,
dependency file, and corresponding readme for related changes.  Do not
assume every set has all of these files.

Read and follow the relevant local skills:

* Use [document standards][docs] when writing documentation.
* Use [commit attribution][attribution] when making a commit.
  Attribution belongs in the commit message, not in source files or
  documentation.  Follow the skill's exception for Hermes Agent.

## Validation and safety

Run syntax checks for changed shell scripts with the intended shell.
For scripts using `#!/bin/sh`, use `sh -n <script>`; use `bash -n` for
Bash-specific startup files.  Syntax checks do not verify runtime
behaviour or portability across operating systems.

Preview link changes with `sh ./dotfiles_link_files.sh -n` from the
repository root.  For runtime checks, use an isolated destination rather
than the real home directory.  Do not run installers as a routine test:
they can download software, install packages, and change system
settings.
Do not invoke the installer as root; it requests privileges when needed.

Review the final diff and run `git diff --check`.  For untracked files,
check their contents separately because they are absent from that diff.
Report which checks ran and any platform-specific checks not performed.

## Before committing

Before making any commit, review the intended changes and update
relevant documentation so that it is in line with those changes.  Leave
unaffected documentation unchanged.

If the project has a changelog, update it automatically for every commit
to describe the changes, following its existing format and conventions.
If no changelog exists, do not create one unless explicitly instructed.

Verify that relevant documentation updates and the update to any
existing changelog are included in the commit, and that unrelated
changes are not.  Keep commit-message attribution separate.

[docs]: .agents/skills/document-standards/SKILL.md
[attribution]: .agents/skills/vcs-commit-message-attribution/SKILL.md
