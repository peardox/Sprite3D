//** @abstract(Keeps a downloaded native library, such as OpenH264, up to date from an address
//** given for each platform.)
//**
//** A JSON file names, for each platform key from Sprite3DNativeLibs, the address of the
//** library to use:
//**
//** @longCode(#
//** {
//**   "win64": "https://example.com/openh264-2.6.0-win64.dll.bz2",
//**   "macarm": "",
//**   ...
//** }
//** #)
//**
//** An empty or missing address means the library is not available on that platform. The
//** library is downloaded into a folder of the caller's choosing, with a small
//** @code(installed.json) beside it recording the address it came from. Creating a
//** TSprite3DLibraryUpdate reads both files and nothing else: if the copy recorded was
//** downloaded from the address now given, CurrentLibrary is its path straight away and no
//** network is used. If the address has changed, as when 2.6.0 is replaced by 2.6.1, or the
//** copy is missing, Start downloads the new one in the background, and once it has been
//** checked it replaces the old copy, which is deleted then or, if it is still in use, the
//** next time.
//**
//** Downloads may be plain or compressed with bzip2 (@code(.bz2), as Cisco publishes
//** OpenH264) or gzip (@code(.gz)); the file is unpacked and checked to be a library for the
//** platform: a Windows DLL, a Mach-O library or an ELF shared object. Any failure, a 404 or
//** other HTTP error, no network, a timeout, a damaged download or something that is not a
//** library, is reported as "not available" with the reason, and is tried again the next time
//** the program starts.
//**
//** Create, Start, Cancel and Free on the main thread; Start's procedure is called on the main
//** thread too. Freeing the object cancels a download under way and waits for it to stop.
unit Sprite3DLibraryUpdate;

{
  Keeps a downloaded native library, such as OpenH264, up to date from an
  address given for each platform.

  A JSON file names, for each platform key from Sprite3DNativeLibs, the
  address of the library to use, as one JSON object with members such as:

      "win64": "https://example.com/openh264-2.6.0-win64.dll.bz2",
      "macarm": "",

  An empty or missing address means the library is not available on that
  platform. The library is downloaded into a folder of the caller's
  choosing, with a small installed.json beside it recording the address it
  came from. Creating a TSprite3DLibraryUpdate reads both files and nothing
  else: if the copy recorded was downloaded from the address now given,
  CurrentLibrary is its path straight away and no network is used. If the
  address has changed, as when 2.6.0 is replaced by 2.6.1, or the copy is
  missing, Start downloads the new one in the background, and once it has
  been checked it replaces the old copy, which is deleted then or, if it is
  still in use, the next time.

  Downloads may be plain or compressed with bzip2 (.bz2, as Cisco publishes
  OpenH264) or gzip (.gz); the file is unpacked and checked to be a library
  for the platform: a Windows DLL, a Mach-O library or an ELF shared object.
  Any failure, a 404 or other HTTP error, no network, a timeout, a damaged
  download or something that is not a library, is reported as "not
  available" with the reason, and is tried again the next time the program
  starts.

  Create, Start, Cancel and Free on the main thread; Start's procedure is
  called on the main thread too. Freeing the object cancels a download under
  way and waits for it to stop.
}

interface

uses
  System.SysUtils, System.Classes;

