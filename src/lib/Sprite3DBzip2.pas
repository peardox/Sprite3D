//** @abstract(Decompresses bzip2 data in plain Pascal, on every platform.)
//**
//** Cisco publishes its OpenH264 libraries as @code(.bz2) files, and the RTL reads only zlib
//** and gzip, so this unit decodes bzip2 itself. Bzip2Decompress takes a whole compressed file
//** in memory and returns the whole original; Bzip2DecompressStream reads from one stream and
//** writes each block to another as soon as it is decoded, so a download can be unpacked
//** straight to disk. Concatenated streams, as @code(pbzip2) writes, come back joined. Every
//** block's checksum and each stream's combined checksum are checked, so damaged data raises an
//** error rather than coming back wrong.
//**
//** Blocks marked "randomised", which no bzip2 since version 0.9.5 of 1999 writes, are
//** refused. Memory use is about five times the largest block, at most 4.5 MB, plus the
//** output.
//**
//** No state is kept between calls, so it can be used from any thread.
unit Sprite3DBzip2;

{
  Decompresses bzip2 data in plain Pascal, on every platform.

  Cisco publishes its OpenH264 libraries as .bz2 files, and the RTL reads
  only zlib and gzip, so this unit decodes bzip2 itself. Bzip2Decompress
  takes a whole compressed file in memory and returns the whole original;
  Bzip2DecompressStream reads from one stream and writes each block to
  another as soon as it is decoded, so a download can be unpacked straight
  to disk. Concatenated streams, as pbzip2 writes, come back joined. Every
  block's checksum and each stream's combined checksum are checked, so
  damaged data raises an error rather than coming back wrong.

  Blocks marked "randomised", which no bzip2 since version 0.9.5 of 1999
  writes, are refused. Memory use is about five times the largest block, at
  most 4.5 MB, plus the output.

  No state is kept between calls, so it can be used from any thread.
}

interface

uses
  System.SysUtils, System.Classes;

type
  //** @abstract(Raised when data is not bzip2, or is damaged or cut short.)
  EBzip2Error = class(Exception);

//** @abstract(Whether data starts as a bzip2 stream does.)
//**
//** Only the four-byte header is checked: @code(BZh) and a block size from 1 to 9.
//**
//** @param(AData The data to look at.)
//**
//** @returns(True if it looks like bzip2.)
function IsBzip2(const AData: TBytes): Boolean;

//** @abstract(Decompresses a whole bzip2 file held in memory.)
//**
//** @param(AData The compressed data: one or more bzip2 streams, one after another.)
//**
//** @returns(The original data.)
//**
//** @raises(EBzip2Error If the data is not bzip2, is damaged, fails a checksum or ends too
//** soon.)
//**
//** @raises(EOutOfMemory If the output cannot be held in memory.)
function Bzip2Decompress(const AData: TBytes): TBytes;

//** @abstract(Decompresses bzip2 from one stream into another, a block at a time.)
//**
//** ASource is read from its current position through a 64 KB buffer, and each block is
//** written to ATarget as soon as it is decoded, so neither the compressed data nor the
//** original is ever held whole in memory: only one block, at most 900 KB, and the tables
//** for it. Concatenated streams are joined as Bzip2Decompress joins them, and every
//** checksum is checked in the same way; ATarget may already hold some blocks when an error
//** is raised, so write to a temporary file and keep it only if this returns. Blocks while
//** decoding; it keeps no state, so it may be called on any thread.
//**
//** @param(ASource The compressed data, read from its current position to the end of the
//** bzip2 data; anything after that is left unread or ignored.)
//**
//** @param(ATarget Where the original is written, from its current position.)
//**
//** @param(AMaxSize The most the original may come to, in bytes; 0 or less for no limit.)
//**
//** @returns(How many bytes were written to ATarget.)
//**
//** @raises(EBzip2Error If the data is not bzip2, is damaged or cut short, uses randomised
//** blocks, or comes to more than AMaxSize.)
function Bzip2DecompressStream(const ASource, ATarget: TStream;
  const AMaxSize: Int64 = 0): Int64;

implementation

uses
  System.Math;

const
  MAX_CODE_LEN = 20;        // longest Huffman code bzip2 writes
  MAX_SELECTORS = 18002;    // selectors kept; more may be stored, and are ignored
  MIN_GROUPS = 2;
  MAX_GROUPS = 6;
  MAX_ALPHA = 258;          // 256 byte values, RUNA/RUNB folded in, plus end of block
  GROUP_SIZE = 50;          // symbols coded with each selector
  RUN_A = 0;
  RUN_B = 1;

