//** @abstract(A background for a Gorilla3D view: a checker for transparency, a colour or a
//** gradient.)
//**
//** TSprite3DBackgroundSpec describes a background: its kind, its colours and the size of
//** the checker squares. TSprite3DBackground draws one behind everything a TSprite3DCamera
//** sees. It is an unlit plane that moves with the camera, just inside the far plane, and is
//** resized every frame to fill the view exactly, whatever the projection, field of view or
//** window size; its colours are worked out per pixel by GLSL code in its material, through
//** the same SurfaceShader hook Sprite3DGrid uses. It hangs from the camera's RollPivot, the
//** dummy the camera itself hangs from, so it is drawn like any other dummy's child; it is
//** two planes facing opposite ways, so one always faces the camera however Gorilla culls
//** back faces.
//**
//** The Transparent kind draws a checker of two greys, the usual sign that an image is
//** transparent there; its squares are CheckerSize pixels on screen. Solid fills the view
//** with one colour, and Gradient blends from GradientFrom at the top to GradientTo at the
//** bottom.
//**
//** The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs the same
//** background: transparent for Transparent, as the checker stands for, and the colour or
//** gradient otherwise. Hide the plane while a grab is drawn, with Hidden, so it does not
//** end up in the grab.
//**
//** @preformatted(
//** TSprite3DCamera.RollPivot @(TDummy@)
//** |-- TSprite3DCamera                 at @(0, 0, -Distance@), looking along +Z
//** `-- TSprite3DBackground @(TDummy@)   fitted to the view every frame
//**     |-- TGorillaPlane              facing the camera; drawn by its shader
//**     `-- TGorillaPlane              the same, turned to face the other way
//** )
unit Sprite3DBackground;

