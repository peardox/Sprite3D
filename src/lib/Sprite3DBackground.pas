//** @abstract(A background for a Gorilla3D view: none, a checker for transparency, a colour
//** or a gradient.)
//**
//** TSprite3DBackgroundSpec describes a background: its kind, its colours and the size of the
//** checker squares. TSprite3DBackground draws one behind everything a TSprite3DCamera sees.
//** It is an unlit plane that moves with the camera, just inside the far plane, and is resized
//** every frame to fill the view exactly, whatever the projection, field of view or window
//** size. Its colour comes from a short GLSL SurfaceShader: one colour for Solid, a blend down
//** the plane for Gradient, with the plane turned in the view, and enlarged to cover it, to
//** point the blend in the chosen GradientDirection. It hangs from the camera's RollPivot, the
//** dummy the camera itself hangs from; every plane is a pair facing opposite ways, so one
//** always faces the camera however Gorilla culls back faces.
//**
//** The None kind, the default, draws nothing at all, leaving whatever the viewport shows
//** behind the scene, and grabs transparent. The Transparent kind draws a checker of two
//** greys, the usual sign that an image is transparent there. It is built from geometry:
//** the whole-view plane is put away, and two pools of small planes, one sharing a material
//** of the light grey and one of the dark grey, all made before the first frame, tile the
//** view side by side at the background's depth. They never overlap, so the depth buffer
//** never has to choose between two surfaces at almost the same depth. Each frame only
//** moves them, as the scene is never changed in any other way once it is drawn. The
//** squares are CheckerSize logical pixels on screen, counted from the view's top-left
//** corner, which is light. To keep the number of planes reasonable, a checker that would
//** need more than MaxCheckerSquares squares of either grey has its squares enlarged by a
//** whole multiple until it fits. Every plane is left out of Gorilla's frustum culling,
//** which wrongly skipped most of the squares.
//**
//** Every material has a black Diffuse colour: even unlit, Gorilla adds part of it to the
//** colour a shader gives, which would brighten the background.
//**
//** The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs the same
//** background: transparent for None and for Transparent, as the checker stands for, and
//** the colour or gradient otherwise. Hide the background while a grab is drawn, with
//** Hidden, so it does not end up in the grab.
//**
//** @preformatted(
//** TSprite3DCamera.RollPivot @(TDummy@)
//** |-- TSprite3DCamera                 at @(0, 0, -Distance@), looking along +Z
//** `-- TSprite3DBackground @(TDummy@)   fitted to the view every frame
//**     |-- TGorillaPlane @(x2@)          the whole view; colour or gradient
//**     `-- TGorillaPlane @(x2 each@)     the checker's squares, while Transparent
//** )
unit Sprite3DBackground;

