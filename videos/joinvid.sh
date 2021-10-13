#!/bin/sh
#
# Combine videos. Provide one or more filenames of videos to be combined; the
# resulting video file will be named 'joined.mp4'.
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# $ ./joinvid.sh FILENAME1 FILENAME2...
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

echo "\e[0;92mGenerating list of input videos...\e[0m"
echo "# Videos to merge" >concat.txt

for file in "$@"; do
  echo "file '$file'" >>concat.txt
done

echo "\e[0;92mUsing ffmpeg to merge files...\e[0m"

ffmpeg -v quiet -stats -f concat -i concat.txt -c copy joined.mp4

rm concat.txt
echo "\e[0;92mVideos merged! File: \e[0;94mjoined.mp4\e[0m"
