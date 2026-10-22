//** @abstract(H.264 encoding with Cisco's OpenH264 library, loaded only when it is present.)
//**
//** OpenH264 is Cisco's open-source H.264 encoder. Cisco publishes ready-built copies of it
//** for each platform, and pays the H.264 patent royalties for copies downloaded from Cisco,
//** which is why it is not shipped with Sprite3D: Sprite3DLibraryUpdate downloads it from the
//** address given for the platform, and this unit loads that copy and no other. Without it,
//** Sprite3DVideo writes MPEG-4 Part 2 instead.
//**
//** SetPreferredOpenH264 names the copy; OpenH264Available loads it the first time it is asked,
//** if it is version 2.0 or later and has the encoder's entry points, and OpenH264Retry tries
//** again after a download. No other folder, and no copy the system may have, is ever tried.
//**
//** TSprite3DH264Encoder then turns YUV 4:2:0 pictures into H.264 Annex B access units, ready
//** for an MP4 muxer, with its parameter sets available separately for the MP4's header.
//**
//** The declarations used to call the library are translated from OpenH264's
//** @code(codec_api.h), @code(codec_app_def.h) and @code(codec_def.h), Copyright @(c@) 2013,
//** Cisco Systems, under the BSD 2-clause licence: redistributions of source must keep that
//** notice and binaries must reproduce it in their documentation.
//**
//** For the main thread, or any one thread at a time.
unit Sprite3DOpenH264;

{
  H.264 encoding with Cisco's OpenH264 library, loaded only when it is
  present.

  OpenH264 is Cisco's open-source H.264 encoder. Cisco publishes ready-built
  copies of it for each platform, and pays the H.264 patent royalties for
  copies downloaded from Cisco, which is why it is not shipped with
  Sprite3D: Sprite3DLibraryUpdate downloads it from the address given for
  the platform, and this unit loads that copy and no other. Without it,
  Sprite3DVideo writes MPEG-4 Part 2 instead.

  SetPreferredOpenH264 names the copy; OpenH264Available loads it the first
  time it is asked, if it is version 2.0 or later and has the encoder's
  entry points, and OpenH264Retry tries again after a download. No other
  folder, and no copy the system may have, is ever tried.

  TSprite3DH264Encoder then turns YUV 4:2:0 pictures into H.264 Annex B
  access units, ready for an MP4 muxer, with its parameter sets available
  separately for the MP4's header.

  The declarations used to call the library are translated from OpenH264's
  codec_api.h, codec_app_def.h and codec_def.h, Copyright (c) 2013, Cisco
  Systems, under the BSD 2-clause licence: redistributions of source must
  keep that notice and binaries must reproduce it in their documentation.

  For the main thread, or any one thread at a time.
}

interface

uses
  System.SysUtils;

