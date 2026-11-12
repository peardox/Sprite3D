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
//** Windows   command line: Explorer starts the program with the file's full path; with
//**           HandOffToRunningInstance, a copy started while another runs hands its files to
//**           that one, through WM_COPYDATA to a hidden window, and ends
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

    Windows   command line: Explorer starts the program with the file's full path; with
              HandOffToRunningInstance, a copy started while another runs hands its files to
              that one, through WM_COPYDATA to a hidden window, and ends
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
  TSprite3DOpenFileEvent = procedure(const AFileName: String) of object;

  //** @abstract(The queue of files the operating system has asked the application to open.)
  //**
  //** There is one, created when the unit is initialised and reached through
  //** FileOpenRequests; do not create or free it. Call TakePending once the application can
  //** open files, normally when the main form is shown, then set OnOpenFile for the requests
  //** that come later. For the main thread only.
  TSprite3DFileOpenRequests = class
  private
    //** @abstract(The requests waiting for TakePending, oldest first; FOnOpenFile receives
    //** later ones; FStarted is set by the first TakePending; FMessageId is the iOS or Android
    //** message subscription, or -1.)
    FPending: TArray<String>;
    FOnOpenFile: TSprite3DOpenFileEvent;
    FStarted: Boolean;
    FMessageId: Integer;
    //** @abstract(Requests every file named on the command line.)
    procedure ReadCommandLine;
    //** @abstract(Starts listening where the platform needs the application running: on
    //** Android, for VIEW intents.)
    procedure StartPlatform;
    {$IF DEFINED(IOS) or DEFINED(ANDROID)}
    //** @abstract(Requests the file of an iOS open-URL event or an Android VIEW intent.)
    //** @param(Sender The message's sender.)
    //** @param(AMessage The message.)
    procedure HandleMessage(const Sender: TObject; const AMessage: TMessage);
    {$ENDIF}
  public
    //** @abstract(Creates the queue; used only by the unit's initialisation.)
    constructor Create;
    //** @abstract(Stops listening for requests; used only by the unit's finalisation.)
    destructor Destroy; override;
    //** @abstract(Adds a request, as the platform code does when the system sends one.)
    //**
    //** If OnOpenFile is set, it is called at once; otherwise the file waits for
    //** TakePending. Files that do not exist are ignored. Other sources of files to open,
    //** such as files dropped on the window, can use it too.
    //**
    //** @param(AFileName The file to open; made a full path.)
    procedure Request(const AFileName: String);
    //** @abstract(Returns and clears the requests so far, and starts listening for more.)
    //**
    //** The first call also reads the command line, and on Android the intent that started
    //** the application. Blocks briefly on Android if a file must first be copied from
    //** another app.
    //**
    //** @returns(The files asked for so far, oldest first; empty if there are none.)
    function TakePending: TArray<String>;
    //** @abstract(Called for each request that arrives after TakePending; nil to queue them.)
    //**
    //** Set it to nil before the object it belongs to is freed. Command-line requests all
    //** arrive before TakePending, so on Windows and Linux it is never called.
    property OnOpenFile: TSprite3DOpenFileEvent read FOnOpenFile write FOnOpenFile;
  end;

//** @abstract(The application's one queue of files to open.)
//**
//** @returns(The queue, which lives until the application ends.)
function FileOpenRequests: TSprite3DFileOpenRequests;

//** @abstract(Hands the files on the command line to a copy of the application already
//** running, so it opens them rather than a second window; True if it did.)
//**
//** Call it first thing in the program, before @code(Application.Initialize); on True, end
//** the program at once. The first copy to call it becomes the one running: it keeps a
//** named mutex and a hidden message-only window, and every later copy started with files,
//** as by double-clicking a model in Explorer, sends their full paths to that window and
//** returns True. The running copy then passes each to Request, from its own main loop,
//** and brings its main form to the front. A later copy started with no files, or one that
//** cannot reach the running copy within a few seconds (it is still starting, or hung),
//** returns False and runs as a copy of its own, so no file is ever lost.
//**
//** Several files opened together from Explorer each start a copy; all reach the first,
//** in turn. Only copies run by the same user in the same session are seen.
//**
//** Windows only. macOS already sends files to the copy running, through the "open
//** documents" event; on other platforms it returns False.
//**
//** @param(AInstanceName A name for the application, the same in every copy, used for the
//** mutex and the window class; letters, digits and dots only.)
//**
//** @returns(True if the files went to the copy running, and this one should end.)
function HandOffToRunningInstance(const AInstanceName: String): Boolean;

