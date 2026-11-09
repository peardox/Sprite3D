//** @abstract(Reads PNG files into TSprite3DImage records, in plain Pascal, on any thread.)
//**
//** ReadPng decodes a PNG from a stream and LoadPng from a file. Every kind of PNG the
//** standard allows is read: greyscale, truecolour, indexed, greyscale with alpha and
//** truecolour with alpha, at every bit depth each allows (1, 2, 4, 8 or 16), interlaced
//** (Adam7) or not, with transparency from a @code(tRNS) chunk where there is one. The
//** result is always 8-bit RGBA with straight alpha, top row first, as TSprite3DImage
//** holds it: 16-bit samples are rounded to 8 bits, and samples of fewer bits are scaled up
//** to the full range.
//**
//** The decoder uses only System.ZLib and the RTL, not FMX or the platform's image codecs, so
//** it is safe on a worker thread and behaves the same on every platform. It reads only what
//** it needs for the pixels: @code(IHDR), @code(PLTE), @code(tRNS), @code(IDAT) and
//** @code(IEND). Gamma, colour profiles, text and every other ancillary chunk are skipped,
//** and chunk CRCs are not checked; damaged image data is still caught, as zlib checks its
//** own. A file that is not a PNG, or is damaged or cut short, raises EPngError with a
//** message saying what is wrong.
//**
//** @preformatted(
//** file or stream
//** `-- ReadPng: signature, chunks, IDAT joined
//**     |-- System.ZLib inflates the filtered rows
//**     |-- each row unfiltered (None, Sub, Up, Average, Paeth)
//**     `-- each pixel expanded to RGBA 8   -> TSprite3DImage
//** )
unit Sprite3DPngReader;

{
  Reads PNG files into TSprite3DImage records, in plain Pascal, on any
  thread.

  ReadPng decodes a PNG from a stream and LoadPng from a file. Every kind of
  PNG the standard allows is read: greyscale, truecolour, indexed, greyscale
  with alpha and truecolour with alpha, at every bit depth each allows (1, 2,
  4, 8 or 16), interlaced (Adam7) or not, with transparency from a tRNS chunk
  where there is one. The result is always 8-bit RGBA with straight alpha,
  top row first, as TSprite3DImage holds it: 16-bit samples are rounded to 8
  bits, and samples of fewer bits are scaled up to the full range.

  The decoder uses only System.ZLib and the RTL, not FMX or the platform's
  image codecs, so it is safe on a worker thread and behaves the same on
  every platform. It reads only IHDR, PLTE, tRNS, IDAT and IEND; every other
  chunk is skipped, and chunk CRCs are not checked (zlib checks its own
  data). A file that is not a PNG, or is damaged or cut short, raises
  EPngError saying what is wrong.

    file or stream
    `-- ReadPng: signature, chunks, IDAT joined
        |-- System.ZLib inflates the filtered rows
        |-- each row unfiltered (None, Sub, Up, Average, Paeth)
        `-- each pixel expanded to RGBA 8   -> TSprite3DImage
}

interface

uses
  System.SysUtils, System.Classes, Sprite3DSpriteSheet;

const
  //** @abstract(The most pixels ReadPng accepts in one image: 16384 by 16384.)
  //**
  //** A bad or hostile file can claim any size in its header; this stops it asking for more
  //** memory than any sprite frame needs before a byte of its image data has been read.
  PNG_MAX_PIXELS = Int64(16384) * 16384;

type
  //** @abstract(Raised when a PNG cannot be read: not a PNG, a kind the standard does not
  //** allow, too large, damaged or cut short.)
  EPngError = class(Exception);

//** @abstract(Decodes a PNG from a stream.)
//**
//** Reads from the stream's current position to the end of the PNG's @code(IEND) chunk, or
//** to the end of the stream if that comes first and the image data is complete.
//**
//** @param(AStream The stream, positioned at the PNG's signature.)
//**
//** @returns(The image, 8-bit RGBA with straight alpha, top row first.)
//**
//** @raises(EPngError If the data is not a PNG, is of a kind the standard does not allow,
//** has more than PNG_MAX_PIXELS pixels, or is damaged or cut short.)
//**
//** @raises(EOutOfMemory If the image cannot be allocated.)
function ReadPng(const AStream: TStream): TSprite3DImage;