type
  //** @abstract(Raised when OpenH264 cannot set up or encode.)
  /// <summary>Raised when OpenH264 cannot set up or encode.</summary>
  ESprite3DH264Error = class(Exception);

  //** @abstract(One OpenH264 encoder, for pictures of one size.)
  //**
  //** Create it with the size and frame rate, feed it every picture in order with Encode,
  //** then free it. Every picture is encoded on its own, without frames held back, so each
  //** Encode returns that picture's access unit straight away; there are no B-frames, so the
  //** decoding order is the display order. Rate control aims at a constant quality, and the
  //** encoder never drops a frame.
  /// <summary>One OpenH264 encoder, for pictures of one size.</summary>
  /// <remarks>Create it with the size and frame rate, feed it every picture in order with
  /// Encode, then free it. Every picture is encoded on its own, without frames held back, so
  /// each Encode returns that picture's access unit straight away; there are no B-frames, so
  /// the decoding order is the display order. Rate control aims at a constant quality, and the
  /// encoder never drops a frame.</remarks>
  TSprite3DH264Encoder = class
  private
    FEncoder: Pointer;
    FWidth: Integer;
    FHeight: Integer;
    FInfo: Pointer;
    FFrameRate: Single;
    FCount: Int64;
    function Collect: TBytes;
  public
    //** @abstract(Sets up an encoder for AWidth x AHeight pictures at AFrameRate.)
    //**
    //** @param(AWidth The picture width in pixels; even, at least 16.)
    //**
    //** @param(AHeight The picture height in pixels; even, at least 16.)
    //**
    //** @param(AFrameRate Frames per second, which sets the bit budget; more than 0.)
    //**
    //** @param(AKeyInterval Frames between key frames; 0 for only the first.)
    //**
    //** @raises(ESprite3DH264Error If OpenH264 is not available or refuses the settings.)
    /// <summary>Sets up an encoder for AWidth x AHeight pictures at AFrameRate.</summary>
    /// <param name="AWidth">The picture width in pixels; even, at least 16.</param>
    /// <param name="AHeight">The picture height in pixels; even, at least 16.</param>
    /// <param name="AFrameRate">Frames per second, which sets the bit budget; more than
    /// 0.</param>
    /// <param name="AKeyInterval">Frames between key frames; 0 for only the first.</param>
    /// <exception cref="ESprite3DH264Error">If OpenH264 is not available or refuses the
    /// settings.</exception>
    constructor Create(const AWidth, AHeight: Integer; const AFrameRate: Single;
      const AKeyInterval: Integer);
    //** @abstract(Releases the encoder.)
    /// <summary>Releases the encoder.</summary>
    destructor Destroy; override;
    //** @abstract(The sequence and picture parameter sets, as an Annex B byte stream.)
    //**
    //** This is what an MP4 muxer needs, as the stream's extra data, to write the stream's
    //** @code(avcC) description before any frame.
    //**
    //** @returns(The SPS and PPS NAL units, each after a start code.)
    //**
    //** @raises(ESprite3DH264Error If OpenH264 fails.)
    /// <summary>The sequence and picture parameter sets, as an Annex B byte stream.</summary>
    /// <remarks>This is what an MP4 muxer needs, as the stream's extra data, to write the
    /// stream's <c>avcC</c> description before any frame.</remarks>
    /// <returns>The SPS and PPS NAL units, each after a start code.</returns>
    /// <exception cref="ESprite3DH264Error">If OpenH264 fails.</exception>
    function ParameterSets: TBytes;
    //** @abstract(Encodes one YUV 4:2:0 picture.)
    //**
    //** @param(APlanes The Y, U and V planes, in that order; U and V are half the width and
    //** height.)
    //**
    //** @param(AStrides The bytes from one row to the next in each plane.)
    //**
    //** @param(AData On return, the picture as an Annex B access unit; empty if the encoder
    //** skipped it.)
    //**
    //** @param(AKey On return, True if it is a key frame, which a player can start from.)
    //**
    //** @raises(ESprite3DH264Error If OpenH264 fails.)
    /// <summary>Encodes one YUV 4:2:0 picture.</summary>
    /// <param name="APlanes">The Y, U and V planes, in that order; U and V are half the width
    /// and height.</param>
    /// <param name="AStrides">The bytes from one row to the next in each plane.</param>
    /// <param name="AData">On return, the picture as an Annex B access unit; empty if the
    /// encoder skipped it.</param>
    /// <param name="AKey">On return, True if it is a key frame, which a player can start
    /// from.</param>
    /// <exception cref="ESprite3DH264Error">If OpenH264 fails.</exception>
    procedure Encode(const APlanes: array of PByte; const AStrides: array of Integer;
      out AData: TBytes; out AKey: Boolean);
  end;

//** @abstract(Whether OpenH264 is loaded, loading it the first time.)
//**
//** The first call loads the copy SetPreferredOpenH264 named, if it is version 2.0 or later
//** and has the encoder; later calls return the same answer at once. With no copy named, the
//** answer is False. The library stays loaded until the program ends.
//**
//** @returns(True if TSprite3DH264Encoder can be used.)
/// <summary>Whether OpenH264 is loaded, loading it the first time.</summary>
/// <remarks>The first call loads the copy SetPreferredOpenH264 named, if it is version 2.0 or
/// later and has the encoder; later calls return the same answer at once. With no copy named,
/// the answer is False. The library stays loaded until the program ends.</remarks>
/// <returns>True if TSprite3DH264Encoder can be used.</returns>
function OpenH264Available: Boolean;

