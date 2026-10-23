//** @abstract(Grabs every frame of a model's animation, or of a turn of the camera round it,
//** one off-screen grab after another.)
//**
//** A frame source says how many frames there are, how long they last together, and how to
//** show frame N. TSprite3DAnimationFrames shows the frames of one of a Gorilla model's
//** animations, from the first to the last; TSprite3DTurntableFrames turns a
//** TSprite3DCamera once round the model, for a model or a moment with no animation to play.
//**
//** TSprite3DFrameCapture then shows each frame in turn and grabs it with a
//** TSprite3DOffscreen, starting the next grab from inside the previous one's procedure, as
//** TSprite3DOffscreen.GrabSizes does. The grabs are copied into TSprite3DImage records
//** straight away, so the whole run holds no FMX bitmaps, and the caller gets them all at the
//** end in one procedure, ready for Sprite3DSpriteSheet to lay out and save.
//**
//** The capture does not frame the model; the owner of the camera sets one framing for the
//** whole run before starting it, so every frame is drawn at the same scale, and puts its own
//** back afterwards.
//**
//** A newly started animation can take a few drawn frames to show its first pose: Gorilla
//** switches clips, uploads the baked poses and settles the skeleton over the next frames
//** drawn, and until then the model can be in the pose it had before, or at the wrong height.
//** So the first frame is grabbed WarmUpFrames times, DEFAULT_WARM_UP_FRAMES unless changed,
//** and those grabs are thrown away before the real one.
//**
//** TSprite3DAnimationPlayer plays, pauses and steps an animation on screen, one export frame
//** at a time, holding each pose as a capture would. SetAnimationPaused pauses an animation's
//** clock the same way on every Delphi version.
//**
//** Everything here is for the main thread. A capture runs over many frames of the main loop;
//** the application stays responsive meanwhile, and should not start other grabs, load
//** another model or change the animation until the capture reports.
//**
//** @preformatted(
//** TSprite3DFrameSource @(abstract@)
//** |-- TSprite3DAnimationFrames   a TGorillaAnimation, frame by frame
//** `-- TSprite3DTurntableFrames   the camera's azimuth, once round
//**
//** TSprite3DFrameCapture   ShowFrame @(N@) -> TSprite3DOffscreen.Grab -> copy -> N + 1
//** )
unit Sprite3DAnimCapture;