{
  A background for a Gorilla3D view: none, a checker for transparency, a
  colour or a gradient.

  TSprite3DBackgroundSpec describes a background: its kind, its colours and
  the size of the checker squares. TSprite3DBackground draws one behind
  everything a TSprite3DCamera sees. It is an unlit plane that moves with
  the camera, just inside the far plane, and is resized every frame to fill
  the view exactly, whatever the projection, field of view or window size.
  Its colour comes from a short GLSL SurfaceShader: one colour for Solid, a
  blend down the plane for Gradient, with the plane turned in the view, and
  enlarged to cover it, to point the blend in the chosen GradientDirection.
  It hangs from the camera's RollPivot,
  the dummy the camera itself hangs from; every plane is a pair facing
  opposite ways, so one always faces the camera however Gorilla culls back
  faces.

  The None kind, the default, draws nothing at all, leaving whatever the
  viewport shows behind the scene, and grabs transparent. The Transparent
  kind draws a checker of two greys, the usual sign that an image is
  transparent there. It is built from geometry: the whole-view plane is put
  away, and two pools of small planes, one sharing a material of the light
  grey and one of the dark grey, all made before the first frame, tile the
  view side by side at the background's depth. They never overlap, so the
  depth buffer never has to choose between two surfaces at almost the same
  depth. Each frame only moves them, as the scene is never changed in any
  other way once it is drawn. The squares are CheckerSize logical pixels on
  screen, counted from the view's top-left corner, which is light. To keep
  the number of planes reasonable, a checker that would need more than
  MaxCheckerSquares squares of either grey has its squares enlarged by a
  whole multiple until it fits. Every plane is left out of Gorilla's
  frustum culling, which wrongly skipped most of the squares.

  Every material has a black Diffuse colour: even unlit, Gorilla adds part
  of it to the colour a shader gives, which would brighten the background.

  The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs
  the same background: transparent for None and for Transparent, as the
  checker stands for, and the colour or gradient otherwise. Hide the background while a
  grab is drawn, with Hidden, so it does not end up in the grab.

    TSprite3DCamera.RollPivot (TDummy)
    |-- TSprite3DCamera                 at (0, 0, -Distance), looking along +Z
    `-- TSprite3DBackground (TDummy)   fitted to the view every frame
        |-- TGorillaPlane (x2)          the whole view; colour or gradient
        `-- TGorillaPlane (x2 each)     the checker's squares, while Transparent
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
    //** @abstract(No background is drawn: the viewport's own shows, and grabs are
    //** transparent. The default.)
    /// <summary>No background is drawn: the viewport's own shows, and grabs are
    /// transparent. The default.</summary>
    None,
    //** @abstract(A checker on screen, standing for transparency; transparency in grabs.)
    /// <summary>A checker on screen, standing for transparency; transparency in
    /// grabs.</summary>
    Transparent,
    //** @abstract(One colour, Colour.)
    /// <summary>One colour, Colour.</summary>
    Solid,
    //** @abstract(A blend from GradientFrom to GradientTo, in the direction
    //** GradientDirection.)
    /// <summary>A blend from GradientFrom to GradientTo, in the direction
    /// GradientDirection.</summary>
    Gradient);

  //** @abstract(Which way a Gradient background runs, from GradientFrom to GradientTo.)
  //**
  //** The diagonals run corner to corner whatever the view's shape: the colour is constant
  //** along lines parallel to the other diagonal, as in CSS's @code(to bottom right).
  /// <summary>Which way a Gradient background runs, from GradientFrom to
  /// GradientTo.</summary>
  /// <remarks>The diagonals run corner to corner whatever the view's shape: the colour is
  /// constant along lines parallel to the other diagonal, as in CSS's <c>to bottom
  /// right</c>.</remarks>
  TSprite3DGradientDirection = (
    //** @abstract(From the top edge to the bottom edge. The default.)
    /// <summary>From the top edge to the bottom edge. The default.</summary>
    TopToBottom,
    //** @abstract(From the left edge to the right edge.)
    /// <summary>From the left edge to the right edge.</summary>
    LeftToRight,
    //** @abstract(From the top-left corner to the bottom-right corner.)
    /// <summary>From the top-left corner to the bottom-right corner.</summary>
    TopLeftToBottomRight,
    //** @abstract(From the top-right corner to the bottom-left corner.)
    /// <summary>From the top-right corner to the bottom-left corner.</summary>
    TopRightToBottomLeft);
  {$SCOPEDENUMS OFF}

  //** @abstract(Describes a background: its kind, colours and checker size.)
  //**
  //** A plain record, copied by value. Default gives the application's starting background:
  //** None, with a checker of 64-pixel squares in two greys ready for Transparent. Colours
  //** are used opaque; their alpha is ignored.
  /// <summary>Describes a background: its kind, colours and checker size.</summary>
  /// <remarks>A plain record, copied by value. Default gives the application's starting
  /// background: None, with a checker of 64-pixel squares in two greys ready for Transparent.
  /// Colours are used opaque; their alpha is ignored.</remarks>
  TSprite3DBackgroundSpec = record
    //** @abstract(What the background shows.)
    /// <summary>What the background shows.</summary>
    Kind: TSprite3DBackgroundKind;
    //** @abstract(The colour of a Solid background.)
    /// <summary>The colour of a Solid background.</summary>
    Colour: TAlphaColor;
    //** @abstract(The colour at the start of a Gradient background.)
    /// <summary>The colour at the start of a Gradient background.</summary>
    GradientFrom: TAlphaColor;
    //** @abstract(The colour at the end of a Gradient background.)
    /// <summary>The colour at the end of a Gradient background.</summary>
    GradientTo: TAlphaColor;
    //** @abstract(Which way a Gradient background runs.)
    /// <summary>Which way a Gradient background runs.</summary>
    GradientDirection: TSprite3DGradientDirection;
    //** @abstract(The side of each checker square, in pixels on screen; at least 1.)
    /// <summary>The side of each checker square, in pixels on screen; at least 1.</summary>
    CheckerSize: Integer;
    //** @abstract(The lighter checker colour.)
    /// <summary>The lighter checker colour.</summary>
    CheckerLight: TAlphaColor;
    //** @abstract(The darker checker colour.)
    /// <summary>The darker checker colour.</summary>
    CheckerDark: TAlphaColor;
    //** @abstract(The starting background: None.)
    //**
    //** The checker has 64-pixel squares of light and mid grey, Colour is mid grey and the
    //** gradient runs from light grey at the top to dark grey at the bottom, ready for when
    //** another kind is chosen.
    //**
    //** @returns(The default spec.)
    /// <summary>The starting background: None.</summary>
    /// <remarks>The checker has 64-pixel squares of light and mid grey, Colour is mid grey and
    /// the gradient runs from light grey at the top to dark grey at the bottom, ready for
    /// when another kind is chosen.</remarks>
    /// <returns>The default spec.</returns>
    class function Default: TSprite3DBackgroundSpec; static;
    //** @abstract(The gradient's colour a fraction of the way along it.)
    //**
    //** @param(AFraction 0 for the start, GradientFrom, to 1 for the end, GradientTo; values
    //** outside are clamped.)
    //**
    //** @returns(The blended colour, opaque.)
    /// <summary>The gradient's colour a fraction of the way along it.</summary>
    /// <param name="AFraction">0 for the start, GradientFrom, to 1 for the end, GradientTo;
    /// values outside are clamped.</param>
    /// <returns>The blended colour, opaque.</returns>
    function GradientAt(const AFraction: Single): TAlphaColor;
    //** @abstract(The direction the gradient runs in an area of the given size, and its
    //** length.)
    //**
    //** The direction is a unit vector with X to the right and Y down; the length is the
    //** area's extent along it, from the starting edge or corner to the opposite one.
    //**
    //** @param(AWidth The area's width, in any unit.)
    //**
    //** @param(AHeight The area's height, in the same unit.)
    //**
    //** @param(ADX The direction's X component.)
    //**
    //** @param(ADY The direction's Y component; never negative.)
    //**
    //** @param(ALength The gradient's length, in the unit of AWidth and AHeight.)
    /// <summary>The direction the gradient runs in an area of the given size, and its
    /// length.</summary>
    /// <remarks>The direction is a unit vector with X to the right and Y down; the length is
    /// the area's extent along it, from the starting edge or corner to the opposite
    /// one.</remarks>
    /// <param name="AWidth">The area's width, in any unit.</param>
    /// <param name="AHeight">The area's height, in the same unit.</param>
    /// <param name="ADX">The direction's X component.</param>
    /// <param name="ADY">The direction's Y component; never negative.</param>
    /// <param name="ALength">The gradient's length, in the unit of AWidth and
    /// AHeight.</param>
    procedure GradientAxis(const AWidth, AHeight: Single; out ADX, ADY, ALength: Single);
    //** @abstract(The gradient's colour at a point of an area.)
    //**
    //** @param(AX The point's distance from the area's left edge.)
    //**
    //** @param(AY The point's distance from the area's top edge.)
    //**
    //** @param(AWidth The area's width, in the unit of AX.)
    //**
    //** @param(AHeight The area's height, in the unit of AY.)
    //**
    //** @returns(The blended colour, opaque.)
    /// <summary>The gradient's colour at a point of an area.</summary>
    /// <param name="AX">The point's distance from the area's left edge.</param>
    /// <param name="AY">The point's distance from the area's top edge.</param>
    /// <param name="AWidth">The area's width, in the unit of AX.</param>
    /// <param name="AHeight">The area's height, in the unit of AY.</param>
    /// <returns>The blended colour, opaque.</returns>
    function GradientAtPoint(const AX, AY, AWidth, AHeight: Single): TAlphaColor;
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
    // The checker's squares, in facing pairs: 2 * MaxCheckerSquares dark,
    // then as many light
    FSquares: TArray<TGorillaPlane>;
    FDarkMaterial: TGorillaDefaultMaterialSource;
    FLightMaterial: TGorillaDefaultMaterialSource;
    FSpec: TSprite3DBackgroundSpec;
    FHidden: Boolean;
    procedure BuildPlanes;
    function NewPlane(const AIndex: Integer;
      const AMaterial: TGorillaDefaultMaterialSource): TGorillaPlane;
    procedure UpdateMaterials;
    procedure Fit;
    procedure FitSquares(const AZ: Single; const AShow: Boolean);
    procedure TurnPlane(const APlane: TGorillaPlane; const AFlipped: Boolean;
      const AAngle, ADX, ADY: Single);
    function SurfaceCode: String;
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
    procedure SetHidden(const Value: Boolean);
  protected
    //** @abstract(Fits the planes to the view before each frame is drawn.)
    /// <summary>Fits the planes to the view before each frame is drawn.</summary>
    procedure Render; override;
  public
    //** @abstract(The most checker squares of each grey drawn in the view.)
    //**
    //** A checker that would need more has its squares enlarged by a whole multiple until it
    //** fits. Each square is a pair of planes, all made by AttachTo.
    /// <summary>The most checker squares of each grey drawn in the view.</summary>
    /// <remarks>A checker that would need more has its squares enlarged by a whole multiple
    /// until it fits. Each square is a pair of planes, all made by AttachTo.</remarks>
    const MaxCheckerSquares = 150;
  public
    //** @abstract(Creates the background with the default spec, not yet attached.)
    //**
    //** @param(AOwner The owner; nil is usual, as the camera's rig frees it once attached.)
    /// <summary>Creates the background with the default spec, not yet attached.</summary>
    /// <param name="AOwner">The owner; nil is usual, as the camera's rig frees it once
    /// attached.</param>
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Puts the background behind everything ACamera sees.)
    //**
    //** Makes it a child of ACamera's RollPivot, beside the camera, so it moves and turns with
    //** the camera and is freed with its rig. The first call also makes all its planes, so
    //** call it before the view is first drawn.
    //**
    //** @param(ACamera The camera to follow.)
    /// <summary>Puts the background behind everything ACamera sees.</summary>
    /// <remarks>Makes it a child of ACamera's RollPivot, beside the camera, so it moves and
    /// turns with the camera and is freed with its rig. The first call also makes all its
    /// planes, so call it before the view is first drawn.</remarks>
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

