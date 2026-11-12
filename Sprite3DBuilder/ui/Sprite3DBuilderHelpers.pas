//** @abstract(Support routines for the Sprite3DBuilder application that are neither UI nor
//** library.)
//**
//** The application keeps three kinds of code apart. The units in @code(ui) only handle the
//** user interface; the units in @code(lib) are a library with no knowledge of this
//** application, usable in other projects; and this unit holds what is left: the
//** application's own rules, such as where the asset kits are found and what settings are
//** kept. It uses the library and the RTL, never the UI.
//**
//** TSprite3DAppSettings holds the settings kept between sessions, in @code(settings.json)
//** in the application's own per-user folder, SupportFolder.
//**
//** AssetsFolder finds the @code(assets) folder the kits are kept in, and AssetModelFiles
//** lists the models in one of its folders. Loading a model through LoadModelFile also
//** registers Gorilla3D's loaders for glTF, FBX, OBJ, USD, Collada, STL and PLY files, as
//** this unit uses them.
//**
//** All routines are for the main thread, except the members of IModelFileRead.
unit Sprite3DBuilderHelpers;

{
  Support routines for the Sprite3DBuilder application that are neither UI
  nor library.

  The application keeps three kinds of code apart. The units in ui only
  handle the user interface; the units in lib are a library with no
  knowledge of this application, usable in other projects; and this unit
  holds what is left: the application's own rules, such as where the asset
  kits are found and what settings are kept. It uses the library and the
  RTL, never the UI.

  TSprite3DAppSettings holds the settings kept between sessions, in
  settings.json in the application's own per-user folder, SupportFolder.

  AssetsFolder finds the assets folder the kits are kept in, and
  AssetModelFiles lists the models in one of its folders. Loading a model
  through LoadModelFile also registers Gorilla3D's loaders for glTF, FBX,
  OBJ, USD, Collada, STL and PLY files, as this unit uses them.

  All routines are for the main thread, except the members of
  IModelFileRead.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math.Vectors,
  FMX.Graphics, FMX.Types3D, FMX.Controls3D,
  System.JSON, Gorilla.Model, Sprite3DStorage, Neon.Core.Attributes;

const
  //** @abstract(The application's name, used for its per-user folder.)
  APP_NAME = 'Sprite3DBuilder';
  //** @abstract(The name of the settings file in SupportFolder.)
  SETTINGS_FILE_NAME = 'settings.json';
  //** @abstract(The largest shift or rise either way, as a fraction of how far the picture
  //** can slide.)
  //**
  //** 1 slides it until the near side of the model's fitted volume is on that edge of the
  //** picture: the model just gone off it.
  PAN_LIMIT = 1.0;
  //** @abstract(The lowest frame rate File, Settings lets the view be drawn at.)
  VIEW_FPS_MIN = 1;
  //** @abstract(The highest frame rate kept for the view; File, Settings offers no more than
  //** the display's refresh rate.)
  VIEW_FPS_MAX = 1000;
  //** @abstract(The frame rate the view is drawn at until File, Settings changes it, and the
  //** most it offers where the display's refresh rate is not known.)
  VIEW_FPS_DEFAULT = 60;
  //** @abstract(The level grid's spacing until settings.json says otherwise: a small floor
  //** tile of the dungeon kit, 2 units across.)
  GRID_SIZE_DEFAULT = 2.0;
  //** @abstract(The smallest grid spacing settings.json may give.)
  GRID_SIZE_MIN = 0.01;
  //** @abstract(The largest grid spacing settings.json may give.)
  GRID_SIZE_MAX = 1000.0;
  //** @abstract(The name of the folder the asset kits are kept in, off the repository root.)
  ASSETS_FOLDER_NAME = 'assets';
  //** @abstract(The width and height of every asset thumbnail, in pixels.)
  //**
  //** A cached thumbnail of another size is made again, so changing this remakes them all.
  THUMBNAIL_SIZE = 128;
  //** @abstract(The name of the thumbnail cache's folder in SupportFolder, beside
  //** settings.json.)
  THUMBNAIL_FOLDER_NAME = 'thumbnails';
  //** @abstract(The folder of group icons: in SupportFolder for the user's own, and, below
  //** an @code(icons) folder beside the program or above it, for those that come with it;
  //** see GroupIconsFolder.)
  GROUP_ICONS_FOLDER_NAME = 'groups';
  //** @abstract(The folder holding GROUP_ICONS_FOLDER_NAME beside the program or above it.)
  ICONS_FOLDER_NAME = 'icons';

type
  //** @abstract(The application's look: FMX's own default style, or one of the FMX styles
  //** that come with RAD Studio.)
  //**
  //** @code(thDefault) is the platform's own style. @code(thDark) is Dark.style; the others
  //** are the coloured Graphite styles, dark grey with an accent: @code(thAquaGraphite) blue,
  //** @code(thRubyGraphite) red and @code(thGoldenGraphite) gold.
  TSprite3DTheme = (thDefault, thDark, thAquaGraphite, thRubyGraphite, thGoldenGraphite);

  //** @abstract(The projection chosen in View, Projection on the main form.)
  //**
  //** Perspective and orthographic are the camera's own (its ProjectionMode). The four
  //** oblique projections are drawn by the Spritely package's TSpritelyProjection, with the
  //** camera in perspective: the picture is made from what the perspective shows at the
  //** orbit centre's distance, with depth drawn across it. Cavalier draws depth at full
  //** length at 45 degrees, cabinet at half length at 63.43 degrees (2 in 1), military at
  //** full length straight down the picture (with the camera looking straight down, height
  //** goes straight up and the plan keeps its shape), and plan oblique at full length down
  //** and to the right (with the camera straight down and the plan square to the picture,
  //** height goes up and to the left at 45 degrees). The camera's angles are left to View,
  //** Camera: these look as intended from Head On (cavalier, cabinet) and Top Down (military,
  //** plan oblique).
  TSprite3DProjection = (
    //** @abstract(The camera's own perspective.)
    prPerspective,
    //** @abstract(The camera's own orthographic projection.)
    prOrthographic,
    //** @abstract(Oblique: depth at full length, at 45 degrees.)
    prCavalier,
    //** @abstract(Oblique: depth at half length, at 63.43 degrees.)
    prCabinet,
    //** @abstract(Oblique: depth at full length, straight down the picture.)
    prMilitary,
    //** @abstract(Oblique: depth at full length, down and to the right, so height goes up and
    //** to the left.)
    prPlanOblique);

  //** @abstract(How a TSprite3DProjection is named in each place it appears.)
  TSprite3DProjectionInfo = record
    //** @abstract(In settings.json and as the menu item's name: Perspective, Orthographic,
    //** Cavalier, Cabinet, Military, PlanOblique.)
    Key: String;
    //** @abstract(As the menu, the window caption and the Debug tab show it.)
    Caption: String;
  end;

  //** @abstract(Which graphics processor Windows gives the application.)
  //**
  //** @code(gmSystem) lets Windows decide; @code(gmPowerSaving) asks for the low-power GPU and
  //** @code(gmHighPerformance) for the high-performance one. Used on Windows only, and only
  //** after the application is restarted.
  TSprite3DGpuMode = (gmSystem, gmPowerSaving, gmHighPerformance);

  //** @abstract(The choices made in File, Settings, together.)
  TSprite3DGeneralSettings = record
    //** @abstract(The application's look.)
    Theme: TSprite3DTheme;
    //** @abstract(The graphics processor asked for; Windows only.)
    GpuMode: TSprite3DGpuMode;
    //** @abstract(The frame rate the view is drawn at, VIEW_FPS_MIN to MaxViewFps.)
    ViewFps: Integer;
    //** @abstract(Whether JSON files are written minified.)
    MinifyJson: Boolean;
    //** @abstract(The most ViewFps may be: the display's refresh rate, set by the caller; not
    //** kept.)
    MaxViewFps: Integer;
  end;

  //** @abstract(Protected-access helper for TControl3D; nothing in the project uses it yet.)
  //**
  //** Casting a TControl3D to this class exposes its protected members inside the unit that
  //** declares the cast. Because it is in the interface section, other units can use it too.
  TControl3DAccess = class(TControl3D);

  //** @abstract(The application's settings, kept between sessions in settings.json.)
  //**
  //** Create it, call Load once at start-up, and call Save after changing a setting. The file
  //** is @code(settings.json) in SupportFolder; on the first run it does not exist yet, so
  //** every setting keeps its default until the first Save. For the main thread only.
  //**
  //** @seealso(TSprite3DJsonSettings)
  TSprite3DAppSettings = class(TSprite3DJsonSettings)
  private
    FShowBoundingBox: Boolean;
    FOrthographic: Boolean;
    //** @abstract(Backing fields for Headlight and OriginalLight.)
    FHeadlight, FOriginalLight: Boolean;
    //** @abstract(Backing field for Projection.)
    FProjection: String;
    FCameraView: String;
    FVariableAzimuth: Single;
    FVariableInclination: Single;
    FVariableRoll: Single;
    FPanEnabled: Boolean;
    FPanX: Single;
    FPanZ: Single;
    FKeepShift: Boolean;
    FDistanceFactor: Single;
    FTheme: String;
    FGpuMode: TSprite3DGpuMode;
    FViewFps: Integer;
    FMinifyJson: Boolean;
    FMouseView: Boolean;
    //** @abstract(Backing fields for GridSize, AssetFolder and PreviewBackground.)
    FGridSize: Single;
    FAssetFolder: String;
    FPreviewBackground: String;
    procedure SetViewFps(const Value: Integer);
    procedure SetMinifyJson(const Value: Boolean);
    //** @abstract(Setter for GridSize: keeps it within GRID_SIZE_MIN to GRID_SIZE_MAX.)
    //**
    //** @param(Value The spacing wanted.)
    procedure SetGridSize(const Value: Single);
    function GetThemeKind: TSprite3DTheme;
    procedure SetThemeKind(const Value: TSprite3DTheme);
    //** @abstract(Getter for ProjectionKind.)
    function GetProjectionKind: TSprite3DProjection;
    //** @abstract(Setter for ProjectionKind.)
    procedure SetProjectionKind(const Value: TSprite3DProjection);
  public
    //** @abstract(Creates the settings with their defaults, for settings.json in
    //** SupportFolder.)
    //**
    //** Nothing is read until Load is called.
    constructor Create; reintroduce;
    //** @abstract(The application's per-user folder, for settings.json and support files.)
    //**
    //** AppDataFolder for APP_NAME: for example @code(%APPDATA%\Sprite3DBuilder) on Windows. It is
    //** created by the first Save.
    //**
    //** @returns(The folder's full path, without a trailing path delimiter.)
    class function SupportFolder: String; static;
    //** @abstract(The thumbnail cache: THUMBNAIL_FOLDER_NAME in SupportFolder, beside
    //** settings.json; see Sprite3DAssetCache.)
    //**
    //** Made when the first thumbnail is saved.
    //**
    //** @returns(The folder's full path, without a trailing path delimiter.)
    class function ThumbnailFolder: String; static;
    //** @abstract(The user's own group icons: @code(icons/groups) in SupportFolder.)
    //**
    //** An icon chosen from elsewhere is copied here. Made when the first is.
    //**
    //** @returns(The folder's full path, without a trailing path delimiter.)
    class function UserGroupIconsFolder: String; static;
    //** @abstract(Theme as a TSprite3DTheme.)
    //**
    //** A name in settings.json that is not one of the themes, such as one from an older
    //** version, reads as thDefault.
    property ThemeKind: TSprite3DTheme read GetThemeKind write SetThemeKind;
    //** @abstract(Projection as a TSprite3DProjection.)
    //**
    //** A settings.json without @code(projection), as earlier versions wrote, reads as
    //** prOrthographic if its @code(orthographic) is true and prPerspective if not; a name
    //** this version does not know reads as prPerspective. Writing sets Orthographic too, so
    //** an earlier version reading the file still finds orthographic or perspective.
    property ProjectionKind: TSprite3DProjection read GetProjectionKind write SetProjectionKind;
  published
    //** @abstract(Whether View, Show bounding box is ticked on the main form; False by
    //** default.)
    //**
    //** Stored as @code(showBoundingBox).
    property ShowBoundingBox: Boolean read FShowBoundingBox write FShowBoundingBox;
    //** @abstract(Whether the main form's projection is orthographic; False by default.)
    //**
    //** Stored as @code(orthographic). Before View, Projection it was the View, Orthographic
    //** tick; now Projection says which projection, and this is kept in step with it for
    //** earlier versions, and read only when Projection is missing.
    property Orthographic: Boolean read FOrthographic write FOrthographic;
    //** @abstract(The projection chosen in View, Projection on the main form; empty by default,
    //** which reads as Orthographic says.)
    //**
    //** Stored as @code(projection): one of Perspective, Orthographic, Cavalier, Cabinet,
    //** Military and PlanOblique. Kept as text so a name this version does not know can never
    //** stop settings.json loading; use ProjectionKind in code.
    property Projection: String read FProjection write FProjection;
    //** @abstract(Whether View, Lights, Headlight is ticked on the main form: the Spritely
    //** camera's own light; True by default.)
    //**
    //** Stored as @code(headlight).
    property Headlight: Boolean read FHeadlight write FHeadlight;
    //** @abstract(Whether View, Lights, Original Light is ticked on the main form: the light
    //** the form made before the Spritely camera; False by default.)
    //**
    //** Stored as @code(originalLight).
    property OriginalLight: Boolean read FOriginalLight write FOriginalLight;
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
    //** @abstract(Whether the shift and rise are applied; False by default.)
    //**
    //** Stored as @code(panEnabled), the name from before they were a lens shift. Set by the
    //** Shift and rise box in the Variable camera dialog. While False, PanX and PanZ are kept
    //** but have no effect.
    property PanEnabled: Boolean read FPanEnabled write FPanEnabled;
    //** @abstract(The shift: the picture slid right (positive) or left, as a fraction of how
    //** far it can go; 0 by default.)
    //**
    //** Stored as @code(panX). Values beyond PAN_LIMIT either way are limited to it, which also
    //** brings a value from before, when it was a multiple of the model's radius, into range.
    property PanX: Single read FPanX write FPanX;
    //** @abstract(The rise: the picture slid up (positive) or down, as a fraction of how far
    //** it can go; 0 by default.)
    //**
    //** Stored as @code(panZ). Values beyond PAN_LIMIT either way are limited to it.
    property PanZ: Single read FPanZ write FPanZ;
    //** @abstract(Whether the shift and rise are kept for the next session; False by
    //** default.)
    //**
    //** Stored as @code(keepShift). Set by Save shift, rise and distance values between
    //** sessions in the Variable camera dialog. While False, PanEnabled, PanX and PanZ are
    //** saved off and at 0 and DistanceFactor at 1, and none is read at start-up, so each
    //** session starts without a shift or rise, at the fitted distance.
    property KeepShift: Boolean read FKeepShift write FKeepShift;
    //** @abstract(The Variable camera dialog's distance, a factor on the fitted distance; 1
    //** by default.)
    //**
    //** Stored as @code(distanceFactor); saved, and read at start-up, only while KeepShift.
    //** A value of 0 or less counts as 1.
    property DistanceFactor: Single read FDistanceFactor write FDistanceFactor;
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
    //** included, sets JsonText.MinifyJson, which every JSON file Sprite3DBuilder writes follows,
    //** settings.json itself among them.
    property MinifyJson: Boolean read FMinifyJson write SetMinifyJson;
    //** @abstract(Whether View, Camera, Temporary Mouse View is ticked; False by default.)
    //**
    //** Stored as @code(mouseView); set by the menu item, and saved as soon as it changes.
    //** Only the tick is kept: the turn and zoom the mouse gives the view never are, and
    //** each session starts from the normal view. Desktop only; ignored on Android and iOS.
    property MouseView: Boolean read FMouseView write FMouseView;
    //** @abstract(The level grid's spacing, in the kit's own units; GRID_SIZE_DEFAULT, 2, by
    //** default, a floor tile of the dungeon kit.)
    //**
    //** Stored as @code(gridSize). A value outside GRID_SIZE_MIN to GRID_SIZE_MAX reads as the
    //** default. Set only in settings.json for now.
    property GridSize: Single read FGridSize write SetGridSize;
    //** @abstract(The folder File, Open Asset Folder last chose; empty until one is.)
    //**
    //** Stored as @code(assetFolder). The next Open Asset Folder starts there, or in
    //** AssetsFolder while it is empty or gone.
    property AssetFolder: String read FAssetFolder write FAssetFolder;
    //** @abstract(What the Library's model preview shows behind the model: @code(checker),
    //** standing for transparency, the default, or @code(black), @code(grey) or
    //** @code(white).)
    //**
    //** Stored as @code(previewBackground); set by the drop-down over the preview, and saved
    //** as soon as it changes. Any other value reads as @code(checker). Thumbnails are not
    //** changed by it: they are always grabbed with a transparent background.
    property PreviewBackground: String read FPreviewBackground write FPreviewBackground;
  end;

//** @abstract(Shifts an angle in degrees by whole turns into the range 0 to 360.)
//**
//** @param(ADegrees Any angle in degrees, negative or past a full turn.)
//**
//** @returns(The same direction as an angle from 0 up to, but not including, 360.)
function Wrap360(const ADegrees: Single): Single;


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
//** The program's assets folder, from @link(GetAssetsPath): the executable's folder on Windows
//** (three folders up from it, @code('../../../'), when started from the IDE), the bundle's
//** Resources folder on macOS, and the application's resource folder on Android.
//**
//** @returns(A folder path ending in a path delimiter.)
function DefaultModelDir: String;

//** @abstract(Replaces a model's contents with a model file.)
//**
//** Clears AModel and loads AFileName into it, none of its animations played. Blocks while
//** the file loads.
//**
//** Its animations are loaded, but, unless ACacheAnimations, not baked: baking (Gorilla3D's
//** vertex position cache) makes them play faster, but takes 40 to 100 ms or more for each
//** animated model, which a still picture, such as a thumbnail, does not need.
//**
//** @param(AModel The model to load into; its old contents are removed first.)
//**
//** @param(AFileName A glTF, FBX, OBJ, USD, Collada, STL or PLY file.)
//**
//** @param(ABox The model's bounding box straight after loading, before anything is added
//** to it or it is moved, in its own coordinates.)
//**
//** @param(ACacheAnimations True to bake the animations, for a model that will play them;
//** False, the default, not to.)
//**
//** @returns(The names of the model's animations in sorted order; empty if it has none.)
//**
//** @raises(Exception If the file cannot be read or loaded; AModel is then left cleared or
//** part-loaded.)
function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox; const ACacheAnimations: Boolean = False): TArray<String>;







