//** @abstract(The projection test: tries every way TSpritelyProjectionAccess has of moving the
//** picture across the lens (a lens shift and rise), measures what each really did, and logs
//** it.)
//**
//** Run draws with the viewport's RenderManual and reads the picture with MakeScreenshot, so
//** it needs nothing on screen to look at. For each way it:
//**
//** @orderedList(
//**   @item(draws a reference frame;)
//**   @item(makes the change - written once, written before each frame, or written inside the
//**     frame by the hook - and takes two looks, each after PROJTEST_RENDERS_PER_LOOK renders,
//**     as MakeScreenshot is a frame late (CheckScreenshotLag);)
//**   @item(puts everything back and draws again, to check it went back;)
//**   @item(measures both frames against the reference (MeasureShift): a shift of
//**     PROJTEST_SHIFT of the half-width to the right should move the picture that far, and
//**     nothing else; if it does, a rise of the same up is tried.)
//** )
//**
//** The ways, in order: the public SetRenderToMatrix and SetCameraMatrix (a shear, as LenticularDemoFMX
//** does), then each projection and camera matrix Survey found in memory. The log ends with
//** what worked.
unit ProjectionTestRunner;

{
  The projection test: every way of moving the picture across the lens
  (public SetRenderToMatrix, SetCameraMatrix with a shear, the projection
  and camera matrices found in memory), each written once, before each
  frame or inside the frame; each measured against a reference frame and
  logged, then a summary of what worked.
}

interface

uses
  System.SysUtils, System.Classes, System.Math, System.Math.Vectors,
  FMX.Types3D, FMX.Graphics, Gorilla.Viewport, Spritely.Projection, ProjectionTestMeasure;

const
  //** @abstract(How far each test moves the picture, in normalised device units: 0.1 is a tenth
  //** of the picture's half-width, 96 px across a 1920 px picture.)
  PROJTEST_SHIFT = 0.1;
  //** @abstract(RenderManual calls before each screenshot: MakeScreenshot shows the picture of
  //** the RenderManual before the last (ProjTest1), so one alone shows the frame before.)
  PROJTEST_RENDERS_PER_LOOK = 2;
  //** @abstract(The most projection matrices found in memory that are tried.)
  PROJTEST_MAX_PROJECTION_SLOTS = 6;
  //** @abstract(The most camera matrices found in memory that are tried.)
  PROJTEST_MAX_CAMERA_SLOTS = 3;

