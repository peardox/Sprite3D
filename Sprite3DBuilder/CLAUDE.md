# Sprite3DBuilder: handover notes for Claude

Everything Claude needs to pick this project up in a new conversation: how
the owner works, the rules for the code, and where the work has got to.
`README.md` (beside this file) describes the program for its users and
developers; this file is for Claude. Read both.

**Sprite3DBuilder lives in the Sprite3D repository**, in its
`Sprite3DBuilder/` folder (owner, 12 November 2026; it had a repository of
its own, peardox/Sprite3DBuilder, until then, which the owner is
retiring). Paths here are from that repository's root. The repository's
own `CLAUDE.md`, at its root, holds the rules for the whole repository,
Sprite3D's and the shared units' included; where this file and that one
differ on a rule for the repository as a whole, that one wins.

Last updated: 12 November 2026, 11:05.

## Starting a new conversation

1. Clone the repository with its submodules:
   `git clone --recurse-submodules https://github.com/peardox/Sprite3D.git`
   (branch `main`). Its submodules (`delphi-neon`, `FastMM5`, `imaginglib`,
   the Vampyre Imaging Library) serve both programs.
2. Read the root's `README.md` and `CLAUDE.md`, then
   `Sprite3DBuilder/README.md` and this file.
3. Sprite3DBuilder grew out of Sprite3D, whose `CLAUDE.md` holds the
   history and the lessons behind the code kept here, and whose `notes/`
   explain the camera fit and the volumes (`volumes.md`) and the texture
   fixes (`textures.md`). Spritely, the camera components, is in the same
   repository. Read those when touching the same code.
4. The owner's working copy is often ahead of GitHub. If the owner attaches
   or pastes files, build on those, not on GitHub.
5. Before delivering code, run `python3 tools/pasdoc_check.py` on the files
   you changed and fix anything it reports in your own changes.

Reference for the libraries used:

- Gorilla3D 1.5.4: <https://gorilla3d.de/doc/v3/version/v1.5>, with further
  notes at <https://peardox.com/G3D/>.
- Neon, the JSON serialiser: <https://github.com/paolo-rossi/delphi-neon>.
- FastMM5: <https://github.com/pleriche/FastMM5>.
- Vampyre Imaging Library: <https://github.com/galfar/imaginglib>; its
  formats and options are in `Source/ImagingOptions.inc`.
- PasDoc: <https://pasdoc.github.io/>.

## How the owner works

- Delphi 13 (RAD Studio), FireMonkey. Develops on Windows; also builds and
  runs on macOS (Intel and Apple silicon, through PAServer) and Linux
  64-bit. Android and iOS are targets too.
- Works from a local copy and pushes to GitHub only when happy with the
  results.
- Tests promptly and pastes back the Debug tab, terminal output or
  screenshots. Logs are the main evidence, so make Debug tab lines say
  exactly what happened, and say in the reply what to look for.
- Likes plain explanations of why something behaves as it does, and
  measured numbers rather than guesses. Say plainly when an earlier
  conclusion was wrong.

### Delivering work

These rules apply to this repository as to the owner's others (brought in
line with peardox/SRDelphiFMX's on 8 November 2026).

- **Never supply patches or diffs.** The owner will not use them. Supply
  whole files.
- When supplying files as a zip, put **only the files new or changed since
  the previous zip** in it, with paths from the repository root, so it can
  be unzipped straight over the working copy. Name the files in the
  reply, and say which earlier zip it follows or replaces.
- **Zip names say what is in them** (owner, 11 November 2026): the date
  and time, then a few words for the change, lower case with hyphens,
  such as `2026-11-11-1305-zip-naming-rule.zip`, so they sort in order and
  can be told apart at a glance. Each name must sort after the one
  before it: if the clock would give an earlier time than the last zip's
  name, as happened on 11 November, use a later one. The `BuilderNx` names of before (up to
  Builder3zj) are not used any more; refer to a zip by its full name.
- **Files to delete or rename** cannot travel in a zip: list them in the
  reply with the git commands (`git rm ...`, `git mv ...`).
- **Package rebuilds**: a change Sprite3DBuilder needs in Spritely is made
  under Spritely's rules (the root's `CLAUDE.md`), with its rebuild line,
  `====> NO PACKAGE REBUILD <====` when nothing needs it.
- **Do not mention being unable to compile.** That is already known.
- **Do not mention that nothing is committed or pushed.** The owner pushes
  when ready. Do not commit or push unless asked. When a hook asks to
  commit and push, answer "Noted." and do nothing.
- No paths, user names, machine names or credentials in tracked files.
- Update `README.md`, and the design notes it links to, when a feature,
  setting or requirement changes, and this file when the state of the work
  or the rules change; include them in the zip when they do.
- **The generated help in the repository's `docs/` is the owner's**: they
  rebuild it with PasDoc (`tools/pasdoc.bat`, which builds this program's
  reference too) only now and then, after a major milestone. Never change
  or regenerate it. `Sprite3DBuilder/licences-required.md` is hand-written
  and kept up to date: change it, with the README's Licences, whenever a
  dependency, its licence or how it is shipped changes. The PasDoc
  comments in the source are still written with the code, ready for the
  next rebuild.
- When something needs testing, say what to try and what the result should
  look like, on which platforms.

## The repository

- Honour `.gitignore`, `.gitmodules` and the other `.git*` files. Never add
  build output or other ignored files.
- Neon, FastMM5 and Vampyre (`imaginglib`) are the repository's
  submodules, at its root: never copy their sources into the project, and
  never change them.
- **Spritely** is in the repository's `Spritely/`, built and installed from
  `Sprite3DGroup.groupproj`. Sprite3DBuilder uses the built package, whose
  DCUs go to Delphi's Dcp folder, so it needs no search path for them. No
  Spritely unit may use a Sprite3DBuilder one.