//** @abstract(The file spec of every model format LoadModelFile loads.)
//**
//** @returns(@code(*.glb;*.gltf;*.fbx;*.obj;*.usdc;*.usda;*.usd;*.usdz;*.dae;*.stl;*.ply),
//** from the same list IsModelFile uses.)
function AllModelsFileSpec: String;



//** @abstract(Whether a file is a model LoadModelFile can load, judged by its extension.)
//**
//** The extensions are those of the loaders this unit registers: .glb, .gltf, .fbx, .obj,
//** .usdc, .usda, .usd, .usdz, .dae, .stl and .ply, in any case. The file's contents are not checked.
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True if its extension is one of the model formats.)
function IsModelFile(const AFileName: String): Boolean;

//** @abstract(The folder the asset kits are kept in: an @code(assets) folder beside the
//** program or in one of the folders above it.)
//**
//** Looks in the program's own folder, then up to five folders above it, so it finds the
//** repository's @code(assets) folder when the program runs from its build folder
//** (@code(src\Win64\Debug)), or from inside a macOS bundle. If there is none, gives
//** DefaultModelDir.
//**
//** @returns(The folder's full path, without a trailing path delimiter.)
function AssetsFolder: String;

//** @abstract(The group icons that come with the program: @code(icons/groups) beside the
//** program or in one of the folders above it.)
//**
//** Looked for as AssetsFolder looks for the assets folder, so the repository's own is found
//** when the program runs from its build folder.
//**
//** @returns(The folder's full path, without a trailing path delimiter; empty if there is
//** none.)
function GroupIconsFolder: String;

