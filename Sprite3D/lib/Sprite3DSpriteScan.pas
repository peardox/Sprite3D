//** @abstract(Measures sprites made elsewhere: the frames of an animation, one PNG per frame
//** in a folder, scanned for their empty borders and how much of them is drawn.)
//**
//** A sprite to be replaced by one of Sprite3D's comes as a folder of frames, one PNG file
//** each, and usually one folder for each animation or pose of the same character or asset.
//** ScanSpriteFolder reads every PNG in one folder (not its sub-folders) with LoadPng and
//** measures each frame exactly as an export's metadata does:
//**
//** @unorderedList(
//**   @item(its @bold(empty border), with MeasureFrameEmpty from Sprite3DSpriteSheet: the
//**     fully transparent columns and rows at each edge, alpha 0 only;)
//**   @item(its @bold(active pixels): every pixel that is not fully transparent, so the same
//**     test as the border.)
//** )
//**
//** The frames' borders are then combined as @code(sprite_empty) is, with LeastFrameEmpty:
//** the least of each side over every frame, so a crop by those four amounts holds all of
//** every frame. What is left is the @bold(content), the box the animation occupies, and each
//** frame's @bold(coverage) is its active pixels as a share of that box. The lowest, mean and
//** highest coverage over the frames are kept, for the caller to decide what to do with.
//**
//** The animations of one sprite are then combined with CombineSpriteScans, as an export's
//** @code(sprite_empty) is combined over every frame it made: the least of each side over
//** every animation gives one content box they all share, and every frame's coverage is
//** worked out again against that, so all the figures compare.
//**
//** ScanAtlas measures an atlas instead: one or more sheets, each a grid of frames of a
//** given size, every frame measured the same way. Frames with nothing drawn are unused
//** padding, counted but left out of the figures. ScanAtlasTree measures every copy of one
//** sheet in a folder tree, each variation an atlas of its own.
//**
//** SpriteFolders turns the folders a user chose into the folders to scan: a folder with no
//** PNG files of its own stands for those of its sub-folders that have some, so choosing a
//** character's folder scans each of its animations.
//**
//** Uses only the RTL, Sprite3DFileSearch, Sprite3DSpriteSheet and Sprite3DPngReader, and
//** knows nothing of the application. Safe on a worker thread.
//**
//** @preformatted(
//** chosen folders
//** `-- SpriteFolders          -> the folders holding frames
//**     `-- ScanSpriteFolder, each one
//**         |-- LoadPng, every *.png in it
//**         |-- MeasureFrameEmpty and CountActivePixels, each frame
//**         `-- LeastFrameEmpty, then the content box and coverage
//**                            -> TSprite3DSpriteScan, one per folder
//**             `-- CombineSpriteScans: the least of each side over them all,
//**                 every frame's coverage of that shared box
//**                            -> TSprite3DSpriteScan, Combined
//** )
unit Sprite3DSpriteScan;

{
  Measures sprites made elsewhere: the frames of an animation, one PNG per
  frame in a folder, scanned for their empty borders and how much of them is
  drawn.

  ScanSpriteFolder reads every PNG in one folder (not its sub-folders) with
  LoadPng and measures each frame as an export's metadata does: its empty
  border with MeasureFrameEmpty (alpha 0 only), and its active pixels, every
  pixel not fully transparent. The borders are combined as sprite_empty is,
  with LeastFrameEmpty, the least of each side over every frame. What is left
  is the content box the animation occupies, and each frame's coverage is
  its active pixels as a share of that box; the lowest, mean and highest are
  kept.

  CombineSpriteScans then takes the least of each side over every animation
  of the sprite, giving one content box they all share, and works every
  frame's coverage out again against that.

  ScanAtlas measures an atlas instead: one or more sheets, each a grid of
  frames of a given size, measured the same way; frames with nothing drawn
  are unused padding, counted but left out of the figures. ScanAtlasTree
  measures every copy of one sheet in a folder tree, each one an atlas.

  SpriteFolders turns the folders chosen into the folders to scan: a folder
  with no PNG files of its own stands for those of its sub-folders that have
  some.

  RTL, Sprite3DFileSearch, Sprite3DSpriteSheet and Sprite3DPngReader only.
  Safe on a worker thread.

    chosen folders
    `-- SpriteFolders          -> the folders holding frames
        `-- ScanSpriteFolder, each one
            |-- LoadPng, every *.png in it
            |-- MeasureFrameEmpty and CountActivePixels, each frame
            `-- LeastFrameEmpty, then the content box and coverage
                               -> TSprite3DSpriteScan, one per folder
                `-- CombineSpriteScans: the least of each side over them all,
                    every frame's coverage of that shared box
                               -> TSprite3DSpriteScan, Combined
}

interface

uses
  System.SysUtils, Sprite3DSpriteSheet;

const
  //** @abstract(The frames ScanSpriteFolder reads.)
  SPRITE_SCAN_FRAME_SPEC = '*.png';
  //** @abstract(Other image files that may sit among the frames; ScanSpriteFolder lists them
  //** as skipped, as it reads only PNG.)
  SPRITE_SCAN_OTHER_SPEC = '*.bmp;*.gif;*.jpg;*.jpeg;*.tga;*.tif;*.tiff;*.webp';
  //** @abstract(The Name CombineSpriteScans gives the scan of every animation together; in
  //** brackets, so no folder's own name is likely to match it.)
  SPRITE_SCAN_COMBINED_NAME = '(all animations)';

