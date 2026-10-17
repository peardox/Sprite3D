//** @abstract(Per-user storage for an application: where to keep files, and JSON settings.)
//**
//** AppDataFolder gives the folder each platform expects an application to keep its own
//** files in, such as settings and support files, kept between sessions and private to the
//** user. TSprite3DJsonSettings is a base class for settings: a descendant declares its
//** settings as published properties, and Load and Save read and write them as a JSON file,
//** using the Neon library.
//**
//** The unit knows nothing of any particular application; the application name and file
//** name come from the caller. It needs the Neon library, whose @code(Source) folder must be
//** on the project's search path.
//**
//** @preformatted(
//** Windows   %APPDATA%\<AppName>                   e.g. C:\Users\x\AppData\Roaming\Sprite3D
//** macOS     ~/Library/Application Support/<AppName>
//** Linux     $XDG_CONFIG_HOME/<AppName>, or ~/.config/<AppName>
//** Android   the app's private files folder        Context.getFilesDir
//** iOS       the app's Library/Application Support folder
//** )
unit Sprite3DStorage;

{
  Per-user storage for an application: where to keep files, and JSON
  settings.

  AppDataFolder gives the folder each platform expects an application to
  keep its own files in, such as settings and support files, kept between
  sessions and private to the user. TSprite3DJsonSettings is a base class for
  settings: a descendant declares its settings as published properties, and
  Load and Save read and write them as a JSON file, using the Neon library.

  The unit knows nothing of any particular application; the application
  name and file name come from the caller. It needs the Neon library, whose
  Source folder must be on the project's search path.

    Windows   %APPDATA%\<AppName>                   e.g. C:\Users\x\AppData\Roaming\Sprite3D
    macOS     ~/Library/Application Support/<AppName>
    Linux     $XDG_CONFIG_HOME/<AppName>, or ~/.config/<AppName>
    Android   the app's private files folder        Context.getFilesDir
    iOS       the app's Library/Application Support folder
}

interface

uses
  System.SysUtils, System.Classes;

//** @abstract(The per-user folder an application should keep its own files in.)
//**
//** The folder is chosen by platform, as in the unit description, and is not created; the
//** caller creates it when it first writes there, as TSprite3DJsonSettings.Save does. On
//** Android and iOS the folder already belongs to the app, so AAppName is only added on the
//** desktop platforms, where the folder is shared with other applications.
//**
//** @param(AAppName The application's name, used as the folder name on the desktop; it
//** should be a valid file name on every platform.)
//**
//** @returns(The folder's full path, without a trailing path delimiter.)
/// <summary>The per-user folder an application should keep its own files in.</summary>
/// <remarks>The folder is chosen by platform, as in the unit description, and is not created;
/// the caller creates it when it first writes there, as TSprite3DJsonSettings.Save does. On
/// Android and iOS the folder already belongs to the app, so AAppName is only added on the
/// desktop platforms, where the folder is shared with other applications.</remarks>
/// <param name="AAppName">The application's name, used as the folder name on the desktop; it
/// should be a valid file name on every platform.</param>
/// <returns>The folder's full path, without a trailing path delimiter.</returns>
function AppDataFolder(const AAppName: String): String;

