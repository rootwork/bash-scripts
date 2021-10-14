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