const
  // The background sits this far along the far plane's distance, so
  // everything the camera can show is in front of it
  DEPTH_FRACTION = 0.95;
  // Each checker square is this much larger than its place, so neighbours
  // overlap by a fraction of a pixel and no crack shows between them
  SQUARE_OVERLAP = 1.01;
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

// An unlit material with a black Diffuse colour: even unlit, Gorilla adds
// part of the Diffuse colour to what the shader gives (#808080 showed as
// #E0E0E0 with Diffuse #808080, and as #A0A0A0 with Diffuse black). Making
// the Ambient, Emissive and Specular colours black as well came with the
// background not showing at all, so they are left as they are.
function NewFlatMaterial(const AOwner: TComponent): TGorillaDefaultMaterialSource;
begin
  Result := TGorillaDefaultMaterialSource.Create(AOwner);
  Result.UseLighting := False;
  Result.UseSpecular := False;
  Result.Diffuse := TAlphaColors.Black;
end;

{ TSprite3DBackgroundSpec }

class function TSprite3DBackgroundSpec.Default: TSprite3DBackgroundSpec;
begin
  Result.Kind := TSprite3DBackgroundKind.None;
  Result.Colour := $FF808080;
  Result.GradientFrom := $FFD0D0D0;
  Result.GradientTo := $FF404040;
  Result.GradientDirection := TSprite3DGradientDirection.TopToBottom;
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