//** @abstract(Names the copy of OpenH264 to load: the one downloaded for this platform.)
//**
//** Call it before OpenH264Available, or before OpenH264Retry once a copy has been
//** downloaded. An empty string means there is none, and H.264 is not offered.
//**
//** @param(APath The library's full path.)
/// <summary>Names the copy of OpenH264 to load: the one downloaded for this
/// platform.</summary>
/// <remarks>Call it before OpenH264Available, or before OpenH264Retry once a copy has been
/// downloaded. An empty string means there is none, and H.264 is not offered.</remarks>
/// <param name="APath">The library's full path.</param>
procedure SetPreferredOpenH264(const APath: String);

//** @abstract(Loads the named OpenH264 again unless a copy is already loaded.)
//**
//** As OpenH264Available, but a failed earlier attempt does not stop a new one. A loaded copy
//** stays in use until the program ends.
//**
//** @returns(True if TSprite3DH264Encoder can be used.)
/// <summary>Loads the named OpenH264 again unless a copy is already loaded.</summary>
/// <remarks>As OpenH264Available, but a failed earlier attempt does not stop a new one. A
/// loaded copy stays in use until the program ends.</remarks>
/// <returns>True if TSprite3DH264Encoder can be used.</returns>
function OpenH264Retry: Boolean;

//** @abstract(The full path of the OpenH264 loaded, or empty if none is.)
//**
//** @returns(The path, as it was loaded.)
/// <summary>The full path of the OpenH264 loaded, or empty if none is.</summary>
/// <returns>The path, as it was loaded.</returns>
function OpenH264LoadedLibrary: String;

//** @abstract(Which OpenH264 was loaded and from where, or why none was.)
//**
//** Empty until OpenH264Available has been called.
//**
//** @returns(A line for a log or a hint.)
/// <summary>Which OpenH264 was loaded and from where, or why none was.</summary>
/// <remarks>Empty until OpenH264Available has been called.</remarks>
/// <returns>A line for a log or a hint.</returns>
function OpenH264Status: String;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ELSE}
  Posix.Dlfcn,
  {$ENDIF}
  System.Classes, System.IOUtils, System.Math, OSPaths;

// The structures below must be laid out as OpenH264's C compiler lays them
// out: natural alignment, enumerations as 4-byte ints
{$ALIGN 8}
{$MINENUMSIZE 4}

// Translated from OpenH264's codec_api.h, codec_app_def.h and codec_def.h
// (Copyright (c) 2013, Cisco Systems; BSD 2-clause). Enumerations are C
// ints, so they are declared as Integer here.
const
  // EUsageType. OpenH264's parameter check accepts only the two real-time
  // usages (CAMERA_VIDEO_NON_REAL_TIME = 2 is refused with code 1,
  // cmInitParaError); real-time camera video is the one for rendered frames
  CAMERA_VIDEO_REAL_TIME = 0;
  RC_QUALITY_MODE = 0;                 // RC_MODES
  VIDEO_FORMAT_I420 = 23;              // EVideoFormatType videoFormatI420
  VIDEO_FRAME_TYPE_INVALID = 0;        // EVideoFrameType
  VIDEO_FRAME_TYPE_IDR = 1;
  VIDEO_FRAME_TYPE_SKIP = 4;
  ENCODER_OPTION_DATAFORMAT = 0;       // ENCODER_OPTION
  ENCODER_OPTION_IDR_INTERVAL = 1;
  ENCODER_OPTION_RC_FRAME_SKIP = 9;
  ENCODER_OPTION_TRACE_LEVEL = 25;
  WELS_LOG_QUIET = 0;
  MAX_LAYER_NUM_OF_FRAME = 128;
  CM_RESULT_SUCCESS = 0;
  // Bits per pixel per frame aimed at: enough for clean sprites
  BITS_PER_PIXEL = 0.25;
  MIN_BITRATE = 500000;

