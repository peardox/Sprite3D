//** @abstract(Draws a far-reaching grid on a model's floor with a GLSL shader.)
//**
//** ShowModelGrid adds a TModelGrid to a TGorillaModel. It shows a grid of lines across one of
//** the model's axes, Y by default, so the grid lies in X and Z. The lines are GridSize apart in
//** the model's own units, 1.0 by default, in mid-grey, with one through the model's centre of
//** rotation, and the grid reaches GridCells cells each side of it, fading out towards its
//** edge. GridLevel is where it crosses its axis; with GridOnFloor, the default, that is the
//** model's floor, the bounding-box face across the grid's axis that is lower in the scene.
//** That suits a model standing on its lowest bound, as the test animation does, but not
//** every model; set GridLevel to override it.
//**
//** The grid is a single TGorillaPlane. The lines are worked out per pixel by GLSL code in its
//** TGorillaDefaultMaterialSource, through its documented SurfaceShader hook, which Gorilla
//** converts for Vulkan and Metal. So the grid costs two triangles however far it reaches, the
//** lines are anti-aliased and about a pixel wide at any distance, and nothing is recalculated
//** per frame. Changing a grid property rewrites the shader once, with the new values written
//** into it as constants.
//**
//** The plane is not a child of the model, so it never counts in the model's bounding box,
//** and FitToBounds is unaffected. It sits in a frame beside the model that copies the
//** model's position, rotation, scale and centre of rotation whenever they change, so the
//** grid is in the model's units and moves with it.
//**
//** @preformatted(
//** <model's parent>
//** |-- TGorillaModel
//** |   `-- TModelGrid       one per model, found by FindModelGrid;
//** |                        keeps the frame on the model's transform
//** `-- grid frame           TDummy copying the model's transform, owned by the TModelGrid
//**     `-- TGorillaPlane    turned onto GridAxis at GridLevel; grid drawn by its shader
//** )
//**
//** @preformatted(
//** Grid := ShowModelGrid@(GorillaModel1@);   // after the model is loaded and placed
//** if Grid <> nil then
//**   Grid.GridSize := 0.5;
//** HideModelGrid@(GorillaModel1@);
//** )
unit Sprite3DGrid;