var
  CrcTable: array[0..255] of Cardinal;

procedure InitCrcTable;
var
  I, K: Integer;
  C: Cardinal;
begin
  // bzip2's CRC-32 runs most significant bit first
  for I := 0 to 255 do
  begin
    C := Cardinal(I) shl 24;
    for K := 0 to 7 do
      if (C and $80000000) <> 0 then
        C := (C shl 1) xor $04C11DB7
      else
        C := C shl 1;
    CrcTable[I] := C;
  end;
end;

procedure Fail(const AWhat: String);
begin
  raise EBzip2Error.Create('The bzip2 data is damaged: ' + AWhat + '.');
end;

const
  // How much of a source stream is read at a time
  STREAM_BUFFER = 65536;

type
  // Reads bits most significant first, from Data, or with Source set, from
  // Source through Data as a buffer of its next Count bytes
  TBitReader = record
    Data: TBytes;
    Pos: Integer;
    Count: Integer;
    Source: TStream;
    Buf: UInt64;
    Live: Integer;
    function Get(const ACount: Integer): Cardinal;
    procedure Align;
    function Fill(const ANeed: Integer): Boolean;
    function StreamFollows: Boolean;
  end;

// At least ANeed bytes unread in Data, reading more from Source if there is
// one; False if there are not that many left
function TBitReader.Fill(const ANeed: Integer): Boolean;
var
  Kept, Got: Integer;
begin
  if Count - Pos >= ANeed then
    Exit(True);
  if Source = nil then
    Exit(False);
  // What is left moves to the front, and the rest of the buffer is filled
  Kept := Count - Pos;
  if Kept > 0 then
    Move(Data[Pos], Data[0], Kept);
  Pos := 0;
  Count := Kept;
  if Length(Data) < STREAM_BUFFER then
    SetLength(Data, STREAM_BUFFER);
  repeat
    Got := Source.Read(Data[Count], Length(Data) - Count);
    Inc(Count, Got);
  until (Got <= 0) or (Count - Pos >= ANeed);
  Result := Count - Pos >= ANeed;
end;

// Whether another stream starts at the next byte, as pbzip2 writes them;
// only when no bits are left over from the last
function TBitReader.StreamFollows: Boolean;
begin
  Result := (Live = 0) and Fill(3) and (Data[Pos] = Ord('B')) and
    (Data[Pos + 1] = Ord('Z')) and (Data[Pos + 2] = Ord('h'));
end;

function TBitReader.Get(const ACount: Integer): Cardinal;
begin
  while Live < ACount do
  begin
    if not Fill(1) then
      raise EBzip2Error.Create('The bzip2 data ends too soon.');
    Buf := (Buf shl 8) or Data[Pos];
    Inc(Pos);
    Inc(Live, 8);
  end;
  Dec(Live, ACount);
  Result := Cardinal((Buf shr Live) and ((UInt64(1) shl ACount) - 1));
end;

// Skips to the next whole byte
procedure TBitReader.Align;
begin
  Dec(Live, Live mod 8);
end;

type
  // The growing output
  TOutput = record
    Data: TBytes;
    Len: NativeInt;
    procedure Add(const AByte: Byte); inline;
  end;

procedure TOutput.Add(const AByte: Byte);
begin
  // Doubled, from 64 KB at least; written out rather than with Max, so this
  // inline routine needs nothing from System.Math
  if Len = Length(Data) then
    if NativeInt(Length(Data)) * 2 < 65536 then
      SetLength(Data, 65536)
    else
      SetLength(Data, NativeInt(Length(Data)) * 2);
  Data[Len] := AByte;
  Inc(Len);
end;

type
  // One Huffman table, decoded as bzip2's own decoder does: codes of each
  // length form a range, Limit is its last code and Base takes a code to
  // its place in Perm
  TCodeTable = record
    Limit: array[0..MAX_CODE_LEN + 1] of Integer;
    Base: array[0..MAX_CODE_LEN + 1] of Integer;
    Perm: array[0..MAX_ALPHA - 1] of Integer;
    PermCount: Integer;
    MinLen: Integer;
  end;

procedure BuildTable(const ALengths: array of Integer; const AAlpha: Integer;
  var ATable: TCodeTable);