type
  TOpenH264Version = record
    uMajor, uMinor, uRevision, uReserved: Cardinal;
  end;
  POpenH264Version = ^TOpenH264Version;

  TSEncParamBase = record
    iUsageType: Integer;
    iPicWidth: Integer;
    iPicHeight: Integer;
    iTargetBitrate: Integer;
    iRCMode: Integer;
    fMaxFrameRate: Single;
  end;
  PSEncParamBase = ^TSEncParamBase;

  // Version 2.6.0 added three PSNR flags at the end; earlier versions read
  // only the fields before them, and the flags are left False, so one
  // declaration serves both
  TSSourcePicture = record
    iColorFormat: Integer;
    iStride: array[0..3] of Integer;
    pData: array[0..3] of PByte;
    iPicWidth: Integer;
    iPicHeight: Integer;
    uiTimeStamp: Int64;
    bPsnrY: Boolean;
    bPsnrU: Boolean;
    bPsnrV: Boolean;
  end;
  PSSourcePicture = ^TSSourcePicture;

  // SLayerBSInfo up to pBsBuf, which every 2.x version shares. Version
  // 2.6.0 added rPsnr: array[0..2] of float after pBsBuf, which makes each
  // layer 56 bytes instead of 40 on 64-bit platforms, so the layers in
  // SFrameBSInfo are found by LayerSize, set from the loaded version, and
  // never through an array declared here
  TSLayerBSInfo = record
    uiTemporalId: Byte;
    uiSpatialId: Byte;
    uiQualityId: Byte;
    eFrameType: Integer;
    uiLayerType: Byte;
    iSubSeqId: Integer;
    iNalCount: Integer;
    pNalLengthInByte: PInteger;
    pBsBuf: PByte;
  end;
  PSLayerBSInfo = ^TSLayerBSInfo;

  // SFrameBSInfo is iLayerNum, MAX_LAYER_NUM_OF_FRAME layers, then
  // eFrameType, iFrameSizeInBytes and uiTimeStamp; it is reached through
  // the functions below, with the layer size of the version loaded
  PSFrameBSInfo = Pointer;

  // ISVCEncoder in C: a pointer to a pointer to this table; every entry
  // takes the encoder itself first
  PEncoder = ^PEncoderVtbl;
  PEncoderVtbl = ^TEncoderVtbl;
  TEncoderVtbl = record
    Initialize: function(AThis: PEncoder; const AParam: PSEncParamBase): Integer; cdecl;
    InitializeExt: function(AThis: PEncoder; const AParam: Pointer): Integer; cdecl;
    GetDefaultParams: function(AThis: PEncoder; AParam: Pointer): Integer; cdecl;
    Uninitialize: function(AThis: PEncoder): Integer; cdecl;
    EncodeFrame: function(AThis: PEncoder; const ASrcPic: PSSourcePicture;
      ABsInfo: PSFrameBSInfo): Integer; cdecl;
    EncodeParameterSets: function(AThis: PEncoder; ABsInfo: PSFrameBSInfo): Integer; cdecl;
    ForceIntraFrame: function(AThis: PEncoder; AIDR: Boolean): Integer; cdecl;
    SetOption: function(AThis: PEncoder; AOptionId: Integer; AOption: Pointer): Integer; cdecl;
    GetOption: function(AThis: PEncoder; AOptionId: Integer; AOption: Pointer): Integer; cdecl;
  end;

  TWelsCreateSVCEncoder = function(out AEncoder: PEncoder): Integer; cdecl;
  TWelsDestroySVCEncoder = procedure(AEncoder: PEncoder); cdecl;
  TWelsGetCodecVersionEx = procedure(AVersion: POpenH264Version); cdecl;

const
  // Each layer's size with and without 2.6.0's rPsnr, rounded up to the
  // alignment of its pointers
  LAYER_SIZE_2_0 = ((SizeOf(TSLayerBSInfo) + SizeOf(Pointer) - 1) div SizeOf(Pointer)) *
    SizeOf(Pointer);
  LAYER_SIZE_2_6 = ((SizeOf(TSLayerBSInfo) + 3 * SizeOf(Single) + SizeOf(Pointer) - 1) div
    SizeOf(Pointer)) * SizeOf(Pointer);
  // The layers start after iLayerNum, at the alignment of their pointers
  LAYERS_OFFSET = SizeOf(Pointer);
  // Room for the larger SFrameBSInfo: layers, then two ints and an int64
  FRAME_INFO_SIZE = LAYERS_OFFSET + MAX_LAYER_NUM_OF_FRAME * LAYER_SIZE_2_6 + 16;