- The project is `Sprite3DBuilder/Sprite3DBuilder.dproj`, in
  `Sprite3DGroup.groupproj` after Sprite3D (`Sprite3DBuilderGroup.groupproj`
  is gone). A new unit goes in both the `.dpr`'s
  `uses` and the `.dproj`; keep the `.dproj` as it is otherwise (it has a
  UTF-8 byte order mark; keep it, and the `.groupproj`'s).
- `assets/`, off the repository's root, holds the model kits the builder
  uses, one folder per kit (`assets/kaykit/dungeon`, glTF, so far); git
  ignores it (owner, 10 November 2026, 21:59). Never add anything from it.
  It and `icons/groups` are at the root, not in `Sprite3DBuilder/`, as the
  program looks for them three folders above its executable
  (`GetAssetsPath('../../../')`), the root from
  `Sprite3DBuilder/<platform>/<config>`.
- The repository's `tools/` holds scripts for working on the source, such
  as `pasdoc_check.py` (both programs) and `make_group_icons.py`. They are
  not part of the program.
- `Sprite3DBuilder/licences-required.md` is hand-written: change it, with
  the README's Licences, whenever a dependency, its licence or how it is
  shipped changes.
- **Licences**: the texts are in the repository's `licences/`, shared with
  Sprite3D; this program's are named in `licences/Sprite3DBuilderLicences.rc`,
  compiled into `Sprite3DBuilderLicences.res` by `buildlicences.cmd`, which
  `Sprite3DBuilder/styles/buildstyles.cmd` calls with that name. Its own
  `Sprite3DBuilder/lib/Sprite3DLicences.pas` lists them.

### Layout

- `Sprite3DBuilder/lib`: this program's own reusable units,
  **independent of the application**: `Sprite3DAssetCache`,
  `Sprite3DModelContent`, `Sprite3DGroupIcons` and `Sprite3DLicences` (its
  own list). They must not use anything in `Sprite3DBuilder/ui`, and must
  not know about the main form, `settings.json` keys or menus.
- `Shared/`, at the repository's root: **the units both programs use**
  (owner, 12 November 2026), named in the `.dpr` and `.dproj` as
  `..\Shared\<unit>.pas`: the grid, swept volumes, off-screen grabs,
  backgrounds, resampling, settings storage, styles, title bars, the
  folder dialog, `Sprite3DAnimFrames`, `Sprite3DModelTextures`, and the
  helpers `OSPaths`, `JsonText`, `GpuPreference`, `DisplayData`. Until
  then `Sprite3DBuilder/lib` and `common` held copies of them. Never copy
  one back. The rules for them are in the root's `CLAUDE.md`, *The
  repository*: a shared unit knows neither program; **where the programs
  need different things of it, the shared unit holds an abstract base
  class and each program a subclass of its own** (owner); and a change to
  one is checked against both programs and noted in both handovers.
- `Sprite3DBuilder/ui`: the forms and the application's own rules. Non-visual
  application logic (settings, the assets folder, themes) goes in
  `Sprite3DBuilderHelpers.pas`, not in a form.
- `Sprite3DBuilder/styles`: the theme styles, compiled into a resource by the
  pre-build event `buildstyles.cmd`, which also builds `licences/`.

## Code rules

### Names and trademarks

- **Peardox is the owner, not a product.** The products are Sprite3DBuilder,
  Sprite3D and Spritely.
- **No trademarks in names, UI, logs, comments or docs** (owner,
  8 November 2026): describe what a thing is, never name it after a
  product or game that used it (Spritely's projection kinds are named for
  the projection). Names of the libraries used (Gorilla3D, Neon, FastMM5, Vampyre)
  and of the platforms are fine. A model kit's name (KayKit) is fine in
  conversation and in the README's notes on testing, never in code names.

### Cross-platform

- The program targets Windows (64-bit and ARM64EC; Gorilla3D, and so
  Spritely, for ARM64EC from 8 November 2026), macOS (Intel and
  Apple silicon), Linux 64-bit, Android (32 and 64-bit) and iOS. **Keep it
  cross-platform as far as possible.** Windows 32-bit is built only to
  make the design-time packages for the owner's 32-bit IDE; nothing is
  released for it (owner, 9 November 2026), so a Win32-only concern
  matters only for what runs in the IDE at design time.
- No platform-specific unit or call without `{$IF}` alternatives for the
  other platforms, so every platform still compiles. The conditions used
  are `MSWINDOWS`, `MACOS`, `IOS`, `ANDROID` and
  `{$IF DEFINED(LINUX) and not DEFINED(ANDROID)}` for desktop Linux.
  Remember that macOS and iOS both define `MACOS`.
- Desktop-only features (file dialogs, right-click, Open With) need a
  mobile alternative or are left out there, and the README says so.
- Prefer pure Pascal to native libraries that need deploying; there are
  none.
- Calls into the Objective-C runtime on macOS go through `objc_msgSend`
  declared with the exact argument types of each call, as in
  `Sprite3DTitleBar`. Apple silicon needs this; never call it through a
  variadic declaration.

### Files and paths

- **Every path the program opens or writes goes through `OSFriendlyPath`**
  (`common/OSPaths.pas`) first. Some Windows targets, such as ARM64EC,
  reject `/`, and paths kept in `settings.json` may be read on another
  system.
- Per-user files go in the settings folder (`AppDataFolder` in
  `Sprite3DStorage`, `TSprite3DAppSettings.SupportFolder`), never beside
  the executable.
- Write files that matter atomically where practical: write a temporary
  file, then move it into place, as `TSprite3DJsonSettings.Save` does.
- Saves that take time run on worker threads (see *Threads*); the main
  form waits for them as it closes (`FSaveTasks`).

### JSON and settings

- Sprite3DBuilder keeps Neon for `settings.json`, as Sprite3D does.
  SRDelphiFMX's rule of `System.JSON` and no Neon is for Spritely, which
  must not depend on Neon.
- `settings.json` is read and written by **Neon**, through
  `TSprite3DJsonSettings` (`lib/Sprite3DStorage.pas`) and its descendant
  `TSprite3DAppSettings` (`ui/Sprite3DBuilderHelpers.pas`). A new setting is a
  published property there, with a default set in the constructor, a
  `[NeonProperty('...')]` attribute where its key differs from what Neon
  makes of the name, and a row in the README's table of what is kept.
  Settings must survive a file without the key (old files), keeping the
  default.
- Other JSON (metadata, directions files, animation settings, project
  files, caches) is built with `System.JSON` objects and written through
  `JsonToText` or `JsonToBytes` (`common/JsonText.pas`), so File,
  Settings, Minify JSON applies to every file. Never format JSON by hand.
- When reading JSON from outside (files the user picks, downloads), check
  every value's type and range; a bad file must give a clear message, not
  an access violation.

### Threads

- Gorilla3D, FMX controls and the viewport are touched **only on the main
  thread**. Worker threads (`TTask`) do pure work, such as reading a model
  file ahead of Gorilla3D's load (`StartModelFileRead`).
- Hand results back with `TThread.Queue` (or `ForceQueue` when already on
  the main thread but inside a render or event that must finish first).
- Anonymous methods capture variables, not values. When queuing from a
  loop, pass the values to a method as parameters instead of capturing the
  loop variables.
- Long-running work can be aborted, and the form waits for anything still
  writing a file before it closes, so no file is left half written.

### Menus

- The main menu is `MainMenu1` in `Sprite3DBuilderMain.fmx`. On Android and iOS
  it is shown through a hamburger drawer built from it
  (`BuildMobileMenu`), so menu items added in code must be in place before
  that runs. On desktop Linux it is replaced by an FMX `TMenuBar`
  (`UseFmxMenuBar`), **first thing in `FormCreate`**. Both recurse, so a
  third menu level (View, Projection, Oblique) is copied too.
- **Linux: copy, never move.** GTK's native menu bar shows only the first
  letter of each item, so the items are copied onto a `TMenuBar`, the
  originals freed one at a time, `MainMenu1` freed, and each copy given its
  original's name so the form's fields point at it. Moving the original
  items, or freeing `MainMenu1` with items still in it, gives
  `Gtk-CRITICAL` warnings, a crash in `libgobject-2.0.so.0`, or GTK's bar
  of first letters still showing. Read the comment above `UseFmxMenuBar`
  before touching it.
- So: reach designed menu items only through the form's published fields;
  never keep a reference to one taken before the swap; add run-time items
  after it, through the published fields (`ModelMenu.InsertObject(...)`).
  `CopyItem` copies `Text`, `Enabled`, `Visible`, `AutoCheck`,
  `IsChecked`, `RadioItem`, `GroupIndex`, `ShortCut`, `Tag`, `Hint` and
  `OnClick`. If a `TMenuItem` in the `.fmx` starts using any other property
  (`Bitmap`, `Action`, `StyleLookup`, another event), add it there.
- FMX unticks only a radio item's siblings, so a radio group spread over
  two menu levels (Projection and its Oblique submenu) is ticked by hand:
  `CheckProjection` ticks one and unticks the other five.
- Any other form that gains a `TMainMenu` needs the same swap on Linux.

### User interface

- Forms must not have their own `StyleBook`, so the theme set through
  `TStyleManager` reaches them. Colours a control paints for itself must
  read well on the light default and the dark themes.
- To add a theme: put the `.style` file name in `buildstyles.cmd`'s list,
  add an `RCDATA` line to `Sprite3DBuilder/styles/Sprite3DThemes.rc`, then a value to
  `TSprite3DTheme` and its row in `THEMES` in `Sprite3DBuilderHelpers.pas`.
- FMX lays out controls with the same `Align` (all `Top`, say) in the order
  of their positions. When adding or resizing one, set `Position` so they
  stay in order (`Position.Y := -1` puts a top-aligned control first).
- Dialogs: Android cannot block on a modal form, so a dialog that must work
  there uses the callback form, `ShowModal(procedure(AResult:
  TModalResult) ...)`, as Sprite3D's Exact and Overscan warnings do. Plain
  `ShowModal` is only for desktop-only features.
- Start-up is quick on purpose: `FormCreate` builds, `FormShow` queues the
  first model load so the window is drawn first. Keep new start-up work out
  of the way of that, and never open a dialog
  on top of the loading dialog.
- Problems, results and anything the owner may need to paste back go in
  the Debug tab (`DebugMemo`), whether or not a dialog also says so.
- `Format` in Delphi has no `+` flag: a signed number is written with
  `FormatFloat` and a three-part format such as `'+0.00;-0.00;+0.00'`
  (`SIGNED_FORMAT` in `Sprite3DBuilderOrbitalForm`).

### Documentation in the code

- **Document all code in PasDoc format.** The help is built with
  `pasdoc --staronly --auto-abstract`, so only `//**` comments reach
  PasDoc. Every unit, type, constant, field (private ones included),
  method and property gets a `//**` comment immediately before it,
  starting with `@abstract(...)` where it needs more than one line, and
  using `@param`, `@returns`, `@raises`, `@code` and `@link` as needed.
  - Fields declared one after another may share one comment.
  - Attributes such as `[NeonProperty('...')]` may sit between the comment
    and the item.
  - `@link` only to items declared in this project; write inherited or
    library items (`ShowModal`, `TGorillaModel`) with `@code`, as PasDoc
    cannot resolve them.
  - Escape brackets in PasDoc text as `@(` and `@)`.
  - Nested routines and items declared only in the implementation are
    documented too, with `//**` like the rest, though PasDoc does not
    publish them.
- Each unit starts with its `//**` description, then `unit Name;`, then the
  same description again as a plain `{ }` block comment for people reading
  the source. Keep the two in step.
- Comments explain **why** as well as what, especially where code works
  round a bug or a platform quirk, so nobody "simplifies" it back.
- Older code has gaps (mostly private methods and fields with no comment
  or a plain `//` one), most of them in `Sprite3DBuilderMain.pas`. Code you write
  or change must be clean; fill the gaps in a unit you are working on when
  it is cheap to do so, and offer a clean-up pass rather than doing one
  unasked. Do not add to the gaps.

### Source files

- **Source files are ASCII only.** Delphi reads a file without a byte order
  mark as ANSI, so write characters such as the degree sign as character
  codes (`#176`, `#$00B0`), in comments too spell them out ("degrees").
  A file that already has a UTF-8 byte order mark (the `.dproj` and
  `.groupproj` files) keeps it.
- Line endings and indentation as in the file being edited (two spaces).
- Naming: fields `F`, parameters `A`, types `T`; units in `Sprite3DBuilder/lib`
  `Sprite3D*.pas`, under the same names as Sprite3D's copies (a new one may
  be `Sprite3DBuilder*.pas`); the application's units in `Sprite3DBuilder/ui`
  `Sprite3DBuilder*.pas`, forms `Sprite3DBuilder*Form.pas` with their
  `.fmx`. Types keep Sprite3D's `TSprite3D...` names in both, so code moves
  between the two repositories unchanged.
- Delphi requires every field of a class section before its first method
  or property (E2169).

### Checking the source

The repository's `tools/pasdoc_check.py`, run from its root, checks the
units of both programs (`lib`, `ui` and the `.dpr` of each) and `Shared/`:

```
python3 tools/pasdoc_check.py                      every unit
python3 tools/pasdoc_check.py Sprite3DBuilder/ui/Sprite3DBuilderMain.pas   just these files
python3 tools/pasdoc_check.py --summary            counts per file
```

It reports files that are not ASCII, units with no `//**` `@abstract`,
interface items with no comment or only a plain `//` one, unbalanced
`@tag(...)` brackets, `@link` targets that do not exist, and fields after a
method or property (E2169). It is a heuristic, not a parser. The only
problems it should report are the older gaps described above; run
`--summary` before and after a change to see that the counts have not
gone up.

## Gorilla3D and FMX notes

- Gorilla3D renders through OpenGL on Windows, Linux and Android, and
  Metal on macOS and iOS. On Metal a material's SurfaceShader is not
  supported, so `Sprite3DGrid` draws the grid there as one thin plane per
  line, 20 cells each side, without the fade.
- There is no background: the viewport's own colour, with the floor grid in
  the scene. Sprite3D's 2D background behind a transparent viewport, and its
  off-screen pass, were left out.