//** @abstract(Decodes a PNG file.)
//**
//** The whole file is read into memory first, then decoded with @link(ReadPng). Safe on any
//** thread.
//**
//** @param(AFileName The file, as a full path.)
//**
//** @returns(The image, 8-bit RGBA with straight alpha, top row first.)
//**
//** @raises(EPngError As for ReadPng.)
//**
//** @raises(EFOpenError If the file cannot be opened.)
function LoadPng(const AFileName: String): TSprite3DImage;

implementation

uses
  System.ZLib, System.Math;

const
  //** The eight bytes every PNG file starts with.
  PNG_SIGNATURE: array[0..7] of Byte = (137, 80, 78, 71, 13, 10, 26, 10);

  //** Where each of the seven Adam7 passes starts, and how far apart its pixels are, across
  //** and down. A non-interlaced image is read as one pass starting at (0, 0) with steps of 1.
  ADAM7_X_START: array[0..6] of Integer = (0, 4, 0, 2, 0, 1, 0);
  ADAM7_Y_START: array[0..6] of Integer = (0, 0, 4, 0, 2, 0, 1);
  ADAM7_X_STEP: array[0..6] of Integer = (8, 8, 4, 4, 2, 2, 1);
  ADAM7_Y_STEP: array[0..6] of Integer = (8, 8, 8, 4, 4, 2, 2);

  //** The colour types the PNG standard defines.
  COLOUR_GREY = 0;
  COLOUR_RGB = 2;
  COLOUR_INDEXED = 3;
  COLOUR_GREY_ALPHA = 4;
  COLOUR_RGBA = 6;

type
  //** What the @code(IHDR), @code(PLTE) and @code(tRNS) chunks say about the image, and what
  //** follows from it: everything needed to turn a row of samples into RGBA.
  TPngHeader = record
    //** The image's width and height in pixels.
    Width, Height: Integer;
    //** Bits per sample: 1, 2, 4, 8 or 16.
    BitDepth: Integer;
    //** One of the COLOUR_ constants.
    ColourType: Integer;
    //** True for Adam7 interlacing.
    Interlaced: Boolean;
    //** Samples per pixel: 1 for grey or indexed, 2 grey with alpha, 3 RGB, 4 RGBA.
    Channels: Integer;
    //** Bits per pixel, Channels * BitDepth.
    PixelBits: Integer;
    //** The byte distance the filters look back: whole bytes per pixel, at least 1.
    FilterStep: Integer;
    //** The palette, as RGBA, for an indexed image; entries the tRNS chunk does not cover
    //** are opaque. Empty for the other colour types.
    Palette: TArray<Cardinal>;
    //** For greyscale and truecolour images, True if a tRNS chunk names a colour that is
    //** fully transparent; TransparentGrey or TransparentRed, TransparentGreen and
    //** TransparentBlue then hold it, at the image's own bit depth.
    HasTransparentColour: Boolean;
    TransparentGrey: Integer;
    TransparentRed, TransparentGreen, TransparentBlue: Integer;
  end;

// Reads a 4-byte big-endian number, raising EPngError if the stream ends
function ReadBigEndian32(const AStream: TStream): Cardinal;
var
  B: array[0..3] of Byte;
begin
  if AStream.Read(B, 4) <> 4 then
    raise EPngError.Create('The file ends in the middle of a chunk.');
  Result := (Cardinal(B[0]) shl 24) or (Cardinal(B[1]) shl 16) or
    (Cardinal(B[2]) shl 8) or Cardinal(B[3]);
end;

// A 4-byte big-endian number from a chunk's data
function BigEndian32(const AData: TBytes; const AOffset: Integer): Cardinal;
begin
  Result := (Cardinal(AData[AOffset]) shl 24) or (Cardinal(AData[AOffset + 1]) shl 16) or
    (Cardinal(AData[AOffset + 2]) shl 8) or Cardinal(AData[AOffset + 3]);
end;

// A 2-byte big-endian number from a chunk's data
function BigEndian16(const AData: TBytes; const AOffset: Integer): Integer;
begin
  Result := (Integer(AData[AOffset]) shl 8) or AData[AOffset + 1];
