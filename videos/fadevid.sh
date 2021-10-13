#!/bin/sh
#
# Add a fade-in and fade-out, both visually (from/to black) and audially
# (from/to silence) to a video clip. You do not need to know the length of the
# video. The script will ask you how long you want the fade to be, and output a
# new video with "-faded" appended to the file name.
#
# Sources:
# https://blog.feurious.com/add-fade-in-and-fade-out-effects-with-ffmpeg
# https://video.stackexchange.com/questions/28269/how-do-i-fade-in-and-out-in-ffmpeg
#
# This script requires ffmpeg to be installed.
#
# USAGE
#
# Provide a filename, and when the script asks you how long the fade should
# last, respond with a number.
#
#   $ ./fadevid.sh example.mp4
#   > Video length is 122.029413 seconds. How long do you want each fade to last? (in seconds)
#   $ 5
#   > [ffmpeg reports conversion progress]
#   > Done. Video created at example-faded.mp4
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
base=${file%.*}
ext=${file#$base}
ext=${ext#.}

vidlength=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 $file)

if [ -f "${file}" ]; then # Make sure video file exists
  echo "\e[0;92mVideo length is \e[0;94m$vidlength\e[0;92m seconds. How long do you want each fade to last? (in seconds)\e[0m"
  read duration

  outpoint=$(echo "$vidlength - $duration" | bc)

  ffmpeg -v quiet -stats -i $file -vf fade=t=in:st=0:d=${duration},fade=t=out:st=${outpoint}:d=${duration} -af afade=t=in:st=0:d=${duration},afade=t=out:st=${outpoint}:d=${duration} ${base}-faded.${ext}

  echo "\e[0;92mDone. Video created at \e[0;94m$base-faded.$ext\e[0m"
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
