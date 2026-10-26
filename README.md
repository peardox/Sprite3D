# Sprite3D

Sprite3D is a Delphi FireMonkey application for viewing 3D models from fixed and free camera angles, and for rendering them to images and icons. It is built on [Gorilla3D](https://www.gorilla3d.de/) and is meant as a tool for making sprites from 3D models: load a model, choose a view such as isometric, and grab it as a transparent PNG or a Windows icon, or export its animations as sprite strips, spritesheetes, animated GIFs or MP4 videos.

The code is split so that the 3D parts can be reused: everything in `src/lib` is independent of the application, and `src/ui` holds the forms and the application's own rules.

![Sprite3D showing the sample cube in the isometric view, over the checker that stands for a transparent background](img/ScreenShot.png)

## Features

- **Orbit camera.** Three dials set azimuth, inclination and roll. The camera turns on a chain of single-axis pivots, so it passes over the poles without gimbal lock.
- **Fixed views.** View, Camera offers Isometric, Pixel 2:1, 1/4 View, 3/4 View, Sqrt(2), Golden Ratio, Head On, Top Down and Side View, or Variable to use the dials. The chosen view, and the dials' angles in Variable, are restored next session.
- **Lock Camera.** View, Camera, Lock Camera fixes the camera exactly where it is. While it is ticked nothing moves or turns it: the views and Orthographic are disabled, loading a model or resizing the window does not refit, and grabs, icons and animation exports use the view as it stands rather than fitting the model to their own size. Unticking it leaves the camera where it is until something else changes it. The lock can't be changed during an export, and starts off each session.
- **Pan.** View, Camera, Variable also has a Pan box, off by default. Ticked, two sliders move the view along the model's own X and Z axes, up to twice the model's radius either way, for the odd model that should sit off centre. The pan sits on top of the fit and never changes the angles or the distance; it applies in every view, and in grabs and icons, until it is switched off, and the window title says "(panned)" while it is in use. Centre puts it back to 0.
- **Fitting.** Each model is centred and the camera fitted to the volume it sweeps turning about its up axis. What that volume is depends on the Animations list. While two or more animations are ticked for export, playing or paused, it is the combined volume, the rest pose and every animation used joined into one, so everything a batch exports is framed at the same scale. Otherwise, with one ticked or none, it is the volume of what is on screen alone, so that fills as much of the view as it can: the selected animation's own volume, playing or paused, or the rest pose's for a static model, one without animations, or with nothing selected. The view is refitted whenever that changes: another entry is chosen, a tick is set or cleared, or an animation is paused, stepped or played. The volume fills the view on the tighter axis, and the camera orbits a point on the turning axis, so turning the azimuth dial never pushes the model out of view. Only the distance, or the orthographic size, changes; the angles are left alone. See [Volumes](volumes.md).
- **Perspective or orthographic** projection.
- **View shape.** The view has the same shape as the grabs: as large as fits left of the Animations panel at the aspect ratio of the grab size in File, Settings, usually square, and centred on a dark grey surround. What is on screen is framed just as a grab will be, and the view takes the new shape as soon as the grab size changes. When the window opens, its width is changed so that the area left of the Animations panel has that shape too, and the view fills it with no grey at the sides; the height is kept, and the window stays on the display. A maximised window is left as it is.
- **FPS readout.** The top left of the view shows, in white on a dark backing that reads over any background, the frames per second the viewport is drawing, from Gorilla3D's `FramesPerSecond`, refreshed ten times a second. It is not part of grabs or exports.
- **Bounding box, axes and grid.** The model's bounding box, its X, Y and Z axes through its centre of rotation, and a far-reaching grid on the model's floor, the lowest point of its own geometry, that fades out with distance. Each can be switched on or off in the View menu, as can "Orthographic".
- **Model Volume and Animation Volume.** Wireframes of the volume the model sweeps turning about its up axis. Show Model Volume, on by default, draws the volume of the animation playing, or of the rest pose, in aqua and yellow, and follows each animation as it plays. Show Animation Volume, off by default, draws the combined volume, the rest pose and every animation used joined into one, in fuchsia and hot pink, but only while the view is fitted to it: while two or more animations are ticked for export. It is never drawn for a model without animations. See [Volumes](volumes.md).
- **Animations Used.** Animation, Animations Used... lists the model's animations with tick boxes, and Select all / none. A column on the right gives each animation's own swept volume as a percentage of the combined volume of the rest pose and the animations ticked, updated as ticks change, so an animation that reaches much further than the rest, and would shrink every other in an export, stands out; an unticked one can show more than 100%. On OK, unticked animations leave the Animations list, so they are neither played nor exported, and leave the combined volume, and the camera is refitted; Cancel changes nothing. A new model starts with every animation used.
- **Animation menu.** Animations Used..., then Animation Settings... (described below), then Directions...; on Android and iOS, the right-click menu's Save as items are at its foot.
- **Directions.** Animation, Directions... sets the directions a sprite set shows the model from, used by exports when **Directions** is ticked under the Animations list. A compass drawn as a clock face has a marker for each direction, the "12 o'clock" in red. A drop-down sets how many there are (1, 2, or any multiple of 4 or 6 up to 64), and a dial turns the red marker to any bearing, named when it is on one of the 32 points of the compass; **Lock to directions** makes the dial step one direction at a time. The directions are numbered clockwise or anticlockwise, or in any order with **Change Order**: click the markers in the order wanted, and the first one clicked becomes the red marker. **Export...** and **Import...** save and load the whole set as a JSON file, for artwork whose directions come in an order of its own. OK keeps it in `settings.json`. See [Directions](directions.md).
- **What is saved.** Grabs and icons are saved as the view shows them: the background, and the bounding box, axes, grid, Model Volume and Animation Volume if they are showing. Animation exports show the model alone, with none of those helpers and no background.
- **Grab.** File, Grab renders the view off screen at the grab size chosen in File, Settings (256 × 256 pixels unless changed), with the model fitted to fill the image, and saves it as the next of `grab001.png`, `grab002.png` and so on. The background is transparent unless a solid colour or gradient is chosen.
- **Save As Icon.** File, Save As Icon renders the view at each size Windows 10 and 11 use (16, 20, 24, 32, 40, 48, 64 and 256 pixels, 32-bit) and saves them as one `.ico` file. The icon writer is designed so other formats, such as macOS icons, can be added.
- **Animation export.** Every animation in the model can be saved frame by frame as a sprite strip, a spritesheet, an animated GIF or an MP4 video, one at a time or in a batch. See *Animation export* below.
- **Background.** File, Background Settings... chooses what is drawn behind the model: None, Transparent (a two-grey checker standing for transparency, with an adjustable square size), Solid, or Gradient (top to bottom, left to right, or either diagonal). Colours can be picked or typed as hex. Grabs and icons follow the choice; animation exports never have a background.
- **Opening files from the system.** When the operating system opens the application with a model, for example a `.glb` or `.gltf` file double-clicked in Explorer or Finder, that model is loaded instead of the default one. This is handled on Windows, macOS, Linux, Android and iOS.
- **File, Save Project... / Load Project...** Save Project opens the Creator Credits dialog, for the creator, modeller and artist, each with a URL for their work, and the day the project started (today unless set). On OK the credits go into the `meta` section of every metadata file exported from then on, and Sprite3D asks where to save them as a **project file**, `<model>.sprite3d` beside the model unless you choose otherwise. Load Project opens one again. A project file is JSON holding the credits, the model's full path (`file`), the directions of Animation, Directions, the Animations list (as Save Animation Settings writes it) and the export choices: grab size, animation frame rate, the Metadata and Directions ticks, and the texture atlas page size and power-of-2 choice. Loading one applies all of these; if the model it names exists and isn't the one shown it is loaded, and the Animations list is applied once it is in. `.sprite3d` files are associated with Sprite3D along with the model formats (see *File associations*), so double-clicking one opens it, and one given at start-up is loaded in place of the start-up model. On Android and iOS, which have no file dialogs, the credits are kept for the session only.
- **Animation, Load / Save Animation Settings...** Save writes the whole Animations list to a JSON file, `<model>_animations.json` in the model's folder unless you choose otherwise: every entry in order, with its tick and any frame count typed in, and the entry selected. Load reads such a file back and applies it: the animations it lists that the model has become the animations used, the ticks and frame counts are set as it says, and its selected entry is selected and played. Animations the model doesn't have are left out and listed; a file that names none of the model's animations changes nothing. Desktop only, with a model loaded and nothing being exported.
- **File, Settings...** A dialog, its groups in two columns so it fits smaller displays (one scrolling column on Android and iOS), for:
  - **Open model files.** Offer Sprite3D under Open With for model files and, optionally, make it their default application. Before changing a default, the one in use is recorded; clearing the box puts it back, if that application is still installed, and otherwise just removes Sprite3D's claim. Everything is per user. On Windows a default the user picked in Windows' own dialog can only be changed there, so Settings, Default apps is opened when that happens. On macOS, Open With comes from the app bundle (see below) and only the default can be changed. Android and iOS decide these things when the app is built, so the group is disabled there.
  - **Startup action.** None (no model is loaded), Load default model, or Load last model, which falls back to the default model if the last one has gone. A file the system asks Sprite3D to open always comes first.
  - **Grab size.** The size of every off-screen grab: 8 × 8, 16 × 16, 24 × 24, 32 × 32, 64 × 64, 96 × 96, 128 × 128, 160 × 160, 192 × 192, 256 × 256, 384 × 384 or 512 × 512, or Custom, where width and height are typed separately, each from 8 to 1024 pixels. Kept as `grabWidth` and `grabHeight`. Icons keep the sizes their file format needs. Below it, the grab folder in use is shown with a Reset button, which empties it so the next grab asks for a folder again.
  - **Theme.** Default (FMX's own platform style), Dark, or one of three coloured styles, Aqua Graphite, Ruby Graphite and Golden Graphite, applied at once. Title bars follow the theme where the system allows. See *Themes* below.
  - **View frame rate.** A slider from 1 frame a second up to the display's refresh rate sets how often the view is drawn, applied on OK. The refresh rate comes from `common/DisplayData.pas`: on Windows from the monitor the window is on, on macOS from CoreGraphics for each display, and on Android from the display; where the system doesn't say (iOS, Linux, and some built-in Mac panels), the slider goes up to 60. 60 unless changed; kept as `viewFps`. The rate asked for is kept, but the view is never drawn faster than the display it is on: move the window to a slower monitor and the rate drops to that monitor's refresh rate within a tenth of a second, and moving it back brings the rate asked for back. Leaving the slider at the top on a slower monitor keeps a higher rate chosen on a faster one. Lower rates use less power and leave more of the computer to other work; exports are unaffected.
  - **Minify JSON.** Off by default. Ticked, every JSON file Sprite3D writes from then on is minified, with no indents or line breaks: exported metadata, directions files, animation settings, project files, `settings.json` itself and the caches. Unticked, they are indented two spaces for people to read. Kept as `minifyJson`.
  - **Graphics processor**, Windows only: let Windows decide, low power or high power, through `common/GpuPreference.pas`. It takes effect the next time Sprite3D starts.
- **Animation, Animation Settings...** A slider sets the frame rate animations are exported at, from 1 to 60 frames a second, 30 unless changed. Kept as `animationFps`. The same dialog has:
  - **Overscan.** Ticked, every grab, icon and animation export is drawn 2 to 8 times larger each way, 4 unless changed, and scaled back down to its size, which smooths edges and fine detail far better than the renderer's own anti-aliasing. As much of the factor as the GPU can draw in one go is drawn in one go, never more than 8192 pixels across, which keeps a grab's memory under about 1 GB. On many systems that is little more than the size of the view itself. The rest is made up with shifted drawings: the image is drawn several times at that size, each time with the view slid by a different fraction of a pixel, each drawing scaled down, and the results averaged, so 8x at 256 × 256 on a GPU that can only draw 512 pixels across is sixteen drawings at 2x. That takes longer, but any factor works anywhere. Each drawing is scaled down as soon as it has been made, so only one enlarged image exists at a time, and what is saved is always the size asked for. If an enlarged drawing comes back smaller than asked for, or completely transparent, that size is not tried again that session, the grab is made again with smaller drawings and more of them, and the Debug tab says so. Animation exports throw away a few warm-up grabs first; those are made without overscan. Ticking it first shows a warning that each frame is then rendered at the grab size times the factor each way and resampled back down, which takes far longer, so it is best kept for the final, production-ready frames: **OK** keeps the tick and **Cancel** takes it back. **Do not show this again**, between them, stops the warning appearing in future, kept in `settings.json` as `showOverscanWarning`. The tick is not kept: overscan starts off each session. The factor is kept as `overscan`.
  - **Resampling.** The filter overscanned images are scaled down with: Box (area average), the default and exact for a whole-number scale; Bilinear; Bicubic (Catmull-Rom); Bicubic (Mitchell); or Lanczos 3, the sharpest. Kept as `resampleFilter`.
  - **Padding.** A slider sets the padding, the number of empty pixels every export aims to leave round the sprite on the axis with least room, from 0, the default, to a quarter of the grab size's smaller side. Kept as `padding`. See *Two passes* under Batch export.
  - **Texture Atlas.** **Page size** is the largest a texture atlas page may be each way: 1k, 2k, 4k (the default), 8k or 16k pixels. Kept as `atlasPageSize`. **Pages need not be a power of 2**, off by default, lets each page be exactly as large as its frames need; otherwise each side is the smallest power of 2 that holds them. Kept as `atlasNonPowerOf2`. See *Texture atlas* below.
- **Settings kept between sessions** in `settings.json`: the grab folder, the icon folder, the directions file folder, the Metadata and Directions export ticks, the background, the camera view, the pan, the View menu's on/off items, the animation frame rate, the view frame rate, the directions, the overscan factor and resampling filter, the texture atlas page size and power-of-2 choice, and the choices in File, Settings. The animations used are chosen afresh for each model, and overscan starts off each session.
- **Mobile layout.** On Android and iOS the menus are reached through a hamburger button.
- **Loading a model.** A model loads behind a dialog with a progress bar, a line under it saying what is happening, and an Abort button (Escape, or the dialog's close box, does the same). The file is first read in the background, which is where a cold load spends most of its time and can be aborted at once; Gorilla3D then builds the model in one step, which can't be interrupted, so Abort pressed then takes effect as soon as that step ends; then the model's animations are measured for their volumes, a slice at a time, with the percentage shown. The measurements are kept (see *Settings* below), so a model that hasn't changed skips that stage next time. The new model is built beside the one on screen, which isn't changed until the new one is ready; while the animations are measured the new model is shown in its place, as Gorilla3D only poses a model it can draw. Abort, or a file that fails to load, brings the previous model back exactly as it was, or no model at start-up. A model asked for during a load, such as a file opened from Explorer or Finder, is loaded straight after it.
- **No model.** While no model is loaded, for example with the start-up action None or after aborting the first load, the view is covered by a panel saying so and pointing to File, Open Model.
- **Quick start-up, responsive window.** The window appears before the first model loads. The FFmpeg libraries are looked for only once that load has ended, so MP4 is offered a moment later. Overscanned grabs are matted and scaled down, and strips, spritesheets, GIFs and MP4s are composed and encoded, on a worker thread, so the window keeps responding while that is done; closing the window waits for a file being written.

Model formats: glTF (`.gltf`, `.glb`), FBX, OBJ, USD (`.usdc`), Collada (`.dae`), STL and PLY, as Gorilla3D loads them.

## Requirements

- RAD Studio (Delphi) with FireMonkey.
- [Gorilla3D](https://www.gorilla3d.de/) 1.5, installed in the IDE.
- [Neon](https://github.com/paolo-rossi/delphi-neon), the JSON serialisation library, included as a Git submodule.
- Optional, for MP4 export only: the FFmpeg 8.1 shared libraries, from the DLL pack described under *Getting started*. Without them everything else works, and MP4 is simply not offered.

Target platforms: Windows (32-bit, 64-bit and ARM64EC), macOS (Intel and Apple silicon), Linux 64-bit, Android (32 and 64-bit) and iOS.

## Getting started

Clone with the submodule:

```
git clone --recurse-submodules https://github.com/peardox/Sprite3D.git
```

or, in an existing clone:

```
git submodule update --init
```

Open `Sprite3DGroup.groupproj` (or `src/Sprite3d.dproj`) in RAD Studio, choose a platform and run. Neon's source folder is already on the project's search path.

### FFmpeg libraries (optional, for MP4 export)

MP4 export uses the FFmpeg 8.1 shared libraries. They are not in the repository; download the DLL pack from

**<https://peardox.com/Sprite3d-dlls.zip>** (about 32 MB; Windows 64-bit only for now)

and extract it in the project root, the folder holding `README.md`. It creates the `dlls` folder, with one folder per platform:

```
Sprite3D/
`-- dlls/
    |-- win32/  win64/  win64arm/      Windows 32-bit, 64-bit, ARM64EC
    |-- macx64/  macarm/               macOS Intel, Apple silicon
    |-- linux64/                       Linux
    |-- android32/  android64/         Android
    `-- iosarm64/  iossimarm64/        iOS device, simulator
```

Only `win64` is in the pack so far. The `.gitignore` keeps `.dll`, `.so` and `.dylib` files out of Git, so the extracted libraries are never committed.

Each folder holds five libraries: avutil, swresample, swscale, avcodec and avformat. Their names follow each platform's own rules:

| Platform | Names |
|---|---|
| Windows | `avutil-60.dll`, `swresample-6.dll`, `swscale-9.dll`, `avcodec-62.dll`, `avformat-62.dll` |
| macOS, iOS | `libavutil.60.dylib`, `libswresample.6.dylib`, `libswscale.9.dylib`, `libavcodec.62.dylib`, `libavformat.62.dylib` |
| Linux | `libavutil.so.60`, `libswresample.so.6`, `libswscale.so.9`, `libavcodec.so.62`, `libavformat.so.62` |
| Android | `libavutil.so`, `libswresample.so`, `libswscale.so`, `libavcodec.so`, `libavformat.so` (Android only unpacks `lib*.so` files from an APK) |

They must be FFmpeg 8.1's (avutil 60, avcodec 62, avformat 62) and include the MPEG-4 encoder, which every standard build does. Sprite3D loads them only to offer MP4: if they are missing or the wrong version, the program runs exactly as before and MP4 is not offered. The Debug tab says at start-up which happened, and from where they were loaded.

#### Deployment

The project's deployment entries copy each platform's libraries from `dlls/<platform>` to that platform's usual place for an application's own libraries, which is also the first place Sprite3D looks:

| Platform | Deployed to |
|---|---|
| Windows (32-bit, 64-bit, ARM64EC) | beside `Sprite3d.exe` |
| macOS | `Sprite3d.app/Contents/Frameworks` |
| Linux | a `lib` folder beside the executable |
| Android | the APK's `lib/armeabi-v7a` or `lib/arm64-v8a`, unpacked by the system |
| iOS | `Sprite3d.app/Frameworks` |

After that it looks beside the executable, in `dlls/<platform>` beside it, and in `dlls/<platform>` in each of the six folders above it, so a build run from `src/Win64/Debug` finds the repository's `dlls/win64` without deploying; and last wherever the system looks for shared libraries.

An ARM64EC build (Windows on ARM) can load x64 and ARM64EC libraries but not plain ARM64 ones, so `dlls/win64arm` normally holds a copy of the x64 libraries in `dlls/win64`. Run from the source tree, it also looks in `dlls/win64` after `dlls/win64arm`, so the copy is only needed for deploying.

Until a platform's folder has its libraries, deploying for that platform reports them as missing; untick them in Project, Deployment, or add the libraries. On macOS and iOS the libraries are signed with the app when it is signed, and the hardened runtime must allow libraries from other developers (`com.apple.security.cs.disable-library-validation`) unless they are signed with the app's own team ID.

The libraries are needed only at run time, never to build: Sprite3D does not link against them on any platform, so every platform builds without them.

### OpenH264 (optional, for H.264 MP4 files)

On its own, FFmpeg's MP4 export writes MPEG-4 Part 2 video, which desktop players handle but web browsers do not. With Cisco's [OpenH264](https://github.com/cisco/openh264) library as well, MP4 files are H.264 instead, which plays everywhere.

OpenH264 is never shipped with Sprite3D: Cisco pays the H.264 patent royalties only for copies of its library downloaded from Cisco. Instead, Sprite3D downloads it at run time. Which file to download is given by a list published at **`https://sprite3d.com/openh264/openh264.json`**, fetched each time Sprite3D starts:

```json
{
  "win32": "",
  "win64": "https://sprite3d.com/openh264/openh264-2.7.0-win64.dll.bz2",
  "macarm": "https://sprite3d.com/openh264/libopenh264-2.7.0-mac-arm64.dylib.bz2",
  "linux64": "https://sprite3d.com/openh264/libopenh264-2.7.0-linux64.8.so.bz2",
  "android32": "",
  ...
}
```

- **The list.** One entry per platform key (`win32`, `win64`, `win64arm`, `macx64`, `macarm`, `linux64`, `android32`, `android64`); other members, such as `_comment`, are ignored. An entry may be one address, a list of addresses, or objects with `url` (or `file`) and, if wanted, `version`. An address that is not a full `http` or `https` one is taken as relative to the list's own folder. A missing or empty entry means no H.264 on that platform: MP4 files are MPEG-4 Part 2 there.
- **The latest version.** Where a platform has more than one entry, the highest version is used: an entry's `version`, or else the version in its file name, such as `2.7.0` in `openh264-2.7.0-win64.dll.bz2`, compared number by number, so 2.10.0 is later than 2.9.0. Entries that are not valid addresses are left out and the Debug tab names them.
- **Downloaded once, then kept.** At start-up the copy downloaded before is used straight away, with no network. Once the first model is shown, the list is fetched in the background; if its latest entry is that copy, nothing more is done, and if not, the new version is downloaded and replaces the old one. A new copy is used at once if there was none, otherwise from the next start.
- **Failures are quiet.** The list or the library not found (404), any other HTTP error, no network, a timeout, a list that is not valid JSON, a damaged download or a file that is not a library for the platform: none of these interrupts anything. The copy already there stays in use, or MP4 files are MPEG-4 Part 2, it is tried again at the next start, and the Debug tab says what happened, as it does when the copy is up to date or a new one has been downloaded.
- **Formats.** `.bz2` files, as Cisco publishes them, are streamed to disk and then unpacked from there a block at a time into the library's file, so neither is held whole in memory; `.gz` and plain libraries work too. The result must be a library for the platform, a Windows DLL, a Mach-O library or an ELF shared object, before it replaces anything. Use OpenH264 2.0 or later; `https` addresses are best, as macOS, iOS and Android refuse plain `http` by default.
- **Where it goes.** An `openh264` folder in the settings folder (see *Settings*), with an `installed.json` recording the address, version and list each copy came from. Delete the folder to force a fresh download.
- **`win64arm`** is Windows on ARM (ARM64EC). It can load x64 libraries but not Cisco's plain ARM64 build, so give it the same x64 (`win64`) address as `win64`.
- **iOS** does not allow downloaded code to be loaded, so nothing is fetched there and it never has H.264.
- **Debugging.** While debugging is on, from `debug_enabled` in `settings.json` or **`--debug`** on the command line, the list is not fetched at all, nothing is downloaded, and no OpenH264 is loaded, so MP4 files are MPEG-4 Part 2. See *Debugging*.

Only a copy Sprite3D downloaded itself is ever loaded: an OpenH264 placed in `dlls` or elsewhere by hand is not used. The `openh264.json` in the project root is no longer read.

### First run

On start-up the application loads `models/uvcube.glb`, a cube with its faces labelled, from the repository's `models` folder. On Windows it looks for `models` in the current folder first, then three levels up, which is the repository root when run from `src/<platform>/<config>`. On macOS the folder is expected in the user's Library folder and on Linux in the home folder.

## Project layout

```
Sprite3D/
|-- Sprite3DGroup.groupproj
|-- README.md
|-- viewport.md, offscreen.md, volumes.md, directions.md, metadata.md  design notes
|-- delphi-neon/              Neon JSON library (submodule)
|-- docs/                     generated API help (PasDoc)
|-- models/                   sample model: uvcube.glb
|-- dlls/                     FFmpeg libraries, from the DLL pack; not in Git
|-- openh264.json             no longer read; the list is fetched from sprite3d.com
`-- src/
    |-- Sprite3d.dpr, .dproj, .res, Sprite3d_Icon.ico
    |-- ffmpeg/               DelphiFFmpeg.com FFmpeg 8.1 headers, unchanged, for reference
    |-- styles/               the themes' FMX styles, linked into the program
    |   |-- Sprite3DThemes.rc        the RCDATA resources
    |   `-- buildstyles.cmd          pre-build: copies the .style files, builds the .res
    |-- lib/                  reusable units, no application code
    |   |-- Sprite3DCamera.pas       orbit camera, fitting, view extents
    |   |-- Sprite3DAxes.pas         a model's X, Y and Z axes
    |   |-- Sprite3DGrid.pas         floor grid drawn by a GLSL shader
    |   |-- Sprite3DSweep.pas        swept volumes: measuring, wireframes, camera fit
    |   |-- Sprite3DOffscreen.pas    off-screen rendering with transparency and overscan
    |   |-- Sprite3DResample.pas     resampling filters for scaling overscanned grabs down
    |   |-- Sprite3DBackground.pas   none, checker, colour or gradient background
    |   |-- Sprite3DIconWriter.pas   icon file writers (Windows .ico)
    |   |-- Sprite3DOpenFiles.pas    files the system asks the app to open
    |   |-- Sprite3DFileAssoc.pas    Open With and default-application registration
    |   |-- Sprite3DStyles.pas       switching FMX styles at run time
    |   |-- Sprite3DTitleBar.pas     title bars coloured to match the style
    |   |-- Sprite3DStorage.pas      per-user app folder and JSON settings
    |   |-- Sprite3DAnimCapture.pas  grabs every frame of an animation, or of a turn
    |   |-- Sprite3DSpriteSheet.pas  strips, spritesheets, PNG and animated GIF writers
    |   |-- Sprite3DVideo.pas        MP4 writer, loading FFmpeg only when present
    |   |-- Sprite3DOpenH264.pas     H.264 encoder, loading the downloaded OpenH264
    |   |-- Sprite3DLibraryUpdate.pas downloads and updates a library from a JSON address
    |   |-- Sprite3DBzip2.pas        bzip2 decompression, for Cisco's .bz2 downloads
    |   `-- Sprite3DNativeLibs.pas   each platform's folders for an app's own libraries
    |-- common/               small cross-project helpers
    |   |-- OSPaths.pas              where the program and its assets are; OS-friendly paths
    |   |-- GpuPreference.pas        Windows' per-program GPU preference
    |   `-- DisplayData.pas          the displays, their modes and refresh rates, per platform
    `-- ui/                   the application
        |-- Sprite3dMain.pas, .fmx           main form
        |-- Sprite3DBackgroundForm.pas, .fmx Background Settings dialog
        |-- Sprite3DOrbitalForm.pas, .fmx    Variable camera dialog, with the pan
        |-- Sprite3DSettingsForm.pas, .fmx   Settings dialog
        |-- Sprite3DAnimationForm.pas, .fmx  Animation dialog: the export frame rate
        |-- Sprite3DAnimationsUsedForm.pas, .fmx  Animations Used dialog
        |-- Sprite3DLoadForm.pas, .fmx       model loading dialog
        |-- Sprite3DDirectionsForm.pas, .fmx  Directions dialog: the compass
        |-- Sprite3DExportForm.pas, .fmx  batch export progress dialog
        `-- Sprite3DHelpers.pas              application rules and settings
```

## Animation export

The Animations list on the right of the Model tab shows the animations used, by name. A **static** model, one with no animations, has a single entry instead, named after its file without the extension (`uvcube` for `uvcube.glb`), which shows the model as loaded. Clicking an entry plays it, and so does moving to it with the Up and Down arrow keys, Home, End or the page keys. Under the list, five buttons, with icons and their names as hints, act on the selected animation: **first frame**, **previous frame**, **play / pause**, **next frame** and **last frame**. The frames are the ones an export makes at the Animation, Animation Settings frame rate, shown exactly as the export will show them, so you can check any frame before saving. The four frame buttons pause the animation on their frame; stepping wraps round from the last frame to the first and back. After the buttons, a readout such as `3 / 24` always shows the frame showing, held or playing, and the frames an export makes; the `/` stays in the same place whatever the numbers, and it reads `- / -` when there is nothing to count, as for a static model. Play and pause share one button, whose icon and hint change to say which it does. Choosing an entry shows it paused on its first frame; once **play** has been pressed, choosing an entry plays it from the start instead, until **pause** or a frame button is pressed again. Starting an export lets a held animation play on. The Frames column beside each entry shows how many frames exporting it makes at the Animation, Animation Settings frame rate, and is updated when the rate changes; for a static model's entry it is 1, as it exports a single still frame. **Double-click a frame count to change it**: type the number of frames to export that animation in and press Enter, or leave the box; Escape leaves it as it was, and an empty box or 0 goes back to the count the frame rate gives. A count typed in replaces the automatic one for every export of that animation, and for the frame buttons and readout, whatever the frame rate, and is shown in italics. Counts typed in are kept until another model is loaded, and are saved with Animation, Save Animation Settings. Animation, Animations Used... chooses which animations are listed.

### One animation

Right-click an entry to select and play it and open a menu:

| Item | Saves | File name |
|---|---|---|
| Save as sprite strip | every frame of one direction side by side in one row, one strip per direction | `<model>_<animation>_dir<NN>_strip<frames>.png` |
| Save as Spritesheet | every frame of every direction in a square grid, left to right then top to bottom; any cells after the last frame are transparent | `<model>_<animation>.png` |
| Save as AniGif | an animated GIF that loops for ever | `<animation>.gif` |
| Save as MP4 video | a video-only MP4 file, H.264 when OpenH264 is present and MPEG-4 Part 2 otherwise; offered only when the FFmpeg libraries load | `<animation>.mp4` |

Files go to the grab folder, which is asked for the first time, as for File, Grab. A file with the same name is replaced. Characters that are not allowed in file names become underscores.

A static model's entry has no animation, so it saves a single still frame of the model as loaded instead. A sprite strip of it is named `<model>_static_strip<frames>.png`, such as `uvcube_static_strip1.png`; otherwise its entry is named after the model, so the names follow the same pattern: `uvcube_uvcube.png` for a spritesheet, `uvcube.gif` for an AniGif. With **Directions** ticked, a static model's strip, AniGif or MP4 holds every direction in the one file, one frame each in the order set: a strip of eight directions is `uvcube_static_strip8.png`, a single row, and an AniGif or MP4 shows each direction for a second in turn.

Each of these asks for the folder to save in every time, opening where the last export went; cancel, and nothing is saved.

On Android and iOS, which have no right-click, the same items are in the Animation group of the menu drawer and act on the selected entry.

### Batch export

Each entry has a tick box. Below the list:

- **All** ticks or clears every entry. It doesn't change which entry is selected, or the animation playing.
- The drop-down chooses **Sprite strip**, **Spritesheet**, **Texture Atlas**, **AniGif** or, when FFmpeg loaded, **MP4 video**. See *Texture atlas* below. The choice is remembered between sessions, and MP4 video comes back once FFmpeg has loaded.
- **Metadata**, above Export, saves a JSON file beside each strip, spritesheet or atlas page, with the same name and the extension `.json`; see *Metadata* below. It is offered only for strips and spritesheets, applies to the right-click menu's strips and spritesheets too, and is remembered between sessions. A texture atlas always has its metadata, as without it the animations on a page can't be told apart: while Texture Atlas is chosen the box shows ticked and greyed out, and choosing another format shows your own choice again.
- **Directions**, beside it, exports every animation in each direction set in Animation, Directions, in the order set there, one direction after another for each animation before the next animation. For each direction the camera is turned round the model by the direction's bearing, as turning the azimuth dial on by that much would, so bearing 0 is the view as it is; the framing is the same in every direction. A sprite strip is then one file per direction, `<model>_<animation>_dir01_strip<frames>.png` and so on, a spritesheet holds every direction's frames in its grid, a texture atlas packs them in turn, and an AniGif or MP4 is one file per direction, `<animation>_dir01.gif` and so on. A static model, one with no animations, is the exception: its strip, AniGif or MP4 holds every direction in one file. The metadata's `directions` lists the directions' bearings in that order, and each frame's `direction` says which it is. Abort stops at once. The right-click menu's saves use the directions too while it is ticked. It is remembered between sessions.
- **Two passes.** Every export runs twice, from Export or the right-click menu; there is nothing to tick. The first pass draws every frame of every ticked animation, in every direction, with overscan off whether or not it is on (but see below for static models), and saves nothing: it only measures how far the frames reach on each side, over the whole batch, to a fraction of a pixel where the edge pixels are partly drawn. The second pass is then the export as usual, overscan as chosen, but each capture's framing is slid and scaled so the sprite fills the frame, with the sprite centred. On the axis with least room it leaves the **padding** on both sides: the number of empty pixels set by the Padding slider in Animation, Animation Settings, 0 by default and at most a quarter of the grab size, kept in `settings.json` as `padding`. The sprite's edge is aimed a quarter of a pixel past the padding without overscan, past the centre of the next pixel, as frames drawn without overscan have hard edges, and halfway across it with overscan, whose smoothing covers it partly. A **static** model, one with no animations (`is_animated` false in the metadata), is measured more finely: the first pass draws at 4x overscan with the Box filter, an exact average, which finds the edge to about an eighth of a pixel, at the cost of a slower first pass, and both passes leave 2% of the frame spare round the fit, so the first pass never draws up to the frame's edge. Animated models are measured at 1x, which finds a hard edge only to within half a pixel, so their padding can come out a pixel more, or a part of a pixel be lost, now and then. **Exact**, beside Directions, measures animated models as a static one is, at 4x overscan with 2% spare, so their padding comes out exactly as set too, at the cost of a slower first pass; it starts clear each session and is not saved. Ticking it first shows what it does and how much longer the first pass takes: **OK** ticks it, **Cancel** leaves it clear, and **Do not show this again**, between them, stops the message appearing again either way, kept as `showExactWarning` in `settings.json`. With Exact unticked, if an animated model's export comes out with neither left and right nor top and bottom both at the padding, a message says so once the export's dialog has closed, giving the `sprite_empty` it came out at, and suggests ticking Exact; benchmarks never show it. With overscan, and padding of 0, the overscan's smoothing just past the sprite's edge can be cut off by the frame. The sprite keeps its shape, so the other sides are left with a little more. In orthographic projection the scaling is done with the orthographic height, in perspective with the camera's distance, which is close rather than exact. Like the rest of an export's framing it is only for the export: the view is put back afterwards, and the pan and distance settings are not changed. All the metadata comes from the second pass. The origin moves as the sprite is recentred, to wherever the centre of rotation then falls, to a fraction of a pixel, and every capture of the batch is framed alike, so every file gives the same origin. The camera's `distance` and `ortho_height` are the second pass's; the orthographic height is changed for that pass only. `sprite_empty` is worked out once the export ends, as the least on each side over every frame of the second pass, and the same values are written into every metadata file of the batch, at least one side being the padding when the measuring was fine enough; each frame's own `empty` is left as it is. `two_pass` is true. If the sprite touched the edge in the first pass it may have been cut off, so it may not shrink quite as far as aimed. A locked camera is exported as it stands. The progress bar covers both passes; the time remaining is for the pass under way alone, and says so, as *Time remaining for Pass 1* or *Pass 2*. Abort during the first pass exports nothing.
- **Export** always asks for a folder first, whatever is being exported, so a new sub-folder can be made for the batch; cancel, and nothing is exported. It opens where the last export went, or for a texture atlas where the last atlas went, both remembered between sessions. It then saves every ticked entry that way, one after another. The grab folder does not change. The ticks are left as they were, so the same batch can be exported again, and once it ends the entry selected before it is selected and playing again. Failures do not stop the others.
- **Progress.** While the batch runs, a dialog shows a progress bar for the whole batch, which animation it is on and which frame is being captured or that it is being saved, and a list of the files saved so far. **Abort** in it stops the batch at once, as does Escape or the dialog's close box. While it runs, an estimate of the time remaining is shown under the bar, as hours, minutes and seconds (H:MM:SS, the hours going past 24 rather than into days), from the time taken so far; it appears after the first couple of seconds. At the end it shows what was exported, how long the export took, and any failures, in place of a separate message; Abort is then disabled and **Close** enabled. After an abort the dialog closes by itself straight away. With **Autoclose when done** ticked, beside Abort, it also closes by itself once an export has finished, unless something failed, when it stays open so you can read why; the outcome is in the Debug tab either way. The tick is remembered between sessions.
- **No redrawing meanwhile.** Every frame of an export is drawn off screen, so the view's own timed redraws are stopped while a batch runs, and the view is drawn only as the grabs need. On macOS and iOS, where grabs are screenshots of the view, it carries on drawing.
- **Abort**, under the list and in the progress dialog, enabled only while a batch runs, stops at once with nothing more done: the capture under way is dropped, and no atlas page, metadata or Exact suggestion still to come is made. Files already being written are finished. Entries not yet exported stay ticked.
- **Saving as it goes.** Each image is saved as soon as it is complete, a strip or spritesheet once its last direction is captured and a texture atlas page once it is full, and its frames are let go, so a batch holds only what it still needs. What its metadata will say is worked out from the frames then, and kept; every `.json` is written once the batch ends, after all the images, so the list shows the images saved one by one and then the metadata files. A 2-pass export needs this, as its `sprite_empty` is the whole second pass's. The right-click menu's saves write the `.json` straight after the image.
- **Quitting mid-export.** Closing the window while anything is being captured, exported or written asks *Still exporting. Do you really want to quit?* No carries on with the export. Yes stops it and quits: the capture under way and anything not yet saved, such as a texture atlas's pages, are dropped, while files already being written are finished first, so none is left half written.

### Results

The **Results** tab, between Model and Debug, plays back what has been exported, using only the exported files themselves:

- **Select Folder...**, at the bottom, chooses the folder to read; beside it is the folder, followed in brackets by the model its exports were made from, its file name as the metadata's `meta.file` gives it, without its folder. It is cut short with an ellipsis if it would run into Show grid; its hint gives all of it, and how many animations and metadata files were read. It opens where the last export went, kept in `settings.json` as `lastExportFolder`, and that folder is also read the first time the tab is shown. After an export to the folder being shown, the tab reads it again.
- **The list** on the right is every animation found in the folder's metadata: every `.json` beside its `.png`, read in name order, whose `animations` are objects with `name`, `frame_count` and `time`. Metadata from before that change, and AniGifs and MP4s, are not read yet. An animation saved more than once, in a strip and an atlas say, is listed once, the first file read supplying its frames. The first animation is selected.
- **The animation** is drawn in the middle of the drawing area, each frame cut from its image at `image.sprite_size`, pixels kept sharp when magnified. It plays straight away at its own rate, its `frame_count` frames over its `time` seconds, so an animation whose frame count was changed plays at the rate that gives.
- **A checker** of two greys, as the Model tab's Transparent background, is drawn behind the animation, so its transparent parts can be seen. **Grid Size**, the right half of the slider row under the player, sets its squares in the sprite's own pixels, from 1 to 16 but no more than half the sprite's smaller side; it zooms with the animation, each square always covering exactly that many of its pixels. **Show grid**, at the right of the Select Folder row, hides the checker when cleared; it starts ticked and is remembered between sessions, as `resultsShowGrid` in `settings.json`.
- **A yellow border**, 1 pixel wide, is drawn on the drawing area just outside the animation, so the edges of its frames can be seen; it covers none of the frame's own pixels.
- **The controls** under it are the Model tab's player buttons, first, previous, play or pause, next and last, with the frame showing, then **<** and **>** to step through the animation's directions, starting from the first, with its bearing shown, and the frame count, time and frame rate. **Zoom**, the left half of the slider row, magnifies it, its top end always the largest that fits the space, so it never grows past the drawing area, however the window is sized. The zoom chosen is remembered between sessions, as `resultsZoom` in `settings.json`, written when you leave the tab or close Sprite3D; if the space is smaller when it is shown again, it is shown as large as fits, the slider brought down to match, and it grows back towards the zoom chosen as the space allows.
- **Edges.** Directly under the animation list, level with the Select Folder row, is a drop-down of **Left**, **Top**, **Right** and **Bottom**, with back and forward buttons. An *edge case* is a frame whose `empty` on a side equals its own image's `sprite_empty` on that side: a frame that comes closest to that edge, which is what decides how far the frames could be cropped. Every image has at least one on each side, on any page, in any animation and direction; a frame can be an edge case on more than one side. The buttons jump to the previous or next edge case over everything read, round and round, selecting that animation, direction and frame and pausing there: every left edge case first, then top, right and bottom, each side's in the list's order, then each animation's directions, then its frames. From the last left edge case, the forward button goes on to the first top one, and the drop-down changes to show the side of the edge case showing. Choosing a side in the drop-down yourself makes the buttons carry on from that side, from the frame showing. Beside them, on an edge case, is which of them all it is, and which of its side's, such as *12 of 40 (3 of 9 top)*; on any other frame, playing or not, it says *Edge Case Finder*. Its hint gives the frame's `empty` and its image's `sprite_empty` on that side, and how many edge cases there are.
- **Empty border values.** At the right of the Select Folder row, beside Show grid, while the animation is paused, the frame showing's `empty` is shown as `(left,top,right,bottom)`, such as `(12,0,9,31)`, the number of wholly transparent columns or rows at each edge of the frame. Its hint explains the order and what the numbers mean; **File, Settings**, under **Results**, turns the hint off, kept as `resultsEdgeHint`.

### Debugging

`settings.json` has a hidden `debug_enabled`, false unless you change it by hand; the application only ever sets it back to false, with **File, Debug, Disable Debug**. Starting Sprite3D with **`--debug`** on the command line turns debugging on for that run only, without changing `settings.json`. While debugging is on:

- The Debug tab says so at startup, and whether it came from `settings.json` or `--debug`. Nothing is said while debugging is off.
- OpenH264 is not fetched, downloaded or loaded; see *OpenH264*.
- **File, Debug, Frame Borders** is added to the menu, a tick that turns on `debug_frame_borders`, kept in `settings.json`. While it is ticked, every exported frame gets a 1-pixel opaque black border round its edge, in strips, spritesheets, atlas pages, AniGifs and MP4s, so each cell's bounds can be seen. The border is only in the saved images: the metadata, and a 2-pass export's measuring, use the frames as rendered. With debugging off the borders are never drawn, whatever `debug_frame_borders` says.
- **File, Debug, Save Oversampled Frame** is a tick, kept in `settings.json` as `debug_save_oversampled`. While it and overscan are both on, each export saves its first frame as drawn, at the overscanned size before it is scaled down, as `Oversampled.png` in the export's folder, replacing any there, so you can see that overscan really is drawing larger; the Debug tab says where it went and at what size. Grabs on macOS and iOS are screenshots, with no overscan, so nothing is saved there.
- **File, Debug, Compare Images...** (desktop only) asks for two images, *First File to Compare* then *Second File to Compare*, either of PNG, JPEG, BMP, GIF or TIFF. If they are the same size it makes a third, saved where a save dialog says, `differences.png` beside the first unless changed, and always a PNG: each pixel is **black** where the two are alike in red, green, blue and alpha, **light grey** where only red, green or blue differ, **dark grey** where only alpha differs, and **white** where both do. The Debug tab gives how many pixels fell in each. Images of different sizes are not compared; a message gives both sizes.
- **File, Debug, Benchmark** asks for a folder, then exports the model shown 8 times as a **Texture Atlas**, with metadata and directions, which it ticks for you, and the entries ticked in the Animations list if two or more are, otherwise every entry, ticking **All** for you: once without overscan, then at each overscan from 2x to 8x. Each run goes into a folder of its own in the one chosen, `ortho1x_<stamp>` to `ortho8x_<stamp>` in orthographic projection or `persp1x_<stamp>` to `persp8x_<stamp>` in perspective, `<stamp>` being when the benchmark started as `YYMMDDHHMMSS`, such as `ortho4x_261025135800`, and is timed from start to finish, both passes and the pages. The progress dialog closes itself after each run. Once all 8 are done, the Debug tab gets the results between `Benchmark Results start` and `Benchmark Results end`, one comma-separated line per run: the overscan, the seconds taken and the frames made per second, such as `4,80.826,24.32`. The same lines alone are saved in the folder chosen as `benchmark_<stamp>.csv`. A run that is aborted or goes wrong ends the benchmark there, with the lines of the runs before it. The overscan chosen in Animation Settings is put back afterwards.
- **File, Debug, Disable Debug**, there only while `debug_enabled` is true, sets it back to false in `settings.json` straight away. Debugging stops at once and File, Debug is removed, unless **`--debug`** is keeping it on for that run. OpenH264 is only looked for at startup, so it is fetched the next time Sprite3D starts.

**Memory leaks.** Leaks still allocated when the program closes are shown in a message box, as `ReportMemoryLeaksOnShutdown` is set in `Sprite3d.dpr` (switch it off for a release build). On Windows, [FastMM5](https://github.com/pleriche/FastMM5), a submodule in `FastMM5`, is the memory manager, and it also writes the whole report, every leaked block and what it holds, to `Sprite3d_MemoryManager_EventLog.txt` in the executable's folder. The file is deleted when the program starts, so it only ever holds the last run's leaks; no file means nothing leaked. Ctrl+C in the message box copies its text too. On other platforms the system's memory manager is used and leaks are not reported.

Whether debugging is on or not, any saved image with a frame whose empty border is 0 on some side, so that the sprite may be cut off, is reported in the Debug tab, with how many frames do and on which sides. An export with padding of 0 is the exception, as it aims for that.

### Texture atlas

A texture atlas is the animations of a batch packed together onto shared pages, each a spritesheet of several animations. Export captures the ticked entries in turn, and saves each page as soon as its frames are in:

- **Order.** The animations go on in the order of the Animations list, their frames left to right and then down, each one's straight after the last one's. When a page is full the next frame starts the next page, even partway through an animation, so every page but the last is full and an animation of any length fits.
- **Page size.** A page holds as many frames, of the grab size, as fit in the page size from Animation, Animation Settings each way: at 4k with 256 × 256 frames that is 16 × 16 = 256 frames. Each page is then made as small as its frames allow: powers of 2 each way, the least area first and then the squarest, or with *Pages need not be a power of 2* ticked, exactly the grid of frames it needs. Cells after the last frame are left transparent, and the metadata's `unused` counts them.
- **Names.** The pages are named after the model, `<model>_atlas_01.png`, `<model>_atlas_02.png` and so on, each with its `.json`, which an atlas always has, listing the animations with frames on that page in `animations`, each with its name, whole frame count and length in seconds, and, for every frame, which animation, direction and frame it is. Before the new pages are written, every existing `<model>_atlas_<number>.png` in the folder, and the `.json` beside each, is deleted, so no page is left over from an earlier, larger atlas; nothing else is touched, and nothing is deleted if there is no new page to write.
- **Abort** stops at once; no page still to come is made, and no metadata is written.
- **Memory.** Only the frames of the page being filled are kept, as every full page is saved and let go straight away, but a 16k page alone takes 1 GB to make, so a large page size needs plenty of memory.
- **Metadata.** Each page's `.json` is written once the batch ends, when the number of pages and frames in all are known.

Every animation of a batch is framed alike, so they share one origin.

### Metadata

With **Metadata** ticked, a strip or spritesheet, and always an atlas page, is followed by a JSON file of the same name, such as `hero_walk_dir01_strip24.json` beside `hero_walk_dir01_strip24.png`. It starts with a `meta` section: `export_type`, which is `strip`, `sheet` or `atlas`, the page and the number of pages, the creator credits from File, Save Project, the day the project started, when the export was made, and the model file. It then gives the image's size and layout; the `origin`, where the model's centre of rotation falls in every frame, to a thousandth of a pixel; the animations it holds in `animations`, each with its `name`, `frame_count` and `time`, its own length in seconds, which a changed frame count leaves as it is, so `frame_count / time` is its frame rate; the number of empty cells after the last frame in `unused`; and, in `frames`, one entry per frame saying which animation, direction and frame it is, with its *empty sections*, the fully transparent columns and rows at its edges, with `sprite_empty`, the smallest of each over all the frames, so every frame can be cropped by the same amount without losing anything. See [Metadata](metadata.md) for the format and how each value is worked out.

### How the frames are made

- **Size and framing.** Every frame is grabbed off screen at the grab size from File, Settings, with no background, whatever File, Background Settings shows behind the model on screen. The camera is framed once for the whole animation, so the model is the same size and in the same place in every frame and the frames line up. An animation saved on its own, from the right-click menu, is framed around its own swept volume, so it fills the image as far as its own poses allow. A batch, and a static model's still, are framed around the combined swept volume of the rest pose and every animation used, so every animation of a batch is at the same scale. The view on screen is put back afterwards. See [Volumes](volumes.md).
- **Frame rate.** Animation, Animation Settings... sets it (30 frames a second unless changed). An animation lasting *D* seconds is cut into *N* = *D* × rate frames, rounded, and frame *i* shows the pose at *i* × *D* / *N* seconds. The frame after the last would be at *D*, which in a looping animation is the first pose again, so the frames loop with no jump and no repeated frame. To keep a whole number of frames in the cycle, the rate actually used is *N* / *D*: 8 frames a second on a 1.3-second walk gives 10 frames of 0.13 seconds. GIFs and MP4s play the frames at that rate, so they last exactly one cycle.
- **Warm-up.** An animation that has just been started can take a few drawn frames to show its first pose, and until then the model can still be in the pose it had before, or sit at another height. So before each animation is captured, its first frame is grabbed three times and those grabs are thrown away; only then is it grabbed for keeping.
- **Poses, not blended images.** Gorilla3D bakes each animation into poses about 60 times a second on desktop, interpolating between the file's keyframes. Each frame uses the baked pose nearest its time, within 1/120 of a second, and images are never blended, which would leave ghosts in a sprite. A rate above the baked rate repeats some poses.
- **Transparency.** Strips, spritesheets and GIFs are transparent around the model. GIF allows only fully transparent or fully opaque pixels, so soft edges become one or the other, and each frame has its own palette of up to 255 colours. MP4 has no transparency: frames are laid over black.
- **Memory.** A capture is refused, with a message, if its frames would need more than 1 GB; choose a smaller grab size for very long animations.

### MP4 video

MP4 files are video only, with a key frame every 12 frames and no B-frames. Which codec they use depends on the libraries found; an export's progress list names the codec of each file saved.

| Libraries found | Codec | Plays in |
|---|---|---|
| FFmpeg and OpenH264 | H.264 Constrained Baseline, from OpenH264, at a constant quality of about a quarter of a bit per pixel per frame | everything, web browsers included |
| FFmpeg only | MPEG-4 Part 2, FFmpeg's own `mpeg4` encoder, at a fixed high quality | desktop players such as VLC, QuickTime and the Windows players, but not web browsers |
| neither | MP4 is not offered | |

Odd widths and heights get one black row or column added, as both encoders need even sizes. Grabs smaller than 16 pixels across or down are always MPEG-4 Part 2, as OpenH264 cannot take them. See *FFmpeg libraries* and *OpenH264* above.

## Settings

Settings are kept in `settings.json`, written by Neon, in the folder each platform expects:

| Platform | Folder |
|---|---|
| Windows | `%APPDATA%\Sprite3D` |
| macOS | `~/Library/Application Support/Sprite3D` |
| Linux | `$XDG_CONFIG_HOME/Sprite3D`, or `~/.config/Sprite3D` |
| Android | the application's documents folder |
| iOS | `Library/Application Support/Sprite3D` |

The file is plain JSON and can be edited by hand. Colours are written as `#AARRGGBB`.

The same folder has a `bounds` folder: the measured bounds of each model's animations, one small JSON file per model, named from a hash of the model's full path, size and time of last change. A model that is edited, replaced or moved is simply measured again, and its old file is no longer used. The folder can be deleted at any time; nothing is lost but the time it takes to measure again.

## Themes

The themes other than Default are FMX styles that come with RAD Studio, in its `Redist\styles\Fmx` folder:

| Theme | Style file | Look |
|---|---|---|
| Dark | `Dark.style` | dark grey |
| Aqua Graphite | `AquaGraphite.style` | dark grey with blue |
| Ruby Graphite | `RubyGraphite.style` | dark grey with red |
| Golden Graphite | `GoldenGraphite.style` | dark grey with gold |

The four styles are linked into the program as RCDATA resources, so every build, Debug or Release, on every platform, carries them inside it and there is nothing to deploy. The project's pre-build event runs `src/styles/buildstyles.cmd`, which:

1. copies any style missing from `src/styles` out of `$(BDS)\Redist\styles\Fmx`; files already there are left alone, so a style can be swapped by hand;
2. compiles `src/styles/Sprite3DThemes.rc` with RAD Studio's `brcc32`, from that folder, into `Sprite3DThemes.res`, which `Sprite3d.dpr` links in.

The `.rc` is compiled there rather than by the IDE because the IDE resolves its file names from the project folder and may compile it before the pre-build event has run. If a style or `brcc32` can't be found, or the compile fails, the build stops with an error saying which.

At run time each theme's resource, such as `Sprite3DAquaGraphiteStyle`, is used first. Should one be missing, Sprite3D falls back to looking for the `.style` file, matched regardless of case:

1. in a `styles` folder beside the program (or, when run from the IDE, in the repository root), or beside the program itself;
2. in a `styles` folder in the settings folder above;
3. on Windows, when run from the IDE, in RAD Studio's own `Redist\styles\Fmx` folder.

If a style cannot be found at all, the theme and title bars stay as they were and the places tried are reported.

Title bars follow the theme, using the style's own form background colour and the theme's accent colour for the window border:

| Platform | Title bar |
|---|---|
| Windows 11 | the caption takes the style's background colour, with black or white text, whichever reads better, and the accent as the border |
| Windows 10 | dark for the dark themes; Windows 10 cannot colour a title bar |
| macOS 10.14 on | dark appearance for the dark themes, for the whole application |
| Linux | unchanged: the window manager draws it |
| Android, iOS | no title bar |

## File associations

| Platform | Open With | Always open with |
|---|---|---|
| Windows | `HKCU\Software\Classes`: a `Sprite3D.Model` ProgID, `Applications\Sprite3d.exe` and each extension's `OpenWithProgids`; also listed in Settings, Default apps | the extension's per-user default; a default chosen in Windows' own dialog can only be changed there |
| Linux | `~/.local/share/applications/sprite3d.desktop` and a shared-mime-info package in `~/.local/share/mime/packages` | `[Default Applications]` in `~/.config/mimeapps.list` |
| macOS | `CFBundleDocumentTypes` in `src/info.plist.TemplateOSX.xml` | Launch Services |
| Android, iOS | not available | not available |

Sprite3D's own project files, `.sprite3d`, are associated each time Sprite3D starts, whatever is chosen for model files: on Windows they get a ProgID of their own, `Sprite3D.Project`, made the extension's default in `HKCU\Software\Classes\.sprite3d`; on Linux the MIME type `application/x-sprite3d` goes into the desktop entry and is made its default in `mimeapps.list`; on macOS they are a second document type in the bundle, with Sprite3D as their owner. If you once picked another program for them with *Always* in Windows' own *How do you want to open this file?* dialog, that choice still wins; pick Sprite3D there once, or in Settings, Default apps.

The previous defaults are kept in `settings.json` as `associationBackup` until they have been put back.

## Documentation

Every public item in the source is documented with `//**` comments for [PasDoc](https://pasdoc.github.io/). The HTML help is in `docs/lib` and `docs/ui`, one set for each source folder, built from within that folder with, for example:

```
cd src/lib
pasdoc --staronly --auto-abstract --format html --output ../../docs/lib *.pas
```

## Licences

- `src/ffmpeg` holds the FFmpeg Delphi/Pascal headers from [DelphiFFmpeg.com](http://www.delphiffmpeg.com/headers/), unchanged. They are not compiled into Sprite3D: they bind FFmpeg statically, and define some error codes only for Windows and macOS, so `Sprite3DVideo.pas` instead declares the few records and constants it needs, copied from them, and loads the libraries itself. The headers and those declarations are under DelphiFFmpeg.com's BSD-style licence, in `src/ffmpeg/LICENSE.txt`: the notice must stay with the source, and binaries must reproduce it in their documentation.
- The FFmpeg libraries in the DLL pack are under FFmpeg's own licence, the LGPL for the builds used. Shipping them with Sprite3D brings the LGPL's conditions for those libraries.
- `src/lib/Sprite3DOpenH264.pas` translates declarations from OpenH264's API headers, Copyright (c) 2013, Cisco Systems, under the BSD 2-clause licence: the notice stays with the source, and binaries must reproduce it in their documentation. The OpenH264 library itself is not distributed with Sprite3D; Cisco's binary licence and its H.264 patent cover apply to copies downloaded from Cisco.

## Paths

Every file the application opens or writes, models, settings, the bounds cache, grabs, icons, exports and the video libraries, goes through `OSFriendlyPath` in `common/OSPaths.pas` first, which gives it the platform's own delimiters: only `\` on Windows and only `/` elsewhere, with doubled delimiters inside the path made single. Some Windows targets, such as Win64 on ARM (ARM64EC), don't accept `/` in every path, and a model path kept in `settings.json` on one system may be read on another.

## Known issues

- On macOS and iOS, where Gorilla3D renders through Metal, grabs and icons are screenshots of the view as shown, cropped to the grab's shape and scaled: the model is not refitted for them, and they are opaque, with the viewport's own background.
- In orthographic projection the viewport background is not drawn, as Gorilla3D draws it black over the whole scene there. Grabs are not affected.
- Background colours in the viewport show about 1.25 times brighter than chosen. Grabs and icons use the exact colours.
- Android would need intent filters, and iOS document types, added to their manifest and Info.plist for Open With; neither is set up yet.
- The camera view and View menu ticks are saved when the main form is destroyed, which Android and iOS do not always do before ending an application.
- Animations are all treated as loops: for one that does not loop, the last pose is left out of the export.
- On macOS and iOS, animation frames are screenshots, as grabs are there, so they share the limits above.
- MP4 export has been tested on Windows 64-bit; the macOS and Linux libraries are not in the DLL pack yet.
- H.264 export through OpenH264 has been tested on Windows 64-bit with OpenH264 2.6.0. Versions 2.0 to 2.5 lay out the encoder's output differently; Sprite3D allows for that, but has not been tested with them.
- The OpenH264 download and the deployment entries for platforms other than Windows 64-bit are new and untested.
- The first time a model's volumes are needed, which is when it loads, every pose of every animation is measured, and the application does not respond until that is done. For a model with many long animations this can take a moment.
- The swept volumes are built from bounding boxes, so a model that fills little of its box is framed with room to spare.
- Overscan is done on the CPU, after each grab is read back. A high factor with a wide filter is slow, Lanczos 3 at 8x most of all, and an export makes one such grab per frame. Box is the quickest. Where the GPU cannot draw the whole factor at once, each grab is several drawings, which multiplies the time again: 8x at 256 × 256 with drawings of 512 pixels is sixteen drawings a frame.
- Shifted drawings slide the camera rather than the projection. In orthographic views that is exact; in perspective, parts of the model much nearer or further than its centre are sampled a fraction of a pixel off, which only shows as slightly softer anti-aliasing there.
- Overscan does not apply on macOS and iOS, where grabs are screenshots of the view.

## Further reading

- [Viewport](viewport.md): how the viewport background is drawn, and why it is built the way it is.
- [OffScreen](offscreen.md): how the offscreen rendering works, and why it is built the way it is.
- [Volumes](volumes.md): the volume a model sweeps turning about its up axis, how it is measured for each animation, and how the camera is fitted to it.
- [Metadata](metadata.md): the JSON saved beside a strip or spritesheet, and how its empty sections and origin are measured.
- [Directions](directions.md): the Animation, Directions dialog, how the order of the directions works, Change Order, and the directions file Export and Import use.
