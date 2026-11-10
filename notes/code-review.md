# Code review, 9 November 2026

**Fixes applied** (Fixes1, 9 November, 22:45): items 1, 2, 3, 4 and 6;
(Fixes2, 22:55): item 7; (Cisco1, 10 November): item 8. Items 5 and 50 are withdrawn. Item 9
is in part met, as the list's addresses are now all https. The rest are open.

A review of the source at `main` `0d0103f`, against the rules in
`CLAUDE.md`, by six reviewers each reading whole units, collated and
spot-checked by a seventh. Every unit was covered. Line numbers are
those of `0d0103f`.

Each finding says what is suspected and, where it is not confirmed, what
would confirm it. "Confirmed" means the collator read the lines and the
code does what the finding says; it does not mean the effect was seen
running. Many first suspicions withdrew on inspection; what withdrew is
listed at the end of each section so it is not raised again.

Mechanical checks over every unit: all sources are ASCII; the `.dpr` and
`.dproj` unit lists agree (38 each); `tools/pasdoc_check.py` reports 456
undocumented and 74 plain-commented interface items, all in the older
gaps `CLAUDE.md` describes (down from about 480 and 80 on 27 October);
no `src/lib` or `src/common` unit uses `src/ui`; no form has a
`StyleBook`; the four View Show items no longer carry `IsChecked` in
`Sprite3dMain.fmx`, and the only ticks left (`HeadlightItem`,
`PerspectiveItem`) match the constructor.

## Fix first

In order. Items 1 to 4 are confirmed; 6 to 9 are likely; 5 was wrong.

1. **Fixed.** **Quitting during an export hangs the desktop.** `Sprite3dMain.pas`
   9875 to 9886, `FinishBatch`: the `FQuitConfirmed` branch clears the
   batch state and exits without `ReportBatch`, so `FExportDialog.Finish`
   is never called. The progress dialog's `FormCloseQuery` refuses to
   close until `Finish`, so its `ShowModal` never returns and the main
   form's `Close` from `QuitAfterConfirm` runs inside that modal loop.
   `FormCloseQuery` (3932 to 3943) sets `FBatchAborted` but does not
   cancel `FCapture`, so the capture's `Done` is what gets here. To see
   it: start a strip export, close the main window, answer Yes.

2. **Fixed.** **A finished MP4 can have `av_write_trailer` called twice.**
   `Sprite3DVideo.pas` 1055 to 1059 and 1182 to 1186: `Check(... av_write_trailer ...)`
   then `HeaderWritten := False`. If `Check` raises, the flag is still
   True and the `finally` calls the trailer again on a context FFmpeg
   has already torn down. Clear the flag before the call.

3. **Fixed** (by removing the dead lines and correcting both
   descriptions, so the behaviour is unchanged: the assets folder on
   every platform; say if the old per-platform folders were wanted).
   **`DefaultModelDir` is dead above its last line.** `Sprite3DHelpers.pas`
   2090 to 2105: the `{$IF}` block (library path on macOS, home on Linux)
   and the Windows `DirectoryExists('models')` check are all overwritten
   by `Result := GetAssetsPath('../../../')`. The interface comment
   (1160 to 1164) and `Sprite3dMain.pas` 933 to 935 describe what no
   longer happens; on macOS the default is the bundle's Resources folder.

4. **Fixed.** **Deadlock when a model is requested during a folder scan.**
   `Sprite3dMain.pas` about 6324: the "load later" guard tests
   `FLoadStage <> lsNone` but not `FScanning`. A model dropped after Open
   Directory starts scanning but before `FQueueActive` is set loads at
   once; `RunLoadQueue` (12400) creates a second `TModelLoadForm` over
   `FLoadDialog` while the first is modal; `EndLoad` (6669) then sees
   `FLoadDialogHeld` and never finishes the first dialog, so its
   `ShowModal` never returns. `OpenDirectoryMenuItemClick` guards the
   reverse case (about 12250).

