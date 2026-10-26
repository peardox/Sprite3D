//** @abstract(Support routines for the Sprite3D application that are neither UI nor library.)
//**
//** The application keeps three kinds of code apart. The units in @code(ui) only handle the
//** user interface; the units in @code(lib) are a library with no knowledge of this
//** application, usable in other projects; and this unit holds what is left: the
//** application's own rules, such as where models are found, how grabs are named and saved,
//** and how a loaded model is placed. It uses the library and the RTL, never the UI.
//**
//** TSprite3DAppSettings holds the settings kept between sessions, in @code(settings.json)
//** in the application's own per-user folder, SupportFolder. The measured bounds of each
//** model's animations are kept there too, one file per model in its @code(bounds) folder,
//** through LoadAnimationBoundsCache and SaveAnimationBoundsCache.
//**
//** Loading a model through LoadModelFile also registers Gorilla3D's loaders for glTF, FBX,
//** OBJ, USD, Collada, STL and PLY files, as this unit uses them. Each model the application
//** keeps loaded, on its Static or Animated tab, is held in a TSprite3DModelSlot, made with
//** NewModelSlot, found with ModelSlotIndex and freed with FreeModelSlot; ShowModelWithHelpers
//** shows or hides one with everything drawn beside it.
//**
//** All routines are for the main thread, except the members of IModelFileRead.
unit Sprite3DHelpers;

