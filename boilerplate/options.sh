#!/usr/bin/env bash
# shellcheck disable=all
#
# Options and flags
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php
# https://stackoverflow.com/a/28466267/519360

# Options and flags from command line
needs_arg() {
  if [ -z "$OPTARG" ]; then
    error_exit "Error: Argument required for option '$OPT' but none provided."
  fi
}
while getopts :dt-:qh OPT; do
  # Using help flag only? The above should be:
  # while getopts :-:h OPT; do
  if [ "$OPT" = "-" ]; then # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"     # extract long option name
    OPTARG="${OPTARG#$OPT}" # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"    # remove assigning `=`
  else
    OPTARG="${OPTARG#=}" # if short option, just remove assigning `=`
  fi
  case "$OPT" in
    h | help)
      help_message
      graceful_exit
      ;;
    q | quiet)
      quiet_mode=true
      ;;
    d | date)
      needs_arg
      date="$OPTARG"
      ;;
    ??*) # bad long option
      usage >&2
      error_exit "Unknown option --$OPT"
      ;;
    ?) # bad short option
      usage >&2
      error_exit "Unknown option -$OPTARG"
      ;;
  esac
done
shift $((OPTIND - 1)) # remove parsed options and args from $@ list