{
  A background for a Gorilla3D view: a checker for transparency, a colour or
  a gradient.

  TSprite3DBackgroundSpec describes a background: its kind, its colours and
  the size of the checker squares. TSprite3DBackground draws one behind
  everything a TSprite3DCamera sees. It is an unlit plane that moves with
  the camera, just inside the far plane, and is resized every frame to fill
  the view exactly, whatever the projection, field of view or window size;
  its colours are worked out per pixel by GLSL code in its material, through
  the same SurfaceShader hook Sprite3DGrid uses. It hangs from the camera's
  RollPivot, the dummy the camera itself hangs from, so it is drawn like any
  other dummy's child; it is two planes facing opposite ways, so one always
  faces the camera however Gorilla culls back faces.

  The Transparent kind draws a checker of two greys, the usual sign that an
  image is transparent there; its squares are CheckerSize pixels on screen.
  Solid fills the view with one colour, and Gradient blends from
  GradientFrom at the top to GradientTo at the bottom.

  The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs
  the same background: transparent for Transparent, as the checker stands
  for, and the colour or gradient otherwise. Hide the plane while a grab is
  drawn, with Hidden, so it does not end up in the grab.

    TSprite3DCamera.RollPivot (TDummy)
    |-- TSprite3DCamera                 at (0, 0, -Distance), looking along +Z
    `-- TSprite3DBackground (TDummy)   fitted to the view every frame
        |-- TGorillaPlane              facing the camera; drawn by its shader
        `-- TGorillaPlane              the same, turned to face the other way
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
  //** and is freed with the camera's rig. Each frame it fits its plane to the view at a depth
  //** just inside the far
  //** plane, so the scene is always in front of it. Set Spec to change what it shows, and
  //** PixelScale to the screen's scale so checker squares are CheckerSize logical pixels.
  //** For the main thread only.
  /// <summary>Draws a background behind everything a TSprite3DCamera sees.</summary>
  /// <remarks>Create it and call AttachTo with the camera; it then hangs from the camera's
  /// RollPivot and is freed with the camera's rig. Each frame it fits its plane to the view at
  /// a depth just inside the far
  /// plane, so the scene is always in front of it. Set Spec to change what it shows, and
  /// PixelScale to the screen's scale so checker squares are CheckerSize logical pixels. For
  /// the main thread only.</remarks>
  TSprite3DBackground = class(TDummy)
  private
    FCamera: TSprite3DCamera;
    FPlanes: array[0..1] of TGorillaPlane;
    FMaterial: TGorillaDefaultMaterialSource;
    FSpec: TSprite3DBackgroundSpec;
    FPixelScale: Single;
    FHidden: Boolean;
    procedure BuildPlane;
    procedure UpdateShader;
    procedure Fit;
    function SurfaceCode: String;
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
    procedure SetPixelScale(const Value: Single);
    procedure SetHidden(const Value: Boolean);
  protected
    //** @abstract(Fits the plane to the view before each frame is drawn.)
    /// <summary>Fits the plane to the view before each frame is drawn.</summary>
    procedure Render; override;
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
    //** @abstract(Device pixels per logical pixel; 1 by default.)
    //**
    //** Set it to the form's canvas scale, such as 2 on a 200% display, so checker squares are
    //** CheckerSize logical pixels whatever the display.
    /// <summary>Device pixels per logical pixel; 1 by default.</summary>
    /// <remarks>Set it to the form's canvas scale, such as 2 on a 200% display, so checker
    /// squares are CheckerSize logical pixels whatever the display.</remarks>
    property PixelScale: Single read FPixelScale write SetPixelScale;
    //** @abstract(True moves the plane out of view, as while a grab is drawn.)
    //**
    //** It is moved beyond the far plane rather than made invisible, so it takes effect for
    //** the next drawing even within a frame. False brings it back.
    /// <summary>True moves the plane out of view, as while a grab is drawn.</summary>
    /// <remarks>It is moved beyond the far plane rather than made invisible, so it takes
    /// effect for the next drawing even within a frame. False brings it back.</remarks>
    property Hidden: Boolean read FHidden write SetHidden;
  end;

implementation

uses
  System.Math;

const
  // The plane sits this far along the far plane's distance, so everything
  // the camera can show is in front of it
  DEPTH_FRACTION = 0.95;
  // Where the plane goes while Hidden: well beyond the far plane
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
  FPixelScale := 1;
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
    BuildPlane;
  Fit;
end;

// Two planes, each parented before anything else, as in Gorilla's examples.
// A plane lies in its local X-Y plane, square to the camera, which looks
// along +Z; FMX's +Y points down the screen, so a plane's +Y is the bottom
// of the view. The second is turned half a turn about Y, so whichever side
// Gorilla treats as the front, one of them shows it to the camera. The turn
// keeps Y, so both draw exactly the same pixels.
procedure TSprite3DBackground.BuildPlane;
var
  I: Integer;
begin
  // Owned by this object, so freed with it, after the planes that use it
  FMaterial := TGorillaDefaultMaterialSource.Create(Self);
  FMaterial.UseLighting := False;
  FMaterial.UseSpecular := False;
  UpdateShader;

  for I := 0 to High(FPlanes) do
  begin
    FPlanes[I] := TGorillaPlane.Create(nil);
    FPlanes[I].Stored := False;
    FPlanes[I].Locked := True;
    FPlanes[I].HitTest := False;
    FPlanes[I].Parent := Self;   // freed with this object
    if I = 1 then
      FPlanes[I].RotationAngle.Point := Point3D(0, 180, 0);
    FPlanes[I].MaterialSource := FMaterial;
  end;
end;

// The pattern, per pixel. The checker uses the window position of the
// pixel, gl_FragCoord, so its squares are a fixed size on screen however
// far away the plane is; the gradient uses the plane's own position,
// v_VertPos, which runs from -0.5 at the top to 0.5 at the bottom.
function TSprite3DBackground.SurfaceCode: String;
var
  Colour: String;
begin
  case FSpec.Kind of
    TSprite3DBackgroundKind.Solid:
      Colour := '  vec3 col = ' + GlslColour(FSpec.Colour) + ';' + sLineBreak;
    TSprite3DBackgroundKind.Gradient:
      Colour :=
        '  float t = clamp(vars.v_VertPos.y + 0.5, 0.0, 1.0);' + sLineBreak +
        '  vec3 col = mix(' + GlslColour(FSpec.GradientFrom) + ', ' +
          GlslColour(FSpec.GradientTo) + ', t);' + sLineBreak;
  else
    Colour :=
      '  vec2 cell = floor(gl_FragCoord.xy / ' +
        GlslFloat(Max(FSpec.CheckerSize, 1) * FPixelScale) + ');' + sLineBreak +
      '  float odd = mod(cell.x + cell.y, 2.0);' + sLineBreak +
      '  vec3 col = mix(' + GlslColour(FSpec.CheckerLight) + ', ' +
        GlslColour(FSpec.CheckerDark) + ', odd);' + sLineBreak;
  end;
  Result :=
    'void SurfaceShader(inout TLocals DATA){' + sLineBreak +
    Colour +
    '  DATA.BaseColor = vec4(col, 1.0);' + sLineBreak +
    '  DATA.Alpha = 1.0;' + sLineBreak +
    '}';
end;

procedure TSprite3DBackground.UpdateShader;
var
  Code: TStringList;
begin
  if FMaterial = nil then
    Exit;
  // The material's own colour too, in case the shader's is not what reaches
  // the screen
  if FSpec.Kind = TSprite3DBackgroundKind.Solid then
    FMaterial.Diffuse := FSpec.Colour or $FF000000
  else
    FMaterial.Diffuse := FSpec.CheckerLight or $FF000000;
  // The shader property takes a TStrings instance; setting .Text at runtime
  // would not trigger Gorilla's shader update
  Code := TStringList.Create;
  try
    Code.Text := SurfaceCode;
    FMaterial.SurfaceShader := Code;
  finally
    Code.Free;
  end;
end;

// Sizes and places the plane to fill the camera's view; only what changed is
// set, as each change makes the scene redraw
procedure TSprite3DBackground.Fit;
var
  Depth, HalfW, HalfH, Z: Single;
  Plane: TGorillaPlane;
begin
  if (FPlanes[0] = nil) or (FCamera = nil) then
    Exit;
  Depth := FCamera.MaxViewDepth * DEPTH_FRACTION;
  if not FCamera.ViewHalfExtents(Depth, HalfW, HalfH) then
    Exit;
  // Depth is measured from the camera, which is Distance behind this
  // frame's origin
  if FHidden then
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
  UpdateShader;
end;

procedure TSprite3DBackground.SetPixelScale(const Value: Single);
begin
  if SameValue(Value, FPixelScale) or (Value <= 0) then
    Exit;
  FPixelScale := Value;
  UpdateShader;
end;

procedure TSprite3DBackground.SetHidden(const Value: Boolean);
begin
  FHidden := Value;
  Fit;
end;

end.
