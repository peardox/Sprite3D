# Spritely

Spritely is a set of camera components for FireMonkey and Gorilla3D 1.5.3,
installed as a pair of packages and shown on the **Spritely** page of the
palette. Sprite3D uses its orbital camera; other programs can use either
component without Sprite3D.

Spritely came from peardox/SRDelphiFMX (8 November 2026), where it was
built and tested with StereoModel and ProjectionTest. From that date this
repository owns it, ProjectionTest included; the copies in SRDelphiFMX are
to be removed. Paths below
are from this folder, `Spritely/`.

Every change to Spritely is logged, newest first, in [NOTES.md](NOTES.md):
what changed, why, and what a program using the components must do.
Read it before relying on how a component behaves.

## Layout

| Folder | What is in it |
|---|---|
| `lib/` | The units: `Spritely.OrbitalCamera.pas`, `Spritely.Projection.pas`, and `Spritely.Reg.pas` with `Spritely.Reg.dcr` (design time only) |
| `lib/icons/` | The palette icons (`.ico`, and the `.svg` sources in `svg/`) |
| `packages/` | `Spritely` (runtime) and `dclSpritely` (design time) |
| `ProjectionTest/` | The projection's test bed (see [The projection test](#the-projection-test)): `ProjectionTest.dpr` / `.dproj`, the form in `ui/`, the measuring and the test runner in `common/` |
| `models/` | ProjectionTest's models: `DemoSceneNoWall.glb` (its test model), `DollyHallway.glb` (the dolly-zoom test) and `uvcube.glb` (a cube with a UV test texture; the fallback, and the subject of the hallway) |
| `NOTES.md` | The log of updates, newest first |
| `tools/` | `gen_packages.py` (the packages), `gen_icons.py` and `gen_icon_res.py` (the palette icons), `gen_demo_scene.py` and `gen_dolly_hallway.py` (the test models) |

## The components

Both are FireMonkey components and show on the palette only while an FMX
form or frame is designed. Spritely knows nothing of Sprite3D or any other
program: programs require Spritely, never the reverse.

### TSpritelyOrbitalCamera (`lib/Spritely.OrbitalCamera.pas`)

An orbit camera for a `TGorillaViewport`. It is non-visual: drop it on the
form, or create it in code, and set **Viewport**. At run time it builds the
camera in that viewport and makes it the viewport's camera; at design time
it only keeps its settings.

| Property | |
|---|---|
| `Viewport` | The `TGorillaViewport` the camera goes in |
| `Headlight` | True (default): a point light rides on the camera, lighting whatever is in view. False: no light is made; add the scene's lights yourself |
| `Azimuth`, `PolarAngle`, `Roll` | The camera's angles in degrees round the orbit centre. `PolarAngle` is not limited, so the camera can go over the poles |
| `Distance` | From the orbit centre (default 10) |
| `FOV` | Field of view in degrees (default 45) |
| `ProjectionMode` | Perspective (default), orthographic or isometric |
| `OrthoHeight`, `OrthoWidth` | The view's size in orthographic and isometric mode; 0 leaves Gorilla3D's own height, and a width of 0 follows the height |
| `Locked` | While True nothing moves or turns the camera |
| `Subject` | A model the camera may not go inside: the wheel, `Distance`, orbits and angles stop at the face nearest the camera (its bounding box, plus a gap of twice the viewport's near plane) |
| `Projection` | A `TSpritelyProjection` that draws this camera's view: it takes `Distance` as its target plane and moves the camera for the dolly zoom, and the fits and `ProjectToView` follow the lens, shift, rise and parallel views it draws (the camera's `ProjectionMode` must stay perspective) |

Run-time properties: `Camera`, the `TSpritelyOrbitalGorillaCamera` it built
(nil until `Viewport` is set at run time), and `Light`, the headlight (nil
while `Headlight` is False). Everything the camera itself offers, such as
`FitPointsOnAxis`, `ShiftView`, `ProjectToView`, `SaveFraming` and
`RestoreFraming`, is reached through `Camera`.

Methods: `FitToBounds` frames a subject for the current angles, and
`FitToBoundsMax` for every angle (orbit freely afterwards). The subject is
centred in the view and the target (the orbit centre) is put on its
turning axis, the up axis through its centre of rotation, so the camera
turns about the subject's own axis. `FitToBounds` makes the subject as
large as it goes for the current angles; `FitToBoundsMax` frames the ball
round it, centred on that axis halfway up, so no angle takes any of it out
of view. Each sets the target and `Distance`, or the orthographic size,
from the angles, `FOV` and projection as they are, and takes the subject
as:

- a model: `FitToBounds(Model)`, turning about its `RotationCenter`;
- a group of models: `FitToBounds([Model1, Model2])`, the box holding them
  all, turning about its middle;
- a box in the scene's space: `FitToBounds(Box)`, turning about its middle;
- a box in an object's own space, such as part of a model:
  `FitToBounds(Box, Model)`, turning about the model's `RotationCenter`.

A box has no centre of rotation of its own, so the box and group forms
also take one: `FitToBounds(Box, Center)`, `FitToBounds(Box, Model, Center)`
(in the model's coordinates), `FitToBounds([Model1, Model2], Center)`.
All take an optional margin. Also: `SetTargetDepth` (moves the target
nearer or deeper along the line of sight without moving the camera: the
picture is unchanged, the point the camera orbits, and `Distance`, change),
`Orbit`, `Zoom` (works in every projection), `LookAt`, `MoveCenterTo`, and
`MinimumDistance` (how near the camera may come along its present line
without entering `Subject`).

It is a component of its own rather than the camera itself because the
camera hangs under three pivots, one per angle, that are not stored: as a
camera placed on a form it would never be written to the `.fmx`.

The camera began as Sprite3D's own `Sprite3DCamera` unit, renamed
(`TSprite3DCamera` became `TSpritelyOrbitalGorillaCamera`,
`TSprite3DFraming` `TSpritelyOrbitalFraming`, `TQuat` `TSpritelyQuat` and
`TLookAtMode` `TSpritelyLookAtMode`) and grown. Sprite3D now uses it in
place of that unit.

### TSpritelyProjection (`lib/Spritely.Projection.pas`)

A projection for any FireMonkey 3D viewport (`TViewport3D`,
`TGorillaViewport`): FMX and Gorilla3D offer only perspective (with the
camera's own angle of view) and orthographic. FMX keeps the projection it
draws with private (`TContext3D.FProjectionMatrix`); the component finds it
inside the first frame, by its value, and writes its own over it in every
frame, through an empty 3D object first in the viewport. Where several
contexts draw the scene in turn, such as the viewport's own and a render
pass's (an off-screen grab), it keeps where each keeps its projection, so
each is written from its own FMX projection. It is made from
FMX's own each time, so resizes and a new angle of view are followed, and
FMX's goes back when nothing is changed or `Active` is False. It was found
and measured with ProjectionTest (below).

| Property | |
|---|---|
| `Viewport` | The viewport to draw for |
| `Kind` | `pjPerspective` (default), `pjOrthographic`, `pjCavalier` (depth at full length, 45 degrees), `pjCabinet` (half length, 63.4 degrees), `pjMilitary` (full length straight down the picture: with the camera straight above, height is drawn straight up and the plan keeps its shape), `pjPlanOblique` (with the camera straight above and the plan square to the picture, height drawn up and to the left at 45 degrees, full length), `pjTrueIsometric` (orthographic from azimuth 45, inclination 35.264: the three axes equally foreshortened, 120 degrees apart), `pjDimetric` (2:1 dimetric, the "isometric" of pixel art: orthographic from azimuth 45, inclination 30, ground squares drawn twice as wide as high), `pjTrimetric` (orthographic from azimuth 35, inclination 45) or `pjOblique` (`ObliqueAngle`, `ObliqueScale`) |
| `CameraPreset` | True (default): choosing a `Kind` with preset angles turns the `Focus` to them (`PresetAngles`: cavalier and cabinet level at a face, military straight above with the plan turned 45 degrees, plan oblique straight above, and the three orthographic presets above); `ApplyCameraPreset` does it again |
| `FieldOfView` | The lens: vertical field of view in degrees; 0 (default) keeps the camera's own |
| `Dolly` | True (default): a new `FieldOfView` also moves the `Focus` so the target plane keeps its size - the dolly zoom |
| `ShiftX`, `ShiftY` | Lens shift and rise: the picture moved across the lens, in normalised device units (the picture is 2 wide and 2 high), the camera standing still |
| `ObliqueAngle`, `ObliqueScale` | `pjOblique`'s direction (degrees, 0 right, 90 up) and length for depth |
| `Focus` | The camera that gives the target plane's distance and moves for the dolly zoom; set by `TSpritelyOrbitalCamera.Projection` |
| `Distance` | The target plane's distance without a `Focus` |
| `ManageCulling` | True (default): a `TGorillaViewport`'s `FrustumCulling` is off while the projection is changed, as Gorilla3D culls by its own camera's frustum |
| `Active` | False: FMX's own projection |

The parallel views are made from the perspective at the target plane, so
switching keeps the target's size and true shape, and the depth range (and
depth buffer) is kept. `TSpritelyProjectionAccess`, in the same unit, is
the tool underneath: it finds the projection and camera matrices in memory
and changes them, for tests and other uses.

To use both: drop a `TSpritelyOrbitalCamera` and a `TSpritelyProjection`,
set the camera's `Viewport` and its `Projection` to the projection (that
sets the projection's `Focus` and `Viewport`), then set `Kind` and the
rest. Sprite3D's oblique projections (cavalier, cabinet, military and
plan oblique), on its experimental branch `oblique` from 8 November 2026,
use `TSpritelyProjection` made in code, with `CameraPreset` and `Dolly`
off: Sprite3D turns the camera to `PresetAngles` itself. Sprite3D's
`main` does not use it yet.

