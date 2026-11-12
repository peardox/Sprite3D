//** @abstract(Finds files in a folder and its sub-folders that match a file spec, such as
//** @code(*.glb) or @code(*.glb;*.gltf).)
//**
//** FindFiles walks a folder tree and adds to a TList every file whose name matches one of
//** the spec's patterns. Patterns use @code(*) for any run of characters and @code(?) for
//** any one, and are matched against the file's name alone, without its folder, ignoring
//** case on every platform, so @code(*.glb) also finds @code(MODEL.GLB) on Linux. A folder
//** that cannot be read is skipped rather than ending the search, and the walk goes no
//** deeper than MAX_FOLDER_DEPTH, so a link that loops back on itself cannot make it run for
//** ever.
//**
//** The unit knows nothing of models or of any application: it uses the RTL alone, and is
//** safe to call from a worker thread, as long as nothing else uses the same list meanwhile.
unit Sprite3DFileSearch;

{
  Finds files in a folder and its sub-folders that match a file spec, such
  as *.glb or *.glb;*.gltf.

  FindFiles walks a folder tree and adds to a TList every file whose name
  matches one of the spec's patterns, ignoring case on every platform. A
  folder that cannot be read is skipped, and the walk goes no deeper than
  MAX_FOLDER_DEPTH, so a looping link cannot make it run for ever. RTL only;
  safe on a worker thread.
}

interface

uses
  System.SysUtils, System.Generics.Collections;

const
  //** @abstract(How many folders deep FindFiles goes below the one it is given.)
  //**
  //** Deep enough for any real folder tree; it is there so that a link to a folder above
  //** itself, which would otherwise be followed round and round, ends the walk.
  MAX_FOLDER_DEPTH = 64;

//** @abstract(Splits a file spec into its patterns.)
//**
//** Patterns are separated by semicolons, commas or spaces, so @code(*.glb;*.gltf),
//** @code(*.glb, *.gltf) and @code(*.glb *.gltf) are alike. Empty parts are dropped, and
//** so are repeats, ignoring case.
//**
//** @param(ASpec The file spec.)
//**
//** @returns(The patterns, in the order given; empty if ASpec has none.)
function SplitFileSpec(const ASpec: String): TArray<String>;

//** @abstract(Whether a file's name matches any of a set of patterns.)
//**
//** @param(AFileName A file name or path; only the name is matched.)
//**
//** @param(APatterns Patterns, as SplitFileSpec returns them.)
//**
//** @returns(True if the name matches one of them, ignoring case.)
function MatchesFileSpec(const AFileName: String; const APatterns: TArray<String>): Boolean;

//** @abstract(Adds to AFiles every file in AFolder that matches ASpec, and, if ARecursive,
//** every one in its sub-folders, however deep, up to MAX_FOLDER_DEPTH.)
//**
//** Each file is added as a full path. Within a folder files are added in name order,
//** ignoring case, before the files of its sub-folders, which are visited in name order too,
//** so the same tree always gives the same list. Files already in AFiles are not added
//** again. Folders that cannot be read are skipped.
//**
//** @param(AFolder The folder to search.)
//**
//** @param(ASpec The file spec, such as @code(*.glb) or @code(*.glb;*.gltf); see
//** SplitFileSpec.)
//**
//** @param(AFiles The list the files are added to; it is not emptied first.)
//**
//** @param(ARecursive True, the default, to search sub-folders too.)
//**
//** @returns(How many files were added.)
//**
//** @raises(EArgumentException If AFiles is nil.)
//**
//** @raises(EDirectoryNotFoundException If AFolder is not a folder that exists.)
function FindFiles(const AFolder, ASpec: String; const AFiles: TList<String>;
  const ARecursive: Boolean = True): Integer;

implementation

uses
  System.IOUtils, System.Types, System.Generics.Defaults;

function SplitFileSpec(const ASpec: String): TArray<String>;
var
  Part: String;
  Known: Boolean;
begin
  Result := nil;
  for Part in ASpec.Split([';', ',', ' '], TStringSplitOptions.ExcludeEmpty) do
  begin
    Known := False;
    for var Pattern in Result do
      Known := Known or SameText(Pattern, Part.Trim);
    if not Known and (Part.Trim <> String.Empty) then
      Result := Result + [Part.Trim];
  end;
end;

function MatchesFileSpec(const AFileName: String; const APatterns: TArray<String>): Boolean;
var
  Name: String;
begin
  Name := ExtractFileName(AFileName);
  for var Pattern in APatterns do
    if TPath.MatchesPattern(Name, Pattern, False) then
      Exit(True);
  Result := False;
end;

// Names in order, ignoring case, so the walk is the same every time
procedure SortNames(var ANames: TStringDynArray);
begin
  TArray.Sort<String>(ANames, TComparer<String>.Construct(
    function(const A, B: String): Integer
    begin
      Result := CompareText(A, B);
      if Result = 0 then
        Result := CompareStr(A, B);
    end));
end;

function FindFiles(const AFolder, ASpec: String; const AFiles: TList<String>;
  const ARecursive: Boolean): Integer;
var
  Patterns: TArray<String>;
  Added: Integer;

  procedure Walk(const AFolderNow: String; const ADepth: Integer);
  var
    Names, Folders: TStringDynArray;
  begin
    // A folder that cannot be listed, such as one without permission, is
    // left out rather than ending the search
    try
      Names := TDirectory.GetFiles(AFolderNow);
    except
      Names := nil;
    end;
    SortNames(Names);
    for var FileName in Names do
      if MatchesFileSpec(FileName, Patterns) and not AFiles.Contains(FileName) then
      begin
        AFiles.Add(FileName);
        Inc(Added);
      end;
    if not ARecursive or (ADepth >= MAX_FOLDER_DEPTH) then
      Exit;
    try
      Folders := TDirectory.GetDirectories(AFolderNow);
    except
      Folders := nil;
    end;
    SortNames(Folders);
    for var Folder in Folders do
      Walk(Folder, ADepth + 1);
  end;

begin
  if AFiles = nil then
    raise EArgumentException.Create('FindFiles needs a list to add the files to');
  if (AFolder = String.Empty) or not TDirectory.Exists(AFolder) then
    raise EDirectoryNotFoundException.CreateFmt('There is no folder %s', [AFolder]);
  Added := 0;
  Patterns := SplitFileSpec(ASpec);
  if Length(Patterns) > 0 then
    // As given: stripping a trailing separator would empty a root such as /
    Walk(AFolder, 0);
  Result := Added;
end;

end.
