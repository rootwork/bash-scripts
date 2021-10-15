#!/bin/bash
# shellcheck disable=all
#
# Pathname expansion
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# Sanitize directory name
path=$1
[[ "$path" =~ ^[./].*$ ]] || path="./$path"

# Dissect and examine filename
file=$1
name="${1%.*}"
ext="${1##*.}"
if [[ ! $file ]]; then
  usage >&2
  error_exit "Filename must be provided."
fi
