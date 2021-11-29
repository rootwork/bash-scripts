#!/usr/bin/env bash
# shellcheck disable=all
#
# Standard settings and variables.
#
# Note the PROGNAME is just that, the name -- _not_ the program's location! See
# https://mywiki.wooledge.org/BashFAQ/028
# for suggestions on determining the program's location.
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php
# http://redsymbol.net/articles/unofficial-bash-strict-mode/

# Standard settings and variables
set -euo pipefail
IFS=$'\n\t'
PROGNAME=${0##*/}
VERSION="1.0"