var
  MinLen, MaxLen, L, S, I, Vec: Integer;
begin
  MinLen := MAX_CODE_LEN;
  MaxLen := 0;
  for S := 0 to AAlpha - 1 do
  begin
    MinLen := Min(MinLen, ALengths[S]);
    MaxLen := Max(MaxLen, ALengths[S]);
  end;
  ATable.MinLen := MinLen;
  ATable.PermCount := 0;
  for L := MinLen to MaxLen do
    for S := 0 to AAlpha - 1 do
      if ALengths[S] = L then
      begin
        ATable.Perm[ATable.PermCount] := S;
        Inc(ATable.PermCount);
      end;
  FillChar(ATable.Base, SizeOf(ATable.Base), 0);
  FillChar(ATable.Limit, SizeOf(ATable.Limit), 0);
  for S := 0 to AAlpha - 1 do
    Inc(ATable.Base[ALengths[S] + 1]);
  for I := 1 to MAX_CODE_LEN + 1 do
    Inc(ATable.Base[I], ATable.Base[I - 1]);
  Vec := 0;
  for L := MinLen to MaxLen do
  begin
    Inc(Vec, ATable.Base[L + 1] - ATable.Base[L]);
    ATable.Limit[L] := Vec - 1;
    Vec := Vec shl 1;
  end;
  for L := MinLen + 1 to MaxLen do
    ATable.Base[L] := ((ATable.Limit[L - 1] + 1) shl 1) - ATable.Base[L];
end;

function DecodeSymbol(var ABits: TBitReader; const ATable: TCodeTable): Integer;
var
  Len, Code, Index: Integer;
begin
  Len := ATable.MinLen;
  Code := ABits.Get(Len);
  while True do
  begin
    if Len > MAX_CODE_LEN then
      Fail('a Huffman code is too long');
    if Code <= ATable.Limit[Len] then
      Break;
    Inc(Len);
    Code := (Code shl 1) or Integer(ABits.Get(1));
  end;
  Index := Code - ATable.Base[Len];
  if (Index < 0) or (Index >= ATable.PermCount) then
    Fail('a Huffman code is not in its table');
  Result := ATable.Perm[Index];
end;

// One block, from after its magic number; returns its CRC
function DecodeBlock(var ABits: TBitReader; const AMaxBlock: Integer;
  var AOut: TOutput): Cardinal;
var
  StoredCrc, Crc, Used, Bits: Cardinal;
  OrigPtr, InUse, Alpha, Groups, Selectors, Kept, I, J, T, Cur, Sym, Group: Integer;
  GroupLeft, SelectorIndex, RunLength, RunBit, EndOfBlock, N, Pos, Same, Last: Integer;
  Seq: array[0..255] of Byte;
  Mtf: array[0..255] of Byte;
  GroupMtf: array[0..MAX_GROUPS - 1] of Byte;
  Selector: TBytes;
  Lengths: array[0..MAX_ALPHA - 1] of Integer;
  Tables: array[0..MAX_GROUPS - 1] of TCodeTable;
  Counts, Starts: array[0..255] of Integer;
  Block: TBytes;
  Next: TArray<Integer>;
  V, Ch: Byte;
