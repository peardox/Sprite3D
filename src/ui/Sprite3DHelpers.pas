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
//** OBJ, USD, Collada, STL and PLY files, as this unit uses them.
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
  them.

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
  /// <summary>The application's name, used for its per-user folder.</summary>
  APP_NAME = 'Sprite3D';
  //** @abstract(The name of the settings file in SupportFolder.)
  /// <summary>The name of the settings file in SupportFolder.</summary>
  SETTINGS_FILE_NAME = 'settings.json';
  //** @abstract(The transport buttons' icons: SVG paths in a 24 by 24 box, drawn in the
  //** button's text colour, shared by the View tab's player and the Results tab's.)
  /// <summary>The transport buttons' icons: SVG paths in a 24 by 24 box, drawn in the
  /// button's text colour, shared by the View tab's player and the Results tab's.</summary>
  ICON_FIRST = 'M5 6h2v12H5z M8 12l6-6v12z M14 12l6-6v12z';
  ICON_PREVIOUS = 'M7 12l7-6v12z M15 6h2v12h-2z';
  ICON_PLAY = 'M8 5v14l11-7z';
  ICON_PAUSE = 'M6 5h4v14H6z M14 5h4v14h-4z';
  ICON_NEXT = 'M7 6h2v12H7z M10 6v12l7-6z';
  ICON_LAST = 'M4 6v12l6-6z M10 6v12l6-6z M17 6h2v12h-2z';
  //** @abstract(The largest camera pan either way, as a multiple of the model's radius.)
  //**
  //** The radius is half the diagonal of the model's bounding box, so a pan of 1 moves the
  //** orbit centre out to where the model's farthest corner was.
  /// <summary>The largest camera pan either way, as a multiple of the model's
  /// radius.</summary>
  /// <remarks>The radius is half the diagonal of the model's bounding box, so a pan of 1
  /// moves the orbit centre out to where the model's farthest corner was.</remarks>
  PAN_LIMIT = 2.0;
  //** @abstract(The lowest frame rate Model, Animation Settings offers for saved animations,
  //** in frames per second.)
  /// <summary>The lowest frame rate Model, Animation Settings offers for saved animations, in
  /// frames per second.</summary>
  ANIMATION_FPS_MIN = 1;
  //** @abstract(The highest frame rate Model, Animation Settings offers for saved animations,
  //** in frames per second.)
  //**
  //** Gorilla bakes animations at 60 frames a second on desktop, so a higher rate would only
  //** repeat frames.
  /// <summary>The highest frame rate Model, Animation Settings offers for saved animations, in
  /// frames per second.</summary>
  /// <remarks>Gorilla bakes animations at 60 frames a second on desktop, so a higher rate
  /// would only repeat frames.</remarks>
  ANIMATION_FPS_MAX = 60;
  //** @abstract(The frame rate saved animations use until Model, Animation Settings changes
  //** it.)
  /// <summary>The frame rate saved animations use until Model, Animation Settings changes
  /// it.</summary>
  ANIMATION_FPS_DEFAULT = 30;
  //** @abstract(The smallest overscan factor Model, Animation Settings offers.)
  /// <summary>The smallest overscan factor Model, Animation Settings offers.</summary>
  OVERSCAN_FACTOR_MIN = 2;
  //** @abstract(The largest overscan factor Model, Animation Settings offers, before the GPU's
  //** own limit for the grab size.)
  /// <summary>The largest overscan factor Model, Animation Settings offers, before the GPU's
  /// own limit for the grab size.</summary>
  OVERSCAN_FACTOR_MAX = 16;
  //** @abstract(The overscan factor Model, Animation Settings shows until another is chosen.)
  /// <summary>The overscan factor Model, Animation Settings shows until another is
  /// chosen.</summary>
  OVERSCAN_FACTOR_DEFAULT = 4;
  //** @abstract(The lowest frame rate File, Settings lets the view be drawn at.)
  /// <summary>The lowest frame rate File, Settings lets the view be drawn at.</summary>
  VIEW_FPS_MIN = 1;
  //** @abstract(The highest frame rate kept for the view; File, Settings offers no more than
  //** the display's refresh rate.)
  /// <summary>The highest frame rate kept for the view; File, Settings offers no more than the
  /// display's refresh rate.</summary>
  VIEW_FPS_MAX = 1000;
  //** @abstract(The frame rate the view is drawn at until File, Settings changes it, and the
  //** most it offers where the display's refresh rate is not known.)
  /// <summary>The frame rate the view is drawn at until File, Settings changes it, and the
  /// most it offers where the display's refresh rate is not known.</summary>
  VIEW_FPS_DEFAULT = 60;
  //** @abstract(The numbers of directions Model, Directions offers: 1, 2, and every multiple of
  //** 4 or 6 up to 64, smallest first.)
  /// <summary>The numbers of directions Model, Directions offers: 1, 2, and every multiple of
  /// 4 or 6 up to 64, smallest first.</summary>
  DIRECTION_COUNTS: array[0..22] of Integer =
    (1, 2, 4, 6, 8, 12, 16, 18, 20, 24, 28, 30, 32, 36, 40, 42, 44, 48, 52, 54, 56, 60, 64);
  //** @abstract(The number of directions until Model, Directions changes it.)
  /// <summary>The number of directions until Model, Directions changes it.</summary>
  DIRECTION_COUNT_DEFAULT = 8;
  //** @abstract(The largest a texture atlas page may be, each way, as Model, Animation Settings
  //** offers it: 1k, 2k, 4k, 8k and 16k pixels.)
  /// <summary>The largest a texture atlas page may be, each way, as Model, Animation Settings
  /// offers it: 1k, 2k, 4k, 8k and 16k pixels.</summary>
  ATLAS_PAGE_SIZES: array[0..4] of Integer = (1024, 2048, 4096, 8192, 16384);
  //** @abstract(The texture atlas page size until Model, Animation Settings changes it.)
  /// <summary>The texture atlas page size until Model, Animation Settings changes
  /// it.</summary>
  ATLAS_PAGE_SIZE_DEFAULT = 4096;
  //** @abstract(The @code(format) a directions file names itself with, so another JSON file
  //** is not taken for one.)
  /// <summary>The <c>format</c> a directions file names itself with, so another JSON file is
  /// not taken for one.</summary>
  DIRECTIONS_FILE_FORMAT = 'Sprite3D directions';
  //** @abstract(The newest directions file layout this version writes and reads.)
  /// <summary>The newest directions file layout this version writes and reads.</summary>
  DIRECTIONS_FILE_VERSION = 1;
  //** @abstract(The extension Model, Directions gives the directions files it exports.)
  /// <summary>The extension Model, Directions gives the directions files it
  /// exports.</summary>
  DIRECTIONS_FILE_EXTENSION = '.json';
  //** @abstract(The extension of Sprite3D project files: credits, the model, directions and
  //** the Animations list, which File, Save Project saves and the system opens with
  //** Sprite3D.)
  /// <summary>The extension of Sprite3D project files: credits, the model, directions and the
  /// Animations list, which File, Save Project saves and the system opens with
  /// Sprite3D.</summary>
  PROJECT_FILE_EXTENSION = '.sprite3d';
  //** @abstract(The @code(format) a project file names itself with.)
  /// <summary>The <c>format</c> a project file names itself with.</summary>
  PROJECT_FILE_FORMAT = 'Sprite3D project';
  //** @abstract(The newest project file layout this version writes and reads.)
  /// <summary>The newest project file layout this version writes and reads.</summary>
  PROJECT_FILE_VERSION = 1;
  //** @abstract(The smallest width or height File, Grab renders, in pixels.)
  /// <summary>The smallest width or height File, Grab renders, in pixels.</summary>
  GRAB_SIZE_MIN = 8;
  //** @abstract(The largest width or height File, Grab renders, in pixels.)
  /// <summary>The largest width or height File, Grab renders, in pixels.</summary>
  GRAB_SIZE_MAX = 1024;
  //** @abstract(The width and height File, Grab renders until another size is chosen.)
  /// <summary>The width and height File, Grab renders until another size is
  /// chosen.</summary>
  GRAB_SIZE_DEFAULT = 256;
  //** @abstract(The square grab sizes File, Settings offers, in pixels, smallest first.)
  //**
  //** Any other size, square or not, is a custom size.
  /// <summary>The square grab sizes File, Settings offers, in pixels, smallest
  /// first.</summary>
  /// <remarks>Any other size, square or not, is a custom size.</remarks>
  GRAB_PRESET_SIZES: array[0..11] of Integer =
    (8, 16, 24, 32, 64, 96, 128, 160, 192, 256, 384, 512);