// A diagonal runs along the normal to the other diagonal, (H, W) or (-H, W)
// scaled to unit length, so its two corners are exactly at either end
procedure TSprite3DBackgroundSpec.GradientAxis(const AWidth, AHeight: Single;
  out ADX, ADY, ALength: Single);
var
  W, H, N: Single;
begin
  W := Max(AWidth, 0);
  H := Max(AHeight, 0);
  N := Sqrt(W * W + H * H);
  case GradientDirection of
    TSprite3DGradientDirection.LeftToRight:
      begin
        ADX := 1;
        ADY := 0;
      end;
    TSprite3DGradientDirection.TopLeftToBottomRight,
    TSprite3DGradientDirection.TopRightToBottomLeft:
      if N > 0 then
      begin
        ADX := H / N;
        ADY := W / N;
        if GradientDirection = TSprite3DGradientDirection.TopRightToBottomLeft then
          ADX := -ADX;
      end
      else
      begin
        ADX := 0;
        ADY := 1;
      end;
  else
    begin
      ADX := 0;
      ADY := 1;
    end;
  end;
  ALength := W * Abs(ADX) + H * Abs(ADY);
end;

function TSprite3DBackgroundSpec.GradientAtPoint(const AX, AY, AWidth,
  AHeight: Single): TAlphaColor;
