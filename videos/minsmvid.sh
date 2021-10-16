#!/bin/bash

# ---------------------------------------------------------------------------
# minsmvid - Reduce video size even more than minvid, with second argument for
# bitrate, in KB. A value of 2600 might be a helpful starting point.
#
# This script requires ffmpeg to be installed: https://ffmpeg.org

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
# $ ./minsmvid.sh <FILE> <BITRATE>

# Revision history:
# 2021-10-15  Adding help, dependency checks, and other standardization (1.1)
# 2021-10-11  Initial release (1.0)
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.1"
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
    "${bold}Usage:${reset} ${PROGNAME} <FILE> <BITRATE>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Reduce video size even more than minvid, with second argument for bitrate, in
KB. A value of 2600 might be a helpful starting point.${reset}

$(usage)

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
name="${1%.*}"
ext="${1##*.}"
bitrate=$2
if [[ ! $file ]]; then
  usage >&2
  error_exit "Filename must be provided."
fi
if [[ ! $bitrate ]]; then
  usage >&2
  error_exit "Bitrate must be provided."
fi

# Dependencies
ffmpeg=$(command -v ffmpeg)
if [[ ! $ffmpeg ]]; then
  error_exit "Ffmpeg must be installed <https://ffmpeg.org>. Aborting."
fi

if [ -f "${file}" ]; then # Make sure video file exists
  printf "%s\n" "${green}Running first of two passes.${reset}"
  "$ffmpeg" -v quiet -stats -y -i "$file" -tune film -preset slower -map_metadata -1 -map_chapters -1 -c:v libx264 -b:v "$bitrate"k -pass 1 -vsync cfr -f null /dev/null &&
    printf "%s\n" "${green}Running second of two passes.${reset}"
  "$ffmpeg" -v quiet -stats -i "$file" -c:v libx264 -b:v "$bitrate"k -pass 2 -c:a aac -b:a 128k -movflags +faststart "$name"-minsm."$ext"
  rm ffmpeg2pass-0.log.mbtree && rm ffmpeg2pass-0.log
  printf "%s\n" "${green}Video minified. File: ${reset}${bold}${name}-minsm.${ext}${reset}${reset}"
else
  error_exit "Video file '${file}' not found."
fi
