//** @abstract(Demo form for TSprite3DCamera: loads a model and drives the camera with dials.)
//**
//** The form has two tabs. The View tab holds a TGorillaViewport, created at run time, and a
//** panel of three dials for Azimuth, inclination and Roll, plus four check boxes: one shows
//** the model's own X, Y and Z axes through its centre of rotation, one a grid on its floor,
//** one chooses how the model is fitted, and one switches between perspective and orthographic
//** projection. The Debug tab holds a memo for log output.
//**
//** The camera starts with all three angles at 0, and each readout always shows its dial's
//** angle, from 0 to 359 degrees. Azimuth is sent to the camera reversed, 360 minus the
//** readout, so the view turns the right way for the dial. View, Variable, the default, lets
//** the dials set the angles; View, Isometric sets the camera to PolarAngle 35.264, Azimuth 45
//** and Roll 0, the true isometric view, and switches the dials off. A test slider along the
//** bottom of the 3D view moves the camera out from the fitted distance, x1 to x20.
//**
//** On show, the form loads the model whose file FormShow names; File, OpenModel then loads any
//** other glTF, FBX, OBJ, USD, Collada, STL or PLY file. Each model replaces the last: it plays
//** its last animation by name if it has any, is centred and turned 180 degrees about X, and
//** the camera is fitted so it fills the view. The model is refitted when the viewport is
//** resized, the projection changes or the "Fit any angle" box is toggled, but not when a dial
//** turns. Checked, that box uses FitToBoundsMax, which frames the model for every angle at
//** once, so the dials can never push it out of view. Unchecked, FitToBounds frames it exactly
//** for the angles at the time of the fit, and turning a dial afterwards can push part of it
//** past the edge until the next refit.
//**
//** @preformatted(
//** TabControl1
//** |-- GorillaTab "View"
//** |   `-- MainLayout
//** |       |-- ViewportLayout   owns the TGorillaViewport
//** |       |   `-- DistanceLayout   test strip: DistanceLabel, DistanceTrack
//** |       `-- ControlsLayout   dials, labels, four check boxes
//** `-- DebugTab "Debug"
//**     `-- DebugMemo
//**
//** MainMenu1
//** |-- FileMenu "File"
//** |   `-- OpenModelMenuItem "OpenModel"   shows OpenDialog1
//** `-- ViewMenu "View"
//**     |-- ViewVariableItem "Variable"    dials set the angles
//**     `-- ViewIsometricItem "Isometric"  fixed isometric angles
//** )
unit Sprite3dMain;
{
  Demo form for TSprite3DCamera: loads a model and drives the camera with dials.
  The form has two tabs. The View tab holds a TGorillaViewport, created at
  run time, and a panel of three dials for Azimuth, inclination and Roll,
  plus four check boxes: one shows the model's own X, Y and Z axes through
  its centre of rotation, one a grid on its floor, one chooses how the model
  is fitted, and one switches between perspective and orthographic
  projection. The Debug tab holds a memo for log output.
  The camera starts with all three angles at 0, and each readout always
  shows its dial's angle, from 0 to 359 degrees. Azimuth is sent to the
  camera reversed, 360 minus the readout, so the view turns the right way
  for the dial. View, Variable, the default, lets the dials set the angles;
  View, Isometric sets the camera to PolarAngle 35.264, Azimuth 45 and Roll
  0, the true isometric view, and switches the dials off. A test slider
  along the bottom of the 3D view moves the camera out from the fitted
  distance, x1 to x20.
  On show, the form loads the model whose file FormShow names; File,
  OpenModel then loads any other glTF, FBX, OBJ, USD, Collada, STL or PLY
  file. Each model replaces the last: it plays its last animation by name if
  it has any, is centred and turned 180 degrees about X, and the camera is
  fitted so it fills the view. The model is refitted when the viewport is
  resized, the projection changes or the "Fit any angle" box is toggled, but
  not when a dial turns. Checked, that box uses FitToBoundsMax, which frames
  the model for every angle at once, so the dials can never push it out of
  view. Unchecked, FitToBounds frames it exactly for the angles at the time
  of the fit, and turning a dial afterwards can push part of it past the
  edge until the next refit.
    TabControl1
    |-- GorillaTab "View"
    |   `-- MainLayout
    |       |-- ViewportLayout   owns the TGorillaViewport
    |       |   `-- DistanceLayout   test strip: DistanceLabel, DistanceTrack
    |       `-- ControlsLayout   dials, labels, four check boxes
    `-- DebugTab "Debug"
        `-- DebugMemo

    MainMenu1
    |-- FileMenu "File"
    |   `-- OpenModelMenuItem "OpenModel"   shows OpenDialog1
    `-- ViewMenu "View"
        |-- ViewVariableItem "Variable"    dials set the angles
        `-- ViewIsometricItem "Isometric"  fixed isometric angles
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Math.Vectors, Gorilla.Control, Gorilla.Transform, Gorilla.Mesh,
  Gorilla.Model, FMX.Controls3D, Gorilla.Light, Gorilla.Viewport,
  FMX.TabControl, FMX.Layouts, Gorilla.Controller, Gorilla.Animation.Controller,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Objects3D, Gorilla.Camera, Sprite3dCamera, FMX.Menus;

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
    //** @abstract(Test strip along the bottom of the 3D view holding the distance slider.)
    //**
    //** For testing only; delete it, with DistanceLabel, DistanceTrack and
    //** DistanceTrackChange, when it is no longer needed. The model is then always shown at
    //** the fitted distance.
    /// <summary>Test strip along the bottom of the 3D view holding the distance
    /// slider.</summary>
    /// <remarks>For testing only; delete it, with DistanceLabel, DistanceTrack and
    /// DistanceTrackChange, when it is no longer needed. The model is then always shown at
    /// the fitted distance.</remarks>
    DistanceLayout: TLayout;
    //** @abstract(Shows the distance slider's factor, such as "Distance x2.5".)
    /// <summary>Shows the distance slider's factor, such as "Distance x2.5".</summary>
    DistanceLabel: TLabel;
    //** @abstract(Moves the camera out from the fitted distance, from x1 to x20; test only.)
    //**
    //** See DistanceTrackChange.
    /// <summary>Moves the camera out from the fitted distance, from x1 to x20; test
    /// only.</summary>
    /// <remarks>See <see cref="DistanceTrackChange"/>.</remarks>
    DistanceTrack: TTrackBar;
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
    //** Checked, the model is framed for every possible Azimuth, inclination and Roll, so
    //** turning the dials only moves the camera round it and the model always stays in view.
    //** Unchecked, the model is framed exactly for the angles at the time of the fit; turning a
    //** dial afterwards can push part of it past the edge until the next refit, which happens
    //** on a resize, a projection change or toggling this box.
    /// <summary>Chooses FitToBoundsMax over FitToBounds, so the model fits at every
    /// angle.</summary>
    /// <remarks>Checked, the model is framed for every possible Azimuth, inclination and Roll,
    /// so turning the dials only moves the camera round it and the model always stays in view.
    /// Unchecked, the model is framed exactly for the angles at the time of the fit; turning a
    /// dial afterwards can push part of it past the edge until the next refit, which happens on
    /// a resize, a projection change or toggling this box.</remarks>
    chkFitAnyAngle: TCheckBox;
    //** @abstract(Shows or hides the model's X, Y and Z axes; checked at start-up.)
    //**
    //** Checked, every model is loaded with ShowModelAxes from Sprite3DAxes, which draws red,
    //** green and blue lines through its centre of rotation; unchecked, they are removed.
    /// <summary>Shows or hides the model's X, Y and Z axes; checked at start-up.</summary>
    /// <remarks>Checked, every model is loaded with ShowModelAxes from Sprite3DAxes, which draws
    /// red, green and blue lines through its centre of rotation; unchecked, they are
    /// removed.</remarks>
    chkShowAxes: TCheckBox;
    //** @abstract(Shows or hides the floor grid; checked at start-up.)
    //**
    //** Checked, every model is loaded with ShowModelGrid from Sprite3DGrid, which draws a
    //** shader grid of grey lines 1.0 apart on the model's floor; unchecked, it is removed.
    /// <summary>Shows or hides the floor grid; checked at start-up.</summary>
    /// <remarks>Checked, every model is loaded with ShowModelGrid from Sprite3DGrid, which draws
    /// a shader grid of grey lines 1.0 apart on the model's floor; unchecked, it is
    /// removed.</remarks>
    chkShowGrid: TCheckBox;
    //** @abstract(Asks for the model file that File, OpenModel loads.)
    //**
    //** Its filter, set in the form designer, offers only the formats the unit has loaders
    //** for: .glb, .gltf, .fbx, .obj, .usdc, .dae, .stl and .ply, all together first and then
    //** one at a time.
    /// <summary>Asks for the model file that File, OpenModel loads.</summary>
    /// <remarks>Its filter, set in the form designer, offers only the formats the unit has
    /// loaders for: .glb, .gltf, .fbx, .obj, .usdc, .dae, .stl and .ply, all together first and
    /// then one at a time.</remarks>
    OpenDialog1: TOpenDialog;
    //** @abstract(The form's menu bar, holding FileMenu.)
    /// <summary>The form's menu bar, holding FileMenu.</summary>
    MainMenu1: TMainMenu;
    //** @abstract(The "File" menu, holding OpenModelMenuItem.)
    /// <summary>The "File" menu, holding OpenModelMenuItem.</summary>
    FileMenu: TMenuItem;
    //** @abstract(The "OpenModel" item; see OpenModelMenuItemClick.)
    /// <summary>The "OpenModel" item; see <see cref="OpenModelMenuItemClick"/>.</summary>
    OpenModelMenuItem: TMenuItem;
    //** @abstract(The "View" menu, choosing how the camera angles are set.)
    //**
    //** Its items form one radio group: Variable or Isometric.
    /// <summary>The "View" menu, choosing how the camera angles are set.</summary>
    /// <remarks>Its items form one radio group: Variable or Isometric.</remarks>
    ViewMenu: TMenuItem;
    //** @abstract(The "Variable" view, checked at start-up; see ViewVariableItemClick.)
    /// <summary>The "Variable" view, checked at start-up; see
    /// <see cref="ViewVariableItemClick"/>.</summary>
    ViewVariableItem: TMenuItem;
    //** @abstract(The "Isometric" view; see ViewIsometricItemClick.)
    /// <summary>The "Isometric" view; see <see cref="ViewIsometricItemClick"/>.</summary>
    ViewIsometricItem: TMenuItem;
    //** @abstract(Sets up the viewport, light and camera, and picks the models folder.)
    //**
    //** The models folder is the library path on macOS, the home folder on Linux and
    //** @code('../../../') elsewhere; on Windows it is the current folder instead if that has a
    //** models subfolder. The handler creates a TGorillaViewport owned by ViewportLayout, a
    //** point light, and a TSprite3DCamera with a 45-degree FOV, which becomes the viewport's
    //** camera. The viewport runs at a fixed 60 frames per second without VSync.
    //**
    //** The camera starts with all three angles at 0. The dials are turned to
    //** those angles and the readouts set to match, so dial, readout and camera agree from the
    //** start.
    //**
    //** @param(Sender The form.)
    /// <summary>Sets up the viewport, light and camera, and picks the models folder.</summary>
    /// <remarks><para>The models folder is the library path on macOS, the home folder on Linux
    /// and <c>'../../../'</c> elsewhere; on Windows it is the current folder instead if that has
    /// a models subfolder. The handler creates a TGorillaViewport owned by ViewportLayout, a
    /// point light, and a TSprite3DCamera with a 45-degree FOV, which becomes the viewport's
    /// camera. The viewport runs at a fixed 60 frames per second without VSync.</para>
    /// <para>The camera starts with all three angles at 0. The dials are turned to
    /// those angles and the readouts set to match, so dial, readout and camera agree from the
    /// start.</para></remarks>
    /// <param name="Sender">The form.</param>
    procedure FormCreate(Sender: TObject);
    //** @abstract(Loads the first model from the models folder and fits the camera to it.)
    //**
    //** The file is named in this handler; change it there to start with a different model, or
    //** use File, OpenModel once the form is up. Shows a message and loads nothing if the file
    //** is missing or cannot be read.
    //**
    //** @param(Sender The form.)
    /// <summary>Loads the first model from the models folder and fits the camera to
    /// it.</summary>
    /// <remarks>The file is named in this handler; change it there to start with a different
    /// model, or use File, OpenModel once the form is up. Shows a message and loads nothing if
    /// the file is missing or cannot be read.</remarks>
    /// <param name="Sender">The form.</param>
    procedure FormShow(Sender: TObject);
    //** @abstract(Copies AzimuthDial to the camera's Azimuth.)
    //**
    //** The dial value is negated, wrapped into 0 to 360 and shown in AzimuthText. The camera
    //** gets the angle reversed, 360 minus the readout, so the view turns the right way for the
    //** dial. The model is not refitted; see chkFitAnyAngle.
    //**
    //** @param(Sender AzimuthDial.)
    /// <summary>Copies AzimuthDial to the camera's Azimuth.</summary>
    /// <remarks>The dial value is negated, wrapped into 0 to 360 and shown in AzimuthText. The
    /// camera gets the angle reversed, 360 minus the readout, so the view turns the right way
    /// for the dial. The model is not refitted; see <see cref="chkFitAnyAngle"/>.</remarks>
    /// <param name="Sender">AzimuthDial.</param>
    procedure AzimuthDialChange(Sender: TObject);
    //** @abstract(Copies AngleDial to the camera's PolarAngle.)
    //**
    //** The dial value is negated and wrapped into 0 to 360, shown in AngleText and written to
    //** the camera. Values past 90 take the camera over the pole. The model is not refitted;
    //** see chkFitAnyAngle.
    //**
    //** @param(Sender AngleDial.)
    /// <summary>Copies AngleDial to the camera's PolarAngle.</summary>
    /// <remarks>The dial value is negated and wrapped into 0 to 360, shown in AngleText and
    /// written to the camera. Values past 90 take the camera over the pole. The model is not
    /// refitted; see <see cref="chkFitAnyAngle"/>.</remarks>
    /// <param name="Sender">AngleDial.</param>
    procedure AngleDialChange(Sender: TObject);
    //** @abstract(Copies RollDial to the camera's Roll.)
    //**
    //** The dial value is wrapped into 0 to 360, without negating, shown in RollText and written
    //** to the camera. The model is not refitted; see chkFitAnyAngle.
    //**
    //** @param(Sender RollDial.)
    /// <summary>Copies RollDial to the camera's Roll.</summary>
    /// <remarks>The dial value is wrapped into 0 to 360, without negating, shown in RollText
    /// and written to the camera. The model is not refitted; see
    /// <see cref="chkFitAnyAngle"/>.</remarks>
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
    //** @abstract(Adds or removes the model's axes to match chkShowAxes.)
    //**
    //** Does nothing until a model is loaded.
    //**
    //** @param(Sender chkShowAxes.)
    /// <summary>Adds or removes the model's axes to match chkShowAxes.</summary>
    /// <remarks>Does nothing until a model is loaded.</remarks>
    /// <param name="Sender">chkShowAxes.</param>
    procedure chkShowAxesChange(Sender: TObject);
    //** @abstract(Adds or removes the floor grid to match chkShowGrid.)
    //**
    //** Does nothing until a model is loaded.
    //**
    //** @param(Sender chkShowGrid.)
    /// <summary>Adds or removes the floor grid to match chkShowGrid.</summary>
    /// <remarks>Does nothing until a model is loaded.</remarks>
    /// <param name="Sender">chkShowGrid.</param>
    procedure chkShowGridChange(Sender: TObject);
    //** @abstract(Lets the user pick a model file and loads it in place of the current one.)
    //**
    //** Shows OpenDialog1 and passes the chosen file to SwitchModel, which clears the old model
    //** and loads the new one with the current camera angles and fit mode. Nothing changes if
    //** the dialog is cancelled. A file that fails to load is reported by SwitchModel, and the
    //** view is then left empty until another model loads.
    //**
    //** @param(Sender OpenModelMenuItem.)
    /// <summary>Lets the user pick a model file and loads it in place of the current
    /// one.</summary>
    /// <remarks>Shows OpenDialog1 and passes the chosen file to SwitchModel, which clears the old
    /// model and loads the new one with the current camera angles and fit mode. Nothing changes
    /// if the dialog is cancelled. A file that fails to load is reported by SwitchModel, and the
    /// view is then left empty until another model loads.</remarks>
    /// <param name="Sender">OpenModelMenuItem.</param>
    procedure OpenModelMenuItemClick(Sender: TObject);
    //** @abstract(Hands the camera angles back to the dials.)
    //**
    //** Checks the Variable item and turns the three dials back on. The camera keeps its
    //** current angles until a dial is turned.
    //**
    //** @param(Sender ViewVariableItem.)
    /// <summary>Hands the camera angles back to the dials.</summary>
    /// <remarks>Checks the Variable item and turns the three dials back on. The camera keeps
    /// its current angles until a dial is turned.</remarks>
    /// <param name="Sender">ViewVariableItem.</param>
    procedure ViewVariableItemClick(Sender: TObject);
    //** @abstract(Sets the isometric view and fixes it.)
    //**
    //** Sets the camera's PolarAngle to 35.264, the true isometric elevation, its Azimuth to
    //** 45 and its Roll to 0, turns the dials to match and switches them off, then refits the
    //** model for the new view. Because azimuth is sent to the camera reversed, the azimuth
    //** readout shows 315.
    //**
    //** @param(Sender ViewIsometricItem.)
    /// <summary>Sets the isometric view and fixes it.</summary>
    /// <remarks>Sets the camera's PolarAngle to 35.264, the true isometric elevation, its
    /// Azimuth to 45 and its Roll to 0, turns the dials to match and switches them off, then
    /// refits the model for the new view. Because azimuth is sent to the camera reversed, the
    /// azimuth readout shows 315.</remarks>
    /// <param name="Sender">ViewIsometricItem.</param>
    procedure ViewIsometricItemClick(Sender: TObject);
    //** @abstract(Moves the camera out by the slider's factor; test only.)
    //**
    //** In perspective mode the camera's Distance becomes the fitted distance times the
    //** factor; in orthographic mode, where distance does not change the size, OrthoHeight
    //** is scaled instead. The factor is kept when the model is refitted.
    //**
    //** @param(Sender DistanceTrack.)
    /// <summary>Moves the camera out by the slider's factor; test only.</summary>
    /// <remarks>In perspective mode the camera's Distance becomes the fitted distance times
    /// the factor; in orthographic mode, where distance does not change the size, OrthoHeight
    /// is scaled instead. The factor is kept when the model is refitted.</remarks>
    /// <param name="Sender">DistanceTrack.</param>
    procedure DistanceTrackChange(Sender: TObject);
  private
    { Private declarations }
    FModelRotation: TPoint3D;
    FAzimuth: Single;
    FRoll: Single;
    FPolarAngle: Single;
    // Camera Distance and OrthoHeight from the last fit, before the test
    // distance factor is applied
    FFitDistance: Single;
    FFitOrthoHeight: Single;
    GorillaViewport: TGorillaViewport;
    GorillaLight: TGorillaLight;
    GorillaModel: TGorillaModel;
    GorillaCamera: TSprite3DCamera;
    ModelDir: String;
    procedure SwitchModel(const AModel: String);
    function FitModel: Boolean;
    procedure ApplyAngles;
    procedure ApplyDistance;
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
  FMX.Types3D,
  Sprite3DAxes, Sprite3DGrid;

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

  FAzimuth := 0;
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
  // Fill the space the bottom test strip (DistanceLayout) leaves
  GorillaViewport.Align := TAlignLayout.Client;

  // Point the dials at the starting angles, then show those angles and give
  // them to the camera. Setting a dial fires its OnChange, which reads the
  // same angle back, so the fields keep their values; ApplyAngles covers a
  // dial that was already in place and so fired nothing.
  AzimuthDial.Value := -FAzimuth;
  AngleDial.Value := -FPolarAngle;
  RollDial.Value := FRoll;
  ApplyAngles;
end;

{ Shift an angle in degrees by whole turns into [0, 360) }
function Wrap360(const ADegrees: Single): Single;
begin
  Result := ADegrees - 360 * Floor(ADegrees / 360);
end;

{ Show the readout for a wrapped angle: whole degrees, never "360" }
function DegreesText(const ADegrees: Single): String;
begin
  Result := Format('%3d', [Round(ADegrees) mod 360]);
end;

// The single place where dial changes reach the readouts and the camera,
// so they can never disagree. Azimuth goes to the camera reversed (360
// minus the readout) so the view turns the right way for the dial.
// Dials do not refit: with "Fit any angle" off, turning one can push the
// model past the edge until the next refit; with it on, it never does.
procedure TMainForm.ApplyAngles;
begin
  AzimuthText.Text := DegreesText(FAzimuth);
  AngleText.Text := DegreesText(FPolarAngle);
  RollText.Text := DegreesText(FRoll);
  if Assigned(GorillaCamera) then
  begin
    GorillaCamera.Azimuth := Wrap360(-FAzimuth);
    GorillaCamera.PolarAngle := FPolarAngle;
    GorillaCamera.Roll := FRoll;
  end;
end;

procedure TMainForm.AngleDialChange(Sender: TObject);
begin
  FPolarAngle := Wrap360(-AngleDial.Value);
  ApplyAngles;
end;

procedure TMainForm.AzimuthDialChange(Sender: TObject);
begin
  FAzimuth := Wrap360(-AzimuthDial.Value);
  ApplyAngles;
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
  FRoll := Wrap360(RollDial.Value);
  ApplyAngles;
end;

// On startup load a default Model as specified by DefaultLoadType
// The directory layout of models/Orientation follows this pattern
// to allow easy addition of new Model types
procedure TMainForm.FormShow(Sender: TObject);
begin
  SwitchModel(ModelDir + 'models/TestAnimatedCharacter.glb');
//  SwitchModel(ModelDir + 'models/TestStaticCharacter.glb');
end;

procedure TMainForm.GorillaViewportResize(Sender: TObject);
begin
  FitModel;
end;

procedure TMainForm.OpenModelMenuItemClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    SwitchModel(OpenDialog1.Filename);
end;

procedure TMainForm.ViewVariableItemClick(Sender: TObject);
begin
  ViewVariableItem.IsChecked := True;
  ViewIsometricItem.IsChecked := False;
  AzimuthDial.Enabled := True;
  AngleDial.Enabled := True;
  RollDial.Enabled := True;
end;

procedure TMainForm.ViewIsometricItemClick(Sender: TObject);
const
  // Camera angles: the true isometric elevation is ArcTan(1 / Sqrt(2))
  ISO_POLAR = 35.264;
  ISO_AZIMUTH = 45;
  ISO_ROLL = 0;
begin
  ViewVariableItem.IsChecked := False;
  ViewIsometricItem.IsChecked := True;
  // The dial fields hold the readout values; azimuth reaches the camera
  // reversed (see ApplyAngles), so the readout is the reverse of 45
  FAzimuth := Wrap360(-ISO_AZIMUTH);
  FPolarAngle := ISO_POLAR;
  FRoll := ISO_ROLL;
  // Turn the dials to match; their OnChange reads the same angles back
  AzimuthDial.Value := -FAzimuth;
  AngleDial.Value := -FPolarAngle;
  RollDial.Value := FRoll;
  ApplyAngles;
  AzimuthDial.Enabled := False;
  AngleDial.Enabled := False;
  RollDial.Enabled := False;
  FitModel;   // a deliberate change of view, so frame the model for it
end;

// Refit after a change of model, size, projection or fit mode. The dials do
// not call this: FitToBoundsMax already allows for every angle, and with
// FitToBounds a dial turn is allowed to push the model past the edge.
function TMainForm.FitModel: Boolean;
begin
  Result := Assigned(GorillaCamera) and Assigned(GorillaModel);
  if not Result then
    Exit;
  if chkFitAnyAngle.IsChecked then
    Result := GorillaCamera.FitToBoundsMax(GorillaModel)
  else
    Result := GorillaCamera.FitToBounds(GorillaModel);
  if Result then
  begin
    // Remember the fit, then apply the test distance factor on top of it
    FFitDistance := GorillaCamera.Distance;
    FFitOrthoHeight := GorillaCamera.OrthoHeight;
    ApplyDistance;
  end;
end;

// Test only: the fitted view moved out by the distance slider's factor
procedure TMainForm.ApplyDistance;
var
  Factor: Single;
begin
  Factor := DistanceTrack.Value;
  DistanceLabel.Text := Format('Distance x%.1f', [Factor]);
  if not Assigned(GorillaCamera) or (FFitDistance <= 0) then
    Exit;
  if GorillaCamera.IsOrthographic then
    GorillaCamera.OrthoHeight := FFitOrthoHeight * Factor
  else
    GorillaCamera.Distance := FFitDistance * Factor;
end;

procedure TMainForm.DistanceTrackChange(Sender: TObject);
begin
  ApplyDistance;
end;

procedure TMainForm.chkFitAnyAngleChange(Sender: TObject);
begin
  FitModel;
end;

procedure TMainForm.chkShowAxesChange(Sender: TObject);
begin
  if chkShowAxes.IsChecked then
    ShowModelAxes(GorillaModel)
  else
    HideModelAxes(GorillaModel);
end;

procedure TMainForm.chkShowGridChange(Sender: TObject);
begin
  if chkShowGrid.IsChecked then
    ShowModelGrid(GorillaModel)
  else
    HideModelGrid(GorillaModel);
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
    GorillaCamera.Azimuth := Wrap360(-FAzimuth);
    GorillaCamera.PolarAngle := FPolarAngle;

    // Draw the box that FitToBounds and FitToBoundsMax fit: the bounds of
    // the current pose, in Gorilla's default orange.
    GorillaModel.ShowBoundingBox := True;
    // Axes through the centre of rotation, sized for the newly loaded model
    if chkShowAxes.IsChecked then
      ShowModelAxes(GorillaModel);
    GorillaModel.Position.Point := Point3D(BBox.TopLeftNear.X + (BBox.Width / 2),
                                            BBox.TopLeftNear.Y + (BBox.Height / 2),
                                            BBox.TopLeftNear.Z + (BBox.Depth / 2));

    FModelRotation := Point3D(180, 0, 0);

    GorillaModel.RotationAngle.X := FModelRotation.X;
    GorillaModel.RotationAngle.Y := FModelRotation.Y;
    GorillaModel.RotationAngle.Z := FModelRotation.Z;

    // Floor grid, after the model is placed and turned, because the floor
    // depends on which way up it is
    if chkShowGrid.IsChecked then
      ShowModelGrid(GorillaModel);

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