type
  //** @abstract(Raised by LoadDirectionsFile when a file cannot be used as directions.)
  //**
  //** The message says what is wrong, in words fit to show the user.
  /// <summary>Raised by LoadDirectionsFile when a file cannot be used as
  /// directions.</summary>
  /// <remarks>The message says what is wrong, in words fit to show the user.</remarks>
  EDirectionsFile = class(Exception);

  //** @abstract(Who made a sprite set, as File, Save Project sets it and the metadata's
  //** @code(meta) gives it.)
  //**
  //** Every field may be empty. Created is a date as ISO 8601 text, @code(yyyy-mm-dd).
  /// <summary>Who made a sprite set, as File, Save Project sets it and the metadata's
  /// <c>meta</c> gives it.</summary>
  /// <remarks>Every field may be empty. Created is a date as ISO 8601 text,
  /// <c>yyyy-mm-dd</c>.</remarks>
  TSprite3DCredits = record
    //** @abstract(Who created the sprite set.)
    /// <summary>Who created the sprite set.</summary>
    Creator: String;
    //** @abstract(Where the creator's work is.)
    /// <summary>Where the creator's work is.</summary>
    CreatorUrl: String;
    //** @abstract(Who made the models.)
    /// <summary>Who made the models.</summary>
    Modeller: String;
    //** @abstract(Where the modeller's work is.)
    /// <summary>Where the modeller's work is.</summary>
    ModellerUrl: String;
    //** @abstract(Who made the textures.)
    /// <summary>Who made the textures.</summary>
    Artist: String;
    //** @abstract(Where the artist's work is.)
    /// <summary>Where the artist's work is.</summary>
    ArtistUrl: String;
    //** @abstract(The day the project started, as @code(yyyy-mm-dd); empty if not set.)
    /// <summary>The day the project started, as <c>yyyy-mm-dd</c>; empty if not
    /// set.</summary>
    Created: String;
  end;

  //** @abstract(What the application loads when it starts and no file was asked for.)
  //**
  //** @code(saNone) loads nothing; @code(saDefaultModel) loads the sample model;
  //** @code(saLastModel) loads the model last opened, or the sample model if that file has
  //** gone. A file the operating system asks the application to open always comes first.
  /// <summary>What the application loads when it starts and no file was asked for.</summary>
  /// <remarks><c>saNone</c> loads nothing; <c>saDefaultModel</c> loads the sample model;
  /// <c>saLastModel</c> loads the model last opened, or the sample model if that file has
  /// gone. A file the operating system asks the application to open always comes
  /// first.</remarks>
  TSprite3DStartupAction = (saNone, saDefaultModel, saLastModel);

  //** @abstract(The application's look: FMX's own default style, or one of the FMX styles
  //** that come with RAD Studio.)
  //**
  //** @code(thDefault) is the platform's own style. @code(thDark) is Dark.style; the others
  //** are the coloured Graphite styles, dark grey with an accent: @code(thAquaGraphite) blue,
  //** @code(thRubyGraphite) red and @code(thGoldenGraphite) gold.
  /// <summary>The application's look: FMX's own default style, or one of the FMX styles that
  /// come with RAD Studio.</summary>
  /// <remarks><c>thDefault</c> is the platform's own style. <c>thDark</c> is Dark.style; the
  /// others are the coloured Graphite styles, dark grey with an accent:
  /// <c>thAquaGraphite</c> blue, <c>thRubyGraphite</c> red and <c>thGoldenGraphite</c>
  /// gold.</remarks>
  TSprite3DTheme = (thDefault, thDark, thAquaGraphite, thRubyGraphite, thGoldenGraphite);

  //** @abstract(Which graphics processor Windows gives the application.)
  //**
  //** @code(gmSystem) lets Windows decide; @code(gmPowerSaving) asks for the low-power GPU and
  //** @code(gmHighPerformance) for the high-performance one. Used on Windows only, and only
  //** after the application is restarted.
  /// <summary>Which graphics processor Windows gives the application.</summary>
  /// <remarks><c>gmSystem</c> lets Windows decide; <c>gmPowerSaving</c> asks for the
  /// low-power GPU and <c>gmHighPerformance</c> for the high-performance one. Used on Windows
  /// only, and only after the application is restarted.</remarks>
  TSprite3DGpuMode = (gmSystem, gmPowerSaving, gmHighPerformance);

  //** @abstract(The choices made in File, Settings, together.)
  /// <summary>The choices made in File, Settings, together.</summary>
  TSprite3DGeneralSettings = record
    //** @abstract(Whether the application is offered under Open With for model files.)
    /// <summary>Whether the application is offered under Open With for model files.</summary>
    OpenWith: Boolean;
    //** @abstract(Whether the application opens model files by default.)
    /// <summary>Whether the application opens model files by default.</summary>
    AlwaysOpenWith: Boolean;
    //** @abstract(What is loaded at start-up.)
    /// <summary>What is loaded at start-up.</summary>
    StartupAction: TSprite3DStartupAction;
    //** @abstract(The application's look.)
    /// <summary>The application's look.</summary>
    Theme: TSprite3DTheme;
    //** @abstract(The graphics processor asked for; Windows only.)
    /// <summary>The graphics processor asked for; Windows only.</summary>
    GpuMode: TSprite3DGpuMode;
    //** @abstract(The width of off-screen grabs, in pixels, GRAB_SIZE_MIN to GRAB_SIZE_MAX.)
    /// <summary>The width of off-screen grabs, in pixels, GRAB_SIZE_MIN to
    /// GRAB_SIZE_MAX.</summary>
    GrabWidth: Integer;
    //** @abstract(The height of off-screen grabs, in pixels, GRAB_SIZE_MIN to GRAB_SIZE_MAX.)
    /// <summary>The height of off-screen grabs, in pixels, GRAB_SIZE_MIN to
    /// GRAB_SIZE_MAX.</summary>
    GrabHeight: Integer;
    //** @abstract(The folder File, Grab saves into; empty to be asked at the next grab.)
    /// <summary>The folder File, Grab saves into; empty to be asked at the next
    /// grab.</summary>
    SaveFolder: String;
    //** @abstract(The frame rate the view is drawn at, VIEW_FPS_MIN to MaxViewFps.)
    /// <summary>The frame rate the view is drawn at, VIEW_FPS_MIN to MaxViewFps.</summary>
    ViewFps: Integer;
    //** @abstract(Whether JSON files are written minified.)
    /// <summary>Whether JSON files are written minified.</summary>
    MinifyJson: Boolean;
    //** @abstract(The most ViewFps may be: the display's refresh rate, set by the caller; not
    //** kept.)
    /// <summary>The most ViewFps may be: the display's refresh rate, set by the caller; not
    /// kept.</summary>
    MaxViewFps: Integer;
  end;

  //** @abstract(Protected-access helper for TControl3D; nothing in the project uses it yet.)
  //**
  //** Casting a TControl3D to this class exposes its protected members inside the unit that
  //** declares the cast. Because it is in the interface section, other units can use it too.
  /// <summary>Protected-access helper for TControl3D; nothing in the project uses it
  /// yet.</summary>
  /// <remarks>Casting a TControl3D to this class exposes its protected members inside the unit
  /// that declares the cast. Because it is in the interface section, other units can use it
  /// too.</remarks>
  TControl3DAccess = class(TControl3D);

  //** @abstract(The application's settings, kept between sessions in settings.json.)
  //**
  //** Create it, call Load once at start-up, and call Save after changing a setting. The file
  //** is @code(settings.json) in SupportFolder; on the first run it does not exist yet, so
  //** every setting keeps its default until the first Save. For the main thread only.
  //**
  //** @seealso(TSprite3DJsonSettings)
  /// <summary>The application's settings, kept between sessions in settings.json.</summary>
  /// <remarks>Create it, call Load once at start-up, and call Save after changing a setting.
  /// The file is <c>settings.json</c> in SupportFolder; on the first run it does not exist
  /// yet, so every setting keeps its default until the first Save. For the main thread
  /// only.</remarks>
  /// <seealso cref="Sprite3DStorage.TSprite3DJsonSettings"/>
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
    FDebugFrameBorders: Boolean;
    FExportAutoClose: Boolean;
    FLastExportFolder: String;
    FOverscan: Integer;
    FResampleFilter: TSprite3DResampleFilter;
    procedure SetAnimationFps(const Value: Integer);
    procedure SetViewFps(const Value: Integer);
    procedure SetMinifyJson(const Value: Boolean);
    procedure SetDirectionCount(const Value: Integer);
    procedure SetDirectionStart(const Value: Single);
    procedure SetOverscan(const Value: Integer);
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
    /// <summary>Creates the settings with their defaults, for settings.json in
    /// SupportFolder.</summary>
    /// <remarks>Nothing is read until Load is called.</remarks>
    constructor Create; reintroduce;
    //** @abstract(The application's per-user folder, for settings.json and support files.)
    //**
    //** AppDataFolder for APP_NAME: for example @code(%APPDATA%\Sprite3D) on Windows. It is
    //** created by the first Save.
    //**
    //** @returns(The folder's full path, without a trailing path delimiter.)
    /// <summary>The application's per-user folder, for settings.json and support
    /// files.</summary>
    /// <remarks>AppDataFolder for APP_NAME: for example <c>%APPDATA%\Sprite3D</c> on Windows.
    /// It is created by the first Save.</remarks>
    /// <returns>The folder's full path, without a trailing path delimiter.</returns>
    class function SupportFolder: String; static;
    //** @abstract(True if SaveFolder is set and the folder still exists.)
    //**
    //** False on the first run, and also if the folder has been removed or is on a drive
    //** that is not connected, so the user can be asked for a folder again.
    //**
    //** @returns(Whether grabs can be saved in SaveFolder without asking.)
    /// <summary>True if SaveFolder is set and the folder still exists.</summary>
    /// <remarks>False on the first run, and also if the folder has been removed or is on a
    /// drive that is not connected, so the user can be asked for a folder again.</remarks>
    /// <returns>Whether grabs can be saved in SaveFolder without asking.</returns>
    function HasSaveFolder: Boolean;
    //** @abstract(The order the directions are taken in: for each direction, from the first,
    //** its position round the compass.)
    //**
    //** Positions count clockwise from 0 at DirectionStart. This is DirectionOrder when it
    //** holds every position from 1 to DirectionCount once each, less one; otherwise the plain
    //** order, clockwise or anticlockwise as DirectionClockwise says.
    //**
    //** @returns(DirectionCount positions, every one from 0 to DirectionCount - 1 once.)
    /// <summary>The order the directions are taken in: for each direction, from the first,
    /// its position round the compass.</summary>
    /// <remarks>Positions count clockwise from 0 at DirectionStart. This is DirectionOrder
    /// when it holds every position from 1 to DirectionCount once each, less one; otherwise
    /// the plain order, clockwise or anticlockwise as DirectionClockwise says.</remarks>
    /// <returns>DirectionCount positions, every one from 0 to DirectionCount - 1
    /// once.</returns>
    function DirectionOrderList: TArray<Integer>;
    //** @abstract(Each direction's compass bearing, in the order the directions are taken
    //** in.)
    //**
    //** @returns(DirectionCount bearings, in degrees clockwise from north, 0 up to 360.)
    /// <summary>Each direction's compass bearing, in the order the directions are taken
    /// in.</summary>
    /// <returns>DirectionCount bearings, in degrees clockwise from north, 0 up to
    /// 360.</returns>
    function DirectionBearings: TArray<Single>;
    //** @abstract(The background settings together, as the viewport and grabs use them.)
    //**
    //** Reading turns the stored colour texts back into colours; one that cannot be read
    //** takes its default. Writing stores all of them; call Save afterwards to keep them.
    /// <summary>The background settings together, as the viewport and grabs use
    /// them.</summary>
    /// <remarks>Reading turns the stored colour texts back into colours; one that cannot be
    /// read takes its default. Writing stores all of them; call Save afterwards to keep
    /// them.</remarks>
    property BackgroundSpec: TSprite3DBackgroundSpec read GetBackgroundSpec
      write SetBackgroundSpec;
    //** @abstract(Theme as a TSprite3DTheme.)
    //**
    //** A name in settings.json that is not one of the themes, such as one from an older
    //** version, reads as thDefault.
    /// <summary>Theme as a TSprite3DTheme.</summary>
    /// <remarks>A name in settings.json that is not one of the themes, such as one from an
    /// older version, reads as thDefault.</remarks>
    property ThemeKind: TSprite3DTheme read GetThemeKind write SetThemeKind;
  published
    //** @abstract(The folder grabs are saved in; empty until one is chosen.)
    //**
    //** Stored as @code(saveFolder) in settings.json.
    /// <summary>The folder grabs are saved in; empty until one is chosen.</summary>
    /// <remarks>Stored as <c>saveFolder</c> in settings.json.</remarks>
    property SaveFolder: String read FSaveFolder write FSaveFolder;
    //** @abstract(The folder the last icon was saved in, where the next save dialog opens;
    //** empty until an icon is saved.)
    //**
    //** Stored as @code(iconFolder) in settings.json.
    /// <summary>The folder the last icon was saved in, where the next save dialog opens; empty
    /// until an icon is saved.</summary>
    /// <remarks>Stored as <c>iconFolder</c> in settings.json.</remarks>
    property IconFolder: String read FIconFolder write FIconFolder;
    //** @abstract(The folder a directions file was last exported to or imported from, where
    //** the next Export or Import in Model, Directions opens; empty until one is.)
    //**
    //** Stored as @code(directionsFolder) in settings.json.
    /// <summary>The folder a directions file was last exported to or imported from, where the
    /// next Export or Import in Model, Directions opens; empty until one is.</summary>
    /// <remarks>Stored as <c>directionsFolder</c> in settings.json.</remarks>
    property DirectionsFolder: String read FDirectionsFolder write FDirectionsFolder;
    //** @abstract(What the background shows: None, Transparent, Solid or Gradient.)
    //**
    //** Stored as @code(backgroundKind), by name. None, the default until one is chosen,
    //** draws no background; Transparent shows a checker in the viewport. Both leave grabs
    //** transparent.
    /// <summary>What the background shows: None, Transparent, Solid or Gradient.</summary>
    /// <remarks>Stored as <c>backgroundKind</c>, by name. None, the default until one is
    /// chosen, draws no background; Transparent shows a checker in the viewport. Both leave
    /// grabs transparent.</remarks>
    property BackgroundKind: TSprite3DBackgroundKind read FBackgroundKind
      write FBackgroundKind;
    //** @abstract(The Solid background's colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(backgroundColour).
    /// <summary>The Solid background's colour, as <c>#AARRGGBB</c>.</summary>
    /// <remarks>Stored as <c>backgroundColour</c>.</remarks>
    property BackgroundColour: String read FBackgroundColour write FBackgroundColour;
    //** @abstract(The Gradient background's starting colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(gradientFrom).
    /// <summary>The Gradient background's starting colour, as <c>#AARRGGBB</c>.</summary>
    /// <remarks>Stored as <c>gradientFrom</c>.</remarks>
    property GradientFrom: String read FGradientFrom write FGradientFrom;
    //** @abstract(The Gradient background's ending colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(gradientTo).
    /// <summary>The Gradient background's ending colour, as <c>#AARRGGBB</c>.</summary>
    /// <remarks>Stored as <c>gradientTo</c>.</remarks>
    property GradientTo: String read FGradientTo write FGradientTo;
    //** @abstract(Which way the Gradient background runs.)
    //**
    //** Stored as @code(gradientDirection), by name. TopToBottom, the default, is used when
    //** settings.json has none.
    /// <summary>Which way the Gradient background runs.</summary>
    /// <remarks>Stored as <c>gradientDirection</c>, by name. TopToBottom, the default, is used
    /// when settings.json has none.</remarks>
    property GradientDirection: TSprite3DGradientDirection read FGradientDirection
      write FGradientDirection;
    //** @abstract(The side of each checker square in the viewport, in pixels; 64 by
    //** default.)
    //**
    //** Stored as @code(checkerSize). Values below 1 count as 1.
    /// <summary>The side of each checker square in the viewport, in pixels; 64 by
    /// default.</summary>
    /// <remarks>Stored as <c>checkerSize</c>. Values below 1 count as 1.</remarks>
    property CheckerSize: Integer read FCheckerSize write FCheckerSize;
    //** @abstract(The lighter checker colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(checkerLight).
    /// <summary>The lighter checker colour, as <c>#AARRGGBB</c>.</summary>
    /// <remarks>Stored as <c>checkerLight</c>.</remarks>
    property CheckerLight: String read FCheckerLight write FCheckerLight;
    //** @abstract(The darker checker colour, as @code(#AARRGGBB).)
    //**
    //** Stored as @code(checkerDark).
    /// <summary>The darker checker colour, as <c>#AARRGGBB</c>.</summary>
    /// <remarks>Stored as <c>checkerDark</c>.</remarks>
    property CheckerDark: String read FCheckerDark write FCheckerDark;
    //** @abstract(Whether View, Show bounding box is ticked on the main form; True by
    //** default.)
    //**
    //** Stored as @code(showBoundingBox).
    /// <summary>Whether View, Show bounding box is ticked on the main form; True by
    /// default.</summary>
    /// <remarks>Stored as <c>showBoundingBox</c>.</remarks>
    property ShowBoundingBox: Boolean read FShowBoundingBox write FShowBoundingBox;
    //** @abstract(Whether View, Show grid is ticked on the main form; True by default.)
    //**
    //** Stored as @code(showGrid).
    /// <summary>Whether View, Show grid is ticked on the main form; True by
    /// default.</summary>
    /// <remarks>Stored as <c>showGrid</c>.</remarks>
    property ShowGrid: Boolean read FShowGrid write FShowGrid;
    //** @abstract(Whether View, Show axes is ticked on the main form; True by default.)
    //**
    //** Stored as @code(showAxes).
    /// <summary>Whether View, Show axes is ticked on the main form; True by
    /// default.</summary>
    /// <remarks>Stored as <c>showAxes</c>.</remarks>
    property ShowAxes: Boolean read FShowAxes write FShowAxes;
    //** @abstract(Whether View, Show Model Volume is ticked on the main form; True by
    //** default.)
    //**
    //** Stored as @code(showSweptVolume).
    /// <summary>Whether View, Show Model Volume is ticked on the main form; True by
    /// default.</summary>
    /// <remarks>Stored as <c>showSweptVolume</c>.</remarks>
    property ShowSweptVolume: Boolean read FShowSweptVolume write FShowSweptVolume;
    //** @abstract(Whether View, Show Animation Volume is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(showCombinedSweptVolume).
    /// <summary>Whether View, Show Animation Volume is ticked on the main form; False by
    /// default.</summary>
    /// <remarks>Stored as <c>showCombinedSweptVolume</c>.</remarks>
    property ShowCombinedSweptVolume: Boolean read FShowCombinedSweptVolume
      write FShowCombinedSweptVolume;
    //** @abstract(Whether View, Orthographic is ticked on the main form; False by default.)
    //**
    //** Stored as @code(orthographic).
    /// <summary>Whether View, Orthographic is ticked on the main form; False by
    /// default.</summary>
    /// <remarks>Stored as <c>orthographic</c>.</remarks>
    property Orthographic: Boolean read FOrthographic write FOrthographic;
    //** @abstract(The main form's camera view, the checked View, Camera item; Isometric by
    //** default.)
    //**
    //** Stored as @code(cameraView): the item's name without its View prefix and Item suffix,
    //** one of Variable, Isometric, Pixel2To1, ThreeQuarter, HeadOn, TopDown and Side. An
    //** unknown name gives Isometric.
    /// <summary>The main form's camera view, the checked View, Camera item; Isometric by
    /// default.</summary>
    /// <remarks>Stored as <c>cameraView</c>: the item's name without its View prefix and Item
    /// suffix, one of Variable, Isometric, Pixel2To1, ThreeQuarter, HeadOn, TopDown and Side.
    /// An unknown name gives Isometric.</remarks>
    property CameraView: String read FCameraView write FCameraView;
    //** @abstract(The Azimuth dial's angle in the Variable view, in degrees; 0 by default.)
    //**
    //** Stored as @code(variableAzimuth). Kept whenever the session ends in the Variable
    //** view, and restored with it.
    /// <summary>The Azimuth dial's angle in the Variable view, in degrees; 0 by
    /// default.</summary>
    /// <remarks>Stored as <c>variableAzimuth</c>. Kept whenever the session ends in the
    /// Variable view, and restored with it.</remarks>
    property VariableAzimuth: Single read FVariableAzimuth write FVariableAzimuth;
    //** @abstract(The Inclination dial's angle in the Variable view, in degrees; 0 by
    //** default.)
    //**
    //** Stored as @code(variableInclination). Kept whenever the session ends in the Variable
    //** view, and restored with it.
    /// <summary>The Inclination dial's angle in the Variable view, in degrees; 0 by
    /// default.</summary>
    /// <remarks>Stored as <c>variableInclination</c>. Kept whenever the session ends in the
    /// Variable view, and restored with it.</remarks>
    property VariableInclination: Single read FVariableInclination
      write FVariableInclination;
    //** @abstract(The Roll dial's angle in the Variable view, in degrees; 0 by default.)
    //**
    //** Stored as @code(variableRoll). Kept whenever the session ends in the Variable view,
    //** and restored with it.
    /// <summary>The Roll dial's angle in the Variable view, in degrees; 0 by
    /// default.</summary>
    /// <remarks>Stored as <c>variableRoll</c>. Kept whenever the session ends in the Variable
    /// view, and restored with it.</remarks>
    property VariableRoll: Single read FVariableRoll write FVariableRoll;
    //** @abstract(Whether the camera pan is applied; False by default.)
    //**
    //** Stored as @code(panEnabled). Set by the Pan box in the Variable camera dialog. While
    //** False, PanX and PanZ are kept but have no effect.
    /// <summary>Whether the camera pan is applied; False by default.</summary>
    /// <remarks>Stored as <c>panEnabled</c>. Set by the Pan box in the Variable camera dialog.
    /// While False, PanX and PanZ are kept but have no effect.</remarks>
    property PanEnabled: Boolean read FPanEnabled write FPanEnabled;
    //** @abstract(The camera pan along the model's X axis, as a multiple of its radius; 0 by
    //** default.)
    //**
    //** Stored as @code(panX). Values beyond PAN_LIMIT either way are limited to it.
    /// <summary>The camera pan along the model's X axis, as a multiple of its radius; 0 by
    /// default.</summary>
    /// <remarks>Stored as <c>panX</c>. Values beyond PAN_LIMIT either way are limited to
    /// it.</remarks>
    property PanX: Single read FPanX write FPanX;
    //** @abstract(The camera pan along the model's Z axis, as a multiple of its radius; 0 by
    //** default.)
    //**
    //** Stored as @code(panZ). Values beyond PAN_LIMIT either way are limited to it.
    /// <summary>The camera pan along the model's Z axis, as a multiple of its radius; 0 by
    /// default.</summary>
    /// <remarks>Stored as <c>panZ</c>. Values beyond PAN_LIMIT either way are limited to
    /// it.</remarks>
    property PanZ: Single read FPanZ write FPanZ;
    //** @abstract(What is loaded at start-up; the sample model by default.)
    //**
    //** Stored as @code(startupAction), by name.
    /// <summary>What is loaded at start-up; the sample model by default.</summary>
    /// <remarks>Stored as <c>startupAction</c>, by name.</remarks>
    property StartupAction: TSprite3DStartupAction read FStartupAction write FStartupAction;
    //** @abstract(The full path of the model last loaded; empty until one is.)
    //**
    //** Stored as @code(lastModel). Used when StartupAction is saLastModel.
    /// <summary>The full path of the model last loaded; empty until one is.</summary>
    /// <remarks>Stored as <c>lastModel</c>. Used when StartupAction is saLastModel.</remarks>
    property LastModel: String read FLastModel write FLastModel;
    //** @abstract(The application's look, by name; Default by default.)
    //**
    //** Stored as @code(theme): one of Default, Dark, AquaGraphite, RubyGraphite and
    //** GoldenGraphite. Kept as text rather than as an enumeration so that a name this version
    //** does not know can never stop settings.json loading; use ThemeKind in code.
    /// <summary>The application's look, by name; Default by default.</summary>
    /// <remarks>Stored as <c>theme</c>: one of Default, Dark, AquaGraphite, RubyGraphite and
    /// GoldenGraphite. Kept as text rather than as an enumeration so that a name this version
    /// does not know can never stop settings.json loading; use ThemeKind in code.</remarks>
    property Theme: String read FTheme write FTheme;
    //** @abstract(The graphics processor last chosen in File, Settings; Windows only.)
    //**
    //** Stored as @code(gpuMode), by name. Windows keeps the choice itself, per program file;
    //** the dialog shows what Windows has, so this is a record of the last choice.
    /// <summary>The graphics processor last chosen in File, Settings; Windows only.</summary>
    /// <remarks>Stored as <c>gpuMode</c>, by name. Windows keeps the choice itself, per program
    /// file; the dialog shows what Windows has, so this is a record of the last
    /// choice.</remarks>
    property GpuMode: TSprite3DGpuMode read FGpuMode write FGpuMode;
    //** @abstract(Whether the application was last registered for Open With.)
    //**
    //** Stored as @code(openWith). The system's registration is what counts; the dialog reads
    //** it afresh.
    /// <summary>Whether the application was last registered for Open With.</summary>
    /// <remarks>Stored as <c>openWith</c>. The system's registration is what counts; the
    /// dialog reads it afresh.</remarks>
    property OpenWith: Boolean read FOpenWith write FOpenWith;
    //** @abstract(Whether the application was last made the default for model files.)
    //**
    //** Stored as @code(alwaysOpenWith).
    /// <summary>Whether the application was last made the default for model
    /// files.</summary>
    /// <remarks>Stored as <c>alwaysOpenWith</c>.</remarks>
    property AlwaysOpenWith: Boolean read FAlwaysOpenWith write FAlwaysOpenWith;
    //** @abstract(The default applications model files had before this one was made the
    //** default, for putting them back.)
    //**
    //** Stored as @code(associationBackup): one @code(key=value) line per type, as
    //** TSprite3DFileAssociations.MakeDefault writes it. Empty when nothing needs putting back.
    /// <summary>The default applications model files had before this one was made the
    /// default, for putting them back.</summary>
    /// <remarks>Stored as <c>associationBackup</c>: one <c>key=value</c> line per type, as
    /// TSprite3DFileAssociations.MakeDefault writes it. Empty when nothing needs putting
    /// back.</remarks>
    property AssociationBackup: String read FAssociationBackup write FAssociationBackup;
    //** @abstract(The width of off-screen grabs, in pixels; GRAB_SIZE_DEFAULT by default.)
    //**
    //** Stored as @code(grabWidth). Written values are limited to GRAB_SIZE_MIN to
    //** GRAB_SIZE_MAX.
    /// <summary>The width of off-screen grabs, in pixels; GRAB_SIZE_DEFAULT by
    /// default.</summary>
    /// <remarks>Stored as <c>grabWidth</c>. Written values are limited to GRAB_SIZE_MIN to
    /// GRAB_SIZE_MAX.</remarks>
    property GrabWidth: Integer read FGrabWidth write SetGrabWidth;
    //** @abstract(The height of off-screen grabs, in pixels; GRAB_SIZE_DEFAULT by default.)
    //**
    //** Stored as @code(grabHeight). Written values are limited to GRAB_SIZE_MIN to
    //** GRAB_SIZE_MAX.
    /// <summary>The height of off-screen grabs, in pixels; GRAB_SIZE_DEFAULT by
    /// default.</summary>
    /// <remarks>Stored as <c>grabHeight</c>. Written values are limited to GRAB_SIZE_MIN to
    /// GRAB_SIZE_MAX.</remarks>
    property GrabHeight: Integer read FGrabHeight write SetGrabHeight;
    //** @abstract(The frame rate animations are saved at, in frames per second;
    //** ANIMATION_FPS_DEFAULT by default.)
    //**
    //** Set in Model, Animation Settings. Stored as @code(animationFps). Written values are
    //** limited to ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.
    /// <summary>The frame rate animations are saved at, in frames per second;
    /// ANIMATION_FPS_DEFAULT by default.</summary>
    /// <remarks>Set in Model, Animation Settings. Stored as <c>animationFps</c>. Written
    /// values are limited to ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.</remarks>
    property AnimationFps: Integer read FAnimationFps write SetAnimationFps;
    //** @abstract(The frame rate the view is drawn at, in frames per second;
    //** VIEW_FPS_DEFAULT by default.)
    //**
    //** Set in File, Settings, which offers up to the display's refresh rate. Stored as
    //** @code(viewFps). Written values are limited to VIEW_FPS_MIN to VIEW_FPS_MAX.
    /// <summary>The frame rate the view is drawn at, in frames per second; VIEW_FPS_DEFAULT by
    /// default.</summary>
    /// <remarks>Set in File, Settings, which offers up to the display's refresh rate. Stored
    /// as <c>viewFps</c>. Written values are limited to VIEW_FPS_MIN to
    /// VIEW_FPS_MAX.</remarks>
    property ViewFps: Integer read FViewFps write SetViewFps;
    //** @abstract(Whether JSON files are written minified, with no indents or line breaks;
    //** False by default.)
    //**
    //** Set in File, Settings. Stored as @code(minifyJson). Writing it, loading settings.json
    //** included, sets JsonText.MinifyJson, which every JSON file Sprite3D writes follows,
    //** settings.json itself among them.
    /// <summary>Whether JSON files are written minified, with no indents or line breaks; False
    /// by default.</summary>
    /// <remarks>Set in File, Settings. Stored as <c>minifyJson</c>. Writing it, loading
    /// settings.json included, sets JsonText.MinifyJson, which every JSON file Sprite3D writes
    /// follows, settings.json itself among them.</remarks>
    property MinifyJson: Boolean read FMinifyJson write SetMinifyJson;
    //** @abstract(How many directions Model, Directions has around its compass;
    //** DIRECTION_COUNT_DEFAULT by default.)
    //**
    //** Stored as @code(directionCount). A written value that is not one of DIRECTION_COUNTS
    //** becomes the nearest that is.
    /// <summary>How many directions Model, Directions has around its compass;
    /// DIRECTION_COUNT_DEFAULT by default.</summary>
    /// <remarks>Stored as <c>directionCount</c>. A written value that is not one of
    /// DIRECTION_COUNTS becomes the nearest that is.</remarks>
    property DirectionCount: Integer read FDirectionCount write SetDirectionCount;
    //** @abstract(The compass bearing of position 0, the red marker in Model, Directions, in
    //** degrees clockwise from north; 0, north, by default.)
    //**
    //** Stored as @code(directionStart). It is the first direction's bearing unless
    //** DirectionOrder puts another first. Written values are wrapped into 0 up to 360.
    /// <summary>The compass bearing of position 0, the red marker in Model, Directions, in
    /// degrees clockwise from north; 0, north, by default.</summary>
    /// <remarks>Stored as <c>directionStart</c>. It is the first direction's bearing unless
    /// DirectionOrder puts another first. Written values are wrapped into 0 up to
    /// 360.</remarks>
    property DirectionStart: Single read FDirectionStart write SetDirectionStart;
    //** @abstract(Whether the directions are numbered clockwise from the first; True by
    //** default.)
    //**
    //** Stored as @code(directionClockwise). False numbers them anticlockwise. Used when
    //** DirectionOrder is empty or does not fit DirectionCount.
    /// <summary>Whether the directions are numbered clockwise from the first; True by
    /// default.</summary>
    /// <remarks>Stored as <c>directionClockwise</c>. False numbers them anticlockwise. Used
    /// when DirectionOrder is empty or does not fit DirectionCount.</remarks>
    property DirectionClockwise: Boolean read FDirectionClockwise
      write FDirectionClockwise;
    //** @abstract(The order the directions are taken in, as Model, Directions set it; empty
    //** by default.)
    //**
    //** Stored as @code(directionOrder): the positions round the compass, counted clockwise
    //** from 1 at DirectionStart, in the order the directions are numbered, separated by
    //** commas, such as @code('3,5,7,1,4,6,8,2') for E, S, W, N, SE, SW, NW and NE when the
    //** first of eight is north. Empty, or text that is not every position from 1 to
    //** DirectionCount once each, means the plain order DirectionClockwise gives. Use
    //** DirectionOrderList and DirectionBearings rather than reading it directly.
    /// <summary>The order the directions are taken in, as Model, Directions set it; empty by
    /// default.</summary>
    /// <remarks>Stored as <c>directionOrder</c>: the positions round the compass, counted
    /// clockwise from 1 at DirectionStart, in the order the directions are numbered, separated
    /// by commas, such as <c>'3,5,7,1,4,6,8,2'</c> for E, S, W, N, SE, SW, NW and NE when the
    /// first of eight is north. Empty, or text that is not every position from 1 to
    /// DirectionCount once each, means the plain order DirectionClockwise gives. Use
    /// DirectionOrderList and DirectionBearings rather than reading it directly.</remarks>
    property DirectionOrder: String read FDirectionOrder write FDirectionOrder;
    //** @abstract(Whether the Model, Directions dial turns in steps of one direction; False
    //** by default.)
    //**
    //** Stored as @code(directionSnap). True locks DirectionStart to whole multiples of 360
    //** divided by DirectionCount, counted from north.
    /// <summary>Whether the Model, Directions dial turns in steps of one direction; False by
    /// default.</summary>
    /// <remarks>Stored as <c>directionSnap</c>. True locks DirectionStart to whole multiples of
    /// 360 divided by DirectionCount, counted from north.</remarks>
    property DirectionSnap: Boolean read FDirectionSnap write FDirectionSnap;
    //** @abstract(Whether a sprite strip or spritesheet is saved with its metadata; False by
    //** default.)
    //**
    //** Stored as @code(exportMetadata); set by the Metadata box above Export. True writes,
    //** beside each strip or spritesheet, a JSON file of the same name with the extension
    //** .json, made by SaveSheetMetadata: the image's size and layout, where the centre of
    //** rotation falls in a frame, and each frame's transparent border. AniGifs and MP4 videos
    //** have none, and texture atlas pages always have it, whatever this says.
    /// <summary>Whether a sprite strip or spritesheet is saved with its metadata; False by
    /// default.</summary>
    /// <remarks>Stored as <c>exportMetadata</c>; set by the Metadata box above Export. True
    /// writes, beside each strip or spritesheet, a JSON file of the same name with the
    /// extension .json, made by SaveSheetMetadata: the image's size and layout, where the
    /// centre of rotation falls in a frame, and each frame's transparent border. AniGifs and
    /// MP4 videos have none, and texture atlas pages always have it, whatever this
    /// says.</remarks>
    property ExportMetadata: Boolean read FExportMetadata write FExportMetadata;
    //** @abstract(Whether exports are to be made for every direction of Model, Directions;
    //** False by default.)
    //**
    //** Stored as @code(exportDirections); set by the Directions box above Export. Ticked,
    //** each animation is exported once for each direction, in their order, and the
    //** metadata's @code(directions) lists their bearings; otherwise it is the single dummy
    //** entry 0.
    /// <summary>Whether exports are to be made for every direction of Model, Directions; False
    /// by default.</summary>
    /// <remarks>Stored as <c>exportDirections</c>; set by the Directions box above Export.
    /// Ticked, each animation is exported once for each direction, in their order, and the
    /// metadata's <c>directions</c> lists their bearings; otherwise it is the single dummy
    /// entry 0.</remarks>
    property ExportDirections: Boolean read FExportDirections write FExportDirections;
    //** @abstract(The largest a texture atlas page may be, in pixels each way;
    //** ATLAS_PAGE_SIZE_DEFAULT by default.)
    //**
    //** Stored as @code(atlasPageSize); set in Model, Animation Settings. A written value that
    //** is not one of ATLAS_PAGE_SIZES becomes the nearest that is.
    /// <summary>The largest a texture atlas page may be, in pixels each way;
    /// ATLAS_PAGE_SIZE_DEFAULT by default.</summary>
    /// <remarks>Stored as <c>atlasPageSize</c>; set in Model, Animation Settings. A written
    /// value that is not one of ATLAS_PAGE_SIZES becomes the nearest that is.</remarks>
    property AtlasPageSize: Integer read FAtlasPageSize write SetAtlasPageSize;
    //** @abstract(Whether a texture atlas page may be any size, rather than a power of 2 each
    //** way; False by default.)
    //**
    //** Stored as @code(atlasNonPowerOf2); set in Model, Animation Settings. False makes each
    //** page's width and height the smallest powers of 2 that hold its frames; True makes the
    //** page exactly as large as its grid of frames.
    /// <summary>Whether a texture atlas page may be any size, rather than a power of 2 each
    /// way; False by default.</summary>
    /// <remarks>Stored as <c>atlasNonPowerOf2</c>; set in Model, Animation Settings. False
    /// makes each page's width and height the smallest powers of 2 that hold its frames; True
    /// makes the page exactly as large as its grid of frames.</remarks>
    property AtlasNonPowerOf2: Boolean read FAtlasNonPowerOf2 write FAtlasNonPowerOf2;
    //** @abstract(What Export saves, as the drop-down under the animation controls chose it;
    //** @code(strip) by default.)
    //**
    //** Stored as @code(exportKind): @code(strip), @code(sheet), @code(atlas), @code(gif) or
    //** @code(mp4). Anything else counts as @code(strip), and @code(mp4) while the video
    //** libraries have not loaded is shown as @code(strip) until they do.
    /// <summary>What Export saves, as the drop-down under the animation controls chose it;
    /// <c>strip</c> by default.</summary>
    /// <remarks>Stored as <c>exportKind</c>: <c>strip</c>, <c>sheet</c>, <c>atlas</c>,
    /// <c>gif</c> or <c>mp4</c>. Anything else counts as <c>strip</c>, and <c>mp4</c> while
    /// the video libraries have not loaded is shown as <c>strip</c> until they do.</remarks>
    property ExportKind: String read FExportKind write FExportKind;
    //** @abstract(The folder texture atlas pages are saved in, chosen with Texture Atlas in
    //** the drop-down; empty by default.)
    //**
    //** Stored as @code(atlasFolder). A folder that no longer exists is asked for again.
    /// <summary>The folder texture atlas pages are saved in, chosen with Texture Atlas in the
    /// drop-down; empty by default.</summary>
    /// <remarks>Stored as <c>atlasFolder</c>. A folder that no longer exists is asked for
    /// again.</remarks>
    property AtlasFolder: String read FAtlasFolder write FAtlasFolder;
    //** @abstract(Whether the debugging aids are offered; False by default.)
    //**
    //** Stored as @code(debug_enabled), and only changed by editing settings.json by hand:
    //** nothing in the application sets it. True adds File, Debug to the menu and says so in
    //** the Debug tab at startup.
    /// <summary>Whether the debugging aids are offered; False by default.</summary>
    /// <remarks>Stored as <c>debug_enabled</c>, and only changed by editing settings.json by
    /// hand: nothing in the application sets it. True adds File, Debug to the menu and says so
    /// in the Debug tab at startup.</remarks>
    //** @abstract(Whether the export progress dialog closes by itself when an export ends
    //** without problems; False by default.)
    //**
    //** Stored as @code(exportAutoClose); set by Autoclose when done in that dialog.
    /// <summary>Whether the export progress dialog closes by itself when an export ends without
    /// problems; False by default.</summary>
    /// <remarks>Stored as <c>exportAutoClose</c>; set by Autoclose when done in that
    /// dialog.</remarks>
    property ExportAutoClose: Boolean read FExportAutoClose write FExportAutoClose;
    //** @abstract(The folder the last export went to, from Export or the right-click menu;
    //** empty until there has been one.)
    //**
    //** Stored as @code(lastExportFolder). The Results tab reads it when it first shows, and
    //** its Select Folder opens there.
    /// <summary>The folder the last export went to, from Export or the right-click menu; empty
    /// until there has been one.</summary>
    /// <remarks>Stored as <c>lastExportFolder</c>. The Results tab reads it when it first
    /// shows, and its Select Folder opens there.</remarks>
    property LastExportFolder: String read FLastExportFolder write FLastExportFolder;
    [NeonProperty('debug_enabled')]
    property DebugEnabled: Boolean read FDebugEnabled write FDebugEnabled;
    //** @abstract(Whether every exported frame gets a 1-pixel black border; False by default.)
    //**
    //** Stored as @code(debug_frame_borders); set by File, Debug, Frame Borders, which is
    //** offered only while DebugEnabled. Has no effect while DebugEnabled is False. The border
    //** is drawn on the saved images only: the metadata is measured from the frames as
    //** rendered.
    /// <summary>Whether every exported frame gets a 1-pixel black border; False by
    /// default.</summary>
    /// <remarks>Stored as <c>debug_frame_borders</c>; set by File, Debug, Frame Borders, which
    /// is offered only while DebugEnabled. Has no effect while DebugEnabled is False. The
    /// border is drawn on the saved images only: the metadata is measured from the frames as
    /// rendered.</remarks>
    [NeonProperty('debug_frame_borders')]
    property DebugFrameBorders: Boolean read FDebugFrameBorders write FDebugFrameBorders;
    //** @abstract(The overscan factor Model, Animation Settings was last left at;
    //** OVERSCAN_FACTOR_DEFAULT by default.)
    //**
    //** Only the factor is kept: whether overscan is on is not, and it starts off each
    //** session, until ticked in Model, Animation Settings. Stored as @code(overscan). Written
    //** values are limited to OVERSCAN_FACTOR_MIN to OVERSCAN_FACTOR_MAX; a grab may use less,
    //** if the GPU cannot draw that much larger.
    /// <summary>The overscan factor Model, Animation Settings was last left at;
    /// OVERSCAN_FACTOR_DEFAULT by default.</summary>
    /// <remarks>Only the factor is kept: whether overscan is on is not, and it starts off each
    /// session, until ticked in Model, Animation Settings. Stored as <c>overscan</c>. Written
    /// values are limited to OVERSCAN_FACTOR_MIN to OVERSCAN_FACTOR_MAX; a grab may use less,
    /// if the GPU cannot draw that much larger.</remarks>
    property Overscan: Integer read FOverscan write SetOverscan;
    //** @abstract(The filter overscanned grabs are scaled down with; Box by default.)
    //**
    //** Chosen in Model, Animation Settings. Stored as @code(resampleFilter).
    /// <summary>The filter overscanned grabs are scaled down with; Box by default.</summary>
    /// <remarks>Chosen in Model, Animation Settings. Stored as
    /// <c>resampleFilter</c>.</remarks>
    property ResampleFilter: TSprite3DResampleFilter read FResampleFilter
      write FResampleFilter;
  end;

