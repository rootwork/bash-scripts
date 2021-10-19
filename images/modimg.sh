#!/bin/bash

# ----------------------------------------------------------------------------
# modimg - Create optimized image formats for the web. Generate WebP, AVIF, and
# JXL images for browsers that support them, then optimize the fallback JPEG,
# PNG and GIF images.
#
# Modern formats will only be created if they don't exist, meaning you can have
# this run as part of CI (for instance on each deployment of a static site).
#
# This script requires the following tools:
# imagemagick <https://imagemagick.org>
# libwebp <https://developers.google.com/speed/webp/download>
# avif-cli <https://github.com/lovell/avif-cli>

# Copyright 2021 Ivan Boothe <git@rootwork.org>

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
# $ ./modimg.sh [-q|--quiet] [-o|--overwrite] <DIR> [NEWSIZE]
# $ ./modimg.sh [-h|--help]

# EXAMPLES
#
# Optimize and create new formats from all images in the current directory:
# $ ./modimg.sh .
#
# Do the same, but place new images and optimized images in this directory,
# overwriting existing images:
# $ ./modimg.sh -o .
#
# Do the same to all images in the "pictures" category, and resize the new
# images to be a maximum of 1000 pixels wide:
# $ ./minpic.sh pictures 1000
#
# Don't report anything but errors:
# $ ./minpic.sh --quiet photos

# RESOURCES
#
# WebP:
# https://en.wikipedia.org/wiki/WebP
# https://developers.google.com/speed/webp
# https://caniuse.com/webp
#
# AVIF:
# https://en.wikipedia.org/wiki/AV1#AV1_Image_File_Format_(AVIF)
# https://web.dev/compress-images-avif/
# https://fronius.me/articles/2020-10-14-comparing-image-formats-jpg-webp-avif.html
# https://aomediacodec.github.io/av1-avif/
# https://caniuse.com/avif
#
# JXL:
# https://en.wikipedia.org/wiki/JPEG_XL
# https://jpeg.org/jpegxl/
# https://cloudinary.com/blog/how_jpeg_xl_compares_to_other_image_codecs
# https://caniuse.com/jpegxl

# Revision history:
# 2021-10-18  Cleanup, standardization, and addition of JXL options (1.1)
# 2021-08-24  Initial release (1.0)
# ---------------------------------------------------------------------------

# Standard variables
PROGNAME=${0##*/}
VERSION="1.1"
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
bold=$(tput bold)
reset=$(tput sgr0)
reverse=$(tput smso)

# Error handling
error_exit() {
  local error_message="${red}$1${reset}"

  printf "%s\n" "${PROGNAME}: ${error_message:-"${red}Unknown Error${reset}"}" >&2
  exit 1
}
# Use as following:
# command || error_exit "command failed in line $LINENO"

graceful_exit() {
  # Optionally provide file cleanup here.
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
    "${bold}Usage:${reset} ${PROGNAME} [-o|--overwrite] [-m|--modern-only] <DIR>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
Create optimized image formats for the web. Generate WebP, AVIF, and JXL images
for browsers that support them, then optimize the fallback JPEG, PNG and GIF
images.

Modern formats will only be created if they don't exist, meaning you can have
this run as part of CI (for instance on each deployment of a static site).

By default, images will be created in the subdirectory "modimg" unless the
--overwrite flag is used.${reset}

$(usage)

${bold}Options:${reset}
-h, --help         Display this help message and exit.
-q, --quiet        Quiet mode. Do not report anything but errors.
-o, --overwrite    Place any new images in the existing directory, and overwrite
                   any optimized images, instead of placing new and optimized
                   images in the "modimg" subdirectory.

${bold}Examples:${reset}

Optimize and create new formats from all images in the current directory:
${green}$ ${PROGNAME} .${reset}

Do the same, but place new images and optimized images in this directory,
overwriting existing images:
${green}$ ${PROGNAME} -o .${reset}

Do the same to all images in the "pictures" category, and resize the new images
to be a maximum of 1000 pixels wide:
${green}$ ${PROGNAME} pictures 1000${reset}

Don't report anything but errors:
${green}$ ${PROGNAME} --quiet photos${reset}

_EOF_
}

# Options and flags from command line
while getopts :-:oqh OPT; do
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
      quiet_mode="-quiet"
      ;;
    o | overwrite)
      overwrite=true
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
if [[ ! $path ]]; then
  usage >&2
  error_exit "Directory must be provided."
fi
[[ "$path" =~ ^[./].*$ ]] || path="./$path"
files=''

# Get new size, if set
size=$2

# Dependencies
mogrify=$(command -v mogrify)
if [[ ! $mogrify ]]; then
  error_exit "Imagemagick's mogrify must be available and does not appear to be. Try reinstalling Imagemagick <https://imagemagick.org>. Aborting."
fi
cwebp=$(command -v cwebp)
if [[ ! $cwebp ]]; then
  error_exit "libwebp must be installed <https://developers.google.com/speed/webp/download>. Aborting."
fi
avif=$(command -v avif)
if [[ ! $avif ]]; then
  error_exit "avif-cli must be installed <https://github.com/lovell/avif-cli>. Aborting."
fi

# Create directory for output
if [[ ! $overwrite ]]; then
  output="$path/modimg"
  mkdir -p "$output"
else
  output=$path
fi

# Globs that match nothing expand to nothing; ** matches multiple levels.
shopt -s nullglob
shopt -s globstar

# Optimize existing images
if [[ $size ]]; then
  size=$size\>
  opt=(-strip -thumbnail "${size}")
else
  opt=(-strip)
fi

for f in "$path"/**/*.{jpg,jpeg,png,gif}; do
  if [ -e "$f" ]; then
    "$mogrify" "${opt[@]}" -path "$output" "$f"
    files+=("$f")
    if [[ ! $quiet_mode ]]; then
      printf "%s\n" "${green}Optimized ${f}${reset}"
    fi
  fi
done

# Create WebP formats.
# Omit GIFs because they're likely to be larger than the equivalent WebP.
webp=$( (IFS=$'\n' && echo "${files[*]}") | grep -v '.gif$')
for f in $webp; do
  filename=$(basename "$filename")
  newfile="${output}/${filename%.*}.webp"
  if [ -e "$f" ]; then
    if [ ! -e "${newfile}" ]; then # Create only if file doesn't exist.
      cwebp -quiet "$f" -o "${newfile}"
      if [[ ! $quiet_mode ]]; then
        printf "%s\n" "${green}Created ${newfile}${reset}"
      fi
    fi
  fi
done
