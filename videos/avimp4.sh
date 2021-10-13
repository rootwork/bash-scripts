#!/bin/sh
#
# More thorough conversion of AVI to MP4 than the default process.
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# $ ./avimp4.sh FILENAME
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"

if [ -f "${file}" ]; then # Make sure video file exists
  ffmpeg -v quiet -stats -i "$file" -c:a aac -b:a 128k -c:v libx265 -x265-params log-level=error -crf 23 "$name".mp4
  echo "\e[0;92mVideo converted. File: \e[0;94m$name.mp4\e[0m"
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
