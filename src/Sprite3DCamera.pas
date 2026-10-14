unit Sprite3DCamera;

{ TSprite3DCamera - a TCamera with an internal pivot chain:

    <your parent>                (e.g. TViewport3D / TForm3D / any TControl3D)
      └─ AzimuthPivot (TDummy)    rotates around Y  -> Azimuth
          └─ PolarPivot (TDummy)  rotates around X  -> PolarAngle
              └─ RollPivot (TDummy) rotates around Z -> Roll
                  └─ TSprite3DCamera  sits at (0, 0, -Distance), looking +Z
                                    at the pivot origin (= OrbitCenter)

  Angles are in degrees.
  PolarAngle is an elevation and is NOT clamped: 0 = equator, +90 = above
  the centre looking down, -90 = below looking up. Values past +/-90 carry
  the camera over the pole and down the far side (upside down), and so on
  for any value. FMX's up is -Y.

  Orientation
  -----------
  The three angles are a view of one orientation quaternion
      Q = Qy(Azimuth) * Qx(-PolarAngle) * Qz(Roll)
  in the rig parent's coordinate space. Reading `Orientation` builds Q
  from the angles; `SetOrientation` decomposes any quaternion back into
  the three angles and pushes them to the pivots. The decomposition:
    - picks, of the two equivalent angle triples, the one nearest the
      current angles, so the values change continuously and the polar
      angle can run past +/-90 instead of snapping back;
    - at the exact poles (where Azimuth and Roll spin about the same axis)
      keeps the current Azimuth and puts the remaining twist in Roll,
      so nothing jumps.

  LookAt
  ------
  LookAt keeps the camera where it is and turns it to face a point. The
  turn is the shortest-arc quaternion from the current view direction to
  the new one. No world-up vector is involved, so there is nothing to
  become parallel to the view direction: it works looking straight up or
  down and never flips. A 180-degree turn pivots about the camera's own
  up axis. The point becomes the new OrbitCenter, and Distance is set to
  the camera's distance from it, so orbiting continues around that point.

  Modes:
    lmMinimalTwist (default) - pure shortest-arc turn; the camera keeps as
      much of its current "up" as possible. Repeated LookAts can build up
      some roll, as any free-flying camera does.
    lmKeepRoll - same view direction, but Roll is kept at its current
      value, keeping the horizon as it was. Still pole-safe: at the exact
      poles Azimuth is held rather than recomputed.

  Usage:
    Cam := TSprite3DCamera.Create(Self);
    Cam.Rig.Parent := Viewport3D1;   // attach the whole chain, NOT Cam.Parent
    Viewport3D1.Camera := Cam;
    Viewport3D1.UsingDesignCamera := False;

    Cam.LookAt(Point3D(2, 0, 3));    // point in the rig parent's space

  FitToBounds
  -----------
  FitToBounds(Box) frames a box so it fills as much of the viewport as
  possible while staying fully visible however the box is rotated about
  its centre (and whatever the camera's Azimuth / PolarAngle / Roll).
  The set of all rotations of a box is exactly its circumscribed sphere
  (centre = box centre, radius = half the space diagonal), so that sphere
  is what gets fitted - it is the tightest bound that is safe for every
  rotation, because some rotation always brings a corner onto it.

    - The orbit centre moves to the box centre; angles are untouched.
    - Perspective: the sphere is made tangent to the narrower pair of
      frustum planes. The half-angles are read from the camera's own
      GetProjectionMatrix for the viewport's size, so the FOV convention
      (vertical / horizontal) and aspect ratio come from Gorilla itself.
      With projection scale s on the narrower axis (s = 1 / tan(half)),
        Distance = R / sin(half) = R * Sqrt(1 + s*s)
    - Orthographic / isometric: size does not depend on distance, so
      OrthoHeight (and OrthoWidth if you set one) is sized so 2R fits the
      narrower side. Distance is set to 2R, putting the camera outside the
      sphere so the near plane cannot cut into it.
    - AMargin adds padding as a fraction of the radius (0.1 = 10%).

  Coordinate spaces matter: FitToBounds(Box) expects the box in the rig
  parent's (scene) space. A model's own bounds are in its LOCAL space,
  usually centred on the mesh origin; if the model has been moved (say
  lifted to stand on a floor) or scaled, using them directly aims at the
  wrong point. Pass the object too - FitToBounds(Box, Model) - and the
  box's corners are carried through the model's full transform first;
  the centre and radius are then measured in scene space, so position,
  rotation and (even non-uniform) scale are all accounted for.

  The viewport is found by walking up from the rig to the first
  TGorillaViewport.
}

interface

uses
  System.Classes, System.Math, System.Math.Vectors,
  FMX.Types, FMX.Types3D, FMX.Controls3D, FMX.Objects3D, FMX.Viewport3D,
  Gorilla.Camera, Gorilla.Viewport, Gorilla.Model;

type
  { Unit quaternion, Hamilton convention, right-hand rule on raw
    coordinates. Q1 * Q2 means "apply Q2 first, then Q1". }
  TQuat = record
    W, X, Y, Z: Double;
    class function Create(const AW, AX, AY, AZ: Double): TQuat; static;
    class function Identity: TQuat; static;
    class function AxisAngle(const Axis: TPoint3D; const Radians: Double): TQuat; static;
    { Shortest rotation taking unit vector AFrom onto unit vector ATo.
      For opposite vectors, rotates 180 degrees about AFallbackAxis, which
      must be perpendicular to AFrom. }
    class function ShortestArc(const AFrom, ATo, AFallbackAxis: TPoint3D): TQuat; static;
    class function Slerp(const A, B: TQuat; const T: Double): TQuat; static;
    class operator Multiply(const A, B: TQuat): TQuat;
    function Conjugate: TQuat;
    function Normalized: TQuat;
    function Rotate(const V: TPoint3D): TPoint3D;
  end;

  TLookAtMode = (lmMinimalTwist, lmKeepRoll);

  TSprite3DCamera = class(TGorillaCamera)
  private
    class var FFmxSign: Integer;
    class function FmxSign: Integer; static;
  private
    FAzimuthPivot: TDummy;
    FPolarPivot: TDummy;
    FRollPivot: TDummy;
    FAzimuth: Single;
    FPolarAngle: Single;
    FRoll: Single;
    FDistance: Single;
    function CreatePivot(const AParent: TFmxObject): TDummy;
    function GetOrbitCenter: TPosition3D;
    function GetOrientation: TQuat;
    procedure SetAzimuth(const Value: Single);
    procedure SetPolarAngle(const Value: Single);
    procedure SetRoll(const Value: Single);
    procedure SetDistance(const Value: Single);
    procedure UpdatePivots;
    procedure UpdateDistance;
    procedure ApplyOrientation(const Q: TQuat; const KeepRoll: Boolean);
    function FitSphere(const ACenter: TPoint3D; ARadius: Single;
      const AViewWidth, AViewHeight, AMargin: Single): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Turn the camera, from where it stands, to face APoint (given in the
      rig parent's space). Pole-safe and flip-free; see unit header. }
    procedure LookAt(const APoint: TPoint3D;
      const AMode: TLookAtMode = lmMinimalTwist);

    { Set the orientation directly (rig parent space). The angles are
      re-derived continuously from it. }
    procedure SetOrientation(const Q: TQuat);

    { Incremental helpers, e.g. from mouse drag / wheel }
    procedure Orbit(const DeltaAzimuth, DeltaPolar: Single);
    procedure Zoom(const Factor: Single);
    { Move the orbit centre without changing the angles (pans the view) }
    procedure MoveCenterTo(const APoint: TPoint3D);

    { Camera position in the rig parent's space }
    function CameraPosition: TPoint3D;

    { The TViewport3D (e.g. TGorillaViewport) the rig lives in, or nil }
    function FindViewport: TViewport3D;

    { Frame ABox (rig parent space) as large as possible in the viewport,
      safe for any rotation of the box about its centre. Re-centres the
      orbit on the box. Returns False (and changes nothing) if there is
      no viewport with a usable size. See unit header. }
    function FitToBounds(const ABox: TBoundingBox;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for a explicit model }
    function FitToBounds(const AModel: TGorillaModel;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for an explicit view size (e.g. before the viewport is shown) }
    function FitToBounds(const ABox: TBoundingBox; const AViewWidth,
      AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;
    { ABox is in ASpace's LOCAL coordinates (e.g. a model's mesh bounds).
      It is carried through ASpace's position, rotation and scale into
      the rig parent's space before fitting. Use this whenever the box
      comes from the object itself rather than from the scene. }
    function FitToBounds(const ABox: TBoundingBox; const ASpace: TControl3D;
      const AMargin: Single = 0): Boolean; overload;

    { Root of the chain - set Rig.Parent to place the camera in a scene }
    property Rig: TDummy read FAzimuthPivot;
    property AzimuthPivot: TDummy read FAzimuthPivot;
    property PolarPivot: TDummy read FPolarPivot;
    property RollPivot: TDummy read FRollPivot;

    { Orbit centre = root pivot position, in the rig parent's space.
      (Named so as not to clash with TCamera.Target, which should be
      left nil on this camera.) }
    property OrbitCenter: TPosition3D read GetOrbitCenter;
    property Orientation: TQuat read GetOrientation write SetOrientation;
  published
    property Azimuth: Single read FAzimuth write SetAzimuth;
    property PolarAngle: Single read FPolarAngle write SetPolarAngle;
    property Roll: Single read FRoll write SetRoll;
    property Distance: Single read FDistance write SetDistance;
  end;

implementation

const
  EPS = 1E-6;

{ Shift angle A (radians) by whole turns so it lies nearest to Ref }
function NearestAngle(const A, Ref: Double): Double;
begin
  Result := A + 2 * Pi * Round((Ref - A) / (2 * Pi));
end;

{ TQuat }

class function TQuat.Create(const AW, AX, AY, AZ: Double): TQuat;
begin
  Result.W := AW;
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

class function TQuat.Identity: TQuat;
begin
  Result := TQuat.Create(1, 0, 0, 0);
end;

class function TQuat.AxisAngle(const Axis: TPoint3D; const Radians: Double): TQuat;
var
  N: TPoint3D;
  S: Double;
begin
  N := Axis.Normalize;
  S := Sin(Radians / 2);
  Result := TQuat.Create(Cos(Radians / 2), N.X * S, N.Y * S, N.Z * S);
end;

class function TQuat.ShortestArc(const AFrom, ATo, AFallbackAxis: TPoint3D): TQuat;
var
  D: Double;
  C, Ax: TPoint3D;
begin
  D := AFrom.DotProduct(ATo);
  if D < -1 + EPS then
  begin
    // Opposite directions: any perpendicular axis works; use the given one
    Ax := AFallbackAxis.Normalize;
    Result := TQuat.Create(0, Ax.X, Ax.Y, Ax.Z);
  end
  else
  begin
    C := AFrom.CrossProduct(ATo);
    Result := TQuat.Create(1 + D, C.X, C.Y, C.Z).Normalized;
  end;
end;

class function TQuat.Slerp(const A, B: TQuat; const T: Double): TQuat;
var
  BB: TQuat;
  CosT, Theta, SinT, WA, WB: Double;
begin
  BB := B;
  CosT := A.W * B.W + A.X * B.X + A.Y * B.Y + A.Z * B.Z;
  if CosT < 0 then
  begin
    // Take the short way round
    BB := TQuat.Create(-B.W, -B.X, -B.Y, -B.Z);
    CosT := -CosT;
  end;
  if CosT > 1 - EPS then
  begin
    WA := 1 - T;
    WB := T;
  end
  else
  begin
    Theta := ArcCos(CosT);
    SinT := Sin(Theta);
    WA := Sin((1 - T) * Theta) / SinT;
    WB := Sin(T * Theta) / SinT;
  end;
  Result := TQuat.Create(WA * A.W + WB * BB.W, WA * A.X + WB * BB.X,
    WA * A.Y + WB * BB.Y, WA * A.Z + WB * BB.Z).Normalized;
end;

class operator TQuat.Multiply(const A, B: TQuat): TQuat;
begin
  Result.W := A.W * B.W - A.X * B.X - A.Y * B.Y - A.Z * B.Z;
  Result.X := A.W * B.X + A.X * B.W + A.Y * B.Z - A.Z * B.Y;
  Result.Y := A.W * B.Y - A.X * B.Z + A.Y * B.W + A.Z * B.X;
  Result.Z := A.W * B.Z + A.X * B.Y - A.Y * B.X + A.Z * B.W;
end;

function TQuat.Conjugate: TQuat;
begin
  Result := TQuat.Create(W, -X, -Y, -Z);
end;

function TQuat.Normalized: TQuat;
var
  L: Double;
begin
  L := Sqrt(W * W + X * X + Y * Y + Z * Z);
  if L < EPS then
    Exit(TQuat.Identity);
  Result := TQuat.Create(W / L, X / L, Y / L, Z / L);
end;

function TQuat.Rotate(const V: TPoint3D): TPoint3D;
var
  TX, TY, TZ: Double;
begin
  // v' = v + 2w(u x v) + 2u x (u x v), with u = (X, Y, Z)
  TX := 2 * (Y * V.Z - Z * V.Y);
  TY := 2 * (Z * V.X - X * V.Z);
  TZ := 2 * (X * V.Y - Y * V.X);
  Result.X := V.X + W * TX + (Y * TZ - Z * TY);
  Result.Y := V.Y + W * TY + (Z * TX - X * TZ);
  Result.Z := V.Z + W * TZ + (X * TY - Y * TX);
end;

{ TSprite3DCamera }

class function TSprite3DCamera.FmxSign: Integer;
var
  D: TDummy;
begin
  // FMX's rotation sense relative to the right-hand rule is checked once,
  // against FMX itself: rotate +90 about Z and see where +X lands. FMX
  // uses row vectors, so the image of +X is the first matrix row. All
  // quaternion maths above is right-handed; this sign maps it onto the
  // pivots' RotationAngle values.
  if FFmxSign = 0 then
  begin
    D := TDummy.Create(nil);
    try
      D.RotationAngle.Point := Point3D(0, 0, 90);
      if D.AbsoluteMatrix.m12 >= 0 then
        FFmxSign := 1
      else
        FFmxSign := -1;
    finally
      D.Free;
    end;
  end;
  Result := FFmxSign;
end;

constructor TSprite3DCamera.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDistance   := 10;
  FAzimuth    := 0;
  FPolarAngle := 0;
  FRoll       := 0;

  // Build the chain: Azimuth -> Polar -> Roll -> Camera
  FAzimuthPivot := CreatePivot(nil);
  if AOwner is TGorillaViewport then
    FAzimuthPivot.Parent := TGorillaViewport(AOwner);

  FPolarPivot   := CreatePivot(FAzimuthPivot);
  FRollPivot    := CreatePivot(FPolarPivot);
  Parent := FRollPivot;

  // The camera itself carries no rotation; the pivots do all the work
  RotationAngle.Point := TPoint3D.Zero;

  UpdatePivots;
  UpdateDistance;
end;

function TSprite3DCamera.CreatePivot(const AParent: TFmxObject): TDummy;
begin
  // No owner: the pivots' lifetime is managed by the parent/child chain
  // and by this camera's destructor. Not stored, so they never end up
  // in a .fmx file.
  Result := TDummy.Create(nil);
  Result.Stored := False;
  Result.Locked := True;
  Result.HitTest := False;
  Result.Parent := AParent;
end;

destructor TSprite3DCamera.Destroy;
begin
  // Two ways we can get here:
  //  1) The chain is being torn down (e.g. the viewport freed Rig, which
  //     frees its children down to us) - the pivots are already dying.
  //  2) We are freed directly (e.g. by our Owner) - we must free the
  //     chain ourselves, after detaching so it doesn't free us again.
  if (FRollPivot <> nil) and (Parent = FRollPivot)
    and not (csDestroying in FRollPivot.ComponentState) then
  begin
    Parent := nil;
    FAzimuthPivot.Free;  // also frees PolarPivot and RollPivot
  end;
  FAzimuthPivot := nil;
  FPolarPivot := nil;
  FRollPivot := nil;
  inherited;
end;

function TSprite3DCamera.GetOrbitCenter: TPosition3D;
begin
  Result := FAzimuthPivot.Position;
end;

function TSprite3DCamera.GetOrientation: TQuat;
begin
  Result :=
    TQuat.AxisAngle(Point3D(0, 1, 0), DegToRad(FAzimuth)) *
    TQuat.AxisAngle(Point3D(1, 0, 0), DegToRad(-FPolarAngle)) *
    TQuat.AxisAngle(Point3D(0, 0, 1), DegToRad(FRoll));
end;

procedure TSprite3DCamera.SetOrientation(const Q: TQuat);
begin
  ApplyOrientation(Q, False);
end;

procedure TSprite3DCamera.ApplyOrientation(const Q: TQuat; const KeepRoll: Boolean);
var
  N, QA, QB, Res: TQuat;
  M02, M12, M22, CosB, B0: Double;
  PrevA, PrevB, PrevC: Double;
  A: array[0..1] of Double;
  B: array[0..1] of Double;
  C: array[0..1] of Double;
  Cost: array[0..1] of Double;
  I, Best: Integer;
begin
  // Q = Qy(a) * Qx(b) * Qz(c), with b = -PolarAngle.
  // As a rotation matrix (column vectors), the third column is the view
  // direction:  (sin a cos b, -sin b, cos a cos b).
  N := Q.Normalized;
  M02 := 2 * (N.X * N.Z + N.W * N.Y);
  M12 := 2 * (N.Y * N.Z - N.W * N.X);
  M22 := 1 - 2 * (N.X * N.X + N.Y * N.Y);

  PrevA := DegToRad(FAzimuth);
  PrevB := DegToRad(-FPolarAngle);
  PrevC := DegToRad(FRoll);

  B0 := ArcSin(EnsureRange(-M12, -1, 1));
  CosB := Sqrt(M02 * M02 + M22 * M22);

  // Two angle triples give the same rotation:
  //   (a, b, c)  with cos b >= 0      and  (a + 180, 180 - b, c + 180)
  // Branch 1 is the second one; it is how the polar angle gets past +/-90.
  B[0] := B0;
  B[1] := Pi - B0;
  if CosB > EPS then
  begin
    A[0] := ArcTan2(M02, M22);
    A[1] := ArcTan2(-M02, -M22);
  end
  else
  begin
    // Exactly at a pole: azimuth and roll share an axis. Hold azimuth;
    // the residual twist is solved into roll below.
    A[0] := PrevA;
    A[1] := PrevA;
  end;

  for I := 0 to 1 do
  begin
    A[I] := NearestAngle(A[I], PrevA);
    B[I] := NearestAngle(B[I], PrevB);
    // Whatever is left after azimuth and polar is a pure Z rotation
    QA := TQuat.AxisAngle(Point3D(0, 1, 0), A[I]);
    QB := TQuat.AxisAngle(Point3D(1, 0, 0), B[I]);
    Res := QB.Conjugate * QA.Conjugate * N;
    C[I] := NearestAngle(2 * ArcTan2(Res.Z, Res.W), PrevC);
    Cost[I] := Abs(A[I] - PrevA) + Abs(B[I] - PrevB);
    if not KeepRoll then
      Cost[I] := Cost[I] + Abs(C[I] - PrevC);
  end;

  if Cost[1] < Cost[0] then
    Best := 1
  else
    Best := 0;

  // Azimuth is wrapped to [0, 360) by its setter; that is the same
  // rotation, so continuity is unaffected. Polar and roll are left
  // unwrapped so they move continuously.
  FAzimuth := RadToDeg(A[Best]);
  FAzimuth := FAzimuth - 360 * Floor(FAzimuth / 360);
  FPolarAngle := -RadToDeg(B[Best]);
  if not KeepRoll then
    FRoll := RadToDeg(C[Best]);
  // With KeepRoll the view direction is still exact: it depends only on
  // azimuth and polar, never on roll.

  UpdatePivots;
end;

function TSprite3DCamera.CameraPosition: TPoint3D;
begin
  Result := FAzimuthPivot.Position.Point +
    GetOrientation.Rotate(Point3D(0, 0, -FDistance));
end;

function TSprite3DCamera.FindViewport: TViewport3D;
var
  P: TFmxObject;
begin
  P := FAzimuthPivot.Parent;
  while (P <> nil) and not (P is TGorillaViewport) do
    P := P.Parent;
  Result := TViewport3D(P);
end;

function TSprite3DCamera.FitToBounds(const ABox: TBoundingBox;
  const AMargin: Single): Boolean;
var
  VP: TViewport3D;
begin
  VP := FindViewport;
  Result := (VP <> nil) and
    FitToBounds(ABox, VP.Width, VP.Height, AMargin);
end;

function TSprite3DCamera.FitToBounds(const ABox: TBoundingBox;
  const AViewWidth, AViewHeight: Single; const AMargin: Single): Boolean;
begin
  // Circumscribed sphere = union of every rotation of the box
  Result := FitSphere((ABox.TopLeftNear + ABox.BottomRightFar) * 0.5,
    (ABox.BottomRightFar - ABox.TopLeftNear).Length * 0.5,
    AViewWidth, AViewHeight, AMargin);
end;

function TSprite3DCamera.FitToBounds(const AModel: TGorillaModel;
  const AMargin: Single): Boolean;
begin
  if Assigned(AModel) then
    Result := FitToBounds(AModel.GetAbsoluteBoundingBox(),
      AModel, AMargin)
  else
    Result := False;
end;

function TSprite3DCamera.FitToBounds(const ABox: TBoundingBox;
  const ASpace: TControl3D; const AMargin: Single): Boolean;
var
  VP: TViewport3D;
  RigParent: TFmxObject;
  Corners: array[0..7] of TPoint3D;
  Center, P: TPoint3D;
  R: Single;
  I: Integer;

  // ASpace local -> rig parent space, via FMX absolute (viewport) space
  function ToRigSpace(const ALocal: TPoint3D): TPoint3D;
  begin
    if ASpace <> nil then
      Result := ASpace.LocalToAbsolute3D(ALocal)
    else
      Result := ALocal;
    if RigParent is TControl3D then
      Result := TControl3D(RigParent).AbsoluteToLocal3D(Result);
  end;

begin
  VP := FindViewport;
  Result := (VP <> nil) and (VP.Width > 0) and (VP.Height > 0);
  if not Result then
    Exit;
  RigParent := FAzimuthPivot.Parent;

  for I := 0 to 7 do
  begin
    P.X := IfThen(I and 1 = 0, ABox.Left,   ABox.Right);
    P.Y := IfThen(I and 2 = 0, ABox.Top,    ABox.Bottom);
    P.Z := IfThen(I and 4 = 0, ABox.Near,   ABox.Far);
    Corners[I] := ToRigSpace(P);
  end;

  // An affine transform maps the box centre to the transformed centre;
  // the sphere around it must reach the farthest transformed corner
  // (they are not all equidistant under non-uniform scale).
  Center := ToRigSpace((ABox.TopLeftNear + ABox.BottomRightFar) * 0.5);
  R := 0;
  for I := 0 to 7 do
    R := Max(R, (Corners[I] - Center).Length);

  Result := FitSphere(Center, R, VP.Width, VP.Height, AMargin);
end;

function TSprite3DCamera.FitSphere(const ACenter: TPoint3D; ARadius: Single;
  const AViewWidth, AViewHeight, AMargin: Single): Boolean;
var
  R, S, Aspect, K: Single;
  M: TMatrix3D;
begin
  Result := (AViewWidth > 0) and (AViewHeight > 0);
  if not Result then
    Exit;

  R := ARadius * (1 + Max(AMargin, 0));
  if R < EPS then
    R := EPS;  // degenerate (point) box: still centre on it

  FAzimuthPivot.Position.Point := ACenter;

  if IsOrthographic then
  begin
    if OrthoWidth > 0 then
    begin
      // Explicit width: scale both, keeping the user's ratio
      K := 2 * R / Min(OrthoWidth, OrthoHeight);
      OrthoWidth := OrthoWidth * K;
      OrthoHeight := OrthoHeight * K;
    end
    else
    begin
      // Width derived from height * aspect: the narrower side must hold 2R
      Aspect := AViewWidth / AViewHeight;
      OrthoHeight := 2 * R * Max(1, 1 / Aspect);
    end;
    Distance := 2 * R;
  end
  else
  begin
    // Diagonal of the projection matrix = 1 / tan(half-angle) per axis.
    // Near/far do not affect it; the larger scale is the narrower angle.
    M := GetProjectionMatrix(AViewWidth, AViewHeight, 1, 1000);
    S := Max(Abs(M.m11), Abs(M.m22));
    Distance := R * Sqrt(1 + S * S);
  end;
end;

procedure TSprite3DCamera.LookAt(const APoint: TPoint3D; const AMode: TLookAtMode);
var
  Q, Turn: TQuat;
  Eye, Diff, FromDir, ToDir, UpDir: TPoint3D;
  Len: Single;
begin
  Q := GetOrientation;
  Eye := CameraPosition;
  Diff := APoint - Eye;
  Len := Diff.Length;
  if Len < EPS then
    Exit;  // already standing on the point; nothing sensible to face

  FromDir := Q.Rotate(Point3D(0, 0, 1));   // current view direction
  ToDir := Diff.Normalize;
  UpDir := Q.Rotate(Point3D(0, -1, 0));    // camera's own up (FMX up = -Y)

  Turn := TQuat.ShortestArc(FromDir, ToDir, UpDir);

  // Re-centre the orbit on the point; the camera itself does not move:
  // new eye = APoint - Len * ToDir = old eye.
  FAzimuthPivot.Position.Point := APoint;
  FDistance := Len;
  UpdateDistance;

  ApplyOrientation(Turn * Q, AMode = lmKeepRoll);
end;

procedure TSprite3DCamera.SetAzimuth(const Value: Single);
begin
  // Keep it in [0, 360) so it doesn't grow unbounded while orbiting
  FAzimuth := Value - 360 * Floor(Value / 360);
  UpdatePivots;
end;

procedure TSprite3DCamera.SetPolarAngle(const Value: Single);
begin
  FPolarAngle := Value;  // unrestrained
  UpdatePivots;
end;

procedure TSprite3DCamera.SetRoll(const Value: Single);
begin
  FRoll := Value;
  UpdatePivots;
end;

procedure TSprite3DCamera.SetDistance(const Value: Single);
begin
  FDistance := Max(Value, 0.001);
  UpdateDistance;
end;

procedure TSprite3DCamera.UpdatePivots;
var
  S: Integer;
begin
  // Each pivot is a pure single-axis rotation; the two unused axes are
  // always exactly 0, so FMX never composes Euler angles on any one
  // object. S maps right-handed angles to FMX's rotation sense.
  if FAzimuthPivot = nil then
    Exit;
  S := FmxSign;
  FAzimuthPivot.RotationAngle.Point := Point3D(0, S * FAzimuth, 0);
  FPolarPivot.RotationAngle.Point := Point3D(S * -FPolarAngle, 0, 0);
  FRollPivot.RotationAngle.Point := Point3D(0, 0, S * FRoll);
end;

procedure TSprite3DCamera.UpdateDistance;
begin
  // Camera looks down +Z, so back it off along -Z towards the viewer
  Position.Point := Point3D(0, 0, -FDistance);
end;

procedure TSprite3DCamera.Orbit(const DeltaAzimuth, DeltaPolar: Single);
begin
  FAzimuth := FAzimuth + DeltaAzimuth;
  FAzimuth := FAzimuth - 360 * Floor(FAzimuth / 360);
  FPolarAngle := FPolarAngle + DeltaPolar;
  UpdatePivots;
end;

procedure TSprite3DCamera.Zoom(const Factor: Single);
begin
  if Factor > 0 then
    Distance := FDistance * Factor;
end;

procedure TSprite3DCamera.MoveCenterTo(const APoint: TPoint3D);
begin
  FAzimuthPivot.Position.Point := APoint;
end;

initialization
  RegisterFmxClasses([TSprite3DCamera]);

end.
