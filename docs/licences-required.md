# Licences required

What the third-party parts of Sprite3D and Spritely ask of anyone who builds
or distributes them, as of 9 November 2026. This is a map of what to check,
not legal advice.

## FastMM5: GPL v3, or a commercial licence

FastMM5 (the `FastMM5` submodule, <https://github.com/pleriche/FastMM5>) is
dual-licensed: free under the GPL v3, or under a commercial licence, which
lets it be used in your own applications royalty free, with no requirement to
disclose your source code. The commercial licence is perpetual, per developer:
$99 for one developer, more for teams, $999 for a site.

It is compiled into every Windows build of Sprite3D (`src/Sprite3d.dpr`,
`{$IFDEF MSWINDOWS}`), Release included, and into Spritely's ProjectionTest.

- Under the GPL, distributing a Windows binary of Sprite3D means releasing
  Sprite3D's whole source under the GPL v3, Spritely's with it, as it is
  linked in.
- To keep either closed, or under another licence, either buy the commercial
  licence, or use FastMM5 only in Debug builds, so Release builds use Delphi's
  own memory manager.

## Neon: MIT

Neon (the `delphi-neon` submodule, <https://github.com/paolo-rossi/delphi-neon>),
Copyright (c) 2015 Paolo Rossi, reads and writes `settings.json`.

- Keep its copyright and licence notice with every copy; for a binary, in its
  documentation or About box.

## FFmpeg headers: BSD-style

`src/ffmpeg` holds the FFmpeg Delphi/Pascal headers from DelphiFFmpeg.com,
unchanged and not compiled in; `src/lib/Sprite3DVideo.pas` copies the few
records and constants it needs from them.

- The notice in `src/ffmpeg/LICENSE.txt` stays with the source.
- Binaries reproduce it in their documentation.

## OpenH264 declarations: BSD 2-clause

`src/lib/Sprite3DOpenH264.pas` translates declarations from OpenH264's API
headers, Copyright (c) 2013, Cisco Systems.

- The notice stays with the source.
- Binaries reproduce it in their documentation.

## OpenH264 library: Cisco's binary licence, and where it comes from

Cisco pays the H.264 patent royalties only for copies of its OpenH264 binary
downloaded directly from Cisco. Sprite3D never ships the library: it downloads
it at run time from the addresses in the list at
`https://sprite3d.com/openh264/openh264.json`.

- **To change:** the list's entries point at files hosted on sprite3d.com. A
  copy served from there is not covered by Cisco's patent licence, which would
  make sprite3d.com the distributor of an H.264 encoder without that cover.
  Point every entry at Cisco's own downloads
  (`https://ciscobinary.openh264.org/...`), which publishes the same `.bz2`
  files; Sprite3D reads any address, so no code changes. (Owner, 9 November
  2026: the addresses will be changed to Cisco's.)
- Users receive the library under Cisco's binary licence, from Cisco.

## FFmpeg libraries: LGPL

The FFmpeg 8.1 shared libraries in the DLL pack
(`https://peardox.com/Sprite3d-dlls.zip`) are under FFmpeg's own licence, the
LGPL for the builds used. Sprite3D loads them at run time if present and never
links against them, which is the simple way to meet the LGPL. Anyone shipping
them still needs to:

- ship the LGPL text, and say the libraries are FFmpeg's;
- say where their source is, for the exact version, or offer it;
- leave users able to replace them with their own builds (separate shared
  libraries already allow this);
- use builds configured without `--enable-gpl` or `--enable-nonfree`, or the
  LGPL no longer applies.

## Gorilla3D: commercial

Gorilla3D (<https://gorilla3d.de/>) is licensed per developer by its author.
Your licence covers using its runtime in your applications.

- Check its terms on redistributing the runtime packages, and on Spritely's
  packages, which are built against it.

## RAD Studio: the FMX styles and runtime

The four theme styles (`Dark`, `AquaGraphite`, `RubyGraphite`,
`GoldenGraphite`) come from RAD Studio's `Redist\styles\Fmx` folder and are
linked into the program as resources.

- They, and the Delphi runtime, are redistributable as part of an application
  under your RAD Studio licence.

## Sprite3D and Spritely themselves

The repository has no licence file, so by default all rights are reserved:
the code can be read on GitHub, but nobody has the right to reuse it.

- If one is chosen, the FastMM5 choice above decides it for any Windows build
  that includes FastMM5 under the GPL.

## Notices still to add

None of these notices is in the program or its documentation yet:

- Neon's MIT notice;
- the DelphiFFmpeg.com BSD notice;
- Cisco's BSD notice for the OpenH264 declarations;
- for builds shipped with the DLL pack, the LGPL text and FFmpeg's source
  details.

An About box, or a notices file shipped beside the program, would carry them.