var
  // The size of one SLayerBSInfo in the version loaded
  LayerSize: Integer = LAYER_SIZE_2_6;
  CreateEncoder: TWelsCreateSVCEncoder;
  DestroyEncoder: TWelsDestroySVCEncoder;
  GetVersionEx: TWelsGetCodecVersionEx;
  Tried: Boolean;
  Loaded: Boolean;
  Status: String;
  // The only copy ever loaded; see SetPreferredOpenH264
  PreferredLibrary: String;
  LoadedLibrary: String;

{ Loading }

function OpenLibrary(const APath: String): HMODULE;
var
  Path: String;
begin
  Path := OSFriendlyPath(APath);
  {$IFDEF MSWINDOWS}
  if ExtractFilePath(Path) <> String.Empty then
    Result := LoadLibraryEx(PChar(Path), 0, LOAD_WITH_ALTERED_SEARCH_PATH)
  else
    Result := LoadLibrary(PChar(Path));
  {$ELSE}
  Result := System.SysUtils.LoadLibrary(PChar(Path));
  {$ENDIF}
end;

function FindSymbol(const AModule: HMODULE; const AName: String): Pointer;
begin
  {$IFDEF MSWINDOWS}
  Result := GetProcAddress(AModule, PChar(AName));
  {$ELSE}
  Result := System.SysUtils.GetProcAddress(AModule, PChar(AName));
  {$ENDIF}
end;

// Why the last OpenLibrary failed, as the system puts it
function LoadError: String;
begin
  {$IFDEF MSWINDOWS}
  Result := SysErrorMessage(GetLastError);
  {$ELSE}
  Result := String(UTF8String(dlerror));
  {$ENDIF}
  if Result = String.Empty then
    Result := 'unknown error';
end;

procedure CloseLibrary(const AModule: HMODULE);
begin
  {$IFDEF MSWINDOWS}
  FreeLibrary(AModule);
  {$ELSE}
  System.SysUtils.FreeLibrary(AModule);
  {$ENDIF}
end;

// Loads APath if it is a usable OpenH264; True and the entry points set if
// so, otherwise AReason says why not
function TryLibrary(const APath: String; out AVersion: TOpenH264Version;
  out AReason: String): Boolean;
var
  Module: HMODULE;
  Create_: TWelsCreateSVCEncoder;
  Destroy_: TWelsDestroySVCEncoder;
  Version: TWelsGetCodecVersionEx;
begin
  Result := False;
  AReason := String.Empty;
  FillChar(AVersion, SizeOf(AVersion), 0);
  Module := OpenLibrary(APath);
  if Module = 0 then
  begin
    AReason := 'could not be loaded: ' + LoadError;
    Exit;
  end;
  @Create_ := FindSymbol(Module, 'WelsCreateSVCEncoder');
  @Destroy_ := FindSymbol(Module, 'WelsDestroySVCEncoder');
  @Version := FindSymbol(Module, 'WelsGetCodecVersionEx');
  if not Assigned(Create_) or not Assigned(Destroy_) or not Assigned(Version) then
  begin
    AReason := 'is not OpenH264: it lacks WelsCreateSVCEncoder, WelsDestroySVCEncoder ' +
      'or WelsGetCodecVersionEx';
    CloseLibrary(Module);
    Exit;
  end;
  Version(@AVersion);
  // The structures above match version 2.0 and later
  if AVersion.uMajor < 2 then
  begin
    AReason := Format('is version %d.%d.%d; 2.0 or later is needed',
      [AVersion.uMajor, AVersion.uMinor, AVersion.uRevision]);
    CloseLibrary(Module);
    Exit;
  end;
  CreateEncoder := Create_;
  DestroyEncoder := Destroy_;
  if (AVersion.uMajor > 2) or (AVersion.uMinor >= 6) then
    LayerSize := LAYER_SIZE_2_6
  else
    LayerSize := LAYER_SIZE_2_0;
  GetVersionEx := Version;
  Result := True;
end;

function OpenH264Available: Boolean;
var
  Reason: String;
  Version: TOpenH264Version;
