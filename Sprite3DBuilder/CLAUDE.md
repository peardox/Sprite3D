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

Last updated: 13 November 2026, 16:30.

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
  `Sprite3DModelContent`, `Sprite3DGroupIcons`, `Sprite3DLevelPlacement`
  (placing pieces) and `Sprite3DLicences` (its own list). They must not use anything in `Sprite3DBuilder/ui`, and must
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

- **Read the documentation for the Gorilla3D version installed, 1.5,
  before designing anything on Gorilla**:
  https://docs.gorilla3d.de/version/v1.5/page/Core/Models.md (models,
  instancing, cloning, static meshes, bounding boxes) and the pages beside
  it. Older versions' pages (docs.gorilla3d.de/1.0.0 to 1.2.0) are a last
  resort. The area fill took three wrong rounds (a shared definition that
  crashed on closing, a load per piece at 171 ms each, an assets package
  not applied) that the v1.5 instancing section would have skipped (owner,
  12 November 2026, 20:08).
- **GPU instancing (v1.5)**: `Model.AddInstanceItem(Name)` returns a
  `TGorillaMeshInstance`; add instances to the model, not a sub-mesh. The
  model itself is always drawn, as instance #0, and hiding it hides them
  all (visibility, material and pose are shared). An instance's transform
  is absolute, in the viewport's coordinates, replacing the model's.
  `RotationAngle` on an instance **adds** to its turn (an internal
  quaternion): set a whole transform with `SetTransform(Matrix)`, or
  `ResetRotationAngle` first. `FrustumCullingCheck` False on the model, or
  every instance vanishes when it is out of view. `BeginInstancesEditing`/
  `EndInstancesEditing` on the model round many changes; `DeleteInstance`
  (collection index) or freeing the item removes one; the `Instances`
  collection does not hold the model itself. Picking and bounding boxes
  are not documented to know of instances: Builder picks pieces itself.
- **`TPath` in `Sprite3DBuilderMain` is `System.IOUtils.TPath`** (the file
  path record), as `System.IOUtils` is in the implementation's `uses`,
  after `FMX.Objects`: write the shape as `FMX.Objects.TPath` (owner, 12
  November 2026, 19:01: E2003 on `Create`, `Parent` and the rest).
- **`Default(...)` does not compile in a unit that uses `Gorilla.DefTypes`**
  (as `Sprite3DBuilderMain` does): its unscoped enumeration value
  `Default` hides the intrinsic (E2066, then E2010 against
  `TGorillaOAuthMode`; owner, 12 November 2026, 18:23). Set each field
  instead, or build the value in a unit without it.
- **Known and harmless: opening the Library writes `cannot create texture
  by TContextOpenGLWindows (Error = 1282)`** to the IDE's event log (Debug
  Output), once, with nothing drawn wrong (owner, 12 November 2026,
  12:34). It was there before the move into the Sprite3D repository too:
  the build from Sprite3DBuilder's own repository at `f6de00d` gives the
  same line (owner, 12:41). It comes as the Library's own
  `TGorillaViewport`, a second OpenGL view beside the main form's, is set
  up in `TAssetsForm.FormCreate`, most likely a texture made before that
  view's OpenGL context is ready and made again after; 1282 is OpenGL's
  general "invalid operation". Not the 24-bit PNG case of 11 November,
  which had the same text but failed a model's textures. Leave it unless
  something is seen to go wrong with it.
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
  loader's parse tree. **Nor any `LoadNewModelFrom...` class function**:
  `LoadNewModelFromDef` gave every model made from one definition that
  same definition, which each freed as it was destroyed, the second
  faulting in `TGorillaModel.Destroy` (`_AsClass` to `TModelDef`; owner,
  12 November 2026, 19:20-19:29); the viewport sends its free notification before it
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

### Where things stand (13 November 2026, 00:30): read this first

The session of 12-13 November 2026 built level editing on top of the
Library. Its dated entries follow, newest first; this is their summary.