{
  Support routines for the Sprite3D application that are neither UI nor
  library.

  The application keeps three kinds of code apart. The units in ui only
  handle the user interface; the units in lib are a library with no
  knowledge of this application, usable in other projects; and this unit
  holds what is left: the application's own rules, such as where models are
  found, how grabs are named and saved, and how a loaded model is placed.
  It uses the library and the RTL, never the UI.

  TSprite3DAppSettings holds the settings kept between sessions, in
  settings.json in the application's own per-user folder, SupportFolder.
  The measured bounds of each model's animations are kept there too, one
  file per model in its bounds folder, through LoadAnimationBoundsCache and
  SaveAnimationBoundsCache.

  Loading a model through LoadModelFile also registers Gorilla3D's loaders
  for glTF, FBX, OBJ, USD, Collada, STL and PLY files, as this unit uses
  them. Each model the application keeps loaded, on its Static or Animated
  tab, is held in a TSprite3DModelSlot, made with NewModelSlot, found with
  ModelSlotIndex and freed with FreeModelSlot; ShowModelWithHelpers shows
  or hides one with everything drawn beside it.

  All routines are for the main thread, except the members of
  IModelFileRead.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math.Vectors,
  FMX.Graphics, FMX.Types3D, FMX.Controls3D,
  System.JSON, Gorilla.Model, Sprite3DStorage, Sprite3DBackground, Sprite3DFileAssoc,
  Sprite3DResample, Sprite3DSweep, Neon.Core.Attributes;

const
  //** @abstract(The application's name, used for its per-user folder.)
  APP_NAME = 'Sprite3D';
  //** @abstract(The name of the settings file in SupportFolder.)
  SETTINGS_FILE_NAME = 'settings.json';
  //** @abstract(Where the list of OpenH264 downloads is fetched from at run time.)
  //**
  //** A JSON file giving, for each platform key from Sprite3DNativeLibs, the OpenH264 library
  //** to download; see Sprite3DLibraryUpdate. It is not fetched while debugging is on.
  OPENH264_LIST_URL = 'https://sprite3d.com/openh264/openh264.json';
  //** @abstract(The First frame button's icon, a bar and two left-pointing triangles.)
  //**
  //** Like the other ICON_ constants, an SVG path in a 24 by 24 box, for a TPath drawn in the
  //** button's text colour; shared by the Model tab's player and the Results tab's.
  ICON_FIRST = 'M5 6h2v12H5z M8 12l6-6v12z M14 12l6-6v12z';
  //** @abstract(The Previous frame button's icon, a left-pointing triangle and a bar.)
  //**
  //** An SVG path in a 24 by 24 box; see @link(ICON_FIRST).
  ICON_PREVIOUS = 'M7 12l7-6v12z M15 6h2v12h-2z';
  //** @abstract(The Play button's icon, a right-pointing triangle.)
  //**
  //** An SVG path in a 24 by 24 box; see @link(ICON_FIRST).
  ICON_PLAY = 'M8 5v14l11-7z';
  //** @abstract(The Pause icon, two bars, shown on the Play button while playing.)
  //**
  //** An SVG path in a 24 by 24 box; see @link(ICON_FIRST).
  ICON_PAUSE = 'M6 5h4v14H6z M14 5h4v14h-4z';
  //** @abstract(The Next frame button's icon, a bar and a right-pointing triangle.)
  //**
  //** An SVG path in a 24 by 24 box; see @link(ICON_FIRST).
  ICON_NEXT = 'M7 6h2v12H7z M10 6v12l7-6z';
  //** @abstract(The Last frame button's icon, two right-pointing triangles and a bar.)
  //**
  //** An SVG path in a 24 by 24 box; see @link(ICON_FIRST).
  ICON_LAST = 'M4 6v12l6-6z M10 6v12l6-6z M17 6h2v12h-2z';
  //** @abstract(The largest camera pan either way, as a multiple of the model's radius.)
  //**
  //** The radius is half the diagonal of the model's bounding box, so a pan of 1 moves the
  //** orbit centre out to where the model's farthest corner was.
  PAN_LIMIT = 2.0;
  //** @abstract(The lowest frame rate Models, Animation Settings offers for saved
  //** animations, in frames per second.)
  ANIMATION_FPS_MIN = 1;
  //** @abstract(The highest frame rate Models, Animation Settings offers for saved
  //** animations, in frames per second.)
  //**
  //** Gorilla bakes animations at 60 frames a second on desktop, so a higher rate would only
  //** repeat frames.
  ANIMATION_FPS_MAX = 60;
  //** @abstract(The frame rate saved animations use until Models, Animation Settings changes
  //** it.)
  ANIMATION_FPS_DEFAULT = 30;
  //** @abstract(The smallest overscan factor Models, Animation Settings offers.)
  OVERSCAN_FACTOR_MIN = 2;
  //** @abstract(The largest overscan factor Models, Animation Settings offers, before the
  //** GPU's own limit for the grab size.)
  OVERSCAN_FACTOR_MAX = 8;
  //** @abstract(The overscan factor Models, Animation Settings shows until another is
  //** chosen.)
  OVERSCAN_FACTOR_DEFAULT = 4;
  //** @abstract(The lowest frame rate File, Settings lets the view be drawn at.)
  VIEW_FPS_MIN = 1;
  //** @abstract(The highest frame rate kept for the view; File, Settings offers no more than
  //** the display's refresh rate.)
  VIEW_FPS_MAX = 1000;
  //** @abstract(The frame rate the view is drawn at until File, Settings changes it, and the
  //** most it offers where the display's refresh rate is not known.)
  VIEW_FPS_DEFAULT = 60;
  //** @abstract(The numbers of directions Models, Directions offers: 1, 2, and every
  //** multiple of 4 or 6 up to 64, smallest first.)
  DIRECTION_COUNTS: array[0..22] of Integer =
    (1, 2, 4, 6, 8, 12, 16, 18, 20, 24, 28, 30, 32, 36, 40, 42, 44, 48, 52, 54, 56, 60, 64);
  //** @abstract(The number of directions until Models, Directions changes it.)
  DIRECTION_COUNT_DEFAULT = 8;
  //** @abstract(The largest a texture atlas page may be, each way, as Animation, Animation
  //** Settings offers it: 1k, 2k, 4k, 8k and 16k pixels.)
  ATLAS_PAGE_SIZES: array[0..4] of Integer = (1024, 2048, 4096, 8192, 16384);
  //** @abstract(The texture atlas page size until Models, Animation Settings changes it.)
  ATLAS_PAGE_SIZE_DEFAULT = 4096;
  //** @abstract(The @code(format) a directions file names itself with, so another JSON file
  //** is not taken for one.)
  DIRECTIONS_FILE_FORMAT = 'Sprite3D directions';
  //** @abstract(The newest directions file layout this version writes and reads.)
  DIRECTIONS_FILE_VERSION = 1;
  //** @abstract(The extension Models, Directions gives the directions files it exports.)
  DIRECTIONS_FILE_EXTENSION = '.json';
  //** @abstract(The extension of Sprite3D project files: credits, the model, directions and
  //** the Animations list, which File, Save Project saves and the system opens with
  //** Sprite3D.)
  PROJECT_FILE_EXTENSION = '.sprite3d';
  //** @abstract(The @code(format) a project file names itself with.)
  PROJECT_FILE_FORMAT = 'Sprite3D project';
  //** @abstract(The newest project file layout this version writes and reads.)
  PROJECT_FILE_VERSION = 1;
  //** @abstract(The smallest width or height File, Grab renders, in pixels.)
  GRAB_SIZE_MIN = 8;
  //** @abstract(The largest width or height File, Grab renders, in pixels.)
  GRAB_SIZE_MAX = 1024;
  //** @abstract(The width and height File, Grab renders until another size is chosen.)
  GRAB_SIZE_DEFAULT = 256;
  //** @abstract(The square grab sizes File, Settings offers, in pixels, smallest first.)
  //**
  //** Any other size, square or not, is a custom size.
  GRAB_PRESET_SIZES: array[0..11] of Integer =
    (8, 16, 24, 32, 64, 96, 128, 160, 192, 256, 384, 512);

type
  //** @abstract(Raised by LoadDirectionsFile when a file cannot be used as directions.)
  //**
  //** The message says what is wrong, in words fit to show the user.
  EDirectionsFile = class(Exception);

  //** @abstract(Who made a sprite set, as File, Save Project sets it and the metadata's
  //** @code(meta) gives it.)
  //**
  //** Every field may be empty. Created is a date as ISO 8601 text, @code(yyyy-mm-dd).
  TSprite3DCredits = record
    //** @abstract(Who created the sprite set.)
    Creator: String;
    //** @abstract(Where the creator's work is.)
    CreatorUrl: String;
    //** @abstract(Who made the models.)
    Modeller: String;
    //** @abstract(Where the modeller's work is.)
    ModellerUrl: String;
    //** @abstract(Who made the textures.)
    Artist: String;
    //** @abstract(Where the artist's work is.)
    ArtistUrl: String;
    //** @abstract(The day the project started, as @code(yyyy-mm-dd); empty if not set.)
    Created: String;
  end;

  //** @abstract(What the application loads when it starts and no file was asked for.)
  //**
  //** @code(saNone) loads nothing; @code(saDefaultModel) loads the sample model;
  //** @code(saLastModel) loads the models last opened on the Static and Animated tabs, the one
  //** used last last, or the sample model if they have gone; after Clear has emptied both
  //** tabs it loads nothing. A file the operating system asks the application to open always
  //** comes first.
  TSprite3DStartupAction = (saNone, saDefaultModel, saLastModel);

  //** @abstract(The application's look: FMX's own default style, or one of the FMX styles
  //** that come with RAD Studio.)
  //**
  //** @code(thDefault) is the platform's own style. @code(thDark) is Dark.style; the others
  //** are the coloured Graphite styles, dark grey with an accent: @code(thAquaGraphite) blue,
  //** @code(thRubyGraphite) red and @code(thGoldenGraphite) gold.
  TSprite3DTheme = (thDefault, thDark, thAquaGraphite, thRubyGraphite, thGoldenGraphite);

  //** @abstract(Which graphics processor Windows gives the application.)
  //**
  //** @code(gmSystem) lets Windows decide; @code(gmPowerSaving) asks for the low-power GPU and
  //** @code(gmHighPerformance) for the high-performance one. Used on Windows only, and only
  //** after the application is restarted.
  TSprite3DGpuMode = (gmSystem, gmPowerSaving, gmHighPerformance);

  //** @abstract(The choices made in File, Settings, together.)
  TSprite3DGeneralSettings = record
    //** @abstract(Whether the application is offered under Open With for model files.)
    OpenWith: Boolean;
    //** @abstract(Whether the application opens model files by default.)
    AlwaysOpenWith: Boolean;
    //** @abstract(What is loaded at start-up.)
    StartupAction: TSprite3DStartupAction;
    //** @abstract(The application's look.)
    Theme: TSprite3DTheme;
    //** @abstract(The graphics processor asked for; Windows only.)
    GpuMode: TSprite3DGpuMode;
    //** @abstract(The width of off-screen grabs, in pixels, GRAB_SIZE_MIN to GRAB_SIZE_MAX.)
    GrabWidth: Integer;
    //** @abstract(The height of off-screen grabs, in pixels, GRAB_SIZE_MIN to GRAB_SIZE_MAX.)
    GrabHeight: Integer;
    //** @abstract(The folder File, Grab saves into; empty to be asked at the next grab.)
    SaveFolder: String;
    //** @abstract(The frame rate the view is drawn at, VIEW_FPS_MIN to MaxViewFps.)
    ViewFps: Integer;
    //** @abstract(Whether JSON files are written minified.)
    MinifyJson: Boolean;
    //** @abstract(Whether the Results tab's empty border values have a hint explaining them.)
    ResultsEdgeHint: Boolean;
    //** @abstract(The most ViewFps may be: the display's refresh rate, set by the caller; not
    //** kept.)
    MaxViewFps: Integer;
  end;

  //** @abstract(Protected-access helper for TControl3D; nothing in the project uses it yet.)
  //**
  //** Casting a TControl3D to this class exposes its protected members inside the unit that
  //** declares the cast. Because it is in the interface section, other units can use it too.
  TControl3DAccess = class(TControl3D);

  //** @abstract(One loaded model and what was measured of it as it loaded: the animated
  //** model of the Animated tab, or one entry of the Static tab's Models list.)
  //**
  //** The application keeps every model it has loaded in the viewport, hidden while another
  //** is shown, each with one of these. Make one with NewModelSlot, find one by file with
  //** ModelSlotIndex, and free its model with FreeModelSlot. A record with Model nil stands
  //** for no model; EmptyModelSlot returns one.
  TSprite3DModelSlot = record
    //** @abstract(The model, parented to the viewport; nil for none.)
    Model: TGorillaModel;
    //** @abstract(The file it was loaded from, expanded.)
    FileName: String;
    //** @abstract(The name it is listed and exported by: its file's name without the
    //** extension, unless that was taken and it was renamed with UniqueModelName.)
    Name: String;
    //** @abstract(Its own bounds, measured as it loaded, before any helper was added.)
    Box: TBoundingBox;
    //** @abstract(Each animation's bounds over all its poses; empty for a static model.)
    Bounds: TArray<TAnimationBounds>;
    //** @abstract(Every animation the model has, in its order; empty for a static model.)
    Names: TArray<String>;
    //** @abstract(The animations Models, Animations Used ticks; every one, as loaded.)
    Used: TArray<String>;
    //** @abstract(Whether the model has animations: True for the Animated tab's model, False
    //** for the Static tab's.)
    IsAnimated: Boolean;
    //** @abstract(When it was first listed, counting up from 1, so the static models can be
    //** shown in the order they were opened whether or not Models, Statics Used lists them;
    //** 0 until it is listed.)
    Order: Integer;
  end;

  //** @abstract(The application's settings, kept between sessions in settings.json.)
  //**
  //** Create it, call Load once at start-up, and call Save after changing a setting. The file
  //** is @code(settings.json) in SupportFolder; on the first run it does not exist yet, so
  //** every setting keeps its default until the first Save. For the main thread only.
  //**
  //** @seealso(TSprite3DJsonSettings)
  TSprite3DAppSettings = class(TSprite3DJsonSettings)
  private
    FSaveFolder: String;
    FIconFolder: String;
    FDirectionsFolder: String;
    FBackgroundKind: TSprite3DBackgroundKind;
    FBackgroundColour: String;
    FGradientFrom: String;
    FGradientTo: String;
    FGradientDirection: TSprite3DGradientDirection;
    FCheckerSize: Integer;
    FCheckerLight: String;
    FCheckerDark: String;
    FShowBoundingBox: Boolean;
    FShowGrid: Boolean;
    FShowAxes: Boolean;
    FShowSweptVolume: Boolean;
    FShowCombinedSweptVolume: Boolean;
    FOrthographic: Boolean;
    FCameraView: String;
    FVariableAzimuth: Single;
    FVariableInclination: Single;
    FVariableRoll: Single;
    FPanEnabled: Boolean;
    FPanX: Single;
    FPanZ: Single;
    FStartupAction: TSprite3DStartupAction;
    FLastModel: String;
    FLastAnimatedModel: String;
    FLastStaticModel: String;
    FTheme: String;
    FGpuMode: TSprite3DGpuMode;
    FOpenWith: Boolean;
    FAlwaysOpenWith: Boolean;
    FAssociationBackup: String;
    FGrabWidth: Integer;
    FGrabHeight: Integer;
    FAnimationFps: Integer;
    FViewFps: Integer;
    FMinifyJson: Boolean;
    FDirectionCount: Integer;
    FDirectionStart: Single;
    FDirectionClockwise: Boolean;
    FDirectionOrder: String;
    FDirectionSnap: Boolean;
    FExportMetadata: Boolean;
    FExportDirections: Boolean;
    FAtlasPageSize: Integer;
    FAtlasNonPowerOf2: Boolean;
    FExportKind: String;
    FAtlasFolder: String;
    FDebugEnabled: Boolean;
    FDebugSwitch: Boolean;
    FDebugFrameBorders: Boolean;
    FDebugSaveOversampled: Boolean;
    FExportAutoClose: Boolean;
    FLastExportFolder: String;
    FOpenDirectoryFolder: String;
    FOpenDirectorySpec: String;
    FShowOverscanWarning: Boolean;
    FShowExactWarning: Boolean;
    FResultsShowGrid: Boolean;
    FResultsEdgeHint: Boolean;
    FResultsZoom: Single;
    FOverscan: Integer;
    FPadding: Integer;
    FResampleFilter: TSprite3DResampleFilter;
    procedure SetAnimationFps(const Value: Integer);
    procedure SetViewFps(const Value: Integer);
    procedure SetMinifyJson(const Value: Boolean);
    procedure SetDirectionCount(const Value: Integer);
    procedure SetDirectionStart(const Value: Single);
    procedure SetOverscan(const Value: Integer);
    procedure SetPadding(const Value: Integer);
    procedure SetAtlasPageSize(const Value: Integer);
    procedure SetGrabWidth(const Value: Integer);
    procedure SetGrabHeight(const Value: Integer);
    function GetBackgroundSpec: TSprite3DBackgroundSpec;
    procedure SetBackgroundSpec(const Value: TSprite3DBackgroundSpec);
    function GetThemeKind: TSprite3DTheme;
    procedure SetThemeKind(const Value: TSprite3DTheme);
  public
    //** @abstract(Creates the settings with their defaults, for settings.json in
    //** SupportFolder.)
    //**
    //** Nothing is read until Load is called.
    constructor Create; reintroduce;
    //** @abstract(The application's per-user folder, for settings.json and support files.)
    //**
    //** AppDataFolder for APP_NAME: for example @code(%APPDATA%\Sprite3D) on Windows. It is
    //** created by the first Save.
    //**
    //** @returns(The folder's full path, without a trailing path delimiter.)
    class function SupportFolder: String; static;
    //** @abstract(True if SaveFolder is set and the folder still exists.)
    //**
    //** False on the first run, and also if the folder has been removed or is on a drive
    //** that is not connected, so the user can be asked for a folder again.
    //**
    //** @returns(Whether grabs can be saved in SaveFolder without asking.)
    function HasSaveFolder: Boolean;
    //** @abstract(The order the directions are taken in: for each direction, from the first,
    //** its position round the compass.)
    //**
    //** Positions count clockwise from 0 at DirectionStart. This is DirectionOrder when it
    //** holds every position from 1 to DirectionCount once each, less one; otherwise the plain
    //** order, clockwise or anticlockwise as DirectionClockwise says.
    //**
    //** @returns(DirectionCount positions, every one from 0 to DirectionCount - 1 once.)
    function DirectionOrderList: TArray<Integer>;
    //** @abstract(Each direction's compass bearing, in the order the directions are taken
    //** in.)
    //**
    //** @returns(DirectionCount bearings, in degrees clockwise from north, 0 up to 360.)
    function DirectionBearings: TArray<Single>;
    //** @abstract(The background settings together, as the viewport and grabs use them.)
    //**
    //** Reading turns the stored colour texts back into colours; one that cannot be read
    //** takes its default. Writing stores all of them; call Save afterwards to keep them.
    property BackgroundSpec: TSprite3DBackgroundSpec read GetBackgroundSpec
      write SetBackgroundSpec;
    //** @abstract(Theme as a TSprite3DTheme.)
    //**
    //** A name in settings.json that is not one of the themes, such as one from an older
    //** version, reads as thDefault.
    property ThemeKind: TSprite3DTheme read GetThemeKind write SetThemeKind;
    //** @abstract(Whether --debug was given on the command line; False by default.)
    //**
    //** Turns debugging on for this run only, as DebugEnabled does: it is public, not
    //** published, so it is never written to settings.json. Set once at start-up.
    property DebugSwitch: Boolean read FDebugSwitch write FDebugSwitch;
    //** @abstract(Whether debugging is on: DebugEnabled from settings.json, or DebugSwitch
    //** from the command line.)
    //**
    //** While it is, File, Debug is offered, the Debug tab says so at start-up, and OpenH264
    //** is neither fetched nor loaded.
    //**
    //** @returns(True if either is set.)
    function DebugActive: Boolean;
  published
    //** @abstract(The folder grabs are saved in; empty until one is chosen.)
    //**
    //** Stored as @code(saveFolder) in settings.json.
    property SaveFolder: String read FSaveFolder write FSaveFolder;
    //** @abstract(The folder the last icon was saved in, where the next save dialog opens;
    //** empty until an icon is saved.)
    //**
    //** Stored as @code(iconFolder) in settings.json.
    property IconFolder: String read FIconFolder write FIconFolder;
    //** @abstract(The folder a directions file was last exported to or imported from, where
    //** the next Export or Import in Models, Directions opens; empty until one is.)
    //**
    //** Stored as @code(directionsFolder) in settings.json.
    property DirectionsFolder: String read FDirectionsFolder write FDirectionsFolder;
    //** @abstract(What the background shows: None, Transparent, Solid or Gradient.)
    //**
    //** Stored as @code(backgroundKind), by name. None, the default until one is chosen,
    //** draws no background; Transparent shows a checker in the viewport. Both leave grabs
    //** transparent.
    property BackgroundKind: TSprite3DBackgroundKind read FBackgroundKind
      write FBackgroundKind;
    //** @abstract(The Solid background's colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(backgroundColour).
    property BackgroundColour: String read FBackgroundColour write FBackgroundColour;
    //** @abstract(The Gradient background's starting colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(gradientFrom).
    property GradientFrom: String read FGradientFrom write FGradientFrom;
    //** @abstract(The Gradient background's ending colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(gradientTo).
    property GradientTo: String read FGradientTo write FGradientTo;
    //** @abstract(Which way the Gradient background runs.)
    //**
    //** Stored as @code(gradientDirection), by name. TopToBottom, the default, is used when
    //** settings.json has none.
    property GradientDirection: TSprite3DGradientDirection read FGradientDirection
      write FGradientDirection;
    //** @abstract(The side of each checker square in the viewport, in pixels; 64 by
    //** default.)
    //**
    //** Stored as @code(checkerSize). Values below 1 count as 1.
    property CheckerSize: Integer read FCheckerSize write FCheckerSize;
    //** @abstract(The lighter checker colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(checkerLight).
    property CheckerLight: String read FCheckerLight write FCheckerLight;
    //** @abstract(The darker checker colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(checkerDark).
    property CheckerDark: String read FCheckerDark write FCheckerDark;
    //** @abstract(Whether View, Show bounding box is ticked on the main form; True by
    //** default.)
    //**
    //** Stored as @code(showBoundingBox).
    property ShowBoundingBox: Boolean read FShowBoundingBox write FShowBoundingBox;
    //** @abstract(Whether View, Show grid is ticked on the main form; True by default.)
    //**
    //** Stored as @code(showGrid).
    property ShowGrid: Boolean read FShowGrid write FShowGrid;
    //** @abstract(Whether View, Show axes is ticked on the main form; True by default.)
    //**
    //** Stored as @code(showAxes).
    property ShowAxes: Boolean read FShowAxes write FShowAxes;
    //** @abstract(Whether View, Show Model Volume is ticked on the main form; True by
    //** default.)
    //**
    //** Stored as @code(showSweptVolume).
    property ShowSweptVolume: Boolean read FShowSweptVolume write FShowSweptVolume;
    //** @abstract(Whether View, Show Animation Volume is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(showCombinedSweptVolume).
    property ShowCombinedSweptVolume: Boolean read FShowCombinedSweptVolume
      write FShowCombinedSweptVolume;
    //** @abstract(Whether View, Orthographic is ticked on the main form; False by default.)
    //**
    //** Stored as @code(orthographic).
    property Orthographic: Boolean read FOrthographic write FOrthographic;
    //** @abstract(The main form's camera view, the checked View, Camera item; Isometric by
    //** default.)
    //**
    //** Stored as @code(cameraView): the item's name without its View prefix and Item suffix,
    //** one of Variable, Isometric, Pixel2To1, ThreeQuarter, HeadOn, TopDown and Side. An
    //** unknown name gives Isometric.
    property CameraView: String read FCameraView write FCameraView;
    //** @abstract(The Azimuth dial's angle in the Variable view, in degrees; 0 by default.)
    //**
    //** Stored as @code(variableAzimuth). Kept whenever the session ends in the Variable
    //** view, and restored with it.
    property VariableAzimuth: Single read FVariableAzimuth write FVariableAzimuth;
    //** @abstract(The Inclination dial's angle in the Variable view, in degrees; 0 by
    //** default.)
    //**
    //** Stored as @code(variableInclination). Kept whenever the session ends in the Variable
    //** view, and restored with it.
    property VariableInclination: Single read FVariableInclination
      write FVariableInclination;
    //** @abstract(The Roll dial's angle in the Variable view, in degrees; 0 by default.)
    //**
    //** Stored as @code(variableRoll). Kept whenever the session ends in the Variable view,
    //** and restored with it.
    property VariableRoll: Single read FVariableRoll write FVariableRoll;
    //** @abstract(Whether the camera pan is applied; False by default.)
    //**
    //** Stored as @code(panEnabled). Set by the Pan box in the Variable camera dialog. While
    //** False, PanX and PanZ are kept but have no effect.
    property PanEnabled: Boolean read FPanEnabled write FPanEnabled;
    //** @abstract(The camera pan along the model's X axis, as a multiple of its radius; 0 by
    //** default.)
    //**
    //** Stored as @code(panX). Values beyond PAN_LIMIT either way are limited to it.
    property PanX: Single read FPanX write FPanX;
    //** @abstract(The camera pan along the model's Z axis, as a multiple of its radius; 0 by
    //** default.)
    //**
    //** Stored as @code(panZ). Values beyond PAN_LIMIT either way are limited to it.
    property PanZ: Single read FPanZ write FPanZ;
    //** @abstract(What is loaded at start-up; the sample model by default.)
    //**
    //** Stored as @code(startupAction), by name.
    property StartupAction: TSprite3DStartupAction read FStartupAction write FStartupAction;
    //** @abstract(The full path of the model last loaded, of either kind; empty until one is,
    //** or once Clear has emptied both tabs.)
    //**
    //** Stored as @code(lastModel). Used when StartupAction is saLastModel, which loads it
    //** last, so its tab is the one shown.
    property LastModel: String read FLastModel write FLastModel;
    //** @abstract(The full path of the model with animations last loaded; empty until one is,
    //** or once Clear has emptied the Animated tab.)
    //**
    //** Stored as @code(lastAnimatedModel). Used when StartupAction is saLastModel.
    property LastAnimatedModel: String read FLastAnimatedModel write FLastAnimatedModel;
    //** @abstract(The full path of the static model last loaded; empty until one is, or once
    //** Clear has emptied the Static tab.)
    //**
    //** Stored as @code(lastStaticModel). Used when StartupAction is saLastModel.
    property LastStaticModel: String read FLastStaticModel write FLastStaticModel;
    //** @abstract(The application's look, by name; Default by default.)
    //**
    //** Stored as @code(theme): one of Default, Dark, AquaGraphite, RubyGraphite and
    //** GoldenGraphite. Kept as text rather than as an enumeration so that a name this version
    //** does not know can never stop settings.json loading; use ThemeKind in code.
    property Theme: String read FTheme write FTheme;
    //** @abstract(The graphics processor last chosen in File, Settings; Windows only.)
    //**
    //** Stored as @code(gpuMode), by name. Windows keeps the choice itself, per program file;
    //** the dialog shows what Windows has, so this is a record of the last choice.
    property GpuMode: TSprite3DGpuMode read FGpuMode write FGpuMode;
    //** @abstract(Whether the application was last registered for Open With.)
    //**
    //** Stored as @code(openWith). The system's registration is what counts; the dialog reads
    //** it afresh.
    property OpenWith: Boolean read FOpenWith write FOpenWith;
    //** @abstract(Whether the application was last made the default for model files.)
    //**
    //** Stored as @code(alwaysOpenWith).
    property AlwaysOpenWith: Boolean read FAlwaysOpenWith write FAlwaysOpenWith;
    //** @abstract(The default applications model files had before this one was made the
    //** default, for putting them back.)
    //**
    //** Stored as @code(associationBackup): one @code(key=value) line per type, as
    //** TSprite3DFileAssociations.MakeDefault writes it. Empty when nothing needs putting back.
    property AssociationBackup: String read FAssociationBackup write FAssociationBackup;
    //** @abstract(The width of off-screen grabs, in pixels; GRAB_SIZE_DEFAULT by default.)
    //**
    //** Stored as @code(grabWidth). Written values are limited to GRAB_SIZE_MIN to
    //** GRAB_SIZE_MAX.
    property GrabWidth: Integer read FGrabWidth write SetGrabWidth;
    //** @abstract(The height of off-screen grabs, in pixels; GRAB_SIZE_DEFAULT by default.)
    //**
    //** Stored as @code(grabHeight). Written values are limited to GRAB_SIZE_MIN to
    //** GRAB_SIZE_MAX.
    property GrabHeight: Integer read FGrabHeight write SetGrabHeight;
    //** @abstract(The frame rate animations are saved at, in frames per second;
    //** ANIMATION_FPS_DEFAULT by default.)
    //**
    //** Set in Models, Animation Settings. Stored as @code(animationFps). Written values are
    //** limited to ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.
    property AnimationFps: Integer read FAnimationFps write SetAnimationFps;
    //** @abstract(The frame rate the view is drawn at, in frames per second;
    //** VIEW_FPS_DEFAULT by default.)
    //**
    //** Set in File, Settings, which offers up to the display's refresh rate. Stored as
    //** @code(viewFps). Written values are limited to VIEW_FPS_MIN to VIEW_FPS_MAX.
    property ViewFps: Integer read FViewFps write SetViewFps;
    //** @abstract(Whether JSON files are written minified, with no indents or line breaks;
    //** False by default.)
    //**
    //** Set in File, Settings. Stored as @code(minifyJson). Writing it, loading settings.json
    //** included, sets JsonText.MinifyJson, which every JSON file Sprite3D writes follows,
    //** settings.json itself among them.
    property MinifyJson: Boolean read FMinifyJson write SetMinifyJson;
    //** @abstract(How many directions Models, Directions has around its compass;
    //** DIRECTION_COUNT_DEFAULT by default.)
    //**
    //** Stored as @code(directionCount). A written value that is not one of DIRECTION_COUNTS
    //** becomes the nearest that is.
    property DirectionCount: Integer read FDirectionCount write SetDirectionCount;
    //** @abstract(The compass bearing of position 0, the red marker in Models, Directions,
    //** in degrees clockwise from north; 0, north, by default.)
    //**
    //** Stored as @code(directionStart). It is the first direction's bearing unless
    //** DirectionOrder puts another first. Written values are wrapped into 0 up to 360.
    property DirectionStart: Single read FDirectionStart write SetDirectionStart;
    //** @abstract(Whether the directions are numbered clockwise from the first; True by
    //** default.)
    //**
    //** Stored as @code(directionClockwise). False numbers them anticlockwise. Used when
    //** DirectionOrder is empty or does not fit DirectionCount.
    property DirectionClockwise: Boolean read FDirectionClockwise
      write FDirectionClockwise;
    //** @abstract(The order the directions are taken in, as Models, Directions set it; empty
    //** by default.)
    //**
    //** Stored as @code(directionOrder): the positions round the compass, counted clockwise
    //** from 1 at DirectionStart, in the order the directions are numbered, separated by
    //** commas, such as @code('3,5,7,1,4,6,8,2') for E, S, W, N, SE, SW, NW and NE when the
    //** first of eight is north. Empty, or text that is not every position from 1 to
    //** DirectionCount once each, means the plain order DirectionClockwise gives. Use
    //** DirectionOrderList and DirectionBearings rather than reading it directly.
    property DirectionOrder: String read FDirectionOrder write FDirectionOrder;
    //** @abstract(Whether the Models, Directions dial turns in steps of one direction; False
    //** by default.)
    //**
    //** Stored as @code(directionSnap). True locks DirectionStart to whole multiples of 360
    //** divided by DirectionCount, counted from north.
    property DirectionSnap: Boolean read FDirectionSnap write FDirectionSnap;
    //** @abstract(Whether a sprite strip or spritesheet is saved with its metadata; False by
    //** default.)
    //**
    //** Stored as @code(exportMetadata); set by the Metadata box above Export. True writes,
    //** beside each strip or spritesheet, a JSON file of the same name with the extension
    //** .json, made by SaveSheetMetadata: the image's size and layout, where the centre of
    //** rotation falls in a frame, and each frame's transparent border. AniGifs and MP4 videos
    //** have none, and texture atlas pages always have it, whatever this says.
    property ExportMetadata: Boolean read FExportMetadata write FExportMetadata;
    //** @abstract(Whether exports are to be made for every direction of Models, Directions;
    //** False by default.)
    //**
    //** Stored as @code(exportDirections); set by the Directions box above Export. Ticked,
    //** each animation is exported once for each direction, in their order, and the
    //** metadata's @code(directions) lists their bearings; otherwise it is the single dummy
    //** entry 0.
    property ExportDirections: Boolean read FExportDirections write FExportDirections;
    //** @abstract(The largest a texture atlas page may be, in pixels each way;
    //** ATLAS_PAGE_SIZE_DEFAULT by default.)
    //**
    //** Stored as @code(atlasPageSize); set in Models, Animation Settings. A written value
    //** that is not one of ATLAS_PAGE_SIZES becomes the nearest that is.
    property AtlasPageSize: Integer read FAtlasPageSize write SetAtlasPageSize;
    //** @abstract(Whether a texture atlas page may be any size, rather than a power of 2 each
    //** way; False by default.)
    //**
    //** Stored as @code(atlasNonPowerOf2); set in Models, Animation Settings. False makes
    //** each page's width and height the smallest powers of 2 that hold its frames; True makes
    //** the page exactly as large as its grid of frames.
    property AtlasNonPowerOf2: Boolean read FAtlasNonPowerOf2 write FAtlasNonPowerOf2;
    //** @abstract(What Export saves, as the drop-down under the animation controls chose it;
    //** @code(strip) by default.)
    //**
    //** Stored as @code(exportKind): @code(strip), @code(sheet), @code(atlas), @code(gif) or
    //** @code(mp4). Anything else counts as @code(strip), and @code(mp4) while the video
    //** libraries have not loaded is shown as @code(strip) until they do.
    property ExportKind: String read FExportKind write FExportKind;
    //** @abstract(The folder the last texture atlas was exported to; empty until there has
    //** been one.)
    //**
    //** Stored as @code(atlasFolder). Export always asks for a folder; for a texture atlas
    //** the folder dialog opens here, if the folder is still there.
    property AtlasFolder: String read FAtlasFolder write FAtlasFolder;
    //** @abstract(Whether the export progress dialog closes by itself when an export ends
    //** without problems; False by default.)
    //**
    //** Stored as @code(exportAutoClose); set by Autoclose when done in that dialog.
    property ExportAutoClose: Boolean read FExportAutoClose write FExportAutoClose;
    //** @abstract(The folder the last export went to, from Export or the right-click menu;
    //** empty until there has been one.)
    //**
    //** Stored as @code(lastExportFolder). Every export's folder dialog opens here, as does
    //** the Results tab's Select Folder, and the Results tab reads it when it first shows.
    property LastExportFolder: String read FLastExportFolder write FLastExportFolder;
    //** @abstract(The folder File, Open Directory last searched; empty until it has been
    //** used.)
    //**
    //** Stored as @code(openDirectoryFolder). Its dialog opens showing this folder.
    property OpenDirectoryFolder: String read FOpenDirectoryFolder write FOpenDirectoryFolder;
    //** @abstract(The file spec File, Open Directory last searched for; @code(*.glb) by
    //** default.)
    //**
    //** Stored as @code(openDirectorySpec). One or more patterns, such as @code(*.glb) or
    //** @code(*.glb;*.gltf); see SplitFileSpec in Sprite3DFileSearch.
    property OpenDirectorySpec: String read FOpenDirectorySpec write FOpenDirectorySpec;
    //** @abstract(Whether ticking Overscan in Models, Animation Settings first warns how
    //** much longer rendering takes; True by default.)
    //**
    //** Stored as @code(showOverscanWarning). Cleared by ticking Do not show this again in
    //** that warning.
    property ShowOverscanWarning: Boolean read FShowOverscanWarning
      write FShowOverscanWarning;
    //** @abstract(Whether ticking Exact, above Export, first says what it does and how much
    //** longer the first pass takes; True by default.)
    //**
    //** Stored as @code(showExactWarning). Cleared by ticking Do not show this again in that
    //** warning.
    property ShowExactWarning: Boolean read FShowExactWarning write FShowExactWarning;
    //** @abstract(Whether the Results tab draws its checker behind the animation; True by
    //** default.)
    //**
    //** Stored as @code(resultsShowGrid); set by Show grid on the Results tab.
    property ResultsShowGrid: Boolean read FResultsShowGrid write FResultsShowGrid;
    //** @abstract(Whether the Results tab's empty border values have a hint explaining them;
    //** True by default.)
    //**
    //** Stored as @code(resultsEdgeHint); set in File, Settings.
    property ResultsEdgeHint: Boolean read FResultsEdgeHint write FResultsEdgeHint;
    //** @abstract(The zoom last chosen on the Results tab, as a multiple of the sprite size;
    //** 1 by default.)
    //**
    //** Stored as @code(resultsZoom). When it is shown again it is limited to what fits the
    //** drawing area then, the slider brought down to match.
    property ResultsZoom: Single read FResultsZoom write FResultsZoom;
    //** @abstract(Whether the debugging aids are offered; False by default.)
    //**
    //** Stored as @code(debug_enabled). Only set to True by editing settings.json by hand;
    //** File, Debug, Disable Debug sets it back to False. True adds File, Debug to the menu
    //** and says so in the Debug tab at startup.
    [NeonProperty('debug_enabled')]
    property DebugEnabled: Boolean read FDebugEnabled write FDebugEnabled;
    //** @abstract(Whether every exported frame gets a 1-pixel black border; False by default.)
    //**
    //** Stored as @code(debug_frame_borders); set by File, Debug, Frame Borders, which is
    //** offered only while DebugActive. Has no effect while DebugActive is False. The border
    //** is drawn on the saved images only: the metadata is measured from the frames as
    //** rendered.
    [NeonProperty('debug_frame_borders')]
    property DebugFrameBorders: Boolean read FDebugFrameBorders write FDebugFrameBorders;
    //** @abstract(Whether an export with overscan saves its first frame, as drawn before it
    //** is scaled down, as Oversampled.png; False by default.)
    //**
    //** Stored as @code(debug_save_oversampled); set by File, Debug, Save Oversampled Frame,
    //** which is offered only while DebugActive. Has no effect while DebugActive is False, or
    //** while overscan is off. The file goes in the export's folder.
    [NeonProperty('debug_save_oversampled')]
    property DebugSaveOversampled: Boolean read FDebugSaveOversampled
      write FDebugSaveOversampled;
    //** @abstract(The overscan factor Models, Animation Settings was last left at;
    //** OVERSCAN_FACTOR_DEFAULT by default.)
    //**
    //** Only the factor is kept: whether overscan is on is not, and it starts off each session,
    //** until ticked in Models, Animation Settings. Stored as @code(overscan). Written
    //** values are limited to OVERSCAN_FACTOR_MIN to OVERSCAN_FACTOR_MAX; a grab may use less,
    //** if the GPU cannot draw that much larger.
    property Overscan: Integer read FOverscan write SetOverscan;
    //** @abstract(The filter overscanned grabs are scaled down with; Box by default.)
    //**
    //** Chosen in Models, Animation Settings. Stored as @code(resampleFilter).
    property ResampleFilter: TSprite3DResampleFilter read FResampleFilter
      write FResampleFilter;
    //** @abstract(Padding: the empty border, in pixels, every export aims to leave round the
    //** sprite on the axis with least room; 0 by default.)
    //**
    //** Set in Models, Animation Settings. Stored as @code(padding). Written values below 0
    //** count as 0; an export uses at most PaddingLimit of the grab size, so a value kept for
    //** a larger grab size is cut down rather than lost.
    [NeonProperty('padding')]
    property Padding: Integer read FPadding write SetPadding;
  end;

//** @abstract(The most padding Models, Animation Settings allows for a grab size: a
//** quarter of its smaller side, in whole pixels.)
//**
//** Padding is the empty border, in pixels, an export aims to leave round the sprite on the
//** axis with least room. A quarter each side leaves half the frame for the sprite.
//**
//** @param(AGrabWidth The grab's width in pixels.)
//**
//** @param(AGrabHeight The grab's height in pixels.)
//**
//** @returns(The largest padding allowed, 0 or more.)
function PaddingLimit(const AGrabWidth, AGrabHeight: Integer): Integer;

//** @abstract(Shifts an angle in degrees by whole turns into the range 0 to 360.)
//**
//** @param(ADegrees Any angle in degrees, negative or past a full turn.)
//**
//** @returns(The same direction as an angle from 0 up to, but not including, 360.)
function Wrap360(const ADegrees: Single): Single;

//** @abstract(The entry of DIRECTION_COUNTS nearest to a number, the smaller of two as near.)
//**
//** @param(ACount Any number.)
//**
//** @returns(One of DIRECTION_COUNTS.)
function NearestDirectionCount(const ACount: Integer): Integer;

//** @abstract(The abbreviated name of a point of the 32-point compass, if a bearing is on
//** one.)
//**
//** The points are 11.25 degrees apart, named as the mariner's compass names them: the
//** cardinal points N, E, S and W; the intercardinal NE, SE, SW and NW; the eight winds
//** between them, NNE, ENE and so on; and the sixteen "by" points, NbE (north by east),
//** NEbN and so on.
//**
//** @param(ADegrees A bearing in degrees clockwise from north, any number of turns.)
//**
//** @returns(The point's abbreviation, such as N, NbE, NNE or NEbN, for a bearing within a
//** hundredth of a degree of one; otherwise an empty string, so a whole-degree bearing only
//** has a name on the eight points that fall on whole degrees.)
function CompassPointName(const ADegrees: Single): String;

//** @abstract(The plain order of ACount directions: clockwise from position 0, or
//** anticlockwise.)
//**
//** @param(ACount How many directions; values below 1 give an empty order.)
//**
//** @param(AClockwise True for 0, 1, 2 and so on; False for 0, ACount - 1, ACount - 2 and so
//** on.)
//**
//** @returns(ACount positions, every one from 0 to ACount - 1 once.)
function PlainDirectionOrder(const ACount: Integer; const AClockwise: Boolean): TArray<Integer>;

//** @abstract(Whether an order holds every position from 0 to ACount - 1 exactly once.)
//**
//** @param(AOrder The order, as positions from 0.)
//**
//** @param(ACount How many directions there are.)
//**
//** @returns(True if AOrder has ACount entries and each position once.)
function IsDirectionOrder(const AOrder: TArray<Integer>; const ACount: Integer): Boolean;

//** @abstract(An order as the text DirectionOrder keeps: positions from 1, separated by
//** commas.)
//**
//** @param(AOrder The order, as positions from 0.)
//**
//** @returns(The text, such as @code('3,5,7,1,4,6,8,2'); empty for an empty order.)
function DirectionOrderToText(const AOrder: TArray<Integer>): String;

//** @abstract(Reads the text DirectionOrder keeps back into an order.)
//**
//** @param(AText Positions from 1, separated by commas; spaces are ignored.)
//**
//** @returns(The positions from 0, in order; an entry that is not a number gives -1, which
//** IsDirectionOrder rejects.)
function DirectionOrderFromText(const AText: String): TArray<Integer>;

//** @abstract(Writes a set of directions to a JSON file, for Models, Directions' Export.)
//**
//** The file holds everything Models, Directions sets, so it can be read back with
//** LoadDirectionsFile, kept beside artwork whose directions come in a fixed order, and
//** swapped between models:
//**
//** @preformatted(
//** {
//**   "format": "Sprite3D directions",
//**   "version": 1,
//**   "count": 8,
//**   "start": 0,
//**   "snap": false,
//**   "clockwise": true,
//**   "order": [3, 5, 7, 1, 4, 6, 8, 2],
//**   "directions": [
//**     { "number": 1, "position": 3, "bearing": 90, "point": "E" },
//**     ...
//**   ]
//** }
//** )
//**
//** @code(order) holds the positions, counted clockwise from 1 at the red marker, in the
//** order the directions are taken in, as DirectionOrder does. @code(directions) spells
//** each one out, with its bearing and compass point, for people and other tools to read;
//** LoadDirectionsFile ignores it. The folder is made if it does not exist.
//**
//** @param(AFileName The file to write; replaced if it exists.)
//**
//** @param(ACount How many directions; one of DIRECTION_COUNTS.)
//**
//** @param(AStart The red marker's bearing, in degrees clockwise from north.)
//**
//** @param(AOrder The order, as positions from 0; one that does not fit ACount is written
//** as the plain clockwise order.)
//**
//** @param(ASnap Whether the dial is locked to steps of one direction.)
//**
//** @raises(EInOutError or another file exception if the file cannot be written.)
procedure SaveDirectionsFile(const AFileName: String; const ACount: Integer;
  const AStart: Single; const AOrder: TArray<Integer>; const ASnap: Boolean);

//** @abstract(Reads a set of directions from a JSON file written by SaveDirectionsFile.)
//**
//** @code(count) and @code(start) are needed. @code(order) may be left out, when
//** @code(clockwise), true if it too is left out, gives the plain order; @code(snap) may
//** be left out, for False. @code(format), when present, must be DIRECTIONS_FILE_FORMAT,
//** and @code(version), when present, no newer than DIRECTIONS_FILE_VERSION. Anything
//** else in the file is ignored.
//**
//** @param(AFileName The file to read.)
//**
//** @param(ACount Set to the number of directions, one of DIRECTION_COUNTS.)
//**
//** @param(AStart Set to the red marker's bearing, wrapped into 0 up to 360.)
//**
//** @param(AOrder Set to the order, as positions from 0, every one once.)
//**
//** @param(ASnap Set to whether the dial is locked to steps of one direction.)
//**
//** @raises(EDirectionsFile if the file is not JSON, is not a directions file, or holds a
//** count or order that cannot be used; the message says which, for showing as it is.)
//**
//** @raises(EFileNotFoundException or another file exception if the file cannot be read.)
procedure LoadDirectionsFile(const AFileName: String; out ACount: Integer;
  out AStart: Single; out AOrder: TArray<Integer>; out ASnap: Boolean);

//** @abstract(A set of directions as the JSON object SaveDirectionsFile writes.)
//**
//** For keeping directions inside another JSON file, such as a project file. The caller
//** owns the object.
//**
//** @param(ACount How many directions; one of DIRECTION_COUNTS.)
//**
//** @param(AStart The red marker's bearing, in degrees clockwise from north.)
//**
//** @param(AOrder The order, as positions from 0; one that does not fit ACount is written
//** as the plain clockwise order.)
//**
//** @param(ASnap Whether the dial is locked to steps of one direction.)
//**
//** @returns(The object, with every member SaveDirectionsFile writes.)
function DirectionsToJson(const ACount: Integer; const AStart: Single;
  const AOrder: TArray<Integer>; const ASnap: Boolean): TJSONObject;

//** @abstract(Reads a set of directions from a JSON object, as LoadDirectionsFile reads a
//** file.)
//**
//** @param(AValue The object, such as one DirectionsToJson made.)
//**
//** @param(ACount Set to the number of directions, one of DIRECTION_COUNTS.)
//**
//** @param(AStart Set to the red marker's bearing, wrapped into 0 up to 360.)
//**
//** @param(AOrder Set to the order, as positions from 0, every one once.)
//**
//** @param(ASnap Set to whether the dial is locked to steps of one direction.)
//**
//** @raises(EDirectionsFile If AValue is not an object of directions, or holds a count or
//** order that cannot be used; the message says which.)
procedure DirectionsFromJson(const AValue: TJSONValue; out ACount: Integer;
  out AStart: Single; out AOrder: TArray<Integer>; out ASnap: Boolean);

//** @abstract(Whether a file is a Sprite3D project file, judged by its extension,
//** PROJECT_FILE_EXTENSION.)
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True if its extension is PROJECT_FILE_EXTENSION, in any case.)
function IsProjectFile(const AFileName: String): Boolean;

