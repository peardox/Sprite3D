//** @abstract(Draws a model's X, Y and Z axes through its centre of rotation.)
//**
//** ShowModelAxes adds a TModelAxes to a TGorillaModel. In each frame's main pass it draws
//** three lines with the context's DrawLine helper: red along X, green along Y and blue along
//** Z. They cross at the model's centre of rotation, which is FMX's RotationCenter in the
//** model's own coordinates and is the model's origin unless that has been changed. Each line
//** runs from one face of the model's bounding box to the opposite face, so unless the centre
//** of rotation lies outside that box, the lines stay inside the box that FitToBounds frames.
//**
//** The axes are a child of the model and are drawn with their own AbsoluteMatrix, so they
//** move, turn and scale with the model and show its own axes rather than the scene's. FMX's Y
//** axis points down the screen, so with no rotation the green line's positive end is at the
//** bottom. By default the lines are 1 pixel wide and drawn with depth testing off, so the
//** model never hides them.
//**
//** This follows Gorilla v1.5's Line Rendering guide: a TDummy descendant that overrides
//** Render, sets and restores the context matrix, draws only in the main pass, and wraps a
//** wider line width in BeginLineRendering and EndLineRendering. Widths above 1 pixel work on
//** desktop OpenGL only; Vulkan, Metal and OpenGL ES always draw 1 pixel.
//**
//** @preformatted(
//** TGorillaModel
//** `-- TModelAxes      one per model, found by FindModelAxes;
//**                     draws the three lines in its Render
//** )
//**
//** Usage:
//**
//** @preformatted(
//** ShowModelAxes@(GorillaModel1@);    // after the model is loaded
//** HideModelAxes@(GorillaModel1@);
//** )
unit Sprite3DAxes;