//** @abstract(The model files in AFolder, not in its sub-folders, sorted by name.)
//**
//** A file counts if IsModelFile says it is a model, so a glTF's @code(.bin) and its
//** textures are left out.
//**
//** @param(AFolder The folder to look in.)
//**
//** @returns(Their full paths; empty if there are none or the folder cannot be read.)
function AssetModelFiles(const AFolder: String): TArray<String>;

//** @abstract(The words of a model's name, in lower case, as grouping takes them.)
//**
//** The name is split at underscores, hyphens, spaces and dots; a name with none of those
//** is split where a capital follows a small letter, so @code(WallCorner) is
//** @code(wall corner). Words that only tell variants apart are left out: numbers, and
//** single letters, such as the @code(a) of @code(blaster-a).
//**
//** @param(AName The model's name, its file's name without the extension.)
//**
//** @returns(The words; empty if none is left.)
function AssetNameWords(const AName: String): TArray<String>;

//** @abstract(The group a model is put in when nothing has chosen one: the first word of
//** its name (AssetNameWords), or its whole name in lower case if it has none.)
//**
//** @param(AName The model's name, its file's name without the extension.)
//**
//** @returns(The group's name; never empty for a name that is not.)
function AssetGroupName(const AName: String): String;

//** @abstract(The groups the models of one collection are put in when nothing has chosen
//** them, one for each name, in ANames' order.)
//**
//** Kits name their models in different ways: @code(wall_corner) has its group first,
//** @code(small-tree) last. Each model is put in its first word (AssetNameWords), or each
//** in its last, whichever puts more of them in groups of two or more; the first, if it is
//** as good. A name with no words is a group of its own name, in lower case.
//**
//** @param(ANames The models' names, their files' names without the extension.)
//**
//** @returns(Their groups.)
function AssetGroupNames(const ANames: TArray<String>): TArray<String>;

