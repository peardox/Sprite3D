//** @abstract(Writes a model loaded by Gorilla3D as a GLB file: its nodes, static meshes,
//** materials and textures, put together here and saved through GLTFLib.)
//**
//** Gorilla3D loads every format it reads (FBX, USD, OBJ, Collada, STL, PLY, glTF) into the
//** same tree of definitions, a TModelDef. This unit walks that tree and writes it out as
//** glTF 2.0:
//**
//** @unorderedList(
//**   @item(every TTransformDef becomes a node, with its Transform as the node's matrix, and
//**     its children as the node's children;)
//**   @item(a mesh definition with vertex data becomes a mesh: POSITION, NORMAL, TEXCOORD_0
//**     and, if asked for, COLOR_0, shared by its primitives. The primitives are its vertex
//**     groups when it is drawn by them, otherwise its own indices;)
//**   @item(each material used becomes a metallic-roughness material: the diffuse colour and
//**     opacity as the base colour, the emissive colour, metallic and roughness (estimated
//**     from the specular power for a material that is not PBR), double-sidedness and alpha
//**     mode;)
//**   @item(the diffuse, normal, emissive and ambient-occlusion textures, as Gorilla holds
//**     them, flipped as it draws them, embedded as PNG.)
//** )
//**
//** Skins and animations are written too (see TGltfExportOptions.Skins and Animations):
//** the joints become nodes, each skinned mesh gets JOINTS_0, WEIGHTS_0 and a skin, and each
//** animation's stages become channels on the nodes they drive. A node an animation drives
//** is written as translation, rotation and scale, as glTF requires; every other node keeps
//** its matrix. Morph targets, lights and cameras are not written; the nodes of lights and
//** cameras are written as empty nodes.
//**
//** The coordinates are written as Gorilla holds them. Whether that is right is what
//** ImportTests (in ImportTests/) was for: TGltfExportOptions can negate any axis, reverse
//** the winding and flip V. GLB, glTF, FBX and USD all came out right with the defaults; see
//** notes/imports.md.
//**
//** The GLB is put together in memory, then loaded by GLTFLib's TglTFDocument, which checks
//** it, and saved by it. A file GLTFLib refuses is written beside the output as .raw.glb for
//** inspection.
//**
//** Uses Gorilla.DefTypes, FMX for the vertex buffers and bitmaps, and GLTFLib. Knows nothing
//** of the application.
unit Sprite3DGltfExport;

interface

uses
  System.SysUtils, System.Classes,
  Gorilla.DefTypes;

type
  //** @abstract(How a model is written; see @link(TGltfExportOptions.Create) for the
  //** defaults.)
  TGltfExportOptions = record
    //** @abstract(Negates X in every position, normal and node matrix.)
    NegateX: Boolean;
    //** @abstract(Negates Y in every position, normal and node matrix.)
    NegateY: Boolean;
    //** @abstract(Negates Z in every position, normal and node matrix.)
    NegateZ: Boolean;
    //** @abstract(Reverses the order of every triangle's corners; on by default.)
    //**
    //** Gorilla3D holds triangles the other way round from glTF: a GLB loaded and written
    //** back without this had every triangle reversed (mashed_potatos.glb, 10 November
    //** 2026), so it is on by default. An odd number of negated axes mirrors the model,
    //** which reverses the triangles again; that is allowed for as well.
    ReverseWinding: Boolean;
    //** @abstract(Writes V as 1 - V in every texture coordinate.)
    FlipV: Boolean;
    //** @abstract(Writes the vertex colours as COLOR_0, when the mesh has them.)
    //**
    //** Off by default: glTF multiplies the base colour by COLOR_0, and FMX vertex buffers
    //** often carry colours nothing draws.
    VertexColors: Boolean;
    //** @abstract(Embeds the materials' textures.)
    Textures: Boolean;
    //** @abstract(Also writes the GLB as put together here, before GLTFLib loads and saves
    //** it, as <name>.raw.glb.)
    WriteRaw: Boolean;
    //** @abstract(Scales the model by Gorilla's UnitScale, so the GLB is in metres; off by
    //** default.)
    //**
    //** Gorilla keeps an FBX in its own units (centimetres are usual, UnitScale 0.01) and
    //** shows it at that size. glTF is in metres, so a converted FBX is 100 times too big in
    //** other viewers unless this is on. It is written as a parent node with that scale, so
    //** the vertices are not changed. Off by default, so the two views compare.
    ApplyUnitScale: Boolean;
    //** @abstract(Writes skins: the joints as nodes, JOINTS_0 and WEIGHTS_0, and the inverse
    //** bind matrices; on by default.)
    //**
    //** The weights come from each joint reference's vertex indices and weights, mapped to
    //** the drawn vertices through the mesh's VertexIndexMap as Gorilla does; the four
    //** heaviest are kept and made to add up to 1. The inverse bind matrices are worked out
    //** from the joints' rest transforms, so the rest pose is the bind pose.
    Skins: Boolean;
    //** @abstract(Writes the animations; on by default.)
    //**
    //** Each stage drives the node of the definition it refers to. Matrix keys
    //** (TransformMatrix) become translation, rotation and scale channels; Position.Point,
    //** Scale.Point and Quaternion keys become one channel each. Key times are the
    //** interpolator's normalised keys times its Duration, in seconds, and every channel is
    //** written as LINEAR. Other kinds of key are listed in the log as left out.
    Animations: Boolean;
    //** @abstract(Leaves out animation keys that the keys either side give anyway; on by
    //** default.)
    //**
    //** Gorilla holds each joint's keys as matrices at every time any of its channels has a
    //** key, so translation, rotation and scale all get keys where the source had few. A
    //** key is left out when interpolating between the keys kept either side of it gives
    //** its value to 1E-5 (times the channel's largest value, if over 1), checked for every
    //** key left out between them. A channel that never changes keeps one key.
    ThinKeys: Boolean;
    //** @abstract(Returns the defaults: nothing negated or flipped, the winding reversed,
    //** textures, skins and animations on, vertex colours and the raw file off.)
    class function Create: TGltfExportOptions; static;
  end;

  //** @abstract(What was written.)
  TGltfExportStats = record
    //** @abstract(Nodes written.)
    Nodes: Integer;
    //** @abstract(Meshes written.)
    Meshes: Integer;
    //** @abstract(Primitives written, over every mesh.)
    Primitives: Integer;
    //** @abstract(Vertices written, over every mesh.)
    Vertices: Integer;
    //** @abstract(Triangles written, over every primitive.)
    Triangles: Integer;
    //** @abstract(Materials written.)
    Materials: Integer;
    //** @abstract(Images embedded.)
    Images: Integer;
    //** @abstract(Skins written.)
    Skins: Integer;
    //** @abstract(Joints over every skin written.)
    Joints: Integer;
    //** @abstract(Animations written.)
    Animations: Integer;
    //** @abstract(Channels over every animation written.)
    Channels: Integer;
    //** @abstract(Animation keys Gorilla held, over every channel.)
    KeysHeld: Integer;
    //** @abstract(Animation keys written, after ThinKeys.)
    KeysWritten: Integer;
    //** @abstract(Size of the GLB put together, in bytes.)
    Bytes: Int64;
  end;

  //** @abstract(What a model's definitions hold, counted the way BuildGlb would write
  //** them.)
  TGltfModelCounts = record
    //** @abstract(Mesh definitions with vertex data.)
    Meshes: Integer;
    //** @abstract(Their vertices.)
    Vertices: Integer;
    //** @abstract(Triangles they draw.)
    Triangles: Integer;
    //** @abstract(Materials in the model's table.)
    Materials: Integer;
    //** @abstract(Animations in the model.)
    Animations: Integer;
    //** @abstract(Skins, counted as the controllers that have one.)
    Skins: Integer;
  end;

//** @abstract(Puts a model together as GLB bytes.)
//**
//** @param(AModel The model's definitions, as TGorillaModel.Def holds them.)
//**
//** @param(AOptions How to write it.)
//**
//** @param(ALog Gets a line for each mesh and material, and for anything left out; may be
//** nil.)
//**
//** @param(AStats What was written.)
//**
//** @returns(The whole GLB file.)
//**
//** @raises(Exception The model holds no mesh that could be written.)
function BuildGlb(const AModel: TModelDef; const AOptions: TGltfExportOptions;
  const ALog: TStrings; out AStats: TGltfExportStats): TBytes;

//** @abstract(Writes a model as a GLB file, through GLTFLib.)
//**
//** BuildGlb puts it together; TglTFDocument loads the bytes, which checks them, and saves
//** them. GLTFLib's warnings go to ALog. When GLTFLib refuses the bytes, they are written as
//** <name>.raw.glb before the error is raised again.
//**
//** @param(AModel The model's definitions.)
//**
//** @param(AFileName The output; its extension should be .glb.)
//**
//** @param(AOptions How to write it.)
//**
//** @param(ALog Gets the lines of BuildGlb and GLTFLib's warnings; may be nil.)
//**
//** @param(AStats What was written.)
//**
//** @raises(Exception See BuildGlb; also GLTFLib's EglTFError and file errors.)
procedure ExportGlb(const AModel: TModelDef; const AFileName: string;
  const AOptions: TGltfExportOptions; const ALog: TStrings; out AStats: TGltfExportStats);

//** @abstract(Counts what a model's definitions hold, for comparing a model with its
//** export.)
//**
//** @param(AModel The model's definitions; nil gives all zeros.)
//**
//** @returns(The counts.)
function CountModel(const AModel: TModelDef): TGltfModelCounts;

//** @abstract(Lists the classes of a model's definitions and how many of each, as
//** "TMeshDef 3, TJointDef 40", for the log.)
//**
//** @param(AModel The model's definitions; nil gives an empty string.)
//**
//** @returns(The list.)
function DescribeModel(const AModel: TModelDef): string;

//** @abstract(Lists a model's animations with their length in seconds and number of stages,
//** as "walk 1.20 s 34 stages, idle 2.00 s 34 stages".)
//**
//** @param(AModel The model's definitions; nil gives an empty string.)
//**
//** @returns(The list, or an empty string when there are none.)
function DescribeAnimations(const AModel: TModelDef): string;

implementation

uses
  System.Types, System.UITypes, System.Math, System.Math.Vectors, System.JSON,
  System.TypInfo, System.StrUtils, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults, System.RTLConsts,
  FMX.Types, FMX.Types3D, FMX.Graphics,
  glTF.Document;

const
  // glTF numbers, kept here so nothing hangs on GLTFLib's constant names
  GL_UNSIGNED_BYTE = 5121;
  GL_UNSIGNED_SHORT = 5123;
  GL_UNSIGNED_INT = 5125;
  GL_FLOAT = 5126;
  GL_ARRAY_BUFFER = 34962;
  GL_ELEMENT_ARRAY_BUFFER = 34963;
  GL_LINEAR = 9729;
  GL_LINEAR_MIPMAP_LINEAR = 9987;

  GLB_MAGIC = $46546C67;   // 'glTF'
  GLB_VERSION = 2;
  GLB_CHUNK_JSON = $4E4F534A;
  GLB_CHUNK_BIN = $004E4942;

  GENERATOR = 'Sprite3D (Gorilla3D definitions, GLTFLib)';

  // Below this a matrix entry counts as equal to the identity's
  MATRIX_TOLERANCE = 1E-6;