5. **Withdrawn.** **GIF LZW code widening is one code late.** `Sprite3DSpriteSheet.pas`
   1291 and 1310: the encoder widens when `Next > (1 shl FSize)`; giflib's
   encoder widens when its running code `>= 1 shl bits`, one code
   earlier. If this is right, decoders read one code at the old width
   that was written at the new, and the picture breaks after about 254
   codes. Wrong: giflib's check runs inside its output routine before
   it inserts the new entry, so its `>=` on the count before the insert
   is the same moment as this code's `>` on the count after it. The END
   code (1307 to 1312) matches giflib too. The encoder is right.

6. **Fixed** (`ContinueLoading` on both exits). **Pending models stall after a missing file.** `Sprite3dMain.pas`
   6318 to 6337: when `SwitchModel` exits because the file is not found,
   or a capture is running, `ReportLoadEnd` never runs, so
   `ContinueLoading` never pops the next of `FPendingModels`. Opening
   several files with one missing loads none after it.

7. **Fixed.** **The first animation's frame override is never saved.**
   `AnimationListToJson`, about 4251: `if I > 0 then Count :=
   FrameOverride(...)` skips entry 0, a leftover from the old `(None)`
   first entry (`OLD_NO_ANIMATION`, 2849). A count typed for the first
   animation is dropped from settings and project files.

8. **The OpenH264 downloader cannot replace a same-named loaded DLL on
   Windows, and retries every start.** `Sprite3DLibraryUpdate.pas` 727
   to 729: `TFile.Delete(Target)` on the DLL `OpenH264Available` loaded
   at start-up fails with a sharing violation, the `except` at 741
   reports "could not be saved", `installed.json` keeps the old URL, and
   the next start downloads the 64 MB again. This is exactly what
   pointing `openh264.json` at Cisco's downloads (same file names, new
   URLs) would trigger. A versioned or URL-derived file name, or a
   deferred swap, breaks the loop. *Fixed (Cisco1): each copy's name
   carries a hash of its address (`InstalledFileName`).*

9. **The downloader trusts what it loads.** `Sprite3DLibraryUpdate.pas`
   306, 591, 721: `http` is accepted alongside `https`, redirects are
   followed (so https can be downgraded), and the only check before
   `TFile.Move` is the `MZ`/ELF/Mach-O magic. Anyone who can alter the
   list or the transfer gets a library loaded by `LoadLibraryEx` on the
   next `RecheckH264`. Https only, and a `sha256` in the list checked
   before the move, would close it. *In part: the list's addresses are
   all Cisco's https ones since 10 November; the client still accepts
   http and checks no hash.*

## Sprite3dMain.pas

10. **Aborting during atlas page saving misreports.** 10457 to 10484:
    `AbortButtonClick` with `FAtlasSaving` clears `FAtlasPending` and
    `FAtlasParts` while the worker runs; `FinishAtlas` then iterates
    empty lists, `FBatchSaved` is not counted for pages that were
    written, and `ReportBatch` says "Exported 0 of N" for files on disk.

11. **Project file numbers are applied unchecked.** `LoadProjectFile`,
    4748 to 4756: `GrabWidth`, `AnimationFps`, `AtlasPageSize` go
    straight to the settings. `GrabWidth`'s setter clamps with
    `EnsureRange`; check the other two. `CLAUDE.md` requires range
    checks on every value from outside JSON.

12. **A grab can be saved to an empty folder.** 4846: `HasSaveFolder` is
    checked, but the grab completes a frame later and the callback reads
    `SaveFolder` then. Clearing the folder in File, Settings within that
    frame gives `SaveGrab` an empty folder. Narrow.

13. **`FAppliedPan` is zeroed by assignment in three places** (5739,
    4920, 8426) rather than through `TakeOffSlide`, relying on a later
    `RestoreFraming` to make the orbit centre and the record agree. No
    reachable fault was constructed; the sequence to try is orthographic,
    shift on, Mouse View drag, then Cancel in Variable's dialog
    (`RestoreCamera` to `ApplyPan` to `PlaceShift` to `TakeOffSlide`).

14. **File, Open Model on mobile.** 4836: `OpenDialog1.Execute` with no
    platform condition; the drawer (3144) lists the item and on Android
    it does nothing. `CLAUDE.md` says leave such items out there and say
    so in the README.

15. **`LoadStartupModel`'s `saLastModel` branch** (3806 to 3819) exits
    before the loop that opens the rest of the requested files, so
    project files that failed to load are dropped silently. The loop is
    dead for that branch.