//** @abstract(Credits as the @code(credits) object of a project file.)
//**
//** Members are @code(creator), @code(creator_url), @code(modeller), @code(modeller_url),
//** @code(artist), @code(artist_url) and @code(created); empty ones are written as
//** @code(null). The caller owns the object.
//**
//** @param(ACredits The credits.)
//**
//** @returns(The object.)
function CreditsToJson(const ACredits: TSprite3DCredits): TJSONObject;

//** @abstract(Reads credits from the @code(credits) object of a project file.)
//**
//** Members left out, @code(null) or not text are read as empty.
//**
//** @param(AValue The object; anything else gives empty credits.)
//**
//** @returns(The credits.)
function CreditsFromJson(const AValue: TJSONValue): TSprite3DCredits;

//** @abstract(Formats an angle from Wrap360 as whole degrees for a readout.)
//**
//** Rounds to the nearest degree, so 359.6 shows as 0, never 360, and pads to three
//** characters so readouts stay the same width.
//**
//** @param(ADegrees An angle from 0 up to 360.)
//**
//** @returns(The angle as text, such as @code('  0') or @code(' 45').)
function DegreesText(const ADegrees: Single): String;

//** @abstract(The folder that holds the application's models folder, for this platform.)
//**
//** The library path on macOS, the home folder on Linux and @code('../../../') elsewhere;
//** on Windows it is the current folder instead, returned as an empty string, if that has a
//** models subfolder.
//**
//** @returns(A folder path ending in a path delimiter, or empty for the current folder.)
function DefaultModelDir: String;

