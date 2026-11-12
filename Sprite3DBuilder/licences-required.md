# Licences required

What the third-party parts of Sprite3DBuilder ask of anyone who builds or
distributes it, as of 12 November 2026. This is a map of what to check, not
legal advice.

The licences and notices a release must carry are text files in the
repository's `licences/`, shared with Sprite3D, linked into the program as
RCDATA resources (`licences/Sprite3DBuilderLicences.rc`, compiled by the
pre-build step), so every
build carries them. **File, Licences...** shows them, and its **Save All...**
writes them to one `THIRD-PARTY-NOTICES.txt` to ship beside the program.

## FastMM5: GPL v3, or a commercial licence

FastMM5 (the `FastMM5` submodule, <https://github.com/pleriche/FastMM5>) is
dual-licensed: free under the GPL v3, or under a commercial licence, which
lets it be used in your own applications royalty free, with no requirement to
disclose your source code.

It is compiled into every Windows build of Sprite3DBuilder
(`Sprite3DBuilder/Sprite3DBuilder.dpr`, `{$IFDEF MSWINDOWS}`), Release included.

- Under the GPL, distributing a Windows binary means releasing
  Sprite3DBuilder's whole source under the GPL v3.
- To keep it closed, or under another licence, either buy the commercial
  licence, or use FastMM5 only in Debug builds.

## Neon: MIT

Neon (the `delphi-neon` submodule, <https://github.com/paolo-rossi/delphi-neon>),
Copyright (c) 2015 Paolo Rossi, reads and writes `settings.json`.

- Keep its copyright and licence notice with every copy; for a binary, in its
  documentation or About box. **Done:** `licences/Neon-LICENSE.txt`, in File,
  Licences.

## Vampyre Imaging Library: Mozilla Public License 2.0

The Vampyre Imaging Library (the `imaginglib` submodule,
<https://github.com/galfar/imaginglib>), by Marek Mauder, reads textures in
formats the model loader does not read, such as layered `.psd` files, in
`Shared/Sprite3DModelTextures.pas`. It is compiled into every build, used
unmodified.

The MPL 2.0 is a file-level copyleft: it covers Vampyre's own files only,
not Sprite3DBuilder's.

- Distributing a binary: tell its recipients how to get the Source Code Form
  of the MPL files, and carry the licence. **Done:**
  `licences/Vampyre-LICENSE.txt` (a notice giving the source's address, then
  the licence), in File, Licences.
- Changing any of Vampyre's files would mean making the changed files
  available under the MPL; so leave the submodule unchanged, as the rules
  for submodules say.

## Spritely: Sprite3D's

Spritely, in this repository's `Spritely/`, is linked in as a runtime
package's units, and the units in `Shared/` are compiled in. They carry
whatever licence Sprite3D chooses; it has none yet.

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

## Model kits

Models opened in the program are not part of it. KayKit's Dungeon Pack, the
first kit it is meant for, is CC0 (public domain dedication): nothing is
required, though crediting Kay Lousberg is welcome.

## Sprite3DBuilder itself

The repository (Sprite3D's, which holds it) has no licence file, so by
default all rights are reserved.

## Notices still to add

FastMM5's notice is not in File, Licences: what it needs depends on the
licence chosen for it (see FastMM5 above).
