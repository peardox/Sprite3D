//** @abstract(ProjectionTest's form: a Gorilla3D view of a test model, the projection test
//** (Run test, also once by itself after the model loads), and TSpritelyProjection live.)
//**
//** The test (TPeardoxProjectionTester) finds the matrices FMX draws with and tries every way
//** of moving the picture across the lens, measuring each; its log is in the memo on the right
//** and in ProjectionTest.log beside the executable.
//**
//** Live, the component TSpritelyProjection (made in code here, as a new component is first)
//** draws the view: the projection box (perspective, orthographic, cavalier, cabinet,
//** military, oblique), the Angle and Depth sliders for the free oblique, the Lens slider
//** with Dolly (the dolly zoom), and the Shift and Rise sliders. It is the orbit camera's
//** Projection, so Fit frames the model in the projection actually drawn. Front gives the
//** front view, level, which is also the start view. The model box lists the models in the
//** models folder (DollyHallway.glb for the dolly zoom); Open loads any other.
unit ProjectionTestMain;

{
  ProjectionTest's form: a Gorilla3D view of a test model through the
  Spritely orbital camera, the projection test (button, and once by itself
  after the model loads), and TSpritelyProjection live: projection, oblique
  angle and depth, lens with the dolly zoom, shift and rise; Fit frames in
  the projection drawn. Models from the models folder or Open. The log goes
  to the memo and to ProjectionTest.log.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Math.Vectors, System.IOUtils,
  FMX.Types, FMX.Types3D, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo,
  Gorilla.Viewport, Gorilla.Camera, Gorilla.Model, Gorilla.GLB.Loader, Gorilla.GLTF.Loader,
  Gorilla.FBX.Loader, Gorilla.OBJ.Loader,
  Spritely.OrbitalCamera, Spritely.Projection, ProjectionTestMeasure, ProjectionTestRunner;

type
  //** @abstract(The form: the view, the log, the test button and the live controls.)
  TPeardoxProjectionTestForm = class(TForm)
    //** @abstract(Holds the view; fills the form left of the log and above the controls.)
    ViewLayout: TLayout;
    //** @abstract(The Gorilla3D viewport, seen through SpritelyOrbitalCamera1's camera.)
    GorillaViewport1: TGorillaViewport;
    //** @abstract(The log, also written to ProjectionTest.log.)
    LogMemo: TMemo;
    //** @abstract(The strip of controls along the bottom.)
    ControlLayout: TLayout;
    //** @abstract(Runs the projection test.)
    btnRunTest: TButton;
    //** @abstract(The models in the models folder; choosing one loads it.)
    ModelBox: TComboBox;
    //** @abstract(Loads a model from anywhere.)
    btnOpen: TButton;
    //** @abstract(Frames the model in the projection drawn (FitToBounds).)
    btnFit: TButton;
    //** @abstract(The front view: azimuth, inclination and roll 0, the target on the model's
    //** centre (its depth against the target 0), framed for every angle; the start view.)
    btnFront: TButton;
    //** @abstract(Labels ShiftTrack.)
    ShiftLabel: TLabel;
    //** @abstract(Shift: the picture moved right (+) or left, -0.5 to 0.5 of the half-width.)
    ShiftTrack: TTrackBar;
    //** @abstract(Labels RiseTrack.)
    RiseLabel: TLabel;
    //** @abstract(Rise: the picture moved up (+) or down, -0.5 to 0.5 of the half-height.)
    RiseTrack: TTrackBar;
    //** @abstract(Puts the shift and rise back to nought.)
    btnCentre: TButton;
    //** @abstract(TSpritelyProjection's Active: off, FMX's own projection is drawn.)
    ActiveCheck: TCheckBox;
    //** @abstract(Free Movement: ticked, the camera may go anywhere, into the model too (it is
    //** no longer the orbit camera's Subject); unticked, it is kept outside the model's box.)
    FreeCheck: TCheckBox;
    //** @abstract(Chooses the projection: perspective, orthographic or an oblique one. The
    //** control strip is at the top of the form so the list opens downwards: at the bottom of
    //** a full-screen window FMX opened it far above the box.)
    KindBox: TComboBox;
    //** @abstract(Labels AngleTrack.)
    AngleLabel: TLabel;
    //** @abstract(The free oblique: the direction depth is drawn in, 0 to 360 degrees, 0 right,
    //** 90 up.)
    AngleTrack: TTrackBar;
    //** @abstract(Labels DepthTrack.)
    DepthLabel: TLabel;
    //** @abstract(The free oblique: how long depth is drawn, 0 to 1 of its true length.)
    DepthTrack: TTrackBar;
    //** @abstract(Labels LensTrack.)
    LensLabel: TLabel;
    //** @abstract(The lens: the vertical field of view drawn with, 5 to 120 degrees.)
    LensTrack: TTrackBar;
    //** @abstract(TSpritelyProjection's Dolly: a lens change moves the camera too, keeping the
    //** target plane's size - the dolly zoom.)
    DollyCheck: TCheckBox;
    //** @abstract(The last log line.)
    StatusLabel: TLabel;
    //** @abstract(The orbit camera the view is seen through.)
    SpritelyOrbitalCamera1: TSpritelyOrbitalCamera;
    //** @abstract(Makes the projection, the access, the tester and the timers, wires the
    //** controls and opens the log.)
    //**
    //** @param(Sender The form.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Starts the timer that loads the model once the form is up.)
    //**
    //** @param(Sender The form.)
    procedure FormShow(Sender: TObject);
    //** @abstract(Puts FMX's projection back, frees the tester and closes the log.)
    //**
    //** @param(Sender The form.)
    //** @param(Action Left as it is.)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    //** @abstract(The component under test: draws the live view.)
    FProjection: TSpritelyProjection;
    //** @abstract(Finds and changes the matrices for the test.)
    FAccess: TSpritelyProjectionAccess;
    //** @abstract(Runs the test.)
    FTester: TPeardoxProjectionTester;
    //** @abstract(The model shown, or nil.)
    FModel: TGorillaModel;
    //** @abstract(The models folder found, or empty.)
    FModelFolder: string;
    //** @abstract(Loads the model a moment after the form shows; once.)
    FStartTimer: TTimer;
    //** @abstract(Runs the test once by itself after the first model loads.)
    FAutoTestTimer: TTimer;
    //** @abstract(Logs what the projection is doing, every LIVE_REPORT_MS.)
    FReportTimer: TTimer;
    //** @abstract(The projection's frame count at the last report.)
    FReportFrames: Int64;
    //** @abstract(True while the controls are set from code, so their handlers do nothing.)
    FSetting: Boolean;
    //** @abstract(True while a left drag orbits.)
    FDragging: Boolean;
    //** @abstract(Where the mouse was at the last step of the drag.)
    FDragLast: TPointF;
    //** @abstract(True while the test runs, so it is not started twice.)
    FTesting: Boolean;
    //** @abstract(The log file; nil if it could not be made.)
    FLogWriter: TStreamWriter;
    //** @abstract(Opens ProjectionTest.log, keeping the last run's as ProjectionTest.prev.log.)
    procedure LogOpen;
    //** @abstract(Ends and closes the log.)
    procedure LogClose;
    //** @abstract(Adds a line to the memo, the log file and the status line.)
    //**
    //** @param(AText The line.)
    procedure LogLine(const AText: string);
    //** @abstract(TSpritelyProjection's OnLog: its lines into the log.)
    //**
    //** @param(Sender The projection.)
    //** @param(AText The line.)
    procedure ProjectionLog(Sender: TObject; const AText: string);
    //** @abstract(Finds the models folder, fills ModelBox and loads the test model.)
    //**
    //** @param(Sender The timer.)
    procedure StartTick(Sender: TObject);
    //** @abstract(Runs the test once, after the first model has loaded.)
    //**
    //** @param(Sender The timer.)
    procedure AutoTestTick(Sender: TObject);
    //** @abstract(Logs the projection's state and frames drawn.)
    //**
    //** @param(Sender The timer.)
    procedure ReportTick(Sender: TObject);
    //** @abstract(Finds the models folder beside the executable or in one of the folders above
    //** it.)
    //**
    //** @returns(Its path, or empty.)
    function FindModelFolder: string;
    //** @abstract(Lists the models in FModelFolder in ModelBox.)
    procedure FillModels;
    //** @abstract(Loads a model in place of the one shown and frames it.)
    //**
    //** @param(APath The file.)
    //** @returns(True if it loaded.)
    function LoadModel(const APath: string): Boolean;
    //** @abstract(Gives the test's hook the model's place and size, so it is not culled.)
    procedure PlaceHook;
    //** @abstract(Runs the projection test, the component off meanwhile.)
    procedure RunTest;
    //** @abstract(Sets the controls from the projection's values.)
    procedure ShowValues;
    //** @abstract(Run test: runs the projection test.)
    //**
    //** @param(Sender The button.)
    procedure RunTestClick(Sender: TObject);
    //** @abstract(A model chosen in ModelBox: loads it.)
    //**
    //** @param(Sender The box.)
    procedure ModelChange(Sender: TObject);
    //** @abstract(Open: loads a model chosen in a file dialog.)
    //**
    //** @param(Sender The button.)
    procedure OpenClick(Sender: TObject);
    //** @abstract(Fit: frames the model for the present angles, in the projection drawn.)
    //**
    //** @param(Sender The button.)
    procedure FitClick(Sender: TObject);
    //** @abstract(The front view, as btnFront: azimuth, inclination and roll 0, the target
    //** on the model's centre, framed for every angle.)
    procedure FrontView;
    //** @abstract(Front: the front view.)
    //**
    //** @param(Sender The button.)
    procedure FrontClick(Sender: TObject);
    //** @abstract(Centre: the shift and rise back to nought.)
    //**
    //** @param(Sender The button.)
    procedure CentreClick(Sender: TObject);
    //** @abstract(Active ticked or not.)
    //**
    //** @param(Sender The box.)
    procedure ActiveChange(Sender: TObject);
    //** @abstract(Free Movement ticked or not: the orbit camera's Subject is nil while
    //** ticked, the model again when not.)
    //**
    //** @param(Sender The box.)
    procedure FreeChange(Sender: TObject);
    //** @abstract(Whether the camera is kept outside the model: Free Movement not ticked.)
    //**
    //** @returns(The model to keep the camera out of, or nil.)
    function SubjectWanted: TGorillaModel;
    //** @abstract(Dolly ticked or not.)
    //**
    //** @param(Sender The box.)
    procedure DollyChange(Sender: TObject);
    //** @abstract(A projection chosen; the component turns the camera to the kind's preset
    //** angles, if it has them (TSpritelyProjection.CameraPreset, PresetAngles).)
    //**
    //** @param(Sender The box.)
    procedure KindChange(Sender: TObject);
    //** @abstract(A slider moved: shift, rise, the free oblique's angle and depth.)
    //**
    //** @param(Sender The slider.)
    procedure TrackChange(Sender: TObject);
    //** @abstract(The lens slider moved: the projection's FieldOfView, which with Dolly moves
    //** the camera.)
    //**
    //** @param(Sender The slider.)
    procedure LensChange(Sender: TObject);
    //** @abstract(The view changed size: the test's survey is out of date.)
    //**
    //** @param(Sender The viewport.)
    procedure ViewResized(Sender: TObject);
    //** @abstract(A left button press starts an orbit drag.)
    //**
    //** @param(Sender The viewport.)
    //** @param(Button The button.)
    //** @param(Shift The keys and buttons held.)
    //** @param(X Where across.)
    //** @param(Y Where down.)
    procedure ViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Orbits while the left button is held.)
    //**
    //** @param(Sender The viewport.)
    //** @param(Shift The keys and buttons held.)
    //** @param(X Where across.)
    //** @param(Y Where down.)
    procedure ViewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    //** @abstract(Ends the drag.)
    //**
    //** @param(Sender The viewport.)
    //** @param(Button The button.)
    //** @param(Shift The keys and buttons held.)
    //** @param(X Where across.)
    //** @param(Y Where down.)
    procedure ViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    //** @abstract(Zooms: the wheel away brings the view nearer.)
    //**
    //** @param(Sender The viewport.)
    //** @param(Shift The keys and buttons held.)
    //** @param(WheelDelta How far the wheel turned, 120 a notch.)
    //** @param(Handled Set True.)
    procedure ViewMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean);
  end;

