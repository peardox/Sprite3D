//** @abstract(Resamples RGBA pixels to another size with a choice of filters, for overscanned
//** grabs.)
//**
//** ResamplePixels scales an image held as RGBA bytes, four to a pixel, rows one after
//** another, with one of the filters in TSprite3DResampleFilter. It is meant for overscan:
//** rendering a grab at a whole multiple of its size and scaling it back down, which
//** smooths edges and fine detail far better than the renderer's own anti-aliasing. It
//** works in either direction and for any pair of sizes, though shrinking is what it is
//** for.
//**
//** The pixels must be premultiplied, colour already multiplied by alpha, as Sprite3D's
//** grabs and FMX bitmaps hold them. Filtering premultiplied values keeps transparent pixels
//** from bleeding their hidden colour into the edges round them. Filters with negative
//** lobes can ring; each result is clamped to 0 to 255, and each colour to its alpha, so it
//** stays a valid premultiplied pixel.
//**
//** The work is separable: each row is resampled across, into a buffer of single-precision
//** values the new width by the old height, then each column down. A filter reaches a
//** number of source pixels that grows with the scale, so shrinking by 16 with Lanczos 3
//** reads 96 source pixels each way for every result.
//**
//** @preformatted(
//** Filter      reach in output pixels   character
//** Box         0.5                      area average: exact for whole multiples
//** Bilinear    1                        tent: soft
//** CatmullRom  2                        bicubic: sharp, slight ringing
//** Mitchell    2                        bicubic: balanced
//** Lanczos3    3                        windowed sinc: sharpest, most ringing
//** )
unit Sprite3DResample;

{
  Resamples RGBA pixels to another size with a choice of filters, for
  overscanned grabs.

  ResamplePixels scales an image held as RGBA bytes, four to a pixel, rows
  one after another, with one of the filters in TSprite3DResampleFilter. It
  is meant for overscan: rendering a grab at a whole multiple of its size and
  scaling it back down, which smooths edges and fine detail far better than
  the renderer's own anti-aliasing. It works in either direction and for any
  pair of sizes, though shrinking is what it is for.

  The pixels must be premultiplied, colour already multiplied by alpha, as
  Sprite3D's grabs and FMX bitmaps hold them. Filtering premultiplied values
  keeps transparent pixels from bleeding their hidden colour into the edges
  round them. Filters with negative lobes can ring; each result is clamped
  to 0 to 255, and each colour to its alpha, so it stays a valid
  premultiplied pixel.

  The work is separable: each row is resampled across, into a buffer of
  single-precision values the new width by the old height, then each column
  down. A filter reaches a number of source pixels that grows with the
  scale, so shrinking by 16 with Lanczos 3 reads 96 source pixels each way
  for every result.

    Filter      reach in output pixels   character
    Box         0.5                      area average: exact for whole multiples
    Bilinear    1                        tent: soft
    CatmullRom  2                        bicubic: sharp, slight ringing
    Mitchell    2                        bicubic: balanced
    Lanczos3    3                        windowed sinc: sharpest, most ringing
}

interface

uses
  System.SysUtils;

type
  //** @abstract(The filter ResamplePixels scales with.)
  /// <summary>The filter ResamplePixels scales with.</summary>
  TSprite3DResampleFilter = (
    //** @abstract(Area average: each result is the mean of the source pixels it covers.)
    //**
    //** Exact for a whole-number scale, such as overscan, with no ringing.
    /// <summary>Area average: each result is the mean of the source pixels it
    /// covers.</summary>
    /// <remarks>Exact for a whole-number scale, such as overscan, with no ringing.</remarks>
    rfBox,
    //** @abstract(Tent filter, reaching one output pixel each way: soft.)
    /// <summary>Tent filter, reaching one output pixel each way: soft.</summary>
    rfBilinear,
    //** @abstract(Catmull-Rom cubic, reaching two output pixels each way: sharp, with slight
    //** ringing.)
    /// <summary>Catmull-Rom cubic, reaching two output pixels each way: sharp, with slight
    /// ringing.</summary>
    rfCatmullRom,
    //** @abstract(Mitchell-Netravali cubic, B = C = 1/3, reaching two output pixels each way:
    //** a balance of sharpness and ringing.)
    /// <summary>Mitchell-Netravali cubic, B = C = 1/3, reaching two output pixels each way: a
    /// balance of sharpness and ringing.</summary>
    rfMitchell,
    //** @abstract(Lanczos windowed sinc, reaching three output pixels each way: the sharpest,
    //** with the most ringing.)
    /// <summary>Lanczos windowed sinc, reaching three output pixels each way: the sharpest,
    /// with the most ringing.</summary>
    rfLanczos3);

//** @abstract(The name a filter is shown by, such as @code('Box @(area average@)').)
//**
//** @param(AFilter The filter.)
//**
//** @returns(Its name for a drop-down list.)
/// <summary>The name a filter is shown by, such as <c>'Box (area average)'</c>.</summary>
/// <param name="AFilter">The filter.</param>
/// <returns>Its name for a drop-down list.</returns>
function ResampleFilterName(const AFilter: TSprite3DResampleFilter): String;

