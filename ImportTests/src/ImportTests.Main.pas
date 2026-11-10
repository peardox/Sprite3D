//** @abstract(ImportTests' window: a model loaded by Gorilla3D on the left, its GLB export
//** loaded back on the right, and a log below.)
//**
//** Open model... loads any format Gorilla3D reads into the left view. Export GLB writes it
//** with ImportTests.GltfExport, to the file last chosen with Export GLB as..., and loads the
//** result into the right view, so the two can be compared. The boxes above choose how the
//** coordinates are written; change them and export again.
//**
//** Both views are placed as Sprite3D places a model (centred on its box, turned 180 degrees
//** about X) and framed by their own TSpritelyOrbitalCamera. Dragging in either view turns
//** both cameras together, and the wheel zooms both, so they keep showing the same side.
//**
//** The log lists, for each export, every mesh and material written, anything left out,
//** GLTFLib's warnings, and the counts and box sizes of both models.
//**
//** A model given on the command line is opened at start-up.
unit ImportTests.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Math.Vectors,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox, FMX.Controls.Presentation,
  FMX.Types3D, FMX.Controls3D, FMX.ListBox,
  Gorilla.DefTypes, Gorilla.Viewport, Gorilla.Model,
  Spritely.OrbitalCamera,
  ImportTests.GltfExport;

type
  //** @abstract(One of the two views: a caption, a viewport, its camera and the model in
  //** it.)
  TModelView = class
  private
    FHost: TLayout;
    FCaption: TLabel;
    FArea: TLayout;
    FViewport: TGorillaViewport;
    FCamera: TSpritelyOrbitalCamera;
    FModel: TGorillaModel;
    FBox: TBoundingBox;
    FTitle: string;
  public
    //** @abstract(Builds the view's controls, owned by AOwner, inside AParent.)
    //**
    //** @param(AOwner Owns the controls and the camera.)
    //**
    //** @param(AParent Where the view goes.)
    //**
    //** @param(ATitle The caption's text before a file name, as "Original".)
    constructor Create(const AOwner: TComponent; const AParent: TFmxObject;
      const ATitle: string);
    //** @abstract(Frees the model shown, if any.)
    procedure Clear;
    //** @abstract(Loads a model file in place of the one shown, places it and frames it.)
    //**
    //** @param(AFileName The model.)
    //**
    //** @raises(Exception Gorilla3D could not load it; the view is then empty.)
    procedure Load(const AFileName: string);
    //** @abstract(Frames the model again.)
    procedure Fit;
    //** @abstract(The model's definitions, or nil when there is no model or Gorilla kept
    //** none.)
    //**
    //** TGorillaModel.Def is declared as a TCustomDef; a loaded model's is a TModelDef.
    //**
    //** @returns(The definitions.)
    function Def: TModelDef;
    //** @abstract(The layout holding the caption and the viewport.)
    property Host: TLayout read FHost;
    //** @abstract(The layout behind the viewport, which takes the mouse.)
    property Area: TLayout read FArea;
    //** @abstract(The view's camera.)
    property Camera: TSpritelyOrbitalCamera read FCamera;
    //** @abstract(The model shown, or nil.)
    property Model: TGorillaModel read FModel;
    //** @abstract(The model's bounding box as loaded, before it was placed.)
    property Box: TBoundingBox read FBox;
    //** @abstract(The caption's text before a file name, as "Original".)
    property Title: string read FTitle;
  end;

  //** @abstract(The main window; everything but the form itself is made in FormCreate.)
  TImportTestsForm = class(TForm)
    //** @abstract(Builds the window and opens a model given on the command line.)
    procedure FormCreate(Sender: TObject);
    //** @abstract(Frees the two views.)
    procedure FormDestroy(Sender: TObject);
  private
    FButtons: TLayout;
    FOptionsBar: TLayout;
    FOpenButton: TButton;
    FExportButton: TButton;
    FExportAsButton: TButton;
    FFitButton: TButton;
    FClearButton: TButton;
    FNegateX: TCheckBox;
    FNegateY: TCheckBox;
    FNegateZ: TCheckBox;
    FReverse: TCheckBox;
    FFlipV: TCheckBox;
    FColours: TCheckBox;
    FTextures: TCheckBox;
    FRaw: TCheckBox;
    FUnitScale: TCheckBox;
    FSkins: TCheckBox;
    FAnimations: TCheckBox;
    FThinKeys: TCheckBox;
    FAnimationBar: TLayout;
    FAnimationList: TComboBox;
    FPlayButton: TButton;
    FStopButton: TButton;
    FViews: TLayout;
    FLeft: TModelView;
    FRight: TModelView;
    FSplitter: TSplitter;
    FMemo: TMemo;
    FSourceFile: string;
    FExportFile: string;
    FDragging: Boolean;
    FDragFrom: TPointF;
    function AddButton(const AText: string; const AWidth: Single;
      const AClick: TNotifyEvent): TButton;
    function AddCheck(const AText: string; const AChecked: Boolean): TCheckBox;
    procedure Log(const AText: string); overload;
    procedure Log(const ALines: TStrings); overload;
    function Options: TGltfExportOptions;
    procedure UpdateButtons;
    procedure LoadSource(const AFileName: string);
    procedure ExportTo(const AFileName: string);
    procedure LogComparison;
    procedure OpenClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure ExportAsClick(Sender: TObject);
    procedure FitClick(Sender: TObject);
    procedure ClearClick(Sender: TObject);
    procedure PlayClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure FillAnimations;
    procedure PlayOn(const AView: TModelView; const AName: string);
    procedure ViewsResize(Sender: TObject);
    procedure AreaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    procedure AreaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure AreaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Single);
    procedure AreaMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      var Handled: Boolean);
  end;

