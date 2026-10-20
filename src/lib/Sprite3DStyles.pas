//** @abstract(Switches the whole application between FireMonkey's own default look and a
//** named FMX style, at run time.)
//**
//** ApplyFmxStyle sets the style through TStyleManager, so it reaches every form that has no
//** StyleBook of its own, including forms already on screen. A named style is looked for
//** first as a resource linked into the program, then as a @code(<name>.style) file in each
//** of the folders given, in order, with the file name matched regardless of case. An
//** empty name puts back the platform's default style.
//**
//** The styles that come with RAD Studio are in its @code(Redist\styles\Fmx) folder; copy the
//** ones wanted next to the program, link them in as RCDATA resources, or deploy them with
//** the application.
//**
//** The unit knows nothing of any particular application. Call it on the main thread only.
unit Sprite3DStyles;

{
  Switches the whole application between FireMonkey's own default look and
  a named FMX style, at run time.

  ApplyFmxStyle sets the style through TStyleManager, so it reaches every
  form that has no StyleBook of its own, including forms already on screen.
  A named style is looked for first as a resource linked into the program,
  then as a <name>.style file in each of the folders given, in order, with
  the file name matched regardless of case. An empty name puts back the
  platform's default style.

  The styles that come with RAD Studio are in its Redist\styles\Fmx folder;
  copy the ones wanted next to the program, link them in as RCDATA
  resources, or deploy them with the application.

  The unit knows nothing of any particular application. Call it on the main
  thread only.
}

interface

uses
  System.SysUtils;

//** @abstract(Applies a named FMX style to the whole application, or puts back the default.)
//**
//** For a non-empty AName, AResourceName is tried first, if given, then
//** @code(<AName>.style) in each of AFolders in turn; the first that loads is used. When
//** none is found or none loads, the style in use is left as it was.
//**
//** @param(AName The style's file name without @code(.style), such as @code(Dark); empty
//** for the platform's default style.)
//**
//** @param(AResourceName The name of an RCDATA resource holding the style, or empty to look
//** for files only.)
//**
//** @param(AFolders The folders to look in for the style file, in order; empty entries are
//** skipped.)
//**
//** @param(AError On failure, why; empty on success.)
//**
//** @returns(True if the style, or the default, is now in use.)
/// <summary>Applies a named FMX style to the whole application, or puts back the
/// default.</summary>
/// <remarks>For a non-empty AName, AResourceName is tried first, if given, then
/// <c>&lt;AName&gt;.style</c> in each of AFolders in turn; the first that loads is used. When
/// none is found or none loads, the style in use is left as it was.</remarks>
/// <param name="AName">The style's file name without <c>.style</c>, such as <c>Dark</c>;
/// empty for the platform's default style.</param>
/// <param name="AResourceName">The name of an RCDATA resource holding the style, or empty to
/// look for files only.</param>
/// <param name="AFolders">The folders to look in for the style file, in order; empty entries
/// are skipped.</param>
/// <param name="AError">On failure, why; empty on success.</param>
/// <returns>True if the style, or the default, is now in use.</returns>
function ApplyFmxStyle(const AName, AResourceName: String;
  const AFolders: array of String; out AError: String): Boolean;

implementation

uses
  System.IOUtils, FMX.Styles;

// <AName>.style in AFolder, matched without regard to case, as RAD Studio
// ships some styles with a capital S and Linux file names are case-sensitive;
// empty if there is none
function FindStyleFile(const AFolder, AName: String): String;
begin
  Result := TPath.Combine(AFolder, AName + '.style');
  if TFile.Exists(Result) then
    Exit;
  Result := String.Empty;
  if not TDirectory.Exists(AFolder) then
    Exit;
  try
    for var Candidate in TDirectory.GetFiles(AFolder) do
      if SameText(ExtractFileName(Candidate), AName + '.style') then
        Exit(Candidate);
  except
    // An unreadable folder has nothing to offer
  end;
end;

function ApplyFmxStyle(const AName, AResourceName: String;
  const AFolders: array of String; out AError: String): Boolean;
var
  FileName, Tried: String;
begin
  AError := String.Empty;
  if AName = String.Empty then
  begin
    // nil hands every form back to the platform's own style
    TStyleManager.SetStyle(nil);
    Exit(True);
  end;

  if AResourceName <> String.Empty then
  try
    if TStyleManager.TrySetStyleFromResource(AResourceName) then
      Exit(True);
  except
    // A damaged resource: carry on with the files
  end;

  Tried := String.Empty;
  for var Folder in AFolders do
  begin
    if Folder = String.Empty then
      Continue;
    FileName := FindStyleFile(Folder, AName);
    Tried := Tried + sLineBreak + '  ' + TPath.Combine(Folder, AName + '.style');
    if FileName = String.Empty then
      Continue;
    try
      TStyleManager.SetStyleFromFile(FileName);
      Exit(True);
    except
      on E: Exception do
        AError := 'Can''t load ' + FileName + ': ' + E.Message;
    end;
  end;

  if AError = String.Empty then
    AError := 'The ' + AName + ' style was not found. Looked in:' + Tried;
  Result := False;
end;

end.
