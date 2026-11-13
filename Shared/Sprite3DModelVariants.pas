//** @abstract(A glTF model's material variants (the KHR_materials_variants extension): their
//** names, read from the file without loading it, and the pieces a tool that writes them
//** needs.)
//**
//** A model with variants holds several looks for the same meshes: the file names them in its
//** root's @code(extensions.KHR_materials_variants.variants), and each primitive that changes
//** says, in its own @code(extensions.KHR_materials_variants.mappings), which material it
//** takes for which variants. A primitive with no mapping for the variant chosen keeps its
//** own material, and so does every primitive when none is chosen: the model as made, its
//** base, which a reader that does not know the extension shows.
//**
//** Gorilla3D reads the extension itself and swaps a loaded model's materials
//** (TGorillaModel.MaterialVariants, MaterialVariant, MaterialVariantName), so showing a
//** variant needs nothing here. ModelVariantNames is for knowing a model's variants without
//** loading it (the Library's tiles); for a GLB it reads only the header and the JSON chunk.
//** GltfVariantNamesOf, ReadGltfJson and GlbBytes are the pieces, for a tool that writes
//** variants (Sprite3D's glTF, Add Variants).
//**
//** Pure file and JSON work, no Gorilla3D or FireMonkey: any platform, any one thread at a time.
unit Sprite3DModelVariants;

{
  A glTF model's material variants (KHR_materials_variants): their names,
  read from the file without loading it (only a GLB's JSON chunk), and the
  pieces a tool that writes them needs. Gorilla3D reads the extension itself
  and swaps a loaded model's materials (TGorillaModel.MaterialVariant), so
  showing a variant needs nothing here. Pure file and JSON work.
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
  System.Classes, System.IOUtils, System.Generics.Collections, OSPaths;

const
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

end.
