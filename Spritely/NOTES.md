# Spritely: notes on updates

A log of every change to Spritely, newest first, for any session that uses
or changes it: in peardox/Sprite3D, where Spritely lives, or in another
repository that builds against the Spritely package. Read it before
relying on how a component behaves, and add an entry with every change to
`Spritely/` (see "Writing an entry" at the end).

Spritely's description, packages and rules are in [README.md](README.md).

---

## 8 November 2026: one projection slot per drawing context (Projection2)

**Changed:** `lib/Spritely.Projection.pas` (`TSpritelyProjection`).
**Confirmed** in Sprite3D (owner, 21:35): grabs now match the view.
**Rebuild:** runtime package Spritely, all platforms. dclSpritely needs no
reinstall (`Spritely.Reg` and the icons are unchanged).

**Why.** Several contexts can draw one Gorilla3D scene in turn. In
Sprite3D the view and the off-screen grab pass each draw with their own
`TContextOpenGLWindows`. `TSpritelyProjection` kept one slot (where FMX
keeps its projection), for the last context it saw. When another context
drew, it forgot the first one's slot without putting FMX's projection
back, so that context still held our oblique matrix. On its next frame
the component found no perspective there, logged "The context's
projection is not a perspective: nothing changed", and gave up. From then
on a stale projection was drawn while the camera kept being refitted:
the view looked wrong, and grabs came out small and off centre.

**What changed.**
- `FSlots`: one slot per context, oldest first, kept while other contexts
  draw, up to `SPRITELY_PROJECTION_MAX_CONTEXTS` (8). Each slot's tracker
  keeps telling FMX's value and ours apart, so each context is always
  drawn from its own FMX projection: the view at the window's size, a
  grab pass at the grab's.
- `SlotFor` finds a context's slot, and drops it if the value there is
  neither ours nor a perspective (a new object at the same address, or
  the camera out of perspective mode), so it is looked for again.
- `FFailedContexts` replaces the single failed context; `Changed` still
  clears it.
- `LiveSlot` replaces `SlotAlive`: the slot in the viewport's present
  context, the only context known to be alive outside a frame. `DropSlot`
  and `Changed` restore FMX's projection only there. A render pass's
  context is written to only from inside its own frame.
- `FindSlot` is now a function returning the new slot. Its log line gives
  the context's address and how many are kept:
  `Projection found in TContextOpenGLWindows $... at +$60 (2 context(s) kept)`.

**For users of the component.** No property or event changed. Programs
that draw the scene through a second context (a render pass, an
off-screen target) now get the projection there too.

---

## 8 November 2026: first used in Sprite3D (Projection1)

**Changed in Spritely:** nothing. Recorded here as the first program
other than ProjectionTest to use `TSpritelyProjection`.

Sprite3D's View, Projection offers Perspective and Orthographic (the
camera's own) and Cavalier, Cabinet, Military and Plan Oblique, drawn by a
`TSpritelyProjection` made in code with `CameraPreset` and `Dolly` off, so
Sprite3D's own camera views keep the angles. It is the
`TSpritelyOrbitalCamera`'s `Projection`, so the camera's fits and
`ProjectToView` follow it.

Learned on the way:
- `TSpritelyOrbitalCamera.Projection` sets the projection's `Focus`, not
  its `Viewport`; set that too.
- With an oblique kind, `FitPointsOnAxis` frames the points exactly but
  leaves the orbit centre where the fit puts it rather than on the given
  line, since a parallel view is sheared about the target plane. Refit
  after turning the camera.
- `ShiftView` is exact for the parallel kinds: they are made at the
  target plane with the perspective's scale there.

---

## 8 November 2026: WinARM64EC (SpritelyMove2)

**Changed:** `packages/Spritely.dproj` (WinARM64EC ticked, with its
property groups) and `tools/gen_packages.py` (WinARM64EC in
`RUNTIME_PLATFORMS`). **Rebuild:** Spritely for WinARM64EC.

Gorilla3D is now installed for WinARM64EC (owner), so the runtime package
builds for it too. The design package stays Win32 and Win64.

---

## 8 November 2026: ProjectionTest and the test models (SpritelyMove2)

**Added:** `ProjectionTest/` (unchanged from SRDelphiFMX but for its
FastMM5 path, now `..\..\FastMM5`), `models/` (`DemoSceneNoWall.glb`,
`DollyHallway.glb`, `uvcube.glb`) and `tools/gen_demo_scene.py` and
`tools/gen_dolly_hallway.py`. **Rebuild:** none.

ProjectionTest finds `models` up to five folders above its executable,
so it uses `Spritely/models`. Run here, `gen_dolly_hallway.py` writes
`DollyHallway.glb` byte for byte; `DemoSceneNoWall.glb` differs only in
its "generator" text, as it does from SRDelphiFMX's own copy.

---

## 8 November 2026: moved from peardox/SRDelphiFMX (SpritelyMove1)

**Added:** `lib/` (`Spritely.OrbitalCamera`, `Spritely.Projection`,
`Spritely.Reg` with its `.dcr`, `icons/`), `packages/` (`Spritely`,
`dclSpritely`), `tools/` (`gen_packages.py`, `gen_icons.py`,
`gen_icon_res.py`) and `README.md`.
**Rebuild:** Spritely for every platform used and always Win32, then
reinstall dclSpritely from here, after removing the one installed from
SRDelphiFMX.

Spritely is owned by peardox/Sprite3D from this date; SRDelphiFMX's copy
is to be removed. The units, `.dcr`, icons and packages were copied byte
for byte. The three generator scripts were cut down to Spritely alone,
and rewrite the same files as SRDelphiFMX's own. Changes Spritely needs
are now made here, not in SRDelphiFMX.

Sprite3D's own `TSprite3DCamera` (unit `Sprite3DCamera`) was replaced by
`TSpritelyOrbitalCamera`, which needed no change. Its camera,
`TSpritelyOrbitalGorillaCamera`, is `TSprite3DCamera` renamed and
extended: with no `Projection` and no `Subject` it behaves exactly as the
old camera did.

---

## Writing an entry

With every change to anything in `Spritely/`, add an entry at the top,
under a rule (`---`), with:

- the date, a short title, and the zip it came in;
- **Changed** or **Added**: the files;
- **Rebuild**: which packages and platforms, or none, matching the
  delivery's `====> REBUILD ... <====` line;
- **Why**, with the evidence (a log line, a test);
- **What changed**, named as in the code, so a search finds it;
- **For users of the component**: anything a program using Spritely must
  do or will notice, or "nothing".

Keep it ASCII, and name no paths, user names or machines.
