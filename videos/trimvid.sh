#!/bin/sh
#
# Trim MP4 videos with a starting timecode and a duration or stop timecode.
#
# This script requires ffmpeg to be installed. See its documentation for details
# on the duration and timecode formats that can be passed:
# https://ffmpeg.org/ffmpeg-utils.html#time-duration-syntax
#
# USAGE
#
# trimvid FILENAME START END
#
# START format is HH:MM:SS.
#
# END format is optional. If no value is provided, it trims from the start
# timecode to the end of the video. If a value is provided, it can be either a
# decimal number (in seconds), in which case it acts as a duration, OR a
# timecode in the form of HH:MM:SS, in which case it acts as a stop position.
#
# EXAMPLES
#
# Trim video.mp4 beginning at 1 minute, 29 seconds to the end of the video.
# $ ./trimvid.sh video.mp4 00:01:29
#
# Trim video.mp4 beginning at 1 minute, 29 seconds and lasting for 90 seconds
# (one and a half minutes).
# $ ./trimvid.sh video.mp4 00:01:29 90
#
# Trim video.mp4 beginning at 1 minute, 29 seconds and ending at 1 hour, 52
# minutes, 56 seconds.
# $ ./trimvid.sh video.mp4 00:01:29 01:52:56
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"
ext="${1##*.}"

start=$2
end=$3

# Determine length of video (decimal, in seconds)
vidlength=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 $file)

if [ $end ]; then
  if [ -z "${end##*:*}" ]; then # end is a timecode
    end=$(echo "$end" | awk -F':' '{print $1 * 60 * 60 + $2 * 60 + $3}')
    start=$(echo "$start" | awk -F':' '{print $1 * 60 * 60 + $2 * 60 + $3}')
    end=$(echo "$end - $start" | bc) # provide end as duration
  else                               # end is a duration
    end=$end
  fi
else
  end=$vidlength
fi

if [ -f "${file}" ]; then # Make sure video file exists
  ffmpeg -v quiet -stats -ss "$start" -i "$file" -t "$end" -c copy -map_metadata -1 -map_chapters -1 "$name"-trim."$ext"
  echo "\e[0;92mVideo trimmed. File: \e[0;94m$name-trim.$ext\e[0m"
else
  echo "\e[0;91mError. Video file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
