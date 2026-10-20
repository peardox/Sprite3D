//** @abstract(Writes a sequence of frames as a video-only MP4 file with the FFmpeg libraries,
//** loaded only when first needed.)
//**
//** The video is MPEG-4 Part 2, FFmpeg's own @code(mpeg4) encoder, which every FFmpeg build
//** has and which needs no library beyond FFmpeg's own under its LGPL licence. It plays in
//** desktop players such as VLC, QuickTime and the Windows players, but not in web browsers.
//** There is no sound track.
//**
//** The types and constants come from the DelphiFFmpeg.com FFmpeg 8.1 headers in the
//** @code(ffmpeg) folder, used as they are. Those headers bind every function statically, so
//** calling any of them would make the program fail to start where the libraries are
//** missing. This unit calls none of them: it loads avutil, avcodec and avformat itself with
//** LoadLibrary or dlopen and looks up the two dozen functions it needs, with the headers'
//** signatures, so Sprite3D starts and runs whether or not the libraries are there, and
//** offers video only when VideoAvailable says they loaded.
//**
//** The libraries must be FFmpeg 8.1's major versions, as the headers are: avutil 60,
//** avcodec 62 and avformat 62. They are looked for, in order, next to the executable, in a
//** @code(dlls/<platform>) folder beside it or in any folder above it (so a build run from the
//** source tree finds the repository's @code(dlls) folder), in a macOS bundle's Frameworks
//** folder, and last wherever the system looks for libraries. @code(<platform>) is
//** @code(win64), @code(macarm), @code(macx64) or @code(linux64).
//**
//** @preformatted(
//** Windows   avutil-60.dll         avcodec-62.dll         avformat-62.dll
//** macOS     libavutil.60.dylib    libavcodec.62.dylib    libavformat.62.dylib
//** Linux     libavutil.so.60       libavcodec.so.62       libavformat.so.62
//** )
//**
//** Any other FFmpeg library one of those needs, such as swresample, must be in the same
//** folder; it is loaded first if it is there.
//**
//** For the main thread, or any one thread at a time.
unit Sprite3DVideo;

{
  Writes a sequence of frames as a video-only MP4 file with the FFmpeg
  libraries, loaded only when first needed.

  The video is MPEG-4 Part 2, FFmpeg's own mpeg4 encoder, which every FFmpeg
  build has and which needs no library beyond FFmpeg's own under its LGPL
  licence. It plays in desktop players such as VLC, QuickTime and the
  Windows players, but not in web browsers. There is no sound track.

  The types and constants come from the DelphiFFmpeg.com FFmpeg 8.1 headers
  in the ffmpeg folder, used as they are. Those headers bind every function
  statically, so calling any of them would make the program fail to start
  where the libraries are missing. This unit calls none of them: it loads
  avutil, avcodec and avformat itself with LoadLibrary or dlopen and looks
  up the two dozen functions it needs, with the headers' signatures, so
  Sprite3D starts and runs whether or not the libraries are there, and
  offers video only when VideoAvailable says they loaded.

  The libraries must be FFmpeg 8.1's major versions, as the headers are:
  avutil 60, avcodec 62 and avformat 62. They are looked for, in order, next
  to the executable, in a dlls/<platform> folder beside it or in any folder
  above it (so a build run from the source tree finds the repository's dlls
  folder), in a macOS bundle's Frameworks folder, and last wherever the
  system looks for libraries. <platform> is win64, macarm, macx64 or
  linux64.

    Windows   avutil-60.dll         avcodec-62.dll         avformat-62.dll
    macOS     libavutil.60.dylib    libavcodec.62.dylib    libavformat.62.dylib
    Linux     libavutil.so.60       libavcodec.so.62       libavformat.so.62

  Any other FFmpeg library one of those needs, such as swresample, must be
  in the same folder; it is loaded first if it is there.

  For the main thread, or any one thread at a time.
}

interface

uses
  System.SysUtils, Sprite3DSpriteSheet;

type
  //** @abstract(Raised when a video cannot be written.)
  //**
  //** The message says which step failed and, where FFmpeg gave one, its reason.
  /// <summary>Raised when a video cannot be written.</summary>
  /// <remarks>The message says which step failed and, where FFmpeg gave one, its
  /// reason.</remarks>
  ESprite3DVideoError = class(Exception);