{
  Draws a far-reaching grid on a model's floor with a GLSL shader.

  ShowModelGrid adds a TModelGrid to a TGorillaModel. It shows a grid of
  lines across one of the model's axes, Y by default, so the grid lies in X
  and Z. The lines are GridSize apart in the model's own units, 1.0 by
  default, in mid-grey, with one through the model's centre of rotation, and
  the grid reaches GridCells cells each side of it, fading out towards its
  edge. GridLevel is where it crosses its axis; with GridOnFloor, the
  default, that is the model's floor, the bounding-box face across the
  grid's axis that is lower in the scene. That suits a model standing on its
  lowest bound, as the test animation does, but not every model; set
  GridLevel to override it.

  The grid is a single TGorillaPlane. The lines are worked out per pixel by
  GLSL code in its TGorillaDefaultMaterialSource, through its documented
  SurfaceShader hook, which Gorilla converts for Vulkan and Metal. So the
  grid costs two triangles however far it reaches, the lines are
  anti-aliased and about a pixel wide at any distance, and nothing is
  recalculated per frame. Changing a grid property rewrites the shader once,
  with the new values written into it as constants.

  The plane is not a child of the model, so it never counts in the model's
  bounding box, and FitToBounds is unaffected. It sits in a frame beside the
  model that copies the model's position, rotation, scale and centre of
  rotation whenever they change, so the grid is in the model's units and
  moves with it.

    <model's parent>
    |-- TGorillaModel
    |   `-- TModelGrid       one per model, found by FindModelGrid;
    |                        keeps the frame on the model's transform
    `-- grid frame           TDummy copying the model's transform, owned by the TModelGrid
        `-- TGorillaPlane    turned onto GridAxis at GridLevel; grid drawn by its shader

  Usage:
    Grid := ShowModelGrid(GorillaModel1);   // after the model is loaded and placed
    if Grid <> nil then
      Grid.GridSize := 0.5;
    HideModelGrid(GorillaModel1);
}

interface

uses
  System.Classes, System.SysUtils, System.UITypes, System.Math, System.Math.Vectors,
  FMX.Types, FMX.Types3D, FMX.Controls3D, FMX.Objects3D,
  Gorilla.Model, Gorilla.Plane, Gorilla.Material.Default;

type
  //** @abstract(The axis a TModelGrid is drawn across.)
  //**
  //** The grid lies in the plane of the other two axes.
  //**
  //** @value(gaX Across X: the grid lies in Y and Z.)
  //**
  //** @value(gaY Across Y, the default: the grid lies in X and Z.)
  //**
  //** @value(gaZ Across Z: the grid lies in X and Y.)
  /// <summary>The axis a TModelGrid is drawn across.</summary>
  /// <remarks><para>The grid lies in the plane of the other two axes.</para>
  /// <para><c>gaX</c>: across X; the grid lies in Y and Z.</para>
  /// <para><c>gaY</c>: across Y, the default; the grid lies in X and Z.</para>
  /// <para><c>gaZ</c>: across Z; the grid lies in X and Y.</para></remarks>
  TGridAxis = (gaX, gaY, gaZ);

  //** @abstract(Shows a shader-drawn grid for its parent model.)
  //**
  //** A TDummy that draws nothing itself. It owns a frame beside its parent, holding the
  //** TGorillaPlane the grid is drawn on, and in each Render copies the parent's position,
  //** rotation, scale and centre of rotation to the frame if any of them changed. The plane
  //** and its material are built when SetExtent is called and rebuilt only when a grid
  //** property changes. Freeing the TModelGrid frees the frame, plane and material.
  //**
  //** The object is not stored in .fmx files and ignores the mouse. Use it from the main
  //** thread only.
  /// <summary>Shows a shader-drawn grid for its parent model.</summary>
  /// <remarks><para>A TDummy that draws nothing itself. It owns a frame beside its parent,
  /// holding the TGorillaPlane the grid is drawn on, and in each Render copies the parent's
  /// position, rotation, scale and centre of rotation to the frame if any of them changed. The
  /// plane and its material are built when SetExtent is called and rebuilt only when a grid
  /// property changes. Freeing the TModelGrid frees the frame, plane and material.</para>
  /// <para>The object is not stored in .fmx files and ignores the mouse. Use it from the main
  /// thread only.</para></remarks>
  TModelGrid = class(TDummy)
  private
    FBoxLo: TPoint3D;
    FBoxHi: TPoint3D;
    FPivot: TPoint3D;
    FHasExtent: Boolean;
    FFrame: TDummy;
    FGridAxis: TGridAxis;
    FGridSize: Single;
    FGridColor: TAlphaColor;
    FGridLevel: Single;
    FGridOnFloor: Boolean;
    FGridCells: Integer;
    procedure FreeGrid;
    procedure RebuildGrid;
    procedure SyncFrame;
    function FloorLevel: Single;
    function SurfaceCode: string;
    procedure SetGridAxis(const Value: TGridAxis);
    procedure SetGridSize(const Value: Single);
    procedure SetGridColor(const Value: TAlphaColor);
    procedure SetGridLevel(const Value: Single);
    procedure SetGridOnFloor(const Value: Boolean);
    procedure SetGridCells(const Value: Integer);
  protected
    //** @abstract(Keeps the grid frame on the parent's transform.)
    //**
    //** Copies the parent's position, rotation, scale and centre of rotation to the frame if
    //** any of them changed; otherwise does nothing. Draws nothing: the plane draws the grid.
    /// <summary>Keeps the grid frame on the parent's transform.</summary>
    /// <remarks>Copies the parent's position, rotation, scale and centre of rotation to the
    /// frame if any of them changed; otherwise does nothing. Draws nothing: the plane draws the
    /// grid.</remarks>
    procedure Render; override;

    //** @abstract(Forgets the frame if something else frees it first.)
    //**
    //** @param(AComponent The component being freed or removed.)
    //**
    //** @param(Operation What is happening to it.)
    /// <summary>Forgets the frame if something else frees it first.</summary>
    /// <param name="AComponent">The component being freed or removed.</param>
    /// <param name="Operation">What is happening to it.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    //** @abstract(Creates a grid with no extent: across Y, on the floor, lines 1.0 apart.)
    //**
    //** The colour is mid-grey and the grid reaches 100 cells each side. Nothing is built
    //** until SetExtent is called.
    //**
    //** @param(AOwner The owner, or nil to leave freeing to the parent.)
    /// <summary>Creates a grid with no extent: across Y, on the floor, lines 1.0
    /// apart.</summary>
    /// <remarks>The colour is mid-grey and the grid reaches 100 cells each side. Nothing is
    /// built until <see cref="SetExtent"/> is called.</remarks>
    /// <param name="AOwner">The owner, or nil to leave freeing to the parent.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the grid, with its frame, plane and material.)
    //**
    //** If the frame's parent is already being freed, as when the whole scene closes, the
    //** frame is left for it to free.
    /// <summary>Frees the grid, with its frame, plane and material.</summary>
    /// <remarks>If the frame's parent is already being freed, as when the whole scene closes,
    /// the frame is left for it to free.</remarks>
    destructor Destroy; override;

    //** @abstract(Gives the model's bounds and centre of rotation, and builds the grid.)
    //**
    //** All points are in the parent's coordinates. The grid is centred on ACentre in its
    //** plane, and with GridOnFloor its level is picked from the bounds. Set the parent first:
    //** the grid needs it, and is not built without one.
    //**
    //** @param(ALow The bounding box's corner with the smallest X, Y and Z.)
    //**
    //** @param(AHigh The bounding box's corner with the largest X, Y and Z.)
    //**
    //** @param(ACentre The centre of rotation; one line passes through it each way.)
    /// <summary>Gives the model's bounds and centre of rotation, and builds the grid.</summary>
    /// <remarks>All points are in the parent's coordinates. The grid is centred on ACentre in
    /// its plane, and with GridOnFloor its level is picked from the bounds. Set the parent
    /// first: the grid needs it, and is not built without one.</remarks>
    /// <param name="ALow">The bounding box's corner with the smallest X, Y and Z.</param>
    /// <param name="AHigh">The bounding box's corner with the largest X, Y and Z.</param>
    /// <param name="ACentre">The centre of rotation; one line passes through it each
    /// way.</param>
    procedure SetExtent(const ALow, AHigh, ACentre: TPoint3D);

    //** @abstract(Picks the floor again, if GridOnFloor, and rebuilds the grid.)
    //**
    //** The floor depends on how the parent is turned, and is only picked when the grid is
    //** built or a grid property changes. Call this after turning the parent. Moving or
    //** scaling the parent needs no call.
    /// <summary>Picks the floor again, if GridOnFloor, and rebuilds the grid.</summary>
    /// <remarks>The floor depends on how the parent is turned, and is only picked when the grid
    /// is built or a grid property changes. Call this after turning the parent. Moving or
    /// scaling the parent needs no call.</remarks>
    procedure UpdateGrid;

    //** @abstract(The axis the grid is drawn across; gaY by default, so it lies in X and Z.)
    //**
    //** With GridOnFloor the floor is picked again for the new axis.
    /// <summary>The axis the grid is drawn across; gaY by default, so it lies in X and
    /// Z.</summary>
    /// <remarks>With GridOnFloor the floor is picked again for the new axis.</remarks>
    property GridAxis: TGridAxis read FGridAxis write SetGridAxis;
    //** @abstract(Distance between grid lines in the parent's units; 1.0 by default.)
    //**
    //** One line passes through the centre of rotation and the rest are whole multiples of
    //** GridSize from it. The grid scales with the parent. Zero or less hides the grid.
    /// <summary>Distance between grid lines in the parent's units; 1.0 by default.</summary>
    /// <remarks>One line passes through the centre of rotation and the rest are whole multiples
    /// of GridSize from it. The grid scales with the parent. Zero or less hides the
    /// grid.</remarks>
    property GridSize: Single read FGridSize write SetGridSize;
    //** @abstract(Colour of the grid lines; mid-grey, $FF808080, by default.)
    //**
    //** Its alpha scales the lines' opacity.
    /// <summary>Colour of the grid lines; mid-grey, $FF808080, by default.</summary>
    /// <remarks>Its alpha scales the lines' opacity.</remarks>
    property GridColor: TAlphaColor read FGridColor write SetGridColor;
    //** @abstract(Where the grid crosses its axis, in the parent's units; 0 with no other
    //** information.)
    //**
    //** Every point on the grid has this value on GridAxis. While GridOnFloor is True it is
    //** set to the floor whenever the grid is built. Setting it yourself turns GridOnFloor off,
    //** so your value is kept.
    /// <summary>Where the grid crosses its axis, in the parent's units; 0 with no other
    /// information.</summary>
    /// <remarks>Every point on the grid has this value on GridAxis. While GridOnFloor is True it
    /// is set to the floor whenever the grid is built. Setting it yourself turns GridOnFloor
    /// off, so your value is kept.</remarks>
    property GridLevel: Single read FGridLevel write SetGridLevel;
    //** @abstract(Whether GridLevel follows the model's floor; True by default.)
    //**
    //** The floor is the face of the bounding box, across GridAxis, that is lower in the
    //** scene once the parent's transform is applied; FMX's Y points down, so that is the one
    //** with the larger scene Y. If neither is lower, because GridAxis is level in the scene,
    //** the face with the smaller value is used. This assumes the model stands on its lowest
    //** bound, which is true of the test animation but not of every model.
    /// <summary>Whether GridLevel follows the model's floor; True by default.</summary>
    /// <remarks>The floor is the face of the bounding box, across GridAxis, that is lower in
    /// the scene once the parent's transform is applied; FMX's Y points down, so that is the
    /// one with the larger scene Y. If neither is lower, because GridAxis is level in the
    /// scene, the face with the smaller value is used. This assumes the model stands on its
    /// lowest bound, which is true of the test animation but not of every model.</remarks>
    property GridOnFloor: Boolean read FGridOnFloor write SetGridOnFloor;
    //** @abstract(How many grid cells reach out each side of the centre; 100 by default.)
    //**
    //** The plane is 2 * GridCells * GridSize across, so 200 units square by default. The
    //** lines fade out over the outer half. The cost does not depend on this value. Values
    //** below 1 count as 1.
    /// <summary>How many grid cells reach out each side of the centre; 100 by
    /// default.</summary>
    /// <remarks>The plane is 2 * GridCells * GridSize across, so 200 units square by default.
    /// The lines fade out over the outer half. The cost does not depend on this value. Values
    /// below 1 count as 1.</remarks>
    property GridCells: Integer read FGridCells write SetGridCells;
  end;

//** @abstract(Shows a shader-drawn grid on AModel's floor.)
//**
//** Any grid already on AModel is removed first, so calling it again, for example after
//** loading a different model, rebuilds it for the new bounds. The grid uses AModel's current
//** bounding box, from @code(GetAnimatedBoundingBox), and @code(AModel.RotationCenter). Call
//** it once the model is placed and turned, since the floor depends on the turn. The grid is
//** added as a child of AModel and is freed with it. Call from the main thread only.
//**
//** @param(AModel The model to show a grid for. Nothing happens if it is nil.)
//**
//** @returns(The new grid, owned by AModel; or nil, with nothing added, if AModel is nil or
//** its bounding box is empty.)
//**
//** @seealso(HideModelGrid)
//**
//** @seealso(FindModelGrid)
/// <summary>Shows a shader-drawn grid on AModel's floor.</summary>
/// <remarks>Any grid already on AModel is removed first, so calling it again, for example
/// after loading a different model, rebuilds it for the new bounds. The grid uses AModel's
/// current bounding box, from <c>GetAnimatedBoundingBox</c>, and
/// <c>AModel.RotationCenter</c>. Call it once the model is placed and turned, since the floor
/// depends on the turn. The grid is added as a child of AModel and is freed with it. Call from
/// the main thread only.</remarks>
/// <param name="AModel">The model to show a grid for. Nothing happens if it is nil.</param>
/// <returns>The new grid, owned by AModel; or nil, with nothing added, if AModel is nil or its
/// bounding box is empty.</returns>
/// <seealso cref="HideModelGrid"/>
/// <seealso cref="FindModelGrid"/>
function ShowModelGrid(const AModel: TGorillaModel): TModelGrid;

//** @abstract(Removes the grid ShowModelGrid added to AModel.)
//**
//** Does nothing if AModel is nil or has no grid. Call from the main thread only.
//**
//** @param(AModel The model to remove the grid from.)
//**
//** @seealso(ShowModelGrid)
/// <summary>Removes the grid ShowModelGrid added to AModel.</summary>
/// <remarks>Does nothing if AModel is nil or has no grid. Call from the main thread
/// only.</remarks>
/// <param name="AModel">The model to remove the grid from.</param>
/// <seealso cref="ShowModelGrid"/>
procedure HideModelGrid(const AModel: TGorillaModel);

//** @abstract(Returns the grid ShowModelGrid added to AModel, or nil.)
//**
//** Looks only at AModel's direct children. The caller does not own the result.
//**
//** @param(AModel The model to look on; nil gives nil.)
//**
//** @returns(The grid, or nil if AModel is nil or has none.)
/// <summary>Returns the grid ShowModelGrid added to AModel, or nil.</summary>
/// <remarks>Looks only at AModel's direct children. The caller does not own the
/// result.</remarks>
/// <param name="AModel">The model to look on; nil gives nil.</param>
/// <returns>The grid, or nil if AModel is nil or has none.</returns>
function FindModelGrid(const AModel: TGorillaModel): TModelGrid;

implementation

const
  // Fraction of the grid's radius over which the lines fade out
  FADE_START = 0.5;

{ Component AIndex of AP: 0 = X, 1 = Y, 2 = Z }
function GetComp(const AP: TPoint3D; const AIndex: Integer): Single;
begin
  case AIndex of
    0: Result := AP.X;
    1: Result := AP.Y;
  else
    Result := AP.Z;
  end;
end;

procedure SetComp(var AP: TPoint3D; const AIndex: Integer; const AValue: Single);
begin
  case AIndex of
    0: AP.X := AValue;
    1: AP.Y := AValue;
  else
    AP.Z := AValue;
  end;
end;

{ Copy ASource to ATarget only if it differs, so an unchanged transform
  never triggers a repaint }
procedure CopyIfChanged(const ATarget: TPosition3D; const ASource: TPoint3D);
var
  P: TPoint3D;
begin
  P := ATarget.Point;
  if (P.X <> ASource.X) or (P.Y <> ASource.Y) or (P.Z <> ASource.Z) then
    ATarget.Point := ASource;
end;

{ A GLSL float literal: always with a decimal point, whatever the locale,
  since GLSL does not mix ints and floats freely }
function GlslFloat(const AValue: Single): string;
begin
  Result := FormatFloat('0.0#####', AValue, TFormatSettings.Invariant);
end;

{ TModelGrid }

constructor TModelGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  FGridAxis := gaY;
  FGridSize := 1.0;
  FGridColor := TAlphaColorRec.Grey;   // $FF808080, mid-grey
  FGridLevel := 0;
  FGridOnFloor := True;
  FGridCells := 100;
end;

destructor TModelGrid.Destroy;
begin
  FreeGrid;
  inherited;
end;

procedure TModelGrid.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FFrame) then
    FFrame := nil;   // the plane and material went with it
end;

procedure TModelGrid.SetExtent(const ALow, AHigh, ACentre: TPoint3D);
begin
  FBoxLo := Point3D(Min(ALow.X, ACentre.X), Min(ALow.Y, ACentre.Y),
    Min(ALow.Z, ACentre.Z));
  FBoxHi := Point3D(Max(AHigh.X, ACentre.X), Max(AHigh.Y, ACentre.Y),
    Max(AHigh.Z, ACentre.Z));
  FPivot := ACentre;
  FHasExtent := True;

  // Sit over the model's box, sized to it, so a size-based cull never
  // skips this object's Render, which keeps the frame in step
  Position.Point := (FBoxLo + FBoxHi) * 0.5;
  Width := Max(FBoxHi.X - FBoxLo.X, 0.001);
  Height := Max(FBoxHi.Y - FBoxLo.Y, 0.001);
  Depth := Max(FBoxHi.Z - FBoxLo.Z, 0.001);

  UpdateGrid;
end;

function TModelGrid.FloorLevel: Single;
const
  LEVEL_EPS = 1E-4;
var
  Model: TControl3D;
  Axis: Integer;
  Lo, Hi, YLo, YHi: Single;
  P: TPoint3D;
begin
  Result := 0;
  if not FHasExtent or not (Parent is TControl3D) then
    Exit;   // no other information: the plane through 0
  Model := TControl3D(Parent);
  Axis := Ord(FGridAxis);
  Lo := GetComp(FBoxLo, Axis);
  Hi := GetComp(FBoxHi, Axis);

  // Carry both faces into the scene and take the one lower on screen;
  // FMX's Y points down, so lower means a larger Y
  P := FPivot;
  SetComp(P, Axis, Lo);
  YLo := Model.LocalToAbsolute3D(P).Y;
  SetComp(P, Axis, Hi);
  YHi := Model.LocalToAbsolute3D(P).Y;

  if Abs(YHi - YLo) <= LEVEL_EPS * Max(1, Abs(Hi - Lo)) then
    Result := Lo   // the axis is level in the scene: no face is lower
  else if YHi > YLo then
    Result := Hi
  else
    Result := Lo;
end;

procedure TModelGrid.SyncFrame;
var
  Model: TControl3D;
begin
  if (FFrame = nil) or not (Parent is TControl3D) then
    Exit;
  Model := TControl3D(Parent);
  // Same parent and the same transform properties give the same matrix,
  // so the frame's space is exactly the model's
  if FFrame.Parent <> Model.Parent then
    FFrame.Parent := Model.Parent;
  CopyIfChanged(FFrame.Position, Model.Position.Point);
  CopyIfChanged(FFrame.RotationAngle, Model.RotationAngle.Point);
  CopyIfChanged(FFrame.Scale, Model.Scale.Point);
  CopyIfChanged(FFrame.RotationCenter, Model.RotationCenter.Point);
end;

procedure TModelGrid.FreeGrid;
var
  Frame: TDummy;
begin
  Frame := FFrame;
  FFrame := nil;
  if Frame = nil then
    Exit;
  Frame.RemoveFreeNotification(Self);
  // When the frame's parent is already being freed (the scene is closing)
  // it frees the frame itself; freeing it here too would do it twice
  if (Frame.Parent <> nil) and (csDestroying in Frame.Parent.ComponentState) then
    Exit;
  Frame.Parent := nil;
  Frame.Free;   // frees the plane, its child, then the material it owns
end;

function TModelGrid.SurfaceCode: string;
var
  C: TAlphaColorRec;
  Half: Single;
begin
  C := TAlphaColorRec(FGridColor);
  Half := FGridCells * FGridSize;
  // The plane's own position, from the documented varying v_VertPos (the
  // original vertex position). TGorillaPlane lies in its local X-Y plane,
  // like FMX's TPlane, so X and Y are the grid's two coordinates, exact in
  // model units whatever the plane's UV layout. No texture coordinates are
  // used: TLocals only declares them when the mesh has them and a texture
  // is in use.
  // Distance to the nearest line in each direction, in pixels, via fwidth;
  // within about a pixel of a line it is drawn, smoothly at the edges.
  // Beyond FADE_START of the radius the lines fade to nothing.
  Result :=
    'void SurfaceShader(inout TLocals DATA){' + sLineBreak +
    '  vec2 p = vars.v_VertPos.xy;' + sLineBreak +
    '  vec2 g = p / ' + GlslFloat(FGridSize) + ';' + sLineBreak +
    '  vec2 w = max(fwidth(g), vec2(0.000001));' + sLineBreak +
    '  vec2 d = abs(fract(g - 0.5) - 0.5) / w;' + sLineBreak +
    '  float line = 1.0 - min(min(d.x, d.y), 1.0);' + sLineBreak +
    '  float fade = 1.0 - smoothstep(' + GlslFloat(Half * FADE_START) + ', ' +
      GlslFloat(Half) + ', length(p));' + sLineBreak +
    '  float a = line * fade * ' + GlslFloat(C.A / 255) + ';' + sLineBreak +
    '  if (a < 0.02) discard;' + sLineBreak +
    '  DATA.BaseColor = vec4(' + GlslFloat(C.R / 255) + ', ' + GlslFloat(C.G / 255) +
      ', ' + GlslFloat(C.B / 255) + ', a);' + sLineBreak +
    '  DATA.Alpha = a;' + sLineBreak +
    '}';
end;

procedure TModelGrid.RebuildGrid;
var
  Model: TControl3D;
  Plane: TGorillaPlane;
  Mat: TGorillaDefaultMaterialSource;
  Code: TStringList;
  P: TPoint3D;
  Half: Single;
begin
  FreeGrid;
  if (FGridSize <= 0) or not FHasExtent or not (Parent is TControl3D)
    or (Parent.Parent = nil) then
    Exit;
  Model := TControl3D(Parent);

  // A frame beside the model, on the model's transform, so the grid is in
  // model units without being part of the model's bounds
  FFrame := TDummy.Create(nil);
  FFrame.Stored := False;
  FFrame.Locked := True;
  FFrame.HitTest := False;
  FFrame.FreeNotification(Self);
  FFrame.Parent := Model.Parent;
  SyncFrame;

  // The plane, parented before anything else, as in Gorilla's examples
  Plane := TGorillaPlane.Create(nil);
  Plane.Stored := False;
  Plane.Locked := True;
  Plane.HitTest := False;
  Plane.Parent := FFrame;   // freed with the frame

  // TGorillaPlane lies in its local X-Y plane, like FMX's TPlane, sized by
  // Width and Height; turn it onto GridAxis
  Half := FGridCells * FGridSize;
  Plane.Width := 2 * Half;
  Plane.Height := 2 * Half;
  case FGridAxis of
    gaX: Plane.RotationAngle.Point := Point3D(0, 90, 0);   // X-Y into Y-Z
    gaY: Plane.RotationAngle.Point := Point3D(90, 0, 0);   // X-Y into X-Z
  else
    Plane.RotationAngle.Point := TPoint3D.Zero;            // X-Y as built
  end;
  // Centred on the pivot in its plane, at GridLevel across its axis
  P := FPivot;
  SetComp(P, Ord(FGridAxis), FGridLevel);
  Plane.Position.Point := P;

  // Owned by the frame, so freed with it, after the plane that uses it
  Mat := TGorillaDefaultMaterialSource.Create(FFrame);
  Mat.UseLighting := False;
  Mat.UseSpecular := False;
  // The grid colour as the material's own colour too, so even if the
  // shader's BaseColor is not what reaches the screen the lines are this
  Mat.Diffuse := FGridColor;
  // The shader property takes a TStrings instance; setting .Text at runtime
  // would not trigger Gorilla's shader update
  Code := TStringList.Create;
  try
    Code.Text := SurfaceCode;
    Mat.SurfaceShader := Code;
  finally
    Code.Free;
  end;
  Plane.MaterialSource := Mat;
end;

procedure TModelGrid.UpdateGrid;
begin
  if FGridOnFloor then
    FGridLevel := FloorLevel;
  RebuildGrid;
end;

procedure TModelGrid.Render;
begin
  inherited;
  SyncFrame;   // a no-op unless the model moved, turned or was scaled
end;

procedure TModelGrid.SetGridAxis(const Value: TGridAxis);
begin
  FGridAxis := Value;
  UpdateGrid;
end;

procedure TModelGrid.SetGridSize(const Value: Single);
begin
  FGridSize := Value;
  RebuildGrid;
end;

procedure TModelGrid.SetGridColor(const Value: TAlphaColor);
begin
  FGridColor := Value;
  RebuildGrid;
end;

procedure TModelGrid.SetGridLevel(const Value: Single);
begin
  FGridLevel := Value;
  FGridOnFloor := False;   // an explicit level always wins
  RebuildGrid;
end;

procedure TModelGrid.SetGridOnFloor(const Value: Boolean);
begin
  FGridOnFloor := Value;
  UpdateGrid;
end;

procedure TModelGrid.SetGridCells(const Value: Integer);
begin
  FGridCells := Max(Value, 1);
  RebuildGrid;
end;

{ Routines }

function FindModelGrid(const AModel: TGorillaModel): TModelGrid;
var
  I: Integer;
begin
  Result := nil;
  if AModel = nil then
    Exit;
  for I := 0 to AModel.ChildrenCount - 1 do
    if AModel.Children[I] is TModelGrid then
      Exit(TModelGrid(AModel.Children[I]));
end;

procedure HideModelGrid(const AModel: TGorillaModel);
var
  Grid: TModelGrid;
begin
  Grid := FindModelGrid(AModel);
  if Grid <> nil then
  begin
    Grid.Parent := nil;
    Grid.Free;   // frees the frame, plane and material
  end;
end;

function ShowModelGrid(const AModel: TGorillaModel): TModelGrid;
var
  Box: TBoundingBox;
begin
  Result := nil;
  if AModel = nil then
    Exit;

  HideModelGrid(AModel);

  // Current pose, in the model's own coordinates. Empty (min > max) if
  // there are no vertices.
  Box := AModel.GetAnimatedBoundingBox();
  if (Box.Left > Box.Right) or (Box.Top > Box.Bottom) or (Box.Near > Box.Far) then
    Exit;

  Result := TModelGrid.Create(nil);
  // Parent first: the floor and the grid need the model and its parent
  Result.Parent := AModel;   // freed with the model
  Result.SetExtent(Box.TopLeftNear, Box.BottomRightFar,
    AModel.RotationCenter.Point);
end;

end.