begin
  if Tried then
    Exit(Loaded);
  Tried := True;
  Loaded := False;
  if PreferredLibrary = String.Empty then
  begin
    Status := 'No OpenH264 has been downloaded for this platform, so MP4 video is ' +
      'MPEG-4 Part 2';
    Exit(False);
  end;
  if not TFile.Exists(PreferredLibrary) then
  begin
    Status := 'OpenH264 is missing from ' + PreferredLibrary +
      ', so MP4 video is MPEG-4 Part 2';
    Exit(False);
  end;
  try
    Loaded := TryLibrary(PreferredLibrary, Version, Reason);
  except
    on E: Exception do
      Reason := 'failed while loading: ' + E.Message;
  end;
  if Loaded then
  begin
    LoadedLibrary := PreferredLibrary;
    Status := Format('OpenH264 %d.%d.%d loaded from %s; MP4 video is H.264',
      [Version.uMajor, Version.uMinor, Version.uRevision, PreferredLibrary]);
  end
  else
    Status := 'OpenH264 was downloaded but is not usable, so MP4 video is MPEG-4 Part 2: ' +
      ExtractFileName(PreferredLibrary) + ' ' + Reason;
  Result := Loaded;
end;

function OpenH264Status: String;
begin
  Result := Status;
end;

procedure SetPreferredOpenH264(const APath: String);
begin
  PreferredLibrary := APath;
end;

function OpenH264Retry: Boolean;
begin
  if Loaded then
    Exit(True);
  Tried := False;
  Result := OpenH264Available;
end;

function OpenH264LoadedLibrary: String;
begin
  Result := LoadedLibrary;
end;

{ TSprite3DH264Encoder }

// The parts of an SFrameBSInfo, placed by the loaded version's layer size
function InfoLayerNum(const AInfo: PSFrameBSInfo): Integer;
begin
  Result := PInteger(AInfo)^;
end;

function InfoLayer(const AInfo: PSFrameBSInfo; const AIndex: Integer): PSLayerBSInfo;
begin
  Result := PSLayerBSInfo(PByte(AInfo) + LAYERS_OFFSET + NativeInt(AIndex) * LayerSize);
end;

function InfoFrameType(const AInfo: PSFrameBSInfo): Integer;
begin
  Result := PInteger(PByte(AInfo) + LAYERS_OFFSET +
    NativeInt(MAX_LAYER_NUM_OF_FRAME) * LayerSize)^;
end;

procedure Check(const AResult: Integer; const AStep: String);
begin
  if AResult <> CM_RESULT_SUCCESS then
    raise ESprite3DH264Error.CreateFmt('OpenH264: %s failed (code %d)', [AStep, AResult]);
end;

constructor TSprite3DH264Encoder.Create(const AWidth, AHeight: Integer;
  const AFrameRate: Single; const AKeyInterval: Integer);
var
  Param: TSEncParamBase;
  Value: Integer;
  NoSkip: Boolean;
  Encoder: PEncoder;
begin
  inherited Create;
  if not Loaded then
    raise ESprite3DH264Error.Create('OpenH264 is not loaded.');
  if (AWidth < 16) or (AHeight < 16) or Odd(AWidth) or Odd(AHeight) or (AFrameRate <= 0) then
    raise ESprite3DH264Error.CreateFmt('OpenH264 cannot encode %d x %d pictures.',
      [AWidth, AHeight]);
  FWidth := AWidth;
  FHeight := AHeight;
  FFrameRate := AFrameRate;
  FCount := 0;
  GetMem(FInfo, FRAME_INFO_SIZE);
  FillChar(FInfo^, FRAME_INFO_SIZE, 0);

  Encoder := nil;
  Check(CreateEncoder(Encoder), 'creating the encoder');
  FEncoder := Encoder;
  if FEncoder = nil then
    raise ESprite3DH264Error.Create('OpenH264 gave no encoder.');

  Value := WELS_LOG_QUIET;
  PEncoder(FEncoder)^^.SetOption(PEncoder(FEncoder), ENCODER_OPTION_TRACE_LEVEL, @Value);

  FillChar(Param, SizeOf(Param), 0);
  Param.iUsageType := CAMERA_VIDEO_REAL_TIME;
  Param.iPicWidth := AWidth;
  Param.iPicHeight := AHeight;
  Param.iTargetBitrate := Max(MIN_BITRATE,
    Round(Min(Double(MaxInt), AWidth * AHeight * AFrameRate * BITS_PER_PIXEL)));
  Param.iRCMode := RC_QUALITY_MODE;
  Param.fMaxFrameRate := AFrameRate;
  Check(PEncoder(FEncoder)^^.Initialize(PEncoder(FEncoder), @Param), 'setting up the encoder');

  Value := VIDEO_FORMAT_I420;
  Check(PEncoder(FEncoder)^^.SetOption(PEncoder(FEncoder), ENCODER_OPTION_DATAFORMAT, @Value),
    'choosing YUV 4:2:0 input');
  Value := AKeyInterval;
  Check(PEncoder(FEncoder)^^.SetOption(PEncoder(FEncoder), ENCODER_OPTION_IDR_INTERVAL, @Value),
    'setting the key frame interval');
  // Every captured frame matters: never let rate control drop one
  NoSkip := False;
  PEncoder(FEncoder)^^.SetOption(PEncoder(FEncoder), ENCODER_OPTION_RC_FRAME_SKIP, @NoSkip);