//** @abstract(Whether MP4 video can be written: the FFmpeg libraries loaded and have the
//** encoder.)
//**
//** The first call looks for and loads the libraries, which takes a moment; later calls
//** return the same answer at once. The libraries stay loaded until the program ends.
//**
//** @returns(True if SaveMpeg4Video can be used.)
/// <summary>Whether MP4 video can be written: the FFmpeg libraries loaded and have the
/// encoder.</summary>
/// <remarks>The first call looks for and loads the libraries, which takes a moment; later
/// calls return the same answer at once. The libraries stay loaded until the program
/// ends.</remarks>
/// <returns>True if SaveMpeg4Video can be used.</returns>
function VideoAvailable: Boolean;

//** @abstract(Why video is or is not available, for a log or a hint.)
//**
//** Loads the libraries if VideoAvailable has not yet been called.
//**
//** @returns(Where the libraries were loaded from and their versions, or what was missing.)
/// <summary>Why video is or is not available, for a log or a hint.</summary>
/// <remarks>Loads the libraries if VideoAvailable has not yet been called.</remarks>
/// <returns>Where the libraries were loaded from and their versions, or what was
/// missing.</returns>
function VideoStatus: String;

//** @abstract(Writes the frames as a video-only MPEG-4 Part 2 MP4 file.)
//**
//** One cycle of ACycleSeconds is shown as Length(AFrames) equal frames, so the video lasts
//** exactly one cycle; the frame rate is carried as an exact fraction where it can be. MP4
//** has no transparency, so each frame is laid over black, which a Solid or Gradient
//** background will already have covered. The width and height are rounded up to even
//** numbers, as the encoder's colour format needs, with black in the extra row or column.
//** Quality is fixed and high (quantiser 3), every twelfth frame is a key frame and there are
//** no B-frames. The file replaces any of that name; the folder must exist. Blocks while it
//** encodes.
//**
//** @param(AFrames The frames, in order; at least one, all the same size.)
//**
//** @param(AFileName The file to write, normally ending in @code(.mp4).)
//**
//** @param(ACycleSeconds How long all the frames last together, in seconds; more than 0.)
//**
//** @raises(ESprite3DVideoError If the libraries are not available, or FFmpeg fails at any
//** step; a part-written file may be left behind.)
//**
//** @raises(EArgumentException If there are no frames, they differ in size, or
//** ACycleSeconds is not more than 0.)
/// <summary>Writes the frames as a video-only MPEG-4 Part 2 MP4 file.</summary>
/// <remarks>One cycle of ACycleSeconds is shown as Length(AFrames) equal frames, so the video
/// lasts exactly one cycle; the frame rate is carried as an exact fraction where it can be.
/// MP4 has no transparency, so each frame is laid over black, which a Solid or Gradient
/// background will already have covered. The width and height are rounded up to even numbers,
/// as the encoder's colour format needs, with black in the extra row or column. Quality is
/// fixed and high (quantiser 3), every twelfth frame is a key frame and there are no
/// B-frames. The file replaces any of that name; the folder must exist. Blocks while it
/// encodes.</remarks>
/// <param name="AFrames">The frames, in order; at least one, all the same size.</param>
/// <param name="AFileName">The file to write, normally ending in <c>.mp4</c>.</param>
/// <param name="ACycleSeconds">How long all the frames last together, in seconds; more than
/// 0.</param>
/// <exception cref="ESprite3DVideoError">If the libraries are not available, or FFmpeg fails
/// at any step; a part-written file may be left behind.</exception>
/// <exception cref="EArgumentException">If there are no frames, they differ in size, or
/// ACycleSeconds is not more than 0.</exception>
procedure SaveMpeg4Video(const AFrames: TArray<TSprite3DImage>; const AFileName: String;
  const ACycleSeconds: Double);

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.Classes, System.IOUtils, System.Math,
  // The DelphiFFmpeg.com headers: types and constants only, see above
  libavutil, libavutil_error, libavutil_frame, libavutil_pixfmt, libavutil_rational,
  libavcodec, libavcodec_codec, libavcodec_codec_id, libavcodec_codec_par,
  libavcodec_packet, libavformat, libavformat_avio;

