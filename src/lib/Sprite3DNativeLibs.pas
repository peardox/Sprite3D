//** @abstract(Where a program's own native libraries are kept on each platform.)
//**
//** Shared libraries a program ships with, such as FFmpeg's, belong in a different place on
//** each platform. NativeLibraryFolders lists, best first, the folders a library is looked for
//** in: the platform's usual place for an application's own libraries, then a
//** @code(dlls/<key>) folder beside the executable and in the folders above it, which is
//** where a build run from the source tree finds a repository's @code(dlls) folder.
//** NativePlatformKey names the platform as those folders do.
//**
//** @preformatted(
//** Platform                Key            Deployed to
//** Windows 32-bit          win32          beside the .exe
//** Windows 64-bit          win64          beside the .exe
//** Windows ARM64EC         win64arm       beside the .exe
//** macOS Intel             macx64         Sprite3d.app/Contents/Frameworks
//** macOS Apple silicon     macarm         Sprite3d.app/Contents/Frameworks
//** Linux 64-bit            linux64        lib beside the executable
//** Android 32-bit          android32      the APK's lib/armeabi-v7a
//** Android 64-bit          android64      the APK's lib/arm64-v8a
//** iOS device             iosarm64       Sprite3d.app/Frameworks
//** iOS simulator          iossimarm64    Sprite3d.app/Frameworks
//** )
//**
//** An ARM64EC program can load x64 and ARM64EC libraries but not plain ARM64 ones, so
//** @code(win64arm) usually holds the same x64 libraries as @code(win64); when run from the
//** source tree, @code(dlls/win64) is looked in after @code(dlls/win64arm) for that reason.
//**
//** Nothing here loads anything. For any thread.
unit Sprite3DNativeLibs;

{
  Where a program's own native libraries are kept on each platform.

  Shared libraries a program ships with, such as FFmpeg's, belong in a
  different place on each platform. NativeLibraryFolders lists, best first,
  the folders a library is looked for in: the platform's usual place for an
  application's own libraries, then a dlls/<key> folder beside the
  executable and in the folders above it, which is where a build run from
  the source tree finds a repository's dlls folder. NativePlatformKey names
  the platform as those folders do.

    Platform                Key            Deployed to
    Windows 32-bit          win32          beside the .exe
    Windows 64-bit          win64          beside the .exe
    Windows ARM64EC         win64arm       beside the .exe
    macOS Intel             macx64         Sprite3d.app/Contents/Frameworks
    macOS Apple silicon     macarm         Sprite3d.app/Contents/Frameworks
    Linux 64-bit            linux64        lib beside the executable
    Android 32-bit          android32      the APK's lib/armeabi-v7a
    Android 64-bit          android64      the APK's lib/arm64-v8a
    iOS device              iosarm64       Sprite3d.app/Frameworks
    iOS simulator           iossimarm64    Sprite3d.app/Frameworks

  An ARM64EC program can load x64 and ARM64EC libraries but not plain ARM64
  ones, so win64arm usually holds the same x64 libraries as win64; when run
  from the source tree, dlls/win64 is looked in after dlls/win64arm for that
  reason.

  Nothing here loads anything. For any thread.
}

interface

//** @abstract(The platform's name, as used for @code(dlls) folders and @code(openh264.json).)
//**
//** @returns(One of the keys in the unit description, such as @code('win64').)
/// <summary>The platform's name, as used for <c>dlls</c> folders and
/// <c>openh264.json</c>.</summary>
/// <returns>One of the keys in the unit description, such as <c>'win64'</c>.</returns>
function NativePlatformKey: String;

//** @abstract(The platform's usual folder for an application's own libraries.)
//**
//** @returns(The folder, with no trailing delimiter, whether or not it exists.)
/// <summary>The platform's usual folder for an application's own libraries.</summary>
/// <returns>The folder, with no trailing delimiter, whether or not it exists.</returns>
function DeployedLibraryFolder: String;

