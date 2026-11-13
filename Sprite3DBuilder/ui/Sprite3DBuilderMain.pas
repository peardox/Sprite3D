//** @abstract(Sprite3DBuilder's main form: an empty level to build in, a floor grid in a
//** Gorilla3D view, with the camera driven by View, Camera and the mouse.)
//**
//** The form has two tabs. The Level tab holds the TGorillaViewport, created at run time, with
//** the level in it: FLevel, an empty root for the pieces to come, and its floor grid, at the
//** spacing kept in settings.json @(2 units at first, a floor tile of the dungeon kit@). The
//** Debug tab holds a memo for log output, and is always there.
//**
//** File, Library opens the Library, TAssetsForm: the user's collections of models, each
//** arranged in groups, from which pieces will be placed. At start it opens by itself if
//** there are any.
//**
//** The camera starts in the isometric view, fitted to the middle of the floor. View, Camera,
//** Variable lets the dials of the Variable camera dialog set the angles, the distance, the
//** shift and the rise; the fixed views set their own angles. Lock Camera fixes the camera
//** where it is, and Mouse View lets the mouse turn and zoom the view. View, Projection
//** chooses perspective, orthographic or one of four oblique projections drawn by the Spritely
//** package's TSpritelyProjection. View, Show bounding box will box each piece placed.
//**
//** On Android and iOS FMX shows no main menu, so MainMenu1 is offered through a hamburger
//** button on a toolbar at the top, which opens a drawer listing every item in MainMenu1; Open
//** Asset Folder is left out there, as there is no folder dialog. On Linux MainMenu1 is
//** replaced, first thing in FormCreate, by a TMenuBar that FMX draws itself, as the native
//** GTK menu bar showed only the first letter of each item; the items must be copied, not
//** moved; see UseFmxMenuBar.
//**
//** @preformatted(
//** TabControl1
//** |-- LevelTab "Level"
//** |   `-- MainLayout
//** |       `-- ViewportLayout
//** |           `-- AspectLayout   dark grey; the TGorillaViewport fills it
//** |               `-- @(the TGorillaViewport, made in code@)
//** |                   `-- FLevel   the level's root, turned so Y is up
//** |                       `-- FGrid   the floor grid
//** `-- DebugTab "Debug"
//**     `-- DebugMemo
//**
//** MainMenu1
//** |-- FileMenu "File"
//** |   |-- LibraryItem "Library..."   the collections of models; desktop only
//** |   |-- ClearLibraryItem "Clear Library..."  deletes the library; desktop only
//** |   |-- CheckThumbnailsItem "Check Thumbnails"  reports empty thumbnails; desktop only
//** |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
//** |   |-- FRotationSnapItem "Rotation Snap..."  the step Rotate and Bend turn by; made in
//** |   |                                code with the palette, desktop only
//** |   |-- LicencesMenuItem "Licences..."  the third-party licences, from the program's resources
//** |   |-- FileSeparatorItem "-"
//** |   `-- ExitMenuItem "Exit"             closes the application
//** |-- FEditMenu "Edit"                  made in code with the history, desktop only
//** |   |-- FUndoItem "Undo"                Ctrl+Z: takes out the last addition
//** |   |-- "-"
//** |   `-- FResetLevelItem "Reset Level..."  asks, then empties the level
//** `-- ViewMenu "View"                   its ticks are kept in settings.json
//**     |-- CameraMenu "Camera"             the view, kept in settings.json
//**     |   |-- ViewVariableItem "Variable"     dials set the angles; also shift and rise
//**     |   |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
//**     |   |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
//**     |   |-- ViewOneQuarterItem "1/4 View"   fixed, inclination 22.5
//**     |   |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45
//**     |   |-- ViewRoot2Item "Sqrt@(2@)"         fixed, inclination about 54.736
//**     |   |-- ViewGoldenRatioItem "Golden Ratio" fixed, inclination about 58.283
//**     |   |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
//**     |   |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
//**     |   |-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
//**     |   |-- FLockSeparatorItem "-"
//**     |   |-- FLockCameraItem "Lock Camera"   fixes the camera; not a view
//**     |   `-- FMouseViewItem "Mouse View"     the mouse turns and zooms the view
//**     |-- LightsMenu "Lights"
//**     |   |-- HeadlightItem "Headlight"   OrbitCamera's light; ticked at start-up
//**     |   `-- OriginalLightItem "Original Light"  a second light on the camera
//**     |-- ProjectionMenu "Projection"      one of six, a radio group
//**     |   |-- PerspectiveItem "Perspective"   the camera's own; at start-up
//**     |   |-- OrthographicItem "Orthographic" the camera's own
//**     |   `-- ObliqueMenu "Oblique"        drawn by TSpritelyProjection, same radio group
//**     |       |-- CavalierItem "Cavalier"
//**     |       |-- CabinetItem "Cabinet"
//**     |       |-- MilitaryItem "Military"
//**     |       `-- PlanObliqueItem "Plan Oblique"
//**     |-- ViewSeparatorItem "-"
//**     `-- ShowBoundsItem "Show bounding box"  off at first
//** )
unit Sprite3DBuilderMain;

