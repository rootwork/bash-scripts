#!/bin/bash

# ---------------------------------------------------------------------------
# imagedate - Rewrite file and metadata dates on images to increment in the
# order of the alphabetized filenames.
#
# I had a directory of images that were alphabetized by filename, and I wanted
# to import them into Snapfish. I wanted to order them by filename, but
# Snapfish only offered sorting by the date the photos were taken (forward or
# back).
#
# So I went about finding out how to create sequential creation dates for these
# photos' metadata based on their alphabetized file names. Date and time of
# first image is customizable (default 2000:01:01 00:00:00) and images are
# separated in increments of 5 minutes.
#
# This script requires exiftool to be installed: sudo apt install exiftool

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
# $ ./imagedate.sh [-q|--quiet] [--date=<YYYY:mm:ss>] [--time=<HH:MM:SS>] <DIR>
# $ ./imagedate.sh [-h|--help]

# EXAMPLES
#
# $ ./imagedate.sh .
# $ ./imagedate.sh -q images
# $ ./imagedate.sh --date="2020:01:01" --time="10:10:10" images
# $ ./imagedate.sh -q --date="2020:01:01" --time="10:10:10" images
# $ ./imagedate.sh --help

# HELPFUL COMMANDS
# Additional tools you can use during this process.
#
# check file dates
# $ stat <FILE>
#
# check EXIF dates
# $ exiftool <FILE> | grep "Date"
#
# check EXIF dates and get relevant field parameters
# $ exiftool -a -G0:1 -time:all <FILE>
#
# clean up exiftool "_original" files if you've generated them
# $ exiftool -delete_original <DIR>
#
# show EXIF problems for an individual file or all files in a directory
# $ exiftool -validate -error -warning -a -r <FILE/DIR>

# RESOURCES
#
# https://askubuntu.com/questions/62492/how-can-i-change-the-date-modified-created-of-a-file
# https://www.thegeekstuff.com/2012/11/linux-touch-command/
# https://unix.stackexchange.com/questions/180315/bash-script-ask-for-user-input-to-change-a-directory-sub-directorys-and-file
# https://photo.stackexchange.com/questions/60342/how-can-i-incrementally-date-photos
# https://exiftool.org/forum/index.php?topic=3429.0

# Revision history:
# 2021-10-14  Added flag options for date and time; applying quiet mode to
#             exiftool; minor cleanup and bug fixes (1.2)
# 2021-10-13  Modified into a full-fledged program (1.1)
# 2020-12-02  Created as a GitHub Gist of suggested commands
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.2"
red=$(tput setaf 1)
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
    "${bold}Usage:${reset} ${PROGNAME} [-q|--quiet] [--date=<YYYY:mm:ss>] [--time=<HH:MM:SS>] <DIR>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Rewrite file and metadata dates on images to increment in the order of the
alphabetized filenames. Useful when you have a system (Snapfish) that will
only order by date, but you want images ordered by filename. Date and time of
first image is customizable (default 2000:01:01 00:00:00) and images are
separated in increments of 5 minutes.${reset}

$(usage)

${bold}Options:${reset}
-h, --help    Display this help message and exit.
-q, --quiet   Quiet mode. Accept all defaults.
--date=       Provide starting date, in YYYY:mm:dd format.
--time=       Provide starting time, in HH:MM:SS format.

_EOF_
}

# Options and flags from command line
needs_arg() {
  if [ -z "$OPTARG" ]; then
    echo "$OPT: $OPTARG"
    error_exit "Error: Argument required for option '$OPT' but none provided."
  fi
}
while getopts :dt-:qh OPT; do
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
    q | quiet)
      quiet_mode="-quiet"
      ;;
    d | date)
      needs_arg
      date="$OPTARG"
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

# Sanitize directory name
dir=$1
[[ "$dir" =~ ^[./].*$ ]] || dir="./$dir"

if [ -d "${dir}" ]; then # Make sure directory exists

  if [[ ! $quiet_mode ]]; then
    echo -e "\033[1;31mWARNING:\033[0m\033[1m This script will overwrite file and metadata dates for any images it finds in the directory \033[1;31m${dir}\033[0m\033[1m -- do you want to proceed? (y/N)\e[0m"
    read -r go
  fi

  if [[ $go == *"y"* || $quiet_mode ]]; then

    if [[ ! $date ]]; then
      if [[ ! $quiet_mode ]]; then
        echo -e "\033[1;33mOn what date do you want your images to begin incrementing (YYYY:mm:dd, default 2000:01:01)?\e[0m"
        read -r startdate
      fi
      date="${startdate:=2000:01:01}"
    fi

    if [[ ! $time ]]; then
      if [[ ! $quiet_mode ]]; then
        echo -e "\033[1;33mAt what time do you want your images to begin incrementing (HH:MM:SS, default 00:00:00)?\e[0m"
        read -r starttime
      fi
      time="${starttime:=00:00:00)}"
    fi

    # Begin...
    echo -e "\e[0;92mSetting image dates...\e[0m"

    # Set all files to sequential (alphabetical) modified date.
    touch -a -m -- "${dir}"/* || error_exit "touch failed in line $LINENO"

    # Now space them apart to ensure crappy photo software picks up on the
    # differences.
    for i in "${dir}"/*; do
      touch -r "$i" -d '-1 hour' "$i" || error_exit "touch failed in line $LINENO"
      sleep 0.005
    done

    # Use exiftool to set "all dates" (which is only standard image
    # creation/modification/access) to an arbitrary date, (P)reserving file
    # modification date.
    exiftool $quiet_mode -overwrite_original -P -alldates="${date} ${time}" "${dir}"/. || error_exit "exiftool failed in line $LINENO"

    # Now update those dates sequentially separated apart (timestamps will kick
    # over to the next day/month/year as necessary), going alphabetically by
    # filename, at five-minute intervals.
    exiftool $quiet_mode -fileorder FileName -overwrite_original -P '-alldates+<0:${filesequence;$_*=5}' "${dir}"/. || error_exit "exiftool failed in line $LINENO"

    # Update nonstandard "Date/Time Digitized" field to match creation date.
    exiftool $quiet_mode -r -overwrite_original -P "-XMP-exif:DateTimeDigitized<CreateDate" "${dir}"/. || error_exit "exiftool failed in line $LINENO"

    # Update nonstandard and stupidly vague "Metadata Date" field to match
    # creation date.
    exiftool $quiet_mode -r -overwrite_original -P "-XMP-xmp:MetadataDate<CreateDate" "${dir}"/. || error_exit "exiftool failed in line $LINENO"

    echo -e "\e[0;92m                      ...done.\e[0m"

  else
    echo -e "\e[0;92mOperation canceled.\e[0m"
  fi

else
  echo -e "\e[0;91mError. Directory \e[0m'${dir}'\e[0;91m not found.\e[0m"
fi
