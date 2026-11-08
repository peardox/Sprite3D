//** @abstract(Getting at the matrices FireMonkey draws a 3D scene with - the projection and
//** the camera (view) matrix - from outside FMX, and changing them while a frame is drawn.)
//**
//** FMX keeps the projection a TContext3D draws with in private fields: CurrentProjectionMatrix
//** can be read, but nothing public sets it, and TViewport3D builds it from the camera's angle
//** of view. Gorilla3D draws with what FMX gives it (its author, November 2026), so a camera of
//** ours has no say. This unit finds where the matrices really are and writes them there:
//**
//** @unorderedList(
//**   @item(TSpritelyProjectionAccess.Survey draws one frame and, from inside it, reads the
//**     context's public matrices; then it looks through the memory of the context, the
//**     viewport, the cameras and the objects they hold for a copy of each - a 4 x 4 block of
//**     Singles equal to it, or one shaped like a perspective projection. RTTI is not needed
//**     to find them (FMX and Gorilla3D may be compiled without field RTTI), only to name them
//**     where it is there. Each find is a TSpritelyMatrixSlot.)
//**   @item(TSpritelyRenderHook is an empty 3D object put first in the viewport, so FMX calls it
//**     once the frame has set its matrices and before any model is drawn: the place to
//**     change them for that frame.)
//**   @item(SetAdjust chooses what to change and how - a slot (the projection or the camera
//**     matrix), the public SetCameraMatrix, or the public SetRenderToMatrix - and the change
//**     is made in the hook (InRender) or by ApplyNow, between frames. RestoreAll puts back
//**     what was changed.)
//** )
//**
//** The helpers at the end (ShiftProjection, ShearForShift, ClipShift) make the matrices for a
//** lens shift and rise: the picture moved across the lens, the camera standing still.
//**
//** TSpritelyProjection, the component, puts it to use: perspective with any lens (and the
//** dolly zoom), orthographic, and the oblique projections - cavalier, cabinet, military or
//** any angle and scale - each with a lens shift and rise, written into FMX's projection
//** inside every frame. TSpritelyProjectionAccess is the general tool underneath, kept for
//** tests and for other matrices (the ProjectionTest program surveys and measures with it).
//**
//** Found with the ProjectionTest program (8 November 2026): the projection is cached in
//** TContext3D.FProjectionMatrix, written once it stays until FMX makes it again, and FMX's
//** public SetRenderToMatrix does not change the picture.
unit Spritely.Projection;

