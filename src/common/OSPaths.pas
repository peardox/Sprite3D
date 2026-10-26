//** @abstract(Where the program and its assets are, on each platform.)
//**
//** GetAssetsPath gives the folder a program's own files, such as models, are deployed to, and
//** GetBinaryPath the folder its executable is in, for loading libraries shipped with it. On
//** Windows, when the program was started from the RAD Studio IDE, either can instead give a
//** folder relative to the executable, such as the repository root, so a build run from the
//** source tree finds the files there.
//**
//** Every path returned ends with the platform's path delimiter, so a folder name can be
//** appended directly. iOS is not handled yet.
//**
//** OSFriendlyPath turns any path into the platform's own form, with only @code(\) between
//** its parts on Windows and only @code(/) elsewhere. Some Windows targets, such as Win64 on
//** ARM (ARM64EC), do not accept @code(/) in every path they are given, so every file the
//** application opens goes through it first, as do the folders this unit returns.
unit OSPaths;

{
  Where the program and its assets are, on each platform.

  GetAssetsPath gives the folder a program's own files, such as models, are
  deployed to, and GetBinaryPath the folder its executable is in, for
  loading libraries shipped with it. On Windows, when the program was
  started from the RAD Studio IDE, either can instead give a folder relative
  to the executable, such as the repository root, so a build run from the
  source tree finds the files there.

  Every path returned ends with the platform's path delimiter, so a folder
  name can be appended directly. iOS is not handled yet.

  OSFriendlyPath turns any path into the platform's own form, with only \
  between its parts on Windows and only / elsewhere. Some Windows targets,
  such as Win64 on ARM (ARM64EC), do not accept / in every path they are
  given, so every file the application opens goes through it first, as do
  the folders this unit returns.
}

interface

//** @abstract(The folder a program's own files are deployed to.)
//**
//** Windows and Linux: the executable's folder. macOS: the application bundle's Resources
//** folder. Android: the app's private files folder. On Windows, when started from the IDE,
//** whether under the debugger or not, DevelopmentPath is taken relative to the executable's
//** folder instead, for example @code('../../../') for the repository root from
//** @code(src/Win64/Debug). iOS: not handled yet; the result is undefined.
//**
//** @param(DevelopmentPath A folder relative to the executable's, used on Windows when started
//** from the IDE; empty to always use the executable's folder.)
//**
//** @returns(The folder, ending with a path delimiter.)
//**
//** @raises(EOSError If Windows or Linux cannot report the executable's path.)
function GetAssetsPath(const DevelopmentPath: string = ''): string;

//** @abstract(The folder the program's executable is in, for libraries shipped with it.)
//**
//** As GetAssetsPath, except that on macOS it is the bundle's executable folder,
//** @code(Contents/MacOS), and on Android nothing is returned yet.
//**
//** @param(DevelopmentPath A folder relative to the executable's, used on Windows when started
//** from the IDE; empty to always use the executable's folder.)
//**
//** @returns(The folder, ending with a path delimiter.)
//**
//** @raises(EOSError If Windows or Linux cannot report the executable's path.)
function GetBinaryPath(const DevelopmentPath: string = ''): string;

//** @abstract(A path in the platform's own form: @code(\) between its parts on Windows,
//** @code(/) elsewhere.)
//**
//** Every @code(/) and @code(\) becomes PathDelim, and a run of them after the start becomes
//** one, so a folder ending in a delimiter joined to a name starting with one still gives a
//** valid path. Delimiters at the very start are kept as they are, so Windows network paths
//** such as @code(\\server\share) and @code(\\?\) paths survive. Nothing else changes:
//** the path is not expanded, and is not checked to exist. Outside Windows, @code(\) is a
//** legal character in a file name, but a path given with Windows delimiters, as one kept
//** in a settings file written on Windows may be, is the far likelier meaning.
//**
//** @param(APath The path, absolute or relative; empty gives empty.)
//**
//** @returns(The path with the platform's delimiters.)
function OSFriendlyPath(const APath: string): string;

implementation

uses
  System.SysUtils
  {$IF DEFINED(IOS)}
  , iOSapi.Foundation, iOSapi.Helpers
  {$ELSEIF DEFINED(ANDROID)}
  , Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText
  {$ELSEIF DEFINED(MACOS)}
  , Macapi.Foundation, Macapi.Helpers
{$ELSEIF DEFINED(MSWINDOWS)}
  , System.IOUtils, Winapi.Windows, Winapi.TlHelp32
{$ELSEIF DEFINED(LINUX)}
  , Posix.Unistd, Posix.SysTypes
{$ENDIF}
;

{$IF DEFINED(MSWINDOWS)}
function IsRunningFromIDE: Boolean;
var
  Snapshot: THandle;
  Entry: TProcessEntry32;
  ParentPID: DWORD;
begin
  // Set by the Delphi debugger when the app is started with F9
  if DebugHook <> 0 then
    Exit(True);

  // Otherwise check whether the parent process is the IDE (Run Without Debugging)
  Result := False;
  ParentPID := 0;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    // Find our own process to get the parent's PID
    Entry.dwSize := SizeOf(Entry);
    if Process32First(Snapshot, Entry) then
      repeat
        if Entry.th32ProcessID = GetCurrentProcessId then
        begin
          ParentPID := Entry.th32ParentProcessID;
          Break;
        end;
      until not Process32Next(Snapshot, Entry);

    if ParentPID = 0 then
      Exit;

    // Find the parent and check its executable name
    Entry.dwSize := SizeOf(Entry);
    if Process32First(Snapshot, Entry) then
      repeat
        if Entry.th32ProcessID = ParentPID then
          Exit(SameText(ExtractFileName(PChar(@Entry.szExeFile)), 'bds.exe'));
      until not Process32Next(Snapshot, Entry);
  finally
    CloseHandle(Snapshot);
  end;
