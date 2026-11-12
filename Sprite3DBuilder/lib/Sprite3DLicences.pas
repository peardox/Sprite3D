//** @abstract(The third-party licences and notices Sprite3DBuilder carries, read from the program's
//** own resources.)
//**
//** Every licence or notice a release must include is a text file in the project's
//** @code(licences) folder, linked into the program as an RCDATA resource by
//** @code(licences/Sprite3DLicences.rc), so it is inside the executable on every platform and
//** cannot be left out of a release. ThirdPartyLicences lists them, in the order they are shown, each
//** with a title and its resource name; LicenceText reads one, and AllLicencesText puts them
//** all together, for a notices file to ship beside the program.
//**
//** To add a licence: put its text file in @code(licences), name it in
//** @code(Sprite3DLicences.rc), and add it to ThirdPartyLicences. Uses the RTL only; safe on any
//** thread.
unit Sprite3DLicences;

{
  The third-party licences and notices Sprite3DBuilder carries, read from the
  program's own resources.

  Every licence or notice a release must include is a text file in the
  project's licences folder, linked into the program as an RCDATA resource
  by licences/Sprite3DLicences.rc, so it is inside the executable on every
  platform and cannot be left out of a release. ThirdPartyLicences lists them;
  LicenceText reads one, and AllLicencesText puts them all together.

  To add a licence: put its text file in licences, name it in
  Sprite3DLicences.rc, and add it to ThirdPartyLicences. RTL only; any thread.
}

interface

uses
  System.SysUtils;

const
  //** @abstract(The resource holding Neon's MIT licence.)
  LICENCE_NEON = 'LICENCE_NEON';
  //** @abstract(The resource holding the Vampyre Imaging Library's notice and its Mozilla
  //** Public License 2.0.)
  LICENCE_VAMPYRE = 'LICENCE_VAMPYRE';

type
  //** @abstract(One licence or notice the program carries.)
  TSprite3DLicence = record
    //** @abstract(What it covers, as shown in File, Licences.)
    Title: String;
    //** @abstract(The RCDATA resource holding its text, one of the LICENCE_ constants.)
    Resource: String;
  end;

//** @abstract(Every licence and notice the program carries, in the order they are shown.)
//** @returns(The list.)
function ThirdPartyLicences: TArray<TSprite3DLicence>;

//** @abstract(One licence's text, read from the program's resources.)
//**
//** The text files are UTF-8; their line breaks come back as the platform's own.
//**
//** @param(AResource The resource's name, one of the LICENCE_ constants.)
//**
//** @returns(The text; if the resource is missing, a line saying so, as the build then left
//** it out.)
function LicenceText(const AResource: String): String;

//** @abstract(Every licence and notice together, each under its title, for a notices file
//** to ship beside the program.)
//** @returns(The text, lines ending with the platform's line break.)
function AllLicencesText: String;

implementation

uses
  System.Classes;

function ThirdPartyLicences: TArray<TSprite3DLicence>;

  function Entry(const ATitle, AResource: String): TSprite3DLicence;
  begin
    Result.Title := ATitle;
    Result.Resource := AResource;
  end;

begin
  Result := [
    Entry('Neon JSON library: MIT licence', LICENCE_NEON),
    Entry('Vampyre Imaging Library: Mozilla Public License 2.0', LICENCE_VAMPYRE)];
end;

function LicenceText(const AResource: String): String;
const
  // RT_RCDATA, given as itself, as its declaration differs by platform
  RCDATA = PChar(10);
var
  Stream: TResourceStream;
  Bytes: TBytes;
begin
  try
    Stream := TResourceStream.Create(HInstance, AResource, RCDATA);
  except
    on E: EResNotFound do
      Exit(Format('(The text of %s is missing from this build: licences\Sprite3DLicences.res ' +
        'was not linked in.)', [AResource]));
  end;
  try
    SetLength(Bytes, Stream.Size);
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
  Result := TEncoding.UTF8.GetString(Bytes).TrimLeft([#$FEFF]);
  Result := AdjustLineBreaks(Result, tlbsCRLF);
  if sLineBreak <> #13#10 then
    Result := Result.Replace(#13#10, sLineBreak);
end;

function AllLicencesText: String;
var
  Lines: TStringBuilder;
  Licence: TSprite3DLicence;
begin
  Lines := TStringBuilder.Create;
  try
    Lines.Append('Third-party licences and notices for Sprite3DBuilder').Append(sLineBreak);
    Lines.Append(StringOfChar('=', 53)).Append(sLineBreak);
    for Licence in ThirdPartyLicences do
    begin
      Lines.Append(sLineBreak).Append(sLineBreak);
      Lines.Append(Licence.Title).Append(sLineBreak);
      Lines.Append(StringOfChar('-', Length(Licence.Title))).Append(sLineBreak);
      Lines.Append(sLineBreak);
      Lines.Append(LicenceText(Licence.Resource).TrimRight).Append(sLineBreak);
    end;
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;

end.