{
  Getting at the matrices FireMonkey draws a 3D scene with (projection and
  camera) from outside FMX: Survey finds where they are kept by their
  values, from inside a frame (TSpritelyRenderHook, an empty object first in
  the viewport); SetAdjust and the hook or ApplyNow change them, RestoreAll
  puts them back. Helpers make a lens shift / rise, orthographic, oblique
  and new-lens projections. TSpritelyProjection is the component: any of
  them, with shift and rise and the dolly zoom, written in every frame.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math, System.Math.Vectors,
  System.Generics.Collections, System.Rtti, System.TypInfo,
  FMX.Types, FMX.Types3D, FMX.Controls, FMX.Controls3D, Gorilla.Viewport;

const
  //** @abstract(How near two matrix entries must be to count as the same: a share of the larger,
  //** or this much when both are under 1.)
  SPRITELY_MATRIX_TOLERANCE = 1E-5;
  //** @abstract(The most objects Survey looks through, so a long chain of references cannot make
  //** it slow.)
  SPRITELY_MATRIX_MAX_SCAN_OBJECTS = 64;
  //** @abstract(An object larger than this, in bytes, is not looked through: no context or
  //** camera is that large, so it is taken as a bad reference.)
  SPRITELY_MATRIX_MAX_INSTANCE = 1 shl 20;
  //** @abstract(TSpritelyProjection's Distance until it is set: the target plane's distance
  //** without a Focus.)
  SPRITELY_PROJECTION_DEFAULT_DISTANCE = 10;
  //** @abstract(The field of view taken as the camera's own until a frame has shown it,
  //** degrees: FMX's and Gorilla3D's default.)
  SPRITELY_PROJECTION_DEFAULT_FOV = 45;
  //** @abstract(TSpritelyProjection's ObliqueAngle until it is set, degrees.)
  SPRITELY_PROJECTION_OBLIQUE_ANGLE = 45;
  //** @abstract(TSpritelyProjection's ObliqueScale until it is set.)
  SPRITELY_PROJECTION_OBLIQUE_SCALE = 1;
  //** @abstract(The cabinet projection's angle, degrees: receding lines at 2 in 1, ArcTan(2).)
  SPRITELY_PROJECTION_CABINET_ANGLE = 63.43;
  //** @abstract(The plan oblique projection's angle, degrees: depth (down, looking from above)
  //** drawn down and to the right, so height goes up and to the left.)
  SPRITELY_PROJECTION_PLAN_OBLIQUE_ANGLE = 315;
  //** @abstract(The true isometric camera's inclination, degrees: ArcTan(1 / Sqrt(2)), so the
  //** three axes are drawn equally foreshortened, 120 degrees apart.)
  SPRITELY_PROJECTION_ISOMETRIC_INCLINATION = 35.264;
  //** @abstract(The 2:1 dimetric camera's inclination, degrees: ArcSin(1 / 2), so a square on
  //** the ground is drawn twice as wide as it is high - the "isometric" of pixel art.)
  SPRITELY_PROJECTION_DIMETRIC_INCLINATION = 30;

type
  //** @abstract(Points at a matrix kept inside an object.)
  TSpritelyMatrixPtr = ^TMatrix3D;

  //** @abstract(What a slot holds, by how Survey recognised it.)
  TSpritelyMatrixKind = (
    //** Equal to the context's CurrentProjectionMatrix, as read inside the frame
    mkProjection,
    //** Shaped like a perspective projection but not equal to the context's
    mkProjectionLike,
    //** Equal to the context's CurrentCameraMatrix (the view matrix)
    mkCamera,
    //** Equal to the context's CurrentCameraInvMatrix
    mkCameraInverse);

  //** @abstract(What SetAdjust changes.)
  TSpritelyAdjustTarget = (
    //** Nothing
    atNone,
    //** A projection slot, written in memory
    atProjectionSlot,
    //** A camera slot, written in memory (and its inverse, when one was found beside it)
    atCameraSlot,
    //** The camera matrix, through the context's public SetCameraMatrix
    atSetCameraMatrix,
    //** The context's public SetRenderToMatrix (its own value is not readable, so the change is
    //** made from the identity)
    atRenderToMatrix);

  //** @abstract(Makes a changed matrix from the one in use.)
  //**
  //** @param(AMatrix The matrix as FMX made it, before any change of ours.)
  //** @param(AContext The context drawing the frame.)
  //** @returns(The matrix to draw with.)
  TSpritelyMatrixAdjust = reference to function(const AMatrix: TMatrix3D;
    AContext: TContext3D): TMatrix3D;

  //** @abstract(Where log lines go.)
  //**
  //** @param(AText The line.)
  TSpritelyLogProc = reference to procedure(const AText: string);

  //** @abstract(Called by TSpritelyRenderHook when FMX draws it: inside a frame, before the
  //** models.)
  //**
  //** @param(Sender The hook.)
  //** @param(AContext The context drawing the frame.)
  TSpritelyRenderHookEvent = procedure(Sender: TObject; AContext: TContext3D) of object;

  //** @abstract(Remembers a matrix's own value while ours is written over it, so it can be put
  //** back, and notices when FMX has made it again.)
  //**
  //** The value read is taken as FMX's own unless it is still the one last written: then FMX has
  //** not touched it since, and the value kept from before is FMX's.
  TSpritelyCleanTracker = record
  private
    //** @abstract(FMX's own value, as last seen.)
    FClean: TMatrix3D;
    //** @abstract(The value last written.)
    FLast: TMatrix3D;
    //** @abstract(Whether anything has been written since Reset.)
    FWritten: Boolean;
  public
    //** @abstract(FMX's own value.)
    //**
    //** @param(ACurrent The value there now.)
    //** @returns(ACurrent, unless it is the one last written; then the value from before.)
    function Clean(const ACurrent: TMatrix3D): TMatrix3D;
    //** @abstract(Notes a write.)
    //**
    //** @param(AValue What was written.)
    procedure Wrote(const AValue: TMatrix3D);
    //** @abstract(Forgets every write.)
    procedure Reset;
    //** @abstract(Whether anything has been written since Reset.)
    property Written: Boolean read FWritten;
    //** @abstract(FMX's own value, as last seen.)
    property CleanValue: TMatrix3D read FClean;
    //** @abstract(The value last written.)
    property LastValue: TMatrix3D read FLast;
  end;

  //** @abstract(A matrix kept inside an object: where it is, what it was taken for, and how to
  //** write it and put it back.)
  TSpritelyMatrixSlot = class
  private
    //** @abstract(The object the matrix is in.)
    FHolder: TObject;
    //** @abstract(Bytes from the start of the object.)
    FOffset: Integer;
    //** @abstract(What it was taken for.)
    FKind: TSpritelyMatrixKind;
    //** @abstract(The field's name from RTTI, or empty.)
    FName: string;
    //** @abstract(How Survey reached the object, e.g. 'render context'.)
    FWhere: string;
    //** @abstract(FMX's own value while ours is written.)
    FTracker: TSpritelyCleanTracker;
    //** @abstract(Where the matrix is in memory.)
    //**
    //** @returns(The holder's address plus the offset.)
    function Address: TSpritelyMatrixPtr;
  public
    //** @abstract(Makes a slot.)
    //**
    //** @param(AHolder The object the matrix is in.)
    //** @param(AOffset Bytes from the start of the object.)
    //** @param(AKind What it was taken for.)
    //** @param(AName The field's name, or empty.)
    //** @param(AWhere How the object was reached.)
    constructor Create(AHolder: TObject; AOffset: Integer; AKind: TSpritelyMatrixKind;
      const AName, AWhere: string);
    //** @abstract(Reads the matrix there now.)
    //**
    //** @returns(The matrix.)
    function Read: TMatrix3D;
    //** @abstract(Writes a matrix there, without noting it: Apply is the way to change it.)
    //**
    //** @param(AValue The matrix.)
    procedure Write(const AValue: TMatrix3D);
    //** @abstract(FMX's own value, even while ours is written.)
    //**
    //** @returns(The matrix FMX made.)
    function CleanValue: TMatrix3D;
    //** @abstract(Writes a matrix there and notes it, so Restore can put FMX's back.)
    //**
    //** @param(AValue The matrix.)
    procedure Apply(const AValue: TMatrix3D);
    //** @abstract(Puts FMX's value back if ours is still there.)
    //**
    //** @returns(True if it wrote anything.)
    function Restore: Boolean;
    //** @abstract(What is there now, for the log.)
    //**
    //** @returns('ours' (the value last written), 'FMX''s' (its own) or 'changed' (neither).)
    function State: string;
    //** @abstract(One line for the log: where, offset, name and kind.)
    //**
    //** @returns(The line.)
    function Describe: string;
    //** @abstract(The object the matrix is in.)
    property Holder: TObject read FHolder;
    //** @abstract(Bytes from the start of the object.)
    property Offset: Integer read FOffset;
    //** @abstract(What it was taken for.)
    property Kind: TSpritelyMatrixKind read FKind;
    //** @abstract(The field's name from RTTI, or empty.)
    property Name: string read FName;
    //** @abstract(How Survey reached the object.)
    property Where: string read FWhere;
  end;

  //** @abstract(An empty 3D object that calls OnRenderBegin each time FMX draws it.)
  //**
  //** Put first among the viewport's children, it is drawn once the frame's camera and
  //** projection are set and before the models: the place to change them for that frame. It
  //** draws nothing. Gorilla3D culls by bounds when FrustumCulling is on, so give it the
  //** model's place and size.
  TSpritelyRenderHook = class(TControl3D)
  private
    //** @abstract(Called each time FMX draws the hook.)
    FOnRenderBegin: TSpritelyRenderHookEvent;
    //** @abstract(How many times FMX has drawn the hook.)
    FCalls: Integer;
  protected
    //** @abstract(Counts the call and calls OnRenderBegin; draws nothing.)
    procedure Render; override;
  public
    //** @abstract(Makes the hook: not stored, not hit by the mouse.)
    //**
    //** @param(AOwner The owner.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(How many times FMX has drawn the hook; may be set, e.g. to 0.)
    property Calls: Integer read FCalls write FCalls;
    //** @abstract(Called each time FMX draws the hook, inside the frame.)
    property OnRenderBegin: TSpritelyRenderHookEvent read FOnRenderBegin write FOnRenderBegin;
  end;

  //** @abstract(Finds the matrices a viewport draws with, and changes them inside the frame or
  //** between frames.)
  //**
  //** Made in code with the viewport (anything that is an IViewport3D: TViewport3D,
  //** TGorillaViewport). It puts a TSpritelyRenderHook first in the viewport. Survey before
  //** anything else, and again after the viewport's size or the camera's lens changes, or
  //** if the context may have been made again.
  TSpritelyProjectionAccess = class(TComponent)
  private
    //** @abstract(The viewport.)
    FViewport: TFmxObject;
    //** @abstract(The hook in the viewport; nil once the viewport has freed it.)
    FHook: TSpritelyRenderHook;
    //** @abstract(What the last Survey found.)
    FSlots: TObjectList<TSpritelyMatrixSlot>;
    //** @abstract(Where log lines go; may be nil.)
    FOnLog: TSpritelyLogProc;
    //** @abstract(True while Survey's frame is drawn: the hook then looks round.)
    FSurveying: Boolean;
    //** @abstract(Whether a Survey has been made.)
    FSurveyed: Boolean;
    //** @abstract(Whether the hook was called in Survey's frame.)
    FHookSeen: Boolean;
    //** @abstract(The context the hook saw in Survey's frame, or the viewport's if none.)
    FRenderContext: TContext3D;
    //** @abstract(CurrentProjectionMatrix inside Survey's frame.)
    FInsideProjection: TMatrix3D;
    //** @abstract(CurrentCameraMatrix inside Survey's frame.)
    FInsideCamera: TMatrix3D;
    //** @abstract(CurrentCameraInvMatrix inside Survey's frame.)
    FInsideCameraInverse: TMatrix3D;
    //** @abstract(CurrentProjectionMatrix after Survey's frame, outside it.)
    FOutsideProjection: TMatrix3D;
    //** @abstract(CurrentCameraMatrix after Survey's frame, outside it.)
    FOutsideCamera: TMatrix3D;
    //** @abstract(More objects for Survey to look through: the cameras.)
    FExtra: TArray<TObject>;
    //** @abstract(CurrentProjectionMatrix at each call of the hook in Survey's frame: a renderer
    //** that draws more than once a frame (a shadow pass) shows here.)
    FSurveyProjections: TArray<TMatrix3D>;
    //** @abstract(The objects looked through so far in this Survey.)
    FScanned: TList<TObject>;
    //** @abstract(What is changed.)
    FTarget: TSpritelyAdjustTarget;
    //** @abstract(The slot changed, for atProjectionSlot and atCameraSlot.)
    FTargetSlot: TSpritelyMatrixSlot;
    //** @abstract(The camera inverse slot changed with FTargetSlot, or nil.)
    FInverseSlot: TSpritelyMatrixSlot;
    //** @abstract(Makes the changed matrix.)
    FAdjust: TSpritelyMatrixAdjust;
    //** @abstract(True: the hook makes the change in each frame.)
    FInRender: Boolean;
    //** @abstract(The camera matrix's own value while SetCameraMatrix has ours.)
    FCameraTracker: TSpritelyCleanTracker;
    //** @abstract(The context last given a render-to matrix of ours, or nil.)
    FRenderToContext: TContext3D;
    //** @abstract(The hook's call: Survey's look round, then the change if InRender.)
    //**
    //** @param(Sender The hook.)
    //** @param(AContext The context drawing the frame.)
    procedure HookRender(Sender: TObject; AContext: TContext3D);
    //** @abstract(Sends a line to OnLog.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: string);
    //** @abstract(Looks through the contexts, the viewport, FExtra and what the contexts and
    //** viewport hold.)
    //**
    //** @param(AContext The context drawing the frame.)
    procedure ScanAll(AContext: TContext3D);
    //** @abstract(Looks through one object's memory for the matrices.)
    //**
    //** @param(AObject The object; nil or one already seen is skipped.)
    //** @param(AWhere How it was reached, for the log.)
    procedure ScanObject(AObject: TObject; const AWhere: string);
    //** @abstract(Looks through the objects an object holds in its fields, where RTTI lists
    //** them; not FMX controls.)
    //**
    //** @param(AObject The object.)
    //** @param(AWhere How it was reached, for the log.)
    procedure FollowFields(AObject: TObject; const AWhere: string);
    //** @abstract(Says what a block of memory is, if it is one of the matrices.)
    //**
    //** @param(AMatrix The 16 Singles.)
    //** @param(AKind What it is.)
    //** @returns(True if it is one.)
    function Classify(const AMatrix: TMatrix3D; out AKind: TSpritelyMatrixKind): Boolean;
    //** @abstract(Makes the change chosen by SetAdjust.)
    //**
    //** @param(AContext The context to change; nil does nothing for the public routes.)
    procedure ApplyTo(AContext: TContext3D);
  protected
    //** @abstract(Lets go of the hook when the viewport frees it.)
    //**
    //** @param(AComponent The component going.)
    //** @param(Operation opRemove when it goes.)
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    //** @abstract(Makes the access and puts its hook first in the viewport.)
    //**
    //** @param(AOwner The owner.)
    //** @param(AViewport The viewport: anything that is an IViewport3D.)
    constructor Create(AOwner: TComponent; AViewport: TFmxObject); reintroduce;
    //** @abstract(Takes the hook out of the viewport. Changes are not put back: call RestoreAll
    //** first while the context is still there.)
    destructor Destroy; override;
    //** @abstract(The viewport's context.)
    //**
    //** @returns(The context, or nil.)
    function Context: TContext3D;
    //** @abstract(Draws one frame and finds the matrices it is drawn with.)
    //**
    //** Any change is put back and SetAdjust cleared first, as the slots are made again.
    //**
    //** @param(ARender Draws one frame, e.g. TGorillaViewport.RenderManual.)
    //** @param(AExtra More objects to look through, e.g. the cameras.)
    procedure Survey(const ARender: TProc; const AExtra: array of TObject);
    //** @abstract(Writes what the last Survey found to the log.)
    procedure LogSurvey;
    //** @abstract(The first slot of a kind.)
    //**
    //** @param(AKind The kind.)
    //** @returns(The slot, or nil.)
    function FirstSlot(AKind: TSpritelyMatrixKind): TSpritelyMatrixSlot;
    //** @abstract(The camera inverse slot in the same object as a camera slot.)
    //**
    //** @param(ASlot The camera slot.)
    //** @returns(The inverse slot, or nil.)
    function InverseFor(ASlot: TSpritelyMatrixSlot): TSpritelyMatrixSlot;
    //** @abstract(Chooses what to change and how; RestoreAll is not called, so call it before
    //** choosing another.)
    //**
    //** @param(ATarget What to change; atNone stops changing.)
    //** @param(ASlot The slot, for atProjectionSlot and atCameraSlot.)
    //** @param(AInverse The camera inverse slot to change with a camera slot, or nil.)
    //** @param(AAdjust Makes the changed matrix from FMX's own.)
    //** @param(AInRender True: the hook makes the change in every frame; False: only ApplyNow.)
    procedure SetAdjust(ATarget: TSpritelyAdjustTarget; ASlot, AInverse: TSpritelyMatrixSlot;
      const AAdjust: TSpritelyMatrixAdjust; AInRender: Boolean);
    //** @abstract(Makes the change now, outside a frame, in the viewport's context.)
    procedure ApplyNow;
    //** @abstract(Puts back everything changed, where it is still ours.)
    procedure RestoreAll;
    //** @abstract(Drops the slots, for when their objects may have gone (the view resized, the
    //** context made again): a slot in the viewport's present context is still put back first,
    //** as that object is alive, and the public render-to matrix too. Survey again before
    //** using a slot.)
    //**
    //** Without putting the projection back, the next Survey takes our own projection for
    //** FMX's (owner's ProjTest4 log: a resize while the military view was on).
    procedure Forget;
    //** @abstract(The general way to set the projection: AAdjust makes the projection to draw
    //** with from FMX's own, and it is written into FMX's projection field - in each frame, or
    //** by ApplyNow - until SetAdjust(atNone, ...) and RestoreAll.)
    //**
    //** @param(AAdjust Makes the projection, e.g. Oblique, ShiftProjection or both.)
    //** @param(AInRender True to write it in each frame (survives FMX making it again).)
    //** @returns(False if Survey found no projection.)
    function AdjustProjection(const AAdjust: TSpritelyMatrixAdjust; AInRender: Boolean): Boolean;
    //** @abstract(Whether two matrices are the same, entry by entry.)
    //**
    //** @param(A One.)
    //** @param(B The other.)
    //** @returns(True if every entry is within SPRITELY_MATRIX_TOLERANCE.)
    class function SameMatrix(const A, B: TMatrix3D): Boolean; static;
    //** @abstract(Whether a matrix is shaped like a perspective projection, either way round.)
    //**
    //** @param(M The matrix.)
    //** @returns(True if it is.)
    class function IsPerspectiveLike(const M: TMatrix3D): Boolean; static;
    //** @abstract(Whether a projection is laid out for row vectors, FMX's way (w taken from the
    //** fourth column), rather than column vectors.)
    //**
    //** @param(P The projection.)
    //** @returns(True for row vectors.)
    class function RowLayout(const P: TMatrix3D): Boolean; static;
    //** @abstract(A projection with its picture moved across the lens: a lens shift and rise.)
    //**
    //** The window of the projection slides by (ASX, ASY) in normalised device units (the whole
    //** picture is 2 wide and 2 high): x_ndc + ASX, y_ndc + ASY. Perspective is unchanged.
    //**
    //** @param(P The projection.)
    //** @param(ASX Shift, + moves the picture right.)
    //** @param(ASY Rise, + moves the picture up in normalised device units.)
    //** @returns(The shifted projection.)
    class function ShiftProjection(const P: TMatrix3D; ASX, ASY: Single): TMatrix3D; static;
    //** @abstract(The view-space shear that moves the picture as ShiftProjection does, for the
    //** camera matrix: multiply the view matrix by it, View * Shear.)
    //**
    //** As an off-axis (stereo) view can be made: x + kx z, y + ky z. Lighting worked out in
    //** view space sees the shear.
    //**
    //** @param(P The projection drawn with.)
    //** @param(ASX Shift in normalised device units.)
    //** @param(ASY Rise in normalised device units.)
    //** @returns(The shear.)
    class function ShearForShift(const P: TMatrix3D; ASX, ASY: Single): TMatrix3D; static;
    //** @abstract(The matrix that moves a picture after the projection, in clip space: for
    //** SetRenderToMatrix.)
    //**
    //** @param(ASX Shift in normalised device units.)
    //** @param(ASY Rise in normalised device units.)
    //** @param(ARowLayout True for row vectors (FMX's), False for the transpose.)
    //** @returns(The matrix.)
    class function ClipShift(ASX, ASY: Single; ARowLayout: Boolean): TMatrix3D; static;
    //** @abstract(A matrix on one line, row by row, for the log.)
    //**
    //** @param(M The matrix.)
    //** @returns(The line.)
    class function MatrixText(const M: TMatrix3D): string; static;
    //** @abstract(The near and far planes of an FMX perspective projection.)
    //**
    //** FMX builds it Direct3D's way, right-handed, depth 0 at the near plane and 1 at the far:
    //** m33 = f / (n - f), m43 = n f / (n - f); so n = m43 / m33 and f = m43 / (m33 + 1).
    //**
    //** @param(P The perspective, row vectors.)
    //** @param(ANear The near plane's distance.)
    //** @param(AFar The far plane's distance.)
    //** @returns(False if P is not such a perspective.)
    class function DepthRange(const P: TMatrix3D; out ANear, AFar: Single): Boolean; static;
    //** @abstract(An orthographic projection showing at every depth what a perspective shows at
    //** ADistance: the view's size, aspect and depth range kept.)
    //**
    //** @param(P FMX's perspective, row vectors.)
    //** @param(ADistance Where the two agree: the orbit camera's distance to its target.)
    //** @returns(The orthographic projection; P itself if it is not a perspective.)
    class function Orthographic(const P: TMatrix3D; ADistance: Single): TMatrix3D; static;
    //** @abstract(An oblique (parallel) projection: Orthographic with depth drawn across the
    //** picture.)
    //**
    //** A point ADepth further from the camera than the target plane is drawn AScale * ADepth
    //** away in the picture's direction AAngle (degrees, 0 right, 90 up), so the target plane
    //** keeps its true shape and depth recedes along that line. Cavalier is scale 1 at 45
    //** degrees, cabinet 0.5 at 63.4 (or 45), military (planometric) 1 at 270 with the
    //** camera looking straight down. Depth is unchanged, so the depth buffer still works.
    //**
    //** @param(P FMX's perspective, row vectors.)
    //** @param(ADistance The target plane's distance from the camera.)
    //** @param(AScale How long receding depth is drawn, 1 its true length.)
    //** @param(AAngle The direction receding depth is drawn, degrees.)
    //** @returns(The oblique projection; P itself if it is not a perspective.)
    class function Oblique(const P: TMatrix3D; ADistance, AScale, AAngle: Single): TMatrix3D;
      static;
    //** @abstract(A perspective with another field of view: the lens changed, nothing else.)
    //**
    //** x and y are scaled alike, so the aspect is kept; depth and any shift are unchanged.
    //** With the camera moved to keep Distance * tan(AFieldOfView / 2) the same, this is the
    //** dolly zoom (the target plane keeps its size, the perspective changes).
    //**
    //** @param(P The perspective, row vectors.)
    //** @param(AFieldOfView The vertical field of view, degrees, over 0 and under 180.)
    //** @returns(The perspective; P itself if it is not one or the angle is out of range.)
    class function WithFieldOfView(const P: TMatrix3D; AFieldOfView: Single): TMatrix3D; static;
    //** @abstract(The vertical field of view of a perspective.)
    //**
    //** @param(P The perspective, row vectors.)
    //** @returns(Degrees; 0 if P is not a perspective.)
    class function FieldOfView(const P: TMatrix3D): Single; static;
    //** @abstract(The hook; nil once the viewport has freed it.)
    property Hook: TSpritelyRenderHook read FHook;
    //** @abstract(What the last Survey found, in the order found.)
    property Slots: TObjectList<TSpritelyMatrixSlot> read FSlots;
    //** @abstract(Whether a Survey has been made.)
    property Surveyed: Boolean read FSurveyed;
    //** @abstract(Whether the hook was called in Survey's frame; if not, the matrices were read
    //** after it, outside.)
    property HookSeen: Boolean read FHookSeen;
    //** @abstract(The context the hook saw in Survey's frame, or the viewport's if none.)
    property RenderContext: TContext3D read FRenderContext;
    //** @abstract(CurrentProjectionMatrix inside Survey's frame.)
    property InsideProjection: TMatrix3D read FInsideProjection;
    //** @abstract(CurrentCameraMatrix inside Survey's frame.)
    property InsideCamera: TMatrix3D read FInsideCamera;
    //** @abstract(CurrentProjectionMatrix after Survey's frame.)
    property OutsideProjection: TMatrix3D read FOutsideProjection;
    //** @abstract(What SetAdjust changes.)
    property Target: TSpritelyAdjustTarget read FTarget;
    //** @abstract(Where log lines go.)
    property OnLog: TSpritelyLogProc read FOnLog write FOnLog;
  end;

  //** @abstract(The projection TSpritelyProjection draws with.)
  TSpritelyProjectionKind = (
    //** FMX's own perspective (with the lens and shift of TSpritelyProjection)
    pjPerspective,
    //** Orthographic: at every depth what the perspective shows at the target plane
    pjOrthographic,
    //** Oblique: depth drawn at full length, at 45 degrees
    pjCavalier,
    //** Oblique: depth drawn at half length, at 63.43 degrees (ArcTan 2)
    pjCabinet,
    //** Oblique (planometric): depth at full length straight down the picture - with the
    //** camera looking straight down, height is drawn straight up and the plan keeps its shape
    pjMilitary,
    //** Plan oblique: with the camera looking straight down and the plan square to the
    //** picture, height is drawn up and to the left at 45 degrees, full length (depth
    //** down-right: 315 degrees), as many hand-drawn top-down game maps are; camera preset
    //** azimuth 0, inclination 90
    pjPlanOblique,
    //** True isometric: orthographic, the camera at azimuth 45 and inclination 35.264, so the
    //** three axes are equally foreshortened and drawn 120 degrees apart
    pjTrueIsometric,
    //** 2:1 dimetric, the "isometric" of pixel-art games: orthographic, the camera at azimuth
    //** 45 and inclination 30, so a ground square is drawn twice as wide as high and its edges
    //** run 2 across for 1 up
    pjDimetric,
    //** Trimetric: orthographic, the camera at azimuth 35 and inclination 45 - tilted down
    //** about 45 degrees, height straight up, the scene turned so no two axes match, the look
    //** of many pre-rendered role-playing game maps
    pjTrimetric,
    //** Oblique with ObliqueAngle and ObliqueScale
    pjOblique);

  //** @abstract(What a TSpritelyProjection asks of the camera it draws for: the target plane's
  //** distance, and a hand in the dolly zoom.)
  //**
  //** TSpritelyOrbitalCamera has it; anything else that keeps a target distance can.
  ISpritelyProjectionFocus = interface
    ['{A3F07D52-61C8-4E9B-B2D4-7C15E86F0A3B}']
    //** @abstract(The distance from the camera to the target plane, along the line of sight.)
    //**
    //** @returns(The distance, scene units.)
    function ProjectionFocusDistance: Single;
    //** @abstract(The lens changed with Dolly on: move the camera so the target plane keeps
    //** its size, Distance * tan(half the angle) unchanged.)
    //**
    //** @param(AOldFieldOfView The vertical field of view before, degrees.)
    //** @param(ANewFieldOfView The vertical field of view now, degrees.)
    procedure ProjectionLensChanged(AOldFieldOfView, ANewFieldOfView: Single);
    //** @abstract(A projection with a camera preset was chosen (CameraPreset on): turn the
    //** camera to these angles, with no roll.)
    //**
    //** @param(AAzimuth The turn about the vertical axis, degrees.)
    //** @param(AInclination The tilt, degrees, 90 looking straight down.)
    procedure ProjectionViewAngles(AAzimuth, AInclination: Single);
  end;

  //** @abstract(How a TSpritelyProjection's picture is made, in the terms a camera's fits and
  //** ProjectToView need.)
  //**
  //** In the camera's own axes, X right and Y up the picture, a point X, Y at depth Z in front
  //** of the camera is drawn at normalised device x = X SX / Z + ShiftX in perspective, and,
  //** in a parallel view with the target plane at depth D, at x = (X + ShearX (Z - D)) SX / D +
  //** ShiftX; y likewise with SY, ShearY and ShiftY.
  TSpritelyViewShape = record
    //** @abstract(True for a parallel (orthographic or oblique) view.)
    Parallel: Boolean;
    //** @abstract(1 / tan(half the field of view) across, the lens drawn with.)
    SX: Single;
    //** @abstract(1 / tan(half the field of view) up and down, the lens drawn with.)
    SY: Single;
    //** @abstract(Shift, normalised device units, + right.)
    ShiftX: Single;
    //** @abstract(Rise, normalised device units, + up.)
    ShiftY: Single;
    //** @abstract(Oblique: how far across a unit of depth beyond the target plane is drawn,
    //** + right.)
    ShearX: Single;
    //** @abstract(Oblique: how far up a unit of depth beyond the target plane is drawn, + up.)
    ShearY: Single;
  end;

  //** @abstract(Called with a line for the log.)
  //**
  //** @param(Sender The projection.)
  //** @param(AText The line.)
  TSpritelyProjectionLogEvent = procedure(Sender: TObject; const AText: string) of object;

  //** @abstract(A projection for a FireMonkey 3D viewport (TViewport3D, TGorillaViewport, any
  //** IViewport3D): perspective with any lens, orthographic, and the oblique projections -
  //** cavalier, cabinet, military, plan oblique or any angle and scale, and the true
  //** isometric, 2:1 dimetric and trimetric camera presets - each with a lens shift and rise.)
  //**
  //** FMX builds the projection from the camera's angle of view and keeps it private
  //** (TContext3D.FProjectionMatrix); Gorilla3D draws with it. This component finds it inside
  //** the first frame, by its value, and writes its own over it inside every frame, through an
  //** empty 3D object put first in the viewport (TSpritelyRenderHook). It is made from FMX's own
  //** each time, so a resize or a new angle of view is followed, and FMX's is put back when
  //** nothing is to be changed or Active is False.
  //**
  //** The parallel views are made from the perspective at the target plane, so switching keeps
  //** the target's size; the target plane is Focus's (TSpritelyOrbitalCamera's Distance) or,
  //** without one, Distance. FieldOfView sets the lens; with Dolly and a Focus, a new lens also
  //** moves the camera so the target plane keeps its size - the dolly zoom. A camera that fits
  //** views (TSpritelyOrbitalCamera.Projection) reads ViewShape so its fits follow.
  //**
  //** Gorilla3D culls by its own camera's frustum, which a parallel or shifted view no longer
  //** is, so with ManageCulling the viewport's FrustumCulling is off while the projection is
  //** changed. The camera must be in perspective mode: FMX's projection is the starting point.
  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TSpritelyProjection = class(TComponent)
  private
    //** @abstract(The viewport, or nil.)
    FViewport: TControl;
    //** @abstract(The camera (or other) that gives the target distance and takes part in the
    //** dolly zoom, or nil; it has ISpritelyProjectionFocus.)
    FFocus: TComponent;
    //** @abstract(The empty object first in the viewport that calls us inside each frame; nil
    //** at design time and without a viewport.)
    FHook: TSpritelyRenderHook;
    //** @abstract(Where FMX keeps the projection, once found; owned.)
    FSlot: TSpritelyMatrixSlot;
    //** @abstract(Whether the projection is changed at all.)
    FActive: Boolean;
    //** @abstract(The projection drawn with.)
    FKind: TSpritelyProjectionKind;
    //** @abstract(The lens, vertical field of view in degrees; 0 for the camera's own.)
    FFieldOfView: Single;
    //** @abstract(The camera's own field of view as last seen in a frame, degrees.)
    FOwnFieldOfView: Single;
    //** @abstract(Whether a lens change moves the Focus to keep the target's size.)
    FDolly: Boolean;
    //** @abstract(Whether choosing a Kind with a camera preset turns the Focus to it.)
    FCameraPreset: Boolean;
    //** @abstract(Shift, normalised device units, + right.)
    FShiftX: Single;
    //** @abstract(Rise, normalised device units, + up.)
    FShiftY: Single;
    //** @abstract(pjOblique's direction for depth, degrees, 0 right, 90 up.)
    FObliqueAngle: Single;
    //** @abstract(pjOblique's length for depth, 1 its true length.)
    FObliqueScale: Single;
    //** @abstract(The target plane's distance when there is no Focus.)
    FDistance: Single;
    //** @abstract(Whether FrustumCulling is turned off while the projection is changed.)
    FManageCulling: Boolean;
    //** @abstract(Whether we turned FrustumCulling off.)
    FCullingOff: Boolean;
    //** @abstract(FrustumCulling before we turned it off.)
    FSavedCulling: Boolean;
    //** @abstract(Frames the projection has been written in.)
    FFrames: Int64;
    //** @abstract(The context the projection was last NOT found in, so it is not looked for
    //** (and logged) again every frame; cleared by Changed.)
    FFailedContext: TContext3D;
    //** @abstract(Where log lines go.)
    FOnLog: TSpritelyProjectionLogEvent;
    //** @abstract(Whether the slot lies in the viewport's present context, so it is safe to
    //** write: a context made again (a resize, a new form) leaves the slot in freed memory.)
    //**
    //** @returns(True if FSlot is there and alive.)
    function SlotAlive: Boolean;
    //** @abstract(Sends a line to OnLog.)
    //**
    //** @param(AText The line.)
    procedure Log(const AText: string);
    //** @abstract(The hook's call, inside each frame: finds the projection if need be and
    //** writes ours, or puts FMX's back.)
    //**
    //** @param(Sender The hook.)
    //** @param(AContext The context drawing the frame.)
    procedure HookRender(Sender: TObject; AContext: TContext3D);
    //** @abstract(Finds where AContext keeps its projection, by its value.)
    //**
    //** @param(AContext The context.)
    procedure FindSlot(AContext: TContext3D);
    //** @abstract(Puts FMX's projection back and forgets where it is.)
    procedure DropSlot;
    //** @abstract(Makes the hook in the viewport, at run time.)
    procedure MakeHook;
    //** @abstract(Takes the hook out and frees it.)
    procedure FreeHook;
    //** @abstract(Turns FrustumCulling off or back, as ManageCulling and Changing say, and
    //** asks for a new frame.)
    procedure Changed;
    //** @abstract(Whether anything is to be changed: not plain perspective with the own lens
    //** and no shift.)
    //**
    //** @returns(True if the projection differs from FMX's.)
    function Changing: Boolean;
    //** @abstract(The target plane's distance: Focus's, or Distance.)
    //**
    //** @returns(The distance.)
    function FocusDistance: Single;
    //** @abstract(The oblique direction and length for Kind.)
    //**
    //** @param(AAngle Degrees.)
    //** @param(AScale Length per unit of depth.)
    //** @returns(False for perspective and orthographic.)
    function ObliqueFor(out AAngle, AScale: Single): Boolean;
    //** @abstract(Setter for Viewport.)
    procedure SetViewport(const Value: TControl);
    //** @abstract(Setter for Focus.)
    procedure SetFocus(const Value: TComponent);
    //** @abstract(Setter for Active.)
    procedure SetActive(const Value: Boolean);
    //** @abstract(Setter for Kind: with CameraPreset, turns the Focus to the kind's angles.)
    procedure SetKind(const Value: TSpritelyProjectionKind);
    //** @abstract(Setter for FieldOfView: with Dolly, tells Focus to move.)
    procedure SetFieldOfView(const Value: Single);
    //** @abstract(Setter for ShiftX.)
    procedure SetShiftX(const Value: Single);
    //** @abstract(Setter for ShiftY.)
    procedure SetShiftY(const Value: Single);
    //** @abstract(Setter for ObliqueAngle.)
    procedure SetObliqueAngle(const Value: Single);
    //** @abstract(Setter for ObliqueScale.)
    procedure SetObliqueScale(const Value: Single);
    //** @abstract(Setter for Distance.)
    procedure SetDistance(const Value: Single);
    //** @abstract(Setter for ManageCulling.)
    procedure SetManageCulling(const Value: Boolean);
    //** @abstract(Whether FieldOfView is stored: when not 0.)
    function IsFieldOfViewStored: Boolean;
    //** @abstract(Whether ShiftX is stored: when not 0.)
    function IsShiftXStored: Boolean;
    //** @abstract(Whether ShiftY is stored: when not 0.)
    function IsShiftYStored: Boolean;
    //** @abstract(Whether ObliqueAngle is stored: when not the default.)
    function IsObliqueAngleStored: Boolean;
    //** @abstract(Whether ObliqueScale is stored: when not the default.)
    function IsObliqueScaleStored: Boolean;
    //** @abstract(Whether Distance is stored: when not the default.)
    function IsDistanceStored: Boolean;
  protected
    //** @abstract(Lets go of the viewport, focus or hook when freed.)
    //**
    //** @param(AComponent The component going.)
    //** @param(Operation opRemove when it goes.)
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    //** @abstract(Makes the hook once the form has loaded.)
    procedure Loaded; override;
  public
    //** @abstract(Makes the projection: active, perspective, the camera's own lens, no shift.)
    //**
    //** @param(AOwner The owner.)
    constructor Create(AOwner: TComponent); override;
    //** @abstract(Puts FMX's projection back, if the context is still there, and takes the
    //** hook out.)
    destructor Destroy; override;
    //** @abstract(The projection drawn with, made from FMX's own.)
    //**
    //** @param(AOwn FMX's own perspective, as the camera's angle of view makes it.)
    //** @returns(The projection for Kind, FieldOfView and the shift, or AOwn when Active is
    //** False or AOwn is not a perspective.)
    function MakeMatrix(const AOwn: TMatrix3D): TMatrix3D;
    //** @abstract(The view's shape, for a camera's fits and ProjectToView.)
    //**
    //** @param(AOwnSX The camera's own 1 / tan(half the field of view) across.)
    //** @param(AOwnSY The camera's own 1 / tan(half the field of view) up and down.)
    //** @returns(The shape; the camera's own perspective when Active is False.)
    function ViewShape(AOwnSX, AOwnSY: Single): TSpritelyViewShape;
    //** @abstract(The lens drawn with, vertical field of view in degrees: FieldOfView, or the
    //** camera's own when that is 0.)
    //**
    //** @returns(Degrees.)
    function EffectiveFieldOfView: Single;
    //** @abstract(The camera angles a kind is drawn from, if it has a preset: cavalier and
    //** cabinet level at a face (0, 0), military from above with the plan turned (45, 90),
    //** plan oblique from above with the plan square (0, 90), true isometric (45, 35.264),
    //** 2:1 dimetric (45, 30), trimetric (35, 45).)
    //**
    //** @param(AKind The kind.)
    //** @param(AAzimuth The turn about the vertical axis, degrees.)
    //** @param(AInclination The tilt, degrees, 90 looking straight down.)
    //** @returns(False for perspective, orthographic and free oblique, which keep the camera.)
    class function PresetAngles(AKind: TSpritelyProjectionKind; out AAzimuth,
      AInclination: Single): Boolean; static;
    //** @abstract(Turns the Focus to Kind's preset angles, if it has them and there is a
    //** Focus; Kind does this itself when set, with CameraPreset on.)
    //**
    //** @returns(True if the camera was turned.)
    function ApplyCameraPreset: Boolean;
    //** @abstract(Frames the projection has been written in, since it was made.)
    property Frames: Int64 read FFrames;
    //** @abstract(Whether FMX's projection has been found.)
    //**
    //** @returns(True once found.)
    function Found: Boolean;
  published
    //** @abstract(The viewport to draw for: anything that is an IViewport3D.)
    property Viewport: TControl read FViewport write SetViewport;
    //** @abstract(The camera that gives the target plane's distance and moves for the dolly
    //** zoom: one with ISpritelyProjectionFocus, such as TSpritelyOrbitalCamera. Setting
    //** TSpritelyOrbitalCamera.Projection sets this.)
    property Focus: TComponent read FFocus write SetFocus;
    //** @abstract(False: FMX's projection is put back and nothing is changed.)
    property Active: Boolean read FActive write SetActive default True;
    //** @abstract(The projection: perspective, orthographic or one of the oblique ones.)
    property Kind: TSpritelyProjectionKind read FKind write SetKind default pjPerspective;
    //** @abstract(The lens: the vertical field of view drawn with, degrees, over 0 and under
    //** 180; 0, the default, keeps the camera's own.)
    property FieldOfView: Single read FFieldOfView write SetFieldOfView
      stored IsFieldOfViewStored;
    //** @abstract(True, the default: a new FieldOfView also moves the Focus so the target
    //** plane keeps its size - the dolly zoom. False: a plain zoom.)
    property Dolly: Boolean read FDolly write FDolly default True;
    //** @abstract(True, the default: setting Kind to one with a camera preset (PresetAngles)
    //** also turns the Focus to it. False: the camera is left where it is.)
    property CameraPreset: Boolean read FCameraPreset write FCameraPreset default True;
    //** @abstract(Lens shift: the picture moved right (+) or left, normalised device units,
    //** where the whole picture is 2 wide.)
    property ShiftX: Single read FShiftX write SetShiftX stored IsShiftXStored;
    //** @abstract(Lens rise: the picture moved up (+) or down, normalised device units,
    //** where the whole picture is 2 high.)
    property ShiftY: Single read FShiftY write SetShiftY stored IsShiftYStored;
    //** @abstract(pjOblique: the direction depth is drawn in, degrees, 0 right, 90 up; 45 by
    //** default.)
    property ObliqueAngle: Single read FObliqueAngle write SetObliqueAngle
      stored IsObliqueAngleStored;
    //** @abstract(pjOblique: how long depth is drawn, 1 (the default) its true length.)
    property ObliqueScale: Single read FObliqueScale write SetObliqueScale
      stored IsObliqueScaleStored;
    //** @abstract(The target plane's distance from the camera when there is no Focus; 10 by
    //** default.)
    property Distance: Single read FDistance write SetDistance stored IsDistanceStored;
    //** @abstract(True, the default: a TGorillaViewport's FrustumCulling is off while the
    //** projection is changed, as Gorilla3D culls by its camera's own frustum.)
    property ManageCulling: Boolean read FManageCulling write SetManageCulling default True;
    //** @abstract(Called with a line for the log: where the projection was found, or why not.)
    property OnLog: TSpritelyProjectionLogEvent read FOnLog write FOnLog;
  end;

//** @abstract(The name of a matrix kind, for the log.)
//**
//** @param(AKind The kind.)
//** @returns(The name.)
function MatrixKindName(AKind: TSpritelyMatrixKind): string;

implementation

function MatrixKindName(AKind: TSpritelyMatrixKind): string;
begin
  case AKind of
    mkProjection: Result := 'PROJECTION';
    mkProjectionLike: Result := 'projection-like';
    mkCamera: Result := 'CAMERA (view)';
    mkCameraInverse: Result := 'camera inverse';
  else
    Result := '?';
  end;
end;

//** @abstract(Whether every entry of a matrix is a finite number.)
//**
//** @param(M The matrix.)
//** @returns(True if none is NaN or infinite.)
function AllFinite(const M: TMatrix3D): Boolean;
var
  R, C: Integer;
begin
  for R := 0 to 3 do
    for C := 0 to 3 do
      if IsNan(M.M[R].V[C]) or IsInfinite(M.M[R].V[C]) then
        Exit(False);
  Result := True;
end;

//** @abstract(Whether a matrix is all zero or the identity: values found everywhere, so never
//** taken for one of the matrices.)
//**
//** @param(M The matrix.)
//** @returns(True if it is either.)
function IsTrivial(const M: TMatrix3D): Boolean;
var
  R, C: Integer;
  Zero, Ident: Boolean;
begin
  Zero := True;
  Ident := True;
  for R := 0 to 3 do
    for C := 0 to 3 do
    begin
      if M.M[R].V[C] <> 0 then
        Zero := False;
      if (R = C) and (M.M[R].V[C] <> 1) then
        Ident := False;
      if (R <> C) and (M.M[R].V[C] <> 0) then
        Ident := False;
    end;
  Result := Zero or Ident;
end;

//** @abstract(Whether a number is near nought.)
//**
//** @param(A The number.)
//** @returns(True if under 1E-4.)
function Nought(A: Single): Boolean; inline;
begin
  Result := Abs(A) < 1E-4;
end;

{ TSpritelyCleanTracker }

function TSpritelyCleanTracker.Clean(const ACurrent: TMatrix3D): TMatrix3D;
begin
  // FMX made it again since our write (or nothing was written): that is its
  // own value now
  if not FWritten or not TSpritelyProjectionAccess.SameMatrix(ACurrent, FLast) then
    FClean := ACurrent;
  Result := FClean;
end;

procedure TSpritelyCleanTracker.Wrote(const AValue: TMatrix3D);
begin
  FLast := AValue;
  FWritten := True;
end;

procedure TSpritelyCleanTracker.Reset;
begin
  FWritten := False;
end;

{ TSpritelyMatrixSlot }

constructor TSpritelyMatrixSlot.Create(AHolder: TObject; AOffset: Integer;
  AKind: TSpritelyMatrixKind; const AName, AWhere: string);
begin
  inherited Create;
  FHolder := AHolder;
  FOffset := AOffset;
  FKind := AKind;
  FName := AName;
  FWhere := AWhere;
end;

function TSpritelyMatrixSlot.Address: TSpritelyMatrixPtr;
begin
  Result := TSpritelyMatrixPtr(PByte(FHolder) + FOffset);
end;

function TSpritelyMatrixSlot.Read: TMatrix3D;
begin
  Result := Address^;
end;

procedure TSpritelyMatrixSlot.Write(const AValue: TMatrix3D);
begin
  Address^ := AValue;
end;

function TSpritelyMatrixSlot.CleanValue: TMatrix3D;
begin
  Result := FTracker.Clean(Read);
end;

procedure TSpritelyMatrixSlot.Apply(const AValue: TMatrix3D);
begin
  // Keep FMX's value first, in case this is the first write
  FTracker.Clean(Read);
  Write(AValue);
  FTracker.Wrote(AValue);
end;

function TSpritelyMatrixSlot.Restore: Boolean;
begin
  Result := False;
  if FTracker.Written and TSpritelyProjectionAccess.SameMatrix(Read, FTracker.LastValue) then
  begin
    Write(FTracker.CleanValue);
    Result := True;
  end;
  FTracker.Reset;
end;

function TSpritelyMatrixSlot.State: string;
var
  Here: TMatrix3D;
begin
  Here := Read;
  if FTracker.Written and TSpritelyProjectionAccess.SameMatrix(Here, FTracker.LastValue) then
    Result := 'ours'
  else if TSpritelyProjectionAccess.SameMatrix(Here, FTracker.CleanValue) then
    Result := 'FMX''s'
  else
    Result := 'changed';
end;

function TSpritelyMatrixSlot.Describe: string;
var
  FieldName: string;
begin
  FieldName := FName;
  if FieldName = '' then
    FieldName := '(no RTTI name)';
  Result := Format('%s in %s (%s) at +$%x, %s', [MatrixKindName(FKind), FWhere,
    FHolder.ClassName, FOffset, FieldName]);
end;

{ TSpritelyRenderHook }

constructor TSpritelyRenderHook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Stored := False;
  HitTest := False;
end;

procedure TSpritelyRenderHook.Render;
begin
  Inc(FCalls);
  if Assigned(FOnRenderBegin) then
    FOnRenderBegin(Self, Context);
end;

{ TSpritelyProjectionAccess }

constructor TSpritelyProjectionAccess.Create(AOwner: TComponent; AViewport: TFmxObject);
begin
  inherited Create(AOwner);
  FViewport := AViewport;
  FSlots := TObjectList<TSpritelyMatrixSlot>.Create(True);
  FScanned := TList<TObject>.Create;
  FInsideProjection := TMatrix3D.Identity;
  FInsideCamera := TMatrix3D.Identity;
  FInsideCameraInverse := TMatrix3D.Identity;
  FOutsideProjection := TMatrix3D.Identity;
  FOutsideCamera := TMatrix3D.Identity;
  if FViewport <> nil then
  begin
    // Owned by the viewport, so it goes with it; first among its children,
    // so it is drawn before the models
    FHook := TSpritelyRenderHook.Create(FViewport);
    FHook.OnRenderBegin := HookRender;
    FViewport.InsertObject(0, FHook);
    FHook.FreeNotification(Self);
  end;
end;

destructor TSpritelyProjectionAccess.Destroy;
begin
  if FHook <> nil then
  begin
    FHook.RemoveFreeNotification(Self);
    FHook.OnRenderBegin := nil;
    FHook.Parent := nil;
    FHook.Free;
    FHook := nil;
  end;
  FScanned.Free;
  FSlots.Free;
  inherited Destroy;
end;

procedure TSpritelyProjectionAccess.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FHook) then
    FHook := nil;
