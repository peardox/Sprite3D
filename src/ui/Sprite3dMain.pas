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
//** Camera, Pixel 2:1 does the same with an inclination of about 26.565; View, Camera, 3/4 View
//** uses 45 degrees through the orthographic camera; View, Camera, Head On and View, Camera,
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
//** |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
//** |   `-- ExitMenuItem "Exit"             closes the application
//** `-- ViewMenu "View"                   its ticks are kept in settings.json
//**     |-- CameraMenu "Camera"             the view, kept in settings.json
//**     |   |-- ViewVariableItem "Variable"     dials set the angles; also the pan
//**     |   |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
//**     |   |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
//**     |   |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45, orthographic
//**     |   |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
//**     |   |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
//**     |   `-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
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
  3/4 View uses 45 degrees through the orthographic camera; View, Camera, Head
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
    |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
    |   `-- ExitMenuItem "Exit"             closes the application
    `-- ViewMenu "View"                   its ticks are kept in settings.json
        |-- CameraMenu "Camera"             the view, kept in settings.json
        |   |-- ViewVariableItem "Variable"     dials set the angles; also the pan
        |   |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
        |   |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
        |   |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45, orthographic
        |   |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
        |   |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
        |   `-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
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
  Sprite3DOrbitalForm, Sprite3DSettingsForm, FMX.ListBox
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  , FMX.MultiView   // FMX.ListBox, also needed there, is listed above
  {$ENDIF}
  ;

type
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
    /// <summary>The model's animations, by name, after a first entry, <c>(None)</c>, that stops
    /// any animation; see <see cref="AnimationListBoxClick"/>.</summary>
    AnimationListBox: TListBox;
    ViewOneQuarterItem: TMenuItem;
    ViewRoot2Item: TMenuItem;
    ViewGoldenRatioItem: TMenuItem;
    CameraSeparatorItem1: TMenuItem;
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
    //** Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is loaded.
    //**
    //** @param(Sender The TGorillaViewport.)
    /// <summary>Refits the camera to the model when the viewport changes size.</summary>
    /// <remarks>Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is
    /// loaded.</remarks>
    /// <param name="Sender">The TGorillaViewport.</param>
    procedure GorillaViewportResize(Sender: TObject);
    //** @abstract(Ticks or unticks OrthographicItem, then switches the projection to match
    //** and refits the model.)
    //**
    //** Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in the form
    //** caption, and refits, since the two modes size the view differently.
    //**
    //** @param(Sender OrthographicItem.)
    /// <summary>Ticks or unticks OrthographicItem, then switches the projection to match and
    /// refits the model.</summary>
    /// <remarks>Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in
    /// the form caption, and refits, since the two modes size the view
    /// differently.</remarks>
    /// <param name="Sender">OrthographicItem.</param>
    procedure OrthographicItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks FitAnyAngleItem, then refits the model.)
    //**
    //** @param(Sender FitAnyAngleItem.)
    /// <summary>Ticks or unticks FitAnyAngleItem, then refits the model.</summary>
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
    //** camera refitted by FitToBounds for that size so the model fills it, and is saved a
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
    /// it, and is saved a frame later as grab001.png, grab002.png and so on: the number starts
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
    //** @abstract(Sets the 3/4 view, through the orthographic camera, and fixes it.)
    //**
    //** The angle of military projection: inclination 45 degrees at azimuth 45. It also ticks
    //** OrthographicItem, switching the camera to orthographic, which gives the flat look of
    //** 3/4-view game art. Other views leave the projection as it is.
    //**
    //** @param(Sender ViewThreeQuarterItem.)
    /// <summary>Sets the 3/4 view, through the orthographic camera, and fixes it.</summary>
    /// <remarks>The angle of military projection: inclination 45 degrees at azimuth 45. It also
    /// ticks OrthographicItem, switching the camera to orthographic, which gives the flat look of
    /// 3/4-view game art. Other views leave the projection as it is.</remarks>
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
    procedure AnimationListBoxClick(Sender: TObject);
    procedure ViewOneQuarterItemClick(Sender: TObject);
    procedure ViewRoot2ItemClick(Sender: TObject);
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
  FMX.Platform,
  Gorilla.DefTypes, System.Math,
  Sprite3DAxes, Sprite3DGrid, Sprite3DOpenFiles, Sprite3DBackgroundForm;

{$R *.fmx}

const
  // The first entry of AnimationListBox, which stops any animation and
  // shows the model as loaded
  NO_ANIMATION = '(None)';

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
  if Assigned(GorillaCamera) then
  begin
    GorillaCamera.Azimuth := Wrap360(-FAzimuth);
    GorillaCamera.PolarAngle := FPolarAngle;
    GorillaCamera.Roll := Wrap360(-FRoll);   // reversed, as is Azimuth
  end;
end;

procedure TMainForm.OrthographicItemClick(Sender: TObject);
begin
  OrthographicItem.IsChecked := not OrthographicItem.IsChecked;
  ApplyProjection;
end;

// The projection and caption to match OrthographicItem, then a refit, as
// the two modes size the view differently
procedure TMainForm.ApplyProjection;
begin
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
    if SameText(CameraViewKey(CameraMenu.Items[I]), AKey) then
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
    if CameraMenu.Items[I].IsChecked then
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
  FitModel;
end;

procedure TMainForm.OpenModelMenuItemClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    SwitchModel(OpenDialog1.Filename);
end;

procedure TMainForm.GrabMenuItemClick(Sender: TObject);
begin
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
  FSavedFraming := GorillaCamera.SaveFraming;
  if Assigned(GorillaModel) and
    GorillaCamera.FitToBounds(GorillaModel, AWidth, AHeight) and FPanEnabled then
    // The pan as on screen, on top of the grab's own fit
    GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point +
      ModelPanOffset(GorillaModel, FModelBox, FPanX, FPanZ);
  // Grabs add their own backdrop after matting; the viewport's would make
  // every pixel opaque
  FBackground.Hidden := True;
end;

// Put the on-screen framing back before the main pass draws
procedure TMainForm.OffscreenAfterGrab(Sender: TObject);
begin
  GorillaCamera.RestoreFraming(FSavedFraming);
  FBackground.Hidden := False;
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
    CameraMenu.Items[I].IsChecked := False;
end;

// The pattern for every fixed view: clear all the checks, set the view,
// then check the item that chose it
procedure TMainForm.SelectFixedView(const AItem: TMenuItem;
  const APolarAngle, AAzimuth: Single);
begin
  ClearViewChecks;
  SetPolarViewAngle(APolarAngle, AAzimuth);
  AItem.IsChecked := True;
end;

procedure TMainForm.ViewVariableItemClick(Sender: TObject);
var
  Dialog: TOrbitalSettingsForm;
begin
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
  if not Assigned(GorillaCamera) then
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
  Result := Assigned(GorillaCamera) and Assigned(GorillaModel);
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
  if not Assigned(GorillaCamera) or (FFitDistance <= 0) then
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
  if not Assigned(GorillaCamera) or not FFitted then
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

    GorillaCamera.Roll := Wrap360(-FRoll);   // reversed, as is Azimuth
    GorillaCamera.Azimuth := Wrap360(-FAzimuth);
    GorillaCamera.PolarAngle := FPolarAngle;

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

    if not FitModel then
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


end.
