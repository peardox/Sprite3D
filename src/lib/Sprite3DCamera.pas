//** @abstract(Orbit camera for Gorilla3D, driven by a chain of three single-axis pivots.)
//**
//** TSprite3DCamera is a TGorillaCamera that hangs at the end of a chain of three TDummy
//** pivots. Each pivot turns about one axis only, so Azimuth, PolarAngle and Roll never combine
//** as Euler angles on one object, and the camera can pass over the poles without gimbal lock.
//** The camera sits Distance units back from the orbit centre and always looks at it.
//**
//** @preformatted(
//** <your parent>                      e.g. TGorillaViewport, or any TControl3D
//** `-- AzimuthPivot @(TDummy@)         rotates about Y  ->  Azimuth
//**     `-- PolarPivot @(TDummy@)       rotates about X  ->  PolarAngle
//**         `-- RollPivot @(TDummy@)    rotates about Z  ->  Roll
//**             `-- TSprite3DCamera    at @(0, 0, -Distance@), looking along +Z
//**                                    at the orbit centre, OrbitCenter
//** )
//**
//** Angles are in degrees, and FMX's up direction is -Y. PolarAngle is an elevation and is not
//** limited: 0 is level with the centre, +90 is above it looking down and -90 is below it
//** looking up. Values past +/-90 carry the camera over the pole and down the far side, upside
//** down, and so on for any value.
//**
//** Orientation. The three angles are views of one orientation quaternion, in the rig parent's
//** space, and TQuat does the arithmetic:
//**
//** @preformatted(
//** Q = Qy@(Azimuth@) * Qx@(-PolarAngle@) * Qz@(Roll@)
//** )
//**
//** Reading Orientation builds Q from the angles; SetOrientation splits any quaternion back
//** into the three angles and passes them to the pivots. Of the two angle sets that give the
//** same rotation, it picks the one nearest the current angles, so the values change
//** continuously and PolarAngle can run past +/-90 instead of snapping back. At an exact pole,
//** where Azimuth and Roll turn about the same axis, it keeps the current Azimuth and puts the
//** rest of the twist into Roll, so nothing jumps.
//**
//** LookAt. LookAt keeps the camera where it is and turns it to face a point. The turn is the
//** shortest-arc rotation from the current view direction to the new one. No world-up vector is
//** involved, so nothing can become parallel to the view direction: it works looking straight
//** up or down and never flips, and a 180-degree turn pivots about the camera's own up axis.
//** The point becomes the new OrbitCenter and Distance becomes the camera's distance from it,
//** so orbiting continues round that point.
//**
//** With lmMinimalTwist, the default, the camera keeps as much of its current up direction as
//** it can, so repeated LookAt calls can build up some roll, as with any free-flying camera.
//** With lmKeepRoll the view direction is the same but Roll keeps its current value, so the
//** horizon stays as it was; at an exact pole Azimuth is held rather than worked out again.
//**
//** FitToBounds and FitToBoundsMax. Both make a box as large as possible in the viewport
//** without any part of it overflowing. Neither changes the angles: they move the orbit centre
//** and set Distance, or the orthographic size.
//**
//** FitToBounds fits the box's eight corners exactly, for the current Azimuth, PolarAngle and
//** Roll. The view is centred on them, so the box touches both edges of the tighter axis, left
//** and right or top and bottom, with equal room on the other axis. Changing an angle
//** afterwards can push the box out of view, so call it again after every change.
//**
//** FitToBoundsMax fits the box for every Azimuth, PolarAngle and Roll. Together the three
//** angles reach every orientation, so the box can end up in any rotation about the orbit
//** centre, and all those rotations together fill the ball about the orbit centre that reaches
//** the box's farthest corner. That ball is what is fitted: nothing smaller is safe, because
//** some angle always brings a corner onto it. The ball is centred on the box centre or, when
//** the box comes from a model or another object, on that object's centre of rotation, its
//** RotationCenter. That point can lie outside the box; the camera then circles the point the
//** model turns about, which stays put however an animation moves the box. The orbit centre
//** goes to the ball's centre, and the angles can then change freely without refitting.
//**
//** FitPointsOnAxis frames a set of points the caller gives, such as an outline of a model's
//** swept volume, as FitToBounds frames a box: as large as possible for the current angles,
//** centred so they fill the tighter axis. The orbit centre is then put where the view axis
//** meets a line the caller gives, such as the axis the model turns about, with Distance
//** changed to match, so the view is the same but turning the azimuth keeps the points
//** centred when that line is upright. The angles are not changed.
//**
//** Both read the frustum from the camera's own GetProjectionMatrix for the viewport's size, so
//** the FOV convention, vertical or horizontal, and the aspect ratio come from Gorilla itself,
//** never from guesses.
//**
//** In perspective, FitToBounds works in camera space. With tx and ty the tangents of the
//** half-angles, each corner (x, y, z) must satisfy the first two conditions below for an eye
//** at (cx, cy, cz). Per axis that gives the farthest-forward eye shown, with cx halfway
//** between the bounds, and the eye takes the smaller cz of the two axes, so both fit. It is
//** also kept NEAR_CLEARANCE, 1 unit and FMX's near plane, behind the nearest corner, so the
//** near plane cannot cut into the box. Distance is then measured to the depth of the box's
//** middle.
//**
//** @preformatted(
//** |x - cx| <= tx * @(z - cz@)   and   |y - cy| <= ty * @(z - cz@)
//** cz = @(min@(x + tx z@) - max@(x - tx z@)@) / @(2 tx@)
//** )
//**
//** In perspective, FitToBoundsMax makes the ball, of radius R, touch the narrower pair of
//** frustum planes, s being the projection scale on the narrower axis times the margin:
//**
//** @preformatted(
//** Distance = R / sin@(half@) = R * Sqrt@(1 + s * s@)
//** )
//**
//** In orthographic or isometric mode the size does not depend on distance, so OrthoHeight, and
//** OrthoWidth if one is set, is scaled until the box (FitToBounds) or the ball
//** (FitToBoundsMax) just fills the tighter axis, and the view is centred on it. Distance only
//** has to keep the camera clear of it. AMargin is padding as a fraction of the view: 0.1 makes
//** the fitted box or ball 1/1.1 of the view on the tighter axis.
//**
//** Coordinate spaces matter. FitToBounds(Box) expects the box in the rig parent's space, the
//** scene. A model's own bounds are in its local space, usually centred on the mesh origin, so
//** if the model has been moved, for example lifted to stand on a floor, or scaled, using them
//** directly aims at the wrong point. Pass the object too, as in FitToBounds(Box, Model), and
//** the box's corners are carried through the model's full transform first, so position,
//** rotation and even non-uniform scale are allowed for. FitToBounds(Model) and
//** FitToBoundsMax(Model) do this with the model's local box from GetAnimatedBoundingBox, the
//** same box ShowBoundingBox draws. The viewport is found by walking up from the rig to the
//** first TGorillaViewport.
//**
//** Usage:
//**
//** @preformatted(
//** Cam := TSprite3DCamera.Create@(Self@);
//** Cam.Rig.Parent := GorillaViewport1;   // parent the whole chain, not Cam itself
//** GorillaViewport1.Camera := Cam;
//** GorillaViewport1.UsingDesignCamera := False;
//** Cam.FitToBounds@(GorillaModel1@);       // frame a model
//** Cam.LookAt@(Point3D@(2, 0, 3@)@);         // or face a point, in the rig parent's space
//** )
unit Sprite3DCamera;