const
  // The major versions the headers describe; the libraries must match, or
  // the records' layouts may not
  AVUTIL_MAJOR = 60;
  AVCODEC_MAJOR = 62;
  AVFORMAT_MAJOR = 62;

  {$IF DEFINED(MSWINDOWS)}
  PLATFORM_FOLDER = 'win64';
  {$ELSEIF DEFINED(MACOS) and DEFINED(CPUARM64)}
  PLATFORM_FOLDER = 'macarm';
  {$ELSEIF DEFINED(MACOS)}
  PLATFORM_FOLDER = 'macx64';
  {$ELSE}
  PLATFORM_FOLDER = 'linux64';
  {$IFEND}

  // AVERROR(EAGAIN): the headers give it for Windows and macOS only
  {$IF DEFINED(MACOS)}
  ERROR_AGAIN = -35;
  {$ELSE}
  ERROR_AGAIN = -11;
  {$IFEND}

  NO_TIMESTAMP = Int64($8000000000000000);   // AV_NOPTS_VALUE
  QUANTISER = 3;      // 2 is best and largest; 31 worst and smallest
  KEY_INTERVAL = 12;  // frames between key frames
  // MPEG-4 Part 2 stores the time base's denominator in 16 bits
  MAX_TIME_DEN = 65535;

type
  // The functions used, with the headers' signatures; size_t is NativeUInt
  // here, as the headers' Size_t is 32 bits on Linux
  TAvutilVersion = function: Cardinal; cdecl;
  TAvFrameAlloc = function: PAVFrame; cdecl;
  TAvFrameFree = procedure(frame: PPAVFrame); cdecl;
  TAvFrameGetBuffer = function(frame: PAVFrame; align: Integer): Integer; cdecl;
  TAvFrameMakeWritable = function(frame: PAVFrame): Integer; cdecl;
  TAvStrError = function(errnum: Integer; errbuf: PAnsiChar;
    errbuf_size: NativeUInt): Integer; cdecl;
  TAvcodecVersion = function: Cardinal; cdecl;
  TAvcodecFindEncoder = function(id: TAVCodecID): PAVCodec; cdecl;
  TAvcodecAllocContext3 = function(const codec: PAVCodec): PAVCodecContext; cdecl;
  TAvcodecFreeContext = procedure(avctx: PPAVCodecContext); cdecl;
  TAvcodecOpen2 = function(avctx: PAVCodecContext; const codec: PAVCodec;
    options: Pointer): Integer; cdecl;
  TAvcodecSendFrame = function(avctx: PAVCodecContext; const frame: PAVFrame): Integer; cdecl;
  TAvcodecReceivePacket = function(avctx: PAVCodecContext; avpkt: PAVPacket): Integer; cdecl;
  TAvcodecParametersFromContext = function(par: PAVCodecParameters;
    const codec: PAVCodecContext): Integer; cdecl;
  TAvPacketAlloc = function: PAVPacket; cdecl;
  TAvPacketFree = procedure(pkt: PPAVPacket); cdecl;
  TAvPacketUnref = procedure(pkt: PAVPacket); cdecl;
  TAvformatVersion = function: Cardinal; cdecl;
  TAvformatAllocOutputContext2 = function(ctx: PPAVFormatContext; oformat: PAVOutputFormat;
    const format_name, filename: PAnsiChar): Integer; cdecl;
  TAvformatNewStream = function(s: PAVFormatContext; const c: PAVCodec): PAVStream; cdecl;
  TAvioOpen = function(s: PPAVIOContext; const url: PAnsiChar; flags: Integer): Integer; cdecl;
  TAvioClosep = function(s: PPAVIOContext): Integer; cdecl;
  TAvformatWriteHeader = function(s: PAVFormatContext; options: Pointer): Integer; cdecl;
  TAvInterleavedWriteFrame = function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
  TAvWriteTrailer = function(s: PAVFormatContext): Integer; cdecl;
  TAvformatFreeContext = procedure(s: PAVFormatContext); cdecl;

  TFFmpegApi = record
    avutil_version: TAvutilVersion;
    av_frame_alloc: TAvFrameAlloc;
    av_frame_free: TAvFrameFree;
    av_frame_get_buffer: TAvFrameGetBuffer;
    av_frame_make_writable: TAvFrameMakeWritable;
    av_strerror: TAvStrError;
    avcodec_version: TAvcodecVersion;
    avcodec_find_encoder: TAvcodecFindEncoder;
    avcodec_alloc_context3: TAvcodecAllocContext3;
    avcodec_free_context: TAvcodecFreeContext;
    avcodec_open2: TAvcodecOpen2;
    avcodec_send_frame: TAvcodecSendFrame;
    avcodec_receive_packet: TAvcodecReceivePacket;
    avcodec_parameters_from_context: TAvcodecParametersFromContext;
    av_packet_alloc: TAvPacketAlloc;
    av_packet_free: TAvPacketFree;
    av_packet_unref: TAvPacketUnref;
    avformat_version: TAvformatVersion;
    avformat_alloc_output_context2: TAvformatAllocOutputContext2;
    avformat_new_stream: TAvformatNewStream;
    avio_open: TAvioOpen;
    avio_closep: TAvioClosep;
    avformat_write_header: TAvformatWriteHeader;
    av_interleaved_write_frame: TAvInterleavedWriteFrame;
    av_write_trailer: TAvWriteTrailer;
    avformat_free_context: TAvformatFreeContext;
  end;

