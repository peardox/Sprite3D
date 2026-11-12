//** @abstract(The textures a model names, made ready for the model loader: each one found,
//** and made a PNG if it is in a format the loader does not read, and the model loaded
//** from a copy that names what was found.)
//**
//** A model kit can name textures the loader cannot use: an image in a format it does not
//** read (a layered image file, @code(.psd), say), or a file that is not there, as when the
//** kit was exported naming its working files but ships PNGs. PrepareModelTextures goes
//** through every image a glTF (@code(.gltf)) names, in this order:
//**
//** @orderedList(
//**   @item(The file named, if it is there and in a format the loader reads
//**     (LoaderReadsImage), is used as it is.)
//**   @item(The file named, if it is there in any other format the image library reads,
//**     is made a PNG.)
//**   @item(Only if the file named is not there, or cannot be read, a file of the same
//**     name, case ignored, is looked for elsewhere, nearest first: in the folder named
//**     and the model's folder, then anywhere below each of the model's folder's parents,
//**     up to SEARCH_LEVELS_UP, but never a disk's root or a folder directly in it, nor a
//**     tree of more than TREE_FILE_LIMIT files. It is used as it is, or made a PNG.)
//**   @item(Only then the same name with another extension, in the same places in the
//**     same order: PNG first, then JPEG, then any other format the image library reads,
//**     which is made a PNG.)
//**   @item(Then, for a name with an image's extension in it, as an exporter can leave
//**     (@code(T_Wall_png.png)), the name without it (WithoutNamedExtension), in the same
//**     places in the same order.)
//**   @item(Failing all of those, the placeholder texture (PLACEHOLDER_FILE_NAME), so the
//**     model still loads, its thumbnail showing where the texture is missing.))
//**
//** If any texture had to be found or made, the model is loaded from a copy of it in the
//** cache's @code(models) folder, named after the model's key. The loader looks for the
//** files a glTF names in the glTF's own folder, whatever its uri says (a full path is
//** not taken), so every file the copy names, its buffers and every texture, is in that
//** folder too, named after the SHA-256 of its content: a file the model kit uses as it
//** is, copied there once; a PNG made, named after the file it was made from. So a texture
//** many models share is there once, and is made or copied again only when it changes.
//** The model kit's own files are never written.
//**
//** A layered image file's channels after the colour ones are taken for transparency
//** only when the file says its merged image has it (MergedAlpha); the image library
//** alone would take any such channel, a saved selection as a rule, for transparency.
//**
//** The images are read by the Vampyre Imaging Library (the @code(imaginglib) submodule),
//** which is pure Pascal, so this works on every platform the program is built for. Its
//** settings are global, as are the folder listings kept here: call PrepareModelTextures
//** from one thread at a time; the program calls it from the main thread only.
//**
//** A buffer, a glTF's binary data, that is not where the model says is looked for too
//** (ResolveBuffer): the same name nearest first, then, beside the model, one named as the
//** model or as the name given without a copy number such as @code(_001); only a file of
//** the length the model gives it is taken. Found ones go in the copy as textures do.
//**
//** Other model formats are loaded as they are, for now.
unit Sprite3DModelTextures;

{
  The textures a model names, made ready for the model loader: each one
  found, and made a PNG if it is in a format the loader does not read, and
  the model loaded from a copy that names what was found.

  For each image a glTF names: the file named, if the loader reads it; else
  the file named made a PNG, if the image library reads it; else, only then,
  the same file name, case ignored, nearest first: the folder named, the
  model's, then below each of its parents up to SEARCH_LEVELS_UP (never a
  disk's root or a folder in it, nor a tree of more than TREE_FILE_LIMIT
  files); else the same name with another extension in the same places;
  else the name without an image extension left in it (T_Wall_png.png);
  else a magenta and black placeholder, so the model still loads. If anything was
  found or made, the model is loaded from a copy in the cache's models
  folder; every file it names (buffers, textures, PNGs made) is copied
  beside it, named after the SHA-256 of its content (a PNG made, of its
  source), as the loader looks for them in the glTF's own folder. The
  kit's own files are never written. One thread at a time.
}

interface

uses
  System.SysUtils;

const
  //** @abstract(How many folders above the model's a texture is looked for in, each with
  //** every folder below it.)
  SEARCH_LEVELS_UP = 3;

type
  //** @abstract(What became of a texture a model names.)
  TSprite3DTextureOutcome = (
    //** @abstract(Used as it is: there, in a format the loader reads.)
    toAsNamed,
    //** @abstract(There, in a format the loader does not read: made a PNG.)
    toConverted,
    //** @abstract(Not there, or not readable; the same name in a format the loader reads
    //** was used instead.)
    toOtherFile,
    //** @abstract(Not there, or not readable; the same name in another format was found
    //** and made a PNG.)
    toOtherFileConverted,
    //** @abstract(Nothing could be used: the placeholder texture is used in its place, for
    //** a texture, if it could be made; a buffer is left as named, for the loader to report.)
    toMissing);

  //** @abstract(One texture a model names, and what was done with it.)
  TSprite3DTextureFix = record
    //** @abstract(The name as the model gives it.)
    Named: String;
    //** @abstract(The file used in its place: the file found, or the PNG made; empty for
    //** toAsNamed and toMissing.)
    Used: String;
    //** @abstract(The file the PNG was made from, for toConverted and
    //** toOtherFileConverted; empty otherwise.)
    Source: String;
    //** @abstract(What became of it.)
    Outcome: TSprite3DTextureOutcome;
    //** @abstract(Why the file named was not used as it is; empty for toAsNamed and
    //** toConverted.)
    Reason: String;
    //** @abstract(True for a buffer, the model's binary data, rather than a texture.)
    IsBuffer: Boolean;
  end;

