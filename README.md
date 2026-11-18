> **Unofficial fork.** This repository is an unofficial public fork of
> [Komet/MediaElch](https://github.com/Komet/MediaElch) and is licensed under
> [LGPL-3.0](COPYING). It is not affiliated with or endorsed by the upstream project.

<div align="center">
	<img alt="MediaElch Logo" src="data/img/MediaElch.png" />
</div>

[![codecov](https://codecov.io/gh/Komet/MediaElch/branch/master/graph/badge.svg)](https://codecov.io/gh/Komet/MediaElch)
[![Coverity](https://img.shields.io/coverity/scan/19171.svg)](https://scan.coverity.com/projects/komet-mediaelch)
![Jenkins](https://jenkins.ameyering.de/buildStatus/icon?job=bugwelle%2FMediaElch%2Fmaster)

# MediaElch

MediaElch is a MediaManager for Kodi. Information about Movies, TV Shows,
Concerts and Music are stored as `NFO` files.
Fanarts are downloaded automatically from fanart.tv.

- Documentation: <https://mediaelch.github.io/mediaelch-doc/about.html>
- Blog: <https://mediaelch.github.io/mediaelch-blog/posts/>
- Source Code: <https://github.com/Komet/MediaElch>

![MediaElch Movies](https://mediaelch.github.io/mediaelch-doc/_images/movie-main.png)


## Download

Official upstream builds are available at
<https://mediaelch.github.io/mediaelch-doc/download.html>.
Unofficial Windows builds from this fork are published under
[Releases](https://github.com/krrks/MediaElch/releases).


## Unofficial Windows builds

This fork builds Windows x64 binaries with the manually triggered
[`Build Windows release`](.github/workflows/build-release.yml) GitHub Actions
workflow. The artifacts are unsigned portable ZIP files.

Extract each ZIP into an **empty directory**. Do not unpack it over an existing
MediaElch installation: the official Windows builds are MinGW-based, and mixing
their Qt DLLs with this MSVC build makes the application fail to start.

Each release states the exact source commit it was built from and the changes
it contains. Changes in this fork so far:

- TMDb movie search no longer sends a duplicate `include_adult` query
  parameter, which TMDb rejected with HTTP 400 (upstream issue
  [#1992](https://github.com/Komet/MediaElch/issues/1992)). Includes a
  defensive guard and a regression test.
- Manual GitHub Actions workflow that builds, packages and publishes the
  Windows ZIP as a release.


## Documentation

Documentation is available at <https://mediaelch.github.io/mediaelch-doc/about.html>.


### Build Instructions

For build instructions, see: https://mediaelch.github.io/mediaelch-doc/contributing/build/index.html


### Developer Documentation

For testing MediaElch, have a look at our developer/contributor
documentation in [`docs/README.md`](docs/README.md).


## Support

We're active in the [Kodi forum](https://forum.kodi.tv/showthread.php?tid=136333)
and on [GitHub](https://github.com/Komet/MediaElch).
If you want to report a bug, please see
["Bug Reports"](https://mediaelch.github.io/mediaelch-doc/contributing/bug-reports.html).