var
  //** @abstract(The form, made by the program.)
  PeardoxProjectionTestForm: TPeardoxProjectionTestForm;

implementation

{$R *.fmx}

const
  //** @abstract(The test model; DemoScene's spheres and cubes give the measure plenty of
  //** edges.)
  TEST_MODEL = 'DemoSceneNoWall.glb';
  //** @abstract(Loaded if TEST_MODEL is not found.)
  FALLBACK_MODEL = 'uvcube.glb';
  //** @abstract(The folder the models are in.)
  MODEL_FOLDER = 'models';
  //** @abstract(The model files listed in ModelBox and offered by Open.)
  MODEL_MASKS: array[0..3] of string = ('*.glb', '*.gltf', '*.fbx', '*.obj');
  //** @abstract(Open's filter.)
  MODEL_FILTER = 'Models (*.glb;*.gltf;*.fbx;*.obj)|*.glb;*.gltf;*.fbx;*.obj|All files|*.*';
  //** @abstract(How many folders above the executable are searched for MODEL_FOLDER.)
  FOLDERS_UP = 5;
  //** @abstract(The turn about X that stands a glTF model up in FMX, as in StereoModel.)
  MODEL_TURN_X = 180;
  //** @abstract(The margin round the model when it is framed.)
  VIEW_MARGIN = 0.08;
  //** @abstract(The front view's azimuth (owner, 8 November 2026: also the start view).)
  FRONT_AZIMUTH = 0;
  //** @abstract(The front view's inclination: level.)
  FRONT_POLAR = 0;
  //** @abstract(Degrees of orbit per pixel dragged.)
  ORBIT_DEGREES_PER_PIXEL = 0.5;
  //** @abstract(How much one wheel notch changes the distance.)
  ZOOM_STEP = 1.1;
  //** @abstract(A wheel notch.)
  WHEEL_NOTCH = 120;
  //** @abstract(The shift and rise sliders' range each way, in hundredths of normalised device
  //** units.)
  TRACK_RANGE = 50;
  //** @abstract(The lens slider's range, degrees.)
  LENS_MIN = 5;
  //** @abstract(The lens slider's range, degrees.)
  LENS_MAX = 120;
  //** @abstract(The log's file name.)
  LOG_FILE = 'ProjectionTest.log';
  //** @abstract(The last run's log, kept beside it.)
  PREV_LOG_FILE = 'ProjectionTest.prev.log';
  //** @abstract(The smallest size given to the test's hook each way.)
  HOOK_MIN_SIZE = 0.01;
  //** @abstract(Milliseconds after the form shows before the model loads.)
  START_DELAY_MS = 100;
  //** @abstract(Milliseconds after the model loads before the test runs by itself, when
  //** AUTO_TEST is True.)
  AUTO_TEST_DELAY_MS = 1500;
  //** @abstract(Whether the projection test runs by itself after the first model loads.
  //** False since ProjComp5 (owner, 8 November 2026: what the test showed is settled, and
  //** TSpritelyProjection is the way); Run test still runs it, and True brings it back.)
  AUTO_TEST = False;
  //** @abstract(Milliseconds between live reports in the log.)
  LIVE_REPORT_MS = 2000;
  //** @abstract(The projections' names in KindBox, in TSpritelyProjectionKind's order.)
  KIND_NAMES: array[TSpritelyProjectionKind] of string = (
    'Projection: perspective',
    'Projection: orthographic',
    'Projection: cavalier (1, 45 deg)',
    'Projection: cabinet (0.5, 63.4 deg)',
    'Projection: military (1, 270 deg, from above)',
    'Projection: plan oblique (1, 315 deg, from above)',
    'Projection: true isometric (orthographic, 45 / 35.26 deg)',
    'Projection: 2:1 dimetric (orthographic, 45 / 30 deg)',
    'Projection: trimetric (orthographic, 35 / 45 deg)',
    'Projection: oblique (Angle, Depth)');

