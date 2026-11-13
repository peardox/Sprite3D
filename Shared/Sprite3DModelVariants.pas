//** @abstract(A glTF model's material variants (the KHR_materials_variants extension): their
//** names, and the copy of the model to load to show one.)
//**
//** A model with variants holds several looks for the same meshes: the file names them in its
//** root's @code(extensions.KHR_materials_variants.variants), and each primitive that changes
//** says, in its own @code(extensions.KHR_materials_variants.mappings), which material it
//** takes for which variants. A primitive with no mapping for the variant chosen keeps its
//** own material, and so does every primitive when none is chosen: the model as made, its
//** base, which a reader that does not know the extension shows.
//**
//** The model loader does not choose variants, so PrepareModelVariant makes a copy of the
//** model in which each primitive's own material is the one its mapping gives for the variant
//** chosen; that copy is loaded as any model is. It goes in the cache's @code(models) folder,
//** where Sprite3DModelTextures puts its copies, named after the model's key and the
//** variant. The loader looks for the files a glTF names in the glTF's own folder only, so a
//** buffer or image the model keeps in a file of its own is copied there too, named after the
//** SHA-256 of its content, unless the model loaded is itself a copy in that folder already.
//** The model kit's own files are never written.
//**
//** ModelVariantNames reads the names; GltfVariantNamesOf, ReadGltfJson and GlbBytes are the
//** pieces, for a tool that writes variants (Sprite3D's glTF, Add Variants).
//**
//** Pure file and JSON work, no Gorilla3D or FireMonkey: any platform, any one thread at a time.
unit Sprite3DModelVariants;

{
  A glTF model's material variants (KHR_materials_variants): their names,
  and a copy of the model to load to show one, in which each primitive's own
  material is the one its mapping gives for that variant. The copy goes in
  the cache's models folder, named after the model's key and the variant,
  with any buffer or image the model keeps in a file copied beside it, named
  after the SHA-256 of its content, as the loader looks in the glTF's own
  folder only. The model kit's own files are never written. No variant
  chosen: the model as made, its base. Pure file and JSON work.
}

interface

uses
  System.SysUtils, System.JSON;

const
  //** @abstract(The extension's name, as a glTF's @code(extensionsUsed) lists it.)
  VARIANTS_EXTENSION = 'KHR_materials_variants';
  //** @abstract(The variant that is none: the model as made, its base.)
  BASE_VARIANT = -1;

//** @abstract(The names of the variants a model file has, in the file's order; the index of
//** a name is the variant's.)
//**
//** Only a glTF, @code(.gltf) or @code(.glb), can have them. A variant with no name is
//** called @code(Variant N), N counting from 1.
//**
//** @param(AModelFile The model file.)
//**
//** @returns(The names; empty if it has none, is not glTF, or cannot be read. Never an
//** exception.)
function ModelVariantNames(const AModelFile: String): TArray<String>;

//** @abstract(The file to load to show variant AVariant of a model: a copy in which each
//** primitive's own material is the one its mapping gives for that variant.)
//**
//** @param(ALoadFile The file the model is loaded from: the model itself, or the copy
//** Sprite3DModelTextures made of it.)
//**
//** @param(ACacheFolder The cache; the copy, and every file it names, go in its
//** @code(models) folder.)
//**
//** @param(AKey The model's key, which names the copy with the variant.)
//**
//** @param(AVariant The variant's index in ModelVariantNames; BASE_VARIANT, or one the model
//** does not have, for the model as made.)
//**
//** @returns(The copy; ALoadFile itself for the base, or for a model that is not glTF.)
//**
//** @raises(Exception If the model cannot be read as glTF, or the copy, or a file it names,
//** cannot be written.)
function PrepareModelVariant(const ALoadFile, ACacheFolder, AKey: String;
  const AVariant: Integer): String;

//** @abstract(The variant names a glTF's JSON gives, as ModelVariantNames does.)
//**
//** @param(AJson The glTF's root object.)
//**
//** @returns(The names; empty if it has none.)
function GltfVariantNamesOf(const AJson: TJSONObject): TArray<String>;

//** @abstract(Reads a glTF's JSON, and a GLB's binary chunk, from a file's bytes.)
//**
//** @param(ABytes The whole file.)
//**
//** @param(ABin On return, a GLB's BIN chunk; empty for a @code(.gltf), or a GLB without one.)
//**
//** @param(AIsGlb On return, True if the bytes are a GLB.)
//**
//** @returns(The root object; the caller frees it.)
//**
//** @raises(Exception If the bytes are neither a GLB nor glTF JSON.)
function ReadGltfJson(const ABytes: TBytes; out ABin: TBytes;
  out AIsGlb: Boolean): TJSONObject;

