//** @abstract(A background for a Gorilla3D view: a checker for transparency, a colour or a
//** gradient.)
//**
//** TSprite3DBackgroundSpec describes a background: its kind, its colours and the size of
//** the checker squares. TSprite3DBackground draws one behind everything a TSprite3DCamera
//** sees. It is an unlit plane that moves with the camera, just inside the far plane, and is
//** resized every frame to fill the view exactly, whatever the projection, field of view or
//** window size. Its colour comes from a short GLSL SurfaceShader: one colour for Solid, a
//** blend down the plane for Gradient. It hangs from the camera's RollPivot, the dummy the
//** camera itself hangs from; every plane is a pair facing opposite ways, so one always
//** faces the camera however Gorilla culls back faces.
//**
//** The Transparent kind draws a checker of two greys, the usual sign that an image is
//** transparent there. It is built from geometry rather than a shader, as Gorilla would not
//** draw any per-pixel checker shader: the plane is filled with the light grey, and a pool of
//** small planes, all sharing one material of the dark grey, is laid over it as the dark
//** squares, a little nearer the camera. The squares are CheckerSize logical pixels on
//** screen, counted from the view's top-left corner, which is light. To keep the number of
//** planes reasonable, a checker that would need more than MaxCheckerSquares dark squares
//** has its squares enlarged by a whole multiple until it fits.
//**
//** The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs the same
//** background: transparent for Transparent, as the checker stands for, and the colour or
//** gradient otherwise. Hide the background while a grab is drawn, with Hidden, so it does
//** not end up in the grab.
//**
//** @preformatted(
//** TSprite3DCamera.RollPivot @(TDummy@)
//** |-- TSprite3DCamera                 at @(0, 0, -Distance@), looking along +Z
//** `-- TSprite3DBackground @(TDummy@)   fitted to the view every frame
//**     |-- TGorillaPlane @(x2@)          the whole view; colour, gradient or light grey
//**     `-- TGorillaPlane @(x2 each@)     the dark checker squares, while Transparent
//** )
unit Sprite3DBackground;

{
  A background for a Gorilla3D view: a checker for transparency, a colour or
  a gradient.

  TSprite3DBackgroundSpec describes a background: its kind, its colours and
  the size of the checker squares. TSprite3DBackground draws one behind
  everything a TSprite3DCamera sees. It is an unlit plane that moves with
  the camera, just inside the far plane, and is resized every frame to fill
  the view exactly, whatever the projection, field of view or window size.
  Its colour comes from a short GLSL SurfaceShader: one colour for Solid, a
  blend down the plane for Gradient. It hangs from the camera's RollPivot,
  the dummy the camera itself hangs from; every plane is a pair facing
  opposite ways, so one always faces the camera however Gorilla culls back
  faces.

  The Transparent kind draws a checker of two greys, the usual sign that an
  image is transparent there. It is built from geometry rather than a
  shader, as Gorilla would not draw any per-pixel checker shader: the plane
  is filled with the light grey, and a pool of small planes, all sharing one
  material of the dark grey, is laid over it as the dark squares, a little
  nearer the camera. The squares are CheckerSize logical pixels on screen,
  counted from the view's top-left corner, which is light. To keep the
  number of planes reasonable, a checker that would need more than
  MaxCheckerSquares dark squares has its squares enlarged by a whole
  multiple until it fits.

  The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs
  the same background: transparent for Transparent, as the checker stands
  for, and the colour or gradient otherwise. Hide the background while a
  grab is drawn, with Hidden, so it does not end up in the grab.

    TSprite3DCamera.RollPivot (TDummy)
    |-- TSprite3DCamera                 at (0, 0, -Distance), looking along +Z
    `-- TSprite3DBackground (TDummy)   fitted to the view every frame
        |-- TGorillaPlane (x2)          the whole view; colour, gradient or light grey
        `-- TGorillaPlane (x2 each)     the dark checker squares, while Transparent
}

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Math.Vectors,
  FMX.Types3D, FMX.Controls3D, FMX.Objects3D,
  Gorilla.Plane, Gorilla.Material.Default,
  Sprite3DCamera;

