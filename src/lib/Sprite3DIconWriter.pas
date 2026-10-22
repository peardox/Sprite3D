//** @abstract(Writes sets of square images as icon files, starting with Windows .ico.)
//**
//** TSprite3DIconWriter is the base for icon formats: each descendant gives its format's
//** name, file extension and the image sizes it normally holds, and writes a set of FMX
//** bitmaps in that format. TSprite3DIcoWriter writes Windows icons. Every format is
//** registered at start-up with RegisterIconWriter, so a program can offer all of them, for
//** example as the file types of a save dialog, through IconWriters and IconDialogFilter;
//** adding a format, such as the macOS .icns format, needs only a new descendant and its
//** registration.
//**
//** The writers are plain Pascal over FMX bitmaps and streams, so they work the same on every
//** platform. They do not render anything; the images come from the caller, for example from
//** TSprite3DOffscreen.GrabSizes.
//**
//** @preformatted(
//** TSprite3DIconWriter @(abstract@)
//** `-- TSprite3DIcoWriter   Windows .ico: 16, 20, 24, 32, 40, 48, 64, 256, 32-bit
//** )
unit Sprite3DIconWriter;

{
  Writes sets of square images as icon files, starting with Windows .ico.

  TSprite3DIconWriter is the base for icon formats: each descendant gives
  its format's name, file extension and the image sizes it normally holds,
  and writes a set of FMX bitmaps in that format. TSprite3DIcoWriter writes
  Windows icons. Every format is registered at start-up with
  RegisterIconWriter, so a program can offer all of them, for example as the
  file types of a save dialog, through IconWriters and IconDialogFilter;
  adding a format, such as the macOS .icns format, needs only a new
  descendant and its registration.

  The writers are plain Pascal over FMX bitmaps and streams, so they work
  the same on every platform. They do not render anything; the images come
  from the caller, for example from TSprite3DOffscreen.GrabSizes.

    TSprite3DIconWriter (abstract)
    `-- TSprite3DIcoWriter   Windows .ico: 16, 20, 24, 32, 40, 48, 64, 256, 32-bit
}

interface

uses
  System.SysUtils, System.Classes, FMX.Graphics;

type
  //** @abstract(Base class for an icon file format.)
  //**
  //** A descendant overrides the class functions that describe its format and SaveToStream,
  //** which writes it. Create one writer per save; writers hold no state between saves
  //** unless a descendant adds options. For the main thread only, as FMX bitmaps are.
  /// <summary>Base class for an icon file format.</summary>
  /// <remarks>A descendant overrides the class functions that describe its format and
  /// SaveToStream, which writes it. Create one writer per save; writers hold no state between
  /// saves unless a descendant adds options. For the main thread only, as FMX bitmaps
  /// are.</remarks>
  TSprite3DIconWriter = class abstract
  public
    //** @abstract(Creates a writer with the format's default options.)
    /// <summary>Creates a writer with the format's default options.</summary>
    constructor Create; virtual;
    //** @abstract(The format's name for people, such as @code('Windows icon').)
    //**
    //** @returns(A short name, used in dialog filters.)
    /// <summary>The format's name for people, such as <c>'Windows icon'</c>.</summary>
    /// <returns>A short name, used in dialog filters.</returns>
    class function FormatName: String; virtual; abstract;
    //** @abstract(The format's file extension, with its dot, such as @code('.ico').)
    //**
    //** @returns(The extension, in lower case.)
    /// <summary>The format's file extension, with its dot, such as <c>'.ico'</c>.</summary>
    /// <returns>The extension, in lower case.</returns>
    class function FileExtension: String; virtual; abstract;
    //** @abstract(The image sizes, in pixels, a file of this format normally holds.)
    //**
    //** @returns(The widths, which are also the heights, smallest first.)
    /// <summary>The image sizes, in pixels, a file of this format normally holds.</summary>
    /// <returns>The widths, which are also the heights, smallest first.</returns>
    class function DefaultSizes: TArray<Integer>; virtual; abstract;
    //** @abstract(The format as one file type for a file dialog's Filter.)
    //**
    //** @returns(Such as @code('Windows icon @(*.ico@)|*.ico').)
    /// <summary>The format as one file type for a file dialog's Filter.</summary>
    /// <returns>Such as <c>'Windows icon (*.ico)|*.ico'</c>.</returns>
    class function DialogFilter: String;
    //** @abstract(AFileName with this format's extension, added or replacing another.)
    //**
    //** A name already ending in the extension, in any case, is returned unchanged.
    //**
    //** @param(AFileName A file name, with or without an extension.)
    //**
    //** @returns(The file name ending in FileExtension.)
    /// <summary>AFileName with this format's extension, added or replacing another.</summary>
    /// <remarks>A name already ending in the extension, in any case, is returned
    /// unchanged.</remarks>
    /// <param name="AFileName">A file name, with or without an extension.</param>
    /// <returns>The file name ending in FileExtension.</returns>
    class function FixFileName(const AFileName: String): String;
    //** @abstract(Writes the images to AStream in this format.)
    //**
    //** Blocks while writing. The images are not changed or freed.
    //**
    //** @param(AImages The images, each square; which sizes are allowed depends on the
    //** format.)
    //**
    //** @param(AStream The stream to write to, from its current position.)
    //**
    //** @raises(EArgumentException If there are no images, or one is not square or is a size
    //** the format cannot hold.)
    /// <summary>Writes the images to AStream in this format.</summary>
    /// <remarks>Blocks while writing. The images are not changed or freed.</remarks>
    /// <param name="AImages">The images, each square; which sizes are allowed depends on the
    /// format.</param>
    /// <param name="AStream">The stream to write to, from its current position.</param>
    /// <exception cref="EArgumentException">If there are no images, or one is not square or is
    /// a size the format cannot hold.</exception>
    procedure SaveToStream(const AImages: array of TBitmap; const AStream: TStream);
      virtual; abstract;
    //** @abstract(Writes the images to a file in this format.)
    //**
    //** Creates the file's folder if needed and replaces any existing file. Blocks while
    //** writing. If writing fails, the part-written file is deleted.
    //**
    //** @param(AImages The images, as for SaveToStream.)
    //**
    //** @param(AFileName The full path to write; it is used as given, so pass it through
    //** FixFileName first to be sure of the extension.)
    //**
    //** @raises(Exception If the images are unsuitable, as for SaveToStream, or the file
    //** cannot be written.)
    /// <summary>Writes the images to a file in this format.</summary>
    /// <remarks>Creates the file's folder if needed and replaces any existing file. Blocks
    /// while writing. If writing fails, the part-written file is deleted.</remarks>
    /// <param name="AImages">The images, as for SaveToStream.</param>
    /// <param name="AFileName">The full path to write; it is used as given, so pass it through
    /// FixFileName first to be sure of the extension.</param>
    /// <exception cref="Exception">If the images are unsuitable, as for SaveToStream, or the
    /// file cannot be written.</exception>
    procedure SaveToFile(const AImages: array of TBitmap; const AFileName: String);
  end;

  //** @abstract(A TSprite3DIconWriter descendant, for choosing a format at run time.)
  /// <summary>A TSprite3DIconWriter descendant, for choosing a format at run time.</summary>
  TSprite3DIconWriterClass = class of TSprite3DIconWriter;

  //** @abstract(Writes Windows .ico files.)
  //**
  //** Each image is stored with 32 bits per pixel: 8-bit blue, green, red and alpha.
  //** Images smaller than PngMinSize are stored as bitmaps, with the AND mask older readers
  //** need, and larger ones as PNG, which keeps the file small; this is how Windows 10 and 11
  //** store their own icons, with PNG only for 256. Images may be 1 to 256 pixels square.
  //** The default sizes are Windows 10 and 11's: 16, 20, 24, 32, 40, 48, 64 and 256.
  /// <summary>Writes Windows .ico files.</summary>
  /// <remarks>Each image is stored with 32 bits per pixel: 8-bit blue, green, red and alpha.
  /// Images smaller than PngMinSize are stored as bitmaps, with the AND mask older readers
  /// need, and larger ones as PNG, which keeps the file small; this is how Windows 10 and 11
  /// store their own icons, with PNG only for 256. Images may be 1 to 256 pixels square. The
  /// default sizes are Windows 10 and 11's: 16, 20, 24, 32, 40, 48, 64 and 256.</remarks>
  TSprite3DIcoWriter = class(TSprite3DIconWriter)
  private
    FPngMinSize: Integer;
    function BitmapEntry(const AImage: TBitmap): TBytes;
    function PngEntry(const AImage: TBitmap): TBytes;
  public
    //** @abstract(Creates a writer that stores 256-pixel images as PNG.)
    /// <summary>Creates a writer that stores 256-pixel images as PNG.</summary>
    constructor Create; override;
    //** @abstract(Returns @code('Windows icon').)
    //**
    //** @returns(@code('Windows icon').)
    /// <summary>Returns <c>'Windows icon'</c>.</summary>
    /// <returns><c>'Windows icon'</c>.</returns>
    class function FormatName: String; override;
    //** @abstract(Returns @code('.ico').)
    //**
    //** @returns(@code('.ico').)
    /// <summary>Returns <c>'.ico'</c>.</summary>
    /// <returns><c>'.ico'</c>.</returns>
    class function FileExtension: String; override;
    //** @abstract(Returns Windows 10 and 11's sizes: 16, 20, 24, 32, 40, 48, 64 and 256.)
    //**
    //** @returns(The eight sizes, smallest first.)
    /// <summary>Returns Windows 10 and 11's sizes: 16, 20, 24, 32, 40, 48, 64 and
    /// 256.</summary>
    /// <returns>The eight sizes, smallest first.</returns>
    class function DefaultSizes: TArray<Integer>; override;
    //** @abstract(Writes the images as one .ico file, in the order given.)
    //**
    //** @param(AImages One to 65535 images, each square and 1 to 256 pixels.)
    //**
    //** @param(AStream The stream to write to, from its current position.)
    //**
    //** @raises(EArgumentException If there are no images, too many, or one is not square or
    //** is larger than 256 pixels.)
    /// <summary>Writes the images as one .ico file, in the order given.</summary>
    /// <param name="AImages">One to 65535 images, each square and 1 to 256 pixels.</param>
    /// <param name="AStream">The stream to write to, from its current position.</param>
    /// <exception cref="EArgumentException">If there are no images, too many, or one is not
    /// square or is larger than 256 pixels.</exception>
    procedure SaveToStream(const AImages: array of TBitmap; const AStream: TStream); override;
    //** @abstract(The smallest image size stored as PNG; 256 by default.)
    //**
    //** Images this size or larger are stored as PNG, smaller ones as bitmaps. Set it above
    //** 256 to store every image as a bitmap, for the oldest readers, or lower to make the
    //** file smaller; Windows Vista and later read either.
    /// <summary>The smallest image size stored as PNG; 256 by default.</summary>
    /// <remarks>Images this size or larger are stored as PNG, smaller ones as bitmaps. Set it
    /// above 256 to store every image as a bitmap, for the oldest readers, or lower to make the
    /// file smaller; Windows Vista and later read either.</remarks>
    property PngMinSize: Integer read FPngMinSize write FPngMinSize;
  end;

//** @abstract(Adds an icon format to those IconWriters lists.)
//**
//** Call it from a writer unit's initialization section. Registering a class twice has no
//** further effect.
//**
//** @param(AWriter The writer class to add.)
/// <summary>Adds an icon format to those IconWriters lists.</summary>
/// <remarks>Call it from a writer unit's initialization section. Registering a class twice has
/// no further effect.</remarks>
/// <param name="AWriter">The writer class to add.</param>
procedure RegisterIconWriter(const AWriter: TSprite3DIconWriterClass);

//** @abstract(Every registered icon format, in the order registered.)
//**
//** @returns(The writer classes; TSprite3DIcoWriter is always first.)
/// <summary>Every registered icon format, in the order registered.</summary>
/// <returns>The writer classes; TSprite3DIcoWriter is always first.</returns>
function IconWriters: TArray<TSprite3DIconWriterClass>;

//** @abstract(A file dialog Filter offering every registered icon format.)
//**
//** The formats are in the order of IconWriters, so a dialog's FilterIndex, which counts
//** from 1, picks @code(IconWriters[FilterIndex - 1]).
//**
//** @returns(Such as @code('Windows icon @(*.ico@)|*.ico').)
/// <summary>A file dialog Filter offering every registered icon format.</summary>
/// <remarks>The formats are in the order of IconWriters, so a dialog's FilterIndex, which
/// counts from 1, picks <c>IconWriters[FilterIndex - 1]</c>.</remarks>
/// <returns>Such as <c>'Windows icon (*.ico)|*.ico'</c>.</returns>
function IconDialogFilter: String;

implementation

uses
  System.UITypes, System.Math, OSPaths;

var
  GIconWriters: TArray<TSprite3DIconWriterClass>;

procedure RegisterIconWriter(const AWriter: TSprite3DIconWriterClass);
var
  W: TSprite3DIconWriterClass;
begin
  for W in GIconWriters do
    if W = AWriter then
      Exit;
  GIconWriters := GIconWriters + [AWriter];
end;

function IconWriters: TArray<TSprite3DIconWriterClass>;
begin
  Result := Copy(GIconWriters);
end;

function IconDialogFilter: String;
var
  W: TSprite3DIconWriterClass;
begin
  Result := String.Empty;
  for W in GIconWriters do
  begin
    if Result <> String.Empty then
      Result := Result + '|';
    Result := Result + W.DialogFilter;
  end;
end;

// A square image's pixels, top row first, as blue, green, red, alpha bytes
// with straight (not premultiplied) alpha. FMX bitmaps hold premultiplied
// colour in a platform-dependent order, so each pixel is read as a
// TAlphaColor and the colour divided back out by its alpha.
function StraightBGRA(const AImage: TBitmap): TBytes;
var
  Data: TBitmapData;
  X, Y, I: Integer;
  C: TAlphaColorRec;
  A: Cardinal;

  function Unpremultiply(const AValue: Byte): Byte;
  begin
    if (A = 0) or (A = 255) then
      Result := AValue
    else
      Result := Byte(Min(255, (Cardinal(AValue) * 255 + A div 2) div A));
  end;

begin
  SetLength(Result, AImage.Width * AImage.Height * 4);
  if not AImage.Map(TMapAccess.Read, Data) then
    raise EInvalidOperation.Create('Cannot read an icon image.');
  try
    I := 0;
    for Y := 0 to AImage.Height - 1 do
      for X := 0 to AImage.Width - 1 do
      begin
        C.Color := Data.GetPixel(X, Y);
        A := C.A;
        Result[I] := Unpremultiply(C.B);
        Result[I + 1] := Unpremultiply(C.G);
        Result[I + 2] := Unpremultiply(C.R);
        Result[I + 3] := C.A;
        Inc(I, 4);
      end;
  finally
    AImage.Unmap(Data);
  end;
end;

procedure WriteWord(const AStream: TStream; const AValue: Word);
begin
  AStream.WriteData(AValue);   // every Delphi target is little-endian, as ICO is
end;

procedure WriteDWord(const AStream: TStream; const AValue: Cardinal);
begin
  AStream.WriteData(AValue);
end;

{ TSprite3DIconWriter }

constructor TSprite3DIconWriter.Create;
begin
  inherited Create;
end;

class function TSprite3DIconWriter.DialogFilter: String;
begin
  Result := Format('%s (*%s)|*%s', [FormatName, FileExtension, FileExtension]);
end;

class function TSprite3DIconWriter.FixFileName(const AFileName: String): String;
begin
  if SameText(ExtractFileExt(AFileName), FileExtension) then
    Result := AFileName
  else if ExtractFileExt(AFileName) = String.Empty then
    Result := AFileName + FileExtension
  else
    Result := ChangeFileExt(AFileName, FileExtension);
end;

procedure TSprite3DIconWriter.SaveToFile(const AImages: array of TBitmap;
  const AFileName: String);
var
  Stream: TFileStream;
  FileName, Dir: String;
begin
  FileName := OSFriendlyPath(AFileName);
  Dir := ExtractFileDir(FileName);
  if Dir <> String.Empty then
    ForceDirectories(Dir);
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    try
      SaveToStream(AImages, Stream);
    finally
      Stream.Free;
    end;
  except
    // No half-written icon left behind
    System.SysUtils.DeleteFile(AFileName);
    raise;
  end;
end;

{ TSprite3DIcoWriter }

const
  ICO_HEADER_SIZE = 6;     // ICONDIR: reserved, type, count
  ICO_ENTRY_SIZE = 16;     // ICONDIRENTRY
  BMP_INFO_SIZE = 40;      // BITMAPINFOHEADER
  ICO_MAX_SIZE = 256;

constructor TSprite3DIcoWriter.Create;
begin
  inherited Create;
  FPngMinSize := 256;
end;

class function TSprite3DIcoWriter.FormatName: String;
begin
  Result := 'Windows icon';
end;

class function TSprite3DIcoWriter.FileExtension: String;
begin
  Result := '.ico';
end;

class function TSprite3DIcoWriter.DefaultSizes: TArray<Integer>;
begin
  Result := [16, 20, 24, 32, 40, 48, 64, 256];
end;

// The image as a BITMAPINFOHEADER, the colour rows and the AND mask rows,
// both bottom row first, as an ICO bitmap entry is laid out. The header's
// height counts both, so it is twice the image's.
function TSprite3DIcoWriter.BitmapEntry(const AImage: TBitmap): TBytes;
var
  Pixels: TBytes;
  W, H, Y, X, MaskStride, ColourSize, MaskSize, P: Integer;
  Stream: TBytesStream;
  MaskRow: TBytes;
begin
  W := AImage.Width;
  H := AImage.Height;
  Pixels := StraightBGRA(AImage);
  MaskStride := ((W + 31) div 32) * 4;   // 1 bit a pixel, rows padded to 32 bits
  ColourSize := W * H * 4;
  MaskSize := MaskStride * H;

  Stream := TBytesStream.Create;
  try
    WriteDWord(Stream, BMP_INFO_SIZE);   // biSize
    WriteDWord(Stream, Cardinal(W));     // biWidth
    WriteDWord(Stream, Cardinal(H * 2)); // biHeight: colour plus mask
    WriteWord(Stream, 1);                // biPlanes
    WriteWord(Stream, 32);               // biBitCount
    WriteDWord(Stream, 0);               // biCompression: BI_RGB
    WriteDWord(Stream, Cardinal(ColourSize + MaskSize)); // biSizeImage
    WriteDWord(Stream, 0);               // biXPelsPerMeter
    WriteDWord(Stream, 0);               // biYPelsPerMeter
    WriteDWord(Stream, 0);               // biClrUsed
    WriteDWord(Stream, 0);               // biClrImportant

    for Y := H - 1 downto 0 do
      Stream.WriteBuffer(Pixels[Y * W * 4], W * 4);

    // AND mask: a set bit marks a fully transparent pixel, for readers
    // that ignore alpha
    SetLength(MaskRow, MaskStride);
    for Y := H - 1 downto 0 do
    begin
      FillChar(MaskRow[0], MaskStride, 0);
      for X := 0 to W - 1 do
      begin
        P := (Y * W + X) * 4;
        if Pixels[P + 3] = 0 then
          MaskRow[X div 8] := MaskRow[X div 8] or ($80 shr (X mod 8));
      end;
      Stream.WriteBuffer(MaskRow[0], MaskStride);
    end;

    Result := Copy(Stream.Bytes, 0, Stream.Size);
  finally
    Stream.Free;
  end;
end;

// The image as a PNG file, which an ICO entry may hold whole
function TSprite3DIcoWriter.PngEntry(const AImage: TBitmap): TBytes;
var
  Stream: TBytesStream;
begin
  Stream := TBytesStream.Create;
  try
    AImage.SaveToStream(Stream);   // FMX saves PNG, with straight alpha
    Result := Copy(Stream.Bytes, 0, Stream.Size);
  finally
    Stream.Free;
  end;
end;

procedure TSprite3DIcoWriter.SaveToStream(const AImages: array of TBitmap;
  const AStream: TStream);
var
  Entries: TArray<TBytes>;
  I, Size: Integer;
  Offset: Cardinal;
begin
  if Length(AImages) = 0 then
    raise EArgumentException.Create('An icon needs at least one image.');
  if Length(AImages) > High(Word) then
    raise EArgumentException.Create('An icon can hold at most 65535 images.');
  for I := 0 to High(AImages) do
  begin
    if not Assigned(AImages[I]) then
      raise EArgumentException.CreateFmt('Icon image %d is missing.', [I]);
    Size := AImages[I].Width;
    if (Size <> AImages[I].Height) or (Size < 1) or (Size > ICO_MAX_SIZE) then
      raise EArgumentException.CreateFmt(
        'Icon image %d is %d x %d; it must be square and 1 to %d pixels.',
        [I, AImages[I].Width, AImages[I].Height, ICO_MAX_SIZE]);
  end;

  SetLength(Entries, Length(AImages));
  for I := 0 to High(AImages) do
    if AImages[I].Width >= FPngMinSize then
      Entries[I] := PngEntry(AImages[I])
    else
      Entries[I] := BitmapEntry(AImages[I]);

  // ICONDIR
  WriteWord(AStream, 0);   // reserved
  WriteWord(AStream, 1);   // type: icon
  WriteWord(AStream, Word(Length(AImages)));

  // ICONDIRENTRY for each image; the data follows them all
  Offset := ICO_HEADER_SIZE + ICO_ENTRY_SIZE * Cardinal(Length(AImages));
  for I := 0 to High(AImages) do
  begin
    Size := AImages[I].Width;
    AStream.WriteData(Byte(Size mod 256));   // width; 0 means 256
    AStream.WriteData(Byte(Size mod 256));   // height; 0 means 256
    AStream.WriteData(Byte(0));              // colours in palette: none
    AStream.WriteData(Byte(0));              // reserved
    WriteWord(AStream, 1);                   // colour planes
    WriteWord(AStream, 32);                  // bits per pixel
    WriteDWord(AStream, Cardinal(Length(Entries[I])));
    WriteDWord(AStream, Offset);
    Inc(Offset, Cardinal(Length(Entries[I])));
  end;

  for I := 0 to High(Entries) do
    AStream.WriteBuffer(Entries[I][0], Length(Entries[I]));
end;

initialization
  RegisterIconWriter(TSprite3DIcoWriter);

end.
