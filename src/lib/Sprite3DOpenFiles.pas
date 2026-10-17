//** @abstract(Collects the files the operating system asks the application to open.)
//**
//** When the user opens a document with an application, for example by double-clicking a
//** file associated with it, each platform tells the application differently. This unit
//** gathers them into one place, FileOpenRequests, so the application handles them the same
//** way everywhere.
//**
//** Requests that arrive before the application is ready wait in a queue; TakePending
//** returns them, and from then on each new request is passed straight to OnOpenFile, if it
//** is set. All requests are reported on the main thread, as full paths of local files.
//**
//** The unit knows nothing of any particular file type; filtering is the caller's job.
//** Registering the file types with the operating system is also the caller's: a file
//** association on Windows, a @code(.desktop) file on Linux, document types in Info.plist on
//** macOS and iOS, and an intent filter in AndroidManifest.xml on Android.
//**
//** @preformatted(
//** Windows   command line: Explorer starts the program with the file's full path
//** Linux     command line: Exec=... %f in the .desktop file
//** macOS     the "open documents" Apple event from Finder or the Dock, at launch and later;
//**           also the command line, when started with a file name
//** iOS       the open-URL application event, at launch and later
//** Android   the VIEW intent that started the activity, and any later one; content:// files
//**           are copied into the application's cache folder first
//** )
unit Sprite3DOpenFiles;

{
  Collects the files the operating system asks the application to open.

  When the user opens a document with an application, for example by
  double-clicking a file associated with it, each platform tells the
  application differently. This unit gathers them into one place,
  FileOpenRequests, so the application handles them the same way
  everywhere.

  Requests that arrive before the application is ready wait in a queue;
  TakePending returns them, and from then on each new request is passed
  straight to OnOpenFile, if it is set. All requests are reported on the
  main thread, as full paths of local files.

  The unit knows nothing of any particular file type; filtering is the
  caller's job. Registering the file types with the operating system is
  also the caller's: a file association on Windows, a .desktop file on
  Linux, document types in Info.plist on macOS and iOS, and an intent
  filter in AndroidManifest.xml on Android.

    Windows   command line: Explorer starts the program with the file's full path
    Linux     command line: Exec=... %f in the .desktop file
    macOS     the "open documents" Apple event from Finder or the Dock, at launch and later;
              also the command line, when started with a file name
    iOS       the open-URL application event, at launch and later
    Android   the VIEW intent that started the activity, and any later one; content:// files
              are copied into the application's cache folder first
}

interface

uses
  System.SysUtils, System.Classes, System.Messaging;