type
  //** @abstract(Reports the end of a download, on the main thread.)
  //**
  //** @param(ALibrary The library's full path if it is now available; empty if not.)
  //**
  //** @param(AMessage What happened, for a log: where it was saved, or why it is not
  //** available.)
  /// <summary>Reports the end of a download, on the main thread.</summary>
  /// <param name="ALibrary">The library's full path if it is now available; empty if
  /// not.</param>
  /// <param name="AMessage">What happened, for a log: where it was saved, or why it is not
  /// available.</param>
  TSprite3DLibraryUpdateDone = reference to procedure(const ALibrary, AMessage: String);

  //** @abstract(One library's download, for this platform; see the unit description.)
  /// <summary>One library's download, for this platform; see the unit description.</summary>
  TSprite3DLibraryUpdate = class
  private
    FName: String;
    FFolder: String;
    FUrl: String;
    FCurrent: String;
    FMessage: String;
    FThread: TThread;
    FFinished: Boolean;
    FOnDone: TSprite3DLibraryUpdateDone;
    procedure ReadConfig(const AConfigFile: String);
    procedure ReadInstalled;
    procedure Finished(const ALibrary, AMessage: String);
  public
    //** @abstract(Reads the configuration and what has been downloaded; uses no network.)
    //**
    //** @param(AConfigFile The JSON file of addresses; a missing or unreadable file means no
    //** address.)
    //**
    //** @param(AName The library's name for messages, such as @code('OpenH264').)
    //**
    //** @param(AFolder Where downloads are kept; created when the first is saved. Every file
    //** in it other than the current library and @code(installed.json) may be deleted.)
    /// <summary>Reads the configuration and what has been downloaded; uses no
    /// network.</summary>
    /// <param name="AConfigFile">The JSON file of addresses; a missing or unreadable file
    /// means no address.</param>
    /// <param name="AName">The library's name for messages, such as
    /// <c>'OpenH264'</c>.</param>
    /// <param name="AFolder">Where downloads are kept; created when the first is saved. Every
    /// file in it other than the current library and <c>installed.json</c> may be
    /// deleted.</param>
    constructor Create(const AConfigFile, AName, AFolder: String);
    //** @abstract(Cancels a download under way, waits for it to stop, and frees the object.)
    /// <summary>Cancels a download under way, waits for it to stop, and frees the
    /// object.</summary>
    destructor Destroy; override;
    //** @abstract(Downloads the library in the background if it is configured and not
    //** already current.)
    //**
    //** AOnDone is called once, on the main thread, when the download ends, unless it is
    //** cancelled. Nothing happens, and AOnDone is not called, if there is no address, the
    //** current copy is up to date, or a download has already been started by this object.
    //**
    //** @param(AOnDone Called with the new library's path, or an empty path and the reason.)
    //**
    //** @returns(True if a download was started.)
    /// <summary>Downloads the library in the background if it is configured and not already
    /// current.</summary>
    /// <remarks>AOnDone is called once, on the main thread, when the download ends, unless it
    /// is cancelled. Nothing happens, and AOnDone is not called, if there is no address, the
    /// current copy is up to date, or a download has already been started by this
    /// object.</remarks>
    /// <param name="AOnDone">Called with the new library's path, or an empty path and the
    /// reason.</param>
    /// <returns>True if a download was started.</returns>
    function Start(const AOnDone: TSprite3DLibraryUpdateDone): Boolean;
    //** @abstract(Stops a download under way without calling its procedure, and waits for it.)
    /// <summary>Stops a download under way without calling its procedure, and waits for
    /// it.</summary>
    procedure Cancel;
    //** @abstract(The address given for this platform; empty if the library is not
    //** available here.)
    /// <summary>The address given for this platform; empty if the library is not available
    /// here.</summary>
    property Url: String read FUrl;
    //** @abstract(The library downloaded from Url, ready to load; empty if there is none yet.)
    /// <summary>The library downloaded from Url, ready to load; empty if there is none
    /// yet.</summary>
    property CurrentLibrary: String read FCurrent;
    //** @abstract(The state, for a log: up to date, needs downloading, or not available.)
    /// <summary>The state, for a log: up to date, needs downloading, or not
    /// available.</summary>
    property Message: String read FMessage;
  end;

implementation

uses
  System.IOUtils, System.JSON, System.ZLib, System.Math, System.Net.HttpClient,
  System.Net.URLClient, Sprite3DNativeLibs, Sprite3DBzip2, OSPaths;

const
  INSTALLED_FILE = 'installed.json';
  PART_SUFFIX = '.part';
  CONNECT_TIMEOUT = 15000;      // milliseconds
  RESPONSE_TIMEOUT = 60000;
  MAX_DOWNLOAD = 64 * 1024 * 1024;

type
  // The download itself, on a thread of its own
  TDownloadThread = class(TThread)
  private
    FOwner: TSprite3DLibraryUpdate;
    FUrl: String;
    FFolder: String;
    FLibrary: String;
    FError: String;
    FTooLarge: Boolean;
    procedure ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64;
      var AAbort: Boolean);
    procedure Run;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOwner: TSprite3DLibraryUpdate);
  end;

// The file name the library is saved under: the last part of the address,
// without a query or a compression extension, made safe for every platform
function FileNameFromUrl(const AUrl: String): String;
const
  BAD = '/\:*?"<>|';
