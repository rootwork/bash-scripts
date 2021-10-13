#!/bin/sh
#
# Add a watermark image to a video. You do not need to know the dimensions of
# the video or the watermark image, just how far from the lower-right corner
# you want the watermark to be. A new video will be output with "-marked"
# appended to the file name.
#
# This is barely more than an alias, but is a lot easier than remembering all
# the configuration parameters.
#
# Sources:
# https://gist.github.com/bennylope/d5d6029fb63648582fed2367ae23cfd6
# https://ffmpeg.org/ffmpeg-filters.html#overlay-1
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# Run the script with a path to the video, a path to the watermark file, and the
# distance (in pixels) you want the watermark to appear from the lower-right
# corner.
#
#   $ ./markvid.sh video.mp4 watermark.png 10
#   > [ffmpeg reports conversion progress]
#   > Done. Video created at video-marked.mp4
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
base=${file%.*}
ext=${file#$base}
ext=${ext#.}

wm=$2
dist=$3

if [ -f "${file}" ]; then # Make sure video file exists
  if [ -f "${wm}" ]; then # Make sure watermark file exists
    ffmpeg -v quiet -stats -i $file -i $wm -filter_complex "overlay=main_w-overlay_w-${dist}:main_h-overlay_h-${dist}" ${base}-marked.${ext}
    echo "\e[0;92mDone. Video created at \e[0;94m${base}-marked.${ext}\e[0m"
  else
    echo "\e[0;91mError. Watermark file \e[0m'${wm}'\e[0;91m not found.\e[0m"
  fi
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