//** @abstract(Scales premultiplied RGBA pixels to a new size with AFilter.)
//**
//** ASource holds ASourceWidth by ASourceHeight pixels, four bytes each in the order R, G, B,
//** A, rows one after another, with colour already multiplied by alpha. Which way up the
//** rows run does not matter, as the result keeps the same order. Every result is clamped
//** to 0 to 255 and each colour to its alpha. Source pixels past an edge count as the edge
//** pixel. Blocks while it works; any thread, as it touches nothing shared.
//**
//** @param(ASource The pixels to scale.)
//**
//** @param(ASourceWidth The source's width in pixels; at least 1.)
//**
//** @param(ASourceHeight The source's height in pixels; at least 1.)
//**
//** @param(AWidth The result's width in pixels; at least 1.)
//**
//** @param(AHeight The result's height in pixels; at least 1.)
//**
//** @param(AFilter The filter to scale with.)
//**
//** @returns(AWidth by AHeight pixels in the same layout; a copy of ASource if the sizes are
//** the same.)
//**
//** @raises(EArgumentException If a size is less than 1 or ASource is not ASourceWidth by
//** ASourceHeight pixels long.)
/// <summary>Scales premultiplied RGBA pixels to a new size with AFilter.</summary>
/// <remarks>ASource holds ASourceWidth by ASourceHeight pixels, four bytes each in the order
/// R, G, B, A, rows one after another, with colour already multiplied by alpha. Which way up
/// the rows run does not matter, as the result keeps the same order. Every result is clamped
/// to 0 to 255 and each colour to its alpha. Source pixels past an edge count as the edge
/// pixel. Blocks while it works; any thread, as it touches nothing shared.</remarks>
/// <param name="ASource">The pixels to scale.</param>
/// <param name="ASourceWidth">The source's width in pixels; at least 1.</param>
/// <param name="ASourceHeight">The source's height in pixels; at least 1.</param>
/// <param name="AWidth">The result's width in pixels; at least 1.</param>
/// <param name="AHeight">The result's height in pixels; at least 1.</param>
/// <param name="AFilter">The filter to scale with.</param>
/// <returns>AWidth by AHeight pixels in the same layout; a copy of ASource if the sizes are the
/// same.</returns>
/// <exception cref="EArgumentException">If a size is less than 1 or ASource is not ASourceWidth
/// by ASourceHeight pixels long.</exception>
function ResamplePixels(const ASource: TBytes; const ASourceWidth, ASourceHeight, AWidth,
  AHeight: Integer; const AFilter: TSprite3DResampleFilter): TBytes;

implementation

uses
  System.Math;

type
  // The source pixels one result reads along one direction, and how much
  // of each: Weights[K] is for source pixel First + K, clamped to the edge
  TContribution = record
    First: Integer;
    Weights: TArray<Single>;
  end;

function ResampleFilterName(const AFilter: TSprite3DResampleFilter): String;
begin
  case AFilter of
    rfBox: Result := 'Box (area average)';
    rfBilinear: Result := 'Bilinear';
    rfCatmullRom: Result := 'Bicubic (Catmull-Rom)';
    rfMitchell: Result := 'Bicubic (Mitchell)';
  else
    Result := 'Lanczos 3';
  end;
end;

// How far each filter reaches, in output pixels
function FilterSupport(const AFilter: TSprite3DResampleFilter): Double;
begin
  case AFilter of
    rfBox: Result := 0.5;
    rfBilinear: Result := 1;
    rfCatmullRom, rfMitchell: Result := 2;
  else
    Result := 3;
  end;
end;

function Sinc(const X: Double): Double;
begin
  if Abs(X) < 1E-8 then
    Result := 1
  else
    Result := Sin(Pi * X) / (Pi * X);
end;

// The cubic family of Mitchell and Netravali, for B and C
function Cubic(const X, B, C: Double): Double;
var
  T: Double;
begin
  T := Abs(X);
  if T < 1 then
    Result := ((12 - 9 * B - 6 * C) * T * T * T + (-18 + 12 * B + 6 * C) * T * T +
      (6 - 2 * B)) / 6
  else if T < 2 then
    Result := ((-B - 6 * C) * T * T * T + (6 * B + 30 * C) * T * T +
      (-12 * B - 48 * C) * T + (8 * B + 24 * C)) / 6
  else
    Result := 0;
end;

// The filter's weight at X output pixels from the centre
function FilterWeight(const AFilter: TSprite3DResampleFilter; const X: Double): Double;
begin
  case AFilter of
    rfBox:
      if (X >= -0.5) and (X < 0.5) then
        Result := 1
      else
        Result := 0;
    rfBilinear: Result := Max(0.0, 1 - Abs(X));
    rfCatmullRom: Result := Cubic(X, 0, 0.5);
    rfMitchell: Result := Cubic(X, 1 / 3, 1 / 3);
  else
    if Abs(X) < 3 then
      Result := Sinc(X) * Sinc(X / 3)
    else
      Result := 0;
  end;