{
  Sprite3DBuilder's main form: an empty level to build in, a floor grid in a
  Gorilla3D view, with the camera driven by View, Camera and the mouse.

  The form has two tabs. The Level tab holds the TGorillaViewport, created
  at run time, with the level in it: FLevel, an empty root for the pieces to
  come, and its floor grid, at the spacing kept in settings.json (2 units at
  first, a floor tile of the dungeon kit). The Debug tab holds a memo for
  log output, and is always there.

  File, Library opens the Library, TAssetsForm: the user's collections of
  models, each arranged in groups, from which pieces will be placed. At
  start it opens by itself if there are any.

  The camera starts in the isometric view, fitted to the middle of the
  floor. View, Camera, Variable lets the dials of the Variable camera dialog
  set the angles, the distance, the shift and the rise; the fixed views set
  their own angles. Lock Camera fixes the camera where it is, and Mouse View
  lets the mouse turn and zoom the view. View, Projection chooses
  perspective, orthographic or one of four oblique projections drawn by the
  Spritely package's TSpritelyProjection. View, Show bounding box will box
  each piece placed.

  On Android and iOS FMX shows no main menu, so MainMenu1 is offered through
  a hamburger button on a toolbar at the top, which opens a drawer listing
  every item in MainMenu1; Library is left out there, as there is
  no folder dialog. On Linux MainMenu1 is replaced, first thing in
  FormCreate, by a TMenuBar that FMX draws itself, as the native GTK menu
  bar showed only the first letter of each item; the items must be copied,
  not moved; see UseFmxMenuBar.

    TabControl1
    |-- LevelTab "Level"
    |   `-- MainLayout
    |       `-- ViewportLayout
    |           `-- AspectLayout   dark grey; the TGorillaViewport fills it
    |               `-- (the TGorillaViewport, made in code)
    |                   `-- FLevel   the level's root, turned so Y is up
    |                       `-- FGrid   the floor grid
    `-- DebugTab "Debug"
        `-- DebugMemo

    MainMenu1
    |-- FileMenu "File"
    |   |-- LibraryItem "Library..."   the collections of models; desktop only
    |   |-- ClearLibraryItem "Clear Library..."  deletes the library; desktop only
    |   |-- CheckThumbnailsItem "Check Thumbnails"  reports empty thumbnails; desktop only
    |   |-- SettingsMenuItem "Settings..."  opens the general settings dialog
    |   |-- FRotationSnapItem "Rotation Snap..."  the step Rotate and Bend turn by; made in
    |   |                                code with the palette, desktop only
    |   |-- LicencesMenuItem "Licences..."  the third-party licences, from the program's resources
    |   |-- FileSeparatorItem "-"
    |   `-- ExitMenuItem "Exit"             closes the application
    |-- FEditMenu "Edit"                  made in code with the history, desktop only
    |   |-- FUndoItem "Undo"                Ctrl+Z: takes out the last addition
    |   |-- "-"
    |   `-- FResetLevelItem "Reset Level..."  asks, then empties the level
    `-- ViewMenu "View"                   its ticks are kept in settings.json
        |-- CameraMenu "Camera"             the view, kept in settings.json
        |   |-- ViewVariableItem "Variable"     dials set the angles; also shift and rise
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
        |   |-- FLockCameraItem "Lock Camera"   fixes the camera; not a view
        |   `-- FMouseViewItem "Mouse View"     the mouse turns and zooms the view
        |-- LightsMenu "Lights"
        |   |-- HeadlightItem "Headlight"   OrbitCamera's light; ticked at start-up
        |   `-- OriginalLightItem "Original Light"  a second light on the camera
        |-- ProjectionMenu "Projection"      one of six, a radio group
        |   |-- PerspectiveItem "Perspective"   the camera's own; at start-up
        |   |-- OrthographicItem "Orthographic" the camera's own
        |   `-- ObliqueMenu "Oblique"        drawn by TSpritelyProjection, same radio group
        |       |-- CavalierItem "Cavalier"
        |       |-- CabinetItem "Cabinet"
        |       |-- MilitaryItem "Military"
        |       `-- PlanObliqueItem "Plan Oblique"
        |-- ViewSeparatorItem "-"
        `-- ShowBoundsItem "Show bounding box"  off at first
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Math.Vectors, FMX.Types3D, Gorilla.Control, Gorilla.Transform, Gorilla.Mesh,
  Gorilla.Model, FMX.Controls3D, Gorilla.Light, Gorilla.Viewport,
  FMX.TabControl, FMX.Layouts, Gorilla.Controller, Gorilla.Animation.Controller,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Objects, FMX.Objects3D, Gorilla.Camera, Spritely.OrbitalCamera, Spritely.Projection, FMX.Menus,
  Sprite3DBuilderHelpers, Sprite3DBuilderOrbitalForm, Sprite3DBuilderSettingsForm,
  FMX.ListBox, Sprite3DSweep, System.Threading, Gorilla.Animation, DisplayData, Sprite3DGrid,
  System.Generics.Collections, Sprite3DBuilderAssetsForm, Sprite3DAssetCache,
  System.Diagnostics, Sprite3DLevelPlacement
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  , FMX.MultiView   // FMX.ListBox, also needed there, is listed above
  {$ENDIF}
  ;

type
  //** @abstract(A piece placed on the level: its model, where it lands, and its fall.)
  TLevelPiece = record
    //** @abstract(Its number, unique for the session, which the history knows it by.)
    Id: Integer;
    //** @abstract(The model that draws it, the template, a child of the level's root owned
    //** by the viewport and parked out of sight; the piece is a GPU instance of it.)
    Model: TGorillaModel;
    //** @abstract(Its instance of Model, whose Position and RotationAngle are in the
    //** viewport's coordinates, not the level's.)
    Instance: TGorillaMeshInstance;
    //** @abstract(What was dragged to make it.)
    Spec: TSprite3DPieceSpec;
    //** @abstract(Where its origin is once it has landed, in the level's coordinates.)
    Landed: TPoint3D;
    //** @abstract(How far it is turned about the up axis, through its origin, in degrees,
    //** 0 up to 360; 0 as placed. Set by the Rotate and Bend tools.)
    Turn: Single;
    //** @abstract(Its model's box turned by Turn, and then squared up to the level's axes,
    //** about its origin: what it takes up, for landing and joining.)
    Turned: TBoundingBox;
    //** @abstract(True while it is still falling.)
    Falling: Boolean;
    //** @abstract(The height of its origin when it was let go.)
    FromY: Single;
    //** @abstract(When it was let go, in seconds on TMainForm's FClock.)
    Started: Double;
    //** @abstract(Its box where it lands, in the level's coordinates.)
    //**
    //** @returns(The box, which pieces dropped later land on.)
    function Box: TBoundingBox;
  end;

  //** @abstract(The palette's tools that change the level, one of which is on while Mouse
  //** View is off.)
  TLevelEditTool = (
    //** Places the model chosen in the Library.
    etPlace,
    //** Removes the piece clicked.
    etErase,
    //** Drags the piece under the pointer across the level, X and Z.
    etMove,
    //** Turns the piece under the pointer about its middle.
    etRotate,
    //** Turns the piece under the pointer and those joined to it on one side about its join
    //** with the piece on the other side.
    etBend,
    //** Variants: outlines every piece whose model has material variants; a click on one
    //** chooses its variant from a menu (with Shift, for every piece of that model).
    etVariant,
    //** Move Camera: drags the view across the level, X and Z.
    etPan);

  //** @abstract(One line of the history: the pieces one click or area placed.)
  THistoryEntry = record
    //** @abstract(The model placed.)
    Name: String;
    //** @abstract(How many were placed.)
    Placed: Integer;
    //** @abstract(The TLevelPiece.Id of those still in the level.)
    Ids: TArray<Integer>;
  end;

  //** @abstract(What placing a model has made once, for every piece of it: the template the
  //** pieces are drawn by, the file it was loaded from and whether it is static.)
  TPieceSource = record
    //** @abstract(The model loaded once, a child of the level's root, parked far below the
    //** floor (TEMPLATE_PARK_Y): every piece of it is drawn by the GPU as an instance of it.)
    Template: TGorillaModel;
    //** @abstract(The file the template was loaded from: the model's own, or its copy with
    //** the textures and buffers found or made, from PrepareModelTextures, or a copy showing
    //** a material variant, from PrepareModelVariant.)
    LoadFile: String;
    //** @abstract(True if the model is static (meshes only, no skin, no animations), so the
    //** template's meshes are made static.)
    IsStatic: Boolean;
  end;

  //** @abstract(The main form: a Gorilla3D view of the level, a floor grid for now, with the
  //** camera driven by View, Camera.)
  //**
  //** The viewport and the level are created at run time, not at design time. The camera and its
  //** light are made by OrbitCamera, a @code(TSpritelyOrbitalCamera) on the form, once
  //** FormCreate gives it the viewport. All event handlers run on the main thread.
  TMainForm = class(TForm)
    //** @abstract(Fills the form and holds the Level and Debug tabs.)
    TabControl1: TTabControl;
    //** @abstract(The tab captioned "Level", first of all; active at start-up.)
    //**
    //** Holds MainLayout, with the viewport and the level in it.
    LevelTab: TTabItem;
    //** @abstract(The tab captioned "Debug", holding DebugMemo; always shown.)
    DebugTab: TTabItem;
    //** @abstract(Log output: what was chosen, what went wrong, and what changed.)
    DebugMemo: TMemo;
    //** @abstract(Fills the Level tab, and holds ViewportLayout.)
    MainLayout: TLayout;
    //** @abstract(Fills MainLayout; holds AspectLayout, with the frame rate and Mouse View
    //** readouts over it.)
    ViewportLayout: TLayout;
    //** @abstract(Fills ViewportLayout in dark grey, and holds the TGorillaViewport made in
    //** FormCreate, which fills it.)
    //**
    //** Its name is from Sprite3D, where the viewport kept the shape of the grabs inside it;
    //** here there are no grabs, so the viewport fills it. Clicks pass through it.
    AspectLayout: TRectangle;
    //** @abstract(An FMX TModel3D placed at design time; the code does not use it.)
    //**
    //** Pieces will be TGorillaModel objects made at run time, under FLevel.
    Model3D1: TModel3D;
    //** @abstract(The orbital camera, from the Spritely package: it builds the viewport's
    //** camera, kept in GorillaCamera, and the headlight riding on it, kept in GorillaLight.)
    //**
    //** Placed in the form designer with no Viewport, as the viewport is made at run time;
    //** FormCreate sets Viewport, which builds the camera. Headlight is on, so the light sits
    //** where the camera is and points where it looks, lighting whatever side of the level is
    //** in view. The rest of the form works on the camera itself, GorillaCamera, as before.
    OrbitCamera: TSpritelyOrbitalCamera;
    //** @abstract(The form's menu bar, holding FileMenu.)
    MainMenu1: TMainMenu;
    //** @abstract(The "File" menu: Library..., Clear Library..., Settings..., Licences... and
    //** Exit.)
    FileMenu: TMenuItem;
    //** @abstract(The "Library..." item, first in File; see LibraryItemClick. Desktop only:
    //** freed on Android and iOS, which have no folder dialog to add collections with.)
    LibraryItem: TMenuItem;
    //** @abstract(The "Clear Library..." item, after Library; see ClearLibraryItemClick.
    //** Desktop only, as Library is.)
    ClearLibraryItem: TMenuItem;
    //** @abstract(The "Check Thumbnails" item, after Clear Library; see
    //** CheckThumbnailsItemClick. Desktop only, as Library is.)
    CheckThumbnailsItem: TMenuItem;
    //** @abstract(The File menu's "Licences..." item; see LicencesMenuItemClick.)
    LicencesMenuItem: TMenuItem;
    //** @abstract(The "Settings..." item; see SettingsMenuItemClick.)
    SettingsMenuItem: TMenuItem;
    //** @abstract(Separator line in the File menu, above Exit.)
    FileSeparatorItem: TMenuItem;
    //** @abstract(The "Exit" item; see ExitMenuItemClick.)
    ExitMenuItem: TMenuItem;
    //** @abstract(The "View" menu; holds CameraMenu.)
    ViewMenu: TMenuItem;
    //** @abstract(The "Camera" submenu of View, choosing how the camera angles are set.)
    //**
    //** Its items form one radio group: Variable, where the dials set the angles, and the
    //** fixed views Isometric, Pixel 2:1, 3/4 View, Head On, Top Down and Side View. Choosing
    //** an item clears every check in the submenu, sets the view, then checks that item. The
    //** checked item, and the dials' angles while Variable is checked, are kept in
    //** settings.json and restored at start-up.
    CameraMenu: TMenuItem;
    //** @abstract(The line between CameraMenu and the View menu's on/off items.)
    ViewSeparatorItem: TMenuItem;
    //** @abstract(Shows or hides the placed pieces' bounding boxes; off at first.)
    //**
    //** Ticked, every piece placed in the level will be drawn with Gorilla's ShowBoundingBox,
    //** an orange box round its bounds. With none placed yet only the tick changes. See
    //** ShowBoundsItemClick.
    ShowBoundsItem: TMenuItem;
    //** @abstract(The View menu's "Projection" submenu: one of six projections, a radio
    //** group; see ProjectionItemClick and ApplyProjection.)
    //**
    //** Perspective and Orthographic are the camera's own. Cavalier, Cabinet, Military and
    //** Plan Oblique are drawn by FProjection, a @code(TSpritelyProjection), with the camera
    //** in perspective. Kept as @code(projection) in settings.json.
    ProjectionMenu: TMenuItem;
    //** @abstract(The camera's own perspective; chosen at start-up when nothing is saved.)
    PerspectiveItem: TMenuItem;
    //** @abstract(The camera's own orthographic projection.)
    OrthographicItem: TMenuItem;
    //** @abstract(View, Projection's "Oblique" submenu, below Orthographic: CavalierItem,
    //** CabinetItem, MilitaryItem and PlanObliqueItem.)
    //**
    //** Its items are in the same radio group as PerspectiveItem and OrthographicItem, but FMX
    //** unticks only an item's siblings, so CheckProjection ticks and unticks all six.
    ObliqueMenu: TMenuItem;
    //** @abstract(Cavalier: depth drawn at full length at 45 degrees; best from Head On.)
    CavalierItem: TMenuItem;
    //** @abstract(Cabinet: depth drawn at half length at 63.43 degrees; best from Head On.)
    CabinetItem: TMenuItem;
    //** @abstract(Military: depth drawn at full length straight down the picture; best from
    //** Top Down, where height goes straight up and the plan keeps its shape.)
    MilitaryItem: TMenuItem;
    //** @abstract(Plan oblique: depth drawn at full length down and to the right; best from
    //** Top Down, where height goes up and to the left at 45 degrees.)
    PlanObliqueItem: TMenuItem;
    //** @abstract(The View menu's "Lights" submenu, holding HeadlightItem and
    //** OriginalLightItem, which switch each light on or off on its own.)
    //**
    //** Both can be on at once, which lights the level twice from the same point, or both
    //** off, which leaves it unlit; the Debug tab says which are on each time one
    //** changes. See ApplyLights.
    LightsMenu: TMenuItem;
    //** @abstract(Switches OrbitCamera's headlight on or off; ticked at start-up.)
    //**
    //** The headlight is a point light that @code(TSpritelyOrbitalCamera) makes at the
    //** camera's own position while its @code(Headlight) is True. See HeadlightItemClick.
    HeadlightItem: TMenuItem;
    //** @abstract(Switches the original light on or off; not ticked at start-up.)
    //**
    //** The original light is the point light the form made by hand before the Spritely
    //** camera came in, kept in GorillaLight; it is the same kind of light in the same
    //** place as the headlight, made by the form instead of the component. See
    //** OriginalLightItemClick.
    OriginalLightItem: TMenuItem;
    //** @abstract(The "Variable" view; see ViewVariableItemClick.)
    ViewVariableItem: TMenuItem;
    //** @abstract(The "Isometric" view, chosen at start-up when no other is saved; see
    //** ViewIsometricItemClick.)
    ViewIsometricItem: TMenuItem;
    //** @abstract(The "Pixel 2:1" view; see ViewPixel2To1ItemClick.)
    ViewPixel2To1Item: TMenuItem;
    //** @abstract(The "3/4 View" view; see ViewThreeQuarterItemClick.)
    ViewThreeQuarterItem: TMenuItem;
    //** @abstract(The "Head On" view; see ViewHeadOnItemClick.)
    ViewHeadOnItem: TMenuItem;
    //** @abstract(The "Top Down" view; see ViewTopDownItemClick.)
    ViewTopDownItem: TMenuItem;
    //** @abstract(The "Side View" view; see ViewSideItemClick.)
    ViewSideItem: TMenuItem;
    //** @abstract(The "1/4 View" view; see ViewOneQuarterItemClick.)
    ViewOneQuarterItem: TMenuItem;
    //** @abstract(The "Sqrt@(2@)" view; see ViewRoot2ItemClick.)
    ViewRoot2Item: TMenuItem;
    //** @abstract(The "Golden Ratio" view; see ViewGoldenRatioItemClick.)
    ViewGoldenRatioItem: TMenuItem;
    //** @abstract(A separator line in the View, Camera menu, between groups of views.)
    CameraSeparatorItem1: TMenuItem;
    //** @abstract(A separator line in the View, Camera menu, between groups of views.)
    CameraSeparatorItem2: TMenuItem;
    //** @abstract(Sets up the viewport, light, camera and the empty level.)
    //**
    //** The handler creates a TGorillaViewport filling AspectLayout and gives it to OrbitCamera,
    //** which builds the camera, with a 45-degree FOV, makes it the viewport's camera, and
    //** puts its headlight, a point light, on the camera at its origin, so it sits where the
    //** camera is and points where it looks. The viewport runs at the frame rate set in File,
    //** Settings without VSync. BuildLevel then makes the level's root and its floor grid.
    //**
    //** The dials start at 0, then the camera view kept in settings.json is chosen, as its
    //** View, Camera item would choose it: a fixed view turns the dials to its angles and
    //** switches them off, and Variable turns them to the angles kept with it and leaves them
    //** on. Isometric is chosen when none is kept. Last, the View menu's on/off items are
    //** ticked as settings.json says they were left, and applied, which also sets the
    //** projection.
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Says in the Debug tab that the level starts empty, and sets the caption.)
    //**
    //** Runs once, the first time the form is shown.
    //**
    //** @param(Sender The form.)
    procedure FormShow(Sender: TObject);
    //** @abstract(Saves the view state and frees the settings.)
    //**
    //** The checked View, Camera item, the dials' angles if that is Variable, and the ticks of
    //** the View menu's on/off items are written to settings.json for the next session;
    //** a failed save is ignored, as no message can be shown here. Other settings are saved as
    //** soon as they change.
    //**
    //** @param(Sender The form.)
    procedure FormDestroy(Sender: TObject);
    //** @abstract(Lets the window close: nothing is ever being written that a close could
    //** leave half done.)
    //**
    //** Kept as the place to ask before an unsaved level is thrown away, once there are levels.
    //**
    //** @param(Sender The form.)
    //**
    //** @param(CanClose Always left True.)
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    //** @abstract(Copies RollDial to the camera's Roll.)
    //**
    //** The dial value is wrapped into 0 to 360, without negating, shown in RollText and
    //** written to the camera. The view is not refitted; see FitModel.
    //**
    //** @param(Sender RollDial.)
    procedure RollDialChange(Sender: TObject);
    //** @abstract(Refits the camera to the level when the viewport changes size.)
    //**
    //** Assigned to the viewport's OnResize in FormCreate. Does nothing while View, Camera,
    //** Lock Camera is ticked.
    //**
    //** @param(Sender The TGorillaViewport.)
    procedure GorillaViewportResize(Sender: TObject);
    //** @abstract(Keeps the palette and the history inside the view when AspectLayout
    //** changes size; the viewport fills AspectLayout, and refits itself.)
    //**
    //** @param(Sender AspectLayout.)
    procedure AspectLayoutResize(Sender: TObject);
    //** @abstract(Chooses the projection of the View, Projection item clicked, then switches
    //** to it and refits the view; see ApplyProjection.)
    //**
    //** Clicking the oblique projection already ticked turns the camera back to its angles,
    //** undoing whatever View, Camera, Variable has turned since; clicking Perspective or
    //** Orthographic while ticked does nothing. Does nothing while View, Camera, Lock Camera
    //** is ticked, when the items are disabled.
    //**
    //** @param(Sender PerspectiveItem, OrthographicItem or one of ObliqueMenu's items.)
    procedure ProjectionItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks HeadlightItem, then switches OrbitCamera's headlight to
    //** match; see ApplyLights.)
    //**
    //** @param(Sender HeadlightItem.)
    procedure HeadlightItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks OriginalLightItem, then makes or frees the original light
    //** to match; see ApplyLights.)
    //**
    //** @param(Sender OriginalLightItem.)
    procedure OriginalLightItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks ShowBoundsItem, then shows or hides the placed pieces'
    //** bounding boxes to match.)
    //**
    //** Only the tick changes until a piece is placed.
    //**
    //** @param(Sender ShowBoundsItem.)
    procedure ShowBoundsItemClick(Sender: TObject);
    //** @abstract(Opens the Library; see OpenLibrary.)
    //**
    //** @param(Sender LibraryItem.)
    procedure LibraryItemClick(Sender: TObject);
    //** @abstract(Shows the Library, TAssetsForm, making it the first time.)
    //**
    //** Made, it is told AssetFolder from settings.json, the folder of the one palette of
    //** before the library, so that palette can become the first collection.
    procedure OpenLibrary;
    //** @abstract(Opens the Library at start if it has collections, or there is a palette of
    //** before the library to make one of; queued from FormShow, desktop only.)
    procedure OpenLastLibrary;
    //** @abstract(Asks, then deletes the whole library: the database and the thumbnail
    //** folder with everything in it.)
    //**
    //** If the Library form has been made, it does it (TAssetsForm.ClearLibrary) and shows
    //** itself empty; if not, ClearAssetLibrary is called here, on
    //** TSprite3DAppSettings.ThumbnailFolder. What was done goes to the Debug tab. The model
    //** files are never touched. No changes nothing.
    //**
    //** @param(Sender ClearLibraryItem.)
    procedure ClearLibraryItemClick(Sender: TObject);
    //** @abstract(Checks every thumbnail in the library for ones with nothing, or almost
    //** nothing, in them (TAssetsForm.CheckThumbnails), without showing the Library; the
    //** summary goes to the Debug tab, the list to the report it names.)
    //**
    //** @param(Sender CheckThumbnailsItem.)
    procedure CheckThumbnailsItemClick(Sender: TObject);
    //** @abstract(Makes the Library, TAssetsForm, if it has not been made, without showing
    //** it: told the settings it needs, and where to send its log and its choice of
    //** preview background.)
    procedure EnsureAssetsForm;
    //** @abstract(Shows the third-party licences and notices the program carries, from its
    //** own resources: TLicencesForm, by ShowLicences.)
    //**
    //** @param(Sender LicencesMenuItem.)
    procedure LicencesMenuItemClick(Sender: TObject);
    //** @abstract(Opens the Settings dialog and applies what is chosen.)
    //**
    //** The dialog, TGeneralSettingsForm, opens modally, centred on this form, showing the
    //** settings as they stand, with the GPU read from the system. On OK the theme is applied
    //** at once, the view's frame rate changed, the GPU preference is stored for the next start, and everything is saved to
    //** settings.json; anything the user needs to know, such as a failure or the need to
    //** restart, is reported in a message. Cancel changes nothing. On Android and iOS, where a
    //** dialog cannot block, it opens as an ordinary form and OK is applied when it closes.
    //**
    //** @param(Sender SettingsMenuItem.)
    procedure SettingsMenuItemClick(Sender: TObject);
    //** @abstract(Closes the application.)
    //**
    //** Closes the main form, which ends the application in the normal way, so the form and
    //** everything it owns are freed as usual.
    //**
    //** @param(Sender ExitMenuItem.)
    procedure ExitMenuItemClick(Sender: TObject);
    //** @abstract(Opens the Variable camera dialog, where dials set the angles.)
    //**
    //** The dialog, TOrbitalSettingsForm, shows the current angles, distance factor, shift
    //** and rise as the view shows them: a Mouse View turn and zoom are taken into
    //** them (ShownCameraSpec) and the mouse view reset, so the view does not move and OK
    //** keeps it as the normal view. Every change is shown in the viewport at once. Cancel
    //** puts the camera back as it was, mouse view and all. Either way the View checks are
    //** cleared and Variable is checked.
    //** While the form is being created, as when the Variable view is restored at start-up,
    //** no dialog is shown and only the check changes.
    //**
    //** @param(Sender ViewVariableItem.)
    procedure ViewVariableItemClick(Sender: TObject);
    //** @abstract(Sets the isometric view and fixes it.)
    //**
    //** Clears every View check, sets the inclination to ArcTan@(1/Sqrt@(2@)@), about 35.264
    //** degrees, the true isometric elevation, the azimuth to 45 and the roll to 0, as shown on
    //** the readouts, turns the dials to match and switches them off, refits the level for the
    //** new view, then checks the Isometric item. As with the dial, the azimuth reaches the
    //** camera reversed. The other fixed views work the same way with their own inclination.
    //**
    //** @param(Sender ViewIsometricItem.)
    procedure ViewIsometricItemClick(Sender: TObject);
    //** @abstract(Moves the camera out by the slider's factor; test only.)
    //**
    //** In perspective mode the camera's Distance becomes the fitted distance times the
    //** factor; in orthographic mode, where distance does not change the size, OrthoHeight
    //** is scaled instead. The factor is kept when the level is refitted.
    //**
    //** @param(Sender DistanceTrack.)
    procedure DistanceTrackChange(Sender: TObject);
    //** @abstract(Sets the pixel-art 2:1 view and fixes it.)
    //**
    //** As View, Camera, Isometric, but with the inclination ArcTan@(1/2@), about 26.565
    //** degrees, at which lines on the floor run 2 pixels across for each pixel up, as in 2:1
    //** pixel art.
    //**
    //** @param(Sender ViewPixel2To1Item.)
    procedure ViewPixel2To1ItemClick(Sender: TObject);
    //** @abstract(Sets the 3/4 view and fixes it.)
    //**
    //** The angle of military projection: inclination 45 degrees at azimuth 45. The projection
    //** is applied again as it stands, so View, Orthographic gives the flat look of 3/4-view
    //** game art; the view no longer switches it on by itself.
    //**
    //** @param(Sender ViewThreeQuarterItem.)
    procedure ViewThreeQuarterItemClick(Sender: TObject);
    //** @abstract(Sets the head-on view and fixes it.)
    //**
    //** Inclination 0 and azimuth 0: at floor height, looking along its Z axis.
    //**
    //** @param(Sender ViewHeadOnItem.)
    procedure ViewHeadOnItemClick(Sender: TObject);
    //** @abstract(Sets the top-down view and fixes it.)
    //**
    //** Inclination 90 and azimuth 0: straight down onto the level.
    //**
    //** @param(Sender ViewTopDownItem.)
    procedure ViewTopDownItemClick(Sender: TObject);
    //** @abstract(Sets the side view and fixes it.)
    //**
    //** Inclination 0 and azimuth 90: at floor height, from the side, a quarter turn
    //** from View, Camera, Head On.
    //**
    //** @param(Sender ViewSideItem.)
    procedure ViewSideItemClick(Sender: TObject);
    //** @abstract(Sets the 1/4 view and fixes it.)
    //**
    //** Inclination 22.5 degrees at azimuth 45: a lower look than View, Camera, 3/4 View. The
    //** projection is applied again as it stands, and the level refitted.
    //**
    //** @param(Sender ViewOneQuarterItem.)
    procedure ViewOneQuarterItemClick(Sender: TObject);
    //** @abstract(Sets the Sqrt@(2@) view and fixes it.)
    //**
    //** As View, Camera, Isometric, but with the inclination ArcTan@(Sqrt@(2@)@), about 54.736
    //** degrees, the complement of the isometric angle.
    //**
    //** @param(Sender ViewRoot2Item.)
    procedure ViewRoot2ItemClick(Sender: TObject);
    //** @abstract(Sets the golden-ratio view and fixes it.)
    //**
    //** As View, Camera, Isometric, but with the inclination ArcTan@(1.618...@), the golden
    //** ratio, about 58.283 degrees.
    //**
    //** @param(Sender ViewGoldenRatioItem.)
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
    //** @abstract(The original light, made by ApplyLights while OriginalLightItem is ticked,
    //** and nil while it is not.)
    //**
    //** A point light parented to the camera at its origin with no turn of its own, as the
    //** form made it before the Spritely camera, which brought its own headlight
    //** (@code(OrbitCamera.Light)). Owned by the viewport; ApplyLights frees it when the item
    //** is unticked, and the viewport frees it at the end otherwise.
    GorillaLight: TGorillaLight;
    //** @abstract(The viewport's camera, built by OrbitCamera when FormCreate sets its
    //** Viewport; everything that turns, fits or reads the camera uses it.)
    //**
    //** The camera's own methods, such as @code(FitPointsOnAxis), @code(ShiftView),
    //** @code(SaveFraming) and @code(RestoreFraming), are on it rather than on OrbitCamera.
    //** It is the viewport's, freed with it, never by the form.
    GorillaCamera: TSpritelyOrbitalGorillaCamera;
    // Settings kept between sessions in settings.json
    FSettings: TSprite3DAppSettings;
    // True once FormShow has run
    FStarted: Boolean;
    //** @abstract(The level's root: a @code(TDummy) in the viewport, turned 180 degrees about
    //** X so Y is up inside it, as in the kits; every placed piece will be a child of it. The
    //** camera is fitted to it. Made by BuildLevel.)
    FLevel: TDummy;
    //** @abstract(The level's floor grid, a TModelGrid from Sprite3DGrid on FLevel, at
    //** GridSize from settings.json, always shown.)
    FGrid: TModelGrid;
    //** @abstract(The Library, the collections of models as thumbnails; made, owned by this
    //** form, the first time it is opened, then kept.)
    FAssetsForm: TAssetsForm;
    //** @abstract(ApplyLights has written its first Debug tab line, saying which lights the
    //** session starts with; after that it writes one only when they change.)
    FLightsLogged: Boolean;
    //** @abstract(Draws the oblique projections chosen in View, Projection: a
    //** @code(TSpritelyProjection), made in FormCreate and freed first thing in FormDestroy.)
    //**
    //** It is OrbitCamera's Projection, so the camera's fits and ProjectToView follow what it
    //** draws, and its Viewport is GorillaViewport, where it puts an empty 3D object first
    //** among the children to write the projection inside each frame. CameraPreset is off:
    //** the camera's angles stay View, Camera's. For Perspective and Orthographic its Kind is
    //** pjPerspective, so it leaves FMX's projection alone.
    FProjection: TSpritelyProjection;
    //** @abstract(The projection ApplyProjection last logged; Ord -1 before the first.)
    FLoggedProjection: Integer;
    //** @abstract(True while an oblique projection is chosen in View, Projection: the camera
    //** starts at the projection's angles, View, Camera's fixed views are disabled, and
    //** Variable's dials turn it from there.)
    FObliqueActive: Boolean;
    //** @abstract(The View, Camera view, by its settings key, chosen before the first oblique
    //** projection; put back when the projection is the camera's own again, and kept in
    //** settings.json in place of the oblique one.)
    FObliqueView: String;
    //** @abstract(The angles, as the readouts show them, before the first oblique projection;
    //** put back with FObliqueView when it is Variable.)
    FObliqueAzimuth, FObliqueInclination, FObliqueRoll: Single;
    //** @abstract(The shift and rise from View, Camera, Variable, applied on top of every fit
    //** while FPanEnabled: FPanX the shift, right positive, FPanZ the rise, up positive, each
    //** a fraction of how far the picture can slide, PAN_LIMIT either way; see PlaceShift.)
    //**
    //** The names are from before they were a lens shift, when they moved the orbit centre
    //** along the model's X and Z axes in Sprite3D; settings.json keeps the same keys.
    FPanEnabled: Boolean;
    FPanX, FPanZ: Single;
    //** @abstract(Whether the shift, rise and distance factor are kept for the next session:
    //** Variable's Save shift, rise and distance values between sessions, kept as
    //** @code(keepShift); False by default. See KeepShiftSettings.)
    FPanKeep: Boolean;
    //** @abstract(True while FormCreate puts back the last session's camera view and
    //** projection, so ResetViewSettings leaves the distance, shift and rise it loaded.)
    FRestoringView: Boolean;
    //** @abstract(The Variable camera dialog while it is open on the desktop, else nil, so
    //** Mouse View's wheel and drag change its distance and azimuth rather than the mouse
    //** view; see DialogMouseView.)
    FOrbitalDialog: TOrbitalSettingsForm;
    //** @abstract(True once the view has been fitted, so there is a fit to shift.)
    FFitted: Boolean;
    //** @abstract(How far PutOnSlide has slid the orbit centre, in orthographic projection,
    //** where the slide stands in for the lens shift; zero otherwise.)
    //**
    //** Taken off again before every new slide and around every change Mouse View
    //** makes (ShiftCamera, which then places the shift again), and set to zero by every
    //** fit, which puts the centre back where the fit wants it.
    FAppliedPan: TPoint3D;
    //** @abstract(The shift and rise PlaceShift last placed, in normalised device units, 0
    //** while off.)
    FSlideX, FSlideY: Single;
    //** @abstract(What PlaceShift was last asked for, the fractions and whether on, so
    //** ShiftCamera can place it again when Mouse View turns or zooms.)
    FPlaceEnabled: Boolean;
    FPlaceShift, FPlaceRise: Single;
    //** @abstract(The shift and rise line LogShift wrote last, so it writes only changes.)
    FLoggedShift: String;
    // View, Camera, Lock Camera, and the line above it
    FLockCameraItem: TMenuItem;
    FLockSeparatorItem: TMenuItem;
    //** @abstract(View, Camera, Mouse View, between the line and Lock Camera;
    //** desktop only, so nil on Android and iOS.) See MouseViewItemClick.
    FMouseViewItem: TMenuItem;
    //** @abstract(The mouse view's turn and zoom, on top of the normal view.)
    //** FMouseYaw is in degrees of the camera's own Azimuth, wrapped into 0 to 360, and
    //** FMouseZoom a factor on the distance, or on the orthographic size; 0 and 1 while the
    //** view is normal.
    FMouseYaw: Single;
    FMouseZoom: Single;
    //** @abstract(True while FMouseYaw and FMouseZoom are on the camera.) SuspendMouseView
    //** takes them off while the normal view is changed, and ResumeMouseView puts them back.
    FMouseApplied: Boolean;
    //** @abstract(How many SuspendMouseView calls are still to be matched by
    //** ResumeMouseView.) The mouse view goes back on only when it falls to 0.
    FMouseSuspend: Integer;
    //** @abstract(Whether FMouseZoom is on the orthographic size rather than the distance.)
    //** Kept, so it comes off the one it was put on even if the projection has changed since.
    FMouseZoomOrtho: Boolean;
    //** @abstract(What was shown when the mouse view first moved the camera, from
    //** MouseViewSubject.) Anything else shown puts the normal view back.
    FMouseSubject: String;
    //** @abstract(True while the left button, pressed over the view, is held.) FMouseLastX
    //** is where the pointer last was, in AspectLayout's coordinates.
    FMouseDragging: Boolean;
    FMouseLastX: Single;
    // The frame rate the viewport draws at, top left of the view, and the
    // timer that refreshes it
    FFpsLabel: TLabel;
    FFpsBack: TRectangle;   // dark, so the label reads on any background
    FReadoutTimer: TTimer;
    // The displays, kept so the one the form is on can be checked cheaply
    // as the readouts refresh; read again whenever the form moves to
    // another, so the frame rate follows that display's refresh rate
    FDisplays: TPeardoxDisplays;
    FDisplayIndex: Integer;
    //** @abstract(The box shown where a piece dragged from the Library would come to rest,
    //** a
    //** child of FLevel; hidden but while one is over the floor. Made by BuildLevel.)
    FPlaceBox: TSprite3DPlacementBox;
    //** @abstract(True while FPlaceBox is shown, round FPlaceSpots.)
    FPlaceShown: Boolean;
    //** @abstract(The height the origin of each piece shown would rest at, in the level's
    //** coordinates.)
    FPlaceLand: Single;
    //** @abstract(Where each piece shown would go across the floor: its origin's X and Z,
    //** in
    //** X and Y. One while hovering; the area's while dragging.)
    FPlaceSpots: TArray<TPointF>;
    //** @abstract(The model Place Model places: the one last chosen in the Library that can
    //** be
    //** placed.)
    FBrush: TSprite3DPieceSpec;
    //** Every model picked in the Library, FBrush first: each piece placed is
    //** one of them at random; FBrush alone sets the spacing and the box shown
    FBrushSet: TArray<TSprite3DPieceSpec>;
    //** @abstract(True once a model has been chosen to place.)
    FHasBrush: Boolean;
    //** @abstract(True while the left button, pressed over the floor with Place Model on,
    //** is
    //** held: the area from FPlaceAnchor to the pointer is shown.)
    FPlaceDown: Boolean;
    //** @abstract(Where the area started: the spot under the pointer as the button went
    //** down.)
    FPlaceAnchor: TPointF;
    //** @abstract(True once the Debug tab has said this area was cut to MAX_AREA_PIECES.)
    FPlaceCapLogged: Boolean;
    //** @abstract(The time PlacePiece has spent, since PlaceShown began, loading pieces,
    //** and
    //** putting them in the level, in stopwatch ticks: for the Debug tab, to see where an
    //** area's time goes.)
    FMakeTicks, FSetupTicks: Int64;
    //** Numbers the instances, which are named
    FInstanceSerial: Integer;
    //** Rotate and Bend. FEditTool is the palette's tool while Mouse View is
    //** off. FPoser, a hidden child of FLevel, gives an instance its whole
    //** transform the way FMX gives the template its own; FTurnSign is the
    //** way FMX turns for a positive angle about the level's up axis.
    //** FPickBox outlines FPicked, the piece under the pointer (-1 for none).
    //** While FTurnDown, the pieces FTurnSet are being turned by FTurnBy
    //** degrees about FTurnHinge, from where they were (FTurnSaved, every
    //** piece as it was when FTurnButton was pressed, at FTurnStartX)
    FEditTool: TLevelEditTool;
    FPoser: TDummy;
    FTurnSign: Single;
    FPickBox: TSprite3DPlacementBox;
    FPicked: Integer;
    FTurnDown: Boolean;
    FTurnButton: TMouseButton;
    FTurnStartX: Single;
    FTurnBy: Single;
    FTurnHinge: TPointF;
    FTurnSet: TArray<Integer>;
    //** How many of FTurnSet are carried: stacked on the pieces turned
    FTurnCarried: Integer;
    FTurnSaved: TArray<TLevelPiece>;
    FRotateButton, FBendButton: TRectangle;
    //** @abstract(The palette's Variants button, beside Bend.)
    FVariantButton: TRectangle;
    FRotationSnapItem: TMenuItem;
    //** Erase, Move Object and Move Camera. FNextPieceId numbers the pieces.
    //** Move Object: while FMoveDown, piece FMoveIndex follows the pointer,
    //** its middle FMoveOffset from the floor point under it; FMoveRiders, the
    //** pieces resting on it, are left behind and fall when it is let go.
    //** Move Camera: while FPanDown, the floor point FPanGrab stays under the
    //** pointer; FViewCentre is the middle of the floor the view is fitted to
    FNextPieceId: Integer;
    FEraseButton, FMoveButton, FPanButton: TRectangle;
    FMoveDown: Boolean;
    FMoveIndex: Integer;
    FMoveOffset: TPointF;
    FMoveStart: TPoint3D;
    FMoveRiders: TArray<Integer>;
    FPanDown: Boolean;
    FPanGrab: TPointF;
    FViewCentre: TPointF;
    //** The history panel: on the left, below the palette, newest first; at
    //** most HISTORY_MAX entries. FMovingPanel is the panel whose grip is held
    FHistory: TList<THistoryEntry>;
    FHistoryBack, FHistoryGrip: TRectangle;
    FHistoryBox: TVertScrollBox;
    FMovingPanel: TControl;
    //** Edit, Undo: takes out the newest history line's pieces, the last
    //** addition; made with the history, desktop only
    FEditMenu, FUndoItem, FResetLevelItem: TMenuItem;
    //** Level files: FLevelFile, the file the level was last saved to or
    //** loaded from (empty for a new one); FLevelDirty, changed since;
    //** FCloseAsked, the user has said what to do with the changes, so the
    //** window may close. File, Load Level, Save Level and Save Level As
    FLevelFile: String;
    FLevelDirty: Boolean;
    FCloseAsked: Boolean;
    FLoadLevelItem, FSaveLevelItem, FSaveLevelAsItem: TMenuItem;
    //** View, History: shows or hides the history panel. FPanelsPlaced: the
    //** palette and the history have been put where settings.json says, once
    //** the window had its size; until then their places are not kept
    FHistoryItem: TMenuItem;
    FPanelsPlaced: Boolean;
    //** The view's size the panels were last kept for: as it changes, each
    //** panel keeps its distance from the edges it is nearer
    FViewSize: TSizeF;
    //** @abstract(How many pieces across X and Z the box shown holds: 1 and 1 but while an
    //** area is dragged.)
    FPlaceCountX, FPlaceCountZ: Integer;
    //** The area's first spot and the signed step to the next, each way, so
    //** the rest height is found without testing every spot (AreaSpots)
    FAreaOrigin, FAreaStep: TPointF;
    //** @abstract(For each model placed, by its key, the file its pieces load and whether
    //** it
    //** is static, found when its first piece is placed. Made by BuildLevel.)
    FSources: TDictionary<String, TPieceSource>;
    //** @abstract(Each model's material variants' names, by its key in lower case, read once
    //** from its file (ModelVariantNames); empty for a model without.)
    FVariantNames: TDictionary<String, TArray<String>>;
    //** @abstract(While Variants is the tool: an outline round each piece whose model has
    //** variants, up to MAX_VARIANT_MARKS; owned.)
    FVariantMarks: TObjectList<TSprite3DPlacementBox>;
    //** @abstract(The Variants tool's menu, made afresh for each click.)
    FPieceVariantMenu: TPopupMenu;
    //** @abstract(The piece the Variants tool's menu is for, an index into FPieces.)
    FVariantTarget: Integer;
    //** @abstract(True if the menu's choice is for every piece of the target's model (Shift
    //** was held).)
    FVariantAll: Boolean;
    //** @abstract(The palette: a floating toolbar over the view, on a dark backing,
    //** upright,
    //** with a grip across its top to move it and the Place Model and Mouse View tools under
    //** it. Made by BuildPalette; desktop only.)
    FPaletteBack: TRectangle;
    //** @abstract(The palette's grip, across its top: dragging it moves the palette.)
    FPaletteGrip: TRectangle;
    //** @abstract(The palette's Place Model and Mouse View buttons.)
    FPlaceButton, FCameraButton: TRectangle;
    //** @abstract(The status bar along the bottom of the form: the tool on, the model it
    //** places and what the mouse does. Made by BuildStatusBar; desktop only.)
    FStatusBar: TStatusBar;
    //** @abstract(The status bar's text.)
    FStatusLabel: TLabel;
    //** @abstract(True while the grip is dragged.)
    FPaletteMoving: Boolean;
    //** @abstract(Where the grip was taken, in the palette's own coordinates.)
    FPaletteGrab: TPointF;
    //** @abstract(Every piece placed, in the order placed. Made by BuildLevel.)
    FPieces: TList<TLevelPiece>;
    //** @abstract(Moves the falling pieces, while any fall.)
    FFallTimer: TTimer;
    //** @abstract(The clock the falls are timed by, started by BuildLevel.)
    FClock: TStopwatch;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    // The Settings dialog's starting values, for comparing on OK
    FSettingsBefore: TSprite3DGeneralSettings;
    {$ENDIF}
    function FitModel: Boolean;
    //** @abstract(FitModel's fit, of the normal view alone; FitModel takes the mouse view
    //** off around it.) False if the camera is locked or there is no level.
    function FitNormalView: Boolean;
    procedure ApplyAngles;
    procedure ApplyDistance;
    //** @abstract(Puts the view's shift and rise, FPanEnabled, FPanX and FPanZ, on the view;
    //** see ShowPan.)
    procedure ApplyPan;
    procedure ShowDistanceFactor(const AFactor: Single);
    //** @abstract(Shows a shift and rise on the view, at the viewport's size, without keeping
    //** them; see PlaceShift.)
    //**
    //** Does nothing while the camera is locked or before the first fit.
    //**
    //** @param(AEnabled Whether the shift and rise are on; False slides nothing.)
    //** @param(APanX The shift, -1 to 1.)
    //** @param(APanZ The rise, -1 to 1.)
    procedure ShowPan(const AEnabled: Boolean; const APanX, APanZ: Single);
    //** @abstract(Slides the picture by a shift and rise, the view of the level itself
    //** unchanged.)
    //**
    //** Each is a fraction of how far the picture can slide that way: until the near side of
    //** the volume, as it is drawn now (SweepViewExtent), is on that edge, so at 1 or -1 the
    //** model has just gone off the picture's right or left edge, or top or bottom, however
    //** near or far the camera is. In perspective and the oblique
    //** projections the slide is FProjection's lens shift and rise (@code(ShiftX),
    //** @code(ShiftY)): the camera does not move, so nothing in the picture changes but its
    //** place. In orthographic projection, which FProjection cannot draw over, the camera
    //** slides across the picture instead (PutOnSlide), which in a parallel view is the same
    //** thing exactly. Whatever this slid before is taken off first. FSlideX and FSlideY keep
    //** what is placed.
    //**
    //** @param(AEnabled Whether to slide at all; False only takes off the slide before.)
    //** @param(AShift The shift, right positive; limited to PAN_LIMIT either way.)
    //** @param(ARise The rise, up positive; limited to PAN_LIMIT either way.)
    //** @param(AVolume The volume the view is fitted to, whose width and height set how far
    //** the picture can slide.)
    //** @param(AWidth The view's width, in pixels.)
    //** @param(AHeight The view's height, in pixels.)
    procedure PlaceShift(const AEnabled: Boolean; const AShift, ARise: Single;
      const AVolume: TSweptVolume; const AWidth, AHeight: Single);
    //** @abstract(Takes the orthographic slide, FAppliedPan, off the orbit centre.)
    procedure TakeOffSlide;
    //** @abstract(In orthographic projection, slides the camera across the picture by FSlideX
    //** and FSlideY, from the orthographic size as it is now, and keeps how far in
    //** FAppliedPan.)
    //**
    //** Does nothing in perspective, where the slide is a lens shift, or with nothing to slide.
    //**
    //** @param(AWidth The view's width, in pixels.)
    //** @param(AHeight The view's height, in pixels.)
    procedure PutOnSlide(const AWidth, AHeight: Single);
    //** @abstract(Sets FProjection's lens shift and rise, only where they differ, as each
    //** change makes it repaint.)
    //**
    //** @param(AShiftX The shift, in normalised device units: the picture is 2 wide.)
    //** @param(AShiftY The rise, in normalised device units, up positive.)
    procedure SetLensShift(const AShiftX, AShiftY: Single);
    //** @abstract(Writes the view's shift and rise to the Debug tab, as asked for and as
    //** placed, when that differs from the line written last.)
    //**
    //** @param(AEnabled Whether the shift and rise are on.)
    //** @param(AShift The shift asked for, -1 to 1.)
    //** @param(ARise The rise asked for, -1 to 1.)
    procedure LogShift(const AEnabled: Boolean; const AShift, ARise: Single);
    //** @abstract(Puts the shift, rise and distance factor into FSettings as they are to be
    //** saved: as they are while FPanKeep, otherwise off, 0 and 1; and FPanKeep itself, as
    //** @code(keepShift).)
    procedure KeepShiftSettings;
    function CurrentCameraSpec: TCameraSettings;
    //** @abstract(What the view shows: CurrentCameraSpec with Mouse View's turn
    //** added to the azimuth and its zoom multiplied into the distance factor, for the
    //** Variable dialog to start from.)
    //**
    //** @returns(The angles, distance factor, shift and rise as shown.)
    function ShownCameraSpec: TCameraSettings;
    //** @abstract(Puts back a Mouse View turn and zoom that opening the Variable
    //** dialog took in, when the dialog is cancelled.)
    //**
    //** @param(AYaw The turn, in the camera's own degrees, as FMouseYaw.)
    //** @param(AZoom The zoom, as FMouseZoom; 1 with AYaw 0 puts nothing back.)
    //** @param(ASubject What the mouse view was of, as FMouseSubject.)
    procedure RestoreMouseView(const AYaw, AZoom: Single; const ASubject: String);
    procedure ShowCameraSpec(const ASpec: TCameraSettings);
    procedure AcceptCameraSpec(const ASpec: TCameraSettings);
    procedure RestoreCamera;
    procedure OrbitalDialogPreview(Sender: TObject);
    //** @abstract(The window's caption: the projection's name from View, Projection, with
    //** reminders when a shift or rise is in use or the camera is locked.)
    //**
    //** @returns(The caption.)
    function ProjectionCaption: String;
    //** @abstract(Carries out the Settings dialog's choices that changed and saves them.)
    //**
    //** @param(AOld The choices before the dialog.)
    //**
    //** @param(ANew The choices made.)
    procedure ApplyGeneralSettings(const AOld, ANew: TSprite3DGeneralSettings);
    //** @abstract(Sets a fixed view: every setting of the camera view to the view's own, then
    //** a refit.)
    //**
    //** The inclination and azimuth given, roll 0, and through ResetViewSettings the distance
    //** factor 1, no shift or rise, and no Mouse View turn or zoom: a fixed view is
    //** a starting point with set values, and anything changed after it is View, Camera,
    //** Variable's. The View menu checks are the caller's job.
    //**
    //** @param(APolarAngle The inclination, in degrees.)
    //** @param(AAzimuth The azimuth, in degrees, as the readouts show it.)
    procedure SetPolarViewAngle(const APolarAngle: Single;
      const AAzimuth: Single = 45);
    //** @abstract(Puts the settings a preset view does not name back to their own: the
    //** distance factor to 1, the shift and rise to 0, and Mouse View to the normal
    //** view.)
    //**
    //** For the fixed views and the oblique projections' angles. Only the values change: the
    //** caller turns the camera and refits, which shows them. The Shift and rise tick is left
    //** as it is, with nothing to slide. Does nothing while FRestoringView, as the start-up
    //** putting back the last session's view is not a choice of view.
    procedure ResetViewSettings;
    procedure ClearViewChecks;
    procedure SelectFixedView(const AItem: TMenuItem; const APolarAngle: Single;
      const AAzimuth: Single = 45);
    procedure RestoreViewToggles;
    //** @abstract(Puts the projection as View, Projection says, logs it in the Debug tab when
    //** it changes, sets the caption, and refits the level.)
    //**
    //** Perspective and Orthographic set the camera's ProjectionMode and leave FProjection
    //** drawing FMX's own; the oblique ones put the camera in perspective, which
    //** @code(TSpritelyProjection) starts from, and set FProjection's Kind. The camera's
    //** fits follow FProjection (it is OrbitCamera's Projection), so the level is framed in
    //** the projection actually drawn. While the camera is locked only the caption changes.
    procedure ApplyProjection;
    //** @abstract(Turns the camera to an oblique projection's own angles, with View, Camera,
    //** Variable checked; remembers the view before, the first time, in FObliqueView.)
    //**
    //** All three angles are set, whatever they were before: the azimuth and inclination
    //** from @code(TSpritelyProjection.PresetAngles), the roll 0, and an angle the preset does
    //** not use is 0 too. Cavalier and cabinet: 0, 0, 0 (level at the south face); military:
    //** azimuth 45, inclination 90 (from straight above, the plan turned to the south-west,
    //** as Isometric is); plan oblique: 0, 90, 0. The Debug tab gives all three.
    //**
    //** @param(AKind The oblique kind.)
    procedure EnterObliqueView(const AKind: TSpritelyProjectionKind);
    //** @abstract(Puts back the View, Camera view, and its angles, from before the oblique
    //** projections.)
    procedure LeaveObliqueView;
    //** @abstract(The View, Camera view checked, by its settings key; empty if none.)
    //**
    //** @returns(The key.)
    function CheckedCameraViewKey: String;
    //** @abstract(The projection View, Projection has ticked.)
    //**
    //** @returns(The projection; prPerspective if, somehow, none is ticked.)
    function CheckedProjection: TSprite3DProjection;
    //** @abstract(The View, Projection item for a projection.)
    //**
    //** @param(AProjection The projection.)
    //** @returns(Its menu item.)
    function ProjectionItem(const AProjection: TSprite3DProjection): TMenuItem;
    //** @abstract(Ticks the View, Projection item for a projection and unticks the other
    //** five.)
    //**
    //** FMX unticks only a radio item's siblings, and the oblique items are in ObliqueMenu,
    //** a level below Perspective and Orthographic, so ticking one alone would leave two
    //** ticked and CheckedProjection would read the first.
    //**
    //** @param(AProjection The projection to tick.)
    procedure CheckProjection(const AProjection: TSprite3DProjection);
    //** @abstract(Puts a line from FProjection in the Debug tab: where it found FMX's
    //** projection in a frame, or why it could not.)
    //**
    //** Queued, as FProjection calls it from inside a frame being drawn.
    //**
    //** @param(Sender FProjection.)
    //** @param(AText The line.)
    procedure ProjectionLog(Sender: TObject; const AText: string);
    //** @abstract(Puts the lights as HeadlightItem and OriginalLightItem say, and logs which
    //** are on in the Debug tab when that has changed.)
    //**
    //** The headlight through @code(OrbitCamera.Headlight), which makes or frees it; the
    //** original light by making it in GorillaLight, a point light on the camera at its
    //** origin, or freeing it.
    procedure ApplyLights;
    procedure ApplyShowBounds;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    {$ENDIF}
    procedure RestoreCameraView;
    procedure SaveViewState;
    function CameraViewKey(const AItem: TMenuItem): String;
    function CameraViewItem(const AKey: String): TMenuItem;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    procedure OrbitalDialogAccept(Sender: TObject);
    procedure OrbitalDialogCancel(Sender: TObject);
    procedure SettingsDialogAccept(Sender: TObject);
    {$ENDIF}
    procedure BuildLockCameraItem;
    procedure LockCameraItemClick(Sender: TObject);
    function CameraLocked: Boolean;
    function IsCameraViewItem(const AItem: TMenuItem): Boolean;
    procedure UpdateCameraLockControls;
    //** @abstract(Adds View, Camera, Mouse View, and hooks the mouse on the view.) Desktop
    //** only; called by BuildLockCameraItem, just before Lock Camera is added.
    procedure BuildMouseViewItem;
    //** @abstract(Ticks or unticks Mouse View, and keeps the tick in
    //** settings.json.) Unticking it puts the normal view back. The view takes the mouse
    //** only while it is ticked.
    procedure MouseViewItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks Mouse View, without saving it.)
    //** Unticked, the normal view is put back.
    //** @param(AOn True to tick it.)
    procedure ApplyMouseViewTick(const AOn: Boolean);
    //** @abstract(True while View, Camera, Mouse View is ticked.)
    function MouseViewOn: Boolean;
    //** @abstract(What the view shows, as far as the mouse view is concerned: the level.)
    //** Empty with no level.
    function MouseViewSubject: String;
    //** @abstract(Turns and zooms the camera, whether or not it is locked.)
    //** @param(AYaw Degrees added to the camera's Azimuth.)
    //** @param(AZoom The factor the distance, or the orthographic size, is multiplied by.)
    //** @param(AOrtho True to zoom the orthographic size, False the distance.)
    procedure ShiftCamera(const AYaw, AZoom: Single; const AOrtho: Boolean);
    //** @abstract(Moves the mouse view on by a turn and a zoom, from the mouse.)
    //** The zoom in all is kept within MOUSE_VIEW_ZOOM_MIN to MOUSE_VIEW_ZOOM_MAX. Nothing is
    //** done with no level, or while the mouse view is suspended.
    //** @param(AYaw Degrees added to the camera's Azimuth.)
    //** @param(AZoom The factor the zoom is multiplied by.)
    procedure MoveMouseView(const AYaw, AZoom: Single);
    //** @abstract(Mouse View's wheel or drag while Variable's dialog is open: the turn added
    //** to the dialog's azimuth and the zoom multiplied into its distance (0.2 to 20, the
    //** slider's range), its controls set to match, and the view showing it.)
    //**
    //** @param(AYaw The turn, in the camera's own degrees, as MoveMouseView takes it.)
    //** @param(AZoom The zoom, a factor on the distance, as MoveMouseView takes it.)
    procedure DialogMouseView(const AYaw, AZoom: Single);
    //** @abstract(Takes the mouse view off the camera, leaving the normal view, before code
    //** changes the normal view.) Each call is matched by ResumeMouseView; they nest.
    procedure SuspendMouseView;
    //** @abstract(Puts the mouse view back on the camera, on top of whatever the normal view
    //** now is, once every SuspendMouseView has been matched.)
    procedure ResumeMouseView;
    //** @abstract(Puts the normal view back and forgets the mouse view's turn and zoom.)
    procedure ResetMouseView;
    //** @abstract(Puts the normal view back if the view now shows another subject than the
    //** mouse view was started on; with one level, it always shows the same.) FitModel calls
    //** it, and so does ReadoutTimerTimer, a few times a second.
    procedure CheckMouseViewSubject;
    //** @abstract(Mouse view: the left button starts turning the view; the right, or a
    //** Control-click as elsewhere in Sprite3DBuilder, puts the normal view back.)
    procedure ViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Mouse view: while the left button is held, moving left or right turns the
    //** view.)
    procedure ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Mouse view: letting go of the left button stops turning the view.)
    procedure ViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Mouse view: the wheel moves the camera nearer or further.)
    procedure ViewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean);
    function ViewFpsLimit: Integer;
    procedure ApplyViewFps;
    procedure CheckDisplay;
    //** @abstract(Makes the level's root, FLevel, and its grid, FGrid.)
    procedure BuildLevel;
    //** @abstract(Makes the frame rate readout, top left over the view, and its timer.)
    procedure BuildFpsReadout;
    //** @abstract(Refreshes the frame rate readout, and checks the display.)
    //**
    //** @param(Sender FReadoutTimer.)
    procedure ReadoutTimerTimer(Sender: TObject);
    //** @abstract(The volume the view is fitted to: the middle of the level's floor,
    //** LEVEL_FRAME_CELLS cells across and LEVEL_FRAME_CELLS_HIGH high, swept about its
    //** centre.)
    //**
    //** @returns(The volume.)
    function ViewVolume: TSweptVolume;
    //** @abstract(The floor point under a point of the screen, if it is over the view and
    //** shows the floor.)
    //**
    //** Four floor points, LEVEL_FRAME_CELLS cells apart, are shown through the camera
    //** (ProjectToView) and the map of the view onto the floor solved from them
    //** (TSprite3DFloorMap), so it holds for every projection. The point found is shown again
    //** and must land within FLOOR_MAP_TOLERANCE pixels of the pointer, which rules out the
    //** sky in perspective, whose map points behind the camera.
    //**
    //** @param(AScreen The point, in screen coordinates.)
    //**
    //** @param(AOverView Set to True if it is over the view at all.)
    //**
    //** @param(AFloor Set to the floor's X and Z there, in its X and Y.)
    //**
    //** @returns(True if the floor is there.)
    function LevelFloorAt(const AScreen: TPointF; out AOverView: Boolean;
      out AFloor: TPointF): Boolean;
    //** @abstract(The boxes of every piece placed, where each lands.)
    //**
    //** @returns(The boxes, in the level's coordinates.)
    function PlacedBoxes: TArray<TBoundingBox>;
    //** @abstract(The model chosen in the Library: the one Place Model places, if it can be
    //** placed.)
    //**
    //** @param(ASpecs The models picked that can be placed, the one clicked first.)
    //**
    //** @param(ALeftOut The names of those picked that cannot be placed yet.)
    procedure ChooseModel(const ASpecs: TArray<TSprite3DPieceSpec>;
      const ALeftOut: TArray<String>);
    //** @abstract(What Place Model places, for the status bar and the Debug tab: the
    //** model's name, or the first's and how many more it picks among.)
    function BrushName: String;
    //** @abstract(True while Place Model is the palette's tool and Mouse View is off.)
    //**
    //** @returns(Whether the left button places.)
    function PlaceToolOn: Boolean;
    //** @abstract(True while Rotate is the palette's tool.)
    function RotateToolOn: Boolean;
    //** @abstract(True while Bend is the palette's tool.)
    function BendToolOn: Boolean;
    //** @abstract(Turns a vector across the level about its up axis, as FMX turns a child
    //** of
    //** the level by RotationAngle.Y.)
    //**
    //** @param(AVector The vector, in the level's coordinates; its Y is kept.)
    //**
    //** @param(ADegrees The turn.)
    //**
    //** @returns(The vector turned.)
    function TurnVector(const AVector: TPoint3D; const ADegrees: Single): TPoint3D;
    //** @abstract(A box turned about the up axis through its origin, squared up to the
    //** axes.)
    function TurnedBox(const ABox: TBoundingBox; const ADegrees: Single): TBoundingBox;
    //** @abstract(The middle of a piece's footprint, in the level, as X and Z.)
    function PieceMiddle(const APiece: TLevelPiece): TPointF;
    //** @abstract(The floor point, or the point at a height above it, under a point of the
    //** screen; LevelFloorAt at height 0.)
    function LevelPlaneAt(const AScreen: TPointF; const AHeight: Single;
      out AOverView: Boolean; out APoint: TPointF): Boolean;
    //** @abstract(The piece under a point of the screen: the nearest whose turned box the
    //** line of sight meets.)
    //**
    //** @returns(Its index in FPieces, or -1 for none.)
    function PieceAt(const AScreen: TPointF): Integer;
    //** @abstract(Gives an outline's control the size of the box it draws, so it is not
    //** passed over as out of sight while its box is in sight.)
    procedure FitOutline(const AOutline: TSprite3DPlacementBox);
    //** @abstract(Outlines a piece, the one under the pointer, or hides the outline.)
    //**
    //** @param(AIndex The piece's index in FPieces; -1 to hide it.)
    procedure ShowPick(const AIndex: Integer);
    //** @abstract(Starts turning a piece, with Rotate, or bending at it, with Bend.)
    //**
    //** @param(AIndex The piece pressed on, -1 for none.)
    //**
    //** @param(AReversed With Bend, True for the right button: the piece and those to its
    //** left turn, about its join with the piece to its right.)
    //**
    //** @param(AX Where the pointer is, across the view.)
    //**
    //** @param(AButton The button pressed, which must stay held.)
    //**
    //** @returns(True if a turn started.)
    function StartTurn(const AIndex: Integer; const AReversed: Boolean; const AX: Single;
      const AButton: TMouseButton): Boolean;
    //** @abstract(Turns the pieces being turned by ADegrees from where they were.)
    procedure ApplyTurn(const ADegrees: Single);
    //** @abstract(Ends a turn: Rotate puts a piece left square to the grid back on it.)
    procedure EndTurn;
    //** @abstract(Begins (True) or ends (False) editing every template's instances, so they
    //** go to the GPU once.)
    procedure EditInstances(const ABegin: Boolean);
    //** @abstract(Chooses one of the palette's tools that change the level, turning Mouse
    //** View off.)
    procedure ChooseEditTool(const ATool: TLevelEditTool);
    //** @abstract(Says in the Debug tab what the tool now on does.)
    procedure LogEditTool;
    //** @abstract(The status bar's text for Rotate and Bend.)
    function TurnStatus: String;
    //** @abstract(Shows the Rotation Snap dialog and keeps the step chosen.)
    procedure ShowRotationSnap;
    //** @abstract(Chooses Rotate.)
    procedure RotateButtonClick(Sender: TObject);
    //** @abstract(Chooses Bend.)
    procedure BendButtonClick(Sender: TObject);
    //** @abstract(A double-click on Rotate or Bend: chooses it and shows Rotation Snap.)
    procedure TurnButtonDblClick(Sender: TObject);
    //** @abstract(File, Rotation Snap...: shows the Rotation Snap dialog.)
    procedure RotationSnapItemClick(Sender: TObject);
    //** @abstract(True while Erase is the palette's tool.)
    function EraseToolOn: Boolean;
    //** @abstract(True while Move Object is the palette's tool.)
    function MoveToolOn: Boolean;
    //** @abstract(True while Move Camera is the palette's tool.)
    function PanToolOn: Boolean;
    //** @abstract(True while a tool that points at pieces is on: Erase, Move Object, Rotate,
    //** Bend or Variants.)
    function PickToolOn: Boolean;
    //** @abstract(True while Variants is the palette's tool.)
    function VariantToolOn: Boolean;
    //** @abstract(Chooses Variants.)
    //**
    //** @param(Sender FVariantButton.)
    procedure VariantButtonClick(Sender: TObject);
    //** @abstract(The names of the material variants of a piece's model, read from its file
    //** once and kept in FVariantNames.)
    //**
    //** @param(ASpec The piece's spec.)
    //**
    //** @returns(The names; empty for a model without.)
    function VariantNamesOf(const ASpec: TSprite3DPieceSpec): TArray<String>;
    //** @abstract(The key FSources keeps a template by: the model's key, and its variant's
    //** name if it has one, as each variant is a template of its own.)
    //**
    //** @param(ASpec The spec.)
    //**
    //** @returns(The key.)
    function SourceKey(const ASpec: TSprite3DPieceSpec): String;
    //** @abstract(Puts an outline round every piece whose model has variants while Variants is
    //** the tool, and takes them away otherwise.)
    procedure RefreshVariantMarks;
    //** @abstract(Shows the Variants tool's menu for a piece: the base and its model's
    //** variants, the one it is ticked.)
    //**
    //** @param(AIndex The piece, an index into FPieces.)
    //**
    //** @param(AAll True to change every piece of its model.)
    //**
    //** @param(AScreen Where the menu goes, in screen coordinates.)
    procedure ShowPieceVariantMenu(const AIndex: Integer; const AAll: Boolean;
      const AScreen: TPointF);
    //** @abstract(The Variants tool's menu's choice: the piece, or every piece of its model,
    //** made that variant.)
    //**
    //** @param(Sender A menu item; its TagString is the variant's name, empty for the base.)
    procedure PieceVariantItemClick(Sender: TObject);
    //** @abstract(Makes pieces a variant: each is drawn by that variant's template from now
    //** on, where it is, turned as it is. A piece still falling is left as it is.)
    //**
    //** @param(AIndices The pieces, indices into FPieces, all of one model.)
    //**
    //** @param(AVariantName The variant's name; empty for the base.)
    procedure SetPiecesVariant(const AIndices: TArray<Integer>; const AVariantName: String);
    //** @abstract(Chooses Erase.)
    procedure EraseButtonClick(Sender: TObject);
    //** @abstract(Chooses Move Object.)
    procedure MoveButtonClick(Sender: TObject);
    //** @abstract(Chooses Move Camera.)
    procedure PanButtonClick(Sender: TObject);
    //** @abstract(The indices in FPieces of the pieces numbered AIds that are still there.)
    function IndicesOf(const AIds: TArray<Integer>): TArray<Integer>;
    //** @abstract(Takes pieces out of the level, then lets whatever rested on them fall.)
    //**
    //** @param(AIndices Their indices in FPieces, in any order.)
    procedure RemovePieces(const AIndices: TArray<Integer>);
    //** @abstract(Lets a piece go, before RemovePieces drops it from FPieces: its instance
    //** is freed; the model's template stays, parked and loaded. AGone, the pieces going, is
    //** not needed now that no piece is a template, and kept for the caller's sake.)
    procedure ReleasePiece(const AIndex: Integer; const AGone: TArray<Boolean>);
    //** @abstract(Lets every piece over a part of the floor, with nothing under it now,
    //** fall onto what is, lowest first; a piece that falls adds its footprint to the part,
    //** so what rested on it falls too.)
    //**
    //** @param(ARegion The part of the floor, X and Z, where something was taken away.)
    procedure SettlePieces(const ARegion: TRectF);
    //** @abstract(The pieces resting on a piece, on those, and so on up.)
    function RidersOf(const AIndex: Integer): TArray<Integer>;
    //** @abstract(Starts Move Object on a piece.)
    function StartMove(const AIndex: Integer; const AScreen: TPointF): Boolean;
    //** @abstract(Moves the piece being moved under a point of the screen.)
    procedure TrackMove(const AScreen: TPointF; const AFree: Boolean);
    //** @abstract(Ends Move Object: what rested on the piece falls.)
    procedure EndMove;
    //** @abstract(Move Camera: slides the view so the floor point grabbed comes back under
    //** a point of the screen.)
    procedure TrackPan(const AScreen: TPointF);
    //** @abstract(Moves FViewCentre, and the camera with it, across the level.)
    procedure MoveViewCentre(const ADelta: TPointF);
    //** @abstract(Puts the view's centre back on the level's middle and refits.)
    procedure ResetViewCentre;
    //** @abstract(Makes the history panel.)
    procedure BuildHistory;
    //** @abstract(Adds a line to the history for pieces just placed.)
    procedure AddHistory(const AName: String; const AIds: TArray<Integer>);
    //** @abstract(Takes pieces gone from the level off the history, and drops empty lines.)
    procedure PruneHistory;
    //** @abstract(Lays out the history panel's lines again.)
    procedure ShowHistory;
    //** @abstract(A history line's remove button: takes its pieces out of the level.)
    procedure HistoryRemoveClick(Sender: TObject);
    //** @abstract(Keeps one floating panel inside the view.)
    procedure KeepPanelInView(const APanel: TControl);
    //** @abstract(Edit, Undo: takes out the pieces of the last addition, the newest history
    //** line.)
    procedure UndoItemClick(Sender: TObject);
    //** @abstract(Edit, Reset Level: asks, then takes every piece out, leaving the empty
    //** grid.)
    procedure ResetLevelItemClick(Sender: TObject);
    //** @abstract(Adds File, Load Level..., Save Level and Save Level As... at the top of
    //** the File menu.)
    procedure BuildLevelFileItems;
    //** @abstract(Notes the level has changed since it was saved or loaded.)
    procedure MarkLevelChanged;
    //** @abstract(The window's title: the level's name, with * while it has changes not
    //** saved, then the projection.)
    procedure UpdateCaption;
    //** @abstract(The level's file name, or Untitled.)
    function LevelName: String;
    //** @abstract(Writes the level, every piece and the history, to a level file.)
    //**
    //** @returns(True if it was written.)
    function SaveLevelTo(const AFileName: String): Boolean;
    //** @abstract(Saves to the level's file, asking for one if it has none.)
    function SaveLevel: Boolean;
    //** @abstract(Asks for a file and saves the level to it.)
    function SaveLevelAs: Boolean;
    //** @abstract(Replaces the level with one read from a level file: its pieces where they
    //** were, turned as they were, and its history.)
    //**
    //** @returns(True if it was read; a piece whose model cannot be loaded is left out, and
    //** the Debug tab says so.)
    function LoadLevelFile(const AFileName: String): Boolean;
    //** @abstract(Does AThen once the level's changes, if any, have been saved or let go:
    //** asks
    //** Save, Don't Save or Cancel; Cancel does nothing.)
    procedure AskToKeepLevel(const AThen: TProc);
    //** @abstract(File, Load Level...: the level's changes seen to, then a level file
    //** chosen and loaded.)
    procedure LoadLevelItemClick(Sender: TObject);
    //** @abstract(File, Save Level: SaveLevel.)
    procedure SaveLevelItemClick(Sender: TObject);
    //** @abstract(File, Save Level As...: SaveLevelAs.)
    procedure SaveLevelAsItemClick(Sender: TObject);
    //** @abstract(A file the system asks Sprite3DBuilder to open, as by Open With or a
    //** double-click on a level file: loads it, once the level's changes are seen to.)
    procedure OpenRequestedFile(const AFileName: String);
    //** @abstract(View, History: shows or hides the history panel.)
    procedure HistoryItemClick(Sender: TObject);
    //** @abstract(Puts the palette and the history where settings.json says, or where they
    //** start the first time: the palette top left, the history top right. Queued from
    //** FormCreate, so the view has its size.)
    procedure PlacePanels;
    //** @abstract(Keeps the windows' places, the panels' and whether the history is shown
    //** in FSettings, for SaveViewState to save.)
    procedure KeepPlaces;
    //** @abstract(Moves a panel with the view's right or bottom edge, if it is nearer that
    //** edge, as the view changes size.)
    procedure AnchorPanel(const APanel: TControl; const AOld, ANew: TSizeF);
    //** @abstract(Where the model chosen would go for a point of the screen: the floor
    //** point
    //** under it, snapped to the grid for the model's footprint.)
    //**
    //** @param(AScreen The point, in screen coordinates.)
    //**
    //** @param(ASpot Set to the model's origin's X and Z, in X and Y.)
    //**
    //** @returns(False if no model is chosen or the floor is not there.)
    function PlaceSpotAt(const AScreen: TPointF; out ASpot: TPointF): Boolean;
    //** @abstract(The spots of an area of the model chosen, repeated from one spot to
    //** another.)
    //**
    //** Each step is the model's footprint in whole cells (its size over the grid's,
    //** rounded, at least 1), so the copies lie edge to edge. At most MAX_AREA_PIECES: past
    //** that the longer side is cut, and the Debug tab says so once.
    //**
    //** @param(AFrom The spot the area started at.)
    //**
    //** @param(ATo The spot under the pointer.)
    //**
    //** @returns(The spots, row by row.)
    function AreaSpots(const AFrom, ATo: TPointF): TArray<TPointF>;
    //** @abstract(Shows where the model chosen would rest at each of ASpots: one box round
    //** them all, at the height of the highest piece under any of them, or the floor.)
    //**
    //** @param(ASpots The spots, as AreaSpots or PlaceSpotAt give them.)
    procedure ShowPlacement(const ASpots: TArray<TPointF>);
    //** @abstract(Hides the box.)
    procedure HidePlacement;
    //** @abstract(Shows the box for the pointer as it is, with the button up or held.)
    //**
    //** @param(AScreen The pointer, in screen coordinates.)
    procedure TrackPlacement(const AScreen: TPointF);
    //** @abstract(Places the model chosen at every spot shown, and lets them fall into the
    //** box.)
    procedure PlaceShown;
    //** @abstract(Adds a piece of a model to the level, loaded as the Library loads a
    //** model,
    //** and lets it fall.)
    //**
    //** Each piece is a model of its own, made with @code(TGorillaModel.Create) and loaded
    //** with its own @code(LoadFromFile), so it owns its definition and can be freed alone:
    //** never with the @code(LoadNewModelFrom...) class functions (see the handover's Gorilla3D
    //** notes).
    //**
    //** @param(ASpec The model.)
    //**
    //** @param(ASource What PieceSourceFor found for it.)
    //**
    //** @param(AFrom Where its origin starts, in the level's coordinates.)
    //**
    //** @param(ALand The height its origin lands at.)
    //**
    //** @returns(False, the Debug tab saying why, if it could not be made.)
    procedure MovePiece(const APiece: TLevelPiece; const AY: Single);
    //** @abstract(Places one piece of ASpec: a GPU instance of ASource's template, at
    //** AFrom, to fall to height ALand; False if it could not be added.)
    function PlacePiece(const ASpec: TSprite3DPieceSpec; var ASource: TPieceSource;
      const AFrom: TPoint3D; const ALand: Single): Boolean;
    //** @abstract(Frees every piece placed, before the form frees its children, with the
    //** fall
    //** timer stopped.)
    procedure FreeLevelPieces;
    //** @abstract(Makes the palette: the floating toolbar over the view.)
    procedure BuildPalette;
    //** @abstract(Makes the status bar along the bottom of the form.)
    procedure BuildStatusBar;
    //** @abstract(Says in the status bar which tool is on, the model it places, and what
    //** the mouse does: while an area is dragged, its size.)
    procedure UpdateStatus;
    //** @abstract(What placing a model needs, found once: its textures fixed (the file to
    //** load) and whether it is static, from loading it once as the Library does.)
    //**
    //** @param(ASpec The model.)
    //**
    //** @param(ASource Set to what was found.)
    //**
    //** @returns(False, the Debug tab saying why, if it could not be loaded.)
    function PieceSourceFor(const ASpec: TSprite3DPieceSpec;
      out ASource: TPieceSource): Boolean;
    //** @abstract(Shows which tool is on and the model chosen, on the palette.)
    procedure UpdatePalette;
    //** @abstract(Keeps the palette inside the view, as the view is resized.)
    procedure KeepPaletteInView;
    //** @abstract(Chooses the palette's tool: Mouse View, or Place Model; ticks View, Mouse
    //** View to match, keeps it in settings.json and says so in the Debug tab.)
    //**
    //** @param(AMouseView True for Mouse View, False for Place Model.)
    procedure ChooseTool(const AMouseView: Boolean);
    //** @abstract(Chooses Place Model.)
    //**
    //** @param(Sender FPlaceButton.)
    procedure PlaceButtonClick(Sender: TObject);
    //** @abstract(Chooses Mouse View.)
    //**
    //** @param(Sender FCameraButton.)
    procedure CameraButtonClick(Sender: TObject);
    //** @abstract(Starts moving the palette.)
    //**
    //** @param(Sender FPaletteGrip.)
    //**
    //** @param(Button The button pressed.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the grip.)
    //**
    //** @param(Y Where, down the grip.)
    procedure PaletteGripMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Moves the palette with the pointer, inside the view.)
    //**
    //** @param(Sender FPaletteGrip.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the grip.)
    //**
    //** @param(Y Where, down the grip.)
    procedure PaletteGripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Stops moving the palette.)
    //**
    //** @param(Sender FPaletteGrip.)
    //**
    //** @param(Button The button let go.)
    //**
    //** @param(Shift The keys and buttons held.)
    //**
    //** @param(X Where, across the grip.)
    //**
    //** @param(Y Where, down the grip.)
    procedure PaletteGripMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Hides the box as the pointer leaves the view, unless an area is being
    //** dragged.)
    //**
    //** @param(Sender AspectLayout.)
    procedure ViewMouseLeave(Sender: TObject);
    //** @abstract(Moves each falling piece down, under gravity, until it lands.)
    //**
    //** @param(Sender FFallTimer.)
    procedure FallTimerTimer(Sender: TObject);
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
    //** Linux only: the menu bar FMX draws itself, holding copies of MainMenu1's items, as
    //** the native GTK menu bar showed only each item's first letter. Made by UseFmxMenuBar.
    FDesktopMenuBar: TMenuBar;
    //** @abstract(Linux only: replaces MainMenu1 with FDesktopMenuBar.)
    //** Copies every item of MainMenu1, with its submenus, onto a new TMenuBar, frees the
    //** originals one at a time and then MainMenu1, and gives each copy its original's name,
    //** which points the form's published field at the copy. The items are copied rather
    //** than moved because each holds a handle to the GTK widget FMX has already made for
    //** it, which freeing MainMenu1 destroys; a moved item's next change then reached a
    //** destroyed widget (GTK-CRITICAL warnings, or a crash). It must be the first thing
    //** FormCreate does, before any menu item is changed, added or kept in a private field.
    procedure UseFmxMenuBar;
    {$ENDIF}
  public
    { Public declarations }
  end;

