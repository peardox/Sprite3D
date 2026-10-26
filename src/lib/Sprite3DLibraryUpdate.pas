//** @abstract(Keeps a downloaded native library, such as OpenH264, up to date from a list of
//** downloads published on a web server.)
//**
//** The list is a JSON file fetched at run time, such as
//** @code(https://sprite3d.com/openh264/openh264.json). It names, for each platform key from
//** Sprite3DNativeLibs, the library or libraries that may be downloaded:
//**
//** @longCode(#
//** {
//**   "win64": "libopenh264-2.6.0-win64.dll.bz2",
//**   "macarm": ["libopenh264-2.5.0-mac-arm64.dylib.bz2",
//**              "libopenh264-2.6.0-mac-arm64.dylib.bz2"],
//**   "linux64": { "url": "https://example.com/libopenh264-2.6.0-linux64.8.so.bz2",
//**                "version": "2.6.0" },
//**   "android32": ""
//** }
//** #)
//**
//** A platform's entry is one address, a list of them, or an object, or a list of objects,
//** with @code(url) @(or @code(file)@) and, if wanted, @code(version). An address that is not
//** a full @code(http) or @code(https) one is taken as relative to the list's own folder. A
//** missing or empty entry means the library is not available on that platform. Where there
//** are several, the highest version is used: the entry's @code(version), or else the first
//** run of numbers and dots in its file name, such as @code(2.6.0), compared number by number.
//** Entries that are not valid addresses are left out and reported.
//**
//** The library is downloaded into a folder of the caller's choosing, with a small
//** @code(installed.json) beside it recording the address it came from. Creating a
//** TSprite3DLibraryUpdate reads that file and nothing else, and uses no network:
//** CurrentLibrary is the copy downloaded before, if it is still there. Start then fetches the
//** list in the background. If its best entry is the address the copy came from, nothing more
//** is done; otherwise the new library is downloaded and, once checked, replaces the old copy,
//** which is deleted then or, if it is still in use, the next time.
//**
//** Downloads may be plain or compressed with bzip2 (@code(.bz2), as Cisco publishes OpenH264)
//** or gzip (@code(.gz)), told apart by their first bytes. The compressed file is streamed to
//** disk, then unpacked from there a block at a time into the library's file, so neither is
//** held whole in memory, and checked to be a library for the platform: a Windows DLL, a Mach-O
//** library or an ELF shared object. Any failure, the list or the library missing, a 404 or
//** other HTTP error, no network, a timeout, a list that is not JSON, a damaged download or
//** something that is not a library, is reported with the reason; the copy downloaded before,
//** if any, stays in use, and it is all tried again the next time the program starts.
//**
//** Create, Start, Cancel and Free on the main thread; Start's procedure is called on the main
//** thread too. Freeing the object cancels a download under way and waits for it to stop.
unit Sprite3DLibraryUpdate;

