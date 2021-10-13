#!/bin/sh
#
# Convert any video files readable by ffmpeg (including but not limited to MP4,
# MPG, M4V, MOV, WEBM, WMV, AVI, 3GP) into modern H265-encoded MP4 file. This
# will generally be smaller in file size and more widely playable than other
# video formats.
#
# Background information:
# https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding
# https://ffmpeg.org/ffmpeg-formats.html#Demuxers
# Or run `ffmpeg -formats` at the command prompt to see all valid input formats.
# Note that video formats aren't necessarily the same thing as file extensions,
# but ffmpeg will determine the encoding based on the file contents, not the
# file extension itself.
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# Provide either a filename or a file extension.
#
# If a filename is provided, it will convert only that file.
#
# If a file extension is provided, it will convert all matching files in the
# current directory.
#
# EXAMPLES
#
# Converting one file named example.mpg:
#
#   $ ./convertvid.sh example.mpg
#
# Converting all WMV files in the current directory:
#
#   $ ./convertvid.sh wmv
#
# Files will be output into a subdirectory named "converted", with each file
# having its original filename appended with .mp4
#
# Note that providing '*' as a file format won't work; you'll need to provide
# file formats one at a time that exist in the current directory.
#
# INSPIRATION
#
# https://stackoverflow.com/a/33766147
# https://video.stackexchange.com/a/19862
# https://linuxconfig.org/how-to-use-ffmpeg-to-convert-multiple-media-files-at-once-on-linux
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

input=$1

mkdir -p ./converted

# Input is a single file
if [ -f "${input}" ]; then
  ffmpeg -i "$input" -vcodec libx265 -crf 28 "./converted/${input%.*}.mp4"
  echo "Conversion complete. Converted file can be found in the 'converted' subdirectory."
# Input is file extension
else
  for f in *.${input}; do
    ffmpeg -i "$f" -vcodec libx265 -crf 28 "./converted/${f%.*}.mp4"
  done
  echo "Conversion complete. Converted file(s) can be found in the 'converted' subdirectory."
fi