end;

// The bytes of one row of AWidth pixels, without its filter byte
function RowBytes(const AHeader: TPngHeader; const AWidth: Integer): Integer;
begin
  Result := Integer((Int64(AWidth) * AHeader.PixelBits + 7) div 8);
end;

// How many pixels a pass has along a side of ASize pixels, starting at
// AStart and stepping AStep
function PassSize(const ASize, AStart, AStep: Integer): Integer;
begin
  if ASize <= AStart then
    Result := 0
  else
    Result := (ASize - AStart + AStep - 1) div AStep;
end;

// Checks and records the IHDR chunk
procedure ReadHeader(const AData: TBytes; var AHeader: TPngHeader);
var
  W, H: Cardinal;
  Allowed: Boolean;
begin
  if Length(AData) <> 13 then
    raise EPngError.Create('The PNG header is the wrong length.');
  W := BigEndian32(AData, 0);
  H := BigEndian32(AData, 4);
  if (W = 0) or (H = 0) or (W > $7FFFFFFF) or (H > $7FFFFFFF) then
    raise EPngError.CreateFmt('The PNG header gives an impossible size, %u x %u.', [W, H]);
  if Int64(W) * Int64(H) > PNG_MAX_PIXELS then
    raise EPngError.CreateFmt('The image is %u x %u pixels, more than can be read.', [W, H]);
  AHeader.Width := Integer(W);
  AHeader.Height := Integer(H);
  AHeader.BitDepth := AData[8];
  AHeader.ColourType := AData[9];
  if AData[10] <> 0 then
    raise EPngError.Create('The PNG uses an unknown compression method.');
  if AData[11] <> 0 then
    raise EPngError.Create('The PNG uses an unknown filter method.');
  if AData[12] > 1 then
    raise EPngError.Create('The PNG uses an unknown interlace method.');
  AHeader.Interlaced := AData[12] = 1;
  // The bit depths the standard allows for each colour type
  case AHeader.ColourType of
    COLOUR_GREY:
      begin
        Allowed := AHeader.BitDepth in [1, 2, 4, 8, 16];
        AHeader.Channels := 1;
      end;
    COLOUR_RGB:
      begin
        Allowed := AHeader.BitDepth in [8, 16];
        AHeader.Channels := 3;
      end;
    COLOUR_INDEXED:
      begin
        Allowed := AHeader.BitDepth in [1, 2, 4, 8];
        AHeader.Channels := 1;
      end;
    COLOUR_GREY_ALPHA:
      begin
        Allowed := AHeader.BitDepth in [8, 16];
        AHeader.Channels := 2;
      end;
    COLOUR_RGBA:
      begin
        Allowed := AHeader.BitDepth in [8, 16];
        AHeader.Channels := 4;
      end;
  else
    raise EPngError.CreateFmt('The PNG has an unknown colour type, %d.',
      [AHeader.ColourType]);
  end;
  if not Allowed then
    raise EPngError.CreateFmt('The PNG has colour type %d at %d bits, which the standard ' +
      'does not allow.', [AHeader.ColourType, AHeader.BitDepth]);
  AHeader.PixelBits := AHeader.Channels * AHeader.BitDepth;
  AHeader.FilterStep := Max(1, AHeader.PixelBits div 8);
end;

// Records the PLTE chunk as opaque RGBA entries; only an indexed image needs
// it, so it is ignored for the others, which may carry one as a hint
procedure ReadPalette(const AData: TBytes; var AHeader: TPngHeader);
var
  I, Count: Integer;
begin
  if AHeader.ColourType <> COLOUR_INDEXED then
    Exit;
  if (Length(AData) = 0) or (Length(AData) mod 3 <> 0) or (Length(AData) > 256 * 3) then
    raise EPngError.Create('The PNG palette is the wrong length.');
  Count := Length(AData) div 3;
  SetLength(AHeader.Palette, Count);
  for I := 0 to Count - 1 do
    AHeader.Palette[I] := Cardinal(AData[I * 3]) or (Cardinal(AData[I * 3 + 1]) shl 8) or
      (Cardinal(AData[I * 3 + 2]) shl 16) or (Cardinal(255) shl 24);