//** @abstract(Turns a @code(file:) URL into a local path; other text is returned unchanged.)
//**
//** Handles @code(file:///path) and @code(file://localhost/path), and decodes percent
//** escapes such as @code(%20).
//**
//** @param(AUrl A URL or a path.)
//**
//** @returns(The local path.)
function FileUrlToPath(const AUrl: String): String;

implementation

uses
  System.IOUtils, System.NetEncoding
  {$IF DEFINED(MSWINDOWS)}
  , Winapi.Windows, Winapi.Messages, FMX.Forms, FMX.Platform.Win
  {$ELSEIF DEFINED(IOS)}
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

// Every argument that names an existing file, as a full path; options such
// as -x, and /x on Windows, are skipped
function CommandLineFiles: TArray<String>;
var
  I: Integer;
  Arg, FileName: String;
begin
  Result := nil;
  for I := 1 to ParamCount do
  begin
    Arg := ParamStr(I);
    if Arg.StartsWith('-') then
      Continue;
    {$IFDEF MSWINDOWS}
    if Arg.StartsWith('/') then
      Continue;
    {$ENDIF}
    FileName := ExpandFileName(Arg);
    if FileExists(FileName) then
      Result := Result + [FileName];
  end;
end;

{$IFDEF MSWINDOWS}
// Windows: one copy of the application at a time takes the files. The first
// copy keeps a named mutex, which tells later copies that it is running, and
// a hidden message-only window, which receives their files as WM_COPYDATA:
// the paths, each ended by #0, in UTF-16. The message is sent with a
// timeout, so a hung copy never holds up a new one.
const
  // WM_COPYDATA's dwData for a list of files, 'S3DF'
  COPYDATA_OPEN_FILES = $53334446;
  // How long a later copy waits for the first to create its window, which it
  // does as it starts, and for it to take the files
  HANDOFF_WAIT_MS = 5000;
  HANDOFF_POLL_MS = 100;

var
  // The first copy's mutex and window; 0 in a later copy that runs on its own
  GInstanceMutex: THandle;
  GReceiverWindow: HWND;
  GReceiverClass: String;

function ReceiverClassName(const AInstanceName: String): String;
begin
  Result := AInstanceName + '.OpenFiles';
end;

// The running copy's main form, brought forward and restored if minimised.
// Windows lets it come to the front because the copy that sent the files
// allowed it with AllowSetForegroundWindow.
procedure BringApplicationForward;
var
  Wnd: HWND;
begin
  if (Application = nil) or (Application.MainForm = nil) then
    Exit;
  Wnd := FormToHWND(Application.MainForm);
  if Wnd = 0 then
    Exit;
  if IsIconic(Wnd) then
    ShowWindow(Wnd, SW_RESTORE);
  SetForegroundWindow(Wnd);
end;

// The hidden window's procedure: files from a later copy are passed to
// Request from a fresh turn of the main loop, not inside SendMessage, so the
// later copy is answered at once and can end while they load
function ReceiverWindowProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  Data: PCopyDataStruct;
  Text: String;