//** @abstract(The folder grabs are saved in without asking, or empty where the user should
//** choose.)
//**
//** Android and iOS have no folder dialog, so there grabs go to a fixed Grabs folder the
//** user can reach: under the app's public storage on Android, which shows over USB or in a
//** file manager, and under its Documents folder on iOS, which shows in the Files app once
//** the app enables file sharing in its Info.plist. Elsewhere this returns an empty string.
//**
//** @returns(The fixed grab folder on Android and iOS; an empty string on other platforms.)
function DefaultGrabFolder: String;

//** @abstract(Where downloaded copies of OpenH264 are kept: an @code(openh264) folder in
//** SupportFolder.)
//**
//** Per user and private to the application on every platform; created when the first copy
//** is saved.
//**
//** @returns(The folder's full path.)
function OpenH264Folder: String;

//** @abstract(The first free numbered file name in a folder, such as grab001.png.)
//**
//** Starts at ANumber and moves it past every name already taken, so an existing file is
//** never chosen. Numbers have at least three digits. The file is not created.
//**
//** @param(AFolder The folder to look in.)
//**
//** @param(APrefix The start of the file name, such as @code('grab').)
//**
//** @param(AExtension The extension, with its dot, such as @code('.png').)
//**
//** @param(ANumber The number to try first; on return, the number of the name returned.)
//**
//** @returns(The full path of the first name that does not exist yet.)
function NextNumberedFileName(const AFolder, APrefix, AExtension: String;
  var ANumber: Integer): String;

//** @abstract(Saves a grab as the next free grabNNN.png in a folder.)
//**
//** Creates the folder if needed, picks the name with NextNumberedFileName starting at
//** ANumber, saves ABitmap there as PNG and moves ANumber on to the next number. Blocks
//** while the file is written.
//**
//** @param(ABitmap The image to save; it is not freed.)
//**
//** @param(AFolder The folder to save in.)
//**
//** @param(ANumber The number to try first; on return, one past the number used. Unchanged
//** if the save fails.)
//**
//** @returns(The full path of the file written.)
//**
//** @raises(Exception If the folder cannot be created or the file cannot be written; the
//** class depends on the cause.)
function SaveGrab(const ABitmap: TBitmap; const AFolder: String;
  var ANumber: Integer): String;

//** @abstract(Replaces a model's contents with a model file and starts its last animation.)
//**
//** Clears AModel, loads AFileName into it, and, if the file has animations, plays the one
//** whose name sorts last. Blocks while the file loads.
//**
//** @param(AModel The model to load into; its old contents are removed first.)
//**
//** @param(AFileName A glTF, FBX, OBJ, USD, Collada, STL or PLY file.)
//**
//** @param(ABox The model's bounding box straight after loading, before anything is added
//** to it or it is moved; pass it to PlaceModel.)
//**
//** @returns(The names of the model's animations in sorted order; empty if it has none.)
//**
//** @raises(Exception If the file cannot be read or loaded; AModel is then left cleared or
//** part-loaded.)
function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox): TArray<String>;

//** @abstract(Centres a loaded model on its bounding box and turns it right way up.)
//**
//** Moves AModel to the centre of ABox and turns it 180 degrees about X, which the
//** application's models need to stand upright.
//**
//** @param(AModel The model to place.)
//**
//** @param(ABox The box LoadModelFile returned for it.)
procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);

//** @abstract(A slot holding no model: Model nil, every other field empty or zero.)
//**
//** Use this rather than @code(Default(TSprite3DModelSlot)): where Gorilla.DefTypes is in
//** scope, @code(Default) names its TGorillaOAuthMode value instead of the intrinsic.
//**
//** @returns(The empty slot.)
function EmptyModelSlot: TSprite3DModelSlot;

//** @abstract(A slot for a model just loaded, with every animation used.)
//**
//** IsAnimated is set from ANames: True if the model has any animation. Name is the file's
//** name without its extension.
//**
//** @param(AModel The model, loaded with LoadModelFile and placed with PlaceModel.)
//**
//** @param(AFileName The file it was loaded from, expanded.)
//**
//** @param(ABox The box LoadModelFile returned for it.)
//**
//** @param(ABounds Each animation's bounds, measured or from the bounds cache; empty for a
//** model without animations.)
//**
//** @param(ANames The names LoadModelFile returned: its animations, empty if it has none.)
//**
//** @returns(The slot; it does not own the model until FreeModelSlot is called on it.)
function NewModelSlot(const AModel: TGorillaModel; const AFileName: String;
  const ABox: TBoundingBox; const ABounds: TArray<TAnimationBounds>;
  const ANames: TArray<String>): TSprite3DModelSlot;

//** @abstract(Which of ASlots was loaded from AFileName.)
//**
//** Names are compared expanded, in this platform's form, as the platform compares them.
//**
//** @param(ASlots The slots to look in.)
//**
//** @param(AFileName A model file.)
//**
//** @returns(The index of the first slot loaded from that file, or -1 if there is none.)
function ModelSlotIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AFileName: String): Integer;

//** @abstract(Which of ASlots is listed as AName.)
//**
//** @param(ASlots The slots to look in.)
//**
//** @param(AName A name as a slot's Name gives it; compared ignoring case, as files that
//** differ only in case would clash on Windows and macOS when exported.)
//**
//** @returns(The index of the first slot with that name, or -1 if there is none.)
function ModelSlotNameIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AName: String): Integer;

//** @abstract(A name based on AName that no slot of ASlots has: AName itself if it is free,
//** otherwise @code(AName (2)), @code(AName (3)) and so on, the first that is free.)
//**
//** @param(AName The name wanted.)
//**
//** @param(ASlots The slots whose names are taken.)
//**
//** @returns(The free name.)
function UniqueModelName(const AName: String; const ASlots: TArray<TSprite3DModelSlot>): String;

//** @abstract(The file spec of every model format LoadModelFile loads.)
//**
//** @returns(@code(*.glb;*.gltf;*.fbx;*.obj;*.usdc;*.dae;*.stl;*.ply), from the same list
//** IsModelFile uses.)
function AllModelsFileSpec: String;

//** @abstract(Frees a slot's model, with its helpers, and empties the slot.)
//**
//** The model's axes, grid, swept volumes and bounds outline are its own components, so go
//** with it. Afterwards ASlot is EmptyModelSlot. The caller must first
//** stop using the model, if it is the one shown.
//**
//** @param(ASlot The slot whose model goes; nothing is freed if its Model is nil.)
procedure FreeModelSlot(var ASlot: TSprite3DModelSlot);