var
  //** @abstract(The main window.)
  ImportTestsForm: TImportTestsForm;

implementation

{$R *.fmx}

uses
  System.IOUtils,
  Gorilla.Animation, Gorilla.Animation.Controller,
  // The loaders register the formats Gorilla3D reads, as in Sprite3DHelpers
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.OBJ.Loader,
  Gorilla.USD.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader;

const
  MODEL_FILTER = 'Models|*.fbx;*.glb;*.gltf;*.obj;*.dae;*.usd;*.usda;*.usdc;*.usdz;*.stl;*.ply' +
    '|All files|*.*';
  GLB_FILTER = 'GLB (*.glb)|*.glb';
  // Degrees the cameras turn for each pixel dragged
  ORBIT_PER_PIXEL = 0.4;
  // Zoom for one notch of the wheel
  ZOOM_PER_NOTCH = 0.9;
  VIEW_COLOUR = $FF30343C;
  // As MODEL_ROTATION in Sprite3DHelpers
  MODEL_TURN_X = 180;

function BoxText(const ABox: TBoundingBox): string;
begin
  Result := Format('%.4g x %.4g x %.4g, centre %.4g %.4g %.4g',
    [ABox.Width, ABox.Height, ABox.Depth,
     ABox.TopLeftNear.X + ABox.Width / 2, ABox.TopLeftNear.Y + ABox.Height / 2,
     ABox.TopLeftNear.Z + ABox.Depth / 2]);
end;

function CountsText(const ACounts: TGltfModelCounts): string;
begin
  Result := Format('%d meshes, %d vertices, %d triangles, %d materials, %d skins, ' +
    '%d animations', [ACounts.Meshes, ACounts.Vertices, ACounts.Triangles, ACounts.Materials,
    ACounts.Skins, ACounts.Animations]);
end;

{ TModelView }

constructor TModelView.Create(const AOwner: TComponent; const AParent: TFmxObject;
  const ATitle: string);
begin
  inherited Create;
  FTitle := ATitle;
  FHost := TLayout.Create(AOwner);
  FHost.Parent := AParent;

  FCaption := TLabel.Create(AOwner);
  FCaption.Parent := FHost;
  FCaption.Align := TAlignLayout.Top;
  FCaption.Height := 22;
  FCaption.Margins.Left := 6;
  FCaption.Text := ATitle;

  // The viewport lets the mouse through to this layout, as Sprite3D's does
  FArea := TLayout.Create(AOwner);
  FArea.Parent := FHost;
  FArea.Align := TAlignLayout.Client;
  FArea.HitTest := True;
  FArea.AutoCapture := True;

  FViewport := TGorillaViewport.Create(AOwner);
  FViewport.Parent := FArea;
  FViewport.Align := TAlignLayout.Client;
  FViewport.HitTest := False;
  FViewport.Color := VIEW_COLOUR;
  FViewport.UseFixedFrameRate := True;
  FViewport.VSync := False;
  FViewport.FixedFrameRate := 60;

  FCamera := TSpritelyOrbitalCamera.Create(AOwner);
  FCamera.Headlight := True;
  FCamera.FOV := 45;
  FCamera.Viewport := FViewport;
