#!/usr/bin/env -S just --justfile
# ^ A shebang isn't required, but allows a justfile to be executed
#   like a sript, with `./justfile install`, for example.

set shell := ["bash", "-c"]

os := os()

install:
  ./install.sh {{os}}

apply:
  chezmoi apply --source .

diff:
  chezmoi diff --source .
