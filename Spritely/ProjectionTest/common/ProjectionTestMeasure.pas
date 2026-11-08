//** @abstract(Measures how far a picture moved between two renders, so a test can say for
//** itself whether a change to the matrices shifted the picture as it should.)
//**
//** A lens shift or rise moves the whole picture rigidly: every pixel by the same amount, new
//** parts coming in at one edge. MeasureShift finds that move from the edges in the two
//** pictures (summed down the columns for across, along the rows for up and down, so a model
//** on a plain background still gives a clear answer), then checks that the second picture,
//** moved back by it, matches the first: if not, something other than a shift happened (a
//** zoom, a turn, a change of lighting).
unit ProjectionTestMeasure;

{
  How far a picture moved between two renders: edge profiles down the
  columns and along the rows give the move across and up / down; the
  second picture moved back must then match the first, or it was not a
  plain shift.
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math, FMX.Graphics;

const
  //** @abstract(Mean grey difference, 0 to 255, under which two pictures count as the same.)
  PEARDOX_SHIFT_SAME = 0.1;
  //** @abstract(What is left after moving back, as a share of the difference before, above
  //** which the change is not a plain shift.)
  PEARDOX_SHIFT_MAX_RESIDUAL = 0.4;
  //** @abstract(Pixels a measured shift may be off and still count as the expected one, or this
  //** share of it if larger: PEARDOX_SHIFT_TOLERANCE_SHARE.)
  PEARDOX_SHIFT_TOLERANCE_PX = 2;
  //** @abstract(Share of the expected shift it may be off by; see PEARDOX_SHIFT_TOLERANCE_PX.)
  PEARDOX_SHIFT_TOLERANCE_SHARE = 0.1;

type
  //** @abstract(A picture as greys, 0 to 255, row by row from the top.)
  TPeardoxGreyPicture = record
    //** @abstract(Pixels across.)
    Width: Integer;
    //** @abstract(Pixels down.)
    Height: Integer;
    //** @abstract(Width x Height greys.)
    Pixels: TArray<Single>;
    //** @abstract(Whether there is a picture.)
    //**
    //** @returns(True if it has pixels.)
    function Valid: Boolean;
    //** @abstract(Makes the greys from a bitmap: the mean of red, green and blue.)
    //**
    //** @param(ABitmap The bitmap; nil or empty gives no picture.)
    //** @returns(The picture.)
    class function FromBitmap(ABitmap: TBitmap): TPeardoxGreyPicture; static;
  end;

  //** @abstract(What a measured move says.)
  TPeardoxShiftVerdict = (
    //** One of the pictures is missing or they differ in size
    svNoPicture,
    //** The pictures are the same
    svNoChange,
    //** Moved by the expected amount, the expected way
    svExpected,
    //** Moved by the expected amount, the other way
    svWrongWay,
    //** Moved, but not by the expected amount
    svWrongAmount,
    //** Changed, but not by a plain move
    svNotAShift);

  //** @abstract(A measured move and what it says.)
  TPeardoxShiftResult = record
    //** @abstract(Measured move across, pixels, + right.)
    DX: Single;
    //** @abstract(Measured move up and down, pixels, + down.)
    DY: Single;
    //** @abstract(Expected move across, pixels, + right.)
    ExpectedDX: Single;
    //** @abstract(Expected move up and down, pixels, + down.)
    ExpectedDY: Single;
    //** @abstract(Mean grey difference between the pictures before moving back, 0 to 255.)
    Change: Single;
    //** @abstract(The difference left after moving back, as a share of Change.)
    Residual: Single;
    //** @abstract(What it says.)
    Verdict: TPeardoxShiftVerdict;
    //** @abstract(One line for the log.)
    //**
    //** @returns(The verdict in capitals, the move, the expected move and the residual.)
    function Text: string;
  end;

//** @abstract(Measures how far a picture moved from a reference.)
//**
//** @param(ARef The picture before.)
//** @param(APic The picture after.)
//** @param(AExpectedDX The move expected across, pixels, + right.)
//** @param(AExpectedDY The move expected up and down, pixels, + down.)
//** @returns(The move and what it says.)
function MeasureShift(const ARef, APic: TPeardoxGreyPicture;
  AExpectedDX, AExpectedDY: Single): TPeardoxShiftResult;

//** @abstract(The mean grey difference between two pictures.)
//**
//** @param(A One picture.)
//** @param(B The other, the same size.)
//** @returns(0 to 255; -1 if they cannot be compared.)
function PictureDifference(const A, B: TPeardoxGreyPicture): Single;

//** @abstract(The name of a verdict, for the log.)
//**
//** @param(AVerdict The verdict.)
//** @returns(The name, in capitals where it matters.)
function VerdictName(AVerdict: TPeardoxShiftVerdict): string;

implementation

function VerdictName(AVerdict: TPeardoxShiftVerdict): string;
begin
  case AVerdict of
    svNoPicture: Result := 'no picture to compare';
    svNoChange: Result := 'NO CHANGE';
    svExpected: Result := 'SHIFTS AS EXPECTED';
    svWrongWay: Result := 'SHIFTS THE WRONG WAY';
    svWrongAmount: Result := 'MOVES, BUT NOT BY THE EXPECTED AMOUNT';
    svNotAShift: Result := 'CHANGES, BUT NOT A PLAIN SHIFT';
  else
    Result := '?';
  end;
end;

{ TPeardoxGreyPicture }

function TPeardoxGreyPicture.Valid: Boolean;
begin
  Result := (Width > 2) and (Height > 2) and (Length(Pixels) = Width * Height);
end;

class function TPeardoxGreyPicture.FromBitmap(ABitmap: TBitmap): TPeardoxGreyPicture;
var
  Data: TBitmapData;
  X, Y, Step: Integer;
  Row: PByte;
  C: TAlphaColor;
begin
  Result.Width := 0;
  Result.Height := 0;
  Result.Pixels := nil;
  if (ABitmap = nil) or ABitmap.IsEmpty then
    Exit;
  if not ABitmap.Map(TMapAccess.Read, Data) then
    Exit;
  try
    Result.Width := Data.Width;
    Result.Height := Data.Height;
    SetLength(Result.Pixels, Data.Width * Data.Height);
    Step := Data.BytesPerPixel;
    for Y := 0 to Data.Height - 1 do
      if Step = 4 then
      begin
        // BGRA or RGBA: the first three bytes are the colours either way
        Row := PByte(Data.GetScanline(Y));
        for X := 0 to Data.Width - 1 do
        begin
          Result.Pixels[Y * Data.Width + X] := (Row[0] + Row[1] + Row[2]) / 3;
          Inc(Row, 4);
        end;
      end
      else
        for X := 0 to Data.Width - 1 do
        begin
          C := Data.GetPixel(X, Y);
          Result.Pixels[Y * Data.Width + X] :=
            (TAlphaColorRec(C).R + TAlphaColorRec(C).G + TAlphaColorRec(C).B) / 3;
        end;
  finally
    ABitmap.Unmap(Data);
  end;
end;

//** @abstract(Edge strength summed down each column and along each row.)
//**
//** @param(A The picture.)
//** @param(ACols One sum per column.)
//** @param(ARows One sum per row.)
procedure EdgeProfiles(const A: TPeardoxGreyPicture; out ACols, ARows: TArray<Single>);
var
  X, Y, W: Integer;
  G: Single;
begin
  W := A.Width;
  SetLength(ACols, A.Width);
  SetLength(ARows, A.Height);
  for X := 0 to A.Width - 1 do
    ACols[X] := 0;
  for Y := 0 to A.Height - 1 do
    ARows[Y] := 0;
  for Y := 1 to A.Height - 1 do
    for X := 1 to A.Width - 1 do
    begin
      G := Abs(A.Pixels[Y * W + X] - A.Pixels[Y * W + X - 1]) +
        Abs(A.Pixels[Y * W + X] - A.Pixels[(Y - 1) * W + X]);
      ACols[X] := ACols[X] + G;
      ARows[Y] := ARows[Y] + G;
    end;
end;

//** @abstract(How badly one profile matches another moved by S.)
//**
//** Over both profiles' whole length, nought beyond their ends: what moves out of the picture
//** counts against the move, so laying empty background on empty background cannot win.
//**
//** @param(A The first.)
//** @param(B The second.)
//** @param(S The move: B[I + S] is compared with A[I].)
//** @returns(The summed difference.)
function ProfileCost(const A, B: TArray<Single>; S: Integer): Double;
var
  I, J, N: Integer;
  X, Y: Single;
  Sum: Double;
begin
  N := Length(A);
  Sum := 0;
  for I := Min(0, -S) to Max(N, N - S) - 1 do
  begin
    if (I >= 0) and (I < N) then
      X := A[I]
    else
      X := 0;
    J := I + S;
    if (J >= 0) and (J < N) then
      Y := B[J]
    else
      Y := 0;
    Sum := Sum + Abs(X - Y);
  end;
  Result := Sum;
end;

//** @abstract(The move that best lays one profile on the other, to a fraction of a pixel.)
//**
//** @param(A The profile before.)
//** @param(B The profile after.)
//** @returns(The move, + towards higher indices.)
function ProfileShift(const A, B: TArray<Single>): Single;
var
  S, Best, Limit: Integer;
  Cost, BestCost, CM, CP, Denom: Double;
begin
  Limit := (Length(A) * 3) div 4;
  Best := 0;
  BestCost := ProfileCost(A, B, 0);
  for S := -Limit to Limit do
  begin
    Cost := ProfileCost(A, B, S);
    if Cost < BestCost then
    begin
      BestCost := Cost;
      Best := S;
    end;
  end;
  Result := Best;
  // A parabola through the best and its neighbours gives the fraction
  if (Best > -Limit) and (Best < Limit) then
  begin
    CM := ProfileCost(A, B, Best - 1);
    CP := ProfileCost(A, B, Best + 1);
    Denom := CM - 2 * BestCost + CP;
    if Denom > 0 then
      Result := Best + 0.5 * (CM - CP) / Denom;
  end;
end;

//** @abstract(The mean grey difference between a picture and another moved by (DX, DY).)
//**
//** @param(A The picture before.)
//** @param(B The picture after.)
//** @param(DX Move across: B(X + DX, Y + DY) is compared with A(X, Y).)
//** @param(DY Move down.)
//** @returns(The mean over the overlap, 0 to 255; MaxSingle with nothing overlapping.)
function MovedDifference(const A, B: TPeardoxGreyPicture; DX, DY: Integer): Single;
var
  X, Y, W: Integer;
  Sum: Double;
  Count: Int64;
begin
  W := A.Width;
  Sum := 0;
  Count := 0;
  for Y := Max(0, -DY) to Min(A.Height - 1, A.Height - 1 - DY) do
    for X := Max(0, -DX) to Min(W - 1, W - 1 - DX) do
    begin
      Sum := Sum + Abs(A.Pixels[Y * W + X] - B.Pixels[(Y + DY) * W + X + DX]);
      Inc(Count);
    end;
  if Count = 0 then
    Result := MaxSingle
  else
    Result := Sum / Count;
end;

function PictureDifference(const A, B: TPeardoxGreyPicture): Single;
begin
  if not A.Valid or not B.Valid or (A.Width <> B.Width) or (A.Height <> B.Height) then
    Result := -1
  else
    Result := MovedDifference(A, B, 0, 0);
end;

//** @abstract(Whether a measured move is the expected one.)
//**
//** @param(AMeasured The move measured.)
//** @param(AExpected The move expected.)
//** @returns(True if within PEARDOX_SHIFT_TOLERANCE_PX, or PEARDOX_SHIFT_TOLERANCE_SHARE of it.)
function Near(AMeasured, AExpected: Single): Boolean;
var
  Tolerance: Single;
begin
  Tolerance := PEARDOX_SHIFT_TOLERANCE_SHARE * Abs(AExpected);
  if Tolerance < PEARDOX_SHIFT_TOLERANCE_PX then
    Tolerance := PEARDOX_SHIFT_TOLERANCE_PX;
  Result := Abs(AMeasured - AExpected) <= Tolerance;
end;

function MeasureShift(const ARef, APic: TPeardoxGreyPicture;
  AExpectedDX, AExpectedDY: Single): TPeardoxShiftResult;
var
  ColsA, RowsA, ColsB, RowsB: TArray<Single>;
  Moved: Single;
begin
  Result.DX := 0;
  Result.DY := 0;
  Result.ExpectedDX := AExpectedDX;
  Result.ExpectedDY := AExpectedDY;
  Result.Change := 0;
  Result.Residual := 0;
  Result.Verdict := svNoPicture;
  Result.Change := PictureDifference(ARef, APic);
  if Result.Change < 0 then
    Exit;
  if Result.Change < PEARDOX_SHIFT_SAME then
  begin
    Result.Verdict := svNoChange;
    Exit;
  end;
  EdgeProfiles(ARef, ColsA, RowsA);
  EdgeProfiles(APic, ColsB, RowsB);
  Result.DX := ProfileShift(ColsA, ColsB);
  Result.DY := ProfileShift(RowsA, RowsB);
  Moved := MovedDifference(ARef, APic, Round(Result.DX), Round(Result.DY));
  Result.Residual := Moved / Result.Change;
  if Result.Residual > PEARDOX_SHIFT_MAX_RESIDUAL then
    Result.Verdict := svNotAShift
  else if Near(Result.DX, AExpectedDX) and Near(Result.DY, AExpectedDY) then
    Result.Verdict := svExpected
  else if Near(Result.DX, -AExpectedDX) and Near(Result.DY, -AExpectedDY) then
    Result.Verdict := svWrongWay
  else
    Result.Verdict := svWrongAmount;
end;

{ TPeardoxShiftResult }

function TPeardoxShiftResult.Text: string;
begin
  case Verdict of
    svNoPicture, svNoChange:
      Result := VerdictName(Verdict);
  else
    Result := Format('%s (moved %.1f, %.1f px; expected %.1f, %.1f; difference %.2f, ' +
      'left after moving back %.0f%%)', [VerdictName(Verdict), DX, DY, ExpectedDX, ExpectedDY,
      Change, Residual * 100]);
  end;
end;

end.