//** @abstract(Whether the model loader reads image file AFileName as it is, judged by its
//** extension: PNG and JPEG, which FMX reads on every platform.)
//**
//** @param(AFileName The file.)
//**
//** @returns(True for @code(.png), @code(.jpg) and @code(.jpeg), case ignored.)
function LoaderReadsImage(const AFileName: String): Boolean;

//** @abstract(Readies the textures model AModelFile names, as the unit's description says,
//** and gives the file to load it from.)
//**
//** @param(AModelFile The model file, as a full path.)
//**
//** @param(ACacheFolder The cache; the copy, and every file it names, go in its
//** @code(models) folder.)
//**
//** @param(AKey The model's key, which names its copy; see TSprite3DAssetHasher.)
//**
//** @param(AFixes On return, every texture the model names, with what was done with it;
//** empty for a model that is not a glTF, or names none.)
//**
//** @returns(The file to load: the copy, if any texture was found or made, else
//** AModelFile.)
//**
//** @raises(Exception If the copy, or a file it names, cannot be written.)
function PrepareModelTextures(const AModelFile, ACacheFolder, AKey: String;
  out AFixes: TArray<TSprite3DTextureFix>): String;

implementation

uses
  System.Classes, System.IOUtils, System.JSON, System.NetEncoding, System.Hash,
  System.Generics.Collections, System.Generics.Defaults,
  Imaging, ImagingTypes, OSPaths, JsonText;

const
  //** @abstract(The cache's folder of models' copies, and every file they name.)
  MODEL_FOLDER_NAME = 'models';
  //** @abstract(Goes before the extension of every PNG made, and changes whenever the way
  //** they are made does, so none made the old way is used again.)
  MADE_PNG_VERSION = '.v3';
  //** @abstract(The texture put in the place of one that cannot be found, in the folder of
  //** models' copies: a magenta and black checker, the usual sign of a missing texture.)
  PLACEHOLDER_FILE_NAME = 'missing-texture.v1.png';
  //** @abstract(How many files, of any kind, a folder's tree may hold for a texture to be
  //** looked for in it.)
  TREE_FILE_LIMIT = 100000;
  //** @abstract(How long, in milliseconds, a folder's listing is used again before it is
  //** made afresh.)
  LISTING_KEEP_MS = 30 * 60 * 1000;

type
  //** @abstract(What a file says about the transparency of its merged image, the one the
  //** image library reads.)
  TMergedAlpha = (
    //** @abstract(Not a layered image file: its alpha, if any, is taken as it is.)
    maNotLayered,
    //** @abstract(A layered image file whose merged image is opaque: any extra channel is
    //** a saved selection or mask, not transparency.)
    maOpaque,
    //** @abstract(A layered image file whose merged image has transparency, in its first
    //** extra channel.)
    maTransparent);

//** @abstract(Reads ASize bytes of AStream as a big-endian unsigned number.)
//**
//** @param(AStream The stream.)
//**
//** @param(ASize How many bytes, 1 to 8.)
//**
//** @returns(The number.)
//**
//** @raises(EReadError If the stream ends first.)
function ReadBigEndian(const AStream: TStream; const ASize: Integer): Int64;
var
  Bytes: TBytes;
begin
  SetLength(Bytes, ASize);
  AStream.ReadBuffer(Bytes[0], ASize);
  Result := 0;
  for var I := 0 to ASize - 1 do
    Result := (Result shl 8) or Bytes[I];
end;

//** @abstract(What layered image file AFile (@code(.psd) or @code(.psb)) says about its
//** merged image's transparency.)
//**
//** The merged image is the one stored whole after the layers, which the image library
//** reads. Its channels after the colour ones are alpha channels, saved selections and
//** masks as a rule; the first of them is the merged image's transparency only when the
//** layer count is stored as a negative number. The layer count is in the layer info,
//** or, for 16 and 32 bits a channel, in a tagged block (@code(Lr16), @code(Lr32) or
//** @code(Layr)) after it. A file with no layers has no transparency.
//**
//** @param(AFile The file.)
//**
//** @returns(maNotLayered if it is not a layered image file; else whether its merged image
//** has transparency, maOpaque if that cannot be told.)
function MergedAlpha(const AFile: String): TMergedAlpha;
const
  SIGNATURE = $38425053;    // 8BPS
  BLOCK_8BIM = $3842494D;   // 8BIM
  BLOCK_8B64 = $38423634;   // 8B64
  KEY_LR16 = $4C723136;     // Lr16
  KEY_LR32 = $4C723332;     // Lr32
  KEY_LAYR = $4C617972;     // Layr
var
  Stream: TFileStream;
  Version, LengthSize: Integer;
  SectionEnd, InfoLength, BlockLength, Key: Int64;
  LongKeys: TArray<Int64>;
  IsLong: Boolean;