//** @abstract(Shows or hides a model together with what is drawn beside it.)
//**
//** Its axes and grid, from Sprite3DAxes and Sprite3DGrid, and its swept volumes, from
//** Sprite3DSweep, are drawn in the model's parent rather than as its children, so they do
//** not follow the model's Visible: each is shown or hidden here with it. The bounds outline
//** checks the model's Visible itself.
//**
//** @param(AModel The model; nothing happens if it is nil.)
//**
//** @param(AShown True to show it, False to hide it.)
procedure ShowModelWithHelpers(const AModel: TGorillaModel; const AShown: Boolean);

//** @abstract(Whether a file is a model LoadModelFile can load, judged by its extension.)
//**
//** The extensions are those of the loaders this unit registers: .glb, .gltf, .fbx, .obj,
//** .usdc, .dae, .stl and .ply, in any case. The file's contents are not checked.
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True if its extension is one of the model formats.)
function IsModelFile(const AFileName: String): Boolean;

//** @abstract(The model to load at start-up: the first one the system asked to open, or
//** ADefault.)
//**
//** @param(ARequested The files the operating system asked the application to open, oldest
//** first, as Sprite3DOpenFiles collects them; files that are not models are skipped.)
//**
//** @param(ADefault The model to load when none was asked for.)
//**
//** @returns(The first model in ARequested, or ADefault if it holds none.)
function StartupModelFile(const ARequested: TArray<String>;
  const ADefault: String): String;

type
  //** @abstract(A read of a model file on a worker thread, from StartModelFileRead.)
  //**
  //** Every member may be called from the main thread while the read goes on. The worker holds
  //** its own reference, so letting go of this one, or cancelling, never leaves it reading
  //** freed memory.
  IModelFileRead = interface
    ['{3E8B6A51-2C4D-4F7A-9E1B-5D7C8A9F0B24}']
    //** @abstract(Asks the worker to stop at the next block; Done follows soon after.)
    procedure Cancel;
    //** @abstract(True once the worker has stopped: read to the end, cancelled, or failed.)
    //**
    //** @returns(Whether the read is over.)
    function Done: Boolean;
    //** @abstract(How many bytes have been read so far.)
    //**
    //** @returns(The count, from 0 to TotalBytes.)
    function BytesRead: Int64;
    //** @abstract(The file's size in bytes; 0 until the file has been opened.)
    //**
    //** @returns(The size.)
    function TotalBytes: Int64;
    //** @abstract(Why the read failed, once Done; empty if it did not.)
    //**
    //** @returns(The error message, or an empty string.)
    function Error: String;
  end;

//** @abstract(Starts reading a model file from start to end on a worker thread.)
//**
//** Nothing is kept: the point is to bring the file into the operating system's file cache,
//** which is where a cold load spends most of its time, while the user interface goes on and
//** the read can be cancelled; Gorilla3D's own load, which cannot, then finds it there. The
//** file is read in blocks of a megabyte, shared for reading and writing.
//**
//** @param(AFileName The file to read.)
//**
//** @returns(The read under way.)
function StartModelFileRead(const AFileName: String): IModelFileRead;

//** @abstract(Where the measured animation bounds of a model file are kept between
//** sessions.)
//**
//** A file in the bounds folder of SupportFolder, named from a hash of the model's full path,
//** size and time of last change, so a model that is changed or replaced gets a new file
//** and its old figures are never used. Nothing is created.
//**
//** @param(AModelFile The model file; it must exist.)
//**
//** @returns(The cache file's path, or empty if the model file cannot be found.)
function AnimationBoundsCacheFile(const AModelFile: String): String;

//** @abstract(Reads the animation bounds saved for a model file, so they need not be measured
//** again.)
//**
//** The figures are used only if they were saved for exactly the animations named, in any
//** order, and by this version of the cache; anything else, a damaged file included, gives
//** False and leaves the model to be measured.
//**
//** @param(AModelFile The model file, as loaded.)
//**
//** @param(ANames Every animation the model has, as LoadModelFile listed them.)
//**
//** @param(ABounds The figures, in the order they were saved; empty when False, and without
//** any animation that had no pose to measure.)
//**
//** @returns(True if usable figures were read.)
function LoadAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  out ABounds: TArray<TAnimationBounds>): Boolean;

//** @abstract(Saves a model file's measured animation bounds for the next time it is
//** loaded.)
//**
//** Writes AnimationBoundsCacheFile as JSON, making the folder if need be. A failure to write
//** is ignored: the model is simply measured again next time.
//**
//** @param(AModelFile The model file the figures were measured from.)
//**
//** @param(ANames Every animation the model has, as LoadModelFile listed them.)
//**
//** @param(ABounds The figures, as TAnimationBoundsMeasurer gave them.)
procedure SaveAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  const ABounds: TArray<TAnimationBounds>);

//** @abstract(The file an icon is saved to without asking, or empty where the user should
//** choose.)
//**
//** Android and iOS have no save dialog, so there icons go to the next free
//** @code(iconNNN) name, with AExtension, in DefaultGrabFolder. Elsewhere this returns an
//** empty string, and the user picks the file.
//**
//** @param(AExtension The icon format's extension, with its dot, such as @code('.ico').)
//**
//** @returns(The full path on Android and iOS; an empty string on other platforms.)
function AutoIconFileName(const AExtension: String): String;

//** @abstract(How far to move the orbit centre for a camera pan.)
//**
//** The pan runs along the model's own X and Z axes, as View, Show axes draws them, so it
//** never moves the view up or down the model's Y axis. Each amount is a multiple of the
//** model's radius, half the diagonal of ABox, so a pan looks the same for a model of any
//** size. The camera's angles and distance are not involved.
//**
//** @param(AModel The model; nil gives no offset.)
//**
//** @param(ABox The model's own bounds as loaded, for its size.)
//**
//** @param(APanX The pan along the model's X axis; limited to PAN_LIMIT either way.)
//**
//** @param(APanZ The pan along the model's Z axis; limited to PAN_LIMIT either way.)
//**
//** @returns(The offset to add to the fitted orbit centre, in the viewport's space.)
function ModelPanOffset(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const APanX, APanZ: Single): TPoint3D;

//** @abstract(Gives the whole application, title bars included, the look ATheme names.)
//**
//** thDefault puts back FMX's own platform style and the system's title bars. The other
//** themes are the FMX styles that come with RAD Studio: Dark.style, AquaGraphite.style,
//** RubyGraphite.style and GoldenGraphite.style. Each is looked for as a linked-in RCDATA
//** resource called @code(Sprite3D<Name>Style), such as @code(Sprite3DDarkStyle), which
//** @code(styles\Sprite3DThemes.rc) links into every build, then, should that be missing, as a
//** file in a @code(styles) folder beside the program or its assets, beside the program,
//** in a @code(styles) folder in SupportFolder, or, on Windows, in RAD Studio's
//** @code(Redist\styles\Fmx) folder when the BDS environment variable is set, as it is when
//** run from the IDE. Once the style is in use, the title bars take its form background
//** colour, with the theme's accent as the window border, where the system allows; see
//** Sprite3DTitleBar.
//**
//** @param(ATheme The look to use.)
//**
//** @param(AError On failure, why, including where it looked.)
//**
//** @returns(True if the look is now in use; False leaves the current one, title bars
//** included.)
function ApplyTheme(const ATheme: TSprite3DTheme; out AError: String): Boolean;

//** @abstract(A new TSprite3DFileAssociations for the model files this application opens.)
//**
//** The caller owns the result and frees it.
//**
//** @returns(The associations object, set up for every extension IsModelFile accepts.)
function CreateModelAssociations: TSprite3DFileAssociations;

//** @abstract(Registers or unregisters the application for model files as asked, keeping
//** what is needed to undo it in ASettings.)
//**
//** In order: registers for Open With if AOpenWith; makes the application the default if
//** AAlways, recording the old defaults in ASettings.AssociationBackup, or otherwise puts
//** back the recorded defaults if it was the default; and unregisters if not AOpenWith.
//** AAlways counts only with AOpenWith, except on macOS, where Open With is fixed by the
//** bundle. Where the user has to confirm a default in the system's own settings, that page
//** is opened and AMessage says so. ASettings.OpenWith and AlwaysOpenWith are updated to
//** the result; the caller saves ASettings.
//**
//** @param(ASettings The application's settings, for the backup.)
//**
//** @param(AOpenWith Whether to be offered under Open With.)
//**
//** @param(AAlways Whether to be the default for model files.)
//**
//** @param(AMessage Anything the user should be told, failures included; empty if
//** nothing.)
//**
//** @returns(True if every step succeeded.)
function ApplyFileAssociations(const ASettings: TSprite3DAppSettings;
  const AOpenWith, AAlways: Boolean; out AMessage: String): Boolean;

//** @abstract(Makes Sprite3D open its own project files, PROJECT_FILE_EXTENSION, when one is
//** double-clicked.)
//**
//** Called each time the application starts, so the files open with the copy of the
//** program last run, whatever is chosen for model files in File, Settings. On Windows the
//** extension gets a ProgID of its own, @code(Sprite3D.Project), and is made to open with it;
//** a choice made with Always in Windows' own How do you want to open dialog still wins. On
//** Linux the project MIME type, @code(application/x-sprite3d), goes into the application's
//** desktop entry, with the model types if they are registered, and is made to open with it.
//** On macOS the bundle's document types do this, and elsewhere there are no associations,
//** so it does nothing.
//**
//** @param(AMessage Set to what went wrong; empty if nothing did.)
//**
//** @returns(True on success, or where there is nothing to do.)
function RegisterProjectFiles(out AMessage: String): Boolean;

//** @abstract(True where the GPU preference can be set: Windows only.)
//**
//** @returns(True on Windows.)
function GpuModeSupported: Boolean;

//** @abstract(The GPU preference Windows has for this program file now.)
//**
//** @returns(The preference, or gmSystem where there is none or the platform has none.)
function ReadGpuMode: TSprite3DGpuMode;

//** @abstract(Asks Windows for a GPU for this program file, from the next start.)
//**
//** gmSystem removes the program's entry, handing the choice back to Windows. Uses
//** GpuPreference.SetGpuPreference.
//**
//** @param(AMode The preference.)
//**
//** @returns(True if it was stored; always False where GpuModeSupported is False.)
function WriteGpuMode(const AMode: TSprite3DGpuMode): Boolean;

//** @abstract(The File, Settings choices as they stand now.)
//**
//** Open With, the default application and the GPU preference are read from the system,
//** where it can say; the rest come from ASettings.
//**
//** @param(ASettings The application's settings.)
//**
//** @returns(The choices.)
function ReadGeneralSettings(const ASettings: TSprite3DAppSettings): TSprite3DGeneralSettings;

implementation

uses
  System.Classes, System.Math, System.IOUtils, System.Hash, System.StrUtils,
  System.Threading, System.SyncObjs, System.Generics.Collections,
  OSPaths, JsonText, Sprite3DStyles, Sprite3DTitleBar, Sprite3DAxes, Sprite3DGrid,
  {$IF DEFINED(MSWINDOWS)}
  GpuPreference,
  {$ENDIF}
  Gorilla.DefTypes,
  Gorilla.Animation,
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.OBJ.Loader,
//  Gorilla.USD.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader;

const
  // The turn every loaded model is given so that it stands upright
  MODEL_ROTATION: TPoint3D = (X: 180; Y: 0; Z: 0);

{ TSprite3DAppSettings }

constructor TSprite3DAppSettings.Create;
begin
  inherited Create(TPath.Combine(SupportFolder, SETTINGS_FILE_NAME));
  FSaveFolder := String.Empty;
  FIconFolder := String.Empty;
  FDirectionsFolder := String.Empty;
  SetBackgroundSpec(TSprite3DBackgroundSpec.Default);
  // As the main form's check boxes start; a settings.json without these
  // keys leaves them so
  FShowBoundingBox := True;
  FShowGrid := True;
  FShowAxes := True;
  FShowSweptVolume := True;
  FShowCombinedSweptVolume := False;
  FOrthographic := False;
  // The main form's view as it starts
  FCameraView := 'Isometric';
  FVariableAzimuth := 0;
  FVariableInclination := 0;
  FVariableRoll := 0;
  // Panning is rare: off, and centred, until chosen
  FPanEnabled := False;
  FPanX := 0;
  FPanZ := 0;
  // File, Settings: as the application behaved before it had them
  FStartupAction := saDefaultModel;
  FLastModel := String.Empty;
  FLastAnimatedModel := String.Empty;
  FLastStaticModel := String.Empty;
  SetThemeKind(thDefault);
  FGpuMode := gmSystem;
  FOpenWith := False;
  FAlwaysOpenWith := False;
  FAssociationBackup := String.Empty;
  FGrabWidth := GRAB_SIZE_DEFAULT;
  FGrabHeight := GRAB_SIZE_DEFAULT;
  FAnimationFps := ANIMATION_FPS_DEFAULT;
  FViewFps := VIEW_FPS_DEFAULT;
  SetMinifyJson(False);
  FDirectionCount := DIRECTION_COUNT_DEFAULT;
  FDirectionStart := 0;
  FDirectionClockwise := True;
  FDirectionOrder := String.Empty;
  FDirectionSnap := False;
  FExportMetadata := False;
  FExportDirections := False;
  FAtlasPageSize := ATLAS_PAGE_SIZE_DEFAULT;
  FAtlasNonPowerOf2 := False;
  FExportKind := 'strip';
  FAtlasFolder := String.Empty;
  FDebugEnabled := False;
  FDebugFrameBorders := False;
  FDebugSaveOversampled := False;
  FExportAutoClose := False;
  FLastExportFolder := String.Empty;
  FOpenDirectoryFolder := String.Empty;
  FOpenDirectorySpec := '*.glb';
  FShowOverscanWarning := True;
  FShowExactWarning := True;
  FResultsShowGrid := True;
  FResultsEdgeHint := True;
  FResultsZoom := 1;
  FOverscan := OVERSCAN_FACTOR_DEFAULT;
  FPadding := 0;
  FResampleFilter := rfBox;
end;

procedure TSprite3DAppSettings.SetAnimationFps(const Value: Integer);
begin
  FAnimationFps := EnsureRange(Value, ANIMATION_FPS_MIN, ANIMATION_FPS_MAX);
end;

function TSprite3DAppSettings.DirectionOrderList: TArray<Integer>;
begin
  Result := DirectionOrderFromText(FDirectionOrder);
  if not IsDirectionOrder(Result, FDirectionCount) then
    Result := PlainDirectionOrder(FDirectionCount, FDirectionClockwise);
