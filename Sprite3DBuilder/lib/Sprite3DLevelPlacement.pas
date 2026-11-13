//** @abstract(Placing a piece on the level: what is dragged, where the pointer is on the
//** floor, where the piece snaps to, where it lands and how it falls, and the box shown while
//** it is dragged.)
//**
//** A piece is dragged from the Library as a TSprite3DPieceSpec: its name, file, key and
//** bounding box, in its own units, Y up. While it is over the level the box is drawn, by a
//** TSprite3DPlacementBox, where the piece would go; let go, the piece falls into place.
//**
//** The floor point under the pointer comes from a TSprite3DFloorMap: the map of the screen
//** onto the floor plane, a homography, solved from four floor points and where the camera
//** shows them. Any view the camera can give, perspective, orthographic or the oblique ones,
//** shows a plane through a projective map, so the four points are enough and the map is
//** exact, without the projection's own sums being needed here.
//**
//** All coordinates are the level's own: X and Z across the floor, Y up, the floor at
//** Y = 0. The unit knows nothing of the application; the box draws on the main thread, as
//** every FMX 3D control does.
unit Sprite3DLevelPlacement;

{
  Placing a piece on the level: what is dragged, where the pointer is on the
  floor, where the piece snaps to, where it lands and how it falls, and the
  box shown while it is dragged.

  A piece is dragged from the Library as a TSprite3DPieceSpec: its name,
  file, key and bounding box, in its own units, Y up. While it is over the
  level the box is drawn, by a TSprite3DPlacementBox, where the piece would
  go; let go, the piece falls into place.

  The floor point under the pointer comes from a TSprite3DFloorMap: the map
  of the screen onto the floor plane, a homography, solved from four floor
  points and where the camera shows them. Any view the camera can give,
  perspective, orthographic or the oblique ones, shows a plane through a
  projective map, so the four points are enough and the map is exact,
  without the projection's own sums being needed here.

  All coordinates are the level's own: X and Z across the floor, Y up, the
  floor at Y = 0. The unit knows nothing of the application; the box draws
  on the main thread, as every FMX 3D control does.
}

interface

uses
  System.SysUtils, System.Types, System.Math, System.Math.Vectors, FMX.Types3D,
  Sprite3DSweep;

type
  //** @abstract(A model dragged from the Library to the level.)
  TSprite3DPieceSpec = record
    //** @abstract(The model's name, for the Debug tab.)
    Name: String;
    //** @abstract(Its file, as a full path.)
    FileName: String;
    //** @abstract(Its key, the SHA-256 of its content, which names its copy if its textures
    //** had to be found or made.)
    Key: String;
    //** @abstract(The low corner of its bounding box, in its own coordinates and units, Y up.)
    BoxMin: TPoint3D;
    //** @abstract(The high corner of its bounding box; see BoxMin.)
    BoxMax: TPoint3D;
    //** @abstract(The name of the material variant it is placed as (Sprite3DModelVariants);
    //** empty for the model as made, its base.)
    VariantName: String;
    //** @abstract(Its bounding box, from BoxMin and BoxMax.)
    //**
    //** @returns(The box, in its own coordinates.)
    function Box: TBoundingBox;
    //** @abstract(Whether it has a box to place it by: one with some size, its corners in
    //** order.)
    //**
    //** @returns(True if it can be placed.)
    function HasBox: Boolean;
  end;

  //** @abstract(The map of the screen onto the floor plane: a 3 by 3 homography, taking a
  //** point in the view's pixels to the floor's X and Z.)
  TSprite3DFloorMap = record
  private
    //** @abstract(The homography, row by row; the last entry is 1.)
    FH: array[0..8] of Double;
  public
    //** @abstract(Solves the map from four points on the floor and where the view shows them.)
    //**
    //** @param(AScreen The four points in the view's pixels.)
    //**
    //** @param(AFloor The same four points on the floor, as X and Z (in the point's X and Y),
    //** no three of them in a line.)
    //**
    //** @param(AMap Set to the map.)
    //**
    //** @returns(False if there are not four of each or they give no map, as when three are
    //** in a line.)
    class function Solve(const AScreen, AFloor: array of TPointF;
      out AMap: TSprite3DFloorMap): Boolean; static;
    //** @abstract(The floor point a point of the view shows.)
    //**
    //** In perspective, a point above the horizon maps to a floor point behind the camera;
    //** check the answer by showing it again.
    //**
    //** @param(AScreen The point, in the view's pixels.)
    //**
    //** @param(AFloor Set to the floor's X and Z, in its X and Y.)
    //**
    //** @returns(False if the point maps to infinity, as on the horizon.)
    function Map(const AScreen: TPointF; out AFloor: TPointF): Boolean;
  end;

  //** @abstract(A box drawn as its 12 edges where a piece would go: the box shown while a piece
  //** is dragged over the level.)
  //**
  //** A TSprite3DBoxOutline that draws the box it is given, in its own coordinates, with its
  //** own matrix, on screen and in any grab alike, so it is placed by setting Position. Put
  //** it in the level, as a child of the level's root; it is not a model's child, so it
  //** counts in no model's bounds.
  TSprite3DPlacementBox = class(TSprite3DBoxOutline)
  private
    //** @abstract(The box drawn, in the outline's own coordinates.)
    FBox: TBoundingBox;
  protected
    //** @abstract(Box, with the outline's AbsoluteMatrix.)
    //**
    //** @param(ABox Set to Box.)
    //**
    //** @param(AMatrix Set to the outline's AbsoluteMatrix.)
    //**
    //** @returns(True unless Box has no size.)
    function GetOutline(out ABox: TBoundingBox; out AMatrix: TMatrix3D): Boolean; override;
  public
    //** @abstract(The box drawn, in the outline's own coordinates, such as a piece's
    //** bounding box with the outline at the piece's position.)
    property Box: TBoundingBox read FBox write FBox;
  end;

