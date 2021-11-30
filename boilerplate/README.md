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
3. [colors.sh](colors.sh)
4. [errors.sh](errors.sh)
5. [help.sh](help.sh)
6. [options.sh](options.sh)
7. [pathname.sh](pathname.sh)
8. [dependencies.sh](dependencies.sh)

If considering using temporary files: [temp.sh](temp.sh)

When you're ready to release, be sure to go back over the script and look for
comment lines that don't need to be included, as well as pieces that may not be
necessary -- checking for flags with arguments when you're not using any such
flags, deriving the extension of a provided file without using that variable,
etc.
