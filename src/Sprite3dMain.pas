unit Sprite3dMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Math.Vectors, Gorilla.Control, Gorilla.Transform, Gorilla.Mesh,
  Gorilla.Model, FMX.Controls3D, Gorilla.Light, Gorilla.Viewport,
  FMX.TabControl, FMX.Layouts, Gorilla.Controller, Gorilla.Animation.Controller,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Objects3D, Gorilla.Camera, Sprite3dCamera;

type
  TControl3DAccess = class(TControl3D);
  TForm1 = class(TForm)
    TabControl1: TTabControl;
    GorillaTab: TTabItem;
    TabItem1: TTabItem;
    Memo1: TMemo;
    Layout1: TLayout;
    ViewportLayout: TLayout;
    Layout2: TLayout;
    AzimuthDial: TArcDial;
    AzimuthLabel: TLabel;
    AzimuthText: TLabel;
    AngleDial: TArcDial;
    AngleLabel: TLabel;
    AngleText: TLabel;
    Model3D1: TModel3D;
    RollDial: TArcDial;
    RollLabel: TLabel;
    RollText: TLabel;
    chkOrthoToggle: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure AzimuthDialChange(Sender: TObject);
    procedure AngleDialChange(Sender: TObject);
    procedure RollDialChange(Sender: TObject);
    procedure GorillaViewportResize(Sender: TObject);
    procedure chkOrthoToggleChange(Sender: TObject);
  private
    { Private declarations }
    FModelRotation: TPoint3D;
    FAzimuth: Single;
    FRoll: Single;
    FPolarAngle: Single;
    GorillaViewport: TGorillaViewport;
    GorillaLight: TGorillaLight;
    GorillaModel: TGorillaModel;
    GorillaAnimationController: TGorillaAnimationController;
    GorillaCamera: TSprite3DCamera;
    ModelDir: String;
    procedure SwitchModel(const AModel: String);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  System.IOUtils,
  FMX.Platform,
  Gorilla.DefTypes, System.Math,
  Gorilla.Animation,
  Gorilla.GLB.Loader,
  Gorilla.GLTF.Loader,
  Gorilla.OBJ.Loader,
  Gorilla.USD.Loader,
  Gorilla.FBX.Loader,
  Gorilla.DAE.Loader,
  Gorilla.STL.Loader,
  Gorilla.PLY.Loader,
  FMX.Types3D;

{$R *.fmx}

procedure TForm1.FormCreate(Sender: TObject);
begin
  TabControl1.ActiveTab := GorillaTab;

  {$IF DEFINED(MACOS)}
  ModelDir := IncludeTrailingPathDelimiter(TPath.GetLibraryPath);
  {$ELSEIF DEFINED(LINUX)}
  ModelDir := IncludeTrailingPathDelimiter(TPath.GetHomePath);
  {$ELSE}
  ModelDir := '../../../';
  {$ENDIF}

  {$IF DEFINED(MSWINDOWS)}
  if DirectoryExists('models') then
    ModelDir := String.Empty;
  {$IFEND}
  GorillaViewport := TGorillaViewport.Create(ViewportLayout);
  GorillaViewport.OnResize := GorillaViewportResize;
  GorillaLight := TGorillaLight.Create(GorillaViewport);
  GorillaLight.Parent := GorillaViewport;
  GorillaLight.LightType := TLightType.Point;
  GorillaViewport.UseFixedFrameRate := true;
  GorillaViewport.VSync := False;
  GorillaViewport.HitTest := False;
  GorillaViewport.FixedFrameRate := 60;
//  GorillaViewport.DiagnosticsActive := true;
  GorillaViewport.UsingDesignCamera := False;
  GorillaCamera := TSprite3DCamera.Create(GorillaViewport);
  GorillaViewport.Camera := GorillaCamera;// .Camera;
  GorillaModel := Nil;
  GorillaCamera.FOV := 45;

end;

procedure TForm1.AngleDialChange(Sender: TObject);
begin
  FPolarAngle := -AngleDial.Value;
  if FPolarAngle < 0 then
      FPolarAngle := FPolarAngle + 360;

  AngleText.Text := Format('%3.0f',[FPolarAngle]);

  GorillaCamera.PolarAngle := FPolarAngle;

end;