(*
  Keeps a downloaded native library, such as OpenH264, up to date from a
  list of downloads published on a web server.

  The list is a JSON file fetched at run time, such as
  https://sprite3d.com/openh264/openh264.json. It names, for each platform
  key from Sprite3DNativeLibs, the library or libraries that may be
  downloaded:

      {
        "win64": "libopenh264-2.6.0-win64.dll.bz2",
        "macarm": ["libopenh264-2.5.0-mac-arm64.dylib.bz2",
                   "libopenh264-2.6.0-mac-arm64.dylib.bz2"],
        "linux64": { "url": "https://example.com/libopenh264-2.6.0-linux64.8.so.bz2",
                     "version": "2.6.0" },
        "android32": ""
      }

  A platform's entry is one address, a list of them, or an object, or a
  list of objects, with url (or file) and, if wanted, version. An address
  that is not a full http or https one is taken as relative to the list's
  own folder. A missing or empty entry means the library is not available on
  that platform. Where there are several, the highest version is used: the
  entry's version, or else the first run of numbers and dots in its file
  name, such as 2.6.0, compared number by number. Entries that are not valid
  addresses are left out and reported.

  The library is downloaded into a folder of the caller's choosing, with a
  small installed.json beside it recording the address it came from.
  Creating a TSprite3DLibraryUpdate reads that file and nothing else, and
  uses no network: CurrentLibrary is the copy downloaded before, if it is
  still there. Start then fetches the list in the background. If its best
  entry is the address the copy came from, nothing more is done; otherwise
  the new library is downloaded and, once checked, replaces the old copy,
  which is deleted then or, if it is still in use, the next time.

  Downloads may be plain or compressed with bzip2 (.bz2, as Cisco publishes
  OpenH264) or gzip (.gz), told apart by their first bytes. The compressed
  file is streamed to disk, then unpacked from there a block at a time into
  the library's file, so neither is held whole in memory, and checked to be
  a library for the platform: a Windows DLL, a Mach-O library or an ELF
  shared object. Any failure, the list or the library missing, a 404 or
  other HTTP error, no network, a timeout, a list that is not JSON, a
  damaged download or something that is not a library, is reported with the
  reason; the copy downloaded before, if any, stays in use, and it is all
  tried again the next time the program starts.

  Create, Start, Cancel and Free on the main thread; Start's procedure is
  called on the main thread too. Freeing the object cancels a download under
  way and waits for it to stop.
*)

interface

uses
  System.SysUtils, System.Classes;

type
  //** @abstract(Reports the end of a check or download, on the main thread.)
  //**
  //** @param(ALibrary The new library's full path if one was downloaded; empty if the copy
  //** already there is the latest, or if none could be had.)
  //**
  //** @param(AMessage What happened, for a log: what was saved and where, that the copy is
  //** up to date, or why none is available.)
  TSprite3DLibraryUpdateDone = reference to procedure(const ALibrary, AMessage: String);

  //** @abstract(The library chosen from a list of downloads for one platform.)
  TSprite3DLibraryChoice = record
    //** @abstract(The full address to download; empty if the list has none for the platform.)
    Url: String;
    //** @abstract(Its version, as given or as read from its file name; empty if neither says.)
    Version: String;
    //** @abstract(The entries for the platform that were left out, and why.)
    Rejected: TArray<String>;
  end;

//** @abstract(Chooses, from a list of downloads, the latest library for a platform.)
//**
//** The list's format is given in the unit description. Relative addresses are resolved
//** against AListUrl's folder, and only @code(http) and @code(https) addresses with a host are
//** kept. Of those, the one with the highest version is chosen; entries without a version
//** rank below any with one, and among equals the first listed wins. Touches nothing but its
//** arguments, so it may be called on any thread.
//**
//** @param(AJson The list, as text.)
//**
//** @param(AListUrl The address the list was fetched from.)
//**
//** @param(APlatform The platform key to look up, such as @code('win64').)
//**
//** @returns(The choice; its Url is empty if the platform has no usable entry, with Rejected
//** saying why any entry was left out.)
//**
//** @raises(EJSONException Or another exception, if AJson is not JSON.)
//**
//** @raises(EArgumentException If AJson is JSON but not an object.)
function ChooseLibrary(const AJson, AListUrl, APlatform: String): TSprite3DLibraryChoice;