var
  //** @abstract(The main form, created by Application.CreateForm in Sprite3DBuilder.dpr.)
  MainForm: TMainForm;

implementation

uses
  FMX.Platform, System.IOUtils, OSPaths, Gorilla.DefTypes, System.Math,
  FMX.DialogService, Sprite3DBuilderLicencesForm, System.StrUtils, Sprite3DModelTextures,
  Sprite3DModelContent, Sprite3DBuilderRotationForm, System.Generics.Defaults, System.JSON,
  JsonText, Sprite3DOpenFiles, Sprite3DModelVariants;

const
  //** @abstract(Mouse View: degrees the view turns for each pixel the pointer
  //** moves left or right with the left button held; a full turn is 720 pixels.)
  MOUSE_VIEW_DEGREES_PER_PIXEL = 0.5;
  //** @abstract(Mouse View: the factor one notch of the wheel moves the camera
  //** nearer or further by.)
  MOUSE_VIEW_ZOOM_STEP = 1.1;
  //** @abstract(Mouse View: the nearest the wheel brings the camera, as a factor
  //** of the normal view's distance or orthographic size.)
  MOUSE_VIEW_ZOOM_MIN = 0.2;
  //** @abstract(Mouse View: the furthest the wheel takes the camera, as a factor
  //** of the normal view's distance or orthographic size.)
  MOUSE_VIEW_ZOOM_MAX = 10.0;

{$R *.fmx}

var
  // Set as the main form is destroyed, for work queued from other threads
  // that may arrive after it has gone
  MainFormGone: Boolean = False;

const
  // How often the frame rate readout is refreshed, in milliseconds
  READOUT_INTERVAL_MS = 100;
  // The area the view is fitted to at the start: this many grid cells each
  // way across the floor, and this many cells high, about a wall's height
  // in a kit whose walls are two cells tall
  LEVEL_FRAME_CELLS = 10;
  LEVEL_FRAME_CELLS_HIGH = 2;
  //** @abstract(How far above where it rests a piece let go starts its fall, in grid cells:
  //** just enough to see it settle. The box shown while dragging is where it rests.)
  PLACE_LIFT_CELLS = 0.25;
  //** @abstract(Gravity, in grid cells per second per second, so a fall looks the same at
  //** any grid spacing; the fall of PLACE_LIFT_CELLS takes about a tenth of a second.)
  FALL_GRAVITY_CELLS = 40;
  //** @abstract(How often the falling pieces are moved, in milliseconds.)
  FALL_STEP_MS = 15;
  //** @abstract(How near, in pixels, the floor point found must show to the pointer.)
  FLOOR_MAP_TOLERANCE = 1.5;
  //** @abstract(The colour of the box shown where a piece would go: light cyan, apart from
  //** Gorilla's orange bounding boxes. Also the edge of the palette's tool that is on.)
  PLACE_BOX_COLOUR = $FF40E0F0;
  //** @abstract(The most pieces one click and drag places: 100 by 100. Once every piece
  //** loaded its model, at about 170 ms a piece, and an area held 256; GPU instances cost
  //** almost nothing each.)
  MAX_AREA_PIECES = 10000;
  //** @abstract(The palette's buttons, square, in pixels; its grip's height; and the gap
  //** between its parts.)
  PALETTE_BUTTON = 32;
  PALETTE_GRIP = 10;
  PALETTE_GAP = 4;
  //** @abstract(The Place Model icon, as FMX path data in a 24 by 24 square: an arrow
  //** coming
  //** down onto a cube.)
  PLACE_MODEL_ICON = 'M12,1 L12,9 M8.5,5.5 L12,9 L15.5,5.5 ' +
    'M12,11 L20,15 L12,19 L4,15 Z M4,15 L4,20 L12,24 L20,20 L20,15 M12,19 L12,24';
  //** @abstract(The Mouse View icon, as path data in a 24 by 24 square: a small camera with
  //** an arrow circling round it, as Mouse View turns the view about the level.)
  MOUSE_VIEW_ICON = 'M8,10.5 L10,10.5 L11,9 L13,9 L14,10.5 L16,10.5 L16,15 L8,15 Z ' +
    'M2.5,13 C2.5,7.5 6.8,4 12,4 C17.2,4 21.5,7.5 21.5,13 M19.3,11 L21.5,13.6 L23.6,11 ' +
    'M21.5,15.5 C20.5,18.6 16.6,21 12,21 C7.4,21 3.5,18.6 2.5,15.5';
  //** @abstract(The Rotate icon, as path data in a 24 by 24 square: a circling arrow round
  //** a
  //** square seen from above.)
  ROTATE_ICON = 'M20,12 C20,16.42 16.42,20 12,20 C7.58,20 4,16.42 4,12 ' +
    'C4,7.58 7.58,4 12,4 C14.5,4 16.7,5.1 18.2,6.9 M18.6,2.5 L18.4,7.2 L13.8,7.0 ' +
    'M9,9 L15,9 L15,15 L9,15 Z';
  //** @abstract(The Bend icon, as path data in a 24 by 24 square: a run of wall bent at a
  //** hinge, with an arc for the turn.)
  BEND_ICON = 'M1,17 L11,17 L11,21 L1,21 Z M11,17 L18,10 L21,13 L13.8,20.2 ' +
    'M13,19 C13,20.1 12.1,21 11,21 C9.9,21 9,20.1 9,19 C9,17.9 9.9,17 11,17 ' +
    'C12.1,17 13,17.9 13,19 Z M17,17 C17,15.6 16.5,14.3 15.6,13.3';
  //** @abstract(The colour of the outline round the piece Move Object, Rotate or Bend would
  //** take: amber.)
  PICK_BOX_COLOUR = $FFFFB020;
  //** @abstract(The colour of the outline round the piece Erase would remove: red.)
  ERASE_BOX_COLOUR = $FFFF4040;
  //** @abstract(The colour of the outline round the piece the Variants tool would change:
  //** green.)
  VARIANT_PICK_COLOUR = $FF40F070;
  //** @abstract(The colour of the outlines round every piece with variants while Variants is
  //** the tool: a darker green.)
  VARIANT_MARK_COLOUR = $FF208048;
  //** @abstract(How many pieces with variants are outlined at most, so a level of thousands
  //** stays quick; the rest are still found by pointing at them.)
  MAX_VARIANT_MARKS = 500;
  //** @abstract(The Variants icon, as path data in a 24 by 24 square: two overlapping
  //** swatches.)
  VARIANT_ICON = 'M2,2 L14,2 L14,14 L2,14 Z M10,10 L22,10 L22,22 L10,22 Z M10,14 L14,14 ' +
    'L14,10';
  //** @abstract(The Erase icon, as path data in a 24 by 24 square: an eraser on a line.)
  ERASE_ICON = 'M3,15 L13,5 L21,13 L13,21 L9,21 Z M8,10 L16,18 M2,23 L22,23';
  //** @abstract(The Move Object icon: a cube with arrows out to the four sides.)
  MOVE_OBJECT_ICON = 'M12,8 L16,10 L12,12 L8,10 Z M8,10 L8,14 L12,16 L16,14 L16,10 ' +
    'M12,12 L12,16 M12,6 L12,1 M10,3 L12,1 L14,3 M12,18 L12,23 M10,21 L12,23 L14,21 ' +
    'M6,12 L1,12 M3,10 L1,12 L3,14 M18,12 L23,12 M21,10 L23,12 L21,14';
  //** @abstract(The Move Camera icon: a small camera with arrows out to the four sides.)
  MOVE_CAMERA_ICON = 'M7,10 L9,10 L10,8.5 L14,8.5 L15,10 L17,10 L17,16 L7,16 Z ' +
    'M12,6 L12,1 M10,3 L12,1 L14,3 M12,18 L12,23 M10,21 L12,23 L14,21 ' +
    'M5,13 L1,13 M3,11 L1,13 L3,15 M19,13 L23,13 M21,11 L23,13 L21,15';
  //** @abstract(The most lines the history keeps.)
  HISTORY_MAX = 50;
  //** @abstract(The history panel's width, and the height of a line, in pixels.)
  HISTORY_WIDTH = 210;
  HISTORY_LINE = 24;
  //** @abstract(Where a model's template is kept, in the level, far below the floor, out of
  //** sight: every piece is a GPU instance of it, and Gorilla draws it too, as instance #0.)
  TEMPLATE_PARK_Y = -100000;
  //** @abstract(Rotate and Bend: degrees a piece turns for each pixel the pointer moves
  //** left
  //** or right, as Mouse View turns the view.)
  TURN_DEGREES_PER_PIXEL = 0.5;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  {$IF DEFINED(LINUX) and not DEFINED(ANDROID)}
  // Before any menu item is changed, added or remembered; see UseFmxMenuBar
  UseFmxMenuBar;
  {$ENDIF}

  // The Library's error log holds this session's errors only
  TAssetsForm.BeginErrorLog;

  // The Level tab first, with the view on it
  TabControl1.ActiveTab := LevelTab;

  FAzimuth := 0;
  FRoll := 0;
  FPolarAngle := 0;
  FFactor := 1.0;

  GorillaViewport := TGorillaViewport.Create(AspectLayout);
  GorillaViewport.Parent := AspectLayout;
  // The view fills the tab: there are no grabs
  // whose shape it would have to keep
  GorillaViewport.Align := TAlignLayout.Client;
  GorillaViewport.OnResize := GorillaViewportResize;
  GorillaViewport.UseFixedFrameRate := true;
  GorillaViewport.VSync := False;
  GorillaViewport.HitTest := False;
  GorillaViewport.FixedFrameRate := 60;
//  GorillaViewport.DiagnosticsActive := true;
  // OrbitCamera, on the form, builds the camera in the viewport and makes it
  // the viewport's camera (turning UsingDesignCamera off). The camera is the
  // viewport's, freed with it; the rest of the form works on it through
  // GorillaCamera. The lights, OrbitCamera's headlight and the original
  // light, are put as View, Lights says by RestoreViewToggles, below: until
  // then only the headlight, as the item starts ticked.
  OrbitCamera.Headlight := HeadlightItem.IsChecked;
  OrbitCamera.FOV := 45;
  OrbitCamera.Viewport := GorillaViewport;
  GorillaCamera := OrbitCamera.Camera;
  // The oblique projections of View, Projection: made in code, as a new
  // component is first; ApplyProjection, from RestoreViewToggles below, sets
  // its Kind. The camera's angles stay View, Camera's (no preset), and a
  // lens change never moves the camera (no dolly). OrbitCamera's Projection
  // makes the camera's fits follow it; its Viewport is set here, as that
  // does not set it.
  FLoggedProjection := -1;
  FProjection := TSpritelyProjection.Create(Self);
  FProjection.CameraPreset := False;
  FProjection.Dolly := False;
  FProjection.Kind := pjPerspective;
  FProjection.OnLog := ProjectionLog;
  FProjection.Viewport := GorillaViewport;
  OrbitCamera.Projection := FProjection;
  GorillaLight := nil;

  // Settings from earlier sessions; on the first run, the defaults
  FSettings := TSprite3DAppSettings.Create;
  FSettings.Load;
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  // Where it was last session, on the monitor it was on, kept on a monitor
  // that is there and within its work area
  PlaceFormOnScreen(Self, FSettings.MainLeft, FSettings.MainTop, FSettings.MainWidth,
    FSettings.MainHeight, FSettings.MainMaximized);
  {$ENDIF}
  // The normal view: no mouse view turn or zoom
  FMouseZoom := 1;
  // The frame rate the view is drawn at, as chosen in File, Settings, within
  // what the display can show
  FDisplayIndex := -1;
  ApplyViewFps;
  // The look chosen in File, Settings; FMX's default needs nothing doing
  if FSettings.ThemeKind <> thDefault then
  begin
    var ThemeError: String;
    if not ApplyTheme(FSettings.ThemeKind, ThemeError) then
      DebugMemo.Lines.Add(ThemeError);
  end;
  // The shift, rise and distance, applied after every fit from here on: from
  // the last session only when it asked for them to be kept, otherwise no
  // shift or rise, at the fitted distance
  FPanKeep := FSettings.KeepShift;
  if FPanKeep then
  begin
    FPanEnabled := FSettings.PanEnabled;
    FPanX := EnsureRange(FSettings.PanX, -PAN_LIMIT, PAN_LIMIT);
    FPanZ := EnsureRange(FSettings.PanZ, -PAN_LIMIT, PAN_LIMIT);
    if FSettings.DistanceFactor > 0 then
      FFactor := FSettings.DistanceFactor;
  end;
  AspectLayout.HitTest := False;

  // The empty level, with its grid, before the view is put back, which
  // frames it
  BuildLevel;

  // The camera view as it was left last session; Isometric the first time.
  // Its handlers, and an oblique projection's below, would reset the
  // distance, shift and rise loaded above, as choosing a view does: not when
  // putting back the last session's
  FRestoringView := True;
  try
    RestoreCameraView;

    // The View menu's on/off items as they were left last session
    RestoreViewToggles;
  finally
    FRestoringView := False;
  end;

  // Frames per second, top left over the view
  BuildFpsReadout;

  // View, Camera, Lock Camera; before the menu is mirrored on mobile. On
  // Linux the menu bar has already been swapped, so it goes straight onto it
  BuildLockCameraItem;

  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  // The palette, over the view, once Mouse View, one of its tools, is made;
  // desktop only, as the Library its models come from is
  BuildPalette;
  BuildHistory;
  BuildStatusBar;
  BuildLevelFileItems;
  // Once the window is shown at its size, so places kept for a larger view
  // are not pulled in first; then a level the system asked to open, as by a
  // double-click on it, and later ones as they come
  TThread.ForceQueue(nil,
    procedure
    begin
      PlacePanels;
      if MainFormGone then
        Exit;
      for var Request in FileOpenRequests.TakePending do
        if IsLevelFile(Request) then
        begin
          LoadLevelFile(Request);
          Break;
        end;
      FileOpenRequests.OnOpenFile := OpenRequestedFile;
    end);
  // Level files open with this copy of the program; off the main thread,
  // as on Linux it runs the system's database updates
  TTask.Run(
    procedure
    var
      Note: String;
    begin
      if not RegisterLevelFiles(Note) then
        TThread.Queue(nil,
          procedure
          begin
            if not MainFormGone then
              DebugMemo.Lines.Add('Can''t associate ' + LEVEL_FILE_EXTENSION +
                ' files with Sprite3DBuilder: ' + Note);
          end);
    end);
  {$ENDIF}

  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  // There is no folder dialog there to add collections with, so no
  // Library, nor a cache of its thumbnails to clear
  LibraryItem.Free;
  ClearLibraryItem.Free;
  CheckThumbnailsItem.Free;
  // Built from the finished menus, so it comes after every item is added
  BuildMobileMenu;
  {$ENDIF}
end;