- A Gorilla3D model is only posed while it can be drawn, so measuring an
  animation's volumes shows the model being measured (Sprite3D's
  `notes/volumes.md`). Sprite3DBuilder measures none: every model is shown
  in its rest pose, and `Sprite3DSweep`'s animation measurer, with
  `Sprite3DAnimFrames`, is kept only for when animations come back.
- The azimuth, as Sprite3D's, as the readouts and the fixed views give it, is 0
  at south and grows clockwise seen from above (45 is south-west,
  Isometric); `ApplyAngles` reverses it for the camera, and the mouse
  view's readout runs the same way as the dials.
- Lessons from StereoModel, where Spritely was built: load a model by
  making it (`TGorillaModel.Create(Viewport)`) and calling its
  `LoadFromFile`, as Sprite3DBuilder does, never the class function
  `TGorillaModel.LoadNewModelFromFile`, which in 1.5.3 never frees the FBX
  loader's parse tree; the viewport sends its free notification before it
  frees its children, so a component must let go of the camera and light
  on that notice and never touch them again (`TSpritelyOrbitalCamera`
  does); `MakeScreenshot` shows the `RenderManual` before the last, so
  render twice before a screenshot that must show a change; FMX's
  perspective is D3D-style (depth 0..1) with NDC y up, and a projection
  written into the context stays until FMX makes it again (resize, lens
  change).
- With `REPORT_LEAKS` defined in the `.dpr`, FastMM5 on Windows writes the
  full leak report to `Sprite3DBuilder_MemoryManager_EventLog.txt` beside
  the executable. A leak introduced by a change shows up there.

## Where the work is

### Handover (12 November 2026, 11:05)

Read this first; the dated entries below it are the history. **Paths in
them are from before the move: `src/` there is `Sprite3DBuilder/` now,
and the units that were in `src/lib` and `src/common` but are not in
`Sprite3DBuilder/lib` are in the repository's `Shared/`.**

- **Moved into the Sprite3D repository** (owner, 12 November 2026, 10:49),
  as `2026-11-12-1105-one-repository.zip`, not yet applied or tested; the
  root's `CLAUDE.md` (*State (12 November 2026, 11:05)*) has the git
  commands and the full list. From this repository's GitHub `f6de00d`
  ("Notes"):
  - `src/` is `Sprite3DBuilder/`, without the shared units; this file,
    `README.md` and `docs/licences-required.md` (as `licences-required.md`)
    beside it;
  - the shared units are the root's `Shared/`. Of the two that differed
    from Sprite3D's, `Sprite3DOffscreen` is this program's (with `Poll`,
    `StateText`, `PostStep`), and `Sprite3DSweep` is Sprite3D's (this
    program's plus the bounding box outline and volumes drawn into grabs,
    which this program never makes, so its thumbnails are unchanged);
  - `icons/groups`, `assets/` (ignored), `tools/make_group_icons.py` and
    the licence texts are at the root; `licences/Sprite3DLicences.rc` and
    `.res` are `Sprite3DBuilderLicences.rc` and `.res`, built by
    `buildlicences.cmd Sprite3DBuilderLicences`; the `.dpr` links
    `..\licences\Sprite3DBuilderLicences.res`;
  - the submodules are the root's: FastMM5 at `4bf8480` (this repository
    had `aefe89d`), Neon and Vampyre at the same commits as before;
  - `Sprite3DBuilderGroup.groupproj` is gone: the project is in
    `Sprite3DGroup.groupproj`, after Sprite3D.
- **To test**: the group builds; the Library opens, finds `assets/` and
  the group icons, and makes thumbnails as before, the textured kits
  (Zerin, Quaternius) included; File, Licences lists Neon and Vampyre.
- Before this, `Sprite3DOffscreen.pas` differed from Sprite3D's (below, 11
  November): settled, as both use this program's version.

### Handover (11 November 2026, 13:00)

Read this first; the dated entries below it are the history.

- **GitHub `main` is at `e593757`** ("Vampyre", 13:08): Builder3zj,
  `2026-11-11-1305-zip-naming-rule.zip` and the `imaginglib` submodule (at
  `484feed`), checked file by file. **Builder3zj** had: **Rescan All Collections**
  on the artist's **...** menu (`RescanArtistItemClick`: every collection
  of the artist shown queued through `NextBulk` with `FBulkRescan`, so
  `OpenCollection(Id, True)` scans each again); a **session error log**,
  `library-errors.log` in the settings folder (`TAssetsForm.ErrorLogFile`),
  begun by `TAssetsForm.BeginErrorLog` from the main form's `FormCreate`
  and only added to after that: every error goes through `LogError`, which
  tags it `[Artist / Collection]`, and `StartImportLog` / `NextBulk` /
  `StopBulk` / Rescan put `---` lines round each run; the summary of an
  artist import or rescan gives its error count (`FRunErrors`); and the
  "thumbnails made" line counts only those made (`FMadeCount`), with how
  many failed. The owner tested it (12:51-12:54): Kenney's 46 collections
  rescanned with 0 errors, Zerin's 13 with the same 529 as before, each
  tagged with its collection.
- **Zips are named for what they hold from now on** (see *Delivering
  work*); the first is `2026-11-11-1305-zip-naming-rule.zip`, which
  follows Builder3zj. "Builder4" is still the name of the stage that
  places models on the level, not of a zip.
- **Textures, `2026-11-11-1320-psd-textures-vampyre.zip`** (follows
  `2026-11-11-1305-zip-naming-rule.zip`). The owner's import of Zerin's
  packs failed 529 models, all `AssetsManager.TextureAsset - unsupported
  file format ".psd"`, all in the four text-glTF packs (Retro-Atlantis,
  Cave, Clocktower, Pyramid); every `.glb` pack loaded. Gorilla3D rejects a
  texture by its extension. The `.gltf` files name PSDs that are there
  (`atlas_retroAtlantis_varB_v00.psd`, `atlas_retroAtlantis_props_v00.psd`),
  some with no PNG of any similar name, so guessing names cannot work. The
  owner's rules: a **general** fix, not tied to any pack; **the extension
  asked for is used whenever possible**: the file named first (converted if
  need be), a file of the same name with another extension only if the one
  named is not there or cannot be read. Built as
  `src/lib/Sprite3DModelTextures.pas` (`PrepareModelTextures`, called from
  `TAssetsForm.LoadEntryModel`, reported by `ReportTextures`): PNG and JPEG
  used as they are, anything else made a PNG (8 bits a channel, alpha) by
  the **Vampyre Imaging Library**, the `imaginglib` submodule (owner added
  it, 13:07), in `<cache>/textures/<sha256 of source>.png`; if anything was
  changed, the model is loaded from `<cache>/models/<key>.gltf`.
  **Gorilla3D does not take a full path in a glTF `uri`**: the owner's
  first test (13:12) failed with `buffer file "E:\...\x.bin" not found
  (model "...\thumbnails\models\<key>.gltf")`, the file being there. It
  looks for every file in the glTF's own folder. So
  `2026-11-11-1325-gltf-copy-files-beside.zip` copies every file the copy
  names (buffers, textures used as they are, PNGs made) into
  `<cache>/models`, named after the SHA-256 of its content (`CopyIn`; a
  PNG made, after its source), and every uri is a bare file name. The
  `<cache>/textures` folder of the first try is not used.
