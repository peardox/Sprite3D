//** @abstract(Renders a Gorilla3D viewport's scene to an off-screen target of any size.)
//**
//** TSprite3DOffscreen is a Gorilla3D render pass. It is attached to a TGorillaViewport and
//** stays switched off until Grab is called. Grab switches it on for one frame: the pass
//** renders the viewport's scene, through the viewport's own camera, into a frame buffer of
//** Width by Height pixels, 256 by 256 unless changed, and the result is read back into an
//** FMX TBitmap and handed to the caller's procedure. The pass then switches itself off
//** again, so it costs nothing between grabs.
//**
//** The capture is asynchronous. Grab returns at once; the procedure runs on the main thread
//** after the next frame has been drawn, outside the render loop, so it may save files or
//** show dialogs. The viewport must be rendering for this to happen: if it is hidden, for
//** example on another tab, the grab waits until it is shown again, or until Cancel.
//**
//** The camera's projection is worked out for the target's size. To make the model fill the
//** target, fit the camera to the target's shape in OnBeforeGrab and put it back in
//** OnAfterGrab; the screen never shows the grab's framing.
//**
//** Read-back uses OpenGL directly, with the GL functions looked up at run time in the
//** platform's library, so it works on every platform Gorilla renders with OpenGL, its
//** default: Windows, macOS and Linux with desktop OpenGL, Android and iOS with OpenGL ES 3.
//** If a project switches Gorilla to its optional Vulkan backend, grabs fail with an error
//** saying an OpenGL function is not available.
//**
//** @preformatted(
//** TGorillaRenderPassController @(Gorilla.Controller@)
//** `-- TSprite3DOffscreen   pre-pass into a Width x Height frame buffer
//** )
unit Sprite3DOffscreen;