type
  //** @abstract(Receives a file the operating system asks the application to open.)
  //**
  //** @param(AFileName The file's full path; it existed when the request arrived.)
  /// <summary>Receives a file the operating system asks the application to open.</summary>
  /// <param name="AFileName">The file's full path; it existed when the request
  /// arrived.</param>
  TSprite3DOpenFileEvent = procedure(const AFileName: String) of object;

  //** @abstract(The queue of files the operating system has asked the application to open.)
  //**
  //** There is one, created when the unit is initialised and reached through
  //** FileOpenRequests; do not create or free it. Call TakePending once the application can
  //** open files, normally when the main form is shown, then set OnOpenFile for the requests
  //** that come later. For the main thread only.
  /// <summary>The queue of files the operating system has asked the application to
  /// open.</summary>
  /// <remarks>There is one, created when the unit is initialised and reached through
  /// FileOpenRequests; do not create or free it. Call TakePending once the application can
  /// open files, normally when the main form is shown, then set OnOpenFile for the requests
  /// that come later. For the main thread only.</remarks>
  TSprite3DFileOpenRequests = class
  private
    FPending: TArray<String>;
    FOnOpenFile: TSprite3DOpenFileEvent;
    FStarted: Boolean;
    FMessageId: Integer;
    procedure ReadCommandLine;
    procedure StartPlatform;
    {$IF DEFINED(IOS) or DEFINED(ANDROID)}
    procedure HandleMessage(const Sender: TObject; const AMessage: TMessage);
    {$ENDIF}
  public
    //** @abstract(Creates the queue; used only by the unit's initialisation.)
    /// <summary>Creates the queue; used only by the unit's initialisation.</summary>
    constructor Create;
    //** @abstract(Stops listening for requests; used only by the unit's finalisation.)
    /// <summary>Stops listening for requests; used only by the unit's
    /// finalisation.</summary>
    destructor Destroy; override;
    //** @abstract(Adds a request, as the platform code does when the system sends one.)
    //**
    //** If OnOpenFile is set, it is called at once; otherwise the file waits for
    //** TakePending. Files that do not exist are ignored. Other sources of files to open,
    //** such as files dropped on the window, can use it too.
    //**
    //** @param(AFileName The file to open; made a full path.)
    /// <summary>Adds a request, as the platform code does when the system sends
    /// one.</summary>
    /// <remarks>If OnOpenFile is set, it is called at once; otherwise the file waits for
    /// TakePending. Files that do not exist are ignored. Other sources of files to open, such
    /// as files dropped on the window, can use it too.</remarks>
    /// <param name="AFileName">The file to open; made a full path.</param>
    procedure Request(const AFileName: String);
    //** @abstract(Returns and clears the requests so far, and starts listening for more.)
    //**
    //** The first call also reads the command line, and on Android the intent that started
    //** the application. Blocks briefly on Android if a file must first be copied from
    //** another app.
    //**
    //** @returns(The files asked for so far, oldest first; empty if there are none.)
    /// <summary>Returns and clears the requests so far, and starts listening for
    /// more.</summary>
    /// <remarks>The first call also reads the command line, and on Android the intent that
    /// started the application. Blocks briefly on Android if a file must first be copied from
    /// another app.</remarks>
    /// <returns>The files asked for so far, oldest first; empty if there are none.</returns>
    function TakePending: TArray<String>;
    //** @abstract(Called for each request that arrives after TakePending; nil to queue them.)
    //**
    //** Set it to nil before the object it belongs to is freed. Command-line requests all
    //** arrive before TakePending, so on Windows and Linux it is never called.
    /// <summary>Called for each request that arrives after TakePending; nil to queue
    /// them.</summary>
    /// <remarks>Set it to nil before the object it belongs to is freed. Command-line requests
    /// all arrive before TakePending, so on Windows and Linux it is never called.</remarks>
    property OnOpenFile: TSprite3DOpenFileEvent read FOnOpenFile write FOnOpenFile;
  end;

//** @abstract(The application's one queue of files to open.)
//**
//** @returns(The queue, which lives until the application ends.)
/// <summary>The application's one queue of files to open.</summary>
/// <returns>The queue, which lives until the application ends.</returns>
function FileOpenRequests: TSprite3DFileOpenRequests;

//** @abstract(Turns a @code(file:) URL into a local path; other text is returned unchanged.)
//**
//** Handles @code(file:///path) and @code(file://localhost/path), and decodes percent
//** escapes such as @code(%20).
//**
//** @param(AUrl A URL or a path.)
//**
//** @returns(The local path.)
/// <summary>Turns a <c>file:</c> URL into a local path; other text is returned
/// unchanged.</summary>
/// <remarks>Handles <c>file:///path</c> and <c>file://localhost/path</c>, and decodes percent
/// escapes such as <c>%20</c>.</remarks>
/// <param name="AUrl">A URL or a path.</param>
/// <returns>The local path.</returns>
function FileUrlToPath(const AUrl: String): String;

implementation