//** @abstract(Shifts an angle in degrees by whole turns into the range 0 to 360.)
//**
//** @param(ADegrees Any angle in degrees, negative or past a full turn.)
//**
//** @returns(The same direction as an angle from 0 up to, but not including, 360.)
/// <summary>Shifts an angle in degrees by whole turns into the range 0 to 360.</summary>
/// <param name="ADegrees">Any angle in degrees, negative or past a full turn.</param>
/// <returns>The same direction as an angle from 0 up to, but not including, 360.</returns>
function Wrap360(const ADegrees: Single): Single;

//** @abstract(The entry of DIRECTION_COUNTS nearest to a number, the smaller of two as near.)
//**
//** @param(ACount Any number.)
//**
//** @returns(One of DIRECTION_COUNTS.)
/// <summary>The entry of DIRECTION_COUNTS nearest to a number, the smaller of two as
/// near.</summary>
/// <param name="ACount">Any number.</param>
/// <returns>One of DIRECTION_COUNTS.</returns>
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
/// <summary>The abbreviated name of a point of the 32-point compass, if a bearing is on
/// one.</summary>
/// <remarks>The points are 11.25 degrees apart, named as the mariner's compass names them:
/// the cardinal points N, E, S and W; the intercardinal NE, SE, SW and NW; the eight winds
/// between them, NNE, ENE and so on; and the sixteen "by" points, NbE (north by east), NEbN
/// and so on.</remarks>
/// <param name="ADegrees">A bearing in degrees clockwise from north, any number of
/// turns.</param>
/// <returns>The point's abbreviation, such as N, NbE, NNE or NEbN, for a bearing within a
/// hundredth of a degree of one; otherwise an empty string, so a whole-degree bearing only
/// has a name on the eight points that fall on whole degrees.</returns>
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
/// <summary>The plain order of ACount directions: clockwise from position 0, or
/// anticlockwise.</summary>
/// <param name="ACount">How many directions; values below 1 give an empty order.</param>
/// <param name="AClockwise">True for 0, 1, 2 and so on; False for 0, ACount - 1, ACount - 2
/// and so on.</param>
/// <returns>ACount positions, every one from 0 to ACount - 1 once.</returns>
function PlainDirectionOrder(const ACount: Integer; const AClockwise: Boolean): TArray<Integer>;