{$IF DEFINED(LINUX) and not DEFINED(ANDROID)}
// The native GTK menu bar FMX uses on Linux showed only the first letter of
// each item, so MainMenu1 is replaced by a TMenuBar, which FMX draws itself
// in the form's style.
//
// The items are COPIED, not moved, and this must stay so. By the time
// FormCreate runs, FMX has already made the GTK menu from MainMenu1, and
// every item holds a handle to its GTK widget. Freeing MainMenu1 destroys
// those widgets, so an item moved onto the bar beforehand kept a handle to a
// destroyed widget, and its next change (Enabled, IsChecked, Text, Visible)
// made FMX update it: GLib-GObject-CRITICAL and Gtk-CRITICAL warnings at
// start-up, or an access violation in libgobject-2.0.so.0. The copies are
// new objects that GTK has never seen.
//
// The originals are then freed one at a time while MainMenu1 still exists:
// each removal makes FMX rebuild the GTK bar without that item, so it ends
// up empty and goes. Freeing MainMenu1 with its items still in it would
// leave GTK's bar of first letters showing above the TMenuBar. As each
// original is freed, Delphi sets the form's field of that name to nil and
// the name becomes free, so once MainMenu1 is gone each copy takes its
// original's name, which points the form's published field at the copy, and
// every handler and tick in the form carries on working unchanged.
//
// So this must run first in FormCreate, before any menu item is changed,
// added or remembered in a private field: a reference taken before it would
// be left pointing at a freed original. Items added later go in through the
// published fields, so straight onto the TMenuBar.
procedure TMainForm.UseFmxMenuBar;
var
  Copies: TArray<TMenuItem>;
  Names: TArray<String>;
  I: Integer;

  //** @abstract(Puts a copy of AItem, with copies of its submenus, in AParent.)
  //** The copy is owned by the form, so naming it afterwards sets the form's field of that
  //** name; it is added to Copies, and AItem's name to Names, for UseFmxMenuBar to do so.
  //** Every TMenuItem property Sprite3DBuilderMain.fmx sets is copied (Text, Enabled, IsChecked,
  //** RadioItem, GroupIndex and OnClick; Locked is design-time only), and a few more for
  //** safety: add any other property the form comes to use.
  //** @param(AItem The designed item to copy.)
  //** @param(AParent The menu bar or menu item the copy goes in.)
  procedure CopyItem(const AItem: TMenuItem; const AParent: TFmxObject);
  var
    Clone: TMenuItem;
    J: Integer;
  begin
    Clone := TMenuItem.Create(Self);
    Clone.Text := AItem.Text;
    Clone.Enabled := AItem.Enabled;
    Clone.Visible := AItem.Visible;
    Clone.AutoCheck := AItem.AutoCheck;
    Clone.IsChecked := AItem.IsChecked;
    Clone.RadioItem := AItem.RadioItem;
    Clone.GroupIndex := AItem.GroupIndex;
    Clone.ShortCut := AItem.ShortCut;
    Clone.Tag := AItem.Tag;
    Clone.Hint := AItem.Hint;
    Clone.OnClick := AItem.OnClick;
    Clone.Parent := AParent;
    Copies := Copies + [Clone];
    Names := Names + [AItem.Name];
    for J := 0 to AItem.ItemsCount - 1 do
      CopyItem(AItem.Items[J], Clone);
  end;

begin
  FDesktopMenuBar := TMenuBar.Create(Self);
  FDesktopMenuBar.Parent := Self;
  // Top-aligned controls are laid out in the order of their positions: this
  // keeps the menu bar above any other top-aligned control
  FDesktopMenuBar.Position.Y := -1;
  FDesktopMenuBar.Align := TAlignLayout.Top;
  for I := 0 to MainMenu1.ItemsCount - 1 do
    if MainMenu1.Items[I] is TMenuItem then
      CopyItem(TMenuItem(MainMenu1.Items[I]), FDesktopMenuBar);

  // Item by item, so FMX rebuilds the GTK bar after each and it ends up empty
  // and gone; never free MainMenu1 with items still in it, nor move the
  // originals instead of copying them (see above). Each original's field is
  // set to nil as it is freed.
  while MainMenu1.ItemsCount > 0 do
    MainMenu1.Items[0].Free;
  MainMenu1.RecreateOSMenu;
  FreeAndNil(MainMenu1);

  // Naming a copy points the form's field of that name at it
  for I := 0 to High(Copies) do
    if Names[I] <> '' then
      Copies[I].Name := Names[I];
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

procedure TMainForm.ApplyAngles;
begin
  if CameraLocked then
    Exit;
  // The normal view's angles; a mouse view turn goes back on top of them
  SuspendMouseView;
  try
    if Assigned(GorillaCamera) then
    begin
      GorillaCamera.Azimuth := Wrap360(-FAzimuth);
      GorillaCamera.PolarAngle := FPolarAngle;
      GorillaCamera.Roll := Wrap360(-FRoll);   // reversed, as is Azimuth
    end;
  finally
    ResumeMouseView;
  end;
end;

procedure TMainForm.ProjectionItemClick(Sender: TObject);
begin
  if CameraLocked then
    Exit;   // the projection is part of the camera
  if not (Sender is TMenuItem) then
    Exit;
  for var Kind := Low(TSprite3DProjection) to High(TSprite3DProjection) do
    if ProjectionItem(Kind) = Sender then
    begin
      // Already the projection: an oblique one is chosen again to put its
      // angles back after Variable has turned them; the camera's own have
      // nothing to put back
      if TMenuItem(Sender).IsChecked and (Kind in [prPerspective, prOrthographic]) then
        Exit;
      CheckProjection(Kind);
      ApplyProjection;
      Exit;
    end;
end;

procedure TMainForm.CheckProjection(const AProjection: TSprite3DProjection);
begin
  // Not left to RadioItem: FMX unticks only siblings, and the oblique items
  // are a level down, in ObliqueMenu
  for var Kind := Low(TSprite3DProjection) to High(TSprite3DProjection) do
    ProjectionItem(Kind).IsChecked := Kind = AProjection;
end;

function TMainForm.ProjectionItem(const AProjection: TSprite3DProjection): TMenuItem;
begin
  case AProjection of
    prOrthographic: Result := OrthographicItem;
    prCavalier: Result := CavalierItem;
    prCabinet: Result := CabinetItem;
    prMilitary: Result := MilitaryItem;
    prPlanOblique: Result := PlanObliqueItem;
  else
    Result := PerspectiveItem;
  end;
end;

function TMainForm.CheckedProjection: TSprite3DProjection;
begin
  for var Kind := Low(TSprite3DProjection) to High(TSprite3DProjection) do
    if ProjectionItem(Kind).IsChecked then
      Exit(Kind);
  Result := prPerspective;
end;

function TMainForm.CheckedCameraViewKey: String;
begin
  Result := String.Empty;
  for var I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) and CameraMenu.Items[I].IsChecked then
      Exit(CameraViewKey(CameraMenu.Items[I]));
end;

procedure TMainForm.EnterObliqueView(const AKind: TSpritelyProjectionKind);
var
  Azimuth, Inclination: Single;
begin
  if not FObliqueActive then
  begin
    // The view to go back to, kept until a camera's own projection is chosen
    FObliqueView := CheckedCameraViewKey;
    FObliqueAzimuth := FAzimuth;
    FObliqueInclination := FPolarAngle;
    FObliqueRoll := FRoll;
    FObliqueActive := True;
  end;
  // Every angle is set, so nothing turned before is left over: one the
  // preset does not give is 0
  if not TSpritelyProjection.PresetAngles(AKind, Azimuth, Inclination) then
  begin
    Azimuth := 0;
    Inclination := 0;
  end;
  // FAzimuth is in Sprite3DBuilder's own terms, Sprite3D's, as the readouts and fixed views
  // give it: 0 is south and it grows clockwise seen from above, so 45 is
  // south-west (Isometric). PresetAngles' military 45 is a plan turned 45
  // degrees, either way being the same projection mirrored, so it is taken
  // as it stands, south-west, rather than reversed to 315 as the camera's
  // own sense would make it (ApplyAngles does that reversing).
  FAzimuth := Wrap360(Azimuth);
  FPolarAngle := Inclination;
  FRoll := 0;
  // The distance, shift and rise too: ApplyProjection's refit shows them
  ResetViewSettings;
  ApplyAngles;
  ClearViewChecks;
  ViewVariableItem.IsChecked := True;
  DebugMemo.Lines.Add(Format('Camera at the projection''s angles: azimuth %.0f, ' +
    'inclination %.0f, roll %.0f', [FAzimuth, FPolarAngle, FRoll]));
end;

procedure TMainForm.LeaveObliqueView;
var
  Item: TMenuItem;
begin
  // Cleared first: a fixed view's handler may call ApplyProjection again
  FObliqueActive := False;
  UpdateCameraLockControls;
  Item := CameraViewItem(FObliqueView);
  if (Item = nil) or (Item = ViewVariableItem) then
  begin
    FAzimuth := FObliqueAzimuth;
    FPolarAngle := FObliqueInclination;
    FRoll := FObliqueRoll;
    ApplyAngles;
    ClearViewChecks;
    ViewVariableItem.IsChecked := True;
  end
  else if Assigned(Item.OnClick) then
    Item.OnClick(Item);
  DebugMemo.Lines.Add('Camera view put back: ' + CheckedCameraViewKey);
end;

procedure TMainForm.ProjectionLog(Sender: TObject; const AText: string);
var
  Line: String;
begin
  // Called from inside a frame: the memo is changed afterwards
  Line := 'Projection component: ' + AText;
  TThread.ForceQueue(nil,
    procedure
    begin
      if not MainFormGone then
        DebugMemo.Lines.Add(Line);
    end);
end;

// The projection and caption to match View, Projection, then a refit, as
// each projection sizes the view differently. The camera's own perspective
// or orthographic, or an oblique one drawn by FProjection over the camera's
// perspective (TSpritelyProjection is made from FMX's perspective, so the
// camera must be in perspective for it). FProjection's Kind is set either
// way, pjPerspective for the camera's own, so it lets FMX's projection be.
procedure TMainForm.ApplyProjection;
const
  // FProjection's Kind for each: the camera's own projections need none
  KINDS: array[TSprite3DProjection] of TSpritelyProjectionKind = (
    pjPerspective, pjPerspective, pjCavalier, pjCabinet, pjMilitary, pjPlanOblique);
var
  Kind: TSprite3DProjection;
begin
  if CameraLocked then
  begin
    UpdateCaption;
    Exit;
  end;
  Kind := CheckedProjection;
  // The lens shift off before the camera may leave perspective, where
  // FProjection could not draw it; FitModel below puts the shift and rise
  // back in the new projection's own way
  SetLensShift(0, 0);
  if Kind = prOrthographic then
    GorillaCamera.ProjectionMode := TGorillaCameraProjection.cpOrthographic
  else
    GorillaCamera.ProjectionMode := TGorillaCameraProjection.cpPerspective;
  if FProjection <> nil then
    FProjection.Kind := KINDS[Kind];
  // An oblique projection is drawn from its own angles; the camera's own
  // projections take back the view chosen before
  if KINDS[Kind] <> pjPerspective then
    EnterObliqueView(KINDS[Kind])
  else if FObliqueActive then
    LeaveObliqueView;
  UpdateCameraLockControls;
  if Ord(Kind) <> FLoggedProjection then
  begin
    FLoggedProjection := Ord(Kind);
    if KINDS[Kind] = pjPerspective then
      DebugMemo.Lines.Add('Projection: ' + ProjectionInfo(Kind).Caption + ', the camera''s own')
    else
      DebugMemo.Lines.Add('Projection: ' + ProjectionInfo(Kind).Caption +
        ', drawn by TSpritelyProjection over the camera''s perspective');
  end;
  UpdateCaption;
  FitModel;
end;

procedure TMainForm.RollDialChange(Sender: TObject);
begin
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  FSetupComplete := True;
  if FStarted then
    Exit;   // the form can be shown again; the level stays as it is
  FStarted := True;
  UpdateCaption;
  DebugMemo.Lines.Add(Format('Empty level: grid of %s units', [FormatFloat('0.###',
    FSettings.GridSize)]));
  // Once the main window is up: the palette, if there is one, on the last
  // asset folder
  TThread.ForceQueue(nil, OpenLastLibrary);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // A level with changes not saved: asked first, then closed again once the
  // answer is in, as the dialog may answer after this returns
  CanClose := FCloseAsked or not FLevelDirty;
  if CanClose then
    Exit;
  AskToKeepLevel(
    procedure
    begin
      FCloseAsked := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          if not MainFormGone then
            Close;
        end);
    end);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MainFormGone := True;   // queued work arriving from here on does nothing
  FileOpenRequests.OnOpenFile := nil;
  // The projection let go of and freed while the viewport, its hook's owner,
  // and the camera are whole: freed later, with the form's other components,
  // it could meet them half destroyed (ProjectionTest's exit fault in
  // SRDelphiFMX was of that kind)
  if OrbitCamera <> nil then
    OrbitCamera.Projection := nil;
  FreeAndNil(FProjection);
  if Assigned(FReadoutTimer) then
    FReadoutTimer.Enabled := False;
  if Assigned(FFallTimer) then
    FFallTimer.Enabled := False;
  // The pieces, while the form and the viewport are whole
  FreeLevelPieces;
  FreeAndNil(FHistory);
  FreeAndNil(FPieces);
  FreeAndNil(FSources);
  FreeAndNil(FVariantMarks);
  FreeAndNil(FVariantNames);
  FreeAndNil(FDisplays);
  SaveViewState;
  FreeAndNil(FSettings);
end;

// Ticks the View menu's on/off items as settings.json says, then applies
// each, as choosing it would: the lights, the bounding boxes, and the
// projection and caption, which refits the view.
procedure TMainForm.RestoreViewToggles;
begin
  ShowBoundsItem.IsChecked := FSettings.ShowBoundingBox;
  CheckProjection(FSettings.ProjectionKind);
  HeadlightItem.IsChecked := FSettings.Headlight;
  OriginalLightItem.IsChecked := FSettings.OriginalLight;
  ApplyLights;
  ApplyShowBounds;
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
  if FObliqueActive then
  begin
    // The view from before the oblique projection: the next session puts
    // it back, then the projection turns the camera to its own angles
    FSettings.CameraView := FObliqueView;
    if CameraViewItem(FObliqueView) = ViewVariableItem then
    begin
      FSettings.VariableAzimuth := FObliqueAzimuth;
      FSettings.VariableInclination := FObliqueInclination;
      FSettings.VariableRoll := FObliqueRoll;
    end;
  end
  else
  begin
    for I := 0 to CameraMenu.ItemsCount - 1 do
      if IsCameraViewItem(CameraMenu.Items[I]) and CameraMenu.Items[I].IsChecked then
        FSettings.CameraView := CameraViewKey(CameraMenu.Items[I]);
    if ViewVariableItem.IsChecked then
    begin
      FSettings.VariableAzimuth := FAzimuth;
      FSettings.VariableInclination := FPolarAngle;
      FSettings.VariableRoll := FRoll;
    end;
  end;
  FSettings.ShowBoundingBox := ShowBoundsItem.IsChecked;
  FSettings.ProjectionKind := CheckedProjection;
  FSettings.Headlight := HeadlightItem.IsChecked;
  FSettings.OriginalLight := OriginalLightItem.IsChecked;
  KeepShiftSettings;
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  KeepPlaces;
  {$ENDIF}
  try
    FSettings.Save;
  except
    // Nowhere to report it; see above
  end;
end;

procedure TMainForm.AspectLayoutResize(Sender: TObject);
var
  NewSize: TSizeF;
begin
  // AspectLayout fills ViewportLayout, so this is its resize too; the
  // viewport fills AspectLayout, and its own OnResize refits the view.
  // The panels keep to their nearer edges, then inside the view
  NewSize := TSizeF.Create(ViewportLayout.Width, ViewportLayout.Height);
  if FPanelsPlaced and (FViewSize.Width > 0) and (FViewSize.Height > 0) then
  begin
    AnchorPanel(FPaletteBack, FViewSize, NewSize);
    AnchorPanel(FHistoryBack, FViewSize, NewSize);
  end;
  FViewSize := NewSize;
  KeepPaletteInView;
end;

procedure TMainForm.AnchorPanel(const APanel: TControl; const AOld, ANew: TSizeF);
var
  At: TPointF;
begin
  if APanel = nil then
    Exit;
  At := APanel.Position.Point;
  // Its middle in the right half: as far from the right edge as it was
  if At.X + APanel.Width / 2 > AOld.Width / 2 then
    At.X := At.X + ANew.Width - AOld.Width;
  if At.Y + APanel.Height / 2 > AOld.Height / 2 then
    At.Y := At.Y + ANew.Height - AOld.Height;
  APanel.Position.Point := At;
end;

procedure TMainForm.GorillaViewportResize(Sender: TObject);
begin
  FitModel;
end;

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

procedure TMainForm.LibraryItemClick(Sender: TObject);
begin
  OpenLibrary;
end;

procedure TMainForm.EnsureAssetsForm;
begin
  if FAssetsForm = nil then
  begin
    FAssetsForm := TAssetsForm.Create(Self);
    // Where it was last session, as the main window is put back
    PlaceFormOnScreen(FAssetsForm, FSettings.LibraryLeft, FSettings.LibraryTop,
      FSettings.LibraryWidth, FSettings.LibraryHeight, FSettings.LibraryMaximized);
    FAssetsForm.OnLog :=
      procedure(const AText: String)
      begin
        if not MainFormGone then
          DebugMemo.Lines.Add(AText);
      end;
    FAssetsForm.MigrationFolder := OSFriendlyPath(FSettings.AssetFolder);
    // The model selected in the Library is the one Place Model places
    FAssetsForm.OnModelChosen :=
      procedure(const ASpecs: TArray<TSprite3DPieceSpec>; const ALeftOut: TArray<String>)
      begin
        if not MainFormGone then
          ChooseModel(ASpecs, ALeftOut);
      end;
    FAssetsForm.PreviewBackground := FSettings.PreviewBackground;
    // Kept as soon as it is chosen
    FAssetsForm.OnPreviewBackground :=
      procedure(const AKey: String)
      begin
        if MainFormGone then
          Exit;
        FSettings.PreviewBackground := AKey;
        try
          FSettings.Save;
        except
          on E: Exception do
            DebugMemo.Lines.Add('Can''t save the settings to ' + FSettings.FileName + ': ' +
              E.Message);
        end;
      end;
  end;
  FAssetsForm.GridSize := FSettings.GridSize;
end;

procedure TMainForm.OpenLibrary;
begin
  EnsureAssetsForm;
  FAssetsForm.ShowLibrary;
end;

