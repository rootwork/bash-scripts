#!/usr/bin/env bash
# shellcheck disable=all
#
# This pattern accomplishes two things:
# - First, and perhaps most importantly, it ensures that when you call a program
#   you do so using the full relative path on your system. For example, when you
#   run "ffmpeg" you're really running "/usr/bin/ffmpeg" (or wherever you have
#   it installed on your system). If you're curious why this pattern uses
#   `command -v` and not `which`, see:
#   https://stackoverflow.com/a/677212
#   https://manpages.ubuntu.com/manpages/trusty/en/man1/command.1posix.html

# Dependencies
dependency=$(command -v dependency)
if [[ ! $dependency ]]; then
  error_exit "DEPENDENCY must be installed <URL>. Aborting."
fi
