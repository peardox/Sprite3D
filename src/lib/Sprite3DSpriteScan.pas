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
    //** @abstract(Active as a share of the animation's content box, from 0 to 1; 0 until
    //** the whole folder has been measured, or if the box is empty.)
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
    //** @abstract(Whether the figures are good: True when Error is empty.)
    //** @returns(True if Error is empty.)
    function Valid: Boolean;
  end;

  //** @abstract(Asked between frames whether to stop scanning; True stops.)
  //** @returns(True to stop.)
  TSprite3DScanAborted = reference to function: Boolean;

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

// Works out the figures once every frame has been read: the size check,
// SpriteEmpty, the content box, and each frame's coverage with the least,
// mean and most
procedure Summarise(var AScan: TSprite3DSpriteScan);
var
  I: Integer;
  Empties: TArray<TSprite3DFrameEmpty>;
  Box: Int64;
  ActiveSum, CoverageSum: Double;
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
  // its empty border is cropped, so the frames' figures compare directly
  Box := Int64(AScan.ContentWidth) * AScan.ContentHeight;
  ActiveSum := 0;
  CoverageSum := 0;
  AScan.ActiveMin := High(Int64);
  AScan.ActiveMax := 0;
  AScan.CoverageMin := MaxDouble;
  AScan.CoverageMax := 0;
  for I := 0 to High(AScan.Frames) do
  begin
    AScan.Frames[I].Coverage := AScan.Frames[I].Active / Box;
    ActiveSum := ActiveSum + AScan.Frames[I].Active;
    CoverageSum := CoverageSum + AScan.Frames[I].Coverage;
    AScan.ActiveMin := Min(AScan.ActiveMin, AScan.Frames[I].Active);
    AScan.ActiveMax := Max(AScan.ActiveMax, AScan.Frames[I].Active);
    AScan.CoverageMin := Min(AScan.CoverageMin, AScan.Frames[I].Coverage);
    AScan.CoverageMax := Max(AScan.CoverageMax, AScan.Frames[I].Coverage);
  end;
  AScan.ActiveMean := ActiveSum / Length(AScan.Frames);
  AScan.CoverageMean := CoverageSum / Length(AScan.Frames);
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

end.