end;

function GetApplicationPath: string;
var
  Buffer: array of Char;
  Len: DWORD;
begin
  Result := '';
  SetLength(Buffer, MAX_PATH);
  repeat
    Len := GetModuleFileName(0, PChar(Buffer), Length(Buffer));
    if Len = 0 then
      RaiseLastOSError;
    if Len < DWORD(Length(Buffer)) then
      Break;
    SetLength(Buffer, Length(Buffer) * 2);  // Path was truncated, so grow the buffer and retry
  until False;
  SetString(Result, PChar(Buffer), Len);
  Result := ExtractFilePath(Result);
end;
{$ENDIF}

function GetDroidApplicationResourcePath: string;
begin
  Result := '';
  {$IFDEF ANDROID}
  Result := IncludeTrailingPathDelimiter(
    JStringToString(TAndroidHelper.Context.getFilesDir.getAbsolutePath));
  {$ENDIF}
end;

function GetMacBundleResourcePath: string;
{$IF DEFINED(IOS)}
{$ELSEIF DEFINED(MACOS)}
var
  Bundle: NSBundle;
{$ENDIF}
begin
  Result := '';
  {$IF DEFINED(IOS)}
  {$ELSEIF DEFINED(MACOS)}
  Bundle := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
  if Bundle <> nil then
    Result := IncludeTrailingPathDelimiter(NSStrToStr(Bundle.resourcePath));
  {$ENDIF}
end;

function GetMacBundleBinaryPath: string;
{$IF DEFINED(IOS)}
{$ELSEIF DEFINED(MACOS)}
var
  Bundle: NSBundle;
{$ENDIF}
begin
  Result := '';
  {$IF DEFINED(IOS)}
  {$ELSEIF DEFINED(MACOS)}
  Bundle := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
  if Bundle <> nil then
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(NSStrToStr(Bundle.executablePath)));
  {$ENDIF}
end;

function GetLinuxApplicationPath: string;
{$IF DEFINED(LINUX)}
var
  Buffer: TBytes;
  Len: ssize_t;
{$ENDIF}
begin
  Result := '';
  {$IF DEFINED(LINUX)}
  SetLength(Buffer, 1024);
  repeat
    Len := readlink('/proc/self/exe', MarshaledAString(Buffer), Length(Buffer));
    if Len < 0 then
      RaiseLastOSError;
    if Len < Length(Buffer) then
      Break;
    SetLength(Buffer, Length(Buffer) * 2);  // Path may be truncated, so grow the buffer and retry
  until False;

  // readlink doesn't null-terminate, and the path is UTF-8 bytes
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(TEncoding.UTF8.GetString(Buffer, 0, Len)));
  {$ENDIF}
end;
function OSFriendlyPath(const APath: string): string;
var
  I, Lead: Integer;
  Builder: TStringBuilder;
  Last: Boolean;
begin
  if APath = '' then
    Exit('');
  // The delimiters it starts with are kept, in the platform's form
  Lead := 0;
  while (Lead < APath.Length) and CharInSet(APath.Chars[Lead], ['/', '\']) do
    Inc(Lead);
  Builder := TStringBuilder.Create(APath.Length);
  try
    Builder.Append(PathDelim, Lead);
    Last := Lead > 0;
    for I := Lead to APath.Length - 1 do
      if CharInSet(APath.Chars[I], ['/', '\']) then
      begin
        if not Last then
          Builder.Append(PathDelim);
        Last := True;
      end
      else
      begin
        Builder.Append(APath.Chars[I]);
        Last := False;
      end;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function GetAssetsPath(const DevelopmentPath: string = ''): string;
begin
  {$IF DEFINED(IOS)}
  //
  {$ELSEIF DEFINED(ANDROID)}
  Result := GetDroidApplicationResourcePath;
  {$ELSEIF DEFINED(MACOS)}
  Result := GetMacBundleResourcePath;
  {$ELSEIF DEFINED(MSWINDOWS)}
  Result := GetApplicationPath;
  // When launched from the IDE, resolve DevelopmentPath relative to the exe folder
  if (DevelopmentPath <> '') and IsRunningFromIDE then
    Result := IncludeTrailingPathDelimiter(
      ExpandFileName(TPath.Combine(Result, DevelopmentPath)));
  {$ELSEIF DEFINED(LINUX)}
  Result := GetLinuxApplicationPath;
  {$ENDIF}
  Result := OSFriendlyPath(Result);
end;

function GetBinaryPath(const DevelopmentPath: string = ''): string;
begin
  {$IF DEFINED(IOS)}
  //
  {$ELSEIF DEFINED(ANDROID)}
  //
  {$ELSEIF DEFINED(MACOS)}
  Result := GetMacBundleBinaryPath;
  {$ELSEIF DEFINED(MSWINDOWS)}
  Result := GetApplicationPath;
  if(Result = '') then
    Result := 'assets/';
  // When launched from the IDE, resolve DevelopmentPath relative to the exe folder
  if (DevelopmentPath <> '') and IsRunningFromIDE then
    Result := IncludeTrailingPathDelimiter(
      ExpandFileName(TPath.Combine(Result, DevelopmentPath)));
  {$ELSEIF DEFINED(LINUX)}
  Result := GetLinuxApplicationPath;
  {$ELSE}
  ShowMesage('Unsupported OS');
  {$ENDIF}
  Result := OSFriendlyPath(Result);
end;


end.