type
  //** @abstract(A folder holding models of one format, as FindModelFolders finds it.)
  TModelFolder = record
    //** @abstract(The folder, as a full path.)
    Folder: String;
    //** @abstract(The format: the files' extension, in lower case with the dot.)
    Format: String;
    //** @abstract(How many model files of the format it holds.)
    Count: Integer;
    //** @abstract(Their names without the extension, in lower case, to tell when two
    //** folders hold the same models.)
    Names: TArray<String>;
  end;

//** @abstract(Every folder under ARoots, the roots among them, that holds model files: one
//** entry for each folder and format in it, sorted by folder, then format.)
//**
//** For a model pack, which often holds the same models in several formats, each in its own
//** folder (glTF, FBX, a second FBX for one engine, OBJ), so the user can choose which to
//** take. A folder that cannot be read is passed over.
//**
//** @param(ARoots The folders to look in, and below.)
//**
//** @returns(The folders and formats found.)
function FindModelFolders(const ARoots: TArray<String>): TArray<TModelFolder>;

//** @abstract(The formats AFolders hold, best first, as MODEL_FORMAT_PREFERENCE orders them.)
//**
//** @param(AFolders The folders, from FindModelFolders.)
//**
//** @returns(The extensions.)
function FoundModelFormats(const AFolders: TArray<TModelFolder>): TArray<String>;