type
  {$SCOPEDENUMS ON}
  //** @abstract(What a background shows.)
  /// <summary>What a background shows.</summary>
  TSprite3DBackgroundKind = (
    //** @abstract(Nothing: a checker on screen, transparency in grabs.)
    /// <summary>Nothing: a checker on screen, transparency in grabs.</summary>
    Transparent,
    //** @abstract(One colour, Colour.)
    /// <summary>One colour, Colour.</summary>
    Solid,
    //** @abstract(A vertical blend from GradientFrom at the top to GradientTo at the bottom.)
    /// <summary>A vertical blend from GradientFrom at the top to GradientTo at the
    /// bottom.</summary>
    Gradient);
  {$SCOPEDENUMS OFF}

  //** @abstract(Describes a background: its kind, colours and checker size.)
  //**
  //** A plain record, copied by value. Default gives the application's starting background:
  //** a checker of 64-pixel squares in two greys. Colours are used opaque; their alpha is
  //** ignored.
  /// <summary>Describes a background: its kind, colours and checker size.</summary>
  /// <remarks>A plain record, copied by value. Default gives the application's starting
  /// background: a checker of 64-pixel squares in two greys. Colours are used opaque; their
  /// alpha is ignored.</remarks>
  TSprite3DBackgroundSpec = record
    //** @abstract(What the background shows.)
    /// <summary>What the background shows.</summary>
    Kind: TSprite3DBackgroundKind;
    //** @abstract(The colour of a Solid background.)
    /// <summary>The colour of a Solid background.</summary>
    Colour: TAlphaColor;
    //** @abstract(The colour at the top of a Gradient background.)
    /// <summary>The colour at the top of a Gradient background.</summary>
    GradientFrom: TAlphaColor;
    //** @abstract(The colour at the bottom of a Gradient background.)
    /// <summary>The colour at the bottom of a Gradient background.</summary>
    GradientTo: TAlphaColor;
    //** @abstract(The side of each checker square, in pixels on screen; at least 1.)
    /// <summary>The side of each checker square, in pixels on screen; at least 1.</summary>
    CheckerSize: Integer;
    //** @abstract(The lighter checker colour.)
    /// <summary>The lighter checker colour.</summary>
    CheckerLight: TAlphaColor;
    //** @abstract(The darker checker colour.)
    /// <summary>The darker checker colour.</summary>
    CheckerDark: TAlphaColor;
    //** @abstract(The starting background: a checker of 64-pixel squares, light and mid
    //** grey.)
    //**
    //** Colour is mid grey and the gradient runs from light grey to dark grey, ready for
    //** when another kind is chosen.
    //**
    //** @returns(The default spec.)
    /// <summary>The starting background: a checker of 64-pixel squares, light and mid
    /// grey.</summary>
    /// <remarks>Colour is mid grey and the gradient runs from light grey to dark grey, ready
    /// for when another kind is chosen.</remarks>
    /// <returns>The default spec.</returns>
    class function Default: TSprite3DBackgroundSpec; static;
    //** @abstract(The gradient's colour a fraction of the way down.)
    //**
    //** @param(AFraction 0 for the top, GradientFrom, to 1 for the bottom, GradientTo;
    //** values outside are clamped.)
    //**
    //** @returns(The blended colour, opaque.)
    /// <summary>The gradient's colour a fraction of the way down.</summary>
    /// <param name="AFraction">0 for the top, GradientFrom, to 1 for the bottom, GradientTo;
    /// values outside are clamped.</param>
    /// <returns>The blended colour, opaque.</returns>
    function GradientAt(const AFraction: Single): TAlphaColor;
  end;

  //** @abstract(Draws a background behind everything a TSprite3DCamera sees.)
  //**
  //** Create it and call AttachTo with the camera; it then hangs from the camera's RollPivot
  //** and is freed with the camera's rig. Each frame it fits its planes to the view at a
  //** depth just inside the far plane, so the scene is always in front of it. Set Spec to
  //** change what it shows. While the camera is orthographic the background is kept out of
  //** view for now, as it draws black over the scene there. For the main thread only.
  /// <summary>Draws a background behind everything a TSprite3DCamera sees.</summary>
  /// <remarks>Create it and call AttachTo with the camera; it then hangs from the camera's
  /// RollPivot and is freed with the camera's rig. Each frame it fits its planes to the view
  /// at a depth just inside the far plane, so the scene is always in front of it. Set Spec to
  /// change what it shows. While the camera is orthographic the background is kept out of
  /// view for now, as it draws black over the scene there. For the main thread
  /// only.</remarks>
  TSprite3DBackground = class(TDummy)
  private
    FCamera: TSprite3DCamera;
    FPlanes: array[0..1] of TGorillaPlane;   // the whole view, a facing pair
    FMaterial: TGorillaDefaultMaterialSource;
    FSquares: TArray<TGorillaPlane>;          // dark squares, in facing pairs
    FSquareMaterial: TGorillaDefaultMaterialSource;
    FSquaresWanted: Integer;   // planes the pool is being grown to
    FSpec: TSprite3DBackgroundSpec;
    FGrowQueued: Boolean;      // a pool growth is waiting to run after the frame
    FAlive: IInterface;        // shared with the queued growth; see Destroy
    FHidden: Boolean;
    procedure BuildPlanes;
    function NewPlane(const AIndex: Integer;
      const AMaterial: TGorillaDefaultMaterialSource): TGorillaPlane;
    procedure GrowSquares;
    procedure QueueGrowSquares(const ACount: Integer);
    procedure UpdateMaterials;
    procedure Fit;
    procedure FitSquares(const AZ: Single; const AShow: Boolean);
    function SurfaceCode: String;
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
    procedure SetHidden(const Value: Boolean);
  protected
    //** @abstract(Fits the planes to the view before each frame is drawn.)
    /// <summary>Fits the planes to the view before each frame is drawn.</summary>
    procedure Render; override;
  public
    //** @abstract(The most dark checker squares drawn in the view.)
    //**
    //** A checker that would need more has its squares enlarged by a whole multiple until it
    //** fits. Each square is a pair of planes.
    /// <summary>The most dark checker squares drawn in the view.</summary>
    /// <remarks>A checker that would need more has its squares enlarged by a whole multiple
    /// until it fits. Each square is a pair of planes.</remarks>
    const MaxCheckerSquares = 400;
    //** @abstract(Creates the background with the default spec, not yet attached.)
    //**
    //** @param(AOwner The owner; nil is usual, as the camera's rig frees it once attached.)
    /// <summary>Creates the background with the default spec, not yet attached.</summary>
    /// <param name="AOwner">The owner; nil is usual, as the camera's rig frees it once
    /// attached.</param>
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Frees the background; a growth of the checker still queued is dropped.)
    /// <summary>Frees the background; a growth of the checker still queued is
    /// dropped.</summary>
    destructor Destroy; override;
    //** @abstract(Puts the background behind everything ACamera sees.)
    //**
    //** Makes it a child of ACamera's RollPivot, beside the camera, so it moves and turns with
    //** the camera and is freed with its rig.
    //**
    //** @param(ACamera The camera to follow.)
    /// <summary>Puts the background behind everything ACamera sees.</summary>
    /// <remarks>Makes it a child of ACamera's RollPivot, beside the camera, so it moves and
    /// turns with the camera and is freed with its rig.</remarks>
    /// <param name="ACamera">The camera to follow.</param>
    procedure AttachTo(const ACamera: TSprite3DCamera);
    //** @abstract(What the background shows; setting it redraws it.)
    /// <summary>What the background shows; setting it redraws it.</summary>
    property Spec: TSprite3DBackgroundSpec read FSpec write SetSpec;
    //** @abstract(True moves the background out of view, as while a grab is drawn.)
    //**
    //** Its planes are moved beyond the far plane rather than made invisible, so it takes
    //** effect for the next drawing even within a frame. False brings it back.
    /// <summary>True moves the background out of view, as while a grab is drawn.</summary>
    /// <remarks>Its planes are moved beyond the far plane rather than made invisible, so it
    /// takes effect for the next drawing even within a frame. False brings it back.</remarks>
    property Hidden: Boolean read FHidden write SetHidden;
  end;

