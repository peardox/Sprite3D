//** @abstract(The displays attached to the computer, with their names, sizes and modes, on
//** every platform.)
//**
//** TPeardoxDisplays lists every display when it is created, and RefreshRateFor gives the
//** refresh rate of the one a form is on, which Sprite3D uses to limit the view's frame rate.
//** How much is known depends on the platform:
//**
//** @preformatted(
//** Windows   every monitor Windows knows of: its device name, the monitor's own name and
//**           physical size where its EDID gives them, its desktop and work areas, its
//**           current mode and every mode it offers
//** macOS     FMX's displays, with each one's refresh rate from CoreGraphics
//** Android   FMX's display, with the refresh rate Display.getRefreshRate gives
//** iOS       FMX's display; refresh rate 0, unknown
//** Linux     FMX's display; refresh rate 0, unknown
//** )
//**
//** Outside Windows a display has no device or monitor name of its own, so both are made up,
//** such as @code(Display 2), its only mode is its current one, its colour depth is 0,
//** unknown, and its physical size is unknown. A refresh rate of 0 means the system did not
//** say, as macOS does for some built-in panels. For the main thread.
unit DisplayData;

{
  The displays attached to the computer, with their names, sizes and modes,
  on every platform.

  TPeardoxDisplays lists every display when it is created, and
  RefreshRateFor gives the refresh rate of the one a form is on, which
  Sprite3D uses to limit the view's frame rate. How much is known depends on
  the platform:

    Windows   every monitor Windows knows of: its device name, the monitor's
              own name and physical size where its EDID gives them, its
              desktop and work areas, its current mode and every mode it
              offers
    macOS     FMX's displays, with each one's refresh rate from CoreGraphics
    Android   FMX's display, with the refresh rate Display.getRefreshRate
              gives
    iOS       FMX's display; refresh rate 0, unknown
    Linux     FMX's display; refresh rate 0, unknown

  Outside Windows a display has no device or monitor name of its own, so
  both are made up, such as "Display 2", its only mode is its current one,
  its colour depth is 0, unknown, and its physical size is unknown. A
  refresh rate of 0 means the system did not say, as macOS does for some
  built-in panels. For the main thread.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  FMX.Forms;

type
  //** @abstract(One display mode: resolution, colour depth and refresh rate.)
  /// <summary>One display mode: resolution, colour depth and refresh rate.</summary>
  TDisplayMode = record
    //** @abstract(The width in pixels.)
    /// <summary>The width in pixels.</summary>
    Width: Integer;
    //** @abstract(The height in pixels.)
    /// <summary>The height in pixels.</summary>
    Height: Integer;
    //** @abstract(Bits per pixel; 0 if unknown.)
    /// <summary>Bits per pixel; 0 if unknown.</summary>
    BitsPerPixel: Integer;
    //** @abstract(The refresh rate in hertz; 0 if unknown.)
    /// <summary>The refresh rate in hertz; 0 if unknown.</summary>
    RefreshRate: Integer; // Hz
    //** @abstract(The mode as text, such as @code(2560 x 1440, 32-bit, 144 Hz).)
    //**
    //** A colour depth or refresh rate of 0, unknown, is left out.
    //**
    //** @returns(The text.)
    /// <summary>The mode as text, such as <c>2560 x 1440, 32-bit, 144 Hz</c>.</summary>
    /// <remarks>A colour depth or refresh rate of 0, unknown, is left out.</remarks>
    /// <returns>The text.</returns>
    function ToString: string;
  end;

  //** @abstract(A list of display modes.)
  /// <summary>A list of display modes.</summary>
  TDisplayModeList = TList<TDisplayMode>;

  //** @abstract(One display, as the system describes it; on Windows, with its EDID.)
  //**
  //** AvailableModes belongs to the TPeardoxDisplays that made the record; a copy shares it.
  //** See the unit description for what is known outside Windows.
  /// <summary>One display, as the system describes it; on Windows, with its EDID.</summary>
  /// <remarks>AvailableModes belongs to the TPeardoxDisplays that made the record; a copy
  /// shares it. See the unit description for what is known outside Windows.</remarks>
  TDisplayInfo = record
      //** @abstract(Windows' device name, such as @code(\\.\DISPLAY1); elsewhere
      //** @code(Display) and its number.)
      /// <summary>Windows' device name, such as <c>\\.\DISPLAY1</c>; elsewhere
      /// <c>Display</c> and its number.</summary>
      DeviceName: string;
      //** @abstract(The monitor's own name from its EDID, else the adapter's description;
      //** elsewhere @code(Main display) or DeviceName.)
      /// <summary>The monitor's own name from its EDID, else the adapter's description;
      /// elsewhere <c>Main display</c> or DeviceName.</summary>
      FriendlyName: string;
      //** @abstract(The monitor's area of the desktop, in desktop pixels.)
      /// <summary>The monitor's area of the desktop, in desktop pixels.</summary>
      MonitorRect: TRect;
      //** @abstract(The monitor's area less the taskbar and docked toolbars.)
      /// <summary>The monitor's area less the taskbar and docked toolbars.</summary>
      WorkRect: TRect;
      //** @abstract(Whether this is the primary monitor.)
      /// <summary>Whether this is the primary monitor.</summary>
      IsPrimary: Boolean;
      //** @abstract(The mode the monitor is in.)
      /// <summary>The mode the monitor is in.</summary>
      CurrentMode: TDisplayMode;
      //** @abstract(Every mode the monitor offers, without duplicates.)
      /// <summary>Every mode the monitor offers, without duplicates.</summary>
      AvailableModes: TDisplayModeList;
      // Physical size from EDID
      //** @abstract(The image's width in millimetres from the EDID; 0 if unknown.)
      /// <summary>The image's width in millimetres from the EDID; 0 if unknown.</summary>
      WidthMm: Integer;      // horizontal image size, millimetres
      //** @abstract(The image's height in millimetres from the EDID; 0 if unknown.)
      /// <summary>The image's height in millimetres from the EDID; 0 if unknown.</summary>
      HeightMm: Integer;     // vertical image size, millimetres
      //** @abstract(The diagonal in inches, from WidthMm and HeightMm; 0 if unknown.)
      /// <summary>The diagonal in inches, from WidthMm and HeightMm; 0 if unknown.</summary>
      DiagonalInches: Double; // computed diagonal, 0 if unknown
    end;

  //** @abstract(A list of monitors.)
  /// <summary>A list of monitors.</summary>
  TDisplayInfoList = TList<TDisplayInfo>;

  //** @abstract(Every display attached, read when the object is created.)
  /// <summary>Every display attached, read when the object is created.</summary>
  TPeardoxDisplays = class
  private
    FDisplays: TDisplayInfoList;
    function GetCount: Integer;
    function GetDisplay(AIndex: Integer): TDisplayInfo;
    procedure Refresh;
    procedure ClearDisplays;
  public
    //** @abstract(Reads every display from the system.)
    /// <summary>Reads every display from the system.</summary>
    constructor Create;
    //** @abstract(Frees the list and every monitor's mode list.)
    /// <summary>Frees the list and every monitor's mode list.</summary>
    destructor Destroy; override;

    //** @abstract(The number of monitors.)
    /// <summary>The number of monitors.</summary>
    property Count: Integer read GetCount;
    //** @abstract(A monitor by position, from 0 to Count - 1.)
    /// <summary>A monitor by position, from 0 to Count - 1.</summary>
    property Displays[AIndex: Integer]: TDisplayInfo
      read GetDisplay; default;
    //** @abstract(The list itself, owned by this object.)
    /// <summary>The list itself, owned by this object.</summary>
    property List: TDisplayInfoList read FDisplays;
    //** @abstract(Which display a form is on.)
    //**
    //** On Windows, the monitor Windows puts most of the form's window on; elsewhere, the one
    //** FMX reports for it.
    //**
    //** @param(AForm The form; nil, or one without a window yet, gives -1.)
    //**
    //** @returns(The display's position in the list, or -1 if it cannot be told.)
    /// <summary>Which display a form is on.</summary>
    /// <remarks>On Windows, the monitor Windows puts most of the form's window on; elsewhere,
    /// the one FMX reports for it.</remarks>
    /// <param name="AForm">The form; nil, or one without a window yet, gives -1.</param>
    /// <returns>The display's position in the list, or -1 if it cannot be told.</returns>
    function IndexOfForm(const AForm: TCommonCustomForm): Integer;
    //** @abstract(The refresh rate of the display a form is on, in hertz.)
    //**
    //** The primary display's if the form's cannot be told.
    //**
    //** @param(AForm The form; nil asks about the primary display.)
    //**
    //** @returns(The refresh rate; 0 if the system does not say.)
    /// <summary>The refresh rate of the display a form is on, in hertz.</summary>
    /// <remarks>The primary display's if the form's cannot be told.</remarks>
    /// <param name="AForm">The form; nil asks about the primary display.</param>
    /// <returns>The refresh rate; 0 if the system does not say.</returns>
    function RefreshRateFor(const AForm: TCommonCustomForm): Integer;
  end;

implementation

uses
  System.Math
  {$IF DEFINED(MSWINDOWS)}
  , Winapi.Windows, Winapi.MultiMon, System.Win.Registry, FMX.Platform.Win
  {$ELSEIF DEFINED(ANDROID)}
  , FMX.Platform, Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText
  {$ELSE}
  , FMX.Platform
  {$ENDIF}
  ;

{ TDisplayMode }

function TDisplayMode.ToString: string;
begin
  Result := Format('%d x %d', [Width, Height]);
  if BitsPerPixel > 0 then
    Result := Result + Format(', %d-bit', [BitsPerPixel]);
  if RefreshRate > 0 then
    Result := Result + Format(', %d Hz', [RefreshRate]);
end;

{$IF DEFINED(MSWINDOWS)}

const
  ENUM_CURRENT_SETTINGS = DWORD(-1);

  // DisplayDevice StateFlags (from wingdi.h)
  DISPLAY_DEVICE_ACTIVE = $00000001;
  DISPLAY_DEVICE_ATTACHED = $00000002;

  // EnumDisplayDevices flag (from winuser.h)
  EDD_GET_DEVICE_INTERFACE_NAME = $00000001;

  EDID_LENGTH = 128;
  EDID_DESCRIPTOR_START = 54;
  EDID_DESCRIPTOR_SIZE = 18;
  EDID_DESCRIPTOR_COUNT = 4;
  EDID_TAG_MONITOR_NAME = $FC;

  // Basic display parameters: image size in cm
  EDID_HSIZE_CM_OFFSET = 21;
  EDID_VSIZE_CM_OFFSET = 22;
  // Detailed timing descriptor: image size in mm (12-bit split fields)
  EDID_DTD_HSIZE_LO = 12; // low 8 bits of horizontal size
  EDID_DTD_VSIZE_LO = 13; // low 8 bits of vertical size
  EDID_DTD_SIZE_HI  = 14; // high nibbles: hi 4 bits H, hi 4 bits V

procedure ParseEdidPhysicalSize(const Edid: TBytes;
  out AWidthMm, AHeightMm: Integer);
var
  DtdBase, HMm, VMm: Integer;
begin
  AWidthMm := 0;
  AHeightMm := 0;
  if Length(Edid) < EDID_LENGTH then
    Exit;

  // Prefer the detailed timing descriptor (mm precision). The first
  // descriptor block at offset 54 is the preferred timing when its
  // pixel-clock bytes (0,1) are non-zero.
  DtdBase := EDID_DESCRIPTOR_START;
  if (Edid[DtdBase] <> 0) or (Edid[DtdBase + 1] <> 0) then
  begin
    HMm := Edid[DtdBase + EDID_DTD_HSIZE_LO] or
      ((Edid[DtdBase + EDID_DTD_SIZE_HI] shr 4) shl 8);
    VMm := Edid[DtdBase + EDID_DTD_VSIZE_LO] or
      ((Edid[DtdBase + EDID_DTD_SIZE_HI] and $0F) shl 8);
    if (HMm > 0) and (VMm > 0) then
    begin
      AWidthMm := HMm;
      AHeightMm := VMm;
      Exit;
    end;
  end;

  // Fall back to the basic cm fields (less precise, some monitors 0 here)
  if (Edid[EDID_HSIZE_CM_OFFSET] > 0) and
     (Edid[EDID_VSIZE_CM_OFFSET] > 0) then
  begin
    AWidthMm := Edid[EDID_HSIZE_CM_OFFSET] * 10;
    AHeightMm := Edid[EDID_VSIZE_CM_OFFSET] * 10;
  end;
end;

{ ---- EDID parsing ---- }

function ParseEdidMonitorName(const Edid: TBytes): string;
var
  I, Base, J: Integer;
  Ch: Byte;
begin
  Result := '';
  if Length(Edid) < EDID_LENGTH then
    Exit;

  for I := 0 to EDID_DESCRIPTOR_COUNT - 1 do
  begin
    Base := EDID_DESCRIPTOR_START + I * EDID_DESCRIPTOR_SIZE;

    if (Edid[Base] = 0) and (Edid[Base + 1] = 0) and
       (Edid[Base + 2] = 0) and
       (Edid[Base + 3] = EDID_TAG_MONITOR_NAME) then
    begin
      for J := Base + 5 to Base + EDID_DESCRIPTOR_SIZE - 1 do
      begin
        Ch := Edid[J];
        if Ch = $0A then
          Break;
        Result := Result + Char(Ch);
      end;
      Result := Trim(Result);
      Exit;
    end;
  end;
end;

function InterfacePathToInstancePath(const APath: string): string;
var
  S: string;
  P: Integer;
begin
  S := APath;
  if S.StartsWith('\\?\') or S.StartsWith('\\.\') then
    S := S.Substring(4);
  P := S.LastIndexOf('#');
  if P > 0 then
    S := S.Substring(0, P);
  Result := S.Replace('#', '\');
end;

function ReadEdidForDevice(const InstancePath: string): TBytes;
var
  Reg: TRegistry;
  KeyPath: string;
begin
  Result := nil;
  KeyPath := 'SYSTEM\CurrentControlSet\Enum\' + InstancePath +
    '\Device Parameters';

  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly(KeyPath) then
    begin
      if Reg.ValueExists('EDID') then
      begin
        SetLength(Result, Reg.GetDataSize('EDID'));
        if Length(Result) > 0 then
          Reg.ReadBinaryData('EDID', Result[0], Length(Result));
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function GetFriendlyMonitorName(const GdiDeviceName: string;
  out AWidthMm, AHeightMm: Integer): string;
var
  Monitor: TDisplayDevice;
  MonIdx: DWORD;
  InstancePath: string;
  Edid: TBytes;
begin
  Result := '';
  AWidthMm := 0;
  AHeightMm := 0;

  MonIdx := 0;
  FillChar(Monitor, SizeOf(Monitor), 0);
  Monitor.cb := SizeOf(TDisplayDevice);

  while EnumDisplayDevices(PChar(GdiDeviceName), MonIdx, Monitor,
    EDD_GET_DEVICE_INTERFACE_NAME) do
  begin
    if (Monitor.StateFlags and DISPLAY_DEVICE_ACTIVE) <> 0 then
    begin
      InstancePath := InterfacePathToInstancePath(
        string(Monitor.DeviceID));

      Edid := ReadEdidForDevice(InstancePath);
      if Length(Edid) >= EDID_LENGTH then
      begin
        Result := ParseEdidMonitorName(Edid);
        ParseEdidPhysicalSize(Edid, AWidthMm, AHeightMm);
      end;

      if Result = '' then
        Result := string(Monitor.DeviceString);

      if Result <> '' then
        Exit;
    end;

    Inc(MonIdx);
    FillChar(Monitor, SizeOf(Monitor), 0);
    Monitor.cb := SizeOf(TDisplayDevice);
  end;
end;

{ ---- Display mode enumeration ---- }

function DevModeToDisplayMode(const DevMode: TDevMode): TDisplayMode;
begin
  Result.Width := DevMode.dmPelsWidth;
  Result.Height := DevMode.dmPelsHeight;
  Result.BitsPerPixel := DevMode.dmBitsPerPel;
  Result.RefreshRate := DevMode.dmDisplayFrequency;
end;

function SameMode(const A, B: TDisplayMode): Boolean;
begin
  Result := (A.Width = B.Width) and (A.Height = B.Height) and
    (A.BitsPerPixel = B.BitsPerPixel) and (A.RefreshRate = B.RefreshRate);
end;

function GetCurrentMode(const DeviceName: string): TDisplayMode;
var
  DevMode: TDevMode;
begin
  FillChar(DevMode, SizeOf(DevMode), 0);
  DevMode.dmSize := SizeOf(TDevMode);

  if EnumDisplaySettings(PChar(DeviceName), ENUM_CURRENT_SETTINGS,
    DevMode) then
    Result := DevModeToDisplayMode(DevMode)
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function GetAvailableModes(const DeviceName: string): TDisplayModeList;
var
  DevMode: TDevMode;
  ModeNum: DWORD;
  Mode: TDisplayMode;
  Existing: TDisplayMode;
  Found: Boolean;
begin
  Result := TDisplayModeList.Create;
  ModeNum := 0;

  FillChar(DevMode, SizeOf(DevMode), 0);
  DevMode.dmSize := SizeOf(TDevMode);

  while EnumDisplaySettings(PChar(DeviceName), ModeNum, DevMode) do
  begin
    Mode := DevModeToDisplayMode(DevMode);

    Found := False;
    for Existing in Result do
      if SameMode(Existing, Mode) then
      begin
        Found := True;
        Break;
      end;

    if not Found then
      Result.Add(Mode);

    Inc(ModeNum);
    FillChar(DevMode, SizeOf(DevMode), 0);
    DevMode.dmSize := SizeOf(TDevMode);
  end;
end;

{ ---- Monitor enumeration callback ---- }

function MonitorEnumProc(hMonitor: HMONITOR; hdcMonitor: HDC;
  lprcMonitor: PRect; dwData: LPARAM): BOOL; stdcall;
var
  List: TDisplayInfoList;
  Info: TMonitorInfoEx;
  Display: TDisplayInfo;
  Added: Boolean;
begin
  Result := True;
  List := TDisplayInfoList(dwData);

  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(TMonitorInfoEx);

  if not GetMonitorInfo(hMonitor, @Info) then
    Exit;

  Display := Default(TDisplayInfo);
  Added := False;
  try
    Display.DeviceName := string(Info.szDevice);
    Display.MonitorRect := Info.rcMonitor;
    Display.WorkRect := Info.rcWork;
    Display.IsPrimary := (Info.dwFlags and MONITORINFOF_PRIMARY) <> 0;
    Display.FriendlyName := GetFriendlyMonitorName(Display.DeviceName,
      Display.WidthMm, Display.HeightMm);
    Display.CurrentMode := GetCurrentMode(Display.DeviceName);
    Display.AvailableModes := GetAvailableModes(Display.DeviceName);

    if (Display.WidthMm > 0) and (Display.HeightMm > 0) then
      Display.DiagonalInches :=
        Sqrt(Sqr(Display.WidthMm) + Sqr(Display.HeightMm)) / 25.4
    else
      Display.DiagonalInches := 0;

    List.Add(Display);
    Added := True;
  finally
    if not Added then
      Display.AvailableModes.Free;
  end;
end;

procedure ReadDisplays(const AList: TDisplayInfoList);
begin
  EnumDisplayMonitors(0, nil, @MonitorEnumProc, LPARAM(AList));
end;

// The device name of the monitor AForm's window is mostly on; empty if it
// has no window yet
function FormDeviceName(const AForm: TCommonCustomForm): string;
var
  Wnd: HWND;
  Info: TMonitorInfoEx;
begin
  Result := '';
  if (AForm = nil) or (AForm.Handle = nil) then
    Exit;
  Wnd := WindowHandleToPlatform(AForm.Handle).Wnd;
  if Wnd = 0 then
    Exit;
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(TMonitorInfoEx);
  if GetMonitorInfo(MonitorFromWindow(Wnd, MONITOR_DEFAULTTONEAREST), @Info) then
    Result := string(Info.szDevice);
end;

{$ELSE}

{$IF DEFINED(MACOS) and not DEFINED(IOS)}
const
  CORE_GRAPHICS = '/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics';

// Declared here rather than taken from Macapi.CoreGraphics, so nothing
// depends on which of these a given Delphi version translates
function CGMainDisplayID: UInt32; cdecl; external CORE_GRAPHICS name 'CGMainDisplayID';
function CGGetActiveDisplayList(AMaxDisplays: UInt32; ADisplays: PUInt32;
  ACount: PUInt32): Int32; cdecl; external CORE_GRAPHICS name 'CGGetActiveDisplayList';
function CGDisplayCopyDisplayMode(ADisplay: UInt32): Pointer; cdecl;
  external CORE_GRAPHICS name 'CGDisplayCopyDisplayMode';
function CGDisplayModeGetRefreshRate(AMode: Pointer): Double; cdecl;
  external CORE_GRAPHICS name 'CGDisplayModeGetRefreshRate';
procedure CGDisplayModeRelease(AMode: Pointer); cdecl;
  external CORE_GRAPHICS name 'CGDisplayModeRelease';

function CGRefreshRate(const ADisplay: UInt32): Integer;
var
  Mode: Pointer;
begin
  Result := 0;
  Mode := CGDisplayCopyDisplayMode(ADisplay);
  if Mode = nil then
    Exit;
  try
    Result := Round(CGDisplayModeGetRefreshRate(Mode));
  finally
    CGDisplayModeRelease(Mode);
  end;
end;
{$ENDIF}

// Each display's refresh rate as the system gives it, the main display's
// first, then the others in the system's order; empty if it does not say
function PlatformRefreshRates: TArray<Integer>;
{$IF DEFINED(MACOS) and not DEFINED(IOS)}
const
  MAX_DISPLAYS = 32;
var
  Ids: array[0..MAX_DISPLAYS - 1] of UInt32;
  Count: UInt32;
  I: Integer;
  Main: UInt32;
begin
  Main := CGMainDisplayID;
  Result := [CGRefreshRate(Main)];
  Count := 0;
  if CGGetActiveDisplayList(MAX_DISPLAYS, @Ids[0], @Count) <> 0 then
    Exit;
  for I := 0 to Integer(Count) - 1 do
    if Ids[I] <> Main then
      Result := Result + [CGRefreshRate(Ids[I])];
end;
{$ELSEIF DEFINED(ANDROID)}
begin
  Result := nil;
  if TAndroidHelper.Display <> nil then
    Result := [Round(TAndroidHelper.Display.getRefreshRate)];
end;
{$ELSE}
begin
  Result := nil;   // iOS and Linux: not asked
end;
{$ENDIF}

function RateAt(const ARates: TArray<Integer>; const AIndex: Integer): Integer;
begin
  if AIndex < Length(ARates) then
    Result := ARates[AIndex]
  else if Length(ARates) > 0 then
    Result := ARates[0]   // one rate for every display
  else
    Result := 0;
end;

procedure AddDisplay(const AList: TDisplayInfoList; const AIndex: Integer;
  const APrimary: Boolean; const ABounds, AWorkArea: TRectF; const AScale: Single;
  const ARate: Integer);
var
  Display: TDisplayInfo;
  Scale: Single;
begin
  Scale := AScale;
  if Scale <= 0 then
    Scale := 1;
  Display := Default(TDisplayInfo);
  Display.DeviceName := Format('Display %d', [AIndex + 1]);
  if APrimary then
    Display.FriendlyName := 'Main display'
  else
    Display.FriendlyName := Display.DeviceName;
  Display.MonitorRect := Rect(Round(ABounds.Left), Round(ABounds.Top),
    Round(ABounds.Right), Round(ABounds.Bottom));
  Display.WorkRect := Rect(Round(AWorkArea.Left), Round(AWorkArea.Top),
    Round(AWorkArea.Right), Round(AWorkArea.Bottom));
  Display.IsPrimary := APrimary;
  Display.CurrentMode.Width := Round(ABounds.Width * Scale);
  Display.CurrentMode.Height := Round(ABounds.Height * Scale);
  Display.CurrentMode.BitsPerPixel := 0;
  Display.CurrentMode.RefreshRate := ARate;
  Display.AvailableModes := TDisplayModeList.Create;
  Display.AvailableModes.Add(Display.CurrentMode);
  AList.Add(Display);
end;

// FMX's displays, the main one first in the rates; with no display service,
// the one screen
procedure ReadDisplays(const AList: TDisplayInfoList);
var
  Rates: TArray<Integer>;
  I, Next: Integer;
  Rate: Integer;
  ScreenService: IFMXScreenService;
  Size: TPointF;
begin
  Rates := PlatformRefreshRates;
  if Screen.DisplayCount > 0 then
  begin
    Next := 1;
    for I := 0 to Screen.DisplayCount - 1 do
    begin
      var Display := Screen.Displays[I];
      if Display.Primary then
        Rate := RateAt(Rates, 0)
      else
      begin
        Rate := RateAt(Rates, Next);
        Inc(Next);
      end;
      AddDisplay(AList, I, Display.Primary,
        RectF(Display.Bounds.Left, Display.Bounds.Top, Display.Bounds.Right,
          Display.Bounds.Bottom),
        RectF(Display.WorkArea.Left, Display.WorkArea.Top, Display.WorkArea.Right,
          Display.WorkArea.Bottom),
        Display.Scale, Rate);
    end;
  end
  else if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService,
    ScreenService) then
  begin
    Size := ScreenService.GetScreenSize;
    AddDisplay(AList, 0, True, RectF(0, 0, Size.X, Size.Y), RectF(0, 0, Size.X, Size.Y),
      ScreenService.GetScreenScale, RateAt(Rates, 0));
  end;
end;

{$ENDIF}

{ TPeardoxDisplays }

constructor TPeardoxDisplays.Create;
begin
  inherited Create;
  FDisplays := TDisplayInfoList.Create;
  Refresh;
end;

destructor TPeardoxDisplays.Destroy;
begin
  ClearDisplays;
  FDisplays.Free;
  inherited Destroy;
end;

procedure TPeardoxDisplays.ClearDisplays;
var
  Display: TDisplayInfo;
begin
  if FDisplays = nil then
    Exit;
  for Display in FDisplays do
    Display.AvailableModes.Free;
  FDisplays.Clear;
end;

procedure TPeardoxDisplays.Refresh;
begin
  ClearDisplays;
  ReadDisplays(FDisplays);
end;

function TPeardoxDisplays.IndexOfForm(const AForm: TCommonCustomForm): Integer;
{$IF DEFINED(MSWINDOWS)}
var
  Name: string;
  I: Integer;
begin
  Result := -1;
  Name := FormDeviceName(AForm);
  if Name = '' then
    Exit;
  for I := 0 to FDisplays.Count - 1 do
    if SameText(FDisplays[I].DeviceName, Name) then
      Exit(I);
end;
{$ELSE}
begin
  Result := -1;
  if (AForm = nil) or (Screen.DisplayCount = 0) then
    Exit;
  Result := Screen.DisplayFromForm(AForm).Index;
  if (Result < 0) or (Result >= FDisplays.Count) then
    Result := -1;
end;
{$ENDIF}

function TPeardoxDisplays.RefreshRateFor(const AForm: TCommonCustomForm): Integer;
var
  Index, I: Integer;
begin
  Result := 0;
  Index := IndexOfForm(AForm);
  if Index < 0 then
    for I := 0 to FDisplays.Count - 1 do
      if FDisplays[I].IsPrimary then
      begin
        Index := I;
        Break;
      end;
  if (Index < 0) and (FDisplays.Count > 0) then
    Index := 0;
  if Index >= 0 then
    Result := FDisplays[Index].CurrentMode.RefreshRate;
end;

function TPeardoxDisplays.GetCount: Integer;
begin
  Result := FDisplays.Count;
end;

function TPeardoxDisplays.GetDisplay(AIndex: Integer): TDisplayInfo;
begin
  Result := FDisplays[AIndex];
end;

end.
