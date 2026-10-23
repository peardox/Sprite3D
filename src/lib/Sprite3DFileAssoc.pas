//** @abstract(Registers an application with the operating system as an Open With choice for
//** file types, and as their default application, and puts things back afterwards.)
//**
//** TSprite3DFileAssociations is given an application name, a programmatic identifier, a
//** description and a list of file types, and works for the current user only; nothing needs
//** administrator rights. Before it makes the application the default for a type it records
//** what the default was, in a backup string the caller keeps, so RestoreDefaults can put the
//** old default back. An old default is only put back if it is still valid: the program it
//** names must still be registered or installed. Otherwise the type is left with no per-user
//** default, and the system's own choice applies again.
//**
//** @preformatted(
//** Windows   HKCU\Software\Classes: a ProgID, Applications\<exe>, <ext>\OpenWithProgids,
//**           and <ext>'s default value for "always"; Capabilities and RegisteredApplications
//**           so the app is listed in Settings, Default apps. A choice the user made in
//**           Windows' own dialog @(UserChoice@) cannot be changed by a program; then
//**           NeedsUserConfirmation is set and OpenSystemDefaults shows that page.
//** Linux     a .desktop file in $XDG_DATA_HOME/applications and a shared-mime-info package
//**           for the types; "always" is the [Default Applications] group of
//**           $XDG_CONFIG_HOME/mimeapps.list.
//** macOS     Open With comes from CFBundleDocumentTypes in the bundle's Info.plist and
//**           cannot be removed at run time; "always" is set through Launch Services.
//** Android,  not supported: the app declares what it opens when it is built, and the user
//** iOS       picks the default in the system's chooser.
//** )
//**
//** The unit knows nothing of any particular application. All methods are for the main thread
//** and may block briefly while files, the registry or helper programs are used.
unit Sprite3DFileAssoc;

{
  Registers an application with the operating system as an Open With
  choice for file types, and as their default application, and puts things
  back afterwards.

  TSprite3DFileAssociations is given an application name, a programmatic
  identifier, a description and a list of file types, and works for the
  current user only; nothing needs administrator rights. Before it makes
  the application the default for a type it records what the default was,
  in a backup string the caller keeps, so RestoreDefaults can put the old
  default back. An old default is only put back if it is still valid: the
  program it names must still be registered or installed. Otherwise the
  type is left with no per-user default, and the system's own choice
  applies again.

    Windows   HKCU\Software\Classes: a ProgID, Applications\<exe>,
              <ext>\OpenWithProgids, and <ext>'s default value for
              "always"; Capabilities and RegisteredApplications so the app
              is listed in Settings, Default apps. A choice the user made
              in Windows' own dialog (UserChoice) cannot be changed by a
              program; then NeedsUserConfirmation is set and
              OpenSystemDefaults shows that page.
    Linux     a .desktop file in $XDG_DATA_HOME/applications and a
              shared-mime-info package for the types; "always" is the
              [Default Applications] group of $XDG_CONFIG_HOME/mimeapps.list.
    macOS     Open With comes from CFBundleDocumentTypes in the bundle's
              Info.plist and cannot be removed at run time; "always" is set
              through Launch Services.
    Android,  not supported: the app declares what it opens when it is
    iOS       built, and the user picks the default in the system's chooser.

  The unit knows nothing of any particular application. All methods are for
  the main thread and may block briefly while files, the registry or helper
  programs are used.
}

// Delphi also defines LINUX for Android and MACOS for iOS; these name the
// desktop systems only
{$IF DEFINED(LINUX) and not DEFINED(ANDROID)}
  {$DEFINE S3D_DESKTOP_LINUX}
{$ENDIF}
{$IF DEFINED(MACOS) and not DEFINED(IOS)}
  {$DEFINE S3D_DESKTOP_MACOS}
{$ENDIF}

interface

uses
  System.SysUtils, System.Classes;