## Packages and installing

| Package | What it is |
|---|---|
| `packages/Spritely` | Runtime: the `Spritely.*` units in `lib`. It requires `rtl`, `fmx` and Gorilla3D's runtime package (`Gorilla3D_Delphi_13_2_0_Florence`). Win32, Win64, WinARM64EC, macOS (x64, ARM64), Linux64, Android (32 and 64-bit), iOS device and simulator |
| `packages/dclSpritely` | Design time: `lib/Spritely.Reg.pas`, which puts both components on the **Spritely** palette page with their icons. Win32 (the 32-bit IDE) and Win64 |

The runtime package writes its DCUs to Delphi's Dcp folder,
`$(BDSCOMMONDIR)\Dcp\<platform>` (`\Dcp` alone for Win32), beside its
`.dcp`, which is on the IDE's default Library path, so **a program that
uses Spritely needs no search path** and lists no Spritely unit in its
`.dpr`: it names `Spritely.OrbitalCamera` in a `uses` clause and Delphi
finds the DCU.

To install, from `Sprite3DGroup.groupproj` in the repository root:

1. Build **Spritely** for every platform you compile programs for, and
   always for **Win32**, which the 32-bit IDE's design package needs.
   Debug and Release write to the same Dcp folder: the last build wins.
2. Build **dclSpritely** (Win32) and **Install** it (right-click in the
   Projects window). The Spritely page appears on the palette.
3. Build the program: Sprite3d, or ProjectionTest.

If Spritely was installed earlier from SRDelphiFMX, remove that
dclSpritely from Component, Install Packages first, then install this one,
so the IDE loads the package from here.

After a change in `lib`, rebuild Spritely for each platform used before
building a program; after a change to `Spritely.Reg.pas` or the icons,
rebuild and reinstall dclSpritely too. A program failing with *F2613 Unit
'Spritely.OrbitalCamera' not found* has not got Spritely built for the
platform it is compiling for.

### Generating the packages, icons and test models

From this folder:

```
python3 tools/gen_packages.py      the .dpk files (and a missing .dproj)
python3 tools/gen_icons.py         redraw lib/icons (needs Pillow and rsvg-convert)
python3 tools/gen_icon_res.py      package the icons into lib/Spritely.Reg.dcr
python3 tools/gen_demo_scene.py    models/DemoScene.glb and DemoSceneNoWall.glb
python3 tools/gen_dolly_hallway.py models/DollyHallway.glb, from models/uvcube.glb
```

All but `gen_icons.py` need only Python's standard library. The two model
scripts came unchanged from SRDelphiFMX, so their comments still speak of
StereoModel and LenticularDemoFMX, where the scenes were first used. A new component unit in `lib` must be added to `SPRITELY_UNITS`
in `gen_packages.py`, or the script stops; a new component also needs its
icon in `gen_icons.py`'s `ICONS` and its class in `gen_icon_res.py`'s
`SETS`. The `.dpk` files are always rewritten by the script; a `.dproj`
only when missing, as the IDE's re-saved copy then counts (`--force`
overwrites it). Never edit the `.dcr` by hand.

## Rules for the code

- Types `TSpritely...`, units `lib/Spritely.<Name>.pas`, constants
  `SPRITELY_...`. Every component carries
  `[ComponentPlatformsAttribute(SPRITELY_COMPONENT_PLATFORMS)]`, or the
  palette greys it out for Win64.
- Spritely uses nothing outside FireMonkey, the RTL and Gorilla3D. If it
  ever needs settings, it gets a `Spritely.Storage` unit of its own.
- No trademarks in names, UI, logs, comments or docs: the projection kinds
  are named for the projection, never for a game that used it.
