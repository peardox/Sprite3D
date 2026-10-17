//** @abstract(Demo form for TSprite3DCamera: loads a model and drives the camera with dials.)
//**
//** The form has two tabs. The View tab holds a TGorillaViewport, created at run time, and a
//** panel of three dials for Azimuth, inclination and Roll, plus four check boxes: one shows
//** the model's own X, Y and Z axes through its centre of rotation, one a grid on its floor,
//** one chooses how the model is fitted, and one switches between perspective and orthographic
//** projection. The Debug tab holds a memo for log output.
//**
//** The camera starts in the isometric view, and each readout always shows its dial's angle,
//** from 0 to 359 degrees. Azimuth is sent to the camera reversed, 360 minus the readout, so
//** the view turns the right way for the dial. View, Variable lets the dials set the angles;
//** View, Isometric, the default for now, sets the readouts to inclination 35.264, azimuth 45
//** and roll 0, the true isometric view, and switches the dials off; View, Pixel 2:1 does the
//** same with an inclination of about 26.565; View, 3/4 View uses 45 degrees through the
//** orthographic camera; View, Head On and View, Top Down use inclinations of 0 and 90 at
//** azimuth 0; and View, Side View uses inclination 0 at azimuth 90. A test slider along the
//** bottom of the 3D view moves the camera out from the fitted distance, x1 to x20.
//**
//** On show, the form loads the model whose file FormShow names; File, OpenModel then loads any
//** other glTF, FBX, OBJ, USD, Collada, STL or PLY file, and File, Exit closes the application.
//** File, Grab renders the view off screen at 256 by 256 pixels, with the model fitted to fill
//** it, and saves it as the next of grab001.png, grab002.png and so on in SaveFolder, asking
//** for that folder the first time.
//** Each model replaces the last: it plays its last animation by name if it has any, is centred
//** and turned 180 degrees about X, and the camera is fitted so it fills the view. The model is
//** refitted when the viewport is resized, the projection changes or the "Fit any angle" box is
//** toggled, but not when a dial turns. Checked, that box uses FitToBoundsMax, which frames the
//** model for every angle at once, so the dials can never push it out of view. Unchecked,
//** FitToBounds frames it exactly for the angles at the time of the fit, and turning a dial
//** afterwards can push part of it past the edge until the next refit.
//**
//** The form only handles the user interface. The 3D work is done by the library units in
//** @code(lib): Sprite3DCamera, Sprite3DAxes, Sprite3DGrid and Sprite3DOffscreen. The
//** application's other rules, such as where models are found, how a model is loaded and
//** placed, and how grabs are named and saved, are in Sprite3DHelpers.
//**
//** On Android and iOS, where FMX shows no menu bar, the same menus are reached through a
//** hamburger button on a toolbar at the top, which opens a drawer listing every item in
//** MainMenu1; ticks show the current View. Exit is left out on iOS.
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
//** |   |-- OpenModelMenuItem "OpenModel"   shows OpenDialog1
//** |   |-- GrabMenuItem "Grab"             saves the off-screen view as grabNNN.png
//** |   `-- ExitMenuItem "Exit"             closes the application
//** `-- ViewMenu "View"
//**     |-- ViewVariableItem "Variable"     dials set the angles
//**     |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
//**     |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
//**     |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45, orthographic
//**     |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
//**     |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
//**     `-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
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
  The camera starts in the isometric view, and each readout always shows its
  dial's angle, from 0 to 359 degrees. Azimuth is sent to the camera
  reversed, 360 minus the readout, so the view turns the right way for the
  dial. View, Variable lets the dials set the angles; View, Isometric, the
  default for now, sets the readouts to inclination 35.264, azimuth 45 and
  roll 0, the true isometric view, and switches the dials off; View, Pixel
  2:1 does the same with an inclination of about 26.565; View, 3/4 View uses
  45 degrees through the orthographic camera; View, Head On and View, Top
  Down use inclinations of 0 and 90 at azimuth 0; and View, Side View uses
  inclination 0 at azimuth 90. A test slider along the bottom of the 3D view
  moves the camera out from the fitted distance, x1 to x20.
  On show, the form loads the model whose file FormShow names; File,
  OpenModel then loads any other glTF, FBX, OBJ, USD, Collada, STL or PLY
  file, and File, Exit closes the application. File, Grab renders the view
  off screen at 256 by 256 pixels, with the model fitted to fill it, and
  saves it as the next of grab001.png, grab002.png and so on in SaveFolder,
  asking for that folder the first time. Each model replaces the last:
  it plays its last animation by name if it has any, is centred and turned
  180 degrees about X, and the camera is fitted so it fills the view. The
  model is refitted when the viewport is resized, the projection changes or
  the "Fit any angle" box is toggled, but not when a dial turns. Checked,
  that box uses FitToBoundsMax, which frames the model for every angle at
  once, so the dials can never push it out of view. Unchecked, FitToBounds
  frames it exactly for the angles at the time of the fit, and turning a
  dial afterwards can push part of it past the edge until the next refit.
    TabControl1
    |-- GorillaTab "View"
    |   `-- MainLayout
    |       |-- ViewportLayout   owns the TGorillaViewport
    |       |   `-- DistanceLayout   test strip: DistanceLabel, DistanceTrack
    |       `-- ControlsLayout   dials, labels, four check boxes
    `-- DebugTab "Debug"
        `-- DebugMemo

    The form only handles the user interface. The 3D work is done by the
    library units in lib: Sprite3DCamera, Sprite3DAxes, Sprite3DGrid and
    Sprite3DOffscreen. The application's other rules, such as where models
    are found, how a model is loaded and placed, and how grabs are named and
    saved, are in Sprite3DHelpers.

    On Android and iOS, where FMX shows no menu bar, the same menus are
    reached through a hamburger button on a toolbar at the top, which opens a
    drawer listing every item in MainMenu1; ticks show the current View.
    Exit is left out on iOS.

    MainMenu1
    |-- FileMenu "File"
    |   |-- OpenModelMenuItem "OpenModel"   shows OpenDialog1
    |   |-- GrabMenuItem "Grab"             saves the off-screen view as grabNNN.png
    |   `-- ExitMenuItem "Exit"             closes the application
    `-- ViewMenu "View"
        |-- ViewVariableItem "Variable"     dials set the angles
        |-- ViewIsometricItem "Isometric"   fixed, inclination about 35.264
        |-- ViewPixel2To1Item "Pixel 2:1"   fixed, inclination about 26.565
        |-- ViewThreeQuarterItem "3/4 View" fixed, inclination 45, orthographic
        |-- ViewHeadOnItem "Head On"        fixed, inclination 0, azimuth 0
        |-- ViewTopDownItem "Top Down"      fixed, inclination 90, azimuth 0
        `-- ViewSideItem "Side View"        fixed, inclination 0, azimuth 90
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Math.Vectors, Gorilla.Control, Gorilla.Transform, Gorilla.Mesh,
  Gorilla.Model, FMX.Controls3D, Gorilla.Light, Gorilla.Viewport,
  FMX.TabControl, FMX.Layouts, Gorilla.Controller, Gorilla.Animation.Controller,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Objects3D, Gorilla.Camera, Sprite3dCamera, FMX.Menus,
  Sprite3DOffscreen
  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  , FMX.MultiView, FMX.ListBox
  {$ENDIF}
  ;