//** @abstract(Which of AFolders to take by default: those of format APreferred, or of the
//** best format found if none has it, leaving out one whose models mostly have the names of
//** one already taken, which would be the same models again.)
//**
//** @param(AFolders The folders, from FindModelFolders.)
//**
//** @param(APreferred The format the user prefers; empty for the best found.)
//**
//** @returns(One flag for each folder, in AFolders' order.)
function DefaultModelFolders(const AFolders: TArray<TModelFolder>;
  const APreferred: String): TArray<Boolean>;

//** @abstract(A format's name for people: glTF, FBX, OBJ and so on.)
//**
//** @param(AExt The extension, with the dot.)
//**
//** @returns(The name; the extension itself, without the dot and in capitals, if it is not
//** known.)
function ModelFormatName(const AExt: String): String;

//** @abstract(The model files in AFolder of the formats AFormats, not in its sub-folders,
//** sorted by name.)
//**
//** @param(AFolder The folder.)
//**
//** @param(AFormats The extensions, with the dot; empty for every model format.)
//**
//** @returns(Their full paths.)
function AssetModelFilesOf(const AFolder: String; const AFormats: TArray<String>):
  TArray<String>;


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




//** @abstract(The names of a projection: its settings key and caption.)
//**
//** @param(AProjection The projection.)
//** @returns(Its names.)
function ProjectionInfo(const AProjection: TSprite3DProjection): TSprite3DProjectionInfo;

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
//** The GPU preference is read from the system, where it can say; the rest come from
//** ASettings.
//**
//** @param(ASettings The application's settings.)
//**
//** @returns(The choices.)
function ReadGeneralSettings(const ASettings: TSprite3DAppSettings): TSprite3DGeneralSettings;