16. **`RegisterProjectFiles`'s task** (`FormShow`, 3694 to 3707) is not in
    `FSaveTasks`, so on Linux the program can exit while `xdg-mime` or
    `update-desktop-database` is half done.

17. **`StartCapture` returning False mid-batch** (9815 to 9857) logs one
    error per direction of the same entry, as `FDirFrames` is not
    cleared and the loop tries every direction. Noise only.

18. **Benchmark paths bypass `OSFriendlyPath`**: 11140 to 11143, 11199 to
    11204, 11274 to 11275, 11362. Debug only; the rule has no exemption.

19. **Dead code and drift from the `.fmx`.** `RollDialChange` (3645) and
    `DistanceTrackChange` (5939) handle controls no longer on the form,
    with interface comments (988 to 994, 1234 to 1241) describing them;
    `Model3D1` (705) is documented as unused; the unit abstract (lines 1
    and 2) still says "Demo form for the Spritely orbital camera";
    `CreditsItem` and `LoadCreditsItem` (740 to 743) are named for one
    thing and captioned another, and the menu tree at 213 to 265 omits
    them; the one-quarter and three-quarter handlers (5617, 5638) call
    `ApplyProjection` and so fit twice per click, under a comment about
    Military's 45 degrees the code no longer matches; `FBatchCaptureMs`
    (1890) is set to -1 and never timed, so `ReportBatch`'s "capturing /
    making pages" breakdown is dead.

20. **New fields with plain comments**: `FTwoPass*` (1760 to 1779),
    `FBenchmark*` (1899 to 1907), and many private methods in the second
    half (`Capturing` 8137, `StartCapture` 8237, `SaveAtlasPage` 10206,
    `SaveSheet` 12587, `ApplyNameClash` 12186). The older gaps are
    growing.

21. Minor: `ApplyViewFps` runs in `FormCreate` before the window has a
    handle, so the primary display is used until the first readout tick
    (one extra Debug line); the Mouse View readout is not updated while
    the wheel drives Variable's dialog (7439); `AnimationItemDblClick`
    (7787 to 7800) reads label positions that are 0 before first layout,
    so the first double-click anywhere on a row opens the editor.

Checked and sound: worker tasks touch pure data and hand back through
`TThread.Queue` with `MainFormGone` guards; loop variables are copied
before capture; `SaveAtlasPages` shares its arrays safely through
refcounting; the save-task chain serialises captures; `TakeOffSlide` and
`PutOnSlide` around a mouse zoom are consistent; `FinishBatch`'s pass 1
and pass 2 ordering; `CopyItem` copies every property the `.fmx` uses;
`FormDestroy`'s `WaitForAll` cannot deadlock.

## Rendering and export (src/lib)

22. **Overscan retry learns an unscaled size.** `Sprite3DOffscreen.pas`
    1661, 1711, `RetryAfter`: the failed size is `Max(W, H) * FScan`
    without `FPixelScale`, while `DirectOverscan` divides `TargetLimit` by
    a size that includes it. On a 2x display the learned limit is half
    what it should be and overscan is cut more than needed. Confirm with
    a scaled display and a drawing that fails: `OnOverscanReduced` would
    report half the texture that failed.

23. **`PlanAtlasPages` can drop a full page silently.**
    `Sprite3DSpriteSheet.pas` 1551 to 1553, 1573: `ClosePage` drops the
    page if `SizeAtlasPage` returns False. `Capacity` is computed from
    `AMaxSize`, so with power-of-2 pages and a non-power-of-2 `AMaxSize`
    a full page fits no page and vanishes without error. Safe today only
    if the UI's page sizes are all powers of 2; the drop should raise.

24. **`TSprite3DFrameCapture.Cancel` leak window on macOS and iOS.**
    `Sprite3DAnimCapture.pas` 827, 921: `Cancel` frees the capture only
    when the offscreen is idle and `FSettleTime <= 0`; with settle time
    70 it trusts a pending step to free it, but if `Cancel` comes when no
    step is pending (from inside `FOnProgress`, after a grab is delivered
    and before the next `QueueGrab`) nothing frees it. The condition
    should track whether a step is pending, not the platform constant.
    Also confirm every `FOnDone` handler nils `FCapture` (8477 does).