type
  //** @abstract(When a test makes its change.)
  TPeardoxTestTiming = (
    //** Once, before the first of the two frames
    ttOnce,
    //** Before each frame (and before each screenshot)
    ttBeforeEachRender,
    //** Inside each frame, by the hook, before the models are drawn
    ttInRender);

  //** @abstract(Makes the change for a shift and rise.)
  //**
  //** @param(ASX Shift, normalised device units, + right.)
  //** @param(ASY Rise, normalised device units, + up.)
  //** @returns(The change.)
  TSpritelyAdjustMaker = reference to function(ASX, ASY: Single): TSpritelyMatrixAdjust;

  //** @abstract(Runs the projection test on a Gorilla3D viewport.)
  TPeardoxProjectionTester = class
  private
    //** @abstract(The viewport drawn.)
    FViewport: TGorillaViewport;
    //** @abstract(Finds and changes the matrices.)
    FAccess: TSpritelyProjectionAccess;
    //** @abstract(Where log lines go.)
    FOnLog: TSpritelyLogProc;
    //** @abstract(The ways that shifted and rose the picture as expected.)
    FWorking: TStringList;
    //** @abstract(The ways that moved it, but not as expected.)
    FOdd: TStringList;
    //** @abstract(How many times the hook was drawn in the last frame's RenderManual.)
    FRenderCalls: Integer;
    //** @abstract(How many times the hook was drawn in the last frame's MakeScreenshot.)
    FShotCalls: Integer;
    //** @abstract(The first projection slot that worked, or nil.)
    FBestProjection: TSpritelyMatrixSlot;
    //** @abstract(How FBestProjection was written when it worked.)
    FBestProjectionTiming: TPeardoxTestTiming;
    //** @abstract(The first camera slot that worked, or nil.)
    FBestCamera: TSpritelyMatrixSlot;
    //** @abstract(Whether SetRenderToMatrix worked, written inside the frame.)
    FRenderToWorks: Boolean;
    //** @abstract(Whether SetCameraMatrix with a shear worked, inside the frame.)
    FShearWorks: Boolean;
    //** @abstract(Sends a line to OnLog.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: string);
    //** @abstract(How many times the hook has been drawn.)
    //**
    //** @returns(The count, 0 without a hook.)
    function Hooked: Integer;
    //** @abstract(Draws a frame and takes its picture.)
    //**
    //** @param(ABefore Called before each RenderManual and again before MakeScreenshot; may be
    //** nil.)
    //** @param(ARenders How many times to RenderManual before the screenshot.)
    //** @returns(The picture.)
    function Frame(const ABefore: TProc;
      ARenders: Integer = PROJTEST_RENDERS_PER_LOOK): TPeardoxGreyPicture;
    //** @abstract(Whether MakeScreenshot shows the last RenderManual's picture or an earlier
    //** one: a shift written once, then one screenshot after each of two renders.)
    procedure CheckScreenshotLag;
    //** @abstract(What the context's getter says after a write, for the log.)
    //**
    //** @param(ATarget What was written.)
    //** @param(ASlot The slot written, or nil.)
    //** @returns(A note, or empty.)
    function GetterNote(ATarget: TSpritelyAdjustTarget; ASlot: TSpritelyMatrixSlot): string;
    //** @abstract(One test: a change, two frames, measured and logged, and everything put back.)
    //**
    //** @param(AName The test's name for the log.)
    //** @param(ATarget What to change.)
    //** @param(ASlot The slot, for slot targets.)
    //** @param(ATiming When to change it.)
    //** @param(ASX Shift, normalised device units.)
    //** @param(ASY Rise, normalised device units.)
    //** @param(AAdjust The change.)
    //** @returns(What the second frame says.)
    function RunCase(const AName: string; ATarget: TSpritelyAdjustTarget;
      ASlot: TSpritelyMatrixSlot; ATiming: TPeardoxTestTiming; ASX, ASY: Single;
      const AAdjust: TSpritelyMatrixAdjust): TPeardoxShiftVerdict;
    //** @abstract(A shift test and, if the picture moved, a rise test; notes the outcome.)
    //**
    //** @param(AName The way's name for the log.)
    //** @param(ATarget What to change.)
    //** @param(ASlot The slot, for slot targets.)
    //** @param(ATiming When to change it.)
    //** @param(AMaker Makes the change.)
    //** @returns(True if both went as expected.)
    function RunBoth(const AName: string; ATarget: TSpritelyAdjustTarget;
      ASlot: TSpritelyMatrixSlot; ATiming: TPeardoxTestTiming;
      const AMaker: TSpritelyAdjustMaker): Boolean;
    //** @abstract(Tries one slot every way.)
    //**
    //** @param(AName The slot's name for the log.)
    //** @param(ATarget atProjectionSlot or atCameraSlot.)
    //** @param(ASlot The slot.)
    //** @param(AMaker Makes the change.)
    //** @param(ATiming When it first worked.)
    //** @returns(True if any timing worked.)
    function RunSlot(const AName: string; ATarget: TSpritelyAdjustTarget;
      ASlot: TSpritelyMatrixSlot; const AMaker: TSpritelyAdjustMaker;
      out ATiming: TPeardoxTestTiming): Boolean;
    //** @abstract(The summary at the end of the log.)
    procedure LogSummary;
  public
    //** @abstract(Makes the tester.)
    //**
    //** @param(AViewport The viewport to draw.)
    //** @param(AAccess The access made for that viewport.)
    constructor Create(AViewport: TGorillaViewport; AAccess: TSpritelyProjectionAccess);
    //** @abstract(Frees the lists.)
    destructor Destroy; override;
    //** @abstract(Runs the whole test; the viewport's ManualRendering, UseFixedFrameRate and
    //** FrustumCulling are put back afterwards.)
    //**
    //** @param(AExtra More objects for Survey to look through: the cameras.)
    procedure Run(const AExtra: array of TObject);
    //** @abstract(The first projection slot that worked, or nil; valid until the next Survey.)
    property BestProjection: TSpritelyMatrixSlot read FBestProjection;
    //** @abstract(How BestProjection was written when it worked.)
    property BestProjectionTiming: TPeardoxTestTiming read FBestProjectionTiming;
    //** @abstract(The first camera slot that worked, or nil; valid until the next Survey.)
    property BestCamera: TSpritelyMatrixSlot read FBestCamera;
    //** @abstract(Whether SetRenderToMatrix worked inside the frame.)
    property RenderToWorks: Boolean read FRenderToWorks;
    //** @abstract(Whether SetCameraMatrix with a shear worked inside the frame.)
    property ShearWorks: Boolean read FShearWorks;
    //** @abstract(Where log lines go.)
    property OnLog: TSpritelyLogProc read FOnLog write FOnLog;
  end;

