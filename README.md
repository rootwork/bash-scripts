# Bash scripts

[![License](https://img.shields.io/npm/l/mjml-bullet-list?color=brightgreen&style=flat-square)](https://github.com/premail/mjml-bullet-list/blob/main/LICENSE)

## Image manipulation

- [minpic.sh](images/minpic.sh): Minify JPEG and PNG images, losslessly, for the
  web.
- [webpjpg.sh](images/webpjpg.sh): Convert webp images to lossless PNG first,
  then to JPEG.

## Video manipulation

- [avimp4.sh](videos/avimp4.sh): Convert AVI to MP4. More thorough than ffmpeg's
  default process.
- [convertvid.sh](videos/convertvid.sh): Convert any video files readable by
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
- [minsmvid.sh](videos/minsmvid.sh): Reduce video size even more than minvid,
  with second argument for bitrate.
- [stripvid.sh](videos/stripvid.sh): Strip metadata from a video.
- [trimvid.sh](videos/trimvid.sh): Trim MP4 videos with a starting timecode and
  a duration or stop timecode.

## Usage

Install individual script files to `~/bin`. If you're not doing so already,
export this directory to your `PATH` in `.bash_profile`, `.bashrc`, `.zshrc`,
etc.:

```sh
export PATH="$HOME/bin:$PATH"
```

## Dependencies

All scripts note any dependencies required. Most image scripts require
[imagemagick](https://imagemagick.org/index.php) and most video scripts require
[ffmpeg](https://ffmpeg.org/).

I have tested these on Linux (Linux Mint, based on Ubuntu/Debian) using the
[Z Shell](https://zsh.sourceforge.io/), but they should run in any
Bash-compatible environment.

# Formatting

All bash scripts auto-formatted with [`shfmt`](https://github.com/mvdan/sh)
using the [Sublime Text plugin](https://github.com/soifou/sublime-shfmt).

# License

GPLv3. See [LICENSE](LICENSE).