type
  //** @abstract(One library's download, for this platform; see the unit description.)
  TSprite3DLibraryUpdate = class
  private
    FName: String;
    FFolder: String;
    FListUrl: String;
    FInstalledUrl: String;
    FCurrent: String;
    FMessage: String;
    FThread: TThread;
    FOnDone: TSprite3DLibraryUpdateDone;
    procedure ReadInstalled;
    procedure Finished(const ALibrary, AMessage: String);
  public
    //** @abstract(Reads what has been downloaded before; uses no network.)
    //**
    //** @param(AListUrl The address of the JSON list of downloads, fetched by Start; empty
    //** means there is none, and Start does nothing.)
    //**
    //** @param(AName The library's name for messages, such as @code('OpenH264').)
    //**
    //** @param(AFolder Where downloads are kept; created when the first is saved. Every file
    //** in it other than the current library and @code(installed.json) may be deleted.)
    constructor Create(const AListUrl, AName, AFolder: String);
    //** @abstract(Cancels a download under way, waits for it to stop, and frees the object.)
    destructor Destroy; override;
    //** @abstract(Fetches the list in the background, and downloads the latest library for
    //** this platform if it is not the copy already there.)
    //**
    //** AOnDone is called once, on the main thread, when that ends, unless it is cancelled.
    //** Nothing happens, and AOnDone is not called, if there is no list address, or if this
    //** object has already started once.
    //**
    //** @param(AOnDone Called with the new library's path, or with an empty path and what
    //** happened.)
    //**
    //** @returns(True if the check was started.)
    function Start(const AOnDone: TSprite3DLibraryUpdateDone): Boolean;
    //** @abstract(Stops a check or download under way without calling its procedure, and
    //** waits for it.)
    procedure Cancel;
    //** @abstract(The address of the list of downloads.)
    property ListUrl: String read FListUrl;
    //** @abstract(The address CurrentLibrary was downloaded from; empty if there is none.)
    property InstalledUrl: String read FInstalledUrl;
    //** @abstract(The library downloaded before, or by Start, ready to load; empty if there
    //** is none yet.)
    property CurrentLibrary: String read FCurrent;
    //** @abstract(The state, for a log: which copy is there, or what the last check found.)
    property Message: String read FMessage;
  end;

implementation

uses
  System.IOUtils, System.JSON, System.ZLib, System.Math, System.Net.HttpClient,
  System.Net.URLClient, System.RegularExpressions, System.Generics.Collections,
  Sprite3DNativeLibs, Sprite3DBzip2, OSPaths, JsonText;

const
  INSTALLED_FILE = 'installed.json';
  PART_SUFFIX = '.part';
  DOWNLOAD_SUFFIX = '.download';
  CONNECT_TIMEOUT = 15000;      // milliseconds
  RESPONSE_TIMEOUT = 60000;
  // The most a list, a download and a library unpacked may be
  MAX_LIST = 1024 * 1024;
  MAX_DOWNLOAD = 64 * 1024 * 1024;
  MAX_LIBRARY = 128 * 1024 * 1024;

{ Choosing }

// The parts of a version, such as 2.6.0 as [2, 6, 0]; empty if none
function VersionParts(const AVersion: String): TArray<Integer>;
var
  Part: Integer;
begin
  Result := nil;
  for var Text in AVersion.Split(['.']) do
    if TryStrToInt(Text, Part) then
      Result := Result + [Part]
    else
      Exit(nil);
end;

// Below 0 if A is the lower version, above if the higher; a missing part
// counts as 0, and no version at all is below any
function CompareVersions(const A, B: TArray<Integer>): Integer;
begin
  if (Length(A) = 0) or (Length(B) = 0) then
    Exit(Ord(Length(A) > 0) - Ord(Length(B) > 0));
  for var I := 0 to Max(High(A), High(B)) do
  begin
    var X := 0;
    var Y := 0;
    if I <= High(A) then
      X := A[I];
    if I <= High(B) then
      Y := B[I];
    if X <> Y then
      Exit(Ord(X > Y) - Ord(X < Y));
  end;
  Result := 0;
end;

// The last part of an address's path, without a query
function FileOfUrl(const AUrl: String): String;
var
  I: Integer;
begin
  Result := AUrl;
  I := Result.IndexOfAny(['?', '#']);
  if I >= 0 then
    Result := Result.Substring(0, I);
  I := Result.LastIndexOf('/');
  if I >= 0 then
    Result := Result.Substring(I + 1);
end;

// The address an entry names, made full: as it is if it is http or https,
// from the list's host if it starts with /, and otherwise from the list's
// folder. Empty, with AProblem set, if it is not a usable address.
function ResolveUrl(const AEntry, AListUrl: String; out AProblem: String): String;
var
  Entry, Base: String;
  Uri: TURI;
  Slash: Integer;