implementation

uses
  System.Classes, System.Math, System.IOUtils, System.Hash, System.StrUtils,
  System.Threading, System.SyncObjs, System.Generics.Collections, System.Generics.Defaults,
  OSPaths, JsonText, Sprite3DStyles, Sprite3DTitleBar,
  {$IF DEFINED(MSWINDOWS)}
  GpuPreference,
  {$ENDIF}
  Gorilla.DefTypes,
  Gorilla.Animation,
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.OBJ.Loader,
  Gorilla.USD.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader;

{ TSprite3DAppSettings }

constructor TSprite3DAppSettings.Create;
begin
  inherited Create(TPath.Combine(SupportFolder, SETTINGS_FILE_NAME));
  // As the main form's check box starts: off; a settings.json without the
  // key leaves it so
  FShowBoundingBox := False;
  FOrthographic := False;
  // Empty: decided by FOrthographic, so a file from before View, Projection
  // keeps its projection
  FProjection := String.Empty;
  FHeadlight := True;
  FOriginalLight := False;
  // The main form's view as it starts
  FCameraView := 'Isometric';
  FVariableAzimuth := 0;
  FVariableInclination := 0;
  FVariableRoll := 0;
  // Panning is rare: off, and centred, until chosen
  FPanEnabled := False;
  FPanX := 0;
  FPanZ := 0;
  FKeepShift := False;
  FDistanceFactor := 1;
  SetThemeKind(thDefault);
  FGpuMode := gmSystem;
  FViewFps := VIEW_FPS_DEFAULT;
  SetMinifyJson(False);
  FMouseView := False;
  FGridSize := GRID_SIZE_DEFAULT;
  FAssetFolder := String.Empty;
  FPreviewBackground := 'checker';
end;

procedure TSprite3DAppSettings.SetGridSize(const Value: Single);
begin
  // A bad value, as from a settings.json edited by hand, falls back to the
  // default rather than leaving a grid that cannot be drawn
  if (Value >= GRID_SIZE_MIN) and (Value <= GRID_SIZE_MAX) then
    FGridSize := Value
  else
    FGridSize := GRID_SIZE_DEFAULT;
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

class function TSprite3DAppSettings.SupportFolder: String;
begin
  Result := OSFriendlyPath(AppDataFolder(APP_NAME));
end;

class function TSprite3DAppSettings.ThumbnailFolder: String;
begin
  Result := OSFriendlyPath(TPath.Combine(SupportFolder, THUMBNAIL_FOLDER_NAME));
end;

class function TSprite3DAppSettings.UserGroupIconsFolder: String;
begin
  Result := OSFriendlyPath(TPath.Combine(TPath.Combine(SupportFolder, ICONS_FOLDER_NAME),
    GROUP_ICONS_FOLDER_NAME));
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
  // Once the library path on macOS and the home folder on Linux, with the
  // current folder on Windows when it had a models subfolder; a later line
  // overrode all of that with the assets folder, so that is what it is
  Result := GetAssetsPath('../../../');
end;

const
  // One for each loader in the uses clause above
  // (Gorilla.USD.Loader reads USD's binary, text and either-format files,
  // and the zipped package)
  MODEL_EXTENSIONS: array[0..10] of String =
    ('.glb', '.gltf', '.fbx', '.obj', '.usdc', '.usda', '.usd', '.usdz', '.dae', '.stl',
     '.ply');
  //** @abstract(The model formats, best first, for a pack that has several: glTF keeps
  //** materials and bounds most faithfully in Gorilla3D, then FBX, then the rest.)
  MODEL_FORMAT_PREFERENCE: array[0..10] of String =
    ('.gltf', '.glb', '.fbx', '.dae', '.usdz', '.usdc', '.usd', '.usda', '.obj', '.ply',
     '.stl');

function FindModelFolders(const ARoots: TArray<String>): TArray<TModelFolder>;
var
  Found: TDictionary<String, Integer>;
  Key, Folder: String;
  Index: Integer;
  Item: TModelFolder;

  procedure Look(const ARoot: String);
  var
    Files: TArray<String>;
  begin
    try
      Files := TDirectory.GetFiles(ARoot, '*', TSearchOption.soAllDirectories);
    except
      on Exception do
        Exit;   // unreadable: as if empty
    end;
    for var FileName in Files do
    begin
      if not IsModelFile(FileName) then
        Continue;
      Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));
      Item.Format := LowerCase(ExtractFileExt(FileName));
      Key := LowerCase(Folder) + '|' + Item.Format;
      if not Found.TryGetValue(Key, Index) then
      begin
        Item.Folder := Folder;
        Item.Count := 0;
        Item.Names := nil;
        Result := Result + [Item];
        Index := High(Result);
        Found.Add(Key, Index);
      end;
      Inc(Result[Index].Count);
      Result[Index].Names := Result[Index].Names +
        [LowerCase(TPath.GetFileNameWithoutExtension(FileName))];
    end;
  end;