end;

function TSprite3DAppSettings.DirectionBearings: TArray<Single>;
var
  Order: TArray<Integer>;
begin
  Order := DirectionOrderList;
  SetLength(Result, Length(Order));
  for var I := 0 to High(Order) do
    Result[I] := Wrap360(FDirectionStart + Order[I] * 360 / FDirectionCount);
end;

procedure TSprite3DAppSettings.SetDirectionCount(const Value: Integer);
begin
  FDirectionCount := NearestDirectionCount(Value);
end;

procedure TSprite3DAppSettings.SetDirectionStart(const Value: Single);
begin
  FDirectionStart := Wrap360(Value);
end;

procedure TSprite3DAppSettings.SetViewFps(const Value: Integer);
begin
  FViewFps := EnsureRange(Value, VIEW_FPS_MIN, VIEW_FPS_MAX);
end;

procedure TSprite3DAppSettings.SetMinifyJson(const Value: Boolean);
begin
  FMinifyJson := Value;
  JsonText.MinifyJson := Value;   // every JSON file written from now on
end;

procedure TSprite3DAppSettings.SetOverscan(const Value: Integer);
begin
  FOverscan := EnsureRange(Value, OVERSCAN_FACTOR_MIN, OVERSCAN_FACTOR_MAX);
end;

procedure TSprite3DAppSettings.SetPadding(const Value: Integer);
begin
  FPadding := EnsureRange(Value, 0, PaddingLimit(GRAB_SIZE_MAX, GRAB_SIZE_MAX));
end;

procedure TSprite3DAppSettings.SetAtlasPageSize(const Value: Integer);
begin
  FAtlasPageSize := ATLAS_PAGE_SIZES[0];
  for var Size in ATLAS_PAGE_SIZES do
    if Abs(Size - Value) < Abs(FAtlasPageSize - Value) then
      FAtlasPageSize := Size;
end;

// Neon writes through the setters too, so a hand-edited settings.json can't
// ask for a size outside the limits
procedure TSprite3DAppSettings.SetGrabWidth(const Value: Integer);
begin
  FGrabWidth := EnsureRange(Value, GRAB_SIZE_MIN, GRAB_SIZE_MAX);
end;

procedure TSprite3DAppSettings.SetGrabHeight(const Value: Integer);
begin
  FGrabHeight := EnsureRange(Value, GRAB_SIZE_MIN, GRAB_SIZE_MAX);
end;

// A colour as #AARRGGBB, which people can read and edit in settings.json
function ColourToText(const AColour: TAlphaColor): String;
begin
  Result := '#' + IntToHex(Int64(AColour), 8);
end;

// #AARRGGBB, or #RRGGBB taken as opaque, back to a colour; ADefault if the
// text is anything else
function TextToColour(const AText: String; const ADefault: TAlphaColor): TAlphaColor;
var
  Hex: String;
  Value: Int64;
begin
  Hex := AText.Trim;
  if Hex.StartsWith('#') then
    Hex := Hex.Substring(1);
  if ((Length(Hex) <> 8) and (Length(Hex) <> 6)) or
    not TryStrToInt64('$' + Hex, Value) then
    Exit(ADefault);
  if Length(Hex) = 6 then
    Value := Value or $FF000000;
  Result := TAlphaColor(Value);
end;

function TSprite3DAppSettings.GetBackgroundSpec: TSprite3DBackgroundSpec;
var
  Defaults: TSprite3DBackgroundSpec;
begin
  Defaults := TSprite3DBackgroundSpec.Default;
  Result.Kind := FBackgroundKind;
  Result.Colour := TextToColour(FBackgroundColour, Defaults.Colour);
  Result.GradientFrom := TextToColour(FGradientFrom, Defaults.GradientFrom);
  Result.GradientTo := TextToColour(FGradientTo, Defaults.GradientTo);
  Result.GradientDirection := FGradientDirection;
  Result.CheckerSize := Max(FCheckerSize, 1);
  Result.CheckerLight := TextToColour(FCheckerLight, Defaults.CheckerLight);
  Result.CheckerDark := TextToColour(FCheckerDark, Defaults.CheckerDark);
end;

procedure TSprite3DAppSettings.SetBackgroundSpec(const Value: TSprite3DBackgroundSpec);
begin
  FBackgroundKind := Value.Kind;
  FBackgroundColour := ColourToText(Value.Colour);
  FGradientFrom := ColourToText(Value.GradientFrom);
  FGradientTo := ColourToText(Value.GradientTo);
  FGradientDirection := Value.GradientDirection;
  FCheckerSize := Max(Value.CheckerSize, 1);
  FCheckerLight := ColourToText(Value.CheckerLight);
  FCheckerDark := ColourToText(Value.CheckerDark);
end;

class function TSprite3DAppSettings.SupportFolder: String;
begin
  Result := OSFriendlyPath(AppDataFolder(APP_NAME));
end;

function TSprite3DAppSettings.HasSaveFolder: Boolean;
begin
  Result := (FSaveFolder <> String.Empty) and DirectoryExists(FSaveFolder);
end;

function NearestDirectionCount(const ACount: Integer): Integer;
begin
  Result := DIRECTION_COUNTS[0];
  for var Count in DIRECTION_COUNTS do
    if Abs(Count - ACount) < Abs(Result - ACount) then
      Result := Count;
end;

function PlainDirectionOrder(const ACount: Integer; const AClockwise: Boolean): TArray<Integer>;
begin
  Result := nil;
  if ACount < 1 then
    Exit;
  SetLength(Result, ACount);
  for var I := 0 to ACount - 1 do
    if AClockwise then
      Result[I] := I
    else
      Result[I] := (ACount - I) mod ACount;
end;

function IsDirectionOrder(const AOrder: TArray<Integer>; const ACount: Integer): Boolean;
var
  Seen: TArray<Boolean>;
begin
  Result := (ACount >= 1) and (Length(AOrder) = ACount);
  if not Result then
    Exit;
  SetLength(Seen, ACount);
  for var Position in AOrder do
  begin
    if (Position < 0) or (Position >= ACount) or Seen[Position] then
      Exit(False);
    Seen[Position] := True;
  end;
end;

function DirectionOrderToText(const AOrder: TArray<Integer>): String;
begin
  Result := String.Empty;
  for var I := 0 to High(AOrder) do
  begin
    if I > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(AOrder[I] + 1);
  end;
end;

function DirectionOrderFromText(const AText: String): TArray<Integer>;
begin
  Result := nil;
  if AText.Trim = String.Empty then
    Exit;
  for var Part in AText.Split([',']) do
    Result := Result + [StrToIntDef(Part.Trim, 0) - 1];
end;

function DirectionsToJson(const ACount: Integer; const AStart: Single;
  const AOrder: TArray<Integer>; const ASnap: Boolean): TJSONObject;
var
  Order: TArray<Integer>;
  Root, Item: TJSONObject;
  Positions, Items: TJSONArray;
  Count: Integer;
  Start, Bearing: Single;
begin
  Count := NearestDirectionCount(ACount);
  Start := Wrap360(AStart);
  Order := AOrder;
  if not IsDirectionOrder(Order, Count) then
    Order := PlainDirectionOrder(Count, True);
  Root := TJSONObject.Create;
  try
    Root.AddPair('format', DIRECTIONS_FILE_FORMAT);
    Root.AddPair('version', TJSONNumber.Create(DIRECTIONS_FILE_VERSION));
    Root.AddPair('count', TJSONNumber.Create(Count));
    Root.AddPair('start', TJSONNumber.Create(Start));
    Root.AddPair('snap', TJSONBool.Create(ASnap));
    Root.AddPair('clockwise', TJSONBool.Create((Count <= 2) or (DirectionOrderToText(Order) <>
      DirectionOrderToText(PlainDirectionOrder(Count, False)))));
    Positions := TJSONArray.Create;
    Root.AddPair('order', Positions);
    Items := TJSONArray.Create;
    Root.AddPair('directions', Items);
    for var I := 0 to High(Order) do
    begin
      Positions.Add(Order[I] + 1);
      Bearing := Wrap360(Start + Order[I] * 360 / Count);
      Item := TJSONObject.Create;
      Items.AddElement(Item);
      Item.AddPair('number', TJSONNumber.Create(I + 1));
      Item.AddPair('position', TJSONNumber.Create(Order[I] + 1));
      Item.AddPair('bearing', TJSONNumber.Create(Bearing));
      Item.AddPair('point', CompassPointName(Bearing));
    end;
  except
    Root.Free;
    raise;
  end;
  Result := Root;
end;

procedure SaveDirectionsFile(const AFileName: String; const ACount: Integer;
  const AStart: Single; const AOrder: TArray<Integer>; const ASnap: Boolean);
var
  FileName: String;
  Root: TJSONObject;
begin
  FileName := OSFriendlyPath(AFileName);
  Root := DirectionsToJson(ACount, AStart, AOrder, ASnap);
  try
    if ExtractFileDir(FileName) <> String.Empty then
      ForceDirectories(ExtractFileDir(FileName));
    // UTF-8 without a byte order mark, which some JSON readers reject
    TFile.WriteAllBytes(FileName, JsonToBytes(Root));
  finally
    Root.Free;
  end;
end;

procedure DirectionsFromJson(const AValue: TJSONValue; out ACount: Integer;
  out AStart: Single; out AOrder: TArray<Integer>; out ASnap: Boolean);
var
  Root: TJSONObject;
  Positions: TJSONArray;
  Text: String;
  Version, Count, Position: Integer;
  Start: Double;
  Clockwise, Snap, Known: Boolean;
begin
  if not (AValue is TJSONObject) then
    raise EDirectionsFile.Create('This is not a set of directions: it is not a JSON ' +
      'object.');
  Root := TJSONObject(AValue);
  if Root.TryGetValue<String>('format', Text) and (Text <> DIRECTIONS_FILE_FORMAT) then
    raise EDirectionsFile.CreateFmt('This file is not a directions file: its format is ' +
      '"%s".', [Text]);
  if Root.TryGetValue<Integer>('version', Version) and
    (Version > DIRECTIONS_FILE_VERSION) then
    raise EDirectionsFile.CreateFmt('This directions file is version %d, from a newer ' +
      'Sprite3D; this one reads up to version %d.', [Version, DIRECTIONS_FILE_VERSION]);
  if not Root.TryGetValue<Integer>('count', Count) then
    raise EDirectionsFile.Create('This directions file does not say how many directions ' +
      'there are ("count").');
  Known := False;
  for var Allowed in DIRECTION_COUNTS do
    Known := Known or (Allowed = Count);
  if not Known then
    raise EDirectionsFile.CreateFmt('This directions file has %d directions; the number ' +
      'must be 1, 2, or a multiple of 4 or 6 up to 64.', [Count]);
  if not Root.TryGetValue<Double>('start', Start) then
    raise EDirectionsFile.Create('This directions file does not say where the first ' +
      'position points ("start").');
  if not Root.TryGetValue<Boolean>('snap', Snap) then
    Snap := False;
  if not Root.TryGetValue<Boolean>('clockwise', Clockwise) then
    Clockwise := True;
  AOrder := nil;
  Positions := Root.GetValue('order') as TJSONArray;
  if Positions = nil then
    AOrder := PlainDirectionOrder(Count, Clockwise)
  else
  begin
    for var Item in Positions do
    begin
      if not ((Item is TJSONNumber) and TryStrToInt(Item.Value, Position)) then
        Position := 0;   // not a whole number: rejected below
      AOrder := AOrder + [Position - 1];
    end;
    if not IsDirectionOrder(AOrder, Count) then
      raise EDirectionsFile.CreateFmt('The order in this directions file ("order") must ' +
        'hold every position from 1 to %d exactly once.', [Count]);
  end;
  ACount := Count;
  AStart := Wrap360(Start);
  ASnap := Snap;
end;

procedure LoadDirectionsFile(const AFileName: String; out ACount: Integer;
  out AStart: Single; out AOrder: TArray<Integer>; out ASnap: Boolean);
var
  Value: TJSONValue;
begin
  Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(OSFriendlyPath(AFileName),
    TEncoding.UTF8));
  try
    DirectionsFromJson(Value, ACount, AStart, AOrder, ASnap);
  finally
    Value.Free;
  end;
end;

function IsProjectFile(const AFileName: String): Boolean;
begin
  Result := SameText(ExtractFileExt(AFileName), PROJECT_FILE_EXTENSION);
end;

function CreditsToJson(const ACredits: TSprite3DCredits): TJSONObject;
var
  Obj: TJSONObject;

  procedure Add(const AName, AValue: String);
  begin
    if AValue.Trim = String.Empty then
      Obj.AddPair(AName, TJSONNull.Create)
    else
      Obj.AddPair(AName, AValue.Trim);
  end;

begin
  Obj := TJSONObject.Create;
  Result := Obj;
  Add('creator', ACredits.Creator);
  Add('creator_url', ACredits.CreatorUrl);
  Add('modeller', ACredits.Modeller);
  Add('modeller_url', ACredits.ModellerUrl);
  Add('artist', ACredits.Artist);
  Add('artist_url', ACredits.ArtistUrl);
  Add('created', ACredits.Created);
end;

function CreditsFromJson(const AValue: TJSONValue): TSprite3DCredits;

  function Get(const AName: String): String;
  begin
    if not TJSONObject(AValue).TryGetValue<String>(AName, Result) then
      Result := String.Empty;
  end;

begin
  // Every field set; Default() would mean Gorilla's TGorillaOAuthMode.Default
  // in this unit
  Result.Creator := String.Empty;
  Result.CreatorUrl := String.Empty;
  Result.Modeller := String.Empty;
  Result.ModellerUrl := String.Empty;
  Result.Artist := String.Empty;
  Result.ArtistUrl := String.Empty;
  Result.Created := String.Empty;
  if not (AValue is TJSONObject) then
    Exit;
  Result.Creator := Get('creator');
  Result.CreatorUrl := Get('creator_url');
  Result.Modeller := Get('modeller');
  Result.ModellerUrl := Get('modeller_url');
  Result.Artist := Get('artist');
  Result.ArtistUrl := Get('artist_url');
  Result.Created := Get('created');
end;