end;

// Records the tRNS chunk: an alpha for each palette entry it covers, or the
// one colour that is fully transparent
procedure ReadTransparency(const AData: TBytes; var AHeader: TPngHeader);
var
  I, Mask: Integer;
begin
  // Samples are compared at the image's own depth; any higher bits the
  // file sets are ignored, as the standard says they should be zero
  Mask := (1 shl AHeader.BitDepth) - 1;
  case AHeader.ColourType of
    COLOUR_INDEXED:
      begin
        if Length(AHeader.Palette) = 0 then
          raise EPngError.Create('The PNG''s transparency comes before its palette.');
        // More entries than the palette has are ignored, as most readers do
        for I := 0 to Min(Length(AData), Length(AHeader.Palette)) - 1 do
          AHeader.Palette[I] := (AHeader.Palette[I] and $00FFFFFF) or
            (Cardinal(AData[I]) shl 24);
      end;
    COLOUR_GREY:
      begin
        if Length(AData) < 2 then
          raise EPngError.Create('The PNG''s transparency is the wrong length.');
        AHeader.TransparentGrey := BigEndian16(AData, 0) and Mask;
        AHeader.HasTransparentColour := True;
      end;
    COLOUR_RGB:
      begin
        if Length(AData) < 6 then
          raise EPngError.Create('The PNG''s transparency is the wrong length.');
        AHeader.TransparentRed := BigEndian16(AData, 0) and Mask;
        AHeader.TransparentGreen := BigEndian16(AData, 2) and Mask;
        AHeader.TransparentBlue := BigEndian16(AData, 4) and Mask;
        AHeader.HasTransparentColour := True;
      end;
  end;
  // Images with an alpha channel carry no tRNS chunk; one is ignored
end;

// Inflates the joined IDAT data into exactly ASize bytes of filtered rows
function Inflate(const ACompressed: TMemoryStream; const ASize: Int64): TBytes;
var
  Inflater: TZDecompressionStream;
  Done, Got: Integer;
begin
  if ASize > MaxInt then
    raise EPngError.Create('The image data is too large to read.');
  SetLength(Result, Integer(ASize));
  if ASize = 0 then
    Exit;
  ACompressed.Position := 0;
  try
    Inflater := TZDecompressionStream.Create(ACompressed);
    try
      Done := 0;
      while Done < ASize do
      begin
        Got := Inflater.Read(Result[Done], Integer(ASize) - Done);
        if Got <= 0 then
          raise EPngError.Create('The image data is cut short.');
        Inc(Done, Got);
      end;
    finally
      Inflater.Free;
    end;
  except
    on E: EPngError do
      raise;
    on E: Exception do
      raise EPngError.Create('The image data is damaged: ' + E.Message);
  end;
end;

// The Paeth predictor: whichever of left, above and above-left is nearest
// to left + above - above-left
function Paeth(const ALeft, AAbove, AAboveLeft: Integer): Integer;
var
  P, PA, PB, PC: Integer;
begin
  P := ALeft + AAbove - AAboveLeft;
  PA := Abs(P - ALeft);
  PB := Abs(P - AAbove);
  PC := Abs(P - AAboveLeft);
  if (PA <= PB) and (PA <= PC) then
    Result := ALeft
  else if PB <= PC then
    Result := AAbove
  else
    Result := AAboveLeft;
end;

// Undoes one row's filter in place. ARaw holds the row at ARowStart, its
// filter byte first; APrior is the row above already unfiltered, or all
// zeros for a pass's first row, ALength bytes long
procedure Unfilter(var ARaw: TBytes; const ARowStart, ALength: Integer;
  const APrior: TBytes; const AStep: Integer);
var
  I, Start, Left, AboveLeft: Integer;
  Filter: Byte;
