#!/bin/bash

# ---------------------------------------------------------------------------
# convertvid - Convert any video files readable by ffmpeg (including but not
# limited to MP4, MPG, M4V, MOV, WEBM, WMV, AVI, 3GP) into modern H265-encoded
# MP4 file. This will generally be smaller in file size and more widely playable
# than other video formats.
#
# You can provide either a filename or a file type/extension (e.g. 'wmv') and it
# will convert all matching files.
#
# Converted videos will be output into a subdirectory named "converted", with
# each file having its original filename appended with .mp4
#
# This script requires ffmpeg to be installed: https://ffmpeg.org
#
# Background information:
#
# https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding
# https://ffmpeg.org/ffmpeg-formats.html#Demuxers
#
# Or run `ffmpeg -formats` at the command prompt to see all valid input formats.
# Note that video formats aren't necessarily the same thing as file extensions,
# but ffmpeg will determine the encoding based on the file contents, not the
# file extension itself.

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
# $ ./convertvid.sh <FILE|FILETYPE>
# $ ./convertvid.sh [-h|--help]

# EXAMPLES
#
# Provide either a filename or a file type/extension (e.g. 'wmv'). If a filename
# is provided, it will convert only that file. If a file type is provided, it
# will convert all matching files in the current directory.
#
# Converting one file named example.mpg:
#
#   $ ./convertvid.sh example.mpg
#
# Converting all WMV files in the current directory:
#
#   $ ./convertvid.sh wmv
#
# Note that providing '*' as a file format won't work; you'll need to provide
# file formats one at a time that exist in the current directory.

# INSPIRATION
#
# https://stackoverflow.com/a/33766147
# https://video.stackexchange.com/a/19862
# https://linuxconfig.org/how-to-use-ffmpeg-to-convert-multiple-media-files-at-once-on-linux

# Revision history:
# 2021-10-15  Adding help, dependency checks, and other standardization (1.2)
# 2021-10-12  Minor cleanup (1.1)
# 2021-06-29  Initial release (1.0)
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
    "${bold}Usage:${reset} ${PROGNAME} <FILE|FILETYPE>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Convert AVI videos to MP4 format. More thorough than ffmpeg's default process,
resulting in both smaller and better-quality videos.${reset}

$(usage)

${bold}Examples:${reset}

Provide either a filename or a file type/extension (e.g. 'wmv'). If a filename
is provided, it will convert only that file. If a file type is provided, it will
convert all matching files in the current directory.

Converting one file named example.mpg:

${green}$ ./convertvid.sh example.mpg${reset}

Converting all WMV files in the current directory:

${green}$ ./convertvid.sh wmv${reset}

Note that providing '*' as a file format won't work; you'll need to provide
file formats one at a time that exist in the current directory.

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
ffmpeg=$(command -v ffmpeg)
if [[ ! $ffmpeg ]]; then
  error_exit "Ffmpeg must be installed <https://ffmpeg.org>. Aborting."
fi

mkdir -p ./converted

# Input is a single file
if [ -f "${file}" ]; then
  printf "%s\n" "${green}Converting video...${reset}"
  file_converted=${file%.*}.mp4
  "$ffmpeg" -v quiet -stats -i "$file" -vcodec libx265 -crf 28 "./converted/${file_converted}"
  printf "%s\n" "${green}Video converted. File: ${reset}${bold}./converted/${file_converted}${reset}"
# Input is file extension
else
  printf "%s\n" "${green}Converting videos...${reset}"
  for f in *."${file}"; do
    "$ffmpeg" -v quiet -stats -i "$f" -vcodec libx265 -crf 28 "./converted/${f%.*}.mp4"
  done
  printf "%s\n" "${green}Videos converted. Files can be found in the ${reset}${bold}'converted'${reset}${green} subdirectory.${reset}"
fi