procedure TMainForm.OpenLastLibrary;
{$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
var
  Found: TSprite3DAssetLibrary;
{$ENDIF}
begin
  if MainFormGone then
    Exit;
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  if (LoadAssetLibrary(TSprite3DAppSettings.ThumbnailFolder, Found) and
    (Length(Found.Collections) > 0)) or
    FileExists(TPath.Combine(TSprite3DAppSettings.ThumbnailFolder,
    ASSET_PALETTE_FILE_NAME)) then
    OpenLibrary;
  {$ENDIF}
end;

procedure TMainForm.CheckThumbnailsItemClick(Sender: TObject);
begin
  EnsureAssetsForm;
  TabControl1.ActiveTab := DebugTab;
  FAssetsForm.CheckThumbnails;
end;

// Asks first, as the thumbnails take a while to make again
procedure TMainForm.ClearLibraryItemClick(Sender: TObject);
begin
  TDialogService.MessageDialog('Delete the whole library: every collection, its groups and ' +
    'icons chosen, and every thumbnail? The model files themselves are not touched. This ' +
    'cannot be undone.',
    TMsgDlgType.mtWarning, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    var
      Error: String;
    begin
      if (AResult <> mrYes) or MainFormGone then
        Exit;
      if FAssetsForm <> nil then
        FAssetsForm.ClearLibrary
      else if ClearAssetLibrary(TSprite3DAppSettings.ThumbnailFolder, Error) then
        DebugMemo.Lines.Add('Assets: the library, its collections and every thumbnail ' +
          'deleted')
      else
        DebugMemo.Lines.Add('Assets: the library is cleared, but some could not be ' +
          'deleted: ' + Error);
    end);
end;

procedure TMainForm.LicencesMenuItemClick(Sender: TObject);
begin
  ShowLicences;
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
        Notes.Add('The graphics processor choice takes effect the next time ' +
          'Sprite3DBuilder starts.');
      end
      else
        Notes.Add('Can''t store the graphics processor choice in the registry.');
    end;

    if ANew.ViewFps <> AOld.ViewFps then
    begin
      FSettings.ViewFps := ANew.ViewFps;   // limited to the allowed range
      ApplyViewFps;
    end;

    // Every JSON file written from now on, settings.json included
    if ANew.MinifyJson <> AOld.MinifyJson then
      FSettings.MinifyJson := ANew.MinifyJson;

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
  Spec: TCameraSettings;
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  MouseYaw, MouseZoom: Single;
  MouseSubject: String;
  {$ENDIF}
begin
  if CameraLocked then
    Exit;   // the views are switched off while the camera is locked
  // While the form is being created (RestoreCameraView) there is nothing to
  // show the dialog over; the angles are already set
  if FSetupComplete then
  begin
    Dialog := TOrbitalSettingsForm.Create(nil);
    // What is on screen, Mouse View's turn and zoom included, which
    // becomes the dialog's to change, so OK keeps it as the normal view;
    // Cancel gives the mouse view back (there is none on Android and iOS)
    {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
    MouseYaw := FMouseYaw;
    MouseZoom := FMouseZoom;
    MouseSubject := FMouseSubject;
    {$ENDIF}
    Spec := ShownCameraSpec;
    ResetMouseView;
    ShowCameraSpec(Spec);
    Dialog.CameraSpec := Spec;
    // Every dial is live, oblique projection or not (AzimuthOnly was for
    // debugging the obliques; owner, 9 November 2026)
    Dialog.OnPreview := OrbitalDialogPreview;
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
    // ShowModal cannot block here: the dialog reports OK or Cancel and
    // frees itself
    Dialog.OnAccept := OrbitalDialogAccept;
    Dialog.OnCancel := OrbitalDialogCancel;
    Dialog.ShowAndFree;
    {$ELSE}
    // Mouse View's wheel and drag over the view change the dialog's
    // distance and azimuth while it is open
    FOrbitalDialog := Dialog;
    try
      if Dialog.ShowModal = mrOk then
        AcceptCameraSpec(Dialog.CameraSpec)
      else
      begin
        RestoreCamera;   // the previews moved the camera; put it back
        RestoreMouseView(MouseYaw, MouseZoom, MouseSubject);
      end;
    finally
      FOrbitalDialog := nil;
      Dialog.Free;
    end;
    {$ENDIF}
  end;
  ClearViewChecks;
  ViewVariableItem.IsChecked := True;
end;

function TMainForm.ShownCameraSpec: TCameraSettings;
begin
  Result := CurrentCameraSpec;
  if not FMouseApplied then
    Exit;
  // The mouse view's turn is in the camera's own sense, which the readouts
  // reverse; its zoom is on the distance or the orthographic size, as the
  // distance factor is, so the two multiply
  Result.Azimuth := Wrap360(Result.Azimuth - FMouseYaw);
  Result.Distance := Result.Distance * FMouseZoom;
end;

procedure TMainForm.RestoreMouseView(const AYaw, AZoom: Single; const ASubject: String);
begin
  if (AYaw = 0) and (AZoom = 1) then
    Exit;
  FMouseYaw := AYaw;
  FMouseZoom := AZoom;
  FMouseSubject := ASubject;
  // Put on top of the normal view as ResumeMouseView does after any change
  SuspendMouseView;
  ResumeMouseView;
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
  Result.PanKeep := FPanKeep;
end;

// Shows ASpec in the viewport without keeping it: the form's own fields
// stay as they are, so RestoreCamera can undo it
procedure TMainForm.ShowCameraSpec(const ASpec: TCameraSettings);
begin
  if CameraLocked or not Assigned(GorillaCamera) then
    Exit;
  // The normal view as the dialog shows it; a mouse view goes back on top
  SuspendMouseView;
  try
    GorillaCamera.Azimuth := Wrap360(-ASpec.Azimuth);
    GorillaCamera.PolarAngle := ASpec.PolarAngle;
    GorillaCamera.Roll := Wrap360(-ASpec.Roll);
    ShowDistanceFactor(ASpec.Distance);
    ShowPan(ASpec.PanEnabled, ASpec.PanX, ASpec.PanZ);
  finally
    ResumeMouseView;
  end;
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
  FPanKeep := ASpec.PanKeep;
  RestoreCamera;
  UpdateCaption;
  // Kept straight away; SaveViewState writes them again on the way out
  KeepShiftSettings;
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

// The window's caption: the projection, and a reminder when a shift or rise
// is in use
function TMainForm.ProjectionCaption: String;
begin
  Result := ProjectionInfo(CheckedProjection).Caption;
  if FPanEnabled and ((FPanX <> 0) or (FPanZ <> 0)) then
    Result := Result + ' (shifted)';
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
  // projection is switched, and the level refitted, to match.
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
  // projection is switched, and the level refitted, to match.
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
  // At floor height, looking straight along its Z axis
  SelectFixedView(ViewHeadOnItem, 0, 0);
end;

procedure TMainForm.ViewTopDownItemClick(Sender: TObject);
begin
  // Straight down onto the level
  SelectFixedView(ViewTopDownItem, 90, 0);
end;

procedure TMainForm.ViewSideItemClick(Sender: TObject);
begin
  // At floor height, from the side: a quarter turn from Head On
  SelectFixedView(ViewSideItem, 0, 90);
end;

procedure TMainForm.ResetViewSettings;
begin
  // Not while the last session's view is put back: that is not a choice of
  // view, and its distance, shift and rise were kept on purpose
  if FRestoringView then
    Exit;
  ResetMouseView;
  FFactor := 1;
  FPanX := 0;
  FPanZ := 0;
  // The caption drops "(shifted)"
  UpdateCaption;
end;

// Sets a fixed view: the given inclination and azimuth (45 unless given)
// with roll 0, all as shown on the readouts, with the dials turned to
// match and switched off, then refits. The View menu checks are the
// caller's job.
procedure TMainForm.SetPolarViewAngle(const APolarAngle, AAzimuth: Single);
const
  FIXED_ROLL = 0;
begin
  // A fixed view is a starting point: nothing changed before carries over
  ResetViewSettings;
  // The dial fields hold the readout values; ApplyAngles sends azimuth to
  // the camera reversed, as it does for the dial
  FAzimuth := AAzimuth;
  FPolarAngle := APolarAngle;
  FRoll := FIXED_ROLL;
  // Turn the dials to match; their OnChange reads the same angles back
  ApplyAngles;
  FitModel;   // a deliberate change of view, so frame the model for it
end;

// Refit after a change of size or projection, to ViewVolume: the middle
// of the level's floor, as large as the view allows.
// The dials do not call this: with the orbit centre on the turning axis, the
// fit already allows for turning the azimuth.
//
// Mouse View sits on top of the fit: the fit is of the normal view
// alone, with the mouse view's turn and zoom taken off around it and put back
// after, so a refit (the window resized, say) keeps them.
// A new subject shows the normal view:
// they are forgotten, whether or not the camera is locked.
function TMainForm.FitModel: Boolean;
begin
  CheckMouseViewSubject;
  SuspendMouseView;
  try
    Result := FitNormalView;
  finally
    ResumeMouseView;
  end;
end;

function TMainForm.FitNormalView: Boolean;
begin
  Result := not CameraLocked and Assigned(GorillaCamera) and Assigned(FLevel);
  if not Result then
    Exit;
  // No lens shift while fitting: the fit allows for one, and would centre the
  // model in the shifted picture, undoing it
  SetLensShift(0, 0);
  Result := FitCameraToSweep(GorillaCamera, FLevel, ViewVolume);
  if Result then
  begin
    // Remember the fit, then apply the test distance factor and the shift
    // and rise on top of it. The fit put the orbit centre where it wants it,
    // so no orthographic slide is left on it
    FFitDistance := GorillaCamera.Distance;
    FFitOrthoHeight := GorillaCamera.OrthoHeight;
    FAppliedPan := TPoint3D.Zero;
    FFitted := True;
    ApplyDistance;
    ApplyPan;
  end;
end;

// The fitted view moved out by Variable's Distance factor
procedure TMainForm.ApplyDistance;
begin
  ShowDistanceFactor(FFactor);
end;

procedure TMainForm.ShowDistanceFactor(const AFactor: Single);
begin
  if CameraLocked or not Assigned(GorillaCamera) or (FFitDistance <= 0) then
    Exit;
  // The normal view's distance; a mouse view zoom goes back on top of it
  SuspendMouseView;
  try
    if GorillaCamera.IsOrthographic then
      GorillaCamera.OrthoHeight := FFitOrthoHeight * AFactor
    else
      GorillaCamera.Distance := FFitDistance * AFactor;
  finally
    ResumeMouseView;
  end;
end;

procedure TMainForm.ApplyPan;
begin
  ShowPan(FPanEnabled, FPanX, FPanZ);
end;

procedure TMainForm.ShowPan(const AEnabled: Boolean; const APanX, APanZ: Single);
begin
  if CameraLocked or not Assigned(GorillaCamera) or not FFitted or
    not Assigned(FLevel) then
    Exit;
  // Measured with a mouse view's turn and zoom on, as they are drawn;
  // ShiftCamera places it again whenever they change
  PlaceShift(AEnabled, APanX, APanZ, ViewVolume, GorillaViewport.Width,
    GorillaViewport.Height);
  LogShift(AEnabled, APanX, APanZ);
end;

procedure TMainForm.KeepShiftSettings;
begin
  FSettings.KeepShift := FPanKeep;
  // Not kept, they are saved off, at 0 and at 1, so a file read by an
  // earlier version starts without them too
  FSettings.PanEnabled := FPanKeep and FPanEnabled;
  if FPanKeep then
  begin
    FSettings.PanX := FPanX;
    FSettings.PanZ := FPanZ;
    FSettings.DistanceFactor := FFactor;
  end
  else
  begin
    FSettings.PanX := 0;
    FSettings.PanZ := 0;
    FSettings.DistanceFactor := 1;
  end;
end;

procedure TMainForm.LogShift(const AEnabled: Boolean; const AShift, ARise: Single);
var
  Line, How: String;
begin
  if not AEnabled then
    Line := 'Shift and rise off'
  else
  begin
    if GorillaCamera.IsOrthographic then
      How := 'the camera slid'
    else
      How := 'lens shift';
    Line := Format('Shift and rise on: shift %s, rise %s (%s %s, %s of the picture''s ' +
      'half-width and half-height)', [FormatFloat('+0.000;-0.000;+0.000', AShift),
      FormatFloat('+0.000;-0.000;+0.000', ARise), How,
      FormatFloat('+0.000;-0.000;+0.000', FSlideX),
      FormatFloat('+0.000;-0.000;+0.000', FSlideY)]);
  end;
  if Line = FLoggedShift then
    Exit;
  FLoggedShift := Line;
  DebugMemo.Lines.Add(Line);
end;

procedure TMainForm.SetLensShift(const AShiftX, AShiftY: Single);
begin
  if FProjection = nil then
    Exit;
  if FProjection.ShiftX <> AShiftX then
    FProjection.ShiftX := AShiftX;
  if FProjection.ShiftY <> AShiftY then
    FProjection.ShiftY := AShiftY;
end;

procedure TMainForm.PlaceShift(const AEnabled: Boolean; const AShift, ARise: Single;
  const AVolume: TSweptVolume; const AWidth, AHeight: Single);
var
  Shift, Rise, Left, Top, Right, Bottom: Single;
  ToRight, ToLeft, ToTop, ToBottom: Single;
begin
  if not Assigned(GorillaCamera) or (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  FPlaceEnabled := AEnabled;
  FPlaceShift := AShift;
  FPlaceRise := ARise;
  // The slide before taken off: the orbit centre back where the fit put it.
  // Turning the camera since does not matter, as the centre is the pivot
  TakeOffSlide;
  FSlideX := 0;
  FSlideY := 0;
  Shift := 0;
  Rise := 0;
  if AEnabled then
  begin
    Shift := EnsureRange(AShift, -PAN_LIMIT, PAN_LIMIT);
    Rise := EnsureRange(ARise, -PAN_LIMIT, PAN_LIMIT);
  end;
  if (Shift <> 0) or (Rise <> 0) then
  begin
    // How far the picture can slide each way, in normalised device units
    // (the picture is 2 across and 2 down): until the volume's near side is
    // on that edge. Without a volume to measure, until the target is
    ToRight := 1;
    ToLeft := 1;
    ToTop := 1;
    ToBottom := 1;
    if Assigned(FLevel) and SweepViewExtent(GorillaCamera, FLevel, AVolume,
      AWidth, AHeight, Left, Top, Right, Bottom) then
    begin
      // y down, as measured
      Left := 2 * Left / AWidth - 1;
      Right := 2 * Right / AWidth - 1;
      Top := 2 * Top / AHeight - 1;
      Bottom := 2 * Bottom / AHeight - 1;
      // A lens shift in use only adds to every point (up is negative y), so
      // it is taken off what was measured; the orthographic slide is off
      // already
      if not GorillaCamera.IsOrthographic and (FProjection <> nil) then
      begin
        Left := Left - FProjection.ShiftX;
        Right := Right - FProjection.ShiftX;
        Top := Top + FProjection.ShiftY;
        Bottom := Bottom + FProjection.ShiftY;
      end;
      ToRight := Max(1 - Left, 0);
      ToLeft := Max(1 + Right, 0);
      ToTop := Max(1 + Bottom, 0);
      ToBottom := Max(1 - Top, 0);
    end;
    if Shift > 0 then
      FSlideX := Shift * ToRight
    else
      FSlideX := Shift * ToLeft;
    if Rise > 0 then
      FSlideY := Rise * ToTop
    else
      FSlideY := Rise * ToBottom;
  end;
  if GorillaCamera.IsOrthographic then
  begin
    // FProjection cannot draw over the camera's own orthographic projection,
    // so the camera slides instead: in a parallel view, exactly the same
    SetLensShift(0, 0);
    PutOnSlide(AWidth, AHeight);
  end
  else
    SetLensShift(FSlideX, FSlideY);
end;

procedure TMainForm.TakeOffSlide;
begin
  if FAppliedPan.Length > 0 then
  begin
    GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point - FAppliedPan;
    FAppliedPan := TPoint3D.Zero;
  end;
end;

procedure TMainForm.PutOnSlide(const AWidth, AHeight: Single);
var
  Before: TPoint3D;
begin
  if not GorillaCamera.IsOrthographic or ((FSlideX = 0) and (FSlideY = 0)) or
    (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  // ShiftView moves the camera, so the picture goes the other way; it works
  // from the orthographic size as it is now, so the slide is redone whenever
  // that changes
  Before := GorillaCamera.OrbitCenter.Point;
  GorillaCamera.ShiftView(-FSlideX * AWidth / 2, -FSlideY * AHeight / 2, AWidth, AHeight);
  FAppliedPan := GorillaCamera.OrbitCenter.Point - Before;
end;

procedure TMainForm.DistanceTrackChange(Sender: TObject);
begin
  ApplyDistance;
end;

// The volume the view is fitted to: the starting area of the level, swept
// about its centre, so every azimuth frames it alike
function TMainForm.ViewVolume: TSweptVolume;
var
  Half: Single;
  Box: TBoundingBox;
begin
  Half := LEVEL_FRAME_CELLS * FSettings.GridSize / 2;
  // In the level's own coordinates, Y up: the floor, and the height of a
  // wall above it
  // Centred on FViewCentre, which Move Camera moves, so a refit keeps the
  // view where it was moved to, and the view turns about it
  Box := TBoundingBox.Create(Point3D(FViewCentre.X - Half, 0, FViewCentre.Y - Half),
    Point3D(FViewCentre.X + Half, LEVEL_FRAME_CELLS_HIGH * FSettings.GridSize,
    FViewCentre.Y + Half));
  Result := CalcSweptVolume(Box, Point3D(FViewCentre.X, 0, FViewCentre.Y), saY);
end;

{ TLevelPiece }

function TLevelPiece.Box: TBoundingBox;
begin
  Result := TBoundingBox.Create(Turned.TopLeftNear + Landed, Turned.BottomRightFar + Landed);
end;

{ Placing pieces }

function TMainForm.LevelFloorAt(const AScreen: TPointF; out AOverView: Boolean;
  out AFloor: TPointF): Boolean;
begin
  Result := LevelPlaneAt(AScreen, 0, AOverView, AFloor);
end;

// As the floor, any level plane is a homography of the screen: its four
// points are taken at AHeight
function TMainForm.LevelPlaneAt(const AScreen: TPointF; const AHeight: Single;
  out AOverView: Boolean; out APoint: TPointF): Boolean;
var
  Local: TPointF;
  W, H, Half, SX, SY: Single;
  Screen, Floor: array[0..3] of TPointF;
  Map: TSprite3DFloorMap;
begin
  Result := False;
  AOverView := False;
  APoint := TPointF.Zero;
  if (FLevel = nil) or (GorillaCamera = nil) or (GorillaViewport = nil) or
    (WindowState = TWindowState.wsMinimized) or (TabControl1.ActiveTab <> LevelTab) then
    Exit;
  W := GorillaViewport.Width;
  H := GorillaViewport.Height;
  Local := GorillaViewport.AbsoluteToLocal(ScreenToClient(AScreen));
  AOverView := (W > 0) and (H > 0) and TRectF.Create(0, 0, W, H).Contains(Local);
  if not AOverView then
    Exit;
  // Four floor points about the middle of the view, and where the view
  // shows them
  Half := LEVEL_FRAME_CELLS * FSettings.GridSize / 2;
  Floor[0] := FViewCentre + TPointF.Create(-Half, -Half);
  Floor[1] := FViewCentre + TPointF.Create(Half, -Half);
  Floor[2] := FViewCentre + TPointF.Create(Half, Half);
  Floor[3] := FViewCentre + TPointF.Create(-Half, Half);
  for var I := 0 to 3 do
  begin
    if not GorillaCamera.ProjectToView(Point3D(Floor[I].X, AHeight, Floor[I].Y), FLevel, W, H,
      SX, SY) then
      Exit;
    Screen[I] := TPointF.Create(SX, SY);
  end;
  if not TSprite3DFloorMap.Solve(Screen, Floor, Map) or not Map.Map(Local, APoint) then
    Exit;
  // Shown again, it must be where the pointer is: above the horizon, the
  // map gives a point behind the camera, which shows elsewhere or not at all
  if not GorillaCamera.ProjectToView(Point3D(APoint.X, AHeight, APoint.Y), FLevel, W, H, SX, SY) then
    Exit;
  Result := TPointF.Create(SX, SY).Distance(Local) <= FLOOR_MAP_TOLERANCE;
end;

function TMainForm.PlacedBoxes: TArray<TBoundingBox>;
begin
  Result := nil;
  if FPieces = nil then
    Exit;
  SetLength(Result, FPieces.Count);
  for var I := 0 to FPieces.Count - 1 do
    Result[I] := FPieces[I].Box;
end;

procedure TMainForm.ChooseModel(const ASpecs: TArray<TSprite3DPieceSpec>;
  const ALeftOut: TArray<String>);
var
  Size: TPoint3D;
  Same: Boolean;
begin
  if Length(ALeftOut) > 0 then
    DebugMemo.Lines.Add('Level: ' + String.Join(', ', ALeftOut) + ' can''t be placed until ' +
      'their thumbnails are made, as their boxes come with them');
  if Length(ASpecs) = 0 then
    Exit;
  Same := FHasBrush and (Length(ASpecs) = Length(FBrushSet));
  if Same then
    for var I := 0 to High(ASpecs) do
      if ASpecs[I].Key <> FBrushSet[I].Key then
        Same := False;
  if Same then
    Exit;
  FBrush := ASpecs[0];
  FBrushSet := ASpecs;
  FHasBrush := True;
  if not FPlaceDown then
    HidePlacement;   // the next move shows the new one
  UpdatePalette;
  Size := FBrush.BoxMax - FBrush.BoxMin;
  if Length(FBrushSet) = 1 then
    DebugMemo.Lines.Add(Format('Level: Place Model places %s, its box %.3g x %.3g x %.3g ' +
      '(width, height, depth)', [FBrush.Name, Size.X, Size.Y, Size.Z]))
  else
  begin
    var Names: TArray<String> := nil;
    for var Spec in FBrushSet do
      Names := Names + [Spec.Name];
    DebugMemo.Lines.Add(Format('Level: Place Model places one of %d models at random for ' +
      'each piece: %s; spaced by the first''s box, %.3g x %.3g x %.3g (width, height, depth)',
      [Length(FBrushSet), String.Join(', ', Names), Size.X, Size.Y, Size.Z]));
  end;
end;

function TMainForm.BrushName: String;
begin
  if Length(FBrushSet) <= 1 then
    Result := FBrush.Name
  else
    Result := Format('%s and %d more, at random', [FBrush.Name, Length(FBrushSet) - 1]);
end;

function TMainForm.PlaceToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etPlace);
end;

function TMainForm.RotateToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etRotate);
end;

function TMainForm.BendToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etBend);
end;

function TMainForm.PlaceSpotAt(const AScreen: TPointF; out ASpot: TPointF): Boolean;
var
  Over: Boolean;
  Floor: TPointF;
begin
  ASpot := TPointF.Zero;
  Result := FHasBrush and LevelFloorAt(AScreen, Over, Floor);
  if Result then
    ASpot := SnapPiecePosition(Floor, FBrush.Box, FSettings.GridSize);
end;

function TMainForm.AreaSpots(const AFrom, ATo: TPointF): TArray<TPointF>;
var
  Size: TPoint3D;
  Grid, StepX, StepZ: Single;
  CountX, CountZ, DirX, DirZ: Integer;
begin
  Grid := FSettings.GridSize;
  Size := FBrush.BoxMax - FBrush.BoxMin;
  // The footprint in whole cells, so the copies lie edge to edge
  if Grid > 0 then
  begin
    StepX := Max(1, Round(Size.X / Grid)) * Grid;
    StepZ := Max(1, Round(Size.Z / Grid)) * Grid;
  end
  else
  begin
    StepX := Max(Size.X, 1E-3);
    StepZ := Max(Size.Z, 1E-3);
  end;
  CountX := Round(Abs(ATo.X - AFrom.X) / StepX) + 1;
  CountZ := Round(Abs(ATo.Y - AFrom.Y) / StepZ) + 1;
  DirX := IfThen(ATo.X < AFrom.X, -1, 1);
  DirZ := IfThen(ATo.Y < AFrom.Y, -1, 1);
  if CountX * CountZ > MAX_AREA_PIECES then
  begin
    while CountX * CountZ > MAX_AREA_PIECES do
      if CountX >= CountZ then
        Dec(CountX)
      else
        Dec(CountZ);
    if not FPlaceCapLogged then
    begin
      FPlaceCapLogged := True;
      DebugMemo.Lines.Add(Format('Level: an area holds at most %d pieces; cut to %d by %d',
        [MAX_AREA_PIECES, CountX, CountZ]));
    end;
  end;
  FPlaceCountX := CountX;
  FPlaceCountZ := CountZ;
  FAreaOrigin := AFrom;
  FAreaStep := TPointF.Create(DirX * StepX, DirZ * StepZ);
  SetLength(Result, CountX * CountZ);
  for var Z := 0 to CountZ - 1 do
    for var X := 0 to CountX - 1 do
      Result[Z * CountX + X] := TPointF.Create(AFrom.X + DirX * X * StepX,
        AFrom.Y + DirZ * Z * StepZ);
end;

procedure TMainForm.ShowPlacement(const ASpots: TArray<TPointF>);

  // Whether a spot's position along one axis, AOrigin + I * AStep for I
  // from 0 to ACount - 1, falls strictly between ALo and AHi
  function AnySpotIn(const AOrigin, AStep: Single; const ACount: Integer;
    const ALo, AHi: Single): Boolean;
  var
    A, B, T: Single;
  begin
    if (ACount <= 1) or (Abs(AStep) < 1E-9) then
      Exit((AOrigin > ALo) and (AOrigin < AHi));
    A := (ALo - AOrigin) / AStep;
    B := (AHi - AOrigin) / AStep;
    if A > B then
    begin
      T := A;
      A := B;
      B := T;
    end;
    // The first whole I above A, and the last below B
    Result := Max(0, Floor(A) + 1) <= Min(ACount - 1, Ceil(B) - 1);
  end;

var
  Box: TBoundingBox;
  Others: TArray<TBoundingBox>;
  Grid, Rest, MinX, MaxX, MinZ, MaxZ, Inset: Single;
  Origin, Step: TPointF;
  Middle: TPoint3D;
  CountX, CountZ: Integer;
begin
  if (Length(ASpots) = 0) or not FHasBrush then
  begin
    HidePlacement;
    Exit;
  end;
  Grid := FSettings.GridSize;
  Box := FBrush.Box;
  Others := PlacedBoxes;
  // All of them rest at one height, the highest any of them would land at,
  // so the box round them is where they all go: the highest top of a box
  // under any spot's footprint, by more than a hundredth of a cell each
  // way, as LandingHeight has it. The spots are a regular grid, so for each
  // box placed it is worked out which spots it is under, rather than
  // testing every spot against every box
  if Length(ASpots) = 1 then
  begin
    Origin := ASpots[0];
    Step := TPointF.Zero;
    CountX := 1;
    CountZ := 1;
  end
  else
  begin
    Origin := FAreaOrigin;
    Step := FAreaStep;
    CountX := FPlaceCountX;
    CountZ := FPlaceCountZ;
  end;
  Inset := Max(Grid, 0) * 0.01;
  Rest := 0;
  for var B in Others do
    if (B.Bottom > Rest) and
      AnySpotIn(Origin.X, Step.X, CountX, B.Left + Inset - Box.Right, B.Right - Inset - Box.Left) and
      AnySpotIn(Origin.Y, Step.Y, CountZ, B.Near + Inset - Box.Far, B.Far - Inset - Box.Near) then
      Rest := B.Bottom;
  MinX := MaxSingle;
  MaxX := -MaxSingle;
  MinZ := MaxSingle;
  MaxZ := -MaxSingle;
  for var Spot in ASpots do
  begin
    MinX := Min(MinX, Spot.X + Box.Left);
    MaxX := Max(MaxX, Spot.X + Box.Right);
    MinZ := Min(MinZ, Spot.Y + Box.Near);
    MaxZ := Max(MaxZ, Spot.Y + Box.Far);
  end;
  // Rest is where their bottoms go; their origins are their own floors
  // above or below that. TBoundingBox: Top is the low Y, Bottom the high
  FPlaceLand := Rest - Box.Top;
  FPlaceSpots := ASpots;
  // The outline's control is put in the middle of what it outlines, and
  // made its size: left at the level's origin, it was not drawn once the
  // view had been moved (Move Camera, or a level loaded) so far that the
  // origin was out of sight, the renderer passing it over as not seen
  Middle := Point3D((MinX + MaxX) / 2, Rest + (Box.Bottom - Box.Top) / 2, (MinZ + MaxZ) / 2);
  FPlaceBox.Position.Point := Middle;
  FPlaceBox.Box := TBoundingBox.Create(
    Point3D(MinX - Middle.X, -(Box.Bottom - Box.Top) / 2, MinZ - Middle.Z),
    Point3D(MaxX - Middle.X, (Box.Bottom - Box.Top) / 2, MaxZ - Middle.Z));
  FitOutline(FPlaceBox);
  FPlaceBox.Visible := True;
  FPlaceShown := True;
  UpdateStatus;
end;

procedure TMainForm.HidePlacement;
begin
  if FPlaceBox <> nil then
    FPlaceBox.Visible := False;
  FPlaceShown := False;
  FPlaceSpots := nil;
  UpdateStatus;
end;

procedure TMainForm.TrackPlacement(const AScreen: TPointF);
var
  Spot: TPointF;
begin
  // Off the floor, as above the horizon: an area keeps its last spot; a
  // hover shows nothing
  if not PlaceSpotAt(AScreen, Spot) then
  begin
    if not FPlaceDown then
      HidePlacement;
    Exit;
  end;
  if FPlaceDown then
    ShowPlacement(AreaSpots(FPlaceAnchor, Spot))
  else
  begin
    FPlaceCountX := 1;
    FPlaceCountZ := 1;
    ShowPlacement([Spot]);
  end;
end;

// Each spot is the first model's place; a piece of another model of the set
// is put with its footprint's middle where the first's would be, and its
// own floor where the first's would rest
procedure TMainForm.PlaceShown;
var
  Spots: TArray<TPointF>;
  Rest, Lift: Single;
  Placed, Pick: Integer;
  Watch: TStopwatch;
  Onto: String;
  Specs: TArray<TSprite3DPieceSpec>;
  Sources: TArray<TPieceSource>;
  Source: TPieceSource;
  First: Integer;
  Started: Double;
  Piece: TLevelPiece;
  Ids: TArray<Integer>;
  Shift: TPointF;
  Spec: TSprite3DPieceSpec;
begin
  if not FPlaceShown or not FHasBrush or (Length(FPlaceSpots) = 0) then
    Exit;
  Spots := FPlaceSpots;
  // Where their bottoms go: the first's origin rests at FPlaceLand
  Rest := FPlaceLand + FBrush.Box.Top;
  Lift := PLACE_LIFT_CELLS * FSettings.GridSize;
  Watch := TStopwatch.StartNew;
  FMakeTicks := 0;
  FSetupTicks := 0;
  // Each model's template, loaded the first time it is placed; one that
  // will not load is left out
  Specs := nil;
  Sources := nil;
  for var Each in FBrushSet do
    if PieceSourceFor(Each, Source) then
    begin
      Specs := Specs + [Each];
      Sources := Sources + [Source];
    end;
  if Length(Specs) = 0 then
    Exit;
  Placed := 0;
  First := FPieces.Count;
  EditInstances(True);
  try
    for var I := 0 to High(Spots) do
    begin
      Pick := Random(Length(Specs));
      Spec := Specs[Pick];
      Shift := TPointF.Create(
        (FBrush.Box.Left + FBrush.Box.Right - Spec.Box.Left - Spec.Box.Right) / 2,
        (FBrush.Box.Near + FBrush.Box.Far - Spec.Box.Near - Spec.Box.Far) / 2);
      if PlacePiece(Spec, Sources[Pick], Point3D(Spots[I].X + Shift.X,
        Rest - Spec.Box.Top + Lift, Spots[I].Y + Shift.Y), Rest - Spec.Box.Top) then
        Inc(Placed)
      else
        Break;   // one could not be made: nor will the rest
    end;
  finally
    EditInstances(False);
  end;
  if Placed = 0 then
    Exit;
  // Nothing is drawn while they are made, so they all start to fall now,
  // together; timed from when each was made, the first would have landed
  // before it was ever seen
  Started := FClock.Elapsed.TotalSeconds;
  SetLength(Ids, FPieces.Count - First);
  for var I := First to FPieces.Count - 1 do
  begin
    Piece := FPieces[I];
    Piece.Started := Started;
    FPieces[I] := Piece;
    Ids[I - First] := Piece.Id;
  end;
  if Length(Specs) = 1 then
    AddHistory(Specs[0].Name, Ids)
  else
    AddHistory(Format('%s +%d', [Specs[0].Name, Length(Specs) - 1]), Ids);
  MarkLevelChanged;
  FFallTimer.Enabled := True;
  if SameValue(Rest, 0, 1E-4) then
    Onto := 'the floor'
  else
    Onto := Format('pieces, their bases at %.3g', [Rest]);
  DebugMemo.Lines.Add(Format('Level: placed %d x %s in %d ms (%d ms loading the model(s), ' +
    '%d ms adding instances), onto %s', [Placed, BrushName,
    Watch.ElapsedMilliseconds, FMakeTicks * 1000 div TStopwatch.Frequency,
    FSetupTicks * 1000 div TStopwatch.Frequency, Onto]));
end;

function TMainForm.PieceSourceFor(const ASpec: TSprite3DPieceSpec;
  out ASource: TPieceSource): Boolean;
var
  Names: TArray<String>;
  VariantIndex: Integer;
  Fixes: TArray<TSprite3DTextureFix>;
  Box: TBoundingBox;
  Watch: TStopwatch;
  Kind: TSprite3DModelKind;
  Template: TGorillaModel;
begin
  Result := FSources.TryGetValue(SourceKey(ASpec), ASource);
  if Result then
    Exit;
  // Not Default(): Gorilla.DefTypes' unscoped value Default hides it here
  ASource.Template := nil;
  ASource.LoadFile := String.Empty;
  ASource.IsStatic := False;
  // Kind is set once the template has loaded; a failure exits before it is
  // used
  Watch := TStopwatch.StartNew;
  // Made and loaded with its own LoadFromFile, as the Library loads a
  // model; never a TGorillaModel.LoadNewModelFrom... class function (an
  // access violation on closing, 12 November 2026). Every later piece of
  // it is a GPU instance of it, as Gorilla3D's author advised (12 November
  // 2026), so it is loaded once
  Template := TGorillaModel.Create(GorillaViewport);
  try
    // Its textures found, or made PNGs, and loaded from the copy in the
    // cache if any were, as the Library loads it
    Template.Parent := FLevel;
    Template.HitTest := False;
    ASource.LoadFile := PrepareModelTextures(ASpec.FileName,
      TSprite3DAppSettings.ThumbnailFolder, ASpec.Key, Fixes);
    for var Fix in Fixes do
      // Qualified, as Gorilla.DefTypes, used here, has unscoped values
      if Fix.Outcome <> TSprite3DTextureOutcome.toAsNamed then
        DebugMemo.Lines.Add(Format('Level: %s: %s %s: %s', [ASpec.Name,
          IfThen(Fix.IsBuffer, 'buffer', 'texture'), Fix.Named,
          IfThen(Fix.Used <> '', 'used ' + ExtractFileName(Fix.Used), 'not found')]));
    // A variant: from a copy whose meshes take its materials; one the model
    // no longer has is placed as the base, said so
    if ASpec.VariantName <> String.Empty then
    begin
      VariantIndex := -1;
      Names := VariantNamesOf(ASpec);
      for var I := 0 to High(Names) do
        if SameText(Names[I], ASpec.VariantName) then
          VariantIndex := I;
      if VariantIndex >= 0 then
        ASource.LoadFile := PrepareModelVariant(ASource.LoadFile,
          TSprite3DAppSettings.ThumbnailFolder, ASpec.Key, VariantIndex)
      else
        DebugMemo.Lines.Add(Format('Level: %s has no variant %s now; shown as made',
          [ASpec.Name, ASpec.VariantName]));
    end;
    LoadModelFile(Template, ASource.LoadFile, Box);
    // Meshes only, no skin, no animations: its meshes can be made static,
    // before it is first drawn, so its buffers are made static ones
    Kind := GuessModelKind(ModelContent(Template));
    ASource.IsStatic := Kind = mkStatic;
    if ASource.IsStatic then
      MarkMeshesStatic(Template);
    // Gorilla culls every instance by the template's own bounds: with
    // culling on, all its pieces would vanish whenever the template, parked
    // below the floor, was out of view, which it always is
    Template.FrustumCullingCheck := False;
    Template.ResetToBindPose();
    // Never a piece: an FBX of PolygonDungeon placed as the template itself
    // was not drawn, while its instances were (owner, 12 November 2026,
    // 23:56); so every piece is an instance, the same way for every model,
    // and the template, which Gorilla draws as instance #0, is kept out of
    // sight far below the floor
    Template.Position.Point := Point3D(0, TEMPLATE_PARK_Y, 0);
  except
    on E: Exception do
    begin
      Template.Free;
      DebugMemo.Lines.Add('Level: can''t load ' + ASpec.FileName + ': ' + E.Message);
      Exit(False);
    end;
  end;
  ASource.Template := Template;
  Inc(FMakeTicks, Watch.ElapsedTicks);
  // Pieces land by the box the model was chosen with, which pieces placed
  // later land on; say if the model loaded has another
  if not (SameValue(Box.Left, ASpec.BoxMin.X, 1E-3) and
    SameValue(Box.Top, ASpec.BoxMin.Y, 1E-3) and SameValue(Box.Near, ASpec.BoxMin.Z, 1E-3) and
    SameValue(Box.Right, ASpec.BoxMax.X, 1E-3) and SameValue(Box.Bottom, ASpec.BoxMax.Y, 1E-3) and
    SameValue(Box.Far, ASpec.BoxMax.Z, 1E-3)) then
    DebugMemo.Lines.Add(Format('Level: %s loaded with a box of (%.3g, %.3g, %.3g) to ' +
      '(%.3g, %.3g, %.3g), not the Library''s; placed by the Library''s', [ASpec.Name,
      Box.Left, Box.Top, Box.Near, Box.Right, Box.Bottom, Box.Far]));
  FSources.Add(SourceKey(ASpec), ASource);
  DebugMemo.Lines.Add(Format('Level: %s%s loaded in %d ms, its pieces drawn as GPU instances ' +
    'of it; %s', [ASpec.Name, IfThen(ASpec.VariantName <> String.Empty, ' (' +
    ASpec.VariantName + ')', ''), Watch.ElapsedMilliseconds, IfThen(ASource.IsStatic,
    'static, so its meshes are made static',
    LowerCase(ModelKindName(Kind)) + ', so its meshes are not made static')]));
  Result := True;
end;

// Every piece is a GPU instance of its model's template, posed by MovePiece.
function TMainForm.PlacePiece(const ASpec: TSprite3DPieceSpec; var ASource: TPieceSource;
  const AFrom: TPoint3D; const ALand: Single): Boolean;
var
  Piece: TLevelPiece;
  Ticks: Int64;
begin
  Result := False;
  Ticks := TStopwatch.GetTimeStamp;
  Piece.Model := ASource.Template;
  Piece.Instance := nil;
  Inc(FNextPieceId);
  Piece.Id := FNextPieceId;
  // Every field set here: Default() cannot be used in this unit, as
  // Gorilla.DefTypes' unscoped enumeration value Default hides it
  Piece.Spec := ASpec;
  Piece.Landed := Point3D(AFrom.X, ALand, AFrom.Z);
  Piece.Turn := 0;
  Piece.Turned := ASpec.Box;
  Piece.Falling := True;
  Piece.FromY := AFrom.Y;
  Piece.Started := FClock.Elapsed.TotalSeconds;
  try
    Inc(FInstanceSerial);
    Piece.Instance := ASource.Template.AddInstanceItem(Format('Piece%d', [FInstanceSerial]));
  except
    on E: Exception do
    begin
      DebugMemo.Lines.Add('Level: can''t add a piece of ' + ASpec.Name + ': ' + E.Message);
      Exit;
    end;
  end;
  MovePiece(Piece, AFrom.Y);
  Inc(FSetupTicks, TStopwatch.GetTimeStamp - Ticks);
  FPieces.Add(Piece);
  Result := True;
end;

// Puts a piece's origin at height AY in the level, above where it lands,
// turned by its Turn. An instance's transform is absolute, in the viewport's
// coordinates, replacing the template's, and RotationAngle on an instance
// adds to its turn (Gorilla's v1.5 documentation): so FPoser, a child of the
// level, is given the position and turn the piece has, and the instance its
// whole matrix with SetTransform.
procedure TMainForm.MovePiece(const APiece: TLevelPiece; const AY: Single);
begin
  FPoser.Position.Point := Point3D(APiece.Landed.X, AY, APiece.Landed.Z);
  FPoser.ResetRotationAngle;
  FPoser.RotationAngle.Y := APiece.Turn;
  APiece.Instance.SetTransform(FPoser.AbsoluteMatrix);
end;

{ Rotate and Bend }

function TMainForm.TurnVector(const AVector: TPoint3D; const ADegrees: Single): TPoint3D;
var
  S, C: Single;
begin
  // FTurnSign says which way FMX turns: (1, 0, 0) turned by 90 is
  // (0, 0, FTurnSign)
  SinCos(DegToRad(ADegrees), S, C);
  S := S * FTurnSign;
  Result := Point3D(AVector.X * C - AVector.Z * S, AVector.Y, AVector.X * S + AVector.Z * C);
end;

function TMainForm.TurnedBox(const ABox: TBoundingBox; const ADegrees: Single): TBoundingBox;
var
  P: TPoint3D;
  MinX, MaxX, MinZ, MaxZ: Single;
begin
  if ADegrees = 0 then
    Exit(ABox);
  MinX := MaxSingle;
  MaxX := -MaxSingle;
  MinZ := MaxSingle;
  MaxZ := -MaxSingle;
  for var I := 0 to 3 do
  begin
    // System.Math's: System.StrUtils, also used here, has IfThen for strings
    P := TurnVector(Point3D(System.Math.IfThen(Odd(I), ABox.Right, ABox.Left), 0,
      System.Math.IfThen(I >= 2, ABox.Far, ABox.Near)), ADegrees);
    MinX := Min(MinX, P.X);
    MaxX := Max(MaxX, P.X);
    MinZ := Min(MinZ, P.Z);
    MaxZ := Max(MaxZ, P.Z);
  end;
  Result := TBoundingBox.Create(Point3D(MinX, ABox.Top, MinZ), Point3D(MaxX, ABox.Bottom, MaxZ));
end;

function TMainForm.PieceMiddle(const APiece: TLevelPiece): TPointF;
var
  V: TPoint3D;
begin
  V := TurnVector(Point3D((APiece.Spec.BoxMin.X + APiece.Spec.BoxMax.X) / 2, 0,
    (APiece.Spec.BoxMin.Z + APiece.Spec.BoxMax.Z) / 2), APiece.Turn);
  Result := TPointF.Create(APiece.Landed.X + V.X, APiece.Landed.Z + V.Z);
end;

// The line of sight under the pointer is found from the floor point and the
// point over it at the height of the tallest piece; each piece's own box,
// in its own turn, is tested against it. The view looks down on the level,
// so the nearest piece is the one the line meets highest up the line.
function TMainForm.PieceAt(const AScreen: TPointF): Integer;
var
  Over: Boolean;
  OnFloor, OnTop: TPointF;
  Top, Best, TNear, TFar: Single;
  A, B: TPoint3D;
  Piece: TLevelPiece;
begin
  Result := -1;
  if (FPieces = nil) or (FPieces.Count = 0) then
    Exit;
  Top := FSettings.GridSize;
  for var I := 0 to FPieces.Count - 1 do
    Top := Max(Top, FPieces[I].Box.Bottom);
  if not LevelPlaneAt(AScreen, 0, Over, OnFloor) or not LevelPlaneAt(AScreen, Top, Over, OnTop) then
    Exit;
  A := Point3D(OnFloor.X, 0, OnFloor.Y);
  B := Point3D(OnTop.X, Top, OnTop.Y);
  Best := -MaxSingle;
  for var I := 0 to FPieces.Count - 1 do
  begin
    Piece := FPieces[I];
    // Into the piece's own coordinates: a turn and a shift keep where
    // along the line each point is
    if LineThroughBox(TurnVector(A - Piece.Landed, -Piece.Turn),
      TurnVector(B - Piece.Landed, -Piece.Turn), Piece.Spec.Box, TNear, TFar) and
      (TFar > Best) then
    begin
      Best := TFar;
      Result := I;
    end;
  end;
end;

// A control's size is taken as centred on its position, so it is made
// large enough each way to reach the box's farthest side from there
procedure TMainForm.FitOutline(const AOutline: TSprite3DPlacementBox);
var
  B: TBoundingBox;
begin
  B := AOutline.Box;
  AOutline.Width := Max(2 * Max(Abs(B.Left), Abs(B.Right)), 0.01);
  AOutline.Height := Max(2 * Max(Abs(B.Top), Abs(B.Bottom)), 0.01);
  AOutline.Depth := Max(2 * Max(Abs(B.Near), Abs(B.Far)), 0.01);
end;

procedure TMainForm.ShowPick(const AIndex: Integer);
var
  Piece: TLevelPiece;
  Index: Integer;
begin
  FPicked := -1;
  Index := AIndex;
  // Variants points at pieces with variants only
  if VariantToolOn and (Index >= 0) and (FPieces <> nil) and (Index < FPieces.Count) and
    (Length(VariantNamesOf(FPieces[Index].Spec)) = 0) then
    Index := -1;
  if (FPickBox <> nil) and (FPieces <> nil) and (Index >= 0) and (Index < FPieces.Count) then
  begin
    FPicked := Index;
    Piece := FPieces[Index];
    FPickBox.Box := Piece.Spec.Box;
    if EraseToolOn then
      FPickBox.Color := ERASE_BOX_COLOUR
    else if VariantToolOn then
      FPickBox.Color := VARIANT_PICK_COLOUR
    else
      FPickBox.Color := PICK_BOX_COLOUR;
    FPickBox.Position.Point := Piece.Landed;
    FPickBox.ResetRotationAngle;
    FPickBox.RotationAngle.Y := Piece.Turn;
    FitOutline(FPickBox);
    FPickBox.Visible := True;
  end
  else if FPickBox <> nil then
    FPickBox.Visible := False;
  UpdateStatus;
end;

procedure TMainForm.EditInstances(const ABegin: Boolean);
begin
  if FSources = nil then
    Exit;
  for var Source in FSources.Values do
    if ABegin then
      Source.Template.BeginInstancesEditing
    else
      Source.Template.EndInstancesEditing;
end;

// Bend: pieces are joined when they stand on the same base, share most of
// their height, and their footprints touch or overlap. Pressed with the
// left button, the piece pressed on is hinged to the joined piece nearest
// it on its left, as the view shows them, and it and every piece joined to
// it, short of crossing that hinge, turn about the hinge: the point halfway
// between the two pieces' middles. The right button is the same with left
// and right swapped.
function TMainForm.StartTurn(const AIndex: Integer; const AReversed: Boolean;
  const AX: Single; const AButton: TMouseButton): Boolean;
var
  Saved: TArray<TLevelPiece>;
  Gap: Single;

  function Joined(const A, B: TLevelPiece): Boolean;
  var
    BoxA, BoxB: TBoundingBox;
  begin
    BoxA := A.Box;
    BoxB := B.Box;
    // TBoundingBox: Top is the low Y, the base; Bottom the high Y
    Result := (Abs(BoxA.Top - BoxB.Top) <= Gap) and
      (Min(BoxA.Bottom, BoxB.Bottom) - BoxA.Top >=
        0.5 * Max(BoxA.Bottom - BoxA.Top, BoxB.Bottom - BoxB.Top)) and
      (BoxA.Left <= BoxB.Right + Gap) and (BoxB.Left <= BoxA.Right + Gap) and
      (BoxA.Near <= BoxB.Far + Gap) and (BoxB.Near <= BoxA.Far + Gap);
  end;

  // Across the view, in pixels, where a piece's middle shows
  function ScreenX(const APiece: TLevelPiece; out ASX: Single): Boolean;
  var
    Mid: TPointF;
    Box: TBoundingBox;
    SY: Single;
  begin
    Mid := PieceMiddle(APiece);
    Box := APiece.Box;
    Result := GorillaCamera.ProjectToView(Point3D(Mid.X, (Box.Top + Box.Bottom) / 2, Mid.Y),
      FLevel, GorillaViewport.Width, GorillaViewport.Height, ASX, SY);
  end;

var
  Hinge: Integer;
  Here, There, BestX: Single;
  Taken: TArray<Boolean>;
  Queue: TList<Integer>;
  Mid, HingeMid: TPointF;
  Side: String;
begin
  Result := False;
  if (AIndex < 0) or (FPieces = nil) or (AIndex >= FPieces.Count) then
    Exit;
  Saved := FPieces.ToArray;
  if RotateToolOn then
  begin
    FTurnSet := [AIndex];
    FTurnHinge := PieceMiddle(Saved[AIndex]);
  end
  else
  begin
    Gap := 0.05 * FSettings.GridSize;
    if not ScreenX(Saved[AIndex], Here) then
      Exit;
    // The joined piece nearest on the side bent at
    Hinge := -1;
    BestX := 0;
    for var I := 0 to High(Saved) do
      if (I <> AIndex) and Joined(Saved[AIndex], Saved[I]) and ScreenX(Saved[I], There) then
        if (not AReversed and (There < Here) and ((Hinge < 0) or (There > BestX))) or
          (AReversed and (There > Here) and ((Hinge < 0) or (There < BestX))) then
        begin
          Hinge := I;
          BestX := There;
        end;
    Side := IfThen(AReversed, 'right', 'left');
    if Hinge < 0 then
    begin
      DebugMemo.Lines.Add(Format('Level: Bend: nothing is joined to %s on its %s to bend ' +
        'at', [Saved[AIndex].Spec.Name, Side]));
      Exit;
    end;
    Mid := PieceMiddle(Saved[AIndex]);
    HingeMid := PieceMiddle(Saved[Hinge]);
    FTurnHinge := TPointF.Create((Mid.X + HingeMid.X) / 2, (Mid.Y + HingeMid.Y) / 2);
    // The piece pressed on and all joined to it, never through the hinge
    // piece: a run closed in a ring comes back to the hinge piece, which
    // stays
    SetLength(Taken, Length(Saved));
    Taken[Hinge] := True;
    Taken[AIndex] := True;
    // Breadth first; the list read from the front is the set turned
    Queue := TList<Integer>.Create;
    try
      Queue.Add(AIndex);
      var Next := 0;
      while Next < Queue.Count do
      begin
        var At := Queue[Next];
        Inc(Next);
        for var I := 0 to High(Saved) do
          if not Taken[I] and Joined(Saved[At], Saved[I]) then
          begin
            Taken[I] := True;
            Queue.Add(I);
          end;
      end;
      FTurnSet := Queue.ToArray;
    finally
      Queue.Free;
    end;
  end;
  // What is stacked on the pieces turned goes round with them: the pieces
  // resting on them, and on those, as Move Object finds them; never what
  // they rest on. With Bend, what rests on the hinge piece alone stays
  FTurnCarried := 0;
  begin
    var InSet: TArray<Boolean>;
    SetLength(InSet, Length(Saved));
    for var M in FTurnSet do
      InSet[M] := True;
    var Turned := TList<Integer>.Create;
    try
      Turned.AddRange(FTurnSet);
      for var M in FTurnSet do
        for var R in RidersOf(M) do
          if not InSet[R] then
          begin
            InSet[R] := True;
            Turned.Add(R);
            Inc(FTurnCarried);
          end;
      FTurnSet := Turned.ToArray;
    finally
      Turned.Free;
    end;
  end;
  FTurnSaved := Saved;
  FTurnDown := True;
  FTurnButton := AButton;
  FTurnStartX := AX;
  FTurnBy := 0;
  ShowPick(AIndex);
  Result := True;
end;

procedure TMainForm.ApplyTurn(const ADegrees: Single);
var
  Piece, Live: TLevelPiece;
  Mid: TPointF;
  V, Offset: TPoint3D;
begin
  FTurnBy := ADegrees;
  EditInstances(True);
  try
    for var K in FTurnSet do
    begin
      Piece := FTurnSaved[K];
      // Its middle swung about the hinge, and it turned with it
      Mid := PieceMiddle(Piece);
      V := TurnVector(Point3D(Mid.X - FTurnHinge.X, 0, Mid.Y - FTurnHinge.Y), ADegrees);
      Piece.Turn := Piece.Turn + ADegrees;
      Piece.Turn := Piece.Turn - 360 * Floor(Piece.Turn / 360);
      Offset := TurnVector(Point3D((Piece.Spec.BoxMin.X + Piece.Spec.BoxMax.X) / 2, 0,
        (Piece.Spec.BoxMin.Z + Piece.Spec.BoxMax.Z) / 2), Piece.Turn);
      Piece.Landed.X := FTurnHinge.X + V.X - Offset.X;
      Piece.Landed.Z := FTurnHinge.Y + V.Z - Offset.Z;
      Piece.Turned := TurnedBox(Piece.Spec.Box, Piece.Turn);
      // A piece still falling goes on falling, and the fall poses it
      Live := FPieces[K];
      Piece.Falling := Live.Falling;
      Piece.FromY := Live.FromY;
      Piece.Started := Live.Started;
      FPieces[K] := Piece;
      if not Piece.Falling then
        MovePiece(Piece, Piece.Landed.Y);
    end;
  finally
    EditInstances(False);
  end;
  if FTurnSet <> nil then
    ShowPick(FTurnSet[0]);
end;

procedure TMainForm.EndTurn;
var
  Piece, Other: TLevelPiece;
  Spot, Shift: TPointF;
  Square: Boolean;
begin
  if not FTurnDown then
    Exit;
  FTurnDown := False;
  if (FTurnSet = nil) or (FTurnBy = 0) then
  begin
    UpdateStatus;
    Exit;
  end;
  MarkLevelChanged;
  Piece := FPieces[FTurnSet[0]];
  Square := Abs(Piece.Turn / 90 - Round(Piece.Turn / 90)) < 1E-4;
  if RotateToolOn and Square then
  begin
    // Square to the grid again: snapped as placing snaps, by its turned
    // box; what it carries moves with it
    Spot := SnapPiecePosition(PieceMiddle(Piece), Piece.Turned, FSettings.GridSize);
    Shift := TPointF.Create(Spot.X - Piece.Landed.X, Spot.Y - Piece.Landed.Z);
    EditInstances(True);
    try
      for var K in FTurnSet do
      begin
        Other := FPieces[K];
        Other.Landed.X := Other.Landed.X + Shift.X;
        Other.Landed.Z := Other.Landed.Z + Shift.Y;
        FPieces[K] := Other;
        if not Other.Falling then
          MovePiece(Other, Other.Landed.Y);
      end;
    finally
      EditInstances(False);
    end;
    Piece := FPieces[FTurnSet[0]];
  end;
  if RotateToolOn then
    DebugMemo.Lines.Add(Format('Level: turned %s by %.4g, to %.4g degrees%s%s',
      [Piece.Spec.Name, FTurnBy, Piece.Turn, IfThen(FTurnCarried > 0,
      Format(', with the %d piece(s) stacked on it', [FTurnCarried]), ''),
      IfThen(Square, ', snapped to the grid', '')]))
  else
    DebugMemo.Lines.Add(Format('Level: bent %d piece(s) from %s by %.4g degrees about ' +
      '(%.3g, %.3g)%s', [Length(FTurnSet) - FTurnCarried, Piece.Spec.Name, FTurnBy,
      FTurnHinge.X, FTurnHinge.Y, IfThen(FTurnCarried > 0,
      Format(', with the %d piece(s) stacked on them', [FTurnCarried]), '')]));
  ShowPick(FTurnSet[0]);
end;

function TMainForm.TurnStatus: String;
var
  Step, What: String;
begin
  Step := Format('Drag left or right: turn it in steps of %.4g'#176' (hold Shift: freely).',
    [FSettings.RotateSnap]);
  if RotateToolOn then
  begin
    if FTurnDown and (FTurnSet <> nil) then
      Exit(Format('Rotate: %s, turned by %.4g'#176'.  Let go: leave it there.  Shift: turn ' +
        'freely.', [FPieces[FTurnSet[0]].Spec.Name, FTurnBy]));
    if (FPicked >= 0) and (FPicked < FPieces.Count) then
      What := 'Rotate: ' + FPieces[FPicked].Spec.Name + '.  '
    else
      What := 'Rotate: point at a piece.  ';
    Result := What + Step + '  Double-click the tool: the step.  Wheel: zoom.  ' +
      'Right-click: normal view.';
  end
  else
  begin
    if FTurnDown and (FTurnSet <> nil) then
      Exit(Format('Bend: %d piece(s) turned by %.4g'#176' about the join.  Let go: leave them ' +
        'there.  Shift: turn freely.', [Length(FTurnSet) - FTurnCarried, FTurnBy]));
    if (FPicked >= 0) and (FPicked < FPieces.Count) then
      What := 'Bend: ' + FPieces[FPicked].Spec.Name + '.  '
    else
      What := 'Bend: point at a piece of a run.  ';
    Result := What + 'Left-drag left or right: it and the pieces to its right turn about its ' +
      'join with the piece to its left.  Right-drag: it and those to its left, about the join ' +
      'on its right.  Up and down do nothing.  ' +
      Format('Steps of %.4g'#176' (Shift: freely).  Wheel: zoom.', [FSettings.RotateSnap]);
  end;
end;

// Frees the templates, from FSources, and with each its instances, so
// every piece, and the templates kept with no pieces left
procedure TMainForm.FreeLevelPieces;
begin
  if FFallTimer <> nil then
    FFallTimer.Enabled := False;
  if FPieces = nil then
    Exit;
  FTurnDown := False;
  FTurnSet := nil;
  FTurnSaved := nil;
  ShowPick(-1);
  FMoveDown := False;
  FPanDown := False;
  if FVariantMarks <> nil then
    FVariantMarks.Clear;
  if FSources <> nil then
  begin
    for var Source in FSources.Values do
      Source.Template.Free;
    FSources.Clear;
  end;
  FPieces.Clear;
end;

procedure TMainForm.FallTimerTimer(Sender: TObject);
var
  Elapsed, Longest: Double;
  Gravity, Y: Single;
  Piece: TLevelPiece;
  AnyFalling: Boolean;
begin
  Longest := 0;
  if MainFormGone or (FPieces = nil) then
  begin
    FFallTimer.Enabled := False;
    Exit;
  end;
  Elapsed := FClock.Elapsed.TotalSeconds;
  Gravity := FALL_GRAVITY_CELLS * FSettings.GridSize;
  AnyFalling := False;
  // Each template's instances sent to the GPU once a step, not once a piece
  for var Source in FSources.Values do
    Source.Template.BeginInstancesEditing;
  try
    for var I := 0 to FPieces.Count - 1 do
    begin
      Piece := FPieces[I];
      if not Piece.Falling then
        Continue;
      if FallHeight(Piece.FromY, Piece.Landed.Y, Gravity, Elapsed - Piece.Started, Y) then
      begin
        Piece.Falling := False;
        Longest := Max(Longest, Elapsed - Piece.Started);
      end
      else
        AnyFalling := True;
      MovePiece(Piece, Y);
      FPieces[I] := Piece;
    end;
  finally
    for var Source in FSources.Values do
      Source.Template.EndInstancesEditing;
  end;
  if not AnyFalling then
  begin
    FFallTimer.Enabled := False;
    DebugMemo.Lines.Add(Format('Level: landed, %d ms after being let go',
      [Round(Longest * 1000)]));
  end;
end;

procedure TMainForm.ShowBoundsItemClick(Sender: TObject);
begin
  ShowBoundsItem.IsChecked := not ShowBoundsItem.IsChecked;
  ApplyShowBounds;
end;

procedure TMainForm.HeadlightItemClick(Sender: TObject);
begin
  HeadlightItem.IsChecked := not HeadlightItem.IsChecked;
  ApplyLights;
end;

procedure TMainForm.OriginalLightItemClick(Sender: TObject);
begin
  OriginalLightItem.IsChecked := not OriginalLightItem.IsChecked;
  ApplyLights;
end;

// The lights to match View, Lights. Both are point lights on the camera at
// its origin, so they sit where the camera is and point where it looks,
// lighting whatever side of the level is in view: the headlight is made and
// freed by OrbitCamera itself; the original light, the one the form made by
// hand before the Spritely camera, by this. The Debug tab gets a line only
// when what is on changes, so restoring the settings at start-up says once
// what the session starts with.
procedure TMainForm.ApplyLights;
const
  ON_OFF: array[Boolean] of String = ('off', 'on');
var
  WasHead, WasOriginal: Boolean;
begin
  if GorillaCamera = nil then
    Exit;
  WasHead := OrbitCamera.Light <> nil;
  WasOriginal := GorillaLight <> nil;
  OrbitCamera.Headlight := HeadlightItem.IsChecked;
  if OriginalLightItem.IsChecked and (GorillaLight = nil) then
  begin
    GorillaLight := TGorillaLight.Create(GorillaViewport);
    GorillaLight.Parent := GorillaCamera;
    GorillaLight.Position.Point := TPoint3D.Zero;
    GorillaLight.RotationAngle.Point := TPoint3D.Zero;
    GorillaLight.LightType := TLightType.Point;
  end
  else if not OriginalLightItem.IsChecked and (GorillaLight <> nil) then
    FreeAndNil(GorillaLight);
  if (WasHead <> (OrbitCamera.Light <> nil)) or (WasOriginal <> (GorillaLight <> nil)) or
    not FLightsLogged then
  begin
    FLightsLogged := True;
    DebugMemo.Lines.Add('Lights: headlight ' + ON_OFF[OrbitCamera.Light <> nil] +
      ', original light ' + ON_OFF[GorillaLight <> nil]);
  end;
end;

// Every placed piece's bounding box to match ShowBoundsItem; with no piece
// placed yet, only the tick changes
procedure TMainForm.ApplyShowBounds;
begin
  if FLevel = nil then
    Exit;
  for var I := 0 to FLevel.ChildrenCount - 1 do
    if FLevel.Children[I] is TGorillaModel then
      TGorillaModel(FLevel.Children[I]).ShowBoundingBox := ShowBoundsItem.IsChecked;
end;

// The level's root, FLevel, and its grid, FGrid, at the spacing kept in
// settings.json. The root is turned 180 degrees about X, as each model was
// in Sprite3D, because FMX's Y points down: inside it Y is up, as the kits'
// pieces have it, and the floor is Y = 0. The grid lies on that floor, its
// lines through the root's origin, and reaches GridCells cells each way.
procedure TMainForm.BuildLevel;
const
  // The grid's own box: only its floor and centre matter, as it is never
  // fitted to or counted in bounds
  GRID_EXTENT = 1;
begin
  FLevel := TDummy.Create(GorillaViewport);
  FLevel.Parent := GorillaViewport;
  FLevel.HitTest := False;
  FLevel.RotationAngle.X := 180;

  // Where a piece dragged from the Library would go, and the pieces placed
  FPlaceBox := TSprite3DPlacementBox.Create(nil);
  FPlaceBox.Parent := FLevel;   // freed with it
  FPlaceBox.Color := PLACE_BOX_COLOUR;
  FPlaceBox.Visible := False;
  FPieces := TList<TLevelPiece>.Create;
  FSources := TDictionary<String, TPieceSource>.Create;
  FVariantNames := TDictionary<String, TArray<String>>.Create;
  FVariantMarks := TObjectList<TSprite3DPlacementBox>.Create(True);
  FVariantTarget := -1;
  // Place Model picks among several models at random
  Randomize;

  // Rotate and Bend: the outline round the piece under the pointer, and the
  // hidden poser that gives an instance its transform
  FPickBox := TSprite3DPlacementBox.Create(nil);
  FPickBox.Parent := FLevel;   // freed with it
  FPickBox.Color := PICK_BOX_COLOUR;
  FPickBox.Visible := False;
  FPicked := -1;
  FPoser := TDummy.Create(nil);
  FPoser.Parent := FLevel;     // freed with it
  FPoser.Visible := False;
  FPoser.HitTest := False;
  // Which way FMX turns a child of the level for a positive angle, so the
  // sums here turn as the models do
  FPoser.RotationAngle.Y := 90;
  begin
    var Probe := FLevel.AbsoluteToLocal3D(FPoser.LocalToAbsolute3D(Point3D(1, 0, 0)));
    if Probe.Z < 0 then
      FTurnSign := -1
    else
      FTurnSign := 1;
  end;
  FPoser.ResetRotationAngle;
  FFallTimer := TTimer.Create(Self);
  FFallTimer.Enabled := False;
  FFallTimer.Interval := FALL_STEP_MS;
  FFallTimer.OnTimer := FallTimerTimer;
  FClock := TStopwatch.StartNew;

  FGrid := TModelGrid.Create(nil);
  FGrid.Parent := FLevel;   // freed with it
  FGrid.GridSize := FSettings.GridSize;
  // The floor itself, not the lowest face of a box: sets GridOnFloor off
  FGrid.GridLevel := 0;
  FGrid.SetExtent(Point3D(-GRID_EXTENT, 0, -GRID_EXTENT),
    Point3D(GRID_EXTENT, 0, GRID_EXTENT), TPoint3D.Zero);
end;

// The frame rate readout, top left over the view on a dark backing, made here rather than in
// the form designer. It lets clicks through, and is refreshed a few
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

// The frames per second Gorilla's viewport reports
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
  CheckDisplay;
  // A new model shows the normal view, refitted or not; the
  // distance's difference follows a refit of the same one
  CheckMouseViewSubject;
end;

// View, Camera, Lock Camera, below the views and a line. It is not one of
// the views: IsCameraViewItem leaves it out, so choosing a view never clears
// its tick and settings.json never keeps it as the view.
procedure TMainForm.BuildLockCameraItem;
begin
  FLockSeparatorItem := TMenuItem.Create(Self);
  FLockSeparatorItem.Text := '-';
  CameraMenu.AddObject(FLockSeparatorItem);
  {$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
  // Mouse View, above Lock Camera; it needs a mouse
  BuildMouseViewItem;
  {$ENDIF}
  FLockCameraItem := TMenuItem.Create(Self);
  FLockCameraItem.Text := 'Lock Camera';
  FLockCameraItem.IsChecked := False;
  FLockCameraItem.OnClick := LockCameraItemClick;
  CameraMenu.AddObject(FLockCameraItem);
  // The views as the projection allows: a session that starts in an oblique
  // projection chose it (RestoreViewToggles) before this item was made, when
  // UpdateCameraLockControls had nothing to work with
  UpdateCameraLockControls;
end;

// True while View, Camera, Lock Camera is ticked
function TMainForm.CameraLocked: Boolean;
begin
  Result := Assigned(FLockCameraItem) and FLockCameraItem.IsChecked;
end;

// One of the View, Camera views, rather than Mouse View, Lock
// Camera or a line
function TMainForm.IsCameraViewItem(const AItem: TMenuItem): Boolean;
begin
  Result := (AItem <> FLockCameraItem) and (AItem <> FLockSeparatorItem) and
    (AItem <> FMouseViewItem) and (AItem.Text <> '-');
end;

// Ticks or unticks Lock Camera. The camera keeps exactly what it has; on
// unlocking nothing is refitted, so the view stays put until something
// changes it.
procedure TMainForm.LockCameraItemClick(Sender: TObject);
begin
  FLockCameraItem.IsChecked := not FLockCameraItem.IsChecked;
  UpdateCameraLockControls;
  UpdateCaption;
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
  // While an oblique projection is chosen only Variable
  for I := 0 to CameraMenu.ItemsCount - 1 do
    if IsCameraViewItem(CameraMenu.Items[I]) then
      CameraMenu.Items[I].Enabled := not Locked and
        (not FObliqueActive or (CameraMenu.Items[I] = ViewVariableItem));
  // Every item itself, not only ObliqueMenu: the mobile drawer lists the
  // oblique items as rows of their own and checks each one's Enabled
  ObliqueMenu.Enabled := not Locked;
  for var Kind := Low(TSprite3DProjection) to High(TSprite3DProjection) do
    ProjectionItem(Kind).Enabled := not Locked;
end;

// Mouse View
//
// While View, Camera, Mouse View is ticked, the mouse can turn and
// zoom the view to look the level over: left-drag left or right turns it,
// the wheel moves the camera nearer or further, and a right click puts the
// normal view back. It is for looking only and has no lasting effect: the
// dials, the views, the fit, Lock Camera and settings.json never hear of it,
// and a new model shows the normal view. It works whether or not the camera is
// locked, which is why ShiftCamera unlocks the camera for each change.
//
// The turn and zoom are kept as offsets on top of the normal view, not as a
// view of their own. Code that sets the normal view (FitModel, ApplyAngles,
// ShowDistanceFactor, ShowCameraSpec) takes them off first with
// SuspendMouseView and puts them back after with ResumeMouseView, so the
// normal view always comes out as it would without them, and a refit of the
// same model keeps the mouse view on top of the new fit.
//
// The view takes the mouse only while the item is ticked: AspectLayout,
// under the viewport and its surround, is otherwise left with HitTest off,
// as before, so nothing else changes.
procedure TMainForm.BuildMouseViewItem;
begin
  FMouseViewItem := TMenuItem.Create(Self);
  FMouseViewItem.Text := 'Mouse View';
  FMouseViewItem.IsChecked := False;
  FMouseViewItem.OnClick := MouseViewItemClick;
  CameraMenu.AddObject(FMouseViewItem);

  AspectLayout.OnMouseDown := ViewMouseDown;
  AspectLayout.OnMouseMove := ViewMouseMove;
  AspectLayout.OnMouseUp := ViewMouseUp;
  AspectLayout.OnMouseWheel := ViewMouseWheel;
  AspectLayout.OnMouseLeave := ViewMouseLeave;
  // A turn or an area goes on while the pointer is outside the view
  AspectLayout.AutoCapture := True;

  // Ticked as it was left last session, from the normal view
  ApplyMouseViewTick(FSettings.MouseView);
end;

// Mouse View is one of the palette's two tools; off, Place Model is on. The
// view takes the mouse either way: left-drag turns it or places, a right
// click puts the normal view back and the wheel zooms, with either tool.
// Choosing Place Model does not put the normal view back, so a view turned
// to place pieces in stays turned
procedure TMainForm.ApplyMouseViewTick(const AOn: Boolean);
begin
  FMouseViewItem.IsChecked := AOn;
  FMouseDragging := False;
  FPlaceDown := False;
  FTurnDown := False;
  if FMoveDown then
    EndMove;
  FPanDown := False;
  HidePlacement;
  ShowPick(-1);
  AspectLayout.HitTest := True;
  UpdatePalette;
end;

function TMainForm.MouseViewOn: Boolean;
begin
  Result := Assigned(FMouseViewItem) and FMouseViewItem.IsChecked;
end;

procedure TMainForm.MouseViewItemClick(Sender: TObject);
begin
  ChooseTool(not FMouseViewItem.IsChecked);
end;

procedure TMainForm.ChooseTool(const AMouseView: Boolean);
begin
  if Assigned(FMouseViewItem) and (MouseViewOn = AMouseView) then
    Exit;
  ApplyMouseViewTick(AMouseView);
  // Kept at once, as only the tick is kept
  FSettings.MouseView := MouseViewOn;
  try
    FSettings.Save;
  except
    on E: Exception do
      DebugMemo.Lines.Add('Can''t save the settings to ' + FSettings.FileName + ': ' +
        E.Message);
  end;
  if MouseViewOn then
    DebugMemo.Lines.Add('Mouse View: left-drag turns the view, the wheel zooms, a right ' +
      'click puts the normal view back')
  else
    LogEditTool;
end;

procedure TMainForm.LogEditTool;
begin
  case FEditTool of
    etPlace:
      DebugMemo.Lines.Add('Place Model: a click places the model chosen in the Library, a ' +
        'drag an area of it; the wheel zooms, a right click puts the normal view back');
    etErase:
      DebugMemo.Lines.Add('Erase: a click takes the piece out of the level; what rested on ' +
        'it falls');
    etMove:
      DebugMemo.Lines.Add('Move Object: drag a piece across the level, snapped to the grid, ' +
        'freely with Shift held; it rests on what is under it, and what rested on it falls');
    etPan:
      DebugMemo.Lines.Add('Move Camera: drag the level to slide the view across it; a right ' +
        'click puts the normal view back');
    etRotate:
      DebugMemo.Lines.Add(Format('Rotate: drag a piece left or right to turn it about its ' +
        'middle, in steps of %.4g degrees, freely with Shift held; a right click puts the ' +
        'normal view back', [FSettings.RotateSnap]));
    etBend:
      DebugMemo.Lines.Add(Format('Bend: left-drag a piece of a run to turn it and the pieces ' +
        'to its right about its join with the piece to its left; right-drag for the other ' +
        'way; in steps of %.4g degrees, freely with Shift held', [FSettings.RotateSnap]));
    etVariant:
      DebugMemo.Lines.Add('Variants: the pieces whose models have material variants are ' +
        'outlined; a click on one chooses its variant, Shift-click for every piece of its ' +
        'model');
  end;
end;

procedure TMainForm.ChooseEditTool(const ATool: TLevelEditTool);
begin
  if (FEditTool = ATool) and not MouseViewOn then
    Exit;
  FEditTool := ATool;
  if MouseViewOn then
    // Turns Mouse View off, which logs the tool
    ChooseTool(False)
  else
  begin
    ApplyMouseViewTick(False);
    LogEditTool;
  end;
end;

procedure TMainForm.RotateButtonClick(Sender: TObject);
begin
  ChooseEditTool(etRotate);
end;

procedure TMainForm.BendButtonClick(Sender: TObject);
begin
  ChooseEditTool(etBend);
end;

procedure TMainForm.TurnButtonDblClick(Sender: TObject);
begin
  if Sender = FBendButton then
    ChooseEditTool(etBend)
  else
    ChooseEditTool(etRotate);
  ShowRotationSnap;
end;

procedure TMainForm.RotationSnapItemClick(Sender: TObject);
begin
  ShowRotationSnap;
end;

procedure TMainForm.ShowRotationSnap;
var
  Step: Single;
begin
  Step := FSettings.RotateSnap;
  if not TRotationSnapForm.Execute(Step, ROTATE_SNAP_MIN, ROTATE_SNAP_MAX) then
    Exit;
  FSettings.RotateSnap := Step;
  try
    FSettings.Save;
  except
    on E: Exception do
      DebugMemo.Lines.Add('Can''t save the settings to ' + FSettings.FileName + ': ' +
        E.Message);
  end;
  DebugMemo.Lines.Add(Format('Rotate and Bend turn in steps of %.4g degrees',
    [FSettings.RotateSnap]));
  UpdateStatus;
end;

function TMainForm.MouseViewSubject: String;
begin
  // The level; a refit of it keeps the mouse view on top
  if Assigned(FLevel) then
    Result := 'level'
  else
    Result := String.Empty;
end;

procedure TMainForm.ShiftCamera(const AYaw, AZoom: Single; const AOrtho: Boolean);
var
  WasLocked, Slid: Boolean;
begin
  if not Assigned(GorillaCamera) then
    Exit;
  // Whether or not Lock Camera is ticked; the lock is back as it was after
  WasLocked := GorillaCamera.Locked;
  GorillaCamera.Locked := False;
  // The shift and rise placed again after the turn or zoom, as the level's
  // size in the picture, and so how far it can slide, changes with them. An
  // orthographic slide is off while turning, so the camera turns about the
  // model's own axis
  Slid := FFitted and FPlaceEnabled and
    ((FPlaceShift <> 0) or (FPlaceRise <> 0));
  if Slid then
    TakeOffSlide;
  try
    if AYaw <> 0 then
      GorillaCamera.Azimuth := GorillaCamera.Azimuth + AYaw;
    if AZoom <> 1 then
      if AOrtho then
      begin
        // In orthographic projection the distance does not change the size
        GorillaCamera.OrthoHeight := GorillaCamera.OrthoHeight * AZoom;
        if GorillaCamera.OrthoWidth > 0 then
          GorillaCamera.OrthoWidth := GorillaCamera.OrthoWidth * AZoom;
      end
      else
        GorillaCamera.Distance := GorillaCamera.Distance * AZoom;
  finally
    if Slid then
      PlaceShift(FPlaceEnabled, FPlaceShift, FPlaceRise, ViewVolume,
        GorillaViewport.Width, GorillaViewport.Height);
    GorillaCamera.Locked := WasLocked;
  end;
end;

procedure TMainForm.DialogMouseView(const AYaw, AZoom: Single);
const
  // The Variable dialog's Distance slider's range
  DISTANCE_MIN = 0.2;
  DISTANCE_MAX = 20;
var
  Spec: TCameraSettings;
begin
  Spec := FOrbitalDialog.CameraSpec;
  // The mouse view's turn is in the camera's own sense, which the dials
  // reverse; its zoom is a factor on the distance, as the slider's is
  Spec.Azimuth := Wrap360(Spec.Azimuth - AYaw);
  Spec.Distance := EnsureRange(Spec.Distance * AZoom, DISTANCE_MIN, DISTANCE_MAX);
  FOrbitalDialog.TakeSpec(Spec);
  ShowCameraSpec(Spec);
end;

procedure TMainForm.MoveMouseView(const AYaw, AZoom: Single);
var
  Zoom: Single;
begin
  if (FMouseSuspend > 0) or not Assigned(GorillaCamera) or not Assigned(FLevel) then
    Exit;
  // While Variable's dialog is open the wheel and drag change what it edits,
  // so its Distance slider and Azimuth dial show them and OK or Cancel deal
  // with them like any other change made there
  if FOrbitalDialog <> nil then
  begin
    DialogMouseView(AYaw, AZoom);
    Exit;
  end;
  if not FMouseApplied then
  begin
    // The first move from the normal view: what it is of, and which size the
    // zoom changes
    FMouseYaw := 0;
    FMouseZoom := 1;
    FMouseSubject := MouseViewSubject;
    FMouseZoomOrtho := GorillaCamera.IsOrthographic;
  end;
  Zoom := EnsureRange(FMouseZoom * AZoom, MOUSE_VIEW_ZOOM_MIN, MOUSE_VIEW_ZOOM_MAX);
  ShiftCamera(AYaw, Zoom / FMouseZoom, FMouseZoomOrtho);
  FMouseYaw := FMouseYaw + AYaw;
  FMouseYaw := FMouseYaw - 360 * Floor(FMouseYaw / 360);
  FMouseZoom := Zoom;
  FMouseApplied := True;
end;

procedure TMainForm.SuspendMouseView;
begin
  Inc(FMouseSuspend);
  if FMouseApplied then
  begin
    ShiftCamera(-FMouseYaw, 1 / FMouseZoom, FMouseZoomOrtho);
    FMouseApplied := False;
  end;
end;

procedure TMainForm.ResumeMouseView;
begin
  if FMouseSuspend > 0 then
    Dec(FMouseSuspend);
  if (FMouseSuspend > 0) or FMouseApplied or not Assigned(GorillaCamera) then
    Exit;
  if (FMouseYaw = 0) and (FMouseZoom = 1) then
    Exit;
  // On top of the normal view as it now is, zooming whichever size the
  // projection now uses
  FMouseZoomOrtho := GorillaCamera.IsOrthographic;
  ShiftCamera(FMouseYaw, FMouseZoom, FMouseZoomOrtho);
  FMouseApplied := True;
end;

procedure TMainForm.CheckMouseViewSubject;
begin
  if (FMouseSuspend = 0) and ((FMouseYaw <> 0) or (FMouseZoom <> 1)) and
    (MouseViewSubject <> FMouseSubject) then
    ResetMouseView;
end;

procedure TMainForm.ResetMouseView;
begin
  if FMouseApplied then
  begin
    ShiftCamera(-FMouseYaw, 1 / FMouseZoom, FMouseZoomOrtho);
    FMouseApplied := False;
  end;
  FMouseYaw := 0;
  FMouseZoom := 1;
  FMouseSubject := String.Empty;
  FMouseDragging := False;
end;

procedure TMainForm.ViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Spot: TPointF;
  IsRight, Over: Boolean;
  Index: Integer;
begin
  // A Control-click counts as a right-click, as it does on the lists, for a
  // Mac with one button
  IsRight := (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift));
  // Rotate turns with the left button; Bend with either, the right bending
  // the other way. Over no piece, Bend's right button does nothing
  if (RotateToolOn and (Button = TMouseButton.mbLeft) and not IsRight) or
    (BendToolOn and ((Button = TMouseButton.mbLeft) or (Button = TMouseButton.mbRight))) then
  begin
    StartTurn(PieceAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y))), IsRight, X, Button);
    UpdateStatus;
    Exit;
  end;
  // Otherwise the right button puts the normal view back, with any tool:
  // the turn and zoom, and Move Camera's move
  if IsRight then
  begin
    FPlaceDown := False;
    ResetMouseView;
    ResetViewCentre;
    Exit;
  end;
  if Button <> TMouseButton.mbLeft then
    Exit;
  if VariantToolOn then
  begin
    Index := PieceAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    if Index >= 0 then
      ShowPieceVariantMenu(Index, ssShift in Shift,
        AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    Exit;
  end;
  if EraseToolOn then
  begin
    Index := PieceAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    if Index >= 0 then
    begin
      DebugMemo.Lines.Add('Level: took out ' + FPieces[Index].Spec.Name);
      RemovePieces([Index]);
      // The next piece under the pointer, if any
      ShowPick(PieceAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y))));
    end;
    Exit;
  end;
  if MoveToolOn then
  begin
    StartMove(PieceAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y))),
      AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    UpdateStatus;
    Exit;
  end;
  if PanToolOn then
  begin
    FPanDown := LevelFloorAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y)), Over, FPanGrab);
    Exit;
  end;
  if PlaceToolOn then
  begin
    if not FHasBrush then
    begin
      DebugMemo.Lines.Add('Level: choose a model in the Library first (File, Library...)');
      Exit;
    end;
    // The area starts here; a click without a drag is an area of one
    if PlaceSpotAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y)), Spot) then
    begin
      FPlaceDown := True;
      FPlaceAnchor := Spot;
      FPlaceCapLogged := False;
      FPlaceCountX := 1;
      FPlaceCountZ := 1;
      ShowPlacement([Spot]);
    end;
  end
  else if MouseViewOn then
  begin
    FMouseDragging := True;
    FMouseLastX := X;
  end;