//** @abstract(Where a piece's origin goes across the floor, its footprint snapped to the
//** grid, for the floor point under the pointer.)
//**
//** The pointer is taken as the middle of the piece's footprint, then each way, X and Z, on
//** its own: a piece N cells across (its size over the grid's, rounded, at least 1) covers N
//** whole cells, so with N odd its middle goes to the middle of the cell under the pointer,
//** and with N even to the grid line nearest the pointer. A piece of a cell or less is so
//** centred in a cell; a wall two cells long lies along two.
//**
//** @param(AAt The floor point under the pointer, as X and Z.)
//**
//** @param(ABox The piece's bounding box, in its own coordinates.)
//**
//** @param(AGrid The grid's spacing; nothing is snapped if it is not above 0.)
//**
//** @returns(The piece's position, X and Z, as X and Y.)
function SnapPiecePosition(const AAt: TPointF; const ABox: TBoundingBox;
  const AGrid: Single): TPointF;

//** @abstract(The height a footprint lands at: the top of the highest box under it, or the
//** floor.)
//**
//** Boxes that only touch the footprint's edges are not under it: each must overlap it by
//** more than a hundredth of a cell each way.
//**
//** @param(AFootprint The footprint, across the floor: Left and Right in X, Top and Bottom
//** in Z.)
//**
//** @param(AOthers The boxes of the pieces already placed, in the level's coordinates.)
//**
//** @param(AGrid The grid's spacing, for the overlap needed.)
//**
//** @returns(The height, 0 for the floor; never below it.)
function LandingHeight(const AFootprint: TRectF; const AOthers: TArray<TBoundingBox>;
  const AGrid: Single): Single;

//** @abstract(How far a piece has fallen, under steady gravity from rest.)
//**
//** @param(AFrom The height it fell from.)
//**
//** @param(ATo The height it lands at, at or below AFrom.)
//**
//** @param(AGravity The pull, in units per second per second.)
//**
//** @param(ASeconds The time since it was let go.)
//**
//** @param(AY Set to its height now: never below ATo.)
//**
//** @returns(True once it has landed.)
function FallHeight(const AFrom, ATo, AGravity, ASeconds: Single; out AY: Single): Boolean;

//** @abstract(A box's footprint across the floor, moved by a position.)
//**
//** @param(ABox The box, in its own coordinates.)
//**
//** @param(APosition Where its origin is, in the level.)
//**
//** @returns(Left and Right in X, Top and Bottom in Z.)
function BoxFootprint(const ABox: TBoundingBox; const APosition: TPoint3D): TRectF;

//** @abstract(Where a line meets a box: the stretch of the line inside it.)
//**
//** The line runs through AFrom and ATo, and goes on past both; a point on it is
//** AFrom + T * (ATo - AFrom), so T is 0 at AFrom and 1 at ATo.
//**
//** @param(AFrom A point on the line, in the box's coordinates.)
//**
//** @param(ATo Another point on it.)
//**
//** @param(ABox The box.)
//**
//** @param(ANear Set to the T at which the line goes into the box.)
//**
//** @param(AFar Set to the T at which it comes out, at or above ANear.)
//**
//** @returns(True if the line meets the box; False if it misses, or AFrom and ATo are one
//** point.)
function LineThroughBox(const AFrom, ATo: TPoint3D; const ABox: TBoundingBox;
  out ANear, AFar: Single): Boolean;