{
  Renders a Gorilla3D viewport's scene to an off-screen target of any size.

  TSprite3DOffscreen is a Gorilla3D render pass. It is attached to a
  TGorillaViewport and stays switched off until Grab is called. Grab
  switches it on for one frame: the pass renders the viewport's scene,
  through the viewport's own camera, into a frame buffer of Width by Height
  pixels, 256 by 256 unless changed, and the result is read back into an
  FMX TBitmap and handed to the caller's procedure. The pass then switches
  itself off again, so it costs nothing between grabs.

  The capture is asynchronous. Grab returns at once; the procedure runs on
  the main thread after the next frame has been drawn, outside the render
  loop, so it may save files or show dialogs. The viewport must be
  rendering for this to happen: if it is hidden, for example on another
  tab, the grab waits until it is shown again, or until Cancel.

  The camera's projection is worked out for the target's size. To make the
  model fill the target, fit the camera to the target's shape in
  OnBeforeGrab and put it back in OnAfterGrab; the screen never shows the
  grab's framing.

  Read-back uses OpenGL directly, with the GL functions looked up at run
  time in the platform's library, so it works on every platform Gorilla
  renders with OpenGL, its default: Windows, macOS and Linux with desktop
  OpenGL, Android and iOS with OpenGL ES 3. If a project switches Gorilla
  to its optional Vulkan backend, grabs fail with an error saying an OpenGL
  function is not available.

    TGorillaRenderPassController (Gorilla.Controller)
    `-- TSprite3DOffscreen   pre-pass into a Width x Height frame buffer
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Types3D, FMX.Graphics,
  Gorilla.Viewport, Gorilla.Context.Rendering, Gorilla.Controller;

const
  //** @abstract(The width, in pixels, of a new TSprite3DOffscreen's target.)
  /// <summary>The width, in pixels, of a new TSprite3DOffscreen's target.</summary>
  DEFAULT_OFFSCREEN_WIDTH = 256;
  //** @abstract(The height, in pixels, of a new TSprite3DOffscreen's target.)
  /// <summary>The height, in pixels, of a new TSprite3DOffscreen's target.</summary>
  DEFAULT_OFFSCREEN_HEIGHT = 256;

type
  //** @abstract(Receives the result of TSprite3DOffscreen.Grab.)
  //**
  //** Runs on the main thread, outside the render loop. The bitmap belongs to the
  //** TSprite3DOffscreen and is freed when the procedure returns; to keep the image, copy it
  //** with @code(TBitmap.Assign) or save it.
  //**
  //** @param(ABitmap The rendered image, Width by Height pixels, or nil if the grab failed.)
  //**
  //** @param(AError Why the grab failed; empty when ABitmap is assigned.)
  /// <summary>Receives the result of TSprite3DOffscreen.Grab.</summary>
  /// <remarks>Runs on the main thread, outside the render loop. The bitmap belongs to the
  /// TSprite3DOffscreen and is freed when the procedure returns; to keep the image, copy it
  /// with <c>TBitmap.Assign</c> or save it.</remarks>
  /// <param name="ABitmap">The rendered image, Width by Height pixels, or nil if the grab
  /// failed.</param>
  /// <param name="AError">Why the grab failed; empty when ABitmap is assigned.</param>
  TSprite3DGrabProc = reference to procedure(const ABitmap: TBitmap; const AError: String);

  //** @abstract(Signature of TSprite3DOffscreen.OnBeforeGrab.)
  //**
  //** @param(Sender The TSprite3DOffscreen.)
  //**
  //** @param(AWidth The target's width in pixels.)
  //**
  //** @param(AHeight The target's height in pixels.)
  /// <summary>Signature of TSprite3DOffscreen.OnBeforeGrab.</summary>
  /// <param name="Sender">The TSprite3DOffscreen.</param>
  /// <param name="AWidth">The target's width in pixels.</param>
  /// <param name="AHeight">The target's height in pixels.</param>
  TSprite3DGrabSizeEvent = procedure(Sender: TObject; const AWidth,
    AHeight: Integer) of object;

  //** @abstract(A render pass that draws the viewport's scene off screen, one frame on
  //** request.)
  //**
  //** Create it, set Viewport to the TGorillaViewport to capture, then call Grab whenever an
  //** image is wanted. The pass uses the viewport's camera, lights and models as they are at
  //** the time of the frame. It takes over the inherited OnEndRender event, which must not be
  //** reassigned. All members are for the main thread only.
  //**
  //** @seealso(TSprite3DGrabProc)
  /// <summary>A render pass that draws the viewport's scene off screen, one frame on
  /// request.</summary>
  /// <remarks>Create it, set Viewport to the TGorillaViewport to capture, then call Grab
  /// whenever an image is wanted. The pass uses the viewport's camera, lights and models as
  /// they are at the time of the frame. It takes over the inherited OnEndRender event, which
  /// must not be reassigned. All members are for the main thread only.</remarks>
  /// <seealso cref="TSprite3DGrabProc"/>
  TSprite3DOffscreen = class(TGorillaRenderPassController)
  private
    FWidth: Integer;
    FHeight: Integer;
    FPremultiplyAlpha: Boolean;
    FBusy: Boolean;      // from Grab until the result has been delivered
    FPending: Boolean;   // waiting for the frame to read back
    FOnGrabbed: TSprite3DGrabProc;
    FAlive: IInterface;  // shared with queued deliveries; see Destroy
    FPrepared: Boolean;  // OnBeforeGrab has run and OnAfterGrab has not
    FOnBeforeGrab: TSprite3DGrabSizeEvent;
    FOnAfterGrab: TNotifyEvent;
    procedure Restore;
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure ApplyTargetSize;
    procedure HandleEndRender(ASender: TObject; const AContext: TContext3D;
      const ACount: Integer; const APass: TRenderPass);
    function ReadOutput(out AError: String): TBitmap;
    procedure Deliver(const ABitmap: TBitmap; const AError: String);
  protected
    //** @abstract(Returns nil: this pass draws every object with its own materials.)
    //**
    //** Abstract in TGorillaRenderPassController, so it must be overridden. A pass's material
    //** source provides the shader for the RectToFBO method, or one material that every
    //** object is drawn with; this pass uses RenderListToFBO and must keep each model's own
    //** materials and textures, so it has none.
    //**
    //** @returns(Always nil.)
    /// <summary>Returns nil: this pass draws every object with its own materials.</summary>
    /// <remarks>Abstract in TGorillaRenderPassController, so it must be overridden. A pass's
    /// material source provides the shader for the RectToFBO method, or one material that every
    /// object is drawn with; this pass uses RenderListToFBO and must keep each model's own
    /// materials and textures, so it has none.</remarks>
    /// <returns>Always nil.</returns>
    function CreateMaterialSource(): TGorillaRenderPassMaterialSource; override;
  public
    //** @abstract(Creates the pass, switched off, with a 256 by 256 target.)
    //**
    //** The pass renders before the main pass, into its own frame buffer, with Gorilla's
    //** default rendering @(order-independent transparency@), and clears to a transparent
    //** background. Nothing is drawn until Viewport is set and Grab is called.
    //**
    //** @param(AOwner The owner, which frees the pass; the viewport is a good choice.)
    //**
    //** @param(AId Gorilla's identifier for the pass; each pass on one viewport needs its own.)
    /// <summary>Creates the pass, switched off, with a 256 by 256 target.</summary>
    /// <remarks>The pass renders before the main pass, into its own frame buffer, with
    /// Gorilla's default rendering (order-independent transparency), and clears to a
    /// transparent background. Nothing is drawn until Viewport is set and Grab is
    /// called.</remarks>
    /// <param name="AOwner">The owner, which frees the pass; the viewport is a good
    /// choice.</param>
    /// <param name="AId">Gorilla's identifier for the pass; each pass on one viewport needs its
    /// own.</param>
    constructor Create(AOwner: TComponent;
      const AId: String = 'Sprite3DOffscreen'); override;
    //** @abstract(Frees the pass; a grab still waiting is dropped without calling back.)
    /// <summary>Frees the pass; a grab still waiting is dropped without calling
    /// back.</summary>
    destructor Destroy; override;
    //** @abstract(Asks for the next frame to be rendered off screen and passed to
    //** AOnGrabbed.)
    //**
    //** Returns at once and does not block. AOnGrabbed runs later on the main thread, once,
    //** with the image or with the reason it failed. Width and Height are fixed until then.
    //**
    //** @param(AOnGrabbed The procedure to call with the result; must not be nil.)
    //**
    //** @returns(True if the grab was started; False, with nothing started, if one is already
    //** under way @(see Busy@), Viewport is not set or AOnGrabbed is nil.)
    /// <summary>Asks for the next frame to be rendered off screen and passed to
    /// AOnGrabbed.</summary>
    /// <remarks>Returns at once and does not block. AOnGrabbed runs later on the main thread,
    /// once, with the image or with the reason it failed. Width and Height are fixed until
    /// then.</remarks>
    /// <param name="AOnGrabbed">The procedure to call with the result; must not be
    /// nil.</param>
    /// <returns>True if the grab was started; False, with nothing started, if one is already
    /// under way (see Busy), Viewport is not set or AOnGrabbed is nil.</returns>
    function Grab(const AOnGrabbed: TSprite3DGrabProc): Boolean;
    //** @abstract(Abandons a grab that is under way, without calling its procedure.)
    //**
    //** Does nothing if no grab is under way. Use it if the viewport may not render again
    //** soon, for example while it is hidden.
    /// <summary>Abandons a grab that is under way, without calling its procedure.</summary>
    /// <remarks>Does nothing if no grab is under way. Use it if the viewport may not render
    /// again soon, for example while it is hidden.</remarks>
    procedure Cancel;
    //** @abstract(True from a successful Grab until its procedure has run or Cancel.)
    /// <summary>True from a successful Grab until its procedure has run or
    /// Cancel.</summary>
    property Busy: Boolean read FBusy;
  published
    //** @abstract(The target's width in pixels; 256 by default.)
    //**
    //** Values below 1 count as 1. Changes made while Busy wait for the next grab.
    /// <summary>The target's width in pixels; 256 by default.</summary>
    /// <remarks>Values below 1 count as 1. Changes made while Busy wait for the next
    /// grab.</remarks>
    property Width: Integer read FWidth write SetWidth default DEFAULT_OFFSCREEN_WIDTH;
    //** @abstract(The target's height in pixels; 256 by default.)
    //**
    //** Values below 1 count as 1. Changes made while Busy wait for the next grab.
    /// <summary>The target's height in pixels; 256 by default.</summary>
    /// <remarks>Values below 1 count as 1. Changes made while Busy wait for the next
    /// grab.</remarks>
    property Height: Integer read FHeight write SetHeight default DEFAULT_OFFSCREEN_HEIGHT;
    //** @abstract(Whether read-back pixels are premultiplied by alpha; True by default.)
    //**
    //** FMX bitmaps hold premultiplied colour and convert back when saved. If the frame buffer
    //** already holds premultiplied colour, part-transparent edges come out too dark; set this
    //** to False then. It makes no difference to fully opaque pixels.
    /// <summary>Whether read-back pixels are premultiplied by alpha; True by
    /// default.</summary>
    /// <remarks>FMX bitmaps hold premultiplied colour and convert back when saved. If the frame
    /// buffer already holds premultiplied colour, part-transparent edges come out too dark; set
    /// this to False then. It makes no difference to fully opaque pixels.</remarks>
    property PremultiplyAlpha: Boolean read FPremultiplyAlpha write FPremultiplyAlpha
      default True;
    //** @abstract(Runs in Grab, just before the frame is requested, to set the scene up for
    //** the target.)
    //**
    //** Use it to fit the camera to the target's shape, for example with
    //** @code(TSprite3DCamera.FitToBounds@(Model, AWidth, AHeight@)), so the model fills the
    //** grab. Whatever it changes is drawn into the target and must be put back in
    //** OnAfterGrab, which follows it: after the pass has drawn, before the main pass draws the
    //** same frame, or from Cancel if the frame never comes. It is not called if the pass is
    //** freed first. Runs on the main thread.
    /// <summary>Runs in Grab, just before the frame is requested, to set the scene up for the
    /// target.</summary>
    /// <remarks>Use it to fit the camera to the target's shape, for example with
    /// <c>TSprite3DCamera.FitToBounds(Model, AWidth, AHeight)</c>, so the model fills the grab.
    /// Whatever it changes is drawn into the target and must be put back in OnAfterGrab, which
    /// follows it: after the pass has drawn, before the main pass draws the same frame, or from
    /// Cancel if the frame never comes. It is not called if the pass is freed first. Runs on
    /// the main thread.</remarks>
    property OnBeforeGrab: TSprite3DGrabSizeEvent read FOnBeforeGrab write FOnBeforeGrab;
    //** @abstract(Runs once after an OnBeforeGrab, to put back what it changed.)
    //**
    //** Called from inside the render, just after the target has been drawn and read, so the
    //** main pass in the same frame shows the scene as before; or from Cancel if the frame never
    //** came. Not called if the pass is freed while a grab is waiting. Runs on the main
    //** thread, and must only change scene state, not show dialogs or call Grab.
    /// <summary>Runs once after an OnBeforeGrab, to put back what it changed.</summary>
    /// <remarks>Called from inside the render, just after the target has been drawn and read,
    /// so the main pass in the same frame shows the scene as before; or from Cancel if the frame
    /// never came. Not called if the pass is freed while a grab is waiting. Runs on the main
    /// thread, and must only change scene state, not show dialogs or call Grab.</remarks>
    property OnAfterGrab: TNotifyEvent read FOnAfterGrab write FOnAfterGrab;
  end;

implementation

uses
  System.Math
  {$IFDEF POSIX}
  , Posix.Dlfcn
  {$ENDIF}
  ;

// Shared between the pass and the deliveries it queues, so a delivery that
// runs after the pass has been freed can tell, and do nothing.
type
  IAliveFlag = interface
    ['{6C0F9C2E-6A57-4E0E-9B7C-3A1F4F7D2B11}']
    function IsAlive: Boolean;
    procedure Kill;
  end;

  TAliveFlag = class(TInterfacedObject, IAliveFlag)
  private
    FAlive: Boolean;
  public
    constructor Create;
    function IsAlive: Boolean;
    procedure Kill;
  end;

constructor TAliveFlag.Create;
begin
  inherited Create;
  FAlive := True;
end;

function TAliveFlag.IsAlive: Boolean;
begin
  Result := FAlive;
end;

procedure TAliveFlag.Kill;
begin
  FAlive := False;
end;

// OpenGL is reached directly, without platform header units: every function
// needed is looked up at run time in the platform's GL library, so one code
// path serves desktop OpenGL (Windows, macOS, Linux) and OpenGL ES 3
// (Android, iOS). Frame buffer objects are core in both.
const
  GL_NO_ERROR                  = 0;
  GL_TEXTURE_2D                = $0DE1;
  GL_VIEWPORT                  = $0BA2;
  GL_PACK_ALIGNMENT            = $0D05;
  GL_RGBA                      = $1908;
  GL_UNSIGNED_BYTE             = $1401;
  GL_FLOAT                     = $1406;
  GL_FRAMEBUFFER_COMPLETE      = $8CD5;
  GL_COLOR_ATTACHMENT0         = $8CE0;
  GL_READ_FRAMEBUFFER          = $8CA8;
  GL_READ_FRAMEBUFFER_BINDING  = $8CAA;

type
  TGLenum = Cardinal;
  TGLint = Integer;
  TGLuint = Cardinal;
  TGLsizei = Integer;
  PGLint = ^TGLint;
  PGLuint = ^TGLuint;

  TGLGetError = function: TGLenum;
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLGetIntegerv = procedure(pname: TGLenum; params: PGLint);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLPixelStorei = procedure(pname: TGLenum; param: TGLint);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLReadPixels = procedure(x, y: TGLint; width, height: TGLsizei;
    format, atype: TGLenum; pixels: Pointer);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLGenFramebuffers = procedure(n: TGLsizei; framebuffers: PGLuint);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLDeleteFramebuffers = procedure(n: TGLsizei; framebuffers: PGLuint);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLBindFramebuffer = procedure(target: TGLenum; framebuffer: TGLuint);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLFramebufferTexture2D = procedure(target, attachment, textarget: TGLenum;
    texture: TGLuint; level: TGLint);
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
  TGLCheckFramebufferStatus = function(target: TGLenum): TGLenum;
    {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};

  TGLFuncs = record
    GetError: TGLGetError;
    GetIntegerv: TGLGetIntegerv;
    PixelStorei: TGLPixelStorei;
    ReadPixels: TGLReadPixels;
    GenFramebuffers: TGLGenFramebuffers;
    DeleteFramebuffers: TGLDeleteFramebuffers;
    BindFramebuffer: TGLBindFramebuffer;
    FramebufferTexture2D: TGLFramebufferTexture2D;
    CheckFramebufferStatus: TGLCheckFramebufferStatus;
    function Load(out AMissing: String): Boolean;
  end;

{$IF DEFINED(MSWINDOWS)}
// Declared here rather than taken from Winapi.Windows, whose TBitmap would
// hide FMX's in this unit
function GLGetModuleHandle(lpModuleName: PWideChar): NativeUInt; stdcall;
  external 'kernel32.dll' name 'GetModuleHandleW';
function GLGetProcAddress(hModule: NativeUInt; lpProcName: PAnsiChar): Pointer;
  stdcall; external 'kernel32.dll' name 'GetProcAddress';
function GLwglGetProcAddress(lpszProc: PAnsiChar): Pointer; stdcall;
  external 'opengl32.dll' name 'wglGetProcAddress';
{$ELSEIF DEFINED(IOS)}
const
  GL_LIBRARIES: array[0..0] of String =
    ('/System/Library/Frameworks/OpenGLES.framework/OpenGLES');
{$ELSEIF DEFINED(MACOS)}
const
  GL_LIBRARIES: array[0..0] of String =
    ('/System/Library/Frameworks/OpenGL.framework/OpenGL');
{$ELSEIF DEFINED(ANDROID)}
const
  GL_LIBRARIES: array[0..1] of String = ('libGLESv3.so', 'libGLESv2.so');
{$ELSE}
const
  // Linux: libglvnd's libGL first, then its GL-only and GLES libraries
  GL_LIBRARIES: array[0..2] of String =
    ('libGL.so.1', 'libOpenGL.so.0', 'libGLESv2.so.2');
{$ENDIF}

{$IFDEF POSIX}
var
  GLLibrary: NativeUInt = 0;
{$ENDIF}

// The address of a GL function in the current context, or nil
function GetGLProc(const AName: String): Pointer;
var
  Name: UTF8String;
{$IFDEF POSIX}
  I: Integer;
  Lib: UTF8String;
{$ENDIF}
begin
  Name := UTF8String(AName);
  {$IFDEF MSWINDOWS}
  // wglGetProcAddress gives extension and post-1.1 functions; it returns
  // nil, or 1, 2, 3 or -1 on some drivers, for the 1.1 functions that
  // opengl32.dll exports itself
  Result := GLwglGetProcAddress(PAnsiChar(Name));
  if (NativeUInt(Result) <= 3) or (NativeInt(Result) = -1) then
    Result := GLGetProcAddress(GLGetModuleHandle('opengl32.dll'),
      PAnsiChar(Name));
  {$ELSE}
  if GLLibrary = 0 then
    for I := Low(GL_LIBRARIES) to High(GL_LIBRARIES) do
    begin
      Lib := UTF8String(GL_LIBRARIES[I]);
      GLLibrary := dlopen(MarshaledAString(Lib), RTLD_LAZY);
      if GLLibrary <> 0 then
        Break;
    end;
  if GLLibrary = 0 then
    Exit(nil);
  Result := dlsym(GLLibrary, MarshaledAString(Name));
  {$ENDIF}
end;

function TGLFuncs.Load(out AMissing: String): Boolean;

  function Need(const AName: String): Pointer;
  begin
    Result := GetGLProc(AName);
    if (Result = nil) and (AMissing = String.Empty) then
      AMissing := AName;
  end;

begin
  AMissing := String.Empty;
  @GetError := Need('glGetError');
  @GetIntegerv := Need('glGetIntegerv');
  @PixelStorei := Need('glPixelStorei');
  @ReadPixels := Need('glReadPixels');
  @GenFramebuffers := Need('glGenFramebuffers');
  @DeleteFramebuffers := Need('glDeleteFramebuffers');
  @BindFramebuffer := Need('glBindFramebuffer');
  @FramebufferTexture2D := Need('glFramebufferTexture2D');
  @CheckFramebufferStatus := Need('glCheckFramebufferStatus');
  Result := AMissing = String.Empty;
end;

{ TSprite3DOffscreen }

constructor TSprite3DOffscreen.Create(AOwner: TComponent; const AId: String);
begin
  inherited Create(AOwner, AId);
  FAlive := TAliveFlag.Create;
  FWidth := DEFAULT_OFFSCREEN_WIDTH;
  FHeight := DEFAULT_OFFSCREEN_HEIGHT;
  FPremultiplyAlpha := True;

  Enabled := False;   // only on for the frame a grab needs
  _Type := TRenderPassType.Pre;
  Method := TRenderPassMethod.RenderListToFBO;
  RenderProc := TRenderPassRenderingProc.DefaultRendering;
  OverwriteColor := True;
  BackgroundColor := TAlphaColors.Null;   // transparent, for sprites
  ApplyTargetSize;
  OnEndRender := HandleEndRender;
end;

destructor TSprite3DOffscreen.Destroy;
begin
  // Any delivery already queued sees this and does nothing
  (FAlive as IAliveFlag).Kill;
  FOnGrabbed := nil;
  // No OnAfterGrab here: while the form is closing, what it would restore
  // may already be freed
  FPrepared := False;
  inherited;
end;

function TSprite3DOffscreen.CreateMaterialSource: TGorillaRenderPassMaterialSource;
begin
  Result := nil;   // RenderListToFBO with the objects' own materials
end;

procedure TSprite3DOffscreen.ApplyTargetSize;
begin
  OverwriteViewportSize := True;
  ViewportWidth := FWidth;
  ViewportHeight := FHeight;
end;

procedure TSprite3DOffscreen.SetWidth(const Value: Integer);
begin
  FWidth := Max(1, Value);
  if not FBusy then
    ApplyTargetSize;
end;

procedure TSprite3DOffscreen.SetHeight(const Value: Integer);
begin
  FHeight := Max(1, Value);
  if not FBusy then
    ApplyTargetSize;
end;

function TSprite3DOffscreen.Grab(const AOnGrabbed: TSprite3DGrabProc): Boolean;
begin
  Result := (not FBusy) and Assigned(Viewport) and Assigned(AOnGrabbed);
  if not Result then
    Exit;
  FOnGrabbed := AOnGrabbed;
  FBusy := True;
  ApplyTargetSize;   // pick up any size change made while busy
  // Let the owner fit the scene to the target; HandleEndRender restores it
  // and reads the frame back once this pass has drawn it
  if Assigned(FOnBeforeGrab) then
  begin
    FPrepared := True;
    FOnBeforeGrab(Self, FWidth, FHeight);
  end;
  FPending := True;
  Enabled := True;
  Viewport.Invalidate;
end;

procedure TSprite3DOffscreen.Cancel;
begin
  FPending := False;
  FBusy := False;
  FOnGrabbed := nil;
  Enabled := False;
  Restore;
end;

// Calls OnAfterGrab once for the OnBeforeGrab that ran, if any
procedure TSprite3DOffscreen.Restore;
begin
  if not FPrepared then
    Exit;
  FPrepared := False;
  if Assigned(FOnAfterGrab) then
    FOnAfterGrab(Self);
end;

procedure TSprite3DOffscreen.HandleEndRender(ASender: TObject;
  const AContext: TContext3D; const ACount: Integer; const APass: TRenderPass);
var
  Bitmap: TBitmap;
  Error: String;
begin
  if not FPending or (ACount <> 0) then
    Exit;
  FPending := False;
  // Still inside Gorilla's render loop with its context current: read the
  // pixels now, but leave everything else to Deliver's queued step
  Bitmap := ReadOutput(Error);
  // Before the main pass draws this frame, so the screen never shows the
  // grab's framing
  Restore;
  Deliver(Bitmap, Error);
end;

// Reads the area this pass drew in its output texture into a new bitmap of
// that size. Must run with the GL context current, i.e. inside the render.
function TSprite3DOffscreen.ReadOutput(out AError: String): TBitmap;
var
  GL: TGLFuncs;
  Missing: String;
  Tex: TTexture;
  TexW, TexH, X, Y, I: Integer;
  ReadX, ReadY, ReadW, ReadH: Integer;
  GLView: array[0..3] of TGLint;
  Fbo: TGLuint;
  OldRead, OldPack: TGLint;
  Status, GLErr: TGLenum;
  Pixels: TBytes;
  Floats: TArray<Single>;
  F: Single;
  Data: TBitmapData;
  Src, Dst: PByte;
  R, G, B, A: Cardinal;
begin
  Result := nil;
  AError := String.Empty;

  Tex := GetOutputTexture;
  if not Assigned(Tex) or (Tex.Handle = 0) then
  begin
    AError := 'The off-screen pass has no output texture yet.';
    Exit;
  end;
  TexW := Tex.Width;
  TexH := Tex.Height;
  if (TexW <= 0) or (TexH <= 0) then
  begin
    AError := 'The off-screen output texture has no size.';
    Exit;
  end;
  if not GL.Load(Missing) then
  begin
    AError := 'OpenGL function ' + Missing + ' is not available.';
    Exit;
  end;

  // Clear any error left by earlier calls, so the checks below are ours
  for I := 1 to 16 do
    if GL.GetError() = GL_NO_ERROR then
      Break;

  // The pass can draw into only part of its texture: with display scaling
  // the texture may be larger than ViewportWidth x ViewportHeight. So read
  // the area it drew, the GL viewport it is still using, when that lies
  // inside the texture; otherwise read the whole texture.
  GL.GetIntegerv(GL_VIEWPORT, @GLView[0]);
  if (GLView[2] > 0) and (GLView[3] > 0) and (GLView[0] >= 0) and
    (GLView[1] >= 0) and (GLView[0] + GLView[2] <= TexW) and
    (GLView[1] + GLView[3] <= TexH) then
  begin
    ReadX := GLView[0];
    ReadY := GLView[1];
    ReadW := GLView[2];
    ReadH := GLView[3];
  end
  else
  begin
    ReadX := 0;
    ReadY := 0;
    ReadW := TexW;
    ReadH := TexH;
  end;

  SetLength(Pixels, ReadW * ReadH * 4);
  GL.GetIntegerv(GL_READ_FRAMEBUFFER_BINDING, @OldRead);
  GL.GetIntegerv(GL_PACK_ALIGNMENT, @OldPack);
  Fbo := 0;
  GL.GenFramebuffers(1, @Fbo);
  try
    // A frame buffer of our own, bound for reading only, so whatever
    // Gorilla has bound for drawing is left alone
    GL.BindFramebuffer(GL_READ_FRAMEBUFFER, Fbo);
    GL.FramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
      GL_TEXTURE_2D, TGLuint(Tex.Handle), 0);
    Status := GL.CheckFramebufferStatus(GL_READ_FRAMEBUFFER);
    if Status <> GL_FRAMEBUFFER_COMPLETE then
    begin
      AError := Format('The off-screen texture cannot be read (frame buffer ' +
        'status $%.4x).', [Status]);
      Exit;
    end;
    GL.PixelStorei(GL_PACK_ALIGNMENT, 4);

    // RGBA bytes work on desktop GL and for 8-bit targets on OpenGL ES;
    // OpenGL ES only reads a float target as RGBA floats
    GL.ReadPixels(ReadX, ReadY, ReadW, ReadH, GL_RGBA, GL_UNSIGNED_BYTE,
      @Pixels[0]);
    GLErr := GL.GetError();
    if GLErr <> GL_NO_ERROR then
    begin
      SetLength(Floats, ReadW * ReadH * 4);
      GL.ReadPixels(ReadX, ReadY, ReadW, ReadH, GL_RGBA, GL_FLOAT, @Floats[0]);
      GLErr := GL.GetError();
      if GLErr <> GL_NO_ERROR then
      begin
        AError := Format('Reading the off-screen texture failed (OpenGL ' +
          'error $%.4x).', [GLErr]);
        Exit;
      end;
      for I := 0 to High(Floats) do
      begin
        F := Floats[I];
        if F < 0 then
          F := 0
        else if F > 1 then
          F := 1;
        Pixels[I] := Round(F * 255);
      end;
    end;
  finally
    GL.BindFramebuffer(GL_READ_FRAMEBUFFER, TGLuint(OldRead));
    GL.PixelStorei(GL_PACK_ALIGNMENT, OldPack);
    GL.DeleteFramebuffers(1, @Fbo);
  end;

  // OpenGL rows run bottom to top, in RGBA order; the bitmap's own pixel
  // format differs by platform (BGRA on desktop, often RGBA on mobile)
  Result := TBitmap.Create(ReadW, ReadH);
  try
    if not Result.Map(TMapAccess.Write, Data) then
      raise EInvalidOperation.Create('Cannot write to the grab bitmap.');
    try
      for Y := 0 to ReadH - 1 do
      begin
        Src := @Pixels[(ReadH - 1 - Y) * ReadW * 4];
        Dst := Data.GetScanline(Y);
        for X := 0 to ReadW - 1 do
        begin
          R := Src[0];
          G := Src[1];
          B := Src[2];
          A := Src[3];
          if FPremultiplyAlpha and (A < 255) then
          begin
            R := (R * A + 127) div 255;
            G := (G * A + 127) div 255;
            B := (B * A + 127) div 255;
          end;
          case Data.PixelFormat of
            TPixelFormat.BGRA:
              begin
                Dst[0] := B;
                Dst[1] := G;
                Dst[2] := R;
                Dst[3] := A;
              end;
            TPixelFormat.RGBA:
              begin
                Dst[0] := R;
                Dst[1] := G;
                Dst[2] := B;
                Dst[3] := A;
              end;
          else
            Data.SetPixel(X, Y, (A shl 24) or (R shl 16) or (G shl 8) or B);
          end;
          Inc(Src, 4);
          Inc(Dst, 4);
        end;
      end;
    finally
      Result.Unmap(Data);
    end;
  except
    on E: Exception do
    begin
      FreeAndNil(Result);
      AError := E.Message;
    end;
  end;
end;

// Hands ABitmap (owned from here on) to the waiting procedure on a later
// main-thread turn, outside the render loop, scaled to Width x Height first
// if it came back a different size (the whole texture was read).
procedure TSprite3DOffscreen.Deliver(const ABitmap: TBitmap; const AError: String);
var
  Alive: IAliveFlag;
  Callback: TSprite3DGrabProc;
  Me: TSprite3DOffscreen;
  Bitmap: TBitmap;
  ErrorText: String;
  W, H: Integer;
  Step: TThreadProcedure;
begin
  Alive := FAlive as IAliveFlag;
  Callback := FOnGrabbed;
  FOnGrabbed := nil;
  Me := Self;
  Bitmap := ABitmap;   // locals, not parameters, are captured
  ErrorText := AError;
  W := FWidth;
  H := FHeight;
  Step :=
    procedure
    var
      Image, Scaled: TBitmap;
      Error: String;
      Dest: TRectF;
    begin
      Image := Bitmap;
      Error := ErrorText;
      try
        if not Alive.IsAlive then
          Exit;   // the pass was freed; so, probably, is whoever asked
        Me.FBusy := False;
        Me.Enabled := False;

        if Assigned(Image) and ((Image.Width <> W) or (Image.Height <> H)) then
        begin
          Scaled := TBitmap.Create(W, H);
          try
            Dest := TRectF.Create(0, 0, Image.Width, Image.Height).FitInto(
              TRectF.Create(0, 0, W, H));
            if Scaled.Canvas.BeginScene then
            try
              Scaled.Canvas.Clear(TAlphaColors.Null);
              Scaled.Canvas.DrawBitmap(Image,
                TRectF.Create(0, 0, Image.Width, Image.Height), Dest, 1, False);
            finally
              Scaled.Canvas.EndScene;
            end;
            Image.Free;
            Image := Scaled;
          except
            Scaled.Free;
            raise;
          end;
        end;

        if Assigned(Callback) then
          Callback(Image, Error);
      finally
        Image.Free;
      end;
    end;
  // Qualified, in case a unit in the uses clause declares its own TThread
  System.Classes.TThread.ForceQueue(nil, Step);
end;

end.