end;

procedure TSpritelyProjectionAccess.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

function TSpritelyProjectionAccess.Context: TContext3D;
var
  VP: IViewport3D;
begin
  Result := nil;
  if (FViewport <> nil) and Supports(FViewport, IViewport3D, VP) then
    Result := VP.Context;
end;

class function TSpritelyProjectionAccess.SameMatrix(const A, B: TMatrix3D): Boolean;
var
  R, C: Integer;
  X, Y, Big: Single;
begin
  for R := 0 to 3 do
    for C := 0 to 3 do
    begin
      X := A.M[R].V[C];
      Y := B.M[R].V[C];
      if IsNan(X) or IsNan(Y) then
        Exit(False);
      // The tolerance is a share of the larger, or absolute under 1
      Big := Abs(X);
      if Abs(Y) > Big then
        Big := Abs(Y);
      if Big < 1 then
        Big := 1;
      if Abs(X - Y) > SPRITELY_MATRIX_TOLERANCE * Big then
        Exit(False);
    end;
  Result := True;
end;

class function TSpritelyProjectionAccess.IsPerspectiveLike(const M: TMatrix3D): Boolean;
begin
  // Row vectors (FMX): w = z * m34, so the fourth column is (0, 0, +-1, 0);
  // x and y scaled on the diagonal, nothing crossing between them
  // (ProjTest1 took a viewport's shadow settings for one: z must not feed
  // from x or y either, so m13 and m23 are 0 too)
  Result := Nought(M.m14) and Nought(M.m24) and Nought(Abs(M.m34) - 1) and
    Nought(M.m44) and not Nought(M.m11) and not Nought(M.m22) and Nought(M.m12) and
    Nought(M.m21) and Nought(M.m13) and Nought(M.m23) and not Nought(M.m43);
  // Column vectors: the same, transposed
  if not Result then
    Result := Nought(M.m41) and Nought(M.m42) and Nought(Abs(M.m43) - 1) and
      Nought(M.m44) and not Nought(M.m11) and not Nought(M.m22) and Nought(M.m12) and
      Nought(M.m21) and Nought(M.m31) and Nought(M.m32) and not Nought(M.m34);
