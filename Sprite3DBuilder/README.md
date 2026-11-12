# Sprite3DBuilder

Sprite3DBuilder is a Delphi FireMonkey application that will become a level builder for 3D model kits, such as KayKit's dungeon pack. It is built on [Gorilla3D](https://www.gorilla3d.de/) and grew out of [Sprite3D](https://github.com/peardox/Sprite3D): it keeps Sprite3D's view, camera, model loading and settings, and leaves out everything Sprite3D has for making sprites (grabs, icons, exports, the Results tab, backgrounds, projects and the debug tools).

It starts with an empty level: a floor grid at the kit's spacing, ready to build on. File, Library... holds your collections of models, each shown as thumbnails in groups; dragging them onto the level comes next.

Sprite3DBuilder lives in the [Sprite3D](https://github.com/peardox/Sprite3D) repository, in its `Sprite3DBuilder/` folder (from 12 November 2026; it had a repository of its own before). Paths in this file are from that repository's root.

The code is split as Sprite3D's is: everything in `Sprite3DBuilder/lib` is independent of the application, and `Sprite3DBuilder/ui` holds the forms and the application's own rules. The units both programs use (the grid, swept volumes, off-screen grabs, backgrounds, resampling, settings storage, styles, title bars, the folder dialog, the frame sources, the texture fixes, and the small helpers `OSPaths`, `JsonText`, `GpuPreference` and `DisplayData`) are in the repository's `Shared/` folder, and both programs build them from there, so a fix made once is in both.

## Requirements

- RAD Studio (Delphi) with FireMonkey.
- [Gorilla3D](https://www.gorilla3d.de/) 1.5.4 or later, installed in the IDE.
- Spritely, the camera components in the repository's `Spritely/` folder: its runtime package built for each platform you compile for, and its design package installed in the IDE. Sprite3DBuilder uses its orbital camera, `TSpritelyOrbitalCamera`, and its projections, `TSpritelyProjection`. Build them from `Sprite3DGroup.groupproj` (see the repository's README); Sprite3DBuilder needs no search path for them, as the package puts its compiled units in Delphi's Dcp folder.
- [Neon](https://github.com/paolo-rossi/delphi-neon), the JSON serialisation library, [FastMM5](https://github.com/pleriche/FastMM5), and the [Vampyre Imaging Library](https://github.com/galfar/imaginglib), which reads textures in formats the model loader does not, all as the repository's Git submodules (`delphi-neon`, `FastMM5`, `imaginglib`), shared with Sprite3D. The project's search path holds Vampyre's `Source`, `Source\Libs`, `Extensions` and `Extensions\Libs`, and it defines `DONT_LINK_JPEG2000`, as Vampyre's JPEG 2000 support links C objects built for only some platforms, and `DONT_LINK_WEBP`, leaving out WebP, which model kits rarely use, and its decoder's compiler hints.

Target platforms: Windows (64-bit and ARM64EC), macOS (Intel and Apple silicon), Linux 64-bit, Android (32 and 64-bit) and iOS.

## Getting started

Clone the Sprite3D repository, which holds Sprite3DBuilder, with the submodules:

```
git clone --recurse-submodules https://github.com/peardox/Sprite3D.git
```

or, in an existing clone:

```
git submodule update --init
```

1. Open `Sprite3DGroup.groupproj` in RAD Studio, and build and install Spritely first, as the repository's README says.
2. Choose a platform for **Sprite3DBuilder** in the same group and run.

A build failing with *F2613 Unit 'Spritely.OrbitalCamera' not found* has not got Spritely built for the platform it is compiling for.

## Features

- **An empty level.** The view starts with a floor grid at the spacing kept in `settings.json` (`gridSize`, 2 units by default, a floor tile of KayKit's dungeon pack), framed in the isometric view.
- **File, Library...** opens the **Library** (see *Library*). At start it opens by itself, on the collection open last, if there are any collections. Desktop only: Android and iOS have no folder dialog to add collections with.
- **File, Clear Library...** deletes the whole library, after asking: the database (`library.db`) and the `thumbnails` folder with everything in it, so every collection, its groups and every thumbnail go. The model files themselves are never touched. The Library is then empty, ready to add collections again. Desktop only, as the Library is.
- **File, Check Thumbnails** measures every thumbnail in the library, as one with nothing in it is a model that did not draw: none of its pixels visible (alpha 32 or more) is *empty*, a problem; under 1% of them is *nearly empty*, to look into, as a thin model can be that small; a model with no thumbnail is *missing*. The Debug tab gets the counts; `library-thumbnail-check.log` in the settings folder lists every one that is not good, worst first, with its share visible, its highest alpha, its artist and collection, and its file. Each check writes it afresh. Desktop only, as the Library is.
- **View, Camera.** Variable (a dialog with dials for the angles, distance, shift and rise), fixed views (Isometric, Pixel 2:1, 1/4 View, 3/4 View, Sqrt(2), Golden Ratio, Head On, Top Down, Side View), Lock Camera, and Mouse View (left-drag turns, the wheel zooms, a right click puts the normal view back).
- **View, Lights.** The camera's headlight and a second light on the camera, each on or off.
- **View, Projection.** Perspective, orthographic, and the oblique cavalier, cabinet, military and plan oblique projections, drawn by Spritely.
- **View, Show bounding box** will box each piece placed.
- **Debug tab**, always there: what was chosen, what went wrong and what changed.
- **File, Settings...**: theme, the view's frame rate, minified JSON and, on Windows, the graphics processor.
- **File, Licences...**: the third-party licences, from the program's own resources.

On Android and iOS the menu is a drawer opened from a button at the top; on Linux it is an FMX menu bar, as GTK's native one showed only first letters.

## Library

The Library holds artists, and under each artist their collections: sets of models, each from one or more folders (not their sub-folders), arranged in groups, such as *Kaykit Dungeon*. The top bar chooses the artist shown, each listed with how many collections they have and how many models in them all (a collection is listed with its model count, or *not imported yet*); **...** beside it renames the artist, rescans every collection of theirs (**Rescan All Collections**, see below) or deletes them (with their collections, from the library only), and **Add Artist...** adds one. A collection with no artist, such as those of before artists, goes under *Unassigned*; a collection's **...** menu has **Move to Artist** to put it under another.

A new user has none, so the first thing to do is **Add Artist...** then **Add New Asset Collection...**, at the top right of the second bar, which adds a collection to the artist shown: choose its folder, usually the root of the pack, starting where the last was chosen (or the nearest folder above it still there; kept when the library is cleared), then give it a name. The folder and every folder below it are searched for models. Packs often hold the same models in several formats, each in its own folder (KayKit's Dungeon Pack has `gltf`, `fbx`, `fbx(unity)` and `obj`): if models are found in more than one folder or format, **Choose Folders to Import** lists them, each with its format and count, and ticks those of your *preferred format* (remembered), leaving out a folder that repeats the models of one already ticked; tick what you want; **All** ticks every folder, or none, as for a pack with each model in a folder of its own. A folder whose models mostly have the names of those in a bigger (or, as big, shallower) folder of the same format says so, *(same models as ...)*: a copy, such as the models of an engine project the pack comes with, which would show each of them twice. If there is only one, it is just added. A collection remembers each folder with the format taken from it.

The drop-down at the top left chooses the collection shown; **...** beside it renames it or deletes it from the library (its models, folders and thumbnails stay).

**Add Artist Collections...**, on the artist bar, makes many at once: choose a folder holding packs, such as everything one artist has made, and each folder directly inside it becomes a collection, named after it, under the artist shown. So to put a product line (KayKit, say) under its maker, **Add Artist...** the maker first, then choose the product line's folder. With no artist shown, or *Unassigned*, the folder chosen becomes the artist, named after it (or adds to the artist of that name).

The first one asks which format you want, and that becomes the default for the rest; a pack with the default format just gets it, engine copies left out. A pack with none of your formats so far asks again: *Import* takes the format you choose as your next default (so glTF first, then FBX, and so on), *Skip* passes it over and turns down the formats it offered, so a later pack with only those (FBX only, say, when you want glTF) is passed over without asking, and a format skipped is not offered again, *Only My Defaults* passes over it and every later one like it, *Stop* ends there. A pack with more than one folder of the format taken, such as one with sample projects holding models of their own (which name textures kept elsewhere), asks which to import: **Choose Folders to Import** lists just those folders, with the one holding the most models ticked; *Skip* passes over the pack. A pack with only one is imported without asking.

Packs with no models, or named as a collection you have already, are passed over. Then every new collection is imported in full, one after another, its folders read and its thumbnails made, the status line saying which of how many; this can take a while for a big folder. At the end the first is shown, with a summary of what was done. Closing the Library, or choosing another collection or artist, pauses it (see *Jobs*). (Adding folders to an existing collection will come with drag and drop.)

The Library writes what it does to `library-import.log` in the settings folder, each model's load and thumbnail grab timed, so after a hang the last lines say which model it was on; each artist import or rescan starts it afresh. Every error goes to `library-errors.log` beside it as well: a model that cannot be read or loaded, a thumbnail that could not be made or saved, a folder that is not there. Each line says which artist and collection it was in, and lines starting `---` mark where each artist import or rescan began and ended, with how many errors it met. That log is begun again only when the program starts, so it holds every error of the session, across every collection opened, imported or rescanned. The summary at the end of an artist import or rescan says how many errors there were, and the Debug tab line at the end of each collection says how many thumbnails were made and how many failed. While a thumbnail is grabbed, the Library runs the grab's remaining steps itself every 50 ms, as a viewport drawing every frame can hold up the queue they wait in; a grab that has still not come back after 4 seconds is started again, and after three tries the model is passed over, without one, and the import goes on with the next (not while the Library is minimised, when nothing is drawn). If the program is stopped while a model is loading or shown (ended from Task Manager after a hang, say), that model is passed over from then on: it is listed in `library-skipped.txt` beside the log, and taking it out of that file (or deleting the file) tries it again.

**Rescan** reads its folders again for models added, changed or removed. **Remake Thumbnails**, on the collection's **...** menu, rescans it and makes every thumbnail again, cached or not, as after a fix to how models are loaded; **Remake All Thumbnails**, on the artist's, does that to every collection of theirs, as Rescan All Collections does. **Rescan All Collections**, on the artist's **...** menu, does that to every collection of the artist shown, one after another, as an artist import does, making the thumbnails still missing (those that failed before are tried again), then shows the collection open before with a summary; it is a job, paused and resumed as an import is (see *Jobs*). A collection otherwise opens straight from what was saved, without reading its folders.

A collection shows every model as a 128 x 128 thumbnail. The groups are down the left, a button each with its icon above its name and how many models it has; clicking one, or Up and Down, chooses it, and it stays chosen until another is. Its thumbnails fill the right. A model's group, unless it has been moved, comes from its name. The name is split into words at underscores, hyphens, spaces and dots (or at capitals, for a name with none of those, such as `WallCorner`), leaving out numbers and single letters, which only tell variants apart (the *a* of `blaster-a`). Kits put the group in different places: `wall_corner` first, `small-tree` last; so each collection's models all go by their first word, or all by their last, whichever puts more of them in groups of two or more (the first, if it is as good). A plural group such as *crates* is put with *crate* when both are there, and a model left alone in its group goes to *unsorted*, for you to drag where it belongs. **Regroup Collection...**, on the collection's **...** menu, throws its groups away, after asking (with the icons chosen for them and where each model is), and groups every model again so, as for a collection grouped before this.

Groups nest, as folders do. Drag a group into the grid and it goes inside the group shown; onto a group's tile in the grid or a button on the left, inside that one; below the buttons, back to the top. The left shows the top groups; the groups inside the one shown are tiles at the start of its grid, opened with a double-click, and the bar above the grid shows where you are, with *Up* (or Backspace) to go up. A right-click on the grid adds a group inside the one shown. Group names are unique at every level, and a group's count takes in the groups inside it. *Delete Group* needs it to have no models and no groups inside.

The view at the top left says *Model Preview* while it has no model to show.

Thumbnails are picked as files are: click, Control-click to add or take one away, Shift-click for a run. Dragging a picked thumbnail onto another group moves every picked model there. Groups are in alphabetical order, case ignored, at every level. A drag held at the top or bottom edge of the groups or the grid scrolls it. A right-click on the groups opens a menu: *Add Group...*, *Rename Group...*, *Change Icon...*, and *Delete Group* for a group with no models anywhere. (Placing a model on the level, next, will take one at a time.)

A group's icon is the one chosen for it, or else an icon of the library named after the group (`wall.svg` or `wall.png`), or else its first model's thumbnail. The library is `icons/groups` beside the program or above it (the repository's), then the user's own, `icons/groups` beside `settings.json`, where an icon chosen from anywhere else is copied. Icons are PNG, or SVG drawn as filled shapes, such as those of [game-icons.net](https://game-icons.net); an SVG is drawn in one light colour. The icons in the repository are placeholders drawn by `tools/make_group_icons.py`.

A collection's groups, where each is, their icons and which models are in each are its palette. The library, every collection (its folders and formats, models and palette) and every model's metadata are kept in one SQLite database, `library.db` beside `settings.json`, through FireDAC, so everything comes back next time; collections are written in one transaction. FireDAC's SQLite driver is in every edition of RAD Studio, Community included, with SQLite linked into the program on Windows and macOS and the system's used elsewhere; SQLite is public domain. The JSON files of before the database are moved into it as they are come upon: `library.json` and `collection-<id>.json` the first time the Library opens (renamed `.moved`), each model's `.json` as it is first read (deleted). The one `palette.json` of before the library became the collection *Kaykit Dungeon* and was renamed `palette.json.moved`.

Clicking a thumbnail shows its name, group, size in its own units and file, and, once every thumbnail has been made, the model itself in the view at the top left, in the thumbnails' view, over a checker (which stands for transparency, as in Sprite3D; the drop-down at the view's top right changes it to black, grey or white, kept in `settings.json`) and with a floor grid at the level's grid spacing at the model's own floor (Y = 0), one line through its centre of rotation: a model that is raised above the floor, sunk into it, or off the grid shows it there, as it will when placed. Neither is ever in a thumbnail. Dragging across the view turns it, dragging up and down tilts it, the wheel zooms, and a right-click (or Control-click) puts the thumbnails' view back. While thumbnails are being made, the view shows each model as it is made.

**Kinds of model.** Every model is counted as it is loaded, for its thumbnail or its preview: its meshes and their vertices, its skins and their joints, and its animations, the same way for every format. From those comes a guess at its kind: *static* (meshes only: most level pieces), *animated* (meshes and animations, no skin: a prop whose parts move), *rigged* (meshes and a skin, no animations: takes its animations from a library), *rigged and animated* (with animations of its own), *animation library* (animations, with no mesh or only a token one of fewer than 64 vertices) or *empty* (nothing to draw). Its tile shows the kind's tag at its top right (ANIM, RIG, RIG+ANIM, ANIM LIB, EMPTY; none for static), and clicking it shows the kind and the counts beside the size. It is only a guess: an animation library that carries a mannequin looks rigged and animated; choosing a model's kind, and linking animation libraries to the models they fit, are to come. A model whose thumbnail was made before kinds were kept has none until its thumbnails are remade or it is previewed. File, Check Thumbnails counts animation libraries apart, as they have little to draw, and gives every model it lists its kind.

**Textures.** A model can name textures the loader cannot use: an image in a format it does not read (the loader reads PNG and JPEG), or a file that is not there, as when a kit names its working files but ships PNGs. Before each model is loaded, every image a glTF (`.gltf`) names is found, in this order: the file named, used as it is if it is PNG or JPEG; the file named, in any other format the Vampyre Imaging Library reads (a layered `.psd`, say), made a PNG; only if the file named is not there or cannot be read, a file of the same name, case ignored, nearest first: in the folder named and the model's folder, then anywhere below each of the three folders above the model's (never a disk's root or a folder directly in it, nor a folder tree of more than 100,000 files), as packs often keep textures in a folder of their own, such as `../Textures`; only then the same name with another extension, in the same places in the same order, PNG first, then JPEG, then any other format Vampyre reads, made a PNG. Then, for a name with an image's extension left in it by an exporter (`T_Enemies_BaseColor_png.png`), the name without it (`T_Enemies_BaseColor`), in the same places. A texture still not found is replaced, in the copy, by a magenta and black checker, so the model loads and its thumbnail shows where the texture is missing; the error log names it. The search stops at the first place with a file that can be used. Folder listings are made once and kept for half an hour, indexed by name, and each file's SHA-256 is worked out once (again only if it changes), so the many models of a pack that name one texture cost little more than the first. A buffer, a glTF's binary data, that is not where the model says is looked for too: the same name, nearest first in the same places; then, beside the model, one named as the model, or as the name given without the copy number a modelling program can add on export (`Decal_Line_90_001.bin` for `Decal_Line_90.bin`). Only a file of exactly the length the model gives the buffer (its `byteLength`) is taken. If any had to be found or made, the model is loaded from a copy in `thumbnails/models`, named after its key. The loader looks for the files a glTF names in the glTF's own folder (a full path in a `uri` is not taken), so every file the copy names, its buffers and textures, is copied beside it, named after the SHA-256 of its content (a PNG made, after the file it was made from): a texture many models share is there once, and is made or copied again only when it changes. A layered image file's channels after its colour ones are saved selections and masks as a rule; they are taken for transparency only when the file says its merged image has it (a negative layer count), so a PNG made from one is otherwise opaque. The kit's own files are never written. The Debug tab and the import log say what was done with each texture; one that could not be found goes to the error log. Other model formats are loaded as they are, for now.

Each model is known by a key: the SHA-256 of its file and of every file it names (for glTF, the `uri` of its buffers and images), so a copy of a model in another folder is the same model, and any change to it, its `.bin` or its textures makes a new one. Two files with the same key are shown once, and the Debug tab says so.

Thumbnails are made the first time a model is seen, one at a time, in the form's own view: loaded, turned upright, shown in the view for a moment, framed as Sprite3D frames a model, in the isometric view in orthographic projection: the volume its box sweeps turning about the up axis through its centre of rotation is fitted, with the camera's target on that axis, and grabbed off screen with a transparent background, as Sprite3D's grabs are.

They are kept in a `thumbnails` folder beside `settings.json`, as `<key>.png`, in two levels of folders named after the key's first two digits (`3/f/3fa9....png`), so no folder holds more than a share of them. Each model's metadata goes in the database: its name, group, the file it was found as, the files it names, its bounding box (in its own units, so kits made at other scales can be told apart and scaled later), and how and when the thumbnail was made. The next time, every model already in the cache is shown at once. A thumbnail of another size than 128 is made again, so changing the size remakes them.

While they are being made, the status line counts them and, after the first few, says about how long is left. Closing the form pauses them (see *Jobs*).

**Jobs.** Every piece of work the Library does is a job: an artist import, Rescan All Collections or Remake All Thumbnails, a collection's Rescan or Remake Thumbnails, or the thumbnails a collection still lacks. A job is saved as it goes, in `library-job.json` beside the library: what it is, the collection it is on, those still queued, its summary so far and its error count, so neither closing the Library nor quitting, nor a crash, loses it. Closing the Library pauses it; so does choosing another collection or artist, but for one collection's thumbnails, which are simply made when that collection is opened again. While a job is paused nothing is made: collections open with the thumbnails they have, and **Resume Scan**, beside Rescan, carries on from the collection the job was on, through every one still queued, its import log added to and its summary at the end as if it had never stopped. A remake that is resumed keeps the thumbnails it made before it was paused. **Abort Scan**, shown while a job is under way or paused, drops it: what it had still to do is done as each collection is opened. Starting another job drops one that is paused.

File, Clear Library... starts again from nothing. As each thumbnail is made, the Debug tab gets a line with the model's box and the camera's distance and orthographic height, to check a thumbnail by.

## Project layout

```
Sprite3DGroup.groupproj          the project group: Spritely, Sprite3D, Sprite3DBuilder, ProjectionTest
Sprite3DBuilder/
  Sprite3DBuilder.dpr/.dproj     the program
  ui/                            the forms, and Sprite3DBuilderHelpers: settings, the assets folder, themes
  lib/                           the asset cache, model contents, group icons, the licences
  styles/                        the theme styles and buildstyles.cmd, the pre-build step
  README.md, CLAUDE.md           this file, and the handover notes for Claude
  licences-required.md           what each third-party part asks of a release
Shared/                          the units both programs use
licences/                        third-party licences; Sprite3DBuilderLicences.rc names this program's
assets/                          model kits for the builder, such as assets/kaykit/dungeon (glTF); git ignores it
icons/groups/                    group icons for the Library (placeholders, made by the script below)
tools/pasdoc_check.py            checks the PasDoc comments and that sources are ASCII, in both programs
tools/make_group_icons.py        draws the placeholder group icons (needs Pillow)
```

The units in `Sprite3DBuilder/lib` are this program's own: `Sprite3DAssetCache`, the content keys and the cache's metadata files; `Sprite3DModelContent`; `Sprite3DGroupIcons`; and `Sprite3DLicences`, its own list of licences. From `Shared/` come, among the rest, `Sprite3DAnimFrames`, the frame sources `Sprite3DSweep` steps through (Sprite3D's `Sprite3DAnimCapture` builds its off-screen capture on them), and `Sprite3DModelTextures`, the textures a model names, found and made PNGs where the loader cannot read them (see *Textures*). Where the two programs need different things of one piece of shared code, the shared unit holds a base class and each program a subclass of its own.

## Assets

Model kits live in `assets/`, off the repository root, one folder per kit: so far `assets/kaykit/dungeon`, KayKit's Dungeon Pack as glTF. Git ignores the whole folder, so each working copy brings its own kits. Add New Asset Collection... starts there: the program looks for an `assets` folder beside itself and up to five folders above, so it finds the repository's when run from `src/Win64/Debug`.

## Settings

Settings are kept in `settings.json`, written by Neon, in a folder of Sprite3DBuilder's own, apart from Sprite3D's:

| Platform | Folder |
|---|---|
| Windows | `%APPDATA%\Sprite3DBuilder` |
| macOS | `~/Library/Application Support/Sprite3DBuilder` |
| Linux | `$XDG_CONFIG_HOME/Sprite3DBuilder`, or `~/.config/Sprite3DBuilder` |
| Android | the application's documents folder |
| iOS | `Library/Application Support/Sprite3DBuilder` |

What is kept: the View menu's ticks (bounding box, lights, projection), the camera view and the Variable view's angles, the shift, rise and distance when Variable asks for them to be kept, Mouse View's tick, the theme, the GPU choice, the view's frame rate, Minify JSON, the grid's spacing (`gridSize`, set by hand for now), the asset folder last chosen (`assetFolder`) and the Library preview's background (`previewBackground`: `checker`, `black`, `grey` or `white`).

## Themes

As Sprite3D's: the four FMX styles that come with RAD Studio (Dark, Aqua Graphite, Ruby Graphite, Golden Graphite), linked in as resources by the pre-build step `Sprite3DBuilder/styles/buildstyles.cmd`, which also builds the licences' resource.

## Licences

What each third-party part asks of anyone who builds or distributes Sprite3DBuilder is set out in [licences-required.md](licences-required.md). The licences a release must carry are text files in the repository's `licences/`, shared with Sprite3D, linked into the program by `licences/Sprite3DBuilderLicences.rc` and shown by **File, Licences...**.

## Paths

Every file the application opens or writes goes through `OSFriendlyPath` in `Shared/OSPaths.pas` first, which gives it the platform's own delimiters.

## Known issues

- Nothing can be placed yet: the level is the grid alone. Dragging a thumbnail onto it is next.
- On macOS and iOS, where Gorilla3D draws through Metal, a thumbnail is a screenshot of the Library's view, as Sprite3D's grabs are there.
- The camera is fitted to the middle of the floor, 10 cells across, whatever is placed; it will frame the level once there is one.
- The camera view and View menu ticks are saved when the main form is destroyed, which Android and iOS do not always do before ending an application.
