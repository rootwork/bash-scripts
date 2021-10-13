#!/bin/sh
#
# Minify a video by re-encoding it and stripping metadata.
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# $ ./minvid.sh FILENAME
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"
ext="${1##*.}"

if [ -f "${file}" ]; then # Make sure video file exists
  echo "\e[0;92mRe-encoding video in order to minify it.\e[0m"
  ffmpeg -v quiet -stats -i "$file" -vcodec libx265 -x265-params log-level=error -crf 28 -map_metadata -1 -map_chapters -1 -movflags +faststart "$name"-min."$ext"
  echo "\e[0;92mVideo minified. File: \e[0;94m$name-min.$ext\e[0m"
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