type
  TTextureInfo = record
    Index: Integer;
    HasAlpha: Boolean;
  end;

  // A skinned mesh's node, waiting for the joints' nodes to be written
  TPendingSkin = record
    Node: Integer;
    Mesh: TCustomMeshDef;
    Skin: TSkinDef;
  end;

  // A transform taken apart as glTF wants it
  TTrs = record
    T: TPoint3D;
    // x, y, z, w
    R: array[0..3] of Single;
    S: TPoint3D;
    // The three axes are not at right angles, so no TRS gives the matrix
    Sheared: Boolean;
  end;

  TGlbBuilder = class
  private
    FModel: TModelDef;
    FOptions: TGltfExportOptions;
    FLog: TStrings;
    FStats: TGltfExportStats;
    FSign: array[0..2] of Single;
    FReverse: Boolean;
    FBin: TMemoryStream;
    FNodes: TJSONArray;
    FMeshes: TJSONArray;
    FAccessors: TJSONArray;
    FViews: TJSONArray;
    FMaterials: TJSONArray;
    FTextures: TJSONArray;
    FImages: TJSONArray;
    FMaterialIndex: TDictionary<TMaterialDef, Integer>;
    FTextureIndex: TDictionary<TTextureDef, TTextureInfo>;
    // The PNG bytes of each image written, by image index, so a picture used by
    // several textures is stored once
    FImageBytes: TList<TBytes>;
    // Every definition written as a node, with its node index (-1 while its
    // children are being written), and its global transform in Gorilla's terms
    FNodeIndex: TDictionary<TTransformDef, Integer>;
    FGlobal: TDictionary<TTransformDef, TMatrix3D>;
    // Definitions an animation drives, written as TRS rather than a matrix
    FAnimated: TDictionary<TTransformDef, Boolean>;
    FMeshSkin: TDictionary<TCustomMeshDef, TSkinDef>;
    FPendingSkins: TList<TPendingSkin>;
    FSkins: TJSONArray;
    FAnimations: TJSONArray;
    procedure Log(const AText: string);
    function Conjugated(const AMatrix: TMatrix3D): TMatrix3D;
    function ChildrenOf(const ADef: TTransformDef): TArray<TTransformDef>;
    procedure FindSkinsAndAnimated;
    procedure AddArmatures(const ARootNode: Integer);
    procedure WriteSkinAttributes(const AMesh: TCustomMeshDef; const ASkin: TSkinDef;
      const AAttributes: TJSONObject);
    procedure WriteSkins;
    function AddFloatAccessor(const AValues: TArray<Single>; const ACount: Integer;
      const AType: string; const AMinMax: Boolean): Integer;
    procedure AddChannel(const ANode: Integer; const APath: string;
      const ATimes, AValues: TArray<Single>; const AType: string;
      const ASamplers, AChannels: TJSONArray);
    procedure AddInterpolatorChannels(const AInterpolator: TCustomDef; const ANode: Integer;
      const ADuration: Single; const ASamplers, AChannels: TJSONArray; var ASkipped: string);
    procedure WriteAnimations;
    function AddView(const AData; const ASize, ATarget: Integer): Integer;
    function AddAccessor(const AView, AComponent, ACount: Integer; const AType: string;
      const ANormalized: Boolean): TJSONObject;
    function NodeMatrix(const AMatrix: TMatrix3D): TJSONArray;
    function AddNode(const ADef: TTransformDef; const AParentGlobal: TMatrix3D): Integer;
    function AddMesh(const AMesh: TCustomMeshDef): Integer;
    function WriteAttributes(const ABuffer: TVertexBuffer; const AName: string): TJSONObject;
    function AddPrimitive(const AIndices: TIndexBuffer; const AMaterial: TMaterialRefDef;
      const AVertexCount: Integer; const AAttributes: TJSONObject;
      const APrimitives: TJSONArray; const AName: string): Boolean;
    function ResolveMaterial(const ARef: TMaterialRefDef): TMaterialDef;
    function MaterialFor(const ARef: TMaterialRefDef): Integer;
    function TextureFor(const ATexture: TTextureDef): TTextureInfo;
    function AddBitmapTexture(const ABitmap: TBitmap; const AName, ANote: string): TTextureInfo;
    function MetallicRoughnessFor(const AMaterial: TMaterialDef): Integer;
    procedure AddTextureRef(const AParent: TJSONObject; const AName: string;
      const AMaterial: TMaterialDef; const AChannel: TColorChannelDef;
      out AInfo: TTextureInfo);
    function AddScaleNode(const AChild: Integer; const AScale: Single): Integer;
    procedure TakeArray(const ARoot: TJSONObject; const AName: string; var AArray: TJSONArray);
  public
    constructor Create(const AModel: TModelDef; const AOptions: TGltfExportOptions;
      const ALog: TStrings);
    destructor Destroy; override;
    function Build: TBytes;
    property Stats: TGltfExportStats read FStats;
  end;

// Helpers

function Clamp01(const AValue: Single): Single;
begin
  if IsNan(AValue) then
    Result := 0
  else
    Result := EnsureRange(AValue, 0, 1);
end;

function Finite(const AValue: Single): Single;
begin
  if IsNan(AValue) or IsInfinite(AValue) then
    Result := 0
  else
    Result := AValue;
end;

function JNum(const AValue: Double): TJSONNumber;
begin
  Result := TJSONNumber.Create(AValue);
end;

function JInt(const AValue: Int64): TJSONNumber;
begin
  Result := TJSONNumber.Create(AValue);
end;

function KindName(const AKind: TMaterialDefKind): string;
begin
  Result := GetEnumName(TypeInfo(TMaterialDefKind), Ord(AKind));
end;

function ChannelName(const AChannel: TColorChannelDef): string;
begin
  Result := GetEnumName(TypeInfo(TColorChannelDef), Ord(AChannel));
end;

// Gorilla's starting diffuse, from TMaterialDef's constructor
function IsDefaultDiffuse(const AColour: TAlphaColorF): Boolean;
const
  GREY = 0.75;
  CLOSE_ENOUGH = 1E-4;
begin
  Result := (Abs(AColour.R - GREY) < CLOSE_ENOUGH) and (Abs(AColour.G - GREY) < CLOSE_ENOUGH) and
    (Abs(AColour.B - GREY) < CLOSE_ENOUGH);
end;

function FaceName(const AFaces: TFaceOrientation): string;
begin
  Result := GetEnumName(TypeInfo(TFaceOrientation), Ord(AFaces));
end;

function DefName(const ADef: TCustomDef): string;
begin
  if (ADef = nil) or (ADef.Id = '') then
    Result := '(unnamed)'
  else
    Result := ADef.Id;
end;

// True when any pixel is not fully opaque. Scans the bytes directly for the
// two 32-bit formats FMX uses, through GetPixel otherwise.
function BitmapHasAlpha(const ABitmap: TBitmap): Boolean;
var
  Data: TBitmapData;
  X, Y: Integer;
  Row: PByte;
begin
  Result := False;
  if not ABitmap.Map(TMapAccess.Read, Data) then
    Exit;
  try
    if Data.PixelFormat in [TPixelFormat.BGRA, TPixelFormat.RGBA] then
    begin
      for Y := 0 to Data.Height - 1 do
      begin
        Row := Data.GetScanline(Y);
        for X := 0 to Data.Width - 1 do
          if Row[X * 4 + 3] < 255 then
            Exit(True);
      end;
    end
    else
      for Y := 0 to Data.Height - 1 do
        for X := 0 to Data.Width - 1 do
          if TAlphaColorRec(Data.GetPixel(X, Y)).A < 255 then
            Exit(True);
  finally
    ABitmap.Unmap(Data);
  end;
end;

// Whether a mesh is drawn by its vertex groups: when Gorilla says so, or
// when it has no indices of its own but has groups
function UsesVertexGroups(const AMesh: TCustomMeshDef): Boolean;
var
  Child: TTransformDef;
begin
  Result := False;
  if not (AMesh is TMeshDef) then
    Exit;
  if TMeshDef(AMesh).RenderByVertexGroups then
    Exit(True);
  if (AMesh.IndexSource <> nil) and (AMesh.IndexSource.Length > 0) then
    Exit;
  if AMesh.Children <> nil then
    for Child in AMesh.Children do
      if Child is TVertexGroupDef then
        Exit(True);
end;

function IndexCount(const AIndices: TIndexBuffer; const AVertexCount: Integer): Integer;
begin
  if (AIndices = nil) or (AIndices.Length = 0) then
  begin
    if AVertexCount mod 3 = 0 then
      Result := AVertexCount
    else
      Result := 0;
  end
  else
    Result := AIndices.Length - (AIndices.Length mod 3);
end;

// Takes an FMX matrix apart. FMX matrices act on row vectors: the first three
// rows are the images of the axes, and the fourth row the translation. glTF's
// rotation matrix acts on column vectors, so its columns are those rows.
function Decompose(const M: TMatrix3D): TTrs;
var
  R1, R2, R3: TPoint3D;
  SX, SY, SZ, Trace, K: Single;
  A: array[0..2, 0..2] of Single;
  Len: Single;
  I: Integer;
begin
  Result.T := Point3D(M.m41, M.m42, M.m43);
  R1 := Point3D(M.m11, M.m12, M.m13);
  R2 := Point3D(M.m21, M.m22, M.m23);
  R3 := Point3D(M.m31, M.m32, M.m33);
  SX := R1.Length;
  SY := R2.Length;
  SZ := R3.Length;
  // A mirror is put into the scale of X
  if R1.DotProduct(R2.CrossProduct(R3)) < 0 then
    SX := -SX;
  Result.S := Point3D(SX, SY, SZ);
  Result.Sheared := False;
  if (Abs(SX) < 1E-12) or (Abs(SY) < 1E-12) or (Abs(SZ) < 1E-12) then
  begin
    Result.R[0] := 0;
    Result.R[1] := 0;
    Result.R[2] := 0;
    Result.R[3] := 1;
    Exit;
  end;
  R1 := R1 / SX;
  R2 := R2 / SY;
  R3 := R3 / SZ;
  if (Abs(R1.DotProduct(R2)) > 1E-3) or (Abs(R1.DotProduct(R3)) > 1E-3) or
    (Abs(R2.DotProduct(R3)) > 1E-3) then
    Result.Sheared := True;
  // A[row, column] of glTF's rotation: column j is FMX's row j
  A[0, 0] := R1.X; A[0, 1] := R2.X; A[0, 2] := R3.X;
  A[1, 0] := R1.Y; A[1, 1] := R2.Y; A[1, 2] := R3.Y;
  A[2, 0] := R1.Z; A[2, 1] := R2.Z; A[2, 2] := R3.Z;
  Trace := A[0, 0] + A[1, 1] + A[2, 2];
  if Trace > 0 then
  begin
    K := Sqrt(Trace + 1) * 2;
    Result.R[3] := 0.25 * K;
    Result.R[0] := (A[2, 1] - A[1, 2]) / K;
    Result.R[1] := (A[0, 2] - A[2, 0]) / K;
    Result.R[2] := (A[1, 0] - A[0, 1]) / K;
  end
  else if (A[0, 0] > A[1, 1]) and (A[0, 0] > A[2, 2]) then
  begin
    K := Sqrt(1 + A[0, 0] - A[1, 1] - A[2, 2]) * 2;
    Result.R[3] := (A[2, 1] - A[1, 2]) / K;
    Result.R[0] := 0.25 * K;
    Result.R[1] := (A[0, 1] + A[1, 0]) / K;
    Result.R[2] := (A[0, 2] + A[2, 0]) / K;
  end
  else if A[1, 1] > A[2, 2] then
  begin
    K := Sqrt(1 + A[1, 1] - A[0, 0] - A[2, 2]) * 2;
    Result.R[3] := (A[0, 2] - A[2, 0]) / K;
    Result.R[0] := (A[0, 1] + A[1, 0]) / K;
    Result.R[1] := 0.25 * K;
    Result.R[2] := (A[1, 2] + A[2, 1]) / K;
  end
  else
  begin
    K := Sqrt(1 + A[2, 2] - A[0, 0] - A[1, 1]) * 2;
    Result.R[3] := (A[1, 0] - A[0, 1]) / K;
    Result.R[0] := (A[0, 2] + A[2, 0]) / K;
    Result.R[1] := (A[1, 2] + A[2, 1]) / K;
    Result.R[2] := 0.25 * K;
  end;
  Len := 0;
  for I := 0 to 3 do
    Len := Len + Sqr(Result.R[I]);
  Len := Sqrt(Len);
  if Len > 0 then
    for I := 0 to 3 do
      Result.R[I] := Result.R[I] / Len;
end;

// Keeps a run of quaternions on one side, so LINEAR goes the short way round
procedure KeepNear(var AQ: array of Single; const APrevious: array of Single);
var
  Dot: Single;
  I: Integer;
begin
  Dot := 0;
  for I := 0 to 3 do
    Dot := Dot + AQ[I] * APrevious[I];
  if Dot < 0 then
    for I := 0 to 3 do
      AQ[I] := -AQ[I];
end;

function MatrixDifference(const A, B: TMatrix3D): Single;
var
  I, J: Integer;
begin
  Result := 0;
  for I := 0 to 3 do
    for J := 0 to 3 do
      Result := Max(Result, Abs(A.M[I].V[J] - B.M[I].V[J]));