type
  //** @abstract(One frame as ScanSpriteFolder measured it.)
  TSprite3DScanFrame = record
    //** @abstract(The file's name, without its folder.)
    FileName: String;
    //** @abstract(The frame's width in pixels.)
    Width: Integer;
    //** @abstract(The frame's height in pixels.)
    Height: Integer;
    //** @abstract(Its empty border, as MeasureFrameEmpty gives it.)
    Empty: TSprite3DFrameEmpty;
    //** @abstract(How many of its pixels are not fully transparent.)
    Active: Int64;
    //** @abstract(Active as a share of the content box, from 0 to 1: the animation's own
    //** box, or after CombineSpriteScans the one every animation shares; 0 until the whole
    //** folder has been measured, or if the box is empty.)
    Coverage: Double;
  end;

  //** @abstract(One folder's frames, measured: one animation of a sprite.)
  //**
  //** When Error is empty the figures are good: every frame read is Width by Height, and
  //** SpriteEmpty, the content box and the coverage describe them all. Otherwise Error says
  //** why there are no figures, and only Name, Folder, Frames and Skipped are meaningful.
  TSprite3DSpriteScan = record
    //** @abstract(The folder's own name, without its path: the name the animation is known
    //** by.)
    Name: String;
    //** @abstract(The folder, as a full path.)
    Folder: String;
    //** @abstract(Every frame read, in file name order.)
    Frames: TArray<TSprite3DScanFrame>;
    //** @abstract(Files that were not read, each as its name, a colon and why.)
    Skipped: TArray<String>;
    //** @abstract(Why there are no figures; empty when there are.)
    Error: String;
    //** @abstract(The frames' width, the same for all.)
    Width: Integer;
    //** @abstract(The frames' height, the same for all.)
    Height: Integer;
    //** @abstract(The least empty border of each side over every frame, as an export's
    //** @code(sprite_empty) is worked out.)
    SpriteEmpty: TSprite3DFrameEmpty;
    //** @abstract(The width of the content box: Width less SpriteEmpty's Left and Right.)
    ContentWidth: Integer;
    //** @abstract(The height of the content box: Height less SpriteEmpty's Top and Bottom.)
    ContentHeight: Integer;
    //** @abstract(The fewest active pixels in any frame.)
    ActiveMin: Int64;
    //** @abstract(The mean of the frames' active pixels.)
    ActiveMean: Double;
    //** @abstract(The most active pixels in any frame.)
    ActiveMax: Int64;
    //** @abstract(The lowest coverage of any frame, from 0 to 1.)
    CoverageMin: Double;
    //** @abstract(The mean of the frames' coverage, from 0 to 1.)
    CoverageMean: Double;
    //** @abstract(The highest coverage of any frame, from 0 to 1.)
    CoverageMax: Double;
    //** @abstract(True when frames that should be the same size are not: the folder's own
    //** frames, or for CombineSpriteScans' result, any two frames of any of the folders.
    //** Error then names two that differ, and no figures can be worked out.)
    SizeMismatch: Boolean;
    //** @abstract(True for the scan CombineSpriteScans makes of every animation together;
    //** Folder is then empty and Frames holds every animation's frames.)
    Combined: Boolean;
    //** @abstract(The median of the frames' coverage, from 0 to 1: the middle one, or the
    //** mean of the middle two of an even number.)
    CoverageMedian: Double;
    //** @abstract(For ScanAtlas: how many sheets were read; 0 for a folder's scan.)
    SheetCount: Integer;
    //** @abstract(For ScanAtlas: how many cells of the sheets had nothing drawn in them,
    //** unused padding, left out of Frames and of every figure; 0 for a folder's scan.)
    UnusedFrames: Integer;
    //** @abstract(For ScanAtlas: the pixels of every sheet together, the sum of each sheet's
    //** width times its height; 0 for a folder's scan.)
    SheetPixels: Int64;
    //** @abstract(For ScanAtlas: the pixels of every sheet that are not fully transparent,
    //** the sum of every frame's Active; 0 for a folder's scan.)
    ActivePixels: Int64;
    //** @abstract(For ScanAtlas: the share of SheetPixels a perfect packing would save,
    //** from 0 to 1: @code(1 - ActivePixels / SheetPixels).)
    //**
    //** A perfect packing holds every pixel drawn and nothing else, as if the drawn pixels
    //** of every frame could be fitted together with no gap at all. No real packing gets
    //** there, as frames are packed as rectangles, but it is the limit any packing can
    //** approach; 0 for a folder's scan.
    PackingSaving: Double;
    //** @abstract(For ScanAtlas: the pixels of every used frame trimmed to its own tight
    //** box, the sum of each one's width less its Left and Right empty border times its
    //** height less its Top and Bottom; 0 for a folder's scan.)
    TrimmedPixels: Int64;
    //** @abstract(For ScanAtlas: the share of SheetPixels packing the trimmed frames would
    //** save, from 0 to 1: @code(1 - TrimmedPixels / SheetPixels).)
    //**
    //** What a rectangle packer could achieve with every frame trimmed to its own tight box
    //** and the boxes fitted together with no gap; a real packer leaves some, so it gets a
    //** little less. Each frame then needs its own offset, as each @code(frames[i].empty)
    //** of the metadata gives; 0 for a folder's scan.
    TrimSaving: Double;
    //** @abstract(Whether the figures are good: True when Error is empty.)
    //** @returns(True if Error is empty.)
    function Valid: Boolean;
  end;

  //** @abstract(Told as each sheet starts being read.)
  //** @param(AName The sheet's file name, without its folder.)
  //** @param(AIndex Which sheet it is, from 1.)
  //** @param(ACount How many sheets there are.)
  TSprite3DScanProgress = reference to procedure(const AName: String;
    const AIndex, ACount: Integer);

  //** @abstract(Asked between frames whether to stop scanning; True stops.)
  //** @returns(True to stop.)
  TSprite3DScanAborted = reference to function: Boolean;