implementation

uses
  System.Types, System.Math, FMX.Viewport3D;

// Shared between the background and its queued pool growth, so a growth
// that runs after the background has been freed can tell, and do nothing
type
  IBackgroundAlive = interface
    ['{3B1E7C40-2F6D-4E8A-9C51-7A0D4B6E2F13}']
    function IsAlive: Boolean;
    procedure Kill;
  end;

  TBackgroundAlive = class(TInterfacedObject, IBackgroundAlive)
  private
    FAlive: Boolean;
  public
    constructor Create;
    function IsAlive: Boolean;
    procedure Kill;
  end;

constructor TBackgroundAlive.Create;
begin
  inherited Create;
  FAlive := True;
end;

function TBackgroundAlive.IsAlive: Boolean;
begin
  Result := FAlive;
end;

procedure TBackgroundAlive.Kill;
begin
  FAlive := False;
end;

const
  // The background sits this far along the far plane's distance, so
  // everything the camera can show is in front of it
  DEPTH_FRACTION = 0.95;
  // The checker's squares sit this far along it: clearly nearer than the
  // background, so the depth buffer never mixes them up, and still behind
  // anything the scene is likely to hold
  SQUARE_DEPTH_FRACTION = 0.94;
  // Where the planes go while Hidden: well beyond the far plane
  HIDDEN_DEPTH_FACTOR = 10.0;
  // A little larger than the view, so no edge shows through rounding
  OVERSCAN = 1.02;

