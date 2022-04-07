#!/usr/bin/env bash
# shellcheck disable=all
#
# Colors.
#
# Why prefer printf over echo?
# https://unix.stackexchange.com/a/65819
#
# Sources:
#
# https://techstop.github.io/bash-script-colors/
# https://stackoverflow.com/a/4332530

# tput (for printf)
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
bold=$(tput bold)
reset=$(tput sgr0)
reverse=$(tput smso)

# ANSI (for echo/echo -e)
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
yellow_bg="\e[1;43m${expand_bg}"
green="\e[0;92m"
yellow="\e[1;33m"
white="\e[0;97m"
black="\e[0;30m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"