//** @abstract(The name of a timing, for the log.)
//**
//** @param(ATiming The timing.)
//** @returns(The name.)
function TimingName(ATiming: TPeardoxTestTiming): string;

//** @abstract(The change for a projection: ShiftProjection.)
//**
//** @param(ASX Shift.)
//** @param(ASY Rise.)
//** @returns(The change.)
function ShiftAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;

//** @abstract(The change for a camera matrix: times ShearForShift of the context's projection.)
//**
//** @param(ASX Shift.)
//** @param(ASY Rise.)
//** @returns(The change.)
function ShearAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;

//** @abstract(The change for SetRenderToMatrix, for row vectors: ClipShift.)
//**
//** @param(ASX Shift.)
//** @param(ASY Rise.)
//** @returns(The change.)
function ClipRowsAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;

//** @abstract(The change for SetRenderToMatrix, for column vectors: ClipShift transposed.)
//**
//** @param(ASX Shift.)
//** @param(ASY Rise.)
//** @returns(The change.)
function ClipColumnsAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;

implementation

function TimingName(ATiming: TPeardoxTestTiming): string;
begin
  case ATiming of
    ttOnce: Result := 'written once';
    ttBeforeEachRender: Result := 'written before each frame';
    ttInRender: Result := 'written inside each frame (hook)';
  else
    Result := '?';
  end;
end;

function ShiftAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;
begin
  Result :=
    function(const AMatrix: TMatrix3D; AContext: TContext3D): TMatrix3D
    begin
      Result := TSpritelyProjectionAccess.ShiftProjection(AMatrix, ASX, ASY);
    end;
end;

function ShearAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;
begin
  Result :=
    function(const AMatrix: TMatrix3D; AContext: TContext3D): TMatrix3D
    begin
      if AContext = nil then
        Result := AMatrix
      else
        Result := AMatrix * TSpritelyProjectionAccess.ShearForShift(
          AContext.CurrentProjectionMatrix, ASX, ASY);
    end;
end;

function ClipRowsAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;
begin
  Result :=
    function(const AMatrix: TMatrix3D; AContext: TContext3D): TMatrix3D
    begin
      Result := AMatrix * TSpritelyProjectionAccess.ClipShift(ASX, ASY, True);
    end;
end;

function ClipColumnsAdjust(ASX, ASY: Single): TSpritelyMatrixAdjust;
begin
  Result :=
    function(const AMatrix: TMatrix3D; AContext: TContext3D): TMatrix3D
    begin
      Result := AMatrix * TSpritelyProjectionAccess.ClipShift(ASX, ASY, False);
    end;