end;

class function TSpritelyProjectionAccess.RowLayout(const P: TMatrix3D): Boolean;
begin
  // A perspective has w from z: m34 = +-1 (row vectors) or m43 = +-1
  // (columns), m44 = 0. An orthographic or oblique projection (ours) has w
  // = 1: the fourth column is (0, 0, 0, 1) for row vectors, the fourth row
  // for columns; its m43 is a depth term, so m43 alone says nothing
  if Nought(Abs(P.m34) - 1) and Nought(P.m44) then
    Result := True
  else if Nought(Abs(P.m43) - 1) and Nought(P.m44) then
    Result := False
  else if Nought(P.m14) and Nought(P.m24) and Nought(P.m34) then
    Result := True
  else if Nought(P.m41) and Nought(P.m42) and Nought(P.m43) then
    Result := False
  else
    Result := True;
end;

class function TSpritelyProjectionAccess.ShiftProjection(const P: TMatrix3D;
  ASX, ASY: Single): TMatrix3D;
var
  I: Integer;
begin
  // x_clip + ASX * w_clip: the x column gains ASX times the w column (row
  // vectors), so x_ndc + ASX after the divide; the same for y
  Result := P;
  if RowLayout(P) then
    for I := 0 to 3 do
    begin
      Result.M[I].V[0] := P.M[I].V[0] + ASX * P.M[I].V[3];
      Result.M[I].V[1] := P.M[I].V[1] + ASY * P.M[I].V[3];
    end
  else
    for I := 0 to 3 do
    begin
      Result.M[0].V[I] := P.M[0].V[I] + ASX * P.M[3].V[I];
      Result.M[1].V[I] := P.M[1].V[I] + ASY * P.M[3].V[I];
    end;
