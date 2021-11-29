#!/bin/bash

# ----------------------------------------------------------------------------
# modimg - Create optimized image formats for the web. Generate WebP, AVIF, and
# JXL images for browsers that support them, then optimize the fallback JPEG,
# PNG and GIF images.
#
# Modern formats will only be created if they don't exist, meaning you can have
# this run as part of CI (for instance on each deployment of a static site). You
# can choose which formats to generate, and whether to optimize the fallback
# images, on each run.
#
# If a given format is requested and a library cannot be found for that format,
# the format will be skipped and reported to you (unless you turn on --quiet).
#
# By default, optimized images will overwrite un-optimized images, unless you
# set a different directory with the --output option.
#
# This script requires the following tools depending on which options you use:
#
# For image optimization and resizing, Imagemagick <https://imagemagick.org>,
# which you likely already have.
#
# For WebP encoding, libwebp <https://developers.google.com/speed/webp/download>
#
# For AVIF encoding, there aren't a lot of great options that don't require
# building libaom with avifenc from source. Consequently this tool is designed
# to use either the NPM-based AVIF-CLI <https://github.com/lovell/avif-cli> or
# the Go-based Go-AVIF <https://github.com/Kagami/go-avif>, so install one of
# these. (Other options considered included Squoosh-CLI, which had significant
# overhead if used only for AVIF encoding, and cavif, which at the time of
# development was broken.)
#
# For JXL (JPEG-XL) encoding, you can use libvips
# <https://github.com/libvips/libvips/releases>, but it must be at least
# v8.11.0, which is currently newer than a lot of systems have (for instance
# Debian stable). If libvips is not installed, this tool will fall back to
# imagemagick, which will write JXLs but will not save much in file size.

# Copyright 2021 Ivan Boothe <git@rootwork.org>

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
# $ ./modimg.sh [-f|--full] [-q|--quiet] [--output=<DIR>] [--size=<PX>] <DIR>
# $ ./modimg.sh [-o|--optimize] [-a|--avif] [-j|--jxl] [-w|--webp] [-q|--quiet] [-p=<DIR>] [-s=<PX>] <DIR>
# $ ./modimg.sh [-h|--help]

# EXAMPLES
#
# Optimize and create new formats from all images in the current directory:
# $ ./modimg.sh -f .
#
# Create WebP images, do not optimize fallback images, and report nothing but
# errors:
# $ ./modimg.sh -w --quiet .
#
# Create WebP and AVIF images, and place them with new optimized versions of
# fallback images into the "modern" subdirectory of the current directory:
# $ ./modimg.sh -wao --output=modern .
#
# Optimize and create new formats for all images in the "pictures" directory,
# resize them to a maximum width of 1000 pixels, and place them in the
# "new_pictures" subdirectory of "pictures":
# $ ./minpic.sh -f -s=1000 --output=new_pictures pictures

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

# ALTERNATIVE TOOLS:
# https://github.com/Blobfolio/refract
# https://www.npmjs.com/package/@squoosh/cli
# https://www.npmjs.com/package/next-gen-images-webpack-plugin
# https://github.com/h2non/bimg
# https://github.com/h2non/imaginary
# https://pypi.org/project/imagecodecs
# https://github.com/joppuyo/jpeg-xl-encode
# https://github.com/varnav/makejxl

# Revision history:
# 2021-11-29  Updating license (1.3)
# 2021-10-19  Improvement of option flags and addition of JXL format (1.2)
# 2021-10-18  Cleanup and standardization (1.1)
# 2021-08-24  Initial release (1.0)
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

  printf "%s\n" "${PROGNAME}: ${error_message:-"${red}Unknown Error${reset}"}" >&2
  exit 1
}

graceful_exit() {
  rm=$(command -v rm)
  for f in ${files_created[*]}; do
    "$rm" "$f"
  done
  exit 0
}

signal_exit() {

  local signal="$1"

  case "$signal" in
    INT)
      error_exit "${yellow}Program interrupted by user.${reset}"
      ;;
    TERM)
      printf "\n%s\n" "${red}$PROGNAME: Program terminated. Removing generated files...${reset}" >&2
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
    "${bold}Usage:${reset} ${PROGNAME} [-f|--full] [-q|--quiet] [-p=<DIR>] [--size=<PX>] <DIR>"
  printf "%s\n" \
    "       ${PROGNAME} [-o|--optimize] [-a|--avif] [-j|--jxl] [-w|--webp] [-q|--quiet] [-p=<DIR>] [-s=<PX>] <DIR>"
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
this run as part of CI (for instance on each deployment of a static site). You
can choose which formats to generate, and whether to optimize the fallback
images, on each run.