procedure TPeardoxProjectionTestForm.FormCreate(Sender: TObject);
var
  K: TSpritelyProjectionKind;
begin
  LogOpen;
  Caption := 'ProjectionTest';
  LogMemo.ReadOnly := True;
  LogMemo.StyledSettings := LogMemo.StyledSettings - [TStyledSetting.Family, TStyledSetting.Size];
  LogMemo.TextSettings.Font.Family := 'Consolas';
  LogMemo.TextSettings.Font.Size := 11;
  // The component under test, made in code first; the orbit camera's
  // Projection, so it gives the target distance, takes part in the dolly
  // zoom and its fits follow what is drawn
  FProjection := TSpritelyProjection.Create(Self);
  FProjection.OnLog := ProjectionLog;
  FProjection.Viewport := GorillaViewport1;
  SpritelyOrbitalCamera1.Projection := FProjection;
  // The test's own access, for the survey and measures
  FAccess := TSpritelyProjectionAccess.Create(Self, GorillaViewport1);
  FAccess.OnLog := LogLine;
  FTester := TPeardoxProjectionTester.Create(GorillaViewport1, FAccess);
  FTester.OnLog := LogLine;
  FStartTimer := TTimer.Create(Self);
  FStartTimer.Enabled := False;
  FStartTimer.Interval := START_DELAY_MS;
  FStartTimer.OnTimer := StartTick;
  FAutoTestTimer := TTimer.Create(Self);
  FAutoTestTimer.Enabled := False;
  FAutoTestTimer.Interval := AUTO_TEST_DELAY_MS;
  FAutoTestTimer.OnTimer := AutoTestTick;
  FReportTimer := TTimer.Create(Self);
  FReportTimer.Enabled := True;
  FReportTimer.Interval := LIVE_REPORT_MS;
  FReportTimer.OnTimer := ReportTick;
  FSetting := True;
  try
    KindBox.Items.Clear;
    for K := Low(TSpritelyProjectionKind) to High(TSpritelyProjectionKind) do
      KindBox.Items.Add(KIND_NAMES[K]);
    ShiftTrack.Min := -TRACK_RANGE;
    ShiftTrack.Max := TRACK_RANGE;
    RiseTrack.Min := -TRACK_RANGE;
    RiseTrack.Max := TRACK_RANGE;
    AngleTrack.Min := 0;
    AngleTrack.Max := 360;
    DepthTrack.Min := 0;
    DepthTrack.Max := 100;
    LensTrack.Min := LENS_MIN;
    LensTrack.Max := LENS_MAX;
  finally
    FSetting := False;
  end;
  ShowValues;
  btnRunTest.OnClick := RunTestClick;
  btnOpen.OnClick := OpenClick;
  btnFit.OnClick := FitClick;
  btnFront.OnClick := FrontClick;
  btnCentre.OnClick := CentreClick;
  ModelBox.OnChange := ModelChange;
  ActiveCheck.OnChange := ActiveChange;
  DollyCheck.OnChange := DollyChange;
  FreeCheck.OnChange := FreeChange;
  KindBox.OnChange := KindChange;
  ShiftTrack.OnChange := TrackChange;
  RiseTrack.OnChange := TrackChange;
  AngleTrack.OnChange := TrackChange;
  DepthTrack.OnChange := TrackChange;
  LensTrack.OnChange := LensChange;
  GorillaViewport1.OnResize := ViewResized;
  GorillaViewport1.OnMouseDown := ViewMouseDown;
  GorillaViewport1.OnMouseMove := ViewMouseMove;
  GorillaViewport1.OnMouseUp := ViewMouseUp;
  GorillaViewport1.OnMouseWheel := ViewMouseWheel;
