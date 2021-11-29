#!/usr/bin/env bash
# shellcheck disable=all
#
# Help and usage messages.
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# USAGE should match the "Usage" section from the comment block.
# HELP's description should match the description or "Long Description" from the
# comment block.

# Usage: Separate lines for mutually exclusive options.
usage() {
  printf "%s\n" \
    "${bold}Usage:${reset} ${PROGNAME} [-q|--quiet] <DIR>"
  printf "%s\n" \
    "       ${PROGNAME} [-h|--help]"
}

# Help message for --help
help_message() {
  cat <<-_EOF_

${bold}${PROGNAME} ${VERSION}${reset}
${cyan}
[Long description]${reset}

$(usage)

${bold}Options:${reset}
-h, --help    Display this help message and exit.
-q, --quiet   Quiet mode.

_EOF_
}