// A GLSL float literal: always with a decimal point, whatever the locale
function GlslFloat(const AValue: Single): String;
begin
  Result := FormatFloat('0.0#####', AValue, TFormatSettings.Invariant);
end;

// A colour as a GLSL vec3, ignoring alpha
function GlslColour(const AColour: TAlphaColor): String;
var
  C: TAlphaColorRec;
begin
  C := TAlphaColorRec(AColour);
  Result := 'vec3(' + GlslFloat(C.R / 255) + ', ' + GlslFloat(C.G / 255) + ', ' +
    GlslFloat(C.B / 255) + ')';
end;

// The SurfaceShader for one colour, the form Gorilla draws reliably
function SolidCode(const AColour: TAlphaColor): String;
begin
  Result :=
    'void SurfaceShader(inout TLocals DATA){' + sLineBreak +
    '  vec3 col = ' + GlslColour(AColour) + ';' + sLineBreak +
    '  DATA.BaseColor = vec4(col, 1.0);' + sLineBreak +
    '  DATA.Alpha = 1.0;' + sLineBreak +
    '}';
end;

// Hands ACode to AMaterial. The shader property takes a TStrings instance;
// setting .Text at runtime would not trigger Gorilla's shader update.
procedure SetShader(const AMaterial: TGorillaDefaultMaterialSource; const ACode: String);
var
  Code: TStringList;
begin
  Code := TStringList.Create;
  try
    Code.Text := ACode;
    AMaterial.SurfaceShader := Code;
  finally
    Code.Free;
  end;
end;

{ TSprite3DBackgroundSpec }

class function TSprite3DBackgroundSpec.Default: TSprite3DBackgroundSpec;
begin
  Result.Kind := TSprite3DBackgroundKind.Transparent;
  Result.Colour := $FF808080;
  Result.GradientFrom := $FFD0D0D0;
  Result.GradientTo := $FF404040;
  Result.CheckerSize := 64;
  Result.CheckerLight := $FFCCCCCC;
  Result.CheckerDark := $FF999999;
