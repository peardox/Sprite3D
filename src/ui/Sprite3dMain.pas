//** @abstract(Demo form for TSprite3DCamera: loads a model and drives the camera with dials.)
//**
//** The form has two tabs. The View tab holds a TGorillaViewport, created at run time, and a
//** panel of three dials for Azimuth, inclination and Roll. The Debug tab holds a memo for log
//** output. Below the Camera submenu, the View menu has five items that are ticked or not, each
//** switched by choosing it: Show bounding box shows the model's bounding box, Show grid a grid
//** on the model's floor, Show axes its own X, Y and Z axes through its centre of rotation, Fit
//** any angle chooses how the model is fitted, and Orthographic switches between perspective
//** and orthographic projection.
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
//** On show, the form loads the model the operating system asked it to open, as when a .glb or
//** .gltf file is double-clicked in Explorer or Finder, or else what the start-up action in
//** File, Settings asks for; files the system asks to open later replace it. File, OpenModel
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
//** Right-clicking an entry in the Animations list selects and plays it, and opens a pop-up menu
//** with Save as sprite strip, Save as Texture Atlas, Save as AniGif and Save as MP4 video. Each
//** grabs every frame of that animation off screen, from the first to the last, at the grab
//** size and with one framing that fits every frame, and saves them in SaveFolder: side by side
//** in one row as @code(<animation>_strip<frames>.png), in a square grid read left to right and
//** top to bottom as @code(<animation>.png), as a looping @code(<animation>.gif), or as a
//** video-only @code(<animation>.mp4) through Sprite3DVideo, H.264 when Cisco's OpenH264
//** library is present and MPEG-4 Part 2 otherwise. MP4 is offered only when
//** the FFmpeg libraries load; DebugMemo says at start-up whether they did and from where. The
//** @code(@(None@)) entry, which has no animation, captures instead one full turn of the model
//** in one second, at the File, Animation frame rate, named after the model with
//** @code(_rotate) added. On Android and iOS, which have no right-click, the same items are in
//** an Animation group of the menu drawer and act on the selected entry.
//**
//** At start-up the OpenH264 library, which makes MP4 files H.264, is taken from
//** @code(openh264.json): an address for each platform, from which a copy is downloaded in
//** the background into OpenH264Folder the first time, and again whenever the address changes.
//** An empty address, or a failed download, leaves MP4 files as MPEG-4 Part 2. DebugMemo says
//** which happened.
//**
//** File, Animation... sets the frame rate every saved animation uses, 30 frames a second
//** unless changed, from 1 to 60, kept in settings.json. Each animation is resampled to it:
//** one cycle is cut into the whole number of equal steps nearest that rate, so the saved
//** frames still loop exactly; see TSprite3DAnimationFrames.
//**
//** Each entry also has a tick box. Below the list, All ticks every animation, leaving
//** @code(@(None@)) as it is so the turn is exported only when ticked by hand, or clears every
//** entry; a drop-down chooses Sprite strip, Texture Atlas, AniGif or, when FFmpeg loaded, MP4
//** video, and Export saves every ticked entry that way, one after another, in a folder chosen in a folder dialog that opens at SaveFolder, so
//** a new sub-folder can be made there for the batch. SaveFolder itself is not changed. A
//** failed entry is reported at the end and does not stop the others. Each entry is unticked as
//** soon as it is saved, so a failed one stays ticked for another try. Abort, enabled only while
//** a batch runs, lets the entry being captured finish and save, then drops the rest. On
//** Android and iOS, which have no folder dialog, the batch goes to the Grabs folder.
//**
//** View, Camera, Lock Camera fixes the camera where it is. While it is ticked nothing moves or
//** turns the camera: the views, Orthographic, Fit any angle and the pan are switched off, a
//** new model or a resized view is not refitted, and grabs, icons and animation captures use
//** the view exactly as it stands instead of fitting the model to their own size. The
//** @code(@(None@)) turn cannot be captured while it is locked, as it turns the camera. The lock
//** is not kept between sessions.
//**
//** Each model replaces the last: it plays its last animation by name if it has any, is centred
//** and turned 180 degrees about X, and the camera is fitted so it fills the view. The model is
//** refitted when the viewport is resized, the projection changes or View, Fit any angle is
//** chosen, but not when a dial turns. Ticked, that item uses FitToBoundsMax, which frames the
//** model for every angle at once, so the dials can never push it out of view. Not ticked,
//** FitToBounds frames it exactly for the angles at the time of the fit, and turning a dial
//** afterwards can push part of it past the edge until the next refit.
//**
//** The form only handles the user interface. The 3D work is done by the library units in
//** @code(lib): Sprite3DCamera, Sprite3DAxes, Sprite3DGrid and Sprite3DOffscreen. The
//** application's other rules, such as where models are found, how a model is loaded and
//** placed, and how grabs are named and saved, are in Sprite3DHelpers.
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
//** |       |-- ViewportLayout   owns the TGorillaViewport
//** |       |   `-- DistanceLayout   test strip: DistanceLabel, DistanceTrack
//** |       `-- ControlsLayout   dials and their labels
//** `-- DebugTab "Debug"
//**     `-- DebugMemo
//**
//** MainMenu1
//** |-- FileMenu "File"
//** |   |-- OpenModelMenuItem "OpenModel"   shows OpenDialog1
//** |   |-- GrabMenuItem "Grab"             saves the off-screen view as grabNNN.png
//** |   |-- SaveAsIconMenuItem "Save As Icon"  saves the view as a Windows .ico file
//** |   |-- BackgroundSettingsMenuItem "Background Settings..."  opens the background dialog
//** |   |-- FAnimationSettingsItem "Animation..."  frame rate for saved animations
//** |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
//** |   `-- ExitMenuItem "Exit"             closes the application
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
//**     |-- FitAnyAngleItem "Fit any angle" FitToBoundsMax instead of FitToBounds
//**     `-- OrthographicItem "Orthographic" orthographic instead of perspective
//** )
unit Sprite3dMain;
{
  Demo form for TSprite3DCamera: loads a model and drives the camera with
  dials.

  The form has two tabs. The View tab holds a TGorillaViewport, created at run
  time, and a panel of three dials for Azimuth, inclination and Roll. The
  Debug tab holds a memo for log output. Below the Camera submenu, the View
  menu has five items that are ticked or not, each switched by choosing it:
  Show bounding box shows the model's bounding box, Show grid a grid on the
  model's floor, Show axes its own X, Y and Z axes through its centre of
  rotation, Fit any angle chooses how the model is fitted, and Orthographic
  switches between perspective and orthographic projection.

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

  On show, the form loads the model the operating system asked it to open, as
  when a .glb or .gltf file is double-clicked in Explorer or Finder, or else
  what the start-up action in File, Settings asks for; files the system asks
  to open later replace it. File, OpenModel then loads any other glTF, FBX,
  OBJ, USD, Collada, STL or PLY file, and File, Exit closes the application.
  File, Grab renders the view off screen at the grab size set in File,
  Settings, 256 by 256 pixels unless changed, with the model fitted to fill
  it, and saves it as the next of grab001.png, grab002.png and so on in
  SaveFolder, asking for that folder only when none is known: SaveFolder is
  kept between sessions in settings.json, through TSprite3DAppSettings in
  Sprite3DHelpers. File, Save As Icon renders the view off screen at each of
  Windows' icon sizes and saves them together as one .ico file the user names.
  Behind the model the viewport can show a background; by default none is
  drawn. File, Background Settings... chooses None, Transparent (a two-grey
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

  Right-clicking an entry in the Animations list selects and plays it, and
  opens a pop-up menu with Save as sprite strip, Save as Texture Atlas, Save
  as AniGif and Save as MP4 video. Each grabs every frame of that animation
  off screen, from the first to the last, at the grab size and with one
  framing that fits every frame, and saves them in SaveFolder: side by side
  in one row as <animation>_strip<frames>.png, in a square grid read left to
  right and top to bottom as <animation>.png, as a looping <animation>.gif,
  or as a video-only <animation>.mp4 through Sprite3DVideo, H.264 when
  Cisco's OpenH264 library is present and MPEG-4 Part 2 otherwise. MP4 is
  offered only when the FFmpeg libraries load; DebugMemo says at start-up
  whether they did and from where. The (None) entry, which has no animation,
  captures instead one full turn of the model in one second, at the File,
  Animation frame rate, named after the model with _rotate added. On Android
  and iOS, which have no right-click, the same items are in an Animation
  group of the menu drawer and act on the selected entry.

  At start-up the OpenH264 library, which makes MP4 files H.264, is taken
  from openh264.json: an address for each platform, from which a copy is
  downloaded in the background into OpenH264Folder the first time, and again
  whenever the address changes. An empty address, or a failed download,
  leaves MP4 files as MPEG-4 Part 2. DebugMemo says which happened.

  File, Animation... sets the frame rate every saved animation uses, 30
  frames a second unless changed, from 1 to 60, kept in settings.json. Each
  animation is resampled to it: one cycle is cut into the whole number of
  equal steps nearest that rate, so the saved frames still loop exactly; see
  TSprite3DAnimationFrames.

  Each entry also has a tick box. Below the list, All ticks every animation,
  leaving (None) as it is so the turn is exported only when ticked by hand,
  or clears every entry; a drop-down chooses Sprite strip, Texture Atlas,
  AniGif or, when FFmpeg loaded, MP4 video, and Export saves every ticked entry that way, one after another, in a folder
  chosen in a folder dialog that opens at SaveFolder, so a new sub-folder can
  be made there for the batch. SaveFolder itself is not changed. A failed
  entry is reported at the end and does not stop the others. Each entry is
  unticked as soon as it is saved, so a failed one stays ticked for another
  try. Abort, enabled only while a batch runs, lets the entry being captured
  finish and save, then drops the rest. On Android and iOS, which have no
  folder dialog, the batch goes to the Grabs folder.

  View, Camera, Lock Camera fixes the camera where it is. While it is ticked
  nothing moves or turns the camera: the views, Orthographic, Fit any angle
  and the pan are switched off, a new model or a resized view is not
  refitted, and grabs, icons and animation captures use the view exactly as
  it stands instead of fitting the model to their own size. The (None) turn
  cannot be captured while it is locked, as it turns the camera. The lock is
  not kept between sessions.

  Each model replaces the last: it plays its last animation by name if it has
  any, is centred and turned 180 degrees about X, and the camera is fitted so
  it fills the view. The model is refitted when the viewport is resized, the
  projection changes or View, Fit any angle is chosen, but not when a dial
  turns. Ticked, that item uses FitToBoundsMax, which frames the model for
  every angle at once, so the dials can never push it out of view. Not ticked,
  FitToBounds frames it exactly for the angles at the time of the fit, and
  turning a dial afterwards can push part of it past the edge until the next
  refit.

  The form only handles the user interface. The 3D work is done by the library
  units in lib: Sprite3DCamera, Sprite3DAxes, Sprite3DGrid and
  Sprite3DOffscreen. The application's other rules, such as where models are
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
    |       |-- ViewportLayout   owns the TGorillaViewport
    |       |   `-- DistanceLayout   test strip: DistanceLabel, DistanceTrack
    |       `-- ControlsLayout   dials and their labels
    `-- DebugTab "Debug"
        `-- DebugMemo

    MainMenu1
    |-- FileMenu "File"
    |   |-- OpenModelMenuItem "OpenModel"   shows OpenDialog1
    |   |-- GrabMenuItem "Grab"             saves the off-screen view as grabNNN.png
    |   |-- SaveAsIconMenuItem "Save As Icon"  saves the view as a Windows .ico file
    |   |-- BackgroundSettingsMenuItem "Background Settings..."  opens the background dialog
    |   |-- FAnimationSettingsItem "Animation..."  frame rate for saved animations
    |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
    |   `-- ExitMenuItem "Exit"             closes the application
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
        |-- FitAnyAngleItem "Fit any angle" FitToBoundsMax instead of FitToBounds
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
  Sprite3DSpriteSheet
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  , FMX.MultiView   // FMX.ListBox, also needed there, is listed above
  {$ENDIF}
  ;

type
  //** @abstract(What the animation list's pop-up menu saves a capture as.)
  /// <summary>What the animation list's pop-up menu saves a capture as.</summary>
  TSheetKind = (
    //** @abstract(One row of frames, saved as @code(<name>_strip<count>.png).)
    /// <summary>One row of frames, saved as <c>&lt;name&gt;_strip&lt;count&gt;.png</c>.</summary>
    skStrip,
    //** @abstract(A square grid of frames, saved as @code(<name>.png).)
    /// <summary>A square grid of frames, saved as <c>&lt;name&gt;.png</c>.</summary>
    skAtlas,
    //** @abstract(A looping animated GIF, saved as @code(<name>.gif).)
    /// <summary>A looping animated GIF, saved as <c>&lt;name&gt;.gif</c>.</summary>
    skGif,
    //** @abstract(A video-only MPEG-4 MP4, saved as @code(<name>.mp4); only offered when the
    //** FFmpeg libraries load.)
    /// <summary>A video-only MPEG-4 MP4, saved as <c>&lt;name&gt;.mp4</c>; only offered when
    /// the FFmpeg libraries load.</summary>
    skMp4);

  //** @abstract(The main form: a Gorilla3D view of one model, with dials for the camera.)
  //**
  //** The viewport, light, model and TSprite3DCamera are created at run time, not at design
  //** time; the form owns none of them directly. All event handlers run on the main thread.
  //**
  //** @seealso(TSprite3DCamera)
  /// <summary>The main form: a Gorilla3D view of one model, with dials for the camera.</summary>
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
    //** @abstract(The area left of the control panel; owns the TGorillaViewport made in
    //** FormCreate.)
    /// <summary>The area left of the control panel; owns the TGorillaViewport made in
    /// FormCreate.</summary>
    ViewportLayout: TLayout;
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
    //** @abstract(Asks for the model file that File, OpenModel loads.)
    //**
    //** Its filter, set in the form designer, offers only the formats the unit has loaders
    //** for: .glb, .gltf, .fbx, .obj, .usdc, .dae, .stl and .ply, all together first and then
    //** one at a time.
    /// <summary>Asks for the model file that File, OpenModel loads.</summary>
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
    //** @abstract(The "OpenModel" item; see OpenModelMenuItemClick.)
    /// <summary>The "OpenModel" item; see <see cref="OpenModelMenuItemClick"/>.</summary>
    OpenModelMenuItem: TMenuItem;
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
    //** bounds of its current pose, the box the camera fits. See ShowBoundsItemClick.
    /// <summary>Shows or hides the model's bounding box; ticked at start-up.</summary>
    /// <remarks>Ticked, every model is drawn with Gorilla's ShowBoundingBox, an orange box
    /// round the bounds of its current pose, the box the camera fits. See
    /// <see cref="ShowBoundsItemClick"/>.</remarks>
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
    //** @abstract(Chooses FitToBoundsMax over FitToBounds, so the model fits at every angle.)
    //**
    //** Ticked, the model is framed for every possible Azimuth, inclination and Roll, so
    //** turning the dials only moves the camera round it and the model always stays in view.
    //** Not ticked, the model is framed exactly for the angles at the time of the fit; turning
    //** a dial afterwards can push part of it past the edge until the next refit, which
    //** happens on a resize, a projection change or choosing this item.
    /// <summary>Chooses FitToBoundsMax over FitToBounds, so the model fits at every
    /// angle.</summary>
    /// <remarks>Ticked, the model is framed for every possible Azimuth, inclination and Roll,
    /// so turning the dials only moves the camera round it and the model always stays in view.
    /// Not ticked, the model is framed exactly for the angles at the time of the fit; turning
    /// a dial afterwards can push part of it past the edge until the next refit, which happens
    /// on a resize, a projection change or choosing this item.</remarks>
    FitAnyAngleItem: TMenuItem;
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
    //** @abstract(A dark strip above AnimationListBox that holds AnimationsLabel, so the
    //** title stands out whatever the theme.)
    /// <summary>A dark strip above AnimationListBox that holds AnimationsLabel, so the title
    /// stands out whatever the theme.</summary>
    AnimationsHeader: TRectangle;
    //** @abstract(The "Animations" title: bold yellow on AnimationsHeader.)
    /// <summary>The "Animations" title: bold yellow on AnimationsHeader.</summary>
    AnimationsLabel: TLabel;
    //** @abstract(The model's animations, by name, after a first entry, @code(@(None@)), that
    //** stops any animation; see AnimationListBoxClick.)
    //**
    //** Right-clicking an entry selects and plays it and opens a pop-up menu that saves it as a
    //** sprite strip, a texture atlas or an animated GIF; see the unit description.
    /// <summary>The model's animations, by name, after a first entry, <c>(None)</c>, that stops
    /// any animation; see <see cref="AnimationListBoxClick"/>.</summary>
    /// <remarks>Right-clicking an entry selects and plays it and opens a pop-up menu that saves
    /// it as a sprite strip, a texture atlas or an animated GIF; see the unit
    /// description.</remarks>
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
    //** TGorillaViewport owned by ViewportLayout, a TSprite3DCamera with a 45-degree FOV,
    //** which becomes the viewport's camera, and a point light parented to the camera at its
    //** origin, so it sits where the camera is and points where it looks. The viewport runs
    //** at a fixed 60 frames per second without VSync.
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
    /// creates a TGorillaViewport owned by ViewportLayout, a TSprite3DCamera with a 45-degree
    /// FOV, which becomes the viewport's camera, and a point light parented to the camera at
    /// its origin, so it sits where the camera is and points where it looks. The viewport
    /// runs at a fixed 60 frames per second without VSync.</para>
    /// <para>The dials start at 0, then the camera view kept in settings.json is chosen, as
    /// its View, Camera item would choose it: a fixed view turns the dials to its angles and
    /// switches them off, and Variable turns them to the angles kept with it and leaves them
    /// on. Isometric is chosen when none is kept. Last, the View menu's five on/off items are
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
    //** @abstract(Copies RollDial to the camera's Roll.)
    //**
    //** The dial value is wrapped into 0 to 360, without negating, shown in RollText and written
    //** to the camera. The model is not refitted; see FitAnyAngleItem.
    //**
    //** @param(Sender RollDial.)
    /// <summary>Copies RollDial to the camera's Roll.</summary>
    /// <remarks>The dial value is wrapped into 0 to 360, without negating, shown in RollText
    /// and written to the camera. The model is not refitted; see
    /// <see cref="FitAnyAngleItem"/>.</remarks>
    /// <param name="Sender">RollDial.</param>
    procedure RollDialChange(Sender: TObject);
    //** @abstract(Refits the camera to the model when the viewport changes size.)
    //**
    //** Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is loaded,
    //** or while View, Camera, Lock Camera is ticked.
    //**
    //** @param(Sender The TGorillaViewport.)
    /// <summary>Refits the camera to the model when the viewport changes size.</summary>
    /// <remarks>Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is
    /// loaded, or while View, Camera, Lock Camera is ticked.</remarks>
    /// <param name="Sender">The TGorillaViewport.</param>
    procedure GorillaViewportResize(Sender: TObject);
    //** @abstract(Ticks or unticks OrthographicItem, then switches the projection to match
    //** and refits the model.)
    //**
    //** Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in the form
    //** caption, and refits, since the two modes size the view differently. Does nothing while
    //** View, Camera, Lock Camera is ticked, when the item is disabled.
    //**
    //** @param(Sender OrthographicItem.)
    /// <summary>Ticks or unticks OrthographicItem, then switches the projection to match and
    /// refits the model.</summary>
    /// <remarks>Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in
    /// the form caption, and refits, since the two modes size the view differently. Does
    /// nothing while View, Camera, Lock Camera is ticked, when the item is disabled.</remarks>
    /// <param name="Sender">OrthographicItem.</param>
    procedure OrthographicItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks FitAnyAngleItem, then refits the model.)
    //**
    //** Does nothing while View, Camera, Lock Camera is ticked, when the item is disabled.
    //**
    //** @param(Sender FitAnyAngleItem.)
    /// <summary>Ticks or unticks FitAnyAngleItem, then refits the model.</summary>
    /// <remarks>Does nothing while View, Camera, Lock Camera is ticked, when the item is
    /// disabled.</remarks>
    /// <param name="Sender">FitAnyAngleItem.</param>
    procedure FitAnyAngleItemClick(Sender: TObject);
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
    //** Shows OpenDialog1 and passes the chosen file to SwitchModel, which clears the old model
    //** and loads the new one with the current camera angles and fit mode. Nothing changes if
    //** the dialog is cancelled. A file that fails to load is reported by SwitchModel, and the
    //** view is then left empty until another model loads.
    //**
    //** @param(Sender OpenModelMenuItem.)
    /// <summary>Lets the user pick a model file and loads it in place of the current
    /// one.</summary>
    /// <remarks>Shows OpenDialog1 and passes the chosen file to SwitchModel, which clears the old
    /// model and loads the new one with the current camera angles and fit mode. Nothing changes
    /// if the dialog is cancelled. A file that fails to load is reported by SwitchModel, and the
    /// view is then left empty until another model loads.</remarks>
    /// <param name="Sender">OpenModelMenuItem.</param>
    procedure OpenModelMenuItemClick(Sender: TObject);
    //** @abstract(Renders the view off screen and saves it as the next grabNNN.png.)
    //**
    //** If no usable SaveFolder is known, because none has been chosen yet or the stored one no
    //** longer exists, a "Save Location" folder dialog asks for it first, and SaveFolder is set
    //** to the choice and saved; if the dialog is cancelled nothing is grabbed. The image comes
    //** from Offscreen at its Width and Height, the grab size set in File, Settings, with the
    //** camera refitted by FitToBounds for that size so the model fills it, unless View, Camera,
    //** Lock Camera is ticked, when the view is grabbed as it stands, and is saved a
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
    /// previous grab is still under way is ignored.</remarks> <param
    /// name="Sender">GrabMenuItem.</param>
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
    //** OK, the chosen background is kept, used for grabs and icons, and saved to
    //** settings.json; Cancel puts back the background in use. On Android and iOS, where a dialog cannot block, it opens as an ordinary
    //** form and OK is applied when it closes.
    //**
    //** @param(Sender BackgroundSettingsMenuItem.)
    /// <summary>Opens the Background Settings dialog and applies what is chosen.</summary>
    /// <remarks>The dialog, TBackgroundSettingsForm, opens modally, centred on this form,
    /// showing the background in use. Every change is shown in the viewport at once. If it is
    /// closed with OK, the chosen background is kept, used for grabs and icons, and saved to
    /// settings.json; Cancel puts back the background in use. On Android and iOS, where a dialog cannot block, it opens as an ordinary form
    /// and OK is applied when it closes.</remarks>
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
    /// from the system. On OK the file associations are changed as chosen, the theme is
    /// applied at once, the GPU preference is stored for the next start, and everything is
    /// saved to settings.json; anything the user needs to know, such as a failure or the need
    /// to restart, is reported in a message. Cancel changes nothing. On Android and iOS, where a
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
    //** Ignored while an animation is being saved, which needs the animation it started.
    //**
    //** @param(Sender AnimationListBox.)
    /// <summary>Plays the chosen animation, or stops any for <c>(None)</c>.</summary>
    /// <remarks>Ignored while an animation is being saved, which needs the animation it
    /// started.</remarks>
    /// <param name="Sender">AnimationListBox.</param>
    procedure AnimationListBoxClick(Sender: TObject);
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
    // The viewport's background, fixed to the camera
    FBackground: TSprite3DBackground;
    FModelBox: TBoundingBox;   // the model's own bounds, measured as loaded
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
    // Texture Atlas, Save as AniGif
    FAnimationPopup: TPopupMenu;
    // File, Animation...: the frame rate saved animations use
    FAnimationSettingsItem: TMenuItem;
    // Keeps the downloaded OpenH264 in step with openh264.json
    FOpenH264Update: TSprite3DLibraryUpdate;
    // View, Camera, Lock Camera, and the line above it
    FLockCameraItem: TMenuItem;
    FLockSeparatorItem: TMenuItem;
    // True while a grab or a capture has its own framing on the camera,
    // which must be put back even if the camera is locked meanwhile
    FGrabFramed: Boolean;
    FCaptureFramed: Boolean;
    // The capture under way, or nil; it frees itself when it reports
    FCapture: TSprite3DFrameCapture;
    // The on-screen framing, put back when a capture ends
    FCaptureRestore: TSprite3DFraming;
    // The viewport was resized during the capture: refit when it ends
    FRefitAfterCapture: Boolean;
    // Batch export, below the animation list: All, what to save, Export
    FBatchLayout: TLayout;
    FBatchAll: TCheckBox;
    FBatchKindBox: TComboBox;
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
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure AnimationDialogAccept(Sender: TObject);
    {$ENDIF}
    procedure HookAnimationItems;
    procedure AnimationItemMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SaveStripItemClick(Sender: TObject);
    procedure SaveAtlasItemClick(Sender: TObject);
    procedure SaveGifItemClick(Sender: TObject);
    procedure SaveMp4ItemClick(Sender: TObject);
    procedure StartSingleCapture(const AKind: TSheetKind);
    function StartCapture(const AKind: TSheetKind; const AIndex: Integer;
      const AFolder: String; const AOnFinished: TProc<String>;
      out AError: String): Boolean;
    function Capturing: Boolean;
    procedure BuildBatchControls;
    procedure BatchAllChange(Sender: TObject);
    procedure AnimationListBoxChangeCheck(Sender: TObject);
    procedure ExportButtonClick(Sender: TObject);
    procedure AbortButtonClick(Sender: TObject);
    function ChooseExportFolder(out AFolder: String): Boolean;
    procedure RunNextBatchItem;
    procedure FinishBatch;
    procedure UpdateBatchControls;
    function FrameCaptureFraming(const ASource: TSprite3DFrameSource;
      const AWidth, AHeight: Integer): Boolean;
    procedure EndCapture;
    function SaveSheet(const AKind: TSheetKind; const AFrames: TArray<TSprite3DImage>;
      const AFolder, AStem: String; const ACycleSeconds: Double): String;
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
  FMX.Platform, System.IOUtils,
  Gorilla.DefTypes, Gorilla.Animation, System.Math,
  Sprite3DAxes, Sprite3DGrid, Sprite3DOpenFiles, Sprite3DBackgroundForm;

{$R *.fmx}

const
  // The first entry of AnimationListBox, which stops any animation and
  // shows the model as loaded
  NO_ANIMATION = '(None)';
  // What the (None) entry captures instead of an animation: one full turn
  // of the model in TURNTABLE_SECONDS, at the File, Animation frame rate
  TURNTABLE_SECONDS = 1.0;
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

  GorillaViewport := TGorillaViewport.Create(ViewportLayout);
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
  // Settings from earlier sessions; on the first run, the defaults
  FSettings := TSprite3DAppSettings.Create;
  FSettings.Load;
  FGrabNumber := 1;
  // Every grab from here on is this size, until File, Settings changes it
  FOffscreen.Width := FSettings.GrabWidth;
  FOffscreen.Height := FSettings.GrabHeight;
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
  // The background behind the model, as last chosen; the camera frees it
  FBackground := TSprite3DBackground.Create(nil);
  FBackground.AttachTo(GorillaCamera);
  ApplyBackground(FSettings.BackgroundSpec, False);
  // Fill the space the bottom test strip (DistanceLayout) leaves
  GorillaViewport.Align := TAlignLayout.Client;

  // The camera view as it was left last session; Isometric the first time
  RestoreCameraView;

  // The View menu's on/off items as they were left last session
  RestoreViewToggles;

  // The OpenH264 already downloaded, if it is the one openh264.json asks
  // for; before BuildAnimationMenu first loads the video libraries
  PrepareOpenH264;

  // The animation list's right-click menu; on mobile, also the drawer's
  // Animation group, so it must come before BuildMobileMenu
  BuildAnimationMenu;

  // Fetches OpenH264 in the background if it is missing or out of date
  StartOpenH264Update;
  // View, Camera, Lock Camera; before the menu is moved or mirrored
  BuildLockCameraItem;

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
// Dials do not refit: with "Fit any angle" off, turning one can push the
// model past the edge until the next refit; with it on, it never does.
procedure TMainForm.AnimationListBoxClick(Sender: TObject);
var
  ani: String;
begin
  if Capturing then
    Exit;   // a capture is driving the animation
  if Assigned(GorillaModel) then
    begin
      if AnimationListBox.ItemIndex > 0 then
        begin
          ani := AnimationListBox.Items[AnimationListBox.ItemIndex];
          GorillaModel.AnimationManager.PlayAnimation(ani);
        end
      else if AnimationListBox.ItemIndex = 0 then
        begin
          // Show base model
          if Assigned(GorillaModel.AnimationManager) and Assigned(GorillaModel.AnimationManager.Current) then
            GorillaModel.AnimationManager.Current.Stop();
        end;
    end;
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
procedure TMainForm.FormShow(Sender: TObject);
begin
  FSetupComplete := True;
  if FStarted then
    Exit;   // the form can be shown again; the model stays as it is
  FStarted := True;
  LoadStartupModel;
  FileOpenRequests.OnOpenFile := OpenRequestedFile;
end;

function TMainForm.DefaultModelFile: String;
const
  DEFAULT_MODEL = 'models/uvcube.glb';
//  DEFAULT_MODEL = 'models/TestAnimatedCharacter.glb';
//  DEFAULT_MODEL = 'models/TestStaticCharacter.glb';
begin
  Result := ModelDir + DEFAULT_MODEL;
end;

// A model the system asked to open, such as one double-clicked in Explorer
// or Finder, comes first; otherwise the start-up action decides. A last
// model that has gone since falls back to the default one.
procedure TMainForm.LoadStartupModel;
var
  FileName: String;
begin
  FileName := StartupModelFile(FileOpenRequests.TakePending, String.Empty);
  if FileName = String.Empty then
    case FSettings.StartupAction of
      saNone:
        DebugMemo.Lines.Add('Start-up action is None: no model loaded');
      saLastModel:
        if (FSettings.LastModel <> String.Empty) and FileExists(FSettings.LastModel) then
          FileName := FSettings.LastModel
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
  if IsModelFile(AFileName) then
    SwitchModel(AFileName)
  else
    ShowMessage('Not a model this application can open: ' + AFileName);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
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
end;

// Ticks the View menu's on/off items as settings.json says, then applies
// each, as choosing it would: the projection and caption, the fit, and the
// grid, axes and box, which SwitchModel also adds to each model as the items
// say. Before the first model is loaded, those find no model and do nothing.
procedure TMainForm.RestoreViewToggles;
begin
  ShowBoundsItem.IsChecked := FSettings.ShowBoundingBox;
  ShowGridItem.IsChecked := FSettings.ShowGrid;
  ShowAxesItem.IsChecked := FSettings.ShowAxes;
  FitAnyAngleItem.IsChecked := FSettings.FitAnyAngle;
  OrthographicItem.IsChecked := FSettings.Orthographic;
  ApplyShowBounds;
  ApplyShowGrid;
  ApplyShowAxes;
  ApplyProjection;   // refits too, for FitAnyAngleItem
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
  FSettings.FitAnyAngle := FitAnyAngleItem.IsChecked;
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

// Fit the model to the grab's own shape, as large as it will go for the
// current angles (FitToBounds, whatever "Fit any angle" says, and without
// the test distance factor), keeping the on-screen framing to put back
procedure TMainForm.OffscreenBeforeGrab(Sender: TObject;
  const AWidth, AHeight: Integer);
begin
  // Grabs add their own backdrop after matting; the viewport's would make
  // every pixel opaque
  FBackground.Hidden := True;
  // The capture framed the camera once for every frame, and a locked camera
  // is grabbed exactly as it stands
  FGrabFramed := False;
  if Assigned(FCapture) or CameraLocked then
    Exit;
  FSavedFraming := GorillaCamera.SaveFraming;
  FGrabFramed := True;
  if Assigned(GorillaModel) and
    GorillaCamera.FitToBounds(GorillaModel, AWidth, AHeight) and FPanEnabled then
    // The pan as on screen, on top of the grab's own fit
    GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point +
      ModelPanOffset(GorillaModel, FModelBox, FPanX, FPanZ);
end;

// Put the on-screen framing back before the main pass draws
procedure TMainForm.OffscreenAfterGrab(Sender: TObject);
begin
  FBackground.Hidden := False;
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
  Dialog.Values := FSettingsBefore;
  // ShowModal cannot block here: the dialog reports OK and frees itself
  Dialog.OnAccept := SettingsDialogAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    Before := ReadGeneralSettings(FSettings);
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
      DebugMemo.Lines.Add(Format('Grabs are now %d x %d pixels',
        [FSettings.GrabWidth, FSettings.GrabHeight]));
    end;

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

// Refit after a change of model, size, projection or fit mode. The dials do
// not call this: FitToBoundsMax already allows for every angle, and with
// FitToBounds a dial turn is allowed to push the model past the edge.
function TMainForm.FitModel: Boolean;
begin
  Result := not CameraLocked and Assigned(GorillaCamera) and Assigned(GorillaModel);
  if not Result then
    Exit;
  if FitAnyAngleItem.IsChecked then
    Result := GorillaCamera.FitToBoundsMax(GorillaModel)
  else
    Result := GorillaCamera.FitToBounds(GorillaModel);
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

procedure TMainForm.FitAnyAngleItemClick(Sender: TObject);
begin
  if CameraLocked then
    Exit;   // it only chooses how the camera is fitted
  FitAnyAngleItem.IsChecked := not FitAnyAngleItem.IsChecked;
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

// Load a Model Clearing any old model first (so it Switches them)
// GorillaModel will be Nil on first call but set on subsequent calls
procedure TMainForm.SwitchModel(const AModel: String);
var
  BBox: TBoundingBox;
  Anims: TArray<String>;
begin
  if (AModel = String.Empty) or (not FileExists(AModel)) then
    begin
      ShowMessage('Model Not Found ' + AModel);
      Exit;
    end;
  if Capturing then
    begin
      ShowMessage('An animation is being saved; open the model again when it is done.');
      Exit;
    end;

  if GorillaModel = Nil then
    begin
      GorillaModel := TGorillaModel.Create(GorillaViewport);
      GorillaModel.Parent := GorillaViewport;
    end;

  AnimationListBox.Items.Clear;
  AnimationListBox.Items.Add(NO_ANIMATION);
  try
    Anims := LoadModelFile(GorillaModel, AModel, BBox);
    // The model's own bounds, before any helper is added: the grid's floor
    FModelBox := BBox;
    if Length(Anims) > 0 then
      begin
        for var AnimName in Anims do
        begin
          AnimationListBox.Items.Add(AnimName);
        end;
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

    // The angles as the dials have them, unless the camera is locked
    ApplyAngles;

    // Draw the box that FitToBounds and FitToBoundsMax fit, if wanted: the
    // bounds of the current pose, in Gorilla's default orange
    GorillaModel.ShowBoundingBox := ShowBoundsItem.IsChecked;
    // Axes through the centre of rotation, sized for the newly loaded model
    if ShowAxesItem.IsChecked then
      ShowModelAxes(GorillaModel);
    PlaceModel(GorillaModel, BBox);

    // Floor grid, after the model is placed and turned, because the floor
    // depends on which way up it is
    if ShowGridItem.IsChecked then
      ShowModelGrid(GorillaModel, FModelBox);

    // A locked camera stays where it is, whatever the new model's size
    if not CameraLocked and not FitModel then
      Caption := 'Problem fitting Camera'
    else
      Caption := ProjectionCaption;

    // For the "Load last model" start-up action; saved with the view state
    FSettings.LastModel := ExpandFileName(AModel);

  except
    on E : Exception do
      begin
        ShowMessage('Can''t Load Model : ' + AModel + sLineBreak +
                    'Exception class name : '+ E.ClassName   + sLineBreak +
                    'Exception message : ' + E.Message);
        FreeAndNil(GorillaModel);
      end;
  end;
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
  AddItem(FAnimationPopup, 'Save as Texture Atlas', SaveAtlasItemClick);
  AddItem(FAnimationPopup, 'Save as AniGif', SaveGifItemClick);
  // MP4 needs the FFmpeg libraries: offered only if they load
  AddItem(FAnimationPopup, 'Save as MP4 video', SaveMp4ItemClick).Enabled := VideoAvailable;
  DebugMemo.Lines.Add(VideoStatus);
  BuildBatchControls;

  // File, Animation..., just above Settings...
  FAnimationSettingsItem := TMenuItem.Create(Self);
  FAnimationSettingsItem.Text := 'Animation...';
  FAnimationSettingsItem.OnClick := AnimationSettingsItemClick;
  FileMenu.InsertObject(SettingsMenuItem.Index, FAnimationSettingsItem);
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  FAnimationMenu := TMenuItem.Create(Self);
  FAnimationMenu.Text := 'Animation';
  MainMenu1.AddObject(FAnimationMenu);
  AddItem(FAnimationMenu, 'Save as sprite strip', SaveStripItemClick);
  AddItem(FAnimationMenu, 'Save as Texture Atlas', SaveAtlasItemClick);
  AddItem(FAnimationMenu, 'Save as AniGif', SaveGifItemClick);
  if VideoAvailable then
    AddItem(FAnimationMenu, 'Save as MP4 video', SaveMp4ItemClick);
  {$ENDIF}
end;

// File, Animation...: the frame rate saved animations use. OK keeps the
// new rate and saves it; Cancel leaves the old one.
procedure TMainForm.AnimationSettingsItemClick(Sender: TObject);
var
  Dialog: TAnimationSettingsForm;
begin
  Dialog := TAnimationSettingsForm.Create(nil);
  Dialog.Fps := FSettings.AnimationFps;
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // ShowModal cannot block here: the dialog reports OK and frees itself
  Dialog.OnAccept := AnimationDialogAccept;
  Dialog.ShowAndFree;
  {$ELSE}
  try
    if Dialog.ShowModal = mrOk then
      ApplyAnimationFps(Dialog.Fps);
  finally
    Dialog.Free;
  end;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
procedure TMainForm.AnimationDialogAccept(Sender: TObject);
begin
  ApplyAnimationFps(TAnimationSettingsForm(Sender).Fps);
end;
{$ENDIF}

// Keeps the frame rate and writes settings.json straight away
procedure TMainForm.ApplyAnimationFps(const AFps: Integer);
begin
  if AFps = FSettings.AnimationFps then
    Exit;
  FSettings.AnimationFps := AFps;   // limited to the allowed range
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
  FitAnyAngleItem.Enabled := not Locked;
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
    AnimationListBox.ListItems[I].OnMouseUp := AnimationItemMouseUp;
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

procedure TMainForm.SaveAtlasItemClick(Sender: TObject);
begin
  StartSingleCapture(skAtlas);
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
  if not StartCapture(AKind, Max(0, AnimationListBox.ItemIndex), SaveFolder,
    procedure(AResult: String)
    begin
      if AResult <> String.Empty then
        ShowMessage(AResult);
    end, Error) then
    ShowMessage(Error);
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
function TMainForm.StartCapture(const AKind: TSheetKind; const AIndex: Integer;
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
begin
  Result := False;
  AError := String.Empty;
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
  if (AKind = skMp4) and not VideoAvailable then
  begin
    AError := 'MP4 video is not available: ' + VideoStatus;
    Exit;
  end;

  if (AIndex = 0) and CameraLocked then
  begin
    AError := 'The (None) turn turns the camera, which is locked. Untick View, Camera, ' +
      'Lock Camera to capture it.';
    Exit;
  end;

  if AIndex = 0 then
  begin
    // No animation: one turn of the model, named after the model
    Stem := SafeFileStem(TPath.GetFileNameWithoutExtension(FSettings.LastModel) +
      '_rotate');
    Source := TSprite3DTurntableFrames.Create(GorillaCamera,
      Max(1, Round(FSettings.AnimationFps * TURNTABLE_SECONDS)), TURNTABLE_SECONDS);
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
    Source := TSprite3DAnimationFrames.Create(GorillaModel, Anim, FSettings.AnimationFps);
  end;

  Count := Source.FrameCount;
  CycleSeconds := Source.Duration;
  // The frames, and the strip or atlas made from them
  Bytes := Int64(Count) * FOffscreen.Width * FOffscreen.Height * 4 * 2;
  if Bytes > MAX_CAPTURE_BYTES then
  begin
    Source.Free;
    AError := Format('%s: %d frames of %d x %d pixels need more memory than a ' +
      'capture may use. Choose a smaller grab size in File, Settings.',
      [Stem, Count, FOffscreen.Width, FOffscreen.Height]);
    Exit;
  end;

  // One framing for every frame, from here until EndCapture; a locked
  // camera is captured exactly as it stands
  FRefitAfterCapture := False;
  FCaptureFramed := not CameraLocked;
  if FCaptureFramed then
    FCaptureRestore := GorillaCamera.SaveFraming;
  Source.Start;
  if FCaptureFramed and
    not FrameCaptureFraming(Source, FOffscreen.Width, FOffscreen.Height) then
    DebugMemo.Lines.Add('Could not frame the capture; using the view as it is');

  // Locals, not parameters, for the procedures below to capture
  Kind := AKind;
  Folder := AFolder;
  OnFinished := AOnFinished;
  Capture := TSprite3DFrameCapture.Create(FOffscreen, Source,
    procedure(const AFrames: TArray<TSprite3DImage>; const ACaptureError: String)
    var
      Outcome, FileName: String;
    begin
      FCapture := nil;
      EndCapture;
      UpdateBatchControls;
      Outcome := String.Empty;
      if ACaptureError <> String.Empty then
        Outcome := Stem + ': capture failed: ' + ACaptureError
      else
        try
          FileName := SaveSheet(Kind, AFrames, Folder, Stem, CycleSeconds);
          DebugMemo.Lines.Add(Format('Saved %s (%d frames)', [FileName, Length(AFrames)]));
        except
          on E: Exception do
            Outcome := 'Can''t save ' + Stem + ' in ' + Folder + sLineBreak + E.Message;
        end;
      if Outcome <> String.Empty then
        DebugMemo.Lines.Add(Outcome);
      if Assigned(OnFinished) then
        OnFinished(Outcome);
    end,
    procedure(const ADone, ATotal: Integer)
    begin
      Caption := Format('Capturing %s: frame %d of %d', [Stem, ADone, ATotal]);
    end);
  Capture.SourceStarted;
  FCapture := Capture;
  UpdateBatchControls;
  DebugMemo.Lines.Add(Format('Capturing %s: %d frames of %d x %d',
    [Stem, Count, FOffscreen.Width, FOffscreen.Height]));
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
  FBatchLayout.Height := 64;
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
  FBatchKindBox.Items.Add('Texture Atlas');
  FBatchKindBox.Items.Add('AniGif');
  if VideoAvailable then
    FBatchKindBox.Items.Add('MP4 video');
  FBatchKindBox.ItemIndex := Ord(skStrip);

  // Second row: Export, and Abort beside it
  Row := TLayout.Create(Self);
  Row.Parent := FBatchLayout;
  Row.Align := TAlignLayout.Top;
  Row.Margins.Top := 4;
  Row.Height := 26;
  Row.Position.Y := 100;   // below the first row

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

// All ticks every animation, or clears every entry. (None), entry 0, is not
// an animation, so ticking All leaves it as it is; it is only exported when
// ticked by hand. Clearing All clears it too.
procedure TMainForm.BatchAllChange(Sender: TObject);
var
  I: Integer;
begin
  if FSyncingChecks then
    Exit;
  FSyncingChecks := True;
  try
    for I := 0 to AnimationListBox.Count - 1 do
      if (I > 0) or not FBatchAll.IsChecked then
        AnimationListBox.ListItems[I].IsChecked := FBatchAll.IsChecked;
  finally
    FSyncingChecks := False;
  end;
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
end;

// Export is offered only when there is a model and nothing is being saved
procedure TMainForm.UpdateBatchControls;
begin
  if FExportButton = nil then
    Exit;
  FExportButton.Enabled := not Capturing;
  FBatchKindBox.Enabled := not Capturing;
  FBatchAll.Enabled := not Capturing;
  FAbortButton.Enabled := FBatchActive and not FBatchAborted;
  // The lock cannot change while a capture has its own framing on the camera
  UpdateCameraLockControls;
  if FBatchActive and FBatchAborted then
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
  if not ChooseExportFolder(Folder) then
    Exit;   // cancelled

  FBatchItems := Items;
  FBatchPos := 0;
  FBatchKind := TSheetKind(EnsureRange(FBatchKindBox.ItemIndex, Ord(Low(TSheetKind)),
    Ord(High(TSheetKind))));
  FBatchFolder := Folder;
  FBatchSaved := 0;
  FBatchErrors := nil;
  FBatchAborted := False;
  FBatchActive := True;
  UpdateBatchControls;
  DebugMemo.Lines.Add(Format('Exporting %d animations as %s to %s',
    [Length(Items), FBatchKindBox.Items[Ord(FBatchKind)], Folder]));
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
  while not Started and not FBatchAborted and (FBatchPos <= High(FBatchItems)) do
  begin
    Started := StartCapture(FBatchKind, FBatchItems[FBatchPos], FBatchFolder,
      procedure(AResult: String)
      var
        Entry: Integer;
      begin
        if AResult = String.Empty then
        begin
          Inc(FBatchSaved);
          // Done: untick it, and let All follow
          Entry := FBatchItems[FBatchPos];
          if Entry < AnimationListBox.Count then
            AnimationListBox.ListItems[Entry].IsChecked := False;
          AnimationListBoxChangeCheck(AnimationListBox);
        end
        else
          FBatchErrors := FBatchErrors + [AResult];
        Inc(FBatchPos);
        TThread.ForceQueue(nil,
          procedure
          begin
            if FBatchActive then   // cleared if the form is closing
              RunNextBatchItem;
          end);
      end, Error);
    if not Started then
    begin
      FBatchErrors := FBatchErrors + [Error];
      DebugMemo.Lines.Add(Error);
      Inc(FBatchPos);
    end;
  end;
  if not Started then
    FinishBatch;
end;

// Reports the batch and gives the list back its own animation
procedure TMainForm.FinishBatch;
var
  Report: String;
begin
  FBatchActive := False;
  UpdateBatchControls;
  // The batch left its last animation playing; play the selected one again
  AnimationListBoxClick(AnimationListBox);
  Report := Format('Exported %d of %d animations to %s',
    [FBatchSaved, Length(FBatchItems), FBatchFolder]);
  if FBatchAborted then
    Report := Report + sLineBreak + Format('Aborted: %d not exported',
      [Length(FBatchItems) - FBatchPos]);
  DebugMemo.Lines.Add(Report);
  if Length(FBatchErrors) > 0 then
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
// AWidth x AHeight, with the pan on top as for every fit. A turn is fitted
// for every angle about the model's centre of rotation, so no frame of the
// turn can leave the target. An animation is fitted, at the current angles,
// to the union of its frames' boxes, so the widest pose still fits; the
// source must already be started.
function TMainForm.FrameCaptureFraming(const ASource: TSprite3DFrameSource;
  const AWidth, AHeight: Integer): Boolean;
var
  I: Integer;
  Box, Union: TBoundingBox;
begin
  if ASource is TSprite3DTurntableFrames then
    Result := GorillaCamera.FitToBoundsMax(GorillaModel, AWidth, AHeight)
  else
  begin
    for I := 0 to ASource.FrameCount - 1 do
    begin
      ASource.ShowFrame(I);
      Box := GorillaModel.GetAnimatedBoundingBox();
      if I = 0 then
        Union := Box
      else
      begin
        Union.TopLeftNear := Point3D(
          Min(Union.TopLeftNear.X, Min(Box.TopLeftNear.X, Box.BottomRightFar.X)),
          Min(Union.TopLeftNear.Y, Min(Box.TopLeftNear.Y, Box.BottomRightFar.Y)),
          Min(Union.TopLeftNear.Z, Min(Box.TopLeftNear.Z, Box.BottomRightFar.Z)));
        Union.BottomRightFar := Point3D(
          Max(Union.BottomRightFar.X, Max(Box.TopLeftNear.X, Box.BottomRightFar.X)),
          Max(Union.BottomRightFar.Y, Max(Box.TopLeftNear.Y, Box.BottomRightFar.Y)),
          Max(Union.BottomRightFar.Z, Max(Box.TopLeftNear.Z, Box.BottomRightFar.Z)));
      end;
    end;
    Result := GorillaCamera.FitToBounds(Union, GorillaModel, AWidth, AHeight);
  end;
  if Result and FPanEnabled then
    GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point +
      ModelPanOffset(GorillaModel, FModelBox, FPanX, FPanZ);
end;

// The on-screen view as it was before the capture, refitted if the
// viewport changed size meanwhile
procedure TMainForm.EndCapture;
begin
  // Only a framing the capture set is put back
  if FCaptureFramed then
    GorillaCamera.RestoreFraming(FCaptureRestore);
  FCaptureFramed := False;
  ApplyAngles;
  if FRefitAfterCapture then
    FitModel;
  FRefitAfterCapture := False;
  Caption := ProjectionCaption;
end;

// Lays out and writes the captured frames in AFolder, creating it if need
// be; names follow the pop-up menu's rules, and an existing file of the same
// name is replaced. Returns the file written, with the codec in brackets
// for an MP4, for the log; raises if it cannot be written.
function TMainForm.SaveSheet(const AKind: TSheetKind;
  const AFrames: TArray<TSprite3DImage>; const AFolder, AStem: String;
  const ACycleSeconds: Double): String;
var
  Cells: Integer;
begin
  ForceDirectories(AFolder);
  case AKind of
    skStrip:
      begin
        Result := TPath.Combine(AFolder,
          Format('%s_strip%d.png', [AStem, Length(AFrames)]));
        SavePng(ComposeStrip(AFrames), Result);
      end;
    skAtlas:
      begin
        Result := TPath.Combine(AFolder, AStem + '.png');
        SavePng(ComposeAtlas(AFrames, Cells), Result);
      end;
    skGif:
      begin
        // Each frame's share of the cycle, in hundredths of a second
        Result := TPath.Combine(AFolder, AStem + '.gif');
        SaveAnimatedGif(AFrames, Result,
          Max(1, Round(100 * ACycleSeconds / Max(1, Length(AFrames)))));
      end;
  else
    begin
      // H.264 when OpenH264 is present, otherwise MPEG-4 Part 2
      Result := TPath.Combine(AFolder, AStem + '.mp4');
      Result := Result + ' (' + SaveMp4Video(AFrames, Result, ACycleSeconds) + ')';
    end;
  end;
end;

end.