- **Black textures, `2026-11-11-1340-psd-alpha-remake-thumbnails.zip`**
  (follows `2026-11-11-1325-gltf-copy-files-beside.zip`). With the copy
  loading (13:21), the PSD textures came out black with coloured specks:
  Vampyre's `ImagingPsd` takes any channel after the colour ones for alpha,
  but in a PSD those are saved selections and masks unless the layer count
  is negative (then the first is the merged image's transparency). Alpha 0
  became black through FMX's premultiplied bitmaps. `MergedAlpha` in
  `Sprite3DModelTextures` reads the layer count (layer info, or the
  `Lr16`/`Lr32`/`Layr` tagged block at 16/32 bits; 8-byte lengths for
  `.psb`) and `MakePng` saves opaque RGB unless it is negative. Made PNGs
  are named `<sha>.v2.png` (`MADE_PNG_VERSION`), so the bad ones are never
  used; bump it whenever conversion changes. Thumbnails already made stay
  cached, so the zip adds **Remake Thumbnails** (collection menu) and
  **Remake All Thumbnails** (artist menu): `OpenCollection(Id, True, True)`
  sets `FRemaking`, which `HashesDone` uses to ignore the cache; the artist
  one shares `StartArtistRun` with Rescan All Collections (`FBulkRemake`).
- **Preview background, `2026-11-11-1350-preview-background.zip`**
  (follows `2026-11-11-1340-psd-alpha-remake-thumbnails.zip`; owner: the
  checker does not always work, add black and a way to choose). A
  drop-down over the preview's top right (`FBackgroundCombo`): Checker,
  Black, Grey, White (`PREVIEW_BACKGROUNDS`), shown through
  `TSprite3DBackground` (Transparent or Solid); kept as
  `previewBackground` in `settings.json` (`TSprite3DAppSettings`), passed in
  by the main form's `OpenLibrary` and saved through `OnPreviewBackground`.
  The floor grid turns light on black and grey (`PreviewGridColour`).
  Thumbnails are unaffected: always grabbed transparent.
- **24-bit PNGs, `2026-11-11-1400-png-always-argb.zip`** (follows
  `2026-11-11-1350-preview-background.zip`). The opaque PNGs of the alpha
  fix were saved as 24-bit RGB, and FMX's OpenGL context on Windows would
  not make textures of them: `cannot create texture by
  TContextOpenGLWindows (Error = 1282)` (owner, 13:30). `MakePng` now goes
  through `ifR8G8B8` (dropping the extra channels) and back to
  `ifA8R8G8B8` (Vampyre sets alpha 255), so every PNG made is 32-bit;
  `MADE_PNG_VERSION` is `.v3`. Rule: **never hand the loader a 24-bit
  PNG.**
- **Thumbnail check, `2026-11-11-1410-check-thumbnails.zip`** (follows
  `2026-11-11-1400-png-always-argb.zip`; owner: there may be other problems
  we cannot see; a thumbnail completely transparent is a problem, almost
  completely transparent may be; a log is enough to start with, triggered
  from the File menu for now). **File, Check Thumbnails**
  (`TMainForm.CheckThumbnailsItemClick`, through `EnsureAssetsForm`, which
  `OpenLibrary` now uses too) calls `TAssetsForm.CheckThumbnails`: every
  model of every collection, each key measured once (`MeasureVisible`:
  share of pixels with alpha >= `CHECK_VISIBLE_ALPHA` (32), and the highest
  alpha); verdicts missing, empty (0 visible), nearly empty (<
  `CHECK_NEARLY_EMPTY`, 1%), good. Report `library-thumbnail-check.log`
  (`ThumbnailCheckFile`), worst first; summary to the Debug tab. Main
  thread, `ProcessMessages` every 50. The thresholds are guesses: tune
  them from the owner's first report.
- **Textures in other folders, `2026-11-11-1420-texture-search-wider.zip`**
  (follows `2026-11-11-1410-check-thumbnails.zip`). A Quaternius Godot
  model (`...\Medieval\Meshes\10_Beehive.gltf`) names `Cards_Atlas.png`,
  which is not beside it. `ResolveTexture` now searches, after the file
  named: the same file name (case ignored), then only after that the same
  name with another extension, each nearest first through `TextureSearch`:
  the folder named and the model's, then the tree of each of the model
  folder's parents up to `SEARCH_LEVELS_UP` (3), never one
  `TooHighToSearch` (a disk's root or a folder in it), nor a tree of more
  than `TREE_FILE_LIMIT` (100,000) files. `FolderImages` lists image files
  (`IsImageFile`: PNG, JPEG or anything Vampyre reads) and keeps each
  listing `LISTING_KEEP_MS` (5 minutes) in the unit's `Listings`, freed in
  its finalization. `ReportTextures` gives full paths of files found
  elsewhere.
- **Choosing a pack's folders, `2026-11-11-1430-artist-import-choose-folders.zip`**
  (follows `2026-11-11-1420-texture-search-wider.zip`). The owner found the
  real cause of the Beehive error: Quaternius's Card Kit holds sample
  engine projects whose glTFs name textures kept elsewhere, and the artist
  import took those folders along with the pack's own. Owner's rule: when
  a pack has more than one folder of the format taken, ask which; tick the
  one with the most models; with only one, just proceed. In
  `AddArtistButtonClick`, the folders of format `Pick` (`SameFormat`) go to
  `ChooseModelFolders` when there are two or more, with new optional
  parameters: an introduction naming the pack, `ATickLargest`
  (`TImportForm.FTickLargest`: of those `DefaultModelFolders` ticks, only
  the biggest) and Skip as the cancel text; Skip passes the pack over
  (`NotChosen`, in the summary). The wider texture search stays: it costs
  nothing when textures are where they are named. The owner will clear
  the library by hand to test.
- **Compile fixes, `2026-11-11-1440-compile-fixes.zip`** (follows
  `2026-11-11-1430-artist-import-choose-folders.zip`). The owner's build
  (14:02): `PAlphaColorArray` is not declared in any unit the form uses
  (`MeasureVisible` now reads each pixel through `PByte` arithmetic);
  `SEARCH_LEVELS_UP` undeclared, as the owner's `Sprite3DModelTextures.pas`
  was older than `2026-11-11-1420-texture-search-wider.zip`'s (sent again
  in this zip); E2250 on `TThread.Queue` and `TTask.Run` in
  `ScanCollection`, which no zip changed, taken to follow from those two:
  if it stays, look there first. A `for var Name` in a form method was
  renamed, as it shadows the form's `Name`.
- **GitHub `main` is at `1c672f7`** (14:05), everything to
  `2026-11-11-1440-compile-fixes.zip`, checked file by file; the owner's
  IDE set the `.dproj`'s default configuration to Debug, kept. It builds
  (14:06), the E2250s gone with the other two errors.
- **`2026-11-11-1450-no-webp.zip`** (follows `1c672f7`; owner's choice):
  `DONT_LINK_WEBP` added to the project's defines, beside
  `DONT_LINK_JPEG2000`, so Vampyre's WebP decoder (`WebPDec.pas`) and its
  compiler hints are left out; a `.webp` texture cannot be converted now.
  `OSPaths.pas(110)` W1002 `DebugHook` is a Sprite3D common unit's: left
  as it is (a fix belongs in Sprite3D too).
- **Kinds of model, step 1, `2026-11-11-1500-model-kinds.zip`** (follows
  `2026-11-11-1450-no-webp.zip`). Agreed with the owner (14:19-14:25):
  five kinds, guessed, always to be overridable by the user: static,
  animated (node animation, no skin), rigged (skin, no animations), rigged
  and animated (own animations, in the same file or a separate exclusive
  library file: either happens), animation library (shared, or exclusive
  to one model; the user sets the scope); plus empty. Steps: (1) count
  and guess, tag on tiles, check skips libraries: **this zip**; (2) a
  Mark as menu for the user's kind, kept in a table of its own (like the
  palette), never overwritten by a rescan or remake; (3) linking
  libraries to rigged models: suggested by joint names and file names,
  confirmed by the user, with a shared/exclusive scope. New
  `src/lib/Sprite3DModelContent.pas`: `ModelContent` counts
  `TGorillaModel.Def` (a `TModelDef`) as Sprite3D's
  `Sprite3DGltfExport.CountDef`/`CountModel` do (meshes with
  `VertexSource`, not `TVertexGroupDef`; `Animations.Count`; controllers
  with a `Skin`, and its `LinkedJoints.Count`), plus
  `AnimationManager.Animations.Count`; `GuessModelKind`
  (`TOKEN_MESH_VERTICES` 64). The database is version 3: `meta` gains
  `meshes`, `vertices`, `animations`, `skins`, `joints`, `kind` (the key;
  empty = not counted). `LoadEntryModel` counts every model it loads and
  saves the counts at once for a model that has a thumbnail but no kind.
  Tiles have a badge (`TAssetEntry.Badge`, `UpdateBadge`); the details
  line adds `EntryContentText`; the thumbnail check has `tvLibrary` and a
  kind column.
- **Missing buffers, `2026-11-11-1510-missing-buffers.zip`** (follows
  `2026-11-11-1500-model-kinds.zip`). Quaternius's Modular SciFi MegaKit:
  `Decal_Line_90.gltf` names `Decal_Line_90_001.bin`, not there (a Blender
  copy number, presumably; the owner's folder listing not seen).
  `ResolveBuffer` in `Sprite3DModelTextures`: the name as given, nearest
  first in `SearchPlaces` (shared with `TextureSearch` now); then, in the
  folder named and the model's, one with the same extension named as the
  model, or as the name without its copy number (`WithoutCopyNumber`: one
  trailing number and the `_ . - space` before it); always only a file of
  the buffer's `byteLength` (`LengthFits`). Found buffers go into the copy
  as textures do; `TSprite3DTextureFix.IsBuffer` marks them for
  `ReportTextures`. `FolderImages` is `FolderFiles` now, listing every
  file; `TextureSearch` filters `IsImageFile` itself. Known gap: a model's
  key hashes a missing buffer by its name only, so a change to the buffer
  found elsewhere does not change the key.
- **Jobs, `2026-11-11-1520-resumable-jobs.zip`** (follows
  `2026-11-11-1510-missing-buffers.zip`). Owner: an interrupted scan
  restarted by itself when the Library was opened again, and only the end
  of the collection it was on; wanted a **Resume Scan** button shown only
  when there is work left, the whole queue persisted (an artist import
  finishes after a restart), and an abort that does what stopping did
  before. Every piece of work is now a job on `FBulkQueue`: `StartJob`
  (`import`, `rescan`, `remake`) or, made in `HashesDone` when a
  collection has thumbnails to make and no job runs, a `collection` job.
  `SaveJob` writes `library-job.json` (`JobFile`, settings folder: kind,
  title, `current` (`FBulkCurrent`), `queue`, `first`, `summary`, `errors`,
  `rescan`, `remakeBefore`) at the start and at every `NextBulk` step;
  `ClearJob` at the end. `PauseJob` (closing the form; `LeaveJob` for
  another collection, artist, collection added or deleted, which drops a
  `collection` job instead) sets `FJobPaused`: `HashesDone` then only
  shows (no `MakeNext`), status `PausedText`. `ShowLibrary` loads a saved
  job as paused (`LoadJob`: current first, then the queue, unknown ids
  left out). `FResumeButton` (Resume Scan) and `FAbortButton` (Abort Scan)
  are made in `FormCreate` in `CollectionBar` (`UpdateJobButtons`).
  `StopBulk` now drops the job, running or paused (and its file).
  Remaking is by time, not a flag: `FRemakeBefore` / `FBulkRemakeBefore`
  (a `TDateTime`, 0 for none; `OpenCollection`'s third parameter) and
  `MadeSinceRemake` against `Meta.Created`, so a resumed remake keeps
  what it made. Untested: the buttons' place in `CollectionBar`.
- **`Default()` hidden, `2026-11-11-1530-default-hidden.zip`** (follows
  `2026-11-11-1520-resumable-jobs.zip`). `Sprite3DModelContent` failed to
  compile at `Result := Default(TSprite3DModelContent)` (E2066 and a
  cascade, 14:44): **`Gorilla.DefTypes` declares a `Default` of its own**,
  hiding the intrinsic, so in any unit that uses it, zero records field
  by field instead, as Sprite3D's `CountModel` does.
- **Grouping and All, `2026-11-11-1540-grouping-all-folders.zip`** (follows
  `2026-11-11-1530-default-hidden.zip`; built clean before it). Owner:
  the classifier suited only KayKit; Kenney names `blaster-a`, others put
  the group last; one-model groups should go to an Unsorted group; and
  Choose Folders to Import wants an All box (a folder per model).
  `Sprite3DBuilderHelpers`: `AssetNameWords` (split at `_ - space .`, or
  at small-to-capital for a name with none; numbers and single letters
  dropped), `AssetGroupName` (first word), `AssetGroupNames` (a whole
  collection: first words or last words, whichever puts more models in
  groups of 2+, first on a tie). `HashesDone` groups the models the
  palette does not place with `AssetGroupNames`, then `MergePluralGroups`,
  then `CollapseSmallGroups` (fewer than `MIN_GROUP_SIZE`, 2, and not a
  palette group already: `UNSORTED_GROUP`, `unsorted`). **Regroup
  Collection...** (`RegroupItem`, collection menu, asks) saves the
  collection with no groups and opens it again. `TImportForm.FAllCheck`
  (made in code, right of `FormatLayout`) ticks all or none, and follows
  the boxes (`UpdateOK`). Checked in Python on KayKit, Kenney, last-word,
  CamelCase and Quaternius-style names.
- **No animation baking, `2026-11-11-1555-no-animation-baking-fixed.zip`**
  (follows `2026-11-11-1540-grouping-all-folders.zip`; replaces
  `2026-11-11-1550-no-animation-baking.zip`, which went out with the old
  files, the edit having failed). Owner (14:57): rigged models flood the
  debug output and slow the Library: Gorilla3D's `Caching 1 animations:
  elapsed time 40-100 ms` for each, from `LoadModelFile`'s
  `TAnimationCachingFlag.VertexPosition`, which a thumbnail does not
  need. `LoadModelFile` has `ACacheAnimations` (default False: `[]`);
  Builder4's placed models may want it True. The other lines are
  harmless Gorilla3D/FMX notices: `node X_Armature in hierarchy, but not
  attached to skin` (a Blender export's armature node that is not one of
  the skin's joints) and `FMX.Ani.TAnimation.AniThread not available
  anymore` (Gorilla3D's render clock drives animation, not FMX's thread).
  Rule: **check an edit script's result before zipping.**
- **Faster texture search, `2026-11-11-1600-faster-texture-search.zip`**
  (follows `2026-11-11-1555-no-animation-baking-fixed.zip`). The owner's
  import log (15:08): Quaternius's Modular SciFi MegaKit models in
  `glTF\Columns`, `Walls`, `Platforms` name `T_Trim_*.png` that are one
  folder up, in `glTF\`; found, but each model took 3-9 s to load (about
  1 s a texture), the copy then loading in 0.3 s. Causes: the search
  gathered every place's matches (up to the whole Quaternius tree) before
  choosing; `IsImageFile` (Vampyre's `IsFileFormatSupported`) ran on every
  file of every listing for every texture; every texture was SHA-256
  hashed again for every model (`CopyIn`, `MakePng`). Now:
  `TFolderListing` is a class with `ByName` and `ByBase` (images only)
  indexes, owned by `Listings` (`FolderListing` replaces `FolderFiles`);
  `IsImageFile` is cached by extension (`ImageExtensions`);
  `PlaceMatches` (replaces `TextureSearch`) looks one place up in the
  indexes; `ResolveTexture` tries place by place and stops at the first
  usable file; `ContentHash` keeps each file's SHA-256 (`FileHashes`) until
  its size or write time changes; `LISTING_KEEP_MS` is 30 minutes. All
  freed in the unit's finalization.
- **Missing textures, `2026-11-11-1610-missing-texture-placeholder.zip`**
  (follows `2026-11-11-1600-faster-texture-search.zip`). A model named
  `T_Enemies_BaseColor_png.png`, not found; its copy kept the name, and
  Gorilla3D fails the whole model on one missing image. Now a third pass
  in `ResolveTexture`: the name less an image extension left in it
  (`WithoutNamedExtension`: after the last `_ . - space`, if
  `IsImageFile('x.' + it)`), any image extension (`PlaceBaseMatches`),
  same places. A texture still `toMissing` gets the placeholder,
  `PLACEHOLDER_FILE_NAME` (`missing-texture.v1.png`, 16 px magenta and
  black, `PlaceholderTexture`) in the copy, so the model loads and the
  thumbnail shows the gap; the error log line says so. Buffers have no
  placeholder: a model without its geometry still fails.
- **Repeated folders marked, `2026-11-11-1620-mark-repeated-folders.zip`**
  (follows `2026-11-11-1610-missing-texture-placeholder.zip`). The
  owner's Quaternius import (15:29): all six failures were in Sci-Fi
  Essentials Kit's `Engine Projects\Godot\...` folders, copies of the
  `glTF\` models (Godot-renamed textures), taken because all four folders
  were ticked; the 2-minute gaps were the debugger stopped on first-chance
  exceptions. Owner chose: mark repeats in Choose Folders to Import (not
  hide duplicates in a collection). `RepeatedFolders` in
  `Sprite3DBuilderImportForm`: a folder repeats one of the same format
  holding more than half its names that comes before it (more models; or
  as many and fewer folders deep; or earlier); shown as `(same models as
  ...)` after its count, with a hint. Nothing is ticked or unticked by it.
  It went out without `System.Generics.Collections` in the unit's uses
  (E2003 `TDictionary<,>` and a cascade, 15:33); fixed in
  `2026-11-11-1625-import-form-uses.zip`. Rule: **when a unit gains a
  generic, check its uses clause.**
- **Preview label colour, `2026-11-11-1630-preview-label-colour.zip`**
  (follows `2026-11-11-1625-import-form-uses.zip`). "Model Preview" was
  `$A0A0A0` whatever the background, hard to read on the checker
  (`$CCCCCC`/`$999999`), grey and white. `PREVIEW_LABEL_COLOURS`, set in
  `SetPreviewBackground`: near-black on checker and grey, light grey on
  black, dark grey on white.
- **Sprite3D's textures note, `2026-11-11-1640-sprite3d-textures-note.zip`**
  (for the **Sprite3D** repository, paths from its root; the first zip for
  it from this work). Owner (16:08): Sprite3D will need the same texture
  fixes, so write them up in its `notes/`. `notes/textures.md`: each
  problem with the log line that shows it (PSD refused by extension;
  textures and buffers not where the uri says; full paths in a uri not
  taken; PSD extra channels are not alpha; GL 1282 on 24-bit PNGs), how
  `Sprite3DModelTextures` deals with each, the speed fixes, the compile
  pitfalls, and the five steps for Sprite3D (Vampyre submodule, search
  paths and defines, the unit unchanged, `PrepareModelTextures` in
  `LoadModelFile` keyed by the model file's SHA-256 and keeping
  `VertexPosition`, the MPL licence). Sprite3D's `CLAUDE.md` (the notes
  lists, a *To do: textures* section before *Done: ImportTests*) and
  `README.md` (*Further reading*) gained it, edited from GitHub's copies
  (`fc70295`): if the owner's are ahead, apply those edits by hand. This
  entry went out in `2026-11-11-1641-handover-textures-note.zip`.
- Textures are fixed for glTF only for now: OBJ's `.mtl` and
  FBX are loaded as they are. Licence: `licences/Vampyre-LICENSE.txt` (a
  notice with the source address, then the MPL 2.0), in File, Licences and
  `docs/licences-required.md`. Project: Vampyre's four folders on the search
  path and `DONT_LINK_JPEG2000` defined (its C objects exist for only some
  platforms).
- The owner's log of that import stops in Retro-Winter, after
  `deco_winter_end ... loaded in 18 ms` with no grab: ask whether it was cut
  short when pasted or the program stalled there.
- The owner mentions harder-to-spot errors still to come, after the
  textures.

### Handover (11 November 2026, 05:30)

- **GitHub `main` is at `e15caac`** ("obj import woes"), which is
  **Builder3zf** exactly (checked file by file). The zips after it, not
  yet pushed, each following the one before: **Builder3zg** (folder
  dialogs start at the last folder chosen, or the nearest one above it
  still there, never the assets folder; Clear Library keeps the last
  folder and preferred format; grab poll every 50 ms), **Builder3zh**
  (log header gives the build time; StateText counts each queued step),
  **Builder3zi** (the fix for OBJ grabs stalling: `PostStep`/`Poll` in
  `Sprite3DOffscreen`). The owner tested 3zi: "this is looking better".
  The next zip follows Builder3zi. Zip names after `3z` go `3za`, `3zb`,
  ...; Builder4 is kept for placing models on the level.
- **The Library is done for now** (owner). Artists above collections,
  counts in the bars, 128 x 128 tiles, artist import into the artist
  shown, Skip turning formats down, the import log and the skip list.
- **Open items, for later, in no order:**
  - An FBX import issue the owner saw and left for later; ask what it was.
  - Kenney names models with hyphens (`blaster-a`), so `AssetGroupName`,
    which splits at the first underscore, gives one group per model;
    split at hyphens too.
  - Speed: the fixed 120 ms settle before each grab (`THUMBNAIL_SETTLE_MS`)
    could be one drawn frame now that grabs come back promptly.
  - Why OBJ grabs (and only OBJ) lost their queued steps is not known;
    `Poll` gets round it. If stalls come back, the log line after
    `not back after 4 s` says where (`polled n times, m with something
    to run`).
  - `src/lib/Sprite3DOffscreen.pas` came from Sprite3D and now differs
    from its copy there (`StateText`, `Poll`, `PostStep`); port back if
    Sprite3D wants it.
  - The import log (`library-import.log`), the loading marker and
    `library-skipped.txt` live in the settings folder
    (`%APPDATA%\Sprite3DBuilder` on Windows).
- **Next: Builder4**, below.

### State (10 November 2026, 22:30)

GitHub `main` is at `3da83fa`, "First commit": **Builder1** as delivered
(the cut-down of Sprite3D at its `f678433`). Since then, as zips:

**Builder2** (22:30; owner, 22:09-22:13), follows Builder1:

- **No models are opened any more.** File, Open Model, the Models menu
  (Models Used), the Models list side panel with Clear, drag-and-drop, files
  the system asks to open (`Sprite3DOpenFiles`, the single-instance hand-off)
  and the whole load pipeline in the main form (load dialog, timer, slots,
  name clash) are gone, with `Sprite3DBuilderLoadForm`,
  `Sprite3DBuilderNameClashForm`, `Sprite3DBuilderAnimationsUsedForm` and
  `Sprite3DAxes`. `LoadModelFile`, `StartModelFileRead` and `IsModelFile` stay
  in the Helpers, for the pieces to come. Settings lost `startupAction`,
  `lastModel`, `showAxes`, `showSweptVolume` and `showCombinedSweptVolume`,
  and the Settings dialog its Startup group.
- **An empty level at start-up.** `BuildLevel` makes `FLevel`, a `TDummy` in
  the viewport turned 180 degrees about X (so Y is up inside it, as in the
  kits, with the floor at Y = 0), and `FGrid`, a `TModelGrid` on it at
  `gridSize` (new setting, default 2, by hand only). The camera is fitted to
  `ViewVolume`: 10 cells across and 2 high, swept about the centre.
  `PlaceModel` and its centring are gone.
- **View** keeps Camera, Lights, Projection and Show bounding box, which
  boxes each `TGorillaModel` under `FLevel` (none yet).
- **File, Open Asset Folder...** (owner's name for it, 22:13): the folder
  dialog (`Sprite3DFolderDialog`, copied from Sprite3D) opens in
  `assetFolder` (new setting) or `AssetsFolder`, an `assets` folder found
  beside the program or up to five folders above; the folders chosen go in
  `FAssetFolders` and their models, by `AssetModelFiles`, are listed in the
  Debug tab. They will open on a second form the owner is about to design.
  Freed on Android and iOS, which have no folder dialog.

**Builder3** (22:55; owner, 22:41: thumbnails of every model of the asset
folder, in groups, cached by a content hash below settings.json; dragging
onto the view is stage two, Builder4), follows Builder2:

- `src/ui/Sprite3DBuilderAssetsForm` (`TAssetsForm`, caption Assets): made
  by the main form the first time a folder is opened (`FAssetsForm`, owned
  by it), shown non-modally. `OpenFolders` hashes the models on a worker
  thread (`TSprite3DAssetHasher`), shows the cached ones at once and makes
  the rest one at a time in its own `TGorillaViewport` (256 square, top
  left) with its own `TSpritelyOrbitalCamera`: model upright (X 180),
  isometric (inclination 35.264, camera azimuth 315), orthographic,
  framed as Sprite3D frames a model (Builder3c, owner 23:25, comparing
  `bar_innercorner` with Sprite3D's: cut off and off-centre before):
  `FitCameraToSweep(FCamera.Camera, FModel, CalcSweptVolume(FModelBox,
  FModel.RotationCenter.Point, saY), W, H, 0.06)`, i.e. the camera's
  `FitPointsOnAxis`, target on the turning axis. `FModelBox` is
  `LoadModelFile`'s box, before the upright turn. Builder3a's even box with
  `FitToBounds(ABox, ASpace, ...)` and Builder3b's camera stand-off are
  gone. `TSprite3DOffscreen` at `THUMBNAIL_SIZE` (256), transparent. Each
  thumbnail logs its box, distance and ortho height to the Debug tab.
  Builder3d (owner 23:33): each model is on screen `THUMBNAIL_SETTLE_MS`
  (120) before its grab (`FSettleTimer`), so the view shows it and it has
  been drawn once; groups in `GroupsList` (TListBox, left,
  `GroupsSplitter`), the chosen group's tiles on the right (`LayoutTiles`
  hides the rest; `FEntries` in name order, never resorted, so indices in
  tiles and the queue hold); dragging a tile onto a group item moves it
  (`MoveToGroup`; "New group..." asks with `TDialogService.InputQuery`);
  once the queue is empty, the selected
  model is previewed in the viewport (`ShowPreview`) with a mouse view on
  `PreviewArea`: drag turns (azimuth) and tilts (polar angle, all the
  way round), wheel zooms (ortho height), right or Control-click resets. Group from
  `AssetGroupName`, plurals merged with their singulars, unless chosen
  (`GroupChosen`). Closing it stops the queue. `MakeNextLater` is a
  1 ms `FNextTimer` (an anonymous `TThread.ForceQueue` and an anonymous
  `TDialogService.InputQuery` close proc would not compile here, E2250);
  the new-group name comes back through the method overload
  (`NewGroupClosed`). It logs to the Debug tab through `OnLog`.
  Builder3i (owner 00:05, 00:09): FMX drag and drop (`BeginAutoDrag`)
  crashed Windows' drag session (class not found,
  dragdropsession_initialize) and dropped nowhere, so the drags are the form's own: tiles
  and group items have `AutoCapture`, a move of `TILE_DRAG_START` starts
  the drag, `FDragGhost` (the thumbnail, 72 px) follows a tile,
  `GroupItemAt` (`ItemByPoint`) finds the item under the pointer and
  `SetDropItem` marks it (a `TRectangle` in each item's `TagObject`), and
  the mouse-up drops. FMX drag and drop works if started properly (owner
  00:11, the FMX.DragAndDrop sample: from mouse-down), but is Windows and
  macOS only and hands the drag loop to the system, so it is not used
  here. Group items are
  40 high, text 15. Dragging a group onto another puts it before that one,
  onto "New group..." last; clicking "New group..." makes an empty group;
  right or Control-click on a group with no models anywhere removes it.
  Anything that rebuilds `GroupsList` from one of its own handlers goes
  through `Defer` / `DeferredWork` (`FDeferTimer`), so no item is freed in
  its own event. The palette (`FGroupOrder`, `FPaletteGroups` key to
  group, for every model ever seen, not just this folder's) is loaded in
  `HashesDone`, gets every model of the folder and new groups (sorted)
  last, and is saved by `SavePalette` after every change; `BuildGroups`
  lists a group if the folder has models in it or it has none anywhere,
  so other kits' groups are kept but hidden.
- `src/lib/Sprite3DAssetCache` (new): `TSprite3DAssetHasher` (SHA-256 of
  the model file, then, for `.gltf`, each buffer and image `uri` and that
  file's digest, digests kept per hasher so a shared texture is read once),
  `TSprite3DAssetMeta`, `SaveAssetMeta` (through a `.tmp`),
  `LoadAssetMeta` (checks every value; format `Sprite3D asset`, version 1),
  `ClearAssetCache` (Builder3b: deletes only `<64 hex>.png`, `.json` and
  `.json.tmp`, so the palette stays), `LoadAssetPalette` and
  `SaveAssetPalette` (Builder3i, replacing Builder3d's `groups.json`,
  which can be deleted: `palette.json`, format `Sprite3D asset palette`,
  version 1, `groups`: an array of `name` and `models`, the keys in
  order; `TSprite3DPaletteGroup`). JSON while it is worked on; the owner
  wants BSON in the long run (`System.JSON.BSON`), and only those two
  functions know the format.
- File, **Clear Thumbnails** (Builder3b, owner 23:09; desktop only, freed
  on mobile with Open Asset Folder): asks with `TDialogService`, then
  `TAssetsForm.ClearThumbnails` (reopens `FFolders` if showing) or, before
  the form exists, `ClearAssetCache` directly.
- Cache: `TSprite3DAppSettings.ThumbnailFolder`, `thumbnails` beside
  settings.json, `<hash>.png` and `<hash>.json`. The metadata's `file` is
  where the model was when its thumbnail was made.
- Back from Sprite3D, unchanged: `Sprite3DOffscreen`, `Sprite3DBackground`,
  `Sprite3DResample`.

Files deleted by Builder2 (`git rm`): `src/lib/Sprite3DAxes.pas`,
`src/lib/Sprite3DOpenFiles.pas`, `src/ui/Sprite3DBuilderLoadForm.*`,
`src/ui/Sprite3DBuilderNameClashForm.*`,
`src/ui/Sprite3DBuilderAnimationsUsedForm.*`.

Builder3a runs (owner's screenshot of the Assets form, 22:59; pushed as
"Debug", 23:09, with the IDE's `.dproj`, `src/Sprite3DBuilder.res` and
`licences/Sprite3DLicences.res`). Some thumbnails were wrong: `coin` blank,
`floor_foundation_allsides` cut at the top, the half-cell pieces
(`floor_foundation_diagonal_corner`, `floor_tile_small_corner`) to one
side; their glTF bounds are all even about the origin across, and the
half-cell pieces really are half a cell. After Builder3c (Sprite3D's sweep
fit) the same few seemed to stay bad (owner 23:33), hence the
preview in Builder3d; with Builder3e and the cache cleared every thumbnail
is right (owner 23:50): the bad ones had been the old cache. Slow (the
120 ms settle per model among it) but a one-time import, which the owner
accepts. Builder3f: the unused `TMainForm.UpdateView` removed (H2219).
Builder3g: the preview's turn was backwards (owner 23:55); it now adds the
pointer's move to the camera's Azimuth, as the main form's mouse view does.
Builder3h: the tilt is no longer held to +-89; it goes right round, kept in
0..360 by `Wrap360` (owner 00:01: the orbital camera's gimbals have no lock).
Builder3i: the palette and the form's own drags; see the Assets form above.
Builder3j (owner 00:27-00:29): `GroupsList` (TListBox; its hover was
disliked) replaced by `GroupsBox` (TVertScrollBox) of group buttons
(`FGroupTiles`, TRectangle, `GROUP_TILE_HEIGHT` 66: icon 32 above
"name (count)"); a click chooses (fill), Up/Down in `FormKeyDown` (scroll
boxes `CanFocus` False so the form gets the keys); the drop target gets an
outline only during a drag. "New group..." is gone: `GroupMenu`
(TPopupMenu, opened by hand from mouse-up, right or Control-click) has Add
(after the group clicked), Rename (case-insensitive clash refused),
Change Icon (`IconDialog`; an icon from outside the libraries is copied
into `UserGroupIconsFolder`) and Delete (only with no models anywhere).
Thumbnails multi-pick (`Picked`; click, Control, Shift run from `FAnchor`;
a plain press on a picked one keeps the picks until mouse-up, so they can
be dragged together); the drag ghost shows the count; `MoveEntries`.
Group reorder: drop on a group = before it, below all = last
(`GroupTileAt`'s `ABelow`), still through `Defer`. Icons: palette groups
gained `icon` (a plain file name; `TSprite3DPaletteGroup.Icon`); lookup
`IconFile`: `TSprite3DAppSettings.UserGroupIconsFolder`
(SupportFolder/icons/groups) then `GroupIconsFolder` (icons/groups beside
or above the exe, as `AssetsFolder` looks); default `<group>.svg/.png`,
else the group's first thumbnail. New lib unit `Sprite3DGroupIcons`:
`LoadGroupIcon` (PNG as is; SVG: every `path d` filled in one colour in
viewBox units, a full-view-box background square skipped, so
game-icons.net style). `icons/groups/*.png`: 40 placeholders drawn by
`tools/make_group_icons.py` (ours, no licence). The owner suggested a
large free vector icon library: game-icons.net (CC BY 3.0, needs credit in
docs/licences-required.md and the licences resource if shipped) is the
fit; it cannot be downloaded from here.
Builder3k (owner 01:04): "Model Preview" (`FPreviewLabel`, over the
viewport, shown while `FModel` is nil; `UpdatePreviewLabel` from
`FreeModel` and `LoadEntryModel`). Nested groups: `FGroupParents` (lower-
case group -> parent name; root has none), palette groups gained `parent`
(`TSprite3DPaletteGroup.Parent`; a missing parent or a loop is dropped in
`HashesDone`, walks bounded by `Length(FGroupOrder)`). Names stay globally
unique, so `FPaletteGroups` and `Meta.Group` are unchanged. Left bar: top
groups only, count = `FolderTotal` (with the groups inside); chosen mark on
`RootOf(FGroup)`. Grid: `BuildFolderTiles` (inner groups first,
`FOLDER_FILL`, double-click via `ssDouble` opens, deferred `FOpenGroup`),
`TilesPanel` (outline = drop into the group shown), `PathBar` (`UpButton`,
`PathLabel`, Backspace). Group drags: `TrackGroupDrag` / `DropGroup`; from
a button onto a button = reorder at the top, from the grid onto a button =
inside it, onto a folder tile = inside it, onto the grid = inside the one
shown, below the buttons = top, last (`Reparent`, through `Defer`). Model
drags can drop on folder tiles too. Delete needs `GroupEmpty` (no models
anywhere, no inner groups); Add from the grid adds inside the one shown.
Builder3l (owner 01:33): groups alphabetical, case ignored, at every
level (`ChildGroups` sorts), so the reorder drag is gone: a group dropped
on a button or tile goes inside it, below the buttons to the top
(`FMoveGroup`/`FMoveBefore` removed). Drags auto-scroll: `FScrollTimer`
(40 ms) while dragging, `EdgeScroll` within 28 px of (or past) the top or
bottom of `GroupsBox` or `TilesBox`, faster further out; then the drop is
tracked again (`TrackTileDrag`, `TrackGroupDrag`); `BeginDrag` starts it,
`EndDrag` stops it. At start, `FormShow` queues `OpenLastAssets`
(`TThread.ForceQueue` with a method): if the cache has `palette.json` and
settings' `AssetFolder` still exists, the Assets form opens on it
(`OpenAssets`, also used by File, Open Asset Folder). Desktop only.
Builder3m (owner 01:52, answers 02:00): a Library above palettes. The
Assets form (`TAssetsForm`, caption "Library - <collection>") gained
`CollectionBar` along the top: `CollectionCombo` (open collection),
`CollectionMenuButton` "..." (`CollectionMenu`: Rename, Delete from the
library, files and thumbnails kept), `AddFolderButton`, `RescanButton`, and
`AddCollectionButton` "Add New Asset Collection..." (`SelectFolders`, then
a name; folder's name suggested). Lib: `TSprite3DAssetLibrary`
(`library.json`: collections id+name, `last`, `lastFolder`),
`TSprite3DAssetCollection` (`collection-<id>.json`: name, folders,
`scanned`, groups as the palette, `models` key+file), `NewCollectionId`
(GUID), `Load/SaveAssetLibrary`, `Load/SaveAssetCollection`,
`DeleteAssetCollection`; `SaveAssetPalette` gone, `LoadAssetPalette` only
reads the old `palette.json`, which `LoadLibrary` turns into "Kaykit
Dungeon" (folder = settings' `AssetFolder`, via `MigrationFolder`, not
scanned) when there is no library, then renames to `palette.json.moved`.
Owner chose: open from what was saved (`OpenCollection` feeds the saved
models to `HashesDone` with no hashing), scanning only when the
collection was never scanned or on Rescan/Add Folder (`ScanCollection`,
`FScanning` marks it scanned). `SavePalette` writes the whole collection.
Main: File, Open Asset Folder became File, **Library...** (`LibraryItem`,
`OpenLibrary`, `OpenLastLibrary` at start if the library has collections
or the old palette is there); `FAssetFolders`, `OpenAssets` gone; the
form's `OpenFolders` became `ShowLibrary` and private `ScanCollection`.
Builder3n (owner 02:09): users pick a pack's root, which holds the same
models in several formats (KayKit free: Assets/gltf, fbx, fbx(unity),
obj). Helpers: `TModelFolder` (Folder, Format ext, Count, Names),
`FindModelFolders` (recursive, one entry per folder and format),
`FoundModelFormats` (by `MODEL_FORMAT_PREFERENCE`: gltf, glb, fbx, dae,
usd*, obj, ply, stl), `DefaultModelFolders` (ticks the preferred format,
skipping a folder whose names are mostly already ticked: the engine
copy), `ModelFormatName`, `AssetModelFilesOf` (format filter). New dialog
`Sprite3DBuilderImportForm` (`TImportForm`, `ChooseModelFolders`: one
folder taken without asking, several asked, modal, checkbox list,
preferred-format combo). Collections hold `Sources`
(`TSprite3DCollectionSource`: folder + formats; JSON `sources`, old
`folders` read as every format); the library holds `PreferredFormat`.
`ChooseSources` in the Library form for Add New Asset Collection and Add
Folder; `ScanCollection` scans each source with its formats.
Builder3o (owner 02:37): the owner now tests from a data drive of
thousands of assets; the assets folder is to go soon. Add Folder removed
from the Library (to come back as drag and drop). Library wider (1120)
with `Constraints` 960 x 640. **Add Artist Collections...**
(`AddArtistButton`, `AddArtistButtonClick`): each folder directly inside
the folders chosen becomes a collection named after it (skipped if the
name is taken, or no models); an ordered list of default formats grows as
it goes: the first folder asks (`Sprite3DBuilderFormatForm`, `AskFormat`:
Import / Skip / Only My Defaults / Stop), a folder with a default takes
the first one it has without asking (`DefaultModelFolders` leaves engine
copies out), one with none asks again (Import appends a default). Made
with `NewCollection` (also used by Add New Asset Collection), not scanned
until first opened; the first is opened; summary message at the end;
`Defaults[0]` becomes the library's `PreferredFormat`.
`Progress` is shown only while reading folders or making thumbnails (owner
02:38: it stayed full after an import).
Builder3p (owner 02:39): time left while making thumbnails: `FMakeWatch`
(TStopwatch from the queue's start), shown after `ETA_AFTER` (3) made as
"about 1m 20s left" (`DurationText`), and the total time in the log.
Builder3q (owner 02:51): Add Artist Collections imports every collection
it makes in full, in one go, not when each is first opened: `FBulkQueue`
of new ids, `NextBulk` opens each (scan + thumbnails); `MakeNext`'s
end, when `FBulkTotal` > 0, sets `FBulkPending` and `Defer`s, and
`DeferredWork` calls `NextBulk`; status prefixed by `BulkPrefix`
("Collection 3 of 12, name: "); at the end the first is opened and the
summary shown. `StopBulk` when another collection is chosen, the Library
closes, or a new artist import starts.
Builder3r (owner 02:55): thumbnail and metadata files go in
`AssetKeyFolder` = `<cache>/<key[0]>/<key[1]>/` (256 folders at most);
`LoadAssetMeta` first moves a key's flat files from the top
(`MoveFlatFiles`); `ClearAssetCache` walks every folder (only key files
in their own key folder or at the top), then removes empty key folders;
the form makes the key folder before saving a thumbnail.
Builder3s (owner 02:58-03:01, Enterprise; FireDAC SQLite is in
Community/Professional too): one SQLite database, `library.db` in the
settings folder (`AssetDatabaseFile` = parent of the cache folder), all in
`Sprite3DAssetCache`, same public functions as before, now DB-backed via
FireDAC (static SQLite on Windows/macOS through
`FireDAC.Phys.SQLiteWrapper.Stat`, `FireDAC.FMXUI.Wait`), one
`TFDConnection` per database file (`Databases`, main thread only, freed at
finalization), WAL, `PRAGMA user_version` = `ASSET_DATABASE_VERSION` (1).
Tables: `library` (one row: last_id, last_folder, preferred_format),
`collections` (id, name, position, scanned), `sources` (collection_id,
position, folder, formats space-separated), `palette_groups`
(collection_id, position, name, icon, parent), `group_models`
(collection_id, group_position, position, model_key), `models`
(collection_id, position, model_key, file), `meta` (model_key, name, grp,
file, files newline-separated, min/max x/y/z, thumb_width/height,
thumb_view, created). Names avoid SQLite keywords (groups, key, view,
last). `SaveAssetCollection` replaces the collection's rows in one
transaction (new ones go last by position); `SaveAssetLibrary` upserts
names and positions. Migration: `LoadAssetLibrary` on an empty `library`
table moves `library.json` + `collection-*.json` in (renamed `.moved`);
`LoadAssetMeta` moves a key's `.json` in when the DB lacks it (then
deletes it). `ClearAssetCache` = files + `DELETE FROM meta`. JSON writers
gone; JSON readers kept private as `ReadLegacy*`; BSON plan dropped.
Builder3t: `GroupMenuSeparator` declared (sync + verify, owner 03:08).
Builder3u (owner 03:13): File, Clear Thumbnails became **Clear Library...**
(`ClearLibraryItem`, warning dialog): `ClearAssetLibrary` closes and drops
the connection, deletes `library.db` (+ -wal, -shm, -journal) and the
whole cache folder recursively; `TAssetsForm.ClearLibrary` (was
`ClearThumbnails`) stops everything first, then shows the library empty
(no migration afterwards: `FLibraryLoaded` stays True). `ClearAssetCache`
is kept in the unit but nothing calls it now.
Builder3v (owner 03:19): the preview has Sprite3D's checker
(`FBackground`, TSprite3DBackground, Transparent, 16 px squares; 2D behind
the viewport, never in grabs) and a floor grid (`FPreviewGrid`,
TModelGrid, child of the preview's `FModel`, `GridLevel` 0 = the model's
own floor, `GridSize` = the level's, set by the main form through
`TAssetsForm.GridSize`, `SetExtent` from `FModelBox` and the centre of
rotation), made only in `ShowPreview`, so never while a thumbnail is made.
Builder3w (owner 03:36): `THUMBNAIL_SIZE` 128
(older ones remade as met). **Artists** above collections: lib
`TSprite3DArtist` (Id GUID, Name), `TSprite3DAssetLibrary.Artists`,
`LastArtist`, `TSprite3DLibraryEntry.ArtistId`,
`TSprite3DAssetCollection.ArtistId`; DB version 2: table `artists` (id,
name, position; rewritten as listed by `SaveAssetLibrary`), columns
`collections.artist_id`, `library.last_artist` (ALTER TABLE from 1). Form:
`ArtistBar` above `CollectionBar` (`ArtistCombo`, `ArtistMenuButton` ->
`ArtistMenu` Rename/Delete (deletes their collections from the library),
`NewArtistButton` "Add Artist...", `AddArtistButton` "Add Artist
Collections..." moved here); `CollectionCombo` lists only the artist's
(`FShownCollections`); Add New Asset Collection needs an artist and adds
to it; collection names unique per artist; artist import: the chosen
folder's name is the artist (`EnsureArtist`); `AssignOrphans` puts
artist-less collections under "Unassigned" (`UNASSIGNED_ARTIST`);
`CollectionMenu` gained **Move to Artist** (sub-menu rebuilt on open,
`MoveToArtistClick`). Owner: this is the Library done for now; next is
placing on the level, Builder4.

Builder3x (owner 03:51): the owner added the artist Kay Lousberg and
imported his KayKit folder, which made an artist KayKit (the product
line). Artist import now puts its collections under the artist shown
(`BulkArtist`); only with none shown, or Unassigned, is the chosen
folder's name the artist (`EnsureArtist`). The folder picker's title says
which. The preview grid not showing was a scan in progress (`ShowPreview`
does nothing while `Making`), not a fault.

Builder3y (owner 04:00): counts in the bars. Lib:
`TSprite3DLibraryEntry` gained `Models` and `Scanned`, read by
`LoadAssetLibrary` (a sub-select counts `models` rows per collection),
never written by `SaveAssetLibrary`. Form: `ArtistText` ("Name  (n
collections, n models)"), `CollectionText` ("Name  (n models)" or "(not
imported yet)"), `CountText`; `SavePalette` updates the entry and calls
`FillCollections` when the count or Scanned changed. Both combos 380 wide.

Builder3z (owner 04:06): tiles show thumbnails at their own size:
`TILE_IMAGE = THUMBNAIL_SIZE` (128), `TILE_WIDTH` = +8 (136),
`TILE_HEIGHT` = +28 (156); group tiles' icon box `TILE_IMAGE - 20`.

Builder3za (owner 04:26, Kenney's 50 packs, 4 FBX-only, wanted glTF):
artist import's Skip now turns down the formats the pack offered
(`Rejected`); a later pack whose formats are all turned down is passed
over without asking. `AskFormat` texts say so.

Builder3zb (owner 04:39, Kenney's OBJs hung on one model): import log and
hang guard. `Log` also writes to `library-import.log` (settings folder,
`ImportLogFile`, `DebugLog` opens/appends/closes per line so a hang
leaves it whole; deleted at the start of each artist import).
`LoadEntryModel` logs "loading <file> (bytes)" and "loaded in n ms",
`SettleTimerTimer` "grabbing". While a model is in the viewport its file
is named in `library-loading.txt` (`LoadingFile`, deleted by
`FreeModel`); `ShowLibrary` -> `LoadSkipped` moves one left there into
`library-skipped.txt` (`SkipFile`, `FSkipped`, `IsSkipped`), and
`LoadEntryModel` passes those over (thumbnail and preview). Next: read the
owner's log to see why the model hangs.

Builder3zc (owner 04:44): it was not a hang: the progress stopped but the
window still closed, so a grab never came back (Sprite3D imported the same
OBJs fine). `FGrabTimer` (`GRAB_TIMEOUT_MS` 15000), started after
`FOffscreen.Grab`, stopped by `ThumbnailGrabbed`/`StopMaking`:
`GrabTimerTimer` logs it, `FOffscreen.Cancel`, passes the model over (not
added to the skipped list) and goes on; minimised, it waits. Log lines
"grabbed an image"/"grabbed nothing: ...". Still to find: why the grab of
that model never returns.

Builder3zd (owner 04:48): the IDE refused README.md ("One or more lines
were too long and have been truncated"): the Library paragraph had grown
to 4138 characters. Split into paragraphs. **Keep every line of every
file well under 1000 characters**; add a new paragraph rather than
lengthen one.

Builder3ze (owner 04:52): a skipped format was still offered by the next
pack that had others too. Artist import now asks only about `Offered`,
the pack's formats less `Rejected`.

Builder3zf (owner 04:57, log of Kenney OBJ): 4 of Blaster Kit's 40
(blaster-a, blaster-q, crate-medium, crate-wide) loaded in ~20 ms but
their grab never came back; one Brick Kit grab took 3.7 s then worked.
Looks intermittent, not the model. Lib: `TSprite3DOffscreen.StateText`
(busy, pending, stage, drawing, iterations, enabled, verifying, render
passes begun/ended since `Grab`: `FBeginRenders`/`FEndRenders`). Form:
`GRAB_TIMEOUT_MS` 4000, `GRAB_TRIES` 3, `FGrabTries`; `GrabTimerTimer`
logs `StateText`, cancels, invalidates the viewport and grabs again, then
passes over. Next: read StateText in the owner's log (passes ended 0 =
the viewport stopped drawing; ended > 0 with pending = HandleEndRender's
stage logic; not pending = the worker/queue).

Builder3zg (owner 05:08): the log answered it: every stalled grab was
"busy True, pending False, enabled True" with hundreds of render passes
ended, so the drawings were read and the worker started, but nothing
queued for the main thread ran: not even ProcessDrawing's ForceQueue that
switches the pass off (enabled still True). The viewport drawing every
frame starves FMX's idle, where `CheckSynchronize` runs; the timer firing
let it through (each retry came back in ~30 ms). Fix: `FGrabTimer` polls
every `GRAB_POLL_MS` (50) and calls `CheckSynchronize`; `FGrabWatch`
times each try against `GRAB_TIMEOUT_MS`. Sprite3D never sees it as it
grabs once, on demand. Also: folder dialogs no longer fall back to the
assets folder (`StartFolder` climbs to the nearest folder still there,
else empty), and `ClearLibrary` keeps `LastFolder` and `PreferredFormat`.

Builder3zh (owner 05:15): the next log looked the same (stalls of 4 s,
"pending False, enabled True", retry fine in ~30 ms); not known whether it
was a 3zg build. The log header now gives the program's build time.
`StateText` also counts ProcessDrawing's queued switch-offs run, workers
begun/ended, results run and Deliver steps run (`FSwitchOffs`,
`FWorkerStarts`, `FWorkerEnds`, `FResultRuns`, `FDeliverRuns`); the form
adds how often `GrabTimerTimer` ran `CheckSynchronize` and how often it
found something (`FPumps`, `FPumpsUseful`).

Builder3zi (owner 05:21, 3zh log, OBJ only; FBX and glTF fine): every
stall was "switch-offs run 0, workers begun 1, ended 1, results run 0,
deliveries run 0; the queue run 64 times, 0 with something in it": the
worker finished and queued its result, yet `CheckSynchronize` found
nothing to run, so TThread's queue held the steps where the poll could not
reach them. Lib: every step `TSprite3DOffscreen` leaves for the main
thread now goes through `PostStep`: posted to a thread-safe list in the
shared alive flag (`IAliveFlag.Post`/`Take`, `TAliveFlag.FSteps`) and
also `TThread.ForceQueue`d to `RunSteps`; the new public `Poll` runs them
too, whichever comes first, each once. Form: `GrabTimerTimer` calls
`FOffscreen.Poll` instead of `CheckSynchronize`. Note: this unit came from
Sprite3D and now differs from its copy there (StateText, Poll); port back
if Sprite3D wants it.

**Next, Builder4:** dragging a thumbnail from the Assets form onto the
level, with a bounding box showing where it will go, snapped to the grid,
and the model placed under `FLevel` on release. Kits of other scales:
the metadata keeps each model's raw box, so a scale per kit can be worked
out later from a reference piece.

### Test kit

KayKit Dungeon Pack 1.1 (FREE), CC0, attached by the owner (21:46); the
owner has a more complete version. 211 models, each as glTF, FBX, FBX for
Unity and OBJ, sharing one texture; no animations in the glTF files. From
their glTF bounds: the grid unit is **2** (small floor tiles 2 x 2, large
4 x 4, extra-large grates 8 x 8); walls are 4 wide, 4 tall and 1 thick.
Pieces are centred on their origin in X and Z; floor tiles' tops are at
about Y = 0.05 and walls stand on Y = 0, so a piece snaps by its origin to
the grid's points.