var
  Path: String;
  I: Integer;
begin
  Path := AUrl;
  I := Path.IndexOfAny(['?', '#']);
  if I >= 0 then
    Path := Path.Substring(0, I);
  I := Path.LastIndexOf('/');
  if I >= 0 then
    Path := Path.Substring(I + 1);
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

// Whether the bytes are a shared library this platform can load
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

function Gunzip(const AData: TBytes): TBytes;
var
  Source: TBytesStream;
  Unzip: TZDecompressionStream;
  Target: TBytesStream;
  Buffer: TBytes;
  Count: Integer;
begin
  Source := TBytesStream.Create(AData);
  try
    // 15 + 16: a gzip header rather than a zlib one
    Unzip := TZDecompressionStream.Create(Source, 15 + 16);
    try
      Target := TBytesStream.Create;
      try
        // Read to the end: a decompression stream has no size to copy by
        SetLength(Buffer, 65536);
        repeat
          Count := Unzip.Read(Buffer[0], Length(Buffer));
          if Count > 0 then
            Target.WriteBuffer(Buffer[0], Count);
          if Target.Size > MAX_DOWNLOAD then
            raise EStreamError.Create('it unpacks to more than any library would');
        until Count <= 0;
        Result := Copy(Target.Bytes, 0, Target.Size);
      finally
        Target.Free;
      end;
    finally
      Unzip.Free;
    end;
  finally
    Source.Free;
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

{ TDownloadThread }

constructor TDownloadThread.Create(const AOwner: TSprite3DLibraryUpdate);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FUrl := AOwner.FUrl;
  FFolder := AOwner.FFolder;
end;

procedure TDownloadThread.ReceiveData(const Sender: TObject; AContentLength,
  AReadCount: Int64; var AAbort: Boolean);
begin
  if AReadCount > MAX_DOWNLOAD then
    FTooLarge := True;
  AAbort := Terminated or FTooLarge;
end;

procedure TDownloadThread.Run;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  Body: TBytesStream;
  Data: TBytes;
  Target, Part: String;
  Installed: TJSONObject;
begin
  Client := THTTPClient.Create;
  Body := TBytesStream.Create;
  try
    Client.ConnectionTimeout := CONNECT_TIMEOUT;
    Client.ResponseTimeout := RESPONSE_TIMEOUT;
    Client.HandleRedirects := True;
    Client.OnReceiveData := ReceiveData;
    try
      Response := Client.Get(FUrl, Body);
    except
      on E: Exception do
      begin
        if Terminated then
          FError := 'cancelled'
        else
          FError := 'could not be downloaded: ' + E.Message;
        Exit;
      end;
    end;
    if Terminated then
    begin
      FError := 'cancelled';
      Exit;
    end;
    if Response.StatusCode <> 200 then
    begin
      if Response.StatusCode = 404 then
        FError := 'was not found at ' + FUrl + ' (404)'
      else
        FError := Format('could not be downloaded: the server answered %d %s',
          [Response.StatusCode, Response.StatusText]);
      Exit;
    end;
    if FTooLarge or (Body.Size > MAX_DOWNLOAD) then
    begin
      FError := 'is too large to be the library';
      Exit;
    end;
    Data := Copy(Body.Bytes, 0, Body.Size);
  finally
    Body.Free;
    Client.Free;
  end;

  // Unpack, then check it is a library for this platform
  try
    if IsBzip2(Data) then
      Data := Bzip2Decompress(Data)
    else if (Length(Data) >= 2) and (Data[0] = $1F) and (Data[1] = $8B) then
      Data := Gunzip(Data);
  except
    on E: Exception do
    begin
      FError := 'could not be unpacked: ' + E.Message;
      Exit;
    end;
  end;
  if not IsNativeLibrary(Data) then
  begin
    FError := 'is not a library for this platform';
    Exit;
  end;

  // Saved under a temporary name first, so a half-written file is never
  // taken for the library
  Target := TPath.Combine(FFolder, FileNameFromUrl(FUrl));
  Part := Target + PART_SUFFIX;
  try
    ForceDirectories(FFolder);
    TFile.WriteAllBytes(Part, Data);
    if TFile.Exists(Target) then
      TFile.Delete(Target);
    TFile.Move(Part, Target);
    Installed := TJSONObject.Create;
    try
      Installed.AddPair('url', FUrl);
      Installed.AddPair('file', ExtractFileName(Target));
      // UTF-8 without a byte-order mark
      TFile.WriteAllBytes(TPath.Combine(FFolder, INSTALLED_FILE),
        TEncoding.UTF8.GetBytes(Installed.ToJSON));
    finally
      Installed.Free;
    end;
  except
    on E: Exception do
    begin
      FError := 'could not be saved in ' + FFolder + ': ' + E.Message;
      try
        if TFile.Exists(Part) then
          TFile.Delete(Part);
      except
        // nothing more to do
      end;
      Exit;
    end;
  end;
  FLibrary := Target;
  DeleteStale(FFolder, Target);