type
  //** @abstract(Base class for settings kept as a JSON file.)
  //**
  //** Declare each setting as a published property of a descendant, with its default set in
  //** the constructor; Load fills them from the file and Save writes them all back. The JSON
  //** member names are the property names in camel case, such as @code(saveFolder) for
  //** SaveFolder. Only published properties are stored, so public ones, such as FileName, are
  //** not. Settings missing from the file keep their defaults and members in the file that no
  //** property matches are ignored, so a newer or older file still loads.
  //**
  //** Not thread-safe; use one object from one thread, normally the main thread.
  /// <summary>Base class for settings kept as a JSON file.</summary>
  /// <remarks>Declare each setting as a published property of a descendant, with its default
  /// set in the constructor; Load fills them from the file and Save writes them all back. The
  /// JSON member names are the property names in camel case, such as <c>saveFolder</c> for
  /// SaveFolder. Only published properties are stored, so public ones, such as FileName, are
  /// not. Settings missing from the file keep their defaults and members in the file that no
  /// property matches are ignored, so a newer or older file still loads.
  /// Not thread-safe; use one object from one thread, normally the main thread.</remarks>
  TSprite3DJsonSettings = class(TPersistent)
  private
    FFileName: String;
  public
    //** @abstract(Creates the settings with their defaults, for the given file.)
    //**
    //** Nothing is read until Load is called, and the file and its folder are not created
    //** until Save.
    //**
    //** @param(AFileName The full path of the JSON file.)
    /// <summary>Creates the settings with their defaults, for the given file.</summary>
    /// <remarks>Nothing is read until Load is called, and the file and its folder are not
    /// created until Save.</remarks>
    /// <param name="AFileName">The full path of the JSON file.</param>
    constructor Create(const AFileName: String); virtual;
    //** @abstract(Reads the settings from FileName.)
    //**
    //** Blocks while the file is read. If the file does not exist, which is normal on the
    //** first run, or cannot be read or parsed, the settings are left as they were and
    //** nothing is raised; a damaged file is replaced at the next Save.
    //**
    //** @returns(True if the file was read; False if it was missing or unusable.)
    /// <summary>Reads the settings from FileName.</summary>
    /// <remarks>Blocks while the file is read. If the file does not exist, which is normal on
    /// the first run, or cannot be read or parsed, the settings are left as they were and
    /// nothing is raised; a damaged file is replaced at the next Save.</remarks>
    /// <returns>True if the file was read; False if it was missing or unusable.</returns>
    function Load: Boolean;
    //** @abstract(Writes all the settings to FileName, creating its folder if needed.)
    //**
    //** Blocks while the file is written. The JSON goes to a temporary file beside FileName,
    //** which then replaces it, so a failure part-way leaves the previous file whole.
    //**
    //** @raises(Exception If the folder cannot be created or the file cannot be written; the
    //** class depends on the cause.)
    /// <summary>Writes all the settings to FileName, creating its folder if needed.</summary>
    /// <remarks>Blocks while the file is written. The JSON goes to a temporary file beside
    /// FileName, which then replaces it, so a failure part-way leaves the previous file
    /// whole.</remarks>
    /// <exception cref="Exception">If the folder cannot be created or the file cannot be
    /// written; the class depends on the cause.</exception>
    procedure Save;
    //** @abstract(The full path of the JSON file, as given to Create.)
    /// <summary>The full path of the JSON file, as given to Create.</summary>
    property FileName: String read FFileName;
  end;

implementation

uses
  System.IOUtils, System.TypInfo,
  Neon.Core.Persistence, Neon.Core.Persistence.JSON;

function AppDataFolder(const AAppName: String): String;
{$IF DEFINED(LINUX)}
var
  ConfigHome: String;
{$ENDIF}
begin
  {$IF DEFINED(MSWINDOWS)}
  // TPath.GetHomePath is %APPDATA% on Windows
  Result := TPath.Combine(TPath.GetHomePath, AAppName);
  {$ELSEIF DEFINED(IOS)}
  // The app's own sandbox: Library/Application Support, backed up, not
  // shown to the user
  Result := TPath.Combine(TPath.GetLibraryPath, 'Application Support');
  {$ELSEIF DEFINED(MACOS)}
  Result := TPath.Combine(TPath.Combine(TPath.Combine(TPath.GetHomePath,
    'Library'), 'Application Support'), AAppName);
  {$ELSEIF DEFINED(ANDROID)}
  // The app's private files folder
  Result := TPath.GetDocumentsPath;
  {$ELSE}
  // Linux: the XDG base directory rules
  ConfigHome := GetEnvironmentVariable('XDG_CONFIG_HOME');
  if ConfigHome = String.Empty then
    ConfigHome := TPath.Combine(TPath.GetHomePath, '.config');
  Result := TPath.Combine(ConfigHome, AAppName);
  {$ENDIF}
  Result := ExcludeTrailingPathDelimiter(Result);
end;

// Camel-case names, published properties only, laid out for people to read
function JsonConfig: INeonConfiguration;
begin
  Result := TNeonConfiguration.Camel
    .SetVisibility([mvPublished])
    .SetPrettyPrint(True);
end;

{ TSprite3DJsonSettings }

constructor TSprite3DJsonSettings.Create(const AFileName: String);
begin
  inherited Create;
  FFileName := AFileName;
end;

function TSprite3DJsonSettings.Load: Boolean;
var
  Json: String;
begin
  Result := False;
  if not TFile.Exists(FFileName) then
    Exit;
  try
    Json := TFile.ReadAllText(FFileName, TEncoding.UTF8);
    TNeon.JSONToObject(Self, Json, JsonConfig);
    Result := True;
  except
    // Unreadable or damaged: keep the current values; Save replaces it
    Result := False;
  end;
end;

procedure TSprite3DJsonSettings.Save;
var
  Json, TempName: String;
begin
  ForceDirectories(ExtractFileDir(FFileName));
  Json := TNeon.ObjectToJSONString(Self, JsonConfig);
  TempName := FFileName + '.tmp';
  // UTF-8 without a byte order mark, as JSON files normally are
  TFile.WriteAllBytes(TempName, TEncoding.UTF8.GetBytes(Json));
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
  TFile.Move(TempName, FFileName);
end;

end.