end;

procedure TPeardoxProjectionTestForm.FormShow(Sender: TObject);
begin
  FStartTimer.Enabled := True;
end;

procedure TPeardoxProjectionTestForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FStartTimer.Enabled := False;
  FAutoTestTimer.Enabled := False;
  FReportTimer.Enabled := False;
  // FMX's own projection back while the context is there
  if FProjection <> nil then
    FProjection.Active := False;
  if FAccess <> nil then
  begin
    FAccess.SetAdjust(atNone, nil, nil, nil, False);
    FAccess.RestoreAll;
  end;
  FreeAndNil(FTester);
  // The projection and the test's access taken down here, while the form,
  // viewport, context and camera are all whole, not left to the form's
  // destruction (an access violation on exit, owner, 8 November 2026,
  // came after this log was closed); each step logged
  if FProjection <> nil then
  begin
    SpritelyOrbitalCamera1.Projection := nil;
    FreeAndNil(FProjection);
    LogLine('Projection component freed');
  end;
  FreeAndNil(FAccess);
  LogLine('Projection access freed');
  LogClose;
end;

procedure TPeardoxProjectionTestForm.LogOpen;
var
  Folder, Path, Prev: string;
begin
  if FLogWriter <> nil then
    Exit;
  {$IF DEFINED(MSWINDOWS) or (DEFINED(LINUX) and not DEFINED(ANDROID))}
  Folder := ExtractFileDir(ExpandFileName(ParamStr(0)));
  {$ELSE}
  Folder := System.IOUtils.TPath.GetDocumentsPath;
  {$ENDIF}
  Path := System.IOUtils.TPath.Combine(Folder, LOG_FILE);
  Prev := System.IOUtils.TPath.Combine(Folder, PREV_LOG_FILE);
  try
    if TFile.Exists(Path) then
    begin
      if TFile.Exists(Prev) then
        TFile.Delete(Prev);
      TFile.Move(Path, Prev);
    end;
    FLogWriter := TStreamWriter.Create(Path, False, TEncoding.UTF8);
    FLogWriter.AutoFlush := True;
  except
    FLogWriter := nil;
  end;
  LogLine(Format('ProjectionTest started %s, %d-bit, %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss',
    Now), SizeOf(Pointer) * 8, TOSVersion.ToString]));