begin
  Result := String.Empty;
  AProblem := String.Empty;
  Entry := AEntry.Trim;
  if Entry.Contains('://') then
    Result := Entry
  else if Entry.StartsWith('//') then
    Result := AListUrl.Substring(0, AListUrl.IndexOf(':') + 1) + Entry
  else if Entry.StartsWith('/') then
  begin
    // The list's scheme and host
    Slash := AListUrl.IndexOf('/', AListUrl.IndexOf('://') + 3);
    if Slash < 0 then
      Base := AListUrl
    else
      Base := AListUrl.Substring(0, Slash);
    Result := Base + Entry;
  end
  else
  begin
    Base := AListUrl;
    Slash := Base.IndexOfAny(['?', '#']);
    if Slash >= 0 then
      Base := Base.Substring(0, Slash);
    Base := Base.Substring(0, Base.LastIndexOf('/') + 1);
    if Entry.StartsWith('./') then
      Entry := Entry.Substring(2);
    Result := Base + Entry;
  end;
  try
    Uri := TURI.Create(Result);
    if not (SameText(Uri.Scheme, 'http') or SameText(Uri.Scheme, 'https')) then
      AProblem := AEntry + ' is not an http or https address'
    else if Uri.Host = String.Empty then
      AProblem := AEntry + ' has no host'
    else if FileOfUrl(Result) = String.Empty then
      AProblem := AEntry + ' names no file';
  except
    on E: Exception do
      AProblem := AEntry + ' is not a valid address: ' + E.Message;
  end;
  if AProblem <> String.Empty then
    Result := String.Empty;
end;

function ChooseLibrary(const AJson, AListUrl, APlatform: String): TSprite3DLibraryChoice;
var
  Root, Entry: TJSONValue;
  Best: TArray<Integer>;
  HaveBest: Boolean;

  // Weighs one candidate: AText an address, AVersion its version if given
  procedure Consider(const AText, AVersion: String);
  var
    Url, Problem, Version: String;
    Parts: TArray<Integer>;
    Found: TMatch;
  begin
    if AText.Trim = String.Empty then
      Exit;
    Url := ResolveUrl(AText, AListUrl, Problem);
    if Url = String.Empty then
    begin
      Result.Rejected := Result.Rejected + [Problem];
      Exit;
    end;
    Version := AVersion.Trim;
    if Version = String.Empty then
    begin
      // From the file name: the first run of numbers and dots with a dot in it
      Found := TRegEx.Match(FileOfUrl(Url), '\d+(\.\d+)+');
      if Found.Success then
        Version := Found.Value;
    end;
    Parts := VersionParts(Version);
    if not HaveBest or (CompareVersions(Parts, Best) > 0) then
    begin
      HaveBest := True;
      Best := Parts;
      Result.Url := Url;
      Result.Version := Version;
    end;
  end;

  // An object entry: url, or file, and perhaps version
  procedure ConsiderObject(const AObject: TJSONObject);
  var
    Text, Version: String;
  begin
    if not AObject.TryGetValue<String>('url', Text) and
      not AObject.TryGetValue<String>('file', Text) then
    begin
      Result.Rejected := Result.Rejected + [AObject.ToJSON + ' gives no url or file'];
      Exit;
    end;
    if not AObject.TryGetValue<String>('version', Version) then
      Version := String.Empty;
    Consider(Text, Version);
  end;

  procedure ConsiderValue(const AValue: TJSONValue);
  begin
    if AValue is TJSONString then
      Consider(TJSONString(AValue).Value, String.Empty)
    else if AValue is TJSONObject then
      ConsiderObject(TJSONObject(AValue))
    else if (AValue <> nil) and not (AValue is TJSONNull) then
      Result.Rejected := Result.Rejected + [AValue.ToJSON + ' is not an address'];
  end;