25. **`FloorLevel` mixes spaces.** `Sprite3DGrid.pas` 469: a scene-space
    difference is compared with `LEVEL_EPS` times a model-space extent,
    so a model scaled by 0.001 trips the "level" test and picks the wrong
    floor. Try a model with `Scale` 0.001 and `RotationAngle.X` 180.

26. **`SaveToFile` deletes the wrong path.** `Sprite3DIconWriter.pas`
    304: `DeleteFile(AFileName)` on the unconverted name while the file
    was written at `OSFriendlyPath(AFileName)`; where the two differ a
    half-written `.ico` stays, against the comment above it.

27. **Integer products on very large targets.** `Sprite3DOffscreen.pas`
    2117, 2144 (`ReadW * ReadH * 4`, and the `Single` buffer at 4 bytes
    each), 967, 260; `Sprite3DSpriteSheet.pas` 755 and 965 (`RowBytes` is
    `NativeInt`, 32-bit on Win32 and Android 32); `Sprite3DResample.pas`
    269, 272; `QuantizeFrame` 1068. All hold today because `TargetLimit`
    and the page sizes bound them; an `Int64` cast or an explicit check
    against the texture size would make them safe, and the "under about
    1 GB" note in Offscreen does not count the resampler's `Single`
    buffer.

28. **`PngEntry` relies on FMX's default stream codec being PNG**
    (`Sprite3DIconWriter.pas` 400); `TBitmapCodecManager.SaveToStream`
    with `'.png'` pins it.

29. **GIF disposal** (`Sprite3DSpriteSheet.pas` 1383): disposal 2 with
    background index 0 and no global table. Browsers treat it as clear
    to transparent; some older viewers paint local entry 0, an opaque
    colour, so frames flash there. Risk, not bug.

30. **`SyncFrame` reparents during `Render`** (`Sprite3DAxes.pas` 445 to
    456, `Sprite3DGrid.pas` 481 to 492) while the parent's children are
    being iterated; `Sprite3DSweep.pas` 1766 deliberately avoids this.
    Only fires if the model is reparented after the helper is built,
    which Sprite3D does not do.

31. Minor: `ShowFrame` (`Sprite3DAnimCapture.pas` 689) can show pose 0
    for the last frame of a non-cyclic animation, which the unit's doc
    admits; `System.RTLConsts` in `Sprite3DSweep.pas` 864 is unused;
    `ForceDirectories` in `Sprite3DIconWriter.pas` 294 is outside a lock
    (main thread only by its own doc, but it is a library routine).

Checked and sound: gradient row direction, the `PixelsToBitmap` fallback
packing, jitter accumulation and the alpha clamp, `GrabSizes` and
`TGrabSizesJob.Finish` ordering, the median-cut split and comparer, the
checker `RowKey` with non-integer sides, scanline `Move`, `UnionBox`,
the measurer's nil `AnimationManager` and start/stop ordering,
`CombinedModelsSweptVolume`'s pivots, the ICO 256 byte, `DrawOnTop`'s
z-test restore.

## Video, network and system (src/lib, src/common)

The hand-declared FFmpeg 8 ABI was checked field by field against
`src/ffmpeg` (`libversion.inc`: avutil 60, avcodec 62, avformat 62;
`AVCodecContext` to `global_quality`, `AVFrame` to `pts`, `AVPacket` to
`duration`, `AVCodecParameters` to `height`, `AVStream` to
`avg_frame_rate`, `AVOutputFormat` to `flags`, `AVFormatContext` to
`pb`, `AVChannelLayout`): all match on 32 and 64 bit. The OpenH264
records match from memory. The bzip2 decoder is bounds-checked and
CRC-verified throughout (284 to 293, 422, 430, 447, 454, 504, 555).