end;

procedure TPeardoxProjectionTestForm.LogClose;
begin
  if FLogWriter = nil then
    Exit;
  FLogWriter.WriteLine(FormatDateTime('hh:nn:ss.zzz', Now) + ' Log closed normally');
  FreeAndNil(FLogWriter);
end;

procedure TPeardoxProjectionTestForm.LogLine(const AText: string);
begin
  if FLogWriter <> nil then
    FLogWriter.WriteLine(FormatDateTime('hh:nn:ss.zzz', Now) + ' ' + AText);
  if LogMemo <> nil then
  begin
    LogMemo.Lines.Add(AText);
    // To the last line, then to its start, so a long line does not leave
    // the memo scrolled sideways
    LogMemo.GoToTextEnd;
    LogMemo.GoToLineBegin;
  end;
  if StatusLabel <> nil then
    StatusLabel.Text := AText;
end;

procedure TPeardoxProjectionTestForm.ProjectionLog(Sender: TObject; const AText: string);
begin
  LogLine('TSpritelyProjection: ' + AText);
end;

function TPeardoxProjectionTestForm.FindModelFolder: string;
var
  Dir, UpDir, Candidate: string;
  I: Integer;
begin
  Result := '';
  Dir := ExtractFileDir(ExpandFileName(ParamStr(0)));
  for I := 0 to FOLDERS_UP do
  begin
    Candidate := System.IOUtils.TPath.Combine(Dir, MODEL_FOLDER);
    if TDirectory.Exists(Candidate) then
      Exit(Candidate);
    UpDir := ExtractFileDir(Dir);
    if (UpDir = '') or (UpDir = Dir) then
      Break;
    Dir := UpDir;
  end;
end;

procedure TPeardoxProjectionTestForm.FillModels;
var
  Names: TStringList;
  Mask, F: string;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := TDuplicates.dupIgnore;
    if FModelFolder <> '' then
      for Mask in MODEL_MASKS do
        for F in TDirectory.GetFiles(FModelFolder, Mask) do
          Names.Add(ExtractFileName(F));
    FSetting := True;
    try
      ModelBox.Items.Assign(Names);
      ModelBox.ItemIndex := -1;
    finally
      FSetting := False;
    end;
  finally
    Names.Free;
  end;