begin
  Result := nil;
  Found := TDictionary<String, Integer>.Create;
  try
    for var Root in ARoots do
      if TDirectory.Exists(OSFriendlyPath(Root)) then
        Look(OSFriendlyPath(Root));
  finally
    Found.Free;
  end;
  TArray.Sort<TModelFolder>(Result, TComparer<TModelFolder>.Construct(
    function(const A, B: TModelFolder): Integer
    begin
      Result := CompareText(A.Folder, B.Folder);
      if Result = 0 then
        Result := CompareText(A.Format, B.Format);
    end));
end;

function FoundModelFormats(const AFolders: TArray<TModelFolder>): TArray<String>;
begin
  Result := nil;
  for var Ext in MODEL_FORMAT_PREFERENCE do
    for var Item in AFolders do
      if Item.Format = Ext then
      begin
        Result := Result + [Ext];
        Break;
      end;
end;

function DefaultModelFolders(const AFolders: TArray<TModelFolder>;
  const APreferred: String): TArray<Boolean>;
var
  Wanted: String;
  Taken: TDictionary<String, Boolean>;
  Same: Integer;
begin
  SetLength(Result, Length(AFolders));
  Wanted := LowerCase(APreferred);
  if IndexText(Wanted, FoundModelFormats(AFolders)) < 0 then
  begin
    Wanted := String.Empty;
    if Length(FoundModelFormats(AFolders)) > 0 then
      Wanted := FoundModelFormats(AFolders)[0];
  end;
  Taken := TDictionary<String, Boolean>.Create;
  try
    for var I := 0 to High(AFolders) do
    begin
      Result[I] := False;
      if AFolders[I].Format <> Wanted then
        Continue;
      // The same models again, as an engine's own copy of a format is
      Same := 0;
      for var Name in AFolders[I].Names do
        if Taken.ContainsKey(Name) then
          Inc(Same);
      if Same * 2 > Length(AFolders[I].Names) then
        Continue;
      Result[I] := True;
      for var Name in AFolders[I].Names do
        Taken.AddOrSetValue(Name, True);
    end;
  finally
    Taken.Free;
  end;
end;

function ModelFormatName(const AExt: String): String;
begin
  case IndexText(AExt, ['.gltf', '.glb', '.fbx', '.obj', '.dae', '.stl', '.ply', '.usd',
    '.usda', '.usdc', '.usdz']) of
    0: Result := 'glTF';
    1: Result := 'glTF binary';
    2: Result := 'FBX';
    3: Result := 'OBJ';
    4: Result := 'Collada';
    5: Result := 'STL';
    6: Result := 'PLY';
    7..10: Result := 'USD';
  else
    Result := UpperCase(AExt.TrimLeft(['.']));
  end;
end;

function AssetModelFilesOf(const AFolder: String; const AFormats: TArray<String>):
  TArray<String>;
begin
  Result := nil;
  for var FileName in AssetModelFiles(AFolder) do
    if (Length(AFormats) = 0) or (IndexText(ExtractFileExt(FileName), AFormats) >= 0) then
      Result := Result + [FileName];
end;

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

function AssetsFolder: String;
const
  // The program's folder and this many above it
  LEVELS_UP = 5;
var
  Folder, Candidate: String;
begin
  Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  for var Level := 0 to LEVELS_UP do
  begin
    Candidate := TPath.Combine(Folder, ASSETS_FOLDER_NAME);
    if TDirectory.Exists(Candidate) then
      Exit(ExpandFileName(Candidate));
    if ExtractFilePath(Folder) = String.Empty then
      Break;   // at the top of the drive
    Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(Folder));
  end;
  Result := ExcludeTrailingPathDelimiter(DefaultModelDir);
end;

function GroupIconsFolder: String;
const
  // The program's folder and this many above it
  LEVELS_UP = 5;
var
  Folder, Candidate: String;
begin
  Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  for var Level := 0 to LEVELS_UP do
  begin
    Candidate := TPath.Combine(TPath.Combine(Folder, ICONS_FOLDER_NAME),
      GROUP_ICONS_FOLDER_NAME);
    if TDirectory.Exists(Candidate) then
      Exit(ExpandFileName(Candidate));
    if ExtractFilePath(Folder) = String.Empty then
      Break;   // at the top of the drive
    Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(Folder));
  end;
  Result := String.Empty;
end;

function AssetModelFiles(const AFolder: String): TArray<String>;
var
  Folder: String;
  List: TStringList;
begin
  Result := nil;
  Folder := OSFriendlyPath(AFolder);
  if not TDirectory.Exists(Folder) then
    Exit;
  List := TStringList.Create;
  try
    try
      for var FileName in TDirectory.GetFiles(Folder) do
        if IsModelFile(FileName) then
          List.Add(FileName);
    except
      on Exception do
        Exit;   // unreadable: as if empty
    end;
    List.Sort;
    Result := List.ToStringArray;
  finally
    List.Free;
  end;
end;

function AssetNameWords(const AName: String): TArray<String>;
var
  Parts: TArray<String>;
  Word: String;
  Start: Integer;
