#!/bin/sh
#
# Reduce video size even more than minvid, with second argument for bitrate, in
# KB. A value of 2600 might be a helpful starting point.
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# $ ./minsmvid.sh FILENAME BITRATE
#
# EXAMPLE
#
# $ ./minsmvid.sh video.mp4 2600
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"
ext="${1##*.}"

bitrate=$2

if [ $bitrate ]; then       # Made sure bitrate is provided
  if [ -f "${file}" ]; then # Make sure video file exists
    echo "\e[0;92mRunning first of two passes.\e[0m"
    ffmpeg -v quiet -stats -y -i "$file" -tune film -preset slower -map_metadata -1 -map_chapters -1 -c:v libx264 -b:v "$bitrate"k -pass 1 -vsync cfr -f null /dev/null &&
      echo "\e[0;92mRunning second of two passes.\e[0m"
    ffmpeg -v quiet -stats -i "$file" -c:v libx264 -b:v "$bitrate"k -pass 2 -c:a aac -b:a 128k -movflags +faststart "$name"-minsm."$ext"
    rm ffmpeg2pass-0.log.mbtree && rm ffmpeg2pass-0.log
    echo "\e[0;92mVideo minified. File: \e[0;94m$name-minsm.$ext\e[0m"
  else
    echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
  fi
else
  echo "\e[0;91mError. Provide a bitrate, e.g. \e[0;94m./minsmvid.sh video.mp4 2600"
fi