//** @abstract(Whether an order holds every position from 0 to ACount - 1 exactly once.)
//**
//** @param(AOrder The order, as positions from 0.)
//**
//** @param(ACount How many directions there are.)
//**
//** @returns(True if AOrder has ACount entries and each position once.)
/// <summary>Whether an order holds every position from 0 to ACount - 1 exactly
/// once.</summary>
/// <param name="AOrder">The order, as positions from 0.</param>
/// <param name="ACount">How many directions there are.</param>
/// <returns>True if AOrder has ACount entries and each position once.</returns>
function IsDirectionOrder(const AOrder: TArray<Integer>; const ACount: Integer): Boolean;

//** @abstract(An order as the text DirectionOrder keeps: positions from 1, separated by
//** commas.)
//**
//** @param(AOrder The order, as positions from 0.)
//**
//** @returns(The text, such as @code('3,5,7,1,4,6,8,2'); empty for an empty order.)
/// <summary>An order as the text DirectionOrder keeps: positions from 1, separated by
/// commas.</summary>
/// <param name="AOrder">The order, as positions from 0.</param>
/// <returns>The text, such as <c>'3,5,7,1,4,6,8,2'</c>; empty for an empty order.</returns>
function DirectionOrderToText(const AOrder: TArray<Integer>): String;