uses
  System.IOUtils, System.NetEncoding
  {$IF DEFINED(IOS)}
  , FMX.Platform, FMX.Platform.iOS
  {$ELSEIF DEFINED(MACOS)}
  , System.TypInfo, Macapi.ObjectiveC, Macapi.ObjCRuntime, Macapi.Foundation,
  Macapi.Helpers
  {$ELSEIF DEFINED(ANDROID)}
  , Androidapi.JNIBridge, Androidapi.JNI.JavaTypes, Androidapi.JNI.Net,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers, FMX.Platform.Android
  {$ENDIF}
  ;

var
  GRequests: TSprite3DFileOpenRequests;

function FileOpenRequests: TSprite3DFileOpenRequests;
begin
  Result := GRequests;
end;

function FileUrlToPath(const AUrl: String): String;
begin
  Result := AUrl;
  if not Result.StartsWith('file:', True) then
    Exit;
  Result := Result.Substring(5);
  if Result.StartsWith('//localhost/', True) then
    Result := Result.Substring(11)
  else if Result.StartsWith('//') then
    Result := Result.Substring(2);
  Result := TNetEncoding.URL.Decode(Result);
end;

{$IF DEFINED(MACOS) and not DEFINED(IOS)}
// macOS: Finder and the Dock send an "open documents" Apple event, at launch
// and while running, instead of using the command line. The handler is
// installed when the unit is initialised and again when the application is
// about to finish launching, because AppKit installs its own handlers then;
// the launch-time event comes after that.
const
  kCoreEventClass = $61657674;    // 'aevt'
  kAEOpenDocuments = $6F646F63;   // 'odoc'
  keyDirectObject = $2D2D2D2D;    // '----'
  typeFileURL = $6675726C;        // 'furl'

type
  ISprite3DOpenDocuments = interface(NSObject)
    ['{8E0C1D52-4C5B-4F0B-9E2B-6C3A2D1F7A44}']
    procedure handleOpenDocuments(event: NSAppleEventDescriptor;
      withReplyEvent: NSAppleEventDescriptor); cdecl;
    procedure appWillFinishLaunching(notification: NSNotification); cdecl;
  end;

  TOpenDocumentsHandler = class(TOCLocal)
  private
    procedure AddDescriptor(const ADescriptor: NSAppleEventDescriptor);
  public
    function GetObjectiveCClass: PTypeInfo; override;
    procedure handleOpenDocuments(event: NSAppleEventDescriptor;
      withReplyEvent: NSAppleEventDescriptor); cdecl;
    procedure appWillFinishLaunching(notification: NSNotification); cdecl;
    procedure Install;
    procedure ObserveLaunch;
  end;

var
  GOpenDocuments: TOpenDocumentsHandler;

function TOpenDocumentsHandler.GetObjectiveCClass: PTypeInfo;
begin
  Result := TypeInfo(ISprite3DOpenDocuments);
end;

procedure TOpenDocumentsHandler.Install;
begin
  TNSAppleEventManager.Wrap(TNSAppleEventManager.OCClass.sharedAppleEventManager)
    .setEventHandler(GetObjectID, sel_getUid('handleOpenDocuments:withReplyEvent:'),
      kCoreEventClass, kAEOpenDocuments);
end;

procedure TOpenDocumentsHandler.ObserveLaunch;
begin
  TNSNotificationCenter.Wrap(TNSNotificationCenter.OCClass.defaultCenter)
    .addObserver(GetObjectID, sel_getUid('appWillFinishLaunching:'),
      StrToNSStr('NSApplicationWillFinishLaunchingNotification'), nil);
end;

procedure TOpenDocumentsHandler.appWillFinishLaunching(notification: NSNotification);
begin
  try
    Install;
  except
    // Never let an exception reach Objective-C
  end;
end;

procedure TOpenDocumentsHandler.AddDescriptor(const ADescriptor: NSAppleEventDescriptor);
var
  Url: NSAppleEventDescriptor;
begin
  if ADescriptor = nil then
    Exit;
  Url := ADescriptor.coerceToDescriptorType(typeFileURL);
  if (Url <> nil) and (Url.stringValue <> nil) then
    GRequests.Request(FileUrlToPath(NSStrToStr(Url.stringValue)));