//** @abstract(A scan with nothing in it: no frames, no figures, every number 0, every
//** flag False and every text empty.)
//**
//** The same as @code(Default@(TSprite3DSpriteScan@)), for units where another unit's
//** identifier hides that intrinsic: Gorilla.DefTypes has an enumeration value named
//** @code(Default).
//**
//** @returns(The empty scan.)
function EmptySpriteScan: TSprite3DSpriteScan;

//** @abstract(The name an animation is known by: a folder's own name, without its path.)
//**
//** A drive or file system root, which has no name of its own, is given whole.
//**
//** @param(AFolder The folder, as a full path, with or without a trailing delimiter.)
//**
//** @returns(Its last part, such as @code(walk) for @code(C:\Sprites\hero\walk).)
function SpriteFolderName(const AFolder: String): String;

//** @abstract(The folders to scan, from the folders a user chose.)
//**
//** A folder with at least one PNG file of its own is scanned itself. One without stands for
//** its sub-folders, one level down, that have some, in name order; sub-folders whose names
//** start with a dot are passed over. One with neither is kept, so its scan can say it has
//** no frames. Repeats are dropped, ignoring case.
//**
//** @param(AFolders The folders chosen, as full paths.)
//**
//** @returns(The folders to scan, as full paths, in order.)
function SpriteFolders(const AFolders: TArray<String>): TArray<String>;

//** @abstract(How many of a frame's pixels are not fully transparent.)
//**
//** The same test as MeasureFrameEmpty: alpha above 0, however faint.
//**
//** @param(AFrame The frame.)
//**
//** @returns(The count; 0 for a frame with nothing drawn.)
function CountActivePixels(const AFrame: TSprite3DImage): Int64;

//** @abstract(Combines the animations of one sprite: the least empty border of each side
//** over all of them, and every frame's coverage of the content box they then share.)
//**
//** Each side's border is the least of the animations' own @code(SpriteEmpty), so the least
//** over every frame of every animation, as an export's @code(sprite_empty) is over every
//** frame it made: cropped by it, every frame of every animation is the same size and loses
//** nothing. Every frame's coverage, and each animation's lowest, mean and highest, is then
//** worked out again against that shared content box, replacing what ScanSpriteFolder gave
//** against the animation's own box, so every figure compares with every other.
//**
//** Every frame of every folder must be the same size, or the borders cannot be compared
//** and nothing can be worked out: if a folder's own frames differ (its SizeMismatch), or
//** two folders' frames do, the result's SizeMismatch is True, its Error names two frames
//** that differ, and every scan keeps the figures it had. Scans without figures for any
//** other reason, such as a folder with no PNG files, take no part. Call it with a single
//** scan too: it then gives that scan's own border and box.
//**
//** @param(AScans The scans, as ScanSpriteFolder made them; their coverage is changed in
//** place.)
//**
//** @returns(The combined scan: Name SPRITE_SCAN_COMBINED_NAME, Combined True, the shared
//** border and content box, and the coverage of every frame of every animation; or, if the
//** frames differ in size, SizeMismatch True and Error saying which.)
function CombineSpriteScans(var AScans: TArray<TSprite3DSpriteScan>): TSprite3DSpriteScan;

//** @abstract(The name an atlas is known by, from its sheets' file names.)
//**
//** One sheet gives its name without the extension. Several give the start their names
//** share, less any digits, spaces, dots, dashes and underscores it ends with, so
//** @code(hero_atlas_01.png) and @code(hero_atlas_02.png) give @code(hero_atlas); if they
//** share nothing, the first sheet's name.
//**
//** @param(AFiles The sheets, as full paths.)
//**
//** @returns(The name; empty if there are no sheets.)
function AtlasScanName(const AFiles: TArray<String>): String;

//** @abstract(Reads and measures the sheets of one atlas: every frame of every sheet, as
//** ScanSpriteFolder measures a folder's frames.)
//**
//** Each sheet is a grid of frames of AFrameWidth by AFrameHeight, read left to right along
//** each row, then down. Its width and height must be whole numbers of frames; a sheet that
//** is not fails the scan (SizeMismatch True, Error saying which), as does a sheet that
//** cannot be read, as the figures would be wrong without it. Sheets may differ in size.
//**
//** Each frame is measured as MeasureFrameEmpty and CountActivePixels measure a frame of its
//** own. A frame with nothing drawn in it is unused padding: it is counted in UnusedFrames
//** and takes no other part. The rest are kept in Frames, each FileName giving the sheet
//** and its row and column from 1, such as @code(hero_atlas_01.png row 2 col 5). Their
//** borders are combined with LeastFrameEmpty into SpriteEmpty, and each one's coverage is
//** of the content box left once that is cropped, with the lowest, mean, median and
//** highest. SheetPixels and ActivePixels total the sheets' pixels and the drawn ones, and
//** PackingSaving is the share a perfect packing of the drawn pixels would save;
//** TrimmedPixels and TrimSaving the same for every frame trimmed to its own tight box.
//**
//** Only one sheet's pixels are held at a time.
//**
//** @param(AFiles The sheets, as full paths, in order.)
//**
//** @param(AFrameWidth The width of every frame, in pixels; at least 1.)
//**
//** @param(AFrameHeight The height of every frame, in pixels; at least 1.)
//**
//** @param(AAborted Asked before each sheet and each row of frames; True stops, leaving
//** Error saying so. May be nil.)
//**
//** @param(AProgress Told as each sheet starts. May be nil.)
//**
//** @returns(The atlas's frames and figures, Name from AtlasScanName, Width and Height the
//** frame size.)
function ScanAtlas(const AFiles: TArray<String>; const AFrameWidth, AFrameHeight: Integer;
  const AAborted: TSprite3DScanAborted;
  const AProgress: TSprite3DScanProgress): TSprite3DSpriteScan;

