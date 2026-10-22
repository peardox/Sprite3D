//** @abstract(Lays out a sequence of frames as a sprite strip, a texture atlas or an
//** animated GIF, and writes them to files.)
//**
//** The frames are TSprite3DImage records: plain RGBA pixels with straight (not
//** premultiplied) alpha, top row first, all the same size. ImageFromBitmap makes one from an
//** FMX bitmap, such as a grab from TSprite3DOffscreen, so the frames take no GPU resources
//** and no canvas is involved.
//**
//** ComposeStrip puts the frames side by side in one row; ComposeAtlas puts them in a square
//** grid, left to right and then top to bottom. SavePng writes such an image as a PNG file and
//** SaveAnimatedGif writes the frames as a looping GIF. Both writers are plain Pascal over
//** streams, using only System.ZLib, so they behave the same on every platform and are not
//** limited by the largest bitmap the GPU or FMX canvas accepts: a strip of a hundred frames
//** of 256 pixels is written as easily as a single frame.
//**
//** GIF keeps 256 colours per frame and on/off transparency, so each frame gets its own
//** palette of up to 255 colours, chosen by median cut, plus one transparent entry; pixels
//** less than half opaque become transparent. Every frame replaces the last (disposal "restore
//** to background"), so transparent sprites animate cleanly.
//**
//** Nothing here keeps state, and every routine may be called on any thread, except
//** ImageFromBitmap, which reads an FMX bitmap and so belongs on the main thread.
//**
//** @preformatted(
//** frames: TArray<TSprite3DImage>
//** |-- ComposeStrip  -> TSprite3DImage, Count x 1 frames  -> SavePng
//** |-- ComposeAtlas  -> TSprite3DImage, N x N frames      -> SavePng
//** `-- SaveAnimatedGif                                    -> .gif
//** )
unit Sprite3DSpriteSheet;