end;

procedure TOpenDocumentsHandler.handleOpenDocuments(event: NSAppleEventDescriptor;
  withReplyEvent: NSAppleEventDescriptor);
var
  List: NSAppleEventDescriptor;
  I, Count: Integer;
begin
  try
    List := event.paramDescriptorForKeyword(keyDirectObject);
    if List = nil then
      Exit;
    Count := List.numberOfItems;
    if Count = 0 then
      AddDescriptor(List)   // a single file, not a list
    else
      for I := 1 to Count do   // Apple event lists count from 1
        AddDescriptor(List.descriptorAtIndex(I));
  except
    // Never let an exception reach Objective-C
  end;
end;
{$ENDIF}

{$IFDEF ANDROID}
// Android: a file opened from another app arrives as a VIEW intent whose
// data is a file: or, more often, a content: URI. Content is copied into
// the cache folder under its display name, so the caller gets a real file.
function ContentDisplayName(const AUri: Jnet_Uri): String;
var
  Cursor: JCursor;
  Index: Integer;
begin
  Result := String.Empty;
  Cursor := TAndroidHelper.Context.getContentResolver.query(AUri, nil, nil, nil, nil);
  if Cursor = nil then
    Exit;
  try
    if Cursor.moveToFirst then
    begin
      Index := Cursor.getColumnIndex(StringToJString('_display_name'));
      if Index >= 0 then
        Result := JStringToString(Cursor.getString(Index));
    end;
  finally
    Cursor.close;
  end;
end;

function CopyContentToCache(const AUri: Jnet_Uri): String;
var
  Name: String;
  Input: JInputStream;
  Output: TFileStream;
  Buffer: TJavaArray<Byte>;
  Count: Integer;
begin
  Name := ExtractFileName(ContentDisplayName(AUri).Replace('/', '_'));
  if Name = String.Empty then
    Name := 'opened-file';
  Result := TPath.Combine(TPath.Combine(TPath.GetCachePath, 'opened'), Name);
  ForceDirectories(ExtractFileDir(Result));

  Input := TAndroidHelper.Context.getContentResolver.openInputStream(AUri);
  if Input = nil then
    Exit(String.Empty);
  Buffer := TJavaArray<Byte>.Create(65536);
  try
    Output := TFileStream.Create(Result, fmCreate);
    try
      repeat
        Count := Input.read(Buffer);
        if Count > 0 then
          Output.WriteBuffer(Buffer.Data^, Count);
      until Count <= 0;
    finally
      Output.Free;
    end;
  finally
    Buffer.Free;
    Input.close;
  end;
end;

procedure RequestFromIntent(const AIntent: JIntent);
var
  Uri: Jnet_Uri;
  Scheme, Path: String;
begin
  if (AIntent = nil) or (AIntent.getAction = nil) or
    not AIntent.getAction.equals(TJIntent.JavaClass.ACTION_VIEW) then
    Exit;
  Uri := AIntent.getData;
  if Uri = nil then
    Exit;
  Scheme := JStringToString(Uri.getScheme);
  try
    if SameText(Scheme, 'file') then
      Path := JStringToString(Uri.getPath)
    else if SameText(Scheme, 'content') then
      Path := CopyContentToCache(Uri)
    else
      Path := String.Empty;
  except
    Path := String.Empty;   // unreadable: ignore the request
  end;
  if Path <> String.Empty then
    GRequests.Request(Path);
end;
{$ENDIF}

{ TSprite3DFileOpenRequests }

constructor TSprite3DFileOpenRequests.Create;
begin
  inherited Create;
  FMessageId := -1;
  {$IFDEF IOS}
  // Open-URL events can arrive before the form is shown, so listen at once
  FMessageId := TMessageManager.DefaultManager.SubscribeToMessage(
    TApplicationEventMessage, HandleMessage);
  {$ENDIF}
end;

