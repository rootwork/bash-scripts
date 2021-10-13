#!/bin/sh
#
# Strip metadata from video.
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# $ ./stripvid.sh FILENAME
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"
ext="${1##*.}"

if [ -f "${file}" ]; then # Make sure video file exists
  ffmpeg -v quiet -stats -i "$file" -c:v copy -c:a copy -map_metadata -1 -map_chapters -1 -movflags +faststart "$name"-stripped."$ext"
  echo "\e[0;92mMetadata stripped from video. File: \e[0;94m$name-stripped.$ext\e[0m"
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