end;

class function TSpritelyProjectionAccess.ShearForShift(const P: TMatrix3D;
  ASX, ASY: Single): TMatrix3D;
var
  WZ: Single;
begin
  // x' = x + kx z in view space: x_ndc moves by kx * m11 / m34 (row
  // vectors), so kx = ASX * m34 / m11; y likewise with m22
  Result := TMatrix3D.Identity;
  if RowLayout(P) then
    WZ := P.m34
  else
    WZ := P.m43;
  if not Nought(P.m11) then
    Result.m31 := ASX * WZ / P.m11;
  if not Nought(P.m22) then
    Result.m32 := ASY * WZ / P.m22;
end;

class function TSpritelyProjectionAccess.ClipShift(ASX, ASY: Single;
  ARowLayout: Boolean): TMatrix3D;
begin
  // x_clip + ASX * w_clip as a matrix after the projection: the w row (row
  // vectors) or the w column (columns) feeds x and y
  Result := TMatrix3D.Identity;
  if ARowLayout then
  begin
    Result.m41 := ASX;
    Result.m42 := ASY;
  end
  else
  begin
    Result.m14 := ASX;
    Result.m24 := ASY;
  end;
end;

class function TSpritelyProjectionAccess.MatrixText(const M: TMatrix3D): string;
var
  R, C: Integer;
begin
  Result := '';
  for R := 0 to 3 do
  begin
    if R > 0 then
      Result := Result + ' |';
    for C := 0 to 3 do
      Result := Result + ' ' + FormatFloat('0.#####', M.M[R].V[C]);
  end;
  Result := '[' + Result + ' ]';