end;

procedure TDownloadThread.Execute;
var
  Me: TDownloadThread;
begin
  try
    Run;
  except
    on E: Exception do
      FError := E.Message;
  end;
  if Terminated then
    Exit;   // cancelled: the owner is not told
  Me := Self;
  // Queued against this thread, so the owner can remove it if it goes first
  Queue(
    procedure
    begin
      Me.FOwner.Finished(Me.FLibrary, Me.FError);
    end);
end;

{ TSprite3DLibraryUpdate }

constructor TSprite3DLibraryUpdate.Create(const AConfigFile, AName, AFolder: String);
begin
  inherited Create;
  FName := AName;
  FFolder := OSFriendlyPath(AFolder);
  ReadConfig(OSFriendlyPath(AConfigFile));
  ReadInstalled;
end;

destructor TSprite3DLibraryUpdate.Destroy;
begin
  Cancel;
  inherited;
end;

procedure TSprite3DLibraryUpdate.ReadConfig(const AConfigFile: String);
var
  Root: TJSONValue;
  Value: String;
begin
  FUrl := String.Empty;
  if (AConfigFile = String.Empty) or not TFile.Exists(AConfigFile) then
    Exit;
  try
    // A byte-order mark, as some editors add, is not JSON
    Root := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(AConfigFile, TEncoding.UTF8).TrimLeft([#$FEFF]));
    try
      if (Root is TJSONObject) and
        TJSONObject(Root).TryGetValue<String>(NativePlatformKey, Value) then
        FUrl := Value.Trim;
    finally
      Root.Free;
    end;
  except
    FUrl := String.Empty;   // unreadable: as if there were no address
  end;
end;

procedure TSprite3DLibraryUpdate.ReadInstalled;
var
  Root: TJSONValue;
  Url, FileName, Path: String;
begin
  FCurrent := String.Empty;
  if FUrl = String.Empty then
  begin
    FMessage := Format('No %s address is given for %s, so it is not available',
      [FName, NativePlatformKey]);
    Exit;
  end;
  FMessage := Format('%s needs downloading from %s', [FName, FUrl]);
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
    finally
      Root.Free;
    end;
  except
    Exit;   // unreadable: download again
  end;
  // Only a copy of exactly the library now asked for will do
  Path := TPath.Combine(FFolder, ExtractFileName(FileName));
  if (Url = FUrl) and TFile.Exists(Path) then
  begin
    FCurrent := Path;
    FMessage := Format('%s is up to date: %s', [FName, Path]);
    DeleteStale(FFolder, Path);
  end
  else if Url <> FUrl then
    FMessage := Format('%s needs updating from %s', [FName, FUrl]);
end;

function TSprite3DLibraryUpdate.Start(const AOnDone: TSprite3DLibraryUpdateDone): Boolean;
begin
  // One download per object
  Result := (FUrl <> String.Empty) and (FCurrent = String.Empty) and (FThread = nil);
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
  Text: String;
begin
  // The thread object is freed by Cancel, when this object is freed
  FFinished := True;
  OnDone := FOnDone;
  FOnDone := nil;
  if ALibrary <> String.Empty then
  begin
    FCurrent := ALibrary;
    Text := Format('%s downloaded to %s', [FName, ALibrary]);
  end
  else
    Text := Format('%s %s, so it is not available', [FName, AMessage]);
  FMessage := Text;
  if Assigned(OnDone) then
    OnDone(ALibrary, Text);
end;

end.
