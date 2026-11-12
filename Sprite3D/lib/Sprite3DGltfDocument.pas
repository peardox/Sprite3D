//** @abstract(The model open in Sprite3D as a GLTFLib document, for the glTF tools to work on,
//** and saving the result as GLB.)
//**
//** A .glb or .gltf model is loaded straight from its file by GLTFLib, so nothing Gorilla3D
//** does not keep (extensions, STEP keys, sampler wrap modes) is lost. Any other format,
//** FBX, OBJ, USD, Collada, STL or PLY, is first written as GLB from the definitions
//** Gorilla3D loaded (Sprite3DGltfExport), then loaded from those bytes.
//**
//** SaveDocumentAsGlb writes a document as GLB. The document itself is never changed by a
//** save, as GLTFLib's saves never change it.
//**
//** Uses Gorilla.DefTypes for the definitions, Sprite3DGltfExport and GLTFLib. Knows nothing
//** of the application.
unit Sprite3DGltfDocument;

{
  The model open in Sprite3D as a GLTFLib document, for the glTF tools to
  work on, and saving the result as GLB. A .glb or .gltf model is loaded
  straight from its file; any other format is written as GLB from Gorilla3D's
  definitions first. Knows nothing of the application.
}

interface

uses
  System.SysUtils, System.Classes,
  Gorilla.DefTypes,
  Sprite3DGltfExport,
  glTF.Document;

//** @abstract(Whether a file is glTF, judged by its extension: .glb or .gltf, in any case.)
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True for .glb and .gltf.)
function IsGltfFile(const AFileName: string): Boolean;

//** @abstract(Loads the open model as a GLTFLib document.)
//**
//** A .glb or .gltf file is loaded as it is, and AOptions is not used. Any other file is
//** written as GLB from AModel, with AOptions, and loaded from those bytes.
//**
//** @param(AFileName The file the model was loaded from.)
//**
//** @param(AModel The model's definitions, as TGorillaModel.Def holds them; only needed when
//** the file is not glTF.)
//**
//** @param(AOptions How a model that is not glTF is written.)
//**
//** @param(ALog Gets a line saying which way it was loaded, the exporter's lines and
//** GLTFLib's warnings; may be nil.)
//**
//** @returns(The document; the caller frees it.)
//**
//** @raises(Exception The file or the definitions cannot be turned into a document.)
function LoadModelDocument(const AFileName: string; const AModel: TModelDef;
  const AOptions: TGltfExportOptions; const ALog: TStrings): TglTFDocument;

//** @abstract(Saves a document as GLB, images inside it.)
//**
//** @param(ADocument The document; it is not changed.)
//**
//** @param(AFileName The output, normally ending .glb.)
//**
//** @param(ALog Gets GLTFLib's save warnings; may be nil.)
//**
//** @raises(Exception GLTFLib's errors and file errors.)
procedure SaveDocumentAsGlb(const ADocument: TglTFDocument; const AFileName: string;
  const ALog: TStrings);

implementation

uses
  System.IOUtils;

function IsGltfFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := ExtractFileExt(AFileName);
  Result := SameText(Ext, '.glb') or SameText(Ext, '.gltf');
end;

procedure AddLines(const ALog: TStrings; const APrefix: string; const ALines: TStrings);
var
  Line: string;
begin
  if (ALog = nil) or (ALines = nil) then
    Exit;
  for Line in ALines do
    ALog.Add(APrefix + Line);
end;

function LoadModelDocument(const AFileName: string; const AModel: TModelDef;
  const AOptions: TGltfExportOptions; const ALog: TStrings): TglTFDocument;
var
  Bytes: TBytes;
  Stats: TGltfExportStats;
begin
  Result := TglTFDocument.Create;
  try
    if IsGltfFile(AFileName) then
    begin
      // Straight from the file: everything in it survives, not just what
      // Gorilla3D kept
      Result.LoadFromFile(AFileName);
      if ALog <> nil then
        ALog.Add('Loaded ' + ExtractFileName(AFileName) + ' as it is (glTF)');
    end
    else
    begin
      if AModel = nil then
        raise Exception.Create('Gorilla3D kept no definitions for this model.');
      if ALog <> nil then
        ALog.Add('Converting ' + ExtractFileName(AFileName) +
          ' to glTF from what Gorilla3D loaded');
      Bytes := BuildGlb(AModel, AOptions, ALog, Stats);
      // Images and buffers the converted model names are looked for beside
      // the source file
      Result.BaseDirectory := ExtractFilePath(AFileName);
      Result.LoadFromGLBBytes(Bytes);
    end;
    AddLines(ALog, 'GLTFLib: ', Result.Warnings);
  except
    Result.Free;
    raise;
  end;
end;

procedure SaveDocumentAsGlb(const ADocument: TglTFDocument; const AFileName: string;
  const ALog: TStrings);
var
  Options: TglTFSaveOptions;
begin
  // A GLB holds its images and its first buffer; the rest are as the
  // document has them
  Options := TglTFSaveOptions.Default;
  Options.ImageSaveMode := ismByFormat;
  ADocument.SaveToFile(TPath.ChangeExtension(AFileName, '.glb'), Options);
  AddLines(ALog, 'GLTFLib save: ', ADocument.SaveWarnings);
end;

end.