type
  //** @abstract(One file type an application opens.)
  /// <summary>One file type an application opens.</summary>
  TSprite3DFileType = record
    //** @abstract(The file name extension, with its leading dot, such as @code(.glb).)
    /// <summary>The file name extension, with its leading dot, such as <c>.glb</c>.</summary>
    Extension: String;
    //** @abstract(The MIME type used on Linux, such as @code(model/gltf-binary).)
    /// <summary>The MIME type used on Linux, such as <c>model/gltf-binary</c>.</summary>
    MimeType: String;
    //** @abstract(A short description of the type, shown by Linux file managers.)
    /// <summary>A short description of the type, shown by Linux file managers.</summary>
    Description: String;
    //** @abstract(Makes a file type from its three parts.)
    //**
    //** @param(AExtension The extension, with or without its leading dot.)
    //**
    //** @param(AMimeType The MIME type for Linux.)
    //**
    //** @param(ADescription A short description.)
    //**
    //** @returns(The file type, with the extension in lower case and starting with a dot.)
    /// <summary>Makes a file type from its three parts.</summary>
    /// <param name="AExtension">The extension, with or without its leading dot.</param>
    /// <param name="AMimeType">The MIME type for Linux.</param>
    /// <param name="ADescription">A short description.</param>
    /// <returns>The file type, with the extension in lower case and starting with a
    /// dot.</returns>
    class function Create(const AExtension, AMimeType,
      ADescription: String): TSprite3DFileType; static;
  end;

  //** @abstract(How much of the file associations this platform lets a program change.)
  //**
  //** @code(asNone): nothing, as on Android and iOS. @code(asDefaultOnly): only which
  //** application is the default; Open With is fixed when the app is built, as on macOS.
  //** @code(asFull): both, as on Windows and Linux.
  /// <summary>How much of the file associations this platform lets a program
  /// change.</summary>
  /// <remarks><c>asNone</c>: nothing, as on Android and iOS. <c>asDefaultOnly</c>: only which
  /// application is the default; Open With is fixed when the app is built, as on macOS.
  /// <c>asFull</c>: both, as on Windows and Linux.</remarks>
  TSprite3DAssocSupport = (asNone, asDefaultOnly, asFull);

  //** @abstract(Registers the running program for a set of file types, for the current user.)
  //**
  //** Create it, use it and free it; it holds no system resources between calls. Each method
  //** that changes something returns False on failure and leaves the reason in LastError.
  //**
  //** @seealso(TSprite3DFileType)
  /// <summary>Registers the running program for a set of file types, for the current
  /// user.</summary>
  /// <remarks>Create it, use it and free it; it holds no system resources between calls. Each
  /// method that changes something returns False on failure and leaves the reason in
  /// LastError.</remarks>
  /// <seealso cref="TSprite3DFileType"/>
  TSprite3DFileAssociations = class
  private
    FAppName: String;
    FProgId: String;
    FDescription: String;
    FExePath: String;
    FFileTypes: TArray<TSprite3DFileType>;
    FLastError: String;
    FNeedsUserConfirmation: Boolean;
    procedure Fail(const AMessage: String);
    {$IF DEFINED(MSWINDOWS)}
    function OpenCommand: String;
    procedure NotifyShell;
    {$ELSEIF DEFINED(S3D_DESKTOP_LINUX)}
    function DesktopId: String;
    function DesktopFileName: String;
    function MimePackageFileName: String;
    function MimeAppsFileName: String;
    function ExecLine: String;
    function DesktopEntryExists(const AId: String): Boolean;
    procedure RefreshDatabases;
    {$ELSEIF DEFINED(S3D_DESKTOP_MACOS)}
    function BundleId: String;
    {$ENDIF}
  public
    //** @abstract(Prepares to register the running program for AFileTypes.)
    //**
    //** Nothing is changed until a method is called.
    //**
    //** @param(AAppName The application's name, as people see it; also used for its keys
    //** and files, so it should not change between versions.)
    //**
    //** @param(AProgId A programmatic identifier, such as @code(Sprite3D.Model), used on
    //** Windows for the registry and in the backup string.)
    //**
    //** @param(ADescription A short description of what the application opens.)
    //**
    //** @param(AFileTypes The types to register.)
    /// <summary>Prepares to register the running program for AFileTypes.</summary>
    /// <remarks>Nothing is changed until a method is called.</remarks>
    /// <param name="AAppName">The application's name, as people see it; also used for its
    /// keys and files, so it should not change between versions.</param>
    /// <param name="AProgId">A programmatic identifier, such as <c>Sprite3D.Model</c>, used
    /// on Windows for the registry and in the backup string.</param>
    /// <param name="ADescription">A short description of what the application
    /// opens.</param>
    /// <param name="AFileTypes">The types to register.</param>
    constructor Create(const AAppName, AProgId, ADescription: String;
      const AFileTypes: TArray<TSprite3DFileType>);

    //** @abstract(How much this platform lets a program change.)
    //**
    //** @returns(asFull on Windows and Linux, asDefaultOnly on macOS, asNone elsewhere.)
    /// <summary>How much this platform lets a program change.</summary>
    /// <returns>asFull on Windows and Linux, asDefaultOnly on macOS, asNone
    /// elsewhere.</returns>
    class function Support: TSprite3DAssocSupport; static;

    //** @abstract(Whether the application is offered under Open With for the types.)
    //**
    //** On Windows and Linux, true when this unit's registration is present, whichever copy
    //** of the program it points to; Register points it at this one. On macOS, true when the
    //** bundle declares document types.
    //**
    //** @returns(True if registered.)
    /// <summary>Whether the application is offered under Open With for the types.</summary>
    /// <remarks>On Windows and Linux, true when this unit's registration is present,
    /// whichever copy of the program it points to; Register points it at this one. On macOS,
    /// true when the bundle declares document types.</remarks>
    /// <returns>True if registered.</returns>
    function IsRegistered: Boolean;

    //** @abstract(Whether this program opens every one of the types by default.)
    //**
    //** @returns(True only if it is the default for all of them.)
    /// <summary>Whether this program opens every one of the types by default.</summary>
    /// <returns>True only if it is the default for all of them.</returns>
    function IsDefault: Boolean;

    //** @abstract(Offers this program under Open With for the types.)
    //**
    //** Registers again over an older registration, so the entries point at this copy of the
    //** program. On macOS it asks Launch Services to read the bundle again.
    //**
    //** @returns(True on success; False, with LastError set, on failure or where the platform
    //** does not allow it.)
    /// <summary>Offers this program under Open With for the types.</summary>
    /// <remarks>Registers again over an older registration, so the entries point at this copy
    /// of the program. On macOS it asks Launch Services to read the bundle again.</remarks>
    /// <returns>True on success; False, with LastError set, on failure or where the platform
    /// does not allow it.</returns>
    function Register: Boolean;

    //** @abstract(Removes what Register added.)
    //**
    //** Call RestoreDefaults first if the program was made the default. Not possible on macOS,
    //** where the bundle declares the types.
    //**
    //** @returns(True on success; False, with LastError set, otherwise.)
    /// <summary>Removes what Register added.</summary>
    /// <remarks>Call RestoreDefaults first if the program was made the default. Not possible
    /// on macOS, where the bundle declares the types.</remarks>
    /// <returns>True on success; False, with LastError set, otherwise.</returns>
    function Unregister: Boolean;

    //** @abstract(Makes this program the default for the types without asking, for types
    //** that are the application's own.)
    //**
    //** Only for file types no other program has a claim to, such as the application's own
    //** documents: it does not keep the previous defaults, as MakeDefault does. On Windows
    //** it sets each extension's own default ProgID in @code(HKCU\Software\Classes), which
    //** a choice made in Windows' own How do you want to open dialog with Always still
    //** overrides; on Linux it sets each MIME type's default in @code(mimeapps.list). Call
    //** Register first. On macOS the bundle's document types do this, so it does nothing.
    //**
    //** @returns(True on success; False, with LastError set, on failure or where the platform
    //** does not allow it.)
    /// <summary>Makes this program the default for the types without asking, for types that
    /// are the application's own.</summary>
    /// <remarks>Only for file types no other program has a claim to, such as the
    /// application's own documents: it does not keep the previous defaults, as MakeDefault
    /// does. On Windows it sets each extension's own default ProgID in
    /// <c>HKCU\Software\Classes</c>, which a choice made in Windows' own How do you want to
    /// open dialog with Always still overrides; on Linux it sets each MIME type's default in
    /// <c>mimeapps.list</c>. Call Register first. On macOS the bundle's document types do
    /// this, so it does nothing.</remarks>
    /// <returns>True on success; False, with LastError set, on failure or where the platform
    /// does not allow it.</returns>
    function Claim: Boolean;

    //** @abstract(Makes this program the default for every type, recording the old defaults.)
    //**
    //** For each type not yet in ABackup, the current per-user default is added to it first,
    //** so calling this again never loses the original. On Windows a choice the user made in
    //** Windows' own dialog still wins; NeedsUserConfirmation is then set.
    //**
    //** @param(ABackup The caller's backup string, which this adds to; keep it for
    //** RestoreDefaults.)
    //**
    //** @returns(True on success; False, with LastError set, otherwise.)
    //**
    //** @seealso(RestoreDefaults)
    /// <summary>Makes this program the default for every type, recording the old
    /// defaults.</summary>
    /// <remarks>For each type not yet in ABackup, the current per-user default is added to it
    /// first, so calling this again never loses the original. On Windows a choice the user
    /// made in Windows' own dialog still wins; NeedsUserConfirmation is then set.</remarks>
    /// <param name="ABackup">The caller's backup string, which this adds to; keep it for
    /// RestoreDefaults.</param>
    /// <returns>True on success; False, with LastError set, otherwise.</returns>
    /// <seealso cref="RestoreDefaults"/>
    function MakeDefault(var ABackup: String): Boolean;

    //** @abstract(Puts back the defaults recorded by MakeDefault.)
    //**
    //** Only types still defaulting to this program are changed, so a choice the user has made
    //** since is kept. A recorded default is put back only if it is still valid; otherwise the
    //** per-user default is removed. On macOS, where a default cannot be removed, a type with
    //** no valid old default keeps this program and the reason is put in LastError. The
    //** entries dealt with are taken out of ABackup.
    //**
    //** @param(ABackup The backup string from MakeDefault; on return, what is left of it,
    //** normally empty.)
    //**
    //** @returns(True if every type was dealt with; False, with LastError set, otherwise.)
    /// <summary>Puts back the defaults recorded by MakeDefault.</summary>
    /// <remarks>Only types still defaulting to this program are changed, so a choice the user
    /// has made since is kept. A recorded default is put back only if it is still valid;
    /// otherwise the per-user default is removed. On macOS, where a default cannot be removed,
    /// a type with no valid old default keeps this program and the reason is put in LastError.
    /// The entries dealt with are taken out of ABackup.</remarks>
    /// <param name="ABackup">The backup string from MakeDefault; on return, what is left of
    /// it, normally empty.</param>
    /// <returns>True if every type was dealt with; False, with LastError set,
    /// otherwise.</returns>
    function RestoreDefaults(var ABackup: String): Boolean;

    //** @abstract(Opens the system's own page for choosing default applications.)
    //**
    //** Windows only, where it opens Settings, Default apps, at this application if Windows
    //** supports that. Does nothing elsewhere.
    /// <summary>Opens the system's own page for choosing default applications.</summary>
    /// <remarks>Windows only, where it opens Settings, Default apps, at this application if
    /// Windows supports that. Does nothing elsewhere.</remarks>
    procedure OpenSystemDefaults;

    //** @abstract(The reason the last failing method failed; empty after success.)
    /// <summary>The reason the last failing method failed; empty after success.</summary>
    property LastError: String read FLastError;
    //** @abstract(True when a default could not be changed by a program and the user has to
    //** choose it in the system's settings.)
    /// <summary>True when a default could not be changed by a program and the user has to
    /// choose it in the system's settings.</summary>
    property NeedsUserConfirmation: Boolean read FNeedsUserConfirmation;
    //** @abstract(The full path of the running program, which the registration points at.)
    /// <summary>The full path of the running program, which the registration points
    /// at.</summary>
    property ExePath: String read FExePath;
  end;