begin
  if AMsg = WM_COPYDATA then
  begin
    Data := PCopyDataStruct(ALParam);
    if (Data <> nil) and (Data.dwData = COPYDATA_OPEN_FILES) and
      (Data.lpData <> nil) and (Data.cbData >= SizeOf(Char)) then
    begin
      SetString(Text, PChar(Data.lpData), Data.cbData div SizeOf(Char));
      TThread.ForceQueue(nil,
        procedure
        begin
          try
            BringApplicationForward;
            if GRequests <> nil then
              for var FileName in Text.Split([#0], TStringSplitOptions.ExcludeEmpty) do
                GRequests.Request(FileName);
          except
            // A bad request must not end the application
          end;
        end);
      Exit(1);
    end;
  end;
  Result := DefWindowProc(AWnd, AMsg, AWParam, ALParam);
end;

// The first copy's hidden window, which later copies find by its class
procedure CreateReceiver(const AInstanceName: String);
var
  WindowClass: TWndClass;
begin
  GReceiverClass := ReceiverClassName(AInstanceName);
  FillChar(WindowClass, SizeOf(WindowClass), 0);
  WindowClass.lpfnWndProc := @ReceiverWindowProc;
  WindowClass.hInstance := HInstance;
  WindowClass.lpszClassName := PChar(GReceiverClass);
  if Winapi.Windows.RegisterClass(WindowClass) = 0 then
    Exit;
  GReceiverWindow := CreateWindowEx(0, PChar(GReceiverClass), nil, 0, 0, 0, 0, 0,
    HWND_MESSAGE, 0, HInstance, nil);
end;

procedure DestroyReceiver;
begin
  if GReceiverWindow <> 0 then
  begin
    DestroyWindow(GReceiverWindow);
    GReceiverWindow := 0;
  end;
  if GReceiverClass <> String.Empty then
    Winapi.Windows.UnregisterClass(PChar(GReceiverClass), HInstance);
  if GInstanceMutex <> 0 then
  begin
    CloseHandle(GInstanceMutex);
    GInstanceMutex := 0;
  end;
end;

// Sends AFiles to the running copy's window; True once it has taken them
function SendToRunningInstance(const AInstanceName: String;
  const AFiles: TArray<String>): Boolean;
var
  Text: String;
  Data: TCopyDataStruct;
  Wnd: HWND;
  ProcessId: DWORD;
  Answer: DWORD_PTR;
  Waited: Integer;
begin
  Result := False;
  Text := String.Join(#0, AFiles) + #0;
  Waited := 0;
  repeat
    Wnd := FindWindowEx(HWND_MESSAGE, 0, PChar(ReceiverClassName(AInstanceName)), nil);
    if Wnd <> 0 then
    begin
      // Lets the running copy bring its window to the front
      ProcessId := 0;
      GetWindowThreadProcessId(Wnd, @ProcessId);
      if ProcessId <> 0 then
        AllowSetForegroundWindow(ProcessId);
      Data.dwData := COPYDATA_OPEN_FILES;
      Data.cbData := Length(Text) * SizeOf(Char);
      Data.lpData := PChar(Text);
      Answer := 0;
      Exit((SendMessageTimeout(Wnd, WM_COPYDATA, 0, LPARAM(@Data),
        SMTO_ABORTIFHUNG or SMTO_BLOCK, HANDOFF_WAIT_MS, @Answer) <> 0) and (Answer = 1));
    end;
    // The first copy is still starting: its window comes soon
    Sleep(HANDOFF_POLL_MS);
    Inc(Waited, HANDOFF_POLL_MS);
  until Waited >= HANDOFF_WAIT_MS;
end;
{$ENDIF}

function HandOffToRunningInstance(const AInstanceName: String): Boolean;
{$IFDEF MSWINDOWS}
var
  Files: TArray<String>;
begin
  Result := False;
  if GInstanceMutex <> 0 then
    Exit;   // asked again: this copy is the one running
  GInstanceMutex := CreateMutex(nil, False, PChar('Local\' + AInstanceName + '.Instance'));
  if GInstanceMutex = 0 then
    Exit;   // cannot tell: run as usual
  if GetLastError <> ERROR_ALREADY_EXISTS then
  begin
    // The first copy: it takes the files of every later one
    CreateReceiver(AInstanceName);
    Exit;
  end;
  // Another copy is running. Only the first keeps the mutex
  CloseHandle(GInstanceMutex);
  GInstanceMutex := 0;
  Files := CommandLineFiles;
  if Length(Files) = 0 then
    Exit;   // started with no files: a window of its own
  Result := SendToRunningInstance(AInstanceName, Files);
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

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
//
// The "about to finish launching" notification is observed through
// CoreFoundation with a plain C callback, not through an Objective-C method
// on the handler: the Objective-C observer crashed on Apple silicon, and the
// callback needs no Objective-C class or method dispatch at all. The local
// CoreFoundation centre is the one NSNotificationCenter posts to.
const
  libCoreFoundation = '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation';
  kCFStringEncodingUTF8 = $08000100;
  kCFNotificationDeliverImmediately = 4;
  WILL_FINISH_LAUNCHING = 'NSApplicationWillFinishLaunchingNotification';

  kCoreEventClass = $61657674;    // 'aevt'
  kAEOpenDocuments = $6F646F63;   // 'odoc'
  keyDirectObject = $2D2D2D2D;    // '----'
  typeFileURL = $6675726C;        // 'furl'

type
  ISprite3DOpenDocuments = interface(NSObject)
    ['{8E0C1D52-4C5B-4F0B-9E2B-6C3A2D1F7A44}']
    procedure handleOpenDocuments(event: NSAppleEventDescriptor;
      withReplyEvent: NSAppleEventDescriptor); cdecl;
  end;

  TOpenDocumentsHandler = class(TOCLocal)
  private
    procedure AddDescriptor(const ADescriptor: NSAppleEventDescriptor);
  public
    function GetObjectiveCClass: PTypeInfo; override;
    procedure handleOpenDocuments(event: NSAppleEventDescriptor;
      withReplyEvent: NSAppleEventDescriptor); cdecl;
    procedure Install;
  end;

// Declared here with plain pointers, so nothing depends on how the RTL's
// own headers type them
function CFNotificationCenterGetLocalCenter: Pointer; cdecl;
  external libCoreFoundation name 'CFNotificationCenterGetLocalCenter';
procedure CFNotificationCenterAddObserver(ACenter, AObserver, ACallBack, AName,
  AObject: Pointer; ASuspensionBehavior: NativeInt); cdecl;
  external libCoreFoundation name 'CFNotificationCenterAddObserver';
procedure CFNotificationCenterRemoveObserver(ACenter, AObserver, AName,
  AObject: Pointer); cdecl;
  external libCoreFoundation name 'CFNotificationCenterRemoveObserver';
function CFStringCreateWithBytes(AAlloc, ABytes: Pointer; ANumBytes: NativeInt;
  AEncoding: UInt32; AIsExternal: Boolean): Pointer; cdecl;
  external libCoreFoundation name 'CFStringCreateWithBytes';
procedure CFRelease(AObject: Pointer); cdecl;
  external libCoreFoundation name 'CFRelease';

var
  GOpenDocuments: TOpenDocumentsHandler;
  // The notification's name, kept while the observer is registered
  GLaunchName: Pointer;

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

// Called by CoreFoundation, on the main thread, as the application is about
// to finish launching: AppKit has just installed its own Apple event
// handlers, so this one goes back in over them
procedure WillFinishLaunching(ACenter, AObserver, AName, AObject,
  AUserInfo: Pointer); cdecl;
begin
  try
    if GOpenDocuments <> nil then
      GOpenDocuments.Install;
  except
    // Never let an exception reach the operating system
  end;
end;

procedure ObserveLaunch;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(WILL_FINISH_LAUNCHING);
  GLaunchName := CFStringCreateWithBytes(nil, @Bytes[0], Length(Bytes),
    kCFStringEncodingUTF8, False);
  if GLaunchName = nil then
    Exit;
  // The observer pointer only identifies the registration
  CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter, @GLaunchName,
    @WillFinishLaunching, GLaunchName, nil, kCFNotificationDeliverImmediately);
end;

procedure StopObservingLaunch;
begin
  if GLaunchName = nil then
    Exit;
  CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter, @GLaunchName,
    GLaunchName, nil);
  CFRelease(GLaunchName);
  GLaunchName := nil;
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
begin
  for var FileName in CommandLineFiles do
    Request(FileName);
end;

// Starts listening where the platform needs the application to be running
procedure TSprite3DFileOpenRequests.StartPlatform;
begin
  {$IFDEF ANDROID}
  // Later VIEW intents reach the running activity as messages
  MainActivity.registerIntentAction(TJIntent.JavaClass.ACTION_VIEW);
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
    ObserveLaunch;
  except
    // Without the handler, Finder requests are lost but the application runs
  end;
  {$ENDIF}

finalization
  {$IFDEF MSWINDOWS}
  DestroyReceiver;
  {$ENDIF}
  {$IF DEFINED(MACOS) and not DEFINED(IOS)}
  StopObservingLaunch;
  FreeAndNil(GOpenDocuments);
  {$ENDIF}
  FreeAndNil(GRequests);

end.
