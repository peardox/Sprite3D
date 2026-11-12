//** @abstract(A cache of model thumbnails and metadata, keyed by a hash of each model's content.)
//**
//** Every model gets a key: a SHA-256 of its file and of every file it names, so identical
//** copies in different folders share one key, and any change to the model, its buffers or
//** its textures gives a new one. TSprite3DAssetHasher works the key out. For a glTF file
//** (@code(.gltf)) the files named are the @code(uri) of each of its @code(buffers) and
//** @code(images) that is not a @code(data:) URI, relative to the model's folder, in the
//** order the file gives them; their names and contents both count. For every other format
//** only the file itself counts.
//**
//** The thumbnails are PNG files in a cache folder, for each key in a folder of its first two
//** digits (AssetKeyFolder: @code(3/f/3fa9....png)). Everything else is in one SQLite
//** database, ASSET_DATABASE_FILE_NAME in the folder that holds the cache folder, the
//** settings folder (AssetDatabaseFile), through FireDAC, with SQLite linked into the program
//** where FireDAC can, Windows and macOS, and the system's elsewhere: each model's metadata, a
//** TSprite3DAssetMeta (its name, group, the file it was first seen as, the files it names, its
//** bounding box in its own units, and how its thumbnail was made; SaveAssetMeta,
//** LoadAssetMeta); the library, the list of collections (LoadAssetLibrary,
//** SaveAssetLibrary); and each collection, its name, the folders its models come from and
//** the formats taken from each, its models with their files, and its palette, the groups with
//** their icons, nesting and models (LoadAssetCollection, SaveAssetCollection). A collection
//** is written in one transaction. ClearAssetCache deletes the thumbnails and the metadata and
//** leaves the library, so the user's arrangement outlives the thumbnails.
//**
//** The JSON files of before the database are moved into it as they are come upon:
//** @code(library.json) and @code(collection-<id>.json) the first time the library is read,
//** then renamed @code(.moved); a model's @code(<key>.json) as its metadata is first read,
//** then deleted. @code(palette.json), the one palette of before the library, is only read
//** (LoadAssetPalette), for the application to make a collection of.
//**
//** The unit knows nothing of the application. TSprite3DAssetHasher only reads files, so it
//** may run on a worker thread, one hasher to a thread; everything that touches the database
//** is for the main thread, which holds one connection to it, freed at finalization.
//**
//** @preformatted(
//** <settings folder>
//** |-- library.db       the library, collections, palettes and models' metadata
//** `-- <cache folder>
//**     `-- 3/f/         AssetKeyFolder: the first two digits of the keys in it
//**         `-- <key>.png    the thumbnail
//** )
unit Sprite3DAssetCache;