implementation

uses
  System.IOUtils, OSPaths
  {$IF DEFINED(MSWINDOWS)}
  , Winapi.Windows, Winapi.ShellAPI, System.Win.Registry
  {$ELSEIF DEFINED(S3D_DESKTOP_MACOS)}
  , Macapi.Foundation, Macapi.Helpers
  {$ENDIF}
  ;

// The backup string: one "key=value" line per type, where an empty value
// means there was no per-user default
function BackupToList(const ABackup: String): TStringList;
begin
  Result := TStringList.Create;
  Result.LineBreak := #10;
  Result.NameValueSeparator := '=';
  Result.Text := ABackup.Replace(#13, '');
end;

function ListToBackup(const AList: TStringList): String;
begin
  Result := AList.Text.Trim;
end;

{ TSprite3DFileType }

class function TSprite3DFileType.Create(const AExtension, AMimeType,
  ADescription: String): TSprite3DFileType;
begin
  Result.Extension := AExtension.Trim.ToLower;
  if not Result.Extension.StartsWith('.') then
    Result.Extension := '.' + Result.Extension;
  Result.MimeType := AMimeType;
  Result.Description := ADescription;
end;

{ TSprite3DFileAssociations }

constructor TSprite3DFileAssociations.Create(const AAppName, AProgId,
  ADescription: String; const AFileTypes: TArray<TSprite3DFileType>);
begin
  inherited Create;
  FAppName := AAppName;
  FProgId := AProgId;
  FDescription := ADescription;
  FFileTypes := Copy(AFileTypes);
  FExePath := ExpandFileName(ParamStr(0));
end;

procedure TSprite3DFileAssociations.Fail(const AMessage: String);
begin
  if FLastError = String.Empty then
    FLastError := AMessage
  else
    FLastError := FLastError + sLineBreak + AMessage;
end;

class function TSprite3DFileAssociations.Support: TSprite3DAssocSupport;
begin
  {$IF DEFINED(MSWINDOWS) or DEFINED(S3D_DESKTOP_LINUX)}
  Result := asFull;
  {$ELSEIF DEFINED(S3D_DESKTOP_MACOS)}
  Result := asDefaultOnly;
  {$ELSE}
  Result := asNone;
  {$ENDIF}
end;

{$IF DEFINED(MSWINDOWS)}
{ ---------------------------------------------------------------- Windows }

const
  CLASSES_KEY = 'Software\Classes\';
  USER_CHOICE_KEY = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\%s\UserChoice';
  REGISTERED_APPS_KEY = 'Software\RegisteredApplications';
  ASSOCF_NONE = 0;
  ASSOCSTR_EXECUTABLE = 2;
  SHCNE_ASSOCCHANGED = $08000000;
  SHCNF_IDLIST = 0;

function AssocQueryStringW(AFlags, AStr: DWORD; AAssoc, AExtra: PWideChar;
  AOut: PWideChar; var AOutLen: DWORD): HRESULT; stdcall;
  external 'shlwapi.dll' name 'AssocQueryStringW';

procedure SHChangeNotifyW(AEventId: Integer; AFlags: UINT; AItem1,
  AItem2: Pointer); stdcall; external 'shell32.dll' name 'SHChangeNotify';

function TSprite3DFileAssociations.OpenCommand: String;
begin
  Result := Format('"%s" "%%1"', [FExePath]);
end;

procedure TSprite3DFileAssociations.NotifyShell;
begin
  SHChangeNotifyW(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

function CapabilitiesKey(const AAppName: String): String;
begin
  Result := 'Software\' + AAppName + '\Capabilities';
end;

function ApplicationsKey(const AExePath: String): String;
begin
  Result := CLASSES_KEY + 'Applications\' + ExtractFileName(AExePath);
end;

// The ProgID Windows itself would use for AExtension, from the user's own
// choice in Windows' dialog; empty if there is none
function UserChoiceProgId(const AExtension: String): String;
var
  Reg: TRegistry;
begin
  Result := String.Empty;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(Format(USER_CHOICE_KEY, [AExtension])) then
    begin
      if Reg.ValueExists('ProgId') then
        Result := Reg.ReadString('ProgId');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

// A ProgID is valid if HKEY_CLASSES_ROOT, the merged per-user and
// per-machine view, still has it
function ProgIdExists(const AProgId: String): Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  if AProgId = String.Empty then
    Exit;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    Result := Reg.KeyExists(AProgId);
  finally
    Reg.Free;
  end;
end;

function TSprite3DFileAssociations.IsRegistered: Boolean;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    Result := Reg.KeyExists(CLASSES_KEY + FProgId + '\shell\open\command');
  finally
    Reg.Free;
  end;
end;

function TSprite3DFileAssociations.IsDefault: Boolean;
var
  Buffer: array[0..MAX_PATH * 2] of WideChar;
  Len: DWORD;
begin
  Result := Length(FFileTypes) > 0;
  for var FileType in FFileTypes do
  begin
    // What Explorer would actually run, after UserChoice, per-user and
    // per-machine settings are all taken into account
    Len := Length(Buffer);
    if AssocQueryStringW(ASSOCF_NONE, ASSOCSTR_EXECUTABLE,
      PWideChar(FileType.Extension), 'open', @Buffer[0], Len) <> S_OK then
      Exit(False);
    if not SameFileName(ExpandFileName(String(PWideChar(@Buffer[0]))), FExePath) then
      Exit(False);
  end;
end;

function TSprite3DFileAssociations.Register: Boolean;
var
  Reg: TRegistry;
  Cap: String;

  procedure WriteDefault(const AKey, AValue: String);
  begin
    if not Reg.OpenKey(AKey, True) then
      raise ERegistryException.Create('Can''t write HKCU\' + AKey);
    Reg.WriteString('', AValue);
    Reg.CloseKey;
  end;

begin
  FLastError := String.Empty;
  Cap := CapabilitiesKey(FAppName);
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;

      // The ProgID: how files of these types are described and opened
      WriteDefault(CLASSES_KEY + FProgId, FDescription);
      WriteDefault(CLASSES_KEY + FProgId + '\DefaultIcon', Format('"%s",0', [FExePath]));
      WriteDefault(CLASSES_KEY + FProgId + '\shell\open\command', OpenCommand);

      // The program itself, so Open With can show it by name
      if Reg.OpenKey(ApplicationsKey(FExePath), True) then
      begin
        Reg.WriteString('FriendlyAppName', FAppName);
        Reg.CloseKey;
      end;
      WriteDefault(ApplicationsKey(FExePath) + '\shell\open\command', OpenCommand);
      if Reg.OpenKey(ApplicationsKey(FExePath) + '\SupportedTypes', True) then
      begin
        for var FileType in FFileTypes do
          Reg.WriteString(FileType.Extension, String.Empty);
        Reg.CloseKey;
      end;

      // Each type lists the ProgID among its Open With choices
      for var FileType in FFileTypes do
        if Reg.OpenKey(CLASSES_KEY + FileType.Extension + '\OpenWithProgids', True) then
        begin
          Reg.WriteString(FProgId, String.Empty);
          Reg.CloseKey;
        end;

      // Listed in Settings, Default apps
      if Reg.OpenKey(Cap, True) then
      begin
        Reg.WriteString('ApplicationName', FAppName);
        Reg.WriteString('ApplicationDescription', FDescription);
        Reg.CloseKey;
      end;
      if Reg.OpenKey(Cap + '\FileAssociations', True) then
      begin
        for var FileType in FFileTypes do
          Reg.WriteString(FileType.Extension, FProgId);
        Reg.CloseKey;
      end;
      if Reg.OpenKey(REGISTERED_APPS_KEY, True) then
      begin
        Reg.WriteString(FAppName, Cap);
        Reg.CloseKey;
      end;
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t register for Open With: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Reg.Free;
  end;
  NotifyShell;
end;

function TSprite3DFileAssociations.Unregister: Boolean;
var
  Reg: TRegistry;
  Parent: String;
begin
  FLastError := String.Empty;
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      for var FileType in FFileTypes do
        if Reg.OpenKey(CLASSES_KEY + FileType.Extension + '\OpenWithProgids', False) then
        begin
          if Reg.ValueExists(FProgId) then
            Reg.DeleteValue(FProgId);
          Reg.CloseKey;
        end;
      if Reg.KeyExists(CLASSES_KEY + FProgId) then
        Reg.DeleteKey(CLASSES_KEY + FProgId);
      if Reg.KeyExists(ApplicationsKey(FExePath)) then
        Reg.DeleteKey(ApplicationsKey(FExePath));
      if Reg.KeyExists(CapabilitiesKey(FAppName)) then
        Reg.DeleteKey(CapabilitiesKey(FAppName));
      // Software\<AppName> was only made to hold Capabilities
      Parent := 'Software\' + FAppName;
      if Reg.OpenKey(Parent, False) then
      begin
        var Empty := not Reg.HasSubKeys;
        var Names := TStringList.Create;
        try
          Reg.GetValueNames(Names);
          Empty := Empty and (Names.Count = 0);
        finally
          Names.Free;
        end;
        Reg.CloseKey;
        if Empty then
          Reg.DeleteKey(Parent);
      end;
      if Reg.OpenKey(REGISTERED_APPS_KEY, False) then
      begin
        if Reg.ValueExists(FAppName) then
          Reg.DeleteValue(FAppName);
        Reg.CloseKey;
      end;
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t remove the Open With registration: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Reg.Free;
  end;
  NotifyShell;
end;

function TSprite3DFileAssociations.MakeDefault(var ABackup: String): Boolean;
var
  Reg: TRegistry;
  List: TStringList;
  Old, Choice: String;
begin
  FLastError := String.Empty;
  FNeedsUserConfirmation := False;
  List := BackupToList(ABackup);
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      for var FileType in FFileTypes do
      begin
        if not Reg.OpenKey(CLASSES_KEY + FileType.Extension, True) then
          raise ERegistryException.Create('Can''t write HKCU\' + CLASSES_KEY +
            FileType.Extension);
        Old := String.Empty;
        if Reg.ValueExists('') then
          Old := Reg.ReadString('');
        // Record the first default seen, never one of our own
        if (List.IndexOfName(FileType.Extension) < 0) and not SameText(Old, FProgId) then
          List.Add(FileType.Extension + '=' + Old);
        Reg.WriteString('', FProgId);
        Reg.CloseKey;

        // A choice made in Windows' own dialog overrides the above, and only
        // the user can change it
        Choice := UserChoiceProgId(FileType.Extension);
        if (Choice <> String.Empty) and not SameText(Choice, FProgId) then
          FNeedsUserConfirmation := True;
      end;
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t make ' + FAppName + ' the default: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Reg.Free;
    ABackup := ListToBackup(List);
    List.Free;
  end;
  NotifyShell;
end;

function TSprite3DFileAssociations.RestoreDefaults(var ABackup: String): Boolean;
var
  Reg: TRegistry;
  List: TStringList;
  Old: String;
  Index: Integer;
begin
  FLastError := String.Empty;
  FNeedsUserConfirmation := False;
  Result := True;
  List := BackupToList(ABackup);
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    for var FileType in FFileTypes do
    begin
      Index := List.IndexOfName(FileType.Extension);
      if Index >= 0 then
        Old := List.ValueFromIndex[Index]
      else
        Old := String.Empty;
      try
        if Reg.OpenKey(CLASSES_KEY + FileType.Extension, False) then
        begin
          // Only undo what is still ours
          if Reg.ValueExists('') and SameText(Reg.ReadString(''), FProgId) then
          begin
            if ProgIdExists(Old) and not SameText(Old, FProgId) then
              Reg.WriteString('', Old)
            else
              Reg.DeleteValue('');
          end;
          Reg.CloseKey;
        end;
        if Index >= 0 then
          List.Delete(Index);
      except
        on E: Exception do
        begin
          Fail('Can''t put back the default for ' + FileType.Extension + ': ' + E.Message);
          Result := False;
        end;
      end;
      // The user's own choice of this program, made in Windows' dialog,
      // can only be changed by the user
      if SameText(UserChoiceProgId(FileType.Extension), FProgId) then
        FNeedsUserConfirmation := True;
    end;
  finally
    Reg.Free;
    ABackup := ListToBackup(List);
    List.Free;
  end;
  NotifyShell;
end;

procedure TSprite3DFileAssociations.OpenSystemDefaults;
var
  Uri: String;
begin
  // registeredAppUser opens the application's own page on Windows 11; older
  // versions ignore it and show the Default apps list
  Uri := 'ms-settings:defaultapps?registeredAppUser=' + FAppName;
  ShellExecute(0, 'open', PChar(Uri), nil, nil, SW_SHOWNORMAL);
end;

function TSprite3DFileAssociations.Claim: Boolean;
var
  Reg: TRegistry;
begin
  FLastError := String.Empty;
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      // The extension's own default: this ProgID opens it
      for var FileType in FFileTypes do
        if Reg.OpenKey(CLASSES_KEY + FileType.Extension, True) then
        begin
          Reg.WriteString(String.Empty, FProgId);
          Reg.CloseKey;
        end;
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t make this program the default: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Reg.Free;
  end;
  NotifyShell;
end;

{$ELSEIF DEFINED(S3D_DESKTOP_LINUX)}
{ ------------------------------------------------------------------ Linux }

const
  libc = 'libc.so.6';
  DEFAULTS_GROUP = '[Default Applications]';

function libc_system(ACommand: MarshaledAString): Integer; cdecl;
  external libc name 'system';

function ShellQuote(const AText: String): String;
begin
  Result := '''' + AText.Replace('''', '''\''''') + '''';
end;

// Runs a command line through /bin/sh, quietly; True if it exited with 0
function RunQuiet(const ACommand: String): Boolean;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(ACommand + ' >/dev/null 2>&1');
  SetLength(Bytes, Length(Bytes) + 1);
  Bytes[High(Bytes)] := 0;
  Result := libc_system(MarshaledAString(@Bytes[0])) = 0;
end;

function XdgDir(const AVariable, AFallback: String): String;
begin
  Result := GetEnvironmentVariable(AVariable);
  if Result = String.Empty then
    Result := TPath.Combine(TPath.GetHomePath, AFallback);
end;

function DataHome: String;
begin
  Result := XdgDir('XDG_DATA_HOME', '.local/share');
end;

function ConfigHome: String;
begin
  Result := XdgDir('XDG_CONFIG_HOME', '.config');
end;

function TSprite3DFileAssociations.DesktopId: String;
begin
  Result := FAppName.ToLower.Replace(' ', '-') + '.desktop';
end;

function TSprite3DFileAssociations.DesktopFileName: String;
begin
  Result := TPath.Combine(TPath.Combine(DataHome, 'applications'), DesktopId);
end;

function TSprite3DFileAssociations.MimePackageFileName: String;
begin
  Result := TPath.Combine(TPath.Combine(TPath.Combine(DataHome, 'mime'), 'packages'),
    FAppName.ToLower.Replace(' ', '-') + '.xml');
end;

function TSprite3DFileAssociations.MimeAppsFileName: String;
begin
  Result := TPath.Combine(ConfigHome, 'mimeapps.list');
end;

// The Exec key's value: the program quoted as the Desktop Entry
// Specification asks, then %f for one local file
function TSprite3DFileAssociations.ExecLine: String;
var
  Quoted: String;
begin
  Quoted := FExePath.Replace('\', '\\').Replace('"', '\"').Replace('`', '\`')
    .Replace('$', '\$').Replace('%', '%%');
  Result := '"' + Quoted + '" %f';
end;

// True if a .desktop file with this id is installed in any data folder
function TSprite3DFileAssociations.DesktopEntryExists(const AId: String): Boolean;
var
  Dirs: TArray<String>;
  DataDirs: String;
begin
  Result := False;
  if AId = String.Empty then
    Exit;
  DataDirs := GetEnvironmentVariable('XDG_DATA_DIRS');
  if DataDirs = String.Empty then
    DataDirs := '/usr/local/share:/usr/share';
  Dirs := [DataHome] + DataDirs.Split([':']);
  for var Dir in Dirs do
  begin
    if Dir = String.Empty then
      Continue;
    // An id such as kde-foo.desktop may also live at kde/foo.desktop
    if TFile.Exists(TPath.Combine(TPath.Combine(Dir, 'applications'), AId)) or
      TFile.Exists(TPath.Combine(TPath.Combine(Dir, 'applications'),
        AId.Replace('-', '/'))) then
      Exit(True);
  end;
end;

procedure TSprite3DFileAssociations.RefreshDatabases;
begin
  // Both are optional; without them the files are still read, just later
  RunQuiet('update-mime-database ' + ShellQuote(TPath.Combine(DataHome, 'mime')));
  RunQuiet('update-desktop-database ' + ShellQuote(TPath.Combine(DataHome, 'applications')));
end;

// mimeapps.list as lines; edited by hand rather than as an ini file so
// comments and other groups are kept exactly as they are
function ReadLines(const AFileName: String): TStringList;
var
  FileName: String;
begin
  FileName := OSFriendlyPath(AFileName);
  Result := TStringList.Create;
  Result.LineBreak := #10;
  if TFile.Exists(FileName) then
    Result.Text := TFile.ReadAllText(FileName, TEncoding.UTF8).Replace(#13, '');
end;

procedure WriteLines(const AFileName: String; const ALines: TStringList);
var
  FileName: String;
begin
  FileName := OSFriendlyPath(AFileName);
  ForceDirectories(ExtractFileDir(FileName));
  TFile.WriteAllBytes(FileName, TEncoding.UTF8.GetBytes(ALines.Text));
end;

// The line index of AKey in the [Default Applications] group, or -1;
// AGroupEnd is where a new key would go (-1 if there is no such group)
function FindDefaultKey(const ALines: TStringList; const AKey: String;
  out AGroupEnd: Integer): Integer;
var
  I: Integer;
  InGroup: Boolean;
  Line: String;
begin
  Result := -1;
  AGroupEnd := -1;
  InGroup := False;
  for I := 0 to ALines.Count - 1 do
  begin
    Line := ALines[I].Trim;
    if Line.StartsWith('[') then
    begin
      if InGroup then
        Exit;   // AGroupEnd already points past the group's last key
      InGroup := SameText(Line, DEFAULTS_GROUP);
      if InGroup then
        AGroupEnd := I + 1;
      Continue;
    end;
    if not InGroup then
      Continue;
    if Line <> String.Empty then
      AGroupEnd := I + 1;
    if Line.StartsWith(AKey + '=') then
      Exit(I);
  end;
end;

function ReadDefault(const ALines: TStringList; const AKey: String): String;
var
  GroupEnd, Index: Integer;
begin
  Index := FindDefaultKey(ALines, AKey, GroupEnd);
  if Index < 0 then
    Exit(String.Empty);
  Result := ALines[Index].Trim.Substring(Length(AKey) + 1).Trim;
end;

procedure WriteDefault(const ALines: TStringList; const AKey, AValue: String);
var
  GroupEnd, Index: Integer;
begin
  Index := FindDefaultKey(ALines, AKey, GroupEnd);
  if AValue = String.Empty then
  begin
    if Index >= 0 then
      ALines.Delete(Index);
    Exit;
  end;
  if Index >= 0 then
    ALines[Index] := AKey + '=' + AValue
  else if GroupEnd >= 0 then
    ALines.Insert(GroupEnd, AKey + '=' + AValue)
  else
  begin
    if (ALines.Count > 0) and (ALines[ALines.Count - 1].Trim <> String.Empty) then
      ALines.Add(String.Empty);
    ALines.Add(DEFAULTS_GROUP);
    ALines.Add(AKey + '=' + AValue);
  end;
end;

// The first desktop id in a mimeapps.list value such as "a.desktop;b.desktop;"
function FirstId(const AValue: String): String;
var
  Parts: TArray<String>;
begin
  Parts := AValue.Split([';'], TStringSplitOptions.ExcludeEmpty);
  if Length(Parts) > 0 then
    Result := Parts[0].Trim
  else
    Result := String.Empty;
end;

function TSprite3DFileAssociations.IsRegistered: Boolean;
begin
  Result := TFile.Exists(DesktopFileName);
end;

function TSprite3DFileAssociations.IsDefault: Boolean;
var
  Lines: TStringList;
begin
  Result := Length(FFileTypes) > 0;
  Lines := ReadLines(MimeAppsFileName);
  try
    for var FileType in FFileTypes do
      if FirstId(ReadDefault(Lines, FileType.MimeType)) <> DesktopId then
        Exit(False);
  finally
    Lines.Free;
  end;
end;

function TSprite3DFileAssociations.Register: Boolean;
var
  Desktop, Mime: TStringBuilder;
  MimeTypes: String;
begin
  FLastError := String.Empty;
  MimeTypes := String.Empty;
  for var FileType in FFileTypes do
    MimeTypes := MimeTypes + FileType.MimeType + ';';

  Desktop := TStringBuilder.Create;
  Mime := TStringBuilder.Create;
  try
    try
      Desktop.Append('[Desktop Entry]').Append(#10)
        .Append('Type=Application').Append(#10)
        .Append('Name=').Append(FAppName).Append(#10)
        .Append('Comment=').Append(FDescription).Append(#10)
        .Append('Exec=').Append(ExecLine).Append(#10)
        .Append('Terminal=false').Append(#10)
        .Append('NoDisplay=false').Append(#10)
        .Append('Categories=Graphics;3DGraphics;Viewer;').Append(#10)
        .Append('MimeType=').Append(MimeTypes).Append(#10);
      ForceDirectories(ExtractFileDir(OSFriendlyPath(DesktopFileName)));
      TFile.WriteAllBytes(OSFriendlyPath(DesktopFileName),
        TEncoding.UTF8.GetBytes(Desktop.ToString));

      // Teach shared-mime-info the extensions; for a type it already knows
      // this only adds the glob
      Mime.Append('<?xml version="1.0" encoding="UTF-8"?>').Append(#10)
        .Append('<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">')
        .Append(#10);
      for var FileType in FFileTypes do
        Mime.Append('  <mime-type type="').Append(FileType.MimeType).Append('">').Append(#10)
          .Append('    <comment>').Append(FileType.Description).Append('</comment>').Append(#10)
          .Append('    <glob pattern="*').Append(FileType.Extension).Append('"/>').Append(#10)
          .Append('  </mime-type>').Append(#10);
      Mime.Append('</mime-info>').Append(#10);
      ForceDirectories(ExtractFileDir(OSFriendlyPath(MimePackageFileName)));
      TFile.WriteAllBytes(OSFriendlyPath(MimePackageFileName),
        TEncoding.UTF8.GetBytes(Mime.ToString));
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t register for Open With: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Desktop.Free;
    Mime.Free;
  end;
  RefreshDatabases;
end;

function TSprite3DFileAssociations.Unregister: Boolean;
begin
  FLastError := String.Empty;
  try
    if TFile.Exists(DesktopFileName) then
      TFile.Delete(DesktopFileName);
    if TFile.Exists(MimePackageFileName) then
      TFile.Delete(MimePackageFileName);
    Result := True;
  except
    on E: Exception do
    begin
      Fail('Can''t remove the Open With registration: ' + E.Message);
      Result := False;
    end;
  end;
  RefreshDatabases;
end;

function TSprite3DFileAssociations.MakeDefault(var ABackup: String): Boolean;
var
  Lines, List: TStringList;
  Old: String;
begin
  FLastError := String.Empty;
  FNeedsUserConfirmation := False;
  List := BackupToList(ABackup);
  Lines := ReadLines(MimeAppsFileName);
  try
    try
      for var FileType in FFileTypes do
      begin
        Old := ReadDefault(Lines, FileType.MimeType);
        if (List.IndexOfName(FileType.MimeType) < 0) and (FirstId(Old) <> DesktopId) then
          List.Add(FileType.MimeType + '=' + Old);
        WriteDefault(Lines, FileType.MimeType, DesktopId + ';');
      end;
      WriteLines(MimeAppsFileName, Lines);
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t make ' + FAppName + ' the default: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    ABackup := ListToBackup(List);
    List.Free;
    Lines.Free;
  end;
end;

function TSprite3DFileAssociations.RestoreDefaults(var ABackup: String): Boolean;
var
  Lines, List: TStringList;
  Old, Valid: String;
  Index: Integer;
begin
  FLastError := String.Empty;
  FNeedsUserConfirmation := False;
  List := BackupToList(ABackup);
  Lines := ReadLines(MimeAppsFileName);
  try
    try
      for var FileType in FFileTypes do
      begin
        Index := List.IndexOfName(FileType.MimeType);
        if Index >= 0 then
          Old := List.ValueFromIndex[Index]
        else
          Old := String.Empty;
        if FirstId(ReadDefault(Lines, FileType.MimeType)) = DesktopId then
        begin
          // Keep only the applications that are still installed
          Valid := String.Empty;
          for var Id in Old.Split([';'], TStringSplitOptions.ExcludeEmpty) do
            if (Id.Trim <> DesktopId) and DesktopEntryExists(Id.Trim) then
              Valid := Valid + Id.Trim + ';';
          WriteDefault(Lines, FileType.MimeType, Valid);
        end;
        if Index >= 0 then
          List.Delete(Index);
      end;
      WriteLines(MimeAppsFileName, Lines);
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t put back the previous defaults: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    ABackup := ListToBackup(List);
    List.Free;
    Lines.Free;
  end;
end;

procedure TSprite3DFileAssociations.OpenSystemDefaults;
begin
  // Desktops differ; there is no one settings page to open
end;

function TSprite3DFileAssociations.Claim: Boolean;
var
  Lines: TStringList;
begin
  FLastError := String.Empty;
  Lines := ReadLines(MimeAppsFileName);
  try
    try
      for var FileType in FFileTypes do
        WriteDefault(Lines, FileType.MimeType, DesktopId);
      WriteLines(MimeAppsFileName, Lines);
      Result := True;
    except
      on E: Exception do
      begin
        Fail('Can''t make this program the default: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

{$ELSEIF DEFINED(S3D_DESKTOP_MACOS)}
{ ------------------------------------------------------------------ macOS }

const
  libCF = '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation';
  libCS = '/System/Library/Frameworks/CoreServices.framework/CoreServices';
  kCFStringEncodingUTF8 = $08000100;
  kCFURLPOSIXPathStyle = 0;
  kLSRolesAll = $FFFFFFFF;

// Declared here with plain pointers, so the unit does not depend on how
// the RTL's own headers type them
function CFStringCreateWithBytes(AAlloc: Pointer; ABytes: Pointer; ANumBytes: NativeInt;
  AEncoding: UInt32; AIsExternal: Boolean): Pointer; cdecl;
  external libCF name 'CFStringCreateWithBytes';
function CFStringGetLength(AString: Pointer): NativeInt; cdecl;
  external libCF name 'CFStringGetLength';
function CFStringGetCString(AString: Pointer; ABuffer: Pointer; ABufferSize: NativeInt;
  AEncoding: UInt32): Boolean; cdecl; external libCF name 'CFStringGetCString';
procedure CFRelease(AObject: Pointer); cdecl; external libCF name 'CFRelease';
function CFArrayGetCount(AArray: Pointer): NativeInt; cdecl;
  external libCF name 'CFArrayGetCount';
function CFURLCreateWithFileSystemPath(AAlloc, APath: Pointer; AStyle: NativeInt;
  AIsDirectory: Boolean): Pointer; cdecl;
  external libCF name 'CFURLCreateWithFileSystemPath';

function UTTypeCreatePreferredIdentifierForTag(ATagClass, ATag,
  AConformingTo: Pointer): Pointer; cdecl;
  external libCS name 'UTTypeCreatePreferredIdentifierForTag';
function LSCopyDefaultRoleHandlerForContentType(AContentType: Pointer;
  ARole: UInt32): Pointer; cdecl;
  external libCS name 'LSCopyDefaultRoleHandlerForContentType';
function LSSetDefaultRoleHandlerForContentType(AContentType: Pointer; ARole: UInt32;
  AHandler: Pointer): Int32; cdecl;
  external libCS name 'LSSetDefaultRoleHandlerForContentType';
function LSRegisterURL(AUrl: Pointer; AUpdate: Boolean): Int32; cdecl;
  external libCS name 'LSRegisterURL';
function LSCopyApplicationURLsForBundleIdentifier(ABundleId: Pointer;
  AOutError: Pointer): Pointer; cdecl;
  external libCS name 'LSCopyApplicationURLsForBundleIdentifier';

// A new CFString; the caller releases it
function NewCFString(const AText: String): Pointer;
var
  Bytes: TBytes;
begin
  // One extra zero byte, so even an empty string has a valid pointer
  Bytes := TEncoding.UTF8.GetBytes(AText + #0);
  Result := CFStringCreateWithBytes(nil, @Bytes[0], Length(Bytes) - 1,
    kCFStringEncodingUTF8, False);
end;

// A CFString as a Delphi string; nil gives an empty string
function CFToStr(const AString: Pointer): String;
var
  Bytes: TBytes;
  Size: NativeInt;
begin
  Result := String.Empty;
  if AString = nil then
    Exit;
  // At most four UTF-8 bytes per UTF-16 unit, plus the terminating zero
  Size := CFStringGetLength(AString) * 4 + 1;
  SetLength(Bytes, Size);
  if CFStringGetCString(AString, @Bytes[0], Size, kCFStringEncodingUTF8) then
    Result := UTF8ToString(PAnsiChar(@Bytes[0]));
end;

// The UTI macOS uses for files with this extension
function ExtensionUti(const AExtension: String): Pointer;
var
  TagClass, Tag: Pointer;
begin
  TagClass := NewCFString('public.filename-extension');
  Tag := NewCFString(AExtension.TrimLeft(['.']));
  try
    Result := UTTypeCreatePreferredIdentifierForTag(TagClass, Tag, nil);
  finally
    CFRelease(Tag);
    CFRelease(TagClass);
  end;
end;

function CurrentHandler(const AExtension: String): String;
var
  Uti, Handler: Pointer;
begin
  Result := String.Empty;
  Uti := ExtensionUti(AExtension);
  if Uti = nil then
    Exit;
  try
    Handler := LSCopyDefaultRoleHandlerForContentType(Uti, kLSRolesAll);
    if Handler <> nil then
    try
      Result := CFToStr(Handler);
    finally
      CFRelease(Handler);
    end;
  finally
    CFRelease(Uti);
  end;
end;

function SetHandler(const AExtension, ABundleId: String): Boolean;
var
  Uti, Id: Pointer;
begin
  Uti := ExtensionUti(AExtension);
  if Uti = nil then
    Exit(False);
  Id := NewCFString(ABundleId);
  try
    Result := LSSetDefaultRoleHandlerForContentType(Uti, kLSRolesAll, Id) = 0;
  finally
    CFRelease(Id);
    CFRelease(Uti);
  end;
end;

// A bundle identifier is valid if Launch Services still knows an app for it
function AppInstalled(const ABundleId: String): Boolean;
var
  Id, Urls: Pointer;
begin
  Result := False;
  if ABundleId = String.Empty then
    Exit;
  Id := NewCFString(ABundleId);
  try
    Urls := LSCopyApplicationURLsForBundleIdentifier(Id, nil);
    if Urls <> nil then
    try
      Result := CFArrayGetCount(Urls) > 0;
    finally
      CFRelease(Urls);
    end;
  finally
    CFRelease(Id);
  end;
end;

function MainBundle: NSBundle;
begin
  Result := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
end;

function TSprite3DFileAssociations.BundleId: String;
begin
  Result := String.Empty;
  if (MainBundle <> nil) and (MainBundle.bundleIdentifier <> nil) then
    Result := NSStrToStr(MainBundle.bundleIdentifier);
end;

function TSprite3DFileAssociations.IsRegistered: Boolean;
begin
  Result := (MainBundle <> nil) and
    (MainBundle.objectForInfoDictionaryKey(StrToNSStr('CFBundleDocumentTypes')) <> nil);
end;

function TSprite3DFileAssociations.IsDefault: Boolean;
var
  Id: String;
begin
  Id := BundleId;
  Result := (Id <> String.Empty) and (Length(FFileTypes) > 0);
  for var FileType in FFileTypes do
    if not SameText(CurrentHandler(FileType.Extension), Id) then
      Exit(False);
end;

function TSprite3DFileAssociations.Register: Boolean;
var
  Path, Url: Pointer;
begin
  FLastError := String.Empty;
  Result := IsRegistered;
  if not Result then
  begin
    Fail('This build does not declare its document types in Info.plist');
    Exit;
  end;
  // Ask Launch Services to read this copy of the bundle again
  Path := NewCFString(NSStrToStr(MainBundle.bundlePath));
  try
    Url := CFURLCreateWithFileSystemPath(nil, Path, kCFURLPOSIXPathStyle, True);
    if Url <> nil then
    try
      LSRegisterURL(Url, True);
    finally
      CFRelease(Url);
    end;
  finally
    CFRelease(Path);
  end;
end;

function TSprite3DFileAssociations.Unregister: Boolean;
begin
  FLastError := String.Empty;
  Fail('On macOS, Open With comes from the application bundle and can''t be removed here');
  Result := False;
end;

function TSprite3DFileAssociations.MakeDefault(var ABackup: String): Boolean;
var
  List: TStringList;
  Id, Old: String;
begin
  FLastError := String.Empty;
  FNeedsUserConfirmation := False;
  Id := BundleId;
  if Id = String.Empty then
  begin
    Fail('This build has no bundle identifier');
    Exit(False);
  end;
  Result := True;
  List := BackupToList(ABackup);
  try
    for var FileType in FFileTypes do
    begin
      Old := CurrentHandler(FileType.Extension);
      if (List.IndexOfName(FileType.Extension) < 0) and not SameText(Old, Id) then
        List.Add(FileType.Extension + '=' + Old);
      if not SetHandler(FileType.Extension, Id) then
      begin
        Fail('Can''t make ' + FAppName + ' the default for ' + FileType.Extension);
        Result := False;
      end;
    end;
  finally
    ABackup := ListToBackup(List);
    List.Free;
  end;
end;

function TSprite3DFileAssociations.RestoreDefaults(var ABackup: String): Boolean;
var
  List: TStringList;
  Id, Old: String;
  Index: Integer;
begin
  FLastError := String.Empty;
  FNeedsUserConfirmation := False;
  Id := BundleId;
  Result := True;
  List := BackupToList(ABackup);
  try
    for var FileType in FFileTypes do
    begin
      Index := List.IndexOfName(FileType.Extension);
      if Index >= 0 then
        Old := List.ValueFromIndex[Index]
      else
        Old := String.Empty;
      if SameText(CurrentHandler(FileType.Extension), Id) then
      begin
        if AppInstalled(Old) and not SameText(Old, Id) then
        begin
          if not SetHandler(FileType.Extension, Old) then
          begin
            Fail('Can''t put back ' + Old + ' for ' + FileType.Extension);
            Result := False;
            Continue;   // keep its backup entry for another try
          end;
        end
        else
        begin
          // macOS has no way to remove a default, only to choose another
          Fail('No previous application to go back to for ' + FileType.Extension +
            '; choose one in Finder''s Get Info window');
          FNeedsUserConfirmation := True;
        end;
      end;
      if Index >= 0 then
        List.Delete(Index);
    end;
  finally
    ABackup := ListToBackup(List);
    List.Free;
  end;
end;

procedure TSprite3DFileAssociations.OpenSystemDefaults;
begin
  // macOS has no settings page for default applications
end;

function TSprite3DFileAssociations.Claim: Boolean;
begin
  // The bundle's document types claim them
  FLastError := String.Empty;
  Result := True;
end;

{$ELSE}
{ ------------------------------------------------------- Android and iOS }

function TSprite3DFileAssociations.IsRegistered: Boolean;
begin
  Result := False;
end;

function TSprite3DFileAssociations.IsDefault: Boolean;
begin
  Result := False;
end;

function TSprite3DFileAssociations.Register: Boolean;
begin
  FLastError := 'Not supported on this platform';
  Result := False;
end;

function TSprite3DFileAssociations.Unregister: Boolean;
begin
  FLastError := 'Not supported on this platform';
  Result := False;
end;

function TSprite3DFileAssociations.MakeDefault(var ABackup: String): Boolean;
begin
  FLastError := 'Not supported on this platform';
  Result := False;
end;

function TSprite3DFileAssociations.RestoreDefaults(var ABackup: String): Boolean;
begin
  FLastError := 'Not supported on this platform';
  Result := False;
end;

procedure TSprite3DFileAssociations.OpenSystemDefaults;
begin
end;

function TSprite3DFileAssociations.Claim: Boolean;
begin
  FLastError := 'Not supported on this platform';
  Result := False;
end;

{$ENDIF}

end.
