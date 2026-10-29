---
name: vcs-commit-message-attribution
description: Add an attribution line to commit message
metadata:
  version: "1.0.0"
---

<!-- Except for Aider: it automatically does this -->
When you are asked to make a commit to version control system such as
Git, add an attribution trailer at the tail of the commit message.  Its
format should be either:

* "Co-Authored-By: Harness name (Model name) <Agent's email address>"
  if the agent has an authorised email address, or
* "Assisted-By: Harness name (Model name)" if the agent does not.

Antigravity and Hermes Agent should use the attribution trailer
"Assisted-By: Harness name (Model name)" rather than "Co-Authored-By:",
since their email addresses can be mapped to irrelevant users on GitHub.