//** @abstract(The side of a square that would hold an atlas's trimmed frames packed with
//** no gap: the square root of TrimmedPixels, rounded up.)
//**
//** An estimate of the sheet a rectangle packer would need, as if the frames, each trimmed
//** to its own tight box, could fill a square exactly; a real packer needs a little more.
//**
//** @param(AAtlas The scan, from ScanAtlas.)
//**
//** @returns(The side in pixels; 0 if the scan has no frames.)
function AtlasPackedSide(const AAtlas: TSprite3DSpriteScan): Integer;

//** @abstract(Finds every copy of one sheet in a folder tree: each variation of an atlas,
//** one sheet per sub-folder.)
//**
//** The root and every sub-folder, however deep (up to MAX_FOLDER_DEPTH of
//** Sprite3DFileSearch), is searched for files named AFileName, ignoring case, in
//** FindFiles' order: a folder's own before its sub-folders', sub-folders in name order.
//**
//** @param(ARoot The folder to search, as a full path.)
//**
//** @param(AFileName The sheet's file name, such as @code(Spritesheet.png), without a
//** folder.)
//**
//** @returns(The sheets found, as full paths; empty if none, or if the root cannot be
//** read.)
function FindAtlasSheets(const ARoot, AFileName: String): TArray<String>;

//** @abstract(Where a file is below a root: its folder, relative to the root.)
//**
//** @param(ARoot The root, as a full path.)
//**
//** @param(AFile The file, as a full path, somewhere below the root.)
//**
//** @returns(The file's folder relative to the root, such as @code(hero\red); a single dot
//** for the root itself.)
function AtlasRelativeFolder(const ARoot, AFile: String): String;

//** @abstract(Measures every copy of one sheet in a folder tree, each as an atlas of its
//** own: one variation per sub-folder.)
//**
//** FindAtlasSheets finds the sheets, and each is measured with ScanAtlas, as a one-sheet
//** atlas. Each scan's Name is then the sheet's folder relative to the root
//** (AtlasRelativeFolder), and its Folder the folder in full, so rows can be told apart.
//** A sheet that fails, for instance by not being a whole number of frames, fails only
//** its own scan, whose Error says why; the rest go on.
//**
//** @param(ARoot The folder to search, as a full path.)
//**
//** @param(AFileName The sheet's file name, without a folder.)
//**
//** @param(AFrameWidth The width of every frame, in pixels.)
//**
//** @param(AFrameHeight The height of every frame, in pixels.)
//**
//** @param(AAborted Asked before each sheet and each row of frames; True stops, leaving
//** the scans so far. May be nil.)
//**
//** @param(AProgress Told as each sheet starts, with its relative folder. May be nil.)
//**
//** @returns(One scan per sheet found, in FindAtlasSheets' order; empty if none.)
function ScanAtlasTree(const ARoot, AFileName: String; const AFrameWidth,
  AFrameHeight: Integer; const AAborted: TSprite3DScanAborted;
  const AProgress: TSprite3DScanProgress): TArray<TSprite3DSpriteScan>;

//** @abstract(Reads and measures every PNG in one folder: one animation's frames.)
//**
//** The folder's PNG files are read in name order (ignoring case), not its sub-folders'. A
//** file that cannot be read is listed in Skipped with the reason, and the rest go on;
//** other image files (SPRITE_SCAN_OTHER_SPEC) are listed there too, as only PNG is read.
//** Each frame's pixels are let go as soon as it is measured, so a long animation at a large
//** size needs memory for one frame at a time.
//**
//** The figures are good only if at least one frame was read, every frame read is the same
//** size, and something is drawn in at least one; otherwise Error says which.
//**
//** @param(AFolder The folder, as a full path.)
//**
//** @param(AAborted Asked before each file; True stops, leaving Error saying so. May be nil.)
//**
//** @returns(The folder's frames and figures.)
function ScanSpriteFolder(const AFolder: String;
  const AAborted: TSprite3DScanAborted): TSprite3DSpriteScan;

implementation

uses
  System.Classes, System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  System.Math, Sprite3DFileSearch, Sprite3DPngReader;

function EmptySpriteScan: TSprite3DSpriteScan;
begin
  Result := Default(TSprite3DSpriteScan);
end;

function TSprite3DSpriteScan.Valid: Boolean;
begin
  Result := Error = String.Empty;
end;

function SpriteFolderName(const AFolder: String): String;
begin
  // ExcludeTrailingPathDelimiter turns C:\ into C:, which has no name of
  // its own; the root is given whole then
  Result := ExtractFileName(ExcludeTrailingPathDelimiter(AFolder));
  if Result = String.Empty then
    Result := AFolder;