var
  Api: TFFmpegApi;
  Tried: Boolean;
  Loaded: Boolean;
  Status: String;

{ Loading }

// A library's file name on this platform
function LibraryFile(const AName: String; const AMajor: Integer): String;
begin
  {$IF DEFINED(MSWINDOWS)}
  Result := Format('%s-%d.dll', [AName, AMajor]);
  {$ELSEIF DEFINED(MACOS)}
  Result := Format('lib%s.%d.dylib', [AName, AMajor]);
  {$ELSE}
  Result := Format('lib%s.so.%d', [AName, AMajor]);
  {$IFEND}
end;

// Loads a library by full path, or by bare name from the system's search
// path; 0 if it cannot be loaded. On Windows, a full path also makes the
// libraries it needs be found in its own folder.
function OpenLibrary(const APath: String): HMODULE;
begin
  {$IFDEF MSWINDOWS}
  if ExtractFilePath(APath) <> String.Empty then
    Result := LoadLibraryEx(PChar(APath), 0, LOAD_WITH_ALTERED_SEARCH_PATH)
  else
    Result := LoadLibrary(PChar(APath));
  {$ELSE}
  Result := System.SysUtils.LoadLibrary(PChar(APath));
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

// The folders to look in, best first; the last, empty, means the system's
// own search path
function CandidateFolders: TArray<String>;
var
  ExeDir, Dir, Parent: String;
  Level: Integer;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  Result := [ExeDir, TPath.Combine(ExeDir, TPath.Combine('dlls', PLATFORM_FOLDER))];
  {$IFDEF MACOS}
  // Inside an application bundle: Contents/MacOS/../Frameworks
  Result := Result + [TPath.GetFullPath(TPath.Combine(ExeDir, '../Frameworks'))];
  {$ENDIF}
  // A build run from the source tree, such as src/Win64/Debug, finds the
  // repository's dlls folder a few levels up
  Dir := ExcludeTrailingPathDelimiter(ExeDir);
  for Level := 1 to 6 do
  begin
    Parent := ExtractFileDir(Dir);
    if (Parent = String.Empty) or (Parent = Dir) then
      Break;
    Dir := Parent;
    Result := Result + [TPath.Combine(Dir, TPath.Combine('dlls', PLATFORM_FOLDER))];
  end;
  Result := Result + [String.Empty];
end;

function LoadApi(out AError: String): Boolean;
var
  Folder, Path: String;
  Util, Codec, Format_: HMODULE;
  Missing: TArray<String>;

  procedure Need(var AProc; const AModule: HMODULE; const AName: String);
  begin
    Pointer(AProc) := FindSymbol(AModule, AName);
    if Pointer(AProc) = nil then
      Missing := Missing + [AName];
  end;

  function Open(const AName: String; const AMajor: Integer): HMODULE;
  begin
    if Folder = String.Empty then
      Result := OpenLibrary(LibraryFile(AName, AMajor))
    else
      Result := OpenLibrary(TPath.Combine(Folder, LibraryFile(AName, AMajor)));
  end;

  procedure OpenOptional(const AName: String; const AMajor: Integer);
  begin
    // Libraries the main three may need, loaded first so they are found
    if (Folder <> String.Empty) and
      TFile.Exists(TPath.Combine(Folder, LibraryFile(AName, AMajor))) then
      Open(AName, AMajor);
  end;

