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
/// <summary>The folder a program's own files are deployed to.</summary>
/// <remarks>Windows and Linux: the executable's folder. macOS: the application bundle's
/// Resources folder. Android: the app's private files folder. On Windows, when started from
/// the IDE, whether under the debugger or not, DevelopmentPath is taken relative to the
/// executable's folder instead, for example <c>'../../../'</c> for the repository root from
/// <c>src/Win64/Debug</c>. iOS: not handled yet; the result is undefined.</remarks>
/// <param name="DevelopmentPath">A folder relative to the executable's, used on Windows when
/// started from the IDE; empty to always use the executable's folder.</param>
/// <returns>The folder, ending with a path delimiter.</returns>
/// <exception cref="EOSError">If Windows or Linux cannot report the executable's
/// path.</exception>
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
/// <summary>The folder the program's executable is in, for libraries shipped with
/// it.</summary>
/// <remarks>As GetAssetsPath, except that on macOS it is the bundle's executable folder,
/// <c>Contents/MacOS</c>, and on Android nothing is returned yet.</remarks>
/// <param name="DevelopmentPath">A folder relative to the executable's, used on Windows when
/// started from the IDE; empty to always use the executable's folder.</param>
/// <returns>The folder, ending with a path delimiter.</returns>
/// <exception cref="EOSError">If Windows or Linux cannot report the executable's
/// path.</exception>
function GetBinaryPath(const DevelopmentPath: string = ''): string;

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
