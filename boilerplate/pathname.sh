#!/bin/bash
# shellcheck disable=all
#
# Pathname expansion
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# Sanitize directory name
dir=$1
[[ "$dir" =~ ^[./].*$ ]] || dir="./$dir"