begin
  Result := False;
  AError := String.Empty;
  Util := 0;
  Codec := 0;
  Format_ := 0;
  for Folder in CandidateFolders do
  begin
    if (Folder <> String.Empty) and
      not TFile.Exists(TPath.Combine(Folder, LibraryFile('avutil', AVUTIL_MAJOR))) then
      Continue;
    Util := Open('avutil', AVUTIL_MAJOR);
    if Util = 0 then
      Continue;
    OpenOptional('swresample', LIBSWRESAMPLE_VERSION_MAJOR);
    OpenOptional('swscale', LIBSWSCALE_VERSION_MAJOR);
    Codec := Open('avcodec', AVCODEC_MAJOR);
    if Codec <> 0 then
      Format_ := Open('avformat', AVFORMAT_MAJOR);
    if Format_ <> 0 then
      Break;
    if Folder = String.Empty then
      Path := 'the system library path'
    else
      Path := Folder;
    AError := Format('Found %s in %s but could not load %s and %s with it.',
      [LibraryFile('avutil', AVUTIL_MAJOR), Path, LibraryFile('avcodec', AVCODEC_MAJOR),
       LibraryFile('avformat', AVFORMAT_MAJOR)]);
  end;
  if Format_ = 0 then
  begin
    if AError = String.Empty then
      AError := Format('FFmpeg %s libraries (%s, %s, %s) were not found next to the ' +
        'program, in a dlls%s%s folder or on the system library path.',
        [FFMPEG_VERSION, LibraryFile('avutil', AVUTIL_MAJOR),
         LibraryFile('avcodec', AVCODEC_MAJOR), LibraryFile('avformat', AVFORMAT_MAJOR),
         PathDelim, PLATFORM_FOLDER]);
    Exit;
  end;

  Missing := nil;
  Need(Api.avutil_version, Util, 'avutil_version');
  Need(Api.av_frame_alloc, Util, 'av_frame_alloc');
  Need(Api.av_frame_free, Util, 'av_frame_free');
  Need(Api.av_frame_get_buffer, Util, 'av_frame_get_buffer');
  Need(Api.av_frame_make_writable, Util, 'av_frame_make_writable');
  Need(Api.av_strerror, Util, 'av_strerror');
  Need(Api.avcodec_version, Codec, 'avcodec_version');
  Need(Api.avcodec_find_encoder, Codec, 'avcodec_find_encoder');
  Need(Api.avcodec_alloc_context3, Codec, 'avcodec_alloc_context3');
  Need(Api.avcodec_free_context, Codec, 'avcodec_free_context');
  Need(Api.avcodec_open2, Codec, 'avcodec_open2');
  Need(Api.avcodec_send_frame, Codec, 'avcodec_send_frame');
  Need(Api.avcodec_receive_packet, Codec, 'avcodec_receive_packet');
  Need(Api.avcodec_parameters_from_context, Codec, 'avcodec_parameters_from_context');
  Need(Api.av_packet_alloc, Codec, 'av_packet_alloc');
  Need(Api.av_packet_free, Codec, 'av_packet_free');
  Need(Api.av_packet_unref, Codec, 'av_packet_unref');
  Need(Api.avformat_version, Format_, 'avformat_version');
  Need(Api.avformat_alloc_output_context2, Format_, 'avformat_alloc_output_context2');
  Need(Api.avformat_new_stream, Format_, 'avformat_new_stream');
  Need(Api.avio_open, Format_, 'avio_open');
  Need(Api.avio_closep, Format_, 'avio_closep');
  Need(Api.avformat_write_header, Format_, 'avformat_write_header');
  Need(Api.av_interleaved_write_frame, Format_, 'av_interleaved_write_frame');
  Need(Api.av_write_trailer, Format_, 'av_write_trailer');
  Need(Api.avformat_free_context, Format_, 'avformat_free_context');
  if Length(Missing) > 0 then
  begin
    AError := 'The FFmpeg libraries lack: ' + String.Join(', ', Missing);
    Exit;
  end;

  // The headers' records match these major versions only
  if (Api.avutil_version shr 16 <> AVUTIL_MAJOR) or
    (Api.avcodec_version shr 16 <> AVCODEC_MAJOR) or
    (Api.avformat_version shr 16 <> AVFORMAT_MAJOR) then
  begin
    AError := Format('The FFmpeg libraries are the wrong version (avutil %d, avcodec %d, ' +
      'avformat %d; FFmpeg %s needs %d, %d, %d).',
      [Api.avutil_version shr 16, Api.avcodec_version shr 16, Api.avformat_version shr 16,
       FFMPEG_VERSION, AVUTIL_MAJOR, AVCODEC_MAJOR, AVFORMAT_MAJOR]);
    Exit;
  end;

  if Api.avcodec_find_encoder(AV_CODEC_ID_MPEG4) = nil then
  begin
    AError := 'The FFmpeg libraries were built without the MPEG-4 encoder.';
    Exit;
  end;

  if Folder = String.Empty then
    Path := 'the system library path'
  else
    Path := Folder;
  AError := Format('FFmpeg loaded from %s (avutil %d.%d, avcodec %d.%d, avformat %d.%d)',
    [Path, Api.avutil_version shr 16, (Api.avutil_version shr 8) and $FF,
     Api.avcodec_version shr 16, (Api.avcodec_version shr 8) and $FF,
     Api.avformat_version shr 16, (Api.avformat_version shr 8) and $FF]);
  Result := True;