end;

{ TGltfExportOptions }

class function TGltfExportOptions.Create: TGltfExportOptions;
begin
  Result.NegateX := False;
  Result.NegateY := False;
  Result.NegateZ := False;
  Result.ReverseWinding := True;
  Result.FlipV := False;
  Result.VertexColors := False;
  Result.Textures := True;
  Result.WriteRaw := False;
  Result.ApplyUnitScale := False;
  Result.Skins := True;
  Result.Animations := True;
  Result.ThinKeys := True;
end;

{ TGlbBuilder }

constructor TGlbBuilder.Create(const AModel: TModelDef; const AOptions: TGltfExportOptions;
  const ALog: TStrings);
var
  Negated: Integer;
begin
  inherited Create;
  FModel := AModel;
  FOptions := AOptions;
  FLog := ALog;
  FillChar(FStats, SizeOf(FStats), 0);
  FSign[0] := IfThen(AOptions.NegateX, -1, 1);
  FSign[1] := IfThen(AOptions.NegateY, -1, 1);
  FSign[2] := IfThen(AOptions.NegateZ, -1, 1);
  Negated := Ord(AOptions.NegateX) + Ord(AOptions.NegateY) + Ord(AOptions.NegateZ);
  // A mirror turns every triangle round; ReverseWinding turns it back
  FReverse := AOptions.ReverseWinding xor Odd(Negated);
  FBin := TMemoryStream.Create;
  FNodes := TJSONArray.Create;
  FMeshes := TJSONArray.Create;
  FAccessors := TJSONArray.Create;
  FViews := TJSONArray.Create;
  FMaterials := TJSONArray.Create;
  FTextures := TJSONArray.Create;
  FImages := TJSONArray.Create;
  FMaterialIndex := TDictionary<TMaterialDef, Integer>.Create;
  FTextureIndex := TDictionary<TTextureDef, TTextureInfo>.Create;
  FImageBytes := TList<TBytes>.Create;
  FNodeIndex := TDictionary<TTransformDef, Integer>.Create;
  FGlobal := TDictionary<TTransformDef, TMatrix3D>.Create;
  FAnimated := TDictionary<TTransformDef, Boolean>.Create;
  FMeshSkin := TDictionary<TCustomMeshDef, TSkinDef>.Create;
  FPendingSkins := TList<TPendingSkin>.Create;
  FSkins := TJSONArray.Create;
  FAnimations := TJSONArray.Create;
end;

destructor TGlbBuilder.Destroy;
begin
  // Arrays handed to the JSON root are nil here; the rest are freed
  FNodes.Free;
  FMeshes.Free;
  FAccessors.Free;
  FViews.Free;
  FMaterials.Free;
  FTextures.Free;
  FImages.Free;
  FMaterialIndex.Free;
  FTextureIndex.Free;
  FImageBytes.Free;
  FNodeIndex.Free;
  FGlobal.Free;
  FAnimated.Free;
  FMeshSkin.Free;
  FPendingSkins.Free;
  FSkins.Free;
  FAnimations.Free;
  FBin.Free;
  inherited;
end;

procedure TGlbBuilder.Log(const AText: string);
begin
  if FLog <> nil then
    FLog.Add(AText);
end;

function TGlbBuilder.AddView(const AData; const ASize, ATarget: Integer): Integer;
const
  Zero: Byte = 0;
var
  View: TJSONObject;
begin
  // Every view starts on a 4-byte boundary, which every accessor type needs
  while FBin.Size mod 4 <> 0 do
    FBin.WriteBuffer(Zero, 1);
  View := TJSONObject.Create;
  View.AddPair('buffer', JInt(0));
  if FBin.Size > 0 then
    View.AddPair('byteOffset', JInt(FBin.Size));
  View.AddPair('byteLength', JInt(ASize));
  if ATarget <> 0 then
    View.AddPair('target', JInt(ATarget));
  FBin.Position := FBin.Size;
  if ASize > 0 then
    FBin.WriteBuffer(AData, ASize);
  FViews.AddElement(View);
  Result := FViews.Count - 1;
end;

function TGlbBuilder.AddAccessor(const AView, AComponent, ACount: Integer;
  const AType: string; const ANormalized: Boolean): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('bufferView', JInt(AView));
  Result.AddPair('componentType', JInt(AComponent));
  if ANormalized then
    Result.AddPair('normalized', TJSONBool.Create(True));
  Result.AddPair('count', JInt(ACount));
  Result.AddPair('type', AType);
  FAccessors.AddElement(Result);
end;

function TGlbBuilder.NodeMatrix(const AMatrix: TMatrix3D): TJSONArray;
var
  Values: array[0..15] of Single;
  Signs: array[0..3] of Single;
  Row, Col: Integer;
  Identity: Boolean;
  Expected: Single;
begin
  // FMX keeps a row-vector matrix row by row, translation in the fourth row:
  // in memory that is the column-major order glTF wants for its
  // column-vector matrix. Negating axes conjugates it by the sign matrix.
  Values[0] := AMatrix.m11;  Values[1] := AMatrix.m12;
  Values[2] := AMatrix.m13;  Values[3] := AMatrix.m14;
  Values[4] := AMatrix.m21;  Values[5] := AMatrix.m22;
  Values[6] := AMatrix.m23;  Values[7] := AMatrix.m24;
  Values[8] := AMatrix.m31;  Values[9] := AMatrix.m32;
  Values[10] := AMatrix.m33; Values[11] := AMatrix.m34;
  Values[12] := AMatrix.m41; Values[13] := AMatrix.m42;
  Values[14] := AMatrix.m43; Values[15] := AMatrix.m44;
  Signs[0] := FSign[0];
  Signs[1] := FSign[1];
  Signs[2] := FSign[2];
  Signs[3] := 1;
  Identity := True;
  for Row := 0 to 3 do
    for Col := 0 to 3 do
    begin
      Values[Row * 4 + Col] := Finite(Values[Row * 4 + Col] * Signs[Row] * Signs[Col]);
      if Row = Col then
        Expected := 1
      else
        Expected := 0;
      if Abs(Values[Row * 4 + Col] - Expected) > MATRIX_TOLERANCE then
        Identity := False;
    end;
  if Identity then
    Exit(nil);
  Result := TJSONArray.Create;
  for Row := 0 to 15 do
    Result.Add(Double(Values[Row]));
end;

function TGlbBuilder.Conjugated(const AMatrix: TMatrix3D): TMatrix3D;
var
  Signs: array[0..3] of Single;
  Row, Col: Integer;
begin
  // Negating axes turns every matrix into S * M * S
  Signs[0] := FSign[0];
  Signs[1] := FSign[1];
  Signs[2] := FSign[2];
  Signs[3] := 1;
  Result := AMatrix;
  for Row := 0 to 3 do
    for Col := 0 to 3 do
      Result.M[Row].V[Col] := AMatrix.M[Row].V[Col] * Signs[Row] * Signs[Col];
end;

function HasDef(const AList: TArray<TTransformDef>; const ADef: TTransformDef): Boolean;
var
  Item: TTransformDef;
begin
  for Item in AList do
    if Item = ADef then
      Exit(True);
  Result := False;
end;

function TGlbBuilder.ChildrenOf(const ADef: TTransformDef): TArray<TTransformDef>;
var
  Child: TTransformDef;
  Joints: TArray<TJointDef>;
  Joint: TJointDef;
begin
  Result := nil;
  if ADef.Children <> nil then
    for Child in ADef.Children do
      // A vertex group is drawn as a primitive of the mesh that owns it
      if not (Child is TVertexGroupDef) then
        Result := Result + [Child];
  // A joint's own joints, and an armature's roots, may not be among its
  // children; in name order, as the map has none
  if (ADef is TJointDef) and (TJointDef(ADef).Joints <> nil) then
  begin
    Joints := TJointDef(ADef).Joints.Values.ToArray;
    TArray.Sort<TJointDef>(Joints, TComparer<TJointDef>.Construct(
      function(const A, B: TJointDef): Integer
      begin
        Result := CompareStr(A.Id, B.Id);
      end));
    for Joint in Joints do
      if not HasDef(Result, Joint) then
        Result := Result + [TTransformDef(Joint)];
  end;
  if (ADef is TArmatureDef) and (TArmatureDef(ADef).Roots <> nil) then
    for Joint in TArmatureDef(ADef).Roots do
      if not HasDef(Result, Joint) then
        Result := Result + [TTransformDef(Joint)];
end;

function TGlbBuilder.AddNode(const ADef: TTransformDef; const AParentGlobal: TMatrix3D): Integer;
var
  Node: TJSONObject;
  Matrix, Kids, Values: TJSONArray;
  Child: TTransformDef;
  Mesh: Integer;
  Global: TMatrix3D;
  Trs: TTrs;
  Pending: TPendingSkin;
  Skin: TSkinDef;
begin
  FNodeIndex.Add(ADef, -1);
  // FMX matrices act on row vectors, so the parent's comes second
  Global := ADef.Transform * AParentGlobal;
  FGlobal.AddOrSetValue(ADef, Global);
  Mesh := -1;
  Node := TJSONObject.Create;
  try
    if ADef.Id <> '' then
      Node.AddPair('name', ADef.Id);
    if FAnimated.ContainsKey(ADef) then
    begin
      // glTF animates only translation, rotation and scale, never a matrix
      Trs := Decompose(Conjugated(ADef.Transform));
      if Trs.Sheared then
        Log('  node ' + DefName(ADef) + ': animated, but its matrix is sheared, so it ' +
          'cannot be taken apart exactly');
      if (Trs.T.X <> 0) or (Trs.T.Y <> 0) or (Trs.T.Z <> 0) then
      begin
        Values := TJSONArray.Create;
        Values.Add(Double(Finite(Trs.T.X)));
        Values.Add(Double(Finite(Trs.T.Y)));
        Values.Add(Double(Finite(Trs.T.Z)));
        Node.AddPair('translation', Values);
      end;
      if (Trs.R[0] <> 0) or (Trs.R[1] <> 0) or (Trs.R[2] <> 0) then
      begin
        Values := TJSONArray.Create;
        Values.Add(Double(Trs.R[0]));
        Values.Add(Double(Trs.R[1]));
        Values.Add(Double(Trs.R[2]));
        Values.Add(Double(Trs.R[3]));
        Node.AddPair('rotation', Values);
      end;
      if (Abs(Trs.S.X - 1) > MATRIX_TOLERANCE) or (Abs(Trs.S.Y - 1) > MATRIX_TOLERANCE) or
        (Abs(Trs.S.Z - 1) > MATRIX_TOLERANCE) then
      begin
        Values := TJSONArray.Create;
        Values.Add(Double(Finite(Trs.S.X)));
        Values.Add(Double(Finite(Trs.S.Y)));
        Values.Add(Double(Finite(Trs.S.Z)));
        Node.AddPair('scale', Values);
      end;
    end
    else
    begin
      Matrix := NodeMatrix(ADef.Transform);
      if Matrix <> nil then
        Node.AddPair('matrix', Matrix);
    end;
    if ADef is TCustomMeshDef then
    begin
      Mesh := AddMesh(TCustomMeshDef(ADef));
      if Mesh >= 0 then
        Node.AddPair('mesh', JInt(Mesh));
    end;
    Kids := TJSONArray.Create;
    Node.AddPair('children', Kids);
    for Child in ChildrenOf(ADef) do
      // A joint can be reached both as a child and through its armature
      if not FNodeIndex.ContainsKey(Child) then
        Kids.Add(AddNode(Child, Global));
    if Kids.Count = 0 then
      Node.RemovePair('children').Free;
  except
    Node.Free;
    raise;
  end;
  FNodes.AddElement(Node);
  Inc(FStats.Nodes);
  Result := FNodes.Count - 1;
  FNodeIndex[ADef] := Result;
  if (Mesh >= 0) and FMeshSkin.TryGetValue(TCustomMeshDef(ADef), Skin) then
  begin
    Pending.Node := Result;
    Pending.Mesh := TCustomMeshDef(ADef);
    Pending.Skin := Skin;
    FPendingSkins.Add(Pending);
  end;
end;

procedure TGlbBuilder.FindSkinsAndAnimated;
var
  Controller: TControllerDef;
  Skinned: TTransformDef;
  Key: TCustomMeshDef;
  Animation: TAnimationDef;
  Stage: TAnimationStageDef;
