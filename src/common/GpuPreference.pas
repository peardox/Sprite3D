unit GpuPreference;

interface
{$if defined(MSWINDOWS)}

type
  TGpuPreference = (gpAutomatic, gpPowerSaving, gpHighPerformance);

/// Sets the Windows GPU preference for the current executable.
/// Takes effect on the next launch of the application.
/// Returns True on success.
function SetGpuPreference(const APreference: TGpuPreference): Boolean;

/// Reads the current preference for this executable. If none exists,
/// writes ADefault to the registry and returns it.
/// Returns True if a usable preference is available (existing or newly set).
function GetGpuPreference(out APreference: TGpuPreference;
  const ADefault: TGpuPreference = gpHighPerformance): Boolean;
{$ifend}

implementation

{$if defined(MSWINDOWS)}
uses
  System.Win.Registry,
  Winapi.Windows,
  System.SysUtils;

const
  GPU_PREF_KEY =
    'SOFTWARE\Microsoft\DirectX\UserGpuPreferences';

function CurrentExePath: string;
begin
  // Full path is used as the value name, matching Windows behavior
  Result := ParamStr(0);
end;

function PreferenceToValue(const APreference: TGpuPreference): string;
var
  N: Integer;
begin
  case APreference of
    gpPowerSaving: N := 1;
    gpHighPerformance: N := 2;
  else
    N := 0; // gpAutomatic
  end;
  // Windows stores it as a string of form: "GpuPreference=2;"
  Result := Format('GpuPreference=%d;', [N]);
end;

function SetGpuPreference(const APreference: TGpuPreference): Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_64KEY);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(GPU_PREF_KEY, True) then
    begin
      if APreference = gpAutomatic then
      begin
        // Remove the value to fully hand control back to Windows
        if Reg.ValueExists(CurrentExePath) then
          Reg.DeleteValue(CurrentExePath);
      end
      else
        Reg.WriteString(CurrentExePath, PreferenceToValue(APreference));
      Result := True;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function GetGpuPreference(out APreference: TGpuPreference;
  const ADefault: TGpuPreference): Boolean;
var
  Reg: TRegistry;
  Data: string;
  P: Integer;
  NumStr: string;
  Found: Boolean;
begin
  Found := False;
  APreference := ADefault;
  Reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(GPU_PREF_KEY) then
    begin
      if Reg.ValueExists(CurrentExePath) then
      begin
        Data := Reg.ReadString(CurrentExePath);
        P := Pos('GpuPreference=', Data);
        if P > 0 then
        begin
          Inc(P, Length('GpuPreference='));
          NumStr := '';
          while (P <= Length(Data)) and CharInSet(Data[P], ['0' .. '9']) do
          begin
            NumStr := NumStr + Data[P];
            Inc(P);
          end;
          case StrToIntDef(NumStr, 0) of
            1: APreference := gpPowerSaving;
            2: APreference := gpHighPerformance;
          else
            APreference := gpAutomatic;
          end;
          Found := True;
        end;
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

  if Found then
    // An existing preference was read successfully.
    Result := True
  else
    Result := False;
end;

{$ifend}

end.