begin
  Result := maNotLayered;
  try
    Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite);
    try
      if ReadBigEndian(Stream, 4) <> SIGNATURE then
        Exit;
      Result := maOpaque;
      Version := ReadBigEndian(Stream, 2);
      // A large document (version 2) has 8-byte section lengths
      if Version = 2 then
        LengthSize := 8
      else
        LengthSize := 4;
      // Reserved, channels, height, width, depth, colour mode
      Stream.Seek(Int64(6 + 2 + 4 + 4 + 2 + 2), soCurrent);
      // Colour mode data, then image resources
      Stream.Seek(ReadBigEndian(Stream, 4), soCurrent);
      Stream.Seek(ReadBigEndian(Stream, 4), soCurrent);
      // Layer and mask information
      SectionEnd := ReadBigEndian(Stream, LengthSize);
      if SectionEnd = 0 then
        Exit;
      SectionEnd := SectionEnd + Stream.Position;
      InfoLength := ReadBigEndian(Stream, LengthSize);
      if InfoLength > 0 then
      begin
        if SmallInt(ReadBigEndian(Stream, 2)) < 0 then
          Result := maTransparent;
        Exit;
      end;
      // No layer info here: at 16 and 32 bits a channel it is a tagged block,
      // after the global layer mask info
      Stream.Seek(ReadBigEndian(Stream, 4), soCurrent);
      // The keys whose lengths are 8 bytes in a large document: Lr16, Lr32,
      // Layr, LMsk, Mt16, Mt32, Mtrn, Alph, FMsk, lnk2, FEid, FXid, PxSD
      LongKeys := [KEY_LR16, KEY_LR32, KEY_LAYR, $4C4D736B, $4D743136, $4D743332,
        $4D74726E, $416C7068, $464D736B, $6C6E6B32, $46456964, $46586964, $50785344];
      while Stream.Position + 12 <= SectionEnd do
      begin
        Key := ReadBigEndian(Stream, 4);
        if (Key <> BLOCK_8BIM) and (Key <> BLOCK_8B64) then
          Exit;
        Key := ReadBigEndian(Stream, 4);
        IsLong := False;
        if Version = 2 then
          for var Each in LongKeys do
            if Each = Key then
              IsLong := True;
        if IsLong then
          BlockLength := ReadBigEndian(Stream, 8)
        else
          BlockLength := ReadBigEndian(Stream, 4);
        if (Key = KEY_LR16) or (Key = KEY_LR32) or (Key = KEY_LAYR) then
        begin
          if SmallInt(ReadBigEndian(Stream, 2)) < 0 then
            Result := maTransparent;
          Exit;
        end;
        Stream.Seek(BlockLength, soCurrent);
      end;
    finally
      Stream.Free;
    end;
  except
    // Unreadable as a layered image: what was found so far stands
  end;
end;

function LoaderReadsImage(const AFileName: String): Boolean;
var
  Ext: String;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.png') or (Ext = '.jpg') or (Ext = '.jpeg');
end;

type
  //** @abstract(A file's SHA-256 as ContentHash worked it out, with what told the file then.)
  TFileHash = record
    //** @abstract(The file's size then.)
    Size: Int64;
    //** @abstract(When it was last written then.)
    Written: TDateTime;
    //** @abstract(Its SHA-256, as 64 lower-case hex digits.)
    Sha: String;
  end;

var
  //** @abstract(The SHA-256 of every file ContentHash has worked one out for, by full path
  //** in upper case.)
  FileHashes: TDictionary<String, TFileHash>;

//** @abstract(The SHA-256 of file AFile's content, worked out again only if its size or
//** the time it was last written has changed since: a texture many models share is read
//** once.)
//**
//** @param(AFile The file.)
//**
//** @returns(Its SHA-256, as 64 lower-case hex digits.)
//**
//** @raises(Exception If it cannot be read.)
function ContentHash(const AFile: String): String;
var
  Key: String;
  Known: TFileHash;
  Size: Int64;
  Written: TDateTime;
begin
  if FileHashes = nil then
    FileHashes := TDictionary<String, TFileHash>.Create;
  Key := UpperCase(AFile);
  Size := TFile.GetSize(AFile);
  Written := TFile.GetLastWriteTime(AFile);
  if FileHashes.TryGetValue(Key, Known) and (Known.Size = Size) and
    (Known.Written = Written) then
    Exit(Known.Sha);
  Result := LowerCase(THashSHA2.GetHashStringFromFile(AFile,
    THashSHA2.TSHA2Version.SHA256));
  Known.Size := Size;
  Known.Written := Written;
  Known.Sha := Result;
  FileHashes.AddOrSetValue(Key, Known);
end;

//** @abstract(Makes image file ASource a PNG in AFolder, 8 bits a channel with alpha, named
//** after the SHA-256 of ASource; one made before is used again.)
//**
//** Its alpha is the image's, but for a layered image file whose merged image is opaque
//** (MergedAlpha), whose extra channel the image library would take for alpha: there it
//** is 255 throughout. It always has an alpha channel, as FMX's OpenGL context cannot make
//** a texture from a 24-bit PNG.
//**
//** @param(ASource The image.)
//**
//** @param(AFolder The folder of models' copies.)
//**
//** @param(APng On return, the PNG; empty if it could not be made.)
//**
//** @param(AReason On return, why it could not be made; empty if it was.)
//**
//** @returns(True if the PNG is there.)
function MakePng(const ASource, AFolder: String; out APng, AReason: String): Boolean;
var
  Image: TImageData;
  Target, Temp: String;
begin
  Result := False;
  APng := String.Empty;
  AReason := String.Empty;
  try
    Target := TPath.Combine(AFolder, ContentHash(ASource) + MADE_PNG_VERSION + '.png');
    if TFile.Exists(Target) then
    begin
      APng := Target;
      Exit(True);
    end;
    ForceDirectories(AFolder);
    InitImage(Image);
    try
      if not LoadImageFromFile(ASource, Image) then
      begin
        AReason := 'the image library can''t read it';
        Exit;
      end;
      // Opaque if the layered image file says its merged image is: through
      // 24 bits, which drops the extra channels; the image library gives
      // alpha 255 on the way back
      if (MergedAlpha(ASource) = maOpaque) and not ConvertImage(Image, ifR8G8B8) then
      begin
        AReason := 'the image library can''t convert it to 24 bits';
        Exit;
      end;
      // Always 8 bits a channel with alpha: FMX's OpenGL context cannot make
      // a texture from a 24-bit PNG (error 1282)
      if not ConvertImage(Image, ifA8R8G8B8) then
      begin
        AReason := 'the image library can''t convert it to 8 bits a channel';
        Exit;
      end;
      // Written whole, then moved into place; the extension says PNG
      Temp := ChangeFileExt(Target, '.tmp.png');
      if not SaveImageToFile(Temp, Image) then
      begin
        AReason := 'can''t write ' + Temp;
        Exit;
      end;
      if TFile.Exists(Target) then
        TFile.Delete(Target);
      TFile.Move(Temp, Target);
      APng := Target;
      Result := True;
    finally
      FreeImage(Image);
    end;
  except
    on E: Exception do
    begin
      APng := String.Empty;
      AReason := E.Message;
      Result := False;
    end;
  end;