//** @abstract(Reads the text DirectionOrder keeps back into an order.)
//**
//** @param(AText Positions from 1, separated by commas; spaces are ignored.)
//**
//** @returns(The positions from 0, in order; an entry that is not a number gives -1, which
//** IsDirectionOrder rejects.)
/// <summary>Reads the text DirectionOrder keeps back into an order.</summary>
/// <param name="AText">Positions from 1, separated by commas; spaces are ignored.</param>
/// <returns>The positions from 0, in order; an entry that is not a number gives -1, which
/// IsDirectionOrder rejects.</returns>
function DirectionOrderFromText(const AText: String): TArray<Integer>;

//** @abstract(Writes a set of directions to a JSON file, for Model, Directions' Export.)
//**
//** The file holds everything Model, Directions sets, so it can be read back with
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
/// <summary>Writes a set of directions to a JSON file, for Model, Directions'
/// Export.</summary>
/// <remarks>The file holds everything Model, Directions sets, so it can be read back with
/// LoadDirectionsFile, kept beside artwork whose directions come in a fixed order, and
/// swapped between models. Its members are <c>format</c> (DIRECTIONS_FILE_FORMAT),
/// <c>version</c>, <c>count</c>, <c>start</c>, <c>snap</c>, <c>clockwise</c>,
/// <c>order</c> and <c>directions</c>. <c>order</c> holds the positions, counted clockwise
/// from 1 at the red marker, in the order the directions are taken in, as DirectionOrder
/// does, such as <c>[3, 5, 7, 1, 4, 6, 8, 2]</c>. <c>directions</c> spells each one out,
/// with its number, position, bearing and compass point, for people and other tools to
/// read; LoadDirectionsFile ignores it. The folder is made if it does not exist.</remarks>
/// <param name="AFileName">The file to write; replaced if it exists.</param>
/// <param name="ACount">How many directions; one of DIRECTION_COUNTS.</param>
/// <param name="AStart">The red marker's bearing, in degrees clockwise from north.</param>
/// <param name="AOrder">The order, as positions from 0; one that does not fit ACount is
/// written as the plain clockwise order.</param>
/// <param name="ASnap">Whether the dial is locked to steps of one direction.</param>
/// <exception cref="EInOutError">Or another file exception, if the file cannot be
/// written.</exception>
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
/// <summary>Reads a set of directions from a JSON file written by
/// SaveDirectionsFile.</summary>
/// <remarks><c>count</c> and <c>start</c> are needed. <c>order</c> may be left out, when
/// <c>clockwise</c>, true if it too is left out, gives the plain order; <c>snap</c> may be
/// left out, for False. <c>format</c>, when present, must be DIRECTIONS_FILE_FORMAT, and
/// <c>version</c>, when present, no newer than DIRECTIONS_FILE_VERSION. Anything else in
/// the file is ignored.</remarks>
/// <param name="AFileName">The file to read.</param>
/// <param name="ACount">Set to the number of directions, one of DIRECTION_COUNTS.</param>
/// <param name="AStart">Set to the red marker's bearing, wrapped into 0 up to 360.</param>
/// <param name="AOrder">Set to the order, as positions from 0, every one once.</param>
/// <param name="ASnap">Set to whether the dial is locked to steps of one
/// direction.</param>
/// <exception cref="EDirectionsFile">If the file is not JSON, is not a directions file, or
/// holds a count or order that cannot be used; the message says which, for showing as it
/// is.</exception>
/// <exception cref="EFileNotFoundException">Or another file exception, if the file cannot
/// be read.</exception>
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
/// <summary>A set of directions as the JSON object SaveDirectionsFile writes.</summary>
/// <remarks>For keeping directions inside another JSON file, such as a project file. The
/// caller owns the object.</remarks>
/// <param name="ACount">How many directions; one of DIRECTION_COUNTS.</param>
/// <param name="AStart">The red marker's bearing, in degrees clockwise from north.</param>
/// <param name="AOrder">The order, as positions from 0; one that does not fit ACount is
/// written as the plain clockwise order.</param>
/// <param name="ASnap">Whether the dial is locked to steps of one direction.</param>
/// <returns>The object, with every member SaveDirectionsFile writes.</returns>
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
/// <summary>Reads a set of directions from a JSON object, as LoadDirectionsFile reads a
/// file.</summary>
/// <param name="AValue">The object, such as one DirectionsToJson made.</param>
/// <param name="ACount">Set to the number of directions, one of DIRECTION_COUNTS.</param>
/// <param name="AStart">Set to the red marker's bearing, wrapped into 0 up to 360.</param>
/// <param name="AOrder">Set to the order, as positions from 0, every one once.</param>
/// <param name="ASnap">Set to whether the dial is locked to steps of one
/// direction.</param>
/// <exception cref="EDirectionsFile">If AValue is not an object of directions, or holds a
/// count or order that cannot be used; the message says which.</exception>
procedure DirectionsFromJson(const AValue: TJSONValue; out ACount: Integer;
  out AStart: Single; out AOrder: TArray<Integer>; out ASnap: Boolean);