end;

function VideoAvailable: Boolean;
begin
  if not Tried then
  begin
    Tried := True;
    try
      Loaded := LoadApi(Status);
    except
      on E: Exception do
      begin
        Loaded := False;
        Status := 'The FFmpeg libraries could not be loaded: ' + E.Message;
      end;
    end;
  end;
  Result := Loaded;
end;

function VideoStatus: String;
begin
  VideoAvailable;
  Result := Status;
end;

{ Writing }

function ErrorText(const ACode: Integer): String;
var
  Buffer: array[0..255] of AnsiChar;
begin
  FillChar(Buffer, SizeOf(Buffer), 0);
  if Assigned(Api.av_strerror) and (Api.av_strerror(ACode, @Buffer[0], Length(Buffer)) = 0) then
    Result := String(AnsiString(PAnsiChar(@Buffer[0])))
  else
    Result := Format('error %d', [ACode]);
end;

procedure Check(const ACode: Integer; const AStep: String);
begin
  if ACode < 0 then
    raise ESprite3DVideoError.CreateFmt('%s: %s', [AStep, ErrorText(ACode)]);
end;

function GreatestDivisor(A, B: Int64): Int64;
var
  T: Int64;
begin
  A := Abs(A);
  B := Abs(B);
  while B <> 0 do
  begin
    T := A mod B;
    A := B;
    B := T;
  end;
  Result := Max(1, A);
end;

// One frame's length as a fraction of a second: the cycle in milliseconds
// over the frame count times 1000, reduced; made coarser only if MPEG-4's
// 16-bit limit needs it
function FrameTimeBase(const ACycleSeconds: Double; const AFrames: Integer): TAVRational;
var
  Num, Den, G: Int64;
begin
  Num := Max(1, Round(ACycleSeconds * 1000));
  Den := Int64(AFrames) * 1000;
  G := GreatestDivisor(Num, Den);
  Num := Num div G;
  Den := Den div G;
  while Den > MAX_TIME_DEN do
  begin
    Den := (Den + 1) div 2;
    Num := Max(1, (Num + 1) div 2);
  end;
  Result.num := Integer(Num);
  Result.den := Integer(Den);
end;

// A timestamp from one time base to another, rounded to nearest
function Rescale(const AValue: Int64; const AFrom, ATo: TAVRational): Int64;
var
  N, D: Int64;
begin
  if AValue = NO_TIMESTAMP then
    Exit(AValue);
  N := AValue * AFrom.num * ATo.den;
  D := Int64(AFrom.den) * ATo.num;
  if D = 0 then
    Exit(AValue);
  if N >= 0 then
    Result := (N + D div 2) div D
  else
    Result := -((-N + D div 2) div D);
end;

// One frame as YUV 4:2:0 (BT.601, limited range), laid over black, into
// AFrame, whose size is the image's rounded up to even numbers
procedure FillYuv(const AImage: TSprite3DImage; const AFrame: PAVFrame);
var
  X, Y, DX, DY, SX, SY, A, R, G, B, SumR, SumG, SumB: Integer;
  Src: PByte;
  RowY, RowU, RowV: PByte;
