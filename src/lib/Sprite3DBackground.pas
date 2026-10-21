//** @abstract(A background for a Gorilla3D view: none, a checker for transparency, a colour
//** or a gradient.)
//**
//** TSprite3DBackgroundSpec describes a background: its kind, its colours and the size of the
//** checker squares. TSprite3DBackground shows one behind a viewport. It is not part of the
//** 3D scene: it is an ordinary 2D control, a sibling placed directly behind the viewport and
//** covering the same area, and the viewport's Color is made fully transparent, so the
//** background shows wherever the scene draws nothing. This needs a Gorilla3D whose viewport
//** honours the alpha of its Color, as Gorilla3D 1.5.3 does.
//**
//** Being 2D, the background does not depend on the camera at all: it is the same in
//** perspective and orthographic projection, at any field of view or zoom, and it never
//** appears in off-screen grabs, which draw the scene into a frame buffer of their own. It is
//** painted from a bitmap, kept until the control's size, the display scale or the spec
//** changes. The checker is drawn at the display's own pixel size, one bitmap pixel to one
//** screen pixel, so its edges stay sharp. The gradient is drawn at no more than
//** MaxGradientPixels pixels along its longer side and stretched smoothly to fit, as a smooth
//** blend loses nothing by it. A Solid background needs no bitmap and is filled directly.
//**
//** The None kind, the default, hides the control and gives the viewport back the opaque
//** Color it had when the background was attached, so the view looks as it did before any
//** background existed. The Transparent kind shows a checker of two greys, the usual sign
//** that an image is transparent there. The squares are CheckerSize logical pixels on screen,
//** counted from the view's top-left corner, which is light.
//**
//** The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs the same
//** background: transparent for None and for Transparent, as the checker stands for, and
//** the colour or gradient otherwise. NewBitmap paints a spec into a bitmap of any size for
//** such uses.
//**
//** @preformatted(
//** ViewportLayout @(or whatever holds the viewport@)
//** |-- TSprite3DBackground   2D, behind; same area as the viewport
//** `-- TGorillaViewport      Color fully transparent unless the kind is None
//** )
unit Sprite3DBackground;

