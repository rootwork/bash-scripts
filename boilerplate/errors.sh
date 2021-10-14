#!/bin/bash
# shellcheck disable=all
#
# Error handling.
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# Error handling
error_exit() {
  local error_message="$1"

  printf "%s\n" "${PROGNAME}: ${error_message:-"Unknown Error"}" >&2
  exit 1
}

graceful_exit() {
  # Optionally provide file cleanup here.
  exit 0
}

signal_exit() {

  local signal="$1"

  case "$signal" in
    INT)
      error_exit "Program interrupted by user"
      ;;
    TERM)
      printf "\n%s\n" "$PROGNAME: Program terminated" >&2
      graceful_exit
      ;;
    *)
      error_exit "$PROGNAME: Terminating on unknown signal"
      ;;
  esac
}