type
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
    //** @abstract(The "File" menu, holding OpenModelMenuItem, GrabMenuItem and ExitMenuItem.)
    /// <summary>The "File" menu, holding OpenModelMenuItem, GrabMenuItem and
    /// ExitMenuItem.</summary>
    FileMenu: TMenuItem;
    //** @abstract(The "OpenModel" item; see OpenModelMenuItemClick.)
    /// <summary>The "OpenModel" item; see <see cref="OpenModelMenuItemClick"/>.</summary>
    OpenModelMenuItem: TMenuItem;
    //** @abstract(The "Grab" item; see GrabMenuItemClick.)
    /// <summary>The "Grab" item; see <see cref="GrabMenuItemClick"/>.</summary>
    GrabMenuItem: TMenuItem;
    //** @abstract(Separator line in the File menu, above Exit.)
    /// <summary>Separator line in the File menu, above Exit.</summary>
    FileSeparatorItem: TMenuItem;
    //** @abstract(The "Exit" item; see ExitMenuItemClick.)
    /// <summary>The "Exit" item; see <see cref="ExitMenuItemClick"/>.</summary>
    ExitMenuItem: TMenuItem;
    //** @abstract(The "View" menu, choosing how the camera angles are set.)
    //**
    //** Its items form one radio group: Variable, where the dials set the angles, and the
    //** fixed views Isometric, Pixel 2:1, 3/4 View, Head On, Top Down and Side
    //** View. Choosing an item clears every check in the menu, sets the view, then checks that
    //** item.
    /// <summary>The "View" menu, choosing how the camera angles are set.</summary>
    /// <remarks>Its items form one radio group: Variable, where the dials set the angles, and
    /// the fixed views Isometric, Pixel 2:1, 3/4 View, Head On, Top Down and Side
    /// View. Choosing an item clears every check in the menu, sets the view, then checks that
    /// item.</remarks>
    ViewMenu: TMenuItem;
    //** @abstract(The "Variable" view; see ViewVariableItemClick.)
    /// <summary>The "Variable" view; see <see cref="ViewVariableItemClick"/>.</summary>
    ViewVariableItem: TMenuItem;
    //** @abstract(The "Isometric" view, chosen at start-up; see ViewIsometricItemClick.)
    /// <summary>The "Isometric" view, chosen at start-up; see
    /// <see cref="ViewIsometricItemClick"/>.</summary>
    ViewIsometricItem: TMenuItem;
    //** @abstract(The "Pixel 2:1" view; see ViewPixel2To1ItemClick.)
    /// <summary>The "Pixel 2:1" view; see <see cref="ViewPixel2To1ItemClick"/>.</summary>
    ViewPixel2To1Item: TMenuItem;
    //** @abstract(The "3/4 View" view; see ViewThreeQuarterItemClick.)
    /// <summary>The "3/4 View" view; see <see cref="ViewThreeQuarterItemClick"/>.</summary>
    ViewThreeQuarterItem: TMenuItem;
    //** @abstract(The "Head On" view; see ViewHeadOnItemClick.)
    /// <summary>The "Head On" view; see <see cref="ViewHeadOnItemClick"/>.</summary>
    ViewHeadOnItem: TMenuItem;
    //** @abstract(The "Top Down" view; see ViewTopDownItemClick.)
    /// <summary>The "Top Down" view; see <see cref="ViewTopDownItemClick"/>.</summary>
    ViewTopDownItem: TMenuItem;
    //** @abstract(The "Side View" view; see ViewSideItemClick.)
    /// <summary>The "Side View" view; see <see cref="ViewSideItemClick"/>.</summary>
    ViewSideItem: TMenuItem;
    //** @abstract(Sets up the viewport, light and camera, and picks the models folder.)
    //**
    //** The models folder comes from DefaultModelDir in Sprite3DHelpers: it is the library path
    //** on macOS, the home folder on Linux and @code('../../../') elsewhere; on Windows it is the
    //** current folder instead if that has a models subfolder. The handler creates a
    //** TGorillaViewport owned by ViewportLayout, a point light, and a TSprite3DCamera with a
    //** 45-degree FOV, which becomes the viewport's camera. The viewport runs at a fixed 60 frames per second without VSync.
    //**
    //** The dials start at 0, then the isometric view is chosen, as View, Isometric does:
    //** the dials are turned to its angles and switched off, and the readouts set to match,
    //** so dial, readout and camera agree from the start.
    //**
    //** @param(Sender The form.)
    /// <summary>Sets up the viewport, light and camera, and picks the models folder.</summary>
    /// <remarks><para>The models folder comes from DefaultModelDir in Sprite3DHelpers: it is
    /// the library path on macOS, the home folder on Linux and <c>'../../../'</c> elsewhere; on
    /// Windows it is the current folder instead if that has a models subfolder. The handler
    /// creates a TGorillaViewport owned by ViewportLayout, a point light, and a TSprite3DCamera
    /// with a 45-degree FOV, which becomes the viewport's camera. The viewport runs at a fixed 60 frames per second without VSync.</para>
    /// <para>The dials start at 0, then the isometric view is chosen, as View, Isometric
    /// does: the dials are turned to its angles and switched off, and the readouts set to
    /// match, so dial, readout and camera agree from the start.</para></remarks>
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
    //** @abstract(Renders the view off screen and saves it as the next grabNNN.png.)
    //**
    //** If SaveFolder is empty, a "Save Location" folder dialog asks for it first, and
    //** SaveFolder is set to the choice; if the dialog is cancelled nothing is grabbed. The
    //** image comes from Offscreen at its Width and Height, 256 by 256 unless changed, with the
    //** camera refitted by FitToBounds for that size so the model fills it, and is saved a
    //** frame later as grab001.png, grab002.png and so on: the number starts at 1
    //** when the folder is chosen and goes up by one for every file saved, skipping any name
    //** already in the folder, so earlier grabs are never overwritten. Each saved file is
    //** logged in DebugMemo; a failed grab or save is reported with a message. A click while
    //** the previous grab is still under way is ignored.
    //**
    //** @param(Sender GrabMenuItem.)
    /// <summary>Renders the view off screen and saves it as the next grabNNN.png.</summary>
    /// <remarks>If SaveFolder is empty, a "Save Location" folder dialog asks for it first, and
    /// SaveFolder is set to the choice; if the dialog is cancelled nothing is grabbed. The
    /// image comes from Offscreen at its Width and Height, 256 by 256 unless changed, with the
    /// camera refitted by FitToBounds for that size so the model fills it, and is saved a
    /// frame later as grab001.png, grab002.png and so on: the number starts at 1 when
    /// the folder is chosen and goes up by one for every file saved, skipping any name already
    /// in the folder, so earlier grabs are never overwritten. Each saved file is logged in
    /// DebugMemo; a failed grab or save is reported with a message. A click while the previous
    /// grab is still under way is ignored.</remarks>
    /// <param name="Sender">GrabMenuItem.</param>
    procedure GrabMenuItemClick(Sender: TObject);
    //** @abstract(Closes the application.)
    //**
    //** Closes the main form, which ends the application in the normal way, so the form and
    //** everything it owns are freed as usual.
    //**
    //** @param(Sender ExitMenuItem.)
    /// <summary>Closes the application.</summary>
    /// <remarks>Closes the main form, which ends the application in the normal way, so the form
    /// and everything it owns are freed as usual.</remarks>
    /// <param name="Sender">ExitMenuItem.</param>
    procedure ExitMenuItemClick(Sender: TObject);
    //** @abstract(Hands the camera angles back to the dials.)
    //**
    //** Clears every View check, turns the three dials back on and checks the Variable item.
    //** The camera keeps its current angles until a dial is turned.
    //**
    //** @param(Sender ViewVariableItem.)
    /// <summary>Hands the camera angles back to the dials.</summary>
    /// <remarks>Clears every View check, turns the three dials back on and checks the Variable
    /// item. The camera keeps its current angles until a dial is turned.</remarks>
    /// <param name="Sender">ViewVariableItem.</param>
    procedure ViewVariableItemClick(Sender: TObject);
    //** @abstract(Sets the isometric view and fixes it.)
    //**
    //** Clears every View check, sets the inclination to ArcTan@(1/Sqrt@(2@)@), about 35.264
    //** degrees, the true isometric elevation, the azimuth to 45 and the roll to 0, as shown on
    //** the readouts, turns the dials to match and switches them off, refits the model for the
    //** new view, then checks the Isometric item. As with the dial, the azimuth reaches the
    //** camera reversed. The other fixed views work the same way with their own inclination.
    //**
    //** @param(Sender ViewIsometricItem.)
    /// <summary>Sets the isometric view and fixes it.</summary>
    /// <remarks>Clears every View check, sets the inclination to ArcTan(1/Sqrt(2)), about
    /// 35.264 degrees, the true isometric elevation, the azimuth to 45 and the roll to 0, as
    /// shown on the readouts, turns the dials to match and switches them off, refits the model
    /// for the new view, then checks the Isometric item. As with the dial, the azimuth reaches
    /// the camera reversed. The other fixed views work the same way with their own
    /// inclination.</remarks>
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
    //** @abstract(Sets the pixel-art 2:1 view and fixes it.)
    //**
    //** As View, Isometric, but with the inclination ArcTan@(1/2@), about 26.565 degrees, at
    //** which lines on the floor run 2 pixels across for each pixel up, as in 2:1 pixel art.
    //**
    //** @param(Sender ViewPixel2To1Item.)
    /// <summary>Sets the pixel-art 2:1 view and fixes it.</summary>
    /// <remarks>As View, Isometric, but with the inclination ArcTan(1/2), about 26.565
    /// degrees, at which lines on the floor run 2 pixels across for each pixel up, as in 2:1
    /// pixel art.</remarks>
    /// <param name="Sender">ViewPixel2To1Item.</param>
    procedure ViewPixel2To1ItemClick(Sender: TObject);
    //** @abstract(Sets the 3/4 view, through the orthographic camera, and fixes it.)
    //**
    //** The angle of military projection: inclination 45 degrees at azimuth 45. It also ticks
    //** chkOrthoToggle, switching the camera to orthographic, which gives the flat look of
    //** 3/4-view game art. Other views leave the projection as it is.
    //**
    //** @param(Sender ViewThreeQuarterItem.)
    /// <summary>Sets the 3/4 view, through the orthographic camera, and fixes it.</summary>
    /// <remarks>The angle of military projection: inclination 45 degrees at azimuth 45. It also
    /// ticks chkOrthoToggle, switching the camera to orthographic, which gives the flat look of
    /// 3/4-view game art. Other views leave the projection as it is.</remarks>
    /// <param name="Sender">ViewThreeQuarterItem.</param>
    procedure ViewThreeQuarterItemClick(Sender: TObject);
    //** @abstract(Sets the head-on view and fixes it.)
    //**
    //** Inclination 0 and azimuth 0: level with the model, looking along its Z axis.
    //**
    //** @param(Sender ViewHeadOnItem.)
    /// <summary>Sets the head-on view and fixes it.</summary>
    /// <remarks>Inclination 0 and azimuth 0: level with the model, looking along its Z
    /// axis.</remarks>
    /// <param name="Sender">ViewHeadOnItem.</param>
    procedure ViewHeadOnItemClick(Sender: TObject);
    //** @abstract(Sets the top-down view and fixes it.)
    //**
    //** Inclination 90 and azimuth 0: straight down onto the model.
    //**
    //** @param(Sender ViewTopDownItem.)
    /// <summary>Sets the top-down view and fixes it.</summary>
    /// <remarks>Inclination 90 and azimuth 0: straight down onto the model.</remarks>
    /// <param name="Sender">ViewTopDownItem.</param>
    procedure ViewTopDownItemClick(Sender: TObject);
    //** @abstract(Sets the side view and fixes it.)
    //**
    //** Inclination 0 and azimuth 90: level with the model, from the side, a quarter turn
    //** from View, Head On.
    //**
    //** @param(Sender ViewSideItem.)
    /// <summary>Sets the side view and fixes it.</summary>
    /// <remarks>Inclination 0 and azimuth 90: level with the model, from the side, a quarter
    /// turn from View, Head On.</remarks>
    /// <param name="Sender">ViewSideItem.</param>
    procedure ViewSideItemClick(Sender: TObject);
  private
    { Private declarations }
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
    FOffscreen: TSprite3DOffscreen;
    // Number for the next grab file; back to 1 whenever SaveFolder is chosen
    FGrabNumber: Integer;
    // The on-screen framing, kept while a grab is fitted to its target
    FSavedFraming: TSprite3DFraming;
    ModelDir: String;
    procedure SwitchModel(const AModel: String);
    function FitModel: Boolean;
    procedure ApplyAngles;
    procedure ApplyDistance;
    procedure SetPolarViewAngle(const APolarAngle: Single;
      const AAzimuth: Single = 45);
    procedure ClearViewChecks;
    procedure SelectFixedView(const AItem: TMenuItem; const APolarAngle: Single;
      const AAzimuth: Single = 45);
    function ChooseSaveFolder: Boolean;
    procedure OffscreenBeforeGrab(Sender: TObject; const AWidth, AHeight: Integer);
    procedure OffscreenAfterGrab(Sender: TObject);
    {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  private
    // Mobile only: FMX shows no TMainMenu there, so MainMenu1 is offered
    // through a hamburger button and a drawer instead
    FMenuBar: TToolBar;
    FMenuButton: TSpeedButton;
    FMenuDrawer: TMultiView;
    FMenuList: TListBox;
    procedure BuildMobileMenu;
    procedure RefreshMobileMenu(Sender: TObject);
    procedure MobileMenuItemClick(Sender: TObject);
    {$ENDIF}
  public
    { Public declarations }
    //** @abstract(The folder File, Grab saves into; empty until one is chosen.)
    //**
    //** Empty at start-up, so the first grab shows the "Save Location" dialog and stores the
    //** choice here. Android and iOS have no such dialog: there the first grab sets it to a
    //** Grabs folder in the app's public storage on Android, or its Documents folder on iOS.
    //** Set it in code to save elsewhere without asking; set it back to empty to ask again.
    //** The folder is created if it does not exist when a grab is saved.
    /// <summary>The folder File, Grab saves into; empty until one is chosen.</summary>
    /// <remarks>Empty at start-up, so the first grab shows the "Save Location" dialog and
    /// stores the choice here. Android and iOS have no such dialog: there the first grab sets
    /// it to a Grabs folder in the app's public storage on Android, or its Documents folder on
    /// iOS. Set it in code to save elsewhere without asking; set it back to empty to ask again.
    /// The folder is created if it does not exist when a grab is saved.</remarks>
    SaveFolder: String;
    //** @abstract(The off-screen renderer File, Grab uses; set its Width and Height to
    //** change the grab size.)
    //**
    //** Created in FormCreate, attached to the viewport, which owns and frees it.
    //**
    //** @seealso(TSprite3DOffscreen)
    /// <summary>The off-screen renderer File, Grab uses; set its Width and Height to change
    /// the grab size.</summary>
    /// <remarks>Created in FormCreate, attached to the viewport, which owns and frees
    /// it.</remarks>
    /// <seealso cref="Sprite3DOffscreen.TSprite3DOffscreen"/>
    property Offscreen: TSprite3DOffscreen read FOffscreen;
  end;

var
  //** @abstract(The main form, created by Application.CreateForm in Sprite3d.dpr.)
  /// <summary>The main form, created by Application.CreateForm in Sprite3d.dpr.</summary>
  MainForm: TMainForm;

implementation

uses
  FMX.Platform,
  Gorilla.DefTypes, System.Math,
  FMX.Types3D,
  Sprite3DAxes, Sprite3DGrid, Sprite3DHelpers;

{$R *.fmx}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TabControl1.ActiveTab := GorillaTab;

  ModelDir := DefaultModelDir;

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

  // Off-screen renderer for File, Grab: 256 x 256 by default
  FOffscreen := TSprite3DOffscreen.Create(GorillaViewport);
  FOffscreen.Viewport := GorillaViewport;
  FOffscreen.OnBeforeGrab := OffscreenBeforeGrab;
  FOffscreen.OnAfterGrab := OffscreenAfterGrab;
  SaveFolder := String.Empty;
  FGrabNumber := 1;
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

  // Start in the isometric view for now; View, Variable hands the angles
  // back to the dials
  ViewIsometricItemClick(Self);

  {$IF DEFINED(ANDROID) or DEFINED(IOS)}
  BuildMobileMenu;
  {$ENDIF}
end;

{$IF DEFINED(ANDROID) or DEFINED(IOS)}
// A toolbar along the top with the platform's hamburger button, which opens
// a drawer listing MainMenu1: one group per top-level menu, one row per item.
// Rows are made from the menu items themselves, so items added to MainMenu1
// later appear here too. Separators are left out, and so is Exit on iOS,
// where apps do not quit themselves.
procedure TMainForm.BuildMobileMenu;
var
  I, J: Integer;
  MenuTop, Item: TMenuItem;
  Header: TListBoxGroupHeader;
  Row: TListBoxItem;
begin
  FMenuBar := TToolBar.Create(Self);
  FMenuBar.Parent := Self;
  FMenuBar.Align := TAlignLayout.Top;

  FMenuButton := TSpeedButton.Create(Self);
  FMenuButton.Parent := FMenuBar;
  FMenuButton.Align := TAlignLayout.Left;
  FMenuButton.StyleLookup := 'drawertoolbutton';
  FMenuButton.Width := FMenuBar.Height;

  FMenuDrawer := TMultiView.Create(Self);
  FMenuDrawer.Parent := Self;
  FMenuDrawer.Mode := TMultiViewMode.Drawer;
  FMenuDrawer.MasterButton := FMenuButton;
  FMenuDrawer.Width := 260;
  FMenuDrawer.OnStartShowing := RefreshMobileMenu;

  FMenuList := TListBox.Create(Self);
  FMenuList.Parent := FMenuDrawer;
  FMenuList.Align := TAlignLayout.Client;
  FMenuList.GroupingKind := TListGroupingKind.Grouped;

  for I := 0 to MainMenu1.ItemsCount - 1 do
  begin
    if not (MainMenu1.Items[I] is TMenuItem) then
      Continue;
    MenuTop := TMenuItem(MainMenu1.Items[I]);
    Header := TListBoxGroupHeader.Create(FMenuList);
    Header.Text := MenuTop.Text;
    FMenuList.AddObject(Header);
    for J := 0 to MenuTop.ItemsCount - 1 do
    begin
      Item := MenuTop.Items[J];
      if Item.Text = '-' then
        Continue;
      {$IFDEF IOS}
      if Item = ExitMenuItem then
        Continue;
      {$ENDIF}
      Row := TListBoxItem.Create(FMenuList);
      Row.Text := Item.Text;
      Row.TagObject := Item;
      Row.OnClick := MobileMenuItemClick;
      FMenuList.AddObject(Row);
    end;
  end;
end;

// Each time the drawer opens, copy the menu's checks and enabled states to
// its rows, so the current View shows a tick
procedure TMainForm.RefreshMobileMenu(Sender: TObject);
var
  I: Integer;
  Row: TListBoxItem;
  Item: TMenuItem;
begin
  for I := 0 to FMenuList.Count - 1 do
  begin
    Row := FMenuList.ListItems[I];
    if not (Row.TagObject is TMenuItem) then
      Continue;
    Item := TMenuItem(Row.TagObject);
    Row.Enabled := Item.Enabled;
    if Item.IsChecked then
      Row.ItemData.Accessory := TListBoxItemData.TAccessory.aCheckmark
    else
      Row.ItemData.Accessory := TListBoxItemData.TAccessory.aNone;
  end;
end;

// Close the drawer, then run the menu item's own handler, so a row does
// exactly what its menu item does on the desktop
procedure TMainForm.MobileMenuItemClick(Sender: TObject);
var
  Item: TMenuItem;
begin
  if not (TListBoxItem(Sender).TagObject is TMenuItem) then
    Exit;
  Item := TMenuItem(TListBoxItem(Sender).TagObject);
  FMenuDrawer.HideMaster;
  if Item.Enabled and Assigned(Item.OnClick) then
    Item.OnClick(Item);
end;
{$ENDIF}


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
  SwitchModel(ModelDir + 'models/uvcube.glb');
//  SwitchModel(ModelDir + 'models/TestAnimatedCharacter.glb');
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

procedure TMainForm.GrabMenuItemClick(Sender: TObject);
begin
  if FOffscreen.Busy then
    Exit;   // the last grab has not been saved yet
  if (SaveFolder = String.Empty) and not ChooseSaveFolder then
    Exit;   // no folder, no grab

  if not FOffscreen.Grab(
    procedure(const ABitmap: TBitmap; const AError: String)
    var
      FileName: String;
    begin
      if not Assigned(ABitmap) then
      begin
        ShowMessage('Grab failed: ' + AError);
        Exit;
      end;
      try
        FileName := SaveGrab(ABitmap, SaveFolder, FGrabNumber);
        DebugMemo.Lines.Add('Grabbed ' + FileName);
      except
        on E: Exception do
          ShowMessage('Can''t save the grab in ' + SaveFolder + sLineBreak +
            E.Message);
      end;
    end) then
    ShowMessage('Grab could not start');
end;

// Fit the model to the grab's own shape, as large as it will go for the
// current angles (FitToBounds, whatever "Fit any angle" says, and without
// the test distance factor), keeping the on-screen framing to put back
procedure TMainForm.OffscreenBeforeGrab(Sender: TObject;
  const AWidth, AHeight: Integer);
begin
  FSavedFraming := GorillaCamera.SaveFraming;
  if Assigned(GorillaModel) then
    GorillaCamera.FitToBounds(GorillaModel, AWidth, AHeight);
end;

// Put the on-screen framing back before the main pass draws
procedure TMainForm.OffscreenAfterGrab(Sender: TObject);
begin
  GorillaCamera.RestoreFraming(FSavedFraming);
end;

// Ask for the grab folder with a "Save Location" dialog, or, where there is
// no such dialog (Android, iOS), take the fixed folder. On a choice,
// SaveFolder takes it and numbering restarts at 1; on cancel nothing changes.
function TMainForm.ChooseSaveFolder: Boolean;
var
  Dir: String;
begin
  Dir := DefaultGrabFolder;
  if Dir <> String.Empty then
    Result := True
  else
  begin
    Dir := SaveFolder;
    Result := SelectDirectory('Save Location', String.Empty, Dir) and
      (Dir <> String.Empty);
  end;
  if Result then
  begin
    SaveFolder := Dir;
    FGrabNumber := 1;
  end;
end;


procedure TMainForm.ExitMenuItemClick(Sender: TObject);
begin
  Close;   // closing the main form ends the application
end;

// Remove the check from every item in the View menu, so a new item needs
// no changes here
procedure TMainForm.ClearViewChecks;
var
  I: Integer;
begin
  for I := 0 to ViewMenu.ItemsCount - 1 do
    ViewMenu.Items[I].IsChecked := False;
end;

// The pattern for every fixed view: clear all the checks, set the view,
// then check the item that chose it
procedure TMainForm.SelectFixedView(const AItem: TMenuItem;
  const APolarAngle, AAzimuth: Single);
begin
  ClearViewChecks;
  SetPolarViewAngle(APolarAngle, AAzimuth);
  AItem.IsChecked := True;
end;

procedure TMainForm.ViewVariableItemClick(Sender: TObject);
begin
  ClearViewChecks;
  AzimuthDial.Enabled := True;
  AngleDial.Enabled := True;
  RollDial.Enabled := True;
  ViewVariableItem.IsChecked := True;
end;

procedure TMainForm.ViewIsometricItemClick(Sender: TObject);
begin
  // ArcTan(1 / Sqrt(2)), about 35.264 degrees
  SelectFixedView(ViewIsometricItem, RadToDeg(ArcTan(1 / Sqrt(2))));
end;

procedure TMainForm.ViewPixel2To1ItemClick(Sender: TObject);
begin
  // ArcTan(1 / 2), about 26.565 degrees: floor lines run 2 across per 1 up
  SelectFixedView(ViewPixel2To1Item, RadToDeg(ArcTan(0.5)));
end;

procedure TMainForm.ViewThreeQuarterItemClick(Sender: TObject);
begin
  // Military projection's 45 degrees, through the orthographic camera. The
  // check box's OnChange switches the projection and refits.
  chkOrthoToggle.IsChecked := True;
  SelectFixedView(ViewThreeQuarterItem, 45);
end;

procedure TMainForm.ViewHeadOnItemClick(Sender: TObject);
begin
  // Level with the model, looking straight along its Z axis
  SelectFixedView(ViewHeadOnItem, 0, 0);
end;

procedure TMainForm.ViewTopDownItemClick(Sender: TObject);
begin
  // Straight down onto the model
  SelectFixedView(ViewTopDownItem, 90, 0);
end;

procedure TMainForm.ViewSideItemClick(Sender: TObject);
begin
  // Level with the model, from the side: a quarter turn from Head On
  SelectFixedView(ViewSideItem, 0, 90);
end;

// Sets a fixed view: the given inclination and azimuth (45 unless given)
// with roll 0, all as shown on the readouts, with the dials turned to
// match and switched off, then refits. The View menu checks are the
// caller's job.
procedure TMainForm.SetPolarViewAngle(const APolarAngle, AAzimuth: Single);
const
  FIXED_ROLL = 0;
begin
  // The dial fields hold the readout values; ApplyAngles sends azimuth to
  // the camera reversed, as it does for the dial
  FAzimuth := AAzimuth;
  FPolarAngle := APolarAngle;
  FRoll := FIXED_ROLL;
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
  Anims: TArray<String>;
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

  try
    Anims := LoadModelFile(GorillaModel, AModel, BBox);
    if Length(Anims) > 0 then
      begin
        DebugMemo.Lines.Add('---------- anims ---------------');
        for var AnimName in Anims do
          DebugMemo.Lines.Add(AnimName);
        DebugMemo.Lines.Add('--------------------------------');
      end;

    GorillaCamera.Roll := FRoll;
    GorillaCamera.Azimuth := Wrap360(-FAzimuth);
    GorillaCamera.PolarAngle := FPolarAngle;

    // Draw the box that FitToBounds and FitToBoundsMax fit: the bounds of
    // the current pose, in Gorilla's default orange.
    GorillaModel.ShowBoundingBox := True;
    // Axes through the centre of rotation, sized for the newly loaded model
    if chkShowAxes.IsChecked then
      ShowModelAxes(GorillaModel);
    PlaceModel(GorillaModel, BBox);

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