destructor TSprite3DFileOpenRequests.Destroy;
begin
  FOnOpenFile := nil;
  {$IF DEFINED(IOS)}
  TMessageManager.DefaultManager.Unsubscribe(TApplicationEventMessage, FMessageId);
  {$ELSEIF DEFINED(ANDROID)}
  if FMessageId >= 0 then
    TMessageManager.DefaultManager.Unsubscribe(TMessageReceivedNotification, FMessageId);
  {$ENDIF}
  inherited;
end;

procedure TSprite3DFileOpenRequests.Request(const AFileName: String);
var
  FileName: String;
begin
  if AFileName = String.Empty then
    Exit;
  FileName := ExpandFileName(AFileName);
  if not FileExists(FileName) then
    Exit;
  if Assigned(FOnOpenFile) then
    FOnOpenFile(FileName)
  else
    FPending := FPending + [FileName];
end;

// Every argument that names an existing file; options such as -x, and
// /x on Windows, are skipped
procedure TSprite3DFileOpenRequests.ReadCommandLine;
var
  I: Integer;
  Arg: String;
begin
  for I := 1 to ParamCount do
  begin
    Arg := ParamStr(I);
    if Arg.StartsWith('-') then
      Continue;
    {$IFDEF MSWINDOWS}
    if Arg.StartsWith('/') then
      Continue;
    {$ENDIF}
    Request(Arg);
  end;
end;

// Starts listening where the platform needs the application to be running
procedure TSprite3DFileOpenRequests.StartPlatform;
begin
  {$IFDEF ANDROID}
  // Later VIEW intents reach the running activity as messages
  TAndroidHelper.Activity.registerIntentAction(TJIntent.JavaClass.ACTION_VIEW);
  FMessageId := TMessageManager.DefaultManager.SubscribeToMessage(
    TMessageReceivedNotification, HandleMessage);
  RequestFromIntent(TAndroidHelper.Activity.getIntent);
  {$ENDIF}
end;

{$IF DEFINED(IOS) or DEFINED(ANDROID)}
procedure TSprite3DFileOpenRequests.HandleMessage(const Sender: TObject;
  const AMessage: TMessage);
{$IFDEF IOS}
var
  Event: TApplicationEventData;
{$ENDIF}
begin
  {$IF DEFINED(IOS)}
  if not (AMessage is TApplicationEventMessage) then
    Exit;
  Event := TApplicationEventMessage(AMessage).Value;
  if (Event.Event = TApplicationEvent.OpenURL) and
    (Event.Context is TiOSOpenApplicationContext) then
    Request(FileUrlToPath(TiOSOpenApplicationContext(Event.Context).URL));
  {$ELSEIF DEFINED(ANDROID)}
  if AMessage is TMessageReceivedNotification then
    RequestFromIntent(TMessageReceivedNotification(AMessage).Value);
  {$ENDIF}
end;
{$ENDIF}

function TSprite3DFileOpenRequests.TakePending: TArray<String>;
var
  Earlier: TArray<String>;
begin
  if not FStarted then
  begin
    FStarted := True;
    // Command-line files come first: they started the application
    Earlier := FPending;
    FPending := nil;
    ReadCommandLine;
    FPending := FPending + Earlier;
    StartPlatform;
  end;
  Result := FPending;
  FPending := nil;
end;

initialization
  GRequests := TSprite3DFileOpenRequests.Create;
  {$IF DEFINED(MACOS) and not DEFINED(IOS)}
  GOpenDocuments := TOpenDocumentsHandler.Create;
  try
    GOpenDocuments.Install;
    GOpenDocuments.ObserveLaunch;
  except
    // Without the handler, Finder requests are lost but the application runs
  end;
  {$ENDIF}

finalization
  {$IF DEFINED(MACOS) and not DEFINED(IOS)}
  FreeAndNil(GOpenDocuments);
  {$ENDIF}
  FreeAndNil(GRequests);

end.
