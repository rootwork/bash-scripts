#!/bin/sh
#
# Convert webp images to lossless PNG first, then to JPEG.
#
# This script requires imagemagick to be installed.
#
# USAGE
#
# $ ./webpjpg.sh picture.webp
# > Image converted to picture.jpg
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

file=$1
name="${1%.*}"

echo "\e[0;92mConverting webp to jpeg...\e[0m"

if [ -f "${file}" ]; then # Make sure video file exists
  dwebp $1 -quiet -o $name.png
  convert $name.png $name.jpg
  rm $name.png
  echo "Image converted to $name.jpg"
else
  echo "\e[0;91mError. Image file \e[0m'${file}'\e[0;91m not found.\e[0m"
fi
