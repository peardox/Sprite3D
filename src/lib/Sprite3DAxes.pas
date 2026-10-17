//** @abstract(Draws a model's X, Y and Z axes through its centre of rotation.)
//**
//** ShowModelAxes adds a TModelAxes to a TGorillaModel. It shows three lines: red along X,
//** green along Y and blue along Z. They cross at the model's centre of rotation, which is
//** FMX's RotationCenter in the model's own coordinates and is the model's origin unless that
//** has been changed. Each line runs from one face of the model's bounding box to the opposite
//** face, so unless the centre of rotation lies outside that box, the lines stay inside the box
//** that FitToBounds frames. The axes move, turn and scale with the model and show its own
//** axes rather than the scene's. FMX's Y axis points down the screen, so with no rotation the
//** green line's positive end is at the bottom.
//**
//** There are two ways of drawing, chosen by OnTop. Gorilla's materials have no setting to turn
//** depth testing off, so only the context can draw over the model.
//**
//** OnTop True, the default, draws the lines over everything, so the model never hides them,
//** even inside a solid model. In each frame's main pass the TModelAxes draws them with the
//** context's DrawLine helper, following Gorilla v1.5's Line Rendering guide. Widths above 1
//** pixel work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always draw 1 pixel.
//**
//** OnTop False draws each line with a GLSL shader, through the documented SurfaceShader hook
//** of a TGorillaDefaultMaterialSource, which Gorilla converts for Vulkan and Metal. Each line
//** is drawn on two thin TGorillaPlane strips that cross along it, so it is seen from any
//** angle; the shader keeps only the pixels within LineWidth / 2 of the strip's middle. The
//** width works on every backend. The lines are ordinary geometry, so the model hides the
//** parts inside it or behind it. The strips are not children of the model, so they never
//** count in its bounding box; they sit in a frame beside the model that copies its position,
//** rotation, scale and centre of rotation whenever they change.
//**
//** @preformatted(
//** <model's parent>
//** |-- TGorillaModel
//** |   `-- TModelAxes          one per model, found by FindModelAxes; OnTop: draws the lines
//** |                           in its Render; otherwise keeps the frame on the model
//** `-- axes frame              OnTop False only; TDummy copying the model's transform
//**     `-- 6 x TGorillaPlane   two strips per line, drawn by their shaders
//** )
//**
//** Usage:
//**
//** @preformatted(
//** ShowModelAxes@(GorillaModel1@);                // after the model is loaded; drawn on top
//** ShowModelAxes@(GorillaModel1@, 2, False@);      // shader lines 2 pixels wide
//** HideModelAxes@(GorillaModel1@);
//** )
unit Sprite3DAxes;