implementation

{ TSprite3DPieceSpec }

function TSprite3DPieceSpec.Box: TBoundingBox;
begin
  Result := TBoundingBox.Create(BoxMin, BoxMax);
end;

function TSprite3DPieceSpec.HasBox: Boolean;
var
  Size: TPoint3D;
begin
  Size := BoxMax - BoxMin;
  Result := (Size.X >= 0) and (Size.Y >= 0) and (Size.Z >= 0) and
    ((Size.X > 0) or (Size.Y > 0) or (Size.Z > 0)) and
    not (IsNan(Size.X) or IsNan(Size.Y) or IsNan(Size.Z));
end;

{ TSprite3DFloorMap }

class function TSprite3DFloorMap.Solve(const AScreen, AFloor: array of TPointF;
  out AMap: TSprite3DFloorMap): Boolean;
var
  A: array[0..7, 0..8] of Double;
  X, Y, U, V, F, Best, T: Double;
  Row, Col, Pivot: Integer;
begin
  AMap := Default(TSprite3DFloorMap);
  Result := (Length(AScreen) = 4) and (Length(AFloor) = 4);
  if not Result then
    Exit;
  // Each pair gives two rows of the eight unknowns, the last entry being 1:
  //   U = (h0 X + h1 Y + h2) / (h6 X + h7 Y + 1)
  //   V = (h3 X + h4 Y + h5) / (h6 X + h7 Y + 1)
  // with X, Y on the screen and U, V on the floor; column 8 is the right side
  for var I := 0 to 3 do
  begin
    X := AScreen[I].X;
    Y := AScreen[I].Y;
    U := AFloor[I].X;
    V := AFloor[I].Y;
    Row := I * 2;
    A[Row, 0] := X; A[Row, 1] := Y; A[Row, 2] := 1;
    A[Row, 3] := 0; A[Row, 4] := 0; A[Row, 5] := 0;
    A[Row, 6] := -X * U; A[Row, 7] := -Y * U; A[Row, 8] := U;
    A[Row + 1, 0] := 0; A[Row + 1, 1] := 0; A[Row + 1, 2] := 0;
    A[Row + 1, 3] := X; A[Row + 1, 4] := Y; A[Row + 1, 5] := 1;
    A[Row + 1, 6] := -X * V; A[Row + 1, 7] := -Y * V; A[Row + 1, 8] := V;
  end;
  // Gaussian elimination with partial pivoting
  for Col := 0 to 7 do
  begin
    Pivot := Col;
    Best := Abs(A[Col, Col]);
    for Row := Col + 1 to 7 do
      if Abs(A[Row, Col]) > Best then
      begin
        Best := Abs(A[Row, Col]);
        Pivot := Row;
      end;
    if Best < 1E-12 then
      Exit(False);
    if Pivot <> Col then
      for var K := 0 to 8 do
      begin
        T := A[Col, K];
        A[Col, K] := A[Pivot, K];
        A[Pivot, K] := T;
      end;
    for Row := 0 to 7 do
      if Row <> Col then
      begin
        F := A[Row, Col] / A[Col, Col];
        if F <> 0 then
          for var K := Col to 8 do
            A[Row, K] := A[Row, K] - F * A[Col, K];
      end;
  end;
  for var I := 0 to 7 do
    AMap.FH[I] := A[I, 8] / A[I, I];
  AMap.FH[8] := 1;
end;

function TSprite3DFloorMap.Map(const AScreen: TPointF; out AFloor: TPointF): Boolean;
var
  W: Double;
begin
  AFloor := TPointF.Zero;
  W := FH[6] * AScreen.X + FH[7] * AScreen.Y + FH[8];
  Result := Abs(W) > 1E-12;
  if not Result then
    Exit;
  AFloor := TPointF.Create(
    (FH[0] * AScreen.X + FH[1] * AScreen.Y + FH[2]) / W,
    (FH[3] * AScreen.X + FH[4] * AScreen.Y + FH[5]) / W);
end;

{ TSprite3DPlacementBox }