32. **`Cancel` can run the completion into a dying form, and can block.**
    `Sprite3DLibraryUpdate.pas` 851 to 854: `Terminate; WaitFor;
    RemoveQueuedEvents`. `WaitFor` on the main thread services the queue,
    so a `Finished` queued just after the `Terminated` check (772) runs
    inside `WaitFor`, before `RemoveQueuedEvents`, and `FOnDone` writes to
    `DebugMemo` during `FreeAndNil(FOpenH264Update)` in `FormDestroy`
    (`Sprite3dMain.pas` 3992). `ReceiveData` only sees `Terminated` when
    bytes arrive, so a stalled connection holds `WaitFor` up to the 15 s
    and 60 s timeouts at close, and `Bzip2DecompressStream` never checks
    `Terminated`.

33. **`LoadApi` never frees modules and can mix folders.**
    `Sprite3DVideo.pas` 641 to 658, 706: when `avutil` loads from one
    folder and `avcodec` fails, the loop moves on without `FreeLibrary`;
    the version check also leaves handles open; there is no
    `CloseLibrary` in the unit. On Windows the next folder's `avcodec` may
    bind to the first folder's `avutil`.

34. **Unguarded globals between the main thread and export workers.**
    `Sprite3DOpenH264.pas` 396 to 427, 440 to 446: `OpenH264Retry` (main
    thread, from the download callback) resets `Tried` and calls
    `OpenH264Available`, while `SaveMp4Video` on a `TTask`
    (`Sprite3dMain.pas` 12730) calls `H264Available` into the same
    routine, which writes `Status`, `Loaded`, `LayerSize`,
    `CreateEncoder`. Two threads assigning the `Status` string is a
    refcount race; two `TryLibrary` calls load the DLL twice. Narrow
    window, at exactly the moment an export is likely running.

35. **Writes that matter are not atomic.** `Sprite3DFileAssoc.pas` 840
    rewrites the user's whole `~/.config/mimeapps.list` in place (a
    crash loses every application's defaults); `Sprite3DLibraryUpdate.pas`
    737 writes `installed.json` in place. `Sprite3DStorage.pas` 181 to
    183, the pattern `CLAUDE.md` cites as the model, does `Delete` then
    `Move`, leaving a window with no file; `MoveFileEx(MOVEFILE_REPLACE_EXISTING)`
    or `rename` is the truly atomic form.

36. **`InstalledUrl` is emptied after a successful download**
    (`Sprite3DLibraryUpdate.pas` 869) though documented (191) as the
    address `CurrentLibrary` came from; the thread knows `Choice.Url`
    and does not pass it back.

37. **`Bzip2Decompress` has no output bound** (`Sprite3DBzip2.pas` 569 to
    588): with `ATarget = nil` the `AMaxSize` check at 546 never runs, and
    RUNA/RUNB plus the final RLE lets a few hundred bytes expand to about
    45 MB a block. The program only calls the bounded
    `Bzip2DecompressStream`, so this is an exposed-API risk.

38. **The OpenH264 2.6 layer-size switch** (`Sprite3DOpenH264.pas` 227 to
    231, 383 to 386) rests on `rPsnr[3]` first shipping in exactly 2.6.0.
    The 40/56-byte arithmetic is right; the boundary was not checked
    offline. Confirm against `codec_app_def.h` history. Everything else
    in that ABI (`SEncParamBase`, `SSourcePicture`, the vtable order with
    the destructor last, enum values) matched.

39. **Refresh rates matched to displays by assumed order**
    (`DisplayData.pas` 453 to 461, macOS and Android): the N-th non-main
    CoreGraphics display is paired with the N-th non-primary
    `Screen.Displays[I]`; nothing guarantees the same order with three
    monitors, so the frame-rate cap can be another display's. Comparing
    `CGDisplayBounds` would make it exact.