end;

function TPeardoxProjectionTestForm.LoadModel(const APath: string): Boolean;
var
  NewModel: TGorillaModel;
  Box: TBoundingBox;
  KeepDolly: Boolean;
begin
  Result := False;
  // Made here and loaded with LoadFromFile, as StereoModel does (Gorilla3D
  // 1.5.3's LoadNewModelFromFile leaks the FBX loader's parse tree)
  NewModel := TGorillaModel.Create(GorillaViewport1);
  try
    NewModel.Parent := GorillaViewport1;
    NewModel.LoadFromFile(nil, APath, []);
  except
    on E: Exception do
    begin
      NewModel.Parent := nil;
      NewModel.Free;
      LogLine(Format('Model load FAILED: %s: %s: %s', [APath, E.ClassName, E.Message]));
      Exit;
    end;
  end;
  FModel.Free;
  FModel := NewModel;
  // As StereoModel's PlaceModel: placed by its own bounds, then stood up
  Box := FModel.GetBoundingBox;
  FModel.Position.Point := Point3D(Box.TopLeftNear.X + (Box.Width / 2),
    Box.TopLeftNear.Y + (Box.Height / 2), Box.TopLeftNear.Z + (Box.Depth / 2));
  FModel.RotationAngle.X := MODEL_TURN_X;
  SpritelyOrbitalCamera1.Subject := SubjectWanted;
  // The camera's own lens again (without a dolly: the fit below sets the
  // distance), then the front view, the start view
  KeepDolly := FProjection.Dolly;
  FProjection.Dolly := False;
  FProjection.FieldOfView := 0;
  FProjection.Dolly := KeepDolly;
  FrontView;
  PlaceHook;
  ShowValues;
  LogLine(Format('Loaded %s; distance %.2f', [APath, SpritelyOrbitalCamera1.Distance]));
  Result := True;
end;

//** @abstract(A size, kept above nought so the hook is never empty.)
//**
//** @param(ASize The size.)
//** @returns(ASize, or HOOK_MIN_SIZE if smaller.)
function AtLeast(ASize: Single): Single;
begin
  Result := ASize;
  if Result < HOOK_MIN_SIZE then
    Result := HOOK_MIN_SIZE;
end;

procedure TPeardoxProjectionTestForm.PlaceHook;
var
  Box: TBoundingBox;
begin
  if (FAccess = nil) or (FAccess.Hook = nil) or (FModel = nil) then
    Exit;
  Box := FModel.GetAbsoluteBoundingBox;
  FAccess.Hook.Position.Point := Box.CenterPoint;
  FAccess.Hook.Width := AtLeast(Box.Width);
  FAccess.Hook.Height := AtLeast(Box.Height);
  FAccess.Hook.Depth := AtLeast(Box.Depth);
end;

procedure TPeardoxProjectionTestForm.StartTick(Sender: TObject);
var
  Path: string;
begin
  FStartTimer.Enabled := False;
  FModelFolder := FindModelFolder;
  FillModels;
  if FModelFolder = '' then
  begin
    LogLine(Format('No %s folder beside the program or above it: use Open', [MODEL_FOLDER]));
    Exit;
  end;
  Path := System.IOUtils.TPath.Combine(FModelFolder, TEST_MODEL);
  if not TFile.Exists(Path) then
    Path := System.IOUtils.TPath.Combine(FModelFolder, FALLBACK_MODEL);
  if not TFile.Exists(Path) then
  begin
    LogLine(Format('Neither %s nor %s in %s: choose a model', [TEST_MODEL, FALLBACK_MODEL,
      FModelFolder]));
    Exit;
  end;
  FSetting := True;
  try
    ModelBox.ItemIndex := ModelBox.Items.IndexOf(ExtractFileName(Path));
  finally
    FSetting := False;
  end;
  if LoadModel(Path) and AUTO_TEST then
    FAutoTestTimer.Enabled := True;
end;

procedure TPeardoxProjectionTestForm.AutoTestTick(Sender: TObject);
begin
  FAutoTestTimer.Enabled := False;
  RunTest;
end;

procedure TPeardoxProjectionTestForm.ReportTick(Sender: TObject);
var
  Frames: Int64;