end;

procedure TMainForm.ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  Moved, Degrees, Step: Single;
  Held: Boolean;
  Index: Integer;
begin
  if PanToolOn then
  begin
    if FPanDown and not (ssLeft in Shift) then
      FPanDown := False;
    if FPanDown then
      TrackPan(AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    Exit;
  end;
  if MoveToolOn and FMoveDown then
  begin
    // Let go where the view could not see it: ends there
    if not (ssLeft in Shift) then
      EndMove
    else
      TrackMove(AspectLayout.LocalToScreen(TPointF.Create(X, Y)), ssShift in Shift);
    Exit;
  end;
  if PickToolOn then
  begin
    if FTurnDown then
    begin
      // The button let go where the view could not see it ends the turn, as
      // it ends Mouse View's
      if FTurnButton = TMouseButton.mbRight then
        Held := ssRight in Shift
      else
        Held := ssLeft in Shift;
      if not Held then
      begin
        EndTurn;
        Exit;
      end;
      Degrees := (X - FTurnStartX) * TURN_DEGREES_PER_PIXEL;
      Step := FSettings.RotateSnap;
      if not (ssShift in Shift) and (Step > 0) then
        Degrees := Round(Degrees / Step) * Step;
      if not SameValue(Degrees, FTurnBy, 1E-4) then
        ApplyTurn(Degrees);
      Exit;
    end;
    Index := PieceAt(AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    if Index <> FPicked then
      ShowPick(Index);
    Exit;
  end;
  if PlaceToolOn then
  begin
    // The left button let go where the view could not see it: the area is
    // dropped, not placed, and the pointer hovers again
    if FPlaceDown and not (ssLeft in Shift) then
      FPlaceDown := False;
    TrackPlacement(AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
    Exit;
  end;
  if not FMouseDragging then
    Exit;
  // The left button let go where the view could not see it, outside the
  // window or while another window had the mouse, sends no mouse-up: the
  // first move without the button held ends the turn instead, so the pointer
  // coming back over the view turns nothing
  if not MouseViewOn or not (ssLeft in Shift) then
  begin
    FMouseDragging := False;
    Exit;
  end;
  Moved := X - FMouseLastX;
  FMouseLastX := X;
  // Left turns the azimuth the dials show up, right turns it down; the
  // camera's own Azimuth runs the other way, as ApplyAngles shows
  if Moved <> 0 then
    MoveMouseView(Moved * MOUSE_VIEW_DEGREES_PER_PIXEL, 1);
end;

procedure TMainForm.ViewMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if FTurnDown then
  begin
    if Button = FTurnButton then
      EndTurn;
    Exit;
  end;
  if Button <> TMouseButton.mbLeft then
    Exit;
  if FMoveDown then
  begin
    EndMove;
    Exit;
  end;
  if FPanDown then
  begin
    FPanDown := False;
    DebugMemo.Lines.Add(Format('Level: Move Camera: the view''s middle is at (%.3g, %.3g)',
      [FViewCentre.X, FViewCentre.Y]));
    Exit;
  end;
  FMouseDragging := False;
  if FPlaceDown then
  begin
    FPlaceDown := False;
    PlaceShown;
    // Hovering again: on top of what was just placed
    TrackPlacement(AspectLayout.LocalToScreen(TPointF.Create(X, Y)));
  end;
end;

procedure TMainForm.ViewMouseLeave(Sender: TObject);
begin
  if not FPlaceDown then
    HidePlacement;
  if not FTurnDown and not FMoveDown and (FPicked >= 0) then
    ShowPick(-1);
end;

procedure TMainForm.ViewMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  // With either tool
  if not Assigned(FMouseViewItem) then
    Exit;
  Handled := True;
  // A notch is 120; rolling the wheel away brings the camera nearer, towards
  // you takes it further away
  MoveMouseView(0, Power(MOUSE_VIEW_ZOOM_STEP, -WheelDelta / 120));
end;

{ Erase, Move Object and Move Camera }

function TMainForm.EraseToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etErase);
end;

function TMainForm.MoveToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etMove);
end;

function TMainForm.PanToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etPan);
end;