begin
  Result.Url := String.Empty;
  Result.Version := String.Empty;
  Result.Rejected := nil;
  HaveBest := False;
  Best := nil;
  // A byte-order mark, as some editors add, is not JSON
  Root := TJSONObject.ParseJSONValue(AJson.TrimLeft([#$FEFF]), False, True);
  try
    if not (Root is TJSONObject) then
      raise EArgumentException.Create('the list is not a JSON object');
    Entry := TJSONObject(Root).Values[APlatform];
    if Entry is TJSONArray then
      for var Item in TJSONArray(Entry) do
        ConsiderValue(Item)
    else
      ConsiderValue(Entry);
  finally
    Root.Free;
  end;
end;

{ Files }

// The file name the library is saved under: the last part of the address,
// without a query or a compression extension, made safe for every platform
function FileNameFromUrl(const AUrl: String): String;
const
  BAD = '/\:*?"<>|';
var
  Path: String;
  I: Integer;
begin
  Path := FileOfUrl(AUrl);
  if Path.EndsWith('.bz2', True) or Path.EndsWith('.gz', True) then
    Path := Path.Substring(0, Path.LastIndexOf('.'));
  for I := 1 to Length(Path) do
    if (Path[I] < ' ') or (Pos(Path[I], BAD) > 0) or (Path[I] = '%') then
      Path[I] := '_';
  Path := Path.Trim([' ', '.']);
  if Path = String.Empty then
    Path := 'library';
  Result := Path;
end;

// Whether the bytes are the start of a shared library this platform can
// load
function IsNativeLibrary(const AData: TBytes): Boolean;
begin
  Result := Length(AData) >= 4;
  if not Result then
    Exit;
  {$IF DEFINED(MSWINDOWS)}
  Result := (AData[0] = Ord('M')) and (AData[1] = Ord('Z'));
  {$ELSEIF DEFINED(MACOS)}
  // Mach-O, 64-bit either byte order, or a universal ("fat") file
  Result := ((AData[0] = $CF) and (AData[1] = $FA) and (AData[2] = $ED) and (AData[3] = $FE)) or
    ((AData[0] = $FE) and (AData[1] = $ED) and (AData[2] = $FA) and (AData[3] = $CF)) or
    ((AData[0] = $CA) and (AData[1] = $FE) and (AData[2] = $BA) and (AData[3] = $BE));
  {$ELSE}
  Result := (AData[0] = $7F) and (AData[1] = Ord('E')) and (AData[2] = Ord('L')) and
    (AData[3] = Ord('F'));
  {$IFEND}
end;

// The first ACount bytes of a file, or fewer if it is shorter
function FileStart(const AFileName: String; const ACount: Integer): TBytes;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, Min(Int64(ACount), Stream.Size));
    if Length(Result) > 0 then
      Stream.ReadBuffer(Result[0], Length(Result));
  finally
    Stream.Free;
  end;
end;

// Unpacks a gzip stream into another, a piece at a time, no more than
// MAX_LIBRARY bytes
procedure GunzipStream(const ASource, ATarget: TStream);
var
  Unzip: TZDecompressionStream;
  Buffer: TBytes;
  Count: Integer;
  Total: Int64;
begin
  // 15 + 16: a gzip header rather than a zlib one
  Unzip := TZDecompressionStream.Create(ASource, 15 + 16);
  try
    SetLength(Buffer, 65536);
    Total := 0;
    repeat
      Count := Unzip.Read(Buffer[0], Length(Buffer));
      if Count > 0 then
      begin
        Inc(Total, Count);
        if Total > MAX_LIBRARY then
          raise EStreamError.Create('it unpacks to more than any library would');
        ATarget.WriteBuffer(Buffer[0], Count);
      end;
    until Count <= 0;
  finally
    Unzip.Free;
  end;
end;

// Deletes every file in AFolder but AKeep and installed.json; files still
// in use stay until the next time
procedure DeleteStale(const AFolder, AKeep: String);
var
  FileName: String;
begin
  if not TDirectory.Exists(AFolder) then
    Exit;
  for FileName in TDirectory.GetFiles(AFolder) do
  begin
    if SameFileName(ExtractFileName(FileName), INSTALLED_FILE) or
      ((AKeep <> String.Empty) and SameFileName(FileName, AKeep)) then
      Continue;
    try
      TFile.Delete(FileName);
    except
      // In use, as a loaded library is on Windows; gone next time
    end;
  end;
end;

// Deletes a file if it is there, quietly
procedure DeleteQuietly(const AFileName: String);
begin
  try
    if TFile.Exists(AFileName) then
      TFile.Delete(AFileName);
  except
    // nothing more to do
  end;
end;

type
  // The check and the download, on a thread of their own
  TDownloadThread = class(TThread)
  private
    FOwner: TSprite3DLibraryUpdate;
    FName: String;
    FListUrl: String;
    FInstalledUrl: String;
    FCurrent: String;
    FFolder: String;
    FLibrary: String;
    FMessage: String;
    // Anything wrong in the list that did not stop the check
    FNote: String;
    FTooLarge: Boolean;
    FLimit: Int64;
    procedure ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64;
      var AAbort: Boolean);
    function Fetch(const AUrl: String; const ATarget: TStream; const ALimit: Int64;
      out AError: String): Boolean;
    procedure Run;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOwner: TSprite3DLibraryUpdate);
  end;