begin
  Filter := ARaw[ARowStart];
  Start := ARowStart + 1;
  case Filter of
    0: ;   // None
    1:     // Sub
      for I := AStep to ALength - 1 do
        ARaw[Start + I] := Byte(ARaw[Start + I] + ARaw[Start + I - AStep]);
    2:     // Up
      for I := 0 to ALength - 1 do
        ARaw[Start + I] := Byte(ARaw[Start + I] + APrior[I]);
    3:     // Average
      for I := 0 to ALength - 1 do
      begin
        if I >= AStep then
          Left := ARaw[Start + I - AStep]
        else
          Left := 0;
        ARaw[Start + I] := Byte(ARaw[Start + I] + (Left + APrior[I]) div 2);
      end;
    4:     // Paeth
      for I := 0 to ALength - 1 do
      begin
        if I >= AStep then
        begin
          Left := ARaw[Start + I - AStep];
          AboveLeft := APrior[I - AStep];
        end
        else
        begin
          Left := 0;
          AboveLeft := 0;
        end;
        ARaw[Start + I] := Byte(ARaw[Start + I] + Paeth(Left, APrior[I], AboveLeft));
      end;
  else
    raise EPngError.CreateFmt('A row of the image has an unknown filter, %d.', [Filter]);
  end;
end;

// Sample AIndex of an unfiltered row starting at AStart, at the image's bit
// depth: for depths under 8 packed from the high bits down, for 16 two bytes
// big-endian
function Sample(const ARaw: TBytes; const AStart, AIndex, ADepth: Integer): Integer;
var
  Bit: Integer;
begin
  case ADepth of
    8:
      Result := ARaw[AStart + AIndex];
    16:
      Result := (Integer(ARaw[AStart + AIndex * 2]) shl 8) or ARaw[AStart + AIndex * 2 + 1];
  else
    begin
      Bit := AIndex * ADepth;
      Result := (ARaw[AStart + Bit div 8] shr (8 - ADepth - Bit mod 8)) and
        ((1 shl ADepth) - 1);
    end;
  end;
end;

// A sample of the image's depth scaled to 0..255: rounded down from 16
// bits, spread over the full range from fewer than 8
function To8(const AValue, ADepth: Integer): Byte;
begin
  case ADepth of
    8:
      Result := AValue;
    16:
      Result := (AValue * 255 + 32767) div 65535;
  else
    Result := AValue * 255 div ((1 shl ADepth) - 1);
  end;
end;

// Expands one unfiltered row of a pass into the image: pixel X of the row
// goes to column AXStart + X * AXStep of row AY
procedure ExpandRow(const AHeader: TPngHeader; const ARaw: TBytes; const ARowStart,
  ARowWidth, AY, AXStart, AXStep: Integer; var AImage: TSprite3DImage);
var
  X, Grey, R, G, B, A, Index, Depth, Channels: Integer;
  Colour: Cardinal;
  Dest: Integer;
