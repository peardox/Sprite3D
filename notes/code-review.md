# Code review, 9 November 2026

A review of the source at `main` `0d0103f`, against the rules in
`CLAUDE.md`. It is partial: the account's usage limit stopped four of the
six reviewers before they reported, so this covers what did come in. The
findings are things to look at, not confirmed defects; each says what
would confirm it.

## What was covered

- `src/ui/Sprite3dMain.pas`, lines 1 to 6500 (start-up, menus, loading,
  grabs, icons, settings, the first half of the view code).
- `Spritely/lib/Spritely.OrbitalCamera.pas` and
  `Spritely/lib/Spritely.Projection.pas`.
- The project files (`.dpr`, `.dproj`, `.groupproj`, the Spritely
  packages), `tools/`, `Spritely/tools/`, `.gitignore`, `.gitmodules`.
- Mechanical checks over every unit: all sources are ASCII; the `.dpr` and
  `.dproj` unit lists agree (38 each); `tools/pasdoc_check.py` reports
  456 undocumented and 74 plain-commented interface items, all in the
  older gaps `CLAUDE.md` describes (down from about 480 and 80 on
  27 October).

## Not yet covered

- `Sprite3dMain.pas` from line 6500: the export and capture state
  machine, abort, Directions, atlas pages, `FSaveTasks`, and the view
  code added on 8 and 9 November (`EnterObliqueView`, `CheckProjection`,
  `PlaceShift`, `ShiftCamera`, `ResetViewSettings`, `FRestoringView`,
  `DialogMouseView`, `OffscreenBeforeGrab`, `HideHelpersForGrab`).
- `src/lib`: `Sprite3DOffscreen`, `Sprite3DSweep`, `Sprite3DAnimCapture`,
  `Sprite3DSpriteSheet`, `Sprite3DResample`, `Sprite3DIconWriter`,
  `Sprite3DBackground`, `Sprite3DAxes`, `Sprite3DGrid` (the reviewer had
  read all nine and was confirming against callers when stopped).
- `src/lib`: `Sprite3DVideo`, `Sprite3DOpenH264`, `Sprite3DBzip2`,
  `Sprite3DLibraryUpdate`, `Sprite3DNativeLibs`, `Sprite3DOpenFiles`,
  `Sprite3DFileAssoc`, `Sprite3DFileSearch`, `Sprite3DStorage`,
  `Sprite3DStyles`, `Sprite3DTitleBar`, and `src/common` (the reviewer
  was checking the FFmpeg records against `src/ffmpeg` when stopped).
- `src/ui`: `Sprite3DHelpers`, `Sprite3DResultsView` and the other forms
  (partly read).

## Findings: Sprite3D

Most serious first. Line numbers are those of `0d0103f`.

1. **Deadlock when a model is requested during a folder scan.**
   `Sprite3dMain.pas` about line 6324: the "load later" guard tests
   `FLoadStage <> lsNone` but not `FScanning`. A model requested after
   Open Directory starts scanning but before `FQueueActive` is set loads
   at once; `RunLoadQueue` then creates a second `TModelLoadForm` and
   overwrites `FLoadDialog` while the first is modal, and `EndLoad` sees
   `FLoadDialogHeld` and never finishes the first dialog, so its
   `ShowModal` never returns. `OpenDirectoryMenuItemClick` guards the
   reverse case (about line 12250). To confirm: open a folder with many
   models, and drop a model on the window while the count is still
   rising.

2. **Pending models stall after a missing file.** About lines 6318 to
   6337: when `SwitchModel` exits because the file is not found, or a
   capture is running, `ReportLoadEnd` never runs, so `ContinueLoading`
   never pops the next of `FPendingModels`. Opening several files at
   once with one missing loads none after it.

3. **The first animation's frame override is never saved.**
   `AnimationListToJson`, about line 4251: `if I > 0 then Count :=
   FrameOverride(...)` skips entry 0. This looks left over from the old
   `(None)` first entry (`OLD_NO_ANIMATION`); entry 0 is now a real
   animation, so a count typed for it is dropped from settings and
   project files.

4. **Project file numbers are applied unchecked.** `LoadProjectFile`,
   about lines 4748 to 4756: `GrabWidth`, `AnimationFps` and
   `AtlasPageSize` go straight from the JSON to the settings. If the
   setters do not clamp, `grab_width: 0` reaches `FitViewportToAspect`'s
   division by `GrabHeight`. `CLAUDE.md` requires every value read from
   outside JSON to be type and range checked. To confirm: read the
   setters in `Sprite3DHelpers.pas` (`GrabWidth` does clamp with
   `EnsureRange`; check the other two).

5. **A grab can be saved to an empty folder.** `GrabMenuItemClick`,
   about line 4846, checks `HasSaveFolder`, but the grab completes a
   frame later and the callback reads `SaveFolder` then. Clearing the
   folder in File, Settings in that frame gives `SaveGrab` an empty
   folder. `FOffscreen.Busy` stops a second grab, not a settings change.
   Narrow, but real.