end;

// Whether AFolder holds at least one frame file, not counting sub-folders.
// A folder that cannot be read has none.
function HasFrames(const AFolder: String): Boolean;
var
  Found: TList<String>;
begin
  Found := TList<String>.Create;
  try
    try
      Result := FindFiles(AFolder, SPRITE_SCAN_FRAME_SPEC, Found, False) > 0;
    except
      Result := False;
    end;
  finally
    Found.Free;
  end;
end;

// AFolder's sub-folders, one level down, in name order ignoring case,
// leaving out those whose names start with a dot. Empty if it cannot be
// read.
function SubFolders(const AFolder: String): TArray<String>;
var
  All: TArray<String>;
  Folder: String;
begin
  Result := nil;
  try
    All := TDirectory.GetDirectories(AFolder);
  except
    Exit;
  end;
  TArray.Sort<String>(All, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(SpriteFolderName(A), SpriteFolderName(B));
    end));
  for Folder in All do
    if not SpriteFolderName(Folder).StartsWith('.') then
      Result := Result + [Folder];
end;

function SpriteFolders(const AFolders: TArray<String>): TArray<String>;
var
  Kept: TArray<String>;

  // Adds AFolder to Kept unless it is there already, ignoring case
  procedure AddOnce(const AFolder: String);
  var
    Folder: String;
  begin
    for Folder in Kept do
      if SameText(ExcludeTrailingPathDelimiter(Folder),
        ExcludeTrailingPathDelimiter(AFolder)) then
        Exit;
    Kept := Kept + [AFolder];
  end;

var
  Folder, Sub: String;
  Any: Boolean;
begin
  Kept := nil;
  for Folder in AFolders do
  begin
    if HasFrames(Folder) then
    begin
      AddOnce(Folder);
      Continue;
    end;
    // No frames of its own: the sub-folders that have some, if any
    Any := False;
    for Sub in SubFolders(Folder) do
      if HasFrames(Sub) then
      begin
        AddOnce(Sub);
        Any := True;
      end;
    if not Any then
      AddOnce(Folder);
  end;
  Result := Kept;
end;

function CountActivePixels(const AFrame: TSprite3DImage): Int64;
var
  I, Count: NativeInt;
  Alpha: PByte;
begin
  Result := 0;
  Count := NativeInt(AFrame.Width) * AFrame.Height;
  if (Count <= 0) or (Length(AFrame.Pixels) < Count * 4) then
    Exit;
  Alpha := @AFrame.Pixels[3];
  for I := 0 to Count - 1 do
  begin
    if Alpha^ <> 0 then
      Inc(Result);
    Inc(Alpha, 4);
  end;
end;

// The files in AFolder matching ASpec, not its sub-folders, in name order;
// empty if it cannot be read
function FolderFiles(const AFolder, ASpec: String): TArray<String>;
var
  Found: TList<String>;
begin
  Found := TList<String>.Create;
  try
    FindFiles(AFolder, ASpec, Found, False);
    Result := Found.ToArray;
  finally
    Found.Free;
  end;
end;

procedure MeasureCoverage(var AScan: TSprite3DSpriteScan; const ABox: Int64); forward;

// Works out the figures once every frame has been read: the size check,
// SpriteEmpty, the content box, and each frame's coverage with the least,
// mean and most
procedure Summarise(var AScan: TSprite3DSpriteScan);
var
  I: Integer;
  Empties: TArray<TSprite3DFrameEmpty>;
begin
  if Length(AScan.Frames) = 0 then
  begin
    if Length(AScan.Skipped) = 0 then
      AScan.Error := 'No PNG files in the folder.'
    else
      AScan.Error := 'None of the image files in the folder could be read.';
    Exit;
  end;

  // Every frame must be the same size for the borders to be comparable
  AScan.Width := AScan.Frames[0].Width;
  AScan.Height := AScan.Frames[0].Height;
  for I := 1 to High(AScan.Frames) do
    if (AScan.Frames[I].Width <> AScan.Width) or (AScan.Frames[I].Height <> AScan.Height) then
    begin
      AScan.SizeMismatch := True;
      AScan.Error := Format('The frames differ in size: %s is %d x %d, %s is %d x %d.',
        [AScan.Frames[0].FileName, AScan.Width, AScan.Height, AScan.Frames[I].FileName,
        AScan.Frames[I].Width, AScan.Frames[I].Height]);
      Exit;
    end;

  // Combined as an export's sprite_empty is: the least of each side. A
  // frame with nothing drawn is empty right across, so it never lowers it
  SetLength(Empties, Length(AScan.Frames));
  for I := 0 to High(AScan.Frames) do
    Empties[I] := AScan.Frames[I].Empty;
  AScan.SpriteEmpty := LeastFrameEmpty(Empties);
  AScan.ContentWidth := AScan.Width - AScan.SpriteEmpty.Left - AScan.SpriteEmpty.Right;
  AScan.ContentHeight := AScan.Height - AScan.SpriteEmpty.Top - AScan.SpriteEmpty.Bottom;
  if (AScan.ContentWidth <= 0) or (AScan.ContentHeight <= 0) then
  begin
    AScan.ContentWidth := 0;
    AScan.ContentHeight := 0;
    AScan.Error := 'Every frame is fully transparent.';
    Exit;
  end;

  // Coverage is of the shared content box, the size the animation takes once
  // its empty border is cropped, so the frames' figures compare directly.
  // CombineSpriteScans works it out again against the box every animation
  // shares
  MeasureCoverage(AScan, Int64(AScan.ContentWidth) * AScan.ContentHeight);
