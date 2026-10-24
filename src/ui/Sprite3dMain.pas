//** @abstract(Demo form for TSprite3DCamera: loads a model and drives the camera with dials.)
//**
//** The form has two tabs. The View tab holds a TGorillaViewport, created at run time, and a
//** panel of three dials for Azimuth, inclination and Roll. The Debug tab holds a memo for log
//** output. Below the Camera submenu, the View menu has six items that are ticked or not, each
//** switched by choosing it: Show bounding box shows the model's bounding box, Show grid a grid
//** on the model's floor, Show axes its own X, Y and Z axes through its centre of rotation,
//** Show Model Volume the space it sweeps turning about its up axis in the animation playing,
//** Show Animation Volume the one joined over the rest pose and every animation used, shown
//** only while it is the volume the view frames, and Orthographic switches
//** between perspective and orthographic projection. Model, Animations Used chooses which of
//** the model's animations are listed and count towards the combined swept volume.
//**
//** The camera starts in the isometric view, and each readout always shows its dial's angle,
//** from 0 to 359 degrees. Azimuth is sent to the camera reversed, 360 minus the readout, so
//** the view turns the right way for the dial. View, Camera, Variable lets the dials set the
//** angles; View, Camera, Isometric, the default for now, sets the readouts to inclination
//** 35.264, azimuth 45 and roll 0, the true isometric view, and switches the dials off; View,
//** Camera, Pixel 2:1 does the same with an inclination of about 26.565; View, Camera, 1/4
//** View, 3/4 View, Sqrt@(2@) and Golden Ratio use about 22.5, 45, 54.736 and 58.283; View,
//** Camera, Head On and View, Camera,
//** Top Down use inclinations of 0 and 90 at azimuth 0; and View, Camera, Side View uses
//** inclination 0 at azimuth 90. A test slider along the bottom of the 3D view moves the camera
//** out from the fitted distance, x1 to x20.
//**
//** A model is loaded behind a modal dialog, TModelLoadForm, with a progress bar, a line saying
//** what is happening, and Abort. The file is read on a worker thread; Gorilla3D then builds
//** the model from it in one step, which cannot be interrupted; and each animation's bounds,
//** which the volumes and the fit need, are measured a slice at a time, unless they are in the
//** bounds folder of the application's support folder from an earlier load of the same,
//** unchanged file. The new model is built beside the one shown, which is left alone until the
//** new one is ready, so Abort, or a failure, leaves the previous model, or none at start-up.
//** While there is no model, a panel over the view says how to load one. The window is drawn
//** before the first model loads, the video libraries are looked for only once that load has
//** ended, and saved files are composed and encoded on a worker thread.
//**
//** On show, the form loads the model the operating system asked it to open, as when a .glb or
//** .gltf file is double-clicked in Explorer or Finder, or else what the start-up action in
//** File, Settings asks for; files the system asks to open later replace it. File, Open Model
//** then loads any other glTF, FBX, OBJ, USD, Collada, STL or PLY file, and File, Exit closes
//** the application. File, Grab renders the view off screen at the grab size set in File,
//** Settings, 256 by 256 pixels unless changed, with the model fitted to fill it, and saves it
//** as the next of grab001.png, grab002.png and so on in SaveFolder, asking for that folder
//** only when none is known: SaveFolder is kept between sessions in settings.json, through
//** TSprite3DAppSettings in Sprite3DHelpers. File, Save As Icon renders the view off screen at
//** each of Windows' icon sizes and saves them together as one .ico file the user names. Behind
//** the model the viewport can show a background; by default none is drawn. File, Background
//** Settings... chooses None, Transparent (a two-grey checker standing for transparency), Solid
//** or Gradient, which grabs and icons follow too.
//**
//** File, Settings... opens TGeneralSettingsForm, centred on this form: whether Sprite3D is
//** offered under Open With for model files and whether it is their default application, the
//** start-up action (no model, the sample model or the model last opened), the size of
//** off-screen grabs (a square preset from 8 to 512 pixels, or a custom width and height from 8
//** to 1024), the theme (FMX's default style, Dark, or the coloured Aqua, Ruby and Golden
//** Graphite styles, which the title bars follow where the system allows) and, on Windows,
//** which GPU to ask for, which takes effect at the next start. All are kept in settings.json.
//**
//** The Variable camera dialog can also pan the view along the model's own X and Z axes,
//** for the odd model that should sit off centre. The pan moves the point the camera
//** orbits, on top of every fit, on screen and in grabs and icons, in whichever view is
//** chosen, until it is switched off; it never changes the angles or the distance. It is
//** off by default and kept in settings.json.
//**
//** The Animations list shows, to the right of each entry under the Frames title, how many
//** frames saving it makes at the Model, Animation Settings frame rate: the animation's length
//** times the rate, rounded, or 1 for @code(@(None@)), a single still frame. Model, Animations
//** Used opens a dialog that ticks which animations are used; the others are left out of the
//** list, so they are not played, saved or exported, and out of the combined swept volume. A
//** new model starts with every animation used.
//**
//** Under the list, five buttons with icons, named in their hints, act on the selected
//** animation: first frame, previous frame, play or pause, next frame and last frame. The
//** frames are those an export makes at the Model, Animation Settings frame rate, held exactly
//** as the export shows them, by TSprite3DAnimationPlayer; any of the four frame buttons pauses
//** the animation on its frame. After them, a readout always shows the frame showing, held or
//** playing, and the frames in all, with the "/" in a fixed place; it reads "- / -" when there
//** is no animation to count, as for @code(@(None@)). A readout over the top left of the view,
//** white on a dark backing, shows the frames per second the viewport draws, which File,
//** Settings sets, kept within the refresh rate of the display the window is on, and checked
//** again whenever the window moves to another display. Play and pause share a button, whose
//** icon and hint change to say which it does. Stepping wraps round from the last frame to the
//** first and back. Choosing an entry plays it from the start, unless the controls are paused,
//** when it starts paused on its first frame; starting a capture lets a held animation play on.
//** Grabs and icons are saved as the view shows them, with the background and every helper
//** showing. Animation exports show the model alone: the bounding box, axes, grid and volume
//** wireframes are hidden for each drawing, and the background is left out, so they are
//** transparent around the model, or black for MP4.
//**
//** Right-clicking an entry in the Animations list selects and plays it, and opens a pop-up
//** menu with Save as sprite strip, Save as Spritesheet, Save as AniGif and Save as MP4
//** video. Each grabs every frame of that animation off screen, from the first to the last, at
//** the grab size and with one framing that fits every frame, and saves them in SaveFolder:
//** side by side in one row as @code(<animation>_strip<frames>.png), in a square grid read left
//** to right and top to bottom as @code(<animation>.png), as a looping @code(<animation>.gif),
//** or as a video-only @code(<animation>.mp4) through Sprite3DVideo, H.264 when Cisco's
//** OpenH264 library is present and MPEG-4 Part 2 otherwise. MP4 is offered only when the
//** FFmpeg libraries load; DebugMemo says at start-up whether they did and from where. The
//** @code(@(None@)) entry, which has no animation, captures instead a single still frame of the
//** model in its bind pose, named after the model. On Android and iOS, which have no
//** right-click, the same items are in an Animation group of the menu drawer and act on the
//** selected entry.
//**
//** At start-up the OpenH264 library, which makes MP4 files H.264, is taken from
//** @code(openh264.json): an address for each platform, from which a copy is downloaded in
//** the background into OpenH264Folder the first time, and again whenever the address changes.
//** An empty address, or a failed download, leaves MP4 files as MPEG-4 Part 2. DebugMemo says
//** which happened.
//**
//** Model, Animation Settings... sets the frame rate every saved animation uses, 30 frames a
//** second unless changed, from 1 to 60, kept in settings.json. Each animation is resampled to
//** it: one cycle is cut into the whole number of equal steps nearest that rate, so the saved
//** frames still loop exactly; see TSprite3DAnimationFrames. The same dialog turns overscan
//** on, for this session only: every grab, icon and export is drawn 2 to 16 times larger each
//** way, as far as the GPU allows at the grab size, and scaled down with the resampling filter
//** chosen there, by TSprite3DOffscreen. The factor and filter are kept in settings.json.
//**
//** Each entry also has a tick box. Below the list, All ticks every animation, leaving
//** @code(@(None@)) as it is so the turn is exported only when ticked by hand, or clears every
//** entry; a drop-down chooses Sprite strip, Spritesheet, Texture Atlas, AniGif or, when FFmpeg
//** loaded, MP4 video, and Export saves every ticked entry that way, one after another, in a
//** folder chosen in a folder dialog that opens at SaveFolder, so a new sub-folder can be made
//** there for the batch. SaveFolder itself is not changed. A failed entry is reported at the
//** end and does not stop the others. Each entry is unticked as soon as it is saved, so a
//** failed one stays ticked for another try. Abort, enabled only while a batch runs, lets the
//** entry being captured finish and save, then drops the rest. On Android and iOS, which have
//** no folder dialog, the batch goes to the Grabs folder.
//**
//** The drop-down's Texture Atlas asks for its folder as it is chosen. Its batch captures
//** every ticked entry, then packs them, in list order, onto pages no larger than the page
//** size in Model, Animation Settings, saved as @code(<model>_atlas_01.png), @code(_02) and
//** so on; see SaveAtlas.
//**
//** View, Camera, Lock Camera fixes the camera where it is. While it is ticked nothing moves or
//** turns the camera: the views, Orthographic and the pan are switched off, a new model or a
//** resized view is not refitted, and grabs, icons and animation captures use the view exactly
//** as it stands instead of fitting the model to their own size. The lock is not kept between
//** sessions.
//**
//** Each model replaces the last: it is centred and turned 180 degrees about X, and the camera
//** is fitted so it fills the view. The model is refitted when the viewport is resized, the
//** projection changes, the animations used change, another entry is chosen, an entry is ticked
//** or unticked for export, or an animation is paused, stepped or played, but not when a dial
//** turns. While two or more animations are ticked, playing or paused, the fit frames the
//** combined swept volume, the space the model sweeps turning about its up axis over its rest
//** pose and every animation used, so everything a batch exports is framed alike, and Show
//** Animation Volume draws it. Otherwise, with one ticked or none, as for a model without
//** animations, it frames the volume of what is on screen alone: the selected animation's,
//** paused or playing, or the rest pose's for @code(@(None@)). Either way the volume fills the
//** view on the tighter axis, and the orbit centre is on the turning axis, so turning the
//** azimuth dial keeps the model in view.
//**
//** The form only handles the user interface. The 3D work is done by the library units in
//** @code(lib): Sprite3DCamera, Sprite3DAxes, Sprite3DGrid, Sprite3DSweep and
//** Sprite3DOffscreen. The application's other rules, such as where models are found, how a
//** model is loaded and placed, and how grabs are named and saved, are in Sprite3DHelpers.
//**
//** On Android and iOS, where FMX shows no menu bar, the same menus are reached through a
//** hamburger button on a toolbar at the top, which opens a drawer listing every item in
//** MainMenu1; ticks show the current camera view and which View items are on. Exit is left
//** out on iOS. On Linux the same items are moved onto a TMenuBar that FMX draws itself, as
//** the native GTK menu bar showed only the first letter of each item.
//**
//** @preformatted(
//** TabControl1
//** |-- GorillaTab "View"
//** |   `-- MainLayout
//** |       |-- ViewportLayout   the area left of the control panel
//** |       |   `-- AspectLayout   dark grey; the TGorillaViewport, centred, at the grab shape
//** |       `-- ControlsLayout   dials and their labels
//** `-- DebugTab "Debug"
//**     `-- DebugMemo
//**
//** MainMenu1
//** |-- FileMenu "File"
//** |   |-- OpenModelMenuItem "Open Model"  shows OpenDialog1
//** |   |-- GrabMenuItem "Grab"             saves the off-screen view as grabNNN.png
//** |   |-- SaveAsIconMenuItem "Save As Icon"  saves the view as a Windows .ico file
//** |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
//** |   `-- ExitMenuItem "Exit"             closes the application
//** |-- ModelMenu "Model"
//** |   |-- AnimationsUsedItem "Animations Used..."  which animations are listed and swept
//** |   |-- ModelSettingsSeparatorItem "-"
//** |   |-- FAnimationSettingsItem "Animation Settings..."  frame rate, overscan, resampling
//** |   |-- BackgroundSettingsMenuItem "Background Settings..."  opens the background dialog
//** |   |-- ModelActionsSeparatorItem "-"
//** |   |-- DirectionsItem "Directions..."  how many directions, the first and their order
//** |   `-- OrientationItem "Orientation"   disabled; for a later version
//** `-- ViewMenu "View"                   its ticks are kept in settings.json
//**     |-- CameraMenu "Camera"             the view, kept in settings.json
//**     |   |-- ViewVariableItem "Variable"     dials set the angles; also the pan
//**     |   |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
//**     |   |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
//**     |   |-- ViewOneQuarterItem "1/4 View"   fixed, inclination 22.5
//**     |   |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45
//**     |   |-- ViewRoot2Item "Sqrt@(2@)"       fixed, inclination about 54.736
//**     |   |-- ViewGoldenRatioItem "Golden Ratio" fixed, inclination about 58.283
//**     |   |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
//**     |   |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
//**     |   |-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
//**     |   |-- FLockSeparatorItem "-"
//**     |   `-- FLockCameraItem "Lock Camera"   fixes the camera; not a view
//**     |-- ViewSeparatorItem "-"
//**     |-- ShowBoundsItem "Show bounding box"  ticked at start-up
//**     |-- ShowGridItem "Show grid"        ticked at start-up
//**     |-- ShowAxesItem "Show axes"        ticked at start-up
//**     |-- ShowSweepItem "Show Model Volume"  ticked at start-up; the space swept turning
//**     |                                      about the up axis
//**     |-- ShowCombinedSweepItem "Show Animation Volume"  the volume the camera
//**     |                                      frames
//**     `-- OrthographicItem "Orthographic" orthographic instead of perspective
//** )
unit Sprite3dMain;
{
  Demo form for TSprite3DCamera: loads a model and drives the camera with
  dials.

  The form has two tabs. The View tab holds a TGorillaViewport, created at run
  time, and a panel of three dials for Azimuth, inclination and Roll. The
  Debug tab holds a memo for log output. Below the Camera submenu, the View
  menu has six items that are ticked or not, each switched by choosing it:
  Show bounding box shows the model's bounding box, Show grid a grid on the
  model's floor, Show axes its own X, Y and Z axes through its centre of
  rotation, Show Model Volume the space it sweeps turning about its up axis
  in the animation playing, Show Animation Volume the one joined over the
  rest pose and every animation used, shown only while it is the volume the
  view frames, and Orthographic switches between
  perspective and orthographic projection.
  Model, Animations Used chooses which of the model's animations are listed
  and count towards the combined swept volume.

  The camera starts in the isometric view, and each readout always shows its
  dial's angle, from 0 to 359 degrees. Azimuth is sent to the camera reversed,
  360 minus the readout, so the view turns the right way for the dial. View,
  Camera, Variable lets the dials set the angles; View, Camera, Isometric, the
  default for now, sets the readouts to inclination 35.264, azimuth 45 and
  roll 0, the true isometric view, and switches the dials off; View, Camera,
  Pixel 2:1 does the same with an inclination of about 26.565; View, Camera,
  1/4 View, 3/4 View, Sqrt(2) and Golden Ratio use about 22.5, 45, 54.736 and
  58.283; View, Camera, Head
  On and View, Camera, Top Down use inclinations of 0 and 90 at azimuth 0; and
  View, Camera, Side View uses inclination 0 at azimuth 90. A test slider
  along the bottom of the 3D view moves the camera out from the fitted
  distance, x1 to x20.

  A model is loaded behind a modal dialog, TModelLoadForm, with a progress
  bar, a line saying what is happening, and Abort. The file is read on a
  worker thread; Gorilla3D then builds the model from it in one step, which
  cannot be interrupted; and each animation's bounds, which the volumes and
  the fit need, are measured a slice at a time, unless they are in the bounds
  folder of the application's support folder from an earlier load of the same,
  unchanged file. The new model is built beside the one shown, which is left
  alone until the new one is ready, so Abort, or a failure, leaves the
  previous model, or none at start-up. While there is no model, a panel over
  the view says how to load one. The window is drawn before the first model
  loads, the video libraries are looked for only once that load has ended, and
  saved files are composed and encoded on a worker thread.

  On show, the form loads the model the operating system asked it to open, as
  when a .glb or .gltf file is double-clicked in Explorer or Finder, or else
  what the start-up action in File, Settings asks for; files the system asks
  to open later replace it. File, Open Model then loads any other glTF, FBX,
  OBJ, USD, Collada, STL or PLY file, and File, Exit closes the application.
  File, Grab renders the view off screen at the grab size set in File,
  Settings, 256 by 256 pixels unless changed, with the model fitted to fill
  it, and saves it as the next of grab001.png, grab002.png and so on in
  SaveFolder, asking for that folder only when none is known: SaveFolder is
  kept between sessions in settings.json, through TSprite3DAppSettings in
  Sprite3DHelpers. File, Save As Icon renders the view off screen at each of
  Windows' icon sizes and saves them together as one .ico file the user names.
  Behind the model the viewport can show a background; by default none is
  drawn. Model, Background Settings... chooses None, Transparent (a two-grey
  checker standing for transparency), Solid or Gradient, which grabs and icons
  follow too.

  File, Settings... opens TGeneralSettingsForm, centred on this form: whether
  Sprite3D is offered under Open With for model files and whether it is their
  default application, the start-up action (no model, the sample model or the
  model last opened), the size of off-screen grabs (a square preset from 8 to
  512 pixels, or a custom width and height from 8 to 1024), the theme (FMX's
  default style, Dark, or the coloured Aqua, Ruby and Golden Graphite styles,
  which the title bars follow where the system allows) and, on Windows, which
  GPU to ask for, which takes effect at the next start. All are kept in
  settings.json.

  The Variable camera dialog can also pan the view along the model's own X
  and Z axes, for the odd model that should sit off centre. The pan moves
  the point the camera orbits, on top of every fit, on screen and in grabs
  and icons, in whichever view is chosen, until it is switched off; it never
  changes the angles or the distance. It is off by default and kept in
  settings.json.

  The Animations list shows, to the right of each entry under the Frames
  title, how many frames saving it makes at the Model, Animation Settings
  frame rate: the animation's length times the rate, rounded, or 1 for (None),
  a single still frame. Model, Animations Used opens a dialog that ticks which
  animations are used; the others are left out of the list, so they are not
  played, saved or exported, and out of the combined swept volume. A new model
  starts with every animation used.

  Under the list, five buttons with icons, named in their hints, act on the
  selected animation: first frame, previous frame, play or pause, next frame
  and last frame. The frames are those an export makes at the Model, Animation
  Settings frame rate, held exactly as the export shows them, by
  TSprite3DAnimationPlayer; any of the four frame buttons pauses the animation
  on its frame. After them, a readout always shows the frame showing, held or
  playing, and the frames in all, with the "/" in a fixed place; it reads "- /
  -" when there is no animation to count, as for (None). A readout over the
  top left of the view, white on a dark backing, shows the frames per second
  the viewport draws, which File, Settings sets, kept within the refresh rate
  of the display the window is on, and checked again whenever the window moves
  to another display. Play and pause share a button, whose icon and hint
  change to say which it does. Stepping wraps round from the last frame to the
  first and back. Choosing an entry plays it from the start, unless the
  controls are paused, when it starts paused on its first frame; starting a
  capture lets a held animation play on. Grabs and icons are saved as the view
  shows them, with the background and every helper showing. Animation exports
  show the model alone: the bounding box, axes, grid and volume wireframes are
  hidden for each drawing, and the background is left out, so they are
  transparent around the model, or black for MP4.

  Right-clicking an entry in the Animations list selects and plays it, and
  opens a pop-up menu with Save as sprite strip, Save as Spritesheet, Save
  as AniGif and Save as MP4 video. Each grabs every frame of that animation
  off screen, from the first to the last, at the grab size and with one
  framing that fits every frame, and saves them in SaveFolder: side by side in
  one row as <animation>_strip<frames>.png, in a square grid read left to
  right and top to bottom as <animation>.png, as a looping <animation>.gif, or
  as a video-only <animation>.mp4 through Sprite3DVideo, H.264 when Cisco's
  OpenH264 library is present and MPEG-4 Part 2 otherwise. MP4 is offered only
  when the FFmpeg libraries load; DebugMemo says at start-up whether they did
  and from where. The (None) entry, which has no animation, captures instead a
  single still frame of the model in its bind pose, named after the model. On
  Android and iOS, which have no right-click, the same items are in an
  Animation group of the menu drawer and act on the selected entry.

  At start-up the OpenH264 library, which makes MP4 files H.264, is taken
  from openh264.json: an address for each platform, from which a copy is
  downloaded in the background into OpenH264Folder the first time, and again
  whenever the address changes. An empty address, or a failed download,
  leaves MP4 files as MPEG-4 Part 2. DebugMemo says which happened.

  Model, Animation Settings... sets the frame rate every saved animation uses, 30
  frames a second unless changed, from 1 to 60, kept in settings.json. Each
  animation is resampled to it: one cycle is cut into the whole number of
  equal steps nearest that rate, so the saved frames still loop exactly; see
  TSprite3DAnimationFrames. The same dialog turns overscan on, for this
  session only: every grab, icon and export is drawn 2 to 16 times larger
  each way, as far as the GPU allows at the grab size, and scaled down with
  the resampling filter chosen there, by TSprite3DOffscreen. The factor and
  filter are kept in settings.json.

  Each entry also has a tick box. Below the list, All ticks every animation,
  leaving (None) as it is so the turn is exported only when ticked by hand,
  or clears every entry; a drop-down chooses Sprite strip, Spritesheet,
  Texture Atlas, AniGif or, when FFmpeg loaded, MP4 video, and Export saves
  every ticked entry that way, one after another, in a folder
  chosen in a folder dialog that opens at SaveFolder, so a new sub-folder can
  be made there for the batch. SaveFolder itself is not changed. A failed
  entry is reported at the end and does not stop the others. Each entry is
  unticked as soon as it is saved, so a failed one stays ticked for another
  try. Abort, enabled only while a batch runs, lets the entry being captured
  finish and save, then drops the rest. On Android and iOS, which have no
  folder dialog, the batch goes to the Grabs folder.

  View, Camera, Lock Camera fixes the camera where it is. While it is ticked
  nothing moves or turns the camera: the views, Orthographic and the pan are
  switched off, a new model or a resized view is not refitted, and grabs,
  icons and animation captures use the view exactly as it stands instead of
  fitting the model to their own size. The lock is not kept between sessions.

  Each model replaces the last: it is centred and turned 180 degrees about X,
  and the camera is fitted so it fills the view. The model is refitted when
  the viewport is resized, the projection changes, the animations used change,
  another entry is chosen, an entry is ticked or unticked for export, or an
  animation is paused, stepped or played, but not when a dial turns. While two
  or more animations are ticked, playing or paused, the fit frames the
  combined swept volume, the space the model sweeps turning about its up axis
  over its rest pose and every animation used, so everything a batch exports
  is framed alike, and Show Animation Volume draws it. Otherwise, with one
  ticked or none, as for a model without animations, it frames the volume of
  what is on screen alone: the selected animation's, paused or playing, or the
  rest pose's for (None). Either way the volume fills the view on the tighter
  axis, and the orbit centre is on the turning axis, so turning the azimuth
  dial keeps the model in view.

  The form only handles the user interface. The 3D work is done by the library
  units in lib: Sprite3DCamera, Sprite3DAxes, Sprite3DGrid, Sprite3DSweep
  and Sprite3DOffscreen. The application's other rules, such as where models are
  found, how a model is loaded and placed, and how grabs are named and saved,
  are in Sprite3DHelpers.

  On Android and iOS, where FMX shows no menu bar, the same menus are reached
  through a hamburger button on a toolbar at the top, which opens a drawer
  listing every item in MainMenu1; ticks show the current camera view and
  which View items are on. Exit is left out on iOS. On Linux the same items are
  moved onto a TMenuBar that FMX draws itself, as the native GTK menu bar
  showed only the first letter of each item.

    TabControl1
    |-- GorillaTab "View"
    |   `-- MainLayout
    |       |-- ViewportLayout   the area left of the control panel
    |       |   `-- AspectLayout   dark grey; the TGorillaViewport, centred, at the grab shape
    |       `-- ControlsLayout   dials and their labels
    `-- DebugTab "Debug"
        `-- DebugMemo

    MainMenu1
    |-- FileMenu "File"
    |   |-- OpenModelMenuItem "Open Model"  shows OpenDialog1
    |   |-- GrabMenuItem "Grab"             saves the off-screen view as grabNNN.png
    |   |-- SaveAsIconMenuItem "Save As Icon"  saves the view as a Windows .ico file
    |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
    |   `-- ExitMenuItem "Exit"             closes the application
    |-- ModelMenu "Model"
    |   |-- AnimationsUsedItem "Animations Used..."  which animations are listed and swept
    |   |-- ModelSettingsSeparatorItem "-"
    |   |-- FAnimationSettingsItem "Animation Settings..."  frame rate, overscan, resampling
    |   |-- BackgroundSettingsMenuItem "Background Settings..."  opens the background dialog
    |   |-- ModelActionsSeparatorItem "-"
    |   |-- DirectionsItem "Directions..."  how many directions, the first and their order
    |   `-- OrientationItem "Orientation"   disabled; for a later version
    `-- ViewMenu "View"                   its ticks are kept in settings.json
        |-- CameraMenu "Camera"             the view, kept in settings.json
        |   |-- ViewVariableItem "Variable"     dials set the angles; also the pan
        |   |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
        |   |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
        |   |-- ViewOneQuarterItem "1/4 View"   fixed, inclination 22.5
        |   |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45
        |   |-- ViewRoot2Item "Sqrt(2)"         fixed, inclination about 54.736
        |   |-- ViewGoldenRatioItem "Golden Ratio" fixed, inclination about 58.283
        |   |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
        |   |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
        |   |-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
        |   |-- FLockSeparatorItem "-"
        |   `-- FLockCameraItem "Lock Camera"   fixes the camera; not a view
        |-- ViewSeparatorItem "-"
        |-- ShowBoundsItem "Show bounding box"  ticked at start-up
        |-- ShowGridItem "Show grid"        ticked at start-up
        |-- ShowAxesItem "Show axes"        ticked at start-up
        |-- ShowSweepItem "Show Model Volume"  ticked at start-up; the space swept turning
        |                                      about the up axis
        |-- ShowCombinedSweepItem "Show Animation Volume"  the volume the camera
        |                                      frames
        `-- OrthographicItem "Orthographic" orthographic instead of perspective
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Math.Vectors, FMX.Types3D, Gorilla.Control, Gorilla.Transform, Gorilla.Mesh,
  Gorilla.Model, FMX.Controls3D, Gorilla.Light, Gorilla.Viewport,
  FMX.TabControl, FMX.Layouts, Gorilla.Controller, Gorilla.Animation.Controller,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Objects, FMX.Objects3D, Gorilla.Camera, Sprite3dCamera, FMX.Menus,
  Sprite3DOffscreen, Sprite3DHelpers, Sprite3DIconWriter, Sprite3DBackground,
  Sprite3DOrbitalForm, Sprite3DSettingsForm, FMX.ListBox, Sprite3DAnimCapture,
  Sprite3DAnimationForm, Sprite3DVideo, Sprite3DLibraryUpdate, Sprite3DOpenH264,
  Sprite3DSpriteSheet, Sprite3DSweep, Sprite3DResample, System.Threading,
  Sprite3DLoadForm, Gorilla.Animation, DisplayData, Sprite3DAxes, Sprite3DGrid,
  Sprite3DExportForm, System.Generics.Collections, FMX.Edit, System.JSON,
  System.Diagnostics
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  , FMX.MultiView   // FMX.ListBox, also needed there, is listed above
  {$ENDIF}
  ;

type
  //** @abstract(What the animation list's pop-up menu saves a capture as.)
  /// <summary>What the animation list's pop-up menu saves a capture as.</summary>
  TSheetKind = (
    //** @abstract(One row of frames, saved as @code(<name>_strip<count>.png).)
    /// <summary>One row of frames, saved as
    /// <c>&lt;name&gt;_strip&lt;count&gt;.png</c>.</summary>
    skStrip,
    //** @abstract(A square grid of frames, saved as @code(<name>.png).)
    /// <summary>A square grid of frames, saved as <c>&lt;name&gt;.png</c>.</summary>
    skSheet,
    //** @abstract(Texture atlas pages: every animation of a batch packed onto shared pages,
    //** saved as @code(<model>_atlas_01.png) and so on; batch Export only.)
    /// <summary>Texture atlas pages: every animation of a batch packed onto shared pages,
    /// saved as <c>&lt;model&gt;_atlas_01.png</c> and so on; batch Export only.</summary>
    skAtlas,
    //** @abstract(A looping animated GIF, saved as @code(<name>.gif).)
    /// <summary>A looping animated GIF, saved as <c>&lt;name&gt;.gif</c>.</summary>
    skGif,
    //** @abstract(A video-only MPEG-4 MP4, saved as @code(<name>.mp4); only offered when the
    //** FFmpeg libraries load.)
    /// <summary>A video-only MPEG-4 MP4, saved as <c>&lt;name&gt;.mp4</c>; only offered when
    /// the FFmpeg libraries load.</summary>
    skMp4);

  //** @abstract(An Animations list read from a file, ready to apply to a model.)
  /// <summary>An Animations list read from a file, ready to apply to a model.</summary>
  TAnimationListState = record
    //** @abstract(The entry to select, by name; empty for none.)
    /// <summary>The entry to select, by name; empty for none.</summary>
    Selected: String;
    //** @abstract(The entries, by name, in the order listed.)
    /// <summary>The entries, by name, in the order listed.</summary>
    Names: TArray<String>;
    //** @abstract(Each entry's tick.)
    /// <summary>Each entry's tick.</summary>
    Checked: TArray<Boolean>;
    //** @abstract(Each entry's frame count typed in; 0 for the one the frame rate gives.)
    /// <summary>Each entry's frame count typed in; 0 for the one the frame rate
    /// gives.</summary>
    Frames: TArray<Integer>;
  end;

  //** @abstract(One animation captured for a texture atlas, kept until the batch ends and the
  //** pages are made.)
  /// <summary>One animation captured for a texture atlas: what its pages' metadata says of
  /// it. Its frames go into the pages as they fill.</summary>
  TAtlasPart = record
    //** @abstract(The entry's name as the Animations list shows it.)
    /// <summary>The entry's name as the Animations list shows it.</summary>
    Name: String;
    //** @abstract(The entry's index in the Animations list, to untick once saved.)
    /// <summary>The entry's index in the Animations list, to untick once saved.</summary>
    Entry: Integer;
    //** @abstract(How many frames it has.)
    /// <summary>How many frames it has.</summary>
    Count: Integer;
    //** @abstract(How long it takes to play once, in seconds: its own length, whatever
    //** number of frames it was saved at.)
    /// <summary>How long it takes to play once, in seconds: its own length, whatever number
    /// of frames it was saved at.</summary>
    Time: Double;
    //** @abstract(The pixel the centre of rotation falls on in its frames.)
    /// <summary>The pixel the centre of rotation falls on in its frames.</summary>
    Origin: TPoint;
    //** @abstract(Whether Origin is known.)
    /// <summary>Whether Origin is known.</summary>
    OriginKnown: Boolean;
    //** @abstract(The direction it was captured in, as an index into the batch's directions;
    //** 0 when directions are not used.)
    /// <summary>The direction it was captured in, as an index into the batch's directions; 0
    /// when directions are not used.</summary>
    Direction: Integer;
  end;

  //** @abstract(A frame captured for a texture atlas, waiting for its page to fill.)
  /// <summary>A frame captured for a texture atlas, waiting for its page to fill.</summary>
  TAtlasCell = record
    //** @abstract(Which animation it is, as an index into the batch's parts.)
    /// <summary>Which animation it is, as an index into the batch's parts.</summary>
    Part: Integer;
    //** @abstract(Which frame of that animation it is, counted from 0.)
    /// <summary>Which frame of that animation it is, counted from 0.</summary>
    Frame: Integer;
    //** @abstract(The frame.)
    /// <summary>The frame.</summary>
    Image: TSprite3DImage;
  end;

  //** @abstract(Where a model load has got to; see TMainForm.SwitchModel.)
  /// <summary>Where a model load has got to; see TMainForm.SwitchModel.</summary>
  TModelLoadStage = (
    //** @abstract(No load is under way.)
    /// <summary>No load is under way.</summary>
    lsNone,
    //** @abstract(The file is being read on a worker thread; Abort stops it at once.)
    /// <summary>The file is being read on a worker thread; Abort stops it at once.</summary>
    lsRead,
    //** @abstract(Gorilla3D builds the model on the next tick, in one step.)
    /// <summary>Gorilla3D builds the model on the next tick, in one step.</summary>
    lsBuild,
    //** @abstract(The new model's animations are being measured, a slice at a time.)
    /// <summary>The new model's animations are being measured, a slice at a
    /// time.</summary>
    lsMeasure,
    //** @abstract(The new model replaces the old one on the next tick.)
    /// <summary>The new model replaces the old one on the next tick.</summary>
    lsCommit);

  //** @abstract(The main form: a Gorilla3D view of one model, with dials for the camera.)
  //**
  //** The viewport, light, model and TSprite3DCamera are created at run time, not at design
  //** time; the form owns none of them directly. All event handlers run on the main thread.
  //**
  //** @seealso(TSprite3DCamera)
  /// <summary>The main form: a Gorilla3D view of one model, with dials for the
  /// camera.</summary>
  /// <remarks>The viewport, light, model and TSprite3DCamera are created at run time, not at
  /// design time; the form owns none of them directly. All event handlers run on the main
  /// thread.</remarks>
  /// <seealso cref="Sprite3DCamera.TSprite3DCamera"/>
  TMainForm = class(TForm)
    //** @abstract(Fills the form and holds the View tab and the Debug tab.)
    /// <summary>Fills the form and holds the View tab and the Debug tab.</summary>
    TabControl1: TTabControl;
    //** @abstract(The tab captioned "View", with the viewport and camera controls; active at
    //** start-up.)
    /// <summary>The tab captioned "View", with the viewport and camera controls; active at
    /// start-up.</summary>
    GorillaTab: TTabItem;
    //** @abstract(The tab captioned "Debug", holding DebugMemo.)
    /// <summary>The tab captioned "Debug", holding DebugMemo.</summary>
    DebugTab: TTabItem;
    //** @abstract(Log output; SwitchModel writes separator lines here when a model has
    //** animations.)
    /// <summary>Log output; SwitchModel writes separator lines here when a model has
    /// animations.</summary>
    DebugMemo: TMemo;
    //** @abstract(Fills the View tab and holds ViewportLayout and ControlsLayout.)
    /// <summary>Fills the View tab and holds ViewportLayout and ControlsLayout.</summary>
    MainLayout: TLayout;
    //** @abstract(The area left of the control panel; holds AspectLayout, with the FPS
    //** readout and the no-model notice over it.)
    /// <summary>The area left of the control panel; holds AspectLayout, with the FPS readout
    /// and the no-model notice over it.</summary>
    ViewportLayout: TLayout;
    //** @abstract(Fills ViewportLayout in dark grey, and holds the TGorillaViewport made in
    //** FormCreate, with its background, centred at the shape of the grabs.)
    //**
    //** The viewport is as large as fits in AspectLayout while keeping the aspect ratio of the
    //** grab size set in File, Settings, usually square, so what is on screen is framed as the
    //** grabs are; the grey shows round it. FitViewportToAspect places it whenever
    //** AspectLayout changes size or the grab size changes. Clicks pass through it.
    /// <summary>Fills ViewportLayout in dark grey, and holds the TGorillaViewport made in
    /// FormCreate, with its background, centred at the shape of the grabs.</summary>
    /// <remarks>The viewport is as large as fits in AspectLayout while keeping the aspect ratio
    /// of the grab size set in File, Settings, usually square, so what is on screen is framed
    /// as the grabs are; the grey shows round it. FitViewportToAspect places it whenever
    /// AspectLayout changes size or the grab size changes. Clicks pass through it.</remarks>
    AspectLayout: TRectangle;
    //** @abstract(The right-hand control panel holding the dials and their labels.)
    /// <summary>The right-hand control panel holding the dials and their labels.</summary>
    ControlsLayout: TLayout;
    //** @abstract(An FMX TModel3D placed at design time; the code does not use it.)
    //**
    //** The model on screen is a TGorillaModel created at run time by SwitchModel.
    /// <summary>An FMX TModel3D placed at design time; the code does not use it.</summary>
    /// <remarks>The model on screen is a TGorillaModel created at run time by
    /// SwitchModel.</remarks>
    Model3D1: TModel3D;
    //** @abstract(Asks for the model file that File, Open Model loads.)
    //**
    //** Its filter, set in the form designer, offers only the formats the unit has loaders
    //** for: .glb, .gltf, .fbx, .obj, .usdc, .dae, .stl and .ply, all together first and then
    //** one at a time.
    /// <summary>Asks for the model file that File, Open Model loads.</summary>
    /// <remarks>Its filter, set in the form designer, offers only the formats the unit has
    /// loaders for: .glb, .gltf, .fbx, .obj, .usdc, .dae, .stl and .ply, all together first and
    /// then one at a time.</remarks>
    OpenDialog1: TOpenDialog;
    //** @abstract(Asks where File, Save As Icon saves; see SaveAsIconMenuItemClick.)
    //**
    //** Its filter is set from IconDialogFilter each time, so it offers every registered icon
    //** format; for now only Windows .ico. It prompts before overwriting a file.
    /// <summary>Asks where File, Save As Icon saves; see
    /// <see cref="SaveAsIconMenuItemClick"/>.</summary>
    /// <remarks>Its filter is set from IconDialogFilter each time, so it offers every
    /// registered icon format; for now only Windows .ico. It prompts before overwriting a
    /// file.</remarks>
    SaveIconDialog: TSaveDialog;
    //** @abstract(The form's menu bar, holding FileMenu.)
    /// <summary>The form's menu bar, holding FileMenu.</summary>
    MainMenu1: TMainMenu;
    //** @abstract(The "File" menu, holding OpenModelMenuItem, GrabMenuItem and ExitMenuItem.)
    /// <summary>The "File" menu, holding OpenModelMenuItem, GrabMenuItem and
    /// ExitMenuItem.</summary>
    FileMenu: TMenuItem;
    //** @abstract(The "Open Model" item; see OpenModelMenuItemClick.)
    /// <summary>The "Open Model" item; see <see cref="OpenModelMenuItemClick"/>.</summary>
    OpenModelMenuItem: TMenuItem;
    //** @abstract(The "Load Animation Settings..." item; see
    //** LoadAnimationSettingsItemClick.)
    /// <summary>The "Load Animation Settings..." item; see
    /// <see cref="LoadAnimationSettingsItemClick"/>.</summary>
    LoadAnimationSettingsItem: TMenuItem;
    //** @abstract(The "Save Animation Settings..." item; see
    //** SaveAnimationSettingsItemClick.)
    /// <summary>The "Save Animation Settings..." item; see
    /// <see cref="SaveAnimationSettingsItemClick"/>.</summary>
    SaveAnimationSettingsItem: TMenuItem;
    //** @abstract(The "Save Project..." item; see CreditsItemClick.)
    /// <summary>The "Save Project..." item; see <see cref="CreditsItemClick"/>.</summary>
    CreditsItem: TMenuItem;
    //** @abstract(The "Load Project..." item; see LoadCreditsItemClick.)
    /// <summary>The "Load Project..." item; see <see cref="LoadCreditsItemClick"/>.</summary>
    LoadCreditsItem: TMenuItem;
    //** @abstract(The "Grab" item; see GrabMenuItemClick.)
    /// <summary>The "Grab" item; see <see cref="GrabMenuItemClick"/>.</summary>
    GrabMenuItem: TMenuItem;
    //** @abstract(The "Save As Icon" item; see SaveAsIconMenuItemClick.)
    /// <summary>The "Save As Icon" item; see <see cref="SaveAsIconMenuItemClick"/>.</summary>
    SaveAsIconMenuItem: TMenuItem;
    //** @abstract(The "Background Settings..." item; see BackgroundSettingsMenuItemClick.)
    /// <summary>The "Background Settings..." item; see
    /// <see cref="BackgroundSettingsMenuItemClick"/>.</summary>
    BackgroundSettingsMenuItem: TMenuItem;
    //** @abstract(The "Settings..." item; see SettingsMenuItemClick.)
    /// <summary>The "Settings..." item; see <see cref="SettingsMenuItemClick"/>.</summary>
    SettingsMenuItem: TMenuItem;
    //** @abstract(Separator line in the File menu, above Exit.)
    /// <summary>Separator line in the File menu, above Exit.</summary>
    FileSeparatorItem: TMenuItem;
    //** @abstract(The "Exit" item; see ExitMenuItemClick.)
    /// <summary>The "Exit" item; see <see cref="ExitMenuItemClick"/>.</summary>
    ExitMenuItem: TMenuItem;
    //** @abstract(The "Model" menu: AnimationsUsedItem, the Animation... and
    //** BackgroundSettingsMenuItem settings, and DirectionsItem and OrientationItem.)
    /// <summary>The "Model" menu: <see cref="AnimationsUsedItem"/>, the Animation... and
    /// <see cref="BackgroundSettingsMenuItem"/> settings, and <see cref="DirectionsItem"/> and
    /// <see cref="OrientationItem"/>.</summary>
    ModelMenu: TMenuItem;
    //** @abstract(The "Animations Used..." item; see AnimationsUsedItemClick.)
    /// <summary>The "Animations Used..." item; see
    /// <see cref="AnimationsUsedItemClick"/>.</summary>
    AnimationsUsedItem: TMenuItem;
    //** @abstract(Separator line in the Model menu, above the settings items.)
    /// <summary>Separator line in the Model menu, above the settings items.</summary>
    ModelSettingsSeparatorItem: TMenuItem;
    //** @abstract(Separator line in the Model menu, above DirectionsItem.)
    /// <summary>Separator line in the Model menu, above
    /// <see cref="DirectionsItem"/>.</summary>
    ModelActionsSeparatorItem: TMenuItem;
    //** @abstract(The "Directions..." item; see DirectionsItemClick.)
    /// <summary>The "Directions..." item; see <see cref="DirectionsItemClick"/>.</summary>
    DirectionsItem: TMenuItem;
    //** @abstract(The "Orientation" item; disabled, as it does nothing yet.)
    /// <summary>The "Orientation" item; disabled, as it does nothing yet.</summary>
    OrientationItem: TMenuItem;
    //** @abstract(The "View" menu; holds CameraMenu.)
    /// <summary>The "View" menu; holds <see cref="CameraMenu"/>.</summary>
    ViewMenu: TMenuItem;
    //** @abstract(The "Camera" submenu of View, choosing how the camera angles are set.)
    //**
    //** Its items form one radio group: Variable, where the dials set the angles, and the
    //** fixed views Isometric, Pixel 2:1, 3/4 View, Head On, Top Down and Side View. Choosing
    //** an item clears every check in the submenu, sets the view, then checks that item. The
    //** checked item, and the dials' angles while Variable is checked, are kept in
    //** settings.json and restored at start-up.
    /// <summary>The "Camera" submenu of View, choosing how the camera angles are
    /// set.</summary>
    /// <remarks>Its items form one radio group: Variable, where the dials set the angles, and
    /// the fixed views Isometric, Pixel 2:1, 3/4 View, Head On, Top Down and Side View.
    /// Choosing an item clears every check in the submenu, sets the view, then checks that
    /// item. The checked item, and the dials' angles while Variable is checked, are kept in
    /// settings.json and restored at start-up.</remarks>
    CameraMenu: TMenuItem;
    //** @abstract(The line between CameraMenu and the View menu's on/off items.)
    /// <summary>The line between CameraMenu and the View menu's on/off items.</summary>
    ViewSeparatorItem: TMenuItem;
    //** @abstract(Shows or hides the model's bounding box; ticked at start-up.)
    //**
    //** Ticked, every model is drawn with Gorilla's ShowBoundingBox, an orange box round the
    //** bounds of its current pose. See ShowBoundsItemClick.
    /// <summary>Shows or hides the model's bounding box; ticked at start-up.</summary>
    /// <remarks>Ticked, every model is drawn with Gorilla's ShowBoundingBox, an orange box
    /// round the bounds of its current pose. See <see cref="ShowBoundsItemClick"/>.</remarks>
    ShowBoundsItem: TMenuItem;
    //** @abstract(Shows or hides the floor grid; ticked at start-up.)
    //**
    //** Ticked, every model is loaded with ShowModelGrid from Sprite3DGrid, which draws a
    //** shader grid of grey lines 1.0 apart on the model's floor, the lowest point of its own
    //** geometry. See ShowGridItemClick.
    /// <summary>Shows or hides the floor grid; ticked at start-up.</summary>
    /// <remarks>Ticked, every model is loaded with ShowModelGrid from Sprite3DGrid, which
    /// draws a shader grid of grey lines 1.0 apart on the model's floor, the lowest point of
    /// its own geometry. See <see cref="ShowGridItemClick"/>.</remarks>
    ShowGridItem: TMenuItem;
    //** @abstract(Shows or hides the model's X, Y and Z axes; ticked at start-up.)
    //**
    //** Ticked, every model is loaded with ShowModelAxes from Sprite3DAxes, which draws red,
    //** green and blue lines through its centre of rotation. See ShowAxesItemClick.
    /// <summary>Shows or hides the model's X, Y and Z axes; ticked at start-up.</summary>
    /// <remarks>Ticked, every model is loaded with ShowModelAxes from Sprite3DAxes, which
    /// draws red, green and blue lines through its centre of rotation. See
    /// <see cref="ShowAxesItemClick"/>.</remarks>
    ShowAxesItem: TMenuItem;
    //** @abstract(Shows or hides the Model Volume, the volume the model sweeps turning about
    //** its up axis; ticked at start-up.)
    //**
    //** Ticked, every model is loaded with ShowModelSweep from Sprite3DSweep, which works out
    //** the space the model's bounds pass through in a full turn about the line through its
    //** centre of rotation parallel to its Y axis, and draws it: the swept box in aqua, and
    //** the tube it holds, with the axis, in yellow. There is one volume for the rest pose,
    //** from the bounds as loaded, and one per animation, from the bounds of all its poses,
    //** read from the bounds cache or measured with TAnimationBoundsMeasurer as the model
    //** loads. Whichever animation the model plays, its volume is drawn; with none playing,
    //** the rest pose's. See ShowSweepItemClick.
    /// <summary>Shows or hides the Model Volume, the volume the model sweeps turning about its
    /// up axis; ticked at start-up.</summary>
    /// <remarks>Ticked, every model is loaded with ShowModelSweep from Sprite3DSweep, which
    /// works out the space the model's bounds pass through in a full turn about the line
    /// through its centre of rotation parallel to its Y axis, and draws it: the swept box in
    /// aqua, and the tube it holds, with the axis, in yellow. There is one volume for the rest
    /// pose, from the bounds as loaded, and one per animation, from the bounds of all its
    /// poses, read from the bounds cache or measured with TAnimationBoundsMeasurer as the
    /// model loads. Whichever animation the model plays, its volume is drawn; with none
    /// playing, the rest pose's. See <see cref="ShowSweepItemClick"/>.</remarks>
    ShowSweepItem: TMenuItem;
    //** @abstract(Shows or hides the Animation Volume, the combined swept volume; not ticked at
    //** start-up.)
    //**
    //** Ticked, the model gets ShowCombinedSweep from Sprite3DSweep: the volume swept turning
    //** about its up axis, joined over its rest pose and every animation ticked in Model,
    //** Animations Used. It is drawn only while the view frames it: while two or more
    //** animations in the Animations list are ticked for export, playing or paused. It is drawn
    //** in fuchsia and hot pink whatever animation plays, so it can be shown alongside
    //** ShowSweepItem's aqua and yellow. It is never drawn for a model with no animations, or
    //** none used, as it would only repeat the rest pose's volume. It is redrawn for each new
    //** model and whenever the animations used or the ticks change. See
    //** ShowCombinedSweepItemClick.
    /// <summary>Shows or hides the Animation Volume, the combined swept volume; not ticked at
    /// start-up.</summary>
    /// <remarks>Ticked, the model gets ShowCombinedSweep from Sprite3DSweep: the volume swept
    /// turning about its up axis, joined over its rest pose and every animation ticked in
    /// Model, Animations Used. It is drawn only while the view frames it: while two or more
    /// animations in the Animations list are ticked for export, playing or paused. It is drawn
    /// in fuchsia and hot pink whatever animation plays, so it can be shown alongside
    /// ShowSweepItem's aqua and yellow. It is never drawn for a model with no animations, or
    /// none used, as it would only repeat the rest pose's volume. It is redrawn for each new
    /// model and whenever the animations used or the ticks change. See
    /// <see cref="ShowCombinedSweepItemClick"/>.</remarks>
    ShowCombinedSweepItem: TMenuItem;
    //** @abstract(Switches the camera between orthographic and perspective projection.)
    //**
    //** Ticked, the camera is orthographic; see OrthographicItemClick.
    /// <summary>Switches the camera between orthographic and perspective projection.</summary>
    /// <remarks>Ticked, the camera is orthographic; see
    /// <see cref="OrthographicItemClick"/>.</remarks>
    OrthographicItem: TMenuItem;
    //** @abstract(The "Variable" view; see ViewVariableItemClick.)
    /// <summary>The "Variable" view; see <see cref="ViewVariableItemClick"/>.</summary>
    ViewVariableItem: TMenuItem;
    //** @abstract(The "Isometric" view, chosen at start-up when no other is saved; see
    //** ViewIsometricItemClick.)
    /// <summary>The "Isometric" view, chosen at start-up when no other is saved; see
    /// <see cref="ViewIsometricItemClick"/>.</summary>
    ViewIsometricItem: TMenuItem;
    //** @abstract(The "Pixel 2:1" view; see ViewPixel2To1ItemClick.)
    /// <summary>The "Pixel 2:1" view; see <see cref="ViewPixel2To1ItemClick"/>.</summary>
    ViewPixel2To1Item: TMenuItem;
    //** @abstract(The "3/4 View" view; see ViewThreeQuarterItemClick.)
    /// <summary>The "3/4 View" view; see <see cref="ViewThreeQuarterItemClick"/>.</summary>
    ViewThreeQuarterItem: TMenuItem;
    //** @abstract(The "Head On" view; see ViewHeadOnItemClick.)
    /// <summary>The "Head On" view; see <see cref="ViewHeadOnItemClick"/>.</summary>
    ViewHeadOnItem: TMenuItem;
    //** @abstract(The "Top Down" view; see ViewTopDownItemClick.)
    /// <summary>The "Top Down" view; see <see cref="ViewTopDownItemClick"/>.</summary>
    ViewTopDownItem: TMenuItem;
    //** @abstract(The "Side View" view; see ViewSideItemClick.)
    /// <summary>The "Side View" view; see <see cref="ViewSideItemClick"/>.</summary>
    ViewSideItem: TMenuItem;
    //** @abstract(A dark strip above AnimationListBox that holds AnimationsLabel and
    //** FramesLabel, so the titles stand out whatever the theme.)
    /// <summary>A dark strip above AnimationListBox that holds AnimationsLabel and FramesLabel,
    /// so the titles stand out whatever the theme.</summary>
    AnimationsHeader: TRectangle;
    //** @abstract(The "Animations" title: bold yellow on AnimationsHeader, at its left, inside
    //** the header's padding.)
    /// <summary>The "Animations" title: bold yellow on AnimationsHeader, at its left, inside
    /// the header's padding.</summary>
    AnimationsLabel: TLabel;
    //** @abstract(The "Frames" title: bold yellow on AnimationsHeader, at its right, inside the
    //** header's padding, over the frame counts in AnimationListBox.)
    /// <summary>The "Frames" title: bold yellow on AnimationsHeader, at its right, inside the
    /// header's padding, over the frame counts in AnimationListBox.</summary>
    FramesLabel: TLabel;
    //** @abstract(The model's animations, by name, after a first entry, @code(@(None@)), that
    //** stops any animation; see AnimationListBoxClick.)
    //**
    //** Only the animations ticked in Model, Animations Used are listed. Each entry shows, at
    //** its right, the number of frames saving it makes at the Model, Animation Settings frame
    //** rate. Choosing an entry plays it, whether by a click or by moving the selection with
    //** the Up and Down arrow keys; see AnimationListBoxChange. Right-clicking an entry
    //** selects and plays it and opens a pop-up menu that saves it as a sprite strip, a
    //** spritesheet or an animated GIF; see the unit description.
    /// <summary>The model's animations, by name, after a first entry, <c>(None)</c>, that stops
    /// any animation; see <see cref="AnimationListBoxClick"/>.</summary>
    /// <remarks>Only the animations ticked in Model, Animations Used are listed. Each entry
    /// shows, at its right, the number of frames saving it makes at the Model, Animation
    /// Settings frame rate. Choosing an entry plays it, whether by a click or by moving the
    /// selection with the Up and Down arrow keys; see <see cref="AnimationListBoxChange"/>.
    /// Right-clicking an entry selects and plays it and opens a pop-up menu that saves it as a
    /// sprite strip, a spritesheet or an animated GIF; see the unit description.</remarks>
    AnimationListBox: TListBox;
    //** @abstract(The "1/4 View" view; see ViewOneQuarterItemClick.)
    /// <summary>The "1/4 View" view; see <see cref="ViewOneQuarterItemClick"/>.</summary>
    ViewOneQuarterItem: TMenuItem;
    //** @abstract(The "Sqrt@(2@)" view; see ViewRoot2ItemClick.)
    /// <summary>The "Sqrt(2)" view; see <see cref="ViewRoot2ItemClick"/>.</summary>
    ViewRoot2Item: TMenuItem;
    //** @abstract(The "Golden Ratio" view; see ViewGoldenRatioItemClick.)
    /// <summary>The "Golden Ratio" view; see <see cref="ViewGoldenRatioItemClick"/>.</summary>
    ViewGoldenRatioItem: TMenuItem;
    //** @abstract(A separator line in the View, Camera menu, between groups of views.)
    /// <summary>A separator line in the View, Camera menu, between groups of views.</summary>
    CameraSeparatorItem1: TMenuItem;
    //** @abstract(A separator line in the View, Camera menu, between groups of views.)
    /// <summary>A separator line in the View, Camera menu, between groups of views.</summary>
    CameraSeparatorItem2: TMenuItem;
    //** @abstract(Sets up the viewport, light and camera, and picks the models folder.)
    //**
    //** The models folder comes from DefaultModelDir in Sprite3DHelpers: it is the library path
    //** on macOS, the home folder on Linux and @code('../../../') elsewhere; on Windows it is
    //** the current folder instead if that has a models subfolder. The handler creates a
    //** TGorillaViewport in AspectLayout, which FitViewportToAspect makes as large as fits
    //** there at the aspect ratio of the grab size, centred; a TSprite3DCamera with a 45-degree
    //** FOV, which becomes the viewport's camera; and a point light parented to the camera at
    //** its origin, so it sits where the camera is and points where it looks. The viewport runs
    //** at a fixed 60 frames per second without VSync. A TSprite3DBackground is put behind the
    //** viewport, showing the background kept in settings.json.
    //**
    //** The dials start at 0, then the camera view kept in settings.json is chosen, as its
    //** View, Camera item would choose it: a fixed view turns the dials to its angles and
    //** switches them off, and Variable turns them to the angles kept with it and leaves them
    //** on. Isometric is chosen when none is kept. Last, the View menu's five on/off items are
    //** ticked as settings.json says they were left, and applied, which also sets the
    //** projection.
    //**
    //** @param(Sender The form.)
    /// <summary>Sets up the viewport, light and camera, and picks the models folder.</summary>
    /// <remarks><para>The models folder comes from DefaultModelDir in Sprite3DHelpers: it is
    /// the library path on macOS, the home folder on Linux and <c>'../../../'</c> elsewhere; on
    /// Windows it is the current folder instead if that has a models subfolder. The handler
    /// creates a TGorillaViewport in AspectLayout, which FitViewportToAspect makes as large as
    /// fits there at the aspect ratio of the grab size, centred; a TSprite3DCamera with a
    /// 45-degree FOV, which becomes the viewport's camera; and a point light parented to the
    /// camera at its origin, so it sits where the camera is and points where it looks. The
    /// viewport runs at a fixed 60 frames per second without VSync. A TSprite3DBackground is
    /// put behind the viewport, showing the background kept in settings.json.</para> <para>The
    /// dials start at 0, then the camera view kept in settings.json is chosen, as its View,
    /// Camera item would choose it: a fixed view turns the dials to its angles and switches
    /// them off, and Variable turns them to the angles kept with it and leaves them on.
    /// Isometric is chosen when none is kept. Last, the View menu's five on/off items are
    /// ticked as settings.json says they were left, and applied, which also sets the
    /// projection.</para></remarks>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Loads the first model, the one the system asked to open or the default, and
    //** starts taking open requests.)
    //**
    //** If the application was started to open a model, for example by double-clicking a
    //** .glb or .gltf file in Explorer or Finder, that model is loaded; the files come from
    //** FileOpenRequests in Sprite3DOpenFiles, and the first one that is a model is used.
    //** Otherwise the default model, named in this handler, is loaded; change it there to
    //** start with a different one. From then on, files the system asks to open while the
    //** application runs, as macOS, iOS and Android can, replace the current model. Runs once,
    //** the first time the form is shown. Shows a message and loads nothing if the file is
    //** missing or cannot be read.
    //**
    //** @param(Sender The form.)
    /// <summary>Loads the first model, the one the system asked to open or the default, and
    /// starts taking open requests.</summary>
    /// <remarks>If the application was started to open a model, for example by double-clicking
    /// a .glb or .gltf file in Explorer or Finder, that model is loaded; the files come from
    /// FileOpenRequests in Sprite3DOpenFiles, and the first one that is a model is used.
    /// Otherwise the default model, named in this handler, is loaded; change it there to start
    /// with a different one. From then on, files the system asks to open while the application
    /// runs, as macOS, iOS and Android can, replace the current model. Runs once, the first
    /// time the form is shown. Shows a message and loads nothing if the file is missing or
    /// cannot be read.</remarks>
    /// <param name="Sender">The form.</param>
    procedure FormShow(Sender: TObject);
    //** @abstract(Stops taking open requests, saves the view state and frees the settings.)
    //**
    //** The checked View, Camera item, the dials' angles if that is Variable, and the ticks of
    //** the View menu's five on/off items are written to settings.json for the next session;
    //** a failed save is ignored, as no message can be shown here. Other settings are saved as
    //** soon as they change.
    //**
    //** @param(Sender The form.)
    /// <summary>Stops taking open requests, saves the view state and frees the
    /// settings.</summary>
    /// <remarks>The checked View, Camera item, the dials' angles if that is Variable, and the
    /// ticks of the View menu's five on/off items are written to settings.json for the next
    /// session; a failed save is ignored, as no message can be shown here. Other settings are
    /// saved as soon as they change.</remarks>
    /// <param name="Sender">The form.</param>
    procedure FormDestroy(Sender: TObject);
    //** @abstract(Asks before quitting while an export is under way.)
    //**
    //** While animations are being captured or exported, or files are still being written,
    //** the close is held and a dialog asks "Still exporting. Do you really want to quit?".
    //** No carries on with the export. Yes stops it, drops what is not yet saved, and closes
    //** the window; files already being written are finished first, so none is left half
    //** written. With nothing being exported the window closes at once.
    //**
    //** @param(Sender The form.)
    //**
    //** @param(CanClose Set to False while the question is open or was answered No.)
    /// <summary>Asks before quitting while an export is under way.</summary>
    /// <remarks>While animations are being captured or exported, or files are still being
    /// written, the close is held and a dialog asks "Still exporting. Do you really want to
    /// quit?". No carries on with the export. Yes stops it, drops what is not yet saved, and
    /// closes the window; files already being written are finished first, so none is left half
    /// written. With nothing being exported the window closes at once.</remarks>
    /// <param name="Sender">The form.</param>
    /// <param name="CanClose">Set to False while the question is open or was answered
    /// No.</param>
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    //** @abstract(Copies RollDial to the camera's Roll.)
    //**
    //** The dial value is wrapped into 0 to 360, without negating, shown in RollText and
    //** written to the camera. The model is not refitted; see FitModel.
    //**
    //** @param(Sender RollDial.)
    /// <summary>Copies RollDial to the camera's Roll.</summary>
    /// <remarks>The dial value is wrapped into 0 to 360, without negating, shown in RollText
    /// and written to the camera. The model is not refitted; see
    /// <see cref="FitModel"/>.</remarks>
    /// <param name="Sender">RollDial.</param>
    procedure RollDialChange(Sender: TObject);
    //** @abstract(Refits the camera to the model when the viewport changes size.)
    //**
    //** Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is
    //** loaded, or while View, Camera, Lock Camera is ticked.
    //**
    //** @param(Sender The TGorillaViewport.)
    /// <summary>Refits the camera to the model when the viewport changes size.</summary>
    /// <remarks>Assigned to the viewport's OnResize in FormCreate. Does nothing until a model
    /// is loaded, or while View, Camera, Lock Camera is ticked.</remarks>
    /// <param name="Sender">The TGorillaViewport.</param>
    procedure GorillaViewportResize(Sender: TObject);
    //** @abstract(Places the viewport again when AspectLayout changes size; see
    //** FitViewportToAspect.)
    //**
    //** @param(Sender AspectLayout.)
    /// <summary>Places the viewport again when AspectLayout changes size; see
    /// FitViewportToAspect.</summary>
    /// <param name="Sender">AspectLayout.</param>
    procedure AspectLayoutResize(Sender: TObject);
    //** @abstract(Ticks or unticks OrthographicItem, then switches the projection to match
    //** and refits the model.)
    //**
    //** Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in the
    //** form caption, and refits, since the two modes size the view differently. Does nothing
    //** while View, Camera, Lock Camera is ticked, when the item is disabled.
    //**
    //** @param(Sender OrthographicItem.)
    /// <summary>Ticks or unticks OrthographicItem, then switches the projection to match and
    /// refits the model.</summary>
    /// <remarks>Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in
    /// the form caption, and refits, since the two modes size the view differently. Does
    /// nothing while View, Camera, Lock Camera is ticked, when the item is disabled.</remarks>
    /// <param name="Sender">OrthographicItem.</param>
    procedure OrthographicItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks ShowAxesItem, then adds or removes the model's axes to
    //** match.)
    //**
    //** Only the tick changes until a model is loaded.
    //**
    //** @param(Sender ShowAxesItem.)
    /// <summary>Ticks or unticks ShowAxesItem, then adds or removes the model's axes to
    /// match.</summary>
    /// <remarks>Only the tick changes until a model is loaded.</remarks>
    /// <param name="Sender">ShowAxesItem.</param>
    procedure ShowAxesItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks ShowBoundsItem, then shows or hides the model's bounding
    //** box to match.)
    //**
    //** Only the tick changes until a model is loaded.
    //**
    //** @param(Sender ShowBoundsItem.)
    /// <summary>Ticks or unticks ShowBoundsItem, then shows or hides the model's bounding box
    /// to match.</summary>
    /// <remarks>Only the tick changes until a model is loaded.</remarks>
    /// <param name="Sender">ShowBoundsItem.</param>
    procedure ShowBoundsItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks ShowSweepItem, then adds or removes the model's swept
    //** volume to match.)
    //**
    //** Only the tick changes until a model is loaded.
    //**
    //** @param(Sender ShowSweepItem.)
    /// <summary>Ticks or unticks ShowSweepItem, then adds or removes the model's swept volume
    /// to match.</summary>
    /// <remarks>Only the tick changes until a model is loaded.</remarks>
    /// <param name="Sender">ShowSweepItem.</param>
    procedure ShowSweepItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks ShowCombinedSweepItem, then adds or removes the combined
    //** swept volume to match.)
    //**
    //** Only the tick changes until a model is loaded.
    //**
    //** @param(Sender ShowCombinedSweepItem.)
    /// <summary>Ticks or unticks ShowCombinedSweepItem, then adds or removes the combined swept
    /// volume to match.</summary>
    /// <remarks>Only the tick changes until a model is loaded.</remarks>
    /// <param name="Sender">ShowCombinedSweepItem.</param>
    procedure ShowCombinedSweepItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks ShowGridItem, then adds or removes the floor grid to
    //** match.)
    //**
    //** Only the tick changes until a model is loaded.
    //**
    //** @param(Sender ShowGridItem.)
    /// <summary>Ticks or unticks ShowGridItem, then adds or removes the floor grid to
    /// match.</summary>
    /// <remarks>Only the tick changes until a model is loaded.</remarks>
    /// <param name="Sender">ShowGridItem.</param>
    procedure ShowGridItemClick(Sender: TObject);
    //** @abstract(Lets the user pick a model file and loads it in place of the current one.)
    //**
    //** Shows OpenDialog1 and passes the chosen file to SwitchModel, which loads it behind a
    //** progress dialog with Abort and then puts it in place of the old model, with the current
    //** camera angles and fit. Nothing changes if either dialog is cancelled or aborted, or if
    //** the file fails to load, which SwitchModel reports.
    //**
    //** @param(Sender OpenModelMenuItem.)
    /// <summary>Lets the user pick a model file and loads it in place of the current
    /// one.</summary>
    /// <remarks>Shows OpenDialog1 and passes the chosen file to SwitchModel, which loads it
    /// behind a progress dialog with Abort and then puts it in place of the old model, with the
    /// current camera angles and fit. Nothing changes if either dialog is cancelled or aborted,
    /// or if the file fails to load, which SwitchModel reports.</remarks>
    /// <param name="Sender">OpenModelMenuItem.</param>
    procedure OpenModelMenuItemClick(Sender: TObject);
    //** @abstract(Saves the Animations list as it stands to a JSON file.)
    //**
    //** Asks where, in a save dialog opening in the model's folder, with the name
    //** @code(<model>_animations.json). The file holds every entry of the list, in order,
    //** with its tick and any frame count typed in for it, and the entry selected:
    //**
    //** @preformatted(
    //** {
    //**   "format": "Sprite3D animation settings",
    //**   "version": 1,
    //**   "model": "hero.glb",
    //**   "selected": "walk",
    //**   "animations": [
    //**     { "name": "(None)", "checked": false },
    //**     { "name": "walk", "checked": true, "frames": 24 },
    //**     { "name": "run", "checked": true }
    //**   ]
    //** }
    //** )
    //**
    //** @code(frames) is there only for a count typed in. Desktop only, with a model loaded
    //** and nothing being exported.
    //**
    //** @param(Sender SaveAnimationSettingsItem.)
    /// <summary>Saves the Animations list as it stands to a JSON file.</summary>
    /// <remarks>Asks where, in a save dialog opening in the model's folder, with the name
    /// <c>&lt;model&gt;_animations.json</c>. The file holds <c>format</c> ("Sprite3D animation
    /// settings"), <c>version</c>, <c>model</c>, <c>selected</c>, the entry selected, and
    /// <c>animations</c>, every entry of the list, in order, each with its <c>name</c>, its
    /// tick as <c>checked</c>, and <c>frames</c>, only for a count typed in. Desktop only,
    /// with a model loaded and nothing being exported.</remarks>
    /// <param name="Sender">SaveAnimationSettingsItem.</param>
    procedure SaveAnimationSettingsItemClick(Sender: TObject);
    //** @abstract(Loads a file saved by SaveAnimationSettingsItemClick and applies it to the
    //** Animations list.)
    //**
    //** The animations the file lists that the model has become the animations used, as
    //** Model, Animations Used would make them, in the model's order; their ticks and frame
    //** counts are set as the file says, every other count going back to the one the frame
    //** rate gives; and the entry the file has selected is selected and played. Animations
    //** the file names that the model does not have are left out and reported. A file that
    //** is not one of these, or that names none of the model's animations, changes nothing.
    //** Desktop only, with a model loaded and nothing being exported.
    //**
    //** @param(Sender LoadAnimationSettingsItem.)
    /// <summary>Loads a file saved by SaveAnimationSettingsItemClick and applies it to the
    /// Animations list.</summary>
    /// <remarks>The animations the file lists that the model has become the animations used,
    /// as Model, Animations Used would make them, in the model's order; their ticks and frame
    /// counts are set as the file says, every other count going back to the one the frame rate
    /// gives; and the entry the file has selected is selected and played. Animations the file
    /// names that the model does not have are left out and reported. A file that is not one
    /// of these, or that names none of the model's animations, changes nothing. Desktop only,
    /// with a model loaded and nothing being exported.</remarks>
    /// <param name="Sender">LoadAnimationSettingsItem.</param>
    procedure LoadAnimationSettingsItemClick(Sender: TObject);
    //** @abstract(File, Save Project: edits the creator credits, keeps them for every export's
    //** metadata, and saves them in a project file.)
    //**
    //** The dialog, TCreditsForm, takes the creator, modeller and artist, each with a URL, and
    //** the day the project started. On OK the credits go into the @code(meta) section of
    //** every metadata file saved from then on, and a save dialog asks where to keep them, as
    //** a project file with the extension PROJECT_FILE_EXTENSION, opening at the project
    //** last saved or loaded, or beside the model. The project file holds the credits, the
    //** model's full path, the directions of Model, Directions, the Animations list and the
    //** export choices; see SaveProjectFile. Cancelling the save keeps the credits all the
    //** same. On Android and iOS, which have no save dialog, the credits are kept for the
    //** session only.
    //**
    //** @param(Sender CreditsItem.)
    /// <summary>File, Save Project: edits the creator credits, keeps them for every export's
    /// metadata, and saves them in a project file.</summary>
    /// <remarks>The dialog, TCreditsForm, takes the creator, modeller and artist, each with a
    /// URL, and the day the project started. On OK the credits go into the <c>meta</c>
    /// section of every metadata file saved from then on, and a save dialog asks where to
    /// keep them, as a project file with the extension PROJECT_FILE_EXTENSION, opening at the
    /// project last saved or loaded, or beside the model. The project file holds the credits,
    /// the model's full path, the directions of Model, Directions, the Animations list and the
    /// export choices; see SaveProjectFile. Cancelling the save keeps the credits all the
    /// same. On Android and iOS, which have no save dialog, the credits are kept for the
    /// session only.</remarks>
    /// <param name="Sender">CreditsItem.</param>
    procedure CreditsItemClick(Sender: TObject);
    //** @abstract(File, Load Project: loads a project file and applies it; see
    //** LoadProjectFile.)
    //**
    //** @param(Sender LoadCreditsItem.)
    /// <summary>File, Load Project: loads a project file and applies it; see
    /// LoadProjectFile.</summary>
    /// <param name="Sender">LoadCreditsItem.</param>
    procedure LoadCreditsItemClick(Sender: TObject);
    //** @abstract(Renders the view off screen and saves it as the next grabNNN.png.)
    //**
    //** If no usable SaveFolder is known, because none has been chosen yet or the stored one no
    //** longer exists, a "Save Location" folder dialog asks for it first, and SaveFolder is set
    //** to the choice and saved; if the dialog is cancelled nothing is grabbed. The image comes
    //** from Offscreen at its Width and Height, the grab size set in File, Settings, with the
    //** camera refitted by FitToBounds for that size so the model fills it, unless View,
    //** Camera, Lock Camera is ticked, when the view is grabbed as it stands, and is saved a
    //** frame later as grab001.png, grab002.png and so on: the number starts at 1 when the
    //** folder is chosen and goes up by one for every file saved, skipping any name already in
    //** the folder, so earlier grabs are never overwritten. Each saved file is logged in
    //** DebugMemo; a failed grab or save is reported with a message. A click while the previous
    //** grab is still under way is ignored.
    //**
    //** @param(Sender GrabMenuItem.)
    /// <summary>Renders the view off screen and saves it as the next grabNNN.png.</summary>
    /// <remarks>If no usable SaveFolder is known, because none has been chosen yet or the
    /// stored one no longer exists, a "Save Location" folder dialog asks for it first, and
    /// SaveFolder is set to the choice and saved; if the dialog is cancelled nothing is
    /// grabbed. The image comes from Offscreen at its Width and Height, the grab size set in
    /// File, Settings, with the camera refitted by FitToBounds for that size so the model fills
    /// it, unless View, Camera, Lock Camera is ticked, when the view is grabbed as it stands,
    /// and is saved a frame later as grab001.png, grab002.png and so on: the number starts
    /// at 1 when the folder is chosen and goes up by one for every file saved, skipping any
    /// name already in the folder, so earlier grabs are never overwritten. Each saved file is
    /// logged in DebugMemo; a failed grab or save is reported with a message. A click while the
    /// previous grab is still under way is ignored.</remarks>
    /// <param name="Sender">GrabMenuItem.</param>
    procedure GrabMenuItemClick(Sender: TObject);
    //** @abstract(Renders the view at every icon size and saves it as one icon file.)
    //**
    //** First asks for the file with SaveIconDialog, which opens in the folder the last icon
    //** was saved in, kept in settings.json, and offers only the .ico type; nothing happens
    //** if it is cancelled. Android and iOS have no save dialog, so there the icon goes to the
    //** next free iconNNN.ico in the Grabs folder. Then Offscreen renders the view once for
    //** each of the format's sizes, 16, 20, 24, 32, 40, 48, 64 and 256 for .ico, each with
    //** the camera fitted to it as for File, Grab, and the images are written together. The
    //** saved file is logged in DebugMemo; a failure is reported with a message. A click while
    //** a grab is under way is ignored.
    //**
    //** @param(Sender SaveAsIconMenuItem.)
    /// <summary>Renders the view at every icon size and saves it as one icon file.</summary>
    /// <remarks>First asks for the file with SaveIconDialog, which opens in the folder the last
    /// icon was saved in, kept in settings.json, and offers only the .ico type; nothing happens
    /// if it is cancelled. Android and iOS have no save dialog, so there the icon goes to the
    /// next free iconNNN.ico in the Grabs folder. Then Offscreen renders the view once for each
    /// of the format's sizes, 16, 20, 24, 32, 40, 48, 64 and 256 for .ico, each with the camera
    /// fitted to it as for File, Grab, and the images are written together. The saved file is
    /// logged in DebugMemo; a failure is reported with a message. A click while a grab is under
    /// way is ignored.</remarks>
    /// <param name="Sender">SaveAsIconMenuItem.</param>
    procedure SaveAsIconMenuItemClick(Sender: TObject);
    //** @abstract(Opens the Background Settings dialog and applies what is chosen.)
    //**
    //** The dialog, TBackgroundSettingsForm, opens modally, centred on this form, showing the
    //** background in use. Every change is shown in the viewport at once. If it is closed with
    //** OK, the chosen background is kept, used for grabs and icons but not animation exports,
    //** and saved to settings.json; Cancel puts back the background in use. On Android and iOS,
    //** where a dialog cannot block, it opens as an ordinary form and OK is applied when it
    //** closes.
    //**
    //** @param(Sender BackgroundSettingsMenuItem.)
    /// <summary>Opens the Background Settings dialog and applies what is chosen.</summary>
    /// <remarks>The dialog, TBackgroundSettingsForm, opens modally, centred on this form,
    /// showing the background in use. Every change is shown in the viewport at once. If it is
    /// closed with OK, the chosen background is kept, used for grabs and icons but not
    /// animation exports, and saved to settings.json; Cancel puts back the background in use.
    /// On Android and iOS, where a dialog cannot block, it opens as an ordinary form and OK is
    /// applied when it closes.</remarks>
    /// <param name="Sender">BackgroundSettingsMenuItem.</param>
    procedure BackgroundSettingsMenuItemClick(Sender: TObject);
    //** @abstract(Opens the Settings dialog and applies what is chosen.)
    //**
    //** The dialog, TGeneralSettingsForm, opens modally, centred on this form, showing the
    //** settings as they stand, with Open With, the default application and the GPU read from
    //** the system. On OK the file associations are changed as chosen, the theme is applied
    //** at once, the GPU preference is stored for the next start, and everything is saved to
    //** settings.json; anything the user needs to know, such as a failure or the need to
    //** restart, is reported in a message. Cancel changes nothing. On Android and iOS, where a
    //** dialog cannot block, it opens as an ordinary form and OK is applied when it closes.
    //**
    //** @param(Sender SettingsMenuItem.)
    /// <summary>Opens the Settings dialog and applies what is chosen.</summary>
    /// <remarks>The dialog, TGeneralSettingsForm, opens modally, centred on this form, showing
    /// the settings as they stand, with Open With, the default application and the GPU read
    /// from the system. On OK the file associations are changed as chosen, the theme is applied
    /// at once, the GPU preference is stored for the next start, and everything is saved to
    /// settings.json; anything the user needs to know, such as a failure or the need to
    /// restart, is reported in a message. Cancel changes nothing. On Android and iOS, where a
    /// dialog cannot block, it opens as an ordinary form and OK is applied when it
    /// closes.</remarks>
    /// <param name="Sender">SettingsMenuItem.</param>
    procedure SettingsMenuItemClick(Sender: TObject);
    //** @abstract(Closes the application.)
    //**
    //** Closes the main form, which ends the application in the normal way, so the form and
    //** everything it owns are freed as usual.
    //**
    //** @param(Sender ExitMenuItem.)
    /// <summary>Closes the application.</summary>
    /// <remarks>Closes the main form, which ends the application in the normal way, so the form
    /// and everything it owns are freed as usual.</remarks>
    /// <param name="Sender">ExitMenuItem.</param>
    procedure ExitMenuItemClick(Sender: TObject);
    //** @abstract(Opens the Variable camera dialog, where dials set the angles.)
    //**
    //** The dialog, TOrbitalSettingsForm, shows the current angles, distance factor and pan,
    //** and every change is shown in the viewport at once. OK keeps the changes; Cancel puts
    //** the camera back as it was. Either way the View checks are cleared and Variable is
    //** checked. While the form is being created, as when the Variable view is restored at
    //** start-up, no dialog is shown and only the check changes.
    //**
    //** @param(Sender ViewVariableItem.)
    /// <summary>Opens the Variable camera dialog, where dials set the angles.</summary>
    /// <remarks>The dialog, TOrbitalSettingsForm, shows the current angles, distance factor and
    /// pan, and every change is shown in the viewport at once. OK keeps the changes; Cancel
    /// puts the camera back as it was. Either way the View checks are cleared and Variable is
    /// checked. While the form is being created, as when the Variable view is restored at
    /// start-up, no dialog is shown and only the check changes.</remarks>
    /// <param name="Sender">ViewVariableItem.</param>
    procedure ViewVariableItemClick(Sender: TObject);
    //** @abstract(Sets the isometric view and fixes it.)
    //**
    //** Clears every View check, sets the inclination to ArcTan@(1/Sqrt@(2@)@), about 35.264
    //** degrees, the true isometric elevation, the azimuth to 45 and the roll to 0, as shown on
    //** the readouts, turns the dials to match and switches them off, refits the model for the
    //** new view, then checks the Isometric item. As with the dial, the azimuth reaches the
    //** camera reversed. The other fixed views work the same way with their own inclination.
    //**
    //** @param(Sender ViewIsometricItem.)
    /// <summary>Sets the isometric view and fixes it.</summary>
    /// <remarks>Clears every View check, sets the inclination to ArcTan(1/Sqrt(2)), about
    /// 35.264 degrees, the true isometric elevation, the azimuth to 45 and the roll to 0, as
    /// shown on the readouts, turns the dials to match and switches them off, refits the model
    /// for the new view, then checks the Isometric item. As with the dial, the azimuth reaches
    /// the camera reversed. The other fixed views work the same way with their own
    /// inclination.</remarks>
    /// <param name="Sender">ViewIsometricItem.</param>
    procedure ViewIsometricItemClick(Sender: TObject);
    //** @abstract(Moves the camera out by the slider's factor; test only.)
    //**
    //** In perspective mode the camera's Distance becomes the fitted distance times the
    //** factor; in orthographic mode, where distance does not change the size, OrthoHeight
    //** is scaled instead. The factor is kept when the model is refitted.
    //**
    //** @param(Sender DistanceTrack.)
    /// <summary>Moves the camera out by the slider's factor; test only.</summary>
    /// <remarks>In perspective mode the camera's Distance becomes the fitted distance times
    /// the factor; in orthographic mode, where distance does not change the size, OrthoHeight
    /// is scaled instead. The factor is kept when the model is refitted.</remarks>
    /// <param name="Sender">DistanceTrack.</param>
    procedure DistanceTrackChange(Sender: TObject);
    //** @abstract(Sets the pixel-art 2:1 view and fixes it.)
    //**
    //** As View, Camera, Isometric, but with the inclination ArcTan@(1/2@), about 26.565
    //** degrees, at which lines on the floor run 2 pixels across for each pixel up, as in 2:1
    //** pixel art.
    //**
    //** @param(Sender ViewPixel2To1Item.)
    /// <summary>Sets the pixel-art 2:1 view and fixes it.</summary>
    /// <remarks>As View, Camera, Isometric, but with the inclination ArcTan(1/2), about 26.565
    /// degrees, at which lines on the floor run 2 pixels across for each pixel up, as in 2:1
    /// pixel art.</remarks>
    /// <param name="Sender">ViewPixel2To1Item.</param>
    procedure ViewPixel2To1ItemClick(Sender: TObject);
    //** @abstract(Sets the 3/4 view and fixes it.)
    //**
    //** The angle of military projection: inclination 45 degrees at azimuth 45. The projection
    //** is applied again as it stands, so View, Orthographic gives the flat look of 3/4-view
    //** game art; the view no longer switches it on by itself.
    //**
    //** @param(Sender ViewThreeQuarterItem.)
    /// <summary>Sets the 3/4 view and fixes it.</summary>
    /// <remarks>The angle of military projection: inclination 45 degrees at azimuth 45. The
    /// projection is applied again as it stands, so View, Orthographic gives the flat look of
    /// 3/4-view game art; the view no longer switches it on by itself.</remarks>
    /// <param name="Sender">ViewThreeQuarterItem.</param>
    procedure ViewThreeQuarterItemClick(Sender: TObject);
    //** @abstract(Sets the head-on view and fixes it.)
    //**
    //** Inclination 0 and azimuth 0: level with the model, looking along its Z axis.
    //**
    //** @param(Sender ViewHeadOnItem.)
    /// <summary>Sets the head-on view and fixes it.</summary>
    /// <remarks>Inclination 0 and azimuth 0: level with the model, looking along its Z
    /// axis.</remarks>
    /// <param name="Sender">ViewHeadOnItem.</param>
    procedure ViewHeadOnItemClick(Sender: TObject);
    //** @abstract(Sets the top-down view and fixes it.)
    //**
    //** Inclination 90 and azimuth 0: straight down onto the model.
    //**
    //** @param(Sender ViewTopDownItem.)
    /// <summary>Sets the top-down view and fixes it.</summary>
    /// <remarks>Inclination 90 and azimuth 0: straight down onto the model.</remarks>
    /// <param name="Sender">ViewTopDownItem.</param>
    procedure ViewTopDownItemClick(Sender: TObject);
    //** @abstract(Sets the side view and fixes it.)
    //**
    //** Inclination 0 and azimuth 90: level with the model, from the side, a quarter turn
    //** from View, Camera, Head On.
    //**
    //** @param(Sender ViewSideItem.)
    /// <summary>Sets the side view and fixes it.</summary>
    /// <remarks>Inclination 0 and azimuth 90: level with the model, from the side, a quarter
    /// turn from View, Camera, Head On.</remarks>
    /// <param name="Sender">ViewSideItem.</param>
    procedure ViewSideItemClick(Sender: TObject);
    //** @abstract(Plays the chosen animation, or stops any for @code(@(None@)).)
    //**
    //** A click that moved the selection has already been played by AnimationListBoxChange,
    //** so it is not played twice; a click on the entry already selected plays it again.
    //** Ignored while an animation is being saved, which needs the animation it started.
    //**
    //** @param(Sender AnimationListBox.)
    /// <summary>Plays the chosen animation, or stops any for <c>(None)</c>.</summary>
    /// <remarks>A click that moved the selection has already been played by
    /// <see cref="AnimationListBoxChange"/>, so it is not played twice; a click on the entry
    /// already selected plays it again. Ignored while an animation is being saved, which needs
    /// the animation it started.</remarks>
    /// <param name="Sender">AnimationListBox.</param>
    procedure AnimationListBoxClick(Sender: TObject);
    //** @abstract(Plays the newly selected animation, or stops any for @code(@(None@)),
    //** whatever moved the selection.)
    //**
    //** Runs whenever the selection moves: the Up and Down arrow keys, Home, End and the page
    //** keys, a click on another entry, or code setting ItemIndex. So stepping through the list
    //** with the keys plays each animation as a click does. Ignored while an animation is
    //** being saved, and when the list is emptied for another model.
    //**
    //** @param(Sender AnimationListBox.)
    /// <summary>Plays the newly selected animation, or stops any for <c>(None)</c>, whatever
    /// moved the selection.</summary>
    /// <remarks>Runs whenever the selection moves: the Up and Down arrow keys, Home, End and
    /// the page keys, a click on another entry, or code setting ItemIndex. So stepping through
    /// the list with the keys plays each animation as a click does. Ignored while an animation
    /// is being saved, and when the list is emptied for another model.</remarks>
    /// <param name="Sender">AnimationListBox.</param>
    procedure AnimationListBoxChange(Sender: TObject);
    //** @abstract(Opens the Animations Used dialog, and on OK lists only the animations ticked
    //** there and refits to their swept volume.)
    //**
    //** The dialog lists every animation of the model, ticked if it is used now, with its own
    //** swept volume as a percentage of the combined one, measuring the animations first if
    //** they have not been; Cancel changes nothing. On OK the animations list is rebuilt with
    //** only those ticked, keeping the selection if it is still listed; if the animation
    //** playing is left out, the model is shown at rest, as @code(@(None@)) does. The model is
    //** then refitted, to the swept volume joined over the rest pose and the animations used.
    //** Does nothing without a model, or while an animation is being saved. On Android and iOS
    //** the dialog does not block, and the choice is applied when it closes.
    //**
    //** @param(Sender AnimationsUsedItem.)
    /// <summary>Opens the Animations Used dialog, and on OK lists only the animations ticked
    /// there and refits to their swept volume.</summary>
    /// <remarks>The dialog lists every animation of the model, ticked if it is used now, with
    /// its own swept volume as a percentage of the combined one, measuring the animations first
    /// if they have not been; Cancel changes nothing. On OK the animations list is rebuilt with
    /// only those ticked, keeping the selection if it is still listed; if the animation playing
    /// is left out, the model is shown at rest, as <c>(None)</c> does. The model is then
    /// refitted, to the swept volume joined over the rest pose and the animations used. Does
    /// nothing without a model, or while an animation is being saved. On Android and iOS the
    /// dialog does not block, and the choice is applied when it closes.</remarks>
    /// <param name="Sender">AnimationsUsedItem.</param>
    procedure AnimationsUsedItemClick(Sender: TObject);
    //** @abstract(Opens the Directions dialog, and on OK keeps what is chosen there.)
    //**
    //** The dialog, TDirectionsForm, shows a compass with a marker for each direction, the
    //** first in red, and sets how many directions there are, the first one's bearing, the
    //** order they are taken in, clockwise, anticlockwise or any order clicked with Change
    //** Order, and whether the dial is locked to steps of one direction, as kept in
    //** settings.json; Export and Import write them to and read them from a JSON file of their
    //** own, in DirectionsFolder. OK keeps and saves them; Cancel changes nothing. The rest of
    //** the program reads the result with DirectionBearings in the settings. On Android and iOS
    //** the dialog does not block, and the choice is kept when it closes.
    //**
    //** @param(Sender DirectionsItem.)
    /// <summary>Opens the Directions dialog, and on OK keeps what is chosen there.</summary>
    /// <remarks>The dialog, TDirectionsForm, shows a compass with a marker for each direction,
    /// the first in red, and sets how many directions there are, the first one's bearing, the
    /// order they are taken in, clockwise, anticlockwise or any order clicked with Change
    /// Order, and whether the dial is locked to steps of one direction, as kept in
    /// settings.json; Export and Import write them to and read them from a JSON file of their
    /// own, in DirectionsFolder. OK keeps and saves them; Cancel changes nothing. The rest of
    /// the program reads the result with DirectionBearings in the settings. On Android and iOS
    /// the dialog does not block, and the choice is kept when it closes.</remarks>
    /// <param name="Sender">DirectionsItem.</param>
    procedure DirectionsItemClick(Sender: TObject);
    //** @abstract(Sets the 1/4 view and fixes it.)
    //**
    //** Inclination 22.5 degrees at azimuth 45: a lower look than View, Camera, 3/4 View. The
    //** projection is applied again as it stands, and the model refitted.
    //**
    //** @param(Sender ViewOneQuarterItem.)
    /// <summary>Sets the 1/4 view and fixes it.</summary>
    /// <remarks>Inclination 22.5 degrees at azimuth 45: a lower look than View, Camera, 3/4
    /// View. The projection is applied again as it stands, and the model refitted.</remarks>
    /// <param name="Sender">ViewOneQuarterItem.</param>
    procedure ViewOneQuarterItemClick(Sender: TObject);
    //** @abstract(Sets the Sqrt@(2@) view and fixes it.)
    //**
    //** As View, Camera, Isometric, but with the inclination ArcTan@(Sqrt@(2@)@), about 54.736
    //** degrees, the complement of the isometric angle.
    //**
    //** @param(Sender ViewRoot2Item.)
    /// <summary>Sets the Sqrt(2) view and fixes it.</summary>
    /// <remarks>As View, Camera, Isometric, but with the inclination ArcTan(Sqrt(2)), about
    /// 54.736 degrees, the complement of the isometric angle.</remarks>
    /// <param name="Sender">ViewRoot2Item.</param>
    procedure ViewRoot2ItemClick(Sender: TObject);
    //** @abstract(Sets the golden-ratio view and fixes it.)
    //**
    //** As View, Camera, Isometric, but with the inclination ArcTan@(1.618...@), the golden
    //** ratio, about 58.283 degrees.
    //**
    //** @param(Sender ViewGoldenRatioItem.)
    /// <summary>Sets the golden-ratio view and fixes it.</summary>
    /// <remarks>As View, Camera, Isometric, but with the inclination ArcTan(1.618...), the
    /// golden ratio, about 58.283 degrees.</remarks>
    /// <param name="Sender">ViewGoldenRatioItem.</param>
    procedure ViewGoldenRatioItemClick(Sender: TObject);
  private
    { Private declarations }
    FSetupComplete: Boolean;
    FAzimuth: Single;
    FRoll: Single;
    FPolarAngle: Single;
    FFactor: Single;
    // Camera Distance and OrthoHeight from the last fit, before the test
    // distance factor is applied
    FFitDistance: Single;
    FFitOrthoHeight: Single;
    GorillaViewport: TGorillaViewport;
    GorillaLight: TGorillaLight;
    GorillaModel: TGorillaModel;
    GorillaCamera: TSprite3DCamera;
    FOffscreen: TSprite3DOffscreen;
    // Number for the next grab file; back to 1 whenever SaveFolder is chosen
    FGrabNumber: Integer;
    // Settings kept between sessions in settings.json
    FSettings: TSprite3DAppSettings;
    // True once FormShow has loaded the first model
    FStarted: Boolean;
    // The viewport's background: a 2D control behind the transparent viewport
    FBackground: TSprite3DBackground;
    FModelBox: TBoundingBox;   // the model's own bounds, measured as loaded
    // Each animation's bounds over all its poses, for the swept volume:
    // read from the bounds cache or measured while the model loads
    FAnimationBounds: TArray<TAnimationBounds>;
    FAnimationBoundsMeasured: Boolean;
    FModelFile: String;         // the model loaded, for the bounds cache
    // The load under way, if any: what stage it is at, driven by FLoadTimer
    // a tick at a time so the dialog stays responsive. The new model is
    // built beside the old one, which is untouched until the new one is
    // ready, so an abort or a failure leaves everything as it was.
    FLoadStage: TModelLoadStage;
    FLoadTimer: TTimer;
    FLoadDialog: TModelLoadForm;
    FLoadFile: String;
    FLoadRead: IModelFileRead;
    FLoadModel: TGorillaModel;
    FLoadAnims: TArray<String>;
    FLoadBox: TBoundingBox;
    FLoadBounds: TArray<TAnimationBounds>;
    FMeasurer: TAnimationBoundsMeasurer;   // the new model's, while measured
    FLoadAborted: Boolean;
    FLoadError: String;      // shown once the dialog has closed
    FPendingModel: String;   // asked for during a load; loaded after it
    // Covers the view while no model is loaded, saying how to load one
    FNoModelPanel: TPanel;
    // Saves under way on worker threads; the form waits for them as it closes
    FSaveTasks: TArray<ITask>;
    // The MP4 entry of the animation pop-up menu, enabled once the video
    // libraries are found to load
    FMp4Item: TMenuItem;
    // Set when AnimationListBoxChange has played FChangePlayedIndex, so the
    // click that moved the selection there does not play it a second time
    FChangePlayed: Boolean;
    FChangePlayedIndex: Integer;
    // Every animation of the loaded model, sorted, and those Model,
    // Animations Used ticks: only these are listed and count towards the
    // swept volume the camera frames. All, for a new model.
    FAnimationNames: TArray<String>;
    FUsedAnimations: TArray<String>;
    // The orbit centre before a shifted overscan drawing slid it, while slid
    FShiftedCentre: TPoint3D;
    FViewShifted: Boolean;
    // Whether Model, Animation Settings's Overscan is ticked; kept for this session
    // only, so overscan always starts off
    FOverscanOn: Boolean;
    // True while AnimationListBox is refilled, so its OnChange plays nothing
    FRebuildingList: Boolean;
    // Ticks are being set by SetEntryChecks, which keeps the selection: a
    // change of it meanwhile plays nothing
    FKeepingSelection: Boolean;
    // Quitting mid-export was confirmed: the next close goes ahead
    FQuitConfirmed: Boolean;
    // The on-screen framing, kept while a grab is fitted to its target
    FSavedFraming: TSprite3DFraming;
    // The camera pan, applied on top of every fit while FPanEnabled
    FPanEnabled: Boolean;
    FPanX: Single;
    FPanZ: Single;
    // The orbit centre from the last fit, before the pan is added
    FFitCenter: TPoint3D;
    FFitted: Boolean;
    // The animation list's pop-up menu: Save as sprite strip, Save as
    // Spritesheet, Save as AniGif
    FAnimationPopup: TPopupMenu;
    // Model, Animation Settings...: the frame rate saved animations use
    FAnimationSettingsItem: TMenuItem;
    // Keeps the downloaded OpenH264 in step with openh264.json
    FOpenH264Update: TSprite3DLibraryUpdate;
    // View, Camera, Lock Camera, and the line above it
    FLockCameraItem: TMenuItem;
    FLockSeparatorItem: TMenuItem;
    // True while a grab or a capture has its own framing on the camera,
    // which must be put back even if the camera is locked meanwhile
    FGrabFramed: Boolean;
    // The helpers a grab hid, to be shown again after it: the bounding box,
    // and the axes, grid and volume wireframes
    FGrabHidden: TArray<TControl3D>;
    FGrabHidBounds: Boolean;
    FGrabHidAxes: TModelAxes;
    FGrabHidGrid: TModelGrid;
    FCaptureFramed: Boolean;
    // The camera's distance from its orbit centre, and its orthographic
    // height, as the last capture was framed, for the metadata's camera: a
    // batch frames every capture alike, and an atlas's metadata is written
    // after the camera is put back
    FCaptureDistance: Single;
    FCaptureOrthoHeight: Single;
    // The capture under way, or nil; it frees itself when it reports
    FCapture: TSprite3DFrameCapture;
    // The on-screen framing, put back when a capture ends
    FCaptureRestore: TSprite3DFraming;
    // The viewport was resized during the capture: refit when it ends
    FRefitAfterCapture: Boolean;
    // The orbit centre before SnapCaptureOrigin slid the view, put back by
    // EndCapture even when the camera is locked
    FOriginSnapped: Boolean;
    FOriginRestore: TPoint3D;
    // A 2-pass export. FTwoPassRun: this batch runs two passes. FBatchPass:
    // 0 for an ordinary batch, 1 while the first pass measures (overscan off,
    // nothing saved), 2 while the second pass exports. FTwoPassBounds, once
    // FTwoPassMeasured, is how far every frame the first pass drew reached.
    // From it, once FTwoPassAdjusted, every capture of the
    // second pass slides its picture by FTwoPassMoveX across and
    // FTwoPassMoveY down, in pixels of the plain fit, then multiplies
    // OrthoHeight, or in perspective Distance, by FTwoPassScale. Like the
    // rest of a capture's framing, it is undone when the capture ends.
    // FTwoPassBounds is to a fraction of a pixel where the edge pixels are
    // partly covered.
    FTwoPassRun: Boolean;
    FBatchPass: Integer;
    FTwoPassBounds: TRectF;
    FTwoPassMeasured: Boolean;
    // The pixel the first capture of a batch put the centre of rotation on;
    // every later capture of the batch is snapped to the same pixel, so the
    // whole batch shares one origin
    FBatchOrigin: TPoint;
    FBatchOriginSet: Boolean;
    FTwoPassAdjusted: Boolean;
    FTwoPassMoveX: Single;
    FTwoPassMoveY: Single;
    FTwoPassScale: Single;
    // When the pass under way started, on FBatchClock, so a 2-pass export's
    // time remaining is for that pass alone; 0 for the first pass
    FPassStartMs: Int64;
    // Batch export, below the animation list: All, what to save, Export
    FBatchLayout: TLayout;
    // The play, pause and step buttons under the animation list, for the
    // selected animation, and the player that holds and steps it; nil until
    // one of them, or choosing an entry, plays an animation
    FTransportLayout: TLayout;
    FFirstButton: TButton;
    FPreviousButton: TButton;
    FPlayButton: TButton;
    FNextButton: TButton;
    FLastButton: TButton;
    // The frame readout after the buttons, "frame / frames", as three labels
    // so the "/" stays put whatever the numbers
    FFrameNumberLabel: TLabel;
    FFrameSlashLabel: TLabel;
    FFrameTotalLabel: TLabel;
    // The frame rate the viewport draws at, top left of the view, and the
    // timer that refreshes it and the frame readout
    FFpsLabel: TLabel;
    FFpsBack: TRectangle;   // dark, so the label reads on any background
    FReadoutTimer: TTimer;
    // The displays, kept so the one the form is on can be checked cheaply
    // as the readouts refresh; read again whenever the form moves to
    // another, so the frame rate follows that display's refresh rate
    FDisplays: TPeardoxDisplays;
    FDisplayIndex: Integer;
    FPlayer: TSprite3DAnimationPlayer;
    FBatchAll: TCheckBox;
    FBatchKindBox: TComboBox;
    // Above Export: whether a strip or spritesheet is saved with its metadata,
    // whether to export every direction, and whether to export in two passes
    // (a measuring pass, then the export reframed from what it measured).
    // 2-pass is not kept: it starts clear each session and is in no project
    // file
    FBatchMetadata: TCheckBox;
    FBatchDirections: TCheckBox;
    FBatchTwoPass: TCheckBox;
    FExportButton: TButton;
    FAbortButton: TButton;
    // Abort was clicked: the batch stops once the current entry is saved
    FBatchAborted: Boolean;
    // True while the code changes ticks, so the tick handlers ignore it
    FSyncingChecks: Boolean;
    // The batch under way: the entries still to capture, as list indices,
    // what to save them as, where, and how it is going
    FBatchActive: Boolean;
    FBatchItems: TArray<Integer>;
    FBatchPos: Integer;
    FBatchKind: TSheetKind;
    FBatchFolder: String;
    FBatchSaved: Integer;
    FBatchErrors: TArray<String>;
    // A Texture Atlas batch: the animations captured so far; their frames
    // not yet on a saved page, each page being saved as soon as it is full;
    // how many pages have been saved; the parts with a page that could not
    // be; the metadata of the pages saved, written when the batch ends; the
    // folder chosen when Texture Atlas was picked; the last page is being
    // written; the drop-down's choice before the last change, to go back to
    // if no folder is chosen
    FAtlasParts: TArray<TAtlasPart>;
    FAtlasQueue: TArray<TAtlasCell>;
    FAtlasPageCount: Integer;
    FAtlasFailed: TArray<Boolean>;
    FAtlasPending: TArray<TSprite3DSheetMetadata>;
    FAtlasFolder: String;
    FAtlasSaving: Boolean;
    // A batch's metadata, measured as each image was saved and written once
    // the batch ends, after every image
    FPendingMetadata: TArray<TSprite3DSheetMetadata>;
    // File, Debug and its Frame Borders item, made only while debug_enabled
    // is true in settings.json
    FDebugMenu: TMenuItem;
    FFrameBordersItem: TMenuItem;
    FBatchKindIndex: Integer;
    // The batch's progress dialog, while it is open, and whether the view's
    // own redraws were stopped for the batch
    FExportDialog: TExportProgressForm;
    FViewPaused: Boolean;
    // The entry selected when the batch started, selected again at its end
    FBatchSelected: Integer;
    // The creator credits, for every export's metadata; the project file
    // last saved or loaded; and an Animations list from a project, applied
    // once its model, FPendingListModel, has loaded
    FCredits: TSprite3DCredits;
    FProjectFile: String;
    FPendingList: TAnimationListState;
    FPendingListModel: String;
    FHasPendingList: Boolean;
    // Directions: each batch step's direction, as an index into the
    // bearings, or -1 without directions; the bearings, from Model,
    // Directions, empty without; how many entries the batch has; and, for a
    // strip or spritesheet, the frames of the entry's directions so far and
    // whether one of them failed
    FBatchDirs: TArray<Integer>;
    FBatchBearings: TArray<Single>;
    FBatchEntryCount: Integer;
    // How long the batch has taken, from Export to its report, and how much
    // of that was capturing before a texture atlas's pages were made
    FBatchClock: TStopwatch;
    FBatchCaptureMs: Int64;
    // When the dialog's time remaining was last changed, on FBatchClock; -1
    // before the first estimate
    FBatchRemainingAt: Int64;
    FDirFrames: TArray<TSprite3DImage>;
    FDirFailed: Boolean;
    // The camera's azimuth before a capture turned it to a direction, put
    // back by EndCapture, and whether it did
    FDirTurned: Boolean;
    FDirRestoreAzimuth: Single;
    // Whether an animation chosen in the list starts held on its first frame:
    // so at first, and after Pause or a step; not after Play
    FHoldNew: Boolean;
    // Frame counts typed over an entry's own, by animation name, for this
    // model; and the editor for one, while it is open
    FFrameOverrides: TDictionary<String, Integer>;
    FFrameEditor: TEdit;
    FFrameEditName: String;
    FSpentEditor: TEdit;   // closed, freed from a fresh main-loop turn
    FItemDownX: Single;    // where on its entry the mouse last went down
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    // Mobile only: the pop-up menu's items, offered in the menu drawer
    FAnimationMenu: TMenuItem;
    {$ENDIF}
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    // The Settings dialog's starting values, for comparing on OK
    FSettingsBefore: TSprite3DGeneralSettings;
    {$ENDIF}
    ModelDir: String;
    procedure SwitchModel(const AModel: String);
    function FitModel: Boolean;
    procedure PlaySelectedAnimation;
    function SweepFitVolume: TSweptVolume;
    function AnimationSweptVolume(const AName: String): TSweptVolume;
    function GrabFit(const AWidth, AHeight: Integer): Boolean;
    procedure ApplyAngles;
    procedure ApplyDistance;
    procedure ApplyPan;
    procedure ShowDistanceFactor(const AFactor: Single);
    procedure ShowPan(const AEnabled: Boolean; const APanX, APanZ: Single);
    function CurrentCameraSpec: TCameraSettings;
    procedure ShowCameraSpec(const ASpec: TCameraSettings);
    procedure AcceptCameraSpec(const ASpec: TCameraSettings);
    procedure RestoreCamera;
    procedure OrbitalDialogPreview(Sender: TObject);
    function ProjectionCaption: String;
    function DefaultModelFile: String;
    procedure LoadStartupModel;
    procedure ApplyGeneralSettings(const AOld, ANew: TSprite3DGeneralSettings);
    procedure SetPolarViewAngle(const APolarAngle: Single;
      const AAzimuth: Single = 45);
    procedure ClearViewChecks;
    procedure SelectFixedView(const AItem: TMenuItem; const APolarAngle: Single;
      const AAzimuth: Single = 45);
    function ChooseSaveFolder: Boolean;
    procedure OpenRequestedFile(const AFileName: String);
    procedure ApplyBackground(const ASpec: TSprite3DBackgroundSpec;
      const ASave: Boolean);
    procedure RestoreViewToggles;
    procedure ApplyProjection;
    procedure ApplyShowAxes;
    procedure ApplyShowBounds;
    procedure ApplyShowGrid;
    procedure ApplyShowSweep;
    procedure ApplyShowCombinedSweep;
    procedure LoadTimerTimer(Sender: TObject);
    procedure LoadDialogAbort(Sender: TObject);
    procedure BuildLoadModel;
    procedure ShowLoadModel(const AShowNew: Boolean);
    procedure MeasureLoadModel;
    procedure CommitLoad;
    procedure EndLoad(const AError: String);
    procedure ReportLoadEnd;
    procedure BuildNoModelPanel;
    procedure UpdateNoModelPanel;
    procedure StartVideo;
    procedure RestoreCameraView;
    procedure SaveViewState;
    function CameraViewKey(const AItem: TMenuItem): String;
    function CameraViewItem(const AKey: String): TMenuItem;
    procedure BackgroundDialogPreview(Sender: TObject);
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure BackgroundDialogAccept(Sender: TObject);
    procedure BackgroundDialogCancel(Sender: TObject);
    procedure OrbitalDialogAccept(Sender: TObject);
    procedure OrbitalDialogCancel(Sender: TObject);
    procedure SettingsDialogAccept(Sender: TObject);
    {$ENDIF}
    function ChooseIconFile(out AFileName: String;
      out AWriter: TSprite3DIconWriterClass): Boolean;
    function GetSaveFolder: String;
    procedure SetSaveFolder(const Value: String);
    procedure OffscreenBeforeGrab(Sender: TObject; const AWidth, AHeight: Integer);
    procedure OffscreenAfterGrab(Sender: TObject);
    procedure BuildAnimationMenu;
    procedure PrepareOpenH264;
    procedure StartOpenH264Update;
    procedure BuildLockCameraItem;
    procedure LockCameraItemClick(Sender: TObject);
    function CameraLocked: Boolean;
    function IsCameraViewItem(const AItem: TMenuItem): Boolean;
    procedure UpdateCameraLockControls;
    procedure AnimationSettingsItemClick(Sender: TObject);
    procedure ApplyAnimationFps(const AFps: Integer);
    procedure ApplyOverscan(const AOn: Boolean; const AFactor: Integer;
      const AFilter: TSprite3DResampleFilter);
    procedure OffscreenOverscanReduced(Sender: TObject; const AFailedSize,
      AMaxOverscan: Integer);
    procedure OffscreenShiftView(Sender: TObject; const ARight, AUp: Single);
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure AnimationDialogAccept(Sender: TObject);
    {$ENDIF}
    procedure HookAnimationItems;
    procedure RebuildAnimationList;
    function IsUsedAnimation(const AName: String): Boolean;
    procedure UpdateFrameCounts;
    function AnimationFrameCount(const AIndex: Integer): Integer;
    function FrameCountLabel(const AItem: TListBoxItem): TLabel;
    procedure ApplyUsedAnimations(const AUsed: TArray<String>);
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure AnimationsUsedAccept(Sender: TObject);
    procedure DirectionsAccept(Sender: TObject);
    {$ENDIF}
    procedure ApplyDirections(const ACount: Integer; const AStart: Single;
      const AOrder: TArray<Integer>; const ASnap: Boolean);
    procedure AnimationItemMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SaveStripItemClick(Sender: TObject);
    procedure SaveSheetItemClick(Sender: TObject);
    procedure SaveGifItemClick(Sender: TObject);
    procedure SaveMp4ItemClick(Sender: TObject);
    procedure StartSingleCapture(const AKind: TSheetKind);
    function StartCapture(const AKind: TSheetKind; const AIndex, ADirection: Integer;
      const AFolder: String; const AOnFinished: TProc<String>;
      out AError: String): Boolean;
    procedure StartBatch(const AItems: TArray<Integer>; const AKind: TSheetKind;
      const AFolder: String; const ATwoPass: Boolean = False);
    procedure TurnToDirection(const ABearing: Single);
    function BatchStepTitle: String;
    function BatchEntryOrdinal(const APos: Integer): Integer;
    procedure FitFormToGrabShape;
    function Capturing: Boolean;
    procedure BuildBatchControls;
    procedure BuildTransportControls;
    procedure UpdateTransportControls;
    procedure UpdateFrameReadout;
    function ViewFpsLimit: Integer;
    procedure ApplyViewFps;
    procedure CheckDisplay;
    procedure BuildFpsReadout;
    procedure ReadoutTimerTimer(Sender: TObject);
    procedure FitViewportToAspect;
    procedure TransportButtonApplyStyle(Sender: TObject);
    procedure TransportChanged;
    function EnsurePlayer: Boolean;
    function AnimationHeld: Boolean;
    procedure PlayButtonClick(Sender: TObject);
    procedure FirstButtonClick(Sender: TObject);
    procedure PreviousButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure LastButtonClick(Sender: TObject);
    function SelectedAnimation: TGorillaAnimation;
    function TickedAnimationCount: Integer;
    procedure HideHelpersForGrab;
    procedure ShowHelpersAfterGrab;
    function UsesCombinedView: Boolean;
    function ViewVolume: TSweptVolume;
    procedure UpdateView;
    procedure BatchAllChange(Sender: TObject);
    procedure BatchKindChange(Sender: TObject);
    procedure RestoreBatchKind;
    procedure SetEntryChecks(const AEntries: TArray<Integer>; const AChecked: Boolean);
    procedure ShowExportStep(const AItemFraction: Single; const AStatus: String);
    procedure ExportDialogAbort(Sender: TObject);
    procedure ExportDialogClosed(Sender: TObject);
    procedure ExportDialogAutoCloseChange(Sender: TObject);
    procedure PauseViewForExport(const APause: Boolean);
    function FrameOverride(const AName: String): Integer;
    procedure SetFrameOverride(const AName: String; const ACount: Integer);
    procedure AnimationItemMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure AnimationItemDblClick(Sender: TObject);
    procedure StartFrameEdit(const AEntry: Integer);
    procedure FinishFrameEdit(const ACommit, AFreeNow: Boolean);
    procedure FreeSpentEditor;
    procedure FrameEditorKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FrameEditorExit(Sender: TObject);
    procedure UpdateListFileItems;
    function AnimationListToJson: TJSONObject;
    function ReadAnimationList(const AValue: TJSONValue; out AState: TAnimationListState;
      out AError: String): Boolean;
    procedure ApplyAnimationList(const AState: TAnimationListState; const AFrom: String);
    function ExportMeta(const APage, APageCount: Integer): TSprite3DSheetMeta;
    procedure SaveProjectAs;
    procedure SaveProjectFile(const AFileName: String);
    function LoadProjectFile(const AFileName: String): Boolean;
    procedure ApplyPendingList;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure CreditsAccept(Sender: TObject);
    {$ENDIF}
    function Exporting: Boolean;
    procedure QuitAfterConfirm;
    procedure BatchMetadataChange(Sender: TObject);
    procedure BatchDirectionsChange(Sender: TObject);
    procedure AnimationListBoxChangeCheck(Sender: TObject);
    procedure ExportButtonClick(Sender: TObject);
    procedure AbortButtonClick(Sender: TObject);
    function ChooseExportFolder(out AFolder: String): Boolean;
    procedure RunNextBatchItem;
    procedure ContinueBatch;
    procedure FinishBatch;
    procedure ReportBatch;
    procedure ChooseAtlasFolder;
    procedure AddAtlasPart(const APart: TAtlasPart; const AFrames: TArray<TSprite3DImage>);
    procedure SaveAtlasPages(const AFinal: Boolean; const AThen: TProc);
    procedure FinishAtlas;
    function SaveAtlasPage(const ACells: TArray<TAtlasCell>; const AParts: TArray<TAtlasPart>;
      const AFileName: String; const APage, APageSize: Integer;
      const ANonPowerOf2, ABorders: Boolean; const ADirections: TArray<Single>;
      const AMeta: TSprite3DSheetMeta; out AMetadata: TSprite3DSheetMetadata;
      var ANotes: TArray<String>): String;
    procedure WriteBatchMetadata;
    procedure BuildDebugMenu;
    procedure FrameBordersItemClick(Sender: TObject);
    function FrameBordersOn: Boolean;
    procedure ApplyAtlasSettings(const APageSize: Integer; const ANonPowerOf2: Boolean);
    procedure DeleteAtlasPages(const AFolder, AStem: String; var ANotes: TArray<String>);
    procedure UpdateBatchControls;
    function FrameCaptureFraming(const ASource: TSprite3DFrameSource;
      const AWidth, AHeight: Integer): Boolean;
    procedure EndCapture;
    function SnapCaptureOrigin(const AWidth, AHeight: Integer; out AOrigin: TPoint): Boolean;
    procedure SetMeasuringOverscan(const AMeasuring: Boolean);
    procedure MeasureTwoPassFrames(const AFrames: TArray<TSprite3DImage>);
    procedure ComputeTwoPassAdjust;
    procedure ApplyTwoPassAdjust(const AWidth, AHeight: Integer);
    procedure SlidePicture(const ARight, ADown: Single; const AWidth, AHeight: Integer);
    procedure StartSecondPass;

    function SaveSheet(const AKind: TSheetKind; const AFrames: TArray<TSprite3DImage>;
      const AFolder, AStem: String; const ACycleSeconds: Double;
      const AMetadata: Boolean; const AOrigin: TPoint; const AOriginKnown: Boolean;
      const AAnimation: String; const ADirections: TArray<Single>;
      const AMeta: TSprite3DSheetMeta; const ABorders, ADeferMetadata: Boolean;
      out APending: TSprite3DSheetMetadata; out AHasPending: Boolean): String;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  private
    // Mobile only: FMX shows no TMainMenu there, so MainMenu1 is offered
    // through a hamburger button and a drawer instead
    FMenuBar: TToolBar;
    FMenuButton: TSpeedButton;
    FMenuDrawer: TMultiView;
    FMenuList: TListBox;
    procedure BuildMobileMenu;
    procedure RefreshMobileMenu(Sender: TObject);
    procedure MobileMenuItemClick(Sender: TObject);
    {$ENDIF}
    {$IF DEFINED(LINUX) and not DEFINED(ANDROID)}
  private
    // Linux only: MainMenu1's items, moved onto a menu bar FMX draws itself,
    // as the native GTK menu bar showed only each item's first letter
    FDesktopMenuBar: TMenuBar;
    procedure UseFmxMenuBar;
    {$ENDIF}
  public
    { Public declarations }
    //** @abstract(The folder File, Grab saves into, kept between sessions; empty until one is
    //** chosen.)
    //**
    //** Read from settings.json at start-up, so it is empty only on the first run, or until a
    //** folder is chosen. The first grab without a usable folder shows the "Save Location"
    //** dialog and stores the choice here. Android and iOS have no such dialog: there the
    //** first grab sets it to a Grabs folder in the app's public storage on Android, or its
    //** Documents folder on iOS. Setting it saves settings.json at once; a failure to write
    //** the file is reported with a message, and the new folder is still used this session.
    //** Set it to empty to be asked again.
    /// <summary>The folder File, Grab saves into, kept between sessions; empty until one is
    /// chosen.</summary>
    /// <remarks>Read from settings.json at start-up, so it is empty only on the first run, or
    /// until a folder is chosen. The first grab without a usable folder shows the "Save
    /// Location" dialog and stores the choice here. Android and iOS have no such dialog: there
    /// the first grab sets it to a Grabs folder in the app's public storage on Android, or its
    /// Documents folder on iOS. Setting it saves settings.json at once; a failure to write the
    /// file is reported with a message, and the new folder is still used this session. Set it
    /// to empty to be asked again.</remarks>
    property SaveFolder: String read GetSaveFolder write SetSaveFolder;
    //** @abstract(The off-screen renderer File, Grab uses; set its Width and Height to
    //** change the grab size.)
    //**
    //** Created in FormCreate, attached to the viewport, which owns and frees it.
    //**
    //** @seealso(TSprite3DOffscreen)
    /// <summary>The off-screen renderer File, Grab uses; set its Width and Height to change
    /// the grab size.</summary>
    /// <remarks>Created in FormCreate, attached to the viewport, which owns and frees
    /// it.</remarks>
    /// <seealso cref="Sprite3DOffscreen.TSprite3DOffscreen"/>
    property Offscreen: TSprite3DOffscreen read FOffscreen;
  end;

var
  //** @abstract(The main form, created by Application.CreateForm in Sprite3d.dpr.)
  /// <summary>The main form, created by Application.CreateForm in Sprite3d.dpr.</summary>
  MainForm: TMainForm;

implementation

uses
  FMX.Platform, System.IOUtils, OSPaths,
  Gorilla.DefTypes, System.Math,
  Sprite3DOpenFiles, Sprite3DBackgroundForm,
  Sprite3DAnimationsUsedForm, Sprite3DDirectionsForm, FMX.DialogService,
  Sprite3DCreditsForm, System.DateUtils, JsonText;

{$R *.fmx}

var
  // Set as the main form is destroyed, for work queued from other threads
  // that may arrive after it has gone
  MainFormGone: Boolean = False;

// ATasks without ATask, for the list of saves under way
function RemoveTask(const ATasks: TArray<ITask>; const ATask: ITask): TArray<ITask>;
begin
  Result := nil;
  for var Task in ATasks do
    if Task <> ATask then
      Result := Result + [Task];
end;

const
  // How often a load moves on, in milliseconds, and how long each slice of
  // animation measuring may hold the main thread; the rest goes to drawing
  // the dialog and to Abort
  LOAD_INTERVAL_MS = 15;
  MEASURE_BUDGET_MS = 30;
  // The share of the progress bar each stage of a load ends at
  LOAD_READ_END = 0.3;
  LOAD_BUILD_END = 0.6;
  LOAD_MEASURE_END = 0.95;
  // How often the frame rate and frame readouts are refreshed, in
  // milliseconds: often enough for the frame number to follow playback
  READOUT_INTERVAL_MS = 100;

  // The first entry of AnimationListBox, which stops any animation and
  // shows the model as loaded
  NO_ANIMATION = '(None)';
  // What the (None) entry captures instead of an animation is one still
  // frame, the model in its bind pose; a GIF or MP4 of it lasts this long
  STILL_SECONDS = 1.0;
  // Marks the frame-count label FrameCountLabel puts on each list entry
  FRAME_LABEL_TAG = 3001;
  // The most memory a capture may use for its frames and the image made
  // from them, so a long animation at a large grab size is refused with a
  // message instead of running the device out of memory
  MAX_CAPTURE_BYTES = Int64(1024) * 1024 * 1024;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TabControl1.ActiveTab := GorillaTab;

  ModelDir := DefaultModelDir;

  FAzimuth := 0;
  FRoll := 0;
  FPolarAngle := 0;
  FFactor := 1.0;

  GorillaViewport := TGorillaViewport.Create(AspectLayout);
  GorillaViewport.Parent := AspectLayout;
  GorillaViewport.OnResize := GorillaViewportResize;
  GorillaViewport.UseFixedFrameRate := true;
  GorillaViewport.VSync := False;
  GorillaViewport.HitTest := False;
  GorillaViewport.FixedFrameRate := 60;
//  GorillaViewport.DiagnosticsActive := true;
  GorillaViewport.UsingDesignCamera := False;
  GorillaCamera := TSprite3DCamera.Create(GorillaViewport);
  GorillaViewport.Camera := GorillaCamera;// .Camera;
  // The light rides on the camera: a child at its origin with no turn of its
  // own, so it sits where the camera is and points where the camera looks,
  // lighting whatever side of the model is in view
  GorillaLight := TGorillaLight.Create(GorillaViewport);
  GorillaLight.Parent := GorillaCamera;
  GorillaLight.Position.Point := TPoint3D.Zero;
  GorillaLight.RotationAngle.Point := TPoint3D.Zero;
  GorillaLight.LightType := TLightType.Point;
  GorillaModel := Nil;
  GorillaCamera.FOV := 45;

  // Off-screen renderer for File, Grab, at the size set in File, Settings
  FOffscreen := TSprite3DOffscreen.Create(GorillaViewport);
  FOffscreen.Viewport := GorillaViewport;
  FOffscreen.OnBeforeGrab := OffscreenBeforeGrab;
  FOffscreen.OnAfterGrab := OffscreenAfterGrab;
  FOffscreen.OnOverscanReduced := OffscreenOverscanReduced;
  FOffscreen.OnShiftView := OffscreenShiftView;
  // Settings from earlier sessions; on the first run, the defaults
  FSettings := TSprite3DAppSettings.Create;
  FSettings.Load;
  // debug_enabled is only ever set by hand in settings.json; said only when on
  if FSettings.DebugEnabled then
    DebugMemo.Lines.Add('Debug enabled (debug_enabled is true in ' +
      FSettings.FileName + ')');
  FFrameOverrides := TDictionary<String, Integer>.Create;
  // An animation chosen first shows held on its first frame
  FHoldNew := True;
  // The frame rate the view is drawn at, as chosen in File, Settings, within
  // what the display can show
  FDisplayIndex := -1;
  ApplyViewFps;
  FGrabNumber := 1;
  // Every grab from here on is this size, until File, Settings changes it
  FOffscreen.Width := FSettings.GrabWidth;
  FOffscreen.Height := FSettings.GrabHeight;
  // Overscan starts off each session; the filter is kept for when it is on
  FOffscreen.Resample := FSettings.ResampleFilter;
  FOffscreen.Overscan := 1;
  // The look chosen in File, Settings; FMX's default needs nothing doing
  if FSettings.ThemeKind <> thDefault then
  begin
    var ThemeError: String;
    if not ApplyTheme(FSettings.ThemeKind, ThemeError) then
      DebugMemo.Lines.Add(ThemeError);
  end;
  // The camera pan, applied by every fit from here on
  FPanEnabled := FSettings.PanEnabled;
  FPanX := EnsureRange(FSettings.PanX, -PAN_LIMIT, PAN_LIMIT);
  FPanZ := EnsureRange(FSettings.PanZ, -PAN_LIMIT, PAN_LIMIT);
  // Placed by FitViewportToAspect, at the shape of the grabs, once the
  // background is attached below
  GorillaViewport.Align := TAlignLayout.None;
  // The background behind the model, as last chosen: a 2D control behind
  // the viewport, which it makes see-through. It takes the viewport's
  // alignment, so it comes after that is set; its parent frees it.
  FBackground := TSprite3DBackground.Create(nil);
  FBackground.AttachTo(GorillaViewport);
  ApplyBackground(FSettings.BackgroundSpec, False);
  AspectLayout.HitTest := False;
  FitViewportToAspect;

  // The camera view as it was left last session; Isometric the first time
  RestoreCameraView;

  // The View menu's on/off items as they were left last session
  RestoreViewToggles;

  // Moves a model load on, a tick at a time
  FLoadTimer := TTimer.Create(Self);
  FLoadTimer.Enabled := False;
  FLoadTimer.Interval := LOAD_INTERVAL_MS;
  FLoadTimer.OnTimer := LoadTimerTimer;
  // Says how to load a model until one is
  BuildNoModelPanel;
  // Frames per second, top left over the view, above the panel
  BuildFpsReadout;

  // The OpenH264 already downloaded, if it is the one openh264.json asks
  // for; before StartVideo first loads the video libraries
  PrepareOpenH264;

  // The animation list's right-click menu; on mobile, also the drawer's
  // Animation group, so it must come before BuildMobileMenu
  BuildAnimationMenu;

  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // The mobile menu is built from the finished menus, so video is looked
  // for now; on the desktop that waits until the first model is shown
  StartVideo;
  {$ENDIF}
  // View, Camera, Lock Camera; before the menu is moved or mirrored
  BuildLockCameraItem;
  // File, Debug, only while debug_enabled; likewise before the menu moves
  BuildDebugMenu;

  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  BuildMobileMenu;
  {$ELSEIF DEFINED(LINUX)}
  UseFmxMenuBar;
  {$ENDIF}
end;

{$IF DEFINED(LINUX) and not DEFINED(ANDROID)}
// The native GTK menu bar FMX uses on Linux showed only the first letter of
// each item, so MainMenu1's items are moved, as they are, onto a TMenuBar,
// which FMX draws itself in the form's style. They are the same objects, so
// every handler, tick and Enabled state in the form still applies. The
// emptied MainMenu1 is then freed, so no native menu bar is made.
procedure TMainForm.UseFmxMenuBar;
var
  Items: TArray<TFmxObject>;
  I: Integer;
begin
  FDesktopMenuBar := TMenuBar.Create(Self);
  FDesktopMenuBar.Parent := Self;
  FDesktopMenuBar.Align := TAlignLayout.Top;
  // Listed first, then moved in their order: moving one changes the list
  SetLength(Items, MainMenu1.ItemsCount);
  for I := 0 to High(Items) do
    Items[I] := MainMenu1.Items[I];
  for I := 0 to High(Items) do
    Items[I].Parent := FDesktopMenuBar;
  FreeAndNil(MainMenu1);
end;
{$ENDIF}

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
// A toolbar along the top with the platform's hamburger button, which opens
// a drawer listing MainMenu1: one group per menu or submenu that has items,
// such as View, Camera, one row per item. Rows are made from the menu items
// themselves, so items added to MainMenu1 later appear here too. Separators
// are left out, and so is Exit on iOS, where apps do not quit themselves.
procedure TMainForm.BuildMobileMenu;

  // A group headed AHeading for AMenu's items, then a group for each of its
  // submenus, headed with both names
  procedure AddMenu(const AMenu: TMenuItem; const AHeading: String);
  var
    J: Integer;
    Item: TMenuItem;
    Header: TListBoxGroupHeader;
    Row: TListBoxItem;
    HasRows: Boolean;
  begin
    HasRows := False;
    for J := 0 to AMenu.ItemsCount - 1 do
    begin
      Item := AMenu.Items[J];
      if (Item.Text = '-') or (Item.ItemsCount > 0) then
        Continue;
      {$IFDEF IOS}
      if Item = ExitMenuItem then
        Continue;
      {$ENDIF}
      if not HasRows then
      begin
        Header := TListBoxGroupHeader.Create(FMenuList);
        Header.Text := AHeading;
        FMenuList.AddObject(Header);
        HasRows := True;
      end;
      Row := TListBoxItem.Create(FMenuList);
      Row.Text := Item.Text;
      Row.TagObject := Item;
      Row.OnClick := MobileMenuItemClick;
      FMenuList.AddObject(Row);
    end;
    for J := 0 to AMenu.ItemsCount - 1 do
      if AMenu.Items[J].ItemsCount > 0 then
        AddMenu(AMenu.Items[J], AHeading + ', ' + AMenu.Items[J].Text);
  end;

var
  I: Integer;
begin
  FMenuBar := TToolBar.Create(Self);
  FMenuBar.Parent := Self;
  FMenuBar.Align := TAlignLayout.Top;

  FMenuButton := TSpeedButton.Create(Self);
  FMenuButton.Parent := FMenuBar;
  FMenuButton.Align := TAlignLayout.Left;
  FMenuButton.StyleLookup := 'drawertoolbutton';
  FMenuButton.Width := FMenuBar.Height;

  FMenuDrawer := TMultiView.Create(Self);
  FMenuDrawer.Parent := Self;
  FMenuDrawer.Mode := TMultiViewMode.Drawer;
  FMenuDrawer.MasterButton := FMenuButton;
  FMenuDrawer.Width := 260;
  FMenuDrawer.OnStartShowing := RefreshMobileMenu;

  FMenuList := TListBox.Create(Self);
  FMenuList.Parent := FMenuDrawer;
  FMenuList.Align := TAlignLayout.Client;
  FMenuList.GroupingKind := TListGroupingKind.Grouped;

  for I := 0 to MainMenu1.ItemsCount - 1 do
    if MainMenu1.Items[I] is TMenuItem then
      AddMenu(TMenuItem(MainMenu1.Items[I]), TMenuItem(MainMenu1.Items[I]).Text);
end;

// Each time the drawer opens, copy the menu's checks and enabled states to
// its rows, so the current View shows a tick
procedure TMainForm.RefreshMobileMenu(Sender: TObject);
var
  I: Integer;
  Row: TListBoxItem;
  Item: TMenuItem;
begin
  for I := 0 to FMenuList.Count - 1 do
  begin
    Row := FMenuList.ListItems[I];
    if not (Row.TagObject is TMenuItem) then
      Continue;
    Item := TMenuItem(Row.TagObject);
    Row.Enabled := Item.Enabled;
    if Item.IsChecked then
      Row.ItemData.Accessory := TListBoxItemData.TAccessory.aCheckmark
    else
      Row.ItemData.Accessory := TListBoxItemData.TAccessory.aNone;
  end;
end;

// Close the drawer, then run the menu item's own handler, so a row does
// exactly what its menu item does on the desktop
procedure TMainForm.MobileMenuItemClick(Sender: TObject);
var
  Item: TMenuItem;
begin
  if not (TListBoxItem(Sender).TagObject is TMenuItem) then
    Exit;
  Item := TMenuItem(TListBoxItem(Sender).TagObject);
  FMenuDrawer.HideMaster;
  if Item.Enabled and Assigned(Item.OnClick) then
    Item.OnClick(Item);
end;
{$ENDIF}


// The single place where dial changes reach the readouts and the camera,
// so they can never disagree. Azimuth and Roll go to the camera reversed
// (360 minus the readout) so the view turns the right way for the dial.
// Dials do not refit: with FitToBounds, turning one can push the model
// past the edge until the next refit; the swept volume fit allows for any
// azimuth.
procedure TMainForm.AnimationListBoxClick(Sender: TObject);
begin
  // A click on another entry moves the selection first, and
  // AnimationListBoxChange has played it already
  if FChangePlayed and (AnimationListBox.ItemIndex = FChangePlayedIndex) then
  begin
    FChangePlayed := False;
    Exit;
  end;
  FChangePlayed := False;
  PlaySelectedAnimation;
end;

// The selection moved, by the arrow keys, a click or code: play the new
// entry at once, as a click on it would
procedure TMainForm.AnimationListBoxChange(Sender: TObject);
begin
  FChangePlayed := False;
  if FRebuildingList or FKeepingSelection then
    Exit;   // the selection is kept as it was; nothing new to play
  if Capturing or (AnimationListBox.ItemIndex < 0) then
    Exit;   // a capture drives the animation; or the list is being emptied
  PlaySelectedAnimation;
  FChangePlayed := True;
  FChangePlayedIndex := AnimationListBox.ItemIndex;
end;

// Plays the selected animation, or stops any for (None); nothing while a
// capture is driving the animation
procedure TMainForm.PlaySelectedAnimation;
var
  ani: String;
  WasHeld: Boolean;
begin
  if Capturing then
    Exit;   // a capture is driving the animation
  // Choosing an entry plays it from the start; but while the controls are
  // paused, the new animation starts paused too, on its first frame
  // An animation chosen starts held on its first frame at first, and after
  // Pause or a step; once Play has been pressed, it plays
  if FPlayer <> nil then
    FHoldNew := FPlayer.Held;
  WasHeld := FHoldNew;
  FreeAndNil(FPlayer);
  if Assigned(GorillaModel) then
    begin
      if AnimationListBox.ItemIndex > 0 then
        begin
          ani := AnimationListBox.Items[AnimationListBox.ItemIndex];
          var Anim := GorillaModel.AnimationManager.PlayAnimation(ani);
          if Anim <> nil then
          begin
            FPlayer := TSprite3DAnimationPlayer.Create(GorillaModel, Anim,
              FSettings.AnimationFps, FrameOverride(ani));
            if WasHeld then
              FPlayer.ShowFrame(0);
          end;
        end
      else if AnimationListBox.ItemIndex = 0 then
        begin
          // The model as loaded: Gorilla puts it back in its bind pose
          GorillaModel.ResetToBindPose();
        end;
    end;
  UpdateTransportControls;
  UpdateView;
end;

procedure TMainForm.ApplyAngles;
begin
  if CameraLocked then
    Exit;
  if Assigned(GorillaCamera) then
  begin
    GorillaCamera.Azimuth := Wrap360(-FAzimuth);
    GorillaCamera.PolarAngle := FPolarAngle;
    GorillaCamera.Roll := Wrap360(-FRoll);   // reversed, as is Azimuth
  end;
end;

procedure TMainForm.OrthographicItemClick(Sender: TObject);
begin
  if CameraLocked then
    Exit;   // the projection is part of the camera
  OrthographicItem.IsChecked := not OrthographicItem.IsChecked;
  ApplyProjection;
end;

// The projection and caption to match OrthographicItem, then a refit, as
// the two modes size the view differently
procedure TMainForm.ApplyProjection;
begin
  if CameraLocked then
  begin
    Caption := ProjectionCaption;
    Exit;
  end;
  if OrthographicItem.IsChecked then
    GorillaCamera.ProjectionMode := TGorillaCameraProjection.cpOrthographic
  else
    GorillaCamera.ProjectionMode := TGorillaCameraProjection.cpPerspective;
  Caption := ProjectionCaption;
  FitModel;
end;

procedure TMainForm.RollDialChange(Sender: TObject);
begin
end;

// On startup load a default Model as specified by DefaultLoadType
// The directory layout of models/Orientation follows this pattern
// to allow easy addition of new Model types
// Makes the window wider or narrower, as it opens, so that the area left of
// the Animations panel has the shape of the grab size from File, Settings,
// and the view fills it with no grey either side. The height is kept. The
// width stays within the display's work area, keeping the window on it; a
// maximised or full-screen window, and Android and iOS, are left as they are.
procedure TMainForm.FitFormToGrabShape;
{$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
var
  Aspect, Wanted: Single;
  NewWidth, MinWidth, MaxWidth: Integer;
  Area: TRectF;
{$ENDIF}
begin
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  if (WindowState <> TWindowState.wsNormal) or FullScreen or (FSettings = nil) or
    (FSettings.GrabHeight <= 0) or (ViewportLayout.Height <= 0) then
    Exit;
  Aspect := FSettings.GrabWidth / FSettings.GrabHeight;
  Wanted := ViewportLayout.Height * Aspect;
  NewWidth := Round(ClientWidth + (Wanted - ViewportLayout.Width));
  MinWidth := Round(ControlsLayout.Width) + 160;
  Area := Screen.WorkAreaRect;
  // The window's frame round the client area counts towards the display
  MaxWidth := Round(Area.Width) - (Width - ClientWidth);
  NewWidth := EnsureRange(NewWidth, MinWidth, Max(MinWidth, MaxWidth));
  if NewWidth = ClientWidth then
    Exit;
  ClientWidth := NewWidth;
  // Back onto the display if the wider window runs off it
  if Left + Width > Area.Right then
    Left := Max(Round(Area.Left), Round(Area.Right) - Width);
  {$ENDIF}
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  FSetupComplete := True;
  if FStarted then
    Exit;   // the form can be shown again; the model stays as it is
  FStarted := True;
  // Project files open with this copy of the program, off the main thread,
  // as on Linux it runs the system's database updates
  TTask.Run(
    procedure
    var
      Note: String;
    begin
      if not RegisterProjectFiles(Note) then
        TThread.Queue(nil,
          procedure
          begin
            if not MainFormGone then
              DebugMemo.Lines.Add('Can''t associate ' + PROJECT_FILE_EXTENSION +
                ' files with Sprite3D: ' + Note);
          end);
    end);
  // The window is drawn before the first model loads, rather than staying
  // blank until it has; the video libraries are looked for after that
  Caption := 'Loading...';
  TThread.ForceQueue(nil,
    procedure
    begin
      if MainFormGone then
        Exit;
      // Laid out by now: the view is made the shape of the grabs
      FitFormToGrabShape;
      LoadStartupModel;
      FileOpenRequests.OnOpenFile := OpenRequestedFile;
      {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
      TThread.ForceQueue(nil,
        procedure
        begin
          if not MainFormGone then
            StartVideo;
        end);
      {$ENDIF}
    end);
end;

function TMainForm.DefaultModelFile: String;
const
  DEFAULT_MODEL = 'models/uvcube.glb';
//  DEFAULT_MODEL = 'models/TestAnimatedCharacter.glb';
//  DEFAULT_MODEL = 'models/TestStaticCharacter.glb';
begin
  Result := OSFriendlyPath(ModelDir + DEFAULT_MODEL);
end;

// A model the system asked to open, such as one double-clicked in Explorer
// or Finder, comes first; otherwise the start-up action decides. A last
// model that has gone since falls back to the default one.
procedure TMainForm.LoadStartupModel;
var
  FileName: String;
  Requested: TArray<String>;
begin
  Requested := FileOpenRequests.TakePending;
  // A project the system asked to open comes first, and loads its model
  for var Request in Requested do
    if IsProjectFile(Request) then
    begin
      if LoadProjectFile(Request) then
        Exit;
      Break;
    end;
  FileName := StartupModelFile(Requested, String.Empty);
  if FileName = String.Empty then
    case FSettings.StartupAction of
      saNone:
        DebugMemo.Lines.Add('Start-up action is None: no model loaded');
      saLastModel:
        if (FSettings.LastModel <> String.Empty) and
          FileExists(OSFriendlyPath(FSettings.LastModel)) then
          FileName := OSFriendlyPath(FSettings.LastModel)
        else
        begin
          if FSettings.LastModel <> String.Empty then
            DebugMemo.Lines.Add('Last model not found: ' + FSettings.LastModel);
          FileName := DefaultModelFile;
        end;
    else
      FileName := DefaultModelFile;
    end;
  if FileName <> String.Empty then
    SwitchModel(FileName);
end;

// A file the system asks to open while the application runs
procedure TMainForm.OpenRequestedFile(const AFileName: String);
begin
  if IsProjectFile(AFileName) then
    LoadProjectFile(AFileName)
  else if IsModelFile(AFileName) then
    SwitchModel(AFileName)
  else
    ShowMessage('Not a model this application can open: ' + AFileName);
end;

// Anything of an export still going: a capture, a batch, atlas pages or
// files being written
function TMainForm.Exporting: Boolean;
begin
  Result := Capturing or FAtlasSaving or (Length(FSaveTasks) > 0);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FQuitConfirmed or not Exporting then
    Exit;
  CanClose := False;
  TDialogService.MessageDialog('Still exporting. Do you really want to quit?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult <> mrYes then
        Exit;   // carry on exporting
      FQuitConfirmed := True;
      // No further entries, and nothing more for an atlas; FormDestroy
      // cancels the capture under way and waits for files being written
      FBatchAborted := True;
      FAtlasParts := nil;
      FAtlasQueue := nil;
      FAtlasPending := nil;
      FPendingMetadata := nil;
      DebugMemo.Lines.Add('Quitting: export abandoned');
      // Closed again from a fresh main-loop turn, once this close has ended
      TThread.ForceQueue(nil, QuitAfterConfirm);
    end);
end;

// The close the user confirmed mid-export
procedure TMainForm.QuitAfterConfirm;
begin
  if not MainFormGone then
    Close;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MainFormGone := True;   // queued work arriving from here on does nothing
  if Assigned(FReadoutTimer) then
    FReadoutTimer.Enabled := False;
  FreeAndNil(FDisplays);
  FreeAndNil(FPlayer);
  // A load under way is dropped, its dialog with it
  FLoadTimer.Enabled := False;
  FLoadStage := lsNone;
  FreeAndNil(FMeasurer);
  if FLoadRead <> nil then
    FLoadRead.Cancel;
  FLoadRead := nil;
  FreeAndNil(FLoadModel);
  FreeAndNil(FLoadDialog);
  // Files being written are finished, so none is left half written
  if Length(FSaveTasks) > 0 then
    try
      TTask.WaitForAll(FSaveTasks);
    except
      // Reported already, or not at all now the form is going
    end;
  FSaveTasks := nil;
  // Stops a download under way and waits for it
  FreeAndNil(FOpenH264Update);
  FBatchActive := False;   // no further batch entries
  if Assigned(FCapture) then
  begin
    FCapture.Cancel;   // nothing is saved; the model is going too
    FCapture := nil;
  end;
  FileOpenRequests.OnOpenFile := nil;
  SaveViewState;
  FreeAndNil(FSettings);
  FreeAndNil(FSpentEditor);
  FreeAndNil(FFrameOverrides);
end;

// Ticks the View menu's on/off items as settings.json says, then applies
// each, as choosing it would: the projection and caption, the fit, and the
// grid, axes, box and swept volume, which SwitchModel also adds to each model
// as the items say. Before the first model is loaded, those find no model and do nothing.
procedure TMainForm.RestoreViewToggles;
begin
  ShowBoundsItem.IsChecked := FSettings.ShowBoundingBox;
  ShowGridItem.IsChecked := FSettings.ShowGrid;
  ShowAxesItem.IsChecked := FSettings.ShowAxes;
  ShowSweepItem.IsChecked := FSettings.ShowSweptVolume;
  ShowCombinedSweepItem.IsChecked := FSettings.ShowCombinedSweptVolume;
  OrthographicItem.IsChecked := FSettings.Orthographic;
  ApplyShowBounds;
  ApplyShowGrid;
  ApplyShowAxes;
  ApplyShowSweep;
  ApplyShowCombinedSweep;
  ApplyProjection;   // refits too
end;

// The name settings.json keeps for a View, Camera item: its component name
// without the View prefix and Item suffix, such as Isometric for
// ViewIsometricItem, so it stays the same if the caption changes
function TMainForm.CameraViewKey(const AItem: TMenuItem): String;
begin
  Result := AItem.Name;
  if Result.StartsWith('View') then
    Result := Result.Substring(4);
  if Result.EndsWith('Item') then
    Result := Result.Substring(0, Result.Length - 4);
end;

// The View, Camera item kept as AKey, or nil if none has that name
function TMainForm.CameraViewItem(const AKey: String): TMenuItem;
var
  I: Integer;
begin
  Result := nil;
  if AKey = String.Empty then
    Exit;
  for I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) and
      SameText(CameraViewKey(CameraMenu.Items[I]), AKey) then
      Exit(CameraMenu.Items[I]);
end;

// Chooses the camera view kept in settings.json, as its menu item would.
// For Variable the dials are first turned to the angles kept with it, each
// dial's OnChange taking its angle, and ApplyAngles covering a dial that
// was already there; a fixed view sets its own angles. Isometric is chosen
// when no view, or an unknown one, is kept.
procedure TMainForm.RestoreCameraView;
var
  Item: TMenuItem;
begin
  Item := CameraViewItem(FSettings.CameraView);
  if Item = ViewVariableItem then
  begin
    FAzimuth := Wrap360(FSettings.VariableAzimuth);
    FPolarAngle := Wrap360(FSettings.VariableInclination);
    FRoll := Wrap360(FSettings.VariableRoll);
    ApplyAngles;
    ViewVariableItemClick(ViewVariableItem);
  end
  else if (Item <> nil) and Assigned(Item.OnClick) then
    Item.OnClick(Item)
  else
    ViewIsometricItemClick(ViewIsometricItem);
end;

// Keeps the camera view and the View menu's on/off items in settings.json for
// the next session. The dials' angles are kept only while Variable is
// checked, so a fixed view leaves the last Variable angles in place. Runs as
// the form is destroyed, where a message box cannot be shown, so a failed
// save is ignored and the next session starts from the last saved state.
procedure TMainForm.SaveViewState;
var
  I: Integer;
begin
  if FSettings = nil then
    Exit;
  for I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) and CameraMenu.Items[I].IsChecked then
      FSettings.CameraView := CameraViewKey(CameraMenu.Items[I]);
  if ViewVariableItem.IsChecked then
  begin
    FSettings.VariableAzimuth := FAzimuth;
    FSettings.VariableInclination := FPolarAngle;
    FSettings.VariableRoll := FRoll;
  end;
  FSettings.ShowBoundingBox := ShowBoundsItem.IsChecked;
  FSettings.ShowGrid := ShowGridItem.IsChecked;
  FSettings.ShowAxes := ShowAxesItem.IsChecked;
  FSettings.ShowSweptVolume := ShowSweepItem.IsChecked;
  FSettings.ShowCombinedSweptVolume := ShowCombinedSweepItem.IsChecked;
  FSettings.Orthographic := OrthographicItem.IsChecked;
  FSettings.PanEnabled := FPanEnabled;
  FSettings.PanX := FPanX;
  FSettings.PanZ := FPanZ;
  try
    FSettings.Save;
  except
    // Nowhere to report it; see above
  end;
end;

procedure TMainForm.AspectLayoutResize(Sender: TObject);
begin
  FitViewportToAspect;
end;

// Makes the viewport, and its background behind it, as large as fits in
// AspectLayout at the aspect ratio of the grab size, centred, on whole
// logical pixels. Its own OnResize then refits the model.
procedure TMainForm.FitViewportToAspect;
var
  Area, Box: TRectF;
  Aspect, W, H: Single;
begin
  if (GorillaViewport = nil) or (FSettings = nil) then
    Exit;   // still being made
  Area := AspectLayout.LocalRect;
  if (Area.Width <= 0) or (Area.Height <= 0) or (FSettings.GrabHeight <= 0) then
    Exit;
  Aspect := FSettings.GrabWidth / FSettings.GrabHeight;
  if Area.Width / Area.Height > Aspect then
  begin
    // Wider than the grabs: full height, grey either side
    H := Area.Height;
    W := H * Aspect;
  end
  else
  begin
    // Taller than the grabs: full width, grey above and below
    W := Area.Width;
    H := W / Aspect;
  end;
  W := Max(1, Trunc(W));
  H := Max(1, Trunc(H));
  Box := TRectF.Create(TPointF.Create(Round((Area.Width - W) / 2),
    Round((Area.Height - H) / 2)), W, H);
  if GorillaViewport.BoundsRect <> Box then
    GorillaViewport.BoundsRect := Box;
  if (FBackground <> nil) and (FBackground.BoundsRect <> Box) then
    FBackground.BoundsRect := Box;
end;

procedure TMainForm.GorillaViewportResize(Sender: TObject);
begin
  if Assigned(FCapture) then
  begin
    // The capture's framing stays until it ends; EndCapture refits then
    FRefitAfterCapture := True;
    Exit;
  end;
  FitModel;
end;

const
  ANIMATION_SETTINGS_FORMAT = 'Sprite3D animation settings';
  ANIMATION_SETTINGS_VERSION = 1;
  ANIMATION_SETTINGS_FILTER =
    'Sprite3D animation settings (*.json)|*.json|All files (*.*)|*.*';
  PROJECT_FILTER = 'Sprite3D project (*.sprite3d)|*.sprite3d|All files (*.*)|*.*';

// File, Save and Load Animation Settings: with a model, while nothing is
// being exported, and on the desktop, which has file dialogs
procedure TMainForm.UpdateListFileItems;
var
  Usable: Boolean;
begin
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  Usable := False;
  {$ELSE}
  Usable := (GorillaModel <> nil) and not Capturing;
  {$ENDIF}
  SaveAnimationSettingsItem.Enabled := Usable;
  LoadAnimationSettingsItem.Enabled := Usable;
  // The credits can be set on every platform; a project file needs the
  // desktop's file dialogs
  CreditsItem.Enabled := not Capturing;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  LoadCreditsItem.Enabled := False;
  {$ELSE}
  LoadCreditsItem.Enabled := not Capturing;
  {$ENDIF}
end;

// The Animations list as it stands, as the JSON File, Save Animation
// Settings writes and a project file holds: every entry in order, with its
// tick and any frame count typed in, and the entry selected. The caller
// owns the object.
function TMainForm.AnimationListToJson: TJSONObject;
var
  Entry: TJSONObject;
  List: TJSONArray;
  Count: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('format', ANIMATION_SETTINGS_FORMAT);
  Result.AddPair('version', TJSONNumber.Create(ANIMATION_SETTINGS_VERSION));
  Result.AddPair('model', ExtractFileName(FModelFile));
  if AnimationListBox.ItemIndex >= 0 then
    Result.AddPair('selected', AnimationListBox.Items[AnimationListBox.ItemIndex])
  else
    Result.AddPair('selected', TJSONNull.Create);
  List := TJSONArray.Create;
  Result.AddPair('animations', List);
  for var I := 0 to AnimationListBox.Count - 1 do
  begin
    Entry := TJSONObject.Create;
    List.AddElement(Entry);
    Entry.AddPair('name', AnimationListBox.Items[I]);
    Entry.AddPair('checked', TJSONBool.Create(AnimationListBox.ListItems[I].IsChecked));
    Count := 0;
    if I > 0 then
      Count := FrameOverride(AnimationListBox.Items[I]);
    if Count > 0 then
      Entry.AddPair('frames', TJSONNumber.Create(Count));
  end;
end;

// Reads an Animations list from JSON written by AnimationListToJson, without
// applying it. False, with AError saying why, if it cannot be used.
function TMainForm.ReadAnimationList(const AValue: TJSONValue;
  out AState: TAnimationListState; out AError: String): Boolean;
var
  Text, Name: String;
  List: TJSONArray;
  Ticked: Boolean;
  Count: Integer;
begin
  Result := False;
  AError := String.Empty;
  AState.Selected := String.Empty;
  AState.Names := nil;
  AState.Checked := nil;
  AState.Frames := nil;
  if not (AValue is TJSONObject) then
  begin
    AError := 'It is not a JSON object.';
    Exit;
  end;
  if TJSONObject(AValue).TryGetValue<String>('format', Text) and
    (Text <> ANIMATION_SETTINGS_FORMAT) then
  begin
    AError := Format('Its format is "%s".', [Text]);
    Exit;
  end;
  if not TJSONObject(AValue).TryGetValue<String>('selected', AState.Selected) then
    AState.Selected := String.Empty;
  List := TJSONObject(AValue).GetValue('animations') as TJSONArray;
  if List = nil then
  begin
    AError := 'It lists no animations ("animations").';
    Exit;
  end;
  for var Element in List do
  begin
    if not (Element is TJSONObject) or
      not TJSONObject(Element).TryGetValue<String>('name', Name) then
      Continue;
    if not TJSONObject(Element).TryGetValue<Boolean>('checked', Ticked) then
      Ticked := False;
    if not TJSONObject(Element).TryGetValue<Integer>('frames', Count) then
      Count := 0;
    AState.Names := AState.Names + [Name];
    AState.Checked := AState.Checked + [Ticked];
    AState.Frames := AState.Frames + [EnsureRange(Count, 0, 9999)];
  end;
  Result := True;
end;

// Applies an Animations list to the model loaded: the animations it lists
// that the model has become the animations used, their ticks and frame
// counts are set, and its selected entry is selected and played. AFrom names
// where it came from, for the messages: those it lists that the model does
// not have are reported, and if it names none of the model's, nothing is
// changed.
procedure TMainForm.ApplyAnimationList(const AState: TAnimationListState;
  const AFrom: String);
var
  Used, Missing: TArray<String>;
  Ticks: TArray<Integer>;
  Listed: Boolean;
  Index: Integer;
begin
  if (GorillaModel = nil) or Capturing then
    Exit;
  // The model's animations it lists, in the model's order, and those it
  // lists that the model does not have
  Used := nil;
  for var Known in FAnimationNames do
    for var I := 0 to High(AState.Names) do
      if AState.Names[I] = Known then
      begin
        Used := Used + [Known];
        Break;
      end;
  Missing := nil;
  for var I := 0 to High(AState.Names) do
    if AState.Names[I] <> NO_ANIMATION then
    begin
      Listed := False;
      for var Known in FAnimationNames do
        Listed := Listed or (Known = AState.Names[I]);
      if not Listed then
        Missing := Missing + [AState.Names[I]];
    end;
  if (Length(Used) = 0) and (Length(Missing) > 0) then
  begin
    ShowMessage('None of the animations in ' + AFrom +
      ' are in this model, so the Animations list was not changed.');
    Exit;
  end;

  // Frame counts, then the animations used, which lists them afresh with
  // nothing ticked, then the ticks and the selection
  FinishFrameEdit(False, True);
  FFrameOverrides.Clear;
  for var I := 0 to High(AState.Names) do
    if (AState.Names[I] <> NO_ANIMATION) and (AState.Frames[I] > 0) then
      FFrameOverrides.AddOrSetValue(AState.Names[I], AState.Frames[I]);
  ApplyUsedAnimations(Used);
  Ticks := nil;
  for var I := 0 to High(AState.Names) do
    if AState.Checked[I] then
    begin
      Index := AnimationListBox.Items.IndexOf(AState.Names[I]);
      if Index >= 0 then
        Ticks := Ticks + [Index];
    end;
  FSyncingChecks := True;
  try
    SetEntryChecks(Ticks, True);
  finally
    FSyncingChecks := False;
  end;
  AnimationListBoxChangeCheck(AnimationListBox);   // All, and the volume shown
  Index := AnimationListBox.Items.IndexOf(AState.Selected);
  if (Index >= 0) and (Index <> AnimationListBox.ItemIndex) then
    AnimationListBox.ItemIndex := Index   // played, as choosing it would
  else
  begin
    // Its frame count may have changed: play it again with the new one
    FChangePlayed := False;
    PlaySelectedAnimation;
  end;
  UpdateFrameCounts;
  UpdateTransportControls;
  DebugMemo.Lines.Add('Applied the animation settings from ' + AFrom);
  if Length(Missing) > 0 then
    ShowMessage('Not in this model, so left out of the Animations list:' + sLineBreak +
      String.Join(sLineBreak, Missing));
end;

procedure TMainForm.SaveAnimationSettingsItemClick(Sender: TObject);
var
  Dialog: TSaveDialog;
  FileName: String;
  Root: TJSONObject;
begin
  if (GorillaModel = nil) or Capturing then
    Exit;
  FinishFrameEdit(True, False);   // a count being typed counts
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := 'Save Animation Settings';
    Dialog.Filter := ANIMATION_SETTINGS_FILTER;
    Dialog.DefaultExt := 'json';
    Dialog.Options := [TOpenOption.ofOverwritePrompt, TOpenOption.ofHideReadOnly,
      TOpenOption.ofPathMustExist, TOpenOption.ofEnableSizing];
    Dialog.InitialDir := ExtractFileDir(FModelFile);
    Dialog.FileName := SafeFileStem(TPath.GetFileNameWithoutExtension(FModelFile)) +
      '_animations.json';
    if not Dialog.Execute or (Dialog.FileName = String.Empty) then
      Exit;
    FileName := Dialog.FileName;
  finally
    Dialog.Free;
  end;
  Root := AnimationListToJson;
  try
    try
      // UTF-8 without a byte order mark, which some JSON readers reject
      TFile.WriteAllBytes(OSFriendlyPath(FileName), JsonToBytes(Root));
      DebugMemo.Lines.Add('Saved the animation settings to ' + FileName);
    except
      on E: Exception do
        ShowMessage('Can''t save the animation settings to ' + FileName + sLineBreak +
          E.Message);
    end;
  finally
    Root.Free;
  end;
end;

procedure TMainForm.LoadAnimationSettingsItemClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  FileName, Error: String;
  Value: TJSONValue;
  State: TAnimationListState;
  Readable: Boolean;
begin
  if (GorillaModel = nil) or Capturing then
    Exit;
  FinishFrameEdit(False, False);
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Load Animation Settings';
    Dialog.Filter := ANIMATION_SETTINGS_FILTER;
    Dialog.DefaultExt := 'json';
    Dialog.Options := [TOpenOption.ofFileMustExist, TOpenOption.ofHideReadOnly,
      TOpenOption.ofEnableSizing];
    Dialog.InitialDir := ExtractFileDir(FModelFile);
    if not Dialog.Execute or (Dialog.FileName = String.Empty) then
      Exit;
    FileName := Dialog.FileName;
  finally
    Dialog.Free;
  end;
  // Read it all before changing anything
  try
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(OSFriendlyPath(FileName),
      TEncoding.UTF8));
    try
      Readable := ReadAnimationList(Value, State, Error);
    finally
      Value.Free;
    end;
  except
    on E: Exception do
    begin
      Readable := False;
      Error := E.Message;
    end;
  end;
  if not Readable then
  begin
    ShowMessage('Can''t load the animation settings from ' + FileName + sLineBreak + Error);
    Exit;
  end;
  ApplyAnimationList(State, ExtractFileName(FileName));
end;

// The meta section of the metadata saved now: page APage of APageCount, the
// image's own frames as the total, the 2-pass and overscan choices, the
// camera, the credits, the day the project started, now, and the model
function TMainForm.ExportMeta(const APage, APageCount: Integer): TSprite3DSheetMeta;
begin
  Result.Page := APage;
  Result.PageCount := APageCount;
  Result.TotalFrames := 0;   // the image's own frames, unless set
  Result.Creator := FCredits.Creator;
  Result.CreatorUrl := FCredits.CreatorUrl;
  Result.Modeller := FCredits.Modeller;
  Result.ModellerUrl := FCredits.ModellerUrl;
  Result.Artist := FCredits.Artist;
  Result.ArtistUrl := FCredits.ArtistUrl;
  Result.Created := FCredits.Created;
  // Local time, with its offset from UTC
  Result.Modified := DateToISO8601(Now, False);
  Result.ModelFile := FModelFile;
  // Whether these frames were made by a 2-pass export's second pass
  Result.TwoPass := FBatchActive and FTwoPassRun;
  Result.OverscanEnabled := FOverscanOn;
  Result.Overscan := FSettings.Overscan;
  // The view checked in View, Camera, by the name settings.json keeps it by
  Result.Camera.View := String.Empty;
  for var I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) and CameraMenu.Items[I].IsChecked then
      Result.Camera.View := CameraViewKey(CameraMenu.Items[I]);
  Result.Camera.Orthographic :=
    GorillaCamera.ProjectionMode = TGorillaCameraProjection.cpOrthographic;
  // The readouts, as shown; a direction's turn is not in them
  Result.Camera.Azimuth := FAzimuth;
  Result.Camera.Inclination := FPolarAngle;
  Result.Camera.Roll := FRoll;
  // As the capture was framed, not the view: the export fits the camera to
  // what it saves, the combined swept volume for a batch
  Result.Camera.Distance := FCaptureDistance;
  Result.Camera.OrthoHeight := FCaptureOrthoHeight;
  Result.Camera.PanEnabled := FPanEnabled;
  Result.Camera.PanX := FPanX;
  Result.Camera.PanZ := FPanZ;
  Result.Camera.Locked := CameraLocked;
end;

// File, Save Project...: the credits, and on OK they are kept for every
// export's metadata and saved, with the model, the directions, the
// Animations list and the export choices, as a project file
procedure TMainForm.CreditsItemClick(Sender: TObject);
var
  Dialog: TCreditsForm;
begin
  Dialog := TCreditsForm.Create(nil);
  Dialog.Credits := FCredits;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here, and there is no save dialog: the credits
  // are kept for this session's exports
  Dialog.OnAccept := CreditsAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    if Dialog.ShowModal <> mrOk then
      Exit;
    FCredits := Dialog.Credits;
  finally
    Dialog.Free;
  end;
  DebugMemo.Lines.Add('Creator credits set');
  SaveProjectAs;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.CreditsAccept(Sender: TObject);
begin
  FCredits := (Sender as TCreditsForm).Credits;
  DebugMemo.Lines.Add('Creator credits set');
end;
{$ENDIF}

// Asks where to save the project file, opening at the last one or beside the
// model, and saves it there
procedure TMainForm.SaveProjectAs;
var
  Dialog: TSaveDialog;
  FileName: String;
begin
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := 'Save Project';
    Dialog.Filter := PROJECT_FILTER;
    Dialog.DefaultExt := PROJECT_FILE_EXTENSION.Substring(1);
    Dialog.Options := [TOpenOption.ofOverwritePrompt, TOpenOption.ofHideReadOnly,
      TOpenOption.ofPathMustExist, TOpenOption.ofEnableSizing];
    if FProjectFile <> String.Empty then
    begin
      Dialog.InitialDir := ExtractFileDir(FProjectFile);
      Dialog.FileName := ExtractFileName(FProjectFile);
    end
    else if FModelFile <> String.Empty then
    begin
      Dialog.InitialDir := ExtractFileDir(FModelFile);
      Dialog.FileName := TPath.GetFileNameWithoutExtension(FModelFile) +
        PROJECT_FILE_EXTENSION;
    end
    else
      Dialog.FileName := 'project' + PROJECT_FILE_EXTENSION;
    if not Dialog.Execute or (Dialog.FileName = String.Empty) then
      Exit;
    FileName := Dialog.FileName;
  finally
    Dialog.Free;
  end;
  SaveProjectFile(FileName);
end;

// Writes the project file: the credits, the model, the directions, the
// Animations list and the export choices
procedure TMainForm.SaveProjectFile(const AFileName: String);
var
  Root, Item: TJSONObject;
begin
  FinishFrameEdit(True, False);
  Root := TJSONObject.Create;
  try
    Root.AddPair('format', PROJECT_FILE_FORMAT);
    Root.AddPair('version', TJSONNumber.Create(PROJECT_FILE_VERSION));
    Root.AddPair('credits', CreditsToJson(FCredits));
    if FModelFile <> String.Empty then
      Root.AddPair('file', ExpandFileName(FModelFile))
    else
      Root.AddPair('file', TJSONNull.Create);
    Root.AddPair('directions', DirectionsToJson(FSettings.DirectionCount,
      FSettings.DirectionStart, FSettings.DirectionOrderList, FSettings.DirectionSnap));
    if GorillaModel <> nil then
      Root.AddPair('animations', AnimationListToJson);
    Item := TJSONObject.Create;
    Root.AddPair('export', Item);
    Item.AddPair('grab_width', TJSONNumber.Create(FSettings.GrabWidth));
    Item.AddPair('grab_height', TJSONNumber.Create(FSettings.GrabHeight));
    Item.AddPair('animation_fps', TJSONNumber.Create(FSettings.AnimationFps));
    Item.AddPair('metadata', TJSONBool.Create(FSettings.ExportMetadata));
    Item.AddPair('directions', TJSONBool.Create(FSettings.ExportDirections));
    Item.AddPair('atlas_page_size', TJSONNumber.Create(FSettings.AtlasPageSize));
    Item.AddPair('atlas_non_power_of_2', TJSONBool.Create(FSettings.AtlasNonPowerOf2));
    try
      // UTF-8 without a byte order mark, which some JSON readers reject
      TFile.WriteAllBytes(OSFriendlyPath(AFileName), JsonToBytes(Root));
      FProjectFile := AFileName;
      DebugMemo.Lines.Add('Saved the project to ' + AFileName);
    except
      on E: Exception do
        ShowMessage('Can''t save the project to ' + AFileName + sLineBreak + E.Message);
    end;
  finally
    Root.Free;
  end;
end;

// File, Load Project...: a project file, applied
procedure TMainForm.LoadCreditsItemClick(Sender: TObject);
var
  Dialog: TOpenDialog;
  FileName: String;
begin
  if Capturing then
    Exit;
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Load Project';
    Dialog.Filter := PROJECT_FILTER;
    Dialog.DefaultExt := PROJECT_FILE_EXTENSION.Substring(1);
    Dialog.Options := [TOpenOption.ofFileMustExist, TOpenOption.ofHideReadOnly,
      TOpenOption.ofEnableSizing];
    if FProjectFile <> String.Empty then
      Dialog.InitialDir := ExtractFileDir(FProjectFile)
    else if FModelFile <> String.Empty then
      Dialog.InitialDir := ExtractFileDir(FModelFile);
    if not Dialog.Execute or (Dialog.FileName = String.Empty) then
      Exit;
    FileName := Dialog.FileName;
  finally
    Dialog.Free;
  end;
  LoadProjectFile(FileName);
end;

// Reads a project file and applies what it holds: the credits; the export
// choices; the directions, kept as Model, Directions keeps them; and, if
// the model it names exists, that model, loaded if it is not the one shown,
// with the Animations list applied once it is in. True if that model is
// being loaded.
function TMainForm.LoadProjectFile(const AFileName: String): Boolean;
var
  Value, Part: TJSONValue;
  Root, Choices: TJSONObject;
  Text, ModelFile, Error: String;
  Version, Number: Integer;
  Flag: Boolean;
  Count: Integer;
  Start: Single;
  Order: TArray<Integer>;
  Snap, HasList: Boolean;
  State: TAnimationListState;
  Notes: TArray<String>;
begin
  Result := False;
  if Capturing then
    Exit;
  Notes := nil;
  HasList := False;
  ModelFile := String.Empty;
  try
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(OSFriendlyPath(AFileName),
      TEncoding.UTF8));
  except
    on E: Exception do
    begin
      ShowMessage('Can''t read the project ' + AFileName + sLineBreak + E.Message);
      Exit;
    end;
  end;
  try
    if not (Value is TJSONObject) then
    begin
      ShowMessage(AFileName + ' is not a Sprite3D project: it is not a JSON object.');
      Exit;
    end;
    Root := TJSONObject(Value);
    if Root.TryGetValue<String>('format', Text) and (Text <> PROJECT_FILE_FORMAT) then
    begin
      ShowMessage(Format('%s is not a Sprite3D project: its format is "%s".',
        [AFileName, Text]));
      Exit;
    end;
    if Root.TryGetValue<Integer>('version', Version) and (Version > PROJECT_FILE_VERSION) then
      Notes := Notes + [Format('It is version %d, from a newer Sprite3D; what this one ' +
        'knows of it was read.', [Version])];

    FCredits := CreditsFromJson(Root.GetValue('credits'));

    // The export choices
    Choices := Root.GetValue('export') as TJSONObject;
    if Choices <> nil then
    begin
      if Choices.TryGetValue<Integer>('grab_width', Number) then
        FSettings.GrabWidth := Number;   // limited to the allowed range
      if Choices.TryGetValue<Integer>('grab_height', Number) then
        FSettings.GrabHeight := Number;
      FOffscreen.Width := FSettings.GrabWidth;
      FOffscreen.Height := FSettings.GrabHeight;
      FitViewportToAspect;
      if Choices.TryGetValue<Integer>('animation_fps', Number) then
        ApplyAnimationFps(Number);
      if Choices.TryGetValue<Boolean>('metadata', Flag) then
        FSettings.ExportMetadata := Flag;
      if Choices.TryGetValue<Boolean>('directions', Flag) then
      begin
        FSettings.ExportDirections := Flag;
        FBatchDirections.IsChecked := Flag;
      end;
      if Choices.TryGetValue<Integer>('atlas_page_size', Number) then
        FSettings.AtlasPageSize := Number;
      if Choices.TryGetValue<Boolean>('atlas_non_power_of_2', Flag) then
        FSettings.AtlasNonPowerOf2 := Flag;
      UpdateBatchControls;
    end;

    // The directions
    Part := Root.GetValue('directions');
    if Part <> nil then
      try
        DirectionsFromJson(Part, Count, Start, Order, Snap);
        FSettings.DirectionSnap := Snap;
        FSettings.DirectionCount := Count;
        FSettings.DirectionStart := Start;
        FSettings.DirectionClockwise := True;
        FSettings.DirectionOrder := DirectionOrderToText(Order);
      except
        on E: EDirectionsFile do
          Notes := Notes + ['Its directions were left as they were: ' + E.Message];
      end;

    // The Animations list, applied once its model is in
    Part := Root.GetValue('animations');
    if Part <> nil then
    begin
      HasList := ReadAnimationList(Part, State, Error);
      if not HasList then
        Notes := Notes + ['Its Animations list was not applied: ' + Error];
    end;
    if not Root.TryGetValue<String>('file', ModelFile) then
      ModelFile := String.Empty;
  finally
    Value.Free;
  end;

  try
    FSettings.Save;
  except
    on E: Exception do
      Notes := Notes + ['Can''t save the settings: ' + E.Message];
  end;
  FProjectFile := AFileName;
  DebugMemo.Lines.Add('Loaded the project ' + AFileName);

  // Its model, if it is there; the list goes with it
  ModelFile := OSFriendlyPath(ModelFile);
  if (ModelFile <> String.Empty) and FileExists(ModelFile) and
    not SameFileName(ExpandFileName(ModelFile), ExpandFileName(FModelFile)) then
  begin
    FPendingListModel := ExpandFileName(ModelFile);
    FPendingList := State;
    FHasPendingList := HasList;
    SwitchModel(ModelFile);
    Result := True;
  end
  else
  begin
    if (ModelFile <> String.Empty) and not FileExists(ModelFile) then
      Notes := Notes + ['Its model is not there: ' + ModelFile];
    if HasList and (GorillaModel <> nil) then
      ApplyAnimationList(State, ExtractFileName(AFileName));
  end;
  if Length(Notes) > 0 then
    ShowMessage('Loaded ' + ExtractFileName(AFileName) + sLineBreak + sLineBreak +
      String.Join(sLineBreak, Notes));
end;

procedure TMainForm.OpenModelMenuItemClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    SwitchModel(OpenDialog1.Filename);
end;

procedure TMainForm.GrabMenuItemClick(Sender: TObject);
begin
  if Capturing then
    Exit;   // an animation is being saved
  if FOffscreen.Busy then
    Exit;   // the last grab has not been saved yet
  if not FSettings.HasSaveFolder and not ChooseSaveFolder then
    Exit;   // no folder, no grab

  if not FOffscreen.Grab(
    procedure(const ABitmap: TBitmap; const AError: String)
    var
      FileName: String;
    begin
      if not Assigned(ABitmap) then
      begin
        ShowMessage('Grab failed: ' + AError);
        Exit;
      end;
      try
        FileName := SaveGrab(ABitmap, SaveFolder, FGrabNumber);
        DebugMemo.Lines.Add('Grabbed ' + FileName);
      except
        on E: Exception do
          ShowMessage('Can''t save the grab in ' + SaveFolder + sLineBreak +
            E.Message);
      end;
    end) then
    ShowMessage('Grab could not start');
end;

// Fit the model to the grab's own shape as FitModel would, to ViewVolume,
// without the test distance factor, keeping the on-screen framing to put
// back
procedure TMainForm.OffscreenBeforeGrab(Sender: TObject;
  const AWidth, AHeight: Integer);
begin
  // Animation exports show the model alone: the helpers drawn on screen to
  // show its box, axes, floor and volumes are left out. Grabs and icons are
  // saved as the view shows them, helpers and all.
  if Assigned(FCapture) then
    HideHelpersForGrab;
  // The on-screen background is a 2D control behind the viewport, so it is
  // never in the grab's frame buffer; grabs add their own backdrop after
  // matting
  // The capture framed the camera once for every frame, and a locked camera
  // is grabbed exactly as it stands
  FGrabFramed := False;
  if Assigned(FCapture) or CameraLocked then
    Exit;
  FSavedFraming := GorillaCamera.SaveFraming;
  FGrabFramed := True;
  if Assigned(GorillaModel) and GrabFit(AWidth, AHeight) and FPanEnabled then
    // The pan as on screen, on top of the grab's own fit
    GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point +
      ModelPanOffset(GorillaModel, FModelBox, FPanX, FPanZ);
end;

// Hides, for one drawing of an animation export, everything drawn on
// screen only to help see the model: its bounding box, axes and grid, and the Model and
// Animation Volume wireframes. Only what is showing is hidden, and
// ShowHelpersAfterGrab shows exactly that again.
procedure TMainForm.HideHelpersForGrab;

  procedure HideIt(const AHelper: TControl3D);
  begin
    if (AHelper <> nil) and AHelper.Visible then
    begin
      AHelper.Visible := False;
      FGrabHidden := FGrabHidden + [AHelper];
    end;
  end;

begin
  ShowHelpersAfterGrab;   // anything still hidden from a grab that ended early
  if GorillaModel = nil then
    Exit;
  FGrabHidBounds := GorillaModel.ShowBoundingBox;
  if FGrabHidBounds then
    GorillaModel.ShowBoundingBox := False;
  // The axes and grid draw beside the model, not as their own children, so
  // they are hidden with Shown rather than Visible
  FGrabHidAxes := FindModelAxes(GorillaModel);
  if (FGrabHidAxes <> nil) and FGrabHidAxes.Shown then
    FGrabHidAxes.Shown := False
  else
    FGrabHidAxes := nil;
  FGrabHidGrid := FindModelGrid(GorillaModel);
  if (FGrabHidGrid <> nil) and FGrabHidGrid.Shown then
    FGrabHidGrid.Shown := False
  else
    FGrabHidGrid := nil;
  HideIt(FindModelSweep(GorillaModel));
  HideIt(FindCombinedSweep(GorillaModel));
end;

// Shows again what HideHelpersForGrab hid, before the main pass draws
procedure TMainForm.ShowHelpersAfterGrab;
begin
  for var Helper in FGrabHidden do
    Helper.Visible := True;
  FGrabHidden := nil;
  if FGrabHidAxes <> nil then
    FGrabHidAxes.Shown := True;
  FGrabHidAxes := nil;
  if FGrabHidGrid <> nil then
    FGrabHidGrid.Shown := True;
  FGrabHidGrid := nil;
  if FGrabHidBounds and (GorillaModel <> nil) then
    GorillaModel.ShowBoundingBox := True;
  FGrabHidBounds := False;
end;

// Put the on-screen framing back before the main pass draws
procedure TMainForm.OffscreenAfterGrab(Sender: TObject);
begin
  ShowHelpersAfterGrab;
  // Only a framing this grab set is put back
  if not FGrabFramed then
    Exit;
  FGrabFramed := False;
  GorillaCamera.RestoreFraming(FSavedFraming);
end;

procedure TMainForm.BackgroundSettingsMenuItemClick(Sender: TObject);
var
  Dialog: TBackgroundSettingsForm;
begin
  Dialog := TBackgroundSettingsForm.Create(nil);
  Dialog.Spec := FSettings.BackgroundSpec;
  // Every change shows in the viewport at once
  Dialog.OnPreview := BackgroundDialogPreview;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog reports OK or Cancel and frees
  // itself
  Dialog.OnAccept := BackgroundDialogAccept;
  Dialog.OnCancel := BackgroundDialogCancel;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    if Dialog.ShowModal = mrOk then
      ApplyBackground(Dialog.Spec, True)
    else
      // The previews changed the viewport; put back the background in use
      ApplyBackground(FSettings.BackgroundSpec, False);
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

// Shows the dialog's background in the viewport without keeping it: grabs
// and settings.json keep the one in use until OK
procedure TMainForm.BackgroundDialogPreview(Sender: TObject);
begin
  FBackground.Spec := TBackgroundSettingsForm(Sender).Spec;
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.BackgroundDialogAccept(Sender: TObject);
begin
  ApplyBackground(TBackgroundSettingsForm(Sender).Spec, True);
end;

procedure TMainForm.BackgroundDialogCancel(Sender: TObject);
begin
  ApplyBackground(FSettings.BackgroundSpec, False);
end;
{$ENDIF}

// The most File, Settings offers for the view's frame rate: the refresh rate
// of the display the form is on, or VIEW_FPS_DEFAULT where the system does
// not say
function TMainForm.ViewFpsLimit: Integer;
begin
  if FDisplays = nil then
  begin
    FDisplays := TPeardoxDisplays.Create;
    FDisplayIndex := FDisplays.IndexOfForm(Self);
  end;
  Result := FDisplays.RefreshRateFor(Self);
  if Result < VIEW_FPS_MIN then
    Result := VIEW_FPS_DEFAULT;
end;

// The view's frame rate: the one File, Settings asks for, but never more
// than the display the form is on can show. The rate asked for is kept, so
// moving back to a faster display brings it back.
procedure TMainForm.ApplyViewFps;
var
  Limit, Rate: Integer;
begin
  if GorillaViewport = nil then
    Exit;
  Limit := ViewFpsLimit;
  Rate := Min(FSettings.ViewFps, Limit);
  if Round(GorillaViewport.FixedFrameRate) = Rate then
    Exit;
  GorillaViewport.FixedFrameRate := Rate;
  if Rate < FSettings.ViewFps then
    DebugMemo.Lines.Add(Format('The view is drawn at %d frames per second, as this ' +
      'display refreshes at %d; %d is asked for', [Rate, Limit, FSettings.ViewFps]))
  else
    DebugMemo.Lines.Add(Format('The view is drawn at up to %d frames per second', [Rate]));
end;

// Whether the form is on another display than before, as after being moved
// across; if so the displays are read again and the frame rate kept within
// the new one's. Checking is cheap, so it is done with each readout refresh.
procedure TMainForm.CheckDisplay;
var
  Index: Integer;
begin
  if FDisplays = nil then
    Exit;
  Index := FDisplays.IndexOfForm(Self);
  if Index = FDisplayIndex then
    Exit;
  // Another display, or one plugged in or changed: read them all afresh
  FreeAndNil(FDisplays);
  FDisplays := TPeardoxDisplays.Create;
  FDisplayIndex := FDisplays.IndexOfForm(Self);
  ApplyViewFps;
end;

procedure TMainForm.SettingsMenuItemClick(Sender: TObject);
var
  Dialog: TGeneralSettingsForm;
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  Before: TSprite3DGeneralSettings;
  {$ENDIF}
begin
  Dialog := TGeneralSettingsForm.Create(nil);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  FSettingsBefore := ReadGeneralSettings(FSettings);
  FSettingsBefore.MaxViewFps := ViewFpsLimit;
  Dialog.Values := FSettingsBefore;
  // ShowModal cannot block here: the dialog reports OK and frees itself
  Dialog.OnAccept := SettingsDialogAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    Before := ReadGeneralSettings(FSettings);
    Before.MaxViewFps := ViewFpsLimit;
    Dialog.Values := Before;
    if Dialog.ShowModal = mrOk then
      ApplyGeneralSettings(Before, Dialog.Values);
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.SettingsDialogAccept(Sender: TObject);
begin
  ApplyGeneralSettings(FSettingsBefore, TGeneralSettingsForm(Sender).Values);
end;
{$ENDIF}

// Carries out the Settings dialog's choices that changed, keeps them all in
// settings.json, and tells the user anything they need to know
procedure TMainForm.ApplyGeneralSettings(const AOld, ANew: TSprite3DGeneralSettings);
var
  Notes: TStringList;
  Note: String;
begin
  Notes := TStringList.Create;
  try
    if (ANew.OpenWith <> AOld.OpenWith) or (ANew.AlwaysOpenWith <> AOld.AlwaysOpenWith) then
    begin
      ApplyFileAssociations(FSettings, ANew.OpenWith, ANew.AlwaysOpenWith, Note);
      if Note <> String.Empty then
        Notes.Add(Note);
    end;

    if ANew.Theme <> AOld.Theme then
    begin
      if not ApplyTheme(ANew.Theme, Note) then
        Notes.Add(Note);
      FSettings.ThemeKind := ANew.Theme;
    end;

    if GpuModeSupported and (ANew.GpuMode <> AOld.GpuMode) then
    begin
      if WriteGpuMode(ANew.GpuMode) then
      begin
        FSettings.GpuMode := ANew.GpuMode;
        Notes.Add('The graphics processor choice takes effect the next time Sprite3D ' +
          'starts.');
      end
      else
        Notes.Add('Can''t store the graphics processor choice in the registry.');
    end;

    if (ANew.GrabWidth <> AOld.GrabWidth) or (ANew.GrabHeight <> AOld.GrabHeight) then
    begin
      FSettings.GrabWidth := ANew.GrabWidth;   // limited to the allowed range
      FSettings.GrabHeight := ANew.GrabHeight;
      FOffscreen.Width := FSettings.GrabWidth;
      FOffscreen.Height := FSettings.GrabHeight;
      // The view on screen takes the grabs' new shape
      FitViewportToAspect;
      DebugMemo.Lines.Add(Format('Grabs are now %d x %d pixels',
        [FSettings.GrabWidth, FSettings.GrabHeight]));
    end;

    if ANew.ViewFps <> AOld.ViewFps then
    begin
      FSettings.ViewFps := ANew.ViewFps;   // limited to the allowed range
      ApplyViewFps;
    end;

    // Every JSON file written from now on, settings.json included
    if ANew.MinifyJson <> AOld.MinifyJson then
      FSettings.MinifyJson := ANew.MinifyJson;

    if ANew.SaveFolder <> AOld.SaveFolder then
    begin
      // Only ever emptied by the dialog: the next grab asks for a folder,
      // and numbering starts again at 1 there
      FSettings.SaveFolder := ANew.SaveFolder;
      FGrabNumber := 1;
      DebugMemo.Lines.Add('Grab folder cleared; the next grab asks for one');
    end;

    FSettings.StartupAction := ANew.StartupAction;
    try
      FSettings.Save;
    except
      on E: Exception do
        Notes.Add('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
          E.Message);
    end;

    for var Line in Notes do
      DebugMemo.Lines.Add(Line);
    if Notes.Count > 0 then
      ShowMessage(Notes.Text.Trim);
  finally
    Notes.Free;
  end;
end;

// Shows ASpec in the viewport and uses it for grabs; with ASave, also keeps
// it in settings.json
procedure TMainForm.ApplyBackground(const ASpec: TSprite3DBackgroundSpec;
  const ASave: Boolean);
begin
  FBackground.Spec := ASpec;
  FOffscreen.Backdrop := ASpec;
  if not ASave then
    Exit;
  FSettings.BackgroundSpec := ASpec;
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

function TMainForm.GetSaveFolder: String;
begin
  Result := FSettings.SaveFolder;
end;

// Keep the folder and write settings.json straight away, so it survives
// however the session ends
procedure TMainForm.SetSaveFolder(const Value: String);
begin
  FSettings.SaveFolder := Value;
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

procedure TMainForm.SaveAsIconMenuItemClick(Sender: TObject);
var
  FileName: String;
  Writer: TSprite3DIconWriterClass;
begin
  if Capturing then
    Exit;   // an animation is being saved
  if FOffscreen.Busy then
    Exit;   // a grab is still under way
  if not ChooseIconFile(FileName, Writer) then
    Exit;

  if not FOffscreen.GrabSizes(Writer.DefaultSizes,
    procedure(const AImages: TArray<TBitmap>; const AError: String)
    var
      Icon: TSprite3DIconWriter;
    begin
      if AError <> String.Empty then
      begin
        ShowMessage('Icon failed: ' + AError);
        Exit;
      end;
      Icon := Writer.Create;
      try
        try
          Icon.SaveToFile(AImages, FileName);
          DebugMemo.Lines.Add('Saved icon ' + FileName);
        except
          on E: Exception do
            ShowMessage('Can''t save ' + FileName + sLineBreak + E.Message);
        end;
      finally
        Icon.Free;
      end;
    end) then
    ShowMessage('Icon could not start');
end;

// Ask which file, and so which format, to save the icon as. The dialog
// offers every registered format and opens where the last icon went; the
// chosen folder is kept for next time. Android and iOS have no save
// dialog, so there the first format is used with a numbered name.
function TMainForm.ChooseIconFile(out AFileName: String;
  out AWriter: TSprite3DIconWriterClass): Boolean;
var
  Writers: TArray<TSprite3DIconWriterClass>;
  Index: Integer;
begin
  Writers := IconWriters;
  AWriter := Writers[0];
  AFileName := AutoIconFileName(AWriter.FileExtension);
  if AFileName <> String.Empty then
    Exit(True);

  SaveIconDialog.Filter := IconDialogFilter;
  SaveIconDialog.FilterIndex := 1;
  SaveIconDialog.InitialDir := FSettings.IconFolder;
  SaveIconDialog.FileName := String.Empty;
  Result := SaveIconDialog.Execute and (SaveIconDialog.FileName <> String.Empty);
  if not Result then
    Exit;

  Index := SaveIconDialog.FilterIndex - 1;
  if (Index >= 0) and (Index <= High(Writers)) then
    AWriter := Writers[Index];
  AFileName := AWriter.FixFileName(SaveIconDialog.FileName);

  FSettings.IconFolder := ExtractFileDir(AFileName);
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

// Ask for the grab folder with a "Save Location" dialog, or, where there is
// no such dialog (Android, iOS), take the fixed folder. On a choice,
// SaveFolder takes it and numbering restarts at 1; on cancel nothing changes.
function TMainForm.ChooseSaveFolder: Boolean;
var
  Dir: String;
begin
  Dir := DefaultGrabFolder;
  if Dir <> String.Empty then
    Result := True
  else
  begin
    Dir := SaveFolder;
    Result := SelectDirectory('Save Location', String.Empty, Dir) and
      (Dir <> String.Empty);
  end;
  if Result then
  begin
    SaveFolder := Dir;
    FGrabNumber := 1;
  end;
end;


procedure TMainForm.ExitMenuItemClick(Sender: TObject);
begin
  Close;   // closing the main form ends the application
end;

// Remove the check from every item in the View menu, so a new item needs
// no changes here
procedure TMainForm.ClearViewChecks;
var
  I: Integer;
begin
  for I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) then
      CameraMenu.Items[I].IsChecked := False;
end;

// The pattern for every fixed view: clear all the checks, set the view,
// then check the item that chose it
procedure TMainForm.SelectFixedView(const AItem: TMenuItem;
  const APolarAngle, AAzimuth: Single);
begin
  if CameraLocked then
    Exit;   // the views are switched off while the camera is locked
  ClearViewChecks;
  SetPolarViewAngle(APolarAngle, AAzimuth);
  AItem.IsChecked := True;
end;

procedure TMainForm.ViewVariableItemClick(Sender: TObject);
var
  Dialog: TOrbitalSettingsForm;
begin
  if CameraLocked then
    Exit;   // the views are switched off while the camera is locked
  // While the form is being created (RestoreCameraView) there is nothing to
  // show the dialog over; the angles are already set
  if FSetupComplete then
  begin
    Dialog := TOrbitalSettingsForm.Create(nil);
    Dialog.CameraSpec := CurrentCameraSpec;
    Dialog.OnPreview := OrbitalDialogPreview;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    // ShowModal cannot block here: the dialog reports OK or Cancel and
    // frees itself
    Dialog.OnAccept := OrbitalDialogAccept;
    Dialog.OnCancel := OrbitalDialogCancel;
    Dialog.ShowAndFree;
    {$ELSE}
    try
      if Dialog.ShowModal = mrOk then
        AcceptCameraSpec(Dialog.CameraSpec)
      else
        RestoreCamera;   // the previews moved the camera; put it back
    finally
      Dialog.Free;
    end;
    {$ENDIF}
  end;
  ClearViewChecks;
  ViewVariableItem.IsChecked := True;
end;

// The dialog's starting values: what the camera is showing now
function TMainForm.CurrentCameraSpec: TCameraSettings;
begin
  Result.Azimuth := FAzimuth;
  Result.Roll := FRoll;
  Result.PolarAngle := FPolarAngle;
  Result.Distance := FFactor;
  Result.PanEnabled := FPanEnabled;
  Result.PanX := FPanX;
  Result.PanZ := FPanZ;
end;

// Shows ASpec in the viewport without keeping it: the form's own fields
// stay as they are, so RestoreCamera can undo it
procedure TMainForm.ShowCameraSpec(const ASpec: TCameraSettings);
begin
  if CameraLocked or not Assigned(GorillaCamera) then
    Exit;
  GorillaCamera.Azimuth := Wrap360(-ASpec.Azimuth);
  GorillaCamera.PolarAngle := ASpec.PolarAngle;
  GorillaCamera.Roll := Wrap360(-ASpec.Roll);
  ShowDistanceFactor(ASpec.Distance);
  ShowPan(ASpec.PanEnabled, ASpec.PanX, ASpec.PanZ);
end;

// Keeps ASpec, from the dialog's OK, and shows it
procedure TMainForm.AcceptCameraSpec(const ASpec: TCameraSettings);
begin
  FAzimuth := ASpec.Azimuth;
  FRoll := ASpec.Roll;
  FPolarAngle := ASpec.PolarAngle;
  FFactor := ASpec.Distance;
  FPanEnabled := ASpec.PanEnabled;
  FPanX := EnsureRange(ASpec.PanX, -PAN_LIMIT, PAN_LIMIT);
  FPanZ := EnsureRange(ASpec.PanZ, -PAN_LIMIT, PAN_LIMIT);
  RestoreCamera;
  Caption := ProjectionCaption;
  // Kept straight away; SaveViewState writes them again on the way out
  FSettings.PanEnabled := FPanEnabled;
  FSettings.PanX := FPanX;
  FSettings.PanZ := FPanZ;
  try
    FSettings.Save;
  except
    on E: Exception do
      DebugMemo.Lines.Add('Can''t save the settings: ' + E.Message);
  end;
end;

// Shows the form's own camera state again, after a preview
procedure TMainForm.RestoreCamera;
begin
  ApplyAngles;
  ApplyDistance;
  ApplyPan;
end;

procedure TMainForm.OrbitalDialogPreview(Sender: TObject);
begin
  ShowCameraSpec(TOrbitalSettingsForm(Sender).CameraSpec);
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.OrbitalDialogAccept(Sender: TObject);
begin
  AcceptCameraSpec(TOrbitalSettingsForm(Sender).CameraSpec);
end;

procedure TMainForm.OrbitalDialogCancel(Sender: TObject);
begin
  RestoreCamera;
end;
{$ENDIF}

// The window's caption: the projection, and a reminder when a pan is in use
function TMainForm.ProjectionCaption: String;
begin
  if GorillaCamera.ProjectionMode = TGorillaCameraProjection.cpOrthographic then
    Result := 'Orthographic'
  else if GorillaCamera.ProjectionMode = TGorillaCameraProjection.cpPerspective then
    Result := 'Perspective'
  else
    Result := 'Some other projection';
  if FPanEnabled and ((FPanX <> 0) or (FPanZ <> 0)) then
    Result := Result + ' (panned)';
  if CameraLocked then
    Result := Result + ' (camera locked)';
end;

procedure TMainForm.ViewIsometricItemClick(Sender: TObject);
begin
  // ArcTan(1 / Sqrt(2)), about 35.264 degrees
  SelectFixedView(ViewIsometricItem, RadToDeg(ArcTan(1 / Sqrt(2))));
end;

procedure TMainForm.ViewOneQuarterItemClick(Sender: TObject);
begin
  // Military projection's 45 degrees, through the orthographic camera. The
  // projection is switched, and the model refitted, to match.
  ApplyProjection;
  SelectFixedView(ViewOneQuarterItem, 22.5);
end;

procedure TMainForm.ViewPixel2To1ItemClick(Sender: TObject);
begin
  // ArcTan(1 / 2), about 26.565 degrees: floor lines run 2 across per 1 up
  SelectFixedView(ViewPixel2To1Item, RadToDeg(ArcTan(0.5)));
end;

procedure TMainForm.ViewRoot2ItemClick(Sender: TObject);
begin
  // ArcTan(Sqrt(2))
  SelectFixedView(ViewRoot2Item, RadToDeg(ArcTan(Sqrt(2))));
end;

procedure TMainForm.ViewThreeQuarterItemClick(Sender: TObject);
begin
  // Military projection's 45 degrees, through the orthographic camera. The
  // projection is switched, and the model refitted, to match.
//  OrthographicItem.IsChecked := True;
  ApplyProjection;
  SelectFixedView(ViewThreeQuarterItem, 45);
end;

procedure TMainForm.ViewGoldenRatioItemClick(Sender: TObject);
begin
  // ArcTan(1.61803398875)
  SelectFixedView(ViewGoldenRatioItem, RadToDeg(ArcTan(1.61803398875)));
end;

procedure TMainForm.ViewHeadOnItemClick(Sender: TObject);
begin
  // Level with the model, looking straight along its Z axis
  SelectFixedView(ViewHeadOnItem, 0, 0);
end;

procedure TMainForm.ViewTopDownItemClick(Sender: TObject);
begin
  // Straight down onto the model
  SelectFixedView(ViewTopDownItem, 90, 0);
end;

procedure TMainForm.ViewSideItemClick(Sender: TObject);
begin
  // Level with the model, from the side: a quarter turn from Head On
  SelectFixedView(ViewSideItem, 0, 90);
end;

// Sets a fixed view: the given inclination and azimuth (45 unless given)
// with roll 0, all as shown on the readouts, with the dials turned to
// match and switched off, then refits. The View menu checks are the
// caller's job.
procedure TMainForm.SetPolarViewAngle(const APolarAngle, AAzimuth: Single);
const
  FIXED_ROLL = 0;
begin
  // The dial fields hold the readout values; ApplyAngles sends azimuth to
  // the camera reversed, as it does for the dial
  FAzimuth := AAzimuth;
  FPolarAngle := APolarAngle;
  FRoll := FIXED_ROLL;
  // Turn the dials to match; their OnChange reads the same angles back
  ApplyAngles;
  FitModel;   // a deliberate change of view, so frame the model for it
end;

// Refit after a change of model, size, projection, animation or ticks, to
// ViewVolume: the combined swept volume while animations are ticked for export
// playing or paused, so everything a batch exports is framed alike, and
// otherwise the volume of what is shown alone, as large as the view allows.
// The dials do not call this: with the orbit centre on the turning axis, the
// fit already allows for turning the azimuth.
function TMainForm.FitModel: Boolean;
begin
  Result := not CameraLocked and Assigned(GorillaCamera) and Assigned(GorillaModel);
  if not Result then
    Exit;
  Result := FitCameraToSweep(GorillaCamera, GorillaModel, ViewVolume);
  if Result then
  begin
    // Remember the fit, then apply the test distance factor and the pan on
    // top of it
    FFitDistance := GorillaCamera.Distance;
    FFitOrthoHeight := GorillaCamera.OrthoHeight;
    FFitCenter := GorillaCamera.OrbitCenter.Point;
    FFitted := True;
    ApplyDistance;
    ApplyPan;
  end;
end;

// Test only: the fitted view moved out by the distance slider's factor
procedure TMainForm.ApplyDistance;
begin
  ShowDistanceFactor(FFactor);
end;

procedure TMainForm.ShowDistanceFactor(const AFactor: Single);
begin
  if CameraLocked or not Assigned(GorillaCamera) or (FFitDistance <= 0) then
    Exit;
  if GorillaCamera.IsOrthographic then
    GorillaCamera.OrthoHeight := FFitOrthoHeight * AFactor
  else
    GorillaCamera.Distance := FFitDistance * AFactor;
end;

procedure TMainForm.ApplyPan;
begin
  ShowPan(FPanEnabled, FPanX, FPanZ);
end;

// The orbit centre from the last fit, moved by the pan if it is on. Only the
// centre moves: the angles, distance and orthographic size are untouched.
procedure TMainForm.ShowPan(const AEnabled: Boolean; const APanX, APanZ: Single);
var
  Center: TPoint3D;
begin
  if CameraLocked or not Assigned(GorillaCamera) or not FFitted then
    Exit;
  Center := FFitCenter;
  if AEnabled then
    Center := Center + ModelPanOffset(GorillaModel, FModelBox, APanX, APanZ);
  GorillaCamera.OrbitCenter.Point := Center;
end;

procedure TMainForm.DistanceTrackChange(Sender: TObject);
begin
  ApplyDistance;
end;

// The combined volume: the rest pose's and that of each animation used, all
// measured as the model loaded; framed while animations are ticked, and by
// batch exports
function TMainForm.SweepFitVolume: TSweptVolume;
begin
  Result := CombinedSweptVolume(GorillaModel, FModelBox, FAnimationBounds,
    FUsedAnimations, True, saY);
end;

// One animation's own swept volume, without the rest pose's, for saving
// that animation alone; not Valid if it had no pose to measure
function TMainForm.AnimationSweptVolume(const AName: String): TSweptVolume;
begin
  Result := CombinedSweptVolume(GorillaModel, FModelBox, FAnimationBounds,
    TArray<String>.Create(AName), False, saY);
end;

// The grab's own fit, for OffscreenBeforeGrab: as FitModel's, for a view of
// AWidth by AHeight
function TMainForm.GrabFit(const AWidth, AHeight: Integer): Boolean;
begin
  Result := FitCameraToSweep(GorillaCamera, GorillaModel, ViewVolume, AWidth, AHeight);
end;

// How many animations are ticked for export; (None), entry 0, the turn,
// is not an animation and does not count
function TMainForm.TickedAnimationCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to AnimationListBox.Count - 1 do
    if AnimationListBox.ListItems[I].IsChecked then
      Inc(Result);
end;

// Whether the view shows the combined volume: while two or more animations
// are ticked for export, as a batch frames them all alike, playing or
// paused. With one ticked, or none, it shows the volume of what is on
// screen alone, playing or paused.
function TMainForm.UsesCombinedView: Boolean;
begin
  Result := (GorillaModel <> nil) and (TickedAnimationCount >= 2);
end;

// The volume the view is fitted to and grabs are framed by: the combined one
// when UsesCombinedView, otherwise the selected animation's own, or the rest
// pose's for (None) and for a model without animations
function TMainForm.ViewVolume: TSweptVolume;
begin
  if UsesCombinedView then
    Exit(SweepFitVolume);
  if AnimationListBox.ItemIndex > 0 then
  begin
    Result := AnimationSweptVolume(AnimationListBox.Items[AnimationListBox.ItemIndex]);
    if Result.Valid then
      Exit;
  end;
  // The rest pose alone: no animation named
  Result := CombinedSweptVolume(GorillaModel, FModelBox, FAnimationBounds, nil, True, saY);
end;

// The combined wireframe and the fit, after anything that changes which
// volume the view shows. During a capture both wait until it ends.
procedure TMainForm.UpdateView;
begin
  if Capturing then
  begin
    FRefitAfterCapture := True;
    Exit;
  end;
  ApplyShowCombinedSweep;
  FitModel;
end;

procedure TMainForm.ShowAxesItemClick(Sender: TObject);
begin
  ShowAxesItem.IsChecked := not ShowAxesItem.IsChecked;
  ApplyShowAxes;
end;

procedure TMainForm.ShowBoundsItemClick(Sender: TObject);
begin
  ShowBoundsItem.IsChecked := not ShowBoundsItem.IsChecked;
  ApplyShowBounds;
end;

procedure TMainForm.ShowGridItemClick(Sender: TObject);
begin
  ShowGridItem.IsChecked := not ShowGridItem.IsChecked;
  ApplyShowGrid;
end;

procedure TMainForm.ShowSweepItemClick(Sender: TObject);
begin
  ShowSweepItem.IsChecked := not ShowSweepItem.IsChecked;
  ApplyShowSweep;
end;

procedure TMainForm.ShowCombinedSweepItemClick(Sender: TObject);
begin
  ShowCombinedSweepItem.IsChecked := not ShowCombinedSweepItem.IsChecked;
  ApplyShowCombinedSweep;
end;

// The combined swept volume, to match ShowCombinedSweepItem, and only while
// the view frames it (UsesCombinedView): the volume joined over the rest
// pose and the animations used. Nothing without a model.
procedure TMainForm.ApplyShowCombinedSweep;
begin
  if not ShowCombinedSweepItem.IsChecked then
  begin
    HideCombinedSweep(GorillaModel);
    Exit;
  end;
  // A model without animations, or with none used, has no animation volume
  // to show: it would only repeat the rest pose's. Nor is it shown unless
  // the view is of the combined volume: two or more animations ticked.
  if (GorillaModel = nil) or (Length(FUsedAnimations) = 0) or not UsesCombinedView then
  begin
    HideCombinedSweep(GorillaModel);
    Exit;
  end;
  ShowCombinedSweep(GorillaModel, SweepFitVolume);
end;

// The model's axes to match ShowAxesItem; nothing without a model
procedure TMainForm.ApplyShowAxes;
begin
  if ShowAxesItem.IsChecked then
    ShowModelAxes(GorillaModel)
  else
    HideModelAxes(GorillaModel);
end;

// The model's bounding box to match ShowBoundsItem; nothing without a model
procedure TMainForm.ApplyShowBounds;
begin
  if GorillaModel <> nil then
    GorillaModel.ShowBoundingBox := ShowBoundsItem.IsChecked;
end;

// The floor grid to match ShowGridItem, on the model's own bounds as
// loaded; nothing without a model
procedure TMainForm.ApplyShowGrid;
begin
  if ShowGridItem.IsChecked then
    ShowModelGrid(GorillaModel, FModelBox)
  else
    HideModelGrid(GorillaModel);
end;

// The volume swept turning about the model's up axis, to match
// ShowSweepItem: the rest pose's from the model's own bounds as loaded, and
// one per animation, measured as the model loaded, so the wireframe follows
// whichever animation plays. Nothing without a model.
procedure TMainForm.ApplyShowSweep;
begin
  if not ShowSweepItem.IsChecked then
  begin
    HideModelSweep(GorillaModel);
    Exit;
  end;
  if GorillaModel = nil then
    Exit;

  ShowModelSweep(GorillaModel, FModelBox, FAnimationBounds, saY);
end;

// Looks for the video libraries, which can take a while to load, so the
// desktop does it after the first model is shown; offers MP4 if they load,
// and fetches OpenH264 in the background if it is missing or out of date
procedure TMainForm.StartVideo;
begin
  if VideoAvailable then
  begin
    if Assigned(FMp4Item) then
      FMp4Item.Enabled := True;
    // In TSheetKind's order: the item index is the kind
    if Assigned(FBatchKindBox) and (FBatchKindBox.Items.Count = Ord(skMp4)) then
    begin
      FBatchKindBox.Items.Add('MP4 video');
      // MP4 chosen last session, now it can be
      if not Capturing then
        RestoreBatchKind;
    end;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    if Assigned(FAnimationMenu) then
    begin
      var Item := TMenuItem.Create(Self);
      Item.Text := 'Save as MP4 video';
      Item.OnClick := SaveMp4ItemClick;
      FAnimationMenu.AddObject(Item);
    end;
    {$ENDIF}
  end;
  DebugMemo.Lines.Add(VideoStatus);
  StartOpenH264Update;
end;

// Loads AModel in place of the model shown, with a dialog showing how far it
// has got and what it is doing, and an Abort button. The load runs in
// stages from FLoadTimer, a tick at a time, so the dialog is drawn and Abort
// is seen between them: the file is read on a worker thread, which brings it
// into the system's file cache; Gorilla3D builds the model from it in one
// step, which cannot be interrupted; its animations are measured a slice at
// a time, unless the bounds cache has them; and it then replaces the old
// model. The new model is built beside the old one, which is left alone
// until then, so an abort, or a failure at any stage, puts everything back
// as it was: the old model, or none at start-up.
// On the desktop the dialog is modal and this returns once the load has
// ended; on Android and iOS it returns at once. A model asked for while a
// load is under way, as by a file opened from the system, is loaded after it.
procedure TMainForm.SwitchModel(const AModel: String);
var
  Dialog: TModelLoadForm;
  Model: String;
begin
  // In this platform's own form, whoever named it: a dialog, the system, a
  // setting kept from another platform, or a constant
  Model := OSFriendlyPath(AModel);
  if (Model = String.Empty) or (not FileExists(Model)) then
    begin
      ShowMessage('Model Not Found ' + Model);
      Exit;
    end;
  if FLoadStage <> lsNone then
  begin
    FPendingModel := Model;
    Exit;
  end;
  if Capturing then
    begin
      ShowMessage('An animation is being saved; open the model again when it is done.');
      Exit;
    end;

  FLoadFile := ExpandFileName(Model);
  FLoadAborted := False;
  FLoadError := String.Empty;
  FLoadRead := StartModelFileRead(FLoadFile);
  FLoadStage := lsRead;
  Dialog := TModelLoadForm.Create(nil);
  FLoadDialog := Dialog;
  Dialog.SetModelName(ExtractFileName(FLoadFile));
  Dialog.SetProgress(0, 'Reading the file...');
  Dialog.OnAbort := LoadDialogAbort;
  Caption := 'Loading ' + ExtractFileName(FLoadFile) + '...';
  FLoadTimer.Enabled := True;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog frees itself when the load ends,
  // and EndLoad reports
  Dialog.ShowAndFree;
  {$ELSE}
  try
    Dialog.ShowModal;
  finally
    // ShowModal only returns once EndLoad has closed the dialog; if it ever
    // returned sooner, the load is dropped here
    FLoadDialog := nil;
    if FLoadStage <> lsNone then
      EndLoad(String.Empty);
    Dialog.Free;
  end;
  ReportLoadEnd;
  {$ENDIF}
end;

// Abort, from the dialog: the read stops at once, and the next tick drops
// the load. During the build, which cannot be interrupted, the click is
// seen as soon as Gorilla3D returns.
procedure TMainForm.LoadDialogAbort(Sender: TObject);
begin
  FLoadAborted := True;
  if FLoadRead <> nil then
    FLoadRead.Cancel;
end;

// One tick of the load: one stage's worth of work, or a slice of it
procedure TMainForm.LoadTimerTimer(Sender: TObject);
var
  Done, Total: Int64;
  Fraction: Single;
begin
  if FLoadStage = lsNone then
  begin
    FLoadTimer.Enabled := False;
    Exit;
  end;
  if FLoadDialog = nil then
    FLoadAborted := True;   // the dialog has gone: nothing to report to
  if FLoadAborted then
  begin
    DebugMemo.Lines.Add('Load aborted: ' + FLoadFile);
    EndLoad(String.Empty);
    Exit;
  end;
  try
    case FLoadStage of
      lsRead:
        if not FLoadRead.Done then
        begin
          Done := FLoadRead.BytesRead;
          Total := FLoadRead.TotalBytes;
          if Total > 0 then
            Fraction := Done / Total
          else
            Fraction := 0;
          FLoadDialog.SetProgress(LOAD_READ_END * Fraction,
            Format('Reading the file: %.1f of %.1f MB',
              [Done / (1024 * 1024), Total / (1024 * 1024)]));
        end
        else if FLoadRead.Error <> String.Empty then
          raise EInOutError.Create(FLoadRead.Error)
        else
        begin
          // Said before the build starts, on the next tick, so the dialog
          // is drawn saying so while Gorilla3D works
          FLoadRead := nil;
          FLoadDialog.SetProgress(LOAD_READ_END, 'Building the model...');
          FLoadStage := lsBuild;
        end;
      lsBuild:
        BuildLoadModel;
      lsMeasure:
        MeasureLoadModel;
      lsCommit:
        CommitLoad;
    end;
  except
    on E: Exception do
      EndLoad('Can''t Load Model : ' + FLoadFile + sLineBreak +
        'Exception class name : ' + E.ClassName + sLineBreak +
        'Exception message : ' + E.Message);
  end;
end;

// Gorilla3D builds the new model, hidden, beside the one shown; this is the
// one step that blocks. Its animations' figures come from the bounds cache
// if it has been seen before, unchanged; otherwise they are measured next.
procedure TMainForm.BuildLoadModel;
begin
  FLoadModel := TGorillaModel.Create(GorillaViewport);
  FLoadModel.Visible := False;
  FLoadModel.Parent := GorillaViewport;
  FLoadAnims := LoadModelFile(FLoadModel, FLoadFile, FLoadBox);
  // The model's own bounds, before any helper is added: the grid's floor
  PlaceModel(FLoadModel, FLoadBox);
  if (Length(FLoadAnims) = 0) or
    LoadAnimationBoundsCache(FLoadFile, FLoadAnims, FLoadBounds) then
  begin
    FLoadDialog.SetProgress(LOAD_MEASURE_END, 'Setting up the view...');
    FLoadStage := lsCommit;
  end
  else
  begin
    // Gorilla only poses a model it can draw: a hidden one keeps its first
    // pose whatever frame it is set to, so every animation would measure as
    // the rest pose. So the new model is shown, and the old one hidden,
    // while it is measured; an abort puts the old one back. The new model
    // has no helpers yet, so nothing else counts in its bounds.
    ShowLoadModel(True);
    FMeasurer := TAnimationBoundsMeasurer.Create(FLoadModel);
    FLoadDialog.SetProgress(LOAD_BUILD_END,
      Format('Measuring %d animations...', [Length(FLoadAnims)]));
    FLoadStage := lsMeasure;
  end;
end;

// Shows the model being loaded and hides the one on screen, with the
// wireframes beside it (its grid and axes are its children, so go with it),
// or with AShowNew False the other way round
procedure TMainForm.ShowLoadModel(const AShowNew: Boolean);
var
  Sweep: TModelSweep;
  Combined: TCombinedSweep;
begin
  if FLoadModel <> nil then
    FLoadModel.Visible := AShowNew;
  if GorillaModel = nil then
    Exit;
  GorillaModel.Visible := not AShowNew;
  Sweep := FindModelSweep(GorillaModel);
  if Sweep <> nil then
    Sweep.Visible := not AShowNew;
  Combined := FindCombinedSweep(GorillaModel);
  if Combined <> nil then
    Combined.Visible := not AShowNew;
end;

// A slice of measuring the new model's animations; when they are all done,
// the figures go to the bounds cache for next time
procedure TMainForm.MeasureLoadModel;
begin
  if FMeasurer.Step(MEASURE_BUDGET_MS) then
  begin
    FLoadBounds := FMeasurer.Results;
    FreeAndNil(FMeasurer);
    SaveAnimationBoundsCache(FLoadFile, FLoadAnims, FLoadBounds);
    FLoadDialog.SetProgress(LOAD_MEASURE_END, 'Setting up the view...');
    FLoadStage := lsCommit;
  end
  else
    FLoadDialog.SetProgress(LOAD_BUILD_END +
      (LOAD_MEASURE_END - LOAD_BUILD_END) * FMeasurer.Progress,
      Format('Measuring %d animations: %d%%',
        [Length(FLoadAnims), Trunc(FMeasurer.Progress * 100)]));
end;

// The new model replaces the old, which is freed with its helpers, and gets
// the list, helpers and fit the View menu asks for
procedure TMainForm.CommitLoad;
var
  Old: TGorillaModel;
begin
  FreeAndNil(FPlayer);   // its animation goes with the old model
  AnimationListBox.Items.Clear;
  AnimationListBox.Items.Add(NO_ANIMATION);
  Old := GorillaModel;
  GorillaModel := FLoadModel;
  FLoadModel := nil;
  if Old <> nil then
  begin
    Old.Parent := nil;
    Old.Free;
  end;
  GorillaModel.Visible := True;
  // Measuring stepped the animations through their poses and left the
  // model however the last of them did; put it in its bind pose, exactly as
  // choosing (None) does, so it shows, and its bounding box measures, the
  // same either way
  GorillaModel.ResetToBindPose();

  FModelBox := FLoadBox;
  FModelFile := FLoadFile;
  FAnimationBounds := FLoadBounds;
  FAnimationBoundsMeasured := True;
  // Every animation is used until Model, Animations Used says otherwise
  FAnimationNames := FLoadAnims;
  FUsedAnimations := Copy(FLoadAnims);
  // Frame counts typed in were for the old model's animations
  FFrameOverrides.Clear;
  RebuildAnimationList;

  // The angles as the dials have them, unless the camera is locked
  ApplyAngles;

  // Draw the model's box, if wanted: the bounds of the current pose, in
  // Gorilla's default orange
  GorillaModel.ShowBoundingBox := ShowBoundsItem.IsChecked;
  // Gorilla draws that box on screen only; this draws it into grabs too
  ShowModelBoundsOutline(GorillaModel);
  // Axes through the centre of rotation, sized for the newly loaded model
  if ShowAxesItem.IsChecked then
    ShowModelAxes(GorillaModel);

  // Floor grid, after the model is placed and turned, because the floor
  // depends on which way up it is
  if ShowGridItem.IsChecked then
    ShowModelGrid(GorillaModel, FModelBox);

  // The volume swept turning about the up axis, for the new bounds
  if ShowSweepItem.IsChecked then
    ApplyShowSweep;
  if ShowCombinedSweepItem.IsChecked then
    ApplyShowCombinedSweep;

  // For the "Load last model" start-up action; saved with the view state
  FSettings.LastModel := FLoadFile;
  DebugMemo.Lines.Add('Loaded ' + FLoadFile);

  EndLoad(String.Empty);

  // A locked camera stays where it is, whatever the new model's size
  if not CameraLocked and not FitModel then
    Caption := 'Problem fitting Camera';

  // A project's Animations list, for this model, once the load has ended
  if FHasPendingList and SameFileName(ExpandFileName(FModelFile), FPendingListModel) then
    TThread.ForceQueue(nil, ApplyPendingList)
  else
    FHasPendingList := False;
end;

// The Animations list of the project that asked for the model just loaded
procedure TMainForm.ApplyPendingList;
begin
  if MainFormGone or not FHasPendingList then
    Exit;
  FHasPendingList := False;
  ApplyAnimationList(FPendingList, ExtractFileName(FProjectFile));
end;

// Ends the load, whether it worked, failed with AError or was aborted:
// anything of the new model not yet taken on is freed, the dialog is
// closed, and on Android and iOS the outcome is reported at once; on the
// desktop SwitchModel reports it once ShowModal has returned
procedure TMainForm.EndLoad(const AError: String);
var
  Dialog: TModelLoadForm;
begin
  FLoadTimer.Enabled := False;
  FLoadStage := lsNone;
  FreeAndNil(FMeasurer);
  if FLoadRead <> nil then
    FLoadRead.Cancel;
  FLoadRead := nil;
  if FLoadModel <> nil then
  begin
    // Not taken on: the old model, if any, is shown again as it was
    ShowLoadModel(False);
    FLoadModel.Parent := nil;
    FreeAndNil(FLoadModel);
  end;
  FLoadAnims := nil;
  FLoadBounds := nil;
  FLoadError := AError;
  // A project's Animations list waits for its model only while it loads
  if AError <> String.Empty then
    FHasPendingList := False;
  Caption := ProjectionCaption;
  UpdateNoModelPanel;
  Dialog := FLoadDialog;
  FLoadDialog := nil;
  if Dialog <> nil then
    Dialog.Finish;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  ReportLoadEnd;
  {$ENDIF}
end;

// After the dialog has gone: what went wrong, if anything, and any model
// asked for meanwhile, loaded next
procedure TMainForm.ReportLoadEnd;
var
  Pending: String;
begin
  if FLoadError <> String.Empty then
  begin
    DebugMemo.Lines.Add(FLoadError);
    ShowMessage(FLoadError);
    FLoadError := String.Empty;
  end;
  Pending := FPendingModel;
  FPendingModel := String.Empty;
  if Pending <> String.Empty then
    TThread.ForceQueue(nil,
      procedure
      begin
        if not MainFormGone then
          SwitchModel(Pending);
      end);
end;

// The panel that covers the view while no model is loaded, as at start-up
// with the start-up action None, or after the first load is aborted. It
// takes the theme's panel colours, and lets clicks through.
procedure TMainForm.BuildNoModelPanel;
var
  Content: TLayout;
  Title, Hint: TLabel;
begin
  FNoModelPanel := TPanel.Create(Self);
  FNoModelPanel.Parent := ViewportLayout;
  FNoModelPanel.Align := TAlignLayout.Contents;
  FNoModelPanel.HitTest := False;

  Content := TLayout.Create(Self);
  Content.Parent := FNoModelPanel;
  Content.Align := TAlignLayout.Center;
  Content.Width := 360;
  Content.Height := 80;
  Content.HitTest := False;

  Title := TLabel.Create(Self);
  Title.Parent := Content;
  Title.Align := TAlignLayout.Top;
  Title.Height := 34;
  Title.StyledSettings := Title.StyledSettings -
    [TStyledSetting.Size, TStyledSetting.Style];
  Title.TextSettings.Font.Size := 20;
  Title.TextSettings.Font.Style := [TFontStyle.fsBold];
  Title.TextSettings.HorzAlign := TTextAlign.Center;
  Title.Text := 'No model loaded';
  Title.HitTest := False;

  Hint := TLabel.Create(Self);
  Hint.Parent := Content;
  Hint.Align := TAlignLayout.Client;
  Hint.TextSettings.HorzAlign := TTextAlign.Center;
  Hint.TextSettings.VertAlign := TTextAlign.Leading;
  Hint.TextSettings.WordWrap := True;
  Hint.Text := 'Choose File, Open Model to load one.';
  Hint.HitTest := False;

  UpdateNoModelPanel;
end;

// Shows the no-model panel only while there is no model
procedure TMainForm.UpdateNoModelPanel;
begin
  if FNoModelPanel = nil then
    Exit;
  FNoModelPanel.Visible := GorillaModel = nil;
  if FNoModelPanel.Visible then
    FNoModelPanel.BringToFront;
  if FFpsBack <> nil then
    FFpsBack.BringToFront;   // the frame rate stays readable over the panel
end;

// Reads openh264.json and what has been downloaded, without the network,
// and tells Sprite3DOpenH264 which copy to load, if any
procedure TMainForm.PrepareOpenH264;
begin
  FOpenH264Update := TSprite3DLibraryUpdate.Create(OpenH264ConfigFile, 'OpenH264',
    OpenH264Folder);
  SetPreferredOpenH264(FOpenH264Update.CurrentLibrary);
  DebugMemo.Lines.Add(FOpenH264Update.Message);
end;

// Downloads OpenH264 if openh264.json gives an address this copy does not
// come from. Only worth doing when FFmpeg can write MP4 files. When the new
// copy arrives it is loaded straight away, so H.264 is offered without a
// restart; a failure, 404s included, leaves MP4 files as MPEG-4 Part 2.
procedure TMainForm.StartOpenH264Update;
begin
  if not VideoAvailable then
    Exit;
  FOpenH264Update.Start(
    procedure(const ALibrary, AMessage: String)
    begin
      DebugMemo.Lines.Add(AMessage);
      if ALibrary = String.Empty then
        Exit;
      if OpenH264LoadedLibrary <> String.Empty then
      begin
        DebugMemo.Lines.Add('The new OpenH264 is used from the next start');
        Exit;
      end;
      SetPreferredOpenH264(ALibrary);
      RecheckH264;
      DebugMemo.Lines.Add(OpenH264Status);
    end);
end;

// The animation list's pop-up menu, made here rather than in the form
// designer. On Android and iOS, which have no right-click, the same items
// are also put in an Animation menu, which BuildMobileMenu shows as a group
// of the drawer; they act on the selected entry.
procedure TMainForm.BuildAnimationMenu;

  function AddItem(const AParent: TFmxObject; const AText: String;
    const AOnClick: TNotifyEvent): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Text := AText;
    Result.OnClick := AOnClick;
    AParent.AddObject(Result);
  end;

begin
  FAnimationPopup := TPopupMenu.Create(Self);
  FAnimationPopup.Parent := Self;
  // Clicks on an entry usually reach the list, not the entry; see
  // HookAnimationItems
  AnimationListBox.OnMouseUp := AnimationItemMouseUp;
  AddItem(FAnimationPopup, 'Save as sprite strip', SaveStripItemClick);
  AddItem(FAnimationPopup, 'Save as Spritesheet', SaveSheetItemClick);
  AddItem(FAnimationPopup, 'Save as AniGif', SaveGifItemClick);
  // MP4 needs the FFmpeg libraries: offered once StartVideo finds they load
  FMp4Item := AddItem(FAnimationPopup, 'Save as MP4 video', SaveMp4ItemClick);
  FMp4Item.Enabled := False;
  BuildBatchControls;
  BuildTransportControls;

  // Model, Animation Settings..., just above Background Settings...
  FAnimationSettingsItem := TMenuItem.Create(Self);
  FAnimationSettingsItem.Text := 'Animation Settings...';
  FAnimationSettingsItem.OnClick := AnimationSettingsItemClick;
  ModelMenu.InsertObject(BackgroundSettingsMenuItem.Index, FAnimationSettingsItem);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  FAnimationMenu := TMenuItem.Create(Self);
  FAnimationMenu.Text := 'Animation';
  MainMenu1.AddObject(FAnimationMenu);
  AddItem(FAnimationMenu, 'Save as sprite strip', SaveStripItemClick);
  AddItem(FAnimationMenu, 'Save as Spritesheet', SaveSheetItemClick);
  AddItem(FAnimationMenu, 'Save as AniGif', SaveGifItemClick);
  // MP4 is added by StartVideo if the video libraries load
  {$ENDIF}
end;

// Model, Animation Settings...: the frame rate saved animations use. OK keeps the
// new rate and saves it; Cancel leaves the old one.
procedure TMainForm.AnimationSettingsItemClick(Sender: TObject);
var
  Dialog: TAnimationSettingsForm;
begin
  Dialog := TAnimationSettingsForm.Create(nil);
  Dialog.Fps := FSettings.AnimationFps;
  // Overscan: as far as the GPU can go at the grab size, the factor and
  // filter last chosen, and ticked only if it was ticked this session
  Dialog.MaxOverscan := FOffscreen.MaxOverscan(FSettings.GrabWidth, FSettings.GrabHeight);
  Dialog.Overscan := FSettings.Overscan;
  Dialog.Filter := FSettings.ResampleFilter;
  Dialog.OverscanEnabled := FOverscanOn;
  Dialog.AtlasPageSize := FSettings.AtlasPageSize;
  Dialog.AtlasNonPowerOf2 := FSettings.AtlasNonPowerOf2;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog reports OK and frees itself
  Dialog.OnAccept := AnimationDialogAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    if Dialog.ShowModal = mrOk then
    begin
      ApplyAnimationFps(Dialog.Fps);
      ApplyOverscan(Dialog.OverscanEnabled, Dialog.Overscan, Dialog.Filter);
      ApplyAtlasSettings(Dialog.AtlasPageSize, Dialog.AtlasNonPowerOf2);
    end;
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.AnimationDialogAccept(Sender: TObject);
var
  Dialog: TAnimationSettingsForm;
begin
  Dialog := TAnimationSettingsForm(Sender);
  ApplyAnimationFps(Dialog.Fps);
  ApplyOverscan(Dialog.OverscanEnabled, Dialog.Overscan, Dialog.Filter);
  ApplyAtlasSettings(Dialog.AtlasPageSize, Dialog.AtlasNonPowerOf2);
end;
{$ENDIF}

// An overscanned target was too large for this GPU to draw: the grab is
// being made again smaller, and this size is not tried again this session
procedure TMainForm.OffscreenOverscanReduced(Sender: TObject; const AFailedSize,
  AMaxOverscan: Integer);
begin
  DebugMemo.Lines.Add(Format('Overscan: a %d-pixel target could not be drawn here; ' +
    'grabs of %d x %d are now drawn at most %dx in one go, the rest made up with ' +
    'shifted drawings', [AFailedSize, FOffscreen.Width, FOffscreen.Height, AMaxOverscan]));
end;

// One of an overscanned grab's shifted drawings: slide the view by a
// fraction of a pixel of the grab, from where it was, or, for 0 and 0, put
// it back. Each slide starts from the same place, so none adds to another.
procedure TMainForm.OffscreenShiftView(Sender: TObject; const ARight, AUp: Single);
begin
  if not Assigned(GorillaCamera) then
    Exit;
  if FViewShifted then
    GorillaCamera.OrbitCenter.Point := FShiftedCentre
  else
    FShiftedCentre := GorillaCamera.OrbitCenter.Point;
  FViewShifted := (ARight <> 0) or (AUp <> 0);
  if FViewShifted then
    GorillaCamera.ShiftView(ARight, AUp, FOffscreen.Width, FOffscreen.Height);
end;

// Overscan for every grab and export from now on: on or off for this
// session only, and the factor and filter kept in settings.json. A grab
// uses less than AFactor if the GPU cannot draw that much at its size.
procedure TMainForm.ApplyOverscan(const AOn: Boolean; const AFactor: Integer;
  const AFilter: TSprite3DResampleFilter);
var
  Changed: Boolean;
begin
  Changed := (FSettings.Overscan <> AFactor) or (FSettings.ResampleFilter <> AFilter);
  FOverscanOn := AOn;
  FSettings.Overscan := AFactor;   // limited to the allowed range
  FSettings.ResampleFilter := AFilter;
  FOffscreen.Resample := AFilter;
  if AOn then
  begin
    FOffscreen.Overscan := FSettings.Overscan;
    DebugMemo.Lines.Add(Format('Overscan on: %dx, scaled down with %s',
      [FSettings.Overscan, ResampleFilterName(AFilter)]));
  end
  else
  begin
    FOffscreen.Overscan := 1;
    DebugMemo.Lines.Add('Overscan off');
  end;
  if Changed then
    try
      FSettings.Save;
    except
      on E: Exception do
        ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
          E.Message);
    end;
end;

// Keeps the frame rate and writes settings.json straight away
procedure TMainForm.ApplyAnimationFps(const AFps: Integer);
begin
  if AFps = FSettings.AnimationFps then
    Exit;
  FSettings.AnimationFps := AFps;   // limited to the allowed range
  UpdateFrameCounts;
  // The frames stepped through are the export frames, so they follow too
  if FPlayer <> nil then
    FPlayer.FrameRate := FSettings.AnimationFps;
  UpdateTransportControls;
  DebugMemo.Lines.Add(Format('Animations are now saved at %d frames per second',
    [FSettings.AnimationFps]));
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

// View, Camera, Lock Camera, below the views and a line. It is not one of
// the views: IsCameraViewItem leaves it out, so choosing a view never clears
// its tick and settings.json never keeps it as the view.
procedure TMainForm.BuildLockCameraItem;
begin
  FLockSeparatorItem := TMenuItem.Create(Self);
  FLockSeparatorItem.Text := '-';
  CameraMenu.AddObject(FLockSeparatorItem);
  FLockCameraItem := TMenuItem.Create(Self);
  FLockCameraItem.Text := 'Lock Camera';
  FLockCameraItem.IsChecked := False;
  FLockCameraItem.OnClick := LockCameraItemClick;
  CameraMenu.AddObject(FLockCameraItem);
end;

// True while View, Camera, Lock Camera is ticked
function TMainForm.CameraLocked: Boolean;
begin
  Result := Assigned(FLockCameraItem) and FLockCameraItem.IsChecked;
end;

// One of the View, Camera views, rather than Lock Camera or a line
function TMainForm.IsCameraViewItem(const AItem: TMenuItem): Boolean;
begin
  Result := (AItem <> FLockCameraItem) and (AItem <> FLockSeparatorItem) and
    (AItem.Text <> '-');
end;

// Ticks or unticks Lock Camera. The camera keeps exactly what it has; on
// unlocking nothing is refitted, so the view stays put until something
// changes it. Not while a grab or capture has its own framing on the camera,
// which it must be free to put back.
procedure TMainForm.LockCameraItemClick(Sender: TObject);
begin
  if Capturing or FOffscreen.Busy then
    Exit;
  FLockCameraItem.IsChecked := not FLockCameraItem.IsChecked;
  UpdateCameraLockControls;
  Caption := ProjectionCaption;
  if CameraLocked then
    DebugMemo.Lines.Add('Camera locked')
  else
    DebugMemo.Lines.Add('Camera unlocked');
end;

// Everything that would move the camera is switched off while it is
// locked, and the camera itself refuses changes as well, so nothing slips
// through
procedure TMainForm.UpdateCameraLockControls;
var
  I: Integer;
  Locked: Boolean;
begin
  if FLockCameraItem = nil then
    Exit;
  Locked := CameraLocked;
  if Assigned(GorillaCamera) then
    GorillaCamera.Locked := Locked;
  for I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) then
      CameraMenu.Items[I].Enabled := not Locked;
  OrthographicItem.Enabled := not Locked;
  FLockCameraItem.Enabled := not Capturing;
end;

// The list's entries are hooked as well as the list itself: depending on
// the style, a click on an entry reaches either the entry or the list, and
// FMX does not pass mouse events on to a parent, so only one of the two
// handlers runs for any click
procedure TMainForm.HookAnimationItems;
var
  I: Integer;
begin
  for I := 0 to AnimationListBox.Count - 1 do
  begin
    AnimationListBox.ListItems[I].OnMouseUp := AnimationItemMouseUp;
    AnimationListBox.ListItems[I].OnMouseDown := AnimationItemMouseDown;
    AnimationListBox.ListItems[I].OnDblClick := AnimationItemDblClick;
  end;
end;

// Fills AnimationListBox with (None) and the animations used, in the
// model's order, with their frame counts and no batch ticks. The selected
// entry stays selected if it is still listed, without being played again.
// If the animation playing is no longer listed, the model is shown at rest,
// as choosing (None) would.
procedure TMainForm.RebuildAnimationList;
var
  Previous, Name: String;
  WasNone: Boolean;
  Current: TGorillaAnimation;
begin
  // An open frame count editor goes with the entries it sits on, and so
  // does one closed but not yet freed
  FinishFrameEdit(False, True);
  FreeAndNil(FSpentEditor);
  WasNone := AnimationListBox.ItemIndex = 0;
  if AnimationListBox.ItemIndex > 0 then
    Previous := AnimationListBox.Items[AnimationListBox.ItemIndex]
  else
    Previous := String.Empty;

  FRebuildingList := True;
  try
    AnimationListBox.BeginUpdate;
    try
      AnimationListBox.Items.Clear;
      AnimationListBox.Items.Add(NO_ANIMATION);
      for Name in FAnimationNames do
        if IsUsedAnimation(Name) then
          AnimationListBox.Items.Add(Name);
    finally
      AnimationListBox.EndUpdate;
    end;
    HookAnimationItems;
    // A new list starts with nothing ticked
    if Assigned(FBatchAll) then
    begin
      FSyncingChecks := True;
      try
        FBatchAll.IsChecked := False;
      finally
        FSyncingChecks := False;
      end;
    end;
    if Previous <> String.Empty then
      AnimationListBox.ItemIndex := AnimationListBox.Items.IndexOf(Previous)
    else if WasNone then
      AnimationListBox.ItemIndex := 0;
  finally
    FRebuildingList := False;
  end;
  UpdateFrameCounts;
  UpdateTransportControls;
  UpdateListFileItems;

  if Assigned(GorillaModel) and Assigned(GorillaModel.AnimationManager) then
  begin
    Current := GorillaModel.AnimationManager.Current;
    if Assigned(Current) and Current.IsRunning and not IsUsedAnimation(Current.Id) then
    begin
      FRebuildingList := True;
      try
        AnimationListBox.ItemIndex := 0;
      finally
        FRebuildingList := False;
      end;
      FChangePlayed := False;
      PlaySelectedAnimation;   // (None): stops it
    end;
  end;
end;

function TMainForm.IsUsedAnimation(const AName: String): Boolean;
var
  Name: String;
begin
  for Name in FUsedAnimations do
    if Name = AName then
      Exit(True);
  Result := False;
end;

// The frames saving entry AIndex makes at the Model, Animation Settings
// rate, worked out as a capture does: 1 for (None), a still of the bind
// pose, otherwise the animation's length times the rate, rounded. 0 if the
// animation cannot be found.
function TMainForm.AnimationFrameCount(const AIndex: Integer): Integer;
var
  Anim: TGorillaAnimation;
  Source: TSprite3DAnimationFrames;
begin
  Result := 0;
  if AIndex = 0 then
    Exit(1);
  if (GorillaModel = nil) or (GorillaModel.AnimationManager = nil) then
    Exit;
  Anim := GorillaModel.AnimationManager.GetAnimation(AnimationListBox.Items[AIndex]);
  if Anim = nil then
    Exit;
  Source := TSprite3DAnimationFrames.Create(GorillaModel, Anim, FSettings.AnimationFps,
    FrameOverride(Anim.Id));
  try
    Result := Source.FrameCount;
  finally
    Source.Free;
  end;
end;

// The label at the right of a list entry that shows its frame count, made
// the first time it is wanted. It ignores the mouse, so clicks still reach
// the entry.
function TMainForm.FrameCountLabel(const AItem: TListBoxItem): TLabel;
var
  I: Integer;
begin
  for I := 0 to AItem.ChildrenCount - 1 do
    if (AItem.Children[I] is TLabel) and (TLabel(AItem.Children[I]).Tag = FRAME_LABEL_TAG) then
      Exit(TLabel(AItem.Children[I]));
  Result := TLabel.Create(AItem);
  Result.Stored := False;
  Result.Tag := FRAME_LABEL_TAG;
  Result.Parent := AItem;
  Result.Align := TAlignLayout.Right;
  Result.Width := 50;
  Result.Margins.Right := 6;   // with the list's border, level with FramesLabel
  Result.HitTest := False;
  Result.TextSettings.HorzAlign := TTextAlign.Trailing;
end;

// Every entry's frame count, for the Model, Animation Settings rate now
procedure TMainForm.UpdateFrameCounts;
var
  I, Count: Integer;
  Lbl: TLabel;
begin
  for I := 0 to AnimationListBox.Count - 1 do
  begin
    Count := AnimationFrameCount(I);
    Lbl := FrameCountLabel(AnimationListBox.ListItems[I]);
    if Count > 0 then
      Lbl.Text := IntToStr(Count)
    else
      Lbl.Text := String.Empty;
    // A count typed in, in place of the entry's own, in italics
    Lbl.StyledSettings := Lbl.StyledSettings - [TStyledSetting.Style];
    if (I > 0) and (FrameOverride(AnimationListBox.Items[I]) > 0) then
      Lbl.TextSettings.Font.Style := [TFontStyle.fsItalic]
    else
      Lbl.TextSettings.Font.Style := [];
  end;
end;

// A frame count typed in for an animation, or 0 for its own
function TMainForm.FrameOverride(const AName: String): Integer;
begin
  if (FFrameOverrides = nil) or not FFrameOverrides.TryGetValue(AName, Result) then
    Result := 0;
end;

// Sets, or with 0 clears, the frame count typed in for an animation; the
// counts shown, and the animation playing if it is that one, follow
procedure TMainForm.SetFrameOverride(const AName: String; const ACount: Integer);
begin
  if ACount = FrameOverride(AName) then
    Exit;
  if ACount > 0 then
    FFrameOverrides.AddOrSetValue(AName, ACount)
  else
    FFrameOverrides.Remove(AName);
  UpdateFrameCounts;
  if (FPlayer <> nil) and (FPlayer.Animation.Id = AName) then
  begin
    // The frames stepped through are the export frames: start it again
    // with the new count, held if it was held
    FChangePlayed := False;
    PlaySelectedAnimation;
  end;
  UpdateTransportControls;
  if ACount > 0 then
    DebugMemo.Lines.Add(Format('%s: exported in %d frames', [AName, ACount]))
  else
    DebugMemo.Lines.Add(Format('%s: frame count as the frame rate gives', [AName]));
end;

// Where on its entry the mouse went down, for a double-click to tell the
// frame count from the name
procedure TMainForm.AnimationItemMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FItemDownX := X;
end;

// A double-click on an entry's frame count opens it for editing; one on the
// name does nothing more than its clicks did
procedure TMainForm.AnimationItemDblClick(Sender: TObject);
var
  Item: TListBoxItem;
  Lbl: TLabel;
begin
  if not (Sender is TListBoxItem) then
    Exit;
  Item := TListBoxItem(Sender);
  Lbl := FrameCountLabel(Item);
  if FItemDownX < Lbl.Position.X - Lbl.Margins.Left then
    Exit;
  for var I := 1 to AnimationListBox.Count - 1 do
    if AnimationListBox.ListItems[I] = Item then
    begin
      StartFrameEdit(I);
      Break;
    end;
end;

// An edit box over entry AEntry's frame count: Enter, or leaving it, keeps
// what was typed, Escape does not; empty or 0 goes back to the count the
// frame rate gives. (None), entry 0, is always one frame.
procedure TMainForm.StartFrameEdit(const AEntry: Integer);
var
  Item: TListBoxItem;
  Lbl: TLabel;
begin
  if Capturing or (AEntry < 1) or (AEntry >= AnimationListBox.Count) then
    Exit;
  FinishFrameEdit(False, False);
  Item := AnimationListBox.ListItems[AEntry];
  Lbl := FrameCountLabel(Item);
  FFrameEditName := AnimationListBox.Items[AEntry];
  FFrameEditor := TEdit.Create(nil);
  FFrameEditor.Stored := False;
  FFrameEditor.Parent := Item;
  FFrameEditor.Align := TAlignLayout.Right;
  FFrameEditor.Width := Lbl.Width;
  FFrameEditor.Margins.Rect := Lbl.Margins.Rect;
  FFrameEditor.FilterChar := '0123456789';
  FFrameEditor.MaxLength := 4;
  FFrameEditor.TextSettings.HorzAlign := TTextAlign.Trailing;
  FFrameEditor.Text := Lbl.Text;
  FFrameEditor.Hint := 'Frames to export this animation in; empty or 0 for the count ' +
    'the frame rate gives';
  FFrameEditor.ShowHint := True;
  FFrameEditor.OnKeyDown := FrameEditorKeyDown;
  FFrameEditor.OnExit := FrameEditorExit;
  Lbl.Visible := False;
  FFrameEditor.SetFocus;
  FFrameEditor.SelectAll;
end;

// Closes the frame count editor, keeping what was typed if ACommit. It is
// freed at once if AFreeNow, as when the entries are about to go; otherwise
// from a fresh main-loop turn, as this may be running in its own event.
procedure TMainForm.FinishFrameEdit(const ACommit, AFreeNow: Boolean);
var
  Editor: TEdit;
  Text: String;
begin
  Editor := FFrameEditor;
  if Editor = nil then
    Exit;
  FFrameEditor := nil;
  Editor.OnExit := nil;
  Editor.OnKeyDown := nil;
  Text := Editor.Text.Trim;
  if Editor.Parent is TListBoxItem then
    FrameCountLabel(TListBoxItem(Editor.Parent)).Visible := True;
  if AFreeNow then
    Editor.Free
  else
  begin
    Editor.Visible := False;
    FreeAndNil(FSpentEditor);   // one left from before, not in any event now
    FSpentEditor := Editor;
    TThread.ForceQueue(nil, FreeSpentEditor);
  end;
  if ACommit then
    SetFrameOverride(FFrameEditName, EnsureRange(StrToIntDef(Text, 0), 0, 9999));
end;

procedure TMainForm.FreeSpentEditor;
begin
  if not MainFormGone then
    FreeAndNil(FSpentEditor);
end;

procedure TMainForm.FrameEditorKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    FinishFrameEdit(True, False);
  end
  else if Key = vkEscape then
  begin
    Key := 0;
    FinishFrameEdit(False, False);
  end;
end;

procedure TMainForm.FrameEditorExit(Sender: TObject);
begin
  FinishFrameEdit(True, False);
end;

// Model, Directions...: how many directions, where the first points, the
// order they are taken in, and whether the dial snaps. OK keeps and saves
// them; Cancel leaves everything as it was.
procedure TMainForm.DirectionsItemClick(Sender: TObject);
var
  Dialog: TDirectionsForm;
  Order: TArray<Integer>;
begin
  Dialog := TDirectionsForm.Create(nil);
  Dialog.Snap := FSettings.DirectionSnap;
  Dialog.Count := FSettings.DirectionCount;
  Dialog.Start := FSettings.DirectionStart;
  Order := FSettings.DirectionOrderList;
  if not IsDirectionOrder(Order, Dialog.Count) then
    Order := PlainDirectionOrder(Dialog.Count, FSettings.DirectionClockwise);
  Dialog.Order := Order;
  Dialog.Folder := FSettings.DirectionsFolder;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog reports OK and frees itself
  Dialog.OnAccept := DirectionsAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    if Dialog.ShowModal = mrOk then
    begin
      FSettings.DirectionsFolder := Dialog.Folder;
      ApplyDirections(Dialog.Count, Dialog.Start, Dialog.Order, Dialog.Snap);
    end
    else
      // Kept with the other settings when they are next saved
      FSettings.DirectionsFolder := Dialog.Folder;
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.DirectionsAccept(Sender: TObject);
var
  Dialog: TDirectionsForm;
begin
  Dialog := Sender as TDirectionsForm;
  ApplyDirections(Dialog.Count, Dialog.Start, Dialog.Order, Dialog.Snap);
end;
{$ENDIF}

// Keeps the directions chosen in Model, Directions, and saves them. A plain
// order is kept as DirectionClockwise alone, with DirectionOrder empty
procedure TMainForm.ApplyDirections(const ACount: Integer; const AStart: Single;
  const AOrder: TArray<Integer>; const ASnap: Boolean);
var
  Clockwise, Anticlockwise: TArray<Integer>;
  Plain: Boolean;
begin
  FSettings.DirectionCount := ACount;   // limited to DIRECTION_COUNTS
  FSettings.DirectionStart := AStart;
  FSettings.DirectionSnap := ASnap;
  Clockwise := PlainDirectionOrder(FSettings.DirectionCount, True);
  Anticlockwise := PlainDirectionOrder(FSettings.DirectionCount, False);
  Plain := not IsDirectionOrder(AOrder, FSettings.DirectionCount) or
    (DirectionOrderToText(AOrder) = DirectionOrderToText(Clockwise)) or
    (DirectionOrderToText(AOrder) = DirectionOrderToText(Anticlockwise));
  if Plain then
  begin
    FSettings.DirectionClockwise := (FSettings.DirectionCount <= 2) or
      not IsDirectionOrder(AOrder, FSettings.DirectionCount) or
      (DirectionOrderToText(AOrder) <> DirectionOrderToText(Anticlockwise));
    FSettings.DirectionOrder := String.Empty;
  end
  else
  begin
    FSettings.DirectionClockwise := True;
    FSettings.DirectionOrder := DirectionOrderToText(AOrder);
  end;
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

procedure TMainForm.AnimationsUsedItemClick(Sender: TObject);
var
  Dialog: TAnimationsUsedForm;
  Volumes: TArray<TSweptVolume>;
  I: Integer;
begin
  if GorillaModel = nil then
    Exit;
  if Capturing then
  begin
    ShowMessage('An animation is being saved; choose the animations used when it is done.');
    Exit;
  end;
  // Each animation's own swept volume, and the rest pose's, for the
  // dialog's percentage column
  SetLength(Volumes, Length(FAnimationNames));
  for I := 0 to High(FAnimationNames) do
    Volumes[I] := AnimationSweptVolume(FAnimationNames[I]);
  Dialog := TAnimationsUsedForm.Create(nil);
  Dialog.SetAnimations(FAnimationNames, FUsedAnimations, Volumes,
    CalcSweptVolume(FModelBox, GorillaModel.RotationCenter.Point, saY));
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog reports OK and frees itself
  Dialog.OnAccept := AnimationsUsedAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    if Dialog.ShowModal = mrOk then
      ApplyUsedAnimations(Dialog.UsedAnimations);
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.AnimationsUsedAccept(Sender: TObject);
begin
  ApplyUsedAnimations(TAnimationsUsedForm(Sender).UsedAnimations);
end;
{$ENDIF}

// Lists only the animations used, then refits to the swept volume joined
// over them and the rest pose
procedure TMainForm.ApplyUsedAnimations(const AUsed: TArray<String>);
begin
  if Capturing then
    Exit;   // the dialog does not block on Android and iOS
  FUsedAnimations := AUsed;
  RebuildAnimationList;
  DebugMemo.Lines.Add(Format('Animations used: %d of %d',
    [Length(FUsedAnimations), Length(FAnimationNames)]));
  FitModel;
  // The combined volume is joined over the animations used, so it changes too
  ApplyShowCombinedSweep;
end;

// A right-click selects and plays the entry under the mouse, as a left
// click would, then opens the pop-up menu there. Sender is either the list,
// whose coordinates find the entry, or an entry itself. On macOS a
// Control-click counts as a right-click.
procedure TMainForm.AnimationItemMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Item: TListBoxItem;
  At: TPointF;
  I: Integer;
  RightClick: Boolean;
begin
  RightClick := Button = TMouseButton.mbRight;
  {$IFDEF MACOS}
  RightClick := RightClick or ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift));
  {$ENDIF}
  if not RightClick or not (Sender is TControl) then
    Exit;
  if Capturing then
    Exit;   // one capture at a time

  if Sender is TListBoxItem then
    Item := TListBoxItem(Sender)
  else
    Item := AnimationListBox.ItemByPoint(X, Y);
  if Item = nil then
    Exit;   // below the last entry

  for I := 0 to AnimationListBox.Count - 1 do
    if (AnimationListBox.ListItems[I] = Item) and (AnimationListBox.ItemIndex <> I) then
    begin
      AnimationListBox.ItemIndex := I;
      AnimationListBoxClick(AnimationListBox);
      Break;
    end;
  At := TControl(Sender).LocalToScreen(TPointF.Create(X, Y));
  FAnimationPopup.Popup(At.X, At.Y);
end;

procedure TMainForm.SaveStripItemClick(Sender: TObject);
begin
  StartSingleCapture(skStrip);
end;

procedure TMainForm.SaveSheetItemClick(Sender: TObject);
begin
  StartSingleCapture(skSheet);
end;

procedure TMainForm.SaveGifItemClick(Sender: TObject);
begin
  StartSingleCapture(skGif);
end;

procedure TMainForm.SaveMp4ItemClick(Sender: TObject);
begin
  StartSingleCapture(skMp4);
end;

// True from the start of a single capture or a batch until it has saved
// everything; between a batch's entries FCapture is briefly nil
function TMainForm.Capturing: Boolean;
begin
  Result := Assigned(FCapture) or FBatchActive;
end;

// The pop-up menu's action: the selected entry, saved in SaveFolder
procedure TMainForm.StartSingleCapture(const AKind: TSheetKind);
var
  Error: String;
begin
  if Capturing or FOffscreen.Busy then
    Exit;   // a capture or a grab is under way
  if GorillaModel = nil then
  begin
    ShowMessage('Open a model first.');
    Exit;
  end;
  if not FSettings.HasSaveFolder and not ChooseSaveFolder then
    Exit;   // no folder, no capture
  if FSettings.ExportDirections then
  begin
    // One capture per direction: run as a batch of this one entry, with
    // its progress dialog
    StartBatch([Max(0, AnimationListBox.ItemIndex)], AKind, SaveFolder);
    Exit;
  end;
  if not StartCapture(AKind, Max(0, AnimationListBox.ItemIndex), -1, SaveFolder,
    procedure(AResult: String)
    begin
      if AResult <> String.Empty then
        ShowMessage(AResult);
    end, Error) then
    ShowMessage(Error);
end;

// What to say in the Debug tab when frames are drawn right up to their edge,
// an empty border of 0 on some side, so the sprite may be cut off: how many
// of AFrames do, and how many on each side; empty if none does. AName is
// the image they are saved in. Frames with nothing drawn are left out. Runs
// on a worker thread.
function EdgeTouchNote(const AName: String; const AFrames: TArray<TSprite3DImage>): String;
var
  Empty: TSprite3DFrameEmpty;
  Touching, Left, Top, Right, Bottom: Integer;
begin
  Result := String.Empty;
  Touching := 0;
  Left := 0;
  Top := 0;
  Right := 0;
  Bottom := 0;
  for var Frame in AFrames do
  begin
    Empty := MeasureFrameEmpty(Frame);
    if Empty.Left >= Frame.Width then
      Continue;   // nothing drawn
    if Empty.Left = 0 then
      Inc(Left);
    if Empty.Top = 0 then
      Inc(Top);
    if Empty.Right = 0 then
      Inc(Right);
    if Empty.Bottom = 0 then
      Inc(Bottom);
    if (Empty.Left = 0) or (Empty.Top = 0) or (Empty.Right = 0) or (Empty.Bottom = 0) then
      Inc(Touching);
  end;
  if Touching > 0 then
    Result := Format('%s: %d of %d frames have an empty border of 0 (left %d, top %d, ' +
      'right %d, bottom %d); the sprite may be cut off',
      [AName, Touching, Length(AFrames), Left, Top, Right, Bottom]);
end;

// Grabs every frame of the list entry AIndex, then saves them as AKind in
// AFolder. An animation is stepped through its own frames; (None), entry 0,
// turns the model once instead. The camera is framed once for the whole
// run, so every frame is drawn at the same scale and the frames line up,
// and the on-screen framing is put back when the capture ends.
// AOnFinished is called once the capture has ended, with an empty string if
// the file was saved, or else what went wrong; it is not called when this
// returns False, which it does, with AError set, if the capture could not
// start at all.
function TMainForm.StartCapture(const AKind: TSheetKind; const AIndex, ADirection: Integer;
  const AFolder: String; const AOnFinished: TProc<String>;
  out AError: String): Boolean;
var
  Count: Integer;
  CycleSeconds: Double;
  Anim: TGorillaAnimation;
  Source: TSprite3DFrameSource;
  Capture: TSprite3DFrameCapture;
  Stem, Folder: String;
  Bytes: Int64;
  Kind: TSheetKind;
  OnFinished: TProc<String>;
  Metadata, OriginKnown: Boolean;
  Origin: TPoint;
  AnimationName: String;
  Entry, Direction: Integer;
  HasDirection, LastDirection: Boolean;
  Bearings: TArray<Single>;
  Meta: TSprite3DSheetMeta;
  Measuring: Boolean;
begin
  Result := False;
  AError := String.Empty;
  // A 2-pass export's first pass: the frames are drawn only to be measured
  Measuring := FBatchActive and (FBatchPass = 1);
  if Assigned(FCapture) or FOffscreen.Busy then
  begin
    AError := 'A capture or a grab is already under way.';
    Exit;
  end;
  if GorillaModel = nil then
  begin
    AError := 'Open a model first.';
    Exit;
  end;
  if (AIndex < 0) or (AIndex >= AnimationListBox.Count) then
  begin
    AError := 'There is no such entry in the animation list.';
    Exit;
  end;
  if (AKind = skAtlas) and not FBatchActive then
  begin
    AError := 'A texture atlas is made by batch Export only.';
    Exit;
  end;
  if (AKind = skMp4) and not VideoAvailable then
  begin
    AError := 'MP4 video is not available: ' + VideoStatus;
    Exit;
  end;

  // The capture drives the animation itself, so nothing stays held
  FreeAndNil(FPlayer);
  UpdateTransportControls;


  if AIndex = 0 then
  begin
    // No animation: one still frame of the model in its bind pose, named
    // after the model. A turntable source of one frame shows the view as it
    // is, without turning it.
    Stem := SafeFileStem(TPath.GetFileNameWithoutExtension(FSettings.LastModel));
    Source := TSprite3DTurntableFrames.Create(GorillaCamera, 1, STILL_SECONDS);
  end
  else
  begin
    Anim := nil;
    if Assigned(GorillaModel.AnimationManager) then
      Anim := GorillaModel.AnimationManager.GetAnimation(AnimationListBox.Items[AIndex]);
    if Anim = nil then
    begin
      AError := 'The model has no animation called ' + AnimationListBox.Items[AIndex];
      Exit;
    end;
    Stem := SafeFileStem(AnimationListBox.Items[AIndex]);
    Source := TSprite3DAnimationFrames.Create(GorillaModel, Anim, FSettings.AnimationFps,
      FrameOverride(AnimationListBox.Items[AIndex]));
  end;

  // A direction of Model, Directions: the camera is turned to it before
  // the source starts, so a still's turntable starts from it too
  HasDirection := (ADirection >= 0) and (ADirection < Length(FBatchBearings));
  Direction := Max(0, ADirection);
  LastDirection := not HasDirection or (ADirection = High(FBatchBearings));
  if HasDirection then
  begin
    Bearings := Copy(FBatchBearings);
    // GIFs and videos are one file per direction
    if AKind in [skGif, skMp4] then
      Stem := Stem + Format('_dir%.2d', [ADirection + 1]);
  end
  else
    Bearings := nil;

  Count := Source.FrameCount;
  CycleSeconds := Source.Duration;
  // The frames, and the strip or spritesheet made from them
  Bytes := Int64(Count) * FOffscreen.Width * FOffscreen.Height * 4 * 2;
  // A strip or spritesheet of directions keeps every direction's frames
  if HasDirection and (AKind in [skStrip, skSheet]) then
    Bytes := Bytes * Length(FBatchBearings);
  if Bytes > MAX_CAPTURE_BYTES then
  begin
    Source.Free;
    AError := Format('%s: %d frames of %d x %d pixels need more memory than a ' +
      'capture may use. Choose a smaller grab size in File, Settings.',
      [Stem, Count, FOffscreen.Width, FOffscreen.Height]);
    Exit;
  end;

  // Exports carry no background, whatever the view shows behind the model:
  // strips, spritesheets and GIFs are transparent around it, and MP4s, which
  // cannot be, are laid over black. EndCapture puts the view's back.
  var NoBackdrop := TSprite3DBackgroundSpec.Default;
  NoBackdrop.Kind := TSprite3DBackgroundKind.None;
  FOffscreen.Backdrop := NoBackdrop;

  // One framing for every frame, from here until EndCapture; a locked
  // camera is captured exactly as it stands
  FRefitAfterCapture := False;
  FCaptureFramed := not CameraLocked;
  if FCaptureFramed then
    FCaptureRestore := GorillaCamera.SaveFraming;
  if HasDirection then
    TurnToDirection(FBatchBearings[ADirection]);
  Source.Start;
  if FCaptureFramed and
    not FrameCaptureFraming(Source, FOffscreen.Width, FOffscreen.Height) then
    DebugMemo.Lines.Add('Could not frame the capture; using the view as it is');
  // A 2-pass export's second pass: the framing reworked from what the first
  // pass measured, so the sprite fills the frame. The fit is the same as the
  // first pass's, so its pixels are the ones measured.
  if FCaptureFramed and FBatchActive and (FBatchPass = 2) and FTwoPassAdjusted then
    ApplyTwoPassAdjust(FOffscreen.Width, FOffscreen.Height);
  // The camera as these frames are drawn, which the metadata records: for a
  // 2-pass export, the second pass's
  FCaptureDistance := GorillaCamera.Distance;
  FCaptureOrthoHeight := GorillaCamera.OrthoHeight;

  // Where the centre of rotation falls in every frame: the framing holds for
  // the whole capture and the model never moves, so once is enough. For a
  // strip or spritesheet the view is slid by under half a pixel so that it
  // falls on the centre of a pixel, and the metadata's origin is that
  // pixel, whole numbers, whether or not the metadata is saved, so the image
  // is the same either way.
  Metadata := FSettings.ExportMetadata and (AKind in [skStrip, skSheet]);
  Origin := TPoint.Zero;
  // A measuring pass saves nothing, so has no origin to place
  OriginKnown := not Measuring and (AKind in [skStrip, skSheet, skAtlas]) and
    SnapCaptureOrigin(FOffscreen.Width, FOffscreen.Height, Origin);
  // The entry's name, as listed: the animation's, or (None) for the still
  AnimationName := AnimationListBox.Items[AIndex];
  // Credits, dates and model for the metadata, as they are now
  Meta := ExportMeta(1, 1);

  // Locals, not parameters, for the procedures below to capture
  Kind := AKind;
  Entry := AIndex;
  Folder := AFolder;
  OnFinished := AOnFinished;
  Capture := TSprite3DFrameCapture.Create(FOffscreen, Source,
    procedure(const AFrames: TArray<TSprite3DImage>; const ACaptureError: String)
    var
      Outcome: String;
      Frames: TArray<TSprite3DImage>;
      Task: ITask;
      DeferMetadata, Borders: Boolean;
    begin
      FCapture := nil;
      EndCapture;
      UpdateBatchControls;
      if ACaptureError <> String.Empty then
      begin
        Outcome := Stem + ': capture failed: ' + ACaptureError;
        DebugMemo.Lines.Add(Outcome);
        if Assigned(OnFinished) then
          OnFinished(Outcome);
        Exit;
      end;
      if Measuring then
      begin
        // The first pass: each frame's empty border is folded into the
        // batch's, and the frames are let go; nothing is built or saved
        MeasureTwoPassFrames(AFrames);
        if FExportDialog <> nil then
          if HasDirection then
            FExportDialog.AddLine(Format('Measured %s, direction %d (%d frames)',
              [AnimationName, Direction + 1, Length(AFrames)]))
          else
            FExportDialog.AddLine(Format('Measured %s (%d frames)',
              [AnimationName, Length(AFrames)]));
        if Assigned(OnFinished) then
          OnFinished(String.Empty);
        Exit;
      end;
      if Kind = skAtlas then
      begin
        // Its frames join those waiting for a page; every page they fill is
        // saved straight away and its frames let go, before the next capture
        var Part: TAtlasPart;
        Part.Name := AnimationName;
        Part.Entry := Entry;
        Part.Count := Length(AFrames);
        Part.Time := CycleSeconds;
        Part.Origin := Origin;
        Part.OriginKnown := OriginKnown;
        Part.Direction := Direction;
        AddAtlasPart(Part, AFrames);
        if FExportDialog <> nil then
          if HasDirection then
            FExportDialog.AddLine(Format('Captured %s, direction %d (%d frames)',
              [AnimationName, Direction + 1, Length(AFrames)]))
          else
            FExportDialog.AddLine(Format('Captured %s (%d frames)',
              [AnimationName, Length(AFrames)]));
        SaveAtlasPages(False,
          procedure
          begin
            if Assigned(OnFinished) then
              OnFinished(String.Empty);
          end);
        Exit;
      end;
      Frames := AFrames;
      if HasDirection and (Kind in [skStrip, skSheet]) then
      begin
        // One image for every direction of the animation: its frames are
        // kept until the last direction is in, then saved together
        FDirFrames := FDirFrames + AFrames;
        if not LastDirection then
        begin
          if Assigned(OnFinished) then
            OnFinished(String.Empty);
          Exit;
        end;
        Frames := FDirFrames;
        FDirFrames := nil;
        if FDirFailed then
        begin
          Outcome := Stem + ': not saved, as a direction could not be captured';
          DebugMemo.Lines.Add(Outcome);
          if Assigned(OnFinished) then
            OnFinished(Outcome);
          Exit;
        end;
      end
      else if not HasDirection then
        Bearings := nil;
      // Composing and encoding the file is pure arithmetic on the frames,
      // and can take a while for a GIF or a video, so it is done on a
      // worker thread; the window stays responsive meanwhile, and the result
      // is reported on the main thread
      Caption := Format('Saving %s...', [Stem]);
      if FBatchActive then
        ShowExportStep(1, BatchStepTitle + sLineBreak + 'Saving...');
      // A batch saves each image as soon as it is made, so its frames can be
      // let go, and writes all the metadata once the batch ends
      DeferMetadata := FBatchActive;
      Borders := FrameBordersOn;
      Task := TTask.Run(
        procedure
        var
          Saved, Failure, EdgeNote: String;
          FrameCount: Integer;
          Pending: TSprite3DSheetMetadata;
          HasPending: Boolean;
        begin
          Saved := String.Empty;
          Failure := String.Empty;
          HasPending := False;
          // Frames whose drawing reaches the edge, for the Debug tab
          EdgeNote := EdgeTouchNote(Stem, Frames);
          FrameCount := Length(Frames);
          try
            // A GIF or video is one direction; a strip or spritesheet holds
            // every direction captured
            if Kind in [skGif, skMp4] then
              Saved := SaveSheet(Kind, Frames, Folder, Stem, CycleSeconds, Metadata, Origin,
                OriginKnown, AnimationName, nil, Meta, Borders, DeferMetadata, Pending,
                HasPending)
            else
              Saved := SaveSheet(Kind, Frames, Folder, Stem, CycleSeconds, Metadata, Origin,
                OriginKnown, AnimationName, Bearings, Meta, Borders, DeferMetadata, Pending,
                HasPending);
          except
            on E: Exception do
              Failure := 'Can''t save ' + Stem + ' in ' + Folder + sLineBreak + E.Message;
          end;
          Frames := nil;   // the frames are let go before the result is reported
          TThread.Queue(nil,
            procedure
            begin
              if MainFormGone then
                Exit;
              FSaveTasks := RemoveTask(FSaveTasks, Task);
              Task := nil;
              if Failure = String.Empty then
              begin
                // Its metadata, written with the rest at the end
                if HasPending then
                  FPendingMetadata := FPendingMetadata + [Pending];
                if FExportDialog <> nil then
                  FExportDialog.AddLine(Format('Saved %s (%d frames)',
                    [ExtractFileName(Saved), FrameCount]));
              end
              else
                DebugMemo.Lines.Add(Failure);
              if EdgeNote <> String.Empty then
                DebugMemo.Lines.Add(EdgeNote);
              if not Capturing then
                Caption := ProjectionCaption;
              if Assigned(OnFinished) then
                OnFinished(Failure);
            end);
        end);
      FSaveTasks := FSaveTasks + [Task];
    end,
    procedure(const ADone, ATotal: Integer)
    begin
      Caption := Format('Capturing %s: frame %d of %d', [Stem, ADone, ATotal]);
      if FBatchActive then
        ShowExportStep(ADone / Max(1, ATotal), BatchStepTitle + sLineBreak +
          Format('Capturing frame %d of %d', [ADone, ATotal]));
    end);
  Capture.SourceStarted;
  FCapture := Capture;
  UpdateBatchControls;
  Result := Capture.Run;
  if not Result then
  begin
    // Run has finished the source and freed the capture
    FCapture := nil;
    EndCapture;
    UpdateBatchControls;
    AError := Stem + ': the capture could not start.';
  end;
end;

const
  // The transport buttons' icons: SVG paths in a 24 by 24 box, drawn in the
  // button's text colour
  ICON_FIRST = 'M5 6h2v12H5z M8 12l6-6v12z M14 12l6-6v12z';
  ICON_PREVIOUS = 'M7 12l7-6v12z M15 6h2v12h-2z';
  ICON_PLAY = 'M8 5v14l11-7z';
  ICON_PAUSE = 'M6 5h4v14H6z M14 5h4v14h-4z';
  ICON_NEXT = 'M7 6h2v12H7z M10 6v12l7-6z';
  ICON_LAST = 'M4 6v12l6-6z M10 6v12l6-6z M17 6h2v12h-2z';

// The buttons that play, pause and step the selected animation, in a row
// under the animation list and above the batch controls, made here rather
// than in the form designer: first frame, previous frame, play or pause,
// next frame and last frame, each an icon with its name as a hint, and the
// readout of the frame showing at the right. With (None) selected there is
// nothing for them to act on.
procedure TMainForm.BuildTransportControls;
var
  Readout: TLayout;

  function AddReadoutLabel(const AParent: TLayout; const AWidth: Single;
    const AAlign: TTextAlign): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.Position.X := AParent.ChildrenCount * 1000;   // in order, as above
    Result.Align := TAlignLayout.Left;
    Result.Width := AWidth;
    Result.TextSettings.HorzAlign := AAlign;
    Result.TextSettings.WordWrap := False;
    Result.HitTest := False;
  end;

  function AddButton(const AIcon, AHint: String; const AOnClick: TNotifyEvent): TButton;
  var
    Icon: FMX.Objects.TPath;
  begin
    Result := TButton.Create(Self);
    Result.Parent := FTransportLayout;
    // FMX orders left-aligned controls by their X, and a new one at X = 0
    // would go before those already there, reversing the row; so each is
    // placed after the last
    Result.Position.X := FTransportLayout.ChildrenCount * 1000;
    Result.Align := TAlignLayout.Left;
    Result.Width := 30;
    Result.Margins.Right := 2;
    Result.Text := String.Empty;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AOnClick;
    Result.OnApplyStyleLookup := TransportButtonApplyStyle;
    Icon := FMX.Objects.TPath.Create(Self);
    Icon.Parent := Result;
    Icon.Align := TAlignLayout.Center;
    Icon.Width := 24;
    Icon.Height := 24;
    Icon.WrapMode := TPathWrapMode.Original;
    Icon.Data.Data := AIcon;
    Icon.Stroke.Kind := TBrushKind.None;
    Icon.Fill.Color := TAlphaColors.Black;   // the theme's colour once styled
    Icon.HitTest := False;
    Result.TagObject := Icon;
  end;

begin
  FTransportLayout := TLayout.Create(Self);
  FTransportLayout.Parent := ControlsLayout;
  FTransportLayout.Align := TAlignLayout.Bottom;
  FTransportLayout.Height := 36;
  FTransportLayout.Padding.Rect := TRectF.Create(4, 4, 4, 2);
  FFirstButton := AddButton(ICON_FIRST, 'First frame', FirstButtonClick);
  FPreviousButton := AddButton(ICON_PREVIOUS, 'Previous frame', PreviousButtonClick);
  FPlayButton := AddButton(ICON_PLAY, 'Play', PlayButtonClick);
  FNextButton := AddButton(ICON_NEXT, 'Next frame', NextButtonClick);
  FLastButton := AddButton(ICON_LAST, 'Last frame', LastButtonClick);
  // The readout: the frame number right-aligned in a fixed width, then the
  // "/", then the total, so the "/" never moves
  Readout := TLayout.Create(Self);
  Readout.Parent := FTransportLayout;
  Readout.Align := TAlignLayout.Client;
  Readout.Hint := 'The frame showing, of the frames an export makes';
  Readout.ShowHint := True;
  Readout.HitTest := True;   // for the hint
  FFrameNumberLabel := AddReadoutLabel(Readout, 28, TTextAlign.Trailing);
  FFrameSlashLabel := AddReadoutLabel(Readout, 10, TTextAlign.Center);
  FFrameSlashLabel.Text := '/';
  FFrameTotalLabel := AddReadoutLabel(Readout, 28, TTextAlign.Leading);
  UpdateTransportControls;
end;

// An icon takes the colour the theme gives the button's text, so it shows
// on every style, light or dark
procedure TMainForm.TransportButtonApplyStyle(Sender: TObject);
var
  Button: TButton;
begin
  Button := Sender as TButton;
  if Button.TagObject is FMX.Objects.TPath then
    FMX.Objects.TPath(Button.TagObject).Fill.Color := Button.ResultingTextSettings.FontColor;
end;

// The selected animation, or nil for (None), no selection or no model
function TMainForm.SelectedAnimation: TGorillaAnimation;
begin
  Result := nil;
  if (GorillaModel = nil) or not Assigned(GorillaModel.AnimationManager) or
    (AnimationListBox.ItemIndex <= 0) then
    Exit;
  Result := GorillaModel.AnimationManager.GetAnimation(
    AnimationListBox.Items[AnimationListBox.ItemIndex]);
end;

// True while the selected animation is held on a frame
function TMainForm.AnimationHeld: Boolean;
begin
  Result := (FPlayer <> nil) and FPlayer.Held and (FPlayer.Animation = SelectedAnimation);
end;

// Every button needs a selected animation, and none works during a capture.
// Play and pause share a button: its icon and hint say which it does now.
// The label shows the frame held, counted from 1.
procedure TMainForm.UpdateTransportControls;
var
  Anim: TGorillaAnimation;
  Playing: Boolean;
begin
  if FPlayButton = nil then
    Exit;
  if Capturing then
    Anim := nil
  else
    Anim := SelectedAnimation;
  Playing := (Anim <> nil) and (GorillaModel.AnimationManager.Current = Anim) and
    Anim.IsRunning and not AnimationHeld;
  FFirstButton.Enabled := Anim <> nil;
  FPreviousButton.Enabled := Anim <> nil;
  FPlayButton.Enabled := Anim <> nil;
  FNextButton.Enabled := Anim <> nil;
  FLastButton.Enabled := Anim <> nil;
  if Playing then
  begin
    FMX.Objects.TPath(FPlayButton.TagObject).Data.Data := ICON_PAUSE;
    FPlayButton.Hint := 'Pause';
  end
  else
  begin
    FMX.Objects.TPath(FPlayButton.TagObject).Data.Data := ICON_PLAY;
    FPlayButton.Hint := 'Play';
  end;
  UpdateFrameReadout;
end;

// The frame readout: the frame showing, counted from 1, of the frames an
// export makes, held or playing; for an animation playing without a player
// the frames alone; and "- / -" for (None), no model or a capture
procedure TMainForm.UpdateFrameReadout;
var
  Anim: TGorillaAnimation;
  Number, Total: String;
begin
  if FFrameNumberLabel = nil then
    Exit;
  Number := '-';
  Total := '-';
  if not Capturing then
  begin
    Anim := SelectedAnimation;
    if (Anim <> nil) and (FPlayer <> nil) and (FPlayer.Animation = Anim) then
    begin
      Number := IntToStr(FPlayer.CurrentFrame + 1);
      Total := IntToStr(FPlayer.FrameCount);
    end
    else if Anim <> nil then
      Total := IntToStr(AnimationFrameCount(AnimationListBox.ItemIndex));
  end;
  if FFrameNumberLabel.Text <> Number then
    FFrameNumberLabel.Text := Number;
  if FFrameTotalLabel.Text <> Total then
    FFrameTotalLabel.Text := Total;
end;

// The frame rate readout, top left over the view on a dark backing, made here rather than in
// the form designer. It lets clicks through, and is refreshed with the frame readout a few
// times a second, as a value changing every frame cannot be read anyway.
procedure TMainForm.BuildFpsReadout;
begin
  // A dark, mostly opaque backing whatever the theme, with white text, so
  // it reads over any background the view has
  FFpsBack := TRectangle.Create(Self);
  FFpsBack.Parent := ViewportLayout;
  FFpsBack.Align := TAlignLayout.None;
  FFpsBack.Position.Point := TPointF.Create(8, 6);
  FFpsBack.Width := 64;
  FFpsBack.Height := 20;
  FFpsBack.XRadius := 4;
  FFpsBack.YRadius := 4;
  FFpsBack.Fill.Kind := TBrushKind.Solid;
  FFpsBack.Fill.Color := $C0000000;
  FFpsBack.Stroke.Kind := TBrushKind.None;
  FFpsBack.HitTest := False;

  FFpsLabel := TLabel.Create(Self);
  FFpsLabel.Parent := FFpsBack;
  FFpsLabel.Align := TAlignLayout.Client;
  FFpsLabel.StyledSettings := FFpsLabel.StyledSettings - [TStyledSetting.FontColor];
  FFpsLabel.TextSettings.FontColor := TAlphaColors.White;
  FFpsLabel.TextSettings.HorzAlign := TTextAlign.Center;
  FFpsLabel.TextSettings.WordWrap := False;
  FFpsLabel.HitTest := False;
  FFpsLabel.Text := '- fps';
  FFpsBack.BringToFront;

  FReadoutTimer := TTimer.Create(Self);
  FReadoutTimer.Interval := READOUT_INTERVAL_MS;
  FReadoutTimer.OnTimer := ReadoutTimerTimer;
  FReadoutTimer.Enabled := True;
end;

// The frames per second Gorilla's viewport reports, and the frame showing
procedure TMainForm.ReadoutTimerTimer(Sender: TObject);
var
  Text: String;
begin
  if Assigned(GorillaViewport) and Assigned(FFpsLabel) then
  begin
    Text := Format('%d fps', [Round(GorillaViewport.FramesPerSecond)]);
    if FFpsLabel.Text <> Text then
      FFpsLabel.Text := Text;
  end;
  UpdateFrameReadout;
  CheckDisplay;
end;

// A player for the selected animation, playing it from the start if it is
// not already playing; False if there is no animation to play
function TMainForm.EnsurePlayer: Boolean;
var
  Anim: TGorillaAnimation;
begin
  Result := False;
  if Capturing then
    Exit;
  Anim := SelectedAnimation;
  if Anim = nil then
    Exit;
  if (FPlayer = nil) or (FPlayer.Animation <> Anim) then
  begin
    FreeAndNil(FPlayer);
    if (GorillaModel.AnimationManager.Current <> Anim) or not Anim.IsRunning then
      GorillaModel.AnimationManager.PlayAnimation(Anim);
    FPlayer := TSprite3DAnimationPlayer.Create(GorillaModel, Anim, FSettings.AnimationFps,
      FrameOverride(Anim.Id));
  end;
  Result := True;
end;

// After a button: the buttons, and the view, as a held animation is framed
// by its own volume
procedure TMainForm.TransportChanged;
begin
  UpdateTransportControls;
  UpdateView;
end;

// Play or pause: carries on from the frame held, holds the frame showing,
// or plays the selected animation if it is not playing
procedure TMainForm.PlayButtonClick(Sender: TObject);
var
  Anim: TGorillaAnimation;
begin
  Anim := SelectedAnimation;
  if Capturing or (Anim = nil) then
    Exit;
  if (FPlayer = nil) or (FPlayer.Animation <> Anim) or
    (GorillaModel.AnimationManager.Current <> Anim) or not Anim.IsRunning then
  begin
    // Not playing: from the start, playing
    FreeAndNil(FPlayer);
    FHoldNew := False;
    PlaySelectedAnimation;
    TransportChanged;
    Exit;
  end;
  if FPlayer.Held then
    FPlayer.Play
  else
    FPlayer.Pause;
  FHoldNew := FPlayer.Held;
  TransportChanged;
end;

// First frame: held on the animation's first pose
procedure TMainForm.FirstButtonClick(Sender: TObject);
begin
  if not EnsurePlayer then
    Exit;
  FPlayer.ShowFrame(0);
  TransportChanged;
end;

// Last frame: held on the animation's last pose, the frame an export ends on
procedure TMainForm.LastButtonClick(Sender: TObject);
begin
  if not EnsurePlayer then
    Exit;
  FPlayer.ShowFrame(FPlayer.FrameCount - 1);
  TransportChanged;
end;

// Previous frame: held one frame back, from the one held or showing; from
// the first, round to the last
procedure TMainForm.PreviousButtonClick(Sender: TObject);
begin
  if not EnsurePlayer then
    Exit;
  FPlayer.Step(-1);
  TransportChanged;
end;

// Next frame: held one frame on, from the one held or showing; from the
// last, round to the first
procedure TMainForm.NextButtonClick(Sender: TObject);
begin
  if not EnsurePlayer then
    Exit;
  FPlayer.Step(1);
  TransportChanged;
end;

// The batch controls under the animation list, made here rather than in the
// form designer, and tick boxes on the list's entries. FMX's list box draws
// each entry's tick box to the left of its text.
procedure TMainForm.BuildBatchControls;
var
  Row: TLayout;
begin
  AnimationListBox.ShowCheckboxes := True;
  AnimationListBox.OnChangeCheck := AnimationListBoxChangeCheck;

  FBatchLayout := TLayout.Create(Self);
  FBatchLayout.Parent := ControlsLayout;
  FBatchLayout.Align := TAlignLayout.Bottom;
  FBatchLayout.Height := 94;
  FBatchLayout.Padding.Rect := TRectF.Create(4, 4, 4, 4);

  // First row: All, then what to save
  Row := TLayout.Create(Self);
  Row.Parent := FBatchLayout;
  Row.Align := TAlignLayout.Top;
  Row.Height := 26;

  FBatchAll := TCheckBox.Create(Self);
  FBatchAll.Parent := Row;
  FBatchAll.Align := TAlignLayout.Left;
  FBatchAll.Width := 44;
  FBatchAll.Text := 'All';
  FBatchAll.Hint := 'Tick or clear every animation';
  FBatchAll.ShowHint := True;
  FBatchAll.OnChange := BatchAllChange;

  FBatchKindBox := TComboBox.Create(Self);
  FBatchKindBox.Parent := Row;
  FBatchKindBox.Align := TAlignLayout.Client;
  // In TSheetKind's order: the item index is the kind
  FBatchKindBox.Items.Add('Sprite strip');
  FBatchKindBox.Items.Add('Spritesheet');
  FBatchKindBox.Items.Add('Texture Atlas');
  FBatchKindBox.Items.Add('AniGif');
  // MP4 video is added by StartVideo if the video libraries load
  FBatchKindBox.ItemIndex := Ord(skStrip);
  FBatchKindIndex := Ord(skStrip);
  FBatchKindBox.OnChange := BatchKindChange;
  // As it was left last session; MP4 waits for StartVideo to offer it
  RestoreBatchKind;

  // Second row, above Export: the metadata, directions and two-pass choices
  Row := TLayout.Create(Self);
  Row.Parent := FBatchLayout;
  Row.Align := TAlignLayout.Top;
  Row.Margins.Top := 4;
  Row.Height := 26;
  Row.Position.Y := 100;   // below the first row

  FBatchMetadata := TCheckBox.Create(Self);
  FBatchMetadata.Parent := Row;
  FBatchMetadata.Align := TAlignLayout.Left;
  FBatchMetadata.Width := 84;
  FBatchMetadata.Text := 'Metadata';
  FBatchMetadata.Hint := 'Save a .json file of the same name beside each strip or ' +
    'spritesheet, with its layout, origin and each frame''s empty border';
  FBatchMetadata.ShowHint := True;
  FBatchMetadata.IsChecked := FSettings.ExportMetadata;
  FBatchMetadata.OnChange := BatchMetadataChange;

  FBatchDirections := TCheckBox.Create(Self);
  FBatchDirections.Parent := Row;
  FBatchDirections.Align := TAlignLayout.Left;
  FBatchDirections.Width := 88;
  FBatchDirections.Text := 'Directions';
  FBatchDirections.Hint := 'Export every animation in each direction set in Model, ' +
    'Directions, in their order';
  FBatchDirections.ShowHint := True;
  FBatchDirections.IsChecked := FSettings.ExportDirections;
  FBatchDirections.OnChange := BatchDirectionsChange;

  FBatchTwoPass := TCheckBox.Create(Self);
  FBatchTwoPass.Parent := Row;
  FBatchTwoPass.Align := TAlignLayout.Client;
  FBatchTwoPass.Text := '2-pass';
  FBatchTwoPass.Hint := 'Export in two passes: the first, without overscan, measures the ' +
    'frames; the second exports them reframed to fill the frame';
  FBatchTwoPass.ShowHint := True;
  FBatchTwoPass.IsChecked := False;   // not kept between sessions

  // Third row: Export, and Abort beside it
  Row := TLayout.Create(Self);
  Row.Parent := FBatchLayout;
  Row.Align := TAlignLayout.Top;
  Row.Margins.Top := 4;
  Row.Height := 26;
  Row.Position.Y := 200;   // below the second row

  FAbortButton := TButton.Create(Self);
  FAbortButton.Parent := Row;
  FAbortButton.Align := TAlignLayout.Right;
  FAbortButton.Margins.Left := 4;
  FAbortButton.Width := 56;
  FAbortButton.Text := 'Abort';
  FAbortButton.Hint := 'Stop the export once the current animation is saved';
  FAbortButton.ShowHint := True;
  FAbortButton.OnClick := AbortButtonClick;

  FExportButton := TButton.Create(Self);
  FExportButton.Parent := Row;
  FExportButton.Align := TAlignLayout.Client;
  FExportButton.Text := 'Export';
  FExportButton.Hint := 'Save every ticked animation as chosen above';
  FExportButton.ShowHint := True;
  FExportButton.OnClick := ExportButtonClick;

  // Put the strip below the list, whatever the creation order did
  FBatchLayout.Position.Y := ControlsLayout.Height;
  UpdateBatchControls;
end;

// The name settings.json keeps a kind of export by
function SheetKindKey(const AKind: TSheetKind): String;
begin
  case AKind of
    skSheet:
      Result := 'sheet';
    skAtlas:
      Result := 'atlas';
    skGif:
      Result := 'gif';
    skMp4:
      Result := 'mp4';
  else
    Result := 'strip';
  end;
end;

// What to save changed: Metadata is offered for strips and spritesheets only
procedure TMainForm.BatchKindChange(Sender: TObject);
begin
  if FSyncingChecks then
    Exit;
  if FBatchKindBox.ItemIndex = Ord(skAtlas) then
    // Once the drop-down has closed, from a fresh main-loop turn
    TThread.ForceQueue(nil, ChooseAtlasFolder)
  else
  begin
    FBatchKindIndex := FBatchKindBox.ItemIndex;
    FBatchKindBox.Hint := String.Empty;
    // Kept for next session
    FSettings.ExportKind := SheetKindKey(TSheetKind(FBatchKindIndex));
  end;
  UpdateBatchControls;
end;

// The drop-down as settings.json last kept it: the kind of export, if the
// drop-down offers it, and for a texture atlas its folder, if it is still
// there; otherwise the folder is asked for at Export. Choosing it here asks
// for nothing.
procedure TMainForm.RestoreBatchKind;
var
  Index: Integer;
begin
  if FBatchKindBox = nil then
    Exit;
  Index := Ord(skStrip);
  for var Kind := Low(TSheetKind) to High(TSheetKind) do
    if SameText(FSettings.ExportKind, SheetKindKey(Kind)) then
      Index := Ord(Kind);
  if Index >= FBatchKindBox.Items.Count then
    Exit;   // MP4 before the video libraries have loaded
  FSyncingChecks := True;
  try
    FBatchKindBox.ItemIndex := Index;
  finally
    FSyncingChecks := False;
  end;
  FBatchKindIndex := Index;
  FBatchKindBox.Hint := String.Empty;
  if (Index = Ord(skAtlas)) and (FSettings.AtlasFolder <> String.Empty) and
    TDirectory.Exists(FSettings.AtlasFolder) then
  begin
    FAtlasFolder := FSettings.AtlasFolder;
    FBatchKindBox.Hint := 'Texture atlas pages are saved in ' + FAtlasFolder;
  end;
  UpdateBatchControls;
end;

// Texture Atlas was chosen: where its pages go, in a folder dialog opening
// at the save folder, as for Export. Without a folder the drop-down goes
// back to what it was.
procedure TMainForm.ChooseAtlasFolder;
var
  Folder: String;
begin
  if MainFormGone or (FBatchKindBox.ItemIndex <> Ord(skAtlas)) then
    Exit;
  if ChooseExportFolder(Folder) then
  begin
    FAtlasFolder := Folder;
    FBatchKindIndex := Ord(skAtlas);
    // Both kept for next session
    FSettings.ExportKind := SheetKindKey(skAtlas);
    FSettings.AtlasFolder := Folder;
    FBatchKindBox.Hint := 'Texture atlas pages are saved in ' + Folder;
    DebugMemo.Lines.Add('Texture atlas pages will be saved in ' + Folder);
  end
  else
  begin
    FSyncingChecks := True;
    try
      FBatchKindBox.ItemIndex := FBatchKindIndex;
    finally
      FSyncingChecks := False;
    end;
  end;
  UpdateBatchControls;
end;

// Kept in settings.json; used by every texture atlas made from now on
procedure TMainForm.ApplyAtlasSettings(const APageSize: Integer;
  const ANonPowerOf2: Boolean);
begin
  if (FSettings.AtlasPageSize = APageSize) and (FSettings.AtlasNonPowerOf2 = ANonPowerOf2) then
    Exit;
  FSettings.AtlasPageSize := APageSize;   // limited to ATLAS_PAGE_SIZES
  FSettings.AtlasNonPowerOf2 := ANonPowerOf2;
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

// Kept in settings.json, and used by every strip or spritesheet saved from now on,
// from Export or the pop-up menu
procedure TMainForm.BatchMetadataChange(Sender: TObject);
begin
  // Ticked by UpdateBatchControls for a texture atlas: not the user's choice
  if FSyncingChecks then
    Exit;
  FSettings.ExportMetadata := FBatchMetadata.IsChecked;
end;

// Kept in settings.json; ticked, every animation is exported in each
// direction of Model, Directions
procedure TMainForm.BatchDirectionsChange(Sender: TObject);
begin
  FSettings.ExportDirections := FBatchDirections.IsChecked;
end;

// Ticks or clears the given entries of the Animations list, leaving the
// selected entry, and so the animation playing, as they were: FMX can move
// the selection to an entry whose tick changes, so it is put back, and the
// change plays nothing meanwhile. Entries not in the list are skipped.
procedure TMainForm.SetEntryChecks(const AEntries: TArray<Integer>; const AChecked: Boolean);
var
  Selected: Integer;
begin
  Selected := AnimationListBox.ItemIndex;
  FKeepingSelection := True;
  try
    for var Entry in AEntries do
      if (Entry >= 0) and (Entry < AnimationListBox.Count) then
        AnimationListBox.ListItems[Entry].IsChecked := AChecked;
    if AnimationListBox.ItemIndex <> Selected then
      AnimationListBox.ItemIndex := Selected;
  finally
    FKeepingSelection := False;
  end;
end;

// All ticks every animation, or clears every entry. (None), entry 0, is not
// an animation, so ticking All leaves it as it is; it is only exported when
// ticked by hand. Clearing All clears it too.
procedure TMainForm.BatchAllChange(Sender: TObject);
var
  I: Integer;
  Entries: TArray<Integer>;
begin
  if FSyncingChecks then
    Exit;
  Entries := nil;
  for I := 0 to AnimationListBox.Count - 1 do
    if (I > 0) or not FBatchAll.IsChecked then
      Entries := Entries + [I];
  FSyncingChecks := True;
  try
    // The selected entry, and the animation playing, stay as they are
    SetEntryChecks(Entries, FBatchAll.IsChecked);
  finally
    FSyncingChecks := False;
  end;
  UpdateView;   // ticked or not decides the volume shown
end;

// A tick changed by hand: All shows whether every animation is ticked,
// whatever (None), entry 0, is set to
procedure TMainForm.AnimationListBoxChangeCheck(Sender: TObject);
var
  I: Integer;
  Every: Boolean;
begin
  if FSyncingChecks or (FBatchAll = nil) then
    Exit;
  Every := AnimationListBox.Count > 1;
  for I := 1 to AnimationListBox.Count - 1 do
    if not AnimationListBox.ListItems[I].IsChecked then
    begin
      Every := False;
      Break;
    end;
  FSyncingChecks := True;
  try
    FBatchAll.IsChecked := Every;
  finally
    FSyncingChecks := False;
  end;
  UpdateView;   // ticked or not decides the volume shown
end;

// Export is offered only when there is a model and nothing is being saved
procedure TMainForm.UpdateBatchControls;
begin
  UpdateTransportControls;
  if FExportButton = nil then
    Exit;
  FExportButton.Enabled := not Capturing;
  FBatchKindBox.Enabled := not Capturing;
  FBatchAll.Enabled := not Capturing;
  // Only strips, spritesheets and atlases have metadata. An atlas always
  // has it, as without it there is no telling its animations apart: the box
  // shows ticked and cannot be changed while Texture Atlas is chosen, and
  // shows the choice kept for strips and spritesheets again after
  var WasSyncing := FSyncingChecks;
  FSyncingChecks := True;
  try
    if FBatchKindBox.ItemIndex = Ord(skAtlas) then
      FBatchMetadata.IsChecked := True
    else
      FBatchMetadata.IsChecked := FSettings.ExportMetadata;
  finally
    FSyncingChecks := WasSyncing;
  end;
  FBatchMetadata.Enabled := not Capturing and
    (FBatchKindBox.ItemIndex in [Ord(skStrip), Ord(skSheet)]);
  FBatchDirections.Enabled := not Capturing;
  FBatchTwoPass.Enabled := not Capturing;
  UpdateListFileItems;
  FAbortButton.Enabled := FBatchActive and not FBatchAborted and not FAtlasSaving;
  // The lock cannot change while a capture has its own framing on the camera
  UpdateCameraLockControls;
  if FAtlasSaving then
    FExportButton.Text := 'Saving atlas...'
  else if FBatchActive and FBatchAborted then
    FExportButton.Text := 'Stopping...'
  else if FBatchActive then
    FExportButton.Text := 'Exporting...'
  else
    FExportButton.Text := 'Export';
end;

// Where a batch goes: a folder dialog opening at SaveFolder, in which a new
// sub-folder can be made. Android and iOS have no folder dialog, so there
// the fixed Grabs folder is used. SaveFolder itself is left as it is.
function TMainForm.ChooseExportFolder(out AFolder: String): Boolean;
begin
  AFolder := DefaultGrabFolder;
  if AFolder <> String.Empty then
    Exit(True);
  AFolder := SaveFolder;
  if (AFolder = String.Empty) or not TDirectory.Exists(AFolder) then
    AFolder := TPath.GetDocumentsPath;
  Result := SelectDirectory('Export Location', String.Empty, AFolder) and
    (AFolder <> String.Empty);
end;

// Saves every ticked entry as the drop-down says, one after another
procedure TMainForm.ExportButtonClick(Sender: TObject);
var
  I: Integer;
  Items: TArray<Integer>;
  Folder: String;
begin
  if Capturing or FOffscreen.Busy then
    Exit;
  if GorillaModel = nil then
  begin
    ShowMessage('Open a model first.');
    Exit;
  end;
  Items := nil;
  for I := 0 to AnimationListBox.Count - 1 do
    if AnimationListBox.ListItems[I].IsChecked then
      Items := Items + [I];
  if Length(Items) = 0 then
  begin
    ShowMessage('Tick the animations to export first.');
    Exit;
  end;
  FBatchKind := TSheetKind(EnsureRange(FBatchKindBox.ItemIndex, Ord(Low(TSheetKind)),
    Ord(High(TSheetKind))));
  // A texture atlas goes to the folder chosen with it, if it is still there
  if (FBatchKind = skAtlas) and (FAtlasFolder <> String.Empty) and
    TDirectory.Exists(FAtlasFolder) then
    Folder := FAtlasFolder
  else if not ChooseExportFolder(Folder) then
    Exit   // cancelled
  else if FBatchKind = skAtlas then
  begin
    FAtlasFolder := Folder;
    FSettings.AtlasFolder := Folder;
  end;

  StartBatch(Items, FBatchKind, Folder, FBatchTwoPass.IsChecked);
end;

// Runs a batch: every entry of AItems, in order, saved as AKind in
// AFolder, behind the progress dialog. With Directions ticked, each entry is
// captured once per direction of Model, Directions, in their order, before
// the next entry. With ATwoPass, the whole batch is first run through once
// with overscan off, saving nothing, only to measure how much empty border
// its frames leave; the second pass is then the export itself, overscan as
// chosen, with every capture's framing slid and scaled so the sprite fills
// the frame to within TWO_PASS_MARGIN pixels.
procedure TMainForm.StartBatch(const AItems: TArray<Integer>; const AKind: TSheetKind;
  const AFolder: String; const ATwoPass: Boolean);
var
  Items: TArray<Integer>;
  Folder: String;
begin
  Folder := AFolder;
  FBatchKind := AKind;
  // Each entry, then each of its directions
  if FSettings.ExportDirections then
    FBatchBearings := FSettings.DirectionBearings
  else
    FBatchBearings := nil;
  Items := nil;
  FBatchDirs := nil;
  for var Entry in AItems do
    if Length(FBatchBearings) = 0 then
    begin
      Items := Items + [Entry];
      FBatchDirs := FBatchDirs + [-1];
    end
    else
      for var D := 0 to High(FBatchBearings) do
      begin
        Items := Items + [Entry];
        FBatchDirs := FBatchDirs + [D];
      end;
  FBatchEntryCount := Length(AItems);
  // Timed from here to the report
  FBatchClock := TStopwatch.StartNew;
  FBatchCaptureMs := -1;
  FBatchRemainingAt := -1;
  FDirFrames := nil;
  FDirFailed := False;
  FBatchItems := Items;
  FBatchPos := 0;
  FAtlasParts := nil;
  // The entry selected now is selected again, and played, once it is done
  FBatchSelected := AnimationListBox.ItemIndex;
  FBatchFolder := Folder;
  FBatchSaved := 0;
  FBatchErrors := nil;
  FBatchAborted := False;
  // 2-pass: the first pass measures, with overscan off whatever is chosen,
  // as its frames are only looked at for their empty borders
  FTwoPassRun := ATwoPass;
  FTwoPassMeasured := False;
  FTwoPassAdjusted := False;
  FAtlasQueue := nil;
  FAtlasPageCount := 0;
  FAtlasFailed := nil;
  FAtlasPending := nil;
  FPendingMetadata := nil;
  FBatchOriginSet := False;
  if FTwoPassRun then
    FBatchPass := 1
  else
    FBatchPass := 0;
  SetMeasuringOverscan(FBatchPass = 1);
  FBatchActive := True;
  UpdateBatchControls;
  // Every drawing is off screen: the view need not redraw meanwhile
  PauseViewForExport(True);

  // The progress, Abort, and at the end the outcome, in a dialog of its own
  FExportDialog := TExportProgressForm.Create(nil);
  if Length(FBatchBearings) > 0 then
    FExportDialog.Caption := Format('Exporting %d animations in %d directions as %s',
      [FBatchEntryCount, Length(FBatchBearings), FBatchKindBox.Items[Ord(FBatchKind)]])
  else
    FExportDialog.Caption := Format('Exporting %d animations as %s',
      [FBatchEntryCount, FBatchKindBox.Items[Ord(FBatchKind)]]);
  FExportDialog.OnAbort := ExportDialogAbort;
  FExportDialog.OnClosed := ExportDialogClosed;
  // Autoclose when done, as it was left
  FExportDialog.AutoClose := FSettings.ExportAutoClose;
  FExportDialog.OnAutoCloseChange := ExportDialogAutoCloseChange;
  FExportDialog.AddLine('To ' + Folder);
  FPassStartMs := 0;
  if FTwoPassRun then
  begin
    FExportDialog.SetRemainingPass(1);
    FExportDialog.AddLine('Pass 1 of 2: measuring, overscan off, nothing saved');
  end;
  ShowExportStep(0, 'Starting...');
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog frees itself when closed
  FExportDialog.ShowAndFree;
  RunNextBatchItem;
  {$ELSE}
  // The batch runs from queued calls, which the modal dialog's own loop
  // carries out; ShowModal returns once Close is pressed at the end
  TThread.ForceQueue(nil, ContinueBatch);
  try
    FExportDialog.ShowModal;
  finally
    var Dialog := FExportDialog;
    FExportDialog := nil;
    Dialog.Free;
  end;
  {$ENDIF}
end;

// The batch's progress in its dialog: AItemFraction of the way through the
// entry under way, and what is happening, after which entry it is; and the
// time left, from the time taken so far and the fraction done
procedure TMainForm.ShowExportStep(const AItemFraction: Single; const AStatus: String);
const
  // No estimate until this much has been done and this long has passed, as
  // the first frames say little about the rest
  ESTIMATE_AFTER_FRACTION = 0.01;
  ESTIMATE_AFTER_MS = 2000;
  // Changed at most this often, so the figure can be read
  ESTIMATE_EVERY_MS = 500;
var
  Total: Integer;
  Fraction, BarFraction: Double;
  Elapsed: Int64;
begin
  if FExportDialog = nil then
    Exit;
  Total := Max(1, Length(FBatchItems));
  // How far through the pass under way, the only pass of an ordinary export
  Fraction := (Min(FBatchPos, Total) + EnsureRange(AItemFraction, 0, 1)) / Total;
  // A 2-pass export goes through the batch twice; each pass is half the bar
  BarFraction := Fraction;
  if FTwoPassRun then
    if FBatchPass = 2 then
      BarFraction := 0.5 + Fraction / 2
    else
      BarFraction := Fraction / 2;
  FExportDialog.SetProgress(BarFraction, AStatus);
  if FBatchAborted then
  begin
    // The status line says it is stopping; the estimate was for the lot
    FExportDialog.SetRemainingNote(String.Empty);
    Exit;
  end;
  // The time remaining is for the pass under way: a measuring pass draws
  // without overscan and saves nothing, so it says little about the export
  Elapsed := FBatchClock.ElapsedMilliseconds - FPassStartMs;
  if (Fraction < ESTIMATE_AFTER_FRACTION) or (Elapsed < ESTIMATE_AFTER_MS) then
  begin
    if FBatchRemainingAt < 0 then
      FExportDialog.SetRemaining(-1);
    Exit;
  end;
  if (FBatchRemainingAt >= 0) and (Elapsed - FBatchRemainingAt < ESTIMATE_EVERY_MS) then
    Exit;
  FBatchRemainingAt := Elapsed;   // on the pass's own clock
  // The rest at the rate so far; every step is taken to be alike, so a
  // batch of animations of very different lengths makes it rougher
  FExportDialog.SetRemaining(Round(Elapsed * (1 - Fraction) / Fraction));
end;

// Which list entry, counted from 1, batch step APos is of
function TMainForm.BatchEntryOrdinal(const APos: Integer): Integer;
begin
  Result := 0;
  for var I := 0 to Min(APos, High(FBatchItems)) do
    if (I = 0) or (FBatchItems[I] <> FBatchItems[I - 1]) then
      Inc(Result);
end;

// The batch step under way, for the progress dialog: which animation of how
// many, and which direction, if directions are used
function TMainForm.BatchStepTitle: String;
var
  Entry, Direction: Integer;
  Point: String;
begin
  Result := String.Empty;
  if (FBatchPos < 0) or (FBatchPos > High(FBatchItems)) then
    Exit;
  Entry := FBatchItems[FBatchPos];
  Result := Format('Animation %d of %d: %s', [BatchEntryOrdinal(FBatchPos),
    FBatchEntryCount, AnimationListBox.Items[Entry]]);
  if FBatchPass = 1 then
    Result := 'Pass 1 of 2, measuring. ' + Result
  else if FBatchPass = 2 then
    Result := 'Pass 2 of 2. ' + Result;
  Direction := FBatchDirs[FBatchPos];
  if Direction >= 0 then
  begin
    Point := CompassPointName(FBatchBearings[Direction]);
    if Point = String.Empty then
      Point := FormatFloat('0.##', FBatchBearings[Direction],
        TFormatSettings.Invariant) + #176;
    Result := Result + Format(', direction %d of %d (%s)',
      [Direction + 1, Length(FBatchBearings), Point]);
  end;
end;

// Turns the camera for a direction: the view it shows is the one the
// azimuth dial would give turned on by ABearing, so bearing 0 is the view
// as it is. A locked camera is turned too, as a direction needs it; either
// way EndCapture turns it back.
procedure TMainForm.TurnToDirection(const ABearing: Single);
var
  WasLocked: Boolean;
begin
  if not FDirTurned then
    FDirRestoreAzimuth := GorillaCamera.Azimuth;
  FDirTurned := True;
  WasLocked := GorillaCamera.Locked;
  GorillaCamera.Locked := False;
  try
    // The dial's azimuth is the camera's reversed
    GorillaCamera.Azimuth := Wrap360(FDirRestoreAzimuth - ABearing);
  finally
    GorillaCamera.Locked := WasLocked;
  end;
end;

// Abort in the progress dialog: as the Abort button under the list
procedure TMainForm.ExportDialogAbort(Sender: TObject);
begin
  AbortButtonClick(Sender);
end;

// Autoclose when done ticked or cleared in the progress dialog: kept in
// settings.json straight away
procedure TMainForm.ExportDialogAutoCloseChange(Sender: TObject);
begin
  if not (Sender is TExportProgressForm) then
    Exit;
  FSettings.ExportAutoClose := TExportProgressForm(Sender).AutoClose;
  try
    FSettings.Save;
  except
    on E: Exception do
      DebugMemo.Lines.Add('Can''t save the settings to ' + FSettings.FileName + ': ' +
        E.Message);
  end;
end;

// The progress dialog has closed; on Android and iOS it frees itself
procedure TMainForm.ExportDialogClosed(Sender: TObject);
begin
  if Sender = FExportDialog then
    FExportDialog := nil;
end;

// Stops the view's own timed redraws while a batch exports, and starts them
// again after. A grab makes the viewport draw a frame itself, which is all
// an export needs, so the view is not redrawn in between. On macOS and iOS
// grabs are screenshots of the view, so it is left drawing there.
procedure TMainForm.PauseViewForExport(const APause: Boolean);
begin
  {$IF not DEFINED(MACOS)}
  if APause = FViewPaused then
    Exit;
  FViewPaused := APause;
  GorillaViewport.UseFixedFrameRate := not APause;
  if not APause then
    GorillaViewport.Invalidate;
  {$ENDIF}
end;

// The batch's next entry, queued after an entry has been saved; nothing if
// the batch has been ended, as when the form is closing
procedure TMainForm.ContinueBatch;
begin
  if FBatchActive and not MainFormGone then
    RunNextBatchItem;
end;

// Starts the batch's next entry, or ends the batch after the last. Each
// entry starts from a fresh main-loop turn, after the last capture has
// freed itself.
procedure TMainForm.RunNextBatchItem;
var
  Error: String;
  Started: Boolean;
begin
  Started := False;
  // Abort takes effect at the start of an entry, so every direction of the
  // one under way is still captured and saved
  while not Started and (FBatchPos <= High(FBatchItems)) and not (FBatchAborted and
    ((FBatchPos = 0) or (FBatchItems[FBatchPos] <> FBatchItems[FBatchPos - 1]))) do
  begin
    if (FBatchPos = 0) or (FBatchItems[FBatchPos] <> FBatchItems[FBatchPos - 1]) then
    begin
      // A new entry: no frames of other directions kept for it yet
      FDirFrames := nil;
      FDirFailed := False;
    end;
    Started := StartCapture(FBatchKind, FBatchItems[FBatchPos], FBatchDirs[FBatchPos],
      FBatchFolder,
      procedure(AResult: String)
      begin
        if FBatchPass = 1 then
        begin
          // Measuring saves nothing, and a capture that failed here is
          // already logged; it is tried again, and reported, in pass 2
        end
        else if AResult <> String.Empty then
        begin
          FBatchErrors := FBatchErrors + [AResult];
          FDirFailed := True;
        end
        else if (FBatchKind <> skAtlas) and ((FBatchDirs[FBatchPos] < 0) or
          (FBatchDirs[FBatchPos] = High(FBatchBearings))) then
          // Counted once its last direction is saved; a texture atlas's
          // animations are counted once their pages are. The ticks stay as
          // they are.
          Inc(FBatchSaved);
        Inc(FBatchPos);
        // The next entry from a fresh main-loop turn, by a method rather
        // than another anonymous one nested in this
        TThread.ForceQueue(nil, ContinueBatch);
      end, Error);
    if not Started then
    begin
      // Reported once, by the pass that exports
      if FBatchPass <> 1 then
        FBatchErrors := FBatchErrors + [Error];
      DebugMemo.Lines.Add(Error);
      FDirFailed := True;
      Inc(FBatchPos);
    end;
  end;
  if not Started then
    FinishBatch;
end;

// Ends the batch: for a texture atlas, makes and saves its pages first,
// which reports when done; otherwise reports straight away
procedure TMainForm.FinishBatch;
begin
  // Overscan as chosen again, if a measuring pass turned it off
  SetMeasuringOverscan(False);
  if FQuitConfirmed then
  begin
    // Quitting: nothing more is saved, and nothing is reported
    FBatchPass := 0;
    FBatchActive := False;
    FAtlasParts := nil;
    FAtlasQueue := nil;
    FAtlasPending := nil;
    FPendingMetadata := nil;
    PauseViewForExport(False);
    Exit;
  end;
  if FBatchPass = 1 then
  begin
    if FBatchAborted then
    begin
      // Stopped while measuring: nothing has been exported
      FBatchPos := 0;
      ReportBatch;
    end
    else
      StartSecondPass;
    Exit;
  end;
  // Every image is saved by now, but for a texture atlas's last page, which
  // is saved first; then every metadata file, then the report
  if (FBatchKind = skAtlas) and (Length(FAtlasParts) > 0) then
    SaveAtlasPages(True, FinishAtlas)
  else
  begin
    WriteBatchMetadata;
    ReportBatch;
  end;
end;

// The end of a 2-pass export's first pass: works out the framing from what
// it measured, then runs the batch again from the start as an ordinary
// export, overscan as chosen, with that framing on top of every fit
procedure TMainForm.StartSecondPass;
begin
  ComputeTwoPassAdjust;
  FBatchPass := 2;
  FBatchPos := 0;
  // The origin is the second pass's own
  FBatchOriginSet := False;
  FDirFrames := nil;
  FDirFailed := False;
  FAtlasParts := nil;
  FAtlasQueue := nil;
  FAtlasPageCount := 0;
  FAtlasFailed := nil;
  FAtlasPending := nil;
  FPendingMetadata := nil;
  // The time remaining starts over for this pass, as an export's frames
  // take longer to make than a measuring pass's
  FBatchRemainingAt := -1;
  FPassStartMs := FBatchClock.ElapsedMilliseconds;
  if FExportDialog <> nil then
  begin
    FExportDialog.SetRemainingPass(2);
    FExportDialog.AddLine('Pass 2 of 2: exporting');
  end;
  ShowExportStep(0, 'Starting pass 2...');
  TThread.ForceQueue(nil, ContinueBatch);
end;

// How many list entries have every one of their parts among ASaved: the
// animations of a texture atlas saved in every direction
function DistinctWholeEntries(const AParts: TArray<TAtlasPart>;
  const ASaved: TArray<Integer>): Integer;
var
  IsSaved: TArray<Boolean>;
  Entries: TArray<Integer>;
  Whole, Seen: Boolean;
begin
  Result := 0;
  SetLength(IsSaved, Length(AParts));
  for var Index in ASaved do
    if (Index >= 0) and (Index < Length(AParts)) then
      IsSaved[Index] := True;
  Entries := nil;
  for var I := 0 to High(AParts) do
  begin
    Seen := False;
    for var Entry in Entries do
      Seen := Seen or (Entry = AParts[I].Entry);
    if Seen then
      Continue;
    Entries := Entries + [AParts[I].Entry];
    Whole := True;
    for var J := I to High(AParts) do
      if AParts[J].Entry = AParts[I].Entry then
        Whole := Whole and IsSaved[J];
    if Whole then
      Inc(Result);
  end;
end;

// A texture atlas animation just captured: kept for its pages' metadata,
// its frames added to those waiting for a page. Frames too large for any
// page are let go, and the animation reported as not saved.
procedure TMainForm.AddAtlasPart(const APart: TAtlasPart;
  const AFrames: TArray<TSprite3DImage>);
var
  Index, PageSize: Integer;
  Cell: TAtlasCell;
begin
  Index := Length(FAtlasParts);
  FAtlasParts := FAtlasParts + [APart];
  FAtlasFailed := FAtlasFailed + [False];
  if Length(AFrames) = 0 then
    Exit;
  PageSize := FSettings.AtlasPageSize;
  if (AFrames[0].Width > PageSize) or (AFrames[0].Height > PageSize) then
  begin
    FAtlasFailed[Index] := True;
    FBatchErrors := FBatchErrors + [Format('%s: frames of %d x %d do not fit on a %d x %d ' +
      'atlas page; choose a larger page size in Model, Animation Settings, or a smaller ' +
      'grab size.', [APart.Name, AFrames[0].Width, AFrames[0].Height, PageSize, PageSize])];
    Exit;
  end;
  Cell.Part := Index;
  for var I := 0 to High(AFrames) do
  begin
    Cell.Frame := I;
    Cell.Image := AFrames[I];
    FAtlasQueue := FAtlasQueue + [Cell];
  end;
end;

// Saves, on a worker thread, every texture atlas page the waiting frames
// fill, in order, numbered on from those already saved, and lets their
// frames go; with AFinal, the frames left over too, as the last page. Each
// page's metadata is measured and kept, to be written when the batch ends.
// AThen runs on the main thread once they are saved, or straight away if
// there is no page to save.
procedure TMainForm.SaveAtlasPages(const AFinal: Boolean; const AThen: TProc);
var
  PerPage, PageSize, First: Integer;
  NonPowerOf2, Borders: Boolean;
  Pages: TArray<TArray<TAtlasCell>>;
  Parts: TArray<TAtlasPart>;
  Folder, Stem: String;
  Bearings: TArray<Single>;
  Meta: TSprite3DSheetMeta;
  Task: ITask;
begin
  Pages := nil;
  PageSize := FSettings.AtlasPageSize;
  NonPowerOf2 := FSettings.AtlasNonPowerOf2;
  Borders := FrameBordersOn;
  if Length(FAtlasQueue) > 0 then
  begin
    // A full page holds as many frames as fit each way; every page but the
    // last is full, so a full page is laid out the same whatever follows
    PerPage := Max(1, (PageSize div Max(1, FAtlasQueue[0].Image.Width)) *
      (PageSize div Max(1, FAtlasQueue[0].Image.Height)));
    while Length(FAtlasQueue) >= PerPage do
    begin
      SetLength(Pages, Length(Pages) + 1);
      Pages[High(Pages)] := System.Copy(FAtlasQueue, 0, PerPage);
      System.Delete(FAtlasQueue, 0, PerPage);
    end;
    if AFinal and (Length(FAtlasQueue) > 0) then
    begin
      SetLength(Pages, Length(Pages) + 1);
      Pages[High(Pages)] := FAtlasQueue;
      FAtlasQueue := nil;
    end;
  end;
  if Length(Pages) = 0 then
  begin
    AThen();
    Exit;
  end;
  First := FAtlasPageCount + 1;
  Inc(FAtlasPageCount, Length(Pages));
  Parts := System.Copy(FAtlasParts);
  Folder := FBatchFolder;
  Stem := SafeFileStem(TPath.GetFileNameWithoutExtension(FSettings.LastModel));
  Bearings := Copy(FBatchBearings);
  // The camera these frames were drawn with: for a 2-pass export, the
  // second pass's
  Meta := ExportMeta(1, 1);
  if AFinal then
  begin
    FAtlasSaving := True;
    UpdateBatchControls;
    Caption := 'Saving texture atlas...';
  end;
  if FExportDialog <> nil then
    ShowExportStep(1, BatchStepTitle + sLineBreak + 'Saving the texture atlas page...');
  Task := TTask.Run(
    procedure
    var
      Files, Notes, EdgeNotes: TArray<String>;
      Kept: TArray<TSprite3DSheetMetadata>;
      Failed: TArray<Integer>;
      Metadata: TSprite3DSheetMetadata;
      FileName: String;
    begin
      Files := nil;
      Notes := nil;
      EdgeNotes := nil;
      Kept := nil;
      Failed := nil;
      // The pages of an earlier atlas of this model go first, so none is
      // left over from a larger one
      if First = 1 then
        try
          DeleteAtlasPages(OSFriendlyPath(Folder), Stem, Notes);
        except
          on E: Exception do
            Notes := Notes + [E.Message];
        end;
      for var P := 0 to High(Pages) do
      begin
        FileName := TPath.Combine(OSFriendlyPath(Folder),
          Format('%s_atlas_%.2d.png', [Stem, First + P]));
        try
          ForceDirectories(OSFriendlyPath(Folder));
          Files := Files + [SaveAtlasPage(Pages[P], Parts, FileName, First + P, PageSize,
            NonPowerOf2, Borders, Bearings, Meta, Metadata, Notes)];
          var PageFrames: TArray<TSprite3DImage> := nil;
          for var Cell in Pages[P] do
            PageFrames := PageFrames + [Cell.Image];
          var EdgeNote := EdgeTouchNote(ExtractFileName(FileName), PageFrames);
          if EdgeNote <> String.Empty then
            EdgeNotes := EdgeNotes + [EdgeNote];
          Kept := Kept + [Metadata];
        except
          on E: Exception do
          begin
            Notes := Notes + ['Can''t save ' + FileName + sLineBreak + E.Message];
            // Every animation with frames on this page is not wholly saved
            for var Cell in Pages[P] do
              Failed := Failed + [Cell.Part];
          end;
        end;
        // Its frames are done with
        Pages[P] := nil;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if MainFormGone then
            Exit;
          FSaveTasks := RemoveTask(FSaveTasks, Task);
          Task := nil;
          FAtlasPending := FAtlasPending + Kept;
          for var Part in Failed do
            if (Part >= 0) and (Part < Length(FAtlasFailed)) then
              FAtlasFailed[Part] := True;
          for var Written in Files do
          begin
            if FExportDialog <> nil then
              FExportDialog.AddLine('Saved ' + ExtractFileName(Written));
          end;
          for var Note in Notes do
            DebugMemo.Lines.Add(Note);
          for var Note in EdgeNotes do
            DebugMemo.Lines.Add(Note);
          FBatchErrors := FBatchErrors + Notes;
          if not FQuitConfirmed then
            AThen();
        end);
    end);
  FSaveTasks := FSaveTasks + [Task];
end;

// The texture atlas's last page is saved: every page's metadata now knows
// how many pages and frames there are in all, and is written with the rest;
// the animations whose every page was saved are counted; then the report
procedure TMainForm.FinishAtlas;
var
  Total: Integer;
  Saved: TArray<Integer>;
begin
  FAtlasSaving := False;
  Total := 0;
  for var Part in FAtlasParts do
    Inc(Total, Part.Count);
  for var I := 0 to High(FAtlasPending) do
  begin
    FAtlasPending[I].Info.Meta.PageCount := FAtlasPageCount;
    FAtlasPending[I].Info.Meta.TotalFrames := Total;
  end;
  FPendingMetadata := FPendingMetadata + FAtlasPending;
  FAtlasPending := nil;
  Saved := nil;
  for var I := 0 to High(FAtlasParts) do
    if (FAtlasParts[I].Count > 0) and not FAtlasFailed[I] then
      Saved := Saved + [I];
  // An animation is saved once every direction of it is
  FBatchSaved := FBatchSaved + DistinctWholeEntries(FAtlasParts, Saved);
  FAtlasParts := nil;
  FAtlasFailed := nil;
  if not Capturing then
    Caption := ProjectionCaption;
  WriteBatchMetadata;
  ReportBatch;
end;

// One texture atlas page, ACells in order, laid out as PlanAtlasPages lays
// out a page of that many frames, saved as AFileName; its metadata is
// measured into AMetadata, to be written later, its page count and total
// frames still to be filled in. AParts says which animation each cell's part
// is. Returns the file written, for the log. Runs on a worker thread.
function TMainForm.SaveAtlasPage(const ACells: TArray<TAtlasCell>;
  const AParts: TArray<TAtlasPart>; const AFileName: String; const APage, APageSize: Integer;
  const ANonPowerOf2, ABorders: Boolean; const ADirections: TArray<Single>;
  const AMeta: TSprite3DSheetMeta; out AMetadata: TSprite3DSheetMetadata;
  var ANotes: TArray<String>): String;
var
  Pages: TArray<TSprite3DAtlasPage>;
  Page: TSprite3DAtlasPage;
  Frames: TArray<TSprite3DImage>;
  Info: TSprite3DSheetInfo;
  Ref: TSprite3DFrameRef;
  Listed, PartIndex: Integer;
begin
  Pages := PlanAtlasPages([Length(ACells)], ACells[0].Image.Width, ACells[0].Image.Height,
    APageSize, ANonPowerOf2);
  if Length(Pages) <> 1 then
    raise EArgumentException.CreateFmt('%d frames do not make one atlas page.',
      [Length(ACells)]);
  Page := Pages[0];
  // Every field set here or below; Default() would mean Gorilla's
  // TGorillaOAuthMode.Default in this unit
  Frames := nil;
  SetLength(Info.Directions, Length(ADirections));
  for var K := 0 to High(ADirections) do
    Info.Directions[K] := ADirections[K];
  Info.Animations := nil;
  Info.AnimationFrames := nil;
  Info.AnimationTimes := nil;
  Info.Frames := nil;
  for var Cell in ACells do
  begin
    PartIndex := Cell.Part;
    // Each animation listed once per page, with its whole length
    Listed := -1;
    for var K := 0 to High(Info.Animations) do
      if Info.Animations[K] = AParts[PartIndex].Name then
        Listed := K;
    if Listed < 0 then
    begin
      Info.Animations := Info.Animations + [AParts[PartIndex].Name];
      // Its frames in each direction: every direction has as many
      Info.AnimationFrames := Info.AnimationFrames + [AParts[PartIndex].Count];
      Info.AnimationTimes := Info.AnimationTimes + [AParts[PartIndex].Time];
      Listed := High(Info.Animations);
    end;
    Frames := Frames + [Cell.Image];
    Ref.Animation := Listed;
    Ref.Direction := AParts[PartIndex].Direction;
    Ref.Frame := Cell.Frame;
    Info.Frames := Info.Frames + [Ref];
  end;
  // With ABorders each frame has a black border in the page, but not in what
  // the metadata is measured from
  if ABorders then
    SavePng(ComposeAtlasPage(FramesWithBorder(Frames), Page), AFileName)
  else
    SavePng(ComposeAtlasPage(Frames, Page), AFileName);
  Info.Width := Page.Width;
  Info.Height := Page.Height;
  Info.Cols := Page.Cols;
  Info.Rows := Page.Rows;
  // Page APage; the page count and total frames are known once the last
  // page is saved
  Info.Meta := AMeta;
  Info.Meta.Page := APage;
  Info.Meta.PageCount := 1;
  Info.Meta.TotalFrames := 0;
  // Every animation of a batch is framed alike, and snapped to the same
  // pixel, so they share one origin; the first's is given, and a difference
  // is reported, except for a 2-pass export, whose second pass is reframed
  // from the first and gives its own origin
  Info.Origin := AParts[ACells[0].Part].Origin;
  Info.OriginKnown := AParts[ACells[0].Part].OriginKnown;
  if not AMeta.TwoPass then
    for var Cell in ACells do
      if (AParts[Cell.Part].OriginKnown <> Info.OriginKnown) or
        (AParts[Cell.Part].Origin <> Info.Origin) then
      begin
        ANotes := ANotes + [Format('%s: the animations'' origins differ; the ' +
          'first''s is given', [ExtractFileName(AFileName)])];
        Break;
      end;
  AMetadata := MeasureSheetMetadata(TPath.ChangeExtension(AFileName, '.json'), Frames, Info);
  Result := Format('%s (%d animations, %d frames, %d x %d)', [AFileName,
    Length(Info.Animations), Length(Frames), Page.Width, Page.Height]);
end;

// Deletes AStem_atlas_<number>.png in AFolder, any number of digits, and the
// .json beside each; nothing else, not even AStem_atlas_x.png. What cannot
// be deleted is added to ANotes. Runs on a worker thread.
procedure TMainForm.DeleteAtlasPages(const AFolder, AStem: String;
  var ANotes: TArray<String>);
var
  Prefix, Digits, Json: String;
  IsNumber: Boolean;
begin
  if not TDirectory.Exists(AFolder) then
    Exit;
  Prefix := AStem + '_atlas_';
  for var PageFile in TDirectory.GetFiles(AFolder, Prefix + '*.png') do
  begin
    // The wildcard matches more than a number, and ignores case on Windows
    Digits := TPath.GetFileNameWithoutExtension(PageFile);
    if not SameText(Copy(Digits, 1, Length(Prefix)), Prefix) then
      Continue;
    Digits := Copy(Digits, Length(Prefix) + 1, MaxInt);
    IsNumber := Digits <> String.Empty;
    for var C in Digits do
      if not CharInSet(C, ['0'..'9']) then
        IsNumber := False;
    if not IsNumber or not SameText(TPath.GetExtension(PageFile), '.png') then
      Continue;
    try
      TFile.Delete(PageFile);
      Json := TPath.ChangeExtension(PageFile, '.json');
      if TFile.Exists(Json) then
        TFile.Delete(Json);
    except
      on E: Exception do
        ANotes := ANotes + ['Can''t delete the old atlas page ' + PageFile + sLineBreak +
          E.Message];
    end;
  end;
end;

// A length of time for a report: tenths of a second under a minute, such as
// 12.3 s, then minutes and seconds, 1 min 05 s, then hours, 1 h 02 min
function DurationText(const AMilliseconds: Int64): String;
var
  Seconds: Int64;
begin
  if AMilliseconds < 60000 then
    Exit(FormatFloat('0.0', Max(0, AMilliseconds) / 1000, TFormatSettings.Invariant) +
      ' s');
  Seconds := (AMilliseconds + 500) div 1000;
  if Seconds < 3600 then
    Result := Format('%d min %.2d s', [Seconds div 60, Seconds mod 60])
  else
    Result := Format('%d h %.2d min', [Seconds div 3600, (Seconds mod 3600) div 60]);
end;

// Reports the batch and gives the list back its own animation
procedure TMainForm.ReportBatch;
var
  Report: String;
begin
  FBatchActive := False;
  FBatchPass := 0;
  UpdateBatchControls;
  // The batch left its last animation playing: the entry selected before
  // it, which it does not change, is selected and played again
  if (FBatchSelected >= 0) and (FBatchSelected < AnimationListBox.Count) and
    (AnimationListBox.ItemIndex <> FBatchSelected) then
  begin
    FKeepingSelection := True;
    try
      AnimationListBox.ItemIndex := FBatchSelected;
    finally
      FKeepingSelection := False;
    end;
  end;
  FChangePlayed := False;
  PlaySelectedAnimation;
  Report := Format('Exported %d of %d animations to %s',
    [FBatchSaved, FBatchEntryCount, FBatchFolder]);
  if Length(FBatchBearings) > 0 then
    Report := Report + Format(', each in %d directions', [Length(FBatchBearings)]);
  if FTwoPassRun then
    Report := Report + ', in two passes';
  if FBatchAborted then
    Report := Report + sLineBreak + Format('Aborted: %d not exported',
      [FBatchEntryCount - BatchEntryOrdinal(FBatchPos - 1)]);
  // How long it took; for a texture atlas, the capturing and the pages too
  FBatchClock.Stop;
  Report := Report + sLineBreak + 'Took ' + DurationText(FBatchClock.ElapsedMilliseconds);
  if FBatchCaptureMs >= 0 then
    Report := Report + Format(': capturing %s, making and saving the pages %s',
      [DurationText(FBatchCaptureMs),
      DurationText(FBatchClock.ElapsedMilliseconds - FBatchCaptureMs)]);
  FDirFrames := nil;
  DebugMemo.Lines.Add(Report);
  PauseViewForExport(False);
  // The outcome stays in the progress dialog until it is closed
  if FExportDialog <> nil then
    FExportDialog.Finish(Report, FBatchErrors)
  else if Length(FBatchErrors) > 0 then
    ShowMessage(Report + sLineBreak + sLineBreak + String.Join(sLineBreak, FBatchErrors))
  else
    ShowMessage(Report);
  FBatchErrors := nil;
  FBatchItems := nil;
  FBatchAborted := False;
  UpdateBatchControls;
end;

// Stops the batch after the entry being captured; that one still finishes
// and is saved, as a half-made capture has nothing worth keeping
procedure TMainForm.AbortButtonClick(Sender: TObject);
begin
  if not FBatchActive or FBatchAborted then
    Exit;
  FBatchAborted := True;
  DebugMemo.Lines.Add('Export aborted; stopping after the current animation');
  UpdateBatchControls;
end;

// Frames the camera once for every frame of ASource, for a target of
// AWidth x AHeight, with the pan on top as for every fit. A single
// animation saved from the list's pop-up menu, or the Animation menu on
// Android and iOS, is framed to its own swept volume, so it fills the
// target as far as its own poses allow. A batch, and the (None) still, are
// framed to the combined swept volume, which holds every pose of every
// animation used, so every animation of a batch is framed alike. Either way
// the orbit centre is on the turning axis, so a turn of the camera's
// azimuth never takes the model out of the target.
function TMainForm.FrameCaptureFraming(const ASource: TSprite3DFrameSource;
  const AWidth, AHeight: Integer): Boolean;
var
  Volume: TSweptVolume;
begin
  if not FBatchActive and (ASource is TSprite3DAnimationFrames) then
  begin
    Volume := AnimationSweptVolume(TSprite3DAnimationFrames(ASource).Animation.Id);
    if not Volume.Valid then
      Volume := SweepFitVolume;   // not measured: the combined volume holds it too
  end
  else
    Volume := SweepFitVolume;
  Result := FitCameraToSweep(GorillaCamera, GorillaModel, Volume, AWidth, AHeight);
  if Result and FPanEnabled then
    GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point +
      ModelPanOffset(GorillaModel, FModelBox, FPanX, FPanZ);
end;

// The on-screen view as it was before the capture, refitted if the
// viewport changed size meanwhile
procedure TMainForm.EndCapture;
begin
  // Grabs and icons show the background again, as the view does
  FOffscreen.Backdrop := FBackground.Spec;
  // The turn to a direction, even on a locked camera
  if FDirTurned then
  begin
    var WasLocked := GorillaCamera.Locked;
    GorillaCamera.Locked := False;
    try
      GorillaCamera.Azimuth := FDirRestoreAzimuth;
    finally
      GorillaCamera.Locked := WasLocked;
    end;
    FDirTurned := False;
  end;
  // The slide that put the centre of rotation on a pixel, even on a locked
  // camera; a framing the capture set is put back over it anyway
  if FOriginSnapped then
    GorillaCamera.OrbitCenter.Point := FOriginRestore;
  FOriginSnapped := False;
  // Only a framing the capture set is put back
  if FCaptureFramed then
    GorillaCamera.RestoreFraming(FCaptureRestore);
  FCaptureFramed := False;
  ApplyAngles;
  if FRefitAfterCapture then
  begin
    ApplyShowCombinedSweep;
    FitModel;
  end;
  FRefitAfterCapture := False;
  Caption := ProjectionCaption;
end;

// Slides the view, by under half a pixel each way, so the model's centre of
// rotation falls exactly on the centre of a pixel of an AWidth by AHeight
// grab, and gives that pixel, counted from 0 at the top left, as AOrigin:
// whole numbers. ShiftView is exact in orthographic projection and very
// nearly so in perspective, so the point is measured again after each
// slide, a few times at most. Which way a slide moves the picture is
// checked as it goes rather than assumed. False, with AOrigin (0, 0) and the
// view as it was, if the point is behind the camera. EndCapture undoes the
// slide.
function TMainForm.SnapCaptureOrigin(const AWidth, AHeight: Integer;
  out AOrigin: TPoint): Boolean;
const
  TOLERANCE = 0.01;   // of a pixel
  TRIES = 4;
var
  X, Y, DX, DY, NX, NY: Single;
  SignX, SignY: Single;
  I, TX, TY: Integer;

  function Measure(out AX, AY: Single): Boolean;
  begin
    Result := GorillaCamera.ProjectToView(GorillaModel.RotationCenter.Point, GorillaModel,
      AWidth, AHeight, AX, AY);
  end;

begin
  AOrigin := TPoint.Zero;
  Result := (GorillaModel <> nil) and Measure(X, Y);
  if not Result then
    Exit;
  FOriginRestore := GorillaCamera.OrbitCenter.Point;
  FOriginSnapped := True;
  // ShiftView moves the picture the other way to the view: right is -X,
  // and up moves the picture down, +Y
  SignX := -1;
  SignY := 1;
  // The pixel the point is in; but within a batch, every capture is framed
  // alike, so the point falls within a pixel of the first capture's, and
  // it goes on that same pixel. Otherwise a point that falls on the line
  // between two pixels, as recentring the sprite can leave it, would go
  // into one or the other by rounding alone.
  TX := Floor(X);
  TY := Floor(Y);
  if FBatchActive and FBatchOriginSet and (Abs(FBatchOrigin.X + 0.5 - X) <= 1) and
    (Abs(FBatchOrigin.Y + 0.5 - Y) <= 1) then
  begin
    TX := FBatchOrigin.X;
    TY := FBatchOrigin.Y;
  end;
  for I := 1 to TRIES do
  begin
    // To the centre of the pixel chosen
    DX := TX + 0.5 - X;
    DY := TY + 0.5 - Y;
    if (Abs(DX) <= TOLERANCE) and (Abs(DY) <= TOLERANCE) then
      Break;
    GorillaCamera.ShiftView(SignX * DX, SignY * DY, AWidth, AHeight);
    if not Measure(NX, NY) then
      Break;
    // A slide that made it worse went the wrong way: undo it twice over
    if (Abs(DX) > TOLERANCE) and (Abs(TX + 0.5 - NX) > Abs(DX)) then
    begin
      GorillaCamera.ShiftView(-2 * SignX * DX, 0, AWidth, AHeight);
      SignX := -SignX;
    end;
    if (Abs(DY) > TOLERANCE) and (Abs(TY + 0.5 - NY) > Abs(DY)) then
    begin
      GorillaCamera.ShiftView(0, -2 * SignY * DY, AWidth, AHeight);
      SignY := -SignY;
    end;
    if not Measure(X, Y) then
      Break;
  end;
  AOrigin := TPoint.Create(TX, TY);
  // The batch's origin, for the captures after this one
  if FBatchActive and not FBatchOriginSet then
  begin
    FBatchOrigin := AOrigin;
    FBatchOriginSet := True;
  end;
end;

const
  // How many empty pixels a 2-pass export aims to leave round the sprite on
  // the side with least room: one, so nothing drawn ever touches the edge
  TWO_PASS_MARGIN = 1;
  // Where that side's edge is aimed, in pixels in from the frame's edge:
  // halfway across the pixel after the empty ones
  TWO_PASS_EDGE = TWO_PASS_MARGIN + 0.5;

// A 2-pass export's first pass draws without overscan, whatever is chosen,
// as it only measures; AMeasuring False puts the chosen overscan back
procedure TMainForm.SetMeasuringOverscan(const AMeasuring: Boolean);
begin
  if AMeasuring or not FOverscanOn then
    FOffscreen.Overscan := 1
  else
    FOffscreen.Overscan := FSettings.Overscan;
end;

// The first pass's frames: how far the drawn part reaches each way, over
// every frame of every animation and direction of the batch so far. Each
// side starts from the outermost pixel drawn on; where that line's pixels
// are at most partly covered, the edge is taken to be that far into the
// pixel, so the edge is known to a fraction of a pixel when the drawing is
// smoothed. A frame with nothing drawn on it is left out.
procedure TMainForm.MeasureTwoPassFrames(const AFrames: TArray<TSprite3DImage>);

  // How fully the most covered pixel of a row or column is drawn, 0 to 1
  function LineCover(const AFrame: TSprite3DImage; const AStart, AStep,
    ACount: Integer): Single;
  var
    Most: Integer;
  begin
    Most := 0;
    for var I := 0 to ACount - 1 do
      Most := Max(Most, Integer(AFrame.Pixels[(NativeInt(AStart) + I * AStep) * 4 + 3]));
    Result := Most / 255;
  end;

var
  Empty: TSprite3DFrameEmpty;
  Reach: TRectF;
  W, H, X0, X1, Y0, Y1: Integer;
begin
  for var Frame in AFrames do
  begin
    W := Frame.Width;
    H := Frame.Height;
    if Length(Frame.Pixels) < Int64(W) * H * 4 then
      Continue;
    Empty := MeasureFrameEmpty(Frame);
    if Empty.Left >= W then
      Continue;   // nothing drawn
    X0 := Empty.Left;
    X1 := W - 1 - Empty.Right;
    Y0 := Empty.Top;
    Y1 := H - 1 - Empty.Bottom;
    // The outermost column or row drawn on, less what of it is not covered
    Reach.Left := X0 + 1 - LineCover(Frame, X0, W, H);
    Reach.Right := X1 + LineCover(Frame, X1, W, H);
    Reach.Top := Y0 + 1 - LineCover(Frame, Y0 * W, 1, W);
    Reach.Bottom := Y1 + LineCover(Frame, Y1 * W, 1, W);
    if not FTwoPassMeasured then
      FTwoPassBounds := Reach
    else
    begin
      FTwoPassBounds.Left := Min(FTwoPassBounds.Left, Reach.Left);
      FTwoPassBounds.Top := Min(FTwoPassBounds.Top, Reach.Top);
      FTwoPassBounds.Right := Max(FTwoPassBounds.Right, Reach.Right);
      FTwoPassBounds.Bottom := Max(FTwoPassBounds.Bottom, Reach.Bottom);
    end;
    FTwoPassMeasured := True;
  end;
end;

// The second pass's framing, from where the first pass's drawing reached.
// The picture is slid so the drawn part's centre falls on the frame's
// centre, then drawn larger or smaller about that centre until, on the side
// with least room, its edge lies TWO_PASS_EDGE pixels in from the frame's
// edge: halfway across the second pixel, so that pixel is drawn on and the
// outermost one is left empty, an empty border of TWO_PASS_MARGIN, with
// half a pixel to spare either way. The other two sides keep the drawn
// part's shape, so are left with more. With nothing measured, or a locked
// camera, which is captured as it stands, the second pass is an ordinary
// export.
procedure TMainForm.ComputeTwoPassAdjust;
const
  // Scaling beyond this either way is taken to be a bad measurement
  SCALE_LIMIT = 100;
var
  W, H: Integer;
  DrawnW, DrawnH, RoomW, RoomH: Single;
  Grow: Double;
  Note: String;
begin
  FTwoPassAdjusted := False;
  W := FOffscreen.Width;
  H := FOffscreen.Height;
  if CameraLocked then
    Note := '2-pass: the camera is locked, so it is used as it stands'
  else if not FTwoPassMeasured then
    Note := '2-pass: nothing was drawn to measure, so the framing is left as it is'
  else
  begin
    DrawnW := FTwoPassBounds.Right - FTwoPassBounds.Left;
    DrawnH := FTwoPassBounds.Bottom - FTwoPassBounds.Top;
    RoomW := W - 2 * TWO_PASS_EDGE;
    RoomH := H - 2 * TWO_PASS_EDGE;
    if (DrawnW <= 0) or (DrawnH <= 0) or (RoomW < 1) or (RoomH < 1) then
      Note := '2-pass: the frame is too small to reframe, so the framing is left as it is'
    else
    begin
      Grow := Min(RoomW / DrawnW, RoomH / DrawnH);
      if (Grow > SCALE_LIMIT) or (Grow < 1 / SCALE_LIMIT) then
        Note := Format('2-pass: the sprite would be drawn %.4g times as large, which is ' +
          'too far off to trust, so the framing is left as it is', [Grow])
      else
      begin
        // The drawn part's centre to the frame's
        FTwoPassMoveX := W / 2 - (FTwoPassBounds.Left + FTwoPassBounds.Right) / 2;
        FTwoPassMoveY := H / 2 - (FTwoPassBounds.Top + FTwoPassBounds.Bottom) / 2;
        // OrthoHeight, or Distance, shrinks as the picture grows
        FTwoPassScale := 1 / Grow;
        FTwoPassAdjusted := True;
        // The slide is not reported: the sprite is always recentred, so the
        // origin always moves, and the metadata gives where it ends up
        Note := Format('2-pass: the sprite will be drawn %.4f times as large', [Grow]);
        // Drawing that reached the edge may have gone past it, so it is
        // larger than measured and will not shrink quite as far as aimed
        if (FTwoPassBounds.Left <= 0) or (FTwoPassBounds.Top <= 0) or
          (FTwoPassBounds.Right >= W) or (FTwoPassBounds.Bottom >= H) then
          Note := Note + '. The sprite touched the edge of the frame, so it may have been ' +
            'cut off and its empty border may not come down to ' + IntToStr(TWO_PASS_MARGIN);
        if not GorillaCamera.IsOrthographic then
          Note := Note + '. In perspective the result is close rather than exact';
      end;
    end;
  end;
  if FExportDialog <> nil then
    FExportDialog.AddLine(Note);
end;

// Puts the second pass's framing on top of a capture's fit, for a grab of
// AWidth by AHeight: the slide first, in the fit's own pixels, as measured,
// then the change of size, about the centre of the view. In orthographic
// projection OrthoHeight, and OrthoWidth if it is set, change; in
// perspective Distance does, though never so far that the camera is inside
// the model's bounds. EndCapture puts back the framing as it was.
procedure TMainForm.ApplyTwoPassAdjust(const AWidth, AHeight: Integer);
var
  Radius, NewDistance: Single;
begin
  SlidePicture(FTwoPassMoveX, FTwoPassMoveY, AWidth, AHeight);
  if GorillaCamera.IsOrthographic then
  begin
    GorillaCamera.OrthoHeight := GorillaCamera.OrthoHeight * FTwoPassScale;
    if GorillaCamera.OrthoWidth > 0 then
      GorillaCamera.OrthoWidth := GorillaCamera.OrthoWidth * FTwoPassScale;
  end
  else
  begin
    NewDistance := GorillaCamera.Distance * FTwoPassScale;
    Radius := 0.5 * Sqrt(Sqr(FModelBox.Width) + Sqr(FModelBox.Height) +
      Sqr(FModelBox.Depth));
    // Never nearer than the model's radius, nor nearer than the fit if that
    // was already nearer still
    Radius := Min(Radius, GorillaCamera.Distance);
    if (Radius > 0) and (NewDistance < Radius) then
      NewDistance := Radius;
    GorillaCamera.Distance := NewDistance;
  end;
end;

// Slides the picture ARight pixels right and ADown pixels down, in a view
// of AWidth by AHeight, by sliding the view the other way. As in
// SnapCaptureOrigin, which way the slide moves the picture is checked on
// the model's centre of rotation rather than assumed, and put right if it
// went the wrong way.
procedure TMainForm.SlidePicture(const ARight, ADown: Single;
  const AWidth, AHeight: Integer);
const
  TOLERANCE = 0.01;   // of a pixel
var
  X0, Y0, X1, Y1: Single;
  Known: Boolean;
begin
  if (Abs(ARight) <= TOLERANCE) and (Abs(ADown) <= TOLERANCE) then
    Exit;
  Known := (GorillaModel <> nil) and GorillaCamera.ProjectToView(
    GorillaModel.RotationCenter.Point, GorillaModel, AWidth, AHeight, X0, Y0);
  // The picture moves the other way to the view: right is -X, and sliding
  // the view up moves the picture down
  GorillaCamera.ShiftView(-ARight, ADown, AWidth, AHeight);
  if not Known or not GorillaCamera.ProjectToView(GorillaModel.RotationCenter.Point,
    GorillaModel, AWidth, AHeight, X1, Y1) then
    Exit;
  if (Abs(ARight) > TOLERANCE) and ((X1 - X0) * ARight < 0) then
    GorillaCamera.ShiftView(2 * ARight, 0, AWidth, AHeight);
  if (Abs(ADown) > TOLERANCE) and ((Y1 - Y0) * ADown < 0) then
    GorillaCamera.ShiftView(0, -2 * ADown, AWidth, AHeight);
end;

// Writes every metadata file the batch measured, in the order the images
// were saved, once every image is saved. For a 2-pass export, each gives as
// sprite_empty the least on each side over every frame of the second pass,
// the whole export's, so they all give the same; otherwise each gives its
// own frames'. Each frame's own empty is its own either way.
procedure TMainForm.WriteBatchMetadata;
var
  All: TArray<TSprite3DFrameEmpty>;
  Least: TSprite3DFrameEmpty;
  Unified: Boolean;
  Note: String;
begin
  if Length(FPendingMetadata) = 0 then
    Exit;
  Unified := FTwoPassRun and (FBatchPass = 2);
  if Unified then
  begin
    All := nil;
    for var Pending in FPendingMetadata do
      All := All + Pending.Empties;
    Least := LeastFrameEmpty(All);
    All := nil;
  end;
  Caption := 'Saving metadata...';
  if FExportDialog <> nil then
    FExportDialog.SetProgress(1, 'Saving the metadata...');
  for var Pending in FPendingMetadata do
    try
      if Unified then
        WriteSheetMetadata(Pending, Least)
      else
        WriteSheetMetadata(Pending);
      if FExportDialog <> nil then
        FExportDialog.AddLine('Saved ' + ExtractFileName(Pending.FileName));
    except
      on E: Exception do
      begin
        Note := 'Can''t save ' + Pending.FileName + sLineBreak + E.Message;
        DebugMemo.Lines.Add(Note);
        FBatchErrors := FBatchErrors + [Note];
      end;
    end;
  FPendingMetadata := nil;
  if Unified then
  begin
    Note := Format('2-pass: sprite_empty for every frame of the export: left %d, top %d, ' +
      'right %d, bottom %d', [Least.Left, Least.Top, Least.Right, Least.Bottom]);
    if Min(Min(Least.Left, Least.Top), Min(Least.Right, Least.Bottom)) <>
      TWO_PASS_MARGIN then
      Note := Note + Format('; aimed at %d on the side with least room', [TWO_PASS_MARGIN]);
    if FExportDialog <> nil then
      FExportDialog.AddLine(Note);
  end;
  if not Capturing then
    Caption := ProjectionCaption;
end;

// File, Debug, Frame Borders, made only while debug_enabled is true in
// settings.json, just above Exit, ticked as debug_frame_borders says
procedure TMainForm.BuildDebugMenu;
var
  Separator: TMenuItem;
begin
  if not FSettings.DebugEnabled then
    Exit;
  Separator := TMenuItem.Create(Self);
  Separator.Text := '-';
  FileMenu.InsertObject(ExitMenuItem.Index, Separator);
  FDebugMenu := TMenuItem.Create(Self);
  FDebugMenu.Text := 'Debug';
  FileMenu.InsertObject(ExitMenuItem.Index, FDebugMenu);
  FFrameBordersItem := TMenuItem.Create(Self);
  FFrameBordersItem.Text := 'Frame Borders';
  FFrameBordersItem.IsChecked := FSettings.DebugFrameBorders;
  FFrameBordersItem.OnClick := FrameBordersItemClick;
  FDebugMenu.AddObject(FFrameBordersItem);
end;

// Ticks or unticks Frame Borders, kept in settings.json as
// debug_frame_borders straight away
procedure TMainForm.FrameBordersItemClick(Sender: TObject);
begin
  FFrameBordersItem.IsChecked := not FFrameBordersItem.IsChecked;
  FSettings.DebugFrameBorders := FFrameBordersItem.IsChecked;
  if FSettings.DebugFrameBorders then
    DebugMemo.Lines.Add('Frame borders on: every exported frame gets a 1-pixel black border')
  else
    DebugMemo.Lines.Add('Frame borders off');
  try
    FSettings.Save;
  except
    on E: Exception do
      ShowMessage('Can''t save the settings to ' + FSettings.FileName + sLineBreak +
        E.Message);
  end;
end;

// Whether exported frames get a black border: only while debugging is on
function TMainForm.FrameBordersOn: Boolean;
begin
  Result := FSettings.DebugEnabled and FSettings.DebugFrameBorders;
end;

// Lays out and writes the captured frames in AFolder, creating it if need
// be; names follow the pop-up menu's rules, and an existing file of the same
// name is replaced. With ADirections, the frames are every direction's in
// turn, as many for each: a strip has one row per direction, and a
// spritesheet holds them all in its square grid. With AMetadata, a strip or
// spritesheet also gets its metadata beside it, the same name with .json,
// AOrigin giving the pixel the centre of rotation falls on in a frame, if
// AOriginKnown, AAnimation the name of the animation saved, and ADirections
// the directions' bearings. Returns the file written, with the codec in
// brackets for an MP4, or with the metadata added, for the log; raises if
// it cannot be written. Runs on a worker thread, so touches no controls.
function TMainForm.SaveSheet(const AKind: TSheetKind;
  const AFrames: TArray<TSprite3DImage>; const AFolder, AStem: String;
  const ACycleSeconds: Double; const AMetadata: Boolean; const AOrigin: TPoint;
  const AOriginKnown: Boolean; const AAnimation: String;
  const ADirections: TArray<Single>; const AMeta: TSprite3DSheetMeta;
  const ABorders, ADeferMetadata: Boolean; out APending: TSprite3DSheetMetadata;
  out AHasPending: Boolean): String;
var
  Cells, Directions, PerDirection: Integer;
  Folder: String;
  // What goes into the image: the frames, or with ABorders copies with a black
  // border; the metadata is always measured from the frames themselves
  Shown: TArray<TSprite3DImage>;

  // The metadata of an image of ACols by ARows frames: this one animation,
  // in each of its directions
  function SheetInfo(const ACols, ARows: Integer): TSprite3DSheetInfo;
  begin
    // Every field set; Default() would mean Gorilla's
    // TGorillaOAuthMode.Default in this unit
    SetLength(Result.Directions, Length(ADirections));
    for var K := 0 to High(ADirections) do
      Result.Directions[K] := ADirections[K];
    Result.Width := ACols * AFrames[0].Width;
    Result.Height := ARows * AFrames[0].Height;
    Result.Cols := ACols;
    Result.Rows := ARows;
    Result.Origin := AOrigin;
    Result.OriginKnown := AOriginKnown;
    Result.Animations := [AAnimation];
    Result.AnimationFrames := [PerDirection];
    // Its own length, whatever number of frames it was saved at
    Result.AnimationTimes := [ACycleSeconds];
    Result.Meta := AMeta;   // one image: page 1 of 1
    // Frame I is frame I mod PerDirection of direction I div PerDirection
    SetLength(Result.Frames, Length(AFrames));
    for var I := 0 to High(AFrames) do
    begin
      Result.Frames[I].Animation := 0;
      Result.Frames[I].Direction := I div PerDirection;
      Result.Frames[I].Frame := I mod PerDirection;
    end;
  end;

  // The image's metadata, ACols by ARows frames: written now, saying so for
  // the log, or with ADeferMetadata measured and handed back to be written
  // once the batch ends, so the frames need not be kept
  function SaveMetadata(const AImage: String; const ACols, ARows: Integer): String;
  begin
    Result := String.Empty;
    if ADeferMetadata then
    begin
      APending := MeasureSheetMetadata(TPath.ChangeExtension(AImage, '.json'), AFrames,
        SheetInfo(ACols, ARows));
      AHasPending := True;
    end
    else
    begin
      SaveSheetMetadata(TPath.ChangeExtension(AImage, '.json'), AFrames,
        SheetInfo(ACols, ARows));
      Result := ' and its .json';
    end;
  end;

begin
  AHasPending := False;
  if ABorders then
    Shown := FramesWithBorder(AFrames)
  else
    Shown := AFrames;
  Folder := OSFriendlyPath(AFolder);
  ForceDirectories(Folder);
  Directions := Max(1, Length(ADirections));
  PerDirection := Max(1, Length(AFrames) div Directions);
  case AKind of
    skStrip:
      begin
        Result := TPath.Combine(Folder,
          Format('%s_strip%d.png', [AStem, PerDirection]));
        // One row per direction
        if Directions > 1 then
          SavePng(ComposeRows(Shown, PerDirection), Result)
        else
          SavePng(ComposeStrip(Shown), Result);
        if AMetadata then
          Result := Result + SaveMetadata(Result, PerDirection, Directions);
      end;
    skSheet:
      begin
        Result := TPath.Combine(Folder, AStem + '.png');
        SavePng(ComposeSheet(Shown, Cells), Result);
        if AMetadata then
          Result := Result + SaveMetadata(Result, Cells, Cells);
      end;
    skAtlas:
      // Made into pages as they fill, by SaveAtlasPages
      raise EInvalidOperation.Create('A texture atlas is saved by SaveAtlasPages.');
    skGif:
      begin
        // Each frame's share of the cycle, in hundredths of a second
        Result := TPath.Combine(Folder, AStem + '.gif');
        SaveAnimatedGif(Shown, Result,
          Max(1, Round(100 * ACycleSeconds / Max(1, Length(AFrames)))));
      end;
  else
    begin
      // H.264 when OpenH264 is present, otherwise MPEG-4 Part 2
      Result := TPath.Combine(Folder, AStem + '.mp4');
      Result := Result + ' (' + SaveMp4Video(Shown, Result, ACycleSeconds) + ')';
    end;
  end;
end;

end.