{
  Grabs every frame of a model's animation, or of a turn of the camera round
  it, one off-screen grab after another.

  A frame source says how many frames there are, how long they last
  together, and how to show frame N. TSprite3DAnimationFrames shows the
  frames of one of a Gorilla model's animations, from the first to the last;
  TSprite3DTurntableFrames turns a TSprite3DCamera once round the model, for
  a model or a moment with no animation to play.

  TSprite3DFrameCapture then shows each frame in turn and grabs it with a
  TSprite3DOffscreen, starting the next grab from inside the previous one's
  procedure, as TSprite3DOffscreen.GrabSizes does. The grabs are copied into
  TSprite3DImage records straight away, so the whole run holds no FMX
  bitmaps, and the caller gets them all at the end in one procedure, ready
  for Sprite3DSpriteSheet to lay out and save.

  The capture does not frame the model; the owner of the camera sets one
  framing for the whole run before starting it, so every frame is drawn at
  the same scale, and puts its own back afterwards.

  A newly started animation can take a few drawn frames to show its first
  pose: Gorilla switches clips, uploads the baked poses and settles the
  skeleton over the next frames drawn, and until then the model can be in
  the pose it had before, or at the wrong height. So the first frame is
  grabbed WarmUpFrames times, DEFAULT_WARM_UP_FRAMES unless changed, and
  those grabs are thrown away before the real one.

  TSprite3DAnimationPlayer plays, pauses and steps an animation on screen,
  one export frame at a time, holding each pose as a capture would.
  SetAnimationPaused pauses an animation's clock the same way on every
  Delphi version.

  Everything here is for the main thread. A capture runs over many frames of
  the main loop; the application stays responsive meanwhile, and should not
  start other grabs, load another model or change the animation until the
  capture reports.

    TSprite3DFrameSource (abstract)
    |-- TSprite3DAnimationFrames   a TGorillaAnimation, frame by frame
    `-- TSprite3DTurntableFrames   the camera's azimuth, once round

    TSprite3DFrameCapture   ShowFrame (N) -> TSprite3DOffscreen.Grab -> copy -> N + 1
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math.Vectors, System.Diagnostics,
  FMX.Graphics, Gorilla.Model, Gorilla.Animation,
  Sprite3DCamera, Sprite3DOffscreen, Sprite3DSpriteSheet;

type
  //** @abstract(Reports a finished capture: every frame, in order, or an error.)
  //**
  //** @param(AFrames The frames, first to last, all the grab's size; empty if AError is set.
  //** They belong to the procedure.)
  //**
  //** @param(AError Empty on success; otherwise why the capture stopped.)
  /// <summary>Reports a finished capture: every frame, in order, or an error.</summary>
  /// <param name="AFrames">The frames, first to last, all the grab's size; empty if AError is
  /// set. They belong to the procedure.</param>
  /// <param name="AError">Empty on success; otherwise why the capture stopped.</param>
  TSprite3DFramesProc = reference to procedure(const AFrames: TArray<TSprite3DImage>;
    const AError: String);

  //** @abstract(Reports progress after each frame is grabbed.)
  //**
  //** @param(ADone How many frames have been grabbed so far.)
  //**
  //** @param(ATotal How many frames there are in all.)
  /// <summary>Reports progress after each frame is grabbed.</summary>
  /// <param name="ADone">How many frames have been grabbed so far.</param>
  /// <param name="ATotal">How many frames there are in all.</param>
  TSprite3DCaptureProgress = reference to procedure(const ADone, ATotal: Integer);

const
  //** @abstract(How many grabs of the first frame TSprite3DFrameCapture throws away before
  //** keeping one, by default.)
  //**
  //** Each is one drawn frame, enough for Gorilla to have switched to the animation and
  //** shown its first pose.
  /// <summary>How many grabs of the first frame TSprite3DFrameCapture throws away before
  /// keeping one, by default.</summary>
  /// <remarks>Each is one drawn frame, enough for Gorilla to have switched to the animation
  /// and shown its first pose.</remarks>
  DEFAULT_WARM_UP_FRAMES = 3;

type
  //** @abstract(Something that can be shown one frame at a time for capture.)
  //**
  //** Call Start once, then ShowFrame for any frame from 0 to FrameCount - 1 in any order,
  //** then Finish once. Between Start and Finish the scene is the source's to change.
  /// <summary>Something that can be shown one frame at a time for capture.</summary>
  /// <remarks>Call Start once, then ShowFrame for any frame from 0 to FrameCount - 1 in any
  /// order, then Finish once. Between Start and Finish the scene is the source's to
  /// change.</remarks>
  TSprite3DFrameSource = class abstract
  public
    //** @abstract(How many frames there are; at least 1.)
    //**
    //** @returns(The frame count.)
    /// <summary>How many frames there are; at least 1.</summary>
    /// <returns>The frame count.</returns>
    function FrameCount: Integer; virtual; abstract;
    //** @abstract(How long all the frames last together, in seconds, when played.)
    //**
    //** @returns(The length of one pass through every frame; more than 0.)
    /// <summary>How long all the frames last together, in seconds, when played.</summary>
    /// <returns>The length of one pass through every frame; more than 0.</returns>
    function Duration: Single; virtual; abstract;
    //** @abstract(Takes over the scene for capture; called once, before any ShowFrame.)
    /// <summary>Takes over the scene for capture; called once, before any
    /// ShowFrame.</summary>
    procedure Start; virtual;
    //** @abstract(Puts the scene in the state of one frame.)
    //**
    //** @param(AIndex The frame, from 0 to FrameCount - 1.)
    /// <summary>Puts the scene in the state of one frame.</summary>
    /// <param name="AIndex">The frame, from 0 to FrameCount - 1.</param>
    procedure ShowFrame(const AIndex: Integer); virtual; abstract;
    //** @abstract(Hands the scene back; called once, after the last ShowFrame.)
    //**
    //** An animation is left playing as it was chosen; the camera is left at the angle it
    //** had before Start.
    /// <summary>Hands the scene back; called once, after the last ShowFrame.</summary>
    /// <remarks>An animation is left playing as it was chosen; the camera is left at the angle
    /// it had before Start.</remarks>
    procedure Finish; virtual;
    //** @abstract(How long each frame shows when played, in hundredths of a second, as GIF
    //** counts it.)
    //**
    //** @returns(Duration / FrameCount, rounded, at least 1.)
    /// <summary>How long each frame shows when played, in hundredths of a second, as GIF counts
    /// it.</summary>
    /// <returns>Duration / FrameCount, rounded, at least 1.</returns>
    function FrameDelay: Integer;
  end;

  //** @abstract(One cycle of a Gorilla model's animation, resampled at a chosen frame rate.)
  //**
  //** The animation's length D seconds is split into N equal steps, where N is D times the
  //** chosen rate, rounded, and at least 1. Frame I shows the pose at time I * D / N, so frame
  //** 0 is the first pose and frame N - 1 is one step before the end. Played at N frames per D
  //** seconds the frames take exactly as long as the animation, and since the time after the
  //** last frame is D, which is where a cyclical animation is back at its first pose, the
  //** frames loop without a jump or a repeated frame. The rate actually played, N / D, is the
  //** chosen rate adjusted by at most half a frame per cycle so the cycle stays whole; 8 frames
  //** a second on a 1.3-second walk gives 10 frames of 0.13 seconds.
  //**
  //** Sprite3D loads models with vertex caching, so Gorilla has already baked the animation
  //** into @code(FrameCount) poses at its own rate (60 a second on desktop, 24 on some mobile
  //** platforms). Each output time is mapped onto that grid and the nearest baked pose is
  //** shown with @code(SetFixedCacheFrame), whatever the animation clock is doing; on desktop
  //** that is within 1/120 of a second of the exact time. The poses themselves are
  //** interpolated between the file's keyframes when Gorilla bakes them; the images are never
  //** blended, which would leave ghosts in a sprite. At a rate above the baked rate some poses
  //** repeat.
  //**
  //** An animation without baked poses is instead posed by seeking its skeleton to each exact
  //** time, which interpolates the keyframes there. On Delphi 13 and later, where Gorilla's
  //** render clock holds the skeleton, the pose is evaluated on the next drawn frame, so it
  //** can lag the requested time by one display frame.
  //**
  //** Animations that do not cycle are not treated differently yet: their last pose is left
  //** out, as for a cycle.
  //**
  //** Start makes the animation the model's current one, without blending, and starts it.
  /// <summary>One cycle of a Gorilla model's animation, resampled at a chosen frame
  /// rate.</summary>
  /// <remarks><para>The animation's length D seconds is split into N equal steps, where N is D
  /// times the chosen rate, rounded, and at least 1. Frame I shows the pose at time I * D / N,
  /// so frame 0 is the first pose and frame N - 1 is one step before the end. Played at N
  /// frames per D seconds the frames take exactly as long as the animation, and since the time
  /// after the last frame is D, which is where a cyclical animation is back at its first pose,
  /// the frames loop without a jump or a repeated frame. The rate actually played, N / D, is
  /// the chosen rate adjusted by at most half a frame per cycle so the cycle stays whole; 8
  /// frames a second on a 1.3-second walk gives 10 frames of 0.13 seconds.</para>
  /// <para>Sprite3D loads models with vertex caching, so Gorilla has already baked the
  /// animation into <c>FrameCount</c> poses at its own rate (60 a second on desktop, 24 on
  /// some mobile platforms). Each output time is mapped onto that grid and the nearest baked
  /// pose is shown with <c>SetFixedCacheFrame</c>, whatever the animation clock is doing; on
  /// desktop that is within 1/120 of a second of the exact time. The poses themselves are
  /// interpolated between the file's keyframes when Gorilla bakes them; the images are never
  /// blended, which would leave ghosts in a sprite. At a rate above the baked rate some poses
  /// repeat.</para>
  /// <para>An animation without baked poses is instead posed by seeking its skeleton to each
  /// exact time, which interpolates the keyframes there. On Delphi 13 and later, where
  /// Gorilla's render clock holds the skeleton, the pose is evaluated on the next drawn frame,
  /// so it can lag the requested time by one display frame.</para>
  /// <para>Animations that do not cycle are not treated differently yet: their last pose is
  /// left out, as for a cycle.</para>
  /// <para>Start makes the animation the model's current one, without blending, and starts
  /// it.</para></remarks>
  TSprite3DAnimationFrames = class(TSprite3DFrameSource)
  private
    FModel: TGorillaModel;
    FAnimation: TGorillaAnimation;
    FCached: Boolean;
    FCachedFrames: Integer;
    FFrames: Integer;
    FDuration: Single;
    procedure SeekTo(const ATime: Single);
  public
    //** @abstract(Prepares to capture one cycle of AAnimation of AModel at AFrameRate, or in
    //** AFrameCount frames.)
    //**
    //** @param(AModel The model the animation belongs to; it must outlive this object.)
    //**
    //** @param(AAnimation One of AModel's animations; it must outlive this object.)
    //**
    //** @param(AFrameRate The frames per second wanted; at least 1.)
    //**
    //** @param(AFrameCount The number of frames wanted, in place of what AFrameRate gives,
    //** such as one chosen by hand; 0, the default, for what AFrameRate gives.)
    //**
    //** @raises(EArgumentException If AModel or AAnimation is nil, or AFrameRate is less
    //** than 1.)
    /// <summary>Prepares to capture one cycle of AAnimation of AModel at AFrameRate, or in
    /// AFrameCount frames.</summary>
    /// <param name="AModel">The model the animation belongs to; it must outlive this
    /// object.</param>
    /// <param name="AAnimation">One of AModel's animations; it must outlive this
    /// object.</param>
    /// <param name="AFrameRate">The frames per second wanted; at least 1.</param>
    /// <param name="AFrameCount">The number of frames wanted, in place of what AFrameRate
    /// gives, such as one chosen by hand; 0, the default, for what AFrameRate gives.</param>
    /// <exception cref="EArgumentException">If AModel or AAnimation is nil, or AFrameRate is
    /// less than 1.</exception>
    constructor Create(const AModel: TGorillaModel; const AAnimation: TGorillaAnimation;
      const AFrameRate: Integer; const AFrameCount: Integer = 0);
    //** @abstract(The number of frames: the count chosen, or the length times the chosen
    //** rate, rounded.)
    //**
    //** @returns(The frame count; at least 1.)
    /// <summary>The number of frames: the count chosen, or the length times the chosen rate,
    /// rounded.</summary>
    /// <returns>The frame count; at least 1.</returns>
    function FrameCount: Integer; override;
    //** @abstract(The animation's length in seconds.)
    //**
    //** @returns(The skeleton's Duration, or the baked pose count over the baked rate if that
    //** is not set.)
    /// <summary>The animation's length in seconds.</summary>
    /// <returns>The skeleton's Duration, or the baked pose count over the baked rate if that
    /// is not set.</returns>
    function Duration: Single; override;
    //** @abstract(Makes the animation the current one, without blending, and starts it.)
    /// <summary>Makes the animation the current one, without blending, and starts
    /// it.</summary>
    procedure Start; override;
    //** @abstract(Shows the pose at frame AIndex's time, I * Duration / FrameCount.)
    //**
    //** @param(AIndex The frame, from 0 to FrameCount - 1.)
    /// <summary>Shows the pose at frame AIndex's time, I * Duration / FrameCount.</summary>
    /// <param name="AIndex">The frame, from 0 to FrameCount - 1.</param>
    procedure ShowFrame(const AIndex: Integer); override;
    //** @abstract(Releases the fixed frame and leaves the animation playing.)
    /// <summary>Releases the fixed frame and leaves the animation playing.</summary>
    procedure Finish; override;
    //** @abstract(The animation being captured.)
    /// <summary>The animation being captured.</summary>
    property Animation: TGorillaAnimation read FAnimation;
  end;

  //** @abstract(One turn of the camera round the model, in equal steps.)
  //**
  //** Frame I is the camera's azimuth at Start plus I * 360 / FrameCount degrees, so the
  //** model appears to turn once round its vertical axis, and the frame after the last is the
  //** first again. The light rides on Sprite3D's camera, so the model is lit from the viewer's
  //** side in every frame, exactly as if the model itself had been turned in front of a still
  //** camera. Only the azimuth changes; the inclination, roll and framing are left as they
  //** are. A camera whose Locked is True does not turn, so every frame comes out the same;
  //** check it before capturing.
  /// <summary>One turn of the camera round the model, in equal steps.</summary>
  /// <remarks>Frame I is the camera's azimuth at Start plus I * 360 / FrameCount degrees, so
  /// the model appears to turn once round its vertical axis, and the frame after the last is
  /// the first again. The light rides on Sprite3D's camera, so the model is lit from the
  /// viewer's side in every frame, exactly as if the model itself had been turned in front of
  /// a still camera. Only the azimuth changes; the inclination, roll and framing are left as
  /// they are. A camera whose Locked is True does not turn, so every frame comes out the same;
  /// check it before capturing.</remarks>
  TSprite3DTurntableFrames = class(TSprite3DFrameSource)
  private
    FCamera: TSprite3DCamera;
    FFrames: Integer;
    FDuration: Single;
    FStartAzimuth: Single;
  public
    //** @abstract(Prepares one turn of ACamera in AFrames steps lasting ADuration seconds.)
    //**
    //** @param(ACamera The camera to turn; it must outlive this object.)
    //**
    //** @param(AFrames The number of frames; at least 1.)
    //**
    //** @param(ADuration How long the turn takes when played, in seconds; more than 0.)
    //**
    //** @raises(EArgumentException If ACamera is nil, AFrames is less than 1 or ADuration is
    //** not more than 0.)
    /// <summary>Prepares one turn of ACamera in AFrames steps lasting ADuration
    /// seconds.</summary>
    /// <param name="ACamera">The camera to turn; it must outlive this object.</param>
    /// <param name="AFrames">The number of frames; at least 1.</param>
    /// <param name="ADuration">How long the turn takes when played, in seconds; more than
    /// 0.</param>
    /// <exception cref="EArgumentException">If ACamera is nil, AFrames is less than 1 or
    /// ADuration is not more than 0.</exception>
    constructor Create(const ACamera: TSprite3DCamera; const AFrames: Integer;
      const ADuration: Single);
    //** @abstract(The number of frames given to Create.)
    //**
    //** @returns(The frame count.)
    /// <summary>The number of frames given to Create.</summary>
    /// <returns>The frame count.</returns>
    function FrameCount: Integer; override;
    //** @abstract(The length given to Create.)
    //**
    //** @returns(The length of the turn in seconds.)
    /// <summary>The length given to Create.</summary>
    /// <returns>The length of the turn in seconds.</returns>
    function Duration: Single; override;
    //** @abstract(Notes the camera's azimuth, which frame 0 uses.)
    /// <summary>Notes the camera's azimuth, which frame 0 uses.</summary>
    procedure Start; override;
    //** @abstract(Turns the camera to frame AIndex's azimuth.)
    //**
    //** @param(AIndex The frame, from 0 to FrameCount - 1.)
    /// <summary>Turns the camera to frame AIndex's azimuth.</summary>
    /// <param name="AIndex">The frame, from 0 to FrameCount - 1.</param>
    procedure ShowFrame(const AIndex: Integer); override;
    //** @abstract(Puts the camera back at the azimuth it had at Start.)
    /// <summary>Puts the camera back at the azimuth it had at Start.</summary>
    procedure Finish; override;
  end;

  //** @abstract(One capture run: every frame of a source, grabbed in turn.)
  //**
  //** Create it, then call Run. Run starts the source, shows frame 0 and asks the off-screen
  //** renderer for a grab; the first WarmUpFrames grabs are thrown away, frame 0 being shown
  //** again before each, then each grab is copied, the next frame shown and grabbed, and so
  //** on.
  //** When the last frame is in, or a grab fails, the source is finished, the procedure given
  //** to Create is called once with every frame or the error, and the capture frees itself
  //** and its source. While it runs, the off-screen renderer is busy for most of the time but
  //** not all of it, so the owner should refuse other grabs on its own account.
  //**
  //** The capture changes nothing about the framing: the owner frames the camera for the
  //** whole run first and restores it in its procedure. Where TSprite3DOffscreen grabs by
  //** screenshot (macOS and iOS), each frame is left on screen for SettleTime milliseconds
  //** before it is grabbed, so the screenshot shows it.
  /// <summary>One capture run: every frame of a source, grabbed in turn.</summary>
  /// <remarks><para>Create it, then call Run. Run starts the source, shows frame 0 and asks the
  /// off-screen renderer for a grab; the first WarmUpFrames grabs are thrown away, frame 0
  /// being shown again before each, then each grab is copied, the next frame shown and
  /// grabbed, and so on. When the last frame is in, or a grab fails, the source is finished, the
  /// procedure given to Create is called once with every frame or the error, and the capture
  /// frees itself and its source. While it runs, the off-screen renderer is busy for most of
  /// the time but not all of it, so the owner should refuse other grabs on its own
  /// account.</para>
  /// <para>The capture changes nothing about the framing: the owner frames the camera for the
  /// whole run first and restores it in its procedure. Where TSprite3DOffscreen grabs by
  /// screenshot (macOS and iOS), each frame is left on screen for SettleTime milliseconds
  /// before it is grabbed, so the screenshot shows it.</para></remarks>
  TSprite3DFrameCapture = class
  private
    FOffscreen: TSprite3DOffscreen;
    FSource: TSprite3DFrameSource;
    FOnDone: TSprite3DFramesProc;
    FOnProgress: TSprite3DCaptureProgress;
    FFrames: TArray<TSprite3DImage>;
    FIndex: Integer;
    FCancelled: Boolean;
    FStarted: Boolean;
    FSettleTime: Integer;
    FWarmUpFrames: Integer;
    FWarmUpLeft: Integer;
    FKeptOverscan: Integer;   // the renderer's overscan, put back after warming up
    procedure GrabFrame;
    procedure QueueGrab;
    procedure Done(const AError: String);
  public
    //** @abstract(Prepares a capture of ASource with AOffscreen.)
    //**
    //** @param(AOffscreen The off-screen renderer; it must outlive the capture. Its Width and
    //** Height are the frame size.)
    //**
    //** @param(ASource The frames; the capture owns it from here on and frees it.)
    //**
    //** @param(AOnDone Called once when the capture ends, unless it is cancelled.)
    //**
    //** @param(AOnProgress Called after each frame is grabbed; may be nil.)
    /// <summary>Prepares a capture of ASource with AOffscreen.</summary>
    /// <param name="AOffscreen">The off-screen renderer; it must outlive the capture. Its Width
    /// and Height are the frame size.</param>
    /// <param name="ASource">The frames; the capture owns it from here on and frees
    /// it.</param>
    /// <param name="AOnDone">Called once when the capture ends, unless it is
    /// cancelled.</param>
    /// <param name="AOnProgress">Called after each frame is grabbed; may be nil.</param>
    constructor Create(const AOffscreen: TSprite3DOffscreen;
      const ASource: TSprite3DFrameSource; const AOnDone: TSprite3DFramesProc;
      const AOnProgress: TSprite3DCaptureProgress = nil);
    //** @abstract(Frees the source and any frames not handed over.)
    /// <summary>Frees the source and any frames not handed over.</summary>
    destructor Destroy; override;
    //** @abstract(Starts the capture; returns at once.)
    //**
    //** The source has already been started if the owner called its Start itself, for
    //** example to measure every frame before framing; Run then does not start it again.
    //**
    //** @returns(True if it started; False if the off-screen renderer is busy or has no
    //** viewport, in which case the capture has finished its source, called nothing and
    //** freed itself.)
    /// <summary>Starts the capture; returns at once.</summary>
    /// <remarks>The source has already been started if the owner called its Start itself, for
    /// example to measure every frame before framing; Run then does not start it
    /// again.</remarks>
    /// <returns>True if it started; False if the off-screen renderer is busy or has no
    /// viewport, in which case the capture has finished its source, called nothing and freed
    /// itself.</returns>
    function Run: Boolean;
    //** @abstract(Stops the capture without calling its procedure.)
    //**
    //** Use it when the owner is going away. The source is finished, and the capture frees
    //** itself the next time it would have gone on, or at once if nothing is pending.
    /// <summary>Stops the capture without calling its procedure.</summary>
    /// <remarks>Use it when the owner is going away. The source is finished, and the capture
    /// frees itself the next time it would have gone on, or at once if nothing is
    /// pending.</remarks>
    procedure Cancel;
    //** @abstract(Marks the source as already started by the owner, so Run does not start it
    //** again.)
    /// <summary>Marks the source as already started by the owner, so Run does not start it
    /// again.</summary>
    procedure SourceStarted;
    //** @abstract(The frames being captured.)
    /// <summary>The frames being captured.</summary>
    property Source: TSprite3DFrameSource read FSource;
    //** @abstract(Milliseconds each frame is left on screen before it is grabbed.)
    //**
    //** 0 where grabs render off screen, which draws the frame as it is set; about four
    //** display frames where grabs are screenshots.
    /// <summary>Milliseconds each frame is left on screen before it is grabbed.</summary>
    /// <remarks>0 where grabs render off screen, which draws the frame as it is set; about
    /// four display frames where grabs are screenshots.</remarks>
    property SettleTime: Integer read FSettleTime write FSettleTime;
    //** @abstract(How many grabs of the first frame are thrown away before the one that is
    //** kept; DEFAULT_WARM_UP_FRAMES by default.)
    //**
    //** Each waits for a frame to be drawn, so the animation has caught up with its first pose
    //** by the time it is kept. Set it before Run; negative values count as 0. They are
    //** grabbed without overscan, which is put back for the frames that are kept, so they cost
    //** little whatever the overscan.
    /// <summary>How many grabs of the first frame are thrown away before the one that is
    /// kept; DEFAULT_WARM_UP_FRAMES by default.</summary>
    /// <remarks>Each waits for a frame to be drawn, so the animation has caught up with its
    /// first pose by the time it is kept. Set it before Run; negative values count as 0. They
    /// are grabbed without overscan, which is put back for the frames that are kept, so they
    /// cost little whatever the overscan.</remarks>
    property WarmUpFrames: Integer read FWarmUpFrames write FWarmUpFrames;
  end;

//** @abstract(Holds an animation on its current pose, or lets it carry on from there.)
//**
//** Pauses or unpauses the animation's skeleton clock, the same way on every Delphi version:
//** @code(Skeleton.Paused) on Delphi 13 and later, where Gorilla's render clock owns
//** @code(Pause), and @code(Skeleton.Pause) before. A paused animation stays current and
//** running, with its pose held, baked or not, so whatever follows the playing animation
//** still sees it; unpaused, it carries on from the same moment. Main thread only.
//**
//** @param(AAnimation The animation; nil, or one without a skeleton, is ignored.)
//**
//** @param(APaused True to hold the pose, False to carry on.)
/// <summary>Holds an animation on its current pose, or lets it carry on from
/// there.</summary>
/// <remarks>Pauses or unpauses the animation's skeleton clock, the same way on every Delphi
/// version: <c>Skeleton.Paused</c> on Delphi 13 and later, where Gorilla's render clock owns
/// <c>Pause</c>, and <c>Skeleton.Pause</c> before. A paused animation stays current and
/// running, with its pose held, baked or not, so whatever follows the playing animation still
/// sees it; unpaused, it carries on from the same moment. Main thread only.</remarks>
/// <param name="AAnimation">The animation; nil, or one without a skeleton, is
/// ignored.</param>
/// <param name="APaused">True to hold the pose, False to carry on.</param>
procedure SetAnimationPaused(const AAnimation: TGorillaAnimation; const APaused: Boolean);

type
  //** @abstract(Plays, pauses and steps one animation of a model on screen, an export frame
  //** at a time.)
  //**
  //** Made when the animation starts playing from its beginning. While it plays, the player
  //** keeps its own clock, so Pause can tell which frame is showing. Pause, Step and
  //** ShowFrame hold the animation on one frame: the frames are those an export at FrameRate
  //** makes, by TSprite3DAnimationFrames, so frame N is held exactly as frame N of an export
  //** shows it, from the baked pose where Gorilla has baked the animation. Play carries on
  //** from the frame held. Freeing the player lets a held animation play on.
  //**
  //** For the main thread only. The model and animation must outlive the player, and nothing
  //** else, such as a capture, may drive the animation while it is held.
  /// <summary>Plays, pauses and steps one animation of a model on screen, an export frame at a
  /// time.</summary>
  /// <remarks>Made when the animation starts playing from its beginning. While it plays, the
  /// player keeps its own clock, so Pause can tell which frame is showing. Pause, Step and
  /// ShowFrame hold the animation on one frame: the frames are those an export at FrameRate
  /// makes, by TSprite3DAnimationFrames, so frame N is held exactly as frame N of an export
  /// shows it, from the baked pose where Gorilla has baked the animation. Play carries on from
  /// the frame held. Freeing the player lets a held animation play on.
  /// For the main thread only. The model and animation must outlive the player, and nothing
  /// else, such as a capture, may drive the animation while it is held.</remarks>
  TSprite3DAnimationPlayer = class
  private
    FModel: TGorillaModel;
    FAnimation: TGorillaAnimation;
    FFrameRate: Integer;
    FFrameCount: Integer;                // frames chosen by hand; 0 for FFrameRate's
    FFrames: TSprite3DAnimationFrames;   // the export frames, at FFrameRate
    FHeld: Boolean;
    FFrame: Integer;                     // the frame held
    FClock: TStopwatch;                  // since play last started
    FOffset: Double;                     // seconds into the cycle it started at
    function GetFrameCount: Integer;
    function GetCurrentFrame: Integer;
    function PlayingFrame: Integer;
    procedure SetFrameRate(const AValue: Integer);
  public
    //** @abstract(Starts following an animation that has just started from its beginning.)
    //**
    //** @param(AModel The model the animation belongs to.)
    //**
    //** @param(AAnimation The animation, current and running from its first pose.)
    //**
    //** @param(AFrameRate The export frame rate, which sets the frames held and stepped
    //** through.)
    //**
    //** @param(AFrameCount The number of export frames, in place of what AFrameRate gives,
    //** such as one chosen by hand; 0, the default, for what AFrameRate gives. It is kept
    //** when FrameRate changes.)
    //**
    //** @raises(EArgumentException If AModel or AAnimation is nil, or AFrameRate is below 1.)
    /// <summary>Starts following an animation that has just started from its
    /// beginning.</summary>
    /// <param name="AModel">The model the animation belongs to.</param>
    /// <param name="AAnimation">The animation, current and running from its first
    /// pose.</param>
    /// <param name="AFrameRate">The export frame rate, which sets the frames held and stepped
    /// through.</param>
    /// <param name="AFrameCount">The number of export frames, in place of what AFrameRate
    /// gives, such as one chosen by hand; 0, the default, for what AFrameRate gives. It is
    /// kept when FrameRate changes.</param>
    /// <exception cref="EArgumentException">If AModel or AAnimation is nil, or AFrameRate is
    /// below 1.</exception>
    constructor Create(const AModel: TGorillaModel; const AAnimation: TGorillaAnimation;
      const AFrameRate: Integer; const AFrameCount: Integer = 0);
    //** @abstract(Lets a held animation play on from its frame, then frees the player.)
    /// <summary>Lets a held animation play on from its frame, then frees the player.</summary>
    destructor Destroy; override;
    //** @abstract(Carries on playing from the frame held; nothing if it is not held.)
    /// <summary>Carries on playing from the frame held; nothing if it is not held.</summary>
    procedure Play;
    //** @abstract(Holds the animation on the frame showing now; nothing if already held.)
    /// <summary>Holds the animation on the frame showing now; nothing if already
    /// held.</summary>
    procedure Pause;
    //** @abstract(Holds the animation on frame AFrame.)
    //**
    //** @param(AFrame The frame, from 0 to FrameCount - 1; others wrap round, as the
    //** animation loops, so -1 is the last frame.)
    /// <summary>Holds the animation on frame AFrame.</summary>
    /// <param name="AFrame">The frame, from 0 to FrameCount - 1; others wrap round, as the
    /// animation loops, so -1 is the last frame.</param>
    procedure ShowFrame(const AFrame: Integer);
    //** @abstract(Holds the animation ADelta frames on from the one held, or from the one
    //** showing if it is playing.)
    //**
    //** @param(ADelta Frames to move: 1 for the next, -1 for the previous; it wraps round.)
    /// <summary>Holds the animation ADelta frames on from the one held, or from the one
    /// showing if it is playing.</summary>
    /// <param name="ADelta">Frames to move: 1 for the next, -1 for the previous; it wraps
    /// round.</param>
    procedure Step(const ADelta: Integer);
    //** @abstract(The animation played.)
    /// <summary>The animation played.</summary>
    property Animation: TGorillaAnimation read FAnimation;
    //** @abstract(True while the animation is held on one frame.)
    /// <summary>True while the animation is held on one frame.</summary>
    property Held: Boolean read FHeld;
    //** @abstract(The frame held, from 0; meaningful only while Held.)
    /// <summary>The frame held, from 0; meaningful only while Held.</summary>
    property Frame: Integer read FFrame;
    //** @abstract(The frame showing, from 0: the one held, or while playing the one nearest the
    //** moment showing, by the player's own clock.)
    /// <summary>The frame showing, from 0: the one held, or while playing the one nearest the
    /// moment showing, by the player's own clock.</summary>
    property CurrentFrame: Integer read GetCurrentFrame;
    //** @abstract(How many frames one cycle has at FrameRate, as an export makes.)
    /// <summary>How many frames one cycle has at FrameRate, as an export makes.</summary>
    property FrameCount: Integer read GetFrameCount;
    //** @abstract(The export frame rate the frames are counted at.)
    //**
    //** Changing it while held keeps the same point of the cycle, to the nearest new frame.
    //** Values below 1 count as 1.
    /// <summary>The export frame rate the frames are counted at.</summary>
    /// <remarks>Changing it while held keeps the same point of the cycle, to the nearest new
    /// frame. Values below 1 count as 1.</remarks>
    property FrameRate: Integer read FFrameRate write SetFrameRate;
  end;

implementation

uses
  System.Math;

procedure SetAnimationPaused(const AAnimation: TGorillaAnimation; const APaused: Boolean);
begin
  if (AAnimation = nil) or not Assigned(AAnimation.Skeleton) then
    Exit;
  {$IF CompilerVersion >= 37.0}
  AAnimation.Skeleton.Paused := APaused;
  {$ELSE}
  AAnimation.Skeleton.Pause := APaused;
  {$ENDIF}
end;

{ TSprite3DAnimationPlayer }

constructor TSprite3DAnimationPlayer.Create(const AModel: TGorillaModel;
  const AAnimation: TGorillaAnimation; const AFrameRate: Integer;
  const AFrameCount: Integer);
begin
  inherited Create;
  if AFrameRate < 1 then
    raise EArgumentException.Create('The frame rate must be at least 1.');
  FModel := AModel;
  FAnimation := AAnimation;
  FFrameRate := AFrameRate;
  FFrameCount := Max(0, AFrameCount);
  // Raises for a missing model or animation
  FFrames := TSprite3DAnimationFrames.Create(AModel, AAnimation, AFrameRate, FFrameCount);
  FOffset := 0;
  FClock := TStopwatch.StartNew;
end;

destructor TSprite3DAnimationPlayer.Destroy;
begin
  if Assigned(FFrames) then
    Play;
  FFrames.Free;
  inherited;
end;

function TSprite3DAnimationPlayer.GetFrameCount: Integer;
begin
  Result := FFrames.FrameCount;
end;

function TSprite3DAnimationPlayer.GetCurrentFrame: Integer;
begin
  if FHeld then
    Result := FFrame
  else
    Result := PlayingFrame;
end;

// The frame nearest the moment showing now, by the player's own clock
function TSprite3DAnimationPlayer.PlayingFrame: Integer;
var
  Duration, Time, Phase: Double;
begin
  Duration := FFrames.Duration;
  if Duration <= 0 then
    Exit(0);
  Time := FOffset + FClock.Elapsed.TotalSeconds;
  Phase := Frac(Time / Duration);
  Result := Round(Phase * FrameCount) mod FrameCount;
end;

procedure TSprite3DAnimationPlayer.ShowFrame(const AFrame: Integer);
var
  Count: Integer;
begin
  Count := FrameCount;
  FFrame := ((AFrame mod Count) + Count) mod Count;
  if not FHeld then
  begin
    // This animation alone, no cross-fade, then its clock stopped
    if Assigned(FModel.AnimationManager) then
      FModel.AnimationManager.CancelBlend;
    FFrames.Start;
    SetAnimationPaused(FAnimation, True);
    FHeld := True;
  end;
  FFrames.ShowFrame(FFrame);
end;

procedure TSprite3DAnimationPlayer.Pause;
begin
  if not FHeld then
    ShowFrame(PlayingFrame);
end;

procedure TSprite3DAnimationPlayer.Step(const ADelta: Integer);
begin
  if FHeld then
    ShowFrame(FFrame + ADelta)
  else
    ShowFrame(PlayingFrame + ADelta);
end;

procedure TSprite3DAnimationPlayer.Play;
var
  Time: Double;
begin
  if not FHeld then
    Exit;
  FHeld := False;
  Time := FFrame * FFrames.Duration / FrameCount;
  // The baked pose let go and the clock running again, from the frame held
  FFrames.Finish;
  SetAnimationPaused(FAnimation, False);
  if Assigned(FAnimation.Skeleton) then
    FAnimation.Skeleton.SeekTo(Time);
  FOffset := Time;
  FClock := TStopwatch.StartNew;
end;

procedure TSprite3DAnimationPlayer.SetFrameRate(const AValue: Integer);
var
  Rate: Integer;
  Phase: Double;
begin
  Rate := Max(1, AValue);
  if Rate = FFrameRate then
    Exit;
  Phase := FFrame / FrameCount;
  FFrameRate := Rate;
  FreeAndNil(FFrames);
  FFrames := TSprite3DAnimationFrames.Create(FModel, FAnimation, Rate, FFrameCount);
  if FHeld then
  begin
    FFrame := Round(Phase * FrameCount) mod FrameCount;
    FFrames.ShowFrame(FFrame);
  end;
end;

{ TSprite3DFrameSource }

procedure TSprite3DFrameSource.Start;
begin
end;

procedure TSprite3DFrameSource.Finish;
begin
end;

function TSprite3DFrameSource.FrameDelay: Integer;
begin
  Result := Max(1, Round(100 * Duration / Max(1, FrameCount)));
end;

{ TSprite3DAnimationFrames }

constructor TSprite3DAnimationFrames.Create(const AModel: TGorillaModel;
  const AAnimation: TGorillaAnimation; const AFrameRate: Integer;
  const AFrameCount: Integer);
const
  // Only used if Gorilla reports neither a length nor a baked rate
  FALLBACK_LENGTH = 1.0;
begin
  inherited Create;
  if (AModel = nil) or (AAnimation = nil) then
    raise EArgumentException.Create('There is no animation to capture.');
  if AFrameRate < 1 then
    raise EArgumentException.Create('The frame rate must be at least 1.');
  FModel := AModel;
  FAnimation := AAnimation;
  FCachedFrames := FAnimation.FrameCount;
  FCached := FCachedFrames > 0;
  FDuration := 0;
  if Assigned(FAnimation.Skeleton) then
    FDuration := FAnimation.Skeleton.Duration;
  if FDuration <= 0 then
    if FCached and (FAnimation.FrameRate > 0) then
      FDuration := FCachedFrames / FAnimation.FrameRate
    else
      FDuration := FALLBACK_LENGTH;
  // A whole number of equal steps in one cycle: as many as asked for, or as
  // near the rate as that allows
  if AFrameCount > 0 then
    FFrames := AFrameCount
  else
    FFrames := Max(1, Round(FDuration * AFrameRate));
end;

function TSprite3DAnimationFrames.FrameCount: Integer;
begin
  Result := FFrames;
end;

function TSprite3DAnimationFrames.Duration: Single;
begin
  Result := FDuration;
end;

procedure TSprite3DAnimationFrames.Start;
begin
  // Assigning Current switches clips without the cross-fade PlayAnimation
  // can do, which would mix two animations in the first frames
  if FModel.AnimationManager.Current <> FAnimation then
    FModel.AnimationManager.Current := FAnimation;
  if not FAnimation.IsRunning then
    FAnimation.Start;
end;

procedure TSprite3DAnimationFrames.SeekTo(const ATime: Single);
var
  Time: Single;
begin
  if not Assigned(FAnimation.Skeleton) then
    Exit;
  // Reaching Duration would end or wrap the clip, so stay just short of it
  Time := EnsureRange(ATime, 0, Max(0, Duration * 0.9999));
  {$IF CompilerVersion >= 37.0}
  // Gorilla's render clock holds the skeleton and evaluates the new
  // position on the next frame it draws
  FAnimation.Skeleton.SeekTo(Time);
  {$ELSE}
  // ProcessTick only evaluates an unpaused clip; pause it again so the
  // clock leaves the pose where it is
  FAnimation.Skeleton.Pause := False;
  FAnimation.Skeleton.SeekTo(Time);
  FAnimation.Skeleton.ProcessTick(0, 0);
  FAnimation.Skeleton.Pause := True;
  {$ENDIF}
end;

procedure TSprite3DAnimationFrames.ShowFrame(const AIndex: Integer);
var
  Phase: Double;
  Baked: Integer;
begin
  // How far through the cycle this frame is, 0 up to but not including 1
  Phase := EnsureRange(AIndex, 0, FFrames - 1) / FFrames;
  if FCached then
  begin
    // The nearest baked pose; past the last one is the first again
    Baked := Round(Phase * FCachedFrames) mod FCachedFrames;
    FAnimation.SetFixedCacheFrame(Baked);
  end
  else
    SeekTo(Phase * FDuration);
end;

procedure TSprite3DAnimationFrames.Finish;
begin
  if FCached then
    FAnimation.UnsetFixedCacheFrame
  else
  begin
    {$IF CompilerVersion < 37.0}
    if Assigned(FAnimation.Skeleton) then
      FAnimation.Skeleton.Pause := False;
    {$ENDIF}
  end;
  if not FAnimation.IsRunning then
    FAnimation.Start;
end;

{ TSprite3DTurntableFrames }

constructor TSprite3DTurntableFrames.Create(const ACamera: TSprite3DCamera;
  const AFrames: Integer; const ADuration: Single);
begin
  inherited Create;
  if (ACamera = nil) or (AFrames < 1) or (ADuration <= 0) then
    raise EArgumentException.Create('The turn cannot be captured as given.');
  FCamera := ACamera;
  FFrames := AFrames;
  FDuration := ADuration;
end;

function TSprite3DTurntableFrames.FrameCount: Integer;
begin
  Result := FFrames;
end;

function TSprite3DTurntableFrames.Duration: Single;
begin
  Result := FDuration;
end;

procedure TSprite3DTurntableFrames.Start;
begin
  FStartAzimuth := FCamera.Azimuth;
end;

procedure TSprite3DTurntableFrames.ShowFrame(const AIndex: Integer);
var
  Angle: Double;
begin
  Angle := FStartAzimuth + 360.0 * AIndex / FFrames;
  Angle := Angle - 360.0 * Floor(Angle / 360.0);
  FCamera.Azimuth := Angle;
end;

procedure TSprite3DTurntableFrames.Finish;
begin
  FCamera.Azimuth := FStartAzimuth;
end;

{ TSprite3DFrameCapture }

constructor TSprite3DFrameCapture.Create(const AOffscreen: TSprite3DOffscreen;
  const ASource: TSprite3DFrameSource; const AOnDone: TSprite3DFramesProc;
  const AOnProgress: TSprite3DCaptureProgress);
begin
  inherited Create;
  FOffscreen := AOffscreen;
  FSource := ASource;
  FOnDone := AOnDone;
  FOnProgress := AOnProgress;
  FWarmUpFrames := DEFAULT_WARM_UP_FRAMES;
  {$IF DEFINED(MACOS)}
  FSettleTime := 70;   // about four frames at 60 a second
  {$ELSE}
  FSettleTime := 0;
  {$ENDIF}
end;

destructor TSprite3DFrameCapture.Destroy;
begin
  FSource.Free;
  inherited;
end;

procedure TSprite3DFrameCapture.SourceStarted;
begin
  FStarted := True;
end;

function TSprite3DFrameCapture.Run: Boolean;
begin
  Result := Assigned(FOffscreen) and Assigned(FOffscreen.Viewport) and
    not FOffscreen.Busy and Assigned(FSource) and (FSource.FrameCount > 0);
  if not Result then
  begin
    if FStarted then
      FSource.Finish;
    Free;
    Exit;
  end;
  if not FStarted then
  begin
    FSource.Start;
    FStarted := True;
  end;
  SetLength(FFrames, 0);
  FIndex := 0;
  // Grabs to throw away while the animation catches up with its first pose
  FWarmUpLeft := Max(FWarmUpFrames, 0);
  // Warm-up grabs are thrown away, so they need no overscan
  FKeptOverscan := FOffscreen.Overscan;
  if FWarmUpLeft > 0 then
    FOffscreen.Overscan := 1;
  FSource.ShowFrame(0);
  QueueGrab;
end;

// Grab now, or once the frame has been on screen long enough to be in a
// screenshot
procedure TSprite3DFrameCapture.QueueGrab;
var
  Me: TSprite3DFrameCapture;
begin
  FOffscreen.Viewport.Invalidate;
  if FSettleTime <= 0 then
  begin
    GrabFrame;
    Exit;
  end;
  Me := Self;
  TThread.ForceQueue(nil,
    procedure
    begin
      if Me.FCancelled then
        Me.Free
      else
        Me.GrabFrame;
    end, FSettleTime);
end;

procedure TSprite3DFrameCapture.GrabFrame;
var
  Me: TSprite3DFrameCapture;
begin
  Me := Self;
  if not FOffscreen.Grab(
    procedure(const ABitmap: TBitmap; const AError: String)
    begin
      if Me.FCancelled then
      begin
        Me.Free;
        Exit;
      end;
      if not Assigned(ABitmap) then
      begin
        Me.Done(AError);
        Exit;
      end;
      if Me.FWarmUpLeft > 0 then
      begin
        // A warm-up grab: thrown away, and frame 0 shown and grabbed again,
        // with the overscan back for the one that is kept
        Dec(Me.FWarmUpLeft);
        if Me.FWarmUpLeft = 0 then
          Me.FOffscreen.Overscan := Me.FKeptOverscan;
        Me.FSource.ShowFrame(0);
        Me.QueueGrab;
        Exit;
      end;
      try
        Me.FFrames := Me.FFrames + [ImageFromBitmap(ABitmap)];
      except
        on E: Exception do
        begin
          Me.Done(E.Message);
          Exit;
        end;
      end;
      Inc(Me.FIndex);
      if Assigned(Me.FOnProgress) then
        Me.FOnProgress(Me.FIndex, Me.FSource.FrameCount);
      if Me.FIndex >= Me.FSource.FrameCount then
        Me.Done(String.Empty)
      else
      begin
        Me.FSource.ShowFrame(Me.FIndex);
        Me.QueueGrab;
      end;
    end) then
    Done('A grab could not be started.');
end;

// Hands the scene back, reports, and frees the capture
procedure TSprite3DFrameCapture.Done(const AError: String);
var
  Frames: TArray<TSprite3DImage>;
begin
  if FWarmUpLeft > 0 then
    FOffscreen.Overscan := FKeptOverscan;   // ended while warming up
  try
    FSource.Finish;
    if AError = String.Empty then
      Frames := FFrames
    else
      Frames := nil;
    FFrames := nil;
    if Assigned(FOnDone) then
      FOnDone(Frames, AError);
  finally
    Free;
  end;
end;

procedure TSprite3DFrameCapture.Cancel;
begin
  if FCancelled then
    Exit;
  FCancelled := True;
  if FWarmUpLeft > 0 then
    FOffscreen.Overscan := FKeptOverscan;   // cancelled while warming up
  FOnDone := nil;
  FOnProgress := nil;
  if FStarted then
    FSource.Finish;
  // A grab or a delayed step is pending, and frees the capture when it
  // runs; if the renderer is gone it never will, which only happens as the
  // program closes
  if not FOffscreen.Busy and (FSettleTime <= 0) then
    Free;
end;

end.