end;

{ TPeardoxProjectionTester }

constructor TPeardoxProjectionTester.Create(AViewport: TGorillaViewport;
  AAccess: TSpritelyProjectionAccess);
begin
  inherited Create;
  FViewport := AViewport;
  FAccess := AAccess;
  FWorking := TStringList.Create;
  FOdd := TStringList.Create;
end;

destructor TPeardoxProjectionTester.Destroy;
begin
  FOdd.Free;
  FWorking.Free;
  inherited Destroy;
end;

procedure TPeardoxProjectionTester.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

function TPeardoxProjectionTester.Hooked: Integer;
begin
  if FAccess.Hook <> nil then
    Result := FAccess.Hook.Calls
  else
    Result := 0;
end;

function TPeardoxProjectionTester.Frame(const ABefore: TProc;
  ARenders: Integer): TPeardoxGreyPicture;
var
  Shot: TBitmap;
  Count, I: Integer;
begin
  // ProjTest1's log: MakeScreenshot shows the picture of the RenderManual
  // before the last, so a look is taken after two renders
  for I := 1 to ARenders do
  begin
    if Assigned(ABefore) then
      ABefore();
    Count := Hooked;
    FViewport.RenderManual;
    FRenderCalls := Hooked - Count;
  end;
  // MakeScreenshot may draw the frame again: the change goes in first again
  if Assigned(ABefore) then
    ABefore();
  Count := Hooked;
  Shot := FViewport.MakeScreenshot;
  try
    FShotCalls := Hooked - Count;
    Result := TPeardoxGreyPicture.FromBitmap(Shot);
  finally
    Shot.Free;
  end;
end;

function TPeardoxProjectionTester.GetterNote(ATarget: TSpritelyAdjustTarget;
  ASlot: TSpritelyMatrixSlot): string;
var
  Ctx: TContext3D;
begin
  Result := '';
  Ctx := FAccess.Context;
  if (Ctx = nil) or (ASlot = nil) then
    Exit;
  case ATarget of
    atProjectionSlot:
      if TSpritelyProjectionAccess.SameMatrix(Ctx.CurrentProjectionMatrix, ASlot.Read) then
        Result := 'CurrentProjectionMatrix returns the written value'
      else
        Result := 'CurrentProjectionMatrix does NOT return the written value';
    atCameraSlot:
      if TSpritelyProjectionAccess.SameMatrix(Ctx.CurrentCameraMatrix, ASlot.Read) then
        Result := 'CurrentCameraMatrix returns the written value'
      else
        Result := 'CurrentCameraMatrix does NOT return the written value';
  end;
end;

function TPeardoxProjectionTester.RunCase(const AName: string; ATarget: TSpritelyAdjustTarget;
  ASlot: TSpritelyMatrixSlot; ATiming: TPeardoxTestTiming; ASX, ASY: Single;
  const AAdjust: TSpritelyMatrixAdjust): TPeardoxShiftVerdict;
var
  Ref, First, Second, Back: TPeardoxGreyPicture;
  R1, R2: TPeardoxShiftResult;
  ExpectX, ExpectY, BackDiff: Single;
  Notes: string;
  Inverse: TSpritelyMatrixSlot;