//** @abstract(A GLB file's bytes, from its JSON and its binary chunk.)
//**
//** Each chunk is padded to a multiple of 4 bytes, the JSON with spaces and the binary with
//** zeros, as the GLB format asks.
//**
//** @param(AJson The root object; written compact, as UTF-8.)
//**
//** @param(ABin The BIN chunk; empty for none.)
//**
//** @returns(The file's bytes.)
function GlbBytes(const AJson: TJSONObject; const ABin: TBytes): TBytes;

implementation

uses
  // System.Generics.Collections lets TJSONArray's inline GetValue expand
  System.Classes, System.IOUtils, System.Hash, System.NetEncoding,
  System.Generics.Collections, OSPaths, JsonText;

const
  //** @abstract(The cache's folder of models' copies, as Sprite3DModelTextures names it.)
  MODEL_FOLDER_NAME = 'models';
  //** @abstract(A GLB's magic number: "glTF" in ASCII, little-endian.)
  GLB_MAGIC = $46546C67;
  //** @abstract(The JSON chunk's type: "JSON" in ASCII, little-endian.)
  CHUNK_JSON = $4E4F534A;
  //** @abstract(The binary chunk's type: "BIN" and a zero, little-endian.)
  CHUNK_BIN = $004E4942;

function GltfVariantNamesOf(const AJson: TJSONObject): TArray<String>;
var
  Variants: TJSONArray;
  Name: String;
begin
  Result := nil;
  if (AJson = nil) or not AJson.TryGetValue<TJSONArray>('extensions.' +
    VARIANTS_EXTENSION + '.variants', Variants) then
    Exit;
  for var I := 0 to Variants.Count - 1 do
  begin
    Name := String.Empty;
    if Variants.Items[I] is TJSONObject then
      TJSONObject(Variants.Items[I]).TryGetValue<String>('name', Name);
    Name := Name.Trim;
    if Name = String.Empty then
      Name := Format('Variant %d', [I + 1]);
    Result := Result + [Name];
  end;
end;

//** @abstract(A little-endian 32-bit number in ABytes at AOffset.)
//**
//** @param(ABytes The bytes.)
//**
//** @param(AOffset Where it starts.)
//**
//** @returns(The number.)
function ReadUInt32(const ABytes: TBytes; const AOffset: Integer): Cardinal;
begin
  Move(ABytes[AOffset], Result, SizeOf(Result));
end;

//** @abstract(Writes a little-endian 32-bit number into ABytes at AOffset.)
//**
//** @param(ABytes The bytes.)
//**
//** @param(AOffset Where it goes.)
//**
//** @param(AValue The number.)
procedure WriteUInt32(var ABytes: TBytes; const AOffset: Integer; const AValue: Cardinal);
begin
  Move(AValue, ABytes[AOffset], SizeOf(AValue));
end;

function ReadGltfJson(const ABytes: TBytes; out ABin: TBytes;
  out AIsGlb: Boolean): TJSONObject;
var
  Offset, Length_: Integer;
  Kind: Cardinal;
  Text: String;
  Value: TJSONValue;