procedure TForm1.AzimuthDialChange(Sender: TObject);
begin
  FAzimuth := -AzimuthDial.Value;

  if FAzimuth < 0 then
      FAzimuth := FAzimuth + 360;

  AzimuthText.Text := Format('%3.0f',[FAzimuth]);

  GorillaCamera.Azimuth := FAzimuth;
end;

procedure TForm1.chkOrthoToggleChange(Sender: TObject);
begin
  if chkOrthoToggle.IsChecked then
    begin
      Caption := 'Orthographic';
      GorillaCamera.ProjectionMode := TGorillaCameraProjection.cpOrthographic;
    end
  else
    begin
      Caption := 'Perspective';
      GorillaCamera.ProjectionMode := TGorillaCameraProjection.cpPerspective;
    end;
  if Assigned(GorillaCamera) and Assigned(GorillaModel) then
    GorillaCamera.FitToBounds(GorillaModel);
end;

procedure TForm1.RollDialChange(Sender: TObject);
begin
  FRoll := RollDial.Value;

  if FRoll < 0 then
      FRoll := FRoll + 360;

  RollText.Text := Format('%3.0f',[FRoll]);

  GorillaCamera.Roll := FRoll;
end;

// On startup load a default Model as specified by DefaultLoadType
// The directory layout of models/Orientation follows this pattern
// to allow easy addition of new Model types
procedure TForm1.FormShow(Sender: TObject);
begin
  SwitchModel(ModelDir + 'models/TestModel.glb');
end;

procedure TForm1.GorillaViewportResize(Sender: TObject);
begin
  if Assigned(GorillaCamera) and Assigned(GorillaModel) then
    GorillaCamera.FitToBounds(GorillaModel);
end;

// Load a Model Clearing any old model first (so it Switches them)
// GorillaModel will be Nil on first call but set on subsequent calls
procedure TForm1.SwitchModel(const AModel: String);
var
  BBox: TBoundingBox;
  anims: TStringList;
begin
  if (AModel = String.Empty) or (not FileExists(AModel)) then
    begin
      ShowMessage('Model Not Found ' + AModel);
      Exit;
    end;

  if GorillaModel = Nil then
    begin
      GorillaModel := TGorillaModel.Create(GorillaViewport);
      GorillaModel.Parent := GorillaViewport;
    end;

  GorillaModel.Clear;

  try
    GorillaModel.LoadFromFile(nil, AModel, []);
    anims := TStringList.Create;
    anims.Sorted := True;

    try
      if GorillaModel.AnimationManager.Animations.Count > 0 then
        begin
          Memo1.Lines.Add('---------- anims ---------------');
          for var AnimName in GorillaModel.AnimationManager.Animations.Keys do
            anims.Add(AnimName);
          Memo1.Lines.Add('--------------------------------');
          GorillaModel.AnimationManager.PlayAnimation(anims[anims.count - 1]);
        end;
    finally
      anims.Free;
    end;

    RollDial.Value := 0;
    AzimuthDial.Value := 0;
    AngleDial.Value := 0;
    BBox := GorillaModel.GetBoundingBox();

    GorillaModel.IsMarked := True;
    GorillaModel.Position.Point := Point3D(BBox.TopLeftNear.X + (BBox.Width / 2),
                                            BBox.TopLeftNear.Y + (BBox.Height / 2),
                                            BBox.TopLeftNear.Z + (BBox.Depth / 2));

    FModelRotation := Point3D(180, 0, 0);

    GorillaModel.RotationAngle.X := FModelRotation.X;
    GorillaModel.RotationAngle.Y := FModelRotation.Y;
    GorillaModel.RotationAngle.Z := FModelRotation.Z;

    if not GorillaCamera.FitToBounds(GorillaModel) then
      Caption := 'Problem fitting Camera'
    else if GorillaCamera.ProjectionMode = TGorillaCameraProjection.cpOrthographic then
      Caption := 'Orthographic'
    else if GorillaCamera.ProjectionMode = TGorillaCameraProjection.cpPerspective then
      Caption := 'Perspective'
    else
      Caption := 'Some other projection';


  except
    on E : Exception do
      begin
        ShowMessage('Can''t Load Model : ' + AModel + sLineBreak +
                    'Exception class name : '+ E.ClassName   + sLineBreak +
                    'Exception message : ' + E.Message);
        FreeAndNil(GorillaModel);
      end;
  end;
end;


end.