//** @abstract(Whether a file is a Sprite3D project file, judged by its extension,
//** PROJECT_FILE_EXTENSION.)
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True if its extension is PROJECT_FILE_EXTENSION, in any case.)
/// <summary>Whether a file is a Sprite3D project file, judged by its extension,
/// PROJECT_FILE_EXTENSION.</summary>
/// <param name="AFileName">A file name or path.</param>
/// <returns>True if its extension is PROJECT_FILE_EXTENSION, in any case.</returns>
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
/// <summary>Credits as the <c>credits</c> object of a project file.</summary>
/// <remarks>Members are <c>creator</c>, <c>creator_url</c>, <c>modeller</c>,
/// <c>modeller_url</c>, <c>artist</c>, <c>artist_url</c> and <c>created</c>; empty ones are
/// written as <c>null</c>. The caller owns the object.</remarks>
/// <param name="ACredits">The credits.</param>
/// <returns>The object.</returns>
function CreditsToJson(const ACredits: TSprite3DCredits): TJSONObject;

//** @abstract(Reads credits from the @code(credits) object of a project file.)
//**
//** Members left out, @code(null) or not text are read as empty.
//**
//** @param(AValue The object; anything else gives empty credits.)
//**
//** @returns(The credits.)
/// <summary>Reads credits from the <c>credits</c> object of a project file.</summary>
/// <remarks>Members left out, <c>null</c> or not text are read as empty.</remarks>
/// <param name="AValue">The object; anything else gives empty credits.</param>
/// <returns>The credits.</returns>
function CreditsFromJson(const AValue: TJSONValue): TSprite3DCredits;