end;

// Each frame's coverage of a box of ABox pixels, and the least, mean and
// most of them and of the active pixels; ABox at least 1
procedure MeasureCoverage(var AScan: TSprite3DSpriteScan; const ABox: Int64);
var
  I, Middle: Integer;
  ActiveSum, CoverageSum: Double;
  Sorted: TArray<Double>;
begin
  ActiveSum := 0;
  CoverageSum := 0;
  AScan.ActiveMin := High(Int64);
  AScan.ActiveMax := 0;
  AScan.CoverageMin := MaxDouble;
  AScan.CoverageMax := 0;
  for I := 0 to High(AScan.Frames) do
  begin
    AScan.Frames[I].Coverage := AScan.Frames[I].Active / ABox;
    ActiveSum := ActiveSum + AScan.Frames[I].Active;
    CoverageSum := CoverageSum + AScan.Frames[I].Coverage;
    AScan.ActiveMin := Min(AScan.ActiveMin, AScan.Frames[I].Active);
    AScan.ActiveMax := Max(AScan.ActiveMax, AScan.Frames[I].Active);
    AScan.CoverageMin := Min(AScan.CoverageMin, AScan.Frames[I].Coverage);
    AScan.CoverageMax := Max(AScan.CoverageMax, AScan.Frames[I].Coverage);
  end;
  AScan.ActiveMean := ActiveSum / Length(AScan.Frames);
  AScan.CoverageMean := CoverageSum / Length(AScan.Frames);
  // The median: the middle value, or the mean of the middle two
  SetLength(Sorted, Length(AScan.Frames));
  for I := 0 to High(AScan.Frames) do
    Sorted[I] := AScan.Frames[I].Coverage;
  TArray.Sort<Double>(Sorted);
  Middle := Length(Sorted) div 2;
  if Odd(Length(Sorted)) then
    AScan.CoverageMedian := Sorted[Middle]
  else
    AScan.CoverageMedian := (Sorted[Middle - 1] + Sorted[Middle]) / 2;
end;

function ScanSpriteFolder(const AFolder: String;
  const AAborted: TSprite3DScanAborted): TSprite3DSpriteScan;
var
  Files, Others: TArray<String>;
  FileName: String;
  Frame: TSprite3DImage;
  Measured: TSprite3DScanFrame;
begin
  Result := Default(TSprite3DSpriteScan);
  Result.Folder := AFolder;
  Result.Name := SpriteFolderName(AFolder);
  if not TDirectory.Exists(AFolder) then
  begin
    Result.Error := 'The folder does not exist.';
    Exit;
  end;
  try
    Files := FolderFiles(AFolder, SPRITE_SCAN_FRAME_SPEC);
    Others := FolderFiles(AFolder, SPRITE_SCAN_OTHER_SPEC);
  except
    on E: Exception do
    begin
      Result.Error := 'The folder cannot be read: ' + E.Message;
      Exit;
    end;
  end;
  for FileName in Others do
    Result.Skipped := Result.Skipped + [ExtractFileName(FileName) +
      ': not a PNG; only PNG frames are read'];

  for FileName in Files do
  begin
    if Assigned(AAborted) and AAborted then
    begin
      Result.Error := 'Stopped before every frame was read.';
      Exit;
    end;
    try
      Frame := LoadPng(FileName);
    except
      on E: Exception do
      begin
        Result.Skipped := Result.Skipped + [ExtractFileName(FileName) + ': ' + E.Message];
        Continue;
      end;
    end;
    Measured := Default(TSprite3DScanFrame);
    Measured.FileName := ExtractFileName(FileName);
    Measured.Width := Frame.Width;
    Measured.Height := Frame.Height;
    Measured.Empty := MeasureFrameEmpty(Frame);
    Measured.Active := CountActivePixels(Frame);
    // The pixels are not kept: one frame's worth of memory at a time
    Frame.Pixels := nil;
    Result.Frames := Result.Frames + [Measured];
  end;
  Summarise(Result);
end;

function AtlasScanName(const AFiles: TArray<String>): String;
var
  Stem: String;
  I, Len: Integer;
begin
  Result := String.Empty;
  if Length(AFiles) = 0 then
    Exit;
  Result := ChangeFileExt(ExtractFileName(AFiles[0]), String.Empty);
  if Length(AFiles) = 1 then
    Exit;
  // The start every name shares, ignoring case
  for I := 1 to High(AFiles) do
  begin
    Stem := ChangeFileExt(ExtractFileName(AFiles[I]), String.Empty);
    Len := 0;
    while (Len < Length(Result)) and (Len < Length(Stem)) and
      SameText(Result.Chars[Len], Stem.Chars[Len]) do
      Inc(Len);
    Result := Result.Substring(0, Len);
  end;
  // Less the sheet numbers and the separators before them
  Result := Result.TrimRight(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '.',
    '-', '_']);
  if Result = String.Empty then
    Result := ChangeFileExt(ExtractFileName(AFiles[0]), String.Empty);
end;

// Measures the cell of AWidth by AHeight at (ALeft, ATop) of a sheet as
// MeasureFrameEmpty and CountActivePixels measure a frame: its empty border
// in the cell's own pixels, and how many of its pixels are not fully
// transparent. The cell must lie inside the sheet
procedure MeasureCell(const ASheet: TSprite3DImage; const ALeft, ATop, AWidth,
  AHeight: Integer; out AEmpty: TSprite3DFrameEmpty; out AActive: Int64);