If a given format is requested and a library cannot be found for that format,
the format will be skipped and reported to you (unless you turn on --quiet).

By default, optimized images will overwrite un-optimized images, unless you set
a different directory with the --output option.${reset}

$(usage)

${bold}Options:${reset}
-h, --help       Display this help message and exit.
-q, --quiet      Quiet mode. Do not report skipped options or results.

-o, --optimize   Include image optimization. Requires imagemagick.
-a, --avif       Generate AVIF images. Requires avif-cli (npm) or go-avif.
-j, --jxl        Generate JXL (JPEG-XL) images. Requires imagemagick,
                 libvips v8.11.0+, or Python imagecodecs with the jpegxl
                 extension.
-w, --webp       Generate WebP images. Requires libwebp.

-f, --full       Shorthand option that optimizes images and generates all
                 available image formats.

-s=<PX>          Resize all images to a MAXIMUM of this value, in pixels.
                 Requires imagemagick.

-p=<DIR>         Output for new images and optimized versions of existing
                 images. Defaults to the current directory, overwriting
                 un-optimized images.

${bold}Examples:${reset}

Optimize and create new formats from all images in the current directory:
${green}$ ${PROGNAME} -f .${reset}

Create WebP images, do not optimize fallback images, and report nothing but
errors:
${green}$ ${PROGNAME} -w --quiet .${reset}

Create WebP and AVIF images, and place them with new optimized versions of
fallback images into the "modern" subdirectory of the current directory:
${green}$ ${PROGNAME} -wao --output=modern .${reset}

Optimize and create new formats for all images in the "pictures" directory,
resize them to a maximum width of 1000 pixels, and place them in the
"new_pictures" subdirectory of "pictures":
${green}$ ${PROGNAME} -f -s=1000 --output=new_pictures pictures${reset}

_EOF_
}

# Options and flags from command line
needs_arg() {
  if [ -z "$OPTARG" ]; then
    error_exit "Error: Argument required for option '$OPT' but none provided."
  fi
}
while getopts :-ps:oajwfqh OPT; do
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
    o | optimize)
      optimize=true
      ;;
    a | avif)
      gen_avif=true
      ;;
    j | jxl)
      gen_jxl=true
      ;;
    w | webp)
      gen_webp=true
      ;;
    f | full)
      optimize=true
      gen_avif=true
      gen_jxl=true
      gen_webp=true
      ;;
    s | size)
      needs_arg
      size="$OPTARG"
      ;;
    p | output)
      needs_arg
      output="$OPTARG"
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

# Make sure there's at least one operation
if [[ ! $optimize && ! $size && ! $gen_avif && ! $gen_jxl && ! $gen_webp ]]; then
  usage >&2
  error_exit "No operations requested."
fi

# Sanitize directory names
path=$1
if [[ ! $path ]]; then
  usage >&2
  error_exit "Directory must be provided."
fi
[[ "$path" =~ ^[./].*$ ]] || path="./$path"

# Create file arrays
files=''
for f in "$path"/**/*.{jpg,jpeg,png,gif}; do
  files+=("$f")
done
files_created=''
# Optimize: All
path_optimize=${files[*]}
# WebP: All but GIF, since they're likely to be smaller than the equivalent WebP
path_webp=$( (IFS=$'\n' && echo "${files[*]}") | grep -v '.gif$')
# AVIF: All
path_avif=${files[*]}
# JXL: All
path_jxl=${files[*]}

# Dependencies, depending on operation(s)
mogrify=$(command -v mogrify)

cwebp=$(command -v cwebp)

npx=$(command -v npx) # Indicates NPM rather than Go-based AVIF encoding.
avif=$(command -v avif)

convert=$(command -v convert)
jxl="$convert"
vips=$(command -v vips)
# Make sure libvips is at least v8.11.0
if [[ $vips ]]; then
  vips_v=$($vips --version)
  vips_regex="\b([0-9]+)\.([0-9]+)\.([0-9]+)\b"
  if [[ $vips_v =~ $vips_regex ]]; then
    vips_major="${BASH_REMATCH[1]}"
    vips_minor="${BASH_REMATCH[2]}"
    # vips_release="${BASH_REMATCH[3]}"
  fi
  if [[ $vips_major -ge "8" && $vips_minor -ge "11" ]]; then
    jxl="$vips copy"
  else
    jxl="$convert"
  fi