- Cross-platform (Windows, macOS, Linux 64-bit, Android, iOS) with `{$IF}`
  alternatives for anything platform-specific.
- `//**` PasDoc on everything, private members too; ASCII sources;
  two-space indent.
- ProjectionTest's own types keep the owner's prefix, `TPeardox...`
  (`TPeardoxProjectionTestForm`), and its constants `PEARDOX_...` or
  `PROJTEST_...`.

## The projection test

`ProjectionTest/ProjectionTest.dproj`, in `Sprite3DGroup.groupproj` (it
needs the **Spritely** package only), asks whether the projection
FireMonkey draws a 3D scene with can be reached and changed from outside
FMX. FMX keeps the projection matrix private and builds it from the
camera's angle of view, and Gorilla3D draws with what FMX gives it, so a
camera cannot supply its own. The test tries it on a lens shift and rise
(the picture moved across the lens, the camera standing still), which
needs an off-axis projection.

Run it: it finds a `models` folder beside the executable or up to five
folders above it, which from `ProjectionTest/<platform>/<config>` is this
folder's `models/`, and loads `DemoSceneNoWall.glb` (or `uvcube.glb`).
**Run test** runs the test. The log is in the panel on the right and in
`ProjectionTest.log` beside the executable (the last run's kept as
`ProjectionTest.prev.log`).

What it does:

1. **Survey.** An empty 3D object, the hook (`TSpritelyRenderHook`), is
   put first in the viewport, so FMX calls it inside each frame once the
   camera and projection are set and before any model is drawn. In one
   frame it reads the context's public projection and camera matrices,
   then looks through the memory of the context, the viewport, the cameras
   and the objects they hold for copies of them (or anything shaped like a
   perspective projection). That needs no RTTI, so it finds private fields
   whether or not FMX and Gorilla3D were compiled with field RTTI. Each
   find is logged with its object, offset and, where RTTI has it, name.
2. **Every way of moving the picture**, each written once, before each
   frame, or inside the frame by the hook: the context's public
   `SetRenderToMatrix`, the public `SetCameraMatrix` with a shear in the
   view matrix, and each projection and camera matrix found in memory.
3. **Measured, not judged by eye.** For each, a reference frame, two
   frames with the change, and one after putting everything back, all read
   with `MakeScreenshot`. The move is measured from the pictures
   (`ProjectionTestMeasure`): a shift of 0.1 of the half-width should move
   everything 96 px right on a 1920 px picture and change nothing else.
   Each line says `SHIFTS AS EXPECTED`, `NO CHANGE`, `SHIFTS THE WRONG
   WAY`, `MOVES, BUT NOT BY THE EXPECTED AMOUNT` or `CHANGES, BUT NOT A
   PLAIN SHIFT`; a way that shifts is then tried for rise.
4. **The result** at the end lists what worked.

Live, `TSpritelyProjection` draws the view, as the orbit camera's
`Projection`. The first row of controls has **Run test**, the **model**
box (every `.glb`, `.gltf`, `.fbx` and `.obj` in the models folder),
**Open...** for any other, **Fit** (frames the model for the present
angles in the projection actually drawn), the **Shift** and **Rise**
sliders, **Centre**, **Active** and **Free Movement** (ticked, the camera
is no longer kept outside the model's box, so it can go inside a model
such as the hallway). The second row chooses the **projection** (the
component turns the camera to the kind's preset angles, if it has them),
the free oblique's **Angle** and **Depth**, the **Lens**, and **Dolly
(keep size)**: with it, a lens change also moves the camera so the target
plane keeps its size - the dolly zoom. Left-drag orbits and the wheel
zooms throughout. While something is changed, the log says every 2 s what
is drawn and in how many frames. The view starts, and **Front** puts it
back, level at the front, framed for every angle.

To see the dolly zoom, choose **DollyHallway.glb**: the UV cube on a long
chequered floor between two rows of pillars, a wall at the far end and
the near end open. From the front view, wheel in on the cube, then drag
Lens from 45 down to 10 and up to 120 with Dolly ticked: the cube keeps
its size while the pillars, the floor and the far wall come forward
(narrow lens) or stretch away (wide). Untick Dolly for a plain zoom.

## Open items

Carried over from SRDelphiFMX, not yet settled: a Windows chime when
ProjectionTest closes (no dialog, cause unknown); "Depth 0" in
ProjectionTest's Front view taken as the target on the model's centre (not
confirmed); `SetTargetDepth` changes a parallel view's size, by design (its
size is the target plane's); the wheel scales `Distance`, so it never
passes the target (a fly or move-forward control would need asking for).