begin
  if (FProjection = nil) or FTesting then
    Exit;
  Frames := FProjection.Frames - FReportFrames;
  FReportFrames := FProjection.Frames;
  // Only while something is changed, so an idle log stays quiet
  if (Frames = 0) and (FProjection.Kind = pjPerspective) and (FProjection.FieldOfView = 0) and
    (FProjection.ShiftX = 0) and (FProjection.ShiftY = 0) then
    Exit;
  LogLine(Format('Live: %s, angle %.0f, depth %.2f; lens %.1f deg, camera distance %.2f; ' +
    'shift %.2f, rise %.2f; active %s; written in %d frame(s) in %.0f s; projection found %s',
    [KIND_NAMES[FProjection.Kind], FProjection.ObliqueAngle, FProjection.ObliqueScale,
     FProjection.EffectiveFieldOfView, SpritelyOrbitalCamera1.Distance, FProjection.ShiftX,
     FProjection.ShiftY, BoolToStr(FProjection.Active, True), Frames, LIVE_REPORT_MS / 1000,
     BoolToStr(FProjection.Found, True)]));
end;

procedure TPeardoxProjectionTestForm.ShowValues;
begin
  FSetting := True;
  try
    ActiveCheck.IsChecked := FProjection.Active;
    DollyCheck.IsChecked := FProjection.Dolly;
    KindBox.ItemIndex := Ord(FProjection.Kind);
    ShiftTrack.Value := FProjection.ShiftX * 100;
    RiseTrack.Value := FProjection.ShiftY * 100;
    AngleTrack.Value := FProjection.ObliqueAngle;
    DepthTrack.Value := FProjection.ObliqueScale * 100;
    LensTrack.Value := FProjection.EffectiveFieldOfView;
  finally
    FSetting := False;
  end;
  ShiftLabel.Text := Format('Shift %.2f', [FProjection.ShiftX]);
  RiseLabel.Text := Format('Rise %.2f', [FProjection.ShiftY]);
  AngleLabel.Text := Format('Angle %.0f', [FProjection.ObliqueAngle]);
  DepthLabel.Text := Format('Depth %.2f', [FProjection.ObliqueScale]);
  LensLabel.Text := Format('Lens %.0f', [FProjection.EffectiveFieldOfView]);
end;

procedure TPeardoxProjectionTestForm.RunTest;
var
  WasActive: Boolean;
begin
  if FTesting or (FModel = nil) then
    Exit;
  FTesting := True;
  WasActive := FProjection.Active;
  try
    // The component off, FMX's own projection back: the test writes its own
    FProjection.Active := False;
    FTester.Run([GorillaViewport1.Camera, SpritelyOrbitalCamera1.Camera]);
  finally
    FProjection.Active := WasActive;
    FTesting := False;
  end;
end;

procedure TPeardoxProjectionTestForm.RunTestClick(Sender: TObject);
begin
  RunTest;
end;

procedure TPeardoxProjectionTestForm.ModelChange(Sender: TObject);
begin
  if FSetting or (ModelBox.ItemIndex < 0) or (FModelFolder = '') then
    Exit;
  LoadModel(System.IOUtils.TPath.Combine(FModelFolder, ModelBox.Items[ModelBox.ItemIndex]));
end;