end;

destructor TSprite3DH264Encoder.Destroy;
begin
  if FEncoder <> nil then
  begin
    PEncoder(FEncoder)^^.Uninitialize(PEncoder(FEncoder));
    DestroyEncoder(PEncoder(FEncoder));
  end;
  FreeMem(FInfo);
  inherited;
end;

// Every NAL unit in FInfo, in order, as one byte stream; OpenH264 writes
// them with Annex B start codes
function TSprite3DH264Encoder.Collect: TBytes;
var
  Layer, Nal, Size, Total: Integer;
  Info: PSLayerBSInfo;
begin
  Result := nil;
  Total := 0;
  for Layer := 0 to Min(InfoLayerNum(FInfo), MAX_LAYER_NUM_OF_FRAME) - 1 do
  begin
    Info := InfoLayer(FInfo, Layer);
    Size := 0;
    for Nal := 0 to Info.iNalCount - 1 do
      Inc(Size, PInteger(PByte(Info.pNalLengthInByte) + Nal * SizeOf(Integer))^);
    if (Size <= 0) or (Info.pBsBuf = nil) then
      Continue;
    SetLength(Result, Total + Size);
    Move(Info.pBsBuf^, Result[Total], Size);
    Inc(Total, Size);
  end;
end;

function TSprite3DH264Encoder.ParameterSets: TBytes;
begin
  FillChar(FInfo^, FRAME_INFO_SIZE, 0);
  Check(PEncoder(FEncoder)^^.EncodeParameterSets(PEncoder(FEncoder), FInfo),
    'writing the parameter sets');
  Result := Collect;
end;

procedure TSprite3DH264Encoder.Encode(const APlanes: array of PByte;
  const AStrides: array of Integer; out AData: TBytes; out AKey: Boolean);
var
  Picture: TSSourcePicture;
  I: Integer;
begin
  if (Length(APlanes) < 3) or (Length(AStrides) < 3) then
    raise ESprite3DH264Error.Create('OpenH264 needs three planes.');
  FillChar(Picture, SizeOf(Picture), 0);
  Picture.iColorFormat := VIDEO_FORMAT_I420;
  Picture.iPicWidth := FWidth;
  Picture.iPicHeight := FHeight;
  // Rate control works from the time between pictures, in milliseconds
  Picture.uiTimeStamp := Round(FCount * 1000 / FFrameRate);
  Inc(FCount);
  for I := 0 to 2 do
  begin
    Picture.pData[I] := APlanes[I];
    Picture.iStride[I] := AStrides[I];
  end;
  FillChar(FInfo^, FRAME_INFO_SIZE, 0);
  Check(PEncoder(FEncoder)^^.EncodeFrame(PEncoder(FEncoder), @Picture, FInfo),
    'encoding a frame');
  AKey := InfoFrameType(FInfo) = VIDEO_FRAME_TYPE_IDR;
  if InfoFrameType(FInfo) in [VIDEO_FRAME_TYPE_INVALID, VIDEO_FRAME_TYPE_SKIP] then
    AData := nil
  else
    AData := Collect;
end;

end.