begin
  Ref := Frame(nil);
  // + shift moves the picture right; + rise moves it up, which is - in
  // screen pixels (down is +)
  ExpectX := ASX * Ref.Width / 2;
  ExpectY := -ASY * Ref.Height / 2;
  Inverse := nil;
  if ATarget = atCameraSlot then
    Inverse := FAccess.InverseFor(ASlot);
  Notes := '';
  FAccess.SetAdjust(ATarget, ASlot, Inverse, AAdjust, ATiming = ttInRender);
  try
    case ATiming of
      ttOnce:
        begin
          FAccess.ApplyNow;
          Notes := GetterNote(ATarget, ASlot);
          First := Frame(nil);
          Second := Frame(nil);
        end;
      ttBeforeEachRender:
        begin
          First := Frame(FAccess.ApplyNow);
          Second := Frame(FAccess.ApplyNow);
        end;
    else
      begin
        First := Frame(nil);
        Second := Frame(nil);
      end;
    end;
    if ASlot <> nil then
    begin
      if Notes <> '' then
        Notes := Notes + '; ';
      Notes := Notes + 'the slot after the frames: ' + ASlot.State;
    end;
  finally
    FAccess.SetAdjust(atNone, nil, nil, nil, False);
    FAccess.RestoreAll;
  end;
  Back := Frame(nil);
  BackDiff := PictureDifference(Ref, Back);
  if Notes <> '' then
    Notes := Notes + '; ';
  if (BackDiff >= 0) and (BackDiff < PEARDOX_SHIFT_SAME) then
    Notes := Notes + 'put back'
  else
    Notes := Notes + Format('NOT PUT BACK (difference %.2f)', [BackDiff]);
  R1 := MeasureShift(Ref, First, ExpectX, ExpectY);
  R2 := MeasureShift(Ref, Second, ExpectX, ExpectY);
  Log('  ' + AName + ':');
  Log(Format('    after %d renders: %s', [PROJTEST_RENDERS_PER_LOOK, R1.Text]));
  Log(Format('    after %d renders: %s', [2 * PROJTEST_RENDERS_PER_LOOK, R2.Text]));
  Log('    ' + Notes);
  Result := R2.Verdict;
end;

function TPeardoxProjectionTester.RunBoth(const AName: string; ATarget: TSpritelyAdjustTarget;
  ASlot: TSpritelyMatrixSlot; ATiming: TPeardoxTestTiming;
  const AMaker: TSpritelyAdjustMaker): Boolean;
var
  Name: string;
  VX, VY: TPeardoxShiftVerdict;
begin
  Name := AName + ', ' + TimingName(ATiming);
  VX := RunCase(Name + ', shift right', ATarget, ASlot, ATiming, PROJTEST_SHIFT, 0,
    AMaker(PROJTEST_SHIFT, 0));
  Result := False;
  case VX of
    svNoPicture, svNoChange:
      Exit;
    svExpected, svWrongWay:
      begin
        VY := RunCase(Name + ', rise', ATarget, ASlot, ATiming, 0, PROJTEST_SHIFT,
          AMaker(0, PROJTEST_SHIFT));
        Result := (VX = svExpected) and (VY = svExpected);
        if Result then
          FWorking.Add(Name)
        else
          FOdd.Add(Format('%s (shift: %s; rise: %s)', [Name, VerdictName(VX), VerdictName(VY)]));
      end;
  else
    FOdd.Add(Format('%s (shift: %s)', [Name, VerdictName(VX)]));
  end;
end;

function TPeardoxProjectionTester.RunSlot(const AName: string; ATarget: TSpritelyAdjustTarget;
  ASlot: TSpritelyMatrixSlot; const AMaker: TSpritelyAdjustMaker;
  out ATiming: TPeardoxTestTiming): Boolean;
var
  T: TPeardoxTestTiming;
begin
  Result := False;
  ATiming := ttInRender;
  for T := Low(TPeardoxTestTiming) to High(TPeardoxTestTiming) do
    if RunBoth(AName, ATarget, ASlot, T, AMaker) and not Result then
    begin
      Result := True;
      ATiming := T;
    end;
end;

procedure TPeardoxProjectionTester.CheckScreenshotLag;
var
  S: TSpritelyMatrixSlot;
  Ref, One, Two: TPeardoxGreyPicture;
  R1, R2: TPeardoxShiftResult;
  ExpectX: Single;