{
  A cache of model thumbnails and metadata, keyed by a hash of each model's
  content.

  Every model gets a key: a SHA-256 of its file and of every file it names,
  so identical copies in different folders share one key, and any change to
  the model, its buffers or its textures gives a new one.
  TSprite3DAssetHasher works the key out. For a glTF file (.gltf) the files
  named are the uri of each of its buffers and images that is not a data:
  URI, relative to the model's folder, in the order the file gives them;
  their names and contents both count. For every other format only the file
  itself counts.

  The thumbnails are PNG files in a cache folder, for each key in a folder
  of its first two digits (3/f/ for 3fa9...). Everything else is in one
  SQLite database, library.db in the settings folder, through FireDAC: each
  model's metadata, the library, and each collection with its sources,
  models and palette. ClearAssetCache deletes thumbnails and metadata and
  leaves the library. The JSON files of before the database are moved into
  it as they are come upon. palette.json, of before the library, is only
  read, for the application to make a collection of.

  The unit knows nothing of the application. TSprite3DAssetHasher only reads
  files, so it may run on a worker thread; everything that touches the
  database is for the main thread.

    <settings folder>
    |-- library.db       the library, collections, palettes and metadata
    `-- <cache folder>
        `-- 3/f/         the first two digits of the keys in it
            `-- <key>.png    the thumbnail
}

interface

uses
  System.SysUtils, System.Types, System.Math.Vectors, System.Generics.Collections;

const
  //** @abstract(The @code(format) written in, and looked for in, every metadata file.)
  ASSET_META_FORMAT = 'Sprite3D asset';
  //** @abstract(The metadata files' version: one of another version is not read.)
  ASSET_META_VERSION = 1;
  //** @abstract(The palette's file in the cache folder before the library; see
  //** LoadAssetPalette.)
  ASSET_PALETTE_FILE_NAME = 'palette.json';
  //** @abstract(The format named in the palette's file.)
  ASSET_PALETTE_FORMAT = 'Sprite3D asset palette';
  //** @abstract(The palette file's version.)
  ASSET_PALETTE_VERSION = 1;
  //** @abstract(The library's file in the cache folder: the collections; see
  //** LoadAssetLibrary.)
  ASSET_LIBRARY_FILE_NAME = 'library.json';
  //** @abstract(The format named in the library's file.)
  ASSET_LIBRARY_FORMAT = 'Sprite3D asset library';
  //** @abstract(The library file's version.)
  ASSET_LIBRARY_VERSION = 1;
  //** @abstract(The format named in a collection's file; see LoadAssetCollection.)
  ASSET_COLLECTION_FORMAT = 'Sprite3D asset collection';
  //** @abstract(A collection file's version.)
  ASSET_COLLECTION_VERSION = 1;
  //** @abstract(The database, in the settings folder; see AssetDatabaseFile.)
  ASSET_DATABASE_FILE_NAME = 'library.db';
  //** @abstract(The database's schema version, kept in its @code(user_version).)
  ASSET_DATABASE_VERSION = 3;

type
  //** @abstract(What the cache keeps about one model.)
  TSprite3DAssetMeta = record
    //** @abstract(The model's key: the SHA-256 of its content, as 64 lower-case hex digits.)
    Hash: String;
    //** @abstract(The model's name: its file's name without the extension.)
    Name: String;
    //** @abstract(The group the caller put it in, such as the first word of its name.)
    Group: String;
    //** @abstract(The model's file, as a full path: where it was when its thumbnail was made,
    //** or, once read back, where the caller found it this time.)
    FileName: String;
    //** @abstract(The files the model names, as it names them, relative to its folder.)
    Files: TArray<String>;
    //** @abstract(The low corner of its bounding box, in its own coordinates and units.)
    BoxMin: TPoint3D;
    //** @abstract(The high corner of its bounding box, in its own coordinates and units.)
    BoxMax: TPoint3D;
    //** @abstract(The thumbnail's width in pixels.)
    ThumbWidth: Integer;
    //** @abstract(The thumbnail's height in pixels.)
    ThumbHeight: Integer;
    //** @abstract(How the thumbnail was drawn, such as @code(isometric orthographic).)
    View: String;
    //** @abstract(When the thumbnail was made, as ISO 8601 text.)
    Created: String;
    //** @abstract(Meshes with vertex data, as the caller counted them when it loaded the
    //** model; meaningful only when Kind is set.)
    Meshes: Integer;
    //** @abstract(Their vertices, all together; see Meshes.)
    Vertices: Integer;
    //** @abstract(Animations; see Meshes.)
    Animations: Integer;
    //** @abstract(Skins; see Meshes.)
    Skins: Integer;
    //** @abstract(Joints, over every skin; see Meshes.)
    Joints: Integer;
    //** @abstract(The kind of model the caller made of those counts, by its key, such as
    //** @code(static); empty when they have not been counted.)
    Kind: String;
    //** @abstract(The bounding box's size: BoxMax less BoxMin.)
    //**
    //** @returns(Width, height and depth, in the model's own units.)
    function Size: TPoint3D;
  end;

  //** @abstract(One group of the palette: its name and the keys of its models, in order.)
  TSprite3DPaletteGroup = record
    //** @abstract(The group's name, as the user sees it.)
    Name: String;
    //** @abstract(The keys of its models, in order; a key is in one group at most.)
    Models: TArray<String>;
    //** @abstract(The file name of its icon, without a folder, as the application's icon
    //** library knows it; empty for none chosen.)
    Icon: String;
    //** @abstract(The group it is inside, by name; empty for one at the top. The reader
    //** passes it on as written: whether it names a group, and makes no loop, is the
    //** application's to check.)
    Parent: String;
  end;

  //** @abstract(A model of a collection: its key, and the file it was found as.)
  TSprite3DCollectionModel = record
    //** @abstract(The model's key.)
    Key: String;
    //** @abstract(The model file, as a full path.)
    FileName: String;
  end;

  //** @abstract(Where some of a collection's models come from: a folder, and which model
  //** formats in it.)
  TSprite3DCollectionSource = record
    //** @abstract(The folder; its sub-folders are not looked in.)
    Folder: String;
    //** @abstract(The file extensions taken from it, in lower case with the dot, such as
    //** @code(.gltf); empty for every model format.)
    Formats: TArray<String>;
  end;

  //** @abstract(A collection: a set of models from one or more folders, arranged in groups;
  //** the palette is its groups.)
  TSprite3DAssetCollection = record
    //** @abstract(Its id, which names its file; see AssetCollectionFile.)
    Id: String;
    //** @abstract(Its name, as the user sees it.)
    Name: String;
    //** @abstract(Where its models come from: folders, and the formats taken from each.)
    Sources: TArray<TSprite3DCollectionSource>;
    //** @abstract(Its groups, the palette.)
    Groups: TArray<TSprite3DPaletteGroup>;
    //** @abstract(Its models, as its folders were last scanned.)
    Models: TArray<TSprite3DCollectionModel>;
    //** @abstract(True once its folders have been scanned, so Models is whole.)
    Scanned: Boolean;
    //** @abstract(The id of the artist it is under; see TSprite3DArtist.)
    ArtistId: String;
  end;

  //** @abstract(A collection as the library lists it.)
  TSprite3DLibraryEntry = record
    //** @abstract(The collection's id.)
    Id: String;
    //** @abstract(Its name.)
    Name: String;
    //** @abstract(The id of the artist it is under; empty for none yet.)
    ArtistId: String;
    //** @abstract(How many models it has, as last written by SaveAssetCollection; read by
    //** LoadAssetLibrary, never written by SaveAssetLibrary.)
    Models: Integer;
    //** @abstract(True once its folders have been scanned, as last written by
    //** SaveAssetCollection; read by LoadAssetLibrary, never written by SaveAssetLibrary.)
    Scanned: Boolean;
  end;

  //** @abstract(An artist: whoever made the collections under them; the library's top level.)
  TSprite3DArtist = record
    //** @abstract(Their id: letters, digits and hyphens, as a collection's is.)
    Id: String;
    //** @abstract(Their name, as the user sees it.)
    Name: String;
  end;

  //** @abstract(The library: every collection, and which was open last.)
  TSprite3DAssetLibrary = record
    //** @abstract(The artists, in the order they were added.)
    Artists: TArray<TSprite3DArtist>;
    //** @abstract(The collections, in the order they were added, each under its artist.)
    Collections: TArray<TSprite3DLibraryEntry>;
    //** @abstract(The id of the collection open last; empty for none.)
    Last: String;
    //** @abstract(The folder chosen last in a folder dialog, to start the next in.)
    LastFolder: String;
    //** @abstract(The model format the user prefers when a folder holds the same models in
    //** several, as its extension, such as @code(.gltf); empty for none chosen yet.)
    PreferredFormat: String;
    //** @abstract(The id of the artist shown last; empty for none.)
    LastArtist: String;
  end;

  //** @abstract(Works out models' keys; see the unit's description.)
  //**
  //** A file several models name, such as a texture they share, is hashed once per hasher:
  //** its digest is kept, by full path, for the next model that names it. Use one hasher for
  //** one scan of a folder, on one thread.
  TSprite3DAssetHasher = class
  private
    //** @abstract(The digest of each file named so far, by its full path in upper case.)
    FDigests: TDictionary<String, TBytes>;
    //** @abstract(The SHA-256 of AFileName's content, from FDigests if it is there.)
    //**
    //** @param(AFileName A full path.)
    //**
    //** @returns(The 32-byte digest.)
    function FileDigest(const AFileName: String): TBytes;
  public
    //** @abstract(Creates a hasher with nothing remembered.)
    constructor Create;
    //** @abstract(Frees the hasher and the digests it kept.)
    destructor Destroy; override;
    //** @abstract(The key of the model in AFileName.)
    //**
    //** @param(AFileName The model file.)
    //**
    //** @param(AFiles On return, the files it names, as it names them; empty but for glTF.)
    //**
    //** @param(AError On return, why there is no key; empty if there is one. A file it names
    //** that is missing is not an error: it counts by its name alone, so the key changes when
    //** it appears.)
    //**
    //** @returns(The key, 64 lower-case hex digits; empty if AFileName cannot be read.)
    function HashModel(const AFileName: String; out AFiles: TArray<String>;
      out AError: String): String;
  end;

//** @abstract(The folder in the cache folder ACacheFolder that key AHash's thumbnail goes in.)
//**
//** Two levels, named after the key's first and second hexadecimal digits, so
//** @code(3fa9...) is in @code(3/f): a cache of thousands of models has at most 256 folders,
//** each with a fraction of the files, not one folder of every file.
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash A model's key.)
//**
//** @returns(The folder's full path; it need not exist.)
function AssetKeyFolder(const ACacheFolder, AHash: String): String;

//** @abstract(The thumbnail file of key AHash in the cache folder ACacheFolder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash A model's key.)
//**
//** @returns(The file's full path, @code(<AHash>.png) in AssetKeyFolder; it need not exist.)
function AssetThumbnailFile(const ACacheFolder, AHash: String): String;

//** @abstract(The database that goes with the cache folder ACacheFolder:
//** ASSET_DATABASE_FILE_NAME in the folder that holds it, the settings folder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @returns(The database's full path.)
function AssetDatabaseFile(const ACacheFolder: String): String;

//** @abstract(Writes AMeta to the database, in place of what it had for the key.)
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(AMeta The metadata; its Hash is the key.)
//**
//** @raises(Exception If the database cannot be opened or written.)
procedure SaveAssetMeta(const ACacheFolder: String; const AMeta: TSprite3DAssetMeta);

//** @abstract(Reads the metadata of key AHash from the database.)
//**
//** If the database has none, but there is a metadata file of before it for the key, that is
//** read, written to the database and deleted.
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(AHash The model's key.)
//**
//** @param(AMeta On return, the metadata when True.)
//**
//** @returns(True if there is metadata for AHash; False otherwise, never an exception.)
function LoadAssetMeta(const ACacheFolder, AHash: String;
  out AMeta: TSprite3DAssetMeta): Boolean;

//** @abstract(Deletes every thumbnail from the cache folder, and every model's metadata from
//** the database; the library, its collections and their palettes stay.)
//**
//** Only files named for a key, 64 hexadecimal digits with @code(.png), or @code(.json) or
//** @code(.json.tmp) of before the database, in their key folder (AssetKeyFolder) or at the
//** top, are deleted, and the key folders left empty. A file that cannot be deleted is left;
//** the rest go on.
//**
//** @param(ACacheFolder The cache folder; if it does not exist there are no files to do.)
//**
//** @param(AFailed On return, how many files could not be deleted.)
//**
//** @returns(How many models' metadata were deleted.)
function ClearAssetCache(const ACacheFolder: String; out AFailed: Integer): Integer;

//** @abstract(Deletes the whole library: the database, ASSET_DATABASE_FILE_NAME and its
//** journal files, and the cache folder with everything in it, every thumbnail among it.)
//**
//** The database's connection is closed first. The model files themselves are never touched.
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(AError On return, what could not be deleted, and why; empty if all was.)
//**
//** @returns(True if everything was deleted; never an exception.)
function ClearAssetLibrary(const ACacheFolder: String; out AError: String): Boolean;

//** @abstract(Reads the palette file of before the library, palette.json, from ACacheFolder,
//** so it can be moved into the library as a collection.)
//**
//** A missing, damaged or other file gives an empty palette. A group's @code(icon) is kept
//** only if it is a plain file name, with no folder in it. A group whose name is empty, or
//** the same, ignoring case, as an earlier one's, is left out, as is a key that is not 64
//** hexadecimal digits or that an earlier group has already; keys are in lower case.
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(APalette On return, the groups in order; empty if there is no palette.)
//**
//** @returns(True if the file was there and read; False otherwise, never an exception.)
function LoadAssetPalette(const ACacheFolder: String;
  out APalette: TArray<TSprite3DPaletteGroup>): Boolean;

//** @abstract(A new collection id: a GUID in lower case, without braces.)
//**
//** @returns(The id.)
function NewCollectionId: String;

//** @abstract(Reads the library, the list of collections, from the database.)
//**
//** The first time, with a database that has no library yet, the library and collection files
//** of before it, @code(library.json) and @code(collection-<id>.json) in the cache folder, are
//** written to it and renamed @code(.moved).
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(ALibrary On return, the library; empty if there is none.)
//**
//** @returns(True if there is a library; False otherwise, never an exception.)
function LoadAssetLibrary(const ACacheFolder: String;
  out ALibrary: TSprite3DAssetLibrary): Boolean;

//** @abstract(Writes the library to the database: the last artist and collection open, the
//** last folder, the preferred format, the artists in order, and each collection's name,
//** artist and place in the list.)
//**
//** The artists are written as listed, so one left out is deleted; delete its collections
//** with DeleteAssetCollection first.
//**
//** A collection the list has that the database has not is added, with nothing in it.
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(ALibrary The library.)
//**
//** @raises(Exception If the database cannot be opened or written.)
procedure SaveAssetLibrary(const ACacheFolder: String; const ALibrary: TSprite3DAssetLibrary);

//** @abstract(Reads collection AId from the database.)
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(AId The collection's id.)
//**
//** @param(ACollection On return, the collection when True.)
//**
//** @returns(True if the database has it; False otherwise, never an exception.)
function LoadAssetCollection(const ACacheFolder, AId: String;
  out ACollection: TSprite3DAssetCollection): Boolean;

//** @abstract(Writes a collection to the database, in place of what it had, in one
//** transaction.)
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(ACollection The collection.)
//**
//** @raises(Exception If the id is not one, or the database cannot be opened or written.)
procedure SaveAssetCollection(const ACacheFolder: String;
  const ACollection: TSprite3DAssetCollection);

//** @abstract(Deletes collection AId from the database; its thumbnails stay.)
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @param(AId The collection's id.)
//**
//** @returns(True if it is gone, or was never there.)
function DeleteAssetCollection(const ACacheFolder, AId: String): Boolean;

implementation

uses
  System.IOUtils, System.Hash, System.JSON, System.NetEncoding, System.Variants, System.Math,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.FMXUI.Wait,
  {$IF DEFINED(MSWINDOWS) or (DEFINED(MACOS) and not DEFINED(IOS))}
  // SQLite linked into the program, so there is no library to ship
  FireDAC.Phys.SQLiteWrapper.Stat,
  {$ENDIF}
  OSPaths, JsonText;

function TSprite3DAssetMeta.Size: TPoint3D;
begin
  Result := BoxMax - BoxMin;
end;

{ TSprite3DAssetHasher }

constructor TSprite3DAssetHasher.Create;
begin
  inherited Create;
  FDigests := TDictionary<String, TBytes>.Create;
end;

destructor TSprite3DAssetHasher.Destroy;
begin
  FDigests.Free;
  inherited;
end;

function TSprite3DAssetHasher.FileDigest(const AFileName: String): TBytes;
var
  Key: String;
begin
  Key := UpperCase(AFileName);
  if FDigests.TryGetValue(Key, Result) then
    Exit;
  Result := THashSHA2.GetHashBytesFromFile(AFileName, THashSHA2.TSHA2Version.SHA256);
  FDigests.Add(Key, Result);
end;

// The uri of every element of AArray, an array of objects, that names a file
function NamedFiles(const AArray: TJSONValue): TArray<String>;
var
  Uri: String;
begin
  Result := nil;
  if not (AArray is TJSONArray) then
    Exit;
  for var Item in TJSONArray(AArray) do
    if (Item is TJSONObject) and TJSONObject(Item).TryGetValue<String>('uri', Uri) and
      (Uri <> String.Empty) and not Uri.StartsWith('data:', True) then
      Result := Result + [Uri];
end;

function TSprite3DAssetHasher.HashModel(const AFileName: String;
  out AFiles: TArray<String>; out AError: String): String;
var
  FileName, Folder, Named: String;
  Bytes: TBytes;
  Hash: THashSHA2;
  Root: TJSONValue;
begin
  Result := String.Empty;
  AFiles := nil;
  AError := String.Empty;
  FileName := OSFriendlyPath(AFileName);
  try
    Bytes := TFile.ReadAllBytes(FileName);
  except
    on E: Exception do
    begin
      AError := E.Message;
      Exit;
    end;
  end;
  Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(Bytes);
  if SameText(ExtractFileExt(FileName), '.gltf') then
  begin
    // A glTF that is not JSON is the loader's to report; here it is only
    // its own bytes
    try
      Root := TJSONObject.ParseJSONValue(Bytes, 0);
    except
      Root := nil;
    end;
    try
      if Root is TJSONObject then
        AFiles := NamedFiles(TJSONObject(Root).GetValue('buffers')) +
          NamedFiles(TJSONObject(Root).GetValue('images'));
    finally
      Root.Free;
    end;
    Folder := ExtractFilePath(FileName);
    for var Uri in AFiles do
    begin
      // The name counts, so a model naming another file is another model;
      // then the content, if the file is there
      Hash.Update(TEncoding.UTF8.GetBytes(Uri + #0));
      Named := OSFriendlyPath(TPath.Combine(Folder, TNetEncoding.URL.Decode(Uri)));
      if TFile.Exists(Named) then
        try
          Hash.Update(FileDigest(ExpandFileName(Named)));
        except
          // Unreadable now: it counts by its name, as a missing one does
        end;
    end;
  end;
  Result := LowerCase(Hash.HashAsString);
end;

{ The cache folder }

function AssetKeyFolder(const ACacheFolder, AHash: String): String;
var
  Key: String;
begin
  Key := LowerCase(AHash);
  if Length(Key) < 2 then
    Key := Key + '00';
  Result := OSFriendlyPath(TPath.Combine(TPath.Combine(ACacheFolder, Key.Substring(0, 1)),
    Key.Substring(1, 1)));
end;

//** @abstract(Key AHash's metadata file of before the database, in its key folder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash The key.)
//**
//** @returns(The file's full path.)
function AssetMetaFile(const ACacheFolder, AHash: String): String;
begin
  Result := TPath.Combine(AssetKeyFolder(ACacheFolder, AHash), AHash + '.json');
end;

//** @abstract(Moves key AHash's files from the top of the cache folder, where they were
//** kept before AssetKeyFolder, into their folder, if they are there and it has not got
//** them already. A failure leaves them where they are.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash The key.)
procedure MoveFlatFiles(const ACacheFolder, AHash: String);
var
  Flat, Target: String;
begin
  for var Ext in TArray<String>.Create('.json', '.png') do
  begin
    Flat := OSFriendlyPath(TPath.Combine(ACacheFolder, AHash + Ext));
    if not TFile.Exists(Flat) then
      Continue;
    Target := TPath.Combine(AssetKeyFolder(ACacheFolder, AHash), AHash + Ext);
    try
      ForceDirectories(AssetKeyFolder(ACacheFolder, AHash));
      if TFile.Exists(Target) then
        TFile.Delete(Flat)
      else
        TFile.Move(Flat, Target);
    except
      // Left where it is; it is only made again
    end;
  end;
end;

function AssetThumbnailFile(const ACacheFolder, AHash: String): String;
begin
  Result := TPath.Combine(AssetKeyFolder(ACacheFolder, AHash), AHash + '.png');
end;

// A point as a JSON array of three numbers
// A JSON array of three numbers as a point; False for anything else
function JsonToPoint(const AValue: TJSONValue; out APoint: TPoint3D): Boolean;
var
  Items: TJSONArray;
begin
  Result := False;
  if not (AValue is TJSONArray) then
    Exit;
  Items := TJSONArray(AValue);
  if Items.Count <> 3 then
    Exit;
  for var I := 0 to 2 do
    if not (Items.Items[I] is TJSONNumber) then
      Exit;
  APoint := Point3D(TJSONNumber(Items.Items[0]).AsDouble,
    TJSONNumber(Items.Items[1]).AsDouble, TJSONNumber(Items.Items[2]).AsDouble);
  Result := True;
end;

//** @abstract(Whether AName is a key: 64 hexadecimal digits.)
//**
//** @param(AName A file's name without its extension.)
//**
//** @returns(True if it is.)
function IsAssetKey(const AName: String): Boolean;
begin
  Result := Length(AName) = 64;
  if Result then
    for var C in AName do
      if not CharInSet(C, ['0'..'9', 'a'..'f', 'A'..'F']) then
        Exit(False);
end;

//** @abstract(Deletes the thumbnail files, and metadata files of before the database, from
//** the cache folder: see ClearAssetCache.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AFailed On return, how many could not be deleted.)
//**
//** @returns(How many metadata files were deleted.)
function ClearCacheFiles(const ACacheFolder: String; out AFailed: Integer): Integer;
var
  Folder, Ext, Name, Place: String;
  Files: TArray<String>;
begin
  Result := 0;
  AFailed := 0;
  Folder := OSFriendlyPath(ACacheFolder);
  if (Folder = String.Empty) or not TDirectory.Exists(Folder) then
    Exit;
  try
    Files := TDirectory.GetFiles(Folder, '*', TSearchOption.soAllDirectories);
  except
    on Exception do
    begin
      Inc(AFailed);
      Exit;
    end;
  end;
  for var FileName in Files do
  begin
    Ext := LowerCase(TPath.GetExtension(FileName));
    Name := TPath.GetFileNameWithoutExtension(FileName);
    if Ext = '.tmp' then
    begin
      if not SameText(TPath.GetExtension(Name), '.json') then
        Continue;
      Name := TPath.GetFileNameWithoutExtension(Name);
    end
    else if (Ext <> '.png') and (Ext <> '.json') then
      Continue;
    if not IsAssetKey(Name) then
      Continue;
    // Only in its own key folder, or at the top as before them
    Place := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));
    if not SameText(Place, ExcludeTrailingPathDelimiter(Folder)) and
      not SameText(Place, AssetKeyFolder(Folder, Name)) then
      Continue;
    try
      TFile.Delete(FileName);
      if Ext = '.json' then
        Inc(Result);
    except
      Inc(AFailed);
    end;
  end;
  // The key folders left empty go too
  for var First in '0123456789abcdef' do
    for var Second in '0123456789abcdef' do
    begin
      Place := AssetKeyFolder(Folder, First + Second);
      try
        if TDirectory.Exists(Place) and TDirectory.IsEmpty(Place) then
          TDirectory.Delete(Place);
      except
        // Kept: not empty after all, or in use
      end;
    end;
  for var First in '0123456789abcdef' do
  begin
    Place := TPath.Combine(Folder, First);
    try
      if TDirectory.Exists(Place) and TDirectory.IsEmpty(Place) then
        TDirectory.Delete(Place);
    except
      // Kept
    end;
  end;
end;

//** @abstract(Reads a palette's groups from a JSON array, checking every value.)
//**
//** A group whose name is empty, or the same, ignoring case, as an earlier one's, is left
//** out, as is a key that is not 64 hexadecimal digits or that an earlier group has; keys
//** are put in lower case. An icon that is not a plain file name is dropped.
//**
//** @param(AGroups The array.)
//**
//** @returns(The groups, in order.)
function ReadPaletteGroups(const AGroups: TJSONArray): TArray<TSprite3DPaletteGroup>;
var
  Key: String;
  Models: TJSONArray;
  Group: TSprite3DPaletteGroup;
  Names, Keys: TDictionary<String, Boolean>;
begin
  Result := nil;
  Names := TDictionary<String, Boolean>.Create;
  Keys := TDictionary<String, Boolean>.Create;
  try
    for var Item in AGroups do
    begin
      if not (Item is TJSONObject) then
        Continue;
      Group.Name := Trim(TJSONObject(Item).GetValue<String>('name', ''));
      if (Group.Name = String.Empty) or Names.ContainsKey(LowerCase(Group.Name)) then
        Continue;
      Names.Add(LowerCase(Group.Name), True);
      Group.Models := nil;
      // A plain file name only: never a path into somewhere else
      Group.Icon := Trim(TJSONObject(Item).GetValue<String>('icon', ''));
      if Group.Icon.Contains('/') or Group.Icon.Contains('\') or
        Group.Icon.Contains(':') or Group.Icon.Contains('..') then
        Group.Icon := String.Empty;
      Group.Parent := Trim(TJSONObject(Item).GetValue<String>('parent', ''));
      if TJSONObject(Item).TryGetValue<TJSONArray>('models', Models) then
        for var Value in Models do
        begin
          if not (Value is TJSONString) then
            Continue;
          Key := LowerCase(Value.Value);
          if IsAssetKey(Key) and not Keys.ContainsKey(Key) then
          begin
            Keys.Add(Key, True);
            Group.Models := Group.Models + [Key];
          end;
        end;
      Result := Result + [Group];
    end;
  finally
    Keys.Free;
    Names.Free;
  end;
end;

//** @abstract(Reads a JSON file of the cache whose @code(format) and @code(version) are as
//** given.)
//**
//** @param(AFileName The file.)
//**
//** @param(AFormat The format it must name.)
//**
//** @param(AVersion The version it must have.)
//**
//** @returns(Its root object, the caller's; nil if it is missing, not JSON, or another
//** format or version.)
function ReadCacheJson(const AFileName, AFormat: String;
  const AVersion: Integer): TJSONObject;
var
  Root: TJSONValue;
  Version: Integer;
begin
  Result := nil;
  if not TFile.Exists(AFileName) then
    Exit;
  Root := TJSONObject.ParseJSONValue(TFile.ReadAllBytes(AFileName), 0);
  if (Root is TJSONObject) and
    (TJSONObject(Root).GetValue<String>('format', '') = AFormat) and
    TJSONObject(Root).TryGetValue<Integer>('version', Version) and (Version = AVersion) then
    Exit(TJSONObject(Root));
  Root.Free;
end;

//** @abstract(Whether AId can be a collection's id: letters, digits and hyphens only.)
//**
//** @param(AId The id.)
//**
//** @returns(True if so, and not empty.)
function IsCollectionId(const AId: String): Boolean;
begin
  Result := AId <> String.Empty;
  for var C in AId do
    if not CharInSet(C, ['0'..'9', 'a'..'z', 'A'..'Z', '-']) then
      Exit(False);
end;

function LoadAssetPalette(const ACacheFolder: String;
  out APalette: TArray<TSprite3DPaletteGroup>): Boolean;
var
  Root: TJSONObject;
  Groups: TJSONArray;
begin
  Result := False;
  APalette := nil;
  try
    Root := ReadCacheJson(TPath.Combine(OSFriendlyPath(ACacheFolder),
      ASSET_PALETTE_FILE_NAME), ASSET_PALETTE_FORMAT, ASSET_PALETTE_VERSION);
    if Root = nil then
      Exit;
    try
      if not Root.TryGetValue<TJSONArray>('groups', Groups) then
        Exit;
      APalette := ReadPaletteGroups(Groups);
      Result := True;
    finally
      Root.Free;
    end;
  except
    APalette := nil;
    Result := False;
  end;
end;

//** @abstract(The name of a collection file of before the database.)
//**
//** @param(AId The collection's id.)
//**
//** @returns(@code(collection-<id>.json).)
function AssetCollectionFile(const AId: String): String;
begin
  Result := 'collection-' + LowerCase(AId) + '.json';
end;

function NewCollectionId: String;
begin
  Result := LowerCase(TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
end;

//** @abstract(Reads library.json, the library file of before the database.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(ALibrary On return, the library.)
//**
//** @returns(True if the file was there and read; never an exception.)
function ReadLegacyLibrary(const ACacheFolder: String;
  out ALibrary: TSprite3DAssetLibrary): Boolean;
var
  Root: TJSONObject;
  Items: TJSONArray;
  Entry: TSprite3DLibraryEntry;
begin
  Result := False;
  ALibrary.Collections := nil;
  ALibrary.Last := String.Empty;
  ALibrary.LastFolder := String.Empty;
  ALibrary.PreferredFormat := String.Empty;
  try
    Root := ReadCacheJson(TPath.Combine(OSFriendlyPath(ACacheFolder),
      ASSET_LIBRARY_FILE_NAME), ASSET_LIBRARY_FORMAT, ASSET_LIBRARY_VERSION);
    if Root = nil then
      Exit;
    try
      ALibrary.Last := Root.GetValue<String>('last', '');
      ALibrary.LastFolder := Root.GetValue<String>('lastFolder', '');
      ALibrary.PreferredFormat := LowerCase(Root.GetValue<String>('preferredFormat', ''));
      if Root.TryGetValue<TJSONArray>('collections', Items) then
        for var Item in Items do
        begin
          if not (Item is TJSONObject) then
            Continue;
          Entry := Default(TSprite3DLibraryEntry);
          Entry.Id := TJSONObject(Item).GetValue<String>('id', '');
          Entry.Name := Trim(TJSONObject(Item).GetValue<String>('name', ''));
          if IsCollectionId(Entry.Id) and (Entry.Name <> String.Empty) then
            ALibrary.Collections := ALibrary.Collections + [Entry];
        end;
      Result := True;
    finally
      Root.Free;
    end;
  except
    ALibrary.Collections := nil;
    Result := False;
  end;
end;

//** @abstract(Reads collection-<id>.json, a collection file of before the database.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AId The collection's id.)
//**
//** @param(ACollection On return, the collection.)
//**
//** @returns(True if the file was there and read; never an exception.)
function ReadLegacyCollection(const ACacheFolder, AId: String;
  out ACollection: TSprite3DAssetCollection): Boolean;
var
  Root: TJSONObject;
  Items: TJSONArray;
  Model: TSprite3DCollectionModel;
  Source: TSprite3DCollectionSource;
  Formats: TJSONArray;
  Keys: TDictionary<String, Boolean>;
begin
  Result := False;
  ACollection := Default(TSprite3DAssetCollection);
  if not IsCollectionId(AId) then
    Exit;
  Keys := TDictionary<String, Boolean>.Create;
  try
    try
      Root := ReadCacheJson(TPath.Combine(OSFriendlyPath(ACacheFolder),
        AssetCollectionFile(AId)), ASSET_COLLECTION_FORMAT, ASSET_COLLECTION_VERSION);
      if Root = nil then
        Exit;
      try
        ACollection.Id := LowerCase(AId);
        ACollection.Name := Trim(Root.GetValue<String>('name', ''));
        ACollection.Scanned := Root.GetValue<Boolean>('scanned', False);
        if Root.TryGetValue<TJSONArray>('sources', Items) then
          for var Item in Items do
          begin
            if not (Item is TJSONObject) then
              Continue;
            Source.Folder := TJSONObject(Item).GetValue<String>('folder', '');
            Source.Formats := nil;
            if TJSONObject(Item).TryGetValue<TJSONArray>('formats', Formats) then
              for var Ext in Formats do
                if (Ext is TJSONString) and Ext.Value.StartsWith('.') then
                  Source.Formats := Source.Formats + [LowerCase(Ext.Value)];
            if Source.Folder <> String.Empty then
              ACollection.Sources := ACollection.Sources + [Source];
          end
        // A file of before sources: plain folders, every format
        else if Root.TryGetValue<TJSONArray>('folders', Items) then
          for var Item in Items do
            if (Item is TJSONString) and (Item.Value <> String.Empty) then
            begin
              Source.Folder := Item.Value;
              Source.Formats := nil;
              ACollection.Sources := ACollection.Sources + [Source];
            end;
        if Root.TryGetValue<TJSONArray>('groups', Items) then
          ACollection.Groups := ReadPaletteGroups(Items);
        if Root.TryGetValue<TJSONArray>('models', Items) then
          for var Item in Items do
          begin
            if not (Item is TJSONObject) then
              Continue;
            Model.Key := LowerCase(TJSONObject(Item).GetValue<String>('key', ''));
            Model.FileName := TJSONObject(Item).GetValue<String>('file', '');
            if IsAssetKey(Model.Key) and (Model.FileName <> String.Empty) and
              not Keys.ContainsKey(Model.Key) then
            begin
              Keys.Add(Model.Key, True);
              ACollection.Models := ACollection.Models + [Model];
            end;
          end;
        Result := True;
      finally
        Root.Free;
      end;
    except
      ACollection := Default(TSprite3DAssetCollection);
      Result := False;
    end;
  finally
    Keys.Free;
  end;
end;

//** @abstract(Reads key AHash's metadata file of before the database, @code(<AHash>.json),
//** from its key folder, or from the top of ACacheFolder.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @param(AHash The key.)
//**
//** @param(AMeta On return, the metadata when True.)
//**
//** @returns(True if the file is there and every value is right; never an exception.)
function ReadLegacyMeta(const ACacheFolder, AHash: String;
  out AMeta: TSprite3DAssetMeta): Boolean;
var
  FileName, Text: String;
  Root: TJSONValue;
  Obj, Box, Thumb: TJSONObject;
  Version, Width, Height: Integer;
  Files: TJSONArray;
begin
  // A cache from before the key folders: its files moved in first
  MoveFlatFiles(ACacheFolder, AHash);
  Result := False;
  AMeta := Default(TSprite3DAssetMeta);
  FileName := AssetMetaFile(ACacheFolder, AHash);
  if not TFile.Exists(FileName) then
    Exit;
  Root := nil;
  try
    try
      Root := TJSONObject.ParseJSONValue(TFile.ReadAllBytes(FileName), 0);
      if not (Root is TJSONObject) then
        Exit;
      Obj := TJSONObject(Root);
      if not Obj.TryGetValue<String>('format', Text) or (Text <> ASSET_META_FORMAT) then
        Exit;
      if not Obj.TryGetValue<Integer>('version', Version) or
        (Version <> ASSET_META_VERSION) then
        Exit;
      if not Obj.TryGetValue<String>('hash', AMeta.Hash) or
        not SameText(AMeta.Hash, AHash) then
        Exit;
      if not Obj.TryGetValue<String>('name', AMeta.Name) or
        not Obj.TryGetValue<String>('group', AMeta.Group) or
        not Obj.TryGetValue<String>('file', AMeta.FileName) then
        Exit;
      if Obj.TryGetValue<TJSONArray>('files', Files) then
        for var Item in Files do
          if Item is TJSONString then
            AMeta.Files := AMeta.Files + [TJSONString(Item).Value]
          else
            Exit;
      if not Obj.TryGetValue<TJSONObject>('bounds', Box) or
        not JsonToPoint(Box.GetValue('min'), AMeta.BoxMin) or
        not JsonToPoint(Box.GetValue('max'), AMeta.BoxMax) then
        Exit;
      if not Obj.TryGetValue<TJSONObject>('thumbnail', Thumb) or
        not Thumb.TryGetValue<Integer>('width', Width) or
        not Thumb.TryGetValue<Integer>('height', Height) or
        (Width <= 0) or (Height <= 0) then
        Exit;
      AMeta.ThumbWidth := Width;
      AMeta.ThumbHeight := Height;
      Thumb.TryGetValue<String>('view', AMeta.View);
      Thumb.TryGetValue<String>('created', AMeta.Created);
      Result := True;
    except
      // A damaged file: as if there were none
      Result := False;
    end;
  finally
    Root.Free;
    if not Result then
      AMeta := Default(TSprite3DAssetMeta);
  end;
end;

{ The database }

var
  //** @abstract(The open databases, by file, one connection each, for the main thread;
  //** freed at finalization.)
  Databases: TObjectDictionary<String, TFDConnection> = nil;

//** @abstract(Makes the tables of a new database, or of one older than
//** ASSET_DATABASE_VERSION.)
//**
//** @param(AConnection The open database.)
procedure CreateSchema(const AConnection: TFDConnection);
var
  Version: Integer;
begin
  Version := AConnection.ExecSQLScalar('PRAGMA user_version');
  if Version >= ASSET_DATABASE_VERSION then
    Exit;
  AConnection.StartTransaction;
  try
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS library (id INTEGER PRIMARY KEY ' +
      'CHECK (id = 1), last_id TEXT NOT NULL DEFAULT '''', last_folder TEXT NOT NULL ' +
      'DEFAULT '''', preferred_format TEXT NOT NULL DEFAULT '''')');
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS collections (id TEXT PRIMARY KEY, ' +
      'name TEXT NOT NULL, position INTEGER NOT NULL, scanned INTEGER NOT NULL ' +
      'DEFAULT 0)');
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS sources (collection_id TEXT NOT NULL, ' +
      'position INTEGER NOT NULL, folder TEXT NOT NULL, formats TEXT NOT NULL, ' +
      'PRIMARY KEY (collection_id, position))');
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS palette_groups (collection_id TEXT NOT NULL, ' +
      'position INTEGER NOT NULL, name TEXT NOT NULL, icon TEXT NOT NULL, parent TEXT ' +
      'NOT NULL, PRIMARY KEY (collection_id, position))');
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS group_models (collection_id TEXT NOT ' +
      'NULL, group_position INTEGER NOT NULL, position INTEGER NOT NULL, model_key TEXT NOT ' +
      'NULL, PRIMARY KEY (collection_id, group_position, position))');
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS models (collection_id TEXT NOT NULL, ' +
      'position INTEGER NOT NULL, model_key TEXT NOT NULL, file TEXT NOT NULL, ' +
      'PRIMARY KEY (collection_id, position))');
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS meta (model_key TEXT PRIMARY KEY, name TEXT ' +
      'NOT NULL, grp TEXT NOT NULL, file TEXT NOT NULL, files TEXT NOT NULL, ' +
      'min_x REAL, min_y REAL, min_z REAL, max_x REAL, max_y REAL, max_z REAL, ' +
      'thumb_width INTEGER NOT NULL, thumb_height INTEGER NOT NULL, thumb_view TEXT NOT NULL, ' +
      'created TEXT NOT NULL)');
    // 2: artists, above collections
    AConnection.ExecSQL('CREATE TABLE IF NOT EXISTS artists (id TEXT PRIMARY KEY, name ' +
      'TEXT NOT NULL, position INTEGER NOT NULL)');
    if Version < 2 then
    begin
      // A database of 1 has these tables without the new columns; a new one
      // was made just now without them too
      AConnection.ExecSQL('ALTER TABLE collections ADD COLUMN artist_id TEXT NOT NULL ' +
        'DEFAULT ''''');
      AConnection.ExecSQL('ALTER TABLE library ADD COLUMN last_artist TEXT NOT NULL ' +
        'DEFAULT ''''');
    end;
    // 3: what each model holds, and the kind of model it makes
    if Version < 3 then
    begin
      for var Column in TArray<String>.Create('meshes', 'vertices', 'animations', 'skins',
        'joints') do
        AConnection.ExecSQL('ALTER TABLE meta ADD COLUMN ' + Column +
          ' INTEGER NOT NULL DEFAULT 0');
      AConnection.ExecSQL('ALTER TABLE meta ADD COLUMN kind TEXT NOT NULL DEFAULT ''''');
    end;
    AConnection.ExecSQL('PRAGMA user_version = ' + IntToStr(ASSET_DATABASE_VERSION));
    AConnection.Commit;
  except
    AConnection.Rollback;
    raise;
  end;
end;

//** @abstract(The open database that goes with ACacheFolder, opened, and made, the first
//** time.)
//**
//** @param(ACacheFolder The cache folder; see AssetDatabaseFile.)
//**
//** @returns(The connection; not the caller's.)
//**
//** @raises(Exception If it cannot be opened or made.)
function Database(const ACacheFolder: String): TFDConnection;
var
  FileName: String;
begin
  FileName := AssetDatabaseFile(ACacheFolder);
  if Databases = nil then
    Databases := TObjectDictionary<String, TFDConnection>.Create([doOwnsValues]);
  if Databases.TryGetValue(LowerCase(FileName), Result) then
    Exit;
  ForceDirectories(ExtractFilePath(FileName));
  Result := TFDConnection.Create(nil);
  try
    Result.DriverName := 'SQLite';
    Result.Params.Values['Database'] := FileName;
    Result.Params.Values['OpenMode'] := 'CreateUTF8';
    Result.Params.Values['LockingMode'] := 'Normal';
    Result.Params.Values['JournalMode'] := 'WAL';
    Result.Params.Values['Synchronous'] := 'Normal';
    Result.Params.Values['BusyTimeout'] := '10000';
    Result.LoginPrompt := False;
    Result.ResourceOptions.SilentMode := True;
    Result.Connected := True;
    CreateSchema(Result);
  except
    Result.Free;
    raise;
  end;
  Databases.Add(LowerCase(FileName), Result);
end;

//** @abstract(A query on the database, opened with ASQL and AParams.)
//**
//** @param(AConnection The database.)
//**
//** @param(ASQL The SELECT.)
//**
//** @param(AParams Its parameters, in order.)
//**
//** @returns(The query, open; the caller's.)
function OpenQuery(const AConnection: TFDConnection; const ASQL: String;
  const AParams: array of Variant): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := AConnection;
    Result.Open(ASQL, AParams);
  except
    Result.Free;
    raise;
  end;
end;

function AssetDatabaseFile(const ACacheFolder: String): String;
begin
  Result := OSFriendlyPath(TPath.Combine(ExtractFileDir(ExcludeTrailingPathDelimiter(
    OSFriendlyPath(ACacheFolder))), ASSET_DATABASE_FILE_NAME));
end;

//** @abstract(Writes AMeta to the database AConnection.)
//**
//** @param(AConnection The database.)
//**
//** @param(AMeta The metadata.)
procedure WriteMeta(const AConnection: TFDConnection; const AMeta: TSprite3DAssetMeta);
begin
  AConnection.ExecSQL('INSERT OR REPLACE INTO meta (model_key, name, grp, file, files, min_x, ' +
    'min_y, min_z, max_x, max_y, max_z, thumb_width, thumb_height, thumb_view, created, ' +
    'meshes, vertices, animations, skins, joints, kind) ' +
    'VALUES (:model_key, :name, :grp, :file, :files, :min_x, :min_y, :min_z, :max_x, :max_y, ' +
    ':max_z, :thumb_width, :thumb_height, :thumb_view, :created, :meshes, :vertices, ' +
    ':animations, :skins, :joints, :kind)',
    [LowerCase(AMeta.Hash), AMeta.Name, AMeta.Group, AMeta.FileName,
    String.Join(#10, AMeta.Files), AMeta.BoxMin.X, AMeta.BoxMin.Y, AMeta.BoxMin.Z,
    AMeta.BoxMax.X, AMeta.BoxMax.Y, AMeta.BoxMax.Z, AMeta.ThumbWidth, AMeta.ThumbHeight,
    AMeta.View, AMeta.Created, AMeta.Meshes, AMeta.Vertices, AMeta.Animations, AMeta.Skins,
    AMeta.Joints, AMeta.Kind]);
end;

procedure SaveAssetMeta(const ACacheFolder: String; const AMeta: TSprite3DAssetMeta);
begin
  WriteMeta(Database(ACacheFolder), AMeta);
end;

function LoadAssetMeta(const ACacheFolder, AHash: String;
  out AMeta: TSprite3DAssetMeta): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  Files: String;
begin
  Result := False;
  AMeta := Default(TSprite3DAssetMeta);
  try
    Connection := Database(ACacheFolder);
    Query := OpenQuery(Connection, 'SELECT * FROM meta WHERE model_key = :model_key',
      [LowerCase(AHash)]);
    try
      if not Query.Eof then
      begin
        AMeta.Hash := Query.FieldByName('model_key').AsString;
        AMeta.Name := Query.FieldByName('name').AsString;
        AMeta.Group := Query.FieldByName('grp').AsString;
        AMeta.FileName := Query.FieldByName('file').AsString;
        Files := Query.FieldByName('files').AsString;
        if Files <> String.Empty then
          AMeta.Files := Files.Split([#10]);
        AMeta.BoxMin := Point3D(Query.FieldByName('min_x').AsSingle,
          Query.FieldByName('min_y').AsSingle, Query.FieldByName('min_z').AsSingle);
        AMeta.BoxMax := Point3D(Query.FieldByName('max_x').AsSingle,
          Query.FieldByName('max_y').AsSingle, Query.FieldByName('max_z').AsSingle);
        AMeta.ThumbWidth := Query.FieldByName('thumb_width').AsInteger;
        AMeta.ThumbHeight := Query.FieldByName('thumb_height').AsInteger;
        AMeta.View := Query.FieldByName('thumb_view').AsString;
        AMeta.Created := Query.FieldByName('created').AsString;
        AMeta.Meshes := Query.FieldByName('meshes').AsInteger;
        AMeta.Vertices := Query.FieldByName('vertices').AsInteger;
        AMeta.Animations := Query.FieldByName('animations').AsInteger;
        AMeta.Skins := Query.FieldByName('skins').AsInteger;
        AMeta.Joints := Query.FieldByName('joints').AsInteger;
        AMeta.Kind := Query.FieldByName('kind').AsString;
        Exit(True);
      end;
    finally
      Query.Free;
    end;
    // Not in the database: a file of before it, moved in
    if ReadLegacyMeta(ACacheFolder, AHash, AMeta) then
    begin
      WriteMeta(Connection, AMeta);
      try
        TFile.Delete(AssetMetaFile(ACacheFolder, AHash));
      except
        // Read again next time; harmless
      end;
      Result := True;
    end;
  except
    AMeta := Default(TSprite3DAssetMeta);
    Result := False;
  end;
end;

function ClearAssetCache(const ACacheFolder: String; out AFailed: Integer): Integer;
begin
  Result := ClearCacheFiles(ACacheFolder, AFailed);
  try
    Result := Max(Result, Database(ACacheFolder).ExecSQL('DELETE FROM meta'));
  except
    Inc(AFailed);
  end;
end;

//** @abstract(Writes the library and its collections of before the database, if there are
//** any, to the database, and renames their files @code(.moved); once, as the database is
//** found to have no library.)
//**
//** @param(ACacheFolder The cache folder.)
//**
//** @returns(True if a library was moved in.)
function MoveLegacyLibrary(const ACacheFolder: String): Boolean;
var
  Old: TSprite3DAssetLibrary;
  Collection: TSprite3DAssetCollection;
  FileName: String;
begin
  Result := False;
  if not ReadLegacyLibrary(ACacheFolder, Old) then
    Exit;
  for var Entry in Old.Collections do
    if ReadLegacyCollection(ACacheFolder, Entry.Id, Collection) then
    begin
      Collection.Name := Entry.Name;
      SaveAssetCollection(ACacheFolder, Collection);
    end;
  SaveAssetLibrary(ACacheFolder, Old);
  // Kept, renamed, so they are not moved in again
  for var Entry in Old.Collections do
  begin
    FileName := TPath.Combine(OSFriendlyPath(ACacheFolder), AssetCollectionFile(Entry.Id));
    try
      if TFile.Exists(FileName) then
        TFile.Move(FileName, FileName + '.moved');
    except
      // Left; the database is what is read from now on
    end;
  end;
  FileName := TPath.Combine(OSFriendlyPath(ACacheFolder), ASSET_LIBRARY_FILE_NAME);
  try
    TFile.Move(FileName, FileName + '.moved');
  except
    // Left; the database is what is read from now on
  end;
  Result := True;
end;

function LoadAssetLibrary(const ACacheFolder: String;
  out ALibrary: TSprite3DAssetLibrary): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  Entry: TSprite3DLibraryEntry;
  Artist: TSprite3DArtist;
begin
  Result := False;
  ALibrary.Artists := nil;
  ALibrary.LastArtist := String.Empty;
  ALibrary.Collections := nil;
  ALibrary.Last := String.Empty;
  ALibrary.LastFolder := String.Empty;
  ALibrary.PreferredFormat := String.Empty;
  try
    Connection := Database(ACacheFolder);
    if Connection.ExecSQLScalar('SELECT COUNT(*) FROM library') = 0 then
      if not MoveLegacyLibrary(ACacheFolder) then
        Exit;
    Query := OpenQuery(Connection, 'SELECT * FROM library WHERE id = 1', []);
    try
      if Query.Eof then
        Exit;
      ALibrary.Last := Query.FieldByName('last_id').AsString;
      ALibrary.LastFolder := Query.FieldByName('last_folder').AsString;
      ALibrary.PreferredFormat := Query.FieldByName('preferred_format').AsString;
      ALibrary.LastArtist := Query.FieldByName('last_artist').AsString;
    finally
      Query.Free;
    end;
    Query := OpenQuery(Connection, 'SELECT id, name FROM artists ORDER BY position', []);
    try
      while not Query.Eof do
      begin
        Artist.Id := Query.FieldByName('id').AsString;
        Artist.Name := Query.FieldByName('name').AsString;
        ALibrary.Artists := ALibrary.Artists + [Artist];
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    // Each with how many models it has, for the counts the Library shows
    Query := OpenQuery(Connection, 'SELECT c.id, c.name, c.artist_id, c.scanned, ' +
      '(SELECT COUNT(*) FROM models m WHERE m.collection_id = c.id) AS model_count ' +
      'FROM collections c ORDER BY c.position', []);
    try
      while not Query.Eof do
      begin
        Entry.Id := Query.FieldByName('id').AsString;
        Entry.Name := Query.FieldByName('name').AsString;
        Entry.ArtistId := Query.FieldByName('artist_id').AsString;
        Entry.Scanned := Query.FieldByName('scanned').AsInteger <> 0;
        Entry.Models := Query.FieldByName('model_count').AsInteger;
        ALibrary.Collections := ALibrary.Collections + [Entry];
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    Result := True;
  except
    ALibrary.Collections := nil;
    Result := False;
  end;
end;

procedure SaveAssetLibrary(const ACacheFolder: String; const ALibrary: TSprite3DAssetLibrary);
var
  Connection: TFDConnection;
begin
  Connection := Database(ACacheFolder);
  Connection.StartTransaction;
  try
    Connection.ExecSQL('INSERT OR REPLACE INTO library (id, last_id, last_folder, ' +
      'preferred_format, last_artist) VALUES (1, :last_id, :last_folder, ' +
      ':preferred_format, :last_artist)', [ALibrary.Last, ALibrary.LastFolder,
      ALibrary.PreferredFormat, ALibrary.LastArtist]);
    // The artists as listed: those gone are deleted, their collections with
    // them by DeleteAssetCollection, which the application calls first
    Connection.ExecSQL('DELETE FROM artists');
    for var I := 0 to High(ALibrary.Artists) do
      Connection.ExecSQL('INSERT INTO artists (id, name, position) VALUES (:id, :name, ' +
        ':position)', [LowerCase(ALibrary.Artists[I].Id), ALibrary.Artists[I].Name, I]);
    for var I := 0 to High(ALibrary.Collections) do
      Connection.ExecSQL('INSERT INTO collections (id, name, position, scanned, artist_id) ' +
        'VALUES (:id, :name, :position, 0, :artist_id) ON CONFLICT (id) DO UPDATE SET ' +
        'name = excluded.name, position = excluded.position, artist_id = ' +
        'excluded.artist_id', [LowerCase(ALibrary.Collections[I].Id),
        ALibrary.Collections[I].Name, I, LowerCase(ALibrary.Collections[I].ArtistId)]);
    Connection.Commit;
  except
    Connection.Rollback;
    raise;
  end;
end;

function LoadAssetCollection(const ACacheFolder, AId: String;
  out ACollection: TSprite3DAssetCollection): Boolean;
var
  Connection: TFDConnection;
  Query: TFDQuery;
  Source: TSprite3DCollectionSource;
  Model: TSprite3DCollectionModel;
  Formats: String;
  Index: Integer;
begin
  Result := False;
  ACollection := Default(TSprite3DAssetCollection);
  if not IsCollectionId(AId) then
    Exit;
  try
    Connection := Database(ACacheFolder);
    Query := OpenQuery(Connection, 'SELECT * FROM collections WHERE id = :id',
      [LowerCase(AId)]);
    try
      if Query.Eof then
        Exit;
      ACollection.Id := Query.FieldByName('id').AsString;
      ACollection.Name := Query.FieldByName('name').AsString;
      ACollection.Scanned := Query.FieldByName('scanned').AsInteger <> 0;
      ACollection.ArtistId := Query.FieldByName('artist_id').AsString;
    finally
      Query.Free;
    end;
    Query := OpenQuery(Connection, 'SELECT folder, formats FROM sources WHERE ' +
      'collection_id = :id ORDER BY position', [ACollection.Id]);
    try
      while not Query.Eof do
      begin
        Source.Folder := Query.FieldByName('folder').AsString;
        Formats := Query.FieldByName('formats').AsString;
        Source.Formats := nil;
        if Formats <> String.Empty then
          Source.Formats := Formats.Split([' ']);
        ACollection.Sources := ACollection.Sources + [Source];
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    Query := OpenQuery(Connection, 'SELECT name, icon, parent FROM palette_groups WHERE ' +
      'collection_id = :id ORDER BY position', [ACollection.Id]);
    try
      SetLength(ACollection.Groups, 0);
      while not Query.Eof do
      begin
        SetLength(ACollection.Groups, Length(ACollection.Groups) + 1);
        Index := High(ACollection.Groups);
        ACollection.Groups[Index].Name := Query.FieldByName('name').AsString;
        ACollection.Groups[Index].Icon := Query.FieldByName('icon').AsString;
        ACollection.Groups[Index].Parent := Query.FieldByName('parent').AsString;
        ACollection.Groups[Index].Models := nil;
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    Query := OpenQuery(Connection, 'SELECT group_position, model_key FROM group_models WHERE ' +
      'collection_id = :id ORDER BY group_position, position', [ACollection.Id]);
    try
      while not Query.Eof do
      begin
        Index := Query.FieldByName('group_position').AsInteger;
        if (Index >= 0) and (Index <= High(ACollection.Groups)) then
          ACollection.Groups[Index].Models := ACollection.Groups[Index].Models +
            [Query.FieldByName('model_key').AsString];
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    Query := OpenQuery(Connection, 'SELECT model_key, file FROM models WHERE collection_id = :id ' +
      'ORDER BY position', [ACollection.Id]);
    try
      while not Query.Eof do
      begin
        Model.Key := Query.FieldByName('model_key').AsString;
        Model.FileName := Query.FieldByName('file').AsString;
        ACollection.Models := ACollection.Models + [Model];
        Query.Next;
      end;
    finally
      Query.Free;
    end;
    Result := True;
  except
    ACollection := Default(TSprite3DAssetCollection);
    Result := False;
  end;
end;

procedure SaveAssetCollection(const ACacheFolder: String;
  const ACollection: TSprite3DAssetCollection);
var
  Connection: TFDConnection;
  Id: String;
begin
  if not IsCollectionId(ACollection.Id) then
    raise EArgumentException.Create('Not a collection id: ' + ACollection.Id);
  Id := LowerCase(ACollection.Id);
  Connection := Database(ACacheFolder);
  Connection.StartTransaction;
  try
    // Last in the list if it is new; where it was if not
    Connection.ExecSQL('INSERT INTO collections (id, name, position, scanned, artist_id) ' +
      'VALUES (:id, :name, (SELECT COALESCE(MAX(position), -1) + 1 FROM collections), ' +
      ':scanned, :artist_id) ON CONFLICT (id) DO UPDATE SET name = excluded.name, ' +
      'scanned = excluded.scanned, artist_id = excluded.artist_id',
      [Id, ACollection.Name, Ord(ACollection.Scanned), LowerCase(ACollection.ArtistId)]);
    for var Table in TArray<String>.Create('sources', 'palette_groups', 'group_models', 'models') do
      Connection.ExecSQL('DELETE FROM ' + Table + ' WHERE collection_id = :id', [Id]);
    for var I := 0 to High(ACollection.Sources) do
      Connection.ExecSQL('INSERT INTO sources (collection_id, position, folder, formats) ' +
        'VALUES (:id, :position, :folder, :formats)', [Id, I, ACollection.Sources[I].Folder,
        String.Join(' ', ACollection.Sources[I].Formats)]);
    for var I := 0 to High(ACollection.Groups) do
    begin
      Connection.ExecSQL('INSERT INTO palette_groups (collection_id, position, name, ' +
        'icon, parent) VALUES (:id, :position, :name, :icon, :parent)',
        [Id, I, ACollection.Groups[I].Name, ACollection.Groups[I].Icon,
        ACollection.Groups[I].Parent]);
      for var M := 0 to High(ACollection.Groups[I].Models) do
        Connection.ExecSQL('INSERT INTO group_models (collection_id, group_position, ' +
          'position, model_key) VALUES (:id, :group_position, :position, :model_key)',
          [Id, I, M, ACollection.Groups[I].Models[M]]);
    end;
    for var I := 0 to High(ACollection.Models) do
      Connection.ExecSQL('INSERT INTO models (collection_id, position, model_key, file) ' +
        'VALUES (:id, :position, :model_key, :file)', [Id, I, ACollection.Models[I].Key,
        ACollection.Models[I].FileName]);
    Connection.Commit;
  except
    Connection.Rollback;
    raise;
  end;
end;

function DeleteAssetCollection(const ACacheFolder, AId: String): Boolean;
var
  Connection: TFDConnection;
begin
  Result := False;
  if not IsCollectionId(AId) then
    Exit;
  try
    Connection := Database(ACacheFolder);
    Connection.StartTransaction;
    try
      for var Table in TArray<String>.Create('sources', 'palette_groups', 'group_models',
        'models') do
        Connection.ExecSQL('DELETE FROM ' + Table + ' WHERE collection_id = :id',
          [LowerCase(AId)]);
      Connection.ExecSQL('DELETE FROM collections WHERE id = :id', [LowerCase(AId)]);
      Connection.Commit;
    except
      Connection.Rollback;
      raise;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

function ClearAssetLibrary(const ACacheFolder: String; out AError: String): Boolean;
var
  FileName, Folder: String;
  Connection: TFDConnection;
begin
  AError := String.Empty;
  FileName := AssetDatabaseFile(ACacheFolder);
  // Closed, so the files can go
  if (Databases <> nil) and Databases.TryGetValue(LowerCase(FileName), Connection) then
  begin
    try
      Connection.Connected := False;
    except
      on E: Exception do
        AError := AError + 'closing ' + FileName + ': ' + E.Message + sLineBreak;
    end;
    Databases.Remove(LowerCase(FileName));
  end;
  for var Ext in TArray<String>.Create('', '-wal', '-shm', '-journal') do
    try
      if TFile.Exists(FileName + Ext) then
        TFile.Delete(FileName + Ext);
    except
      on E: Exception do
        AError := AError + FileName + Ext + ': ' + E.Message + sLineBreak;
    end;
  Folder := ExcludeTrailingPathDelimiter(OSFriendlyPath(ACacheFolder));
  try
    if (Folder <> String.Empty) and TDirectory.Exists(Folder) then
      TDirectory.Delete(Folder, True);
  except
    on E: Exception do
      AError := AError + Folder + ': ' + E.Message + sLineBreak;
  end;
  AError := Trim(AError);
  Result := AError = String.Empty;
end;

initialization

finalization
  FreeAndNil(Databases);

end.