{
  Lays out a sequence of frames as a sprite strip, a texture atlas or an
  animated GIF, and writes them to files.

  The frames are TSprite3DImage records: plain RGBA pixels with straight
  (not premultiplied) alpha, top row first, all the same size.
  ImageFromBitmap makes one from an FMX bitmap, such as a grab from
  TSprite3DOffscreen, so the frames take no GPU resources and no canvas is
  involved.

  ComposeStrip puts the frames side by side in one row; ComposeAtlas puts
  them in a square grid, left to right and then top to bottom. SavePng
  writes such an image as a PNG file and SaveAnimatedGif writes the frames
  as a looping GIF. Both writers are plain Pascal over streams, using only
  System.ZLib, so they behave the same on every platform and are not limited
  by the largest bitmap the GPU or FMX canvas accepts: a strip of a hundred
  frames of 256 pixels is written as easily as a single frame.

  GIF keeps 256 colours per frame and on/off transparency, so each frame
  gets its own palette of up to 255 colours, chosen by median cut, plus one
  transparent entry; pixels less than half opaque become transparent. Every
  frame replaces the last (disposal "restore to background"), so transparent
  sprites animate cleanly.

  Nothing here keeps state, and every routine may be called on any thread,
  except ImageFromBitmap, which reads an FMX bitmap and so belongs on the
  main thread.

    frames: TArray<TSprite3DImage>
    |-- ComposeStrip  -> TSprite3DImage, Count x 1 frames  -> SavePng
    |-- ComposeAtlas  -> TSprite3DImage, N x N frames      -> SavePng
    `-- SaveAnimatedGif                                    -> .gif
}

interface

uses
  System.SysUtils, System.Classes, FMX.Graphics;

type
  //** @abstract(An image as plain RGBA bytes with straight alpha, top row first.)
  //**
  //** Pixel (X, Y) starts at byte @code(@(Y * Width + X@) * 4) of Pixels, in the order red,
  //** green, blue, alpha. The colour is not premultiplied by alpha, as PNG and GIF expect.
  //** A record of value type apart from Pixels, which is a reference-counted dynamic array,
  //** so copies share the pixels until one is changed through SetLength or a new array.
  /// <summary>An image as plain RGBA bytes with straight alpha, top row first.</summary>
  /// <remarks>Pixel (X, Y) starts at byte <c>(Y * Width + X) * 4</c> of Pixels, in the order
  /// red, green, blue, alpha. The colour is not premultiplied by alpha, as PNG and GIF expect.
  /// A record of value type apart from Pixels, which is a reference-counted dynamic array, so
  /// copies share the pixels until one is changed through SetLength or a new array.</remarks>
  TSprite3DImage = record
    //** @abstract(The width in pixels.)
    /// <summary>The width in pixels.</summary>
    Width: Integer;
    //** @abstract(The height in pixels.)
    /// <summary>The height in pixels.</summary>
    Height: Integer;
    //** @abstract(Width * Height * 4 bytes of RGBA, top row first.)
    /// <summary>Width * Height * 4 bytes of RGBA, top row first.</summary>
    Pixels: TBytes;
    //** @abstract(A new image of the given size with every pixel fully transparent.)
    //**
    //** @param(AWidth The width in pixels; at least 1.)
    //**
    //** @param(AHeight The height in pixels; at least 1.)
    //**
    //** @returns(The image.)
    //**
    //** @raises(EArgumentException If either size is less than 1.)
    //**
    //** @raises(EOutOfMemory If the pixels cannot be allocated.)
    /// <summary>A new image of the given size with every pixel fully transparent.</summary>
    /// <param name="AWidth">The width in pixels; at least 1.</param>
    /// <param name="AHeight">The height in pixels; at least 1.</param>
    /// <returns>The image.</returns>
    /// <exception cref="EArgumentException">If either size is less than 1.</exception>
    /// <exception cref="EOutOfMemory">If the pixels cannot be allocated.</exception>
    class function Create(const AWidth, AHeight: Integer): TSprite3DImage; static;
  end;

//** @abstract(Copies an FMX bitmap into a TSprite3DImage, removing premultiplied alpha.)
//**
//** FMX bitmaps hold their colour premultiplied by alpha; the copy divides it back out, so a
//** half-transparent edge keeps its true colour. Works with whichever byte order the
//** platform's bitmaps use. For the main thread only. The bitmap is not changed or freed.
//**
//** @param(ABitmap The bitmap to copy; not nil and not empty.)
//**
//** @returns(The copy.)
//**
//** @raises(EArgumentException If ABitmap is nil or empty.)
//**
//** @raises(EInvalidOperation If the bitmap cannot be mapped for reading.)
/// <summary>Copies an FMX bitmap into a TSprite3DImage, removing premultiplied alpha.</summary>
/// <remarks>FMX bitmaps hold their colour premultiplied by alpha; the copy divides it back
/// out, so a half-transparent edge keeps its true colour. Works with whichever byte order the
/// platform's bitmaps use. For the main thread only. The bitmap is not changed or
/// freed.</remarks>
/// <param name="ABitmap">The bitmap to copy; not nil and not empty.</param>
/// <returns>The copy.</returns>
/// <exception cref="EArgumentException">If ABitmap is nil or empty.</exception>
/// <exception cref="EInvalidOperation">If the bitmap cannot be mapped for reading.</exception>
function ImageFromBitmap(const ABitmap: TBitmap): TSprite3DImage;

//** @abstract(Puts the frames side by side in one row: a sprite strip.)
//**
//** Frame I is at X = I * frame width. The result is one frame high and Length(AFrames)
//** frames long.
//**
//** @param(AFrames The frames, in order; at least one, all the same size.)
//**
//** @returns(The strip.)
//**
//** @raises(EArgumentException If there are no frames or they differ in size.)
//**
//** @raises(EOutOfMemory If the strip is too large to allocate.)
/// <summary>Puts the frames side by side in one row: a sprite strip.</summary>
/// <remarks>Frame I is at X = I * frame width. The result is one frame high and
/// Length(AFrames) frames long.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size.</param>
/// <returns>The strip.</returns>
/// <exception cref="EArgumentException">If there are no frames or they differ in
/// size.</exception>
/// <exception cref="EOutOfMemory">If the strip is too large to allocate.</exception>
function ComposeStrip(const AFrames: TArray<TSprite3DImage>): TSprite3DImage;

//** @abstract(Puts the frames in a square grid: a texture atlas.)
//**
//** The grid has ACells columns and ACells rows, where ACells is the smallest number whose
//** square holds every frame, so 30 frames make a 6 by 6 grid. Frame I is in column
//** @code(I mod ACells) and row @code(I div ACells): the frames run left to right along a
//** row, then carry on at the start of the next row down. Cells after the last frame are left
//** fully transparent.
//**
//** @param(AFrames The frames, in order; at least one, all the same size.)
//**
//** @param(ACells On return, the number of columns, which is also the number of rows.)
//**
//** @returns(The atlas.)
//**
//** @raises(EArgumentException If there are no frames or they differ in size.)
//**
//** @raises(EOutOfMemory If the atlas is too large to allocate.)
/// <summary>Puts the frames in a square grid: a texture atlas.</summary>
/// <remarks>The grid has ACells columns and ACells rows, where ACells is the smallest number
/// whose square holds every frame, so 30 frames make a 6 by 6 grid. Frame I is in column
/// <c>I mod ACells</c> and row <c>I div ACells</c>: the frames run left to right along a row,
/// then carry on at the start of the next row down. Cells after the last frame are left fully
/// transparent.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size.</param>
/// <param name="ACells">On return, the number of columns, which is also the number of
/// rows.</param>
/// <returns>The atlas.</returns>
/// <exception cref="EArgumentException">If there are no frames or they differ in
/// size.</exception>
/// <exception cref="EOutOfMemory">If the atlas is too large to allocate.</exception>
function ComposeAtlas(const AFrames: TArray<TSprite3DImage>;
  out ACells: Integer): TSprite3DImage;

//** @abstract(Writes an image as a 32-bit RGBA PNG file.)
//**
//** The file is written in full, replacing any file of that name, with 8-bit RGBA, no
//** interlacing and zlib compression. The folder must exist. Blocks while it writes.
//**
//** @param(AImage The image to write.)
//**
//** @param(AFileName The file to write.)
//**
//** @raises(EArgumentException If the image is empty.)
//**
//** @raises(EFCreateError If the file cannot be created.)
//**
//** @raises(EWriteError If writing fails part way.)
/// <summary>Writes an image as a 32-bit RGBA PNG file.</summary>
/// <remarks>The file is written in full, replacing any file of that name, with 8-bit RGBA, no
/// interlacing and zlib compression. The folder must exist. Blocks while it
/// writes.</remarks>
/// <param name="AImage">The image to write.</param>
/// <param name="AFileName">The file to write.</param>
/// <exception cref="EArgumentException">If the image is empty.</exception>
/// <exception cref="EFCreateError">If the file cannot be created.</exception>
/// <exception cref="EWriteError">If writing fails part way.</exception>
procedure SavePng(const AImage: TSprite3DImage; const AFileName: String);

//** @abstract(Writes the frames as an animated GIF that loops for ever.)
//**
//** Each frame gets its own palette of up to 255 colours, chosen by median cut, and one
//** transparent entry; a pixel less than half opaque is written as transparent. Every frame
//** is shown for ADelay hundredths of a second and then cleared, so transparent frames do
//** not build up on each other. The file replaces any of that name; the folder must exist.
//** Blocks while it writes.
//**
//** @param(AFrames The frames, in order; at least one, all the same size and each at most
//** 65535 pixels wide and high.)
//**
//** @param(AFileName The file to write.)
//**
//** @param(ADelay How long each frame shows, in hundredths of a second. Values below 2 are
//** written as 2, since browsers slow down shorter delays to a tenth of a second.)
//**
//** @raises(EArgumentException If there are no frames, they differ in size or they are
//** too large for GIF.)
//**
//** @raises(EFCreateError If the file cannot be created.)
//**
//** @raises(EWriteError If writing fails part way.)
/// <summary>Writes the frames as an animated GIF that loops for ever.</summary>
/// <remarks>Each frame gets its own palette of up to 255 colours, chosen by median cut, and
/// one transparent entry; a pixel less than half opaque is written as transparent. Every
/// frame is shown for ADelay hundredths of a second and then cleared, so transparent frames do
/// not build up on each other. The file replaces any of that name; the folder must exist.
/// Blocks while it writes.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size and each at
/// most 65535 pixels wide and high.</param>
/// <param name="AFileName">The file to write.</param>
/// <param name="ADelay">How long each frame shows, in hundredths of a second. Values below 2
/// are written as 2, since browsers slow down shorter delays to a tenth of a
/// second.</param>
/// <exception cref="EArgumentException">If there are no frames, they differ in size or they
/// are too large for GIF.</exception>
/// <exception cref="EFCreateError">If the file cannot be created.</exception>
/// <exception cref="EWriteError">If writing fails part way.</exception>
procedure SaveAnimatedGif(const AFrames: TArray<TSprite3DImage>; const AFileName: String;
  const ADelay: Integer);

//** @abstract(A name made safe to use as a file name on every platform.)
//**
//** Characters that Windows, macOS, Linux, Android or iOS reject or treat specially in file
//** names, such as @code(/ \ : * ? " < > |) and control characters, become underscores, and
//** leading and trailing spaces and dots are removed. An empty result becomes
//** @code('animation').
//**
//** @param(AName The name, such as an animation's name.)
//**
//** @returns(The safe name, without a folder or extension.)
/// <summary>A name made safe to use as a file name on every platform.</summary>
/// <remarks>Characters that Windows, macOS, Linux, Android or iOS reject or treat specially in
/// file names, such as <c>/ \ : * ? " &lt; &gt; |</c> and control characters, become
/// underscores, and leading and trailing spaces and dots are removed. An empty result becomes
/// <c>'animation'</c>.</remarks>
/// <param name="AName">The name, such as an animation's name.</param>
/// <returns>The safe name, without a folder or extension.</returns>
function SafeFileStem(const AName: String): String;

implementation

uses
  System.Types, System.UITypes, System.Math, System.ZLib, System.Generics.Collections,
  System.Generics.Defaults, OSPaths;

{ TSprite3DImage }

class function TSprite3DImage.Create(const AWidth, AHeight: Integer): TSprite3DImage;
begin
  if (AWidth < 1) or (AHeight < 1) then
    raise EArgumentException.CreateFmt('An image of %d x %d pixels is not possible.',
      [AWidth, AHeight]);
  Result.Width := AWidth;
  Result.Height := AHeight;
  // A new dynamic array is zero-filled: every pixel transparent black
  SetLength(Result.Pixels, Int64(AWidth) * AHeight * 4);
end;

function ImageFromBitmap(const ABitmap: TBitmap): TSprite3DImage;
var
  Data: TBitmapData;
  X, Y, A: Integer;
  Colour: TAlphaColorRec;
  Dst: PByte;
begin
  if (ABitmap = nil) or ABitmap.IsEmpty then
    raise EArgumentException.Create('There is no image to copy.');
  Result := TSprite3DImage.Create(ABitmap.Width, ABitmap.Height);
  if not ABitmap.Map(TMapAccess.Read, Data) then
    raise EInvalidOperation.Create('Cannot read the grabbed image.');
  try
    Dst := @Result.Pixels[0];
    for Y := 0 to Result.Height - 1 do
      for X := 0 to Result.Width - 1 do
      begin
        // GetPixel hides the platform's byte order; the colour it gives is
        // still premultiplied, as stored
        Colour := TAlphaColorRec(Data.GetPixel(X, Y));
        A := Colour.A;
        if A = 0 then
        begin
          Dst[0] := 0;
          Dst[1] := 0;
          Dst[2] := 0;
        end
        else if A = 255 then
        begin
          Dst[0] := Colour.R;
          Dst[1] := Colour.G;
          Dst[2] := Colour.B;
        end
        else
        begin
          Dst[0] := Min(255, (Colour.R * 255 + A div 2) div A);
          Dst[1] := Min(255, (Colour.G * 255 + A div 2) div A);
          Dst[2] := Min(255, (Colour.B * 255 + A div 2) div A);
        end;
        Dst[3] := A;
        Inc(Dst, 4);
      end;
  finally
    ABitmap.Unmap(Data);
  end;
end;

// Every frame present and the same size; their common size
procedure CheckFrames(const AFrames: TArray<TSprite3DImage>; out AWidth,
  AHeight: Integer);
var
  Frame: TSprite3DImage;
begin
  if Length(AFrames) = 0 then
    raise EArgumentException.Create('There are no frames.');
  AWidth := AFrames[0].Width;
  AHeight := AFrames[0].Height;
  for Frame in AFrames do
    if (Frame.Width <> AWidth) or (Frame.Height <> AHeight) or
      (Length(Frame.Pixels) <> Int64(AWidth) * AHeight * 4) or (AWidth < 1) or
      (AHeight < 1) then
      raise EArgumentException.Create('The frames are not all the same size.');
end;

// Copies AFrame into ADest with its top left corner at (AX, AY)
procedure Blit(const AFrame: TSprite3DImage; var ADest: TSprite3DImage;
  const AX, AY: Integer);
var
  Y: Integer;
  RowBytes: NativeInt;
begin
  RowBytes := NativeInt(AFrame.Width) * 4;
  for Y := 0 to AFrame.Height - 1 do
    Move(AFrame.Pixels[NativeInt(Y) * RowBytes],
      ADest.Pixels[(NativeInt(AY + Y) * ADest.Width + AX) * 4], RowBytes);
end;

function ComposeStrip(const AFrames: TArray<TSprite3DImage>): TSprite3DImage;
var
  W, H, I: Integer;
begin
  CheckFrames(AFrames, W, H);
  Result := TSprite3DImage.Create(W * Length(AFrames), H);
  for I := 0 to High(AFrames) do
    Blit(AFrames[I], Result, I * W, 0);
end;

function ComposeAtlas(const AFrames: TArray<TSprite3DImage>;
  out ACells: Integer): TSprite3DImage;
var
  W, H, I: Integer;
begin
  CheckFrames(AFrames, W, H);
  ACells := Ceil(Sqrt(Length(AFrames)));
  while ACells * ACells < Length(AFrames) do   // guard against rounding
    Inc(ACells);
  Result := TSprite3DImage.Create(W * ACells, H * ACells);
  for I := 0 to High(AFrames) do
    Blit(AFrames[I], Result, (I mod ACells) * W, (I div ACells) * H);
end;

{ PNG }

var
  CrcTable: array[0..255] of Cardinal;

procedure InitCrcTable;
var
  N, K: Integer;
  C: Cardinal;
begin
  for N := 0 to 255 do
  begin
    C := Cardinal(N);
    for K := 0 to 7 do
      if (C and 1) <> 0 then
        C := $EDB88320 xor (C shr 1)
      else
        C := C shr 1;
    CrcTable[N] := C;
  end;
end;

function UpdateCrc(const ACrc: Cardinal; const ABytes: TBytes): Cardinal;
var
  I: Integer;
begin
  Result := ACrc;
  for I := 0 to High(ABytes) do
    Result := CrcTable[(Result xor ABytes[I]) and $FF] xor (Result shr 8);
end;

procedure WriteBE32(const AStream: TStream; const AValue: Cardinal);
var
  B: array[0..3] of Byte;
begin
  B[0] := Byte(AValue shr 24);
  B[1] := Byte(AValue shr 16);
  B[2] := Byte(AValue shr 8);
  B[3] := Byte(AValue);
  AStream.WriteBuffer(B, 4);
end;

// One chunk: length, type, data, and the CRC of type and data
procedure WriteChunk(const AStream: TStream; const AType: AnsiString;
  const AData: TBytes);
var
  TypeBytes: TBytes;
  Crc: Cardinal;
begin
  SetLength(TypeBytes, 4);
  Move(AType[1], TypeBytes[0], 4);
  WriteBE32(AStream, Cardinal(Length(AData)));
  AStream.WriteBuffer(TypeBytes, 4);
  if Length(AData) > 0 then
    AStream.WriteBuffer(AData, Length(AData));
  Crc := UpdateCrc($FFFFFFFF, TypeBytes);
  Crc := UpdateCrc(Crc, AData) xor $FFFFFFFF;
  WriteBE32(AStream, Crc);
end;

procedure SavePng(const AImage: TSprite3DImage; const AFileName: String);
const
  SIGNATURE: array[0..7] of Byte = (137, 80, 78, 71, 13, 10, 26, 10);
var
  Stream: TFileStream;
  Header, Raw, Zipped: TBytes;
  Y: Integer;
  RowBytes, Src, Dst: NativeInt;
begin
  if (AImage.Width < 1) or (AImage.Height < 1) or
    (Length(AImage.Pixels) <> Int64(AImage.Width) * AImage.Height * 4) then
    raise EArgumentException.Create('There is no image to save.');

  // IHDR: size, 8 bits per channel, colour type 6 (RGBA), deflate, no
  // filtering beyond each row's own filter byte, no interlace
  SetLength(Header, 13);
  Header[0] := Byte(AImage.Width shr 24);
  Header[1] := Byte(AImage.Width shr 16);
  Header[2] := Byte(AImage.Width shr 8);
  Header[3] := Byte(AImage.Width);
  Header[4] := Byte(AImage.Height shr 24);
  Header[5] := Byte(AImage.Height shr 16);
  Header[6] := Byte(AImage.Height shr 8);
  Header[7] := Byte(AImage.Height);
  Header[8] := 8;
  Header[9] := 6;
  Header[10] := 0;
  Header[11] := 0;
  Header[12] := 0;

  // Each row is a filter byte, here 0 (none), then its pixels
  RowBytes := NativeInt(AImage.Width) * 4;
  SetLength(Raw, (RowBytes + 1) * AImage.Height);
  Src := 0;
  Dst := 0;
  for Y := 0 to AImage.Height - 1 do
  begin
    Raw[Dst] := 0;
    Move(AImage.Pixels[Src], Raw[Dst + 1], RowBytes);
    Inc(Src, RowBytes);
    Inc(Dst, RowBytes + 1);
  end;
  ZCompress(Raw, Zipped, zcDefault);   // a zlib stream, as IDAT wants
  Raw := nil;

  Stream := TFileStream.Create(OSFriendlyPath(AFileName), fmCreate);
  try
    Stream.WriteBuffer(SIGNATURE, Length(SIGNATURE));
    WriteChunk(Stream, 'IHDR', Header);
    WriteChunk(Stream, 'IDAT', Zipped);
    WriteChunk(Stream, 'IEND', nil);
  finally
    Stream.Free;
  end;
end;

{ GIF }

const
  GIF_TRANSPARENT = 255;   // palette entry kept for transparent pixels
  GIF_MAX_COLOURS = 255;   // the rest of the 256 entries
  GIF_BINS = 32768;        // 5 bits each of red, green and blue

type
  // One cell of the 5-5-5 colour histogram, with the sums for its average
  TColourBin = record
    Key: Integer;
    Count: Int64;
    SumR, SumG, SumB: Int64;
  end;

  // A box of the median cut: a run of Bins, and the bins' extent
  TColourBox = record
    Lo, Hi: Integer;   // inclusive indices into the bins array
    Count: Int64;
    MinC, MaxC: array[0..2] of Integer;
  end;

  // One frame as palette indices, with its palette
  TGifFrame = record
    Palette: array[0..255] of TAlphaColorRec;
    Indices: TBytes;
  end;

function BinChannel(const AKey, AChannel: Integer): Integer; inline;
begin
  case AChannel of
    0: Result := (AKey shr 10) and 31;
    1: Result := (AKey shr 5) and 31;
  else
    Result := AKey and 31;
  end;
end;

procedure MeasureBox(const ABins: TArray<TColourBin>; var ABox: TColourBox);
var
  I, C, V: Integer;
begin
  ABox.Count := 0;
  for C := 0 to 2 do
  begin
    ABox.MinC[C] := 31;
    ABox.MaxC[C] := 0;
  end;
  for I := ABox.Lo to ABox.Hi do
  begin
    Inc(ABox.Count, ABins[I].Count);
    for C := 0 to 2 do
    begin
      V := BinChannel(ABins[I].Key, C);
      ABox.MinC[C] := Min(ABox.MinC[C], V);
      ABox.MaxC[C] := Max(ABox.MaxC[C], V);
    end;
  end;
end;

// Palette and indices for one frame. Opaque colours are counted on a 5-5-5
// grid; up to 255 cells become entries directly, otherwise median cut
// splits them into 255 boxes, each entry the weighted average of its box.
function QuantizeFrame(const AFrame: TSprite3DImage): TGifFrame;
var
  Hist: array of TColourBin;
  Lookup: array of Byte;
  Bins: TArray<TColourBin>;
  Boxes: TArray<TColourBox>;
  BoxCount, I, J, Best, Axis, Split, PixelCount: Integer;
  Score, BestScore, Half, Running: Int64;
  P: PByte;
  Key: Integer;
  Box: TColourBox;
  SortAxis: Integer;
begin
  FillChar(Result.Palette, SizeOf(Result.Palette), 0);
  SetLength(Hist, GIF_BINS);
  SetLength(Lookup, GIF_BINS);
  PixelCount := AFrame.Width * AFrame.Height;

  P := @AFrame.Pixels[0];
  for I := 0 to PixelCount - 1 do
  begin
    if P[3] >= 128 then
    begin
      Key := (Integer(P[0] shr 3) shl 10) or (Integer(P[1] shr 3) shl 5) or (P[2] shr 3);
      Inc(Hist[Key].Count);
      Inc(Hist[Key].SumR, P[0]);
      Inc(Hist[Key].SumG, P[1]);
      Inc(Hist[Key].SumB, P[2]);
    end;
    Inc(P, 4);
  end;
  J := 0;
  for I := 0 to GIF_BINS - 1 do
    if Hist[I].Count > 0 then
      Inc(J);
  SetLength(Bins, J);
  J := 0;
  for I := 0 to GIF_BINS - 1 do
    if Hist[I].Count > 0 then
    begin
      Hist[I].Key := I;
      Bins[J] := Hist[I];
      Inc(J);
    end;
  Hist := nil;

  if Length(Bins) > 0 then
  begin
    // Start with one box holding every colour, then split the box with the
    // most spread, weighted by how many pixels it covers, at its median
    SetLength(Boxes, 1);
    Boxes[0].Lo := 0;
    Boxes[0].Hi := High(Bins);
    MeasureBox(Bins, Boxes[0]);
    BoxCount := 1;
    while BoxCount < GIF_MAX_COLOURS do
    begin
      Best := -1;
      BestScore := 0;
      for I := 0 to BoxCount - 1 do
        if Boxes[I].Hi > Boxes[I].Lo then
        begin
          Score := 0;
          for J := 0 to 2 do
            Score := Max(Score, Int64(Boxes[I].MaxC[J] - Boxes[I].MinC[J] + 1));
          Score := Score * Boxes[I].Count;
          if Score > BestScore then
          begin
            BestScore := Score;
            Best := I;
          end;
        end;
      if Best < 0 then
        Break;   // every box is a single colour: nothing left to split

      Box := Boxes[Best];
      Axis := 0;
      for J := 1 to 2 do
        if Box.MaxC[J] - Box.MinC[J] > Box.MaxC[Axis] - Box.MinC[Axis] then
          Axis := J;
      SortAxis := Axis;
      TArray.Sort<TColourBin>(Bins, TComparer<TColourBin>.Construct(
        function(const L, R: TColourBin): Integer
        begin
          Result := BinChannel(L.Key, SortAxis) - BinChannel(R.Key, SortAxis);
        end), Box.Lo, Box.Hi - Box.Lo + 1);

      // The split leaves at least one bin on each side
      Half := Box.Count div 2;
      Running := 0;
      Split := Box.Lo;
      for J := Box.Lo to Box.Hi - 1 do
      begin
        Inc(Running, Bins[J].Count);
        Split := J;
        if Running >= Half then
          Break;
      end;

      Boxes[Best].Lo := Box.Lo;
      Boxes[Best].Hi := Split;
      MeasureBox(Bins, Boxes[Best]);
      SetLength(Boxes, BoxCount + 1);
      Boxes[BoxCount].Lo := Split + 1;
      Boxes[BoxCount].Hi := Box.Hi;
      MeasureBox(Bins, Boxes[BoxCount]);
      Inc(BoxCount);
    end;

    // Each box becomes an entry; each of its cells maps to it
    for I := 0 to BoxCount - 1 do
    begin
      Box := Boxes[I];
      Score := 0;   // reused as the sums
      Running := 0;
      Half := 0;
      for J := Box.Lo to Box.Hi do
      begin
        Inc(Score, Bins[J].SumR);
        Inc(Running, Bins[J].SumG);
        Inc(Half, Bins[J].SumB);
        Lookup[Bins[J].Key] := I;
      end;
      Result.Palette[I].R := Byte((Score + Box.Count div 2) div Box.Count);
      Result.Palette[I].G := Byte((Running + Box.Count div 2) div Box.Count);
      Result.Palette[I].B := Byte((Half + Box.Count div 2) div Box.Count);
      Result.Palette[I].A := 255;
    end;
  end;

  SetLength(Result.Indices, PixelCount);
  P := @AFrame.Pixels[0];
  for I := 0 to PixelCount - 1 do
  begin
    if P[3] >= 128 then
      Result.Indices[I] := Lookup[(Integer(P[0] shr 3) shl 10) or
        (Integer(P[1] shr 3) shl 5) or (P[2] shr 3)]
    else
      Result.Indices[I] := GIF_TRANSPARENT;
    Inc(P, 4);
  end;
end;

type
  // GIF's variable-length LZW, least significant bit first, 8-bit symbols
  TGifLzw = class
  private
    FCodes: array of Word;    // FCodes[Prefix shl 8 or Symbol]: the code
    FStamps: array of Word;   // valid only where FStamps[...] = FStamp
    FStamp: Word;
    FOut: TBytes;
    FOutLen: Integer;
    FAcc: Cardinal;
    FBits: Integer;
    FSize: Integer;
    procedure Emit(const ACode: Integer);
    procedure PutByte(const AByte: Byte);
    procedure ResetTable;
  public
    constructor Create;
    function Encode(const AIndices: TBytes): TBytes;
  end;

const
  LZW_CLEAR = 256;
  LZW_END = 257;
  LZW_FIRST = 258;
  LZW_MAX = 4096;

constructor TGifLzw.Create;
begin
  inherited Create;
  SetLength(FCodes, LZW_MAX * 256);
  SetLength(FStamps, LZW_MAX * 256);
  FStamp := 0;
end;

procedure TGifLzw.ResetTable;
begin
  // A new stamp empties the table without clearing it
  if FStamp = High(Word) then
  begin
    FillChar(FStamps[0], Length(FStamps) * SizeOf(Word), 0);
    FStamp := 0;
  end;
  Inc(FStamp);
  FSize := 9;
end;

procedure TGifLzw.PutByte(const AByte: Byte);
begin
  if FOutLen = Length(FOut) then
    SetLength(FOut, Max(4096, Length(FOut) * 2));
  FOut[FOutLen] := AByte;
  Inc(FOutLen);
end;

procedure TGifLzw.Emit(const ACode: Integer);
begin
  FAcc := FAcc or (Cardinal(ACode) shl FBits);
  Inc(FBits, FSize);
  while FBits >= 8 do
  begin
    PutByte(Byte(FAcc));
    FAcc := FAcc shr 8;
    Dec(FBits, 8);
  end;
end;

function TGifLzw.Encode(const AIndices: TBytes): TBytes;
var
  I, Prefix, Next, Key: Integer;
  Symbol: Byte;
begin
  FOut := nil;
  FOutLen := 0;
  FAcc := 0;
  FBits := 0;
  ResetTable;
  Next := LZW_FIRST;
  Emit(LZW_CLEAR);
  if Length(AIndices) > 0 then
  begin
    Prefix := AIndices[0];
    for I := 1 to High(AIndices) do
    begin
      Symbol := AIndices[I];
      Key := (Prefix shl 8) or Symbol;
      if FStamps[Key] = FStamp then
        Prefix := FCodes[Key]
      else
      begin
        Emit(Prefix);
        if Next < LZW_MAX then
        begin
          FCodes[Key] := Next;
          FStamps[Key] := FStamp;
          Inc(Next);
          // The decoder, one entry behind, widens once it would need it
          if (Next > (1 shl FSize)) and (FSize < 12) then
            Inc(FSize);
        end
        else
        begin
          // Table full: start again
          Emit(LZW_CLEAR);
          ResetTable;
          Next := LZW_FIRST;
        end;
        Prefix := Symbol;
      end;
    end;
    Emit(Prefix);
    // Reading that code the decoder adds an entry, which can widen the
    // end code
    if Next < LZW_MAX then
    begin
      Inc(Next);
      if (Next > (1 shl FSize)) and (FSize < 12) then
        Inc(FSize);
    end;
  end;
  Emit(LZW_END);
  if FBits > 0 then
    PutByte(Byte(FAcc));
  SetLength(FOut, FOutLen);
  Result := FOut;
  FOut := nil;
end;

procedure WriteLE16(const AStream: TStream; const AValue: Integer);
var
  B: array[0..1] of Byte;
begin
  B[0] := Byte(AValue);
  B[1] := Byte(AValue shr 8);
  AStream.WriteBuffer(B, 2);
end;

procedure WriteByte(const AStream: TStream; const AValue: Byte);
begin
  AStream.WriteBuffer(AValue, 1);
end;

procedure SaveAnimatedGif(const AFrames: TArray<TSprite3DImage>; const AFileName: String;
  const ADelay: Integer);
const
  NETSCAPE: AnsiString = 'NETSCAPE2.0';
var
  W, H, I, Pos, Len: Integer;
  Stream: TFileStream;
  Lzw: TGifLzw;
  Frame: TGifFrame;
  Data: TBytes;
  Header: AnsiString;
begin
  CheckFrames(AFrames, W, H);
  if (W > 65535) or (H > 65535) then
    raise EArgumentException.Create('The frames are too large for a GIF.');

  Lzw := TGifLzw.Create;
  try
    Stream := TFileStream.Create(OSFriendlyPath(AFileName), fmCreate);
    try
      Header := 'GIF89a';
      Stream.WriteBuffer(Header[1], 6);
      // Logical screen: the frame size, no global colour table
      WriteLE16(Stream, W);
      WriteLE16(Stream, H);
      WriteByte(Stream, 0);   // no global table
      WriteByte(Stream, 0);   // background colour index
      WriteByte(Stream, 0);   // pixel aspect ratio not given

      // Loop for ever
      WriteByte(Stream, $21);
      WriteByte(Stream, $FF);
      WriteByte(Stream, 11);
      Stream.WriteBuffer(NETSCAPE[1], 11);
      WriteByte(Stream, 3);
      WriteByte(Stream, 1);
      WriteLE16(Stream, 0);   // 0: no limit
      WriteByte(Stream, 0);

      for I := 0 to High(AFrames) do
      begin
        Frame := QuantizeFrame(AFrames[I]);

        // Graphic control: restore to background, transparent entry 255
        WriteByte(Stream, $21);
        WriteByte(Stream, $F9);
        WriteByte(Stream, 4);
        WriteByte(Stream, (2 shl 2) or 1);
        WriteLE16(Stream, Max(2, ADelay));
        WriteByte(Stream, GIF_TRANSPARENT);
        WriteByte(Stream, 0);

        // Image: the whole screen, with its own 256-entry colour table
        WriteByte(Stream, $2C);
        WriteLE16(Stream, 0);
        WriteLE16(Stream, 0);
        WriteLE16(Stream, W);
        WriteLE16(Stream, H);
        WriteByte(Stream, $80 or 7);
        for Pos := 0 to 255 do
        begin
          WriteByte(Stream, Frame.Palette[Pos].R);
          WriteByte(Stream, Frame.Palette[Pos].G);
          WriteByte(Stream, Frame.Palette[Pos].B);
        end;

        // LZW data in sub-blocks of up to 255 bytes
        WriteByte(Stream, 8);
        Data := Lzw.Encode(Frame.Indices);
        Pos := 0;
        while Pos < Length(Data) do
        begin
          Len := Min(255, Length(Data) - Pos);
          WriteByte(Stream, Len);
          Stream.WriteBuffer(Data[Pos], Len);
          Inc(Pos, Len);
        end;
        WriteByte(Stream, 0);
      end;

      WriteByte(Stream, $3B);   // trailer
    finally
      Stream.Free;
    end;
  finally
    Lzw.Free;
  end;
end;

function SafeFileStem(const AName: String): String;
const
  BAD = '/\:*?"<>|';
var
  I: Integer;
begin
  Result := AName;
  for I := 1 to Length(Result) do
    if (Result[I] < ' ') or (Pos(Result[I], BAD) > 0) then
      Result[I] := '_';
  Result := Result.Trim([' ', '.']);
  if Result = String.Empty then
    Result := 'animation';
end;

initialization
  InitCrcTable;

end.