function TMainForm.PickToolOn: Boolean;
begin
  Result := EraseToolOn or MoveToolOn or RotateToolOn or BendToolOn or VariantToolOn;
end;

procedure TMainForm.EraseButtonClick(Sender: TObject);
begin
  ChooseEditTool(etErase);
end;

{ Variants }

function TMainForm.VariantToolOn: Boolean;
begin
  Result := (FPaletteBack <> nil) and not MouseViewOn and (FEditTool = etVariant);
end;

procedure TMainForm.VariantButtonClick(Sender: TObject);
begin
  ChooseEditTool(etVariant);
end;

function TMainForm.VariantNamesOf(const ASpec: TSprite3DPieceSpec): TArray<String>;
begin
  if FVariantNames = nil then
    Exit(nil);
  if not FVariantNames.TryGetValue(LowerCase(ASpec.Key), Result) then
  begin
    Result := ModelVariantNames(ASpec.FileName);
    FVariantNames.Add(LowerCase(ASpec.Key), Result);
  end;
end;

function TMainForm.SourceKey(const ASpec: TSprite3DPieceSpec): String;
begin
  Result := LowerCase(ASpec.Key);
  if ASpec.VariantName <> String.Empty then
    Result := Result + '|' + LowerCase(ASpec.VariantName);
end;

procedure TMainForm.RefreshVariantMarks;
var
  Mark: TSprite3DPlacementBox;
  Piece: TLevelPiece;
  Count, Skipped: Integer;
begin
  if FVariantMarks = nil then
    Exit;
  FVariantMarks.Clear;
  if not VariantToolOn or (FPieces = nil) then
    Exit;
  Count := 0;
  Skipped := 0;
  for var I := 0 to FPieces.Count - 1 do
  begin
    Piece := FPieces[I];
    if Length(VariantNamesOf(Piece.Spec)) = 0 then
      Continue;
    if Count >= MAX_VARIANT_MARKS then
    begin
      Inc(Skipped);
      Continue;
    end;
    // As the pick's outline is drawn, round the piece's own box, turned
    Mark := TSprite3DPlacementBox.Create(nil);
    Mark.Parent := FLevel;
    Mark.Color := VARIANT_MARK_COLOUR;
    Mark.Box := Piece.Spec.Box;
    Mark.Position.Point := Piece.Landed;
    Mark.RotationAngle.Y := Piece.Turn;
    FitOutline(Mark);
    Mark.Visible := True;
    FVariantMarks.Add(Mark);
    Inc(Count);
  end;
  if Skipped > 0 then
    DebugMemo.Lines.Add(Format('Variants: %d pieces with variants outlined; %d more are not, ' +
      'to keep the view quick, but can still be pointed at', [Count, Skipped]));
end;

procedure TMainForm.ShowPieceVariantMenu(const AIndex: Integer; const AAll: Boolean;
  const AScreen: TPointF);
var
  Names: TArray<String>;
  Item: TMenuItem;
  Spec: TSprite3DPieceSpec;
begin
  if (FPieces = nil) or (AIndex < 0) or (AIndex >= FPieces.Count) then
    Exit;
  Spec := FPieces[AIndex].Spec;
  Names := VariantNamesOf(Spec);
  if Length(Names) = 0 then
  begin
    DebugMemo.Lines.Add('Variants: ' + Spec.Name + ' has no material variants');
    Exit;
  end;
  FVariantTarget := AIndex;
  FVariantAll := AAll;
  // A new menu each time, parented to the form, as FMX shows a popup
  // menu's items only then; not items taken out of the old one, which once
  // hung the Library's menu
  FreeAndNil(FPieceVariantMenu);
  FPieceVariantMenu := TPopupMenu.Create(Self);
  FPieceVariantMenu.Parent := Self;
  Item := TMenuItem.Create(Self);
  if AAll then
    Item.Text := 'Every piece of ' + Spec.Name + ':'
  else
    Item.Text := Spec.Name + ':';
  Item.Enabled := False;
  FPieceVariantMenu.AddObject(Item);
  for var I := -1 to High(Names) do
  begin
    Item := TMenuItem.Create(Self);
    if I < 0 then
    begin
      Item.Text := 'Base (as made)';
      Item.TagString := String.Empty;
    end
    else
    begin
      Item.Text := Names[I];
      Item.TagString := Names[I];
    end;
    Item.IsChecked := SameText(Item.TagString, Spec.VariantName);
    Item.OnClick := PieceVariantItemClick;
    FPieceVariantMenu.AddObject(Item);
  end;
  FPieceVariantMenu.Popup(AScreen.X, AScreen.Y);
end;

procedure TMainForm.PieceVariantItemClick(Sender: TObject);
var
  Indices: TArray<Integer>;
  Key: String;
begin
  if (FPieces = nil) or (FVariantTarget < 0) or (FVariantTarget >= FPieces.Count) then
    Exit;
  Indices := [FVariantTarget];
  if FVariantAll then
  begin
    // Every piece of the model, whichever variant it is
    Key := LowerCase(FPieces[FVariantTarget].Spec.Key);
    Indices := nil;
    for var I := 0 to FPieces.Count - 1 do
      if SameText(FPieces[I].Spec.Key, Key) then
        Indices := Indices + [I];
  end;
  SetPiecesVariant(Indices, TMenuItem(Sender).TagString);
end;

procedure TMainForm.SetPiecesVariant(const AIndices: TArray<Integer>;
  const AVariantName: String);
var
  Spec: TSprite3DPieceSpec;
  Source: TPieceSource;
  Piece: TLevelPiece;
  Changed, Falling: Integer;
begin
  if (FPieces = nil) or (Length(AIndices) = 0) or (AIndices[0] < 0) or
    (AIndices[0] >= FPieces.Count) then
    Exit;
  Spec := FPieces[AIndices[0]].Spec;
  Spec.VariantName := AVariantName;
  // The variant's template, loaded the first time it is wanted
  if not PieceSourceFor(Spec, Source) then
    Exit;
  Changed := 0;
  Falling := 0;
  ShowPick(-1);
  EditInstances(True);
  try
    for var I in AIndices do
    begin
      if (I < 0) or (I >= FPieces.Count) then
        Continue;
      Piece := FPieces[I];
      if SameText(Piece.Spec.VariantName, AVariantName) then
        Continue;
      if Piece.Falling then
      begin
        Inc(Falling);
        Continue;
      end;
      // Drawn by the other template from now on, where it is, as it is
      // turned: the old instance freed, as taking a piece out does
      Piece.Instance.Free;
      Piece.Instance := nil;
      Inc(FInstanceSerial);
      Piece.Instance := Source.Template.AddInstanceItem(Format('Piece%d', [FInstanceSerial]));
      Piece.Model := Source.Template;
      Piece.Spec.VariantName := AVariantName;
      FPieces[I] := Piece;
      MovePiece(Piece, Piece.Landed.Y);
      Inc(Changed);
    end;
  finally
    EditInstances(False);
  end;
  if Changed > 0 then
    MarkLevelChanged;
  DebugMemo.Lines.Add(Format('Variants: %d pieces of %s made %s%s', [Changed, Spec.Name,
    IfThen(AVariantName = String.Empty, 'the base', AVariantName),
    IfThen(Falling > 0, Format('; %d still falling were left as they were', [Falling]), '')]));
end;

procedure TMainForm.MoveButtonClick(Sender: TObject);
begin
  ChooseEditTool(etMove);
end;

procedure TMainForm.PanButtonClick(Sender: TObject);
begin
  ChooseEditTool(etPan);
end;

procedure TMainForm.ReleasePiece(const AIndex: Integer; const AGone: TArray<Boolean>);
begin
  // Gorilla's v1.5 documentation: an instance item can be freed directly.
  // The template stays, parked and loaded, for the next piece of it
  FPieces[AIndex].Instance.Free;
end;

// In one pass over the pieces, as a history line can name thousands
function TMainForm.IndicesOf(const AIds: TArray<Integer>): TArray<Integer>;
var
  Wanted: TDictionary<Integer, Boolean>;
  Count: Integer;
begin
  Result := nil;
  if (FPieces = nil) or (Length(AIds) = 0) then
    Exit;
  Wanted := TDictionary<Integer, Boolean>.Create;
  try
    for var Id in AIds do
      Wanted.AddOrSetValue(Id, True);
    SetLength(Result, Length(AIds));
    Count := 0;
    for var I := 0 to FPieces.Count - 1 do
      if Wanted.ContainsKey(FPieces[I].Id) and (Count < Length(Result)) then
      begin
        Result[Count] := I;
        Inc(Count);
      end;
    SetLength(Result, Count);
  finally
    Wanted.Free;
  end;
end;

procedure TMainForm.RemovePieces(const AIndices: TArray<Integer>);
var
  Gone: TArray<Boolean>;
  Region: TRectF;
  Box: TBoundingBox;
  Any: Boolean;
  Kept: Integer;
begin
  if (FPieces = nil) or (Length(AIndices) = 0) then
    Exit;
  // Whatever was going on with the pieces stops: indices are about to move
  FTurnDown := False;
  FMoveDown := False;
  ShowPick(-1);
  SetLength(Gone, FPieces.Count);
  Any := False;
  Region := TRectF.Empty;
  for var I in AIndices do
    if (I >= 0) and (I < FPieces.Count) and not Gone[I] then
    begin
      Gone[I] := True;
      // Where they stood, for what rested on them to fall
      Box := FPieces[I].Box;
      if Any then
        Region := TRectF.Union(Region, TRectF.Create(Box.Left, Box.Near, Box.Right, Box.Far))
      else
        Region := TRectF.Create(Box.Left, Box.Near, Box.Right, Box.Far);
      Any := True;
    end;
  if not Any then
    Exit;
  EditInstances(True);
  try
    for var I := 0 to FPieces.Count - 1 do
      if Gone[I] then
        ReleasePiece(I, Gone);
  finally
    EditInstances(False);
  end;
  // The rest, in order, in one pass: deleting one at a time moves the list
  // down for each, which an area of thousands makes slow
  Kept := 0;
  for var I := 0 to FPieces.Count - 1 do
    if not Gone[I] then
    begin
      if Kept <> I then
        FPieces[Kept] := FPieces[I];
      Inc(Kept);
    end;
  FPieces.Count := Kept;
  PruneHistory;
  SettlePieces(Region);
  MarkLevelChanged;
end;

// Lowest first, so a piece falls onto where those under it have already
// fallen to. A piece rests on the pieces whose tops are at or below its
// base, as placing lands it; one with nothing left at its base falls
procedure TMainForm.SettlePieces(const ARegion: TRectF);
var
  Order: TArray<Integer>;
  Piece: TLevelPiece;
  Box, Other: TBoundingBox;
  Below: TList<TBoundingBox>;
  Region: TRectF;
  Rest, Eps, Started: Double;
  Any: Boolean;
begin
  if (FPieces = nil) or (FPieces.Count = 0) then
    Exit;
  Eps := 0.01 * FSettings.GridSize;
  Region := ARegion;
  SetLength(Order, FPieces.Count);
  for var I := 0 to High(Order) do
    Order[I] := I;
  TArray.Sort<Integer>(Order, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := CompareValue(FPieces[A].Box.Top, FPieces[B].Box.Top);
    end));
  Started := FClock.Elapsed.TotalSeconds;
  Any := False;
  Below := TList<TBoundingBox>.Create;
  try
    for var K in Order do
    begin
      Piece := FPieces[K];
      if Piece.Falling then
        Continue;
      Box := Piece.Box;
      // Only over where something went, or fell from
      if not ((Box.Left < Region.Right - Eps) and (Box.Right > Region.Left + Eps) and
        (Box.Near < Region.Bottom - Eps) and (Box.Far > Region.Top + Eps)) then
        Continue;
      Below.Clear;
      for var J := 0 to FPieces.Count - 1 do
        if J <> K then
        begin
          Other := FPieces[J].Box;
          if Other.Bottom <= Box.Top + Eps then
            Below.Add(Other);
        end;
      Rest := LandingHeight(TRectF.Create(Box.Left, Box.Near, Box.Right, Box.Far),
        Below.ToArray, FSettings.GridSize);
      if Rest < Box.Top - Eps then
      begin
        Piece.FromY := Piece.Landed.Y;
        Piece.Landed.Y := Piece.Landed.Y - (Box.Top - Rest);
        Piece.Falling := True;
        Piece.Started := Started;
        FPieces[K] := Piece;
        Any := True;
        // What rests on it falls too
        Region := TRectF.Union(Region, TRectF.Create(Box.Left, Box.Near, Box.Right,
          Box.Far));
      end;
    end;
  finally
    Below.Free;
  end;
  if Any then
    FFallTimer.Enabled := True;
end;

// Resting on a piece: based at its top, give or take a hundredth of a
// cell, and over it by more than a hundredth of a cell, as landing counts
// it; then those resting on them, and so on
function TMainForm.RidersOf(const AIndex: Integer): TArray<Integer>;
var
  Taken: TArray<Boolean>;
  Queue: TList<Integer>;
  Eps: Single;
  Under, Over: TBoundingBox;
begin
  Result := nil;
  Eps := 0.01 * FSettings.GridSize;
  SetLength(Taken, FPieces.Count);
  Taken[AIndex] := True;
  Queue := TList<Integer>.Create;
  try
    Queue.Add(AIndex);
    var Next := 0;
    while Next < Queue.Count do
    begin
      Under := FPieces[Queue[Next]].Box;
      Inc(Next);
      for var I := 0 to FPieces.Count - 1 do
        if not Taken[I] then
        begin
          Over := FPieces[I].Box;
          if (Abs(Over.Top - Under.Bottom) <= Eps) and
            (Over.Left < Under.Right - Eps) and (Over.Right > Under.Left + Eps) and
            (Over.Near < Under.Far - Eps) and (Over.Far > Under.Near + Eps) then
          begin
            Taken[I] := True;
            Queue.Add(I);
          end;
        end;
    end;
    // All but the piece itself, first
    Queue.Delete(0);
    Result := Queue.ToArray;
  finally
    Queue.Free;
  end;
end;

function TMainForm.StartMove(const AIndex: Integer; const AScreen: TPointF): Boolean;
var
  Over: Boolean;
  Floor, Mid: TPointF;
begin
  Result := (AIndex >= 0) and (FPieces <> nil) and (AIndex < FPieces.Count) and
    LevelFloorAt(AScreen, Over, Floor);
  if not Result then
    Exit;
  Mid := PieceMiddle(FPieces[AIndex]);
  FMoveIndex := AIndex;
  FMoveOffset := Mid - Floor;
  FMoveStart := FPieces[AIndex].Landed;
  FMoveRiders := RidersOf(AIndex);
  FMoveDown := True;
  ShowPick(AIndex);
end;

// Snapped as placing snaps, by its turned box, unless AFree; resting on
// what is under it there, leaving out what rested on it
procedure TMainForm.TrackMove(const AScreen: TPointF; const AFree: Boolean);
var
  Over: Boolean;
  Floor, Spot: TPointF;
  Piece: TLevelPiece;
  Others: TList<TBoundingBox>;
  Grid, Rest: Single;
  Skip: Boolean;
begin
  if not FMoveDown or not LevelFloorAt(AScreen, Over, Floor) then
    Exit;
  Piece := FPieces[FMoveIndex];
  Grid := FSettings.GridSize;
  Spot := SnapPiecePosition(Floor + FMoveOffset, Piece.Turned,
    System.Math.IfThen(AFree, 0, Grid));
  Others := TList<TBoundingBox>.Create;
  try
    for var I := 0 to FPieces.Count - 1 do
    begin
      Skip := I = FMoveIndex;
      for var R in FMoveRiders do
        if R = I then
          Skip := True;
      if not Skip then
        Others.Add(FPieces[I].Box);
    end;
    Rest := LandingHeight(BoxFootprint(Piece.Turned, Point3D(Spot.X, 0, Spot.Y)),
      Others.ToArray, Grid);
  finally
    Others.Free;
  end;
  Piece.Landed := Point3D(Spot.X, Rest - Piece.Turned.Top, Spot.Y);
  Piece.Falling := False;
  FPieces[FMoveIndex] := Piece;
  EditInstances(True);
  try
    MovePiece(Piece, Piece.Landed.Y);
  finally
    EditInstances(False);
  end;
  ShowPick(FMoveIndex);
end;

procedure TMainForm.EndMove;
var
  Piece: TLevelPiece;
  Box: TBoundingBox;
begin
  if not FMoveDown then
    Exit;
  FMoveDown := False;
  Piece := FPieces[FMoveIndex];
  if not ((Piece.Landed - FMoveStart).Length > 1E-5) then
  begin
    UpdateStatus;
    Exit;
  end;
  DebugMemo.Lines.Add(Format('Level: moved %s to (%.3g, %.3g, %.3g)%s', [Piece.Spec.Name,
    Piece.Landed.X, Piece.Landed.Y, Piece.Landed.Z, IfThen(Length(FMoveRiders) > 0,
    Format('; the %d piece(s) on it fall', [Length(FMoveRiders)]), '')]));
  FMoveRiders := nil;
  // What rested on it, where it was
  Box := TBoundingBox.Create(Piece.Turned.TopLeftNear + FMoveStart,
    Piece.Turned.BottomRightFar + FMoveStart);
  SettlePieces(TRectF.Create(Box.Left, Box.Near, Box.Right, Box.Far));
  MarkLevelChanged;
  ShowPick(FMoveIndex);
end;

procedure TMainForm.TrackPan(const AScreen: TPointF);
var
  Over: Boolean;
  Floor: TPointF;
begin
  if not FPanDown or not LevelFloorAt(AScreen, Over, Floor) then
    Exit;
  if FPanGrab.Distance(Floor) > 1E-5 then
    MoveViewCentre(FPanGrab - Floor);
end;

// The camera's orbit centre is in the viewport's coordinates, the level's
// in its own (turned over), so the move is taken across
procedure TMainForm.MoveViewCentre(const ADelta: TPointF);
var
  World: TPoint3D;
begin
  if (GorillaCamera = nil) or (FLevel = nil) then
    Exit;
  FViewCentre := FViewCentre + ADelta;
  World := FLevel.LocalToAbsolute3D(Point3D(ADelta.X, 0, ADelta.Y)) -
    FLevel.LocalToAbsolute3D(TPoint3D.Zero);
  GorillaCamera.OrbitCenter.Point := GorillaCamera.OrbitCenter.Point + World;
  UpdateStatus;
end;

procedure TMainForm.ResetViewCentre;
begin
  if FViewCentre.IsZero then
    Exit;
  FViewCentre := TPointF.Zero;
  FitModel;
end;

{ Level files }

procedure TMainForm.BuildLevelFileItems;

  function Item(const AIndex: Integer; const AText: String; const AShortCut: TShortCut;
    const AClick: TNotifyEvent): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Text := AText;
    Result.ShortCut := AShortCut;
    Result.OnClick := AClick;
    FileMenu.InsertObject(AIndex, Result);
  end;

begin
  FLoadLevelItem := Item(0, 'Load Level...', scCtrl or Ord('O'), LoadLevelItemClick);
  FSaveLevelItem := Item(1, 'Save Level', scCtrl or Ord('S'), SaveLevelItemClick);
  FSaveLevelAsItem := Item(2, 'Save Level As...', scCtrl or scShift or Ord('S'),
    SaveLevelAsItemClick);
  Item(3, '-', 0, nil);
end;

procedure TMainForm.MarkLevelChanged;
begin
  // Pieces placed, moved, taken out or changed: the outlines follow
  RefreshVariantMarks;
  if FLevelDirty then
    Exit;
  FLevelDirty := True;
  UpdateCaption;
end;

function TMainForm.LevelName: String;
begin
  if FLevelFile = String.Empty then
    Result := 'Untitled'
  else
    Result := ExtractFileName(FLevelFile);
end;

procedure TMainForm.UpdateCaption;
begin
  if (FLevelFile = String.Empty) and not FLevelDirty then
    Caption := ProjectionCaption
  else
    Caption := LevelName + IfThen(FLevelDirty, '*', '') + ' - ' + ProjectionCaption;
end;

// As JSON: the models used, once each; the pieces, each by its model, where
// it rests and its turn; the history, by piece; and the view's middle
function TMainForm.SaveLevelTo(const AFileName: String): Boolean;

  function Point(const AValue: TPoint3D): TJSONArray;
  begin
    Result := TJSONArray.Create;
    Result.Add(SimpleRoundTo(AValue.X, -5));
    Result.Add(SimpleRoundTo(AValue.Y, -5));
    Result.Add(SimpleRoundTo(AValue.Z, -5));
  end;

var
  Root, Obj: TJSONObject;
  Models, Pieces, Lines, Ids: TJSONArray;
  ModelOf: TDictionary<String, Integer>;
  PieceOf: TDictionary<Integer, Integer>;
  Piece: TLevelPiece;
  At: Integer;
  Temp, Target: String;
begin
  Result := False;
  Target := OSFriendlyPath(AFileName);
  Root := TJSONObject.Create;
  ModelOf := TDictionary<String, Integer>.Create;
  PieceOf := TDictionary<Integer, Integer>.Create;
  try
    Root.AddPair('format', LEVEL_FILE_FORMAT);
    Root.AddPair('version', TJSONNumber.Create(LEVEL_FILE_VERSION));
    Root.AddPair('gridSize', TJSONNumber.Create(SimpleRoundTo(FSettings.GridSize, -5)));
    Obj := TJSONObject.Create;
    Obj.AddPair('x', TJSONNumber.Create(SimpleRoundTo(FViewCentre.X, -5)));
    Obj.AddPair('z', TJSONNumber.Create(SimpleRoundTo(FViewCentre.Y, -5)));
    Root.AddPair('viewCentre', Obj);
    Models := TJSONArray.Create;
    Root.AddPair('models', Models);
    Pieces := TJSONArray.Create;
    Root.AddPair('pieces', Pieces);
    for var I := 0 to FPieces.Count - 1 do
    begin
      Piece := FPieces[I];
      // A model once for each variant its pieces are
      if not ModelOf.TryGetValue(SourceKey(Piece.Spec), At) then
      begin
        At := Models.Count;
        ModelOf.Add(SourceKey(Piece.Spec), At);
        Obj := TJSONObject.Create;
        Obj.AddPair('name', Piece.Spec.Name);
        Obj.AddPair('file', Piece.Spec.FileName);
        Obj.AddPair('key', Piece.Spec.Key);
        if Piece.Spec.VariantName <> String.Empty then
          Obj.AddPair('variant', Piece.Spec.VariantName);
        Obj.AddPair('boxMin', Point(Piece.Spec.BoxMin));
        Obj.AddPair('boxMax', Point(Piece.Spec.BoxMax));
        Models.AddElement(Obj);
      end;
      PieceOf.Add(Piece.Id, I);
      Obj := TJSONObject.Create;
      Obj.AddPair('model', TJSONNumber.Create(At));
      // Where it rests: one still falling is saved landed
      Obj.AddPair('at', Point(Piece.Landed));
      Obj.AddPair('turn', TJSONNumber.Create(SimpleRoundTo(Piece.Turn, -4)));
      Pieces.AddElement(Obj);
    end;
    Lines := TJSONArray.Create;
    Root.AddPair('history', Lines);
    if FHistory <> nil then
      for var Entry in FHistory do
      begin
        Obj := TJSONObject.Create;
        Obj.AddPair('name', Entry.Name);
        Obj.AddPair('placed', TJSONNumber.Create(Entry.Placed));
        Ids := TJSONArray.Create;
        for var Id in Entry.Ids do
          if PieceOf.TryGetValue(Id, At) then
            Ids.Add(At);
        Obj.AddPair('pieces', Ids);
        Lines.AddElement(Obj);
      end;
    // Written beside it first, so a failed write leaves the old file whole
    Temp := Target + '.tmp';
    try
      TFile.WriteAllText(Temp, JsonToText(Root), TEncoding.UTF8);
      if TFile.Exists(Target) then
        TFile.Delete(Target);
      TFile.Move(Temp, Target);
    except
      on E: Exception do
      begin
        DebugMemo.Lines.Add('Level: can''t save ' + Target + ': ' + E.Message);
        TDialogService.ShowMessage('The level could not be saved: ' + E.Message);
        Exit;
      end;
    end;
  finally
    PieceOf.Free;
    ModelOf.Free;
    Root.Free;
  end;
  FLevelFile := Target;
  FLevelDirty := False;
  FSettings.LevelFolder := ExtractFilePath(Target);
  UpdateCaption;
  DebugMemo.Lines.Add(Format('Level: saved %d pieces to %s', [FPieces.Count, Target]));
  Result := True;
end;

function TMainForm.SaveLevel: Boolean;
begin
  if FLevelFile = String.Empty then
    Result := SaveLevelAs
  else
    Result := SaveLevelTo(FLevelFile);
end;

function TMainForm.SaveLevelAs: Boolean;
var
  Dialog: TSaveDialog;
begin
  Result := False;
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := 'Save Level';
    Dialog.Filter := 'Sprite3DBuilder levels (*' + LEVEL_FILE_EXTENSION + ')|*' +
      LEVEL_FILE_EXTENSION;
    Dialog.DefaultExt := Copy(LEVEL_FILE_EXTENSION, 2, MaxInt);
    Dialog.Options := Dialog.Options + [TOpenOption.ofOverwritePrompt];
    if FLevelFile <> String.Empty then
    begin
      Dialog.InitialDir := ExtractFilePath(FLevelFile);
      Dialog.FileName := ExtractFileName(FLevelFile);
    end
    else if FSettings.LevelFolder <> String.Empty then
      Dialog.InitialDir := FSettings.LevelFolder;
    if not Dialog.Execute then
      Exit;
    Result := SaveLevelTo(ChangeFileExt(Dialog.FileName, LEVEL_FILE_EXTENSION));
  finally
    Dialog.Free;
  end;
end;

function TMainForm.LoadLevelFile(const AFileName: String): Boolean;

  function ReadPoint(const AValue: TJSONValue): TPoint3D;
  begin
    Result := TPoint3D.Zero;
    if (AValue is TJSONArray) and (TJSONArray(AValue).Count >= 3) then
      Result := Point3D(TJSONArray(AValue).Items[0].GetValue<Single>,
        TJSONArray(AValue).Items[1].GetValue<Single>,
        TJSONArray(AValue).Items[2].GetValue<Single>);
  end;

var
  Source: String;
  Value, Found: TJSONValue;
  Root, Obj: TJSONObject;
  Models, Pieces, Lines: TJSONArray;
  Specs: TArray<TSprite3DPieceSpec>;
  Sources: TArray<TPieceSource>;
  Usable: TArray<Boolean>;
  NewIds: TArray<Integer>;
  Model, Missing, Version: Integer;
  At: TPoint3D;
  Piece: TLevelPiece;
  Entry: THistoryEntry;
  Watch: TStopwatch;
  Centre: TPointF;
begin
  Result := False;
  Source := OSFriendlyPath(AFileName);
  Watch := TStopwatch.StartNew;
  try
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(Source, TEncoding.UTF8));
  except
    on E: Exception do
    begin
      DebugMemo.Lines.Add('Level: can''t read ' + Source + ': ' + E.Message);
      TDialogService.ShowMessage('The level could not be read: ' + E.Message);
      Exit;
    end;
  end;
  try
    if not (Value is TJSONObject) or
      (TJSONObject(Value).GetValue<String>('format', '') <> LEVEL_FILE_FORMAT) then
    begin
      DebugMemo.Lines.Add('Level: ' + Source + ' is not a Sprite3DBuilder level');
      TDialogService.ShowMessage(ExtractFileName(Source) + ' is not a Sprite3DBuilder level.');
      Exit;
    end;
    Root := TJSONObject(Value);
    Version := Root.GetValue<Integer>('version', 0);
    if Version > LEVEL_FILE_VERSION then
    begin
      DebugMemo.Lines.Add(Format('Level: %s is from a newer Sprite3DBuilder (layout %d; ' +
        'this one reads up to %d)', [Source, Version, LEVEL_FILE_VERSION]));
      TDialogService.ShowMessage(ExtractFileName(Source) + ' was saved by a newer ' +
        'Sprite3DBuilder; update this one to open it.');
      Exit;
    end;
    if not SameValue(Root.GetValue<Single>('gridSize', FSettings.GridSize),
      FSettings.GridSize, 1E-4) then
      DebugMemo.Lines.Add(Format('Level: %s was built on a grid of %.3g; the grid now is ' +
        '%.3g', [Source, Root.GetValue<Single>('gridSize', 0), FSettings.GridSize]));

    // The level as it is goes
    FPlaceDown := False;
    HidePlacement;
    FreeLevelPieces;
    if FHistory <> nil then
      FHistory.Clear;

    // The models, each loaded once, as placing loads it; one that cannot be
    // is left out, with its pieces
    Found := Root.FindValue('models');
    if Found is TJSONArray then
      Models := TJSONArray(Found)
    else
      Models := nil;
    if Models <> nil then
    begin
      SetLength(Specs, Models.Count);
      SetLength(Sources, Models.Count);
      SetLength(Usable, Models.Count);
      for var I := 0 to Models.Count - 1 do
      begin
        Usable[I] := False;
        if not (Models.Items[I] is TJSONObject) then
          Continue;
        Obj := TJSONObject(Models.Items[I]);
        Specs[I].Name := Obj.GetValue<String>('name', '');
        Specs[I].FileName := Obj.GetValue<String>('file', '');
        Specs[I].Key := Obj.GetValue<String>('key', '');
        // The base if none is given, as in a level from before variants
        Specs[I].VariantName := Obj.GetValue<String>('variant', '');
        Specs[I].BoxMin := ReadPoint(Obj.FindValue('boxMin'));
        Specs[I].BoxMax := ReadPoint(Obj.FindValue('boxMax'));
        Usable[I] := (Specs[I].Key <> String.Empty) and PieceSourceFor(Specs[I], Sources[I]);
      end;
    end;

    // The pieces, where they rested, turned as they were, not falling
    Missing := 0;
    Found := Root.FindValue('pieces');
    if Found is TJSONArray then
      Pieces := TJSONArray(Found)
    else
      Pieces := nil;
    if Pieces <> nil then
    begin
      SetLength(NewIds, Pieces.Count);
      EditInstances(True);
      try
        for var I := 0 to Pieces.Count - 1 do
        begin
          NewIds[I] := -1;
          if not (Pieces.Items[I] is TJSONObject) then
            Continue;
          Obj := TJSONObject(Pieces.Items[I]);
          Model := Obj.GetValue<Integer>('model', -1);
          if (Model < 0) or (Model > High(Specs)) or not Usable[Model] then
          begin
            Inc(Missing);
            Continue;
          end;
          At := ReadPoint(Obj.FindValue('at'));
          if not PlacePiece(Specs[Model], Sources[Model], At, At.Y) then
          begin
            Inc(Missing);
            Continue;
          end;
          Piece := FPieces[FPieces.Count - 1];
          Piece.Turn := Obj.GetValue<Single>('turn', 0);
          Piece.Turned := TurnedBox(Piece.Spec.Box, Piece.Turn);
          Piece.Falling := False;
          FPieces[FPieces.Count - 1] := Piece;
          MovePiece(Piece, At.Y);
          NewIds[I] := Piece.Id;
        end;
      finally
        EditInstances(False);
      end;
    end;

    // The history, by the pieces read
    Found := Root.FindValue('history');
    if (Found is TJSONArray) and (FHistory <> nil) then
    begin
      Lines := TJSONArray(Found);
      for var I := 0 to Lines.Count - 1 do
      begin
        if not (Lines.Items[I] is TJSONObject) then
          Continue;
        Obj := TJSONObject(Lines.Items[I]);
        Entry.Name := Obj.GetValue<String>('name', '');
        Entry.Placed := Obj.GetValue<Integer>('placed', 0);
        Entry.Ids := nil;
        Found := Obj.FindValue('pieces');
        if Found is TJSONArray then
        begin
          SetLength(Entry.Ids, TJSONArray(Found).Count);
          var Count := 0;
          for var J := 0 to TJSONArray(Found).Count - 1 do
          begin
            var Index := TJSONArray(Found).Items[J].GetValue<Integer>;
            if (Index >= 0) and (Index <= High(NewIds)) and (NewIds[Index] >= 0) then
            begin
              Entry.Ids[Count] := NewIds[Index];
              Inc(Count);
            end;
          end;
          SetLength(Entry.Ids, Count);
        end;
        if Entry.Ids <> nil then
          FHistory.Add(Entry);
      end;
    end;
    ShowHistory;

    // The view's middle, where Move Camera left it
    Found := Root.FindValue('viewCentre');
    if Found is TJSONObject then
    begin
      Centre := TPointF.Create(TJSONObject(Found).GetValue<Single>('x', 0),
        TJSONObject(Found).GetValue<Single>('z', 0));
      ResetViewCentre;
      if not Centre.IsZero then
        MoveViewCentre(Centre);
    end;
  finally
    Value.Free;
  end;
  FLevelFile := Source;
  FLevelDirty := False;
  FSettings.LevelFolder := ExtractFilePath(Source);
  UpdateCaption;
  UpdateStatus;
  RefreshVariantMarks;
  DebugMemo.Lines.Add(Format('Level: loaded %d pieces from %s in %d ms%s', [FPieces.Count,
    Source, Watch.ElapsedMilliseconds, IfThen(Missing > 0, Format('; %d left out, as ' +
    'their models could not be loaded (see above)', [Missing]), '')]));
  if Missing > 0 then
    TDialogService.ShowMessage(Format('%d pieces were left out, as their models could not ' +
      'be loaded; the Debug tab says which.', [Missing]));
  Result := True;
