//** @abstract(Adds material variants (KHR_materials_variants) to a glTF document: other
//** textures for the same model, each set named, to be swapped in when the model is shown.)
//**
//** VariantTextureSlots lists every texture the model's materials use, by material and by use
//** (base colour, normal map and so on), with the file each came from where that is known, as
//** a guide to the texture each variant needs in its place. A variant (TGltfNewVariant) gives
//** a file for any of them; one it leaves empty keeps the model's own. For each variant and
//** each material it changes, SaveWithVariants adds an image for each file (one image per
//** file, however many variants use it), a texture for it with the sampler of the texture it
//** replaces, and a copy of the material using those textures, named after the material and
//** the variant. It then saves the document, and writes the extension into the JSON saved: the
//** variants' names, after any the model has already, in the root, and in each primitive whose
//** material a variant changes, a mapping from that variant to its copy of the material. The
//** model's own materials are the base, with no variant name, which a reader that does not
//** know the extension shows.
//**
//** A variant's texture may be in any format the image library reads (ReadableImageFile):
//** glTF takes PNG and JPEG only, so a TGA, a layered image file (PSD) or the like is made a
//** PNG, once, in the program's cache (ImageForLoader), as a model's own textures are for
//** loading.
//**
//** Saved as GLB, every image is inside it. Saved as glTF (AEmbed False), each image is a file
//** of its own: a variant's PNG or JPEG, and a model's texture that is a file of its own
//** outside the program's cache, are left where they are and named by their path from the
//** glTF (a texture shared by a whole kit, say, is not copied for each model); a PNG made from
//** another format is written beside it under the texture's own name (sp02.png for
//** sp02.tga), as is a texture in the cache, or one that was inside the model.
//**
//** The document is changed: the images, textures and materials are added to it, and the
//** extension to its @code(extensionsUsed). Uses GLTFLib; knows nothing of the application.
unit Sprite3DGltfVariants;