end;

function TSprite3DBackgroundSpec.GradientAt(const AFraction: Single): TAlphaColor;
var
  T: Single;
  F, G: TAlphaColorRec;
  R: TAlphaColorRec;
begin
  T := EnsureRange(AFraction, 0.0, 1.0);
  F := TAlphaColorRec(GradientFrom);
  G := TAlphaColorRec(GradientTo);
  R.R := Round(F.R + (G.R - F.R) * T);
  R.G := Round(F.G + (G.G - F.G) * T);
  R.B := Round(F.B + (G.B - F.B) * T);
  R.A := 255;
  Result := R.Color;
end;

{ TSprite3DBackground }

constructor TSprite3DBackground.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  FSpec := TSprite3DBackgroundSpec.Default;
  FAlive := TBackgroundAlive.Create;
end;

destructor TSprite3DBackground.Destroy;
begin
  (FAlive as IBackgroundAlive).Kill;
  inherited;
end;

procedure TSprite3DBackground.AttachTo(const ACamera: TSprite3DCamera);
begin
  FCamera := ACamera;
  // Beside the camera, which sits in RollPivot at (0, 0, -Distance) with no
  // turn of its own, so this frame shares the camera's orientation
  Parent := ACamera.RollPivot;
  Position.Point := TPoint3D.Zero;
  RotationAngle.Point := TPoint3D.Zero;
  if FPlanes[0] = nil then
    BuildPlanes;
  Fit;
end;

// A plane parented before anything else, as in Gorilla's examples. A plane
// lies in its local X-Y plane, square to the camera, which looks along +Z;
// FMX's +Y points down the screen. An odd AIndex turns it half a turn about
// Y, so of each pair, whichever side Gorilla treats as the front, one of
// them shows it to the camera; the turn keeps Y and the plane's centre, so
// both draw exactly the same pixels.
function TSprite3DBackground.NewPlane(const AIndex: Integer;
  const AMaterial: TGorillaDefaultMaterialSource): TGorillaPlane;
begin
  Result := TGorillaPlane.Create(nil);
  Result.Stored := False;
  Result.Locked := True;
  Result.HitTest := False;
  Result.Parent := Self;   // freed with this object
  if Odd(AIndex) then
    Result.RotationAngle.Point := Point3D(0, 180, 0);
  Result.MaterialSource := AMaterial;
end;

procedure TSprite3DBackground.BuildPlanes;
var
  I: Integer;
begin
  // Owned by this object, so freed with it, after the planes that use them
  FMaterial := TGorillaDefaultMaterialSource.Create(Self);
  FMaterial.UseLighting := False;
  FMaterial.UseSpecular := False;
  FSquareMaterial := TGorillaDefaultMaterialSource.Create(Self);
  FSquareMaterial.UseLighting := False;
  FSquareMaterial.UseSpecular := False;
  for I := 0 to High(FPlanes) do
    FPlanes[I] := NewPlane(I, FMaterial);
  UpdateMaterials;
end;

// Adds square planes until the pool holds FSquaresWanted. Adds children, so
// it must not run during rendering; Fit queues it instead.
procedure TSprite3DBackground.GrowSquares;
var
  I, Old: Integer;
begin
  if (FSquareMaterial = nil) or (Length(FSquares) >= FSquaresWanted) then
    Exit;
  Old := Length(FSquares);
  SetLength(FSquares, FSquaresWanted);
  for I := Old to High(FSquares) do
  begin
    FSquares[I] := NewPlane(I, FSquareMaterial);
    // Out of sight until Fit places it
    FSquares[I].Position.Point := Point3D(0, 0, FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR);
  end;
  Fit;
  Repaint;
end;