begin
  Depth := AHeader.BitDepth;
  Channels := AHeader.Channels;
  for X := 0 to ARowWidth - 1 do
  begin
    Dest := ((AY * AImage.Width) + AXStart + X * AXStep) * 4;
    case AHeader.ColourType of
      COLOUR_GREY:
        begin
          Grey := Sample(ARaw, ARowStart, X, Depth);
          if AHeader.HasTransparentColour and (Grey = AHeader.TransparentGrey) then
            A := 0
          else
            A := 255;
          AImage.Pixels[Dest] := To8(Grey, Depth);
          AImage.Pixels[Dest + 1] := AImage.Pixels[Dest];
          AImage.Pixels[Dest + 2] := AImage.Pixels[Dest];
          AImage.Pixels[Dest + 3] := A;
        end;
      COLOUR_RGB:
        begin
          R := Sample(ARaw, ARowStart, X * 3, Depth);
          G := Sample(ARaw, ARowStart, X * 3 + 1, Depth);
          B := Sample(ARaw, ARowStart, X * 3 + 2, Depth);
          if AHeader.HasTransparentColour and (R = AHeader.TransparentRed) and
            (G = AHeader.TransparentGreen) and (B = AHeader.TransparentBlue) then
            A := 0
          else
            A := 255;
          AImage.Pixels[Dest] := To8(R, Depth);
          AImage.Pixels[Dest + 1] := To8(G, Depth);
          AImage.Pixels[Dest + 2] := To8(B, Depth);
          AImage.Pixels[Dest + 3] := A;
        end;
      COLOUR_INDEXED:
        begin
          Index := Sample(ARaw, ARowStart, X, Depth);
          if Index >= Length(AHeader.Palette) then
            raise EPngError.CreateFmt('A pixel uses palette entry %d, but the palette has ' +
              'only %d.', [Index, Length(AHeader.Palette)]);
          Colour := AHeader.Palette[Index];
          AImage.Pixels[Dest] := Byte(Colour);
          AImage.Pixels[Dest + 1] := Byte(Colour shr 8);
          AImage.Pixels[Dest + 2] := Byte(Colour shr 16);
          AImage.Pixels[Dest + 3] := Byte(Colour shr 24);
        end;
      COLOUR_GREY_ALPHA:
        begin
          AImage.Pixels[Dest] := To8(Sample(ARaw, ARowStart, X * Channels, Depth), Depth);
          AImage.Pixels[Dest + 1] := AImage.Pixels[Dest];
          AImage.Pixels[Dest + 2] := AImage.Pixels[Dest];
          AImage.Pixels[Dest + 3] := To8(Sample(ARaw, ARowStart, X * Channels + 1, Depth),
            Depth);
        end;
      COLOUR_RGBA:
        begin
          AImage.Pixels[Dest] := To8(Sample(ARaw, ARowStart, X * Channels, Depth), Depth);
          AImage.Pixels[Dest + 1] := To8(Sample(ARaw, ARowStart, X * Channels + 1, Depth),
            Depth);
          AImage.Pixels[Dest + 2] := To8(Sample(ARaw, ARowStart, X * Channels + 2, Depth),
            Depth);
          AImage.Pixels[Dest + 3] := To8(Sample(ARaw, ARowStart, X * Channels + 3, Depth),
            Depth);
        end;
    end;
  end;
end;

function ReadPng(const AStream: TStream): TSprite3DImage;
var
  Signature: array[0..7] of Byte;
  Header: TPngHeader;
  HaveHeader, HaveEnd: Boolean;
  ChunkLength: Cardinal;
  ChunkType: array[0..3] of AnsiChar;
  Kind: AnsiString;
  Data: TBytes;
  Compressed: TMemoryStream;
  Raw, Prior: TBytes;
  Pass, Passes, PassW, PassH, Bytes, Y, Offset: Integer;
  XStart, YStart, XStep, YStep: Integer;
  Total: Int64;
