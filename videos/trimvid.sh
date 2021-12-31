#!/bin/bash

# ---------------------------------------------------------------------------
# trimvid - Trim MP4 videos with a starting timecode and (optionally) a duration
# or stop timecode.
#
# See ffmpeg's documentation for details on the duration and timecode formats
# that can be passed:
# <https://ffmpeg.org/ffmpeg-utils.html#time-duration-syntax>
#
# This script requires ffmpeg to be installed: https://ffmpeg.org

# Copyright 2021, Ivan Boothe <git@rootwork.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License at <http://www.gnu.org/licenses/> for
# more details.

# USAGE
#
# $ ./trimvid.sh <FILE> <START> [END] [OUTPUT-FILE]

# EXAMPLES
#
# START format is HH:MM:SS.
#
# END is optional. If no value is provided, it trims from the start timecode to
# the end of the video. If a value is provided, it can be either a decimal
# number (in seconds), in which case it acts as a duration, OR a timecode in the
# form of HH:MM:SS, in which case it acts as a stop position.
#
# OUTPUT-FILE is optional. If no value is provided, it creates a video with
# "-trim" appended to the original filename.
#
# Trim video.mp4 beginning at 1 minute, 29 seconds to the end of the video:
# $ ./trimvid.sh video.mp4 00:01:29
#
# Trim video.mp4 beginning at 1 minute, 29 seconds and lasting for 90 seconds
# (one and a half minutes):
# $ ./trimvid.sh video.mp4 00:01:29 90
#
# Trim video.mp4 beginning at 1 minute, 29 seconds and ending at 1 hour, 52
# minutes, 56 seconds; name the video "final.mp4":
# $ ./trimvid.sh video.mp4 00:01:29 01:52:56 final.mp4

# Revision history:
# 2021-12-30  Adding output filename option (1.3)
# 2021-11-29  Updating license (1.2)
# 2021-10-15  Adding help, dependency checks, and other standardization (1.1)
# 2021-10-11  Initial release (1.0)
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.3"
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
    "${bold}Usage:${reset} ${PROGNAME} <FILE> <START> [END] [OUTPUT-FILE]"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Trim MP4 videos with a starting timecode and (optionally) a duration or stop
timecode.${reset}

$(usage)

${bold}Options:${reset}
-h, --help    Display this help message and exit.

${bold}Example:${reset}

START format is HH:MM:SS.

END is optional. If no value is provided, it trims from the start timecode to
the end of the video. If a value is provided, it can be either a decimal number
(in seconds), in which case it acts as a duration, OR a timecode in the form of
HH:MM:SS, in which case it acts as a stop position.

OUTPUT-FILE is optional. If no value is provided, it creates a video with
"-trim" appended to the original filename.

Trim video.mp4 beginning at 1 minute, 29 seconds to the end of the video:

${green}$ ${PROGNAME} video.mp4 00:01:29${reset}

Trim video.mp4 beginning at 1 minute, 29 seconds and lasting for 90 seconds (one
and a half minutes):

${green}$ ${PROGNAME} video.mp4 00:01:29 90${reset}

Trim video.mp4 beginning at 1 minute, 29 seconds and ending at 1 hour, 52
minutes, 56 seconds; name the video "final.mp4":

${green}$ ${PROGNAME} video.mp4 00:01:29 01:52:56 final.mp4${reset}

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
start=$2
end=$3
output=$4
if [[ ! $file ]]; then
  usage >&2
  error_exit "Input filename must be provided."
fi
if [[ ! $start ]]; then
  usage >&2
  error_exit "Start timecode must be provided."
fi
if [[ ! $output ]]; then
  output="${name}-trim.${ext}"
fi

# Dependencies
ffmpeg=$(command -v ffmpeg)
if [[ ! $ffmpeg ]]; then
  error_exit "Ffmpeg must be installed <https://ffmpeg.org>. Aborting."
fi
ffprobe=$(command -v ffprobe)
if [[ ! $ffprobe ]]; then
  error_exit "Ffprobe must be available and does not appear to be. Try reinstalling ffmpeg <https://ffmpeg.org>. Aborting."
fi

# Determine length of video (decimal, in seconds)
vidlength=$("$ffprobe" -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$file")

if [ "$end" ]; then
  if [ -z "${end##*:*}" ]; then # end is a timecode
    end=$(echo "$end" | awk -F':' '{print $1 * 60 * 60 + $2 * 60 + $3}')
    start=$(echo "$start" | awk -F':' '{print $1 * 60 * 60 + $2 * 60 + $3}')
    end=$(echo "$end - $start" | bc) # provide end as duration
  else                               # end is already a duration
    end=$end
  fi
else
  end=$vidlength
fi

if [ -f "${file}" ]; then # Make sure video file exists
  "$ffmpeg" -v quiet -stats -ss "$start" -i "$file" -t "$end" -c copy -map_metadata -1 -map_chapters -1 "$output"

  printf "%s\n" "${green}Video trimmed. File: ${reset}${bold}${output}"
else
  error_exit "Video file '${file}' not found."
fi