end;

//** @abstract(Copies AFile into AFolder, named after the SHA-256 of its content with its
//** own extension in lower case, unless it is there already.)
//**
//** @param(AFile The file.)
//**
//** @param(AFolder The folder of models' copies.)
//**
//** @returns(The copy's name, without its folder, as the copy's uri.)
//**
//** @raises(Exception If AFile cannot be read or the copy written.)
function CopyIn(const AFile, AFolder: String): String;
var
  Target, Temp: String;
begin
  // A file in the folder already, such as a PNG made, is named as it is
  if SameText(ExcludeTrailingPathDelimiter(ExtractFileDir(AFile)),
    ExcludeTrailingPathDelimiter(AFolder)) then
    Exit(ExtractFileName(AFile));
  Result := ContentHash(AFile) + LowerCase(ExtractFileExt(AFile));
  Target := TPath.Combine(AFolder, Result);
  if TFile.Exists(Target) then
    Exit;
  ForceDirectories(AFolder);
  // Written whole, then moved into place
  Temp := Target + '.tmp';
  TFile.Copy(AFile, Temp, True);
  TFile.Move(Temp, Target);
end;

//** @abstract(Where an extension comes in the search for a texture of the same name: PNG,
//** then JPEG, then the rest.)
//**
//** @param(AFileName The file.)
//**
//** @returns(0 for PNG, 1 for JPEG, 2 for any other.)
function ExtensionRank(const AFileName: String): Integer;
var
  Ext: String;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if Ext = '.png' then
    Result := 0
  else if (Ext = '.jpg') or (Ext = '.jpeg') then
    Result := 1
  else
    Result := 2;
end;

type
  //** @abstract(The files in a folder, or in a folder and every folder below it, as
  //** FolderListing keeps them, with indexes to find them by name.)
  TFolderListing = class
  public
    //** @abstract(The files, as full paths.)
    Files: TArray<String>;
    //** @abstract(The files by their name, in upper case.)
    ByName: TDictionary<String, TArray<String>>;
    //** @abstract(The image files (IsImageFile) by their name without its extension, in
    //** upper case.)
    ByBase: TDictionary<String, TArray<String>>;
    //** @abstract(When it was made, from TThread.GetTickCount64, in milliseconds.)
    Taken: UInt64;
    //** @abstract(Makes the empty indexes.)
    constructor Create;
    //** @abstract(Frees the indexes.)
    destructor Destroy; override;
    //** @abstract(Adds AFile to Files and to the indexes.)
    //**
    //** @param(AFile The file, as a full path.)
    procedure Add(const AFile: String);
  end;

var
  //** @abstract(The listings made in the last LISTING_KEEP_MS, by folder in upper case,
  //** with @code(*) after it for a whole tree; see FolderListing. Owns them.)
  Listings: TObjectDictionary<String, TFolderListing>;
  //** @abstract(Whether each extension, in lower case, is an image's; see IsImageFile.)
  ImageExtensions: TDictionary<String, Boolean>;

//** @abstract(Whether AFileName could be a texture: an image the loader or the image
//** library reads, judged by its extension, and worked out once for each extension.)
//**
//** @param(AFileName The file.)
//**
//** @returns(True if so.)
function IsImageFile(const AFileName: String): Boolean;
var
  Ext: String;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if ImageExtensions = nil then
    ImageExtensions := TDictionary<String, Boolean>.Create;
  if not ImageExtensions.TryGetValue(Ext, Result) then
  begin
    Result := (Ext <> String.Empty) and
      (LoaderReadsImage(AFileName) or IsFileFormatSupported(AFileName));
    ImageExtensions.Add(Ext, Result);
  end;
end;

constructor TFolderListing.Create;
begin
  inherited Create;
  ByName := TDictionary<String, TArray<String>>.Create;
  ByBase := TDictionary<String, TArray<String>>.Create;
end;

destructor TFolderListing.Destroy;
begin
  ByName.Free;
  ByBase.Free;
  inherited;
end;

procedure TFolderListing.Add(const AFile: String);
var
  Key: String;
  Found: TArray<String>;
begin
  Files := Files + [AFile];
  Key := UpperCase(ExtractFileName(AFile));
  if not ByName.TryGetValue(Key, Found) then
    Found := nil;
  ByName.AddOrSetValue(Key, Found + [AFile]);
  if IsImageFile(AFile) then
  begin
    Key := UpperCase(ChangeFileExt(ExtractFileName(AFile), String.Empty));
    if not ByBase.TryGetValue(Key, Found) then
      Found := nil;
    ByBase.AddOrSetValue(Key, Found + [AFile]);
  end;
end;

//** @abstract(The files in AFolder, or in it and every folder below it if ATree, indexed,
//** from a listing made in the last LISTING_KEEP_MS if there is one.)
//**
//** A tree with more than TREE_FILE_LIMIT files, of any kind, is not listed, so a search
//** that goes too high gives up rather than read a whole disk.
//**
//** @param(AFolder The folder.)
//**
//** @param(ATree True for every folder below it too.)
//**
//** @returns(The listing, which is not the caller's; empty if there are no files, the
//** folder is not there, or the tree is too big.)
function FolderListing(const AFolder: String; const ATree: Boolean): TFolderListing;
var
  Key, Folder: String;
  Found: TList<String>;
  Pending: TQueue<String>;
  Seen: Integer;
