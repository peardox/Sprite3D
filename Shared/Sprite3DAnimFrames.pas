//** @abstract(Shows a Gorilla model's animation one frame at a time, at a chosen frame rate.)
//**
//** A frame source says how many frames there are, how long they last together, and how to
//** show frame N. TSprite3DAnimationFrames shows the frames of one of a Gorilla model's
//** animations, from the first to the last, posing the model at each frame's time and holding
//** it there. Sprite3DSweep uses it to step an animation through its poses while measuring
//** the space the model fills.
//**
//** Shared by Sprite3D and Sprite3DBuilder. TSprite3DFrameSource is the base each program
//** builds on for its own frames: Sprite3D's Sprite3DAnimCapture adds a turn of the camera
//** (TSprite3DTurntableFrames) and the off-screen capture of any frame source, which
//** Sprite3DBuilder does not have.
//**
//** Everything here is for the main thread.
//**
//** @preformatted(
//** TSprite3DFrameSource @(abstract@)
//** `-- TSprite3DAnimationFrames   a TGorillaAnimation, frame by frame
//** )
unit Sprite3DAnimFrames;

{
  Shows a Gorilla model's animation one frame at a time, at a chosen frame
  rate.

  A frame source says how many frames there are, how long they last
  together, and how to show frame N. TSprite3DAnimationFrames shows the
  frames of one of a Gorilla model's animations, from the first to the
  last, posing the model at each frame's time and holding it there.
  Sprite3DSweep uses it to step an animation through its poses while
  measuring the space the model fills.

  Shared by Sprite3D and Sprite3DBuilder. TSprite3DFrameSource is the base
  each program builds on for its own frames: Sprite3D's Sprite3DAnimCapture
  adds a turn of the camera (TSprite3DTurntableFrames) and the off-screen
  capture of any frame source, which Sprite3DBuilder does not have.

  Everything here is for the main thread.

    TSprite3DFrameSource (abstract)
    `-- TSprite3DAnimationFrames   a TGorillaAnimation, frame by frame
}

interface

uses
  System.SysUtils, Gorilla.Model, Gorilla.Animation;

type
  //** @abstract(Something that can be shown one frame at a time for capture.)
  //**
  //** Call Start once, then ShowFrame for any frame from 0 to FrameCount - 1 in any order,
  //** then Finish once. Between Start and Finish the scene is the source's to change.
  TSprite3DFrameSource = class abstract
  public
    //** @abstract(How many frames there are; at least 1.)
    //**
    //** @returns(The frame count.)
    function FrameCount: Integer; virtual; abstract;
    //** @abstract(How long all the frames last together, in seconds, when played.)
    //**
    //** @returns(The length of one pass through every frame; more than 0.)
    function Duration: Single; virtual; abstract;
    //** @abstract(Takes over the scene for capture; called once, before any ShowFrame.)
    procedure Start; virtual;
    //** @abstract(Puts the scene in the state of one frame.)
    //**
    //** @param(AIndex The frame, from 0 to FrameCount - 1.)
    procedure ShowFrame(const AIndex: Integer); virtual; abstract;
    //** @abstract(Hands the scene back; called once, after the last ShowFrame.)
    //**
    //** An animation is left playing as it was chosen; the camera is left at the angle it
    //** had before Start.
    procedure Finish; virtual;
    //** @abstract(How long each frame shows when played, in hundredths of a second, as GIF
    //** counts it.)
    //**
    //** @returns(Duration / FrameCount, rounded, at least 1.)
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
  //** The baked poses hold only the skinned meshes. Meshes hung unskinned on joints or
  //** animated nodes (a bear's eyes under its head bone) are placed by the live skeleton, so
  //** it is posed at the baked frame's own time as well, @code(Baked * Duration / (frames -
  //** 1)), the time Gorilla baked it at.
  //**
  //** An animation without baked poses is posed by the skeleton alone, at each exact time,
  //** which interpolates the keyframes there.
  //**
  //** The skeleton is posed at once, whatever the Delphi version: a seek only moves the play
  //** head, so it is followed by one @code(ProcessTick(0, 0)) with Pause cleared for that
  //** call, as Gorilla's render clock does around each tick it lets through (on Delphi 13 and
  //** later the clock skips a paused clip altogether).
  //**
  //** Animations that do not cycle are not treated differently yet: their last pose is left
  //** out, as for a cycle.
  //**
  //** Start makes the animation the model's current one, without blending, and starts it.
  TSprite3DAnimationFrames = class(TSprite3DFrameSource)
  private
    //** @abstract(The model and the animation of it shown, as given to Create.)
    FModel: TGorillaModel;
    FAnimation: TGorillaAnimation;
    //** @abstract(Whether Gorilla has baked the animation's poses, and how many it baked.)
    FCached: Boolean;
    FCachedFrames: Integer;
    //** @abstract(The frame count, and the animation's length in seconds.)
    FFrames: Integer;
    FDuration: Single;
    //** @abstract(Poses the live skeleton at ATime at once, and leaves it held there.)
    //**
    //** @param(ATime Seconds into the clip; kept just short of Duration.)
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
    constructor Create(const AModel: TGorillaModel; const AAnimation: TGorillaAnimation;
      const AFrameRate: Integer; const AFrameCount: Integer = 0);
    //** @abstract(The number of frames: the count chosen, or the length times the chosen
    //** rate, rounded.)
    //**
    //** @returns(The frame count; at least 1.)
    function FrameCount: Integer; override;
    //** @abstract(The animation's length in seconds.)
    //**
    //** @returns(The skeleton's Duration, or the baked pose count over the baked rate if that
    //** is not set.)
    function Duration: Single; override;
    //** @abstract(Makes the animation the current one, without blending, and starts it.)
    procedure Start; override;
    //** @abstract(Shows the pose at frame AIndex's time, I * Duration / FrameCount.)
    //**
    //** @param(AIndex The frame, from 0 to FrameCount - 1.)
    procedure ShowFrame(const AIndex: Integer); override;
    //** @abstract(Releases the fixed frame and leaves the animation playing.)
    procedure Finish; override;
    //** @abstract(The animation being captured.)
    property Animation: TGorillaAnimation read FAnimation;
  end;

implementation

uses
  System.Math;

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
  // Pose the skeleton now. ProcessTick only evaluates a clip whose Pause flag
  // is clear, so clear it for this one call and set it again. On Delphi 13
  // and later Gorilla's render clock owns that flag and skips a paused
  // skeleton altogether (TGorillaRenderClock: "if Paused then Continue"),
  // so a seek alone would never be drawn; the clock itself clears and sets
  // the flag the same way around each tick it lets through.
  FAnimation.Skeleton.Pause := False;
  try
    FAnimation.Skeleton.SeekTo(Time);
    FAnimation.Skeleton.ProcessTick(0, 0);
  finally
    FAnimation.Skeleton.Pause := True;
  end;
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
    // The baked frames hold only skinned meshes. Rigid meshes hung on
    // animated nodes (a bear's eyes under its head bone) are placed by the
    // live skeleton, which a held clip leaves where it stopped: pose it at
    // the baked frame's own time too, or they lag behind or sit astray.
    // Gorilla bakes frame f at f * Duration / (frames - 1).
    if FCachedFrames > 1 then
      SeekTo(Baked * FDuration / (FCachedFrames - 1))
    else
      SeekTo(0);
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

end.
