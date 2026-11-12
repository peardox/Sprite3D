//** @abstract(Loads group icons, PNG or SVG, as bitmaps of a given size.)
//**
//** A PNG is loaded as it is. An SVG is drawn here, as FMX has no SVG reader of its own: the
//** @code(d) of every @code(path) element is read as FMX path data, in the units of the
//** file's @code(viewBox), and filled in one colour, so it suits icons drawn as filled
//** shapes, such as those of game-icons.net, and not those drawn as strokes. A path that
//** covers the whole view box exactly, the background square some icon sets put first, is
//** left out, so the icon's background is transparent.
//**
//** The unit knows nothing of the application. Bitmaps are drawn with FMX's canvas, so call
//** it from the main thread.
unit Sprite3DGroupIcons;

{
  Loads group icons, PNG or SVG, as bitmaps of a given size.

  A PNG is loaded as it is. An SVG is drawn here, as FMX has no SVG reader
  of its own: the d of every path element is read as FMX path data, in the
  units of the file's viewBox, and filled in one colour, so it suits icons
  drawn as filled shapes, such as those of game-icons.net, and not those
  drawn as strokes. A path that covers the whole view box exactly, the
  background square some icon sets put first, is left out, so the icon's
  background is transparent.

  The unit knows nothing of the application. Bitmaps are drawn with FMX's
  canvas, so call it from the main thread.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, FMX.Graphics;

const
  //** @abstract(The file extensions LoadGroupIcon reads, in lower case.)
  GROUP_ICON_EXTENSIONS: array[0..1] of String = ('.svg', '.png');

//** @abstract(Whether LoadGroupIcon reads AFileName, judged by its extension.)
//**
//** @param(AFileName A file name or path.)
//**
//** @returns(True for @code(.svg) and @code(.png), in any case.)
function IsGroupIconFile(const AFileName: String): Boolean;

//** @abstract(Loads an icon file as a bitmap.)
//**
//** @param(AFileName The PNG or SVG file.)
//**
//** @param(ASize For an SVG, the bitmap's width and height in pixels; a PNG keeps its own.)
//**
//** @param(AColour For an SVG, the colour its shapes are filled with.)
//**
//** @returns(The bitmap, the caller's to free; nil if the file cannot be read or has nothing
//** to draw, never an exception.)
function LoadGroupIcon(const AFileName: String; const ASize: Integer;
  const AColour: TAlphaColor): TBitmap;

implementation

uses
  System.IOUtils, System.RegularExpressions, System.Math;

function IsGroupIconFile(const AFileName: String): Boolean;
var
  Ext: String;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := False;
  for var Known in GROUP_ICON_EXTENSIONS do
    if Ext = Known then
      Exit(True);
end;

//** @abstract(The four numbers of an SVG's viewBox, or of its width and height.)
//**
//** @param(AText The SVG's text.)
//**
//** @param(ABox On return, the view box; 0 0 512 512 if the file says nothing.)
procedure ReadViewBox(const AText: String; out ABox: TRectF);
var
  Match: TMatch;
  Parts: TArray<String>;
  Values: array[0..3] of Single;
  Invariant: TFormatSettings;
begin
  ABox := TRectF.Create(0, 0, 512, 512);
  Invariant := TFormatSettings.Invariant;
  Match := TRegEx.Match(AText, 'viewBox\s*=\s*"([^"]+)"', [roIgnoreCase]);
  if not Match.Success then
    Exit;
  Parts := TRegEx.Split(Trim(Match.Groups[1].Value), '[\s,]+');
  if Length(Parts) <> 4 then
    Exit;
  for var I := 0 to 3 do
    if not TryStrToFloat(Parts[I], Values[I], Invariant) then
      Exit;
  if (Values[2] <= 0) or (Values[3] <= 0) then
    Exit;
  ABox := TRectF.Create(Values[0], Values[1], Values[0] + Values[2], Values[1] + Values[3]);
end;

//** @abstract(Draws an SVG's filled paths into a bitmap ASize square.)
//**
//** @param(AFileName The SVG file.)
//**
//** @param(ASize The bitmap's width and height in pixels.)
//**
//** @param(AColour The fill.)
//**
//** @returns(The bitmap; nil if there was nothing to draw.)
function RenderSvg(const AFileName: String; const ASize: Integer;
  const AColour: TAlphaColor): TBitmap;
var
  Text: String;
  View, Bounds: TRectF;
  Path: TPathData;
  Scale: Single;
  Drawn: Boolean;
begin
  Result := nil;
  Text := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  ReadViewBox(Text, View);
  Scale := ASize / Max(View.Width, View.Height);
  Drawn := False;
  Result := TBitmap.Create(ASize, ASize);
  try
    Result.Clear(TAlphaColors.Null);
    Path := TPathData.Create;
    try
      if Result.Canvas.BeginScene then
        try
          Result.Canvas.Fill.Kind := TBrushKind.Solid;
          Result.Canvas.Fill.Color := AColour;
          for var Match in TRegEx.Matches(Text, '<path\b[^>]*?\sd\s*=\s*"([^"]+)"',
            [roIgnoreCase, roSingleLine]) do
          begin
            Path.Data := Match.Groups[1].Value;
            if Path.IsEmpty then
              Continue;
            // A background square over the whole view box is left out
            Bounds := Path.GetBounds;
            if SameValue(Bounds.Left, View.Left, 0.5) and SameValue(Bounds.Top, View.Top, 0.5)
              and SameValue(Bounds.Right, View.Right, 0.5) and
              SameValue(Bounds.Bottom, View.Bottom, 0.5) and (Path.Count <= 6) then
              Continue;
            // View box units to pixels, centred if it is not square
            Path.Translate(-View.Left, -View.Top);
            Path.Scale(Scale, Scale);
            Path.Translate((ASize - View.Width * Scale) / 2, (ASize - View.Height * Scale) / 2);
            Result.Canvas.FillPath(Path, 1);
            Drawn := True;
          end;
        finally
          Result.Canvas.EndScene;
        end;
    finally
      Path.Free;
    end;
    if not Drawn then
      FreeAndNil(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function LoadGroupIcon(const AFileName: String; const ASize: Integer;
  const AColour: TAlphaColor): TBitmap;
begin
  Result := nil;
  try
    if (ASize <= 0) or not TFile.Exists(AFileName) then
      Exit;
    if SameText(ExtractFileExt(AFileName), '.svg') then
      Result := RenderSvg(AFileName, ASize, AColour)
    else if SameText(ExtractFileExt(AFileName), '.png') then
      Result := TBitmap.CreateFromFile(AFileName);
  except
    FreeAndNil(Result);
  end;
end;

end.