begin
  S := FAccess.FirstSlot(mkProjection);
  if S = nil then
  begin
    Log('Screenshot lag: not checked (no projection found in memory)');
    Exit;
  end;
  Ref := Frame(nil);
  ExpectX := PROJTEST_SHIFT * Ref.Width / 2;
  FAccess.SetAdjust(atProjectionSlot, S, nil, ShiftAdjust(PROJTEST_SHIFT, 0), False);
  try
    FAccess.ApplyNow;
    One := Frame(nil, 1);
    Two := Frame(nil, 1);
  finally
    FAccess.SetAdjust(atNone, nil, nil, nil, False);
    FAccess.RestoreAll;
  end;
  Frame(nil);
  R1 := MeasureShift(Ref, One, ExpectX, 0);
  R2 := MeasureShift(Ref, Two, ExpectX, 0);
  Log('Screenshot lag: the projection shifted once, then a screenshot after each render');
  Log('  after 1 render:  ' + R1.Text);
  Log('  after 2 renders: ' + R2.Text);
  if (R1.Verdict = svNoChange) and (R2.Verdict = svExpected) then
    Log('  So: MAKESCREENSHOT IS ONE FRAME LATE - it shows the RenderManual before the last')
  else if R1.Verdict = svExpected then
    Log('  So: MakeScreenshot shows the last RenderManual')
  else
    Log('  So: unclear');
end;

procedure TPeardoxProjectionTester.LogSummary;
var
  S: string;
begin
  Log('=== RESULT ===');
  if FWorking.Count = 0 then
    Log('NOTHING SHIFTED AND ROSE THE PICTURE AS EXPECTED')
  else
    for S in FWorking do
      Log('  WORKS: ' + S);
  for S in FOdd do
    Log('  MOVED, NOT AS EXPECTED: ' + S);
  if FRenderToWorks then
    Log('So: the PUBLIC SetRenderToMatrix moves the picture - no private access is needed');
  if FShearWorks then
    Log('So: the PUBLIC SetCameraMatrix with a shear moves the picture (check the lighting)');
  if FBestProjection <> nil then
    Log(Format('So: the PROJECTION can be set, %s: %s', [TimingName(FBestProjectionTiming),
      FBestProjection.Describe]));
  if FBestCamera <> nil then
    Log('So: the camera matrix can be set in memory: ' + FBestCamera.Describe);
  Log('=== END OF PROJECTION TEST ===');
end;

procedure TPeardoxProjectionTester.Run(const AExtra: array of TObject);
var
  SavedManual, SavedFixed, SavedCulling, Worked: Boolean;
  Ref, Again: TPeardoxGreyPicture;
  S: TSpritelyMatrixSlot;
  Count: Integer;
  Timing: TPeardoxTestTiming;
  ContextName, CameraName: string;
