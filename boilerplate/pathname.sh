#!/usr/bin/env bash
# shellcheck disable=all
#
# Pathname expansion
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# Sanitize directory name
path=${1:-}
if [[ -z "$path" ]]; then
  usage >&2
  error_exit "Directory path must be provided."
fi
[[ "$path" =~ ^[./].*$ ]] || path="./$path"

# Dissect and examine filename
file=${1:-}
if [[ -z "$file" ]]; then
  usage >&2
  error_exit "Filename must be provided."
fi
name="${1%.*}"
ext="${1##*.}"