40. Minor: `Need(Api.av_packet_unref, ...)` (`Sprite3DVideo.pas` 687) is
    required but never called, so its absence would disable video for
    nothing; `Sprite3DTitleBar.pas` 336 to 342 has a dead `else if`;
    `OSPaths.pas` 303 has `ShowMesage('Unsupported OS')` in an unreachable
    `{$ELSE}`, misspelt and without `FMX.Dialogs` in `uses`;
    `Sprite3DOpenFiles.pas` 201 to 206 drops arguments beginning `-` (or
    `/` on Windows) even when they name an existing file, and 582
    `CopyContentToCache` never deletes what it copies, so Android's
    `cache/opened/` grows; `Sprite3DFileAssoc.pas` 784 to 786 applies
    only one of the two escapings the Desktop Entry spec needs for
    `Exec=`, 924 and 1002 to 1005 skip `OSFriendlyPath` in
    `IsRegistered`/`Unregister` where `Register` applies it, and 584 and
    695 create `HKCU\Software\Classes\.glb` keys that `RestoreDefaults`
    never removes; `Sprite3DStyles.pas` 71 and 112 build paths with no
    `OSFriendlyPath`; `Sprite3DFileSearch.pas` 133 is O(n squared) with
    `AFiles.Contains` inside the walk.

Checked and sound: WM_COPYDATA bounds the string by `cbData` and checks
`dwData` (`Sprite3DOpenFiles.pas` 267 to 270); the mutex is created
non-owning, `GetLastError` read at once, both handles closed in
`finalization`; `objc_msgSend` declared per call with exact types and
`BOOL` read as a byte (`Sprite3DTitleBar.pas` 284 to 291); YUV is BT.601
limited range with correct rounding and odd sizes padded consistently
(`Sprite3DVideo.pas` 847 to 908); `ERROR_AGAIN` per platform; codec IDs
and flags; `GpuPreference` writes HKCU only with `KEY_WOW64_64KEY`; EDID
offsets; registry work under HKCU only, `HKEY_CLASSES_ROOT` and
`UserChoice` read only, `DeleteKey` recursive, the backup recording the
first non-own default.

## Forms, Helpers and the Results tab (src/ui)

Settings serialisation is sound: every published property has a row in
the README's table and vice versa (`backgroundSpec`, `themeKind`,
`projectionKind`, `debugSwitch` are `public`, so not serialised,
correctly, since `SetVisibility([mvPublished])` at
`Sprite3DStorage.pas` 143); every default is set in the constructor;
setters clamp hand-edited values.

41. **The program's own JSON is read with `as` and `GetValue<T>`.**
    `Sprite3DHelpers.pas` 2338, 2374 to 2379 (`LoadAnimationBoundsCache`):
    wrong types raise and are swallowed by the outer `except` with no
    Debug line; 2359 accepts non-string names. `Sprite3DResultsView.pas`
    617 to 620 (`ReadMetadataFile`): an `image.directions` with no numeric
    entries falls back to `[0.0]` and silently drops every frame with
    `direction > 0` (658) while reporting the file used; `sprite_size`
    has no upper bound, so a hostile value reaches `TBitmap.Create` at
    1304. The rule is type and range checks on every value from outside.

42. **The bounds cache is never checked against its model.**
    `SaveAnimationBoundsCache` (2417) writes `model` as an absolute path
    without `OSFriendlyPath`; the loader (2344 to 2370) checks only
    `version` and `names`, so a model renamed over another with the same
    animation names reuses stale bounds. 2350 also reads the file
    without `OSFriendlyPath`.

43. **`DirectionsFromJson`** (1974 to 1976): `TryStrToInt` on a number
    written `1.0` fails, the position becomes 0, then -1 is added and the
    whole file is rejected as "must hold every position from 1 to N",
    blaming the wrong thing.

44. **The Results tab's edge seek** (`Sprite3DResultsView.pas` 1531, 1587):
    when the frame showing is past every match on the chosen side,
    Previous goes to the last match, Next to the next side's first; with
    zero matches on the side, both change side. Consistent, but the
    drop-down then changes side on its own, undocumented. `Key()` shifts
    into 20-bit fields without masking (unreachable sizes).

45. **Plain strings from `settings.json` are not validated** (`FExportKind
    := 'strip'` 1649, `FOpenDirectorySpec := '*.glb'` 1657): a hand-edited
    `exportKind` of `"foo"` reaches the main form's consumers unchecked;
    `DirectionOrderList` (1674 to 1679) silently discards a saved order
    that no longer fits the count. Confirm the `ExportKind` consumers.

46. **`DegreesText`** (2087): `Round(ADegrees) mod 360` is negative for
    negative input, which `Sprite3DOrbitalForm.pas` 498 relies on for a
    signed readout; the name does not say so, and `Format('%3d')` on
    359.6 gives 360. Fragile for new callers.

