#!/bin/bash
#
# Rewrite file and metadata dates on images to increment in the order of the
# alphabetized filenames.
#
# I had a directory of images that were alphabetized by file name, and I wanted
# to import them into a popular photo-printing service. I wanted to order them
# by filename, but this particular service only offered sorting by the date the
# photos were taken (forward or back).
#
# So I went about finding out how to create sequential creation dates for these
# photos' metadata based on their alphabetized file names. The actual date set
# didn't matter to me, because all I wanted them to be was in order.
#
# Note this IRREVERSIBLY alters your images' file and metadata dates! Don't
# run this on images for which you what to preserve the original information
# unless you have a copy of them elsewhere.
#
# This script requires exiftool to be installed: sudo apt install exiftool
#
# USAGE
#
# $ ./imagedate.sh DIR
#
# EXAMPLES
#
# $ ./imagedate.sh .
# $ ./imagedate.sh ./photos
#
# HELPFUL COMMANDS
# Additional tools you can use during this process.
#
# check file dates
# $ stat <FILE>
#
# check EXIF dates
# $ exiftool <FILE> | grep "Date"
#
# check EXIF dates and get relevant field parameters
# $ exiftool -a -G0:1 -time:all <FILE>
#
# clean up exiftool "_original" files if you've generated them
# $ exiftool -delete_original <DIR>
#
# show EXIF problems for an individual file or all files in a directory
# $ exiftool -validate -error -warning -a -r <FILE/DIR>
#
# RESOURCES
#
# https://askubuntu.com/questions/62492/how-can-i-change-the-date-modified-created-of-a-file
# https://www.thegeekstuff.com/2012/11/linux-touch-command/
# https://unix.stackexchange.com/questions/180315/bash-script-ask-for-user-input-to-change-a-directory-sub-directorys-and-file
# https://photo.stackexchange.com/questions/60342/how-can-i-incrementally-date-photos
# https://exiftool.org/forum/index.php?topic=3429.0
#
# LICENSE
#
# GPLv3: https://github.com/rootwork/bash-scripts/blob/main/LICENSE

dir=$1

if [ -d "${dir}" ]; then # Make sure directory exists

  echo -e "\e[0;91m\e[1mWARNING:\e[0m\e[1m This script will overwrite file and metadata dates for any images it finds. Do you want to proceed? (y/N)\e[0m"
  read go
  yes="y"

  if [[ $go == *"$yes"* ]]; then

    echo -e "\e[0;92mSetting image dates...\e[0m"

    # Set all files to sequential (alphabetical) modified date.
    touch -a -m -- ${dir}/*

    # Now space them apart by 5 milliseconds to ensure crappy photo software
    # picks up on the differences.
    for i in ${dir}/*; do
      touch -r "$i" -d '-1 hour' "$i"
      sleep 0.005
    done

    # Use exiftool to set "all dates" (which is only standard image
    # creation/modification/access) to an arbitrary date, (P)reserving file
    # modification date.
    exiftool -overwrite_original -P -alldates="2000:01:01 00:00:00" ${dir}/.

    # Now update those dates sequentially separated one hour apart (it will kick
    # over to the next day/month/year as necessary), going alphabetically by
    # filename.
    exiftool -fileorder FileName -overwrite_original -P '-alldates+<${filesequence}0:0:0' ${dir}/.

    # Update nonstandard "Date/Time Digitized" field to match creation date.
    exiftool -r -overwrite_original -P "-XMP-exif:DateTimeDigitized<CreateDate" ${dir}/.

    # Update nonstandard and stupidly vague "Metadata Date" field to match
    # creation date.
    exiftool -r -overwrite_original -P "-XMP-xmp:MetadataDate<CreateDate" ${dir}/.

    echo -e "\e[0;92m                      ...done.\e[0m"

  else
    echo -e "\e[0;92mOperation canceled.\e[0m"
  fi

else
  echo -e "\e[0;91mError. Directory \e[0m'${dir}'\e[0;91m not found.\e[0m"
fi
