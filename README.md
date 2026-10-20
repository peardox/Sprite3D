# Sprite3D

Sprite3D is a Delphi FireMonkey application for viewing 3D models from fixed and free camera angles, and for rendering them to images and icons. It is built on [Gorilla3D](https://www.gorilla3d.de/) and is meant as a tool for making sprites from 3D models: load a model, choose a view such as isometric, and grab it as a transparent PNG or a Windows icon.

The code is split so that the 3D parts can be reused: everything in `src/lib` is independent of the application, and `src/ui` holds the forms and the application's own rules.

![Sprite3D showing the sample cube in the isometric view, over the checker that stands for a transparent background](img/ScreenShot.png)

## Features

- **Orbit camera.** Three dials set azimuth, inclination and roll. The camera turns on a chain of single-axis pivots, so it passes over the poles without gimbal lock.
- **Fixed views.** View, Camera offers Isometric, Pixel 2:1, 3/4 View, Head On, Top Down and Side View, or Variable to use the dials. The chosen view, and the dials' angles in Variable, are restored next session.
- **Pan.** View, Camera, Variable also has a Pan box, off by default. Ticked, two sliders move the view along the model's own X and Z axes, up to twice the model's radius either way, for the odd model that should sit off centre. The pan sits on top of the fit and never changes the angles or the distance; it applies in every view, and in grabs and icons, until it is switched off, and the window title says "(panned)" while it is in use. Centre puts it back to 0.
- **Fitting.** Each model is centred and the camera fitted so the model fills the view. With "Fit any angle" checked, the fit holds for every angle, so the dials can never push the model out of view.
- **Perspective or orthographic** projection.
- **Bounding box, axes and grid.** The model's bounding box, its X, Y and Z axes through its centre of rotation, and a far-reaching grid on the model's floor, the lowest point of its own geometry, that fades out with distance. Each can be switched on or off in the View menu, as can "Fit any angle" and "Orthographic".
- **Grab.** File, Grab renders the view off screen at the grab size chosen in File, Settings (256 × 256 pixels unless changed), with the model fitted to fill the image, and saves it as the next of `grab001.png`, `grab002.png` and so on. The background is transparent unless a solid colour or gradient is chosen.
- **Save As Icon.** File, Save As Icon renders the view at each size Windows 10 and 11 use (16, 20, 24, 32, 40, 48, 64 and 256 pixels, 32-bit) and saves them as one `.ico` file. The icon writer is designed so other formats, such as macOS icons, can be added.
- **Background.** File, Background Settings... chooses what is drawn behind the model: None, Transparent (a two-grey checker standing for transparency, with an adjustable square size), Solid, or Gradient (top to bottom, left to right, or either diagonal). Colours can be picked or typed as hex. Grabs and icons follow the choice.
- **Opening files from the system.** When the operating system opens the application with a model, for example a `.glb` or `.gltf` file double-clicked in Explorer or Finder, that model is loaded instead of the default one. This is handled on Windows, macOS, Linux, Android and iOS.
- **File, Settings...** A dialog for:
  - **Open model files.** Offer Sprite3D under Open With for model files and, optionally, make it their default application. Before changing a default, the one in use is recorded; clearing the box puts it back, if that application is still installed, and otherwise just removes Sprite3D's claim. Everything is per user. On Windows a default the user picked in Windows' own dialog can only be changed there, so Settings, Default apps is opened when that happens. On macOS, Open With comes from the app bundle (see below) and only the default can be changed. Android and iOS decide these things when the app is built, so the group is disabled there.
  - **Startup action.** None (no model is loaded), Load default model, or Load last model, which falls back to the default model if the last one has gone. A file the system asks Sprite3D to open always comes first.
  - **Grab size.** The size of every off-screen grab: 8 × 8, 16 × 16, 24 × 24, 32 × 32, 64 × 64, 96 × 96, 128 × 128, 160 × 160, 192 × 192, 256 × 256, 384 × 384 or 512 × 512, or Custom, where width and height are typed separately, each from 8 to 1024 pixels. Kept as `grabWidth` and `grabHeight`. Icons keep the sizes their file format needs. Below it, the grab folder in use is shown with a Reset button, which empties it so the next grab asks for a folder again.
  - **Theme.** Default (FMX's own platform style), Dark, or one of three coloured styles, Aqua Graphite, Ruby Graphite and Golden Graphite, applied at once. Title bars follow the theme where the system allows. See *Themes* below.
  - **Graphics processor**, Windows only: let Windows decide, low power or high power, through `common/GpuPreference.pas`. It takes effect the next time Sprite3D starts.
- **Settings kept between sessions** in `settings.json`: the grab folder, the icon folder, the background, the camera view, the pan, the View menu's on/off items, and the choices in File, Settings.
- **Mobile layout.** On Android and iOS the menus are reached through a hamburger button.

Model formats: glTF (`.gltf`, `.glb`), FBX, OBJ, USD (`.usdc`), Collada (`.dae`), STL and PLY, as Gorilla3D loads them.

## Requirements

- RAD Studio (Delphi) with FireMonkey.
- [Gorilla3D](https://www.gorilla3d.de/) 1.5, installed in the IDE.
- [Neon](https://github.com/paolo-rossi/delphi-neon), the JSON serialisation library, included as a Git submodule.

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

On start-up the application loads `models/uvcube.glb`, a cube with its faces labelled, from the repository's `models` folder. On Windows it looks for `models` in the current folder first, then three levels up, which is the repository root when run from `src/<platform>/<config>`. On macOS the folder is expected in the user's Library folder and on Linux in the home folder.

## Project layout

```
Sprite3D/
|-- Sprite3DGroup.groupproj
|-- README.md
|-- delphi-neon/              Neon JSON library (submodule)
|-- docs/                     generated API help (PasDoc)
|-- models/                   sample model: uvcube.glb
`-- src/
    |-- Sprite3d.dpr, .dproj, .res, Sprite3d_Icon.ico
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
    |   `-- Sprite3DStorage.pas      per-user app folder and JSON settings
    |-- common/               small cross-project helpers
    |   |-- OSPaths.pas              where the program and its assets are
    |   |-- GpuPreference.pas        Windows' per-program GPU preference
    |   `-- DisplayData.pas          display modes (Windows only; not used by the app yet)
    `-- ui/                   the application
        |-- Sprite3dMain.pas, .fmx           main form
        |-- Sprite3DBackgroundForm.pas, .fmx Background Settings dialog
        |-- Sprite3DOrbitalForm.pas, .fmx    Variable camera dialog, with the pan
        |-- Sprite3DSettingsForm.pas, .fmx   Settings dialog
        `-- Sprite3DHelpers.pas              application rules and settings
```

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

## Known issues

- On macOS and iOS, where Gorilla3D renders through Metal, grabs and icons are screenshots of the view as shown, cropped to the grab's shape and scaled: the model is not refitted for them, and they are opaque, with the viewport's own background.
- In orthographic projection the viewport background is not drawn, as Gorilla3D draws it black over the whole scene there. Grabs are not affected.
- Background colours in the viewport show about 1.25 times brighter than chosen. Grabs and icons use the exact colours.
- Android would need intent filters, and iOS document types, added to their manifest and Info.plist for Open With; neither is set up yet.
- The camera view and View menu ticks are saved when the main form is destroyed, which Android and iOS do not always do before ending an application.

## Further reading

- [Viewport](viewport.md): how the viewport background is drawn, and why it is built the way it is.
- [OffScreen](offscreen.md): how the offscreen rendering works, and why it is built the way it is.