function CompassPointName(const ADegrees: Single): String;
const
  // The 32 points, from north clockwise, 11.25 degrees apart
  POINT_STEP = 360 / 32;
  POINT_TOLERANCE = 0.01;
  NAMES: array[0..31] of String = (
    'N', 'NbE', 'NNE', 'NEbN', 'NE', 'NEbE', 'ENE', 'EbN',
    'E', 'EbS', 'ESE', 'SEbE', 'SE', 'SEbS', 'SSE', 'SbE',
    'S', 'SbW', 'SSW', 'SWbS', 'SW', 'SWbW', 'WSW', 'WbS',
    'W', 'WbN', 'WNW', 'NWbW', 'NW', 'NWbN', 'NNW', 'NbW');
var
  Angle: Single;
  Steps: Integer;
begin
  Result := String.Empty;
  Angle := Wrap360(ADegrees);
  Steps := Round(Angle / POINT_STEP);
  if Abs(Angle - Steps * POINT_STEP) <= POINT_TOLERANCE then
    Result := NAMES[Steps mod 32];
end;

function Wrap360(const ADegrees: Single): Single;
begin
  Result := ADegrees - 360 * Floor(ADegrees / 360);
end;

function DegreesText(const ADegrees: Single): String;
begin
  Result := Format('%3d', [Round(ADegrees) mod 360]);
end;

function DefaultModelDir: String;
begin
  {$IF DEFINED(MACOS)}
  Result := IncludeTrailingPathDelimiter(TPath.GetLibraryPath);
  {$ELSEIF DEFINED(LINUX)}
  Result := IncludeTrailingPathDelimiter(TPath.GetHomePath);
  {$ELSE}
  Result := '../../../';
  {$ENDIF}

  {$IF DEFINED(MSWINDOWS)}
  if DirectoryExists('models') then
    Result := String.Empty;
  {$ENDIF}
  Result := GetAssetsPath('../../../');

end;

function PaddingLimit(const AGrabWidth, AGrabHeight: Integer): Integer;
begin
  Result := Max(0, Min(AGrabWidth, AGrabHeight) div 4);
end;

function DefaultGrabFolder: String;
begin
  {$IF DEFINED(ANDROID)}
  Result := TPath.Combine(TPath.GetPublicPath, 'Grabs');
  {$ELSEIF DEFINED(IOS)}
  Result := TPath.Combine(TPath.GetDocumentsPath, 'Grabs');
  {$ELSE}
  Result := String.Empty;   // desktop: the user chooses
  {$ENDIF}
end;

function TSprite3DAppSettings.DebugActive: Boolean;
begin
  Result := FDebugEnabled or FDebugSwitch;
end;

function OpenH264Folder: String;
begin
  Result := TPath.Combine(TSprite3DAppSettings.SupportFolder, 'openh264');
end;

function NextNumberedFileName(const AFolder, APrefix, AExtension: String;
  var ANumber: Integer): String;
begin
  repeat
    Result := TPath.Combine(AFolder,
      Format('%s%.3d%s', [APrefix, ANumber, AExtension]));
    if not FileExists(Result) then
      Break;
    Inc(ANumber);
  until False;
end;

function SaveGrab(const ABitmap: TBitmap; const AFolder: String;
  var ANumber: Integer): String;
var
  Number: Integer;
  Folder: String;
begin
  // Work on a copy, so ANumber is untouched if anything below fails
  Number := ANumber;
  Folder := OSFriendlyPath(AFolder);
  ForceDirectories(Folder);
  Result := NextNumberedFileName(Folder, 'grab', '.png', Number);
  ABitmap.SaveToFile(Result);
  ANumber := Number + 1;
end;

const
  // One for each loader in the uses clause above
  MODEL_EXTENSIONS: array[0..7] of String =
    ('.glb', '.gltf', '.fbx', '.obj', '.usdc', '.dae', '.stl', '.ply');

function AllModelsFileSpec: String;
begin
  Result := String.Empty;
  for var Known in MODEL_EXTENSIONS do
  begin
    if Result <> String.Empty then
      Result := Result + ';';
    Result := Result + '*' + Known;
  end;
end;

function IsModelFile(const AFileName: String): Boolean;
var
  Ext: String;
begin
  Ext := ExtractFileExt(AFileName);
  for var Known in MODEL_EXTENSIONS do
    if SameText(Ext, Known) then
      Exit(True);
  Result := False;
end;

function StartupModelFile(const ARequested: TArray<String>;
  const ADefault: String): String;
begin
  for var FileName in ARequested do
    if IsModelFile(FileName) then
      Exit(FileName);
  Result := ADefault;
end;

type
  // The read StartModelFileRead starts; the counters are shared with the
  // worker, so they are only touched through TInterlocked
  TModelFileRead = class(TInterfacedObject, IModelFileRead)
  private
    FFileName: String;
    FCancelled: Integer;
    FDone: Integer;
    FBytesRead: Int64;
    FTotalBytes: Int64;
    FError: String;   // written before FDone is set
    procedure Run;
  public
    procedure Cancel;
    function Done: Boolean;
    function BytesRead: Int64;
    function TotalBytes: Int64;
    function Error: String;
  end;

procedure TModelFileRead.Cancel;
begin
  TInterlocked.Exchange(FCancelled, 1);
end;

function TModelFileRead.Done: Boolean;
begin
  Result := TInterlocked.CompareExchange(FDone, 0, 0) <> 0;
end;

function TModelFileRead.BytesRead: Int64;
begin
  Result := TInterlocked.Read(FBytesRead);
end;

function TModelFileRead.TotalBytes: Int64;
begin
  Result := TInterlocked.Read(FTotalBytes);
end;

function TModelFileRead.Error: String;
begin
  if Done then
    Result := FError
  else
    Result := String.Empty;
end;

// On the worker: read the file to the end, a block at a time, stopping
// early if cancelled
procedure TModelFileRead.Run;
const
  BLOCK = 1024 * 1024;
var
  Stream: TFileStream;
  Buffer: TBytes;
  Count: Integer;
begin
  try
    try
      Stream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
      try
        TInterlocked.Exchange(FTotalBytes, Stream.Size);
        SetLength(Buffer, BLOCK);
        repeat
          if TInterlocked.CompareExchange(FCancelled, 0, 0) <> 0 then
            Break;
          Count := Stream.Read(Buffer[0], BLOCK);
          if Count > 0 then
            TInterlocked.Add(FBytesRead, Count);
        until Count <= 0;
      finally
        Stream.Free;
      end;
    except
      on E: Exception do
        FError := E.Message;
    end;
  finally
    TInterlocked.Exchange(FDone, 1);
  end;
end;

function StartModelFileRead(const AFileName: String): IModelFileRead;
var
  Read: TModelFileRead;
  Keep: IModelFileRead;
begin
  Read := TModelFileRead.Create;
  Read.FFileName := OSFriendlyPath(AFileName);
  Keep := Read;   // the worker's own reference
  Result := Keep;
  TTask.Run(
    procedure
    begin
      Read.Run;
      Keep := nil;
    end);
end;

const
  // Raised whenever what is measured, or how, changes, so older figures are
  // not used. 2: models were measured hidden, which left every animation at
  // its rest pose, so those figures are wrong
  BOUNDS_CACHE_VERSION = 2;
  BOUNDS_CACHE_FOLDER = 'bounds';

function AnimationBoundsCacheFile(const AModelFile: String): String;
var
  Search: TSearchRec;
  FullName, Key: String;
begin
  Result := String.Empty;
  FullName := ExpandFileName(OSFriendlyPath(AModelFile));
  if FindFirst(FullName, faAnyFile, Search) <> 0 then
    Exit;
  try
    Key := Format('%s|%d|%s|%d', [FullName, Search.Size,
      FormatDateTime('yyyymmddhhnnsszzz', Search.TimeStamp), BOUNDS_CACHE_VERSION]);
  finally
    FindClose(Search);
  end;
  Result := OSFriendlyPath(TPath.Combine(TPath.Combine(TSprite3DAppSettings.SupportFolder,
    BOUNDS_CACHE_FOLDER), THashMD5.GetHashString(Key) + '.json'));
end;

function LoadAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  out ABounds: TArray<TAnimationBounds>): Boolean;
var
  FileName: String;
  Root: TJSONValue;
  Items, Names: TJSONArray;
  Item: TJSONObject;
  Box: TJSONArray;
  Entry: TAnimationBounds;
  Found: TArray<TAnimationBounds>;
  Saved: TArray<String>;
  Name: String;

  function Coord(const AIndex: Integer): Single;
  begin
    Result := (Box.Items[AIndex] as TJSONNumber).AsDouble;
  end;

begin
  Result := False;
  ABounds := nil;
  FileName := AnimationBoundsCacheFile(AModelFile);
  if (FileName = String.Empty) or not FileExists(FileName) then
    Exit;
  Root := nil;
  try
    try
      Root := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
      if not (Root is TJSONObject) or
        (TJSONObject(Root).GetValue<Integer>('version', 0) <> BOUNDS_CACHE_VERSION) then
        Exit;
      // Saved for exactly these animations, each once
      Names := TJSONObject(Root).GetValue('names') as TJSONArray;
      if (Names = nil) or (Names.Count <> Length(ANames)) then
        Exit;
      for var I := 0 to Names.Count - 1 do
        Saved := Saved + [Names.Items[I].Value];
      for Name in ANames do
      begin
        var Count := 0;
        for var Other in Saved do
          if Other = Name then
            Inc(Count);
        if Count <> 1 then
          Exit;
      end;
      Items := TJSONObject(Root).GetValue('animations') as TJSONArray;
      if (Items = nil) or (Items.Count > Length(ANames)) then
        Exit;
      for var I := 0 to Items.Count - 1 do
      begin
        Item := Items.Items[I] as TJSONObject;
        Box := Item.GetValue('box') as TJSONArray;
        if (Box = nil) or (Box.Count <> 6) then
          Exit;
        Entry.Name := Item.GetValue<String>('name');
        Entry.Poses := Item.GetValue<Integer>('poses');
        Entry.Box.TopLeftNear := Point3D(Coord(0), Coord(1), Coord(2));
        Entry.Box.BottomRightFar := Point3D(Coord(3), Coord(4), Coord(5));
        if IndexStr(Entry.Name, Saved) < 0 then
          Exit;
        Found := Found + [Entry];
      end;
      ABounds := Found;
      Result := True;
    except
      ABounds := nil;   // damaged or unreadable: measure again
      Result := False;
    end;
  finally
    Root.Free;
  end;
end;

procedure SaveAnimationBoundsCache(const AModelFile: String; const ANames: TArray<String>;
  const ABounds: TArray<TAnimationBounds>);
var
  FileName: String;
  Root, Item: TJSONObject;
  Items, Box, Names: TJSONArray;
  Entry: TAnimationBounds;

  procedure AddCoord(const AValue: Double);
  begin
    Box.AddElement(TJSONNumber.Create(AValue));
  end;

begin
  FileName := AnimationBoundsCacheFile(AModelFile);
  if FileName = String.Empty then
    Exit;
  Root := TJSONObject.Create;
  try
    Root.AddPair('version', TJSONNumber.Create(BOUNDS_CACHE_VERSION));
    Root.AddPair('model', ExpandFileName(AModelFile));
    Names := TJSONArray.Create;
    Root.AddPair('names', Names);
    for var Name in ANames do
      Names.Add(Name);
    Items := TJSONArray.Create;
    Root.AddPair('animations', Items);
    for Entry in ABounds do
    begin
      Item := TJSONObject.Create;
      Items.AddElement(Item);
      Item.AddPair('name', Entry.Name);
      Item.AddPair('poses', TJSONNumber.Create(Entry.Poses));
      Box := TJSONArray.Create;
      Item.AddPair('box', Box);
      AddCoord(Entry.Box.TopLeftNear.X);
      AddCoord(Entry.Box.TopLeftNear.Y);
      AddCoord(Entry.Box.TopLeftNear.Z);
      AddCoord(Entry.Box.BottomRightFar.X);
      AddCoord(Entry.Box.BottomRightFar.Y);
      AddCoord(Entry.Box.BottomRightFar.Z);
    end;
    try
      ForceDirectories(ExtractFilePath(FileName));
      // UTF-8 without a byte order mark, indented or minified as asked
      TFile.WriteAllBytes(FileName, JsonToBytes(Root));
    except
      // Not kept: measured again next time
    end;
  finally
    Root.Free;
  end;
end;

function AutoIconFileName(const AExtension: String): String;
var
  Folder: String;
  Number: Integer;
begin
  Folder := DefaultGrabFolder;
  if Folder = String.Empty then
    Exit(String.Empty);   // desktop: the user chooses
  Number := 1;
  Result := NextNumberedFileName(Folder, 'icon', AExtension, Number);
end;

function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox): TArray<String>;
var
  Names: TStringList;
  I: Integer;
  Ani: TArray<TGorillaAnimation>;
begin
  AModel.Clear;
  AModel.LoadFromFile(nil, OSFriendlyPath(AFileName), [TAnimationCachingFlag.VertexPosition]);

  Names := TStringList.Create;
  try
    Ani := AModel.AnimationManager.GetSortedAnimations();
    for I := 0 to Length(Ani) - 1 do
      Names.Add(Ani[I].Id);
    Result := Names.ToStringArray;
  finally
    Names.Free;
  end;

  // Taken before the caller adds axes or a grid to the model, which would
  // otherwise count towards it
  ABox := AModel.GetBoundingBox();
end;

procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);
begin
  AModel.Position.Point := Point3D(ABox.TopLeftNear.X + (ABox.Width / 2),
                                   ABox.TopLeftNear.Y + (ABox.Height / 2),
                                   ABox.TopLeftNear.Z + (ABox.Depth / 2));
  AModel.RotationAngle.X := MODEL_ROTATION.X;
  AModel.RotationAngle.Y := MODEL_ROTATION.Y;
  AModel.RotationAngle.Z := MODEL_ROTATION.Z;
end;

function EmptyModelSlot: TSprite3DModelSlot;
begin
  // Every field set; Default() would mean Gorilla's TGorillaOAuthMode.Default
  Result.Model := nil;
  Result.FileName := String.Empty;
  Result.Name := String.Empty;
  Result.Box.TopLeftNear := TPoint3D.Zero;
  Result.Box.BottomRightFar := TPoint3D.Zero;
  Result.Bounds := nil;
  Result.Names := nil;
  Result.Used := nil;
  Result.IsAnimated := False;
  Result.Order := 0;
end;

function NewModelSlot(const AModel: TGorillaModel; const AFileName: String;
  const ABox: TBoundingBox; const ABounds: TArray<TAnimationBounds>;
  const ANames: TArray<String>): TSprite3DModelSlot;