begin
  if FOptions.Skins and (FModel.Controllers <> nil) then
    for Controller in FModel.Controllers do
    begin
      if Controller.Skin = nil then
        Continue;
      for Skinned in Controller.Skin.GetSkinnedMeshes do
      begin
        // A vertex group's vertices are its owner's
        if (Skinned is TVertexGroupDef) and (Skinned.Owner is TCustomMeshDef) then
          Key := TCustomMeshDef(Skinned.Owner)
        else if Skinned is TCustomMeshDef then
          Key := TCustomMeshDef(Skinned)
        else
          Continue;
        if not FMeshSkin.ContainsKey(Key) then
          FMeshSkin.Add(Key, Controller.Skin);
      end;
    end;
  if FOptions.Animations and (FModel.Animations <> nil) then
    for Animation in FModel.Animations do
      if Animation.Stages <> nil then
        for Stage in Animation.Stages do
          if Stage.Reference is TTransformDef then
            FAnimated.AddOrSetValue(TTransformDef(Stage.Reference), True);
end;

procedure TGlbBuilder.AddArmatures(const ARootNode: Integer);
var
  Armature: TArmatureDef;
  Root: TJSONObject;
  Kids: TJSONArray;
  Parent: TMatrix3D;
begin
  if not (FOptions.Skins or FOptions.Animations) or (FModel.Armatures = nil) then
    Exit;
  // Armatures the tree of children did not reach go under the model's node
  Root := FNodes.Items[ARootNode] as TJSONObject;
  if not FGlobal.TryGetValue(FModel, Parent) then
    Parent := TMatrix3D.Identity;
  for Armature in FModel.Armatures do
  begin
    if FNodeIndex.ContainsKey(Armature) then
      Continue;
    Kids := Root.GetValue('children') as TJSONArray;
    if Kids = nil then
    begin
      Kids := TJSONArray.Create;
      Root.AddPair('children', Kids);
    end;
    Kids.Add(AddNode(Armature, Parent));
    Log('armature ' + DefName(Armature) + ': written under the model''s node');
  end;
end;

procedure TGlbBuilder.WriteSkinAttributes(const AMesh: TCustomMeshDef;
  const ASkin: TSkinDef; const AAttributes: TJSONObject);
var
  Count, J, I, K, Slot, View, Dropped, Unweighted, OutOfRange: Integer;
  Ref: TJointRefDef;
  Map: TVertexIndexMap;
  Drawn: TVertexIndices;
  Joints: TArray<Integer>;
  Weights: TArray<Single>;
  JointBytes: TArray<Byte>;
  JointShorts: TArray<Word>;
  Sum: Single;

  procedure Put(const AVertex, AJoint: Integer; const AWeight: Single);
  var
    S, Least: Integer;
  begin
    if (AVertex < 0) or (AVertex >= Count) then
    begin
      Inc(OutOfRange);
      Exit;
    end;
    // The same joint twice adds up; otherwise an empty slot, or the lightest
    // if this one is heavier
    for S := 0 to 3 do
      if (Weights[AVertex * 4 + S] > 0) and (Joints[AVertex * 4 + S] = AJoint) then
      begin
        Weights[AVertex * 4 + S] := Weights[AVertex * 4 + S] + AWeight;
        Exit;
      end;
    Least := 0;
    for S := 1 to 3 do
      if Weights[AVertex * 4 + S] < Weights[AVertex * 4 + Least] then
        Least := S;
    if Weights[AVertex * 4 + Least] > 0 then
    begin
      Inc(Dropped);
      if Weights[AVertex * 4 + Least] >= AWeight then
        Exit;
    end;
    Joints[AVertex * 4 + Least] := AJoint;
    Weights[AVertex * 4 + Least] := AWeight;
  end;

begin
  Count := AMesh.VertexSource.Length;
  SetLength(Joints, Count * 4);
  SetLength(Weights, Count * 4);
  Dropped := 0;
  Unweighted := 0;
  OutOfRange := 0;
  Map := AMesh.VertexIndexMap;
  for J := 0 to ASkin.LinkedJoints.Count - 1 do
  begin
    Ref := ASkin.LinkedJoints[J];
    if Ref = nil then
      Continue;
    // A joint that moves several meshes keeps a set of weights for each
    if Ref.HasMeshWeights then
      Ref.ApplyMeshWeights(AMesh.Id)
    else if (Ref.Controller <> nil) and (Ref.Target <> nil) and (Ref.Target <> AMesh) and
      not ((Ref.Target is TVertexGroupDef) and (Ref.Target.Owner = AMesh)) then
      Continue;
    for I := 0 to Min(High(Ref.Indices), High(Ref.Weights)) do
    begin
      if Ref.Weights[I] <= 0 then
        Continue;
      // Indices are the source file's vertices; the map gives the drawn ones
      if (Map <> nil) and (Map.Count > 0) then
      begin
        if Map.TryGetValue(TIndexType(Ref.Indices[I]), Drawn) then
          for K := 0 to High(Drawn) do
            Put(Integer(Drawn[K]), J, Ref.Weights[I]);
      end
      else
        Put(Ref.Indices[I], J, Ref.Weights[I]);
    end;
  end;
  for I := 0 to Count - 1 do
  begin
    Sum := 0;
    for Slot := 0 to 3 do
      Sum := Sum + Weights[I * 4 + Slot];
    if Sum > 0 then
    begin
      for Slot := 0 to 3 do
        Weights[I * 4 + Slot] := Weights[I * 4 + Slot] / Sum;
    end
    else
    begin
      // glTF wants every vertex weighted; an unweighted one follows joint 0
      Inc(Unweighted);
      Joints[I * 4] := 0;
      Weights[I * 4] := 1;
    end;
    // Unused slots point at joint 0 with no weight
    for Slot := 0 to 3 do
      if Weights[I * 4 + Slot] = 0 then
        Joints[I * 4 + Slot] := 0;
  end;
  if ASkin.LinkedJoints.Count <= 256 then
  begin
    SetLength(JointBytes, Count * 4);
    for I := 0 to Count * 4 - 1 do
      JointBytes[I] := Joints[I];
    View := AddView(JointBytes[0], Count * 4, GL_ARRAY_BUFFER);
    AddAccessor(View, GL_UNSIGNED_BYTE, Count, 'VEC4', False);
  end
  else
  begin
    SetLength(JointShorts, Count * 4);
    for I := 0 to Count * 4 - 1 do
      JointShorts[I] := Joints[I];
    View := AddView(JointShorts[0], Count * 8, GL_ARRAY_BUFFER);
    AddAccessor(View, GL_UNSIGNED_SHORT, Count, 'VEC4', False);
  end;
  AAttributes.AddPair('JOINTS_0', JInt(FAccessors.Count - 1));
  View := AddView(Weights[0], Count * 16, GL_ARRAY_BUFFER);
  AddAccessor(View, GL_FLOAT, Count, 'VEC4', False);
  AAttributes.AddPair('WEIGHTS_0', JInt(FAccessors.Count - 1));
  Log(Format('  skin %s on %s: %d joints', [DefName(ASkin), DefName(AMesh),
    ASkin.LinkedJoints.Count]));
  if Dropped > 0 then
    Log(Format('  %d weights beyond the four heaviest of a vertex left out', [Dropped]));
  if Unweighted > 0 then
    Log(Format('  %d vertices had no weight; they follow joint 0', [Unweighted]));
  if OutOfRange > 0 then
    Log(Format('  %d weights named a vertex the mesh does not have', [OutOfRange]));
end;

procedure TGlbBuilder.WriteSkins;
var
  Pending: TPendingSkin;
  Count, J, Index: Integer;
  Ref: TJointRefDef;
  MeshGlobal, JointGlobal, Inverse: TMatrix3D;
  Floats: TArray<Single>;
  JointNodes: TJSONArray;
  Skin, Node: TJSONObject;
  Ok: Boolean;
  Differs: Single;
  Compared: Integer;
begin
  for Pending in FPendingSkins do
  begin
    Count := Pending.Skin.LinkedJoints.Count;
    if Count = 0 then
      Continue;
    if not FGlobal.TryGetValue(Pending.Mesh, MeshGlobal) then
      MeshGlobal := TMatrix3D.Identity;
    SetLength(Floats, Count * 16);
    JointNodes := TJSONArray.Create;
    Ok := True;
    Differs := 0;
    Compared := 0;
    for J := 0 to Count - 1 do
    begin
      Ref := Pending.Skin.LinkedJoints[J];
      if (Ref = nil) or (Ref.Joint = nil) or not FNodeIndex.TryGetValue(Ref.Joint, Index) or
        (Index < 0) then
      begin
        Log(Format('skin %s: joint %d is not among the nodes written; skin left out',
          [DefName(Pending.Skin), J]));
        Ok := False;
        Break;
      end;
      JointNodes.Add(Index);
      if not FGlobal.TryGetValue(Ref.Joint, JointGlobal) then
        JointGlobal := TMatrix3D.Identity;
      // From the mesh's space to the joint's, at rest: row vectors, so the
      // mesh's global first, then the inverse of the joint's
      Inverse := MeshGlobal * JointGlobal.Inverse;
      if Ref.IsInvBindMatrixAvailable then
      begin
        Differs := Max(Differs, MatrixDifference(Inverse, Ref.InvBindMatrix));
        Inc(Compared);
      end;
      Inverse := Conjugated(Inverse);
      Move(Inverse, Floats[J * 16], 16 * SizeOf(Single));
    end;
    if not Ok then
    begin
      JointNodes.Free;
      Continue;
    end;
    Skin := TJSONObject.Create;
    if Pending.Skin.Id <> '' then
      Skin.AddPair('name', Pending.Skin.Id);
    Skin.AddPair('inverseBindMatrices',
      JInt(AddFloatAccessor(Floats, Count, 'MAT4', False)));
    Skin.AddPair('joints', JointNodes);
    FSkins.AddElement(Skin);
    Inc(FStats.Skins);
    Inc(FStats.Joints, Count);
    Node := FNodes.Items[Pending.Node] as TJSONObject;
    Node.AddPair('skin', JInt(FSkins.Count - 1));
    if Compared > 0 then
      Log(Format('skin %s: inverse bind matrices from the rest pose; Gorilla''s own differ ' +
        'by up to %.4g over %d joints', [DefName(Pending.Skin), Differs, Compared]))
    else
      Log('skin ' + DefName(Pending.Skin) + ': inverse bind matrices from the rest pose');
  end;
end;

function TGlbBuilder.AddFloatAccessor(const AValues: TArray<Single>; const ACount: Integer;
  const AType: string; const AMinMax: Boolean): Integer;
var
  View, Width, I, C: Integer;
  Acc: TJSONObject;
  MinArr, MaxArr: TJSONArray;
  Lo, Hi: Single;
begin
  Width := Length(AValues) div Max(1, ACount);
  View := AddView(AValues[0], Length(AValues) * SizeOf(Single), 0);
  Acc := AddAccessor(View, GL_FLOAT, ACount, AType, False);
  if AMinMax then
  begin
    MinArr := TJSONArray.Create;
    MaxArr := TJSONArray.Create;
    for C := 0 to Width - 1 do
    begin
      Lo := MaxSingle;
      Hi := -MaxSingle;
      for I := 0 to ACount - 1 do
      begin
        Lo := Min(Lo, AValues[I * Width + C]);
        Hi := Max(Hi, AValues[I * Width + C]);
      end;
      MinArr.Add(Double(Lo));
      MaxArr.Add(Double(Hi));
    end;
    Acc.AddPair('min', MinArr);
    Acc.AddPair('max', MaxArr);
  end;
  Result := FAccessors.Count - 1;
end;

// Leaves out the keys that interpolating between the kept keys either side
// gives anyway, to a tolerance; see TGltfExportOptions.ThinKeys
procedure ThinKeys(const ATimes, AValues: TArray<Single>; const AWidth: Integer;
  out AKeptTimes, AKeptValues: TArray<Single>);