6. **`ReportMemoryLeaksOnShutdown` is commented out.** `src/Sprite3d.dpr`
   lines 7 to 9 and 98: the comments, the README and `CLAUDE.md` all say
   it is set, and `{$DEFINE REPORT_LEAKS}` is also commented out. Either
   turn it on or correct the three descriptions.

7. **Deployment entries.** `src/Sprite3d.dproj` lines 793 to 845 and
   1453 to 1488 deploy `styles\buildstyles.cmd` to Linux64, OSXARM64
   (under `Contents\Resources\StartUp\`, so `System.StartUpCopy` copies it
   into the user's folders), Win64 and WinARM64EC, and `..\README.md` to
   Android64, Linux64, OSXARM64 and Win64. No entry is
   `<Enabled>false</Enabled>`. The `.rc` is not deployed (it is only a
   `<None Include>`), so `CLAUDE.md`'s note about it was wrong and is
   corrected.

8. **File, Open Model on mobile.** `OpenModelMenuItemClick`, about line
   4836, calls `OpenDialog1.Execute` with no platform condition. The
   hamburger drawer (built from the menu at about line 3144) lists the
   item, and on Android it does nothing. `CLAUDE.md` says such items are
   left out on mobile and the README says so.

9. **`LoadStartupModel`'s `saLastModel` branch** (about lines 3806 to
   3819) exits before the loop that opens the rest of the requested
   files, so project files that failed to load are dropped without a
   message. Minor; the loop is dead for that branch.

10. **`RegisterProjectFiles`'s task** (`FormShow`, about lines 3694 to
    3707) is not in `FSaveTasks`, so on Linux the program can exit while
    `xdg-mime` or `update-desktop-database` is half done. No crash; a
    possibly incomplete registration.

11. **`FreeAndNil(FOpenH264Update)` in `FormDestroy`** (about line 3992):
    confirm that `TSprite3DLibraryUpdate.Cancel` removes its queued
    completion events (`TThread.RemoveQueuedEvents`); if not, the queued
    `Finished` call runs after its owner is freed.

12. **Dead code and drift from the `.fmx`.** `RollDialChange` (about
    line 3645) and `DistanceTrackChange` (about line 5939) handle controls
    that are no longer on the form, and their interface comments (lines
    988 to 994, 1234 to 1241) describe them; `Model3D1` (line 705) is
    documented as unused; the unit's abstract (lines 1 and 2) still says
    "Demo form for the Spritely orbital camera"; `CreditsItem` and
    `LoadCreditsItem` (lines 740 to 743) are named for one thing and
    captioned for another, and the menu tree at lines 213 to 265 omits
    them. The three-quarter and one-quarter view handlers (about lines
    5617 and 5638) call `ApplyProjection` and so fit twice per click,
    under a comment about Military's 45 degrees that no longer matches
    the code.

13. **New fields with plain comments.** `FTwoPass*` (lines 1760 to 1779)
    and `FBenchmark*` (lines 1899 to 1907) use `//`, not `//**`, so the
    older gaps are growing.

14. **`ViewFpsLimit` at start-up.** `ApplyViewFps` runs in `FormCreate`
    before the window has a handle, so `IndexOfForm` gives -1 and the
    primary display is used until the first readout tick re-applies it.
    Works; one extra Debug line at start-up.

## Findings: Spritely

15. **Win32: the memory scan can raise `EInvalidOp`.**
    `Spritely.Projection.pas` lines 959, 1371, 1881: `FindSlot` and
    `ScanObject` read arbitrary object bytes as `Single`. On Win32 Delphi
    loads `Single` through the x87 FPU with the invalid-operation
    exception unmasked, so a signalling-NaN bit pattern (pointers in the
    `$7F80xxxx` to `$7FBFxxxx` range) raises before `IsNan` runs.
    `ScanObject` has a `try/except`; `FindSlot` has none, so the
    exception would escape FMX's `Render`. Win64 uses SSE and does not
    signal on a load, which is where this has been tested. To confirm:
    run ProjectionTest or Sprite3D as Win32 with an oblique on.

16. **Slot eviction at the limit.** Lines 1885 to 1886: at
    `SPRITELY_PROJECTION_MAX_CONTEXTS` the oldest slot is deleted without
    restoring FMX's projection in that context. If it was a live context
    (the viewport's, or the grab pass), the next `FindSlot` there reads
    the oblique matrix, logs "The context's projection is not a
    perspective" and puts the context in `FFailedContexts`: the
    Projection2 symptom again. Needs more than eight distinct context
    objects; a grab pass that re-makes its context on each size change
    could get there.

17. **`FFailedContexts` never heals.** Lines 1967 to 1975 and 2117: it is
    cleared only by `Changed`, so a context skipped once (the camera was
    orthographic at the time, say) stays skipped until a projection
    property changes, and it holds raw `TContext3D` pointers of possibly
    freed contexts, so a new context at a dead address is skipped too.
    Sprite3D is safe today only because `SetKind` has no
    `Value = FKind` short cut and always calls `Changed`.

18. **`Destroy` does not restore `FrustumCulling`** (lines 1779 to 1791);
    `SetViewport` does (line 2146). Harmless in Sprite3D, where the
    projection is freed with the form.

19. **`ShiftView` ignores the projection's lens.**
    `Spritely.OrbitalCamera.pas` lines 2649 to 2663 use the camera's own
    `m11`/`m22`, while `FitCorners` and `ProjectToView` go through
    `ShapeFor`. With `FieldOfView <> 0` on the projection a slide of N
    pixels is off by the lens factor. Not visible yet: Sprite3D only
    slides in Gorilla's orthographic mode.

20. **Orthographic fits with `OrthoHeight` 0.** Lines 2475 to 2481 and
    3183 multiply Gorilla's `OrthoHeight`; if its default is 0 ("use the
    viewport"), every fit and wheel zoom in orthographic and isometric
    mode changes nothing. Confirm from `TGorillaCamera.OrthoHeight`'s
    default.

21. **Preset angles.** `Spritely.Projection.pas` lines 2194 to 2231 hand
    `PresetAngles` to the Focus as the camera's azimuth, which runs the
    other way from Sprite3D's; the two routes give mirror images for
    asymmetric scenes. Only matters while both are in use (ProjectionTest
    with `CameraPreset`, Sprite3D without).

22. **Rules.** `TSpritelyProjection` carries
    `[ComponentPlatformsAttribute(pidAllPlatforms)]` (line 661), not
    `SPRITELY_COMPONENT_PLATFORMS`, because the constant lives in
    `Spritely.OrbitalCamera.pas` (line 322), which uses `Spritely.Projection`;
    the constant wants a small shared unit. `Spritely.Projection.pas` has
    no `RegisterFmxClasses([TSpritelyProjection])`, while
    `Spritely.OrbitalCamera.pas` registers its two (line 3609).
    Implementation-only helpers in `Spritely.OrbitalCamera.pas` (lines
    1756 to 1794, 3210 to 3213: `EPS`, `NEAR_CLEARANCE`, `FAR_PLANE`,
    `TBoxCorners`, `GetBoxCorners`, `IsValidBox`, `NearestAngle`,
    `ModelsBox`) have `{ }` or `//` comments where the rule says `//**`.

23. **Packages.** `Spritely/packages/Spritely.dpk` is the IDE's re-saved
    form (an `IMPLICITBUILDING` block, no "Written by
    tools/gen_packages.py" line), so the next run of the script changes
    it. `Spritely.dproj` lacks the `Base_OSX64`, `Base_OSXARM64`,
    `Base_Linux64`, `Base_iOSDevice64` and `Base_iOSSimARM64` groups that
    `dclSpritely.dproj` has. `gen_packages.py`'s `ALL_PLATFORMS` lacks
    `Win64x`, which the IDE added. The platform tick lists otherwise
    agree with the script.

Checked and found sound: the quaternion code (`ApplyOrientation`,
`ShortestArc`, `Rotate`, `FmxSign`), fits with degenerate boxes (zero
size, NaN rejected by `IsValidBox`), the orthographic and oblique
matrices (depth 0 to 1, row-vector shear order), `ShiftProjection` in
clip space, `SlotFor`'s stale-slot handling, field order (E2169), no
Sprite3D or Neon dependency in `Spritely/lib`, and the camera, light and
viewport notification order.

## Findings: tools and repository

24. **`tools/pasdoc_check.py`.** Line 217 treats any line ending in `}`
    as a comment, so a `{ }` block satisfies the check though PasDoc's
    `--staronly` ignores it. `declared_names` (line 80) counts every
    `x = y` comparison and every local `v: T` as a declaration, so a
    `@link` to almost anything passes. Blank lines between fields do not
    reset the shared-comment rule (line 173), and a field list broken
    over two lines is reported undocumented. Attributes are skipped only
    when on one line. Implementation items are not checked, as its
    docstring says.

25. **Tracked generated files.** `src/styles/Sprite3DThemes.res` is
    rewritten by every pre-build, and `src/Sprite3d.deployproj` is
    machine-specific; both are tracked. Nothing ignored is tracked and
    no tracked file matches an ignore pattern.

26. **`Sprite3d.dproj`** has Android (32-bit) disabled (line 2453) while
    `CLAUDE.md` lists it as a target and the Spritely package has it
    enabled. `buildstyles.cmd`'s failure handling is sound.

## Next

Resume the four stopped reviewers (their reading is saved) and add their
findings here, then take the "Worth fixing" items (1 to 7) in order.
