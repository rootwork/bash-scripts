#!/bin/bash

# ---------------------------------------------------------------------------
# pdf2jpg - Convert each page of a PDF to a JPEG image, each with the same name
# as the PDF and the page number appended. Page range, image resolution and
# quality are configurable.
#
# Originally Poppler's `pdftoppm` only supported image exports to PNG files,
# while for all but the simplest of PDFs rendering them in JPEG will be smaller
# in file size. Newer versions (0.57+?) of pdftoppm do have a `-jpeg` flag. You
# can specify JPEG conversion using ImageMagick instead with the `--im` flag,
# which will work with older versions of pdftoppm but will take slightly longer.
#
# Prior art:
# https://www.tecmint.com/convert-pdf-to-image-in-linux-commandline/
# https://stackoverflow.com/a/28221795/19148969
#
# This script requires the following software to be installed:
#
# - Poppler <https://poppler.freedesktop.org>, which may be installed on your
# system and can be added with the following commands, as appropriate:
#
#   $ sudo apt install poppler-utils     # [On Debian/Ubuntu & Mint]
#   $ sudo dnf install poppler-utils     # [On RHEL/CentOS & Fedora]
#   $ sudo pacman -S poppler             # [On Arch Linux]
#   $ sudo zypper install poppler-tools  # [On OpenSUSE]
#
# - Imagemagick <https://imagemagick.org>, if you have a version of `pdftoppm`,
# installed with Poppler, that does not have the `-jpeg` option.

# Copyright 2022, Ivan Boothe <git@rootwork.org>

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
# $ ./pdf2jpg.sh [--first=INT] [--last=INT] [--only=INT] [--res=DPI] [--quality=PCT] [-i|--im] [-q|--quiet] <filename.pdf>
# $ ./pdf2jpg.sh [-h|--help]

# EXAMPLES
#
# Convert each page of file.pdf to JPEG images file-01.jpg, file-02.jpg, etc.:
# $ ./pdf2jpg.sh file.pdf
#
# Convert each page of file.pdf to JPEG images at 150 DPI resolution and at 100%
# quality:
# $ ./pdf2jpg.sh --res=150 --quality=100 file.pdf
#
# Convert pages 3 to 7 of file.pdf to JPEG images using Imagemagick:
# $ ./pdf2jpg.sh --first=3 --last=7 -i file.pdf
#
# Convert only page 5 of file.pdf to a JPEG image at 150 DPI resolution and at
# 100% quality, using Imagemagick, and do not report anything but errors:
# $ ./pdf2jpg.sh --only=5 --res=150 --quality=100 -i -q file.pdf

# Revision history:
# 2022-07-15  Initial release (1.0)
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.0"
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
    "${bold}Usage:${reset} ${PROGNAME} [--first=INT] [--last=INT] [--res=DPI] [--quality=PCT] [-i|--im] [-q|--quiet] <filename.pdf>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Convert each page of a PDF to a JPEG image, each with the same name as the PDF
and the page number appended.${reset}

$(usage)

${bold}Options:${reset}
--first      Optionally specify the page of the PDF on which to begin.
--last       Optionally specify the page of the PDF on which to end.
--only       Optionally specify only this page of the PDF and no others.
--res        Specify resolution of the images. Defaults to 72 (DPI), standard
             for a website. Because the dimensions of the images are not
             constrained, resolution size will affect the width and height of
             the generated images.
--quality    Specify the quality of the JPEG images, from 1 to 100, with higher
             being greater quality and larger file size. Defaults to 90
-i, --im     Process images through ImageMagick, which will take slightly
             longer. Necessary if your version of pdftoppm (part of Poppler)
             does not have the '-jpeg' option.
-q, --quiet  Quiet mode.
-h, --help   Display this help message and exit.

_EOF_
}

# Options and flags from command line
quiet_mode=false
use_im=false
resolution=72
quality=90
needs_arg() {
  if [ -z "$OPTARG" ]; then
    error_exit "Error: Argument required for option '$OPT' but none provided."
  fi
}
while getopts :ifloyr-:qh OPT; do
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
      quiet_mode=true
      ;;
    i | im)
      use_im=true
      ;;
    f | first)
      needs_arg
      first="$OPTARG"
      ;;
    l | last)
      needs_arg
      last="$OPTARG"
      ;;
    o | only)
      needs_arg
      only="$OPTARG"
      ;;
    y | quality)
      needs_arg
      quality="$OPTARG"
      ;;
    r | res)
      needs_arg
      resolution="$OPTARG"
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
file=${1:-}
if [[ -z "$file" ]]; then
  usage >&2
  error_exit "Filename must be provided."
fi
name="${1%.*}"

# Dependencies
pdfinfo=$(command -v pdfinfo)
if [[ ! $pdfinfo ]]; then
  error_exit "Poppler must be installed <https://poppler.freedesktop.org>. Aborting."
fi
pdftoppm=$(command -v pdftoppm)
if [[ ! $pdftoppm ]]; then
  error_exit "Poppler must be installed <https://poppler.freedesktop.org>. Aborting."
fi

if [[ $use_im = "true" ]]; then
  convert=$(command -v convert)
  if [[ ! $convert ]]; then
    error_exit "Imagemagick must be installed <https://imagemagick.org> to use the -i|--im option. Aborting."
  fi
fi

if [ -f "${file}" ]; then # Make sure file exists

  if [[ $quiet_mode = "false" ]]; then
    pages_total=$($pdfinfo "$file" | grep "Pages" | sed -r -e 's/\s+//g' -e 's/Pages\://g')
    pages="Pages 1 to $pages_total"

    if [[ $only ]]; then
      pages="Page $only"
    fi

    if [[ $first ]]; then
      pages="Pages $first"
      if [[ $last ]]; then
        pages="$pages to $last"
      else
        pages="$pages to $pages_total"
      fi
    fi

    if [[ $last ]]; then
      if [[ $first ]]; then
        pages=$pages
      else
        pages="Pages 1 to $last"
      fi
    fi

    printf "%s\n" "${cyan}Processing ${file} (${pages}, of ${pages_total} pages), please wait...${reset}"
  fi

  # Set options
  opts="-r ${resolution}"
  if [[ $first ]]; then
    opts="${opts} -f ${first}"
  fi
  if [[ $last ]]; then
    opts="${opts} -l ${last}"
  fi
  if [[ $only ]]; then
    opts="${opts} -f ${only} -l ${only}"
  fi

  if [[ $use_im = "true" ]]; then
    format="-png"
  else
    format="-jpeg -jpegopt progressive=y,quality=$quality"
  fi

  # Use Poppler to convert the PDF to images
  $pdftoppm $format $opts "$file" "$name"

  # Optionally use ImageMagick to convert images to JPEG format
  if [[ $use_im = "true" ]]; then
    for i in "$name"*.png; do
      $convert "$i" -strip -interlace Plane -quality $quality -set filename:f '%t' '%[filename:f].jpg'
      rm "$i"
      if [[ $quiet_mode = "false" ]]; then
        printf "%s\n" "${green}${i%.*}.jpg created.${reset}"
      fi
    done
  fi

  if [[ $quiet_mode = "false" ]]; then
    printf "%s\n" "${green}${bold}Conversion complete.${reset}"
  fi

else
  error_exit "File '${file}' not found."
fi
