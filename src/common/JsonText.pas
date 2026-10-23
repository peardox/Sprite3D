//** @abstract(How Sprite3D writes its JSON files: indented for people to read, or minified.)
//**
//** Every JSON file Sprite3D writes goes through JsonToText, or, for settings.json, follows
//** MinifyJson itself, so File, Settings, Minify JSON changes them all at once: exports'
//** metadata, directions files, animation settings, project files, settings.json and the
//** caches. MinifyJson is set on the main thread as the settings load and change; files may
//** be written on worker threads, which only read it.
unit JsonText;

{
  How Sprite3D writes its JSON files: indented for people to read, or
  minified.

  Every JSON file Sprite3D writes goes through JsonToText, or, for
  settings.json, follows MinifyJson itself, so File, Settings, Minify JSON
  changes them all at once: exports' metadata, directions files, animation
  settings, project files, settings.json and the caches. MinifyJson is set
  on the main thread as the settings load and change; files may be written
  on worker threads, which only read it.
}

interface

uses
  System.SysUtils, System.JSON;

var
  //** @abstract(True writes JSON with no indents or line breaks; False, the default, indents
  //** it two spaces.)
  /// <summary>True writes JSON with no indents or line breaks; False, the default, indents it
  /// two spaces.</summary>
  MinifyJson: Boolean = False;

//** @abstract(A JSON value as the text of a file, minified or indented as MinifyJson says.)
//**
//** @param(AValue The value, such as a file's root object; nil gives @code(null).)
//**
//** @returns(The text, with no byte order mark or trailing line break.)
/// <summary>A JSON value as the text of a file, minified or indented as MinifyJson
/// says.</summary>
/// <param name="AValue">The value, such as a file's root object; nil gives
/// <c>null</c>.</param>
/// <returns>The text, with no byte order mark or trailing line break.</returns>
function JsonToText(const AValue: TJSONValue): String;

//** @abstract(A JSON value as UTF-8 bytes for a file, without a byte order mark, which some
//** JSON readers reject.)
//**
//** @param(AValue The value, such as a file's root object.)
//**
//** @returns(The bytes of JsonToText.)
/// <summary>A JSON value as UTF-8 bytes for a file, without a byte order mark, which some
/// JSON readers reject.</summary>
/// <param name="AValue">The value, such as a file's root object.</param>
/// <returns>The bytes of JsonToText.</returns>
function JsonToBytes(const AValue: TJSONValue): TBytes;

implementation

function JsonToText(const AValue: TJSONValue): String;
begin
  if AValue = nil then
    Result := 'null'
  else if MinifyJson then
    Result := AValue.ToJSON
  else
    Result := AValue.Format(2);
end;

function JsonToBytes(const AValue: TJSONValue): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(JsonToText(AValue));
end;

end.