end;

function TSpritelyProjectionAccess.Classify(const AMatrix: TMatrix3D;
  out AKind: TSpritelyMatrixKind): Boolean;
begin
  Result := False;
  AKind := mkProjectionLike;
  if not AllFinite(AMatrix) or IsTrivial(AMatrix) then
    Exit;
  Result := True;
  if SameMatrix(AMatrix, FInsideProjection) or SameMatrix(AMatrix, FOutsideProjection) then
    AKind := mkProjection
  else if SameMatrix(AMatrix, FInsideCamera) or SameMatrix(AMatrix, FOutsideCamera) then
    AKind := mkCamera
  else if SameMatrix(AMatrix, FInsideCameraInverse) then
    AKind := mkCameraInverse
  else if IsPerspectiveLike(AMatrix) then
    AKind := mkProjectionLike
  else
    Result := False;
end;

//** @abstract(The name of the field a byte of an object lies in, from RTTI.)
//**
//** @param(AObject The object.)
//** @param(AOffset Bytes from its start.)
//** @param(AStraddles True when RTTI shows the bytes start inside a TMatrix3D field: then
//** they are the tail of one matrix and the head of the next, not a matrix.)
//** @returns('Class.Field' when the matrix starts the field, 'Class.Field+n' when it lies n
//** bytes into it (a record), or empty where RTTI has nothing.)
function FieldNameAt(AObject: TObject; AOffset: Integer; out AStraddles: Boolean): string;
var
  Ctx: TRttiContext;
  T: TRttiType;
  F: TRttiField;
  Size: Integer;
begin
  Result := '';
  AStraddles := False;
  Ctx := TRttiContext.Create;
  try
    T := Ctx.GetType(AObject.ClassType);
    if T = nil then
      Exit;
    for F in T.GetFields do
    begin
      if F.FieldType = nil then
        Continue;
      Size := F.FieldType.TypeSize;
      if (AOffset >= F.Offset) and (AOffset < F.Offset + Size) then
      begin
        Result := F.Name;
        if F.Parent is TRttiType then
          Result := TRttiType(F.Parent).Name + '.' + Result;
        if AOffset > F.Offset then
        begin
          Result := Result + '+' + IntToStr(AOffset - F.Offset);
          AStraddles := SameText(F.FieldType.Name, 'TMatrix3D');
        end;
        Exit;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

procedure TSpritelyProjectionAccess.ScanObject(AObject: TObject; const AWhere: string);
var
  Base: PByte;
  Size, Offset: Integer;
  Kind: TSpritelyMatrixKind;
  Name: string;
  Straddles: Boolean;
begin
  if (AObject = nil) or (FScanned.IndexOf(AObject) >= 0) or
    (FScanned.Count >= SPRITELY_MATRIX_MAX_SCAN_OBJECTS) then
    Exit;
  FScanned.Add(AObject);
  try
    Size := AObject.InstanceSize;
    if (Size <= SizeOf(Pointer)) or (Size > SPRITELY_MATRIX_MAX_INSTANCE) then
      Exit;
    Base := PByte(AObject);
    // Past the class pointer; Singles are 4-byte aligned
    Offset := SizeOf(Pointer);
    while Offset + SizeOf(TMatrix3D) <= Size do
    begin
      Straddles := False;
      if Classify(TSpritelyMatrixPtr(Base + Offset)^, Kind) then
        Name := FieldNameAt(AObject, Offset, Straddles);
      if Classify(TSpritelyMatrixPtr(Base + Offset)^, Kind) and not Straddles then
      begin
        FSlots.Add(TSpritelyMatrixSlot.Create(AObject, Offset, Kind, Name, AWhere));
        Inc(Offset, SizeOf(TMatrix3D));
      end
      else
        Inc(Offset, SizeOf(Single));
    end;
  except
    on E: Exception do
      Log(Format('  Could not look through %s: %s: %s', [AWhere, E.ClassName, E.Message]));
  end;
end;

procedure TSpritelyProjectionAccess.FollowFields(AObject: TObject; const AWhere: string);
var
  Ctx: TRttiContext;
  T: TRttiType;
  F: TRttiField;
  Child: TObject;
  Children: TList<TPair<TObject, string>>;
  Pair: TPair<TObject, string>;
begin
  if AObject = nil then
    Exit;
  Children := TList<TPair<TObject, string>>.Create;
  Ctx := TRttiContext.Create;
  try
    try
      T := Ctx.GetType(AObject.ClassType);
      if T <> nil then
        for F in T.GetFields do
          if (F.FieldType <> nil) and (F.FieldType.TypeKind = tkClass) then
          begin
            Child := F.GetValue(AObject).AsObject;
            // Not the control tree: forms, layouts and models hold no
            // context's matrices
            if (Child <> nil) and not (Child is TFmxObject) then
              Children.Add(TPair<TObject, string>.Create(Child, AWhere + '.' + F.Name));
          end;
    except
      on E: Exception do
        Log(Format('  Could not list the fields of %s: %s: %s', [AWhere, E.ClassName,
          E.Message]));
    end;
    for Pair in Children do
      ScanObject(Pair.Key, Pair.Value);
  finally
    Ctx.Free;
    Children.Free;
  end;
end;

procedure TSpritelyProjectionAccess.ScanAll(AContext: TContext3D);
var
  O: TObject;
  Own: TContext3D;
begin
  FScanned.Clear;
  Own := Context;
  ScanObject(AContext, 'render context');
  if Own <> AContext then
    ScanObject(Own, 'viewport context');
  ScanObject(FViewport, 'viewport');
  for O in FExtra do
    if O <> nil then
      ScanObject(O, O.ClassName);
  // One level further: what the contexts and the viewport hold (a
  // renderer's own objects, render targets)
  FollowFields(AContext, 'render context');
  if Own <> AContext then
    FollowFields(Own, 'viewport context');
  FollowFields(FViewport, 'viewport');
end;

procedure TSpritelyProjectionAccess.HookRender(Sender: TObject; AContext: TContext3D);
begin
  if AContext = nil then
    Exit;
  if FSurveying then
    FSurveyProjections := FSurveyProjections + [AContext.CurrentProjectionMatrix];
  if FSurveying and not FHookSeen then
  begin
    FHookSeen := True;
    FRenderContext := AContext;
    FInsideProjection := AContext.CurrentProjectionMatrix;
    FInsideCamera := AContext.CurrentCameraMatrix;
    FInsideCameraInverse := AContext.CurrentCameraInvMatrix;
    // Looked for now, while the frame's values are surely in place
    ScanAll(AContext);
  end;
  if FInRender and not FSurveying then
    ApplyTo(AContext);
end;

procedure TSpritelyProjectionAccess.Survey(const ARender: TProc; const AExtra: array of TObject);
var
  Ctx: TContext3D;
  I: Integer;
begin
  RestoreAll;
  SetAdjust(atNone, nil, nil, nil, False);
  FSlots.Clear;
  SetLength(FExtra, Length(AExtra));
  for I := 0 to High(AExtra) do
    FExtra[I] := AExtra[I];
  FHookSeen := False;
  FRenderContext := nil;
  FSurveyProjections := nil;
  // Last Survey's values must not match old copies left in memory
  FOutsideProjection := TMatrix3D.Identity;
  FOutsideCamera := TMatrix3D.Identity;
  if FHook <> nil then
    FHook.Calls := 0;
  Ctx := Context;
  FSurveying := True;
  try
    if Assigned(ARender) then
      ARender();
  finally
    FSurveying := False;
  end;
  if Ctx <> nil then
  begin
    FOutsideProjection := Ctx.CurrentProjectionMatrix;
    FOutsideCamera := Ctx.CurrentCameraMatrix;
  end;
  if not FHookSeen and (Ctx <> nil) then
  begin
    // The hook was not drawn: take the values from outside the frame
    FRenderContext := Ctx;
    FInsideProjection := FOutsideProjection;
    FInsideCamera := FOutsideCamera;
    FInsideCameraInverse := Ctx.CurrentCameraInvMatrix;
    ScanAll(Ctx);
  end;
  FSurveyed := True;
end;

procedure TSpritelyProjectionAccess.LogSurvey;
var
  S: TSpritelyMatrixSlot;
  Own: TContext3D;
  I: Integer;
begin
  Own := Context;
  if FHook <> nil then
    Log(Format('Survey: the hook was drawn %d time(s) in the frame', [FHook.Calls]))
  else
    Log('Survey: there is no hook (the viewport has freed it)');
  if not FHookSeen then
    Log('Survey: THE HOOK WAS NOT DRAWN, so the matrices were read after the frame, outside it');
  if Own <> nil then
    Log(Format('Survey: viewport context %s', [Own.ClassName]))
  else
    Log('Survey: the viewport has no context');
  if (FRenderContext <> nil) and (FRenderContext <> Own) then
    Log(Format('Survey: THE FRAME WAS DRAWN BY ANOTHER CONTEXT, %s', [FRenderContext.ClassName]));
  Log('Survey: projection inside the frame  ' + MatrixText(FInsideProjection));
  if SameMatrix(FInsideProjection, FOutsideProjection) then
    Log('Survey: projection after the frame   the same')
  else
    Log('Survey: projection after the frame   ' + MatrixText(FOutsideProjection) +
      ' (DIFFERENT)');
  Log('Survey: camera inside the frame      ' + MatrixText(FInsideCamera));
  for I := 1 to High(FSurveyProjections) do
    if SameMatrix(FSurveyProjections[I], FInsideProjection) then
      Log(Format('Survey: hook call %d, projection the same', [I + 1]))
    else
      Log(Format('Survey: hook call %d, projection %s (DIFFERENT: another pass?)', [I + 1,
        MatrixText(FSurveyProjections[I])]));
  if RowLayout(FInsideProjection) then
    Log('Survey: the projection is laid out for row vectors (FMX''s way)')
  else
    Log('Survey: the projection is laid out for COLUMN vectors');
  if FSlots.Count = 0 then
    Log('Survey: NO MATRIX FOUND in the objects looked through')
  else
    for S in FSlots do
      Log('  Found ' + S.Describe + ' ' + MatrixText(S.Read));
  Log(Format('Survey: %d object(s) looked through', [FScanned.Count]));
end;

function TSpritelyProjectionAccess.FirstSlot(AKind: TSpritelyMatrixKind): TSpritelyMatrixSlot;
var
  S: TSpritelyMatrixSlot;
begin
  for S in FSlots do
    if S.Kind = AKind then
      Exit(S);
  Result := nil;
end;

function TSpritelyProjectionAccess.InverseFor(ASlot: TSpritelyMatrixSlot): TSpritelyMatrixSlot;
var
  S: TSpritelyMatrixSlot;
begin
  Result := nil;
  if ASlot = nil then
    Exit;
  for S in FSlots do
    if (S.Kind = mkCameraInverse) and (S.Holder = ASlot.Holder) then
      Exit(S);
end;

procedure TSpritelyProjectionAccess.SetAdjust(ATarget: TSpritelyAdjustTarget;
  ASlot, AInverse: TSpritelyMatrixSlot; const AAdjust: TSpritelyMatrixAdjust; AInRender: Boolean);
begin
  if not Assigned(AAdjust) then
    ATarget := atNone;
  if (ATarget in [atProjectionSlot, atCameraSlot]) and (ASlot = nil) then
    ATarget := atNone;
  FTarget := ATarget;
  FTargetSlot := ASlot;
  FInverseSlot := AInverse;
  FAdjust := AAdjust;
  FInRender := AInRender and (ATarget <> atNone);
end;

