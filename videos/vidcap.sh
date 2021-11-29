#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# vidcap - Create screencaps of a video, that is, individual images from
# different time codes of the video. (Not to be confused with video captioning.)
#
# This script requires the following software to be installed:
# - ffmpeg: https://ffmpeg.org
# - Imagemagick, which you likely already have: https://imagemagick.org

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
# $ ./vidcap.sh [-x|--index] [-q|quiet] <FILE> [INT (number of screencaps; default 1)]
# $ ./vidcap.sh [-h|--help]

# EXAMPLES
#
# Create one screencap, from the middle of the video (by time code):
# $ ./vidcap.sh avi1.avi
#
# Create five screencaps, evenly spaced across the video (by time code):
# $ ./vidcap.sh avi1.avi 5

# Create ten screencaps, evenly spaced across the video (by time code), plus an
# index image combining all of the screencaps:
# $ ./vidcap.sh -x mp41.mp4 10

# Create ONLY an index image combining twelve screencaps, evenly spaced across
# the video (by time code), and don't return anything to the console but errors.
# $ ./vidcap.sh -o -q mp41.mp4 12

# RESOURCES
#
# Based on prior art from these sources:
# https://blog.roberthallam.org/2018/04/quick-hacks-a-script-to-extract-a-single-image-frame-from-video/
# https://fdalvi.github.io/blog/2018-09-01-creating-video-screencaps/
# https://github.com/fdalvi/video-screencaps/blob/master/create_screenshots.sh

# Revision history:
# 2021-11-29  Added check for sufficient number of screencaps when creating
#             index (1.1)
# 2021-11-28  Initial release (1.0)
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.1"

# Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
bold=$(tput bold)
reset=$(tput sgr0)

# Error handling
error_exit() {
  local error_message="${red}$1${reset}"

  printf "%s\n" "${PROGNAME}: ${error_message:-"${red}Unknown Error${reset}"}" >&2
  exit 1
}
# Use as following:
# command || error_exit "command failed in line $LINENO"

graceful_exit() {
  rm -f "${name}_"*.jpg
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
    "${bold}Usage:${reset} ${PROGNAME} [-x|--index] [-o|--onlyindex] [-q|--quiet] <FILE> [INT (number of screencaps; default 1)]"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Create screencaps of a video, that is, individual images from different time
codes of the video. (Not to be confused with video captioning.)${reset}

$(usage)

${bold}Options:${reset}
-x, --index       Create an index image combining all of the screencaps.
-o, --onlyindex   Create ONLY an index image; do not save individual screencaps.
-q, --quiet       Quiet mode.
-h, --help        Display this help message and exit.

_EOF_
}

# Options and flags from command line
needs_arg() {
  if [ -z "$OPTARG" ]; then
    error_exit "Error: Argument required for option '$OPT' but none provided."
  fi
}
while getopts :xo-:qh OPT; do
  # Using help flag only? The above should be:
  # while getopts :-:h OPT; do
  if [ "$OPT" = "-" ]; then # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"     # extract long option name
    OPTARG="${OPTARG#$OPT}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"    # remove assigning `=`
  else
    OPTARG="${OPTARG#=}" # if short option, just remove assigning `=`
  fi
  case "$OPT" in
    h | help)
      help_message
      graceful_exit
      ;;
    q | quiet)
      quiet_mode=true
      ;;
    x | index)
      index=true
      ;;
    o | onlyindex)
      index=true
      onlyindex=true
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

# Sanitize directory name
path=$1
[[ "$path" =~ ^[./].*$ ]] || path="./$path"

# Dissect and examine filename
file=$1
name="${1%.*}"
if [[ ! $file ]]; then
  usage >&2
  error_exit "Filename must be provided."
fi
number_of_screenshots=$2
if [[ ! $number_of_screenshots ]]; then
  number_of_screenshots=1
fi

# Dependencies
ffmpeg=$(command -v ffmpeg)
if [[ ! $ffmpeg ]]; then
  error_exit "Ffmpeg must be installed <https://ffmpeg.org>. Aborting."
fi
montage=$(command -v montage)
if [[ ! $montage ]]; then
  error_exit "Imagemagick must be installed <https://imagemagick.org>. Aborting."
fi

# Determining time codes
duration=$(ffprobe -show_streams "${file}" 2>&1 | grep "^duration=" | cut -d'=' -f2 | head -1)
if [[ ! $quiet_mode ]]; then
  printf "%s\n" "${cyan}Video is ${duration} seconds long.${reset}"
fi

# Take screencap
if [ $number_of_screenshots -eq 1 ]; then
  # One screencap only
  ss=$(echo "${duration}/2" | bc)
  if [[ ! $quiet_mode ]]; then
    printf "%s\n" "${green}Capturing screencap at ${ss}s...${reset}"
    echo "ffmpeg -v quiet -ss \"${ss}\" -i \"${file}\" -vframes 1 -f image2 \"${name}.jpg\""
  fi
  "$ffmpeg" -v quiet -ss "${ss}" -i "${file}" -vframes 1 -f image2 "${name}.jpg"
else
  # Multiple screencaps
  seek_factor=$(echo "scale=5; ($duration-0.1)/($number_of_screenshots-1)" | bc)
  if [[ ! $quiet_mode ]]; then
    printf "%s\n" "${green}Capturing frame every ${seek_factor} seconds...${reset}"
  fi
  for ss_idx in $(seq 0 $((number_of_screenshots - 1))); do
    ss=$(echo "${ss_idx} * ${seek_factor}" | bc)
    if [ "$ss_idx" -lt 9 ]; then
      tmp_idx=$(echo "${ss_idx} + 1" | bc)
      file_idx="0$tmp_idx"
    else
      file_idx=$(echo "${ss_idx} + 1" | bc)
    fi
    if [[ ! $quiet_mode ]]; then
      printf "%s\n" "${green}Capturing screencap at ${ss}s...${reset}"
    fi
    "$ffmpeg" -v quiet -ss "${ss}" -i "${file}" -vframes 1 -f image2 "${name}_${file_idx}.jpg"
  done
fi

# Create index file
if [[ $index ]]; then
  if [ $number_of_screenshots -eq 1 ]; then
    printf "%s\n" "${red}Creation of index requires at least two screencaps.${reset}"
    usage >&2
    error_exit "Insufficient screecaps for index."
  fi
  width=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 "${file}")
  halfwidth=$(echo "${width}/2" | bc)
  "$montage" -quiet "${name}_02.jpg" -tile 1x1 -border 2 -geometry "${width}"x+0+0 "${name}_top.jpg"
  "$montage" -quiet "${name}_"[0-9][0-1,3-9].jpg -tile 2x -border 2 -geometry "${halfwidth}"x+0+0 "${name}_caps.jpg"
  "$montage" -quiet "${name}_top.jpg" "${name}_caps.jpg" -tile 1x2 -geometry +0+0 "${name}.jpg"
  rm -f "${name}_top.jpg" "${name}_caps.jpg"
fi

# Remove individual caps
if [[ $onlyindex ]]; then
  rm -f "${name}_"[0-9][0-9].jpg
fi

if [[ ! $quiet_mode ]]; then
  printf "%s\n" "${cyan}Finished!${reset}"
fi