//** @abstract(The folders to look for the program's own libraries in, best first.)
//**
//** DeployedLibraryFolder; the executable's own folder; a @code(dlls/<key>) folder beside the
//** executable; and @code(dlls/<key>) in each of the six folders above it. Folders may not
//** exist, and none is repeated. On Android only DeployedLibraryFolder is given, as the
//** executable's path means nothing there.
//**
//** @returns(The folders, without trailing delimiters.)
/// <summary>The folders to look for the program's own libraries in, best first.</summary>
/// <remarks>DeployedLibraryFolder; the executable's own folder; a <c>dlls/&lt;key&gt;</c>
/// folder beside the executable; and <c>dlls/&lt;key&gt;</c> in each of the six folders above
/// it. Folders may not exist, and none is repeated. On Android only DeployedLibraryFolder is
/// given, as the executable's path means nothing there.</remarks>
/// <returns>The folders, without trailing delimiters.</returns>
function NativeLibraryFolders: TArray<String>;

implementation

uses
  System.SysUtils, System.IOUtils;

function NativePlatformKey: String;
begin
  {$IF DEFINED(MSWINDOWS) and DEFINED(WIN32)}
  Result := 'win32';
  {$ELSEIF DEFINED(MSWINDOWS) and (DEFINED(ARM64EC) or DEFINED(CPUARM64))}
  // Delphi's WinARM64EC compiler defines ARM64EC and CPUARM64
  Result := 'win64arm';
  {$ELSEIF DEFINED(MSWINDOWS)}
  Result := 'win64';
  {$ELSEIF DEFINED(IOS) and DEFINED(IOSSIMULATOR)}
  Result := 'iossimarm64';
  {$ELSEIF DEFINED(IOS)}
  Result := 'iosarm64';
  {$ELSEIF DEFINED(MACOS) and DEFINED(CPUARM64)}
  Result := 'macarm';
  {$ELSEIF DEFINED(MACOS)}
  Result := 'macx64';
  {$ELSEIF DEFINED(ANDROID) and DEFINED(CPU64BITS)}
  Result := 'android64';
  {$ELSEIF DEFINED(ANDROID)}
  Result := 'android32';
  {$ELSE}
  Result := 'linux64';
  {$IFEND}
end;

function ExeFolder: String;
begin
  Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function DeployedLibraryFolder: String;
begin
  {$IF DEFINED(MSWINDOWS)}
  Result := ExeFolder;
  {$ELSEIF DEFINED(IOS)}
  // ParamStr(0) is the executable at the top of Sprite3d.app
  Result := TPath.Combine(ExeFolder, 'Frameworks');
  {$ELSEIF DEFINED(MACOS)}
  // Sprite3d.app/Contents/MacOS/../Frameworks
  Result := TPath.GetFullPath(TPath.Combine(ExeFolder, '../Frameworks'));
  {$ELSEIF DEFINED(ANDROID)}
  // The APK's lib/<abi> folder, unpacked by the system
  Result := ExcludeTrailingPathDelimiter(TPath.GetLibraryPath);
  {$ELSE}
  Result := TPath.Combine(ExeFolder, 'lib');
  {$IFEND}
end;

function NativeLibraryFolders: TArray<String>;
var
  Folders: TArray<String>;   // a nested routine cannot reach Result
  Dir, Parent: String;
  Level: Integer;

  procedure Add(const AFolder: String);
  var
    Known: String;
  begin
    if AFolder = String.Empty then
      Exit;
    for Known in Folders do
      if SameFileName(Known, AFolder) then
        Exit;
    Folders := Folders + [AFolder];
  end;

begin
  Folders := nil;
  Add(DeployedLibraryFolder);
  {$IFNDEF ANDROID}
  Dir := ExeFolder;
  Add(Dir);
  Add(TPath.Combine(Dir, TPath.Combine('dlls', NativePlatformKey)));
  // A build run from the source tree, such as src/Win64/Debug, finds the
  // repository's dlls folder a few levels up
  for Level := 1 to 6 do
  begin
    Parent := ExtractFileDir(Dir);
    if (Parent = String.Empty) or (Parent = Dir) then
      Break;
    Dir := Parent;
    Add(TPath.Combine(Dir, TPath.Combine('dlls', NativePlatformKey)));
    {$IF DEFINED(MSWINDOWS) and (DEFINED(ARM64EC) or DEFINED(CPUARM64))}
    // ARM64EC loads x64 libraries too
    Add(TPath.Combine(Dir, TPath.Combine('dlls', 'win64')));
    {$IFEND}
  end;
  {$ENDIF}
  Result := Folders;
end;

end.
