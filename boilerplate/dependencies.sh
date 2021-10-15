#!/bin/bash
# shellcheck disable=all
#
# Dependencies.
#
# Sources:
#
# https://stackoverflow.com/a/677212

# Dependencies
dependency=$(command -v dependency)
if [[ ! $dependency ]]; then
  error_exit "DEPENDENCY must be installed <URL>. Aborting."
fi
