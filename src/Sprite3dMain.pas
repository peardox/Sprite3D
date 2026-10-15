//** @abstract(Demo form for TSprite3DCamera: loads a model and drives the camera with dials.)
//**
//** The form has two tabs. The View tab holds a TGorillaViewport, created at run time, and a
//** panel of three dials for Azimuth, inclination and Roll, plus two check boxes: one
//** switches between perspective and orthographic projection, the other chooses how the model
//** is fitted. The Debug tab holds a memo for log output.
//**
//** On show, the form loads the model whose file FormShow names, plays its last animation by
//** name if it has any, centres it and turns it 180 degrees about X, and fits the camera so it
//** fills the view. The model is refitted whenever a dial turns, the viewport is resized, the
//** projection changes or the "Fit any angle" box is toggled. Checked, that box uses
//** FitToBoundsMax, which frames the model for every angle at once; unchecked, FitToBounds
//** frames it exactly for the current angles.
//**
//** @preformatted(
//** TabControl1
//** |-- GorillaTab "View"
//** |   `-- MainLayout
//** |       |-- ViewportLayout   owns the TGorillaViewport
//** |       `-- ControlsLayout   dials, labels, both check boxes
//** `-- DebugTab "Debug"
//**     `-- DebugMemo
//** )
unit Sprite3dMain;
{
  Demo form for TSprite3DCamera: loads a model and drives the camera with dials.
  The form has two tabs. The View tab holds a TGorillaViewport, created at run
  time, and a panel of three dials for Azimuth, inclination and Roll, plus
  two check boxes: one switches between perspective and orthographic
  projection, the other chooses how the model is fitted. The Debug tab
  holds a memo for log output.
  On show, the form loads the model whose file FormShow names, plays its
  last animation by name if it has any, centres it and turns it 180 degrees
  about X, and fits the camera so it fills the view. The model is refitted
  whenever a dial turns, the viewport is resized, the projection changes or
  the "Fit any angle" box is toggled. Checked, that box uses
  FitToBoundsMax, which frames the model for every angle at once;
  unchecked, FitToBounds frames it exactly for the current angles.
    TabControl1
    |-- GorillaTab "View"
    |   `-- MainLayout
    |       |-- ViewportLayout   owns the TGorillaViewport
    |       `-- ControlsLayout   dials, labels, both check boxes
    `-- DebugTab "Debug"
        `-- DebugMemo
}

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
  //** @abstract(Protected-access helper for TControl3D; nothing in the project uses it yet.)
  //**
  //** Casting a TControl3D to this class exposes its protected members inside the unit that
  //** declares the cast. Because it is in the interface section, other units can use it too.
  /// <summary>Protected-access helper for TControl3D; nothing in the project uses it
  /// yet.</summary>
  /// <remarks>Casting a TControl3D to this class exposes its protected members inside the unit
  /// that declares the cast. Because it is in the interface section, other units can use it
  /// too.</remarks>
  TControl3DAccess = class(TControl3D);
  //** @abstract(The main form: a Gorilla3D view of one model, with dials for the camera.)
  //**
  //** The viewport, light, model and TSprite3DCamera are created at run time, not at design
  //** time; the form owns none of them directly. All event handlers run on the main thread.
  //**
  //** @seealso(TSprite3DCamera)
  /// <summary>The main form: a Gorilla3D view of one model, with dials for the camera.</summary>
  /// <remarks>The viewport, light, model and TSprite3DCamera are created at run time, not at
  /// design time; the form owns none of them directly. All event handlers run on the main
  /// thread.</remarks>
  /// <seealso cref="Sprite3DCamera.TSprite3DCamera"/>
  TMainForm = class(TForm)
    //** @abstract(Fills the form and holds the View tab and the Debug tab.)
    /// <summary>Fills the form and holds the View tab and the Debug tab.</summary>
    TabControl1: TTabControl;
    //** @abstract(The tab captioned "View", with the viewport and camera controls; active at
    //** start-up.)
    /// <summary>The tab captioned "View", with the viewport and camera controls; active at
    /// start-up.</summary>
    GorillaTab: TTabItem;
    //** @abstract(The tab captioned "Debug", holding DebugMemo.)
    /// <summary>The tab captioned "Debug", holding DebugMemo.</summary>
    DebugTab: TTabItem;
    //** @abstract(Log output; SwitchModel writes separator lines here when a model has
    //** animations.)
    /// <summary>Log output; SwitchModel writes separator lines here when a model has
    /// animations.</summary>
    DebugMemo: TMemo;
    //** @abstract(Fills the View tab and holds ViewportLayout and ControlsLayout.)
    /// <summary>Fills the View tab and holds ViewportLayout and ControlsLayout.</summary>
    MainLayout: TLayout;
    //** @abstract(The area left of the control panel; owns the TGorillaViewport made in
    //** FormCreate.)
    /// <summary>The area left of the control panel; owns the TGorillaViewport made in
    /// FormCreate.</summary>
    ViewportLayout: TLayout;
    //** @abstract(The right-hand control panel holding the dials, their labels and both
    //** check boxes.)
    /// <summary>The right-hand control panel holding the dials, their labels and both check
    /// boxes.</summary>
    ControlsLayout: TLayout;
    //** @abstract(Sets the camera's Azimuth; see AzimuthDialChange.)
    /// <summary>Sets the camera's Azimuth; see <see cref="AzimuthDialChange"/>.</summary>
    AzimuthDial: TArcDial;
    //** @abstract(The caption "Azimuth" above AzimuthDial.)
    /// <summary>The caption "Azimuth" above AzimuthDial.</summary>
    AzimuthLabel: TLabel;
    //** @abstract(Shows the current azimuth in whole degrees.)
    /// <summary>Shows the current azimuth in whole degrees.</summary>
    AzimuthText: TLabel;
    //** @abstract(Sets the camera's PolarAngle; see AngleDialChange.)
    /// <summary>Sets the camera's PolarAngle; see <see cref="AngleDialChange"/>.</summary>
    AngleDial: TArcDial;
    //** @abstract(The caption "Inclination" above AngleDial.)
    /// <summary>The caption "Inclination" above AngleDial.</summary>
    AngleLabel: TLabel;
    //** @abstract(Shows the current polar angle in whole degrees.)
    /// <summary>Shows the current polar angle in whole degrees.</summary>
    AngleText: TLabel;
    //** @abstract(An FMX TModel3D placed at design time; the code does not use it.)
    //**
    //** The model on screen is a TGorillaModel created at run time by SwitchModel.
    /// <summary>An FMX TModel3D placed at design time; the code does not use it.</summary>
    /// <remarks>The model on screen is a TGorillaModel created at run time by
    /// SwitchModel.</remarks>
    Model3D1: TModel3D;
    //** @abstract(Sets the camera's Roll; see RollDialChange.)
    /// <summary>Sets the camera's Roll; see <see cref="RollDialChange"/>.</summary>
    RollDial: TArcDial;
    //** @abstract(The caption "Roll" above RollDial.)
    /// <summary>The caption "Roll" above RollDial.</summary>
    RollLabel: TLabel;
    //** @abstract(Shows the current roll in whole degrees.)
    /// <summary>Shows the current roll in whole degrees.</summary>
    RollText: TLabel;
    //** @abstract(Switches the camera between orthographic and perspective projection.)
    /// <summary>Switches the camera between orthographic and perspective projection.</summary>
    chkOrthoToggle: TCheckBox;
    //** @abstract(Chooses FitToBoundsMax over FitToBounds, so the model fits at every angle.)
    //**
    //** Checked, the model is framed once for every possible Azimuth, inclination and Roll and
    //** turning the dials only moves the camera round it. Unchecked, the model is framed
    //** exactly for the current angles and refitted after every dial change.
    /// <summary>Chooses FitToBoundsMax over FitToBounds, so the model fits at every
    /// angle.</summary>
    /// <remarks>Checked, the model is framed once for every possible Azimuth, inclination and
    /// Roll and turning the dials only moves the camera round it. Unchecked, the model is
    /// framed exactly for the current angles and refitted after every dial change.</remarks>
    chkFitAnyAngle: TCheckBox;
    //** @abstract(Sets up the viewport, light and camera, and picks the models folder.)
    //**
    //** The models folder is the library path on macOS, the home folder on Linux and
    //** @code('../../../') elsewhere; on Windows it is the current folder instead if that has a
    //** models subfolder. The handler creates a TGorillaViewport owned by ViewportLayout, a
    //** point light, and a TSprite3DCamera with a 45-degree FOV, which becomes the viewport's
    //** camera. The viewport runs at a fixed 60 frames per second without VSync.
    //**
    //** @param(Sender The form.)
    /// <summary>Sets up the viewport, light and camera, and picks the models folder.</summary>
    /// <remarks>The models folder is the library path on macOS, the home folder on Linux and
    /// <c>'../../../'</c> elsewhere; on Windows it is the current folder instead if that has a
    /// models subfolder. The handler creates a TGorillaViewport owned by ViewportLayout, a point
    /// light, and a TSprite3DCamera with a 45-degree FOV, which becomes the viewport's camera.
    /// The viewport runs at a fixed 60 frames per second without VSync.</remarks>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Loads a model from the models folder and fits the camera to it.)
    //**
    //** The file is named in this handler; change it there to try a different model. Shows a
    //** message and loads nothing if the file is missing or cannot be read.
    //**
    //** @param(Sender The form.)
    /// <summary>Loads a model from the models folder and fits the camera to it.</summary>
    /// <remarks>The file is named in this handler; change it there to try a different model.
    /// Shows a message and loads nothing if the file is missing or cannot be read.</remarks>
    /// <param name="Sender">The form.</param>
    procedure FormShow(Sender: TObject);
    //** @abstract(Copies AzimuthDial to the camera's Azimuth.)
    //**
    //** The dial value is negated and shifted into 0 to 360, shown in AzimuthText, and written
    //** to the camera; the model is then refitted for the new view.
    //**
    //** @param(Sender AzimuthDial.)
    /// <summary>Copies AzimuthDial to the camera's Azimuth.</summary>
    /// <remarks>The dial value is negated and shifted into 0 to 360, shown in AzimuthText, and
    /// written to the camera; the model is then refitted for the new view.</remarks>
    /// <param name="Sender">AzimuthDial.</param>
    procedure AzimuthDialChange(Sender: TObject);
    //** @abstract(Copies AngleDial to the camera's PolarAngle.)
    //**
    //** The dial value is negated and shifted into 0 to 360, shown in AngleText, and written to
    //** the camera; the model is then refitted. Values past 90 take the camera over the pole.
    //**
    //** @param(Sender AngleDial.)
    /// <summary>Copies AngleDial to the camera's PolarAngle.</summary>
    /// <remarks>The dial value is negated and shifted into 0 to 360, shown in AngleText, and
    /// written to the camera; the model is then refitted. Values past 90 take the camera over
    /// the pole.</remarks>
    /// <param name="Sender">AngleDial.</param>
    procedure AngleDialChange(Sender: TObject);
    //** @abstract(Copies RollDial to the camera's Roll.)
    //**
    //** The dial value is shifted into 0 to 360, without negating, shown in RollText, and
    //** written to the camera; the model is then refitted for the new view.
    //**
    //** @param(Sender RollDial.)
    /// <summary>Copies RollDial to the camera's Roll.</summary>
    /// <remarks>The dial value is shifted into 0 to 360, without negating, shown in RollText,
    /// and written to the camera; the model is then refitted for the new view.</remarks>
    /// <param name="Sender">RollDial.</param>
    procedure RollDialChange(Sender: TObject);
    //** @abstract(Refits the camera to the model when the viewport changes size.)
    //**
    //** Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is loaded.
    //**
    //** @param(Sender The TGorillaViewport.)
    /// <summary>Refits the camera to the model when the viewport changes size.</summary>
    /// <remarks>Assigned to the viewport's OnResize in FormCreate. Does nothing until a model is
    /// loaded.</remarks>
    /// <param name="Sender">The TGorillaViewport.</param>
    procedure GorillaViewportResize(Sender: TObject);
    //** @abstract(Switches the projection to match chkOrthoToggle and refits the model.)
    //**
    //** Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in the form
    //** caption, and calls FitToBounds, since the two modes size the view differently.
    //**
    //** @param(Sender chkOrthoToggle.)
    /// <summary>Switches the projection to match chkOrthoToggle and refits the model.</summary>
    /// <remarks>Sets ProjectionMode to cpOrthographic or cpPerspective, puts the mode's name in
    /// the form caption, and calls FitToBounds, since the two modes size the view
    /// differently.</remarks>
    /// <param name="Sender">chkOrthoToggle.</param>
    procedure chkOrthoToggleChange(Sender: TObject);
    //** @abstract(Refits the model when the fit mode changes.)
    //**
    //** @param(Sender chkFitAnyAngle.)
    /// <summary>Refits the model when the fit mode changes.</summary>
    /// <param name="Sender">chkFitAnyAngle.</param>
    procedure chkFitAnyAngleChange(Sender: TObject);
  private
    { Private declarations }
    FModelRotation: TPoint3D;
    FAzimuth: Single;
    FRoll: Single;
    FPolarAngle: Single;
    GorillaViewport: TGorillaViewport;
    GorillaLight: TGorillaLight;
    GorillaModel: TGorillaModel;
    GorillaCamera: TSprite3DCamera;
    ModelDir: String;
    procedure SwitchModel(const AModel: String);
    function FitModel: Boolean;
  public
    { Public declarations }
  end;

