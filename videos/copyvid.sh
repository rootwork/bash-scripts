#!/bin/sh
#
# Quick copy of any file format to MP4
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# $ ./copyvid.sh FILENAME
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"
ext="${1##*.}"

if [ -f "${file}" ]; then # Make sure video file exists
  _ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  mp4='mp4'
  if [ $_ext = $mp4 ]; then # Warn if video is already an MP4
    echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m is already in MP4 format.\e[0m"
  else
    ffmpeg -v quiet -stats -i "$file" -c:v copy -c:a copy "$name".mp4
    echo "\e[0;92mVideo converted. File: \e[0;94m$name.mp4\e[0m"
  fi
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