var
  X, Y, MinX, MaxX, MinY, MaxY: Integer;
  Alpha: PByte;
begin
  MinX := AWidth;
  MaxX := -1;
  MinY := AHeight;
  MaxY := -1;
  AActive := 0;
  for Y := 0 to AHeight - 1 do
  begin
    Alpha := @ASheet.Pixels[((NativeInt(ATop + Y) * ASheet.Width) + ALeft) * 4 + 3];
    for X := 0 to AWidth - 1 do
    begin
      if Alpha^ <> 0 then
      begin
        Inc(AActive);
        if X < MinX then
          MinX := X;
        if X > MaxX then
          MaxX := X;
        if Y < MinY then
          MinY := Y;
        MaxY := Y;
      end;
      Inc(Alpha, 4);
    end;
  end;
  if MaxX < 0 then
  begin
    // Nothing drawn: empty from every side, as MeasureFrameEmpty gives it
    AEmpty.Left := AWidth;
    AEmpty.Right := AWidth;
    AEmpty.Top := AHeight;
    AEmpty.Bottom := AHeight;
  end
  else
  begin
    AEmpty.Left := MinX;
    AEmpty.Right := AWidth - 1 - MaxX;
    AEmpty.Top := MinY;
    AEmpty.Bottom := AHeight - 1 - MaxY;
  end;
end;

function ScanAtlas(const AFiles: TArray<String>; const AFrameWidth, AFrameHeight: Integer;
  const AAborted: TSprite3DScanAborted;
  const AProgress: TSprite3DScanProgress): TSprite3DSpriteScan;
var
  I, Row, Col, Cols, Rows: Integer;
  SheetName: String;
  Sheet: TSprite3DImage;
  Measured: TSprite3DScanFrame;
  Empties: TArray<TSprite3DFrameEmpty>;
begin
  Result := EmptySpriteScan;
  Result.Name := AtlasScanName(AFiles);
  Result.Width := AFrameWidth;
  Result.Height := AFrameHeight;
  if (AFrameWidth < 1) or (AFrameHeight < 1) then
  begin
    Result.Error := Format('The frame size, %d x %d, is not a size.',
      [AFrameWidth, AFrameHeight]);
    Exit;
  end;
  if Length(AFiles) = 0 then
  begin
    Result.Error := 'No sheets were given.';
    Exit;
  end;

  for I := 0 to High(AFiles) do
  begin
    SheetName := ExtractFileName(AFiles[I]);
    if Assigned(AAborted) and AAborted then
    begin
      Result.Error := 'Stopped before every sheet was read.';
      Exit;
    end;
    if Assigned(AProgress) then
      AProgress(SheetName, I + 1, Length(AFiles));
    // A sheet missing would leave the figures wrong, so it fails the scan
    try
      Sheet := LoadPng(AFiles[I]);
    except
      on E: Exception do
      begin
        Result.Error := SheetName + ' cannot be read: ' + E.Message;
        Exit;
      end;
    end;
    if (Sheet.Width mod AFrameWidth <> 0) or (Sheet.Height mod AFrameHeight <> 0) then
    begin
      Result.SizeMismatch := True;
      Result.Error := Format('%s is %d x %d, which is not a whole number of %d x %d ' +
        'frames.', [SheetName, Sheet.Width, Sheet.Height, AFrameWidth, AFrameHeight]);
      Exit;
    end;
    Inc(Result.SheetCount);
    Inc(Result.SheetPixels, Int64(Sheet.Width) * Sheet.Height);
    Cols := Sheet.Width div AFrameWidth;
    Rows := Sheet.Height div AFrameHeight;
    for Row := 0 to Rows - 1 do
    begin
      if Assigned(AAborted) and AAborted then
      begin
        Result.Error := 'Stopped before every sheet was read.';
        Exit;
      end;
      for Col := 0 to Cols - 1 do
      begin
        Measured := Default(TSprite3DScanFrame);
        MeasureCell(Sheet, Col * AFrameWidth, Row * AFrameHeight, AFrameWidth,
          AFrameHeight, Measured.Empty, Measured.Active);
        // Nothing drawn: padding, not a frame
        if Measured.Active = 0 then
        begin
          Inc(Result.UnusedFrames);
          Continue;
        end;
        Inc(Result.ActivePixels, Measured.Active);
        Inc(Result.TrimmedPixels, Int64(AFrameWidth - Measured.Empty.Left -
          Measured.Empty.Right) * (AFrameHeight - Measured.Empty.Top - Measured.Empty.Bottom));
        Measured.FileName := Format('%s row %d col %d', [SheetName, Row + 1, Col + 1]);
        Measured.Width := AFrameWidth;
        Measured.Height := AFrameHeight;
        Result.Frames := Result.Frames + [Measured];
      end;
    end;
    // One sheet's pixels at a time
    Sheet.Pixels := nil;
  end;

  if Length(Result.Frames) = 0 then
  begin
    Result.Error := 'Every frame of every sheet is empty.';
    Exit;
  end;
  // As over a folder's frames: the least of each side, then the box left
  SetLength(Empties, Length(Result.Frames));
  for I := 0 to High(Result.Frames) do
    Empties[I] := Result.Frames[I].Empty;
  Result.SpriteEmpty := LeastFrameEmpty(Empties);
  Result.ContentWidth := AFrameWidth - Result.SpriteEmpty.Left - Result.SpriteEmpty.Right;
  Result.ContentHeight := AFrameHeight - Result.SpriteEmpty.Top - Result.SpriteEmpty.Bottom;
  MeasureCoverage(Result, Int64(Result.ContentWidth) * Result.ContentHeight);
  // What packing every drawn pixel with no gap at all would save
  Result.PackingSaving := 1 - Result.ActivePixels / Result.SheetPixels;
  // What packing each frame trimmed to its own box, with no gap, would save
  Result.TrimSaving := 1 - Result.TrimmedPixels / Result.SheetPixels;