begin
  Key := UpperCase(ExcludeTrailingPathDelimiter(AFolder));
  if ATree then
    Key := Key + '*';
  if Listings = nil then
    Listings := TObjectDictionary<String, TFolderListing>.Create([doOwnsValues]);
  if Listings.TryGetValue(Key, Result) and
    (TThread.GetTickCount64 - Result.Taken < LISTING_KEEP_MS) then
    Exit;
  Found := TList<String>.Create;
  Pending := TQueue<String>.Create;
  try
    Seen := 0;
    if TDirectory.Exists(AFolder) then
      Pending.Enqueue(AFolder);
    while Pending.Count > 0 do
    begin
      Folder := Pending.Dequeue;
      try
        for var Each in TDirectory.GetFiles(Folder) do
        begin
          Inc(Seen);
          if Seen > TREE_FILE_LIMIT then
          begin
            Found.Clear;
            Pending.Clear;
            Break;
          end;
          Found.Add(Each);
        end;
        if ATree and (Seen <= TREE_FILE_LIMIT) then
          for var Each in TDirectory.GetDirectories(Folder) do
            Pending.Enqueue(Each);
      except
        // A folder that cannot be read is passed over
      end;
    end;
    Result := TFolderListing.Create;
    for var Each in Found do
      Result.Add(Each);
  finally
    Pending.Free;
    Found.Free;
  end;
  Result.Taken := TThread.GetTickCount64;
  Listings.AddOrSetValue(Key, Result);
end;

//** @abstract(How many path delimiters AFileName has: how deep it is.)
//**
//** @param(AFileName The file.)
//**
//** @returns(The count.)
function FolderDepth(const AFileName: String): Integer;
begin
  Result := 0;
  for var C in AFileName do
    if C = PathDelim then
      Inc(Result);
end;

//** @abstract(Whether AFolder is a disk's root, or a folder directly in it, which a
//** search never goes up to.)
//**
//** @param(AFolder The folder.)
//**
//** @returns(True if so.)
function TooHighToSearch(const AFolder: String): Boolean;
var
  Parent: String;
begin
  Parent := ExtractFileDir(ExcludeTrailingPathDelimiter(AFolder));
  Result := (Parent = String.Empty) or
    SameText(ExcludeTrailingPathDelimiter(Parent), ExcludeTrailingPathDelimiter(AFolder)) or
    SameText(IncludeTrailingPathDelimiter(Parent), TPath.GetPathRoot(AFolder));
  if not Result then
    Result := SameText(IncludeTrailingPathDelimiter(ExcludeTrailingPathDelimiter(AFolder)),
      TPath.GetPathRoot(AFolder));
end;

//** @abstract(Where a file a model names is looked for, nearest first: the folder named
//** and the model's folder, then the tree of each of the model's folder's parents up to
//** SEARCH_LEVELS_UP, but none that is TooHighToSearch.)
//**
//** @param(AModelFolder The model's folder.)
//**
//** @param(ANamed The file named, as a full path.)
//**
//** @param(APlaces On return, the folders.)
//**
//** @param(ATrees On return, for each folder, True if every folder below it counts too.)
procedure SearchPlaces(const AModelFolder, ANamed: String; out APlaces: TArray<String>;
  out ATrees: TArray<Boolean>);
var
  Folder, Upper: String;
begin
  APlaces := [ExcludeTrailingPathDelimiter(ExtractFileDir(ANamed))];
  ATrees := [False];
  if not SameText(APlaces[0], ExcludeTrailingPathDelimiter(AModelFolder)) then
  begin
    APlaces := APlaces + [ExcludeTrailingPathDelimiter(AModelFolder)];
    ATrees := ATrees + [False];
  end;
  Folder := ExcludeTrailingPathDelimiter(AModelFolder);
  for var Level := 1 to SEARCH_LEVELS_UP do
  begin
    Upper := ExtractFileDir(Folder);
    if (Upper = String.Empty) or SameText(Upper, Folder) or TooHighToSearch(Upper) then
      Break;
    Folder := Upper;
    APlaces := APlaces + [Folder];
    ATrees := ATrees + [True];
  end;
end;

//** @abstract(The image files in one of SearchPlaces' places with ANamed's name, nearest
//** first.)
//**
//** If AExactName, only files with ANamed's file name, case ignored; if not, only those
//** with its name but another extension. The nearer file, by fewer folders between, comes
//** first, then PNG, then JPEG, then the rest, then name order.
//**
//** @param(AListing The place's listing, from FolderListing.)
//**
//** @param(ANamed The texture named, as a full path.)
//**
//** @param(AExactName True for its own file name; False for its name with any other
//** extension.)
//**
//** @returns(The files, as full paths.)
function PlaceMatches(const AListing: TFolderListing; const ANamed: String;
  const AExactName: Boolean): TArray<String>;
var
  FileName: String;
  Found: TArray<String>;
begin
  Result := nil;
  FileName := ExtractFileName(ANamed);
  if AExactName then
  begin
    if AListing.ByName.TryGetValue(UpperCase(FileName), Found) then
      for var Each in Found do
        if IsImageFile(Each) then
          Result := Result + [Each];
  end
  else if AListing.ByBase.TryGetValue(UpperCase(ChangeFileExt(FileName, String.Empty)),
    Found) then
    for var Each in Found do
      if not SameText(ExtractFileName(Each), FileName) then
        Result := Result + [Each];
  TArray.Sort<String>(Result, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := FolderDepth(A) - FolderDepth(B);
      if Result = 0 then
        Result := ExtensionRank(A) - ExtensionRank(B);
      if Result = 0 then
        Result := CompareText(A, B);
    end));