begin
  FWorking.Clear;
  FOdd.Clear;
  FBestProjection := nil;
  FBestCamera := nil;
  FRenderToWorks := False;
  FShearWorks := False;
  Log('=== PROJECTION TEST ===');
  if FAccess.Context <> nil then
    ContextName := FAccess.Context.ClassName
  else
    ContextName := 'none';
  if FViewport.Camera <> nil then
    CameraName := FViewport.Camera.ClassName
  else
    CameraName := 'none';
  Log(Format('Viewport %s, %.0f x %.0f; context %s; camera %s', [FViewport.ClassName,
    FViewport.Width, FViewport.Height, ContextName, CameraName]));
  SavedManual := FViewport.ManualRendering;
  SavedFixed := FViewport.UseFixedFrameRate;
  SavedCulling := FViewport.FrustumCulling;
  FViewport.UseFixedFrameRate := False;
  FViewport.ManualRendering := True;
  // The hook is small; culling must not leave it out
  FViewport.FrustumCulling := False;
  try
    FAccess.Survey(
      procedure
      begin
        FViewport.RenderManual;
      end, AExtra);
    FAccess.LogSurvey;
    Ref := Frame(nil);
    if not Ref.Valid then
    begin
      Log('NO PICTURE from MakeScreenshot: nothing can be measured');
      Exit;
    end;
    Again := Frame(nil);
    Log(Format('Picture %d x %d; the hook was drawn %d time(s) by RenderManual and %d by ' +
      'MakeScreenshot; two frames in a row differ by %.3f', [Ref.Width, Ref.Height,
      FRenderCalls, FShotCalls, PictureDifference(Ref, Again)]));
    if PictureDifference(Ref, Again) >= PEARDOX_SHIFT_SAME then
      Log('WARNING: two frames in a row differ (an animation?), so the measures are rough');
    Log(Format('Each way moves the picture %.2f of its half-width right (expect %.0f px), ' +
      'then, if it moved, %.2f of its half-height up (expect %.0f px up)', [PROJTEST_SHIFT,
      PROJTEST_SHIFT * Ref.Width / 2, PROJTEST_SHIFT, PROJTEST_SHIFT * Ref.Height / 2]));

    CheckScreenshotLag;
    Log('--- 1. Public: the context''s SetRenderToMatrix ---');
    RunBoth('SetRenderToMatrix (row vectors)', atRenderToMatrix, nil, ttOnce, ClipRowsAdjust);
    RunBoth('SetRenderToMatrix (row vectors)', atRenderToMatrix, nil, ttBeforeEachRender,
      ClipRowsAdjust);
    FRenderToWorks := RunBoth('SetRenderToMatrix (row vectors)', atRenderToMatrix, nil,
      ttInRender, ClipRowsAdjust);
    Worked := RunBoth('SetRenderToMatrix (column vectors)', atRenderToMatrix, nil, ttInRender,
      ClipColumnsAdjust);
    FRenderToWorks := FRenderToWorks or Worked;

    Log('--- 2. Public: SetCameraMatrix with a shear (LenticularDemoFMX''s way) ---');
    RunBoth('SetCameraMatrix shear', atSetCameraMatrix, nil, ttBeforeEachRender, ShearAdjust);
    FShearWorks := RunBoth('SetCameraMatrix shear', atSetCameraMatrix, nil, ttInRender,
      ShearAdjust);

    Log('--- 3. The projection matrices found in memory ---');
    Count := 0;
    for S in FAccess.Slots do
      if (S.Kind in [mkProjection, mkProjectionLike]) and
        (Count < PROJTEST_MAX_PROJECTION_SLOTS) then
      begin
        Inc(Count);
        Log(Format('Projection P%d: %s', [Count, S.Describe]));
        if RunSlot(Format('P%d', [Count]), atProjectionSlot, S, ShiftAdjust, Timing) and
          (FBestProjection = nil) then
        begin
          FBestProjection := S;
          FBestProjectionTiming := Timing;
        end;
      end;
    if Count = 0 then
      Log('  (none found)');

    Log('--- 4. The camera matrices found in memory, with a shear ---');
    Count := 0;
    for S in FAccess.Slots do
      if (S.Kind = mkCamera) and (Count < PROJTEST_MAX_CAMERA_SLOTS) then
      begin
        Inc(Count);
        if FAccess.InverseFor(S) <> nil then
          Log(Format('Camera V%d: %s; its inverse is written too', [Count, S.Describe]))
        else
          Log(Format('Camera V%d: %s', [Count, S.Describe]));
        if RunSlot(Format('V%d', [Count]), atCameraSlot, S, ShearAdjust, Timing) and
          (FBestCamera = nil) then
          FBestCamera := S;
      end;
    if Count = 0 then
      Log('  (none found)');
    LogSummary;
  finally
    FAccess.SetAdjust(atNone, nil, nil, nil, False);
    FAccess.RestoreAll;
    FViewport.FrustumCulling := SavedCulling;
    FViewport.ManualRendering := SavedManual;
    FViewport.UseFixedFrameRate := SavedFixed;
  end;
end;

end.