end;

function AtlasPackedSide(const AAtlas: TSprite3DSpriteScan): Integer;
begin
  if AAtlas.TrimmedPixels <= 0 then
    Exit(0);
  Result := Ceil(Sqrt(AAtlas.TrimmedPixels));
end;

function FindAtlasSheets(const ARoot, AFileName: String): TArray<String>;
var
  Found: TList<String>;
begin
  Result := nil;
  if (AFileName = String.Empty) or not TDirectory.Exists(ARoot) then
    Exit;
  Found := TList<String>.Create;
  try
    try
      FindFiles(ARoot, AFileName, Found, True);
    except
      // A root that cannot be read has no sheets
    end;
    Result := Found.ToArray;
  finally
    Found.Free;
  end;
end;

function AtlasRelativeFolder(const ARoot, AFile: String): String;
begin
  Result := ExcludeTrailingPathDelimiter(ExtractRelativePath(
    IncludeTrailingPathDelimiter(ARoot), IncludeTrailingPathDelimiter(ExtractFileDir(AFile))));
  if Result = String.Empty then
    Result := '.';
end;

function ScanAtlasTree(const ARoot, AFileName: String; const AFrameWidth,
  AFrameHeight: Integer; const AAborted: TSprite3DScanAborted;
  const AProgress: TSprite3DScanProgress): TArray<TSprite3DSpriteScan>;
var
  Sheets: TArray<String>;
  Scan: TSprite3DSpriteScan;
  Relative: String;
  I: Integer;
begin
  Result := nil;
  Sheets := FindAtlasSheets(ARoot, AFileName);
  for I := 0 to High(Sheets) do
  begin
    if Assigned(AAborted) and AAborted then
      Exit;
    Relative := AtlasRelativeFolder(ARoot, Sheets[I]);
    if Assigned(AProgress) then
      AProgress(Relative, I + 1, Length(Sheets));
    Scan := ScanAtlas([Sheets[I]], AFrameWidth, AFrameHeight, AAborted, nil);
    Scan.Name := Relative;
    Scan.Folder := ExtractFileDir(Sheets[I]);
    Result := Result + [Scan];
  end;
end;

function CombineSpriteScans(var AScans: TArray<TSprite3DSpriteScan>): TSprite3DSpriteScan;
var
  I, Used: Integer;
  Empties: TArray<TSprite3DFrameEmpty>;
  Box: Int64;
  FirstName: String;
begin
  Result := Default(TSprite3DSpriteScan);
  Result.Name := SPRITE_SCAN_COMBINED_NAME;
  Result.Combined := True;
  Used := 0;
  // Every frame of every folder must be the same size: one folder of mixed
  // sizes fails the whole scan
  for I := 0 to High(AScans) do
    if AScans[I].SizeMismatch then
    begin
      Result.SizeMismatch := True;
      Result.Error := AScans[I].Name + ': ' + AScans[I].Error;
      Exit;
    end;
  for I := 0 to High(AScans) do
  begin
    if not AScans[I].Valid then
      Continue;
    if Used = 0 then
    begin
      FirstName := AScans[I].Name + '/' + AScans[I].Frames[0].FileName;
      Result.Width := AScans[I].Width;
      Result.Height := AScans[I].Height;
    end
    else if (AScans[I].Width <> Result.Width) or (AScans[I].Height <> Result.Height) then
    begin
      // The borders of frames of different sizes cannot be compared, so
      // nothing can be worked out
      Result.SizeMismatch := True;
      Result.Error := Format('The frames differ in size: %s is %d x %d, %s/%s is %d x %d.',
        [FirstName, Result.Width, Result.Height, AScans[I].Name,
        AScans[I].Frames[0].FileName, AScans[I].Width, AScans[I].Height]);
      Result.Frames := nil;
      Exit;
    end;
    // The least of each side over every animation, exactly as over the
    // frames of one: the least of the least
    Empties := Empties + [AScans[I].SpriteEmpty];
    Result.Frames := Result.Frames + AScans[I].Frames;
    Inc(Used);
  end;
  if Used = 0 then
  begin
    Result.Error := 'No animation could be measured.';
    Exit;
  end;
  Result.SpriteEmpty := LeastFrameEmpty(Empties);
  Result.ContentWidth := Result.Width - Result.SpriteEmpty.Left - Result.SpriteEmpty.Right;
  Result.ContentHeight := Result.Height - Result.SpriteEmpty.Top - Result.SpriteEmpty.Bottom;
  // Each animation's own box lies inside this one, so it is never empty
  Box := Int64(Result.ContentWidth) * Result.ContentHeight;
  for I := 0 to High(AScans) do
    if AScans[I].Valid then
      MeasureCoverage(AScans[I], Box);
  MeasureCoverage(Result, Box);
end;

end.
