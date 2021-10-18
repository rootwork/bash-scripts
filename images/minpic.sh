#!/bin/bash

# ---------------------------------------------------------------------------
# minpic - Minify JPEG and PNG images, losslessly, for the web.
#
# This script requires Trimage to be installed: https://trimage.org

# Copyright 2021, Ivan Boothe <git@rootwork.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# USAGE
#
# $ ./minpic.sh <FILE|FILEGLOB> <FILE2|FILEGLOB2> ...
# $ ./minpic.sh [-h|--help]

# EXAMPLES
#
# $ ./minpic.sh pic.jpg
# $ ./minpic.sh pic.jpg pic2.png
# $ ./minpic.sh *.jpg pic2.png

# Revision history:
# 2021-10-15  Adding checks for dependencies, filename (1.2)
# 2021-10-14  Minor cleanup and standardization (1.1)
# 2021-10-11  Initial release (1.0)
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.2"
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
bold=$(tput bold)
reset=$(tput sgr0)

# Error handling
error_exit() {
  local error_message="${red}$1${reset}"

  printf "%s\n" "${PROGNAME}: ${error_message:-"Unknown Error"}" >&2
  exit 1
}

graceful_exit() {
  exit 0
}

signal_exit() {
  local signal="$1"

  case "$signal" in
    INT)
      error_exit "${yellow}Program interrupted by user.${reset}"
      ;;
    TERM)
      printf "\n%s\n" "${red}$PROGNAME: Program terminated.${reset}" >&2
      graceful_exit
      ;;
    *)
      error_exit "${red}$PROGNAME: Terminating on unknown signal.${reset}"
      ;;
  esac
}

# Usage: Separate lines for mutually exclusive options.
usage() {
  printf "%s\n" \
    "${bold}Usage:${reset} ${PROGNAME} <FILE|FILEGLOB> <FILE2|FILEGLOB2> ..."
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Minify JPEG and PNG images, losslessly, for the web. Uses Trimage for
simplicity, which uses optipng, pngcrush, advpng and jpegoptim, depending on the
filetype.${reset}

$(usage)

${bold}Options:${reset}
-h, --help    Display this help message and exit.

_EOF_
}

# Options and flags from command line
while getopts :-:h OPT; do
  if [ "$OPT" = "-" ]; then
    OPT="${OPTARG%%=*}"     # extract long option name
    OPTARG="${OPTARG#$OPT}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"    # remove assigning `=`
  fi
  case "$OPT" in
    h | help)
      help_message
      graceful_exit
      ;;
    ??*) # bad long option
      usage >&2
      error_exit "Unknown option --$OPT"
      ;;
    ?) # bad short option
      usage >&2
      error_exit "Unknown option -$OPTARG"
      ;;
  esac
done
shift $((OPTIND - 1)) # remove parsed options and args from $@ list

# Program variables
file=$1
if [[ ! $file ]]; then
  usage >&2
  error_exit "Filename must be provided."
fi

# Dependencies
trimage=$(command -v trimage)
if [[ ! $trimage ]]; then
  error_exit "Trimage must be installed <https://trimage.org>. Aborting."
fi

printf "%s\n" "${green}Using Trimage to minify images...${reset}"

for i in "$@"; do
  if [ -f "${i}" ]; then # Make sure image file exists
    "$trimage" --quiet --file="$i"
    printf "%s\n" "${green}Image file '${i}' minified.${reset}"
  else
    error_exit "Image file '${i}' not found."
  fi
done