{
  Adds material variants (KHR_materials_variants) to a glTF document.
  VariantTextureSlots lists the textures the materials use, by use, with the
  file each came from; each variant gives files for any of them. For each
  variant and each material it changes, SaveWithVariants adds the images,
  textures and a copy of the material, saves the document (GLB, or glTF with
  the variants' textures left where they are), then writes the variants'
  names in the root and each primitive's mappings into the JSON saved. The
  model's own materials are the base. Changes the document. Uses GLTFLib;
  knows nothing of the application.
}

interface

uses
  System.SysUtils, System.Classes,
  glTF.Document;

type
  //** @abstract(What a material uses a texture for.)
  TGltfTextureUse = (
    //** @abstract(The colour: pbrMetallicRoughness.baseColorTexture.)
    tuBaseColour,
    //** @abstract(Metal and roughness: pbrMetallicRoughness.metallicRoughnessTexture.)
    tuMetallicRoughness,
    //** @abstract(The normal map: normalTexture.)
    tuNormal,
    //** @abstract(Ambient occlusion: occlusionTexture.)
    tuOcclusion,
    //** @abstract(Glow: emissiveTexture.)
    tuEmissive);

  //** @abstract(One texture a material of the model uses, for which a variant may give
  //** another file.)
  TGltfTextureSlot = record
    //** @abstract(The material's index.)
    Material: Integer;
    //** @abstract(The material's name; @code(Material N) if it has none.)
    MaterialName: String;
    //** @abstract(What the material uses the texture for.)
    Use: TGltfTextureUse;
    //** @abstract(The texture's index.)
    Texture: Integer;
    //** @abstract(The image's index; -1 if the texture names none glTF can show (one an
    //** extension supplies).)
    Image: Integer;
    //** @abstract(The file the image came from, as the model names it, or the file it was
    //** found or made from; empty if it was inside the model with no name.)
    FileName: String;
  end;

  //** @abstract(A variant to add: its name, and a file for each slot, by the index of
  //** VariantTextureSlots; an empty one keeps the model's own texture.)
  TGltfNewVariant = record
    //** @abstract(Its name.)
    Name: String;
    //** @abstract(An image file for each slot, as a full path, or empty: PNG or JPEG, or any
  //** other format the image library reads, made a PNG.)
    Files: TArray<String>;
  end;

  //** @abstract(Gives the file an image of the model came from, for the slots' FileName:
  //** the model's own name for a texture read from the program's copy of it.)
  //**
  //** @param(AImageFile The image's file, as the document resolves its uri; empty if it has
  //** none.)
  //**
  //** @returns(The file to show; AImageFile if nothing better is known.)
  TGltfImageNamer = reference to function(const AImageFile: String): String;

//** @abstract(What a material uses a texture for, in a few words: @code(Base colour),
//** @code(Normal map) and so on.)
//**
//** @param(AUse The use.)
//**
//** @returns(The words.)
function TextureUseText(const AUse: TGltfTextureUse): String;

//** @abstract(Every texture a material a primitive uses has, in material order, then use
//** order.)
//**
//** @param(ADocument The document.)
//**
//** @param(ANamer Gives the file each image came from; may be nil.)
//**
//** @returns(The slots; empty if no material a primitive uses has a texture.)
function VariantTextureSlots(const ADocument: TglTFDocument;
  const ANamer: TGltfImageNamer): TArray<TGltfTextureSlot>;

//** @abstract(The variants the document has already, by name, in order.)
//**
//** @param(ADocument The document.)
//**
//** @returns(The names; empty for none.)
function ExistingVariantNames(const ADocument: TglTFDocument): TArray<String>;

//** @abstract(Adds the variants to the document and saves it, with the extension, as the
//** unit's description says.)
//**
//** @param(ADocument The document; changed.)
//**
//** @param(ASlots VariantTextureSlots of the document.)
//**
//** @param(AVariants The variants to add, after any it has; each with a file for at least
//** one slot.)
//**
//** @param(AFileName The file to save, @code(.glb) or @code(.gltf).)
//**
//** @param(AEmbed True for a GLB with every image inside; False for a glTF, AFileName ending
//** @code(.gltf), with images as files.)
//**
//** @param(ACacheFolder The program's cache, whose files a glTF saved does not name where
//** they are; may be empty.)
//**
//** @param(ALog Gets a line for each variant, and GLTFLib's warnings; may be nil.)
//**
//** @raises(Exception If a file cannot be read, or the model saved, or the result is not as
//** written.)
procedure SaveWithVariants(const ADocument: TglTFDocument;
  const ASlots: TArray<TGltfTextureSlot>; const AVariants: TArray<TGltfNewVariant>;
  const AFileName: String; const AEmbed: Boolean; const ACacheFolder: String;
  const ALog: TStrings);

implementation

uses
  System.IOUtils, System.JSON, System.Generics.Collections,
  glTF.Classes, glTF.Edit,
  Sprite3DModelVariants, Sprite3DModelTextures;

const
  //** @abstract(Where each use's texture index is in a material's JSON, by use: an object
  //** path, then @code(index).)
  USE_PATHS: array[TGltfTextureUse] of String = (
    'pbrMetallicRoughness.baseColorTexture',
    'pbrMetallicRoughness.metallicRoughnessTexture',
    'normalTexture',
    'occlusionTexture',
    'emissiveTexture');

function TextureUseText(const AUse: TGltfTextureUse): String;
const
  TEXTS: array[TGltfTextureUse] of String = ('Base colour', 'Metal and roughness',
    'Normal map', 'Ambient occlusion', 'Glow (emissive)');
begin
  Result := TEXTS[AUse];
end;

//** @abstract(The JSON object at a dotted path in AJson, made if it is not there.)
//**
//** @param(AJson The object to start from.)
//**
//** @param(APath Names separated by dots.)
//**
//** @returns(The object; owned by AJson.)
function ObjectAt(const AJson: TJSONObject; const APath: String): TJSONObject;
var
  Next: TJSONValue;
begin
  Result := AJson;
  for var Name in APath.Split(['.']) do
  begin
    Next := Result.GetValue(Name);
    if not (Next is TJSONObject) then
    begin
      Result.RemovePair(Name).Free;
      Next := TJSONObject.Create;
      Result.AddPair(Name, Next);
    end;
    Result := TJSONObject(Next);
  end;
end;

function VariantTextureSlots(const ADocument: TglTFDocument;
  const ANamer: TGltfImageNamer): TArray<TGltfTextureSlot>;
var
  Root: TglTF;
  Used: TArray<Boolean>;
  Json: TJSONObject;
  Slot: TGltfTextureSlot;
  Index: Integer;
  Image: TglTFImage;
  FileName: String;
begin
  Result := nil;
  Root := ADocument.Root;
  SetLength(Used, Root.Materials.Count);
  for var Mesh in Root.Meshes do
    for var Primitive in Mesh.Primitives do
      if (Primitive.Material >= 0) and (Primitive.Material < Length(Used)) then
        Used[Primitive.Material] := True;
  for var M := 0 to High(Used) do
  begin
    if not Used[M] then
      Continue;
    Json := Root.Materials[M].SaveToJSON;
    try
      for var Use := Low(TGltfTextureUse) to High(TGltfTextureUse) do
      begin
        if not Json.TryGetValue<Integer>(USE_PATHS[Use] + '.index', Index) or
          (Index < 0) or (Index >= Root.Textures.Count) then
          Continue;
        Slot.Material := M;
        Slot.MaterialName := Root.Materials[M].Name;
        if Slot.MaterialName = String.Empty then
          Slot.MaterialName := Format('Material %d', [M]);
        Slot.Use := Use;
        Slot.Texture := Index;
        Slot.Image := Root.Textures[Index].Source;
        if (Slot.Image < 0) or (Slot.Image >= Root.Images.Count) then
          Slot.Image := -1;
        FileName := String.Empty;
        if Slot.Image >= 0 then
        begin
          Image := Root.Images[Slot.Image];
          if (Image.Uri <> String.Empty) and not Image.IsDataUri then
            FileName := ADocument.ResolveUri(Image.Uri)
          else if Image.SourceFile <> String.Empty then
            FileName := Image.SourceFile;
          if Assigned(ANamer) then
            FileName := ANamer(FileName);
          // Inside the model: its name, if it has one, is the best guide
          if (FileName = String.Empty) and (Image.Name <> String.Empty) then
            FileName := Image.Name;
        end;
        Slot.FileName := FileName;
        Result := Result + [Slot];
      end;
    finally
      Json.Free;
    end;
  end;
end;

function ExistingVariantNames(const ADocument: TglTFDocument): TArray<String>;
var
  Json: TJSONObject;
begin
  Json := ADocument.Root.SaveToJSON;
  try
    Result := GltfVariantNamesOf(Json);
  finally
    Json.Free;
  end;
end;

//** @abstract(A path made a glTF uri: forward slashes, and every byte outside the
//** unreserved set, a space say, percent-encoded.)
//**
//** @param(APath A relative path.)
//**
//** @returns(The uri.)
function UriOfPath(const APath: String): String;
const
  HEX = '0123456789ABCDEF';
var
  Bytes: TBytes;
  C: Byte;
begin
  Result := String.Empty;
  Bytes := TEncoding.UTF8.GetBytes(APath.Replace('\', '/'));
  for C in Bytes do
    if CharInSet(Char(C), ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~', '/']) then
      Result := Result + Char(C)
    else
      Result := Result + '%' + HEX[(C shr 4) + 1] + HEX[(C and $F) + 1];
end;

//** @abstract(Whether AFile is in AFolder, or a folder below it.)
//**
//** @param(AFile A full path.)
//**
//** @param(AFolder A folder; empty is never.)
//**
//** @returns(True if it is.)
function IsInFolder(const AFile, AFolder: String): Boolean;
begin
  Result := (AFolder <> String.Empty) and
    ExpandFileName(AFile).StartsWith(IncludeTrailingPathDelimiter(ExpandFileName(AFolder)),
    True);
end;

procedure SaveWithVariants(const ADocument: TglTFDocument;
  const ASlots: TArray<TGltfTextureSlot>; const AVariants: TArray<TGltfNewVariant>;
  const AFileName: String; const AEmbed: Boolean; const ACacheFolder: String;
  const ALog: TStrings);
var
  Root: TglTF;
  First: Integer;
  ImageOf: TDictionary<String, Integer>;
  // For each variant, each material it changes and the copy's index
  Copies: TArray<TDictionary<Integer, Integer>>;
  CopyNames: TDictionary<Integer, String>;
  Json, Saved, Mapping, Holder, TextureInfo: TJSONObject;
  NewTexture: TglTFTexture;
  NewMaterial: TglTFMaterial;
  ImageIndex, TextureIndex, Copy_: Integer;
  OutFolder: String;
  Options: TglTFSaveOptions;
  Stream: TMemoryStream;
  Bytes, Bin: TBytes;
  IsGlb: Boolean;
  Variants, Mappings, Numbers, Materials, Meshes, Primitives: TJSONArray;
  Primitive: TJSONObject;
  Material: Integer;
  Changed: Boolean;

  //** @abstract(The image for file AFile, added the first time it is asked for.)
  function ImageFor(const AFile: String): Integer;
  var
    ImageJson: TJSONObject;
    NewImage: TglTFImage;
    Ext, Uri, Png, Reason: String;
    Made: Boolean;
  begin
    if ImageOf.TryGetValue(LowerCase(AFile), Result) then
      Exit;
    // glTF takes PNG and JPEG only: anything else (TGA, PSD...) is made a
    // PNG, once, in the cache, as a model's own textures are for loading
    if not ImageForLoader(AFile, ACacheFolder, Png, Reason) then
      raise Exception.CreateFmt('%s can''t be made a PNG: %s', [AFile, Reason]);
    Made := not SameFileName(Png, AFile);
    if Assigned(ALog) and Made then
      ALog.Add(Format('glTF variants: %s made a PNG', [ExtractFileName(AFile)]));
    Ext := LowerCase(ExtractFileExt(Png));
    ImageJson := TJSONObject.Create;
    try
      if AEmbed then
        Uri := UriOfPath(TPath.GetFileNameWithoutExtension(AFile) + Ext)
      else if Made then
        // Written beside the glTF, under the texture's own name: sp02.png
        // for sp02.tga
        Uri := UriOfPath(TPath.GetFileNameWithoutExtension(AFile) + Ext)
      else
        // Left where it is, named by its path from the glTF
        Uri := UriOfPath(ExtractRelativePath(IncludeTrailingPathDelimiter(OutFolder),
          AFile));
      ImageJson.AddPair('uri', Uri);
      if (Ext = '.jpg') or (Ext = '.jpeg') then
        ImageJson.AddPair('mimeType', 'image/jpeg')
      else
        ImageJson.AddPair('mimeType', 'image/png');
      ImageJson.AddPair('name', TPath.GetFileNameWithoutExtension(AFile));
      NewImage := TglTFImage.Create;
      try
        NewImage.LoadFromJSON(ImageJson, Format('images[%d]', [Root.Images.Count]));
      except
        NewImage.Free;
        raise;
      end;
    finally
      ImageJson.Free;
    end;
    NewImage.Data := TFile.ReadAllBytes(Png);
    NewImage.SourceFile := Png;
    NewImage.Embed := AEmbed;
    // A file left where it is may be shared by a whole kit; one made is
    // written beside the glTF, renamed rather than put over a different one
    NewImage.Shared := not AEmbed and not Made;
    Root.Images.Add(NewImage);
    Result := Root.Images.Count - 1;
    ImageOf.Add(LowerCase(AFile), Result);
  end;

begin
  Root := ADocument.Root;
  OutFolder := ExtractFileDir(ExpandFileName(AFileName));
  First := Length(ExistingVariantNames(ADocument));
  ImageOf := TDictionary<String, Integer>.Create;
  CopyNames := TDictionary<Integer, String>.Create;
  SetLength(Copies, Length(AVariants));
  try
    // The images, textures and materials of each variant
    for var V := 0 to High(AVariants) do
    begin
      Copies[V] := TDictionary<Integer, Integer>.Create;
      for var S := 0 to High(ASlots) do
      begin
        if (S > High(AVariants[V].Files)) or (AVariants[V].Files[S] = String.Empty) then
          Continue;
        Copies[V].AddOrSetValue(ASlots[S].Material, -1);
      end;
      for var M in Copies[V].Keys.ToArray do
      begin
        Json := Root.Materials[M].SaveToJSON;
        try
          for var S := 0 to High(ASlots) do
          begin
            if (ASlots[S].Material <> M) or (S > High(AVariants[V].Files)) or
              (AVariants[V].Files[S] = String.Empty) then
              Continue;
            ImageIndex := ImageFor(AVariants[V].Files[S]);
            // A texture for it, sampled as the one it replaces
            Saved := TJSONObject.Create;
            try
              Saved.AddPair('source', TJSONNumber.Create(ImageIndex));
              if Root.Textures[ASlots[S].Texture].Sampler >= 0 then
                Saved.AddPair('sampler',
                  TJSONNumber.Create(Root.Textures[ASlots[S].Texture].Sampler));
              NewTexture := TglTFTexture.Create;
              try
                NewTexture.LoadFromJSON(Saved, Format('textures[%d]', [Root.Textures.Count]));
              except
                NewTexture.Free;
                raise;
              end;
            finally
              Saved.Free;
            end;
            Root.Textures.Add(NewTexture);
            TextureIndex := Root.Textures.Count - 1;
            TextureInfo := ObjectAt(Json, USE_PATHS[ASlots[S].Use]);
            TextureInfo.RemovePair('index').Free;
            TextureInfo.AddPair('index', TJSONNumber.Create(TextureIndex));
          end;
          // Named after the material and the variant: "spider_mat (Red)"
          for var S in ASlots do
            if S.Material = M then
            begin
              Json.RemovePair('name').Free;
              Json.AddPair('name', S.MaterialName + ' (' + AVariants[V].Name + ')');
              Break;
            end;
          NewMaterial := TglTFMaterial.Create;
          try
            NewMaterial.LoadFromJSON(Json, Format('materials[%d]', [Root.Materials.Count]));
          except
            NewMaterial.Free;
            raise;
          end;
        finally
          Json.Free;
        end;
        Root.Materials.Add(NewMaterial);
        Copy_ := Root.Materials.Count - 1;
        Copies[V][M] := Copy_;
        CopyNames.AddOrSetValue(Copy_, NewMaterial.Name);
      end;
      if Assigned(ALog) then
        ALog.Add(Format('glTF variants: %s changes %d materials', [AVariants[V].Name,
          Copies[V].Count]));
    end;

    // Listed as used before saving, so GLTFLib keeps every material, and
    // the images only a variant uses
    TglTFEdit.AddExtensionUsed(Root, VARIANTS_EXTENSION);
    if not AEmbed then
      // The model's own textures that are files outside the cache stay
      // where they are too; those in the cache, or inside the model, are
      // written beside the glTF
      for var I := 0 to Root.Images.Count - 1 do
      begin
        if ImageOf.ContainsValue(I) then
          Continue;
        if (Root.Images[I].SourceFile <> String.Empty) and
          TFile.Exists(Root.Images[I].SourceFile) and
          not IsInFolder(Root.Images[I].SourceFile, ACacheFolder) then
        begin
          Root.Images[I].Uri := UriOfPath(ExtractRelativePath(
            IncludeTrailingPathDelimiter(OutFolder), Root.Images[I].SourceFile));
          Root.Images[I].Embed := False;
          Root.Images[I].Shared := True;
        end
        else
        begin
          // Written beside it: a PNG made in the cache is named after its
          // content there, so it takes the name of the file it came from,
          // as the slots know it (sp01.png for sp01.tga)
          Root.Images[I].Embed := False;
          if (Root.Images[I].SourceFile <> String.Empty) and
            IsInFolder(Root.Images[I].SourceFile, ACacheFolder) then
            for var Slot in ASlots do
              if (Slot.Image = I) and (Slot.FileName <> String.Empty) then
              begin
                Root.Images[I].Uri := UriOfPath(TPath.GetFileNameWithoutExtension(
                  Slot.FileName) + LowerCase(ExtractFileExt(Root.Images[I].SourceFile)));
                Break;
              end;
        end;
      end;

    Options := TglTFSaveOptions.Default;
    if AEmbed then
    begin
      Stream := TMemoryStream.Create;
      try
        ADocument.SaveToStream(Stream, gffGLB, Options);
        SetLength(Bytes, Stream.Size);
        if Stream.Size > 0 then
          Move(Stream.Memory^, Bytes[0], Stream.Size);
      finally
        Stream.Free;
      end;
    end
    else
    begin
      Options.Buffers := rmExternal;
      Options.ImageSaveMode := ismPerImage;
      Options.PrettyPrint := True;
      ADocument.SaveToFile(AFileName, Options);
      Bytes := TFile.ReadAllBytes(AFileName);
    end;
    if Assigned(ALog) then
      ALog.AddStrings(ADocument.SaveWarnings);

    // The extension, into the JSON saved
    Saved := ReadGltfJson(Bytes, Bin, IsGlb);
    try
      // Each copy must be where it was made: the save renumbers nothing
      // while the extension is listed, which this checks
      if not Saved.TryGetValue<TJSONArray>('materials', Materials) then
        raise Exception.Create('The saved model has no materials');
      for var Pair in CopyNames do
        if (Pair.Key >= Materials.Count) or
          not (Materials.Items[Pair.Key] is TJSONObject) or
          (TJSONObject(Materials.Items[Pair.Key]).GetValue<String>('name', '') <>
          Pair.Value) then
          raise Exception.CreateFmt('The saved model''s material %d is not %s', [Pair.Key,
            Pair.Value]);

      // After any the model has already, so their numbers stay
      Holder := ObjectAt(Saved, 'extensions.' + VARIANTS_EXTENSION);
      if not Holder.TryGetValue<TJSONArray>('variants', Variants) then
      begin
        Holder.RemovePair('variants').Free;
        Variants := TJSONArray.Create;
        Holder.AddPair('variants', Variants);
      end;
      for var V := 0 to High(AVariants) do
        Variants.AddElement(TJSONObject.Create(TJSONPair.Create('name',
          AVariants[V].Name)));

      if not Saved.TryGetValue<TJSONArray>('meshes', Meshes) then
        raise Exception.Create('The saved model has no meshes');
      for var MeshValue in Meshes do
      begin
        if not (MeshValue is TJSONObject) or
          not TJSONObject(MeshValue).TryGetValue<TJSONArray>('primitives', Primitives) then
          Continue;
        for var PrimitiveValue in Primitives do
        begin
          if not (PrimitiveValue is TJSONObject) then
            Continue;
          Primitive := TJSONObject(PrimitiveValue);
          if not Primitive.TryGetValue<Integer>('material', Material) then
            Continue;
          Changed := False;
          Mappings := nil;
          for var V := 0 to High(AVariants) do
          begin
            if not Copies[V].TryGetValue(Material, Copy_) then
              Continue;
            if Mappings = nil then
            begin
              // After any mappings it has already
              Holder := ObjectAt(Primitive, 'extensions.' + VARIANTS_EXTENSION);
              if not Holder.TryGetValue<TJSONArray>('mappings', Mappings) then
              begin
                Holder.RemovePair('mappings').Free;
                Mappings := TJSONArray.Create;
                Holder.AddPair('mappings', Mappings);
              end;
            end;
            Numbers := TJSONArray.Create;
            Numbers.Add(First + V);
            Mapping := TJSONObject.Create;
            Mapping.AddPair('material', TJSONNumber.Create(Copy_));
            Mapping.AddPair('variants', Numbers);
            Mappings.AddElement(Mapping);
            Changed := True;
          end;
          if Changed and Assigned(ALog) then
            ALog.Add(Format('glTF variants: a primitive of material %d mapped', [Material]));
        end;
      end;

      if IsGlb then
        TFile.WriteAllBytes(AFileName, GlbBytes(Saved, Bin))
      else
        // UTF-8 without a byte order mark, which some glTF readers reject
        TFile.WriteAllBytes(AFileName, TEncoding.UTF8.GetBytes(Saved.Format(2)));
    finally
      Saved.Free;
    end;
  finally
    for var D in Copies do
      D.Free;
    CopyNames.Free;
    ImageOf.Free;
  end;
end;

end.
