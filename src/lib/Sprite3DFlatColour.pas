//** @abstract(Flat colours and simple gradients for Gorilla3D materials without a shader, for
//** Metal.)
//**
//** On macOS and iOS Gorilla3D draws through Metal, where a material's SurfaceShader is not
//** supported and a plain material colour is not reliably drawn. These routines colour a
//** TGorillaDefaultMaterialSource through a small texture instead: one colour, or a blend
//** from the top of the texture to the bottom.
//**
//** Texturing must be switched on before a texture is given and before the material is first
//** drawn, or Gorilla reports "Texture0 not activated in material". So call PrepareFlatMaterial
//** once, as the material is made and before any object uses it; SetFlatColour and
//** SetFlatGradient then only change the texture's pixels.
//**
//** The unit compiles on every platform; the rest of the project uses it only where Metal is
//** in use. For the main thread only.
unit Sprite3DFlatColour;

{
  Flat colours and simple gradients for Gorilla3D materials without a
  shader, for Metal.

  On macOS and iOS Gorilla3D draws through Metal, where a material's
  SurfaceShader is not supported and a plain material colour is not
  reliably drawn. These routines colour a TGorillaDefaultMaterialSource
  through a small texture instead: one colour, or a blend from the top of
  the texture to the bottom.

  Texturing must be switched on before a texture is given and before the
  material is first drawn, or Gorilla reports "Texture0 not activated in
  material". So call PrepareFlatMaterial once, as the material is made and
  before any object uses it; SetFlatColour and SetFlatGradient then only
  change the texture's pixels.

  The unit compiles on every platform; the rest of the project uses it only
  where Metal is in use. For the main thread only.
}

interface

uses
  System.UITypes, Gorilla.Material.Default;

//** @abstract(Sets a new material up to take its colour from a texture.)
//**
//** Unlit, without specular light, with texturing on, a white Diffuse colour so the texture's
//** colours are left as they are, and a black texture to begin with. Call it before the
//** material is given to any object.
//**
//** @param(AMaterial The material, newly made.)
/// <summary>Sets a new material up to take its colour from a texture.</summary>
/// <remarks>Unlit, without specular light, with texturing on, a white Diffuse colour so the
/// texture's colours are left as they are, and a black texture to begin with. Call it before
/// the material is given to any object.</remarks>
/// <param name="AMaterial">The material, newly made.</param>
procedure PrepareFlatMaterial(const AMaterial: TGorillaDefaultMaterialSource);

//** @abstract(Colours a material prepared by PrepareFlatMaterial with one opaque colour.)
//**
//** @param(AMaterial The material.)
//**
//** @param(AColour The colour; its alpha is ignored.)
/// <summary>Colours a material prepared by PrepareFlatMaterial with one opaque
/// colour.</summary>
/// <param name="AMaterial">The material.</param>
/// <param name="AColour">The colour; its alpha is ignored.</param>
procedure SetFlatColour(const AMaterial: TGorillaDefaultMaterialSource;
  const AColour: TAlphaColor);

//** @abstract(Colours a material prepared by PrepareFlatMaterial with a blend from ATop to
//** ABottom.)
//**
//** The blend runs down the texture, from its first row to its last, in 256 steps. Alpha is
//** ignored.
//**
//** @param(AMaterial The material.)
//**
//** @param(ATop The colour at the top of the texture.)
//**
//** @param(ABottom The colour at the bottom of the texture.)
/// <summary>Colours a material prepared by PrepareFlatMaterial with a blend from ATop to
/// ABottom.</summary>
/// <remarks>The blend runs down the texture, from its first row to its last, in 256 steps.
/// Alpha is ignored.</remarks>
/// <param name="AMaterial">The material.</param>
/// <param name="ATop">The colour at the top of the texture.</param>
/// <param name="ABottom">The colour at the bottom of the texture.</param>
procedure SetFlatGradient(const AMaterial: TGorillaDefaultMaterialSource;
  const ATop, ABottom: TAlphaColor);

implementation

uses
  FMX.Graphics;

const
  SOLID_SIZE = 4;          // a solid colour needs only a few pixels
  GRADIENT_ROWS = 256;
  GRADIENT_COLUMNS = 4;

// Fills a new Columns x Rows texture from ATop down to ABottom and gives it
// to AMaterial, which keeps its own copy
procedure FillTexture(const AMaterial: TGorillaDefaultMaterialSource;
  const AColumns, ARows: Integer; const ATop, ABottom: TAlphaColor);
var
  Bitmap: TBitmap;
  Data: TBitmapData;
  T, B, C: TAlphaColorRec;
  X, Y: Integer;
  K: Single;
begin
  T := TAlphaColorRec(ATop);
  B := TAlphaColorRec(ABottom);
  Bitmap := TBitmap.Create(AColumns, ARows);
  try
    if Bitmap.Map(TMapAccess.Write, Data) then
    try
      for Y := 0 to ARows - 1 do
      begin
        if ARows > 1 then
          K := Y / (ARows - 1)
        else
          K := 0;
        C.R := Round(T.R + (B.R - T.R) * K);
        C.G := Round(T.G + (B.G - T.G) * K);
        C.B := Round(T.B + (B.B - T.B) * K);
        C.A := 255;
        for X := 0 to AColumns - 1 do
          Data.SetPixel(X, Y, C.Color);
      end;
    finally
      Bitmap.Unmap(Data);
    end;
    AMaterial.Texture := Bitmap;
  finally
    Bitmap.Free;
  end;
end;

procedure PrepareFlatMaterial(const AMaterial: TGorillaDefaultMaterialSource);
begin
  AMaterial.UseLighting := False;
  AMaterial.UseSpecular := False;
  // On before any texture is given, so the material is built with one
  AMaterial.UseTexturing := True;
  AMaterial.Diffuse := TAlphaColors.White;
  FillTexture(AMaterial, SOLID_SIZE, SOLID_SIZE, TAlphaColors.Black, TAlphaColors.Black);
end;

procedure SetFlatColour(const AMaterial: TGorillaDefaultMaterialSource;
  const AColour: TAlphaColor);
begin
  FillTexture(AMaterial, SOLID_SIZE, SOLID_SIZE, AColour, AColour);
end;

procedure SetFlatGradient(const AMaterial: TGorillaDefaultMaterialSource;
  const ATop, ABottom: TAlphaColor);
begin
  FillTexture(AMaterial, GRADIENT_COLUMNS, GRADIENT_ROWS, ATop, ABottom);
end;

end.