{
  Draws a model's X, Y and Z axes through its centre of rotation.

  ShowModelAxes adds a TModelAxes to a TGorillaModel. It shows three lines:
  red along X, green along Y and blue along Z. They cross at the model's
  centre of rotation, which is FMX's RotationCenter in the model's own
  coordinates and is the model's origin unless that has been changed. Each
  line runs from one face of the model's bounding box to the opposite face,
  so unless the centre of rotation lies outside that box, the lines stay
  inside the box that FitToBounds frames. The axes move, turn and scale with
  the model and show its own axes rather than the scene's. FMX's Y axis
  points down the screen, so with no rotation the green line's positive end
  is at the bottom.

  There are two ways of drawing, chosen by OnTop. Gorilla's materials have
  no setting to turn depth testing off, so only the context can draw over
  the model.

  OnTop True, the default, draws the lines over everything, so the model
  never hides them, even inside a solid model. In each frame's main pass the
  TModelAxes draws them with the context's DrawLine helper, following
  Gorilla v1.5's Line Rendering guide. Widths above 1 pixel work on desktop
  OpenGL only; Vulkan, Metal and OpenGL ES always draw 1 pixel.

  OnTop False draws each line with a GLSL shader, through the documented
  SurfaceShader hook of a TGorillaDefaultMaterialSource, which Gorilla
  converts for Vulkan and Metal. Each line is drawn on two thin
  TGorillaPlane strips that cross along it, so it is seen from any angle;
  the shader keeps only the pixels within LineWidth / 2 of the strip's
  middle. The width works on every backend. The lines are ordinary geometry,
  so the model hides the parts inside it or behind it. The strips are not
  children of the model, so they never count in its bounding box; they sit
  in a frame beside the model that copies its position, rotation, scale and
  centre of rotation whenever they change.

    <model's parent>
    |-- TGorillaModel
    |   `-- TModelAxes          one per model, found by FindModelAxes; OnTop: draws the lines
    |                           in its Render; otherwise keeps the frame on the model
    `-- axes frame              OnTop False only; TDummy copying the model's transform
        `-- 6 x TGorillaPlane   two strips per line, drawn by their shaders

  Usage:
    ShowModelAxes(GorillaModel1);                // after the model is loaded; drawn on top
    ShowModelAxes(GorillaModel1, 2, False);      // shader lines 2 pixels wide
    HideModelAxes(GorillaModel1);
}

interface

uses
  System.Classes, System.SysUtils, System.UITypes, System.Math, System.Math.Vectors,
  FMX.Types, FMX.Types3D, FMX.Controls3D, FMX.Objects3D,
  Gorilla.Context, Gorilla.Context.Types, Gorilla.Model, Gorilla.Plane,
  Gorilla.Material.Default;

type
  //** @abstract(Shows three coloured lines through a point, drawn on top or by shaders.)
  //**
  //** A TDummy. With OnTop it draws the lines in its own Render, in the main pass only, with
  //** the context's DrawLine helper. Without OnTop it draws nothing itself: it owns a frame
  //** beside its parent holding six shader-drawn TGorillaPlane strips, and in each Render
  //** copies the parent's position, rotation, scale and centre of rotation to the frame if any
  //** of them changed. The strips are built when SetExtent is called and rebuilt only when a
  //** property changes. Freeing the TModelAxes frees the frame, strips and materials.
  //**
  //** Its Width, Height and Depth are set to the lines' extent and its Position to their
  //** middle, so anything that culls by an object's size sees the whole set. The object is not
  //** stored in .fmx files and ignores the mouse. Use it from the main thread only.
  /// <summary>Shows three coloured lines through a point, drawn on top or by
  /// shaders.</summary>
  /// <remarks><para>A TDummy. With OnTop it draws the lines in its own Render, in the main pass
  /// only, with the context's DrawLine helper. Without OnTop it draws nothing itself: it owns a
  /// frame beside its parent holding six shader-drawn TGorillaPlane strips, and in each Render
  /// copies the parent's position, rotation, scale and centre of rotation to the frame if any
  /// of them changed. The strips are built when SetExtent is called and rebuilt only when a
  /// property changes. Freeing the TModelAxes frees the frame, strips and materials.</para>
  /// <para>Its Width, Height and Depth are set to the lines' extent and its Position to their
  /// middle, so anything that culls by an object's size sees the whole set. The object is not
  /// stored in .fmx files and ignores the mouse. Use it from the main thread only.</para>
  /// </remarks>
  TModelAxes = class(TDummy)
  private
    FLo: TPoint3D;
    FHi: TPoint3D;
    FCentre: TPoint3D;
    FBoxLo: TPoint3D;
    FBoxHi: TPoint3D;
    FPivot: TPoint3D;
    FFrame: TDummy;
    FXColor: TAlphaColor;
    FYColor: TAlphaColor;
    FZColor: TAlphaColor;
    FLineWidth: Single;
    FOnTop: Boolean;
    FHasExtent: Boolean;
    procedure DrawLines;
    procedure DrawOnTop;
    procedure FreeStrips;
    procedure RebuildStrips;
    procedure AddStrip(const ACentre: TPoint3D; const ALength: Single;
      const ARotation: TPoint3D; const AAlongY: Boolean; const AColor: TAlphaColor);
    procedure SyncFrame;
    function StripCode(const AAlongY: Boolean; const AColor: TAlphaColor): string;
    procedure SetXColor(const Value: TAlphaColor);
    procedure SetYColor(const Value: TAlphaColor);
    procedure SetZColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
    procedure SetOnTop(const Value: Boolean);
  protected
    //** @abstract(Draws the lines on top, or keeps the strips' frame on the parent.)
    //**
    //** Does nothing before SetExtent is called. With OnTop, draws the three lines in the main
    //** pass only, setting the context matrix to this object's AbsoluteMatrix and restoring
    //** the previous matrix, line state and depth test afterwards, even if drawing fails.
    //** Without OnTop, copies the parent's transform to the frame if it changed, and draws
    //** nothing.
    /// <summary>Draws the lines on top, or keeps the strips' frame on the parent.</summary>
    /// <remarks>Does nothing before <see cref="SetExtent"/> is called. With OnTop, draws the
    /// three lines in the main pass only, setting the context matrix to this object's
    /// AbsoluteMatrix and restoring the previous matrix, line state and depth test afterwards,
    /// even if drawing fails. Without OnTop, copies the parent's transform to the frame if it
    /// changed, and draws nothing.</remarks>
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
    //** @abstract(Creates axes with no extent: red, green and blue, 1 pixel wide, on top.)
    //**
    //** Nothing is drawn until SetExtent is called.
    //**
    //** @param(AOwner The owner, or nil to leave freeing to the parent.)
    /// <summary>Creates axes with no extent: red, green and blue, 1 pixel wide, on
    /// top.</summary>
    /// <remarks>Nothing is drawn until <see cref="SetExtent"/> is called.</remarks>
    /// <param name="AOwner">The owner, or nil to leave freeing to the parent.</param>
    constructor Create(AOwner: TComponent); override;

    //** @abstract(Frees the axes, with any frame, strips and materials.)
    //**
    //** If the frame's parent is already being freed, as when the whole scene closes, the
    //** frame is left for it to free.
    /// <summary>Frees the axes, with any frame, strips and materials.</summary>
    /// <remarks>If the frame's parent is already being freed, as when the whole scene closes,
    /// the frame is left for it to free.</remarks>
    destructor Destroy; override;

    //** @abstract(Sets where the three lines cross and how far each reaches.)
    //**
    //** Each line passes through ACentre parallel to one axis and runs from the low corner's
    //** value to the high corner's value on that axis, widened if need be to reach ACentre.
    //** All points are in the parent's coordinates. Without OnTop the strips are built here,
    //** so set the parent first; they are not built without one. Redraws the axes.
    //**
    //** @param(ALow The corner with the smallest X, Y and Z, such as a bounding box's
    //** TopLeftNear.)
    //**
    //** @param(AHigh The corner with the largest X, Y and Z, such as a bounding box's
    //** BottomRightFar.)
    //**
    //** @param(ACentre The point the three lines cross.)
    /// <summary>Sets where the three lines cross and how far each reaches.</summary>
    /// <remarks>Each line passes through ACentre parallel to one axis and runs from the low
    /// corner's value to the high corner's value on that axis, widened if need be to reach
    /// ACentre. All points are in the parent's coordinates. Without OnTop the strips are built
    /// here, so set the parent first; they are not built without one. Redraws the
    /// axes.</remarks>
    /// <param name="ALow">The corner with the smallest X, Y and Z, such as a bounding box's
    /// TopLeftNear.</param>
    /// <param name="AHigh">The corner with the largest X, Y and Z, such as a bounding box's
    /// BottomRightFar.</param>
    /// <param name="ACentre">The point the three lines cross.</param>
    procedure SetExtent(const ALow, AHigh, ACentre: TPoint3D);

    //** @abstract(Colour of the X line; red by default.)
    /// <summary>Colour of the X line; red by default.</summary>
    property XColor: TAlphaColor read FXColor write SetXColor;
    //** @abstract(Colour of the Y line; green by default.)
    /// <summary>Colour of the Y line; green by default.</summary>
    property YColor: TAlphaColor read FYColor write SetYColor;
    //** @abstract(Colour of the Z line; blue by default.)
    /// <summary>Colour of the Z line; blue by default.</summary>
    property ZColor: TAlphaColor read FZColor write SetZColor;
    //** @abstract(Line width in screen pixels, whatever the distance; 1 by default.)
    //**
    //** Without OnTop the shader draws any width on every backend. With OnTop, values above 1
    //** work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always draw 1 pixel. Values
    //** below 1 count as 1.
    /// <summary>Line width in screen pixels, whatever the distance; 1 by default.</summary>
    /// <remarks>Without OnTop the shader draws any width on every backend. With OnTop, values
    /// above 1 work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always draw 1 pixel.
    /// Values below 1 count as 1.</remarks>
    property LineWidth: Single read FLineWidth write SetLineWidth;
    //** @abstract(Whether the lines are drawn over everything; True by default.)
    //**
    //** True draws them with the context and depth testing off, so the model and anything in
    //** front cannot hide them. False draws them with shaders as ordinary geometry, so they
    //** disappear where they pass inside a solid model or behind something. Changing it
    //** switches between the two at once.
    /// <summary>Whether the lines are drawn over everything; True by default.</summary>
    /// <remarks>True draws them with the context and depth testing off, so the model and
    /// anything in front cannot hide them. False draws them with shaders as ordinary geometry,
    /// so they disappear where they pass inside a solid model or behind something. Changing it
    /// switches between the two at once.</remarks>
    property OnTop: Boolean read FOnTop write SetOnTop;
  end;

//** @abstract(Draws AModel's X, Y and Z axes through its centre of rotation.)
//**
//** Any axes already on AModel are removed first, so calling it again, for example after
//** loading a different model, redraws them for the new bounds. The lines cross at
//** @code(AModel.RotationCenter) and each runs across AModel's current bounding box, from
//** @code(GetAnimatedBoundingBox), widened if need be to reach the centre of rotation. X is
//** red, Y green and Z blue.
//**
//** The axes are added as a child of AModel, so they follow its position, rotation and scale,
//** and are freed with it. They are sized for the box at the time of the call. Without
//** AOnTop, AModel must already have a parent. Call from the main thread only.
//**
//** @param(AModel The model to draw axes on. Nothing happens if it is nil.)
//**
//** @param(ALineWidth Line width in screen pixels. With AOnTop, values above 1 work on desktop
//** OpenGL only; without it, on every backend.)
//**
//** @param(AOnTop True to draw the lines over everything, so the model cannot hide them;
//** False to draw them with shaders, letting the model hide the parts inside it.)
//**
//** @returns(The new axes, owned by AModel; or nil, with nothing added, if AModel is nil or
//** its bounding box is empty.)
//**
//** @seealso(HideModelAxes)
//**
//** @seealso(FindModelAxes)
/// <summary>Draws AModel's X, Y and Z axes through its centre of rotation.</summary>
/// <remarks><para>Any axes already on AModel are removed first, so calling it again, for
/// example after loading a different model, redraws them for the new bounds. The lines cross
/// at <c>AModel.RotationCenter</c> and each runs across AModel's current bounding box, from
/// <c>GetAnimatedBoundingBox</c>, widened if need be to reach the centre of rotation. X is
/// red, Y green and Z blue.</para>
/// <para>The axes are added as a child of AModel, so they follow its position, rotation and
/// scale, and are freed with it. They are sized for the box at the time of the call. Without
/// AOnTop, AModel must already have a parent. Call from the main thread only.</para></remarks>
/// <param name="AModel">The model to draw axes on. Nothing happens if it is nil.</param>
/// <param name="ALineWidth">Line width in screen pixels. With AOnTop, values above 1 work on
/// desktop OpenGL only; without it, on every backend.</param>
/// <param name="AOnTop">True to draw the lines over everything, so the model cannot hide them;
/// False to draw them with shaders, letting the model hide the parts inside it.</param>
/// <returns>The new axes, owned by AModel; or nil, with nothing added, if AModel is nil or its
/// bounding box is empty.</returns>
/// <seealso cref="HideModelAxes"/>
/// <seealso cref="FindModelAxes"/>
function ShowModelAxes(const AModel: TGorillaModel; const ALineWidth: Single = 1;
  const AOnTop: Boolean = True): TModelAxes;

//** @abstract(Removes the axes ShowModelAxes added to AModel.)
//**
//** Frees the TModelAxes, with any strips. Does nothing if AModel is nil or has no axes. Call
//** from the main thread only.
//**
//** @param(AModel The model to remove the axes from.)
//**
//** @seealso(ShowModelAxes)
/// <summary>Removes the axes ShowModelAxes added to AModel.</summary>
/// <remarks>Frees the TModelAxes, with any strips. Does nothing if AModel is nil or has no
/// axes. Call from the main thread only.</remarks>
/// <param name="AModel">The model to remove the axes from.</param>
/// <seealso cref="ShowModelAxes"/>
procedure HideModelAxes(const AModel: TGorillaModel);

//** @abstract(Returns the axes ShowModelAxes added to AModel, or nil.)
//**
//** Looks only at AModel's direct children. The caller does not own the result; it is freed
//** with AModel or by HideModelAxes.
//**
//** @param(AModel The model to look on; nil gives nil.)
//**
//** @returns(The axes, or nil if AModel is nil or has none.)
/// <summary>Returns the axes ShowModelAxes added to AModel, or nil.</summary>
/// <remarks>Looks only at AModel's direct children. The caller does not own the result; it is
/// freed with AModel or by <see cref="HideModelAxes"/>.</remarks>
/// <param name="AModel">The model to look on; nil gives nil.</param>
/// <returns>The axes, or nil if AModel is nil or has none.</returns>
function FindModelAxes(const AModel: TGorillaModel): TModelAxes;

implementation

const
  // A strip is never thinner than this, so a flat model still gets a
  // valid plane
  MIN_STRIP = 0.001;

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

{ TModelAxes }

constructor TModelAxes.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  FXColor := TAlphaColorRec.Red;
  FYColor := TAlphaColorRec.Lime;   // pure green; TAlphaColorRec.Green is dark
  FZColor := TAlphaColorRec.Blue;
  FLineWidth := 1;
  FOnTop := True;
end;

destructor TModelAxes.Destroy;
begin
  FreeStrips;
  inherited;
end;

procedure TModelAxes.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FFrame) then
    FFrame := nil;   // the strips and materials went with it
end;

procedure TModelAxes.SetExtent(const ALow, AHigh, ACentre: TPoint3D);
var
  Mid: TPoint3D;
begin
  // In the parent's (the model's) coordinates, for the strips
  FBoxLo := Point3D(Min(ALow.X, ACentre.X), Min(ALow.Y, ACentre.Y),
    Min(ALow.Z, ACentre.Z));
  FBoxHi := Point3D(Max(AHigh.X, ACentre.X), Max(AHigh.Y, ACentre.Y),
    Max(AHigh.Z, ACentre.Z));
  FPivot := ACentre;

  // Sit in the middle of the lines, sized to them, so a size-based cull
  // never drops them; DrawLines then works relative to this position
  Mid := (FBoxLo + FBoxHi) * 0.5;
  Position.Point := Mid;
  Width := Max(FBoxHi.X - FBoxLo.X, MIN_STRIP);
  Height := Max(FBoxHi.Y - FBoxLo.Y, MIN_STRIP);
  Depth := Max(FBoxHi.Z - FBoxLo.Z, MIN_STRIP);
  FLo := FBoxLo - Mid;
  FHi := FBoxHi - Mid;
  FCentre := ACentre - Mid;
  FHasExtent := True;

  RebuildStrips;
  Repaint;
end;

{ --- On top: drawn by the context --- }

procedure TModelAxes.DrawLines;
var
  O: Single;
begin
  O := AbsoluteOpacity;
  Context.DrawLine(Point3D(FLo.X, FCentre.Y, FCentre.Z),
    Point3D(FHi.X, FCentre.Y, FCentre.Z), O, FXColor);
  Context.DrawLine(Point3D(FCentre.X, FLo.Y, FCentre.Z),
    Point3D(FCentre.X, FHi.Y, FCentre.Z), O, FYColor);
  Context.DrawLine(Point3D(FCentre.X, FCentre.Y, FLo.Z),
    Point3D(FCentre.X, FCentre.Y, FHi.Z), O, FZColor);
end;

procedure TModelAxes.DrawOnTop;
var
  Ctx: TGorillaContext;
  PrevMat: TMatrix3D;
  Wide: Boolean;
begin
  // Main pass only: Render also runs in shadow, reflection, environment
  // and other passes, where CurrentPass is assigned. Under a plain FMX
  // context there are no passes, and the FMX helpers still work.
  if Context is TGorillaContext then
    Ctx := TGorillaContext(Context)
  else
    Ctx := nil;
  if (Ctx <> nil) and Assigned(Ctx.CurrentPass) then
    Exit;

  // Line width is Gorilla line state; it needs persistent mode because
  // there are three draws. Width 1 is the default, so leave state alone.
  Wide := (Ctx <> nil) and (FLineWidth > 1);

  PrevMat := Context.CurrentMatrix;
  Context.SetMatrix(AbsoluteMatrix);
  try
    Context.SetContextState(TContextState.csZTestOff);
    try
      if Wide then
        Ctx.BeginLineRendering(FLineWidth, TGorillaLineType.Solid, True);
      try
        DrawLines;
      finally
        if Wide then
          Ctx.EndLineRendering(True);
      end;
    finally
      Context.SetContextState(TContextState.csZTestOn);
    end;
  finally
    Context.SetMatrix(PrevMat);
  end;
end;

{ --- Not on top: drawn by shaders on strips --- }

procedure TModelAxes.SyncFrame;
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

procedure TModelAxes.FreeStrips;
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
  Frame.Free;   // frees the strips, then the materials it owns
end;

function TModelAxes.StripCode(const AAlongY: Boolean; const AColor: TAlphaColor): string;
var
  C: TAlphaColorRec;
  Across: string;
begin
  C := TAlphaColorRec(AColor);
  // The line runs down the middle of the strip, along its local X or Y.
  // v_VertPos is the strip's own unit-square position, -0.5 to 0.5, so the
  // other coordinate is 0 on the line. Divided by fwidth it becomes the
  // distance from the line in pixels, whatever the strip's size, distance
  // or angle; pixels further than half the line width are discarded. The
  // strip ends where the line ends, so no end test is needed.
  if AAlongY then
    Across := 'x'
  else
    Across := 'y';
  Result :=
    'void SurfaceShader(inout TLocals DATA){' + sLineBreak +
    '  float s = vars.v_VertPos.' + Across + ';' + sLineBreak +
    '  float d = abs(s) / max(fwidth(s), 0.000001);' + sLineBreak +
    '  if (d > ' + GlslFloat(FLineWidth * 0.5) + ') discard;' + sLineBreak +
    '  DATA.BaseColor = vec4(' + GlslFloat(C.R / 255) + ', ' + GlslFloat(C.G / 255) +
      ', ' + GlslFloat(C.B / 255) + ', ' + GlslFloat(C.A / 255) + ');' + sLineBreak +
    '  DATA.Alpha = ' + GlslFloat(C.A / 255) + ';' + sLineBreak +
    '}';
end;

procedure TModelAxes.AddStrip(const ACentre: TPoint3D; const ALength: Single;
  const ARotation: TPoint3D; const AAlongY: Boolean; const AColor: TAlphaColor);
var
  Plane: TGorillaPlane;
  Mat: TGorillaDefaultMaterialSource;
  Code: TStringList;
  Len: Single;
begin
  // The plane, parented before anything else, as in Gorilla's examples
  Plane := TGorillaPlane.Create(nil);
  Plane.Stored := False;
  Plane.Locked := True;
  Plane.HitTest := False;
  Plane.Parent := FFrame;   // freed with the frame
  Plane.TwoSide := True;    // seen from either side

  // Square, so the line is exactly as long as the strip whichever way it
  // runs; only the line's pixels survive the shader. The line is centred
  // on the strip, so the turn's direction does not matter.
  Len := Max(ALength, MIN_STRIP);
  Plane.Width := Len;
  Plane.Height := Len;
  Plane.RotationAngle.Point := ARotation;
  Plane.Position.Point := ACentre;

  // Owned by the frame, so freed with it, after the plane that uses it
  Mat := TGorillaDefaultMaterialSource.Create(FFrame);
  Mat.UseLighting := False;
  Mat.UseSpecular := False;
  Mat.Diffuse := AColor;
  // The shader property takes a TStrings instance; setting .Text at runtime
  // would not trigger Gorilla's shader update
  Code := TStringList.Create;
  try
    Code.Text := StripCode(AAlongY, AColor);
    Mat.SurfaceShader := Code;
  finally
    Code.Free;
  end;
  Plane.MaterialSource := Mat;
end;

procedure TModelAxes.RebuildStrips;
var
  Model: TControl3D;
  Mid, Size, NoTurn, TurnX, TurnY: TPoint3D;
begin
  NoTurn := TPoint3D.Zero;
  TurnX := Point3D(90, 0, 0);   // local X-Y into X-Z; local Y onto Z
  TurnY := Point3D(0, 90, 0);   // local X-Y into Z-Y; local X onto Z

  FreeStrips;
  if FOnTop or not FHasExtent or not (Parent is TControl3D)
    or (Parent.Parent = nil) then
    Exit;
  Model := TControl3D(Parent);

  // A frame beside the model, on the model's transform, so the strips are
  // in model units without being part of the model's bounds
  FFrame := TDummy.Create(nil);
  FFrame.Stored := False;
  FFrame.Locked := True;
  FFrame.HitTest := False;
  FFrame.FreeNotification(Self);
  FFrame.Parent := Model.Parent;
  SyncFrame;

  // Two strips per line, in the two planes that contain it, so whichever
  // way the line is seen at least one strip faces the camera. Each turn is
  // about one axis only, so the order of FMX's rotations does not matter.
  Mid := (FBoxLo + FBoxHi) * 0.5;
  Size := FBoxHi - FBoxLo;
  // X: along local X, in X-Y and in X-Z
  AddStrip(Point3D(Mid.X, FPivot.Y, FPivot.Z), Size.X, NoTurn, False, FXColor);
  AddStrip(Point3D(Mid.X, FPivot.Y, FPivot.Z), Size.X, TurnX, False, FXColor);
  // Y: along local Y, in X-Y and in Z-Y
  AddStrip(Point3D(FPivot.X, Mid.Y, FPivot.Z), Size.Y, NoTurn, True, FYColor);
  AddStrip(Point3D(FPivot.X, Mid.Y, FPivot.Z), Size.Y, TurnY, True, FYColor);
  // Z: along local Y turned onto Z in X-Z, and local X turned onto Z in Z-Y
  AddStrip(Point3D(FPivot.X, FPivot.Y, Mid.Z), Size.Z, TurnX, True, FZColor);
  AddStrip(Point3D(FPivot.X, FPivot.Y, Mid.Z), Size.Z, TurnY, False, FZColor);
end;

procedure TModelAxes.Render;
begin
  inherited;
  if not FHasExtent then
    Exit;
  if FOnTop then
    DrawOnTop
  else
    SyncFrame;   // a no-op unless the model moved, turned or was scaled
end;

procedure TModelAxes.SetXColor(const Value: TAlphaColor);
begin
  FXColor := Value;
  RebuildStrips;
  Repaint;
end;

procedure TModelAxes.SetYColor(const Value: TAlphaColor);
begin
  FYColor := Value;
  RebuildStrips;
  Repaint;
end;

procedure TModelAxes.SetZColor(const Value: TAlphaColor);
begin
  FZColor := Value;
  RebuildStrips;
  Repaint;
end;

procedure TModelAxes.SetLineWidth(const Value: Single);
begin
  FLineWidth := Max(Value, 1);
  RebuildStrips;
  Repaint;
end;

procedure TModelAxes.SetOnTop(const Value: Boolean);
begin
  FOnTop := Value;
  RebuildStrips;   // builds the strips when False, frees them when True
  Repaint;
end;

{ Routines }

function FindModelAxes(const AModel: TGorillaModel): TModelAxes;
var
  I: Integer;
begin
  Result := nil;
  if AModel = nil then
    Exit;
  for I := 0 to AModel.ChildrenCount - 1 do
    if AModel.Children[I] is TModelAxes then
      Exit(TModelAxes(AModel.Children[I]));
end;

procedure HideModelAxes(const AModel: TGorillaModel);
var
  Axes: TModelAxes;
begin
  Axes := FindModelAxes(AModel);
  if Axes <> nil then
  begin
    Axes.Parent := nil;
    Axes.Free;   // frees any frame, strips and materials
  end;
end;

function ShowModelAxes(const AModel: TGorillaModel; const ALineWidth: Single;
  const AOnTop: Boolean): TModelAxes;
var
  Box: TBoundingBox;
begin
  Result := nil;
  if AModel = nil then
    Exit;

  HideModelAxes(AModel);

  // Current pose, in the model's own coordinates: the box ShowBoundingBox
  // draws and FitToBounds fits. Empty (min > max) if there are no vertices.
  Box := AModel.GetAnimatedBoundingBox();
  if (Box.Left > Box.Right) or (Box.Top > Box.Bottom) or (Box.Near > Box.Far) then
    Exit;

  Result := TModelAxes.Create(nil);
  Result.LineWidth := ALineWidth;
  Result.OnTop := AOnTop;
  // Parent first: the strips need the model and its parent
  Result.Parent := AModel;   // freed with the model
  Result.SetExtent(Box.TopLeftNear, Box.BottomRightFar,
    AModel.RotationCenter.Point);
end;

end.