var
  Count, Last, I, K, C: Integer;
  Tolerance, Biggest, U: Single;
  Kept: TList<Integer>;
  Same: Boolean;

  // Whether every key after Last up to ATo lies on the line from Last to ANext
  function Covered(const ATo, ANext: Integer): Boolean;
  var
    J, D: Integer;
  begin
    for J := Last + 1 to ATo do
    begin
      if ATimes[ANext] <= ATimes[Last] then
        Exit(False);
      U := (ATimes[J] - ATimes[Last]) / (ATimes[ANext] - ATimes[Last]);
      for D := 0 to AWidth - 1 do
        if Abs(AValues[Last * AWidth + D] +
          (AValues[ANext * AWidth + D] - AValues[Last * AWidth + D]) * U -
          AValues[J * AWidth + D]) > Tolerance then
          Exit(False);
    end;
    Result := True;
  end;

begin
  Count := Length(ATimes);
  Biggest := 0;
  for I := 0 to High(AValues) do
    Biggest := Max(Biggest, Abs(AValues[I]));
  Tolerance := 1E-5 * Max(1, Biggest);
  Kept := TList<Integer>.Create;
  try
    if Count > 0 then
      Kept.Add(0);
    Last := 0;
    for I := 1 to Count - 2 do
      if not Covered(I, I + 1) then
      begin
        Kept.Add(I);
        Last := I;
      end;
    if Count > 1 then
    begin
      K := Count - 1;
      Kept.Add(K);
      // Only the ends kept, and the same: every key lies between equal values,
      // so the channel never changes and one key is enough
      if Kept.Count = 2 then
      begin
        Same := True;
        for C := 0 to AWidth - 1 do
          if Abs(AValues[K * AWidth + C] - AValues[C]) > Tolerance then
            Same := False;
        if Same then
          Kept.Delete(1);
      end;
    end;
    SetLength(AKeptTimes, Kept.Count);
    SetLength(AKeptValues, Kept.Count * AWidth);
    for I := 0 to Kept.Count - 1 do
    begin
      AKeptTimes[I] := ATimes[Kept[I]];
      for C := 0 to AWidth - 1 do
        AKeptValues[I * AWidth + C] := AValues[Kept[I] * AWidth + C];
    end;
  finally
    Kept.Free;
  end;
end;

procedure TGlbBuilder.AddChannel(const ANode: Integer; const APath: string;
  const ATimes, AValues: TArray<Single>; const AType: string;
  const ASamplers, AChannels: TJSONArray);
var
  Sampler, Channel, Target: TJSONObject;
  Times, Values: TArray<Single>;
begin
  if Length(ATimes) = 0 then
    Exit;
  Inc(FStats.KeysHeld, Length(ATimes));
  if FOptions.ThinKeys then
    ThinKeys(ATimes, AValues, Length(AValues) div Length(ATimes), Times, Values)
  else
  begin
    Times := ATimes;
    Values := AValues;
  end;
  Inc(FStats.KeysWritten, Length(Times));
  Sampler := TJSONObject.Create;
  // The spec needs min and max on the times
  Sampler.AddPair('input', JInt(AddFloatAccessor(Times, Length(Times), 'SCALAR', True)));
  Sampler.AddPair('output', JInt(AddFloatAccessor(Values, Length(Times), AType, False)));
  Sampler.AddPair('interpolation', 'LINEAR');
  ASamplers.AddElement(Sampler);
  Target := TJSONObject.Create;
  Target.AddPair('node', JInt(ANode));
  Target.AddPair('path', APath);
  Channel := TJSONObject.Create;
  Channel.AddPair('sampler', JInt(ASamplers.Count - 1));
  Channel.AddPair('target', Target);
  AChannels.AddElement(Channel);
  Inc(FStats.Channels);
end;

procedure TGlbBuilder.AddInterpolatorChannels(const AInterpolator: TCustomDef;
  const ANode: Integer; const ADuration: Single; const ASamplers, AChannels: TJSONArray;
  var ASkipped: string);
var
  Keys: TInterpolatorKeyDefList;
  Duration, Time, Last: Single;
  Path: string;
  Times, Moves, Turns, Sizes: TArray<Single>;
  N, I: Integer;
  Trs: TTrs;
  Previous: array[0..3] of Single;
  Rotation: TMatrix3D;
  Point: TPoint3D;
  MatrixKey: TInterpolatorKeyDef<TMatrix3D>;
  PointKey: TInterpolatorKeyDef<TPoint3D>;
  TurnKey: TInterpolatorKeyDef<TQuaternion3D>;

  procedure Skip(const AWhat: string);
  begin
    if Pos(AWhat, ASkipped) = 0 then
      ASkipped := ASkipped + ' ' + AWhat;
  end;

  // The keys' times in seconds; False for a key that does not move time on
  function KeyTime(const AKey: Single): Boolean;
  begin
    Time := AKey * Duration;
    Result := (N = 0) or (Time > Last);
    if Result then
      Last := Time;
  end;

  procedure AddRotation(const AMatrix: TMatrix3D);
  var
    C: Integer;
  begin
    Trs := Decompose(Conjugated(AMatrix));
    if N > 0 then
      KeepNear(Trs.R, Previous);
    for C := 0 to 3 do
    begin
      Turns[N * 4 + C] := Trs.R[C];
      Previous[C] := Trs.R[C];
    end;
  end;

begin
  if AInterpolator is TTransformationInterpolatorDef then
  begin
    Keys := TTransformationInterpolatorDef(AInterpolator).Keys;
    Duration := TTransformationInterpolatorDef(AInterpolator).Duration;
  end
  else if AInterpolator is TPoint3DInterpolatorDef then
  begin
    Keys := TPoint3DInterpolatorDef(AInterpolator).Keys;
    Duration := TPoint3DInterpolatorDef(AInterpolator).Duration;
  end
  else if AInterpolator is TQuaternion3DInterpolatorDef then
  begin
    Keys := TQuaternion3DInterpolatorDef(AInterpolator).Keys;
    Duration := TQuaternion3DInterpolatorDef(AInterpolator).Duration;
  end
  else
  begin
    Skip(AInterpolator.ClassName);
    Exit;
  end;
  if (Keys = nil) or (Keys.Count = 0) then
    Exit;
  if Duration <= 0 then
    Duration := ADuration;
  SetLength(Times, Keys.Count);
  N := 0;
  Last := 0;

  if AInterpolator is TTransformationInterpolatorDef then
  begin
    SetLength(Moves, Keys.Count * 3);
    SetLength(Turns, Keys.Count * 4);
    SetLength(Sizes, Keys.Count * 3);
    for I := 0 to Keys.Count - 1 do
    begin
      MatrixKey := TInterpolatorKeyDef<TMatrix3D>(Keys[I]);
      if not KeyTime(MatrixKey.Key) then
        Continue;
      Times[N] := Time;
      AddRotation(MatrixKey.Value);
      Moves[N * 3] := Trs.T.X;
      Moves[N * 3 + 1] := Trs.T.Y;
      Moves[N * 3 + 2] := Trs.T.Z;
      Sizes[N * 3] := Trs.S.X;
      Sizes[N * 3 + 1] := Trs.S.Y;
      Sizes[N * 3 + 2] := Trs.S.Z;
      Inc(N);
    end;
    SetLength(Times, N);
    SetLength(Moves, N * 3);
    SetLength(Turns, N * 4);
    SetLength(Sizes, N * 3);
    AddChannel(ANode, 'translation', Times, Moves, 'VEC3', ASamplers, AChannels);
    AddChannel(ANode, 'rotation', Times, Turns, 'VEC4', ASamplers, AChannels);
    AddChannel(ANode, 'scale', Times, Sizes, 'VEC3', ASamplers, AChannels);
  end
  else if AInterpolator is TPoint3DInterpolatorDef then
  begin
    Path := LowerCase(TPoint3DInterpolatorDef(AInterpolator).Path);
    if not ((Path = 'position.point') or (Path = 'position') or
      (Path = 'scale.point') or (Path = 'scale')) then
    begin
      Skip(TPoint3DInterpolatorDef(AInterpolator).Path);
      Exit;
    end;
    SetLength(Moves, Keys.Count * 3);
    for I := 0 to Keys.Count - 1 do
    begin
      PointKey := TInterpolatorKeyDef<TPoint3D>(Keys[I]);
      if not KeyTime(PointKey.Key) then
        Continue;
      Times[N] := Time;
      Point := PointKey.Value;
      // A position is negated with its axes; a scale is not
      if Path.StartsWith('position') then
        Point := Point3D(Point.X * FSign[0], Point.Y * FSign[1], Point.Z * FSign[2]);
      Moves[N * 3] := Point.X;
      Moves[N * 3 + 1] := Point.Y;
      Moves[N * 3 + 2] := Point.Z;
      Inc(N);
    end;
    SetLength(Times, N);
    SetLength(Moves, N * 3);
    if Path.StartsWith('position') then
      AddChannel(ANode, 'translation', Times, Moves, 'VEC3', ASamplers, AChannels)
    else
      AddChannel(ANode, 'scale', Times, Moves, 'VEC3', ASamplers, AChannels);
  end
  else
  begin
    Path := LowerCase(TQuaternion3DInterpolatorDef(AInterpolator).Path);
    if not Path.StartsWith('quaternion') then
    begin
      Skip(TQuaternion3DInterpolatorDef(AInterpolator).Path);
      Exit;
    end;
    SetLength(Turns, Keys.Count * 4);
    for I := 0 to Keys.Count - 1 do
    begin
      TurnKey := TInterpolatorKeyDef<TQuaternion3D>(Keys[I]);
      if not KeyTime(TurnKey.Key) then
        Continue;
      Times[N] := Time;
      // Through FMX's own matrix of the quaternion, so it means what it
      // means to Gorilla
      Rotation := TurnKey.Value;
      AddRotation(Rotation);
      Inc(N);
    end;
    SetLength(Times, N);
    SetLength(Turns, N * 4);
    AddChannel(ANode, 'rotation', Times, Turns, 'VEC4', ASamplers, AChannels);
  end;
end;

// What an interpolator drives, for the log
function InterpolatorKind(const AInterpolator: TCustomDef): string;
begin
  Result := AInterpolator.ClassName;
  if AInterpolator is TTransformationInterpolatorDef then
    Result := Result + ' ' + TTransformationInterpolatorDef(AInterpolator).Path
  else if AInterpolator is TPoint3DInterpolatorDef then
    Result := Result + ' ' + TPoint3DInterpolatorDef(AInterpolator).Path
  else if AInterpolator is TQuaternion3DInterpolatorDef then
    Result := Result + ' ' + TQuaternion3DInterpolatorDef(AInterpolator).Path
  else if AInterpolator is TVector3DInterpolatorDef then
    Result := Result + ' ' + TVector3DInterpolatorDef(AInterpolator).Path;
end;

procedure TGlbBuilder.WriteAnimations;
var
  Animation: TAnimationDef;
  Stage: TAnimationStageDef;
  Interpolator: TCustomDef;
  Samplers, Channels: TJSONArray;
  Anim: TJSONObject;
  Node, Missing, Before, Seen: Integer;
  Skipped, Kinds, Kind: string;
  Tally: TDictionary<string, Integer>;
  Names: TArray<string>;
begin
  if not FOptions.Animations or (FModel.Animations = nil) then
    Exit;
  for Animation in FModel.Animations do
  begin
    Samplers := TJSONArray.Create;
    Channels := TJSONArray.Create;
    Missing := 0;
    Skipped := '';
    Before := FStats.Channels;
    Tally := TDictionary<string, Integer>.Create;
    try
      if Animation.Stages <> nil then
        for Stage in Animation.Stages do
        begin
          if not (Stage.Reference is TTransformDef) or
            not FNodeIndex.TryGetValue(TTransformDef(Stage.Reference), Node) or (Node < 0) then
          begin
            Inc(Missing);
            Continue;
          end;
          if Stage.Interpolators <> nil then
            for Interpolator in Stage.Interpolators do
            begin
              Kind := InterpolatorKind(Interpolator);
              if not Tally.TryGetValue(Kind, Seen) then
                Seen := 0;
              Tally.AddOrSetValue(Kind, Seen + 1);
              AddInterpolatorChannels(Interpolator, Node, Animation.GetDurationInSeconds,
                Samplers, Channels, Skipped);
            end;
        end;
      if Channels.Count = 0 then
      begin
        Log('animation ' + DefName(Animation) + ': nothing it drives could be written; left out');
        Samplers.Free;
        Channels.Free;
      end
      else
      begin
        Anim := TJSONObject.Create;
        if Animation.Id <> '' then
          Anim.AddPair('name', Animation.Id);
        Anim.AddPair('channels', Channels);
        Anim.AddPair('samplers', Samplers);
        FAnimations.AddElement(Anim);
        Inc(FStats.Animations);
        Log(Format('animation %s: %.3f s, %d stages, %d channels',
          [DefName(Animation), Animation.GetDurationInSeconds, Animation.Stages.Count,
           FStats.Channels - Before]));
      end;
      // Which kinds of key it had, so what Gorilla hands over can be seen
      Names := Tally.Keys.ToArray;
      TArray.Sort<string>(Names);
      Kinds := '';
      for Kind in Names do
        Kinds := Kinds + Format(' %s x%d,', [Kind, Tally[Kind]]);
      if Kinds <> '' then
        Log('  keys:' + Kinds.TrimRight([',']));
    except
      Samplers.Free;
      Channels.Free;
      Tally.Free;
      raise;
    end;
    Tally.Free;
    if Missing > 0 then
      Log(Format('  %d stages drive something that is not a node written; left out',
        [Missing]));
    if Skipped <> '' then
      Log('  keys not exported:' + Skipped);
  end;
