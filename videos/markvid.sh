#!/bin/bash

# ---------------------------------------------------------------------------
# markvid - Add a watermark image to a video. You do not need to know the
# dimensions of the video or the watermark image, just how far from the
# lower-right corner you want the watermark to be. A new video will be output
# with "-marked" appended to the file name.
#
# This is barely more than an alias, but is a lot easier than remembering all
# the configuration parameters.
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
# $ ./markvid.sh <VIDEOFILE> <WATERMARKFILE> <PIXELDIST>
# $ ./markvid.sh [-h|--help]

# EXAMPLES
#
# Run the script with a path to the video, a path to the watermark file, and the
# distance (in pixels) you want the watermark to appear from the lower-right
# corner.
#
#   $ ./markvid.sh video.mp4 watermark.png 10
#   > [ffmpeg reports conversion progress]
#   > Done. Video created at video-marked.mp4

# RESOURCES
#
# https://gist.github.com/bennylope/d5d6029fb63648582fed2367ae23cfd6
# https://ffmpeg.org/ffmpeg-filters.html#overlay-1

# Revision history:
# 2021-10-15  Adding help, dependency checks, and other standardization (1.1)
# 2021-10-06  Initial release (1.0)
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
    "${bold}Usage:${reset} ${PROGNAME} <VIDEOFILE> <WATERMARKFILE> <PIXELDIST>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Add a watermark image to a video. You do not need to know the dimensions of the
video or the watermark image, just how far from the lower-right corner you want
the watermark to be. A new video will be output with "-marked" appended to the
file name.

This is barely more than an alias, but is a lot easier than remembering all the
configuration parameters.${reset}

$(usage)

${bold}Examples:${reset}

Run the script with a path to the video, a path to the watermark file, and the
distance (in pixels) you want the watermark to appear from the lower-right
corner.

${green}$ ./markvid.sh video.mp4 watermark.png 10${reset}
> [ffmpeg reports conversion progress]
> Done. Video created at video-marked.mp4

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
wm=$2
dist=$3
if [[ ! $file ]]; then
  usage >&2
  error_exit "Video filename must be provided."
fi
if [[ ! $wm ]]; then
  usage >&2
  error_exit "Watermark filename must be provided."
fi
if [[ ! $dist ]]; then
  usage >&2
  error_exit "Distance (in pixels) must be provided."
fi

# Dependencies
ffmpeg=$(command -v ffmpeg)
if [[ ! $ffmpeg ]]; then
  error_exit "Ffmpeg must be installed <https://ffmpeg.org>. Aborting."
fi

if [ -f "${file}" ]; then # Make sure video file exists
  if [ -f "${wm}" ]; then # Make sure watermark file exists
    "$ffmpeg" -v quiet -stats -i "$file" -i "$wm" -filter_complex "overlay=main_w-overlay_w-${dist}:main_h-overlay_h-${dist}" "${name}"-marked."${ext}"
    printf "%s\n" "${green}Done. Video created at: ${reset}${bold}${name}-marked.${ext}${reset}"
  else
    error_exit "Watermark file '${wm}' not found."
  fi
else
  error_exit "Video file '${file}' not found."
fi