{ TDownloadThread }

constructor TDownloadThread.Create(const AOwner: TSprite3DLibraryUpdate);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FName := AOwner.FName;
  FListUrl := AOwner.FListUrl;
  FInstalledUrl := AOwner.FInstalledUrl;
  FCurrent := AOwner.FCurrent;
  FFolder := AOwner.FFolder;
end;

procedure TDownloadThread.ReceiveData(const Sender: TObject; AContentLength,
  AReadCount: Int64; var AAbort: Boolean);
begin
  if AReadCount > FLimit then
    FTooLarge := True;
  AAbort := Terminated or FTooLarge;
end;

// Downloads AUrl into ATarget, no more than ALimit bytes; False, with
// AError saying why, if it could not be had
function TDownloadThread.Fetch(const AUrl: String; const ATarget: TStream;
  const ALimit: Int64; out AError: String): Boolean;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
begin
  Result := False;
  AError := String.Empty;
  FTooLarge := False;
  FLimit := ALimit;
  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := CONNECT_TIMEOUT;
    Client.ResponseTimeout := RESPONSE_TIMEOUT;
    Client.HandleRedirects := True;
    Client.OnReceiveData := ReceiveData;
    try
      // Written into ATarget as it arrives
      Response := Client.Get(AUrl, ATarget);
    except
      on E: Exception do
      begin
        if Terminated then
          AError := 'cancelled'
        else if FTooLarge then
          AError := 'is larger than it should be at ' + AUrl
        else
          AError := 'could not be downloaded from ' + AUrl + ': ' + E.Message;
        Exit;
      end;
    end;
  finally
    Client.Free;
  end;
  if Terminated then
    AError := 'cancelled'
  else if FTooLarge or (ATarget.Size > ALimit) then
    AError := 'is larger than it should be at ' + AUrl
  else if Response.StatusCode = 404 then
    AError := 'was not found at ' + AUrl + ' (404)'
  else if Response.StatusCode <> 200 then
    AError := Format('could not be downloaded from %s: the server answered %d %s',
      [AUrl, Response.StatusCode, Response.StatusText])
  else
    Result := True;
end;

procedure TDownloadThread.Run;
var
  List: TBytesStream;
  Choice: TSprite3DLibraryChoice;
  Error, Target, Part, Download: String;
  Source, Output: TFileStream;
  Head: TBytes;
  Installed: TJSONObject;
