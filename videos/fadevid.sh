#!/bin/bash

# ---------------------------------------------------------------------------
# fadevid - Add a fade-in and fade-out, both visually (from/to black) and
# audially (from/to silence) to a video clip. You do not need to know the length
# of the video. The script will ask you how long you want the fade to be, and
# output a new video with "-faded" appended to the file name.
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
# $ ./fadevid.sh [--time=S] <FILE>
# $ ./fadevid.sh [-h|--help]

# EXAMPLES
#
# Provide a filename, and when the script asks you how long the fade should
# last, respond with a number.
#
#   $ ./fadevid.sh example.mp4
#   > Video length is 122.029413 seconds. How long do you want each fade to last? (in seconds)
#   $ 5
#   > [ffmpeg reports conversion progress]
#   > Done. Video created at example-faded.mp4
#
# Or provide both the filename and the length of the fade, in seconds.
#
#   $ ./fadevid.sh --time=5 example.mp4
#   > [ffmpeg reports conversion progress]
#   > Done. Video created at example-faded.mp4

# RESOURCES
#
# https://blog.feurious.com/add-fade-in-and-fade-out-effects-with-ffmpeg
# https://video.stackexchange.com/q/28269

# Revision history:
# 2021-10-18  Adding time as a command-line option (1.2)
# 2021-10-15  Adding help, dependency checks, and other standardization (1.1)
# 2021-10-06  Initial release (1.0)
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
    "${bold}Usage:${reset} ${PROGNAME} [--time=S] <FILE>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Add a fade-in and fade-out, both visually (from/to black) and audially (from/to
silence) to a video clip. You do not need to know the length of the video. The
script will ask you how long you want the fade to be, and output a new video
with "-faded" appended to the file name.${reset}

$(usage)

${bold}Options:${reset}
-h, --help    Display this help message and exit.
--time=       Provide the length of the fade, in seconds.

${bold}Example:${reset}

Provide a filename, and when the script asks you how long the fade should
last, respond with a number.

${green}$ ${PROGNAME} example.mp4${reset}
> Video length is 122.029413 seconds. How long do you want each fade to last? (in seconds)
${green}$ 5${reset}
> [ffmpeg reports conversion progress]
> Done. Video created at example-faded.mp4

Or provide both the filename and the length of the fade, in seconds.

${green}$ ${PROGNAME} --time=5 example.mp4${reset}
> [ffmpeg reports conversion progress]
> Done. Video created at example-faded.mp4

_EOF_
}

# Options and flags from command line
needs_arg() {
  if [ -z "$OPTARG" ]; then
    error_exit "Error: Argument required for option '$OPT' but none provided."
  fi
}
while getopts :t-:h OPT; do
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
    t | time)
      needs_arg
      time="$OPTARG"
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
if [[ ! $file ]]; then
  usage >&2
  error_exit "Filename must be provided."
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

if [ -f "${file}" ]; then # Make sure video file exists
  vidlength=$("$ffprobe" -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$file")

  if [[ ! $time ]]; then
    printf "%s\n" "${yellow}Video length is ${reset}${vidlength} seconds${yellow} How long do you want each fade to last? (in seconds)${reset}"
    read -r duration
  else
    duration=$time
  fi

  outpoint=$(echo "$vidlength - $duration" | bc)

  "$ffmpeg" -v quiet -stats -i "$file" -vf fade=t=in:st=0:d="${duration}",fade=t=out:st="${outpoint}":d="${duration}" -af afade=t=in:st=0:d="${duration}",afade=t=out:st="${outpoint}":d="${duration}" "${name}"-faded."${ext}"

  printf "%s\n" "${green}Done. Video created at: ${reset}${bold}${name}-faded.${ext}${reset}"
else
  error_exit "Video file '${file}' not found."
fi