// Grows the pool to ACount planes on the main thread after the current
// frame, once however many times it is asked for before then
procedure TSprite3DBackground.QueueGrowSquares(const ACount: Integer);
var
  Alive: IBackgroundAlive;
  Me: TSprite3DBackground;
  Step: TThreadProcedure;
begin
  FSquaresWanted := Max(FSquaresWanted, ACount);
  if FGrowQueued then
    Exit;
  FGrowQueued := True;
  Alive := FAlive as IBackgroundAlive;
  Me := Self;
  Step :=
    procedure
    begin
      if not Alive.IsAlive then
        Exit;   // freed meanwhile
      Me.FGrowQueued := False;
      Me.GrowSquares;
    end;
  System.Classes.TThread.ForceQueue(nil, Step);
end;

// The colour of the whole-view plane, per pixel, from the plane's own
// position, v_VertPos, which runs from -0.5 at the top to 0.5 at the bottom.
// While Transparent it is the checker's light grey; the dark squares are
// planes of their own.
function TSprite3DBackground.SurfaceCode: String;
begin
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      Result := SolidCode(FSpec.Colour);
    TSprite3DBackgroundKind.Gradient:
      Result :=
        'void SurfaceShader(inout TLocals DATA){' + sLineBreak +
        '  float t = clamp(vars.v_VertPos.y + 0.5, 0.0, 1.0);' + sLineBreak +
        '  vec3 col = mix(' + GlslColour(FSpec.GradientFrom) + ', ' +
          GlslColour(FSpec.GradientTo) + ', t);' + sLineBreak +
        '  DATA.BaseColor = vec4(col, 1.0);' + sLineBreak +
        '  DATA.Alpha = 1.0;' + sLineBreak +
        '}';
  else
    Result := SolidCode(FSpec.CheckerLight);
  end;
end;

// Builds the shaders for the present spec. Changes the materials, so it must
// not run during rendering.
procedure TSprite3DBackground.UpdateMaterials;
begin
  if FMaterial = nil then
    Exit;
  // The materials' own colours too, in case a shader's is not what reaches
  // the screen
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      FMaterial.Diffuse := FSpec.Colour or $FF000000;
    TSprite3DBackgroundKind.Gradient:
      FMaterial.Diffuse := FSpec.GradientFrom or $FF000000;
  else
    FMaterial.Diffuse := FSpec.CheckerLight or $FF000000;
  end;
  SetShader(FMaterial, SurfaceCode);
  FSquareMaterial.Diffuse := FSpec.CheckerDark or $FF000000;
  SetShader(FSquareMaterial, SolidCode(FSpec.CheckerDark));
end;

// Lays the dark squares over the view at local depth AZ, or, without AShow,
// moves them all out of view. A square is CheckerSize logical pixels, times
// the smallest whole multiple that keeps the dark squares within
// MaxCheckerSquares; square (column, row) from the top-left is dark where
// column + row is odd. Planes the pool lacks are queued for after the frame;
// those it has spare are hidden.
procedure TSprite3DBackground.FitSquares(const AZ: Single; const AShow: Boolean);
var
  Viewport: TViewport3D;
  Depth, HalfW, HalfH, Side, PixelSide, X, Y: Single;
  Columns, Rows, Dark, Multiple, Used, Column, Row, I: Integer;
  Plane: TGorillaPlane;

  // Places plane AIndex, unless the pool has not reached it yet
  procedure Place(const AIndex: Integer; const AX, AY: Single);
  begin
    if AIndex > High(FSquares) then
      Exit;
    Plane := FSquares[AIndex];
    if not Plane.Visible then
      Plane.Visible := True;
    if not SameValue(Plane.Width, Side, 0.0001) then
      Plane.Width := Side;
    if not SameValue(Plane.Height, Side, 0.0001) then
      Plane.Height := Side;
    if not SameValue(Plane.Position.X, AX, 0.0001) or
      not SameValue(Plane.Position.Y, AY, 0.0001) or
      not SameValue(Plane.Position.Z, AZ, 0.001) then
      Plane.Position.Point := Point3D(AX, AY, AZ);
  end;