var
  //** @abstract(The main form, created by Application.CreateForm in Sprite3d.dpr.)
  /// <summary>The main form, created by Application.CreateForm in Sprite3d.dpr.</summary>
  MainForm: TMainForm;

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

procedure TMainForm.FormCreate(Sender: TObject);
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

  FAzimuth := 180;
  FRoll := 0;
  FPolarAngle := 0;

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

procedure TMainForm.AngleDialChange(Sender: TObject);
begin
  FPolarAngle := -AngleDial.Value;
  if FPolarAngle < 0 then
      FPolarAngle := FPolarAngle + 360;

  AngleText.Text := Format('%3.0f',[FPolarAngle]);

  GorillaCamera.PolarAngle := FPolarAngle;
end;

procedure TMainForm.AzimuthDialChange(Sender: TObject);
begin
  FAzimuth := -AzimuthDial.Value;

  AzimuthText.Text := Format('%3.0f',[FAzimuth + 180]);

  GorillaCamera.Azimuth := FAzimuth;
end;

procedure TMainForm.chkOrthoToggleChange(Sender: TObject);
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
  FitModel;
end;

procedure TMainForm.RollDialChange(Sender: TObject);
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
procedure TMainForm.FormShow(Sender: TObject);
begin
//  SwitchModel(ModelDir + 'models/TestAnimatedCharacter.glb');
  SwitchModel(ModelDir + 'models/TestStaticCharacter.glb');