//** @abstract(Formats an angle from Wrap360 as whole degrees for a readout.)
//**
//** Rounds to the nearest degree, so 359.6 shows as 0, never 360, and pads to three
//** characters so readouts stay the same width.
//**
//** @param(ADegrees An angle from 0 up to 360.)
//**
//** @returns(The angle as text, such as @code('  0') or @code(' 45').)
/// <summary>Formats an angle from Wrap360 as whole degrees for a readout.</summary>
/// <remarks>Rounds to the nearest degree, so 359.6 shows as 0, never 360, and pads to three
/// characters so readouts stay the same width.</remarks>
/// <param name="ADegrees">An angle from 0 up to 360.</param>
/// <returns>The angle as text, such as <c>'  0'</c> or <c>' 45'</c>.</returns>
function DegreesText(const ADegrees: Single): String;

//** @abstract(The folder that holds the application's models folder, for this platform.)
//**
//** The library path on macOS, the home folder on Linux and @code('../../../') elsewhere;
//** on Windows it is the current folder instead, returned as an empty string, if that has a
//** models subfolder.
//**
//** @returns(A folder path ending in a path delimiter, or empty for the current folder.)
/// <summary>The folder that holds the application's models folder, for this
/// platform.</summary>
/// <remarks>The library path on macOS, the home folder on Linux and <c>'../../../'</c>
/// elsewhere; on Windows it is the current folder instead, returned as an empty string, if
/// that has a models subfolder.</remarks>
/// <returns>A folder path ending in a path delimiter, or empty for the current
/// folder.</returns>
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
/// <summary>The folder grabs are saved in without asking, or empty where the user should
/// choose.</summary>
/// <remarks>Android and iOS have no folder dialog, so there grabs go to a fixed Grabs folder
/// the user can reach: under the app's public storage on Android, which shows over USB or in a
/// file manager, and under its Documents folder on iOS, which shows in the Files app once the
/// app enables file sharing in its Info.plist. Elsewhere this returns an empty
/// string.</remarks>
/// <returns>The fixed grab folder on Android and iOS; an empty string on other
/// platforms.</returns>
function DefaultGrabFolder: String;

//** @abstract(The @code(openh264.json) that gives OpenH264's download address for each
//** platform, or empty if there is none.)
//**
//** Looked for where it is deployed, the folder GetAssetsPath gives (beside the executable on
//** Windows and Linux, the bundle's Resources folder on macOS, the app's files folder on
//** Android), then beside the executable and in each of the six folders above it, which finds
//** the repository's copy when run from the source tree. iOS does not allow downloaded code
//** to be loaded, so there it is always empty.
//**
//** @returns(The file's full path, or an empty string.)
/// <summary>The <c>openh264.json</c> that gives OpenH264's download address for each
/// platform, or empty if there is none.</summary>
/// <remarks>Looked for where it is deployed, the folder GetAssetsPath gives (beside the
/// executable on Windows and Linux, the bundle's Resources folder on macOS, the app's files
/// folder on Android), then beside the executable and in each of the six folders above it,
/// which finds the repository's copy when run from the source tree. iOS does not allow
/// downloaded code to be loaded, so there it is always empty.</remarks>
/// <returns>The file's full path, or an empty string.</returns>
function OpenH264ConfigFile: String;

//** @abstract(Where downloaded copies of OpenH264 are kept: an @code(openh264) folder in
//** SupportFolder.)
//**
//** Per user and private to the application on every platform; created when the first copy
//** is saved.
//**
//** @returns(The folder's full path.)
/// <summary>Where downloaded copies of OpenH264 are kept: an <c>openh264</c> folder in
/// SupportFolder.</summary>
/// <remarks>Per user and private to the application on every platform; created when the first
/// copy is saved.</remarks>
/// <returns>The folder's full path.</returns>
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
/// <summary>The first free numbered file name in a folder, such as grab001.png.</summary>
/// <remarks>Starts at ANumber and moves it past every name already taken, so an existing file
/// is never chosen. Numbers have at least three digits. The file is not created.</remarks>
/// <param name="AFolder">The folder to look in.</param>
/// <param name="APrefix">The start of the file name, such as <c>'grab'</c>.</param>
/// <param name="AExtension">The extension, with its dot, such as <c>'.png'</c>.</param>
/// <param name="ANumber">The number to try first; on return, the number of the name
/// returned.</param>
/// <returns>The full path of the first name that does not exist yet.</returns>
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
/// <summary>Saves a grab as the next free grabNNN.png in a folder.</summary>
/// <remarks>Creates the folder if needed, picks the name with NextNumberedFileName starting
/// at ANumber, saves ABitmap there as PNG and moves ANumber on to the next number. Blocks
/// while the file is written.</remarks>
/// <param name="ABitmap">The image to save; it is not freed.</param>
/// <param name="AFolder">The folder to save in.</param>
/// <param name="ANumber">The number to try first; on return, one past the number used.
/// Unchanged if the save fails.</param>
/// <returns>The full path of the file written.</returns>
/// <exception cref="Exception">If the folder cannot be created or the file cannot be
/// written; the class depends on the cause.</exception>
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
/// <summary>Replaces a model's contents with a model file and starts its last
/// animation.</summary>
/// <remarks>Clears AModel, loads AFileName into it, and, if the file has animations, plays the
/// one whose name sorts last. Blocks while the file loads.</remarks>
/// <param name="AModel">The model to load into; its old contents are removed first.</param>
/// <param name="AFileName">A glTF, FBX, OBJ, USD, Collada, STL or PLY file.</param>
/// <param name="ABox">The model's bounding box straight after loading, before anything is
/// added to it or it is moved; pass it to PlaceModel.</param>
/// <returns>The names of the model's animations in sorted order; empty if it has
/// none.</returns>
/// <exception cref="Exception">If the file cannot be read or loaded; AModel is then left
/// cleared or part-loaded.</exception>
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
/// <summary>Centres a loaded model on its bounding box and turns it right way up.</summary>
/// <remarks>Moves AModel to the centre of ABox and turns it 180 degrees about X, which the
/// application's models need to stand upright.</remarks>
/// <param name="AModel">The model to place.</param>
/// <param name="ABox">The box LoadModelFile returned for it.</param>
procedure PlaceModel(const AModel: TGorillaModel; const ABox: TBoundingBox);

//** @abstract(Whether a file is a model LoadModelFile can load, judged by its extension.)
//**
//** The extensions are those of the loaders this unit registers: .glb, .gltf, .fbx, .obj,
//** .usdc, .dae, .stl and .ply, in any case. The file's contents are not checked.
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True if its extension is one of the model formats.)
/// <summary>Whether a file is a model LoadModelFile can load, judged by its
/// extension.</summary>
/// <remarks>The extensions are those of the loaders this unit registers: .glb, .gltf, .fbx,
/// .obj, .usdc, .dae, .stl and .ply, in any case. The file's contents are not
/// checked.</remarks>
/// <param name="AFileName">A file name or path.</param>
/// <returns>True if its extension is one of the model formats.</returns>
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
/// <summary>The model to load at start-up: the first one the system asked to open, or
/// ADefault.</summary>
/// <param name="ARequested">The files the operating system asked the application to open,
/// oldest first, as Sprite3DOpenFiles collects them; files that are not models are
/// skipped.</param>
/// <param name="ADefault">The model to load when none was asked for.</param>
/// <returns>The first model in ARequested, or ADefault if it holds none.</returns>
function StartupModelFile(const ARequested: TArray<String>;
  const ADefault: String): String;