var
  DX, DY, Len: Single;
begin
  GradientAxis(AWidth, AHeight, DX, DY, Len);
  if Len <= 0 then
    Exit(GradientAt(0));
  Result := GradientAt(((AX - AWidth / 2) * DX + (AY - AHeight / 2) * DY) / Len + 0.5);
end;

{ TSprite3DBackground }

constructor TSprite3DBackground.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  FSpec := TSprite3DBackgroundSpec.Default;
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

// A plane parented before anything else, as in Gorilla's examples, and left
// out of frustum culling. A plane
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
  // Always drawn: Gorilla's frustum culling misjudged where the small
  // checker squares are and skipped most of them, though they were in view
  Result.FrustumCullingCheck := False;
  if Odd(AIndex) then
    Result.RotationAngle.Point := Point3D(0, 180, 0);
  Result.MaterialSource := AMaterial;
end;

procedure TSprite3DBackground.BuildPlanes;
var
  I: Integer;
begin
  // Owned by this object, so freed with it, after the planes that use them
  FMaterial := NewFlatMaterial(Self);
  FDarkMaterial := NewFlatMaterial(Self);
  FLightMaterial := NewFlatMaterial(Self);
  for I := 0 to High(FPlanes) do
    FPlanes[I] := NewPlane(I, FMaterial);
  // The whole pool of squares now, out of sight until Fit places them: the
  // dark ones first, then the light
  SetLength(FSquares, 4 * MaxCheckerSquares);
  for I := 0 to High(FSquares) do
  begin
    if I < 2 * MaxCheckerSquares then
      FSquares[I] := NewPlane(I, FDarkMaterial)
    else
      FSquares[I] := NewPlane(I, FLightMaterial);
    FSquares[I].Position.Point := Point3D(0, 0, FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR);
  end;
  UpdateMaterials;
end;

// The colour of the whole-view plane, per pixel, from the plane's own
// position, v_VertPos, which runs from -0.5 at the top to 0.5 at the bottom.
// It is not shown while Transparent; the checker's squares are planes of
// their own.
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
  SetShader(FMaterial, SurfaceCode);
  SetShader(FDarkMaterial, SolidCode(FSpec.CheckerDark));
  SetShader(FLightMaterial, SolidCode(FSpec.CheckerLight));