end;

procedure TModelView.Clear;
begin
  if FModel = nil then
    Exit;
  FCamera.Subject := nil;
  FModel.Parent := nil;
  FreeAndNil(FModel);
  FCaption.Text := FTitle;
end;

procedure TModelView.Load(const AFileName: string);
begin
  Clear;
  // A new model each time, so nothing of the last file is kept
  FModel := TGorillaModel.Create(FViewport);
  FModel.Parent := FViewport;
  FModel.HitTest := False;
  try
    FModel.LoadFromFile(nil, AFileName, [TAnimationCachingFlag.VertexPosition]);
  except
    FModel.Parent := nil;
    FreeAndNil(FModel);
    raise;
  end;
  FBox := FModel.GetBoundingBox();
  // Placed as Sprite3D's PlaceModel does
  FModel.Position.Point := Point3D(FBox.TopLeftNear.X + (FBox.Width / 2),
                                   FBox.TopLeftNear.Y + (FBox.Height / 2),
                                   FBox.TopLeftNear.Z + (FBox.Depth / 2));
  FModel.RotationAngle.X := MODEL_TURN_X;
  FCamera.Subject := FModel;
  Fit;
  FCaption.Text := FTitle + ': ' + TPath.GetFileName(AFileName);
end;

function TModelView.Def: TModelDef;
begin
  if (FModel <> nil) and (FModel.Def is TModelDef) then
    Result := TModelDef(FModel.Def)
  else
    Result := nil;
end;

procedure TModelView.Fit;
begin
  if FModel <> nil then
    FCamera.FitToBounds(FModel);
end;

{ TImportTestsForm }

