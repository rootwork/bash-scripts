#!/usr/bin/env bash
# shellcheck disable=all
#
# Temporary files and process substitution.
#
# Sources:
#
# https://linuxcommand.org/lc3_adv_standards.php

# Wherever possible, temporary files should be avoided. In many cases, process substitution can be used instead. Doing it this way will reduce file clutter, run faster, and in some cases be more secure.

# Rather than this:
#
# command1 > "$TEMPFILE"
# [code]
# command2 < "$TEMPFILE"

# Consider this:
#
# command2 < <(command1)

# If temporary files cannot be avoided, care must be taken to create them safely. We must consider, for example, what happens if there is more than one instance of the script running at the same time. For security reasons, if a temporary file is placed in a world-writable directory (such as /tmp) we must ensure the file name is unpredictable. A good way to create temporary file is by using the mktemp command as follows:

TEMPFILE="$(mktemp /tmp/"$PROGNAME".$$.XXXXXXXXX)"

# In this example, a temporary file will be created in the /tmp directory with the name consisting of the script’s name followed by its process ID (PID) and 10 random characters.

# For temporary files belonging to a regular user, the /tmp directory should be avoided in favor of the user’s home directory.
