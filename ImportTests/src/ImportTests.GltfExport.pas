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
//** Skins, animations, morph targets, lights and cameras are not written yet; the nodes of
//** armatures, lights and cameras are written as empty nodes.
//**
//** The coordinates are written as Gorilla holds them. Whether that is right is what
//** ImportTests is for: TGltfExportOptions can negate any axis, reverse the winding and flip
//** V, so the output can be compared with the original until a rule is found.
//**
//** The GLB is put together in memory, then loaded by GLTFLib's TglTFDocument, which checks
//** it, and saved by it. A file GLTFLib refuses is written beside the output as .raw.glb for
//** inspection.
//**
//** Uses Gorilla.DefTypes, FMX for the vertex buffers and bitmaps, and GLTFLib. Knows nothing
//** of the application.
unit ImportTests.GltfExport;

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
    //** @abstract(Returns the defaults: nothing negated or flipped, the winding reversed,
    //** textures on, vertex colours and the raw file off.)
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

implementation

uses
  System.Types, System.UITypes, System.Math, System.Math.Vectors, System.JSON,
  System.TypInfo, System.StrUtils, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults,
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

  GENERATOR = 'Sprite3D ImportTests (Gorilla3D definitions, GLTFLib)';

  // Below this a matrix entry counts as equal to the identity's
  MATRIX_TOLERANCE = 1E-6;

type
  TTextureInfo = record
    Index: Integer;
    HasAlpha: Boolean;
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
    procedure Log(const AText: string);
    function AddView(const AData; const ASize, ATarget: Integer): Integer;
    function AddAccessor(const AView, AComponent, ACount: Integer; const AType: string;
      const ANormalized: Boolean): TJSONObject;
    function NodeMatrix(const AMatrix: TMatrix3D): TJSONArray;
    function AddNode(const ADef: TTransformDef): Integer;
    function AddMesh(const AMesh: TCustomMeshDef): Integer;
    function WriteAttributes(const ABuffer: TVertexBuffer; const AName: string): TJSONObject;
    function AddPrimitive(const AIndices: TIndexBuffer; const AMaterial: TMaterialRefDef;
      const AVertexCount: Integer; const AAttributes: TJSONObject;
      const APrimitives: TJSONArray; const AName: string): Boolean;
    function ResolveMaterial(const ARef: TMaterialRefDef): TMaterialDef;
    function MaterialFor(const ARef: TMaterialRefDef): Integer;
    function TextureFor(const ATexture: TTextureDef): TTextureInfo;
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

function TGlbBuilder.AddNode(const ADef: TTransformDef): Integer;
var
  Node: TJSONObject;
  Matrix, Kids: TJSONArray;
  Child: TTransformDef;
  Mesh: Integer;
begin
  Node := TJSONObject.Create;
  try
    if ADef.Id <> '' then
      Node.AddPair('name', ADef.Id);
    Matrix := NodeMatrix(ADef.Transform);
    if Matrix <> nil then
      Node.AddPair('matrix', Matrix);
    if ADef is TCustomMeshDef then
    begin
      Mesh := AddMesh(TCustomMeshDef(ADef));
      if Mesh >= 0 then
        Node.AddPair('mesh', JInt(Mesh));
    end;
    if ADef is TSkinDef then
      Log('  skin ' + DefName(ADef) + ': written as a plain node; skins are not exported yet');
    Kids := TJSONArray.Create;
    Node.AddPair('children', Kids);
    if ADef.Children <> nil then
      for Child in ADef.Children do
      begin
        // A vertex group is drawn as a primitive of the mesh that owns it
        if Child is TVertexGroupDef then
          Continue;
        Kids.Add(AddNode(Child));
      end;
    if Kids.Count = 0 then
      Node.RemovePair('children').Free;
  except
    Node.Free;
    raise;
  end;
  FNodes.AddElement(Node);
  Inc(FStats.Nodes);
  Result := FNodes.Count - 1;
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
begin
  Result := -1;
  Mesh := nil;
  Buffer := AMesh.VertexSource;
  if (Buffer = nil) or (Buffer.Length = 0) then
    Exit;
  Name := DefName(AMesh);
  Attributes := WriteAttributes(Buffer, Name);
  try
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
  Stream: TMemoryStream;
  Image, Texture: TJSONObject;
  View: Integer;
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
    Result.HasAlpha := BitmapHasAlpha(Bitmap);
    Stream := TMemoryStream.Create;
    try
      // FMX saves a bitmap to a stream as PNG
      Bitmap.SaveToStream(Stream);
      View := AddView(Stream.Memory^, Stream.Size, 0);
    finally
      Stream.Free;
    end;
    Image := TJSONObject.Create;
    if ATexture.Id <> '' then
      Image.AddPair('name', ATexture.Id);
    Image.AddPair('bufferView', JInt(View));
    Image.AddPair('mimeType', 'image/png');
    FImages.AddElement(Image);
    Inc(FStats.Images);
    Texture := TJSONObject.Create;
    Texture.AddPair('sampler', JInt(0));
    Texture.AddPair('source', JInt(FImages.Count - 1));
    FTextures.AddElement(Texture);
    Result.Index := FTextures.Count - 1;
    Log(Format('  texture %s: %d x %d%s%s', [DefName(ATexture), Bitmap.Width, Bitmap.Height,
      IfThen(Result.HasAlpha, ', has transparency', ''),
      IfThen(ATexture.Flipping <> [], ', flipped by Gorilla', '')]));
  finally
    Bitmap.Free;
  end;
  FTextureIndex.Add(ATexture, Result);
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
          TColorChannelDef.AO, TColorChannelDef.Emissive]) then
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
  RootNode := AddNode(FModel);
  if FStats.Primitives = 0 then
    raise Exception.Create('The model holds no mesh data that could be exported.');
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
  if AModel = nil then
    Exit;
  CountDef(AModel, Result);
  if AModel.Materials <> nil then
    Result.Materials := AModel.Materials.Count;
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