begin
  ABin := nil;
  Text := String.Empty;
  AIsGlb := (Length(ABytes) >= 12) and (ReadUInt32(ABytes, 0) = GLB_MAGIC);
  if AIsGlb then
  begin
    // The header, then chunks: the JSON first, the BIN after it, if any
    Offset := 12;
    while Offset + 8 <= Length(ABytes) do
    begin
      Length_ := Integer(ReadUInt32(ABytes, Offset));
      Kind := ReadUInt32(ABytes, Offset + 4);
      if (Length_ < 0) or (Offset + 8 + Length_ > Length(ABytes)) then
        raise Exception.Create('The GLB''s chunks are not whole');
      if Kind = CHUNK_JSON then
        Text := TEncoding.UTF8.GetString(ABytes, Offset + 8, Length_)
      else if (Kind = CHUNK_BIN) and (ABin = nil) then
        ABin := Copy(ABytes, Offset + 8, Length_);
      Inc(Offset, 8 + Length_);
    end;
  end
  else
    Text := TEncoding.UTF8.GetString(ABytes);
  // A byte order mark, which some writers put before the text
  if Text.StartsWith(#$FEFF) then
    Text := Text.Substring(1);
  Value := TJSONObject.ParseJSONValue(Text);
  if not (Value is TJSONObject) then
  begin
    Value.Free;
    raise Exception.Create('Not glTF: its JSON is not an object');
  end;
  Result := TJSONObject(Value);
end;

function GlbBytes(const AJson: TJSONObject; const ABin: TBytes): TBytes;
var
  Json: TBytes;
  JsonLength, BinLength, Total, Offset: Integer;
begin
  Json := TEncoding.UTF8.GetBytes(AJson.ToJSON);
  JsonLength := (Length(Json) + 3) and not 3;
  BinLength := (Length(ABin) + 3) and not 3;
  Total := 12 + 8 + JsonLength;
  if Length(ABin) > 0 then
    Inc(Total, 8 + BinLength);
  SetLength(Result, Total);
  FillChar(Result[0], Total, 0);
  WriteUInt32(Result, 0, GLB_MAGIC);
  WriteUInt32(Result, 4, 2);
  WriteUInt32(Result, 8, Total);
  WriteUInt32(Result, 12, JsonLength);
  WriteUInt32(Result, 16, CHUNK_JSON);
  if Length(Json) > 0 then
    Move(Json[0], Result[20], Length(Json));
  // The JSON's padding is spaces
  for var I := 20 + Length(Json) to 20 + JsonLength - 1 do
    Result[I] := $20;
  if Length(ABin) > 0 then
  begin
    Offset := 20 + JsonLength;
    WriteUInt32(Result, Offset, BinLength);
    WriteUInt32(Result, Offset + 4, CHUNK_BIN);
    Move(ABin[0], Result[Offset + 8], Length(ABin));
  end;
end;

//** @abstract(Enough of a glTF file to read its JSON: a GLB's header and JSON chunk only,
//** not its binary chunk, which can be many megabytes; a @code(.gltf) whole.)
//**
//** @param(AFile The file.)
//**
//** @returns(Bytes ReadGltfJson takes.)
//**
//** @raises(Exception If the file cannot be read.)
function GltfJsonBytes(const AFile: String): TBytes;
var
  Stream: TFileStream;
  Header: TBytes;
  JsonLength: Cardinal;
begin
  Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Header, 20);
    if (Stream.Size < 20) or (Stream.Read(Header[0], 20) <> 20) or
      (ReadUInt32(Header, 0) <> GLB_MAGIC) then
    begin
      // Not a GLB: the whole file is the JSON
      Stream.Position := 0;
      SetLength(Result, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(Result[0], Stream.Size);
      Exit;
    end;
    // The header and the JSON chunk's own header, then its data
    JsonLength := ReadUInt32(Header, 12);
    if 20 + Int64(JsonLength) > Stream.Size then
      raise Exception.Create('The GLB''s JSON chunk is not whole');
    SetLength(Result, 20 + JsonLength);
    Move(Header[0], Result[0], 20);
    if JsonLength > 0 then
      Stream.ReadBuffer(Result[20], JsonLength);
  finally
    Stream.Free;
  end;
end;

function ModelVariantNames(const AModelFile: String): TArray<String>;
var
  Ext: String;
  Json: TJSONObject;
  Bin: TBytes;
  IsGlb: Boolean;
begin
  Result := nil;
  Ext := LowerCase(ExtractFileExt(AModelFile));
  if (Ext <> '.gltf') and (Ext <> '.glb') then
    Exit;
  try
    Json := ReadGltfJson(GltfJsonBytes(OSFriendlyPath(AModelFile)), Bin, IsGlb);
    try
      Result := GltfVariantNamesOf(Json);
    finally
      Json.Free;
    end;
  except
    Result := nil;
  end;
end;

//** @abstract(Gives each primitive the material its mapping gives for variant AVariant;
//** one without a mapping for it keeps its own.)
//**
//** @param(AJson The glTF's root object, changed.)
//**
//** @param(AVariant The variant's index.)
//**
//** @returns(How many primitives changed material.)
function ApplyVariant(const AJson: TJSONObject; const AVariant: Integer): Integer;
var
  Meshes, Primitives, Mappings, Variants: TJSONArray;
  Primitive, Mapping: TJSONObject;
  Material, Index: Integer;
begin
  Result := 0;
  if not AJson.TryGetValue<TJSONArray>('meshes', Meshes) then
    Exit;
  for var M := 0 to Meshes.Count - 1 do
  begin
    if not (Meshes.Items[M] is TJSONObject) or
      not TJSONObject(Meshes.Items[M]).TryGetValue<TJSONArray>('primitives', Primitives) then
      Continue;
    for var P := 0 to Primitives.Count - 1 do
    begin
      if not (Primitives.Items[P] is TJSONObject) then
        Continue;
      Primitive := TJSONObject(Primitives.Items[P]);
      if not Primitive.TryGetValue<TJSONArray>('extensions.' + VARIANTS_EXTENSION +
        '.mappings', Mappings) then
        Continue;
      for var Q := 0 to Mappings.Count - 1 do
      begin
        if not (Mappings.Items[Q] is TJSONObject) then
          Continue;
        Mapping := TJSONObject(Mappings.Items[Q]);
        if not Mapping.TryGetValue<Integer>('material', Material) or
          not Mapping.TryGetValue<TJSONArray>('variants', Variants) then
          Continue;
        for var V := 0 to Variants.Count - 1 do
          if Variants.Items[V].TryGetValue<Integer>(Index) and (Index = AVariant) then
          begin
            Primitive.RemovePair('material').Free;
            Primitive.AddPair('material', TJSONNumber.Create(Material));
            Inc(Result);
          end;
      end;
    end;
  end;
end;

//** @abstract(Puts every buffer and image the copy names by file beside it in AFolder, named
//** after the SHA-256 of its content, and names that file instead.)
//**
//** A data URI, or an image inside a buffer, needs nothing. A file that is not there is left
//** as named, for the loader to report.
//**
//** @param(AJson The copy's root object, changed.)
//**
//** @param(ASourceFolder The folder the model's uris are relative to.)
//**
//** @param(AFolder The copy's folder.)
procedure CopyNamedFiles(const AJson: TJSONObject; const ASourceFolder, AFolder: String);
var
  List: TJSONArray;
  Item: TJSONObject;
  Uri, Source, Target, Name: String;
begin
  for var Kind in TArray<String>.Create('buffers', 'images') do
  begin
    if not AJson.TryGetValue<TJSONArray>(Kind, List) then
      Continue;
    for var I := 0 to List.Count - 1 do
    begin
      if not (List.Items[I] is TJSONObject) then
        Continue;
      Item := TJSONObject(List.Items[I]);
      if not Item.TryGetValue<String>('uri', Uri) or (Uri = String.Empty) or
        Uri.StartsWith('data:', True) then
        Continue;
      Source := OSFriendlyPath(TPath.Combine(ASourceFolder, TNetEncoding.URL.URLDecode(Uri)));
      if not TFile.Exists(Source) then
        Continue;
      Name := LowerCase(THashSHA2.GetHashStringFromFile(Source)) +
        LowerCase(ExtractFileExt(Source));
      Target := TPath.Combine(AFolder, Name);
      // Once only: named after its content, so one there is the same
      if not TFile.Exists(Target) then
        TFile.Copy(Source, Target, False);
      Item.RemovePair('uri').Free;
      Item.AddPair('uri', Name);
    end;
  end;
end;

function PrepareModelVariant(const ALoadFile, ACacheFolder, AKey: String;
  const AVariant: Integer): String;
var
  LoadFile, Folder, Ext: String;
  Json: TJSONObject;
  Bin: TBytes;
  IsGlb: Boolean;
begin
  LoadFile := OSFriendlyPath(ALoadFile);
  Result := LoadFile;
  Ext := LowerCase(ExtractFileExt(LoadFile));
  if (AVariant < 0) or ((Ext <> '.gltf') and (Ext <> '.glb')) then
    Exit;
  Json := ReadGltfJson(TFile.ReadAllBytes(LoadFile), Bin, IsGlb);
  try
    if AVariant >= Length(GltfVariantNamesOf(Json)) then
      Exit;   // not one it has: the base
    ApplyVariant(Json, AVariant);
    Folder := OSFriendlyPath(TPath.Combine(ACacheFolder, MODEL_FOLDER_NAME));
    ForceDirectories(Folder);
    // A copy Sprite3DModelTextures made is in this folder already, with
    // every file it names; the model itself needs its files brought here
    if not SameFileName(ExcludeTrailingPathDelimiter(ExtractFilePath(LoadFile)),
      ExcludeTrailingPathDelimiter(Folder)) then
      CopyNamedFiles(Json, ExtractFilePath(LoadFile), Folder);
    Result := TPath.Combine(Folder, Format('%s.variant%d%s', [LowerCase(AKey), AVariant,
      Ext]));
    // Written each time: cheap, and never out of step with the model
    if IsGlb then
      TFile.WriteAllBytes(Result, GlbBytes(Json, Bin))
    else
      TFile.WriteAllBytes(Result, JsonToBytes(Json));
  finally
    Json.Free;
  end;
end;

end.