function TSprite3DPlacementBox.GetOutline(out ABox: TBoundingBox;
  out AMatrix: TMatrix3D): Boolean;
var
  Size: TPoint3D;
begin
  ABox := FBox;
  AMatrix := AbsoluteMatrix;
  Size := FBox.BottomRightFar - FBox.TopLeftNear;
  Result := (Size.X > 0) or (Size.Y > 0) or (Size.Z > 0);
end;

{ Placing }

// The middle of a piece's footprint along one axis, snapped: see
// SnapPiecePosition
function SnapMiddle(const AAt, ASize, AGrid: Single): Single;
var
  Cells: Integer;
begin
  Cells := Max(1, Round(ASize / AGrid));
  if Odd(Cells) then
    Result := (Floor(AAt / AGrid) + 0.5) * AGrid
  else
    Result := Round(AAt / AGrid) * AGrid;
end;

function SnapPiecePosition(const AAt: TPointF; const ABox: TBoundingBox;
  const AGrid: Single): TPointF;
var
  MidX, MidZ: Single;
begin
  // Where the footprint's middle is, from the piece's origin
  MidX := (ABox.Left + ABox.Right) / 2;
  MidZ := (ABox.Near + ABox.Far) / 2;
  if AGrid <= 0 then
    Exit(TPointF.Create(AAt.X - MidX, AAt.Y - MidZ));
  Result := TPointF.Create(
    SnapMiddle(AAt.X, ABox.Right - ABox.Left, AGrid) - MidX,
    SnapMiddle(AAt.Y, ABox.Far - ABox.Near, AGrid) - MidZ);
end;

function LandingHeight(const AFootprint: TRectF; const AOthers: TArray<TBoundingBox>;
  const AGrid: Single): Single;
var
  Inset: Single;
begin
  Result := 0;
  Inset := Max(AGrid, 0) * 0.01;
  // TBoundingBox: Left and Right are X, Top and Bottom Y (low and high),
  // Near and Far Z; so a box's top, in the level, Y up, is its Bottom
  for var B in AOthers do
    if (AFootprint.Left < B.Right - Inset) and (AFootprint.Right > B.Left + Inset) and
      (AFootprint.Top < B.Far - Inset) and (AFootprint.Bottom > B.Near + Inset) then
      Result := Max(Result, B.Bottom);
end;

function FallHeight(const AFrom, ATo, AGravity, ASeconds: Single; out AY: Single): Boolean;
begin
  AY := AFrom - 0.5 * Max(AGravity, 0) * Sqr(Max(ASeconds, 0));
  Result := AY <= ATo;
  if Result then
    AY := ATo;
end;

function BoxFootprint(const ABox: TBoundingBox; const APosition: TPoint3D): TRectF;
begin
  Result := TRectF.Create(ABox.Left + APosition.X, ABox.Near + APosition.Z,
    ABox.Right + APosition.X, ABox.Far + APosition.Z);
end;

function LineThroughBox(const AFrom, ATo: TPoint3D; const ABox: TBoundingBox;
  out ANear, AFar: Single): Boolean;

  // One pair of faces: narrows ANear to AFar to where the line is between
  // them; False once nothing is left
  function Slab(const AStart, AStep, ALow, AHigh: Single): Boolean;
  var
    T1, T2: Single;
  begin
    if Abs(AStep) < 1E-9 then
      // Parallel to these faces: in or out all along
      Exit((AStart >= ALow) and (AStart <= AHigh));
    T1 := (ALow - AStart) / AStep;
    T2 := (AHigh - AStart) / AStep;
    if T1 > T2 then
    begin
      var T := T1;
      T1 := T2;
      T2 := T;
    end;
    ANear := Max(ANear, T1);
    AFar := Min(AFar, T2);
    Result := ANear <= AFar;
  end;

var
  Step: TPoint3D;
begin
  ANear := -MaxSingle;
  AFar := MaxSingle;
  Step := ATo - AFrom;
  if (Abs(Step.X) < 1E-9) and (Abs(Step.Y) < 1E-9) and (Abs(Step.Z) < 1E-9) then
    Exit(False);
  // TBoundingBox: Left and Right are X, Top and Bottom Y, Near and Far Z
  Result := Slab(AFrom.X, Step.X, ABox.Left, ABox.Right) and
    Slab(AFrom.Y, Step.Y, ABox.Top, ABox.Bottom) and
    Slab(AFrom.Z, Step.Z, ABox.Near, ABox.Far);
end;

end.