{
  Orbit camera for Gorilla3D, driven by a chain of three single-axis pivots.

  TSprite3DCamera is a TGorillaCamera that hangs at the end of a chain of
  three TDummy pivots. Each pivot turns about one axis only, so Azimuth,
  PolarAngle and Roll never combine as Euler angles on one object, and the
  camera can pass over the poles without gimbal lock. The camera sits
  Distance units back from the orbit centre and always looks at it.

    <your parent>                      e.g. TGorillaViewport, or any TControl3D
    `-- AzimuthPivot (TDummy)         rotates about Y  ->  Azimuth
        `-- PolarPivot (TDummy)       rotates about X  ->  PolarAngle
            `-- RollPivot (TDummy)    rotates about Z  ->  Roll
                `-- TSprite3DCamera    at (0, 0, -Distance), looking along +Z
                                       at the orbit centre, OrbitCenter

  Angles are in degrees, and FMX's up direction is -Y. PolarAngle is an
  elevation and is not limited: 0 is level with the centre, +90 is above it
  looking down and -90 is below it looking up. Values past +/-90 carry the
  camera over the pole and down the far side, upside down, and so on for any
  value.

  Orientation. The three angles are views of one orientation quaternion, in
  the rig parent's space, and TQuat does the arithmetic:

    Q = Qy(Azimuth) * Qx(-PolarAngle) * Qz(Roll)

  Reading Orientation builds Q from the angles; SetOrientation splits any
  quaternion back into the three angles and passes them to the pivots. Of
  the two angle sets that give the same rotation, it picks the one nearest
  the current angles, so the values change continuously and PolarAngle can
  run past +/-90 instead of snapping back. At an exact pole, where Azimuth
  and Roll turn about the same axis, it keeps the current Azimuth and puts
  the rest of the twist into Roll, so nothing jumps.

  LookAt. LookAt keeps the camera where it is and turns it to face a point.
  The turn is the shortest-arc rotation from the current view direction to
  the new one. No world-up vector is involved, so nothing can become
  parallel to the view direction: it works looking straight up or down and
  never flips, and a 180-degree turn pivots about the camera's own up axis.
  The point becomes the new OrbitCenter and Distance becomes the camera's
  distance from it, so orbiting continues round that point.

  With lmMinimalTwist, the default, the camera keeps as much of its current
  up direction as it can, so repeated LookAt calls can build up some roll,
  as with any free-flying camera. With lmKeepRoll the view direction is the
  same but Roll keeps its current value, so the horizon stays as it was; at
  an exact pole Azimuth is held rather than worked out again.

  FitToBounds and FitToBoundsMax. Both make a box as large as possible in
  the viewport without any part of it overflowing. Neither changes the
  angles: they move the orbit centre and set Distance, or the orthographic
  size.

  FitToBounds fits the box's eight corners exactly, for the current Azimuth,
  PolarAngle and Roll. The view is centred on them, so the box touches both
  edges of the tighter axis, left and right or top and bottom, with equal
  room on the other axis. Changing an angle afterwards can push the box out
  of view, so call it again after every change.

  FitToBoundsMax fits the box for every Azimuth, PolarAngle and Roll.
  Together the three angles reach every orientation, so the box can end up
  in any rotation about the orbit centre, and all those rotations together
  fill the ball about the orbit centre that reaches the box's farthest
  corner. That ball is what is fitted: nothing smaller is safe, because some
  angle always brings a corner onto it. The ball is centred on the box
  centre or, when the box comes from a model or another object, on that
  object's centre of rotation, its RotationCenter. That point can lie
  outside the box; the camera then circles the point the model turns about,
  which stays put however an animation moves the box. The orbit centre goes
  to the ball's centre, and the angles can then change freely without
  refitting.

  FitPointsOnAxis frames a set of points the caller gives, such as an
  outline of a model's swept volume, as FitToBounds frames a box: as large
  as possible for the current angles, centred so they fill the tighter axis.
  The orbit centre is then put where the view axis meets a line the caller
  gives, such as the axis the model turns about, with Distance changed to
  match, so the view is the same but turning the azimuth keeps the points
  centred when that line is upright. The angles are not changed.

  Both read the frustum from the camera's own GetProjectionMatrix for the
  viewport's size, so the FOV convention, vertical or horizontal, and the
  aspect ratio come from Gorilla itself, never from guesses.

  In perspective, FitToBounds works in camera space. With tx and ty the
  tangents of the half-angles, each corner (x, y, z) must satisfy the first
  two conditions below for an eye at (cx, cy, cz). Per axis that gives the
  farthest-forward eye shown, with cx halfway between the bounds, and the
  eye takes the smaller cz of the two axes, so both fit. It is also kept
  NEAR_CLEARANCE, 1 unit and FMX's near plane, behind the nearest corner, so
  the near plane cannot cut into the box. Distance is then measured to the
  depth of the box's middle.

    |x - cx| <= tx * (z - cz)   and   |y - cy| <= ty * (z - cz)
    cz = (min(x + tx z) - max(x - tx z)) / (2 tx)

  In perspective, FitToBoundsMax makes the ball, of radius R, touch the
  narrower pair of frustum planes, s being the projection scale on the
  narrower axis times the margin:

    Distance = R / sin(half) = R * Sqrt(1 + s * s)

  In orthographic or isometric mode the size does not depend on distance, so
  OrthoHeight, and OrthoWidth if one is set, is scaled until the box
  (FitToBounds) or the ball (FitToBoundsMax) just fills the tighter axis,
  and the view is centred on it. Distance only has to keep the camera clear
  of it. AMargin is padding as a fraction of the view: 0.1 makes the fitted
  box or ball 1/1.1 of the view on the tighter axis.

  Coordinate spaces matter. FitToBounds(Box) expects the box in the rig
  parent's space, the scene. A model's own bounds are in its local space,
  usually centred on the mesh origin, so if the model has been moved, for
  example lifted to stand on a floor, or scaled, using them directly aims at
  the wrong point. Pass the object too, as in FitToBounds(Box, Model), and
  the box's corners are carried through the model's full transform first, so
  position, rotation and even non-uniform scale are allowed for.
  FitToBounds(Model) and FitToBoundsMax(Model) do this with the model's
  local box from GetAnimatedBoundingBox, the same box ShowBoundingBox draws.
  The viewport is found by walking up from the rig to the first
  TGorillaViewport.

  Usage:

    Cam := TSprite3DCamera.Create(Self);
    Cam.Rig.Parent := GorillaViewport1;   // parent the whole chain, not Cam itself
    GorillaViewport1.Camera := Cam;
    GorillaViewport1.UsingDesignCamera := False;
    Cam.FitToBounds(GorillaModel1);       // frame a model
    Cam.LookAt(Point3D(2, 0, 3));         // or face a point, in the rig parent's space
}

interface

uses
  System.Classes, System.Math, System.Math.Vectors,
  FMX.Types, FMX.Types3D, FMX.Controls3D, FMX.Objects3D, FMX.Viewport3D,
  Gorilla.Camera, Gorilla.Viewport, Gorilla.Model;

