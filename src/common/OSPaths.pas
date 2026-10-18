unit OSPaths;

interface

function GetAssetsPath(const DevelopmentPath: string = ''): string;
// GetAssetsPath is a multi-OS (Currently Win/Mac/Linux) path
// resolver that will ...
// Linux  - Return application directory
// Window - Return application directory
// MacOS  - Return application bundle Resources directory
//
// Window (Running from IDE) - Returns a directory relative application
//                             directory as passed in DevelopmentPath for
//                             example '../..' that is within the build tree
//
// All returned paths will have the OS relevant path delimeter at the end
// therefore appending e.g. 'assets' + pathdelim to this would return a
// consistent folder layout accross systems that will be relevant for
// application deployment as well
//
// ToDo: Android + iOS

function GetBinaryPath(const DevelopmentPath: string = ''): string;
// See GetAssetsPath
// This is intended to allow development dynamic libraries
// to be flexibly loaded (not as widely useful)

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
end;


end.