begin
  Result := EmptyModelSlot;
  Result.Model := AModel;
  Result.FileName := AFileName;
  Result.Name := TPath.GetFileNameWithoutExtension(AFileName);
  Result.Box := ABox;
  Result.Bounds := ABounds;
  Result.Names := ANames;
  Result.Used := Copy(ANames);
  Result.IsAnimated := Length(ANames) > 0;
end;

function ModelSlotIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AFileName: String): Integer;
var
  Wanted: String;
  I: Integer;
begin
  Result := -1;
  Wanted := ExpandFileName(OSFriendlyPath(AFileName));
  for I := 0 to High(ASlots) do
    if SameFileName(ExpandFileName(OSFriendlyPath(ASlots[I].FileName)), Wanted) then
      Exit(I);
end;

function ModelSlotNameIndex(const ASlots: TArray<TSprite3DModelSlot>;
  const AName: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(ASlots) do
    if SameText(ASlots[I].Name, AName) then
      Exit(I);
end;

function UniqueModelName(const AName: String; const ASlots: TArray<TSprite3DModelSlot>): String;
var
  Number: Integer;
begin
  Result := AName;
  Number := 1;
  while ModelSlotNameIndex(ASlots, Result) >= 0 do
  begin
    Inc(Number);
    Result := Format('%s (%d)', [AName, Number]);
  end;
end;

procedure FreeModelSlot(var ASlot: TSprite3DModelSlot);
var
  Model: TGorillaModel;
begin
  Model := ASlot.Model;
  ASlot := EmptyModelSlot;
  if Model = nil then
    Exit;
  Model.Parent := nil;
  Model.Free;
end;

procedure ShowModelWithHelpers(const AModel: TGorillaModel; const AShown: Boolean);
var
  Sweep: TModelSweep;
  Combined: TCombinedSweep;
  Axes: TModelAxes;
  Grid: TModelGrid;
begin
  if AModel = nil then
    Exit;
  AModel.Visible := AShown;
  Sweep := FindModelSweep(AModel);
  if Sweep <> nil then
    Sweep.Visible := AShown;
  Combined := FindCombinedSweep(AModel);
  if Combined <> nil then
    Combined.Visible := AShown;
  // Hidden with Shown, as their lines are not their children either
  Axes := FindModelAxes(AModel);
  if Axes <> nil then
    Axes.Shown := AShown;
  Grid := FindModelGrid(AModel);
  if Grid <> nil then
    Grid.Shown := AShown;
end;

function ModelPanOffset(const AModel: TGorillaModel; const ABox: TBoundingBox;
  const APanX, APanZ: Single): TPoint3D;
var
  Origin, AxisX, AxisZ: TPoint3D;
  Radius: Single;
begin
  Result := TPoint3D.Zero;
  if AModel = nil then
    Exit;
  Radius := 0.5 * Sqrt(Sqr(ABox.Width) + Sqr(ABox.Height) + Sqr(ABox.Depth));
  if Radius <= 0 then
    Radius := 1;
  // The model's own X and Z directions in the viewport's space, which is
  // where the camera's rig lives; scale is taken out, the radius puts it back
  Origin := AModel.LocalToAbsolute3D(TPoint3D.Zero);
  AxisX := AModel.LocalToAbsolute3D(Point3D(1, 0, 0)) - Origin;
  AxisZ := AModel.LocalToAbsolute3D(Point3D(0, 0, 1)) - Origin;
  if AxisX.Length > 0 then
    AxisX := AxisX.Normalize;
  if AxisZ.Length > 0 then
    AxisZ := AxisZ.Normalize;
  Result := AxisX * (EnsureRange(APanX, -PAN_LIMIT, PAN_LIMIT) * Radius) +
    AxisZ * (EnsureRange(APanZ, -PAN_LIMIT, PAN_LIMIT) * Radius);
end;

type
  // What the application knows about each theme
  TThemeInfo = record
    Key: String;             // in settings.json, and the style's file name
    Fallback: TAlphaColor;   // caption colour if the style's background can't be read
    Accent: TAlphaColor;     // window border; Null for the system's
  end;

const
  THEMES: array[TSprite3DTheme] of TThemeInfo = (
    (Key: 'Default';        Fallback: TAlphaColors.White; Accent: TAlphaColors.Null),
    (Key: 'Dark';           Fallback: $FF2B2B2B;          Accent: TAlphaColors.Null),
    (Key: 'AquaGraphite';   Fallback: $FF3A3A3A;          Accent: $FF2A9FD6),
    (Key: 'RubyGraphite';   Fallback: $FF3A3A3A;          Accent: $FFC0262C),
    (Key: 'GoldenGraphite'; Fallback: $FF3A3A3A;          Accent: $FFD4A017));

function TSprite3DAppSettings.GetThemeKind: TSprite3DTheme;
begin
  for var Kind := Low(TSprite3DTheme) to High(TSprite3DTheme) do
    if SameText(FTheme, THEMES[Kind].Key) then
      Exit(Kind);
  Result := thDefault;
end;

procedure TSprite3DAppSettings.SetThemeKind(const Value: TSprite3DTheme);
begin
  FTheme := THEMES[Value].Key;
end;

function ApplyTheme(const ATheme: TSprite3DTheme; out AError: String): Boolean;
var
  Folders: TArray<String>;
  Assets, Bds, StyleName, ResourceName: String;
begin
  Assets := GetAssetsPath('../../../');
  Folders := [];
  if Assets <> String.Empty then
    Folders := Folders + [TPath.Combine(Assets, 'styles'), Assets];
  Folders := Folders + [TPath.Combine(TSprite3DAppSettings.SupportFolder, 'styles')];
  {$IF DEFINED(MSWINDOWS)}
  // Set by the IDE for programs it runs, so a development build finds the
  // styles that come with RAD Studio without copying them
  Bds := GetEnvironmentVariable('BDS');
  if Bds <> String.Empty then
    Folders := Folders + [TPath.Combine(Bds, 'Redist\styles\Fmx')];
  {$ELSE}
  Bds := String.Empty;
  {$ENDIF}

  if ATheme = thDefault then
  begin
    StyleName := String.Empty;
    ResourceName := String.Empty;
  end
  else
  begin
    StyleName := THEMES[ATheme].Key;
    ResourceName := 'Sprite3D' + StyleName + 'Style';
  end;

  Result := ApplyFmxStyle(StyleName, ResourceName, Folders, AError);
  if not Result then
    Exit;   // the old style is still in use; so are its title bars

  if ATheme = thDefault then
    SetTitleBarSpec(TSprite3DTitleBarSpec.System)
  else
    SetTitleBarSpec(TitleBarSpecFromStyle(THEMES[ATheme].Fallback, THEMES[ATheme].Accent));
end;

const
  // The MIME types Linux knows the model files by; each pairs with an
  // extension in MODEL_EXTENSIONS
  MODEL_MIME_TYPES: array[0..7] of String =
    ('model/gltf-binary', 'model/gltf+json', 'model/x-fbx', 'model/obj',
     'model/x-usdc', 'model/vnd.collada+xml', 'model/stl', 'model/x-ply');
  MODEL_DESCRIPTIONS: array[0..7] of String =
    ('glTF binary model', 'glTF model', 'FBX model', 'Wavefront OBJ model',
     'USD binary model', 'Collada model', 'STL model', 'PLY model');

// Sprite3D's own project files, as the associations know them
function ProjectFileType: TSprite3DFileType;
begin
  Result := TSprite3DFileType.Create(PROJECT_FILE_EXTENSION, 'application/x-sprite3d',
    'Sprite3D project');
end;

function RegisterProjectFiles(out AMessage: String): Boolean;
{$IF DEFINED(MSWINDOWS)}
var
  Project: TSprite3DFileAssociations;
{$ELSEIF DEFINED(LINUX) and not DEFINED(ANDROID)}
var
  Project, Models: TSprite3DFileAssociations;
{$ENDIF}
begin
  AMessage := String.Empty;
  {$IF DEFINED(MSWINDOWS)}
  Project := TSprite3DFileAssociations.Create(APP_NAME, APP_NAME + '.Project',
    'Sprite3D project', [ProjectFileType]);
  try
    Result := Project.Register and Project.Claim;
    if not Result then
      AMessage := Project.LastError;
  finally
    Project.Free;
  end;
  {$ELSEIF DEFINED(LINUX) and not DEFINED(ANDROID)}
  Project := TSprite3DFileAssociations.Create(APP_NAME, APP_NAME + '.Project',
    'Sprite3D project', [ProjectFileType]);
  Models := CreateModelAssociations;
  try
    // The desktop entry lists every type it opens: the models too, if they
    // are registered, as they would be dropped otherwise
    if Models.IsRegistered then
      Result := Models.Register
    else
      Result := Project.Register;
    // The default for the project type alone, never for the models
    Result := Result and Project.Claim;
    if not Result then
      AMessage := Project.LastError + Models.LastError;
  finally
    Models.Free;
    Project.Free;
  end;
  {$ELSE}
  // Nothing to register here
  Result := True;
  {$ENDIF}
end;

function CreateModelAssociations: TSprite3DFileAssociations;
var
  Types: TArray<TSprite3DFileType>;
  I: Integer;
begin
  SetLength(Types, Length(MODEL_EXTENSIONS));
  for I := 0 to High(MODEL_EXTENSIONS) do
    Types[I] := TSprite3DFileType.Create(MODEL_EXTENSIONS[I], MODEL_MIME_TYPES[I],
      MODEL_DESCRIPTIONS[I]);
  {$IF DEFINED(LINUX) and not DEFINED(ANDROID)}
  // Linux has one desktop entry for every type, so Sprite3D's own project
  // files go in with the models, or registering these would drop them
  Types := Types + [ProjectFileType];
  {$ENDIF}
  Result := TSprite3DFileAssociations.Create(APP_NAME, APP_NAME + '.Model',
    '3D model', Types);
end;

function ApplyFileAssociations(const ASettings: TSprite3DAppSettings;
  const AOpenWith, AAlways: Boolean; out AMessage: String): Boolean;
var
  Assoc: TSprite3DFileAssociations;
  Support: TSprite3DAssocSupport;
  Backup: String;
  Always: Boolean;
  Notes: TStringList;
  AllOk: Boolean;

  procedure Step(const AOk: Boolean);
  begin
    if not AOk then
    begin
      AllOk := False;
      if Assoc.LastError <> String.Empty then
        Notes.Add(Assoc.LastError);
    end;
  end;

begin
  AMessage := String.Empty;
  AllOk := True;
  Support := TSprite3DFileAssociations.Support;
  if Support = asNone then
  begin
    AMessage := 'File associations can''t be changed on this platform.';
    Exit(False);
  end;

  Notes := TStringList.Create;
  Assoc := CreateModelAssociations;
  try
    Backup := ASettings.AssociationBackup;
    // Being the default without being offered at all makes no sense, except
    // on macOS, where being offered is fixed by the bundle
    Always := AAlways and (AOpenWith or (Support = asDefaultOnly));

    if AOpenWith or (Support = asDefaultOnly) then
      Step(Assoc.Register);

    if Always then
    begin
      if not Assoc.IsDefault then
        Step(Assoc.MakeDefault(Backup));
    end
    else if (Backup <> String.Empty) or Assoc.IsDefault then
      Step(Assoc.RestoreDefaults(Backup));

    if Assoc.NeedsUserConfirmation then
    begin
      {$IF DEFINED(MSWINDOWS)}
      Notes.Add('Windows keeps a default you chose yourself, and only you can change it. ' +
        'Default apps is now open: pick the application for each model file type there.');
      Assoc.OpenSystemDefaults;
      {$ELSEIF DEFINED(MACOS) and not DEFINED(IOS)}
      Notes.Add('To choose another application, use Get Info on a model file in Finder ' +
        'and change "Open with".');
      {$ENDIF}
    end;

    if not AOpenWith and (Support = asFull) and Assoc.IsRegistered then
      Step(Assoc.Unregister);

    ASettings.AssociationBackup := Backup;
    ASettings.OpenWith := Assoc.IsRegistered;
    ASettings.AlwaysOpenWith := Always;
    AMessage := Notes.Text.Trim;
  finally
    Assoc.Free;
    Notes.Free;
  end;
  Result := AllOk;
end;

function GpuModeSupported: Boolean;
begin
  {$IF DEFINED(MSWINDOWS)}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function ReadGpuMode: TSprite3DGpuMode;
{$IF DEFINED(MSWINDOWS)}
var
  Preference: TGpuPreference;
{$ENDIF}
begin
  Result := gmSystem;
  {$IF DEFINED(MSWINDOWS)}
  if GetGpuPreference(Preference, gpAutomatic) then
    case Preference of
      gpPowerSaving: Result := gmPowerSaving;
      gpHighPerformance: Result := gmHighPerformance;
    end;
  {$ENDIF}
end;

function WriteGpuMode(const AMode: TSprite3DGpuMode): Boolean;
begin
  {$IF DEFINED(MSWINDOWS)}
  case AMode of
    gmPowerSaving: Result := SetGpuPreference(gpPowerSaving);
    gmHighPerformance: Result := SetGpuPreference(gpHighPerformance);
  else
    Result := SetGpuPreference(gpAutomatic);
  end;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function ReadGeneralSettings(const ASettings: TSprite3DAppSettings): TSprite3DGeneralSettings;
var
  Assoc: TSprite3DFileAssociations;
begin
  Result.StartupAction := ASettings.StartupAction;
  Result.Theme := ASettings.ThemeKind;
  Result.OpenWith := ASettings.OpenWith;
  Result.AlwaysOpenWith := ASettings.AlwaysOpenWith;
  if TSprite3DFileAssociations.Support <> asNone then
  begin
    // The system's own state wins over what was last saved: the user may
    // have changed it outside the application
    Assoc := CreateModelAssociations;
    try
      Result.OpenWith := Assoc.IsRegistered;
      Result.AlwaysOpenWith := Assoc.IsDefault;
    finally
      Assoc.Free;
    end;
  end;
  Result.GrabWidth := ASettings.GrabWidth;
  Result.GrabHeight := ASettings.GrabHeight;
  Result.SaveFolder := ASettings.SaveFolder;
  Result.ViewFps := ASettings.ViewFps;
  Result.MinifyJson := ASettings.MinifyJson;
  Result.ResultsEdgeHint := ASettings.ResultsEdgeHint;
  // The caller knows the display; until it says, at least the rate in use
  Result.MaxViewFps := Max(ASettings.ViewFps, VIEW_FPS_DEFAULT);
  if GpuModeSupported then
    Result.GpuMode := ReadGpuMode
  else
    Result.GpuMode := ASettings.GpuMode;
end;

end.
