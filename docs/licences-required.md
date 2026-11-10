# Licences required

What the third-party parts of Sprite3D and Spritely ask of anyone who builds
or distributes them, as of 10 November 2026. This is a map of what to check,
not legal advice.

The licences and notices a release must carry are text files in
`licences/`, linked into the program as RCDATA resources
(`licences/Sprite3DLicences.rc`, compiled by the pre-build step), so every
build carries them. **File, Licences...** shows them, and its **Save All...**
writes them to one `THIRD-PARTY-NOTICES.txt` to ship beside the program.

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
  documentation or About box. **Done:** `licences/Neon-LICENSE.txt`, in File,
  Licences.

## FFmpeg headers: BSD-style

`src/ffmpeg` holds the FFmpeg Delphi/Pascal headers from DelphiFFmpeg.com,
unchanged and not compiled in; `src/lib/Sprite3DVideo.pas` copies the few
records and constants it needs from them.

- The notice in `src/ffmpeg/LICENSE.txt` stays with the source.
- Binaries reproduce it in their documentation. **Done:**
  `licences/DelphiFFmpeg-LICENSE.txt`, a copy, in File, Licences.

## OpenH264 declarations: BSD 2-clause

`src/lib/Sprite3DOpenH264.pas` translates declarations from OpenH264's API
headers, Copyright (c) 2013, Cisco Systems.

- The notice stays with the source: the unit reproduces it in full.
- Binaries reproduce it in their documentation. **Done:**
  `licences/OpenH264-BSD-LICENSE.txt`, from Cisco's `LICENSE`, in File,
  Licences.

## OpenH264 library: Cisco's binary licence, and where it comes from

Cisco's OpenH264 binary is covered by Cisco's AVC/H.264 patent licence from
MPEG LA, at no cost, if four conditions are met. Sprite3D never ships the
library, and meets each one:

1. **Downloaded separately, from Cisco, to the user's device.** Every address
   in the list at `https://sprite3d.com/openh264/openh264.json` is Cisco's own
   (`https://ciscobinary.openh264.org/...`), and Sprite3D downloads it at run
   time.
2. **The user can enable, disable and re-enable it.** File, Settings..., MP4
   video, **Use OpenH264 for H.264 MP4 video** (`useOpenH264`).
3. **"OpenH264 Video Codec provided by Cisco Systems, Inc."** is shown beside
   that tick box.
4. **The licence text is reproduced** where licensing information is shown:
   **Cisco Licence...** beside the tick box shows it in full, and
   [licences/OpenH264-BINARY_LICENSE.txt](../licences/OpenH264-BINARY_LICENSE.txt)
   holds it, word for word from openh264.org (v1.0).

Users receive the library under Cisco's binary licence, from Cisco.

## FFmpeg libraries: LGPL

The FFmpeg 8.1 shared libraries in the DLL pack
(`https://peardox.com/Sprite3d-dlls.zip`) are under FFmpeg's own licence, the
LGPL for the builds used. Sprite3D loads them at run time if present and never
links against them, which is the simple way to meet the LGPL. Anyone shipping
them still needs to:

- ship the LGPL text, and say the libraries are FFmpeg's (**done:**
  `licences/LGPL-2.1.txt`, FFmpeg 8.1's `COPYING.LGPLv2.1`, and
  `licences/FFmpeg-NOTICE.txt`, both in File, Licences);
- say where their source is, for the exact version, or offer it (**done**
  in `FFmpeg-NOTICE.txt`, for 8.1: if the DLL pack is a point release such
  as 8.1.2, change the version and the addresses there);
- leave users able to replace them with their own builds (separate shared
  libraries already allow this);
- use builds configured without `--enable-gpl` or `--enable-nonfree`, or the
  LGPL no longer applies. `FFmpeg-NOTICE.txt` says they are; check the DLL
  pack's builds really are (`ffmpeg -version` lists the configuration).

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

Every notice above is in File, Licences. FastMM5's is not: what it needs
depends on the licence chosen for it (see FastMM5 above). Under the
commercial licence nothing is needed; under the GPL v3, Sprite3D's own
licence and the GPL text would join the list.