procedure TSpritelyProjectionAccess.ApplyTo(AContext: TContext3D);
var
  V: TMatrix3D;
begin
  case FTarget of
    atProjectionSlot:
      FTargetSlot.Apply(FAdjust(FTargetSlot.CleanValue, AContext));
    atCameraSlot:
      begin
        V := FAdjust(FTargetSlot.CleanValue, AContext);
        FTargetSlot.Apply(V);
        if FInverseSlot <> nil then
          FInverseSlot.Apply(V.Inverse);
      end;
    atSetCameraMatrix:
      if AContext <> nil then
      begin
        V := FAdjust(FCameraTracker.Clean(AContext.CurrentCameraMatrix), AContext);
        AContext.SetCameraMatrix(V);
        FCameraTracker.Wrote(V);
      end;
    atRenderToMatrix:
      if AContext <> nil then
      begin
        AContext.SetRenderToMatrix(FAdjust(TMatrix3D.Identity, AContext));
        FRenderToContext := AContext;
      end;
  end;
end;

procedure TSpritelyProjectionAccess.ApplyNow;
begin
  ApplyTo(Context);
end;

procedure TSpritelyProjectionAccess.RestoreAll;
var
  S: TSpritelyMatrixSlot;
  Ctx: TContext3D;
begin
  for S in FSlots do
    S.Restore;
  Ctx := Context;
  if (FRenderToContext <> nil) and
    ((FRenderToContext = Ctx) or (FRenderToContext = FRenderContext)) then
    FRenderToContext.SetRenderToMatrix(TMatrix3D.Identity);
  FRenderToContext := nil;
  if FCameraTracker.Written and (Ctx <> nil) and
    SameMatrix(Ctx.CurrentCameraMatrix, FCameraTracker.LastValue) then
    Ctx.SetCameraMatrix(FCameraTracker.CleanValue);
  FCameraTracker.Reset;
end;

procedure TSpritelyProjectionAccess.Forget;
var
  Ctx: TContext3D;
  S: TSpritelyMatrixSlot;
begin
  SetAdjust(atNone, nil, nil, nil, False);
  Ctx := Context;
  if (FRenderToContext <> nil) and (FRenderToContext = Ctx) then
    Ctx.SetRenderToMatrix(TMatrix3D.Identity);
  FRenderToContext := nil;
  FCameraTracker.Reset;
  // The present context is alive: put FMX's values back there (only where
  // ours is still in place, so a projection FMX has made anew for the new
  // size is left alone)
  for S in FSlots do
    if (Ctx <> nil) and (S.Holder = Ctx) then
      S.Restore;
  FSlots.Clear;
  FSurveyed := False;
end;

function TSpritelyProjectionAccess.AdjustProjection(const AAdjust: TSpritelyMatrixAdjust;
  AInRender: Boolean): Boolean;
var
  Slot: TSpritelyMatrixSlot;
begin
  Slot := FirstSlot(mkProjection);
  Result := Slot <> nil;
  if Result then
    SetAdjust(atProjectionSlot, Slot, nil, AAdjust, AInRender);
end;

class function TSpritelyProjectionAccess.DepthRange(const P: TMatrix3D;
  out ANear, AFar: Single): Boolean;
begin
  ANear := 0;
  AFar := 0;
  Result := Nought(P.m34 + 1) and Nought(P.m44) and not Nought(P.m33) and not Nought(P.m43);
  if not Result then
    Exit;
  ANear := P.m43 / P.m33;
  if Abs(P.m33 + 1) < 1E-9 then
    AFar := ANear * 1E6
  else
    AFar := P.m43 / (P.m33 + 1);
  Result := (ANear > 0) and (AFar > ANear);
end;

class function TSpritelyProjectionAccess.Orthographic(const P: TMatrix3D;
  ADistance: Single): TMatrix3D;
var
  N, F: Single;
begin
  if not DepthRange(P, N, F) or Nought(P.m11) or Nought(P.m22) or (ADistance <= 0) then
    Exit(P);
  // The perspective's half-sizes at ADistance are ADistance / m11 and
  // ADistance / m22; scale x and y to those, depth linear from the near
  // plane (0) to the far (1) as FMX's perspective does, w = 1. Any
  // off-axis part of P (m31, m32) is the perspective's own and not kept
  Result := TMatrix3D.Identity;
  Result.m11 := P.m11 / ADistance;
  Result.m22 := P.m22 / ADistance;
  Result.m33 := 1 / (N - F);
  Result.m43 := N / (N - F);
  Result.m44 := 1;
end;

class function TSpritelyProjectionAccess.Oblique(const P: TMatrix3D;
  ADistance, AScale, AAngle: Single): TMatrix3D;
var
  Ortho, Shear: TMatrix3D;
  CX, CY: Single;
begin
  Ortho := Orthographic(P, ADistance);
  if SameMatrix(Ortho, P) then
    Exit(P);
  // In view space (right-handed, looking down -z) a point's depth beyond
  // the target plane is d = -(z + ADistance); x' = x + CX d, y' = y + CY d,
  // so with row vectors the z row gets -CX, -CY and the fourth row
  // -CX * ADistance, -CY * ADistance
  CX := AScale * Cos(DegToRad(AAngle));
  CY := AScale * Sin(DegToRad(AAngle));
  Shear := TMatrix3D.Identity;
  Shear.m31 := -CX;
  Shear.m32 := -CY;
  Shear.m41 := -CX * ADistance;
  Shear.m42 := -CY * ADistance;
  Result := Shear * Ortho;
end;

class function TSpritelyProjectionAccess.FieldOfView(const P: TMatrix3D): Single;
var
  N, F: Single;
begin
  // m22 = 1 / tan(half the vertical field of view)
  if not DepthRange(P, N, F) or (P.m22 <= 0) then
    Exit(0);
  Result := RadToDeg(2 * ArcTan(1 / P.m22));
end;

class function TSpritelyProjectionAccess.WithFieldOfView(const P: TMatrix3D;
  AFieldOfView: Single): TMatrix3D;
var
  N, F, Factor: Single;
begin
  Result := P;
  if not DepthRange(P, N, F) or (P.m22 <= 0) or (AFieldOfView <= 0) or
    (AFieldOfView >= 180) then
    Exit;
  // The new 1 / tan(half the angle) over the old; x scaled alike keeps the
  // aspect (m11 / m22)
  Factor := (1 / Tan(DegToRad(AFieldOfView) / 2)) / P.m22;
  Result.m11 := P.m11 * Factor;
  Result.m22 := P.m22 * Factor;
end;

{ TSpritelyProjection }

constructor TSpritelyProjection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := True;
  FKind := pjPerspective;
  FDolly := True;
  FCameraPreset := True;
  FObliqueAngle := SPRITELY_PROJECTION_OBLIQUE_ANGLE;
  FObliqueScale := SPRITELY_PROJECTION_OBLIQUE_SCALE;
  FDistance := SPRITELY_PROJECTION_DEFAULT_DISTANCE;
  FOwnFieldOfView := SPRITELY_PROJECTION_DEFAULT_FOV;
  FManageCulling := True;
end;

destructor TSpritelyProjection.Destroy;
begin
  // FMX's projection back while the context is surely there: only if the
  // viewport is not going too
  if (FViewport <> nil) and not (csDestroying in FViewport.ComponentState) then
    DropSlot
  else
    FreeAndNil(FSlot);
  FreeHook;
  inherited Destroy;
end;

procedure TSpritelyProjection.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TSpritelyProjection.Loaded;
begin
  inherited Loaded;
  MakeHook;
  Changed;
end;

procedure TSpritelyProjection.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if AComponent = FHook then
    FHook := nil
  else if AComponent = FFocus then
    FFocus := nil
  else if AComponent = FViewport then
  begin
    // The viewport frees its context and our hook with it: forget both
    FreeAndNil(FSlot);
    if FHook <> nil then
    begin
      FHook.RemoveFreeNotification(Self);
      FHook.OnRenderBegin := nil;
      FHook := nil;
    end;
    FViewport := nil;
    FCullingOff := False;
  end;
end;