end;

//** @abstract(Readies image file ACandidate in place of the one named: used as it is if the
//** loader reads it, else made a PNG.)
//**
//** @param(ACandidate The file.)
//**
//** @param(AFolder The folder of models' copies.)
//**
//** @param(AFix What is known of the texture; filled in if ACandidate can be used.)
//**
//** @returns(True if it can.)
function UseCandidate(const ACandidate, AFolder: String; var AFix: TSprite3DTextureFix): Boolean;
var
  Png, Why: String;
begin
  Result := True;
  if LoaderReadsImage(ACandidate) then
  begin
    AFix.Outcome := toOtherFile;
    AFix.Used := ACandidate;
    Exit;
  end;
  if MakePng(ACandidate, AFolder, Png, Why) then
  begin
    AFix.Outcome := toOtherFileConverted;
    AFix.Used := Png;
    AFix.Source := ACandidate;
    Exit;
  end;
  Result := False;
end;

//** @abstract(AName without one number at its end and the separator before it, such as
//** the @code(_001) or @code(.001) a modelling program adds to a name it has seen before.)
//**
//** @param(AName A file's name without its extension.)
//**
//** @returns(The name without them; AName if it has none.)
function WithoutCopyNumber(const AName: String): String;
var
  At: Integer;
begin
  Result := AName;
  At := Length(AName);
  while (At >= 1) and CharInSet(AName[At], ['0'..'9']) do
    Dec(At);
  if (At >= 2) and (At < Length(AName)) and CharInSet(AName[At], ['_', '.', '-', ' ']) then
    Result := Copy(AName, 1, At - 1);
end;

//** @abstract(Whether file AFile is ALength bytes long, or ALength is not known.)
//**
//** @param(AFile The file.)
//**
//** @param(ALength The length the model gives; 0 or less for none.)
//**
//** @returns(True if it fits.)
function LengthFits(const AFile: String; const ALength: Int64): Boolean;
begin
  if ALength <= 0 then
    Exit(True);
  try
    Result := TFile.GetSize(AFile) = ALength;
  except
    Result := False;
  end;
end;

//** @abstract(Finds a buffer a glTF names that is not where it says.)
//**
//** Only a file of the length the model gives (@code(byteLength)) can be it. First the
//** name as given, case ignored, nearest first in SearchPlaces' places; then, in the folder
//** named and the model's, a file with the same extension named as the model (a buffer is
//** usually named after its model), or as the name given without its copy number
//** (WithoutCopyNumber), which a modelling program can add on export.
//**
//** @param(AModelFile The model, as a full path.)
//**
//** @param(AUri The buffer's uri, as the model gives it.)
//**
//** @param(ALength The buffer's length, from its @code(byteLength); 0 or less for none.)
//**
//** @returns(What was done with it: toAsNamed if it is there, toOtherFile if another was
//** found, else toMissing; IsBuffer is set.)
function ResolveBuffer(const AModelFile, AUri: String; const ALength: Int64):
  TSprite3DTextureFix;
var
  ModelFolder, Named, FileName, Ext, ModelBase, Stripped, Base: String;
  Places: TArray<String>;
  Trees: TArray<Boolean>;
  Matches, Found: TArray<String>;
begin
  Result := Default(TSprite3DTextureFix);
  Result.Named := AUri;
  Result.IsBuffer := True;
  Result.Outcome := toMissing;
  ModelFolder := ExtractFilePath(AModelFile);
  Named := OSFriendlyPath(TPath.Combine(ModelFolder, TNetEncoding.URL.Decode(AUri)));
  if TFile.Exists(Named) then
  begin
    Result.Outcome := toAsNamed;
    Exit;
  end;
  Result.Reason := ExtractFileName(Named) + ' is not there';
  FileName := ExtractFileName(Named);
  Ext := ExtractFileExt(FileName);
  SearchPlaces(ModelFolder, Named, Places, Trees);

  // The name as given, of the right length, nearest first
  for var I := 0 to High(Places) do
  begin
    Matches := nil;
    if FolderListing(Places[I], Trees[I]).ByName.TryGetValue(UpperCase(FileName), Found) then
      for var Each in Found do
        if LengthFits(Each, ALength) then
          Matches := Matches + [Each];
    TArray.Sort<String>(Matches, TComparer<String>.Construct(
      function(const A, B: String): Integer
      begin
        Result := FolderDepth(A) - FolderDepth(B);
        if Result = 0 then
          Result := CompareText(A, B);
      end));
    if Length(Matches) > 0 then
    begin
      Result.Outcome := toOtherFile;
      Result.Used := Matches[0];
      Exit;
    end;
  end;

  // Beside it, named as the model, or without the copy number
  ModelBase := ChangeFileExt(ExtractFileName(AModelFile), String.Empty);
  Stripped := WithoutCopyNumber(ChangeFileExt(FileName, String.Empty));
  for var I := 0 to High(Places) do
  begin
    if Trees[I] then
      Break;
    for var Pass := 0 to 1 do
      for var Each in FolderListing(Places[I], False).Files do
      begin
        if not SameText(ExtractFileExt(Each), Ext) then
          Continue;
        Base := ChangeFileExt(ExtractFileName(Each), String.Empty);
        if (((Pass = 0) and SameText(Base, ModelBase)) or
          ((Pass = 1) and SameText(Base, Stripped))) and LengthFits(Each, ALength) then
        begin
          Result.Outcome := toOtherFile;
          Result.Used := Each;
          Exit;
        end;
      end;
  end;