{
  Draws a model's X, Y and Z axes through its centre of rotation.

  ShowModelAxes adds a TModelAxes to a TGorillaModel. In each frame's main
  pass it draws three lines with the context's DrawLine helper: red along X,
  green along Y and blue along Z. They cross at the model's centre of
  rotation, which is FMX's RotationCenter in the model's own coordinates and
  is the model's origin unless that has been changed. Each line runs from one
  face of the model's bounding box to the opposite face, so unless the centre
  of rotation lies outside that box, the lines stay inside the box that
  FitToBounds frames.

  The axes are a child of the model and are drawn with their own
  AbsoluteMatrix, so they move, turn and scale with the model and show its
  own axes rather than the scene's. FMX's Y axis points down the screen, so
  with no rotation the green line's positive end is at the bottom. By
  default the lines are 1 pixel wide and drawn with depth testing off, so
  the model never hides them.

  This follows Gorilla v1.5's Line Rendering guide: a TDummy descendant that
  overrides Render, sets and restores the context matrix, draws only in the
  main pass, and wraps a wider line width in BeginLineRendering and
  EndLineRendering. Widths above 1 pixel work on desktop OpenGL only;
  Vulkan, Metal and OpenGL ES always draw 1 pixel.

    TGorillaModel
    `-- TModelAxes      one per model, found by FindModelAxes;
                        draws the three lines in its Render

  Usage:
    ShowModelAxes(GorillaModel1);    // after the model is loaded
    HideModelAxes(GorillaModel1);
}

interface

uses
  System.Classes, System.UITypes, System.Math, System.Math.Vectors,
  FMX.Types3D, FMX.Controls3D, FMX.Objects3D,
  Gorilla.Context, Gorilla.Context.Types, Gorilla.Model;

type
  //** @abstract(Draws three coloured lines through a point, using the render context.)
  //**
  //** A TDummy that overrides Render, as Gorilla's Line Rendering guide recommends, so it adds
  //** no meshes or materials. It draws only in the main pass, not in shadow, reflection or
  //** other passes. The lines are in its parent's coordinates when it has no position,
  //** rotation or scale of its own, which is how ShowModelAxes adds it. Its Width, Height and
  //** Depth are set to the lines' extent and its Position to their middle, so anything that
  //** culls by an object's size sees the whole set.
  //**
  //** The object is not stored in .fmx files and ignores the mouse. Use it from the main thread
  //** only.
  /// <summary>Draws three coloured lines through a point, using the render context.</summary>
  /// <remarks><para>A TDummy that overrides Render, as Gorilla's Line Rendering guide
  /// recommends, so it adds no meshes or materials. It draws only in the main pass, not in
  /// shadow, reflection or other passes. The lines are in its parent's coordinates when it has
  /// no position, rotation or scale of its own, which is how ShowModelAxes adds it. Its Width,
  /// Height and Depth are set to the lines' extent and its Position to their middle, so
  /// anything that culls by an object's size sees the whole set.</para>
  /// <para>The object is not stored in .fmx files and ignores the mouse. Use it from the main
  /// thread only.</para></remarks>
  TModelAxes = class(TDummy)
  private
    FLo: TPoint3D;
    FHi: TPoint3D;
    FCentre: TPoint3D;
    FXColor: TAlphaColor;
    FYColor: TAlphaColor;
    FZColor: TAlphaColor;
    FLineWidth: Single;
    FOnTop: Boolean;
    FHasExtent: Boolean;
    procedure DrawLines;
    procedure SetXColor(const Value: TAlphaColor);
    procedure SetYColor(const Value: TAlphaColor);
    procedure SetZColor(const Value: TAlphaColor);
    procedure SetLineWidth(const Value: Single);
    procedure SetOnTop(const Value: Boolean);
  protected
    //** @abstract(Draws the three lines in the main pass.)
    //**
    //** Does nothing before SetExtent is called, or in any pass other than the main one.
    //** Sets the context matrix to this object's AbsoluteMatrix for the drawing and restores
    //** the previous matrix, line state and depth test afterwards, even if drawing fails.
    /// <summary>Draws the three lines in the main pass.</summary>
    /// <remarks>Does nothing before <see cref="SetExtent"/> is called, or in any pass other
    /// than the main one. Sets the context matrix to this object's AbsoluteMatrix for the
    /// drawing and restores the previous matrix, line state and depth test afterwards, even if
    /// drawing fails.</remarks>
    procedure Render; override;
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

    //** @abstract(Sets where the three lines cross and how far each reaches.)
    //**
    //** Each line passes through ACentre parallel to one axis and runs from the low corner's
    //** value to the high corner's value on that axis, widened if need be to reach ACentre.
    //** All points are in the parent's coordinates. Redraws the axes.
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
    /// ACentre. All points are in the parent's coordinates. Redraws the axes.</remarks>
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
    //** Values above 1 work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always draw
    //** 1 pixel. Values below 1 count as 1.
    /// <summary>Line width in screen pixels, whatever the distance; 1 by default.</summary>
    /// <remarks>Values above 1 work on desktop OpenGL only; Vulkan, Metal and OpenGL ES always
    /// draw 1 pixel. Values below 1 count as 1.</remarks>
    property LineWidth: Single read FLineWidth write SetLineWidth;
    //** @abstract(Whether the lines are drawn over everything; True by default.)
    //**
    //** True turns depth testing off while the lines are drawn, so the model and anything in
    //** front cannot hide them. False draws them like any other geometry, so they disappear
    //** where they pass inside a solid model.
    /// <summary>Whether the lines are drawn over everything; True by default.</summary>
    /// <remarks>True turns depth testing off while the lines are drawn, so the model and
    /// anything in front cannot hide them. False draws them like any other geometry, so they
    /// disappear where they pass inside a solid model.</remarks>
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
//** and are freed with it. They are sized for the box at the time of the call. Call from the
//** main thread only.
//**
//** @param(AModel The model to draw axes on. Nothing happens if it is nil.)
//**
//** @param(ALineWidth Line width in screen pixels. Values above 1 work on desktop OpenGL
//** only.)
//**
//** @param(AOnTop True to draw the lines over everything, so the model cannot hide them;
//** False to let the model hide the parts inside it.)
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
/// scale, and are freed with it. They are sized for the box at the time of the call. Call from
/// the main thread only.</para></remarks>
/// <param name="AModel">The model to draw axes on. Nothing happens if it is nil.</param>
/// <param name="ALineWidth">Line width in screen pixels. Values above 1 work on desktop OpenGL
/// only.</param>
/// <param name="AOnTop">True to draw the lines over everything, so the model cannot hide them;
/// False to let the model hide the parts inside it.</param>
/// <returns>The new axes, owned by AModel; or nil, with nothing added, if AModel is nil or its
/// bounding box is empty.</returns>
/// <seealso cref="HideModelAxes"/>
/// <seealso cref="FindModelAxes"/>
function ShowModelAxes(const AModel: TGorillaModel; const ALineWidth: Single = 1;
  const AOnTop: Boolean = True): TModelAxes;

//** @abstract(Removes the axes ShowModelAxes added to AModel.)
//**
//** Frees the TModelAxes. Does nothing if AModel is nil or has no axes. Call from the main
//** thread only.
//**
//** @param(AModel The model to remove the axes from.)
//**
//** @seealso(ShowModelAxes)
/// <summary>Removes the axes ShowModelAxes added to AModel.</summary>
/// <remarks>Frees the TModelAxes. Does nothing if AModel is nil or has no axes. Call from the
/// main thread only.</remarks>
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

procedure TModelAxes.SetExtent(const ALow, AHigh, ACentre: TPoint3D);
var
  Mid: TPoint3D;
begin
  FLo := Point3D(Min(ALow.X, ACentre.X), Min(ALow.Y, ACentre.Y),
    Min(ALow.Z, ACentre.Z));
  FHi := Point3D(Max(AHigh.X, ACentre.X), Max(AHigh.Y, ACentre.Y),
    Max(AHigh.Z, ACentre.Z));

  // Sit in the middle of the lines, sized to them, so a size-based cull
  // never drops them; the lines are then drawn relative to this position
  Mid := (FLo + FHi) * 0.5;
  Position.Point := Mid;
  Width := Max(FHi.X - FLo.X, 0.001);
  Height := Max(FHi.Y - FLo.Y, 0.001);
  Depth := Max(FHi.Z - FLo.Z, 0.001);
  FLo := FLo - Mid;
  FHi := FHi - Mid;
  FCentre := ACentre - Mid;
  FHasExtent := True;
  Repaint;
end;

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

procedure TModelAxes.Render;
var
  Ctx: TGorillaContext;
  PrevMat: TMatrix3D;
  Wide: Boolean;
begin
  inherited;
  if not FHasExtent then
    Exit;

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
    if FOnTop then
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
      if FOnTop then
        Context.SetContextState(TContextState.csZTestOn);
    end;
  finally
    Context.SetMatrix(PrevMat);
  end;
end;

procedure TModelAxes.SetXColor(const Value: TAlphaColor);
begin
  FXColor := Value;
  Repaint;
end;

procedure TModelAxes.SetYColor(const Value: TAlphaColor);
begin
  FYColor := Value;
  Repaint;
end;

procedure TModelAxes.SetZColor(const Value: TAlphaColor);
begin
  FZColor := Value;
  Repaint;
end;

procedure TModelAxes.SetLineWidth(const Value: Single);
begin
  FLineWidth := Max(Value, 1);
  Repaint;
end;

procedure TModelAxes.SetOnTop(const Value: Boolean);
begin
  FOnTop := Value;
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
    Axes.Free;
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
  Result.SetExtent(Box.TopLeftNear, Box.BottomRightFar,
    AModel.RotationCenter.Point);
  Result.Parent := AModel;   // freed with the model
end;

end.
