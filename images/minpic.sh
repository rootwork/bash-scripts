#!/bin/sh
#
# Minify JPEG and PNG images, losslessly, for the web.
#
# This script requires Trimage to be installed: https://trimage.org
#
# USAGE
#
# $ ./minpic.sh FILE
#
# EXAMPLES
#
# $ ./minpic.sh pic.jpg
# $ ./minpic.sh pic.jpg pic2.png
# $ ./minpic.sh *.jpg pic2.png
#
# LICENSE
#
# GPLv3: https://raw.githubusercontent.com/rootwork/dotfiles/hosted/LICENSE

echo "\e[0;92mUsing Trimage to minify images...\e[0m"

for i in "$@"; do
  if [ -f "${i}" ]; then # Make sure video file exists
    trimage -q -f "$i"
  else
    echo "\e[0;91mError. Image file \e[0m'${i}'\e[0;91m not found.\e[0m"
  fi
done