begin
  for Y := 0 to AFrame.height - 1 do
  begin
    RowY := PByte(AFrame.data[0]) + NativeInt(Y) * AFrame.linesize[0];
    for X := 0 to AFrame.width - 1 do
    begin
      if (X < AImage.Width) and (Y < AImage.Height) then
      begin
        Src := @AImage.Pixels[(NativeInt(Y) * AImage.Width + X) * 4];
        A := Src[3];
        R := (Src[0] * A + 127) div 255;
        G := (Src[1] * A + 127) div 255;
        B := (Src[2] * A + 127) div 255;
      end
      else
      begin
        R := 0;
        G := 0;
        B := 0;
      end;
      RowY[X] := Byte(((66 * R + 129 * G + 25 * B + 128) div 256) + 16);
    end;
  end;

  for Y := 0 to AFrame.height div 2 - 1 do
  begin
    RowU := PByte(AFrame.data[1]) + NativeInt(Y) * AFrame.linesize[1];
    RowV := PByte(AFrame.data[2]) + NativeInt(Y) * AFrame.linesize[2];
    for X := 0 to AFrame.width div 2 - 1 do
    begin
      // The average of the 2 x 2 pixels this sample covers
      SumR := 0;
      SumG := 0;
      SumB := 0;
      for DY := 0 to 1 do
        for DX := 0 to 1 do
        begin
          SX := X * 2 + DX;
          SY := Y * 2 + DY;
          if (SX < AImage.Width) and (SY < AImage.Height) then
          begin
            Src := @AImage.Pixels[(NativeInt(SY) * AImage.Width + SX) * 4];
            A := Src[3];
            Inc(SumR, (Src[0] * A + 127) div 255);
            Inc(SumG, (Src[1] * A + 127) div 255);
            Inc(SumB, (Src[2] * A + 127) div 255);
          end;
        end;
      R := (SumR + 2) div 4;
      G := (SumG + 2) div 4;
      B := (SumB + 2) div 4;
      // 32896 = 128 * 256 + 128: the offset and the rounding, kept positive
      RowU[X] := Byte((-38 * R - 74 * G + 112 * B + 32896) div 256);
      RowV[X] := Byte((112 * R - 94 * G - 18 * B + 32896) div 256);
    end;
  end;
end;

procedure SaveMpeg4Video(const AFrames: TArray<TSprite3DImage>; const AFileName: String;
  const ACycleSeconds: Double);
var
  Output: PAVFormatContext;
  Stream: PAVStream;
  Encoder: PAVCodec;
  Context: PAVCodecContext;
  Frame: PAVFrame;
  Packet: PAVPacket;
  FileName: UTF8String;
  W, H, I, Ret: Integer;
  TimeBase: TAVRational;
  Opened, HeaderWritten: Boolean;

  // Every packet the encoder has ready, into the file; True at the end of
  // the stream
  function Drain: Boolean;
  var
    Code: Integer;
  begin
    Result := False;
    repeat
      Code := Api.avcodec_receive_packet(Context, Packet);
      if Code = ERROR_AGAIN then
        Exit(False);
      if Code = AVERROR_EOF then
        Exit(True);
      Check(Code, 'Encoding a frame');
      if Packet.duration <= 0 then
        Packet.duration := 1;
      Packet.pts := Rescale(Packet.pts, Context.time_base, Stream.time_base);
      Packet.dts := Rescale(Packet.dts, Context.time_base, Stream.time_base);
      Packet.duration := Rescale(Packet.duration, Context.time_base, Stream.time_base);
      Packet.stream_index := Stream.index;
      // The muxer takes the packet's contents and leaves it blank
      Check(Api.av_interleaved_write_frame(Output, Packet), 'Writing a frame');
    until False;
  end;

