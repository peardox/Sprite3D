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
//** platform's library, so it works on every platform Gorilla renders with OpenGL: Windows
//** and Linux with desktop OpenGL, Android with OpenGL ES 3. If a project switches Gorilla
//** to its optional Vulkan backend, grabs fail with an error saying an OpenGL function is not
//** available.
//**
//** On macOS and iOS Gorilla renders through Metal, so there a grab is instead a screenshot of
//** the viewport as it is shown, from TGorillaViewport.MakeScreenshot, cropped about its
//** centre to the target's shape and scaled to the target's size. OnBeforeGrab and
//** OnAfterGrab are not called, so the framing is the screen's, and the image is opaque: it
//** shows the viewport's own background, and Backdrop and TransparentBackground are not
//** used.
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
  renders with OpenGL: Windows and Linux with desktop OpenGL, Android with
  OpenGL ES 3. If a project switches Gorilla to its optional Vulkan
  backend, grabs fail with an error saying an OpenGL function is not
  available.

  On macOS and iOS Gorilla renders through Metal, so there a grab is
  instead a screenshot of the viewport as it is shown, from
  TGorillaViewport.MakeScreenshot, cropped about its centre to the target's
  shape and scaled to the target's size. OnBeforeGrab and OnAfterGrab are
  not called, so the framing is the screen's, and the image is opaque: it
  shows the viewport's own background, and Backdrop and
  TransparentBackground are not used.

    TGorillaRenderPassController (Gorilla.Controller)
    `-- TSprite3DOffscreen   pre-pass into a Width x Height frame buffer
}

// Gorilla3D renders through Metal on macOS and iOS, where OpenGL read-back
// cannot work; grabs there are screenshots of the viewport instead
{$IF DEFINED(MACOS)}
  {$DEFINE S3D_SCREENSHOT_GRAB}
{$ENDIF}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Types3D, FMX.Graphics,
  Gorilla.Viewport, Gorilla.Context.Rendering, Gorilla.Controller,
  Sprite3DBackground;

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

  //** @abstract(Receives the result of TSprite3DOffscreen.GrabSizes.)
  //**
  //** Runs on the main thread, outside the render loop. The bitmaps belong to the
  //** TSprite3DOffscreen and are freed when the procedure returns; to keep them, copy them
  //** with @code(TBitmap.Assign) or save them.
  //**
  //** @param(AImages One bitmap for each size asked for, in the same order and of that size;
  //** empty if the grabs failed.)
  //**
  //** @param(AError Why the grabs failed; empty when AImages holds every size.)
  /// <summary>Receives the result of TSprite3DOffscreen.GrabSizes.</summary>
  /// <remarks>Runs on the main thread, outside the render loop. The bitmaps belong to the
  /// TSprite3DOffscreen and are freed when the procedure returns; to keep them, copy them with
  /// <c>TBitmap.Assign</c> or save them.</remarks>
  /// <param name="AImages">One bitmap for each size asked for, in the same order and of that
  /// size; empty if the grabs failed.</param>
  /// <param name="AError">Why the grabs failed; empty when AImages holds every size.</param>
  TSprite3DGrabSizesProc = reference to procedure(const AImages: TArray<TBitmap>;
    const AError: String);

  //** @abstract(A render pass that draws the viewport's scene off screen, one frame on
  //** request.)
  //**
  //** Create it, set Viewport to the TGorillaViewport to capture, then call Grab whenever an
  //** image is wanted. The pass uses the viewport's camera, lights and models as they are at
  //** the time of the frame. It takes over the inherited OnBeginRender, OnEndRender,
  //** BackgroundColor and Iterations, which must not be changed. All members are for the main
  //** thread only.
  //**
  //** With TransparentBackground, the default, the background comes out transparent, with
  //** soft edges and see-through materials partly transparent, by difference matting: the
  //** frame is drawn twice, over black and over white. Where the two differ, the background
  //** showed through, by as much as they differ; the over-black image is then the colour
  //** already multiplied by that alpha, which is how FMX bitmaps hold it. This needs nothing
  //** from the renderer's own alpha, which Gorilla's passes do not keep. Both drawings are
  //** made in the same frame, as two iterations of the pass, so an animated model is caught
  //** in the same pose in both; if the renderer does not take the new clear colour between
  //** iterations, the pass finds the drawings identical and, from then on, draws them in
  //** frames one after the other instead. The first grab also draws over 50% grey, which
  //** shows whether the renderer gamma-encodes its output after blending; if it does, the
  //** matting is done in linear light, so soft edges keep their true alpha either way.
  //**
  //** @seealso(TSprite3DGrabProc)
  /// <summary>A render pass that draws the viewport's scene off screen, one frame on
  /// request.</summary>
  /// <remarks>Create it, set Viewport to the TGorillaViewport to capture, then call Grab
  /// whenever an image is wanted. The pass uses the viewport's camera, lights and models as
  /// they are at the time of the frame. It takes over the inherited OnBeginRender,
  /// OnEndRender, BackgroundColor and Iterations, which must not be changed. All members are
  /// for the main thread only.
  /// <para>With TransparentBackground, the default, the background comes out transparent,
  /// with soft edges and see-through materials partly transparent, by difference matting: the
  /// frame is drawn twice, over black and over white. Where the two differ, the background
  /// showed through, by as much as they differ; the over-black image is then the colour
  /// already multiplied by that alpha, which is how FMX bitmaps hold it. This needs nothing
  /// from the renderer's own alpha, which Gorilla's passes do not keep. Both drawings are made
  /// in the same frame, as two iterations of the pass, so an animated model is caught in the
  /// same pose in both; if the renderer does not take the new clear colour between iterations,
  /// the pass finds the drawings identical and, from then on, draws them in frames one after
  /// the other instead. The first grab also draws over 50% grey, which shows whether the
  /// renderer gamma-encodes its output after blending; if it does, the matting is done in
  /// linear light, so soft edges keep their true alpha either way.</para></remarks>
  /// <seealso cref="TSprite3DGrabProc"/>
  TSprite3DOffscreen = class(TGorillaRenderPassController)
  private
    FWidth: Integer;
    FHeight: Integer;
    FTransparentBackground: Boolean;
    FOpaqueBackground: TAlphaColor;
    FBusy: Boolean;      // from Grab until the result has been delivered
    FPending: Boolean;   // waiting for the frame to read back
    FStage: Integer;     // how this grab draws; see Grab
    FColours: TArray<TAlphaColor>; // the background of each drawing
    FReads: TArray<TBytes>;        // each drawing, RGBA rows bottom first
    FReadWidth: Integer;
    FReadHeight: Integer;
    FIndex: Integer;       // the drawing the next frame is for, frame by frame
    FUseFrames: Boolean;   // drawings need a frame each: see HandleEndRender
    FTriedFrames: Boolean; // this grab fell back to a frame each
    FOutputKnown: Boolean; // FOutputEncoded has been measured
    FOutputEncoded: Boolean; // the renderer gamma-encodes after blending
    FBackdrop: TSprite3DBackgroundSpec;
    FOnGrabbed: TSprite3DGrabProc;
    FAlive: IInterface;  // shared with queued deliveries; see Destroy
    FPrepared: Boolean;  // OnBeforeGrab has run and OnAfterGrab has not
    FOnBeforeGrab: TSprite3DGrabSizeEvent;
    FOnAfterGrab: TNotifyEvent;
    procedure Restore;
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure ApplyTargetSize;
    procedure HandleBeginRender(ASender: TObject; const AContext: TContext3D;
      const ACount: Integer; const APass: TRenderPass);
    procedure HandleEndRender(ASender: TObject; const AContext: TContext3D;
      const ACount: Integer; const APass: TRenderPass);
    procedure Prepare;
    function ReadDrawing(const AIndex: Integer; out AError: String): Boolean;
    procedure StartNextFrame;
    procedure Fail(const AError: String);
    procedure CompleteMatte;
    procedure Finish(const APixels: TBytes; const AWidth, AHeight: Integer;
      const AError: String);
    function ReadPixels(out APixels: TBytes; out AWidth, AHeight: Integer;
      out AError: String): Boolean;
    procedure Deliver(const ABitmap: TBitmap; const AError: String);
    {$IFDEF S3D_SCREENSHOT_GRAB}
    procedure GrabScreenshot;
    {$ENDIF}
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
    //** default rendering @(order-independent transparency@), and makes the background
    //** transparent. Nothing is drawn until Viewport is set and Grab is called.
    //**
    //** @param(AOwner The owner, which frees the pass; the viewport is a good choice.)
    //**
    //** @param(AId Gorilla's identifier for the pass; each pass on one viewport needs its own.)
    /// <summary>Creates the pass, switched off, with a 256 by 256 target.</summary>
    /// <remarks>The pass renders before the main pass, into its own frame buffer, with
    /// Gorilla's default rendering (order-independent transparency), and makes the background
    /// transparent. Nothing is drawn until Viewport is set and Grab is called.</remarks>
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
    //** @abstract(Grabs one square image of each size in turn, then passes them all to
    //** AOnGrabbed.)
    //**
    //** Does what Grab does once for each size, one frame after another: Width and Height are
    //** set to the size, OnBeforeGrab and OnAfterGrab run around each grab, so the camera can
    //** be fitted to each, and the images are collected. Afterwards Width and Height are put
    //** back as they were. Returns at once and does not block; AOnGrabbed runs once on the
    //** main thread when every size is done, or as soon as one fails. Busy is True
    //** throughout, as each grab starts the next; do not call Grab or Cancel until
    //** AOnGrabbed has run.
    //**
    //** @param(ASizes The widths, which are also the heights, in pixels; each at least 1.)
    //**
    //** @param(AOnGrabbed The procedure to call with the images; must not be nil.)
    //**
    //** @returns(True if the grabs were started; False, with nothing started, if a grab is
    //** already under way, Viewport is not set, ASizes is empty or AOnGrabbed is nil.)
    /// <summary>Grabs one square image of each size in turn, then passes them all to
    /// AOnGrabbed.</summary>
    /// <remarks>Does what Grab does once for each size, one frame after another: Width and
    /// Height are set to the size, OnBeforeGrab and OnAfterGrab run around each grab, so the
    /// camera can be fitted to each, and the images are collected. Afterwards Width and Height
    /// are put back as they were. Returns at once and does not block; AOnGrabbed runs once on
    /// the main thread when every size is done, or as soon as one fails. Busy is True
    /// throughout, as each grab starts the next; do not call Grab or Cancel until AOnGrabbed
    /// has run.</remarks>
    /// <param name="ASizes">The widths, which are also the heights, in pixels; each at least
    /// 1.</param>
    /// <param name="AOnGrabbed">The procedure to call with the images; must not be
    /// nil.</param>
    /// <returns>True if the grabs were started; False, with nothing started, if a grab is
    /// already under way, Viewport is not set, ASizes is empty or AOnGrabbed is
    /// nil.</returns>
    function GrabSizes(const ASizes: array of Integer;
      const AOnGrabbed: TSprite3DGrabSizesProc): Boolean;
    //** @abstract(What grabs show behind the model when TransparentBackground is True.)
    //**
    //** None, the default, and Transparent leave the background transparent. Solid and
    //** Gradient fill it, after the matting, with the colour or with the gradient from
    //** GradientFrom to GradientTo in GradientDirection; soft edges blend into it as they
    //** would on screen. The checker settings are not used: the checker only stands for
    //** transparency on screen. Changes made while Busy apply from the next grab.
    /// <summary>What grabs show behind the model when TransparentBackground is
    /// True.</summary>
    /// <remarks>None, the default, and Transparent leave the background transparent. Solid
    /// and Gradient fill it, after the matting, with the colour or with the gradient from
    /// GradientFrom to GradientTo in GradientDirection; soft edges blend into it as they
    /// would on screen. The checker settings are not used: the checker only stands for
    /// transparency on screen. Changes made while Busy apply from the next grab.</remarks>
    property Backdrop: TSprite3DBackgroundSpec read FBackdrop write FBackdrop;
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
    //** @abstract(Whether grabs have a transparent background; True by default.)
    //**
    //** True draws each grab twice, over black and over white, and works out each pixel's
    //** alpha from the difference, as described for the class, so the background is fully
    //** transparent and soft edges are partly so. False draws it once over OpaqueBackground,
    //** with every pixel opaque.
    /// <summary>Whether grabs have a transparent background; True by default.</summary>
    /// <remarks>True draws each grab twice, over black and over white, and works out each
    /// pixel's alpha from the difference, as described for the class, so the background is
    /// fully transparent and soft edges are partly so. False draws it once over
    /// OpaqueBackground, with every pixel opaque.</remarks>
    property TransparentBackground: Boolean read FTransparentBackground
      write FTransparentBackground default True;
    //** @abstract(The background colour when TransparentBackground is False; black by
    //** default.)
    //**
    //** Its alpha is ignored: the background is always drawn opaque.
    /// <summary>The background colour when TransparentBackground is False; black by
    /// default.</summary>
    /// <remarks>Its alpha is ignored: the background is always drawn opaque.</remarks>
    property OpaqueBackground: TAlphaColor read FOpaqueBackground write FOpaqueBackground
      default TAlphaColors.Black;
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

const
  // How a grab draws
  STAGE_OPAQUE = 0;       // once, over OpaqueBackground
  STAGE_ITERATIONS = 1;   // every background in one frame, as iterations
  STAGE_FRAMES = 2;       // every background in a frame of its own

  // The backgrounds for matting: black and white, plus grey to learn
  // whether the output is gamma-encoded
  MATTE_GREY: TAlphaColor = $FF808080;
  // Grey reads back as 128 from linear output and about 186 from
  // sRGB-encoded output; this splits the two
  ENCODED_GREY_THRESHOLD = 157;

  // Drawings closer than this in every channel count as identical
  MATTE_TOLERANCE = 2;

var
  // sRGB-encoded byte to linear light, 0 to 1
  SRGBToLinear: array[0..255] of Single;

procedure InitSRGBTable;
var
  I: Integer;
  V: Single;
begin
  for I := 0 to 255 do
  begin
    V := I / 255;
    if V <= 0.04045 then
      SRGBToLinear[I] := V / 12.92
    else
      SRGBToLinear[I] := Power((V + 0.055) / 1.055, 2.4);
  end;
end;

// Linear light, 0 to 1, to sRGB-encoded, 0 to 1
function LinearToSRGB(const AValue: Single): Single;
begin
  if AValue <= 0 then
    Result := 0
  else if AValue >= 1 then
    Result := 1
  else if AValue <= 0.0031308 then
    Result := AValue * 12.92
  else
    Result := 1.055 * Power(AValue, 1 / 2.4) - 0.055;
end;

// Whether two drawings differ anywhere in colour
function DrawingsDiffer(const ADark, ALight: TBytes): Boolean;
var
  I: Integer;
begin
  Result := False;
  I := 0;
  while I < Length(ADark) do
  begin
    if (Abs(ALight[I] - ADark[I]) > MATTE_TOLERANCE) or
      (Abs(ALight[I + 1] - ADark[I + 1]) > MATTE_TOLERANCE) or
      (Abs(ALight[I + 2] - ADark[I + 2]) > MATTE_TOLERANCE) then
      Exit(True);
    Inc(I, 4);
  end;
end;

// Whether the renderer gamma-encodes after blending, from the drawing over
// grey: where the background shows fully (black over black, white over
// white), grey reads back as 128 if not and about 186 if so. Returns False
// if no pixel shows the background, so it cannot tell.
function MeasureEncoding(const ADark, ALight, AGrey: TBytes;
  out AEncoded: Boolean): Boolean;
var
  I, Count: Integer;
  Values: array[0..255] of Integer;
  Half, Seen: Integer;
begin
  FillChar(Values, SizeOf(Values), 0);
  Count := 0;
  I := 0;
  while I < Length(ADark) do
  begin
    if (ADark[I] <= 1) and (ADark[I + 1] <= 1) and (ADark[I + 2] <= 1) and
      (ALight[I] >= 254) and (ALight[I + 1] >= 254) and (ALight[I + 2] >= 254) then
    begin
      Inc(Values[AGrey[I]]);
      Inc(Count);
    end;
    Inc(I, 4);
  end;
  Result := Count > 0;
  if not Result then
    Exit;
  // The median grey value, so stray pixels cannot sway it
  Half := Count div 2;
  Seen := 0;
  for I := 0 to 255 do
  begin
    Inc(Seen, Values[I]);
    if Seen > Half then
    begin
      AEncoded := I >= ENCODED_GREY_THRESHOLD;
      Exit;
    end;
  end;
  AEncoded := False;
end;

// Difference matting. ADark and ALight are the same drawing over black and
// over white, RGBA. A pixel with alpha a and colour c blends to c*a over
// black and c*a + (1 - a) over white, so their difference is 1 - a, and the
// over-black value is the colour already multiplied by alpha. The three
// channels' differences are averaged, which evens out rounding. If the
// renderer blends in linear light and gamma-encodes afterwards (AEncoded),
// the sums only hold in linear light, so the values are decoded first and
// the colour encoded again before it is multiplied by alpha. Drawings that
// are identical give alpha 255 everywhere: no background showed.
function BuildMatte(const ADark, ALight: TBytes; const AEncoded: Boolean): TBytes;
var
  I, K, A: Integer;
  AF, C: Single;
begin
  SetLength(Result, Length(ADark));
  I := 0;
  while I < Length(ADark) do
  begin
    if not AEncoded then
    begin
      A := EnsureRange(255 - ((ALight[I] - ADark[I]) + (ALight[I + 1] - ADark[I + 1]) +
        (ALight[I + 2] - ADark[I + 2]) + 1) div 3, 0, 255);
      // Premultiplied colour can never exceed its alpha
      for K := 0 to 2 do
        Result[I + K] := Min(ADark[I + K], A);
    end
    else
    begin
      AF := 1 - ((SRGBToLinear[ALight[I]] - SRGBToLinear[ADark[I]]) +
        (SRGBToLinear[ALight[I + 1]] - SRGBToLinear[ADark[I + 1]]) +
        (SRGBToLinear[ALight[I + 2]] - SRGBToLinear[ADark[I + 2]])) / 3;
      AF := EnsureRange(AF, 0.0, 1.0);
      A := Round(AF * 255);
      for K := 0 to 2 do
        if A = 0 then
          Result[I + K] := 0
        else
        begin
          C := LinearToSRGB(SRGBToLinear[ADark[I + K]] / AF);
          Result[I + K] := Min(Round(C * A), A);
        end;
    end;
    Result[I + 3] := A;
    Inc(I, 4);
  end;
end;

// Fills the transparent parts of a matted image, RGBA rows bottom first and
// premultiplied, with a solid colour or a gradient in its direction: each
// pixel becomes itself plus the backdrop times what it lets through,
// 1 - alpha, so soft edges blend into the backdrop. Every pixel ends opaque.
procedure FillBackdrop(var APixels: TBytes; const AWidth, AHeight: Integer;
  const ABackdrop: TSprite3DBackgroundSpec);
var
  X, Y, I, Rest: Integer;
  Fill: TAlphaColorRec;
begin
  if ABackdrop.Kind in [TSprite3DBackgroundKind.None,
    TSprite3DBackgroundKind.Transparent] then
    Exit;
  Fill := TAlphaColorRec(ABackdrop.Colour);
  for Y := 0 to AHeight - 1 do
  begin
    I := Y * AWidth * 4;
    for X := 0 to AWidth - 1 do
    begin
      // Rows are stored bottom first; the gradient is measured from the top
      // left, at the pixel's centre
      if ABackdrop.Kind = TSprite3DBackgroundKind.Gradient then
        Fill := TAlphaColorRec(ABackdrop.GradientAtPoint(X + 0.5, AHeight - Y - 0.5,
          AWidth, AHeight));
      Rest := 255 - APixels[I + 3];
      if Rest > 0 then
      begin
        APixels[I] := Min(255, APixels[I] + (Fill.R * Rest + 127) div 255);
        APixels[I + 1] := Min(255, APixels[I + 1] + (Fill.G * Rest + 127) div 255);
        APixels[I + 2] := Min(255, APixels[I + 2] + (Fill.B * Rest + 127) div 255);
        APixels[I + 3] := 255;
      end;
      Inc(I, 4);
    end;
  end;
end;

// RGBA pixels, bottom row first and already premultiplied, as a new FMX
// bitmap, in whichever byte order the platform's bitmaps use
function PixelsToBitmap(const APixels: TBytes; const AWidth,
  AHeight: Integer): TBitmap;
var
  Data: TBitmapData;
  X, Y: Integer;
  Src, Dst: PByte;
begin
  Result := TBitmap.Create(AWidth, AHeight);
  try
    if not Result.Map(TMapAccess.Write, Data) then
      raise EInvalidOperation.Create('Cannot write to the grab bitmap.');
    try
      for Y := 0 to AHeight - 1 do
      begin
        Src := @APixels[(AHeight - 1 - Y) * AWidth * 4];
        Dst := Data.GetScanline(Y);
        for X := 0 to AWidth - 1 do
        begin
          case Data.PixelFormat of
            TPixelFormat.BGRA:
              begin
                Dst[0] := Src[2];
                Dst[1] := Src[1];
                Dst[2] := Src[0];
                Dst[3] := Src[3];
              end;
            TPixelFormat.RGBA:
              begin
                Dst[0] := Src[0];
                Dst[1] := Src[1];
                Dst[2] := Src[2];
                Dst[3] := Src[3];
              end;
          else
            Data.SetPixel(X, Y, (Cardinal(Src[3]) shl 24) or (Cardinal(Src[0]) shl 16) or
              (Cardinal(Src[1]) shl 8) or Src[2]);
          end;
          Inc(Src, 4);
          Inc(Dst, 4);
        end;
      end;
    finally
      Result.Unmap(Data);
    end;
  except
    Result.Free;
    raise;
  end;
end;

constructor TSprite3DOffscreen.Create(AOwner: TComponent; const AId: String);
begin
  inherited Create(AOwner, AId);
  FAlive := TAliveFlag.Create;
  FWidth := DEFAULT_OFFSCREEN_WIDTH;
  FHeight := DEFAULT_OFFSCREEN_HEIGHT;
  FTransparentBackground := True;
  FOpaqueBackground := TAlphaColors.Black;
  FBackdrop := TSprite3DBackgroundSpec.Default;

  Enabled := False;   // only on for the frame a grab needs
  _Type := TRenderPassType.Pre;
  Method := TRenderPassMethod.RenderListToFBO;
  RenderProc := TRenderPassRenderingProc.DefaultRendering;
  OverwriteColor := True;
  BackgroundColor := TAlphaColors.Black;
  ApplyTargetSize;
  OnBeginRender := HandleBeginRender;
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
  {$IFDEF S3D_SCREENSHOT_GRAB}
  GrabScreenshot;   // reports through Deliver, as the render does
  Exit;
  {$ENDIF}
  ApplyTargetSize;   // pick up any size change made while busy
  FReads := nil;
  FTriedFrames := False;
  // How the grab draws: see HandleEndRender
  if not FTransparentBackground then
  begin
    FStage := STAGE_OPAQUE;
    FColours := [TAlphaColor(FOpaqueBackground or $FF000000)];
  end
  else
  begin
    FColours := [TAlphaColors.Black, TAlphaColors.White];
    if not FOutputKnown then
      FColours := FColours + [MATTE_GREY];
    if FUseFrames then
      FStage := STAGE_FRAMES
    else
      FStage := STAGE_ITERATIONS;
  end;
  SetLength(FReads, Length(FColours));
  FIndex := 0;
  BackgroundColor := FColours[0];
  if FStage = STAGE_ITERATIONS then
    Iterations := Length(FColours)   // HandleBeginRender sets each colour
  else
    Iterations := 1;
  Prepare;
  FPending := True;
  Enabled := True;
  Viewport.Invalidate;
end;

{$IFDEF S3D_SCREENSHOT_GRAB}
// Metal: the viewport as last shown, cropped about its centre to the
// target's shape and drawn at the target's size, then handed to Deliver,
// which reports it on the main thread and frees it. Any failure is reported
// the same way, as an error.
procedure TSprite3DOffscreen.GrabScreenshot;
var
  Shot, Image: TBitmap;
  Source: TRectF;
  W, H: Single;
begin
  Shot := nil;
  Image := nil;
  try
    try
      Shot := Viewport.MakeScreenshot;
      if (Shot = nil) or (Shot.Width = 0) or (Shot.Height = 0) then
        raise Exception.Create('The view gave no image.');
      // The largest rectangle of the target's shape, centred
      W := Shot.Width;
      H := Shot.Height;
      if W / H > FWidth / FHeight then
        W := H * FWidth / FHeight
      else
        H := W * FHeight / FWidth;
      Source := TRectF.Create(0, 0, W, H);
      Source.Offset((Shot.Width - W) / 2, (Shot.Height - H) / 2);
      Image := TBitmap.Create(FWidth, FHeight);
      if Image.Canvas.BeginScene then
      try
        Image.Canvas.Clear(TAlphaColors.Null);
        Image.Canvas.DrawBitmap(Shot, Source, TRectF.Create(0, 0, FWidth, FHeight), 1, False);
      finally
        Image.Canvas.EndScene;
      end;
    finally
      Shot.Free;
    end;
  except
    on E: Exception do
    begin
      FreeAndNil(Image);
      Deliver(nil, 'The view could not be captured: ' + E.Message);
      Exit;
    end;
  end;
  Deliver(Image, String.Empty);
end;
{$ENDIF}

// Lets the owner fit the scene to the target; Restore puts it back
procedure TSprite3DOffscreen.Prepare;
begin
  if Assigned(FOnBeforeGrab) then
  begin
    FPrepared := True;
    FOnBeforeGrab(Self, FWidth, FHeight);
  end;
end;

// One GrabSizes run: grabs each size in turn from the previous grab's
// procedure, keeping copies, and frees itself when it has reported
type
  TGrabSizesJob = class
  private
    FOffscreen: TSprite3DOffscreen;
    FSizes: TArray<Integer>;
    FIndex: Integer;
    FImages: TArray<TBitmap>;
    FOnGrabbed: TSprite3DGrabSizesProc;
    FOldWidth: Integer;
    FOldHeight: Integer;
    function GrabNext: Boolean;
    procedure Finish(const AError: String);
  public
    constructor Create(const AOffscreen: TSprite3DOffscreen;
      const ASizes: array of Integer; const AOnGrabbed: TSprite3DGrabSizesProc);
    destructor Destroy; override;
  end;

constructor TGrabSizesJob.Create(const AOffscreen: TSprite3DOffscreen;
  const ASizes: array of Integer; const AOnGrabbed: TSprite3DGrabSizesProc);
var
  I: Integer;
begin
  inherited Create;
  FOffscreen := AOffscreen;
  SetLength(FSizes, Length(ASizes));
  for I := 0 to High(ASizes) do
    FSizes[I] := ASizes[I];
  FOnGrabbed := AOnGrabbed;
  FOldWidth := AOffscreen.Width;
  FOldHeight := AOffscreen.Height;
end;

destructor TGrabSizesJob.Destroy;
var
  Image: TBitmap;
begin
  for Image in FImages do
    Image.Free;
  inherited;
end;

// Starts the grab for FSizes[FIndex]; False if it could not start
function TGrabSizesJob.GrabNext: Boolean;
var
  Job: TGrabSizesJob;
begin
  Job := Self;
  FOffscreen.Width := FSizes[FIndex];
  FOffscreen.Height := FSizes[FIndex];
  Result := FOffscreen.Grab(
    procedure(const ABitmap: TBitmap; const AError: String)
    var
      Kept: TBitmap;
    begin
      if not Assigned(ABitmap) then
      begin
        Job.Finish(AError);
        Exit;
      end;
      // The grab's bitmap is freed when this returns, so keep a copy
      Kept := TBitmap.Create;
      Kept.Assign(ABitmap);
      Job.FImages := Job.FImages + [Kept];
      Inc(Job.FIndex);
      if Job.FIndex > High(Job.FSizes) then
        Job.Finish(String.Empty)
      else if not Job.GrabNext then
        Job.Finish('A grab could not be started.');
    end);
end;

// Puts the size back, reports, and frees the job and its images
procedure TGrabSizesJob.Finish(const AError: String);
var
  Images: TArray<TBitmap>;
begin
  FOffscreen.Width := FOldWidth;
  FOffscreen.Height := FOldHeight;
  try
    if AError = String.Empty then
      Images := FImages
    else
      Images := nil;
    FOnGrabbed(Images, AError);
  finally
    Free;
  end;
end;

function TSprite3DOffscreen.GrabSizes(const ASizes: array of Integer;
  const AOnGrabbed: TSprite3DGrabSizesProc): Boolean;
var
  Job: TGrabSizesJob;
  Size: Integer;
begin
  Result := (not FBusy) and Assigned(Viewport) and (Length(ASizes) > 0) and
    Assigned(AOnGrabbed);
  if not Result then
    Exit;
  for Size in ASizes do
    if Size < 1 then
      Exit(False);
  Job := TGrabSizesJob.Create(Self, ASizes, AOnGrabbed);
  Result := Job.GrabNext;
  if not Result then
  begin
    // Nothing was started: undo quietly, without calling back
    Width := Job.FOldWidth;
    Height := Job.FOldHeight;
    Job.Free;
  end;
end;

procedure TSprite3DOffscreen.Cancel;
begin
  FPending := False;
  FBusy := False;
  FReads := nil;
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

// In the same-frame matting, each iteration is cleared to its own colour
procedure TSprite3DOffscreen.HandleBeginRender(ASender: TObject;
  const AContext: TContext3D; const ACount: Integer; const APass: TRenderPass);
begin
  if FPending and (FStage = STAGE_ITERATIONS) and (ACount <= High(FColours)) then
    BackgroundColor := FColours[ACount];
end;

// Still inside Gorilla's render loop with its context current: read the
// pixels now, and leave everything else to Finish's queued delivery. The
// owner's changes are put back (Restore) before the main pass draws the
// frame, so the screen never shows the grab's framing.
procedure TSprite3DOffscreen.HandleEndRender(ASender: TObject;
  const AContext: TContext3D; const ACount: Integer; const APass: TRenderPass);
var
  Error: String;
  Pixels: TBytes;
begin
  if not FPending then
    Exit;

  case FStage of
    STAGE_OPAQUE:
      if ACount = 0 then
      begin
        if not ReadDrawing(0, Error) then
        begin
          Fail(Error);
          Exit;
        end;
        FPending := False;
        Restore;
        Pixels := FReads[0];
        for var I := 0 to FReadWidth * FReadHeight - 1 do
          Pixels[I * 4 + 3] := 255;   // the renderer's alpha is not kept
        Finish(Pixels, FReadWidth, FReadHeight, String.Empty);
      end;

    STAGE_ITERATIONS:
      if ACount <= High(FColours) then
      begin
        if not ReadDrawing(ACount, Error) then
          Fail(Error)
        else if ACount = High(FColours) then
        begin
          if DrawingsDiffer(FReads[0], FReads[1]) then
            CompleteMatte
          else
          begin
            // The drawings came out alike: the clear colour did not change
            // between iterations. Keep the first, over black, and draw the
            // others in frames of their own.
            FTriedFrames := True;
            FIndex := 1;
            StartNextFrame;
          end;
        end;
      end;

    STAGE_FRAMES:
      if ACount = 0 then
      begin
        if not ReadDrawing(FIndex, Error) then
        begin
          Fail(Error);
          Exit;
        end;
        Inc(FIndex);
        if FIndex <= High(FColours) then
          StartNextFrame
        else
        begin
          // A frame each worked where iterations did not: keep to it
          if FTriedFrames and DrawingsDiffer(FReads[0], FReads[1]) then
            FUseFrames := True;
          CompleteMatte;
        end;
      end;
  end;
end;

// Reads the drawing just made into FReads[AIndex]; the first sets the size
// the others must match
function TSprite3DOffscreen.ReadDrawing(const AIndex: Integer;
  out AError: String): Boolean;
var
  Pixels: TBytes;
  W, H: Integer;
begin
  Result := ReadPixels(Pixels, W, H, AError);
  if not Result then
    Exit;
  if AIndex = 0 then
  begin
    FReadWidth := W;
    FReadHeight := H;
  end
  else if (W <> FReadWidth) or (H <> FReadHeight) then
  begin
    AError := 'The drawings of the grab differ in size.';
    Exit(False);
  end;
  FReads[AIndex] := Pixels;
end;

// Ends the grab with an error
procedure TSprite3DOffscreen.Fail(const AError: String);
begin
  FPending := False;
  Restore;
  Finish(nil, 0, 0, AError);
end;

// Every background has been drawn: learn the output's encoding if this grab
// drew over grey, then build the transparent image
procedure TSprite3DOffscreen.CompleteMatte;
var
  Encoded: Boolean;
  Matte: TBytes;
begin
  FPending := False;
  Restore;
  if (not FOutputKnown) and (Length(FReads) > 2) and
    MeasureEncoding(FReads[0], FReads[1], FReads[2], Encoded) then
  begin
    FOutputEncoded := Encoded;
    FOutputKnown := True;
  end;
  Matte := BuildMatte(FReads[0], FReads[1], FOutputEncoded);
  FillBackdrop(Matte, FReadWidth, FReadHeight, FBackdrop);
  Finish(Matte, FReadWidth, FReadHeight, String.Empty);
end;

// Ends this frame's part of the grab and has a later frame draw over the
// next background. The scene is put back before the main pass draws this
// frame, then set up again for the target, outside the render loop, before
// the next read; a frame drawn before then reads nothing, as nothing is
// pending. The pass is left on: switching it off from inside its own render
// is not safe.
procedure TSprite3DOffscreen.StartNextFrame;
var
  Alive: IAliveFlag;
  Me: TSprite3DOffscreen;
  Step: TThreadProcedure;
begin
  FPending := False;
  Restore;
  FStage := STAGE_FRAMES;
  Iterations := 1;
  BackgroundColor := FColours[FIndex];
  Alive := FAlive as IAliveFlag;
  Me := Self;
  Step :=
    procedure
    begin
      if not Alive.IsAlive or not Me.FBusy then
        Exit;   // freed or cancelled meanwhile
      Me.Prepare;
      Me.FPending := True;
      Me.Viewport.Invalidate;
    end;
  System.Classes.TThread.ForceQueue(nil, Step);
end;

// Turns the read pixels, if any, into the bitmap for the waiting procedure
procedure TSprite3DOffscreen.Finish(const APixels: TBytes; const AWidth,
  AHeight: Integer; const AError: String);
var
  Bitmap: TBitmap;
  Error: String;
begin
  FReads := nil;
  Bitmap := nil;
  Error := AError;
  if (Error = String.Empty) and (Length(APixels) > 0) then
    try
      Bitmap := PixelsToBitmap(APixels, AWidth, AHeight);
    except
      on E: Exception do
        Error := E.Message;
    end
  else if Error = String.Empty then
    Error := 'Nothing was read from the off-screen target.';
  Deliver(Bitmap, Error);
end;

// Reads the area this pass drew in its output texture as RGBA bytes, bottom
// row first, with its size. Must run with the GL context current, i.e.
// inside the render. Returns False, with AError set, if it cannot.
function TSprite3DOffscreen.ReadPixels(out APixels: TBytes; out AWidth,
  AHeight: Integer; out AError: String): Boolean;
var
  GL: TGLFuncs;
  Missing: String;
  Tex: TTexture;
  TexW, TexH, I: Integer;
  ReadX, ReadY, ReadW, ReadH: Integer;
  GLView: array[0..3] of TGLint;
  Fbo: TGLuint;
  OldRead, OldPack: TGLint;
  Status, GLErr: TGLenum;
  Pixels: TBytes;
  Floats: TArray<Single>;
  F: Single;
begin
  Result := False;
  APixels := nil;
  AWidth := 0;
  AHeight := 0;
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

  APixels := Pixels;
  AWidth := ReadW;
  AHeight := ReadH;
  Result := True;
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

initialization
  InitSRGBTable;

end.