47. **Orbital dial handlers ignore `FUpdating`** (`Sprite3DOrbitalForm.pas`
    367 to 372): `ShowSpec` works only because it copies `Spec` first and
    restores it (444 to 445, 464), measuring text three times on the way;
    a new handler that forgets the pattern loses precision through the
    dial's float.

48. **Leftovers.** `TOrbitalSettingsForm.AzimuthOnly` (242 to 250, 276,
    477 to 484) is unused (the only reference is a comment at
    `Sprite3dMain.pas` 5461); `src/Sprite3d.dpr` 118 still auto-creates a
    global `OrbitalSettingsForm` that nothing references while the main
    form makes its own (5448), so an unused form lives for the session;
    `AutoIconFileName`'s `Number := 1` (2459) is dead if the callee
    ignores the input.

49. Minor: `ConfirmOverscan`'s warning form (`Sprite3DAnimationForm.pas`
    423, 473) is owned, never freed explicitly, so on Android each repeat
    adds a form until the dialog closes; `Sprite3DDirectionsForm.pas` 569
    and 608 store `ExtractFileDir(Dialog.FileName)` into
    `directionsFolder` without `OSFriendlyPath` (the Background dialog's
    image path was not re-checked for the same).

## Spritely

50. **Withdrawn.** **Win32: the memory scan can raise `EInvalidOp`.**
    `Spritely.Projection.pas` 959, 1371, 1881: `FindSlot` and
    `ScanObject` read arbitrary object bytes as `Single`. Win32 Delphi
    loads `Single` through the x87 FPU with the invalid-operation
    exception unmasked, so a signalling-NaN pattern (pointers in
    `$7F80xxxx` to `$7FBFxxxx`) raises before `IsNan` runs. `ScanObject`
    has a `try/except`; `FindSlot` has none, so it would escape FMX's
    `Render`. Win64's SSE does not signal, which is where this has been
    tested. Withdrawn: Win32 is built only for the design-time packages
    (the IDE is 32-bit) and nothing is released there, and the projection
    installs no hook under `csDesigning` (1833, 2108), so the scan never
    runs on Win32 at all.

51. **Slot eviction at the limit** (1885 to 1886): at
    `SPRITELY_PROJECTION_MAX_CONTEXTS` the oldest slot is deleted without
    restoring FMX's projection there. If it was live, the next
    `FindSlot` reads the oblique, logs "not a perspective" and puts the
    context in `FFailedContexts`: the Projection2 symptom again. Needs
    more than eight distinct context objects; a grab pass that re-makes
    its context on each size change could get there.

52. **`FFailedContexts` never heals** (1967 to 1975, 2117): cleared only
    by `Changed`, so a context skipped once stays skipped until a
    projection property changes, and it holds raw `TContext3D` pointers
    of possibly freed contexts. Sprite3D is safe today only because
    `SetKind` has no `Value = FKind` short cut.

53. **`Destroy` does not restore `FrustumCulling`** (1779 to 1791);
    `SetViewport` does (2146). Harmless while the projection dies with
    the form.

54. **`ShiftView` ignores the projection's lens**
    (`Spritely.OrbitalCamera.pas` 2649 to 2663): it uses the camera's own
    `m11`/`m22` where `FitCorners` and `ProjectToView` go through
    `ShapeFor`; with `FieldOfView <> 0` a slide of N pixels is off by the
    lens factor. Not visible yet (Sprite3D slides only in Gorilla's
    orthographic mode).

55. **Orthographic fits with `OrthoHeight` 0** (2475 to 2481, 3183)
    multiply Gorilla's value; if its default is 0 ("use the viewport"),
    every fit and wheel zoom in orthographic mode does nothing. Confirm
    from `TGorillaCamera.OrthoHeight`'s default.

56. **Preset angles** (`Spritely.Projection.pas` 2194 to 2231) hand
    `PresetAngles` to the Focus as the camera's azimuth, which runs the
    other way from Sprite3D's; mirror images for asymmetric scenes while
    both routes are in use (ProjectionTest with `CameraPreset`, Sprite3D
    without).