begin
  StoredCrc := ABits.Get(32);
  if ABits.Get(1) <> 0 then
    raise EBzip2Error.Create('The bzip2 data uses randomised blocks, which are not ' +
      'supported.');
  OrigPtr := ABits.Get(24);

  // The byte values the block uses
  Used := ABits.Get(16);
  InUse := 0;
  for I := 0 to 15 do
    if (Used and ($8000 shr I)) <> 0 then
    begin
      Bits := ABits.Get(16);
      for J := 0 to 15 do
        if (Bits and ($8000 shr J)) <> 0 then
        begin
          Seq[InUse] := I * 16 + J;
          Inc(InUse);
        end;
    end;
  if InUse = 0 then
    Fail('a block uses no symbols');
  Alpha := InUse + 2;

  // Which Huffman table codes each group of 50 symbols
  Groups := ABits.Get(3);
  if (Groups < MIN_GROUPS) or (Groups > MAX_GROUPS) then
    Fail('a block has a wrong number of tables');
  Selectors := ABits.Get(15);
  if Selectors < 1 then
    Fail('a block has no selectors');
  for I := 0 to Groups - 1 do
    GroupMtf[I] := I;
  Kept := Min(Selectors, MAX_SELECTORS);
  SetLength(Selector, Kept);
  for I := 0 to Selectors - 1 do
  begin
    J := 0;
    while ABits.Get(1) <> 0 do
    begin
      Inc(J);
      if J >= Groups then
        Fail('a selector is out of range');
    end;
    V := GroupMtf[J];
    while J > 0 do
    begin
      GroupMtf[J] := GroupMtf[J - 1];
      Dec(J);
    end;
    GroupMtf[0] := V;
    if I < Kept then
      Selector[I] := V;
  end;

  // The Huffman tables, as code lengths that change by one at a time
  for T := 0 to Groups - 1 do
  begin
    Cur := ABits.Get(5);
    for I := 0 to Alpha - 1 do
    begin
      while True do
      begin
        if (Cur < 1) or (Cur > MAX_CODE_LEN) then
          Fail('a code length is out of range');
        if ABits.Get(1) = 0 then
          Break;
        if ABits.Get(1) = 0 then
          Inc(Cur)
        else
          Dec(Cur);
      end;
      Lengths[I] := Cur;
    end;
    BuildTable(Lengths, Alpha, Tables[T]);
  end;

  // The symbols: move-to-front indices, with runs of the front byte
  for I := 0 to 255 do
    Mtf[I] := I;
  FillChar(Counts, SizeOf(Counts), 0);
  SetLength(Block, AMaxBlock);
  N := 0;
  EndOfBlock := InUse + 1;
  GroupLeft := 0;
  SelectorIndex := -1;
  Group := 0;
  RunLength := 0;
  RunBit := 1;
  while True do
  begin
    if GroupLeft = 0 then
    begin
      Inc(SelectorIndex);
      if SelectorIndex >= Kept then
        Fail('a block runs past its selectors');
      Group := Selector[SelectorIndex];
      GroupLeft := GROUP_SIZE;
    end;
    Dec(GroupLeft);
    Sym := DecodeSymbol(ABits, Tables[Group]);

    if Sym <= RUN_B then
    begin
      // RUNA adds the current power of two, RUNB twice it
      Inc(RunLength, RunBit shl Sym);
      RunBit := RunBit shl 1;
      if RunLength > AMaxBlock then
        Fail('a run is too long');
      Continue;
    end;

    if RunLength > 0 then
    begin
      Ch := Seq[Mtf[0]];
      if N + RunLength > AMaxBlock then
        Fail('a block is too long');
      FillChar(Block[N], RunLength, Ch);
      Inc(N, RunLength);
      Inc(Counts[Ch], RunLength);
      RunLength := 0;
      RunBit := 1;
    end;

    if Sym = EndOfBlock then
      Break;

    I := Sym - 1;
    V := Mtf[I];
    if I > 0 then
      Move(Mtf[0], Mtf[1], I);
    Mtf[0] := V;
    if N >= AMaxBlock then
      Fail('a block is too long');
    Ch := Seq[V];
    Block[N] := Ch;
    Inc(N);
    Inc(Counts[Ch]);
  end;
  if (N = 0) or (OrigPtr >= N) then
    Fail('a block''s start is out of range');

  // Undo the Burrows-Wheeler transform: Next takes each position to the next
  J := 0;
  for I := 0 to 255 do
  begin
    Starts[I] := J;
    Inc(J, Counts[I]);
  end;
  SetLength(Next, N);
  for I := 0 to N - 1 do
  begin
    Next[Starts[Block[I]]] := I;
    Inc(Starts[Block[I]]);
  end;

  // Then the first run-length coding: four equal bytes and a count of more
  Crc := $FFFFFFFF;
  Pos := Next[OrigPtr];
  Same := 0;
  Last := -1;
  I := 0;
  while I < N do
  begin
    Ch := Block[Pos];
    Pos := Next[Pos];
    Inc(I);
    if Same = 4 then
    begin
      for J := 1 to Ch do
      begin
        AOut.Add(Byte(Last));
        Crc := (Crc shl 8) xor CrcTable[((Crc shr 24) xor Cardinal(Last)) and $FF];
      end;
      Same := 0;
      Last := -1;
      Continue;
    end;
    if Ch = Last then
      Inc(Same)
    else
    begin
      Same := 1;
      Last := Ch;
    end;
    AOut.Add(Ch);
    Crc := (Crc shl 8) xor CrcTable[((Crc shr 24) xor Ch) and $FF];
  end;
  Result := not Crc;
  if Result <> StoredCrc then
    Fail('a block''s checksum does not match');