type
  { Unit quaternion, Hamilton convention, right-hand rule on raw
    coordinates. Q1 * Q2 means "apply Q2 first, then Q1". }
  //** @abstract(A quaternion of Doubles, used for the camera's orientation arithmetic.)
  //**
  //** Hamilton convention, with the right-hand rule on raw coordinates. @code(A * B) means
  //** apply B first, then A. The rotation helpers expect a unit quaternion; Create does not
  //** normalise. TQuat is a plain value type with nothing to free, and may be used on any
  //** thread.
  TQuat = record
    //** @abstract(The scalar part W and the vector part X, Y, Z.)
    //**
    //** For a rotation by angle t about unit axis n, W = cos@(t/2@) and
    //** @(X, Y, Z@) = n sin@(t/2@).
    W, X, Y, Z: Double;
    //** @abstract(Builds a quaternion from its four components, without normalising.)
    //**
    //** @param(AW The scalar part.)
    //**
    //** @param(AX The X component of the vector part.)
    //**
    //** @param(AY The Y component of the vector part.)
    //**
    //** @param(AZ The Z component of the vector part.)
    //**
    //** @returns(The quaternion @(AW, AX, AY, AZ@), exactly as given.)
    class function Create(const AW, AX, AY, AZ: Double): TQuat; static;
    //** @abstract(Returns the identity rotation, which leaves every vector unchanged.)
    //**
    //** @returns(The quaternion @(1, 0, 0, 0@).)
    class function Identity: TQuat; static;
    //** @abstract(Builds the rotation of Radians about Axis.)
    //**
    //** Axis is normalised first, so it need not be unit length, but it must not be zero.
    //** Positive angles follow the right-hand rule about Axis.
    //**
    //** @param(Axis The axis to turn about; any non-zero length.)
    //**
    //** @param(Radians The angle to turn, in radians.)
    //**
    //** @returns(A unit quaternion for the rotation.)
    class function AxisAngle(const Axis: TPoint3D; const Radians: Double): TQuat; static;
    { Shortest rotation taking unit vector AFrom onto unit vector ATo.
      For opposite vectors, rotates 180 degrees about AFallbackAxis, which
      must be perpendicular to AFrom. }
    //** @abstract(Builds the smallest rotation that turns AFrom onto ATo.)
    //**
    //** Both vectors must be unit length. When they point in opposite directions, with a dot
    //** product below -1 + 1E-6, every axis gives an equally short turn, so the result is a
    //** 180-degree turn about AFallbackAxis. LookAt passes the camera's own up direction there.
    //**
    //** @param(AFrom The starting direction, unit length.)
    //**
    //** @param(ATo The target direction, unit length.)
    //**
    //** @param(AFallbackAxis The axis used only for opposite vectors; must be perpendicular to
    //** AFrom, any non-zero length.)
    //**
    //** @returns(A unit quaternion that rotates AFrom onto ATo.)
    //**
    //** @seealso(TSprite3DCamera.LookAt)
    class function ShortestArc(const AFrom, ATo, AFallbackAxis: TPoint3D): TQuat; static;
    //** @abstract(Interpolates spherically between two rotations.)
    //**
    //** Always takes the shorter way round, using -B in place of B where that is nearer to A.
    //** When A and B are almost equal it falls back to linear interpolation to avoid dividing
    //** by a tiny sine. The result is normalised.
    //**
    //** @param(A The rotation at T = 0; unit length.)
    //**
    //** @param(B The rotation at T = 1; unit length.)
    //**
    //** @param(T The interpolation factor, normally from 0 to 1.)
    //**
    //** @returns(The interpolated rotation, as a unit quaternion.)
    class function Slerp(const A, B: TQuat; const T: Double): TQuat; static;
    //** @abstract(Composes two rotations; the result applies B first, then A.)
    //**
    //** @param(A The rotation applied second.)
    //**
    //** @param(B The rotation applied first.)
    //**
    //** @returns(The Hamilton product @code(A * B), not normalised.)
    class operator Multiply(const A, B: TQuat): TQuat;
    //** @abstract(Returns the conjugate, which for a unit quaternion is the inverse rotation.)
    //**
    //** @returns(The quaternion @(W, -X, -Y, -Z@).)
    function Conjugate: TQuat;
    //** @abstract(Returns this quaternion scaled to unit length.)
    //**
    //** If the length is below 1E-6 there is no meaningful direction, and the identity is
    //** returned instead.
    //**
    //** @returns(A unit quaternion.)
    function Normalized: TQuat;
    //** @abstract(Rotates a vector by this quaternion.)
    //**
    //** The result is only a pure rotation if this is a unit quaternion.
    //**
    //** @param(V The vector to rotate.)
    //**
    //** @returns(The rotated vector.)
    function Rotate(const V: TPoint3D): TPoint3D;
  end;

  //** @abstract(How LookAt treats Roll when it turns the camera.)
  //**
  //** @value(lmMinimalTwist The default. A pure shortest-arc turn: the camera keeps as much of
  //** its current up direction as it can. Repeated LookAt calls can build up some roll.)
  //**
  //** @value(lmKeepRoll The same view direction, but Roll keeps its current value, so the
  //** horizon stays as it was. Still safe at the poles, where Azimuth is held.)
  //**
  //** @seealso(TSprite3DCamera.LookAt)
  TLookAtMode = (lmMinimalTwist, lmKeepRoll);


  //** @abstract(A camera's framing: where it orbits and how far out it is.)
  //**
  //** Holds what FitToBounds and FitToBoundsMax change, so a fit can be undone. Angles are
  //** not included; a fit never changes them.
  //**
  //** @seealso(TSprite3DCamera.SaveFraming)
  TSprite3DFraming = record
    //** @abstract(The point the camera orbits, OrbitCenter, in the rig parent's space.)
    OrbitCenter: TPoint3D;
    //** @abstract(The camera's Distance from OrbitCenter.)
    Distance: Single;
    //** @abstract(The orthographic view height, OrthoHeight.)
    OrthoHeight: Single;
    //** @abstract(The orthographic view width, OrthoWidth; 0 when it follows the height.)
    OrthoWidth: Single;
  end;

  //** @abstract(A TGorillaCamera that orbits a centre point through a chain of three pivots.)
  //**
  //** The constructor builds the pivot chain and makes the camera a child of RollPivot. Place
  //** the camera in a scene by setting @code(Rig.Parent), never the camera's own Parent. Leave
  //** TCamera.Target nil: the pivots aim the camera at OrbitCenter.
  //**
  //** The pivots have no owner and are not stored in .fmx files. Freeing the camera frees the
  //** pivots; freeing Rig frees the pivots and the camera. Like any FMX object, use it from
  //** the main thread only. The class is registered with RegisterFmxClasses.
  //**
  //** @seealso(Rig)
  //**
  //** @seealso(LookAt)
  //**
  //** @seealso(FitToBounds)
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
    FLocked: Boolean;
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
    function FitBox(const ABox: TBoundingBox; const ASpace: TControl3D;
      const AFromRigSpace: Boolean; const AViewWidth, AViewHeight,
      AMargin: Single; const AAnyAngle: Boolean): Boolean;
    function FitCorners(const ACorners: array of TPoint3D;
      const AViewWidth, AViewHeight, AMargin: Single;
      const AAnyAngle: Boolean; const APivot: TPoint3D;
      const AUsePivot: Boolean): Boolean;
    function FitOnAxis(const APoints: array of TPoint3D; const ALinePoint,
      ALineDirection: TPoint3D; const ASpace: TControl3D; const AViewWidth, AViewHeight,
      AMargin: Single): Boolean;
  public
    //** @abstract(Creates the camera and its pivot chain.)
    //**
    //** Distance starts at 10 and all three angles at 0. If AOwner is a TGorillaViewport, Rig
    //** is parented to it straight away; otherwise set @code(Rig.Parent) before the camera can
    //** render anything.
    //**
    //** @param(AOwner The owner of the camera itself, not of the pivots. If it is a
    //** TGorillaViewport it also becomes the parent of Rig.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Frees the camera and, if it was freed directly, its pivot chain.)
    //**
    //** When the camera is freed directly, for example by its owner, it detaches from RollPivot
    //** and frees Rig, which frees PolarPivot and RollPivot with it. When Rig is being freed by
    //** its own parent, the pivots are already on their way out and are left alone.
    destructor Destroy; override;

    { Turn the camera, from where it stands, to face APoint (given in the
      rig parent's space). Pole-safe and flip-free; see unit header. }
    //** @abstract(Turns the camera, from where it stands, to face APoint.)
    //**
    //** The turn is the shortest-arc rotation from the current view direction to the new one.
    //** No world-up vector is involved, so it works looking straight up or down and never
    //** flips; a 180-degree turn pivots about the camera's own up axis.
    //**
    //** The camera's position does not change. APoint becomes the new OrbitCenter and Distance
    //** becomes the camera's distance from it, so later orbiting circles that point. If the
    //** camera already stands on APoint, within 1E-6, nothing happens.
    //**
    //** @param(APoint The point to face, in the rig parent's space.)
    //**
    //** @param(AMode Whether Roll may change; see TLookAtMode.)
    //**
    //** @seealso(TLookAtMode)
    //**
    //** @seealso(SetOrientation)
    procedure LookAt(const APoint: TPoint3D;
      const AMode: TLookAtMode = lmMinimalTwist);

    { Set the orientation directly (rig parent space). The angles are
      re-derived continuously from it. }
    //** @abstract(Sets the orientation directly, in the rig parent's space.)
    //**
    //** Q is normalised, then split into Azimuth, PolarAngle and Roll. Of the two angle sets
    //** that give the same rotation, the one nearest the current angles is chosen, so the
    //** values change continuously and PolarAngle can run past +/-90. At an exact pole Azimuth
    //** is held and the rest of the twist goes into Roll. Azimuth is wrapped into 0 to 360;
    //** PolarAngle and Roll are not wrapped.
    //**
    //** OrbitCenter and Distance do not change, so the camera swings round the centre.
    //**
    //** @param(Q The new orientation. A quaternion of near-zero length is treated as the
    //** identity.)
    //**
    //** @seealso(Orientation)
    procedure SetOrientation(const Q: TQuat);

    { Incremental helpers, e.g. from mouse drag / wheel }
    //** @abstract(Adds to Azimuth and PolarAngle, for example from a mouse drag.)
    //**
    //** Azimuth is wrapped into 0 to 360. PolarAngle is not limited, so the camera can carry on
    //** over a pole. Roll, Distance and OrbitCenter do not change.
    //**
    //** @param(DeltaAzimuth Degrees to add to Azimuth.)
    //**
    //** @param(DeltaPolar Degrees to add to PolarAngle; positive raises the camera.)
    procedure Orbit(const DeltaAzimuth, DeltaPolar: Single);
    //** @abstract(Multiplies Distance by Factor, for example from the mouse wheel.)
    //**
    //** A Factor below 1 moves the camera closer. A Factor of zero or less is ignored, and
    //** Distance never goes below 0.001. In orthographic mode the apparent size depends on
    //** OrthoHeight, not on Distance, so zooming this way has no visible effect there.
    //**
    //** @param(Factor The multiplier; must be greater than zero to have any effect.)
    procedure Zoom(const Factor: Single);
    { Move the orbit centre without changing the angles (pans the view) }
    //** @abstract(Moves the orbit centre to APoint without changing the angles or Distance.)
    //**
    //** The camera moves with the centre, so the view pans.
    //**
    //** @param(APoint The new orbit centre, in the rig parent's space.)
    procedure MoveCenterTo(const APoint: TPoint3D);

    { Camera position in the rig parent's space }
    //** @abstract(Returns the camera's position in the rig parent's space.)
    //**
    //** Computed from OrbitCenter, the three angles and Distance rather than read back from FMX
    //** matrices, so it is correct before the first frame is drawn.
    //**
    //** @returns(The camera's position.)
    function CameraPosition: TPoint3D;
    //** @abstract(Returns the current framing, for RestoreFraming to put back later.)
    //**
    //** Use it around a temporary fit, such as fitting the model to an off-screen target of a
    //** different shape.
    //**
    //** @returns(OrbitCenter, Distance, OrthoHeight and OrthoWidth as they are now.)
    //**
    //** @seealso(RestoreFraming)
    function SaveFraming: TSprite3DFraming;
    //** @abstract(Puts back a framing returned by SaveFraming.)
    //**
    //** Sets OrbitCenter, Distance, OrthoHeight and OrthoWidth; the angles are left as they
    //** are.
    //**
    //** @param(AFraming The framing to restore.)
    //**
    //** @seealso(SaveFraming)
    procedure RestoreFraming(const AFraming: TSprite3DFraming);

    { The TViewport3D (e.g. TGorillaViewport) the rig lives in, or nil }
    //** @abstract(Returns the TGorillaViewport the rig is placed in, or nil.)
    //**
    //** Walks up the parent chain from Rig's parent and stops at the first TGorillaViewport. A
    //** plain TViewport3D is not recognised. The caller does not own the result.
    //**
    //** @returns(The viewport, typed as TViewport3D, or nil if Rig has no TGorillaViewport
    //** above it.)
    function FindViewport: TViewport3D;

    { Make ABox (rig parent space) as large as possible in the viewport
      without overflowing it, for the CURRENT angles. Moves the orbit
      centre and sets Distance (or the orthographic size); never changes
      the angles. Changing the angles afterwards can push the box out of
      view - see FitToBoundsMax. Returns False (and changes nothing) if
      there is no viewport with a usable size. See unit header. }
    //** @abstract(Makes ABox as large as possible in the viewport for the current angles.)
    //**
    //** The fit is for the camera's current Azimuth, PolarAngle and Roll, which are never
    //** changed. OrbitCenter moves and Distance changes; in orthographic or isometric mode
    //** OrthoHeight, and OrthoWidth if it is non-zero, are scaled as well. The view is centred
    //** on the box's eight corners, and they touch both edges of the tighter axis. The
    //** frustum, including the aspect ratio, comes from GetProjectionMatrix for the viewport's
    //** size.
    //**
    //** Changing an angle afterwards can push the box out of view, so call FitToBounds again
    //** after every change, or use FitToBoundsMax. In perspective mode every corner is also
    //** kept at least 1 unit in front of the camera, FMX's near plane, which can make a very
    //** deep box smaller than the view.
    //**
    //** @param(ABox The box to frame, in the rig parent's space. For a box in an object's own
    //** local space, use the overload that takes ASpace.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the box 1/1.1 of the view
    //** on the tighter axis. Negative values count as 0.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty,
    //** there is no viewport, or it has zero width or height.)
    //**
    //** @seealso(FitToBoundsMax)
    //**
    //** @seealso(FindViewport)
    function FitToBounds(const ABox: TBoundingBox;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for a Gorilla model: fits the box ShowBoundingBox draws }
    //** @abstract(Makes a Gorilla model's bounding box as large as possible for the current
    //** angles.)
    //**
    //** Takes @code(AModel.GetAnimatedBoundingBox), which Gorilla v1.5 documents as the box of
    //** the current pose in the model's local space and which ShowBoundingBox draws. It is
    //** passed, with AModel as the space, to the overload that takes ASpace, so the model's
    //** position, rotation and scale are applied once. The box follows the animation, so the
    //** fit is for the pose at the time of the call.
    //**
    //** @param(AModel The model to frame; nil makes the call return False.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the box 1/1.1 of the view
    //** on the tighter axis.)
    //**
    //** @returns(True if the model was framed; False, with nothing changed, if AModel is nil,
    //** it has no vertices, there is no viewport, or the viewport has zero width or height.)
    //**
    //** @seealso(FitToBoundsMax)
    function FitToBounds(const AModel: TGorillaModel;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for an explicit view size (e.g. before the viewport is shown) }
    //** @abstract(Fits ABox for the current angles and an explicit view size.)
    //**
    //** Works like the overload without a view size, but uses AViewWidth and AViewHeight instead
    //** of the viewport's size, so no viewport is needed, for example before it is shown. Only
    //** their ratio matters.
    //**
    //** @param(ABox The box to frame, in the rig parent's space.)
    //**
    //** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
    //**
    //** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the box 1/1.1 of the view
    //** on the tighter axis.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty
    //** or either size is zero or less.)
    function FitToBounds(const ABox: TBoundingBox; const AViewWidth,
      AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;
    { Same, for a Gorilla model and an explicit view size (e.g. an
      off-screen target whose shape differs from the viewport's) }
    //** @abstract(Makes a Gorilla model's bounding box as large as possible in a view of the given
    //** size, for the current angles.)
    //**
    //** Works like the overload that takes only a model, but frames it for AViewWidth by
    //** AViewHeight instead of the viewport's size; only their ratio matters. Use it to fit the
    //** model to an off-screen target, such as a TSprite3DOffscreen, whose shape differs from
    //** the viewport's. The camera is changed as by every fit, so the on-screen view changes
    //** too until it is refitted or restored.
    //**
    //** @param(AModel The model to frame; nil makes the call return False.)
    //**
    //** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
    //**
    //** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the box 1/1.1 of the view
    //** on the tighter axis.)
    //**
    //** @returns(True if the model was framed; False, with nothing changed, if AModel is nil,
    //** it has no vertices, or either size is zero or less.)
    //**
    //** @seealso(FitToBoundsMax)
    function FitToBounds(const AModel: TGorillaModel; const AViewWidth,
      AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;
    { ABox is in ASpace's LOCAL coordinates (e.g. a model's mesh bounds).
      Its corners are carried through ASpace's position, rotation and
      scale into the rig parent's space before fitting. Use this whenever
      the box comes from the object itself rather than from the scene. }
    //** @abstract(Fits a box given in ASpace's local coordinates for the current angles.)
    //**
    //** All eight corners are carried through ASpace's position, rotation and scale into the rig
    //** parent's space, then fitted as in the other overloads, using the viewport's size. A
    //** rotated box is fitted as the rotated box, not as a larger axis-aligned one, and
    //** non-uniform scale is handled.
    //**
    //** @param(ABox The box to frame, in ASpace's local coordinates, such as a model's mesh
    //** bounds.)
    //**
    //** @param(ASpace The object whose local space ABox is in. If nil, ABox is taken to be in
    //** absolute viewport space.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the box 1/1.1 of the view
    //** on the tighter axis.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty,
    //** there is no viewport, or it has zero width or height.)
    function FitToBounds(const ABox: TBoundingBox; const ASpace: TControl3D;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for an explicit view size (e.g. an off-screen target), so a box
      gathered by the caller, such as the union of an animation's poses, can
      be fitted to a grab }
    //** @abstract(Fits a box given in ASpace's local coordinates for the current angles and
    //** an explicit view size.)
    //**
    //** Works like the overload that takes a box and a space, but frames it for AViewWidth by
    //** AViewHeight instead of the viewport's size; only their ratio matters. Use it to frame a
    //** box the caller has gathered, such as the union of every pose of an animation, for an
    //** off-screen target whose shape differs from the viewport's. The camera is changed as by
    //** every fit, so the on-screen view changes too until it is refitted or restored.
    //**
    //** @param(ABox The box to frame, in ASpace's local coordinates.)
    //**
    //** @param(ASpace The object whose local space ABox is in. If nil, ABox is taken to be in
    //** absolute viewport space.)
    //**
    //** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
    //**
    //** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the box 1/1.1 of the view
    //** on the tighter axis.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty
    //** or either size is zero or less.)
    function FitToBounds(const ABox: TBoundingBox; const ASpace: TControl3D;
      const AViewWidth, AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;

    { Make ABox as large as possible in the viewport while staying fully
      visible for EVERY Azimuth, PolarAngle and Roll. The orbit centre
      moves to the box centre (or, in the overloads that know the object,
      to its centre of rotation), so the angles can then be changed freely
      without refitting. See unit header. }
    //** @abstract(Makes ABox as large as possible while it stays visible at every angle.)
    //**
    //** Azimuth, PolarAngle and Roll together reach every orientation, so the box can end up
    //** in any rotation about the orbit centre. All those rotations together fill the sphere
    //** around the box's centre that reaches its farthest corner, so that sphere is what is
    //** fitted: it is the smallest shape that is safe for every angle. OrbitCenter moves to
    //** the box's centre and Distance, or the orthographic size, is set; the angles are not
    //** changed and can then be changed freely without refitting. The overloads that take a
    //** model or ASpace centre the sphere on that object's centre of rotation instead.
    //**
    //** The box looks smaller than with FitToBounds, by up to the ratio of the box's half
    //** diagonal to its smaller visible half-size. In perspective mode the sphere is kept at
    //** least 1 unit in front of the camera, FMX's near plane.
    //**
    //** @param(ABox The box to frame, in the rig parent's space. For a box in an object's own
    //** local space, use the overload that takes ASpace.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the sphere 1/1.1 of the
    //** view on the tighter axis. Negative values count as 0.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty,
    //** there is no viewport, or it has zero width or height.)
    //**
    //** @seealso(FitToBounds)
    function FitToBoundsMax(const ABox: TBoundingBox;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for a Gorilla model: the box ShowBoundingBox draws }
    //** @abstract(Makes a Gorilla model's bounding box as large as possible while it stays
    //** visible at every angle.)
    //**
    //** Takes @code(AModel.GetAnimatedBoundingBox), the current pose's box in the model's local
    //** space, and passes it with AModel as the space to the overload that takes ASpace, so the
    //** model's transform is applied once. The sphere is centred on the model's centre of
    //** rotation, its RotationCenter, which can lie outside the box: the camera then circles
    //** the point the model turns about, which stays put however an animation moves the box.
    //** The pose is taken at the time of the call; an animation that later reaches farther
    //** from that point can still overflow.
    //**
    //** @param(AModel The model to frame; nil makes the call return False.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the sphere 1/1.1 of the
    //** view on the tighter axis.)
    //**
    //** @returns(True if the model was framed; False, with nothing changed, if AModel is nil,
    //** it has no vertices, there is no viewport, or the viewport has zero width or height.)
    //**
    //** @seealso(FitToBounds)
    function FitToBoundsMax(const AModel: TGorillaModel;
      const AMargin: Single = 0): Boolean; overload;
    { Same, for an explicit view size (e.g. before the viewport is shown) }
    //** @abstract(Fits ABox for every angle and an explicit view size.)
    //**
    //** Works like the overload without a view size, but uses AViewWidth and AViewHeight instead
    //** of the viewport's size, so no viewport is needed, for example before it is shown. Only
    //** their ratio matters.
    //**
    //** @param(ABox The box to frame, in the rig parent's space.)
    //**
    //** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
    //**
    //** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the sphere 1/1.1 of the
    //** view on the tighter axis.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty
    //** or either size is zero or less.)
    function FitToBoundsMax(const ABox: TBoundingBox; const AViewWidth,
      AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;
    { Same, for a Gorilla model and an explicit view size }
    //** @abstract(Makes a Gorilla model's bounding box as large as possible in a view of the given
    //** size while it stays visible at every angle.)
    //**
    //** Works like the overload that takes only a model, centring the sphere on the model's
    //** centre of rotation, but frames it for AViewWidth by AViewHeight instead of the
    //** viewport's size; only their ratio matters. Use it to fit the model to an off-screen
    //** target whose shape differs from the viewport's. The camera is changed as by every fit.
    //**
    //** @param(AModel The model to frame; nil makes the call return False.)
    //**
    //** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
    //**
    //** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the sphere 1/1.1 of the
    //** view on the tighter axis.)
    //**
    //** @returns(True if the model was framed; False, with nothing changed, if AModel is nil,
    //** it has no vertices, or either size is zero or less.)
    //**
    //** @seealso(FitToBounds)
    function FitToBoundsMax(const AModel: TGorillaModel; const AViewWidth,
      AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;
    { ABox is in ASpace's LOCAL coordinates, as for FitToBounds }
    //** @abstract(Fits a box given in ASpace's local coordinates for every angle.)
    //**
    //** All eight corners are carried through ASpace's position, rotation and scale into the rig
    //** parent's space. The sphere is centred on ASpace's centre of rotation, its RotationCenter
    //** carried into the same space, and reaches the farthest transformed corner from it, so
    //** non-uniform scale is handled. The centre of rotation can lie outside the box; the camera
    //** then circles it, which keeps it steady while an animation moves the box. With ASpace nil
    //** the sphere is centred on the box. It is then fitted as in the other overloads, using
    //** the viewport's size.
    //**
    //** @param(ABox The box to frame, in ASpace's local coordinates, such as a model's mesh
    //** bounds.)
    //**
    //** @param(ASpace The object whose local space ABox is in. If nil, ABox is taken to be in
    //** absolute viewport space.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the sphere 1/1.1 of the
    //** view on the tighter axis.)
    //**
    //** @returns(True if the box was framed; False, with nothing changed, if the box is empty,
    //** there is no viewport, or it has zero width or height.)
    function FitToBoundsMax(const ABox: TBoundingBox; const ASpace: TControl3D;
      const AMargin: Single = 0): Boolean; overload;

    //** @abstract(Frames a set of points as large as possible for the current angles, with the
    //** orbit centre on a given line.)
    //**
    //** The points are framed as FitToBounds frames a box's corners: as large as they can be
    //** in the view, centred, so they reach both edges of the tighter axis, left and right or
    //** top and bottom, and in perspective mode at least 1 unit in front of the camera, FMX's
    //** near plane. The view only holds their convex hull, so the points need only enclose the
    //** shape to be framed. Azimuth, PolarAngle and Roll are not changed.
    //**
    //** OrbitCenter is then moved along the view axis to the point nearest the line through
    //** ALinePoint along ALineDirection, and Distance changed by the same amount, so the
    //** camera, and the view, stay exactly where the fit put them. For a shape that is round
    //** about that line, such as a model's swept volume about its turning axis, the view axis
    //** meets the line while Roll is 0, so the orbit centre is on it and turning the azimuth,
    //** with the line upright, keeps the shape centred and in view. When the view axis runs
    //** along the line, as seen from straight above, or the move would put the camera less
    //** than 1 unit from the new centre, the orbit centre is left where the fit put it.
    //**
    //** The points and the line are carried through ASpace's position, rotation and scale into
    //** the rig parent's space first.
    //**
    //** @param(APoints The points to keep in view, in ASpace's local coordinates.)
    //**
    //** @param(ALinePoint A point on the line the orbit centre is put on, in the same
    //** coordinates.)
    //**
    //** @param(ALineDirection The line's direction, in the same coordinates; any length but 0.)
    //**
    //** @param(ASpace The object whose local space the points and line are in. If nil, they are
    //** taken to be in absolute viewport space.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the points' extent 1/1.1 of
    //** the view on the tighter axis. Negative values count as 0.)
    //**
    //** @returns(True if the points were framed; False, with nothing changed, if there are
    //** none, the camera is locked, there is no viewport, or it has zero width or height.)
    //**
    //** @seealso(FitToBounds)
    function FitPointsOnAxis(const APoints: array of TPoint3D; const ALinePoint,
      ALineDirection: TPoint3D; const ASpace: TControl3D;
      const AMargin: Single = 0): Boolean; overload;

    //** @abstract(Frames a set of points with the orbit centre on a given line, for an explicit
    //** view size.)
    //**
    //** Works like the overload without a view size, but frames the points for AViewWidth by
    //** AViewHeight instead of the viewport's size; only their ratio matters. Use it for an
    //** off-screen target whose shape differs from the viewport's.
    //**
    //** @param(APoints The points to keep in view, in ASpace's local coordinates.)
    //**
    //** @param(ALinePoint A point on the line the orbit centre is put on, in the same
    //** coordinates.)
    //**
    //** @param(ALineDirection The line's direction, in the same coordinates; any length but 0.)
    //**
    //** @param(ASpace The object whose local space the points and line are in. If nil, they are
    //** taken to be in absolute viewport space.)
    //**
    //** @param(AViewWidth The width of the view, in the same units as AViewHeight.)
    //**
    //** @param(AViewHeight The height of the view, in the same units as AViewWidth.)
    //**
    //** @param(AMargin Padding as a fraction of the view: 0.1 makes the points' extent 1/1.1 of
    //** the view on the tighter axis.)
    //**
    //** @returns(True if the points were framed; False, with nothing changed, if there are
    //** none, the camera is locked, or either size is zero or less.)
    function FitPointsOnAxis(const APoints: array of TPoint3D; const ALinePoint,
      ALineDirection: TPoint3D; const ASpace: TControl3D; const AViewWidth,
      AViewHeight: Single; const AMargin: Single = 0): Boolean; overload;

    //** @abstract(Slides the view by a number of pixels across and up, without turning it.)
    //**
    //** OrbitCenter, and so the camera, moves along the camera's own right and up directions
    //** by as much as ARight and AUp pixels measure, in a view of AViewWidth by AViewHeight,
    //** at the orbit centre's depth: so the picture moves the other way by that many pixels
    //** there. In orthographic mode a pixel is the same size at every depth and the slide is
    //** exact; in perspective, parts nearer or further than the orbit centre move a little
    //** more or less, which for the fractions of a pixel it is meant for is negligible. The
    //** angles, Distance and the orthographic size are not changed, and it works whether or
    //** not the camera is Locked, as the caller is expected to put OrbitCenter back.
    //**
    //** @param(ARight Pixels to slide the view right; negative slides it left.)
    //**
    //** @param(AUp Pixels to slide the view up; negative slides it down.)
    //**
    //** @param(AViewWidth The width of the view the pixels are measured in.)
    //**
    //** @param(AViewHeight The height of the view the pixels are measured in.)
    procedure ShiftView(const ARight, AUp, AViewWidth, AViewHeight: Single);
    //** @abstract(Where a point falls in a view of a given size, as the camera stands.)
    //**
    //** The point is carried into the rig's space as the fits carry a box's corners, then seen
    //** through the camera's own GetProjectionMatrix for AViewWidth by AViewHeight, in
    //** perspective or orthographic projection as the camera is set. The result is measured
    //** in the view's pixels from its top-left corner, so the centre of the view is
    //** @code(@(AViewWidth / 2, AViewHeight / 2@)) and the centre of the top-left pixel is
    //** @code(@(0.5, 0.5@)). It may lie outside the view.
    //**
    //** @param(APoint The point, in ASpace's own coordinates, such as a model's
    //** RotationCenter.)
    //**
    //** @param(ASpace The object whose coordinates APoint is in; nil for the rig parent's.)
    //**
    //** @param(AViewWidth The width of the view, in pixels, such as a grab's.)
    //**
    //** @param(AViewHeight The height of the view, in pixels.)
    //**
    //** @param(AX Set to the distance from the view's left edge, in pixels.)
    //**
    //** @param(AY Set to the distance from the view's top edge, in pixels.)
    //**
    //** @returns(False, leaving AX and AY at 0, if the view has no size or, in perspective,
    //** the point is not in front of the camera.)
    function ProjectToView(const APoint: TPoint3D; const ASpace: TControl3D;
      const AViewWidth, AViewHeight: Single; out AX, AY: Single): Boolean;

    { Root of the chain - set Rig.Parent to place the camera in a scene }
    //** @abstract(The root of the pivot chain; set @code(Rig.Parent) to place the camera in a
    //** scene.)
    //**
    //** The same object as AzimuthPivot. Its Position is OrbitCenter. Freeing Rig frees the
    //** whole chain, the camera included.
    property Rig: TDummy read FAzimuthPivot;
    //** @abstract(The pivot that turns about Y for Azimuth; the root of the chain, same as Rig.)
    //**
    //** Its rotation is overwritten whenever an angle changes, so do not set it directly.
    property AzimuthPivot: TDummy read FAzimuthPivot;
    //** @abstract(The pivot that turns about X for PolarAngle; a child of AzimuthPivot.)
    //**
    //** Its rotation is overwritten whenever an angle changes, so do not set it directly.
    property PolarPivot: TDummy read FPolarPivot;
    //** @abstract(The pivot that turns about Z for Roll; a child of PolarPivot and the camera's
    //** parent.)
    //**
    //** Its rotation is overwritten whenever an angle changes, so do not set it directly.
    property RollPivot: TDummy read FRollPivot;

    { Orbit centre = root pivot position, in the rig parent's space.
      (Named so as not to clash with TCamera.Target, which should be
      left nil on this camera.) }
    //** @abstract(The point the camera orbits and looks at, in the rig parent's space.)
    //**
    //** This is Rig's Position object, so writing to it, for example
    //** @code(OrbitCenter.Point := P), moves the centre and the camera with it. It is named so
    //** as not to clash with TCamera.Target, which should be left nil on this camera.
    property OrbitCenter: TPosition3D read GetOrbitCenter;
    //** @abstract(The camera's orientation as a quaternion in the rig parent's space.)
    //**
    //** Reading builds @code(Qy@(Azimuth@) * Qx@(-PolarAngle@) * Qz@(Roll@)). Writing calls
    //** SetOrientation, which splits the quaternion back into the three angles.
    //**
    //** @seealso(SetOrientation)
    property Orientation: TQuat read GetOrientation write SetOrientation;
  published
    //** @abstract(Rotation about the vertical Y axis through the orbit centre, in degrees.)
    //**
    //** Written values are wrapped into 0 to 360. The pivots update at once.
    property Azimuth: Single read FAzimuth write SetAzimuth;
    //** @abstract(Elevation of the camera above the orbit centre, in degrees.)
    //**
    //** 0 is level with the centre, +90 is directly above looking down and -90 directly below
    //** looking up. Not limited: values past +/-90 carry the camera over the pole and down the
    //** far side, upside down.
    property PolarAngle: Single read FPolarAngle write SetPolarAngle;
    //** @abstract(Rotation of the camera about its own view direction, in degrees.)
    //**
    //** Neither wrapped nor limited. It never changes where the camera points.
    property Roll: Single read FRoll write SetRoll;
    //** @abstract(Distance from the orbit centre to the camera, in scene units.)
    //**
    //** Defaults to 10 and is clamped to at least 0.001. In orthographic mode it does not change
    //** the apparent size; FitToBounds still sets it to keep the near plane clear of the framed
    //** object.
    property Distance: Single read FDistance write SetDistance;
    //** @abstract(While True, nothing done through this class moves or turns the camera.)
    //**
    //** Setting Azimuth, PolarAngle, Roll, Distance or Orientation, and calling LookAt, Orbit,
    //** Zoom, MoveCenterTo or RestoreFraming, then do nothing, and every FitToBounds and
    //** FitToBoundsMax returns False without changing anything. Reading is unaffected, so
    //** SaveFraming still works. It does not stop code writing straight to the inherited
    //** properties, such as ProjectionMode and OrthoHeight, or to OrbitCenter's position;
    //** callers that honour the lock must check it before they do. False by default.
    property Locked: Boolean read FLocked write FLocked;
  end;

implementation

const
  EPS = 1E-6;
  // FMX's own context projects with the near plane at 1 and the far plane
  // at 1000. FitToBounds keeps every corner at least NEAR_CLEARANCE in
  // front of the camera, so the near plane never cuts into the box.
  // Typed, so Min / Max with Single arguments resolve without ambiguity
  NEAR_CLEARANCE: Single = 1.0;
  FAR_PLANE: Single = 1000.0;

type
  TBoxCorners = array[0..7] of TPoint3D;

{ The eight corners of ABox; bits 0, 1 and 2 of the index pick Right,
  Bottom and Far over Left, Top and Near }
procedure GetBoxCorners(const ABox: TBoundingBox; out ACorners: TBoxCorners);
var
  I: Integer;
begin
  for I := 0 to High(ACorners) do
  begin
    ACorners[I].X := IfThen(I and 1 = 0, ABox.Left, ABox.Right);
    ACorners[I].Y := IfThen(I and 2 = 0, ABox.Top, ABox.Bottom);
    ACorners[I].Z := IfThen(I and 4 = 0, ABox.Near, ABox.Far);
  end;
end;

{ False for an empty box (e.g. a model with no vertices), whose minimum
  lies beyond its maximum }
function IsValidBox(const ABox: TBoundingBox): Boolean;
begin
  Result := (ABox.Left <= ABox.Right) and (ABox.Top <= ABox.Bottom) and
    (ABox.Near <= ABox.Far);
end;

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
  if FLocked then
    Exit;
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

function TSprite3DCamera.SaveFraming: TSprite3DFraming;
begin
  Result.OrbitCenter := OrbitCenter.Point;
  Result.Distance := Distance;
  Result.OrthoHeight := OrthoHeight;
  Result.OrthoWidth := OrthoWidth;
end;

procedure TSprite3DCamera.RestoreFraming(const AFraming: TSprite3DFraming);
begin
  if FLocked then
    Exit;
  OrbitCenter.Point := AFraming.OrbitCenter;
  Distance := AFraming.Distance;
  OrthoHeight := AFraming.OrthoHeight;
  OrthoWidth := AFraming.OrthoWidth;
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
    FitBox(ABox, nil, True, VP.Width, VP.Height, AMargin, False);
end;

function TSprite3DCamera.FitToBounds(const ABox: TBoundingBox;
  const AViewWidth, AViewHeight: Single; const AMargin: Single): Boolean;
begin
  Result := FitBox(ABox, nil, True, AViewWidth, AViewHeight, AMargin, False);
end;

function TSprite3DCamera.FitToBounds(const AModel: TGorillaModel;
  const AMargin: Single): Boolean;
begin
  // GetAnimatedBoundingBox is in the model's LOCAL space (relative to its
  // AbsoluteMatrix) and is the box ShowBoundingBox draws, so the model is
  // passed as the space and its transform is applied exactly once.
  // GetBoundingBox / GetAbsoluteBoundingBox already include the model's
  // matrices; passing one of them here applied the transform twice and
  // put the framing off-centre.
  Result := Assigned(AModel) and
    FitToBounds(AModel.GetAnimatedBoundingBox(), AModel, AMargin);
end;

function TSprite3DCamera.FitToBounds(const AModel: TGorillaModel;
  const AViewWidth, AViewHeight: Single; const AMargin: Single): Boolean;
begin
  // Same box and space as FitToBounds(AModel), for a view of a given size
  Result := Assigned(AModel) and
    FitBox(AModel.GetAnimatedBoundingBox(), AModel, False, AViewWidth,
      AViewHeight, AMargin, False);
end;

function TSprite3DCamera.FitToBounds(const ABox: TBoundingBox;
  const ASpace: TControl3D; const AMargin: Single): Boolean;
var
  VP: TViewport3D;
begin
  VP := FindViewport;
  Result := (VP <> nil) and
    FitBox(ABox, ASpace, False, VP.Width, VP.Height, AMargin, False);
end;

function TSprite3DCamera.FitToBounds(const ABox: TBoundingBox;
  const ASpace: TControl3D; const AViewWidth, AViewHeight: Single;
  const AMargin: Single): Boolean;
begin
  // As the overload above, for a view of a given size
  Result := FitBox(ABox, ASpace, False, AViewWidth, AViewHeight, AMargin, False);
end;

function TSprite3DCamera.FitToBoundsMax(const ABox: TBoundingBox;
  const AMargin: Single): Boolean;
var
  VP: TViewport3D;
begin
  VP := FindViewport;
  Result := (VP <> nil) and
    FitBox(ABox, nil, True, VP.Width, VP.Height, AMargin, True);
end;

function TSprite3DCamera.FitToBoundsMax(const ABox: TBoundingBox;
  const AViewWidth, AViewHeight: Single; const AMargin: Single): Boolean;
begin
  Result := FitBox(ABox, nil, True, AViewWidth, AViewHeight, AMargin, True);
end;

function TSprite3DCamera.FitToBoundsMax(const AModel: TGorillaModel;
  const AMargin: Single): Boolean;
begin
  // Same box and space as FitToBounds(AModel); see the note there
  Result := Assigned(AModel) and
    FitToBoundsMax(AModel.GetAnimatedBoundingBox(), AModel, AMargin);
end;

function TSprite3DCamera.FitToBoundsMax(const AModel: TGorillaModel;
  const AViewWidth, AViewHeight: Single; const AMargin: Single): Boolean;
begin
  // Same box and space as FitToBoundsMax(AModel), for a view of a given size
  Result := Assigned(AModel) and
    FitBox(AModel.GetAnimatedBoundingBox(), AModel, False, AViewWidth,
      AViewHeight, AMargin, True);
end;

function TSprite3DCamera.FitToBoundsMax(const ABox: TBoundingBox;
  const ASpace: TControl3D; const AMargin: Single): Boolean;
var
  VP: TViewport3D;
begin
  VP := FindViewport;
  Result := (VP <> nil) and
    FitBox(ABox, ASpace, False, VP.Width, VP.Height, AMargin, True);
end;

function TSprite3DCamera.FitBox(const ABox: TBoundingBox;
  const ASpace: TControl3D; const AFromRigSpace: Boolean;
  const AViewWidth, AViewHeight, AMargin: Single;
  const AAnyAngle: Boolean): Boolean;
var
  RigParent: TFmxObject;
  Corners: TBoxCorners;
  Pivot: TPoint3D;
  UsePivot: Boolean;
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
  // Every FitToBounds and FitToBoundsMax comes through here
  if FLocked then
    Exit(False);
  Result := IsValidBox(ABox);
  if not Result then
    Exit;
  GetBoxCorners(ABox, Corners);

  // Unless the box is already in the rig parent's space, every corner is
  // carried through the transform, so a rotated box is fitted as the
  // rotated box, not as a bigger axis-aligned one.
  if not AFromRigSpace then
  begin
    RigParent := FAzimuthPivot.Parent;
    for I := 0 to High(Corners) do
      Corners[I] := ToRigSpace(Corners[I]);
  end;

  // For every angle, a box from an object is fitted about that object's
  // centre of rotation, which can lie outside the box: the camera then
  // circles the point the model turns about, which stays put however an
  // animation moves the box, instead of following the box's centre
  UsePivot := AAnyAngle and (ASpace <> nil) and not AFromRigSpace;
  if UsePivot then
    Pivot := ToRigSpace(ASpace.RotationCenter.Point)
  else
    Pivot := TPoint3D.Zero;

  Result := FitCorners(Corners, AViewWidth, AViewHeight, AMargin, AAnyAngle,
    Pivot, UsePivot);
end;

function TSprite3DCamera.FitCorners(const ACorners: array of TPoint3D;
  const AViewWidth, AViewHeight, AMargin: Single;
  const AAnyAngle: Boolean; const APivot: TPoint3D;
  const AUsePivot: Boolean): Boolean;
var
  Q: TQuat;
  M: TMatrix3D;
  AxR, AxU, AxF, Center: TPoint3D;
  SX, SY, Scale, TX, TY, Rad, K, Dist: Single;
  X, Y, Z, XMin, XMax, YMin, YMax, ZMin, ZMax: Single;
  LoX, HiX, LoY, HiY, EyeX, EyeY, EyeZ: Single;
  I: Integer;
begin
  Result := (Length(ACorners) > 0) and (AViewWidth > 0) and (AViewHeight > 0);
  if not Result then
    Exit;

  // The diagonal of the projection matrix is, per axis, 1 / tan(half-angle)
  // in perspective and 1 / (half the visible size) in orthographic mode.
  // Either way it already includes the viewport's aspect ratio and
  // Gorilla's own FOV convention, so nothing here has to assume them.
  M := GetProjectionMatrix(AViewWidth, AViewHeight, NEAR_CLEARANCE, FAR_PLANE);
  SX := Abs(M.m11);
  SY := Abs(M.m22);
  Result := (SX > EPS) and (SY > EPS);
  if not Result then
    Exit;
  Scale := 1 + Max(AMargin, 0);

  // Camera axes in the rig parent's space: right, down (FMX's up is -Y;
  // the fit is symmetric, so the sign does not matter) and view direction.
  Q := GetOrientation;
  AxR := Q.Rotate(Point3D(1, 0, 0));
  AxU := Q.Rotate(Point3D(0, 1, 0));
  AxF := Q.Rotate(Point3D(0, 0, 1));

  // Centre of the corners (the affine image of the box centre), or for an
  // every-angle fit with a pivot, the pivot; then the radius of the sphere
  // around it that reaches the farthest corner
  Center := TPoint3D.Zero;
  for I := 0 to High(ACorners) do
    Center := Center + ACorners[I];
  Center := Center * (1 / Length(ACorners));
  if AAnyAngle and AUsePivot then
    Center := APivot;
  Rad := 0;
  for I := 0 to High(ACorners) do
    Rad := Max(Rad, (ACorners[I] - Center).Length);

  if AAnyAngle then
  begin
    // Every Azimuth / PolarAngle / Roll together reach every orientation,
    // so the box can take any rotation about the orbit centre. The union
    // of those rotations is the ball of radius Rad about Center, so that
    // ball is fitted, centred, with the orbit centre on Center: the
    // object's centre of rotation if there is one, otherwise the box's.
    if IsOrthographic then
    begin
      // Scale the visible area until its narrower half-size holds the radius
      K := Rad * Scale * Max(SX, SY);
      Dist := Rad + Max(Rad, NEAR_CLEARANCE);
    end
    else
    begin
      // Ball tangent to the narrower pair of frustum planes, narrowed by
      // the margin: Distance = Rad / sin(half'), tan(half') = 1 / (S * Scale)
      K := 0;
      Dist := Rad * Sqrt(1 + Sqr(Max(SX, SY) * Scale));
      Dist := Max(Dist, Rad + NEAR_CLEARANCE);
    end;
  end
  else
  begin
    // Corners in camera axes. Positions are measured from the rig parent's
    // origin; only differences matter, so no common origin is needed.
    XMin := MaxSingle;  XMax := -MaxSingle;
    YMin := MaxSingle;  YMax := -MaxSingle;
    ZMin := MaxSingle;  ZMax := -MaxSingle;
    LoX := -MaxSingle;  HiX := MaxSingle;
    LoY := -MaxSingle;  HiY := MaxSingle;
    TX := 1 / (SX * Scale);   // tan of the usable half-angles
    TY := 1 / (SY * Scale);
    for I := 0 to High(ACorners) do
    begin
      X := ACorners[I].DotProduct(AxR);
      Y := ACorners[I].DotProduct(AxU);
      Z := ACorners[I].DotProduct(AxF);
      XMin := Min(XMin, X);  XMax := Max(XMax, X);
      YMin := Min(YMin, Y);  YMax := Max(YMax, Y);
      ZMin := Min(ZMin, Z);  ZMax := Max(ZMax, Z);
      // Perspective: a corner is inside the frustum of an eye at
      // (EyeX, EyeY, EyeZ) when |X - EyeX| <= TX * (Z - EyeZ), i.e.
      // EyeX - TX * EyeZ >= X - TX * Z  and  EyeX + TX * EyeZ <= X + TX * Z.
      LoX := Max(LoX, X - TX * Z);
      HiX := Min(HiX, X + TX * Z);
      LoY := Max(LoY, Y - TY * Z);
      HiY := Min(HiY, Y + TY * Z);
    end;

    if IsOrthographic then
    begin
      // Centre on the box; scale the visible area so the tighter axis
      // just holds it. Distance only has to keep the camera clear of it.
      K := Max((XMax - XMin) * SX, (YMax - YMin) * SY) * 0.5 * Scale;
      Center := AxR * ((XMin + XMax) * 0.5) + AxU * ((YMin + YMax) * 0.5) +
        AxF * ((ZMin + ZMax) * 0.5);
      Dist := (ZMax - ZMin) * 0.5 + Max(Rad, NEAR_CLEARANCE);
    end
    else
    begin
      // Farthest-forward eye that holds every corner on each axis; the
      // smaller of the two holds them on both. Halfway between the bounds
      // centres the box with equal room either side. Then keep the near
      // plane clear of the nearest corner.
      K := 0;
      EyeZ := Min((HiX - LoX) / (2 * TX), (HiY - LoY) / (2 * TY));
      EyeZ := Min(EyeZ, ZMin - NEAR_CLEARANCE);
      EyeX := (LoX + HiX) * 0.5;
      EyeY := (LoY + HiY) * 0.5;
      // Orbit round the point on the view axis level with the box's middle
      Dist := (ZMin + ZMax) * 0.5 - EyeZ;
      Center := AxR * EyeX + AxU * EyeY + AxF * (EyeZ + Dist);
    end;
  end;

  if IsOrthographic and (K > EPS) then
  begin
    // Visible size is proportional to OrthoHeight (and to OrthoWidth when
    // one is set), so scaling them by K scales the visible area by K.
    OrthoHeight := OrthoHeight * K;
    if OrthoWidth > 0 then
      OrthoWidth := OrthoWidth * K;
  end;

  FAzimuthPivot.Position.Point := Center;
  Distance := Dist;
end;

function TSprite3DCamera.FitPointsOnAxis(const APoints: array of TPoint3D;
  const ALinePoint, ALineDirection: TPoint3D; const ASpace: TControl3D;
  const AMargin: Single): Boolean;
var
  VP: TViewport3D;
begin
  VP := FindViewport;
  Result := (VP <> nil) and FitOnAxis(APoints, ALinePoint, ALineDirection, ASpace,
    VP.Width, VP.Height, AMargin);
end;

function TSprite3DCamera.FitPointsOnAxis(const APoints: array of TPoint3D;
  const ALinePoint, ALineDirection: TPoint3D; const ASpace: TControl3D;
  const AViewWidth, AViewHeight: Single; const AMargin: Single): Boolean;
begin
  Result := FitOnAxis(APoints, ALinePoint, ALineDirection, ASpace, AViewWidth,
    AViewHeight, AMargin);
end;

function TSprite3DCamera.FitOnAxis(const APoints: array of TPoint3D;
  const ALinePoint, ALineDirection: TPoint3D; const ASpace: TControl3D;
  const AViewWidth, AViewHeight, AMargin: Single): Boolean;
var
  RigParent: TFmxObject;
  Rig: TArray<TPoint3D>;
  LinePoint, LineDir, Center, AxF, W: TPoint3D;
  B, D, E, Denom, S: Single;
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
  if FLocked then
    Exit(False);
  Result := Length(APoints) > 0;
  if not Result then
    Exit;

  RigParent := FAzimuthPivot.Parent;
  SetLength(Rig, Length(APoints));
  for I := 0 to High(APoints) do
    Rig[I] := ToRigSpace(APoints[I]);
  LinePoint := ToRigSpace(ALinePoint);
  LineDir := ToRigSpace(ALinePoint + ALineDirection) - LinePoint;

  // The view FitToBounds would give the points: as large as they will go,
  // centred, for the current angles
  Result := FitCorners(Rig, AViewWidth, AViewHeight, AMargin, False, TPoint3D.Zero, False);
  if not Result or (LineDir.Length < EPS) then
    Exit;
  LineDir := LineDir.Normalize;

  // Slide the orbit centre along the view axis to the point nearest the
  // line, and the distance with it, so the camera does not move. With the
  // ray C + s F and the line P + t L (both unit), the nearest s is
  // (b e - d) / (1 - b * b), with b = F.L, d = F.(C - P), e = L.(C - P).
  Center := FAzimuthPivot.Position.Point;
  AxF := GetOrientation.Rotate(Point3D(0, 0, 1));
  W := Center - LinePoint;
  B := AxF.DotProduct(LineDir);
  D := AxF.DotProduct(W);
  E := LineDir.DotProduct(W);
  Denom := 1 - B * B;
  if Denom < EPS then
    Exit;   // looking along the line: any centre on the view axis will do
  S := (B * E - D) / Denom;
  if Distance + S < NEAR_CLEARANCE then
    Exit;   // the line is behind or right in front of the camera
  FAzimuthPivot.Position.Point := Center + AxF * S;
  Distance := Distance + S;
end;

function TSprite3DCamera.ProjectToView(const APoint: TPoint3D; const ASpace: TControl3D;
  const AViewWidth, AViewHeight: Single; out AX, AY: Single): Boolean;
var
  M: TMatrix3D;
  Q: TQuat;
  P, D: TPoint3D;
  SX, SY, X, Y, Z: Single;
  RigParent: TFmxObject;
begin
  AX := 0;
  AY := 0;
  Result := False;
  if (AViewWidth <= 0) or (AViewHeight <= 0) then
    Exit;
  M := GetProjectionMatrix(AViewWidth, AViewHeight, NEAR_CLEARANCE, FAR_PLANE);
  SX := Abs(M.m11);
  SY := Abs(M.m22);
  if (SX < EPS) or (SY < EPS) then
    Exit;
  // Into the rig parent's space, as FitBox carries a box's corners
  if ASpace <> nil then
    P := ASpace.LocalToAbsolute3D(APoint)
  else
    P := APoint;
  RigParent := FAzimuthPivot.Parent;
  if (ASpace <> nil) and (RigParent is TControl3D) then
    P := TControl3D(RigParent).AbsoluteToLocal3D(P);
  // In the camera's axes: right, down (FMX's up is -Y) and the view direction
  Q := GetOrientation;
  D := P - CameraPosition;
  X := D.DotProduct(Q.Rotate(Point3D(1, 0, 0)));
  Y := D.DotProduct(Q.Rotate(Point3D(0, 1, 0)));
  Z := D.DotProduct(Q.Rotate(Point3D(0, 0, 1)));
  // The diagonal is 1 / tan(half-angle) in perspective, and 1 / (half the
  // visible size) in orthographic mode, per axis
  if not IsOrthographic then
  begin
    if Z < EPS then
      Exit;   // at or behind the eye
    X := X / Z;
    Y := Y / Z;
  end;
  AX := (1 + X * SX) * AViewWidth / 2;
  AY := (1 + Y * SY) * AViewHeight / 2;
  Result := True;
end;

procedure TSprite3DCamera.ShiftView(const ARight, AUp, AViewWidth, AViewHeight: Single);
var
  M: TMatrix3D;
  SX, SY, PX, PY: Single;
  Q: TQuat;
begin
  if (AViewWidth <= 0) or (AViewHeight <= 0) or ((ARight = 0) and (AUp = 0)) then
    Exit;
  // The projection's diagonal is 1 / tan(half-angle) in perspective and
  // 1 / (half the visible size) in orthographic mode, so one pixel measures
  // 2 * Distance / (S * size) at the orbit centre, or 2 / (S * size)
  M := GetProjectionMatrix(AViewWidth, AViewHeight, NEAR_CLEARANCE, FAR_PLANE);
  SX := Abs(M.m11);
  SY := Abs(M.m22);
  if (SX < EPS) or (SY < EPS) then
    Exit;
  if IsOrthographic then
  begin
    PX := 2 / (SX * AViewWidth);
    PY := 2 / (SY * AViewHeight);
  end
  else
  begin
    PX := 2 * FDistance / (SX * AViewWidth);
    PY := 2 * FDistance / (SY * AViewHeight);
  end;
  // The camera's right, and its up, which is FMX's -Y
  Q := GetOrientation;
  FAzimuthPivot.Position.Point := FAzimuthPivot.Position.Point +
    Q.Rotate(Point3D(1, 0, 0)) * (ARight * PX) - Q.Rotate(Point3D(0, 1, 0)) * (AUp * PY);
end;

procedure TSprite3DCamera.LookAt(const APoint: TPoint3D; const AMode: TLookAtMode);
var
  Q, Turn: TQuat;
  Eye, Diff, FromDir, ToDir, UpDir: TPoint3D;
  Len: Single;
begin
  if FLocked then
    Exit;
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
  if FLocked then
    Exit;
  // Keep it in [0, 360) so it doesn't grow unbounded while orbiting
  FAzimuth := Value - 360 * Floor(Value / 360);
  UpdatePivots;
end;

procedure TSprite3DCamera.SetPolarAngle(const Value: Single);
begin
  if FLocked then
    Exit;
  FPolarAngle := Value;  // unrestrained
  UpdatePivots;
end;

procedure TSprite3DCamera.SetRoll(const Value: Single);
begin
  if FLocked then
    Exit;
  FRoll := Value;
  UpdatePivots;
end;

procedure TSprite3DCamera.SetDistance(const Value: Single);
begin
  if FLocked then
    Exit;
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
  if FLocked then
    Exit;
  FAzimuth := FAzimuth + DeltaAzimuth;
  FAzimuth := FAzimuth - 360 * Floor(FAzimuth / 360);
  FPolarAngle := FPolarAngle + DeltaPolar;
  UpdatePivots;
end;

procedure TSprite3DCamera.Zoom(const Factor: Single);
begin
  if FLocked then
    Exit;
  if Factor > 0 then
    Distance := FDistance * Factor;
end;

procedure TSprite3DCamera.MoveCenterTo(const APoint: TPoint3D);
begin
  if FLocked then
    Exit;
  FAzimuthPivot.Position.Point := APoint;
end;

initialization
  RegisterFmxClasses([TSprite3DCamera]);

end.
