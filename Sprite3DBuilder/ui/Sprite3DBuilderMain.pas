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
//** |   |-- LicencesMenuItem "Licences..."  the third-party licences, from the program's resources
//** |   |-- FileSeparatorItem "-"
//** |   `-- ExitMenuItem "Exit"             closes the application
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
    |   |-- LicencesMenuItem "Licences..."  the third-party licences, from the program's resources
    |   |-- FileSeparatorItem "-"
    |   `-- ExitMenuItem "Exit"             closes the application
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
  System.Generics.Collections, Sprite3DBuilderAssetsForm, Sprite3DAssetCache
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  , FMX.MultiView   // FMX.ListBox, also needed there, is listed above
  {$ENDIF}
  ;

type
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
    //** @abstract(Places the Mouse View readout again when AspectLayout changes size; the
    //** viewport fills AspectLayout, and refits itself.)
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
    //** @abstract(The mouse view readout, top right over the view, shown while
    //** FMouseViewItem is ticked.) A dark FMouseViewBack, as the frame rate readout has at
    //** the top left, holding the centred title "Mouseview On", FMouseViewLabel, and under it
    //** FMouseViewDetails, shown while the view is turned or zoomed: the azimuth and the
    //** distance (or the orthographic size, named in FMouseDistanceName) as they differ from
    //** the normal view, in FMouseAzimuthValue and FMouseDistanceValue, and "Right Click to
    //** Reset". See UpdateMouseViewReadout.
    FMouseViewBack: TRectangle;
    FMouseViewLabel: TLabel;
    FMouseViewDetails: TLayout;
    FMouseAzimuthValue: TLabel;
    FMouseDistanceName: TLabel;
    FMouseDistanceValue: TLabel;
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
    // timer that refreshes it, and the Mouse View readout
    FFpsLabel: TLabel;
    FFpsBack: TRectangle;   // dark, so the label reads on any background
    FReadoutTimer: TTimer;
    // The displays, kept so the one the form is on can be checked cheaply
    // as the readouts refresh; read again whenever the form moves to
    // another, so the frame rate follows that display's refresh rate
    FDisplays: TPeardoxDisplays;
    FDisplayIndex: Integer;
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
    //** @abstract(Adds View, Camera, Mouse View and the "Mouseview On" readout,
    //** and hooks the mouse on the view.) Desktop only; called by BuildLockCameraItem, just
    //** before Lock Camera is added.
    procedure BuildMouseViewItem;
    //** @abstract(Puts the "Mouseview On" readout at the top right of the view.) Called as
    //** the view is resized.
    procedure PlaceMouseViewReadout;
    //** @abstract(Shows the mouse view's turn and zoom in the readout.)
    //** The azimuth, as the dials show it, as + or - its normal value, and the distance, or in
    //** orthographic projection the orthographic size, as a factor on its normal value, as
    //** Variable's Distance slider gives its own, each to 3 decimal places, with "Right Click
    //** to Reset" under them; shown only while either differs from normal, the readout
    //** shrinking back to its title when the turn is 0 and the factor 1.
    procedure UpdateMouseViewReadout;
    //** @abstract(Ticks or unticks Mouse View, and keeps the tick in
    //** settings.json.) Unticking it puts the normal view back. The view takes the mouse
    //** only while it is ticked.
    procedure MouseViewItemClick(Sender: TObject);
    //** @abstract(Ticks or unticks Mouse View, without saving it.)
    //** Unticked, the normal view is put back; the view takes the mouse and shows the
    //** readout only while it is ticked.
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
    //** @abstract(Refreshes the frame rate and Mouse View readouts, and checks the display.)
    //**
    //** @param(Sender FReadoutTimer.)
    procedure ReadoutTimerTimer(Sender: TObject);
    //** @abstract(The volume the view is fitted to: the middle of the level's floor,
    //** LEVEL_FRAME_CELLS cells across and LEVEL_FRAME_CELLS_HIGH high, swept about its
    //** centre.)
    //**
    //** @returns(The volume.)
    function ViewVolume: TSweptVolume;
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
  FMX.DialogService, Sprite3DBuilderLicencesForm;

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
  //** @abstract(Mouse View: the readout's width, its title's height, the height
  //** of each line under the title, and the width of the values' column, in pixels.)
  MOUSE_VIEW_READOUT_WIDTH = 160;
  MOUSE_VIEW_TITLE_HEIGHT = 20;
  MOUSE_VIEW_ROW_HEIGHT = 17;
  MOUSE_VIEW_VALUE_WIDTH = 72;
  //** @abstract(Mouse View: a difference from the normal view smaller than this
  //** shows as 0.000, and counts as none.)
  MOUSE_VIEW_SHOWN_ZERO = 0.0005;

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
    Caption := ProjectionCaption;
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
  Caption := ProjectionCaption;
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
  Caption := ProjectionCaption;
  DebugMemo.Lines.Add(Format('Empty level: grid of %s units', [FormatFloat('0.###',
    FSettings.GridSize)]));
  // Once the main window is up: the palette, if there is one, on the last
  // asset folder
  TThread.ForceQueue(nil, OpenLastLibrary);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Nothing is ever being written that a close could leave half done: the
  // window always closes. Kept as the place to ask before throwing away an
  // unsaved level, once there are levels.
  CanClose := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MainFormGone := True;   // queued work arriving from here on does nothing
  // The projection let go of and freed while the viewport, its hook's owner,
  // and the camera are whole: freed later, with the form's other components,
  // it could meet them half destroyed (ProjectionTest's exit fault in
  // SRDelphiFMX was of that kind)
  if OrbitCamera <> nil then
    OrbitCamera.Projection := nil;
  FreeAndNil(FProjection);
  if Assigned(FReadoutTimer) then
    FReadoutTimer.Enabled := False;
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
  try
    FSettings.Save;
  except
    // Nowhere to report it; see above
  end;
end;

procedure TMainForm.AspectLayoutResize(Sender: TObject);
begin
  // AspectLayout fills ViewportLayout, so this is its resize too; the
  // viewport fills AspectLayout, and its own OnResize refits the view
  PlaceMouseViewReadout;
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
    FAssetsForm.OnLog :=
      procedure(const AText: String)
      begin
        if not MainFormGone then
          DebugMemo.Lines.Add(AText);
      end;
    FAssetsForm.MigrationFolder := OSFriendlyPath(FSettings.AssetFolder);
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
  Caption := ProjectionCaption;
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
  Caption := ProjectionCaption;
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
  Box := TBoundingBox.Create(Point3D(-Half, 0, -Half),
    Point3D(Half, LEVEL_FRAME_CELLS_HIGH * FSettings.GridSize, Half));
  Result := CalcSweptVolume(Box, TPoint3D.Zero, saY);
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

// The frames per second Gorilla's viewport reports, and the Mouse View readout
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
  UpdateMouseViewReadout;
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

  //** @abstract(A white label in the readout, letting clicks through.)
  //** @param(AParent The control it goes in.)
  //** @param(AText Its text.)
  //** @param(AAlign Where in its width the text sits.)
  //** @returns(The label, owned by the form.)
  function MouseViewText(const AParent: TFmxObject; const AText: String;
    const AAlign: TTextAlign): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.StyledSettings := Result.StyledSettings - [TStyledSetting.FontColor];
    Result.TextSettings.FontColor := TAlphaColors.White;
    Result.TextSettings.HorzAlign := AAlign;
    Result.TextSettings.WordWrap := False;
    Result.HitTest := False;
    Result.Text := AText;
  end;

  //** @abstract(One row of the readout's details: a name at the left and a value at the
  //** right.)
  //** @param(ARow The row, from 0 at the top, which sets its place.)
  //** @param(AName The name.)
  //** @param(AValue Set to the value's label, which starts empty.)
  //** @returns(The name's label.)
  function MouseViewRow(const ARow: Integer; const AName: String;
    out AValue: TLabel): TLabel;
  var
    Row: TLayout;
  begin
    Row := TLayout.Create(Self);
    Row.Parent := FMouseViewDetails;
    // Top-aligned controls are laid out in the order of their positions
    Row.Position.Y := ARow * MOUSE_VIEW_ROW_HEIGHT;
    Row.Align := TAlignLayout.Top;
    Row.Height := MOUSE_VIEW_ROW_HEIGHT;
    Row.HitTest := False;
    AValue := MouseViewText(Row, String.Empty, TTextAlign.Trailing);
    AValue.Align := TAlignLayout.Right;
    AValue.Width := MOUSE_VIEW_VALUE_WIDTH;
    Result := MouseViewText(Row, AName, TTextAlign.Leading);
    Result.Align := TAlignLayout.Client;
  end;

begin
  FMouseViewItem := TMenuItem.Create(Self);
  FMouseViewItem.Text := 'Mouse View';
  FMouseViewItem.IsChecked := False;
  FMouseViewItem.OnClick := MouseViewItemClick;
  CameraMenu.AddObject(FMouseViewItem);

  // As the frame rate readout, but top right, and only while ticked
  FMouseViewBack := TRectangle.Create(Self);
  FMouseViewBack.Parent := ViewportLayout;
  FMouseViewBack.Align := TAlignLayout.None;
  FMouseViewBack.Width := MOUSE_VIEW_READOUT_WIDTH;
  FMouseViewBack.Height := MOUSE_VIEW_TITLE_HEIGHT;
  FMouseViewBack.XRadius := 4;
  FMouseViewBack.YRadius := 4;
  FMouseViewBack.Fill.Kind := TBrushKind.Solid;
  FMouseViewBack.Fill.Color := $C0000000;
  FMouseViewBack.Stroke.Kind := TBrushKind.None;
  FMouseViewBack.HitTest := False;
  FMouseViewBack.Visible := False;

  // The title, centred
  FMouseViewLabel := MouseViewText(FMouseViewBack, 'Mouseview On', TTextAlign.Center);
  FMouseViewLabel.Align := TAlignLayout.Top;
  FMouseViewLabel.Height := MOUSE_VIEW_TITLE_HEIGHT;

  // Under it, while turned or zoomed: two rows of a name at the left and a
  // value at the right, and the reset hint, centred
  FMouseViewDetails := TLayout.Create(Self);
  FMouseViewDetails.Parent := FMouseViewBack;
  FMouseViewDetails.Position.Y := MOUSE_VIEW_TITLE_HEIGHT;
  FMouseViewDetails.Align := TAlignLayout.Top;
  FMouseViewDetails.Height := 3 * MOUSE_VIEW_ROW_HEIGHT;
  FMouseViewDetails.Padding.Left := 8;
  FMouseViewDetails.Padding.Right := 8;
  FMouseViewDetails.HitTest := False;
  FMouseViewDetails.Visible := False;
  MouseViewRow(0, 'Azimuth', FMouseAzimuthValue);
  FMouseDistanceName := MouseViewRow(1, 'Distance', FMouseDistanceValue);
  var ResetHint := MouseViewText(FMouseViewDetails, 'Right Click to Reset',
    TTextAlign.Center);
  ResetHint.Position.Y := 2 * MOUSE_VIEW_ROW_HEIGHT;
  ResetHint.Align := TAlignLayout.Top;
  ResetHint.Height := MOUSE_VIEW_ROW_HEIGHT;

  FMouseViewBack.BringToFront;
  PlaceMouseViewReadout;

  AspectLayout.OnMouseDown := ViewMouseDown;
  AspectLayout.OnMouseMove := ViewMouseMove;
  AspectLayout.OnMouseUp := ViewMouseUp;
  AspectLayout.OnMouseWheel := ViewMouseWheel;

  // Ticked as it was left last session, from the normal view
  ApplyMouseViewTick(FSettings.MouseView);
end;

procedure TMainForm.PlaceMouseViewReadout;
var
  Left: Single;
begin
  if not Assigned(FMouseViewBack) then
    Exit;
  // 8 pixels in from the right, as the frame rate is from the left, but
  // never past the left edge in a very narrow view
  Left := ViewportLayout.Width - FMouseViewBack.Width - 8;
  if Left < 8 then
    Left := 8;
  FMouseViewBack.Position.Point := TPointF.Create(Left, 6);
end;

//** @abstract(A value with its sign, + or -, to 3 decimal places; a value that would show
//** as 0.000 shows as +0.000.)
//** @param(AValue The value.)
//** @returns(Such as +12.500 or -0.250.)
function SignedText(const AValue: Single): String;
begin
  if Abs(AValue) < MOUSE_VIEW_SHOWN_ZERO then
    Result := '+' + FormatFloat('0.000', 0)
  else if AValue < 0 then
    Result := '-' + FormatFloat('0.000', -AValue)
  else
    Result := '+' + FormatFloat('0.000', AValue);
end;

procedure TMainForm.UpdateMouseViewReadout;
var
  Turn, Zoom: Single;
  Shown: Boolean;
begin
  if not Assigned(FMouseViewBack) then
    Exit;
  Turn := 0;
  Zoom := 1;
  if FMouseApplied and Assigned(GorillaCamera) then
  begin
    // As the dials show the azimuth, which runs the other way to the
    // camera's own, from -180 to +180
    Turn := -FMouseYaw;
    if Turn <= -180 then
      Turn := Turn + 360;
    // A factor on the normal view's distance, or size, as Variable's
    // Distance slider gives its own; opening Variable multiplies the two
    Zoom := FMouseZoom;
  end;
  Shown := (Abs(Turn) >= MOUSE_VIEW_SHOWN_ZERO) or
    (Abs(Zoom - 1) >= MOUSE_VIEW_SHOWN_ZERO);
  if Shown then
  begin
    FMouseAzimuthValue.Text := SignedText(Turn);
    FMouseDistanceValue.Text := 'x' + FormatFloat('0.000', Zoom);
    // In orthographic projection the wheel changes the view's size
    if FMouseZoomOrtho then
      FMouseDistanceName.Text := 'Size'
    else
      FMouseDistanceName.Text := 'Distance';
  end;
  if FMouseViewDetails.Visible <> Shown then
  begin
    FMouseViewDetails.Visible := Shown;
    if Shown then
      FMouseViewBack.Height := MOUSE_VIEW_TITLE_HEIGHT + 3 * MOUSE_VIEW_ROW_HEIGHT + 3
    else
      FMouseViewBack.Height := MOUSE_VIEW_TITLE_HEIGHT;
  end;
end;

procedure TMainForm.ApplyMouseViewTick(const AOn: Boolean);
begin
  FMouseViewItem.IsChecked := AOn;
  FMouseDragging := False;
  if not AOn then
    ResetMouseView;
  AspectLayout.HitTest := AOn;
  FMouseViewBack.Visible := AOn;
  UpdateMouseViewReadout;
end;

function TMainForm.MouseViewOn: Boolean;
begin
  Result := Assigned(FMouseViewItem) and FMouseViewItem.IsChecked;
end;

procedure TMainForm.MouseViewItemClick(Sender: TObject);
begin
  ApplyMouseViewTick(not FMouseViewItem.IsChecked);
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
    DebugMemo.Lines.Add('Mouse view on: left-drag turns the view, the wheel ' +
      'zooms, a right click puts the normal view back')
  else
    DebugMemo.Lines.Add('Mouse view off');
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
  UpdateMouseViewReadout;
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
  UpdateMouseViewReadout;
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
  UpdateMouseViewReadout;
end;

procedure TMainForm.ViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if not MouseViewOn then
    Exit;
  // A Control-click counts as a right-click, as it does on the lists, for a
  // Mac with one button
  if (Button = TMouseButton.mbRight) or
    ((Button = TMouseButton.mbLeft) and (ssCtrl in Shift)) then
    ResetMouseView
  else if Button = TMouseButton.mbLeft then
  begin
    FMouseDragging := True;
    FMouseLastX := X;
  end;
end;

procedure TMainForm.ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  Moved: Single;
begin
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
  if Button = TMouseButton.mbLeft then
    FMouseDragging := False;
end;

procedure TMainForm.ViewMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  if not MouseViewOn then
    Exit;
  Handled := True;
  // A notch is 120; rolling the wheel away brings the camera nearer, towards
  // you takes it further away
  MoveMouseView(0, Power(MOUSE_VIEW_ZOOM_STEP, -WheelDelta / 120));
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
{$ENDIF}

end.
