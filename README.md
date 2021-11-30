# Bash scripts

[![License](https://img.shields.io/npm/l/mjml-bullet-list?color=brightgreen&style=flat-square)](https://github.com/premail/mjml-bullet-list/blob/main/LICENSE)

Scripts marked with a 🌟 are ones I use a lot or am particularly proud of.

### Image manipulation

- 🌟 [imagedate.sh](images/imagedate.sh): Rewrite file and metadata dates on images
  to increment in the order of the alphabetized filenames. Useful when you have
  a system (Snapfish) that will only order by date, but you want images ordered
  by filename.
- [minpic.sh](images/minpic.sh): Minify JPEG and PNG images, losslessly, for the
  web. Really just a more convenient wrapper for
  [Trimage](https://trimage.org/).
- 🌟 [modimg.sh](images/modimg.sh): Create optimized image formats for the web.
  Generate [WebP](https://developers.google.com/speed/webp),
  [AVIF](https://web.dev/compress-images-avif/), and
  [JXL](https://cloudinary.com/blog/how_jpeg_xl_compares_to_other_image_codecs)
  images for browsers that support them, then optimize the fallback JPEG, PNG
  and GIF images. See the file for additional options and details.
- [webpjpg.sh](images/webpjpg.sh): Convert webp images to lossless PNG first,
  then to JPEG.

### Video manipulation

- [avimp4.sh](videos/avimp4.sh): Convert AVI videos to MP4 format. More thorough
  than ffmpeg's default process, resulting in both smaller and better-quality
  videos.
- 🌟 [convertvid.sh](videos/convertvid.sh): Convert any video files readable by
  ffmpeg (including but not limited to MP4, MPG, M4V, MOV, WEBM, WMV, AVI, 3GP)
  into modern H265-encoded MP4 file. This will generally be smaller in file size
  and more widely playable than other video formats.
- [copyvid.sh](videos/copyvid.sh): Quick conversion of any file format to MP4.
- [fadevid.sh](videos/fadevid.sh): Add a fade-in and fade-out, both visually
  (from/to black) and audially (from/to silence) to a video clip.
- [joinvid.sh](videos/joinvid.sh): Combine videos.
- [markvid.sh](videos/markvid.sh): Add a watermark image to a video.
- [minvid.sh](videos/minvid.sh): Minify a video by re-encoding it and stripping
  metadata.
- [minsmvid.sh](videos/minsmvid.sh): Reduce video size even more than `minvid`,
  with second argument for bitrate.
- [stripvid.sh](videos/stripvid.sh): Strip metadata from a video.
- [trimvid.sh](videos/trimvid.sh): Trim MP4 videos with a starting timecode and
  a duration or stop timecode.
- 🌟 [vidcap.sh](videos/vidcap.sh): Create screencaps of a video, that is,
  individual images from different time codes of the video. (Not to be confused
  with video captioning.)

### Boilerplate code

A collection of patterns and snippets I use when writing scripts, many derived
from [William E. Shotts, Jr](https://linuxcommand.org/lc3_adv_standards.php).
See [boilerplate](boilerplate) for an overview.

### Test files

See [test](test) for sample files and sources.

## Usage

Download the script files you want. You might need to run `chmod +x *.sh` to
make them executable.

You can use them only in the folder in which they reside, or you can make them
system-wide. To do the latter, move them to `~/bin`. Then, if you're not doing
so already, [export](https://linuxhint.com/path_in_bash/) this directory to your
`PATH` in `.bash_profile`, `.bashrc`, `.zshrc`, etc.:

```sh
export PATH="$HOME/bin:$PATH"
```

If you wish, you can also add aliases for them, saving three whole characters!

```sh
alias minvid="minvid.sh"
```

## Dependencies

All scripts note any dependencies required.

I have tested these on Linux (Linux Mint, based on Ubuntu/Debian) using the
[Z Shell](https://zsh.sourceforge.io/), but they should run in any
Bash-compatible environment.

## Linting

All scripts have [shellcheck](https://www.shellcheck.net) run on them with every
save and are auto-formatted with [`shfmt`](https://github.com/mvdan/sh) using
the [Sublime Text plugin](https://github.com/soifou/sublime-shfmt).

# Other resources

You may also be interested in my
[local dotfiles](https://github.com/rootwork/dotfiles/tree/local-nix) (Linux),
which also has flavors in
[Mac](https://github.com/rootwork/dotfiles/tree/local-mac) and
[Windows](https://github.com/rootwork/dotfiles/tree/local-win), as well as a
[hosted (Linux) setup](https://github.com/rootwork/dotfiles/tree/hosted).

# License

GNU Affero General Public License v3.0 or later (AGPL 3+). See
[LICENSE](LICENSE).
