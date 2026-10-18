unit DisplayData;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Winapi.Windows, Winapi.MultiMon;

type
  TDisplayMode = record
    Width: Integer;
    Height: Integer;
    BitsPerPixel: Integer;
    RefreshRate: Integer; // Hz
    function ToString: string;
  end;

  TDisplayModeList = TList<TDisplayMode>;

  TDisplayInfo = record
      DeviceName: string;
      FriendlyName: string;
      MonitorRect: TRect;
      WorkRect: TRect;
      IsPrimary: Boolean;
      CurrentMode: TDisplayMode;
      AvailableModes: TDisplayModeList;
      // Physical size from EDID
      WidthMm: Integer;      // horizontal image size, millimetres
      HeightMm: Integer;     // vertical image size, millimetres
      DiagonalInches: Double; // computed diagonal, 0 if unknown
    end;

  TDisplayInfoList = TList<TDisplayInfo>;

  TPeardoxDisplays = class
  private
    FDisplays: TDisplayInfoList;
    function GetCount: Integer;
    function GetDisplay(AIndex: Integer): TDisplayInfo;
    procedure Refresh;
    procedure ClearDisplays;
  public
    constructor Create;
    destructor Destroy; override;

    property Count: Integer read GetCount;
    property Displays[AIndex: Integer]: TDisplayInfo
      read GetDisplay; default;
    property List: TDisplayInfoList read FDisplays;
  end;

implementation

uses
  System.StrUtils, System.Win.Registry, System.Math
  , FMX.Forms, FMX.Types, System.Types;

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

{ TDisplayMode }

function TDisplayMode.ToString: string;
begin
  Result := Format('%d x %d, %d-bit, %d Hz',
    [Width, Height, BitsPerPixel, RefreshRate]);
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
  EnumDisplayMonitors(0, nil, @MonitorEnumProc, LPARAM(FDisplays));
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