begin
  Used := 0;
  Viewport := FCamera.FindViewport;
  Depth := FCamera.MaxViewDepth * SQUARE_DEPTH_FRACTION;
  if AShow and (Viewport <> nil) and (Viewport.Width >= 1) and (Viewport.Height >= 1) and
    FCamera.ViewHalfExtents(Depth, HalfW, HalfH) then
  begin
    // The smallest multiple of the asked-for size that keeps the count down
    Multiple := 1;
    repeat
      PixelSide := Max(FSpec.CheckerSize, 1) * Multiple;
      Columns := Ceil(Viewport.Width / PixelSide);
      Rows := Ceil(Viewport.Height / PixelSide);
      Dark := (Columns * Rows) div 2;
      Inc(Multiple);
    until Dark <= MaxCheckerSquares;
    // Logical pixels to units at the squares' depth
    Side := PixelSide * 2 * HalfW / Viewport.Width;
    for Row := 0 to Rows - 1 do
      for Column := 0 to Columns - 1 do
        if Odd(Column + Row) then
        begin
          X := -HalfW + (Column + 0.5) * Side;
          Y := -HalfH + (Row + 0.5) * Side;
          Place(Used, X, Y);
          Place(Used + 1, X, Y);
          Inc(Used, 2);
        end;
    if Used > Length(FSquares) then
      QueueGrowSquares(Used);
  end;
  for I := Used to High(FSquares) do
    if FSquares[I].Visible then
      FSquares[I].Visible := False;
end;

// Sizes and places the planes to fill the camera's view; only what changed
// is set, as each change makes the scene redraw
procedure TSprite3DBackground.Fit;
var
  Depth, HalfW, HalfH, Z: Single;
  Plane: TGorillaPlane;
  Away: Boolean;
begin
  if (FPlanes[0] = nil) or (FCamera = nil) then
    Exit;
  Depth := FCamera.MaxViewDepth * DEPTH_FRACTION;
  if not FCamera.ViewHalfExtents(Depth, HalfW, HalfH) then
    Exit;
  // Depth is measured from the camera, which is Distance behind this
  // frame's origin. For now the background is also kept out of view while
  // the camera is orthographic: there it showed black over the whole scene,
  // for every kind, although its size and depth were right.
  Away := FHidden or FCamera.IsOrthographic;
  if Away then
    Z := FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR
  else
    Z := Depth - FCamera.Distance;
  for Plane in FPlanes do
  begin
    if not SameValue(Plane.Width, 2 * HalfW * OVERSCAN, 0.001) then
      Plane.Width := 2 * HalfW * OVERSCAN;
    if not SameValue(Plane.Height, 2 * HalfH * OVERSCAN, 0.001) then
      Plane.Height := 2 * HalfH * OVERSCAN;
    if not SameValue(Plane.Position.Z, Z, 0.001) or (Plane.Position.X <> 0) or
      (Plane.Position.Y <> 0) then
      Plane.Position.Point := Point3D(0, 0, Z);
  end;
  // The squares: hidden the same way, so a grab never shows them
  if Away then
    Z := FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR
  else
    Z := FCamera.MaxViewDepth * SQUARE_DEPTH_FRACTION - FCamera.Distance;
  FitSquares(Z, FSpec.Kind = TSprite3DBackgroundKind.Transparent);
end;

procedure TSprite3DBackground.Render;
begin
  inherited;
  Fit;
end;

procedure TSprite3DBackground.SetSpec(const Value: TSprite3DBackgroundSpec);
begin
  FSpec := Value;
  FSpec.CheckerSize := Max(FSpec.CheckerSize, 1);
  UpdateMaterials;
  Fit;
  Repaint;
end;

procedure TSprite3DBackground.SetHidden(const Value: Boolean);
begin
  FHidden := Value;
  Fit;
end;

end.