function TImportTestsForm.AddButton(const AText: string; const AWidth: Single;
  const AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := FButtons;
  Result.Align := TAlignLayout.Left;
  Result.Width := AWidth;
  Result.Margins.Rect := RectF(4, 4, 0, 4);
  Result.Text := AText;
  Result.OnClick := AClick;
  // Each new one goes to the right of the last
  Result.Position.X := FButtons.Width;
end;

function TImportTestsForm.AddCheck(const AText: string; const AChecked: Boolean): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := FOptionsBar;
  Result.Align := TAlignLayout.Left;
  // The form has no canvas yet; about 7 pixels a character, and the box
  Result.Width := Length(AText) * 7 + 30;
  Result.Margins.Rect := RectF(8, 4, 0, 4);
  Result.Text := AText;
  Result.IsChecked := AChecked;
  Result.Position.X := FOptionsBar.Width;
end;

procedure TImportTestsForm.FormCreate(Sender: TObject);
var
  Defaults: TGltfExportOptions;
begin
  Caption := 'Sprite3D Import Tests';

  FButtons := TLayout.Create(Self);
  FButtons.Parent := Self;
  FButtons.Align := TAlignLayout.Top;
  FButtons.Height := 36;
  FOpenButton := AddButton('Open model...', 110, OpenClick);
  FExportButton := AddButton('Export GLB', 90, ExportClick);
  FExportAsButton := AddButton('Export GLB as...', 120, ExportAsClick);
  FFitButton := AddButton('Fit views', 80, FitClick);
  FClearButton := AddButton('Clear log', 80, ClearClick);

  FOptionsBar := TLayout.Create(Self);
  FOptionsBar.Parent := Self;
  FOptionsBar.Align := TAlignLayout.Top;
  FOptionsBar.Height := 30;
  FOptionsBar.Position.Y := FButtons.Height;
  Defaults := TGltfExportOptions.Create;
  FNegateX := AddCheck('Negate X', Defaults.NegateX);
  FNegateY := AddCheck('Negate Y', Defaults.NegateY);
  FNegateZ := AddCheck('Negate Z', Defaults.NegateZ);
  FReverse := AddCheck('Reverse winding', Defaults.ReverseWinding);
  FFlipV := AddCheck('Flip V', Defaults.FlipV);
  FColours := AddCheck('Vertex colours', Defaults.VertexColors);
  FTextures := AddCheck('Textures', Defaults.Textures);
  FRaw := AddCheck('Also write .raw.glb', Defaults.WriteRaw);
  FUnitScale := AddCheck('Apply unit scale', Defaults.ApplyUnitScale);
  FSkins := AddCheck('Skins', Defaults.Skins);
  FAnimations := AddCheck('Animations', Defaults.Animations);
  FThinKeys := AddCheck('Thin keys', Defaults.ThinKeys);

  // Plays the same animation, by name, in both views
  FAnimationBar := TLayout.Create(Self);
  FAnimationBar.Parent := Self;
  FAnimationBar.Align := TAlignLayout.Top;
  FAnimationBar.Height := 32;
  FAnimationBar.Position.Y := FOptionsBar.Position.Y + FOptionsBar.Height;
  FAnimationList := TComboBox.Create(Self);
  FAnimationList.Parent := FAnimationBar;
  FAnimationList.Align := TAlignLayout.Left;
  FAnimationList.Width := 320;
  FAnimationList.Margins.Rect := RectF(4, 4, 0, 4);
  FPlayButton := TButton.Create(Self);
  FPlayButton.Parent := FAnimationBar;
  FPlayButton.Align := TAlignLayout.Left;
  FPlayButton.Width := 70;
  FPlayButton.Margins.Rect := RectF(4, 4, 0, 4);
  FPlayButton.Position.X := 400;
  FPlayButton.Text := 'Play';
  FPlayButton.OnClick := PlayClick;
  FStopButton := TButton.Create(Self);
  FStopButton.Parent := FAnimationBar;
  FStopButton.Align := TAlignLayout.Left;
  FStopButton.Width := 70;
  FStopButton.Margins.Rect := RectF(4, 4, 0, 4);
  FStopButton.Position.X := 500;
  FStopButton.Text := 'Stop';
  FStopButton.OnClick := StopClick;

  // The memo and its splitter sit at the bottom: the memo first, so it is
  // the lower of the two
  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Align := TAlignLayout.Bottom;
  FMemo.Height := 220;
  FMemo.ReadOnly := True;
  FMemo.StyledSettings := FMemo.StyledSettings - [TStyledSetting.Family];
  FMemo.TextSettings.Font.Family := 'Consolas';
  FMemo.TextSettings.WordWrap := False;

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := TAlignLayout.Bottom;
  FSplitter.Height := 5;
  FSplitter.Position.Y := FMemo.Position.Y - 5;

  FViews := TLayout.Create(Self);
  FViews.Parent := Self;
  FViews.Align := TAlignLayout.Client;
  FViews.OnResize := ViewsResize;

  FLeft := TModelView.Create(Self, FViews, 'Original');
  FLeft.Host.Align := TAlignLayout.Left;
  FRight := TModelView.Create(Self, FViews, 'Exported GLB');
  FRight.Host.Align := TAlignLayout.Client;
  FLeft.Area.OnMouseDown := AreaMouseDown;
  FLeft.Area.OnMouseMove := AreaMouseMove;
  FLeft.Area.OnMouseUp := AreaMouseUp;
  FLeft.Area.OnMouseWheel := AreaMouseWheel;
  FRight.Area.OnMouseDown := AreaMouseDown;
  FRight.Area.OnMouseMove := AreaMouseMove;
  FRight.Area.OnMouseUp := AreaMouseUp;
  FRight.Area.OnMouseWheel := AreaMouseWheel;
  ViewsResize(nil);

  UpdateButtons;
  Log('Open a model, then Export GLB. Drag in either view to turn both; the wheel zooms.');

  // Opened once the window is up, so the views have a size to frame in
  if ParamCount > 0 then
    TThread.ForceQueue(nil,
      procedure
      begin
        LoadSource(ParamStr(1));
      end);
end;

procedure TImportTestsForm.FormDestroy(Sender: TObject);
begin
  // The controls belong to the form; only the two holders are freed here
  FreeAndNil(FLeft);
  FreeAndNil(FRight);
end;

procedure TImportTestsForm.ViewsResize(Sender: TObject);
begin
  if FLeft <> nil then
    FLeft.Host.Width := Max(1, FViews.Width / 2);
end;

procedure TImportTestsForm.Log(const AText: string);
begin
  FMemo.Lines.Add(AText);
  FMemo.GoToTextEnd;
end;

procedure TImportTestsForm.Log(const ALines: TStrings);
begin
  FMemo.Lines.AddStrings(ALines);
  FMemo.GoToTextEnd;
end;

function TImportTestsForm.Options: TGltfExportOptions;
begin
  Result := TGltfExportOptions.Create;
  Result.NegateX := FNegateX.IsChecked;
  Result.NegateY := FNegateY.IsChecked;
  Result.NegateZ := FNegateZ.IsChecked;
  Result.ReverseWinding := FReverse.IsChecked;
  Result.FlipV := FFlipV.IsChecked;
  Result.VertexColors := FColours.IsChecked;
  Result.Textures := FTextures.IsChecked;
  Result.WriteRaw := FRaw.IsChecked;
  Result.ApplyUnitScale := FUnitScale.IsChecked;
  Result.Skins := FSkins.IsChecked;
  Result.Animations := FAnimations.IsChecked;
  Result.ThinKeys := FThinKeys.IsChecked;
end;

procedure TImportTestsForm.UpdateButtons;
var
  HasModel: Boolean;
begin
  HasModel := (FLeft <> nil) and (FLeft.Model <> nil);
  FExportButton.Enabled := HasModel;
  FExportAsButton.Enabled := HasModel;
  FFitButton.Enabled := HasModel;
  FPlayButton.Enabled := HasModel and (FAnimationList.Count > 0);
  FStopButton.Enabled := FPlayButton.Enabled;
end;

procedure TImportTestsForm.FillAnimations;
var
  Animation: TGorillaAnimation;
begin
  FAnimationList.Clear;
  if FLeft.Model <> nil then
    for Animation in FLeft.Model.AnimationManager.GetSortedAnimations() do
      FAnimationList.Items.Add(Animation.Id);
  if FAnimationList.Count > 0 then
    FAnimationList.ItemIndex := 0;
end;

procedure TImportTestsForm.PlayOn(const AView: TModelView; const AName: string);
begin
  if AView.Model = nil then
    Exit;
  if AView.Model.AnimationManager.GetAnimation(AName) = nil then
  begin
    Log('The ' + LowerCase(AView.Title) + ' has no animation called ' + AName);
    Exit;
  end;
  AView.Model.AnimationManager.PlayAnimation(AName);
end;

procedure TImportTestsForm.PlayClick(Sender: TObject);
var
  Name: string;
begin
  if FAnimationList.ItemIndex < 0 then
    Exit;
  Name := FAnimationList.Items[FAnimationList.ItemIndex];
  // The export keeps the original's names, so the same one plays in both
  PlayOn(FLeft, Name);
  PlayOn(FRight, Name);
end;

procedure TImportTestsForm.StopClick(Sender: TObject);

  procedure StopOn(const AView: TModelView);
  begin
    if (AView.Model <> nil) and (AView.Model.AnimationManager.Current <> nil) then
      AView.Model.AnimationManager.Current.Stop;
  end;

begin
  StopOn(FLeft);
  StopOn(FRight);
end;

procedure TImportTestsForm.LoadSource(const AFileName: string);
begin
  FRight.Clear;
  FSourceFile := '';
  FExportFile := '';
  Log('');
  Log('Loading ' + AFileName);
  try
    FLeft.Load(AFileName);
    FSourceFile := AFileName;
    Log('Box: ' + BoxText(FLeft.Box));
    if FLeft.Def = nil then
      Log('Gorilla kept no definitions for this model, so it cannot be exported')
    else
    begin
      Log('Holds: ' + CountsText(CountModel(FLeft.Def)) + ', unit scale ' +
        FloatToStr(FLeft.Def.UnitScale));
      Log('Definitions: ' + DescribeModel(FLeft.Def));
      if DescribeAnimations(FLeft.Def) <> '' then
        Log('Animations: ' + DescribeAnimations(FLeft.Def));
    end;
  except
    on E: Exception do
      Log('Could not load it: ' + E.ClassName + ': ' + E.Message);
  end;
  FillAnimations;
  UpdateButtons;
end;

procedure TImportTestsForm.ExportTo(const AFileName: string);
var
  Lines: TStringList;
  Stats: TGltfExportStats;
  Exported: Boolean;
begin
  if FLeft.Def = nil then
    Exit;
  if SameFileName(TPath.GetFullPath(AFileName), TPath.GetFullPath(FSourceFile)) then
  begin
    Log('Not exported: that is the file being tested. Choose another name.');
    Exit;
  end;
  FExportFile := AFileName;
  Log('');
  Log('Exporting to ' + AFileName);
  FRight.Clear;
  Exported := False;
  Lines := TStringList.Create;
  try
    try
      ExportGlb(FLeft.Def, AFileName, Options, Lines, Stats);
      Exported := True;
    except
      on E: Exception do
        Lines.Add('Export failed: ' + E.ClassName + ': ' + E.Message);
    end;
    Log(Lines);
  finally
    Lines.Free;
  end;
  if not Exported then
    Exit;
  Log(Format('Wrote %d nodes, %d meshes, %d primitives, %d vertices, %d triangles, ' +
    '%d materials, %d images, %d skins (%d joints), %d animations (%d channels); %d bytes',
    [Stats.Nodes, Stats.Meshes, Stats.Primitives, Stats.Vertices, Stats.Triangles,
     Stats.Materials, Stats.Images, Stats.Skins, Stats.Joints, Stats.Animations,
     Stats.Channels, Stats.Bytes]));
  if Stats.KeysHeld > 0 then
    Log(Format('Animation keys: %d held, %d written', [Stats.KeysHeld, Stats.KeysWritten]));
  try
    // The cameras keep their angles between loads and always turn together,
    // so the export is seen from the same side as the original
    FRight.Load(AFileName);
    LogComparison;
  except
    on E: Exception do
      Log('Could not load the export back: ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TImportTestsForm.LogComparison;
begin
  Log('Original: ' + BoxText(FLeft.Box));
  Log('Exported: ' + BoxText(FRight.Box));
  Log('Original holds ' + CountsText(CountModel(FLeft.Def)));
  if FRight.Def <> nil then
  begin
    Log('Exported holds ' + CountsText(CountModel(FRight.Def)));
    Log('Exported definitions: ' + DescribeModel(FRight.Def));
    if DescribeAnimations(FRight.Def) <> '' then
      Log('Exported animations: ' + DescribeAnimations(FRight.Def));
  end;
end;

procedure TImportTestsForm.OpenClick(Sender: TObject);
var
  Dialog: TOpenDialog;
begin
  Dialog := TOpenDialog.Create(nil);
  try
    Dialog.Title := 'Open a model';
    Dialog.Filter := MODEL_FILTER;
    if FSourceFile <> '' then
      Dialog.InitialDir := TPath.GetDirectoryName(FSourceFile);
    if Dialog.Execute then
      LoadSource(Dialog.FileName);
  finally
    Dialog.Free;
  end;
end;

procedure TImportTestsForm.ExportClick(Sender: TObject);
begin
  if FExportFile = '' then
    ExportAsClick(Sender)
  else
    ExportTo(FExportFile);
end;

procedure TImportTestsForm.ExportAsClick(Sender: TObject);
var
  Dialog: TSaveDialog;
begin
  if FSourceFile = '' then
    Exit;
  Dialog := TSaveDialog.Create(nil);
  try
    Dialog.Title := 'Export as GLB';
    Dialog.Filter := GLB_FILTER;
    Dialog.DefaultExt := 'glb';
    if FExportFile <> '' then
    begin
      Dialog.InitialDir := TPath.GetDirectoryName(FExportFile);
      Dialog.FileName := TPath.GetFileName(FExportFile);
    end
    else
    begin
      Dialog.InitialDir := TPath.GetDirectoryName(FSourceFile);
      Dialog.FileName := TPath.GetFileNameWithoutExtension(FSourceFile) + '_export.glb';
    end;
    Dialog.Options := Dialog.Options + [TOpenOption.ofOverwritePrompt];
    if Dialog.Execute then
      ExportTo(Dialog.FileName);
  finally
    Dialog.Free;
  end;
end;

procedure TImportTestsForm.FitClick(Sender: TObject);
begin
  FLeft.Fit;
  FRight.Fit;
end;

procedure TImportTestsForm.ClearClick(Sender: TObject);
begin
  FMemo.Lines.Clear;
end;

procedure TImportTestsForm.AreaMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Button <> TMouseButton.mbLeft then
    Exit;
  FDragging := True;
  FDragFrom := PointF(X, Y);
end;

procedure TImportTestsForm.AreaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  DX, DY: Single;
begin
  if not FDragging then
    Exit;
  DX := X - FDragFrom.X;
  DY := Y - FDragFrom.Y;
  FDragFrom := PointF(X, Y);
  // Both turn together, so the two views keep showing the same side
  FLeft.Camera.Orbit(-DX * ORBIT_PER_PIXEL, DY * ORBIT_PER_PIXEL);
  FRight.Camera.Orbit(-DX * ORBIT_PER_PIXEL, DY * ORBIT_PER_PIXEL);
end;

procedure TImportTestsForm.AreaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FDragging := False;
end;

procedure TImportTestsForm.AreaMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
var
  Factor: Single;
begin
  Factor := Power(ZOOM_PER_NOTCH, WheelDelta / 120);
  FLeft.Camera.Zoom(Factor);
  FRight.Camera.Zoom(Factor);
  Handled := True;
end;

end.