begin
  Result := nil;
  Parts := AName.Split(['_', '-', ' ', '.'], TStringSplitOptions.ExcludeEmpty);
  // One part: split where a capital follows a small letter
  if Length(Parts) = 1 then
  begin
    Parts := nil;
    Start := 1;
    for var I := 2 to Length(AName) do
      if CharInSet(AName[I], ['A'..'Z']) and CharInSet(AName[I - 1], ['a'..'z']) then
      begin
        Parts := Parts + [Copy(AName, Start, I - Start)];
        Start := I;
      end;
    Parts := Parts + [Copy(AName, Start, MaxInt)];
  end;
  for var Part in Parts do
  begin
    Word := Part.ToLower;
    // Variants: numbers and single letters
    if (Word.Length <= 1) or (StrToIntDef(Word, -1) >= 0) then
      Continue;
    Result := Result + [Word];
  end;
end;

function AssetGroupName(const AName: String): String;
var
  Words: TArray<String>;
begin
  Words := AssetNameWords(AName);
  if Length(Words) > 0 then
    Result := Words[0]
  else
    Result := AName.ToLower;
end;

function AssetGroupNames(const ANames: TArray<String>): TArray<String>;
var
  Firsts, Lasts: TArray<String>;
  Words: TArray<String>;

  // How many of AGroups are in a group of two or more
  function Grouped(const AGroups: TArray<String>): Integer;
  var
    Counts: TDictionary<String, Integer>;
    Count: Integer;
  begin
    Result := 0;
    Counts := TDictionary<String, Integer>.Create;
    try
      for var Group in AGroups do
      begin
        if not Counts.TryGetValue(Group, Count) then
          Count := 0;
        Counts.AddOrSetValue(Group, Count + 1);
      end;
      for var Group in AGroups do
        if Counts[Group] >= 2 then
          Inc(Result);
    finally
      Counts.Free;
    end;
  end;

begin
  SetLength(Firsts, Length(ANames));
  SetLength(Lasts, Length(ANames));
  for var I := 0 to High(ANames) do
  begin
    Words := AssetNameWords(ANames[I]);
    if Length(Words) = 0 then
    begin
      Firsts[I] := ANames[I].ToLower;
      Lasts[I] := Firsts[I];
    end
    else
    begin
      Firsts[I] := Words[0];
      Lasts[I] := Words[High(Words)];
    end;
  end;
  if Grouped(Lasts) > Grouped(Firsts) then
    Result := Lasts
  else
    Result := Firsts;
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

function LoadModelFile(const AModel: TGorillaModel; const AFileName: String;
  out ABox: TBoundingBox; const ACacheAnimations: Boolean): TArray<String>;
var
  Names: TStringList;
  I: Integer;
  Ani: TArray<TGorillaAnimation>;
begin
  AModel.Clear;
  if ACacheAnimations then
    AModel.LoadFromFile(nil, OSFriendlyPath(AFileName), [TAnimationCachingFlag.VertexPosition])
  else
    AModel.LoadFromFile(nil, OSFriendlyPath(AFileName), []);

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

const
  //** @abstract(The names of each projection; see TSprite3DProjectionInfo.)
  PROJECTIONS: array[TSprite3DProjection] of TSprite3DProjectionInfo = (
    (Key: 'Perspective';  Caption: 'Perspective'),
    (Key: 'Orthographic'; Caption: 'Orthographic'),
    (Key: 'Cavalier';     Caption: 'Cavalier'),
    (Key: 'Cabinet';      Caption: 'Cabinet'),
    (Key: 'Military';     Caption: 'Military'),
    (Key: 'PlanOblique';  Caption: 'Plan Oblique'));

function ProjectionInfo(const AProjection: TSprite3DProjection): TSprite3DProjectionInfo;
begin
  Result := PROJECTIONS[AProjection];
end;

function TSprite3DAppSettings.GetProjectionKind: TSprite3DProjection;
begin
  if FProjection = String.Empty then
  begin
    if FOrthographic then
      Exit(prOrthographic);
    Exit(prPerspective);
  end;
  for var Kind := Low(TSprite3DProjection) to High(TSprite3DProjection) do
    if SameText(FProjection, PROJECTIONS[Kind].Key) then
      Exit(Kind);
  Result := prPerspective;
end;

procedure TSprite3DAppSettings.SetProjectionKind(const Value: TSprite3DProjection);
begin
  FProjection := PROJECTIONS[Value].Key;
  FOrthographic := Value = prOrthographic;
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
  MODEL_MIME_TYPES: array[0..10] of String =
    ('model/gltf-binary', 'model/gltf+json', 'model/x-fbx', 'model/obj',
     'model/x-usdc', 'model/x-usda', 'model/x-usd', 'model/vnd.usdz+zip',
     'model/vnd.collada+xml', 'model/stl', 'model/x-ply');
  MODEL_DESCRIPTIONS: array[0..10] of String =
    ('glTF binary model', 'glTF model', 'FBX model', 'Wavefront OBJ model',
     'USD binary model', 'USD text model', 'USD model', 'USD package', 'Collada model',
     'STL model', 'PLY model');

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
begin
  Result.Theme := ASettings.ThemeKind;
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