end;

//** @abstract(AName without an image file's extension at its end, after an underscore,
//** dot, hyphen or space, as an exporter can leave when it names a texture after its file:
//** @code(T_Wall_png) for @code(T_Wall).)
//**
//** @param(AName A file's name without its extension.)
//**
//** @returns(The name without it; AName if it has none.)
function WithoutNamedExtension(const AName: String): String;
var
  At: Integer;
begin
  Result := AName;
  At := AName.LastDelimiter('_.- ');
  if (At > 0) and (At < AName.Length - 1) and IsImageFile('x.' + AName.Substring(At + 1)) then
    Result := AName.Substring(0, At);
end;

//** @abstract(The image files in one of SearchPlaces' places named ABase with any extension,
//** case ignored, nearest first, then PNG, then JPEG, then the rest.)
//**
//** @param(AListing The place's listing, from FolderListing.)
//**
//** @param(ABase The name, without an extension.)
//**
//** @returns(The files, as full paths.)
function PlaceBaseMatches(const AListing: TFolderListing; const ABase: String):
  TArray<String>;
begin
  if not AListing.ByBase.TryGetValue(UpperCase(ABase), Result) then
    Exit(nil);
  TArray.Sort<String>(Result, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := FolderDepth(A) - FolderDepth(B);
      if Result = 0 then
        Result := ExtensionRank(A) - ExtensionRank(B);
      if Result = 0 then
        Result := CompareText(A, B);
    end));
end;

//** @abstract(The placeholder texture, PLACEHOLDER_FILE_NAME in AFolder, made if it is not
//** there: 16 pixels square, magenta and black in squares of 8.)
//**
//** @param(AFolder The folder of models' copies.)
//**
//** @returns(Its full path; empty if it could not be made.)
function PlaceholderTexture(const AFolder: String): String;
var
  Image: TImageData;
  Pixel: PCardinal;
  Temp: String;
begin
  Result := TPath.Combine(AFolder, PLACEHOLDER_FILE_NAME);
  if TFile.Exists(Result) then
    Exit;
  try
    ForceDirectories(AFolder);
    InitImage(Image);
    try
      if not NewImage(16, 16, ifA8R8G8B8, Image) then
        Exit(String.Empty);
      Pixel := Image.Bits;
      for var Y := 0 to 15 do
        for var X := 0 to 15 do
        begin
          if ((X div 8) + (Y div 8)) mod 2 = 0 then
            Pixel^ := $FFFF00FF
          else
            Pixel^ := $FF000000;
          Inc(Pixel);
        end;
      Temp := ChangeFileExt(Result, '.tmp.png');
      if not SaveImageToFile(Temp, Image) then
        Exit(String.Empty);
      TFile.Move(Temp, Result);
    finally
      FreeImage(Image);
    end;
  except
    Result := String.Empty;
  end;
end;

//** @abstract(Finds and readies one texture, in the unit's order.)
//**
//** @param(AModelFolder The model's folder.)
//**
//** @param(AUri The texture's uri, as the model gives it.)
//**
//** @param(AFolder The folder of models' copies, where PNGs made go.)
//**
//** @returns(What was done with it.)
function ResolveTexture(const AModelFolder, AUri, AFolder: String): TSprite3DTextureFix;
var
  Named, Png, Why, Base: String;
  Places: TArray<String>;
  Trees: TArray<Boolean>;
  Tried: TDictionary<String, Boolean>;
begin
  Result := Default(TSprite3DTextureFix);
  Result.Named := AUri;
  Result.Outcome := toMissing;
  Named := OSFriendlyPath(TPath.Combine(AModelFolder, TNetEncoding.URL.Decode(AUri)));

  // The file named, in the format named, whenever it can be used
  if TFile.Exists(Named) then
  begin
    if LoaderReadsImage(Named) then
    begin
      Result.Outcome := toAsNamed;
      Exit;
    end;
    if MakePng(Named, AFolder, Png, Why) then
    begin
      Result.Outcome := toConverted;
      Result.Used := Png;
      Result.Source := Named;
      Exit;
    end;
    Result.Reason := ExtractFileName(Named) + ': ' + Why;
  end
  else
    Result.Reason := ExtractFileName(Named) + ' is not there';

  // Then the name as given elsewhere, nearest first, stopping at the first
  // place with one that can be used; only then the same name in another
  // format, so
  SearchPlaces(AModelFolder, Named, Places, Trees);
  Tried := TDictionary<String, Boolean>.Create;
  try
    // The file named itself has been tried
    Tried.Add(UpperCase(Named), True);
    for var Pass := 0 to 1 do
      for var I := 0 to High(Places) do
        for var Candidate in PlaceMatches(FolderListing(Places[I], Trees[I]), Named,
          Pass = 0) do
        begin
          if Tried.ContainsKey(UpperCase(Candidate)) then
            Continue;
          Tried.Add(UpperCase(Candidate), True);
          if UseCandidate(Candidate, AFolder, Result) then
            Exit;
        end;
    // Last, a name with an image's extension in it, as T_Wall_png.png for
    // T_Wall.png: without it, in the same places, nearest first
    Base := WithoutNamedExtension(ChangeFileExt(ExtractFileName(Named), String.Empty));
    if not SameText(Base, ChangeFileExt(ExtractFileName(Named), String.Empty)) then
      for var I := 0 to High(Places) do
        for var Candidate in PlaceBaseMatches(FolderListing(Places[I], Trees[I]), Base) do
        begin
          if Tried.ContainsKey(UpperCase(Candidate)) then
            Continue;
          Tried.Add(UpperCase(Candidate), True);
          if UseCandidate(Candidate, AFolder, Result) then
            Exit;
        end;
  finally
    Tried.Free;
  end;