57. **Rules.** `TSpritelyProjection` carries
    `[ComponentPlatformsAttribute(pidAllPlatforms)]` (661), not
    `SPRITELY_COMPONENT_PLATFORMS`, because the constant lives in
    `Spritely.OrbitalCamera.pas` (322), which uses `Spritely.Projection`;
    the constant wants a small shared unit. `Spritely.Projection.pas` has
    no `RegisterFmxClasses([TSpritelyProjection])` where
    `Spritely.OrbitalCamera.pas` registers its two (3609).
    Implementation-only helpers in `Spritely.OrbitalCamera.pas` (1756 to
    1794, 3210 to 3213: `EPS`, `NEAR_CLEARANCE`, `FAR_PLANE`,
    `TBoxCorners`, `GetBoxCorners`, `IsValidBox`, `NearestAngle`,
    `ModelsBox`) use `{ }` or `//` where the rule says `//**`.

58. **Packages.** `Spritely/packages/Spritely.dpk` is the IDE's re-saved
    form (`IMPLICITBUILDING` block, no "Written by tools/gen_packages.py"
    line), so the next run of the script changes it. `Spritely.dproj`
    lacks the `Base_OSX64`, `Base_OSXARM64`, `Base_Linux64`,
    `Base_iOSDevice64`, `Base_iOSSimARM64` groups `dclSpritely.dproj`
    has. `gen_packages.py`'s `ALL_PLATFORMS` lacks `Win64x`, which the IDE
    added. Platform tick lists otherwise agree with the script.

Checked and sound: the quaternion code (`ApplyOrientation`,
`ShortestArc`, `Rotate`, `FmxSign`), fits with degenerate boxes,
orthographic and oblique matrices (depth 0 to 1, row-vector shear order),
`ShiftProjection` in clip space, `SlotFor`'s stale-slot handling and the
tracker's recovery at a reused address, field order, no Sprite3D or Neon
dependency, and the camera, light and viewport notification order.

## Project files and tools

59. **`ReportMemoryLeaksOnShutdown` is commented out.** `src/Sprite3d.dpr`
    7 to 9 and 98: the comments, the README and `CLAUDE.md` all say it is
    set; `{$DEFINE REPORT_LEAKS}` is commented out too. Turn it on or
    correct the three descriptions.

60. **Deployment.** `src/Sprite3d.dproj` 793 to 845 and 1453 to 1488
    deploy `styles\buildstyles.cmd` to Linux64, OSXARM64 (under
    `Contents\Resources\StartUp\`, so `System.StartUpCopy` copies it into
    the user's folders), Win64 and WinARM64EC, and `..\README.md` to
    Android64, Linux64, OSXARM64 and Win64; nothing is
    `<Enabled>false</Enabled>`. The `.rc` is not deployed. Android
    (32-bit) is disabled at 2453 while `CLAUDE.md` lists it as a target
    and the Spritely package has it enabled.

61. **`tools/pasdoc_check.py`.** Line 217 treats any line ending in `}`
    as a comment, so a `{ }` block passes though PasDoc's `--staronly`
    ignores it; `declared_names` (80) counts every `x = y` and every local
    `v: T` as a declaration, so a `@link` to almost anything passes;
    blank lines between fields do not reset the shared-comment rule
    (173), and a field list broken over two lines is reported
    undocumented; attributes are skipped only when on one line.
    Implementation items are not checked, as its docstring says.

62. **Tracked generated files.** `src/styles/Sprite3DThemes.res` is
    rewritten by every pre-build and `src/Sprite3d.deployproj` is
    machine-specific; both are tracked. Nothing ignored is tracked and
    nothing tracked matches an ignore pattern. `buildstyles.cmd`'s
    failure handling is sound.

## Overall

Threading discipline, path handling and the cross-platform conditionals
hold up almost everywhere, and the hand-declared ABIs and the bzip2
decoder are correct. The defects are in state machines at their edges
(quit during export, load during scan, abort during page saving,
pending models after a failure) and in a few places where a flag or a
record is left behind an operation that can fail. The downloader needs
hardening before the list points at outside downloads. The rest is
drift: dead handlers and stale comments in the main form, growing
PasDoc gaps, and documentation that describes a leak report the `.dpr`
does not produce.