end;

function TGlbBuilder.WriteAttributes(const ABuffer: TVertexBuffer;
  const AName: string): TJSONObject;
var
  Count, I, J, View, Fixed: Integer;
  Floats: TArray<Single>;
  Colours: TArray<Byte>;
  P: TPoint3D;
  T: TPointF;
  C: TAlphaColorRec;
  Lo, Hi: array[0..2] of Single;
  Len: Single;
  Acc: TJSONObject;
  MinArr, MaxArr: TJSONArray;
begin
  Result := TJSONObject.Create;
  try
    Count := ABuffer.Length;

    // POSITION, with the min and max the spec requires
    SetLength(Floats, Count * 3);
    for J := 0 to 2 do
    begin
      Lo[J] := MaxSingle;
      Hi[J] := -MaxSingle;
    end;
    for I := 0 to Count - 1 do
    begin
      P := ABuffer.Vertices[I];
      Floats[I * 3] := Finite(P.X * FSign[0]);
      Floats[I * 3 + 1] := Finite(P.Y * FSign[1]);
      Floats[I * 3 + 2] := Finite(P.Z * FSign[2]);
      for J := 0 to 2 do
      begin
        Lo[J] := Min(Lo[J], Floats[I * 3 + J]);
        Hi[J] := Max(Hi[J], Floats[I * 3 + J]);
      end;
    end;
    View := AddView(Floats[0], Count * 12, GL_ARRAY_BUFFER);
    Acc := AddAccessor(View, GL_FLOAT, Count, 'VEC3', False);
    MinArr := TJSONArray.Create;
    MaxArr := TJSONArray.Create;
    for J := 0 to 2 do
    begin
      MinArr.Add(Double(Lo[J]));
      MaxArr.Add(Double(Hi[J]));
    end;
    Acc.AddPair('min', MinArr);
    Acc.AddPair('max', MaxArr);
    Result.AddPair('POSITION', JInt(FAccessors.Count - 1));

    // NORMAL, made unit length; a zero normal, which glTF does not allow,
    // becomes +Z
    if TVertexFormat.Normal in ABuffer.Format then
    begin
      Fixed := 0;
      for I := 0 to Count - 1 do
      begin
        P := ABuffer.Normals[I];
        P := Point3D(Finite(P.X * FSign[0]), Finite(P.Y * FSign[1]), Finite(P.Z * FSign[2]));
        Len := Sqrt(P.X * P.X + P.Y * P.Y + P.Z * P.Z);
        if Len < 1E-12 then
        begin
          P := Point3D(0, 0, 1);
          Inc(Fixed);
        end
        else
          P := Point3D(P.X / Len, P.Y / Len, P.Z / Len);
        Floats[I * 3] := P.X;
        Floats[I * 3 + 1] := P.Y;
        Floats[I * 3 + 2] := P.Z;
      end;
      View := AddView(Floats[0], Count * 12, GL_ARRAY_BUFFER);
      AddAccessor(View, GL_FLOAT, Count, 'VEC3', False);
      Result.AddPair('NORMAL', JInt(FAccessors.Count - 1));
      if Fixed > 0 then
        Log(Format('  mesh %s: %d zero normals written as +Z', [AName, Fixed]));
    end
    else
      Log('  mesh ' + AName + ': no normals');

    // TEXCOORD_0
    if TVertexFormat.TexCoord0 in ABuffer.Format then
    begin
      SetLength(Floats, Count * 2);
      for I := 0 to Count - 1 do
      begin
        T := ABuffer.TexCoord0[I];
        Floats[I * 2] := Finite(T.X);
        if FOptions.FlipV then
          Floats[I * 2 + 1] := Finite(1 - T.Y)
        else
          Floats[I * 2 + 1] := Finite(T.Y);
      end;
      View := AddView(Floats[0], Count * 8, GL_ARRAY_BUFFER);
      AddAccessor(View, GL_FLOAT, Count, 'VEC2', False);
      Result.AddPair('TEXCOORD_0', JInt(FAccessors.Count - 1));
    end;

    // COLOR_0, as normalised unsigned bytes
    if FOptions.VertexColors and (TVertexFormat.Color0 in ABuffer.Format) then
    begin
      SetLength(Colours, Count * 4);
      for I := 0 to Count - 1 do
      begin
        C := TAlphaColorRec(ABuffer.Color0[I]);
        Colours[I * 4] := C.R;
        Colours[I * 4 + 1] := C.G;
        Colours[I * 4 + 2] := C.B;
        Colours[I * 4 + 3] := C.A;
      end;
      View := AddView(Colours[0], Count * 4, GL_ARRAY_BUFFER);
      AddAccessor(View, GL_UNSIGNED_BYTE, Count, 'VEC4', True);
      Result.AddPair('COLOR_0', JInt(FAccessors.Count - 1));
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TGlbBuilder.AddPrimitive(const AIndices: TIndexBuffer;
  const AMaterial: TMaterialRefDef; const AVertexCount: Integer;
  const AAttributes: TJSONObject; const APrimitives: TJSONArray;
  const AName: string): Boolean;
var
  Count, I, Highest, View, Material: Integer;
  Shorts: TArray<Word>;
  Longs: TArray<Cardinal>;
  Prim: TJSONObject;
  Value: Integer;
begin
  Result := False;
  Count := IndexCount(AIndices, AVertexCount);
  if Count = 0 then
  begin
    Log('  mesh ' + AName + ': a primitive with no triangles, left out');
    Exit;
  end;
  Prim := TJSONObject.Create;
  try
    Prim.AddPair('attributes', AAttributes.Clone as TJSONObject);
    if (AIndices <> nil) and (AIndices.Length > 0) then
    begin
      if AIndices.Length mod 3 <> 0 then
        Log(Format('  mesh %s: %d indices, not a whole number of triangles; the last %d left out',
          [AName, AIndices.Length, AIndices.Length mod 3]));
      Highest := 0;
      for I := 0 to Count - 1 do
      begin
        Value := AIndices.Indices[I];
        if (Value < 0) or (Value >= AVertexCount) then
        begin
          Log(Format('  mesh %s: index %d of %d is %d, outside its %d vertices; primitive left out',
            [AName, I, Count, Value, AVertexCount]));
          Prim.Free;
          Exit;
        end;
        if Value > Highest then
          Highest := Value;
      end;
      // 65535 is the restart value for 16-bit indices, so it may not be used
      if Highest < 65535 then
      begin
        SetLength(Shorts, Count);
        for I := 0 to Count - 1 do
          Shorts[I] := AIndices.Indices[I];
        if FReverse then
          for I := 0 to (Count div 3) - 1 do
          begin
            Value := Shorts[I * 3 + 1];
            Shorts[I * 3 + 1] := Shorts[I * 3 + 2];
            Shorts[I * 3 + 2] := Value;
          end;
        View := AddView(Shorts[0], Count * 2, GL_ELEMENT_ARRAY_BUFFER);
        AddAccessor(View, GL_UNSIGNED_SHORT, Count, 'SCALAR', False);
      end
      else
      begin
        SetLength(Longs, Count);
        for I := 0 to Count - 1 do
          Longs[I] := AIndices.Indices[I];
        if FReverse then
          for I := 0 to (Count div 3) - 1 do
          begin
            Value := Longs[I * 3 + 1];
            Longs[I * 3 + 1] := Longs[I * 3 + 2];
            Longs[I * 3 + 2] := Value;
          end;
        View := AddView(Longs[0], Count * 4, GL_ELEMENT_ARRAY_BUFFER);
        AddAccessor(View, GL_UNSIGNED_INT, Count, 'SCALAR', False);
      end;
      Prim.AddPair('indices', JInt(FAccessors.Count - 1));
    end
    else
    begin
      Log('  mesh ' + AName + ': no indices, drawn as a plain triangle list');
      if FReverse then
        Log('  mesh ' + AName + ': winding not reversed, as it has no indices');
    end;
    Material := MaterialFor(AMaterial);
    if Material >= 0 then
      Prim.AddPair('material', JInt(Material));
  except
    Prim.Free;
    raise;
  end;
  APrimitives.AddElement(Prim);
  Inc(FStats.Primitives);
  Inc(FStats.Triangles, Count div 3);
  Result := True;
end;

function TGlbBuilder.AddMesh(const AMesh: TCustomMeshDef): Integer;
var
  Buffer: TVertexBuffer;
  Name: string;
  Attributes, Mesh: TJSONObject;
  Prims: TJSONArray;
  Child: TTransformDef;
  Groups: Integer;
  Skin: TSkinDef;
begin
  Result := -1;
  Buffer := AMesh.VertexSource;
  if (Buffer = nil) or (Buffer.Length = 0) then
    Exit;
  Name := DefName(AMesh);
  Attributes := WriteAttributes(Buffer, Name);
  try
    if FMeshSkin.TryGetValue(AMesh, Skin) then
      WriteSkinAttributes(AMesh, Skin, Attributes);
    Prims := TJSONArray.Create;
    try
      Groups := 0;
      if UsesVertexGroups(AMesh) then
      begin
        for Child in AMesh.Children do
          if Child is TVertexGroupDef then
          begin
            Inc(Groups);
            AddPrimitive(TVertexGroupDef(Child).IndexSource, TVertexGroupDef(Child).Material,
              Buffer.Length, Attributes, Prims, Name + '/' + DefName(Child));
          end;
      end
      else
        AddPrimitive(AMesh.IndexSource, AMesh.Material, Buffer.Length, Attributes, Prims, Name);
      if Prims.Count = 0 then
      begin
        Log('  mesh ' + Name + ': nothing to draw, left out');
        Prims.Free;
        Exit;
      end;
      Mesh := TJSONObject.Create;
      if AMesh.Id <> '' then
        Mesh.AddPair('name', AMesh.Id);
      Mesh.AddPair('primitives', Prims);
    except
      Prims.Free;
      raise;
    end;
  finally
    Attributes.Free;
  end;
  FMeshes.AddElement(Mesh);
  Inc(FStats.Meshes);
  Inc(FStats.Vertices, Buffer.Length);
  if Groups > 0 then
    Log(Format('mesh %s: %d vertices, %d vertex groups, faces %s', [Name, Buffer.Length, Groups,
      FaceName(AMesh.FaceOrientation)]))
  else
    Log(Format('mesh %s: %d vertices, faces %s', [Name, Buffer.Length,
      FaceName(AMesh.FaceOrientation)]));
  Result := FMeshes.Count - 1;
end;

function TGlbBuilder.ResolveMaterial(const ARef: TMaterialRefDef): TMaterialDef;
begin
  Result := nil;
  if ARef = nil then
    Exit;
  Result := ARef.Reference;
  // Some loaders set only the reference's id; look it up in the model's table
  if (Result = nil) and (ARef.Id <> '') and (FModel.Materials <> nil) then
    FModel.Materials.TryGetValue(ARef.Id, Result);
end;

function TGlbBuilder.TextureFor(const ATexture: TTextureDef): TTextureInfo;
var
  Bitmap: TBitmap;
