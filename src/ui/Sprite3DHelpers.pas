//** @abstract(Support routines for the Sprite3D application that are neither UI nor library.)
//**
//** The application keeps three kinds of code apart. The units in @code(ui) only handle the
//** user interface; the units in @code(lib) are a library with no knowledge of this
//** application, usable in other projects; and this unit holds what is left: the
//** application's own rules, such as where models are found, how grabs are named and saved,
//** and how a loaded model is placed. It uses the library and the RTL, never the UI.
//**
//** TSprite3DAppSettings holds the settings kept between sessions, in @code(settings.json)
//** in the application's own per-user folder, SupportFolder.
//**
//** Loading a model through LoadModelFile also registers Gorilla3D's loaders for glTF, FBX,
//** OBJ, USD, Collada, STL and PLY files, as this unit uses them.
//**
//** All routines are for the main thread.
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

  Loading a model through LoadModelFile also registers Gorilla3D's loaders
  for glTF, FBX, OBJ, USD, Collada, STL and PLY files, as this unit uses
  them.

  All routines are for the main thread.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math.Vectors,
  FMX.Graphics, FMX.Types3D, FMX.Controls3D,
  Gorilla.Model, Sprite3DStorage, Sprite3DBackground, Sprite3DFileAssoc;

const
  //** @abstract(The application's name, used for its per-user folder.)
  /// <summary>The application's name, used for its per-user folder.</summary>
  APP_NAME = 'Sprite3D';
  //** @abstract(The name of the settings file in SupportFolder.)
  /// <summary>The name of the settings file in SupportFolder.</summary>
  SETTINGS_FILE_NAME = 'settings.json';
  //** @abstract(The largest camera pan either way, as a multiple of the model's radius.)
  //**
  //** The radius is half the diagonal of the model's bounding box, so a pan of 1 moves the
  //** orbit centre out to where the model's farthest corner was.
  /// <summary>The largest camera pan either way, as a multiple of the model's
  /// radius.</summary>
  /// <remarks>The radius is half the diagonal of the model's bounding box, so a pan of 1
  /// moves the orbit centre out to where the model's farthest corner was.</remarks>
  PAN_LIMIT = 2.0;
  //** @abstract(The lowest frame rate File, Animation offers for saved animations, in frames
  //** per second.)
  /// <summary>The lowest frame rate File, Animation offers for saved animations, in frames per
  /// second.</summary>
  ANIMATION_FPS_MIN = 1;
  //** @abstract(The highest frame rate File, Animation offers for saved animations, in frames
  //** per second.)
  //**
  //** Gorilla bakes animations at 60 frames a second on desktop, so a higher rate would only
  //** repeat frames.
  /// <summary>The highest frame rate File, Animation offers for saved animations, in frames
  /// per second.</summary>
  /// <remarks>Gorilla bakes animations at 60 frames a second on desktop, so a higher rate
  /// would only repeat frames.</remarks>
  ANIMATION_FPS_MAX = 60;
  //** @abstract(The frame rate saved animations use until File, Animation changes it.)
  /// <summary>The frame rate saved animations use until File, Animation changes
  /// it.</summary>
  ANIMATION_FPS_DEFAULT = 30;
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
    FFitAnyAngle: Boolean;
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
    procedure SetAnimationFps(const Value: Integer);
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
    //** @abstract(Whether View, Fit any angle is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(fitAnyAngle).
    /// <summary>Whether View, Fit any angle is ticked on the main form; False by
    /// default.</summary>
    /// <remarks>Stored as <c>fitAnyAngle</c>.</remarks>
    property FitAnyAngle: Boolean read FFitAnyAngle write FFitAnyAngle;
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
    //** Set in File, Animation. Stored as @code(animationFps). Written values are limited to
    //** ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.
    /// <summary>The frame rate animations are saved at, in frames per second;
    /// ANIMATION_FPS_DEFAULT by default.</summary>
    /// <remarks>Set in File, Animation. Stored as <c>animationFps</c>. Written values are
    /// limited to ANIMATION_FPS_MIN to ANIMATION_FPS_MAX.</remarks>
    property AnimationFps: Integer read FAnimationFps write SetAnimationFps;
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
  System.Classes, System.Math, System.IOUtils,
  OSPaths, Sprite3DStyles, Sprite3DTitleBar,
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
  SetBackgroundSpec(TSprite3DBackgroundSpec.Default);
  // As the main form's check boxes start; a settings.json without these
  // keys leaves them so
  FShowBoundingBox := True;
  FShowGrid := True;
  FShowAxes := True;
  FFitAnyAngle := False;
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
end;

procedure TSprite3DAppSettings.SetAnimationFps(const Value: Integer);
begin
  FAnimationFps := EnsureRange(Value, ANIMATION_FPS_MIN, ANIMATION_FPS_MAX);
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
  Result := AppDataFolder(APP_NAME);
end;

function TSprite3DAppSettings.HasSaveFolder: Boolean;
begin
  Result := (FSaveFolder <> String.Empty) and DirectoryExists(FSaveFolder);
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
begin
  // Work on a copy, so ANumber is untouched if anything below fails
  Number := ANumber;
  ForceDirectories(AFolder);
  Result := NextNumberedFileName(AFolder, 'grab', '.png', Number);
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
  AModel.LoadFromFile(nil, AFileName, [TAnimationCachingFlag.VertexPosition]);

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

function CreateModelAssociations: TSprite3DFileAssociations;
var
  Types: TArray<TSprite3DFileType>;
  I: Integer;
begin
  SetLength(Types, Length(MODEL_EXTENSIONS));
  for I := 0 to High(MODEL_EXTENSIONS) do
    Types[I] := TSprite3DFileType.Create(MODEL_EXTENSIONS[I], MODEL_MIME_TYPES[I],
      MODEL_DESCRIPTIONS[I]);
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
  if GpuModeSupported then
    Result.GpuMode := ReadGpuMode
  else
    Result.GpuMode := ASettings.GpuMode;
end;

end.