end;

//** @abstract(Sets an image's or buffer's uri to AFile, a file name in the copy's folder,
//** and, for an image with a mimeType, the type of AFile.)
//**
//** @param(AItem The image or buffer.)
//**
//** @param(AFile The file's name.)
procedure SetUri(const AItem: TJSONObject; const AFile: String);
var
  Ext: String;
begin
  AItem.RemovePair('uri').Free;
  AItem.AddPair('uri', AFile);
  if AItem.GetValue('mimeType') <> nil then
  begin
    Ext := LowerCase(ExtractFileExt(AFile));
    AItem.RemovePair('mimeType').Free;
    if Ext = '.png' then
      AItem.AddPair('mimeType', 'image/png')
    else if (Ext = '.jpg') or (Ext = '.jpeg') then
      AItem.AddPair('mimeType', 'image/jpeg');
  end;
end;

//** @abstract(Whether AItem names a file by its uri, as opposed to holding its data or
//** naming none.)
//**
//** @param(AItem An element of images or buffers.)
//**
//** @param(AUri On return, the uri.)
//**
//** @returns(True if it names a file.)
function NamesFile(const AItem: TJSONValue; out AUri: String): Boolean;
begin
  Result := (AItem is TJSONObject) and TJSONObject(AItem).TryGetValue<String>('uri', AUri) and
    (AUri <> String.Empty) and not AUri.StartsWith('data:', True);
end;

function PrepareModelTextures(const AModelFile, ACacheFolder, AKey: String;
  out AFixes: TArray<TSprite3DTextureFix>): String;
var
  FileName, Folder, Models, Uri, Target, Temp: String;
  Root, Images, Buffers: TJSONValue;
  Fix: TSprite3DTextureFix;
  Used: TDictionary<TJSONObject, String>;
  Changed: Boolean;
  ByteLength: Int64;
begin
  Result := AModelFile;
  AFixes := nil;
  FileName := OSFriendlyPath(AModelFile);
  if not SameText(ExtractFileExt(FileName), '.gltf') then
    Exit;
  // One that cannot be read, or is not JSON, is the loader's to report
  try
    Root := TJSONObject.ParseJSONValue(TFile.ReadAllBytes(FileName), 0);
  except
    Root := nil;
  end;
  // The file each image is to name instead, by image
  Used := TDictionary<TJSONObject, String>.Create;
  try
    if not (Root is TJSONObject) then
      Exit;
    Folder := ExtractFilePath(FileName);
    Models := TPath.Combine(OSFriendlyPath(ACacheFolder), MODEL_FOLDER_NAME);
    Images := TJSONObject(Root).GetValue('images');
    Buffers := TJSONObject(Root).GetValue('buffers');
    Changed := False;
    if Images is TJSONArray then
      for var Item in TJSONArray(Images) do
        if NamesFile(Item, Uri) then
        begin
          Fix := ResolveTexture(Folder, Uri, Models);
          // One that cannot be found: the placeholder, so the model still
          // loads, its thumbnail showing where the texture is missing
          if Fix.Outcome = toMissing then
            Fix.Used := PlaceholderTexture(Models);
          AFixes := AFixes + [Fix];
          if Fix.Used <> String.Empty then
          begin
            Used.Add(TJSONObject(Item), Fix.Used);
            Changed := True;
          end;
        end;
    // Buffers that are not where the model says
    if Buffers is TJSONArray then
      for var Item in TJSONArray(Buffers) do
        if NamesFile(Item, Uri) then
        begin
          if not TJSONObject(Item).TryGetValue<Int64>('byteLength', ByteLength) then
            ByteLength := 0;
          Fix := ResolveBuffer(FileName, Uri, ByteLength);
          if Fix.Outcome = toAsNamed then
            Continue;
          AFixes := AFixes + [Fix];
          if Fix.Used <> String.Empty then
          begin
            Used.Add(TJSONObject(Item), Fix.Used);
            Changed := True;
          end;
        end;
    if not Changed then
      Exit;

    // The loader looks in the copy's own folder for every file it names,
    // so each one is copied there, under its content's name: the files
    // used in place of those named, then every other image and buffer
    if Images is TJSONArray then
      for var Item in TJSONArray(Images) do
        if NamesFile(Item, Uri) then
        begin
          if not Used.TryGetValue(TJSONObject(Item), Target) then
            Target := OSFriendlyPath(TPath.Combine(Folder, TNetEncoding.URL.Decode(Uri)));
          // One still missing keeps its name, for the loader to report
          if TFile.Exists(Target) then
            SetUri(TJSONObject(Item), CopyIn(Target, Models));
        end;
    if Buffers is TJSONArray then
      for var Item in TJSONArray(Buffers) do
        if NamesFile(Item, Uri) then
        begin
          if not Used.TryGetValue(TJSONObject(Item), Target) then
            Target := OSFriendlyPath(TPath.Combine(Folder, TNetEncoding.URL.Decode(Uri)));
          if TFile.Exists(Target) then
            SetUri(TJSONObject(Item), CopyIn(Target, Models));
        end;

    // Written whole, then moved into place
    Target := TPath.Combine(Models, AKey + '.gltf');
    ForceDirectories(Models);
    Temp := Target + '.tmp';
    TFile.WriteAllBytes(Temp, JsonToBytes(Root));
    if TFile.Exists(Target) then
      TFile.Delete(Target);
    TFile.Move(Temp, Target);
    Result := Target;
  finally
    Used.Free;
    Root.Free;
  end;
end;

initialization

finalization
  Listings.Free;
  ImageExtensions.Free;
  FileHashes.Free;

end.