end;

// The contributions for each of ADestination results from ASource pixels.
// Shrinking, the filter is widened by the scale so every source pixel
// counts; enlarging, it stays its own width. Weights are made to add up
// to 1, so flat areas stay exactly flat.
function BuildContributions(const ASource, ADestination: Integer;
  const AFilter: TSprite3DResampleFilter): TArray<TContribution>;
var
  Scale, Width, Reach, Center, Sum: Double;
  I, J, Lo, Hi, Nearest: Integer;
  W: TArray<Double>;
begin
  SetLength(Result, ADestination);
  Scale := ASource / ADestination;
  Width := Max(Scale, 1);
  Reach := FilterSupport(AFilter) * Width;
  for I := 0 to ADestination - 1 do
  begin
    Center := (I + 0.5) * Scale;   // in source pixels, from the left edge
    Lo := Floor(Center - Reach);
    Hi := Ceil(Center + Reach);
    SetLength(W, Hi - Lo + 1);
    Sum := 0;
    for J := Lo to Hi do
    begin
      W[J - Lo] := FilterWeight(AFilter, (J + 0.5 - Center) / Width);
      Sum := Sum + W[J - Lo];
    end;
    Result[I].First := Lo;
    SetLength(Result[I].Weights, Length(W));
    if Abs(Sum) < 1E-12 then
    begin
      // Nothing fell inside the filter: take the nearest source pixel
      Nearest := Floor(Center);
      for J := Lo to Hi do
        if J = Nearest then
          Result[I].Weights[J - Lo] := 1
        else
          Result[I].Weights[J - Lo] := 0;
    end
    else
      for J := 0 to High(W) do
        Result[I].Weights[J] := W[J] / Sum;
  end;
end;

function ResamplePixels(const ASource: TBytes; const ASourceWidth, ASourceHeight, AWidth,
  AHeight: Integer; const AFilter: TSprite3DResampleFilter): TBytes;
var
  Across, Down: TArray<TContribution>;
  Temp: TArray<Single>;
  X, Y, K, S, Index, A: Integer;
  W, R, G, B, Al: Single;
  Row: PByte;
begin
  if (ASourceWidth < 1) or (ASourceHeight < 1) or (AWidth < 1) or (AHeight < 1) then
    raise EArgumentException.Create('Every size must be at least 1 pixel.');
  if Length(ASource) <> ASourceWidth * ASourceHeight * 4 then
    raise EArgumentException.Create('The pixels do not match the size given.');
  if (ASourceWidth = AWidth) and (ASourceHeight = AHeight) then
    Exit(Copy(ASource));

  Across := BuildContributions(ASourceWidth, AWidth, AFilter);
  Down := BuildContributions(ASourceHeight, AHeight, AFilter);

  // Across: every source row to the new width
  SetLength(Temp, AWidth * ASourceHeight * 4);
  for Y := 0 to ASourceHeight - 1 do
  begin
    Row := @ASource[Y * ASourceWidth * 4];
    for X := 0 to AWidth - 1 do
    begin
      R := 0;
      G := 0;
      B := 0;
      Al := 0;
      for K := 0 to High(Across[X].Weights) do
      begin
        W := Across[X].Weights[K];
        if W = 0 then
          Continue;
        S := EnsureRange(Across[X].First + K, 0, ASourceWidth - 1) * 4;
        R := R + W * Row[S];
        G := G + W * Row[S + 1];
        B := B + W * Row[S + 2];
        Al := Al + W * Row[S + 3];
      end;
      Index := (Y * AWidth + X) * 4;
      Temp[Index] := R;
      Temp[Index + 1] := G;
      Temp[Index + 2] := B;
      Temp[Index + 3] := Al;
    end;
  end;

  // Down: every column to the new height, clamped to valid premultiplied
  // bytes
  SetLength(Result, AWidth * AHeight * 4);
  for Y := 0 to AHeight - 1 do
    for X := 0 to AWidth - 1 do
    begin
      R := 0;
      G := 0;
      B := 0;
      Al := 0;
      for K := 0 to High(Down[Y].Weights) do
      begin
        W := Down[Y].Weights[K];
        if W = 0 then
          Continue;
        S := (EnsureRange(Down[Y].First + K, 0, ASourceHeight - 1) * AWidth + X) * 4;
        R := R + W * Temp[S];
        G := G + W * Temp[S + 1];
        B := B + W * Temp[S + 2];
        Al := Al + W * Temp[S + 3];
      end;
      Index := (Y * AWidth + X) * 4;
      A := EnsureRange(Round(Al), 0, 255);
      Result[Index] := EnsureRange(Round(R), 0, A);
      Result[Index + 1] := EnsureRange(Round(G), 0, A);
      Result[Index + 2] := EnsureRange(Round(B), 0, A);
      Result[Index + 3] := A;
    end;
end;

end.