procedure TPeardoxProjectionTestForm.OpenClick(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Filter := MODEL_FILTER;
    if FModelFolder <> '' then
      Dialog.InitialDir := FModelFolder;
    Dialog.Options := Dialog.Options + [TOpenOption.ofFileMustExist];
    if Dialog.Execute and LoadModel(Dialog.FileName) then
    begin
      FSetting := True;
      try
        ModelBox.ItemIndex := ModelBox.Items.IndexOf(ExtractFileName(Dialog.FileName));
      finally
        FSetting := False;
      end;
    end;
  finally
    Dialog.Free;
  end;
end;

procedure TPeardoxProjectionTestForm.FitClick(Sender: TObject);
begin
  if FModel = nil then
    Exit;
  // FitToBounds, not the every-angle fit: as tight as the present angles,
  // lens, shift and projection allow, so following the projection shows
  if SpritelyOrbitalCamera1.FitToBounds(FModel, VIEW_MARGIN) then
    LogLine(Format('Fit: %s, lens %.1f deg, shift %.2f, rise %.2f: distance %.2f',
      [KIND_NAMES[FProjection.Kind], FProjection.EffectiveFieldOfView, FProjection.ShiftX,
       FProjection.ShiftY, SpritelyOrbitalCamera1.Distance]))
  else
    LogLine('Fit FAILED');
end;

procedure TPeardoxProjectionTestForm.FrontView;
begin
  if FModel = nil then
    Exit;
  SpritelyOrbitalCamera1.Azimuth := FRONT_AZIMUTH;
  SpritelyOrbitalCamera1.PolarAngle := FRONT_POLAR;
  SpritelyOrbitalCamera1.Roll := 0;
  // The every-angle fit puts the target on the model's centre (its depth
  // against the target, the glass in StereoModel, is 0)
  if SpritelyOrbitalCamera1.FitToBoundsMax(FModel, VIEW_MARGIN) then
    LogLine(Format('Front view: azimuth %.0f, inclination %.0f, roll 0, the target on the ' +
      'model''s centre, distance %.2f', [SpritelyOrbitalCamera1.Azimuth,
      SpritelyOrbitalCamera1.PolarAngle, SpritelyOrbitalCamera1.Distance]))
  else
    LogLine('Front view: framing FAILED');
end;

procedure TPeardoxProjectionTestForm.FrontClick(Sender: TObject);
begin
  FrontView;
end;

procedure TPeardoxProjectionTestForm.CentreClick(Sender: TObject);
begin
  FProjection.ShiftX := 0;
  FProjection.ShiftY := 0;
  ShowValues;
end;

procedure TPeardoxProjectionTestForm.ActiveChange(Sender: TObject);
begin
  if FSetting then
    Exit;
  FProjection.Active := ActiveCheck.IsChecked;
  LogLine('Active ' + BoolToStr(FProjection.Active, True));
end;

function TPeardoxProjectionTestForm.SubjectWanted: TGorillaModel;
begin
  if FreeCheck.IsChecked then
    Result := nil
  else
    Result := FModel;
end;

procedure TPeardoxProjectionTestForm.FreeChange(Sender: TObject);
begin
  if FSetting then
    Exit;
  // With no Subject the orbit camera keeps it out of nothing: the wheel can
  // take it into the model (inside DollyHallway, whose box is the hallway)
  SpritelyOrbitalCamera1.Subject := SubjectWanted;
  if FreeCheck.IsChecked then
    LogLine('Free Movement on: the camera may go into the model')
  else
    LogLine('Free Movement off: the camera is kept outside the model''s box');
end;

procedure TPeardoxProjectionTestForm.DollyChange(Sender: TObject);
begin
  if FSetting then
    Exit;
  FProjection.Dolly := DollyCheck.IsChecked;
end;

procedure TPeardoxProjectionTestForm.KindChange(Sender: TObject);
begin
  if FSetting or (KindBox.ItemIndex < 0) then
    Exit;
  // The component turns the camera for the kinds with a preset (it logs the
  // angles)
  FProjection.Kind := TSpritelyProjectionKind(KindBox.ItemIndex);
  LogLine(KIND_NAMES[FProjection.Kind]);
end;

procedure TPeardoxProjectionTestForm.TrackChange(Sender: TObject);
begin
  if FSetting then
    Exit;
  if Sender = ShiftTrack then
    FProjection.ShiftX := ShiftTrack.Value / 100
  else if Sender = RiseTrack then
    FProjection.ShiftY := RiseTrack.Value / 100
  else if (Sender = AngleTrack) or (Sender = DepthTrack) then
  begin
    FProjection.ObliqueAngle := AngleTrack.Value;
    FProjection.ObliqueScale := DepthTrack.Value / 100;
    // An oblique slider moved: the free oblique, if a fixed one was shown
    if FProjection.Kind in [pjCavalier, pjCabinet, pjMilitary, pjPlanOblique] then
      FProjection.Kind := pjOblique;
  end;
  ShowValues;
end;

procedure TPeardoxProjectionTestForm.LensChange(Sender: TObject);
var
  Before: Single;
begin
  if FSetting then
    Exit;
  Before := SpritelyOrbitalCamera1.Distance;
  // With Dolly the projection moves the camera (TSpritelyOrbitalCamera's
  // ProjectionLensChanged) so the target plane keeps its size
  FProjection.FieldOfView := LensTrack.Value;
  LensLabel.Text := Format('Lens %.0f', [FProjection.EffectiveFieldOfView]);
  if FProjection.Dolly and (Abs(SpritelyOrbitalCamera1.Distance - Before) > 0.0001) then
    StatusLabel.Text := Format('Dolly: lens %.1f deg, camera distance %.2f',
      [FProjection.EffectiveFieldOfView, SpritelyOrbitalCamera1.Distance]);
end;

procedure TPeardoxProjectionTestForm.ViewResized(Sender: TObject);
begin
  // The projection follows FMX remaking its own; nothing to do for it
end;

procedure TPeardoxProjectionTestForm.ViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    FDragging := True;
    FDragLast := PointF(X, Y);
  end;
end;

procedure TPeardoxProjectionTestForm.ViewMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
begin
  if not FDragging then
    Exit;
  if not (ssLeft in Shift) then
  begin
    FDragging := False;
    Exit;
  end;
  // As StereoModel: right turns the camera right round the centre, down
  // raises it
  SpritelyOrbitalCamera1.Orbit((X - FDragLast.X) * ORBIT_DEGREES_PER_PIXEL,
    (Y - FDragLast.Y) * ORBIT_DEGREES_PER_PIXEL);
  FDragLast := PointF(X, Y);
end;

procedure TPeardoxProjectionTestForm.ViewMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    FDragging := False;
end;

procedure TPeardoxProjectionTestForm.ViewMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  // The wheel away (positive) brings the view nearer
  SpritelyOrbitalCamera1.Zoom(Power(ZOOM_STEP, -WheelDelta / WHEEL_NOTCH));
end;

end.