end;

function IsBzip2(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= 4) and (AData[0] = Ord('B')) and (AData[1] = Ord('Z')) and
    (AData[2] = Ord('h')) and (AData[3] >= Ord('1')) and (AData[3] <= Ord('9'));
end;

// Decodes every stream Bits holds; with ATarget, each block is written there
// as soon as it is decoded and AOutput emptied, the total kept in ATotal and
// held to AMaxSize; without, AOutput gathers the whole original
procedure DecodeStreams(var ABits: TBitReader; var AOutput: TOutput; const ATarget: TStream;
  const AMaxSize: Int64; out ATotal: Int64);
var
  Level, MaxBlock: Integer;
  High24, Low24, Combined, BlockCrc: Cardinal;
begin
  ATotal := 0;
  repeat
    // A stream: BZh, the block size, the blocks, the end marker
    if (ABits.Get(8) <> Ord('B')) or (ABits.Get(8) <> Ord('Z')) or
      (ABits.Get(8) <> Ord('h')) then
      raise EBzip2Error.Create('The data is not bzip2.');
    Level := Integer(ABits.Get(8)) - Ord('0');
    if (Level < 1) or (Level > 9) then
      raise EBzip2Error.Create('The data is not bzip2.');
    MaxBlock := Level * 100000;
    Combined := 0;
    while True do
    begin
      High24 := ABits.Get(24);
      Low24 := ABits.Get(24);
      if (High24 = $314159) and (Low24 = $265359) then
      begin
        BlockCrc := DecodeBlock(ABits, MaxBlock, AOutput);
        Combined := ((Combined shl 1) or (Combined shr 31)) xor BlockCrc;
        if ATarget <> nil then
        begin
          // Out as soon as it is checked, and the buffer reused
          Inc(ATotal, AOutput.Len);
          if (AMaxSize > 0) and (ATotal > AMaxSize) then
            raise EBzip2Error.Create('The bzip2 data unpacks to more than is allowed.');
          if AOutput.Len > 0 then
            ATarget.WriteBuffer(AOutput.Data[0], AOutput.Len);
          AOutput.Len := 0;
        end;
      end
      else if (High24 = $177245) and (Low24 = $385090) then
      begin
        if ABits.Get(32) <> Combined then
          Fail('the stream''s checksum does not match');
        ABits.Align;
        Break;
      end
      else
        Fail('a block marker is missing');
    end;
    // Another stream may follow, as pbzip2 writes; anything else ends it
  until not ABits.StreamFollows;
  if ATarget = nil then
    ATotal := AOutput.Len;
end;

function Bzip2Decompress(const AData: TBytes): TBytes;
var
  Bits: TBitReader;
  Output: TOutput;
  Total: Int64;
begin
  if not IsBzip2(AData) then
    raise EBzip2Error.Create('The data is not bzip2.');
  Bits.Data := AData;
  Bits.Pos := 0;
  Bits.Count := Length(AData);
  Bits.Source := nil;
  Bits.Buf := 0;
  Bits.Live := 0;
  Output.Data := nil;
  Output.Len := 0;
  DecodeStreams(Bits, Output, nil, 0, Total);
  SetLength(Output.Data, Output.Len);
  Result := Output.Data;
end;

function Bzip2DecompressStream(const ASource, ATarget: TStream;
  const AMaxSize: Int64): Int64;
var
  Bits: TBitReader;
  Output: TOutput;
begin
  if (ASource = nil) or (ATarget = nil) then
    raise EBzip2Error.Create('No stream to decompress from or to.');
  Bits.Data := nil;
  Bits.Pos := 0;
  Bits.Count := 0;
  Bits.Source := ASource;
  Bits.Buf := 0;
  Bits.Live := 0;
  Output.Data := nil;
  Output.Len := 0;
  // The header first, so anything that is not bzip2 says so plainly
  if not Bits.Fill(4) or (Bits.Data[0] <> Ord('B')) or (Bits.Data[1] <> Ord('Z')) or
    (Bits.Data[2] <> Ord('h')) or (Bits.Data[3] < Ord('1')) or (Bits.Data[3] > Ord('9')) then
    raise EBzip2Error.Create('The data is not bzip2.');
  DecodeStreams(Bits, Output, ATarget, AMaxSize, Result);
end;

initialization
  InitCrcTable;

end.