fi

# Create directory for output
if [[ $output ]]; then
  output="$path/$output"
  mkdir -p "$output"
else
  output=$path
fi

# Globs that match nothing expand to nothing; ** matches multiple levels.
shopt -s nullglob
shopt -s globstar

# Optimize existing images
if [[ $optimize || $size ]]; then
  if [[ $mogrify ]]; then
    opt=''
    if [[ $optimize ]]; then
      opt+=(-strip)
    fi
    if [[ $size ]]; then
      size=$size\>
      opt+=(-thumbnail "${size}")
    fi
    if [[ $quiet_mode ]]; then
      opt+=(-quiet)
    fi
    for f in $path_optimize; do
      if [ -e "$f" ]; then
        "$mogrify""${opt[@]}" "$f" -path "$output" || error_exit "command failed in line $LINENO"
        if [[ ! $quiet_mode ]]; then
          printf "%s\n" "${green}Processed fallback image ${f}${reset}"
        fi
      fi
    done
  else
    printf "%s\n" "${yellow}${bold}Optimization and/or resizing skipped:${reset}${yellow} Imagemagick's mogrify is not available and is required for image optimization and resizing. Try reinstalling Imagemagick <https://imagemagick.org>"
  fi
fi

# Create WebP images.
if [[ $gen_webp ]]; then
  if [[ $cwebp ]]; then
    for f in $path_webp; do
      filename=$(basename "$f")
      newfile="${output}/${filename%.*}.webp"
      if [ -e "$f" ]; then
        if [ ! -e "${newfile}" ]; then # Create only if file doesn't exist.
          $cwebp -quiet "$f" -o "${newfile}" || error_exit "command failed in line $LINENO"
          files_created+=("$newfile")
          if [[ ! $quiet_mode ]]; then
            printf "%s\n" "${green}Created ${newfile}${reset}"
          fi
        fi
      fi
    done
  else
    printf "%s\n" "${yellow}${bold}WebP skipped:${reset}${yellow} libwebp <https://developers.google.com/speed/webp/download> is required for generation of WebP images and was not found."
  fi
fi

# Create AVIF images.
if [[ $gen_avif ]]; then
  if [[ $avif ]]; then
    for f in $path_avif; do
      filename=$(basename "$f")
      newfile="${output}/${filename%.*}.avif"
      if [ -e "$f" ]; then
        if [ ! -e "${newfile}" ]; then # Create only if file doesn't exist.
          # NPM-based AVIF encoding
          if [[ $npx ]]; then
            "$npx" "$avif" --input="$f" --output="${output}" || error_exit "command failed in line $LINENO"
          # Go-based AVIF encoding
          else
            "$avif" -e="$f" -o="${output}" || error_exit "command failed in line $LINENO"
          fi
          files_created+=("$newfile")

          if [[ ! $quiet_mode ]]; then
            printf "%s\n" "${green}Created ${newfile}${reset}"
          fi
        fi
      fi
    done
  else
    printf "%s\n" "${yellow}${bold}AVIF skipped:${reset}${yellow} Either Node-based AVIF-CLI <https://github.com/lovell/avif-cli> or Go-based Go-AVIF <https://github.com/Kagami/go-avif> is required for generation of AVIF images and neither was found."
  fi
fi

# Create JXL images.
if [[ $gen_jxl ]]; then
  if [[ $jxl ]]; then
    for f in $path_jxl; do
      filename=$(basename "$f")
      newfile="${output}/${filename%.*}.jxl"
      if [ -e "$f" ]; then
        if [ ! -e "${newfile}" ]; then # Create only if file doesn't exist.
          "$jxl" "$f" "${newfile}" || error_exit "command failed in line $LINENO"
          files_created+=("$newfile")
          if [[ ! $quiet_mode ]]; then
            printf "%s\n" "${green}Created ${newfile}${reset}"
          fi
        fi
      fi
    done
  else
    printf "%s\n" "${yellow}${bold}JXL skipped:${reset}${yellow} Imagemagick's convert is not available and is required for generation of JXL images. Try reinstalling Imagemagick <https://imagemagick.org> Alternatively, install libvips v8.11.0+ <https://github.com/libvips/libvips/releases>"
  fi
fi
