# Sprite3D

Sprite3D is a Delphi FireMonkey application for viewing 3D models from fixed and free camera angles, and for rendering them to images and icons. It is built on [Gorilla3D](https://www.gorilla3d.de/) and is meant as a tool for making sprites from 3D models: load a model, choose a view such as isometric, and grab it as a transparent PNG or a Windows icon, or export its animations as sprite strips, texture atlases, animated GIFs or MP4 videos.

The code is split so that the 3D parts can be reused: everything in `src/lib` is independent of the application, and `src/ui` holds the forms and the application's own rules.

![Sprite3D showing the sample cube in the isometric view, over the checker that stands for a transparent background](img/ScreenShot.png)

## Features

- **Orbit camera.** Three dials set azimuth, inclination and roll. The camera turns on a chain of single-axis pivots, so it passes over the poles without gimbal lock.
- **Fixed views.** View, Camera offers Isometric, Pixel 2:1, 1/4 View, 3/4 View, Sqrt(2), Golden Ratio, Head On, Top Down and Side View, or Variable to use the dials. The chosen view, and the dials' angles in Variable, are restored next session.
- **Lock Camera.** View, Camera, Lock Camera fixes the camera exactly where it is. While it is ticked nothing moves or turns it: the views, Orthographic and Fit any angle are disabled, loading a model or resizing the window does not refit, and grabs, icons and animation exports use the view as it stands rather than fitting the model to their own size. The `(None)` turn can't be exported while the camera is locked, since it works by turning the camera. Unticking it leaves the camera where it is until something else changes it. The lock can't be changed during an export, and starts off each session.
- **Pan.** View, Camera, Variable also has a Pan box, off by default. Ticked, two sliders move the view along the model's own X and Z axes, up to twice the model's radius either way, for the odd model that should sit off centre. The pan sits on top of the fit and never changes the angles or the distance; it applies in every view, and in grabs and icons, until it is switched off, and the window title says "(panned)" while it is in use. Centre puts it back to 0.
- **Fitting.** Each model is centred and the camera fitted so the model fills the view. With "Fit any angle" checked, the fit holds for every angle, so the dials can never push the model out of view.
- **Perspective or orthographic** projection.
- **Bounding box, axes and grid.** The model's bounding box, its X, Y and Z axes through its centre of rotation, and a far-reaching grid on the model's floor, the lowest point of its own geometry, that fades out with distance. Each can be switched on or off in the View menu, as can "Fit any angle" and "Orthographic".
- **Grab.** File, Grab renders the view off screen at the grab size chosen in File, Settings (256 × 256 pixels unless changed), with the model fitted to fill the image, and saves it as the next of `grab001.png`, `grab002.png` and so on. The background is transparent unless a solid colour or gradient is chosen.
- **Save As Icon.** File, Save As Icon renders the view at each size Windows 10 and 11 use (16, 20, 24, 32, 40, 48, 64 and 256 pixels, 32-bit) and saves them as one `.ico` file. The icon writer is designed so other formats, such as macOS icons, can be added.
- **Animation export.** Every animation in the model can be saved frame by frame as a sprite strip, a texture atlas, an animated GIF or an MP4 video, one at a time or in a batch. See *Animation export* below.
- **Background.** File, Background Settings... chooses what is drawn behind the model: None, Transparent (a two-grey checker standing for transparency, with an adjustable square size), Solid, or Gradient (top to bottom, left to right, or either diagonal). Colours can be picked or typed as hex. Grabs and icons follow the choice.
- **Opening files from the system.** When the operating system opens the application with a model, for example a `.glb` or `.gltf` file double-clicked in Explorer or Finder, that model is loaded instead of the default one. This is handled on Windows, macOS, Linux, Android and iOS.
- **File, Settings...** A dialog for:
  - **Open model files.** Offer Sprite3D under Open With for model files and, optionally, make it their default application. Before changing a default, the one in use is recorded; clearing the box puts it back, if that application is still installed, and otherwise just removes Sprite3D's claim. Everything is per user. On Windows a default the user picked in Windows' own dialog can only be changed there, so Settings, Default apps is opened when that happens. On macOS, Open With comes from the app bundle (see below) and only the default can be changed. Android and iOS decide these things when the app is built, so the group is disabled there.
  - **Startup action.** None (no model is loaded), Load default model, or Load last model, which falls back to the default model if the last one has gone. A file the system asks Sprite3D to open always comes first.
  - **Grab size.** The size of every off-screen grab: 8 × 8, 16 × 16, 24 × 24, 32 × 32, 64 × 64, 96 × 96, 128 × 128, 160 × 160, 192 × 192, 256 × 256, 384 × 384 or 512 × 512, or Custom, where width and height are typed separately, each from 8 to 1024 pixels. Kept as `grabWidth` and `grabHeight`. Icons keep the sizes their file format needs. Below it, the grab folder in use is shown with a Reset button, which empties it so the next grab asks for a folder again.
  - **Theme.** Default (FMX's own platform style), Dark, or one of three coloured styles, Aqua Graphite, Ruby Graphite and Golden Graphite, applied at once. Title bars follow the theme where the system allows. See *Themes* below.
  - **Graphics processor**, Windows only: let Windows decide, low power or high power, through `common/GpuPreference.pas`. It takes effect the next time Sprite3D starts.
- **File, Animation...** A slider sets the frame rate animations are exported at, from 1 to 60 frames a second, 30 unless changed. Kept as `animationFps`.
- **Settings kept between sessions** in `settings.json`: the grab folder, the icon folder, the background, the camera view, the pan, the View menu's on/off items, the animation frame rate, and the choices in File, Settings.
- **Mobile layout.** On Android and iOS the menus are reached through a hamburger button.

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

and extract it in the project root, the folder holding `README.md`. It creates the `dlls` folder:

```
Sprite3D/
`-- dlls/
    `-- win64/       avutil-60.dll, avcodec-62.dll, avformat-62.dll and the libraries they need
```

macOS (`dlls/macarm`) and Linux (`dlls/linux64`) libraries will follow in the same pack. The `.gitignore` already keeps `.dll` and `.so` files out of Git, so the extracted libraries are never committed.

Sprite3D loads the libraries only when it starts, and only to offer MP4: if they are missing or the wrong version, the program runs exactly as before and MP4 is not offered. The Debug tab says at start-up which happened, and from where the libraries were loaded. They are looked for, in order:

1. beside the executable;
2. in `dlls/<platform>` beside the executable;
3. in a macOS bundle's `Contents/Frameworks` folder;
4. in `dlls/<platform>` in any of the six folders above the executable, so a build run from `src/Win64/Debug` finds the repository's `dlls/win64`;
5. wherever the system looks for shared libraries.

`<platform>` is `win64`, `macarm`, `macx64` or `linux64`. The libraries must be FFmpeg 8.1's (avutil 60, avcodec 62, avformat 62) and include the MPEG-4 encoder, which every standard build does. To ship Sprite3D with MP4 export, deploy the contents of the platform's folder beside the executable, or in `Contents/Frameworks` on macOS.

### OpenH264 (optional, for H.264 MP4 files)

On its own, FFmpeg's MP4 export writes MPEG-4 Part 2 video, which desktop players handle but web browsers do not. If Cisco's [OpenH264](https://github.com/cisco/openh264) library is present as well, MP4 files are H.264 instead, which plays everywhere.

OpenH264 is not in the DLL pack and should not be added to it. Cisco pays the H.264 patent royalties only for copies of its library downloaded from Cisco, so each user should download it themselves from the [OpenH264 releases](https://github.com/cisco/openh264/releases), which link to Cisco's binaries:

| Platform | File (version 2.0 or later) |
|---|---|
| Windows 64-bit | `openh264-<version>-win64.dll` |
| macOS Apple silicon | `libopenh264-<version>-mac-arm64.dylib` |
| Linux 64-bit | `libopenh264-<version>-linux64.<n>.so` |

Unpack it (the downloads are `.bz2` files) and put it in the folder the FFmpeg libraries are in, such as `dlls/win64`; the file name can stay as it is. Sprite3D also looks in every other folder it looks in for FFmpeg, and last for the system's own copy. If several copies are in one folder, the one whose name sorts last, normally the newest, is tried first. The Debug tab says at start-up which OpenH264 was loaded and from where, or, if none was, each file it found and why it could not be used (for example a 32-bit DLL in a 64-bit program), or the folders it looked in if it found none. If OpenH264 loads but then fails on a video, that file is written as MPEG-4 Part 2 instead and the Debug tab gives OpenH264's reason.

### First run

On start-up the application loads `models/uvcube.glb`, a cube with its faces labelled, from the repository's `models` folder. On Windows it looks for `models` in the current folder first, then three levels up, which is the repository root when run from `src/<platform>/<config>`. On macOS the folder is expected in the user's Library folder and on Linux in the home folder.

## Project layout

```
Sprite3D/
|-- Sprite3DGroup.groupproj
|-- README.md
|-- delphi-neon/              Neon JSON library (submodule)
|-- docs/                     generated API help (PasDoc)
|-- models/                   sample model: uvcube.glb
|-- dlls/                     FFmpeg libraries, from the DLL pack; not in Git
`-- src/
    |-- Sprite3d.dpr, .dproj, .res, Sprite3d_Icon.ico
    |-- ffmpeg/               DelphiFFmpeg.com FFmpeg 8.1 headers, unchanged, with their licence
    |-- styles/               the themes' FMX styles, linked into the program
    |   |-- Sprite3DThemes.rc        the RCDATA resources
    |   `-- buildstyles.cmd          pre-build: copies the .style files, builds the .res
    |-- lib/                  reusable units, no application code
    |   |-- Sprite3DCamera.pas       orbit camera, fitting, view extents
    |   |-- Sprite3DAxes.pas         a model's X, Y and Z axes
    |   |-- Sprite3DGrid.pas         floor grid drawn by a GLSL shader
    |   |-- Sprite3DOffscreen.pas    off-screen rendering with transparency
    |   |-- Sprite3DBackground.pas   none, checker, colour or gradient background
    |   |-- Sprite3DIconWriter.pas   icon file writers (Windows .ico)
    |   |-- Sprite3DOpenFiles.pas    files the system asks the app to open
    |   |-- Sprite3DFileAssoc.pas    Open With and default-application registration
    |   |-- Sprite3DStyles.pas       switching FMX styles at run time
    |   |-- Sprite3DTitleBar.pas     title bars coloured to match the style
    |   |-- Sprite3DFlatColour.pas   colours as textures, for Metal (macOS, iOS)
    |   |-- Sprite3DStorage.pas      per-user app folder and JSON settings
    |   |-- Sprite3DAnimCapture.pas  grabs every frame of an animation, or of a turn
    |   |-- Sprite3DSpriteSheet.pas  strips, atlases, PNG and animated GIF writers
    |   |-- Sprite3DVideo.pas        MP4 writer, loading FFmpeg only when present
    |   `-- Sprite3DOpenH264.pas     H.264 encoder, loading OpenH264 only when present
    |-- common/               small cross-project helpers
    |   |-- OSPaths.pas              where the program and its assets are
    |   |-- GpuPreference.pas        Windows' per-program GPU preference
    |   `-- DisplayData.pas          display modes (Windows only; not used by the app yet)
    `-- ui/                   the application
        |-- Sprite3dMain.pas, .fmx           main form
        |-- Sprite3DBackgroundForm.pas, .fmx Background Settings dialog
        |-- Sprite3DOrbitalForm.pas, .fmx    Variable camera dialog, with the pan
        |-- Sprite3DSettingsForm.pas, .fmx   Settings dialog
        |-- Sprite3DAnimationForm.pas, .fmx  Animation dialog: the export frame rate
        `-- Sprite3DHelpers.pas              application rules and settings
```

## Animation export

The Animations list on the right of the View tab shows the model's animations by name, after a first entry, `(None)`, which shows the model as loaded. Clicking an entry plays it.

### One animation

Right-click an entry to select and play it and open a menu:

| Item | Saves | File name |
|---|---|---|
| Save as sprite strip | every frame side by side in one row | `<animation>_strip<frames>.png` |
| Save as Texture Atlas | every frame in a square grid, left to right then top to bottom; any cells after the last frame are transparent | `<animation>.png` |
| Save as AniGif | an animated GIF that loops for ever | `<animation>.gif` |
| Save as MP4 video | a video-only MP4 file, H.264 when OpenH264 is present and MPEG-4 Part 2 otherwise; offered only when the FFmpeg libraries load | `<animation>.mp4` |

Files go to the grab folder, which is asked for the first time, as for File, Grab. A file with the same name is replaced. Characters that are not allowed in file names become underscores.

`(None)` has no animation, so it saves one full turn of the model in one second instead, named after the model with `_rotate` added, such as `uvcube_rotate.gif`.

On Android and iOS, which have no right-click, the same items are in the Animation group of the menu drawer and act on the selected entry.

### Batch export

Each entry has a tick box. Below the list:

- **All** ticks every animation, or clears every entry. It leaves `(None)` as it is, so the turn is only exported when you tick it yourself.
- The drop-down chooses **Sprite strip**, **Texture Atlas**, **AniGif** or, when FFmpeg loaded, **MP4 video**.
- **Export** asks for a folder, opening at the grab folder so a new sub-folder can be made there for the batch, then saves every ticked entry that way, one after another. The grab folder itself does not change. Each entry is unticked once it is saved, so after a failure, pressing Export again retries just the entries still ticked. Failures are listed at the end and do not stop the others.
- **Abort**, enabled only while a batch runs, lets the animation being captured finish and save, then drops the rest. Entries not yet exported stay ticked.

### How the frames are made

- **Size and framing.** Every frame is grabbed off screen at the grab size from File, Settings, with the background as chosen in File, Background Settings. The camera is framed once for the whole animation, around the union of every frame's bounding box, so the model is the same size and in the same place in every frame and the frames line up. The view on screen is put back afterwards.
- **Frame rate.** File, Animation... sets it (30 frames a second unless changed). An animation lasting *D* seconds is cut into *N* = *D* × rate frames, rounded, and frame *i* shows the pose at *i* × *D* / *N* seconds. The frame after the last would be at *D*, which in a looping animation is the first pose again, so the frames loop with no jump and no repeated frame. To keep a whole number of frames in the cycle, the rate actually used is *N* / *D*: 8 frames a second on a 1.3-second walk gives 10 frames of 0.13 seconds. GIFs and MP4s play the frames at that rate, so they last exactly one cycle.
- **Poses, not blended images.** Gorilla3D bakes each animation into poses about 60 times a second on desktop, interpolating between the file's keyframes. Each frame uses the baked pose nearest its time, within 1/120 of a second, and images are never blended, which would leave ghosts in a sprite. A rate above the baked rate repeats some poses.
- **Transparency.** Strips, atlases and GIFs keep the transparent background. GIF allows only fully transparent or fully opaque pixels, so soft edges become one or the other, and each frame has its own palette of up to 255 colours. MP4 has no transparency: frames are laid over black, unless a solid or gradient background already fills them.
- **Memory.** A capture is refused, with a message, if its frames would need more than 1 GB; choose a smaller grab size for very long animations.

### MP4 video

MP4 files are video only, with a key frame every 12 frames and no B-frames. Which codec they use depends on the libraries found; the Debug tab names the codec of each file saved.

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

The previous defaults are kept in `settings.json` as `associationBackup` until they have been put back.

## Documentation

Every public item in the source carries two kinds of documentation comment: `///` XML comments for Help Insight in the IDE, and `//**` comments for [PasDoc](https://pasdoc.github.io/). The HTML help is in `docs/lib` and `docs/ui`, one set for each source folder, built from within that folder with, for example:

```
cd src/lib
pasdoc --staronly --auto-abstract --format html --output ../../docs/lib *.pas
```

## Licences

- `src/ffmpeg` holds the FFmpeg Delphi/Pascal headers from [DelphiFFmpeg.com](http://www.delphiffmpeg.com/headers/), unchanged. They are under DelphiFFmpeg.com's BSD-style licence, in `src/ffmpeg/LICENSE.txt`: the notice must stay with the source, and binaries must reproduce it in their documentation.
- The FFmpeg libraries in the DLL pack are under FFmpeg's own licence, the LGPL for the builds used. Shipping them with Sprite3D brings the LGPL's conditions for those libraries.
- `src/lib/Sprite3DOpenH264.pas` translates declarations from OpenH264's API headers, Copyright (c) 2013, Cisco Systems, under the BSD 2-clause licence: the notice stays with the source, and binaries must reproduce it in their documentation. The OpenH264 library itself is not distributed with Sprite3D; Cisco's binary licence and its H.264 patent cover apply to copies downloaded from Cisco.

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

## Further reading

- [Viewport](viewport.md): how the viewport background is drawn, and why it is built the way it is.
- [OffScreen](offscreen.md): how the offscreen rendering works, and why it is built the way it is.
