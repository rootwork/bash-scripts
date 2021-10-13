#!/usr/bin/env bash
#
# Executes on git commits. Unrelated to the other Bash scripts.
# https://codeinthehole.com/tips/tips-for-using-a-git-pre-commit-hook/

# If any command fails, exit immediately with that command's exit status
set -eo pipefail

# Stash unstaged changes
STASH_NAME="pre-commit-$(date +%s)"
git stash save -q --keep-index $STASH_NAME

# Run prettier
prettier --write .

# Return unstaged changes
STASHES=$(git stash list)
if [[ $STASHES == "$STASH_NAME" ]]; then
  git stash pop -q
fi
