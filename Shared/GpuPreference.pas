//** @abstract(Windows' per-program graphics processor preference, as Settings, Display,
//** Graphics sets it.)
//**
//** Windows keeps, for each program file, which GPU to start it on: let Windows decide, the
//** power-saving one or the high-performance one. It is a string value named after the
//** program's full path under @code(HKCU\Software\Microsoft\DirectX\UserGpuPreferences),
//** such as @code(GpuPreference=2;). SetGpuPreference writes the running program's entry and
//** GetGpuPreference reads it. Windows reads it when the program starts, so a change takes
//** effect at the next start.
//**
//** Windows only: on other platforms the unit declares nothing. For any thread.
unit GpuPreference;

{
  Windows' per-program graphics processor preference, as Settings, Display,
  Graphics sets it.

  Windows keeps, for each program file, which GPU to start it on: let
  Windows decide, the power-saving one or the high-performance one. It is a
  string value named after the program's full path under
  HKCU\Software\Microsoft\DirectX\UserGpuPreferences, such as
  GpuPreference=2;. SetGpuPreference writes the running program's entry and
  GetGpuPreference reads it. Windows reads it when the program starts, so a
  change takes effect at the next start.

  Windows only: on other platforms the unit declares nothing. For any
  thread.
}

interface
{$if defined(MSWINDOWS)}

type
  //** @abstract(Which graphics processor Windows starts the program on.)
  TGpuPreference = (
    //** @abstract(Let Windows decide; no entry is kept.)
    gpAutomatic,
    //** @abstract(The power-saving GPU, usually the integrated one; stored as 1.)
    gpPowerSaving,
    //** @abstract(The high-performance GPU, usually the discrete one; stored as 2.)
    gpHighPerformance);

//** @abstract(Sets the Windows GPU preference for the running program.)
//**
//** gpAutomatic removes the program's entry, handing the choice back to Windows; the others
//** write it. It takes effect the next time the program starts.
//**
//** @param(APreference The preference to keep.)
//**
//** @returns(True if the registry key could be opened and the entry written or removed.)
function SetGpuPreference(const APreference: TGpuPreference): Boolean;

//** @abstract(Reads the Windows GPU preference for the running program.)
//**
//** Nothing is written: if the program has no entry, or it cannot be read, APreference is
//** ADefault and the result is False. A number other than 1 or 2 in the entry reads as
//** gpAutomatic.
//**
//** @param(APreference On return, the preference read, or ADefault.)
//**
//** @param(ADefault The preference to give when there is no entry.)
//**
//** @returns(True if an entry was found and read.)
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
