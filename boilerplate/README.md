# Boilerplate code

This folder is just a local source for reusable patterns and snippets.

This does result in repeated code and some maintenance overhead, but allows
scripts to be self-contained, rather than loading these utility pieces in order
to run.

Files are NOT executable Bash scripts; they are saved as `.sh` only to aid with
Bash syntax highlighting. Thus the second line in each file disables shellcheck.

## Usage in order

1. [commentblock.sh](commentblock.sh)
2. [vars.sh](vars.sh)
3. [colors.sh](colors.sh)
4. [errors.sh](errors.sh)
5. [help.sh](help.sh)
6. [options.sh](options.sh)
7. [pathname.sh](pathname.sh)

When considering using temporary files: [temp.sh](temp.sh)
