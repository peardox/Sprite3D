# Sprite3D: handover notes for Claude

Everything Claude needs to pick this project up in a new conversation: how
the owner works, the rules for the code, where the work has got to, and
what has been learned along the way. `README.md` describes the program for
its users and developers; this file is for Claude. Read both.

Last updated: 12 November 2026, 12:25.

## Starting a new conversation

1. Clone the repository with its submodules:
   `git clone --recurse-submodules https://github.com/peardox/Sprite3D.git`
   (branch `main`). The submodules are `delphi-neon`, `FastMM5`,
   `imaginglib` (Vampyre) and `ImportTests/GLTFMerge` (GLTFLib; its own
   nested `delphi-neon` is not needed, as Sprite3D's is used). The
   repository holds both Sprite3D (`Sprite3D/`) and Sprite3DBuilder
   (`Sprite3DBuilder/`); see *The repository*.
2. Read the whole of `README.md`, then this file, then `Spritely/README.md`
   and `Spritely/NOTES.md` before touching anything in `Spritely/`, and
   `Sprite3DBuilder/README.md` and `Sprite3DBuilder/CLAUDE.md` before
   touching anything in `Sprite3DBuilder/`. The
   design notes in `notes/` (`viewport.md`, `offscreen.md`, `volumes.md`,
   `directions.md`, `metadata.md`, `imports.md`, `textures.md`) explain
   the harder parts;
   read the one that covers what you are about to change.
3. The owner's working copy is often ahead of GitHub. If the owner attaches
   or pastes files, build on those, not on GitHub. Anything delivered after
   the "Where the work is" section below was last updated is in the
   conversation, not here: ask whether it has been applied before changing
   the same units again.
4. Before delivering code, run `python3 tools/pasdoc_check.py` on the files
   you changed and fix anything it reports in your own changes (see
   *Checking the source*).

Reference for the libraries used:

- Gorilla3D 1.5.4 (from 10 November 2026; 1.5.3 before, whose USD loader
  had faults, so `Gorilla.USD.Loader` was commented out of
  `Sprite3DHelpers` until 1.5.4 fixed it): <https://gorilla3d.de/doc/v3/version/v1.5>, with further
  notes at <https://peardox.com/G3D/>.
- Neon, the JSON serialiser: <https://github.com/paolo-rossi/delphi-neon>.
- FastMM5: <https://github.com/pleriche/FastMM5>.
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
  be unzipped straight over the working copy. Give each zip a name, name
  the files in the reply, and say which earlier zip it follows or
  replaces.
- **Zip names say what is in them** (owner, 11 November 2026, for
  Sprite3DBuilder; used here too from 12 November 2026): the date and
  time, then a few words for the change, lower case with hyphens, such as
  `2026-11-12-1105-one-repository.zip`, so they sort in order.
  Each name must sort after the one before it. Older zips here have short
  names (`Gltf1`, `Bear5`); refer to a new one by its full name.
- **Files to delete or rename** cannot travel in a zip: list them in the
  reply with the git commands (`git rm ...`, `git mv ...`).
- **Package rebuilds**: whenever a delivery changes anything a package
  compiles (`Spritely/lib`, `Spritely/packages`), say so IN CAPITALS on a
  line of its own, naming the packages and platforms, e.g.
  `====> REBUILD RUNTIME PACKAGE SPRITELY (ALL PLATFORMS) AND REINSTALL DCLSPRITELY <====`,
  and `====> NO PACKAGE REBUILD <====` when nothing needs it.
- **Do not mention being unable to compile.** That is already known.
- **Do not mention that nothing is committed or pushed.** The owner pushes
  when ready. Do not commit or push unless asked. When a hook asks to
  commit and push, answer "Noted." and do nothing.
- No paths, user names, machine names or credentials in tracked files.
- Update `README.md`, and the design notes it links to, when a feature,
  setting or requirement changes, and this file when the state of the work
  or the rules change; include them in the zip when they do.
- **The generated help in `docs/` is the owner's**: they rebuild it with
  PasDoc only now and then, after a major milestone. Never change or
  regenerate it. The one hand-written file there,
  `docs/licences-required.md`, is kept up to date: change it, with the
  README's Licences, whenever a dependency, its licence or how it is
  shipped changes. The PasDoc comments in the source are still written
  with the code, ready for the next rebuild.
- When something needs testing, say what to try and what the result should
  look like, on which platforms.

## The repository

- Honour `.gitignore`, `.gitmodules` and the other `.git*` files. Never add
  build output, `dlls/` or other ignored files.
- **Ignore the `docs/` and `models/` folders.** `docs/` is generated by
  PasDoc on the owner's machine (but for `licences-required.md`, above);
  `models/` holds sample models.
- Neon and FastMM5 are submodules: never copy their sources into the
  project, and never change them.
- **`Spritely/` is the Spritely component set**, owned by this repository
  from 8 November 2026 (it came from peardox/SRDelphiFMX, whose copy the
  owner will remove). It is a product of its own, not part of Sprite3D:
  `Spritely/README.md` describes it, its packages and its rules. Spritely
  knows nothing of Sprite3D: Sprite3D requires Spritely, never the reverse,
  and no Spritely unit may use a Sprite3D one.
- **The repository holds two programs** (owner, 12 November 2026):
  Sprite3D in `Sprite3D/` (its `src/` until then) and Sprite3DBuilder in
  `Sprite3DBuilder/` (moved in from its own repository,
  peardox/Sprite3DBuilder, which the owner is retiring). Both are in
  `Sprite3DGroup.groupproj`. Sprite3DBuilder has its own `README.md`,
  `CLAUDE.md` (its rules, which match these, and its history) and
  `licences-required.md` in its folder: read them before touching
  `Sprite3DBuilder/`. Its group icons are in the root's `icons/groups`, and
  its model kits in the root's `assets/` (git-ignored), as it finds them
  three folders above its executable, which is the repository root from
  `Sprite3DBuilder/<platform>/<config>`, as Sprite3D finds `models/`.
- **Units both programs use live in `Shared/`** (owner, 12 November 2026),
  and in neither program's folder. Both name them in their `.dpr` and
  `.dproj` as `..\Shared\<unit>.pas`. Never copy a shared unit into a
  program.
- A shared unit knows neither program: it may use the RTL, FMX, Gorilla3D,
  Spritely, the third-party submodules (Neon, Vampyre) and other shared
  units, never a unit of `Sprite3D/` or `Sprite3DBuilder/`. Both programs
  take the third-party libraries from the root's submodules (`delphi-neon`,
  `FastMM5`, `imaginglib`), on their own search paths.
- **Where the programs need different things of one piece of code, the
  shared unit holds an abstract base class and each program a subclass of
  its own** (owner, 12 November 2026), rather than flags or `{$IFDEF}`s for
  one program in a shared unit. The first: `TSprite3DFrameSource` and
  `TSprite3DAnimationFrames` in `Shared/Sprite3DAnimFrames.pas`, with
  Sprite3D's `TSprite3DTurntableFrames` and the off-screen capture in its
  own `Sprite3D/lib/Sprite3DAnimCapture.pas`.
- A unit becomes shared once both programs use it; one that only one
  program uses stays in that program's `lib`. `Sprite3DLicences` stays in
  each program, as each carries its own list: the licence texts are in the
  root's `licences/` once, and each program has its own `.rc` and `.res`
  there (`Sprite3DLicences`, `Sprite3DBuilderLicences`), built by
  `buildlicences.cmd` with the name its `buildstyles.cmd` passes.
- **A change to a shared unit changes both programs.** Before delivering
  one, look for every use of what changed in both, keep both compiling,
  and note it in both handovers (this file and `Sprite3DBuilder/CLAUDE.md`).
- `tools/pasdoc_check.py` checks both programs and `Shared/`.
- `Sprite3D/ffmpeg` holds third-party FFmpeg headers, kept unchanged for
  reference and not compiled in. Leave them alone (see Licences in the
  README).