end;

// Tiles the view with the checker's squares at local depth AZ, the same
// depth as the background would be, or, without AShow, moves them all out of
// view. A square is CheckerSize logical pixels, times the smallest whole
// multiple that keeps either grey within MaxCheckerSquares; square (column,
// row) from the top-left is dark where column + row is odd, light otherwise.
// Spare planes are moved beyond the far plane, the way Hidden works, rather
// than made invisible.
procedure TSprite3DBackground.FitSquares(const AZ: Single; const AShow: Boolean);
var
  Viewport: TViewport3D;
  HalfW, HalfH, Side, PixelSide, X, Y, AwayZ: Single;
  Columns, Rows, Multiple, Column, Row, I, Pool: Integer;
  Used: array[Boolean] of Integer;   // planes used: [False] light, [True] dark
  Dark: Boolean;

  // Sizes plane AIndex and puts it at (AX, AY, AZ), changing only what
  // differs, as each change makes the scene redraw
  procedure Place(const AIndex: Integer; const AX, AY: Single);
  var
    Plane: TGorillaPlane;
  begin
    Plane := FSquares[AIndex];
    if not SameValue(Plane.Width, Side * SQUARE_OVERLAP, 0.0001) then
      Plane.Width := Side * SQUARE_OVERLAP;
    if not SameValue(Plane.Height, Side * SQUARE_OVERLAP, 0.0001) then
      Plane.Height := Side * SQUARE_OVERLAP;
    if not SameValue(Plane.Position.X, AX, 0.0001) or
      not SameValue(Plane.Position.Y, AY, 0.0001) or
      not SameValue(Plane.Position.Z, AZ, 0.001) then
      Plane.Position.Point := Point3D(AX, AY, AZ);
  end;

begin
  Pool := 2 * MaxCheckerSquares;   // planes per grey
  Used[False] := 0;
  Used[True] := 0;
  Viewport := FCamera.FindViewport;
  if AShow and (Viewport <> nil) and (Viewport.Width >= 1) and (Viewport.Height >= 1) and
    FCamera.ViewHalfExtents(FCamera.MaxViewDepth * DEPTH_FRACTION, HalfW, HalfH) then
  begin
    // The smallest multiple of the asked-for size that keeps the count down;
    // the light squares are the more numerous, by at most one
    Multiple := 1;
    repeat
      PixelSide := Max(FSpec.CheckerSize, 1) * Multiple;
      Columns := Ceil(Viewport.Width / PixelSide);
      Rows := Ceil(Viewport.Height / PixelSide);
      Inc(Multiple);
    until (Columns * Rows + 1) div 2 <= MaxCheckerSquares;
    // Logical pixels to units at the squares' depth
    Side := PixelSide * 2 * HalfW / Viewport.Width;
    for Row := 0 to Rows - 1 do
      for Column := 0 to Columns - 1 do
      begin
        Dark := Odd(Column + Row);
        X := -HalfW + (Column + 0.5) * Side;
        Y := -HalfH + (Row + 0.5) * Side;
        // Dark planes fill the first half of the pool, light the second
        I := Used[Dark];
        if not Dark then
          Inc(I, Pool);
        Place(I, X, Y);
        Place(I + 1, X, Y);
        Inc(Used[Dark], 2);
      end;
  end;
  AwayZ := FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR;
  for I := 0 to High(FSquares) do
    if ((I < Pool) and (I >= Used[True])) or ((I >= Pool) and (I - Pool >= Used[False])) then
      if not SameValue(FSquares[I].Position.Z, AwayZ, 0.001) then
        FSquares[I].Position.Point := Point3D(0, 0, AwayZ);
end;