end;

procedure TMainForm.GorillaViewportResize(Sender: TObject);
begin
  FitModel;
end;

// Refit after anything that changes the view: angles, size, projection or
// fit mode. FitToBounds is exact for the current angles only, so it has to
// be redone each time; FitToBoundsMax already allows for every angle, so
// redoing it after a dial change gives the same result.
function TMainForm.FitModel: Boolean;
begin
  Result := Assigned(GorillaCamera) and Assigned(GorillaModel);
  if Result then
    if chkFitAnyAngle.IsChecked then
      Result := GorillaCamera.FitToBoundsMax(GorillaModel)
    else
      Result := GorillaCamera.FitToBounds(GorillaModel);
end;

procedure TMainForm.chkFitAnyAngleChange(Sender: TObject);
begin
  FitModel;
end;

// Load a Model Clearing any old model first (so it Switches them)
// GorillaModel will be Nil on first call but set on subsequent calls
procedure TMainForm.SwitchModel(const AModel: String);
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
          DebugMemo.Lines.Add('---------- anims ---------------');
          for var AnimName in GorillaModel.AnimationManager.Animations.Keys do
            anims.Add(AnimName);
          DebugMemo.Lines.Add('--------------------------------');
          GorillaModel.AnimationManager.PlayAnimation(anims[anims.count - 1]);
        end;
    finally
      anims.Free;
    end;

    BBox := GorillaModel.GetBoundingBox();

    GorillaCamera.Roll := FRoll;
    GorillaCamera.Azimuth := FAzimuth;
    GorillaCamera.PolarAngle := FPolarAngle;

    GorillaModel.IsMarked := True;
    // The orange box is the one FitToBounds fits: the current pose's
    // bounds. IsMarked's designer box uses the static mesh and can differ
    // slightly from it on an animated model.
    GorillaModel.ShowBoundingBox := True;
    GorillaModel.Position.Point := Point3D(BBox.TopLeftNear.X + (BBox.Width / 2),
                                            BBox.TopLeftNear.Y + (BBox.Height / 2),
                                            BBox.TopLeftNear.Z + (BBox.Depth / 2));

    FModelRotation := Point3D(180, 0, 0);

    GorillaModel.RotationAngle.X := FModelRotation.X;
    GorillaModel.RotationAngle.Y := FModelRotation.Y;
    GorillaModel.RotationAngle.Z := FModelRotation.Z;

    if not FitModel then
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