procedure TSpritelyProjection.MakeHook;
begin
  if (FHook <> nil) or (FViewport = nil) or (csDesigning in ComponentState) or
    (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  // Owned by the viewport, so it goes with it; first among its children, so
  // FMX draws it before the models, with the frame's matrices already set
  FHook := TSpritelyRenderHook.Create(FViewport);
  FHook.OnRenderBegin := HookRender;
  FViewport.InsertObject(0, FHook);
  FHook.FreeNotification(Self);
end;

procedure TSpritelyProjection.FreeHook;
begin
  if FHook = nil then
    Exit;
  FHook.RemoveFreeNotification(Self);
  FHook.OnRenderBegin := nil;
  // A viewport that is going frees the hook with its other children
  if (FViewport <> nil) and (csDestroying in FViewport.ComponentState) then
  begin
    FHook := nil;
    Exit;
  end;
  FHook.Parent := nil;
  FreeAndNil(FHook);
end;

procedure TSpritelyProjection.FindSlot(AContext: TContext3D);
var
  Own: TMatrix3D;
  Base: PByte;
  Offset, Size: Integer;
begin
  FreeAndNil(FSlot);
  Own := AContext.CurrentProjectionMatrix;
  if not TSpritelyProjectionAccess.IsPerspectiveLike(Own) then
  begin
    Log('The context''s projection is not a perspective: nothing changed (the camera must ' +
      'be in perspective mode)');
    Exit;
  end;
  // The getter returns FMX's cached projection: the field holding the same
  // sixteen Singles is where it is kept (TContext3D.FProjectionMatrix)
  Base := PByte(AContext);
  Size := AContext.InstanceSize;
  Offset := SizeOf(Pointer);
  while Offset + SizeOf(TMatrix3D) <= Size do
  begin
    if TSpritelyProjectionAccess.SameMatrix(TSpritelyMatrixPtr(Base + Offset)^, Own) then
    begin
      FSlot := TSpritelyMatrixSlot.Create(AContext, Offset, mkProjection, '', 'context');
      Log(Format('Projection found in %s at +$%x', [AContext.ClassName, Offset]));
      Exit;
    end;
    Inc(Offset, SizeOf(Single));
  end;
  Log(Format('The projection was NOT found in %s: nothing changed', [AContext.ClassName]));
end;

function TSpritelyProjection.SlotAlive: Boolean;
var
  VP: IViewport3D;
begin
  Result := (FSlot <> nil) and (FViewport <> nil) and Supports(FViewport, IViewport3D, VP) and
    (VP.Context = FSlot.Holder);
end;

procedure TSpritelyProjection.DropSlot;
begin
  if SlotAlive then
    FSlot.Restore;
  FreeAndNil(FSlot);
end;

procedure TSpritelyProjection.HookRender(Sender: TObject; AContext: TContext3D);
var
  Clean: TMatrix3D;
begin
  if AContext = nil then
    Exit;
  if not FActive or not Changing then
  begin
    // FMX's own is to be drawn: put it back where ours still is, and note
    // the camera's own lens (the first dolly step starts from it)
    if (FSlot <> nil) and (FSlot.Holder = AContext) then
      FSlot.Restore;
    if TSpritelyProjectionAccess.FieldOfView(AContext.CurrentProjectionMatrix) > 0 then
      FOwnFieldOfView := TSpritelyProjectionAccess.FieldOfView(AContext.CurrentProjectionMatrix);
    Exit;
  end;
  if (FSlot = nil) or (FSlot.Holder <> AContext) then
  begin
    // A new context, or the first frame: the old one may be gone, so its
    // slot is only forgotten. Not again in a context it was not found in
    // (once logged), until a property changes
    FreeAndNil(FSlot);
    if AContext = FFailedContext then
      Exit;
    FindSlot(AContext);
    if FSlot = nil then
    begin
      FFailedContext := AContext;
      Exit;
    end;
  end;
  Clean := FSlot.CleanValue;
  FOwnFieldOfView := TSpritelyProjectionAccess.FieldOfView(Clean);
  FSlot.Apply(MakeMatrix(Clean));
  Inc(FFrames);
end;

function TSpritelyProjection.Changing: Boolean;
begin
  Result := (FKind <> pjPerspective) or (FFieldOfView > 0) or (FShiftX <> 0) or
    (FShiftY <> 0);
end;

function TSpritelyProjection.Found: Boolean;
begin
  Result := FSlot <> nil;
end;

function TSpritelyProjection.FocusDistance: Single;
var
  F: ISpritelyProjectionFocus;
begin
  Result := FDistance;
  if (FFocus <> nil) and Supports(FFocus, ISpritelyProjectionFocus, F) then
    Result := F.ProjectionFocusDistance;
  if Result <= 0 then
    Result := SPRITELY_PROJECTION_DEFAULT_DISTANCE;
end;

function TSpritelyProjection.ObliqueFor(out AAngle, AScale: Single): Boolean;
begin
  Result := True;
  case FKind of
    pjCavalier:
      begin
        AAngle := 45;
        AScale := 1;
      end;
    pjCabinet:
      begin
        AAngle := SPRITELY_PROJECTION_CABINET_ANGLE;
        AScale := 0.5;
      end;
    pjMilitary:
      begin
        // Depth runs down the picture: looking straight down, what is lower
        // is drawn lower, so height goes straight up
        AAngle := 270;
        AScale := 1;
      end;
    pjPlanOblique:
      begin
        AAngle := SPRITELY_PROJECTION_PLAN_OBLIQUE_ANGLE;
        AScale := 1;
      end;
    pjOblique:
      begin
        AAngle := FObliqueAngle;
        AScale := FObliqueScale;
      end;
  else
    begin
      AAngle := 0;
      AScale := 0;
      Result := False;
    end;
  end;
end;

function TSpritelyProjection.EffectiveFieldOfView: Single;
begin
  if FFieldOfView > 0 then
    Result := FFieldOfView
  else
    Result := FOwnFieldOfView;
end;

function TSpritelyProjection.MakeMatrix(const AOwn: TMatrix3D): TMatrix3D;
var
  Angle, Scale, D: Single;
begin
  Result := AOwn;
  if not FActive or not TSpritelyProjectionAccess.IsPerspectiveLike(AOwn) then
    Exit;
  // The lens first: the parallel views take their size from it
  if FFieldOfView > 0 then
    Result := TSpritelyProjectionAccess.WithFieldOfView(Result, FFieldOfView);
  D := FocusDistance;
  if FKind in [pjOrthographic, pjTrueIsometric, pjDimetric, pjTrimetric] then
    Result := TSpritelyProjectionAccess.Orthographic(Result, D)
  else if ObliqueFor(Angle, Scale) then
    Result := TSpritelyProjectionAccess.Oblique(Result, D, Scale, Angle);
  Result := TSpritelyProjectionAccess.ShiftProjection(Result, FShiftX, FShiftY);
end;

function TSpritelyProjection.ViewShape(AOwnSX, AOwnSY: Single): TSpritelyViewShape;
var
  Factor, Angle, Scale: Single;
begin
  Result.Parallel := False;
  Result.SX := AOwnSX;
  Result.SY := AOwnSY;
  Result.ShiftX := 0;
  Result.ShiftY := 0;
  Result.ShearX := 0;
  Result.ShearY := 0;
  if not FActive then
    Exit;
  if (FFieldOfView > 0) and (FFieldOfView < 180) and (AOwnSY > 0) then
  begin
    // As WithFieldOfView: both scaled alike, the aspect kept
    Factor := (1 / Tan(DegToRad(FFieldOfView) / 2)) / AOwnSY;
    Result.SX := AOwnSX * Factor;
    Result.SY := AOwnSY * Factor;
  end;
  Result.ShiftX := FShiftX;
  Result.ShiftY := FShiftY;
  Result.Parallel := FKind <> pjPerspective;
  if ObliqueFor(Angle, Scale) then
  begin
    Result.ShearX := Scale * Cos(DegToRad(Angle));
    Result.ShearY := Scale * Sin(DegToRad(Angle));
  end;
end;

procedure TSpritelyProjection.Changed;
var
  VP: TGorillaViewport;
  Want: Boolean;
begin
  if (FViewport = nil) or (csLoading in ComponentState) or
    (csDesigning in ComponentState) then
    Exit;
  // Nothing to change now: FMX's projection back at once, not only in the
  // next frame, so a test or a screenshot taken before it sees FMX's; only
  // in a context still alive
  if not (FActive and Changing) and SlotAlive then
    FSlot.Restore;
  // Look again for a projection not found before (the camera may be in
  // perspective mode now)
  FFailedContext := nil;
  if FViewport is TGorillaViewport then
  begin
    VP := TGorillaViewport(FViewport);
    Want := FManageCulling and FActive and Changing;
    if Want and not FCullingOff then
    begin
      FSavedCulling := VP.FrustumCulling;
      VP.FrustumCulling := False;
      FCullingOff := True;
    end
    else if not Want and FCullingOff then
    begin
      VP.FrustumCulling := FSavedCulling;
      FCullingOff := False;
    end;
  end;
  FViewport.Repaint;
end;

procedure TSpritelyProjection.SetViewport(const Value: TControl);
var
  VP: IViewport3D;
begin
  if Value = FViewport then
    Exit;
  if (Value <> nil) and not Supports(Value, IViewport3D, VP) then
    raise EArgumentException.CreateFmt('%s is not a 3D viewport', [Value.Name]);
  // Culling back and FMX's projection back in the old viewport
  if FCullingOff and (FViewport is TGorillaViewport) then
    TGorillaViewport(FViewport).FrustumCulling := FSavedCulling;
  FCullingOff := False;
  DropSlot;
  FreeHook;
  if FViewport <> nil then
    FViewport.RemoveFreeNotification(Self);
  FViewport := Value;
  if FViewport <> nil then
  begin
    FViewport.FreeNotification(Self);
    MakeHook;
  end;
  Changed;
end;

procedure TSpritelyProjection.SetFocus(const Value: TComponent);
var
  F: ISpritelyProjectionFocus;
begin
  if Value = FFocus then
    Exit;
  if (Value <> nil) and not Supports(Value, ISpritelyProjectionFocus, F) then
    raise EArgumentException.CreateFmt('%s cannot be a projection''s focus', [Value.Name]);
  // Not RemoveFreeNotification on the old focus: that would also take away
  // its notice of this projection going (TSpritelyOrbitalCamera keeps a
  // pointer to us); a stale notice is harmless, Notification checks
  FFocus := Value;
  if FFocus <> nil then
    FFocus.FreeNotification(Self);
  Changed;
end;

procedure TSpritelyProjection.SetActive(const Value: Boolean);
begin
  FActive := Value;
  Changed;
end;

procedure TSpritelyProjection.SetKind(const Value: TSpritelyProjectionKind);
begin
  FKind := Value;
  // Not while loading: the camera's stored angles are the ones wanted
  if FCameraPreset and not (csLoading in ComponentState) then
    ApplyCameraPreset;
  Changed;
end;

class function TSpritelyProjection.PresetAngles(AKind: TSpritelyProjectionKind;
  out AAzimuth, AInclination: Single): Boolean;
begin
  Result := True;
  AAzimuth := 0;
  AInclination := 0;
  case AKind of
    // Level, looking at a face: depth drawn across it
    pjCavalier, pjCabinet:
      ;
    // Straight down, the plan turned 45 degrees
    pjMilitary:
      begin
        AAzimuth := 45;
        AInclination := 90;
      end;
    // Straight down, the plan square to the picture
    pjPlanOblique:
      AInclination := 90;
    pjTrueIsometric:
      begin
        AAzimuth := 45;
        AInclination := SPRITELY_PROJECTION_ISOMETRIC_INCLINATION;
      end;
    pjDimetric:
      begin
        AAzimuth := 45;
        AInclination := SPRITELY_PROJECTION_DIMETRIC_INCLINATION;
      end;
    pjTrimetric:
      begin
        AAzimuth := 35;
        AInclination := 45;
      end;
  else
    Result := False;
  end;
end;

function TSpritelyProjection.ApplyCameraPreset: Boolean;
var
  Azimuth, Inclination: Single;
  F: ISpritelyProjectionFocus;
begin
  Result := (FFocus <> nil) and PresetAngles(FKind, Azimuth, Inclination) and
    Supports(FFocus, ISpritelyProjectionFocus, F);
  if Result then
  begin
    F.ProjectionViewAngles(Azimuth, Inclination);
    Log(Format('Camera turned for the projection: azimuth %.3f, inclination %.3f, roll 0',
      [Azimuth, Inclination]));
  end;
end;

procedure TSpritelyProjection.SetFieldOfView(const Value: Single);
var
  OldFov, NewFov: Single;
  F: ISpritelyProjectionFocus;
begin
  if (Value < 0) or (Value >= 180) or (Value = FFieldOfView) then
    Exit;
  OldFov := EffectiveFieldOfView;
  FFieldOfView := Value;
  NewFov := EffectiveFieldOfView;
  // The dolly zoom: the Focus moves so the target plane keeps its size.
  // Not while loading: the stored distance is already the right one
  if FDolly and FActive and (FFocus <> nil) and not (csLoading in ComponentState) and
    (OldFov > 0) and (NewFov > 0) and Supports(FFocus, ISpritelyProjectionFocus, F) then
    F.ProjectionLensChanged(OldFov, NewFov);
  Changed;
end;

procedure TSpritelyProjection.SetShiftX(const Value: Single);
begin
  FShiftX := Value;
  Changed;
end;

procedure TSpritelyProjection.SetShiftY(const Value: Single);
begin
  FShiftY := Value;
  Changed;
end;

procedure TSpritelyProjection.SetObliqueAngle(const Value: Single);
begin
  FObliqueAngle := Value;
  Changed;
end;

procedure TSpritelyProjection.SetObliqueScale(const Value: Single);
begin
  FObliqueScale := Value;
  Changed;
end;

procedure TSpritelyProjection.SetDistance(const Value: Single);
begin
  if Value > 0 then
    FDistance := Value;
  Changed;
end;

procedure TSpritelyProjection.SetManageCulling(const Value: Boolean);
begin
  FManageCulling := Value;
  Changed;
end;

function TSpritelyProjection.IsFieldOfViewStored: Boolean;
begin
  Result := FFieldOfView <> 0;
end;

function TSpritelyProjection.IsShiftXStored: Boolean;
begin
  Result := FShiftX <> 0;
end;

function TSpritelyProjection.IsShiftYStored: Boolean;
begin
  Result := FShiftY <> 0;
end;

function TSpritelyProjection.IsObliqueAngleStored: Boolean;
begin
  Result := FObliqueAngle <> SPRITELY_PROJECTION_OBLIQUE_ANGLE;
end;

function TSpritelyProjection.IsObliqueScaleStored: Boolean;
begin
  Result := FObliqueScale <> SPRITELY_PROJECTION_OBLIQUE_SCALE;
end;

function TSpritelyProjection.IsDistanceStored: Boolean;
begin
  Result := FDistance <> SPRITELY_PROJECTION_DEFAULT_DISTANCE;
end;

end.