// Turns APlane about the view axis so its own Y axis, down which its shader
// blends, points along (ADX, ADY) in this frame, X to the right and Y down.
// AFlipped planes also have their half turn about Y. Which way a positive
// angle turns depends on the order FMX applies the turns in, so after
// turning by AAngle the plane's matrix is checked, and the angle is negated
// if its Y axis points the wrong way. Nothing is set if it already points
// the right way.
procedure TSprite3DBackground.TurnPlane(const APlane: TGorillaPlane;
  const AFlipped: Boolean; const AAngle, ADX, ADY: Single);
const
  CLOSE = 0.999;   // cosine of the angle within which the axis counts as right
var
  YTurn: Single;
  M: TMatrix3D;

  function Aligned: Boolean;
  var
    L: Single;
  begin
    M := APlane.LocalMatrix;
    // FMX transforms row vectors, so the second row is where Y points;
    // divided by its length in case the matrix also scales
    L := Sqrt(Sqr(M.m21) + Sqr(M.m22) + Sqr(M.m23));
    Result := (L > 0) and ((M.m21 * ADX + M.m22 * ADY) / L >= CLOSE);
  end;

begin
  if AFlipped then
    YTurn := 180
  else
    YTurn := 0;
  if SameValue(APlane.RotationAngle.X, 0, 0.001) and
    SameValue(APlane.RotationAngle.Y, YTurn, 0.001) and Aligned then
    Exit;
  APlane.RotationAngle.Point := Point3D(0, YTurn, AAngle);
  if not Aligned then
    APlane.RotationAngle.Point := Point3D(0, YTurn, -AAngle);
end;

// Sizes and places the planes to fill the camera's view; only what changed
// is set, as each change makes the scene redraw
procedure TSprite3DBackground.Fit;
var
  Depth, HalfW, HalfH, Z, PlaneW, PlaneH, DX, DY, Len, Turn: Single;
  I: Integer;
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
  // for every kind, although its size and depth were right. None keeps
  // every plane out of view, so nothing is drawn.
  Away := FHidden or FCamera.IsOrthographic or
    (FSpec.Kind = TSprite3DBackgroundKind.None);
  // While Transparent the squares take the whole-view plane's place
  if Away or (FSpec.Kind = TSprite3DBackgroundKind.Transparent) then
    Z := FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR
  else
    Z := Depth - FCamera.Distance;
  // The plane's shader blends down its own Y axis. For a Gradient, the plane
  // is turned about the view axis so that axis points along the gradient,
  // and sized so its height spans the view along it, end to end, and its
  // width covers the view across it. Otherwise it is square to the view.
  if FSpec.Kind = TSprite3DBackgroundKind.Gradient then
  begin
    FSpec.GradientAxis(2 * HalfW, 2 * HalfH, DX, DY, Len);
    PlaneW := (2 * HalfW * DY + 2 * HalfH * Abs(DX)) * OVERSCAN;
    PlaneH := Len * OVERSCAN;
    Turn := RadToDeg(ArcTan2(DX, DY));
  end
  else
  begin
    DX := 0;
    DY := 1;
    PlaneW := 2 * HalfW * OVERSCAN;
    PlaneH := 2 * HalfH * OVERSCAN;
    Turn := 0;
  end;
  for I := 0 to High(FPlanes) do
  begin
    Plane := FPlanes[I];
    if not SameValue(Plane.Width, PlaneW, 0.001) then
      Plane.Width := PlaneW;
    if not SameValue(Plane.Height, PlaneH, 0.001) then
      Plane.Height := PlaneH;
    if not SameValue(Plane.Position.Z, Z, 0.001) or (Plane.Position.X <> 0) or
      (Plane.Position.Y <> 0) then
      Plane.Position.Point := Point3D(0, 0, Z);
    TurnPlane(Plane, Odd(I), Turn, DX, DY);
  end;
  // The squares, at the same depth: hidden the same way, so a grab never
  // shows them
  if Away then
    Z := FCamera.MaxViewDepth * HIDDEN_DEPTH_FACTOR
  else
    Z := Depth - FCamera.Distance;
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
