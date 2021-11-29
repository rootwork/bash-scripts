# Boilerplate code

This folder is just a local source for reusable patterns and snippets, many
derived from
[William E. Shotts, Jr](https://linuxcommand.org/lc3_adv_standards.php).

This does result in repeated code and some maintenance overhead, but allows
scripts to be self-contained, rather than loading these utility pieces in order
to run.

Files are NOT executable Bash scripts; they are saved as `.sh` only for the
syntax highlighting. Thus the second line in each file disables
[shellcheck](https://www.shellcheck.net).

## Usage in order

1. [commentblock.sh](commentblock.sh)
2. [vars.sh](vars.sh)
3. [pathname.sh](pathname.sh)
4. [colors.sh](colors.sh)
5. [errors.sh](errors.sh)
6. [help.sh](help.sh)
7. [options.sh](options.sh)
8. [dependencies.sh](dependencies.sh)

When considering using temporary files: [temp.sh](temp.sh)