begin
  if (AStream.Read(Signature, 8) <> 8) or
    not CompareMem(@Signature[0], @PNG_SIGNATURE[0], 8) then
    raise EPngError.Create('This is not a PNG file.');
  Header := Default(TPngHeader);
  HaveHeader := False;
  HaveEnd := False;
  // Set before the try, where every path sees it: Delphi's flow analysis
  // can miss an assignment made inside one. Set again below once the
  // header says whether the image is interlaced
  Passes := 1;
  Compressed := TMemoryStream.Create;
  try
    // The chunks, up to IEND; the ones not needed for the pixels are skipped
    while not HaveEnd do
    begin
      if AStream.Position >= AStream.Size then
      begin
        // Some writers leave IEND off; the image data may still be whole,
        // which inflating it shows
        if HaveHeader and (Compressed.Size > 0) then
          Break;
        raise EPngError.Create('The file ends before the image data.');
      end;
      ChunkLength := ReadBigEndian32(AStream);
      if ChunkLength > $7FFFFFFF then
        raise EPngError.Create('A chunk of the file has an impossible length.');
      if AStream.Read(ChunkType, 4) <> 4 then
        raise EPngError.Create('The file ends in the middle of a chunk.');
      SetString(Kind, PAnsiChar(@ChunkType[0]), 4);
      if not HaveHeader and (Kind <> 'IHDR') then
        raise EPngError.Create('The PNG does not start with its header.');
      if (Kind = 'IHDR') or (Kind = 'PLTE') or (Kind = 'tRNS') then
      begin
        SetLength(Data, ChunkLength);
        if (ChunkLength > 0) and
          (AStream.Read(Data[0], Integer(ChunkLength)) <> Integer(ChunkLength)) then
          raise EPngError.Create('The file ends in the middle of a chunk.');
        if Kind = 'IHDR' then
        begin
          if HaveHeader then
            raise EPngError.Create('The PNG has two headers.');
          ReadHeader(Data, Header);
          HaveHeader := True;
        end
        else if Kind = 'PLTE' then
          ReadPalette(Data, Header)
        else
          ReadTransparency(Data, Header);
      end
      else if Kind = 'IDAT' then
      begin
        // CopyFrom raises a bare read error if the stream is short, so the
        // length is checked first, for a clearer message
        if Int64(ChunkLength) > AStream.Size - AStream.Position then
          raise EPngError.Create('The file ends in the middle of the image data.');
        if ChunkLength > 0 then
          Compressed.CopyFrom(AStream, ChunkLength);
      end
      else if Kind = 'IEND' then
        HaveEnd := True
      else
      begin
        // Any other chunk: skipped, as the pixels do not depend on it
        if AStream.Seek(Int64(ChunkLength), soCurrent) > AStream.Size then
          raise EPngError.Create('The file ends in the middle of a chunk.');
      end;
      // The CRC, not checked; zlib checks the image data itself. A missing
      // CRC after IEND is let pass, as the image is complete by then
      if HaveEnd then
        Break;
      ReadBigEndian32(AStream);
    end;

    if Compressed.Size = 0 then
      raise EPngError.Create('The PNG has no image data.');
    if (Header.ColourType = COLOUR_INDEXED) and (Length(Header.Palette) = 0) then
      raise EPngError.Create('The PNG is indexed but has no palette.');

    // How much filtered data the passes take: each row of each pass is its
    // filter byte and its samples; a pass with no pixels takes nothing
    if Header.Interlaced then
      Passes := 7
    else
      Passes := 1;
    Total := 0;
    for Pass := 0 to Passes - 1 do
    begin
      if Header.Interlaced then
      begin
        PassW := PassSize(Header.Width, ADAM7_X_START[Pass], ADAM7_X_STEP[Pass]);
        PassH := PassSize(Header.Height, ADAM7_Y_START[Pass], ADAM7_Y_STEP[Pass]);
      end
      else
      begin
        PassW := Header.Width;
        PassH := Header.Height;
      end;
      if (PassW > 0) and (PassH > 0) then
        Inc(Total, Int64(PassH) * (1 + RowBytes(Header, PassW)));
    end;
    Raw := Inflate(Compressed, Total);
  finally
    Compressed.Free;
  end;

  Result := TSprite3DImage.Create(Header.Width, Header.Height);
  Offset := 0;
  for Pass := 0 to Passes - 1 do
  begin
    if Header.Interlaced then
    begin
      XStart := ADAM7_X_START[Pass];
      YStart := ADAM7_Y_START[Pass];
      XStep := ADAM7_X_STEP[Pass];
      YStep := ADAM7_Y_STEP[Pass];
    end
    else
    begin
      XStart := 0;
      YStart := 0;
      XStep := 1;
      YStep := 1;
    end;
    PassW := PassSize(Header.Width, XStart, XStep);
    PassH := PassSize(Header.Height, YStart, YStep);
    if (PassW = 0) or (PassH = 0) then
      Continue;
    Bytes := RowBytes(Header, PassW);
    // The row above the pass's first is taken as zeros
    Prior := nil;
    SetLength(Prior, Bytes);
    for Y := 0 to PassH - 1 do
    begin
      Unfilter(Raw, Offset, Bytes, Prior, Header.FilterStep);
      ExpandRow(Header, Raw, Offset + 1, PassW, YStart + Y * YStep, XStart, XStep, Result);
      Move(Raw[Offset + 1], Prior[0], Bytes);
      Inc(Offset, 1 + Bytes);
    end;
  end;
end;

function LoadPng(const AFileName: String): TSprite3DImage;
var
  FileStream: TFileStream;
  Memory: TMemoryStream;
begin
  // Read whole, so the decoder's many small reads come from memory
  Memory := TMemoryStream.Create;
  try
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      Memory.CopyFrom(FileStream, 0);
    finally
      FileStream.Free;
    end;
    Memory.Position := 0;
    Result := ReadPng(Memory);
  finally
    Memory.Free;
  end;
end;

end.