begin
  if not VideoAvailable then
    raise ESprite3DVideoError.Create(VideoStatus);
  if Length(AFrames) = 0 then
    raise EArgumentException.Create('There are no frames.');
  if ACycleSeconds <= 0 then
    raise EArgumentException.Create('The video must last some time.');
  W := AFrames[0].Width;
  H := AFrames[0].Height;
  for I := 0 to High(AFrames) do
    if (AFrames[I].Width <> W) or (AFrames[I].Height <> H) or
      (Length(AFrames[I].Pixels) <> Int64(W) * H * 4) then
      raise EArgumentException.Create('The frames are not all the same size.');

  Output := nil;
  Context := nil;
  Frame := nil;
  Packet := nil;
  Opened := False;
  HeaderWritten := False;
  FileName := UTF8String(AFileName);
  TimeBase := FrameTimeBase(ACycleSeconds, Length(AFrames));
  try
    Check(Api.avformat_alloc_output_context2(@Output, nil, 'mp4', PAnsiChar(FileName)),
      'Setting up the MP4 file');
    if Output = nil then
      raise ESprite3DVideoError.Create('Setting up the MP4 file failed.');

    Encoder := Api.avcodec_find_encoder(AV_CODEC_ID_MPEG4);
    if Encoder = nil then
      raise ESprite3DVideoError.Create('FFmpeg has no MPEG-4 encoder.');
    Stream := Api.avformat_new_stream(Output, nil);
    if Stream = nil then
      raise ESprite3DVideoError.Create('Adding the video stream failed.');
    Context := Api.avcodec_alloc_context3(Encoder);
    if Context = nil then
      raise ESprite3DVideoError.Create('Setting up the encoder failed.');

    // Even sizes, as 4:2:0 colour needs; the extra row or column is black
    Context.codec_id := AV_CODEC_ID_MPEG4;
    Context.width := W + (W and 1);
    Context.height := H + (H and 1);
    Context.time_base := TimeBase;
    Context.framerate.num := TimeBase.den;
    Context.framerate.den := TimeBase.num;
    Context.pix_fmt := AV_PIX_FMT_YUV420P;
    Context.gop_size := KEY_INTERVAL;
    Context.max_b_frames := 0;
    // Constant quality rather than a bit rate, which suits short clips of
    // any size
    Context.bit_rate := 0;
    Context.flags := Context.flags or AV_CODEC_FLAG_QSCALE;
    Context.global_quality := FF_QP2LAMBDA * QUANTISER;
    if (Output.oformat.flags and AVFMT_GLOBALHEADER) <> 0 then
      Context.flags := Context.flags or AV_CODEC_FLAG_GLOBAL_HEADER;
    Check(Api.avcodec_open2(Context, Encoder, nil), 'Opening the MPEG-4 encoder');

    Stream.time_base := TimeBase;
    Stream.avg_frame_rate := Context.framerate;
    Check(Api.avcodec_parameters_from_context(Stream.codecpar, Context),
      'Describing the video stream');

    if (Output.oformat.flags and AVFMT_NOFILE) = 0 then
    begin
      Check(Api.avio_open(@Output.pb, PAnsiChar(FileName), AVIO_FLAG_WRITE),
        'Creating ' + AFileName);
      Opened := True;
    end;
    // The muxer may choose its own time base for the stream here
    Check(Api.avformat_write_header(Output, nil), 'Writing the MP4 header');
    HeaderWritten := True;

    Frame := Api.av_frame_alloc;
    Packet := Api.av_packet_alloc;
    if (Frame = nil) or (Packet = nil) then
      raise ESprite3DVideoError.Create('Out of memory for the video frames.');
    Frame.format := Ord(AV_PIX_FMT_YUV420P);
    Frame.width := Context.width;
    Frame.height := Context.height;
    Check(Api.av_frame_get_buffer(Frame, 0), 'Allocating a video frame');

    for I := 0 to High(AFrames) do
    begin
      // The encoder may still hold the last frame's buffer
      Check(Api.av_frame_make_writable(Frame), 'Preparing a video frame');
      FillYuv(AFrames[I], Frame);
      Frame.pts := I;
      Check(Api.avcodec_send_frame(Context, Frame), 'Encoding a frame');
      Drain;
    end;
    // Flush the encoder
    Ret := Api.avcodec_send_frame(Context, nil);
    if Ret <> AVERROR_EOF then
      Check(Ret, 'Finishing the video');
    while not Drain do
      ;   // Drain stops at the end of the stream

    Check(Api.av_write_trailer(Output), 'Finishing the MP4 file');
    HeaderWritten := False;
  finally
    if HeaderWritten then
      Api.av_write_trailer(Output);   // after an error: close the file tidily
    if Packet <> nil then
      Api.av_packet_free(@Packet);
    if Frame <> nil then
      Api.av_frame_free(@Frame);
    if Context <> nil then
      Api.avcodec_free_context(@Context);
    if Opened then
      Api.avio_closep(@Output.pb);
    if Output <> nil then
      Api.avformat_free_context(Output);
  end;
end;

end.