begin
  // TryGetValue clears Result when it finds nothing, so it comes first
  if FTextureIndex.TryGetValue(ATexture, Result) then
    Exit;
  Result.Index := -1;
  Result.HasAlpha := False;
  try
    // A copy, flipped as Gorilla draws it
    Bitmap := ATexture.GetAssetBitmapInstance(True);
  except
    on E: Exception do
    begin
      Log('  texture ' + DefName(ATexture) + ': no bitmap (' + E.Message + ')');
      FTextureIndex.Add(ATexture, Result);
      Exit;
    end;
  end;
  if Bitmap = nil then
  begin
    Log('  texture ' + DefName(ATexture) + ': no bitmap');
    FTextureIndex.Add(ATexture, Result);
    Exit;
  end;
  try
    if Bitmap.IsEmpty then
    begin
      Log('  texture ' + DefName(ATexture) + ': empty bitmap');
      FTextureIndex.Add(ATexture, Result);
      Exit;
    end;
    Result := AddBitmapTexture(Bitmap, ATexture.Id,
      IfThen(ATexture.Flipping <> [], ', flipped by Gorilla', ''));
  finally
    Bitmap.Free;
  end;
  FTextureIndex.Add(ATexture, Result);
end;

function BitmapPng(const ABitmap: TBitmap): TBytes;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    // FMX saves a bitmap to a stream as PNG
    ABitmap.SaveToStream(Stream);
    SetLength(Result, Stream.Size);
    if Stream.Size > 0 then
      Move(Stream.Memory^, Result[0], Stream.Size);
  finally
    Stream.Free;
  end;
end;