type
  //** @abstract(A read of a model file on a worker thread, from StartModelFileRead.)
  //**
  //** Every member may be called from the main thread while the read goes on. The worker holds
  //** its own reference, so letting go of this one, or cancelling, never leaves it reading
  //** freed memory.
  /// <summary>A read of a model file on a worker thread, from StartModelFileRead.</summary>
  /// <remarks>Every member may be called from the main thread while the read goes on. The
  /// worker holds its own reference, so letting go of this one, or cancelling, never leaves
  /// it reading freed memory.</remarks>
  IModelFileRead = interface
    ['{3E8B6A51-2C4D-4F7A-9E1B-5D7C8A9F0B24}']
    //** @abstract(Asks the worker to stop at the next block; Done follows soon after.)
    /// <summary>Asks the worker to stop at the next block; Done follows soon
    /// after.</summary>
    procedure Cancel;
    //** @abstract(True once the worker has stopped: read to the end, cancelled, or failed.)
    //**
    //** @returns(Whether the read is over.)
    /// <summary>True once the worker has stopped: read to the end, cancelled, or
    /// failed.</summary>
    /// <returns>Whether the read is over.</returns>
    function Done: Boolean;
    //** @abstract(How many bytes have been read so far.)
    //**
    //** @returns(The count, from 0 to TotalBytes.)
    /// <summary>How many bytes have been read so far.</summary>
    /// <returns>The count, from 0 to TotalBytes.</returns>
    function BytesRead: Int64;
    //** @abstract(The file's size in bytes; 0 until the file has been opened.)
    //**
    //** @returns(The size.)
    /// <summary>The file's size in bytes; 0 until the file has been opened.</summary>
    /// <returns>The size.</returns>
    function TotalBytes: Int64;
    //** @abstract(Why the read failed, once Done; empty if it did not.)
    //**
    //** @returns(The error message, or an empty string.)
    /// <summary>Why the read failed, once Done; empty if it did not.</summary>
    /// <returns>The error message, or an empty string.</returns>
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
/// <summary>Starts reading a model file from start to end on a worker thread.</summary>
/// <remarks>Nothing is kept: the point is to bring the file into the operating system's
/// file cache, which is where a cold load spends most of its time, while the user interface
/// goes on and the read can be cancelled; Gorilla3D's own load, which cannot, then finds it
/// there. The file is read in blocks of a megabyte, shared for reading and
/// writing.</remarks>
/// <param name="AFileName">The file to read.</param>
/// <returns>The read under way.</returns>
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
/// <summary>Where the measured animation bounds of a model file are kept between
/// sessions.</summary>
/// <remarks>A file in the bounds folder of SupportFolder, named from a hash of the model's
/// full path, size and time of last change, so a model that is changed or replaced gets a
/// new file and its old figures are never used. Nothing is created.</remarks>
/// <param name="AModelFile">The model file; it must exist.</param>
/// <returns>The cache file's path, or empty if the model file cannot be found.</returns>
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
/// <summary>Reads the animation bounds saved for a model file, so they need not be measured
/// again.</summary>
/// <remarks>The figures are used only if they were saved for exactly the animations named,
/// in any order, and by this version of the cache; anything else, a damaged file included,
/// gives False and leaves the model to be measured.</remarks>
/// <param name="AModelFile">The model file, as loaded.</param>
/// <param name="ANames">Every animation the model has, as LoadModelFile listed them.</param>
/// <param name="ABounds">The figures, in the order they were saved; empty when False, and
/// without any animation that had no pose to measure.</param>
/// <returns>True if usable figures were read.</returns>
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
/// <summary>Saves a model file's measured animation bounds for the next time it is
/// loaded.</summary>
/// <remarks>Writes AnimationBoundsCacheFile as JSON, making the folder if need be. A failure
/// to write is ignored: the model is simply measured again next time.</remarks>
/// <param name="AModelFile">The model file the figures were measured from.</param>
/// <param name="ANames">Every animation the model has, as LoadModelFile listed
/// them.</param>
/// <param name="ABounds">The figures, as TAnimationBoundsMeasurer gave them.</param>
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
/// <summary>The file an icon is saved to without asking, or empty where the user should
/// choose.</summary>
/// <remarks>Android and iOS have no save dialog, so there icons go to the next free
/// <c>iconNNN</c> name, with AExtension, in DefaultGrabFolder. Elsewhere this returns an empty
/// string, and the user picks the file.</remarks>
/// <param name="AExtension">The icon format's extension, with its dot, such as
/// <c>'.ico'</c>.</param>
/// <returns>The full path on Android and iOS; an empty string on other platforms.</returns>
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
/// <summary>How far to move the orbit centre for a camera pan.</summary>
/// <remarks>The pan runs along the model's own X and Z axes, as View, Show axes draws them, so
/// it never moves the view up or down the model's Y axis. Each amount is a multiple of the
/// model's radius, half the diagonal of ABox, so a pan looks the same for a model of any
/// size. The camera's angles and distance are not involved.</remarks>
/// <param name="AModel">The model; nil gives no offset.</param>
/// <param name="ABox">The model's own bounds as loaded, for its size.</param>
/// <param name="APanX">The pan along the model's X axis; limited to PAN_LIMIT either
/// way.</param>
/// <param name="APanZ">The pan along the model's Z axis; limited to PAN_LIMIT either
/// way.</param>
/// <returns>The offset to add to the fitted orbit centre, in the viewport's space.</returns>
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
/// <summary>Gives the whole application, title bars included, the look ATheme
/// names.</summary>
/// <remarks>thDefault puts back FMX's own platform style and the system's title bars. The
/// other themes are the FMX styles that come with RAD Studio: Dark.style, AquaGraphite.style,
/// RubyGraphite.style and GoldenGraphite.style. Each is looked for as a linked-in RCDATA
/// resource called <c>Sprite3D&lt;Name&gt;Style</c>, such as <c>Sprite3DDarkStyle</c>, which
/// <c>styles\Sprite3DThemes.rc</c> links into every build, then, should that be missing,
/// as a file in a <c>styles</c> folder beside the program or its assets, beside the program,
/// in a <c>styles</c> folder in SupportFolder, or, on Windows, in RAD Studio's
/// <c>Redist\styles\Fmx</c> folder when the BDS environment variable is set, as it is when
/// run from the IDE. Once the style is in use, the title bars take its form background
/// colour, with the theme's accent as the window border, where the system allows; see
/// Sprite3DTitleBar.</remarks>
/// <param name="ATheme">The look to use.</param>
/// <param name="AError">On failure, why, including where it looked.</param>
/// <returns>True if the look is now in use; False leaves the current one, title bars
/// included.</returns>
function ApplyTheme(const ATheme: TSprite3DTheme; out AError: String): Boolean;

//** @abstract(A new TSprite3DFileAssociations for the model files this application opens.)
//**
//** The caller owns the result and frees it.
//**
//** @returns(The associations object, set up for every extension IsModelFile accepts.)
/// <summary>A new TSprite3DFileAssociations for the model files this application
/// opens.</summary>
/// <remarks>The caller owns the result and frees it.</remarks>
/// <returns>The associations object, set up for every extension IsModelFile
/// accepts.</returns>
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
/// <summary>Registers or unregisters the application for model files as asked, keeping what
/// is needed to undo it in ASettings.</summary>
/// <remarks>In order: registers for Open With if AOpenWith; makes the application the default
/// if AAlways, recording the old defaults in ASettings.AssociationBackup, or otherwise puts
/// back the recorded defaults if it was the default; and unregisters if not AOpenWith.
/// AAlways counts only with AOpenWith, except on macOS, where Open With is fixed by the
/// bundle. Where the user has to confirm a default in the system's own settings, that page is
/// opened and AMessage says so. ASettings.OpenWith and AlwaysOpenWith are updated to the
/// result; the caller saves ASettings.</remarks>
/// <param name="ASettings">The application's settings, for the backup.</param>
/// <param name="AOpenWith">Whether to be offered under Open With.</param>
/// <param name="AAlways">Whether to be the default for model files.</param>
/// <param name="AMessage">Anything the user should be told, failures included; empty if
/// nothing.</param>
/// <returns>True if every step succeeded.</returns>
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
/// <summary>Makes Sprite3D open its own project files, PROJECT_FILE_EXTENSION, when one is
/// double-clicked.</summary>
/// <remarks>Called each time the application starts, so the files open with the copy of the
/// program last run, whatever is chosen for model files in File, Settings. On Windows the
/// extension gets a ProgID of its own, <c>Sprite3D.Project</c>, and is made to open with it;
/// a choice made with Always in Windows' own How do you want to open dialog still wins. On
/// Linux the project MIME type, <c>application/x-sprite3d</c>, goes into the application's
/// desktop entry, with the model types if they are registered, and is made to open with it.
/// On macOS the bundle's document types do this, and elsewhere there are no associations,
/// so it does nothing.</remarks>
/// <param name="AMessage">Set to what went wrong; empty if nothing did.</param>
/// <returns>True on success, or where there is nothing to do.</returns>
function RegisterProjectFiles(out AMessage: String): Boolean;

//** @abstract(True where the GPU preference can be set: Windows only.)
//**
//** @returns(True on Windows.)
/// <summary>True where the GPU preference can be set: Windows only.</summary>
/// <returns>True on Windows.</returns>
function GpuModeSupported: Boolean;

//** @abstract(The GPU preference Windows has for this program file now.)
//**
//** @returns(The preference, or gmSystem where there is none or the platform has none.)
/// <summary>The GPU preference Windows has for this program file now.</summary>
/// <returns>The preference, or gmSystem where there is none or the platform has
/// none.</returns>
function ReadGpuMode: TSprite3DGpuMode;

//** @abstract(Asks Windows for a GPU for this program file, from the next start.)
//**
//** gmSystem removes the program's entry, handing the choice back to Windows. Uses
//** GpuPreference.SetGpuPreference.
//**
//** @param(AMode The preference.)
//**
//** @returns(True if it was stored; always False where GpuModeSupported is False.)
/// <summary>Asks Windows for a GPU for this program file, from the next start.</summary>
/// <remarks>gmSystem removes the program's entry, handing the choice back to Windows. Uses
/// GpuPreference.SetGpuPreference.</remarks>
/// <param name="AMode">The preference.</param>
/// <returns>True if it was stored; always False where GpuModeSupported is False.</returns>
function WriteGpuMode(const AMode: TSprite3DGpuMode): Boolean;

//** @abstract(The File, Settings choices as they stand now.)
//**
//** Open With, the default application and the GPU preference are read from the system,
//** where it can say; the rest come from ASettings.
//**
//** @param(ASettings The application's settings.)
//**
//** @returns(The choices.)
/// <summary>The File, Settings choices as they stand now.</summary>
/// <remarks>Open With, the default application and the GPU preference are read from the
/// system, where it can say; the rest come from ASettings.</remarks>
/// <param name="ASettings">The application's settings.</param>
/// <returns>The choices.</returns>
function ReadGeneralSettings(const ASettings: TSprite3DAppSettings): TSprite3DGeneralSettings;

implementation

uses
  System.Classes, System.Math, System.IOUtils, System.Hash, System.StrUtils,
  System.Threading, System.SyncObjs, System.Generics.Collections,
  OSPaths, JsonText, Sprite3DStyles, Sprite3DTitleBar,
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
  FExportAutoClose := False;
  FLastExportFolder := String.Empty;
  FOverscan := OVERSCAN_FACTOR_DEFAULT;
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

const
  OPENH264_CONFIG_NAME = 'openh264.json';

function OpenH264ConfigFile: String;
{$IFNDEF IOS}
var
  Dir, Parent: String;
  Level: Integer;
{$ENDIF}
begin
  Result := String.Empty;
  {$IFNDEF IOS}
  Result := TPath.Combine(GetAssetsPath, OPENH264_CONFIG_NAME);
  if TFile.Exists(Result) then
    Exit;
  {$IFNDEF ANDROID}
  // Run from the source tree: the repository's copy, a few levels up
  Dir := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  for Level := 0 to 6 do
  begin
    Result := TPath.Combine(Dir, OPENH264_CONFIG_NAME);
    if TFile.Exists(Result) then
      Exit;
    Parent := ExtractFileDir(Dir);
    if (Parent = String.Empty) or (Parent = Dir) then
      Break;
    Dir := Parent;
  end;
  {$ENDIF}
  Result := String.Empty;
  {$ENDIF}
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
{$IF DEFINED(MSWINDOWS) or (DEFINED(LINUX) and not DEFINED(ANDROID))}
var
  Project, Models: TSprite3DFileAssociations;
{$ENDIF}
begin
  AMessage := String.Empty;
  Result := True;
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
  // The caller knows the display; until it says, at least the rate in use
  Result.MaxViewFps := Max(ASettings.ViewFps, VIEW_FPS_DEFAULT);
  if GpuModeSupported then
    Result.GpuMode := ReadGpuMode
  else
    Result.GpuMode := ASettings.GpuMode;
end;

end.