begin
  // The list
  List := TBytesStream.Create;
  try
    if not Fetch(FListUrl, List, MAX_LIST, Error) then
    begin
      FMessage := Format('%s''s list of downloads %s', [FName, Error]);
      Exit;
    end;
    try
      Choice := ChooseLibrary(TEncoding.UTF8.GetString(List.Bytes, 0, List.Size), FListUrl,
        NativePlatformKey);
    except
      on E: Exception do
      begin
        FMessage := Format('%s''s list of downloads at %s is not valid JSON of the kind ' +
          'expected: %s', [FName, FListUrl, E.Message]);
        Exit;
      end;
    end;
  finally
    List.Free;
  end;
  if Choice.Url = String.Empty then
  begin
    FMessage := Format('%s''s list at %s has no usable download for %s',
      [FName, FListUrl, NativePlatformKey]);
    if Length(Choice.Rejected) > 0 then
      FMessage := FMessage + ': ' + String.Join('; ', Choice.Rejected);
    Exit;
  end;
  // Entries left out are worth knowing about even when another is used
  if Length(Choice.Rejected) > 0 then
    FNote := Format(' (%s entries left out of the list: %s)', [NativePlatformKey,
      String.Join('; ', Choice.Rejected)]);
  // Up to date: the latest is what is there already
  if (Choice.Url = FInstalledUrl) and (FCurrent <> String.Empty) and TFile.Exists(FCurrent) then
  begin
    FMessage := Format('%s %s is up to date: %s', [FName, Choice.Version,
      FCurrent]).Replace('  ', ' ');
    Exit;
  end;

  // The library: the download streamed to disk, then unpacked from there,
  // under temporary names, so a half-written file is never taken for it
  Target := TPath.Combine(FFolder, FileNameFromUrl(Choice.Url));
  Part := Target + PART_SUFFIX;
  Download := Target + DOWNLOAD_SUFFIX;
  try
    ForceDirectories(FFolder);
    Source := TFileStream.Create(Download, fmCreate);
    try
      if not Fetch(Choice.Url, Source, MAX_DOWNLOAD, Error) then
      begin
        FMessage := Format('%s %s', [FName, Error]);
        Exit;
      end;
    finally
      Source.Free;
    end;
    if Terminated then
      Exit;
    Head := FileStart(Download, 4);
    Source := TFileStream.Create(Download, fmOpenRead or fmShareDenyWrite);
    try
      Output := TFileStream.Create(Part, fmCreate);
      try
        try
          if IsBzip2(Head) then
            Bzip2DecompressStream(Source, Output, MAX_LIBRARY)
          else if (Length(Head) >= 2) and (Head[0] = $1F) and (Head[1] = $8B) then
            GunzipStream(Source, Output)
          else
            Output.CopyFrom(Source, 0);
        except
          on E: Exception do
          begin
            FMessage := Format('%s from %s could not be unpacked: %s',
              [FName, Choice.Url, E.Message]);
            Exit;
          end;
        end;
      finally
        Output.Free;
      end;
    finally
      Source.Free;
    end;
    DeleteQuietly(Download);
    if not IsNativeLibrary(FileStart(Part, 4)) then
    begin
      FMessage := Format('%s from %s is not a library for this platform',
        [FName, Choice.Url]);
      Exit;
    end;
    if TFile.Exists(Target) then
      TFile.Delete(Target);
    TFile.Move(Part, Target);
    Installed := TJSONObject.Create;
    try
      Installed.AddPair('url', Choice.Url);
      Installed.AddPair('file', ExtractFileName(Target));
      Installed.AddPair('version', Choice.Version);
      Installed.AddPair('list', FListUrl);
      // UTF-8 without a byte-order mark
      TFile.WriteAllBytes(TPath.Combine(FFolder, INSTALLED_FILE), JsonToBytes(Installed));
    finally
      Installed.Free;
    end;
  except
    on E: Exception do
    begin
      FMessage := Format('%s could not be saved in %s: %s', [FName, FFolder, E.Message]);
      Exit;
    end;
  end;
  FLibrary := Target;
  FMessage := Format('%s %s downloaded from %s to %s', [FName, Choice.Version, Choice.Url,
    Target]).Replace('  ', ' ');
  DeleteStale(FFolder, Target);