end;

procedure TMainForm.AskToKeepLevel(const AThen: TProc);
begin
  if not FLevelDirty then
  begin
    AThen();
    Exit;
  end;
  TDialogService.MessageDialog(Format('Save the changes to %s first?', [LevelName]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel],
    TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      if MainFormGone then
        Exit;
      case AResult of
        mrYes:
          if SaveLevel then
            AThen();
        mrNo:
          AThen();
      end;
    end);
end;

procedure TMainForm.LoadLevelItemClick(Sender: TObject);
begin
  AskToKeepLevel(
    procedure
    var
      Dialog: TOpenDialog;
    begin
      Dialog := TOpenDialog.Create(nil);
      try
        Dialog.Title := 'Load Level';
        Dialog.Filter := 'Sprite3DBuilder levels (*' + LEVEL_FILE_EXTENSION + ')|*' +
          LEVEL_FILE_EXTENSION;
        Dialog.Options := Dialog.Options + [TOpenOption.ofFileMustExist];
        if FSettings.LevelFolder <> String.Empty then
          Dialog.InitialDir := FSettings.LevelFolder;
        if Dialog.Execute then
          LoadLevelFile(Dialog.FileName);
      finally
        Dialog.Free;
      end;
    end);
end;

procedure TMainForm.SaveLevelItemClick(Sender: TObject);
begin
  SaveLevel;
end;

procedure TMainForm.SaveLevelAsItemClick(Sender: TObject);
begin
  SaveLevelAs;
end;

procedure TMainForm.OpenRequestedFile(const AFileName: String);
var
  FileName: String;
begin
  if MainFormGone then
    Exit;
  if not IsLevelFile(AFileName) then
  begin
    DebugMemo.Lines.Add('Asked to open ' + AFileName + ', which is not a level file');
    Exit;
  end;
  FileName := AFileName;
  BringToFront;
  AskToKeepLevel(
    procedure
    begin
      LoadLevelFile(FileName);
    end);
end;

{ The history }

// Over the view, top right at first, on the palette's dark backing: a grip
// with its title, and a line for each click or area placed, oldest first,
// newest at the bottom, with a button that takes those pieces out again
procedure TMainForm.BuildHistory;
var
  Title: TText;
begin
  FHistory := TList<THistoryEntry>.Create;
  FHistoryBack := TRectangle.Create(Self);
  FHistoryBack.Parent := ViewportLayout;
  FHistoryBack.XRadius := 4;
  FHistoryBack.YRadius := 4;
  FHistoryBack.Fill.Kind := TBrushKind.Solid;
  FHistoryBack.Fill.Color := $C0000000;
  FHistoryBack.Stroke.Kind := TBrushKind.None;
  FHistoryBack.HitTest := True;
  FHistoryBack.Width := HISTORY_WIDTH;

  FHistoryGrip := TRectangle.Create(Self);
  FHistoryGrip.Parent := FHistoryBack;
  FHistoryGrip.SetBounds(PALETTE_GAP, PALETTE_GAP, HISTORY_WIDTH - 2 * PALETTE_GAP, 18);
  FHistoryGrip.XRadius := 2;
  FHistoryGrip.YRadius := 2;
  FHistoryGrip.Fill.Kind := TBrushKind.Solid;
  FHistoryGrip.Fill.Color := $40FFFFFF;
  FHistoryGrip.Stroke.Kind := TBrushKind.None;
  FHistoryGrip.Cursor := crSizeAll;
  FHistoryGrip.Hint := 'Drag to move the history';
  FHistoryGrip.ShowHint := True;
  FHistoryGrip.AutoCapture := True;
  FHistoryGrip.OnMouseDown := PaletteGripMouseDown;
  FHistoryGrip.OnMouseMove := PaletteGripMouseMove;
  FHistoryGrip.OnMouseUp := PaletteGripMouseUp;
  Title := TText.Create(Self);
  Title.Parent := FHistoryGrip;
  Title.Align := TAlignLayout.Client;
  Title.Margins.Left := 6;
  Title.Text := 'History';
  Title.TextSettings.FontColor := TAlphaColors.White;
  Title.TextSettings.HorzAlign := TTextAlign.Leading;
  Title.HitTest := False;

  FHistoryBox := TVertScrollBox.Create(Self);
  FHistoryBox.Parent := FHistoryBack;
  FHistoryBox.SetBounds(PALETTE_GAP, 2 * PALETTE_GAP + 18, HISTORY_WIDTH - 2 * PALETTE_GAP,
    HISTORY_LINE);
  FHistoryBox.ShowScrollBars := True;

  // Top right, as PlacePanels puts it the first time; shown as View,
  // History says
  FHistoryBack.Position.Point := TPointF.Create(
    Max(8, ViewportLayout.Width - HISTORY_WIDTH - 8), 32);
  FHistoryBack.Visible := FSettings.HistoryVisible;
  FHistoryBack.BringToFront;
  FHistoryItem := TMenuItem.Create(Self);
  FHistoryItem.Text := 'History';
  FHistoryItem.IsChecked := FSettings.HistoryVisible;
  FHistoryItem.OnClick := HistoryItemClick;
  ViewMenu.AddObject(FHistoryItem);

  // Edit, after File, on the menu bar as it is (on Linux, FMX's own, which
  // FileMenu has already been copied onto), with Undo, Ctrl+Z
  FEditMenu := TMenuItem.Create(Self);
  FEditMenu.Text := 'Edit';
  FileMenu.Parent.InsertObject(FileMenu.Index + 1, FEditMenu);
  FUndoItem := TMenuItem.Create(Self);
  FUndoItem.Text := 'Undo';
  FUndoItem.ShortCut := scCtrl or Ord('Z');
  FUndoItem.OnClick := UndoItemClick;
  FEditMenu.AddObject(FUndoItem);
  var Line := TMenuItem.Create(Self);
  Line.Text := '-';
  FEditMenu.AddObject(Line);
  FResetLevelItem := TMenuItem.Create(Self);
  FResetLevelItem.Text := 'Reset Level...';
  FResetLevelItem.OnClick := ResetLevelItemClick;
  FEditMenu.AddObject(FResetLevelItem);
  ShowHistory;
end;

procedure TMainForm.ResetLevelItemClick(Sender: TObject);
begin
  if (FPieces = nil) or (FPieces.Count = 0) then
  begin
    DebugMemo.Lines.Add('Edit, Reset Level: the level is empty already');
    Exit;
  end;
  // Asked, as Undo cannot bring it back
  TDialogService.MessageDialog(Format('Take all %d pieces out of the level, leaving the ' +
    'empty grid? This cannot be undone.', [FPieces.Count]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    var
      Count: Integer;
    begin
      if (AResult <> mrYes) or MainFormGone then
        Exit;
      Count := FPieces.Count;
      FPlaceDown := False;
      HidePlacement;
      // Every piece and every model loaded for them; the next placed loads
      // its model again
      FreeLevelPieces;
      if FHistory <> nil then
        FHistory.Clear;
      ShowHistory;
      // A new, empty level, with no file yet
      FLevelFile := String.Empty;
      FLevelDirty := False;
      UpdateCaption;
      UpdateStatus;
      DebugMemo.Lines.Add(Format('Edit, Reset Level: took out %d pieces; the level is empty',
        [Count]));
    end);
end;

procedure TMainForm.UndoItemClick(Sender: TObject);
var
  Entry: THistoryEntry;
  Indices: TArray<Integer>;
begin
  if (FHistory = nil) or (FHistory.Count = 0) then
  begin
    DebugMemo.Lines.Add('Edit, Undo: nothing placed to undo');
    Exit;
  end;
  Entry := FHistory[FHistory.Count - 1];
  Indices := IndicesOf(Entry.Ids);
  DebugMemo.Lines.Add(Format('Edit, Undo: took out %d x %s', [Length(Indices), Entry.Name]));
  // Its line goes with its pieces (PruneHistory)
  RemovePieces(Indices);
end;

procedure TMainForm.AddHistory(const AName: String; const AIds: TArray<Integer>);
var
  Entry: THistoryEntry;
begin
  if (FHistory = nil) or (Length(AIds) = 0) then
    Exit;
  Entry.Name := AName;
  Entry.Placed := Length(AIds);
  Entry.Ids := AIds;
  // Newest at the bottom; the oldest go first
  FHistory.Add(Entry);
  while FHistory.Count > HISTORY_MAX do
    FHistory.Delete(0);
  ShowHistory;
end;

procedure TMainForm.PruneHistory;
var
  Entry: THistoryEntry;
  Kept: TArray<Integer>;
  Live: TDictionary<Integer, Boolean>;
begin
  if (FHistory = nil) or (FPieces = nil) then
    Exit;
  Live := TDictionary<Integer, Boolean>.Create;
  try
    for var I := 0 to FPieces.Count - 1 do
      Live.AddOrSetValue(FPieces[I].Id, True);
    for var I := FHistory.Count - 1 downto 0 do
    begin
      Entry := FHistory[I];
      SetLength(Kept, Length(Entry.Ids));
      var Count := 0;
      for var Id in Entry.Ids do
        if Live.ContainsKey(Id) then
        begin
          Kept[Count] := Id;
          Inc(Count);
        end;
      SetLength(Kept, Count);
      if Kept = nil then
        FHistory.Delete(I)
      else if Length(Kept) <> Length(Entry.Ids) then
      begin
        Entry.Ids := Kept;
        FHistory[I] := Entry;
      end;
    end;
  finally
    Live.Free;
  end;
  ShowHistory;
end;

procedure TMainForm.ShowHistory;
var
  Line, Remove: TRectangle;
  Text: TText;
  Entry: THistoryEntry;
  Lines, Room: Single;
begin
  if (FHistoryBack = nil) or (FHistory = nil) then
    Exit;
  FHistoryBox.BeginUpdate;
  try
    FHistoryBox.Content.DeleteChildren;
    if FHistory.Count = 0 then
    begin
      Text := TText.Create(FHistoryBox);
      Text.Parent := FHistoryBox;
      Text.SetBounds(0, 0, FHistoryBox.Width - 4, HISTORY_LINE);
      Text.Text := 'Nothing placed yet';
      Text.TextSettings.FontColor := $A0FFFFFF;
      Text.TextSettings.HorzAlign := TTextAlign.Leading;
      Text.Margins.Left := 6;
      Text.HitTest := False;
    end;
    for var I := 0 to FHistory.Count - 1 do
    begin
      Entry := FHistory[I];
      Line := TRectangle.Create(FHistoryBox);
      Line.Parent := FHistoryBox;
      Line.SetBounds(0, I * HISTORY_LINE, FHistoryBox.Width - 14, HISTORY_LINE - 2);
      Line.Fill.Kind := TBrushKind.Solid;
      if Odd(I) then
        Line.Fill.Color := $18FFFFFF
      else
        Line.Fill.Color := TAlphaColors.Null;
      Line.Stroke.Kind := TBrushKind.None;
      Line.HitTest := False;
      Text := TText.Create(Line);
      Text.Parent := Line;
      Text.SetBounds(6, 0, Line.Width - 32, Line.Height);
      if Length(Entry.Ids) = Entry.Placed then
        Text.Text := Format('%d x %s', [Entry.Placed, Entry.Name])
      else
        Text.Text := Format('%d of %d x %s', [Length(Entry.Ids), Entry.Placed, Entry.Name]);
      Text.TextSettings.FontColor := TAlphaColors.White;
      Text.TextSettings.HorzAlign := TTextAlign.Leading;
      Text.TextSettings.Trimming := TTextTrimming.Character;
      Text.TextSettings.WordWrap := False;
      Text.HitTest := False;
      // The remove button, a cross, drawn as the palette's icons are
      Remove := TRectangle.Create(Line);
      Remove.Parent := Line;
      Remove.SetBounds(Line.Width - 22, 2, 18, 18);
      Remove.XRadius := 3;
      Remove.YRadius := 3;
      Remove.Fill.Kind := TBrushKind.Solid;
      Remove.Fill.Color := $30FFFFFF;
      Remove.Stroke.Kind := TBrushKind.None;
      Remove.Cursor := crHandPoint;
      Remove.Hint := 'Take these pieces out of the level';
      Remove.ShowHint := True;
      Remove.Tag := I;
      Remove.OnClick := HistoryRemoveClick;
      Line.HitTest := True;   // so its button gets the click
      Text := TText.Create(Remove);
      Text.Parent := Remove;
      Text.Align := TAlignLayout.Client;
      Text.Text := 'X';
      Text.TextSettings.FontColor := ERASE_BOX_COLOUR;
      Text.TextSettings.Font.Style := [TFontStyle.fsBold];
      Text.HitTest := False;
    end;
  finally
    FHistoryBox.EndUpdate;
  end;
  // Undo has something to undo while there is a line
  if FUndoItem <> nil then
  begin
    FUndoItem.Enabled := FHistory.Count > 0;
    if FHistory.Count > 0 then
      FUndoItem.Text := Format('Undo %d x %s', [Length(FHistory[FHistory.Count - 1].Ids),
        FHistory[FHistory.Count - 1].Name])
    else
      FUndoItem.Text := 'Undo';
  end;
  // As tall as its lines, as far as the view below it allows
  Lines := Max(1, FHistory.Count) * HISTORY_LINE;
  Room := Max(HISTORY_LINE, ViewportLayout.Height - FHistoryBack.Position.Y -
    FHistoryBox.Position.Y - PALETTE_GAP - 8);
  FHistoryBox.Height := Min(Lines, Room);
  FHistoryBack.Height := FHistoryBox.Position.Y + FHistoryBox.Height + PALETTE_GAP;
  KeepPanelInView(FHistoryBack);
  // The newest, at the bottom, in sight, once the box has laid its lines out
  TThread.ForceQueue(nil,
    procedure
    begin
      if not MainFormGone and (FHistoryBox <> nil) then
        FHistoryBox.ViewportPosition := TPointF.Create(0,
          Max(0, FHistory.Count * HISTORY_LINE - FHistoryBox.Height));
    end);
end;

procedure TMainForm.HistoryRemoveClick(Sender: TObject);
var
  Entry: THistoryEntry;
  Indices: TArray<Integer>;
  At: Integer;
begin
  At := TControl(Sender).Tag;
  if (FHistory = nil) or (At < 0) or (At >= FHistory.Count) then
    Exit;
  Entry := FHistory[At];
  Indices := IndicesOf(Entry.Ids);
  DebugMemo.Lines.Add(Format('Level: took out %d x %s, from the history',
    [Length(Indices), Entry.Name]));
  // The click came from a button the new list will free: after this event
  TThread.ForceQueue(nil,
    procedure
    begin
      if not MainFormGone then
        RemovePieces(Indices);
    end);
end;

{ The palette }

// A floating toolbar over the view, on a dark, mostly opaque backing, as the
// frame rate readout is, so it reads over the level whatever the theme:
// a grip to move it, and the Place Model, Erase, Move Object, Rotate,
// Bend, Move Camera and Mouse View tools. Made in code, as the readouts are, so the form
// designer's .fmx is left alone.
procedure TMainForm.BuildPalette;

  function MakeButton(const AIcon, AHint: String; const AColumn: Integer; const AY: Single;
    const AClick: TNotifyEvent): TRectangle;
  var
    // Qualified: System.IOUtils, used here, has a TPath of its own, for file
    // paths, which would be taken otherwise
    Icon: FMX.Objects.TPath;
  begin
    Result := TRectangle.Create(Self);
    Result.Parent := FPaletteBack;
    Result.SetBounds(PALETTE_GAP + AColumn * (PALETTE_BUTTON + PALETTE_GAP), AY,
      PALETTE_BUTTON, PALETTE_BUTTON);
    Result.XRadius := 4;
    Result.YRadius := 4;
    Result.Fill.Kind := TBrushKind.Solid;
    Result.Fill.Color := TAlphaColors.Null;
    Result.Stroke.Kind := TBrushKind.None;
    Result.Stroke.Color := PLACE_BOX_COLOUR;
    Result.Stroke.Thickness := 1.5;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.Cursor := crHandPoint;
    Result.OnClick := AClick;
    // Drawn as lines, in white, so it needs no image and suits any theme
    Icon := FMX.Objects.TPath.Create(Self);
    Icon.Parent := Result;
    Icon.Align := TAlignLayout.Client;
    Icon.Margins.Rect := TRectF.Create(5, 5, 5, 5);
    Icon.Data.Data := AIcon;
    Icon.WrapMode := TPathWrapMode.Fit;
    Icon.Fill.Kind := TBrushKind.None;
    Icon.Stroke.Kind := TBrushKind.Solid;
    Icon.Stroke.Color := TAlphaColors.White;
    Icon.Stroke.Thickness := 1.6;
    Icon.HitTest := False;
  end;

var
  Y: Single;
begin
  // Upright, two columns: the grip across the top; the camera's tools, Move
  // Camera and Mouse View; then the tools that change the level, in pairs.
  // A place with no tool is left empty
  FPaletteBack := TRectangle.Create(Self);
  FPaletteBack.Parent := ViewportLayout;
  FPaletteBack.Align := TAlignLayout.None;
  FPaletteBack.XRadius := 4;
  FPaletteBack.YRadius := 4;
  FPaletteBack.Fill.Kind := TBrushKind.Solid;
  FPaletteBack.Fill.Color := $C0000000;
  FPaletteBack.Stroke.Kind := TBrushKind.None;
  // It takes the clicks it gets, so none reaches the view under it
  FPaletteBack.HitTest := True;
  FPaletteBack.Width := 2 * PALETTE_BUTTON + 3 * PALETTE_GAP;

  FPaletteGrip := TRectangle.Create(Self);
  FPaletteGrip.Parent := FPaletteBack;
  FPaletteGrip.SetBounds(PALETTE_GAP, PALETTE_GAP, 2 * PALETTE_BUTTON + PALETTE_GAP,
    PALETTE_GRIP);
  FPaletteGrip.XRadius := 2;
  FPaletteGrip.YRadius := 2;
  FPaletteGrip.Fill.Kind := TBrushKind.Solid;
  FPaletteGrip.Fill.Color := $40FFFFFF;
  FPaletteGrip.Stroke.Kind := TBrushKind.None;
  FPaletteGrip.Cursor := crSizeAll;
  FPaletteGrip.Hint := 'Drag to move the palette';
  FPaletteGrip.ShowHint := True;
  FPaletteGrip.AutoCapture := True;
  FPaletteGrip.OnMouseDown := PaletteGripMouseDown;
  FPaletteGrip.OnMouseMove := PaletteGripMouseMove;
  FPaletteGrip.OnMouseUp := PaletteGripMouseUp;

  Y := 2 * PALETTE_GAP + PALETTE_GRIP;
  FPanButton := MakeButton(MOVE_CAMERA_ICON, 'Move Camera', 0, Y, PanButtonClick);
  FCameraButton := MakeButton(MOUSE_VIEW_ICON, 'Mouse View: turn the view', 1, Y,
    CameraButtonClick);
  // A little more room between the camera's tools and the level's
  Y := Y + PALETTE_BUTTON + 3 * PALETTE_GAP;
  FPlaceButton := MakeButton(PLACE_MODEL_ICON, 'Place Model', 0, Y, PlaceButtonClick);
  FEraseButton := MakeButton(ERASE_ICON, 'Erase', 1, Y, EraseButtonClick);
  Y := Y + PALETTE_BUTTON + PALETTE_GAP;
  FMoveButton := MakeButton(MOVE_OBJECT_ICON, 'Move Object', 0, Y, MoveButtonClick);
  FRotateButton := MakeButton(ROTATE_ICON, 'Rotate (double-click: the step)', 1, Y,
    RotateButtonClick);
  FRotateButton.OnDblClick := TurnButtonDblClick;
  Y := Y + PALETTE_BUTTON + PALETTE_GAP;
  FBendButton := MakeButton(BEND_ICON, 'Bend (double-click: the step)', 0, Y,
    BendButtonClick);
  FBendButton.OnDblClick := TurnButtonDblClick;
  // Its pair: a piece's material variant
  FVariantButton := MakeButton(VARIANT_ICON, 'Variants: pieces with material variants ' +
    '(Shift-click: every piece of the model)', 1, Y, VariantButtonClick);
  Y := Y + PALETTE_BUTTON + PALETTE_GAP;
  FPaletteBack.Height := Y;

  // File, Rotation Snap..., under Settings..., with the palette as it is for
  // its tools
  FRotationSnapItem := TMenuItem.Create(Self);
  FRotationSnapItem.Text := 'Rotation Snap...';
  FRotationSnapItem.OnClick := RotationSnapItemClick;
  FileMenu.InsertObject(SettingsMenuItem.Index + 1, FRotationSnapItem);

  // Under the frame rate, top left, until PlacePanels puts it where it was
  FPaletteBack.Position.Point := TPointF.Create(8, 32);
  FPaletteBack.BringToFront;
  UpdatePalette;
  KeepPaletteInView;
end;

procedure TMainForm.PlacePanels;
begin
  if MainFormGone or (FPaletteBack = nil) then
    Exit;
  if (FSettings.PaletteLeft >= 0) and (FSettings.PaletteTop >= 0) then
    FPaletteBack.Position.Point := TPointF.Create(FSettings.PaletteLeft,
      FSettings.PaletteTop);
  KeepPanelInView(FPaletteBack);
  if FHistoryBack <> nil then
  begin
    if (FSettings.HistoryLeft >= 0) and (FSettings.HistoryTop >= 0) then
      FHistoryBack.Position.Point := TPointF.Create(FSettings.HistoryLeft,
        FSettings.HistoryTop)
    else
      // The first time: top right
      FHistoryBack.Position.Point := TPointF.Create(
        ViewportLayout.Width - FHistoryBack.Width - 8, 32);
    ShowHistory;
  end;
  FViewSize := TSizeF.Create(ViewportLayout.Width, ViewportLayout.Height);
  FPanelsPlaced := True;
end;

procedure TMainForm.KeepPlaces;
var
  L, T, W, H: Integer;
  Maxed: Boolean;
begin
  L := FSettings.MainLeft;
  T := FSettings.MainTop;
  W := FSettings.MainWidth;
  H := FSettings.MainHeight;
  ReadFormPlace(Self, L, T, W, H, Maxed);
  FSettings.MainLeft := L;
  FSettings.MainTop := T;
  FSettings.MainWidth := W;
  FSettings.MainHeight := H;
  FSettings.MainMaximized := Maxed;
  if FAssetsForm <> nil then
  begin
    L := FSettings.LibraryLeft;
    T := FSettings.LibraryTop;
    W := FSettings.LibraryWidth;
    H := FSettings.LibraryHeight;
    ReadFormPlace(FAssetsForm, L, T, W, H, Maxed);
    FSettings.LibraryLeft := L;
    FSettings.LibraryTop := T;
    FSettings.LibraryWidth := W;
    FSettings.LibraryHeight := H;
    FSettings.LibraryMaximized := Maxed;
  end;
  if FPanelsPlaced then
  begin
    FSettings.PaletteLeft := FPaletteBack.Position.X;
    FSettings.PaletteTop := FPaletteBack.Position.Y;
    if FHistoryBack <> nil then
    begin
      FSettings.HistoryLeft := FHistoryBack.Position.X;
      FSettings.HistoryTop := FHistoryBack.Position.Y;
    end;
  end;
  if FHistoryItem <> nil then
    FSettings.HistoryVisible := FHistoryItem.IsChecked;
end;

procedure TMainForm.HistoryItemClick(Sender: TObject);
begin
  FHistoryItem.IsChecked := not FHistoryItem.IsChecked;
  FHistoryBack.Visible := FHistoryItem.IsChecked;
  if FHistoryBack.Visible then
  begin
    FHistoryBack.BringToFront;
    ShowHistory;
  end;
end;

procedure TMainForm.UpdatePalette;

  procedure Mark(const AButton: TRectangle; const AOn: Boolean);
  begin
    if AOn then
    begin
      AButton.Fill.Color := $40FFFFFF;
      AButton.Stroke.Kind := TBrushKind.Solid;
    end
    else
    begin
      AButton.Fill.Color := TAlphaColors.Null;
      AButton.Stroke.Kind := TBrushKind.None;
    end;
  end;

begin
  if FPaletteBack = nil then
    Exit;
  Mark(FPlaceButton, PlaceToolOn);
  Mark(FEraseButton, EraseToolOn);
  Mark(FMoveButton, MoveToolOn);
  Mark(FRotateButton, RotateToolOn);
  Mark(FBendButton, BendToolOn);
  Mark(FVariantButton, VariantToolOn);
  Mark(FPanButton, PanToolOn);
  Mark(FCameraButton, MouseViewOn);
  UpdateStatus;
  RefreshVariantMarks;
end;

// Along the bottom of the form, under the tabs, on both of them
procedure TMainForm.BuildStatusBar;
begin
  FStatusBar := TStatusBar.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.Align := TAlignLayout.Bottom;
  FStatusBar.ShowSizeGrip := True;
  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := FStatusBar;
  FStatusLabel.Align := TAlignLayout.Client;
  FStatusLabel.Margins.Left := 8;
  FStatusLabel.Margins.Right := 8;
  FStatusLabel.TextSettings.WordWrap := False;
  FStatusLabel.TextSettings.Trimming := TTextTrimming.Character;
  FStatusLabel.HitTest := False;
  UpdateStatus;
end;

procedure TMainForm.UpdateStatus;
const
  VIEW_KEYS = 'Wheel: zoom.  Right-click: normal view.';
var
  Text: String;
  Size: TPoint3D;
begin
  if FStatusLabel = nil then
    Exit;
  if MouseViewOn then
    Text := 'Mouse View.  Drag: turn the view.  ' + VIEW_KEYS
  else if RotateToolOn or BendToolOn then
    Text := TurnStatus
  else if VariantToolOn then
  begin
    if (FPicked >= 0) and (FPieces <> nil) and (FPicked < FPieces.Count) then
      Text := Format('Variants: %s, %s.  Click: choose its variant.  Shift-click: every ' +
        'piece of it.  ', [FPieces[FPicked].Spec.Name,
        IfThen(FPieces[FPicked].Spec.VariantName = String.Empty, 'the base',
        FPieces[FPicked].Spec.VariantName)]) + VIEW_KEYS
    else
      Text := 'Variants: the pieces outlined have material variants; point at one.  ' +
        VIEW_KEYS;
  end
  else if EraseToolOn then
  begin
    if (FPicked >= 0) and (FPieces <> nil) and (FPicked < FPieces.Count) then
      Text := 'Erase: ' + FPieces[FPicked].Spec.Name + '.  Click: take it out.  ' + VIEW_KEYS
    else
      Text := 'Erase: point at a piece.  Click: take it out; what rested on it falls.  ' +
        VIEW_KEYS;
  end
  else if MoveToolOn then
  begin
    if FMoveDown then
      Text := 'Move Object: ' + FPieces[FMoveIndex].Spec.Name + '.  Let go: leave it there.  ' +
        'Shift: off the grid.'
    else if (FPicked >= 0) and (FPieces <> nil) and (FPicked < FPieces.Count) then
      Text := 'Move Object: ' + FPieces[FPicked].Spec.Name + '.  Drag: move it, on the grid ' +
        '(hold Shift: freely).  ' + VIEW_KEYS
    else
      Text := 'Move Object: point at a piece, then drag it.  ' + VIEW_KEYS;
  end
  else if PanToolOn then
    Text := Format('Move Camera.  Drag: slide the view across the level (its middle at ' +
      '%.3g, %.3g).  ', [FViewCentre.X, FViewCentre.Y]) + VIEW_KEYS
  else if not FHasBrush then
    Text := 'Place Model: choose a model in the Library (File, Library...) to place it.  ' +
      VIEW_KEYS
  else if FPlaceDown and (FPlaceCountX * FPlaceCountZ = 1) then
    Text := Format('Place Model: %s.  Let go: place it.  Drag on: fill an area with it.',
      [BrushName])
  else if FPlaceDown then
    Text := Format('Place Model: %s, an area of %d x %d (%d pieces).  Let go: place them.',
      [BrushName, FPlaceCountX, FPlaceCountZ, FPlaceCountX * FPlaceCountZ])
  else
  begin
    Size := FBrush.BoxMax - FBrush.BoxMin;
    Text := Format('Place Model: %s (%.3g x %.3g x %.3g).  Click: place it.  Drag: fill an ' +
      'area with it.  ', [BrushName, Size.X, Size.Y, Size.Z]) + VIEW_KEYS;
  end;
  FStatusLabel.Text := Text;
  FStatusLabel.Hint := Text;
end;

procedure TMainForm.KeepPaletteInView;
begin
  KeepPanelInView(FPaletteBack);
  // Its height follows the room below it
  if FHistoryBack <> nil then
    ShowHistory;
end;

procedure TMainForm.KeepPanelInView(const APanel: TControl);
var
  NewLeft, NewTop: Single;
begin
  if APanel = nil then
    Exit;
  NewLeft := EnsureRange(APanel.Position.X, 0, Max(0, ViewportLayout.Width - APanel.Width));
  NewTop := EnsureRange(APanel.Position.Y, 0, Max(0, ViewportLayout.Height - APanel.Height));
  APanel.Position.Point := TPointF.Create(NewLeft, NewTop);
end;

procedure TMainForm.PlaceButtonClick(Sender: TObject);
begin
  ChooseEditTool(etPlace);
end;

procedure TMainForm.CameraButtonClick(Sender: TObject);
begin
  ChooseTool(True);
end;

procedure TMainForm.PaletteGripMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button <> TMouseButton.mbLeft then
    Exit;
  // The palette's grip or the history's: either moves its own panel
  FMovingPanel := TControl(TControl(Sender).ParentControl);
  FPaletteMoving := True;
  FPaletteGrab := FMovingPanel.AbsoluteToLocal(TControl(Sender).LocalToAbsolute(
    TPointF.Create(X, Y)));
end;

procedure TMainForm.PaletteGripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  At: TPointF;
begin
  if not FPaletteMoving then
    Exit;
  if not (ssLeft in Shift) then
  begin
    FPaletteMoving := False;
    Exit;
  end;
  // Where the pointer is, in the view's layout, less where the grip was
  // taken
  At := ViewportLayout.AbsoluteToLocal(TControl(Sender).LocalToAbsolute(
    TPointF.Create(X, Y)));
  FMovingPanel.Position.Point := At - FPaletteGrab;
  KeepPanelInView(FMovingPanel);
end;

procedure TMainForm.PaletteGripMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    FPaletteMoving := False;
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
{$ENDIF}

end.