{
  A background for a Gorilla3D view: none, a checker for transparency, a
  colour or a gradient.

  TSprite3DBackgroundSpec describes a background: its kind, its colours and
  the size of the checker squares. TSprite3DBackground shows one behind a
  viewport. It is not part of the 3D scene: it is an ordinary 2D control, a
  sibling placed directly behind the viewport and covering the same area,
  and the viewport's Color is made fully transparent, so the background
  shows wherever the scene draws nothing. This needs a Gorilla3D whose
  viewport honours the alpha of its Color, as Gorilla3D 1.5.3 does.

  Being 2D, the background does not depend on the camera at all: it is the
  same in perspective and orthographic projection, at any field of view or
  zoom, and it never appears in off-screen grabs, which draw the scene into
  a frame buffer of their own. It is painted from a bitmap, kept until the
  control's size, the display scale or the spec changes. The checker is
  drawn at the display's own pixel size, one bitmap pixel to one screen
  pixel, so its edges stay sharp. The gradient is drawn at no more than
  MaxGradientPixels pixels along its longer side and stretched smoothly to
  fit, as a smooth blend loses nothing by it. A Solid background needs no
  bitmap and is filled directly.

  The None kind, the default, hides the control and gives the viewport back
  the opaque Color it had when the background was attached, so the view
  looks as it did before any background existed. The Transparent kind shows
  a checker of two greys, the usual sign that an image is transparent there.
  The squares are CheckerSize logical pixels on screen, counted from the
  view's top-left corner, which is light.

  The same spec is meant for TSprite3DOffscreen.Backdrop, which gives grabs
  the same background: transparent for None and for Transparent, as the
  checker stands for, and the colour or gradient otherwise. NewBitmap paints
  a spec into a bitmap of any size for such uses.

    ViewportLayout (or whatever holds the viewport)
    |-- TSprite3DBackground   2D, behind; same area as the viewport
    `-- TGorillaViewport      Color fully transparent unless the kind is None
}

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Types,
  FMX.Types, FMX.Controls, FMX.Graphics, Gorilla.Viewport;

type
  {$SCOPEDENUMS ON}
  //** @abstract(What a background shows.)
  /// <summary>What a background shows.</summary>
  TSprite3DBackgroundKind = (
    //** @abstract(No background is drawn: the viewport's own opaque colour shows, and grabs
    //** are transparent. The default.)
    /// <summary>No background is drawn: the viewport's own opaque colour shows, and grabs
    /// are transparent. The default.</summary>
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
    //** @abstract(Paints the background into a new bitmap of the given size.)
    //**
    //** Every pixel is painted, top row first: Solid in Colour, Gradient as GradientAtPoint
    //** gives at each pixel's centre, Transparent as the checker, with squares of CheckerSize
    //** times APixelsPerUnit pixels from a light one at the top-left, and None fully
    //** transparent. Every colour but None's is opaque. Rows that repeat an earlier row are
    //** copied rather than painted again, so a checker or a left-to-right gradient is cheap at
    //** any size; a top-to-bottom or diagonal gradient is painted pixel by pixel. May be
    //** called from any thread that may use TBitmap, which on most platforms is the main
    //** thread only.
    //**
    //** @param(AWidth The bitmap's width in pixels; at least 1 is used.)
    //**
    //** @param(AHeight The bitmap's height in pixels; at least 1 is used.)
    //**
    //** @param(APixelsPerUnit Bitmap pixels per logical pixel, such as the display scale, for
    //** the checker's square size; 1 for a grab. Values below 0.01 count as 0.01.)
    //**
    //** @returns(The bitmap, owned by the caller, who must free it.)
    //**
    //** @raises(Exception if the bitmap cannot be made or mapped for writing.)
    /// <summary>Paints the background into a new bitmap of the given size.</summary>
    /// <remarks>Every pixel is painted, top row first: Solid in Colour, Gradient as
    /// GradientAtPoint gives at each pixel's centre, Transparent as the checker, with squares
    /// of CheckerSize times APixelsPerUnit pixels from a light one at the top-left, and None
    /// fully transparent. Every colour but None's is opaque. Rows that repeat an earlier row
    /// are copied rather than painted again, so a checker or a left-to-right gradient is cheap
    /// at any size; a top-to-bottom or diagonal gradient is painted pixel by pixel. May be
    /// called from any thread that may use TBitmap, which on most platforms is the main
    /// thread only.</remarks>
    /// <param name="AWidth">The bitmap's width in pixels; at least 1 is used.</param>
    /// <param name="AHeight">The bitmap's height in pixels; at least 1 is used.</param>
    /// <param name="APixelsPerUnit">Bitmap pixels per logical pixel, such as the display
    /// scale, for the checker's square size; 1 for a grab. Values below 0.01 count as
    /// 0.01.</param>
    /// <returns>The bitmap, owned by the caller, who must free it.</returns>
    /// <exception cref="System.SysUtils|Exception">The bitmap cannot be made or mapped for
    /// writing.</exception>
    function NewBitmap(const AWidth, AHeight: Integer;
      const APixelsPerUnit: Single): TBitmap;
  end;

  //** @abstract(Shows a background behind a viewport, as a 2D control.)
  //**
  //** Create it and call AttachTo with the viewport. It becomes the viewport's sibling,
  //** directly behind it, with the same alignment and margins, so it covers the same area;
  //** if the viewport is not aligned, it copies the viewport's bounds once, and does not
  //** follow later moves. It makes the viewport's Color fully transparent while it has
  //** something to show. It takes no mouse or touch input and is never stored. Set Spec to
  //** change what it shows. For the main thread only.
  /// <summary>Shows a background behind a viewport, as a 2D control.</summary>
  /// <remarks>Create it and call AttachTo with the viewport. It becomes the viewport's
  /// sibling, directly behind it, with the same alignment and margins, so it covers the same
  /// area; if the viewport is not aligned, it copies the viewport's bounds once, and does not
  /// follow later moves. It makes the viewport's Color fully transparent while it has
  /// something to show. It takes no mouse or touch input and is never stored. Set Spec to
  /// change what it shows. For the main thread only.</remarks>
  TSprite3DBackground = class(TControl)
  private
    FViewport: TGorillaViewport;
    FOpaqueColour: TAlphaColor;   // the viewport's Color, put back for None
    FSpec: TSprite3DBackgroundSpec;
    FBitmap: TBitmap;             // the checker or gradient as last painted
    FBitmapValid: Boolean;
    FBitmapWidth: Integer;        // the pixel size FBitmap was made for
    FBitmapHeight: Integer;
    procedure UpdateViewport;
    procedure InvalidateBitmap;
    procedure SetSpec(const Value: TSprite3DBackgroundSpec);
  protected
    //** @abstract(Paints the background over the control's whole area.)
    /// <summary>Paints the background over the control's whole area.</summary>
    procedure Paint; override;
    //** @abstract(Forgets the viewport when it is freed.)
    //**
    //** @param(AComponent The component being inserted or removed.)
    //**
    //** @param(Operation Whether it is being inserted or removed.)
    /// <summary>Forgets the viewport when it is freed.</summary>
    /// <param name="AComponent">The component being inserted or removed.</param>
    /// <param name="Operation">Whether it is being inserted or removed.</param>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    //** @abstract(The most pixels a gradient's bitmap has along its longer side.)
    //**
    //** A larger view stretches the bitmap smoothly to fit; a smooth blend loses nothing by
    //** it, and the bitmap is quick to remake while the window is resized.
    /// <summary>The most pixels a gradient's bitmap has along its longer side.</summary>
    /// <remarks>A larger view stretches the bitmap smoothly to fit; a smooth blend loses
    /// nothing by it, and the bitmap is quick to remake while the window is
    /// resized.</remarks>
    const MaxGradientPixels = 512;
  public
    //** @abstract(Creates the background with the default spec, not yet attached.)
    //**
    //** @param(AOwner The owner, which frees it; nil is usual, as its parent frees it once
    //** attached.)
    /// <summary>Creates the background with the default spec, not yet attached.</summary>
    /// <param name="AOwner">The owner, which frees it; nil is usual, as its parent frees it
    /// once attached.</param>
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Frees the background and its bitmap.)
    //**
    //** The viewport, if it still exists, keeps whatever Color it has at the time.
    /// <summary>Frees the background and its bitmap.</summary>
    /// <remarks>The viewport, if it still exists, keeps whatever Color it has at the
    /// time.</remarks>
    destructor Destroy; override;
    //** @abstract(Puts the background behind AViewport.)
    //**
    //** Makes it a child of the viewport's parent, or of its owner if it has no parent yet,
    //** placed just before the viewport so it is painted first. It takes the viewport's Align
    //** and Margins, or its bounds if it is not aligned, so set the viewport's alignment
    //** first. The viewport's Color at this moment is kept as the colour shown for None; if
    //** it is already fully transparent, black is kept instead. Then the viewport's Color is
    //** set for the present spec. Call it once.
    //**
    //** @param(AViewport The viewport to sit behind.)
    //**
    //** @raises(EArgumentNilException if AViewport is nil.)
    /// <summary>Puts the background behind AViewport.</summary>
    /// <remarks>Makes it a child of the viewport's parent, or of its owner if it has no parent
    /// yet, placed just before the viewport so it is painted first. It takes the viewport's
    /// Align and Margins, or its bounds if it is not aligned, so set the viewport's alignment
    /// first. The viewport's Color at this moment is kept as the colour shown for None; if it
    /// is already fully transparent, black is kept instead. Then the viewport's Color is set
    /// for the present spec. Call it once.</remarks>
    /// <param name="AViewport">The viewport to sit behind.</param>
    /// <exception cref="System.SysUtils|EArgumentNilException">AViewport is nil.</exception>
    procedure AttachTo(const AViewport: TGorillaViewport);
    //** @abstract(What the background shows; setting it repaints it.)
    //**
    //** Setting it also sets the viewport's Color: fully transparent for every kind but None,
    //** which hides this control and puts back the viewport's opaque Color.
    /// <summary>What the background shows; setting it repaints it.</summary>
    /// <remarks>Setting it also sets the viewport's Color: fully transparent for every kind
    /// but None, which hides this control and puts back the viewport's opaque
    /// Color.</remarks>
    property Spec: TSprite3DBackgroundSpec read FSpec write SetSpec;
  end;

implementation

uses
  System.Math;

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

// Each row has a key: rows with the same key are the same pixels, so only
// the first of them is painted and the rest are copied from it. -1 means a
// row like no other.
function TSprite3DBackgroundSpec.NewBitmap(const AWidth, AHeight: Integer;
  const APixelsPerUnit: Single): TBitmap;
var
  W, H, X, Y, Key, RowBytes: Integer;
  Data: TBitmapData;
  Side, DX, DY, Len: Single;
  FirstRow: array[0..1] of Integer;   // the first row painted for each key

  function RowKey(const ARow: Integer): Integer;
  begin
    case Kind of
      TSprite3DBackgroundKind.Transparent:
        Result := Floor(ARow / Side) and 1;
      TSprite3DBackgroundKind.Gradient:
        if GradientDirection = TSprite3DGradientDirection.LeftToRight then
          Result := 0
        else
          Result := -1;
    else
      Result := 0;   // None and Solid: every row the same
    end;
  end;

  function PixelAt(const AX, AY: Integer): TAlphaColor;
  begin
    case Kind of
      TSprite3DBackgroundKind.Solid:
        Result := Colour or TAlphaColors.Black;
      TSprite3DBackgroundKind.Gradient:
        if Len <= 0 then
          Result := GradientAt(0)
        else
          Result := GradientAt(((AX + 0.5 - W / 2) * DX + (AY + 0.5 - H / 2) * DY) / Len +
            0.5);
      TSprite3DBackgroundKind.Transparent:
        if Odd(Floor(AX / Side) + Floor(AY / Side)) then
          Result := CheckerDark or TAlphaColors.Black
        else
          Result := CheckerLight or TAlphaColors.Black;
    else
      Result := TAlphaColors.Null;
    end;
  end;

begin
  W := Max(AWidth, 1);
  H := Max(AHeight, 1);
  Side := Max(CheckerSize, 1) * Max(APixelsPerUnit, 0.01);
  GradientAxis(W, H, DX, DY, Len);
  FirstRow[0] := -1;
  FirstRow[1] := -1;
  Result := TBitmap.Create(W, H);
  try
    if not Result.Map(TMapAccess.Write, Data) then
      raise Exception.Create('The background bitmap could not be written.');
    try
      RowBytes := W * Data.BytesPerPixel;
      for Y := 0 to H - 1 do
      begin
        Key := RowKey(Y);
        if (Key >= 0) and (FirstRow[Key] >= 0) then
          Move(Data.GetScanline(FirstRow[Key])^, Data.GetScanline(Y)^, RowBytes)
        else
        begin
          for X := 0 to W - 1 do
            Data.SetPixel(X, Y, PixelAt(X, Y));
          if Key >= 0 then
            FirstRow[Key] := Y;
        end;
      end;
    finally
      Result.Unmap(Data);
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ TSprite3DBackground }

constructor TSprite3DBackground.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  Locked := True;
  HitTest := False;
  CanFocus := False;
  FOpaqueColour := TAlphaColors.Black;
  FSpec := TSprite3DBackgroundSpec.Default;
  Visible := False;   // None, until a spec says otherwise
end;

destructor TSprite3DBackground.Destroy;
begin
  if FViewport <> nil then
    FViewport.RemoveFreeNotification(Self);
  FBitmap.Free;
  inherited;
end;

procedure TSprite3DBackground.AttachTo(const AViewport: TGorillaViewport);
begin
  if AViewport = nil then
    raise EArgumentNilException.Create('TSprite3DBackground.AttachTo needs a viewport.');
  FViewport := AViewport;
  FViewport.FreeNotification(Self);
  if TAlphaColorRec(FViewport.Color).A = 0 then
    FOpaqueColour := TAlphaColors.Black
  else
    FOpaqueColour := FViewport.Color;
  if FViewport.Parent <> nil then
    Parent := FViewport.Parent
  else if FViewport.Owner is TFmxObject then
    Parent := TFmxObject(FViewport.Owner);
  // Painted first, so the viewport draws over it
  if (Parent <> nil) and (FViewport.Parent = Parent) then
    Index := FViewport.Index;
  Margins.Assign(FViewport.Margins);
  if FViewport.Align = TAlignLayout.None then
    BoundsRect := FViewport.BoundsRect
  else
    // Two controls with the same Client alignment share the same area
    Align := FViewport.Align;
  UpdateViewport;
end;

procedure TSprite3DBackground.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FViewport) then
    FViewport := nil;
end;

// Shows this control and makes the viewport see-through, or for None hides
// it and gives the viewport its opaque colour back. Only what differs is set.
procedure TSprite3DBackground.UpdateViewport;
var
  Show: Boolean;
  Colour: TAlphaColor;
begin
  Show := FSpec.Kind <> TSprite3DBackgroundKind.None;
  if Visible <> Show then
    Visible := Show;
  if FViewport = nil then
    Exit;
  if Show then
    Colour := TAlphaColors.Null
  else
    Colour := FOpaqueColour;
  if FViewport.Color <> Colour then
    FViewport.Color := Colour;
end;

procedure TSprite3DBackground.InvalidateBitmap;
begin
  FBitmapValid := False;
  Repaint;
end;

procedure TSprite3DBackground.SetSpec(const Value: TSprite3DBackgroundSpec);
begin
  FSpec := Value;
  FSpec.CheckerSize := Max(FSpec.CheckerSize, 1);
  UpdateViewport;
  InvalidateBitmap;
end;

// The bitmap is remade only when the spec, the size or the display scale
// has changed. The checker is one bitmap pixel per screen pixel, drawn
// without smoothing so its edges stay sharp; the gradient is at most
// MaxGradientPixels along its longer side, stretched smoothly.
procedure TSprite3DBackground.Paint;
var
  Scale, Shrink: Single;
  PixelW, PixelH, BitmapW, BitmapH: Integer;
  Gradient: Boolean;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;
  case FSpec.Kind of
    TSprite3DBackgroundKind.None:
      Exit;
    TSprite3DBackgroundKind.Solid:
      begin
        Canvas.Fill.Kind := TBrushKind.Solid;
        Canvas.Fill.Color := FSpec.Colour or TAlphaColors.Black;
        Canvas.FillRect(LocalRect, 0, 0, AllCorners, AbsoluteOpacity);
        Exit;
      end;
  end;
  Scale := Canvas.Scale;
  if Scale <= 0 then
    Scale := 1;
  PixelW := Max(Round(Width * Scale), 1);
  PixelH := Max(Round(Height * Scale), 1);
  Gradient := FSpec.Kind = TSprite3DBackgroundKind.Gradient;
  if Gradient then
  begin
    Shrink := Min(1.0, MaxGradientPixels / Max(PixelW, PixelH));
    BitmapW := Max(Round(PixelW * Shrink), 1);
    BitmapH := Max(Round(PixelH * Shrink), 1);
  end
  else
  begin
    BitmapW := PixelW;
    BitmapH := PixelH;
  end;
  if not FBitmapValid or (FBitmap = nil) or (FBitmapWidth <> BitmapW) or
    (FBitmapHeight <> BitmapH) then
  begin
    FreeAndNil(FBitmap);
    FBitmap := FSpec.NewBitmap(BitmapW, BitmapH, Scale);
    FBitmapWidth := BitmapW;
    FBitmapHeight := BitmapH;
    FBitmapValid := True;
  end;
  Canvas.DrawBitmap(FBitmap, TRectF.Create(0, 0, FBitmap.Width, FBitmap.Height), LocalRect,
    AbsoluteOpacity, not Gradient);
end;

end.