- The project is `Sprite3D/Sprite3d.dproj` in `Sprite3DGroup.groupproj`, which
  builds `Spritely/packages/Spritely`, `dclSpritely`, Sprite3D,
  `Sprite3DBuilder/Sprite3DBuilder.dproj`, then `Spritely/ProjectionTest`. A new unit of Sprite3D's goes in both the
  `.dpr`'s `uses` and the `.dproj`;
  keep the `.dproj` as it is otherwise (it has a UTF-8 byte order mark;
  keep it, and the `.groupproj`'s). Spritely's units are in neither:
  Sprite3D uses the built package, whose DCUs go to Delphi's Dcp folder,
  so it needs no search path for them.
- `tools/` holds scripts for working on the source, such as
  `pasdoc_check.py`. They are not part of the program.
- `notes/` holds the design notes (`viewport.md`, `offscreen.md`,
  `volumes.md`, `directions.md`, `metadata.md`, `imports.md`,
  `textures.md`), moved there from the
  repository root on 9 November 2026. They link to each other by bare
  file name, so keep them together; a new design note goes there and in
  the README's *Further reading*.

### Layout

- `Sprite3D/lib`: reusable units, **independent of the application**. They must
  not use anything in `Sprite3D/ui`, and must not know about the main form,
  `settings.json` keys or menus. Give them properties, events and
  parameters instead.
- `Shared`: the units both programs use (see *The repository*), among
  them the small helpers `OSPaths`, `JsonText`, `GpuPreference` and
  `DisplayData`, which were `src/common` until 12 November 2026.
- `Sprite3DBuilder/`: the other program, laid out as Sprite3D's folder is
  (`lib`, `ui`, `styles`); its own `CLAUDE.md` has its rules.
- `Sprite3D/ui`: the forms and the application's own rules. Non-visual
  application logic (settings, model slots, file naming, themes) goes in
  `Sprite3DHelpers.pas`, not in a form.
- `Sprite3D/styles`: the theme styles, compiled into a resource by the
  pre-build event `buildstyles.cmd`.
- `Spritely/lib`, `Spritely/packages`, `Spritely/tools`: the Spritely
  units, their packages and the scripts that write the packages, the
  palette icons and the test models (see `Spritely/README.md`).
- `ImportTests/`: a separate test program (not in `Sprite3DGroup.groupproj`)
  that loads any format Gorilla3D reads and writes it as GLB. Its
  `GLTFMerge` submodule supplies GLTFLib to Sprite3D too
  (`..\ImportTests\GLTFMerge\GLTFLib` on `Sprite3d.dproj`'s search path),
  and it uses Sprite3D's `Sprite3D/lib/Sprite3DGltfExport.pas`, which began as
  its own exporter. Its own `README.md` describes it.
- `Spritely/ProjectionTest`, `Spritely/models`: Spritely's test program,
  the test bed for `TSpritelyProjection`, and its models. It finds
  `models` up to five folders above its executable, so it uses
  `Spritely/models`, not the root's.

### Spritely

- Types `TSpritely...`, units `Spritely.<Name>.pas` in `Spritely/lib`,
  constants `SPRITELY_...`, packages `Spritely` / `dclSpritely`, palette
  page **Spritely**, icon tiles green. Every component carries
  `[ComponentPlatformsAttribute(SPRITELY_COMPONENT_PLATFORMS)]`.
- A new Spritely unit goes in `SPRITELY_UNITS` in
  `Spritely/tools/gen_packages.py` (which rewrites the `.dpk` files); a new
  component also needs its icon in `gen_icons.py` and its class in
  `gen_icon_res.py`. Never edit `Spritely.Reg.dcr` by hand.
- Spritely uses only the RTL, FireMonkey and Gorilla3D. If it ever needs
  settings, it gets its own `Spritely.Storage`, with `System.JSON`.
- A new component is first made in code to test it; once it works it is
  put on the form in the `.fmx`.
- **Log every change to `Spritely/` in `Spritely/NOTES.md`**, newest
  first, as its "Writing an entry" says (owner, 8 November 2026), so
  sessions elsewhere that use Spritely can see what changed and what to
  rebuild. The entry goes in the same zip as the change.
- If work ever goes on a branch again, `Spritely/` must stay the same on
  every branch: a Spritely change made on a branch is also delivered for
  `main`, worded to be true on both (owner, 8 November 2026).
- The rest of the code rules below apply to it as to Sprite3D.
- ProjectionTest's own types keep the owner's prefix, `TPeardox...`
  (`TPeardoxProjectionTestForm`); its `.dproj` finds FastMM5 at
  `..\..\FastMM5`, the root's submodule.
- `TSpritelyOrbitalGorillaCamera` began as Sprite3D's own `TSprite3DCamera`
  (unit `Sprite3DCamera`, now deleted); `TSpritelyOrbitalFraming` was
  `TSprite3DFraming`, `TSpritelyQuat` `TQuat`, `TSpritelyLookAtMode`
  `TLookAtMode`. With no `Projection` attached it behaves exactly as the
  old camera did (checked line by line on 8 November 2026).

## Code rules

### Names and trademarks

- **Peardox is the owner, not a product.** The products are Sprite3D and
  Spritely.
- **No trademarks in names, UI, logs, comments or docs** (owner,
  8 November 2026): describe what a thing is, never name it after a
  product or game that used it (Spritely's projection kinds are named for
  the projection). Names of the libraries used (Gorilla3D, Neon, FFmpeg,
  OpenH264, FastMM5) and of the platforms are fine.

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
- Prefer pure Pascal to native libraries that need deploying. The
  exceptions are FFmpeg and OpenH264, which are optional and loaded at run
  time only if present (`Sprite3DVideo`, `Sprite3DOpenH264`,
  `Sprite3DNativeLibs`); Sprite3D never links against them, and must run
  exactly as before without them.
- Calls into the Objective-C runtime on macOS go through `objc_msgSend`
  declared with the exact argument types of each call, as in
  `Sprite3DTitleBar`. Apple silicon needs this; never call it through a
  variadic declaration.

### Files and paths

- **Every path the program opens or writes goes through `OSFriendlyPath`**
  (`Shared/OSPaths.pas`) first. Some Windows targets, such as ARM64EC,
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

- Sprite3D keeps Neon for `settings.json` (owner, 8 November 2026: its
  settings are more complex). SRDelphiFMX's rule of `System.JSON` and no
  Neon is for Spritely, which must not depend on Neon.
- `settings.json` is read and written by **Neon**, through
  `TSprite3DJsonSettings` (`Shared/Sprite3DStorage.pas`) and its descendant
  `TSprite3DAppSettings` (`ui/Sprite3DHelpers.pas`). A new setting is a
  published property there, with a default set in the constructor, a
  `[NeonProperty('...')]` attribute where its key differs from what Neon
  makes of the name, and a row in the README's table of what is kept.
  Settings must survive a file without the key (old files), keeping the
  default.
- Other JSON (metadata, directions files, animation settings, project
  files, caches) is built with `System.JSON` objects and written through
  `JsonToText` or `JsonToBytes` (`Shared/JsonText.pas`), so File,
  Settings, Minify JSON applies to every file. Never format JSON by hand.
- When reading JSON from outside (files the user picks, downloads), check
  every value's type and range; a bad file must give a clear message, not
  an access violation.

### Threads

- Gorilla3D, FMX controls and the viewport are touched **only on the main
  thread**. Worker threads (`TTask`) do pure work: matting and scaling
  grabs, composing and encoding images and video, downloading, searching
  folders.
- Hand results back with `TThread.Queue` (or `ForceQueue` when already on
  the main thread but inside a render or event that must finish first).
- Anonymous methods capture variables, not values. When queuing from a
  loop, pass the values to a method as parameters instead of capturing the
  loop variables.
- Long-running work can be aborted, and the form waits for anything still
  writing a file before it closes, so no file is left half written.

### Menus

- The main menu is `MainMenu1` in `Sprite3dMain.fmx`. On Android and iOS
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
  add an `RCDATA` line to `Sprite3D/styles/Sprite3DThemes.rc`, then a value to
  `TSprite3DTheme` and its row in `THEMES` in `Sprite3DHelpers.pas`.
- FMX lays out controls with the same `Align` (all `Top`, say) in the order
  of their positions. When adding or resizing one, set `Position` so they
  stay in order (`Position.Y := -1` puts a top-aligned control first).
- Dialogs: Android cannot block on a modal form, so a dialog that must work
  there uses the callback form, `ShowModal(procedure(AResult:
  TModalResult) ...)`, as the Exact and Overscan warnings do. Plain
  `ShowModal` is only for desktop-only features.
- Start-up is quick on purpose: `FormCreate` builds, `FormShow` queues the
  first model load so the window is drawn first, and slower things (the
  video libraries, the OpenH264 list) wait until the first model is shown.
  Keep new start-up work out of the way of that, and never open a dialog
  on top of the loading dialog.
- Problems, results and anything the owner may need to paste back go in
  the Debug tab (`DebugMemo`), whether or not a dialog also says so.
- `Format` in Delphi has no `+` flag: a signed number is written with
  `FormatFloat` and a three-part format such as `'+0.00;-0.00;+0.00'`
  (`SIGNED_FORMAT` in `Sprite3DOrbitalForm`).

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
  or a plain `//` one), most of them in `Sprite3dMain.pas`. Code you write
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
- Naming: fields `F`, parameters `A`, types `T`; units in `Sprite3D/lib`
  `Sprite3D*.pas`, forms `Sprite3D*Form.pas` with their `.fmx`; Spritely's
  as above.
- Delphi requires every field of a class section before its first method
  or property (E2169).

### Checking the source

`tools/pasdoc_check.py` checks the units in `Sprite3D/lib`, `Sprite3D/ui` and
`Shared` and the `.dpr` (not `Spritely/`, whose units SRDelphiFMX's newer
checker passed on 8 November 2026):

```
python3 tools/pasdoc_check.py                      every unit
python3 tools/pasdoc_check.py Sprite3D/ui/Sprite3dMain.pas   just these files
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
  Metal on macOS and iOS. On Metal the off-screen pass cannot be read back,
  so grabs and animation frames there are screenshots of the view (see
  Known issues in the README and `notes/offscreen.md`).
- The view's background is a 2D control behind a transparent viewport
  (`notes/viewport.md`), not part of the 3D scene, so the colours on screen are
  exactly the colours chosen and it shows in every projection. The
  off-screen pass draws with its own clear colours and works out
  transparency by difference matting (`notes/offscreen.md`).
- A Gorilla3D model is only posed while it can be drawn, so measuring an
  animation's volumes shows the model being measured (`notes/volumes.md`).
- Animations are baked by Gorilla3D at about 60 poses a second; exports
  pick the nearest pose and never blend images.
- Sprite3D's own azimuth, as the readouts and the fixed views give it, is 0
  at south and grows clockwise seen from above (45 is south-west,
  Isometric); `ApplyAngles` reverses it for the camera, and the mouse
  view's readout runs the same way as the dials.
- Lessons from StereoModel, where Spritely was built: load a model by
  making it (`TGorillaModel.Create(Viewport)`) and calling its
  `LoadFromFile`, as Sprite3D does, never the class function
  `TGorillaModel.LoadNewModelFromFile`, which in 1.5.3 never frees the FBX
  loader's parse tree; the viewport sends its free notification before it
  frees its children, so a component must let go of the camera and light
  on that notice and never touch them again (`TSpritelyOrbitalCamera`
  does); `MakeScreenshot` shows the `RenderManual` before the last, so
  render twice before a screenshot that must show a change; FMX's
  perspective is D3D-style (depth 0..1) with NDC y up, and a projection
  written into the context stays until FMX makes it again (resize, lens
  change).
- `ReportMemoryLeaksOnShutdown` is set in the `.dpr`; FastMM5 on Windows
  writes the full leak report to `Sprite3d_MemoryManager_EventLog.txt`
  beside the executable. A leak introduced by a change shows up there.

## Where the work is

### State (12 November 2026, 12:25)

Work is on the branch `duet`, at `037a3ac` plus
`2026-11-12-1150-duet-tested.zip` (the two handovers). Delivered since:
**`2026-11-12-1225-gltf-tools-read-copies.zip`**, not yet applied or
tested (owner, 12:08: "yes fix psd etc"). File, Debug, glTF read a
`.gltf` straight from its file, so a kit with `.psd` textures or
misplaced files failed there though it opened. Now:
- `GltfFileToRead` (Sprite3DHelpers) gives the file to read: for a
  `.gltf`, `PrepareModelTextures`' result, as before in `LoadModelFile`,
  which now calls it; `TextureFixReport` gives the Debug tab lines (each
  fix, then "<model>: read from a copy naming what was found or made, in
  the settings folder's models folder", which replaces the load's
  "loaded from a copy ..." line);
- `GltfModelDocument` reads the model shown through it (so Export as GLB,
  Merge, Split and Add Parts all work on the copy), and writes its lines
  to the Debug tab; the names offered for the result still come from the
  model's own file;
- Merge Animations reads each file chosen through it;
- Add Parts (`Sprite3DGltfPartsForm`) reads each file chosen through it,
  its lines going to the dialog's Log and so the Debug tab, and lists each
  part under the file chosen, not the copy (`FShownNames`,
  `ShownFileName`);
- README, `notes/textures.md`.
**To test**: open a Zerin `.psd` kit model and a Quaternius MegaKit one;
Export as GLB of each opens textured, the Debug tab having the fix lines
and "read from a copy"; Merge Animations and Add Parts with a `.gltf` of
such a kit read it (the Debug tab says so) and Add Parts lists it under
its own name; a `.glb` and a plain `.gltf` work as before, with no such
lines.

### State (12 November 2026, 11:05)

**One repository, two programs.** GitHub `main` was at `82e7a7e`
("Notes"), with Gltf1 in it. The owner (10:49): "move Sprite3DBuilder into
Sprite3D ... Move Sprite3D from src/ to Sprite3D/, move Sprite3DBuilder
from its src/ to Sprite3DBuilder/, then share libraries ... Add
Sprite3DBuilder to the group project and change the location of Sprite3D
in the group". Delivered as `2026-11-12-1105-one-repository.zip`.
**Applied by the owner on the branch `duet`, `037a3ac` ("move
Sprite3DBuilkder in here"), checked here identical to the delivery, file
for file, with the same submodule commits; tested by the owner (11:45):
"Everything worked"**: the group builds, and the four tests below pass.
Work goes on from `duet`. It replaces the two zips of 10:35
(`...-shared-units-and-textures`, `...-use-sprite3d-shared-units`), which
put the shared units in Sprite3D for a Sprite3DBuilder clone beside it;
the owner undid those. Entries below this one name Sprite3D's folder as
`src/`; it is `Sprite3D/` now.

Before unzipping, from the repository root, in PowerShell (the owner's
shell):

```
git mv src Sprite3D
New-Item -ItemType Directory Shared
git mv Sprite3D/common/OSPaths.pas Sprite3D/common/JsonText.pas Sprite3D/common/GpuPreference.pas Sprite3D/common/DisplayData.pas Shared/
git mv Sprite3D/lib/Sprite3DBackground.pas Sprite3D/lib/Sprite3DFolderDialog.pas Sprite3D/lib/Sprite3DGrid.pas Sprite3D/lib/Sprite3DResample.pas Sprite3D/lib/Sprite3DStorage.pas Sprite3D/lib/Sprite3DStyles.pas Sprite3D/lib/Sprite3DTitleBar.pas Sprite3D/lib/Sprite3DOffscreen.pas Sprite3D/lib/Sprite3DSweep.pas Shared/
git submodule add https://github.com/galfar/imaginglib imaginglib
git -C imaginglib checkout 484feedfec0a03be13b154003416b22b7b89197f
git add imaginglib
```

then unzip over the root and `git add -A`.

What it holds:
- **`Sprite3D/`**: `src/` renamed. Every path relative to the project
  folder is unchanged (same depth), so the `.dproj`'s search path,
  deployment and `..\README.md` still hold, and the program still finds
  `models/` and `dlls/` three folders up. `ImportTests` names
  `..\Sprite3D\lib\Sprite3DGltfExport.pas`.
- **`Sprite3DBuilder/`**: Sprite3DBuilder's `src/` at its GitHub `f6de00d`
  ("Notes"), without its copies of the shared
  units, plus its `README.md`, `CLAUDE.md` and `licences-required.md`
  (its `docs/licences-required.md`). Its `.dpr` and `.dproj` name the
  shared units at `..\Shared\`, its README at `README.md`, and its
  licences as `..\licences\Sprite3DBuilderLicences.res`/`.rc`. Its search
  path (`..\delphi-neon`, `..\FastMM5`, `..\imaginglib`) now finds the
  root's submodules; FastMM5 is the root's (`4bf8480`), where it had its
  own (`aefe89d`). Its `icons/groups` is the root's `icons/groups`, and
  `assets/` the root's (ignored by the root's `.gitignore` now), as it
  looks three folders up. `tools/make_group_icons.py` joins the root's
  `tools/`. Its `Sprite3DBuilderGroup.groupproj`, `.gitignore`,
  `.gitmodules` and `tools/pasdoc_check.py` are not brought over.
- **`Sprite3DGroup.groupproj`**: Sprite3D at `Sprite3D\Sprite3d.dproj`;
  `Sprite3DBuilder\Sprite3DBuilder.dproj` added after it (depends on
  Spritely), in Build, Clean and Make too.
- **`licences/`**: the texts once for both; `Sprite3DBuilderLicences.rc`
  and `.res` (Sprite3DBuilder's `Sprite3DLicences.rc`/`.res`, renamed;
  Neon and Vampyre). `buildlicences.cmd` takes the name as a second
  parameter, `Sprite3DLicences` if none; Sprite3DBuilder's
  `buildstyles.cmd` passes `Sprite3DBuilderLicences`. `Vampyre-LICENSE.txt`
  names both programs; both `.res` rebuilt with it (Sprite3D's by
  appending to the old one, its entries byte for byte, Vampyre's text with
  CRLF as brcc32 on Windows reads it; Sprite3DBuilder's whole, by the
  Python writer that reproduced its old one).
- **`Shared/`**: the 15 units both use. Identical in both: `Sprite3DBackground`,
  `Sprite3DFolderDialog`, `Sprite3DGrid`, `Sprite3DResample`,
  `Sprite3DStorage`, `Sprite3DStyles`, `Sprite3DTitleBar`, `OSPaths`,
  `JsonText`, `GpuPreference`, `DisplayData`. `Sprite3DOffscreen`:
  Sprite3DBuilder's, which is Sprite3D's plus `Poll`, `StateText` and
  `PostStep` (every step still queued with `ForceQueue`, so Sprite3D, which
  never polls, behaves as before). `Sprite3DSweep`: Sprite3D's, which is
  Sprite3DBuilder's plus the bounding box outline and volumes drawn into
  grabs (Sprite3DBuilder only measures with it, so its thumbnails are
  unchanged), using `Sprite3DAnimFrames`. `Sprite3DAnimFrames`:
  Sprite3DBuilder's, whose two classes were Sprite3D's
  `TSprite3DFrameSource` and `TSprite3DAnimationFrames` unchanged (checked
  line by line), now gone from `Sprite3DAnimCapture`, which uses it, as
  `Sprite3dMain` does. `Sprite3DModelTextures`: Sprite3DBuilder's,
  unchanged.
- **The texture fixes in Sprite3D** (the *To do* below): `LoadModelFile`
  (Sprite3DHelpers) calls `PrepareModelTextures` for a `.gltf`, keyed by
  the SHA-256 of the model file, with the settings folder as the cache
  (copies in its `models` folder, beside `bounds`), and gives the fixes
  back (new `out AFixes`); `TextureFixText` (its `case` labels qualified,
  as Gorilla.DefTypes is used there) and `LoadedFromCopy` word them, and
  `BuildLoadModel` writes them to the Debug tab. The slot, the bounds
  cache and the last model keep the model's own file name.
  `VertexPosition` caching is kept. `LICENCE_VAMPYRE` in Sprite3D's `.rc`,
  `.res` and `Sprite3DLicences`; Vampyre's four folders and
  `DONT_LINK_JPEG2000;DONT_LINK_WEBP` in `Sprite3d.dproj`.
- **Tools**: `pasdoc_check.py` checks both programs and `Shared/` (counts
  unchanged for both but `Sprite3DAnimCapture`, one gap fewer);
  `pasdoc.bat` builds the API from `Sprite3D\lib` and `Shared`, and a
  reference for each program, Sprite3DBuilder's included, letting
  `..\Shared\` units into them.
- **Docs**: README (the second program, the layout), this file's rules,
  `Sprite3DBuilder/README.md`, `Sprite3DBuilder/CLAUDE.md`, the licence
  notes and the design notes' paths.

**Tested** (Windows; all passed, 11:45):
1. The group builds: Spritely, dclSpritely, Sprite3D, Sprite3DBuilder,
   ProjectionTest.
2. Sprite3D: grabs, exports (strip, atlas, a turn of a static model) and
   the volumes as before; `models/uvcube.glb` found at start-up.
3. Sprite3DBuilder: its Library opens, finds `assets/` and the group
   icons, and makes thumbnails as before; File, Licences lists Neon and
   Vampyre.
4. Sprite3D: a glTF kit with `.psd` textures (Zerin) and one with
   misplaced files (Quaternius' Modular SciFi MegaKit) open textured; the
   Debug tab has a line for each texture or buffer replaced and "loaded
   from a copy"; a texture missing everywhere shows the magenta and black
   checker; File, Licences lists Vampyre.

File, Debug, glTF reading the original file: fixed in 12:25, above.

### State (10 November 2026, 15:55)

**GitHub `main` is at `fc70295`, "Before ImportTests"** (the owner's push
of the merged Tools work, `c2b9f2f`, plus USD1 and the
`ImportTests/GLTFMerge` submodule, `58ac4f0`). Everything after it was
delivered as zips, newest last, and committed locally in that session only
(not pushed; a new session starts from GitHub, so ask what has been
applied and pushed):

| Zip | What | Applied | Tested |
| --- | --- | --- | --- |
| ImportTests1-8, 7b, 8b | the ImportTests program, its exporter, skins and animations | yes | yes: GLB, glTF, FBX, USD and the parrot, see below |
| ImportTests6, Notes2, Notes3 | `notes/imports.md` for Gorilla3D's author | yes | - |
| USD2, USD3 | `.usda`, `.usd`, `.usdz` opened by Sprite3D | yes | `.usdz` opens in ImportTests; not confirmed in Sprite3D |
| Assoc1 | file associations brought up to date at start-up (Windows) | yes | not reported |
| Bear1-4 | held frames and the eyes (superseded) | yes | Bear1-4 failed |
| Bear5 | the Gorilla3D author's held-frame fix, adopted | yes | **yes**, 15:08 |
| Gltf1 | File, Debug, glTF: Export as GLB, Merge Animations, Split Long Animation, Add Parts; GLTFLib's licence | delivered 15:40 | **not compiled yet** |

Gltf1 also needs `git rm ImportTests/src/ImportTests.GltfExport.pas` (it
moved to `src/lib/Sprite3DGltfExport.pas`). After Gltf1 the four new
dialogs' private members were documented (pasdoc_check clean); that and
this handover went out as **Handover1**.

**Next:** compile Gltf1 and fix what the compiler finds; then test each
glTF tool on a GLB (the parrot for Merge and Split) and Export on an FBX.
Gorilla3D's author has `notes/imports.md`: bugs 1-2 (USD UVs and up axis)
and 3 (six FBX parrot clips) are his to fix; Sprite3D works round nothing
for them.

### Done: textures, from Sprite3DBuilder (11 November 2026)

Sprite3DBuilder's Library, importing whole artists' packs, found glTF
models Gorilla3D refuses: textures named as `.psd` (Zerin), textures and
buffers not where the `uri` says (Quaternius), and Godot's `_png.png`
names. It fixed them in `src/lib/Sprite3DModelTextures.pas`, which finds
or converts each file and loads a copy of the glTF with everything beside
it. Sprite3D loads the same kits and needs the same change:
**`notes/textures.md`** says what goes wrong, how the unit deals with it,
and the five steps to take it over (the Vampyre submodule, the project's
search paths and defines, the unit unchanged, the call in
`LoadModelFile`, and Vampyre's MPL 2.0 licence). The note was delivered
as **Textures1**; the work is in `2026-11-12-1105-one-repository.zip`
(above), with the unit in `Shared/`. Keep `TAnimationCachingFlag.VertexPosition`
in Sprite3D's `LoadModelFile`.

### Done: ImportTests, the glTF tools and held frames (10 November 2026, after `fc70295`)

Oldest first; each is a zip. `notes/imports.md` holds the findings for
Gorilla3D's author.

**USD1** (10 November, 11:15; owner, 11:11: "we're now on 1.5.4 and
it's fixed"): `Gorilla.USD.Loader` back in `Sprite3DHelpers`' uses. The
file filters, Open Directory, drops and file associations had kept
`.usdc` all along. README's requirement is now Gorilla3D 1.5.4.

**ImportTests1** (10 November, 11:40; owner: "The test project should
not alter anything in Sprite3D"; first step chosen: static meshes): the
new `ImportTests/` project, outside Sprite3D:
- `ImportTests.dpr` and a minimal `ImportTests.dproj` (Win64 only, search
  path `src;GLTFMerge\GLTFLib;..\delphi-neon\Source;..\Spritely\lib`);
- `src/ImportTests.GltfExport.pas`, which walks `TGorillaModel.Def`
  (a `TModelDef`) into GLB bytes and saves them through GLTFLib's
  `TglTFDocument.LoadFromGLBBytes` and `SaveToFile`;
- `src/ImportTests.Main.pas` and `.fmx`: the original on the left, the
  reloaded GLB on the right, the cameras turning together, and a log;
- `README.md`.

Not built in the cloud. Things to watch when it is first compiled:
- Gorilla.DefTypes declares its enumerations unscoped (`Default`,
  `Diffuse`, `Normal`, `None`, `Vertical`...);
- the FMX `TBitmapData`, `TVertexBuffer` and `TJSONArray.Add` overloads
  were written from memory.

First tests: an FBX, a USD and a GLB, to see whether Gorilla keeps source
coordinates (the Negate and winding boxes are for finding that out).

**ImportTests2** (11:45): the first compile found that `TGorillaModel.Def`
is declared as a `TCustomDef`, not a `TModelDef`. `TModelView.Def` now
returns it as a `TModelDef`, or nil when it is not one. The exporter unit
compiled.

**ImportTests3** (12:20). The owner's first run, on mashed_potatos.glb
(from a model-sharing site), matched the original's box and counts. The two files compared
in the scratchpad:
- positions, normals and UVs were the same sets of values (Gorilla
  reorders the vertices);
- **every triangle was reversed**, which the double-sided material hid,
  so Gorilla holds triangles clockwise and `ReverseWinding` is now on by
  default;
- Gorilla flattened the five-node hierarchy the site's converter wrote, whose two
  rotations cancel, into a model node and a mesh node with no matrices;
- the base colour came out as `TMaterialDef`'s starting 0.75 grey, where
  the file gave none, so with a diffuse texture that default is now
  written as white.

Checked at 12:15 with the owner's second export: every triangle, with its
winding, positions, normals and UVs match the original; the base colour is
white; the texture is the same pixel for pixel, though stored as RGBA PNG
(2.16 MB against the original's 1.76 MB RGB). The GLB round trip is exact.

**ImportTests4** (12:30), after the owner's first FBX (mashed-potatoes.fbx,
the same model): box and counts match, and the shape is right with no axis
negated, so Gorilla's FBX loader also hands over Y-up coordinates. Two
differences:
- the material is Gorilla's Phong (`mkDefault`), and roughness
  `sqrt(2/(n+2))` made it a glossy PBR with dark edges. That is the
  Beckmann alpha; glTF's roughness is its square root, so it is now the
  fourth root, and 1 when `UseSpecular` is off or the specular colour is
  black. The log gives the specular colour and power it came from.
- UnitScale is 0.01 (centimetres), and Gorilla shows the model at
  101.9 units. The new **Apply unit scale** box (off by default) adds a
  parent node scaled by it, so the GLB is in metres.

The right view drew the FBX's export smaller than the left, though the
boxes match; not yet explained (the GLB test framed both the same).

**ImportTests5** (12:45). christmas_tree_decorated, as the owner's glTF
(written by the owner's 3D suite) and as FBX, compared in the scratchpad against the glTF:
- **the FBX export is exact**: every triangle of both materials, with
  winding, positions, UVs and normals (hard edges included), once the
  node's matrix and the unit scale are applied;
- Gorilla's FBX loader **keeps node transforms rather than baking them**:
  the mesh node carries the exporter's Z-up turn (-90 about X) and a scale of
  100, and UnitScale is 0.01, so with Apply unit scale the GLB comes out
  at the glTF's size in metres;
- both materials came through on one mesh with two vertex groups;
- the export embedded the one atlas three times (the glTF uses it as two
  base colours and an emissive map); identical PNGs now share one image;
- not carried: the glTF's roughness 0.5 (the FBX has specular off, so 1)
  and `KHR_materials_emissive_strength` 4, which the FBX cannot hold.
The potato's framing difference did not recur with the tree.

**USD test** (12:55, no code change). The tree exported by the owner's 3D suite
as `.usda` (Z-up, metres, indexed faceVarying `st`), compared in the
scratchpad with the glTF:
- **positions and winding are exact** once Z-up is turned to Y-up;
- **Gorilla's USD loader reads the UVs wrongly**: it takes `st[n]` for the
  n-th face corner and ignores `primvars:st:indices`. The file is right
  (`st[st:indices[n]]` with V flipped matches the glTF at 39,695 of 39,708
  corners; the rest is rounding). Gorilla's UVs match the corner-number
  reading at 14,569 of the 14,582 values there are. For Gorilla's author.
- **Gorilla turns USD's Z-up the other way from its other loaders**: the
  model definition's matrix maps (x, y, z) to (x, -z, y), so up becomes
  -Y (FMX's screen up), where the glTF and FBX loaders leave +Y up. With
  Sprite3D's 180-degree X turn, a USD model therefore shows upside down
  in Sprite3D as well. For Gorilla's author too.
- In ImportTests, ticking Negate Y and Negate Z (a 180-degree turn about
  X, no mirror, so the winding is unchanged) gives a right-way-up GLB.

**USD2** (13:10; owner: "Sprite3d wont open usd (specifically usdc/a
files)"): `.usda` and `.usd` added beside `.usdc` in `MODEL_EXTENSIONS`
(with their MIME types and descriptions), OpenDialog1's filter (one "USD"
entry for all three), Open Directory's specs and the README. Gorilla's own
list of extensions could not be seen; ImportTests opened a `.usda`, so the
USD loader takes that. If a `.usdc` still fails, the error message will
say whether Gorilla lacks a loader for it. **notes/imports.md** written
for Gorilla3D's author: the two USD bugs with their evidence, the
behaviours a converter must know, and questions; linked from the README's
Further reading.

**USD3** (13:08; owner: "I already know G3D opens them fine", tried in
ImportTests): `.usdz` added the same way, MIME type `model/vnd.usdz+zip`
(the registered one), description "USD package".

**Assoc1** (13:25; owner: "The file association isn't linked with
Sprite3D"). Windows had the model types as they were when Open With was
ticked; nothing registered them again, so `.usda`, `.usd` and `.usdz`
were never offered (`IsRegistered` checks only the ProgID, so Settings
still showed it on). New `RefreshModelAssociations` (Sprite3DHelpers),
called first in `FormShow`: on Windows, when Open With is on, registers
again (every extension, this exe), and when Always is on and not every
type opens with Sprite3D, `MakeDefault` for them, saving the backup if it
changed. No dialog at start-up. Linux already re-registered in
`RegisterProjectFiles`; macOS uses the bundle. To test: start Sprite3D
once, then double-click a `.usdz`.

**ImportTests7** (13:55; owner has an animated parrot as GLB and FBX; the
FBX's animations are named "Rig|..."; "we can live with that"): skins and
animations in the exporter, from reading Gorilla.DefTypes:
- joints are reached through `Children`, `TJointDef.Joints` (a map, taken
  in name order) and `TArmatureDef.Roots`; armatures not reached are put
  under the model's node;
- weights: per `Skin.LinkedJoints[j]`, its `Indices`/`Weights` (after
  `ApplyMeshWeights(mesh.Id)` when it has per-mesh sets), mapped through
  the mesh's `VertexIndexMap` as `ApplyVertexJointsRelation` does; four
  heaviest, normalised; unweighted vertices follow joint 0;
- inverse bind matrices = mesh global * inverse(joint global) at rest
  (row vectors), with the largest difference from Gorilla's
  `InvBindMatrix` logged, as its meaning is not certain;
- channels: `TTransformationInterpolatorDef` decomposed to T/R/S;
  `TPoint3DInterpolatorDef` Position.Point / Scale.Point;
  `TQuaternion3DInterpolatorDef` through FMX's quaternion-to-matrix, then
  decomposed, so its sense is Gorilla's; times = key * Duration; LINEAR;
  each animation's kinds of key are logged;
- animated nodes are written as TRS (glTF forbids an animated matrix);
- the window has Skins and Animations boxes and Play/Stop for the chosen
  animation in both views.

**ImportTests8** (14:10). The parrot GLB (owner's screenshot and files,
13:52), compared in the scratchpad with the source:
- **skin exact**: same 66 joints in the same order, every vertex's
  weights to 1e-7, inverse bind matrices to 4e-7 (Gorilla's own agree with
  the rest-pose ones to 4e-7, so `InvBindMatrix` is the inverse bind
  matrix in row-vector form);
- **animations exact**: all 33, every channel at every key, to 0.06
  degrees; Gorilla hands over only `TTransformationInterpolatorDef`
  (TransformMatrix) keys, one per joint, at every time any channel had a
  key (383,685 against the source's 143,335). The source used STEP on
  179 of 198 samplers; FMX's interpolation types have no step, and the
  values came through anyway.
Changes: **Thin keys** (on) drops keys the kept neighbours give to 1e-5
(checked over all dropped keys; rotations only drop when essentially
equal, as unit quaternions never lie on a chord), giving about 102,000
keys and 0.04 degrees; **metallic-roughness**: Gorilla splits glTF's
texture into Roughness and Metalness channels, so the same picture is
written once as `metallicRoughnessTexture`, or two are packed (G, B).

**Parrot FBX** (14:05, owner's log and `.raw.glb`; no code change),
compared in the scratchpad with the parrot GLB:
- rest pose exact: every joint where the GLB has it, to 5e-8, at scale
  0.01 (centimetres) with no turn; the FBX has one more joint, `Rig`;
- the GLB's clips start one frame (1/30 s) later than the FBX's (keys at
  1/30.. against 0..; 1.000 s against 0.967 s), so they compare shifted;
- shifted, 27 of the 33 clips match to 0.2-0.74 degrees on every joint;
  **Dead, Dead_Falling (COG 123 deg), Death (25), FlyDown, FlyGlide and
  Walk (legs, 34)** do not. Either the two sources differ or Gorilla's
  FBX key heuristics (pre-rotation and absolute-key votes per stage)
  misfire on those. The owner (14:15): "The GLB looks good walking
  straight, the FBX is walking down-hill", so it is the FBX loader;
- 376 weights beyond four per vertex dropped (the FBX has more
  influences; the GLB had four); JOINTS_1/WEIGHTS_1 could carry eight.

**Notes2** (14:20; owner: "Add all findings to notes for Gorilla3D
author"): `notes/imports.md` now has bug 3 (the six FBX clips, with the
heuristics suspected), and behaviours 10-15 (metallic-roughness split,
dense matrix keys, STEP lost, `InvBindMatrix` meaning, more than four
weights, the extra `Rig` joint and stray `Action` clip), plus the parrot in
the results table and a question on forcing the FBX decisions.

**Bear1** (14:30; owner: a bear's eyes stay put when Sprite3D holds or
steps Talk, but move in ImportTests). The eyes are unskinned meshes under
"Eye Right"/"Eye Left", children of the head joint; Talk moves the joint
and animates the eye nodes. ImportTests plays with `PlayAnimation`, so the
skeleton is evaluated. Sprite3D's held frames (the player and every
capture) paused the clock and used `SetFixedCacheFrame`, which poses only
the baked skinned vertices. `TSprite3DAnimationFrames.ShowFrame` now also
calls `SeekTo(Baked / FAnimation.FrameRate)` (or the phase's time when the
rate is 0) before `SetFixedCacheFrame`. Behaviour 16 in
`notes/imports.md` asks Gorilla's author about it. **To test**: hold and
step Talk (the eyes must follow the head); export Talk and check the eyes
in the frames. On Delphi 13 a seek is evaluated on the next drawn frame,
so if exported frames show the eyes one frame behind the body, the
capture needs to wait a frame after `ShowFrame`; not done until seen.

**Bear2** (14:35; owner: "Not fixed", screenshot at 15/21: the eye now
floats above the head, so the seek moved it, but to another pose than the
body's). The seek used `Baked / FAnimation.FrameRate`; it now uses the
same phase as the baked frame, `Phase * FDuration` (the skeleton's own
length), in case the baked frames' rate and the skeleton's length
disagree. In DEBUG builds each held frame logs (FMX `Log.d`, the IDE's
event log) the frame, phase, baked frame and count, `FrameRate`, both
lengths and the seek time. If the eye is still off, those numbers say
whether it is timing or Gorilla not posing the head joint while a fixed
cache frame is set.

**Bear3** (14:40; owner: "Eyes in the one place when stepping", log
showing the seek times right: 161 baked frames at 60 = 2.683 s, skeleton
2.667 s). So with a fixed cache frame set, Gorilla does not pose the
skeleton. `SetFixedCacheFrame` is no longer used: `ShowFrame` seeks the
paused clip (`SeekTo(Phase * FDuration)`) whether baked or not, and
`Finish` no longer unsets a fixed frame. On Delphi 13 a seek is posed on
the next drawn frame, so `TSprite3DFrameSource.NeedsDrawnFrame` (True for
animations there) makes `TSprite3DFrameCapture.QueueGrab` wait at least
`POSE_SETTLE_TIME` (35 ms) before each grab; `FDelayPending` stops
`Cancel` freeing the capture while such a wait is queued. README's
"Poses, not blended images" rewritten; behaviour 16 in
`notes/imports.md` gains the result. **To test**: step Talk (eyes must
follow); export Talk (eyes in place in every frame, no frame lagging);
an export of the parrot or another model looks as before.

**Bear4** (14:50; owner: Bear3 "doesn't move at all when frame-stepping";
then sent Gorilla.Animation.pas and Gorilla.Animation.Controller.pas,
staged outside the repo). The source shows why: `TSkeletonKeyAnimation.
SeekTo` only sets FTime; the pose (and `TransitionTime`, which picks the
baked frame) is computed by `ProcessTick`, and on Delphi 13
`TGorillaRenderClock.Tick` skips paused clips (it drops `FPause` for one
`ProcessTick` per frame). `GorillaSkipJointsWhenCached` is False, so a
tick poses the joints too. `TSprite3DAnimationFrames.SeekTo` now does
what the clock does: `SeekTo`, `Pause := False`, `ProcessTick(0, 0)`,
`Pause` back (as it was on Delphi 13; True before, as the old code did).
The pose is there at once, so the 35 ms wait and `NeedsDrawnFrame` from
Bear3 are gone (`FDelayPending` stays, for SettleTime). Behaviour 16 in
`notes/imports.md` gains this and asks for a public "pose at T now".

**Notes3** (14:55; owner: "explain this fix in detail for Gorilla3D's
author"): `notes/imports.md` has a new section, *Holding an animation on
one frame*: the bear, what the render clock, `ProcessAnimation` and
`GetCurrentCachedFrame` do, a table of the three failed attempts and why,
the code Sprite3D now runs, and the two Gorilla3D changes that would
replace it. Item 16 points there, and a question asks whether the
workaround is safe to rely on.

**Bear5** (15:05; Gorilla3D's author sent his own `Sprite3DAnimCapture.pas`
and `Sprite3dMain.pas`, based on the pre-Bear unit and pre-Assoc1 main:
"I'm not sure if it's a good idea to automatically cache those attached
objects too with the parent mesh, even if they aren't skinned"). Adopted
as he wrote it, with LF line endings:
- `SeekTo` clears `Skeleton.Pause`, seeks, `ProcessTick(0, 0)`, sets
  `Pause` again, on every Delphi version;
- `ShowFrame` keeps `SetFixedCacheFrame(Baked)` and then
  `SeekTo(Baked * FDuration / (FCachedFrames - 1))`, Gorilla's bake time;
- `Finish`, `QueueGrab` and `Cancel` are as before the Bear work (Bear3's
  `NeedsDrawnFrame`, `POSE_SETTLE_TIME` and `FDelayPending` are gone);
- `Sprite3dMain`: `GorillaModel.ResetToBindPose()` before
  `PlayAnimation(ani)` when the selection changes (the only change in his
  copy; Assoc1's start-up code kept).
Only the class description was corrected (it still said a seek lags a
frame on Delphi 13). README's "Poses, not blended images" and
`notes/imports.md` (item 16, "What Sprite3D does now (the author's fix)",
"Left for Gorilla3D") describe it.
**Tested by the owner** (15:08): "Yep - that is a good fix".

**Gltf1** (15:40; owner: "behind debug is good. There are some features
from the GLTFMerge application we actually want to add as well so this
will be a submenu with modals for new options"; chose Merge animations,
Split long animations, Add parts, plus import; work on the open model,
saving a GLB and opening it; a glTF model read from its own file; GLTFLib
from `ImportTests/GLTFMerge`):
- `ImportTests/src/ImportTests.GltfExport.pas` moved (git mv) to
  `src/lib/Sprite3DGltfExport.pas`; ImportTests now uses it from there;
- `src/lib/Sprite3DGltfDocument.pas`: `IsGltfFile`, `LoadModelDocument`
  (glTF straight from its file, anything else through `BuildGlb`),
  `SaveDocumentAsGlb`;
- File, Debug, **glTF** submenu (`GltfMenu` in `Sprite3dMain.fmx`, moved
  into Debug by `BuildDebugMenu` or freed with Tools): Export as GLB...,
  Merge Animations..., Split Long Animation..., Add Parts...; dialogs
  `Sprite3DGltfExportForm`, `...MergeForm`, `...SplitForm`, `...PartsForm`
  (generated .fmx, kept in step with the .pas); handlers and
  `GltfToolsReady`, `GltfModelDocument`, `SaveGltfResult` in Sprite3dMain;
  each tool saves `<model>_export/_merged/_split/_parts.glb`, refuses the
  model's own name, and opens the result with `SwitchModel`;
- merging, splitting and parts run on the main thread (debug tools; small
  files): one duplicate answer chosen in the dialog, no per-name question;
- GLTFLib's MIT licence: `licences/GLTFLib-LICENSE.txt`, `LICENCE_GLTFLIB`
  in the `.rc` and `Sprite3DLicences`, `.res` rebuilt (a Python writer in
  the scratchpad reproduced the old `.res` byte for byte first), and
  `docs/licences-required.md`;
- README: the glTF entries under the features, the requirements, the
  layout trees.
Not compiled. To test: each tool on a GLB, and Export on an FBX.

### Things to check

- Variable's dialog is placed at the main form's centre, so on a wide
  window it can go past the right of the screen (seen 9 November, 12:00).
  Not changed; ask.
- Renaming the shift and rise settings keys (`panEnabled`, `panX`,
  `panZ`, from when they moved the camera along the model's axes) was
  offered with ShiftRise1 and not answered. The README now names the keys
  without the history. If they are renamed, read the old keys too.
- Other platforms have not seen the 9 November work: macOS (grabs are
  screenshots there), Linux (the Oblique submenu on the FMX menu bar, the
  Background dialog's file dialog) and mobile (the drawer's "View,
  Projection, Oblique" group; the background image path typed).
- A Windows chime when ProjectionTest closes, with no dialog (carried
  over from SRDelphiFMX, cause unknown).
- macOS with Metal: whether `MakeScreenshot` keeps the viewport's
  transparency (`notes/viewport.md`, Still to check).
- Popup menus (`FAnimationPopup`) on Linux were not part of the menu fix;
  check they show full names.
- Linux: run under PAServer, closing gives "Runtime error 217" straight
  after Gorilla3D's `ResetDefaultContextClass` log line, sometimes with
  "AniThread not available anymore" lines before it. Run from a terminal it
  closes cleanly. Tested on 27 October 2026: `FormDestroy` runs before
  Gorilla3D unregisters its context, so the form is not freed late, and
  nothing of Sprite3D's is left at that point. The owner has passed it to
  Gorilla3D's author; do not work round it in Sprite3D.
- `notes/code-review.md` (9 November 2026) is a full code review of
  `0d0103f`, 62 findings in the order to take them, with the state of
  each kept at its top. Zip **Fixes1** (22:45, applied, not yet
  tested) took its items 1, 2, 3, 4 and 6: the progress dialog is finished
  when a quit is confirmed mid-export (`FinishBatch`); `HeaderWritten` is
  cleared before `av_write_trailer` (`Sprite3DVideo`, both routines);
  `DefaultModelDir` lost its dead lines and its two descriptions now say
  what it does (the assets folder everywhere; behaviour unchanged);
  `SwitchModel` waits while `FScanning`; and calls `ContinueLoading` on
  its not-found and capturing exits. **Fixes2** (22:55, not yet tested) took item 7:
  `AnimationListToJson` saves the first animation's frame override too
  (test: type a count for the first animation, restart, it must still
  be there). Item 5 (GIF LZW) was withdrawn as
  wrong. Item 8 (the OpenH264 downloader's same-name replace) was fixed
  by Cisco1; item 9 is in part met by the list's https addresses. To test Fixes1: start a strip export, close the window, answer
  Yes (it must quit); open a folder of many models and drop a model on
  the window while the count is rising (it must load after the folder);
  open several files at once with one missing (the rest must load); an
  MP4 export still saves.
- `src/Sprite3d.dproj` deploys `styles\buildstyles.cmd` and `README.md`
  to several platforms (on macOS under StartUp, so `System.StartUpCopy`
  copies them into the user's folders; see Lessons learned); nothing is
  disabled. The `.rc` is not deployed. Ask the owner before disabling
  them.
- `src/Sprite3d.dpr` has `ReportMemoryLeaksOnShutdown := True` commented
  out, though its comments, the README and this file's Gorilla3D notes
  say it is set. Ask whether to turn it on or correct the descriptions.

### Done: the Tools menu, OpenH264 and licences (9 and 10 November 2026; merged into `main` as `c2b9f2f`)

**GitHub `main` is at `c2b9f2f`, "Merge branch 'external-edges'"
(10 November, about 10:45), and is the owner's copy.** It merges
`external-edges` (`873be04`, "Add some tools + fix licenses/h264": every
zip from ScanSprites1 to Licences1) into `50e4711`, "Fixed per code
review" (Fixes1 and Fixes2). The owner built and tested it at 10:51:
"everything appears correct". There is one line of work again, no zip is
outstanding, and a new session builds on `main`. `external-edges` is
merged; nothing depends on it.

How the merge went, for next time: the code-review fixes had reached
`external-edges` on 9 November only as files unzipped from MergeMain1,
not as a git merge, so git saw both branches change the `.md` files and
the merge conflicted in `README.md`, `CLAUDE.md`, `notes/code-review.md`
and `notes/cisco.md`. The branch's versions were right for the first three
(they were written on top of `main`'s); `notes/cisco.md` and the unused
`src/lib/Sprite3DCiscoLicence.pas`, which zips could not delete, were
removed in the merge. MergeMain1 had also left out `Sprite3DVideo.pas`
(unchanged from `main` at the time), so the branch lacked Fixes1's
`av_write_trailer` change until this merge brought it in. Checked at
10:47: `main` equals `external-edges` but for those three files, with no
conflict markers, and every unit, form and resource the project names
exists. When a branch needs another's changes, merge with git rather
than unzipping files over it.

Which of the 9 and 10 November deliveries the owner tested one by one is
not recorded beyond what each entry under *In hand* says; the "To test"
lists are in the README's feature text. When the owner reports a result,
note it here.


**MergeMain1** (23:00): the Tools work, on `external-edges` up to
`448eb6c` "Tools1" (ScanSprites1 to ScanAtlas3 and the owner's `data/`
files), merged into `main` `50e4711` "Fixed per code review" (Fixes1 and
Fixes2). The code merged without conflicts (`Sprite3dMain.pas` and
`Sprite3DHelpers.pas` were changed on both sides, in different places).
`notes/code-review.md` is `main`'s, which records the fixes; the Tools
entries were added to `main`'s README and this file. Work goes on from
this merge; where it is committed is the owner's choice.

The owner is building a **Tools** menu, last on the menu bar, desktop only
(freed in `FormCreate` on Android and iOS before the drawer is built, so
`ToolsMenu` and `ScanSpritesItem` are nil there). Its first item:

- **ScanSprites1** (20:10, not yet tested): Tools, Scan Sprites... measures
  a sprite made elsewhere, to be replaced by one of Sprite3D's: one folder
  of PNG frames per animation, the folder's own name as the reference.
  New units: `lib/Sprite3DPngReader.pas` (pure-Pascal PNG reader, every
  colour type and depth, Adam7, tRNS; worker-thread safe, as FMX bitmaps
  are kept to the main thread), `lib/Sprite3DFolderDialog.pas`
  (`SelectFolders`: `IFileOpenDialog` with `FOS_PICKFOLDERS or
  FOS_ALLOWMULTISELECT` on Windows, `NSOpenPanel` on macOS, FMX's
  single-folder dialog on Linux), `lib/Sprite3DSpriteScan.pas`
  (`SpriteFolders`, `ScanSpriteFolder`: `MeasureFrameEmpty` per frame,
  `LeastFrameEmpty` over the folder, content box, coverage = active pixels
  / content box, min, mean, max), `ui/Sprite3DSpriteScanForm.pas` (grid,
  Copy as TSV). Setting `scanSpritesFolder`. The owner said "a decision will
  be made later" on what to do with the coverage figures; the next Tools
  items will build on these scans.

- **ScanSprites2** (20:35, follows ScanSprites1, which the owner pushed as
  `a60fa93` "Tools1" on the branch `external-edges`, where work now goes;
  the first scan worked on Windows, 5 animations of 154 x 154):
  `CombineSpriteScans` takes the least of each side over every folder (the
  owner: as with our own sprites, each edge's minimum may come from a
  different animation) and works every frame's coverage out again against
  that shared content box; a last row, `(all animations)`
  (`SPRITE_SCAN_COMBINED_NAME`, `Combined` True). Folders of different frame
  sizes are not combined; the last row says so.

- **ScanSprites3** (21:00, follows ScanSprites2; owner, 20:57): every
  frame of every folder must be exactly the same size or the scan FAILS
  (`SizeMismatch`, message naming two frames, no grid). The
  `(all animations)` row is gone; `CombineSpriteScans` still gives the
  shared box, shown above the grid and on Copy's last line. Columns:
  Animation, Frames, Frame size, Left, Top, Right, Bottom, Width, Height
  (the folder's own content box; Left and Top are its offset), Cover (the
  highest coverage, of the shared box). The mean and min coverage are no
  longer shown (still in `TSprite3DSpriteScan`).

- **ScanAtlas1** (21:30, follows ScanSprites4; owner, 21:23): Tools, Scan
  Atlas... (`ScanAtlasItem`): `TScanAtlasForm` asks for the frame size and
  the PNG sheets (one atlas, possibly several sheets); `ScanAtlas` in
  `Sprite3DSpriteScan` cuts each sheet into frames (`MeasureCell`), counts
  empty cells as `UnusedFrames` and leaves them out, combines the rest with
  `LeastFrameEmpty`, coverage of that box with min, median
  (`CoverageMedian`, the owner's "mid") and max. A sheet not a whole number
  of frames, or unreadable, fails the scan. One row for the atlas; the
  owner has lists of which frames are which animation, for a later
  analysis. The results dialog is now generic (`TScanTable`,
  `SpriteScanTable`, `AtlasScanTable`, `EmptyScanTable`) and the main
  form's machinery is shared (`FToolScanning`, `ShowToolResults`,
  `ShowPendingToolResults`, `UpdateToolItems`). Settings
  `scanAtlasFolder`, `scanAtlasFrameWidth`, `scanAtlasFrameHeight`.

- **ScanAtlas2** (21:45, follows ScanAtlas1; owner, 21:37): Saving column,
  the perfect-packing limit `1 - ActivePixels / SheetPixels`
  (`PackingSaving`); `AtlasScanPackingText` gives the totals and the side
  of a square holding the drawn pixels, on Copy's last line and in Debug.

- **ScanAtlas3** (21:50, follows ScanAtlas2): Trim saving column,
  `1 - TrimmedPixels / SheetPixels`, every used frame trimmed to its own
  tight box (`TrimSaving`); its totals join `AtlasScanPackingText`.

- **ScanAtlasFolders1** (23:05, follows MergeMain1, which tested well;
  owner, 22:59): Tools, Scan Atlas Folders... (`ScanAtlasFoldersItem`,
  `TScanAtlasFoldersForm`): a root, a sheet file name (default
  `Spritesheet.png`) and the frame size; `ScanAtlasTree` finds every copy
  below the root (`FindAtlasSheets`, recursive `FindFiles`) and runs
  `ScanAtlas` on each as a one-sheet atlas, Name = folder relative to the
  root (`AtlasRelativeFolder`). One row per sheet (`AtlasTreeTable`); a
  failing sheet fails only its row. New Packed column on both atlas tables:
  `AtlasPackedSide` = ceil(sqrt(TrimmedPixels)), the owner's "sqrt(total
  area)" for a rectangle-packed sheet. The owner: semi-transparent pixels
  are shadow and count; only alpha 0 is empty, as already. Settings
  `scanAtlasRoot`, `scanAtlasFileName`. `LogAtlasScan` shared.

- **DebugTools1** (10 November, 09:20; owner, 09:19): the Tools menu now
  lives in File, Debug (`BuildDebugMenu` moves `ToolsMenu` there, or frees
  it when debugging is off and always on Android and iOS; the FormCreate
  mobile free is gone). File, Debug is inserted above `FileSeparatorItem`
  and has no separator of its own: `FDebugSeparator` is gone, as it put
  two separators together above Exit. `ToolsMenu` is still designed at the
  top level of the menu bar in the .fmx.

- **DebugTab1** (10 November, 09:40; owner, 09:37): the Debug tab is
  shown only while debugging is on (`BuildDebugMenu` sets
  `DebugTab.Visible`; Disable Debug hides it, moving to the model tab
  first with `SelectModelTabOnly(FStaticMode)`). DebugMemo is still
  written to while hidden. The owner also asked to check the OpenH264
  JSON against Cisco's licence and, if it complies, remove the Cisco
  items: the JSON could not be fetched from the sandbox (proxy 403), and
  Cisco's binary licence has three more conditions the program does not
  meet yet (user enable/disable, the "OpenH264 Video Codec provided by
  Cisco Systems, Inc." text, the licence text reproduced); see Cisco1.

- **Cisco1** (10 November, 09:55; owner, 09:44): OpenH264 now meets all
  four conditions of Cisco's binary licence. The list (`openh264.json`,
  attached by the owner at 09:41) points every entry at
  `https://ciscobinary.openh264.org/`; the owner was told its `win64arm`
  entry named the plain ARM64 build, which ARM64EC cannot load; the owner
  changed it to the win64 file (10 November, 10:06). Settings, MP4 video: `OpenH264Check` ("Use OpenH264
  for H.264 MP4 video", `useOpenH264`, default on), `OPENH264_NOTICE`
  beside it, and Cisco Licence... showing `OpenH264BinaryLicence`
  (`lib/Sprite3DCiscoLicence.pas`, generated from
  `licences/OpenH264-BINARY_LICENSE.txt`, Cisco's v1.0 text from the
  openh264.org site's source, `gh-pages` of cisco/openh264; check the
  generated text against the file if either changes).
  `SetOpenH264Enabled` in `Sprite3DOpenH264` gates `OpenH264Available` and
  `OpenH264Retry`; off at start-up, `PrepareOpenH264` fetches nothing.
  Review item 8 fixed: downloads are saved as `InstalledFileName`, the
  URL's name with 8 hex digits of its SHA-256 before the extension.
  `notes/cisco.md` removed, its work done. The BSD notice for the
  translated OpenH264 headers is a separate, still-open item in
  `docs/licences-required.md` (Notices still to add).

- **DebugH264** (10 November, 10:00; owner, 09:59): debugging no longer
  turns OpenH264 off. `PrepareOpenH264` exits only on iOS, when
  `useOpenH264` is off, or when already prepared; the start-up and
  Disable Debug lines no longer mention OpenH264.

- **Licences1** (10 November, 10:15; owner, 10:09: "make the licence text
  files part of the executable so I won't forget to include them"; the
  owner packages the FFmpeg DLLs and models/uvcube.glb themselves). Every
  third-party licence or notice is a text file in the root `licences/`
  folder, named in `licences/Sprite3DLicences.rc` as RCDATA
  (`LICENCE_OPENH264_BINARY`, `_OPENH264_BSD`, `_FFMPEG`, `_LGPL21`,
  `_DELPHIFFMPEG`, `_NEON`), compiled by `licences/buildlicences.cmd`,
  which `src/styles/buildstyles.cmd` now calls at its end (so no
  PreBuildEvent change), and linked by `{$R '..\licences\Sprite3DLicences.res'}`
  in the .dpr. A ready-built `Sprite3DLicences.res` was delivered,
  written to brcc32's layout (flags $0030, language $0809, names upper
  case) and checked by reading it back. `lib/Sprite3DLicences.pas`
  (`ThirdPartyLicences`, `LicenceText` via `TResourceStream` with
  `PChar(10)`, `AllLicencesText`, `OPENH264_NOTICE`) replaces
  `Sprite3DCiscoLicence.pas`, deleted. `ui/Sprite3DLicencesForm`: File,
  Licences... (`LicencesMenuItem`), a combo and a memo, Save All... writing
  `THIRD-PARTY-NOTICES.txt` (UTF-8, no BOM); Settings' Cisco Licence...
  opens it at Cisco's. `Sprite3DOpenH264.pas` carries Cisco's full 2013
  BSD text in a comment. Sources of the texts: Cisco's `LICENSE` (master)
  and `BINARY_LICENSE.txt` (gh-pages), Neon's `LICENSE` at the submodule's
  commit, FFmpeg `n8.1`'s `COPYING.LGPLv2.1`, `src/ffmpeg/LICENSE.txt`;
  `FFmpeg-NOTICE.txt` was written here (says LGPL build, version 8.1:
  the owner is to check the DLL pack's version and configuration).
  FastMM5's notice waits on the owner's choice of its licence.

To check when the owner reports: the multi-select dialog on Windows and
macOS (the macOS one uses `setMessage` and `setDirectoryURL` from
`Macapi.AppKit`, unbuilt); the figures against frames whose borders are
known; a folder of mixed sizes; the grid waiting while a model loads.

### Not yet chosen

What the owner has mentioned: the rest of
`TSpritelyProjection` in Sprite3D (the dolly zoom; shift and rise are
done); the background image in animation exports, and scaling it by hand
(left out of Background1 on purpose); the Variable dialog's placement and
the key rename above.

From the glTF work (10 November): the glTF tools run on the main thread
and ask one duplicate question for all names (GLTFMerge asks per name, on
a worker thread); Add Parts uses GLTFLib's default options; JOINTS_1 /
WEIGHTS_1 for more than four weights (the parrot FBX dropped 376);
morph targets, lights and cameras are not exported; whether to leave USD
out of Export as GLB until Gorilla3D fixes bugs 1 and 2 (it is offered,
with the README saying what goes wrong).

### Delivered on 9 November 2026 (all in `2b98a73`)

Newest first. Each was a zip of whole files; the detail is now in the
README's feature text, so only what a later change needs to know is kept.
None changed `Spritely/`.

- **ViewDefaults1** (13:47): with no settings file, Show Bounding Box,
  Grid, Axes and Model Volume all start off (`TSprite3DAppSettings.Create`,
  and the `.fmx` items lose `IsChecked`). The headlight still starts on.
- **CutPreview1** (13:39): the Background dialog's Image preview draws the
  grab's frame over the whole image, the cut-off parts darkened, the frame
  outlined in black dashes over white (`NewImagePreview`, `GrabWidth`,
  `GrabHeight` set by `BackgroundSettingsMenuItemClick`).
- **ImageAlign1** (13:31): `TSprite3DImageAlign` (nine positions,
  `backgroundImageAlign`) and the dialog's nine radio buttons; File,
  Settings' group is captioned Render (controls still `OutputGroup`,
  `OutputHelpersCheck`; key `helpersInOutput`).
- **OutputSetting1** (13:19): "Grid, Axes and Model Volume in Output"
  moved from the View menu to File, Settings
  (`TSprite3DGeneralSettings.HelpersInOutput`).
- **DialogWheel1** (12:58): while Variable's dialog is open
  (`FOrbitalDialog`), the wheel and left-drag over the view change the
  dialog's Distance and Azimuth (`DialogMouseView`), not the mouse view.
- **KeepRestore1** (12:52): `FRestoringView` stops `ResetViewSettings`
  running while `FormCreate` puts the last view back, so the saved shift,
  rise and distance survive a restart.
- **OutputHelpers1** (12:46): `HideHelpersForGrab` runs for every grab,
  not only captures; the bounding box and Animation Volume are never in
  output, the grid, axes and Model Volume only when the setting is on and
  it is not a measuring pass. (Its menu item became a setting in
  OutputSetting1.)
- **GrabDistance1** (12:42): `OffscreenBeforeGrab` applies Variable's
  distance factor (`FFactor`) after `GrabFit`, so a grab matches the view;
  before, it was the plain fit. Exports are unaffected (two passes).
- **Licences1** (12:33): `docs/licences-required.md`, new; the README's
  Licences links to it.
- **Background1** (12:16): image backgrounds (`TSprite3DBackgroundKind.Image`,
  last in the enum so saved names are unchanged; `ImageFile`, `ImageFit`,
  `BackgroundImage` main thread only, `BackdropPixels` for grabs; the Metal
  screenshot path draws it under the screenshot); "Temporary Mouse View"
  renamed "Mouse View" (key still `mouseView`); Variable's tick wording and
  `distanceFactor` kept with `keepShift`. Animation exports still have no
  background.
- **ShiftKeep1** (12:07): "Keep between sessions" tick (`keepShift`,
  `PanKeep`); shift and rise saved only while it is ticked.
- **ShiftLog1** (12:00): `LogShift` Debug line for every shift change;
  `FormatFloat` with `SIGNED_FORMAT` for the signed labels.
- **PresetViews1** (11:53): every fixed view and every oblique calls
  `ResetViewSettings` (factor 1, shift and rise 0, mouse view reset).
- **ShiftRise4** (11:37, replacing a withdrawn ShiftRise3): the mouse view
  readout's Distance is a factor (`FMouseZoom`); a shift of 1 or -1 puts
  the near side of the fitted volume on the picture's edge
  (`SweepViewExtent` in `Sprite3DSweep`); `ShiftCamera` places the shift
  again after every mouse view change (`FPlaceEnabled`, `FPlaceShift`,
  `FPlaceRise`).
- **ShiftRise2** (11:23): Variable's dialog opens from `ShownCameraSpec`,
  taking the mouse view in; `DistanceTrack.Min` 0.2; orthographic slide
  (`PutOnSlide`, `TakeOffSlide`) around every mouse view change.
- **ShiftRise1** (10:48): the old pan (moving the orbit centre) replaced by
  `TSpritelyProjection`'s lens shift (`PlaceShift`, `SetLensShift`) in
  perspective and the obliques, and a camera slide (`ShiftView`,
  `FAppliedPan`) in orthographic; fits run unshifted; grabs keep the view's
  shift (`FGrabAppliedPan`, `FGrabShiftX/Y`); exports leave it out.
- **ObliqueMenu1** (10:21): View, Projection, Oblique submenu
  (`ObliqueMenu`, `CheckProjection`); Military reads azimuth 45;
  `EnterObliqueView` sets all three angles every time, the same oblique
  chosen again included; Variable's dials all live in an oblique.

### Delivered on 8 November 2026 (on `main` before the merge)

- **ObliqueView1**, **Notes1**, **Projection2**, **Projection1**: View,
  Projection with Perspective, Orthographic and the four obliques drawn by
  `TSpritelyProjection` (`FProjection`, made in code in `FormCreate`, freed
  first in `FormDestroy` with `OrbitCamera.Projection` nil first); choosing
  an oblique turns the camera to its angles (`EnterObliqueView`,
  `LeaveObliqueView`, `FObliqueView` and its angles kept for the way back);
  `camera.projection` in metadata; benchmark prefixes `cav`, `cab`, `mil`,
  `plan`. Projection2 fixed `Spritely.Projection.pas` to keep one slot per
  drawing context (see Lessons learned); `Spritely/NOTES.md` began with
  Notes1. The owner reported "the views look good" and grabs matching the
  view on Windows (22:03).
- **SpritelyMove1**, **SpritelyMove2**, **Lights1**, **Merge1**: Spritely
  moved here from SRDelphiFMX, with ProjectionTest and its models, and
  building for WinARM64EC; `Sprite3DCamera.pas` deleted, the main form
  using `TSpritelyOrbitalCamera` (`OrbitCamera`), whose camera and
  headlight are kept in `GorillaCamera` and `GorillaLight` so the rest of
  the form was unchanged; View, Lights (Headlight, Original Light). Merge1
  put back GrabSize4096 and DragDrop, which whole files built on GitHub had
  undone (see Lessons learned). The owner reported "all back normal again"
  (20:35).

### Earlier (27 October to 6 November 2026, on `main`)

Mouse View (27 October), one window on Windows (`HandOffToRunningInstance`,
`WM_COPYDATA`; Linux still opens a second window), custom grab size to
4096 (`GRAB_SIZE_MAX`, 4 November), drag and drop (overrides of the form's
`DragOver` and `DragDrop`, 6 November), the Linux menu fix
(`UseFmxMenuBar` copies, 27 October), `tools/pasdoc_check.py` and this
file. All described in the README. The Linux menu fix still wants the full
check: run from a terminal, no GTK warnings at start-up or while using the
menus, one bar with full names, the items added in code working (Models,
Animation Settings; View, Camera, Mouse View and Lock Camera; File, Debug
with `--debug`), ticks moving, and the animation pop-up menu working.

## Lessons learned

These cost time once.

- **Gorilla3D, from the ImportTests work (10 November 2026):**
  `TGorillaModel.Def` is a `TCustomDef`, so cast it (`TModelView.Def`);
  Gorilla.DefTypes enumerations are unscoped (`Default`, `Diffuse`,
  `None` clash with ours, so qualify them); `TSkeletonKeyAnimation.SeekTo`
  only sets the time, and a paused clip is not posed until something ticks
  it (the author's fix: unpause, seek, `ProcessTick(0, 0)`, pause; see
  `notes/imports.md`). Do not guess at held-frame fixes from outside: ask
  for his source, as Bear1-3 all failed.
- `Packed` is a reserved word in Delphi; it cannot name a variable.
- A loop variable cannot be one of the outer routine's locals used in a
  nested procedure (E1019).
- `.res` files: rebuild them with the Python writer used for
  `LICENCE_GLTFLIB` (RT_RCDATA, flags $0030, language $0809, names in
  upper case); check it first by reproducing the old `.res` byte for byte.

- **GitHub can be behind the owner's copy by several zips.** Before
  delivering a whole file, make sure it was built on the owner's latest
  copy of it: the files the owner attached, the last zip of this
  conversation, or, if neither has it and "Where the work is" lists zips
  not on GitHub that touch it, ask for it first. On 8 November 2026 whole
  files built on GitHub undid GrabSize4096 and DragDrop (see Merge1).
- **FMX menus on Linux**: see *Menus* above. The full story, written for
  any FMX program, was worked out on GDEMFetch
  (<https://github.com/peardox/GDEM>) in October 2026: the native GTK bar
  shows first letters only; moving items to a `TMenuBar` then freeing the
  `TMainMenu` leaves items holding destroyed GTK widgets; freeing a
  `TMainMenu` with items still in it leaves GTK's bar showing. Copy, empty
  item by item, call `RecreateOSMenu`, free, rename the copies.
- Naming a component owned by the form points the form's published field
  of that name at it (`TComponent.SetReference`); freeing it sets the field
  to nil. That is what lets the menu copies take over the designed items'
  fields.
- `ExcludeTrailingPathDelimiter('F:\')` gives `F:`, the current folder on
  drive F, not its root. Keep drive roots whole when tidying folder paths.
- `ForceDirectories` is not safe when several threads create folders under
  the same new parent: one can give up. Create folders under a lock.
- Delphi's flow analysis is unreliable around `try`/`except`: removing a
  starting value it calls unused (H2077) can bring "might not have been
  initialized" (W1036). Set the value where every path can see it.
- The IDE adds files put in the project (styles, scripts) to every
  platform's deployment; on macOS `System.StartUpCopy` then copies them
  into the user's folders. GDEM disables such entries in its `.dproj`'s
  Deployment section (`<Enabled>false</Enabled>`).
- **Several contexts can draw one Gorilla3D scene.** Sprite3D's
  off-screen grab pass draws with a `TContextOpenGLWindows` of its own,
  not the viewport's. Anything that patches a context from inside the
  frame (`TSpritelyProjection`) must keep its state per context, and must
  not write to a context outside its own frame unless it is the
  viewport's present one. Found on 8 November 2026, when a cabinet grab
  came out small in a corner: the Debug tab's "The context's projection
  is not a perspective" on every frame after the first grab was the clue.
- A restore at start-up that goes through the same handlers as a user's
  choice also runs their side effects: `RestoreCameraView` through the
  fixed views' handlers reset the saved shift and distance until a
  `FRestoringView` flag stopped it (KeepRestore1).
- FMX's `TForm` has no `OnDragOver` or `OnDragDrop` events. To take drops
  on the form, override its public virtual `DragOver` and `DragDrop`.
  After one compile error, Delphi can report a spurious "There is no
  overloaded version of ... that can be called with these arguments"
  (E2250) for every anonymous method later in the unit. Fix the first error
  before looking at those.
- **`Default(...)` does not compile in `Sprite3dMain.pas`**: Gorilla.DefTypes
  has an enumeration value named `Default`, which hides the intrinsic
  (E2066, E2029, "Incompatible types: ... and 'TGorillaOAuthMode'", then
  spurious E2250s). Set the fields, or use a helper such as
  `EmptySpriteScan` from a unit that does not use Gorilla (ScanSprites4).
- Run Linux builds from a terminal when testing: GTK writes its warnings
  there, and the IDE does not show them.