end;

procedure TDownloadThread.Execute;
var
  Me: TDownloadThread;
begin
  // Nothing raised here reaches the program: every failure is a message
  try
    Run;
  except
    on E: Exception do
      FMessage := FName + ': ' + E.Message;
  end;
  FMessage := FMessage + FNote;
  // Whatever is left over from a failed or cancelled download
  if FLibrary = String.Empty then
    for var Leftover in [PART_SUFFIX, DOWNLOAD_SUFFIX] do
      if TDirectory.Exists(FFolder) then
        for var FileName in TDirectory.GetFiles(FFolder, '*' + Leftover) do
          DeleteQuietly(FileName);
  if Terminated then
    Exit;   // cancelled: the owner is not told
  Me := Self;
  // Queued against this thread, so the owner can remove it if it goes first
  TThread.Queue(Self,
    procedure
    begin
      Me.FOwner.Finished(Me.FLibrary, Me.FMessage);
    end);
end;

{ TSprite3DLibraryUpdate }

constructor TSprite3DLibraryUpdate.Create(const AListUrl, AName, AFolder: String);
begin
  inherited Create;
  FName := AName;
  FFolder := OSFriendlyPath(AFolder);
  FListUrl := AListUrl.Trim;
  ReadInstalled;
end;

destructor TSprite3DLibraryUpdate.Destroy;
begin
  Cancel;
  inherited;
end;

procedure TSprite3DLibraryUpdate.ReadInstalled;
var
  Root: TJSONValue;
  Url, FileName, Version, Path: String;
begin
  FCurrent := String.Empty;
  FInstalledUrl := String.Empty;
  FMessage := Format('No %s has been downloaded yet', [FName]);
  Path := TPath.Combine(FFolder, INSTALLED_FILE);
  if not TFile.Exists(Path) then
    Exit;
  try
    Root := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(Path, TEncoding.UTF8).TrimLeft([#$FEFF]));
    try
      if not (Root is TJSONObject) or
        not TJSONObject(Root).TryGetValue<String>('url', Url) or
        not TJSONObject(Root).TryGetValue<String>('file', FileName) then
        Exit;
      if not TJSONObject(Root).TryGetValue<String>('version', Version) then
        Version := String.Empty;
    finally
      Root.Free;
    end;
  except
    Exit;   // unreadable: download again
  end;
  Path := TPath.Combine(FFolder, ExtractFileName(FileName));
  if not TFile.Exists(Path) then
    Exit;
  FCurrent := Path;
  FInstalledUrl := Url;
  FMessage := Format('%s %s is installed: %s', [FName, Version, Path]).Replace('  ', ' ');
  DeleteStale(FFolder, Path);
end;

function TSprite3DLibraryUpdate.Start(const AOnDone: TSprite3DLibraryUpdateDone): Boolean;
begin
  // One check per object
  Result := (FListUrl <> String.Empty) and (FThread = nil);
  if not Result then
    Exit;
  FOnDone := AOnDone;
  FThread := TDownloadThread.Create(Self);
  FThread.Start;
end;

procedure TSprite3DLibraryUpdate.Cancel;
begin
  if FThread = nil then
    Exit;
  FThread.Terminate;
  FThread.WaitFor;
  // A report it queued before stopping must not run after this
  TThread.RemoveQueuedEvents(FThread);
  FreeAndNil(FThread);
  FOnDone := nil;
end;

procedure TSprite3DLibraryUpdate.Finished(const ALibrary, AMessage: String);
var
  OnDone: TSprite3DLibraryUpdateDone;
begin
  // The thread object is freed by Cancel, when this object is freed
  OnDone := FOnDone;
  FOnDone := nil;
  if ALibrary <> String.Empty then
  begin
    FCurrent := ALibrary;
    FInstalledUrl := String.Empty;   // the new copy's, kept in installed.json
  end;
  FMessage := AMessage;
  if Assigned(OnDone) then
    OnDone(ALibrary, AMessage);
end;

end.
