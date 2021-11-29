#!/usr/bin/env bash
# shellcheck disable=all
#
# Error handling.
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# Error handling
error_exit() {
  local error_message="${red}$1${reset}"

  printf "%s\n" "${PROGNAME}: ${error_message:-"${red}Unknown Error${reset}"}" >&2
  exit 1
}
# Use as following:
# command || error_exit "command failed in line $LINENO"

graceful_exit() {
  # Optionally provide file cleanup here.
  exit 0
}

signal_exit() {

  local signal="$1"

  case "$signal" in
    INT)
      error_exit "${yellow}Program interrupted by user.${reset}"
      ;;
    TERM)
      printf "\n%s\n" "${red}$PROGNAME: Program terminated.${reset}" >&2
      graceful_exit
      ;;
    *)
      error_exit "${red}$PROGNAME: Terminating on unknown signal.${reset}"
      ;;
  esac
}