function SameBytes(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and (Length(A) > 0) and CompareMem(@A[0], @B[0], Length(A));
end;

function TGlbBuilder.AddBitmapTexture(const ABitmap: TBitmap;
  const AName, ANote: string): TTextureInfo;
var
  Image, Texture: TJSONObject;
  View, Source, I: Integer;
  Png: TBytes;
  Shared: Boolean;
begin
  Result.HasAlpha := BitmapHasAlpha(ABitmap);
  Png := BitmapPng(ABitmap);
  begin
    // The same picture under another texture (a material using one atlas as
    // both colour and emissive map) shares the image already written
    Source := -1;
    for I := 0 to FImageBytes.Count - 1 do
      if SameBytes(FImageBytes[I], Png) then
      begin
        Source := I;
        Break;
      end;
    Shared := Source >= 0;
    if not Shared then
    begin
      View := AddView(Png[0], Length(Png), 0);
      Image := TJSONObject.Create;
      if AName <> '' then
        Image.AddPair('name', AName);
      Image.AddPair('bufferView', JInt(View));
      Image.AddPair('mimeType', 'image/png');
      FImages.AddElement(Image);
      FImageBytes.Add(Png);
      Inc(FStats.Images);
      Source := FImages.Count - 1;
    end;
    Texture := TJSONObject.Create;
    Texture.AddPair('sampler', JInt(0));
    Texture.AddPair('source', JInt(Source));
    FTextures.AddElement(Texture);
    Result.Index := FTextures.Count - 1;
    Log(Format('  texture %s: %d x %d%s%s%s', [IfThen(AName <> '', AName, '(unnamed)'),
      ABitmap.Width, ABitmap.Height, IfThen(Result.HasAlpha, ', has transparency', ''), ANote,
      IfThen(Shared, Format(', same picture as image %d', [Source]), '')]));
  end;
end;

function TGlbBuilder.MetallicRoughnessFor(const AMaterial: TMaterialDef): Integer;
var
  Rough, Metal: TTextureDef;
  RoughBmp, MetalBmp, Combined: TBitmap;
  RoughData, MetalData, CombinedData: TBitmapData;
  X, Y: Integer;
  RoughPixel, MetalPixel: TAlphaColorRec;
  OutPixel: TAlphaColorRec;
begin
  Result := -1;
  Rough := AMaterial.GetTexture(TColorChannelDef.Roughness);
  Metal := AMaterial.GetTexture(TColorChannelDef.Metalness);
  if (Rough = nil) and (Metal = nil) then
    Exit;
  // glTF wants one picture: roughness in green, metalness in blue. A glTF
  // source's map comes back as both channels with the same picture
  if Metal = nil then
    Exit(TextureFor(Rough).Index);
  if Rough = nil then
    Exit(TextureFor(Metal).Index);
  RoughBmp := nil;
  MetalBmp := nil;
  try
    try
      RoughBmp := Rough.GetAssetBitmapInstance(True);
      MetalBmp := Metal.GetAssetBitmapInstance(True);
    except
      on E: Exception do
      begin
        Log('  metallic-roughness: no bitmap (' + E.Message + ')');
        Exit;
      end;
    end;
    if (RoughBmp = nil) or (MetalBmp = nil) or RoughBmp.IsEmpty or MetalBmp.IsEmpty then
      Exit;
    if SameBytes(BitmapPng(RoughBmp), BitmapPng(MetalBmp)) then
      Exit(TextureFor(Rough).Index);
    if (RoughBmp.Width <> MetalBmp.Width) or (RoughBmp.Height <> MetalBmp.Height) then
    begin
      Log('  metallic-roughness: the two maps differ in size; the roughness map is used alone');
      Exit(TextureFor(Rough).Index);
    end;
    // Two pictures: green from the roughness map, blue from the metalness map
    Combined := TBitmap.Create(RoughBmp.Width, RoughBmp.Height);
    try
      if RoughBmp.Map(TMapAccess.Read, RoughData) then
      try
        if MetalBmp.Map(TMapAccess.Read, MetalData) then
        try
          if Combined.Map(TMapAccess.Write, CombinedData) then
          try
            for Y := 0 to RoughBmp.Height - 1 do
              for X := 0 to RoughBmp.Width - 1 do
              begin
                RoughPixel := TAlphaColorRec(RoughData.GetPixel(X, Y));
                MetalPixel := TAlphaColorRec(MetalData.GetPixel(X, Y));
                OutPixel.A := 255;
                OutPixel.R := 255;
                OutPixel.G := RoughPixel.G;
                OutPixel.B := MetalPixel.B;
                CombinedData.SetPixel(X, Y, OutPixel.Color);
              end;
          finally
            Combined.Unmap(CombinedData);
          end;
        finally
          MetalBmp.Unmap(MetalData);
        end;
      finally
        RoughBmp.Unmap(RoughData);
      end;
      Result := AddBitmapTexture(Combined, 'metallicRoughness',
        ', packed from the roughness and metalness maps').Index;
    finally
      Combined.Free;
    end;
  finally
    RoughBmp.Free;
    MetalBmp.Free;
  end;
end;

procedure TGlbBuilder.AddTextureRef(const AParent: TJSONObject; const AName: string;
  const AMaterial: TMaterialDef; const AChannel: TColorChannelDef; out AInfo: TTextureInfo);
var
  Texture: TTextureDef;
  Ref: TJSONObject;
begin
  AInfo.Index := -1;
  AInfo.HasAlpha := False;
  if not FOptions.Textures then
    Exit;
  Texture := AMaterial.GetTexture(AChannel);
  if Texture = nil then
    Exit;
  AInfo := TextureFor(Texture);
  if AInfo.Index < 0 then
    Exit;
  Ref := TJSONObject.Create;
  Ref.AddPair('index', JInt(AInfo.Index));
  AParent.AddPair(AName, Ref);
end;

function TGlbBuilder.MaterialFor(const ARef: TMaterialRefDef): Integer;
var
  M: TMaterialDef;
  Mat, Pbr: TJSONObject;
  Colour: TJSONArray;
  Alpha, Roughness, Metallic: Single;
  IsPbr, HasEmissive: Boolean;
  BaseTex, NormalTex, EmissiveTex, OcclusionTex: TTextureInfo;
  Base: TAlphaColorF;
  WhiteBase: Boolean;
  Texture: TTextureDef;
  Skipped: string;
  MetalRough: Integer;
  Ref: TJSONObject;
begin
  Result := -1;
  M := ResolveMaterial(ARef);
  if M = nil then
    Exit;
  if FMaterialIndex.TryGetValue(M, Result) then
    Exit;

  Mat := TJSONObject.Create;
  try
    if M.Id <> '' then
      Mat.AddPair('name', M.Id);

    Alpha := Clamp01(M.Diffuse.A);
    if M.UseOpacity then
      Alpha := Clamp01(Alpha * M.Opacity);

    IsPbr := (M.Kind = mkPBR) or (M.ShadingModel = smPBR);
    if IsPbr then
    begin
      Metallic := Clamp01(M.Metallic);
      Roughness := Clamp01(M.Roughness);
    end
    else
    begin
      // A rough match for a Phong highlight: the sharper the highlight,
      // the smoother the surface. 2 / (n + 2) is the Beckmann alpha for a
      // Phong power n, and glTF's roughness is the square root of alpha.
      // With no highlight at all the surface is fully rough.
      Metallic := 0;
      if M.UseSpecular and (M.SpecPow > 0) and
        (Max(M.Specular.R, Max(M.Specular.G, M.Specular.B)) > 0) then
        Roughness := EnsureRange(Sqrt(Sqrt(2 / (M.SpecPow + 2))), 0.04, 1)
      else
        Roughness := 1;
    end;

    Pbr := TJSONObject.Create;
    Mat.AddPair('pbrMetallicRoughness', Pbr);
    // TMaterialDef starts with a diffuse of 0.75 grey, and a loader that
    // finds no colour leaves it so: a glTF material with only a texture
    // came back as 0.75 (mashed_potatos.glb). With a texture to show, that
    // default is written as white, glTF's own default, so the texture is not
    // darkened in other viewers.
    Base := M.Diffuse;
    WhiteBase := FOptions.Textures and IsDefaultDiffuse(Base) and
      (M.GetTexture(TColorChannelDef.Diffuse) <> nil);
    if WhiteBase then
    begin
      Base.R := 1;
      Base.G := 1;
      Base.B := 1;
    end;
    Colour := TJSONArray.Create;
    Colour.Add(Double(Clamp01(Base.R)));
    Colour.Add(Double(Clamp01(Base.G)));
    Colour.Add(Double(Clamp01(Base.B)));
    Colour.Add(Double(Alpha));
    Pbr.AddPair('baseColorFactor', Colour);
    Pbr.AddPair('metallicFactor', JNum(Metallic));
    Pbr.AddPair('roughnessFactor', JNum(Roughness));
    AddTextureRef(Pbr, 'baseColorTexture', M, TColorChannelDef.Diffuse, BaseTex);

    AddTextureRef(Mat, 'normalTexture', M, TColorChannelDef.Normal, NormalTex);
    AddTextureRef(Mat, 'occlusionTexture', M, TColorChannelDef.AO, OcclusionTex);
    AddTextureRef(Mat, 'emissiveTexture', M, TColorChannelDef.Emissive, EmissiveTex);
    if FOptions.Textures then
    begin
      MetalRough := MetallicRoughnessFor(M);
      if MetalRough >= 0 then
      begin
        Ref := TJSONObject.Create;
        Ref.AddPair('index', JInt(MetalRough));
        Pbr.AddPair('metallicRoughnessTexture', Ref);
      end;
    end;

    HasEmissive := (M.Emissive.R > 0) or (M.Emissive.G > 0) or (M.Emissive.B > 0);
    if HasEmissive or (EmissiveTex.Index >= 0) then
    begin
      Colour := TJSONArray.Create;
      if HasEmissive then
      begin
        Colour.Add(Double(Clamp01(M.Emissive.R)));
        Colour.Add(Double(Clamp01(M.Emissive.G)));
        Colour.Add(Double(Clamp01(M.Emissive.B)));
      end
      else
      begin
        // An emissive texture is multiplied by the factor, black by default
        Colour.Add(Double(1));
        Colour.Add(Double(1));
        Colour.Add(Double(1));
      end;
      Mat.AddPair('emissiveFactor', Colour);
    end;

    if M.UseAlphaCutoff then
    begin
      Mat.AddPair('alphaMode', 'MASK');
      Mat.AddPair('alphaCutoff', JNum(Clamp01(M.AlphaCutoff)));
    end
    else if (Alpha < 1) or BaseTex.HasAlpha then
      Mat.AddPair('alphaMode', 'BLEND');

    if M.DoubleSided then
      Mat.AddPair('doubleSided', TJSONBool.Create(True));

    // Say which textures had nowhere to go
    Skipped := '';
    if M.Textures <> nil then
      for Texture in M.Textures do
        if not (Texture.Channel in [TColorChannelDef.Diffuse, TColorChannelDef.Normal,
          TColorChannelDef.AO, TColorChannelDef.Emissive, TColorChannelDef.Metalness,
          TColorChannelDef.Roughness]) then
          Skipped := Skipped + ' ' + ChannelName(Texture.Channel);
  except
    Mat.Free;
    raise;
  end;

  FMaterials.AddElement(Mat);
  Inc(FStats.Materials);
  Result := FMaterials.Count - 1;
  FMaterialIndex.Add(M, Result);
  Log(Format('material %s: %s, colour %.3f %.3f %.3f alpha %.3f, metallic %.3f roughness %.3f%s',
    [DefName(M), KindName(M.Kind), M.Diffuse.R, M.Diffuse.G, M.Diffuse.B, Alpha, Metallic,
     Roughness, IfThen(M.DoubleSided, ', double-sided', '')]));
  if not IsPbr then
    Log(Format('  from specular %.3f %.3f %.3f, power %.3f%s', [M.Specular.R, M.Specular.G,
      M.Specular.B, M.SpecPow, IfThen(M.UseSpecular, '', ', specular off')]));
  if WhiteBase then
    Log('  diffuse is Gorilla''s default 0.75 grey; written as white under the texture');
  if (M.Textures <> nil) and (M.Textures.Count > 0) and not FOptions.Textures then
    Log(Format('  %d textures left out (Textures is off)', [M.Textures.Count]));
  if Skipped <> '' then
    Log('  textures not exported:' + Skipped);
  if (M.Materials <> nil) and (M.Materials.Count > 0) then
    Log(Format('  %d sub-materials (layered) not exported', [M.Materials.Count]));
end;

function TGlbBuilder.AddScaleNode(const AChild: Integer; const AScale: Single): Integer;
var
  Node: TJSONObject;
  Scale, Kids: TJSONArray;
begin
  // A parent for the model, so its own matrix and the vertices are left as
  // they are
  Node := TJSONObject.Create;
  Node.AddPair('name', 'unit_scale');
  Scale := TJSONArray.Create;
  Scale.Add(Double(AScale));
  Scale.Add(Double(AScale));
  Scale.Add(Double(AScale));
  Node.AddPair('scale', Scale);
  Kids := TJSONArray.Create;
  Kids.Add(AChild);
  Node.AddPair('children', Kids);
  FNodes.AddElement(Node);
  Inc(FStats.Nodes);
  Result := FNodes.Count - 1;
  Log(Format('Scaled by the unit scale, %g, so the GLB is in metres', [AScale]));
end;

procedure TGlbBuilder.TakeArray(const ARoot: TJSONObject; const AName: string;
  var AArray: TJSONArray);
begin
  // glTF does not allow empty arrays; an empty one stays with the builder
  if AArray.Count = 0 then
    Exit;
  ARoot.AddPair(AName, AArray);
  AArray := nil;
end;

function TGlbBuilder.Build: TBytes;
var
  Root, Asset, Scene, Buffer, Sampler: TJSONObject;
  Scenes, Roots, Buffers, Samplers: TJSONArray;
  RootNode: Integer;
  Json: TBytes;
  JsonLen, BinLen, Total: Cardinal;
  Output: TMemoryStream;
  Pad: Byte;
  Value: Cardinal;
begin
  FindSkinsAndAnimated;
  RootNode := AddNode(FModel, TMatrix3D.Identity);
  if FStats.Primitives = 0 then
    raise Exception.Create('The model holds no mesh data that could be exported.');
  AddArmatures(RootNode);
  WriteSkins;
  WriteAnimations;
  if FOptions.ApplyUnitScale and (FModel.UnitScale > 0) and (FModel.UnitScale <> 1) then
    RootNode := AddScaleNode(RootNode, FModel.UnitScale);

  Root := TJSONObject.Create;
  try
    Asset := TJSONObject.Create;
    Asset.AddPair('version', '2.0');
    Asset.AddPair('generator', GENERATOR);
    Root.AddPair('asset', Asset);
    Root.AddPair('scene', JInt(0));
    Scene := TJSONObject.Create;
    Roots := TJSONArray.Create;
    Roots.Add(RootNode);
    Scene.AddPair('nodes', Roots);
    Scenes := TJSONArray.Create;
    Scenes.AddElement(Scene);
    Root.AddPair('scenes', Scenes);
    TakeArray(Root, 'nodes', FNodes);
    TakeArray(Root, 'meshes', FMeshes);
    TakeArray(Root, 'skins', FSkins);
    TakeArray(Root, 'animations', FAnimations);
    TakeArray(Root, 'materials', FMaterials);
    TakeArray(Root, 'textures', FTextures);
    TakeArray(Root, 'images', FImages);
    if FStats.Images > 0 then
    begin
      Sampler := TJSONObject.Create;
      Sampler.AddPair('magFilter', JInt(GL_LINEAR));
      Sampler.AddPair('minFilter', JInt(GL_LINEAR_MIPMAP_LINEAR));
      Samplers := TJSONArray.Create;
      Samplers.AddElement(Sampler);
      Root.AddPair('samplers', Samplers);
    end;
    TakeArray(Root, 'accessors', FAccessors);
    TakeArray(Root, 'bufferViews', FViews);
    Buffer := TJSONObject.Create;
    Buffer.AddPair('byteLength', JInt(FBin.Size));
    Buffers := TJSONArray.Create;
    Buffers.AddElement(Buffer);
    Root.AddPair('buffers', Buffers);
    Json := TEncoding.UTF8.GetBytes(Root.ToJSON);
  finally
    Root.Free;
  end;

  // Both chunks are padded to 4 bytes: JSON with spaces, BIN with zeros
  JsonLen := Length(Json);
  while JsonLen mod 4 <> 0 do
  begin
    SetLength(Json, JsonLen + 1);
    Json[JsonLen] := Ord(' ');
    Inc(JsonLen);
  end;
  BinLen := FBin.Size;
  Pad := 0;
  FBin.Position := FBin.Size;
  while BinLen mod 4 <> 0 do
  begin
    FBin.WriteBuffer(Pad, 1);
    Inc(BinLen);
  end;
  Total := 12 + 8 + JsonLen + 8 + BinLen;

  Output := TMemoryStream.Create;
  try
    Value := GLB_MAGIC;
    Output.WriteBuffer(Value, 4);
    Value := GLB_VERSION;
    Output.WriteBuffer(Value, 4);
    Output.WriteBuffer(Total, 4);
    Output.WriteBuffer(JsonLen, 4);
    Value := GLB_CHUNK_JSON;
    Output.WriteBuffer(Value, 4);
    Output.WriteBuffer(Json[0], JsonLen);
    Output.WriteBuffer(BinLen, 4);
    Value := GLB_CHUNK_BIN;
    Output.WriteBuffer(Value, 4);
    Output.WriteBuffer(FBin.Memory^, BinLen);
    SetLength(Result, Output.Size);
    Move(Output.Memory^, Result[0], Output.Size);
  finally
    Output.Free;
  end;
  FStats.Bytes := Length(Result);
end;

{ Public routines }

function BuildGlb(const AModel: TModelDef; const AOptions: TGltfExportOptions;
  const ALog: TStrings; out AStats: TGltfExportStats): TBytes;
var
  Builder: TGlbBuilder;
begin
  if AModel = nil then
    raise Exception.Create('There is no model to export.');
  Builder := TGlbBuilder.Create(AModel, AOptions, ALog);
  try
    Result := Builder.Build;
    AStats := Builder.Stats;
  finally
    Builder.Free;
  end;
end;

procedure ExportGlb(const AModel: TModelDef; const AFileName: string;
  const AOptions: TGltfExportOptions; const ALog: TStrings; out AStats: TGltfExportStats);
var
  Bytes: TBytes;
  Doc: TglTFDocument;
  RawName, Line: string;
begin
  Bytes := BuildGlb(AModel, AOptions, ALog, AStats);
  RawName := ChangeFileExt(AFileName, '.raw.glb');
  if AOptions.WriteRaw then
  begin
    TFile.WriteAllBytes(RawName, Bytes);
    if ALog <> nil then
      ALog.Add('Raw GLB written to ' + RawName);
  end;
  Doc := TglTFDocument.Create;
  try
    try
      Doc.LoadFromGLBBytes(Bytes);
    except
      on E: Exception do
      begin
        if not AOptions.WriteRaw then
          TFile.WriteAllBytes(RawName, Bytes);
        if ALog <> nil then
          ALog.Add('GLTFLib refused the GLB (' + E.Message + '); it was written to ' + RawName);
        raise;
      end;
    end;
    if ALog <> nil then
      for Line in Doc.Warnings do
        ALog.Add('GLTFLib: ' + Line);
    Doc.SaveToFile(AFileName);
    if ALog <> nil then
      for Line in Doc.SaveWarnings do
        ALog.Add('GLTFLib save: ' + Line);
  finally
    Doc.Free;
  end;
end;

procedure CountDef(const ADef: TTransformDef; var ACounts: TGltfModelCounts);
var
  Mesh: TCustomMeshDef;
  Child: TTransformDef;
  Vertices: Integer;
begin
  if (ADef is TCustomMeshDef) and not (ADef is TVertexGroupDef) then
  begin
    Mesh := TCustomMeshDef(ADef);
    if (Mesh.VertexSource <> nil) and (Mesh.VertexSource.Length > 0) then
    begin
      Vertices := Mesh.VertexSource.Length;
      Inc(ACounts.Meshes);
      Inc(ACounts.Vertices, Vertices);
      if UsesVertexGroups(Mesh) then
      begin
        for Child in Mesh.Children do
          if Child is TVertexGroupDef then
            Inc(ACounts.Triangles, IndexCount(TVertexGroupDef(Child).IndexSource, Vertices) div 3);
      end
      else
        Inc(ACounts.Triangles, IndexCount(Mesh.IndexSource, Vertices) div 3);
    end;
  end;
  if ADef.Children <> nil then
    for Child in ADef.Children do
      if not (Child is TVertexGroupDef) then
        CountDef(Child, ACounts);
end;

function CountModel(const AModel: TModelDef): TGltfModelCounts;
begin
  Result.Meshes := 0;
  Result.Vertices := 0;
  Result.Triangles := 0;
  Result.Materials := 0;
  Result.Animations := 0;
  Result.Skins := 0;
  if AModel = nil then
    Exit;
  CountDef(AModel, Result);
  if AModel.Materials <> nil then
    Result.Materials := AModel.Materials.Count;
  if AModel.Animations <> nil then
    Result.Animations := AModel.Animations.Count;
  if AModel.Controllers <> nil then
    for var Controller in AModel.Controllers do
      if Controller.Skin <> nil then
        Inc(Result.Skins);
end;

function DescribeAnimations(const AModel: TModelDef): string;
var
  Animation: TAnimationDef;
  Stages: Integer;
begin
  Result := '';
  if (AModel = nil) or (AModel.Animations = nil) then
    Exit;
  for Animation in AModel.Animations do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Stages := 0;
    if Animation.Stages <> nil then
      Stages := Animation.Stages.Count;
    Result := Result + Format('%s %.2f s %d stages', [DefName(Animation),
      Animation.GetDurationInSeconds, Stages]);
  end;
end;

procedure CountClasses(const ADef: TTransformDef; const ACounts: TDictionary<string, Integer>);
var
  Child: TTransformDef;
  N: Integer;
begin
  if not ACounts.TryGetValue(ADef.ClassName, N) then
    N := 0;
  ACounts.AddOrSetValue(ADef.ClassName, N + 1);
  if ADef.Children <> nil then
    for Child in ADef.Children do
      CountClasses(Child, ACounts);
end;

function DescribeModel(const AModel: TModelDef): string;
var
  Counts: TDictionary<string, Integer>;
  Names: TArray<string>;
  Name: string;
begin
  Result := '';
  if AModel = nil then
    Exit;
  Counts := TDictionary<string, Integer>.Create;
  try
    CountClasses(AModel, Counts);
    Names := Counts.Keys.ToArray;
    TArray.Sort<string>(Names);
    for Name in Names do
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + Name + ' ' + IntToStr(Counts[Name]);
    end;
  finally
    Counts.Free;
  end;
end;

end.