**Zips.** The last is `2026-11-13-1630-gorilla-variants.zip` (Sprite3D's material variants, phase 1; see the root `CLAUDE.md`). Their names ran
ahead of the clock during the session (this one was made at about 00:10):
carry on from the last name rather than the clock, so they stay in order.
The owner applies them in order; each says which it follows.

**Built and working on the owner's machine:**
- Placing: click, area fill (as GPU instances; 100 tiles in about 162 ms),
  landing on what is below, the box showing where it rests.
- The palette, two columns: Move Camera, Mouse View; Place Model, Erase;
  Move Object, Rotate; Bend. The status bar. The history panel (View,
  History), Edit, Undo and Reset Level. Window, palette and history places
  kept. Random placing from several models picked in the Library.
- Rotate (Rotation Snap dialog), Move Camera, Erase, history removal.
- Level files: Save, Save As, Load (`.s3d`, JSON): "work perfectly".
- Still takes (Maya's "Take 001") left out in both programs
  (`Shared/Sprite3DModelAnimations`): Sprite3D, "all pass".
- FBX textures found by name (`Shared/Sprite3DModelTextures`): previews and
  the characters' loads textured in the owner's log.

**Delivered, not yet reported on** (each entry below has its test list):
- `2026-11-13-0005-all-instances.zip`: every piece an instance, the
  template parked below the floor, so FBX first pieces are drawn
  (`invisible.s3d`).
- `2026-11-12-2355-fbx-textures.zip`: thumbnails remade by Rescan when the
  texture rules change (`TEXTURE_RULES_VERSION`); Sprite3D's FBX textured.
- `2026-11-12-2215-outline-culling.zip` (placement box after Move Camera),
  `2210` (stacks turn with Rotate and Bend), `2205` (areas of 10,000),
  Bend itself, and the `.s3d` file association (the owner was about to try
  it).

**Offered or asked, no answer yet:**
- Move Object: carry what is stacked on a piece, as Rotate now does? (It
  leaves it to fall.)
- View, Show Bounding Box shows nothing on instances: an outline per piece,
  like the pick box?
- A random quarter turn for each floor tile placed, so one tile model does
  not look repeated?
- Pieces of mixed heights (a floor of tiles 0.138 to 0.209 high): rest an
  area at one height across pieces, or snap heights to a step?
- macOS: `.s3d` needs the bundle's document types (CFBundleDocumentTypes).
- A level file names models by full path: it loads only where they are.

**Gorilla3D, not understood, worked round:**
- An FBX model's template (instance #0) is not drawn while its instances
  are; glTF's is. So no piece is a template.
- Which of an FBX's texture names its loader uses: every one is set right.
- Its FBX loader's debug output (`Version: 7400`, `unknown property type
  "visibility inheritance"`) is its own and harmless.

**Rules learned this session** (details in the entries and the Gorilla
notes): read Gorilla's v1.5 documentation before designing on it; fixes
are general, never for one vendor or exporter; a control that draws away
from its own position must be placed and sized over what it draws; check
`tools/pasdoc_check.py` against the committed copy's own run (it reads the
tree it sits in), and leave the owner's lines as they are.

**Tools added:** `tools/fbx_inspect.py` (Python 3, nothing else): an FBX's
version, units, objects, every texture name, its takes and whether their
curves move, and that Sprite3DModelTextures' rewriting reproduces it byte
for byte. Use it on any FBX the owner sends before guessing.

### Gorilla3D's own material variants (13 November 2026, 16:30)

- Gorilla3D 1.5 reads `KHR_materials_variants` itself (owner, 16:19; root
  `CLAUDE.md`, *State (13 November 2026, 16:30)*).
  **`2026-11-13-1630-gorilla-variants.zip`**: `PieceSourceFor` sets
  `Template.MaterialVariantName := ASpec.VariantName` after
  `LoadModelFile` (logs if it stays -1); still one template per variant, as
  instances share their template's materials. `LoadEntryModel` sets
  `FModel.MaterialVariantName` from `Meta.Variants[AVariant]`. No copy of
  the model is made any more (`PrepareModelVariant` removed from the shared
  unit). The tiles' names still come from `ModelVariantNames`.

### Material variants in Builder, phase 2 (13 November 2026, 14:20)

- **`2026-11-13-1420-variants-builder.zip`**, not compiled or tested yet;
  follows `2026-11-13-1345-variant-menu.zip` (phase 1 worked in Sprite3D,
  owner 13:32). The owner (13:42) found Builder not knowing variants, as
  phase 2 had not been done; asked for it now (13:43).
- **Shared `Sprite3DModelVariants`**: `ModelVariantNames` now reads only a
  GLB's header and JSON chunk (`GltfJsonBytes`, internal), not the whole
  file (a 77 MB GLB with eight 2k textures was made in testing).
- **`Sprite3DAssetCache`, database version 8**: `meta.variants` TEXT,
  NULL until read; `TSprite3DAssetMeta.Variants`, `.VariantsRead`;
  `WriteMeta` writes NULL while not read; `LoadAssetMeta` reads it.
- **`Sprite3DLevelPlacement`**: `TSprite3DPieceSpec.VariantName` (empty:
  the base). By name, not index, so a record left zeroed (`SetLength`, a
  level from before) is the base.
- **Library** (`Sprite3DBuilderAssetsForm`): `TAssetEntry.Variant`
  (BASE_VARIANT; session only, not saved) and `.VariantText` (a label on
  the badge strip's left: "N var" or the variant chosen; `UpdateBadge`
  shows the strip for either, and sets the tile's hint with the names).
  `HashesDone` reads each entry's names once (`ModelVariantNames`) and
  saves the metadata if it has a thumbnail (one being made saves it with
  the thumbnail). `TileMouseDown` right button: `SelectEntry`, then
  `ShowVariantMenu` (a new `TPopupMenu` each time, **Parent := Self**,
  as Sprite3D's needed); `VariantItemClick` sets it, `UpdateBadge`,
  `ShowPreview` (reloads when the variant differs, `FPreviewVariant`) and
  `NotifyModelChosen`. `LoadEntryModel(AIndex, AVariant)`: thumbnails
  `BASE_VARIANT`, the preview the entry's; `PrepareModelVariant` after
  `PrepareModelTextures`. `LevelSpec` sets `VariantName`.
- **Level** (`Sprite3DBuilderMain`): `SourceKey` (key, `|variant` in
  lower case) keys `FSources`, so each variant is its own template;
  `PieceSourceFor` loads the variant's copy (by name through
  `VariantNamesOf`, cached per key in `FVariantNames`; a name the model no
  longer has is the base, logged). Level files: a model entry per key and
  variant, `variant` written when not the base, read back (absent: the
  base); format version unchanged (older Builders show the base). New
  tool **`etVariant`** (palette, beside Bend, `VARIANT_ICON`):
  `RefreshVariantMarks` puts a `TSprite3DPlacementBox` (dark green) round
  each piece with variants, up to `MAX_VARIANT_MARKS` (500), from
  `UpdatePalette`, `MarkLevelChanged` (before its early exit) and the end
  of `LoadLevelFile`; cleared by `FreeLevelPieces`. `ShowPick` points only
  at pieces with variants for it, bright green. A click:
  `ShowPieceVariantMenu` (header item, base, variants, ticked; Shift for
  every piece of the model); `SetPiecesVariant`: the variant's template,
  then for each piece not falling, its instance freed and one added to the
  new template, `Model`/`Spec.VariantName` set, `MovePiece` at its
  `Landed.Y`; `MarkLevelChanged`. **Not in the history** (Undo does not
  undo it).
- README: *Material variants*, the Variants tool, level files.
- Compiler hints (owner, 14:14), `2026-11-13-1425-variants-hints.zip`:
  `Sprite3DModelVariants` uses `System.Generics.Collections` (H2443, so
  `TJSONArray.GetValue` inlines); `PieceSourceFor`'s `Kind := mkUnknown`
  removed (H2077: set on load, unused on failure); the unused private
  `PieceIndexOf` removed (H2219; unused before this work too).
- **To test** (Windows): rescan the collection with `spider_variants.glb`:
  its tile shows "1 var"; right-click: Base, sp02; choose sp02: the
  preview shows it and the tile says sp02; place one: it is sp02; set the
  tile back to Base, place another. Variants tool: both outlined; click one,
  choose Base/sp02: it changes in place; Shift-click: every spider. Save
  the level, load it: each as it was. A level saved before loads as before.

### Material variants: phase 2 is Builder's (13 November 2026, 13:20)

- The owner (12:48): models with material variants (glTF's
  `KHR_materials_variants`, added by Sprite3D's glTF, Add Variants); the
  Library's tile gets an extra label for a model with variants, and
  right-clicking it chooses the variant to use; placed pieces can be given
  another variant through a new tool icon that highlights every piece with
  variants, a click in that mode popping up the variant menu.
- **Phase 1 is Sprite3D's** (root `CLAUDE.md`, *State (13 November 2026,
  13:20)*), with a **new shared unit, `Shared/Sprite3DModelVariants.pas`**:
  `ModelVariantNames` and `PrepareModelVariant(LoadFile, CacheFolder, Key,
  Variant)`, the copy to load after `PrepareModelTextures`. Not in
  Builder's `.dpr` yet; nothing here uses it yet.
- 13:35 (`2026-11-13-1335-variants-formats.zip`): **shared
  `Sprite3DModelTextures` gains `ReadableImageFile` and `ImageForLoader`**
  (public wrappers of `IsImageFile` and `MakePng`), for Sprite3D's Add
  Variants; nothing Builder calls changed.
- Phase 2, to do: the Library reads `ModelVariantNames` (into the
  metadata, as the counts are), a tile label, a right-click menu
  choosing the variant pieces are placed as; the level file records each
  piece's variant; a piece's template is per model **and variant** (the
  instanced templates share one material); the variant tool. The level
  model and its history must carry the variant.

### The cache tidied after every scan too (13 November 2026, 10:40)

- The owner (10:28): rescans, used a lot to fix thumbnails, left the old
  ones (a model whose files changed gets a new key; its old thumbnail and
  metadata stayed). Asked (10:31) to tidy as each rescan finishes.
  **`2026-11-13-1040-tidy-after-scan.zip`**, follows
  `2026-11-13-1035-tidy-cache.zip`: `HashesDone`, when its results are from
  a scan (`FromScan`, read before `FScanning` is cleared), calls
  `StartPurge` after `SavePalette` has saved the models found. The
  thumbnails the collection then makes are written after the sweep starts
  and are its models', so they stay. A bulk rescan sweeps once per
  collection (a walk of the cache folder each; overlapping calls chain
  through `FPurgeAgain`). README: the tidy paragraph.
  - **To test**: change a texture of a `.gltf` in a collection (so its key
    changes), Rescan: the Debug tab's "N thumbnails in the cache: N in use,
    1 deleted" and "cache tidied: ... the metadata of 1 models"; the new
    thumbnail made and kept. A Rescan with nothing changed: 0 deleted.

### The cache tidied, the database compacted (13 November 2026, 10:35)

- The owner (10:24): after deleting every artist, 2,500 thumbnails and a
  7.5 MB `library.db` were left. Two causes: SQLite never shrinks its
  file (deleted records' pages are kept for reuse; VACUUM rewrites it), and
  only the deleted collections' thumbnails went, never one orphaned
  otherwise (a model whose files changed, so a new key; one a rescan no
  longer finds; an earlier library's).
  **`2026-11-13-1035-tidy-cache.zip`**, follows
  `2026-11-13-1015-why-rescan-log.zip` (which the owner may skip; this zip
  carries the whole form, its lines included).
  - `Sprite3DAssetCache`: `DeletedAssetKeys` and `DELETED_KEYS_SQL` replaced
    by `UsedAssetKeys` (`USED_KEYS_SQL`: keys in the models or groups of
    every unmarked collection there is). `PurgeDeletedAssets` deletes `meta`
    NOT IN those, the marked collections, then every row of the five
    collection tables (verdicts included) whose collection is not there,
    then the marked artists. New `AssetThumbnailFiles` (PNGs named for a
    key in their key folder or at the top, as `ClearCacheFiles` takes them;
    file work only, any thread) and `CompactAssetDatabase` (`PRAGMA
    freelist_count`; if any, `VACUUM`, then `PRAGMA
    wal_checkpoint(TRUNCATE)`; sizes of the file and `-wal` before and
    after).
  - Form: `StartPurge` is now the sweep: used keys read on the main thread,
    then a `TTask` deletes every key PNG not used **and written before it
    started** (a thumbnail being made meanwhile stays; key folders kept).
    `PurgeFilesDone` always purges the records (a file that failed is
    tried at the next sweep), then compacts. `LoadLibrary` runs the sweep
    on every open of the Library (and says so if a delete was unfinished).
    Debug tab: "tidying the cache: the collections have N models", "N
    thumbnails in the cache: N in use, N deleted", "cache tidied: ...",
    "database compacted from X to Y".
  - Checked in SQLite (Python) on the schema as `CreateSchema` makes it:
    used keys kept (either case, models or groups), the rest's metadata
    deleted, stray rows of a missing collection deleted; a 10 MB WAL
    database emptied compacts to 8 KB.
  - A collection listed but not yet scanned (an import still queued) has no
    models saved, so a sweep then takes its old thumbnails, to be made
    again: accepted.
  - **To test**: open the Library with no artists: the Debug tab's counts,
    every thumbnail deleted, the database compacted to a few KB. Then add a
    collection; close and open the Library: "N in use, 0 deleted" and its
    thumbnails from the cache.

### Collections rescanned on every switch? (13 November 2026, 10:15)

- The owner (10:06): the Library appears to rescan every time the
  collection is switched. Not found by reading: `OpenCollection` reads the
  folders only for a rescan or remake asked for, a collection never
  scanned to the end, or one with no models saved; `HashesDone` remakes a
  thumbnail with no metadata, made before a remake, made by older texture
  rules (for `.gltf`/`.fbx`), not `THUMBNAIL_SIZE` square, or with no
  PNG. The metadata's `textures` is saved with each thumbnail and read
  back. **`2026-11-13-1015-why-rescan-log.zip`** (follows
  `2026-11-13-1000-suspect-order.zip`) logs which: "reading its folders:
  <why>" or "N models as last scanned; folders not read", and, when any are
  to make, "to make because: N never made, N made before the remake, N by
  older texture rules, N not 128 x 128 (such as W x H), N with no image
  file". Asked the owner for those lines from one switch. A suspect, if it
  is the size: a grab of another size than 128 square (a scaled display)
  saved as such would be made again on every open.

### Scan for Suspect Models (13 November 2026, 09:50)

- **`2026-11-13-0950-suspect-models.zip`**, not yet tested; follows
  `2026-11-13-0930-delete-with-thumbnails.zip` (also not yet reported on).
  The owner (09:37-09:40): a collection menu item that finds the median
  model size and the outliers, a factor X (default 5) smaller or larger
  than the median ("5 = x smaller or larger"); the median shown in the
  Preview; a slider for X; player controls as Sprite3D's to step through
  them; Tick and Cross for good and bad, not on the median, **recorded in
  the database, Tick (good) the default**. Auto-scaling a collection was
  floated ("We MAY offer"): not built; see below.
  - New `ui/Sprite3DBuilderSuspectForm.pas`, made in code as the Rotation
    Snap dialog (in the `.dpr` and `.dproj`): `TSuspectModelsForm.Execute`
    takes `TSuspectModel` records (the caller's index, name, size, bad),
    `OnShowModel` and `OnVerdict`, and gives back a summary for the log.
    Size: the largest of the box's three sides (`FMeasures`), from the
    metadata, nothing loaded. Median: the smaller middle model of the sort
    (a real model). Outliers: under median/X or over median*X (`Distance`, a factor
    of 1 or more either way, for the readout; size 0 is infinite).
    A median of no size gives no outliers. Slider 1.5 to 20, step 0.5.
    **Order** (owner, 09:51, `2026-11-13-1000-suspect-order.zip`): by size,
    smallest first, largest last (was most extreme first); ties in entry
    order. The owner noted that size 0 (a flat or empty box) is handled:
    it is an outlier, the smallest, labelled "no size".
    Player: Sprite3D's icon paths (copied, as Builder cannot use Sprite3D's
    `Sprite3DHelpers`) and its icon-button styling; Play steps every 1.5 s,
    stopping at the last; any button stops it. Tick and Cross
    (`StaysPressed`, Tick down for good) call `OnVerdict`, then step on to
    the next outlier. Placed over the right of the Library, its top 72 down,
    clear of the preview.
  - `Sprite3DAssetCache`, **database version 7**: table `model_verdicts`
    (`collection_id`, `model_key`, `verdict` 'good' or 'bad', `checked`
    ISO 8601; key the pair); `TSprite3DModelVerdict`, `LoadModelVerdicts`,
    `SaveModelVerdict`. Deleted with the collection (`DeleteAssetCollection`
    and `PurgeDeletedAssets`), not by `SaveAssetCollection`. A model whose
    files change gets a new key and so no verdict.
  - Form: `ScanSuspectItem` (`.fmx`, after Regroup), `ScanSuspectItemClick`
    (entries with a thumbnail, verdicts from the database),
    `SuspectShow` (`ShowGroup` if the model is in another group,
    `SelectEntry`, the tile scrolled into sight), `SuspectVerdict` (saves,
    logs "marked good/bad"). Selecting also hands the model to the level's
    Place Model tool, as any selection does. While thumbnails are being
    made the preview shows nothing (`ShowPreview` waits for `Making`).
  - Verdicts are only recorded and shown in the dialog so far; nothing else
    reads them (a mark on the tile, or leaving bad models out of placing,
    would be next, if wanted).
  - **Auto-scale, not built**: a collection-wide scale factor (kept with the
    collection, applied as models are loaded and placed, and to their
    thumbnails and sizes) is the natural next step; the dialog's median is
    the figure to scale from. Offered to the owner.
  - **To test** (Windows): on a collection with thumbnails, Scan for Suspect
    Models: the median's line and its preview; the slider changes the
    count and the factor line; First/Next/Previous/Last/Play step through
    the outliers, each in the preview with its group opened; Cross on one,
    close, open again: it is still bad (and the Debug tab's "marked bad");
    Tick back: good. A collection whose thumbnails are not all made: the
    note gives how many are left out.

### Deleting collections and artists with their thumbnails (13 November 2026, 09:30)

- **`2026-11-13-0930-delete-with-thumbnails.zip`**, not yet tested; follows
  `2026-11-13-0850-collection-menu-hang.zip`, which worked (owner, 09:06).
  The owner: Delete Collection should delete its thumbnails, mark the
  records for deletion, then on completion delete them; model files left
  alone. The same for Delete Artist, with their collections. Afterwards the
  nearest valid artist or collection is shown.
  - `Sprite3DAssetCache`, **database version 6**: `deleting` (INTEGER, 0)
    on `collections` and `artists`. `MarkAssetCollectionDeleted`,
    `MarkAssetArtistDeleted` (the artist and every collection under them,
    one transaction), `AssetDeletionsPending`, `DeletedAssetKeys`
    (replaced at 10:35 by `UsedAssetKeys`; see *The cache tidied*), `PurgeDeletedAssets`
    (one transaction: `meta` of those keys, then the four collection tables,
    the marked collections and artists). `LoadAssetLibrary` and
    `LoadAssetCollection` leave marked rows out; `SaveAssetLibrary`'s
    rewrite of `artists` spares marked ones. `DeleteAssetCollection` is
    kept, unused by the form now. The SQL was checked in SQLite (Python)
    on the schema as `CreateSchema` makes it: shared keys (another
    collection's model or group, either case) kept.
  - Form: `DeleteCollectionClosed` and `DeleteArtistClosed` mark first (and
    stop, logging, if that fails), take the entries out of `FLibrary`, show
    the nearest (collection: the artist's next in list order, else the one
    before, else none with the artist kept; artist: the next, else the one
    before, with `ArtistCollection`), then `StartPurge`. `StartPurge`
    deletes the PNGs of `DeletedAssetKeys` in a `TTask` (key folders kept,
    as a thumbnail being made may be going into one), `PurgeFilesDone`
    purges the records only if none failed; a delete during a purge sets
    `FPurgeAgain`, and the purge starts over rather than taking records whose
    thumbnails are not done. `LoadLibrary` finishes an unfinished delete
    (`AssetDeletionsPending`). The dialogs' wording says thumbnails go.
  - README: *Deleting*, in the Library's section.
  - **The Library's title** (owner, 09:11): `Library (N models) - Artist /
    Collection`, N the sum of the collections' counts (`FLibrary.Collections[].Models`,
    as `ArtistText` sums an artist's; a model in two counts twice), set in
    `FillCollections`, which runs whenever a count changes. To test: the
    title's count goes up as a scan finds models, and down after a delete.
  - **To test** (Windows):
    1. A collection whose models are in no other: Delete; the Debug tab says
       "deleting the thumbnails of N models", then "delete finished: N
       thumbnails, and the records of 1 collections and N models"; the
       next collection of the artist opens (the one before, if it was the
       last).
    2. Two collections over the same folder: delete one; the other still
       shows every thumbnail, none remade, and the log's count is 0 models.
    3. An artist with several collections: Delete; the next artist (or the
       one before) is shown with a collection open; the log's counts.
    4. Delete an artist's only collection: the artist stays shown, "No
       collections for this artist yet".
    5. Stop the program from the IDE straight after a big delete; start
       it and open the Library: "a delete was left unfinished last time;
       finishing it", then "delete finished".

### Collection menu hang (13 November 2026, 08:50)

- **Worked** (owner, 09:06).
- **Library, the collection's `...` button hung the program**, which had to
  be stopped from the IDE (owner, 08:44). `2026-11-13-0850-collection-menu-hang.zip`,
  not yet tested; follows `2026-11-13-0030-handover.zip`. The artist's
  `...` menu, built the same way but with no sub-menu, was not reported.
  - `CollectionMenuButtonClick` emptied the Move to Artist sub-menu with
    `MoveCollectionItem.DeleteChildren`, the only `DeleteChildren` on a
    styled control in either program. It frees every child, and once the
    menu has been shown a menu item's children include the style objects
    FMX gave it, which it still points at: the likely cause, not
    confirmed. Now only its menu items are freed (`Items[I].Free`, last
    first).
  - Two log lines, to the Debug tab and the import log
    (`library-import.log` in the settings folder, readable after a forced
    stop): "collection menu: removing N Move to Artist item(s)" and
    "collection menu: showing, N artist(s) to move to", then "Popup
    returned".
  - If it still hangs: the last line in the import log says whether it was
    before or inside `Popup`; then the next step is Move to Artist as a
    dialog rather than a run-time sub-menu.
  - **To test** (Windows): open the collection's `...` menu several times,
    with one artist and with several; Move to Artist lists the other
    artists and moves the collection; Rename, Remake Thumbnails, Regroup
    and Delete still work.

### Handover (13 November 2026, 00:15)

The summary above comes first; the entries from here on are the history.

- **Still takes, in both programs**, `2026-11-13-0015-still-takes-shared.zip`,
  not yet tested; follows `2026-11-13-0005-all-instances.zip`. The owner
  (00:01): Sprite3D takes `SM_Prop_Neon_Sleigh_01.fbx` (FBX 7.7) for an
  8-frame animation. Parsed: one mesh, an AnimationStack "Take 001"
  (LocalStop 230930790000 ticks, 5 s) and a BaseLayer, and **no
  AnimationCurve at all**. The 2320 rule lived in Builder's
  `Sprite3DModelContent`; Sprite3D lists every animation Gorilla loads
  (`LoadModelFile`, `GetSortedAnimations`) and plays the last.
  - New `Shared/Sprite3DModelAnimations` (in both `.dpr`/`.dproj`):
    `AnimationMoves` (moved from `Sprite3DModelContent`, unchanged),
    `MovingAnimations` (count of the definitions that move, and how many
    there are), `StillAnimationsLeftOut` (a list of names without the
    still ones, matched to definitions by `Id`; a name matching none is
    kept if any definition moves, dropped if none does).
    `Sprite3DModelContent` uses `MovingAnimations`; both programs'
    `LoadModelFile` filter their names with `StillAnimationsLeftOut`.
  - Not known: whether Gorilla makes a definition for a take with no
    curves at all. If it does not (the animation manager has it, the
    definitions do not), the sleigh still plays in Sprite3D and counts in
    Builder through the manager fallback; then `TGorillaAnimation` must be
    looked at (its definition, or its stages) to tell it is empty.
  - **To test**: Sprite3D opening the sleigh: no animation, no frames;
    a PolygonDungeon character: no animation either (bind pose); an
    animated model (a KayKit character): its animations as before.
  - **Result** (owner, 00:06): "all Sprite3D pass": the sleigh, a
    PolygonDungeon character and an animated model as above. So Gorilla
    does make a definition for a take with no curves, and the open
    question above is answered: `StillAnimationsLeftOut` sees it.

- **Every piece an instance**, `2026-11-13-0005-all-instances.zip`, not
  yet tested; follows `2026-11-12-2355-fbx-textures.zip` (applied: the
  owner's rescans run on it). The owner (23:48-23:56): FBX pieces "look
  like they drop but don't, repeat the drop and they do"; glTF fine. With
  a save (`invisible.s3d`: two `SM_Env_BonePile_01`, the second on the
  first) and the log: the first piece of a model, the template itself, is
  in the level (Erase outlines it, it is saved) but not drawn; its
  instances are. Why Gorilla does not draw that FBX's model itself (its
  instance #0) while drawing its instances is not known; glTF templates
  draw.
  - So no piece is a template now: `PieceSourceFor` parks the template at
    `TEMPLATE_PARK_Y` (-100000, far below the floor, out of sight;
    `FrustumCullingCheck` stays False, so its instances are drawn),
    `PlacePiece` always adds an instance, `MovePiece` poses instances only
    (`FPoser`, `SetTransform`), `ReleasePiece` frees the instance (the
    template stays, loaded, for the next piece; no heir, no hiding).
    `TPieceSource.Taken` is gone. One drawing path for every piece of
    every format.
  - The template's `ShowBoundingBox` is no longer set (it showed only the
    template's own box, which is now out of sight); View, Show Bounding
    Box still acts on the level's models through `ApplyShowBounds`, but no
    instance shows a box: an outline per piece, like the pick box, would
    be the way, if the owner wants it.
  - Gorilla's FBX loader writes, to the debugger's output, `"Kaydara FBX
    Binary  ", Version: 7400` and `TFBXNode.GetPropertyValue() : unknown
    property type "visibility inheritance"` for every FBX 7.4 it loads
    (owner, 23:41, during a rescan of 814): its own notes, harmless, in
    the original files too; nothing of ours.
  - **To test**: load `invisible.s3d`: both bone piles drawn. Place an
    FBX and a glTF model once each: drawn at once, and fall. Erase every
    piece of a model, place it again. Rotate, Bend, Move Object, Undo,
    Save and Load, as before.

- **FBX textures, general**, `2026-11-12-2355-fbx-textures.zip`, not yet
  tested; follows `2026-11-12-2320-still-takes.zip`. The owner (23:19):
  "remember - these fixes must be generalized", and the listing of
  PolygonDungeon's `Textures` (numbered `Dungeons_Texture_01.png` to
  `_04` with `_A` to `_D` variants beside them, `FloorTiles_*`,
  `WallTiles_*`, `.tif` and `.tga` too). Nothing is Synty-specific: the
  still-take rule counts any animation whose keys never change; the FBX
  fix reads whatever any FBX names.
  - `Shared/Sprite3DModelTextures` (both programs): `ResolveTexture` has
    a last step, `PlaceNumberedMatches`: the name, a separator (`_`, `-`,
    `.`, space) and digits alone (so `Atlas_01`, never `Atlas_01_A`),
    nearest first, lowest number first, then PNG, JPEG, the rest. And
    `ADecode` (default True, for glTF's uris): FBX names are plain paths,
    not decoded (a `+` or `%` stays).
  - `PrepareFbxTextures`, from `PrepareModelTextures` for `.fbx`: reads a
    binary FBX (`ReadFbxNode`: 32-bit records below 7500, 64-bit from;
    each property's bytes kept as read; `Nested` keeps whether a node had
    a nested list) or an ASCII one (a `;` comment first; lines in
    `Texture:`/`Video:` blocks). Every Texture and Video object's names
    (`Filename`, `FileName`, `RelativeFilename`, Properties70 `Path` and
    `RelPath`); one with `Content` data is embedded, left alone. A texture
    usable as named by some name is used; otherwise `ResolveTexture` on
    each name until one is found, or the placeholder. If any name of any
    texture is not a file where the model is, a copy is written to
    `models/<key>.fbx`: every name of every texture set to the file found
    (`CopyIn`, beside the copy): its full path where the name was full
    (rooted, or with a drive's colon), its name alone where relative; the
    binary written node for node (`WriteFbxNode`, offsets and lengths
    afresh), then the null record and `WriteFbxFooter`: the 16-byte id,
    zeros to make the file's length a multiple of 16 (5 to 20 of them, as
    the FBX SDK does), the 140-byte tail (version, 120 zeros, magic).
  - Checked with a Python mirror of the Pascal reader and writer on the
    owner's four files (FBX 7.4, 7.5, 7.5, 7.7): written back unchanged
    they are byte-identical; with every name changed they read back with
    the new names, geometry unchanged; the footer rule rebuilds all four
    footers byte for byte. The search, mirrored on a copy of
    PolygonDungeon's layout and names: `FX_CubePivot` (`...Textures/
    Dungeons_Texture.psd`) gets `Textures/Dungeons_Texture_01.png` by the
    number step; `Character_Ghost_01` in `FBX/Characters` (`U:/.../
    Dungeons_Texture_01.png`) gets it by name, two folders up. The beard
    and the plate name other packs' textures: placeholder.
  - Not known: which name Gorilla's FBX loader uses; every one is right
    in the copy, so it should not matter.
  - Owner (23:26): another artist keeps textures in a folder inside the
    model's. `SearchPlaces` took the model's folder alone and reached its
    subfolders only through its parent's tree, which is never searched
    when the parent is a disk's root or a folder directly in it
    (`E:\Artist\Model\model.fbx`, textures in `Model\Textures`: not
    found). The model's folder is now searched with every folder below it
    (unless it is a disk's root), straight after the folder named, so a
    folder inside it comes before one beside it. Mirrored: both layouts
    found, the inner one first.
  - Owner (23:32): after a rescan the preview was textured but the
    thumbnails were not made again, and Sprite3D still showed no texture.
    (1) A thumbnail is kept by the model's key, a hash of its files, which
    the new rules do not change, and Rescan makes only missing ones. Now
    `Sprite3DModelTextures.TEXTURE_RULES_VERSION` (2; raise it whenever the
    finding changes) is kept with each thumbnail (`TSprite3DAssetMeta.
    Textures`, column `textures`, database version 5, 0 for older ones);
    a cached thumbnail of a model `PreparesTextures` takes (`.gltf`,
    `.fbx`), made with an older version, counts as missing, so Rescan, or
    opening the collection, makes it again. (2) Sprite3D's
    `GltfFileToRead` (now `ModelFileToRead`) called
    `PrepareModelTextures` for `.gltf` only; it now asks the unit's
    `PreparesTextures`, so a format added there reaches both programs.
  - The owner's log (23:34), on the 2350 zip: the characters' texture
    found (`Textures\Dungeons_Texture_01.png` for `U:/.../Dungeons_
    Texture_01.png`) and the copy loaded; each texture reported twice (the
    Texture and the Video object): `PrepareFbxTextures` now reports a
    texture once (`Report`). The ghost went from "Rigged and animated" to
    "Rigged, 0 animations": right, as its take's 480 curves all hold still
    (1 or 2 keys, none changing): a bind pose, not an animation (Synty's
    characters take their animations from separate packs).
  - **To test**: open or Rescan PolygonDungeon: the FBX thumbnails are
    made again, textured; KayKit's glTF ones too, once (they were made by
    version 1). Sprite3D opening a PolygonDungeon FBX: textured, and the
    Debug tab's texture lines.
  - **To test**: Remake Thumbnails on PolygonDungeon: textured props and
    characters; the Debug tab and import log say "texture ... used
    Dungeons_Texture_01.png"; a placed FBX piece textured. Sprite3D opening
    an FBX of the pack: textured too. A glTF kit (KayKit) unchanged.

- **FBX textures, and still takes counted as animations**,
  `2026-11-12-2320-still-takes.zip`, not yet tested; follows
  `2026-11-12-2215-outline-culling.zip`.
  - The owner (22:36-23:06) sent four Synty FBX files and (23:09) the
    import log of PolygonDungeon (`E:\3DModels\Synty\PolygonDungeon`:
    `FBX`, `FBX\Characters`, `Textures` holding the PNGs). Parsed
    (binary FBX 7.4-7.7, a Python reader written for it): texture paths are
    the artists' (`U:/Dropbox/SyntyStudios/.../_Working/...`, absolute,
    and relative to where each was exported, up to six folders up to the
    drive root, or absolute again); names are `.psd` or `.png`, sometimes
    of another product (`PolygonGeneric_Texture_01_A.psd`). The PNGs are
    in `..\Textures` (`..\..\Textures` from `Characters`). Only the file
    name can be used. **FBX texture fixing not built yet**: planned as
    glTF's (find by name, PNG then JPEG first, nearest first, three
    folders up; a corrected copy of the FBX in the cache, the textures
    beside it); the owner was asked for the `Textures` folder's listing,
    to know whether `Dungeons_Texture.psd` must also match
    `Dungeons_Texture_01.png` (a number after the name).
  - The import log showed 746 Animated, 49 Animation library, 17 Rigged
    and animated and 2 Static, of 814: Maya's FBX export always writes a
    take ("Take 001"), and Gorilla gives it as an animation, keys or none.
    `ModelContent` now counts only animations that move something
    (`AnimationMoves`: a key of one of its interpolators differs from that
    interpolator's first by more than 1E-5 in any number, by
    `TKeyCheck.Differ<T>` over `TMatrix3D`, `TPoint3D`, `TQuaternion3D`;
    an interpolator of another kind counts as moving), and takes the
    animation manager's count only when the definitions have no
    animations (it holds the still takes too). So props are Static again:
    tagged so, and made static when placed.
  - `Sprite3DAssetCache`: database version 4 forgets every kind with
    animations above 0 (`kind = ''`, `animations = 0`), to be counted
    again on the next load. `TAssetsForm`'s preview now saves what a model
    holds whenever the kind or the count changed, not only when none was
    known.
  - **To test**: open the PolygonDungeon collection: the tags are gone
    from the props (not known yet, then Static); Remake Thumbnails on it:
    the Debug tab's "N models: K static..." and the import log's kinds;
    the 17 characters still Rigged and animated; the 4-vertex
    `SM_Env_Tiles_Texture_*` Static, not Animation library. KayKit's
    glTF models unchanged.

- **Placement box not drawn**, `2026-11-12-2215-outline-culling.zip`,
  follows `2026-11-12-2210-stacks-turn.zip`. The owner (22:03): after a
  Reset Level, Place Model no longer shows the box. Reset does nothing to
  it; the view did: the level loaded before had moved the view's middle
  (Move Camera, -29.5, -1.32), and `FPlaceBox` sat at the level's origin
  (`Position` zero, its 1-unit default size), drawing its outline from
  there by its `Box`. Out of sight, the control is passed over by what
  culls by an object's own place and size (as `TModelSweep` in
  `Sprite3DSweep` already allows for), outline and all. Not confirmed:
  the owner was asked whether a right click (the view's middle back)
  brings it back.
  - `ShowPlacement` puts `FPlaceBox` at the middle of the area's box,
    the box relative to it; `FitOutline` sets an outline's `Width`,
    `Height` and `Depth` to reach its box's farthest side each way from
    its position (sizes are taken as centred on it). `ShowPick` fits
    `FPickBox` the same way (it sits at the piece's origin, turned).
  - Rule: **a control that draws away from its own position must be
    placed and sized to cover what it draws**, or it vanishes when its
    position is out of sight.

- **Stacks turn together**, `2026-11-12-2210-stacks-turn.zip`, not yet
  tested; follows `2026-11-12-2205-large-areas.zip`. The owner had
  `2026-11-12-2155-level-files.zip` running (21:56-21:57): Save, Reset
  Level and Load Level "work perfectly"; the Windows file dialog's own
  debug output (shlwapi, SHELL32, explorerframe HRESULTs) is noise, not
  ours. Trying the file association next. The owner (22:01): rotating
  a model in a stack should turn the ones above it too, not below.
  - `StartTurn`, once the set turned is known (Rotate: the piece; Bend:
    the run past the hinge), adds `RidersOf` each of them not already in
    it (pieces resting on them, transitively, as Move Object finds them),
    counted in `FTurnCarried`. `ApplyTurn` swings every one about the same
    hinge (Rotate: the bottom piece's middle), so a stack turns as one.
    Bend: what rests on the hinge piece alone stays; a piece resting on
    both a turned piece and one staying is carried.
  - `EndTurn`, Rotate square to the grid: the snap's shift of the bottom
    piece is given to the whole set, so the stack stays on it.
  - The logs and the Bend status count the pieces turned without those
    carried, and say how many were carried.
  - Move Object still leaves what rested on a piece behind, to fall:
    ask the owner whether it should carry its stack too, for the same
    reason.
  - **To test**: stack three foundations, Rotate the bottom one by 45 and
    90: all three turn as one, about its middle, and stay on it; Rotate
    the middle one: it and the top turn, the bottom stays. Bend a wall
    with pieces on top of the part that swings.

- **Areas of up to 10,000 pieces**, `2026-11-12-2205-large-areas.zip`,
  not yet tested; follows `2026-11-12-2155-level-files.zip`. The owner
  (21:52): why can Place not handle more than 256 tiles at once? It was
  set when every piece loaded its own model (about 170 ms each); with
  GPU instances it was only a limit. `MAX_AREA_PIECES` is 10,000 (100 by
  100), and what grew with the square of the pieces was made to grow with
  them:
  - `ShowPlacement`, on every move while dragging an area, tested every
    spot against every box placed (`LandingHeight` per spot). Now each box
    placed is tested once: `AnySpotIn` works out, from the area's first
    spot and step (`FAreaOrigin`, `FAreaStep`, set by `AreaSpots`), whether
    any spot's footprint is over it by more than a hundredth of a cell
    each way, as `LandingHeight` counts it.
  - `RemovePieces`: marks the pieces going (`Gone`), lets each go
    (`ReleasePiece`, was `RemovePieceAt`, which now picks the template's
    heir among the pieces staying), then keeps the rest in one pass and
    sets `FPieces.Count`, rather than a `Delete` each.
  - `SettlePieces(ARegion)`: only pieces over the part of the floor where
    something went (the removed pieces' footprints, or where a moved piece
    was) are looked at, the part growing by each piece that falls, so what
    rested on it falls too; Undo of an area over bare floor looks at none.
  - Lists built one item at a time (`X := X + [Y]`, a copy each time):
    the placed ids, Bend's set and Move Object's riders (a `TList` read
    from the front, not `Delete(0)`), the history's pruned ids, the ids
    read from a level file, and the pieces of a history line
    (`IndicesOf`, one pass with a dictionary, for Undo and the history's
    X).
  - **To test**: fill 100 x 100 (the cap message past it); drag the area
    over existing pieces (smooth, and it rests on the highest); Undo it;
    erase a tile under a wall in a big floor (the wall falls); save and
    load the big level.

- **Level files**, `2026-11-12-2155-level-files.zip`, not yet applied or
  tested; follows `2026-11-12-2145-random-tiles-panels-reset.zip`. The
  owner (21:41): File, Save Level and File, Load Level; JSON for now, but
  holding all that is needed to reload the level; extension `.s3d`,
  associated with the application for Open and Open With, as Sprite3D
  does for its types.
  - **Moved to `Shared/`**: `Sprite3DOpenFiles` and `Sprite3DFileAssoc`,
    from `Sprite3D/lib`, unchanged (`git mv`); Sprite3D's `.dpr` and
    `.dproj` name the new paths. The owner must delete the old copies
    (the zip cannot): see the delivery message.
  - Builder's `.dpr`: both units, and `HandOffToRunningInstance(
    'Sprite3DBuilder')` first thing, as Sprite3D's.
  - Helpers: `LEVEL_FILE_EXTENSION` (`.s3d`), `LEVEL_FILE_FORMAT`,
    `LEVEL_FILE_VERSION` (1), `IsLevelFile`, `RegisterLevelFiles` (ProgID
    `Sprite3DBuilder.Level`, MIME `application/x-sprite3dbuilder-level`,
    `Register` and `Claim`, Windows and Linux; run at start-up in a
    `TTask`, as Sprite3D's `RegisterProjectFiles`), setting `LevelFolder`.
  - The file (`SaveLevelTo`, written to `.tmp` then moved): `format`,
    `version`, `gridSize`, `viewCentre` {x, z}, `models` [{name, file,
    key, boxMin, boxMax}], `pieces` [{model, at [x, y, z] (where it
    rests), turn}], `history` [{name, placed, pieces [indices]}]. JSON
    through `JsonToText`, so Minify JSON counts. Model files are kept as
    full paths.
  - `LoadLevelFile`: checks format and version; `FreeLevelPieces`, the
    history cleared; each model loaded once (`PieceSourceFor`, which
    fixes textures as placing does); the pieces placed with
    `PlacePiece`, then set not falling, turned (`Turn`, `Turned`), posed
    (`MovePiece`), in one `EditInstances` round; the history mapped to the
    new ids; the view's centre put back (`ResetViewCentre`,
    `MoveViewCentre`). Pieces of models that cannot load are left out and
    counted. A different grid size is only logged.
  - File menu, top: Load Level... (Ctrl+O), Save Level (Ctrl+S), Save
    Level As... (Ctrl+Shift+S), a line (`BuildLevelFileItems`). TOpenDialog
    and TSaveDialog, starting in `LevelFolder`.
  - Unsaved changes: `FLevelDirty` (`MarkLevelChanged` after placing,
    removing (Erase, history X, Undo), Move Object and Rotate or Bend);
    `UpdateCaption` (every `Caption := ProjectionCaption` now calls it):
    "name* - projection". `AskToKeepLevel` (Save, Don't Save, Cancel)
    before Load Level, a file opened from outside, and closing
    (`FormCloseQuery` asks, then closes again from a queued `Close`,
    `FCloseAsked`). Reset Level makes a new, untitled level.
  - Files from the system: `FileOpenRequests.TakePending` once the panels
    are placed (the first `.s3d` among them loads), then `OnOpenFile :=
    OpenRequestedFile` (nil in `FormDestroy`).
  - Not done: macOS's bundle document types for `.s3d`.
  - **To test** (Windows): build something (areas, turns, a moved
    piece, Move Camera), Save Level, Reset Level, Load Level: the same.
    The title's *. Close with changes: asked. Double-click a `.s3d` in
    Explorer, with Sprite3DBuilder closed and running. Rename a model
    file a level uses and load it: those pieces left out, said. Sprite3D
    still builds and opens its files (the moved units).

- **Random placing from several models; panels follow the edges**,
  `2026-11-12-2145-random-tiles-panels-reset.zip`, not yet tested;
  follows `2026-11-12-2120-layout-and-places.zip`, which the owner has
  running (21:36: the history "just stays where it is" when the window is
  expanded).
  - Owner (21:35): select several icons in the Library, and placing picks
    which is used at random, for covering large areas with floor. The
    Library already picked several (Ctrl, Shift; for dragging to groups):
    `TAssetsModelChosenEvent` now gives `ASpecs` (the picked models that
    can be placed, the one clicked, `FSelected`, first) and `ALeftOut`
    (names without thumbnails); `NotifyModelChosen` fires it from
    `SelectEntry` and after a plain click on a picked tile picks it alone
    (mouse up). Main: `FBrushSet`, `FBrush` its first; `ChooseModel`
    takes the set; `BrushName` for the status bar and log. `PlaceShown`
    loads each model's template (`PieceSourceFor`, one that fails is left
    out), then for each spot `Random` picks one; it goes with its
    footprint's middle where `FBrush`'s would be and its floor at the rest
    height (`FPlaceLand + FBrush.Box.Top`). Spacing, preview and landing
    are `FBrush`'s, so same-size tiles are best. `EditInstances` rounds
    the adds for every template. History line: "Name +N". `Randomize` in
    `BuildLevel`.
  - Owner (21:36): the history panel should stay aligned when the window
    is expanded. `AspectLayoutResize` now moves each panel by the change
    in the view's size along any axis on which its middle is past the
    view's middle (`AnchorPanel`, `FViewSize`, set by `PlacePanels`), so
    the history keeps its distance from the right edge; then it is kept
    inside as before. Kept places are still from the top left.
  - Owner (21:38): Edit, Reset Level, wiping all content to a clean,
    empty grid. `FResetLevelItem`, under Undo and a line; asks first
    (`TDialogService.MessageDialog`, as Clear Library does), as it cannot
    be undone; then `FreeLevelPieces`, and the history cleared. The view
    is left as it is. `FreeLevelPieces` now frees every template from
    `FSources` (its instances with it), not only the pieces' templates: a
    template hidden when all its pieces were erased was otherwise left in
    the level, forgotten, once `FSources` was cleared.
  - **To test** Reset Level: everything goes, the history empties, and
    placing again works (each model loads again).
  - **To test**: pick 3 floor tiles (Ctrl-click), fill 10 x 10: a mix;
    the history says "Floor_Brick +2"; Undo takes them all. Widen and
    narrow the window: the history stays at the right, the palette at the
    left.

- **Layout, places, history order**,
  `2026-11-12-2120-layout-and-places.zip`, not yet applied or tested;
  follows `2026-11-12-2100-erase-history-move-undo.zip`. The owner
  (21:10): history adds to the bottom; the panel on the right; History in
  the View menu; the history's and toolbar's places kept; the main windows
  keep their places and sizes between sessions, made to fit the monitor
  they start on, on different monitors too; the Mouse View stats readout
  removed ("meaningless for this app"); a more suitable icon for Mouse
  View, as it rotates the view; the toolbar in two columns, an empty place
  left blank with no action; the camera icons at the top, Move Camera
  left, Mouse View right. "This is starting to take shape."
  - Palette: `MakeButton` takes a column; rows: Move Camera | Mouse View;
    (a wider gap); Place Model | Erase; Move Object | Rotate; Bend | none.
    `MOUSE_VIEW_ICON` (was `CAMERA_ICON`): a small camera with an arrow
    circling it.
  - Readout removed: `FMouseViewBack` and its labels,
    `PlaceMouseViewReadout`, `UpdateMouseViewReadout`, `SignedText`, the
    `MOUSE_VIEW_READOUT_WIDTH`, `_TITLE_HEIGHT`, `_ROW_HEIGHT`,
    `_VALUE_WIDTH` and `_SHOWN_ZERO` constants and their calls.
  - History: added at the end (`FHistory.Add`), the oldest dropped past
    50; Undo and its caption take the last line; `ShowHistory` scrolls to
    the bottom, queued, once the lines are laid out. Top right at first;
    `FHistoryItem`, View, History, ticked as `historyVisible`.
  - Places: `TSprite3DAppSettings` has `MainLeft`/`Top`/`Width`/`Height`/
    `Maximized`, the same for `Library`, `PaletteLeft`/`Top`,
    `HistoryLeft`/`Top` (-1 until kept) and `HistoryVisible`.
    `Sprite3DBuilderHelpers` has `PlaceFormOnScreen` (FMX desktop
    coordinates, which span every monitor; the monitor overlapped most, by
    `Screen.Displays[I].WorkareaRect`, or the primary,
    `Screen.WorkAreaRect`; sized to fit and moved inside; then maximised
    if it was) and `ReadFormPlace` (normal place; a maximised window keeps
    its kept size, centred on the monitor it is maximised on; a minimised
    one keeps what it had). Main is placed in `FormCreate` straight after
    `FSettings.Load`, the Library when it is made (`EnsureAssetsForm`).
    `KeepPlaces`, from `SaveViewState`, reads them all back. The panels
    are put back by `PlacePanels`, queued from `FormCreate` so the view has
    its size first; their places are kept only once that has run
    (`FPanelsPlaced`). Desktop only. FMX's `TDisplay` (FMX.Types) and
    `TScreen.WorkAreaRect` are from the Athens docwiki.
  - **To test** (Windows): as 2100's list, then: move and resize both
    windows, put the Library on a second monitor, close and start again;
    maximise the main window on the second monitor and restart; unplug or
    turn off a monitor a window was on and start: it comes back on the
    primary. Move the palette and history, restart. View, History off,
    restart.

- **Erase, history, Move Camera, Move Object**,
  `2026-11-12-2055-erase-history-move.zip`, not yet applied or tested;
  follows `2026-11-12-2040-rotate-and-bend.zip` and
  `2026-11-12-2045-rotation-form-fix.zip` (the owner compiled up to the
  dialog's E2003, fixed there; nothing of 2040 tested yet). The owner
  (20:45): an eraser icon, a click removes the model (instance); a
  floating history panel to remove recent additions, on the left of the
  screen; a Move Camera icon, moving the scene in X/Z; a Move Object icon,
  moving the selected object in X/Z. (20:46): Bend should respond only to
  left/right mouse movement: it already did (`FTurnStartX`, X only); the
  status bar and README now say so.
  - Palette, top to bottom: Place Model, Erase, Move Object, Rotate,
    Bend, Move Camera, Mouse View. `TLevelEditTool` adds `etErase`,
    `etMove`, `etPan`; `PickToolOn` is Erase, Move Object, Rotate or
    Bend, which outline the piece under the pointer (red for Erase).
  - Removing (`RemovePieces`, `RemovePieceAt`): an instance is freed
    (`Instance.Free`, as the v1.5 docs allow). The template is instance #0
    and cannot be hidden alone: if its model has another piece, the
    template takes that piece's place (`MovePiece`) and that piece's
    instance is freed; the model's last piece hides the template and sets
    `Taken` False, so the next piece placed reuses it, loaded
    (`PlacePiece` shows it again). Then `PruneHistory` and `SettlePieces`.
  - `SettlePieces`: lowest base first, each piece not falling lands
    (`LandingHeight`) on the boxes whose tops are at or below its base;
    one with less under it than before falls (the fall timer). Used after
    Erase, the history's remove, and Move Object.
  - Move Object (`StartMove`, `TrackMove`, `EndMove`): the piece follows
    the pointer, its middle kept at the offset it was taken at, snapped by
    `SnapPiecePosition` with its turned box (Shift: grid 0, free), resting
    at `LandingHeight` there, leaving out itself and `RidersOf` it (pieces
    resting on it, and on them, found at the press); let go, the riders
    fall (`SettlePieces`). They are not carried with it: tell the owner if
    carrying is wanted.
  - Move Camera (`TrackPan`, `MoveViewCentre`, `ResetViewCentre`):
    `FViewCentre`, the middle of the floor the view is fitted to, in level
    X and Z. `ViewVolume` is centred on it (so `FitModel` keeps it, and the
    view turns about it) and `LevelPlaneAt`'s four points are taken about
    it. Dragging keeps the floor point grabbed under the pointer, moving
    `FViewCentre` and `GorillaCamera.OrbitCenter` by the same amount (the
    level's delta taken into the viewport's coordinates through
    `FLevel.LocalToAbsolute3D`). A right click (any tool but Bend) resets
    it with the mouse view's turn and zoom, and refits. Not kept in
    settings.json.
  - History (`BuildHistory`, `AddHistory`, `PruneHistory`, `ShowHistory`,
    `HistoryRemoveClick`): a panel on the palette's dark backing, below
    it on the left; a grip with "History" (the palette's grip handlers,
    now moving `FMovingPanel`, whichever panel's grip it is; positions
    kept by `KeepPanelInView`); a `TVertScrollBox` of lines, newest first,
    "N x Name" or "K of N x Name", each with a red X that takes those
    pieces out (queued, as the button is freed by the new list).
    `THistoryEntry` keeps the ids (`TLevelPiece.Id`, from
    `FNextPieceId`); at most `HISTORY_MAX` (50). Additions only: erasing,
    moving and turning are not in it, and there is no undo of them.
  - Edit, Undo (owner, 20:51: "Add a new Menu Edit -> Undo (Undoes last
    addition to scene)"): `FEditMenu`, made in `BuildHistory` and
    inserted after `FileMenu` in its parent (MainMenu1, or on Linux the
    TMenuBar it was copied to), with `FUndoItem`, Ctrl+Z
    (`scCtrl or Ord('Z')`); `UndoItemClick` takes out the newest history
    line's pieces (`RemovePieces`, which prunes the line). `ShowHistory`
    enables it and names the line ("Undo 100 x Floor_Brick").
  - Not checked against the source: `TControl.ParentControl`,
    `TThread.ForceQueue`, `TVertScrollBox.Content.DeleteChildren`.
  - **To test** (Windows): first the 2040 list (Rotate, Bend). Erase a
    piece of an area, its first piece (the template), and the last piece
    of a model, then place that model again. Stack a wall on a tile and
    erase the tile: the wall falls. Move a tile with a wall on it: the
    wall falls when the tile is let go. History: place three areas, remove
    the middle one with its X. Move Camera: drag; turn with Mouse View;
    resize the window (the view stays moved); right-click (back).

- **Rotate and Bend**, `2026-11-12-2040-rotate-and-bend.zip`, not yet
  applied or tested; follows `2026-11-12-2030-gpu-instancing.zip` (the
  instancing result was recorded in
  `2026-11-12-2035-instancing-result-notes.zip`, whose `CLAUDE.md` this
  one replaces). The owner (20:21): placed pieces drop in their natural
  orientation; add a rotation tool, 45-degree snap, free with Shift held,
  a modal settings form for the snap (default 45); the model under the
  pointer highlighted, a click and drag turns it as Mouse View turns the
  view. And "Move by join", renamed **Bend** (20:21): lay down a wall,
  point at a piece; left mouse: it and all to its right turn about its
  joint with the one to its left; right mouse: the same reversed; to lay a
  long wall and bend it into a rectangle. The owner does not know if Bend
  will work: "worth a go".
  - `TLevelPiece` has `Turn` (degrees about the up axis through its
    origin) and `Turned` (its box turned and squared up, about its
    origin); `Box` now uses `Turned`, so landing on turned pieces uses
    their turned footprints.
  - Posing: `MovePiece` gives the template its position and
    `ResetRotationAngle` + `RotationAngle.Y`, and an instance the matrix
    of `FPoser` (a hidden `TDummy` child of `FLevel` posed the same way)
    with `SetTransform`, as the v1.5 docs say. `TurnVector` turns a vector
    about the level's up axis with `FTurnSign`, found once in `BuildLevel`
    by turning `FPoser` 90 degrees, so the sums turn the way FMX does.
  - Picking (`PieceAt`): `LevelPlaneAt` (the floor map at any height;
    `LevelFloorAt` is it at 0) gives the line of sight from the floor to
    the height of the tallest piece; each piece's own box, in its turn, is
    tested with `LineThroughBox` (new in `Sprite3DLevelPlacement`); the
    piece met highest up the line wins (the view looks down). The pointer
    must be over the floor (below the horizon). `FPickBox`, an amber
    `TSprite3DPlacementBox`, outlines it (`ShowPick`).
  - Turning (`StartTurn`, `ApplyTurn`, `EndTurn`): drag left or right,
    `TURN_DEGREES_PER_PIXEL` 0.5, rounded to `FSettings.RotateSnap`
    unless Shift is held; each piece's middle swings about `FTurnHinge`
    and its `Turn` adds the same, from where it was at the press
    (`FTurnSaved`). Rotate: the hinge is the piece's own middle; let go
    at a multiple of 90 it is snapped again (`SnapPiecePosition` with its
    turned box). Bend: pieces are joined when on the same base (within 5%
    of a cell), sharing at least half the taller's height, and their
    turned boxes touch (within 5% of a cell); the hinge piece is the
    joined piece nearest on screen on the left (left button) or right
    (right button, or Control and left); the hinge is halfway between the
    two middles; the set turned is everything joined to the piece pressed
    on without passing the hinge piece (breadth first). Heights are kept;
    nothing is dropped again; pieces resting on turned ones stay put.
  - Palette: Place Model, Rotate, Bend, Mouse View (`FEditTool`,
    `TLevelEditTool`, `ChooseEditTool`, `LogEditTool`; `PlaceToolOn` now
    also needs `etPlace`). Only Mouse View is kept in settings.json; the
    edit tool starts as Place Model. Right-click resets the view in Place
    Model and Rotate; in Bend it bends. Status bar: `TurnStatus`.
  - Snap: `TSprite3DAppSettings.RotateSnap` (`rotateSnap`, 1 to 180,
    default 45; `ROTATE_SNAP_*`). `Sprite3DBuilderRotationForm` (new, in
    the `.dpr` and `.dproj`): `TRotationSnapForm.Execute`, a modal form
    made in code (no `.fmx`): an edit box (digits, point or comma, read
    with the invariant format, kept within 1 to 180), presets 15, 22.5, 30,
    45, 90, OK, Cancel. Not a `TNumberBox`: its `ValueType` needs
    `TNumValueType`, undeclared with the units used in Delphi 13 (owner,
    20:33: E2003), and without it the box takes whole numbers only. Opened by File, Rotation Snap... (`FRotationSnapItem`,
    inserted under Settings... with the palette) or a double-click on
    Rotate or Bend.
  - Not checked against the source: FMX's `ResetRotationAngle` on
    `TControl3D`; Gorilla's `SetTransform`. Neither is new to the
    documentation, but if either does not compile, match it.
  - **To test** (Windows): Rotate a wall: amber outline on hover; drag
    turns it in 45s, Shift freely; at 90 it sits on the grid. Rotate an
    instanced piece (not the first placed) and the first: both turn the
    same way, about their middles. Bend a 6-piece wall at its third piece,
    left then right. Set the step to 90 and back.

### Handover (12 November 2026, 19:40)

The entry above follows on from this one.

- **Upright palette, status bar, quick areas**,
  `2026-11-12-1940-status-bar-instanced-pieces.zip`, not yet applied or
  tested; follows `2026-11-12-1915-palette-tpath-fix.zip`. The owner
  (19:11-19:12): the palette upright; the action in a status bar at the
  bottom, saying the model placed and what can be done (drag = area
  fill), and Mouse View with its options when the camera is chosen; the
  area fill "astonishingly slow"; "model clone?", "This is instancing";
  static models have `IsStatic`, which makes things faster.
  - Palette: the grip across the top, the two buttons under it
    (`BuildPalette`); its label is gone (`FPaletteLabel`,
    `PALETTE_LABEL_WIDTH`).
  - Status bar: `BuildStatusBar` (desktop, with the palette), a
    `TStatusBar` aligned to the bottom of the form, under the tabs, with
    `FStatusLabel`; `UpdateStatus` from `UpdatePalette`, `ShowPlacement`
    and `HidePlacement`: Mouse View's controls; Place Model with no model;
    the model, its size, click and drag; pressed, "let go: place it, drag
    on: fill an area"; an area's size and count (`FPlaceCountX`,
    `FPlaceCountZ`, kept by `AreaSpots` and `TrackPlacement`).
  - Speed: an area loaded every piece from its file. Now `TemplateFor`
    loads each model once (textures fixed, `LoadModelFile`), hidden in the
    viewport, kept in `FTemplates` by key for the session (never freed
    before the form, as the pieces are built from its definition), and
    `PlacePiece` makes each piece with
    `TGorillaModel.LoadNewModelFromDef(GorillaViewport, TModelDef(Template.Def), [])`,
    as Gorilla's documentation gives it (the signature is not checked
    against 1.5.4's source: if it does not compile, match it). A template
    whose kind (`GuessModelKind(ModelContent(...))`) is `mkStatic` has its
    mesh definitions marked `IsStatic` (`MarkMeshesStatic`, new in
    `Sprite3DModelContent`, walking `TMeshDef`s as `CountMeshes` does)
    before any piece is made: Gorilla then keeps the vertices on the GPU
    instead of FMX sending them every frame; never for skins or
    animations (Gorilla's warning). The Debug tab gives the load time and
    whether it was made static, and "placed N x name in T ms".
  - First result (owner, 19:19, a debug build): 100 floor tiles (2 meshes,
    static) placed in 3693 ms, 37 ms each, after a 164 ms first load:
    better, still slow; "landed 4156 ms after being let go" showed each
    piece's fall timed from when it was made, while nothing is drawn
    until all are made. `2026-11-12-1950-place-timing.zip`: an area's
    falls start together once all are made, and the "placed" line splits
    the time between `LoadNewModelFromDef` and putting each piece in the
    level (`FMakeTicks`, `FSetupTicks`), to find where it goes. The owner
    is trying a release build. Likely suspects: materials and textures
    made again for every piece from the definition (Gorilla's
    documentation says textures are duplicated unless the definition has
    an assets package), and FastMM5's checks in debug builds. Next, by
    what the split shows: share the template's materials, give the
    definitions a package, or Gorilla's assembler for large areas.
  - **Access violation on closing** (owner, 19:20-19:22, call stack:
    `TGorillaModel.Destroy` -> `_AsClass` -> `InheritsFrom(TModelDef)`,
    under `TDummy.Destroy` under `TGorillaViewport.Destroy`): the
    viewport frees its children newest first, so a template (added after
    `FLevel`) went first, its definition with it, and then each piece,
    freed with `FLevel`, read that definition. Fixed in
    `2026-11-12-1955-free-pieces-first.zip`: `FormDestroy` calls
    `FreeLevelPieces` (pieces newest first, then templates) before the
    form frees its children. `PlacePiece` says once a template whether
    the piece holds the template's own definition or a copy, to know
    whether one piece can be freed alone (removing pieces, to come). Rule:
    **a piece must be freed before the template it was made from.**
  - Freeing pieces first was not enough (owner, 19:29: the same fault,
    now under `FreeLevelPieces`): each piece freed the one definition.
    The owner pointed to the StereoModel lesson (SRDelphiFMX's
    `Sprite3D-SpritelyNotes1.md`): it was applied, but only
    `LoadNewModelFromFile` was named, and `LoadNewModelFromDef` is the
    same kind of class function. `2026-11-12-2005-own-load-per-piece.zip`:
    no templates and no shared definitions. `PieceSourceFor` loads a
    model once (a probe, freed at once) to fix its textures
    (`PrepareModelTextures`) and judge it static, and keeps the file to
    load and the flag in `FSources` (`TPieceSource`); `PlacePiece` makes
    each piece with `TGorillaModel.Create` and its own `LoadFromFile`
    (`LoadModelFile`), then `MarkMeshesStatic` on its own definition
    before it is drawn. `FreeLevelPieces` stays (pieces freed before the
    form's children), but order no longer matters. The "placed" line
    splits loading from putting in the level. Slower than sharing a
    definition: the release build's numbers decide what next (Gorilla's
    documented sharing is a definition held by an assets package).
  - Owner (debug build, the 20:05 zip): no fault on closing; 100 floor
    tiles in 17321 ms, 17145 of it loading, about 171 ms a piece.
    `2026-11-12-2020-assets-package.zip` (pieces loaded through a Gorilla
    assets package) was **not applied**: the owner asked Gorilla3D's
    author, who said: load the model once, then use GPU mesh instancing,
    `AddInstanceItem`, whose result has `Position`, `RotationAngle` and
    `Scale`; the template model must have `FrustumCullingCheck` False, or
    the instances disappear too. `2026-11-12-2030-gpu-instancing.zip`,
    following the 20:05 zip (the package changes taken out again):
    - `PieceSourceFor` loads the model once, the **template**, as the
      probe was loaded (textures fixed, `LoadModelFile`), but keeps it, a
      child of `FLevel`: marked static if static, `FrustumCullingCheck`
      False, kept in `FSources` (`TPieceSource.Template`, `Taken`).
    - The first piece placed is the template itself, moved into place
      (Gorilla's v1.5 docs: the mesh itself is always instance #0, so it
      is drawn, and hiding it hides every instance). Every later piece is
      `Template.AddInstanceItem('PieceN')` (`TLevelPiece.Instance`, nil
      for the template). An instance's transform is absolute, in the
      viewport's coordinates, replacing the template's, so `MovePiece`
      gives an instance `FLevel.LocalToAbsolute3D` of its position, and
      `PlacePiece` its `RotationAngle` that of `FLevel` (180 about X).
    - `BeginInstancesEditing`/`EndInstancesEditing` on the template around
      an area's adds, and on every template around each fall step.
    - `FreeLevelPieces` frees only the templates (their instances go with
      them), then clears `FSources`.
    - The Debug tab: "loaded in T ms, its later pieces drawn as GPU
      instances of it"; "placed N x name in T ms (L ms loading the model,
      A ms adding instances of it)".
    - Not checked against 1.5.4's source: `TGorillaMeshInstance` (taken
      to be in `Gorilla.Mesh`), `AddInstanceItem(String)`,
      `BeginInstancesEditing`, `EndInstancesEditing`. If they do not
      compile, match them.
    - To come: removing a piece is `DeleteInstance` (or freeing its item);
      removing the template while it has instances needs one of them made
      the template's own position first. Instances share the template's
      material, pose and visibility; a piece that must differ needs a
      model of its own (cloning).
    - **Result** (owner, 19:55, debug build): "That's more like it". It
      compiled as written. 100 x Floor_Brick placed in 162 ms, all of it
      the one load, 0 ms adding the instances, landed 115 ms after being
      let go (from 17321 ms with a load per piece). Instancing is the way
      pieces are placed from here on.
  - **To test** (Windows): the palette upright, its grip on top. The
    status bar's text as above, following the tool, the model chosen and
    the area while dragging. Fill a 10 x 10 area of a floor tile: the
    Debug tab's "placed 100 x ... in T ms" should now be well under a
    second after the first load; the template line says static for a
    floor tile. Place an animated or rigged model: not made static, and
    it still draws.

- **The palette, and placing by clicking**, `2026-11-12-1910-palette-place-model.zip`,
  not yet applied or tested; follows `2026-11-12-1845-quicker-drop.zip`.
  The owner (18:53): drag and drop won't work; instead select an icon, the
  box shows over the grid, a left click places it; a floating toolbar, the
  palette, its first tool Place Model with a suitable icon; a click puts
  the model down, a click and drag covers a larger area with repeats of
  it, the box showing the area they will take. (18:54): Mouse View goes on
  another icon, a camera.
  - **Library**: the drag out of the form (18:10) is taken out again
    (`TrackLevelDrag`, `FOverLevel`, the three level events and types);
    moving models between groups is as it was. `SelectEntry` now calls
    `OnModelChosen` (`TAssetsModelChosenEvent`) with `LevelSpec` and
    `LevelTakes` (has a thumbnail, and so a box).
  - **Main form**: `ChooseModel` keeps it as `FBrush` (not if it cannot
    be placed; the Debug tab says why). The palette (`BuildPalette`,
    desktop only, after `BuildLockCameraItem`): `FPaletteBack` on
    `ViewportLayout`, dark as the frame rate readout, at (8, 32); a grip
    (`FPaletteGrip`, `AutoCapture`) that moves it, kept in the view
    (`KeepPaletteInView`, also from `AspectLayoutResize`); `FPlaceButton`
    and `FCameraButton`, `TRectangle`s with a white `TPath` icon
    (`PLACE_MODEL_ICON`, an arrow onto a cube; `CAMERA_ICON`), the one on
    filled lighter and edged in `PLACE_BOX_COLOUR`; `FPaletteLabel`, the
    model chosen. **The two tools are Mouse View on or off**:
    `PlaceToolOn` is `not MouseViewOn`; `ChooseTool` (palette or View,
    Camera, Mouse View) ticks the menu, keeps `mouseView` and logs.
    `ApplyMouseViewTick` no longer resets the view when Mouse View goes
    off (a view turned to place in stays turned) and always leaves
    `AspectLayout.HitTest` on; the readout shows while Mouse View is on or
    the view is turned or zoomed. Right click resets and the wheel zooms
    with either tool. `AspectLayout.AutoCapture` is on, and
    `ViewMouseLeave` hides the box. With Place Model: a move shows the box
    (`TrackPlacement`: `PlaceSpotAt`, `ShowPlacement`); left down starts an
    area at `FPlaceAnchor` (`FPlaceDown`); moves grow it (`AreaSpots`: the
    footprint in whole cells per step, at most `MAX_AREA_PIECES` (256),
    the longer side cut); left up places them (`PlaceShown`, each through
    `PlacePiece`, which now reports textures and a differing box for the
    first only, returns whether it loaded, and stops the area if the first
    does not load). All of an area rest at one height, the highest any
    would land at, and `FPlaceBox` is one box round them (in the level's
    coordinates, at position zero). `FallTimerTimer` gives one line when
    all have landed. Debug tab lines start `Level:`, and one says which
    tool is on.
  - Fixed in `2026-11-12-1915-palette-tpath-fix.zip`: the icon's `TPath`
    was taken as `System.IOUtils.TPath`; now `FMX.Objects.TPath`.
  - **To test** (Windows): the palette at the top left under the frame
    rate, its grip moving it, kept in the view as the window shrinks;
    Place Model edged in cyan unless `mouseView` was on. Select a
    thumbnail: the palette names it and the Debug tab gives its size.
    Hover over the floor: the box rests there, snapped; click: the model
    drops into it; hover over it: the box rests on top. Click and drag
    over several cells: the box covers the area; let go: the copies fill
    it, at one height. Over 256: the Debug tab says it was cut. Click the
    camera: left-drag turns the view, the readout shows; click Place
    Model: the view stays turned, and placing works in it; a right click
    puts the normal view back with either tool. View, Camera, Mouse View
    follows the palette and the other way round. Moving models between
    groups in the Library works as before.

- 18:45, `2026-11-12-1845-quicker-drop.zip`: the owner (18:35): "why start
  so far above? the drop can be much faster". `PLACE_LIFT_CELLS` 1 to 0.25
  and `FALL_GRAVITY_CELLS` 20 to 40: the drop takes about a tenth of a
  second (sqrt(2 x 0.25 / 40) = 0.11 s) where it took a third.
- 18:40, `2026-11-12-1840-box-shows-resting-place.zip`: the owner (18:32:
  "Not a bad start"): the box while hovering should show where the model
  will rest, not some way above. `FPlaceBox` is now at the resting place
  (`FPlaceLand`); the piece still starts `PLACE_LIFT_CELLS` above it
  (`FPlaceAt`) and falls into the box.
- **Dragging a piece from the Library onto the level** (owner, 17:58: drag
  an icon from the Library over the builder form, shown there as the
  model's bounding box; the grid is the ground for now; let go, the model
  joins the scene and gravity makes it fall into place; grid snap the
  grid's size for now; "extremely simple ATM", to be refined as the
  design goes on). `2026-11-12-1810-drag-pieces-onto-level.zip`, not yet applied or
  tested. Follows `2026-11-12-1250-library-gl-message.zip`.
  - **The Library** (`Sprite3DBuilderAssetsForm`): the tile drag it had
    (moving models between groups) goes on outside the form, as the tile
    keeps the mouse (`AutoCapture`). `TrackLevelDrag`, from
    `TileMouseMove`, offers the pressed tile's model (`LevelSpec`: name,
    file, key, box; only one with a thumbnail, `LevelTakes`) to
    `OnLevelDragOver` with the pointer in screen coordinates, when the
    pointer is outside the form's client area; while the level says it is
    over it, the ghost is hidden and no group is marked. `TileMouseUp`
    over the level calls `OnLevelDrop` (and logs that the others picked
    were not taken); `EndDrag` calls `OnLevelDragLeave` for a drag that
    leaves or ends anywhere else. New types `TAssetsLevelDragEvent`,
    `TAssetsLevelDropEvent`, `TAssetsLevelLeaveEvent`. Fixed in
    `2026-11-12-1825-drag-pieces-compile-fix.zip`: `PlacePiece` used
    `Default(TLevelPiece)`, which `Gorilla.DefTypes` hides (see *Gorilla3D
    and FMX notes*); it sets every field instead.
  - **The main form**: `EnsureAssetsForm` sets the three events.
    `LevelFloorAt` finds the floor point under the pointer: four floor
    points `LEVEL_FRAME_CELLS` cells apart shown through
    `GorillaCamera.ProjectToView` (Spritely, which accounts for every
    projection, oblique, shift and rise included), the homography solved
    from them (`TSprite3DFloorMap`), the point found shown again and kept
    only within `FLOOR_MAP_TOLERANCE` (1.5) pixels of the pointer, which
    rules out the sky in perspective; only on the Level tab, not
    minimised. `LevelDragOver` snaps (`SnapPiecePosition`), finds where it
    lands (`LandingHeight` over `PlacedBoxes`) and shows `FPlaceBox`, a
    `TSprite3DPlacementBox` in `FLevel`, in `PLACE_BOX_COLOUR` (light
    cyan): at first `PLACE_LIFT_CELLS` (1) above that; from 18:40 where
    it rests. `LevelDrop` queues `PlacePiece`
    (`ForceQueue`, so the Library's mouse-up ends first), which loads the
    model into `FLevel` as the Library does (`PrepareModelTextures` with
    the thumbnail folder and the key, Builder's `LoadModelFile`,
    `ResetToBindPose`; not turned, as `FLevel` is), and adds a
    `TLevelPiece` to `FPieces`; `FFallTimer` (`FALL_STEP_MS`, 15) moves
    the falling ones (`FallHeight`, gravity `FALL_GRAVITY_CELLS` (20, 40
    from 18:45) cells per second per second, timed on `FClock`). Debug tab lines
    start `Level:`.
  - **`Sprite3DLevelPlacement`** (new, `lib`): `TSprite3DPieceSpec`,
    `TSprite3DFloorMap` (8 by 8 Gaussian elimination; checked in Python
    against random perspective cameras: within 1E-13), `SnapPiecePosition`
    (per axis: a piece N cells across, N = its size over the grid's,
    rounded, at least 1, has its middle at a cell's middle for N odd, on
    a grid line for N even), `LandingHeight` (the highest box overlapping
    the footprint by more than a hundredth of a cell, or 0),
    `FallHeight`, `BoxFootprint`, and `TSprite3DPlacementBox`.
  - **Shared, `Sprite3DSweep`**: the 12-edge drawing of
    `TModelBoundsOutline` moved into a new abstract base,
    `TSprite3DBoxOutline` (`GetOutline` gives the box and matrix; `Render`
    draws); `TModelBoundsOutline` is now its subclass, drawing as before
    (into Sprite3D's grabs only, while `ShowBoundingBox` is on), and
    `TSprite3DPlacementBox` is this program's (owner's rule: a base class
    shared, a subclass in each program). Sprite3D's only use,
    `ShowModelBoundsOutline`, is unchanged; noted in the root's handover.
  - **To test** (Windows): open the Library beside the level and drag a
    thumbnail (a floor tile, a wall, a small prop) over the view: the
    ghost goes as the pointer leaves the Library and the cyan box follows
    the pointer, snapped cell by cell, a cell up; back over the Library
    the ghost returns. Let go: the model appears in the box and falls,
    landing on the floor; drop another over it: it lands on top. Try the
    views and projections (Isometric, Top Down, perspective, an oblique):
    the box stays under the pointer. Let go over the sky in perspective,
    or back over the Library: nothing is placed. The Debug tab has the
    `Level:` lines. Moving models between groups works as before.
  - Not done, by design for this first step: moving, turning or removing
    pieces, saving the level, landing on shapes rather than boxes, any
    snap but the grid's.

### Handover (12 November 2026, 11:05)

Read this first; the dated entries below it are the history. **Paths in
them are from before the move: `src/` there is `Sprite3DBuilder/` now,
and the units that were in `src/lib` and `src/common` but are not in
`Sprite3DBuilder/lib` are in the repository's `Shared/`.**

- **Moved into the Sprite3D repository** (owner, 12 November 2026, 10:49),
  as `2026-11-12-1105-one-repository.zip`, applied by the owner on the
  Sprite3D repository's branch `duet` (`037a3ac`) and tested (11:45:
  "Everything worked"; the tests below all pass); the root's `CLAUDE.md` (*State (12 November 2026, 11:05)*) has the git
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
- **Tested** (passed): the group builds; the Library opens, finds `assets/` and
  the group icons, and makes thumbnails as before, the textured kits
  (Zerin, Quaternius) included; File, Licences lists Neon and Vampyre.
- 12:50: the Library's `Error = 1282` line on opening is known and
  harmless (*Gorilla3D and FMX notes*). Zip
  `2026-11-12-1250-library-gl-message.zip`.
- 12:45: **a program icon of its own** (owner, 12:29: the two programs'
  icons were the same): blocks on a tiled teal floor, drawn by
  `tools/make_builder_icon.py` into `Sprite3DBuilder_Icon.ico` and the main
  icon of `Sprite3DBuilder.res`; run it again to redraw. Zip
  `2026-11-12-1245-builder-icon.zip`, in the root's handover.
- 12:25: Sprite3D's glTF tools read a `.gltf` through the shared
  `PrepareModelTextures` too (`GltfFileToRead` in Sprite3D's helpers); no
  shared unit changed, so nothing here changes.
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
